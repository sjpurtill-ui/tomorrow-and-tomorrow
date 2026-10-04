# Additive legacy cloth repair

Status: **HELD prototype**, not visually accepted or delivered to the player.
Branch `codex/court-legacy-cloth`, base `1c09a4e6`, worktree
`C:/Users/sjpur/.codex/worktrees/court-chapter-assets/TomorrowandTomorrow`.

The initial checkpoint contains adult-male and old-female tunics only. Raw
invariants pass both bundles; actual animation transitions and hand clearance
are pending the separately owned runtime provider. Missing variants/outfits
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
