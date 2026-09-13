extends RefCounted
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "hide_tanning",
    "name": "Hide Tanning",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "curing_regimens",
      "herbal_classification"
    ],
    "requires_all": [
      "curing_regimens",
      "herbal_classification"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Hide Tanning",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Prepare suitable hides and selected plant extracts, then tan and finish flexible leather.",
    "effects": {},
    "production_items": [
      "rendered_leather_fat",
      "prepared_tanning_hides",
      "plant_tannin_extract",
      "vegetable_tanned_leather",
      "finished_flexible_leather"
    ],
    "production_contract": "Actual hunting supplies bounded raw hides and recovered fat once per local day; untreated stock decays. Paid preparation, selected tannin extraction, tanning and finishing consume water, agents, rejected feed and finite workshop work. Flexible leather supplies actual fitted garments. Inputs represent compatible material classes and work coefficients abstract process duration; no species assay, chemical bath simulation or universal leather certification."
  }
]
