extends RefCounted
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "parchment_record_preparation",
    "name": "Parchment Record Preparation",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "hafted_tools",
      "curing_regimens"
    ],
    "requires_all": [
      "hafted_tools",
      "curing_regimens"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Parchment Record Preparation",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "information",
      "research"
    ],
    "observation": "Clean, scrape and stretch suitable untanned skins into a writing surface.",
    "effects": {},
    "production_items": [
      "parchment_prepared_skins",
      "parchment_sheets"
    ],
    "production_contract": "Actual hunted hides, lime, water, abrasives, frames and finite Crafting work produce parchment. Usable sheets are spent on real study notes within the existing Knowledge budget, or bound into physical record books. Imported parchment does not teach its manufacture. Tanned leather cannot substitute for prepared skins. Work coefficients abstract soaking and tension-drying; no arbitrary-skin qualification or detailed storage chemistry is claimed."
  }
]
