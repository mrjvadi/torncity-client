extends Node
## The client shell's language: its own UI strings (i18n/*.po, keys like
## "nav.city"), number formatting and layout direction. Game text is already
## localised by the server; the server is told the language on login and by
## player.language.set.

signal changed(lang: String)

const LANGS := {"fa": "فارسی", "en": "English"}

var lang := "fa"


func _ready() -> void:
	lang = Config.lang if LANGS.has(Config.lang) else "fa"
	TranslationServer.set_locale(lang)


func set_lang(l: String, persist := true) -> void:
	if not LANGS.has(l):
		return
	var was := lang
	lang = l
	TranslationServer.set_locale(l)
	if persist:
		Config.lang = l
		Config.save_user()
	if was != l:
		changed.emit(l)


func is_rtl() -> bool:
	return Fmt.is_rtl(lang)


## A shell string with {placeholders} filled (numbers in the language's digits).
func t(key: String, params := {}) -> String:
	var s := String(TranslationServer.translate(key))
	if s == key:
		# Missing in this language: fall back to English, then to the key.
		var en := TranslationServer.get_translation_object("en")
		if en:
			var e := String(en.get_message(key))
			if e != "":
				s = e
	return Fmt.fill(s, params, lang) if not params.is_empty() else s


func num(n: int) -> String:
	return Fmt.number(n, lang)


func money(n: int) -> String:
	return Fmt.money(n, lang)


func money_short(n: int) -> String:
	return Fmt.money_short(n, lang)


func dur(seconds: int) -> String:
	return Fmt.duration(seconds, lang)


func of(v: int, m: int) -> String:
	return Fmt.of(v, m, lang)


func digits(s: String) -> String:
	return Fmt.digits(s, lang)


func direction() -> Control.LayoutDirection:
	return Control.LAYOUT_DIRECTION_RTL if is_rtl() else Control.LAYOUT_DIRECTION_LTR


func text_direction() -> Control.TextDirection:
	return Control.TEXT_DIRECTION_RTL if is_rtl() else Control.TEXT_DIRECTION_LTR


## Horizontal alignment of the start of a line. Controls laid out RTL mirror
## LEFT/RIGHT themselves, so "start" is always LEFT.
func start_align() -> HorizontalAlignment:
	return HORIZONTAL_ALIGNMENT_LEFT


## A localised name from the bootstrap's tables (cities, places, modes...), or the fallback.
func name_of(table: String, code: String, fallback := "") -> String:
	var t: Dictionary = Session.names.get(table, {})
	if t.has(code):
		return str(t[code])
	return fallback if fallback != "" else code.capitalize()
