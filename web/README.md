# Files served next to the web export

`telegram-web-app.js` is Telegram's Mini App script
(https://telegram.org/js/telegram-web-app.js), served from the game's own
origin. The page loads it synchronously in `<head>` (Telegram's docs require
it before anything else runs), and where telegram.org is filtered the
browser waited up to ~40 s for it with the whole page frozen, so a player
without a VPN never got past the splash. Copy it next to `index.html` after
every export; refresh the copy when Telegram updates the script.
