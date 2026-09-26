"""Characters: full-body figures and head portraits.

    tools/blender/app/blender -b --factory-startup -P art_src/blender/characters.py -- [--only thug] [--samples 64]

Stylised-realistic figures built from metaballs (one family per material, so
skin, clothes and hair blend within themselves but keep clean edges between),
converted to meshes and shaded with the kit's skin, cloth and leather
materials. Units: 1 = 1 cm, standing on z = 0, facing +x.

Writes art/catalog/characters/<code>.png (384 x 768), assets/art/characters/<code>.png
and portraits art/catalog/portraits/<code>_<n>.png, assets/art/portraits/*.png (256 x 256).
"""
import math
import os
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import kit  # noqa: E402
from kit import Builder  # noqa: E402


class Figure:
    def __init__(self):
        self.families = {}

    def _mb(self, fam, material):
        if fam not in self.families:
            mb = bpy.data.metaballs.new(fam)
            mb.resolution = 1.6
            mb.render_resolution = 1.2
            mb.threshold = 0.6
            o = bpy.data.objects.new(fam, mb)
            bpy.context.scene.collection.objects.link(o)
            mb.materials.append(material)
            self.families[fam] = (mb, o)
        return self.families[fam][0]

    def ball(self, fam, material, p, r, stiff=2.0):
        e = self._mb(fam, material).elements.new(type="BALL")
        e.co = p
        e.radius = r
        e.stiffness = stiff
        return e

    def ellipsoid(self, fam, material, p, size, stiff=2.0):
        e = self._mb(fam, material).elements.new(type="ELLIPSOID")
        e.co = p
        e.size_x, e.size_y, e.size_z = size
        e.radius = max(size) * 1.1
        e.stiffness = stiff
        return e

    def limb(self, fam, material, a, b, r0, r1=None, steps=None):
        """A tapered limb from a to b, as a chain of balls."""
        r1 = r0 if r1 is None else r1
        a, b = Vector(a), Vector(b)
        n = steps or max(3, int((b - a).length / (min(r0, r1) * 0.7)))
        for i in range(n + 1):
            t = i / n
            self.ball(fam, material, a.lerp(b, t), r0 + (r1 - r0) * t)

    def finish(self):
        """Metaballs -> meshes (smooth shaded)."""
        objs = []
        bpy.context.view_layer.update()
        dg = bpy.context.evaluated_depsgraph_get()
        for fam, (mb, o) in self.families.items():
            ev = o.evaluated_get(dg)
            me = bpy.data.meshes.new_from_object(ev)
            for p in me.polygons:
                p.use_smooth = True
            mo = bpy.data.objects.new(fam + "_mesh", me)
            bpy.context.scene.collection.objects.link(mo)
            objs.append(mo)
        for fam, (mb, o) in self.families.items():
            bpy.data.objects.remove(o, do_unlink=True)
        return objs


def body(F, skin, top, pants, shoes, hair, build=1.0, female=False, top_kind="cloth", bare_arms=False,
         hair_style="short", pants_kind="cloth"):
    S = kit.mat("skin", skin)
    T = kit.mat(top_kind, top)
    P = kit.mat(pants_kind, pants)
    Sh = kit.mat("leather", shoes)
    H = kit.mat("cloth", hair)
    w = build
    hip = 92
    # legs (spread a little), shoes
    for s in (1, -1):
        y = s * 9 * (0.85 if female else 1.0)
        F.limb("pants", P, (0, y, hip), (1.5, y * 1.05, 50), 8.2 * w, 6.4 * w)
        F.limb("pants", P, (1.5, y * 1.05, 50), (0, y * 1.1, 9), 6.2 * w, 4.6 * w)
        F.ellipsoid("shoes", Sh, (4, y * 1.1, 4), (12, 5.0, 4.2))
    # hips and torso
    F.ellipsoid("pants", P, (0, 0, hip + 2), (12 * w, 17 * w if not female else 18, 10))
    chest_w = 21 * w if not female else 17
    F.ellipsoid("top", T, (0, 0, hip + 16), (11 * w, 17 * w if not female else 15, 13))
    F.ellipsoid("top", T, (0.5, 0, hip + 33), (12.5 * w, chest_w, 14))
    if female:
        for s in (1, -1):
            F.ball("top", T, (7, s * 6, hip + 33), 6)
    F.ball("top", T, (0, 0, hip + 44), 12 * w)
    # neck, head
    F.limb("skin", S, (0, 0, hip + 44), (1, 0, hip + 56), 6.2 * (1 if not female else 0.85))
    F.ellipsoid("skin", S, (1.5, 0, hip + 67), (10.5, 8.8 if not female else 8.3, 12))
    F.ellipsoid("skin", S, (5, 0, hip + 61), (6.5, 7.0, 6.5))          # jaw
    F.ball("skin", S, (11.2, 0, hip + 66), 2.2)                       # nose
    for s in (1, -1):
        F.ball("skin", S, (0, s * 9.2, hip + 66), 2.6)                # ears
    # arms
    sh_y = 19 * w if not female else 16
    arm = "skin" if bare_arms else "top"
    arm_mat = S if bare_arms else T
    for s in (1, -1):
        F.ball("top", T, (0, s * (sh_y - 2), hip + 43), 8 * w)
        F.limb(arm, arm_mat, (0, s * sh_y, hip + 42), (-2, s * (sh_y + 4), hip + 16), 6 * w, 5 * w)
        F.limb(arm, arm_mat, (-2, s * (sh_y + 4), hip + 16), (3, s * (sh_y + 5), hip - 8), 4.8 * w, 3.8 * w)
        F.ellipsoid("skin", S, (4, s * (sh_y + 5), hip - 14), (3.2, 2.4, 5.5))   # hand
    # hair
    if hair_style == "short":
        F.ellipsoid("hair", H, (-0.5, 0, hip + 72), (10.8, 9.4, 8.5))
    elif hair_style == "long":
        F.ellipsoid("hair", H, (-1.5, 0, hip + 71), (11.5, 10, 10))
        F.ellipsoid("hair", H, (-4, 0, hip + 56), (7, 11, 14))
    elif hair_style == "bald":
        pass
    # eyes: separate small dark spheres, not metaballs
    E = Builder()
    for s in (1, -1):
        E.part("glass", "#1B1410", smooth=True).sphere(10.2, s * 3.6, hip + 68.5, 1.25, segs=12, rings=8)
        E.part("paint", "#2B1D14", smooth=True).box(9.6, s * 3.6 - 2.6, hip + 71.2, 1.2, 5.2, 0.9)
    return E


def businessman(F):
    E = body(F, "#D6A988", "#1E2430", "#1E2430", "#121212", "#2A1E16")
    E.part("paint", "#F4F6F8").box(10.5, -4, 124, 1.2, 8, 12)
    E.part("paint", "#8E1B1B", bevel=0.3).box(11.6, -1.6, 113, 1.2, 3.2, 22)
    return E


def thug(F):
    E = body(F, "#C68E6A", "#1F1F1F", "#2E4A6B", "#3A2A1E", "#141414", build=1.08, top_kind="leather", pants_kind="cloth")
    E.part("cloth", "#8A8F96").box(10.8, -6, 112, 1.0, 12, 20)
    return E


def woman(F):
    E = body(F, "#E2B393", "#B3141C", "#B3141C", "#8E1015", "#3A2216", female=True, bare_arms=True, hair_style="long")
    # the dress: a flared skirt over the legs
    D = kit.mat("cloth", "#B3141C")
    for i in range(6):
        z = 92 - i * 8
        F.ellipsoid("top", D, (0, 0, z), (11 + i * 0.8, 15 + i * 1.2, 7))
    return E


def hoodie(F):
    E = body(F, "#B98262", "#2B2F36", "#3A3F47", "#E8E8E8", "#141414")
    T = kit.mat("cloth", "#2B2F36")
    F.ellipsoid("top", T, (-3, 0, 160), (12, 12, 16))   # the hood behind the head
    F.ellipsoid("top", T, (0, 0, 172), (12, 11.5, 10))
    return E


def swat(F):
    E = body(F, "#C68E6A", "#1C1F22", "#1C1F22", "#101010", "#101010", build=1.08, pants_kind="cloth")
    V = kit.mat("cloth", "#2A2E33")
    F.ellipsoid("vest", V, (2, 0, 125), (14, 20, 17))
    E.part("paint", "#1A1D21", rough=0.6, smooth=True).dome(1, 0, 162, 12.5, 11)
    E.part("glass", "#101418").box(8.5, -8, 155, 3, 16, 5)
    # a rifle held across the chest
    G = E.part("metal", "#23262B", rough=0.35, bevel=0.3)
    G.box(12, -18, 110, 5, 40, 5)
    G.box(13, 16, 106, 3, 4, 8)
    E.part("metal", "#23262B").cyl_axis((14.5, 22, 112.5), (14.5, 34, 112.5), 1.0, 10)
    return E


def fighter(F):
    E = body(F, "#B07352", "#E8E4DC", "#5B6143", "#2A2A2A", "#141414", build=1.18, bare_arms=True, hair_style="bald")
    C = kit.mat("cloth", "#5B6143")
    for s in (1, -1):
        F.ball("pants", C, (2, s * 10, 60), 7.6)
    return E


CHARACTERS = {"businessman": businessman, "thug": thug, "woman": woman, "hoodie": hoodie, "swat": swat, "fighter": fighter}


def main():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    only = a[a.index("--only") + 1].split(",") if "--only" in a else []
    samples = int(a[a.index("--samples") + 1]) if "--samples" in a else 64
    sc = kit.reset(samples)
    for code, fn in CHARACTERS.items():
        if only and code not in only:
            continue
        kit.clear_meshes()
        kit.clear_cameras()
        F = Figure()
        E = fn(F)
        objs = F.finish() + E.build()
        # full body: a 3/4 view from a little above
        kit.frame_objects(sc, 384, 768, 0.05, elev=math.radians(8), azim=math.radians(25), objs=objs)
        out = os.path.join(kit.ROOT, "art", "catalog", "characters", code + ".png")
        kit.render(sc, out)
        dst = os.path.join(kit.ROOT, "assets", "art", "characters")
        os.makedirs(dst, exist_ok=True)
        shutil.copy(out, os.path.join(dst, code + ".png"))
        # portrait: head and shoulders
        kit.clear_cameras()
        head = [o for o in objs]
        cam = kit.camera(sc, 256, 256, 46, target=(2, 0, 150), elev=math.radians(4), azim=math.radians(20))
        out = os.path.join(kit.ROOT, "art", "catalog", "portraits", code + ".png")
        kit.render(sc, out)
        dst = os.path.join(kit.ROOT, "assets", "art", "portraits")
        os.makedirs(dst, exist_ok=True)
        shutil.copy(out, os.path.join(dst, code + ".png"))
        print("rendered", code)


if __name__ == "__main__":
    main()
