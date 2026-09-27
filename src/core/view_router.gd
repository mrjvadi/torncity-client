class_name ViewRouter
extends RefCounted
## Maps what the server answered ({screen, view}) to the client screen that
## draws it. Screens with a structured `view` get a native scene; everything
## else falls back to the generic card (text + action buttons), so every game
## feature is reachable even before it has a native screen.
## Unit-tested in tests/test_view_router.gd.

const NATIVE := {
	"profile": "profile",
	"dashboard": "profile",
	"city_map": "city",
	"cities": "cities",
	"travel_options": "travel_options",
	"travel_status": "travel_status",
	"bank": "bank",
	"inventory": "inventory",
	"job_status": "job",
	"life": "life",
	"market": "market",
	"company_list": "companies",
	"crime_hub": "crime",
	"education": "education",
}

## Bottom navigation tabs -> the command each opens ("" = a client screen).
const TABS := {
	"world": {"command": "map.cities", "icon": "ln_world", "label": "nav.world"},
	"map": {"command": "map.list", "icon": "ln_map", "label": "nav.map"},
	"companies": {"command": "company.list", "icon": "ln_companies", "label": "nav.companies"},
	"market": {"command": "market.list", "icon": "ln_market", "label": "nav.market"},
	"inventory": {"command": "inventory.show", "icon": "ln_inventory", "label": "nav.inventory"},
	"messages": {"command": "", "local": "notifications", "icon": "ln_messages", "label": "nav.messages"},
	"profile": {"command": "player.profile.get", "icon": "ln_profile", "label": "nav.profile"},
	"activity": {"command": "job.status", "icon": "ln_profile", "label": "nav.activity"},
	"society": {"command": "faction.mine", "icon": "ln_messages", "label": "nav.society"},
}
## Five tabs fit a phone's thumb; the inventory lives under the profile (and
## the menu), messages behind the HUD's bell. Both stay in TABS, so either can
## still be opened as a tab.
const TAB_ORDER := ["world", "map", "companies", "market", "profile"]

## Which tab a client screen belongs to (for highlighting the nav).
const TAB_OF := {
	"city": "map", "cities": "world", "travel_options": "world", "travel_status": "world",
	"profile": "profile", "life": "profile", "job": "activity", "bank": "market",
	"inventory": "profile", "notifications": "society", "market": "market",
	"companies": "market", "crime": "activity", "education": "activity",
}


## The client screen for a response. A native screen needs its view; without
## one (an error, a notice, or a server that sent text only) it is a card.
static func scene_for(screen: String, view: Variant) -> String:
	if NATIVE.has(screen) and view is Dictionary and not (view as Dictionary).is_empty():
		return NATIVE[screen]
	return "card"


static func tab_for(scene: String, command := "") -> String:
	if TAB_OF.has(scene):
		return TAB_OF[scene]
	for t in TABS:
		if TABS[t]["command"] != "" and TABS[t]["command"] == command:
			return t
	var head := command.split(".")[0]
	if head == "company":
		return "companies"
	if head in ["market", "shop", "auction"]:
		return "market"
	return ""
