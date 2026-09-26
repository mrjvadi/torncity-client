class_name ActionKit
extends RefCounted
## Server actions, placed by what they mean. An action is
##   {command, args, label, kind?, icon?, group?}
## kind: primary | secondary | danger | confirm | navigation | back | refresh.
## Until the server sends `kind` and `icon`, they are inferred (kind_of,
## glyph_of), so today's responses already get the new layout:
##   back / refresh    -> header buttons (never in the grid)
##   primary           -> the pinned call to action at the bottom
##   danger / confirm  -> ask first (ConfirmSheet), then run
##   everything else   -> a grid of icon tiles, grouped by `group`

const DANGER_WORDS := ["delete", "remove", "quit", "leave", "resign", "cancel", "sell_all", "fire", "demolish", "abandon", "close"]


static func kind_of(a: Dictionary) -> String:
	var k := str(a.get("kind", ""))
	if k != "":
		return k
	var label := str(a.get("label", "")).strip_edges()
	var cmd := str(a.get("command", ""))
	if label.begins_with("⬅") or label.begins_with("🔙") or label.begins_with("◀") or cmd == "nav.back":
		return "back"
	if label.begins_with("🔄") or label.begins_with("♻"):
		return "refresh"
	for w in DANGER_WORDS:
		if cmd.ends_with("." + w) or cmd.contains("." + w + "_"):
			return "confirm"
	return "secondary"


static func label_of(a: Dictionary) -> String:
	return TextIcons.strip(str(a.get("label", ""))).strip_edges()


static func glyph_of(a: Dictionary) -> Dictionary:
	return AssetLib.action_glyph(str(a.get("command", "")), str(a.get("icon", "")))


## {primary: [], tiles: [], back: [], refresh: []} — the actions sorted by role.
static func sort(actions: Array, skip := []) -> Dictionary:
	var out := {"primary": [], "tiles": [], "back": [], "refresh": []}
	for a in actions:
		if not (a is Dictionary) or skip.has(str(a.get("command", ""))):
			continue
		match kind_of(a):
			"back": out.back.append(a)
			"refresh": out.refresh.append(a)
			"primary": out.primary.append(a)
			_: out.tiles.append(a)
	return out


## Run an action, asking first when it is destructive.
static func run(a: Dictionary, host: Node) -> void:
	if kind_of(a) in ["danger", "confirm"]:
		ConfirmSheet.ask(host, label_of(a), str(a.get("confirm", "")), func(): Game.run_action(a), kind_of(a) == "danger")
	else:
		Game.run_action(a)


## A grid of action tiles; groups (the `group` field) get a small heading.
static func grid(actions: Array, host: Node, cols := 4) -> Control:
	var by_group := {}
	var order: Array = []
	for a in actions:
		var g := str(a.get("group", ""))
		if not by_group.has(g):
			by_group[g] = []
			order.append(g)
		by_group[g].append(a)
	var box := UI.vbox(12)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for g in order:
		if g != "":
			var h := UI.label(TextIcons.strip(g), "DimLabel")
			box.add_child(h)
		var gc := GridContainer.new()
		gc.columns = cols
		gc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gc.add_theme_constant_override("h_separation", 12)
		gc.add_theme_constant_override("v_separation", 12)
		for a in by_group[g]:
			gc.add_child(ActionTile.make(a, host))
		box.add_child(gc)
	return box


## The primary call to action: a wide glowing button, pinned at the bottom.
static func cta(a: Dictionary, host: Node) -> Button:
	var b := Button.new()
	b.theme_type_variation = "Button"
	b.focus_mode = Control.FOCUS_NONE
	b.text = label_of(a)
	b.custom_minimum_size = Vector2(0, 88)
	b.add_theme_font_size_override("font_size", 28)
	var g := glyph_of(a)
	b.icon = g.get("texture")
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 40)
	b.pressed.connect(func(): ActionKit.run(a, host))
	Fx.press_feedback(b)
	return b
