"""Item icons: small, realistic 3/4 renders for dark inventory slots.

    tools/blender/app/blender -b --factory-startup -P art_src/blender/items.py -- [--only pistol] [--samples 40]

Codes follow configs/content/items.yml, plus the reference kit's weapons and
gear. Writes assets/art/items/<code>.png (256 x 256) — the item/<code> slot —
and a copy in art/catalog/items/.
"""
import math
import os
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit  # noqa: E402
from kit import Builder  # noqa: E402

GUN = "#2A2D32"


def pistol(B):
    B.part("metal", GUN, rough=0.3, bevel=0.4).box(0, -1.5, 8, 26, 3, 4.5)
    B.part("metal", "#1C1E22", rough=0.5, bevel=0.3).profile([(3, 8.5), (10, 8.5), (8, 0), (1, 0)], -1.4, 2.8)
    B.part("metal", GUN, bevel=0.2).profile([(10, 8), (14, 8), (13, 5), (10, 5)], -0.4, 0.8)
    B.part("metal", "#111", smooth=True).cyl_axis((26, 0, 10), (26.3, 0, 10), 0.9, 12)


def rifle(B):
    B.part("metal", GUN, rough=0.35, bevel=0.3).box(0, -1.4, 6, 40, 2.8, 4)
    B.part("metal", "#1C1E22", smooth=True).cyl_axis((40, 0, 8.5), (60, 0, 8.5), 0.8, 12)
    B.part("leather", "#5A3E2B", bevel=0.4).profile([(-18, 4), (0, 6), (0, 10), (-18, 9)], -1.5, 3)
    B.part("metal", "#1C1E22", bevel=0.2).profile([(18, 6), (22, 6), (24, -4), (20, -4)], -1.2, 2.4)
    B.part("metal", "#1C1E22", bevel=0.2).profile([(6, 6), (10, 6), (8, -1), (4, -1)], -1.2, 2.4)
    B.part("metal", "#23262B", smooth=True).cyl_axis((12, 0, 12), (28, 0, 12), 1.4, 16)


def knife(B):
    B.part("metal", "#C9D1DA", rough=0.12, bevel=0.1).profile([(10, 0), (32, 1.5), (36, 3.5), (10, 4)], -0.3, 0.6)
    B.part("leather", "#2B2B2B", bevel=0.5).box(-2, -1, 0.5, 12, 2, 3)
    B.part("metal", "#8A8F96").box(9, -1.6, -0.5, 1.4, 3.2, 5)


def ammo(B):
    for i in range(5):
        y = -8 + i * 4
        B.part("metal", "#C8A24A", rough=0.25, smooth=True).cyl(0, y, 0, 1.5, 8, 20)
        B.part("metal", "#B87333", rough=0.3, smooth=True).cyl(0, y, 8, 1.4, 2.5, 20, r2=0.4)
    B.part("paint", "#3E4630", bevel=0.4).box(-8, -12, 0, 6, 24, 5)


def vest(B):
    C = B.part("cloth", "#2F3A2A", bevel=1.0, smooth=True)
    C.profile([(-12, 0), (12, 0), (12, 22), (7, 28), (3, 22), (-3, 22), (-7, 28), (-12, 22)], -3, 6)
    P = B.part("cloth", "#26301F", bevel=0.6)
    for x in (-9, -3, 3):
        P.box(x, 2.7, 3, 5.5, 1.6, 6)
    B.part("rubber", "#1B1B1B").box(-12, 2.9, 12, 24, 0.5, 1.2)


def helmet(B):
    B.part("paint", "#4A5436", rough=0.7, smooth=True).dome(0, 0, 0, 10, 8)
    B.part("paint", "#3E472E", smooth=True).cyl(0, 0, -0.5, 10.6, 1.2, 32)
    B.part("rubber", "#1B1B1B").box(-1, -10.5, -4, 2, 0.6, 4)


def backpack(B):
    C = B.part("cloth", "#5C4A36", bevel=1.5, smooth=True)
    C.box(-7, -5, 0, 14, 10, 20)
    B.part("cloth", "#4A3B2B", bevel=1.0).box(-6, 4.5, 2, 12, 3, 8)
    B.part("leather", "#2B2B2B").box(-5, -5.5, 18, 10, 11, 1.2)
    B.part("metal", "#B9A36A").box(-1, 7.6, 5.5, 2, 0.4, 2)


def medkit(B):
    B.part("paint", "#D64541", bevel=1.2).box(-10, -7, 0, 20, 14, 12)
    W = B.part("paint", "#F4F6F8")
    W.box(-1.5, 7, 3, 3, 0.4, 7).box(-4, 7, 5, 8, 0.4, 3)
    B.part("metal", "#DDD").box(-4, -2, 12, 8, 4, 1.5)


def water(B):
    B.part("glass", "#8FD0F0", smooth=True).cyl(0, 0, 0, 3.6, 20, 28)
    B.part("glass", "#8FD0F0", smooth=True).cyl(0, 0, 20, 3.6, 4, 28, r2=1.4)
    B.part("paint", "#2F80ED", smooth=True).cyl(0, 0, 24, 1.5, 2, 20)
    B.part("paint", "#F4F6F8", smooth=True).cyl(0, 0, 8, 3.7, 6, 28)


def bread(B):
    B.part("paint", "#C68A3E", rough=0.8, smooth=True).sphere(0, 0, 4, 10, sx=1.4, sy=0.7, sz=0.55, segs=32, rings=16)
    for k in (-6, 0, 6):
        B.part("paint", "#E8C27A", smooth=True).box(k - 0.6, -3, 8.5, 1.2, 6, 0.6)


def burger(B):
    B.part("paint", "#C98A3E", smooth=True).dome(0, 0, 7, 9, 5)
    B.part("foliage", "#4E9A3A", smooth=True).cyl(0, 0, 6, 9.6, 1, 32)
    B.part("paint", "#D14B2A", smooth=True).cyl(0, 0, 4.8, 9, 1.2, 32)
    B.part("paint", "#5A3320", smooth=True).cyl(0, 0, 2.6, 9.2, 2.2, 32)
    B.part("paint", "#C98A3E", smooth=True).cyl(0, 0, 0, 9, 2.6, 32)


def phone(B):
    B.part("metal", "#1C1F24", rough=0.3, bevel=0.8).box(-5, -9, 0, 10, 18, 1.2)
    B.part("glass", "#1F3A55").box(-4.3, -8.3, 1.2, 8.6, 16.6, 0.1)
    B.part("emit", "#56CCF2", strength=0.8).box(-3.8, -7.5, 1.31, 7.6, 12, 0.05)


def laptop(B):
    B.part("metal", "#AEB6C0", rough=0.3, bevel=0.5).box(-12, -8, 0, 24, 16, 1.2)
    B.part("rubber", "#2B2F36").box(-10, -6, 1.2, 20, 9, 0.1)
    B.part("metal", "#AEB6C0", rough=0.3, bevel=0.5).profile([(-8, 1), (-8, 17), (-7, 17), (-7, 1)], -12, 24, axis="x")
    B.part("emit", "#56CCF2", strength=0.7).profile([(-7.05, 2), (-7.05, 16), (-6.95, 16), (-6.95, 2)], -11, 22, axis="x")


def cash(B):
    for i in range(3):
        B.part("paint", "#6FA76A" if i % 2 == 0 else "#5E9A5A", bevel=0.1).box(-10 + i * 0.6, -5 + i * 0.4, i * 1.4, 20, 10, 1.3)
    B.part("paint", "#C9B77A").box(-2, -5.3, 0, 4, 10.6, 4.4)


def gold_bar(B):
    G = B.part("metal", "#D4A63A", rough=0.18, bevel=0.6)
    G.profile([(-10, 0), (10, 0), (8, 5), (-8, 5)], -5, 10)
    G.profile([(-10, 5), (10, 5), (8, 10), (-8, 10)], -4, 8)


def chipset(B):
    B.part("paint", "#1C1F24", bevel=0.4).box(-8, -8, 0, 16, 16, 2)
    B.part("metal", "#C9CED6", rough=0.2).box(-4, -4, 2, 8, 8, 0.4)
    M = B.part("metal", "#D4A63A", rough=0.25)
    for k in range(6):
        M.box(-7 + k * 2.6, 8, 0.5, 1, 2.4, 0.4)
        M.box(8, -7 + k * 2.6, 0.5, 2.4, 1, 0.4)


def circuit_board(B):
    B.part("paint", "#1F6B3A", bevel=0.2).box(-12, -9, 0, 24, 18, 1)
    B.part("paint", "#1C1F24", bevel=0.3).box(-4, -3, 1, 8, 8, 1.4)
    for (x, y, c) in ((-9, -6, "#D4A63A"), (6, 4, "#2F80ED"), (7, -6, "#C0392B"), (-9, 4, "#F4F6F8")):
        B.part("paint", c, smooth=True).cyl(x, y, 1, 1.2, 2.4, 16)
    M = B.part("metal", "#D4A63A", rough=0.25)
    for k in range(6):
        M.box(-12 + k * 4, 8.6, 1, 0.6, 0.6, 0.1)


def cell(B):
    B.part("metal", "#2F80ED", rough=0.3, smooth=True).cyl(0, 0, 0, 4, 16, 28)
    B.part("metal", "#1C1F24", rough=0.3, smooth=True).cyl(0, 0, 11, 4.05, 5, 28)
    B.part("metal", "#C9CED6", rough=0.2, smooth=True).cyl(0, 0, 16, 1.4, 1, 16)


def silica(B):
    B.part("soil", "#E3D3A8", smooth=True).cyl(0, 0, 0, 12, 8, 32, r2=1)


def iron_ore(B):
    import random
    rnd = random.Random(4)
    for k in range(6):
        B.part("concrete", "#6E4B3A").sphere(rnd.uniform(-6, 6), rnd.uniform(-6, 6), rnd.uniform(2, 5), rnd.uniform(3, 5), segs=6, rings=4)


def crude_oil(B):
    B.part("metal", "#1C1F24", rough=0.35, smooth=True).cyl(0, 0, 0, 7, 20, 28)
    for z in (4, 16):
        B.part("metal", "#2A2D32", smooth=True).cyl(0, 0, z, 7.3, 1, 28)
    B.part("paint", "#F2C94C").box(6.6, -3, 8, 0.8, 6, 4)


def wheat(B):
    for k in range(9):
        a = math.radians(-24 + k * 6)
        top = (math.sin(a) * 14, 0, 24 * math.cos(a) * 0.9)
        B.part("paint", "#C9A24A").cyl_axis((0, 0, 0), top, 0.3, 6)
        B.part("paint", "#D9B45A", smooth=True).sphere(top[0], 0, top[2], 1.4, sz=2.4, segs=8, rings=6)
    B.part("cloth", "#8A5A2B").cyl(0, 0, 6, 2.2, 2, 12)


def cotton(B):
    B.part("cloth", "#F2F0EA", smooth=True).box(-9, -7, 0, 18, 14, 14)
    for z in (3, 10):
        B.part("rubber", "#6B4B34").box(-9.3, -7.3, z, 18.6, 14.6, 1)


def timber(B):
    for i, (y, z) in enumerate(((-6, 0), (0, 0), (6, 0), (-3, 5.2), (3, 5.2))):
        B.part("paint", "#7A5236", rough=0.9, smooth=True).cyl_axis((-12, y, z + 3), (12, y, z + 3), 3, 16)
        B.part("paint", "#D9B48A", rough=0.9).cyl_axis((12, y, z + 3), (12.2, y, z + 3), 2.6, 16)


def flour(B):
    B.part("cloth", "#EFE6D2", bevel=2.5, smooth=True).box(-8, -5, 0, 16, 10, 18)
    B.part("paint", "#C0392B").box(-4, 5.1, 6, 8, 0.3, 6)


def tool_steel(B):
    for i in range(3):
        B.part("metal", "#9AA3AE", rough=0.3, bevel=0.3).box(-12, -7 + i * 5, 0, 24, 4, 3)
    for i in range(2):
        B.part("metal", "#8994A0", rough=0.3, bevel=0.3).box(-12, -4.5 + i * 5, 3, 24, 4, 3)


def plastic_case(B):
    B.part("paint", "#2F80ED", rough=0.4, bevel=1.0).box(-10, -7, 0, 20, 14, 10)
    B.part("paint", "#1C5FC0").box(-10.2, -7.2, 7, 20.4, 14.4, 0.8)
    B.part("metal", "#C9CED6").box(-2, 6.9, 7.5, 4, 0.6, 1.5)


def food(B):
    burger(B)


def drink(B):
    B.part("metal", "#C0392B", rough=0.3, smooth=True).cyl(0, 0, 0, 4, 14, 28)
    B.part("metal", "#C9CED6", rough=0.2, smooth=True).cyl(0, 0, 14, 3.6, 1, 28)
    B.part("paint", "#F4F6F8", smooth=True).cyl(0, 0, 5, 4.05, 3, 28)


def medicine(B):
    B.part("paint", "#F4F6F8", smooth=True, rough=0.3).cyl(0, 0, 0, 4.5, 12, 28)
    B.part("paint", "#2F80ED", smooth=True).cyl(0, 0, 12, 4.7, 3, 28)
    B.part("paint", "#27AE60").box(-3, 4.3, 4, 6, 0.4, 4)
    for x, y in ((9, -4), (11, 2)):
        B.part("paint", "#EB5757", smooth=True).sphere(x, y, 1.2, 1.4, sx=2.0, segs=12, rings=8)


def tool(B):
    M = B.part("metal", "#AEB6C0", rough=0.25, bevel=0.3)
    M.box(-12, -1.2, 0, 20, 2.4, 1.4)
    M.cyl(10, 0, 0, 3.8, 1.4, 20)
    B.part("paint", "#1C1F24").box(10, -1.4, -0.1, 5, 2.8, 1.6)
    B.part("rubber", "#C0392B").box(-12, -1.6, -0.2, 9, 3.2, 1.8)


def apparel(B):
    C = B.part("cloth", "#2F80ED", bevel=0.8, smooth=True)
    C.profile([(-8, 0), (8, 0), (8, 16), (13, 12), (16, 16), (9, 22), (3, 22), (0, 20), (-3, 22), (-9, 22), (-16, 16), (-13, 12), (-8, 16)], -1.5, 3)


def gadget(B):
    phone(B)


def device(B):
    laptop(B)


def jewel(B):
    J = B.part("glass", "#56CCF2")
    J.cyl(0, 0, 6, 8, 3, 12, r2=5)
    J.cyl(0, 0, 0, 0.1, 6, 12, r2=8)
    B.part("metal", "#D4A63A", rough=0.2, smooth=True).cyl(0, 0, 8.6, 5, 0.6, 12)


def lockpick_set(B):
    B.part("leather", "#3A2A1E", bevel=0.6).box(-10, -6, 0, 20, 12, 1.4)
    M = B.part("metal", "#C9D1DA", rough=0.15)
    for k in range(5):
        M.box(-7 + k * 3.4, -4, 1.4, 0.6, 8, 0.3)
        M.box(-7 + k * 3.4, 3.4, 1.4, 1.4, 0.6, 0.3)


def crowbar(B):
    R = B.part("paint", "#C0392B", rough=0.4, smooth=True)
    R.cyl_axis((-14, 0, 1), (12, 0, 1), 1, 12)
    R.cyl_axis((12, 0, 1), (15, 0, 5), 1, 12)
    R.cyl_axis((-14, 0, 1), (-17, 0, 0), 1, 12)


def gloves(B):
    for s in (-1, 1):
        L = B.part("leather", "#2B2B2B", bevel=0.6, smooth=True)
        L.box(-5 + s * 6, -2, 0, 9, 4, 12)
        for k in range(4):
            L.box(-4.5 + s * 6 + k * 2.2, -1.6, 12, 1.8, 3.2, 5 - abs(k - 1.5))


def ski_mask(B):
    B.part("cloth", "#1C1F24", smooth=True).sphere(0, 0, 8, 8, sz=1.2, segs=24, rings=14)
    for y in (-3, 3):
        B.part("skin", "#E0B08C", smooth=True).sphere(6.4, y, 9.5, 1.8, sx=0.6, segs=12, rings=8)
    B.part("skin", "#E0B08C", smooth=True).sphere(7, 0, 4.5, 1.8, sx=0.5, sy=1.4, segs=12, rings=8)


def running_shoes(B):
    B.part("cloth", "#2F80ED", bevel=1.2, smooth=True).profile([(0, 1.5), (22, 1.5), (24, 4), (20, 7), (12, 8), (6, 12), (0, 12)], -4, 8)
    B.part("rubber", "#F4F6F8", bevel=0.5).profile([(-0.5, 0), (24, 0), (24.5, 2), (-0.5, 2)], -4.2, 8.4)


def fake_documents(B):
    B.part("leather", "#7A1E2A", bevel=0.3).box(-7, -10, 0, 14, 20, 1.2)
    B.part("metal", "#D4A63A", rough=0.25, smooth=True).cyl(0, 0, 1.2, 3.2, 0.1, 24)
    B.part("paint", "#F2EEE6").box(-5, -8, 1.3, 10, 3, 0.05)


def card_skimmer(B):
    B.part("paint", "#1C1F24", bevel=0.6).box(-6, -10, 0, 12, 20, 3)
    B.part("emit", "#27AE60", strength=2).box(-3, -7, 3, 6, 4, 0.05)
    B.part("paint", "#2F80ED", bevel=0.2).box(-4.3, 2, 3, 8.6, 13, 0.4)
    B.part("metal", "#D4A63A").box(-1.5, 6, 3.4, 3, 2.4, 0.1)


def car(B):
    import vehicles
    vehicles.sports_car(B)


def motorbike(B):
    import vehicles
    vehicles.motorbike(B)


def vehicle(B):
    import vehicles
    vehicles.suv(B)


ALL = {
    # items.yml
    "silica": silica, "iron_ore": iron_ore, "crude_oil": crude_oil, "wheat": wheat, "cotton": cotton,
    "timber": timber, "flour": flour, "tool_steel": tool_steel, "plastic_case": plastic_case,
    "circuit_board": circuit_board, "chipset": chipset, "cell": cell, "food": food, "drink": drink,
    "medicine": medicine, "tool": tool, "apparel": apparel, "gadget": gadget, "device": device,
    "vehicle": vehicle, "jewel": jewel, "lockpick_set": lockpick_set, "crowbar": crowbar, "gloves": gloves,
    "ski_mask": ski_mask, "running_shoes": running_shoes, "fake_documents": fake_documents,
    "card_skimmer": card_skimmer, "car": car, "motorbike": motorbike,
    # the reference kit's extras
    "pistol": pistol, "rifle": rifle, "knife": knife, "ammo": ammo, "vest": vest, "helmet": helmet,
    "backpack": backpack, "medkit": medkit, "water": water, "bread": bread, "phone": phone,
    "laptop": laptop, "cash": cash, "gold_bar": gold_bar,
}


def main():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    only = a[a.index("--only") + 1].split(",") if "--only" in a else []
    samples = int(a[a.index("--samples") + 1]) if "--samples" in a else 40
    sc = kit.reset(samples)
    for code, fn in ALL.items():
        if only and code not in only:
            continue
        kit.clear_meshes()
        kit.clear_cameras()
        B = Builder()
        fn(B)
        objs = B.build()
        kit.frame_objects(sc, 256, 256, 0.1, elev=0.6, objs=objs)
        out = os.path.join(kit.ROOT, "assets", "art", "items", code + ".png")
        kit.render(sc, out)
        cat = os.path.join(kit.ROOT, "art", "catalog", "items")
        os.makedirs(cat, exist_ok=True)
        shutil.copy(out, os.path.join(cat, code + ".png"))
        print("rendered", code)


if __name__ == "__main__":
    main()
