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
DISPLAY=$DISP "$GODOT" --path . --rendering-driver opengl3 --resolution 720x1280 --position 0,0 res://dev/screenshots.tscn -- "$@" 2>&1 | grep -E "shot |ERROR|SCRIPT" | head -60
[ -n "$XPID" ] && kill $XPID
