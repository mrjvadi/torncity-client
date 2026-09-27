# Design system

The interface's look is set in two places:

- the tokens, in the `"ui"` block of `assets/art/palette.json`;
- the builders, in `src/autoload/app_theme.gd` (`AppTheme`).

Change a token and every screen follows. Screens never hard-code a colour.
They ask `AppTheme.col("<token>")`, use a theme variation, or tint a card
with `GlowPanel.tint_with(colour)`.

The art keeps its own colours (the `"colors"` block, see `art-style.md`).
The interface reads its tokens over them, so the city can be as colourful as
it likes while the chrome stays quiet.

## Principles

- **The city carries the colour, the interface stays dark and flat.** Cards
  are near-flat surfaces with a hairline border and a soft shadow. There is no
  gloss, no bevel and no lip.
- **One loud thing per screen.** Only the primary action is filled
  turquoise. Buttons that repeat down a list (Buy, Sell, Enrol) are *tonal*:
  a tint of their colour on the surface.
- **Colour means something.** Turquoise means act, gold means money, red
  means danger or loss, green means success or gain. Domain colours (bank
  lapis, crime red, education violet...) only wash hero cards and badges.
- **Thumb first.** Five tabs, a one-row HUD, and the primary action pinned
  above the tab bar.
- **Right-to-left is the default.** Persian is the first language. Anything
  placed by hand (drawers, sheets) is checked in both directions.

## Tokens (`palette.json` → `"ui"`)

| Token | Use |
|---|---|
| `bg`, `bg_top` | the app background (a vertical gradient, `AppTheme.backdrop()`) and wells (inputs, segmented tracks) |
| `surface` | cards |
| `surface_2` | raised: tonal and ghost buttons, chips, toasts, menu hover |
| `surface_3` | pressed and selected (the selected segment) |
| `stroke`, `stroke_hi` | hairline borders; the stronger one for controls |
| `text`, `text_2`, `text_3` | primary text, secondary (labels, captions), tertiary (placeholders, disabled) |
| `primary`, `primary_hi`, `primary_lo`, `on_primary` | turquoise, the one action; hover, pressed, and the text on it |
| `gold`, `gold_lo`, `on_gold` | money, buying, rewards |
| `danger`, `danger_lo` | irreversible actions, losses, alerts |
| `success`, `warning`, `info` | gains and done; caution; neutral information |

The older interface names (`night`, `panel`, `panel_hi`, `line`,
`text_dim`) are aliases of the new ones, so nothing breaks while code
migrates.

## Scale (`AppTheme` constants, in 720 × 1280 design pixels)

- **Type** (Vazirmatn): `SIZE_CAPTION` 18, `SIZE_SMALL` 21, `SIZE_BODY` 25,
  `SIZE_HEAD` 28, `SIZE_TITLE` 34, `SIZE_HUGE` 50.
- **Label variations:** `TitleLabel`, `HeadLabel`, `SmallLabel`, `DimLabel`,
  `CaptionLabel`, `HugeLabel`, `MoneyLabel` (gold).
- **Radii:** `R_CARD` 24 (cards, sheets), `R_CONTROL` 18 (buttons, inputs),
  `R_SMALL` 12 (badges, rows). Chips are full pills.
- **Spacing:** `GUTTER` 24 (the screen's side margin), `GAP` 16 (between
  cards).

## Components

| Piece | Where | Notes |
|---|---|---|
| Buttons | theme variations | `Button` (primary, filled turquoise), `GoldButton` (pay, buy), `DangerButton`, `GhostButton` and `ActionButton` (tonal surface), `TonalPrimary`, `TonalGold` and `TonalDanger` (list rows, via `GameScreen.pill`), `SegmentButton` (the selected segment), `NavButton` (flat) |
| Card | `GlowPanel` | `tint_with(colour, amount)` for hero cards; `accent` draws a short bar on the reading-start end of the top edge |
| Glass | `GlassPanel` | only for chrome floating over the city (HUD, tab bar, map sheets) |
| HUD | `Hud` | phone: one row with the avatar, cash, energy, health, bell and menu; desktop sidebar: a player card with the bank |
| Tab bar | `BottomNav` | five tabs; the active one gets a soft turquoise pill and a bright top bar, with a turquoise icon and label |
| App bar | `GameScreen.title_row` | back (or the domain badge) at the start, the title, refresh at the end |
| Drawer | `SideMenu` in `Shell.toggle_drawer` | the player on top, then the inventory, the server's menu and the app settings |
| Toast | `ToastLayer` | a `surface_2` card, bordered and accented in the kind's colour |
| Confirm | `ConfirmSheet` | a bottom sheet; the danger button is filled red |

## Checking a change

```sh
dev/screenshots.sh                        # every screen, fa and en, 720 x 1280
SIZE=1600x900 dev/screenshots.sh --out=docs/screenshots/desktop
python3 dev/sheet.py sheet.png docs/screenshots/fa/*.png
```

Look at both languages: a layout that is right in English can be mirrored
off screen in Persian.
