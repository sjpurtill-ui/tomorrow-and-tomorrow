# Early settlement progression — first resource-led slice

Worker branch `codex/early-settlement-progression`, worktree
`/Users/seanpurtill/.codex/worktrees/c2aa/tomorrow-and-tomorrow`.
Base: `4f68230a3c9c94064a91b3c2909ae806411f2297` (town and military integrated).
The delivery commit contains this document. READY for integrator review;
not integrated into canonical or loaded into the running player game.

## Design accepted in this task

The beginning through a roughly 2,000-person town is a scope, not a population
unlock. Delivered resources and research permit construction; actual labor and
completed work determine when it appears. Existing settlement age/repair systems
provide history, not free visual upgrades. No renderer lookup of current wealth,
population, research or date is allowed to repaint an existing building.

| Recorded construction | Visible interpretation |
| --- | --- |
| Carried/temporary shelter | Lightweight ridge or round cover; poles, seams and an open entrance |
| Completed Lean-to Shelters | Rooted posts, layered roof, sleeping platforms; still modest and open |
| Permanent organic household | Recorded round thatch or existing timber town kit |
| Clay shaping plus supplied earthen construction | Thick earthen walls, open doorway, timber-supported earth roof |
| Stone selection plus supplied rubble construction | Irregular dry rubble courses, timber supports and slab roof |
| Raised store / covered work area completed | Separate storage and workshop structures |

The renderer reads **plot forms already created by these systems**. It does not
spend resources, complete research or claim a construction capability itself.
Open yards and storage pits do not become buildings simply because their land-use
category says workshop/storage. Unsupported forms and taller buildings retain the
legacy renderer. Historical founding roof labels sometimes survive a permanent
conversion in the model; a recorded completed form now takes precedence over
that stale label, without rewriting the save.

Eight new assets are active. Three additional cultural/political assets are
studies only; see the asset README. All eleven are exported GLBs with offline
review plates, not concept images masquerading as game captures.

## Culture, politics, and rise/decline

The user explicitly wants cultural strength to have a major effect on impressive,
beautiful architecture once a society has sufficient development. The direction
is shared craft traditions, learned proportions, ornament, skilled joinery,
pigments, public patronage, distinct roof/threshold languages and richer civic
space. These require appropriate knowledge, supplied materials, specialist labor
and actual building/renovation work. They do not make the first camp monumental.

Politics affects access, who receives investment, public versus private space,
enclosure, ceremonial approach and concentrated versus distributed patronage.
The two hall studies deliberately hold craft quality constant while changing
access/enclosure. Neither political form receives a built-in beauty judgement.

Next implementation needs to record the bounded cultural/patronage profile **when
construction or substantial renovation occurs**. Existing
`SocietalValuesModel.architecture_snapshot` already supplies axes such as
monumentality, civic space, permeability, lineage clustering and productive order;
using its current value to restyle every inherited house would erase history.
No new universal "culture = bigger buildings" coefficient has been invented.
The three cultural assets are intentionally not unlocked before that historical
record and suitable public-parcel placement exist.

Decline should appear through existing condition, repair, vacancy, damage and
reuse records. Former imperial buildings can survive a weaker successor; a new
regime need not demolish or instantly recolor everything. The current slice
preserves those records and darkens worn/burned structures, hides destroyed ones,
and leaves actual construction/ruin handling with the existing terrain renderer.
It does not yet model broken roof geometry or cultural renovation costs.

## Implementation and limits

`early_settlement_visual.gd` adapts recorded built forms to the checked organic
plot/road/water placement solver using display copies. It restores original plot
records in the result and selects the correct meshes in bounded MultiMeshes.
Converted households retain reserved sites; additions can fill further sites when
recorded coverage grows. No simulation or save owner changes. New assets omit
invented garden rows; the existing permanent timber kit remains unchanged.

`local_terrain.gd` now enables that kit for actual founding plots as well as
compatible permanent buildings. Population no longer controls this early-mode
switch. The 128-plot/512-building representation budget remains, independent of
resident count; larger fabrics keep inherited kit instances and legacy coverage
for the rest. One representative is not one household or a population ledger.
Camera changes do not change a building's style or physical scale.

Portable camp motifs are still a deliberately limited starting repertoire.
Climate-specific shelter technologies, detailed interiors, construction-stage
asset variants, decay geometry, further public functions and later architectural
traditions remain extensions, not claimed complete here. Earth/stone public
workshops beyond the listed supported forms still use the legacy renderer.

## Verification and handoff

Blender background rebuild completed; both review plates visually inspected.
Godot 4.7.2 headless import and tests run only in the explicit worker checkout with
its existing isolated test override. No editor/game interruption or graphical
Godot test window was used; the user's canonical game remains untouched.

The initial combined run passed 153 cases: early kit (6), organic town (9),
settlement visual architecture (83), settlement model (43), military fronts (12),
zero errors/failures/skips/orphans. A final mixed-resource 2,000-resident fixture
adds a seventh early test, checking bounded mixed styles and unchanged historic
appearance under a change of current societal values. Final validation is recorded
in `/tmp/early-final-import.log` and `/tmp/early-final-tests.log`: **154 passed,
zero errors/failures/skips/orphans, exit 0**. An intermediate new-test reference
to an unpreloaded class failed discovery; it was removed before this complete
successful rerun.

Shared hotspot: `local_terrain.gd`, restricted to the organic/early kit adapter and
route/ground-mode hooks. No changes to settlement_model.gd, project.godot,
game_state.gd, military_campaign.gd or save_system.gd. Existing saves retain their
recorded resource choices; no migration is required. New files are the adapter,
seven-case suite, reproducible Blender generator, eleven GLBs, manifest/review
plates/asset README, and this handoff. The cultural studies are assets for later
work, not an implemented empire/culture system. Canonical integration and in-engine
visual signoff remain for the designated integrator after review.

## Review correction after a599109

The adapter now accepts explicit early household forms: initial material recipes,
the legacy timber_household alias, durable_household_cluster, joined_kin_compound
and courtyard_household_compound. Later and unknown forms are excluded regardless
of one-storey height, material or inherited roof label. Supported market fallback
also uses an explicit early-form list. The shared layout receives an unsupported
roof sentinel on rejected display copies so its broader timber predicate cannot
accidentally re-admit them; obstacle polygons remain present.

Single identity-transformed imported meshes are now reused directly, preserving
Godot importer-generated LOD indices and shadow resources. Only genuinely
multi-mesh or transformed authoring uses the documented flattening fallback,
which cannot preserve that importer data. A regression checks actual imported
rubble_household mesh identity, nonempty LOD data and shadow resource retention.

Final follow-up validation: **156/156 cases passed**, zero errors/failures/skips/
orphans, exit 0, in `/tmp/early-review-final-tests.log`. The nine early cases include
valid/advanced/unknown form coverage and actual imported LOD retention. An initial
LOD-test type assumption was corrected from Dictionary to Godot's returned Array
before the complete successful rerun. No simulation/save schema changes.
