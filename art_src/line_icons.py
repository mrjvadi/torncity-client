"""Line icons for navigation (tab bar, side menu, action grid): 48 x 48, a
2.6 px round stroke in one colour (white; the UI tints them), no fills.
Written to assets/art/icons/ln_<name>.svg.
"""
from svgkit import Svg

S = 48
SW = 2.6


def ic(*paths, circles=(), dots=()):
    s = Svg(S, S)
    for d in paths:
        s.path(d, "none", stroke="#FFFFFF", sw=SW)
    for cx, cy, r in circles:
        s.circle(cx, cy, r, "none", stroke="#FFFFFF", sw=SW)
    for cx, cy, r in dots:
        s.circle(cx, cy, r, "#FFFFFF")
    return s


LINE = {
    "world": lambda: ic("M6 24 H42 M24 6 C16 14 16 34 24 42 C32 34 32 14 24 6", circles=[(24, 24, 18)]),
    "map": lambda: ic("M6 12 L17 8 L31 13 L42 9 V36 L31 40 L17 35 L6 39 Z M17 8 V35 M31 13 V40"),
    "companies": lambda: ic("M8 42 V16 H22 V42 M22 42 V8 H40 V42 M4 42 H44 M12 22 H18 M12 29 H18 M27 15 H35 M27 22 H35 M27 29 H35"),
    "market": lambda: ic("M6 8 H11 L16 32 H37 L42 14 H13", circles=[(18, 39, 3), (35, 39, 3)]),
    "inventory": lambda: ic("M10 16 H38 L36 42 H12 Z M17 16 C17 8 31 8 31 16 M18 26 H30"),
    "messages": lambda: ic("M6 10 H42 V32 H22 L13 40 V32 H6 Z M13 18 H35 M13 25 H28"),
    "profile": lambda: ic("M8 42 C8 32 15 28 24 28 C33 28 40 32 40 42", circles=[(24, 16, 8)]),
    "home": lambda: ic("M6 22 L24 7 L42 22 M11 18 V41 H37 V18 M20 41 V29 H28 V41"),
    "missions": lambda: ic("M12 6 H36 V42 H12 Z M17 15 L20 18 L25 13 M28 16 H32 M17 26 L20 29 L25 24 M28 27 H32 M17 36 H32"),
    "settings": lambda: ic("M24 5 V11 M24 37 V43 M5 24 H11 M37 24 H43 M10.5 10.5 L14.8 14.8 M33.2 33.2 L37.5 37.5 M37.5 10.5 L33.2 14.8 M14.8 33.2 L10.5 37.5",
                           circles=[(24, 24, 9)]),
    "bank": lambda: ic("M5 18 L24 7 L43 18 Z M9 22 V36 M17 22 V36 M31 22 V36 M39 22 V36 M5 41 H43"),
    "work": lambda: ic("M6 16 H42 V40 H6 Z M17 16 V10 H31 V16 M6 26 H42 M22 26 V30 H26 V26"),
    "life": lambda: ic("M24 41 C8 30 6 22 8 15 C11 7 21 8 24 14 C27 8 37 7 40 15 C42 22 40 30 24 41 Z M11 24 H17 L20 18 L25 30 L28 24 H37"),
    "skills": lambda: ic("M8 40 L26 22 M30 6 C24 8 22 14 25 19 L31 25 C36 28 42 24 42 18 L36 24 L30 18 Z"),
    "education": lambda: ic("M4 18 L24 9 L44 18 L24 27 Z M12 22 V33 C18 38 30 38 36 33 V22 M44 18 V30"),
    "crime": lambda: ic("M4 20 C10 14 18 14 24 20 C30 14 38 14 44 20 C44 30 36 34 30 30 C27 28 25 26 24 26 C23 26 21 28 18 30 C12 34 4 30 4 20 Z",
                        dots=[(15, 22, 2.6), (33, 22, 2.6)]),
    "property": lambda: ic("M6 42 V20 L18 12 L30 20 V42 M30 42 V16 H42 V42 M4 42 H44 M14 42 V32 H22 V42"),
    "health": lambda: ic("M19 6 H29 V19 H42 V29 H29 V42 H19 V29 H6 V19 H19 Z"),
    "factions": lambda: ic("M10 42 V6 M10 8 H38 L32 17 L38 26 H10"),
    "friends": lambda: ic("M4 40 C4 31 10 27 17 27 C24 27 30 31 30 40 M28 27 C34 26 44 29 44 38", circles=[(17, 16, 7), (32, 14, 6)]),
    "government": lambda: ic("M8 18 H40 M10 18 V36 M18 18 V36 M30 18 V36 M38 18 V36 M6 40 H42 M8 18 L24 8 L40 18"),
    "menu": lambda: ic("M8 13 H40 M8 24 H40 M8 35 H40"),
    "attack": lambda: ic("M10 38 L34 14 L38 6 L30 10 L6 34 M8 28 L20 40 M6 42 L12 36"),
    "travel": lambda: ic("M6 30 L42 14 C44 13 45 16 43 17 L16 30 L10 36 H6 L10 30 Z M22 25 L14 12 H9 L15 27"),
    "produce": lambda: ic("M6 42 V22 L16 28 V22 L26 28 V22 L36 28 V10 H42 V42 Z M4 42 H44"),
    "research": lambda: ic("M18 6 H30 M20 6 V18 L8 38 C7 41 9 42 11 42 H37 C39 42 41 41 40 38 L28 18 V6 M13 30 H35"),
    "shop": lambda: ic("M8 18 H40 L37 42 H11 Z M16 18 C16 8 32 8 32 18"),
    "logout": lambda: ic("M20 8 H8 V40 H20 M18 24 H42 M34 16 L42 24 L34 32"),
    "back": lambda: ic("M30 8 L14 24 L30 40"),
    "forward": lambda: ic("M18 8 L34 24 L18 40"),
    "close": lambda: ic("M12 12 L36 36 M36 12 L12 36"),
    "plus": lambda: ic("M24 10 V38 M10 24 H38"),
    "minus": lambda: ic("M10 24 H38"),
    "locate": lambda: ic("M24 4 V12 M24 36 V44 M4 24 H12 M36 24 H44", circles=[(24, 24, 12)], dots=[(24, 24, 4)]),
}


def build():
    return [fn().save("icons/ln_%s.svg" % name) for name, fn in LINE.items()]
