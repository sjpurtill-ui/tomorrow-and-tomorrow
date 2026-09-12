# Fasteners, springs and riveted joints

Twenty-four individually authored discoveries add a connected hardware industry. They produce 28 recipes, including alternate matched-fastener and assembled-equipment methods. Each discovery has a physical consequence, an explicit dependency contract and zero calendar gating. No global strength or production bonus is awarded for merely knowing a joint-making method.

Cut threads and rolled threads reconverge on Matched Thread Inspection. Both require the same pitch references and internal-thread foundation. Standard Fastener Kitting converts counted hardware into Machine Fastener Sets; a pinned variant uses physically manufactured Locked Fastener Sets. Existing foreign-study, licensing and recovery rules continue to govern acquisition rather than creating duplicate discoveries for imported methods.

## Discovery inventory

| Discovery | Principal output | Foundations |
|---|---|---|
| Bolt Blank Forging | Bolt Blanks | forge_welding, standard_measures |
| Nut Blank Forging | Nut Blanks | forge_welding, standard_measures |
| Nut Bore Drilling | Bored Nut Blanks | nut_blank_forging, column_drilling_machines |
| Thread Tap Cutting | Thread Taps | lead_screw_cutting, toolbit_heat_treatment |
| Thread Die Cutting | Thread Dies | thread_tap_cutting, toolbit_heat_treatment |
| External Thread Cutting | Cut Bolts | bolt_blank_forging, thread_die_cutting |
| Internal Thread Tapping | Threaded Nuts | nut_bore_drilling, thread_tap_cutting |
| Thread Pitch Gauging | Thread Pitch Gauges | lead_screw_cutting, standard_measures |
| Matched Thread Inspection | Matched Fasteners | thread_pitch_gauging, internal_thread_tapping |
| Washer Punching | Flat Washers | sheet_steel_rolling, standard_measures |
| Cotter Pin Forming | Cotter Pins | wire_drawing, forge_welding |
| Castellated Nut Slotting | Castellated Nuts | internal_thread_tapping, horizontal_milling_machines |
| Split-Pin Locking | Locked Fastener Sets | castellated_nut_slotting, cotter_pin_forming, column_drilling_machines |
| Steel Wire Drawing | Steel Wire | wire_drawing, toolbit_heat_treatment |
| Spring Wire Coiling | Coiled Spring Blanks | steel_wire_drawing, tailstock_fitting |
| Coil Spring Tempering | Tempered Spring Coils | spring_wire_coiling, toolbit_heat_treatment |
| Split Washer Cutting | Split Washers | coil_spring_tempering, washer_punching |
| Rivet Blank Heading | Rivet Blanks | forge_welding, standard_measures |
| Rivet Hole Alignment | Aligned Rivet Plates | sheet_steel_rolling, drill_jig_layout |
| Hot Rivet Setting | Hot-Riveted Panels | rivet_blank_heading, rivet_hole_alignment |
| Cold Rivet Setting | Cold-Riveted Panels | rivet_blank_heading, rivet_hole_alignment |
| Thread-Rolling Die Making | Thread-Rolling Dies | thread_pitch_gauging, horizontal_milling_machines, toolbit_heat_treatment |
| Bolt Thread Rolling | Rolled Bolts | bolt_blank_forging, thread_rolling_die_making |
| Standard Fastener Kitting | Machine Fastener Sets | matched_thread_inspection, washer_punching, split_washer_cutting |

Matched Thread Inspection additionally requires either External Thread Cutting or Bolt Thread Rolling. That is an explicit alternative causal route, not a demand that both histories be repeated.

## Production choices

The original electric-motor and pressure-vessel recipes are unchanged. Component-assembled motors consume two Wrought Iron, three Copper Wire, two Insulated Cable, one Machine Fastener Set and one Cold-Riveted Panel per batch. Their final assembly takes eight work units instead of the original twelve, after upstream hardware has been manufactured. Setup requires a Basic Machine Tool Set and timber. Total supply-chain work may be greater; the shorter final assembly is not a claim of free overall efficiency.

Riveted pressure-vessel assemblies consume two Hot-Riveted Panels, one Coal, one Wrought Iron and two Freshwater, with straightedge, iron and stone setup. Six units of final fitting, sealing and checking work produce a Pressure Vessel. The original ten-unit iron recipe remains available. The output joins the existing plant and equipment supply chains; assembly does not create operating power or commission a plant.

All other outputs have downstream consumers. Flat and split washers enter kits; pinned hardware is an alternative kit component; steel wire, coil forming and tempering feed split washers; headed rivets and aligned plates feed hot and cold assemblies. Drawing steel wire uses hard steel drawing tooling, not a screw-thread die. Paid setup remains on the existing line through retooling and is separate from consumable material stocks.

## Verification

Four focused cases pass with no errors, failures, skips or orphans. The complete-chain fixture manufactures output under every one of the 24 discovery gates, then uses actual components in both final equipment recipes. Other cases cover the cut/rolled reconvergence and missing common measurement, unavailable knowledge and missing components without free stocks, and fractional rivet manufacture through JSON serialization with one paid tooling charge.

The final graph audit reports 556 discoveries and 333 explicit route records with zero graph errors. The ideal-resource dependency check reaches all 240 recipes and 12 plants in seven closure rounds with zero structural errors. This is structural reachability, not campaign pacing. Logs: `/tmp/tt-fasteners.log`, `/tmp/tt-fastener-graph-final.log` and `/tmp/tt-fastener-art-catalog.log`.

The fixture explicitly supplies upstream metals, sheets, machine tools, water, fuel and electrical conductors; it is not evidence of natural historical emergence. Final equipment is manufactured, not commissioned in this test. Existing operating-plant behavior already consumes these resource identities. The model does not simulate thread tolerances, fatigue, bolt preload, alloy selection, corrosion, weld strength, pressure-test measurements or individual spring rates. Split washers are a manufactured component, not an automatic guarantee against loosening.

## Historical grounding

[NASA's Fastener Design Manual](https://ntrs.nasa.gov/api/citations/19900009424/downloads/19900009424.pdf) distinguishes thread forms, washers, locking methods and rivets as engineering choices. These distinctions inform the separate joint and inspection subjects; modern aerospace requirements are not imposed as historical unlock dates. The [National Park Service account of Bay Area shipbuilding](https://www.nps.gov/articles/000/world-war-ii-shipbuilding-in-the-san-francisco-bay-area.htm) describes riveted plate joining and the later transition to welding. Game material quantities and work rates are authored batch values, not historical measurements or fabrication instructions.

## Handoff and remaining work

Implementation worktree: `/Users/seanpurtill/Documents/Codex/tt-technology-implementation`; branch `codex/technology-implementation`; original base `940d5a2ad848d9f45b8d98825cd5219a3eda83e9`; preceding commit `c741823`.

Shared integration files: `scripts/discovery_system.gd`, `scripts/civilian_industry.gd`, the technology graph audit and art catalog. Existing recipe definitions and saves are preserved; new recipes and new resource identifiers are additive within the current production authority. No canonical integration, player launch or artwork generation occurred in this batch.

Counts: 556 authored discoveries, 240 civilian recipes, 12 operating plant types, 78 reviewed illustrations. Remaining: 4,444 discovery identities and 4,922 illustrations against the 5,000 target; 478 currently live discoveries still await artwork. Full 2,500–3,000-year pacing, broader historical/future coverage and combined canonical acceptance remain incomplete.
