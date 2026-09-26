#!/usr/bin/env python3
"""Grid of images for review: dev/grid.py out.png cols cell_w bg_hex files..."""
import sys
from PIL import Image
out, cols, cw, bg = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
files = sys.argv[5:]
ims = [Image.open(f).convert("RGBA") for f in files]
ch = max(int(i.height * cw / i.width) for i in ims)
rows = (len(ims) + cols - 1) // cols
c = tuple(int(bg[i:i + 2], 16) for i in (0, 2, 4)) + (255,)
s = Image.new("RGBA", (cols * cw, rows * ch), c)
for k, im in enumerate(ims):
    im = im.resize((cw, int(im.height * cw / im.width)), Image.LANCZOS)
    s.alpha_composite(im, ((k % cols) * cw, (k // cols) * ch + ch - im.height))
s.convert("RGB").save(out)
