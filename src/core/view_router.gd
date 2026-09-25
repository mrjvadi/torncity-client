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
}

## Bottom navigation tabs -> the command each opens.
const TABS := {
	"city": {"command": "map.list", "icon": "city", "label": "nav.city"},
	"me": {"command": "player.profile.get", "icon": "profile", "label": "nav.me"},
	"work": {"command": "job.status", "icon": "work", "label": "nav.work"},
	"bank": {"command": "bank.show", "icon": "bank", "label": "nav.bank"},
	"more": {"command": "", "icon": "grid", "label": "nav.more"},
}

## Which tab a client screen belongs to (for highlighting the nav).
const TAB_OF := {
	"city": "city", "cities": "city", "travel_options": "city", "travel_status": "city",
	"profile": "me", "life": "me", "inventory": "more",
	"job": "work", "bank": "bank",
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
	return "more"
