# Settlement fabric: READY worker handoff

Status: **READY for integrator review, not integrated or registered.** Content commit `1d6ec00` on `codex/settlement-fabric-processes`. Worktree `/Users/seanpurtill/Documents/Codex/tt-settlement-fabric-processes`; base runtime `41f5b51b21f3d0884d957374ab1b824d241e9e0b`, with documentation checkpoint `ce96154` merged as `c10213d`. Delivery is frozen after this handoff. The full 5,000-discovery overhaul remains incomplete.

## Scope and behavior

Ten existing D08 drafts, with original authored names and ALL/OR foundations preserved:

- `timber_post_beam_connections`
- `timber_splice_connections`
- `timber_lateral_bracing`
- `timber_moisture_movement_design`
- `building_drainage_coordination`
- `building_wind_load_assessment`
- `building_capillary_breaks`
- `roof_flashing_interfaces`
- `rainscreen_wall_assemblies`
- `building_shading_design`

Ten finite civilian workshop recipes produce components. Setup consumes recorded work surfaces, stones and binding fixtures; production consumes materials and allocated crafting work. Manufactured components do not grant housing or service. A compatible occupied plot consumes a component, shares existing builder labor, completes assembly, pays for a separate trial, and receives a retained accepted/rejected/inconclusive result. Local foundations and adoption remain necessary. Installed records retain the selected detail and response evidence; invalid or copied-to-another-plot records are rejected.

Accepted details affect existing operations: bounded rain transfer reduces the rain portion of earthen wear; shading influences capacity-constrained household allocation in hot weather; structural qualification failures prevent further loading upgrades; installed details require supplied repair components. Negative observations do not install hardware. Trials, failed records and repairs neither grant free materials nor increase population. GovernmentPeopleSystem remains the labor owner.

City demand feeds existing workshop recommendations and intercity trade. Destination stock and incoming shipments suppress duplicate requests; transport retains route knowledge, carrier capacity, source reserves, travel time and actual stock debits. Player workshop orders remain explicit; rival controllers use recommendations. Secondary cities receive real components rather than independent free manufacturing.

Purchased research, scholar visits, bilateral study, destructive owned-specimen study and paid manufacturing licenses retain their existing disadvantages. Tests exercise all ten isolated candidates: costs/travel/local study, retained branch foundations, temporary teaching, both-party partnership work, consumed specimens, and 65% licensed production with supplier dependence. None grants equipment or research mastery for free.

Visual details are gated by accepted plot records. Later details follow actual wall blocks, retaining open courtyards and lower wings. Early overlays use finite asset wall profiles, preserve entrances and imported base meshes, and fit within reserved placement envelopes. Round front details follow the wall arc. Wind assessment has no invented permanent decorative apparatus.

## Verification

Final Godot 4.7.2 headless results, with this explicit worktree path:

- **66 gdUnit cases passed**, zero errors/failures/flaky/skips/orphans: building material operations, earthen buildings, secondary city design, architecture kit, organic town visual, early settlement visual, fabric delivery, acquisition, partnerships and specimens. `/tmp/tt-fabric-final-gdunit.log`; report 10; 47.922s.
- Added early geometry-envelope case plus the other five architecture cases passed: `/tmp/tt-fabric-final-envelope.log`; report 11; .314s. Fourteen early/organic assets × eight features have finite vertices, colors/normals, bounded dimensions and stable cached meshes.
- Seven standalone probes passed, exit 0 and no SCRIPT ERROR/ERROR text: `check_fabric_production`, `check_fabric_owner`, `check_fabric_jobs`, `check_fabric_save`, `check_fabric_inspection`, `check_fabric_response`, `audit_settlement_fabric_supply`. Scripts live in `tools/technology-review/`; logs `/tmp/tt-final-<script>.log`.
- Production verifies exact setup debit and finite manufacture for ten methods. Owner scenario uses actual daily allocated workshop work (including zero-worker refusal), then monthly selection/assembly/trial/installation. Save probe uses a unique temporary test slot, deletes only that slot, and verifies independent partial primary/secondary jobs, reload/resume and installed persistence.
- Supply audit: **878 isolated candidate definitions (868 base + ten candidates), 741 recipes including five analyses, 27 facilities**, nine closure rounds, no errors or blocked sources. Includes deferred trial inputs without invented extra recipes. Assumes all knowledge, raw-resource access and successful quality; does not prove campaign timing or geographic availability.
- Actual exported mesh geometry was inspected through matched-scale depth-buffered CPU projections. Evidence: `evidence/settlement-fabric-wall-block-review.png` and `evidence/settlement-fabric-early-review.png`. Export/render utilities are included. These are not GPU screenshots or technology-card artwork.
- `git diff --check` passed. No player/editor was launched, stopped or modified. Import initially failed; the documented temporary serial-import override recovered it and was removed. No project-settings changes are included.

Reproduce a standalone check with:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-settlement-fabric-processes --script tools/technology-review/check_fabric_save.gd
```

Run gdUnit with the same executable/path, `-s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode`, and `-a tests/<suite>.gd` for the named suites. Inspect logs as well as exit status.

## Integration and compatibility

No discovery registration, master-ledger acceptance or paper-and-gouache artwork changes. Integrator owns adding `settlement_fabric_knowledge.gd` entries to registration and reconciling the ten existing drafts. Do not count the 878 isolated audit as the canonical operating total. Main has advanced independently with artwork; this branch has not overwritten or merged those changes.

New modules: `settlement_fabric_knowledge.gd`, `settlement_fabric_operations.gd`, `settlement_fabric_response.gd`, `settlement_fabric_inspection.gd`. Additive fixtures/tests/audits/projections and this handoff accompany them.

Shared integration surfaces:

- `scripts/settlement_model.gd`: monthly work sharing, automatic supplied retrofit selection, trial progression, record resolution, rain/household/loading consumers, city trade targets and explicit plot APIs.
- `scripts/building_material_operations.gd`: plot record validation and component-paid maintenance.
- `scripts/building_material_investment.gd`: finite local/secondary component demand and supply recommendations.
- `scripts/civilian_industry.gd`: ten additive component recipes.
- `scripts/settlement_architecture_kit.gd` and `scripts/early_settlement_visual.gd`: record-gated mesh details and placement reservation.

No save schema version change. Canonical plots without optional fabric records retain prior behavior; invalid optional records fail validation. Existing canonical saves cannot contain these unregistered component lines. Experimental worker saves with earlier timber-only fixtures retain their paid setup records; retool those lines if reusing them. Existing unrelated production lines are untouched. No terrain, government, discovery-system, military-campaign or save-system source edits.

## Limits retained for review

These are selected game response models with normalized detail dimensions and uncertainty, not calibrated structural engineering or a universal solver. Tests cover all method contracts and selected causal consumers, not a complete 2,500–3,000-year campaign. Bounded front-façade representatives are not detailed construction drawings. GPU lighting/shadow appearance and full-city composition are unverified; the integrator explicitly accepted headless geometry/material/bounds and limited projection review for this worker. No interactive capture is required for this delivery.

Known broader pre-existing work remains outside this batch: late generic fabric upgrades use raw Iron Ore/Limestone/Fine Sand and generic housing-progress capacity increments lack this component debit model. This batch does not claim to finish those systems, the complete military tree, full-history pacing, or the 5,000-discovery objective.
