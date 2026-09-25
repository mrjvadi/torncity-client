"""Tiny SVG toolkit shared by the art generator.

Everything is plain SVG 1.1 that Godot's importer (ThorVG) renders: paths,
polygons, circles, ellipses, rects and linear/radial gradients. No text, no
filters, no masks — they either do not import or do not survive a rescale.
"""
import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "assets", "art")

with open(os.path.join(ART, "palette.json"), encoding="utf-8") as fh:
    P = json.load(fh)["colors"]


def _rgb(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))


def _hex(rgb):
    return "#%02X%02X%02X" % tuple(max(0, min(255, int(round(v)))) for v in rgb)


def mix(a, b, t):
    """Blend colour a toward colour b by t (0..1)."""
    ra, rb = _rgb(a), _rgb(b)
    return _hex([ra[i] + (rb[i] - ra[i]) * t for i in range(3)])


def light(c, t=0.22):
    return mix(c, "#FFFFFF", t)


def dark(c, t=0.22):
    # Shadows lean toward the ink colour, not black, so they stay colourful.
    return mix(c, P["ink"], t)


def f(v):
    return ("%.2f" % v).rstrip("0").rstrip(".")


def pts(points):
    return " ".join("%s,%s" % (f(x), f(y)) for x, y in points)


class Svg:
    def __init__(self, w, h, vb=None):
        self.w, self.h = w, h
        self.vb = vb or (0, 0, w, h)
        self.defs = []
        self.els = []
        self._gid = 0
        self.clip_circle = None  # (cx, cy, r): clip everything to a disc

    # -- raw ---------------------------------------------------------------
    def add(self, s):
        self.els.append(s)

    @staticmethod
    def _style(fill, opacity=None, stroke=None, sw=None, cap="round", join="round"):
        s = ' fill="%s"' % (fill or "none")
        if opacity is not None and opacity < 1:
            s += ' opacity="%s"' % f(opacity)
        if stroke:
            s += ' stroke="%s" stroke-width="%s" stroke-linecap="%s" stroke-linejoin="%s"' % (
                stroke, f(sw or 1), cap, join)
        return s

    # -- shapes --------------------------------------------------------------
    def poly(self, points, fill, **kw):
        self.add('<polygon points="%s"%s/>' % (pts(points), self._style(fill, **kw)))

    def line(self, points, stroke, sw, opacity=None, cap="round"):
        self.add('<polyline points="%s"%s/>' % (
            pts(points), self._style(None, opacity=opacity, stroke=stroke, sw=sw, cap=cap)))

    def path(self, d, fill, **kw):
        self.add('<path d="%s"%s/>' % (d, self._style(fill, **kw)))

    def circle(self, cx, cy, r, fill, **kw):
        self.add('<circle cx="%s" cy="%s" r="%s"%s/>' % (f(cx), f(cy), f(r), self._style(fill, **kw)))

    def ellipse(self, cx, cy, rx, ry, fill, **kw):
        self.add('<ellipse cx="%s" cy="%s" rx="%s" ry="%s"%s/>' % (
            f(cx), f(cy), f(rx), f(ry), self._style(fill, **kw)))

    def rect(self, x, y, w, h, fill, rx=0, **kw):
        self.add('<rect x="%s" y="%s" width="%s" height="%s" rx="%s"%s/>' % (
            f(x), f(y), f(w), f(h), f(rx), self._style(fill, **kw)))

    # -- gradients -------------------------------------------------------------
    def lin(self, stops, x1=0, y1=0, x2=0, y2=1):
        self._gid += 1
        gid = "g%d" % self._gid
        st = "".join('<stop offset="%s" stop-color="%s"%s/>' % (
            f(o), c, (' stop-opacity="%s"' % f(a)) if a is not None else "")
            for o, c, a in [(s + (None,))[:3] for s in stops])
        self.defs.append('<linearGradient id="%s" x1="%s" y1="%s" x2="%s" y2="%s">%s</linearGradient>' % (
            gid, f(x1), f(y1), f(x2), f(y2), st))
        return "url(#%s)" % gid

    def rad(self, stops, cx=0.5, cy=0.5, r=0.5):
        self._gid += 1
        gid = "g%d" % self._gid
        st = "".join('<stop offset="%s" stop-color="%s"%s/>' % (
            f(o), c, (' stop-opacity="%s"' % f(a)) if a is not None else "")
            for o, c, a in [(s + (None,))[:3] for s in stops])
        self.defs.append('<radialGradient id="%s" cx="%s" cy="%s" r="%s">%s</radialGradient>' % (
            gid, f(cx), f(cy), f(r), st))
        return "url(#%s)" % gid

    # -- output ----------------------------------------------------------------
    def text(self):
        vb = " ".join(f(v) for v in self.vb)
        out = ['<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="%s">' % (
            f(self.w), f(self.h), vb)]
        defs = list(self.defs)
        if self.clip_circle:
            cx, cy, r = self.clip_circle
            defs.append('<clipPath id="disc"><circle cx="%s" cy="%s" r="%s"/></clipPath>' % (f(cx), f(cy), f(r)))
        if defs:
            out.append("<defs>%s</defs>" % "".join(defs))
        if self.clip_circle:
            out.append('<g clip-path="url(#disc)">')
        out.extend(self.els)
        if self.clip_circle:
            out.append("</g>")
        out.append("</svg>")
        return "\n".join(out) + "\n"

    def save(self, rel):
        path = os.path.join(ART, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(self.text())
        return rel


def star_points(cx, cy, r_out, r_in, n=5, rot=-90):
    out = []
    for i in range(n * 2):
        r = r_out if i % 2 == 0 else r_in
        a = math.radians(rot + i * 180.0 / n)
        out.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return out


def rrect_path(x, y, w, h, r):
    r = min(r, w / 2, h / 2)
    return ("M%s %sh%sa%s %s 0 0 1 %s %sv%sa%s %s 0 0 1 -%s %sh-%sa%s %s 0 0 1 -%s -%sv-%sa%s %s 0 0 1 %s -%sz" % (
        f(x + r), f(y), f(w - 2 * r), f(r), f(r), f(r), f(r), f(h - 2 * r), f(r), f(r), f(r), f(r),
        f(w - 2 * r), f(r), f(r), f(r), f(r), f(h - 2 * r), f(r), f(r), f(r), f(r)))


def convex_hull(points):
    pts_ = sorted(set((round(x, 3), round(y, 3)) for x, y in points))
    if len(pts_) <= 2:
        return pts_

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower, upper = [], []
    for p in pts_:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts_):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]
