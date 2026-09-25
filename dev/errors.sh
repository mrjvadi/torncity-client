#!/usr/bin/env bash
# Compiles every script with the autoloads loaded; prints each error once with its location.
cd "$(dirname "$0")/.."
timeout 180 ${GODOT:-./tools/godot} --headless -s dev/compile_all.gd 2>&1 | awk '/SCRIPT ERROR/{e=$0; getline; print e " @ " $0}' | sed 's/SCRIPT ERROR: //; s/  */ /g' | sort -u
