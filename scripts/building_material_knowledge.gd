extends RefCounted
## Construction methods promoted from the reviewed master inventory.
static func entries()->Array:
	return [
  {
    "id": "voussoir_arch_assembly",
    "name": "Voussoir Arch Assembly",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "stone_sorting",
      "masonry_arch_centering"
    ],
    "requires_all": [
      "stone_sorting",
      "masonry_arch_centering"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Assemble shaped masonry units over temporary support so compression reaches suitable abutments",
    "effects": {},
    "production_items": [
      "voussoir_stones"
    ],
    "production_contract": "Compatible units, centering, qualified supports and skilled masons. Construct load-bearing masonry arches with actual thrust and settlement limits. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners."
  },
  {
    "id": "masonry_arch_centering",
    "name": "Masonry Arch Centering",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "standard_measures"
    ],
    "requires_all": [
      "standard_measures"
    ],
    "requires_any": [
      [
        "joinery",
        "rammed_earth_construction"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Support unfinished arch masonry with qualified removable temporary works",
    "effects": {},
    "production_items": [
      "arch_centering"
    ],
    "production_contract": "Suitable timber framing or earth support, stable ground, labor and inspection. Carry temporary loads until the completed arch can support its qualified duty. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners."
  },
  {
    "id": "masonry_bond_patterns",
    "name": "Masonry Bond Patterns",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lime_mortar",
      "stone_sorting"
    ],
    "requires_all": [
      "lime_mortar",
      "stone_sorting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Arrange masonry units and joints to distribute loads through evaluated wall bonds",
    "effects": {},
    "production_items": [],
    "production_contract": "Suitable units, compatible mortar, masons and inspection. Build coherent walls while workmanship and material condition constrain capacity. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners.",
    "building_method": "masonry_bond_patterns"
  },
  {
    "id": "mortar_compatibility_assessment",
    "name": "Mortar Compatibility Assessment",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lime_mortar",
      "masonry_moisture_management"
    ],
    "requires_all": [
      "lime_mortar",
      "masonry_moisture_management"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Match repair mortar behavior to existing masonry and environmental exposure",
    "effects": {},
    "production_items": [],
    "production_contract": "Characterized masonry, suitable trial mixes and qualified craft assessment. Repair joints without assuming harder mortar is always more compatible. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners.",
    "building_method": "mortar_compatibility_assessment"
  },
  {
    "id": "masonry_repointing",
    "name": "Masonry Repointing",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "mortar_compatibility_assessment"
    ],
    "requires_all": [
      "mortar_compatibility_assessment"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Renew deteriorated exposed mortar joints while preserving sound units and joint function",
    "effects": {},
    "production_items": [],
    "production_contract": "Compatible mortar, appropriate tools, access and trained masons. Restore selected joint service through real labor and materials. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners.",
    "building_method": "masonry_repointing"
  },
  {
    "id": "concrete_curing_control",
    "name": "Concrete Curing Control",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "concrete_mix_design"
    ],
    "requires_all": [
      "concrete_mix_design"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Maintain evaluated moisture and thermal conditions during concrete property development",
    "effects": {},
    "production_items": [],
    "production_contract": "Actual placed concrete, curing resources, time and inspection. Develop supported material properties rather than granting full capacity at placement. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners.",
    "building_method": "concrete_curing_control"
  },
  {
    "id": "concrete_compaction_practice",
    "name": "Concrete Compaction Practice",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "concrete_mix_design"
    ],
    "requires_all": [
      "concrete_mix_design"
    ],
    "requires_any": [
      [
        "concrete_formwork_systems",
        "experimental_controls"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Consolidate placed concrete through a qualified method while avoiding harmful segregation",
    "effects": {},
    "production_items": [],
    "production_contract": "Compatible mix, accessible forms, equipment or craft labor and inspection. Reduce selected voids while placement conditions still affect quality. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners.",
    "building_method": "concrete_compaction_practice"
  },
  {
    "id": "hydraulic_lime_binders",
    "name": "Hydraulic-Lime Binders",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lime_burning",
      "clay_testing"
    ],
    "requires_all": [
      "lime_burning",
      "clay_testing"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Prepare a qualified lime-based binder that can develop strength under damp conditions",
    "effects": {},
    "production_items": [
      "hydraulic_lime_binder"
    ],
    "production_contract": "Suitable feed, controlled burning, water and material tests. Offer binding behavior beyond air-lime systems with source and curing constraints. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners."
  },
  {
    "id": "pozzolanic_binder_blends",
    "name": "Pozzolanic Binder Blends",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lime_mortar",
      "clay_testing"
    ],
    "requires_all": [
      "lime_mortar",
      "clay_testing"
    ],
    "requires_any": [
      [
        "grain_milling",
        "grog_preparation"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Combine a lime-bearing binder with a characterized reactive mineral fraction",
    "effects": {},
    "production_items": [
      "pozzolanic_binder"
    ],
    "production_contract": "Suitable mineral feed, mixing, water and curing evidence. Alter durability and strength development without requiring one particular volcanic source. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners."
  },
  {
    "id": "clinker_cement",
    "name": "Clinker Cement",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "refractory_furnaces",
      "clay_testing",
      "material_accounting"
    ],
    "requires_all": [
      "refractory_furnaces",
      "clay_testing",
      "material_accounting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Produce and qualify a clinker-based hydraulic binder through controlled mineral processing",
    "effects": {},
    "production_items": ["cement_clinker", "ground_cement"],
    "production_contract": "Suitable mineral feed, kiln, grinding, energy and emissions management. Supply a repeatable binder at substantial heat and process-emission cost. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners."
  },
  {
    "id": "rammed_earth_construction",
    "name": "Rammed-Earth Construction",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "clay_testing",
      "structural_load_testing"
    ],
    "requires_all": [
      "clay_testing",
      "structural_load_testing"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Compact suitable earth within temporary forms to create qualified wall sections",
    "effects": {},
    "production_items": [
      "earth_ramming_frames"
    ],
    "production_contract": "Characterized soil, formwork, compaction labor and moisture detailing. Build massive walls while soil variability and water exposure constrain performance. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners."
  },
  {
    "id": "thatched_roofing",
    "name": "Thatched Roofing",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "fiber_grading",
      "framed_construction"
    ],
    "requires_all": [
      "fiber_grading",
      "framed_construction"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Arrange plant material to shed water over a supported roof",
    "effects": {},
    "production_items": [
      "thatch_panels"
    ],
    "production_contract": "Suitable vegetation, skilled fixing, roof pitch and periodic replacement. Provide a light covering with fire, decay and maintenance tradeoffs. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners."
  },
  {
    "id": "fired_roof_tiles",
    "name": "Fired Roof Tiles",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "kiln_control",
      "clay_tempering",
      "framed_construction"
    ],
    "requires_all": [
      "kiln_control",
      "clay_tempering",
      "framed_construction"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Form and fire overlapping ceramic units for a supported weathering surface",
    "effects": {},
    "production_items": [
      "roof_tiles"
    ],
    "production_contract": "Suitable clay, kiln energy, roof support and fixing. Provide replaceable roofing with weight, fracture and joint-leakage constraints. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners."
  },
  {
    "id": "shallow_foundation_assessment",
    "name": "Shallow-Foundation Assessment",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "soil_assays",
      "structural_load_testing"
    ],
    "requires_all": [
      "soil_assays",
      "structural_load_testing"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Compare near-surface ground behavior with a structure's expected load",
    "effects": {},
    "production_items": [
      "foundation_survey_kits"
    ],
    "production_contract": "Site observations, trial evidence and drainage assessment. Choose supported foundation arrangements without assuming uniform ground. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners.",
    "building_method": "shallow_foundation_assessment"
  },
  {
    "id": "foundation_settlement_monitoring",
    "name": "Foundation-Settlement Monitoring",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "geometric_survey",
      "shallow_foundation_assessment"
    ],
    "requires_all": [
      "geometric_survey",
      "shallow_foundation_assessment"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Measure movement of a loaded structure relative to maintained references",
    "effects": {},
    "production_items": [
      "settlement_gauges"
    ],
    "production_contract": "Survey points, instruments and repeated observations. Detect some progressive movement before treating early stability as permanent. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners.",
    "building_method": "foundation_settlement_monitoring"
  },
  {
    "id": "timber_roof_trusses",
    "name": "Timber Roof Trusses",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "joinery",
      "framed_construction",
      "structural_load_testing"
    ],
    "requires_all": [
      "joinery",
      "framed_construction",
      "structural_load_testing"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Carry roof loads through connected timber members with defined support paths",
    "effects": {},
    "production_items": [
      "timber_trusses"
    ],
    "production_contract": "Graded timber, qualified joints and erection labor. Span larger enclosed spaces while joint condition and load changes remain limiting. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners."
  },
  {
    "id": "masonry_buttressing",
    "name": "Masonry Buttressing",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lime_mortar",
      "structural_load_testing"
    ],
    "requires_all": [
      "lime_mortar",
      "structural_load_testing"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Provide external or integrated support against masonry thrust and instability",
    "effects": {},
    "production_items": [],
    "production_contract": "Suitable masonry, foundations and structural assessment. Stabilize selected forms while consuming space and material. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners.",
    "building_method": "masonry_buttressing"
  },
  {
    "id": "vaulted_masonry_roofs",
    "name": "Vaulted Masonry Roofs",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "voussoir_arch_assembly",
      "masonry_buttressing"
    ],
    "requires_all": [
      "voussoir_arch_assembly",
      "masonry_buttressing"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Extend compressed masonry forms across enclosed spaces with supported thrust paths",
    "effects": {},
    "production_items": [],
    "production_contract": "Qualified masonry, temporary support, foundations and skilled erection. Cover durable interior spaces with substantial weight and support demands. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners.",
    "building_method": "vaulted_masonry_roofs"
  },
  {
    "id": "domed_masonry_roofs",
    "name": "Domed Masonry Roofs",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "vaulted_masonry_roofs",
      "geometric_survey"
    ],
    "requires_all": [
      "vaulted_masonry_roofs",
      "geometric_survey"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Carry enclosure loads through a curved shell with assessed supports",
    "effects": {},
    "production_items": [],
    "production_contract": "Suitable geometry, masonry, temporary works and structural review. Enclose broad spaces while cracking and support movement threaten stability. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners.",
    "building_method": "domed_masonry_roofs"
  },
  {
    "id": "masonry_moisture_management",
    "name": "Masonry Moisture Management",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lime_mortar",
      "drainage"
    ],
    "requires_all": [
      "lime_mortar",
      "drainage"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Control water entry, movement and drying in a compatible masonry assembly",
    "effects": {},
    "production_items": [
      "masonry_drainage_beds"
    ],
    "production_contract": "Sound details, suitable materials, ventilation and maintenance. Reduce selected decay while trapped moisture or incompatible repairs can worsen it. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners.",
    "building_method": "masonry_moisture_management"
  },
  {
    "id": "concrete_mix_design",
    "name": "Concrete-Mix Design",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "standard_measures",
      "structural_load_testing"
    ],
    "requires_all": [
      "standard_measures",
      "structural_load_testing"
    ],
    "requires_any": [
      [
        "hydraulic_lime_binders",
        "pozzolanic_binder_blends",
        "clinker_cement"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Qualify aggregate, binder and water proportions for a declared placing and service condition",
    "effects": {},
    "production_items": [
      "hydraulic_concrete",
      "pozzolanic_concrete",
      "clinker_cement_concrete"
    ],
    "production_contract": "Characterized materials, controlled mixing, curing and test evidence. Produce supported concrete properties rather than assuming every mixture is equivalent. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners."
  },
  {
    "id": "concrete_formwork_systems",
    "name": "Concrete Formwork Systems",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "joinery",
      "concrete_mix_design"
    ],
    "requires_all": [
      "joinery",
      "concrete_mix_design"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local construction trials",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Support freshly placed material in a controlled geometry until it can carry required loads",
    "effects": {},
    "production_items": [
      "building_formwork"
    ],
    "production_contract": "Qualified forms, bracing, labor and release criteria. Build repeatable shapes while temporary-work failure can precede finished strength. Implementation uses paid workshop materials and the existing settlement construction and maintenance owners."
  }
]
