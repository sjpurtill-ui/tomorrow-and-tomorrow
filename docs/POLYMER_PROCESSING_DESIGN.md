# Polymer production implementation contract

Status: active implementation design, not a runtime delivery. Base: `6d89ae93ada82b4d12e70a7211dd820dff44a6c5` (740 integrated discoveries). Owner worktree: `/Users/seanpurtill/Documents/Codex/tt-polymer-processing`, branch `codex/polymer-processing`.

`polymer-processing-scope.json` preserves the 25 existing authored identities and their complete original AND/OR predicates. All 25 are reachable in four successive layers from the verified 740-definition baseline. This establishes family research closure, not physical supply closure or historical pacing.

## Operating design

Existing PersistentProduction remains the owner of installed workshop lines, paid materials, shared Crafting work, production targets and settlement stocks. Polymer processing must use that owner. Imported compatible resin can supply an adopted fabrication operation; owning resin does not teach synthesis. Existing research licenses retain their disadvantaged operating terms. No second population, clock, stockpile or save authority is introduced.

Separate chemical identity, grade, forming process and intended application. A melt-processable polyethylene grade cannot stand in for an arbitrary polyurethane, polyamide or solvent. Filled or foamed material cannot silently satisfy an unfilled electrical-insulation requirement. A shaped container does not automatically become a pressure vessel, sterile vessel or food-safe package.

Analytical discoveries must affect a specific operating decision: whether a real feed and process can produce an application-qualified grade. Qualification consumes samples, instrument operation and staff work; its applicability must include material formulation and process conditions. A global reusable stock called “quality certificate” would make unrelated lots interchangeable and is rejected. Evidence of a completed short exposure test does not prove unlimited outdoor lifetime.

## Distinct capability contracts

| Existing discovery | Required physical consequence |
| --- | --- |
| Industrial catalyst design | Qualify a named catalyst for a named reaction; consume catalyst preparation and representative feed in trials; synthesis uses that compatible catalyst and pays replacement/deactivation costs. |
| Polymer-chain models | Evaluate a specific material model against observations and select compatible processing/application bounds. No increase in all industrial output. |
| Thermoplastic processing | Heat and consolidate compatible resin with real heat, equipment and work; reject thermoset substitution. |
| Polymer molecular-weight control | Change and measure a named synthesis grade; distribution-sensitive forming uses that grade, not a universal strength bonus. |
| Polymer additive formulation | Consume named additive and compatible resin into a distinct compound with an explicit application. |
| Polymer monomer purification | Consume an existing impure chemical stream, separation operation and rejects to obtain the same chemical at a suitable grade. Does not synthesize missing monomers. |
| Radical-chain polymerization | Consume a compatible vinyl feed, initiation inputs and controlled reaction capacity into a specified polymer grade. |
| Ionic-chain polymerization | Use a separately compatible feed/initiation system with contamination constraints and a distinct output application. |
| Coordination polymerization | Consume compatible olefin feed and a qualified coordination catalyst; resulting grades differ from radical products. |
| Condensative step polymerization | Consume chemically complementary functional feeds with stoichiometric control and removal of reaction coproducts. |
| Additive step polymerization | Consume complementary reactive feeds; do not add fictitious condensation water to a polyaddition process. |
| Ring-opening polymerization | Consume a named cyclic feed and compatible initiation/catalytic system; do not substitute generic olefin feed. |
| Copolymer sequence control | Consume the actual two feeds and compatible synthesis process; produce a named sequence-dependent material used by a distinct application. |
| Polymer tacticity characterization | Consume representative samples and instrument work to qualify ordering for the specific material; forming uses the qualification. |
| Polymer reaction heat management | Bound reactor batch/throughput by actual available heat-removal capacity; insufficient capacity stops or reduces paid work before input debit. |
| Polymer solution processing | Dissolve compatible resin in the named solvent, form a compatible film/coating, and account for solvent leaving the product. |
| Polymer melt rheology | Evaluate flow behavior for a particular grade and thermal history; high-demand forming must use suitable material/process conditions. |
| Polymer injection molding | Consume compatible melt grade and paid mold/machine operation into actual molded machine or electrical components. |
| Polymer blow molding | Consume suitable parison/preform and compressed air with forming tools into unpressurized hollow containers. |
| Polymer film extrusion | Consume suitable resin and powered extrusion/cooling into film; downstream wrapping or dielectric assembly consumes it. |
| Polymer thermoforming | Consume suitable sheet, heat and paid vacuum/air operation into shaped trays or housings; include trim loss. |
| Polymer foam cell control | Consume compatible formulation and blowing inputs into a distinct foam used in a real insulation/padding assembly. |
| Polymer weathering trials | Consume samples and finite exposure/test work; bounded qualification affects an outdoor application, not all resin forever. |
| Polymer solvent recovery | Recover a fraction of a named spent solvent stream using separation energy/work; remainder is lost/residue and recovered purity limits reuse. |
| Selective polymer depolymerization | Process only a specifically supported polymer into its actual recoverable chemical feed; finite recovery and purification costs prevent a material multiplier. |

## Physical supply gap found before registration

The base supplies industrial gases, acids, caustic soda, pressure vessels, electricity, and machinery. It does not currently supply the distinct monomers required for the six selected synthesis mechanisms. Treating bitumen as ready-to-use monomer would hide missing chemistry.

The existing authored `hydrocarbon_catalytic_cracking` identity has research closure through `fuel_refining` and the selected `industrial_catalyst_design`. It is reserved as a possible additional physical-closure discovery. It can support a defined hydrocarbon product distribution; it cannot by itself supply every aromatic, cyclic and bifunctional monomer. Upstream transformations must be explicitly modeled and assigned to a justified discovery rather than bundled under purification. This is unresolved implementation work, not an external blocker.

Proposed downstream consumers are existing insulated-cable assemblies, actual machine components, film-consuming electrical assemblies and compatible container/insulation users. Exact stock/resource mappings remain pending material-chain selection. Existing glass vessels, ceramic insulators and metal machine components retain their own routes.

## Acceptance needed for runtime delivery

- Preserve exact original research predicates and validate all production dependency paths.
- Demonstrate a paid end-to-end synthesis and forming chain reaching a real downstream operating consumer; exercise each distinct selected mechanism and application, not just dictionary presence.
- Demonstrate wrong resin, catalyst, solvent and grade rejection before resource debit.
- Demonstrate sample/qualification scope, real work and energy limits, heat-removal constraints, fractional production and finite coproduct/recovery balance.
- Demonstrate imported resin fabrication without synthesis mastery; licensed operation retains cost/throughput disadvantages.
- Demonstrate autonomous supply planning for real demand without an unlimited speculative inventory.
- Demonstrate existing primary and secondary settlement isolation and save continuation using the established owners.
- Run relevant production/graph/acquisition regression once after the coherent family, then rerun only checks affected by fixes.
- Leave all 25 identities in authored status until verified runtime promotion by the integrator. Imagery and long-run pacing remain separate unfinished requirements.

## Technical references used in design

- [Open University: manufacturing and process methods](https://www.open.edu/openlearn/science-maths-technology/chemistry/introduction-polymers/content-section-6.2): forming method determines equipment and shape constraints.
- [Open University: blow moulding](https://www.open.edu/openlearn/science-maths-technology/engineering-technology/manupedia/blow-moulding): extrusion/injection supplies the parison; forming requires the subsequent blowing operation.
- [University of York, Essential Chemical Industry: polyamides](https://www.essentialchemicalindustry.org/polymers/polyamides.html): condensation and cyclic-feed routes require different inputs. Full-page retrieval was unavailable during initial review; do not use the search excerpt as sufficient evidence for detailed recipe chemistry.
- [University of York, Essential Chemical Industry: polymers overview](https://www.essentialchemicalindustry.org/polymers/polymers-an-overview.html): formulations and shaping operations have distinct functions. Detailed material recipes still require source verification.

## Initial implementation, unfinished

Nine additive definitions now exist in `scripts/civilian_industry.gd`; their exact parameters are mirrored in `polymer-initial-products.json` for review. They connect a light refinery fraction, crude and separated ethene, LDPE resin, consumed batch characterization, pellet preparation, consumed flow qualification, extruded film and an existing insulated-cable consumer. Each qualification transforms and consumes that named material batch; there is no transferable certificate stock. Yield and time numbers are provisional game-batch quantities, not measured industrial yields.

The first chain uses high-pressure radical polyethylene. [University of York's polyethylene article](https://essentialchemicalindustry.org/polymers/polyethene) distinguishes this oxygen/peroxide-initiated route from low-pressure catalytic routes. Its [applications discussion](https://www.essentialchemicalindustry.org/polymers/polyethene.html) supports LDPE film and electrical insulation as compatible uses.

This code is **HELD and unverified**, not an integration candidate. Seven recipe gates still require registration (six original family identities and a requested distinct steam-cracking discovery). The base's Bitumen resource is a coarse petroleum representation; the refinery-cut assumptions require explicit review. High-pressure reactor capability, finite heat-removal operation, actual analytical instruments, automated demand and full-chain tests remain unresolved. Ordinary pressure-vessel inventory alone is not sufficient evidence for an industrial high-pressure polymerization reactor. No runtime promotion or art-count change is authorized by this checkpoint.

Static recipe review found existing providers for named nonraw inputs other than the base Steel provider missed by the narrow JSON-line scan; Bitumen, Freshwater and Timber use existing raw resources. This scan is not the Godot dependency audit and does not establish production reachability. `git diff --check` passes. No runtime test suite has been run on this unfinished chain.

### Reactor-capacity checkpoint

Added paid reactor and cooling-circuit equipment plus two TechnologyOperations installations. The LDPE job consumes both daily reactor work and heat-removal service, with fractional work capped before any debit. Existing operations reserve Crafting staff, spend power/water/maintenance, commission paid equipment and expire service daily. Eight worktree discovery entries preserve original predicates (including the now-authored steam-cracking addition); this remains a partial family implementation.

Three initial behavioral cases pass: no cooling means no feed debit; partial cooling bounds work and is spent once; crude propene cannot substitute for purified ethene. A subsequent five-case run also passes paid commissioning after correcting an underprovisioned water fixture, but the actual daily-step case reports two runtime errors in knowledge-pathway traversal. The original heat-management OR includes condensative_step_polymerization and additive_step_polymerization, which are not registered yet. Graph audit also fails during that traversal. Resolve the complete family registration and operating consumers before claiming acceptance. Logs: `/tmp/tt-polymer-tests.log`, `/tmp/tt-polymer-capacity-ready.log`, `/tmp/tt-polymer-graph.log`. Initial import completed cleanly. No integration, runtime promotion or full-history pacing claim.

### Daily traversal fix and first end-to-end evidence

DiscoverySystem.technology_depth now returns zero for an absent definition before traversing it. It neither inserts that ID nor grants a root discovery. A regression verifies both the zero result and continued graph rejection of the unknown parent. All eight polymer tests pass in `/tmp/tt-polymer-chain-ready.log` (zero errors/failures/skips/orphans). The earlier commissioning and actual-daily checks are included.

The new end-to-end test starts with existing nonpolymer materials and tooling as fixture inputs, explicitly allocated daily service budgets, and no polymer intermediates. It executes all nine transformations through PersistentProduction and obtains two units of the existing Insulated Cable resource while consuming 640 Bitumen, twelve reactor-work units and twenty-four heat-removal units. The fixture retires each completed line through the existing cancel API before paying for the next setup; it does not raise the one-line starting capacity. This proves sequential paid material transformations, not autonomous production planning or a self-powered historical campaign.

A separate test consumes imported Characterized LDPE through an adopted pelletizing operation while synthesis knowledge remains absent and its synthesis recipe remains locked. The test represents delivered material as fixture inventory; it does not prove the trade delivery mechanism.

The graph audit now terminates normally with exactly two unknown-prerequisite errors: condensative_step_polymerization and additive_step_polymerization in the unchanged heat-management OR group. It reports 748 worktree definitions, not 748 integrated/complete discoveries. Canonical count is unchanged by this isolated work. Remaining family branches, upstream chemistry, qualified analytical instrumentation, automated demand, save/settlement coverage and full-history requirements remain unfinished.

### Injection and sheet-forming branches

Added five recipes: molding-grade LDPE qualification, forming-sheet extrusion, injection-molded covers, pressure-formed/trimmed covers, and existing telephone-set assembly using those covers. Both cover routes retain a timber internal mounting base. They represent low-load protective covers, not structural machinery, pressure vessels, or a weatherproof certification. The material/application choice is a game-design inference from the cited polyethylene source's injection-molded-product and sheet/film uses.

The two discoveries preserve their original predicates. Injection molding requires melt rheology AND precision machinery; thermoforming requires thermoplastic processing AND one of vacuum pumps, compressed air systems or precision machinery. This implemented pressure-forming operation specifically consumes compressed air even when another research route supported discovering thermoforming. Discovery and the chosen physical operation are separate constraints.

All nine focused cases pass in `/tmp/tt-polymer-forming-tests.log`, zero errors/failures/skips/orphans. The new case consumes the two distinct material grades through both forming paths and then spends both covers in existing Telephone Sets. No broader suite was repeated. The isolated family now has sixteen recipes, two plants and ten registered discovery definitions (nine of the original twenty-five plus steam cracking). Sixteen original family identities, the optional catalytic-cracking closure, fuller chemical inputs and the previously stated acceptance requirements remain unfinished. No runtime promotion is requested.
