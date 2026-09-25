extends RefCounted
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "metal_type_casting",
    "name": "Metal-Type Casting",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "copper_casting",
      "dimensional_metrology"
    ],
    "requires_all": [
      "copper_casting",
      "dimensional_metrology"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Metal-Type Casting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "information",
      "research"
    ],
    "observation": "Produce repeatable durable printing characters through qualified casting",
    "effects": {},
    "production_items": ["cast_metal_type_sets", "composed_metal_type_forms"],
    "production_contract": "Paid casting produces selected bronze type sets with rejected material and finishing work. Composition allocates actual metal or wooden type to forms, with spacing material, proof paper, ink and finite work. Installed forms feed existing printing and study; no text, discovered knowledge or arbitrary glyph inventory is created. Compatible repertoire and corrected proofs are abstracted by paid production work."
  },
  {
    "id": "movable_type_composition",
    "name": "Movable-Type Composition",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "phonetic_notation"
    ],
    "requires_all": [
      "phonetic_notation"
    ],
    "requires_any": [
      [
        "wooden_movable_type",
        "metal_type_casting"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Movable-Type Composition",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "information",
      "research"
    ],
    "observation": "Arrange reusable characters into a qualified page form",
    "effects": {},
    "production_items": ["fired_clay_type_forms"],
    "production_contract": "Paid casting produces selected bronze type sets with rejected material and finishing work. Composition allocates actual metal or wooden type to forms, with spacing material, proof paper, ink and finite work. Installed forms feed existing printing and study; no text, discovered knowledge or arbitrary glyph inventory is created. Compatible repertoire and corrected proofs are abstracted by paid production work."
  }
]
