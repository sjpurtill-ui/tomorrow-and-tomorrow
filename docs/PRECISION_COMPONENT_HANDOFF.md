# Precision component processes

Integrator worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/precision-component-processes`, initial base `61403ea`; subsequent catalog-only prerequisite commits through `a067ace` were separately integrated before this runtime delivery. Owned files: new precision-component knowledge and tests, additive CivilianIndustry recipes and DiscoverySystem registration, five explicit research-art assignments/imports and this handoff. Shared Industry/Discovery additions from the concurrent polymer task must be retained at its later integration.

Five existing authored identities retain their exact predicates: reamed_bore_finishing requires column_drilling_machines and dimensional_metrology; reciprocating_profile_slotting requires crank_linkages and toolbit_heat_treatment; gear_shaping_generation requires gear_tooth_generation and precision_machinery; progressive_profile_broaching requires toolbit_heat_treatment and precision_machinery; interchangeable_component_fits requires dimensional_metrology and workshop_standards. None has an OR group or arbitrary global effect.

Fourteen paid recipes add finishing reamers, pilot-bored sleeves, finished sleeves, turned shafts, matching gauges, interchangeable bearing assemblies and a compatible existing-motor output. Separate recipes supply crank-driven slotting rams, single-tool keyed hubs, progressive broaches, broached hubs, existing clutches assembled around those hubs, relieved gear-shaping cutters and compatible generated gear sets. Reaming consumes a prepared hole and tool wear. Broaching trades expensive tooling for less repeated cutting work than slotting. Shaping consumes a separate cutter and reciprocating/indexing setup rather than silently reusing hobbing geometry.

The selected nominal 20 mm shaft/sleeve family is a specific game product grade. A rough sleeve or generic Shaft Bearings stock cannot replace a finished sleeve. Fit checking consumes real shafts, sleeves, lubricant, sample material, work and installed family-specific gauges. Its output is the actual matched metal assembly consumed by motor manufacture, not a reusable quality token. Compatible imports can supply a known operation without teaching manufacture. Existing motor, clutch, gear and machining routes remain available.

PersistentProduction retains all installed tools, partial work/material payments, target stock and workforce ownership. There is no new clock, resource owner, plant, population effect or top-level save state. Tooling is paid at setup and batch inputs/wear are paid proportionally with work. Existing geared-workshop commissioning consumes the produced gears and aligned drive assembly; real generator fuel, operators and upkeep are still required before mechanical service exists.

## Limits and compatibility

Dimensions, tolerance distribution, surface finish and reject selection are bounded named-grade/paid-work abstractions, not a geometric machining simulator. The model does not generate arbitrary CNC geometry, measure individual shafts, or guarantee universal interchangeability. Material allowances include removed/rejected stock without a new scrap, pollutant or mass-unit simulation. Numeric recipe quantities and relative work costs are game tuning, not factory operating guidance.

Old recipes and stored jobs are unchanged. New stock names and new partial jobs use existing stock/save validation; full binary SaveSystem continuation and actor isolation are tested. Imported-stock tests provide materials as fixture inventory and do not independently prove trade delivery. The end-to-end fixtures supply existing nonfamily tooling/materials and explicitly learned methods; they demonstrate paid transformations and a real workshop consumer, not an autonomous historical bootstrap or full campaign pacing.

## Sources

- [Liebherr gear shaping](https://www.liebherr.com/en-gb/gear-technology-and-automation-systems/information-service/customer-magazine/evotion-22/gear-shaping/double-helical-gears-4643204) supports the distinct reciprocating generating method.
- [Original broaching technical chapter](https://www.americanmachinist.com/cutting-tools/media-gallery/21135347/chapter-14-broaches-and-broaching-cutting-tool-applications) explains successive cutting teeth; this is the author's machining textbook exposition.
- [Hoffmann slotting/broaching application](https://www.hoffmann-group.com/HR/hr/rotometal/areas-of-application/machining/broaching-garant/e/68141/) supports repeated single-tool internal profile cutting.
- [Sandvik reaming](https://videos.sandvik.coromant.com/reaming-in-inconel-with-cororeamer) supports finishing a prepared bore with a multi-edge tool.
- Existing dimensional-metrology and workshop-standard foundations support the selected compatible component family; exact game grades, costs and consumers are design choices.

## Verification

91 isolated runtime cases pass with zero errors/failures/skips/orphans: precision components 10, mechanical drives 6, machine-tool production 7, workshop investment 6, persistent production 19, civilian planner 15, owned simulation 19, dependency audit 9. The first focused run had integer-versus-float expectation mistakes; corrected expectations pass without changing runtime behavior.

New tests cover all fourteen routes' fractional payment/save continuation, reamer-to-motor material consumption, slotting/broaching/shaping through paid geared-workshop operation, wrong/unprepared components, missing setup tools, tool-wear depletion, zero work, imported feed without synthesis mastery, planner/controller route choice, actual daily production and repeat-day guarding, actor isolation and full binary save continuation. The isolated graph is clean at 745 discoveries / 527 routes / 416 recipes / 20 facilities with all declared products and plants reachable. Graph closure is structural rather than campaign proof.

Five native illustrations were personally reviewed and copied with originals retained; prompts and paths are in `assets/ui/research/paper/PRECISION_COMPONENT_PROMPTS.md`. All five 768-pixel/mipmap loads and 12 atlas tests pass in the worktree. The art catalog reports 167 verified images for 745 live definitions, 578 queued. Canonical verification and exact runtime snapshot promotion remain pending. No player game or editor was launched or stopped.

Canonical acceptance at `0ecb2a1f459625f4dd72d58abc4b4f63afc01462`: precision10, drives6, planner15, owned simulation19 and dependency audit9 pass (59 runtime cases), plus12 atlas. All five textures load at768 pixels with mipmaps. Exact745-definition snapshot and15ledger tests pass; graph745/527/416/20 is clean. A three-frame startup had2ObjectDB/1resource-in-use cleanup warnings; a verbose repeat and30-frame startup were clean. This intermittent early-exit observation remains recorded, without unrelated fixes. No player launch or package rebuild.
