extends RefCounted
## Individually authored digital switching, storage, arithmetic and sequencing.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "relay_logic",
    "name": "Relay Logic",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "electromagnetic_relays"
    ],
    "requires_all": [
      "electromagnetic_relays"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Relay Logic",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Series and parallel switch contacts implement repeatable conditions using relay states.",
    "effects": {},
    "production_items": [
      "relay_logic_modules"
    ],
    "production_contract": "Manufactured logic and state-storage assemblies consume real components, tooling and workshop labor. Assemblies feed sequence controllers; installed sequencing workshops require commissioning work, operators and electricity. Knowing the method grants no free machinery."
  },
  {
    "id": "diode_logic",
    "name": "Diode Logic",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "silicon_rectifiers",
      "carbon_resistors"
    ],
    "requires_all": [
      "silicon_rectifiers",
      "carbon_resistors"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Diode Logic",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Networks of one-way junctions combine input levels; restoring or inverting a signal requires an active stage.",
    "effects": {},
    "production_items": [
      "diode_logic_modules"
    ],
    "production_contract": "Manufactured logic and state-storage assemblies consume real components, tooling and workshop labor. Assemblies feed sequence controllers; installed sequencing workshops require commissioning work, operators and electricity. Knowing the method grants no free machinery."
  },
  {
    "id": "transistor_inverters",
    "name": "Transistor Inverters",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "bipolar_junction_transistors",
      "carbon_resistors"
    ],
    "requires_all": [
      "bipolar_junction_transistors",
      "carbon_resistors"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Transistor Inverters",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A switching transistor makes a high input produce a low output and restores a usable output level.",
    "effects": {},
    "production_items": [
      "transistor_inverters"
    ],
    "production_contract": "Manufactured logic and state-storage assemblies consume real components, tooling and workshop labor. Assemblies feed sequence controllers; installed sequencing workshops require commissioning work, operators and electricity. Knowing the method grants no free machinery."
  },
  {
    "id": "bistable_multivibrators",
    "name": "Bistable Multivibrators",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "transistor_inverters"
    ],
    "requires_all": [
      "transistor_inverters"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Bistable Multivibrators",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Cross-coupled active stages retain one of two stable states until a switching input changes it.",
    "effects": {},
    "production_items": [
      "bistable_modules"
    ],
    "production_contract": "Manufactured logic and state-storage assemblies consume real components, tooling and workshop labor. Assemblies feed sequence controllers; installed sequencing workshops require commissioning work, operators and electricity. Knowing the method grants no free machinery."
  },
  {
    "id": "binary_counters",
    "name": "Binary Counters",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "bistable_multivibrators"
    ],
    "requires_all": [
      "bistable_multivibrators"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Binary Counters",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Linked bistable stages accumulate input pulses as a binary count.",
    "effects": {},
    "production_items": [
      "binary_counter_modules"
    ],
    "production_contract": "Manufactured logic and state-storage assemblies consume real components, tooling and workshop labor. Assemblies feed sequence controllers; installed sequencing workshops require commissioning work, operators and electricity. Knowing the method grants no free machinery."
  },
  {
    "id": "shift_registers",
    "name": "Shift Registers",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "bistable_multivibrators"
    ],
    "requires_all": [
      "bistable_multivibrators"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Shift Registers",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Clocked storage stages transfer a sequence of states one position at a time.",
    "effects": {},
    "production_items": [
      "shift_register_modules"
    ],
    "production_contract": "Manufactured logic and state-storage assemblies consume real components, tooling and workshop labor. Assemblies feed sequence controllers; installed sequencing workshops require commissioning work, operators and electricity. Knowing the method grants no free machinery."
  },
  {
    "id": "binary_adders",
    "name": "Binary Adders",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [],
    "requires_all": [],
    "requires_any": [
      [
        "relay_logic",
        "diode_logic"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Binary Adders",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Logic combinations produce a sum and carry from binary inputs; linked stages propagate the carry.",
    "effects": {},
    "production_items": [
      "relay_adders",
      "semiconductor_adders"
    ],
    "production_contract": "Manufactured logic and state-storage assemblies consume real components, tooling and workshop labor. Assemblies feed sequence controllers; installed sequencing workshops require commissioning work, operators and electricity. Knowing the method grants no free machinery."
  },
  {
    "id": "hardwired_sequence_control",
    "name": "Hardwired Sequence Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "binary_counters",
      "shift_registers",
      "binary_adders",
      "electronic_machine_control"
    ],
    "requires_all": [
      "binary_counters",
      "shift_registers",
      "binary_adders",
      "electronic_machine_control"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Hardwired Sequence Control",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Counters, stored states and fixed logic advance machinery through a wired sequence of operations in response to measured inputs.",
    "effects": {},
    "production_items": [
      "sequence_controllers"
    ],
    "production_contract": "Manufactured logic and state-storage assemblies consume real components, tooling and workshop labor. Assemblies feed sequence controllers; installed sequencing workshops require commissioning work, operators and electricity. Knowing the method grants no free machinery.",
    "operating_plants": [
      "sequenced_workshop"
    ]
  }
]
