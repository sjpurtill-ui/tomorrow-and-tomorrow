extends RefCounted
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "mineral_pigment_preparation",
    "name": "Mineral-Pigment Preparation",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "stone_sorting",
      "clay_testing"
    ],
    "requires_all": [
      "stone_sorting",
      "clay_testing"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Mineral-Pigment Preparation",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "research"
    ],
    "observation": "Separate and prepare mineral colorants with observed consistency and compatibility",
    "effects": {},
    "production_items": [
      "ochre_levigation",
      "fine_ochre_pigment",
      "earth_pigment_ink",
      "ochre_relief_sheets"
    ],
    "production_contract": "Finite selected feed, grinding/extraction equipment, actual water, work and trial material make prepared colorants. Ochre is a nonrenewable observed occurrence; generic clay or iron ore cannot substitute. Qualified pigment and binder feed actual printed sheets; textile tannin feeds compatible dyeing. No imported output grants local mastery or a universal pigment or dye rating."
  },
  {
    "id": "textile_dye_extraction",
    "name": "Textile-Dye Extraction",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "fiber_grading"
    ],
    "requires_all": [
      "fiber_grading"
    ],
    "requires_any": [
      [
        "herbal_classification",
        "mineral_pigment_preparation"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Textile-Dye Extraction",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "research"
    ],
    "observation": "Prepare characterized colorants from suitable sources for textile use",
    "effects": {},
    "production_items": [
      "textile_tannin_colorant"
    ],
    "production_contract": "Finite selected feed, grinding/extraction equipment, actual water, work and trial material make prepared colorants. Ochre is a nonrenewable observed occurrence; generic clay or iron ore cannot substitute. Qualified pigment and binder feed actual printed sheets; textile tannin feeds compatible dyeing. No imported output grants local mastery or a universal pigment or dye rating."
  }
]
