#!/usr/bin/env bash
# Run Godot with a real renderer under Xvfb: dev/xrun.sh <godot args...>
cd "$(dirname "$0")/.."
GODOT=${GODOT:-./tools/godot}
XVFB=$(command -v Xvfb || echo tools/xvfb/root/usr/bin/Xvfb)
DISP=${DISPLAY_FOR_SHOTS:-:96}
if ! [ -e /tmp/.X11-unix/X${DISP#:} ]; then
  "$XVFB" "$DISP" -screen 0 2400x1600x24 -nolisten tcp >/dev/null 2>&1 &
  XPID=$!
  sleep 2
fi
DISPLAY=$DISP "$GODOT" --path . --rendering-driver opengl3 "$@" 2>&1 | grep -vE "triangulation|^Godot|^OpenGL|^$|xic|V-Sync|at: "
[ -n "$XPID" ] && kill $XPID
