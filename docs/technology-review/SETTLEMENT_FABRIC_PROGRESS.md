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

## Trial resolution and installed records

Monthly owner now resolves finished paid trials. Accepted results create one method-keyed installed record on the target plot; rejected/inconclusive results retain only the latest bounded outcome and do not install. Pending work is cleared after resolution without a material refund. Resolution recomputes observations/classification from retained assembly and requires matching recorded results; copied records on another plot fail validation. Primary/secondary plot validation covers installed records and latest outcome.

Ten-method job checks pass positive resolution, repeat-resolution refusal, plot-ID mismatch, forged classification rejection and non-acceptance without installation. Initial serialized resolution exposed exact floating-point dictionary equality; result comparison now requires identical keys/states and numeric differences no greater than 1e-9 while recomputing the authoritative result. Final /tmp/tt-fabric-resolution.log passes, exit 0. Owner probe also passes (/tmp/tt-fabric-owner-resolution.log). Failed exact probe was stopped by its explicit isolated command only.

Installed records are not yet consumed by renderer or operating benefit/repair logic. No completed discovery claim. Next: installed-feature renderer/cache/bounds, condition-aware maintenance and actual downstream consequences, automated selection, all-method city/save/acquisition and supply verification.

## Installed details in later architecture

SettlementArchitectureKit now reads validated plot-bound installations into feature flags. Accepted timber connection assemblies override the late generation-selected family; missing records retain exact legacy family selection. Meshes add bounded representatives for posts/beams, bracing, movement seams, runoff channels, flashing, rainscreen battens, shade lattices and capillary courses. Wind assessment remains evidence rather than fictitious visible hardware. Feature flags participate in both mesh cache and MultiMesh group keys. EarlySettlementVisual's later-kit placement envelope now uses the same feature-bearing mesh as rendering.

Headless mesh checks pass accepted-record filtering, legacy feature absence, timber precedence, cache reuse, distinct shade mesh and expanded shade bounds. /tmp/tt-fabric-render.log, exit 0. These are mesh assertions, not rendered visual QA. Shapes are currently generic late-building representatives; type-specific detail alignment and early-generation overlays remain unfinished. All generation<4 early forms still use their old renderer; do not claim early installed features visible yet. Operating effects, repairs, automated starts, full acquisition/supply and campaign verification also remain pending. No registration.

## Early-building overlays

Added separate MultiMesh installed-detail overlays for the early authored kit and supported organic-town variants. Original imported meshes and their LOD/shadow data are retained. Detail geometry scales to each source mesh's bounds and shares its transform. Ruins, reclaimed/unfinished plots and severe structural damage suppress overlays. Missing accepted records create no overlay.

Placement uses base-plus-overlay bounds for explicit early kit forms; organic-town variant selection occurs later, so its finite kit's maximum expanded extent is reserved conservatively. Late architecture continues using its own installed mesh bounds. Separate overlay cache keys include the source bounds and feature flags.

Headless parsing of EarlySettlementVisual passes. Extended mesh probe verifies scaled early shade extent and overlay cache reuse; all previous job/record/mesh assertions pass, /tmp/tt-fabric-early-bounds.log, exit 0. This does not verify rendered alignment, visual quality or neighborhood clearance at actual loaded coordinates. Generic facade detail placement needs review against curved/irregular buildings before READY. Operating consequences, repairs, autonomous starts, acquisition and full supply/save/city checks remain unfinished.

## Condition-dependent weather service and paid maintenance

Accepted installed records now produce a service observation using the lesser of current plot condition and originally qualified support condition. Repairs cannot exceed the tested design. Flashing/rainscreen response affects only a selected 20% interface share of earthen-wall rain exposure; other exposure remains. This is a bounded game allocation, not a measured universal wall coefficient. It does not reduce unrelated hazards or give knowledge-wide bonuses.

Existing supplied maintenance is capped by available installed replacement component stocks and debits them in proportion to the work actually delivered after base-fabric material payment. With no installed records its old bill remains unchanged. All ten installed component types contribute a finite aggregate replacement requirement; detailed repair methods and dismantling are not yet modeled.

Headless job/service checks pass insufficient repair supply, partial repair debit, condition-dependent rain transfer and bounded protection; existing actual-owner probe passes. Logs /tmp/tt-fabric-service.log and /tmp/tt-fabric-service-owner.log, exit 0. Need broader tests of actual earthen monthly wear/repair and mixed-city save state. Structural service, runoff/capillary/shading consumers, autonomous starts, acquisition, supply closure and rendered visual QA remain incomplete. HELD.

## Autonomous monthly cycle

The existing monthly owner now starts affordable trials for assembled jobs and selects up to one new supplied retrofit each month, capped at two pending jobs per city. Selection respects adoption, ALL/OR, compatible fabric, real stock, condition and existing installations. It prioritizes weather protection on exposed buildings. Buildings below .35 condition first need stabilization. Failed/inconclusive methods retain a bounded per-method record and are not automatically retried until support condition improves by more than .05. This avoids rotating through unchanged failures and repeatedly consuming materials.

An actual-owner headless probe now exercises autonomous selection, start debit, monthly assembly, automatic paid trial, acceptance into the plot and validation, without direct start calls. It passes along with ten-method job/record tests. /tmp/tt-fabric-autonomous-cycle.log and /tmp/tt-fabric-auto-jobs.log, exit 0. This proves one supplied shading cycle, not autonomous supply production or every method/city/research route. Slot and priority tuning remain game-balance assumptions. Registration, remaining structural/environmental consumers, supply closure, acquisition, full saves and rendered visual QA remain pending.

## Component supply recommendation

BuildingMaterialInvestment now recommends missing retrofit components for actual compatible plots, plus bounded installed-repair stock and pending trial input needs. It uses the existing recursive CivilianProductionPlanner; recommendations create no materials or jobs. Existing controller priority/food/war/city guards remain. A private prospective availability map identifies useful missing components without altering stock or bypassing actual payment.

Expanded actual-owner probe begins with timber/fiber, obtains the shading production recommendation, starts the existing workshop line, pays/advances its finite three-unit work and obtains one component, then completes autonomous monthly installation. /tmp/tt-fabric-produced-cycle.log passes, exit 0. The test advances workshop work directly; it does not prove daily controller production scheduling. Existing investment caller is CivilisationController, with primary-city guards; player/secondary-city automatic manufacturing coverage remains to be investigated, not claimed. Need all-ten supply/recipe checks and branch/acquisition validation. HELD.

## Structural evidence consumer

Retained joint/splice/bracing/moisture/wind trial outcomes now gate further inherited-fabric upgrades on that plot. Failed/inconclusive records block upgrading until successful rework supersedes them. Previously accepted details that no longer meet their selected envelope at current condition also block upgrading. Both candidate selection and the apply transaction check this before payment. Plots with no new optional evidence retain existing rules. A pass does not grant extra storeys or certify an arbitrary load.

Headless method checks pass failed-evidence blocking, sound qualification and degraded installed-service blocking for all five relevant methods. Actual produced shading cycle still passes. /tmp/tt-fabric-load-consumer.log and /tmp/tt-fabric-load-owner.log, exit 0. The generic existing damage event mixes fire/weather/structural failure, so it was not blanket-reduced by bracing. Explicit damage physics and positive structural capacity gains remain outside this narrow consumer. Runoff/capillary/shading service consumers, acquisition, full saves/cities and rendered review remain outstanding. HELD.

## Full game save round trips

Added an isolated SaveSystem probe using a process-specific worker slot. It saves a paid, partly assembled shading job, clears world actors, reloads through SaveSystem, verifies retained work and absent consumed component, rejects same-day repeat work, and resumes assembly/trial/acceptance. A second real save/reload preserves the installed record and shade renderer flag while repeat resolution remains impossible. Each created slot is deleted after its load; no existing user save is overwritten or removed.

`--headless --path /Users/seanpurtill/Documents/Codex/tt-settlement-fabric-processes --script tools/technology-review/check_fabric_save.gd` passes, /tmp/tt-fabric-full-save.log, exit 0. This covers one actor/primary plot and shading, not every method or secondary city. It advances the operation API directly after reload; autonomous daily scheduling remains separately bounded evidence. All-method acquisition/supply, remaining environmental consumers, multi-city save behavior and rendered visual QA remain unfinished. HELD.

## Ten-method production and structural supply audit

Added a combined production probe: each candidate contract validates against a local catalog copy, each recipe refuses missing inputs, partial work produces no completed component, and paid full work produces exactly one batch. No discovery registration occurs. /tmp/tt-fabric-production.log passes, exit 0.

Adapted the existing production/dependency audit as a new worker tool. It verifies exact authored names/ALL/OR against both source files, production bindings, complete candidate graph and current workshop/plant source closure. Result: 868 integrated +10 local candidates =878 graph definitions, 741 recipes including five conditional analyses, 27 facilities, nine closure rounds, zero errors or blocked products/plants. /tmp/tt-fabric-supply-audit.log, exit 0. This assumes knowledge, raw resources and conditional quality success; it does not establish quantities, calendar, site performance, operating capital or acquisition. The ten local candidates are not integrated discoveries. Deferred site-trial bills still need explicit audit alongside workshop inputs.

Remaining acceptance includes disadvantaged acquisition routes, secondary cities, outstanding environmental consumers, player/secondary production scheduling coverage and actual rendered review. HELD.

## Two-city saved work isolation

Extended the real SaveSystem probe with a secondary city holding a separate plot/job and local stores. An empty secondary component stock rejects start even while the primary city holds five spare batches. Supplying one local batch permits secondary work without changing primary stock or progress. Full reload retains .5 primary assembly work and .25 secondary work, independently, and rejects duplicate-day secondary advancement. Primary acceptance and a second installed-save reload still pass.

/tmp/tt-fabric-two-city-save.log passes, exit 0. This verifies scoped city work/stores and saved records, not autonomous secondary manufacture or every method in multiple cities. Test-created slot cleanup remains explicit. Remaining environmental consumers, acquisition routes, daily production coverage and rendered QA are still open. HELD.

## Drainage/capillary and shaded occupancy consumers

Earthen moisture exposure now has explicit bounded game shares: 60% unmodeled/unprotected, 20% envelope interface, 10% runoff and 10% capillary contact. Only accepted installed details alter their corresponding share, through current-condition response. These weights are game abstractions, not universal physical percentages. No discovery-wide effect applies.

Hot-weather occupancy uses current PlanetEnvironment ambient temperature and measured shade transmission to weight existing residential capacities. It preserves the exact housed population up to total capacity, redistributes capped/rounding remainder, and cannot create residents or housing. Cool conditions or absence of installed shade retain the previous allocation path. This is household placement preference, not a thermodynamic comfort or health solver.

Headless checks pass drainage/capillary effects, more shaded occupancy under heat, exact aggregate counts, full-capacity bounds and cool-weather fallback; autonomous produced-installation cycle remains green. /tmp/tt-fabric-environment.log and /tmp/tt-fabric-environment-owner.log, exit 0. An old exact lower-bound assertion hit floating-point rounding after exposure-share addition; test now allows 1e-9 arithmetic tolerance. Failed isolated probes were terminated by their exact test command. Rendered review, acquisition routes, full combined regression and all-city autonomous supply coverage remain outstanding. HELD.
