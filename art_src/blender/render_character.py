"""Render the walking player as a sprite sheet (4 isometric directions x 8 frames).

    tools/blender/app/blender -b --factory-startup -P art_src/blender/render_character.py

A simple procedural figure (rounded limbs, torso, head, hair), posed in code
with a sine walk cycle, shot with the same 30-degree orthographic camera and
lights as the places. Writes assets/art/character/walker.png and walker.json
(the layout src/world/walker.gd reads). Replace both files to reskin.
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)

import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

from svgkit import P, ROOT, light, dark  # noqa: E402
from iso3d import hex_rgba, Z_SCALE  # noqa: E402
import render_places as rp  # noqa: E402  (scene, lights, materials)

FW, FH = 128, 160           # frame, px (2x of a 64 x 80 art-px frame)
ANCHOR = (64, 144)          # feet, px in the frame
FRAMES = 8
DIRS = {"se": (0, 1), "sw": (1, 0), "ne": (-1, 0), "nw": (0, -1)}  # facing, Blender xy


def limb(name, parent, joint, length, radius, color, mats):
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=radius, depth=length)
    o = bpy.context.active_object
    o.name = name
    o.data.transform(Matrix.Translation((0, 0, -length / 2)))
    # round the far end
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=radius)
    cap = bpy.context.active_object
    cap.data.transform(Matrix.Translation((0, 0, -length)))
    for obj in (o, cap):
        obj.data.materials.append(mats.get(color, "solid"))
        for p in obj.data.polygons:
            p.use_smooth = True
    cap.parent = o
    o.parent = parent
    o.location = joint
    return o


def build(mats):
    root = bpy.data.objects.new("root", None)
    bpy.context.scene.collection.objects.link(root)
    body = bpy.data.objects.new("body", None)
    bpy.context.scene.collection.objects.link(body)
    body.parent = root
    skin, shirt, pants, hair, shoe = "#E8B48C", P["turquoise"], P["slate"], "#3A2A22", P["ink"]
    Z = Z_SCALE
    hip_z, sh_z = 7.0 * Z, 12.2 * Z
    legs = [limb("leg_l", body, (0.0, 1.3, hip_z), 6.4 * Z, 1.05, pants, mats),
            limb("leg_r", body, (0.0, -1.3, hip_z), 6.4 * Z, 1.05, pants, mats)]
    for lg in legs:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=6, radius=1.2)
        f = bpy.context.active_object
        f.scale = (1.5, 0.9, 0.6)
        f.location = (0.6, 0, -6.4 * Z - 0.4)
        f.parent = lg
        f.data.materials.append(mats.get(shoe, "solid"))
    # torso: a rounded, slightly tapered block
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=1.0)
    t = bpy.context.active_object
    t.scale = (1.6, 2.5, 3.4 * Z)
    t.location = (0, 0, (hip_z + sh_z) / 2 + 0.3)
    t.parent = body
    t.data.materials.append(mats.get(shirt, "solid"))
    for p in t.data.polygons:
        p.use_smooth = True
    arms = [limb("arm_l", body, (0.0, 2.7, sh_z), 5.2 * Z, 0.75, light(shirt, 0.05), mats),
            limb("arm_r", body, (0.0, -2.7, sh_z), 5.2 * Z, 0.75, light(shirt, 0.05), mats)]
    for a in arms:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=0.8)
        h = bpy.context.active_object
        h.location = (0, 0, -5.2 * Z - 0.6)
        h.parent = a
        h.data.materials.append(mats.get(skin, "solid"))
    # head and hair
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=14, radius=2.25)
    hd = bpy.context.active_object
    hd.location = (0.2, 0, sh_z + 2.9)
    hd.parent = body
    hd.data.materials.append(mats.get(skin, "solid"))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=14, radius=2.4)
    hr = bpy.context.active_object
    hr.scale = (1.0, 1.0, 0.75)
    hr.location = (-0.35, 0, sh_z + 3.6)
    hr.parent = body
    hr.data.materials.append(mats.get(hair, "solid"))
    # a bag strap across the chest: a readable facing cue
    bpy.ops.mesh.primitive_torus_add(major_radius=2.6, minor_radius=0.25)
    st = bpy.context.active_object
    st.rotation_euler = (math.radians(90), math.radians(35), 0)
    st.location = (0.1, 0, (hip_z + sh_z) / 2 + 0.6)
    st.parent = body
    st.data.materials.append(mats.get(P["saffron_dk"], "solid"))
    for o in bpy.context.scene.objects:
        if o.type == "MESH":
            for p in o.data.polygons:
                p.use_smooth = True
    return root, body, legs, arms


def pose(body, legs, arms, phase, walking):
    s = math.sin(phase) if walking else 0.0
    swing = math.radians(28)
    legs[0].rotation_euler = (0, s * swing, 0)
    legs[1].rotation_euler = (0, -s * swing, 0)
    arms[0].rotation_euler = (0, -s * swing * 0.9, 0)
    arms[1].rotation_euler = (0, s * swing * 0.9, 0)
    body.location = (0, 0, abs(math.cos(phase)) * 0.45 if walking else 0.0)


def main():
    sc = rp.setup_scene(FW, 64)
    sc.render.resolution_x = FW
    sc.render.resolution_y = FH
    cam = sc.camera
    # frame: 64 x 80 art px; the feet at ANCHOR
    art_h = FH / 2.0
    cam.data.ortho_scale = art_h * math.cos(math.radians(45))
    px = cam.data.ortho_scale / art_h
    f = Vector((-math.cos(rp.CAM_ELEV) / math.sqrt(2), -math.cos(rp.CAM_ELEV) / math.sqrt(2), -math.sin(rp.CAM_ELEV)))
    right = f.cross(Vector((0, 0, 1))).normalized()
    up = right.cross(f).normalized()
    dy = (ANCHOR[1] - FH / 2) / 2.0   # art px below the centre
    target = up * (dy * px)
    cam.location = target - f * 600
    mats = rp.Materials()
    root, body, legs, arms = build(mats)

    tmp = os.path.join(ROOT, "tools", "_walker_frames")
    os.makedirs(tmp, exist_ok=True)
    rows = {}
    order = []
    for d in DIRS:
        order.append(("walk_" + d, d, True, FRAMES))
    for d in DIRS:
        order.append(("idle_" + d, d, False, 1))
    sheet = np.zeros((len(order) * FH, FRAMES * FW, 4), dtype=np.float32)
    for r, (name, d, walking, n) in enumerate(order):
        rows[name] = r
        fx, fy = DIRS[d]
        # the figure is modelled facing +x; turn it to face (fx, fy)
        root.rotation_euler = (0, 0, math.atan2(fy, fx))
        for k in range(n):
            pose(body, legs, arms, 2 * math.pi * k / FRAMES, walking)
            path = os.path.join(tmp, "%s_%d.png" % (name, k))
            sc.render.filepath = path
            bpy.ops.render.render(write_still=True)
            img = bpy.data.images.load(path)
            pix = np.array(img.pixels[:], dtype=np.float32).reshape(FH, FW, 4)
            bpy.data.images.remove(img)
            # Blender images are bottom-up; the sheet is built bottom-up too
            y0 = (len(order) - 1 - r) * FH
            sheet[y0:y0 + FH, k * FW:(k + 1) * FW] = pix
    out = bpy.data.images.new("walker", FRAMES * FW, len(order) * FH, alpha=True)
    out.pixels = sheet.ravel()
    out_dir = os.path.join(ROOT, "assets", "art", "character")
    os.makedirs(out_dir, exist_ok=True)
    out.filepath_raw = os.path.join(out_dir, "walker.png")
    out.file_format = "PNG"
    out.save()
    with open(os.path.join(out_dir, "walker.json"), "w") as fh:
        json.dump({"frame_size": [FW, FH], "frames": FRAMES, "idle_frames": 1, "fps": 10,
                   "anchor": list(ANCHOR), "display_height": FH / 2, "rows": rows}, fh, indent=1)
    for fname in os.listdir(tmp):
        os.remove(os.path.join(tmp, fname))
    os.rmdir(tmp)
    print("walker sheet written")


main()
