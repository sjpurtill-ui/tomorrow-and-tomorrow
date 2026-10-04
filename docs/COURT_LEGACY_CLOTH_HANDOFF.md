# Additive legacy cloth repair

Status: **HELD two-body prototype**, pending independent family/hand acceptance
and extension to the other five bodies. It is not delivered to the player.
Branch `codex/court-legacy-cloth`, base `1c09a4e6`, worktree
`C:/Users/sjpur/.codex/worktrees/court-chapter-assets/TomorrowandTomorrow`.

The current bundles contain tunic, hide and robe for adult male and old female.
Upper shells share the original body's topology and skin field. Skirts have
independent same-leg panels, overlapping inner facings within the original hem,
smooth waist anchors, and a gold hem partition on the same panel grid. The
lower front/back vent corners turn inward near the knee, avoiding the broad
shin-driven rim protruding as a pointed ribbon. The hip/thigh envelope used by
the separate arm-fitting worker is unchanged. Source animation and real
kneeling are preserved.

Hide retains its asymmetric upper wrap, original ragged hem vocabulary, fur
cape, cord and foot wraps. Robe retains full length, mantle, sash and shoes.
The original cape and mantle meshes are retained with a body-matched shoulder
lining. The lining excludes head/neck vertices; an earlier local variant that
overlaid the lower jaw was rejected. Original fastenings, footwear and cape
surfaces are checked exactly by the raw validator.

The additive files use original skeleton and body morphs without rewriting any
source figure or modern wardrobe. `LegacyBody` changes only replaced outfits'
coverage channels (G hide, B tunic, A robe), for regions covered by real mesh.
Visible legs below the hem remain present. The manifest lists exact source part
names/material slots; missing variants/outfits fall back to the original.
The separately delivered provider is `3b2b8f02` (local cherry-pick `1192e389`).
No simulation or save fields change.

Validation against this explicit worktree:

- Raw two-bundle/all-three-outfit invariants pass: body attributes, morphs,
  skeleton and binds exact; retained original pieces exact; no face/neck in
  cape linings. Log `artifacts/legacy-three-outfits-v9-raw.log`.
- Provider and modern wardrobe regression suites pass 5/5, zero failures,
  errors, skips or orphans (`artifacts/legacy-three-outfits-runtime-tests.log`).
- Current private GPU evidence: `reports/legacy_candidate_v9/`, 186 views,
  PID73864 exit 0 without engine/script errors. Includes both yaws, standing,
  walking samples, kneel through its actual 2.5-second endpoint, cross-sit
  through 1.6 seconds, and release from those complete poses. Earlier captures
  ending at 1.33 seconds were preliminary and do not establish full transitions.
- Adding hide/robe leaves the current tunic surfaces and its B coverage exact.
  Against the previous accepted calibration envelope, the male tunic is exact;
  only old-female lower vent positions change, up to rest Y 0.45651 m. All
  joint weights/indices stay exact (`artifacts/legacy-vent-bounds.log`).
- No diff from base in the seven source figure GLBs, modern wardrobe builder
  or bundles, or animation libraries.

Known outstanding work: authored bare poses already intersect hands and thighs
in some standing/cross-sit samples. The runtime worker owns a bounded cached
arm fit; these asset captures deliberately contain no unvalidated pose override.
Raw motion/coverage diagnostics remain diagnostics, not a visual pass. The
previous prototype's over-tapered breeches silhouette and inward hem-return
experiment were rejected. Current full-family pixels need independent review,
then all seven bodies require the same checks. Generated imports, diagnostics
and captures remain local and are excluded from source commits.
