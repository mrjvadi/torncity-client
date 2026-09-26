# Architecture

The client is a thin, good-looking view of a game that lives on the server.
It never decides a rule: it sends a command, draws the answer, and reacts to
realtime events.

## The contract (v1)

| Call | Use |
|---|---|
| `POST /api/v1/auth/link {code, device_name}` | sign in with the bot's `/link` code |
| `POST /api/v1/auth/telegram {init_data}` | sign in inside a Telegram Mini App |
| `POST /api/v1/auth/refresh {refresh_token}` | new token pair (the refresh token rotates) |
| `POST /api/v1/auth/logout` | revoke the refresh token |
| `GET /api/v1/bootstrap` | player, city, localised city/place/mode names, languages |
| `POST /api/v1/command {command, args, idempotency_key}` | run a game command; answer `{ok, screen, text, view, actions, notice?, error?}` |
| `GET /api/v1/realtime/token` | Centrifugo connection token (server subscribes `player:<id>`) |
| `GET /api/v1/realtime/subscribe?channel=city:<code>` | subscription token for the city channel |

Access tokens last 15 minutes. `Api` refreshes before expiry
(`TokenLogic.needs_refresh`, 30 s early) and once more after any 401; if the
refresh is refused the session ends and the link screen returns.

## Autoloads

| Autoload | Role |
|---|---|
| `Config` | layered settings: `config/client.cfg` < `client.local.cfg` < `user://client.cfg` < command line < web query |
| `I18n` | language, shell strings (`i18n/*.po`), digits and layout direction |
| `AppTheme` | palette, fonts, the Godot `Theme`, and the art resolver (`assets/art/manifest.json`) |
| `Mock` | offline server: same routes and shapes, plus a Centrifugo loopback |
| `Session` | tokens (encrypted file), player, bootstrap names, HUD vitals, notice feed |
| `Api` | HTTP with auth and refresh; `command()` returns the response body |
| `Realtime` | Centrifugo client (below) |
| `TelegramApp` | Mini App bridge: initData, ready/expand, theme, safe-area insets |
| `Game` | boot (sign-in decision), run commands, back stack, route events |

## Screens are driven by the server

`ViewRouter.scene_for(screen, view)` picks the client screen: `profile`,
`dashboard`, `city_map`, `cities`, `travel_options`, `travel_status`, `bank`,
`inventory`, `job_status` and `life` have native scenes when a `view` is
present; everything else — and any answer without a view — is drawn by
`screens/card.gd` from `text` and `actions`. An action is `{label, command,
args}`; pressing it sends exactly that back. An action with `input:{field,text}`
first asks the player for a value. `screen:"notice"` is shown as a toast over
the current screen; `screen:"error"` too, as an error toast.

Server text uses one emoji "anchor" per line (the locale glossary). The client
draws those with its own icon set (`TextIcons`), so no emoji font is shipped.

## Realtime (Centrifugo, JSON protocol)

Implemented from the official protocol description
(centrifugal.dev/docs/transports/client_protocol, client.proto, and the codes
reference):

- one command per JSON object, several per frame joined with `\n`;
  replies echo the command `id`; a message without `id` is a push;
- `connect {token, name, version}` first; server-side subscriptions (the
  personal channel) arrive in the connect reply's `subs`;
- the server's ping is `{}`; the client answers `{}` when the connect result
  said `pong: true`; no frame for `ping + 10 s` means a dead link;
- `subscribe {channel, token}` for `city:<code>`, switched when the player
  changes city; `unsubscribe` pushes with code ≥ 2500 resubscribe;
- `refresh {token}` before the connection token's `ttl`, `sub_refresh` for
  the city subscription; error 109 (token expired) fetches a new token;
- reconnect with exponential backoff and full jitter (0.5 s to 20 s), except
  after terminal close codes 3500–3999 and 4500–4999.

Messages: `{type:"notice", kind, text, view?}` on the personal channel (toast +
feed; a `view` updates the HUD; arrivals land the walker on the map) and
`{type:"announce", text, texts?}` on the city channel.

## Sign-in decision (`AuthFlow.decide`)

1. A stored refresh token → renew silently (Mini App sign-in data is single
   use, so after the first sign-in the refresh token keeps the player in).
2. Else, inside Telegram with signed `initData` → `POST /auth/telegram`.
3. Else → the link-code screen.

If a refresh is refused inside Telegram, `initData` is tried next.

## Telegram Mini App (web build)

`export_presets.cfg` injects `telegram-web-app.js` into the page `<head>`
through the Web preset's `html/head_include`, as Telegram's docs require.
`TelegramApp` reads `window.Telegram.WebApp` through `JavaScriptBridge`, calls
`ready()` and `expand()`, disables vertical swipes (so dragging the map does not
close the app), paints Telegram's header and background in the game's ink
colour, applies `safeAreaInset + contentSafeAreaInset` to the shell, and uses
`initDataUnsafe.user.language_code` only to choose the first language. Mock
mode can fake all of it (`--tg-mock`, `?tgmock=1`).

## The city map

The server knows places by walk time, not position, so `CityLayout` lays the
city out on a 4 × 4 grid of 100-unit lots with 30-unit roads, in the same 2:1
isometric projection the place art is drawn in. Known place codes have fixed
lots (airport and industry at the back, homes and the park in front); unknown
codes take free lots; empty lots get a plaza or a green. The walker follows the
roads (`CityLayout.route`) and is depth-sorted between lot rows. The sky,
mountains (parallax), clouds, water and traffic are drawn in code; the tint
follows the time of day in Tehran.

## Performance (Telegram WebView)

- Compatibility renderer (WebGL 2), no threads (no cross-origin isolation
  needed), 2D only.
- Screens and art load lazily per screen; the map draws ground, roads and
  traffic procedurally instead of shipping tiles.
- Rendered place sprites are 512 px (2× the art space) PNGs with mipmaps; the
  vector originals stay as fallbacks.
- Fonts are WOFF2 (four weights of Vazirmatn, ~200 KB).


## Data-driven client

The client holds no game content: no item, place, city, company type, price or
which-buttons list. It owns only the visual library, the UI components and the
generic renderers.

### Content catalogue — `GET /api/v1/content?since=<version>`

Cached in `user://content.json`; refetched on start and on a realtime
`{type:"content", version}` message. Shape the client needs:

```json
{
  "version": "2026-09-26#42",
  "langs": ["fa", "en"],
  "entries": {
    "city":         [{"code": "fenwick_span", "name": {"fa": "فنویک اسپن", "en": "Fenwick Span"}, "asset": {"icon": "city:fenwick_span"}}],
    "place":        [{"code": "bazaar", "name": {...}, "kind": "place", "asset": {"model": "place:bazaar", "icon": "place:bazaar"}}],
    "company_type": [{"code": "factory", "name": {...}, "asset": {"model": "company:factory", "icon": "company:factory"}}],
    "item":         [{"code": "pistol", "name": {...}, "category": "weapon", "asset": {"icon": "item:pistol"}}],
    "service":      [{"code": "bank", "name": {...}, "asset": {"icon": "service:bank"}}],
    "mode":         [{"code": "flight", "name": {...}, "asset": {"icon": "mode:flight"}}],
    "vehicle": [...], "crime": [...], "course": [...], "military_unit": [...]
  },
  "ui": {"tabs": [{"key": "market", "label": {"fa": "بازار", "en": "Market"}, "command": "market.list", "icon": "nav:market"}]}
}
```

An up-to-date client gets `{"version": "…", "unchanged": true}`. `category`
(items) and `kind` (places) are used for icon fallbacks. Any table name works.

### World — `GET /api/v1/world/city?code=<city>`

```json
{"city": "fenwick_span", "version": 12, "grid": {"w": 16, "h": 16}, "water": {"side": "south", "width": 6},
 "roads": [[0, 0], [1, 0], ...],
 "plots": [{"id": "company:1027", "x": 4, "y": 7, "w": 2, "h": 2, "kind": "company", "model": "company:drone_foundry", "rot": 0,
            "ref": {"table": "company_type", "code": "drone_foundry", "company_id": 1027, "owner": "Sara"},
            "name": {"fa": "پرواز نو", "en": "New Flight Drones"}}]}
```

Kinds: `place | company | home | decor`. Updates on `city:<code>`:
`{type:"world.plot", city, op:"upsert", plot}` or `{…, op:"remove", id}`. A tap on
a company plot sends `company.show {id}`; on a place, the place sheet shows the
server's own actions for it (`args.place`).

### Actions and views

Actions: `{command, args, label, kind, icon, group}` —
`kind: primary | secondary | danger | confirm | navigation | back | refresh`,
`icon`: an asset key (`action:work`), `group`: a heading for tiles, or `"rows"` for
per-row actions a native screen places on its rows (matched by args: `listing`,
`item`, `id`, `crime`, `course`, `place`). Until the server sends `kind`/`icon`,
the client infers them (ActionKit). Placement: primary → pinned CTA; back/refresh
→ header; danger/confirm → confirm sheet; the rest → icon tile grid.

Native views (mock fixtures today, `src/mock/mock_server.gd`):
`market {buy: [{id, item, price, qty, seller, change}], sell: [{item, qty, best_bid}], fee_bps}`,
`company_list {companies: [{id, name, type, level, staff, cash, producing: {item, progress, eta_seconds, per_hour}}]}`,
`crime_hub {heat, jail_seconds, crimes: [{crime, chance, energy, reward, cooldown_seconds}]}`,
`education {intelligence, courses: [{course, status, progress, seconds_left, fee}]}`.
Anything else renders through the generic screen (hero + parsed cards + tile grid).

Runtime art: see [assets.md](assets.md).
