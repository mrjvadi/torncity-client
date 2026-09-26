#!/usr/bin/env python3
"""Compose docs/screenshots/index.png: a contact sheet of every captured
screen, phone (fa/en side by side) then desktop, kept under 2 MB.

    python3 dev/build_index_sheet.py [--font path/to/font.ttf]
"""
import argparse
import glob
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = os.path.join(ROOT, "docs/screenshots")
OUT = os.path.join(SHOTS, "index.png")
BG, PANEL, LINE, TXT, DIM = (10, 19, 32), (22, 36, 58), (43, 68, 104), (233, 239, 248), (142, 162, 191)


def font(sz, path=None):
    for p in [path, "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]:
        if p and os.path.exists(p):
            try:
                return ImageFont.truetype(p, sz)
            except Exception:
                pass
    return ImageFont.load_default()


def names(lang_dir):
    return sorted(os.path.basename(f)[:-4] for f in glob.glob(os.path.join(lang_dir, "*.png")))


def build(font_path=None):
    phone_en = os.path.join(SHOTS, "en")
    phone_names = names(phone_en)
    desk_en = os.path.join(SHOTS, "desktop", "en")
    desk_names = names(desk_en) if os.path.isdir(desk_en) else []

    F_TITLE = font(40, font_path)
    F_LABEL = font(20, font_path)
    F_SECTION = font(30, font_path)

    cell_w, cell_h = 176, 313          # phone thumb (720x1280 scaled)
    pad = 14
    cols = 8
    rows = (len(phone_names) + cols - 1) // cols
    header_h = 120
    phone_h = header_h + rows * (cell_h + 46) + pad

    dcell_w, dcell_h = 320, 180        # desktop thumb (1600x900 scaled)
    dcols = 4
    drows = (len(desk_names) + dcols - 1) // dcols if desk_names else 0
    desk_header_h = 90
    desk_h = (desk_header_h + drows * (dcell_h + 46) + pad) if desk_names else 0

    W = max(cols * (cell_w + pad) + pad, dcols * (dcell_w + pad) + pad, 1500)
    H = phone_h + desk_h + 40
    sheet = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(sheet)
    d.text((30, 20), "Torncity - screenshot index (phone: fa+en side by side)", font=F_TITLE, fill=TXT)

    y = header_h
    x0 = (W - cols * (cell_w + pad)) // 2
    for i, name in enumerate(phone_names):
        col = i % cols
        row = i // cols
        x = x0 + col * (cell_w + pad)
        yy = y + row * (cell_h + 46)
        half = cell_w // 2
        for j, lang in enumerate(["fa", "en"]):
            p = os.path.join(SHOTS, lang, name + ".png")
            if not os.path.exists(p):
                continue
            im = Image.open(p).convert("RGB")
            im.thumbnail((half - 2, cell_h), Image.LANCZOS)
            sheet.paste(im, (x + j * half, yy))
        d.rectangle([x, yy, x + cell_w, yy + cell_h], outline=LINE, width=1)
        d.line([(x + half, yy), (x + half, yy + cell_h)], fill=LINE, width=1)
        label = name.replace("_", " ")
        tw = d.textlength(label, font=F_LABEL)
        d.text((x + (cell_w - tw) / 2, yy + cell_h + 8), label, font=F_LABEL, fill=DIM)

    if desk_names:
        y2 = phone_h + 10
        d.text((30, y2), "Desktop (1600x900, en)", font=F_SECTION, fill=TXT)
        y2 += desk_header_h
        x1 = (W - dcols * (dcell_w + pad)) // 2
        for i, name in enumerate(desk_names):
            col = i % dcols
            row = i // dcols
            x = x1 + col * (dcell_w + pad)
            yy = y2 + row * (dcell_h + 46)
            p = os.path.join(SHOTS, "desktop", "en", name + ".png")
            im = Image.open(p).convert("RGB")
            im.thumbnail((dcell_w, dcell_h), Image.LANCZOS)
            sheet.paste(im, (x, yy))
            d.rectangle([x, yy, x + dcell_w, yy + dcell_h], outline=LINE, width=1)
            label = name.replace("_", " ")
            tw = d.textlength(label, font=F_LABEL)
            d.text((x + (dcell_w - tw) / 2, yy + dcell_h + 8), label, font=F_LABEL, fill=DIM)

    sheet.save(OUT, optimize=True)
    size_mb = os.path.getsize(OUT) / 1e6
    print("saved", OUT, sheet.size, "%.2f MB" % size_mb)
    if size_mb > 2.0:
        # re-save with palette quantisation to shrink it under the 2 MB cap
        sheet.convert("P", palette=Image.ADAPTIVE, colors=200).save(OUT, optimize=True)
        print("requantised", OUT, "%.2f MB" % (os.path.getsize(OUT) / 1e6))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--font")
    a = ap.parse_args()
    build(a.font)
