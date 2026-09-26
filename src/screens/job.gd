extends GameScreen
## «Work»: the job, its pay and performance, and the shift in progress.

var _ring: Ring
var _shift_end := 0.0
var _shift_total := 0


func build() -> void:
	scroll_body(18)
	var v := view
	content.add_child(title_row(I18n.t("nav.work"), "work"))
	maybe_notice()
	if not v.get("employed", false):
		content.add_child(notice_banner(I18n.t("job.none"), "warn"))
		content.add_child(actions_grid(resp.get("actions", []), [], 1))
		return
	var j: Dictionary = v.get("job", {}) if v.get("job") is Dictionary else {}
	var hero := GlowPanel.new()
	hero.top_color = Color("#1F3150")
	hero.bottom_color = Color("#132139")
	hero.accent = AppTheme.col("brick")
	hero.padding = 24
	var hv := UI.vbox(10)
	hv.add_child(UI.hbox(12, [UI.icon("work", 56), UI.label(str(j.get("title", "")), "TitleLabel")]))
	hv.add_child(UI.label("%s - %s" % [str(v.get("employer", "")), str(j.get("career_name", ""))], "DimLabel", -1, true))
	hv.add_child(UI.hbox(10, [UI.icon("moneybag", 36), UI.label(I18n.t("job.pay", {"pay": I18n.money(int(v.get("pay", 0)))}), "MoneyLabel")]))
	hero.add_child(hv)
	content.add_child(hero)

	var row := UI.hbox(16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_ring = Ring.new()
	_ring.icon_name = "hourglass"
	_ring.color = AppTheme.col("blue")
	_ring.custom_minimum_size = Vector2(230, 270)
	var sh = v.get("shift")
	if sh is Dictionary:
		_shift_total = maxi(1, int(sh.get("total_seconds", v.get("shift_length_seconds", 60))))
		_shift_end = Time.get_unix_time_from_system() + int(sh.get("remaining_seconds", 0))
	row.add_child(_ring)
	var perf := Ring.new()
	perf.icon_name = "chart"
	perf.color = AppTheme.col("leaf")
	perf.custom_minimum_size = Vector2(230, 270)
	perf.set_value(int(v.get("performance", 0)) / 100.0, I18n.num(int(v.get("performance", 0))), I18n.t("job.performance"))
	row.add_child(perf)
	content.add_child(row)
	tick()

	var facts := card(I18n.t("job.details"), "info")
	facts.add_child(_fact("energy", I18n.t("job.energy_cost"), I18n.num(int(v.get("energy_cost", 0)))))
	var wp = v.get("workplace")
	if wp is Dictionary:
		facts.add_child(_fact("pin", I18n.t("job.workplace"), I18n.name_of("place", str(wp.get("code", "")), str(wp.get("name", "")))))
	facts.add_child(_fact("moneybag", I18n.t("job.total"), I18n.money(int(v.get("total_earned", 0)))))
	var nxt = v.get("next")
	if nxt is Dictionary and nxt.has("title"):
		facts.add_child(_fact("promotion", I18n.t("job.next"), str(nxt.get("title", ""))))
	var acts: Array = resp.get("actions", [])
	content.add_child(actions_grid(acts, ["job.status"], 1))
	Fx.stagger_in(content)


func _fact(icon_name: String, k: String, val: String) -> Control:
	var h := UI.hbox(10, [UI.icon(icon_name, 32), UI.label(k, "DimLabel"), UI.spacer(), UI.label(val, "SmallLabel")])
	return h


func tick() -> void:
	if _ring == null:
		return
	if _shift_end > 0:
		var left := maxi(0, int(_shift_end - Time.get_unix_time_from_system()))
		_ring.set_value(1.0 - float(left) / _shift_total, I18n.dur(left), I18n.t("job.shift"))
		if left == 0:
			_shift_end = 0
			Game.refresh_current()
	else:
		_ring.set_value(0.0, "—", I18n.t("job.no_shift"))
