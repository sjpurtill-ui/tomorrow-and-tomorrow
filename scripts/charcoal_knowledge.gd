extends RefCounted
## Prepared fuel and controlled ironworking, with physical alternative inputs.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "charcoal_retorts",
    "name": "Charcoal Retorts",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "charcoal",
      "pressure_vessels",
      "refractory_brick_firing"
    ],
    "requires_all": [
      "charcoal",
      "pressure_vessels",
      "refractory_brick_firing"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Charcoal Retorts",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "An enclosed vessel separates the wood charge from its heating fire, allowing more controlled carbonization.",
    "effects": {},
    "production_items": [
      "retort_charcoal"
    ],
    "production_contract": "Finite workshop batches consume paid fuel and tooling. Prepared charcoal can be supplied separately or traded; no discovery grants stocks or global efficiency. Existing bundled wood-fuel recipes remain available."
  },
  {
    "id": "bloomery_charge_control",
    "name": "Bloomery Charge Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "bloomery_smelting",
      "standard_measures"
    ],
    "requires_all": [
      "bloomery_smelting",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Bloomery Charge Control",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Measured ore and prepared charcoal charges make the fuel supply and reduction work explicit at the bloomery.",
    "effects": {},
    "production_items": [
      "charged_bloomery_iron"
    ],
    "production_contract": "Finite workshop batches consume paid fuel and tooling. Prepared charcoal can be supplied separately or traded; no discovery grants stocks or global efficiency. Existing bundled wood-fuel recipes remain available."
  }
]
