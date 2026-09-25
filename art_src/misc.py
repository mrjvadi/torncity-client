"""Brand (logo, app icon, splash), the UI kit reference sheets and ground tiles."""
import math

from svgkit import Svg, P, light, dark, mix, star_points, rrect_path
from iso import Iso


# -- brand ------------------------------------------------------------------------------------
def _skyline(s, cx, base_y, scale, dome=P["turquoise"], tower=P["lapis"], sand=P["sand"]):
    """The emblem's city: a tiled dome between two towers and two minarets."""
    k = scale
    # back towers
    s.path(rrect_path(cx - 118 * k, base_y - 150 * k, 48 * k, 150 * k, 6 * k), dark(tower, 0.1))
    s.path(rrect_path(cx + 70 * k, base_y - 190 * k, 52 * k, 190 * k, 6 * k), tower)
    for i in range(6):
        for j in range(2):
            s.rect(cx + (78 + j * 22) * k, base_y - (176 - i * 26) * k, 14 * k, 14 * k, light(tower, 0.45), rx=2 * k)
    for i in range(5):
        s.rect(cx - 108 * k, base_y - (136 - i * 26) * k, 28 * k, 12 * k, light(tower, 0.3), rx=2 * k)
    # minarets
    for x in (-66, 52):
        s.path(rrect_path(cx + x * k, base_y - 170 * k, 14 * k, 170 * k, 4 * k), light(sand, 0.2))
        s.rect(cx + (x - 4) * k, base_y - 138 * k, 22 * k, 8 * k, P["saffron"], rx=3 * k)
        s.path("M%s %s L%s %s L%s %s Z" % (cx + x * k, base_y - 170 * k, cx + (x + 7) * k, base_y - 192 * k,
                                           cx + (x + 14) * k, base_y - 170 * k), dome)
    # the hall and its dome
    s.path(rrect_path(cx - 60 * k, base_y - 90 * k, 120 * k, 90 * k, 6 * k), sand)
    for i in range(3):
        x = cx + (-40 + i * 30) * k
        s.path("M%s %s V%s A%s %s 0 0 1 %s %s V%s Z" % (x, base_y, base_y - 50 * k, 10 * k, 10 * k, x + 20 * k,
                                                         base_y - 50 * k, base_y), dark(dome, 0.35))
    s.rect(cx - 60 * k, base_y - 90 * k, 120 * k, 10 * k, dome)
    g = s.lin([(0, light(dome, 0.45)), (0.6, dome), (1, dark(dome, 0.3))], 0, 0, 1, 0.4)
    s.path("M%s %s C%s %s %s %s %s %s C%s %s %s %s %s %s Z" % (
        cx - 52 * k, base_y - 90 * k, cx - 56 * k, base_y - 150 * k, cx - 10 * k, base_y - 176 * k, cx, base_y - 190 * k,
        cx + 10 * k, base_y - 176 * k, cx + 56 * k, base_y - 150 * k, cx + 52 * k, base_y - 90 * k), g)
    s.path("M%s %s C%s %s %s %s %s %s" % (cx - 36 * k, base_y - 110 * k, cx - 36 * k, base_y - 140 * k, cx - 20 * k,
                                         base_y - 158 * k, cx - 10 * k, base_y - 166 * k), "none", stroke=light(dome, 0.6), sw=5 * k)
    s.circle(cx, base_y - 196 * k, 6 * k, P["saffron"])


def logo():
    s = Svg(512, 512)
    ring = s.lin([(0, light(P["turquoise"], 0.3)), (1, P["turquoise_dk"])], 0, 0, 1, 1)
    s.circle(256, 262, 238, P["ink"], opacity=0.45)
    s.circle(256, 250, 236, ring)
    sky = s.lin([(0, "#2A2F6B"), (0.55, "#5B4E9A"), (1, "#F29A6B")])
    s.circle(256, 250, 214, sky)
    # the sun
    s.circle(256, 250, 96, "#FFD27A", opacity=0.35)
    s.circle(256, 250, 72, "#FFD27A")
    # stars
    for x, y, r in ((150, 130, 3), (360, 120, 2.5), (330, 170, 2), (180, 180, 2)):
        s.circle(x, y, r, P["white"], opacity=0.85)
    # ground and city (clipped to the disc by keeping it inside)
    s.path("M60 360 Q256 330 452 360 A214 214 0 0 1 60 360 Z", dark(P["lapis"], 0.45))
    _skyline(s, 256, 372, 1.0)
    s.path("M70 372 H442 A214 214 0 0 1 70 372 Z", P["ink"])
    # tile band
    for i in range(9):
        x = 118 + i * 34
        s.poly([(x, 404), (x + 12, 392), (x + 24, 404), (x + 12, 416)], P["saffron"] if i % 2 else P["turquoise"])
    return s


def app_icon():
    s = Svg(256, 256)
    bg = s.lin([(0, "#2B3470"), (1, "#141A33")], 0, 0, 1, 1)
    s.path(rrect_path(0, 0, 256, 256, 56), bg)
    s.circle(128, 128, 60, "#FFD27A", opacity=0.3)
    s.circle(128, 128, 44, "#FFD27A")
    _skyline(s, 128, 206, 0.6)
    s.rect(24, 204, 208, 30, P["ink"])
    s.path(rrect_path(0, 0, 256, 256, 56), "none", stroke=light(P["turquoise"], 0.2), sw=6)
    return s


def splash():
    W, H = 720, 1280
    s = Svg(W, H)
    sky = s.lin([(0, "#101533"), (0.35, "#2A2F6B"), (0.6, "#6A4F9A"), (0.78, "#E9866A"), (0.9, "#F6B96B")])
    s.rect(0, 0, W, H, sky)
    for i in range(70):
        x = (i * 137.5) % W
        y = (i * 71.3) % (H * 0.45)
        s.circle(x, y, 1 + (i % 3) * 0.6, P["white"], opacity=0.3 + (i % 5) * 0.12)
    # sun and glow
    glow = s.rad([(0, "#FFE3A0", 0.9), (0.4, "#FFB870", 0.35), (1, "#FF9A6B", 0)])
    s.circle(360, 900, 420, glow)
    s.circle(360, 905, 120, "#FFD58A")
    # Alborz: far ridge with snow, then nearer ridges
    far = [(0, 930), (70, 860), (130, 890), (220, 790), (300, 860), (380, 800), (470, 870), (560, 780), (650, 850), (720, 810), (720, 1000), (0, 1000)]
    s.poly(far, "#8C6FA8")
    for (x, y) in ((220, 790), (380, 800), (560, 780)):
        s.poly([(x - 34, y + 30), (x, y), (x + 36, y + 32), (x + 16, y + 26), (x, y + 36), (x - 14, y + 24)], "#F3EAF5", opacity=0.9)
    near = [(0, 980), (90, 930), (170, 960), (260, 910), (350, 950), (440, 900), (540, 950), (630, 915), (720, 945), (720, 1060), (0, 1060)]
    s.poly(near, "#5A4A86")
    # skyline silhouette with lit windows
    bld = [(0, 70, 150), (60, 50, 110), (105, 60, 190), (160, 45, 130), (200, 70, 230), (265, 40, 150),
           (440, 45, 160), (480, 70, 250), (545, 50, 140), (590, 60, 200), (645, 40, 120), (680, 60, 170)]
    for x, w, h in bld:
        s.rect(x, 1080 - h, w, h + 10, "#2A2552")
        for yy in range(1080 - h + 14, 1070, 22):
            for xx in range(x + 8, x + w - 10, 16):
                if (xx * 7 + yy * 3) % 5 < 2:
                    s.rect(xx, yy, 7, 9, "#FFC96B", opacity=0.85)
    _skyline(s, 360, 1090, 1.25, dome=P["turquoise"], tower="#3A3F8C", sand="#E8C99A")
    # ground and a tiled plaza edge
    s.rect(0, 1080, W, 200, "#1A1838")
    s.rect(0, 1080, W, 10, P["saffron_dk"])
    for i in range(0, W, 40):
        s.poly([(i, 1112), (i + 20, 1096), (i + 40, 1112), (i + 20, 1128)], P["turquoise_dk"] if (i // 40) % 2 else "#2E3A7A")
    fade = s.lin([(0, "#1A1838", 0), (1, "#0E1024", 1)])
    s.rect(0, 1130, W, 150, fade)
    return s


def build_brand():
    return [logo().save("brand/logo.svg"), app_icon().save("brand/icon.svg"), splash().save("brand/splash.svg")]


# -- UI kit reference (9-patch friendly) ------------------------------------------------------------
def build_ui():
    out = []
    # panel: 96x96, 24px corners -> 9-patch margins 28
    s = Svg(96, 96)
    s.path(rrect_path(4, 8, 88, 86, 24), P["ink"], opacity=0.4)
    g = s.lin([(0, P["panel_hi"]), (1, P["panel"])])
    s.path(rrect_path(4, 4, 88, 86, 24), g)
    s.path(rrect_path(4.75, 4.75, 86.5, 84.5, 23.5), "none", stroke=P["line"], sw=1.5)
    s.path("M20 6 H76", "none", stroke=P["white"], sw=1.5, opacity=0.18)
    out.append(s.save("ui/panel.svg"))
    for name, face in (("button_primary", P["turquoise"]), ("button_gold", P["saffron"]), ("button_ghost", P["panel_hi"]), ("button_danger", P["pomegranate"])):
        b = Svg(96, 72)
        b.path(rrect_path(2, 8, 92, 62, 20), dark(face, 0.35))
        b.path(rrect_path(2, 2, 92, 62, 20), b.lin([(0, light(face, 0.12)), (1, face)]))
        b.path("M22 5 H74", "none", stroke=P["white"], sw=2, opacity=0.35)
        out.append(b.save("ui/%s.svg" % name))
    bar = Svg(96, 24)
    bar.path(rrect_path(0, 0, 96, 24, 12), P["ink"], opacity=0.75)
    bar.path(rrect_path(0, 0, 64, 24, 12), bar.lin([(0, light(P["saffron"], 0.28)), (1, dark(P["saffron"], 0.12))]))
    bar.path(rrect_path(8, 4, 48, 5, 2.5), P["white"], opacity=0.3)
    out.append(bar.save("ui/bar.svg"))
    return out


# -- ground tiles (the map draws its ground in code; these are the slots an artist can fill) ----------
def build_tiles():
    out = []
    for name, top in (("grass", P["grass"]), ("road", P["asphalt"]), ("plaza", P["sand"]), ("water", P["water"])):
        s = Svg(128, 72)
        i = Iso(s, 64, 4, 0.64)
        i.quad([(0, 0, 0), (100, 0, 0), (100, 100, 0), (0, 100, 0)], top)
        i.quad([(0, 100, 0), (100, 100, 0), (100, 100, -12), (0, 100, -12)], dark(top, 0.2))
        i.quad([(100, 0, 0), (100, 100, 0), (100, 100, -12), (100, 0, -12)], dark(top, 0.35))
        if name == "road":
            i.quad([(0, 47, 0), (100, 47, 0), (100, 53, 0), (0, 53, 0)], P["white"], opacity=0.6)
        out.append(s.save("tiles/%s.svg" % name))
    return out


def build_character():
    return []
