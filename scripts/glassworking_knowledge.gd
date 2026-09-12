extends RefCounted
## Glass forming and apparatus manufacture; game batches, not engineering specifications.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "core_formed_glass",
    "name": "Core-Formed Glass",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "glassmaking",
      "clay_shaping"
    ],
    "requires_all": [
      "glassmaking",
      "clay_shaping"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Core-Formed Glass",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A removable core supports hot glass while a hollow vessel is built around it.",
    "effects": {},
    "production_items": [
      "core_glass_vessels"
    ],
    "production_contract": "Enables an individually specified glassworking route with paid tooling, feedstock, fuel and labor. Vessels and laboratory glassware supply alternative chemical workshop setups. Discovery creates no apparatus, inputs or output."
  },
  {
    "id": "glass_blowing",
    "name": "Glass Blowing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "glassmaking",
      "bloomery_smelting"
    ],
    "requires_all": [
      "glassmaking",
      "bloomery_smelting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Glass Blowing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Air introduced through a metal blowpipe expands a hot gather into a hollow vessel.",
    "effects": {},
    "production_items": [
      "blown_glass_vessels"
    ],
    "production_contract": "Enables an individually specified glassworking route with paid tooling, feedstock, fuel and labor. Vessels and laboratory glassware supply alternative chemical workshop setups. Discovery creates no apparatus, inputs or output."
  },
  {
    "id": "mold_blown_glass",
    "name": "Mold-Blown Glass",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "glass_blowing",
      "clay_tempering"
    ],
    "requires_all": [
      "glass_blowing",
      "clay_tempering"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Mold-Blown Glass",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "An inflated gather takes the repeatable shape of a surrounding mold.",
    "effects": {},
    "production_items": [
      "mold_glass_vessels"
    ],
    "production_contract": "Enables an individually specified glassworking route with paid tooling, feedstock, fuel and labor. Vessels and laboratory glassware supply alternative chemical workshop setups. Discovery creates no apparatus, inputs or output."
  },
  {
    "id": "plunger_pressed_glass",
    "name": "Plunger-Pressed Glass",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "glassmaking",
      "forge_welding",
      "workshop_standards"
    ],
    "requires_all": [
      "glassmaking",
      "forge_welding",
      "workshop_standards"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Plunger-Pressed Glass",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A metal plunger displaces hot glass against a mold to form the inside and outside of an open vessel.",
    "effects": {},
    "production_items": [
      "pressed_glass_vessels"
    ],
    "production_contract": "Enables an individually specified glassworking route with paid tooling, feedstock, fuel and labor. Vessels and laboratory glassware supply alternative chemical workshop setups. Discovery creates no apparatus, inputs or output."
  },
  {
    "id": "glass_tube_drawing",
    "name": "Glass Tube Drawing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "glass_blowing",
      "standard_measures"
    ],
    "requires_all": [
      "glass_blowing",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Glass Tube Drawing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A hot hollow gather is drawn lengthwise while preserving a passage through the resulting tube.",
    "effects": {},
    "production_items": [
      "drawn_glass_tubes"
    ],
    "production_contract": "Enables an individually specified glassworking route with paid tooling, feedstock, fuel and labor. Vessels and laboratory glassware supply alternative chemical workshop setups. Discovery creates no apparatus, inputs or output."
  },
  {
    "id": "hydrogen_flame_glassworking",
    "name": "Hydrogen-Flame Glassworking",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "glass_tube_drawing",
      "chemical_distillation"
    ],
    "requires_all": [
      "glass_tube_drawing",
      "chemical_distillation"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Hydrogen-Flame Glassworking",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A controlled hydrogen flame softens a small region of glass tubing for joining and shaping laboratory apparatus.",
    "effects": {},
    "production_items": [
      "hydrogen_worked_glassware"
    ],
    "production_contract": "Enables an individually specified glassworking route with paid tooling, feedstock, fuel and labor. Vessels and laboratory glassware supply alternative chemical workshop setups. Discovery creates no apparatus, inputs or output."
  }
]
