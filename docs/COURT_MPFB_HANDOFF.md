# MPFB court heads — October 4, 2026

Integrator worktree: `C:/Users/sjpur/.codex/worktrees/court-face-richness/TomorrowandTomorrow`.
Branch: `codex/court-face-richness`. Source baseline: integrated main
`895481d83e2a74f000582997b0ca469c889b0627`.
Runtime checkpoints: `807ac66201a3cd090bd17bfc0f3f706e2f2153db` and final
neck fairing `a0914eedcb156836bbfbeedf8ab51e913a7eaa53`. The worktree merges
canonical/origin main `9b41e8114e470a265818afca1f7e948f026c5d5f`, including
the concurrent production, notification and simulation-speed deliveries.

## Behavior

The earlier procedural heads still had unconvincing facial proportions. All
seven variants now use native MPFB head anatomy, including projecting noses,
nostril interiors, lips, eyelids, cheeks and folded ears. All 21 original,
LegacyBody and WardrobeBody GLBs receive the same head per variant.

The existing 33-joint game skeleton, animations, clothing and props stay intact.
Native targets map to the existing twelve identity controls, twelve expressions,
five speech shapes and four moods. Four gaze shapes rotate spherical eyes.
Blinking moves actual eyelids; eyeballs no longer flatten. Native blink strength
is calibrated to 0.78 to avoid lower-lid overtravel. Existing hairstyles and
beards are refitted, retaining their topology and authored texture coordinates.

Native eyebrow transparency uses the original hair mask. Teeth and gums retain
their original texture and UV seams in a separate TEETH material slot. Both
merged and fallback rendering support these materials. Native face geometry
bypasses the procedural relief used by older heads; skin tone, age markings and
other individual appearance colors still come from the game's existing look.

The adapter cuts the original mesh at the chin plane and retains its torso
component. Only the old male/female variants have detached chin remnants below
that plane (14 vertices each); these are replaced by the new chin. The join walks
actual boundary connectivity and preserves consistent winding. Native neck
targets blend into original boundary movement across four topological rings.
A shortest-strip triangulation pairs nearby points on the two loops, avoiding
long diagonals across hunched necks. Six constrained relaxation steps smooth
the new lower neck into the retained body; a fixed fade ends below the lips.
The same linear operator smooths expression deltas and joint weights. This
removes the visible sawtooth jaw edge without pinching the child's full-open
mouth. Original body positions, weights and morphs remain exact; only the
cut-ring normals are recomputed. There is no simulation or save-schema change.

## Sources and regeneration

`assets/court_figures/mpfb_source/provenance.json` records versions, source URLs,
recipes and hashes. Seven NPZs plus the original eyebrow and teeth textures are
CC0 assets; see the adjacent `LICENSE.md`. MPFB's software license is separate.

Regenerate the sources in a fresh background Blender 5.2 process with MPFB
enabled and the packs listed in `MPFB_SETUP.md` installed:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python tools/blender/export_court_mpfb_source.py -- --variant all
python tools/blender/graft_court_mpfb_heads.py --source-ref 895481d8
python tools/blender/validate_court_mpfb_heads.py
```

The graft requires Python and NumPy; it does not require Blender. It reads
pristine baseline Git blobs into an ignored artifact cache, appends GLB payloads,
and atomically replaces the outputs. Existing payload/accessor prefixes are
preserved. Already-grafted inputs are rejected. The fresh `court_figures.py`
Blender generator also calls the adapter before wardrobe generation.

Source worker: `codex/court-mpfb-source`, geometry checkpoint `75007726`, native
textures `fef5eca5` / `02861da7`, runtime regressions `d7db0dee`.
Independent validator: `codex/court-mpfb-validation`, final contract `acf946f3`.

## Acceptance

- `artifacts/mpfb-tests-final.log`: 129/129 cases in twelve suites on combined
  main, including all 107 court regressions and 22 incoming production and
  notification checks; zero errors, failures, skips or orphans. Covers imported native heads,
  morphs, acting blink, spherical gaze, brow UV/mask preservation, teeth,
  fallback/merged dressing, wardrobes, normal targets, camera, presence, render
  budget and gore compatibility.
- Independent final validator: 21/21 GLBs and seven identical cross-bundle heads.
  Original binary/accessor prefixes, rigs, clips, garments and retained body
  attributes/morphs pass; 33 Body targets and 37 active facial channels pass.
  Neck boundaries are connected with consistent directed winding.
- Independent dense review: 933 individual morph poses per variant, 6,531 total,
  in 0.05 strength steps. No neck strip or four-ring transition triangle falls
  below 10% of its resting area. Minimum ratio is 14.18% in the transition and
  18.14% on the neck strip; the seven combined speech poses have a 28.47% minimum.
  All strip triangles retain positive orientation relative to rest. These are individual targets, plus the captured
  combined speech pose, not an exhaustive test of all simultaneous expressions.
- Native source generation checks all seven exports, 168 signed individual
  identity extremes and 462 combined identity cases without triangle reversal.
- `artifacts/mpfb-wardrobe-copy.log`: 14/14 replacement-body copy checks in a
  fresh background Blender process. MPFB mapping accessors are remapped into
  each new document; original mapping values survive exactly.
- `artifacts/mpfb-import-final.log`: Godot 4.7.2 headless/Dummy import exits
  zero with no script or engine errors. Materials load native textures lazily
  so their first import does not block autoload parsing on another machine.
- `artifacts/mpfb-render-final.log`: private GPU capture exits zero with no
  script/engine errors; 18-person sheet, all seven close-ups, front/three-quarter/
  both profiles, and rest/smile/worried/speech/gaze/blink captures reviewed.
  `artifacts/mpfb-render-fallback-final.log` passes the same renderer checks
  for the 18-person sheet and three standard sitters in unmerged mode. Final
  fairing removes the sawtooth silhouette found in the preceding DP-only pass.
  Both probe processes exited; no window appeared on the player's desktop.
- Python compilation and scoped source whitespace checks pass.

## Limits and delivery

Bodies have 15,268–15,528 triangles, and the separate native teeth mesh has 7,120.
The existing court draw-slot budget is retained; this is not an FPS benchmark.
Hair remains the game's illustrated mesh style, and the shader retains stylized
lighting. Native neutral lips can be slightly parted. The assets are adapted
game characters, not photorealistic digital humans.

Existing saved identities remain compatible. No adjudication facts, officials,
population, terrain, campaigns, animation clips or save data are modified.
Only scoped code, tests, source assets, the 21 GLBs and delivery records belong
to this change. Captures, import caches/churn, generated UIDs, Python caches,
test overrides and authoring-tool installs remain local. Existing game/editor
sessions are not stopped or restarted; integrated assets load on the next launch.
