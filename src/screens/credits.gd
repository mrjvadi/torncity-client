extends GameScreen
## Credits: who made the art and the font (CREDITS.md in the repository).
## The icon list is read from assets/icons/game-icons/credits.json, written by
## dev/vendor_game_icons.py, so it always matches the glyphs shipped.

const KENNEY_KITS := "res://assets/kenney"


func build() -> void:
	scroll_body(18)
	content.add_child(title_row(I18n.t("credits.title"), "info", true))

	var k := card(I18n.t("credits.models"), "")
	k.add_child(_text(I18n.t("credits.kenney")))
	var kits := HFlowContainer.new()
	kits.add_theme_constant_override("h_separation", 8)
	kits.add_theme_constant_override("v_separation", 8)
	for d in DirAccess.get_directories_at(KENNEY_KITS):
		kits.add_child(UI.panel(UI.label(str(d).replace("-", " ").capitalize(), "SmallLabel"), "ChipPanel"))
	k.add_child(kits)

	var g := card(I18n.t("credits.icons"), "")
	g.add_child(_text(I18n.t("credits.game_icons")))
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/icons/game-icons/credits.json"))
	var by_author := {}
	if data is Dictionary:
		for e in data.get("icons", []):
			by_author.get_or_add(str(e["author"]), []).append(str(e["icon"]))
	var authors: Array = by_author.keys()
	authors.sort()
	for a in authors:
		var row := UI.vbox(6)
		row.add_child(UI.label(I18n.t("credits.icons_by", {"author": _author_name(a), "count": I18n.num(by_author[a].size())}), "SmallLabel"))
		var strip := HFlowContainer.new()
		strip.add_theme_constant_override("h_separation", 6)
		strip.add_theme_constant_override("v_separation", 6)
		for icon_name in by_author[a]:
			var tex = load("res://assets/icons/game-icons/%s.svg" % icon_name)
			strip.add_child(IconBadge.make({"texture": tex, "tint": AppTheme.col("blue")}, 44))
		row.add_child(strip)
		g.add_child(row)

	var f := card(I18n.t("credits.font"), "")
	f.add_child(_text(I18n.t("credits.vazirmatn")))


func _text(t: String) -> Label:
	var l := UI.label(t, "DimLabel")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func _author_name(folder: String) -> String:
	return {"lorc": "Lorc", "delapouite": "Delapouite", "sbed": "Sbed", "skoll": "Skoll", "john-colburn": "John Colburn",
		"andymeneely": "Andy Meneely", "caro-asercion": "Caro Asercion", "cathelineau": "Cathelineau",
		"faithtoken": "Faithtoken", "guard13007": "Guard13007", "lord-berandas": "Lord Berandas",
		"willdabeast": "Willdabeast"}.get(folder, folder.replace("-", " ").capitalize())
