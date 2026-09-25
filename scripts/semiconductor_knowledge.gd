extends RefCounted
## Distinct semiconductor and photovoltaic processes; physical outputs share workshop stock authority.
static func entries()->Array[Dictionary]:
	return [
	  {
	    "id": "crystallography",
	    "name": "Crystallography",
	    "direction": "Information",
	    "day": 42000,
	    "chance": 0.002,
	    "requires": [
	      "glassmaking",
	      "experimental_optics"
	    ],
	    "requires_all": [
	      "glassmaking",
	      "experimental_optics"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "materials"
	    ],
	    "observation": "Repeated crystal faces and optical behavior suggest an ordered internal structure.",
	    "effects": {},
	    "foundation_for": [
	      "solid_state_physics",
	      "single_crystal_growth"
	    ],
	    "production_contract": "Provides the stated scientific foundation for solid_state_physics, single_crystal_growth. Understanding alone supplies no equipment or operating service."
	  },
	  {
	    "id": "solid_state_physics",
	    "name": "Solid-State Physics",
	    "direction": "Information",
	    "day": 79000,
	    "chance": 0.002,
	    "requires": [
	      "crystallography",
	      "electron_physics"
	    ],
	    "requires_all": [
	      "crystallography",
	      "electron_physics"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "materials"
	    ],
	    "observation": "Charge transport and thermal behavior are investigated in ordered solids rather than isolated atoms.",
	    "effects": {},
	    "foundation_for": [
	      "band_theory"
	    ],
	    "production_contract": "Provides the stated scientific foundation for band_theory. Understanding alone supplies no equipment or operating service."
	  },
	  {
	    "id": "band_theory",
	    "name": "Electronic Band Theory",
	    "direction": "Information",
	    "day": 85000,
	    "chance": 0.002,
	    "requires": [
	      "solid_state_physics",
	      "atomic_physics"
	    ],
	    "requires_all": [
	      "solid_state_physics",
	      "atomic_physics"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "materials"
	    ],
	    "observation": "Allowed and forbidden electronic energy ranges explain contrasting conducting behavior.",
	    "effects": {},
	    "foundation_for": [
	      "semiconductor_doping"
	    ],
	    "production_contract": "Provides the stated scientific foundation for semiconductor_doping, pn_junctions. Understanding alone supplies no equipment or operating service."
	  },
	  {
	    "id": "photoconductivity",
	    "name": "Photoconductivity",
	    "direction": "Information",
	    "day": 71000,
	    "chance": 0.002,
	    "requires": [
	      "experimental_optics",
	      "electrical_measurement"
	    ],
	    "requires_all": [
	      "experimental_optics",
	      "electrical_measurement"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "materials"
	    ],
	    "observation": "Illumination changes the measured conductivity of selected solids.",
	    "effects": {},
	    "foundation_for": [
	      "photovoltaic_conversion"
	    ],
	    "production_contract": "Provides the stated scientific foundation for photovoltaic_conversion. Understanding alone supplies no equipment or operating service."
	  },
	  {
	    "id": "semiconductor_doping",
	    "name": "Semiconductor Doping",
	    "direction": "Information",
	    "day": 86000,
	    "chance": 0.002,
	    "requires": [
	      "chemical_distillation",
	      "electrical_measurement"
	    ],
	    "requires_all": [
	      "chemical_distillation",
	      "electrical_measurement"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "materials"
	    ],
	    "observation": "Controlled impurity additions alter charge-carrier populations in a semiconductor.",
	    "effects": {},
	    "foundation_for": [
	      "pn_junctions",
	      "solar_cell_fabrication"
	    ],
	    "production_contract": "Provides the stated scientific foundation for pn_junctions, solar_cell_fabrication. Understanding alone supplies no equipment or operating service.",
	    "learning_routes": [
	      {
	        "id": "empirical",
	        "label": "Controlled impurity trials",
	        "requires_all": [],
	        "progress_multiplier": 0.65
	      },
	      {
	        "id": "band_model",
	        "label": "Band-guided doping",
	        "requires_all": [
	          "band_theory"
	        ]
	      }
	    ]
	  },
	  {
	    "id": "pn_junctions",
	    "name": "P–N Junctions",
	    "direction": "Information",
	    "day": 90000,
	    "chance": 0.002,
	    "requires": [
	      "semiconductor_doping",
	      "band_theory"
	    ],
	    "requires_all": [
	      "semiconductor_doping",
	      "band_theory"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "materials"
	    ],
	    "observation": "Joining differently doped regions establishes a built-in field and directional electrical behavior.",
	    "effects": {},
	    "foundation_for": [
	      "photovoltaic_conversion"
	    ],
	    "production_contract": "Provides the stated scientific foundation for photovoltaic_conversion. Understanding alone supplies no equipment or operating service."
	  },
	  {
	    "id": "silicon_smelting",
	    "name": "Silicon Smelting",
	    "direction": "Materials",
	    "day": 80000,
	    "chance": 0.002,
	    "requires": [
	      "electric_arc_furnaces",
	      "glassmaking"
	    ],
	    "requires_all": [
	      "electric_arc_furnaces",
	      "glassmaking"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "materials"
	    ],
	    "observation": "Electrical furnace heat and carbon reduction produce a silicon feedstock from silica-bearing material.",
	    "effects": {},
	    "production_items": [
	      "silicon_feedstock"
	    ],
	    "production_contract": "Enables the physical metallurgical silicon recipe. Workshop labor, setup tooling, batch inputs and any specified electrical demand must be supplied."
	  },
	  {
	    "id": "chlorosilane_purification",
	    "name": "Chlorosilane Purification",
	    "direction": "Materials",
	    "day": 85000,
	    "chance": 0.002,
	    "requires": [
	      "silicon_smelting",
	      "fractional_distillation"
	    ],
	    "requires_all": [
	      "silicon_smelting",
	      "fractional_distillation"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "materials"
	    ],
	    "observation": "A volatile chemical intermediate allows impurities to be separated before silicon is deposited again.",
	    "effects": {},
	    "production_items": [
	      "purified_silicon"
	    ],
	    "production_contract": "Enables the physical purified silicon recipe. Workshop labor, setup tooling, batch inputs and any specified electrical demand must be supplied."
	  },
	  {
	    "id": "single_crystal_growth",
	    "name": "Single-Crystal Growth",
	    "direction": "Materials",
	    "day": 88000,
	    "chance": 0.002,
	    "requires": [
	      "crystallography",
	      "chlorosilane_purification",
	      "precision_thermometry"
	    ],
	    "requires_all": [
	      "crystallography",
	      "chlorosilane_purification",
	      "precision_thermometry"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "materials"
	    ],
	    "observation": "Controlled solidification extends a selected crystal orientation through a semiconductor boule.",
	    "effects": {},
	    "production_items": [
	      "silicon_boules"
	    ],
	    "production_contract": "Enables the physical silicon crystal boules recipe. Workshop labor, setup tooling, batch inputs and any specified electrical demand must be supplied."
	  },
	  {
	    "id": "wafer_sawing",
	    "name": "Semiconductor Wafer Sawing",
	    "direction": "Materials",
	    "day": 89000,
	    "chance": 0.002,
	    "requires": [
	      "single_crystal_growth",
	      "standard_measures"
	    ],
	    "requires_all": [
	      "single_crystal_growth",
	      "standard_measures"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "materials"
	    ],
	    "observation": "Thin slices are cut from semiconductor boules, with abrasive loss and surface damage limiting usable output.",
	    "effects": {},
	    "production_items": [
	      "silicon_wafers"
	    ],
	    "production_contract": "Enables the physical sawn silicon wafers recipe. Workshop labor, setup tooling, batch inputs and any specified electrical demand must be supplied.",
	    "learning_routes": [
	      {
	        "id": "machined",
	        "label": "Precision slicing equipment",
	        "requires_all": [
	          "precision_machinery"
	        ]
	      },
	      {
	        "id": "abrasive_wire",
	        "label": "Measured abrasive-wire cutting",
	        "requires_all": [
	          "wire_drawing",
	          "optical_lenses"
	        ],
	        "progress_multiplier": 0.65
	      }
	    ]
	  },
	  {
	    "id": "photovoltaic_conversion",
	    "name": "Photovoltaic Conversion",
	    "direction": "Information",
	    "day": 90000,
	    "chance": 0.002,
	    "requires": [
	      "electrical_measurement"
	    ],
	    "requires_all": [
	      "electrical_measurement"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "materials"
	    ],
	    "observation": "Illuminated material produces a measurable voltage and supplies current to an external load.",
	    "effects": {},
	    "foundation_for": [
	      "solar_cell_fabrication"
	    ],
	    "production_contract": "Provides the stated scientific foundation for solar_cell_fabrication. Understanding alone supplies no equipment or operating service.",
	    "learning_routes": [
	      {
	        "id": "empirical",
	        "label": "Illuminated material experiments",
	        "requires_all": [
	          "photoconductivity",
	          "electrochemical_cells"
	        ],
	        "progress_multiplier": 0.65
	      },
	      {
	        "id": "junction",
	        "label": "Junction-based conversion",
	        "requires_all": [
	          "pn_junctions"
	        ]
	      }
	    ]
	  },
	  {
	    "id": "solar_cell_fabrication",
	    "name": "Solar Cell Fabrication",
	    "direction": "Materials",
	    "day": 92000,
	    "chance": 0.002,
	    "requires": [
	      "photovoltaic_conversion",
	      "wafer_sawing",
	      "semiconductor_doping"
	    ],
	    "requires_all": [
	      "photovoltaic_conversion",
	      "wafer_sawing",
	      "semiconductor_doping"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "materials"
	    ],
	    "observation": "Prepared wafer surfaces, junctions and metal contacts are combined into working photovoltaic cells.",
	    "effects": {},
	    "production_items": [
	      "solar_cells"
	    ],
	    "production_contract": "Enables the physical photovoltaic cells recipe. Workshop labor, setup tooling, batch inputs and any specified electrical demand must be supplied."
	  },
	  {
	    "id": "module_encapsulation",
	    "name": "Photovoltaic Module Encapsulation",
	    "direction": "Materials",
	    "day": 93000,
	    "chance": 0.002,
	    "requires": [
	      "solar_cell_fabrication",
	      "glassmaking",
	      "cable_insulation"
	    ],
	    "requires_all": [
	      "solar_cell_fabrication",
	      "glassmaking",
	      "cable_insulation"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "materials"
	    ],
	    "observation": "Connected cells are enclosed behind protective glazing and mounted for outdoor electrical service.",
	    "effects": {},
	    "production_items": [
	      "solar_modules"
	    ],
	    "production_contract": "Enables the physical photovoltaic modules recipe. Workshop labor, setup tooling, batch inputs and any specified electrical demand must be supplied."
	  },
	  {
	    "id": "photovoltaic_power",
	    "name": "Photovoltaic Power",
	    "direction": "Infrastructure",
	    "day": 95000,
	    "chance": 0.002,
	    "requires": [
	      "module_encapsulation",
	      "electrical_measurement"
	    ],
	    "requires_all": [
	      "module_encapsulation",
	      "electrical_measurement"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "materials"
	    ],
	    "observation": "Installed modules and wiring are commissioned as an operated source of electrical energy.",
	    "effects": {},
	    "operating_plants": [
	      "solar_array"
	    ],
	    "production_contract": "Enables commissioning installed photovoltaic modules into daily electrical service, with actual operators and finite demand."
	  }
	]
