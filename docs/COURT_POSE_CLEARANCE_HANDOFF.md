# Ordinary pose arm clearance

Worker branch `codex/court-pose-clearance`, checkout `C:/Users/sjpur/tt-court-interior-seating`, initial base `31df94aabd35d4d337d0e554e960027634e4a29f`. Provider source is delivered separately. This branch also contains held garment and independent diagnostic cherry-picks for calibration; select owned source commits individually during integration.

## Current checkpoint: two bodies validated, full delivery HELD

`court_pose_clearance.gd` now enables the reviewed male-adult and old-female profiles. The remaining five variants keep their source poses until their own replacement garment envelopes have been checked. All-body/all-outfit acceptance is still pending; this worker checkpoint is not a claim about the player build.

Only `stand`, `sit_cross`, and its ordinary held `stance_cross` are fitted. Cached copies change original upper-arm rotation keys and, for the cross-sit clips only, forearm rotation keys. Figure's owned stand resource updates without changing its player clock or pause; Acting selects a fitted source when creating those layers. Existing walking fitting remains independent. There is no post-pose offset or per-frame collision solver. Root, lower body, head, hand/finger local rotations, timing, non-arm tracks, execution/kneel/prop clips and source GLB bytes remain unchanged.

The tested profiles use these corrections:

| Body | Standing spread | Held cross-sit spread / elbow bend |
| --- | --- | --- |
| Adult male | 6 degrees | 10 / 6 degrees |
| Old female | left12, right13 degrees | 14 / 14 degrees |

The descent briefly reaches20 degrees of spread and12 degrees of elbow extension, then eases to the resting hand position. Exact times and values are in `PROFILES`; they match the independently tested `ext12` candidate. Extension leaves at least6.31 degrees of male and6.75 degrees of old-female elbow bend at the original source keys, so it never passes straight. Diagnostic overrides support scalar degrees, `[seconds,degrees]` curves, side-specific L/R values, or `{spread: curve, flex: curve}`. The fitted cache is bounded at96 resources.

## Evidence and limitations

- 68/68 headless tests pass across pose clearance, acting, walking clearance and legacy provider, with zero errors, failures, skips or orphans. Log: `artifacts/court-pose-two-body-tests.log` (report28). Source invariants cover all seven rigs and every key time/transition; a new regression checks that calibrated elbow extension never exceeds the original available bend.
- Dense independent triangle checks: both tested bodies have zero bare-body hand crossings at64 descent phases each; adult male also has zero cloth crossings. Standing passes64 samples per body with the stated asymmetry; held cross-sit passes48 phases per body.
- Old-female descent retains brief inner-hand/panel-edge overlap at0.73–0.97s: median measured local depth3–6mm, sampled maximum approximately13mm, below2.4mm by0.93s, clear at1.0s. This is not described as zero cloth collision. Front/side pixels retain the complete wrist, palm and fingers, with none of the original forearm burial. Root independently accepted the exact candidate and requested no further offset merely to remove benign edge contacts.
- Private GPU gate:44 tunic/business views at the exact difficult phases and held endpoint, PID58892 exit0, no engine errors; `reports/court_pose_extension_gate`. Root independently reviewed0.77s front/side and1.60s front.
- Complete two-body transition capture:172 tunic/business views, PID81080 exit0, no errors; `reports/court_pose_two_body_full`. Includes ordinary idle settle/depart, release into the existing fitted walk, dense descent frames, and the unchanged2.5-second kneel endpoint. Sampled hands stay visible through the additional transitions.

The tracked capture fixture is `tests/court_pose_clearance_capture.tscn`. It accepts `--profile=res://...json`, `--outfits=tunic,business`, optional `--bodies=...`, `--label=...` and `--quick`. GPU runs use the isolated private-desktop runner, never the player launcher.

The branch includes held family asset890ed589 for these checks. Tunic's upper contact envelope is unchanged from the earlier frozen prototype. Shoulder-only garment repairs and expansion to all seven bodies belong to the asset worker. Source provider compatibility passes against the current two-body, three-family bundles.

Save state is unchanged. Shared-file hooks are the one `_dress` call in `court_figure_3d.gd` and per-layer source selection in `court_acting.gd`, delivered at the scaffold checkpoint. Final per-body profiles and the all-family visual/triangle audit remain required before full acceptance.
