extends RefCounted
## Unregistered worker candidates; preserve authored ALL/OR predicates.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "timber_post_beam_connections",
    "name": "Timber Post Beam Connections",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "joinery",
      "timber_grading"
    ],
    "requires_all": [
      "joinery",
      "timber_grading"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Timber Post Beam Connections",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Qualify fitted connections between structural posts and beams for stated loads",
    "effects": {},
    "operating_contract": "Appropriate timber, craft tools, fitted joints and inspection",
    "production_items": [
      "fitted_post_beam_sets"
    ],
    "production_contract": "Prepare finite components; installed plot work and accepted selected measurements are required separately. Component manufacture alone grants no building service."
  },
  {
    "id": "timber_splice_connections",
    "name": "Timber Splice Connections",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "joinery",
      "timber_grading"
    ],
    "requires_all": [
      "joinery",
      "timber_grading"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Timber Splice Connections",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Join structural timber lengths through an evaluated load-transfer connection",
    "effects": {},
    "operating_contract": "Suitable members, fitted connections and qualified craft work",
    "production_items": [
      "fitted_splice_sets"
    ],
    "production_contract": "Prepare finite components; installed plot work and accepted selected measurements are required separately. Component manufacture alone grants no building service."
  },
  {
    "id": "timber_lateral_bracing",
    "name": "Timber Lateral Bracing",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "framed_construction"
    ],
    "requires_all": [
      "framed_construction"
    ],
    "requires_any": [
      [
        "structural_load_testing",
        "experimental_controls"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Timber Lateral Bracing",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Provide evaluated paths for lateral loads through a timber frame",
    "effects": {},
    "operating_contract": "Qualified braces, connections, foundations and skilled construction",
    "production_items": [
      "timber_brace_sets"
    ],
    "production_contract": "Prepare finite components; installed plot work and accepted selected measurements are required separately. Component manufacture alone grants no building service."
  },
  {
    "id": "timber_moisture_movement_design",
    "name": "Timber Moisture Movement Design",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "timber_seasoning"
    ],
    "requires_all": [
      "timber_seasoning"
    ],
    "requires_any": [
      [
        "masonry_moisture_management",
        "experimental_controls"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Timber Moisture Movement Design",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Accommodate measured wood dimensional changes at building joints and interfaces",
    "effects": {},
    "operating_contract": "Known timber condition, suitable details and qualified installers",
    "production_items": [
      "movement_joint_sets"
    ],
    "production_contract": "Prepare finite components; installed plot work and accepted selected measurements are required separately. Component manufacture alone grants no building service."
  },
  {
    "id": "building_drainage_coordination",
    "name": "Building-Drainage Coordination",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "drainage",
      "household_space_planning"
    ],
    "requires_all": [
      "drainage",
      "household_space_planning"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Building-Drainage Coordination",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Route building runoff and waste flows through compatible maintained connections",
    "effects": {},
    "operating_contract": "Suitable drains, gradients or pumps and receiving capacity",
    "production_items": [
      "building_runoff_channels"
    ],
    "production_contract": "Prepare finite components; installed plot work and accepted selected measurements are required separately. Component manufacture alone grants no building service."
  },
  {
    "id": "building_wind_load_assessment",
    "name": "Building Wind-Load Assessment",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "aerodynamics",
      "structural_load_testing"
    ],
    "requires_all": [
      "aerodynamics",
      "structural_load_testing"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Building Wind-Load Assessment",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Estimate and test wind effects on a structure and its components",
    "effects": {},
    "operating_contract": "Site evidence, qualified models or tests and declared assumptions",
    "production_items": [
      "building_wind_trial_frames"
    ],
    "production_contract": "Prepare finite components; installed plot work and accepted selected measurements are required separately. Component manufacture alone grants no building service."
  },
  {
    "id": "building_capillary_breaks",
    "name": "Building Capillary Breaks",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "masonry_moisture_management"
    ],
    "requires_all": [
      "masonry_moisture_management"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Building Capillary Breaks",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Interrupt supported liquid-water movement across an assembly interface",
    "effects": {},
    "operating_contract": "Compatible barrier materials, continuity and skilled installation",
    "production_items": [
      "capillary_break_courses"
    ],
    "production_contract": "Prepare finite components; installed plot work and accepted selected measurements are required separately. Component manufacture alone grants no building service."
  },
  {
    "id": "roof_flashing_interfaces",
    "name": "Roof Flashing Interfaces",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "building_drainage_coordination"
    ],
    "requires_all": [
      "building_drainage_coordination"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Roof Flashing Interfaces",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Direct water across roof edges, penetrations and adjoining surfaces through qualified interfaces",
    "effects": {},
    "operating_contract": "Compatible flashing, skilled installation and inspection access",
    "production_items": [
      "roof_flashing_pieces"
    ],
    "production_contract": "Prepare finite components; installed plot work and accepted selected measurements are required separately. Component manufacture alone grants no building service."
  },
  {
    "id": "rainscreen_wall_assemblies",
    "name": "Rainscreen Wall Assemblies",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "building_drainage_coordination",
      "building_wind_load_assessment"
    ],
    "requires_all": [
      "building_drainage_coordination",
      "building_wind_load_assessment"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Rainscreen Wall Assemblies",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Separate an outer rain-shedding layer from a drained and protected inner wall",
    "effects": {},
    "operating_contract": "Compatible cladding, cavity, drainage and qualified supports",
    "production_items": [
      "rainscreen_batten_panels"
    ],
    "production_contract": "Prepare finite components; installed plot work and accepted selected measurements are required separately. Component manufacture alone grants no building service."
  },
  {
    "id": "building_shading_design",
    "name": "Building-Shading Design",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "seasonal_patterns",
      "geometric_survey"
    ],
    "requires_all": [
      "seasonal_patterns",
      "geometric_survey"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Building-Shading Design",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Limit or admit solar exposure through qualified orientation and shading",
    "effects": {},
    "operating_contract": "Suitable geometry, materials and seasonal observations",
    "production_items": [
      "building_shade_lattices"
    ],
    "production_contract": "Prepare finite components; installed plot work and accepted selected measurements are required separately. Component manufacture alone grants no building service."
  }
]
