extends RefCounted
## HELD until the physical line owner and all consumers are connected.
static func entries()->Array:
	return [
  {
    "id": "clay_pipe_forming",
    "name": "Clay Pipe Forming",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "clay_shaping",
      "clay_tempering"
    ],
    "requires_all": [
      "clay_shaping",
      "clay_tempering"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local conduit trials",
        "requires_all": []
      }
    ],
    "signals": [
      "freshwater",
      "construction",
      "crafting"
    ],
    "observation": "Shape continuous hollow clay sections with controlled walls and open ends.",
    "effects": {},
    "production_contract": "Suitable prepared clay, water, forming supports, drying space, potters and elapsed workshop time. Produces unfired conduit sections; malformed or cracked sections consume labor and clay without usable installed capacity.",
    "production_items": [
      "unfired_clay_conduits"
    ]
  },
  {
    "id": "ceramic_pipe_firing_qualification",
    "name": "Ceramic Pipe Firing Qualification",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "clay_pipe_forming",
      "kiln_control"
    ],
    "requires_all": [
      "clay_pipe_forming",
      "kiln_control"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local conduit trials",
        "requires_all": []
      }
    ],
    "signals": [
      "freshwater",
      "construction",
      "crafting"
    ],
    "observation": "Compare fired conduit batches for warping, absorption and fracture under declared service conditions.",
    "effects": {},
    "production_contract": "Actual dried pipe sections, kiln volume, fuel, firing labor and sacrificed test pieces. Releases a bounded batch of fired pipe for suitable service; poor firing raises rejection and repair demand. Early fired clay does not automatically gain modern vitrified-pipe performance.",
    "production_items": [
      "fired_clay_conduits"
    ]
  },
  {
    "id": "ceramic_pipe_fit_gauges",
    "name": "Ceramic Pipe Fit Gauges",
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
        "clay_shaping",
        "joinery"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local conduit trials",
        "requires_all": []
      }
    ],
    "signals": [
      "freshwater",
      "construction",
      "crafting"
    ],
    "observation": "Compare fired ends and bores with repeatable mating references.",
    "effects": {},
    "production_contract": "Reference gauges, cooled fired samples, inspectors and batch identity. Sorts compatible sections and rejects bad fits before crews spend transport and trench labor; it grants neither strength nor pressure certification.",
    "production_items": [
      "conduit_fit_gauges"
    ]
  },
  {
    "id": "clay_pipe_socket_jointing",
    "name": "Clay Pipe Socket Jointing",
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
        "lime_mortar",
        "clay_tempering"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local conduit trials",
        "requires_all": []
      }
    ],
    "signals": [
      "freshwater",
      "construction",
      "crafting"
    ],
    "observation": "Fit overlapping ceramic ends with a compatible placed joint seal.",
    "effects": {},
    "production_contract": "Matched pipe sections, seal material, joint access, placement labor and time for the chosen seal. Joins finite gravity-conduit lengths with retained leakage and movement limits; a clay seal remains available without lime technology.",
    "water_conveyance_method": "clay_pipe_socket_jointing"
  },
  {
    "id": "rigid_pipe_bedding",
    "name": "Rigid Pipe Bedding",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "drainage"
    ],
    "requires_all": [
      "drainage"
    ],
    "requires_any": [
      [
        "joinery",
        "clay_tempering"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local conduit trials",
        "requires_all": []
      }
    ],
    "signals": [
      "freshwater",
      "construction",
      "crafting"
    ],
    "observation": "Support a conduit continuously on a prepared trench bed and place compatible side support.",
    "effects": {},
    "production_contract": "Excavated alignment, suitable bedding material, hauling capacity and crews working around real buried services. Reduces unsupported spans and installation breakage for the treated length, at material and labor cost; poor ground can still settle.",
    "production_items": [
      "conduit_bedding"
    ]
  },
  {
    "id": "buried_pipe_load_assessment",
    "name": "Buried Pipe Load Assessment",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "rigid_pipe_bedding",
      "standard_measures"
    ],
    "requires_all": [
      "rigid_pipe_bedding",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local conduit trials",
        "requires_all": []
      }
    ],
    "signals": [
      "freshwater",
      "construction",
      "crafting"
    ],
    "observation": "Relate observed cover, surface loading and support to tested conduit resistance.",
    "effects": {},
    "production_contract": "Site observations, representative pipe loading trials, recorded geometry and trained assessors. Restricts feasible burial depths and traffic crossings; weak sections require stronger supply, better support or rerouting instead of a universal durability bonus.",
    "water_conveyance_method": "buried_pipe_load_assessment"
  },
  {
    "id": "conduit_infiltration_testing",
    "name": "Conduit Infiltration Testing",
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
        "clay_pipe_socket_jointing",
        "wooden_log_conduits",
        "pressure_pipe_jointing"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local conduit trials",
        "requires_all": []
      }
    ],
    "signals": [
      "freshwater",
      "construction",
      "crafting"
    ],
    "observation": "Compare water gained or lost across an isolated installed conduit section under recorded conditions.",
    "effects": {},
    "production_contract": "Reachable test ends, closures, water observations, measurement time and a crew able to distinguish leakage from storage change. Locates sections needing further investigation and prevents untested sections being treated as tight; consumes inspection time without automatically locating every individual defect.",
    "water_conveyance_method": "conduit_infiltration_testing"
  },
  {
    "id": "wooden_log_conduits",
    "name": "Wooden Log Conduits",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "joinery"
    ],
    "requires_all": [
      "joinery"
    ],
    "requires_any": [
      [
        "wheel_hub_boring",
        "cylinder_boring"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local conduit trials",
        "requires_all": []
      }
    ],
    "signals": [
      "freshwater",
      "construction",
      "crafting"
    ],
    "observation": "Bore timber lengths and fit adjoining ends into a continuous water passage.",
    "effects": {},
    "production_contract": "Suitable logs, maintained boring tools, timberworkers, joining labor and replaceable sections. Supplies a locally feasible conduit route where timber and boring skill exist; bore size, leakage and timber condition limit service.",
    "production_items": [
      "wooden_conduits"
    ]
  },
  {
    "id": "gravity_conduit_grade_control",
    "name": "Gravity Conduit Grade Control",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "geometric_survey",
      "drainage"
    ],
    "requires_all": [
      "geometric_survey",
      "drainage"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local conduit trials",
        "requires_all": []
      }
    ],
    "signals": [
      "freshwater",
      "construction",
      "crafting"
    ],
    "observation": "Set and check an installed conduit invert against an intended downhill alignment.",
    "effects": {},
    "production_contract": "Survey references, accessible work fronts, measuring tools and crews able to adjust bedding before covering. Makes chosen gravity flow paths feasible and exposes reverse grades before burial; terrain can demand extra excavation or another route.",
    "water_conveyance_method": "gravity_conduit_grade_control"
  },
  {
    "id": "sewer_rodding_service",
    "name": "Sewer Rodding Service",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "covered_sewers"
    ],
    "requires_all": [
      "covered_sewers"
    ],
    "requires_any": [
      [
        "joinery",
        "wire_drawing"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local conduit trials",
        "requires_all": []
      }
    ],
    "signals": [
      "freshwater",
      "construction",
      "crafting"
    ],
    "observation": "Pass connected rods and compatible clearing heads through accessible conduit runs.",
    "effects": {},
    "production_contract": "Actual access points, rods, cleaning heads, crews, waste handling and a reachable blockage. Restores part of obstructed service through finite maintenance work; inaccessible or structurally failed sections require excavation or replacement.",
    "production_items": [
      "conduit_rodding_sets"
    ]
  }
]
