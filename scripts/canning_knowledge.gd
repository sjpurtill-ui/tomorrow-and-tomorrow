extends RefCounted
## Authored container manufacture and thermal food preservation.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "tin_smelting",
    "name": "Tin Smelting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "ore_assaying",
      "charcoal"
    ],
    "requires_all": [
      "ore_assaying",
      "charcoal"
    ],
    "requires_any": [],
    "resource_requirements": [{"resource":"Tin Ore","stage":"accessible","minimum_stock":2.0}],
    "learning_routes": [
      {
        "id": "local",
        "label": "Tin Smelting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Selected tin ore is reduced and separated into workable tin for controlled coating and alloying.",
    "effects": {},
    "production_items": [
      "refined_tin"
    ],
    "production_contract": "Finite workshop batches consume actual materials, tooling and assigned labor. These components support a supplied cannery; discovery alone grants no food or preservation bonus."
  },
  {
    "id": "sheet_steel_rolling",
    "name": "Sheet Steel Rolling",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "steel_refining",
      "bearing_surfaces"
    ],
    "requires_all": [
      "steel_refining",
      "bearing_surfaces"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Sheet Steel Rolling",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Repeated roller passes form steel into sheet that can be cut and folded consistently.",
    "effects": {},
    "production_items": [
      "steel_sheet"
    ],
    "production_contract": "Finite workshop batches consume actual materials, tooling and assigned labor. These components support a supplied cannery; discovery alone grants no food or preservation bonus."
  },
  {
    "id": "tinplate_coating",
    "name": "Tinplate Coating",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "sheet_steel_rolling",
      "tin_smelting"
    ],
    "requires_all": [
      "sheet_steel_rolling",
      "tin_smelting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Tinplate Coating",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A controlled tin coating protects prepared steel sheet and supplies a useful container material.",
    "effects": {},
    "production_items": [
      "tinplate"
    ],
    "production_contract": "Finite workshop batches consume actual materials, tooling and assigned labor. These components support a supplied cannery; discovery alone grants no food or preservation bonus."
  },
  {
    "id": "can_body_forming",
    "name": "Can Body Forming",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "tinplate_coating",
      "standard_measures"
    ],
    "requires_all": [
      "tinplate_coating",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Can Body Forming",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Sheet blanks become matching can bodies and ends that can be filled and closed at a packing line.",
    "effects": {},
    "production_items": [
      "food_can_sets"
    ],
    "production_contract": "Finite workshop batches consume actual materials, tooling and assigned labor. These components support a supplied cannery; discovery alone grants no food or preservation bonus."
  },
  {
    "id": "double_seaming",
    "name": "Double Seaming",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "can_body_forming",
      "bearing_surfaces"
    ],
    "requires_all": [
      "can_body_forming",
      "bearing_surfaces"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Double Seaming",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Controlled rolling joins a filled container body to its end, with seam checks detecting faulty closure.",
    "effects": {},
    "production_items": [
      "seaming_head"
    ],
    "production_contract": "Finite workshop batches consume actual materials, tooling and assigned labor. These components support a supplied cannery; discovery alone grants no food or preservation bonus."
  },
  {
    "id": "food_retorts",
    "name": "Food Retorts",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "pressure_vessels",
      "precision_thermometry"
    ],
    "requires_all": [
      "pressure_vessels",
      "precision_thermometry"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Food Retorts",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A controlled heated vessel processes closed food containers in repeatable batches.",
    "effects": {},
    "production_items": [
      "food_retort"
    ],
    "production_contract": "Finite workshop batches consume actual materials, tooling and assigned labor. These components support a supplied cannery; discovery alone grants no food or preservation bonus."
  },
  {
    "id": "thermal_process_validation",
    "operating_plants": ["cannery"],
    "name": "Thermal Process Validation",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "food_retorts",
      "double_seaming",
      "experimental_controls"
    ],
    "requires_all": [
      "food_retorts",
      "double_seaming",
      "experimental_controls"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Validated container processing",
        "requires_all": []
      }
    ],
    "signals": [
      "food",
      "research",
      "crafting"
    ],
    "observation": "Measured trials establish processing and closure controls for repeatable preserved food batches.",
    "effects": {},
    "production_contract": "Enables a commissioned cannery. Assigned operators, can sets, coal and water supply finite daily preservation capacity. Actual surplus perishable food is converted with losses; no global storage bonus or food grant."
  }
]
