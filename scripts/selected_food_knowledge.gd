extends RefCounted
static func entries()->Array[Dictionary]:
	return [{
  "id": "edible_resource_recognition",
  "name": "Edible Resource Recognition",
  "direction": "Sustenance",
  "day": 0,
  "chance": 0.003,
  "requires": [],
  "requires_all": [],
  "requires_any": [],
  "learning_routes": [
    {
      "id": "local",
      "label": "Local food identification",
      "requires_all": []
    }
  ],
  "signals": [
    "food",
    "foraging",
    "research"
  ],
  "observation": "Distinguish locally known food resources through transmitted observations and verified identification",
  "effects": {},
  "production_contract": "Qualified local source classes are surveyed and collected with finite Food workers, replacing that share of ordinary harvest. Only compatible curated source classes create identified ingredient lots; unknown plants and generic Fresh plants cannot be converted into them."
}]
