"""Render the city places as isometric sprites with Blender (Cycles, CPU).

    tools/blender/app/blender -b --factory-startup -P art_src/blender/render_places.py -- \
        [--size 512] [--samples 48] [--only bazaar,park]

Writes assets/art/places/render/<code>.png: 256 x 256 art space at --size
pixels (2x by default), transparent background, the lot's centre at the same
spot as the SVG (art_src/places.py contract), so either file fills the slot.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import places  # noqa: E402
from svgkit import P, ROOT  # noqa: E402
from iso3d import Iso3D, hex_rgba  # noqa: E402

ART = 256.0          # art-space canvas, px
ORIGIN = (128.0, 150.0)  # where world (0,0,0) sits in art space
CAM_ELEV = math.radians(30.0)


def args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = {"size": 512, "samples": 48, "only": []}
    for i, v in enumerate(a):
        if v == "--size":
            out["size"] = int(a[i + 1])
        elif v == "--samples":
            out["samples"] = int(a[i + 1])
        elif v == "--only":
            out["only"] = a[i + 1].split(",")
    return out


class Materials:
    """One material per (colour, kind): PBR-lite, from the shared palette."""

    def __init__(self):
        self.cache = {}

    def get(self, color, kind, opacity=1.0):
        key = (color, kind, opacity)
        if key in self.cache:
            return self.cache[key]
        m = bpy.data.materials.new("%s_%s" % (kind, color))
        m.use_nodes = True
        nt = m.node_tree
        bsdf = nt.nodes["Principled BSDF"]
        rgba = hex_rgba(color)
        bsdf.inputs["Base Color"].default_value = rgba
        rough, metal, spec = 0.62, 0.0, 0.35
        if kind == "glass":
            rough, metal, spec = 0.08, 0.15, 0.9
        elif kind == "glossy":
            rough, spec = 0.25, 0.6
        elif kind == "metal":
            rough, metal = 0.3, 0.9
        elif kind == "water":
            rough, spec = 0.05, 0.8
        elif kind == "foliage":
            rough = 0.8
        elif kind == "lit":
            bsdf.inputs["Emission Color"].default_value = rgba
            bsdf.inputs["Emission Strength"].default_value = 1.6
        elif kind == "smoke":
            rough = 1.0
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal
        if "Specular IOR Level" in bsdf.inputs:
            bsdf.inputs["Specular IOR Level"].default_value = spec
        if opacity < 1.0:
            bsdf.inputs["Alpha"].default_value = opacity
        self.cache[key] = m
        return m


def setup_scene(size, samples):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.cycles.max_bounces = 4
    sc.render.film_transparent = True
    sc.render.resolution_x = size
    sc.render.resolution_y = size
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.image_settings.compression = 90
    # keep the palette's colours: no filmic desaturation
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.view_settings.exposure = 0.0
    sc.view_settings.gamma = 1.0

    world = bpy.data.worlds.new("sky")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.62, 0.70, 0.85, 1.0)   # cool ambient fill
    bg.inputs["Strength"].default_value = 0.55
    sc.world = world

    # key light: a warm sun from the upper left (screen), soft-edged shadows
    sun = bpy.data.lights.new("key", "SUN")
    sun.energy = 3.4
    sun.angle = math.radians(9)
    sun.color = (1.0, 0.95, 0.86)
    so = bpy.data.objects.new("key", sun)
    # travels toward -x/+y Blender (from the screen upper left): tops lightest,
    # the down-left faces in light, the down-right faces in shade, as in the SVGs
    d = Vector((-0.55, 0.35, -0.76)).normalized()   # direction the light travels
    so.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(so)
    # a faint cool fill from the other side so shadowed faces keep their colour
    fill = bpy.data.lights.new("fill", "SUN")
    fill.energy = 0.7
    fill.angle = math.radians(30)
    fill.color = (0.75, 0.82, 1.0)
    fo = bpy.data.objects.new("fill", fill)
    fo.rotation_euler = Vector((0.6, -0.5, -0.6)).normalized().to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(fo)

    # camera: orthographic, 30 degrees down, looking along the lot's diagonal
    cam = bpy.data.cameras.new("cam")
    cam.type = "ORTHO"
    cam.ortho_scale = ART * math.cos(math.radians(45))   # 1 art px = 1 world unit along a diagonal
    co = bpy.data.objects.new("cam", cam)
    f = Vector((-math.cos(CAM_ELEV) / math.sqrt(2), -math.cos(CAM_ELEV) / math.sqrt(2), -math.sin(CAM_ELEV)))
    right = f.cross(Vector((0, 0, 1))).normalized()
    up = right.cross(f).normalized()
    # the canvas centre is ORIGIN[1] - 128 art px above world (0,0,0)
    px = cam.ortho_scale / ART
    target = Vector((0, 0, 0)) + up * ((ORIGIN[1] - ART / 2) * px) - right * ((ORIGIN[0] - ART / 2) * px)
    co.location = target - f * 600
    co.rotation_euler = f.to_track_quat("-Z", "Y").to_euler()
    cam.clip_end = 2000
    sc.collection.objects.link(co)
    sc.camera = co
    return sc


def render_place(sc, code, fn, out_dir, mats):
    coll = bpy.data.collections.new(code)
    sc.collection.children.link(coll)
    iso = Iso3D()
    places.FACTORY = lambda: (iso.svg, iso)
    fn()
    iso.build(coll, mats)
    sc.render.filepath = os.path.join(out_dir, code + ".png")
    bpy.ops.render.render(write_still=True)
    for o in list(coll.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.data.collections.remove(coll)
    for m in list(bpy.data.meshes):
        if m.users == 0:
            bpy.data.meshes.remove(m)
    print("rendered", code)


def main():
    a = args()
    out_dir = os.path.join(ROOT, "assets", "art", "places", "render")
    os.makedirs(out_dir, exist_ok=True)
    sc = setup_scene(a["size"], a["samples"])
    mats = Materials()
    for code, fn in places.PLACES.items():
        if a["only"] and code not in a["only"]:
            continue
        render_place(sc, code, fn, out_dir, mats)


if __name__ == "__main__":
    main()
