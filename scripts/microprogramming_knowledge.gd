extends RefCounted
## Authored control-store and processor-control manufacturing methods.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "diode_control_stores",
    "name": "Diode Control Stores",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "diode_logic",
      "memory_address_decoding"
    ],
    "requires_all": [
      "diode_logic",
      "memory_address_decoding"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Diode Control Stores",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "crafting",
      "materials"
    ],
    "observation": "A wired diode matrix stores repeatable low-level control words selected by an address decoder.",
    "effects": {},
    "production_items": [
      "diode_control_store"
    ],
    "production_contract": "Manufactured control components consume real electronics, tooling and Crafting work. An alternative assembly route supplies Programmable Controllers for commissioned powered workshops; ordinary controller production remains available."
  },
  {
    "id": "microinstruction_sequencing",
    "name": "Microinstruction Sequencing",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "program_counters",
      "conditional_branch_circuits"
    ],
    "requires_all": [
      "program_counters",
      "conditional_branch_circuits"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Microinstruction Sequencing",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "crafting",
      "materials"
    ],
    "observation": "A dedicated sequencer chooses the next control word, including conditional paths within an instruction.",
    "effects": {},
    "production_items": [
      "microsequencer"
    ],
    "production_contract": "Manufactured control components consume real electronics, tooling and Crafting work. An alternative assembly route supplies Programmable Controllers for commissioned powered workshops; ordinary controller production remains available."
  },
  {
    "id": "arithmetic_logic_units",
    "name": "Arithmetic-Logic Units",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "binary_adders",
      "transistor_inverters",
      "parallel_register_banks"
    ],
    "requires_all": [
      "binary_adders",
      "transistor_inverters",
      "parallel_register_banks"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Arithmetic-Logic Units",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "crafting",
      "materials"
    ],
    "observation": "A selected operation directs shared registers through arithmetic or logical circuitry.",
    "effects": {},
    "production_items": [
      "arithmetic_logic_unit"
    ],
    "production_contract": "Manufactured control components consume real electronics, tooling and Crafting work. An alternative assembly route supplies Programmable Controllers for commissioned powered workshops; ordinary controller production remains available."
  },
  {
    "id": "microprogrammed_machine_control",
    "name": "Microprogrammed Machine Control",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "diode_control_stores",
      "microinstruction_sequencing",
      "arithmetic_logic_units",
      "stored_program_control"
    ],
    "requires_all": [
      "diode_control_stores",
      "microinstruction_sequencing",
      "arithmetic_logic_units",
      "stored_program_control"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Microprogrammed Machine Control",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "crafting",
      "materials"
    ],
    "observation": "Stored control words coordinate an arithmetic datapath and machine interfaces to execute a programmable controller design.",
    "effects": {},
    "production_items": [
      "microprogrammed_controller"
    ],
    "production_contract": "Manufactured control components consume real electronics, tooling and Crafting work. An alternative assembly route supplies Programmable Controllers for commissioned powered workshops; ordinary controller production remains available."
  }
]
