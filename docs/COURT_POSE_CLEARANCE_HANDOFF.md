# Ordinary pose arm clearance

Worker branch `codex/court-pose-clearance`, checkout `C:/Users/sjpur/tt-court-interior-seating`, initial base `31df94aabd35d4d337d0e554e960027634e4a29f`. Select owned source commits individually: the branch also contains garment and diagnostic cherry-picks used for validation. Canonical checkout and player session were not changed.

## READY: seven-body ordinary arm fitting

`court_pose_clearance.gd` fits ordinary standing and cross-sitting arms to each body. Fingers remain outside the thigh during descent, then hands settle near the knees. The smaller female-adult/young held correction was selected by same-camera comparison; a larger correction unnecessarily lifted the wrists above their support.

Only `stand`, `sit_cross`, and ordinary held `stance_cross` are fitted. Cached copies change original upper-arm rotation keys and, for cross-sit clips only, forearm rotation keys. Figure's owned stand resource updates without changing its clock or pause; Acting selects a fitted source when creating a layer. Existing walking fitting remains independent. There is no post-pose offset or per-frame collision solver. Root, lower body, head, local hand/finger rotations, key times, playback speed, queue/pause, and execution/kneel/prop clips remain unchanged. No source GLB bytes are changed by this runtime delivery.

| Body | Standing spread, degrees | Held cross-sit spread / elbow bend, degrees |
| --- | --- | --- |
| Adult male | 6 | 10 / 6 |
| Adult female | 8 | 10 / 6 |
| Young male | 6 | 10 / 6 |
| Young female | 6 | 10 / 6 |
| Old male | 8 | 10 / 8 |
| Old female | left 12, right 13 | 14 / 14 |
| Child | 10 | 10 / 6 |

The descent briefly reaches 20 degrees of spread and 12 degrees of elbow extension, then eases to the resting position. Exact curves are in `PROFILES`. The already reviewed adult-male and old-female profiles are unchanged. Across all seven source clips the fitted elbow remains 6.3–7.8 degrees short of straight at the most extended original key. Diagnostic overrides support scalar degrees, `[seconds,degrees]` curves, side-specific L/R values, or `{spread: curve, flex: curve}`. The fitted cache is bounded at 96 resources.

## Validation

- **68/68 Godot 4.7.2 headless tests pass**, zero errors, failures, skips or orphans: pose clearance, acting, walking clearance and legacy provider. Log `artifacts/court-pose-all7-tests.log`, report `reports/report_29`. Invariants cover all seven rigs, every key time/transition and non-arm track, protected acting sources, redress clock/pause, walking resource identity, and actual default elbow-extension bounds.
- Independent final triangle audit: **2,016 poses**, all seven bodies × three legacy outfits × standing/descent/held loops at 32 phases. **Zero bare-body hand crossings**. Cloth-edge contacts remain in **380/2,016** samples: standing 29/672, descent 159/672, held 192/672. These counts are retained, not hidden by threshold changes. The separate 1,344-pose walking audit has zero hand/cloth crossings with the replacement garments.
- A second actor identity tests a different breathing/fidget seed over **336 poses**. Standing and descent have zero bare-body crossings; two held knee-rest samples have measured penetration approximately **0.414 mm** and **0.054 mm**. No extra arm offset was added for these surface contacts.
- **428 final private GPU images**, all processes exit 0, no engine errors: 368 views across hide/tunic/robe/business with seven bodies in two readable cohorts, 48 standing/held checks for medieval/courtcoat/formal, and 12 targeted old-male standing frames at 2.33/2.50 seconds. PIDs 28236, 72392, 54548, 48816 and 3332 all exited. Reports are `court_pose_final_adults`, `court_pose_final_young`, `court_pose_formal_adults`, `court_pose_formal_young`, and `court_pose_old_male_rest` beneath `reports/`. Representative front/side images were reviewed at descent, held support, idle settle, release and walking interruption. The unchanged 2.5-second kneel endpoint is included as a reference.
- Earlier same-camera female held A/B: 24 images, PIDs 28056/18444 exit 0, reports `court_pose_female_held_low` and `court_pose_female_held_high`. The lower 10/6 pose preserves readable palms and more natural knee support than 14/14.

## Residual contacts and scope

This is not a zero-cloth-collision claim. The old-female descent retains brief inner-hand/panel-edge overlap at 0.73–0.97 seconds, median local depth 3–6 mm and sampled maximum approximately 13 mm; it falls below 2.4 mm by 0.93 seconds and clears by 1.0 second. Full wrist, palm and fingers remain visible in reviewed front/side images, with the original forearm burial removed. The integrator independently accepted this exact hand path. Some long-garment held poses similarly retain palm/edge resting overlap; adult-male robe and female 10/6 poses were reviewed specifically before choosing the smaller correction. Old-male standing contact was checked at its worst sampled 2.33/2.50-second phase: hands remain fully visible alongside all three legacy garments.

The fixture includes immediate cross-sit-to-walk interruption as a stress case. Existing lower-body interpolation and court departure timing are preserved; this change does not author a new stand-up animation. Numerical cloth strain is separately reported by the asset audit and is not certified as zero by these arm checks. Protected execution and kneeling animations are deliberately unchanged.

The final validation uses complete legacy asset checkpoint `63140339f51f87034dd292c7b82ccc674bda33bc` plus upper-hide seam follow-up `1c7d7cc045e2a95b6723831c5534195dcbcc54a0`. Assets and their source invariants belong to the garment worker. Provider source was delivered separately in `3b2b8f0208dbd0563f325ef0cc3fa6bd5372e4bf` and `31df94aabd35d4d337d0e554e960027634e4a29f`.

Capture scene: `tests/court_pose_clearance_capture.tscn`. It accepts `--profile=res://...json`, `--bodies=...`, `--outfits=...`, `--poses=...`, `--times=...`, `--label=...`, `--quick`, and `--review`. Each captured pose creates fresh actors with stable `legacy_motion_<variant>` identities so cohort/order changes do not alter the seeded ambient movement. Use the isolated private-desktop runner; no player or editor launch is needed.

Save state is unchanged. Shared-file hooks remain the single `_dress` call in `court_figure_3d.gd` and per-layer source selection in `court_acting.gd` delivered at the scaffold checkpoint. This final follow-up only changes the modular profile helper, its tests/capture fixture and this handoff. Generated imports, diagnostics, captures and unrelated local files are excluded. The integrator still owns combined runtime/UI acceptance and delivery to the player branch.
