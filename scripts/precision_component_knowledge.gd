extends RefCounted
## Selected component grades use existing production, workforce and stock owners.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "reamed_bore_finishing",
    "name": "Reamed Bore Finishing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "column_drilling_machines",
      "dimensional_metrology"
    ],
    "requires_all": [
      "column_drilling_machines",
      "dimensional_metrology"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Reamed Bore Finishing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A multi-edge tool finishes an already prepared hole.",
    "effects": {},
    "production_items": [
      "precision_reamers",
      "reamed_sleeves_20"
    ],
    "production_contract": "Produce paid finishing reamers and consume pilot-bored sleeves with reamer wear into gauged 20 mm sleeves. Rough holes and generic bearings do not satisfy the named finished-sleeve feed. These sleeves enter the separate fit-check and motor-assembly route."
  },
  {
    "id": "reciprocating_profile_slotting",
    "name": "Reciprocating Profile Slotting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "crank_linkages",
      "toolbit_heat_treatment"
    ],
    "requires_all": [
      "crank_linkages",
      "toolbit_heat_treatment"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Reciprocating Profile Slotting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Repeated single-tool strokes remove material from a slot.",
    "effects": {},
    "production_items": [
      "slotting_rams",
      "slotted_drive_hubs"
    ],
    "production_contract": "Build guided crank-driven slotting rams, then pay single-tool cutting work and tool wear to make keyed clutch hubs. A hub is consumed by the existing clutch assembly operation; installed rams also support the separately known gear-shaping process."
  },
  {
    "id": "gear_shaping_generation",
    "name": "Gear Shaping Generation",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "gear_tooth_generation",
      "precision_machinery"
    ],
    "requires_all": [
      "gear_tooth_generation",
      "precision_machinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Gear Shaping Generation",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A reciprocating cutter generates meshing tooth geometry.",
    "effects": {},
    "production_items": [
      "gear_shaping_cutters",
      "shaped_gear_sets"
    ],
    "production_contract": "Produce a relieved gear-shaping cutter and use it with a paid reciprocating ram, indexing setup, steel feed and cutter wear to generate compatible gears. Completed gears are consumed by existing geared-workshop commissioning; possession of gears grants no power or synthesis knowledge."
  },
  {
    "id": "progressive_profile_broaching",
    "name": "Progressive Profile Broaching",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "toolbit_heat_treatment",
      "precision_machinery"
    ],
    "requires_all": [
      "toolbit_heat_treatment",
      "precision_machinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Progressive Profile Broaching",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Successively larger cutting teeth produce a finished profile.",
    "effects": {},
    "production_items": [
      "progressive_keyway_broaches",
      "broached_drive_hubs"
    ],
    "production_contract": "Produce a progressive-tooth keyway broach and use a paid press/fixture with turned stock and broach wear to make keyed clutch hubs in less repeated cutting work than the slotting route. Expensive tooling and actual compatible stock are still required."
  },
  {
    "id": "interchangeable_component_fits",
    "name": "Interchangeable Component Fits",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "dimensional_metrology",
      "workshop_standards"
    ],
    "requires_all": [
      "dimensional_metrology",
      "workshop_standards"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Interchangeable Component Fits",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Specify and verify compatible dimensional ranges across separately made components",
    "effects": {},
    "production_items": [
      "fit_gauges_20",
      "interchangeable_bearings_20"
    ],
    "production_contract": "Produce gauges for the selected nominal 20 mm shaft/sleeve family, then pay comparison/fit work, actual turned shafts, reamed sleeves, lubricant and sample material into interchangeable bearing assemblies. Those actual assemblies are consumed by a compatible electric-motor recipe. Sizes, tolerances and rejection yield are bounded product-grade abstractions, not a dimensional physics simulator or universal fit certificate."
  }
]
