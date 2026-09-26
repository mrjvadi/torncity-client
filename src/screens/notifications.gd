extends GameScreen
## The feed of realtime notices and city announcements, newest first.


func build() -> void:
	Session.mark_read()
	scroll_body(12)
	content.add_child(title_row(I18n.t("more.notifications"), "bell", false))
	if Session.notices.is_empty():
		var empty := UI.vbox(10)
		empty.alignment = BoxContainer.ALIGNMENT_CENTER
		var ic := UI.icon("bell", 120)
		ic.modulate = Color(1, 1, 1, 0.35)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		empty.add_child(UI.gap(80))
		empty.add_child(ic)
		empty.add_child(UI.label(I18n.t("feed.empty"), "DimLabel", HORIZONTAL_ALIGNMENT_CENTER, true))
		content.add_child(empty)
		return
	var now := Time.get_unix_time_from_system()
	for n in Session.notices:
		var p := GlowPanel.new()
		p.padding = 18
		p.shadow = 8
		var text := str(n.get("text", ""))
		var kind := str(n.get("kind", ""))
		if kind == "announce":
			p.accent = AppTheme.col("saffron")
		var ic := TextIcons.lead_icon(text)
		var row := UI.hbox(14, [UI.icon(ic if ic != "" else ("bell" if kind == "announce" else "info"), 48)])
		var col := UI.vbox(4)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(UI.rich(TextIcons.strip(text) if ic != "" else text, 24))
		col.add_child(UI.label(I18n.t("feed.ago", {"when": I18n.dur(int(now - float(n.get("at", now))))}), "DimLabel"))
		row.add_child(col)
		p.add_child(row)
		var swipe := SwipeRow.make(p, [])
		swipe.actions = [{"label": I18n.t("feed.dismiss"), "key": "action:dismiss",
			"color": AppTheme.col("red"), "fn": func(): _dismiss(swipe, n)}]
		content.add_child(swipe)
	Fx.stagger_in(content, 0.03)


func _dismiss(row: SwipeRow, n: Dictionary) -> void:
	Session.dismiss_notice(n)
	if Config.headless_capture:
		row.queue_free()
		return
	var t := create_tween()
	t.tween_property(row, "modulate:a", 0.0, 0.16)
	t.parallel().tween_property(row, "collapse", 0.0, 0.16).set_delay(0.05)
	t.tween_callback(row.queue_free)
