#!/usr/bin/env bash
# Download the art sources (Kenney kits, CC0; game-icons.net, CC BY 3.0) into
# tools/kenney/, in parallel, retrying; each zip is verified with `unzip -t`.
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="$HERE/../kenney"
mkdir -p "$DEST" && cd "$DEST" || exit 1
while read -r u; do
  [ -z "$u" ] && continue
  f=$(basename "$u")
  ( for t in $(seq 1 20); do
      curl -sL -C - --max-time 900 -o "$f" "$u" && unzip -tq "$f" >/dev/null 2>&1 && { echo "ok $f $(stat -c %s "$f")"; break; }
    done ) &
done < "$HERE/sources.txt"
wait
