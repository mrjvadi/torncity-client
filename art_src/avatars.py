"""Player avatars: the 12 presets of configs/content/life.yml (life.avatars).

Round portraits, 256 x 256: a coloured disc with a soft radial light, a thin
inner ring, and the subject drawn in the icon language (filled, two-tone,
highlight from the upper left). Codes: fox lion owl wolf cat eagle tulip rocket
gem crown panda dove.
"""
import math

from svgkit import Svg, P, light, dark, mix, star_points

S = 256
C = S / 2


def base(bg):
    s = Svg(S, S)
    s.clip_circle = (C, C, C)
    g = s.rad([(0, light(bg, 0.35)), (0.7, bg), (1, dark(bg, 0.25))], 0.35, 0.3, 0.8)
    s.circle(C, C, C, g)
    s.circle(C, C, C - 6, "none", stroke=light(bg, 0.45), sw=3, opacity=0.6)
    return s


def eye(s, x, y, r, iris=None):
    s.circle(x, y, r, P["white"])
    s.circle(x + r * 0.15, y + r * 0.1, r * 0.62, iris or P["ink"])
    s.circle(x - r * 0.1, y - r * 0.2, r * 0.22, P["white"])


def fox():
    s, c = base(P["sky"]), "#F08A3C"
    s.poly([(58, 40), (104, 92), (70, 112)], dark(c, 0.15))
    s.poly([(198, 40), (152, 92), (186, 112)], dark(c, 0.15))
    s.poly([(66, 58), (96, 92), (76, 102)], P["ink"])
    s.poly([(190, 58), (160, 92), (180, 102)], P["ink"])
    s.path("M128 214 C84 214 50 178 48 128 C48 100 70 84 128 84 C186 84 208 100 208 128 C206 178 172 214 128 214 Z", c)
    s.path("M128 214 C104 214 70 190 58 150 C84 150 110 160 128 180 C146 160 172 150 198 150 C186 190 152 214 128 214 Z", P["white"])
    s.path("M70 110 C80 98 96 94 110 96", "none", stroke=light(c, 0.4), sw=6)
    eye(s, 98, 138, 12)
    eye(s, 158, 138, 12)
    s.path("M116 176 Q128 168 140 176 Q134 190 128 190 Q122 190 116 176 Z", P["ink"])
    return s


def lion():
    s = base(P["pomegranate"])
    mane = "#C9731F"
    for k in range(16):
        a = 2 * math.pi * k / 16
        s.circle(C + 72 * math.cos(a), C + 10 + 72 * math.sin(a), 32, mane if k % 2 else dark(mane, 0.12))
    s.circle(C, C + 10, 70, P["saffron"])
    s.circle(92, 72, 18, P["saffron"])
    s.circle(164, 72, 18, P["saffron"])
    s.circle(92, 72, 9, dark(P["saffron"], 0.25))
    s.circle(164, 72, 9, dark(P["saffron"], 0.25))
    s.ellipse(C, 170, 36, 28, light(P["saffron"], 0.5))
    eye(s, 104, 128, 11, "#6B3F12")
    eye(s, 152, 128, 11, "#6B3F12")
    s.path("M116 156 L140 156 L128 170 Z", "#6B3F12")
    s.path("M128 170 V182 M112 186 Q128 196 144 186", "none", stroke="#6B3F12", sw=4)
    s.path("M86 110 C90 100 100 94 110 94", "none", stroke=light(P["saffron"], 0.5), sw=5)
    return s


def owl():
    s = base(P["violet"])
    body = "#8A5A3C"
    s.path("M70 70 L94 96 M186 70 L162 96", "none", stroke=dark(body, 0.2), sw=14)
    s.path("M128 222 C70 222 56 170 60 130 C62 90 90 70 128 70 C166 70 194 90 196 130 C200 170 186 222 128 222 Z", body)
    s.path("M128 222 C96 222 86 196 88 170 C104 176 116 178 128 178 C140 178 152 176 168 170 C170 196 160 222 128 222 Z", light(body, 0.45))
    for x in (96, 160):
        s.circle(x, 124, 30, light(body, 0.6))
        s.circle(x, 124, 22, P["saffron"])
        s.circle(x, 124, 13, P["ink"])
        s.circle(x - 5, 118, 5, P["white"])
    s.poly([(118, 146), (138, 146), (128, 166)], P["saffron_dk"])
    for x, y in ((108, 196), (128, 204), (148, 196)):
        s.path("M%d %d q6 6 12 0" % (x - 6, y), "none", stroke=dark(body, 0.2), sw=3)
    return s


def wolf():
    s = base(P["lapis"])
    c = "#8D98B3"
    s.poly([(64, 36), (112, 92), (72, 118)], dark(c, 0.2))
    s.poly([(192, 36), (144, 92), (184, 118)], dark(c, 0.2))
    s.poly([(72, 58), (100, 92), (80, 106)], light(c, 0.4))
    s.poly([(184, 58), (156, 92), (176, 106)], light(c, 0.4))
    s.path("M128 222 C96 222 56 186 52 140 C50 110 78 86 128 86 C178 86 206 110 204 140 C200 186 160 222 128 222 Z", c)
    s.path("M128 222 C110 222 96 206 96 180 C96 160 110 150 128 150 C146 150 160 160 160 180 C160 206 146 222 128 222 Z", light(c, 0.6))
    s.path("M128 90 L116 150 L140 150 Z", light(c, 0.35))
    eye(s, 98, 132, 11, "#F6B93B")
    eye(s, 158, 132, 11, "#F6B93B")
    s.ellipse(C, 176, 14, 10, P["ink"])
    return s


def cat():
    s = base(P["turquoise"])
    c = "#E7A15B"
    s.poly([(60, 48), (104, 92), (64, 120)], c)
    s.poly([(196, 48), (152, 92), (192, 120)], c)
    s.poly([(68, 66), (94, 92), (72, 106)], P["rose"])
    s.poly([(188, 66), (162, 92), (184, 106)], P["rose"])
    s.circle(C, 140, 80, c)
    for k, x in enumerate((104, 128, 152)):
        s.path("M%d 64 L%d 88" % (x, x), "none", stroke=dark(c, 0.25), sw=7)
    s.ellipse(C, 176, 34, 24, light(c, 0.55))
    eye(s, 98, 136, 13, P["leaf_dk"])
    eye(s, 158, 136, 13, P["leaf_dk"])
    s.poly([(120, 164), (136, 164), (128, 174)], P["rose"])
    for dy in (-6, 6):
        s.path("M112 %d L64 %d M144 %d L192 %d" % (176 + dy, 170 + dy * 2, 176 + dy, 170 + dy * 2), "none", stroke=P["white"], sw=3, opacity=0.9)
    return s


def eagle():
    s = base(P["sky"])
    brown = "#6E4B2E"
    s.path("M40 230 C50 170 80 150 128 150 C176 150 206 170 216 230 Z", brown)
    s.path("M128 176 C84 176 70 130 76 100 C82 70 104 54 128 54 C160 54 186 76 186 112 C186 150 164 176 128 176 Z", P["white"])
    s.path("M150 104 C176 102 196 114 204 134 C190 132 176 138 168 150 C160 138 150 124 150 104 Z", P["saffron"])
    s.path("M168 150 C176 138 190 132 204 134 C198 144 186 150 176 152 Z", P["saffron_dk"])
    eye(s, 140, 100, 10, "#8A5A1C")
    s.path("M118 88 L152 92", "none", stroke=P["ink"], sw=5)
    s.path("M86 90 C88 76 98 66 110 62", "none", stroke=P["stone"], sw=5)
    return s


def tulip():
    s = base(P["leaf_dk"])
    red = P["pomegranate"]
    s.path("M128 226 V120", "none", stroke=dark(P["leaf"], 0.2), sw=9)
    s.path("M128 206 C96 200 76 176 70 146 C96 150 118 170 128 196 Z", P["leaf"])
    s.path("M128 190 C156 182 176 160 184 132 C160 138 138 156 128 180 Z", light(P["leaf"], 0.2))
    s.path("M86 72 C86 118 102 136 128 136 C154 136 170 118 170 72 L148 96 L128 60 L108 96 Z", red)
    s.path("M108 96 L128 60 L148 96 C144 116 138 132 128 136 C118 132 112 116 108 96 Z", light(red, 0.2))
    s.path("M94 84 C94 104 100 118 110 126", "none", stroke=light(red, 0.5), sw=5)
    return s


def rocket():
    s = base(P["ink"])
    for k in range(18):
        a = k * 2.4
        s.circle(C + 100 * math.cos(a) * (0.4 + (k % 5) / 8), C + 100 * math.sin(a) * (0.4 + (k % 3) / 5), 2 + k % 3, P["white"], opacity=0.7)
    s.path("M104 186 C96 212 112 232 128 240 C144 232 160 212 152 186 Z", P["saffron"])
    s.path("M114 186 C110 204 120 218 128 224 C136 218 146 204 142 186 Z", P["white"])
    s.path("M98 150 L66 190 L102 184 Z", P["pomegranate"])
    s.path("M158 150 L190 190 L154 184 Z", dark(P["pomegranate"], 0.2))
    s.path("M128 30 C160 56 166 110 158 188 H98 C90 110 96 56 128 30 Z", P["stone"])
    s.path("M128 30 C160 56 166 110 158 188 H128 Z", dark(P["stone"], 0.15))
    s.path("M128 30 C142 42 150 56 154 72 H102 C106 56 114 42 128 30 Z", P["pomegranate"])
    s.circle(128, 112, 18, P["lapis"])
    s.circle(128, 112, 12, P["sky"])
    s.circle(122, 106, 4, P["white"])
    return s


def gem():
    s = base(P["violet"])
    t = P["turquoise"]
    s.poly([(76, 96), (180, 96), (216, 128) if False else (208, 128), (128, 222), (48, 128)], t)
    s.poly([(96, 60), (160, 60), (208, 104), (48, 104)], light(t, 0.35))
    s.poly([(48, 104), (208, 104), (128, 222)], t)
    s.poly([(48, 104), (100, 104), (128, 222)], light(t, 0.15))
    s.poly([(156, 104), (208, 104), (128, 222)], dark(t, 0.2))
    s.poly([(100, 104), (156, 104), (128, 222)], mix(t, P["white"], 0.1))
    s.poly([(96, 60), (128, 60), (100, 104), (48, 104)], light(t, 0.55))
    s.poly([(128, 60), (160, 60), (156, 104), (100, 104)], light(t, 0.4))
    s.poly(star_points(84, 78, 12, 3, 4), P["white"])
    return s


def crown():
    s = base(P["lapis_dk"])
    g = P["saffron"]
    s.poly([(46, 90), (88, 136), (128, 66), (168, 136), (210, 90), (192, 190), (64, 190)], g)
    s.poly([(128, 66), (168, 136), (192, 190), (128, 190)], dark(g, 0.1))
    s.rect(60, 178, 136, 26, dark(g, 0.2), rx=8)
    for x, col in ((90, P["pomegranate"]), (128, P["turquoise"]), (166, P["pomegranate"])):
        s.circle(x, 191, 8, col)
    for x, y in ((46, 90), (128, 66), (210, 90)):
        s.circle(x, y - 8, 11, light(g, 0.3))
    s.circle(128, 148, 14, P["sky"])
    s.circle(123, 143, 4, P["white"])
    return s


def panda():
    s = base(P["leaf"])
    s.circle(72, 76, 30, P["ink"])
    s.circle(184, 76, 30, P["ink"])
    s.circle(C, 140, 86, P["white"])
    s.path("M70 126 C74 104 104 100 116 120 C120 140 104 160 88 160 C72 158 66 142 70 126 Z", P["ink"])
    s.path("M186 126 C182 104 152 100 140 120 C136 140 152 160 168 160 C184 158 190 142 186 126 Z", P["ink"])
    s.circle(98, 132, 8, P["white"])
    s.circle(158, 132, 8, P["white"])
    s.circle(100, 132, 4, P["ink"])
    s.circle(156, 132, 4, P["ink"])
    s.ellipse(C, 170, 14, 10, P["ink"])
    s.path("M114 184 Q128 196 142 184", "none", stroke=P["ink"], sw=4)
    s.circle(84, 166, 9, P["rose"], opacity=0.6)
    s.circle(172, 166, 9, P["rose"], opacity=0.6)
    return s


def dove():
    s = base(P["sky"])
    w = P["white"]
    s.path("M52 150 C70 96 120 80 150 96 C170 106 176 128 170 150 C200 150 218 166 224 186 C190 184 150 196 120 196 C86 196 60 180 52 150 Z", w)
    s.path("M96 120 C120 70 170 50 214 58 C196 90 170 118 128 136 Z", P["stone"])
    s.path("M96 120 C120 84 160 66 200 66", "none", stroke=w, sw=5)
    s.circle(160, 104, 16, w)
    eye(s, 164, 100, 5)
    s.poly([(174, 104), (194, 110), (174, 114)], P["saffron"])
    s.path("M186 110 C200 124 206 140 204 152", "none", stroke=P["leaf_dk"], sw=4)
    for k, (x, y) in enumerate(((196, 124), (204, 136), (200, 146))):
        s.ellipse(x, y, 7, 4, P["leaf"])
    return s


AVATARS = {"fox": fox, "lion": lion, "owl": owl, "wolf": wolf, "cat": cat, "eagle": eagle, "tulip": tulip,
           "rocket": rocket, "gem": gem, "crown": crown, "panda": panda, "dove": dove}


def build():
    return [fn().save("avatars/%s.svg" % code) for code, fn in AVATARS.items()]
