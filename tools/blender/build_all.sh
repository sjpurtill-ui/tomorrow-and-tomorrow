#!/usr/bin/env bash
# Builds the court bodies, one Blender run per body, each under the shared
# Blender lock (C:/Users/sjpur/tt-court-lock-blender). The lock is taken only
# when nobody holds it (mkdir fails if the directory exists; nothing here ever
# writes into a lock another worker holds), held for ONE body (about three
# minutes, never more than ten), and released only if the owner line is still
# ours, so others get the machine between bodies.
#   bash tools/blender/build_all.sh [variant ...]
cd "$(dirname "$0")/../.." || exit 1
BLENDER="/c/Program Files/Blender Foundation/Blender 5.2/blender.exe"
LOCK=/c/Users/sjpur/tt-court-lock-blender
VARIANTS=${@:-male_adult female_adult male_old female_old male_young female_young child}
mkdir -p reports/court_figures
ME=""
release() {
  if [ -n "$ME" ] && [ "$(cat "$LOCK/owner.txt" 2>/dev/null)" = "$ME" ]; then rm -rf "$LOCK"; fi
  ME=""
}
trap release EXIT
for v in $VARIANTS; do
  until mkdir "$LOCK" 2>/dev/null; do
    echo "blender lock held by: $(cat "$LOCK/owner.txt" 2>/dev/null)"; sleep 20
  done
  ME="J court_figures build $v $$ $(date +%H:%M:%S)"
  echo "$ME" > "$LOCK/owner.txt"
  timeout 600 "$BLENDER" --background --factory-startup --python tools/blender/court_figures.py -- --variants "$v" --out assets/court_figures > "reports/court_figures/build_$v.log" 2>&1
  release
  grep -E "exported|Traceback|Error" "reports/court_figures/build_$v.log" | tail -2
done
echo "build_all done"
