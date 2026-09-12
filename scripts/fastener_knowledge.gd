extends RefCounted
## Individually authored threaded joints, spring hardware and riveted assemblies.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "bolt_blank_forging",
    "name": "Bolt Blank Forging",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "forge_welding",
      "standard_measures"
    ],
    "requires_all": [
      "forge_welding",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Bolt Blank Forging",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A headed metal blank is formed before its shank receives a thread, separating head shaping from fitting.",
    "effects": {},
    "production_items": [
      "bolt_blanks"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "nut_blank_forging",
    "name": "Nut Blank Forging",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "forge_welding",
      "standard_measures"
    ],
    "requires_all": [
      "forge_welding",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Nut Blank Forging",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Repeated nut blanks leave enough metal around a future bore for a wrench to transmit turning force.",
    "effects": {},
    "production_items": [
      "nut_blanks"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "nut_bore_drilling",
    "name": "Nut Bore Drilling",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "nut_blank_forging",
      "column_drilling_machines"
    ],
    "requires_all": [
      "nut_blank_forging",
      "column_drilling_machines"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Nut Bore Drilling",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A supported blank is drilled through before an internal thread is cut, keeping the bore aligned with its bearing faces.",
    "effects": {},
    "production_items": [
      "bored_nut_blanks"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "thread_tap_cutting",
    "name": "Thread Tap Cutting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lead_screw_cutting",
      "toolbit_heat_treatment"
    ],
    "requires_all": [
      "lead_screw_cutting",
      "toolbit_heat_treatment"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Thread Tap Cutting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A hardened threaded tool with cutting relief makes matching internal threads in a prepared bore.",
    "effects": {},
    "production_items": [
      "thread_taps"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "thread_die_cutting",
    "name": "Thread Die Cutting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "thread_tap_cutting",
      "toolbit_heat_treatment"
    ],
    "requires_all": [
      "thread_tap_cutting",
      "toolbit_heat_treatment"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Thread Die Cutting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A relieved threaded die guides the cutting of an external screw thread on a prepared shank.",
    "effects": {},
    "production_items": [
      "thread_dies"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "external_thread_cutting",
    "name": "External Thread Cutting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "bolt_blank_forging",
      "thread_die_cutting"
    ],
    "requires_all": [
      "bolt_blank_forging",
      "thread_die_cutting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "External Thread Cutting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A die advances along a headed blank while chips are cleared, producing a bolt that can be fitted to a nut.",
    "effects": {},
    "production_items": [
      "cut_bolts"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "internal_thread_tapping",
    "name": "Internal Thread Tapping",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "nut_bore_drilling",
      "thread_tap_cutting"
    ],
    "requires_all": [
      "nut_bore_drilling",
      "thread_tap_cutting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Internal Thread Tapping",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A tap cuts a helical bearing surface inside a drilled nut without replacing the surrounding material with an assumed fit.",
    "effects": {},
    "production_items": [
      "threaded_nuts"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "thread_pitch_gauging",
    "name": "Thread Pitch Gauging",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lead_screw_cutting",
      "standard_measures"
    ],
    "requires_all": [
      "lead_screw_cutting",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Thread Pitch Gauging",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A reference profile distinguishes thread spacing so parts with superficially similar diameters are not treated as interchangeable.",
    "effects": {},
    "production_items": [
      "thread_pitch_gauges"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "matched_thread_inspection",
    "name": "Matched Thread Inspection",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "thread_pitch_gauging",
      "internal_thread_tapping"
    ],
    "requires_all": [
      "thread_pitch_gauging",
      "internal_thread_tapping"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "cut_threads",
        "label": "Inspect cut threads",
        "requires_all": [
          "external_thread_cutting"
        ]
      },
      {
        "id": "rolled_threads",
        "label": "Inspect rolled threads",
        "requires_all": [
          "bolt_thread_rolling"
        ]
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Bolts and nuts are checked together against the same thread reference before they are counted as matching fasteners.",
    "effects": {},
    "production_items": [
      "matched_cut_fasteners",
      "matched_rolled_fasteners"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "washer_punching",
    "name": "Washer Punching",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "sheet_steel_rolling",
      "standard_measures"
    ],
    "requires_all": [
      "sheet_steel_rolling",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Washer Punching",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A hole and outer edge are punched from sheet metal to create a bearing washer around a fastener.",
    "effects": {},
    "production_items": [
      "flat_washers"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "cotter_pin_forming",
    "name": "Cotter Pin Forming",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "wire_drawing",
      "forge_welding"
    ],
    "requires_all": [
      "wire_drawing",
      "forge_welding"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Cotter Pin Forming",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A narrow ductile strip is folded into a split pin that can pass through a drilled fastener and have its legs spread.",
    "effects": {},
    "production_items": [
      "cotter_pins"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "castellated_nut_slotting",
    "name": "Castellated Nut Slotting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "internal_thread_tapping",
      "horizontal_milling_machines"
    ],
    "requires_all": [
      "internal_thread_tapping",
      "horizontal_milling_machines"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Castellated Nut Slotting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Slots around the end of a nut provide positions through which a retaining pin can block its rotation.",
    "effects": {},
    "production_items": [
      "castellated_nuts"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "split_pin_locking",
    "name": "Split-Pin Locking",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "castellated_nut_slotting",
      "cotter_pin_forming",
      "column_drilling_machines"
    ],
    "requires_all": [
      "castellated_nut_slotting",
      "cotter_pin_forming",
      "column_drilling_machines"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Split-Pin Locking",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A bolt is cross-drilled and assembled with a slotted nut and split pin, giving a visible positive restraint against nut rotation.",
    "effects": {},
    "production_items": [
      "locked_fastener_sets"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "steel_wire_drawing",
    "name": "Steel Wire Drawing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "wire_drawing",
      "toolbit_heat_treatment"
    ],
    "requires_all": [
      "wire_drawing",
      "toolbit_heat_treatment"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Steel Wire Drawing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Steel rod is reduced through successive drawing passes, providing wire feedstock for small resilient components.",
    "effects": {},
    "production_items": [
      "steel_wire"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "spring_wire_coiling",
    "name": "Spring Wire Coiling",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "steel_wire_drawing",
      "tailstock_fitting"
    ],
    "requires_all": [
      "steel_wire_drawing",
      "tailstock_fitting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Spring Wire Coiling",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Wire is guided around a mandrel so repeated turns retain a controlled coil form.",
    "effects": {},
    "production_items": [
      "coiled_spring_blanks"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "coil_spring_tempering",
    "name": "Coil Spring Tempering",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "spring_wire_coiling",
      "toolbit_heat_treatment"
    ],
    "requires_all": [
      "spring_wire_coiling",
      "toolbit_heat_treatment"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Coil Spring Tempering",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Formed spring stock receives controlled heating and cooling before it is used as a resilient component.",
    "effects": {},
    "production_items": [
      "tempered_spring_coils"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "split_washer_cutting",
    "name": "Split Washer Cutting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "coil_spring_tempering",
      "washer_punching"
    ],
    "requires_all": [
      "coil_spring_tempering",
      "washer_punching"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Split Washer Cutting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Short helical sections are cut from prepared spring stock and dressed into split washers; their presence alone is not treated as a guarantee against loosening.",
    "effects": {},
    "production_items": [
      "split_washers"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "rivet_blank_heading",
    "name": "Rivet Blank Heading",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "forge_welding",
      "standard_measures"
    ],
    "requires_all": [
      "forge_welding",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Rivet Blank Heading",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A short shank receives one formed head while enough length is left for a second head to be made during joining.",
    "effects": {},
    "production_items": [
      "rivet_blanks"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "rivet_hole_alignment",
    "name": "Rivet Hole Alignment",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "sheet_steel_rolling",
      "drill_jig_layout"
    ],
    "requires_all": [
      "sheet_steel_rolling",
      "drill_jig_layout"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Rivet Hole Alignment",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Overlapping plates are located and drilled as a matching joint so rivets can pass through aligned holes.",
    "effects": {},
    "production_items": [
      "aligned_rivet_plates"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "hot_rivet_setting",
    "name": "Hot Rivet Setting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "rivet_blank_heading",
      "rivet_hole_alignment"
    ],
    "requires_all": [
      "rivet_blank_heading",
      "rivet_hole_alignment"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Hot Rivet Setting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A heated rivet is supported from one side while its tail is upset on the other, drawing the overlapping joint together as it cools.",
    "effects": {},
    "production_items": [
      "hot_riveted_panels"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "cold_rivet_setting",
    "name": "Cold Rivet Setting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "rivet_blank_heading",
      "rivet_hole_alignment"
    ],
    "requires_all": [
      "rivet_blank_heading",
      "rivet_hole_alignment"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Cold Rivet Setting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Smaller ductile rivets are upset without a heating stage to join light sheet assemblies.",
    "effects": {},
    "production_items": [
      "cold_riveted_panels"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "thread_rolling_die_making",
    "name": "Thread-Rolling Die Making",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "thread_pitch_gauging",
      "horizontal_milling_machines",
      "toolbit_heat_treatment"
    ],
    "requires_all": [
      "thread_pitch_gauging",
      "horizontal_milling_machines",
      "toolbit_heat_treatment"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Thread-Rolling Die Making",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Hardened dies carry the negative thread profile needed to displace a blank surface into a repeated helix.",
    "effects": {},
    "production_items": [
      "thread_rolling_dies"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "bolt_thread_rolling",
    "name": "Bolt Thread Rolling",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "bolt_blank_forging",
      "thread_rolling_die_making"
    ],
    "requires_all": [
      "bolt_blank_forging",
      "thread_rolling_die_making"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Bolt Thread Rolling",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A blank is pressed between profiled dies so displaced metal forms its thread rather than being removed as chips.",
    "effects": {},
    "production_items": [
      "rolled_bolts"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  },
  {
    "id": "standard_fastener_kitting",
    "name": "Standard Fastener Kitting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "matched_thread_inspection",
      "washer_punching",
      "split_washer_cutting"
    ],
    "requires_all": [
      "matched_thread_inspection",
      "washer_punching",
      "split_washer_cutting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Standard Fastener Kitting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Matched fasteners and washers are issued as a counted assembly set, reducing fitting work at the final machine bench without creating free components.",
    "effects": {},
    "production_items": [
      "machine_fastener_sets",
      "locked_machine_fastener_sets"
    ],
    "production_contract": "Consumes recorded metal components, paid reusable tooling and finite workshop work. Finished joint components feed fastener sets, motor assembly or riveted pressure-vessel assembly; knowledge grants no free stock, global strength bonus or machine service."
  }
]
