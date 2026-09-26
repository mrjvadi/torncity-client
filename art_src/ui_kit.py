#!/usr/bin/env python3
"""The UI kit as 9-slice PNG textures (assets/ui/*.png), drawn with PIL at 4x
and downsampled so edges are anti-aliased. AppTheme turns each into a
StyleBoxTexture with the margins listed in assets/ui/kit.json.

    python3 art_src/ui_kit.py
"""
import json
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "ui")
with open(os.path.join(ROOT, "assets", "art", "palette.json"), encoding="utf-8") as fh:
    PAL = json.load(fh)["colors"]
SS = 4


def hexa(h, a=255):
    h = PAL.get(h, h).lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def rounded_mask(w, h, r, inset=0):
    m = Image.new("L", (w * SS, h * SS), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([inset * SS, inset * SS, (w - inset) * SS - 1, (h - inset) * SS - 1], radius=r * SS, fill=255)
    return m


def gradient(w, h, top, bottom):
    g = Image.new("RGBA", (w * SS, h * SS))
    px = g.load()
    for y in range(h * SS):
        c = mix(top, bottom, y / max(1, h * SS - 1))
        for x in range(w * SS):
            px[x, y] = c
    return g


def frame(name, w, h, r, top, bottom, border, glow=None, lip=None, shadow=0, border_w=1):
    """A rounded panel/button face: gradient fill, border, inner glow, lip."""
    pad = shadow
    W, H = w + 2 * pad, h + 2 * pad
    img = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    if shadow:
        sh = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
        m = rounded_mask(w, h, r)
        sh.paste((2, 6, 14, 150), (pad * SS, (pad + 2) * SS), m)
        sh = sh.filter(ImageFilter.GaussianBlur(shadow * SS / 2.2))
        img.alpha_composite(sh)
    face = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
    # border: the whole shape in the border colour, then the fill inset by border_w
    face.paste(border, (0, 0), rounded_mask(w, h, r))
    fill = gradient(w, h, top, bottom)
    face.paste(fill, (0, 0), rounded_mask(w, h, r - border_w, border_w))
    if lip:  # a darker bottom edge (buttons)
        lipimg = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
        lipimg.paste(lip, (0, 0), rounded_mask(w, h, r - border_w, border_w))
        cut = Image.new("L", (w * SS, h * SS), 0)
        ImageDraw.Draw(cut).rectangle([0, (h - 4) * SS, w * SS, h * SS], fill=255)
        lm = Image.new("L", (w * SS, h * SS), 0)
        lm.paste(rounded_mask(w, h, r - border_w, border_w), (0, 0), cut)
        face.paste(lip, (0, 0), lm)
    if glow:  # inner glow: a soft light line along the top inside edge
        gl = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
        d = ImageDraw.Draw(gl)
        d.rounded_rectangle([(border_w + 1) * SS, (border_w + 1) * SS, (w - border_w - 1) * SS, (h - border_w - 1) * SS],
                            radius=(r - 1) * SS, outline=glow, width=int(1.5 * SS))
        gl = gl.filter(ImageFilter.GaussianBlur(1.5 * SS))
        fade = Image.new("L", (w * SS, h * SS), 0)
        fd = ImageDraw.Draw(fade)
        for y in range(h * SS):
            fd.line([(0, y), (w * SS, y)], fill=int(255 * max(0.0, 1.0 - y / (h * SS * 0.5))))
        gl.putalpha(_mul(gl.split()[3], fade))
        face.alpha_composite(gl)
    img.alpha_composite(face, (pad * SS, pad * SS))
    img = img.resize((W, H), Image.LANCZOS)
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name + ".png"))
    return {"margin": r + border_w + pad + 2, "shadow": pad}


def _mul(a, b):
    from PIL import ImageChops
    return ImageChops.multiply(a, b)


def main():
    kit = {}
    navy_top, navy_bot = hexa("#1A2A43"), hexa("#0F1A2B")
    border = hexa("#2B4468")
    glow = hexa("#4A6FA5", 160)
    kit["panel"] = frame("panel", 48, 48, 8, navy_top, navy_bot, border, glow, shadow=6)
    kit["panel_flat"] = frame("panel_flat", 40, 40, 8, hexa("#16243A"), hexa("#132035"), border, glow)
    kit["panel_header"] = frame("panel_header", 40, 40, 8, hexa("#1F3252"), hexa("#18294A"), hexa("#35557F"), hexa("#6A8FC7", 140))
    kit["slot"] = frame("slot", 40, 40, 8, hexa("#0B1422"), hexa("#101C2E"), hexa("#22375A"), hexa("#2F4A74", 110))
    kit["slot_selected"] = frame("slot_selected", 40, 40, 8, hexa("#0E1A2C"), hexa("#12213A"), hexa("#2F80ED"), hexa("#56CCF2", 170))
    kit["input"] = frame("input", 40, 40, 8, hexa("#0A1320"), hexa("#0D1827"), hexa("#2B4468"))
    kit["input_focus"] = frame("input_focus", 40, 40, 8, hexa("#0A1320"), hexa("#0D1827"), hexa("#2F80ED"))
    kit["chip"] = frame("chip", 32, 32, 8, hexa("#1D2F4B"), hexa("#18283F"), hexa("#2B4468"))
    kit["tab_active"] = frame("tab_active", 40, 40, 8, hexa("#2F80ED"), hexa("#2566C4"), hexa("#5B9CF2"), hexa("#9CC4FA", 160))
    kit["tab_idle"] = frame("tab_idle", 40, 40, 8, hexa("#16243A"), hexa("#132035"), hexa("#2B4468"))
    for name, base in (("primary", "#2F80ED"), ("buy", "#27AE60"), ("danger", "#EB5757"), ("ghost", "#1D2F4B"), ("gold", "#F2C94C")):
        c = hexa(base)
        light = mix(c, (255, 255, 255, 255), 0.14)
        dark = mix(c, (0, 0, 0, 255), 0.22)
        edge = mix(c, (255, 255, 255, 255), 0.3) if name != "ghost" else hexa("#2B4468")
        g = mix(c, (255, 255, 255, 255), 0.55)
        g = (g[0], g[1], g[2], 150)
        kit["btn_%s_normal" % name] = frame("btn_%s_normal" % name, 48, 44, 8, light, c, edge, g, lip=dark)
        kit["btn_%s_hover" % name] = frame("btn_%s_hover" % name, 48, 44, 8, mix(light, (255, 255, 255, 255), 0.08), mix(c, (255, 255, 255, 255), 0.06), edge, g, lip=dark)
        kit["btn_%s_pressed" % name] = frame("btn_%s_pressed" % name, 48, 44, 8, dark, mix(c, (0, 0, 0, 255), 0.1), edge)
        kit["btn_%s_disabled" % name] = frame("btn_%s_disabled" % name, 48, 44, 8, mix(c, hexa("#16243A"), 0.7), mix(c, hexa("#0F1A2B"), 0.75), hexa("#2B4468"))
    with open(os.path.join(OUT, "kit.json"), "w") as fh:
        json.dump(kit, fh, indent=1)
    print("ui kit:", len(kit), "textures")


if __name__ == "__main__":
    main()
