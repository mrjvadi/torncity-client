"""Vehicles, rendered isometric and glossy (same camera and light as the city).

    tools/blender/app/blender -b --factory-startup -P art_src/blender/vehicles.py -- [--only jet] [--samples 48]

Writes art/catalog/vehicles/<code>.png (512 x 384) and assets/art/vehicles/<code>.png.
Every vehicle faces +x (the screen's lower left). Units: 1 = 10 cm.
"""
import math
import os
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit  # noqa: E402
from kit import Builder  # noqa: E402


def wheels(B, xs, y0, y1, r=3.2, w=2.4, rim="#C9CED6"):
    T = B.part("rubber", "#18191B", smooth=True)
    Rm = B.part("metal", rim, rough=0.25, smooth=True)
    for x in xs:
        for y, s in ((y0, -1), (y1, 1)):
            T.cyl_axis((x, y - w / 2, r), (x, y + w / 2, r), r, 24)
            Rm.cyl_axis((x, y + s * w / 2, r), (x, y + s * (w / 2 + 0.15), r), r * 0.62, 20)


def lights(B, x_front, x_back, y0, y1, z):
    H = B.part("emit", "#FFF6DD", strength=3)
    T = B.part("emit", "#FF2D2D", strength=2)
    for y in (y0 + 1.0, y1 - 3.0):
        H.box(x_front - 0.3, y, z, 0.6, 2.0, 1.0)
        T.box(x_back - 0.3, y, z, 0.6, 2.0, 0.9)


def glass_band(B, pts_xz, y0, width):
    """Windows: the cabin profile grown a little out of the body, across the
    full width, so the windscreen and side windows sit on the paint."""
    cx = sum(p[0] for p in pts_xz) / len(pts_xz)
    cz = sum(p[1] for p in pts_xz) / len(pts_xz)
    grown = [(cx + (x - cx) * 1.05, cz + (z - cz) * 1.08 + 0.25) for x, z in pts_xz]
    B.part("glass", "#1A2838").profile(grown, -0.2, width + 2 * y0 + 0.4)


def sports_car(B, color="#D62828"):
    W = 17
    body = [(0, 2.2), (40, 2.2), (41, 4.5), (38, 6.0), (26, 7.2), (20, 10.8), (12, 11.0), (6, 8.0), (0, 7.6)]
    B.part("carpaint", color, bevel=0.9, smooth=True).profile(body, 0, W)
    glass_band(B, [(25.6, 7.3), (19.8, 10.6), (12.4, 10.8), (7.0, 8.1)], 1.2, W - 2.4)
    B.part("rubber", "#111111").box(-0.4, 1.5, 2.2, 1.2, W - 3, 1.4)
    wheels(B, (8.5, 32), -0.3, W + 0.3, r=3.3)
    lights(B, 40.6, 0.2, 0, W, 5.0)
    B.part("carpaint", "#111111", bevel=0.2).box(-1.5, 2, 7.6, 3, W - 4, 0.6)


def suv(B, color="#1F2328"):
    W = 19
    body = [(0, 2.5), (44, 2.5), (45, 6), (44, 9), (34, 10), (30, 16), (6, 16.5), (1, 15), (0, 10)]
    B.part("carpaint", color, bevel=1.0, smooth=True).profile(body, 0, W)
    glass_band(B, [(33.5, 10.2), (29.6, 15.6), (6.8, 15.9), (4, 14), (4, 10.2)], 1.0, W - 2)
    B.part("metal", "#9AA3AE", rough=0.3).box(8, 1, 16.4, 24, 1, 1).box(8, W - 2, 16.4, 24, 1, 1)
    wheels(B, (9, 35), -0.4, W + 0.4, r=4.0, w=3.0)
    lights(B, 44.6, 0.2, 0, W, 7.5)


def police_car(B):
    W = 18
    body = [(0, 2.4), (44, 2.4), (45, 5.5), (43, 7.5), (32, 8.4), (27, 13.4), (12, 13.6), (7, 9), (0, 8.4)]
    B.part("carpaint", "#F4F6F8", bevel=0.9, smooth=True).profile(body, 0, W)
    B.part("carpaint", "#10245A", bevel=0.4).profile([(12, 2.4), (32, 2.4), (32, 7.4), (12, 7.4)], -0.2, W + 0.4)
    glass_band(B, [(31.6, 8.5), (26.8, 13.2), (12.4, 13.4), (7.6, 9)], 1.0, W - 2)
    B.part("metal", "#2A2D33", bevel=0.2).box(17, 3, 13.6, 7, W - 6, 1.2)
    B.part("emit", "#2F80ED", strength=8).box(17.5, 3.5, 14.8, 6, 5, 1.2)
    B.part("emit", "#FF2D2D", strength=8).box(17.5, W - 8.5, 14.8, 6, 5, 1.2)
    wheels(B, (9, 35), -0.3, W + 0.3)
    lights(B, 44.6, 0.2, 0, W, 5.2)


def ambulance(B):
    W = 20
    B.part("carpaint", "#F7F7F2", bevel=1.0).profile([(0, 2.5), (38, 2.5), (38, 22), (0, 22)], 0, W)
    B.part("carpaint", "#F7F7F2", bevel=1.0, smooth=True).profile([(38, 2.5), (50, 2.5), (51, 8), (48, 11), (44, 17), (38, 17.5)], 0.5, W - 1)
    glass_band(B, [(43.6, 16.6), (47.5, 11.2), (40, 11.2), (40, 16.6)], 1.3, W - 2.6)
    B.part("paint", "#D62828").box(0, -0.25, 9, 38, 0.3, 2.2).box(0, W - 0.05, 9, 38, 0.3, 2.2)
    R = B.part("paint", "#D62828")
    for y in (-0.3, W + 0.0):
        R.box(15, y, 12.5, 8, 0.3, 2.5)
        R.box(17.75, y, 9.75, 2.5, 0.3, 8)
    B.part("emit", "#FF2D2D", strength=8).box(36, 2, 22, 3, 6, 1.4)
    B.part("emit", "#2F80ED", strength=8).box(36, W - 8, 22, 3, 6, 1.4)
    wheels(B, (10, 42), -0.3, W + 0.3, r=3.6)
    lights(B, 50.8, 0.2, 0.5, W - 0.5, 6.0)


def motorbike(B):
    T = B.part("rubber", "#18191B", smooth=True)
    for x in (0, 22):
        T.cyl_axis((x, -1.0, 4.6), (x, 1.0, 4.6), 4.6, 24)
        B.part("metal", "#AEB6C0", rough=0.2, smooth=True).cyl_axis((x, -1.1, 4.6), (x, 1.1, 4.6), 2.6, 16)
    P = B.part("carpaint", "#D98E04", bevel=0.6, smooth=True)
    P.profile([(4, 7), (14, 5.5), (20, 8), (18, 12), (8, 12)], -2.2, 4.4)
    B.part("leather", "#1A1A1A", bevel=0.5).profile([(0, 10), (9, 10.5), (9, 12.5), (1, 12)], -2.4, 4.8)
    M = B.part("metal", "#2B2F36", rough=0.3)
    M.cyl_axis((22, 0, 4.6), (19, 0, 15), 0.6, 8)
    M.cyl_axis((19, -4, 15), (19, 4, 15), 0.5, 8)
    M.cyl_axis((0, 0, 4.6), (8, 0, 10), 0.6, 8)
    B.part("metal", "#B8C0C9", rough=0.2).cyl_axis((4, 2.6, 4), (15, 2.6, 5), 0.9, 12)
    B.part("emit", "#FFF6DD", strength=4).sphere(21.5, 0, 13, 1.4)


def truck(B, color="#E9ECEF", cab="#2F80ED"):
    W = 22
    B.part("paint", color, bevel=0.6).box(0, 0, 4, 52, W, 24)
    for k in range(1, 12):
        B.part("paint", "#C9CDD2").box(k * 4.3, W - 0.1, 4, 0.3, 0.4, 24)
    B.part("carpaint", cab, bevel=1.2, smooth=True).profile([(53, 3), (70, 3), (71, 10), (69, 17), (64, 24), (53, 24)], 0.5, W - 1)
    glass_band(B, [(63.6, 23.4), (68.4, 17.2), (60, 17.2), (60, 23.4)], 1.2, W - 2.4)
    B.part("metal", "#3A3F47").box(0, 1, 2, 70, W - 2, 2)
    wheels(B, (8, 16, 60), -0.3, W + 0.3, r=4.2, w=3.2)
    lights(B, 70.8, 0.2, 0.5, W - 0.5, 7)


def military_truck(B):
    W = 22
    olive = "#4F5B3A"
    B.part("paint", olive, bevel=0.5).box(0, 0, 5, 40, W, 6)
    B.part("cloth", "#5E6B43", smooth=True).profile([(0, 11), (40, 11), (40, 21), (37, 24), (3, 24), (0, 21)], 0, W)
    B.part("paint", olive, bevel=1.2).profile([(40, 4), (58, 4), (58, 13), (55, 20), (41, 20)], 0.5, W - 1)
    glass_band(B, [(54.6, 19.4), (57.4, 13.4), (50, 13.4), (50, 19.4)], 1.4, W - 2.8)
    B.part("metal", "#2E3322").box(58, 2, 5, 1.5, W - 4, 4)
    wheels(B, (8, 18, 50), -0.4, W + 0.4, r=4.6, w=3.6, rim="#3E4630")


def tank(B):
    W = 30
    olive = "#56613F"
    B.part("paint", olive, bevel=1.0).profile([(0, 5), (4, 12), (50, 12), (56, 5), (50, 2), (5, 2)], 0, W)
    T = B.part("rubber", "#1E1F1C", bevel=0.6)
    T.profile([(-1, 5), (4, 0), (52, 0), (57, 5), (52, 9), (4, 9)], -1.5, 6.5)
    T.profile([(-1, 5), (4, 0), (52, 0), (57, 5), (52, 9), (4, 9)], W - 5, 6.5)
    Wh = B.part("metal", "#3B4030", smooth=True)
    for x in range(6, 54, 8):
        for y in (-1.8, W + 1.8):
            Wh.cyl_axis((x, y - 0.3, 4.2), (x, y + 0.3, 4.2), 3.4, 14)
    B.part("paint", olive, bevel=1.0, smooth=True).profile([(12, 12), (40, 12), (42, 16), (36, 21), (18, 21), (12, 17)], 6, W - 12)
    B.part("paint", "#4A5436", smooth=True).cyl_axis((40, W / 2, 17), (78, W / 2, 17), 1.4, 16)
    B.part("paint", "#4A5436", smooth=True).cyl_axis((74, W / 2, 17), (80, W / 2, 17), 2.0, 16)
    B.part("paint", "#3E4630").cyl(24, W / 2, 21, 4, 2.4, 20)


def helicopter(B):
    P = B.part("carpaint", "#2B3A4E", bevel=0.8, smooth=True)
    P.sphere(30, 0, 14, 12, sx=1.4, sy=0.75, sz=0.8, segs=32, rings=16)
    P.cyl_axis((0, 0, 16), (22, 0, 14), 2.0, 16)
    P.profile([(-2, 16), (2, 16), (0, 26), (-4, 26)], -0.6, 1.2)
    B.part("glass", "#16202C", smooth=True).sphere(40, 0, 15, 8, sx=1.1, sy=0.8, sz=0.8, segs=28, rings=14)
    Sk = B.part("metal", "#3A3F47", rough=0.3)
    for y in (-7, 7):
        Sk.cyl_axis((18, y, 2), (46, y, 2), 0.8, 10)
        Sk.cyl_axis((24, y, 2), (24, y * 0.6, 8), 0.6, 8)
        Sk.cyl_axis((40, y, 2), (40, y * 0.6, 8), 0.6, 8)
    R = B.part("metal", "#23272D", rough=0.4)
    R.cyl(30, 0, 23, 1.2, 4, 12)
    for a in (20, 110):
        r = math.radians(a)
        R.cyl_axis((30 - 36 * math.cos(r), -36 * math.sin(r), 27.2), (30 + 36 * math.cos(r), 36 * math.sin(r), 27.2), 0.7, 6)
    R.cyl_axis((-1, 1, 16 - 6), (-1, 1, 16 + 6), 0.4, 6)   # tail rotor


def plane(B, length=90, span=84, color="#F4F6F8", tail="#2F80ED", engines=2, jet=False):
    r = 5.5 if not jet else 4.0
    P = B.part("carpaint", color, smooth=True)
    P.cyl_axis((8, 0, 10), (length - 12, 0, 10), r, 28)
    P.sphere(length - 12, 0, 10, r, sx=2.2, segs=28, rings=14)
    P.sphere(8, 0, 10.6, r, sx=2.0, sy=0.8, sz=0.7, segs=24, rings=12)
    Wg = B.part("carpaint", "#DCE1E8", bevel=0.4)
    for s in (1, -1):
        pts = [(length * 0.42, 0), (length * 0.58, 0), (length * 0.44, s * span / 2), (length * 0.38, s * span / 2)]
        Wg.poly_prism(pts if s > 0 else list(reversed(pts)), 8.2, 1.0)
        ts = [(4, 0), (13, 0), (6, s * span / 6), (2, s * span / 6)]
        Wg.poly_prism(ts if s > 0 else list(reversed(ts)), 12, 0.8)
    B.part("carpaint", tail, bevel=0.4).profile([(2, 12), (14, 12), (6, 30), (0, 30)], -0.6, 1.2)
    E = B.part("metal", "#AEB6C0", rough=0.3, smooth=True)
    if engines:
        if jet:
            for s in (1, -1):
                E.cyl_axis((10, s * 6.5, 13), (22, s * 6.5, 13), 2.4, 18)
        else:
            for s in (1, -1):
                E.cyl_axis((length * 0.4, s * span * 0.2, 6), (length * 0.52, s * span * 0.2, 6), 3.2, 20)
    G = B.part("glass", "#16202C")
    for k in range(int((length - 30) / 4)):
        x = 16 + k * 4
        G.box(x, r - 0.3, 11.2, 1.6, 0.6, 1.6)
    G.box(length - 9, -3, 12.2, 2.4, 6, 1.6)
    B.part("carpaint", tail).box(8, r - 0.4, 7.2, length - 22, 0.6, 0.9)


def jet(B):
    plane(B, length=56, span=40, color="#EDEFF2", tail="#1B1F24", jet=True)


def airliner(B):
    plane(B, length=100, span=92, color="#F4F6F8", tail="#2F80ED")


def cargo_ship(B):
    L, W = 120, 22
    B.part("paint", "#7A2E2E", bevel=1.0).profile([(0, 0), (L - 12, 0), (L, 10), (L, 14), (0, 14)], 0, W)
    B.part("paint", "#1D2733", bevel=0.5).profile([(0, 10), (L, 10), (L, 14), (0, 14)], -0.1, W + 0.2)
    B.part("paint", "#F4F6F8", bevel=0.6).box(4, 3, 14, 14, W - 6, 20)
    windows_ = B.part("glass", "#16202C")
    windows_.box(17.8, 5, 28, 0.4, W - 10, 3)
    cols = ["#C0392B", "#2E86C1", "#27AE60", "#E0A63A", "#8E44AD", "#D35400"]
    for i in range(7):
        for j in range(3):
            for k in range(2):
                B.part("metal", cols[(i + j * 2 + k) % 6], rough=0.5, bevel=0.3).box(24 + i * 12, 1.5 + j * 6.4, 14 + k * 6, 11.4, 6.2, 5.8)


ALL = {"sports_car": sports_car, "suv": suv, "motorbike": motorbike, "truck": truck, "police_car": police_car,
       "ambulance": ambulance, "military_truck": military_truck, "helicopter": helicopter, "jet": jet,
       "airliner": airliner, "cargo_ship": cargo_ship, "tank": tank}


def main():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    only = a[a.index("--only") + 1].split(",") if "--only" in a else []
    samples = int(a[a.index("--samples") + 1]) if "--samples" in a else 48
    sc = kit.reset(samples)
    for code, fn in ALL.items():
        if only and code not in only:
            continue
        kit.clear_meshes()
        kit.clear_cameras()
        B = Builder()
        fn(B)
        objs = B.build()
        kit.frame_objects(sc, 512, 384, 0.06, objs=objs)
        out = os.path.join(kit.ROOT, "art", "catalog", "vehicles", code + ".png")
        kit.render(sc, out)
        dst = os.path.join(kit.ROOT, "assets", "art", "vehicles")
        os.makedirs(dst, exist_ok=True)
        shutil.copy(out, os.path.join(dst, code + ".png"))
        print("rendered", code)


if __name__ == "__main__":
    main()
