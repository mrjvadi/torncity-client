extends GameScreen
## Settings: language, connection (mock or a live server), session.


func build() -> void:
	scroll_body(18)
	content.add_child(title_row(I18n.t("more.settings"), "settings", false))

	var lang := card(I18n.t("settings.language"), "language")
	var lrow := UI.hbox(12)
	for l in I18n.LANGS:
		var b := UI.button(I18n.LANGS[l], "", "Button" if l == I18n.lang else "GhostButton")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): await Game.switch_language(l); shell.open_local("settings"))
		lrow.add_child(b)
	lang.add_child(lrow)

	var conn := card(I18n.t("settings.connection"), "phone")
	var mock := CheckButton.new()
	mock.text = I18n.t("settings.mock")
	mock.button_pressed = Config.mock
	mock.focus_mode = Control.FOCUS_NONE
	conn.add_child(mock)
	conn.add_child(UI.label(I18n.t("settings.api"), "DimLabel"))
	var api := LineEdit.new()
	api.text = Config.api_url
	api.add_theme_font_size_override("font_size", 24)
	api.text_direction = Control.TEXT_DIRECTION_LTR
	conn.add_child(api)
	conn.add_child(UI.label(I18n.t("settings.ws"), "DimLabel"))
	var ws := LineEdit.new()
	ws.text = Config.realtime_url
	ws.add_theme_font_size_override("font_size", 24)
	ws.text_direction = Control.TEXT_DIRECTION_LTR
	conn.add_child(ws)
	var rt := UI.label(I18n.t("settings.realtime", {"state": I18n.t("rt." + Realtime._state_name())}), "DimLabel")
	conn.add_child(rt)
	conn.add_child(UI.button(I18n.t("settings.apply"), "check", "", func():
		var changed := Config.mock != mock.button_pressed or Config.api_url != api.text.strip_edges()
		Config.mock = mock.button_pressed
		Config.api_url = api.text.strip_edges().trim_suffix("/")
		Config.realtime_url = ws.text.strip_edges()
		Config.save_user()
		if changed:
			await Api.logout()
		else:
			Realtime.stop()
			Realtime.start()))

	var acct := card(I18n.t("settings.account"), "profile")
	if Session.player.has("code"):
		acct.add_child(UI.label(I18n.t("profile.code", {"code": Fmt.isolate(str(Session.player["code"]))}), "SmallLabel"))
	acct.add_child(UI.button(I18n.t("settings.game_settings"), "settings", "GhostButton", func(): Game.run("player.settings")))
	acct.add_child(UI.button(I18n.t("settings.logout"), "close", "DangerButton", func(): await Api.logout()))

	var about := card(I18n.t("settings.about"), "info")
	about.add_child(UI.label(I18n.t("settings.version", {"v": Config.VERSION}), "DimLabel", -1, true))
	about.add_child(UI.label(I18n.t("settings.credits"), "DimLabel", -1, true))
	Fx.stagger_in(content)
