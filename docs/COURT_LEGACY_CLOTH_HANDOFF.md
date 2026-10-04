# Additive legacy cloth repair

Status: **HELD prototype**, not visually accepted or delivered to the player.
Branch `codex/court-legacy-cloth`, base `1c09a4e6`, worktree
`C:/Users/sjpur/.codex/worktrees/court-chapter-assets/TomorrowandTomorrow`.

The prototype contains adult-male and old-female tunics only. Raw invariants
pass both bundles; actual animation transitions and hand clearance remain
under review with the separately owned runtime provider. Missing variants/outfits
must continue to use their source pieces until a validated replacement exists.

The additive files use the original skeleton and body morphs without rewriting
the source figures or modern wardrobe. `LegacyBody` changes only the replaced
outfits' vertex coverage channels. Exact source part names and material slots
are listed in `assets/court_figures/legacy/court_legacy.json`. Open skirt vents
retain the actual legs; there is no pose substitution or animation modification.

Initial raw checks: `artifacts/legacy-prototype-raw.log`, 2/2 pass. The private
original-baseline GPU probe produced 18 views of hide/tunic/robe standing,
kneeling and cross-sitting; PID40752 exited 0 without engine/script errors.
`reports/legacy_baseline/` records genuine failures in all three families.
Captures and generated imports remain local and are not delivery evidence for
the prototype itself.

The second iteration adds overlapping source-body-matched skirt facings,
confined to the original hem, and fits the upper shell inside the preserved
belt. It removes the raised-thigh skin breakthrough and buried belt. A third
iteration tapering the skirt to the leg envelope was rejected: it read as
breeches and did not fix the hands. The current fourth iteration restores the
fuller drape and uses a continuous hips anchor around the skirt waist, avoiding
nearest-source weight jumps between opposite thighs. Neither the facings nor
the coverage channel remove visible legs below the hem.

Actual local evidence: the second iteration captured 22 views; the rejected
third captured 58 onset/release/walking views, PID48540 exit 0 with no script or
engine errors after a local fixture indentation repair. Both remain HELD.
Independent source-only intersection checks found bare hand/body crossings in
all seven old-female standing samples and all seven cross-sit samples; at
0.633 seconds of cross-sit, male and old-female have 41 and 119 crossings.
Further skirt narrowing cannot repair those original pose contacts. A bounded
runtime hand clearance fit is being coordinated separately. Full seven-body,
robe and hide expansion has deliberately not begun before two-body acceptance.

The fifth iteration partitions the green panel and gold hem on one shared
vertex grid and skinning field, with no overlapping raised trim sheet. The
fuller standing silhouette is restored. `reports/legacy_candidate_v5/` has 58
views of onset, release and walking; PID48640 exited 0 without engine/script
errors. This remains a HELD two-body checkpoint pending the separate pose fit
and independent visual acceptance. Geometry is frozen for that calibration.
