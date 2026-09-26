#!/usr/bin/env python3
"""Generate the mock city layout, src/mock/world.json (world schema v2).

The real server builds this from its content and the city's companies; this
is only a realistic fixture. World units: 1 = one Kenney road tile (~10 m).

Layout (planned like a real mid-size city):
  * a ring highway around the core, a highway east to the airport on the
    outskirts, two central boulevards (N-S, E-W), avenues and streets on an
    8-unit grid;
  * districts: the CBD towers at the centre, a commercial ring around it,
    garden suburbs to the west and north, the university campus in the
    north-east, an industrial zone on the east edge by the rail line and the
    port, the waterfront port to the south, a central park, farmland west
    and the barracks north-west outside the ring, the airport far east.
"""
import json
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rnd = random.Random(11)

G = 8                     # street grid pitch
CORE = (0, 0, 64, 48)     # x0, y0, x1, y1 of the street grid
roads, plots, districts = [], [], []


def road(cls, *pts, rid=None):
    roads.append({"id": rid or "r%d" % len(roads), "class": cls, "pts": [list(p) for p in pts]})


# -- roads -----------------------------------------------------------------------------------------
x0, y0, x1, y1 = CORE
# the ring highway, a little outside the grid
road("highway", (x0 - 4, y0 - 4), (x1 + 4, y0 - 4), (x1 + 4, y1 + 2), (x0 - 4, y1 + 2), (x0 - 4, y0 - 4), rid="ring")
# highway to the airport (east) and to the farmland (west)
road("highway", (x1 + 4, 20), (104, 20), rid="airport_hw")
road("avenue", (x0 - 4, 24), (-34, 24), rid="west_rd")
# boulevards through the centre
road("boulevard", (32, y0 - 4), (32, y1 + 2), rid="blvd_ns")
road("boulevard", (x0 - 4, 24), (x1 + 4, 24), rid="blvd_ew")
# avenues and streets
for x in range(x0, x1 + 1, G):
    if x == 32:
        continue
    road("avenue" if x in (16, 48) else "street", (x, y0 - 4), (x, y1 + 2))
for y in range(y0, y1 + 1, G):
    if y == 24:
        continue
    road("avenue" if y in (8, 40) else "street", (x0 - 4, y), (x1 + 4, y))

# -- districts -------------------------------------------------------------------------------------
def district(did, kind, fa, en, rect):
    districts.append({"id": did, "kind": kind, "name": {"fa": fa, "en": en}, "rect": list(rect)})


district("cbd", "cbd", "مرکز تجاری", "Downtown", (24, 16, 40, 32))
district("commercial", "commercial", "حلقهٔ تجاری", "Commercial ring", (16, 8, 48, 40))
district("west_suburb", "residential", "محلهٔ باغ‌ها", "Garden suburb", (0, 8, 16, 40))
district("north_suburb", "residential", "شمال شهر", "Northside", (0, 0, 48, 8))
district("campus", "campus", "پردیس دانشگاه", "University campus", (48, 0, 64, 16))
district("industrial", "industrial", "منطقهٔ صنعتی", "Industrial zone", (48, 24, 64, 48))
district("park", "park", "پارک مرکزی", "Central park", (8, 32, 16, 40))
district("port", "port", "بندر", "Port", (24, 40, 48, 48))
district("south_res", "residential", "کرانه", "Riverside", (0, 40, 24, 48))
district("east_mid", "commercial", "بازار شرقی", "East market", (48, 16, 64, 24))
district("farmland", "farmland", "کشتزارها", "Farmland", (-34, 10, -8, 40))
district("military", "military", "پادگان", "Barracks", (-30, -26, -12, -10))
district("airport", "airport", "فرودگاه", "Airport", (74, -6, 124, 34))


def kind_at(x, y):
    # smallest district containing the point
    best = None
    for d in districts:
        a, b, c, e = d["rect"]
        if a <= x < c and b <= y < e:
            area = (c - a) * (e - b)
            if best is None or area < best[0]:
                best = (area, d)
    return best[1] if best else None


# -- blocks: the lots between streets -----------------------------------------------------------------
blocks = []
for bx in range(x0, x1, G):
    for by in range(y0, y1, G):
        cx, cy = bx + G / 2, by + G / 2
        d = kind_at(cx, cy)
        blocks.append({"x": bx + 1.4, "y": by + 1.4, "w": G - 2.8, "h": G - 2.8, "d": d})

# game places (content codes) and where they go
PLACE_KIND = {
    "city_centre": "cbd", "business_district": "cbd", "bazaar": "commercial", "city_hall": "commercial",
    "police_station": "commercial", "hospital": "commercial", "university": "campus", "residential_area": "residential",
    "park": "park", "industrial_zone": "industrial", "train_station": "industrial", "bus_terminal": "commercial",
    "sky_garden": "cbd",
}
OUTSKIRTS = {  # places outside the grid, positioned in their district
    "airport": ("airport", 92, 22, 10, 6),
    "farmland": ("farmland", -26, 18, 8, 8),
    "barracks": ("military", -25, -22, 8, 8),
}
COMPANIES = [
    (1024, "factory", "فولاد البرز", "Alborz Steel", "Sara", "industrial"),
    (1025, "restaurant", "رستوران نارنج", "Naranj Kitchen", "Reza", "commercial"),
    (1026, "grocery", "سوپر آفتاب", "Aftab Market", "Mina", "commercial"),
    (1027, "drone_foundry", "پرواز نو", "New Flight Drones", "Sara", "industrial"),
    (1028, "tech_studio", "استودیو دانا", "Dana Studio", "Ali", "cbd"),
    (1029, "clinic", "درمانگاه مهر", "Mehr Clinic", "Nima", "commercial"),
    (1030, "courier", "پیک سریع", "Swift Courier", "Maryam", "east_mid"),
    (1031, "mine", "معدن کوه‌سنگ", "Kuhsang Mine", "Ali", "industrial"),
]

with open(os.path.join(ROOT, "src", "mock", "fixtures.json"), encoding="utf-8") as fh:
    fx = json.load(fh)
place_codes = [p["code"] for p in fx["places"]]
used = set()


def take(kind_or_id):
    cands = [b for b in blocks if id(b) not in used and b["d"] and (b["d"]["kind"] == kind_or_id or b["d"]["id"] == kind_or_id)]
    # prefer blocks near the centre for landmarks
    cands.sort(key=lambda b: abs(b["x"] + 2.6 - 32) + abs(b["y"] + 2.6 - 24))
    if not cands:
        cands = [b for b in blocks if id(b) not in used and b["d"] and b["d"]["kind"] in ("commercial", "cbd")]
    b = cands[0]
    used.add(id(b))
    return b


def centred(b, s):
    return b["x"] + (b["w"] - s) / 2, b["y"] + (b["h"] - s) / 2


for code in place_codes:
    if code in OUTSKIRTS:
        did, px, py, pw, ph = OUTSKIRTS[code]
        plots.append({"id": "place:" + code, "x": px, "y": py, "w": pw, "h": ph, "kind": "place", "district": did,
                      "ref": {"table": "place", "code": code}, "model": "place:" + code})
        continue
    b = take(PLACE_KIND.get(code, "commercial"))
    s = 4.0 if code in ("university", "park", "hospital", "industrial_zone", "train_station") else 3.2
    x, y = centred(b, s)
    plots.append({"id": "place:" + code, "x": x, "y": y, "w": s, "h": s, "kind": "place", "district": b["d"]["id"],
                  "ref": {"table": "place", "code": code}, "model": "place:" + code})
for cid, t, fa, en, owner, where in COMPANIES:
    b = take(where)
    s = 3.2 if where in ("industrial",) else 2.8
    x, y = centred(b, s)
    plots.append({"id": "company:%d" % cid, "x": x, "y": y, "w": s, "h": s, "kind": "company", "district": b["d"]["id"],
                  "ref": {"table": "company_type", "code": t, "company_id": cid, "owner": owner},
                  "name": {"fa": fa, "en": en}, "model": "company:" + t})
# the rest of the blocks: homes with gardens, shops, towers, sheds, greens
for b in blocks:
    if id(b) in used or not b["d"]:
        continue
    k = b["d"]["kind"]
    bid = "%d_%d" % (int(b["x"]), int(b["y"]))
    if k == "residential":
        for i, (dx, dy) in enumerate(((0.3, 0.3), (2.9, 0.3), (0.3, 2.9), (2.9, 2.9))):
            if rnd.random() < 0.12:
                continue
            plots.append({"id": "home:%s-%d" % (bid, i), "x": b["x"] + dx, "y": b["y"] + dy, "w": 2.0, "h": 2.0, "kind": "home",
                          "district": b["d"]["id"], "model": "home:*", "rot": rnd.choice([0, 90, 180, 270])})
    elif k == "cbd":
        x, y = centred(b, 2.8)
        plots.append({"id": "tower:" + bid, "x": x, "y": y, "w": 2.8, "h": 2.8, "kind": "decor", "district": b["d"]["id"], "model": "decor:tower"})
    elif k in ("commercial",):
        for i, (dx, dy) in enumerate(((0.2, 0.2), (2.8, 2.8))):
            plots.append({"id": "shop:%s-%d" % (bid, i), "x": b["x"] + dx, "y": b["y"] + dy, "w": 2.2, "h": 2.2, "kind": "decor",
                          "district": b["d"]["id"], "model": "decor:shop", "rot": rnd.choice([0, 90])})
    elif k == "industrial":
        x, y = centred(b, 3.0)
        plots.append({"id": "shed:" + bid, "x": x, "y": y, "w": 3.0, "h": 3.0, "kind": "decor", "district": b["d"]["id"], "model": "decor:shed"})
    elif k in ("park", "campus"):
        plots.append({"id": "green:" + bid, "x": b["x"], "y": b["y"], "w": b["w"], "h": b["h"], "kind": "green", "district": b["d"]["id"], "model": ""})
    elif k == "port":
        x, y = centred(b, 3.0)
        plots.append({"id": "yard:" + bid, "x": x, "y": y, "w": 3.0, "h": 3.0, "kind": "decor", "district": b["d"]["id"], "model": "decor:yard"})

world = {
    "schema": 2,
    "city": "{city}",
    "version": 2,
    "bounds": [-40, -32, 128, 64],
    "grid_pitch": G,
    "districts": districts,
    "roads": roads,
    "rails": [{"id": "main_line", "pts": [[-40, 45], [70, 45], [70, 40], [128, 40]]}],
    "water": [{"id": "sea", "rect": [-40, 51.5, 168, 40]}],
    "features": [
        {"type": "runway", "from": [80, 4], "to": [120, 4], "width": 3.0},
        {"type": "runway", "from": [80, 30], "to": [120, 30], "width": 3.0},
        {"type": "apron", "rect": [84, 12, 16, 7]},
        {"type": "plane", "at": [88, 14], "rot": 90}, {"type": "plane", "at": [95, 14.5], "rot": 90},
        {"type": "plane", "at": [110, 4], "rot": 90},
        {"type": "pier", "rect": [30, 50, 3, 6]}, {"type": "pier", "rect": [40, 50, 3, 6]},
        {"type": "ship", "at": [36, 56], "rot": 90}, {"type": "ship", "at": [46, 57], "rot": 90},
        {"type": "field", "rect": [-34, 12, 8, 26]}, {"type": "field", "rect": [-16, 12, 6, 26]},
    ],
    "plots": plots,
}
with open(os.path.join(ROOT, "src", "mock", "world.json"), "w", encoding="utf-8") as fh:
    json.dump(world, fh, ensure_ascii=False, indent=0)
print(len(plots), "plots,", len(roads), "roads,", len(districts), "districts")
