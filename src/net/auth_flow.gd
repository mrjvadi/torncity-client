class_name AuthFlow
extends RefCounted
## Which way a start-up logs in. Pure; unit-tested in tests/test_auth_flow.gd.
##
##   TELEGRAM  inside Telegram as a Mini App with signed initData: log in with it
##             (POST /api/v1/auth/telegram) — no code to type.
##   REFRESH   a refresh token is stored: renew the session silently.
##   LINK      nothing to go on: show the link-code screen (/link in the bot).
##
## initData wins over a stored session: it names the Telegram user who opened
## the app right now, which may not be whoever logged in on this device before.

enum Method { TELEGRAM, REFRESH, LINK }


static func decide(init_data: String, stored_refresh: String) -> Method:
	if is_plausible_init_data(init_data):
		return Method.TELEGRAM
	if stored_refresh != "":
		return Method.REFRESH
	return Method.LINK


## The server validates the signature; the client only checks the shape, so a
## plain browser (empty string) or a stray "#tgWebAppData" fragment does not
## trigger a doomed call.
static func is_plausible_init_data(init_data: String) -> bool:
	return init_data.contains("hash=") and (init_data.contains("auth_date=") or init_data.contains("user="))


## A link code as the player may type it: 8 letters/digits, any case, spaces,
## dashes and Persian digits tolerated. Returns "" when it cannot be one.
static func normalize_code(raw: String) -> String:
	var s := Fmt.to_latin(raw).strip_edges().to_upper().replace(" ", "").replace("-", "")
	if s.length() != 8:
		return ""
	for ch in s:
		if not ((ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9")):
			return ""
	return s


## After a failed login attempt, what to do next.
## A rejected Telegram login (401/403) falls back to the code screen; a network
## failure keeps the method and offers a retry.
static func after_failure(method: Method, http_status: int) -> Method:
	if http_status == 0 or http_status >= 500:
		return method
	return Method.LINK
