extends RefCounted
## Authored lead-acid storage capabilities; game quantities are abstract batches.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "lead_smelting",
    "name": "Lead Smelting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "ore_assaying",
      "sealed_vessels",
      "kiln_control"
    ],
    "requires_all": [
      "ore_assaying",
      "sealed_vessels",
      "kiln_control"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Lead Smelting",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "crafting",
      "research"
    ],
    "observation": "Lead-bearing feed is processed into a workable metal stock rather than treated as finished electrical material.",
    "effects": {},
    "production_items": [
      "refined_lead"
    ],
    "production_contract": "Manufacture consumes actual feedstocks, installed tooling, shared Crafting work and specified electricity. Battery installations begin empty and store only energy supplied by generation; neither discovery nor commissioning grants charge."
  },
  {
    "id": "lead_sheet_rolling",
    "name": "Lead Sheet Rolling",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lead_smelting",
      "bearing_surfaces"
    ],
    "requires_all": [
      "lead_smelting",
      "bearing_surfaces"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Lead Sheet Rolling",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "crafting",
      "research"
    ],
    "observation": "Rollers produce repeatable lead sheets for electrode assemblies.",
    "effects": {},
    "production_items": ["cast_lead_sheets"],
    "production_contract": "Manufacture consumes actual feedstocks, installed tooling, shared Crafting work and specified electricity. Battery installations begin empty and store only energy supplied by generation; neither discovery nor commissioning grants charge."
  },
  {
    "id": "porous_battery_separators",
    "name": "Porous Battery Separators",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "paper_making",
      "experimental_controls"
    ],
    "requires_all": [
      "paper_making",
      "experimental_controls"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Porous Battery Separators",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "crafting",
      "research"
    ],
    "observation": "Prepared porous separators keep opposing electrodes apart while allowing the electrolyte to work between them.",
    "effects": {},
    "production_items": [
      "battery_separators"
    ],
    "production_contract": "Manufacture consumes actual feedstocks, installed tooling, shared Crafting work and specified electricity. Battery installations begin empty and store only energy supplied by generation; neither discovery nor commissioning grants charge."
  },
  {
    "id": "lead_oxide_preparation",
    "name": "Lead Oxide Preparation",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lead_smelting",
      "chemical_distillation",
      "experimental_controls"
    ],
    "requires_all": [
      "lead_smelting",
      "chemical_distillation",
      "experimental_controls"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Lead Oxide Preparation",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "crafting",
      "research"
    ],
    "observation": "A controlled preparation produces lead-oxide feed for rechargeable electrode manufacture.",
    "effects": {},
    "production_items": [
      "lead_oxide"
    ],
    "production_contract": "Manufacture consumes actual feedstocks, installed tooling, shared Crafting work and specified electricity. Battery installations begin empty and store only energy supplied by generation; neither discovery nor commissioning grants charge."
  },
  {
    "id": "lead_acid_cells",
    "name": "Lead-Acid Cells",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "electrochemical_cells",
      "lead_sheet_rolling",
      "lead_oxide_preparation",
      "porous_battery_separators",
      "sulfuric_acid_production"
    ],
    "requires_all": [
      "electrochemical_cells",
      "lead_sheet_rolling",
      "lead_oxide_preparation",
      "porous_battery_separators",
      "sulfuric_acid_production"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Lead-Acid Cells",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "crafting",
      "research"
    ],
    "observation": "Lead electrodes, separators and electrolyte are assembled and formed into rechargeable cells.",
    "effects": {},
    "production_items": ["lead_acid_cell", "lead_electrode_sheets"],
    "production_contract": "Manufacture consumes actual feedstocks, installed tooling, shared Crafting work and specified electricity. Battery installations begin empty and store only energy supplied by generation; neither discovery nor commissioning grants charge."
  },
  {
    "id": "battery_bank_wiring",
    "name": "Battery Bank Wiring",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lead_acid_cells",
      "cable_insulation",
      "standard_measures"
    ],
    "requires_all": [
      "lead_acid_cells",
      "cable_insulation",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Battery Bank Wiring",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "crafting",
      "research"
    ],
    "observation": "Cell assemblies are connected and housed as a stationary energy store with supervised charging and discharge.",
    "effects": {},
    "production_items": [
      "battery_bank"
    ],
    "production_contract": "Manufacture consumes actual feedstocks, installed tooling, shared Crafting work and specified electricity. Battery installations begin empty and store only energy supplied by generation; neither discovery nor commissioning grants charge.",
    "operating_plants": [
      "battery_store"
    ]
  },
  {
    "id": "charge_regulation",
    "name": "Charge Regulation",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "battery_bank_wiring",
      "resistive_sensing",
      "electromagnetic_relays"
    ],
    "requires_all": [
      "battery_bank_wiring",
      "resistive_sensing",
      "electromagnetic_relays"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Charge Regulation",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "crafting",
      "research"
    ],
    "observation": "Sensing and switching regulate a battery bank with less continuous operator effort.",
    "effects": {},
    "production_items": [
      "battery_charge_controller"
    ],
    "production_contract": "Manufacture consumes actual feedstocks, installed tooling, shared Crafting work and specified electricity. Battery installations begin empty and store only energy supplied by generation; neither discovery nor commissioning grants charge.",
    "operating_plants": [
      "regulated_battery_store"
    ]
  }
]
