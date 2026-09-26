#!/usr/bin/env bash
# Renders docs/screenshots/{fa,en}/*.png. Uses $DISPLAY_FOR_SHOTS, or starts
# Xvfb (tools/xvfb/root/usr/bin/Xvfb if installed there, else the system one).
cd "$(dirname "$0")/.."
GODOT=${GODOT:-./tools/godot}
XVFB=$(command -v Xvfb || echo tools/xvfb/root/usr/bin/Xvfb)
DISP=${DISPLAY_FOR_SHOTS:-:97}
if ! [ -e /tmp/.X11-unix/X${DISP#:} ]; then
  "$XVFB" "$DISP" -screen 0 1600x1600x24 -nolisten tcp >/dev/null 2>&1 &
  XPID=$!
  sleep 2
fi
"$GODOT" --headless --path . --import >/dev/null 2>&1
# the art comes from the CDN: serve dist-assets/ like it (build it first if missing)
[ -f dist-assets/manifest.json ] || python3 tools/build_assets/build.py >/dev/null
python3 tools/build_assets/serve.py --port 8090 >/dev/null 2>&1 &
SPID=$!
sleep 0.5
DISPLAY=$DISP "$GODOT" --path . --rendering-driver opengl3 --resolution ${SIZE:-720x1280} --position 0,0 res://dev/screenshots.tscn -- "$@" 2>&1 | grep -vE "triangulation|^Godot|^OpenGL|^$" | head -60
kill $SPID 2>/dev/null
[ -n "$XPID" ] && kill $XPID
