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

## Paid plot-job state

Added SettlementFabricOperations with ten method/component mappings, start-time debit, one pending job per plot, shared-work input API, same-day guard and an awaiting-inspection state. Assembly never modifies inherited appearance or grants service. Added a headless assertion probe for all ten methods covering missing knowledge, debit, duplicate start, partial work, JSON serialization, exact remaining work, inspection hold and malformed paid state.

Godot check-only parse passed. `--headless --path /Users/seanpurtill/Documents/Codex/tt-settlement-fabric-processes --script tools/technology-review/check_fabric_jobs.gd` passed, exit 0, /tmp/tt-fabric-jobs.log. This is a module test, not daily city scheduling, full save compatibility or supply closure. The earlier editor import failure remains recorded; this narrower invocation did not reproduce it.

The module is not yet connected to plot scheduling or save validation. Inspection acceptance/rejection, selected physical evidence, repair, rendering and all acquisition paths remain outstanding. HELD, unregistered.

## Construction owner integration

SettlementModel.start_fabric_retrofit now starts against the selected city's existing plot, stocks and adoption. Monthly construction counts assembling retrofit sites alongside buildings, water and rail before dividing the same builder pool. Awaiting-inspection jobs receive no assembly labor. BuildingMaterialOperations.valid_plot now validates optional fabric jobs, including through its existing primary/secondary state traversal.

Actual-owner headless probe passes: debit, positive monthly work, repeat-month guard, JSON plot persistence and malformed job rejection. Log /tmp/tt-fabric-owner.log, exit 0. Initial probe compile failed because direct SceneTree scripts cannot resolve the autoload identifier at compile time; runtime root lookup corrected the probe. The module probe also passes after integration. These checks do not prove whole-save reload, all cities, all ten daily acquisition routes or workforce balance under a mature campaign.

Automatic selection, method compatibility and qualification, inspection, installed records, paid repair, renderer/cache/bounds changes remain unfinished. No registration or promotion.

## Branch and compatible-fabric guards

Retrofit start now checks every authored ALL parent and one member of each OR group directly from the unregistered knowledge definitions before payment. Occupied building land uses and recorded material families constrain applicability: timber methods require timber/organic fabric, capillary breaks require stone/earth, and fields or encampments are excluded. This is a coarse first compatibility boundary, not qualified geometry or engineering acceptance.

Expanded headless module checks pass for each missing ALL parent, absent OR group and each alternate OR member, plus incompatible-use rejection without payment. Actual settlement-owner probe passes with the shading foundations present. Logs /tmp/tt-fabric-all-or.log and /tmp/tt-fabric-owner-branches.log, both exit 0. Exact branch checks do not prove research acquisition or global reachability. Inspection and final installed service remain pending.

## Selected inspection classifier

Added separate method-specific observation contracts for joint slip, splice opening, braced drift, restrained moisture movement, retained runoff, wind-load residual displacement, capillary uptake, flashing leakage, rainscreen wetting and shade transmission. Each produces accepted, rejected or inconclusive outcomes. Missing/negative/nonfinite observations, inadequate excitation and exposure outside the selected reference envelope cannot pass; uncertainty crossing a limit remains inconclusive.

Thresholds are explicitly original bounded game specifications in normalized measurement units, not universal engineering recommendations. This classifier consumes observations; it does not produce them, prove their provenance, or install components. Paid site-trial production and retained physical geometry remain required before runtime acceptance. No caller-provided result is currently sufficient to grant building service.

Ten-method headless classifier probe passes acceptance/rejection/uncertainty, insufficient and out-of-envelope exposure, NaN and missing measurements. /tmp/tt-fabric-inspection.log, exit 0. Whole gameplay, inspections under city work budgets, physical failure consequences and visuals remain unfinished. HELD.

## Paid inspection labor

Added explicit trial start after assembly, finite method-group material bills, retained paid trial state and one unit of inspection work supplied through the existing retrofit builder allocation. Water trials require freshwater/absorbent material; selected load trials reserve stone/timber; shading trials reserve timber/fiber apparatus. Costs are game batches and will need apparatus/source refinement before acceptance. No automatic inspection acceptance exists.

Testing jobs share the scheduler denominator through needs_work; finished trials become awaiting_observations and release the builder slot. City-scoped start_fabric_trial pays from that city's stores. Job validation covers trial payment, date ordering, work bounds and assembly completion. Ten-method module probe passes missing-material rejection, exact payment, same-day guard, partial-trial serialization, final observation hold and duplicate trial rejection. Existing owner probe passes after these changes; logs /tmp/tt-fabric-paid-trials.log and /tmp/tt-fabric-owner-trials.log, exit 0.

Still required: actual selected site response production, evidence-to-installed linkage, rejection/rework and repair, automatic construction choices, renderer behavior, all acquisition routes, supply closure and full save/city tests. HELD, not a physical operating delivery.

## Retained site response model

Assembly start now retains a selected detail and the existing plot's support condition. Paid trial completion calculates a response from joint stiffness/clearance, moisture allowance, drainage capacity/blockage, elastic reserve, capillary bridging, flashing overlap, rainscreen drainage or shade projection/aperture. The observation then enters the separate uncertainty-aware classifier and is retained with the trial. No caller pass/fail flag supplies the result.

These are deliberately bounded normalized game models with standard component dimensions, not calibrated engineering predictions. Site condition is currently sampled at project start; local deterioration during assembly, detail variation and more specific support qualification remain limitations. Nothing yet promotes these results to installed service or appearance.

Headless job probe passes with generated observations. Response probe verifies sound-support acceptance and degraded-support non-acceptance for all ten, stable serialization and invalid-state refusal. Initial test wrongly required definite rejection for every degraded specimen; the rainscreen result overlaps the uncertainty band and correctly remains inconclusive. Changed the expectation to non-acceptance, retaining the inconclusive behavior. Failed probe was stopped by its exact isolated process command; no player/editor stopped. Final /tmp/tt-fabric-response.log exits 0. Acceptance linkage, rework/repair, renderer, automated selection and acquisition/supply evidence remain outstanding.
