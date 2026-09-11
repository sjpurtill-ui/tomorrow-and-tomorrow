extends RefCounted
## Authored memory access and stored-program control capabilities.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "relay_registers",
    "name": "Relay Registers",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "relay_logic"
    ],
    "requires_all": [
      "relay_logic"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Relay Registers",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Interlocked relay contacts retain a binary word while the register is powered.",
    "effects": {},
    "production_items": [
      "relay_register_units"
    ],
    "production_contract": "Physical register, memory and control assemblies require finite component stocks and workshop work. A commissioned programmable workshop additionally consumes shared power and operator labor; discovery alone supplies no machine or operating bonus."
  },
  {
    "id": "parallel_register_banks",
    "name": "Parallel Register Banks",
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
        "label": "Parallel Register Banks",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Grouped bistable circuits retain several words with separate access connections.",
    "effects": {},
    "production_items": [
      "parallel_register_units"
    ],
    "production_contract": "Physical register, memory and control assemblies require finite component stocks and workshop work. A commissioned programmable workshop additionally consumes shared power and operator labor; discovery alone supplies no machine or operating bonus."
  },
  {
    "id": "memory_address_decoding",
    "name": "Memory Address Decoding",
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
        "label": "Memory Address Decoding",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A pattern on address lines selects one storage location rather than every location at once.",
    "effects": {},
    "production_items": [
      "memory_decoders",
      "electronic_memory_decoders"
    ],
    "production_contract": "Physical register, memory and control assemblies require finite component stocks and workshop work. A commissioned programmable workshop additionally consumes shared power and operator labor; discovery alone supplies no machine or operating bonus."
  },
  {
    "id": "read_write_memory",
    "name": "Addressable Read/Write Memory",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "memory_address_decoding"
    ],
    "requires_all": [
      "memory_address_decoding"
    ],
    "requires_any": [
      [
        "relay_registers",
        "parallel_register_banks"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Addressable Read/Write Memory",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Selection and write control let a stored word be retrieved or replaced without manually rewiring its representation.",
    "effects": {},
    "production_items": [
      "relay_memory_units",
      "electronic_memory_units"
    ],
    "production_contract": "Physical register, memory and control assemblies require finite component stocks and workshop work. A commissioned programmable workshop additionally consumes shared power and operator labor; discovery alone supplies no machine or operating bonus."
  },
  {
    "id": "instruction_registers",
    "name": "Instruction Registers",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "shift_registers",
      "binary_counters"
    ],
    "requires_all": [
      "shift_registers",
      "binary_counters"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Instruction Registers",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A dedicated register holds the current instruction while control circuits interpret it.",
    "effects": {},
    "production_items": [
      "instruction_register_units"
    ],
    "production_contract": "Physical register, memory and control assemblies require finite component stocks and workshop work. A commissioned programmable workshop additionally consumes shared power and operator labor; discovery alone supplies no machine or operating bonus."
  },
  {
    "id": "program_counters",
    "name": "Program Counters",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "binary_counters",
      "binary_adders"
    ],
    "requires_all": [
      "binary_counters",
      "binary_adders"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Program Counters",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A counter retains and advances the address from which the next instruction is fetched.",
    "effects": {},
    "production_items": [
      "program_counter_units"
    ],
    "production_contract": "Physical register, memory and control assemblies require finite component stocks and workshop work. A commissioned programmable workshop additionally consumes shared power and operator labor; discovery alone supplies no machine or operating bonus."
  },
  {
    "id": "conditional_branch_circuits",
    "name": "Conditional Branch Circuits",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "binary_adders",
      "transistor_inverters"
    ],
    "requires_all": [
      "binary_adders",
      "transistor_inverters"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Conditional Branch Circuits",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A tested arithmetic condition selects between the sequential instruction address and a branch destination.",
    "effects": {},
    "production_items": [
      "branch_control_units"
    ],
    "production_contract": "Physical register, memory and control assemblies require finite component stocks and workshop work. A commissioned programmable workshop additionally consumes shared power and operator labor; discovery alone supplies no machine or operating bonus."
  },
  {
    "id": "stored_program_control",
    "name": "Stored-Program Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "read_write_memory",
      "instruction_registers",
      "program_counters",
      "conditional_branch_circuits",
      "electronic_machine_control"
    ],
    "requires_all": [
      "read_write_memory",
      "instruction_registers",
      "program_counters",
      "conditional_branch_circuits",
      "electronic_machine_control"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Stored-Program Control",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Stored instructions, addressed memory and conditional transfers coordinate a machine through a changeable sequence.",
    "effects": {},
    "production_items": [
      "programmable_controllers"
    ],
    "production_contract": "Physical register, memory and control assemblies require finite component stocks and workshop work. A commissioned programmable workshop additionally consumes shared power and operator labor; discovery alone supplies no machine or operating bonus.",
    "operating_plants": [
      "programmable_workshop"
    ]
  }
]
