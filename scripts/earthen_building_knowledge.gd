extends RefCounted
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "adobe_wall_construction",
    "name": "Adobe-Wall Construction",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "clay_testing"
    ],
    "requires_all": [
      "clay_testing"
    ],
    "requires_any": [
      [
        "framed_construction",
        "structural_load_testing"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Adobe-Wall Construction",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Assemble dried earthen units into protected load-bearing walls",
    "effects": {},
    "building_method": "adobe_wall_construction",
    "production_items": [
      "adobe_mix"
    ],
    "production_contract": "Pays for local earth mix, reinforcement, roof protection and construction. Adobe units dry at the building site before wall assembly; wattle infill dries after application. Cold or wet local conditions delay usable housing, and weather-exposed fabric requires real repair supplies. Existing plot capacity, workforce and maintenance owners remain authoritative."
  },
  {
    "id": "wattle_and_daub_walls",
    "name": "Wattle-and-Daub Walls",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "basketry",
      "clay_tempering",
      "framed_construction"
    ],
    "requires_all": [
      "basketry",
      "clay_tempering",
      "framed_construction"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Wattle-and-Daub Walls",
        "requires_all": []
      }
    ],
    "signals": [
      "construction",
      "crafting",
      "materials"
    ],
    "observation": "Combine a woven framework with a compatible earthen infill",
    "effects": {},
    "building_method": "wattle_and_daub_walls",
    "production_items": [
      "earthen_daub",
      "wattle_lattices"
    ],
    "production_contract": "Pays for local earth mix, reinforcement, roof protection and construction. Adobe units dry at the building site before wall assembly; wattle infill dries after application. Cold or wet local conditions delay usable housing, and weather-exposed fabric requires real repair supplies. Existing plot capacity, workforce and maintenance owners remain authoritative."
  }
]
