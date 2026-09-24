## September 22 — year-71 performance audit and bounded reductions

Base `26bb67e`, worker `codex/first-300-playable`. Small compact town fabric keeps a stable camera-independent detail choice; per-build surface samples are reused exactly; resource access inputs are hoisted within a city pass; public map snapshots omit redundant private metrics; ordinary food forecasts use an equivalent fixed numeric kernel. Optional profiles separate frames, actor days and local phases.

Fourteen focused tests pass, with the forecast check expanded to forty scenarios. Eight-day fixed year-71 replay matches full saved state excluding save timestamp. Final pair: 13.984 → 13.531 CPU seconds for eight days (~3.2% reduction); three days/second remains unachieved. No save-schema change or player restart. See `docs/performance/YEAR71_AUDIT.md` for timing variability, remaining synchronous-day bottleneck, map reconstruction spikes and unverified long-game/GPU behavior. Private fixtures and generated imports are excluded.

## September 21 — Military logistics and Government navigation

People is labeled Government. Watch & Field is titled Military and its Supply
tab is Logistics. Logistics shows supply coverage, transport, spare equipment,
ammunition, home-force equipment shortages and damaged gear; it no longer embeds
production queues or workshop orders. Its production link opens the military
filter. Repair ordering moved to Production without changing simulation rules.
Four headless checks pass for navigation labels, removal of duplicate production,
repair-order availability and actual inventory values. No player launch or visual
inspection was performed, per the user's preference.

## September 21 — Top-bar hover detail panels

All six top-right indicators now construct themed detail panels on hover rather
than displaying prose descriptions. Panels contain a headline, explicit city or
all-settlement scope, numeric rows, current status, and applicable coverage bars.
Food uses actual ration flows, water separates reserve from drinking coverage,
health labels projections, and science/output show their contributing factors.
Snapshots are rebuilt on opening within selected-city resource/population scopes.
Five headless checks cover all panel construction, food units, missing water data,
city isolation, and HUD compilation. No game launch or visual review was performed;
the user owns those checks. Existing stat click destinations are retained.

## September 21 — Shelter status and stalled early construction

Overview and Buildings now share a shelter status: starting camp places do not
claim completion of Lean-to Shelters, and unbuilt shelters have no finished-house
illustration. Existing exposed surface fronts created by founding surveys now
become usable instead of returning before their access transition. Smaller crews
can advance projects at the existing proportional work rate; each required trade,
knowledge, prerequisites, and delivered material bill remain necessary.

Eight targeted headless checks pass. A read-only, isolated replay of the saved
Year 10 city's material flow and construction, holding staffing fixed, completed
Storage Pits at day +35, Gathering Yard +88, Open Work Area +157 and Lean-to Shelters
+219. No save migration or stock grants. The pre-existing all-starter-recipes test
in test_local_material_choices also fails on unchanged 489d47f; it is not fixed
here. Player launch and visual review are left to the user.

## September 16 — T05 operating infrastructure checkpoint

Integrated worker sources `f7c5051` and `5579203` at canonical commits
`644464d` and `cc59227`. Four water and waste discoveries no longer act as free
settlement infrastructure: their effects scale from built local works, actual
sources or rainfall, daily volume, labor and condition. Controlled Kilns now
requires commissioned capital, workers and daily fuel, and its finite heat is
consumed by fired-conduit and lime batches. Rival planning commissions the kiln
before dependent production. Lime Mortar's general settlement effect requires
maintained lime masonry while direct construction and repair continue to consume
real mortar stock.

The T05 chronology review and both runtime handoffs are in
`docs/technology-review/`. Graded-route and irrigation networks, followed by the
hidden T05 transformation evaluation, remain outstanding. The canonical source
contains these changes; no running player session was represented as updated.

## September 15 — resource-access correction

Integrated `71b47e3` from canonical base `85cd0bc`. Exhausted timber, loose-stone,
and plant-fiber catchments can now move to bounded working fronts chosen from real
nearby terrain instead of remaining forever on one depleted source. Medicinal
plants participate in finite extraction and hauling. Processing-practice blockers,
depletion, source staffing, transport, typed storage occupancy, and named daily
losses are presented directly in the material UI. Depleted sites are not counted
as accessible. The smooth 70–220 metre stone blobs are replaced by meter-scale,
flattened surface rocks.

Validation is 119/119 selected cases plus a read-only existing-save smoke test.
The smoke migrated three exhausted landscape ledgers without replacing their
history or writing the save. No save-schema requirement was added and no running
player/editor was interrupted. Native visual inspection remains outstanding; the
rock-size regression and all UI data/status logic are covered headlessly.

## September 15 — city metrics, envoy drafting, and repeat reconnaissance

Source `59c34a7`, base `b528391`, integrated by the canonical Mac integrator.
Scope: shared indicator parameterization, city evidence/receipt metadata and
presentation, foreign dialogue drafting/recovery, scouting staff standing orders,
targeted report/notice presentation, and focused tests. The CivilizationSystem
hotspot adds watch lifecycle callbacks, report identity, and optional validation;
no terrain, civic labor, military ownership, or save-system replacement.

Science/health now match the dashboard definitions. New observation fields avoid
silently reinterpreting old percentage evidence. Per-field receipt dates stop a
new low-quality report from rejuvenating inherited evidence. The bounded meter
uses delivered-report recency with a 90-day fresh interval; evidence dates and
unverified projections are still explicit. Report cards preserve unknowns.

Editable next envoy briefs are saved, and setting aside an unanswered returned
reply cancels only that pending request, retaining its brief in the transcript.
Continuous reconnaissance orders reuse physical scout missions, accounting,
routes, risk and return delivery. Each watched city has at most one managed
party; 2–8 people, default 4, and six orders maximum. Resource/route constraints
defer departure, stop orders leave travelers intact, and lost parties pause.
The next visit starts no earlier than the day after return. No remote live data
or free couriers are introduced. City return reports prioritize dated target
findings rather than generic exploration rewards.

Validation: 88/88 headless cases in test_dialogue_continuity,
test_city_intelligence, test_city_label_layout, test_scouting_staff,
test_scout_archive, test_civilization_indicators, test_foreign_city_map_labels,
and test_diplomatic_journey, on the explicit canonical path. Zero errors,
failures, skips, or orphans. No live-service or graphical audit. Save additions
are optional; old reports require a new visit for newly defined metrics.
No shared-file conflicts. Running player PID 43797 stays on `b528391a5f9f`.

## September 15 — narrower discovery announcements

Integrated worker `9c582b2` at canonical `a567633`. Discovery announcements use
a 600-pixel maximum width while retaining their responsive small-window bounds
and full vertical room for explanations and effects. The discovery-popup suite
passes 9/9. No simulation, research progression, art binding, or save data changed.

## September 15 — delegated shared production and working appointments

Source `2a4de92` integrated as `148bd02`. Workshops now expose compact visual rows,
work progress, present stock, separate completed-output receipts and attention
filtering. Steward/quartermaster scheduling uses existing production authorities
for civilian needs and explicitly requested army equipment, with bounded targets,
manual ownership protection and no discarded work. The legacy supply view shares
the board, and Economy → Materials links to it. Appointment input, stable person
resolution, immediate feedback and locked-office explanations are corrected.

131/131 cases pass on canonical main; guarded native checks pass at normal/narrow
widths and exercise actual appointment and production clicks. Receipts persist in
the existing campaign save and begin honestly without backfilled output. Details
and limits are in `PRODUCTION_APPOINTMENTS_HANDOFF.md`. No terrain changed. The
live player remains `2edae731d433` (PID 31435), pending the user's normal relaunch;
the new source is prepared as a separate build-only release, not hot-loaded.

## September 15 — mountain ridges at playable distances

Integrated worker `4946779` at runtime `e9026dc`. New deterministic physical
relief resolves smaller crests and valleys inside the broad mountain envelope.
Both geographic consumers use the same model; no inventory, labor or save-schema
fields changed. All 34 targeted cases pass on integrated main, and private native
visual/streaming checks pass. The complete headless mesh benchmark adds about
2.3% computation, but native preparation latency remains an unresolved limitation.
See `MOUNTAIN_RELIEF_HANDOFF.md` for the full evidence and remaining visual limits.
Terrain work stops after packaging this pass, at the user's explicit request.
The running player remains `5c676ce`, not the new package.

## September 14 — detailed terrain survives small pans

Integrated source `a436341` at `277b90a`. Adjacent patches reuse completed
height/color/climate/geology/season samples at identical map coordinates and
recalculate normals. Covered small pans keep the fine mesh visible through the
replacement. Native paired renders are pixel-identical to complete resampling;
the full zoom/pan check and all 25 targeted tests pass on integrated main.
See `TERRAIN_PAN_REUSE_HANDOFF.md` for timings and limitations. This is a rendering
performance change with no save fields or new geography. The live game remains
on its previously launched build, `5c676ce`.

## September 14 — dryland aerial detail

Integrated worker `54ada8b` at canonical `c7a2de8`. Close dryland retains more
scrub and soil detail through its climate-color pass, and the existing semiarid
image now uses a 500 m aerial footprint instead of a 15 m grass-texture footprint.
Region and Continent comparison captures remain pixel-identical. Both native
ground/streaming probes pass; all 12 ground-field and coordinate-precision tests
pass in the worker and integrated main. See `DRYLAND_SURFACE_HANDOFF.md` for
captures, limits and performance context. The change is visual-only and adds no
save fields. The player's live process still runs `5c676ce`; it has not received
this change. Google Earth-like terrain fidelity remains an active, unfinished goal.

## September 14 — paid settlement fabric methods

Ten existing D08 identities are now registered with their authored AND/OR foundations, finite component production, plot-specific assembly and trial records, city-local delivery, repair demand, acquisition disadvantages and research-card artwork. Runtime commit `e86b1cd41070fb2f9af05eeaf9f3c9ebdaaa5722`; frozen worker source `842f51d06d3fcd721ff43cfcacb03e975c5ed5ea`. The ledger remains 3,470 unique authored identities while the operating split advances to 878 integrated and 2,592 drafts. See `INTEGRATION_STATUS.md` and `technology-review/SETTLEMENT_FABRIC_READY_HANDOFF.md` for tests and limits.

## September 13 — 868 verified operating discoveries

Integrated twelve metallurgy discoveries from frozen source `562d4aa2c58ca42d67a774bd39f6e7a89e6a8fb1` at canonical runtime/art `41f5b51b21f3d0884d957374ab1b824d241e9e0b`. Sixty additional workshop recipes supply apparatus, selected feedstocks, paid processes, destructive inspections and downstream assemblies. Phase surveys, steel normalizing, induction hardening, grain measurement, residual-stress and fracture trials, welding, vacuum melting, investment/lost-foam casting, honing and superfinishing retain workpiece history and produce accepted or rejected stock from measured outcomes. Twelve industrial illustrations use matching architecture, clothing and equipment.

**317 distinct tests pass on isolated and canonical checkouts**, including 13 atlas tests on each. Coverage includes actual daily power, interrupted hot work, finite feeds, installation of fabricated apparatus, paid sample/inspection work, accepted consumers, source ownership, cancellation, save corruption, city isolation, research acquisition, machinery, polymers, textiles and microscopy. The isolated total includes the added inspection-contract regression after its initial 316-test run. Graph and structural supply checks pass: **868 discoveries / 650 learning routes / 726 workshop recipes plus five conditional analyses / 27 facilities**. Conditional process acceptance is an explicit structural-audit assumption, not proof of campaign pacing. Twelve real image bindings load at 768px with mipmaps. Clean canonical import and paced 120-frame startup pass.

All 856 previous runtime definitions remain exact; the twelve additions preserve their authored normalized ALL/OR predicates. The committed canonical snapshot was promoted and compared exactly to the ledger; 15 ledger tests and post-promotion audits pass. Ledger: **868 integrated + 2,602 drafts = 3,470 identities**, leaving **1,530 to author and 4,132 to implement**. Art: **307 subject illustrations / 868 live, 561 queued**. Eight new metallurgy and two forty-item authoring deliveries remain outside these counts pending editorial reconciliation.

Integrator worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/metallurgy-integration`, base `2e04f464928354e0f13ceeea452c78e2e1d0f0f6`. Merge was conflict-free. Integration adds actual catalog registration, normalized acquisition tests, inspection-gate contract validation and complete deferred-inspection supply metadata. Existing production/save/state owners retain optional workpiece records; older canonical saves without these records remain valid. Invalid intermediate development records are rejected; downgrade compatibility is not promised. Models cover selected feed grades, geometries and bounded observations, not universal alloy kinetics or industrial certification. GovernmentPeopleSystem and aggregate population ownership are unchanged.

Evidence: `/tmp/tt-metallurgy-integration-{isolated,canonical}-results.json`, `/tmp/tt-metallurgy-contract-tests.log`, `/tmp/tt-metallurgy-canonical-checks.log`, `/tmp/tt-868-runtime-snapshot.json`, and `/tmp/tt-metallurgy-post-promotion-{graph,supply}.log`. See `technology-review/METALLURGY_READY_HANDOFF.md` and `assets/ui/research/paper/METALLURGY_PROCESS_PROMPTS.md`. No player launch or package rebuild. Ten paid settlement construction/envelope methods are the next worker implementation. A wider industrial-art correction is underway; the 5,000-discovery objective remains unfinished.

## September 13 — industrial artwork advances with its technology

User-directed visual correction integrated at `df4dd03828eec6c6e928a18d6bc9c80973d1877e`, following `46528259b5291398bf0fba05ddeb870cce05e07c`. Nine existing discovery illustrations replace inherited ancient robes, thatched shelters or rural machine settings with coherent industrial interiors and matching clothing: textile calendering, cutting-fluid management, fluid-film bearings, machine stiffness assessment, cylindrical grinding, polymer chain models, melt rheology, monomer purification and reaction heat management. Representative mills, engineering laboratories and chemical pilot plants preserve the paper-and-gouache style. The depicted dates are representative settings, not first-invention claims.

The general paper-art prompt guide now requires architecture, clothing and infrastructure to advance with the apparatus, and rejects the ancient apprentice scene as an industrial style reference. Native outputs and exact edit prompts are retained in `assets/ui/research/paper/INDUSTRIAL_ERA_CORRECTIONS.md`. Latest machinery scenes and five polymer-core scenes were inspected; this is not a claim that all 295 reviewed assets have received a new historical-setting audit. Existing radical-polymerization laboratory and the other latest industrial scenes were retained.

Validation: clean imports; **13 atlas tests pass on isolated and final canonical checkouts**, with zero errors/failures/skips/orphans; all **nine corrected images load through actual ResearchVisuals bindings at 768px with mipmaps** on both. Logs: `/tmp/tt-era-second-atlas.log`, `/tmp/tt-era-final-textures.log`, `/tmp/tt-era-final-canonical-{import,atlas,textures}.log`. Visual inspection confirmed matching industrial settings and retained subject mechanisms.

No runtime, research, save, population or labor changes; counts remain **856 operating discoveries / 295 subject illustrations**. Player process and package unchanged. The source task continues twelve unregistered metallurgy methods toward the unfinished 5,000-discovery objective.

## September 13 — 856 verified operating discoveries

Integrated thirteen machinery discoveries from frozen worker `d20aeee43121d3cfa70086ea623fb4af94137cd6`, with energy-validation correction `a7fa51683fd5b8453cf286526a257a7046cb65a1`, at canonical runtime/art commit `cab79f9c037b1235a24bb2c231c6e3b30b5030fb`. Twenty-nine paid recipes provide coordinate tables, eight specialized heads, four support apparatus sets, eight inspected parts and eight downstream assemblies. Retained coordinates, synchronized skiving rotations, finite power, paid witnesses and process-specific observations determine accepted or rejected output. Actual water-film support, filter saturation, measured deflection/vibration and paid repairs affect subsequent work and wear. Retooling retains head wear.

Integrator review fixed a daily power-demand deadlock: a job with its last raw feed reserved still requests generation on later days. An actually commissioned steam generator supplies the job, stops on fuel exhaustion and resumes after fuel replenishment without charging feed twice. Saved recipe energy and each coordinate frame's geometric work are validated. Three additive conflicts in Industry, discovery registration and research-purchase tests preserve textile/microscopy work and both acquisition tests. No existing owner of labor, civic people or saves was replaced.

**273 distinct isolated runtime tests and 273 canonical runtime tests pass**, plus **13 atlas tests on each checkout**. Changed machinery, coordinate and power suites were rerun after the integrator correction; twelve SEC compatibility tests also pass. Tests cover all thirteen paid research acquisitions, all eight accepted-part consumers, thirteen capital recipes, full saves, rejection, missing supplies, outages, actor isolation, retained wear, polymers, abrasives, clothing and microscopy. Canonical graph: **856 discoveries / 638 learning routes / 666 workshop recipes plus five conditional analyses / 27 facilities**, with no graph or structural supply errors. Thirteen 768px/mipmap textures load through real discovery bindings; clean imports and paced 120-frame startup pass. All 843 prior runtime definitions remain exact; all thirteen new normalized AND/OR predicates preserve authored sources. Committed snapshot, exact baseline reconciliation, 15 ledger tests and post-promotion graph pass. Art: **295 verified / 856 live, 561 queued**.

Ledger: **856 integrated + 2,614 drafts = 3,470 identities**, leaving **1,530 to author and 4,144 to implement**. Integrator worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/machine-process-integration`, base `59f146e5fa9badfa24f147e3adad48d9a3bc968e`. Older saves without machine fields remain valid. Valid unfinished jobs resume under the existing queue; malformed records are rejected. Selected bounded manufacturing measures are game models, not real industrial certification or arbitrary geometry solvers. Detailed evidence remains on jobs; no bespoke machinery dashboard is claimed. See `technology-review/MACHINE_PROCESSES_HANDOFF.md`, `technology-review/MACHINE_ENERGY_CORRECTION_HANDOFF.md` and `assets/ui/research/paper/MACHINE_PROCESS_PROMPTS.md`.

No player launch, package rebuild or millennial pacing claim. The source task is developing twelve metallurgy methods from the latest verified base, still unregistered. The 5,000-discovery objective remains unfinished.

## September 13 — 843 verified operating discoveries

Integrated six textile colorant/finishing discoveries at canonical runtime/art commit `22d57eaa902f4306f96da1feb90fcbefa61690d3`. Eighteen paid recipes prepare finite ochre pigments and plant tannin colorants, scoured/fixed/resist-printed cloth, printing blocks/paste and finishing rolls. Actual ink feeds printed sheets and actual finished cloth feeds fitted garments. Four bounded fabric identities retain finish strength through saves, weighted merges, paid washing and repair; only issued cloth fades daily. Ordinary protection is unchanged. Finite appended ochre geology preserves prior resource generation. The clothing panel shows actual stock and fading patterns.

**236 isolated runtime tests and 236 canonical runtime tests pass**, plus **13 atlas tests on each checkout**. This includes nine focused colorant cases, finite geology, polymer supply/seed stability, clothing, partial production, planner, services, ownership and exact graph requirements. Six 768px/mipmap images load through actual discovery bindings; clean imports and paced 120-frame canonical startup pass. All 837 prior runtime definitions remain exact and all six new normalized AND/OR predicates match their authored identities. Canonical graph: **843 discoveries  / 625 learning routes  / 637 workshop recipes plus five conditional analyses  / 27 facilities**. Exact committed snapshot reconciliation and 15 ledger tests pass. Art: **282 verified  / 843 live, 561 queued**.

Ledger: **843 integrated + 2,627 drafts = 3,470 identities**, leaving **1,530 to author and 4,157 to implement**. Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/textile-colorants`, base `3c70a05c47ba24b872190c5a28c39d36f63026fb`. No merge conflicts. Existing clothing/save ownership accepts absent finish fields in old saves; downgrade of newly finished lots is not promised. Selected nominal five-percent qualification allowances and normalized fading are game abstractions, not physical textile certification. See `technology-review/TEXTILE_COLORANT_HANDOFF.md` and `assets/ui/research/paper/TEXTILE_COLORANT_PROMPTS.md`.

No player launch, package rebuild or millennial pacing claim. Thirteen machinery methods are frozen for the next integration review, with separately reviewed art and an energy-validation correction. The 5,000-discovery objective remains unfinished.

## September 13 — 837 verified operating discoveries

Integrated fourteen microscopy and benign-culture methods from worker `0a83f8a9c8a7a69544aeef99378bfd7aadff9efd`, corrected by `4a97ffdc4db679cc462ac8dce1b06bd75f12a98c`, as canonical runtime/art/UI commit `dd18f3d047bdaa86c8764bd21e45740108d69a1d`. Actual starter and field-cohort material supplies bounded specimens. Existing Knowledge capacity, after scholar absences and clinical care, pays for apparatus, media, blanks, staining, tissue sections, observations and publication. Recorded observations can withhold a specific recently assayed starter or reject a field cohort. Sampled material never returns to food; later latent state cannot rewrite reports.

Division evidence requires retained consecutive resolved views of a constricted parent and separated daughters. Rising aggregate counts alone cannot qualify it. Histology consumes an actual tissue portion, slides and tool wear before observation. Replicated publication compares recorded matching conditions; failed comparisons remain distinct from success. Calibrated heat records qualify finite instrument uses with expiry. The lab panel shows current local evidence, Knowledge reservation and a pause/resume control. These are bounded game specimen/measurement models, not species identification, pathogen causality or real sterilization instructions.

**254 isolated runtime tests and 181 canonical runtime tests pass**, plus **13 atlas tests on each checkout**. The canonical selection covers new specimens, full saves, local interface, paid research, both consumers, settlement state, clinical care, visiting scholars, actor isolation and the integrated textile barriers. Fourteen 768px/mipmap textures and clean imports pass. Canonical graph: **837 discoveries / 619 learning routes / 619 workshop recipes plus five conditional analyses / 27 facilities**, zero graph errors under the two existing declared dormant OR alternatives. All 823 prior runtime definitions remain exact; all fourteen added normalized predicates match their authored sources. Paced 120-frame canonical startup, exact snapshot reconciliation and 15 ledger tests pass. Art: **276 verified / 837 live, 561 queued**.

Ledger: **837 integrated + 2,633 drafts = 3,470 identities**, leaving **1,530 to author and 4,163 to implement**. Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/microscopy-culture-integration`, base `d4d3497dfe54cf0f087e843f5385a0852ad9c0be`. Additive merge preserved the textile barrier changes without conflicts. Existing local state/save owners contain optional microscopy ledgers; older saves default empty. Full saved human, secondary-city and rival evidence remain independent; new evidence downgrade compatibility is not promised. See `technology-review/MICROSCOPY_CULTURE_HANDOFF.md` and `assets/ui/research/paper/MICROSCOPY_CULTURE_PROMPTS.md`.

No player launch, package rebuild or millennial pacing proof. Thirteen mechanical measurement/process methods are independently in development. The 5,000-discovery objective remains unfinished.

## September 13 — 823 verified operating discoveries

Integrated textile waterproofing and garment seam sealing at canonical runtime/art commit `446e926489b55599bee99c5122473cd96519298d`. Six paid workshop recipes produce coating machinery, selected polyethylene coating, panels, heat-sealing tools and compatible tape. Actual rain shells require three paid, dated surface checks; sealing consumes tape, tools, electricity and shared Logistics work, followed by three later seam checks. Failed surface checks request paid patches and retesting. Poor bonding fails; excess heat damages the garment. Existing storm exposure consumes only the issued, condition-limited protection. These are declared game wet-flex balances, not physical certification.

**165 isolated runtime tests and 165 canonical runtime tests pass**, plus **12 atlas tests on each checkout**. All 821 prior runtime definitions remain exact, and both added normalized predicates preserve their authored AND/OR requirements. Canonical graph: **823 discoveries / 605 learning routes / 619 workshop recipes plus five conditional analyses / 27 facilities**. Two 768px/mipmap textures, clean imports, paced 120-frame startup, exact snapshot reconciliation and 15 ledger tests pass. Art: **262 verified / 823 live, 561 queued**.

Ledger: **823 integrated + 2,647 drafts = 3,470 identities**, leaving **1,530 to author and 4,177 to implement**. Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/textile-barriers`, base `4fab0bb5dabb88c9afa7542f6e7c405780e37e00`. No merge conflicts. Existing household clothing owns optional saved barrier metadata; older saves retain prior behavior and pending observations resume once. Downgrade of new garment/recipe saves is not promised. The clothing panel names all garment kinds and displays actual qualification progress. See `technology-review/TEXTILE_BARRIER_HANDOFF.md` and `assets/ui/research/paper/TEXTILE_BARRIER_PROMPTS.md`.

No player launch, package rebuild or millennial pacing claim. Fourteen microscopy/culture methods remain independently in development. The 5,000-discovery objective remains unfinished.

## September 13 — 821 verified operating discoveries

Integrated nine field-botany methods from runtime source `261e317e2a488c32db95c3a071253f66fb0f8dae`, audited through worker `64bf9fd56548b5921af1966ad377b7f1e6f56819`, as canonical runtime/art commit `d912f933562439b97dd53de690d06952bdef575a`. Real cultivated harvest supplies finite local candidate/reference seed. Existing Food workers pay for paired trials, water, records and a field balance; observed developmental stages, morphology, lineage and water-loss comparisons qualify bounded descendant-seed applications. Actual planted area affects drought response only during its finite lifetime. Inferior candidates gain no advantage. Forecasts quote existing evidence/land with expiry and do not invent future generations.

**208 isolated runtime tests and 208 canonical runtime tests pass**, plus **12 atlas tests on each checkout**. Coverage includes two observed generations, missing inputs, small-harvest recovery, morphology mismatch, inferior candidates, paid outside research, full saved unfinished trials, settlement isolation, actual food consumption and forecast expiry. Nine 768px/mipmap textures and clean imports pass. Canonical graph: **821 discoveries / 603 learning routes / 613 workshop recipes plus five conditional analyses / 27 facilities**. All 812 prior definitions are unchanged and all nine added normalized predicates match their authored sources. Paced 120-frame canonical startup, exact snapshot reconciliation and 15 ledger tests pass. Art: **260 verified / 821 live, 561 queued**.

Two authored OR alternatives remain dormant: photosynthetic_process_analysis beside crop_calendars, and germ_theory beside experimental_controls. A narrow, explicitly reported editorial audit verifies exact child/group/parent declarations against draft or preserved promoted provenance and requires a reachable live alternative. Unknown AND/route prerequisites and ordinary validation remain strict; runtime evaluation, mastery and exported definitions are unchanged. Root aligned four older whole-catalog assertions and the exporter with this policy. Seven audit tests and the graph are rerun after actual promotion. No placeholder operating identities are counted.

Ledger: **821 integrated + 2,649 drafts = 3,470 identities**, leaving **1,530 to author and 4,179 to implement**. Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/field-botany-integration`, base `da2093510292abc4f0e4d9954b4f2a49646001ce`. Automatic merge preserved garment changes without conflict. Existing local resource/save owners contain the optional bounded field ledger; older saves without it load empty, with no duplicate population or daily labor owner. Downgrade compatibility is not promised.

The crop model uses abstract traits and developmental intervals with a pooled local reference population. It is not a species atlas, physiological laboratory or pathogen simulator; pathology evidence is limited to supported water limitation. Structural production retains declared external SEC/conditional-outcome assumptions. No millennial pacing proof, player launch or package rebuild. See `technology-review/FIELD_BOTANY_HANDOFF.md`, `technology-review/DORMANT_OR_AUDIT_POLICY.md` and `assets/ui/research/paper/FIELD_BOTANY_PROMPTS.md`. Next: fourteen microscopy and benign-culture methods, independently tied to real starter batches and field specimens. The 5,000-discovery objective remains unfinished.

## September 13 — 812 verified operating discoveries

Integrated zipper closures and leather edge skiving at canonical runtime/art commit `7899db5b29c220158763116b2ac6e9c3e68b93e4`. Twelve paid workshop recipes make matched zipper fronts and gauged, skived, checked and folded leather panels. Actual inputs feed existing fitted/leather garments using shared Logistics work; material, tooling, save continuation, finite offcuts and downstream automatic production are tested. Existing wear and repair apply. Nominal batch qualification consumes a five-percent destructive allowance; no sensor, universal strength, waterproofing or fatigue-life claim.

**114 isolated runtime tests and 114 canonical runtime tests pass**, plus **12 atlas tests on each checkout**. Both 768px/mipmap textures pass. Canonical graph: **812 discoveries / 594 learning routes / 613 workshop recipes plus five conditional analyses / 27 facilities**, zero graph or structural production errors under declared assumptions. Clean imports and paced 120-frame canonical startup pass. All 810 previous runtime definitions remain exact; two new definitions preserve authored normalized AND/OR predicates. Exact snapshot reconciliation and 15 ledger tests pass. Art: **251 verified / 812 live, 561 queued**.

Ledger: **812 integrated + 2,658 drafts = 3,470 identities**, leaving **1,530 to author and 4,188 to implement**. Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/zipper-skiving`, base `603ceb0aa39ac4255ea041d9a7e1d661d645c4ea`. No merge conflicts; additive industry/clothing/art changes and one catalog count assertion. No new mandatory save fields; full saved work resumes once and actors retain independent garments. Downgrade of new recipe jobs is not promised. See `technology-review/ZIPPER_SKIVING_HANDOFF.md` and `assets/ui/research/paper/ZIPPER_SKIVING_PROMPTS.md`.

No player launch or package rebuild; running player state is unchanged. No millennial pacing claim. Nine field-botany methods remain in integration review; the 5,000-discovery objective is unfinished.

## September 13 — six geological interpretation proposals

Authored six distinct D22 methods for ash and fossil correlation, cave-carbonate chronology, helium retention, fluid inclusions and clumped-isotope thermometry. Each retains actual specimen and observation requirements, uncertainty, paid instrument or external service, explicit failure cases and a downstream interpretation. Source review boundaries and semantic distinctions are documented in `technology-review/Geologic Interpretation Methods Review.md`. Historical horizons remain unassigned; existing definitions are unchanged.

Ledger: **810 integrated + 2,660 drafts = 3,470 identities**, leaving **1,530 to author and 4,190 to implement**. D22 coverage is **146 / 160**. Parent, duplicate, reachability and horizon checks and 15 ledger tests pass. Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/geologic-interpretation-coverage`, base `1d4b4f986f14b55035f34b5a04ae93fe875d3588`. Catalog/docs only; runtime 810 and art 249/810/561 queued remain unchanged. No save effect, shared runtime conflicts, player launch or package rebuild.

## September 13 — 810 verified operating discoveries

Integrated revised civic source `fa9b0185a2c6475887e9ebb3441a7ebeca3b0320` and four reviewed illustrations as canonical runtime/art commit `4e44916bff6de7e8ec810ef9890a9790071b4d86`. Existing government officials maintain settlement-and-subject jurisdictions, paid routine mandate reviews, actual pending-duty custody and condition-backed petitions. Explicit narrow, finite and revoked authority stays exceptional. AI and delegated player settlements handle routine records without manual renewal; automatic petition handling preserves the delegate's actual chosen priority. Shared Administration capacity pays for clerical work before other work consumers use the remainder.

**137 isolated runtime cases and 137 canonical runtime cases pass**, plus **12 atlas cases on each checkout**. Tests include 300 days of routine renewal, full saves, research purchases, AI handling, foreign-host rejection, 130 replacements, 131 pending duties exceeding register capacity, bounded disposition retirement and actual community-work conservation. All unadmitted duties wait for paid custody. Canonical graph: **810 discoveries / 592 learning routes / 601 workshop recipes / 27 facilities**, plus five conditional analytical transformations. No graph errors or blocked production routes under the declared structural assumptions. All 806 prior definitions are unchanged; four added normalized learning routes preserve exact authored predicates. Art: **249 verified / 810 live, 561 queued**. Clean imports, four 768-pixel/mipmap texture checks on each checkout, paced 120-frame canonical startup, exact 810-definition reconciliation and 15 ledger tests pass.

Ledger: **810 integrated + 2,654 drafts = 3,464 identities**, leaving **1,536 to author and 4,190 to implement**. Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/civic-integration`, base `65f1a928e460a4bce79503c1b30138a393831638`. Merge was conflict-free. GovernmentPeopleSystem remains the civic owner; existing local labor, inventory and save owners remain authoritative. Optional ledger absence supports older saves; tested mandate and pending-custody saves resume without duplicate completion. Downgrade compatibility for new records is not promised.

Jurisdictions are settlement/subject scopes, not drawn borders. Petitions represent aggregate observed shortages. Clerical work uses a bounded 30-unit bank, with no separate paper inventory. Explicit administrative phrases are supported; unrestricted paraphrase interpretation, every natural progression route and millennial campaign pacing remain unverified. Structural production still assumes finite external SEC references and possible conditional outcomes. No player launch or package rebuild. See `technology-review/CIVIC_ADMINISTRATION_HANDOFF.md`. The 5,000-discovery objective remains unfinished; nine field-botany methods are the next isolated delivery.

## September 13 — seven reviewed military horizon assignments

Applied two H03 and five H05 editorial assignments to existing identities after direct Met, GCHQ, National Army Museum and Navy source review. Updated the earlier provisional sound-ranging and carrier evidence with accessible institutional pages. Current source names, statuses and scope digests reconcile; parent, duplicate, reachability and horizon checks and 15 ledger tests pass. See `technology-review/MILITARY_HORIZON_EVIDENCE.md`.

Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/military-horizon-review`, base `902c05bc2fd8f2fcd748ddab788aebcd96b50976`. Catalog/docs only: 1,366 of 3,464 identities have editorial horizon assignments; no calendar gates, first-invention claims or runtime additions. Runtime remains 806, art 245/806, and save behavior is unchanged. No shared conflicts, player launch or package rebuild.

## September 13 — four early institution illustrations

Added reviewed paper artwork for customary law, public stores, organized watch and formation drill. Native originals and built-in imagegen prompts are retained in `assets/ui/research/paper/EARLY_INSTITUTION_PROMPTS.md`. Four textures pass 768-pixel/mipmap checks and 12 isolated atlas tests pass. Art is **245 verified / 806 live, 561 queued**. Runtime definitions, ledger counts and save behavior are unchanged.

Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/early-institutions-art`, base `1709da22f661eacb60122cbfc3a58c8e8b01467b`. Owns four images/imports, bindings and art records only. No shared conflicts, player launch or package rebuild. Canonical import, all four texture checks and 12 atlas tests also pass at integrated art commit `de382aa01b8be23684620af6baed7f4da45251f7`.

## September 13 — military horizon evidence review

Integrated evidence-only source `83d2c4f6d39d5060c1789c77ece59e99eccdd088` as `7d6db84`. Seven existing military identities have proposed broad historical placements, with unsuccessful full-page fetches explicitly marked provisional. No horizon mappings, prerequisite edits, new identities or runtime changes are included. See `technology-review/MILITARY_HORIZON_EVIDENCE.md`.

Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/military-horizon-integration`, base `d8afdc3c62bda8bd066e30122743b5298e258c50`. Reviewed documentation and whitespace only; no runtime tests required for this change. No merge conflicts or save effects. Runtime remains806, art241/806, ledger3,464 distinct identities. No player launch or package rebuild. Civic source remains held for authority maintenance, actor ownership and handover-capacity fixes.

## September 13 — 806 verified operating discoveries

Integrated frozen abrasive handoff `25e4b8ad773e7351571973d6b3438798e4cc89ba` and five reviewed illustrations as canonical runtime/art commit `11241aee7f00f49df88648536e466e34ebb06205`. Five original discoveries and 32 paid recipes connect actual refined alumina, bonded wheels or dry glue-backed belts, separate grinding fixtures, retained candidate inspection and selected rejected-metal recovery to finished motor components and motors. Candidate identity survives inspection cancellation and save/load; unsupported unfinished-candidate trade fails before either side is debited. Qualified finished products trade normally. The planner replaces untraceable stock, and the panel distinguishes inspection capacity from accepted yield. Paid foreign licenses operate at 65% without mastery and expire.

**257 isolated runtime cases and 148 canonical runtime cases pass**, plus **12 atlas cases on each checkout**. Canonical graph: **806 discoveries / 588 learning routes / 601 workshop recipes / 27 facilities**, plus five conditional analytical transformations. No graph errors or blocked production routes under the declared structural assumptions. All 801 prior definitions are unchanged; five added normalized learning routes preserve exact authored predicates. Art: **241 verified / 806 live, 565 queued**, with all five new textures at 768 pixels with mipmaps. Exact 806-definition snapshot reconciliation and 15 ledger tests pass.

Ledger: **806 integrated + 2,658 drafts = 3,464 identities**, leaving **1,536 to author and 4,194 to implement**. Integration worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/abrasive-integration`, base `cc1f931f5832feee2ffc6ce4e6fe9cb1fc0805fb`. Merge was conflict-free. Existing owners retain daily work, inventory, officials and saves. Optional bounded lot state accepts legacy absence; new partial jobs and actor/store separation are tested. Downgrade compatibility for new jobs is not promised.

Two unpaced short startup exits reported leaked `Tomorrow.mp3` playback/stream objects. A pre-abrasive baseline comparison was clean, and the integrated 120-frame startup paced at 60 fps was also clean. No audio or terrain changes were made; the short-exit cleanup limitation is recorded rather than hidden. Local-only resource closure still excludes specialist SEC supply; structural production assumes finite external references and possible analytical/quality outcomes. Selected size/form/surface ratios are explicit game manufacturing assumptions, not sensor physics, arbitrary-material certification or fatigue life. Full campaign bootstrap and millennial pacing remain unverified. No player launch or package rebuild. See `technology-review/ABRASIVE_FINISHING_HANDOFF.md`. The 5,000-discovery objective remains unfinished.

## September 13 — eight geological chronology proposals

Authored eight distinct D22 methods for natural annual chronologies, calibrated radiocarbon, luminescence, cosmogenic exposure and burial, fission-track thermal histories and argon release spectra. Each preserves its actual observation, paid sample/reference requirements, uncertainty and failure conditions. Existing broad geochronology and core reconstruction identities are unchanged. See `technology-review/Geochronology Methods Review.md` for institutional sources and explicit game-design boundaries.

Ledger: **801 integrated + 2,663 drafts = 3,464 identities**, leaving **1,536 to author and 4,199 to implement**. D22 coverage is **140 / 160**. Parent, duplicate, reachability and horizon checks and 15 ledger tests pass. These are proposals only; runtime801 and art236/801/565queued remain unchanged. Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/geochronology-coverage`, base `49137cbf2631315fe7a3314b4fb952c73ccde7eb`. Catalog/docs only, no runtime conflicts or save effect, player launch or package rebuild. Geological ages are sample interpretations, not gameplay calendar gates.

## September 13 — five early foundation illustrations

Added reviewed paper illustrations for seasonal patterns, smoke preservation, drainage, route memory and labor rotations. Native originals and exact prompts are retained in `assets/ui/research/paper/EARLY_FOUNDATION_PROMPTS.md`; five imported textures pass 768-pixel/mipmap checks and 12 isolated atlas cases pass. Art: **236 verified / 801 live, 565 queued**. No new runtime identities or save behavior.

Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/early-foundation-art`, base `5907991b6b3a74d34363f3851ea65ebb292a2bd9`. Owns only five images/imports, prompt record, bindings and catalog/docs. No shared conflicts, player launch or package rebuild. Canonical import, five texture checks and 12 atlas cases also pass at integrated art commit `5e0b13ef5ff75fee25aa2a494b78d861f617ae8f`.

## September 13 — early illustrations and observed pacing export

Integrated eight reviewed paper illustrations from source commits `51d9fa57d4282c04aea551916f6b7b01e9a79cad` and `224b037`: seed selection, food drying, basketry, tallies, joinery, clean water, standard measures and supply groups. Native originals are retained; all eight imported textures load at 768 pixels with mipmaps, and 12 isolated atlas cases pass. ResearchVisuals binds them to their existing discoveries. Art: **231 verified / 801 live, 570 queued**. Runtime identities and save behavior are unchanged.

Integrated pacing correction `e9f20af`: the exporter now reports recorded observations and provenance instead of generating the obsolete synthetic 3,000-year curve. Independent review preserved the historical report's two discovery samples and day 91,250 / 320-known endpoint, and rejected three malformed inputs. Archived files are preserved; neither this export nor graph reachability establishes full campaign pacing. See `technology-review/OBSERVED_PACING_EXPORT.md`.

Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/campaign-service-integration`, base `121c9f870c852d10902fedb0c5b7b44675aa4d85`. Task-owned art/bindings and tool/docs only; no shared conflicts, player launch or package rebuild. Canonical import, all eight texture checks and 12 atlas cases also pass after fast-forward to `d16dd0d3337b648c8796970e4d950ab2fea8f774`.

## September 13 — campaign service proposal integration

Integrated source proposals `9b74309` and historical evidence `8abca3b`, retaining nine distinct D20 drafts. The duplicate artillery survey datum proposal is excluded in favor of existing geodetic reference frames; sound and flash observation proposals require that foundation plus military cartographic reporting. Billeting follows actual institutional obligations, and inspected serviceable salvage can be reissued without mandatory repair. Generals retain operations and existing population/labor owners remain authoritative.

Ledger: **801 integrated + 2,655 drafts = 3,456 identities**, leaving **1,544 to author and 4,199 to implement**. Parent, duplicate and reachability checks and 15 ledger tests pass. These are design contracts, not live discoveries; early historical horizons remain provisional. Runtime and art counts are unchanged. Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/campaign-service-integration`, base `121c9f870c852d10902fedb0c5b7b44675aa4d85`. Catalog/docs only; no save effect or runtime conflict. No player launch or package rebuild. See `technology-review/Military Campaign Services Review.md` and its evidence addendum.

## September 13 — 801 verified operating discoveries

Garment closure runtime/art commit `095266eb63b67509236153ed814a7f8d7ec218e6` is integrated into canonical main. Two original discoveries retain exact parent predicates. Ten paid workshop recipes make sewing needles, matched buttons and reinforced panels, or forming dies, spring snaps and gauged leather tabs. Two clothing methods consume checked closures through the existing daily production, labor, inventory and clothing owners.

**125 isolated runtime cases and 97 canonical runtime cases pass**, plus **12 atlas cases on each checkout**. Graph: **801 discoveries / 583 learning routes / 569 workshop recipes / 27 facilities**, with five conditional analytical transformations and no graph errors or blocked products. All 799 prior snapshot definitions are unchanged; both additions preserve their authored predicates. Two visually reviewed illustrations load at 768 pixels with mipmaps. Art: **223 verified / 801 live, 578 queued**. Clean canonical thirty-frame startup, exact 801-definition snapshot reconciliation and 15 ledger tests pass.

Ledger: **801 integrated + 2,646 drafts = 3,447 identities**, leaving **1,553 to author and 4,199 to implement**. Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/garment-closures`, base `6fed85fb93fef79b3cabd134047b010b04437150`. Only task changes were committed; no shared-file conflicts occurred. Existing clothing lots and save owners remain compatible; partial production, full save continuation, duplicate completion and actor isolation pass. Named compatibility and acceptance allowances are bounded game assumptions, without universal fastening certification or separate hardware wear. Full campaign pacing remains unverified. No player launch or package rebuild. See `GARMENT_CLOSURES_HANDOFF.md`. The 5,000-discovery objective remains unfinished.

## September 13 — 799 verified operating discoveries

Integrated polymer source `f1513babe69bdbb1507fa531e2a4c2a7560e085e` as canonical runtime/art commit `08547e7e6f764f8d8acd8d655d757ee0cac81e15`. The 47-discovery family adds 123 paid workshop recipes and seven installations: named chemical feeds and catalysts, polymer forming and recovery, enzyme bating, thermal control, and retained-sample NMR and aqueous size-exclusion analysis connected to actual downstream products. Measured grades consume retained samples and select real production routes. The existing daily production, labor, inventory and save owners remain in use.

**316 isolated runtime cases and 163 canonical runtime cases pass**, plus **12 atlas cases on each checkout**. Canonical graph: **799 discoveries / 581 learning routes / 559 workshop recipes / 27 facilities**, with five separately declared conditional analytical transformations. No graph errors or blocked routes. All 752 prior snapshot definitions are unchanged; the 47 added normalized learning routes preserve the authored AND/OR predicates. All 47 new illustrations are visually reviewed and imported with 768-pixel limits and mipmaps. Art: **221 verified / 799 live, 578 queued**. Clean canonical import and thirty-frame headless startup, exact 799-definition snapshot reconciliation, and 15 ledger tests pass.

Ledger: **799 integrated + 2,648 drafts = 3,447 identities**, leaving **1,553 to author and 4,201 to implement**. Integration worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/polymer-integration`, base `24cfea7d76295608099335083ee2c59956fd32d1`. Three conflicts were resolved by preserving both recipe sets, quilt repair plus the new hunting byproduct, and all artwork bindings.

Existing saves retain optional empty analytical state; partial and completed analytical saves, exhaustion, duplicate calls and actor/store isolation pass. Laboratories operate at the primary home. Qualified SEC packing and assigned references come from an explicitly authored, finite external laboratory archive through paid embassy delivery; local synthesis and a complete historical bootstrap are not claimed. Numerical assay performance and material grades are bounded game assumptions. Structural reachability assumes successful conditional analyses and available external reserves; full campaign pacing remains unverified. No player launch or package rebuild. See `POLYMER_DELIVERY_STATUS.md`, `SEC_DISTRIBUTION_MODEL.md` and `SEC_SPECIALIST_SUPPLY.md` for the source behavior and limits. The 5,000-discovery objective remains unfinished.

## September 13 — polymer size-exclusion prerequisite

Authored `size_exclusion_chromatography` with mandatory solution-processing, glass-tube, optical, experimental-control and uncertainty foundations. The selected aqueous PEG route requires real column/flow/detection, attributable media and reference supply, observed finite-resolution calibration and distribution evidence used in a paid process or material choice. The existing NMR number mean remains complementary and is not relabeled as a measured distribution. See `technology-review/Polymer SEC Prerequisite.md`.

Ledger: **752 integrated +2,695 drafts =3,447 identities**, leaving **1,553 to author and4,248 to implement**. All parent/duplicate/reachability checks and15ledger tests pass. Runtime752/534/436/20 and art174/752 remain unchanged. Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/polymer-sec-prerequisite`, base `0947d0efc8db5c6a5696526b67ffb6e33dec40f1`. Catalog/docs only, no save or runtime conflict. Polymer remains HELD for distribution-route supply and final acceptance; thirty reviewed family images are delivered to its worker but not promoted here. External column/standard supply must actually exist and be finite; an import label creates no supplier stock. No player launch or package rebuild.

## September 13 — 752 verified operating discoveries

Braided/quilted clothing runtime/art commit `d51889615deb6145c6e3bdb7129c9c198a931012` is integrated and verified. Two original identities retain exact predicates. Paid braids fasten actual woven wraps; prepared plant-fiber filling, cloth faces and thread make quilt garments. Worn quilts require replacement filling during repair, including planner demand when clothing counts already meet population needs. Existing daily labor, issue, wear and save owners remain in use.

**129 isolated runtime cases and90 canonical runtime cases pass**, plus12atlas cases on each checkout. Graph: **752 discoveries /534 routes /436 recipes /20 facilities**, no errors or blocked products. Both new illustrations load at768pixels with mipmaps; art **174 verified /752 live,578 queued**. Clean thirty-frame startup, exact752-definition snapshot comparison and15ledger tests pass.

Ledger: **752 integrated +2,694 drafts =3,446 identities**, leaving **1,554 to author and4,248 to implement**. Old methods/lots remain valid; binary partial-production save recovery and actor isolation pass. Insulation is a bounded game coefficient for actual supplied filling and condition, not a thermal certification. Full historical bootstrap/pacing remains unverified. No player launch or package rebuild. See `BRAIDED_QUILTED_CLOTHING_HANDOFF.md`. Polymer remains isolated for analytical acceptance; root owns five of its pending illustrations.

## September 13 — marine subsystem coverage

Authored16 D10 mechanisms for distinct propulsors, roll-control hardware, hull-flow modifications, shaft sealing/earthing, navigation observations and centrifugal bilge treatment. Each requires paid compatible hardware, actual supply and measured limits. Propulsive benefits are installation-specific; stabilizers have finite authority; rejected bilge liquid remains held. See `technology-review/Marine Systems Review.md`.

Ledger: **750 integrated +2,696 drafts =3,446 identities**, leaving **1,554 to author and4,250 to implement**. D10 now124/160 authored coverage. Parent/duplicate/reachability checks and15ledger tests pass. Runtime750/532/434/20 and art172/750 are unchanged. Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/marine-systems-coverage`, initial base `3d81ef2`, updated through catalog-only NMR prerequisite `8f0487f5840eea473c852a1496af0ee36e3285c5`. Catalog/docs only; no save or runtime shared-file conflict, player launch or package rebuild.

## September 13 — polymer NMR prerequisite

Authored `nuclear_magnetic_resonance_spectroscopy` for the worker's sequence-sensitive measurement gap, with mandatory atomic physics, spectroscopy, tuned circuits and precision thermometry. A calibrated magnetic field, RF probe/excitation, sensitive receiver, references, thermal control and finite acquisition are required. Bruker's benchtop composition example does not establish universal sequence resolution; ambiguous or unresolved evidence cannot certify a grade. MRI is a distinct existing proposal. See `technology-review/Polymer NMR Prerequisite.md`.

Ledger: **750 integrated +2,680 drafts =3,430 identities**, leaving **1,570 to author and4,250 to implement**. Parent/duplicate checks and15ledger tests pass. Runtime750/532/434/20 and art172/750 are unchanged. Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/polymer-nmr-prerequisite`, base `3d81ef2061c30bbf5eadef42697d56b97de591b0`. Catalog/docs only; no save-format effect. Marine research is paused for this dependency. Polymer runtime remains isolated and under review; no player launch or package rebuild.

## September 13 — aviation subsystem coverage

Authored24 distinct D11 mechanisms covering wing flow/control hardware, fuel routing and gauging, emergency/auxiliary power, electrical isolation, fire sensing, rotor drives/damping, landing-gear behavior, air-cycle cooling and pneumatic deicing. Each proposal names paid hardware, measured limits and a real proposed consumer. Crossfeed is not tank transfer; emergency airflow power and auxiliary turbines have actual energy sources; detection does not extinguish fires. See `technology-review/Aviation Systems Review.md`.

Ledger: **750 integrated +2,679 drafts =3,429 identities**, leaving **1,571 to author and4,250 to implement**. D11 now91/160 authored coverage. Parent/duplicate/reachability checks and15ledger tests pass. Runtime750/532/434/20 and art172/750 remain unchanged. Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/aviation-systems-coverage`, base `4af5831e81f2470c1bd0f8817ea702c1c01175f2`. Catalog-only changes have no save-format impact or runtime shared-file conflict. No player launch or package rebuild.

## September 13 — 750 verified operating discoveries

Formed-metal runtime/art commit `991ef0778aafced0bac3af208daf7262009128f8` is integrated and verified. Five original identities retain exact predicates: metal spinning, rotary swaging, rotary-draw bending, roll forming and centrifugal tube casting. Eighteen paid recipes turn distinct tooling and prepared components into actual motors, qualified pressure fittings and a commissioned pneumatic workshop. Raw blanks and untested frames cannot substitute for finished parts.

**111 isolated runtime cases and 79 canonical runtime cases pass**, plus12 atlas cases on each checkout. Canonical graph: **750 discoveries /532 routes /434 recipes /20 facilities**, all declared production structurally reachable with zero errors. Five new textures load at768 pixels with mipmaps; art is **172 verified /750 live,578 queued**. Clean thirty-frame startup, exact750-definition snapshot comparison and15ledger tests pass.

Ledger: **750 integrated +2,655 drafts =3,405 identities**, leaving **1,595 to author and4,250 to implement**. Existing recipes, daily owners and save schema remain unchanged; fractional work, full binary save continuation and actor isolation pass. Named grades remain bounded abstractions; tests establish paid chains and real daily progress, not a full historical campaign bootstrap. No player launch or package rebuild. See `FORMED_METAL_HANDOFF.md`. Polymer remains isolated pending its complete acceptance.

## September 13 — 745 verified operating discoveries

Precision component runtime/art commit `0ecb2a1f459625f4dd72d58abc4b4f63afc01462` is integrated and verified. Five existing identities retain original predicates: reamed bore finishing, reciprocating profile slotting, gear shaping, progressive broaching and interchangeable component fits. Fourteen paid routes supply distinct tooling, finished sleeves/shafts, family-specific bearing assemblies, keyed clutch hubs and generated gears; actual existing motors and commissioned geared workshops consume those parts. No global fit certificate, free mechanical power or extra labor owner is added.

**91 isolated runtime cases and 59 canonical runtime cases pass**, plus 12 atlas cases on each checkout. Canonical graph: **745 discoveries /527 routes /416 recipes /20 facilities**, with all declared production reachable and no graph errors. Five new illustrations load at 768 pixels with mipmaps; art is **167 verified /745 live, 578 queued**. Exact canonical745-definition snapshot matches the promoted ledger, and 15 catalog-tool tests pass.

Ledger: **745 integrated +2,660 drafts =3,405 identities**, leaving **1,595 to author and 4,255 to implement**. A three-frame startup produced two ObjectDB/one-resource shutdown cleanup warnings; the verbose repeat and a longer thirty-frame startup were clean. No unrelated engine changes were made or general cleanup guarantee claimed. Old jobs/recipes and save owners remain unchanged; new full binary save continuation and actor isolation pass. Dimensions and acceptance remain bounded named-grade abstractions; full historical bootstrap/pacing remains unverified. No player launch or package rebuild. See `PRECISION_COMPONENT_HANDOFF.md`. The other task's partial polymer family remains isolated.

## September 13 — polymer isocyanate prerequisites

Authored four worker-requested upstream identities: coal light-oil recovery, aromatic nitration, aromatic amine hydrogenation and isocyanate synthesis. Exact requested foundations are retained. Typed feeds, paid reaction/separation, catalyst compatibility and rejected fractions remain explicit. EPA's coke-recovery description supports the selected coal route; the initially suggested hydrocarbonization paper does not by itself establish it. See `technology-review/Polymer Isocyanate Prerequisites.md`.

Ledger: **740 integrated +2,665 drafts =3,405 identities**, leaving **1,595 to author and 4,260 to implement**. Parent/duplicate checks and 15 ledger tests pass. Runtime 740/522/402/20 and art 162/740 are unchanged. Catalog-only commit in the integrator worktree on `codex/precision-component-processes`, based on `3e23d2b`; no save-format impact. Separate machining implementation has passed 91 isolated runtime cases but is not yet integrated. No player launch or package rebuild.

## September 13 — polymer oxide prerequisites

Authored worker-requested ethylene_oxide_synthesis and ethylene_glycol_hydrolysis with exact requested mandatory foundations. Separate supported-catalyst oxidation and paid hydrolysis/separation retain named feeds, competing products and grade limits. The silver catalyst is reaction-specific. See `technology-review/Polymer Oxide Prerequisites.md`.

Ledger: **740 integrated +2,661 drafts =3,401 identities**, leaving **1,599 to author and 4,260 to implement**. Parent/duplicate checks and 15 ledger tests pass. Runtime 740/522/402/20 and art 162/740 remain unchanged. The two rows were authored in the integrator worktree on `codex/precision-component-processes`, based on `61403ea`, while its separate five-discovery runtime changes remain uncommitted and unintegrated. This commit contains catalog/docs only, with no save-format impact. No player launch or package rebuild.

## September 13 — textile assembly coverage

Reviewed twelve distinct textile and garment mechanisms: braiding, tufting, elastic-yarn covering, quilting, reinforced button openings, zipper/hook-loop/snap closures, seam taping, leather skiving/finishing and needle lace. Each proposal requires real materials, paid work and component-specific acceptance. Filling controls quilt warmth; closures and coatings do not imply universal strength or sealing. See `technology-review/Textile Assembly Review.md`.

Ledger: **740 integrated +2,659 drafts =3,399 identities**, leaving **1,601 to author and 4,260 to implement**. D07 fills its 120 planned identities as authored coverage, not runtime completion. Parent and normalized-name checks and 15 ledger tests pass. Runtime 740/522/402/20 and art 162/740 are unchanged. No player launch or package rebuild. Integrator worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/textile-assembly-coverage`, base `b59e888`. Catalog-only changes have no save-format impact or runtime shared-file conflict.

## September 13 — road vehicle and infrastructure coverage

Reviewed 32 distinct drivetrain, vehicle control, tire, impact-evidence, emissions and road/bridge assessment proposals. Each requires compatible paid equipment or actual observations, finite work, operating limits and a downstream consumer. Existing broad vehicle/transmission/brake knowledge is not recounted. Grip, injury prevention, emissions control and road condition remain bounded by actual equipment and test evidence rather than global bonuses. See `technology-review/Road Vehicle Review.md`.

Ledger: **740 integrated +2,647 drafts =3,387 identities**, leaving **1,613 to author and 4,260 to implement**. D09 accounts for 140/180 planned identities. All parents resolve, normalized names are distinct and 15 ledger tests pass. Runtime 740/522/402/20 and art 162/740 remain unchanged. No player launch or package rebuild. Integrator worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/road-vehicle-coverage`, final base `5c0d455`. Catalog-only changes have no save-format impact; shared ledger additions preserve the polymer prerequisites. Polymer runtime closure continues in its isolated task.

## September 13 — polymer condensation prerequisites

Authored four worker-requested prerequisites: wood methanol recovery, silver cupellation, formaldehyde synthesis and urea synthesis. Original requested foundations are retained. Each requires typed feed, finite equipment/work and qualification with losses; crude wood condensate is not pure methanol, and ordinary lead stock has no implicit silver content. These remain proposals pending the isolated polymer implementation and integration checks. See `technology-review/Polymer Condensation Prerequisites.md`.

Ledger: **740 integrated +2,615 drafts =3,355 identities**, leaving **1,645 to author and 4,260 to implement**. All parent paths resolve, normalized names are distinct and 15 ledger tests pass. Runtime remains 740/522/402/20 and art 162/740. No player launch or package rebuild. Integrator worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/polymer-condensation-coverage`, base `366ff3b937c242c365507c4b879a9c87ccbcb357`. Catalog-only changes have no save-format impact; shared ledger files were reviewed against current main.

## September 13 — manufacturing process coverage

Reviewed32 distinct removal, forming, joining and casting processes with specific component consumers. Support geometry, tooling access, material compatibility, paid work/energy, consumable losses and inspection remain explicit. Existing generic grinding, gear generation/hobbing, lapping, fastener production and casting-feed design are not recounted. These rows remain authored proposals.

Ledger: **740 integrated +2,611 drafts =3,351 identities**, leaving **1,649 to author and4,260 to implement**. D06 accounts for169/240 planned identities. Parent paths resolve, normalized names are distinct and15 ledger tests pass. Runtime740/522/402/20 and art162/740 are unchanged. No player launch or package rebuild. See `technology-review/Manufacturing Process Review.md`. Polymer implementation continues in its isolated worker checkout.

## September 13 — Earth observation method coverage

Reviewed25 distinct observational and analytical methods covering radar/optical retrievals, atmospheric layers, cryosphere measurements, ocean budgets and flux/source inference. Each requires attributable observations, paid acquisition or computation, uncertainty and a downstream consumer. Existing broad observation networks and forecasting services are not recounted; inferred or missing measurements cannot disclose hidden world state.

Ledger: **740 integrated +2,579 drafts =3,319 identities**, leaving **1,681 to author and4,260 to implement**. D22 accounts for132/160 planned identities. All parents resolve, names are distinct and15 catalog-tool tests pass. Runtime remains740/522/402/20, art162/740. No player launch or package rebuild. See `technology-review/Earth Observation Methods Review.md`. Polymer implementation remains isolated in the other task.

## September 13 — polymer feedstock prerequisite

Authored hydrocarbon_steam_cracking as a distinct thermal process with fuel_refining, pressure_vessels and precision_thermometry foundations. Steam dilution, quench, separation, paid heat/feed/water and mixed yields remain required operating behavior. It is not promoted; the polymer worker is implementing its typed upstream and downstream connections. See `technology-review/Polymer Feedstock Closure.md`.

Ledger: **740 integrated +2,554 drafts =3,294 identities**, leaving **1,706 to author and4,260 to implement**. Parent/duplicate checks and15 ledger tests pass. Runtime/art unchanged; no player launch or package rebuild. Integrator worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/polymer-feedstock-coverage`, based on `d3e3bf327ef38d917171883bf1fea6b43c487dd5`; catalog-only prerequisite requested by the worker.

## September 12 — textile operation coverage

Reviewed32 additional textile operations spanning feed preparation, loom setup/insertion, distinct finishing processes, machine knitting and nonwoven formation/bonding. Existing combing, generic weaving, drawloom/Jacquard selection, fulling/calendering and finished filtration qualification are excluded from duplicate counting. Each proposal has a primary mechanism reference, paid outside-learning contracts, explicit process inputs and a downstream consumer; none is counted as runtime behavior.

Ledger: **740 integrated +2,553 drafts =3,293 identities**, leaving **1,707 to author and4,260 to implement**. D07 accounts for108/120 planned identities. All parent paths resolve, normalized names are unique and15 catalog-tool tests pass. Runtime740/522/402/20 and art162/740 remain verified at `c1f13057d6dee1e53cce319d16fc7fc112c5820c`. No player launch or package rebuild. See `technology-review/Textile Operation Review.md`. The other task is implementing25 polymer discoveries from6d89ae9, including typed feedstock closure and actual downstream consumers.

## September 12 — 740 verified operating discoveries

Selected food source `6731829793b0eb5b65dbb8f0fb94b36d622b4600` and sewing source `8201718` are combined in `43e073253e78fc99b4ab87fee632e63116f843eb`; canonical runtime/art acceptance is `c1f13057d6dee1e53cce319d16fc7fc112c5820c`. Six food identities retain their original predicates. Stable compatible local resource opportunities require recognition, matching adopted preparation and finite collection work; that work is subtracted from the existing food workforce. Raw and unfinished lots are unavailable as food. Shelling, screening, leaching, grating and splitting spend equipment, materials and shared Logistics work; selected intermediates require later paid cooking. No generic plant stock is relabeled into selected species.

Treadle sewing retains bone needle sewing AND cam motion. Two paid recipes supply actual machines and replacement parts; installed machines consume cloth, yarn, parts and the existing clothing workforce to make ordinary sewn garments. No free power, extra insulation or second daily labor owner.

**166 combined runtime cases and98 canonical cases pass**, plus12 atlas cases on both. Graph: **740 discoveries /522 routes /402 recipes /20 facilities**, no errors and all declared production reachable. Exact740-definition canonical snapshot,15 ledger tests and normal headless boot pass. Ledger: **740 integrated +2,521 drafts =3,261 identities**, leaving **1,739 to author and4,260 to implement**.

Selected-food art source `0ac75db` is integrated as `e63aaaa`; sewing art is `c1f1305`. Seven illustrations were personally reviewed and pass canonical768px/mipmap loading. Art: **162 verified /740 live,578 queued**. Selected resources use bounded procedural compatible classes and existing gathering health, not surveyed botanical species or a new regional depletion model. Optional lot provenance and a collection-day stamp use the existing bounded food-batch/save owner; old ordinary cereal lots remain valid. No player launch or package rebuild. See `SELECTED_FOOD_PROCESSING_HANDOFF.md` and `SEWING_MECHANISMS_HANDOFF.md`. The other task is starting a larger coherent polymer family from this verifiedmain.

## September 12 — mathematical structures coverage

Reviewed24 distinct mathematical-structure proposals, including exact algebraic domains, coordinate/shape structure, integration assumptions and weak equation formulations. Each has a primary mechanism reference, finite analytical-work contract, explicit failure limits and a proposed downstream consumer. Existing arithmetic, matrix/vector methods, optimization and PDE solvers are excluded from duplicate counting.

Ledger: **733 integrated +2,528 drafts =3,261 identities**, leaving **1,739 to author and4,267 to implement**. D12 accounts for180/180 planned slots; this is authored allocation coverage, not runtime completeness. All parents resolve, normalized names are unique, and15 catalog-tool tests pass. Runtime remains733/515routes/400recipes/20facilities; art155/733,578queued. No player launch or package rebuild. See `technology-review/Mathematical Structures Review.md`. Selected-food implementation continues in the other task.

## September 12 — 733 discoveries and current-day river verification

Type casting/composition source `7b402f1` and current-day river fix `17430c9d498830b348709a0e0fbc2e523c8d133e` are integrated. Two existing identities retain their original predicates, including wooden OR metal type. Four paid routes supply type and proofed forms to real printing and study. Composition allocates actual type, proof paper, ink and work. Existing complete forms remain usable; no arbitrary text or mastery is granted.

The actual daily owner previously advanced machinery before refreshing discovery context. New daily-step tests reproduced four stale hammer-work units on source deletion or migration. The owner now passes current observations directly to operations, stopping the drive that day. Direct callers retain their existing fallback. Original direct machinery tests alone did not cover this call order.

**82 distinct runtime worktree and 58 canonical cases pass**, plus12 atlas cases on both checkouts. Graph: **733 discoveries /515 routes /400 recipes /20 facilities**, all declared production reachable with no errors. Exact733-definition snapshot matches the ledger;15 catalog-tool tests and normal headless boot pass. Ledger: **733 integrated +2,504 drafts =3,237 identities**, leaving **1,763 to author and4,267 to implement**.

Machinery art source `e4c93fb` is integrated as `f1a5c2c`; type art is `36f3c45`. All eight images visually reviewed and canonical768px/mipmap loads pass; the final12-case canonical atlas rerun passes. Art now **155 verified /733 live,578 queued**. No new top-level save fields, player launch or package rebuild. Type repertoires/proof correction and hydraulic capacity retain explicitly bounded abstractions; full historical pacing is unverified. See `TYPE_COMPOSITION_HANDOFF.md` and `EARLY_MACHINERY_HANDOFF.md`. The other task is implementing six selected-food discoveries.

## September 12 — 731 verified operating discoveries

Early machinery source `3b0c030f18a4ab21033eafa526114325cd184b22` is integrated as `c4af26837581201c3007fb0c971258512982d241`. Six existing discoveries retain original predicates. Fourteen paid recipes supply actual cart parts, paper presses, belt drives and forge products. River hammers require a pinned confirmed nearby river, maintenance, operators and suitable local climate; all installations share at most eight daily hammer-work units. Forging consumes that finite service alongside materials and labor. A belt workshop spends real electricity and replacement belts. Existing general-led military and simulation owners remain authoritative.

**109 combined worktree and 68 canonical cases pass**, with zero errors/failures/skips/orphans. Graph: **731 discoveries / 513 routes / 396 recipes / 20 facilities**, no dependency errors. All 731 canonical definitions match the promoted ledger; 15 catalog-tool tests pass. Normal headless boot is clean. Ledger: **731 integrated + 2,506 drafts = 3,237 identities**, leaving **1,763 to author and 4,269 to implement**.

Parchment illustration `5d38707` is visually reviewed and passes canonical 768px/mipmap loading and all 12 atlas tests. Art: **147 verified / 731 live, 584 queued**; six machinery illustrations are being prepared separately. The one additive recipe conflict retained both families. No top-level save changes, player launch or package rebuild. Hydraulic capacity is an explicit bounded climate proxy, not measured discharge or head; primary installations only and long campaign pacing remains unverified. See `EARLY_MACHINERY_HANDOFF.md`.

## September 12 — 725 verified operating discoveries

Parchment preparation is integrated at `01038541577d52ab78785ab4e94490fd3a8c1ac1`. Actual hunting supplies untanned skins; three paid recipes produce prepared skins, writing sheets and bound records. Study consumes real sheets within existing Knowledge work. Imported sheets do not teach manufacture; tanned leather cannot substitute.

113 distinct worktree and 33 canonical cases pass, with no errors/failures/skips/orphans. Clean normal headless boot. Graph: **725 discoveries / 507 routes / 382 recipes / 18 facilities**. All 725 canonical definitions exactly match the ledger; 15 catalog-tool tests pass. Ledger: **725 integrated + 2,512 drafts = 3,237 identities**, leaving **1,763 to author and 4,275 to implement**. Art remains **146 / 725, 579 queued**, with parchment illustration prepared separately. Existing save and labor owners remain authoritative; process work abstracts soaking and tension-drying. See `PARCHMENT_RECORDS_HANDOFF.md`.

Six machinery methods are READY at source `3b0c030` and undergoing integrator review. No player launch or package rebuild.

## September 12 — numerical and statistical coverage checkpoint

Reviewed 24 distinct D12 proposals with explicit input/work requirements, uncertainty/failure limits and paid outside acquisition routes. Existing dimensional analysis, numerical integration/root finding and least-squares were excluded from duplicate counting. Ledger now holds **724 integrated + 2,513 drafts = 3,237 identities**, leaving **1,763 to author and 4,276 to implement**. All parents resolve, no normalized-name duplicates, and 15 catalog-tool tests pass. These drafts add no runtime capabilities. See `technology-review/Numerical and Statistical Methods Review.md`.

Runtime remains **724 discoveries / 506 routes / 379 recipes / 18 facilities**; art remains **146 / 724, 578 queued**. Six early machinery methods are under implementation in the other task, including physical site-bound water-drive service. No player launch or package rebuild.

## September 12 — armor and leather art verified

Leather illustrations `0905774` and armor art source `4a4ec9c` (integrated as `9b80339`) are visually reviewed. All eight canonical textures load at 768px with mipmaps; 12 canonical atlas cases pass, and import logs are clean. Art now covers **146 of 724 live discoveries**, with **578 queued**. Runtime and ledger totals remain unchanged. The additive ResearchVisuals conflict retained all eight new bindings and all prior subjects. No save changes, player launch or package rebuild.

## September 12 — 724 verified operating discoveries

Integrated armor source `08cd91b` and leather source `d4988fd` as canonical `9c688d27b44bd3dc081b7ec8a0477b1413464776`. Six armor methods manufacture physical components and complete infantry kits; issued fractions now determine actual armor and penetration. Two leather methods turn actual hunting byproducts into paid tanning, fitting, garment use and compatible repairs. General-led operations and existing stock/labor/save owners remain authoritative.

**193 distinct worktree cases and 102 canonical cases pass**, with zero errors, failures, skips or orphans. Graph: **724 discoveries / 506 routes / 379 recipes / 18 facilities**, no dependency errors. All 724 canonical definitions match the ledger; 15 catalog-tool tests pass. Ledger: **724 integrated + 2,489 drafts = 3,213 identities**, leaving **1,787 to author and 4,276 to implement**. Art: **138 verified / 724 live, 586 queued**; eight new illustrations are in preparation.

The one additive recipe conflict retained both complete families. Armor fitting's surgical-anatomy parent was explicitly reconciled to standard measures, preserving the hand-formed/rolled-sheet alternatives and original predicate in the review record. Existing cart quotes use actual Cart Assembly Kits; the stale test was corrected. A standalone audit preload-order error was corrected with runtime loading. Normal headless boot reaches the direction screen cleanly. No player launch, package rebuild or full historical pacing claim. See `ARMOR_LEATHER_INTEGRATION.md` and individual handoffs for bounded material and process abstractions.

## September 12 — glass and earthen illustrations verified

Integrated `02e882d`: seven visually reviewed discovery illustrations and explicit 768px mipmapped import settings. All seven textures load correctly in the canonical checkout, and all 12 worktree atlas cases pass. Art now covers **138 of 716 live discoveries**, with **578 queued**. No runtime or save changes; the runtime remains 716 discoveries, 498 routes, 365 recipes and 18 facilities. Ledger remains 3,213 identities, with 1,787 still to author and 4,284 to implement. The next armor delivery includes six existing identities, including fitted shields. No player launch or package rebuild.

## September 12 — reviewed civilian response coverage

## September 12 — geological coverage and textile art checkpoint

Reviewed31 new geological-investigation proposals:716 integrated +2,497 drafts =**3,213 distinct identities**, leaving **1,787 to author and4,284 to implement**. Existing orebody models, spatial variograms, general traceability and broad observation methods were excluded from duplicate counting. All new parents and AND/OR groups resolve;15 catalog-tool tests pass. These proposals add no runtime survey or resource capability. See `technology-review/Geological Investigation Depth Review.md`.

Textile art source `a76c245` is integrated as `d13ca4b`: six images visually reviewed, all canonical768px/mipmap loads pass, and12 canonical atlas cases pass. Art now covers **131 of716 live discoveries**, with **585 queued**. Runtime remains **716 /498 routes /365 recipes /18 facilities**. The other task is preparing a bounded five-method armor implementation under the existing general-led campaign and equipment owners. No player launch or package rebuild.

## September 12 — 716 verified operating discoveries

Integrated six textile methods from `6d749d4` and two earthen building methods from `9f03bbd` as canonical `2d0048225faccc4fc1f7563a510e74c8c6565aa9`. Paid measured yarn and powered/manual spinning feed actual cloth and garments; imported figured cloth retains its identity through use, care and saves. Actual city trade pays and delays delivery. Adobe units dry before wall assembly, while wattle infill dries after application; local weather delays housing and upkeep spends real materials.

**110 combined worktree and61 canonical cases pass**, with zero errors/failures/skips/orphans. Graph: **716 discoveries /498 routes /365 recipes /18 facilities**, no dependency errors. All716 canonical definitions match the ledger;15 ledger-tool tests pass. Ledger: **716 integrated +2,466 drafts =3,182 identities**, leaving **1,818 to author and4,284 to implement**. Art: **125 verified /716 live,591 queued**. Six textile illustrations are being prepared separately.

Existing stock, labor, plot and save owners remain authoritative; older garment lots default to plain fabric. Textile patterns and earth materials are bounded compatible classes, not arbitrary specifications; climate drying uses the existing monthly sample. Normal headless boot reaches the direction screen but again emits an exit-time ObjectDB/resource cleanup warning. No player/package launch or full historical pacing claim. Details: `EARTHEN_TEXTILE_INTEGRATION.md` and individual handoffs.

## September 12 — 708 verified operating discoveries

Integrated glass and ceramic processes at `5449d0f3bbdb7c691cfe30e869549f92b22454bb`: five existing identities and eleven paid recipes. Compatible cullet remelts with losses; annealed blanks supply actual lenses; plaster molds and prepared bodies produce green forms that need firing and compatible glazing before entering the brine workshop. Original prerequisite predicates remain intact.

**65 distinct worktree cases and 40 canonical cases pass**. Graph and exact loaded snapshot: **708 discoveries /490 routes /352 recipes /18 facilities**; all definitions match and 15 ledger tests pass. Normal headless boot reaches the direction screen without errors. Ledger: **708 integrated + 2,474 drafts = 3,182 identities**, with **1,818 still to author and 4,292 to implement**. Art: **125 verified /708 live, 583 queued**.

Physical processes use compatible material classes and paid trial losses, without detailed thermal/chemistry histories or universal vessel certification. No save schema changes. New subject art and full historical pacing remain outstanding. Textile implementation is active in its separate task. No player launch or package rebuild. See `GLASS_CERAMIC_PROCESS_HANDOFF.md`.

## September 12 — 703 verified operating discoveries

Integrated civilian clinical care `9c6ec61` as `45891f6`, and its three illustrations `16e5cd5` as canonical `851a0cad29aa55e6a7fd689d58b5775af3cf7bba`. Observation and pulse assessment consume dated clay records and local Knowledge duty; nursing consumes water and cloth, with paid continuous care contributing bounded recovery through the existing health owner. Research capacity excludes reserved carers after injuries and absent scholars. Selected-city reports, delayed supplies and optional legacy save state are verified.

**114 combined worktree cases and 43 canonical cases pass**, with zero errors, failures, skips or orphans. All three new canonical textures load at 768 pixels with mipmaps. Graph: **703 discoveries /485 routes /341 recipes /18 facilities**, no dependency errors. All 703 canonical snapshot definitions match the ledger; 15 catalog-tool tests pass. Ledger: **703 integrated + 2,479 drafts = 3,182 identities**, leaving **1,818 to author and 4,297 to implement**. Art: **125 verified /703 live, 578 queued**.

Supportive care uses generic burden and clay records, not disease-specific therapies; unused standing duty remains reserved until adjusted. The headless boot reached DIRECTION_SCREEN_READY without script errors but emitted an exit-time ObjectDB/resource cleanup warning. Full historical pacing remains unproven. No player launch or package rebuild. The next six textile-process identities are assigned independently from this verified runtime.

## September 12 — seven metal-process illustrations verified

Integrated art and explicit import settings through `29188168066b538a195d8cf10dfa1fdfa9a3e65e`. All seven canonical textures load at 768 × 768 with mipmaps; 12 worktree atlas cases pass. Art now covers **122 of 700 live discoveries**, with **578 queued**. Runtime remains 700; the ledger remains 3,182 identities. Clinical runtime delivery `9c6ec61` is READY for combined integration review.

Twenty-one new disaster-response and recovery drafts extend incident assignments, finite evacuation destinations, damage accounting and debris handling. Three overlapping proposed methods were excluded and mapped conceptually to existing procurement, continuity and regulatory review. All 15 ledger-tool checks pass; no duplicate names, missing parents or unreachable drafts. See `technology-review/Disaster Response Service Review.md` for primary sources and future operating acceptance.

Live remains **700 discoveries /482 routes /341 recipes /18 facilities**, with 115 verified illustrations. The authored ledger is **700 integrated + 2,482 drafts = 3,182 identities**, leaving **1,818 to author and 4,300 to implement**. These proposals add no functioning incident system or save state. Clinical care remains HELD in its separate implementation task.

## September 12 — 700 verified operating discoveries

INTEGRATED runtime `07a8085d9e962b805eddc695a42a0f08f29e5201`: seven metal-processing identities provide twelve paid recipes connecting annealing, carburization, casting, brazing and electric welding to actual wire, gears, vessels, cart beds and rolled sheet. All **68 distinct worktree cases and 40 canonical cases pass**, including demanded generator fuel, shared electricity depletion, imported parts, partial-job saves and existing autonomous production. See `METAL_PROCESS_HANDOFF.md`.

Graph and exact canonical snapshot: **700 discoveries /482 explicit routes /341 recipes /18 facilities**. All 700 stored definitions match; 15 ledger-tool checks pass. Ledger: **700 integrated + 2,461 drafts = 3,161 identities**, with **1,839 still to author and 4,300 to implement**. Art: 115 verified /700 live, 585 queued. Civilian clinical care remains HELD in its isolated worker pending full ownership, staffing and behavioral acceptance. No player launch, package rebuild or full-history pacing claim.

## September 12 — optical instrument coverage

Reviewed frozen optical delivery `b8873f6` is integrated as `e37aacb`: 22 distinct optical manufacturing, contrast, imaging and correction proposals, each with five paid recovery routes. Existing coronagraphy and confocal imaging identities were explicitly excluded as duplicates. All horizon mappings merge cleanly; coverage validation and 15 ledger-tool checks pass. See `technology-review/Optical Instrument Methods Review.md`.

Runtime remains **693 discoveries /475 routes /329 recipes /18 facilities**; art remains **115 verified /693 live**. The authored ledger is now **693 integrated + 2,468 drafts = 3,161 identities**, leaving **1,839 to author and 4,307 to implement**. These 22 are authored scope, not working instruments. Civilian clinical-care implementation is assigned to the other isolated task, pending its bounded design and complete acceptance.

## September 12 — verified rail freight and conditioned food

INTEGRATED runtime merge `fbaf803`, with reviewed rail artwork at canonical `e94ffa8e5d65684bf62e7f73b58a0c7b5ec77fc3`. Frozen rail `1c161ef` and food conditioning `0635688` share conserved city stocks, finite workers and existing save owners. All **94 combined runtime checks and 71 canonical runtime/atlas checks pass**; conditioning also passed 20 grain and 14 food-preparation regressions, for 128 distinct runtime cases across the worktree runs. See `RAIL_CONDITIONING_INTEGRATION.md` for paid operations, save compatibility and limits.

Graph and exact canonical snapshot: **693 discoveries /475 explicit routes /329 recipes /18 facilities**. All 693 stored definitions match, and all 15 ledger-tool checks pass. Seven promotions add no identities: **693 integrated + 2,446 drafts = 3,139 identities**, with **1,861 still to author and 4,307 to implement**. Art: **115 verified /693 live**, with 578 queued. Five rail illustrations were visually reviewed and imported with 768-pixel mipmaps. Optical-instrument coverage is in isolated authoring. No player launch, package rebuild or full-history pacing claim.

## September 12 — paid mechanical drives and geared workshop

INTEGRATED runtime `997269f56922f45e8f400a8fe11fb4431da67e58`: seven existing mechanical identities manufacture real clutches, ratchets, chains, bearings, aligned drives, generated gears and hobs. A paid, commissioned Geared Indexing Workshop consumes workers, generated power and replacement components through existing production services. All **54 distinct worktree cases and 28 canonical cases pass**, including binary partial-job and owned-save continuation. See `GEARED_WORKSHOP_HANDOFF.md` for behavior, compatibility and limits.

Graph and exact canonical snapshot: **686 discoveries /468 explicit routes /321 recipes /18 facilities**. All 686 stored definitions match; 15 ledger-tool checks pass. Ledger: **686 integrated + 2,453 drafts = 3,139 identities**, with **1,861 still to author and 4,314 to implement**. Art: 110 verified /686 live, 576 queued. Physical rail freight remains HELD in its worker checkout. No player launch, package rebuild or full-history pacing claim.

## September 12 — physical record media and finite local study

INTEGRATED runtime `5f2dc5c0bd070170f0aa34c2c6880eb3de9a2334`: three existing identities produce paid clay tablets, quantity-record cords and bound paper volumes. Local study consumes real media within one Knowledge work budget; knotted-record assistance is limited to trained specimen quantity work. All **67 distinct worktree cases and 32 canonical cases pass**, including stock conservation, arrived records, ordinary paper/print behavior and owned save continuation. See `RECORD_MEDIA_HANDOFF.md` for the imported-paper binding route and limits.

Graph and exact canonical snapshot: **679 discoveries /461 explicit routes /313 recipes /17 facilities**. All 679 definitions match; 15 ledger-tool checks pass. Ledger: **679 integrated + 2,460 drafts = 3,139 identities**, with **1,861 still to author and 4,321 to implement**. Art: 110 verified /679 live, 569 queued. Rail freight remains HELD in its worker checkout pending complete ownership, shipment, save and control acceptance. No player launch, package rebuild or full-history pacing claim.

## September 12 — supplied laundry and broader rail/food coverage

INTEGRATED runtime `368b7718c419ff73d788e29d3bf9e5ad212a37ce`: three authored identities now implement manufactured soap, electric laundry and dated garment wear trials. Actual supplies, generated power, worker time and sampled garments are consumed. All **109 distinct worktree cases and 61 canonical cases pass**; the final demand/investment checks include fuel-consuming generation and the daily dirt threshold. See `LAUNDRY_SUPPLY_HANDOFF.md` for save compatibility, primary-city electricity scope and the limited game wear protocol.

Graph and exact canonical snapshot: **676 discoveries /458 explicit routes /310 civilian recipes /17 facilities**. All 676 stored definitions match `/tmp/tt-676-canonical-snapshot.json`; 15 ledger-tool checks pass. Reviewed rail `412d360` and food-processing `3079243` add 47 authored drafts, not live features. The ledger is **676 integrated + 2,463 drafts = 3,139 distinct identities**, leaving **1,861 to author and 4,324 to implement**. Art: **110 verified /676 live**, with 566 queued. No player launch, package rebuild or full-history pacing claim. Physical rail freight is now in an isolated worker design/implementation scope.

## September 12 — verified naval access and hull surveys

INTEGRATED runtime `b363f6c6aceaf42515e020281934cef26cb217fd` combines frozen naval `bcda00e` with the canonical sewing checkpoint. All **86 combined cases and 48 canonical dock/clothing/city cases pass**. Paid local construction, finite supported-hull access, dated surveys, automatic supply and delayed secondary-port deliveries share the existing labor and inventory owners. See `NAVAL_SEWING_INTEGRATION.md` for acceptance, save compatibility and the limited canoe/ram-galley handling set.

The clean graph and exact canonical snapshot contain **673 discoveries /455 explicit routes /309 recipes /17 facilities**. All 673 stored definitions match; 15 ledger-tool checks pass. Ledger: **673 integrated + 2,419 drafts = 3,092 identities**, leaving **1,908 to author and 4,327 to implement**. Art: 110 verified /673 live, with 563 queued. Frozen naval artwork `01abed5` was visually reviewed and integrated as `d18a6b0`, with explicit 768-pixel mipmapped imports. Laundry scaffolding is held separately at `b107bca`; it is not live. No player launch, package rebuild or full-history pacing claim.

## September 12 — sewn garments and material-consuming repair

INTEGRATED runtime `638629a669cb62946f88fa51761793941df07e61`: four existing textile identities now implement paid sewing, cutting patterns, size grading and proportional repair. Actual hunting supplies a bounded local bone reserve for needles; stored meat and forecasts cannot create bone. Real cloth, yarn, paper, tools and daily work constrain outputs. All **90 worktree cases and 35 canonical clothing/planner cases pass**; ordinary headless boot is clean. See `SEWING_REPAIR_HANDOFF.md` and `/tmp/tt-sewing-canonical-results.json`.

Canonical snapshot: **671 discoveries /453 explicit routes /309 civilian recipes /17 facilities**. All 671 ledger definitions exactly match `/tmp/tt-671-canonical-snapshot.json`; 15 ledger-tool checks pass. Counts are **671 integrated + 2,421 drafts = 3,092 identities**, leaving **1,908 to author and 4,329 to implement**. Art inventory is **108 verified /671 live**, with 563 queued. Naval dock work remains held in its isolated worker pending acceptance. This checkpoint does not update the packaged player or establish full historical pacing.

## September 12 — grain equipment quotas and two construction illustrations

## September 12 — sustained workshop supply and reviewed coverage

INTEGRATED `cd6accf0cd2dc24b51842bfc3280530ec8c2b52f` fixes a reproduced one-workshop yarn-supply stall. Idle automatic civilian lines can make their own missing upstream inputs through ordinary paid retooling; manual unfinished, paused, reserved and in-progress jobs remain protected. All 65 worktree cases and 32 canonical planner/production cases pass. Optional saved management flags are validated; old unmarked lines remain valid. See `CIVILIAN_UPSTREAM_RESUMPTION_HANDOFF.md` and `/tmp/tt-upstream-canonical-results.json`.

Reviewed maritime coverage `7c81928` adds 20 authored proposals, giving **667 integrated + 2,425 drafts = 3,092 identities**, with **1,908 still to author and 4,333 to implement**. All 15 ledger-tool checks pass; the live graph and 108-art inventory are unchanged. Pacing evidence `6b8940f` closes the older 476-catalog 250-year run and records one bounded 667-catalog early observation. Neither proves current industrial throughput or full-history pacing; no long run was restarted. See `technology-review/PACING_PROFILING.md`.


## September 12 — verified water conveyance, 667 live discoveries

INTEGRATED runtime `04d0dcb1e5d151cb3d0ad360fd2f1bb9466b58e8`, incorporating frozen water `5d08c2b` into canonical `7a5e91f`. **107 combined worktree cases across nine suites and 42 canonical water/clothing/city cases pass**. The graph is clean at **667 discoveries /449 explicit learning routes /309 civilian recipes /17 facilities**. See `WATER_CLOTHING_INTEGRATION.md` for source-bound paid installation, real secondary-city shipping, household-fetching conservation, owner/save coverage and limitations. No player/editor launch or package update occurred.

Reviewed computing coverage `001a230` adds 16 authored proposals; verified water promotion adds no identities. The ledger is **667 integrated + 2,405 authored drafts = 3,072 distinct identities**, leaving **1,928 to author and 4,333 to implement** toward 5,000. All 667 stored definitions exactly match the canonical snapshot ; 15 ledger-tool cases pass. Paid alternative pipe installation foundations retain their earlier draft predicates as reconciliation evidence.

Both water illustrations were visually reviewed and merged from `965c7c6` / `73ab651`, with explicit 768-pixel mipmapped imports. Art inventory: **108 verified /667 live**, 559 queued. All 12 atlas checks pass after import (`/tmp/tt-667-atlas.log`). Full historical pacing, all 5,000 implementations and the remaining illustrations are unfinished. Canonical evidence: `/tmp/tt-water-clothing-canonical-results.json`, `/tmp/tt-667-canonical-snapshot.json`.


## September 12 — supplied household clothing

INTEGRATED runtime `3dce8a70fbc537cce2b0743d1d1e4d167da7d079` from `2bcd799`: six authored textile methods now produce and maintain finite garments and woven wraps. Paid tools, material inputs and remaining Logistics work constrain production, layering and laundering; only issued condition/coverage reduces cold health and cold/storm mortality costs. Save state is owner- and city-local. See `HOUSEHOLD_CLOTHING_HANDOFF.md`.

All **101 worktree cases across six suites and 15 canonical clothing cases pass**, including full-file legacy save loading, secondary-city use, shared quotas and actual daily exposure consumers. Graph: **657 discoveries /439 explicit routes /303 civilian recipes /17 facilities**; no graph/dependency errors. Headless normal boot is clean. Water conveyance remains HELD in its worker checkout pending a complete delivery.

The reconciled ledger has **657 integrated + 2,399 authored drafts = 3,056 distinct identities**, leaving **1,944 to author and 4,343 to implement** toward 5,000. All 657 stored runtime definitions exactly match `/tmp/tt-657-canonical-snapshot.json`; 15 ledger-tool tests pass. Art: 106 verified /657 live, 551 queued. No player/editor launch or interruption; this does not update the previously packaged 559 build or establish full historical pacing. Canonical evidence: `/tmp/tt-clothing-canonical.log`.


INTEGRATED grain fix `b7d35a857da79d410e7eaca13608ac6bd3079828`: installed mill capacity is shared across every grain input stock for the day. Paid handmills can handle the same remaining stock after powered capacity is used. All 59 focused worktree checks pass, including the final 20-case grain rerun; no discovery IDs or save fields change. See `GRAIN_MACHINE_CAPACITY_HANDOFF.md`.

Reviewed art source `e4fd8ee` is integrated as `a228f0e`, adding roof tiles and rammed-earth construction while retaining thatching and all other subject bindings. Both use the approved paper style, mipmaps and 768-pixel runtime textures. The refreshed inventory is **106 verified /651 live**, with 545 queued. Runtime remains **651 discoveries /433 routes /303 recipes /17 facilities**. Water conveyance is in isolated development; no new player launch.

## September 12 — supplied construction and food lots: 651 integrated

INTEGRATED runtime merge `174f80f4fbcb3d581d6ac7a418dd252f0ed3d624`, from canonical `ff0084b` with food `b43d312` and construction `9ce865b` / `42aa579`. Canonical now contains **651 discoveries, 433 explicit learning routes, 303 civilian recipes and 17 operating facility types**. Fifteen food methods use finite cereal lots, paid processing and lot-specific inspection; 22 construction methods connect manufactured materials to actual building work, supplied curing, condition and compatible upkeep. Both use existing owned stocks and labor. Save validation retains grain, food and building state checks together; old saves initialize missing food state and accept absent building profiles.

All **215 worktree cases across 13 runtime/ownership/kit/atlas suites** and **68 canonical cases across four suites** pass. Graph and production closure, import and ordinary headless entry are clean. The separately completed settlement visual suite passes **82/83**, with one existing procedural river-edge fixture producing no mesh at its assumed location; this is documented rather than expanding the release into terrain work. Updated legacy fixtures cover current kit/mesh selection, city identities and label behavior without starting terrain generation. See `FOOD_CONSTRUCTION_INTEGRATION.md`, `FOOD_BATCH_PROCESSING_HANDOFF.md`, and `CONSTRUCTION_MATERIALS_IMPLEMENTATION.md`. Evidence: `/tmp/tt-651-results.json`, `/tmp/tt-651-canonical-results.json`, `/tmp/tt-651-visual-isolated.log`, `/tmp/tt-651-canonical-snapshot.json`.

The editorial ledger contains **651 integrated + 2,405 drafts = 3,056 distinct identities**, leaving **1,944 to author** and 4,349 still to implement toward 5,000. Conduit `5e7cc4e` and frontier `451254f` add 28 authored proposals; promoting the food/construction runtime adds no identities. All 15 ledger-tool tests pass, and all 651 stored runtime definitions exactly match the canonical snapshot. This is an ongoing checkpoint, not completion or a full historical-pacing claim.

Thatched-roofing art `59abb32` was visually reviewed and imported as `8b0a73b`, with mipmaps and a 768-pixel runtime limit. Radio import received the same existing atlas limit. Current art inventory: **104 verified /651 live**, with 547 queued. No player/editor launch or interruption occurred for this checkpoint; the previously packaged 559-discovery build is not claimed to include these changes.

## September 12 — communications and conserved staple processing

INTEGRATED runtime merge `5eab52adbbc30af5c6437e08d61946dbaa3c51de` from canonical `604567c4bc6ae414ff256238a52e57513ed67d8c`, combining grain worker `1764b09` and communications `f3537b8` plus reviewed bench-family correction `2a9562c`. Canonical now has **614 discoveries, 396 explicit learning routes, 282 civilian recipes and 17 operating facilities**. This is a checkpoint toward the user's continuing request for all5,000 integrated discoveries, not completion of that goal.

Seven grain methods use paid handling equipment, finite cereal/fraction stocks, shared Logistics work, electricity where required, and delayed malting with losses. Food consumption, external issue, storage, spoilage and saves account for that same stock. Forty-eight communications discoveries add physical equipment and compatible optical/electrical/radio/digital analysis facilities. Paired staffed radio stations can transmit negotiated research records at actual embassy arrival; finite endpoint budgets, known locations, range, war and supplies constrain delivery. Knowledge still requires local study, payment remains real, and envoys still travel home. Independent review corrected the original cross-family analysis pool so optical tools cannot analyze unrelated electronic apparatus.

All **279 worktree cases across21 suites** and **69 canonical cases across6 suites** pass, with zero errors/failures/flaky cases/skips/orphans. Canonical graph/production closure is clean. Runtime evidence is `/tmp/tt-combined614-results.json`, `/tmp/tt-combined614-canonical-results.json` and `/tmp/tt-combined614-canonical-graph.log`. See `STAPLE_PROCESSING_HANDOFF.md` and `COMMUNICATIONS_IMPLEMENTATION_STATUS.md` for operating details, save compatibility and limits. Save version remains unchanged, with missing new fields initialized safely. Full historical pacing and the remaining4,386 discoveries are still ongoing work.

Radio telegraphy subject art was visually reviewed and integrated from `ac615e6` as `865a1c2`; the refreshed art audit reports **103 verified images /614 live discoveries**, with511 queued. Artwork counts do not stand in for implemented discoveries. The previous signed standalone package remains the559-node `a578cd4` build; the still-open player is the older2026.09.12.1 opening screen. This checkpoint integrates canonical code and art; it does not claim a new player launch or interruption of that window.

## September 12 — substantive technology baseline

INTEGRATED reviewed merge `a578cd41d36bb2e130c9abdbecfeee5234383a36` by fast-forward from canonical Mac `a2123297518176aadd53509513a4676371777f71`. Source baseline `82b574e` contains committed runtime through `18b0cb7`. Release **2026.09.12.2** supersedes the earlier bounded food release below.

Canonical now contains **559 live discoveries, 336 explicit learning routes, 240 civilian production recipes, and 12 operating facility types**. This adds 359 discoveries to the preceding 200-node release. Research uses causal prerequisites, actual staff/material evidence, paid physical exchanges, partnerships, visiting scholars, licenses, and consumed specimens. Workshop intermediates and paid operating facilities span practical materials through computing. Supplied food, cooling, canning, crop nutrients, military training/doctrine, and equipped medical/repair support use the same owned simulation for player and rivals. The three cooking methods remain included. The full 5,000-node design catalog and uncommitted communications are not included.

All **629 worktree cases across 76 suites** and **131 canonical cases across 10 suites** pass, with zero errors/failures/flaky cases/skips/orphans after documented integration corrections. Canonical import and full graph/recipe/plant structural audit are clean. The ordinary worktree entry point boots cleanly at the release version. Actual save-file tests preserve paid facilities and next-day consumption and restore safe defaults for missing legacy fields. Repeated-refresh UI tests retain only the selected discovery's operating controls. See `TECHNOLOGY_BASELINE_RELEASE_HANDOFF.md` for exact conflict decisions, test corrections, compatibility and limits. Detailed evidence: `/tmp/tt-baseline-verified-results.json`, `/tmp/tt-baseline-canonical-results.json`, `/tmp/tt-baseline-canonical-graph.log`.

The standalone canonical package is built from exact source `a578cd41d36bb2e130c9abdbecfeee5234383a36` through `tools/launch_game_macos.py`; `build.ok` matches and the signature verifies. Its absolute path is `artifacts/macos-release/a578cd41d36b/Tomorrow and Tomorrow.app`. The preceding player window remains on the untouched 2026.09.12.1 opening screen (PID22048); a new player launch is not claimed. Normal quit/window-close did not dismiss that opening window, and it was not force-stopped. The user redirected ongoing work toward integrating all5,000 discoveries while the new package is ready. Structural closure and focused behavior checks do not establish full historical balance or smooth mature-campaign frame rates. No unrelated remote backlog is pushed.

## September 12 — supplied cooking and preservation

INTEGRATED bounded food commit `860cdb6964ac622c2f258f64d03b9f607be81c6b` by reviewed fast-forward from canonical Mac `2041666f666d9a487795326325df4d714dcda61f`. The originating coordinator designated this task integrator; the source acknowledged an exclusive runtime window. Release target **2026.09.12.1**.

Hearth roasting, earth ovens and steaming are three ordinary discoveries with adopted, staffed operation and physical inputs. Steaming requires hearth practice plus clay shaping OR basketry. Meal preparation uses shared Logistics time and only benefits fresh rations actually consumed; it creates no calories or storage life. Smoking now consumes Timber; air drying retains its fuel-free plant route. Food reports show actual meals/material use, and the inspector/tree show causal alternatives and operating conditions. Existing save authorities remain unchanged.

The original food worker was `c247e8d` on an isolated compatibility merge. Independent integration review excluded that merge's 625 inherited files: military, industrial, licensing, save extensions, unfinished communications and the 556-node worktree baseline are **not integrated**. Only 13 reviewed files were ported against current canonical code, including the small standalone AND/OR evaluator and existing-pathway/UI support. Canonical now has **200 live discoveries: 197 existing plus three food methods**. See `FOOD_PROCESSING_RELEASE_HANDOFF.md` for exact scope, conflicts, tuning and limits.

All **69 worktree and 69 canonical cases pass**, zero errors/failures/skips/orphans (food 14, tree 9, redistribution 2, atlas 9, discovery 9, society exchange 26). Canonical import and graph/channel/reachability audit are clean. Worktree normal-entry headless boot is clean. Logs are `/tmp/tt-food-canonical-<suite>.log` and `/tmp/tt-food-canonical-audit.log`. UI tests validate data/control construction, not native screenshot layout. Full-history balance, the 5,000-node revamp, later grain systems and new subject artwork remain unfinished.

Verified standalone package and running player: source `d388ea0631865a060dbf7cd7c0118a595591df32`, PID `22048`, absolute executable under canonical `artifacts/macos-release/d388ea063186/Tomorrow and Tomorrow.app`. The normal launcher exported the release and verified its signature; `build.ok` matches that source hash. Native inspection shows the ordinary opening direction screen with window title `Tomorrow and Tomorrow · 2026.09.12.1`. No prior player/editor was running or interrupted. There is no test override or alternate player entry scene. This final launch record is documentation-only; the running executable already includes the integrated food code and is left open for the user.

## September 11 — skip invisible terrain shading

INTEGRATED `f3345c92c25d85ba2c1f45d4b3d229b56f66abfc` by reviewed, conflict-free fast-forward from canonical Mac `ef3eb8701ddc7bce05648da0268731440162aa29`. The terrain shader now skips full surface calculations under completely opaque fog, and close soil/clearing detail when its existing influence is exactly zero. Physical terrain, climate, resources, season, woodland scale, fog boundaries and four viewing distances remain unchanged. No new assets, geometry, cache budgets, simulation rules or save schema.

All **41 worktree and 41 canonical cases pass**, zero errors/failures/flaky cases/skips/orphans. Ordinary imports and normal-entry headless boots are clean. Guarded native baseline/candidate comparisons and the complete terrain LOD probe pass; real woodland, dryland, coast/fog-edge and full landscape captures were inspected. Hidden images are byte-identical; visible images are identical or differ by one 8-bit channel value in at most 9 of 921,600 pixels. See `TERRAIN_SHADER_COST_HANDOFF.md` for reproduction, raw evidence and the narrow rounding tolerance.

The isolated native material comparison at 1280×720 measured **30–34% lower frame intervals on known distant terrain**, and **86–91% lower on fully hidden terrain**, with baseline/candidate/candidate/baseline ordering. These are uncapped render-loop timings, not populated-campaign FPS or GPU timer results; the Compatibility GPU timer is unavailable. Synchronous simulation-day stalls and broader landscape quality remain ongoing work.

Normal standalone release target **2026.09.11.3** is packaged through the canonical build-only launcher after removing both owned test overrides; `build.ok` identifies the exact source revision. No player/editor was launched, stopped or restarted. The separate technology audit was left alone. This is a landscape-only delivery. Old discovery/portrait/window-art work remains STOPPED and unintegrated; no other worker changes are included.

## September 11 — readable woodland at aerial distance

INTEGRATED `0c33647568e8ba3a0868ca274460384d76618b40` by reviewed, conflict-free fast-forward from canonical Mac `2f695346b9c525a2c3b5bba1cbc9ad97fb24a210`. The forest crown layer now uses one physically consistent scale, with roughly 10–20 m crowns and retained crown-top/shadow contrast at the actual 10,000-foot view. Existing mipmaps and pixel-footprint filtering blend it into broad cover at distance. No new imagery, geometry, vegetation records, resource quantities, simulation rules or cache budgets are introduced.

All **41 worktree and 41 canonical regression cases pass**, zero errors/failures/flaky cases/skips/orphans. Ordinary imports and normal-entry headless boots are clean. The guarded native material comparison passes on real temperate/tropical woodland and drylands, including all four distances, winter, harvested cover, coordinate reanchoring, paused stability and fog. Final dryland, fully harvested, hidden, regional and continental material comparisons are byte-identical to baseline. The complete land/water terrain LOD probe also passes coverage, progressive refinement, cancellation, fog and world-boundary checks; captures were inspected. See `WOODLAND_SCALE_HANDOFF.md` for evidence and limits.

Normal standalone release target **2026.09.11.2** is packaged through the canonical build-only launcher after removing both owned test overrides. No player/editor was launched, stopped or restarted. The separate technology worktree process was left alone. This improves woodland readability; it does not finish landscape realism or fix mature-campaign FPS. Per the user's correction, this thread now focuses on landscape: the old discovery/portrait/window-art continuation is STOPPED and unintegrated.

## September 11 — mature-campaign daily research cost

INTEGRATED `613eb98aaad3ad2daaa7fdf3539c06c19799f67b` by conflict-free fast-forward from canonical Mac `61da5e4310c4154fa7d80a915c69c2bf86602b66`. Daily research redistribution now ranks alternatives only in domains that have stranded researchers. Previously it ranked unrelated domains even though those researchers could never transfer there. No research scores, day/evidence gates, RNG, population dynamics or opponent turn frequency change.

All **69 worktree and 69 canonical cases pass**, zero errors/failures/flaky cases/skips/orphans, across research redistribution, discovery projects, simulation performance, civilization parity/save continuation and society exchange. The real day-11238 campaign with twelve opponents was replayed for 24 days. Every opponent completes every day; the complete saved outcome matches the original, excluding only the wall-clock save timestamp. Original headless daily CPU averaged **254.625 ms**; the worktree averaged **207.886 ms**, and the integrated canonical replay **213.524 ms** (about 16% below the original). These are short local CPU measurements, not rendered FPS or a claim that frame stalls are solved. Host load varies.

Canonical import and the normal-entry headless boot are clean. Both owned overrides are removed before the normal standalone **2026.09.11.1** build-only package; its `build.ok` identifies the exact source revision. No player/editor was launched, stopped or restarted. Save schema and current investigations are unchanged. See `DAILY_COST_HANDOFF.md`; logs are in `artifacts/daily-cost/` in the worktree and canonical checkout. Other windows, era skins, subject-specific art, landscape and mature-campaign frame-time work remain ongoing. No other worktree was integrated or modified.

## September 10 — approved ancient scouting window

INTEGRATED `31ba19db2a072b6e88d0db0cd1d00a56508298e0` by conflict-free fast-forward from canonical Mac `ede2e04ea33fdb95e1e8c443dcd0d9b9c6a7121e`. The accepted ancient Scouting design now runs in the real native window: original expedition art, a clay surface, bundled Cinzel headings, a tactile allocation slider, concise purpose choices and compact live party rows. Expanded details scroll into view and retain their controls across refreshes. Empty windows shrink; fixed close/Done controls remain reachable. The actual latest returned find appears with subject-appropriate art, while objects still carried by absent parties remain private. Invitation capacity and continuing visits are shown separately.

All **59 worktree and 59 canonical cases pass**, zero errors/failures/skips/orphans, across the new seven-case presentation suite and existing scouting, society-exchange and route-planning suites. Canonical import and normal-entry headless boot are clean. Native actual-input captures pass and exit at 1440×1000, 960×720 and 340×640 through the verified private background guard. Purpose changes, slider input, disclosures/scrolling, retained rows, empty/advanced states and map/close/Done/Escape dismissal are verified. See `ANCIENT_SCOUTING_WINDOW_HANDOFF.md`; logs are under `artifacts/ancient-scouting/` and the worktree's `artifacts/macos-background-capture/`.

Normal standalone release target **2026.09.10.6** is packaged with the canonical `tools/launch_game_macos.py --build-only`; its `build.ok` identifies the exact integrated revision. Both owned overrides are removed. No player/editor was launched, stopped or restarted. Simulation, saves, physical scouting, shared civilization rules and pause/resume ownership are unchanged. This completes the ancient Scouting window only; the full later-era skin system, other windows, mature-campaign frame stalls, landscape and subject-art work remain ongoing. Advanced capability uses neutral expedition scenery until its own skin is ready.

## September 10 — canopy transition and native verification

INTEGRATED `14eb89050a60d835cb320d2decb56f9091a6e3e4` by conflict-free fast-forward from canonical Mac `940d5a2ad848d9f45b8d98825cd5219a3eda83e9`. Crowns, scrub and forest floor share an aspect-aware fade and a feathered physical boundary. The actual 10,000 ft views no longer retain the square of opaque canopy remnants. Drawing and deferred construction use the same visibility threshold; settled close views construct plants, later zoom preserves identities, and unchanged upkeep retains the clearance cache.

All **41 canonical cases pass** across seven focused suites, zero errors/failures/skips/orphans (`artifacts/canopy-transition/canonical-tests.log`), matching the final worktree run. The normal entry boots and exits cleanly with private userdata (`canonical-boot.log`). Native worktree canopy, seasonal and four-distance terrain probes pass and exit through the verified private Mac capture guard. Actual temperate/tropical/dryland captures, both 10,000 ft aspect ratios, paused pixels, seasonal identity stability, fog concealment, progressive refinement and planet-edge clipping are covered. The combined source diff and representative captures were reviewed. See `CANOPY_TRANSITION_HANDOFF.md` for complete evidence and limitations.

Normal standalone release target **2026.09.10.5** uses `tools/launch_game_macos.py --build-only`; its `build.ok` records the exact packaged revision. Both owned test overrides are removed. No player or editor was stopped or relaunched; the separate technology worktree's headless test process was left alone. Physical resources, geography, save schema and player/opponent simulation rules are unchanged. Existing tree artwork is retained. Mature-campaign frame stalls and broader landscape beauty remain ongoing work. The user's accepted ancient Scouting design is an interactive mockup, not a shipped game skin; subject-specific art and other worktrees remain separate.

## September 10 — scouting dispatch correction

INTEGRATED `96b4f371f9081e854395bfef3166a424556677d7` by conflict-free fast-forward from canonical Mac `2835f00b4114c9aa0241822e77ad3a4c5ecffc61`. Recruitment/influence visits no longer wait for household reception capacity. Staff visit reported peaceful communities or physically search for contact, use smaller affordable parties, consider longer journeys, and rotate beyond unreachable destinations. Household invitations retain all actual-source, reception and food checks. Departure status, specific invitation shortages and the next automatic review are shown separately.

All **113 worktree regression cases pass** across eight suites (`/tmp/tt-dispatch-regression.log`); all **52 canonical scouting/exchange/route cases pass** after integration (`/tmp/tt-dispatch-canonical.log`), with zero errors, failures, skipped cases or orphan nodes. Physical visit/return, absent-household conservation, full-home visits, first-contact search, distant and blocked destinations, provision-limited parties, a farther frontier, save continuity and 340×640/960×720 panel containment are covered. This is not a new frame-rate benchmark or a native artwork audit.

Release **2026.09.10.4** is packaged through the normal Mac launcher after removing the owned test override. The user closed release 2026.09.10.3; no player/editor was stopped. Existing active trips retain routes/timing. An optional per-owner destination cursor defaults to zero for old saves. See `SCOUT_DISPATCH_HANDOFF.md` and `RELEASE_2026_09_10_4.md`. The closed session did not have a recent save for identifying its exact active blocker; the faulty dispatch gates and their reproductions are verified. Prior held art/landscape and frame-time work remains separate.

## September 10 — exploration, finite migration and knowledge exchange

INTEGRATED `63ec7dfcfa7753b8d7c4fe7f13fcb9e8bd6114c4` by conflict-free fast-forward from canonical Mac `7440a7e5d973f2cee82f15564598f3a3cef188a2`. Physical scouting and envoy encounters now carry artifacts, material samples, knowledge and culture. Study supplies specific evidence; fifteen alternative early research paths reconverge on ordinary discoveries. Recruitment transfers actual source households, reserves reception capacity, pays provisions and adds integration pressure. It no longer generates random newcomers. Leaders respond to integration, emigration and learned practices; sharing/reception choices use common player/AI rules. Research understandings support both owners, and border understandings suspend mutual recruitment.

All **132 combined canonical cases pass**, with zero errors/failures/skips/orphans (`/tmp/tt-exchange-canonical-tests.log`), matching the final worktree run. The native collection probe passes real rendering, containment and map-click/Escape dismissal at 960×720 and 340×640; captures were inspected. The private day-11238 campaign with twelve opponents loads and runs twelve ordinary daily steps at a mean **256.23 ms**, range **231.85–325.98 ms**. This short headless sample does not establish smooth frame rates or solve remaining daily stalls. See `KNOWLEDGE_EXCHANGE_HANDOFF.md` and `RELEASE_2026_09_10_3.md` for behavior, evidence and limits.

Normal standalone release target **2026.09.10.3** is packaged only through `tools/launch_game_macos.py --build-only`, with its exact integrated source revision in `build.ok`. No player/editor was stopped or relaunched. Owned test overrides are removed before packaging. Existing saves begin recording actual new exchanges; old rewards are not removed or fabricated retrospectively. Migration currently uses the home settlement and actual civilization populations, not a new independent nomad-population system. Individual new artifact art, full 2,500-year strategic balance, held subject-art work and canopy work are not claimed complete. Continue those authorized iterations without redoing this delivery.

## September 10 — ruler-led opponent decisions and combined release

INTEGRATED `50edee938e0d9d68b28f952dfe0cfcb993d10251` from task `542416b` on `codex/leader-decisions`, based on performance commit `84dcddb8b95e53aed1527dd74d407182f1f8dd45`. The cherry-pick into canonical Mac main was conflict-free. Opponent strategic choices now use the same ruler personality as foreign-leader conversation. Goals affect existing research attention, recruitment commitments, staff training, eligible equipment preferences, exploration, expansion, diplomacy, army objectives and separate naval/air mission choices. All ordinary resource, knowledge, personnel and mission gates remain in force. Monthly reviews are distributed across days with the same twelve reviews per 360 days. No actor or daily turn is skipped. See `LEADER_DECISIONS_HANDOFF.md` for scope, compatibility and limits.

All **94 combined canonical cases pass**, zero errors/failures/skips/orphans, across seven suites (`/tmp/tt-leader-canonical-tests.log`): ruler decisions, shared civilization simulation, land/naval/air catalogue, staff training, research projects, performance invariants and secondary-city rendering. The task's 72 cases also passed before integration. Existing manual-controller parity and campaign/save continuity checks pass. New preferences take effect on the next review in existing campaigns; century commitments retain their existing duration.

The final normal-rendering release probe on the actual mature campaign advances **86.062 days in 30.037 seconds (2.865 days/second)** at the 3-day setting. It records four actual research mixes and three training policies among all twelve opponents. Most are short of food, so emergency convergence is expected. The map capture was inspected and the isolated probe exited. It produced 102 frames in 30 seconds: **daily CPU stalls remain**, and this does not establish smooth graphics or steady 3 days/second. A separate-render-thread diagnostic reached 2.971 days/second but uses an experimental engine option; that option is not enabled in the normal build. No player/editor was interrupted or launched.

Release **2026.09.10.1** combines this change and the earlier performance work. Package only with `tools/launch_game_macos.py --build-only`; the normal app's `build.ok` identifies the exact integrated source revision. Owned overrides and temporary test entry points are removed. The subject-art worktree is still unfinished and excluded. Continued landscape/art work and further frame-time improvements remain pending; no claim that those tasks are finished.

## September 10 — mature-campaign performance

INTEGRATED `84dcddb8b95e53aed1527dd74d407182f1f8dd45` by conflict-free fast-forward from canonical Mac `418869c8e7a1efe362c0c878f1c705c223c428cd`. Daily city/observer history copies and unchanged secondary building/resource mesh rebuilds are removed. Climate, geography, claim shape and social presentation caches retain live simulation rules. The ordinary calendar counts monotonic wall time rather than capped frame delta; save payloads omit repeated catalogue definitions and safely retain state after a UI node is freed.

All **60 canonical regression cases pass**, zero errors/failures/skips/orphans (`/tmp/tt-year20-canonical-tests.log`). A private copy of the actual day-6531 campaign with 12 opponents falls from roughly 0.87–1.11 seconds to 0.30–0.31 seconds of ordinary daily CPU. The standalone test measures **2.998 days/second headless and 2.887 with the map rendered** at the 3 days/second setting. The map capture was inspected and the owned probe exited. This does not promise a steady 3 days/second or smooth frame rate: synchronous daily work still stalls frames. All 13 civilizations' compared outcomes match apart from ten negligible cohort rounding differences (maximum about 1.4e-14); exact save round-trip passes, with a 62.7 MB save. No actor, turn, population or resource simulation was skipped. See `YEAR20_PERFORMANCE_HANDOFF.md`.

No player/editor was interrupted or relaunched. Release **2026.09.10.1** includes the companion leader-decision integration recorded above. The separate subject-art worktree remains unfinished and is not part of this delivery.

## September 9 — Stone Selection artwork correction

INTEGRATED `786390de07ad031ead4de6185fdd4a7b4d8165fa` by conflict-free fast-forward from canonical Mac `4928607e19e202ab3c978b64c7ce20aff0962980`. Stone Selection now shows people selecting/testing rocks in discovery announcements, research cards, inspector and tree. The old pottery image came from the generic Craft & Industry field assignment; the discovery name and effects were already correct. Other generic illustrations are explicitly labeled FIELD ILLUSTRATION. Hidden subjects retain generic art.

All **29 canonical focused tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-discovery-art-canonical-tests.log`). Native capture-only verification passes Stone Selection and Clay Vessels at 1200 × 900 and 800 × 600, plus research card/tree captures. Artwork, visible labels, exact effects and dismissal controls were inspected; the probe exits. See `DISCOVERY_ART_HANDOFF.md` and `assets/ui/research/PROMPTS.md` for scope and built-in image-generation provenance.

Normal standalone release target **2026.09.09.11** is packaged through `tools/launch_game_macos.py --build-only`; `build.ok` records its integrated source revision. Owned overrides removed. Player PID 74445 remains on 2026.09.09.9, untouched; the updated art requires a normal relaunch. Save schema, simulation effects and human/opponent mechanics are unchanged. This is a specific Stone Selection correction, not individual artwork for every discovery. Landscape iteration remains ACTIVE as recorded below.

## September 9 — landscape iteration 6: climate-driven seasonal cover

INTEGRATED `80c79a2e9ffd940e62d356c8dd83b1869b5624ad` by conflict-free fast-forward from canonical Mac `d07dc6e01b3404ccc70ff40876bdd605ee69c39c`. Ground cover, scrub and woodland now change with the existing climate/calendar temperature. The hemispheres reverse; bare drylands and warm tropical cover retain their appropriate appearance. Material updates leave tree positions, counts, resources and meshes fixed. The HUD now shares food's ambient-temperature model, correcting its separate north-only seasonal calculation. Existing food/profile arithmetic and human/opponent rules are unchanged.

All **64 canonical combined tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-season-canonical-tests.log`). Native capture-only verification passes six actual seeded sites, opposite hemisphere color changes, paused pixel stability, preserved plant identities, exact fog concealment and all four camera distances. Representative seasonal/crown pairs and distance captures were inspected; both probes exit cleanly. Normal isolated headless boot is clean. See `SEASONAL_LANDSCAPE_HANDOFF.md` for exact evidence, performance and remaining limits.

Normal standalone release target **2026.09.09.10** is packaged through the build-only Mac launcher, with the exact integrated revision in `build.ok`. Owned overrides are removed. Player PID 74445 remains on release 2026.09.09.9 and was not interrupted or relaunched. No save schema changes. This delivery adds vegetation dormancy; it does not invent snow, rainfall records or species. Landscape iteration remains ACTIVE: improve natural ground detail, canopy appearance and transitions at real camera distances, preserving physical climate, stable placement, fog and performance.

## September 9 — landscape iteration 5: far-world surface precision

INTEGRATED `bc3b0e248ad401b8408af5eb08b2a036ddffb29e` by conflict-free fast-forward from canonical Mac `149cebf5494e8494dc338c5d42468481a5bff246`. Close ground and water no longer acquire vertical bands from large world coordinates. Pixel filtering uses nearby coordinates; repeating ground/forest textures and fine material noise retain world phase, while water phases are reduced precisely before upload. Actual far-world captures also exposed lost camera yaw near vertical: the camera now derives its orientation directly from the requested angles while retaining its position, distances and clipping planes.

All **59 canonical combined tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-precision-canonical-tests.log`). The camera regression reproduced the old failure before correction. Three native capture-only audits pass analytical filtering and coordinate-shift comparisons, actual far-world drylands/cold barrens/coast, all four camera distances, 48 shoreline checks, GPU bed sampling, distant wave filtering, fog concealment and world-edge clipping. Original and corrected surface captures were inspected; probes exit without errors or camera warnings. Normal headless boot is clean. See `SURFACE_PRECISION_HANDOFF.md` for measurements and limits.

Release target **2026.09.09.9** uses the normal standalone build-only Mac launcher, with the exact packaged revision recorded in `build.ok`. Owned test overrides are removed; no player/editor was interrupted or active at integration. Physical terrain, resources, climate, save schema and shared civilization rules are unchanged. This corrects specific surface/camera errors, not every engine precision limit. Iteration remains ACTIVE: continue natural ground and vegetation variety and seasonal appearance based on actual simulation data.

## September 9 — landscape iteration 4: sampled landforms and continental coasts

INTEGRATED `fe31c00c66ab6bd4271b9f16cd2c1d33afcb00a1` by conflict-free fast-forward from canonical Mac `504be6a2b3c732761ae6ea21bb9278f03ffea485`. Detailed terrain now continues through continental view instead of disappearing above the old 820 km cutoff. Regional/continental meshes sample the actual geography at up to 513 × 513 vertices. Progressive previews, cancellation, complete-mesh installation and a four-entry/600,000-vertex cache bound the work. The previous/global ground stays visible during refinement. Water uses the matching installed bed; terrain stops at the finite planet boundary. Unknown mountains, plains and ocean share one unlit fog veil.

All **54 canonical combined tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-lod-canonical-tests.log`). A physical seed audit improves regional interpolation RMSE from 77.9 m to 11.8 m and reduces incorrect land/water classification from 84 to 37 of 251 coastal samples. Native capture-only checks pass all four actual camera distances, fallback/cancellation, equal hidden pixels and world-edge clipping. Before/after regional and continental captures were inspected; probes exit normally. Normal headless project boot is clean. See `TERRAIN_LOD_HANDOFF.md` for exact sampling, performance and limits.

Release target **2026.09.09.8** uses the normal standalone build-only Mac launcher, whose `build.ok` records the exact packaged revision. Owned overrides are removed; no player/editor was interrupted or active at integration. Save format and all simulation geography, resources and human/opponent rules are unchanged. Full detail still takes seconds to refine behind useful previews, and coastlines remain sampled. Iteration remains ACTIVE: next address close surface precision at extreme world coordinates, then richer natural ground/vegetation and seasonal appearance. This does not claim a finished landscape or all-world visual audit.

## September 9 — landscape iteration 3: physical ground materials

INTEGRATED `e4db83e36587599325c565ebc70b93df76e40089` by conflict-free fast-forward from canonical Mac `150af912814573331020bacb7400bc179dd00598`. The terrain no longer draws an unrelated satellite photograph's mountains over the generated land. Base, regional and close meshes carry actual climate and resource-geology fields; dry earth, damp ground and steep exposed rock use those fields. Woodland/depletion channels remain intact. Fine detail filters with distance, integer hashing avoids distant soil precision artifacts, and coarse normal/hillshade smoothing reduces abrupt lighting facets without changing physical geometry.

All **44 canonical combined tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-ground-canonical-tests.log`). The native capture-only audit passes actual dryland/grassland/woodland/cold-barren sites, controlled geological families, fog concealment and four live camera distances. Eleven images were inspected, including real base/regional meshes; the probe exits. Normal project headless boot is clean. See `GROUND_SURFACE_HANDOFF.md` for sampling data, scope and limitations.

Normal standalone release **2026.09.09.7** is packaged through `tools/launch_game_macos.py --build-only`; its `build.ok` records the exact source revision. Owned overrides removed; no player/editor interrupted and none active at integration. Save schema, physical heights, resources, climate and civilization mechanics are unchanged. The material families are illustrative surface treatments, not revealed ores. Iteration remains ACTIVE: coarse regional/continental landform and coastline quality still need improvement, followed by seasonal cover and richer natural materials. This does not claim the landscape is finished.

## September 9 — landscape iteration 2: real sea level and coastal depth

INTEGRATED `7a16b3e5bd373904676d3caac296b15f08d3de10` by conflict-free fast-forward from canonical Mac `4edac93deb789201384a89b9a91921d7dda8d343`. The ocean no longer renders twelve metres above its physical datum. Coastal colors use the actual regional terrain mesh heights, with muted shallows, shelf and deep water. A bounded local surface and matching far-water cutout follow streamed patches. World-anchored ripples fade before becoming unresolved noise; continental coloring suppresses the moving regional depth window. Fog conceals depth and highlights.

All **35 canonical combined tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-coastal-canonical-tests.log`). Native Compatibility captures pass 48 shoreline samples, dry ground/old-height flooding comparison, three depth colors, four GPU-versus-mesh-ray checks, all four map scales, distant animation filtering, continental patch concealment and unknown-water pixel equality. Controlled top-down/perspective coast and water-scale images were inspected; the capture-only probe exits. The normal project also boots/exits cleanly headlessly. See `COASTAL_WATER_HANDOFF.md` for precise scope and limitations.

Normal standalone release **2026.09.09.6** is packaged through `tools/launch_game_macos.py --build-only`, with its source revision in `build.ok`. Owned test overrides removed. No player/editor was interrupted; no player was active at integration. Save schema, physical terrain, water supply, founding rules, resources and shared civilization mechanics are unchanged. Landscape iteration remains ACTIVE: ground materials, geological/seasonal variety and broader scenic quality are still being improved.

## September 9 — landscape iteration 1: biome-faithful, persistent vegetation

INTEGRATED `1c38347c972ba6a02d1b6be81daf9831fd04d4bc` by conflict-free fast-forward from `a5fff97810f36a209307623085f74186e01f4d7a`, on top of the illustrated research/discovery release. Broad trees now use the surveyed woodland field; close/legacy trees reject water and treeless ground. Scrub follows local precipitation and temperature. Fixed world cells, independent cluster seeds and position-based atlas variants keep plants stable when detail patches move or a nearby parcel is cleared. Vegetation and forest floors honor the same discovery mask and woodland depletion as the map, with weak material references.

All **50 canonical combined landscape and research/popup tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-landscape-canonical-tests.log`). The native capture-only probe checks 803 rendered crowns for unchanged position, shape, tint and variant, and verifies hidden foliage produces the same pixels as no foliage. Four climate render comparisons were inspected; the probe passes and exits. Source also passes 36 terrain/resource/harvest/mesh/river tests and a clean headless normal-scene boot. Save schema, physical resources, climate generation and player/opponent mechanics are unchanged. See `LANDSCAPE_COVER_HANDOFF.md`.

Normal standalone release **2026.09.09.5** is packaged with `tools/launch_game_macos.py --build-only`; `build.ok` records its source revision. Test overrides removed; no user game/editor was interrupted or test scene presented as the player. Landscape iteration remains ACTIVE under the existing task heartbeat, now prioritizing honest ground surfaces, shoreline/river appearance, vegetation variety, seasons and scenic quality. This is the first landscape correction, not a claim that all realism is finished.

## September 9 — illustrated research teams and discovery announcements

INTEGRATED `c2cdb0614a2c0f82af4bf3f650a5a00dea79b9c9` by conflict-free fast-forward from `93cc5f578411c0ed8e9fa5dd70a195adefefbf08`. Inquiry opens painted active research cards with real named supervising leaders, acting/vacant offices, equivalent workforce, evidence progress and bottlenecks. The prerequisite tree and established knowledge remain available, with field/leader/name filters and hidden outcomes withheld. Small-window inspectors use a full-width view and Back control; daily updates preserve live cards and navigation.

New player discoveries from the actual calendar open one illustrated popup with signed effects, benefits/trade-offs, adoption explanation, queued Next, Dismiss all, Escape and outside dismissal. Reading pauses with nested pause ownership and restores prior speed. It does not replay history or announce enemy research. The nonexistent steam prerequisite for Safety Lifts is corrected to the existing Steam Propulsion discovery.

All **86 canonical combined tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-research-canonical-tests.log`). The real HUD/calendar probe passes at 1280×900 and 800×600, including an actual completion opening the paused popup and restoring speed. Nine native capture-only renders were inspected; the probe exited without script errors. See `RESEARCH_VISUAL_HANDOFF.md` and `assets/ui/research/PROMPTS.md` for scope, tests, art provenance and limits. Save schema unchanged. Artwork identifies research fields; it does not invent individual researchers. Test overrides removed; normal release version **2026.09.09.4** is built with the canonical Mac launcher, with source revision in `build.ok`. No user game/editor was interrupted; no player process was active at packaging.

## September 9 — illustrated forces, compact map surveys and local construction materials

INTEGRATED `161f0db` and `0ff1c90` by conflict-free fast-forward from canonical Mac `6d127d8f9b3e6c00d25a8cfe2fa458f3d8213735`. The three service rosters use compact illustrated rows, 15 painted portraits, role insignia, actual readiness meters, filters and expandable details. Automated staff training retains its existing costs/time and gets visual policy cards. The user's corrected survey scope is the revealed resource details on the map: compact material icons, distance, qualitative quality/abundance, access and expandable explanations. Unknown information stays unknown.

Dryland terrain uses its climate hue at every rendering scale; green meadow/lush additions respect climate. Starter works and later household/court/workshop recipes choose feasible bills from each city's delivered stores; earthen homes require clay-shaping knowledge. Completed starter works preserve the paid material family in their converted plots, including the existing earthen building kit. This changes neither climate/resources nor the human/opponent distinction. It does not make clay a substitute for industrial fuel or every advanced structural input.

All **79 canonical combined tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-survey-canonical-tests.log`), including civilization ownership and save continuation. The complete-save fixture now resets player military state as the normal new-world entry point does, preventing earlier UI sample bases from contaminating its save. Source verification also passed 88 settlement/resource/visual regressions and 23 focused material/survey/secondary-city cases. Native capture-only roster and terrain/survey probes passed and exited; actual widgets and shader output were inspected. The integrated normal scene booted and exited headlessly without script or cleanup errors. See `MILITARY_VISUAL_ROSTER_HANDOFF.md` and `RESOURCE_SURVEY_MATERIAL_HANDOFF.md` for limits and exact validation.

Save schema unchanged; older built forms remain recorded. Owned test overrides removed. Normal release version **2026.09.09.3** is packaged through `tools/launch_game_macos.py --build-only`, with exact source revision in its `build.ok`. Player PID 55512 remains the older `6d127d8f9b3e` / 2026.09.09.2 standalone session; it was not interrupted or replaced. A normal restart is required to receive these changes. No test scene is the player game.

## September 9 — distinctive civilizations, visible envoy journeys and local AI setup

INTEGRATED `fae9761` (source `6f1500b` plus validation corrections) by conflict-free fast-forward into canonical Mac main from `a31088e`. New worlds receive unique civilization and city names and distinct flags; map cards show the reported controlling civilization. Registering a player home no longer relocates three rivals nearby. Envoy dispatch retains the destination, schedule and map focus; returned outcomes open in a paused leader conversation. Nested settings preserve the prior speed, and speed shortcuts cannot bypass a conversation pause. The connection panel accepts a session-only API key locally and distinguishes missing credentials from HTTP failures. Foreign leaders share civic personality axes and have priorities that affect strategy and negotiations.

All **69 canonical focused tests pass**, zero errors/failures/skips/orphans, exit 0 (`/tmp/tt-civ-canonical-tests.log`). Across the source checkout, **138 named tests are verified** including the full century and billion-population cases and targeted reruns after correcting an obsolete instant-training fixture. The foreign-diplomacy integration probe and local mock HTTP contract probe pass. Flags were inspected at map sizes; dialogs received headless layout checks. No live API connection or native player-window visual audit is claimed. Existing names/locations remain on load; new naming applies to new worlds. The canonical test override was removed.

**HELD:** `1e918e3` in `/Users/seanpurtill/Documents/Codex/tt-civ-identities`, branch `codex/distinct-civilization-identities`, contains incomplete shared demographics and real-city records. It is excluded. Full human/AI rule parity, real opponent founding, shared city economies and multiplayer readiness are unfinished. No artificial population slowdown is delivered. The existing iteration heartbeat now prioritizes completing those shared systems; networking is explicitly outside scope. See `CIVILIZATION_PARITY_AUDIT.md` and `CIV_IDENTITY_DIPLOMACY_HANDOFF.md`.

No player or editor was stopped or launched. The earlier standalone player had already exited when checked. The release is being prepared for the next user-requested launch.

## September 8 — normal standalone release launched

INTEGRATED `fc7b43c` by conflict-free fast-forward from `d9e0f44`. At the user's explicit request, closed the old editor/debug session through Godot's normal Stop & Quit dialog and launched a fresh standalone release with `python3 tools/launch_game_macos.py` from the canonical Mac checkout. No editor, remote debugger or embedded-window arguments are present.

The canonical export succeeds and its ad-hoc signature verifies. The official executable identifies itself as a release export template. Player **PID 9776** runs `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow/artifacts/macos-release/fc7b43c89cfa/Tomorrow and Tomorrow.app/Contents/MacOS/Tomorrow and Tomorrow`; the absolute app path and `build.ok` bind it to this canonical build. Its title is **Tomorrow and Tomorrow · 2026.09.08.1**, without DEBUG. Native inspection shows the real map, **Year 1 / Day 1**, population **120**, and the founding convoy beside a river. Editor PID 2812 and debug player 6076 have exited. The new release remains running.

The launcher starts fresh by default and refuses another active player; this guard was exercised against PID 9776 without opening a duplicate. The packaged main scene also initialized in an isolated headless worktree check; the immediate three-frame shutdown's two-object/one-resource cleanup warning is recorded in MACOS_RELEASE_LAUNCH_HANDOFF.md. Native startup is verified visually; the release log files were still buffered/empty during inspection, so no detailed live-log pass is claimed. No simulation or save-schema changes. Project settings add the ARM-required texture import format and update the visible version; renderer and main scene are retained. See MAC_SETUP.md for the ordinary release launcher.

## September 8 — issued objectives are distinct from military drafts

INTEGRATED `eaca48a` by conflict-free fast-forward from `d312ad0`. Army, Fleet and Air Force command panels show a colored Now line for the actual issued objective and zone/reported city, while the mission picker explicitly labels the Next objective. Current information refreshes without replacing the player's draft. Headquarters identify shared orders, mixed orders and subordinate exceptions. Edit loads the current mission, map zone, reported city and brief into the draft without issuing it or changing forces; unavailable/cancelled orders and transport do not load misleading defaults.

All **53 canonical tests pass**, zero errors/failures/skips/orphans across command hierarchy, main-map services and dismissal (`/tmp/tt-current-orders-canonical.log`). Six new regressions cover read-only editing, inheritance/overrides/mixed headquarters, real separate-service order updates, reported-city targeting and hidden-name isolation, unavailable/cancelled orders, and transport. Extended 1280×720 and 1024×640 layout checks cover the new strip and Edit button with long text while preserving accessible primary actions. No simulation, camera or save changes; see CURRENT_COMMAND_ORDERS_HANDOFF.md. Owned test overrides removed.

Editor PID 2812 and player PID 6076 remain uninterrupted in the canonical checkout. This pass does not claim native visual verification or receipt by the running player. Recreated panels after effective reload, or the next normal project launch, receive the UI. The summary describes issued objectives; it does not imply operational readiness or successful execution.

## September 8 — cancellation respects the selected military command

INTEGRATED `49ef49c` by conflict-free fast-forward from `63e62ab` into canonical Mac main. Cancel orders now retains the selected subdivision path, detaches only that available branch and leaves sibling objectives executing. Changed-strength or busy subdivisions are refused without cancelling their parents; unassigned subdivisions stay read-only. Whole naval/air stand-down validates all subordinates before committing, reports convoy/route refusals and distinguishes port, airbase/carrier and land behavior. Already committed land battles continue resolving.

All **97 canonical tests pass**, zero errors/failures/skips/orphans across six suites (`/tmp/tt-scoped-cancel-canonical.log`). Seven new regressions cover the actual cancel button, exact selection, conserved assets and saved overrides, independent sibling execution, refusal/no-op cases, atomic naval/air cancellation and continued battle resolution. Existing command, service, carrier, transport, siege and layout/dismissal checks pass. No save schema changes or shared hotspot conflicts; see SCOPED_COMMAND_CANCELLATION_HANDOFF.md. Owned test overrides removed.

Player PID 6076 and editor PID 2812 remain running from the canonical checkout; neither was interrupted or relaunched. Native visual verification and receipt by the already-running game are not claimed. The next normal project launch loads the integrated scripts. Virtual subdivisions still require an available assembled force before they can detach.

## September 8 — live founding-overlay correction

INTEGRATED `bd247db` by conflict-free fast-forward from `465390d`. Native inspection of player PID 6076 found the full-size map overlay was incorrectly captured by the global modal fitting contract, collapsing the card. The overlay now opts into its own existing responsive-layout convention. The regression invokes that actual shared contract, verifies the card remains unwrapped and visible, and still checks small-window bounds.

All **16 focused canonical tests pass**, zero errors/failures/orphans (`/tmp/tt-founding-live-layout-canonical.log`). The preceding feature integration passed 107 canonical tests. Owned test overrides are removed. No simulation/save changes in this correction; see FOUNDING_SITE_LIVE_LAYOUT_HANDOFF.md.

Launch verification: canonical editor Run Project launched player **6076** from **465390d**, using the absolute canonical path and `res://local_terrain.tscn`, parent editor **2812**. Native inspection saw the real main map and new water readout, source line and site markers. Startup log has no script errors. The release display remains 2026.09.07.2. This new world used seed 1788457137 and was subsequently running at Year 2; no settlement was committed by the agent.

The corrected card's final native appearance is **not verified**. The desktop-control tool repeatedly focused the editor instead of the embedded game, then returned `windowNotFoundAtPosition` on fresh game-view coordinates. The game window remains running; it was not forcibly stopped or saved over another campaign. Reopening the card after effective script synchronization, or a normal project restart, is required for the final UI correction. The active process command line verifies its checkout, not receipt of this later hotfix.

## September 8 — settlement water guidance and neighbor resentment

INTEGRATED `e434bc8` by conflict-free fast-forward from `bd1992c` into the canonical Mac checkout. Review Founding Site now previews actual known water, carrying distance and household coverage before the first commitment. First/later founding rechecks exact dry ground and confirmed water within the existing 6 km collection limit. The main-map card marks nearby suitable sites and their water; clicking a numbered site uses the agreed 50,000-foot view. Ground inspection and later convoy confirmation carry the same water and neighbor warnings.

Returned foreign-city reports predict stronger resentment at shorter distances. When neighbors observe or learn of the founded city, a quadratic penalty inside 30 km changes real opinion and border tension. Each player city creates at most one current grievance per affected civilization; repeated reports and days do not repeatedly charge it. Nearby cities use their established 12 km sight radius; distant cities wait for reports. Optional grievance dictionaries persist in the existing relations save data. Existing observed cities may acquire their first grievance on update. No hidden cities are exposed by preview.

All **107 canonical tests pass**, zero errors/failures/skips/orphans across seven suites (`/tmp/tt-founding-water-canonical.log`); canonical headless editor import passes (`/tmp/tt-founding-water-canonical-import.log`). Includes real founding, later-city checks, existing city management and intelligence, exact water-limit boundaries, known-only suggestions, 1024×640 controls and warnings, distance ordering, observation delays, multi-city penalties and serialized deduplication. Owned test overrides removed. No player/editor was stopped or campaign save overwritten. See FOUNDING_SITE_GUIDANCE_HANDOFF.md for scope, limits and logs.

At integration, canonical editor PID 2812 is open and the prior player has already exited. Native inspection and the updated player launch are being verified separately; passing tests alone do not establish live receipt.

## September 8 — latest integrated build running after reopening

At the user's launch request, opened the canonical project in Godot. Editor PID **2812** and new player PID **3034** run `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`; the player command line names `res://local_terrain.tscn` and its canonical editor parent. The checkout at launch is **d9aeec5**, including command-panel layout `7a1310c` and exact command-selection refresh `41a97ff` (40 canonical tests passed before launch).

Native inspection shows the actual main map in a new world, Year 1/Day 1, population 120, with the founding convoy and ground inspection visible. The startup log has no script errors and reports seed 1788281429. The displayed release string remains 2026.09.07.2. The earlier embedded-view capture problem is no longer present in this reopened session. No further restart or save load was performed after observing the active game. A temporary editor resume argument was removed; it was not present in this player's command line. The proposed current-order summary follow-up has no source changes and is not part of this build.

## September 8 — exact military selection during refresh

INTEGRATED `41a97ff` by conflict-free fast-forward from `f0b0fe4`. Hierarchy clicks now use the displayed strength and order. Resized detachments can receive orders after the required reselection instead of repeatedly failing a stale-strength check. Vanished subdivisions clear the active order target. Structural refreshes retain the exact active subdivision and other selected commands, preventing an unnoticed switch from a small detachment to its whole parent force. Ordinary count updates preserve existing rows and expansion.

All **40 canonical tests pass**, zero errors/failures/orphans (`/tmp/tt-command-refresh-canonical.log`). New cases cover strength changes, reselection and real asset conservation, disappeared/reappearing teams, placeholder input, and exact subdivision/multi-selection/draft retention in all three services. Native expansion and existing layout/map/command regressions pass. No simulation/save schema changes or shared-file conflicts. See COMMAND_REFRESH_HANDOFF.md. Temporary test overrides removed.

No game/editor UI actions or restart in this pass; player PID 95563 and editor PID 93974 remain running. Native visual verification and receipt by already-open controls are not claimed. Recreated controls after script reload or the next normal launch receive this code.

## September 8 — compact military command panels

INTEGRATED `7a1310c` by conflict-free fast-forward from `241e532`. Army, Fleet and Air Force command panels keep Give objective and Cancel orders outside the scrolling form, give the hierarchy more room, put objective selection first and collapse optional names/briefs. Drawing-only actions appear during a draft. Personnel/craft headers fit; single-line headings and scrollable reports keep the panel within the minimum logical canvas.

All **37 canonical tests pass**, zero errors/failures/orphans (`/tmp/tt-command-panel-canonical.log`). Layout checks cover all three services at explicit logical sizes of 1280×720 and 1024×640 with expanded details, long feedback and scrolling; existing hierarchy, native expansion and map-dismissal checks pass. No simulation/save changes or shared-file conflicts. Temporary test overrides removed. See COMMAND_PANEL_LAYOUT_HANDOFF.md.

The existing player PID 95563 remains running; this integration does not claim that its already-open panel has rebuilt. No player/editor restart was performed. Native inspection of the new layout is pending.

## September 8 — command tree mouse expansion and live inspection

INTEGRATED `388ae88` by fast-forward from `17eb240`. Native mouse expansion now defers row creation until Godot releases its Tree selection lock. Deferred work uses an instance ID and ignores rows removed by a refresh. This fixes the runtime pause found while showing the actual Army Command UI; the earlier direct-method/headless checks did not cover that native event path.

All **35 canonical tests pass**, zero errors/failures/orphans (`/tmp/tt-command-tree-canonical.log`), including a native viewport mouse-event regression and a pending-expansion/rebuild case. No simulation/save changes. Test overrides removed. See COMMAND_TREE_CLICK_HANDOFF.md.

Live verification: canonical editor Run Project launched player **PID 95563** from code commit `388ae88`; its command line contains `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow` and `res://local_terrain.tscn`. Loaded the existing Seanston save at day 29337/population 1047, opened Military → Command on map, expanded the 10-person squad and selected it without the previous error. The game remains paused in Army Command. No objective was issued or saved campaign overwritten.

## September 8 — military hierarchy and autonomous battle zones

INTEGRATED `d220fa1` by conflict-free fast-forward from `41d410b` into the canonical Mac checkout. Military → Army Command, or Forces → Command on map, now opens a real-force command tree on the main terrain. Select an Army down to a Team, or a separate naval/air command, and assign its subtree a drawn zone and objective. Land commanders execute movement, observed contact, flanking, city assaults, siege assaults and occupation detachments. Neutral borders halt unauthorized advances; hostile contact creates dynamic front ribbons. Separate commander battles progress concurrently without duplicating participants or forcing a battle/aftermath screen.

All **163 canonical tests pass**, zero errors/failures/orphans across 12 suites (`/tmp/tt-command-delivery-canonical.log`); the canonical headless editor import also passes (`/tmp/tt-command-canonical-import.log`). Tests include real personnel/equipment conservation, simultaneous battles and save/load, parent/child orders, automatic city outcomes, terrain routing, border/contact behavior, separate service orders, stable hierarchy refresh and 1280×720 panel bounds. New optional hierarchy/battle data is backward compatible with older saves. Temporary test overrides removed; no player/editor interruption or native visual verification. The running game needs a normal project restart to load this structural change.

Limits: local aggregate fronts, not full HOI4 province/supply simulation; the existing siege system still allows one active siege and gates new land engagements during it. Occupation detachments remain in their existing ledger. No future mech catalog is added in this change. See [COMMAND_HIERARCHY_HANDOFF.md](COMMAND_HIERARCHY_HANDOFF.md) for scope, accounting and exact validation.

## September 8 — service-wide training indicators

Integrated `a3f1300`; all 79 relevant canonical tests pass. Navy/Air training now reports the entire service with four visual counts, actual crew attendance and grouped pause reasons. Stale activity clears after base/equipment failures and proficiency-target completion. No save migration, rate changes or player restart. See SERVICE_TRAINING_OVERVIEW_HANDOFF.md.

## September 8 — scout route planning

Integrated `77049fc`; all 60 focused canonical checks pass. Automatic route selection validates before departure, searches all compass sectors and allows local surveys. Cards show actual planned outward distance with return/survey time included. No live discoveries, unearned safety rating or quoted-route reroll. The existing peace-incident fixture failure is documented separately in SCOUT_ROUTE_PLANNING_HANDOFF.md. Saves and ongoing missions remain compatible; no player restart or graphical probe.

## September 8 — automatic crew training recovery

Integrated `1683ba1`; all 74 relevant canonical tests pass. Navy/Air repairs finish before training resumes, training suspension permits essential repairs, and repeated daily checks preserve attendance. Rival messages no longer overwrite player staff reports; roster activity exposes actual repair shortages and travel. Existing saves remain compatible. No player restart or graphical probe. See SERVICE_TRAINING_RECOVERY_HANDOFF.md.

## September 7 — joint operations and modern architecture integrated

INTEGRATED source `f4a7d78` / `f466f20` from `codex/fifty-units` through merge `f996fa6`; integration fixes `2b2e3ea` and `f66bfcb`. This supersedes the held `33ab016` milestone. Canonical Mac checkout is `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`.

The player build now contains 50 neutral land archetypes, 21 naval types and 16 air types; researched production, city-funded bases, aggregate crews, carriers, transport, geography-checked sea routes, player-drawn operating polygons, mission effects, rival industrial/combat operations, fleet screening and submarine detection. Detailed settlement architecture adds 24 masonry/industrial/modern building families through the shared saved-parcel placement system, named construction research and paid upgrades. Historic districts retain their built form.

Combined canonical validation: **139 tests passed**, zero errors/failures/orphans, across 12 suites. After the final keyboard/map/manpower integration refinements, all **30 joint campaign and city-intelligence tests passed** again. The documented baseline raid-intelligence fixture now provides viable military strength explicitly, preserving all hidden/stale-intelligence assertions. Actual current-save compatibility restored day 25512, population 777, seed 1792946605 in isolated test userdata.

Canonical editor Run Project launched version **2026.09.07.1**, player **PID 60507**, from code commit `f66bfcb`. Process command line explicitly contains the canonical absolute project path, `res://local_terrain.tscn` and `--resume-saved`. Startup log confirms the saved world and contains no script errors. Previous player sessions were saved and quit through their own UI. No worker/test scene was shown as the player game. Temporary test-userdata and editor-resume settings were removed.

Live checks: city flags/colors and Military entry cards visible; **Shift+F6** opens Naval & Air Command; **Escape** returns directly to the map. The operations screen shows the home city, foreign names/estimated populations, separate labels, the researched War Canoes choice, base/production controls and polygon-drawing controls. The final player remains paused on that screen. Polygon drawing and mission execution have headless behavioral checks; native mouse drawing was not verified because embedded-window coordinate automation is unreliable. Modern mesh/placement behavior is tested; the current early-era campaign was not artificially advanced to modern architecture for a visual claim.

Limits: HOI4 numerical/combat-system parity is **not complete**. Combat remains aggregate and daily, with simplified fleet screening, detection and air performance. Rival overseas invasions/supply convoys, full doctrine and component-design simulation remain outside this integrated iteration. See `docs/FIFTY_UNITS_HANDOFF.md` for exact behavior and scope. Prior production clarity `da9f917`, flags `a0ff5d5`, staffing `fab7843`, and foreign-label/intel fixes are included in this relaunched player.

## September 7 — army staffing clarity

INTEGRATED `fab7843` by conflict-free fast-forward from `1589e37`. Recruit & Train shows available recruits, training places and work allocation separately. Per-city watch/training priority actions replace the vague allocation detour and retain GovernmentPeopleSystem authority and occupation guards. Eleven targeted and existing recruitment tests pass; no save or calculation changes. See ARMY_STAFFING_HANDOFF.md. The city flag update `a0ff5d5` is included in this base. Player PID 47271 has not been restarted; receipt by the live session is not claimed.

## September 7 — city civilization flags

INTEGRATED `a0ff5d5` by conflict-free fast-forward into canonical Mac main from `86f2971`. City flags, name colors and pins share reported civilization identity at all four camera distances; owned labels use the founding banner. Three isolated targeted checks pass, including stable refresh sizing and changes of reported control. No save schema changes. See CITY_FLAGS_HANDOFF.md. Player PID 47271 is still running; no restart or receipt of these changes by that process is claimed.

# Compact speed dropdown integrated — September 7, 2026

INTEGRATED 45b24d1 in canonical Mac main by conflict-free fast-forward from
ad943db. Canonical HUD file matches the tested worker exactly; tracked tree clean.
Five persistent speed buttons become one dropdown plus pause/resume. Actual rates
and keyboard shortcuts are unchanged. Repeated speed text is removed; checked
representative width is 380 px. Isolated clean import and all five selection,
pause/resume and width checks passed. See SPEED_DROPDOWN_HANDOFF.md.

Player PID 42977 remains running and was not restarted. The last native screenshot
still shows the previous bar; live script application is not claimed. The new
control appears on HUD recreation/next launch, or supported live script reload.
No save changes or shared simulation edits; no remote push.

---

# City parity and four-distance controls integrated — September 7, 2026

INTEGRATED in canonical Mac main:
/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow
Source 3768cbe, fast-forwarded from 06c236c with no conflicts.

Added cities use recorded settlement design and local housing/construction,
resources, health, economy and demographic updates. HUD keeps overall and selected
city population together. City map labels use names and known/estimated population.
Four recovered distances: 10,000 ft, 50,000 ft, Region, Continent; discrete scroll
steps, slower fine adjustment and bounded transitions. Vacant intact buildings
remain visible; saved sites prevent maintenance redraws moving existing homes.

Canonical clean headless import and 91/91 targeted cases pass, zero errors,
failures, skips or orphans. Logs: /tmp/city-parity-canonical-import.log and
/tmp/city-parity-canonical-tests.log. Worktree real-terrain navigation probe passes;
shutdown resource warning documented in CITY_PARITY_DISTANCE_HANDOFF.md.

Canonical test override removed. All 118 pre-existing untracked files retain their
hashes. New optional dictionary data uses existing save serialization; round-trip
verified. No schema bump or arbitrary reset. The separate READY affordable-infill
69d9db9 remains outside this integration. No remote push.

Scope limits: existing national military/fortification authority remains; distant
baked imagery and large-scale performance profiling are not delivered. Actual
completed Lean-to work still converts household forms on monthly synchronization.
Full details and recovered design provenance: CITY_PARITY_DISTANCE_HANDOFF.md.
Canonical player launched through editor Run Project (Command-B), PID 42977.
Verified command includes --path /Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow
and --scene res://local_terrain.tscn. Native screenshot confirms the normal opening
direction screen, day 0; no direction chosen or campaign advanced. Player startup
log contains no script errors. This verifies launch, not visual signoff of every city.

---

# Consolidated deaths and investigation choices — September 7, 2026

INTEGRATED `28a06ac` in canonical Mac main by fast-forward from f0416ef.
Population views summarize deaths by cause with separate paged dated details.
Scout dispatch groups destinations by category and repeated accounts by people,
retaining each exact target and visible evidence. Original records, counts, mission
behavior and save format are unchanged. See CONSOLIDATED_LISTS_HANDOFF.md.

Canonical clean headless import and 15/15 focused list/rumor tests passed with
zero errors, failures, skips or orphans. Logs: /tmp/consolidated-canonical-import.log
and /tmp/consolidated-canonical-tests.log. The broader far-order city-marching case
failed the same three assertions on unchanged f0416ef; no military fix is included.
The private test application override was removed. Player PID 36402 and editor
35944 remain running; restart normally to load this update. No remote push.

---

# Citizen production integrated — September 7, 2026

INTEGRATED source `3dbca50` in canonical Mac main, fast-forwarded from `937cd65`.
The worker was rebased without conflicts to preserve the concurrently integrated
foreign-settlement refresh and its launch record. Original development base was
`1e57003`; no foreign-refresh changes were overwritten.

Military / Supply now defaults to persistent stockpile or continuous production.
Citizen condition, effective Crafting workers, logistics and recorded workplace
condition determine output. The adjustable military crafting share also governs
legacy batch orders and leaves the remaining share to existing civilian systems.
Shortages pause, stock targets replenish after issue, priorities divide capacity,
and retooling carries an efficiency/WIP cost. Finished goods use existing stocks,
training and field delivery. Full behavior and limits: CITIZEN_PRODUCTION_HANDOFF.md.

Canonical clean headless import and six-suite 62/62 regression passed, zero errors,
failures, skips or orphans. Includes 14 new persistent-production and dock-layout
checks. Logs: /tmp/production-canonical-import.log and
/tmp/production-canonical-tests.log. Test userdata was isolated by a temporary
application override with Dummy audio; that override was removed after validation.
New test UID is included in this integration record; unrelated files are retained.

The canonical player PID 36402 was launched by the foreign-refresh task while this
work was integrating. It and editor PID 35944 were preserved. The running player
loaded the prior scripts and needs a normal restart to use production changes.
No new player/test window was launched by this delivery. No remote push.

---

# Foreign settlement refresh integrated — September 7, 2026

INTEGRATED source 0bb8659068e61cb4f4b3df1b010ed310568160ae by conflict-free
fast-forward from 1e57003 in canonical Mac main:
/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow.
The integration-record commit contains this entry.

Foreign settlement visuals now share the authored town house assets, arranged
around courts with narrow feathered paths. Primitive houses and yard mats are
removed. Foreign architecture remains representative because city reports lack
construction records. The city sidebar opens on single-column estimates, with
separately scrolling Report, Scouting and Military tabs. No simulation/save schema
or military-order behavior changes. Source scope and limits are documented in
FOREIGN_SETTLEMENT_REFRESH_HANDOFF.md.

Canonical Godot 4.7.2 headless import passed without errors; the dedicated foreign
refresh probe passed with zero failures at all three viewport sizes. Combined
organic-town and city-intelligence regression: 22/23 passed, zero errors, skipped
cases or orphans. The sole failure is the previously reproduced base-code raid
expectation at test_city_intelligence.gd:93 (one expected, zero received).
Logs: /tmp/foreign-integrated-import.log, /tmp/foreign-integrated-probe.log,
/tmp/foreign-integrated-tests.log. All pre-existing untracked files retain their
hashes. The temporary isolated test configuration was removed.

No Godot player/editor was running before integration. User authorized integration
and loading the game. Canonical editor Run Project (Command-B on this Mac) launched
PID 36402 at gameplay/integration commit 63ef4fd, using the explicit canonical
absolute path and res://local_terrain.tscn. Startup log confirms the new-world
opening at day zero and no script errors. No save was overwritten or live session
interrupted. Graphical sign-off of the foreign view remains pending. No remote push.

---

# Settlement neighborhoods and routine raids — September 7, 2026

INTEGRATED in canonical Mac main by conflict-free fast-forward from 8536c15:
settlement neighborhoods d6bc405, routine raid correction 4ef88ea.
New household courts, actual-footprint shelter density, reserved central hearth,
feathered doorway paths and human-scale service objects replace early parcel mats,
old thick paths and oversized central props. New founding claims cluster more
closely. Existing records are not migrated; later unsupported architecture remains.

Rivals no longer invent three-person raiding parties or knowingly raid overwhelming
observed defenses. Failed raids delay later attempts. Small, outmatched home raids
use the real calendar/combat simulation without forced battle screens or pauses.
Real aftermath policy decisions remain. See SETTLEMENT_NEIGHBORHOODS_HANDOFF.md
and RAID_ROUTINE_HANDOFF.md for scope, save compatibility and limitations.

Canonical clean headless import and 174/174 selected checks passed, zero errors,
failures, skips or orphans. Seven suites: early visual 14, organic town 9,
settlement architecture 83, settlement model 43, raid policy 4, battle injuries 9,
army front visual 12. Evidence /tmp/neighborhood-canonical-import.log and
/tmp/neighborhood-canonical-tests.log. A separate broader worker run hit the
previously documented siege-withdrawal test failure; that issue remains separate.
The test override was removed. Three new script UID files are tracked with this
record; pre-existing unrelated untracked files are retained. No live player was
running at launch preparation. User requested a fresh game after completion;
canonical fresh launch is the next step. No remote push.

---

# Early primitive removal — September 7, 2026

INTEGRATED source `4f73017` as canonical `06862bc`, without conflicts.
Removed the duplicate central Lean-to Shelters tent ring and its unused primitive
mesh helper. Supported early plot forms never fall back to legacy roof/wall
massing, including when no footprint fits. Compact assets retry placement using
their authored envelope, retaining road, parcel, obstacle and land checks.
No-fit parcels can remain visually empty; construction no longer displays legacy
roof massing. Unsupported later forms and communal/service features remain.
No simulation or save-format changes. Local terrain is the shared-file hotspot.
Worker and isolated canonical runs each passed all 104 cases (12 early assets,
9 organic town, 83 settlement architecture), zero errors/failures/orphans.
Logs: `/tmp/early-removal-tests.log`, `/tmp/early-removal-canonical-tests.log`.
The temporary canonical test override was removed. User explicitly requested
that the running test campaign be discarded and a fresh game relaunched, replacing
the earlier resume-only instruction. Canonical fresh launch follows verification.

---

# Early settlement assets integrated — September 7, 2026

INTEGRATED in canonical Mac `main` at
`/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`.
Previous canonical HEAD: `4f68230a3c9c94064a91b3c2909ae806411f2297`.
Source: `a59910960ca453516d13432ab0df9521f6885615`.
Reviewed correction: `5c11d38faf8e716a5f9666f8bf50c9dc42fd9a7b`.
Both were integrated by conflict-free fast-forwards. The commit containing this
entry records final canonical verification; prior organic-town and military-front
sources remain ancestors.

Eight active assets now depict recorded carried shelters, rooted lean-tos,
round/earthen/rubble households, raised stores and covered workshops. They join
the earlier timber town kit. Existing resource/research recipes and completed
work supply the recorded built form; population and calendar do not repaint
buildings. Later/unknown forms are explicitly excluded from the early adapter,
including its shared-solver fallback. Identity meshes preserve imported LOD and
shadow resources. No new simulation/save authority or migration was introduced.

Three authored cultural/political studies remain INACTIVE: crafted household,
open common hall and enclosed authority hall. They are not unlocked in play.
Construction-era cultural/patronage records and appropriate public-parcel
placement are still required; current cultural or political shifts must not
instantly replace inherited architecture. See `EARLY_SETTLEMENT_PROGRESSION.md`.

Canonical Godot 4.7.2 clean headless import passed (exit 0, no script/import errors).
Combined **156/156 passed**, zero errors/failures/skips/orphans: early assets 9,
organic town 9, settlement architecture 83, settlement model 43, military fronts 12.
Evidence: `/tmp/early-canonical-final-import.log`,
`/tmp/early-canonical-final-tests.log` (canonical `reports/report_4/`).

Tests used a newly created isolated `Early_Canonical_a599109_Test` application
name with Dummy audio. That override was removed afterward; none was copied from
the worktree. All 118 pre-existing untracked files retain their exact set and
SHA-256 hashes; all three original save/settings files were unchanged after tests.
See `/tmp/early-canonical-preservation-result.txt`. No unrelated files were staged
or removed. Integration records are the only additional tracked edits.

The user explicitly requested integration and launch. No game/editor was running
before integration. Normal canonical saved-game resume is the next launch step;
no fresh-world/reset/showcase mutation is authorized or required. Offline Blender
asset plates are not game screenshots or FPS verification. Earlier schematic
military limits and the pre-existing siege-withdrawal issue remain unchanged.
No remote push. Further cultural gameplay and later architectural eras are not
claimed complete by this delivery.

---

# Military front integration — September 7, 2026

INTEGRATED in canonical Mac source; graphical review remains pending.
Canonical checkout: `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`, `main`.
Previous HEAD: `577f8aa5d17310674b9d75454c2f584317c6c7aa`.
Reviewed source: `8ea1a7c73dab231bb46c1b187fcf6511c85f78a2`.
Reviewed correction and integrated gameplay HEAD: `45ce52f5605ad234a4755e84e7dd1baa4794fd0c`.
Both commits entered by a normal fast-forward with no conflicts. The commit
containing this entry records the completed canonical verification.

Bounded physical army fronts now replace soldier/mounted-general actors in the
field-army map, dated foreign sightings, eligible occupation garrisons, home
invasion/field battle observation and replay, general campaign map/replay, and
active siege city view. Metre geometry scales by .001 on kilometre terrain;
separate informational glyphs retain distant readability. Real active counts,
equipment and recorded losses determine area; recorded captives are excluded from
combat footprints without becoming casualties. No new combat, fire, control,
prisoner or save authority was added. Legacy direct-cohort controls cannot issue
orders; strategic conversation remains in GeneralCampaignScreen.

The reviewed correction includes occupation fronts in the actual terrain advance
hook, honors pause and inherited visibility, and invalidates siege geometry when
termination alone changes. **Deployment is schematic** where current battle
records lack cohort coordinates and maneuver topology. Optional renderer spatial
inputs do not constitute implemented encirclement or an independent combat solver.
Occupation ground is withheld before live communications when no dated strength
report exists. Full scope and limits: `MILITARY_FRONT_GRAPHICS_HANDOFF.md`.

Canonical Godot 4.7.2 validation, all headless with explicit canonical paths:

- Clean editor import: exit 0, no script/import errors.
- Combined front (12), general campaign (15), battle injury (9), organic town (9)
  and military development (16): **61 passed; zero errors, failures, skips or
  orphans; exit 0**.
- Actual invasion UI/replay probe: **PASS**, exit 0. Verifies zero soldier/general
  actors, responsive observation controls, one resolution, unchanged military
  export/calendar on replay, and pause.

Evidence: `/tmp/military-canonical-import.log`, `/tmp/military-canonical-tests.log`,
`/tmp/military-canonical-ui.log`, and `/tmp/military-canonical-preservation-result.txt`.
The existing siege-withdrawal failure in `test_siege_progression.gd:145` remains
unresolved: expected moving, received stationed. Worker verification reproduced
it on untouched `577f8aa` (8/9 passed). It was not concealed by graphics changes
or counted among the 61 passing canonical cases.

Organic town source `4251a3d98d6ca16af58fc2b102ecb6ecab7f2810` and integration
record `577f8aa` remain ancestors. The earlier 135-case town integration is retained;
its nine organic-town visual cases pass again alongside military on canonical main.

Temporary test configuration used the isolated
`TomorrowAndTomorrow_Military_Canonical_45ce52f_Test` user directory and Dummy audio.
No worktree override was copied. The new override and only the newly generated
front-test UID were removed after checks. All **117 pre-existing untracked files**
and all **three existing save/settings files** retain their SHA-256 hashes; the
original untracked set is exact. No unrelated file was staged, removed or replaced.
The integration-record commit changes only this document and
`FEATURE_RECONCILIATION.md`; tracked source is otherwise clean.

No Godot process was present before or after integration. No player/editor was
interrupted, no graphical test/demo or canonical game was launched, no restart or
push occurred. This verifies source integration, not rendered appearance, FPS or
that a player session has loaded these scripts. **Graphical review is pending.**
Work stops after this integration; no additional phase is started.

---

# Organic town integration — September 7, 2026

INTEGRATED in canonical Mac source, with graphical sign-off pending.
Canonical checkout: `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`, `main`.
Previous HEAD: `1b9e121f481d1382eb1ecce9e7dde17b66b9e754`.
Reviewed worker/source commit and integrated gameplay commit:
`4251a3d98d6ca16af58fc2b102ecb6ecab7f2810` (normal fast-forward, no conflicts).
The integration-record commit is the commit containing this entry.

Compatible inherited single-storey timber/thatch plots now use metre-scale modular
homes along saved lanes, with small garden beds in clear leftover household ground.
Four 24 m² variants, a 12 m² small-parcel derivative and a 120 m² market hall share
bounded batches (512 buildings maximum). No-fit parcels retain existing roofs;
portable camps and unsupported traditions remain under their existing renderer.
The early primary-settlement slice replaces the legacy stage mass/density overlay
through 5,000 population and 128 recorded plots. Authoritative defenses and the
computed settlement extent remain. Houses use uniform scale 0.001, saved plot/route
identities and the same source geometry across camera distances. Inherited kit
houses persist across later population growth; no new population/economy/save
owner was added. Full scope and worker evidence: `ORGANIC_TOWN_HANDOFF.md`.

Canonical Godot 4.7.2 headless import: exit 0, no script/import errors. Combined
`test_organic_town_visual.gd`, `test_settlement_visual_architecture.gd` and
`test_settlement_model.gd`: **135 cases passed; zero errors, failures, skips or
orphans; exit 0**. This reruns the complete reviewed delivery on integrated main.
Checks cover asset dimensions/colors, supplied scale/transforms, camera/population
stability, supported history/materials, road/water/plot clearance, no-fit fallback,
condition/construction/reoccupation, preserved extent/defenses and bounded counts.
Local evidence: `/tmp/organic-canonical-import.log`,
`/tmp/organic-canonical-tests.log`, and canonical `reports/report_1/`.

A newly created temporary test override used isolated
`TomorrowAndTomorrow_OrganicTown_Canonical_Test` user data and Dummy audio. It was
removed after the run; no worktree override was copied, and no pre-existing
canonical override existed. All 117 original untracked files and all three existing
save/settings files retained their SHA-256 hashes. No player save was loaded or
written, no runtime preference changed, and no unrelated sidecar was staged or
removed. Tests exited; no Godot process was present before or after this integration.

**No graphical in-engine sign-off or FPS claim.** No second graphical game/test
window, canonical game launch, live-session interruption or remote push occurred.
The wider mature/continent land-cover transition, foreign towns, later traditions
and slope-specific foundations remain outside this slice. Headless supplied
transforms are not rendered-pixel verification. See the handoff's detailed limits.
At this earlier town checkpoint, military work had not started; the reviewed military integration is recorded above.

---

# Final Mac follow-up integration — September 6, 2026

Canonical Mac `main` integrates `60c95ee61e429ce350a1a5be530c794a185d6dfb`
(training/action feedback and ammunition gate consistency), followed by
`eb39198a83abb0d9ae3db0bb95109ab3544bf8db` (obsolete toolbar layer buttons),
both based on the earlier Mac checkpoint `515f191`.

Feedback wrapping now fits 520×67 in the canonical fixture. Exercise status,
completion and cancel availability update while hovered. Ammunition entry/catalog
use the existing authoritative research/adoption gate. Recruiting timing, production
costs, simulation rules and save schema are unchanged. Resources/Borders/Charted
buttons and unused toolbar state are removed; resource controls in Economy/Atlas
and other toolbar actions remain.

Canonical final combined training probe: 32 checks passed, zero failures, exit 0.
An intermediate rerun found a test-only stale button reference across awaited
layout frames; this checkpoint reacquires the current button before clicking.
Canonical onboarding probe passes toolbar absence/default-resource/bounds checks
but exits 1 on the pre-existing “retired Lens was constructed during normal
inspection” assertion. Worker unchanged-baseline log reproduces that Lens failure;
its separate old toolbar bounds failure is absent after cleanup. No full onboarding
pass is claimed, and no Lens/campaign/battle redesign was added to this batch.

All 117 original untracked import sidecars retain their hashes. Tests did not
save/load a player world. Existing before_river_war.save mtime 15:54:52 predates
this integration; no restore or overwrite performed. No QA override copied.
Player PID 3981 was preserved running the earlier Mac build; normal Save & Quit
and canonical relaunch are required to load these follow-ups. No restart or push
performed. This closes the authorized delegated batch; further work stays with
the coordinator. Older checkpoints below describe their historical state.

---

# Mac integration — September 6, 2026

Canonical Mac checkout: `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`, `main`.
Gameplay commit: `39942ef03111cae82dc6f8975ddf2aba57feab3f`; fast-forwarded from
`7fb7e96288313099af9d5801ae5b5f36441fb627`, including input commit `f15e59f`.

INTEGRATED: native gesture and keyboard map zoom; 10 Hz presentation snapshots;
persistent scalable UI, 3D resolution, shadows and frame limit; persistent music
volume/mute on the Music bus; discoverable confirmed Quit with save failure protection.
Campaign redesign/removal remains PAUSED. No campaign or world-reset behavior changed.

Canonical Godot 4.7.2 headless checks: 24 input and 69 display/music/save/quit checks
passed, zero failures, exit 0. CPU probe passed, exit 0: per-frame schedule batches
211.423/208.960/204.248 ms versus 56.805/55.300/62.295 ms at 10 Hz for 120 paused
process calls; 120 versus 19 snapshot refreshes each. Day/population unchanged.
These are CPU workload measurements, not FPS. Presentation may lag by 100 ms.
Coordinator separately verified 67 graphical checks on Apple M1 Pro and inspected
1280×720 and 1440×900 top/bottom menu captures. No extra graphical launch by integrator.

Save writer review: payload/slots unchanged; sibling temporary file, flush/error check,
then replacement. Open/write/rename errors propagate; Save & Quit remains open on error.
Canonical probes cover replacement success, blocked temporary writes preserving prior
save, and quit failure/cancel/discard paths. No power-loss durability claim is made.

Preservation audit: all 117 pre-existing untracked `.gd.uid` sidecars and the existing
`before_river_war.save` retain their SHA-256 hashes. No QA override.cfg was present or
integrated. Generated probe artifacts remain ignored. No push or player launch performed.
Coordinator owns final relaunch. The in-game release label remains `2026.09.06.2`;
identify this Mac checkpoint by Git commit, not that unchanged label.

See `MAC_DISPLAY_VALIDATION.md` and `MAC_SETUP.md` for controls, worker evidence and limits.

---

# General campaign integration — release .14

Source codex/general-campaign from canonical 2961a15. Added the bounded authored Alderford War without replacing existing terrain, civics, force ownership or combat resolution. Verified full victory/defeat, real UI objective/withdrawal/recovery/save loop, 56 combined tests and seven actual Terra exchanges. See RELEASE_2026_09_05_14.md and INTEGRATION_STATUS.md. The full historical campaign remains outside this slice.

# Canonical feature reconciliation — 2026-09-05

Latest consolidation: release 2026.09.05.5 integrates the battle/siege HUD series
through 018cedd, excluding its isolated project settings. The branch audit found
other differing historical hashes already reconciled as described below. See
RELEASE_2026_09_05_5.md and INTEGRATION_STATUS.md for current scope and evidence.

The playable checkout is `C:/Users/sjpur/TomorrowandTomorrow`, branch `main`.
This record distinguishes recovered behavior from old implementations that have
been superseded. A newer file timestamp is not a reason to replace an entire system.

## Civic and leader work

Reconciled the civic changes from `d085c74` through the consolidation in
`d0f2ab3`, and the statistical decree changes in `b5d794d`, into the current
GovernmentPeopleSystem settlement conversation path:

- Conversational first-person responses, eight recent turns of bounded context,
  and adequate response budget. Questions remain discussion; only explicit
  instructions reach deterministic execution checks.
- Clear orders proceed without repeated mandatory ethical confirmations or a
  personality veto. Leaders retain objections and relationships; population,
  resources and institutional capacity still constrain implementation.
- Six validated immediate metric estimates, with uncertainty and causal reasons.
  Estimates are simulation inputs, not measured causal facts. Food, water, labor
  and production continue through their existing systems.
- Exact counted actions affect the eligible aggregate population once, record
  their actual result and death ledger linkage, and do not become standing policy.
- Follow-up reports distinguish immediate receipts from observed later changes.
  Existing saves retain their records; no retroactive events are fabricated.

The old separate `LeaderConversation` autoload and office popup are not restored:
the current settlement conversations already own named leaders, history, intent
clarification, execution and follow-up reports. Restoring the alternate UI would
create another authority and a separate conversation store. The older standalone
draft/Issue panel itself is not part of the current interface.

Validation: 71 civic/directive/government tests, city-civic runtime probe, and
whole-game save/load probe passed. The live paid API probe is available but was
not run during this reconciliation. Existing renderer/ObjectDB shutdown leak
warnings remain in runtime probes.

## Other scope

Animated armies, historical figures, ambitions, community networks, diplomacy,
current terrain and the subsequent graphics work were integrated before this
pass. Expedition findings, mobility and billion-scale verification were integrated from the scoped handoff below. Combined validation follows.

See `WORKER_HANDOFF.md` for ownership, worktree and integration rules.

## Combined canonical verification

After civic `fb5c118` and expedition/mobility commits through `95a6b0d`:

- 272/272 tests across nine suites passed (report 728, 3m14s), covering civics,
  directives, government, expedition findings, civilization, military development,
  settlement architecture and warfare presentation. The civilization suite
  includes a century with billion-person populations and bounded save records.
- Canonical population-scale probe passed with nine cohorts and one formation;
  whole-game save/load passed after the combined changes.
- GPU expedition report probe passed; both report and journey captures inspected.
  Five painting assets are imported. The real return handler opens the same
  report provider, also reachable through World reports.
- GPU warfare-map runtime probe passed, including current route geometry and hover.
- Existing shutdown resource leaks remain. No paid API call was made by this pass.

The worker's additional 133-test demographics/government/architecture sweep passed
in its isolated checkout; this is supporting evidence, not additional canonical
coverage claimed on top of the 272 tests above.

## Expedition, mobility and scale handoff (worker evidence)

# Feature reconciliation — September 5, 2026

Worker checkout: `C:/Users/sjpur/tt-feature-reconciliation`, branch `codex/feature-reconciliation`, base `9c0aaacd7bc6c37dcbc705ead87cccf06119f157`.

This is a feature inventory, not a claim that a passing subset proves every game feature complete. Canonical integration and editor launch belong to the integrator.

| Work | Evidence and disposition |
| --- | --- |
| Billion-scale population, resources, food, labor and military counts | Already in base. Population probe passes at one billion, nine cohort keys, one 500,000-person formation after one million recruits, and three consequence days. No ordinary citizen registry restored. |
| Bounded civilization simulation | Already in base. Century probe passes: 23 rivals, 115 regions, 1,217 turns, bounded events and 446,929-byte exported civilization state in this fixture. |
| Bounded named leaders | Preserve current GovernmentPeopleSystem and its 96-person ceiling, rather than restoring the superseded institutional-only or 512-citizen implementations. |
| Expedition chronicles and route chart | Omitted from base; restored selectively from 818d9d8, followed by later decisions. Two report tabs, actual days away and grounded discovery records. |
| Five expedition paintings | Omitted from base; restored from 12a60ea plus original dawn cover. Static reusable art, no runtime image-generation charges. |
| Retired illustrated landmarks | Apply 1d7b045 after the chronicle to preserve the later retirement decision; old artwork is archived, not deleted. Existing genuine findings survive load. |
| Mounted scout pursuit and sustained march speeds | Omitted from base; restored from 8cb853b. Army proximity, speed, readiness and scout evasion affect interception; mixed columns respect their slowest element. |
| Scout hover presentation | Selectively reimplemented from 37d92d9/b9c9ae3. Hover-only route captions replace permanent labels. Preserve newer grounded ribbons, correct directional triangles, layer priorities, scale cache and zoom handling instead of replacing the whole renderer with the old overlay. |
| Battle view and unit builds | Already in base: 27 models / 108 animation clips verified. Military UI exposes Inspect in 3D and View Battle. Historical appearance variants are not all separate recruitable combat classes. Battle probe passes with a 192-figure ceiling. |
| Decree statistics / remaining civic checkpoint | b5d794d and d085c74 audited separately by canonical integrator; do not restore an obsolete duplicate LeaderConversation authority. Not claimed complete by this worker. |

## Verification in reconciliation checkout

- Import completed; no parser failure observed.
- Expedition, civilization and military-development suites: 92/92 pass. Civic implementation suite separately: 4/4 pass. An initial mistyped civic test path was corrected and rerun; it was not counted as coverage.
- Population and civilization scale probes pass (figures above).
- Scout gamble dispatch/return probe passes; status calls measured in microseconds in this fixture.
- Warfare runtime passes headless and GPU, preserving route geometry/direction tests and asserting hover account presence / permanent labels hidden.
- All 27 model imports and 108 animated clips pass verification.
- Battle graphics probe passes combat invariance, metadata, casualties, reset, retreat, pause, save and fixed visual count.
- Whole-game save/load probe passes. Only dedicated QA slots used; player saves and running session untouched.
- Actual report dock GPU probe passes and captures both tabs and four alternate paintings. Inspected `artifacts/expedition-report.png` and `artifacts/expedition-journey.png`.

Existing Godot shutdown texture/RID/ObjectDB leak diagnostics remain on several graphical probes. Passing assertions do not establish unlimited-world performance or zero leaks. Paid API behavior is not covered by these offline checks.

## Integration

Review and cherry-pick this branch's task commits in order. Shared hunks include civilization_system.gd, military_campaign.gd, local_terrain.gd, dock_blocks.gd and save_load_probe.gd. Preserve newer integrator civic work when resolving. Do not copy whole systems from the consolidated/archived branch. Before announcing shipment, verify the main report component exposes both tabs, five asset paths exist, the actual return handler opens that component, and the canonical combined tests pass.

User requested visible Godot editor and game with supported built-in external-script reload / live scene synchronization after integration. Preserve any unsaved current session; ask before replacing it if necessary. Worker did not launch a preview as the player game.


## Combined checkpoint: century, battle, conversation and scout returns

The authoritative main now includes `69bc384` (century choices), `3485f1b` (battle terrain/contact and persistent veteran injuries), `2dff85c` (leader dialogue continuity), `cf3a058` (noninterrupting scout returns) and `4bc66f4` (first-page recruitment outcomes/HUD cleanup). Earlier eight-turn civic context is expanded to 24 messages plus recent decisions. See INTEGRATION_STATUS.md for validation and explicit held prototypes; no folder overwrite or blanket old-branch merge was used. Player saves and live campaign were preserved.


## September 5 — sustained sieges and independent protection leagues

Integrated siege worker `1f10c0d` as `8077fa3`, diplomacy worker `4ce8a64` as `60910ec`, and real relief/save integration tests `d727f9d` as `7964a29`. Canonical 98-case checks, world save/load and GPU siege UI pass. These extend the existing food, population, army and ForeignDiplomacy owners rather than creating duplicate simulation authorities. Main retains all previous terrain, battle, injury, century and dialogue changes. The open player from `883a8f2` is preserved and needs a save/relaunch to load structural changes. Details and limits are in docs/INTEGRATION_STATUS.md; chart work is pending, held prototypes remain excluded.


## September 5 — scalable scouting archive

Integrated `6e6b6d0` as `d0315c9`; military console audit `ee0283b` as `de1d41d` is evidence/recommendations only. Searchable five-card pages, 256 full reports, explicit review/retention semantics, compact recent highlights, terrain-evidenced detail-only art. Canonical 71-case checks and GPU archive pass; prior siege/protection code preserved. Chart/city-intel/zoom-fill workers continue separately. See INTEGRATION_STATUS.md for checks, limits and restart status.

## September 5 — consolidation of tested deliveries

Worker strategic charts `4107fd1` integrated as `12d16a3`. Both scout_archive and trend_chart renderers are retained in the shared dock; dynamic provider tabs expose Economy Wealth and Military Supply. Canonical combined 64 cases pass, plus muted GPU chart layout/range/hover checks. The player session is preserved; a normal save/exit/relaunch is required for newly integrated scripts. See INTEGRATION_STATUS.md for the current queue and held unfinished work.

City intelligence `02a6587` integrated as `efbff12`, preserving archive retention/review and chart sampling. The combined eight-suite 113-case regression passes. Independent discovered cities and reciprocal dated evidence extend existing simulation/save owners; see CITY_INTELLIGENCE_HANDOFF.md for scope and limits.

Follow-up `691eed6` → `d418704` restores the existing intelligence threshold for exposing founding focus. Canonical targeted 14/14 cases pass. Worker century and billion-population runs passed; its full run was 117/118 before this isolated guard fix, not an unqualified 118/118 claim.

Zoom streaming `1142441` → `42595fb` cancels obsolete work, fills geography before detail, retains outside coverage and caches four completed meshes. Canonical five terrain cases and expanded camera runtime probe pass; existing city/chart/scout hooks preserved. Full limits and benchmark evidence are in ZOOM_PERFORMANCE_HANDOFF.md. The military usability rewrite remains held and is not part of this release.


## September 7, 2026 — main-map Navy and Air correction

Integrated 7fb5dc2, fecf99f, ff2f02b and 5ae5714; release 2026.09.07.2. Navy and Air have separate panels and service-specific operational rules over the actual terrain camera. The secondary map is removed. Readiness, commissioning quotes, recipe-funded local repairs, airbase crowding, airborne versus port targeting and physical naval contact/fire ranges are implemented and tested. All 63 combined checks passed; the final layout refinement passed 34 relevant cases again. Canonical player PID 67340 runs code 5ae5714 with the explicit project path and resumed campaign; both final panels checked live, paused on Air Command. No new required save fields. Native pointer drawing remains unverified; headless tests cover projection and input behavior. Exact HOI4 numerical parity remains unfinished. See MAIN_MAP_SERVICES_HANDOFF.md and INTEGRATION_STATUS.md.


## September 7 — carrier order correctness

Integrated 947ad09 on canonical main: rebase cancels obsolete carrier ferries; carrier-wing stand-down stays on deck; force reorganization and disbanding require actual home-base arrival; carrier merges preserve pending wing references and carrier removal cannot orphan wings. All 38 relevant canonical tests pass; no save migration. Running player/editor untouched; next normal launch receives this pass. See CARRIER_TRANSITIONS_HANDOFF.md.


## September 8 — carrier wing markers

Integrated 24d2d18 and fixture correction ec1cd9c. Carrier-wing drawing, selection and route origins follow actual carrier positions; detachment restores independent position. Corrected canonical run passes 34 tests; no save changes, no player/editor interruption. See CARRIER_MAP_HANDOFF.md.


## September 8 — military order selection

Integrated 6145949. Region and mission choices survive command-panel refreshes and failed orders, while explicit force selection follows the existing assignment. Current order is labelled separately. All 36 canonical checks pass; no save changes or player restart. See MILITARY_ORDER_SELECTION_HANDOFF.md.


## September 8 — easier panel closing

Integrated e493ab5; 11 canonical checks pass. Bare map dismisses docks/help without issuing world orders; report backdrops dismiss supported screens. Military drawing remains functional. Map-help text and close label clarified. Running new campaign left untouched after user activity was detected; next launch receives the change. See MAP_DISMISSAL_HANDOFF.md.


## September 10 — scouting allocation, city evidence and recruitment groups

Integrated `ce7ed7a` on canonical Mac main, release 2026.09.10.2. Standing scouting replaces repeated general expedition buttons; connected physical routes, paid provisions and returned evidence apply to all civilizations. Compact city intelligence and map labels agree on observed population; targeted observation time improves estimates. Recruitment keeps existing soldiers and fills only missing people in supplied groups that fit free training places. HUD route-planning and hidden monthly vegetation rebuilds are removed; the actual year-31 release replay reaches 2.832 days/second at the 3-day setting. All 158 combined canonical checks pass, plus native UI/click verification. Frame stalls remain; no constant 3-day or smooth-FPS guarantee. See INTEGRATION_STATUS.md and SCOUTING_RECRUITMENT_CLARITY_HANDOFF.md for compatibility, evidence and held work. No player relaunch is part of this delivery.

## September 14 — artifact imagery correction

The reviewed `codex/artifact-paper-art` bank is reconciled with the newer
artifact economy and scouting implementation. Artifact cards no longer display
their linked research-field paintings. Exact approved object art is selected by
origin namespace and stable catalogue ID; legacy ownerless finds are presented
through that same prehistoric ID, and missing IDs use a generic object glyph.
The integrated bank contains 946 reviewed prehistoric images and 21 gated
living-civilization images. The remaining 3,143 prehistoric catalogue IDs are
still unillustrated rather than falsely mapped. Focused canonical validation:
81/81 artifact and exchange cases, two clean artwork audits, and zero missing
imported texture targets.
## September 15 — envoy return and compact city intelligence

Integrated source `04ef544` on canonical Mac main, base `2a21403`. Owned scope:
envoy return/recovery, foreign dialogue status, HUD city cards and dated civic
estimates, shared GDP calculation parameterization, and focused tests. No terrain,
government, save-system, or military ownership changes; no shared-file conflicts.

Pending AI output no longer advances return_day indefinitely. Physical reports
return once; a valid late answer completes the saved discussion independently.
Cards expose people, science/health percentage indices, and GDP in equivalent
worker-days per day (not currency). Five freshness segments saturate; the oldest
displayed observation governs freshness. No live hidden values are used to fill
old reports. Legacy cities without a GDP ledger display Unknown.

Validation: 55/55 cases in test_dialogue_continuity, test_city_intelligence,
test_city_label_layout, test_foreign_city_map_labels, test_diplomatic_journey,
and test_civilization_indicators using headless Godot on the explicit canonical
path. Optional fields preserve old-save loading. No live API or graphical audit;
the specific player's earlier reply failure remains unproven. Existing release
PID 41480 and editor were not stopped or replaced.
## September 15 — Mac AI persistence and bounded dialogue

Source `ff33810` integrated by the canonical Mac integrator from `5963192`.
Keychain connection storage uses a bundled native helper over private pipes, not
command arguments or campaign serialization. Opt-in remembering, explicit removal,
environment precedence and endpoint mismatch protection are covered. The dialogue
panel consolidates repeated failures and prevents unconfigured retries, preserving
drafts. Routine standing-watch reports remain archived but no longer announce
every return. Existing explicit expedition and exceptional return notices remain.
60/60 focused cases and isolated native storage self-test pass; no live service or
graphical audit. No conflicts; narrow edits to terrain return-notification hook and
civilization event publication. No terrain geometry or resource-supply changes.

## September 19 — light and dark interface themes

Integrated worker `da9b80b` as canonical `7cfbe39`. Light is now the default
interface palette, while Dark remains available under Display & Performance and
persists as a machine-local preference. The shared HUD, Command Rail, game menu,
Ground Survey, and Settlement Site review use the selected palette; the terrain
and simulation remain unchanged. Canonical integration preserves existing saves.
Focused worker validation passed 27/27 cases covering preference persistence,
Command Rail stability, survey cards, and founding guidance.

## September 19 — automatic government officials

Integrated worker `b009974` as canonical `e706760`. Government is now a
first-class command-rail destination with a recognizable civic-building icon;
all rail destinations use distinct theme-aware drawn pictograms. Every unlocked
central or local office fills automatically from durable named people with
stable randomized traits and skills. Normal player screens no longer ask the
player to select candidates. Dismiss and Execute immediately trigger succession;
execution removes one person from the aggregate population and carries the
larger legitimacy and cohesion cost. Expanded name banks improve variety while
preserving all names already stored in saves. Focused validation passed 34/34
government simulation cases and 2/2 Government HUD cases. No save migration.

## September 19 — visual government cabinet

Integrated worker `f81c395` as canonical `1edb41c`. The Government destination
now presents authority as gauges and officeholders as compact visual cards with
office seals, abstract portraits, trait chips, ability bars, a fit ring, and
icon-only dismissal and execution controls. The Command Rail uses heavier filled
silhouettes and a clear active medallion. Simulation, appointments, terrain, and
save data are unchanged. Godot completed a clean parse/import pass; the focused
UI runner encountered its existing headless crash before assertions.

## September 19 — separate Construction and Production navigation

Integrated worker `7ef73b8` as canonical `beab66c`. Dedicated hammer and factory
rail destinations expose delegated construction progress and shared production
orders, with civilian/military filters. Settlement retains Overview and History.
Existing leaders continue scheduling work; manual takeover is optional. No new
construction queue override has been implemented. Simulation and save formats
are unchanged. The GdUnit runner crashed before assertions; live visual review
is pending. This structural change requires a restart to appear in the player.

## September 19 — optional work overrides

Worker `28caf4b` integrated as `54772f4`. Construction supports an optional
per-city project priority, subject to existing prerequisites; blank preference
retains leader scheduling. Production can return one persistent line to staff,
resuming it without resetting work or touching other manual lines. Optional
city field is contained in existing settlement records. Focused runtime checks
passed for setting/clearing priorities, invalid-city rejection, per-line isolation
and work preservation. Sidebar providers compile successfully.

## September 19 — compact production line inspector

Integrated worker `814fde7`. Persistent production details now use a product
header, ownership status, four metrics, work progress, a compact input shortage
table, stock target and priority strips, and a short action footer. Priority
overrides release that line from staff control through the existing configure
API. Batch orders, product catalog and retool selection retain their existing
layouts. Compile check and Godot sample-data render passed; no live campaign
changed by the isolated preview. No save format change. Current player has not
been restarted to receive this inspector.

## September 20 — illustrated production queue

Worker `9094cf3` integrated as `eb251ad`. Production now uses stacked illustrated
rows, ten fractional work-share markers, efficiency bars, forecast rates, stock
targets and material shortfalls. Targets, pause, relative priority and delegation
expand inline; history and detailed retooling remain accessible. Production alone
uses a wider responsive dock. Capacity markers are work shares, not invented
factory or worker counts. No simulation or save-format changes.

Canonical isolated Godot review passed action isolation, per-line delegation work
preservation, civilian/military filters and compact minimum width; five seeded
engine snapshots rendered successfully. The review exits without modifying the
player campaign. Existing live game has not been restarted. Art coverage is an
initial family with explicit generic workshop fallback; atlas is ivory-backed.
Queue order displays current line order; relative priority changes work share,
not drag ordering. Full earlier-era production-capacity rebalance is not included.

## September 20 — illustrated construction queue

Worker `21abad0`, based on `7d383a9`, integrated as `583e28c`. Construction now
uses illustrated project rows, actual progress, compact material indicators,
inline project requirements and optional priority with return to leader choice.
Projects and completed works remain separate tabs. Construction shares the wider
responsive production dock. Material alternatives are exposed from the existing
engine recipes; selection and daily construction behavior are unchanged.

Canonical Godot review passed HUD/block compilation, progress/completion filters,
feasible material reporting, priority selection, blocked-priority fallback,
delegation progress preservation, and compact minimum width. The seeded review
rendered and exited; the live player was not restarted. Save schema unchanged.
Shared files: dock_blocks.gd and command_rail_hud.gd; cherry-pick had no conflicts.
Art covers the seven defined communal projects, with an ivory background; it
represents building types rather than every possible material variant. Housing
expansion remains automatic and the existing building record remains accessible.

## September 20 — illustrated provisions and economy tabs

Worker `5775e3d2` integrated as `3211dc24` from base `3495f81a`. Provisions now
shows illustrated stores, actual spoilage and daily flow including mission issues,
water coverage, and engine 30/90-day forecast checkpoints. Meat/fish aggregate
only for display, with separate amounts in the expansion. Food/water direction
and return to leader use existing government APIs. Existing detailed sources,
history, deliveries and other economy tabs remain accessible. Economy uses the
wide work dock, serif heading, and equal-width underlined tabs.

Canonical isolated review passed aggregation, delegation, first-water-report
handling, real dock compilation, compact width and full body fit at 920x1000.
Screenshot is seeded data in the actual dock, not the live campaign. Player was
not restarted. No simulation/save schema changes or merge conflicts. Art is
ivory-backed category illustration; no fabricated portrait or daily forecast
curve. Forecast presentation deliberately uses available engine checkpoints.

## September 20 — illustrated Materials ledger

Workers `b411a5ef` and `360934de`, based on `a4df05ad`, integrated as `c3e35b73`
and `84d2cdd2`. Materials opens in the economy dock rather than immediately
redirecting to the atlas. Illustrated stock rows show actual known-site delivery
rates, observed stock sparklines, expandable site constraints, and selected-city
incoming deliveries. Storage/hauling gauges and optional logistics/delegation
use existing engine values/APIs. The materials atlas remains available inline.
No simulation rules or save schema changes; shared dock/provider edits integrated
without conflicts. Current live player not restarted.

Canonical real-dock seeded review passed hidden-deposit exclusion, row ordering,
unknown-history gaps, incoming-city filtering, expansion toggles, logistics and
return-to-leader with unchanged stocks, compact width and body fit at 920x1000.
Final run had no asset-loading warning. Imported textures are preferred, with
source-image fallback for unimported development assets. No standalone export
was built in this task. Five basic material types have artwork; others retain
accurate names/values without unrelated art. Portrait is a stable illustrative
avatar from the existing five-face atlas. Historical copper points are unavailable
in the existing history schema and correctly show No history. Incoming cart
illustration is representative; no new transport simulation is implied.

## September 20 — Distribution removed; navigation reference approved

Worker `43d22fc6` integrated as `7f278df5`. Distribution tab and dedicated content
removed; Wealth is now tab 2 and the GDP HUD shortcut targets it. Dietary demand
simulation is unchanged. Canonical real-dock review verified three-tab metadata,
Wealth routing, and existing Materials behavior. No save changes, merge conflicts,
or player restart. The exact user-approved Wealth/navigation reference is saved
under docs/design; the illustrated rail and Wealth redesign remain design work,
not implemented features.


## September 20 — accumulated culture and local scouting: INTEGRATED

Source `775c1e91`, base `9785c9f7`, integrated as `3cc5c09d` in the canonical Mac checkout. Century commitments accumulate permanent weighted inheritance and a decaying recent influence across nine multipolar value domains. Fourteen directions influence research and leader-managed labor; player scouting, research, and organic settlement have persistent manual overrides. Expansion reviews retain existing food, terrain, convoy, and construction requirements. Settlement founding and leader execution leave capped cultural imprints.

The culture screen uses parchment, an illustrated portrait, four-pole value tracks with inherited markers, century thumbnails, and compact delegation controls. Existing ambition artwork is reused; the six additional directions do not yet have unique illustrations. Darker values influence the existing culture/labor/research systems; this does not implement new autonomous atrocities or war declarations.

Scout targets and away counts now belong to the chosen departure settlement. Dispatch is bounded by local working-age population and national commitments; provisions come from that settlement's stores. Existing missions remain unchanged. Older culture saves migrate only the last recorded direction; unknown earlier choices are not fabricated.

Canonical focused checks pass: `tools/cultural_inheritance_review.gd` (weighted choices, migration, manual overrides, capped actions, survival gate) and `tools/scout_origin_review.gd` (40-person settlement, 10% target, other-city absences, invalid dispatch rejection, valid dispatch charging local stores). Actual native culture render inspected at 1200×900. No player process restarted. Prior Wealth/navigation work remains isolated and unintegrated in its existing worktree.


## September 20 — first campaign performance pass: INTEGRATED

Worker `6e387951` from `67d5d47c` is integrated as canonical `c0a5d2fe`. Observer city projections omit unused detailed private metrics; surface-front searches use narrow catchment reads and a bounded, invalidated search cache; food forecasts avoid empty botany work. Food simulation depth, AI cadence and elapsed-day rules are unchanged.

The same 24-day, twelve-opponent, day-11238 replay reduced headless mean daily CPU from 281.60 to 253.99 ms (9.8%). Owning simulation state matches the baseline, including full food forecasts; only wall-clock save time and deliberately narrowed observer projections are exempted, with retained projection values checked. Canonical focused validation passes 17/17 with zero errors/failures/skips/orphans. No shared-file conflict occurred. Resource search caches are excluded from saves; existing saves retain their private city data. No player restart or release packaging occurred. This is not a rendered-FPS or year-3000 guarantee. Details: `docs/performance/CAMPAIGN_COST.md`.

## September 20 — second campaign performance pass: INTEGRATED

Worker `2d264dd2` on `codex/campaign-scaling`, based on `e341b8eb`, is integrated as canonical `4ab3a7bd`. Research readiness uses a short-circuit predicate instead of constructing descriptive routes; material profiles reuse constant definitions; food spoilage and forecasts batch preservation lookups. Branching, imported knowledge, adoption, staffing and all food mechanics retain their existing semantics. No persistent readiness cache or save-schema change was introduced.

The same 24-day, twelve-opponent, day-11238 replay reduced mean headless daily CPU from 256.32 to 236.07 ms (7.9% additional reduction). Full saved simulation state matches, excluding only the save timestamp. Canonical focused validation passes 33/33 with zero errors, failures, skips or orphans. Synthetic large-knowledge preservation lookup is 13.6 times faster, a component result rather than a whole-game claim. No shared-file conflicts, player restart or release packaging occurred. The year-100 campaign was unavailable; this does not establish year-3000 performance. Details: `docs/performance/CAMPAIGN_SCALING.md`.

## September 20 — daily society calculations: INTEGRATED

Worker `20a480d7` from base `1fc946b0`, branch `codex/campaign-daily-cost`, integrated as canonical `a3d03025`. Daily subcategories reuse per-office doctrine contributions within each evaluation; axis-only cultural effects skip unrelated political alignment work; monthly adoption hoists unchanged common factors. Existing formulas, live appointment/state changes, legacy profiles, food and research behavior are preserved.

The 24-day, twelve-opponent year-31 replay measured 239.91 → 234.39 ms mean CPU per day (2.3%). Full saved state matches except the timestamp. Canonical focused validation passes 21/21 with no errors, failures, skips or orphans. A pre-existing leadership fixture now isolates its partial settlement records from background city processing. No save-schema change, shared-file conflict, player restart or release packaging. This modest gain does not establish year-100 or year-3000 performance. Details: `docs/performance/CAMPAIGN_SOCIETY_COST.md`.

## September 20 — accumulated exploration and construction cost: INTEGRATED

Worker `f2f1df03`, base `e7a22a40`, branch `codex/campaign-accumulation`, integrated as canonical `bc28072b`. Unchanged map frames check the fog revision before copying explored trails; live convoy-origin uniforms still update. Early-work material history is read only when a plot needs conversion. No territory, materials, permanent records or simulation rules are removed.

Synthetic 1,024-trail/64-point unchanged-map refresh fell from 49.586 ms to 0.0007 ms per call with no materials attached; finished early-work checks at 100,000 unrelated history records fell from 88.161 ms to about 0.0046 ms. These are component stress measurements, not campaign FPS or naturally reached ages. The 24-day twelve-opponent replay matches full saved state except timestamp; its daily CPU mean is essentially unchanged. Canonical focused checks pass 8/8, zero errors/failures/skips/orphans. No shared-file conflict, save-schema change, player restart or release packaging.

The audit identifies remaining full fog repaint cost, settlement/observer-view scaling, and a separate uncorrected succession cap that counts deceased leaders. Those are not implemented fixes. Details and raw measurements: `docs/performance/CAMPAIGN_ACCUMULATION.md`.

## September 20 — chart geometry and completed research: INTEGRATED

Worker `55d92b91`, base `e1f2f8e2`, branch `codex/settlement-map-scaling`, integrated as canonical `e37cdd03`. Visibility queries reuse an exact per-civilization spatial index that rebuilds on exploration changes and clears on reset/import; bucket references are capped with exact fallback. Completed discoveries leave active candidate scans through an unsaved membership/channel index. Live branching, resources, imports, practice and scoring remain unchanged; knowledge, adoption and benefits remain in the campaign.

Canonical focused validation passes 33/33, zero errors/failures/skips/orphans. The 24-day twelve-opponent replay matches saved state apart from timestamp. Synthetic large-chart queries improve 24.416 → 0.0089 ms after a 113.9 ms cold build; completed-catalog channel checks improve 4.475 → 0.292 ms. Daily replay mean was 247.56 → 259.38 ms, so this delivery does not establish an overall daily speedup. The normal map-query workload is outside that harness. The existing scout-origin test fixture now provides local food as required by the prior local-provisions change.

No save-schema change, shared-file conflict, player restart or release packaging. Obsolete-effect pruning is not implemented: old bonuses can remain relevant as operating conditions change. Full fog rasterization, broader settlement/observer scaling, and archived-leader capacity remain unresolved. Details: `docs/performance/CHART_RESEARCH_INDEXES.md`.

## September 20 — fog corridor rasterization: INTEGRATED

Worker `ff591c54`, base `d4ba4fae`, branch `codex/fog-redraw-cost`, integrated as canonical `19c6a130`. Segment painting clips each image row to the corridor's conservative horizontal bounds, avoiding irrelevant pixels inside large diagonal bounding rectangles. Original per-pixel distance, smoothing, blending and output resolution are preserved.

At actual planetary dimensions and 1024×512 mask resolution, synthetic long-diagonal painting measured 28.149 → 0.924 ms; regional diagonal 1.138 → 0.224 ms; horizontal 0.452 → 0.419 ms. Output bytes match. These are individual corridor costs, not total fog repaint or whole-game throughput. Canonical focused validation passes 6/6 with zero errors/failures/skips/orphans, including randomized pixel equivalence and existing refresh semantics. No save or simulation changes, shared-file conflicts, player restart or release packaging. The prior daily-tick timing increase remains unresolved. Details: `docs/performance/FOG_RASTER_COST.md`.


## September 20 — surface resource geography cost: INTEGRATED

Worker `225cdb55`, base `20033bcc`, branch `codex/daily-simulation-speed`, integrated as canonical `cb5d095b`. Resource searches sample only authored surface catchments through a bounded independent cache; full geography reports reuse them. Searches avoid unrelated water and climate sampling. Resource quantities, regrowth, food, research and daily simulation rules remain intact.

Canonical focused checks pass 16/16 with zero errors/failures/skips/orphans. The private year-31, twelve-opponent, 24-day replay matches full saved state except timestamp. Mean CPU/day improves 246.780 → 223.002 ms (9.6%); excluding first-day cold work, approximately 4.9%. This single workload does not establish year-100 or year-3000 performance. No save-schema change, shared-file conflict, player restart or release packaging. Details and raw timing: `docs/performance/SURFACE_GEOGRAPHY_COST.md` and `.json`.


## September 20 — recruitment queues and consequence-based drafting: INTEGRATED

Worker `a6be7587`, base `e91927a3`, branch `codex/military-recruit-deploy`, integrated as canonical `b1b7139e`. Land recruitment now has parallel/serial/repeating formation lines, separate manpower/equipment/training bars, priority, pause/cancel, automatic deployment and early deployment from 20% training. Deployment transfers actual trainees and reservations into a new home army or an existing army at home. No arbitrary recruitment percentage, prototype headcount or classroom intake cap; actual available working-age people remain the physical limit. Away civilians cannot be drafted twice. Mobilization beyond Defense allocation reduces actual civilian workers, including local settlement calculations. Initial instruction may consume civilian food reserves.

Canonical focused validation: 67/67 tests, zero errors/failures/skips/orphans. Covers population and equipment conservation, real instruction completion, early deployment, priority, cancellation, pause costs, workforce loss/recovery, binary save roundtrip, invalid-save rejection, UI construction and existing service training. No graphical player launch, restart or performance/balance claim. Optional save fields preserve existing saves; simulation outcomes intentionally change. No shared-file conflicts.

This is a tested land-queue delivery, not exhaustive HOI4 parity: arbitrary province/front deployment, retrofitting edited templates, global reinforcement-versus-new-unit equipment priorities, and naval/air recruitment parity remain outstanding. Details and governing user instruction: `docs/RECRUIT_DEPLOY_DESIGN.md`.


## September 21 — Army roster force grouping

Army roster now shows home reserve, individual field armies, garrisons by occupied
location, and recruitment lines rather than one card per internal training cohort.
Expanded composition groups roles/equipment and exposes counts, equipment shortage
and weighted drill. Totals sum actual records without modifying campaign ownership;
subgroup shortages remain visible through attention filters. Unreported field data
stays unknown. Navy/air workflows and general-led command remain unchanged.

Validation: 35/35 roster, recruit/deploy and training-accounting tests; private GPU
roster captures pass, including 1024x640. A hundred one-person levy records collapse
into one force, while separate garrisons/queue lines remain separate. No save-schema
change. This corrects the roster; full HOI4 parity remains incomplete as documented
in RECRUIT_DEPLOY_DESIGN.md. Generated imports and captures are excluded.

## September 21 — Recruit & Deploy screen rebuilt

Replaces the narrow dropdown form with a wide dark military workspace. Recruitment
lines occupy the left column; visible illustrated templates with composition,
headcount and direct Train/Edit buttons occupy the right. Batch/parallel/repeat
settings remain real queue inputs. Line priorities, pause/cancel, assembly target,
auto deployment and early deployment remain wired to the existing recruitment
system. Empty queue explains its state; active lines expose separate personnel,
equipment and instruction bars. Columns stack in narrower layouts. No save or
simulation changes and no claim that remaining HOI4 mechanical gaps are complete.

Validation: 22/22 focused recruit/deploy and government HUD tests, including the
actual Train button creating two parallel formations across three batches.
Private GPU captures pass for empty and active queues at 1600x1000 and 1024x640,
with no horizontal overflow. Reference: Paradox's HOI IV Strategy Guide,
https://forumcontent.paradoxplaza.com/public/paradox/banners/HoI_IV_Strategy_Guide.pdf
Generated imports and captures excluded.

## Research landing screen — 2026-09-21

Replaces the six-button Direct Attention menu with an illustrated investigation board, actual progress, workforce and bottlenecks, all twelve research fields, direct relative-attention controls, and access to the existing visual discovery tree. Widened inquiry dock; original field reports, workforce policy and established knowledge remain available. Presentation only: no save migration or simulation rules changed. Validated with 18 research atlas/navigation tests and an isolated GPU probe at 1600x1000 and 1024x640 covering field counts, attention changes, no invented population/knowledge, field reports, tree opening and the empty state. Missing subject paintings show the investigation method instead of a misleading picture.


## Simulation bug and balance audit — 2026-09-21

On base `3c66cf8`, fixed founding-year government priorities bypassing survival emergencies and a saved daily inclination-review marker being reset by nested military state import. Older saves remain compatible. Updated the starter-material test to distinguish advanced framed construction. Added a reproducible three-scenario headless annual audit. 127 checks pass; one existing research-personality distinction test remains failing and is documented without weakening its assertion. The 12-opponent complete save round trip passes. Larger simulated settlements still exhaust food; research pacing and military ration delivery remain open balance findings. See `docs/SIMULATION_BALANCE_AUDIT_2026_09_21.md` for scope, measured before/after results and limitations. No player launch or desktop control.


## Secondary settlement locator zoom — 2026-09-21

Secondary city dots now use the primary city's stage-dependent close-view cutoff, updated on camera motion without requiring a network rebuild. Names and physical city fabric remain separate and visible under their existing rules. This removes the oversized yellow locator over a small settlement during close inspection and restores it at regional zoom. No simulation or save changes. Focused headless regression passes for close/far/close transitions and retained labels. The broader architecture suite stopped at its strategic river-edge mesh test (empty surface, 74 cases executed); this pass does not claim that suite is clean or GPU visual verification. User retains visual review; no running player restart.


## Readable military strength, attention and training — 2026-09-21

Roster personnel now read as soldier/vessel/aircraft counts, with planned strength and condition underneath instead of an unexplained fraction and spaced silhouettes. Attention shows missing gear counts, poor condition, strength shortfalls or actual waiting/paused activity; the filter uses those same reasons. Grouped formations retain poor-condition evidence even when the weighted mean hides it. Training uses a compact shield patch with stacked chevrons and named drill levels; numeric drill and combat experience remain separately visible. The policy panel uses the same patch. No troop, training, spending or save rules changed. All 8 military roster tests pass, covering live refresh, shortages, unknown reports, grouping, compact row height and layout from 800x600 to 1600x900. Headless validation only; user retains visual review and the running game was not restarted.


## Army command clarity and snapping zones — 2026-09-21

Command tabs, tree headers, fields, cards and text now use a coherent palette instead of light labels over default gray controls. The panel height is capped at 820 pixels; force/objective/zone headings describe the workflow. Drawing snaps within 12 screen pixels to drawn or known zone corners, or to 45-degree alignments from the last corner. The preview includes the closing edge and shaded polygon. Clicking near the first corner closes without a duplicate vertex. Right-click finishes a valid polygon; fewer than three corners cancels the unfinished drawing. Enter/Finish remain available, Backspace undoes, Escape cancels. Invalid geometry still explains the error and remains editable. No automatic objective issuance on drawing completion, no free forces and no save-format changes.

Four focused headless checks pass: right-click triangle closure, first-corner snapping, alignment/incomplete cancellation, and themed controls with keyboard undo. The broader command hierarchy suite stopped after 13 cases at its military save round trip with “Invalid accumulated culture”; no claim of a clean full-suite pass. No desktop control or player restart; visual review remains with the user.


## Reopen campaign with collapsed opponent population — 2026-09-21

The day-7995 development save was rejected because six shared-rule opponent summaries reported military commitments greater than their surviving population. This made military_share exceed one and caused startup to exit. Shared demographic projections now cap military population at total population, and import repairs finite positive overflow in old shared summaries. Negative/nonfinite data still fails validation. Authoritative troop records and the save file are untouched. This repairs loading, not the separate military commitment/demographic reconciliation problem after severe population loss; that remains open and must not be mistaken for fixed opponent balance.

The exact quicksave loads successfully in an isolated headless process (day 7995, population 174). Five projection regression checks pass, including old-summary migration and preserving underlying commitments. No save format change; diagnostic scripts/logs are excluded from delivery.


## Workshop scheduling for serving troops — 2026-09-21

The day-7995 save had five craftspeople, a 35% workshop share, usable timber, no lines and no receipts. The enabled steward considered requested recruitment templates but omitted equipment shortages on existing forces; its civilian planner also had no current feasible demand. The steward now includes missing equipment on home, field and occupation formations, subtracts issued equipment, and uses existing inventory to satisfy demand before scheduling. Manual orders remain protected. Empty workshops explicitly report no feasible order rather than claiming existing lines continue. Household crafting remains separate from workshop-line receipts; this does not invent historical receipts or add arbitrary production targets.

An isolated test of the actual save, holding its staffing and other simulation systems fixed, scheduled simple levy weapons and produced three sets by the nineteenth workshop day, consuming exactly 1.05 timber, recording three receipts and stopping once inventory covered the shortage. The save file was not changed. All 15 manager-specific tests pass, including the new reserve-demand/material-conservation regression. Expanded inherited/civilian tests executed 39 cases with two failures: an obsolete supply-dock shape expectation and a sewing-supply test with an empty queue. Those are recorded as unresolved, not a clean full-suite result. No save format change or player restart.


## Live dock progress and settlement production totals — 2026-09-21

Removed the shared dock's hover freeze and its permanent block for nonempty, unfocused text inputs. Active clicks and focused text editing remain protected. Cached signatures are deep snapshots, so in-place percentage changes are detected instead of mutating both old and new signatures together. The existing live-report tick refreshes open main and detail docks without reopening; existing scroll preservation remains in use. This does not interpolate fictional work between simulation updates.

Workshop receipts now carry the producing resource scope's settlement ID/name (primary settlement fallback), and cumulative totals persist by settlement, output and production/repair kind independently of the 256 recent-receipt limit. History shows recorded raw quantities under settlement headings, not only a thirty-day window. Old saves reconstruct totals from retained receipts once and label missing attribution “Settlement not recorded”; older unrecorded production is not invented. All board entry points receive cumulative totals. Five focused tests pass, including hover refresh, mutable progress signatures, separate 150-item settlement totals over 300 receipt days, save restore/migration, invalid totals and visible historical output. Workshop campaign-save round trip also passes; the inherited suite still stops at its previously reported supply-dock shape expectation. No user save or running player changed.

## 2026-09-21 — Buildings settlement breakdown and history

Based on e227eaf; branch codex/building-settlement-history. Buildings now exposes Settlements and History tabs. The settlement report shows completed works by name and raw count, plus actual progress for started projects. Counts explicitly represent projects, not individual structures. History reuses the permanent architectural ledger, with all-settlement and individual-settlement filters, dated events, materials, and pagination. Unknown-settlement legacy records remain in the combined record and are no longer attributed to every settlement. Shared live dock refresh updates progress while the view remains open. No save format or simulation changes.

Validation: tests/test_building_settlement_history.gd — 3 passed, covering progress updates/completion exclusion, settlement-specific history/material accounting including unassigned older records, and tab availability. User handles visual review; no player restart or desktop control.

## 2026-09-21 — Culture explains gameplay and conduct reputation

Based on e17b231, branch codex/culture-gameplay-effects. Replaced the expanded inheritance list with compact work-priority, actual research-multiplier, and scouting-target cards. Food shortage and manual scouting overrides are explicit. Cultural roots remain expandable; different inherited/current tendencies remain visible there. Conduct reputation shows mercy, fear, and grievance with qualitative levels, meters, concise existing gameplay consequences, and hover explanations of what builds them. No reputation is fabricated from cultural ideals. Day and reputation changes refresh the open Culture dock. No simulation or save-format changes.

Validation: tests/test_culture_gameplay_effects.gd — 3 focused tests passed (effect calculation and overrides, empty/earned reputation, headless UI construction). Visual review remains with the user; no game restart or desktop control.

## 2026-09-21 — Cultural roots survives live refresh

Based on a6cc421, branch codex/culture-roots-refresh. Culture provider now owns the roots disclosure state; panel rebuilds preserve both open and closed choices. Expanded roots use responsive compact cards, with earlier tendencies shown only when different. Disclosure uses explicit readable theme colors. No simulation or save changes. Four culture tests pass, including opening, rebuilding, closing and rebuilding again with the provider-owned state. No player restart or desktop control; visual review remains with the user.


## 2026-09-21 — Expose civilian craft production and management

Base 2b0a327, branch codex/production-civilian-demand. Production now visibly names its workshop officeholder and scheduling status. All/Civilian includes household craft output and stocks by settlement with material, fire, staffing and adoption blockers. Household craft completion now adds actual gross quantities to the existing saved production totals per settlement, once per daily craft pass; older lifetime amounts are not invented. Up to six known workshop recipes show setup blockers, with the full catalog under Add. No crafting recipe, labor allocation, automatic order, pause, or discovery was overridden. Existing manual orders stay manual.

Read-only saved-state inspection: day 13399 (year 37), population 235, Quartermaster Kaia Almasi. Four retained levy-weapon completions, paused manual levy line; household cordage/containers already in stocks. Only adopted civilian workshop recipe was graded interior wood, blocked by Steel tooling. Isolated next-day craft call produced 3.6409236 cordage and 2.2468705 woven containers and deducted inputs. This does not establish the reported year-62 state; newer save requested.

Validation: 3 production-visibility tests and 6 existing opening-craft tests passed. Saved diagnostic assertion passed; its report completion stalled when another report runner overlapped, so it is used as diagnostic evidence, not counted in the nine regression checks. No player game restart, desktop control or save overwrite. Temporary probe source removed; private diagnostic logs remain only in artifacts.

## 2026-09-21 — Remove nomad sighting map labels

Base 3a33c39, branch codex/remove-nomad-map-labels. Removed the map's NOMADS SEEN labels and their refresh work; sighting records and scout reports remain intact. Scout report headers and observation dates now use Year / Day of year instead of elapsed-day serials. Eight existing scout archive tests passed. No save changes or player restart.


## 2026-09-21 — Prehistoric pacing foundation

Base 07bca5f; branch codex/prehistoric-pacing-foundations. New worlds inherit ten practical skills and finite tools/materials; spear production is available but paid, while agriculture, pottery, bows and advanced knowledge remain discoveries. The shared initialization applies to opponents too; existing saves keep their recorded state. AI supply planning now considers existing army shortages and can reuse finished unpaused military lines without discarding reserved materials or trials. Pacing evidence distinguishes recipes, inventory, equipped troops and household stocks.

See docs/FIRST_300_YEARS_PACING.md for accepted targets, implementation evidence and outstanding work. Bounded isolated run reached 12.21 years, with war bows at 9.47 and selective planting at 11.38. A 300-year result is not claimed. Field equipment delivery remains unresolved even after AI supply correction. No global research multiplier or late technology calendar lock was introduced. No player launch, restart or save overwrite.
Validation: 13 tests passed across founding knowledge, opening craft practice, and pacing production evidence.


## September 21 — first 300 years: local field-equipment issue

Task branch `codex/first-300-playable`, base `3044691`. Field armies physically stationed at home now share the existing daily replacement-equipment/ammunition budget and finite stores with the reserve. Remote, moving, engaged and convoy formations remain excluded. Combat totals and directly observed reports refresh after issue. Three focused headless checks pass. No save-schema change or player restart. Geography/decision acceptance criteria and outstanding campaign blockers are recorded in `FIRST_300_YEARS_PACING.md`. A running 300-year diagnostic is intermediate evidence only; no full campaign readiness claim.


## September 21 — local food access and matched opening diagnostics

Follow-up on `70faecc`, task `codex/first-300-playable`. Local troops share real settlement food without an artificial field transport penalty; remote/moving armies keep transport constraints. Mixed and separately delivered rations are accounted per force; prepaid campaign forces remain excluded. Four new tests pass; seven-suite run has 54 passes and one construction-labor failure reproduced on the pre-patch baseline. No save schema change or live player restart. Diagnostic knobs vary timber catchments and normal civic ambition; four complete matched one-year runs demonstrate different material stocks, labor, food reserves and construction outcomes. Sparse-site adaptation and complete 300-year readiness remain unverified. Evidence and limitations: `docs/FIRST_300_YEARS_PACING.md` and `docs/technology-review/pacing/first300-paired-opening.json`.


25-year follow-up for `019684a` completed all 9,125 daily ticks: three settlements, 24 known practices, equipped spears, full local food delivery and a civilian fitted-timber line with 42 completed batches. Compact evidence in `docs/technology-review/pacing/first300-local-provisions-25.json`. This is a bounded economic progression result, not complete 300-year readiness or a full-world test.


## September 21 — founding craft wear and durable mineral exposure

Base `31706d5`, task `codex/first-300-playable`. Household tools and containers use their own material-specific wear rather than also being classified as bulk yard minerals and charged a second decay. Exposed durable yard minerals retain modest handling loss rather than perishable overflow loss; organic, liquid and containment-dependent stocks retain storage constraints. Thirteen founding/craft/storage tests pass, including one-year finite flint survival, single-owner tool wear, repeated-day idempotence and perishable overflow. No free materials, knowledge, save-schema changes or player restart. Sparse-site campaign recovery still requires matched validation.


## September 21 — basic mixed forces and culture restore

Base `aef4f3c`. The AI can recruit researched, supplied archers to complement existing spear troops before learning coordinated-screen doctrine. Pending recruits count toward the bounded composition target; no people, equipment or doctrine bonuses are granted. Home reinforcement uses the same basic composition rule and checks actual position, preventing a stale home label from teleporting support. Doctrine benefits still require researched, rehearsed formations. Culture validation accepts finite whole-number days preserved by JSON as floats, while rejecting fractional, negative, nonfinite and nonnumeric days. Twenty-six recruitment, reinforcement, doctrine and culture restore checks pass, including binary/JSON roundtrips. No save schema change or player restart.


## September 21 — terrain-backed campaign diagnostics and checkpoints

The isolated daily pacing diagnostic can now use actual LocalTerrain water, land, material and route services (`--real-geography`) at a chosen globe position. It can write bounded campaign checkpoints every 25 years and at exit, resume them, and validate the binary save payload at completion. A two-day terrain-backed run plus one restored day matched an uninterrupted three-day run in every reported snapshot and bottleneck field; both save validations passed. No rendered test window, fabricated local water in terrain mode, or user save access. Terrain-backed isolated runs still do not include foreign contact or certify a whole player world.


## September 21 — geography-dependent subsistence and generated starts

Base `d12d669`. Daily food results retain the actual share of local labor producing food. Settlement management uses observed output/demand to maintain a subsistence allocation floor, with a reserve margin and room for other essential roles; higher yields release labor. Unknown ledgers keep the prior policy. Generated civilization candidates now require a generalist subsistence base (food potential, growing season and temperature), rather than equating dry land with a viable founding site. Player-directed later settlement is not restricted and no resources are granted. The diagnostic supports actual generated seat selection.

Forty-two government/local-provision checks and 49 founding/geography/subsistence/joint-operation checks pass. Thirty-six generated candidates across three seeds are deterministic and satisfy the founding filter. The pre-existing joint-construction fixture now expects the primary city's 80% share of workers, excluding the fixture's 20% satellite population; runtime construction accounting was already correct. No save-schema change or player restart. Full 300-year campaigns and actual starting-site survival remain validation work, not implied by these focused checks.


## September 21 — household inputs in production dependency checks

The structural supply audit now includes actual household recipes, with their real inputs and knowledge gates. Joined timber is therefore traced through tools and raw materials instead of being incorrectly reported as missing or being declared a free raw resource. Thirteen dependency tests pass, including missing-input and bootstrap-cycle failures. The full runtime graph reports no graph errors and structural reachability for 752 production/analytical routes and 28 plants across 883 discoveries. This assumes obtainable raw inputs and known methods; it does not certify research timing, finite supply, actual installation or campaign outcomes.

### First 300 years: prepared opponent formations
- Aligned foreign formation validation with the combat engine's existing 0–150% readiness range. Prepared armies no longer invalidate the world; nonfinite, negative, and above-cap values remain rejected.
- Validation: projection bounds and player independence suites, 9/9 passed (artifacts/foreign-readiness-tests.log). Actual-world probe rerun follows integration. No save schema change.


### First 300 years: household capital and recoverable building work
- Household crafts reserve finite, paid components for the first adopted local installation; small settlements can reach kiln setup quantities. Existing installations remove that extra demand. Secondary-city stores remain separate.
- A blocked kiln no longer suppresses other feasible building fabrication. Kiln heat and consumed timber now pass installation save validation, with bounded heat and negative-input rejection.
- Pacing evidence includes retained output totals by resource and settlement, so retooled lines do not erase measured production.
- Validation: 30/30 tests across opening crafts, building materials, kiln operation/save validation, settlement delivery and pacing evidence. A real-terrain year-50 checkpoint advanced one year: first kiln operating, fitted post/beam output 31 to 37, splice output 22 to 24, complete save validation passed (artifacts/capital-recovery-verified.json). Earlier cold-start and 300-year acceptance work remains separately tracked.


### First 300 years: physical research, ammunition and final-ground viability
- Generated founding sites now retain subsistence conditions after detailed ground sampling. Sixteen terrain seats pass food, temperature, growing-season and freshwater checks.
- Serving formations create ammunition demand against consumable stock. Orders use normal materials and work. A real year-25 military checkpoint advanced one year: both archers supplied with 12 arrows plus 6 in reserve; 18 arrows recorded as produced and save validated.
- Alumina refining requires chemical separation, pressure vessels, alkali chemistry and bauxite evidence; tin smelting requires ore evidence. The full structural research/production graph still has zero errors. No calendar grants or global research-rate changes.
- Civilization readiness summaries cap at 100%; combat readiness retains its existing 150% range. Older shared summaries repair finite positive overflow without changing the input payload.
- Validation: owned-civilization interaction/parity 19/19, projection bounds 9/9, workshop/persistent production 35/35, research gates 2/2, founding sites 3/3. Stale test inputs corrected for inherited knowledge, equal surveyed land, current production actions and settled recruitment visits. The separate legacy billion-population serialized-size threshold remains under review and is not counted as passing.
- Runtime checkpoint 71c569e. Actual-world 25-year and isolated 300-year campaigns remain in progress. No save schema change or player launch.

### First 300 years: material shortages and settlement adaptation
- Depleted surface fronts retain finite regrowth but no longer suppress a search for another real work site below the extraction working-reserve threshold. Well-stocked resources release more of the existing extraction/hauling allocation to scarce materials; no workers or stock are granted.
- Fractional extraction that produces material is no longer labeled as having no extractors.
- Expansion evaluates measured material cover and current shortages, replacing an unused forest-profile key. Three bounded distance rings include closer known sites that the single-ring search missed. Land, water, charted knowledge, spacing, convoy payment and ordinary city trade still gate settlement and delivery.
- Validation: 42/42 landscape, geography, expansion, city-resource and camp-material checks; 71/71 legacy civilization and initial expansion checks. The obsolete byte threshold now compares the identical world's serialized size before/after scaling population to a billion, then validates bounded records after a century; no runtime limit was loosened.
- A real warm-start checkpoint advanced from year 100 to 101: timber recovered from zero to 8.27; recorded runoff channels 28 to 43, post/beam sets 40 to 42, splice sets 24 to 26, plus first rope coils and thatch panels. Binary save validation passed. Cool-start material recovery is still being checked and is not claimed by this evidence.

### First 300 years: complete-world saves and physical founding kit
- Completed 25 years with the player and three opponents on actual terrain, seed 9241: all survived, zero civilization validation errors, owned and player binary save payload checks passed. Mean daily step was 116.9 ms in this headless workload. Evidence: docs/technology-review/pacing/first300-world25.json (runtime a3e997f, before later material adaptation changes).
- Generated starts require measured wood, stone and fiber catchments for the inherited generalist kit, alongside food, season, temperature and fresh water. Forty-eight real sites across three seeds pass; later chosen settlements may depend on trade.
- Intercity cargo is received before daily household/tool work and later workshops. Dispatch remains later and receiving twice cannot duplicate cargo. Thirty-three city-resource and owned-world checks pass, including daily imported-tool production and shared player/opponent balances.
- The retained treeless cool start recovered under f4cb449 by year 104: 36 equipped spears, 5 equipped bows, 30 arrows carried and 30 spare. The five-year continuation to year 105 completed and its save validated. This does not imply the same industrial path as wooded starts.

### First 300 years: repeated intercity store lookups
- Resolve each city's live store reference once per dispatch pass instead of repeatedly initializing its complete resource schema for every source/destination/good comparison. Earlier dispatches still debit the same dictionary seen by later destinations.
- Validation: 44 city, rail and siege checks pass. A 30-day replay of the same real year-100 checkpoint produces an exactly equal complete exported world before/after, with both binary saves valid. Phase timing was 1.270 s versus 1.152 s, but concurrent workloads made total wall time noisier; no broad speedup claim is made.

### First 300 years: matched decisions and current evidence ledger
- Added current readiness status and a reproducible five-year matched comparison at the same seed/terrain site. Makers and Military change research emphasis and actual output without resource grants; both complete and validate saves.
- New cool opening completes 25 years with 194 people, 25 known practices, 57 spears and 8 fitted post/beam sets produced. Twenty player-panel logic tests pass. Full 300-year endpoints remain pending; no completion or visual-review claim.


## First 300 years: whole-game continuation (September 21)

Saving and loading no longer reseeds the human research stream, inserts an explicitly absent lazy army template, or reranks civilization summaries outside their strategic update. The owned-world payload now retains the human projection so opponents see the same human state on their next day. Older payloads reconstruct the omitted projection before opponents advance. No stocks or discoveries are granted.

Validation: three new save regression cases pass (report 82), plus all 19 owned-world cases (report 81). An actual-terrain three-day player-plus-three-opponent probe restores its complete captured state exactly and produces an exactly equal next day after load, including research RNG and opponent relations. The earlier payload-only check did not cover this. A developed 25-year whole-world continuation run is in progress; the 300-year endpoint remains outstanding. Unique diagnostic save slots are removed after use; player saves are untouched.


## First 300 years: mounted archery foundations (September 21)

The long cool-start run exposed horse-archer equipment being manufactured from mounted scouting alone while bow craft—and therefore arrow production—was unknown. Mounted archery is now a separate practice requiring both mounted scouting and bow craft; equipment and horse-archer training use that practice. Ordinary scouting remains independent. Existing inventories are retained, but no missing practice is granted to old campaigns. The pacing evidence now includes mounted bows and their ammunition alongside foot bows.

Validation: three early research/material gate regressions pass (report 83), including scouting without bow craft being insufficient and completed mounted archery having an arrow recipe. The complete 884-entry graph has zero errors; 752 production routes and 28 plants remain structurally reachable. The consequence validator recognizes actual military catalog gates, with no artificial benefit added just to satisfy validation. Long campaigns will resume this runtime at their next recorded checkpoint; older mounted output remains labeled pre-fix evidence.


## First 300 years: repeated trade route queries (September 21)

Each city-trade dispatch pass now retains local population/position values and charted-route answers across cargo types. These caches end with the dispatch call, so later scouting and population changes are observed normally. Store references and transport balances stay live as dispatches consume them.

Validation: 30 city-resource and rail-freight tests pass (report 84). Matched 30-day continuations from the real warm year-125 checkpoint produce exactly equal complete owned-world saves. Measured city-trade time was 2.031s before and 1.961s after; total runtime was 9.64s versus 9.75s under concurrent audits, so no overall speedup is claimed. This removes repeated work without changing progression.


## First 300 years: military research explanation and combined regression (September 21)

A research entry with no numeric effect now uses its authored production contract before falling back to generic prerequisite text. Mounted archery therefore explains horse-archer equipment, arrows and maintained mounts. The education catalog count fixture includes the newly added practice.

Validation: all eight military education cases pass (report 87), including the new explanation check. The other six suites in report 85 passed all 111 cases across military development, training accounting, joint operations, civilization projection bounds, player independence and government people. The sole earlier failure was the corrected eight-versus-nine catalog fixture. This validates the combined checkpoint; long campaign endpoints remain in progress.


## First 300 years: daily adoption evaluations (September 21)

Capability evaluations now refresh their adoption profile each simulated day. Previously a monthly cached sample could differ after loading, when that unsaved cache rebuilt; this also left within-month progression percentages stale. No research or materials are granted, and all existing capability requirements remain.

The 25-year whole-world comparison restored its captured state exactly but exposed this next-day profile divergence. It also exposed a probe-only omission: the probe now rebinds the same opponent geography callables that the normal terrain scene reconnects after loading. The diagnostic retains its own explicitly named checkpoint alongside its report for repeatable investigation; unique user-save-directory test slots are still removed.

Validation: all eight progression and three whole-save regressions pass (report 88), including adoption changing within one month. The actual-world 25-year continuation is rerunning with the corrected probe and retained checkpoint; it is not yet counted as passed.


## First 300 years: workshop starvation and resumption (September 21)

AI workshops can now finish one paid ordinary batch before changing to another feasible needed product, rather than waiting forever for an intermediate stock target that households continually consume. One change is pending at a time; advanced trials, reserved materials, paused orders and player-controlled lines are protected. The ordinary commands still pay for tooling and all new output. A supply shock cancels the planned change and resumes the original line. Saved change requests are validated.

The player steward also recognizes its own idle pause and resumes that line when demand returns; manual pauses remain protected. Sewing chooses the hide alternative only when a complete hide/fiber batch is available, allowing a missing-yarn request when cloth is available but the hide alternative cannot run. This resolves the previously failing collected-bone/yarn regression without granting supplies.

Validation: 59 planner/steward/opening-craft cases pass (report 91), and five new turnover cases plus 36 inherited/steward cases pass (report 92). The real warm year-125 checkpoint reaches year 128 with a valid save, 192 equipped spears and 206 spare spears, 2,190 lifetime spears produced, and continuing runoff, post/beam, splice and textile output. Earlier continuation had locked both lines into textiles and lost replacement equipment. This recovery includes daily progression evaluation and the turnover fix; it is not yet a 300-year pass.

### First 300 years: delegated civilian investment

Player workshop management now considers the same real civilian infrastructure needs as opponent workshop planning: building fabric, water works, care, scientific equipment and later industrial facilities. The recommendation chain is shared; orders still use normal material charges, construction labor and knowledge gates. Manual scheduling remains off when disabled, and manually controlled lines remain protected. No new save fields or free stock are introduced.

Validation: workshop and civilian supply suites passed 53 checks; the expanded workshop suite passed 38 checks including paid shade components and a kiln commissioned, charged and left under construction (not instantly installed). Power investment passed all 12 checks after its isolated daily fixture included the production turnover phase used by the live controller. This closes a player-versus-opponent planning omission, not a claim of completed 300-year validation.

### First 300 years: delegated batch handoffs and developed-save replay

A delegated player workshop can now finish one paid ordinary batch and change to another needed product when continual consumption prevents its stock target from ever being reached. Trials and reserved work are excluded. Manual lines are excluded; changing a target or pause cancels the scheduled handoff, and disabling management cancels pending handoffs while existing orders continue. AI behavior retains the same batch boundary. The existing validated optional job field is reused; no new save migration is required.

Validation: 57 workshop, turnover and power-investment checks passed. A real 25-year player-plus-three-opponent world on commit 9572808 completed without simulation errors, restored exactly, and produced exactly the same next-day state after loading. Compact evidence is in pacing/first300-world25-continuation.json. The long isolated audit now supports --verify-restore and passed exact restoration and next-day replay on the year-128 warm campaign. The full-world probe can resume a named diagnostic checkpoint through a unique temporary save slot, enabling subsequent checks without touching player saves. The 300-year endpoints remain pending.

### First 300 years: ordinary food forecast cost

Ordinary food forecasts use local numeric arrays while preserving each projected day's arithmetic, spoilage and consumption order. Nutrient, botany and refrigeration forecasts keep their existing paths. In a 30-day replay of the 20-settlement year-128 warm campaign, full world state was exactly equal before/after; runtime was 9.099 versus 8.778 seconds (3.5%), with secondary consequence time 2.545 versus 2.213 seconds. This single comparison is not a general frame-rate claim. All 69 crop nutrition, botany, food batch and technology-operation checks passed, and developed owned-save next-day replay passed. No save fields or balance values changed.

### First 300 years: population read stability

Population normalization now preserves already conserved age and sex totals within floating-point summation noise (relative 1e-12). Actual population changes still rescale cohorts. This prevents save loading or repeated population reads from gradually changing fractional demographics. No save-format change or grant of people is involved.

Validation: two read-stability checks and 23 demographic, monthly scope and full-save checks passed. The save test now resets its military fixture rather than inheriting another suite's incomplete force dictionary. The actual year-30 world, resumed for three days, restores exactly and advances identically after loading. The preceding five-year continuation also recorded the player's first fitted beams (13) and timber splices (2) under the shared civilian planner. Compact evidence: pacing/first300-world30-recovery.json. The full-world diagnostic is continuing toward year 300; this is not an endpoint claim.

### First 300 years: resumable full-world endurance check

The headless full-world probe can retain a private checkpoint every requested interval and repeat an explicitly selected century ambition through ordinary commands. It continues actual daily simulation; it does not advance the calendar without economic, demographic and research work. The year-30 checkpoint/resume smoke check passed, including exact whole-state restoration and next-day replay. The live player-plus-three-opponent run targets day 109500 with makers renewed at ordinary century choices and checkpoints every 25 years. No endpoint result is claimed yet; diagnostic saves remain untracked.

### First 300 years: keep planned workshop handoffs through routine reviews

Routine AI and delegated-staff target reviews now leave a pending paid-batch handoff intact. Explicit player changes still cancel it. This prevents changing demand from repeatedly resetting a scheduled switch before the current batch finishes. All 46 workshop and turnover checks passed, including both routine review and manual override paths. No save-format change.

### First 300 years: expose stalled workshop inputs in endurance evidence

Annual diagnostic records now retain civilian line status, pending handoffs, crafting workforce and production labor share. The isolated audit accepts a checkpoint interval override so ongoing runs can retain yearly checkpoints. These diagnostics do not change game state or balance. A year-54 cold checkpoint loaded and passed exact state restoration and next-day replay. The woodland replay identifies both workshops waiting on manufactured inputs while a pending handoff waits for its input-starved batch to finish; recovery remains under investigation.

### First 300 years: recover workshops blocked on their own manufactured inputs

A managed ordinary batch that cannot finish because its input is missing can now be set aside while the line changes products. Paid progress and the exact recipe are retained in a bounded per-line suspended-batch record and restored once when that recipe returns. Setup tools remain paid; missing setup and remaining batch inputs still cost normal materials. Reserved work, trials and manual lines remain protected. Existing saves need no migration; the optional suspended-batch data is validated, including rejection of recursive or invalid progress records.

Validation: all 60 workshop, turnover and power-investment checks passed, including binary save/load, exact partial-work continuation and no duplicate goods or material refunds. Replaying the real stalled woodland seat from year 125 through 126 produced 45 additional prepared fibers, 31 yarn, 24 spears, two runoff components and one thatch panel versus the stalled replay. It retained 228 equipped spearmen and 235 spare spears. Both exact restoration and next-day continuation passed. Evidence: pacing/first300-starved-batch-recovery.json. The recovered seat continues toward 300; this is not an endpoint claim.

### First 300 years: default twelve-opponent opening

The real-terrain default setting (player plus 12 opponents, seed 9241) completed 365 ordinary days with no waterless generated starts or reported simulation errors. Player and owned payload checks passed; whole-game restoration and next-day continuation were exactly equal. Mean headless day cost was 223.4 ms under concurrent audit load. This is a first-year default-configuration check, not a claim of default-count 300-year or rendered performance verification. Compact evidence: pacing/first300-default12-opening.json.


### First 300 years: maintain government succession across generations

The 96-person government limit now applies to serving officials rather than all historical records. Deceased officials retain their IDs, biographies and references, while new candidates and normal succession fill vacancies without creating population. Actual warm and woodland checkpoints had reached 96 records and zero serving officials; a short warm year-157 recovery restored 88 serving officials for its 32 settlements. Exact save restoration and next-day continuation passed. Evidence: pacing/first300-succession-recovery.json. No save-format migration or player restart.

Endurance reports now include serving and historical official counts and all equipment categories, including pikes previously omitted from the summary. Contact-test fixtures now include the current clay-testing foundation, distinguish incoming collection rewards from outward practice sharing, and retain accumulated culture across a century boundary. They also reflect the existing 14 ambitions and automatic appointment of established specialist offices; these are test corrections, not changes to those game rules.

Validation: 65/65 scholar, society-exchange and paid-research checks passed; the final focused government, century-choice, save-continuation and evidence run passed 52/52. Existing general-campaign, diplomatic-journey and commitment runs passed 31/31. The long campaigns still require their 300-year endpoint checks.


### First 300 years: avoid rebuilding fixed construction rules for every plot

Construction prerequisite checks reuse the fixed authored definitions, while testing current knowledge on every call. No society eligibility, stock, adoption or building state is cached. This removes repeated catalog construction in maintenance planning across settlements. The same real year-157 checkpoint with 32 settlements advanced 30 ordinary days in 16.607 seconds before and 13.834 seconds after (16.7% reduction under concurrent audit load); mean city-trade time fell from 153.26 to 77.72 ms/day. The complete exported world states are exactly equal, and both save/next-day checks pass. All 20 building delivery, acquisition, specimen, partnership and operations tests pass. No save change or rendered performance claim. Evidence: pacing/first300-fabric-definition-performance.json.


### First 300 years: preserve explicit empty observer views and compare 75-year choices

Owned-world import now rebuilds the human observer view only for legacy payloads that omit it. An explicitly empty saved view stays empty, preserving isolated campaigns exactly. The legacy rebuilding behavior is still tested. Four save-continuation checks pass; both unchanged matched year-75 endpoints now restore and advance the next ordinary day with exact equality.

Fresh same-seed, same-terrain runs on 9d1b91d differ only in ordinary Makers/Military ambition. Makers produced 77 fitted post/beam sets, 38 splice sets and 476 spears; Military produced 64, 28 and 308 respectively, plus 137 bows, 107 arrows and 80 pikes. Military fielded 17 archers and eight pikemen alongside spearmen. Both reached 75 years, maintained full current food intake and knew 61 practices with different identities. This establishes a meaningful choice effect, not a 300-year completion claim. Evidence: pacing/first300-matched-decisions-75.json.


### First 300 years: prioritize useful gathering when stores overflow

Finite extractors and carriers now reduce effort on unused materials whose local storage is overflowing. Basic building/household materials, explicit player priorities, active production inputs and operating installation inputs remain protected. Small samples remain available; known civilian recipes retain twice their startup-and-first-batch input requirement, so saving storage cannot prevent starting a newly learned craft. Recipe metadata is fixed; society knowledge, local stocks, orders and storage are evaluated live. No stocks, deposits, workers or output are granted, and saves need no migration.

The actual cold year-131 checkpoint advanced the same 365 ordinary days before and after. The final version produced 38 additional spears while preserving bows/arrows and other recorded output. Timber remained scarce: this improves allocation without erasing environmental limits. All 31 landscape/local-material tests pass, including finite extraction, delayed hauling, samples, active/paused orders, fulfilled targets, installations and craft startup buffers. City, owned-world and early-research suites also passed (36 checks across the resource/save validation run, excluding its separately corrected observer fixture); final save restoration and next-day continuation are exactly equal. Evidence: pacing/first300-gathering-priorities.json.


### First 300 years: use the game terrain provider in endurance harnesses

Both headless harnesses now bind the same stable surface-material provider already used by the game. This enables the existing safe catchment-search cache rather than repeatedly generating full geography reports. An actual military year-175 checkpoint advanced 30 ordinary days in 41.080 seconds before and 16.338 seconds after; the entire exported world states were exactly equal. Save restoration and next-day continuation passed in both. A player-plus-three-opponent checkpoint at year 87 also advanced and passed complete save/next-day equality with no state errors. These are harness parity and timing checks, not a new game rule or rendered performance claim. The full-world probe also retains an earlier checkpoint failure rather than clearing it during final validation. Evidence: pacing/first300-terrain-provider-parity.json.


### First 300 years: reuse eligibility within one building-upgrade decision

Choosing one retrofit now checks its unchanged knowledge, adoption and component availability once before comparing plots, retaining authored method order and existing tie behavior. Repair payment computes its unchanged bill once. No eligibility persists across calls. The same 33-settlement military checkpoint advanced 30 ordinary days in 16.338 seconds before and 12.599 after; whole exported world states are exactly equal. All 20 construction checks and exact save/next-day checks pass. This is a single headless timing pair, not a frame-rate claim. Evidence: pacing/first300-retrofit-selection-performance.json.


### First 300 years: civic/exploration verification and current evidence guide

All 69 civic implementation, administration, answers/alerts, culture-effect, scouting-staff and route-planning checks pass on be3a3ad. The pacing assessment now separates current evidence and remaining endpoint checks from archived development observations, including the superseded construction-labor failure. A fresh current-build 300-year campaign and a default twelve-opponent 25-year run are active alongside the recovered endurance campaigns. No endpoint completion or visual verification is claimed.

## 2026-09-21 — Correct government evidence labels

The pacing report previously called every active named government roster member a serving person, including candidates without a post. Separate distinct officeholders, central posts, settlement leaders and unappointed candidates; retain a distinct count of all recorded people. Schema 16 documents the meaning of older snapshot keys. A direct read of the cold year-155 checkpoint confirms 90 active records means 36 distinct officeholders and 54 candidates across 33 settlements. This changes reporting only; saves, population, labor and succession behavior are unchanged. Validation: pacing production evidence suite, including dual-role and inactive-person counts.

## 2026-09-21 — Validate recorded research foundations

Five actual campaign checkpoints verify 640 chronological discovery origins against knowledge already learned, beginning with ten inherited practices. Zero missing origin records or unmet recorded foundations; current alternative routes also satisfy all learned discoveries. The initial scratch audit incorrectly treated local-route requirements as universal. River craft and clean-water practice used valid alternatives. No gameplay restriction was added. Evidence excludes historical signal strength, physical manufacturing and unfinished 300-year endpoints.

## 2026-09-21 — Locate the player correctly in rival contact queries

An actual default-count year-14 checkpoint showed civ_01 reporting the human homeland at civ_01's own origin on day 31. Human projection copied its normalized position from a rival template; updating world_position alone did not affect the normalized-coordinate lookup used by scout contact and routing. Refresh now derives both coordinates from the actual player origin, including relocation. Five campaign save/location checks pass, covering distant non-contact, arrival near the actual player, exact save/next-day continuation, and legacy/empty projections. No save fields or population change. Existing historical encounter records are not erased; default-count contact validation restarts fresh, and the resumed full-world campaign is recovery evidence. Isolated campaigns contain no foreign contact and are unaffected.

## 2026-09-21 — Cold material-priority decision comparison

Actual cold year-161 checkpoint replayed one year with the normal UI High timber priority value. Compared with the unchanged annual checkpoint: 175 additional spears, 11 additional lances, zero additional civilian goods; identical population and full food intake. Exact restore and next-day continuation pass. This exposes a remaining civilian startup bottleneck rather than completing the release gate. Recorded in the current pacing assessment. Separately, fresh corrected default-count year 1 has no false human contacts while civ_03 and civ_12 establish physical contact.

## 2026-09-21 — Review civilian investment when supplies arrive

AI monthly investment now rechecks after actual material arrivals, before recurring food and military spending; delegated player workshops use their existing paid scheduler at the same point. Disabled management and manual orders retain their existing protections. No materials, labor or knowledge are granted; no food requirement is reduced. Cold year 161–162 produces 53 drainage components that the baseline never starts, with two fewer spears, identical population/full food intake, and exact save/next-day continuation. 39 AI planning/owned-world/save checks and 46 player workshop/save checks pass. Save format is unchanged. Full endurance endpoints remain pending; updated runs must record this runtime transition.

## 2026-09-21 — Unique settlement leadership and late-network staffing

Explicit local-leader transfers now clear the former settlement reference; ordinary reconciliation appoints its successor and repairs stale duplicate references in older saves. Automatic succession no longer borrows a leader already assigned elsewhere. The ordinary candidate pool remains capped at 96, expanding only when actual settlement and central posts need additional people, with four successor places and a hard 288-person bound covering the supported 256 settlements. Population remains aggregate and unchanged by appointments; historical people remain recorded. All 60 government, civic-administration and whole-save checks pass, including all 256 local posts, transfer, stale-reference repair, mortality and output continuation (report 130). Separately, 155 assignments across five actual archived campaign checkpoints had no duplicate, deceased or mismatched local leaders. Endurance endpoints remain pending and runtime transitions must be recorded.

## 2026-09-21 — Scouting route cache respects changing travel range

The default twelve-opponent year-25 run reached day 9125 and restored exactly, but its next day differed: a restored opponent dispatched an extra scout party and spent 99 additional food. Standing-scout route cache keys omitted travel range, although logistics, travel knowledge and mounted adoption change that range. The cache now includes the exact range. A regression test first reproduced different cached/rebuilt routes after changing logistics and now passes; all 38 scouting, route-planning and campaign-save tests pass (report 132). The actual year-25 checkpoint now restores and advances with exact equality. A longer replay with a populated runtime cache remains required before the default-count endurance check is signed off. No save schema change or resource grants.

## 2026-09-21 — Default twelve-opponent year-25 validation

The actual year-20 checkpoint replayed through day 9125 on the corrected scout-range cache, then passed exact whole-save restoration and next-day continuation with zero state errors. All twelve opponents retain full current food intake, population and production; scarce food reserves correctly block some discretionary production. Human contact remains absent at this distant start, while nearby foreign contacts persist. Endpoint evidence and runtime provenance are recorded in first300-default12-25.json. The 300-year runs remain incomplete; this closes only the default-count 25-year check.

## 2026-09-21 — Hydrogen-flame research requires hydrogen knowledge

An older warm campaign learned hydrogen-flame glassworking with only glass-tube drawing and distillation. The research gate now also requires either water electrolysis or chlor-alkali cells, preserving both modeled hydrogen supply routes. Actual manufacturing continues to consume hydrogen and paid tooling. The regression failed before the correction; all 19 glassworking/crop-nutrition tests now pass, including live learning-path eligibility and both alternatives. The complete live graph remains structurally valid, with 752 products and 28 plants reachable under the audit's stated assumptions. Older learned knowledge is preserved; historical foundation evidence is labeled with its pre-correction catalog. Fresh final-build endurance validation remains required.


## Saved campaign map opening — 2026-09-21

The terrain scene was recalculating the seed's current starting candidate every time it loaded, even when the campaign already had a founded settlement. That could move the local origin and opening camera away from saved settlement geography. The scene now opens at the saved founding site (or a resumed unfounded caravan's recorded position). Only new campaigns choose a seeded start. The opening camera uses the existing 10,000-foot preset immediately rather than a 190-km vertical footprint.

Six camera tests pass (GdUnit report 136), covering saved settled and traveling origins, opening distance, cumulative zoom and the four distance presets. A read-only scene-load probe of the player's day-29027 quicksave placed the saved city at the screen center with zero horizontal camera displacement and approximately 10,007 feet of clearance (the marker's small terrain offset explains the difference from the nominal preset). No save data is rewritten. This is camera projection validation, not a claim of rendered visual approval. The running player session must reload after integration; it is not terminated by this fix.


## Optional meal fuel and workshop startup reserves — 2026-09-21

A one-day trace of the stalled cold campaign showed household food processing consuming every delivered Timber unit before construction and workshops. Its earth-oven cooking bought only a 0.001324 diet quality bonus with the remaining 0.4672 Timber. Optional meal preparation now respects the gathering system's existing reserve for known craft inputs, including when supplies change between planning and cooking. It still pays for every prepared ration. Meal intake, preservation, fire maintenance, and their separate material costs are unchanged.

The 30-day pilot resumed 21 bows and 17 simple levy weapons, with full current food intake and exact save/next-day continuation. Civilian output did not increase: that allocation problem remains open. See `technology-review/pacing/first300-meal-fuel-recovery.json` for the pilot's scope and its small final-rule difference. City-reserve reduction and disabling the kiln had not restored civilian output and were rejected; neither experiment is part of this change.

Validation: 22 food-preparation and whole-campaign save tests pass (GdUnit report 141), including both new reserve regressions.


## Civilian orders at delivery time — 2026-09-21

In the cold day-67891 trace, a drainage-component order became affordable after materials arrived, but the AI skipped it because its monthly strategy review was not due. Societies with no unpaused civilian line now review civilian investment after arrivals between monthly reviews. Existing civilian lines keep the broader monthly review; hunger, war, manual-order and paid-tooling guards remain intact.

29 planner, workshop-turnover and whole-campaign save tests pass (report 142). The same stalled checkpoint produced six drainage components over 30 days; the meal-fuel fix alone produced none. Both runs kept full current food intake and exact save/next-day continuation. This proves a short recovery, not the final 300-year gate. Evidence: `technology-review/pacing/first300-civilian-arrival-review.json`.


## Ammonia catalyst research foundations — 2026-09-21

The woodland recovery campaign learned iron ammonia catalysts around year 194 and industrial catalyst design around year 196. The catalyst inquiry required ironworking, experimental controls and distillation but no source of either reaction gas. It now also requires the existing pressure-vessel and nitrogen-separation foundations, plus either modeled hydrogen-production route. This closes the demonstrated early ammonia route into industrial catalyst design without a calendar lock. Already learned discoveries remain in saves; no operating production or resource stocks are granted.

All 14 crop-nutrition tests pass (report 143), including live inquiry checks for missing nitrogen, hydrogen or pressure control and both valid hydrogen alternatives. The full 884-discovery/670-route graph has no errors or blocked manufacturing paths. Evidence: `technology-review/pacing/first300-ammonia-foundations.json`. Ongoing endurance runs retain their earlier catalog histories and are not fresh proof of the corrected gate.


## Sub-minimum food-processing output — 2026-09-22

The cold endurance campaign reported two script errors near year 243 when baking accessed `observations` on an empty output. A source amount just above the minimum batch size can yield bread below that minimum. `add_lot` then declines the output after the source has already been withdrawn. Food processing now checks its smallest output before withdrawal, starter consumption, fuel use or labor charges. This covers baking, dough forming, starch/residue separation, cultures, leavening and assays. Tiny remainders stay in their source lot for ordinary consumption or decay; there is no resource grant or save-format change.

All 31 food-batch tests pass (report 144), including six tiny-output paths that preserve source food and supplies, plus existing conservation, processing and binary-save continuation checks. The prior cold run's error-bearing segment remains evidence of the defect, not a clean validation result. Campaign checkpoints are retained for continued validation with this fix.

## September 22 — reuse installed tools when a paid input chain stalls

A warm campaign reached day 109500 with exact restoration and next-day continuation, but its civilian yarn workshop had stalled despite raw fiber and water. The planner counted installed tools only on finished lines at full capacity. A partially paid yarn batch, and later an unused line slot, therefore made it demand new timber/clay tools that were already installed.

The planner now recognizes tools on eligible managed batches that can be set aside. The controller reuses an equipped line when a new line cannot afford its setup, even with spare capacity. Existing turnover preserves paid work; paused/manual player work and specialized trials remain protected. No supplies, knowledge or output are granted; save format unchanged.

Validation: 25 planner/turnover tests pass, including the paid-work regression. Thirty ordinary days from the actual year-300 checkpoint produced 13 additional Prepared Fibers, 3 Spun Yarn and 17 pikes; exact save restoration and next-day continuation pass. See `technology-review/pacing/first300-installed-tool-recovery.json`. This closes the demonstrated input deadlock; low building condition and the remaining campaign endpoints are still under review.

## September 22 — surveyed replacement sources for exhausted common materials

The warm year-300 campaign had exhausted clay across all 39 settlements; domestic shipments could not supply absent reserves. Ordinary exploration previously excluded this recovery path and dedicated prospecting listed only rare ores/fuels.

Returned exploration now checks depleted common sources (clay, flint, limestone and fine sand); dedicated resource prospecting also includes these materials. Reports use suitable route terrain, and owned-world discoveries resolve against the same location-keyed finite geology used by settlement surveys. Already surveyed/exhausted occurrences are not duplicated. Surveying adds no stock, access, tools or hauling capacity. Founding/surveying another society's cell now preserves its existing shared reserve instead of resetting it. Existing save fields remain compatible.

Validation: 29 focused scout/shared-geology checks pass (report_150), including unsuitable ground, finite replacement clay, no stock grant, no duplicate return and no refill by another society. Nineteen existing owned-civilization checks also pass (report_149), covering save/restore and shared resources. These checks establish the recovery mechanism, not proof that the old year-300 campaign has already restored its buildings. Remaining campaign validation and military-versus-maintenance allocation are still pending.

## September 22 — isolated campaign audit now advances scout returns

The isolated history harness advanced the economy but omitted `CivilizationSystem.advance_to_day`, which the normal owned-world day calls. This left staff policies set but no expeditions dispatched or returned. The harness now calls that lifecycle step in both the campaign and exact-continuation replay, and records scouting status in snapshots. Earlier isolated runs are economic endurance evidence, not full scouting/prospecting progression. The full-world harness already uses the complete day.

Validation: resumed the actual warm campaign at day 109865 for 90 ordinary days. Eight scout reports returned, five parties remained active, recorded deposits rose from 88 to 101, and paid production added 75 drainage components, 411 prepared fibers, 406 yarn and 85 bows. No logged errors; exact restoration and next-day continuation pass. See `technology-review/pacing/first300-scout-supply-recovery.json`. Timber-dependent repairs and remaining endpoints are still pending. This is a test-harness correction, with no player-game or save-schema change.

## September 22 — restored order history no longer aliases the save snapshot

The seed-91420 campaign stopped at day 83936 with exact next-day simulation but a failed immediate-restoration comparison. `_restore_state` assigned the caller's order array directly to the live actor; subsequent commands mutated the retained input save. Restoration now deep-copies order history. No commands, dates or history are discarded and the save schema is unchanged.

Validation: 20 owned-civilization/save tests pass (report_151), including reusing a saved snapshot after submitting new commands. The actual day-83936 checkpoint advanced to 83937 with valid saving, exact restoration and exact next-day continuation, using the corrected scouting lifecycle. The earlier failed comparison is retained as defect evidence; it is not a passed endpoint.

### Supply-bounded automatic military intake (2026-09-22)

Automatic recruitment and local-watch training now use equipment left after serving formations and pending training, bounded by instruction places. The watch uses waiting recruits before mobilizing new civilians. Workshop staff request equipment before new watch intake, and include pending instruction in demand. AI controllers return excess waiting recruits to civilian life without disbanding serving formations. Player-ordered training remains available. No save-schema change or free gear.

Validation: 56 focused tests passed across intake, combined arms, armor, controller strategy, military development and delivery recovery. The existing armor-chain test omitted ordinary workshop turnover; baseline and changed controllers reproduced the same failure, and its fixture now advances that lifecycle step. The combined-arms fixture now supplies the instructors required for its 30-person batch; strategy comparison supplies matching gear.

Actual year-300 military checkpoint continued for 30 ordinary days: waiting recruits 10,046 to 3; home troops retained at 17,907; food intake 100%; state validation, exact restore and next-day replay passed. Equipment fell from 2,103 to 2,073 and existing trainees remain: replacement supply is still unresolved, so this is not full military readiness. Evidence: `technology-review/pacing/first300-military-intake-recovery.json`. Earlier history used the isolated economic harness; corrected scouting runs during this continuation.

### Ordinary managed weapon repairs (2026-09-22)

The year-300 military recovery save held 82,797 damaged weapons. Automatic repairs previously required specialist field-repair companies even though ordinary manual workshop repairs were available. Managed weapon lines now spend their existing allocated workshop time on repairs first, using the established 18% material and 38% work costs. Damaged items and materials are reserved, unfinished manufacturing remains intact, manual/paused lines are protected, and cancellation returns unfinished damaged items without refunding spent inputs. Specialist repair companies retain their existing behavior. Repair receipts have a distinct kind; line status and progress show repair work. Existing saves need no migration; pending repairs are stored with the line.

Validation: 47 unique focused tests across repair, persistent production, specialist field repair, armor and intake passed. Actual 30-day continuation repaired 22 improvised weapons and manufactured 2 new ones, with state validation, exact restore and next-day replay passing. Food intake stayed at 100%. Equipped count still declined 2,073 to 2,064: timber supply remains insufficient for wear and this is not full readiness. Evidence: `technology-review/pacing/first300-managed-repair.json`.

### Remaining timber constraint: geography and export reserves (2026-09-22)

Read-only trace of day 109560 on f5cdab4 with the original real terrain seed confirms no additional qualifying timber front near the capital (local cover 0.00725). Nearby towns hold roughly 70–80 timber but their population-based export reserves require hundreds to thousands; Greenbank alone is above its reserve and sends a small flow. This is distinct from the repaired intake/repair bugs. Evidence: `technology-review/pacing/first300-timber-trade-diagnosis.json`. The next policy check must protect real local building/workshop needs while permitting useful intercity supply. No reserve or regrowth rate change has been validated.

### Local material commitments replace population-scaled export hoarding (2026-09-22)

Non-food intercity export reserves now retain a 20-unit local buffer or the greater identified local bill: eligible unfinished civic construction, the unpaid portion plus next batch of active workshop lines, and 30 days of installed industrial inputs. Primary workshops/plants do not reserve inputs in unrelated secondary towns. Existing water/clothing targets, 45-day food reserves, known routes, carrier capacity and delivery delays remain enforced. No free resources, regrowth changes or save migration.

Seventeen focused city-resource/reserve tests passed. The actual military recovery save advanced from day 109560 to 109590: equipped weapons rose 2,064 to 2,592; civilian output gained 21 drainage components; food intake remained 100%; state validation, exact restore and next-day replay passed. Evidence: `technology-review/pacing/first300-material-reserves.json`. A longer continuation is still required to establish sustainable recovery beyond redistribution of existing stocks.

### Supply endurance failure and recoverable fuel roundoff (2026-09-22)

The 365-day continuation on 75f9fdb reached day 109955 but did not sustain military supply: equipped weapons declined 2,592 to 2,192 with no additional military workshop output. Civilian drainage output rose by 69 and food intake remained 100%. Initial redistribution is therefore insufficient; this does not pass the military readiness gate. The original endpoint save check also failed on a negative near-zero timber balance. Evidence: `technology-review/pacing/first300-supply-endurance.json`.

Smoking and grain-parboiling fuel withdrawals now clamp their paid remainder to zero after fuel-limited arithmetic, preventing floating-point undershoot. Owned-civilization saves normalize negative material residue no larger than 1e-9 on a copied restore payload; larger overdrafts, nonfinite balances and malformed values remain rejected. No actual inventory is granted. The original rejected checkpoint remains unchanged. It now loads, advances one ordinary day to 109956, and passes exact restore/next-day replay checks. Seventy-one focused food/batch/owned-save tests pass, including sub-unit fuel arithmetic, input immutability and rejection of real overdrafts/NaN. This correction does not resolve the ongoing allocation/supply shortfall.

### Food processing fuel reserves
Automatic food batches (including grain parboiling and drying) and smoking now honor the existing known-craft timber reserve, matching optional meal preparation. Fuel costs remain charged; no material is generated. A daily trace at day 109956 showed parboiling consuming all 0.339 available timber after basic fire use despite 226 days of food reserves.
Validation: 52 food processing/preparation tests, including reserve regression coverage. The existing baking fixture supplies fuel above the reserve. Actual military campaign probe reached day 109986 with valid save, exact restore, and exact next-day continuation. Equipment declined from 2192 to 2164: this change protects craft inputs but does not establish sustainable military production or 300-year readiness. No save schema change.

### Household/workshop input sharing
Household crafting ran before workshops and consumed all scarce timber, even when an active workshop order needed it. It now leaves a share of actual unpaid recipe inputs proportional to existing workshop versus household crafting labor. Surplus inputs remain available; paused orders, met targets, and secondary settlement stores are excluded. No free resources, changed recipes, or save schema changes.
Validation: 11 household/opening-craft tests passed. Actual seed 91420 real-geography military continuation, days 109986–110016: equipped weapons 2164 → 2302, 167 improvised weapon output/repair receipts, food intake 1.0, valid save and exact restored next-day continuation. Sustained supply remains unproven; see first300-household-input-sharing.json.

### Civilization-wide Overview
The Overview rail entry, F1, and population shortcut now open a civilization dashboard with 15 metric cards and a clickable settlement list. Local map/city views retain settlement leadership and history. City deficits are listed first; food and water show the lowest reported reserve, shelter is counted locally before aggregation, and missing social reports are excluded from weighted averages. The screen refreshes from current state and includes founding/travel access before a city exists.
Validation: five targeted tests cover secondary shortages, material aggregation, non-pooled shelter, preserving selected city/stores/population, live content updates, city navigation, 700/1200-wide panel layout, and carried supplies before settlement. No save-schema change; campaign endurance testing remains paused. Visual approval remains with the user.

### World dashboard — 2026-09-22
Replaced the narrow Contacts landing page with a wide responsive World overview: known societies and located diplomatic destinations, active scout parties, returned-report totals, rumor leads, and directly readable recent findings. Empty contact states retain useful expedition and report actions. Existing expedition archive, dispatch confirmation and standing review remain available. Expedition dates use years and days rather than raw elapsed-day counts. No simulation or save changes. Three headless checks pass (report_171): archive navigation, 700/1200-width layout, returned finding navigation and live signature updates. Player visual review remains with the user; no running game interrupted.

### Civilization-wide top bar — 2026-09-22
All six headline indicators now use a shared civilization aggregate, independent of the selected settlement. Output and research sum controlled-city contributions; food/water reserve days divide combined stores by combined daily requirements; health and education are resident-weighted. Hover panes list each city, including production, demand, reserve days and shortfalls; missing daily reports remain explicit. Local shortages remain visible on the headline even with ample total reserves. No simulation/save changes. Six targeted KPI tests pass (report_172), including unequal city reserve weighting, selection invariance, state restoration, per-city breakdowns, missing reports and panel construction. Visual review remains with the player.

### Routine military upkeep — 2026-09-22
Ordinary workshops automatically reserve and repair damaged gear without a player repair order or a specialist field-repair company. Upkeep remains active when discretionary production scheduling is manual. Existing active managed lines retain their cheaper repair-first behavior; otherwise a bounded paid repair batch is scheduled, with completed idle staff lines yielding capacity safely. Manual lines, unfinished paid work, knowledge gates, inputs and workshop capacity remain respected. Production's repair action is now a read-only upkeep report including repairs underway; the legacy military screen no longer presents a repair-order button. No new save fields are required; existing repair orders continue. Ten focused tests pass (report_175), covering new manufacture and repair reaching unequipped levies, paid inputs, duplicate reservation prevention, completed-line turnover, status UI and existing managed repair conservation. The inherited broad workshop suite exposed stale assumptions about no standing-watch demand and civilian-first scheduling; its files were left unchanged, and it is not claimed passing. The player's live save was not inspected or interrupted.

### Great undertakings: first 300-year slice — 2026-09-22
Buildings gains an Undertakings tab with twelve authored candidates; stable seed/site selection and population, research and environment gates prevent every campaign offering the same list. Authorization starts real local material and builder consumption. Careful versus pressing policies affect shortages and labor diversion; local leadership skill, cohesion and craft capacity affect workmanship. Projects can stall, be abandoned, complete as failures, operate with condition-scaled local work benefits, decay, and gain enduring or costly reputations. Physical first-pass map forms retain unfinished and ruined states. Records live in existing settlement saves and receive load validation. Legacy saves default to no projects.

Twelve focused checks pass in report_179 (six undertaking and six existing KPI checks), covering input conservation, labor diversion, daily idempotence, hardship, failure, decay, opportunity variation, record serialization, invalid data, authorization, scope restoration, map nodes and UI loading. These do not constitute a 300-year balance or visual-quality certification. The long campaign audit remains paused and no player session was touched. Art specification and concept diagram: docs/art/UNDERTAKINGS_IMAGE_BRIEF.md and docs/art/undertakings-map-study.html. Finished art, production recognition emblems, terrain-aware site placement, autonomous leader proposals, sponsorship disputes, restoration and type-specific hydraulic/storage mechanics remain explicitly unfinished; current benefits are modest local work modifiers.
Existing building settlement/history checks also pass: 3/3, report_180. Total scoped validation: 15 passing checks.

### Completed landmark naming — 2026-09-22
Completed undertakings can be named in their Buildings page; unfinished projects retain working titles. Names persist in the existing saved record, replace the map label, and survive later ruin. Completed failures may also be named. Input is limited to 60 printable characters with surrounding whitespace removed; blank/control-character names are rejected. The detail page now states the actual condition-scaled local work contribution. Seven undertaking tests pass, report_181. Civilization-wide attraction, diplomatic reputation and legacy victory rewards remain design proposals, not implemented effects.

### Food headline total correction — 2026-09-22
Food reports now explicitly expose combined edible stocks. The top bar uses that total, with legacy food-days times daily demand as fallback, instead of treating processed food batches as the entire reserve. Seven KPI tests pass (report_182), including positive reserves with zero batches and genuine zero stocks.

### Live information bar (2026-09-22)
The command bar now refreshes its date and civilization totals every 0.75 seconds independently of legacy interface controls or report navigation. The terrain callback also updates the current HUD before checking for legacy controls. Eight KPI tests pass, including changing visible food/water/date labels without navigation and the total-food regression. Save format unchanged.

### Practical wonder rewards and victory (2026-09-22)
Undertakings now provide local storage, preservation, crafting/research effectiveness, household attraction and traveler-carried diplomatic reputation. Three diverse landmarks with twenty years of maintained operation and accounts reaching two foreign societies earn a persistent Enduring Civilization victory. Buildings and World expose the requirements. Optional save fields validated; 12 targeted wonder tests pass (report 184). See docs/UNDERTAKING_REWARDS.md for exact effects and remaining extensions.

### Remove resource-deposit road spokes (2026-09-22)
Removed the renderer that inferred a dirt road from every visible accessible/developed deposit. Each inferred road allocated its own mesh and material with 79 ribbon segments (474 vertices); the visual cost grew with known resource sites. Recorded settlement routes still render, and extraction/logistics state is unchanged. Source call-site verification confirms no remaining synthetic-resource-road generator. Visual-only removal; no save migration.

### Wonder landmark and progress pass (2026-09-22)
Worker C:/Users/sjpur/tt-overview-history, codex/first-300-playable, based on 8f79f93. New undertakings reserve deterministic sites checked against coast, relief, plot extents and neighboring landmarks; positions are saved and validated. Map forms use one vertex-colored mesh and a label per site, with cached rebuilds at visible construction/state changes. Pitched halls, granaries, kiln domes, orchards, terraces and dry basins replace generic repeated boxes. Existing legacy positions remain compatible. The panel now has construction/workmanship bars, current-pace estimates, maintenance/hardship/reputation figures and up to twelve lifecycle events. Fifteen targeted lifecycle/reward/site/mesh/cache tests logged passing; terrain script also loaded successfully in the first validation pass. Final authored scenes/emblems and player-directed placement remain outstanding. No player game was stopped or launched.

### Unified military home (2026-09-22)
Worktree C:/Users/sjpur/tt-overview-history, codex/first-300-playable, based on f48a672. All ordinary Military dock entries now route to the existing dark command shell, including legacy non-expanded recruitment/logistics links. Forces, embedded recruit/deploy queue and template editing, training policy, and live readiness/supply share its header and navigation. Map command preserves the military panel and returns to it on close. Manufacturing stays in Production; the supply report shows staff-managed repairs, including work underway. Navy/air readiness uses service forces rather than displaying home-army equipment totals. Sidebar now says Military. Authored GeneralCampaign conversations and specialized map/service command tools are retained; this is a consolidation of the main management pages, not a replacement of battlefield controls. No save schema changes or player restart performed.
Validation: four unified-screen tests pass with no errors/orphans (report 190), plus four logistics/Production routing tests (report 188). Repair totals include pending jobs as well as damaged stores.

### Explored-map navigation cost (2026-09-22)
Worktree C:/Users/sjpur/tt-overview-history, codex/first-300-playable, base da14f90. Terrain fog registration retained ShaderMaterials strongly after streamed patches were discarded; every frame updated the accumulated list. Terrain and vegetation now use a weak, deduplicated registry, prune retired entries during registration, and update uniforms only when the origin/texture changes. New materials initialize immediately; in-place mask texture updates remain visible without redundant binding writes. City map queries now apply their existing distance cutoff before deep-copying detailed reports. Five tests pass (report 191): 2,000 retired materials leave only the intentionally retained one; 600 unchanged updates issue zero uniform writes; near-city copies remain isolated; fog raster pixels are unchanged. No live-session FPS claim or exploration/save-data change. Restart required to clear the running build's retained material references.

## September 22 — save load after opponent population collapse

Fixed shared civilization map projections counting a minimum of one resident per settlement after a civilization shrank below its settlement count. Atlas populations now use unfloored settlement shares. Import reconciles only identifiable legacy shared projections with that one-person floor; authoritative demographic and settlement records remain unchanged, and unrelated invalid population data remains rejected. Startup logs now include nested validation details.

Validation: the current player quicksave reopened successfully in a headless worker (day 20221, population 287); save size and modification time unchanged. Twelve projection regression tests passed, zero errors, failures or orphans (report 193), including declining two-town population conservation, legacy summary compatibility, and unrelated overflow rejection. No graphical launch or user-session interruption. Scope is this load failure, not the underlying causes of opponent decline.
## September 22 — navigation priority and coherent terrain transitions

Stopped downgrading completed terrain/water to preview grids during subsequent pan/zoom builds. Cold coverage starts at 129 rather than 33 samples per axis, followed by final detail. Zoom requests target the destination span, small anchor drifts retain in-flight work, and panning inside installed coverage avoids rebuilding. Cached close terrain waits until it covers the camera before replacing wider coverage. Existing final resolution, height authorities, mesh/sample cache bounds and water/terrain atomic binding remain intact.

The user confirmed navigation is much faster with game time paused. The synchronous calendar now yields during active map navigation and clears catch-up debt. This intentionally holds calendar progression briefly during pan/zoom, without changing the selected speed or skipping simulated dates. It does not make individual daily simulation steps cheaper, and cannot interrupt a step already executing. General-led campaign time retains its existing path.

Validation: 40 distinct focused tests passed across terrain LOD (14, report 196), exact terrain sample reuse (8) and rendered water-height interpolation (3, report 194), and simulation performance/clock (15, report 195). Zero errors, failures or orphans. Includes 120 anchor drifts without restart, a 60-frame zoom using one target build, retention of finished terrain and water while building, deferred close-patch installation, and a 600-frame navigation hold with no catch-up burst. No graphical control, launch, or measured player FPS. Large uncached views still require terrain loading; this does not guarantee elimination of every visible LOD transition. No save schema changes.
## September 22 — bounded settlement reference checkpoint

Added two opt-in reference probes and docs/SETTLEMENT_REFERENCE_CHECKPOINT.md. Measured one current-save day and 23-plot fabric construction; built an isolated grounding/clearing prototype with identical geometry across three aerial camera heights. Final private GPU run exited zero with no script errors or visible windows. No game rendering/simulation files or saves changed. Prototype imagery and diagnostic outputs remain local artifacts; private data is excluded from Git. This checkpoint is not an accepted final art pass or an installed performance fix. See the report for measurements, limitations and the next bounded growth/destruction proof.
## September 22 — scouting readability

Scouting's illustrated dark palette now explicitly preserves its surface colors instead of letting the generic light-mode helper turn dark cards pale while retaining pale ink. Party/find cards are opaque dark brown, the clay texture is reduced to 10% opacity, and departure-selector/menu colors match the screen. Later-era framing also retains a compatible dark surface. Scouting policy and simulation behavior are unchanged.

Validation: 8/8 scouting-panel tests passed, zero errors/failures/orphans (report 197). Added contrast checks of at least 4.5:1 for body/secondary/heading ink, the worst-case texture backdrop, and the city selector/menu in both UI color modes. Existing live policy, party details, returned finds, narrow-window layout and era-art checks pass. No player launch or desktop control.

## September 22 — early artwork connected to game state

Connected paper artwork to settlement buildings, materials, workshop products, government people, culture and broad research categories for the first 300 years. Civilization/world identity selects a consistent appearance family; a saved person index keeps that person's illustration stable across offices. Culture's header responds to lived values independently of ancestry. New government scenes retain their aspect ratio, and office badges sit at the corner rather than across the figure. Specific discovery illustrations remain unchanged.

Validation: 9 focused tests passed, zero errors/failures/orphans (report 201). Private GPU capture loaded the year-71 fixture and rendered the actual settlement/government/culture screens at 1500×1000 and 1024×700, with no script errors; the player's running game and ordinary saves were untouched. The capture exposed duplicate cabinet assignments, subsequently corrected with saved cast allocation and a regression test. Four visual families and four principal figures per family are initial coverage, not unique art for all civilizations or officials. See assets/ui/early-paper/README.md for bindings and provenance. Appearance fields are additive save data; gameplay balance and simulation pacing are unchanged.

## September 22 — early military action scenes

Levy, spearman and archer now resolve to separate paper-style action scenes before year 300. Their frames show the whole scene; the army summary uses legible dark text over paper. Unknown reports still show no unit painting and later-era mappings are retained. Actual counts, equipment, training, recruitment and supply logic are unchanged.

Validation in canonical checkout: 14 focused tests passed (report 756), with no errors/failures/orphans. Private GPU military probe passed at normal and 1024×640 layouts; inspected the contained figures and summary contrast. Original images and exact prompts are retained. This is three unit types, not completion of the full military catalogue.

## September 22 — matching early research subjects

Connected the existing paper illustrations for oral_epics, tallies, cordage and clay_shaping to those exact discoveries before year 300. Individual focal points keep the work visible below the source images' blank paper space. Hidden discoveries still resolve to no artwork; later-era paths and gameplay effects remain intact. No new bitmap generation or assets were needed.

Validation: 7 focused early-art tests passed, zero errors/failures/orphans (report 757), including subject identity, unique paths, reveal state and the year-300 transition. The existing subject-art expectations were updated for the deliberate early mappings.
## September 22 — scouting paper header

The first-300-year scouting header now shows an original observation/travel scene in the paper aesthetic. Dark header ink is paired with the light background; the complete scene is contained instead of cropped through the figures. The established dark body palette and all scouting behavior remain unchanged. The existing capability condition still applies, and later framing remains available. Source and exact prompt are retained in assets/ui/early-paper/scouting-prompt.json.

Validation: 8 scouting tests passed (report 758), zero errors/failures/orphans. Private GPU capture of the year-71 fixture completed at 1500×1000 and 1024×700 without script errors; inspected the smaller layout for framing and text contrast. Player session and ordinary saves were not touched.
## September 22 — scheduled world days (canonical 3220e11)

World days run as bounded steps across frames instead of freezing a frame per day; saves and loads finish a day in progress first. AI planning, scouting and read models were split or reused exactly, and map border/corridor refreshes were made cheaper and staggered. Saved simulation state matches the prior baseline on the year-71 fixture, apart from the new art fields that arrived with `46f4cd3`. Frame smoothness improves greatly; total daily CPU does not, and three days/second remains unmet. See `docs/INTEGRATION_STATUS.md` and `docs/performance/YEAR71_AUDIT.md`.
## September 22 — twelve illustrated early undertakings

Added two paper atlases with separate design plates for all twelve undertaking catalogue entries. Available proposal buttons carry the exact corresponding plate; existing projects show their intended design alongside the actual status, custom name, condition and progress. Plates are explicitly design studies, not proof of successful construction. Candidate selection, local costs, hardship, maintenance, rewards, victory and the procedural map silhouettes are unchanged. Texture sheets are shared and loaded lazily, with capped imports and mipmaps.

Validation: 20 tests passed (report 759), zero errors/failures/orphans, covering complete distinct catalogue mappings and existing undertaking/reward behavior. The actual Construction → Undertakings page was captured privately from the year-71 fixture at 1500×1000 and 1024×700; the functioning orchard retained its saved name, condition and operating history. No player input or ordinary save writes. Artwork originals and exact prompts are in assets/ui/early-paper/undertaking-prompts.json.
## September 22 — persistent visual family names

People now retain an authored early_art_profile name as well as their individual scene index. Snapshot and government rows carry that saved name to the image resolver. Adding more visual families later can no longer change existing people merely by changing the size of a hash/modulo lookup. New people inherit their civilization's existing saved family. Appearance remains independent of civic values and gameplay statistics.

Validation: 9 early-art tests passed (report 760), zero errors/failures/orphans, including saved family-name resolution after JSON round-trip and seed changes. Existing missing appearance fields are initialized additively; no save version change or new portraits generated in this checkpoint.
## September 22 — slinger and skirmisher role scenes

Added separate paper action scenes for slingers preparing ammunition and bow-equipped skirmishers screening ahead. Both bind to their exact unit IDs before year 300 and use the existing contained roster framing; no unit gates or combat data changed. Native files and exact prompts are retained in assets/ui/military/paper/ranged-prompts.json. Nine early-art checks passed (report 761), including availability of every currently mapped early unit image.
## September 22 — early river patrol illustration

War canoes now use a distinct four-person patrol scene, matching the catalogue crew size. The first-300-year navy summary uses this scene and the same readable paper framing as the early army. The image remains a role illustration; actual vessels, crews and training are read from game state. Later naval art and all naval rules are unchanged.

Validation: 17 early-art and military-roster checks passed (report 762), zero errors/failures/orphans. Private GPU roster probe passed; inspected the naval summary and canoe card. Native artwork, source filename and prompt are retained in assets/ui/military/paper/canoe-prompt.json. Local in-game capture review: artifacts/early-art-in-game.html (captures are intentionally not committed).
## September 22 — sixteen early research subjects

Expanded the explicit early paper mappings with twelve reviewed, already-existing subject paintings: seasonal_patterns, seed_selection, clean_water, food_drying, controlled_flaking, pit_firing, joinery, basketry, plain_weaving, drop_spindles, customary_law and watch_rotation. Each maps only to its own discovery and has an activity-centered focal point. No new images were generated; no research costs, effects, gates or reveal rules changed. The late-period manifest remains unchanged.

Validation: inspected all twelve source paintings together in a private render; 9 focused tests passed (report 763), including existence, unique subject paths, hidden-state behavior and later-era fallback. Sixteen early discovery mappings are now covered by this pass; this is not the entire research catalogue.

### Early research paper art: 28 subjects

Twelve additional exact research IDs now select reviewed paper illustrations during years 0–299. Hide tanning uses a new pit-and-rack working scene; the previous image remains available. Every mapping retains subject identity, discovery visibility, and the existing post-300-year manifest. No research pacing or simulation values change. The replacement texture is capped at 1024 with mipmaps and uses the existing bounded cache. Focused early-art tests cover file existence, distinct assignments, hidden discoveries, and later-era fallback.

### Early foreign-leader record artwork

Known foreign leaders now receive a contained action illustration beside their record during the first 300 years. Civilization owner, visual family, and cast slot are stored additively in the existing leader dictionary; temperament does not choose ancestry or recast the person. Unknown contacts remain gated by the existing diplomatic query. Ten focused early-art tests pass, including JSON identity persistence; an isolated synthetic diplomatic screen passes at 1440×900 and 1024×700. No real diplomatic message was sent. Four families remain a shared-library limitation.

### Fourteen first-300-year direction illustrations

The founding/century direction cards and national-character history now share fourteen distinct paper scenes. The six later choices no longer wrap around to unrelated first-eight art during years 0–299. New atlases depict exploration, building, council, inquiry, strength, abundance, care, exchange, founding, extraction, exclusion, dynasty, coercion, and controlled speech. Cards contain the whole scene above the caption and use larger early-era artwork; disabled confirmation text has readable contrast. Eleven focused tests pass; isolated screens at 1440×1000 and 1024×700 confirm images stay clear of captions. Effects, saves, and post-300 imagery are unchanged. Two mipmapped atlases, capped at 1536, reuse the bounded cache.

### Early Wealth work illustration

The early Wealth panel replaces its medieval workshop-and-market crop with the shared paper timber-working scene. Currency account visibility and economic numbers are unchanged. The actual year-71 save rendered at 1500×1000 and 1024×700 without script errors; no player save was written. This reuses an imported atlas and adds no texture asset.

### Early research coverage: 36 subjects

Eight additional exact IDs use their reviewed existing paper artwork in years 0–299: smoking, well siting, shared measures, route memory, formation drill, stone sorting, apprenticeship, and stellar wayfinding. No new image assets were needed. Each image was reviewed against its subject and receives an individual crop focus. Existing disclosure gates, bounded texture cache, and later-era bindings are unchanged.

### Early wound care and plant comparison

Two new paper scenes bind specifically to wound_cleaning and herbal_classification for years 0–299, bringing the reviewed early override set to 38 subjects. Native sources and prompts are retained, textures are mipmapped and capped at 1024, and previous manifest art remains the later-era fallback. Eleven focused checks pass. Isolated 490×280 and 260×112 research-card crops were inspected and their focal points adjusted to keep the relevant gestures visible. No medical or research mechanics change.

### Early military support artwork

Repair companies and medical detachments now have specific paper role illustrations in the first 300 years. The crew scenes depict spear/shield maintenance and a carried wooden litter. They join six existing early unit illustrations; no recruitment, repair, medical or production mechanics change. Native images were reviewed for work actions and whole-body framing; imports are capped at 1024 with mipmaps. Nineteen focused early-art and military-roster checks pass, including imported paths and existing later-era behavior.

### Fifth early visual family and shared identity lookup

Ashplain adds four new action compositions and a distinct authored human appearance/clothing tradition. Government and known diplomatic leaders use one family catalogue; existing government records or diplomatic assignments win over a new library-size hash. No civic behavior is inferred from ancestry. Twelve focused checks pass, covering all five atlas regions, government/diplomatic identity preservation, saved roles, JSON, and early/later gates. The new family applies to first-time assignments/new worlds; established appearances remain fixed. Five families remain insufficient for exclusive artwork across every rival civilization.

### Sixth early family and nonrepeating initial distribution

Rillmark adds four new character-action compositions. First assignments now rotate through the authored families by canonical civilization slot with a world-seed offset; the player plus first five rivals do not collide. Existing saved family names remain authoritative. Thirteen focused checks pass, including three seed cases with distinct first-six assignments, government/diplomacy preservation and all atlas boundaries. The library still repeats after six civilizations and is not a complete exclusive ancestry set for maximum-count worlds.

### Eight early character families

Flintmere and Morrowfen add eight distinct action compositions with separate authored facial traits, hair and garment construction. The shared first-assignment sequence covers player plus seven rivals before repetition; existing saved identities remain fixed. Thirteen focused checks pass across all eight source atlases and saved government/diplomatic identity rules. No simulation traits, game RNG or later-era art change. This is still short of exclusive imagery for the default player-plus-twelve world.

### Ten early character families

Thornbank and Sunhollow add eight reviewed action illustrations with varied ordinary faces, adult proportions and working postures. Thirteen focused checks pass across all ten atlases and the nonrepeating initial assignment span. Existing saved families, civic behavior and simulation RNG are unchanged. The library now covers player plus nine rivals before repeating; further coverage remains.

### Twelve early families and previous-world guard

Greyfold and corrected Ochrestep add eight action scenes. The initial distribution covers player plus eleven rivals; saved identities are unchanged. A seed guard prevents a leftover diplomatic appearance from another world entering first assignment. Thirteen focused checks pass, including same-world preservation, different-world fallback and all twelve image regions. Native generated images and the targeted cast correction prompt are retained.

### Thirteen early families for default new worlds

Hollowreed completes thirteen authored human visual families with four principal action scenes each. The default new world assigns a distinct family to the player and each of twelve rivals. Thirteen focused tests pass, and an isolated GPU preview verifies all thirteen new-world assignments and character-widget framing. Existing saved families remain authoritative; larger worlds repeat families and additional officials reuse the small cast. The source cache remains bounded at eight textures. No simulation traits or player saves change.

### World contact artwork follows discovered identity

Early World overview contact cards now reuse the known diplomatic leader image and name. The existing contact-level gate must return a known leader before artwork is attached; rumors and unconfirmed encounters remain unillustrated. An isolated 1024x700 GPU fixture verifies exactly one portrait for one known contact plus an unknown lead, without touching player saves. Later-era cards retain their prior presentation. No new textures or simulation loops were added.

### Early shield-wall unit illustration

Line Infantry now uses an early paper shield-wall training scene before year 300, replacing its later-looking legacy illustration in that interval. Shield-wall knowledge is present in the recorded 75-year same-site pacing comparison; this is tied to an existing unit and research gate, not a new unlock. Nine early unit types now have paper overrides. Both focused suites pass: 21 tests, zero errors, failures or orphans. Native generated source and exact prompt are retained; mipmapped import capped at 1024. No unit balance or pacing changed.

### Material comparison research art

Timber Grading and Clay Testing replace legacy realistic imagery with paper illustrations before year 300. Both discoveries occur in the recorded early pacing runs. The scenes show sound/crooked/rotten timber and distinct clay test outcomes rather than generic crafting. Thirteen focused tests pass; isolated GPU previews check the actual research painter at 490x280 and 260x112. Narrow timber framing prioritizes the wood samples. Forty explicit early research overrides are now installed; later-era mappings remain intact.

### Fiber selection and hafting research artwork

Fiber Grading and Hafted Tools now show their specific material tests and binding work in the early paper style. Both are observed early discoveries. Actual research widgets were reviewed at 490x280 and 260x112; thirteen focused checks passed with no failures or orphans. Forty-two explicit early research overrides are installed, with the existing year-300 gate, visibility rules and bounded texture cache unchanged.

### Early river and coastal watercraft imagery

River Craft and Coastal Watercraft use distinct paper illustrations for early research: shallow-river paddling versus stitched-plank hull construction. Both are present in the recorded early pacing runs. Thirteen focused tests pass; both actual research widget sizes were GPU-reviewed. Coastal framing was lifted slightly to preserve the worker at the upper edge. Forty-four explicit early research overrides are installed; no discovery gates, boat behavior or later-era assets changed.

### Household and shared-care research scenes

Shared Childcare and Household Space Planning now use paper scenes tied to the specific practices: supervised communal care and arranging sleeping, ventilation, storage and circulation in a modest early home. Both occur in the recorded early pacing comparison. Actual large and compact research crops were GPU-reviewed; thirteen focused tests passed without errors, failures or orphans. Forty-six explicit early overrides are installed. Simulation and later-era mappings are unchanged.

### Tempered clay and sealed food vessels

Tempered Clay and Sealed Vessels now show additive mixing and pest-resistant closure in the early paper aesthetic. The two distinct processes remain readable in large and compact research crops, verified by an isolated GPU preview. Thirteen focused tests pass without errors, failures or orphans. Forty-eight explicit early research overrides are installed. Native sources, exact prompts and capped mipmapped imports are retained.

### Quarry reading and timber seasoning

Reading the Quarry Face and Timber Seasoning now use matching early paper imagery for seam inspection and spaced timber drying. Both actual research card sizes were reviewed in an isolated GPU preview. Thirteen focused tests passed without errors, failures or orphans. Fifty explicit early research overrides are installed, preserving later-era mappings. Native sources and exact prompts are retained.

### Early bow craft and weapon hafting

War Bow Craft and Hafted Weapons now show their specific inspection and craft work in early paper illustrations. Both occur in recorded early pacing. Large and compact research crops were reviewed on the isolated GPU desktop; thirteen focused tests passed without errors, failures or orphans. Fifty-two explicit early research overrides are installed, preserving research gates, simulation and later-era mappings.

### Early frame and kiln research art

Framed Construction and Kiln Control now have specific paper illustrations for their early research cards. Imported resources resolve; thirteen focused tests pass without errors, failures or orphans. Fifty-four explicit early research overrides are installed.

### Early shield-wall and field-defense imagery

Shield Wall and Field Fortifications now use paper illustrations showing formation drill and a defensible temporary camp. Imported resources resolve; thirteen focused tests pass with no failures or orphans. Fifty-six early research subjects have explicit paper overrides.

### Early hide floats and coastal galley navigation

Hide Floats and Galley Navigation now show separate river and coastal practices in the paper style. Imported resources resolve; thirteen focused tests pass with no failures or orphans. Fifty-eight early research subjects have explicit paper overrides.

### Early pike and crossbow research images

Pike Drill and Crossbow Mechanism now use specific paper scenes. Imported resources resolve; thirteen focused tests pass with no failures or orphans. Sixty early research subjects have explicit paper overrides. All legacy research images attached to discoveries in the recorded 75-year same-site comparison now have an early paper override; later mappings remain available.

### Audience Hall, Chief Scout and artifact culture (main 7cc2eeec)

Integrated `codex/audience-hall` (6834ea22) and `codex/artifact-culture` (e13b379c) without conflicts. Foreign envoys arrive with gifts, requests, tribute demands and news; officials petition; the court interjects in persistent personas; choices resolve through validated engine effects. A ChiefScout office debriefs returned scout and envoy findings. Artifact study is a research-team role, studied pieces yield culture/research/economic value, a derived allure score gives bounded diplomacy/migration/museum effects, finds cluster at named sites with sets, legendaries and rumors, and the Culture tab opens a full gallery. Combined branch: audience hall, voice, chief scout, audience modal and artifact gallery probes pass with zero script errors; 159 gdUnit cases across artifact, society exchange, century focus, government and city intelligence suites pass except `test_deceased_roster_does_not_exhaust_future_government_successors`, which fails identically on d55b339a. `command_rail_probe` fails identically on d55b339a (missing RailSettlement, toolbar outside viewport). Saves: audience state is optional in ForeignDiplomacy's payload; artifact study state is optional in society_exchange; older saves load.

### Leader-run caravans and settler caravans (main 126218a9)

Integrated `codex/caravan-leader` (840e46b1, already containing ae87ecee). One caravan brain drives the founding journey, player settler caravans and AI moves: the ruler picks a destination; the leader plans water-linked legs, never camps without water, detours to water instead of halting in dry ground, forages and rests on its own judgment, and refuses impossible trips with a reason. Expansion forms a settler caravan (leader, settlers, rations) that travels on carried food and water and founds the town on arrival. Combined branch: caravan_leader, audience_modal and audience_hall probes pass with zero script errors; 76 gdUnit cases across founding convoy travel, founding water guidance, founding site subsistence, settlement model and campaign save continuation pass. In-flight journeys from older saves migrate under a leader; no save version change. Limits: one settler caravan per civilization at a time; founding party carries at most two days of water.

### No victory conditions (main)

Integrated `codex/no-victory` (2b875926 + merge of 251b84a3). All victory/defeat win states are removed: competition thresholds, dominance streaks, outcome and winner fields, the Enduring Civilization award and victory panels. Comparative standing remains as intelligence, explicitly not a contest; strength and collapse remain as chronicle history. Combined branch: 100 gdUnit cases across civilization system, undertaking rewards, campaign save continuation, founding convoy travel and general campaign pass; caravan_leader and audience_hall probes pass with zero script errors. Older saves with removed fields load; the fields are dropped and never written.

### Conceived great works (main)

Integrated `codex/great-works` (9b449a61, containing d3078a1b). Wonders have no fixed list, world claims or races: each people conceives works from its values, needs, environment and history as form x purpose x ambition with a unique name; feasibility is spoken in-world; outcomes range from triumph to collapse (named ruins with real losses), audacious works paying more and failing far more. Officials pitch works in the Audience Hall, stage gates and collapses play as court scenes, completion opens a dedication ceremony with envoys and real gifts, and a works screen records our works and known foreign works as history (no victory). AI rulers conceive works from their own triggers and temperament. Combined branch: eight probes (great works experience, wonder concept, audience hall/voice/modal, chief scout, artifact gallery, caravan leader) pass with zero script errors; 273 gdUnit cases across great works, rivals, undertakings, landmarks, rewards, early art, civilization strategy/system, city intelligence, occupation, society exchange, artifacts, founding travel and save continuation pass. Old undertaking saves load via legacy founding definitions; retired victory fields are ignored.

### Terrain query fixes and continental rasters (main)

Integrated `codex/terrain-bake` (c701d555, containing 533ac28d). River/water lookups use the tributary chunk index; profile_at is lazy and returns shared read-only cached profiles; a per-world land mask answers certain land/sea queries (zero disagreements in 1.4M samples, identical rival placement); background-baked planet/regional rasters build continent-scale patches, cutting time to full continental detail from ~500 to ~110 frames with no visible seams or hitch in isolated GPU captures. Close terrain, gameplay values and saves unchanged. Combined branch: 30 gdUnit cases (terrain bake, planet environment, founding water guidance) plus caravan_leader and audience_hall probes pass. First visit to a new world bakes ~95 s in the background (~32 MB cache per world).

### Audience Hall rework: pacing, variety, continuity, literary voices (main)

Integrated `codex/audience-variety` (1caf299f, containing 707b4816). Replaces timer-driven audiences (an audience every few days, identical repeated petitions) with occasion-driven ones on a ~60–120 day budget, per-speaker spacing, a three-year no-repeat ledger, evolving ambitions and continuity arcs; adds situations backed by real mechanics (accords, pacts, leagues, peace feelers, trade/non-aggression, rumor and city-intel sharing, envoy-brought scholars/studies/licenses, recruitment protests, and cross-owner artifact gifts/sales/returns). Speakers keep one literary/historical voice model and one address for life, are era-gated (no anachronisms; stone-age office titles), answer questions from facts, never repeat a line, and speak briefly. The modal shows live/offline voice, token receipts and a frequency control. Combined branch: audience hall/voice/modal, chief scout, great works experience, caravan, artifact gallery probes and the three-year transcript quality gate (0 duplicate lines, 19/19 questions answered) pass; gdUnit artifact/society exchange (96), great works/civilization (98) and government suites pass except `test_deceased_roster…` and `test_locked_office…`, which fail identically on earlier main. Hall state v2 migrates older saves and calms crowded queues.

### Only foreign envoys arrive unbidden (main e0f61f14)

Fast-forwarded `codex/audience-variety` checkpoint 1. Court business (petitions, grievances, promise follow-ups, introductions, war councils, Chief Scout reports, great-work pitches/forecasts/news/stage gates/outcome scenes) no longer enters the antechamber or pops up; it is filed as dated, deduplicated matters that lapse without penalty and are opened by the ruler. Stage decisions and ceremonies still resolve by council default. Hall state v3 migrates waiting court audiences into matters. audience_hall (0 uninvited court arrivals at every frequency), transcript quality gate, chief_scout, great_works_experience, audience_modal and audience_voice probes pass. Player summon UI follows as checkpoint 2.
