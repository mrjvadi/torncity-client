extends GameScreen
## «Me»: the player's card, level, whereabouts, money, vitals, work and needs.

var _walk_label: Label


func build() -> void:
	scroll_body(18)
	var v := view
	var hero := GlowPanel.new()
	hero.top_color = Color("#1F3150")
	hero.bottom_color = Color("#132139")
	hero.accent = AppTheme.col("blue", 0.8)
	hero.padding = 24
	var hbox := UI.hbox(20)
	var av := AvatarBadge.new()
	av.diameter = 150
	av.ring = AppTheme.col("saffron")
	av.set_avatar(str(v.get("avatar", "")), str(v.get("name", "")), 0)
	hbox.add_child(av)
	var who := UI.vbox(6)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.add_child(UI.label(str(v.get("name", "")), "TitleLabel"))
	var rank = v.get("rank")
	if rank is Dictionary:
		who.add_child(UI.hbox(8, [UI.icon("rank", 30), UI.label(TextIcons.strip(str(rank.get("name", ""))), "SmallLabel")]))
	var code := str(v.get("code", ""))
	if code != "":
		who.add_child(UI.chip("profile", I18n.t("profile.code", {"code": Fmt.isolate(code)})))
	hbox.add_child(who)
	var hv := UI.vbox(16, [hbox])
	# level progress
	var lvl := int(v.get("level", 0))
	var xp := int(v.get("xp", 0))
	var nxt := int(v.get("next_level_xp", 0))
	var lrow := UI.hbox(10, [UI.icon("level", 34), UI.label(I18n.t("profile.level", {"level": lvl}), "HeadLabel")])
	lrow.add_child(UI.spacer())
	if nxt > 0:
		lrow.add_child(UI.label(I18n.t("profile.xp_to_next", {"xp": maxi(0, nxt - xp)}), "DimLabel"))
	hv.add_child(lrow)
	if nxt > 0:
		var bar := StatBar.new()
		bar.icon_name = "xp"
		bar.color = AppTheme.col("blue")
		bar.set_value(xp, nxt, I18n.of(xp, nxt))
		hv.add_child(bar)
	hero.add_child(hv)
	content.add_child(hero)
	maybe_notice()

	# whereabouts
	var where := card(I18n.t("profile.where"), "pin")
	var place = v.get("place")
	var city := I18n.name_of("city", str(v.get("city_code", "")), str(v.get("city", "")))
	if v.get("travelling", false):
		where.add_child(UI.label(I18n.t("profile.travelling", {"city": str(v.get("travel_to", "")), "left": I18n.dur(secs("travel_remaining_seconds"))}), "", -1, true))
	elif v.get("walk") is Dictionary:
		var w: Dictionary = v["walk"]
		_walk_label = UI.label("", "", -1, true)
		_walk_label.set_meta("walk", w)
		_update_walk()
		where.add_child(_walk_label)
	elif place is Dictionary:
		where.add_child(UI.label("%s - %s" % [I18n.name_of("place", str(place.get("code", "")), str(place.get("name", ""))), city], "", -1, true))
	var go := UI.button(I18n.t("nav.city"), "map", "GhostButton", func(): shell.open_tab("city"))
	where.add_child(go)

	# money & vitals tiles
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.add_child(_tile("cash", I18n.t("stat.cash"), I18n.money(int(v.get("cash", 0))), "saffron"))
	grid.add_child(_tile("bank", I18n.t("stat.bank"), I18n.money(int(v.get("bank", 0))), "sky"))
	grid.add_child(_tile("energy", I18n.t("stat.energy"), I18n.of(int(v.get("energy", 0)), int(v.get("max_energy", 100))), "saffron"))
	grid.add_child(_tile("health", I18n.t("stat.health"), I18n.of(int(v.get("health", 0)), int(v.get("max_health", 100))), "pomegranate"))
	content.add_child(grid)

	# work
	var work = v.get("work")
	var wc := card(I18n.t("nav.work"), "work")
	if work is Dictionary and work.get("job") is Dictionary:
		var j: Dictionary = work["job"]
		var jj: Dictionary = j.get("job", {})
		wc.add_child(UI.label(I18n.t("profile.job", {"title": str(jj.get("title", "")), "pay": I18n.money(int(j.get("pay", 0)))}), "", -1, true))
		var left := int(j.get("shift_ends_in_seconds", 0))
		if left > 0:
			wc.add_child(UI.label(I18n.t("job.shift_left", {"left": I18n.dur(left)}), "DimLabel"))
	else:
		wc.add_child(UI.label(I18n.t("profile.no_job"), "DimLabel", -1, true))

	# needs
	var needs = v.get("needs")
	if needs is Dictionary:
		var nc := card(I18n.t("life.needs"), "life")
		for n in [["hunger", "brick", true], ["sleep", "violet", true], ["stress", "rose", true], ["happiness", "leaf", false]]:
			var b := StatBar.new()
			b.icon_name = n[0]
			b.color = AppTheme.col(n[1])
			b.invert = n[2]
			b.set_value(float(needs.get(n[0], 0)), 100.0, "%s - %s" % [I18n.t("need." + n[0]), I18n.num(int(needs.get(n[0], 0)))])
			nc.add_child(b)

	# shortcuts
	var links := GridContainer.new()
	links.columns = 3
	links.add_theme_constant_override("h_separation", 12)
	links.add_theme_constant_override("v_separation", 12)
	for s in [["life", "more.life", "life.me"], ["inventory", "more.inventory", "inventory.show"], ["skills", "more.skills", "skills.list"],
			["friends", "more.friends", "social.friend.list"], ["achievement", "more.achievements", "achievement.list"], ["settings", "more.settings", ""]]:
		links.add_child(Tiles.feature(s[0], I18n.t(s[1]), s[2], shell))
	content.add_child(links)
	var acts: Array = resp.get("actions", [])
	var extra := actions_grid(acts, ["map.list", "bank.show", "skills.list", "social.friend.list", "player.settings"])
	if extra.get_child_count() > 0:
		content.add_child(extra)
	Fx.stagger_in(content)


func _tile(icon_name: String, label: String, value: String, color: String) -> Control:
	var p := GlowPanel.new()
	p.padding = 18
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := UI.vbox(4)
	box.add_child(UI.hbox(10, [UI.icon(icon_name, 40), UI.label(label, "DimLabel")]))
	var l := UI.label(value, "HeadLabel")
	l.add_theme_color_override("font_color", AppTheme.col(color).lightened(0.15))
	box.add_child(l)
	p.add_child(box)
	return p


func _update_walk() -> void:
	if _walk_label == null:
		return
	var w: Dictionary = _walk_label.get_meta("walk")
	var to: Dictionary = w.get("to", {})
	var left := Fmt.seconds_until(str(w.get("arrives_at", "")), Time.get_unix_time_from_system())
	if left <= 0:
		left = int(w.get("remaining_seconds", 0))
	_walk_label.text = I18n.t("map.walking", {"place": I18n.name_of("place", str(to.get("code", "")), str(to.get("name", ""))), "left": I18n.dur(maxi(0, left))})


func tick() -> void:
	_update_walk()
