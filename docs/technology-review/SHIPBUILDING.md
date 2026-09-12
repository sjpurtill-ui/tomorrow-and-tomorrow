# Wooden shipbuilding production

Sixteen individually authored discoveries add seventeen physical workshop recipes. Newly created sailing-warship, frigate, ship-of-the-line and convoy-transport production lines now need manufactured hulls, sails, rigging and masts. A launch cradle is paid once when establishing or retooling the line. Ordinary equipment production, crew recruitment, base readiness, training and general-led operations remain responsible for the finished vessel.

| Practice | Physical consequence |
|---|---|
| Rope Laying | Fiber plants become rope coils. |
| Sail Panel Cutting | Woven cloth becomes measured sail panels. |
| Sail Seaming | Panels, yarn and reinforcing rope become sail sets. |
| Wooden Sheave Blocks | Timber and rope become blocks for running rigging. |
| Standing and Running Rigging | Rope and blocks become coordinated rigging sets. |
| Keel Scarfing | Timber becomes joined keel sections. |
| Grown Frame Selection | Selected curved timber becomes ship frames. |
| Frame Moulding | Paid patterns reduce frame-manufacturing time and timber use. |
| Plank Spiling | Timber becomes fitted hull planks. |
| Caulking Fiber Preparation | Fiber plants become joint-packing material. |
| Treenail Fastening | Timber becomes wooden fastening batches. |
| Hull Seam Caulking | Planks, packing fiber and bitumen become sealed planking assemblies. |
| Carvel Frame Construction | Keels, frames, sealed planking and fastenings become ordinary or heavy hull sections. The heavy recipe requires additional frames, planking and iron. |
| Clinker Shell Construction | Overlapping planks, frames, keels, fiber and iron become an alternative ordinary hull section. |
| Mast Making | Timber and reinforcing rope become ship masts. |
| Launching Cradles | Timber and rope become reusable shipyard tooling. |

All sixteen use causal prerequisites with no calendar unlock. Frame moulding improves an existing output rather than inventing a new resource. Clinker and carvel paths reconverge on ordinary hull sections; frigates and ships of the line require the separate heavy frame-first output. Own research and the existing paid component-production license mechanism remain usable; no foreign knowledge or material is granted by this branch.

## Construction and planning

A convoy transport consumes four ordinary hull sections and one batch each of sails, rigging and masts. A sailing warship uses sixteen ordinary hull sections and four of each outfitting batch. A frigate uses thirty-six heavy hull sections and nine outfitting batches; a ship of the line uses one hundred heavy sections and twenty-five outfitting batches. These are game production batches, not archaeological tonnages or engineering specifications. Final assembly retains the existing work requirements, crew sizes and combat characteristics.

The civilization controller evaluates feasible upstream manufacture instead of rejecting a known ship merely because its finished components are absent. It issues one ordinary component order for the selected candidate, reusing only a completed, unpaused civilian line when capacity is full. Missing raw supplies, unknown production methods, paused inputs, absent labor and unavailable bases block the candidate. Existing active or paused jobs are not overwritten. No hidden supplier or enemy information is consulted. A component recommendation is only a next action; it does not reserve an entire multi-stage bill of materials or forecast future competition for stocks.

When equipment finally exists, ordinary commissioning withdraws it and commits actual crew places. This batch changes no general authority, direct tactical controls, ship movement, combat statistics or logistics rules.

## Evidence and boundaries

Five focused shipbuilding cases pass: the recursive component chain through actual paid production and twelve-person transport commissioning; two successive equipment batches for all four sailing roles with one cradle payment; raw shortages, unknown methods and paused upstream lines; all three hull recipes with actual debits; and a retained legacy ship line's fractional work after JSON serialization. Nineteen existing persistent-production cases also pass. Both suites report zero errors, failures, skips or orphans. The connected test found and fixed a retooling path that otherwise skipped naval tooling payment.

The graph and ideal-resource manufacturing audit reports 492 discoveries, 171 recipes and 12 plants, with no graph or structural production errors. This establishes structural reachability, not a naturally played full-history economy. The artificial test harbor and supplied upstream cloth/iron stocks are explicit fixtures. Native player acceptance and canonical integration are still outstanding.

No save schema changes. Existing ship inventory, forces and production jobs remain intact. Retained legacy persistent ship lines keep their stored raw-material recipes and fractional work; only new or deliberately retooled lines use the new component costs. Their old recipe is not silently replaced mid-batch. Production costs remain balance parameters. Hull geometry, timber species and moisture, actual sail aerodynamics, shipyard wear and harbor launching geometry are not simulated. Sealed planking and hull sections represent accountable assembly work, not literal prefabricated historical modules. Other naval and aircraft recipes still require future production expansion.

## Historical grounding

The [Viking Ship Museum's Gislinge hull account](https://www.vikingeskibsmuseet.dk/en/professions/boatyard/building-projects/gislingeboat-2015/the-gislinge-boats-hull/) supports the importance of grain-following timber conversion and overlapping planks in clinker construction. The [museum's Nordic Clinker Boat Charter](https://www.vikingeskibsmuseet.dk/frontend/Dokumenter/The_Nordic_Clinker_Boat_Charter.pdf) describes the shared construction tradition. The [National Park Service ropewalk history](https://www.nps.gov/places/ropewalk-cny.htm) distinguishes long-established rope use from later enclosed, mechanized ropewalks. This branch therefore requires rope-making knowledge, not a particular century or steam-powered building. These sources inform the practices; they do not establish the game's numerical costs or claim that one hull construction sequence represents every maritime culture.
