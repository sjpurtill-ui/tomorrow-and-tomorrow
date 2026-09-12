extends RefCounted
## Six authored compressed-air engineering capabilities.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "pressure_pipe_jointing",
    "name": "Pressure Pipe Jointing",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "pressure_vessels",
      "workshop_standards"
    ],
    "requires_all": [
      "pressure_vessels",
      "workshop_standards"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Pressure Pipe Jointing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Joined metal pipes convey a compressed-air supply to machinery while connections are checked for leakage.",
    "effects": {},
    "production_items": [
      "pressure_pipe_fittings"
    ],
    "production_contract": "Actual stock, tooling and shared Crafting work make components. A commissioned press consumes finite compressed air and reserves operators for mechanical service; discovery alone supplies no work."
  },
  {
    "id": "cylinder_boring",
    "name": "Cylinder Boring",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "precision_machinery",
      "bearing_surfaces"
    ],
    "requires_all": [
      "precision_machinery",
      "bearing_surfaces"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Cylinder Boring",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A guided cutting tool produces a regular internal cylinder surface for a moving piston.",
    "effects": {},
    "production_items": [
      "bored_cylinders"
    ],
    "production_contract": "Actual stock, tooling and shared Crafting work make components. A commissioned press consumes finite compressed air and reserves operators for mechanical service; discovery alone supplies no work."
  },
  {
    "id": "packed_piston_seals",
    "name": "Packed Piston Seals",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "plain_weaving",
      "lubrication_regimes"
    ],
    "requires_all": [
      "plain_weaving",
      "lubrication_regimes"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Packed Piston Seals",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Prepared packing limits leakage around moving piston rods while accepting friction and eventual replacement.",
    "effects": {},
    "production_items": [
      "piston_packings"
    ],
    "production_contract": "Actual stock, tooling and shared Crafting work make components. A commissioned press consumes finite compressed air and reserves operators for mechanical service; discovery alone supplies no work."
  },
  {
    "id": "directional_air_valves",
    "name": "Directional Air Valves",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "pressure_pipe_jointing",
      "compressed_air_systems"
    ],
    "requires_all": [
      "pressure_pipe_jointing",
      "compressed_air_systems"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Directional Air Valves",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A valve alternately admits and exhausts compressed air to control actuator movement.",
    "effects": {},
    "production_items": [
      "directional_air_valve"
    ],
    "production_contract": "Actual stock, tooling and shared Crafting work make components. A commissioned press consumes finite compressed air and reserves operators for mechanical service; discovery alone supplies no work."
  },
  {
    "id": "pneumatic_cylinders",
    "name": "Pneumatic Cylinders",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "cylinder_boring",
      "packed_piston_seals",
      "directional_air_valves"
    ],
    "requires_all": [
      "cylinder_boring",
      "packed_piston_seals",
      "directional_air_valves"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Pneumatic Cylinders",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A sealed piston converts admitted compressed air into a controlled linear stroke.",
    "effects": {},
    "production_items": [
      "pneumatic_cylinder"
    ],
    "production_contract": "Actual stock, tooling and shared Crafting work make components. A commissioned press consumes finite compressed air and reserves operators for mechanical service; discovery alone supplies no work."
  },
  {
    "id": "pneumatic_pressing",
    "name": "Pneumatic Pressing",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "pneumatic_cylinders",
      "column_buckling",
      "workshop_standards"
    ],
    "requires_all": [
      "pneumatic_cylinders",
      "column_buckling",
      "workshop_standards"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Pneumatic Pressing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A braced frame and air cylinder apply repeatable pressing work; useful motion requires a real compressed-air supply.",
    "effects": {},
    "production_items": [
      "pneumatic_press"
    ],
    "production_contract": "Actual stock, tooling and shared Crafting work make components. A commissioned press consumes finite compressed air and reserves operators for mechanical service; discovery alone supplies no work.",
    "operating_plants": [
      "pneumatic_workshop"
    ]
  }
]
