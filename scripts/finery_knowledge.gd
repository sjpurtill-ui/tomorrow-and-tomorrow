extends RefCounted
## Authored indirect ironworking route, reconverging on existing wrought-iron uses.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "finery_forges",
    "name": "Finery Forges",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "blast_furnace",
      "forge_welding"
    ],
    "requires_all": [
      "blast_furnace",
      "forge_welding"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Fining and hammering pig iron",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Oxidizing and hammering pig iron removes excess carbon and consolidates workable wrought iron.",
    "effects": {},
    "production_items": [
      "finery_iron",
      "charcoal_finery_iron"
    ],
    "production_contract": "Consumes pig iron, wood-derived fuel and assigned workshop labor to supply wrought iron. Bloomery production remains available; discovery grants no metal or global yield bonus."
  }
]
