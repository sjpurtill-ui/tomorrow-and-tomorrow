extends RefCounted
## Distinct textile mechanisms; operational quantities are abstract game batches.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "spinning_wheels",
    "name": "Spinning Wheels",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "drop_spindles",
      "joinery"
    ],
    "requires_all": [
      "drop_spindles",
      "joinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Spinning Wheels",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "A hand-driven wheel transfers rotation to a spindle so drafting fibers need not stop for every fresh spin.",
    "effects": {},
    "production_items": [
      "wheel_spun_yarn"
    ],
    "production_contract": "Enables an authored textile workshop route with its own tooling, material and work costs. Powered routes consume actual electricity; hand manufacture remains available without it. Learning creates no machinery or output."
  },
  {
    "id": "flyer_spinning",
    "name": "Flyer Spinning",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "spinning_wheels",
      "bearing_surfaces"
    ],
    "requires_all": [
      "spinning_wheels",
      "bearing_surfaces"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Flyer Spinning",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "A rotating flyer and bobbin coordinate twisting with winding instead of treating them as entirely separate operations.",
    "effects": {},
    "production_items": [
      "flyer_spun_yarn"
    ],
    "production_contract": "Enables an authored textile workshop route with its own tooling, material and work costs. Powered routes consume actual electricity; hand manufacture remains available without it. Learning creates no machinery or output."
  },
  {
    "id": "multi_spindle_spinning",
    "name": "Multi-Spindle Spinning",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "spinning_wheels",
      "workshop_standards"
    ],
    "requires_all": [
      "spinning_wheels",
      "workshop_standards"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Multi-Spindle Spinning",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "A shared hand-driven frame coordinates multiple spindles while the worker draws out their fiber supply.",
    "effects": {},
    "production_items": [
      "frame_spun_yarn"
    ],
    "production_contract": "Enables an authored textile workshop route with its own tooling, material and work costs. Powered routes consume actual electricity; hand manufacture remains available without it. Learning creates no machinery or output."
  },
  {
    "id": "mule_spinning",
    "name": "Mule Spinning",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "multi_spindle_spinning",
      "flyer_spinning",
      "gear_ratios"
    ],
    "requires_all": [
      "multi_spindle_spinning",
      "flyer_spinning",
      "gear_ratios"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Mule Spinning",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "A moving spindle carriage combines controlled drawing and twisting with a return stroke for winding the yarn.",
    "effects": {},
    "production_items": [
      "hand_mule_yarn",
      "electric_mule_yarn"
    ],
    "production_contract": "Enables an authored textile workshop route with its own tooling, material and work costs. Powered routes consume actual electricity; hand manufacture remains available without it. Learning creates no machinery or output."
  },
  {
    "id": "flying_shuttles",
    "name": "Flying Shuttles",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "plain_weaving",
      "joinery"
    ],
    "requires_all": [
      "plain_weaving",
      "joinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Flying Shuttles",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "A guided shuttle travels across the warp under cord control, reducing the need to pass each weft directly from hand to hand.",
    "effects": {},
    "production_items": [
      "shuttle_woven_cloth"
    ],
    "production_contract": "Enables an authored textile workshop route with its own tooling, material and work costs. Powered routes consume actual electricity; hand manufacture remains available without it. Learning creates no machinery or output."
  },
  {
    "id": "electric_power_looms",
    "name": "Electric Power Looms",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "flying_shuttles",
      "crank_linkages",
      "electric_motors"
    ],
    "requires_all": [
      "flying_shuttles",
      "crank_linkages",
      "electric_motors"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Electric Power Looms",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "A motor coordinates shedding, shuttle movement and beating while operators tend breaks and material supply.",
    "effects": {},
    "production_items": [
      "power_woven_cloth"
    ],
    "production_contract": "Enables an authored textile workshop route with its own tooling, material and work costs. Powered routes consume actual electricity; hand manufacture remains available without it. Learning creates no machinery or output."
  }
]
