# Settlement fabric implementation — HELD

Worktree: `/Users/seanpurtill/Documents/Codex/tt-settlement-fabric-processes`; branch `codex/settlement-fabric-processes`; base `41f5b51b21f3d0884d957374ab1b824d241e9e0b`.

Authorized scope: ten existing draft identities, without discovery registration, artwork or master-ledger changes. Integrator owns promotion. No operating count increase is claimed.

- timber_post_beam_connections
- timber_splice_connections
- timber_lateral_bracing
- timber_moisture_movement_design
- building_drainage_coordination
- building_wind_load_assessment
- building_capillary_breaks
- roof_flashing_interfaces
- rainscreen_wall_assemblies
- building_shading_design

## Verified integration points

BuildingMaterialOperations owns paid material profiles, construction progress, curing, decay and material-consuming repair. SettlementModel creates per-city plots, supplies their bills, progresses construction and retains appearance/history. GovernmentPeopleSystem remains the workforce authority. Extend existing records rather than create duplicate building or labor owners.

The relevant external prerequisites are already in the implemented baseline. Aerodynamics is registered through civilian_science_knowledge.gd, with structural_load_testing and experimental_controls parents. Preserve all authored ALL/OR arrays; no placeholder unlocks.

EarlySettlementVisual calls SettlementArchitectureKit before its material checks. That kit currently chooses masonry, industrial or modern from fabric_generation. Installed timber/envelope features must take precedence for new component records, while old records retain their existing fallback. Mesh cache keys and placement bounds must include installed component geometry.

## Implementation acceptance

Finite prepared components, actual local work and measured selected joint/load/moisture evidence must reach particular plots. Learning alone changes no building. Failed or interrupted work cannot grant installed service. Paid retrofit completion changes only its target; repairs consume compatible stocks and work. Old and new fabric must coexist through save/reload. Construction must operate in the existing daily/city scheduling and shared workforce budget; no independent worker allocation.

Validate all ten acquisition routes with retained prerequisites, disadvantaged foreign recovery and actual local demonstration. Verify finite supply closure, negative outcomes, interruption/save, multiple cities and bounded renderer behavior. Headless checks only. No universal structural solver or prerequisite calibration cascade.

## Separately recorded gaps

SettlementModel._fabric_upgrade_cost uses raw ore, limestone and sand for tier 11+ urban upgrades. SettlementConstruction.process_day has a housing_progress capacity increment without a material debit in that branch. These require separate owner review and are outside this bounded implementation.

## Current status

Scope and owner inspection complete. Runtime implementation, component recipes, renderer changes, acquisition validation and tests remain undone. No save changes, game launch or completed delivery claim.

## First implementation checkpoint

Added settlement_fabric_knowledge.gd with ten unregistered entries preserving exact authored names and ALL/OR arrays. Added ten finite intermediate recipes to CivilianIndustry. These prepare components, not installed structures; no resulting service or successful inspection is claimed. Current generic timber tooling must be reviewed against available craft tools before delivery.

A Python comparison verified the ten prerequisite copies. Git whitespace check passed. First isolated headless editor import terminated with exit 139 after an engine propagate_notification caller-thread error (/tmp/tt-fabric-import.log); this is a failed import check, not passing runtime evidence. No player was launched or stopped. Installed components, measured rejection, paid retrofit/repair, rendering, save validation, acquisition and supply checks remain unfinished. Delivery remains HELD.
