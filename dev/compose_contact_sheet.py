#!/usr/bin/env python3
"""Compose art/contact_sheet.png from the rendered tiles (dev/art_sheet.tscn)
and the screenshots: sections with titles, like the owner's reference sheet."""
import glob, os, sys
from PIL import Image, ImageDraw, ImageFont

tiles, out = sys.argv[1], sys.argv[2]
FONT = sys.argv[3] if len(sys.argv) > 3 else None
W = 2400
BG, PANEL, LINE, TXT, DIM = (10, 19, 32), (22, 36, 58), (43, 68, 104), (233, 239, 248), (142, 162, 191)


def font(sz):
    try:
        f = ImageFont.truetype(FONT, sz)
        try:
            f.set_variation_by_axes([700])
        except Exception:
            pass
        return f
    except Exception:
        return ImageFont.load_default()


def section(title, items, cell, cols, label=True, bg=True):
    rows = (len(items) + cols - 1) // cols
    ch = cell[1] + (34 if label else 0)
    h = 70 + rows * (ch + 12) + 20
    img = Image.new("RGB", (W, h), BG)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([12, 8, W - 12, h - 8], 14, fill=PANEL, outline=LINE, width=2)
    d.text((36, 22), title, font=font(34), fill=TXT)
    x0 = (W - cols * (cell[0] + 12)) // 2
    for i, (name, im) in enumerate(items):
        x = x0 + (i % cols) * (cell[0] + 12)
        y = 70 + (i // cols) * (ch + 12)
        if bg:
            d.rounded_rectangle([x, y, x + cell[0], y + cell[1]], 12, fill=(15, 26, 43), outline=LINE, width=1)
        im = im.convert("RGBA")
        im.thumbnail(cell, Image.LANCZOS)
        img.paste(im, (x + (cell[0] - im.width) // 2, y + (cell[1] - im.height) // 2), im)
        if label:
            t = name
            tw = d.textlength(t, font=font(20))
            d.text((x + (cell[0] - tw) / 2, y + cell[1] + 6), t, font=font(20), fill=DIM)
    return img


def load(pattern):
    return [(os.path.basename(f)[:-4].split("_", 1)[1].replace("_", " ").replace("any", "(fallback)"), Image.open(f))
            for f in sorted(glob.glob(os.path.join(tiles, pattern)))]


parts = []
shots = "docs/screenshots"
hero = Image.new("RGB", (W, 520), BG)
for i, n in enumerate(["splash", "login"]):
    im = Image.open("%s/en/%s.png" % (shots, n)).resize((270, 480))
    hero.paste(im, (40 + i * 290, 20))
city = Image.open("%s/desktop/en/city.png" % shots).resize((853, 480))
hero.paste(city, (640, 20))
cityfa = Image.open("%s/desktop/fa/city.png" % shots).resize((853, 480))
hero.paste(cityfa, (1510, 20))
parts.append(hero)
parts.append(section("Buildings — places (Kenney city kits, composed per content key)", load("place_*.png"), (300, 300), 7))
parts.append(section("Companies — company types (new types fall back to company:*)", load("company_*.png"), (300, 300), 7))
parts.append(section("Vehicles & homes", load("vehicle_*.png") + load("home_*.png") + load("decor_*.png"), (220, 220), 10))
badges = Image.open(os.path.join(tiles, "_badges.png"))
bs = Image.new("RGB", (W, badges.height + 100), BG)
d = ImageDraw.Draw(bs)
d.rounded_rectangle([12, 8, W - 12, bs.height - 8], 14, fill=PANEL, outline=LINE, width=2)
d.text((36, 22), "Icons — game-icons.net glyphs on badges (stats, resources, items, places, actions)", font=font(34), fill=TXT)
bs.paste(badges, ((W - badges.width) // 2, 80), badges.convert("RGBA"))
parts.append(bs)
ui = [(n, Image.open("%s/%s/%s.png" % (shots, l, n))) for l, n in
      [("en", "city"), ("fa", "inventory"), ("en", "market"), ("en", "companies"), ("fa", "crime"), ("en", "education"),
       ("en", "company"), ("fa", "profile"), ("en", "menu"), ("fa", "credits")]]
parts.append(section("UI — screens (phone)", ui, (216, 384), 10))
ui2 = [(n, Image.open("%s/desktop/%s/%s.png" % (shots, l, n))) for l, n in [("en", "market"), ("fa", "companies"), ("en", "crime")]]
parts.append(section("UI — desktop", ui2, (760, 428), 3))
H = sum(p.height for p in parts)
sheet = Image.new("RGB", (W, H), BG)
y = 0
for p in parts:
    sheet.paste(p, (0, y))
    y += p.height
sheet.save(out, optimize=True)
print(out, sheet.size)
