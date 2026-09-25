extends RefCounted
## Physical textile processing and care supplies; quantities are game batches.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "fiber_retting",
    "name": "Fiber Retting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "fiber_grading",
      "clean_water"
    ],
    "requires_all": [
      "fiber_grading",
      "clean_water"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Fiber Retting",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "health"
    ],
    "observation": "Water treatment and careful separation loosen useful stem fibers before they are dried for spinning.",
    "effects": {},
    "production_items": [
      "retted_fibers"
    ],
    "production_contract": "Manufactures the authored textile intermediates or supplies using real stocks, workshop tooling and finite work. No products or medical recovery are granted by learning alone."
  },
  {
    "id": "fiber_combing",
    "name": "Fiber Combing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "fiber_retting",
      "controlled_flaking"
    ],
    "requires_all": [
      "fiber_retting",
      "controlled_flaking"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Fiber Combing",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "health"
    ],
    "observation": "Repeated combing aligns long fibers and separates short tangled material from a spinnable bundle.",
    "effects": {},
    "production_items": ["combed_fibers", "combed_yarn"],
    "production_contract": "Manufactures the authored textile intermediates or supplies using real stocks, workshop tooling and finite work. No products or medical recovery are granted by learning alone."
  },
  {
    "id": "drop_spindles",
    "name": "Drop Spindles",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "cordage",
      "clay_shaping"
    ],
    "requires_all": [
      "cordage",
      "clay_shaping"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Drop Spindles",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "health"
    ],
    "observation": "A weighted rotating spindle draws and twists fibers into a continuous thread of manageable thickness.",
    "effects": {},
    "production_items": ["spun_yarn"],
    "production_contract": "Manufactures the authored textile intermediates or supplies using real stocks, workshop tooling and finite work. No products or medical recovery are granted by learning alone."
  },
  {
    "id": "warp_weighted_looms",
    "name": "Warp-Weighted Looms",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "drop_spindles",
      "pit_firing",
      "joinery"
    ],
    "requires_all": [
      "drop_spindles",
      "pit_firing",
      "joinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Warp-Weighted Looms",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "health"
    ],
    "observation": "Clay weights tension hanging warp threads while a supporting frame keeps the weaving accessible.",
    "effects": {},
    "production_items": [
      "loom_weights"
    ],
    "production_contract": "Manufactures the authored textile intermediates or supplies using real stocks, workshop tooling and finite work. No products or medical recovery are granted by learning alone."
  },
  {
    "id": "plain_weaving",
    "name": "Plain Weaving",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "drop_spindles",
      "warp_weighted_looms"
    ],
    "requires_all": [
      "drop_spindles",
      "warp_weighted_looms"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Plain Weaving",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "health"
    ],
    "observation": "Alternating over-and-under crossings bind warp and weft into a repeatable sheet of cloth.",
    "effects": {},
    "production_items": [
      "woven_cloth"
    ],
    "production_contract": "Manufactures the authored textile intermediates or supplies using real stocks, workshop tooling and finite work. No products or medical recovery are granted by learning alone."
  },
  {
    "id": "woven_dressings",
    "name": "Woven Dressings",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "plain_weaving",
      "wound_cleaning"
    ],
    "requires_all": [
      "plain_weaving",
      "wound_cleaning"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Woven Dressings",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "health"
    ],
    "observation": "Cloth is cleaned, cut and packed into consistent care supplies before it is needed.",
    "effects": {},
    "production_items": [
      "woven_dressings"
    ],
    "production_contract": "Manufactures the authored textile intermediates or supplies using real stocks, workshop tooling and finite work. No products or medical recovery are granted by learning alone."
  }
]
