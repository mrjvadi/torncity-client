extends TestCase


func _jwt(claims: Dictionary) -> String:
	return Mock.jwt(claims)


func test_jwt_exp() -> void:
	eq(TokenLogic.jwt_exp(_jwt({"sub": "1", "exp": 1790000000})), 1790000000)
	eq(TokenLogic.jwt_exp("not-a-jwt"), 0)
	eq(TokenLogic.jwt_claims(_jwt({"sub": "42"}))["sub"], "42")


func test_needs_refresh() -> void:
	check(not TokenLogic.needs_refresh(1000, 900), "plenty of time left")
	check(TokenLogic.needs_refresh(1000, 975), "inside the skew window")
	check(TokenLogic.needs_refresh(1000, 1200), "expired")
	check(not TokenLogic.needs_refresh(0, 1200), "unknown expiry: wait for a 401")


func test_storage_key() -> void:
	eq(TokenLogic.storage_key("dev-a"), TokenLogic.storage_key("dev-a"))
	check(TokenLogic.storage_key("dev-a") != TokenLogic.storage_key("dev-b"))
	eq(TokenLogic.storage_key("x").length(), 64)


func test_refresh_before_expiry() -> void:
	Mock.reset()
	Session.clear()
	await Api.auth_link("ABCD1234")
	# make the access token about to expire
	Session.set_tokens(_jwt({"sub": "1", "exp": int(Time.get_unix_time_from_system()) + 5}), "")
	var old := Session.access_token
	var r := await Api.command("player.profile.get")
	check(r.get("ok", false), "command worked")
	check(Session.access_token != old, "access token was refreshed first")


func test_refresh_after_401() -> void:
	Mock.reset()
	Session.clear()
	await Api.auth_link("ABCD1234")
	# expired, but its exp claim is missing, so only the server's 401 tells
	Session.access_token = "expired.token.value"
	Session.access_exp = 0
	var r := await Api.command("bank.show")
	check(r.get("ok", false), "retried after refresh")
	eq(r.get("screen", ""), "bank")


func test_refused_refresh_logs_out() -> void:
	Mock.reset()
	Session.clear()
	await Api.auth_link("ABCD1234")
	Session.refresh_token = "stolen"
	Session.access_token = "expired.token.value"
	Session.access_exp = 1
	var r := await Api.command("bank.show")
	check(not r.get("ok", true), "command refused")
	eq(Session.refresh_token, "", "session cleared")


func test_tokens_persist_encrypted() -> void:
	Mock.reset()
	Session.clear()
	await Api.auth_link("ABCD1234")
	var rt := Session.refresh_token
	var raw := FileAccess.get_file_as_bytes(Session.STORE)
	check(raw.size() > 0, "file written")
	check(not raw.get_string_from_utf8().contains(rt), "token is not stored in the clear")
	Session.refresh_token = ""
	Session._load()
	eq(Session.refresh_token, rt, "read back")
