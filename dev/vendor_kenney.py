#!/usr/bin/env python3
"""Vendor the Kenney CC0 kits into assets/kenney/<kit>/ from the zips in
tools/kenney/ (downloaded by tools/kenney/fetch.sh from kenney.nl/assets/<kit>).

Only what the game loads is copied: the GLB models with their colormap
texture, the kit's License.txt, and for the 2D packs a small PNG subset.
"""
import os
import re
import shutil
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "tools", "kenney")
DST = os.path.join(ROOT, "assets", "kenney")

MODEL_KITS = {
    "city-kit-commercial": "kenney_city-kit-commercial_2.1.zip",
    "city-kit-industrial": "kenney_city-kit-industrial_2.0.zip",
    "city-kit-roads": "kenney_city-kit-roads.zip",
    "city-kit-suburban": "kenney_city-kit-suburban_20.zip",
    "car-kit": "kenney_car-kit.zip",
    "train-kit": "kenney_train-kit.zip",
    "factory-kit": "kenney_factory-kit_3.0.zip",
    "pirate-kit": "kenney_pirate-kit.zip",
    "blaster-kit": "kenney_blaster-kit_2.1.zip",
    "food-kit": "kenney_food-kit.zip",
    "racing-kit": "kenney_racing-kit.zip",
}
PNG_PACKS = {
    # pack: (zip, regex of files to keep)
    "game-icons": ("kenney_game-icons.zip", r"^PNG/White/2x/[^/]+\.png$"),
    "ui-pack": ("kenney_ui-pack.zip", r"^PNG/(Blue|Grey)/Default/[^/]+\.png$"),
}


def main():
    for kit, zname in MODEL_KITS.items():
        z = zipfile.ZipFile(os.path.join(SRC, zname))
        out = os.path.join(DST, kit)
        if os.path.isdir(out):
            shutil.rmtree(out)
        os.makedirs(os.path.join(out, "Textures"), exist_ok=True)
        n = 0
        for name in z.namelist():
            if name.endswith("/"):
                continue
            base = os.path.basename(name)
            if re.match(r"^Models/GLT?F? ?format/[^/]+\.glb$", name) or re.match(r"^Models/GLB format/[^/]+\.glb$", name):
                target = os.path.join(out, base)
            elif re.match(r"^Models/GLT?F? ?format/Textures/[^/]+\.png$", name) or re.match(r"^Models/GLB format/Textures/[^/]+\.png$", name):
                target = os.path.join(out, "Textures", base)
            elif name == "License.txt":
                target = os.path.join(out, "License.txt")
            else:
                continue
            with z.open(name) as src, open(target, "wb") as dst:
                shutil.copyfileobj(src, dst)
            n += 1
        if not os.listdir(os.path.join(out, "Textures")):
            os.rmdir(os.path.join(out, "Textures"))
        print("%-22s %4d files" % (kit, n))
    for pack, (zname, pattern) in PNG_PACKS.items():
        z = zipfile.ZipFile(os.path.join(SRC, zname))
        out = os.path.join(DST, pack)
        if os.path.isdir(out):
            shutil.rmtree(out)
        os.makedirs(out)
        n = 0
        for name in z.namelist():
            low = name.lower()
            if re.match(pattern, name) or low == "license.txt":
                target = os.path.join(out, "License.txt" if low == "license.txt" else name.split("/")[-2] + "_" + os.path.basename(name)
                                      if pack == "ui-pack" else os.path.basename(name))
                with z.open(name) as src, open(target, "wb") as dst:
                    shutil.copyfileobj(src, dst)
                n += 1
        print("%-22s %4d files" % (pack, n))


if __name__ == "__main__":
    main()
