# Early machinery operating capabilities

READY for integration review; this isolated delivery is not the player build.

Worktree: `/Users/seanpurtill/Documents/Codex/tt-early-machinery`
Branch: `codex/early-machinery`
Base: `857488e12e7bfed8a22917cc17f13d6cc8c25cef`

Six existing authored identities become runtime discoveries: bow_drill_drive,
treadle_lathe_drive, water_powered_hammers, mechanical_screw_presses,
cam_motion_design, belt_power_transmission. Their existing ALL predicates are
retained and all parents resolve; none is replaced by a chronology-only gate.
They use the existing acquisition and adoption systems and create no free
production resources or global knowledge bonuses. Promotion should use the
integrator's clean, verified snapshot, not this worker's base catalog ledger.

## Behavior

Fourteen paid recipes manufacture bow-drill sets, treadle lathes, screw presses,
cam followers, drive belts and belt assemblies, and waterwheel/hammer drives.
Their downstream processes bore axle boxes, turn axles, dewater paper, print
sheets, repeatedly press paper, or forge armor elements and bolt blanks. Existing
cart, printing, armor and fastening consumers use those ordinary resource names.
Hand processes remain available. Imported tooling can be used through an adopted
downstream process without discovering the tooling's manufacture.

The belt workshop spends an electric motor, belt assembly and timber, takes
commissioning work, then consumes electricity and replacement belts while
reserving real Crafting operators. It participates in the existing bounded
mechanical-assistance investment planner.

The river hammer spends a manufactured drive and stone, takes commissioning
work, reserves Crafting operators and consumes replacement cordage. It pins a
revealed River or Tributary source and settlement coordinates at installation.
The current context must still confirm that source identity and position within
0.75 km of the original home. Migration, missing source observations, freezing,
or modeled dry conditions stop the drive. Surface drainage is not accepted.
A settlement's hammers share one site and at most two effective drive units
(eight hammer-work units per day), regardless of installed machine count.

Only explicit forging recipes debit hammer work. Partial jobs consume the same
fraction of service, inputs and labor; output enters stocks only on completion.
Multiple jobs share the remaining daily balance. A same-day operations review
cannot refill spent capacity. Stale services are inaccessible and secondary
settlements cannot consume or reset the primary ledger. Independently owned
actor ledgers remain the existing world-simulation authority.

Automatic hammer investment requires actual target-stock demand for armor plates
or bolt blanks in active downstream production lines, a viable revealed site,
adopted knowledge, available operators and paid capital/maintenance supplies.
It can request upstream manufacture through the ordinary production planner.
It commissions at most one installation automatically and preserves manually
selected production lines. With daily hammer work available, the ordinary supply
planner can select the faster forging variants for new lines. Existing manual
lines are not silently retooled.

## Verification

Godot 4.7.2, explicit isolated worktree, headless only:

- Import: exit 0; no script/import errors.
- Combined GdUnit: **56 distinct cases passed**, no errors, failures, skips,
  flaky cases or orphans. Suites: `test_early_machinery` (10),
  `test_technology_operations` (16), `test_machine_workshop_investment` (6),
  `test_production_dependency_audit` (9), `test_civilian_production_planner` (15).
  Log: `/tmp/tt-early-machinery-acceptance.log`.
- New cases exercise all fourteen paid routes, source identity, migration,
  frozen/dry sites, shared site capacity, consumed-service idempotence, secondary
  isolation, fractional forging/material conservation, downstream-demand
  investment, legacy manual forging and a full binary save/load retaining
  a pinned site, partial job and spent service balance.
- Standalone graph: **730 discoveries, 512 explicit routes, 393/393 recipes,
  20/20 plants**, no graph/dependency errors or blocked fabrication chains.
  Log: `/tmp/tt-early-machinery-graph.log`.
- Catalog tools: **15 tests passed**.
- Normal headless main-scene boot: exit 0, `DIRECTION_SCREEN_READY`, no errors or cleanup warnings. Log: `/tmp/tt-early-machinery-boot.log`.

The dependency audit now validates service demands and rejects missing providers
or service bootstrap cycles as well as material/tooling/electrical cycles.
Structural reachability does not establish geographical availability or campaign
pacing. No long campaign test was restarted for this batch.

## Save compatibility and shared files

No new top-level save field or population authority. River site fields are bounded,
finite numeric arrays and a nonempty source ID within the existing installation
record, so JSON and binary saves retain them. Invalid river sites are rejected;
old records for other plant types retain their prior format. Recipe service
requirements come from immutable product definitions, not editable job data.

Shared changes: CivilianIndustry, DiscoverySystem, TechnologyOperations,
PersistentProduction, CivilianProductionPlanner, MachineWorkshopInvestment,
TechnologyOperationsPanel and the production dependency audit. New helpers own
knowledge definitions, site assessment and hammer investment. No changes to
LocalTerrain, GameState, SaveSystem or civic/leader authority. Integrator should
combine the additive CivilianIndustry/Discovery changes with parchment carefully.

## Limits and historical basis

The river model is an explicit gameplay capacity approximation, **not measured
hydraulic discharge, head or watts**. It uses existing revealed-source and climate
observations; no new river geometry or hydrology simulation is claimed. Only the
primary settlement can install this plant; alternate actor home ledgers use the
same scoped code. Existing manually chosen lines remain manual. Cams here support
an electrically driven paper press; this is not a claim that historical cams
originated with electricity. Costs and time are game batches, not SI estimates.
Six new illustrations remain separate work. The full 5,000-discovery goal and
2,500–3,000-year campaign pacing are still incomplete.

Historical mechanism references, not claims about earliest invention dates:

- [Sheffield Museums: Abbeydale waterwheels](https://www.sheffieldmuseums.org.uk/whats-on/waterwheels/)
  documents waterwheel-driven tilt hammers and other workshop machinery fed by
  the River Sheaf through a dam.
- [National Trust: Finch Foundry heritage record](https://heritagerecords.nationaltrust.org.uk/HBSMR/MonRecord.aspx?uid=MNA106659)
  records water-powered edge-tool manufacture and cam-tripped hammers.
- [London Museum: treadle lathe](https://www.londonmuseum.org.uk/collections/v/object-132809/treadle-lathe/)
  and [University of Reading: lathe collection record](https://www.reading.ac.uk/adlib/Details/collect/9261)
  support foot-operated lathe mechanisms.

## Canonical acceptance

Integrated at `c4af26837581201c3007fb0c971258512982d241`, retaining both additive recipe families. 109 combined worktree cases pass; canonical machinery10, operations16, persistent19, planner15 and parchment8 all pass (68). Exact731-definition canonical snapshot matches the promoted ledger and15 catalog tests pass. Graph731/513/396/20 and normal headless boot are clean. Earlier READY wording is source-handoff history. No player launch or package rebuild.

## Current-day context correction

An actual CivilizationDay integration review found operations preceding discovery-context refresh. Two new daily-step tests reproduced four stale hammer-work units after source deletion or home migration. CivilizationDay now supplies today's context explicitly to Operations.advance; direct legacy callers retain their existing fallback. Both regression cases pass and check zero running units; deleted-source maintenance is checked in the operations input ledger because other daily owners legitimately consume Rope Coils. No order change to discovery, resources, labor or daily consequences.
