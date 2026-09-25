extends RefCounted
## Distinct textile routes. Quantities and losses are explicit game batches.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "yarn_count_standards",
    "name": "Yarn-Count Standards",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "standard_measures",
      "drop_spindles"
    ],
    "requires_all": [
      "standard_measures",
      "drop_spindles"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Yarn-Count Standards",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "Describe and compare yarn linear density through maintained conventions",
    "effects": {},
    "production_items": ["measured_yarn", "measured_drawloom_cloth"],
    "production_contract": "Sample and measure a declared yarn-count class using a maintained length reel and balance, consuming sample yarn, clay records and work. Measured Yarn supports matched-feed weaving; this does not certify every yarn property."
  },
  {
    "id": "yarn_tension_control",
    "name": "Yarn-Tension Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "plain_weaving",
      "feedback_governors"
    ],
    "requires_all": [
      "plain_weaving",
      "feedback_governors"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Yarn-Tension Control",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "Manage yarn loading through a qualified textile process",
    "effects": {},
    "production_items": [
      "tensioned_woven_cloth"
    ],
    "production_contract": "Use installed mechanical tension control and actual Measured Yarn in a distinct weaving route with lower modeled feed loss. Governors and loom tooling are paid; knowledge alone does not improve other workshops."
  },
  {
    "id": "ring_spinning_systems",
    "name": "Ring-Spinning Systems",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "flyer_spinning",
      "rotational_dynamics"
    ],
    "requires_all": [
      "flyer_spinning",
      "rotational_dynamics"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Ring-Spinning Systems",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "Form and wind yarn through a qualified rotating spindle and traveler arrangement",
    "effects": {},
    "production_items": [
      "hand_ring_yarn",
      "electric_ring_yarn"
    ],
    "production_contract": "Ring-and-traveler tooling twists combed fiber into yarn. The hand-driven route remains slower; the motor route needs installed motors and generated electricity for every batch. Products serve existing weaving and sewing."
  },
  {
    "id": "rotor_spinning_systems",
    "name": "Rotor-Spinning Systems",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "drop_spindles",
      "rotational_dynamics",
      "electric_motors"
    ],
    "requires_all": [
      "drop_spindles",
      "rotational_dynamics",
      "electric_motors"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Rotor-Spinning Systems",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "Collect and twist prepared fibers in a qualified rotating chamber",
    "effects": {},
    "production_items": [
      "rotor_spun_yarn"
    ],
    "production_contract": "Open and feed prepared staple fiber into a powered rotating chamber. Rotor spinning uses its own higher material allowance and consumes real electricity; no yarn or power appears from knowledge."
  },
  {
    "id": "drawloom_pattern_control",
    "name": "Drawloom-Pattern Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "plain_weaving",
      "crew_handoffs"
    ],
    "requires_all": [
      "plain_weaving",
      "crew_handoffs"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Drawloom-Pattern Control",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "Select groups of warp threads for controlled figured weaving",
    "effects": {},
    "production_items": ["drawloom_figured_cloth"],
    "production_contract": "Pay for a drawloom and manually select warp groups while consuming yarn and work to make Figured Cloth. Measured feed reduces modeled offcuts. Imported figured cloth can be sewn without teaching loom manufacture."
  },
  {
    "id": "punched_card_loom_control",
    "name": "Punched-Card Loom Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "drawloom_pattern_control",
      "pictographic_records"
    ],
    "requires_all": [
      "drawloom_pattern_control",
      "pictographic_records"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Punched-Card Loom Control",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "Use a physical sequence of encoded selections to control a compatible loom",
    "effects": {},
    "production_items": [
      "loom_pattern_cards",
      "card_figured_cloth",
      "measured_card_cloth"
    ],
    "production_contract": "Punch and lace physical Loom Pattern Cards, then consume a small replacement allowance while selecting warp groups in a compatible loom. The card route saves weaving work but requires actual cards and tooling. Figured Cloth serves household garment production."
  }
]
