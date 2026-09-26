#!/usr/bin/env python3
"""Extract the curated game-icons.net glyphs (CC BY 3.0) into
assets/icons/game-icons/<name>.svg, and write who made each one:
assets/icons/game-icons/CREDITS.txt and credits.json (read by the in-game
Credits screen).

Source archive: tools/kenney/game-icons.net.svg.zip, from
https://game-icons.net/archives/svg/zip/ffffff/transparent/game-icons.net.svg.zip

GLYPHS is the only list here, and it is visual vocabulary, not game content:
the library (assets/library.json) maps asset keys to these glyph names.
"""
import json
import os
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ZIP = os.path.join(ROOT, "tools", "kenney", "game-icons.net.svg.zip")
OUT = os.path.join(ROOT, "assets", "icons", "game-icons")

# glyph -> preferred author folder (None: the first one found)
GLYPHS = {
    # stats and resources
    "heart-beats": None, "lightning-helix": None, "cheerful": None, "sun": None, "stomach": None, "sleepy": None,
    "brain": None, "cash": None, "bank": None, "money-stack": None, "coins": None, "gold-bar": None,
    "medal": None, "trophy": None, "upgrade": None, "star-struck": None, "hourglass": None,
    # actions
    "crossed-swords": None, "walk": None, "briefcase": None, "factory": None, "microscope": None,
    "shopping-cart": None, "shop": None, "world": None, "treasure-map": None, "envelope": None,
    "person": None, "house": None, "family-house": None, "gears": None, "graduate-cap": None,
    "open-book": None, "skills": None, "handcuffs": None, "ninja-mask": None, "police-badge": None,
    "hospital-cross": None, "vote": None, "gavel": None, "scales": None, "chart": None, "trade": None,
    "party-flags": None, "flying-flag": None, "ringing-bell": None, "chat-bubble": None, "padlock": None,
    "key": "lorc", "castle": "lorc", "fist": None, "anchor": None, "modern-city": None, "road": None,
    "clock-tower": None, "hammer-nails": None, "anvil-impact": None, "test-tubes": None, "cargo-crane": None,
    # items
    "pistol-gun": None, "ak47": None, "bowie-knife": "lorc", "bullets": None, "ammo-box": None,
    "kevlar-vest": None, "helmet": None, "backpack": None, "first-aid-kit": None, "water-bottle": None,
    "bread": None, "hamburger": None, "soda-can": None, "pill": None, "smartphone": "delapouite",
    "laptop": None, "microchip": None, "circuitry": None, "car-key": None, "toolbox": None, "wrench": None,
    "crowbar": None, "lockpicks": None, "running-shoe": None, "cut-diamond": None, "diamond-ring": None,
    "ore": None, "wheat": None, "barrel": None, "oil-drum": None, "log": None, "cotton-flower": None,
    "flour": None, "domino-mask": None, "gas-mask": None, "swap-bag": None, "cardboard-box": None,
    "toaster": None, "delivery-drone": None, "sprout": None, "round-silo": None, "warehouse": None,
    # vehicles and military
    "police-car": None, "ambulance": None, "truck": None, "helicopter": None, "jet-fighter": None,
    "airplane": None, "cargo-ship": None, "tank": None, "bus": None, "subway-train": None, "city-car": None,
    "speed-boat": None, "missile-launcher": None, "rocket": None, "tank-tread": None, "battleship": None,
    "armor-vest": None, "shield": None,
}


def main():
    z = zipfile.ZipFile(ZIP)
    found = {}
    for n in z.namelist():
        if not n.endswith(".svg"):
            continue
        name = os.path.basename(n)[:-4]
        author = n.split("/")[-2]
        if name in GLYPHS:
            found.setdefault(name, {})[author] = n
    os.makedirs(OUT, exist_ok=True)
    # drop glyphs no longer listed (keep .import files: they carry the 128 px
    # import scale; new glyphs get it from the import pass in the docs)
    for f in os.listdir(OUT):
        if f.endswith(".svg") and f[:-4] not in GLYPHS:
            os.remove(os.path.join(OUT, f))
            if os.path.exists(os.path.join(OUT, f + ".import")):
                os.remove(os.path.join(OUT, f + ".import"))
    credits = []
    for name, pref in GLYPHS.items():
        if name not in found:
            print("missing:", name)
            continue
        author = pref if pref in found[name] else sorted(found[name])[0]
        with z.open(found[name][author]) as src:
            svg = src.read().decode("utf-8")
        with open(os.path.join(OUT, name + ".svg"), "w", encoding="utf-8") as fh:
            fh.write(svg)
        credits.append({"icon": name, "author": author, "url": "https://game-icons.net/1x1/%s/%s.html" % (author, name)})
    with z.open("icons/license.txt") as src:
        licence = src.read().decode("utf-8")
    with open(os.path.join(OUT, "CREDITS.txt"), "w", encoding="utf-8") as fh:
        fh.write("Icons from https://game-icons.net — CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/)\n")
        fh.write("unless the author's line in the licence below says CC0.\n\n")
        for c in credits:
            fh.write("%-22s Icon made by %s  %s\n" % (c["icon"], c["author"], c["url"]))
        fh.write("\n---- licence.txt from the archive ----\n\n" + licence)
    with open(os.path.join(OUT, "credits.json"), "w", encoding="utf-8") as fh:
        json.dump({"source": "https://game-icons.net", "license": "CC BY 3.0", "icons": credits}, fh, indent=1)
    authors = sorted({c["author"] for c in credits})
    print(len(credits), "icons by", ", ".join(authors))


if __name__ == "__main__":
    main()
