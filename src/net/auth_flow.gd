class_name AuthFlow
extends RefCounted
## Which way a start-up logs in. Pure; unit-tested in tests/test_auth_flow.gd.
##
##   TELEGRAM  inside Telegram as a Mini App with signed initData: log in with it
##             (POST /api/v1/auth/telegram) — no code to type.
##   REFRESH   a refresh token is stored: renew the session silently.
##   LINK      nothing to go on: show the link-code screen (/link in the bot).
##
## A stored session is tried first: the server accepts Mini App sign-in data
## only once (replays are refused), so after the first sign-in the refresh token
## is what keeps the player in. If that refresh is refused, initData is next
## (Game.boot), then the code screen.

enum Method { TELEGRAM, REFRESH, LINK }


static func decide(init_data: String, stored_refresh: String) -> Method:
	if stored_refresh != "":
		return Method.REFRESH
	if is_plausible_init_data(init_data):
		return Method.TELEGRAM
	return Method.LINK


## The server validates the signature; the client only checks the shape, so a
## plain browser (empty string) or a stray "#tgWebAppData" fragment does not
## trigger a doomed call.
static func is_plausible_init_data(init_data: String) -> bool:
	return init_data.contains("hash=") and (init_data.contains("auth_date=") or init_data.contains("user="))


## Zero-width marks a chat app copies along with a code: LRM, RLM, the bidi
## embeddings and isolates, and the byte-order mark.
const INVISIBLE_MARKS := ["\u200e", "\u200f", "\u202a", "\u202b", "\u202c", "\u202d", "\u202e",
	"\u2066", "\u2067", "\u2068", "\u2069", "\ufeff"]


## A link code as the player may type it: 8 letters/digits, any case, spaces,
## dashes and Persian digits tolerated, and the invisible bidi marks a
## right-to-left chat wraps a Latin run in (copied along with the code).
## Returns "" when it cannot be one.
static func normalize_code(raw: String) -> String:
	var s := Fmt.to_latin(raw).strip_edges().to_upper().replace(" ", "").replace("-", "")
	for mark in INVISIBLE_MARKS:
		s = s.replace(mark, "")
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
