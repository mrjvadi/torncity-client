extends TestCase


func test_decide() -> void:
	var tg := TelegramApp.MOCK_INIT_DATA
	eq(AuthFlow.decide(tg, ""), AuthFlow.Method.TELEGRAM)
	eq(AuthFlow.decide(tg, "stored"), AuthFlow.Method.REFRESH, "initData is single use: a stored session goes first")
	eq(AuthFlow.decide("", "stored"), AuthFlow.Method.REFRESH)
	eq(AuthFlow.decide("", ""), AuthFlow.Method.LINK)
	eq(AuthFlow.decide("tgWebAppVersion=7.0", ""), AuthFlow.Method.LINK, "no signature, no Telegram login")


func test_after_failure() -> void:
	eq(AuthFlow.after_failure(AuthFlow.Method.TELEGRAM, 401), AuthFlow.Method.LINK)
	eq(AuthFlow.after_failure(AuthFlow.Method.TELEGRAM, 0), AuthFlow.Method.TELEGRAM, "offline: retry")
	eq(AuthFlow.after_failure(AuthFlow.Method.REFRESH, 503), AuthFlow.Method.REFRESH)


func test_normalize_code() -> void:
	eq(AuthFlow.normalize_code("abcd-1234"), "ABCD1234")
	eq(AuthFlow.normalize_code(" ab cd ۱۲۳۴ "), "ABCD1234")
	eq(AuthFlow.normalize_code("\u2068DVLKJAUH\u2069"), "DVLKJAUH")
	eq(AuthFlow.normalize_code("\u200fdvlk-jauh\u200e"), "DVLKJAUH")
	eq(AuthFlow.normalize_code("ABC123"), "")
	eq(AuthFlow.normalize_code("ABCD123!"), "")


func test_telegram_mock_login() -> void:
	Mock.reset()
	Session.clear()
	TelegramApp._init_mock()
	check(TelegramApp.available)
	var ok := await Game.boot()
	check(ok, "Mini App initData logged in without a code")
	check(Session.refresh_token != "")
	TelegramApp.available = false
	TelegramApp.init_data = ""
	Realtime.stop()


func test_no_telegram_no_session_needs_code() -> void:
	Mock.reset()
	Session.clear()
	TelegramApp.available = false
	TelegramApp.init_data = ""
	var ok := await Game.boot()
	check(not ok, "falls back to the link screen")
