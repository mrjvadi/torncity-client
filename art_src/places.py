"""City places: one 256x256 isometric lot per place code (configs/content/places.yml).

Contract every place image keeps (so an artist's replacement drops in):
  * canvas 256 x 256, transparent background;
  * the lot is a 200 x 100 diamond whose centre sits at (128, 200);
  * nothing is drawn below y = 253.
"""
import math

from svgkit import Svg, P, light, dark, mix
from iso import Iso

W = H = 256
OX, OY = 128, 150


def new():
    s = Svg(W, H)
    return s, Iso(s, OX, OY)


# ---------------------------------------------------------------------------------
def city_centre():
    s, i = new()
    i.plot(P["sand"], inner=(10, light(P["sand"], 0.35)))
    # the plaza's tile pattern: a turquoise eight-point star inlaid in the paving
    cx, cy = 50, 58
    pts_ = []
    for k in range(16):
        r = 22 if k % 2 == 0 else 11
        a = math.radians(k * 22.5)
        pts_.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    i.ground_poly(pts_, mix(P["turquoise"], P["sand"], 0.55))
    # back row: a long arcade building
    i.shadow(8, 8, 36, 22, 30)
    b = i.box(8, 8, 0, 36, 22, 30, P["sand_dk"])
    i.windows(b, "left", 4, 2, arch=True, c=mix(P["turquoise_dk"], P["slate"], 0.3), lit={(1, 1), (3, 0)})
    i.windows(b, "right", 2, 2, arch=True, c=dark(P["turquoise_dk"], 0.2))
    i.box(6, 6, 30, 40, 26, 3, light(P["sand_dk"], 0.1))
    # the clock tower
    i.shadow(58, 12, 22, 22, 78)
    t = i.box(58, 12, 0, 22, 22, 62, P["brick"])
    i.windows(t, "left", 1, 3, mu=7, arch=True, c=dark(P["brick"], 0.45), v0=6, v1=44)
    i.windows(t, "right", 1, 3, mu=7, arch=True, c=dark(P["brick"], 0.55), v0=6, v1=44)
    i.box(56, 10, 62, 26, 26, 5, P["sand"])
    # the clock faces
    i.on_left(t, [(5, 48), (17, 48), (17, 58), (5, 58)], P["white"])
    fx, fy = i.p(58 + 11, 12 + 22, 53)
    s.line([(fx, fy), (fx, fy - 3.5)], P["ink"], 1.2)
    s.line([(fx, fy), (fx + 3, fy + 1)], P["ink"], 1.2)
    i.cylinder(69, 23, 67, 9, 5, P["sand"])
    i.dome(69, 23, 72, 10, P["turquoise"])
    # the fountain
    i.cylinder(cx, cy, 0, 14, 5, P["stone"])
    wx, wy = i.p(cx, cy, 5)
    s.ellipse(wx, wy, 16.5, 8.2, P["water"])
    s.ellipse(wx - 3, wy - 1.5, 8, 3.5, light(P["water"], 0.45))
    s.line([(wx, wy), (wx, wy - 14)], light(P["water"], 0.3), 2.2)
    s.circle(wx, wy - 15, 3, light(P["water"], 0.55))
    # trees and lamps along the front
    i.lamp(28, 86)
    i.lamp(86, 30)
    i.tree(88, 60, 0.9)
    i.tree(84, 86, 1.0, P["leaf_dk"])
    i.tree(14, 84, 0.85)
    return s


def bazaar():
    s, i = new()
    i.plot(light(P["sand"], 0.15))
    i.shadow(10, 14, 80, 40, 24)
    b = i.box(10, 14, 0, 80, 40, 22, P["sand_dk"])
    i.windows(b, "left", 6, 1, mu=5, gap_u=4, v0=2, v1=17, arch=True, c=mix(P["brick"], P["ink"], 0.45))
    i.windows(b, "right", 3, 1, mu=5, v0=2, v1=17, arch=True, c=mix(P["brick"], P["ink"], 0.55))
    # the tiled band under the roof
    i.on_left(b, [(0, 18.5), (80, 18.5), (80, 20.5), (0, 20.5)], P["turquoise"])
    for n, (x, c) in enumerate(((22, P["turquoise"]), (50, P["saffron"]), (78, P["turquoise"]))):
        i.cylinder(x, 34, 22, 8, 3, P["sand"])
        i.dome(x, 34, 25, 9 if n != 1 else 11, c)
    # market stalls with striped awnings in front
    for x, stripe in ((12, P["pomegranate"]), (40, P["saffron"]), (68, P["turquoise"])):
        i.shadow(x, 66, 22, 14, 12, 0.14)
        stall = i.box(x, 66, 0, 22, 14, 9, P["earth"])
        # awning: a sloping striped sheet
        for k in range(4):
            u0, u1 = k * 5.5, (k + 1) * 5.5
            col = stripe if k % 2 == 0 else P["white"]
            i.quad([(x + u0, 64, 16), (x + u1, 64, 16), (x + u1, 84, 11), (x + u0, 84, 11)], col)
        # produce: little heaps of colour on the counter
        for k, col in enumerate((P["saffron"], P["leaf"], P["pomegranate"])):
            px, py = i.p(x + 4 + k * 7, 80, 9)
            s.ellipse(px, py, 3.6, 2.2, col)
    i.lamp(94, 50)
    i.tree(92, 88, 0.8)
    return s


def business_district():
    s, i = new()
    i.plot(P["stone"], inner=(4, light(P["stone"], 0.3)))
    glass = mix(P["sky"], P["lapis"], 0.35)
    i.shadow(10, 10, 30, 30, 120, 0.22)
    t1 = i.box(10, 10, 0, 30, 30, 124, glass, top=light(glass, 0.4), right=dark(glass, 0.35))
    for v in range(8, 120, 9):
        i.on_left(t1, [(2, v), (28, v), (28, v + 4.5), (2, v + 4.5)], light(glass, 0.35))
        i.on_right(t1, [(2, v), (28, v), (28, v + 4.5), (2, v + 4.5)], mix(glass, P["slate"], 0.3))
    i.box(14, 14, 124, 12, 12, 8, P["stone_dk"])
    s.line([i.p(20, 20, 132), i.p(20, 20, 146)], P["stone_dk"], 1.5)
    s.circle(*i.p(20, 20, 147), 2.2, P["pomegranate"])
    teal = mix(P["turquoise"], P["slate"], 0.25)
    i.shadow(50, 14, 34, 28, 88, 0.2)
    t2 = i.box(50, 14, 0, 34, 28, 88, teal, top=light(teal, 0.35), right=dark(teal, 0.35))
    for u in range(3, 32, 6):
        i.on_left(t2, [(u, 4), (u + 3.5, 4), (u + 3.5, 84), (u, 84)], light(teal, 0.3))
    for u in range(3, 26, 6):
        i.on_right(t2, [(u, 4), (u + 3.5, 4), (u + 3.5, 84), (u, 84)], mix(teal, P["ink"], 0.25))
    i.box(48, 12, 88, 38, 32, 3, P["stone"])
    # the bank: a low stone hall with columns and a gold coin sign
    i.shadow(30, 58, 52, 30, 28)
    bank = i.box(30, 58, 0, 52, 30, 24, P["stone"])
    for k in range(7):
        u = 4 + k * 7
        i.on_left(bank, [(u, 2), (u + 3.4, 2), (u + 3.4, 18), (u, 18)], P["white"])
        i.on_left(bank, [(u + 3.4, 2), (u + 7, 2), (u + 7, 18), (u + 3.4, 18)], mix(P["slate"], P["stone"], 0.5))
    i.box(28, 56, 24, 56, 34, 4, light(P["stone"], 0.4))
    i.box(28, 88, 0, 56, 5, 2, P["white"])
    i.gable(30, 58, 28, 52, 30, 9, P["stone_dk"], ridge="x")
    cx, cy = i.p(56, 88, 34)
    s.circle(cx, cy - 1, 5.2, P["saffron_dk"])
    s.circle(cx, cy - 1, 3.6, P["saffron"])
    i.tree(90, 90, 0.7, kind="cone")
    i.tree(8, 90, 0.75, kind="cone")
    return s


def university():
    s, i = new()
    i.plot(P["grass"], inner=(10, light(P["grass"], 0.15)))
    # a path to the door
    i.ground_poly([(44, 60), (56, 60), (56, 100), (44, 100)], P["road"])
    i.shadow(10, 18, 80, 42, 40)
    hall = i.box(10, 18, 0, 80, 42, 32, P["brick"])
    i.windows(hall, "left", 7, 2, mu=4, gap_u=4, arch=True, c=light(P["sky"], 0.2), lit={(1, 0), (5, 1)})
    i.windows(hall, "right", 3, 2, mu=5, arch=True, c=mix(P["sky"], P["slate"], 0.4))
    i.box(8, 16, 32, 84, 46, 3, P["sand"])
    i.gable(10, 18, 35, 80, 42, 12, P["slate"], ridge="x")
    # the central entrance block and its turquoise dome
    i.shadow(40, 40, 22, 26, 58)
    e = i.box(40, 40, 0, 22, 26, 46, P["sand"])
    i.on_left(e, [(6, 0), (16, 0), (16, 14), (11, 18), (6, 14)], dark(P["brick"], 0.35))
    i.windows(e, "left", 2, 1, mu=4, gap_u=5, v0=24, v1=38, arch=True, c=light(P["sky"], 0.2))
    i.cylinder(51, 53, 46, 8, 5, P["sand_dk"])
    i.dome(51, 53, 51, 9, P["turquoise"])
    # trees on the lawn
    i.tree(12, 80, 0.95)
    i.tree(26, 88, 0.8, P["leaf_dk"])
    i.tree(84, 72, 0.95)
    i.tree(74, 88, 0.8, P["leaf_dk"])
    i.flag(92, 22, 44, 22, P["lapis"])
    return s


def city_hall():
    s, i = new()
    i.plot(P["stone"], inner=(6, light(P["stone"], 0.35)))
    i.shadow(12, 18, 76, 50, 40)
    base = i.box(12, 18, 0, 76, 50, 30, P["white"], right=mix(P["stone_dk"], P["white"], 0.35), top=P["stone"])
    # colonnade on the front
    for k in range(9):
        u = 4 + k * 8
        i.on_left(base, [(u, 3), (u + 4, 3), (u + 4, 25), (u, 25)], P["white"])
        i.on_left(base, [(u + 4, 3), (u + 8, 3), (u + 8, 25), (u + 4, 25)], mix(P["stone_dk"], P["white"], 0.2))
    i.windows(base, "right", 5, 2, mu=4, gap_u=4, c=mix(P["sky"], P["slate"], 0.45))
    i.box(10, 16, 30, 80, 54, 4, P["stone"])
    # steps
    i.box(24, 68, 0, 52, 4, 3, P["stone"])
    i.box(24, 72, 0, 52, 4, 1.5, light(P["stone"], 0.3))
    # the pediment over the entrance
    i.svg.poly([i.p(34, 68, 34), i.p(66, 68, 34), i.p(50, 68, 46)], P["white"])
    i.svg.poly([i.p(38, 68, 35.5), i.p(62, 68, 35.5), i.p(50, 68, 43)], P["stone"])
    # drum and golden dome
    i.cylinder(50, 43, 34, 15, 12, P["white"])
    for k in range(6):
        a = math.radians(100 + k * 28)
        px, py = i.p(50 + 13 * math.cos(a) * 0.72, 43 + 13 * math.sin(a) * 0.72, 37)
        s.rect(px - 1.3, py - 7, 2.6, 7, mix(P["sky"], P["slate"], 0.5), rx=1.3)
    i.dome(50, 43, 46, 16, P["saffron"])
    i.flag(84, 22, 34, 20, P["turquoise"])
    i.lamp(14, 88)
    i.lamp(88, 88)
    return s


def police_station():
    s, i = new()
    i.plot(P["stone"], inner=(4, light(P["stone"], 0.28)))
    blue = P["lapis"]
    i.shadow(14, 16, 66, 46, 36)
    b = i.box(14, 16, 0, 66, 46, 32, blue, top=light(blue, 0.3))
    i.on_left(b, [(0, 22), (66, 22), (66, 27), (0, 27)], P["white"])
    i.on_right(b, [(0, 22), (46, 22), (46, 27), (0, 27)], P["stone"])
    # checker band
    for k in range(0, 66, 6):
        i.on_left(b, [(k, 22), (k + 3, 22), (k + 3, 24.5), (k, 24.5)], P["ink"])
    i.windows(b, "left", 5, 1, mu=5, gap_u=5, v0=6, v1=18, c=light(P["sky"], 0.35), lit={(3, 0)})
    i.windows(b, "right", 3, 1, mu=5, gap_u=5, v0=6, v1=18, c=mix(P["sky"], P["slate"], 0.3))
    i.on_left(b, [(28, 0), (38, 0), (38, 13), (28, 13)], dark(blue, 0.45))
    # the star badge over the door
    cx, cy = i.p(14 + 33, 62, 17)
    s.circle(cx, cy, 5.2, P["saffron_dk"])
    from svgkit import star_points
    s.poly(star_points(cx, cy, 4.2, 1.9), P["saffron"])
    i.box(12, 14, 32, 70, 50, 3, P["stone"])
    # roof beacon
    i.box(40, 32, 35, 6, 6, 5, P["pomegranate"])
    i.box(48, 32, 35, 6, 6, 5, P["sky"])
    # a patrol car
    car = i.vehicle(56, 76, 22, 10, P["white"])
    i.box(64, 79, 8.5, 6, 4, 2, P["pomegranate"])
    i.on_left(car, [(0, 1.5), (22, 1.5), (22, 3), (0, 3)], blue)
    i.tree(8, 86, 0.8, P["leaf_dk"], kind="cone")
    i.lamp(90, 40)
    return s


def hospital():
    s, i = new()
    i.plot(P["stone"], inner=(4, light(P["stone"], 0.3)))
    i.shadow(12, 12, 54, 54, 56)
    main = i.box(12, 12, 0, 54, 54, 54, P["white"], right=mix(P["stone_dk"], P["white"], 0.4), top=P["stone"])
    i.windows(main, "left", 4, 4, mu=5, gap_u=6, v0=6, v1=50, c=light(P["sky"], 0.2), lit={(0, 2), (3, 1)})
    i.windows(main, "right", 4, 4, mu=5, gap_u=6, v0=6, v1=50, c=mix(P["sky"], P["slate"], 0.35))
    i.on_left(main, [(0, 51), (54, 51), (54, 54), (0, 54)], P["pomegranate"])
    # helipad
    hx, hy = i.p(39, 39, 54)
    s.ellipse(hx, hy, 24, 12, P["slate"])
    s.ellipse(hx, hy, 20, 10, "none", stroke=P["white"], sw=1.4)
    s.poly([i.p(34, 35, 54), i.p(36, 35, 54), i.p(36, 43, 54), i.p(34, 43, 54)], P["white"])
    s.poly([i.p(42, 35, 54), i.p(44, 35, 54), i.p(44, 43, 54), i.p(42, 43, 54)], P["white"])
    s.poly([i.p(36, 38.5, 54), i.p(42, 38.5, 54), i.p(42, 39.5, 54), i.p(36, 39.5, 54)], P["white"])
    # the wing with the red cross
    i.shadow(66, 30, 24, 40, 30)
    wing = i.box(66, 30, 0, 24, 40, 28, P["white"], right=mix(P["stone_dk"], P["white"], 0.4), top=P["stone"])
    i.windows(wing, "right", 3, 2, mu=4, gap_u=5, v0=5, v1=24, c=mix(P["sky"], P["slate"], 0.35))
    cxu = 8
    i.on_left(wing, [(cxu, 8), (cxu + 8, 8), (cxu + 8, 24), (cxu, 24)], P["pomegranate"])
    i.on_left(wing, [(cxu - 4, 12), (cxu + 12, 12), (cxu + 12, 20), (cxu - 4, 20)], P["pomegranate"])
    # canopy and ambulance
    i.box(20, 66, 12, 30, 10, 2, P["pomegranate"])
    for u in (22, 46):
        i.box(u, 74, 0, 1.5, 1.5, 12, P["stone_dk"])
    amb = i.vehicle(22, 80, 20, 10, P["white"], h=9)
    i.on_left(amb, [(8, 2), (12, 2), (12, 8), (8, 8)], P["pomegranate"])
    i.on_left(amb, [(6, 4), (14, 4), (14, 6), (6, 6)], P["pomegranate"])
    i.tree(88, 86, 0.8)
    return s


def train_station():
    s, i = new()
    i.plot(P["road"])
    # platform and rails
    i.ground_poly([(6, 58), (94, 58), (94, 66), (6, 66)], P["stone"], z=0)
    i.box(6, 58, 0, 88, 8, 2, P["stone"])
    for y0 in (70, 82):
        for x in range(8, 94, 5):
            i.ground_poly([(x, y0 - 1), (x + 2.2, y0 - 1), (x + 2.2, y0 + 7), (x, y0 + 7)], P["earth"])
        s.line([i.p(5, y0 + 0.8), i.p(95, y0 + 0.8)], P["steel"], 1.4)
        s.line([i.p(5, y0 + 5.2), i.p(95, y0 + 5.2)], P["steel"], 1.4)
    # the hall, with a barrel-vault glass roof
    i.shadow(10, 14, 80, 40, 30)
    hall = i.box(10, 14, 0, 80, 40, 22, P["sand_dk"])
    i.windows(hall, "left", 7, 1, mu=4, gap_u=4, v0=3, v1=18, arch=True, c=mix(P["sky"], P["slate"], 0.2),
              lit={(2, 0), (5, 0)})
    i.windows(hall, "right", 3, 1, mu=5, v0=3, v1=18, arch=True, c=mix(P["sky"], P["slate"], 0.45))
    # vault: a series of strips across y, curved in z
    n = 10
    for k in range(n):
        a0, a1 = math.pi * k / n, math.pi * (k + 1) / n
        y0, y1 = 14 + 20 - 20 * math.cos(a0), 14 + 20 - 20 * math.cos(a1)
        z0, z1 = 22 + 14 * math.sin(a0), 22 + 14 * math.sin(a1)
        shade = light(P["sky"], 0.35) if k < n / 2 else mix(P["sky"], P["slate"], 0.25 + 0.05 * (k - n / 2))
        i.quad([(10, y0, z0), (90, y0, z0), (90, y1, z1), (10, y1, z1)], shade)
    # the vault's end wall at x = 90
    ew = []
    for k in range(n + 1):
        a = math.pi * k / n
        ew.append(i.p(90, 14 + 20 - 20 * math.cos(a), 22 + 14 * math.sin(a)))
    s.poly(ew, P["sand"])
    ex, ey = i.p(90, 34, 30)
    s.circle(ex, ey, 5.4, P["white"])
    s.line([(ex, ey), (ex, ey - 3.6)], P["ink"], 1.1)
    s.line([(ex, ey), (ex + 2.6, ey + 1.2)], P["ink"], 1.1)
    for k in range(0, 81, 10):
        s.line([i.p(10 + k, 14, 22), i.p(10 + k, 34, 36), i.p(10 + k, 54, 22)], light(P["stone"], 0.2), 0.9)
    # a train at the platform
    for k, x in enumerate((14, 44)):
        car = i.box(x, 70, 1, 28, 8.5, 9, P["turquoise"], top=light(P["stone"], 0.3))
        i.on_left(car, [(0, 3), (28, 3), (28, 4.5), (0, 4.5)], P["white"])
        for u in range(3, 26, 6):
            i.on_left(car, [(u, 5.2), (u + 4, 5.2), (u + 4, 8), (u, 8)], P["slate"])
    front = i.box(72, 70, 1, 16, 8.5, 9, P["saffron"])
    i.on_left(front, [(2, 5), (12, 5), (12, 8), (2, 8)], P["slate"])
    return s


def bus_terminal():
    s, i = new()
    i.plot(P["asphalt"], rim=P["road"], inner=(4, mix(P["asphalt"], P["stone"], 0.15)))
    # bay markings
    for x in range(14, 90, 16):
        s.line([i.p(x, 56), i.p(x, 76)], P["white"], 1.2, opacity=0.8)
    s.line([i.p(8, 84), i.p(92, 84)], P["saffron"], 1.6)
    # ticket hall
    i.shadow(10, 8, 42, 22, 28)
    hall = i.box(10, 8, 0, 42, 22, 26, P["sand"])
    i.windows(hall, "left", 4, 1, mu=4, gap_u=4, v0=4, v1=20, c=light(P["sky"], 0.2), lit={(2, 0)})
    i.windows(hall, "right", 2, 1, mu=4, v0=4, v1=20, c=mix(P["sky"], P["slate"], 0.4))
    i.box(8, 6, 26, 46, 26, 3, P["saffron"])
    # the canopy over the bays
    for x in (12, 44, 76):
        for y in (38, 52):
            i.box(x, y, 0, 2, 2, 22, P["stone_dk"])
    i.shadow(8, 34, 84, 22, 8, 0.12, reach=2.0)
    i.box(8, 34, 22, 84, 22, 3, P["turquoise"], top=light(P["turquoise"], 0.35))
    # the bus
    bus = i.box(24, 60, 1.5, 50, 13, 15, P["saffron"])
    i.on_left(bus, [(3, 8), (47, 8), (47, 13), (3, 13)], P["slate"])
    for u in range(8, 45, 9):
        i.on_left(bus, [(u, 8), (u + 1, 8), (u + 1, 13), (u, 13)], P["saffron_dk"])
    i.on_left(bus, [(0, 4), (50, 4), (50, 5.5), (0, 5.5)], P["white"])
    i.on_right(bus, [(2, 7), (11, 7), (11, 13), (2, 13)], P["slate"])
    for u in (9, 40):
        wx, wy = i.p(24 + u, 73, 2)
        s.ellipse(wx, wy, 3.2, 3.2, P["ink"])
        s.ellipse(wx, wy, 1.3, 1.3, P["stone_dk"])
    i.tree(90, 12, 0.8)
    return s


def airport():
    s, i = new()
    i.plot(P["grass"], rim=P["road"])
    # runway
    i.ground_poly([(4, 58), (96, 58), (96, 84), (4, 84)], P["asphalt"])
    for x in range(10, 92, 12):
        i.ground_poly([(x, 70.5), (x + 6, 70.5), (x + 6, 72), (x, 72)], P["white"])
    # terminal
    i.shadow(8, 12, 60, 30, 22)
    t = i.box(8, 12, 0, 60, 30, 20, P["stone"], right=mix(P["stone_dk"], P["stone"], 0.4))
    i.on_left(t, [(2, 6), (58, 6), (58, 16), (2, 16)], mix(P["sky"], P["lapis"], 0.2))
    for u in range(2, 58, 7):
        i.on_left(t, [(u, 6), (u + 0.9, 6), (u + 0.9, 16), (u, 16)], light(P["stone"], 0.3))
    i.on_right(t, [(2, 6), (28, 6), (28, 16), (2, 16)], mix(P["sky"], P["slate"], 0.5))
    # curved roof lip
    i.box(6, 10, 20, 64, 34, 3, P["white"])
    # control tower
    i.shadow(78, 24, 10, 10, 72)
    i.cylinder(83, 29, 0, 5, 58, P["white"])
    i.cylinder(83, 29, 58, 9, 3, P["stone"])
    cx, cy, rx, ry = i.cylinder(83, 29, 61, 8, 7, mix(P["sky"], P["lapis"], 0.3))
    i.cylinder(83, 29, 68, 9, 2, P["white"])
    s.line([i.p(83, 29, 70), i.p(83, 29, 80)], P["stone_dk"], 1.3)
    s.circle(*i.p(83, 29, 80.5), 2, P["pomegranate"])
    # a small plane on the runway
    px, py = i.p(52, 71, 5)
    body = P["white"]
    s.path("M%.1f %.1f l-26 -13 q-3 -2 0 -3 l32 13 q3 2 -1 3 z" % (px + 18, py + 6), body)
    s.poly([(px - 2, py - 2), (px + 6, py - 16), (px + 11, py - 15), (px + 6, py + 1)], light(P["stone"], 0.1))
    s.poly([(px + 1, py + 3), (px - 12, py + 12), (px - 7, py + 13), (px + 8, py + 5)], P["stone"])
    s.poly([(px - 18, py - 9), (px - 21, py - 19), (px - 17, py - 19), (px - 12, py - 7)], P["turquoise"])
    s.line([(px - 10, py - 5), (px + 12, py + 5)], P["turquoise"], 1.4)
    i.tree(92, 92, 0.7, kind="cone")
    i.tree(10, 92, 0.7, kind="cone")
    return s


def industrial_zone():
    s, i = new()
    i.plot(mix(P["stone_dk"], P["road"], 0.4), rim=P["road"])
    steel = P["steel"]
    i.shadow(8, 18, 62, 44, 34)
    f_ = i.box(8, 18, 0, 62, 44, 22, steel)
    for u in range(4, 60, 8):
        i.on_left(f_, [(u, 0), (u + 1.2, 0), (u + 1.2, 22), (u, 22)], dark(steel, 0.12))
    i.on_left(f_, [(22, 0), (38, 0), (38, 14), (22, 14)], P["slate"])
    for k in range(4):
        i.on_left(f_, [(22, 2 + k * 3), (38, 2 + k * 3), (38, 2.8 + k * 3), (22, 2.8 + k * 3)], dark(P["slate"], 0.2))
    i.windows(f_, "right", 4, 1, mu=4, gap_u=4, v0=12, v1=18, c=mix(P["sky"], P["slate"], 0.3))
    # saw-tooth roof: four teeth running along x
    for k in range(4):
        y0 = 18 + k * 11
        i.quad([(8, y0, 22), (70, y0, 22), (70, y0, 30), (8, y0, 30)], light(P["sky"], 0.15))
        i.quad([(8, y0, 30), (70, y0, 30), (70, y0 + 11, 22), (8, y0 + 11, 22)], light(steel, 0.25))
        s.poly([i.p(70, y0, 22), i.p(70, y0 + 11, 22), i.p(70, y0, 30)], dark(steel, 0.3))
    # chimneys with a red band, and smoke
    for x, y, h in ((78, 14, 62), (88, 30, 50)):
        i.shadow(x - 4, y - 4, 8, 8, h, 0.18)
        i.cylinder(x, y, 0, 5, h, P["stone"])
        i.cylinder(x, y, h - 12, 5.3, 6, P["pomegranate"], cap=False)
        tx, ty = i.p(x, y, h)
        for k, (dx, dy, r) in enumerate(((0, -6, 5), (4, -14, 6.5), (1, -24, 8))):
            s.circle(tx + dx, ty + dy, r, P["white"], opacity=0.75 - k * 0.15)
    # containers
    for (x, y, z, c) in ((66, 70, 0, P["pomegranate"]), (80, 70, 0, P["turquoise"]), (66, 70, 8, P["saffron"])):
        cbox = i.box(x, y, z, 12, 20, 8, c)
        for u in range(2, 20, 3):
            i.on_right(cbox, [(u, 1), (u + 0.8, 1), (u + 0.8, 7), (u, 7)], dark(c, 0.35))
    return s


def farmland():
    s, i = new()
    i.plot(P["earth"], rim=P["grass_dk"], inset=3)
    # crop rows
    for k, y in enumerate(range(44, 96, 6)):
        c = P["saffron"] if (k // 2) % 2 == 0 else P["leaf"]
        i.ground_poly([(6, y), (60, y), (60, y + 4), (6, y + 4)], c)
        i.ground_poly([(6, y), (60, y), (60, y + 1.3), (6, y + 1.3)], light(c, 0.3))
    for k, y in enumerate(range(50, 96, 7)):
        i.ground_poly([(66, y), (95, y), (95, y + 4.5), (66, y + 4.5)], P["leaf_dk"])
        for x in range(68, 94, 5):
            px, py = i.p(x, y + 2, 0)
            s.circle(px, py - 2, 2.3, P["leaf"])
    # barn
    i.shadow(14, 8, 34, 28, 34)
    barn = i.box(14, 8, 0, 34, 28, 20, P["pomegranate"])
    i.on_left(barn, [(11, 0), (23, 0), (23, 14), (11, 14)], P["white"])
    i.on_left(barn, [(12.2, 1.2), (21.8, 1.2), (21.8, 12.8), (12.2, 12.8)], dark(P["pomegranate"], 0.2))
    s.line([i.p(26, 36, 1.2), i.p(36, 36, 12.8)], P["white"], 1.2)
    s.line([i.p(36, 36, 1.2), i.p(26, 36, 12.8)], P["white"], 1.2)
    i.gable(14, 8, 20, 34, 28, 14, P["slate"], ridge="y")
    # silo
    i.shadow(56, 10, 14, 14, 46, 0.16)
    i.cylinder(63, 17, 0, 7, 38, P["stone"])
    for z in (10, 20, 30):
        i.cylinder(63, 17, z, 7.1, 1, P["stone_dk"], cap=False)
    i.dome(63, 17, 38, 7.4, P["stone_dk"], height=6, finial=False)
    # hay bales
    for x, y in ((80, 16), (86, 26)):
        i.cylinder(x, y, 0, 4, 5, P["saffron_dk"], top=P["saffron"])
    i.tree(92, 38, 0.8)
    return s


def residential_area():
    s, i = new()
    i.plot(P["grass"], rim=P["road"])
    i.ground_poly([(46, 6), (54, 6), (54, 94), (46, 94)], P["road"])
    i.ground_poly([(6, 46), (94, 46), (94, 54), (6, 54)], P["road"])
    houses = [
        (8, 8, P["sand"], P["brick"]),
        (58, 8, light(P["sky"], 0.45), P["slate"]),
        (8, 58, light(P["rose"], 0.45), P["pomegranate"]),
        (58, 60, P["white"], P["turquoise_dk"]),
    ]
    for x, y, wall, roof in houses:
        i.shadow(x + 4, y + 4, 26, 24, 26, 0.16)
        h = i.box(x + 4, y + 4, 0, 26, 24, 14, wall)
        i.on_left(h, [(4, 0), (9, 0), (9, 9), (4, 9)], P["earth_dk"])
        i.on_left(h, [(13, 5), (21, 5), (21, 11), (13, 11)], light(P["sky"], 0.2))
        i.on_left(h, [(16.6, 5), (17.4, 5), (17.4, 11), (16.6, 11)], wall)
        i.on_right(h, [(6, 5), (14, 5), (14, 11), (6, 11)], mix(P["sky"], P["slate"], 0.4))
        i.gable(x + 4, y + 4, 14, 26, 24, 11, roof, ridge="x")
    i.tree(40, 38, 0.8)
    i.tree(90, 40, 0.75, P["leaf_dk"])
    i.tree(38, 92, 0.75, P["leaf_dk"], kind="cone")
    i.tree(92, 92, 0.8)
    return s


def park():
    s, i = new()
    i.plot(P["grass"], rim=P["road"], inset=4, inner=(0, P["grass"]))
    # winding path
    path = []
    for k in range(21):
        t = k / 20
        path.append((6 + 88 * t, 50 + 18 * math.sin(t * math.pi * 1.6)))
    upper = [(x, y - 4) for x, y in path]
    lower = [(x, y + 4) for x, y in reversed(path)]
    i.ground_poly(upper + lower, P["road"])
    # pond
    pond = []
    for k in range(28):
        a = 2 * math.pi * k / 28
        r = 18 + 3 * math.sin(3 * a)
        pond.append((30 + r * math.cos(a), 26 + r * 0.8 * math.sin(a)))
    i.ground_poly(pond, dark(P["water"], 0.15))
    i.ground_poly([(x - 1.2, y - 1.2) for x, y in pond], P["water"])
    px, py = i.p(26, 22)
    s.ellipse(px - 4, py - 2, 9, 2.4, light(P["water"], 0.5))
    # gazebo
    i.shadow(64, 70, 18, 18, 22, 0.14)
    for dx, dy in ((0, 0), (14, 0), (0, 14), (14, 14)):
        i.box(64 + dx, 70 + dy, 0, 2, 2, 14, P["white"])
    i.cylinder(73, 79, 0, 10, 2, P["sand"])
    i.cone(73, 79, 14, 13, 12, P["turquoise"])
    # benches
    for x, y in ((40, 64), (76, 38)):
        i.box(x, y, 3, 10, 3, 1.2, P["earth"])
        i.box(x, y, 4.2, 10, 1, 4, P["earth_dk"])
    # trees
    for x, y, sc, c, k in ((60, 14, 1.0, P["leaf"], "round"), (84, 22, 0.85, P["leaf_dk"], "cone"),
                           (12, 70, 0.9, P["leaf_dk"], "round"), (28, 86, 1.0, P["leaf"], "round"),
                           (90, 60, 0.8, P["leaf"], "cone"), (50, 88, 0.75, P["leaf_dk"], "cone")):
        i.tree(x, y, sc, c, k)
    # flowers
    for x, y, c in ((44, 36, P["rose"]), (48, 40, P["saffron"]), (16, 50, P["rose"]), (70, 56, P["saffron"])):
        fx, fy = i.p(x, y)
        s.circle(fx, fy, 1.8, c)
    return s


def barracks():
    s, i = new()
    i.plot(mix(P["olive"], P["sand"], 0.55), rim=P["road"])
    olive = P["olive"]
    # perimeter fence
    for k in range(0, 101, 10):
        i.box(k - 0.6, -0.6, 0, 1.2, 1.2, 6, P["stone_dk"])
        i.box(-0.6, k - 0.6, 0, 1.2, 1.2, 6, P["stone_dk"])
    s.line([i.p(0, 0, 5), i.p(100, 0, 5)], P["stone_dk"], 0.9)
    s.line([i.p(0, 0, 5), i.p(0, 100, 5)], P["stone_dk"], 0.9)
    # the barracks hall
    i.shadow(10, 12, 60, 30, 28)
    b = i.box(10, 12, 0, 60, 30, 18, olive)
    i.windows(b, "left", 6, 1, mu=4, gap_u=4, v0=5, v1=13, c=mix(P["sky"], P["slate"], 0.35))
    i.windows(b, "right", 3, 1, mu=4, gap_u=4, v0=5, v1=13, c=mix(P["sky"], P["slate"], 0.55))
    i.gable(10, 12, 18, 60, 30, 9, dark(olive, 0.25), ridge="x")
    # parade ground
    i.ground_poly([(12, 52), (60, 52), (60, 80), (12, 80)], P["sand_dk"])
    i.flag(36, 66, 0, 30, P["pomegranate"])
    # watchtower
    for dx, dy in ((0, 0), (10, 0), (0, 10), (10, 10)):
        i.box(76 + dx, 60 + dy, 0, 1.5, 1.5, 30, P["earth_dk"])
    i.box(74, 58, 30, 15, 15, 8, P["earth"])
    i.gable(74, 58, 38, 15, 15, 6, dark(olive, 0.3), ridge="y")
    # jeep and sandbags
    i.vehicle(66, 84, 18, 9, dark(olive, 0.1))
    for k in range(5):
        px, py = i.p(10 + k * 7, 88, 1.5)
        s.ellipse(px, py, 4.2, 2.4, P["sand_dk"])
    return s


# A plot with nothing on it: used for a place code the art does not know yet.
def empty_lot():
    s, i = new()
    i.plot(P["grass"], rim=P["road"])
    i.tree(30, 30, 0.9)
    i.tree(70, 64, 0.8, P["leaf_dk"], kind="cone")
    i.tree(28, 74, 0.7)
    return s


# A decorative filler for empty map cells (a round plaza with a fountain).
def plaza():
    s, i = new()
    i.plot(light(P["sand"], 0.2), rim=P["road"])
    pts_ = [(50 + 30 * math.cos(2 * math.pi * k / 24), 50 + 30 * math.sin(2 * math.pi * k / 24)) for k in range(24)]
    i.ground_poly(pts_, mix(P["turquoise"], P["sand"], 0.6))
    i.cylinder(50, 50, 0, 12, 4, P["stone"])
    wx, wy = i.p(50, 50, 4)
    s.ellipse(wx, wy, 14, 7, P["water"])
    for x, y in ((14, 14), (86, 14), (14, 86), (86, 86)):
        i.tree(x, y, 0.75)
    return s


PLACES = {
    "city_centre": city_centre,
    "bazaar": bazaar,
    "business_district": business_district,
    "university": university,
    "city_hall": city_hall,
    "police_station": police_station,
    "hospital": hospital,
    "train_station": train_station,
    "bus_terminal": bus_terminal,
    "airport": airport,
    "industrial_zone": industrial_zone,
    "farmland": farmland,
    "residential_area": residential_area,
    "park": park,
    "barracks": barracks,
    "_empty": empty_lot,
    "_plaza": plaza,
}


def build():
    out = []
    for code, fn in PLACES.items():
        out.append(fn().save("places/%s.svg" % code))
    return out
