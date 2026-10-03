#!/usr/bin/env bash
# Builds the six court bodies one Blender run at a time, taking the shared
# machine lock (C:/Users/sjpur/tt-court-lock) for each run and releasing it
# between bodies, so no run holds the machine for more than a few minutes.
#   bash tools/blender/build_all.sh [variant ...]
cd "$(dirname "$0")/../.." || exit 1
BLENDER="/c/Program Files/Blender Foundation/Blender 5.2/blender.exe"
VARIANTS=${@:-male_adult female_adult male_old female_old male_young female_young}
mkdir -p reports/court_figures
for v in $VARIANTS; do
  until mkdir /c/Users/sjpur/tt-court-lock 2>/dev/null; do sleep 20; done
  echo "J court_figures build $v" > /c/Users/sjpur/tt-court-lock/owner.txt
  "$BLENDER" --background --factory-startup --python tools/blender/court_figures.py -- --variants "$v" --out assets/court_figures > "reports/court_figures/build_$v.log" 2>&1
  rm -rf /c/Users/sjpur/tt-court-lock
  grep -E "exported|Traceback|Error" "reports/court_figures/build_$v.log" | tail -2
done
echo "build_all done"
