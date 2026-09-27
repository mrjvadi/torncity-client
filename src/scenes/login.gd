extends Control
## Linking a device: the player sends /link to the bot and types the 8-char
## code here. Inside Telegram (Mini App) this screen is skipped — initData
## logs in — unless that login was refused.

signal done

var _code: LineEdit
var _last_prompt := -10000
var _error: Label
var _go: Button


func _ready() -> void:
	Game.mark("login shown")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	layout_direction = I18n.direction()
	var art := TextureRect.new()
	art.texture = AppTheme.tex("brand/splash")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.modulate = Color(0.55, 0.55, 0.7)
	add_child(art)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.07, 0.09, 0.16, 0.35)
	add_child(shade)

	# language toggle, top corner
	var langs := UI.hbox(8)
	langs.set_anchors_preset(Control.PRESET_TOP_RIGHT if not I18n.is_rtl() else Control.PRESET_TOP_LEFT)
	langs.position = Vector2(24, 24)
	for l in I18n.LANGS:
		var b := UI.button(I18n.LANGS[l], "language" if l == I18n.lang else "", "Button" if l == I18n.lang else "GhostButton")
		b.custom_minimum_size = Vector2(150, 70)
		b.pressed.connect(func():
			I18n.set_lang(l)
			get_parent().show_login())
		langs.add_child(b)
	add_child(langs)

	var col := UI.vbox(18)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 36
	col.offset_right = -36
	col.offset_top = 120
	col.offset_bottom = -40
	add_child(col)
	var logo := UI.tex(AppTheme.tex("brand/logo"), Vector2(190, 190))
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(logo)
	var title := UI.label(I18n.t("app.name"), "HugeLabel", HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(title)
	col.add_child(UI.label(I18n.t("login.subtitle"), "SmallLabel", HORIZONTAL_ALIGNMENT_CENTER, true))
	col.add_child(UI.gap(10))

	var card := GlowPanel.new()
	card.accent = AppTheme.col("primary")
	card.padding = 28
	var box := UI.vbox(18)
	box.add_child(UI.hbox(12, [UI.icon("phone", 48), UI.label(I18n.t("login.title"), "HeadLabel")]))
	var steps := UI.vbox(8)
	for i in 3:
		var n := UI.label(I18n.num(i + 1), "HeadLabel", HORIZONTAL_ALIGNMENT_CENTER)
		n.custom_minimum_size = Vector2(44, 44)
		n.add_theme_color_override("font_color", AppTheme.col("saffron"))
		var row := UI.hbox(12, [n, UI.label(I18n.t("login.step%d" % (i + 1)), "", -1, true)])
		steps.add_child(row)
	box.add_child(steps)
	_code = LineEdit.new()
	_code.placeholder_text = "ABCD1234"
	_code.max_length = 12
	_code.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code.text_direction = Control.TEXT_DIRECTION_LTR
	_code.add_theme_font_size_override("font_size", 48)
	_code.add_theme_constant_override("minimum_character_width", 8)
	_code.custom_minimum_size = Vector2(0, 104)
	_code.text_submitted.connect(func(_t): _submit())
	_code.text_changed.connect(func(t):
		var up: String = t.to_upper()
		if up != t:
			var c := _code.caret_column
			_code.text = up
			_code.caret_column = c
		_error.text = "")
	box.add_child(_code)
	_code.focus_entered.connect(func(): Game.mark("code focus"))
	# A phone's web view hands a canvas text field its keyboard unreliably (an
	# iPhone may not show one at all); there the browser's own prompt takes the
	# code, pasting included, and signs in at once.
	if Config.phone_web():
		_code.editable = false
		# a tap arrives twice (the touch, and the mouse press emulated from
		# it): one prompt per tap
		_code.gui_input.connect(func(e):
			if (e is InputEventScreenTouch or e is InputEventMouseButton) and not e.pressed:
				var now := Time.get_ticks_msec()
				if now - _last_prompt > 800:
					_last_prompt = now
					_ask_code())
	_error = UI.label("", "SmallLabel", HORIZONTAL_ALIGNMENT_CENTER, true)
	_error.add_theme_color_override("font_color", AppTheme.col("rose"))
	box.add_child(_error)
	_go = UI.button(I18n.t("login.enter"), "check", "", _submit)
	box.add_child(_go)
	if Config.mock:
		box.add_child(UI.label(I18n.t("login.mock_hint"), "DimLabel", HORIZONTAL_ALIGNMENT_CENTER, true))
	card.add_child(box)
	col.add_child(card)
	Fx.stagger_in(col, 0.06)


func _ask_code() -> void:
	Game.mark("code prompt")
	var got = JavaScriptBridge.eval("window.prompt(%s, '') || ''" % JSON.stringify(I18n.t("login.step3")), true)
	# the page stood still while the prompt was up: the tap's second event
	# (the emulated mouse press) arrives only now, and must not ask again
	_last_prompt = Time.get_ticks_msec()
	if got is String and (got as String).strip_edges() != "":
		_code.text = (got as String).strip_edges().to_upper()
		_submit()


func _submit() -> void:
	var code := AuthFlow.normalize_code(_code.text)
	# never the code itself: only whether it read as one, and its length
	Game.mark("code submit ok=%s len=%d" % [code != "", _code.text.length()])
	if code == "":
		_error.text = I18n.t("login.bad_format")
		Fx.pulse(_code, Color(1.5, 0.7, 0.7))
		return
	_go.disabled = true
	_go.text = I18n.t("login.checking")
	var r := await Game.login_with_code(code)
	_go.disabled = false
	_go.text = I18n.t("login.enter")
	if r.status != 200:
		var msg := ""
		if r.data is Dictionary and r.data.get("error") is Dictionary:
			msg = str(r.data["error"].get("message", ""))
		_error.text = msg if msg != "" else (I18n.t("error.network") if r.status == 0 else I18n.t("login.rejected"))
		return
	done.emit()


## For screenshots and tests: pre-fill a code.
func prefill(code: String) -> void:
	_code.text = code
