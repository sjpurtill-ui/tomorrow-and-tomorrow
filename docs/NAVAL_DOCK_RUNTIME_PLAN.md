# Physical naval dock and hull survey services

HELD implementation worktree `/Users/seanpurtill/Documents/Codex/tt-naval-dock`, branch `codex/naval-dock`, base `cd6accf0cd2dc24b51842bfc3280530ec8c2b52f`. No canonical delivery or discovery promotion is claimed.

The existing naval repair path consumes port-local material and restores condition at a base-capacity-limited rate. It has no constructed out-of-water access or dated hull survey service. This batch will connect existing authored identities `dry_dock_services` and `hull_condition_surveys` to those operations. It adds no discovery identities.

The first supported installation is a timber-vessel lift and supported repair access, using paid Launch Cradles, Rigging Blocks, Rope Coils, Timber and Stone. It is not a universal graving dock: only War Canoes and Ram Galleys are in its declared handling set. Heavy galleys, sailing ships, armored ships, submarines and mixed unsupported formations require later qualified facilities. Relative handling loads and work quantities are game tuning, not naval engineering ratings. Existing afloat repairs remain available.

The helper creates a paid unfinished project, consumes only provided construction work, and returns actual work used. It has a daily access ledger and debits upkeep materials for access. It does not itself restore hull condition or claim to have surveyed a ship.

Required owner integration before READY:

- Validate owned, accessible, completed naval base and actual local adopted knowledge at install. Use `with_city_resources`; never use a neighboring city's stock or rival abstract funds to fabricate local material.
- Include dock projects in existing JointOperations construction share and project count, so base construction and docks divide the same reserved quarter of construction labor. Use local population scope where required. No second workforce authority.
- Introduce bounded repair-access work and dated hull surveys using actual port crews; preserve ordinary repair material charges. Complete the whole payment transaction before debiting dock upkeep/access or changing condition. Insufficient repair supplies must not consume access for work that did not occur.
- Survey observations must state date and vessel condition, require qualified access and crew time, and grant no free repair or durability. Repeated same-day calls cannot buy multiple benefits from one observation.
- Connect player controls and autonomous owned-civilization demand to the same install and repair action. Generals keep mission execution. No mandatory new forms or direct cohort control.
- Validate optional dock and survey fields through JointOperations export/import for human and actor saves. Legacy absent fields remain valid; malformed work, dates, provenance or access counters are rejected.
- Register the two discovery definitions only after their full operating consumers exist; review draft prerequisites rather than importing unnecessary manufacture or calendar gates.

Acceptance requires paid installation, partial construction, shared work and access limits, supported/unsupported hull behavior, material failure transactionality, primary/secondary/actor stock isolation, controls, autonomous acquisition, dated survey consequences and full saved continuation. Run affected joint-force and ownership checks once the cohesive implementation is connected. No broad history or artwork completion follows from this batch.


## Operating integration checkpoint — still HELD

JointOperations now exposes paid owned-port installation, includes unfinished docks in the existing reserved construction quarter, and divides the work by local project count and local population. The repair consumer checks the combined original repair bill plus dock upkeep before any payment or state mutation, and falls back to the original paid afloat repair if dock supplies are unavailable. Available onboard repair crew time bounds dock work, and the ship spends that day in its existing repair branch. The current dock's daily handling budget is shared across formations; unsupported hulls gain no access bonus.

Hull survey adoption enables a paid inspection during dock work. It records pre-repair condition, date, port and work. Fresh evidence permits more effective allocated dock repair work; it does not itself restore condition. A repeat service call cannot repeat dock work that day. Naval controls expose the install action, construction progress, remaining daily handling and dated survey evidence.

Eight dock cases and five existing joint-operation cases pass (13 distinct): paid shortage transactionality, finite reserved work and day guard, combined inspection/repair, shared exhausted capacity, unsupported hulls, legacy/malformed state, secondary-city supplies/occupation guard, and export/import continuation of partial work and spent access. Latest focused owner log `/tmp/tt-naval-dock-owner-tests.log`, exit 0. Earlier combined log `/tmp/tt-naval-dock-tests.log`, exit 0. A missing ordinary repair input in the initial positive fixture was corrected; the deliberate shortage case verifies no stock/access/condition change.

Remaining before READY: actual full SaveSystem/actor continuation, autonomous acquisition and commissioning through owned actors, install-button callback verification, current prerequisite review and the two registered operating discovery definitions/catalog consumer checks. Foreign observer-side aggregate repair accounting is unchanged; actual owned civilizations must use their scoped port inventories for this new service. No player launch, canonical inclusion or completed technology promotion is claimed.
