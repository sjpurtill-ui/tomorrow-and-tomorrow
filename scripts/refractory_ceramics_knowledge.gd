extends RefCounted
## Individually authored refractory preparation and glassworking methods.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "clay_levigation",
    "name": "Clay Levigation",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "clay_shaping",
      "standard_measures"
    ],
    "requires_all": [
      "clay_shaping",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Clay Levigation",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Settling suspended clay separates coarse debris and produces a more repeatable working body.",
    "effects": {},
    "production_items": [
      "prepared_clay"
    ],
    "production_contract": "Finite workshop production consumes real materials, tooling and assigned Crafting labor. Prepared refractory components feed a glassmaking alternative; existing glassmaking remains available. No free materials; the society-wide effect is a small era-scaled contribution, not a direct production bonus."
  },
  {
    "id": "grog_preparation",
    "name": "Grog Preparation",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "pit_firing",
      "stone_sorting"
    ],
    "requires_all": [
      "pit_firing",
      "stone_sorting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Grog Preparation",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Crushed fired clay can temper a fresh body, reducing the proportion that shrinks during drying and firing.",
    "effects": {},
    "production_items": [
      "ceramic_grog"
    ],
    "production_contract": "Finite workshop production consumes real materials, tooling and assigned Crafting labor. Prepared refractory components feed a glassmaking alternative; existing glassmaking remains available. No free materials; the society-wide effect is a small era-scaled contribution, not a direct production bonus."
  },
  {
    "id": "refractory_body_trials",
    "name": "Refractory Body Trials",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "clay_levigation",
      "grog_preparation",
      "kiln_control"
    ],
    "requires_all": [
      "clay_levigation",
      "grog_preparation",
      "kiln_control"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Refractory Body Trials",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Repeated firing trials select clay mixtures that retain useful shape under demanding furnace conditions.",
    "effects": {},
    "production_items": [
      "refractory_clay"
    ],
    "production_contract": "Finite workshop production consumes real materials, tooling and assigned Crafting labor. Prepared refractory components feed a glassmaking alternative; existing glassmaking remains available. No free materials; the society-wide effect is a small era-scaled contribution, not a direct production bonus."
  },
  {
    "id": "refractory_brick_firing",
    "name": "Refractory Brick Firing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "refractory_body_trials",
      "standard_measures"
    ],
    "requires_all": [
      "refractory_body_trials",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Refractory Brick Firing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Regular fired refractory blocks make furnace linings replaceable without rebuilding the entire structure.",
    "effects": {},
    "production_items": [
      "refractory_brick"
    ],
    "production_contract": "Finite workshop production consumes real materials, tooling and assigned Crafting labor. Prepared refractory components feed a glassmaking alternative; existing glassmaking remains available. No free materials; the society-wide effect is a small era-scaled contribution, not a direct production bonus."
  },
  {
    "id": "ceramic_crucibles",
    "name": "Ceramic Crucibles",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "refractory_body_trials",
      "clay_shaping"
    ],
    "requires_all": [
      "refractory_body_trials",
      "clay_shaping"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Ceramic Crucibles",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Formed and fired refractory vessels hold molten batches apart from the surrounding fuel and masonry.",
    "effects": {},
    "production_items": [
      "ceramic_crucible"
    ],
    "production_contract": "Finite workshop production consumes real materials, tooling and assigned Crafting labor. Prepared refractory components feed a glassmaking alternative; existing glassmaking remains available. No free materials; the society-wide effect is a small era-scaled contribution, not a direct production bonus."
  },
  {
    "id": "crucible_glass_melting",
    "name": "Crucible Glass Melting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "ceramic_crucibles",
      "refractory_brick_firing",
      "glassmaking"
    ],
    "requires_all": [
      "ceramic_crucibles",
      "refractory_brick_firing",
      "glassmaking"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Crucible Glass Melting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Prepared melting pots and furnace linings support repeatable glass batches while worn pots require replacement.",
    "effects": {},
    "production_items": [
      "crucible_glass"
    ],
    "production_contract": "Finite workshop production consumes real materials, tooling and assigned Crafting labor. Prepared refractory components feed a glassmaking alternative; existing glassmaking remains available. No free materials; the society-wide effect is a small era-scaled contribution, not a direct production bonus."
  }
]
