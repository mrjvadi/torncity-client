extends GameScreen
## «More»: every other part of the game, as a grid of feature tiles. Each tile
## runs a server command; screens without a native design open as cards.

const FEATURES := [
	["inventory", "more.inventory", "inventory.show"],
	["life", "more.life", "life.me"],
	["travel", "more.travel", "map.cities"],
	["skills", "more.skills", "skills.list"],
	["study", "more.education", "education.list"],
	["crime", "more.crime", "crime.hub"],
	["company", "more.companies", "company.list"],
	["market", "more.market", "market.list"],
	["cart", "more.shops", "shop.list"],
	["auction", "more.auction", "auction.list"],
	["home", "more.property", "property.list"],
	["moneybag", "more.loans", "loan.hub"],
	["stock", "more.stocks", "stock.list"],
	["gold", "more.gold", "gold.show"],
	["hospital", "more.health", "health.hospital"],
	["mission", "more.missions", "mission.board"],
	["faction", "more.factions", "faction.list"],
	["friends", "more.friends", "social.friend.list"],
	["office", "more.government", "gov.city"],
	["certificate", "more.elections", "election.list"],
	["police", "more.military", "military.ministry"],
	["achievement", "more.achievements", "achievement.list"],
	["bell", "more.notifications", ""],
	["settings", "more.settings", ""],
]


func build() -> void:
	scroll_body(18)
	content.add_child(title_row(I18n.t("nav.more"), "grid", false))
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 14)
	for f in FEATURES:
		g.add_child(Tiles.feature(f[0], I18n.t(f[1]), f[2], shell))
	content.add_child(g)
	Fx.stagger_in(g, 0.02)
