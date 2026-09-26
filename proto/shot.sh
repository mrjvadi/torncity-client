#!/usr/bin/env bash
# Renders the prototype: proto/shot.sh out.png  (or --movie out_dir for frames)
cd "$(dirname "$0")/.."
GODOT=${GODOT:-./tools/godot}
DISP=:96
Xvfb $DISP -screen 0 1600x1600x24 -nolisten tcp >/dev/null 2>&1 &
XPID=$!
sleep 1.5
if [ "$1" = "--movie" ]; then
  mkdir -p "$2"
  DISPLAY=$DISP "$GODOT" --path . --rendering-driver opengl3 --resolution 720x1280 --position 0,0 \
    --write-movie "$2/frame.png" --fixed-fps 24 --quit-after ${FRAMES:-96} res://proto/home_proto.tscn 2>&1 | grep -E "SCRIPT ERROR|ERROR: .*(gd|shader)" | head
else
  DISPLAY=$DISP "$GODOT" --path . --rendering-driver opengl3 --resolution 720x1280 --position 0,0 \
    res://proto/home_proto.tscn -- --shot="$(realpath -m "$1")" ${2:-} 2>&1 | grep -E "SCRIPT ERROR|ERROR: .*(gd|shader)|error\(" -A2 | head -30
fi
kill $XPID
