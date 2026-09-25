extends GameScreen
## The generic screen: the server's localised text and its action buttons.
## Every game feature without a native screen still works through this.


func build() -> void:
	scroll_body()
	var text := str(resp.get("text", ""))
	var lines := text.split("\n", false)
	var first := lines[0] if lines.size() > 0 else ""
	var icon_name := TextIcons.lead_icon(first)
	if icon_name == "":
		icon_name = "info" if resp.get("ok", true) else "warning"
	var title := TextIcons.strip(first)
	var body := "\n".join(lines.slice(1)) if lines.size() > 1 else ""
	if title.length() > 38:
		body = text
		title = I18n.t("card.title")
	content.add_child(title_row(title, icon_name))
	maybe_notice_card()
	if body.strip_edges() != "":
		var p := GlowPanel.new()
		p.padding = 26
		p.add_child(UI.rich(body))
		content.add_child(p)
	var acts: Array = resp.get("actions", [])
	if not acts.is_empty():
		content.add_child(actions_grid(acts, [], 1 if acts.size() <= 3 else 2))
	Fx.stagger_in(content)


func maybe_notice_card() -> void:
	var n := str(resp.get("notice", ""))
	if n != "":
		content.add_child(notice_banner(n))
	var err = resp.get("error")
	if err is Dictionary and str(err.get("message", "")) != "" and str(err.get("message", "")) != str(resp.get("text", "")):
		content.add_child(notice_banner(str(err["message"]), "error"))
