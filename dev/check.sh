#!/usr/bin/env bash
# Parse-checks every GDScript file (headless). Usage: dev/check.sh [files...]
cd "$(dirname "$0")/.."
GODOT=${GODOT:-./tools/godot}
files=("$@")
[ ${#files[@]} -eq 0 ] && mapfile -t files < <(find src tests dev -name '*.gd' | sort)
fail=0
for f in "${files[@]}"; do
  out=$("$GODOT" --headless --check-only --script "$f" 2>&1 | grep -E "SCRIPT ERROR|ERROR:|at: " | grep -v "Failed to load script\|Failed to create an autoload" )
  if [ -n "$out" ]; then echo "== $f"; echo "$out" | head -8; fail=1; fi
done
exit $fail
