# Great Work catalog acceptance

Base: `01ce6be538e9ce3491686313bb99cd5f199caf09`.
Worker: `codex/great-work-catalog-acceptance` in
`C:/Users/sjpur/.codex/worktrees/settlement-growth-acceptance/TomorrowandTomorrow`.

The isolated catalog probe covers all 18 conceived forms and 12 legacy IDs
through the actual Model, View and ceremony Stage. The catalog run is complete;
the colossus visual design has been reopened after user feedback, and final
bridge/gate ceremony corrections await focused capture. Earlier colossus images
are superseded as visual approval even though their mechanical checks passed.

## Verified evidence

| Run | Result | Local evidence |
| --- | --- | --- |
| Final authored geometry and variants | 2678/2678, clean exit 0 | `artifacts/great-work-catalog-final-structure/functional.json` |
| Full catalog GPU, maximum six-person cast | 1298/1298, 65 images, clean exit 0 | `artifacts/great-work-catalog-final-gpu/capture.json` |
| Existing real-engine 12-case GPU probe | 252/252, 18 images, clean exit 0 | `artifacts/great-work-catalog-engine-gpu/capture.json` |
| Latest ring Atlas and committed future dedication UI | 54/54, four images, clean exit 0 | `artifacts/great-work-catalog-final-ui/capture.json` |

Matching logs are `artifacts/<folder>.log`; GPU runners also record the private
desktop and process exit in `<log>.runner.txt`. Full catalog GPU PID 43272,
real-engine PID 59896 and final UI PID 52468 exited normally. Rendering used
Godot 4.7.2 Compatibility on the RTX 4090 with Dummy audio. The input desktop
stayed Default; no player game was opened or stopped.

The final structure/catalog runs used worker runtime `d68b7578`: Design
`510366a7`, Architecture `6b896b3b` plus `aaa8addc`, Rituals/Stage
`579daae4` plus `d6eca4b7`, Atlas `957d49bd`, dedication words `5f50fc4e`,
reading correction `7f406ea0`, and merged main `ad8d0913`.
Final targeted UI runtime `3b98d1a0` additionally includes ring labels
`3ef80d6c` and committed side-caption fix `2e00fb41`.
Subsequent main `a7877e0d` has been merged for the remaining focused captures.

## What the checks establish

- 120 canonical model builds at 0/30/70/100 percent, including honest raw
  progress and refusal to turn an incomplete fraction into standing geometry
  merely because its status says functioning.
- Every supported material x tier 0..5 x ambition combination: 900 completed
  builds, plus all 12 purposes for each of 18 forms: 216 purpose builds.
- All 30 completed models and all 30 ritual prop sets have distinct actual
  vertex/index/transform fingerprints independent of colors and labels.
  Authored design IDs must match the actual description and model root.
- 120 real inspector views retain geometry through orbit/zoom; all 30 standing
  views prove sleep/wake through GPU pixels, not the cached viewport getter.
- Every ceremony has six actual figure bodies from recorded/seeded fixture
  participants, distinct ritual identity and physical props, contained
  whole-work bounds, retained model identity through dedication, and an idle
  viewport afterward. Presentation leaves the supplied work record unchanged.
- The earlier 12-case actual-engine probe covers real commission, daily
  completion, paused/live inspection ownership, stalled/ruined/finished states,
  all four capability-derived ceremony modes, narrow dark layout, one-time
  gifts, repeat dedication and close/reopen cleanup. Targeted latest UI images
  confirm truthful ring milestones and committed side-description wording.

The maximum-cast option creates two additional seeded rival actors through the
existing experience fixture helpers. Their envoys resolve through the actual
CharacterVoice API. These are prepared in-memory world records, not player
data or a continuous historical campaign.

## Visual review and catalog map

The acceptance worker individually examined all 30 whole-work before images
and all 120 construction panels. The architecture worker independently reviewed
all 120 panels; the ceremony worker individually examined all 30 after images,
then all 30 maximum-cast recaptures. Root also reviewed the complete catalog.
Review found and corrected the shoulder attachment, premature canal water,
purpose-pedestal overlap and stale committed caption. Final bridge crossing,
gate sightline and redesigned colossus approval remain separate follow-ups.

Five contact pages `catalog-01.png` through `catalog-05.png` are 2400x1800.
Each contains six identities, four actual views per identity. Individual
ceremonies are 1280x900 and alternate light/dark. Every numbered identity below
has both `NN-<design with colon replaced by hyphen>-before.png` and
`-after.png` in the final GPU folder.

| No. | Design | Contact page | Ritual |
| --- | --- | --- | --- |
| 01 | form:ring | 01 | circle_of_witnesses |
| 02 | form:mound | 01 | earth_and_memory |
| 03 | form:stair | 01 | first_ascent |
| 04 | form:tower | 01 | horizon_standard |
| 05 | form:hall | 01 | common_threshold |
| 06 | form:cistern | 01 | water_bowl |
| 07 | form:granary | 02 | first_sheaf |
| 08 | form:bridge | 02 | first_crossing |
| 09 | form:causeway | 02 | road_stone |
| 10 | form:dam | 02 | sluice_seal |
| 11 | form:colossus | 02 | sculptors_reveal |
| 12 | form:garden | 02 | first_branch |
| 13 | form:observatory | 03 | sky_alignment |
| 14 | form:gate | 03 | open_threshold |
| 15 | form:canal | 03 | joining_waters |
| 16 | form:archive | 03 | first_record |
| 17 | form:amphitheatre | 03 | opening_beat |
| 18 | form:lighthouse | 03 | first_beacon |
| 19 | legacy:ancestor_ring | 04 | names_in_stone |
| 20 | legacy:great_hall | 04 | many_hearths |
| 21 | legacy:rain_court | 04 | rain_share |
| 22 | legacy:flood_terraces | 04 | high_water_mark |
| 23 | legacy:star_steps | 04 | seasonal_sightline |
| 24 | legacy:kiln_court | 04 | hundred_fires |
| 25 | legacy:long_song | 05 | verse_of_the_house |
| 26 | legacy:common_stores | 05 | covenant_seal |
| 27 | legacy:safe_passage | 05 | unbarred_way |
| 28 | legacy:living_orchard | 05 | root_and_branch |
| 29 | legacy:stone_crown | 05 | crown_of_the_ridge |
| 30 | legacy:measures_house | 05 | witnessed_measure |

## Reproduction and limits

Use an explicit isolated project, Dummy audio and an ignored acceptance-specific
userdata override. Headless catalog arguments:

```text
res://tests/great_work_catalog_acceptance.tscn -- --great-work-catalog --require-authored --group=structure --variants
```

For actual GPU evidence use `tools/run_isolated_gpu_probe.ps1` with the worker
project, the catalog scene, TimeoutSeconds 900, QuitAfterFrames 30000, and:

```text
--great-work-catalog --require-authored --six-cast --capture --out=res://artifacts/great-work-catalog-final-gpu
```

`--group=structure|construction|ceremonies` selects a section.
`--design=form:bridge,form:gate` selects named identities.
The existing engine probe also accepts comma-separated `--case` IDs, a
one-line reuse hook to capture ring construction and future dedication together.

Prepared catalog records do not claim engine-earned completion or every
material/era/purpose combination being commissionable. The matrix checks
renderer robustness; actual game availability remains governed by the engine.
Supported capability fixtures span year 0 through year 3000, with real known
technology required for modern clothing and opening lights. No future
technology was invented to obtain a late appearance.

Coverage is exhaustive across current catalog identities, not all possible
seeds, every campaign state, every camera angle, or GPU vendors. Pixel sleep,
bounded casts and retained meshes are verified; this is not an FPS or large
settlement benchmark. Cistern and rain-court basins intentionally remain
structural dry geometry because the fixture contains no stored-water record.

The task owns the new catalog probe/scene and this document, plus the minimal
selection hook in the existing engine probe. No simulation rules, save schema,
player preferences or player files change. Images, logs, imports and isolated
userdata remain local generated evidence and are excluded from commits.
