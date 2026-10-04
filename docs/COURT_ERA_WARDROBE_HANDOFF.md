# Court era wardrobe handoff

Worker branch `codex/court-era-wardrobe`, based on `09b3a5f5de858b0c11ac181b78a84e2d73299c67`. This is worker evidence, not a claim that the canonical player build contains the change.

## Rendering contract

All six adult bodies and the child support four new outfit IDs:

- `medieval`: full sleeves, laced doublet, belt, split surcoat panels, leggings and shoes.
- `courtcoat`: tailored coat with long rear tails, broad cuffs, lapels, buttons and adult cravat.
- `formal`: shorter formal coat, short split panels, lapels, shirt and adult cravat.
- `business`: short jacket, shirt, trousers, shoes and adult tie. Children have a plain collar without an adult tie/cravat.

These are new skinned meshes, not robe recolors. Palette slots remain `CLOTH_A` for jacket/trousers, `CLOTH_B` for shirt (medieval leggings), `CLOTH_C` for trim/tie, and `LEATHER` for shoes/belt. Light shirt colors make the later silhouettes legible.

Seven additive GLBs live under `assets/court_figures/wardrobe/`. The original figure GLBs, face shapes, animation libraries, skeletons and hide/tunic/robe meshes are unchanged. Each bundle contains a body copy whose only changed attribute is the green coverage channel, so all four fully sleeved/legged outfits share channel 1 without exhausting the original RGB mask channels. Runtime restores the original body mesh for old outfits, remaps garment binds by bone name and attaches only the selected outfit. The mesh cache supports redressing without replacing the animation player. Existing merged rendering and face painting remain active.

Era selection and etiquette are separate integrator-owned changes. This branch changes no civic state, dates, adjudication, save format or role selection.

## Rebuild and validation

From the explicit worktree, run Blender 5.2 with `--background --factory-startup --python tools/blender/court_era_wardrobe.py`. It reads the seven base figures and writes the additive bundles and source/output SHA-256 manifest. Rebuild the bundles after changing source bodies. It never writes a base figure.

Run `python tools/blender/validate_court_wardrobe.py --root <worktree>` to check raw GLBs independently of Godot's import cache: exact original body attributes except coverage, exact morphs, joint transforms and bind poses, finite geometry, normalized weights, and rest coverage. Reimport changed GLBs with headless Godot before runtime tests.

`tests/test_court_wardrobe.gd` checks all 28 body/outfit combinations, four distinct geometries per body, original face/rig preservation despite glTF vertex reorder, restoration of legacy dress, and merged redressing while walking continues on the same player. Run GdUnit with `--ignoreHeadlessMode`.

`tools/court_wardrobe_capture.tscn` creates 20 private-desktop sheets: all seven bodies in each outfit, standing, walking, sitting, cross-legged sitting and kneeling. Use `tools/run_isolated_gpu_probe.ps1` with this worktree. These are isolated evidence, not the player game.

`tools/court_wardrobe_audit.tscn` samples seven bodies, four outfits, six clips and eight times (1,344 samples). It retains the established 2.6 stretch ratio and 12 cm gap thresholds. Coverage follows matching source bone weights on fitted shell vertices; naive nearest-rest pairing incorrectly joined opposite thighs during cross-legged sitting. Every coverage sample is retained, with nearest-geometry fallback if no source correspondence is available.

## Final worker evidence

- Godot 4.7.2 headless import completed after the final seven-bundle rebuild.
- Raw buffer/rig/morph/coverage invariants: 7/7 bodies passed; maximum rest nearest-cover distances 1.9-2.6 cm.
- Runtime GdUnit: 2/2 tests passed across all 28 body/outfit combinations and merged redressing while walking.
- Private GPU capture completed all 20 sheets (140 body/outfit/pose views), exit 0, no script/render errors in the final log. Shoulder coverage, shirt V boundaries, cuff planes and trouser/boot hems were repaired from the first captures. Split skirt panels follow thighs more strongly when seated; leggings remain visible below/between them.
- Final motion diagnostic: **1,344 samples, 439 flagged samples across 72 body/outfit/clip cases**, maximum stretch **5.2496x**, maximum reported coverage gap **0.000 m**. This is **not a passing stretch audit**. The sharpest ratio is a male-old business-jacket armpit edge during kneeling: **5.95 mm rest to 31.25 mm posed**. Stronger thigh following reduced visible skirt lag but increased relative edge-stretch flags around panel attachment rows. Thresholds are unchanged. Repeated held-pose flags are not distinct holes.

Final local evidence: `artifacts/wardrobe-invariants.log`, `artifacts/wardrobe-tests.log`, `artifacts/wardrobe-motion.log`, `artifacts/wardrobe-capture.log`, and `reports/court_wardrobe/`. The integrator should repeat the wardrobe suite and review combined stage captures with its era-selection/palette rules.

## Limitations and integration

This is a stylized four-step progression, not a comprehensive cultural or gendered historical costume catalog. Adult women wear tailored coats/trousers in the later styles. Clothes use skinning and split panels, not cloth simulation. Deep bends retain localized armpit/hip/cuff and panel-attachment stretching; the numerical motion audit is therefore not clean. Keep the exact flags and visual evidence in the final report.

Shared edit: `scripts/hud/court_figure_3d.gd`; coordinate with other figure work. Generated imports, captures, logs, caches and unrelated import churn are excluded. Original seven base GLBs are unchanged, and no save migration is required.
