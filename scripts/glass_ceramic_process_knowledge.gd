extends RefCounted
## Compatible glass and ceramic workshop batches; coefficients are game abstractions.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "glass_batch_composition_control",
    "name": "Glass Batch Composition Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "glassmaking",
      "material_accounting"
    ],
    "requires_all": [
      "glassmaking",
      "material_accounting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Glass Batch Composition Control",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Control measured batch constituents against a qualified glass composition",
    "effects": {},
    "production_items": [
      "graded_glass_cullet"
    ],
    "production_contract": "Finite workshop routes pay for prepared feedstock, rejected trial material, fuel, molds and work. Graded cullet remelts into usable glass; annealed blanks feed lens grinding. Slip-cast forms need a separate firing route, and fired stoneware needs paid glaze-fit trials before supplying the glazed brine workshop. These are bounded compatible material classes, not arbitrary glass mixing, universal refractory ware or food/medical certification."
  },
  {
    "id": "glass_annealing_schedules",
    "name": "Glass Annealing Schedules",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "glassmaking"
    ],
    "requires_all": [
      "glassmaking"
    ],
    "requires_any": [
      [
        "precision_thermometry",
        "kiln_control"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Glass Annealing Schedules",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Control cooling through an evaluated stress-relief range for a specified glass article",
    "effects": {},
    "production_items": [
      "annealed_glass_blanks"
    ],
    "production_contract": "Finite workshop routes pay for prepared feedstock, rejected trial material, fuel, molds and work. Graded cullet remelts into usable glass; annealed blanks feed lens grinding. Slip-cast forms need a separate firing route, and fired stoneware needs paid glaze-fit trials before supplying the glazed brine workshop. These are bounded compatible material classes, not arbitrary glass mixing, universal refractory ware or food/medical certification."
  },
  {
    "id": "ceramic_slip_casting",
    "name": "Ceramic Slip Casting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "clay_levigation",
      "clay_shaping"
    ],
    "requires_all": [
      "clay_levigation",
      "clay_shaping"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Ceramic Slip Casting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Form qualified ceramic shapes by draining or consolidating a controlled suspension in suitable molds",
    "effects": {},
    "production_items": ["fired_mould_slip_wares"],
    "production_contract": "Finite workshop batches drain prepared clay slip in porous fired-clay moulds to make Slip-Moulded Clay Wares, paying clay, water, fuel and work. Plaster moulds and slip-cast stoneware come later with plaster-mould slip casting."
  },
  {
    "id": "ceramic_glaze_formulation",
    "name": "Ceramic-Glaze Formulation",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "glassmaking",
      "clay_testing",
      "kiln_control"
    ],
    "requires_all": [
      "glassmaking",
      "clay_testing",
      "kiln_control"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Ceramic-Glaze Formulation",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Fit a fired glassy surface to a compatible ceramic body",
    "effects": {},
    "production_items": ["glazed_earthenware_vessels"],
    "production_contract": "Finite workshop routes pay for prepared feedstock, rejected trial material, fuel, molds and work. Graded cullet remelts into usable glass; annealed blanks feed lens grinding. Slip-cast forms need a separate firing route, and fired stoneware needs paid glaze-fit trials before supplying the glazed brine workshop. These are bounded compatible material classes, not arbitrary glass mixing, universal refractory ware or food/medical certification."
  },
  {
    "id": "high_fire_stoneware",
    "name": "High-Fire Stoneware",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "clay_testing",
      "refractory_furnaces"
    ],
    "requires_all": [
      "clay_testing",
      "refractory_furnaces"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "High-Fire Stoneware",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Produce a qualified dense ceramic body through controlled high-temperature firing",
    "effects": {},
    "production_items": ["stoneware_body", "formed_stoneware_vessels", "glazed_stoneware_vessels"],
    "production_contract": "Finite workshop routes pay for prepared feedstock, rejected trial material, fuel, molds and work. Graded cullet remelts into usable glass; annealed blanks feed lens grinding. Slip-cast forms need a separate firing route, and fired stoneware needs paid glaze-fit trials before supplying the glazed brine workshop. These are bounded compatible material classes, not arbitrary glass mixing, universal refractory ware or food/medical certification."
  }
]
