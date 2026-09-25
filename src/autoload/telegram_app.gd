extends Node
## Running inside Telegram as a Mini App (https://core.telegram.org/bots/webapps).
##
## The web export's HTML shell (web/shell.html) loads telegram-web-app.js in
## <head>, so window.Telegram.WebApp exists before the engine starts. Here we:
##   * read WebApp.initData (the signed query string the server validates with
##     the bot token — the client never trusts initDataUnsafe for anything but
##     the default language);
##   * call ready(), expand(), and disableVerticalSwipes() where supported, so
##     dragging the city map does not close the app;
##   * adopt the Telegram theme's background and the safe-area insets
##     (safeAreaInset + contentSafeAreaInset, Bot API 8.0+);
##   * listen for themeChanged / safeAreaChanged / contentSafeAreaChanged.
## Outside Telegram (desktop, Android, a plain browser) `available` is false.
## In mock mode with mock_telegram on, a fixture initData stands in.

signal insets_changed(insets: Dictionary)
signal theme_changed(params: Dictionary)

const MOCK_INIT_DATA := "query_id=AAHmock&user=%7B%22id%22%3A424242%2C%22first_name%22%3A%22Sara%22%2C%22language_code%22%3A%22fa%22%7D&auth_date=1790000000&signature=mock&hash=0f0e0d0c0b0a09080706050403020100"

var available := false
var init_data := ""
var language_code := ""
var platform := ""
var version := ""
var theme_params := {}
var insets := {"top": 0, "bottom": 0, "left": 0, "right": 0}

var _webapp: JavaScriptObject
var _callbacks := []


func _ready() -> void:
	if OS.has_feature("web"):
		_init_web()
	elif Config.mock and Config.mock_telegram:
		_init_mock()


func _init_mock() -> void:
	available = true
	init_data = MOCK_INIT_DATA
	language_code = "fa"
	platform = "mock"
	version = "9.0"


func _init_web() -> void:
	var tg = JavaScriptBridge.get_interface("Telegram")
	if tg == null:
		if Config.mock and Config.mock_telegram:
			_init_mock()
		return
	_webapp = tg.WebApp
	if _webapp == null:
		return
	init_data = str(_webapp.initData) if _webapp.initData != null else ""
	available = init_data != ""
	if not available:
		if Config.mock and Config.mock_telegram:
			_init_mock()
		return
	platform = str(_webapp.platform)
	version = str(_webapp.version)
	var unsafe = _webapp.initDataUnsafe
	if unsafe != null and unsafe.user != null and unsafe.user.language_code != null:
		language_code = str(unsafe.user.language_code)
	_webapp.ready()
	_webapp.expand()
	if _at_least("7.7"):
		_webapp.disableVerticalSwipes()
	_read_theme()
	_read_insets()
	_on("themeChanged", func(_a): _read_theme())
	_on("safeAreaChanged", func(_a): _read_insets())
	_on("contentSafeAreaChanged", func(_a): _read_insets())
	_on("viewportChanged", func(_a): _read_insets())


func _at_least(v: String) -> bool:
	return _webapp != null and bool(_webapp.isVersionAtLeast(v))


func _on(event: String, fn: Callable) -> void:
	var cb := JavaScriptBridge.create_callback(fn)
	_callbacks.append(cb)  # keep a reference or JS drops it
	_webapp.onEvent(event, cb)


func _read_theme() -> void:
	var tp = _webapp.themeParams
	theme_params = {}
	if tp != null:
		for k in ["bg_color", "text_color", "hint_color", "button_color", "button_text_color",
				"secondary_bg_color", "header_bg_color", "accent_text_color", "section_bg_color"]:
			var v = tp[k]
			if v != null:
				theme_params[k] = str(v)
	# Match Telegram's chrome to the game's night palette rather than the
	# user's theme: the game art is designed on dark.
	if _at_least("6.1"):
		_webapp.setHeaderColor(AppTheme.col("ink").to_html(false))
		_webapp.setBackgroundColor(AppTheme.col("ink").to_html(false))
	theme_changed.emit(theme_params)


func _read_insets() -> void:
	var out := {"top": 0, "bottom": 0, "left": 0, "right": 0}
	for key in ["safeAreaInset", "contentSafeAreaInset"]:
		var v = _webapp[key]
		if v != null:
			for side in out:
				var n = v[side]
				if n != null:
					out[side] += int(n)
	insets = out
	insets_changed.emit(insets)


## Insets in the game's canvas units (the canvas is scaled to the window).
func canvas_insets(viewport: Viewport) -> Dictionary:
	var ratio := 1.0
	if OS.has_feature("web"):
		var css_w = JavaScriptBridge.eval("window.innerWidth", true)
		if css_w and float(css_w) > 0:
			ratio = viewport.get_visible_rect().size.x / float(css_w)
	var out := {}
	for side in insets:
		out[side] = insets[side] * ratio
	return out


## Open a t.me link inside Telegram (e.g. the bot, to run /link).
func open_telegram_link(url: String) -> void:
	if _webapp != null:
		_webapp.openTelegramLink(url)
	else:
		OS.shell_open(url)


func haptic(kind := "light") -> void:
	if _webapp != null and _at_least("6.1") and _webapp.HapticFeedback != null:
		_webapp.HapticFeedback.impactOccurred(kind)
