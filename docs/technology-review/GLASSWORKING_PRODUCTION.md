# Glassworking and prepared chemical apparatus

Implemented from `26ed346` in the technology worktree. Six distinct authored discoveries bring the live catalog to 383; eight new recipes add physical vessel/tube/apparatus manufacture and alternative chemical workshop setups. All new discoveries have day zero and common causal prerequisites, with no era lock.

| Discovery | Foundations | Output mechanism |
|---|---|---|
| Core-Formed Glass | Glassmaking, Clay Vessels | Glass shaped around a removable core |
| Glass Blowing | Glassmaking, Bloomery Smelting | A metal blowpipe inflates a hot gather |
| Mold-Blown Glass | Glass Blowing, Clay Tempering | A mold constrains the inflated shape |
| Plunger-Pressed Glass | Glassmaking, Forge Welding, Workshop Standards | A plunger displaces glass against a metal mold |
| Glass Tube Drawing | Glass Blowing, Standard Measures | A hollow gather is drawn into a tube |
| Hydrogen-Flame Glassworking | Glass Tube Drawing, Chemical Distillation | Local flame heating joins/shapes tubes into laboratory apparatus |

Core forming remains a route without iron blowpipes. The modeled free-blowing implementation uses iron tooling; historical clay blowpipes are not implemented. Hydrogen flame work is a specific fueled implementation, not the origin of all flameworking. Knowledge alone does not supply hydrogen or apparatus.

| Recipe | Inputs per batch | Work days | One-time tooling |
|---|---|---:|---|
| Core-formed vessels | 1 Glass, 0.2 Clay, 1 Timber | 4 | 4 Clay, 4 Stone, 2 Timber |
| Free-blown vessels | 0.8 Glass, 1 Timber | 2 | 2 Wrought Iron, 4 Clay, 4 Stone |
| Mold-blown vessels | 0.8 Glass, 1 Timber | 1.5 | 2 Wrought Iron, 8 Clay, 4 Stone |
| Pressed open vessels | 1 Glass, 1 Timber | 1 | 8 Wrought Iron, 6 Stone |
| Drawn glass tubes | 1 Glass, 1 Timber | 3 | 2 Wrought Iron, 4 Timber, 4 Clay |
| Hydrogen-worked laboratory glassware | 1 Glass Tubes, 0.5 Glass Vessels, 0.2 Hydrogen | 3 | 2 Refined Copper, 3 Clay, 1 Pressure Vessels |
| Brine in prepared glass vessels | 1 Salt, 3 Freshwater | 2.5 | 2 Glass Vessels, 2 Clay |
| Silicon refined with prepared apparatus | 1 Metallurgical Silicon, 0.5 Hydrogen Chloride, 0.25 Hydrogen, 1 Freshwater, 3 electricity | 5 | 3 Laboratory Glassware, 3 Pressure Vessels, 5 Steel |

All quantities are abstract design coefficients, not process instructions or engineering measurements. Vessel methods reconverge on Glass Vessels; tube drawing supplies Glass Tubes; flame work supplies Laboratory Glassware. The last two recipes remain gated by Brine Purification and Chlorosilane Purification respectively. Knowing glassworking cannot unlock those chemical processes. Earlier generic glass-based setups remain available, with their original costs. Prepared apparatus changes setup requirements and work time; it does not remove reagents, fuel or shared-power costs.

Manufacturing licenses and specimen examination discover these recipes through the existing civilian catalog. Ordinary licensing support, payment, 65% throughput and local mastery rules remain. Generic vessel stocks do not preserve forming-method provenance, so specimen examination cannot authenticate how a particular vessel was made; this existing shared-output abstraction remains a limitation.

## Sources and scope

Corning Museum of Glass documents the distinct physical mechanisms: [core forming](https://glasscollection.cmog.org/objects/61359), [blowing](https://allaboutglass.cmog.org/definition/blowing), [mold blowing](https://allaboutglass.cmog.org/definition/mold-blowing), [pressed glass](https://allaboutglass.cmog.org/definition/pressed-glass), and [flameworking](https://allaboutglass.cmog.org/definition/flameworking). Its [process overview](https://info.cmog.org/publication/glassworking-processes-and-properties) treats forming and annealing separately. These support distinct production identities, not the numerical game coefficients.

The hydrogen recipe is a game implementation choice based on combustible hydrogen and local glass heating; it is not a reconstruction of the earliest lampworking. SCHOTT's [hydrogen-heated glass trials](https://www.schott.com/en-gb/news-and-media/media-releases/2024/schott-produces-optical-glass-with-100-percent-hydrogen) support hydrogen as an industrial glass heat source, not this exact small-apparatus recipe.

Glass composition, optical quality, corrosion resistance, vessel geometry, oxygen supply, cooling schedules, annealing stress, breakage, molten working state and continuous furnaces are not individually simulated. Generic Glass Vessels include open vessels and containers; they are not pressure vessels. The separate Pressure Vessels tooling remains required for apparatus-supported silicon refining. This does not certify chemical compatibility or equipment safety in the real world. Solar cover sheets, float glass, precision optical glass and additional glass chemistries remain work for later branches.

## Verification and integration

61 cases passed: four glassworking, twelve civilian industry, fourteen technology operations, eleven licenses, eleven reverse engineering and nine technology-tree cases. Zero errors, failures, skips or orphans. New tests exercise all vessel methods, actual tube/fuel consumption, denial without hydrogen, once-only brine setup costs, the independent silicon-research gate, shared-power denial and saved partial refining with no duplicated output.

Graph: 383 identities, 157 explicit routes, no errors. Resource audit: all 383 structurally reachable under its idealized assumptions, not pacing acceptance. Art manifest: 27 reviewed images, 356 queued live subjects.

No new save fields. New goods use existing stock serialization; new recipe IDs require this implementation to operate. Integration conflicts: DiscoverySystem, CivilianIndustry and graph audit. No player launch or canonical integration. The live long-run diagnostic loaded `49fe572` with 377 discoveries, so it does not exercise these new glass methods.
