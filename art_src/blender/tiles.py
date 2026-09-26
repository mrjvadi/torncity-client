"""Environment tiles (isometric blocks with a soil side) and props.

    tools/blender/app/blender -b --factory-startup -P art_src/blender/tiles.py -- [--only water] [--samples 32]

Tiles use the lot camera (same scale as the buildings): art/catalog/tiles/<code>.png
and assets/art/tiles/<code>.png. Props are framed one by one:
art/catalog/props/<code>.png and assets/art/props/<code>.png.
"""
import math
import os
import random
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit  # noqa: E402
from kit import Builder, tree, bush, lamp  # noqa: E402

D = 16  # block depth


def block(B, top_kind, top_color, side="#6B4A32", side_kind="soil"):
    B.part(side_kind, side, bevel=0.5).box(0, 0, -D, 100, 100, D - 3)
    B.part(top_kind, top_color, bevel=0.4).box(0, 0, -3, 100, 100, 3)


def t_grass(B):
    block(B, "grass", "#4F8A38")


def t_road(B):
    block(B, "grass", "#4F8A38")
    B.part("asphalt", "#3C4048", bevel=0.2).box(0, 25, -0.2, 100, 50, 0.6)
    for x in range(4, 100, 16):
        B.part("paint", "#F2F2F2").box(x, 49, 0.4, 9, 2, 0.05)


def t_city_road(B):
    block(B, "concrete", "#A6A9AE", side="#7C7F85", side_kind="concrete")
    B.part("asphalt", "#33373E").box(0, 18, 0, 100, 64, 0.4)
    for x in range(4, 100, 16):
        B.part("paint", "#F2C94C").box(x, 49, 0.45, 9, 2, 0.05)
    for y in (22, 76):
        for x in range(0, 100, 6):
            B.part("paint", "#EDEDED").box(x, y, 0.45, 3, 1, 0.05)
    B.part("concrete", "#C3C5C9", bevel=0.2).box(0, 0, 0, 100, 18, 1.2)
    B.part("concrete", "#C3C5C9", bevel=0.2).box(0, 82, 0, 100, 18, 1.2)


def t_sidewalk(B):
    block(B, "concrete", "#B9BBBF", side="#7C7F85", side_kind="concrete")
    for x in range(0, 100, 10):
        for y in range(0, 100, 10):
            B.part("concrete", "#C9CBCF" if (x + y) % 20 else "#AFB2B7", bevel=0.4).box(x + 0.3, y + 0.3, 0, 9.4, 9.4, 0.6)


def t_water(B):
    block(B, "soil", "#6B4A32")
    B.part("water", "#1E5F86").box(1, 1, -2, 98, 98, 1.8)


def t_forest(B):
    block(B, "grass", "#3F7A30")
    rnd = random.Random(3)
    for k in range(14):
        tree(B, rnd.uniform(8, 92), rnd.uniform(8, 92), rnd.uniform(0.8, 1.2), "cone" if k % 3 else "round",
             ["#2F6B2A", "#3E7F35", "#2B5E27"][k % 3], seed=k)


def t_mountain(B):
    block(B, "grass", "#5A7F3A")
    R = B.part("concrete", "#7A746B", smooth=False)
    R.cyl(45, 45, 0, 42, 48, 7, r2=4)
    R.cyl(70, 30, 0, 26, 30, 6, r2=3)
    B.part("concrete", "#F2F4F7").cyl(45, 45, 38, 9, 10, 7, r2=4)


def t_desert(B):
    block(B, "soil", "#D8B77A", side="#B08A55")
    rnd = random.Random(5)
    for k in range(4):
        B.part("soil", "#E3C48A", smooth=True).sphere(rnd.uniform(20, 80), rnd.uniform(20, 80), -2, rnd.uniform(12, 20), sz=0.3)
    for x, y in ((30, 70), (72, 32)):
        C = B.part("foliage", "#4E7D3A", smooth=True)
        C.cyl(x, y, 0, 2, 16, 12)
        C.cyl_axis((x, y, 8), (x + 5, y, 10), 1.2, 10)
        C.cyl_axis((x + 5, y, 10), (x + 5, y, 15), 1.2, 10)


def t_snow(B):
    block(B, "concrete", "#EEF3F8", side="#6B5B4A", side_kind="soil")
    rnd = random.Random(7)
    for k in range(5):
        x, y = rnd.uniform(15, 85), rnd.uniform(15, 85)
        tree(B, x, y, 1.0, "cone", "#2B5E3A", seed=k)
        B.part("concrete", "#F7FAFD", smooth=True).cyl(x, y, 14, 5, 3, 10, r2=1)


def t_beach(B):
    block(B, "soil", "#E6CF98", side="#B08A55")
    B.part("water", "#1E7FA6").poly_prism([(0, 55), (100, 35), (100, 100), (0, 100)], -2, 1.9)
    B.part("paint", "#F2F4F7").poly_prism([(0, 53), (100, 33), (100, 36), (0, 56)], -0.3, 0.3)
    B.part("cloth", "#EB5757").cyl(30, 25, 0, 0.4, 18, 8)
    B.part("cloth", "#F2C94C", smooth=True).cyl(30, 25, 16, 11, 4, 16, r2=0.5)


TILES = {"grass": t_grass, "road": t_road, "city_road": t_city_road, "sidewalk": t_sidewalk, "water": t_water,
         "forest": t_forest, "mountain": t_mountain, "desert": t_desert, "snow": t_snow, "beach": t_beach}


# -- props --------------------------------------------------------------------------------------------
def p_tree(B):
    tree(B, 0, 0, 1.6, "round", "#4E8F3A")


def p_pine(B):
    tree(B, 0, 0, 1.6, "cone", "#2F6B2A")


def p_bush(B):
    bush(B, 0, 0, 1.6)


def p_lamp(B):
    lamp(B, 0, 0, 22)


def p_fence(B):
    M = B.part("metal", "#5C6570", rough=0.4)
    for k in range(7):
        M.box(k * 6, 0, 0, 0.8, 0.8, 12)
    for z in (3, 10):
        M.box(0, 0.1, z, 36.8, 0.6, 0.8)
    for k in range(6):
        for j in range(3):
            M.cyl_axis((k * 6 + 0.8, 0.4, 3.8 + j * 2), (k * 6 + 6, 0.4, 3.8 + j * 2 + 1.6), 0.18, 4)


def p_crate(B):
    W = B.part("paint", "#8A6440", rough=0.8, bevel=0.3)
    W.box(0, 0, 0, 12, 12, 12)
    S =B.part("paint", "#6E4F31", bevel=0.2)
    S.box(-0.3, -0.3, 0, 12.6, 1.2, 1.2).box(-0.3, -0.3, 10.8, 12.6, 1.2, 1.2)
    S.box(11.4, -0.3, 0, 1.2, 12.6, 1.2).box(11.4, -0.3, 10.8, 1.2, 12.6, 1.2)
    S.box(11.4, -0.3, 0, 1.2, 1.2, 12).box(11.4, 11.4, 0, 1.2, 1.2, 12).box(-0.3, 11.4, 0, 1.2, 1.2, 12)


def p_container(B):
    B.part("metal", "#C0392B", rough=0.5, bevel=0.3).box(0, 0, 0, 40, 16, 16)
    for k in range(0, 40, 2):
        B.part("metal", "#A83226").box(k, 15.9, 0.5, 0.8, 0.4, 15)
    B.part("metal", "#8E2A21").box(39.9, 1, 1, 0.4, 14, 14)


def p_watchtower(B):
    M = B.part("paint", "#6B5A43")
    for dx, dy in ((0, 0), (12, 0), (0, 12), (12, 12)):
        M.box(dx, dy, 0, 1.4, 1.4, 36)
    for z in (10, 22):
        M.cyl_axis((0.7, 0.7, z), (12.7, 12.7, z + 10), 0.4, 6)
    B.part("paint", "#7A6A50", bevel=0.3).box(-2, -2, 36, 17, 17, 8)
    B.part("roof", "#3F4A2E").cyl(6.5, 6.5, 44, 12, 6, 4, r2=0.5)


def p_helipad(B):
    B.part("concrete", "#5B6068", bevel=0.4).box(-25, -25, 0, 50, 50, 2)
    B.part("paint", "#2E3238").cyl(0, 0, 2, 22, 0.2, 48)
    B.part("paint", "#F2C94C").cyl(0, 0, 2.1, 21, 0.1, 48)
    B.part("paint", "#2E3238").cyl(0, 0, 2.15, 19, 0.1, 48)
    W = B.part("paint", "#F4F6F8")
    W.box(-8, -9, 2.3, 3, 18, 0.1).box(5, -9, 2.3, 3, 18, 0.1).box(-8, -1.5, 2.3, 16, 3, 0.1)


def p_bench(B):
    B.part("paint", "#6B4B34", bevel=0.2).box(0, 0, 4, 18, 5, 1).box(0, 0, 5, 18, 1, 6)
    B.part("metal", "#2E3238").box(1, 0, 0, 1, 5, 4).box(16, 0, 0, 1, 5, 4)


def p_barrier(B):
    for k in range(3):
        B.part("concrete", "#D5D7DA", bevel=0.6).profile([(0, 0), (8, 0), (6, 3), (5.5, 9), (2.5, 9), (2, 3)], k * 13, 12)
        if k == 1:
            B.part("paint", "#EB5757").box(0.5, k * 13, 5, 7, 12, 1.2)


PROPS = {"tree": p_tree, "pine": p_pine, "bush": p_bush, "street_lamp": p_lamp, "fence": p_fence, "crate": p_crate,
         "container": p_container, "watchtower": p_watchtower, "helipad": p_helipad, "bench": p_bench, "barrier": p_barrier}


def main():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    only = a[a.index("--only") + 1].split(",") if "--only" in a else []
    samples = int(a[a.index("--samples") + 1]) if "--samples" in a else 32
    sc = kit.reset(samples)
    for group, table in (("tiles", TILES), ("props", PROPS)):
        for code, fn in table.items():
            if only and code not in only:
                continue
            kit.clear_meshes()
            kit.clear_cameras()
            B = Builder()
            fn(B)
            objs = B.build()
            if group == "tiles":
                kit.lot_camera(sc, art_h=288, origin=(128, 150))
            else:
                kit.frame_objects(sc, 256, 256, 0.08, objs=objs)
            out = os.path.join(kit.ROOT, "art", "catalog", group, code + ".png")
            kit.render(sc, out)
            dst = os.path.join(kit.ROOT, "assets", "art", group)
            os.makedirs(dst, exist_ok=True)
            shutil.copy(out, os.path.join(dst, code + ".png"))
            print("rendered", group, code)


if __name__ == "__main__":
    main()
