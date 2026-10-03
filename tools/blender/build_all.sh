#!/usr/bin/env bash
# Builds the court bodies, one Blender run per body, under the shared machine
# lock (C:/Users/sjpur/tt-court-lock). The lock is taken ONCE for the whole
# build and only when nobody holds it (mkdir fails if the directory exists;
# nothing here ever writes into a lock another worker holds). It is released
# at the end only if the owner file is still ours. A whole build of six
# bodies takes about 15 minutes: build only the bodies that changed.
#   bash tools/blender/build_all.sh [variant ...]
cd "$(dirname "$0")/../.." || exit 1
BLENDER="/c/Program Files/Blender Foundation/Blender 5.2/blender.exe"
LOCK=/c/Users/sjpur/tt-court-lock
ME="J court_figures build $$ $(date +%H:%M:%S)"
VARIANTS=${@:-male_adult female_adult male_old female_old male_young female_young}
mkdir -p reports/court_figures
until mkdir "$LOCK" 2>/dev/null; do
  echo "lock held by: $(cat "$LOCK/owner.txt" 2>/dev/null)"; sleep 20
done
echo "$ME ($VARIANTS)" > "$LOCK/owner.txt"
release() {
  if [ "$(head -c ${#ME} "$LOCK/owner.txt" 2>/dev/null)" = "$ME" ]; then rm -rf "$LOCK"; fi
}
trap release EXIT
for v in $VARIANTS; do
  "$BLENDER" --background --factory-startup --python tools/blender/court_figures.py -- --variants "$v" --out assets/court_figures > "reports/court_figures/build_$v.log" 2>&1
  grep -E "exported|Traceback|Error" "reports/court_figures/build_$v.log" | tail -2
done
echo "build_all done"
