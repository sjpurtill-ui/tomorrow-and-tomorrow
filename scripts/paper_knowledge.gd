extends RefCounted
## Individually authored operations; quantities are abstract game batches.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "fiber_pulp_beating",
    "name": "Fiber Pulp Beating",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "fiber_retting",
      "hafted_tools"
    ],
    "requires_all": [
      "fiber_retting",
      "hafted_tools"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Fiber Pulp Beating",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "Repeated wet beating separates and fibrillates prepared plant fibers so they bond into a sheet.",
    "effects": {},
    "production_items": [
      "beaten_pulp"
    ],
    "production_contract": "Enables a physical workshop route with paid tooling, fibers, water and work. Motor-driven beating additionally consumes shared electricity. Paper can be consumed during collection study; learning creates neither paper nor free research."
  },
  {
    "id": "textile_rag_pulping",
    "name": "Textile Rag Pulping",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "plain_weaving",
      "fiber_pulp_beating"
    ],
    "requires_all": [
      "plain_weaving",
      "fiber_pulp_beating"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Textile Rag Pulping",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "Washed plant-fiber cloth is cut, soaked and beaten back into pulp rather than discarded.",
    "effects": {},
    "production_items": [
      "rag_pulp"
    ],
    "production_contract": "Enables a physical workshop route with paid tooling, fibers, water and work. Motor-driven beating additionally consumes shared electricity. Paper can be consumed during collection study; learning creates neither paper nor free research."
  },
  {
    "id": "paper_sheet_pressing",
    "name": "Paper Sheet Pressing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "paper_making",
      "joinery"
    ],
    "requires_all": [
      "paper_making",
      "joinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Paper Sheet Pressing",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "A controlled press removes water from a stack of wet sheets before final drying, reducing workshop time.",
    "effects": {},
    "production_items": [
      "pressed_paper"
    ],
    "production_contract": "Enables a physical workshop route with paid tooling, fibers, water and work. Motor-driven beating additionally consumes shared electricity. Paper can be consumed during collection study; learning creates neither paper nor free research."
  },
  {
    "id": "electric_pulp_beating",
    "name": "Electric Pulp Beating",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "fiber_pulp_beating",
      "electric_motors",
      "bearing_surfaces"
    ],
    "requires_all": [
      "fiber_pulp_beating",
      "electric_motors",
      "bearing_surfaces"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Electric Pulp Beating",
        "requires_all": []
      }
    ],
    "signals": [
      "fiber",
      "crafting",
      "research"
    ],
    "observation": "A motor drives repeated mechanical working of wet fibers while the operator regulates the consistency of the pulp.",
    "effects": {},
    "production_items": [
      "electric_pulp"
    ],
    "production_contract": "Enables a physical workshop route with paid tooling, fibers, water and work. Motor-driven beating additionally consumes shared electricity. Paper can be consumed during collection study; learning creates neither paper nor free research."
  }
]
