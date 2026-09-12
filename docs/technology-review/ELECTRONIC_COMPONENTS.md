# Electronic components and controlled workshops

Implemented from `aa6c5da` in the technology worktree. Nine authored discoveries and nine manufactured component types extend the electrical/semiconductor branch. The live catalog now has 392 discoveries. These are distinct circuit functions, not multiplied tier labels.

| Discovery | Common foundations | Manufactured output |
|---|---|---|
| Carbon Resistors | Electrical Measurement, Graphite Marking | Resistors |
| Foil Capacitors | Electrical Measurement, Sheet Fiber Writing Material, Wire Drawing | Capacitors |
| Electromagnetic Relays | Electromagnetic Induction, Wire Drawing | Relays |
| Wound Transformers | Electromagnetic Induction, Cable Insulation | Transformers |
| Silicon Rectifiers | P–N Junctions, Wafer Sawing | Silicon Diodes |
| Bipolar Junction Transistors | P–N Junctions, Semiconductor Doping | Transistors |
| Transistor Amplifiers | Bipolar Junction Transistors, Carbon Resistors, Foil Capacitors | Amplifier Modules |
| Resistive Sensing | Carbon Resistors, Electrical Measurement | Sensor Assemblies |
| Electronic Machine Control | Transistor Amplifiers, Resistive Sensing, Electromagnetic Relays, Wound Transformers, Silicon Rectifiers, Feedback Governors | Electronic Controllers |

All new discoveries use causal requirements and day zero. The component branches reconverge on a machine controller. Ordinary mechanical/motor workshops remain available; this branch does not replace them or gate their operation. These are discrete-component controls, not a digital computer or integrated circuit.

## Physical production

| Output | Inputs per batch | Work days | Electricity |
|---|---|---:|---:|
| Resistors | 0.1 Graphite, 0.2 Clay, 0.1 Copper Wire | 2 | 0 |
| Capacitors | 0.2 Refined Copper, 0.2 Paper, 0.05 Bitumen | 2 | 0 |
| Relays | 0.5 Wrought Iron, 0.3 Copper Wire, 0.1 Insulated Cable | 3 | 0 |
| Transformers | 1 Wrought Iron, 0.5 Copper Wire, 0.2 Insulated Cable | 4 | 0 |
| Silicon Diodes | 0.2 Silicon Wafers, 0.1 Copper Wire, 0.01 Phosphate Rock | 3 | 1 |
| Transistors | 0.3 Silicon Wafers, 0.1 Copper Wire, 0.02 Phosphate Rock | 4 | 2 |
| Amplifier Modules | 1 Transistors, 2 Resistors, 1 Capacitors, 0.3 Copper Wire | 3 | 0 |
| Sensor Assemblies | 1 Resistors, 0.3 Copper Wire, 0.2 Glass | 3 | 0 |
| Electronic Controllers | 1 Amplifier Modules, 1 Sensor Assemblies, 1 Relays, 1 Transformers, 2 Silicon Diodes, 1 Insulated Cable | 6 | 0 |

Every line also pays its explicit setup tooling, recorded in CivilianIndustry: ceramic/metal fixtures for passive components, iron/timber winding tools, and laboratory glassware/steel/optical tooling for semiconductor fabrication. Existing finite lines, target stocks, shared crafting work, power accounting and saved partial progress apply. Component stocks alone provide no manufacturing-service bonus. Manufacturing licenses and destructive examination use the existing civilian-recipe interfaces and their established conditions.

All quantities are game coefficients. In particular, Phosphate Rock is the existing aggregate semiconductor dopant input; these recipes do not model separate donor/acceptor preparation, junction profiles, masks, diffusion furnaces or chemical purity. They are not literal manufacturing specifications.

## Fifth commissioned installation

The electronically controlled workshop requires Electronic Machine Control and Electric Motors at normal commissioning adoption. Installation consumes one Electronic Controllers, one Electric Motors, two Insulated Cable and two Steel, followed by 15 work. A fully running installation requires 1.5 Crafting operators and 2.5 daily electricity, delivering 4.5 units of the existing mechanical-work service. This service enters the established capped production-workforce factor. Health/workplace conditions, finite operators, generator dispatch, disabled plants and shared electrical supply remain binding.

The ordinary motor-driven workshop still supplies three mechanical-work units for one operator and two electricity. The controlled installation has higher setup complexity and different power/staff needs; it is not an unconditional productivity multiplier or a replacement for every machine. Its aggregate effect represents steadier machine operation, not a simulated feedback circuit.

Save validation now admits the five installation types' legitimate maximum commissioning workforce of 10,000 and aggregate mechanical-work bound of 7,500. Values above those bounds remain rejected. No new state fields are introduced. Old saves without the new plant load normally; older builds cannot operate the new recipe/plant IDs or accept expanded service bounds.

## Grounding and remaining scope

The Computer History Museum distinguishes discrete transistor devices from later circuits combining active and passive elements. [The Silicon Engine](https://www.computerhistory.org/siliconengine/), [early solid circuits](https://www.computerhistory.org/siliconengine/all-semiconductor-solid-circuit-is-demonstrated/). TDK describes foil electrodes separated by a dielectric, while TI documents bipolar amplifier circuits. [Capacitor construction](https://www.tdk-electronics.tdk.com/download/537974/76160cdb800cf40be24ef767fe5082bb/pdf-generaltechnicalinformation.pdf), [TI amplifier fundamentals](https://www.ti.com/asia/download/02_Choose_a_right_amplifier_cn.pdf). Those sources support separating component functions, not these game costs or the workshop's numerical output.

Not implemented here: individual voltages/frequencies, tolerance, noise, thermal drift, insulation failure, AC grid behavior, circuit topology, sensor specialization, calibration, clean-room yield, maintenance failures, vacuum-tube alternatives, integrated circuits, logic/memory, computers, communications networks or software. These remain substantive later-history branches. No new military authority or direct unit controls are introduced.

## Verification and handoff

73 relevant cases passed: five electronic components, twelve civilian industry, fourteen technology operations, eleven licenses, eleven reverse engineering, nine technology tree and eleven visual atlas. Zero errors, failures, skips or orphans. Tests manufacture an entire controller from the new intermediate stocks, consume the shared four-unit diode/transistor energy budget, verify power denial and saved partial fabrication, commission a workshop before supplying solar power, check real operator reservation, preserve the installation through power/staff interruption, and validate the maximum five-type commissioning workforce.

Graph audit: 392 identities, 166 explicit routes, no errors. Idealized resource-dependency audit reaches all 392; this is not campaign pacing evidence. Art queue: 29 reviewed subject images, 363 queued live subjects.

Integration conflicts: DiscoverySystem, CivilianIndustry, TechnologyOperations and graph audit. Changes remain in the implementation worktree; native player presentation and canonical integration are unverified. The live 250-year-target diagnostic loaded the earlier 377-discovery build and does not exercise this new branch.
