extends RefCounted
## Individually authored circuit functions and physical manufacturing routes.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "carbon_resistors",
    "name": "Carbon Resistors",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "electrical_measurement",
      "graphite_marking"
    ],
    "requires_all": [
      "electrical_measurement",
      "graphite_marking"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Carbon Resistors",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A measured carbon path supplies repeatable electrical resistance between metal contacts.",
    "effects": {},
    "production_items": [
      "carbon_resistors"
    ],
    "production_contract": "Enables a physical component-manufacturing line with paid tooling, materials, labor and any specified power. Components feed amplifiers, sensors and machine controllers; commissioned controlled workshops require machinery, operators and shared electricity. Knowledge supplies no free equipment or service."
  },
  {
    "id": "foil_capacitors",
    "name": "Foil Capacitors",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "electrical_measurement",
      "paper_making",
      "wire_drawing"
    ],
    "requires_all": [
      "electrical_measurement",
      "paper_making",
      "wire_drawing"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Foil Capacitors",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Conducting foils separated by an insulating paper layer store charge without a continuous conducting path.",
    "effects": {},
    "production_items": [
      "foil_capacitors"
    ],
    "production_contract": "Enables a physical component-manufacturing line with paid tooling, materials, labor and any specified power. Components feed amplifiers, sensors and machine controllers; commissioned controlled workshops require machinery, operators and shared electricity. Knowledge supplies no free equipment or service."
  },
  {
    "id": "electromagnetic_relays",
    "name": "Electromagnetic Relays",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "electromagnetic_induction",
      "wire_drawing"
    ],
    "requires_all": [
      "electromagnetic_induction",
      "wire_drawing"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Electromagnetic Relays",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A current-carrying coil moves an iron armature to switch a separate circuit.",
    "effects": {},
    "production_items": [
      "electromagnetic_relays"
    ],
    "production_contract": "Enables a physical component-manufacturing line with paid tooling, materials, labor and any specified power. Components feed amplifiers, sensors and machine controllers; commissioned controlled workshops require machinery, operators and shared electricity. Knowledge supplies no free equipment or service."
  },
  {
    "id": "wound_transformers",
    "name": "Wound Transformers",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "electromagnetic_induction",
      "cable_insulation"
    ],
    "requires_all": [
      "electromagnetic_induction",
      "cable_insulation"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Wound Transformers",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Coupled windings transfer changing electrical excitation through a magnetic core at a winding-dependent voltage ratio.",
    "effects": {},
    "production_items": [
      "wound_transformers"
    ],
    "production_contract": "Enables a physical component-manufacturing line with paid tooling, materials, labor and any specified power. Components feed amplifiers, sensors and machine controllers; commissioned controlled workshops require machinery, operators and shared electricity. Knowledge supplies no free equipment or service."
  },
  {
    "id": "silicon_rectifiers",
    "name": "Silicon Rectifiers",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "pn_junctions",
      "wafer_sawing"
    ],
    "requires_all": [
      "pn_junctions",
      "wafer_sawing"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Silicon Rectifiers",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A manufactured silicon junction passes current much more readily in one direction than the other.",
    "effects": {},
    "production_items": [
      "silicon_rectifiers"
    ],
    "production_contract": "Enables a physical component-manufacturing line with paid tooling, materials, labor and any specified power. Components feed amplifiers, sensors and machine controllers; commissioned controlled workshops require machinery, operators and shared electricity. Knowledge supplies no free equipment or service."
  },
  {
    "id": "bipolar_junction_transistors",
    "name": "Bipolar Junction Transistors",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "pn_junctions",
      "semiconductor_doping"
    ],
    "requires_all": [
      "pn_junctions",
      "semiconductor_doping"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Bipolar Junction Transistors",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Two adjacent junctions let a small base signal control a larger collector current.",
    "effects": {},
    "production_items": [
      "bipolar_transistors"
    ],
    "production_contract": "Enables a physical component-manufacturing line with paid tooling, materials, labor and any specified power. Components feed amplifiers, sensors and machine controllers; commissioned controlled workshops require machinery, operators and shared electricity. Knowledge supplies no free equipment or service."
  },
  {
    "id": "transistor_amplifiers",
    "name": "Transistor Amplifiers",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "bipolar_junction_transistors",
      "carbon_resistors",
      "foil_capacitors"
    ],
    "requires_all": [
      "bipolar_junction_transistors",
      "carbon_resistors",
      "foil_capacitors"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Transistor Amplifiers",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A biased transistor circuit uses supplied power to amplify an input signal while passive components establish its operating range.",
    "effects": {},
    "production_items": [
      "transistor_amplifiers"
    ],
    "production_contract": "Enables a physical component-manufacturing line with paid tooling, materials, labor and any specified power. Components feed amplifiers, sensors and machine controllers; commissioned controlled workshops require machinery, operators and shared electricity. Knowledge supplies no free equipment or service."
  },
  {
    "id": "resistive_sensing",
    "name": "Resistive Sensing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "carbon_resistors",
      "electrical_measurement"
    ],
    "requires_all": [
      "carbon_resistors",
      "electrical_measurement"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Resistive Sensing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A calibrated change in resistance becomes a measurable signal of a changing physical condition.",
    "effects": {},
    "production_items": [
      "resistive_sensors"
    ],
    "production_contract": "Enables a physical component-manufacturing line with paid tooling, materials, labor and any specified power. Components feed amplifiers, sensors and machine controllers; commissioned controlled workshops require machinery, operators and shared electricity. Knowledge supplies no free equipment or service."
  },
  {
    "id": "electronic_machine_control",
    "name": "Electronic Machine Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "transistor_amplifiers",
      "resistive_sensing",
      "electromagnetic_relays",
      "wound_transformers",
      "silicon_rectifiers",
      "feedback_governors"
    ],
    "requires_all": [
      "transistor_amplifiers",
      "resistive_sensing",
      "electromagnetic_relays",
      "wound_transformers",
      "silicon_rectifiers",
      "feedback_governors"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Electronic Machine Control",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A sensor, amplifier and switching stage compare machine behavior with a reference and adjust its actuation.",
    "effects": {},
    "production_items": [
      "machine_controllers"
    ],
    "production_contract": "Enables a physical component-manufacturing line with paid tooling, materials, labor and any specified power. Components feed amplifiers, sensors and machine controllers; commissioned controlled workshops require machinery, operators and shared electricity. Knowledge supplies no free equipment or service.",
    "operating_plants": [
      "controlled_workshop"
    ]
  }
]
