extends Control
## Renders the key screens to PNG (docs/screenshots/<lang>/<name>.png) in mock
## mode. Needs a real renderer (not --headless): run through dev/screenshots.sh,
## which starts a virtual X display when there is none.
##   godot --path . --resolution 720x1280 res://dev/screenshots.tscn -- --out=docs/screenshots --langs=fa,en

const SHOTS := [
	["splash", "", {}],
	["login", "", {}],
	["city", "map.list", {}],
	["city_walking", "place.go", {"place": "bazaar"}],
	["company", "company.show", {"id": 1027}],
	["confirm", "company.show", {"id": 1027}],
	["companies", "company.list", {}],
	["market", "market.list", {}],
	["crime", "crime.hub", {}],
	["education", "education.list", {}],
	["inventory", "inventory.show", {}],
	["inventory_empty", "inventory.show", {}],
	["profile", "player.profile.get", {}],
	["bank", "bank.show", {}],
	["job", "job.status", {}],
	["life", "life.me", {}],
	["card", "skills.list", {}],
	["cities", "map.cities", {}],
	["travel_options", "travel.options", {"city": "brennhaven"}],
	["toast", "map.list", {}],
	["notifications", "@notifications", {}],
	["notifications_empty", "@notifications", {}],
	["settings", "@settings", {}],
	["credits", "@credits", {}],
	["menu", "@menu", {}],
]

var out_dir := "docs/screenshots"
var langs := ["fa", "en"]
var only := []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--langs="):
			langs = Array(a.substr(8).split(","))
		elif a.begins_with("--only="):
			only = Array(a.substr(7).split(","))
	Config.headless_capture = true
	Config.mock = true
	Mock.latency = 0.0
	await _run()
	get_tree().quit()


func _frames(n := 3) -> void:
	for i in n:
		await get_tree().process_frame


func _save(lang: String, name: String) -> void:
	await _frames(4)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var dir := "%s/%s" % [out_dir, lang]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + dir) if not dir.begins_with("/") else dir)
	var path := ("res://%s/%s.png" % [dir, name]) if not dir.begins_with("/") else "%s/%s.png" % [dir, name]
	img.save_png(path)
	print("shot ", path)


func _run() -> void:
	var main: Control = load("res://src/scenes/main.tscn").instantiate()
	add_child(main)
	for lang in langs:
		I18n.set_lang(lang, false)
		Mock.reset()
		Session.clear()
		Session.notices.clear()
		var logged := false
		var shell: Control = null
		for s in SHOTS:
			var name: String = s[0]
			if not only.is_empty() and not only.has(name):
				continue
			var cmd: String = s[1]
			if name == "splash":
				main.show_splash()
				await _frames(10)
				await _save(lang, name)
				continue
			if name == "login":
				var l: Control = main.show_login()
				await _frames(2)
				l.prefill("K7Q2M9AX")
				await _save(lang, name)
				continue
			if not logged:
				await Api.auth_link("K7Q2M9AX")
				await Game.start_playing()
				shell = main.show_shell()
				await _frames(6)
				logged = true
				# some realtime history for the feed
				Session.add_notice({"type": "notice", "kind": "arrived", "text": Mock.L("📍 به بازار رسیدید.", "📍 You reached the bazaar.")})
				Session.add_notice({"type": "announce", "kind": "announce", "text": Mock.fx["announcements"][lang][0]})
				Session.add_notice({"type": "notice", "kind": "shift_paid", "text": Mock.L("💰 شیفت تمام شد و 1٬850 نیل دستمزد گرفتید.", "💰 Your shift is over: you were paid 1,850 Nil.")})
			shell.toasts.clear()
			shell.close_drawer()
			var saved_inventory = null
			var saved_notices = null
			if name == "inventory_empty":
				saved_inventory = Mock.fx["inventory"]
				Mock.fx["inventory"] = []
			elif name == "notifications_empty":
				saved_notices = Session.notices.duplicate()
				Session.notices.clear()
			if cmd == "@menu":
				await Game.run("map.list", {})
				await _frames(4)
				shell.toggle_drawer()
			elif cmd.begins_with("@"):
				shell.open_local(cmd.substr(1))
			else:
				await Game.run(cmd, s[2])
			if saved_inventory != null:
				Mock.fx["inventory"] = saved_inventory
			if saved_notices != null:
				Session.notices = saved_notices
			if name == "city_walking":
				# show the walker a third of the way there
				var scr = shell.current
				await _frames(3)
				if scr and scr.get("map") and not scr.map.world._walk.is_empty():
					scr.map.world._walk["left"] = float(scr.map.world._walk["total"]) * 0.55
					scr.map.world.focus(scr.map.slots.get("bazaar", ""), 7.0)
			if name == "confirm":
				await _frames(4)
				# Trigger it exactly the way a real tap does: a danger/confirm
				# action goes through ActionKit.run(), which calls
				# ConfirmSheet.ask() with the screen itself as host.
				var scr: GameScreen = shell.current
				for a in scr.resp.get("actions", []):
					if str(a.get("command", "")) == "company.close":
						ActionKit.run(a, scr)
						break
			if name == "toast":
				await _frames(4)
				shell.toast(Mock.L("💰 شیفت تمام شد و 1٬850 نیل دستمزد گرفتید.", "💰 Your shift is over: you were paid 1,850 Nil."), "ok")
			await _frames(8)
			await _assets_settle()
			if OS.get_environment("SHOT_DEBUG") != "":
				_debug(shell)
			await _save(lang, name)
			if name == "city_walking":
				Mock.st["walk"] = null
				Mock.st["place"] = "city_centre"


## Wait for CDN downloads to finish (up to 20 s), then a few frames to swap them in.
func _assets_settle() -> void:
	var t := 0.0
	while not AssetService.idle() and t < 20.0:
		await get_tree().create_timer(0.1).timeout
		t += 0.1
	await _frames(6)


func _debug(n: Node, depth := 0) -> void:
	if n is Control and depth < 9:
		var c: Control = n
		if c.get_combined_minimum_size().x > 720 or c.position.x < -1 or c.size.x > 721:
			print("  ".repeat(depth), c.name, " ", c.get_class(), " pos=", c.position, " size=", c.size, " min=", c.get_combined_minimum_size())
	for ch in n.get_children():
		_debug(ch, depth + 1)
