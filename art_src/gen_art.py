#!/usr/bin/env python3
"""Regenerates every SVG under assets/art from code.

    python3 art_src/gen_art.py            # everything
    python3 art_src/gen_art.py places     # one group: places icons avatars character brand ui tiles

Colours come from assets/art/palette.json. See docs/art-style.md.
"""
import sys

import places

GROUPS = {"places": places.build}

try:
    import icons
    GROUPS["icons"] = icons.build
except ImportError:
    pass
try:
    import avatars
    GROUPS["avatars"] = avatars.build
except ImportError:
    pass
try:
    import misc
    GROUPS["character"] = misc.build_character
    GROUPS["brand"] = misc.build_brand
    GROUPS["ui"] = misc.build_ui
    GROUPS["tiles"] = misc.build_tiles
except ImportError:
    pass


def main(argv):
    wanted = argv[1:] or list(GROUPS)
    total = 0
    for g in wanted:
        files = GROUPS[g]()
        total += len(files)
        print("%-10s %3d files" % (g, len(files)))
    print("done: %d files" % total)


if __name__ == "__main__":
    main(sys.argv)
