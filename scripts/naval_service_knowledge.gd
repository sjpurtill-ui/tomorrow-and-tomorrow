extends RefCounted
static func entries()->Array:
	return [
  {
    "id": "dry_dock_services",
    "name": "Dry Dock Services",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "structural_load_testing"
    ],
    "requires_all": [
      "structural_load_testing"
    ],
    "requires_any": [
      [
        "mine_drainage",
        "compound_pulleys"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local hull service trials",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "movement"
    ],
    "observation": "Qualified support permits work below the waterline without treating every port as a dry dock.",
    "effects": {},
    "naval_service_method": "dry_dock_services",
    "production_contract": "Paid lift-access construction shares port labor. Completed facilities provide limited, maintained access for War Canoes and Ram Galleys; other hull classes receive no unsupported capacity. Dock use consumes supplies and onboard repair crew work; ordinary repair material remains required."
  },
  {
    "id": "hull_condition_surveys",
    "name": "Hull Condition Surveys",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "hull_seam_caulking",
      "measurement_uncertainty"
    ],
    "requires_all": [
      "hull_seam_caulking",
      "measurement_uncertainty"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Local hull service trials",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "movement"
    ],
    "observation": "Repeatable inspections distinguish observed hull condition from an undated assumption.",
    "effects": {},
    "naval_service_method": "hull_condition_surveys",
    "production_contract": "Qualified dock inspections consume actual access and repair crew work, recording date and observed condition. Fresh inspections improve the effectiveness of subsequent allocated dock repair work; inspection alone restores no condition."
  }
]
