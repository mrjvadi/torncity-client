"""City buildings, one per lot (100 x 100 units = 10 m), modelled with kit.py.

    tools/blender/app/blender -b --factory-startup -P art_src/blender/buildings.py -- [--only bank,park] [--samples 40]

Writes, per building:
  assets/art/places/render/<code>.png      map sprite: a thin kerb, 512 x 576
  art/catalog/buildings/<code>.png         catalogue: a soil-sided block
Place codes follow configs/content/places.yml; the extra codes (hotel,
warehouse, mall, hq, bank, lab) fill empty lots and the catalogue.
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit  # noqa: E402
from kit import Builder, windows, curtain_wall, parapet, rooftop, door, sign, tree, bush, lamp, base, car  # noqa: E402


# Visible facades are x-max (screen lower-left) and y-max (screen lower-right).

def apartment(B, x, y, w, d, floors, wall="#C8B8A2", seed=1, kind="concrete"):
    fh = 11
    h = floors * fh
    B.part(kind, wall, bevel=0.5).box(x, y, 0, w, d, h)
    B.part("concrete", "#8C8479", bevel=0.3).box(x - 0.5, y - 0.5, 0, w + 1, d + 1, 3)
    windows(B, x, y, 3, w, d, h - 3, floors, max(2, int(w / 9)), lit=0.12, seed=seed)
    # balconies on the front
    Bal = B.part("concrete", "#D9D4CC", bevel=0.2)
    Rail = B.part("metal", "#5C6570", rough=0.4)
    for f in range(1, floors):
        z = 3 + f * (h - 3) / floors
        for k in range(max(1, int(w / 18))):
            bx = x + 4 + k * 18
            Bal.box(bx, y + d, z - 0.8, 10, 4, 0.8)
            Rail.box(bx, y + d + 3.6, z, 10, 0.4, 3.2)
    parapet(B, x, y, h, w, d, color="#B7AE9F")
    rooftop(B, x, y, h + 0.4, w, d, seed)
    return h


def residential_area(B):
    base(B, "grass", **B.base)
    B.part("concrete", "#B9BBBE", bevel=0.2).box(4, 60, 0, 92, 10, 0.5)
    apartment(B, 8, 8, 44, 30, 6, "#D4C2A8", 2)
    apartment(B, 60, 10, 30, 36, 4, "#B98E74", 3, "brick")
    # small houses in front
    for i, (hx, col, roof) in enumerate(((10, "#E8E0D2", "#9C4A3A"), (40, "#D9E3EA", "#3E5A7A"))):
        B.part("paint", col, bevel=0.4).box(hx, 74, 0, 22, 18, 12)
        R = B.part("tile", roof, bevel=0.3)
        R.poly_prism([(hx - 1.5, 72.5), (hx + 23.5, 72.5), (hx + 23.5, 83), (hx - 1.5, 83)], 12, 0.1)
        # gable roof as two slopes
        R.quad([(hx - 1.5, 72.5, 12), (hx + 23.5, 72.5, 12), (hx + 23.5, 83, 19), (hx - 1.5, 83, 19)])
        R.quad([(hx - 1.5, 83, 19), (hx + 23.5, 83, 19), (hx + 23.5, 93.5, 12), (hx - 1.5, 93.5, 12)])
        B.part("paint", col).quad([(hx + 22, 74, 12), (hx + 22, 92, 12), (hx + 22, 83, 18.5)])
        windows(B, hx, 74, 1.5, 22, 18, 9, 1, 2, seed=i + 5)
        door(B, "x", hx + 22, 80, 0, 5, 8, canopy=None)
    for tx, ty in ((70, 62), (88, 80), (4, 50)):
        tree(B, tx, ty, 1.0)
    bush(B, 34, 90)
    car(B, 60, 64, color="#2E86DE")
    lamp(B, 56, 58)


def business_district(B):
    base(B, None, **B.base)
    B.part("concrete", "#C3C5C9", bevel=0.2).box(2, 2, 0, 96, 96, 0.6)
    curtain_wall(B, 10, 10, 0.6, 34, 34, 150, 14, glass="#23476E")
    B.part("metal", "#C9D1DB", bevel=0.3).box(12, 12, 150.6, 30, 30, 5)
    B.part("metal", "#8D98A5").cyl(27, 27, 155, 0.6, 16, 6)
    B.part("emit", "#FF4D4D", strength=5).sphere(27, 27, 171.5, 1.0)
    curtain_wall(B, 54, 12, 0.6, 30, 30, 104, 10, glass="#2E5E73", mullion="#D5DCE4")
    B.part("metal", "#DDE3EA", bevel=0.3).box(52.5, 10.5, 104.6, 33, 33, 3)
    # the bank: a stone front with columns
    S = B.part("concrete", "#E4DED1", bevel=0.4)
    S.box(46, 56, 0.6, 46, 34, 26)
    S.box(44, 54, 26.6, 50, 38, 4)
    C = B.part("concrete", "#F2EEE6", bevel=0.2, smooth=True)
    for k in range(6):
        C.cyl(46 + 34 + 5, 58 + k * 6, 0.6, 1.6, 26, 16)
    for k in range(6):
        C.cyl(50 + k * 7, 90 + 4, 0.6, 1.6, 26, 16)
    S.box(44, 54, 0.6, 50, 42, 2)
    door(B, "x", 92, 68, 2.6, 10, 14)
    B.part("metal", "#D4A63A", rough=0.25).cyl(69, 96, 32, 4, 1.2, 24)
    for tx, ty in ((8, 92), (30, 90)):
        tree(B, tx, ty, 0.9, "cone", "#3F7A3A")
    car(B, 10, 60, color="#1C1C1E")
    lamp(B, 40, 94)


def bazaar(B):
    base(B, None, **B.base)
    B.part("concrete", "#CDBFA6", bevel=0.2).box(2, 2, 0, 96, 96, 0.6)
    W = B.part("brick", "#C9A77C", scale=0.45, bevel=0.4)
    W.box(8, 8, 0.6, 70, 44, 24)
    # arched openings on the front
    for k in range(6):
        B.part("paint", "#3A2A1E").box(8 + 5 + k * 11, 52.3, 0.6, 6, 0.4, 14)
    B.part("paint", "#2FA59A", bevel=0.2).box(8, 52, 20, 70, 0.8, 2.2)
    for k, cx in enumerate((22, 43, 64)):
        B.part("concrete", "#D8C3A0").cyl(cx, 30, 24.6, 9, 3, 32)
        B.part("paint", "#2FA59A" if k != 1 else "#E0A63A", rough=0.3, smooth=True).dome(cx, 30, 27.6, 9.5, 11)
    # stalls with striped awnings
    for i, (sx, col) in enumerate(((10, "#C0392B"), (36, "#E0A63A"), (62, "#2E86C1"))):
        B.part("paint", "#7A5236", bevel=0.2).box(sx, 64, 0.6, 22, 12, 7)
        for s in range(5):
            c = col if s % 2 == 0 else "#F4EFE6"
            B.part("cloth", c).quad([(sx + s * 4.4, 62, 16), (sx + (s + 1) * 4.4, 62, 16),
                                     (sx + (s + 1) * 4.4, 80, 11), (sx + s * 4.4, 80, 11)])
        for k, pc in enumerate(("#E67E22", "#27AE60", "#C0392B")):
            B.part("paint", pc, smooth=True).sphere(sx + 5 + k * 6, 72, 8.4, 2.2, sz=0.6)
        B.part("metal", "#4A4F57").box(sx, 79, 0.6, 0.6, 0.6, 11)
        B.part("metal", "#4A4F57").box(sx + 21.4, 79, 0.6, 0.6, 0.6, 11)
    for c in ((84, 30), (88, 86)):
        tree(B, c[0], c[1], 0.9)
    lamp(B, 82, 60)


def university(B):
    base(B, "grass", **B.base)
    B.part("concrete", "#C9C3B5", bevel=0.2).box(40, 50, 0, 20, 48, 0.5)
    W = B.part("brick", "#A9573E", scale=0.4, bevel=0.4)
    W.box(6, 10, 0, 86, 36, 34)
    windows(B, 6, 10, 2, 86, 36, 30, 3, 8, frame="#EDE6D8", glass="#2F4D66", lit=0.1, seed=11)
    B.part("concrete", "#E6DCC8", bevel=0.3).box(4, 8, 34, 90, 40, 3)
    R = B.part("roof", "#4B5563")
    R.quad([(4, 8, 37), (94, 8, 37), (94, 28, 46), (4, 28, 46)])
    R.quad([(4, 28, 46), (94, 28, 46), (94, 48, 37), (4, 48, 37)])
    # centre block with a dome and a clock
    E = B.part("concrete", "#E9E1CF", bevel=0.4)
    E.box(38, 30, 0, 24, 22, 52)
    B.part("concrete", "#D9CDB5").cyl(50, 41, 52, 10, 5, 32)
    B.part("metal", "#2B8C7E", rough=0.35, smooth=True).dome(50, 41, 57, 10.5, 12)
    B.part("metal", "#C9A33A").cyl(50, 41, 69, 0.4, 7, 6)
    B.part("paint", "#FAFAF5", smooth=True).cyl_axis((50, 52, 42), (50, 53, 42), 5, 32)
    B.part("paint", "#222222").box(49.6, 53, 41.6, 0.8, 0.5, 4)
    door(B, "y", 45, 52, 0, 10, 14, canopy="#6B7C8F")
    for tx, ty in ((10, 64), (24, 84), (80, 62), (90, 86), (66, 90)):
        tree(B, tx, ty, 1.0 if tx % 2 else 0.85, "round", "#3E7F35" if tx > 50 else "#4E8F3A")
    for bx in (30, 70):
        B.part("paint", "#6B4B34").box(bx, 70, 1.5, 8, 2, 1)


def city_hall(B):
    base(B, None, **B.base)
    B.part("concrete", "#D7D8DB", bevel=0.2).box(2, 2, 0, 96, 96, 0.6)
    S = B.part("concrete", "#EEE9DF", bevel=0.5)
    S.box(10, 12, 0.6, 76, 56, 34)
    S.box(8, 10, 34.6, 80, 60, 4)
    windows(B, 10, 12, 4, 76, 56, 28, 2, 7, frame="#F7F4EE", glass="#2B4460", sill=False, seed=21)
    # portico
    C = B.part("concrete", "#F8F5EF", smooth=True)
    for k in range(7):
        C.cyl(90, 22 + k * 6.5, 0.6, 1.8, 30, 16)
    S.box(86, 18, 30.6, 8, 46, 4)
    B.part("concrete", "#F2EDE3").quad([(94, 18, 34.6), (94, 64, 34.6), (94, 41, 44)])
    for s in range(4):
        B.part("concrete", "#CFCAC0", bevel=0.2).box(88 + s * 2, 16, 0.6, 12 - s * 2, 52, 0.8 * (4 - s))
    B.part("concrete", "#F1ECE2").cyl(46, 40, 38.6, 15, 12, 40)
    B.part("metal", "#D4A63A", rough=0.2, smooth=True).dome(46, 40, 50.6, 16, 16)
    B.part("metal", "#C9A33A").cyl(46, 40, 66, 0.5, 8, 6)
    # flag
    B.part("metal", "#B8BEC6").cyl(78, 80, 0.6, 0.5, 44, 8)
    B.part("cloth", "#2FA59A").quad([(78, 80, 44), (78, 92, 43), (78, 92, 36), (78, 80, 37)])
    for tx, ty in ((10, 84), (30, 86)):
        tree(B, tx, ty, 0.8, "cone", "#3F7A3A")
    lamp(B, 60, 88)


def police_station(B):
    base(B, None, **B.base)
    B.part("asphalt", "#3C4149").box(2, 60, 0, 96, 38, 0.4)
    B.part("concrete", "#C3C6CB", bevel=0.2).box(2, 2, 0, 96, 58, 0.6)
    S = B.part("paint", "#F2F4F7", bevel=0.5)
    S.box(8, 8, 0.6, 76, 44, 30)
    B.part("paint", "#1F4E9C", bevel=0.3).box(8, 8, 0.6, 76, 44, 8)
    windows(B, 8, 8, 10, 76, 44, 18, 1, 7, frame="#DDE3EA", glass="#1D3957", sill=False, seed=31)
    parapet(B, 8, 8, 30.6, 76, 44, color="#1F4E9C")
    sign(B, "y", 30, 52.2, 20, 30, 7, "#12356F")
    door(B, "y", 38, 52, 0.6, 12, 13, canopy="#12356F")
    B.part("metal", "#9AA3AE").cyl(70, 20, 31, 0.5, 26, 6)
    B.part("metal", "#9AA3AE").cyl_axis((66, 20, 50), (74, 20, 50), 0.3, 6)
    B.part("emit", "#FF3B30", strength=6).box(30, 20, 31.2, 4, 3, 2)
    B.part("emit", "#2F80ED", strength=6).box(36, 20, 31.2, 4, 3, 2)
    car(B, 10, 70, color="#F4F6F8", kind="sedan")
    B.part("paint", "#1F4E9C").box(14, 69.9, 3.2, 8, 0.2, 1.4)
    B.part("emit", "#2F80ED", strength=5).box(15, 72, 9.9, 2, 4, 1)
    B.part("emit", "#FF3B30", strength=5).box(17.5, 72, 9.9, 2, 4, 1)
    car(B, 36, 70, color="#F4F6F8")
    for k in range(4):
        B.part("paint", "#F2F2F2").box(8 + k * 22, 64, 0.45, 0.8, 30, 0.1)
    lamp(B, 90, 58)


def hospital(B):
    base(B, None, **B.base)
    B.part("concrete", "#CDD0D4", bevel=0.2).box(2, 2, 0, 96, 96, 0.6)
    S = B.part("paint", "#F4F6F8", bevel=0.5)
    S.box(8, 8, 0.6, 56, 56, 64)
    windows(B, 8, 8, 4, 56, 56, 58, 6, 5, frame="#E2E7EE", glass="#2A5277", seed=41, lit=0.08)
    B.part("paint", "#D64541", bevel=0.2).box(7.5, 7.5, 60, 57, 57, 4.6)
    B.part("concrete", "#6E747C").box(10, 10, 64.6, 52, 52, 0.4)
    B.part("paint", "#3D434C").cyl(36, 36, 65, 16, 0.5, 40)
    B.part("paint", "#F4F6F8").box(30, 34, 65.6, 12, 4, 0.2)
    B.part("paint", "#F4F6F8").box(30, 30, 65.6, 3, 12, 0.2)
    B.part("paint", "#F4F6F8").box(39, 30, 65.6, 3, 12, 0.2)
    W = B.part("paint", "#EEF1F5", bevel=0.5)
    W.box(64, 30, 0.6, 28, 46, 30)
    windows(B, 64, 30, 3, 28, 46, 26, 2, 3, frame="#E2E7EE", glass="#2A5277", seed=42)
    R = B.part("emit", "#E74C3C", strength=2.5)
    R.box(92.4, 48, 14, 0.4, 10, 3.5)
    R.box(92.4, 51.25, 10.75, 0.4, 3.5, 10)
    B.part("paint", "#D64541", bevel=0.3).box(20, 64, 12, 30, 10, 1.4)
    for px in (22, 47):
        B.part("metal", "#9AA3AE").cyl(px, 72, 0.6, 0.5, 12, 8)
    car(B, 24, 76, color="#F7F7F2", kind="van", length=20, width=9)
    B.part("paint", "#D64541").box(30, 84.95, 4, 8, 0.3, 1.6)
    B.part("emit", "#FF3B30", strength=6).box(28, 78, 12, 3, 5, 1)
    tree(B, 86, 88, 0.9)
    lamp(B, 60, 90)


def train_station(B):
    base(B, None, **B.base)
    B.part("concrete", "#BFC2C6", bevel=0.2).box(2, 2, 0, 96, 50, 0.6)
    B.part("soil", "#6E6356").box(2, 52, 0, 96, 46, 0.5)
    for y0 in (60, 78):
        for x in range(4, 98, 4):
            B.part("paint", "#5B4636", rough=0.9).box(x, y0 - 1, 0.5, 1.8, 12, 0.6)
        M = B.part("metal", "#A7B0BA", rough=0.3)
        M.box(2, y0 + 1.5, 1.1, 96, 0.8, 0.8)
        M.box(2, y0 + 8.5, 1.1, 96, 0.8, 0.8)
    B.part("concrete", "#D4D1C9", bevel=0.3).box(2, 50, 0, 96, 7, 3)
    S = B.part("brick", "#C59C6E", scale=0.4, bevel=0.4)
    S.box(8, 8, 0.6, 80, 38, 22)
    windows(B, 8, 8, 2, 80, 38, 18, 1, 7, frame="#EDE3D2", glass="#2A4B69", sill=False, seed=51)
    # glass barrel vault
    import math
    G = B.part("glass", "#6FA6C9")
    Rb = B.part("metal", "#E1E5EA", rough=0.3)
    n = 12
    for k in range(n):
        a0, a1 = math.pi * k / n, math.pi * (k + 1) / n
        y0_, y1_ = 27 - 19 * math.cos(a0), 27 - 19 * math.cos(a1)
        z0_, z1_ = 22.6 + 14 * math.sin(a0), 22.6 + 14 * math.sin(a1)
        G.quad([(8, y0_, z0_), (88, y0_, z0_), (88, y1_, z1_), (8, y1_, z1_)])
    for k in range(9):
        x = 8 + k * 10
        for j in range(n):
            a0, a1 = math.pi * j / n, math.pi * (j + 1) / n
            Rb.cyl_axis((x, 27 - 19 * math.cos(a0), 22.6 + 14 * math.sin(a0)), (x, 27 - 19 * math.cos(a1), 22.6 + 14 * math.sin(a1)), 0.5, 6)
    # the train
    for i, x in enumerate((6, 38)):
        car_ = B.part("carpaint", "#2E86C1", bevel=1.0)
        car_.box(x, 60.5, 2, 30, 9, 10)
        B.part("paint", "#F2F4F7").box(x, 60.4, 6, 30, 9.2, 1.2)
        for w in range(5):
            B.part("glass", "#1B2533").box(x + 2 + w * 5.6, 69.55, 7.6, 3.6, 0.2, 2.6)
    B.part("carpaint", "#F2C94C", bevel=1.2).box(70, 60.5, 2, 18, 9, 10)
    B.part("glass", "#1B2533").box(84, 60.8, 7, 4, 8.4, 3)
    lamp(B, 94, 50)


def bus_terminal(B):
    base(B, None, **B.base)
    B.part("asphalt", "#3A3F47").box(2, 40, 0, 96, 58, 0.4)
    B.part("concrete", "#C8C9CC", bevel=0.2).box(2, 2, 0, 96, 38, 0.6)
    S = B.part("paint", "#E9E2D3", bevel=0.4)
    S.box(8, 6, 0.6, 50, 26, 22)
    windows(B, 8, 6, 2, 50, 26, 18, 1, 5, frame="#D9D2C4", glass="#244463", sill=False, seed=61)
    B.part("paint", "#F2994A", bevel=0.3).box(6, 4, 22.6, 54, 30, 3)
    for px in (12, 42, 72):
        for py in (42, 60):
            B.part("metal", "#8C96A2").cyl(px, py, 0.4, 0.8, 24, 8)
    B.part("metal", "#2FA59A", rough=0.4, bevel=0.3).box(8, 38, 24, 86, 28, 1.4)
    for k in range(5):
        B.part("paint", "#F2F2F2").box(10 + k * 17, 70, 0.45, 0.8, 26, 0.1)
    # the bus
    P = B.part("carpaint", "#F2C94C", bevel=1.0)
    P.box(20, 74, 2.2, 52, 12, 14)
    G = B.part("glass", "#1B2533")
    for w in range(7):
        G.box(23 + w * 7, 85.95, 8.5, 5.6, 0.2, 4.5)
    G.box(71.95, 75, 6, 0.2, 10, 7)
    B.part("paint", "#FFFFFF").box(20, 85.96, 5, 52, 0.2, 1)
    R = B.part("rubber", "#1A1A1C", smooth=True)
    for a in (28, 62):
        R.cyl_axis((a, 73.4, 2.4), (a, 86.6, 2.4), 2.4, 14)
    tree(B, 88, 12, 0.9)
    lamp(B, 66, 36)


def airport(B):
    base(B, "grass", **B.base)
    B.part("asphalt", "#40454D").box(2, 56, 0, 96, 32, 0.4)
    for x in range(8, 94, 12):
        B.part("paint", "#F2F2F2").box(x, 71.3, 0.45, 6, 1.4, 0.1)
    T = B.part("paint", "#E7EAEE", bevel=0.4)
    T.box(6, 8, 0, 64, 32, 20)
    B.part("glass", "#3A6E96").box(6, 8, 4, 64.5, 32.5, 12)
    B.part("metal", "#F4F6F8", bevel=0.4).box(4, 6, 20, 68, 36, 3)
    # control tower
    B.part("concrete", "#EDEFF2", smooth=True).cyl(84, 24, 0, 5, 62, 24)
    B.part("concrete", "#D5D9DE").cyl(84, 24, 62, 10, 3, 32)
    B.part("glass", "#4A83AE").cyl(84, 24, 65, 9, 8, 32)
    B.part("metal", "#F4F6F8").cyl(84, 24, 73, 10, 2, 32)
    B.part("metal", "#9AA3AE").cyl(84, 24, 75, 0.4, 10, 6)
    B.part("emit", "#FF3B30", strength=6).sphere(84, 24, 85.5, 1)
    # an airliner parked on the apron (fuselage along x)
    P = B.part("carpaint", "#F4F6F8", smooth=True)
    P.cyl_axis((26, 72, 6), (74, 72, 6), 4.2, 24)
    P.sphere(74, 72, 6, 4.2, sx=2.0, sy=1.0, sz=1.0)
    P.sphere(26, 72, 6.6, 4.0, sx=1.8, sy=0.9, sz=0.9)
    W = B.part("carpaint", "#D9DEE5", bevel=0.4)
    W.poly_prism([(44, 72), (54, 72), (48, 98), (42, 98)], 4.6, 0.8)
    W.poly_prism([(44, 72), (54, 72), (48, 46), (42, 46)], 4.6, 0.8)
    W.poly_prism([(26, 72), (32, 72), (28, 80), (25, 80)], 7, 0.6)
    W.poly_prism([(26, 72), (32, 72), (28, 64), (25, 64)], 7, 0.6)
    B.part("carpaint", "#2F80ED", bevel=0.3).box(24, 71.5, 9, 7, 1, 10)
    B.part("glass", "#1B2533").box(78, 69.5, 7.5, 3, 5, 1.6)
    R = B.part("metal", "#9AA3AE", rough=0.35, smooth=True)
    R.cyl_axis((44, 84, 3.4), (51, 84, 3.4), 2, 16)
    R.cyl_axis((44, 60, 3.4), (51, 60, 3.4), 2, 16)
    tree(B, 94, 92, 0.8, "cone", "#3F7A3A")


def industrial_zone(B):
    base(B, None, **B.base)
    B.part("concrete", "#A8A9A6", bevel=0.2).box(2, 2, 0, 96, 96, 0.6)
    S = B.part("metal", "#8D9AAB", rough=0.5, bevel=0.3)
    S.box(6, 12, 0.6, 62, 50, 22)
    for k in range(0, 62, 3):
        B.part("metal", "#7C8898").box(6 + k, 61.8, 0.6, 0.6, 0.6, 22)
    B.part("metal", "#4B5563").box(24, 61.9, 0.6, 18, 0.5, 14)
    windows(B, 6, 12, 14, 62, 50, 6, 1, 6, frame="#8D9AAB", glass="#2E4A63", sill=False, seed=71)
    for k in range(4):
        y0 = 12 + k * 12.5
        B.part("glass", "#7FB0CF").quad([(6, y0, 22.6), (68, y0, 22.6), (68, y0, 31), (6, y0, 31)])
        B.part("metal", "#AEB9C6", rough=0.4).quad([(6, y0, 31), (68, y0, 31), (68, y0 + 12.5, 22.6), (6, y0 + 12.5, 22.6)])
    for (cx, cy, h) in ((80, 16, 66), (90, 32, 52)):
        B.part("concrete", "#D4D1CC", smooth=True).cyl(cx, cy, 0.6, 4.6, h, 24, r2=3.8)
        B.part("paint", "#C0392B").cyl(cx, cy, h - 10, 4.1, 5, 24, r2=4.0)
        B.part("paint", "#EEEEEE", smooth=True, rough=1.0).sphere(cx + 1, cy, h + 6, 5, segs=12, rings=8)
        B.part("paint", "#DDDDDD", smooth=True, rough=1.0).sphere(cx + 4, cy - 2, h + 14, 7, segs=12, rings=8)
    for cx in (80, 90):
        B.part("metal", "#B9C2CC", rough=0.35, smooth=True).cyl(cx, 56, 0.6, 5, 26, 24)
        B.part("metal", "#B9C2CC", rough=0.35, smooth=True).dome(cx, 56, 26.6, 5, 3)
    for (x, y, z, c) in ((10, 72, 0.6, "#C0392B"), (10, 84, 0.6, "#2E86C1"), (10, 72, 9.6, "#E0A63A"), (40, 76, 0.6, "#27AE60")):
        B.part("metal", c, rough=0.5, bevel=0.3).box(x, y, z, 26, 10, 9)
    car(B, 60, 78, color="#E67E22", kind="van", length=22, width=10)


def farmland(B):
    base(B, "grass", **B.base)
    for k, y in enumerate(range(46, 98, 6)):
        B.part("soil", "#7A5634").box(4, y, 0, 58, 4.6, 0.8)
        c = "#D9B44A" if (k // 2) % 2 == 0 else "#5E9E3A"
        B.part("foliage", c).box(4.5, y + 0.8, 0.8, 57, 3, 1.6)
    for y in range(50, 96, 8):
        for x in range(68, 96, 6):
            B.part("foliage", "#3E8E3A", smooth=True).sphere(x, y, 2.4, 2.4, segs=10, rings=6)
    R = B.part("paint", "#A93226", bevel=0.4)
    R.box(12, 6, 0, 34, 28, 20)
    B.part("paint", "#F2EEE6").box(45.9, 14, 0, 0.3, 12, 14)
    Rf = B.part("roof", "#3F4750")
    Rf.quad([(10, 4, 20), (48, 4, 20), (48, 20, 32), (10, 20, 32)])
    Rf.quad([(10, 20, 32), (48, 20, 32), (48, 36, 20), (10, 36, 20)])
    B.part("paint", "#A93226").quad([(46, 6, 20), (46, 34, 20), (46, 20, 31)])
    B.part("metal", "#B9C2CC", rough=0.4, smooth=True).cyl(62, 16, 0, 7, 40, 24)
    B.part("metal", "#8E99A6", smooth=True).dome(62, 16, 40, 7.3, 5)
    for (x, y) in ((80, 14), (86, 26)):
        B.part("foliage", "#D9B44A", smooth=True).cyl_axis((x - 3, y, 3.5), (x + 3, y, 3.5), 3.5, 16)
    tree(B, 92, 40, 1.0)


def park(B):
    base(B, "grass", **B.base)
    import math
    pts = [(30 + 18 * math.cos(2 * math.pi * k / 32) * (1 + 0.12 * math.sin(3 * k)), 30 + 14 * math.sin(2 * math.pi * k / 32)) for k in range(32)]
    B.part("concrete", "#9C8B6E").poly_prism(pts, -0.3, 0.8)
    B.part("water", "#2F6E8E").poly_prism([(30 + (x - 30) * 0.9, 30 + (y - 30) * 0.9) for x, y in pts], -0.2, 0.9)
    path = [(4 + 92 * t / 20, 58 + 14 * math.sin(t / 20 * math.pi * 1.6)) for t in range(21)]
    B.part("concrete", "#CBBE9F").poly_prism([(x, y - 3.5) for x, y in path] + [(x, y + 3.5) for x, y in reversed(path)], 0, 0.3)
    G = B.part("paint", "#F2EEE6", bevel=0.2)
    for dx, dy in ((0, 0), (14, 0), (0, 14), (14, 14)):
        G.box(66 + dx, 72 + dy, 0, 1.4, 1.4, 12)
    B.part("concrete", "#D8D2C4").cyl(73, 79, 0, 10, 1.2, 32)
    B.part("roof", "#2E7D6F", smooth=False).cyl(73, 79, 12, 12, 8, 8, r2=0.5)
    for x, y in ((40, 70), (78, 40)):
        B.part("paint", "#6B4B34", bevel=0.2).box(x, y, 3, 10, 3, 0.8)
        B.part("paint", "#6B4B34", bevel=0.2).box(x, y, 3.8, 10, 0.8, 4)
        B.part("metal", "#2E3238").box(x + 1, y, 0, 0.6, 3, 3).box(x + 8.4, y, 0, 0.6, 3, 3)
    for i, (x, y, s, k) in enumerate(((60, 14, 1.1, "round"), (84, 22, 0.9, "cone"), (12, 72, 1.0, "round"), (28, 88, 1.1, "round"),
                                      (92, 60, 0.9, "cone"), (50, 90, 0.8, "cone"), (8, 50, 0.8, "round"))):
        tree(B, x, y, s, k, "#4E8F3A" if i % 2 else "#3E7F35", seed=i)
    for x, y in ((46, 40), (18, 58), (70, 56)):
        bush(B, x, y, 0.9, "#5B9E3F")
    lamp(B, 56, 62)


def barracks(B):
    base(B, None, **B.base)
    B.part("soil", "#8A7A5C").box(2, 2, 0, 96, 96, 0.5)
    B.part("concrete", "#A89C80").box(8, 50, 0.5, 50, 30, 0.3)
    O = B.part("paint", "#5E6B43", bevel=0.4)
    O.box(8, 8, 0.5, 62, 30, 18)
    windows(B, 8, 8, 3, 62, 30, 12, 1, 6, frame="#4D5836", glass="#27384A", sill=False, seed=81)
    R = B.part("roof", "#3F4A2E")
    R.quad([(6, 6, 18.5), (72, 6, 18.5), (72, 23, 27), (6, 23, 27)])
    R.quad([(6, 23, 27), (72, 23, 27), (72, 40, 18.5), (6, 40, 18.5)])
    B.part("paint", "#5E6B43").quad([(70, 8, 18.5), (70, 38, 18.5), (70, 23, 26.5)])
    # perimeter wall with barbed wire posts on the far sides
    Wl = B.part("concrete", "#B7AF9A", bevel=0.3)
    Wl.box(0, 0, 0.5, 100, 2, 9).box(0, 0, 0.5, 2, 100, 9)
    # watchtower
    M = B.part("paint", "#6B5A43")
    for dx, dy in ((0, 0), (10, 0), (0, 10), (10, 10)):
        M.box(80 + dx, 60 + dy, 0.5, 1.2, 1.2, 30)
    B.part("paint", "#7A6A50", bevel=0.3).box(78, 58, 30, 15, 15, 7)
    B.part("roof", "#3F4A2E").cyl(85.5, 65.5, 37, 11, 5, 4, r2=0.5)
    # flag and a military truck
    B.part("metal", "#B8BEC6").cyl(32, 64, 0.5, 0.5, 36, 8)
    B.part("cloth", "#C0392B").quad([(32, 64, 36), (32, 76, 35), (32, 76, 28), (32, 64, 29)])
    car(B, 58, 84, color="#4F5B3A", kind="suv", length=22, width=10)
    for k in range(6):
        B.part("cloth", "#9C8A62", smooth=True).sphere(10 + k * 6, 88, 1.6, 3, sx=1.3, sz=0.6, segs=10, rings=6)


def city_centre(B):
    base(B, None, **B.base)
    B.part("concrete", "#D9CFBC", bevel=0.2).box(2, 2, 0, 96, 96, 0.6)
    import math
    star = [(50 + (24 if k % 2 == 0 else 12) * math.cos(math.pi * k / 8), 58 + (24 if k % 2 == 0 else 12) * math.sin(math.pi * k / 8)) for k in range(16)]
    B.part("paint", "#2FA59A", rough=0.4).poly_prism(star, 0.6, 0.2)
    # arcade building at the back
    A = B.part("brick", "#D7B98C", scale=0.4, bevel=0.4)
    A.box(6, 6, 0.6, 40, 24, 30)
    windows(B, 6, 6, 2, 40, 24, 26, 2, 4, frame="#EFE6D4", glass="#2A4B69", seed=91)
    # clock tower
    T = B.part("brick", "#B5643C", scale=0.4, bevel=0.4)
    T.box(58, 10, 0.6, 20, 20, 64)
    windows(B, 58, 10, 10, 20, 20, 40, 3, 1, frame="#E8D6B8", glass="#2A3240", seed=92)
    B.part("concrete", "#EFE3CC", bevel=0.3).box(56, 8, 64.6, 24, 24, 4)
    for face in ("x", "y"):
        if face == "x":
            B.part("paint", "#FAF7EF", smooth=True).cyl_axis((78, 20, 56), (78.8, 20, 56), 6, 32)
            B.part("paint", "#222222").box(78.8, 19.6, 56, 0.3, 0.8, 4.5)
        else:
            B.part("paint", "#FAF7EF", smooth=True).cyl_axis((68, 30, 56), (68, 30.8, 56), 6, 32)
            B.part("paint", "#222222").box(67.6, 30.8, 56, 0.8, 0.3, 4.5)
    B.part("concrete", "#EFE3CC").cyl(68, 20, 68.6, 9, 4, 32)
    B.part("metal", "#2B8C7E", rough=0.3, smooth=True).dome(68, 20, 72.6, 9.5, 11)
    B.part("metal", "#C9A33A").cyl(68, 20, 83, 0.4, 6, 6)
    # fountain
    B.part("concrete", "#E6E1D7", bevel=0.3, smooth=True).cyl(50, 58, 0.6, 12, 4, 40)
    B.part("water", "#3E8FB0").cyl(50, 58, 0.6, 10.8, 4.2, 40)
    B.part("concrete", "#E6E1D7", smooth=True).cyl(50, 58, 4, 2, 6, 16)
    B.part("water", "#9ED3E6", smooth=True).sphere(50, 58, 11, 2.6, sz=1.4)
    for tx, ty in ((88, 50), (86, 86), (14, 86), (30, 92)):
        tree(B, tx, ty, 0.95)
    lamp(B, 28, 50)
    lamp(B, 74, 84)


# -- catalogue extras ------------------------------------------------------------------------------------
def hotel(B):
    base(B, None, **B.base)
    B.part("concrete", "#C7C3BB", bevel=0.2).box(2, 2, 0, 96, 96, 0.6)
    B.part("paint", "#6D2E46", bevel=0.5).box(14, 14, 0.6, 50, 44, 110)
    windows(B, 14, 14, 8, 50, 44, 100, 10, 6, frame="#E3C9A8", glass="#2A3E57", lit=0.25, seed=101)
    B.part("paint", "#E3C9A8", bevel=0.3).box(12, 12, 0.6, 54, 48, 8)
    sign(B, "x", 64.2, 24, 96, 24, 9, "#2B1320", "#F2C94C")
    door(B, "x", 66, 30, 0.6, 12, 7, canopy="#2B1320")
    B.part("water", "#3AA6C9").box(72, 64, 0.6, 22, 26, 1.4)
    B.part("concrete", "#E8E4DC").box(70, 62, 0.6, 26, 2, 2).box(70, 90, 0.6, 26, 2, 2)
    for tx, ty in ((8, 90), (40, 88)):
        tree(B, tx, ty, 1.0, "round", "#3E7F35")


def warehouse(B):
    base(B, None, **B.base)
    B.part("asphalt", "#484C53").box(2, 2, 0, 96, 96, 0.4)
    B.part("metal", "#B07C3E", rough=0.55, bevel=0.3).box(8, 10, 0.4, 70, 56, 26)
    for k in range(0, 70, 2):
        B.part("metal", "#94662F").box(8 + k, 65.8, 0.4, 0.5, 0.5, 26)
    for k in range(3):
        B.part("metal", "#4B5563").box(14 + k * 20, 65.9, 0.4, 14, 0.5, 16)
    R = B.part("metal", "#8994A0", rough=0.45)
    R.quad([(6, 8, 26.4), (80, 8, 26.4), (80, 38, 32), (6, 38, 32)])
    R.quad([(6, 38, 32), (80, 38, 32), (80, 68, 26.4), (6, 68, 26.4)])
    B.part("metal", "#B07C3E").quad([(78, 10, 26.4), (78, 66, 26.4), (78, 38, 31.6)])
    for i, c in enumerate(("#C0392B", "#2E86C1", "#27AE60")):
        B.part("metal", c, rough=0.5, bevel=0.3).box(10 + i * 26, 76, 0.4, 24, 10, 10)
    for k in range(4):
        B.part("paint", "#8B6A45", bevel=0.2).box(84, 14 + k * 12, 0.4, 8, 8, 6)
    car(B, 60, 88, color="#ECF0F1", kind="van", length=24, width=10)


def mall(B):
    base(B, None, **B.base)
    B.part("concrete", "#C9CBCE", bevel=0.2).box(2, 2, 0, 96, 96, 0.6)
    B.part("paint", "#E9E6E1", bevel=0.5).box(6, 8, 0.6, 84, 60, 34)
    B.part("glass", "#2E5D84").box(6, 8, 6, 84.5, 60.5, 22)
    B.part("paint", "#2F80ED", bevel=0.3).box(4, 6, 34.6, 88, 64, 3)
    sign(B, "y", 30, 68.4, 26, 36, 7, "#1B2A44", "#56CCF2")
    door(B, "y", 40, 68, 0.6, 16, 5, canopy="#2F80ED")
    rooftop(B, 6, 8, 37.6, 84, 60, 7)
    for k in range(4):
        car(B, 8 + k * 22, 78, color=["#C0392B", "#ECF0F1", "#1C1C1E", "#2E86DE"][k], axis="y", length=14, width=7)


def hq(B):
    base(B, None, **B.base)
    B.part("concrete", "#CFD2D6", bevel=0.2).box(2, 2, 0, 96, 96, 0.6)
    curtain_wall(B, 22, 22, 0.6, 46, 46, 170, 17, glass="#1F3C5E", mullion="#C9D3DE")
    B.part("metal", "#E5E9EE", bevel=0.4).box(20, 20, 170.6, 50, 50, 4)
    B.part("glass", "#1F3C5E").box(30, 30, 174.6, 30, 30, 10)
    B.part("metal", "#E5E9EE").box(28, 28, 184.6, 34, 34, 2)
    sign(B, "x", 68.2, 30, 150, 30, 10, "#0F1A2B", "#2F80ED")
    for tx, ty in ((10, 86), (86, 10), (90, 88)):
        tree(B, tx, ty, 0.9, "cone", "#3F7A3A")


def bank(B):
    base(B, None, **B.base)
    B.part("concrete", "#D5D2CB", bevel=0.2).box(2, 2, 0, 96, 96, 0.6)
    S = B.part("concrete", "#E8E1D2", bevel=0.5)
    S.box(10, 10, 0.6, 70, 62, 40)
    S.box(8, 8, 40.6, 74, 66, 5)
    windows(B, 10, 10, 6, 70, 62, 30, 2, 5, frame="#F4EFE5", glass="#263E57", sill=False, seed=111)
    C = B.part("concrete", "#F7F3EA", smooth=True)
    for k in range(7):
        C.cyl(86, 16 + k * 8.5, 0.6, 2.2, 38, 16)
    S.box(82, 12, 38.6, 10, 60, 4)
    B.part("concrete", "#F2EDE3").quad([(92, 12, 42.6), (92, 72, 42.6), (92, 42, 54)])
    for s in range(4):
        B.part("concrete", "#CFCAC0", bevel=0.2).box(84 + s * 2.5, 10, 0.6, 14 - s * 2.5, 64, 0.8 * (4 - s))
    B.part("metal", "#D4A63A", rough=0.2).cyl_axis((92.2, 42, 47), (93.2, 42, 47), 5, 32)
    lamp(B, 60, 88)
    car(B, 20, 80, color="#1C1C1E")


def lab(B):
    base(B, "grass", **B.base)
    B.part("concrete", "#D8DBDF", bevel=0.2).box(4, 4, 0, 70, 70, 0.5)
    B.part("paint", "#EEF2F6", bevel=0.5).box(8, 8, 0.5, 60, 52, 40)
    B.part("glass", "#3B7BA8").box(8, 8, 10, 60.5, 52.5, 6)
    B.part("glass", "#3B7BA8").box(8, 8, 26, 60.5, 52.5, 6)
    B.part("metal", "#56CCF2", rough=0.3, bevel=0.3).box(6, 6, 40.5, 64, 56, 2)
    B.part("metal", "#DDE3EA", rough=0.3, smooth=True).dome(30, 30, 42.5, 10, 10)
    B.part("paint", "#2B3440").box(29, 20, 49, 2, 20, 3)
    for tx, ty in ((80, 20), (86, 60), (70, 88), (20, 86)):
        tree(B, tx, ty, 0.9)


PLACES = {
    "city_centre": city_centre, "bazaar": bazaar, "business_district": business_district,
    "university": university, "city_hall": city_hall, "police_station": police_station,
    "hospital": hospital, "train_station": train_station, "bus_terminal": bus_terminal,
    "airport": airport, "industrial_zone": industrial_zone, "farmland": farmland,
    "residential_area": residential_area, "park": park, "barracks": barracks,
    "hotel": hotel, "warehouse": warehouse, "mall": mall, "hq": hq, "bank": bank, "lab": lab,
}


EXTRAS = ("hotel", "warehouse", "mall", "hq", "bank", "lab")


def main():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    only = a[a.index("--only") + 1].split(",") if "--only" in a else []
    samples = int(a[a.index("--samples") + 1]) if "--samples" in a else 40
    variants = a[a.index("--variants") + 1].split(",") if "--variants" in a else ["map", "catalog"]
    sc = kit.reset(samples)
    kit.lot_camera(sc)
    for code, fn in PLACES.items():
        if only and code not in only:
            continue
        for v in variants:
            kit.clear_meshes()
            B = Builder()
            B.base = {"depth": 3, "soil": False} if v == "map" else {"depth": 16, "soil": True}
            fn(B)
            B.build()
            # scenery-only buildings are "_<code>" on the map (never a game place)
            slot = ("_" + code) if code in EXTRAS else code
            out = (os.path.join(kit.ROOT, "assets", "art", "places", "render", slot + ".png") if v == "map"
                   else os.path.join(kit.ROOT, "art", "catalog", "buildings", code + ".png"))
            kit.render(sc, out)
            print("rendered", v, code)


if __name__ == "__main__":
    main()
