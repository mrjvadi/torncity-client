"""The 3D backend of the place art: the Iso drawing API, building Blender meshes.

places.py describes each place with boxes, gable roofs, cylinders, domes,
face details, trees and props. iso.Iso draws those as SVG; Iso3D (a subclass,
so windows()/vehicle() and friends are shared) builds the same things as
geometry, grouped into one mesh per material. The renderer (render_places.py)
then lights and shoots them with an orthographic camera matched to the SVG
projection, so a rendered PNG drops into the same slot as the vector file.

World axes are the SVG's: x toward the lower right, y toward the lower left,
z up. Blender gets (y, x, z * Z_SCALE): swapping x and y turns the SVG's
left-handed screen convention into Blender's right-handed one, and Z_SCALE
makes a height read exactly as tall as in the 2:1 SVG projection under a
30-degree camera.
"""
import math

import bpy

from svgkit import P, light, dark, mix
from iso import Iso

Z_SCALE = 0.8165  # cos(45) / cos(30)


def srgb_to_linear(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hex_rgba(h, alpha=1.0):
    h = h.lstrip("#")
    return tuple(srgb_to_linear(int(h[i:i + 2], 16)) for i in (0, 2, 4)) + (alpha,)


class P2(tuple):
    """A projected 2D point that remembers the 3D point it came from."""

    def __new__(cls, xy, w):
        t = super().__new__(cls, xy)
        t.w = w
        return t


class NullSvg:
    """Swallows the 2D-only drawing calls places.py makes directly."""

    def __getattr__(self, name):
        return lambda *a, **k: ""


class RecoverSvg(NullSvg):
    """Rebuilds 2D polygons and lines drawn from projected points as 3D
    geometry; anything drawn from plain screen coordinates is dropped."""

    def __init__(self, iso):
        self.iso = iso

    def poly(self, points, fill, opacity=None, **kw):
        if points and all(hasattr(q, "w") for q in points):
            self.iso.face([q.w for q in points], fill, opacity=opacity or 1.0)

    def line(self, points, stroke, sw, opacity=None, **kw):
        pts = [q.w for q in points if hasattr(q, "w")]
        if len(pts) != len(points):
            return
        for a, b in zip(pts, pts[1:]):
            self.iso.rod(a, b, sw * 0.55, stroke)


class MeshBatch:
    def __init__(self):
        self.verts = []
        self.faces = []
        self.smooth = []

    def add(self, pts, smooth=False):
        base = len(self.verts)
        self.verts.extend(pts)
        self.faces.append(tuple(range(base, base + len(pts))))
        self.smooth.append(smooth)


class Iso3D(Iso):
    is3d = True

    def __init__(self):
        super().__init__(None, 0, 0, 1.0)
        self.svg = RecoverSvg(self)
        self.batches = {}  # (colour, kind, opacity) -> MeshBatch
        self.glass = False

    def p(self, x, y, z=0.0):
        return P2(Iso.p(self, x, y, z), (x, y, z))

    def rod(self, a, b, w, color):
        """A thin square bar from a to b (rails, poles, ribs)."""
        ax, ay, az = a
        bx, by, bz = b
        dx, dy, dz = bx - ax, by - ay, bz - az
        n = math.sqrt(dx * dx + dy * dy + dz * dz) or 1.0
        if abs(dz) > 0.7 * n:
            u, v = (w / 2, 0, 0), (0, w / 2, 0)
        else:
            hx, hy = -dy, dx
            hn = math.sqrt(hx * hx + hy * hy) or 1.0
            u, v = (hx / hn * w / 2, hy / hn * w / 2, 0), (0, 0, w / 2 / Z_SCALE)
        corners = [(-1, -1), (1, -1), (1, 1), (-1, 1)]

        def ring(p):
            return [(p[0] + i * u[0] + j * v[0], p[1] + i * u[1] + j * v[1], p[2] + i * u[2] + j * v[2]) for i, j in corners]

        ra, rb = ring(a), ring(b)
        for k in range(4):
            k2 = (k + 1) % 4
            self.face([ra[k], ra[k2], rb[k2], rb[k]], color, "metal" if color in (P["steel"], P["stone_dk"]) else "solid")

    # -- geometry sinks -------------------------------------------------------------------
    @staticmethod
    def B(x, y, z):
        return (y, x, z * Z_SCALE)

    def _batch(self, color, kind="solid", opacity=1.0):
        if not isinstance(color, str) or not color.startswith("#"):
            color = P["stone"]  # gradients from the 2D code: fall back to a neutral
        key = (color.upper(), kind, round(opacity, 2))
        if key not in self.batches:
            self.batches[key] = MeshBatch()
        return self.batches[key]

    def face(self, pts3, color, kind="solid", smooth=False, opacity=1.0):
        self._batch(color, kind, opacity).add([self.B(*q) for q in pts3], smooth)

    # -- the 2D API, in 3D --------------------------------------------------------------------
    def quad(self, pts3, fill, opacity=1.0, **kw):
        self.face(pts3, fill, opacity=opacity)

    def ground_poly(self, pts2, fill, z=0.0, **kw):
        self.face([(x, y, z) for x, y in pts2], fill)

    def shadow(self, *a, **k):
        pass  # real shadows

    def blob_shadow(self, *a, **k):
        pass

    def plot(self, top, rim=None, inset=5, inner=None, size=100):
        rim = rim or P["road"]
        s = size
        self.box(0, 0, -4, s, s, 4, rim, top=rim)
        i = inset
        self.face([(i, i, 0.05), (s - i, i, 0.05), (s - i, s - i, 0.05), (i, s - i, 0.05)], top)
        if inner:
            j = inset + inner[0]
            self.face([(j, j, 0.1), (s - j, j, 0.1), (s - j, s - j, 0.1), (j, s - j, 0.1)], inner[1])

    def box(self, x, y, z, w, d, h, c, top=None, left=None, right=None):
        # One colour for all sides: the light shades them now. An explicit
        # top colour (roof material) is honoured.
        X, Y, Z = x + w, y + d, z + h
        tc = top if top and top != light(c, 0.24) else c
        self.face([(x, Y, z), (X, Y, z), (X, Y, Z), (x, Y, Z)], c)          # front-left (y max)
        self.face([(X, y, z), (X, Y, z), (X, Y, Z), (X, y, Z)][::-1], c)    # front-right (x max)
        self.face([(x, y, z), (x, y, Z), (X, y, Z), (X, y, z)], c)          # back (y min)
        self.face([(x, y, z), (x, Y, z), (x, Y, Z), (x, y, Z)][::-1], c)    # back (x min)
        self.face([(x, y, Z), (x, Y, Z), (X, Y, Z), (X, y, Z)], tc)         # top
        return (x, y, z, w, d, h)

    def gable(self, x, y, z, w, d, h, c, ridge="x", overhang=2.0, end=None):
        o = overhang
        wall = end or dark(c, 0.30)
        if ridge == "x":
            ym = y + d / 2
            self.face([(x - o, y - o, z), (x + w + o, y - o, z), (x + w + o, ym, z + h), (x - o, ym, z + h)], c)
            self.face([(x - o, y + d + o, z), (x - o, ym, z + h), (x + w + o, ym, z + h), (x + w + o, y + d + o, z)], c)
            for xe in (x, x + w):
                self.face([(xe, y, z), (xe, y + d, z), (xe, ym, z + h)], mix(wall, P["sand"], 0.3))
        else:
            xm = x + w / 2
            self.face([(x - o, y - o, z), (x - o, y + d + o, z), (xm, y + d + o, z + h), (xm, y - o, z + h)], c)
            self.face([(x + w + o, y - o, z), (xm, y - o, z + h), (xm, y + d + o, z + h), (x + w + o, y + d + o, z)], c)
            for ye in (y, y + d):
                self.face([(x, ye, z), (x + w, ye, z), (xm, ye, z + h)], mix(wall, P["sand"], 0.3))

    def _ring(self, cx, cy, z, r, n):
        return [(cx + r * math.cos(2 * math.pi * k / n), cy + r * math.sin(2 * math.pi * k / n), z) for k in range(n)]

    def cylinder(self, cx, cy, z, r, h, c, top=None, segs=32, cap=True):
        lo = self._ring(cx, cy, z, r, segs)
        hi = self._ring(cx, cy, z + h, r, segs)
        for k in range(segs):
            k2 = (k + 1) % segs
            self.face([lo[k], lo[k2], hi[k2], hi[k]], c, smooth=True)
        if cap:
            self.face(hi, top or c)
        return (0, 0, 0, 0)

    def dome(self, cx, cy, z, r, c, height=None, finial=True):
        hh = height if height is not None else r * 1.15
        segs, rings = 32, 12
        rows = []
        for j in range(rings + 1):
            a = (math.pi / 2) * j / rings
            rows.append(self._ring(cx, cy, z + math.sin(a) * hh, r * math.cos(a) + 1e-3, segs))
        for j in range(rings):
            for k in range(segs):
                k2 = (k + 1) % segs
                self.face([rows[j][k], rows[j][k2], rows[j + 1][k2], rows[j + 1][k]], c, "glossy", smooth=True)
        if finial:
            self.cylinder(cx, cy, z + hh - 0.5, 0.5, 7, P["saffron_dk"], segs=8)
            self.sphere(cx, cy, z + hh + 7.5, 1.8, P["saffron"], kind="metal")

    def cone(self, cx, cy, z, r, h, c):
        segs = 32
        lo = self._ring(cx, cy, z, r, segs)
        tip = (cx, cy, z + h)
        for k in range(segs):
            self.face([lo[k], lo[(k + 1) % segs], tip], c, smooth=True)

    def sphere(self, cx, cy, cz, r, c, kind="solid", opacity=1.0, squash=1.0):
        segs, rings = 20, 10
        rows = []
        for j in range(rings + 1):
            a = math.pi * j / rings - math.pi / 2
            rows.append([(cx + r * math.cos(a) * math.cos(2 * math.pi * k / segs),
                          cy + r * math.cos(a) * math.sin(2 * math.pi * k / segs),
                          cz + r * squash * math.sin(a)) for k in range(segs)])
        for j in range(rings):
            for k in range(segs):
                k2 = (k + 1) % segs
                self.face([rows[j][k], rows[j][k2], rows[j + 1][k2], rows[j + 1][k]], c, kind, smooth=True, opacity=opacity)

    # -- face details: offset a little so they sit on the wall, glass is glossy ------------------
    def on_left(self, b, uv, fill, **kw):
        x, y, z, w, d, h = b
        kind = "glass" if self.glass else "solid"
        if self.glass and fill in (P["saffron"], dark(P["saffron"], 0.15)):
            kind = "lit"
        self.face([(x + u, y + d + 0.25, z + v) for u, v in uv], fill, kind)

    def on_right(self, b, uv, fill, **kw):
        x, y, z, w, d, h = b
        kind = "glass" if self.glass else "solid"
        if self.glass and fill in (P["saffron"], dark(P["saffron"], 0.15)):
            kind = "lit"
        self.face([(x + w + 0.25, y + u, z + v) for u, v in uv][::-1], fill, kind)

    def on_top(self, b, uv, fill, **kw):
        x, y, z, w, d, h = b
        self.face([(x + u, y + v, z + h + 0.2) for u, v in uv], fill)

    def windows(self, b, face, cols, rows, mu=4, mv=5, gap_u=3, gap_v=4, c=None, lit=None, arch=False, v0=None, v1=None):
        # a pale frame a little proud of the wall, then the glass inset
        x, y, z, w, d, h = b
        span = w if face == "left" else d
        lo = mv if v0 is None else v0
        hi = (h - mv) if v1 is None else v1
        ww = (span - 2 * mu - gap_u * (cols - 1)) / cols
        wh = (hi - lo - gap_v * (rows - 1)) / rows
        put = self.on_left if face == "left" else self.on_right
        for i in range(cols):
            for j in range(rows):
                u0 = mu + i * (ww + gap_u) - 0.7
                v_0 = lo + j * (wh + gap_v) - 0.7
                if not arch:
                    put(b, [(u0, v_0), (u0 + ww + 1.4, v_0), (u0 + ww + 1.4, v_0 + wh + 1.4), (u0, v_0 + wh + 1.4)], light(P["stone"], 0.4))
        self.glass = True
        # push the glass one step further out than the frame
        orig = (self.on_left, self.on_right)
        self.on_left = lambda bb, uv, fill, **kw: self.face([(bb[0] + u, bb[1] + bb[4] + 0.45, bb[2] + v) for u, v in uv], fill, "lit" if fill in (P["saffron"],) else "glass")
        self.on_right = lambda bb, uv, fill, **kw: self.face([(bb[0] + bb[3] + 0.45, bb[1] + u, bb[2] + v) for u, v in uv][::-1], fill, "lit" if fill in (dark(P["saffron"], 0.15),) else "glass")
        Iso.windows(self, b, face, cols, rows, mu, mv, gap_u, gap_v, c, lit, arch, v0, v1)
        self.on_left, self.on_right = orig
        del self.on_left, self.on_right
        self.glass = False

    # -- props ----------------------------------------------------------------------------------------
    def tree(self, x, y, size=1.0, c=None, kind="round"):
        c = c or P["leaf"]
        s = size
        self.cylinder(x, y, 0, 1.3 * s, 11 * s, P["earth_dk"], segs=10)
        if kind == "round":
            self.sphere(x, y, 18 * s, 8 * s, c, "foliage")
            self.sphere(x - 2.5 * s, y - 1.5 * s, 22 * s, 5.5 * s, light(c, 0.12), "foliage")
        else:
            for k, (r, h) in enumerate(((8, 11), (6.5, 10), (5, 9))):
                self.cone(x, y, (6 + k * 7) * s, r * s, h * s, c if k % 2 else dark(c, 0.1))

    def lamp(self, x, y, h=16):
        self.cylinder(x, y, 0, 0.6, h, P["slate"], segs=8)
        self.sphere(x, y, h + 1, 1.8, P["saffron"], "lit")

    def flag(self, x, y, z, h, c):
        self.cylinder(x, y, z, 0.5, h, P["stone_dk"], segs=8)
        self.face([(x, y, z + h - 1), (x + 10, y - 2, z + h - 2), (x + 10, y - 2, z + h - 8), (x, y, z + h - 7)], c)

    def vehicle(self, x, y, length, width, c, axis="x", h=7, cabin=True):
        b = Iso.vehicle(self, x, y, length, width, c, axis, h, cabin)
        for u in (length * 0.22, length * 0.78):
            if axis == "x":
                for yy in (y + 0.4, y + width - 0.4):
                    self._wheel(x + u, yy, "y")
            else:
                for xx in (x + 0.4, x + width - 0.4):
                    self._wheel(xx, y + u, "x")
        return b

    def _wheel(self, cx, cy, axis, r=2.2):
        segs = 14
        pts = []
        for k in range(segs):
            a = 2 * math.pi * k / segs
            if axis == "y":
                pts.append((cx + r * math.cos(a), cy, 2.2 + r * math.sin(a)))
            else:
                pts.append((cx, cy + r * math.cos(a), 2.2 + r * math.sin(a)))
        self.face(pts, P["ink"])

    def puff(self, x, y, z, r, c, opacity=1.0):
        self.sphere(x, y, z, r, c, "foliage" if c != P["white"] else "smoke", opacity)

    def disc(self, x, y, z, r, c):
        kind = "water" if c == P["water"] else "solid"
        self.face(self._ring(x, y, z, r, 40), c, kind)

    def plane_model(self, x, y, z):
        w = P["white"]
        self.cylinder_x(x - 16, x + 16, y, z + 4, 3.2, w)
        self.face([(x - 3, y - 20, z + 4), (x + 5, y - 20, z + 4), (x + 7, y, z + 4.5), (x - 5, y, z + 4.5)], P["stone"])
        self.face([(x - 5, y, z + 4.5), (x + 7, y, z + 4.5), (x + 5, y + 20, z + 4), (x - 3, y + 20, z + 4)], P["stone"])
        self.face([(x - 16, y, z + 6), (x - 10, y, z + 6), (x - 15, y, z + 15), (x - 18, y, z + 15)], P["turquoise"])
        self.face([(x - 17, y - 7, z + 5), (x - 12, y - 7, z + 5), (x - 11, y + 7, z + 5), (x - 16, y + 7, z + 5)], P["stone"])
        for yy in (-3.5, 3.5):
            self.cylinder(x + 12, y + yy, z, 0.5, 2.5, P["ink"], segs=6)
        self.cylinder(x - 8, y, z, 0.5, 2.5, P["ink"], segs=6)

    def cylinder_x(self, x0, x1, y, z, r, c, segs=20):
        ring = lambda xx: [(xx, y + r * math.cos(2 * math.pi * k / segs), z + r + r * math.sin(2 * math.pi * k / segs)) for k in range(segs)]
        a, b = ring(x0), ring(x1)
        for k in range(segs):
            k2 = (k + 1) % segs
            self.face([a[k], b[k], b[k2], a[k2]], c, "glossy", smooth=True)
        self.face(b[::-1], c)
        self.sphere(x0, y, z + r, r, c, "glossy", squash=1.0)
        # a row of cabin windows
        for k in range(8):
            xx = x0 + 4 + k * 3.2
            self.face([(xx, y + r + 0.05, z + r + 0.6), (xx + 1.6, y + r + 0.05, z + r + 0.6),
                       (xx + 1.6, y + r + 0.05, z + r + 1.8), (xx, y + r + 0.05, z + r + 1.8)], P["slate"], "glass")

    # -- turn batches into Blender objects ------------------------------------------------------------------
    def build(self, collection, materials):
        for (color, kind, opacity), mb in self.batches.items():
            mesh = bpy.data.meshes.new("m")
            mesh.from_pydata(mb.verts, [], mb.faces)
            mesh.update()
            for poly, sm in zip(mesh.polygons, mb.smooth):
                poly.use_smooth = sm
            mesh.materials.append(materials.get(color, kind, opacity))
            obj = bpy.data.objects.new("o", mesh)
            collection.objects.link(obj)
