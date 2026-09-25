"""The icon set: 64 x 64, filled, rounded, two tones, no outlines.

Shape language: a 4 px safe margin, corner radii of 4-8 px, stroke-drawn
details at 5 px with round caps, and one lighter "highlight" shape per icon
from the upper left. Each concept owns one colour (see docs/art-style.md) so
an icon reads by colour before shape.
"""
import math

from svgkit import Svg, P, light, dark, mix, star_points, rrect_path

S = 64


def ico():
    return Svg(S, S)


def circ_arc(cx, cy, r, a0, a1, n=24):
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * k / n)),
             cy + r * math.sin(math.radians(a0 + (a1 - a0) * k / n))) for k in range(n + 1)]


# -- money -------------------------------------------------------------------------------
def cash():
    s, c = ico(), P["leaf"]
    s.path(rrect_path(10, 12, 46, 28, 5), dark(c, 0.25))
    s.path(rrect_path(6, 22, 48, 30, 5), c)
    s.path(rrect_path(10, 26, 40, 22, 3), light(c, 0.22))
    s.circle(30, 37, 7, dark(c, 0.1))
    s.circle(30, 37, 4, light(c, 0.5))
    s.circle(15, 37, 2.2, dark(c, 0.1))
    s.circle(45, 37, 2.2, dark(c, 0.1))
    return s


def bank():
    s, c = ico(), P["lapis"]
    s.poly([(32, 6), (58, 20), (6, 20)], c)
    s.poly([(32, 11), (48, 19), (16, 19)], light(c, 0.3))
    s.path(rrect_path(8, 20, 48, 5, 2), dark(c, 0.15))
    for x in (12, 22, 32, 42):
        s.path(rrect_path(x + 1, 27, 7, 20, 2), light(c, 0.15))
    s.path(rrect_path(6, 48, 52, 8, 3), c)
    s.circle(32, 15.5, 2.4, P["saffron"])
    return s


def card():
    s, c = ico(), P["violet"]
    s.path(rrect_path(6, 14, 52, 36, 6), c)
    s.rect(6, 22, 52, 7, dark(c, 0.35))
    s.path(rrect_path(12, 35, 14, 9, 2), P["saffron"])
    s.path(rrect_path(34, 38, 18, 4, 2), light(c, 0.4))
    return s


def pay():
    s, c = ico(), P["leaf"]
    s.path(rrect_path(4, 20, 36, 24, 4), c)
    s.circle(22, 32, 6, light(c, 0.4))
    s.poly([(42, 22), (58, 32), (42, 42)], P["turquoise"])
    s.rect(34, 28, 10, 8, P["turquoise"], rx=1)
    return s


def moneybag():
    s, c = ico(), P["saffron"]
    s.path("M24 14 L40 14 L36 22 L28 22 Z", dark(c, 0.15))
    s.path("M28 22 C12 28 8 44 12 52 C16 58 48 58 52 52 C56 44 52 28 36 22 Z", c)
    s.path("M26 12 q6 -6 12 0 z", dark(c, 0.2))
    s.path("M18 36 C18 30 22 27 26 26", "none", stroke=light(c, 0.5), sw=4)
    s.path("M32 30 v18 M37 34 q-5 -4 -9 0 q0 4 4 4 q5 0 5 4 q-4 4 -9 0", "none", stroke=dark(c, 0.35), sw=3)
    return s


def deposit():
    s, c = ico(), P["turquoise"]
    s.path("M8 34 L18 34 L22 42 L42 42 L46 34 L56 34 L56 52 Q56 56 52 56 L12 56 Q8 56 8 52 Z", c)
    s.path("M32 6 v24", "none", stroke=P["leaf"], sw=7)
    s.poly([(20, 24), (44, 24), (32, 36)], P["leaf"])
    return s


def withdraw():
    s, c = ico(), P["turquoise"]
    s.path("M8 34 L18 34 L22 42 L42 42 L46 34 L56 34 L56 52 Q56 56 52 56 L12 56 Q8 56 8 52 Z", c)
    s.path("M32 34 v-24", "none", stroke=P["saffron"], sw=7)
    s.poly([(20, 16), (44, 16), (32, 4)], P["saffron"])
    return s


# -- vitals ----------------------------------------------------------------------------------
def energy():
    s, c = ico(), P["saffron"]
    s.poly([(36, 4), (12, 36), (29, 36), (24, 60), (52, 26), (34, 26), (40, 4)], c)
    s.poly([(36, 4), (40, 4), (34, 26), (28, 26)], light(c, 0.45))
    return s


def health():
    s, c = ico(), P["pomegranate"]
    s.path("M32 56 C14 44 6 34 6 23 C6 14 13 8 21 8 C26 8 30 11 32 15 C34 11 38 8 43 8 C51 8 58 14 58 23 C58 34 50 44 32 56 Z", c)
    s.path("M15 22 C15 17 18 15 22 15", "none", stroke=light(c, 0.55), sw=5)
    return s


def hunger():
    s, c = ico(), P["brick"]
    s.path("M8 30 H56 C56 44 46 54 32 54 C18 54 8 44 8 30 Z", c)
    s.path("M8 30 H56 V33 H8 Z", dark(c, 0.2))
    s.path("M14 36 C15 42 19 46 24 48", "none", stroke=light(c, 0.4), sw=4)
    for x in (22, 32, 42):
        s.path("M%d 24 q-4 -5 0 -9 q4 -4 0 -9" % x, "none", stroke=P["stone_dk"], sw=3.5)
    return s


def sleep():
    s, c = ico(), P["violet"]
    s.path("M40 8 C26 10 16 22 16 36 C16 50 28 60 42 58 C34 54 28 45 28 34 C28 22 33 13 40 8 Z", c)
    s.path("M22 30 C22 24 25 19 29 16", "none", stroke=light(c, 0.45), sw=4)
    s.path("M40 16 h12 l-12 14 h12", "none", stroke=light(c, 0.3), sw=4)
    return s


def stress():
    s, c = ico(), P["rose"]
    s.path("M16 40 C8 40 6 30 12 27 C12 18 22 14 28 19 C31 12 44 12 46 21 C54 20 58 28 54 34 C57 38 54 42 50 42 Z", mix(P["slate"], c, 0.35))
    s.path("M16 26 C18 21 22 20 25 21", "none", stroke=light(c, 0.3), sw=3.5)
    s.poly([(34, 36), (24, 50), (31, 50), (27, 60), (40, 45), (33, 45), (37, 36)], c)
    return s


def happiness():
    s, c = ico(), P["saffron"]
    s.circle(32, 32, 26, c)
    s.circle(22, 22, 6, light(c, 0.4))
    s.circle(23, 28, 3.4, dark(c, 0.6))
    s.circle(41, 28, 3.4, dark(c, 0.6))
    s.path("M20 38 Q32 50 44 38", "none", stroke=dark(c, 0.6), sw=4.5)
    return s


def level():
    s, c = ico(), P["saffron"]
    s.poly(star_points(32, 34, 27, 12), c)
    s.poly(star_points(32, 34, 27, 12)[:4] + [(32, 34)], light(c, 0.35))
    return s


def xp():
    s, c = ico(), P["turquoise"]
    s.poly([(32, 4), (40, 24), (60, 32), (40, 40), (32, 60), (24, 40), (4, 32), (24, 24)], c)
    s.poly([(32, 4), (40, 24), (32, 32), (24, 24)], light(c, 0.4))
    s.poly([(4, 32), (24, 24), (32, 32), (24, 40)], light(c, 0.15))
    s.circle(52, 12, 4, light(c, 0.3))
    return s


def rank():
    s, c = ico(), P["saffron"]
    s.poly([(18, 4), (30, 4), (36, 24), (24, 24)], P["lapis"])
    s.poly([(46, 4), (34, 4), (28, 24), (40, 24)], P["pomegranate"])
    s.circle(32, 40, 18, dark(c, 0.15))
    s.circle(32, 40, 14, c)
    s.poly(star_points(32, 40, 9, 4), light(c, 0.5))
    return s


def age():
    s, c = ico(), P["rose"]
    s.path(rrect_path(10, 30, 44, 24, 6), c)
    s.rect(10, 38, 44, 5, light(c, 0.4))
    for x in (22, 32, 42):
        s.rect(x - 2, 18, 4, 12, P["sky"], rx=2)
        s.path("M%d 16 q-4 -5 0 -10 q4 5 0 10 z" % x, P["saffron"])
    return s


# -- places & activities ------------------------------------------------------------------------
def crime():
    s, c = ico(), P["violet"]
    s.path("M4 26 C10 20 22 20 32 26 C42 20 54 20 60 26 C60 40 50 46 42 42 C38 40 35 36 32 36 C29 36 26 40 22 42 C14 46 4 40 4 26 Z", c)
    s.path("M13 30 C16 27 21 27 24 31 C21 35 16 35 13 30 Z", P["ink"])
    s.path("M51 30 C48 27 43 27 40 31 C43 35 48 35 51 30 Z", P["ink"])
    s.path("M10 26 C14 23 19 23 22 24", "none", stroke=light(c, 0.4), sw=3)
    return s


def work():
    s, c = ico(), P["brick"]
    s.path(rrect_path(22, 8, 20, 14, 4), "none", stroke=dark(c, 0.3), sw=5)
    s.path(rrect_path(6, 18, 52, 38, 7), c)
    s.rect(6, 32, 52, 5, dark(c, 0.25))
    s.path(rrect_path(27, 29, 10, 10, 2), P["saffron"])
    s.path("M12 26 h12", "none", stroke=light(c, 0.35), sw=4)
    return s


def study():
    s, c = ico(), P["lapis"]
    s.path("M16 34 V46 C16 52 48 52 48 46 V34 Z", dark(c, 0.2))
    s.poly([(32, 12), (60, 26), (32, 40), (4, 26)], c)
    s.poly([(32, 12), (60, 26), (32, 26)], light(c, 0.25))
    s.path("M52 30 V46", "none", stroke=P["saffron"], sw=3.5)
    s.circle(52, 48, 4, P["saffron"])
    return s


def book():
    s, c = ico(), P["turquoise"]
    s.path("M32 16 C24 10 14 10 6 12 V52 C14 50 24 50 32 56 Z", c)
    s.path("M32 16 C40 10 50 10 58 12 V52 C50 50 40 50 32 56 Z", dark(c, 0.2))
    s.path("M12 20 C17 19 22 19 26 21 M12 28 C17 27 22 27 26 29", "none", stroke=light(c, 0.5), sw=3)
    return s


def certificate():
    s, c = ico(), P["sand"]
    s.path(rrect_path(8, 8, 44, 40, 5), c)
    s.path("M16 18 H44 M16 26 H44 M16 34 H32", "none", stroke=P["sand_dk"], sw=3.5)
    s.circle(46, 44, 10, P["pomegranate"])
    s.poly([(40, 50), (38, 60), (44, 56), (48, 60), (48, 52)], dark(P["pomegranate"], 0.2))
    s.circle(46, 44, 5, light(P["pomegranate"], 0.35))
    return s


def company():
    s, c = ico(), P["turquoise"]
    s.path(rrect_path(8, 18, 26, 40, 3), dark(c, 0.15))
    s.path(rrect_path(28, 6, 28, 52, 3), c)
    for y in range(12, 48, 9):
        for x in (33, 43):
            s.rect(x, y, 6, 5, light(c, 0.45), rx=1)
    for y in range(24, 50, 9):
        s.rect(13, y, 6, 5, light(c, 0.3), rx=1)
    s.rect(37, 48, 10, 10, dark(c, 0.4), rx=1)
    return s


def market():
    s, c = ico(), P["pomegranate"]
    s.path(rrect_path(10, 30, 44, 26, 3), P["sand"])
    s.rect(26, 38, 12, 18, P["brick"], rx=1)
    s.rect(14, 36, 9, 8, light(P["sky"], 0.2), rx=1)
    s.rect(41, 36, 9, 8, light(P["sky"], 0.2), rx=1)
    for k in range(6):
        col = c if k % 2 == 0 else P["white"]
        x = 6 + k * 52 / 6
        s.path("M%.1f 12 H%.1f L%.1f 26 Q%.1f 32 %.1f 26 Z" % (x, x + 52 / 6, x + 52 / 6, x + 26 / 6, x), col)
    s.rect(6, 8, 52, 5, dark(c, 0.2), rx=2)
    return s


def cart():
    s, c = ico(), P["turquoise"]
    s.path("M4 10 H14 L22 42 H50 L56 20 H18", "none", stroke=dark(c, 0.1), sw=5)
    s.poly([(18, 20), (56, 20), (50, 42), (22, 42)], c)
    s.circle(24, 52, 5, P["slate"])
    s.circle(48, 52, 5, P["slate"])
    return s


def auction():
    s, c = ico(), P["earth"]
    s.path("M12 52 H40", "none", stroke=P["slate"], sw=6)
    s.path("M26 26 L50 50", "none", stroke=P["earth_dk"], sw=6)
    s.path(rrect_path(10, 10, 26, 16, 4), c)
    s.path(rrect_path(10, 10, 26, 16, 4), light(c, 0.2))
    s.poly([(12, 30), (30, 12), (40, 22), (22, 40)], c)
    s.poly([(12, 30), (30, 12), (33, 15), (15, 33)], light(c, 0.35))
    return s


def travel():
    s, c = ico(), P["turquoise"]
    s.circle(32, 32, 27, dark(c, 0.2))
    s.circle(32, 32, 22, P["night"])
    s.poly([(32, 12), (38, 32), (32, 52), (26, 32)], P["white"])
    s.poly([(32, 12), (38, 32), (26, 32)], P["pomegranate"])
    s.circle(32, 32, 3.5, c)
    return s


def pin():
    s, c = ico(), P["pomegranate"]
    s.ellipse(32, 56, 12, 4, P["ink"], opacity=0.3)
    s.path("M32 58 C22 44 12 34 12 24 C12 12 21 4 32 4 C43 4 52 12 52 24 C52 34 42 44 32 58 Z", c)
    s.circle(32, 24, 8, P["white"])
    s.path("M19 20 C20 15 24 11 28 10", "none", stroke=light(c, 0.45), sw=3.5)
    return s


def map_():
    s, c = ico(), P["turquoise"]
    s.poly([(6, 14), (22, 8), (22, 52), (6, 58)], c)
    s.poly([(22, 8), (42, 14), (42, 58), (22, 52)], light(c, 0.3))
    s.poly([(42, 14), (58, 8), (58, 52), (42, 58)], c)
    s.path("M10 44 C18 38 24 42 30 34 S44 30 54 20", "none", stroke=P["saffron"], sw=3.5)
    s.circle(54, 20, 3.5, P["pomegranate"])
    return s


def city():
    s, c = ico(), P["turquoise"]
    s.path(rrect_path(6, 30, 16, 28, 2), dark(P["lapis"], 0.05))
    s.path(rrect_path(40, 22, 18, 36, 2), P["lapis"])
    s.path(rrect_path(18, 28, 26, 30, 2), P["sand"])
    s.path("M18 30 A13 13 0 0 1 44 30 Z", c)
    s.circle(31, 14, 2.5, P["saffron"])
    s.path("M31 16 V20", "none", stroke=P["saffron"], sw=2)
    s.path("M26 58 V46 A5 5 0 0 1 36 46 V58 Z", dark(P["sand"], 0.45))
    for y in (28, 36, 44):
        s.rect(45, y, 8, 4, light(P["lapis"], 0.45), rx=1)
    return s


def walk():
    s, c = ico(), P["turquoise"]
    s.circle(36, 10, 6, c)
    s.path("M34 20 L28 38 L36 46 L34 58", "none", stroke=c, sw=7)
    s.path("M28 38 L20 58", "none", stroke=dark(c, 0.2), sw=7)
    s.path("M33 22 L22 28 L18 36", "none", stroke=dark(c, 0.2), sw=5)
    s.path("M34 24 L42 32 L50 32", "none", stroke=c, sw=5)
    return s


def bus():
    s, c = ico(), P["saffron"]
    s.path(rrect_path(10, 6, 44, 46, 8), c)
    s.path(rrect_path(15, 12, 34, 18, 3), light(P["sky"], 0.3))
    s.rect(15, 34, 34, 3, dark(c, 0.2))
    s.circle(19, 43, 3.6, P["white"])
    s.circle(45, 43, 3.6, P["white"])
    s.path(rrect_path(12, 50, 10, 8, 2), P["slate"])
    s.path(rrect_path(42, 50, 10, 8, 2), P["slate"])
    s.rect(24, 7, 16, 3, dark(c, 0.2), rx=1.5)
    return s


def car():
    s, c = ico(), P["sky"]
    s.path("M14 30 L20 16 Q22 12 26 12 H40 Q44 12 46 16 L52 30 Z", dark(c, 0.15))
    s.path("M20 29 L24 18 H40 L45 29 Z", light(c, 0.55))
    s.path(rrect_path(6, 28, 52, 18, 6), c)
    s.circle(18, 47, 6.5, P["slate"])
    s.circle(46, 47, 6.5, P["slate"])
    s.circle(18, 47, 2.4, P["stone"])
    s.circle(46, 47, 2.4, P["stone"])
    s.rect(9, 33, 8, 4, P["saffron"], rx=2)
    s.rect(47, 33, 8, 4, P["white"], rx=2)
    return s


def train():
    s, c = ico(), P["turquoise"]
    s.path(rrect_path(12, 4, 40, 46, 10), c)
    s.path(rrect_path(17, 10, 30, 16, 4), light(P["sky"], 0.3))
    s.rect(12, 30, 40, 4, P["white"])
    s.circle(21, 41, 3.5, P["saffron"])
    s.circle(43, 41, 3.5, P["saffron"])
    s.path("M20 50 L12 60 M44 50 L52 60", "none", stroke=P["slate"], sw=4.5)
    s.path("M16 57 H48", "none", stroke=P["slate"], sw=3)
    return s


def plane():
    s, c = ico(), P["stone"]
    s.path("M32 4 C36 4 37 10 37 16 V26 L60 40 V46 L37 38 V50 L45 56 V60 L32 56 L19 60 V56 L27 50 V38 L4 46 V40 L27 26 V16 C27 10 28 4 32 4 Z", c)
    s.path("M32 4 C36 4 37 10 37 16 V56 L32 56 Z", dark(c, 0.15))
    s.rect(30, 10, 4, 6, P["sky"], rx=2)
    return s


def bell():
    s, c = ico(), P["saffron"]
    s.path("M32 6 C20 6 14 16 14 28 V40 L8 48 H56 L50 40 V28 C50 16 44 6 32 6 Z", c)
    s.circle(32, 53, 6, dark(c, 0.2))
    s.path("M21 26 C21 19 24 15 29 13", "none", stroke=light(c, 0.5), sw=4)
    return s


def settings():
    s, c = ico(), P["stone_dk"]
    teeth = []
    for k in range(16):
        r = 27 if k % 2 == 0 else 21
        a = math.radians(k * 22.5 - 11.25 * (k % 2) + (5 if k % 2 == 0 else 0))
        teeth.append((32 + r * math.cos(math.radians(k * 22.5)), 32 + r * math.sin(math.radians(k * 22.5))))
    pts_ = []
    for k in range(8):
        a = k * 45
        for da, r in ((-14, 21), (-9, 28), (9, 28), (14, 21)):
            pts_.append((32 + r * math.cos(math.radians(a + da)), 32 + r * math.sin(math.radians(a + da))))
    s.poly(pts_, c)
    s.circle(32, 32, 19, light(c, 0.15))
    s.circle(32, 32, 8, P["night"])
    return s


def profile():
    s, c = ico(), P["turquoise"]
    s.circle(32, 20, 13, c)
    s.path("M8 58 C8 42 18 36 32 36 C46 36 56 42 56 58 Z", dark(c, 0.15))
    s.circle(27, 15, 4, light(c, 0.45))
    return s


def friends():
    s, c = ico(), P["sky"]
    s.circle(42, 20, 10, dark(c, 0.2))
    s.path("M26 56 C26 42 34 36 44 36 C54 36 60 42 60 56 Z", dark(c, 0.35))
    s.circle(24, 22, 11, c)
    s.path("M4 58 C4 44 12 38 24 38 C36 38 44 44 44 58 Z", c)
    return s


def more():
    s, c = ico(), P["stone"]
    for x in (12, 32, 52):
        s.circle(x, 32, 6.5, c)
    return s


def grid():
    s, c = ico(), P["stone"]
    for x in (8, 36):
        for y in (8, 36):
            s.path(rrect_path(x, y, 20, 20, 6), c if (x + y) % 56 else light(P["turquoise"], 0.1))
    return s


def back():
    s, c = ico(), P["stone"]
    s.path("M40 10 L18 32 L40 54", "none", stroke=c, sw=8)
    return s


def forward():
    s, c = ico(), P["stone"]
    s.path("M24 10 L46 32 L24 54", "none", stroke=c, sw=8)
    return s


def refresh():
    s, c = ico(), P["turquoise"]
    s.path("M50 26 A20 20 0 0 0 14 22", "none", stroke=c, sw=6)
    s.poly([(52, 10), (54, 30), (36, 26)], c)
    s.path("M14 38 A20 20 0 0 0 50 42", "none", stroke=c, sw=6)
    s.poly([(12, 54), (10, 34), (28, 38)], c)
    return s


def language():
    s, c = ico(), P["sky"]
    s.circle(32, 32, 26, c)
    s.path("M32 6 C20 18 20 46 32 58 C44 46 44 18 32 6 Z", "none", stroke=light(c, 0.55), sw=3)
    s.path("M6 32 H58 M10 19 H54 M10 45 H54", "none", stroke=light(c, 0.55), sw=3)
    return s


def close():
    s, c = ico(), P["stone"]
    s.path("M16 16 L48 48 M48 16 L16 48", "none", stroke=c, sw=8)
    return s


def check():
    s, c = ico(), P["leaf"]
    s.circle(32, 32, 26, c)
    s.path("M19 33 L28 42 L46 22", "none", stroke=P["white"], sw=6.5)
    return s


def plus():
    s, c = ico(), P["turquoise"]
    s.circle(32, 32, 26, c)
    s.path("M32 18 V46 M18 32 H46", "none", stroke=P["white"], sw=6.5)
    return s


def warning():
    s, c = ico(), P["saffron"]
    s.path("M32 6 L60 54 Q61 58 57 58 H7 Q3 58 4 54 Z", c)
    s.path("M32 22 V38", "none", stroke=P["ink"], sw=6)
    s.circle(32, 48, 3.8, P["ink"])
    return s


def info():
    s, c = ico(), P["lapis"]
    s.circle(32, 32, 26, c)
    s.circle(32, 19, 4, P["white"])
    s.path("M32 29 V46", "none", stroke=P["white"], sw=6.5)
    return s


def clock():
    s, c = ico(), P["sky"]
    s.circle(32, 32, 26, c)
    s.circle(32, 32, 21, P["white"])
    s.path("M32 18 V32 L42 38", "none", stroke=P["slate"], sw=4.5)
    s.circle(32, 32, 3, P["pomegranate"])
    return s


def hourglass():
    s, c = ico(), P["sand_dk"]
    s.rect(12, 4, 40, 6, P["earth"], rx=3)
    s.rect(12, 54, 40, 6, P["earth"], rx=3)
    s.path("M16 10 H48 C48 22 38 26 36 32 C38 38 48 42 48 54 H16 C16 42 26 38 28 32 C26 26 16 22 16 10 Z", light(P["sky"], 0.55))
    s.path("M22 16 H42 C40 22 34 26 32 30 C30 26 24 22 22 16 Z", P["saffron"])
    s.path("M20 52 C22 44 30 40 32 40 C34 40 42 44 44 52 Z", P["saffron"])
    return s


def search():
    s, c = ico(), P["stone"]
    s.circle(27, 27, 17, "none", stroke=c, sw=7)
    s.circle(27, 27, 12, light(P["sky"], 0.35), opacity=0.5)
    s.path("M40 40 L56 56", "none", stroke=c, sw=9)
    return s


def lock():
    s, c = ico(), P["saffron"]
    s.path("M20 28 V20 A12 12 0 0 1 44 20 V28", "none", stroke=P["stone_dk"], sw=6)
    s.path(rrect_path(12, 28, 40, 30, 6), c)
    s.circle(32, 41, 5, dark(c, 0.45))
    s.rect(30, 42, 4, 9, dark(c, 0.45), rx=2)
    return s


def home():
    s, c = ico(), P["brick"]
    s.path("M8 30 L32 8 L56 30", "none", stroke=dark(c, 0.15), sw=7)
    s.path("M14 30 L32 14 L50 30 V54 Q50 58 46 58 H18 Q14 58 14 54 Z", P["sand"])
    s.path("M26 58 V42 H38 V58 Z", c)
    s.rect(42, 10, 6, 12, dark(c, 0.15), rx=1)
    return s


def inventory():
    s, c = ico(), P["earth"]
    s.path("M22 16 V12 A10 10 0 0 1 42 12 V16", "none", stroke=dark(c, 0.3), sw=5)
    s.path(rrect_path(8, 16, 48, 42, 10), c)
    s.path(rrect_path(16, 34, 32, 16, 5), dark(c, 0.2))
    s.rect(29, 30, 6, 8, P["saffron"], rx=2)
    s.path("M14 26 C14 22 17 20 21 20", "none", stroke=light(c, 0.4), sw=4)
    return s


def life():
    s, c = ico(), P["leaf"]
    s.path("M32 58 V30", "none", stroke=dark(c, 0.3), sw=5)
    s.path("M32 34 C18 36 8 26 8 10 C24 10 34 18 32 34 Z", c)
    s.path("M32 30 C44 32 56 24 56 12 C42 10 32 18 32 30 Z", light(c, 0.2))
    s.path("M14 16 C20 22 26 26 30 30", "none", stroke=light(c, 0.45), sw=2.5)
    return s


def skills():
    s, c = ico(), P["stone_dk"]
    s.path("M14 50 L36 28", "none", stroke=P["earth"], sw=7)
    s.path("M36 28 A14 14 0 1 0 50 12 L44 20 L38 18 L36 12 L44 6", c)
    s.path("M12 12 L28 28 M24 36 L44 56", "none", stroke=P["saffron"], sw=6)
    return s


def chart():
    s, c = ico(), P["leaf"]
    s.path(rrect_path(6, 6, 52, 52, 8), P["panel_hi"])
    s.path("M12 46 L26 32 L36 40 L52 20", "none", stroke=c, sw=5.5)
    s.poly([(44, 18), (54, 16), (52, 26)], c)
    return s


def promotion():
    s, c = ico(), P["leaf"]
    s.circle(32, 32, 26, c)
    s.path("M32 46 V20 M20 30 L32 18 L44 30", "none", stroke=P["white"], sw=6.5)
    return s


def office():
    s, c = ico(), P["sand"]
    s.path("M12 26 A20 16 0 0 1 52 26 Z", P["saffron"])
    s.rect(30, 4, 4, 8, P["saffron_dk"], rx=1)
    s.path(rrect_path(8, 26, 48, 6, 2), c)
    for x in (13, 24, 35, 46):
        s.rect(x, 33, 5, 17, light(c, 0.3), rx=1)
    s.path(rrect_path(6, 50, 52, 8, 3), dark(c, 0.15))
    return s


def police():
    s, c = ico(), P["lapis"]
    s.path("M32 4 L54 12 V30 C54 44 44 54 32 60 C20 54 10 44 10 30 V12 Z", c)
    s.path("M32 4 L54 12 V30 C54 44 44 54 32 60 Z", dark(c, 0.15))
    s.poly(star_points(32, 30, 12, 5.5), P["saffron"])
    return s


def hospital():
    s, c = ico(), P["pomegranate"]
    s.path(rrect_path(6, 6, 52, 52, 12), P["white"])
    s.path("M26 14 H38 V26 H50 V38 H38 V50 H26 V38 H14 V26 H26 Z", c)
    return s


def jail():
    s, c = ico(), P["slate"]
    s.path(rrect_path(6, 6, 52, 52, 8), mix(P["slate"], P["night"], 0.4))
    for x in (16, 28, 40, 52):
        s.rect(x - 3, 6, 6, 52, P["stone_dk"], rx=2)
    s.rect(6, 22, 52, 5, P["stone"], rx=2)
    return s


def achievement():
    s, c = ico(), P["saffron"]
    s.path("M16 8 H48 V24 C48 34 40 40 32 40 C24 40 16 34 16 24 Z", c)
    s.path("M16 12 H8 C8 24 12 28 18 29 M48 12 H56 C56 24 52 28 46 29", "none", stroke=dark(c, 0.15), sw=4)
    s.rect(28, 40, 8, 10, dark(c, 0.2))
    s.path(rrect_path(18, 50, 28, 8, 3), dark(c, 0.3))
    s.path("M22 14 C22 22 24 28 28 32", "none", stroke=light(c, 0.5), sw=4)
    return s


def bed():
    s, c = ico(), P["violet"]
    s.path(rrect_path(6, 30, 52, 16, 4), c)
    s.path(rrect_path(8, 22, 18, 10, 4), P["white"])
    s.path(rrect_path(24, 24, 34, 8, 3), light(c, 0.35))
    s.rect(6, 44, 5, 12, dark(c, 0.3), rx=2)
    s.rect(53, 44, 5, 12, dark(c, 0.3), rx=2)
    s.rect(4, 14, 5, 42, dark(c, 0.3), rx=2)
    return s


def mission():
    s, c = ico(), P["sand"]
    s.path(rrect_path(10, 8, 44, 52, 6), P["earth"])
    s.path(rrect_path(14, 14, 36, 42, 3), c)
    s.path(rrect_path(22, 4, 20, 10, 3), P["stone_dk"])
    s.path("M20 26 l4 4 l8 -8 M36 28 H44 M20 42 l4 4 l8 -8 M36 44 H44", "none", stroke=P["leaf_dk"], sw=3.5)
    return s


def wave():
    s, c = ico(), P["saffron"]
    s.path("M20 58 C12 50 10 40 12 32 L16 18 Q18 14 21 16 L22 30 L24 10 Q26 6 29 9 L30 28 L32 6 Q34 3 37 6 L37 28 L40 10 Q42 7 45 10 L44 34 L50 26 Q54 24 55 28 L46 48 C42 56 30 62 20 58 Z", c)
    return s


def faction():
    s, c = ico(), P["pomegranate"]
    s.path("M12 6 V60", "none", stroke=P["stone_dk"], sw=5)
    s.path("M14 8 H52 L44 22 L52 36 H14 Z", c)
    s.poly(star_points(30, 22, 7, 3), P["white"])
    return s


def phone():
    s, c = ico(), P["slate"]
    s.path(rrect_path(16, 4, 32, 56, 7), c)
    s.path(rrect_path(20, 10, 24, 40, 3), light(P["sky"], 0.2))
    s.circle(32, 54, 2.5, P["stone"])
    return s


def gold():
    s, c = ico(), P["saffron"]
    s.poly([(10, 50), (54, 50), (48, 36), (16, 36)], dark(c, 0.15))
    s.poly([(16, 36), (48, 36), (44, 26), (20, 26)], c)
    s.poly([(18, 30), (40, 30), (38, 28), (20, 28)], light(c, 0.5))
    s.poly([(4, 60), (60, 60), (54, 50), (10, 50)], c)
    return s


def stock():
    s, c = ico(), P["leaf"]
    for x, h, col in ((10, 20, P["pomegranate"]), (24, 30, c), (38, 24, c), (52, 38, c)):
        s.rect(x - 1, 58 - h - 6, 2, h + 10, P["stone_dk"])
        s.path(rrect_path(x - 5, 58 - h, 10, h - 4, 2), col)
    return s


def food():
    s, c = ico(), P["brick"]
    s.circle(26, 26, 18, c)
    s.circle(20, 20, 6, light(c, 0.35))
    s.path("M34 36 L52 54", "none", stroke=P["sand"], sw=7)
    s.circle(54, 50, 5, P["sand"])
    s.circle(50, 56, 5, P["sand"])
    return s


ICONS = {
    "cash": cash, "bank": bank, "card": card, "pay": pay, "moneybag": moneybag, "deposit": deposit,
    "withdraw": withdraw, "energy": energy, "health": health, "hunger": hunger, "sleep": sleep,
    "stress": stress, "happiness": happiness, "level": level, "xp": xp, "rank": rank, "age": age,
    "crime": crime, "work": work, "study": study, "book": book, "certificate": certificate,
    "company": company, "market": market, "cart": cart, "auction": auction, "travel": travel,
    "pin": pin, "map": map_, "city": city, "walk": walk, "bus": bus, "car": car, "train": train,
    "plane": plane, "bell": bell, "settings": settings, "profile": profile, "friends": friends,
    "more": more, "grid": grid, "back": back, "forward": forward, "refresh": refresh,
    "language": language, "close": close, "check": check, "plus": plus, "warning": warning,
    "info": info, "clock": clock, "hourglass": hourglass, "search": search, "lock": lock,
    "home": home, "inventory": inventory, "life": life, "skills": skills, "chart": chart,
    "promotion": promotion, "office": office, "police": police, "hospital": hospital,
    "jail": jail, "achievement": achievement, "bed": bed, "mission": mission, "wave": wave,
    "faction": faction, "phone": phone, "gold": gold, "stock": stock, "food": food,
}


def build():
    return [fn().save("icons/%s.svg" % name) for name, fn in ICONS.items()]
