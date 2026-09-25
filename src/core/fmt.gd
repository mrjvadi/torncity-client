class_name Fmt
## Number, money, duration and bidi formatting for the client shell.
##
## Mirrors the server's locale rules (configs/locales/*.yml, `format:`): Persian
## writes every number with Persian digits, «٬» between thousands and «٫» as
## the decimal mark; English uses 0-9 and ",". Pure functions: unit-tested in
## tests/test_fmt.gd.

const FA_DIGITS := "۰۱۲۳۴۵۶۷۸۹"
const AR_DIGITS := "٠١٢٣٤٥٦٧٨٩"
const FA_GROUP := "٬"
const FA_DECIMAL := "٫"

## Unicode bidi isolates: keep a name/code written the other way from
## scrambling the sentence around it.
const LRI := "\u2066"
const RLI := "\u2067"
const FSI := "\u2068"
const PDI := "\u2069"


static func is_rtl(lang: String) -> bool:
	return lang == "fa" or lang == "ar"


## Latin digits -> the language's digits (leaves everything else alone).
static func digits(s: String, lang: String) -> String:
	if lang != "fa":
		return s
	var out := ""
	for ch in s:
		var c := ch.unicode_at(0)
		if c >= 48 and c <= 57:
			out += FA_DIGITS[c - 48]
		else:
			out += ch
	return out


## Any Persian/Arabic-Indic digits back to Latin (for parsing what a player typed).
static func to_latin(s: String) -> String:
	var out := ""
	for ch in s:
		var i := FA_DIGITS.find(ch)
		if i < 0:
			i = AR_DIGITS.find(ch)
		out += str(i) if i >= 0 else ch
	return out


## Groups of three with the language's separator: 1234567 -> "1,234,567" / "۱٬۲۳۴٬۵۶۷".
static func number(n: int, lang: String) -> String:
	var neg := n < 0
	var s := str(absi(n))
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = (FA_GROUP if lang == "fa" else ",") + out
	if neg:
		# U+2212 minus sign reads correctly in both directions.
		out = "−" + out
	return digits(out, lang)


static func decimal(v: float, places: int, lang: String) -> String:
	var whole := int(floor(absf(v)))
	var frac := int(round((absf(v) - whole) * pow(10, places)))
	if frac >= int(pow(10, places)):
		whole += 1
		frac = 0
	var s := number(whole if v >= 0 else -whole, lang)
	if places > 0:
		s += (FA_DECIMAL if lang == "fa" else ".") + digits(str(frac).pad_zeros(places), lang)
	return s


## Money in the game currency (Nil). Amounts are integer units, never divided.
static func money(n: int, lang: String) -> String:
	if lang == "fa":
		return number(n, lang) + " نیل"
	return number(n, lang) + " Nil"


## Compact money for the HUD: 12,500 -> 12.5K / ۱۲٫۵ هزار.
static func money_short(n: int, lang: String) -> String:
	var a := absi(n)
	if a < 10000:
		return number(n, lang)
	var units := [[1000000000, "B", " میلیارد"], [1000000, "M", " میلیون"], [1000, "K", " هزار"]]
	for u in units:
		if a >= u[0]:
			var v := float(n) / float(u[0])
			var places := 1 if absf(v) < 100 else 0
			var s := decimal(v, places, lang)
			if s.ends_with(".0") or s.ends_with(FA_DECIMAL + FA_DIGITS[0]):
				s = s.substr(0, s.length() - 2)
			return s + (u[2] if lang == "fa" else u[1])
	return number(n, lang)


## Seconds -> "2h 15m" / "۲ ساعت و ۱۵ دقیقه" (the server's format.duration_*).
static func duration(seconds: int, lang: String) -> String:
	seconds = maxi(seconds, 0)
	var h := seconds / 3600
	var m := (seconds % 3600) / 60
	var s := seconds % 60
	if lang == "fa":
		if h > 0 and m > 0:
			return "%s ساعت و %s دقیقه" % [number(h, lang), number(m, lang)]
		if h > 0:
			return "%s ساعت" % number(h, lang)
		if m > 0:
			return "%s دقیقه" % number(m, lang)
		return "%s ثانیه" % number(s, lang)
	if h > 0 and m > 0:
		return "%dh %dm" % [h, m]
	if h > 0:
		return "%dh" % h
	if m > 0:
		return "%dm" % m
	return "%ds" % s


## "HH:MM" with the language's digits.
static func clock(hour: int, minute: int, lang: String) -> String:
	return digits("%02d:%02d" % [hour, minute], lang)


## "37 of 100" style counts: the server writes «{energy} از {max_energy}».
static func of(v: int, max_v: int, lang: String) -> String:
	if lang == "fa":
		return "%s از %s" % [number(v, lang), number(max_v, lang)]
	return "%s / %s" % [number(v, lang), number(max_v, lang)]


## Isolate a run of opposite-direction text (a Latin player code in a Persian line).
static func isolate(s: String) -> String:
	return FSI + s + PDI


## Replace {placeholders} from a dictionary; numbers are formatted for the language.
static func fill(template: String, params: Dictionary, lang: String) -> String:
	var out := template
	for k in params:
		var v = params[k]
		var sv: String
		if v is int:
			sv = number(v, lang)
		elif v is float:
			sv = decimal(v, 1, lang)
		else:
			sv = str(v)
		out = out.replace("{" + str(k) + "}", sv)
	return out


## Seconds between now and an RFC 3339 instant (negative when past); 0 when unparsable.
static func seconds_until(rfc3339: String, now_unix: float) -> int:
	if rfc3339.is_empty():
		return 0
	var t := Time.get_unix_time_from_datetime_string(rfc3339)
	if t == 0 and not rfc3339.begins_with("1970"):
		return 0
	# get_unix_time_from_datetime_string ignores the zone suffix; the server sends UTC.
	return int(t - now_unix)
