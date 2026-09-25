"""Isometric (2:1 dimetric) drawing helpers for the city buildings.

World axes: x runs toward the lower right of the screen, y toward the lower
left, z straight up. One world unit is one pixel along a screen diagonal.
Light comes from the upper left, so for any box the top face is the lightest,
the face looking down-left (y = max) is the base colour, and the face looking
down-right (x = max) is the darkest.
"""
import math

from svgkit import P, light, dark, mix, convex_hull


class Iso:
    def __init__(self, svg, ox, oy, k=1.0):
        self.svg, self.ox, self.oy, self.k = svg, ox, oy, k

    def p(self, x, y, z=0.0):
        return (self.ox + (x - y) * self.k, self.oy + (x + y) * 0.5 * self.k - z * self.k)

    def quad(self, pts3, fill, **kw):
        self.svg.poly([self.p(*q) for q in pts3], fill, **kw)

    # -- ground ------------------------------------------------------------------
    def plot(self, top, rim=None, inset=5, inner=None, size=100):
        """The lot a building stands on: a light kerb rim and an inner surface."""
        rim = rim or P["road"]
        s = size
        self.quad([(0, 0, 0), (s, 0, 0), (s, s, 0), (0, s, 0)], rim)
        # The kerb's lit edge along the two front sides reads as thickness.
        self.quad([(0, s, 0), (s, s, 0), (s, s, -3), (0, s, -3)], dark(rim, 0.12))
        self.quad([(s, 0, 0), (s, s, 0), (s, s, -3), (s, 0, -3)], dark(rim, 0.25))
        i = inset
        self.quad([(i, i, 0), (s - i, i, 0), (s - i, s - i, 0), (i, s - i, 0)], top)
        if inner:
            j = inset + inner[0]
            self.quad([(j, j, 0), (s - j, j, 0), (s - j, s - j, 0), (j, s - j, 0)], inner[1])

    def ground_poly(self, pts2, fill, z=0.0, **kw):
        self.svg.poly([self.p(x, y, z) for x, y in pts2], fill, **kw)

    def shadow(self, x, y, w, d, h, strength=0.20, reach=0.55):
        """A soft cast shadow falling to the lower right (world +x)."""
        L = h * reach
        foot = [(x, y), (x + w, y), (x + w, y + d), (x, y + d)]
        moved = [(a + L, b - L * 0.25) for a, b in foot]
        hull = convex_hull([self.p(a, b, 0) for a, b in foot + moved])
        self.svg.poly(hull, P["ink"], opacity=strength)

    def blob_shadow(self, x, y, r, strength=0.18):
        cx, cy = self.p(x + r * 0.35, y - r * 0.1, 0)
        self.svg.ellipse(cx, cy, r * 1.25 * self.k, r * 0.62 * self.k, P["ink"], opacity=strength)

    # -- solids --------------------------------------------------------------------
    def box(self, x, y, z, w, d, h, c, top=None, left=None, right=None):
        left = left or c
        right = right or dark(c, 0.24)
        top = top or light(c, 0.24)
        self.quad([(x, y + d, z), (x + w, y + d, z), (x + w, y + d, z + h), (x, y + d, z + h)], left)
        self.quad([(x + w, y, z), (x + w, y + d, z), (x + w, y + d, z + h), (x + w, y, z + h)], right)
        self.quad([(x, y, z + h), (x + w, y, z + h), (x + w, y + d, z + h), (x, y + d, z + h)], top)
        return (x, y, z, w, d, h)

    def gable(self, x, y, z, w, d, h, c, ridge="x", overhang=2.0, end=None):
        """A pitched roof. ridge='x' runs the ridge along x (slopes face ±y)."""
        o = overhang
        top_back = light(c, 0.10)
        front = c
        end = end or dark(c, 0.30)
        if ridge == "x":
            ym = y + d / 2
            self.quad([(x - o, y - o, z), (x + w + o, y - o, z), (x + w + o, ym, z + h), (x - o, ym, z + h)], top_back)
            self.quad([(x - o, y + d + o, z), (x + w + o, y + d + o, z), (x + w + o, ym, z + h), (x - o, ym, z + h)], front)
            self.svg.poly([self.p(x + w, y, z), self.p(x + w, y + d, z), self.p(x + w, ym, z + h)], end)
            # ridge highlight
            self.svg.line([self.p(x - o, ym, z + h), self.p(x + w + o, ym, z + h)], light(c, 0.35), 1.6 * self.k)
        else:
            xm = x + w / 2
            self.quad([(x - o, y - o, z), (x - o, y + d + o, z), (xm, y + d + o, z + h), (xm, y - o, z + h)], top_back)
            self.svg.poly([self.p(x, y + d, z), self.p(x + w, y + d, z), self.p(xm, y + d, z + h)], mix(end, c, 0.45))
            self.quad([(x + w + o, y - o, z), (x + w + o, y + d + o, z), (xm, y + d + o, z + h), (xm, y - o, z + h)], dark(c, 0.18))
            self.svg.line([self.p(xm, y - o, z + h), self.p(xm, y + d + o, z + h)], light(c, 0.35), 1.6 * self.k)

    def cylinder(self, cx, cy, z, r, h, c, top=None, segs=24, cap=True):
        rx, ry = r * math.sqrt(2) * self.k, r * math.sqrt(2) * 0.5 * self.k
        bx, by = self.p(cx, cy, z)
        tx, ty = self.p(cx, cy, z + h)
        body = self.svg.lin([(0, light(c, 0.12)), (0.45, c), (1, dark(c, 0.32))], 0, 0, 1, 0)
        d = "M%.2f %.2f L%.2f %.2f A%.2f %.2f 0 0 0 %.2f %.2f L%.2f %.2f A%.2f %.2f 0 0 1 %.2f %.2f Z" % (
            bx - rx, by, tx - rx, ty, rx, ry, tx + rx, ty, bx + rx, by, rx, ry, bx - rx, by)
        self.svg.path(d, body)
        if cap:
            self.svg.ellipse(tx, ty, rx, ry, top or light(c, 0.28))
        return (tx, ty, rx, ry)

    def dome(self, cx, cy, z, r, c, height=None, finial=True):
        rx = r * math.sqrt(2) * self.k
        ry = rx * 0.5
        hh = (height if height is not None else r * 1.15) * self.k
        bx, by = self.p(cx, cy, z)
        fill = self.svg.lin([(0, light(c, 0.35)), (0.5, c), (1, dark(c, 0.30))], 0, 0, 1, 0.3)
        d = "M%.2f %.2f A%.2f %.2f 0 0 1 %.2f %.2f A%.2f %.2f 0 0 1 %.2f %.2f Z" % (
            bx - rx, by, rx, hh, bx + rx, by, rx, ry, bx - rx, by)
        self.svg.path(d, fill)
        # a crescent highlight on the lit side
        self.svg.ellipse(bx - rx * 0.38, by - hh * 0.55, rx * 0.16, hh * 0.28, "#FFFFFF", opacity=0.35)
        if finial:
            self.svg.line([(bx, by - hh), (bx, by - hh - 7 * self.k)], dark(P["saffron"], 0.1), 1.8 * self.k)
            self.svg.circle(bx, by - hh - 7.5 * self.k, 2.0 * self.k, P["saffron"])

    def cone(self, cx, cy, z, r, h, c):
        rx, ry = r * math.sqrt(2) * self.k, r * math.sqrt(2) * 0.5 * self.k
        bx, by = self.p(cx, cy, z)
        tx, ty = self.p(cx, cy, z + h)
        self.svg.path("M%.2f %.2f L%.2f %.2f L%.2f %.2f A%.2f %.2f 0 0 1 %.2f %.2f Z" % (
            bx - rx, by, tx, ty, bx + rx, by, rx, ry, bx - rx, by),
            self.svg.lin([(0, light(c, 0.2)), (0.5, c), (1, dark(c, 0.3))], 0, 0, 1, 0))

    # -- face details ------------------------------------------------------------------
    def on_left(self, b, uv, fill, **kw):
        """Polygon on the down-left face (y = max) of box b, in (u along x, v up)."""
        x, y, z, w, d, h = b
        self.svg.poly([self.p(x + u, y + d + 0.01, z + v) for u, v in uv], fill, **kw)

    def on_right(self, b, uv, fill, **kw):
        """Polygon on the down-right face (x = max) of box b, in (u along y, v up)."""
        x, y, z, w, d, h = b
        self.svg.poly([self.p(x + w + 0.01, y + u, z + v) for u, v in uv], fill, **kw)

    def on_top(self, b, uv, fill, **kw):
        x, y, z, w, d, h = b
        self.svg.poly([self.p(x + u, y + v, z + h + 0.01) for u, v in uv], fill, **kw)

    def windows(self, b, face, cols, rows, mu=4, mv=5, gap_u=3, gap_v=4, c=None, lit=None,
                arch=False, v0=None, v1=None):
        """A regular grid of windows on one face. lit: set of (col,row) glowing warm."""
        x, y, z, w, d, h = b
        span = w if face == "left" else d
        lo = mv if v0 is None else v0
        hi = (h - mv) if v1 is None else v1
        ww = (span - 2 * mu - gap_u * (cols - 1)) / cols
        wh = (hi - lo - gap_v * (rows - 1)) / rows
        base = c or (light(P["sky"], 0.25) if face == "left" else mix(P["sky"], P["slate"], 0.35))
        glow = P["saffron"] if face == "left" else dark(P["saffron"], 0.15)
        put = self.on_left if face == "left" else self.on_right
        for i in range(cols):
            for j in range(rows):
                u0 = mu + i * (ww + gap_u)
                v_0 = lo + j * (wh + gap_v)
                fill = glow if lit and (i, j) in lit else base
                if arch:
                    pts_ = [(u0, v_0), (u0 + ww, v_0), (u0 + ww, v_0 + wh - ww / 2)]
                    for k in range(1, 8):
                        a = math.pi * k / 8
                        pts_.append((u0 + ww / 2 + math.cos(a) * ww / 2, v_0 + wh - ww / 2 + math.sin(a) * ww / 2))
                    pts_.append((u0, v_0 + wh - ww / 2))
                    put(b, pts_, fill)
                else:
                    put(b, [(u0, v_0), (u0 + ww, v_0), (u0 + ww, v_0 + wh), (u0, v_0 + wh)], fill)

    # -- props -----------------------------------------------------------------------------
    def tree(self, x, y, size=1.0, c=None, kind="round"):
        c = c or P["leaf"]
        s = size
        self.blob_shadow(x, y, 7 * s)
        tx, ty = self.p(x, y, 0)
        self.svg.rect(tx - 1.6 * s * self.k, ty - 10 * s * self.k, 3.2 * s * self.k, 10 * s * self.k, P["earth_dk"], rx=1)
        if kind == "round":
            cx, cy = tx, ty - 17 * s * self.k
            r = 9 * s * self.k
            self.svg.circle(cx, cy, r, dark(c, 0.12))
            self.svg.circle(cx - r * 0.18, cy - r * 0.2, r * 0.8, c)
            self.svg.circle(cx - r * 0.42, cy - r * 0.42, r * 0.32, light(c, 0.3))
        else:
            for i, (w_, hgt) in enumerate(((10, 12), (8, 11), (6, 10))):
                by = ty - (7 + i * 7) * s * self.k
                self.svg.poly([(tx - w_ * s * self.k, by), (tx + w_ * s * self.k, by), (tx, by - hgt * s * self.k)],
                              dark(c, 0.15) if i % 2 == 0 else c)
            self.svg.poly([(tx, ty - 31 * s * self.k), (tx - 3 * s * self.k, ty - 24 * s * self.k),
                           (tx, ty - 25 * s * self.k)], light(c, 0.3))

    def lamp(self, x, y, h=16):
        bx, by = self.p(x, y, 0)
        self.svg.line([(bx, by), (bx, by - h * self.k)], P["slate"], 1.4 * self.k)
        self.svg.circle(bx, by - h * self.k, 2.2 * self.k, P["saffron"])

    def flag(self, x, y, z, h, c):
        bx, by = self.p(x, y, z)
        tx, ty = bx, by - h * self.k
        self.svg.line([(bx, by), (tx, ty)], P["stone_dk"], 1.4 * self.k)
        self.svg.path("M%.2f %.2f q6 -3 12 1 q-1 5 1 9 q-6 -3 -13 0 Z" % (tx, ty), c)
        self.svg.path("M%.2f %.2f q6 -3 12 1 l0 3 q-6 -3 -12 -1 Z" % (tx, ty), light(c, 0.3))

    def vehicle(self, x, y, length, width, c, axis="x", h=7, cabin=True):
        """A small car/van/bus-shaped block with dark windows and wheels."""
        if axis == "x":
            b = self.box(x, y, 1.5, length, width, h, c)
            self.on_left(b, [(length * 0.15, h * 0.55), (length * 0.85, h * 0.55), (length * 0.85, h * 0.92),
                             (length * 0.15, h * 0.92)], P["slate"])
            for u in (length * 0.22, length * 0.78):
                wx, wy = self.p(x + u, y + width, 1.8)
                self.svg.ellipse(wx, wy, 2.4 * self.k, 2.4 * self.k, P["ink"])
        else:
            b = self.box(x, y, 1.5, width, length, h, c)
            self.on_right(b, [(length * 0.15, h * 0.55), (length * 0.85, h * 0.55), (length * 0.85, h * 0.92),
                              (length * 0.15, h * 0.92)], P["slate"])
            for u in (length * 0.22, length * 0.78):
                wx, wy = self.p(x + width, y + u, 1.8)
                self.svg.ellipse(wx, wy, 2.4 * self.k, 2.4 * self.k, P["ink"])
        return b
