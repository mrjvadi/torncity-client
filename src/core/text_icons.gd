class_name TextIcons
extends RefCounted
## Server text uses one emoji "anchor" per line (the locale glossary). The
## client draws those anchors with its own icon set instead of an emoji font
## (small web download, one visual style). Unknown emoji are dropped.

const MAP := {
	"⚡": "energy", "❤": "health", "⭐": "level", "📍": "pin", "🧭": "travel", "⏳": "hourglass",
	"🗺": "map", "🛠": "skills", "👥": "friends", "👤": "profile", "🔎": "search", "🔍": "search",
	"🔄": "refresh", "⚙": "settings", "🌐": "language", "💵": "cash", "🏦": "bank", "💳": "card",
	"💸": "pay", "📥": "deposit", "📤": "withdraw", "💼": "work", "💰": "moneybag", "📈": "chart",
	"⬆": "promotion", "🎓": "study", "📖": "book", "📜": "certificate", "🏛": "office", "🔙": "back",
	"🚶": "walk", "🕒": "clock", "🕐": "clock", "⏰": "clock", "🏥": "hospital", "⛓": "jail",
	"🏅": "achievement", "🏆": "achievement", "👋": "wave", "🧬": "life", "⚠": "warning", "✅": "check",
	"✔": "check", "✖": "close", "❌": "close", "➕": "plus", "🛒": "cart", "🏪": "market",
	"🔨": "auction", "🚓": "police", "👮": "police", "🛏": "bed", "🍞": "food", "🍽": "food",
	"😊": "happiness", "🙂": "happiness", "😣": "stress", "😫": "stress", "🚌": "bus", "🚗": "car",
	"🚆": "train", "🚉": "train", "✈": "plane", "🏢": "company", "🏭": "company", "🕶": "crime",
	"🦹": "crime", "📋": "mission", "🔔": "bell", "📲": "phone", "📱": "phone", "🏠": "home",
	"🏡": "home", "🥇": "gold", "🪙": "gold", "📊": "stock", "🚩": "faction", "🏴": "faction",
	"🔒": "lock", "ℹ": "info", "🎂": "age", "✏": "plus", "⬅": "back", "➡": "forward",
	"🆔": "profile", "🎯": "mission", "📦": "inventory", "🎒": "inventory", "🌱": "life",
}

## Joiners and variation selectors that ride on emoji.
const _INVISIBLE := [0xFE0F, 0xFE0E, 0x200D, 0x20E3]


static func _is_emoji(c: int) -> bool:
	return (c >= 0x1F000 and c <= 0x1FAFF) or (c >= 0x2600 and c <= 0x27BF) or (c >= 0x2B00 and c <= 0x2BFF) \
		or (c >= 0x2190 and c <= 0x21FF) or (c >= 0x2300 and c <= 0x23FF) or c == 0x2139 or c == 0x24C2


## Split text into runs: [{"t": "text", "v": "..."} | {"t": "icon", "v": "energy"}].
static func runs(text: String) -> Array:
	var out := []
	var buf := ""
	for ch in text:
		var c := ch.unicode_at(0)
		if c in _INVISIBLE:
			continue
		if _is_emoji(c):
			if MAP.has(ch):
				if buf != "":
					out.append({"t": "text", "v": buf})
					buf = ""
				out.append({"t": "icon", "v": MAP[ch]})
			continue
		buf += ch
	if buf != "":
		out.append({"t": "text", "v": buf})
	return out


## Text without any emoji (for plain Labels and buttons that draw their own icon).
static func strip(text: String) -> String:
	var s := ""
	for r in runs(text):
		if r["t"] == "text":
			s += r["v"]
	return s.strip_edges()


## The first anchor icon of a line, or "" (buttons use it as their icon).
static func lead_icon(text: String) -> String:
	for r in runs(text):
		if r["t"] == "icon":
			return r["v"]
		if r["v"].strip_edges() != "":
			return ""
	return ""


## BBCode for a RichTextLabel: anchors become inline images of the icon set.
static func to_bbcode(text: String, icon_size: int, icon_path: Callable) -> String:
	var out := ""
	for r in runs(text):
		if r["t"] == "icon":
			var p: String = icon_path.call(r["v"])
			if p != "":
				out += "[img=%dx%d]%s[/img] " % [icon_size, icon_size, p]
		else:
			out += (r["v"] as String).replace("[", "[lb]")
	return out
