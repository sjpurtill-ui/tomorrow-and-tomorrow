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

### Condensation chain and restricted interior application

Added thirteen recipes for captured wood condensate, separated methanol, silver-bearing bullion, cupelled silver, a trial-qualified silver catalyst, formaldehyde solution, captured calcination carbon dioxide, urea, UF resin, substrate-specific adhesive qualification, graded interior wood, pressed interior panels and existing switchboard assembly. Silver Ore is a separate finite metal-ore catalog entry requiring ore assaying for recognition, using the existing extraction owner; Lead Ore is unchanged. Silver resource placement/extraction/save regression remains to verify.

Registered four existing authored discoveries with unchanged predicates: industrial_catalyst_design, condensative_step_polymerization, adhesive_bond_design and engineered_wood_lamination. Four distinct upstream identities have been requested from the integrator and their recipe gates are not registered yet: wood_methanol_recovery, silver_cupellation, formaldehyde_synthesis and urea_synthesis. No generic purification gate grants those transformations.

The resin is consumed through a paid sample/bond operation into Interior UF Wood Adhesive. Panels consume separately graded wood, that adhesive, pressing tooling and work. Their implemented consumer is indoor switchboard construction, retaining a timber mounting component. No exterior durability, universal substrate bonding, waterproofing or load-independent structural claim is made.

Ten focused cases pass in `/tmp/tt-polymer-condensation-tests.log` with zero errors/failures/skips/orphans. The added boundary-fixture test executes thirteen paid transformations, consumes sixteen units of separately supplied Silver Ore and two heat-removal units, and spends the resulting panels in two existing Telephone Switchboards. It supplies existing materials, tooling and service budgets; autonomous mining, prerequisite acquisition and a self-powered campaign are not proven. This remains HELD.

Additional sources: [FAO hardwood carbonization by-product recovery](https://www.fao.org/4/x5328e/x5328e0d.htm) supports wood-derived methanol as a material-expensive alternative; [Historic England archaeometallurgy](https://historicengland.org.uk/images-books/publications/archaeometallurgy-guidelines-best-practice/heag003-archaeometallurgy-guidelines/) covers silver refining; [ECI methanal](https://www.essentialchemicalindustry.org/chemicals/methanal) and [urea](https://essentialchemicalindustry.org/chemicals/urea.html) support the separate feedstock pathways; [ECI methanal plastics](https://www.essentialchemicalindustry.org/polymers/methanal-plastics.html) supports the UF resin family. All recipe quantities remain provisional abstract game batches, not industrial mass balances or operating instructions.

### Silver geography, stable generation and upstream registration

Added a deterministic geology-derived Silver Ore potential in PlanetEnvironment. Silver is appended after existing ResourceSystem catalog entries. A test compares actual generated preexisting deposit arrays with and without the silver entry over eight world seeds; arrays are identical and silver generation is observed. This verifies the relevant founding-generation loop, not every map/scouting path. Existing saved deposits are not regenerated.

Fourteen polymer cases pass in `/tmp/tt-polymer-resource-save-tests.log`, zero errors/failures/skips/orphans. New cases verify recognition requires ore assaying and does not grant stock, extraction reduces a finite deposit with conserved remaining-plus-extracted amount, geographic potential exists, and full SaveSystem save/load restores silver stock and deposit state. The existing nine resource-recognition cases passed separately in `/tmp/tt-polymer-silver-ready.log`; that combined run also had one polymer fixture type error subsequently fixed by assigning its typed deposit array. Do not describe the earlier combined run as green.

Read the four exact authored upstream rows from canonical commit `5c0d455` and registered them without copying or merging shared catalog ledgers. The graph now reports 758 worktree definitions and precisely two errors: missing additive_step_polymerization and missing enzyme_catalysis. The latter is an unchanged optional arm of industrial_catalyst_design; the valid alternative arms do not excuse removing its authored identity. Remaining family work is still HELD. No 758-working or canonical-integration claim is supported.

### Enzyme-catalysis closure

Enzyme Catalysis retains fermentation_control AND chemical_distillation. Its operating route uses selected pancreatic tissue from actual newly hunted rations, a separated enzyme fraction, a paid hide-substrate assay and a specific bating protease. Four recipes connect this to Bated Hides and the existing Tanned Leather/Flexible Leather chain. Existing vegetable tanning is unchanged and does not require this enzyme. The bated route's lower tannin/work quantities are provisional game balances for prepared pelts, not universal industrial yield claims.

HouseholdClothing's existing once-per-local-day owner collects a small pancreatic byproduct only with adopted enzyme practice, caps it at population*0.001, and retains only one quarter of stored tissue per day. Unqualified fraction retains half its activity-equivalent stock per day; qualified protease retains0.98. Those coefficients are explicit abstractions. No additional food worker, food conversion, population ledger or save field was introduced. Enzyme output is substrate-specific material, not a generic catalyst certificate.

Eighteen focused cases pass in `/tmp/tt-polymer-enzyme-local-tests.log`, zero errors/failures/skips/orphans. They include actual FoodSystem hunting versus stored meat, repeat-day protection, decline without new hunting, cap and secondary-city isolation, full save/load of qualified protease stock, and the paid enzyme-to-Flexible Leather chain. Twelve existing leather cases also passed in `/tmp/tt-polymer-enzyme-tests.log` (that run passed29cases combined). The later changes only expanded focused tests. Existing empty/older clothing ledgers need no new required field.

Sources: [UNIDO sustainable leather manufacture](https://www.unido.org/publications/ot/9653545/pdf) identifies specific pancreatic proteases in bating and their substrate/condition dependence; [UNIDO technologies from developing countries](https://downloads.unido.org/ot/46/90/4690534/00001-10000_08465-08605.pdf) describes pancreatic enzyme preparation for hides. The game abstracts extraction and qualification; it does not simulate individual enzyme molecules, species anatomy or detailed biochemical kinetics.

### Polyol-side operation and independent reactor capacity

Added six recipes: alumina support preparation from refractory clay, a separately qualified ethene-oxidation silver catalyst, separated ethylene oxide, hydrolyzed/separated glycol, a stirred polymer reactor, and ring-opened PEG diol. These are named materials; the formaldehyde catalyst is not treated as an interchangeable catalyst qualification. The two new upstream oxide/glycol identities are requested for authoring and remain unregistered pending their approved rows.

Ring Opening Polymerization retains its original industrial_catalyst_design AND (polymer_chain_models OR experimental_controls) predicate. It consumes epoxide and glycol initiation feed, reagents, shared work, electricity, stirred-reactor capacity and heat-removal capacity. The PEG diol's polyurethane downstream consumer remains unfinished; no completed capability claim is made merely from producing this intermediate.

Added a paid stirred-reactor installation under existing pressure-vessel/thermometry knowledge and a low-throughput cooling bath under calorimetry/pressure-vessel knowledge. These prevent mandatory mastery of the high-pressure radical route just to operate a different reaction family. The bath supplies0.2 heat-removal units using real operators and freshwater; the existing new controlled circuit supplies2.0 with paid machinery and power. Quantities are bounded game capacities, not heat-transfer engineering calculations.

Nineteen focused cases pass in `/tmp/tt-polymer-polyol-tests.log`, zero errors/failures/skips/orphans. The new case commissions the cooling bath without radical mastery, then demonstrates that its0.2 cooling capacity allows only proportional paid ring-opening work and no premature finished product. Stirred-work and electricity are explicit boundary-fixture budgets in that test. Full upstream-to-finished-polyurethane operation is not proven.

Sources: [ECI epoxyethane](https://www.essentialchemicalindustry.org/chemicals/epoxyethane.html) identifies supported-silver oxidation and glycol downstream use; [BASF alkylene oxides and glycols](https://chemicals.basf.com/global/en/Petrochemicals/alkylene-oxides-and-glycols/products) and [Dow polyols](https://www.dow.com/en-us/product-technology/pt-polyurethanes/pg-polyurethanes-polyols.html) support the distinct oxide/polyol supply family. Alumina-support preparation and all batch coefficients still need detailed material-grade review before integration. Work remains HELD.

### Isocyanate supply and operating polyurethane consumer

Added twelve feed/catalyst recipes covering coke-oven light oil capture and toluene separation, measured nickel feed and nickel recovery, a separately qualified hydrogenation catalyst, nitrated/aromatic amine feed, producer-gas generation and assayed separation, and enclosed conversion to a named aromatic diisocyanate feed. Two further recipes cure a polyurethane coating onto cloth belt web and splice that web into the existing Drive Belts resource. No retrospectively stored Coke is converted into captured light oil; the new capture process consumes Coal and returns a finite Coke coproduct.

Nickel Ore is appended after silver with a separate finite geology-derived potential and ore-assay recognition. Existing metallurgical_mass_balances, nickel_metal_recovery, biomass_gasification and gas_composition_analysis retain their original predicates. The measured feed and assayed gas are consumed by the specific downstream operations, not transferable universal qualification credits. Cumulative generation comparison removes/restores both new ores and still preserves preexisting deposit arrays. Full save coverage now includes both ore stocks; dedicated nickel deposit/extraction and natural-potential coverage remain to expand.

Registered the six exact approved oxide/isocyanate upstream rows from the integrator's canonical catalog files. Additive Step Polymerization retains its original monomer-purification foundation. A separately available PEG diol, aromatic diisocyanate feed, chain extender and cloth reinforcement are consumed with reaction/cooling work into a dry-interior belt web. The polyurethane belt grade and provisional work/maintenance numbers require material-grade review; no outdoor or universal high-performance belt claim is made.

Twenty focused cases pass in `/tmp/tt-polymer-pu-tests.log`, zero errors/failures/skips/orphans. The new fourteen-operation fixture reaches an actual Drive Belt and then commissions the existing belt workshop, which consumes that manufactured belt as maintenance and operates. Existing supplies and PEG diol are fixture boundaries; the test does not establish a wholly autonomous chemical economy. The graph audit `/tmp/tt-polymer-pu-graph.log` passes with **771 local definitions and zero graph/production dependency errors**. These are worktree definitions, not independently integrated discoveries.

Thirteen of the original twenty-five family identities are now registered with operating code; twelve remain: polymer_molecular_weight_control, polymer_additive_formulation, ionic_chain_polymerization, coordination_polymerization, copolymer_sequence_control, polymer_tacticity_characterization, polymer_solution_processing, polymer_blow_molding, polymer_foam_cell_control, polymer_weathering_trials, polymer_solvent_recovery and selective_polymer_depolymerization. Optional catalytic-cracking closure, final material-grade review, planning, wider regression and artwork remain unfinished. The full family remains HELD despite this clean partial graph.

Source correction: [EPA coke byproduct source assessment](https://nepis.epa.gov/Exe/ZyPURL.cgi?Dockey=20006D63.TXT) supports coke-oven light oil recovery. The previously suggested CDC hydrocarbonization paper describes a different conversion process. [ECI polyurethane](https://www.essentialchemicalindustry.org/polymers/polyurethane.html) supports distinct polyol/isocyanate chemistry; [primary nickel oxide reduction study](https://pubmed.ncbi.nlm.nih.gov/11782187/) supports nickel reduction/catalyst preparation. Recipe numbers and grouped unit operations remain game abstractions, not real chemical operating instructions.

### Natural nickel supply verification

The new natural-terrain regression samples the unchanged PlanetEnvironment profile generator in the isolated actor world, passes its actual potential map through ResourceSystem occurrence generation, and finds a nickel deposit without overriding ore potentials. It then checks recognition requires assaying, recognition grants no ore stock, and worked extraction debits the finite deposit. Remaining amount plus lifetime extraction equals its starting amount. This closes the synthetic-deposit-only test gap; it does not establish every starting region has nickel or measure global abundance. No geography tuning was needed.

Validation: 21 polymer tests pass, zero errors/failures/skips/orphans, approximately seven seconds (`/tmp/tt-polymer-natural-nickel-tests.log`). No additional discoveries promoted; family remains HELD with 13 of the original 25 definitions implemented plus 18 supply-chain definitions. Broader acquisition, autonomous operation, remaining mechanisms, grade review and artwork remain unfinished.

### Blow-molded laboratory rinse bottles

Polymer Blow Molding retains its original AND prerequisites (melt rheology and compressed-air systems). Five recipes now qualify a parison batch with sample loss, mold hollow bodies using finite compressed air, injection-mold closures under the existing injection discovery, assemble/leak-test bottles, and use completed bottles as paid water-dispensing tooling in a bating-protease assay. The alternative assay retains glass reaction/measurement equipment and identical substrate, salt, water and work requirements; its benefit is substituting one glass dispenser, not a free yield bonus. Existing all-glass assay access remains unchanged. Imported closures or bottles can supply that operation without granting their manufacturing discoveries.

Source basis: Open University's [blow-moulding process](https://www.open.edu/openlearn/science-maths-technology/engineering-technology/manupedia/blow-moulding) describes parison inflation, mold cooling and melt-strength constraints, including LDPE. Thermo Fisher's [LDPE wash bottles](https://www.thermofisher.com/order/catalog/product/2436-0505) establish the water-dispenser application. These game batches do not claim exact manufacturing yields, sterile service, hot-liquid suitability, universal solvent resistance or pressure-vessel performance.

The focused scenario follows pellets through both qualified grades, air-dependent forming, closure assembly and actual workshop setup consuming the manufactured bottle, then produces Bating Protease. The first test attempt incorrectly expected a no-air job to start; production correctly rejects missing inputs before setup, so the test now checks that rejection directly. Family scope is now 14/25 original definitions plus 18 upstream definitions, 58 recipes and four plants. No canonical promotion or imagery delivery yet.

Validation: all 22 focused cases pass with zero errors/failures/skips/orphans in 6.8 seconds (`/tmp/tt-polymer-blow-tests.log`). Graph audit sees 772 local definitions, zero branching or production-dependency errors; its 460 recipe/24 plant reachability is structural only, not proof of autonomous campaign operation (`/tmp/tt-polymer-blow-graph.log`).

### Aqueous solution processing and finite solvent recovery

Two original definitions, Polymer Solution Processing and Polymer Solvent Recovery, retain their exact authored prerequisites. Seven recipes qualify a PEG binding batch with sample loss; dissolve it in fresh or separately recovered water; bind/dry alumina granules; form and remove the binder; qualify the resulting supported oxidation catalyst; and recover typed dryer condensate. Actual production consumes that catalyst in ethylene-oxide synthesis. Recovered water has no Freshwater conversion or drinking-water substitution. One binder batch consumes one water batch; drying yields 0.8 condensate, and recovery consumes 1.25 condensate per recovered-water batch. Thus the loop returns at most 0.64 water per initial water, before startup and sample losses, and continues consuming polymer, fuel, power and workshop labor. Discarded recovery fractions are abstract process loss, not a modeled wastewater/pollution system.

The compatibility/grade trial is specific to PEG and alumina. It does not turn arbitrary polymers into universal binders. Source basis: [Dow PEG properties](https://www.dow.com/en-us/pdp.carbowax-polyethylene-glycol-1000.85512z.html) establish water solubility; [PEG ceramic-binder research](https://ceramics.onlinelibrary.wiley.com/doi/10.1002/9780470314272.ch5) describes compaction of PEG-bound spray-dried granules; [alumina-processing experiments](https://www.sciencedirect.com/science/article/pii/S2589299118301137) establish that binder content and processing affect resulting ceramic properties. Recipe quantities and recovery fractions are explicit game-batch assumptions, not measured industrial yields. Catalytic performance remains subject to the existing paid catalyst qualification abstraction; this is not a pore-scale reactor model.

Validation: 24 focused cases pass, zero errors/failures/skips/orphans, 7.4 seconds (`/tmp/tt-polymer-solution-tests.log`). The new operating scenario produces catalyst, consumes it in oxide synthesis, recovers only typed condensate, and reuses recovered water without increasing or consuming Freshwater. A separate rejection case proves ordinary water cannot fabricate recovery output. Graph audit: 774 local definitions, no branching or production-dependency errors (`/tmp/tt-polymer-solution-graph.log`), structural reachability only.

Remaining scope: 16 of 25 original polymer definitions implemented, plus 18 upstream definitions; 65 new recipes and four plants. Nine original mechanisms remain, along with acquisition/autonomous-operation verification, broader material-grade review and all polymer imagery. HELD; no canonical delivery claimed.
