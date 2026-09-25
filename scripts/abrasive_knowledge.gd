extends RefCounted
## Selected abrasive processes; no global percentage bonus or new state owner.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "abrasive_grinding_control",
    "name": "Abrasive-Grinding Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "comparative_mineral_hardness",
      "precision_machinery"
    ],
    "requires_all": [
      "comparative_mineral_hardness",
      "precision_machinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Abrasive-Grinding Control",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Remove material through a qualified abrasive process while controlling heat and geometry",
    "effects": {},
    "production_items": [
      "graded_alumina_grain",
      "green_abrasive_wheels",
      "checked_abrasive_wheels",
      "abrasive_dressing_tools",
      "dressed_abrasive_wheels",
      "grinding_spindle_units"
    ],
    "production_contract": "Paid selected-shape abrasive tooling and inspected component production. Raw abrasive, unfinished wheels and unchecked components cannot substitute for qualified inputs; work, power, cooling and consumable wear remain physical costs."
  },
  {
    "id": "centerless_grinding",
    "name": "Centerless Grinding",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "abrasive_grinding_control",
      "precision_machinery"
    ],
    "requires_all": [
      "abrasive_grinding_control",
      "precision_machinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Centerless Grinding",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A regulating wheel and support locate an uncentered workpiece.",
    "effects": {},
    "production_items": [
      "centerless_regulating_wheels",
      "centerless_support_sets",
      "centerless_ground_shaft_candidates",
      "checked_centerless_shafts"
    ],
    "production_contract": "Paid selected-shape abrasive tooling and inspected component production. Raw abrasive, unfinished wheels and unchecked components cannot substitute for qualified inputs; work, power, cooling and consumable wear remain physical costs."
  },
  {
    "id": "cylindrical_grinding",
    "name": "Cylindrical Grinding",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "centre_lathe_assembly",
      "abrasive_grinding_control"
    ],
    "requires_all": [
      "centre_lathe_assembly",
      "abrasive_grinding_control"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Cylindrical Grinding",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A rotating supported part is ground to a cylindrical surface.",
    "effects": {},
    "production_items": ["cylindrical_grinding_fixtures", "cylindrical_ground_shaft_candidates", "checked_cylindrical_shafts", "textile_finishing_rolls", "calendered_plant_cloth"],
    "production_contract": "Paid selected-shape abrasive tooling and inspected component production. Raw abrasive, unfinished wheels and unchecked components cannot substitute for qualified inputs; work, power, cooling and consumable wear remain physical costs."
  },
  {
    "id": "surface_grinding",
    "name": "Surface Grinding",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "machine_way_scraping",
      "abrasive_grinding_control"
    ],
    "requires_all": [
      "machine_way_scraping",
      "abrasive_grinding_control"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Surface Grinding",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "An abrasive wheel traverses a fixtured surface.",
    "effects": {},
    "production_items": [
      "surface_grinding_fixtures",
      "surface_ground_mount_candidates",
      "checked_ground_mounts"
    ],
    "production_contract": "Paid selected-shape abrasive tooling and inspected component production. Raw abrasive, unfinished wheels and unchecked components cannot substitute for qualified inputs; work, power, cooling and consumable wear remain physical costs."
  },
  {
    "id": "abrasive_belt_finishing",
    "name": "Abrasive Belt Finishing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "abrasive_grinding_control",
      "belt_power_transmission"
    ],
    "requires_all": [
      "abrasive_grinding_control",
      "belt_power_transmission"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Abrasive Belt Finishing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A moving coated abrasive works a contacted surface.",
    "effects": {},
    "production_items": [
      "abrasive_maker_coated_web",
      "abrasive_sized_web",
      "checked_dry_abrasive_belts",
      "abrasive_belt_stands",
      "belt_finished_housing_candidates",
      "checked_deburred_housings"
    ],
    "production_contract": "Paid selected-shape abrasive tooling and inspected component production. Raw abrasive, unfinished wheels and unchecked components cannot substitute for qualified inputs; work, power, cooling and consumable wear remain physical costs."
  }
]
