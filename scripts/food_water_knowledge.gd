extends RefCounted
## Individually authored first food-and-water production slice.
static func entries()->Array[Dictionary]:
	return [
	  {
	    "id": "root_cellars",
	    "name": "Root Cellars",
	    "direction": "Sustenance",
	    "day": 700,
	    "chance": 0.003,
	    "requires": [
	      "drainage"
	    ],
	    "requires_all": [
	      "drainage"
	    ],
	    "requires_any": [
	      [
	        "basketry",
	        "sealed_vessels"
	      ]
	    ],
	    "signals": [
	      "food",
	      "storage",
	      "construction"
	    ],
	    "observation": "Below-ground stores buffer temperature swings while drainage keeps stored roots away from standing water.",
	    "effects": {
	      "food_storage": 0.025
	    },
	    "production_contract": "Protects stored plants; it does not preserve fresh meat or create mechanical refrigeration.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Root Cellars practice",
	        "requires_all": []
	      }
	    ],
	    "preservation_profile": {
	      "Fresh plants": 0.16
	    }
	  },
	  {
	    "id": "raised_granaries",
	    "name": "Raised Granaries",
	    "direction": "Sustenance",
	    "day": 950,
	    "chance": 0.003,
	    "requires": [
	      "joinery"
	    ],
	    "requires_all": [
	      "joinery"
	    ],
	    "requires_any": [
	      [
	        "seed_reserves",
	        "public_stores"
	      ]
	    ],
	    "signals": [
	      "food",
	      "storage",
	      "timber"
	    ],
	    "observation": "Raised floors and separated supports keep grain away from damp ground and make animal access harder.",
	    "effects": {
	      "food_storage": 0.035
	    },
	    "production_contract": "A grain-storage structure rather than a larger generic food bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Raised Granaries practice",
	        "requires_all": []
	      }
	    ],
	    "preservation_profile": {
	      "Dry staples": 0.14
	    }
	  },
	  {
	    "id": "hermetic_grain_storage",
	    "name": "Hermetic Grain Storage",
	    "direction": "Sustenance",
	    "day": 2300,
	    "chance": 0.003,
	    "requires": [
	      "sealed_vessels"
	    ],
	    "requires_all": [
	      "sealed_vessels"
	    ],
	    "requires_any": [
	      [
	        "raised_granaries",
	        "seed_reserves"
	      ]
	    ],
	    "signals": [
	      "food",
	      "storage",
	      "clay"
	    ],
	    "observation": "Dry grain is enclosed in carefully sealed containers instead of repeatedly exposing the whole reserve.",
	    "effects": {
	      "container_capacity": 0.02
	    },
	    "production_contract": "Requires dry grain and sealed containers; the aggregate model represents reduced staple losses.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Hermetic Grain Storage practice",
	        "requires_all": []
	      }
	    ],
	    "preservation_profile": {
	      "Dry staples": 0.18
	    }
	  },
	  {
	    "id": "brine_fermentation",
	    "name": "Brine Fermentation",
	    "direction": "Sustenance",
	    "day": 3100,
	    "chance": 0.003,
	    "requires": [
	      "fermentation_control",
	      "salt_working"
	    ],
	    "requires_all": [
	      "fermentation_control",
	      "salt_working"
	    ],
	    "requires_any": [
	      [
	        "sealed_vessels",
	        "pit_firing"
	      ]
	    ],
	    "signals": [
	      "food",
	      "storage",
	      "crafting"
	    ],
	    "observation": "Repeated batches compare salt concentration, vessel care and keeping time for fermented vegetables.",
	    "effects": {
	      "nutrition_quality": 0.015
	    },
	    "production_contract": "A salted vegetable process; distinct from the general discovery of fermentation.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Brine Fermentation practice",
	        "requires_all": []
	      }
	    ],
	    "preservation_profile": {
	      "Fresh plants": 0.12
	    }
	  },
	  {
	    "id": "vinegar_pickling",
	    "name": "Vinegar Pickling",
	    "direction": "Sustenance",
	    "day": 6000,
	    "chance": 0.003,
	    "requires": [
	      "fermentation_control",
	      "sealed_vessels"
	    ],
	    "requires_all": [
	      "fermentation_control",
	      "sealed_vessels"
	    ],
	    "requires_any": [],
	    "signals": [
	      "food",
	      "storage",
	      "research"
	    ],
	    "observation": "Soured fermented liquids are reused in measured batches to keep plant foods longer.",
	    "effects": {
	      "nutrition_quality": 0.01
	    },
	    "production_contract": "An acid-preservation method with vessels and an established fermentation practice.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Vinegar Pickling practice",
	        "requires_all": []
	      }
	    ],
	    "preservation_profile": {
	      "Fresh plants": 0.12
	    }
	  },
	  {
	    "id": "stock_rotation",
	    "name": "Dated Stock Rotation",
	    "direction": "Sustenance",
	    "day": 4500,
	    "chance": 0.003,
	    "requires": [
	      "tallies"
	    ],
	    "requires_all": [
	      "tallies"
	    ],
	    "requires_any": [
	      [
	        "public_stores",
	        "raised_granaries"
	      ]
	    ],
	    "signals": [
	      "food",
	      "storage",
	      "administration"
	    ],
	    "observation": "Storekeepers mark incoming batches and issue older usable stock before new deliveries.",
	    "effects": {
	      "storage_loss": -0.015
	    },
	    "production_contract": "A handling rule applied to all stocks, not a new preservation chemistry.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Dated Stock Rotation practice",
	        "requires_all": []
	      }
	    ],
	    "preservation_profile": {
	      "Fresh plants": 0.05,
	      "Fresh meat": 0.05,
	      "Fish": 0.05,
	      "Dry staples": 0.05,
	      "Preserved food": 0.05
	    }
	  },
	  {
	    "id": "protected_wellheads",
	    "name": "Protected Wellheads",
	    "direction": "Health",
	    "day": 1300,
	    "chance": 0.003,
	    "requires": [
	      "well_siting",
	      "drainage"
	    ],
	    "requires_all": [
	      "well_siting",
	      "drainage"
	    ],
	    "requires_any": [
	      [
	        "joinery",
	        "lime_mortar"
	      ]
	    ],
	    "signals": [
	      "freshwater",
	      "construction",
	      "illness"
	    ],
	    "observation": "Raised well rims, covers and drainage carry dirty surface water away from the opening.",
	    "effects": {
	      "water_safety": 0.035,
	      "labor_demand": 0.005
	    },
	    "production_contract": "Protects an existing well; it does not increase the aquifer supply.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Protected Wellheads practice",
	        "requires_all": []
	      }
	    ]
	  },
	  {
	    "id": "rainwater_cisterns",
	    "name": "Rainwater Cisterns",
	    "direction": "Infrastructure",
	    "day": 2200,
	    "chance": 0.003,
	    "requires": [
	      "drainage"
	    ],
	    "requires_all": [
	      "drainage"
	    ],
	    "requires_any": [
	      [
	        "sealed_vessels",
	        "lime_mortar",
	        "bitumen_sealing"
	      ]
	    ],
	    "signals": [
	      "rain",
	      "construction",
	      "freshwater"
	    ],
	    "observation": "Catchment surfaces feed lined reserves that retain water between rainfalls.",
	    "effects": {
	      "water_access": 0.035,
	      "labor_demand": 0.005
	    },
	    "production_contract": "A storage route to supply; it does not imply that captured water is disinfected.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Rainwater Cisterns practice",
	        "requires_all": []
	      }
	    ]
	  },
	  {
	    "id": "water_settling_basins",
	    "name": "Water Settling Basins",
	    "direction": "Health",
	    "day": 3500,
	    "chance": 0.003,
	    "requires": [
	      "clay_shaping"
	    ],
	    "requires_all": [
	      "clay_shaping"
	    ],
	    "requires_any": [
	      [
	        "well_siting",
	        "rainwater_cisterns"
	      ]
	    ],
	    "signals": [
	      "freshwater",
	      "storage",
	      "construction"
	    ],
	    "observation": "Water rests in separate basins before the clearer upper portion is drawn off.",
	    "effects": {
	      "water_safety": 0.02,
	      "labor_demand": 0.005
	    },
	    "production_contract": "Removes settling material; the modest aggregate benefit is not a claim of sterilization.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Water Settling Basins practice",
	        "requires_all": []
	      }
	    ]
	  },
	  {
	    "id": "slow_sand_filtration",
	    "name": "Slow Sand Filtration",
	    "direction": "Health",
	    "day": 24000,
	    "chance": 0.003,
	    "requires": [
	      "water_settling_basins",
	      "experimental_controls"
	    ],
	    "requires_all": [
	      "water_settling_basins",
	      "experimental_controls"
	    ],
	    "requires_any": [
	      [
	        "lime_mortar",
	        "sealed_vessels"
	      ]
	    ],
	    "signals": [
	      "freshwater",
	      "research",
	      "illness"
	    ],
	    "observation": "Operators compare water passed slowly through maintained sand beds and clean the beds without abandoning their working layer.",
	    "effects": {
	      "water_safety": 0.06,
	      "labor_demand": 0.015
	    },
	    "production_contract": "A maintained treatment process, separate from sediment settling and source protection.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Slow Sand Filtration practice",
	        "requires_all": []
	      }
	    ]
	  },
	  {
	    "id": "water_service_inspections",
	    "name": "Water Service Inspections",
	    "direction": "Health",
	    "day": 13000,
	    "chance": 0.003,
	    "requires": [
	      "case_records",
	      "standard_measures"
	    ],
	    "requires_all": [
	      "case_records",
	      "standard_measures"
	    ],
	    "requires_any": [
	      [
	        "protected_wellheads",
	        "rainwater_cisterns"
	      ]
	    ],
	    "signals": [
	      "freshwater",
	      "administration",
	      "illness"
	    ],
	    "observation": "Regular checks connect damaged intakes, dirty containers and repair records with recurring water complaints.",
	    "effects": {
	      "water_safety": 0.025,
	      "repair_capacity": 0.025,
	      "labor_demand": 0.01
	    },
	    "production_contract": "An inspection institution shared by several supply routes; no aqueduct-only prerequisite.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Water Service Inspections practice",
	        "requires_all": []
	      }
	    ]
	  },
	  {
	    "id": "separate_clean_water_storage",
	    "name": "Separate Clean-Water Storage",
	    "direction": "Health",
	    "day": 5500,
	    "chance": 0.003,
	    "requires": [
	      "sealed_vessels"
	    ],
	    "requires_all": [
	      "sealed_vessels"
	    ],
	    "requires_any": [
	      [
	        "water_settling_basins",
	        "protected_wellheads"
	      ]
	    ],
	    "signals": [
	      "freshwater",
	      "storage",
	      "illness"
	    ],
	    "observation": "Dedicated covered vessels and separate dipping tools prevent cleaned water from being mixed with untreated supplies.",
	    "effects": {
	      "water_safety": 0.03,
	      "labor_demand": 0.005
	    },
	    "production_contract": "Protects water after collection or treatment; does not substitute for treatment itself.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Separate Clean-Water Storage practice",
	        "requires_all": []
	      }
	    ]
	  }
	]
