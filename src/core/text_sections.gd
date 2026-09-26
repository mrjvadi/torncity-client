class_name TextSections
extends RefCounted
## Parse a server text into sections the generic screen can lay out as
## cards: blocks are separated by blank lines; in each block
##   the first line, when short and followed by more  -> heading
##   "label: value" lines                              -> stats (tiles)
##   "• item" / "- item" lines                          -> list rows
##   anything else                                      -> paragraph
## Returns {title, subtitle, blocks: [{heading, stats: [[k, v]], list: [], para: []}]}.

const BULLETS := ["•", "▪", "▫", "◦", "- ", "· "]


static func parse(text: String) -> Dictionary:
	var raw := text.replace("\r", "").strip_edges()
	var paras := raw.split("\n\n", false)
	var out := {"title": "", "subtitle": "", "blocks": []}
	for bi in paras.size():
		var lines: Array = []
		for l in paras[bi].split("\n", false):
			if l.strip_edges() != "":
				lines.append(l.strip_edges())
		if lines.is_empty():
			continue
		# the very first line is the screen's title
		if bi == 0 and out.title == "":
			out.title = lines.pop_front()
			if lines.size() > 0 and lines[0].length() <= 60 and not _is_bullet(lines[0]):
				out.subtitle = lines.pop_front()
			if lines.is_empty():
				continue
		var blk := {"heading": "", "stats": [], "list": [], "para": []}
		if lines.size() > 1 and lines[0].length() <= 42 and not _is_stat(lines[0]) and not _is_bullet(lines[0]):
			blk.heading = lines.pop_front()
		for l in lines:
			if _is_bullet(l):
				blk.list.append(_unbullet(l))
			elif _is_stat(l):
				blk.stats.append(_split_stat(l))
			else:
				blk.para.append(l)
		out.blocks.append(blk)
	return out


static func _is_bullet(l: String) -> bool:
	for b in BULLETS:
		if l.begins_with(b):
			return true
	return false


static func _unbullet(l: String) -> String:
	for b in BULLETS:
		if l.begins_with(b):
			return l.substr(b.length()).strip_edges()
	return l


static func _is_stat(l: String) -> bool:
	var i := _colon(l)
	return i > 0 and i <= 32 and i < l.length() - 1 and not l.ends_with(":")


static func _colon(l: String) -> int:
	var a := l.find(": ")
	var b := l.find("： ")
	if a < 0:
		return b
	if b < 0:
		return a
	return mini(a, b)


static func _split_stat(l: String) -> Array:
	var i := _colon(l)
	return [l.substr(0, i).strip_edges(), l.substr(i + 1).strip_edges()]
