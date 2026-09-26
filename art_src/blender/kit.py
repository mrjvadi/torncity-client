"""Asset kit for the Blender renders: materials, geometry builders, lighting
and cameras. Every render script (buildings, vehicles, items, tiles, props,
characters, backgrounds) builds with these so the whole game shares one light,
one camera angle and one material library.

Units: 1 unit = 10 cm. A city lot is 100 x 100 (10 m). Blender axes; the
camera looks from +x +y (so faces at x-max and y-max face the viewer), 30
degrees down, orthographic.
"""
import json
import math
import os
import random

import bmesh
import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
with open(os.path.join(ROOT, "assets", "art", "palette.json"), encoding="utf-8") as fh:
    PAL = json.load(fh)["colors"]

CAM_ELEV = math.radians(30.0)
CAM_AZIM = math.radians(45.0)


def rgb(h):
    """sRGB hex -> linear RGBA."""
    if not h.startswith("#"):
        h = PAL[h]
    h = h.lstrip("#")

    def lin(c):
        c /= 255.0
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (lin(int(h[0:2], 16)), lin(int(h[2:4], 16)), lin(int(h[4:6], 16)), 1.0)


# -- scene -----------------------------------------------------------------------------------------
def reset(samples=40):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.cycles.max_bounces = 6
    sc.cycles.transparent_max_bounces = 8
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.image_settings.compression = 90
    sc.view_settings.view_transform = "AgX"
    try:
        sc.view_settings.look = "AgX - Medium High Contrast"
    except TypeError:
        pass
    sc.view_settings.exposure = 0.15
    _world(sc)
    _lights(sc)
    return sc


def _world(sc, strength=0.45):
    w = bpy.data.worlds.new("sky")
    w.use_nodes = True
    nt = w.node_tree
    bg = nt.nodes["Background"]
    sky = nt.nodes.new("ShaderNodeTexSky")
    try:
        sky.sky_type = "HOSEK_WILKIE"
        sky.turbidity = 3.0
    except Exception:
        pass
    sky.sun_direction = Vector((0.55, -0.35, 0.76)).normalized()
    nt.links.new(sky.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = strength
    sc.world = w


def _sun(sc, name, direction, energy, color, angle):
    l = bpy.data.lights.new(name, "SUN")
    l.energy = energy
    l.color = color
    l.angle = math.radians(angle)
    o = bpy.data.objects.new(name, l)
    o.rotation_euler = Vector(direction).normalized().to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(o)
    return o


def _lights(sc):
    # key: warm, from the upper left of the screen, soft-edged shadows
    _sun(sc, "key", (-0.55, 0.35, -0.76), 4.2, (1.0, 0.93, 0.82), 4)
    # rim: cool, from behind, outlines silhouettes against the dark UI
    _sun(sc, "rim", (0.45, 0.75, -0.35), 2.0, (0.62, 0.78, 1.0), 8)
    # fill: faint, from the camera side
    _sun(sc, "fill", (-0.3, -0.8, -0.5), 0.5, (0.8, 0.86, 1.0), 25)


def view_dir(elev=CAM_ELEV, azim=CAM_AZIM):
    """Direction the camera looks (from +x +y toward the origin)."""
    return Vector((-math.cos(elev) * math.cos(azim), -math.cos(elev) * math.sin(azim), -math.sin(elev)))


def camera(sc, res_x, res_y, ortho_scale, target=(0, 0, 0), elev=CAM_ELEV, azim=CAM_AZIM):
    cam = bpy.data.cameras.new("cam")
    cam.type = "ORTHO"
    cam.ortho_scale = ortho_scale
    cam.clip_end = 5000
    o = bpy.data.objects.new("cam", cam)
    f = view_dir(elev, azim)
    o.location = Vector(target) - f * 1500
    o.rotation_euler = f.to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(o)
    sc.camera = o
    sc.render.resolution_x = res_x
    sc.render.resolution_y = res_y
    return o


def lot_camera(sc, px_per_art=2, art_w=256, art_h=352, origin=(128, 214)):
    """The city-lot camera: 1 art px = 1 world unit along a lot diagonal, the
    lot's (0,0,0) corner at `origin` of the art canvas — the SVG contract."""
    ortho = max(art_w, art_h) * math.cos(math.radians(45))
    f = view_dir()
    right = f.cross(Vector((0, 0, 1))).normalized()
    up = right.cross(f).normalized()
    px = math.cos(math.radians(45))
    target = up * ((origin[1] - art_h / 2) * px) - right * ((origin[0] - art_w / 2) * px)
    return camera(sc, art_w * px_per_art, art_h * px_per_art, ortho, target)


def frame_objects(sc, res_x, res_y, margin=0.08, elev=CAM_ELEV, azim=CAM_AZIM, objs=None):
    """A camera that fits every mesh in the scene (items, vehicles, props)."""
    f = view_dir(elev, azim)
    right = f.cross(Vector((0, 0, 1))).normalized()
    up = right.cross(f).normalized()
    pts = []
    for o in (objs or sc.objects):
        if o.type != "MESH":
            continue
        for c in o.bound_box:
            pts.append(o.matrix_world @ Vector(c))
    xs = [p.dot(right) for p in pts]
    ys = [p.dot(up) for p in pts]
    w, h = max(xs) - min(xs), max(ys) - min(ys)
    cx, cy = (max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2
    aspect = res_x / res_y
    scale = max(w, h * aspect) * (1 + 2 * margin)
    if res_y > res_x:
        scale = max(w / aspect, h) * (1 + 2 * margin)
    target = right * cx + up * cy
    return camera(sc, res_x, res_y, scale, target, elev, azim)


def render(sc, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def clear_cameras():
    for o in list(bpy.data.objects):
        if o.type == "CAMERA":
            bpy.data.objects.remove(o, do_unlink=True)


def clear_meshes():
    for o in list(bpy.data.objects):
        if o.type in ("MESH", "CURVE", "EMPTY", "FONT"):
            bpy.data.objects.remove(o, do_unlink=True)
    for m in list(bpy.data.meshes):
        if m.users == 0:
            bpy.data.meshes.remove(m)


# -- materials ---------------------------------------------------------------------------------------
_MATS = {}


def _principled(name):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    return m, nt, nt.nodes["Principled BSDF"]


def _noise(nt, scale, detail=6.0):
    tc = nt.nodes.new("ShaderNodeTexCoord")
    n = nt.nodes.new("ShaderNodeTexNoise")
    n.inputs["Scale"].default_value = scale
    n.inputs["Detail"].default_value = detail
    nt.links.new(tc.outputs["Object"], n.inputs["Vector"])
    return n


def _bump(nt, bsdf, height_socket, strength=0.2, distance=0.5):
    b = nt.nodes.new("ShaderNodeBump")
    b.inputs["Strength"].default_value = strength
    b.inputs["Distance"].default_value = distance
    nt.links.new(height_socket, b.inputs["Height"])
    nt.links.new(b.outputs["Normal"], bsdf.inputs["Normal"])


def _vary(nt, bsdf, color, noise, amount=0.12):
    """Base colour with a little noise variation (dirt, weathering)."""
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    c = rgb(color)
    ramp.color_ramp.elements[0].color = tuple(v * (1 - amount) for v in c[:3]) + (1,)
    ramp.color_ramp.elements[1].color = tuple(min(1, v * (1 + amount)) for v in c[:3]) + (1,)
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])


def mat(kind, color="#888888", **kw):
    key = (kind, color, tuple(sorted(kw.items())))
    if key in _MATS:
        return _MATS[key]
    m, nt, b = _principled("%s_%s" % (kind, color))
    b.inputs["Base Color"].default_value = rgb(color)
    if "Specular IOR Level" in b.inputs:
        b.inputs["Specular IOR Level"].default_value = 0.4
    if kind == "paint":            # painted walls, plastic
        b.inputs["Roughness"].default_value = kw.get("rough", 0.55)
        n = _noise(nt, 0.35)
        _vary(nt, b, color, n, 0.06)
    elif kind == "concrete":
        b.inputs["Roughness"].default_value = 0.85
        n = _noise(nt, 0.9, 8)
        _vary(nt, b, color, n, 0.14)
        _bump(nt, b, n.outputs["Fac"], 0.15, 0.3)
    elif kind == "brick":
        bt = nt.nodes.new("ShaderNodeTexBrick")
        tc = nt.nodes.new("ShaderNodeTexCoord")
        nt.links.new(tc.outputs["Object"], bt.inputs["Vector"])
        bt.inputs["Scale"].default_value = kw.get("scale", 0.35)
        bt.inputs["Mortar Size"].default_value = 0.015
        c = rgb(color)
        bt.inputs["Color1"].default_value = c
        bt.inputs["Color2"].default_value = tuple(v * 0.8 for v in c[:3]) + (1,)
        bt.inputs["Mortar"].default_value = (0.55, 0.52, 0.48, 1)
        nt.links.new(bt.outputs["Color"], b.inputs["Base Color"])
        _bump(nt, b, bt.outputs["Fac"], 0.25, 0.2)
        b.inputs["Roughness"].default_value = 0.8
    elif kind == "glass":
        b.inputs["Base Color"].default_value = rgb(color)
        b.inputs["Roughness"].default_value = 0.04
        b.inputs["Metallic"].default_value = 0.35
        if "Specular IOR Level" in b.inputs:
            b.inputs["Specular IOR Level"].default_value = 1.0
        if "Coat Weight" in b.inputs:
            b.inputs["Coat Weight"].default_value = 0.6
    elif kind == "metal":
        b.inputs["Metallic"].default_value = 0.9
        b.inputs["Roughness"].default_value = kw.get("rough", 0.32)
    elif kind == "carpaint":
        b.inputs["Metallic"].default_value = 0.4
        b.inputs["Roughness"].default_value = 0.25
        if "Coat Weight" in b.inputs:
            b.inputs["Coat Weight"].default_value = 1.0
            b.inputs["Coat Roughness"].default_value = 0.05
    elif kind == "rubber":
        b.inputs["Roughness"].default_value = 0.9
    elif kind == "asphalt":
        b.inputs["Roughness"].default_value = 0.9
        n = _noise(nt, 3.0, 10)
        _vary(nt, b, color, n, 0.18)
        _bump(nt, b, n.outputs["Fac"], 0.3, 0.2)
    elif kind == "grass":
        b.inputs["Roughness"].default_value = 0.95
        n = _noise(nt, 0.6, 8)
        _vary(nt, b, color, n, 0.22)
        _bump(nt, b, n.outputs["Fac"], 0.5, 0.6)
    elif kind == "soil":
        b.inputs["Roughness"].default_value = 1.0
        n = _noise(nt, 1.2, 12)
        _vary(nt, b, color, n, 0.25)
        _bump(nt, b, n.outputs["Fac"], 0.6, 0.8)
    elif kind == "water":
        b.inputs["Roughness"].default_value = 0.03
        b.inputs["Metallic"].default_value = 0.1
        if "Transmission Weight" in b.inputs:
            b.inputs["Transmission Weight"].default_value = 0.3
        n = _noise(nt, 0.4, 4)
        _bump(nt, b, n.outputs["Fac"], 0.25, 0.5)
    elif kind == "emit":
        b.inputs["Emission Color"].default_value = rgb(color)
        b.inputs["Emission Strength"].default_value = kw.get("strength", 3.0)
    elif kind == "skin":
        b.inputs["Roughness"].default_value = 0.5
        if "Subsurface Weight" in b.inputs:
            b.inputs["Subsurface Weight"].default_value = 0.15
            b.inputs["Subsurface Radius"].default_value = (1.0, 0.4, 0.25)
    elif kind == "cloth":
        b.inputs["Roughness"].default_value = 0.9
        if "Sheen Weight" in b.inputs:
            b.inputs["Sheen Weight"].default_value = 0.4
        n = _noise(nt, 4.0, 4)
        _vary(nt, b, color, n, 0.08)
    elif kind == "leather":
        b.inputs["Roughness"].default_value = 0.45
        n = _noise(nt, 6.0, 6)
        _vary(nt, b, color, n, 0.1)
        _bump(nt, b, n.outputs["Fac"], 0.2, 0.1)
    elif kind == "foliage":
        b.inputs["Roughness"].default_value = 0.7
        n = _noise(nt, 0.25, 6)
        _vary(nt, b, color, n, 0.3)
        _bump(nt, b, n.outputs["Fac"], 0.8, 1.5)
        if "Subsurface Weight" in b.inputs:
            b.inputs["Subsurface Weight"].default_value = 0.1
    elif kind == "roof":
        b.inputs["Roughness"].default_value = 0.9
        n = _noise(nt, 2.0, 10)
        _vary(nt, b, color, n, 0.15)
        _bump(nt, b, n.outputs["Fac"], 0.3, 0.2)
    elif kind == "tile":           # roof tiles / cladding: stripes
        w = nt.nodes.new("ShaderNodeTexWave")
        tc = nt.nodes.new("ShaderNodeTexCoord")
        nt.links.new(tc.outputs["Object"], w.inputs["Vector"])
        w.inputs["Scale"].default_value = kw.get("scale", 0.25)
        _bump(nt, b, w.outputs["Fac"], 0.35, 0.3)
        b.inputs["Roughness"].default_value = 0.6
    _MATS[key] = m
    return m


# -- geometry ----------------------------------------------------------------------------------------
class Part:
    """Accumulates primitives of one material into one mesh object."""

    def __init__(self, material, bevel=0.0, smooth=False, name="part"):
        self.bm = bmesh.new()
        self.material = material
        self.bevel = bevel
        self.smooth = smooth
        self.name = name

    def _add(self, geom_fn):
        tmp = bmesh.new()
        geom_fn(tmp)
        me = bpy.data.meshes.new("tmp")
        tmp.to_mesh(me)
        tmp.free()
        self.bm.from_mesh(me)
        bpy.data.meshes.remove(me)

    def box(self, x, y, z, w, d, h):
        def g(b):
            bmesh.ops.create_cube(b, size=1.0)
            bmesh.ops.scale(b, vec=(w, d, h), verts=b.verts)
            bmesh.ops.translate(b, vec=(x + w / 2, y + d / 2, z + h / 2), verts=b.verts)
        self._add(g)
        return self

    def cyl(self, x, y, z, r, h, segs=24, r2=None, cap=True):
        def g(b):
            bmesh.ops.create_cone(b, cap_ends=cap, cap_tris=False, segments=segs, radius1=r,
                                  radius2=r if r2 is None else r2, depth=h)
            bmesh.ops.translate(b, vec=(x, y, z + h / 2), verts=b.verts)
        self._add(g)
        return self

    def cyl_axis(self, a, b_, r, segs=16):
        """A cylinder between two points."""
        a, b_ = Vector(a), Vector(b_)
        d = b_ - a
        L = d.length

        def g(b):
            bmesh.ops.create_cone(b, cap_ends=True, cap_tris=False, segments=segs, radius1=r, radius2=r, depth=L)
            rot = d.normalized().to_track_quat("Z", "Y").to_matrix().to_4x4()
            bmesh.ops.transform(b, matrix=Matrix.Translation((a + b_) / 2) @ rot, verts=b.verts)
        self._add(g)
        return self

    def sphere(self, x, y, z, r, sx=1.0, sy=1.0, sz=1.0, segs=24, rings=12):
        def g(b):
            bmesh.ops.create_uvsphere(b, u_segments=segs, v_segments=rings, radius=r)
            bmesh.ops.scale(b, vec=(sx, sy, sz), verts=b.verts)
            bmesh.ops.translate(b, vec=(x, y, z), verts=b.verts)
        self._add(g)
        return self

    def dome(self, x, y, z, r, h=None, segs=32):
        h = r if h is None else h

        def g(b):
            bmesh.ops.create_uvsphere(b, u_segments=segs, v_segments=16, radius=1.0)
            bmesh.ops.delete(b, geom=[v for v in b.verts if v.co.z < -1e-4], context="VERTS")
            bmesh.ops.scale(b, vec=(r, r, h), verts=b.verts)
            bmesh.ops.translate(b, vec=(x, y, z), verts=b.verts)
        self._add(g)
        return self

    def poly_prism(self, pts, z, h):
        """Extrude a 2D polygon (x,y list) from z to z+h."""
        def g(b):
            vs = [b.verts.new((px, py, z)) for px, py in pts]
            f = b.faces.new(vs)
            ext = bmesh.ops.extrude_face_region(b, geom=[f])
            nv = [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]
            bmesh.ops.translate(b, vec=(0, 0, h), verts=nv)
            bmesh.ops.recalc_face_normals(b, faces=b.faces)
        self._add(g)
        return self

    def profile(self, pts_xz, y0, width, axis="y"):
        """Extrude a side profile (x, z points) across `width` along y (or x)."""
        def g(b):
            if axis == "y":
                vs = [b.verts.new((px, y0, pz)) for px, pz in pts_xz]
                vec = (0, width, 0)
            else:
                vs = [b.verts.new((y0, px, pz)) for px, pz in pts_xz]
                vec = (width, 0, 0)
            f = b.faces.new(vs)
            ext = bmesh.ops.extrude_face_region(b, geom=[f])
            nv = [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]
            bmesh.ops.translate(b, vec=vec, verts=nv)
            bmesh.ops.recalc_face_normals(b, faces=b.faces)
        self._add(g)
        return self

    def quad(self, pts):
        def g(b):
            f = b.faces.new([b.verts.new(p) for p in pts])
        self._add(g)
        return self

    def build(self, collection=None):
        me = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(me)
        self.bm.free()
        for p in me.polygons:
            p.use_smooth = self.smooth
        me.materials.append(self.material)
        o = bpy.data.objects.new(self.name, me)
        (collection or bpy.context.scene.collection).objects.link(o)
        if self.bevel > 0:
            mod = o.modifiers.new("bevel", "BEVEL")
            mod.width = self.bevel
            mod.segments = 2
            mod.limit_method = "ANGLE"
            mod.angle_limit = math.radians(40)
            mod.harden_normals = False
        return o


class Builder:
    """Parts by (material key): add primitives, then build() them all."""

    def __init__(self):
        self.parts = {}

    def part(self, kind, color, bevel=0.0, smooth=False, **kw):
        key = (kind, color, bevel, smooth, tuple(sorted(kw.items())))
        if key not in self.parts:
            self.parts[key] = Part(mat(kind, color, **kw), bevel, smooth, "%s_%s" % (kind, color))
        return self.parts[key]

    def build(self):
        return [p.build() for p in self.parts.values()]


# -- reusable building pieces -------------------------------------------------------------------------
def windows(B, x0, y0, z0, w, d, h, floors, per_floor, face="both", glass="#2B4A6B", frame="#D8DDE6",
            sill=True, win_h=0.55, win_w=0.62, lit=0.0, seed=1):
    """Framed, inset windows on the visible facades (x-max and y-max) of a block."""
    rnd = random.Random(seed)
    fh = h / floors
    G = B.part("glass", glass)
    L = B.part("emit", "#FFD58A", strength=2.2)
    F = B.part("paint", frame, bevel=0.15)
    faces = []
    if face in ("both", "x"):
        faces.append(("x", d))
    if face in ("both", "y"):
        faces.append(("y", w))
    for axis, span in faces:
        n = per_floor if axis == "y" else max(1, int(round(per_floor * d / max(w, 1))))
        cw = span / n
        ww, wh = cw * win_w, fh * win_h
        for fl in range(floors):
            zb = z0 + fl * fh + (fh - wh) * 0.55
            for k in range(n):
                c = k * cw + (cw - ww) / 2
                target = L if rnd.random() < lit else G
                if axis == "x":
                    X = x0 + w
                    F.box(X - 0.2, y0 + c - 0.6, zb - 0.6, 0.8, ww + 1.2, wh + 1.2)
                    target.box(X + 0.45, y0 + c, zb, 0.3, ww, wh)
                    if sill:
                        F.box(X - 0.2, y0 + c - 1.0, zb - 1.3, 1.8, ww + 2.0, 0.8)
                else:
                    Y = y0 + d
                    F.box(x0 + c - 0.6, Y - 0.2, zb - 0.6, ww + 1.2, 0.8, wh + 1.2)
                    target.box(x0 + c, Y + 0.45, zb, ww, 0.3, wh)
                    if sill:
                        F.box(x0 + c - 1.0, Y - 0.2, zb - 1.3, ww + 2.0, 1.8, 0.8)


def curtain_wall(B, x0, y0, z0, w, d, h, floors, glass="#294E78", mullion="#AEB9C9"):
    """A glass tower skin: glass body with mullions and floor bands."""
    B.part("glass", glass, bevel=0.3).box(x0, y0, z0, w, d, h)
    M = B.part("metal", mullion, rough=0.25)
    fh = h / floors
    for f in range(1, floors):
        z = z0 + f * fh
        M.box(x0 - 0.3, y0 + d - 0.2, z - 0.3, w + 0.6, 0.8, 0.6)
        M.box(x0 + w - 0.2, y0 - 0.3, z - 0.3, 0.8, d + 0.6, 0.6)
    for k in range(1, int(w / 6)):
        M.box(x0 + k * w / int(w / 6) - 0.2, y0 + d - 0.2, z0, 0.4, 0.6, h)
    for k in range(1, int(d / 6)):
        M.box(x0 + w - 0.2, y0 + k * d / int(d / 6) - 0.2, z0, 0.6, 0.4, h)


def parapet(B, x, y, z, w, d, color="#C9CCD2", t=1.2, hh=2.5):
    P = B.part("concrete", color, bevel=0.2)
    P.box(x, y, z, w, t, hh).box(x, y + d - t, z, w, t, hh)
    P.box(x, y, z, t, d, hh).box(x + w - t, y, z, t, d, hh)
    B.part("roof", "#4A4F58").box(x + t, y + t, z, w - 2 * t, d - 2 * t, 0.4)


def rooftop(B, x, y, z, w, d, seed=3):
    """AC units, a water tank, vents: the clutter that sells a roof."""
    rnd = random.Random(seed)
    M = B.part("metal", "#9AA3AE", rough=0.45, bevel=0.2)
    for _ in range(rnd.randint(2, 4)):
        ax, ay = x + rnd.uniform(3, w - 9), y + rnd.uniform(3, d - 8)
        M.box(ax, ay, z, 6, 5, 3.5)
        B.part("metal", "#3C434D").cyl(ax + 3, ay + 2.5, z + 3.5, 1.6, 0.3)
    if rnd.random() < 0.7:
        tx, ty = x + rnd.uniform(4, w - 6), y + rnd.uniform(4, d - 6)
        B.part("metal", "#6F7A86").cyl(tx, ty, z, 0.3, 3, 6)
        B.part("paint", "#7D6B5A").cyl(tx, ty, z + 3, 3.2, 5, 16)


def door(B, face, x, y, z, w=8, h=11, color="#2B2F36", canopy=None):
    D = B.part("glass", "#22303F")
    F = B.part("metal", "#8B96A3", bevel=0.1)
    if face == "x":
        F.box(x - 0.3, y - 0.8, z, 1.0, w + 1.6, h + 0.8)
        D.box(x + 0.4, y, z, 0.4, w, h)
        if canopy:
            B.part("paint", canopy, bevel=0.3).box(x, y - 2, z + h + 1, 5, w + 4, 1.2)
    else:
        F.box(x - 0.8, y - 0.3, z, w + 1.6, 1.0, h + 0.8)
        D.box(x, y + 0.4, z, w, 0.4, h)
        if canopy:
            B.part("paint", canopy, bevel=0.3).box(x - 2, y, z + h + 1, w + 4, 5, 1.2)


def sign(B, face, x, y, z, w, h, color, text_color="#FFFFFF"):
    """A signboard with a light strip (text is left to the UI)."""
    S = B.part("paint", color, bevel=0.3)
    if face == "x":
        S.box(x, y, z, 1.2, w, h)
        B.part("emit", text_color, strength=1.5).box(x + 1.2, y + w * 0.12, z + h * 0.35, 0.2, w * 0.76, h * 0.3)
    else:
        S.box(x, y, z, w, 1.2, h)
        B.part("emit", text_color, strength=1.5).box(x + w * 0.12, y + 1.2, z + h * 0.35, w * 0.76, 0.2, h * 0.3)


def tree(B, x, y, s=1.0, kind="round", color="#4E8F3A", seed=0):
    rnd = random.Random(seed + int(x * 7 + y * 13))
    B.part("paint", "#5A3E2B", rough=0.9).cyl(x, y, 0, 0.9 * s, 9 * s, 8, r2=0.6 * s)
    F = B.part("foliage", color, smooth=True)
    if kind == "round":
        for _ in range(5):
            F.sphere(x + rnd.uniform(-3, 3) * s, y + rnd.uniform(-3, 3) * s, (13 + rnd.uniform(-1, 4)) * s,
                     rnd.uniform(3.5, 5.2) * s, segs=14, rings=8)
    else:
        for k in range(3):
            F.cyl(x, y, (5 + k * 5) * s, (7 - k * 1.8) * s, 7 * s, 12, r2=0.3 * s)


def bush(B, x, y, s=1.0, color="#3F7F34"):
    F = B.part("foliage", color, smooth=True)
    F.sphere(x, y, 1.8 * s, 2.6 * s, sz=0.75, segs=12, rings=6)
    F.sphere(x + 1.8 * s, y - 1 * s, 1.5 * s, 2.0 * s, sz=0.75, segs=12, rings=6)


def lamp(B, x, y, h=16):
    M = B.part("metal", "#3E4650", rough=0.4)
    M.cyl(x, y, 0, 0.45, h, 8)
    M.box(x - 0.4, y - 0.4, h - 0.6, 0.8, 3.2, 0.6)
    B.part("emit", "#FFE2A8", strength=4.0).box(x - 0.6, y + 2.0, h - 1.2, 1.2, 1.4, 0.6)


def base(B, top="grass", depth=4, pave=None, size=100, soil=True):
    """The lot: a block with a kerb (map) or a soil side (catalogue) and a top."""
    if soil and depth > 6:
        B.part("soil", "#6B4A32", bevel=0.4).box(0, 0, -depth, size, size, depth - 2)
        B.part("grass" if top == "grass" else "concrete", "#4F8A38" if top == "grass" else "#9A9DA3", bevel=0.3).box(0, 0, -2, size, size, 2)
    else:
        B.part("concrete", "#A9ADB3", bevel=0.4).box(0, 0, -depth, size, size, depth)
    if top == "grass":
        B.part("grass", "#5B9A40").box(1.5, 1.5, -0.2, size - 3, size - 3, 0.4)
    if pave:
        x, y, w, d = pave
        B.part("concrete", "#B8B9BC", bevel=0.2).box(x, y, 0, w, d, 0.5)


def car(B, x, y, z=0, length=16, width=8, color="#C0392B", axis="x", kind="sedan"):
    """A compact car along x (or y). Glossy paint, glass, rubber, lights."""
    P = B.part("carpaint", color, bevel=0.8)
    G = B.part("glass", "#1B2533")
    R = B.part("rubber", "#1A1A1C", smooth=True)
    H = B.part("emit", "#FFF4D6", strength=2.0)
    T = B.part("emit", "#FF3B30", strength=1.5)
    L, W = length, width

    def bx(a, b, c, dl, dw, dh, part):
        if axis == "x":
            part.box(x + a, y + b, z + c, dl, dw, dh)
        else:
            part.box(x + b, y + a, z + c, dw, dl, dh)
    body_h = 3.4 if kind != "suv" else 4.6
    bx(0, 0, 1.6, L, W, body_h, P)
    cab = (0.22, 0.72) if kind != "van" else (0.1, 0.95)
    ch = 3.0 if kind != "suv" else 3.4
    bx(L * cab[0], 0.5, 1.6 + body_h, L * (cab[1] - cab[0]), W - 1.0, ch, G)
    bx(L * cab[0] + 0.8, 0.8, 1.6 + body_h + ch - 0.6, L * (cab[1] - cab[0]) - 1.6, W - 1.6, 0.8, P)
    bx(L - 0.3, 0.8, 3.2, 0.5, 1.8, 1.0, H)
    bx(L - 0.3, W - 2.6, 3.2, 0.5, 1.8, 1.0, H)
    bx(-0.2, 0.8, 3.4, 0.4, 1.6, 0.8, T)
    bx(-0.2, W - 2.4, 3.4, 0.4, 1.6, 0.8, T)
    for a in (L * 0.2, L * 0.8):
        for b in (-0.3, W + 0.3):
            if axis == "x":
                R.cyl_axis((x + a, y + b - 0.9, z + 2.0), (x + a, y + b + 0.9, z + 2.0), 2.0, 14)
            else:
                R.cyl_axis((x + b - 0.9, y + a, z + 2.0), (x + b + 0.9, y + a, z + 2.0), 2.0, 14)
