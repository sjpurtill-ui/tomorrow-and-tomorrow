extends RefCounted
## Shared civilian foundations for engineering, observation and future science.
static func entries()->Array[Dictionary]:
	return [
	  {
	    "id": "glassmaking",
	    "name": "Glassmaking",
	    "direction": "Materials",
	    "day": 6000,
	    "chance": 0.002,
	    "requires": [
	      "kiln_control",
	      "salt_working"
	    ],
	    "requires_all": [
	      "kiln_control",
	      "salt_working"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Silica mixtures are heated and cooled into reproducible glass for vessels and optical work.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Glassmaking investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "crucible_glass_melting",
	      "ceramic_glaze_formulation"
	    ]
	  },
	  {
	    "id": "optical_lenses",
	    "name": "Optical Lenses",
	    "direction": "Information",
	    "day": 13000,
	    "chance": 0.002,
	    "requires": [
	      "glassmaking",
	      "standard_measures"
	    ],
	    "requires_all": [
	      "glassmaking",
	      "standard_measures"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Curved transparent surfaces are ground and compared for repeatable magnification and focus.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Optical Lenses investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "two_lens_tube_microscope",
	      "two_lens_telescope"
	    ]
	  },
	  {
	    "id": "experimental_optics",
	    "name": "Experimental Optics",
	    "direction": "Information",
	    "day": 23000,
	    "chance": 0.002,
	    "requires": [
	      "optical_lenses",
	      "experimental_controls"
	    ],
	    "requires_all": [
	      "optical_lenses",
	      "experimental_controls"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Controlled light paths distinguish reflection, refraction and interference effects.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Experimental Optics investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "spectroscopy"
	    ]
	  },
	  {
	    "id": "vacuum_pumps",
	    "name": "Vacuum Pumps",
	    "direction": "Information",
	    "day": 35000,
	    "chance": 0.002,
	    "requires": [
	      "precision_machinery",
	      "sealed_vessels"
	    ],
	    "requires_all": [
	      "precision_machinery",
	      "sealed_vessels"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Fitted pumps and seals remove air from experimental chambers.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Vacuum Pumps investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "vacuum_experiments"
	    ]
	  },
	  {
	    "id": "vacuum_experiments",
	    "name": "Vacuum Experiments",
	    "direction": "Information",
	    "day": 42000,
	    "chance": 0.002,
	    "requires": [
	      "vacuum_pumps",
	      "experimental_controls"
	    ],
	    "requires_all": [
	      "vacuum_pumps",
	      "experimental_controls"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Pressure is varied systematically while other chamber conditions are recorded.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Vacuum Experiments investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "steam_suction_pump"
	    ]
	  },
	  {
	    "id": "precision_thermometry",
	    "name": "Precision Thermometry",
	    "direction": "Information",
	    "day": 28000,
	    "chance": 0.002,
	    "requires": [
	      "glassmaking",
	      "standard_measures"
	    ],
	    "requires_all": [
	      "glassmaking",
	      "standard_measures"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Reproducible temperature scales let observers compare heating and cooling experiments.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Precision Thermometry investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "calorimetry",
	      "fractional_distillation"
	    ]
	  },
	  {
	    "id": "calorimetry",
	    "name": "Calorimetry",
	    "direction": "Information",
	    "day": 36000,
	    "chance": 0.002,
	    "requires": [
	      "precision_thermometry",
	      "experimental_controls"
	    ],
	    "requires_all": [
	      "precision_thermometry",
	      "experimental_controls"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Measured heat exchanges distinguish temperature from the quantity of energy transferred.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Calorimetry investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "heat_engine_cycles"
	    ]
	  },
	  {
	    "id": "heat_engine_cycles",
	    "name": "Heat Engine Cycles",
	    "direction": "Information",
	    "day": 47000,
	    "chance": 0.002,
	    "requires": [
	      "calorimetry",
	      "pressure_vessels"
	    ],
	    "requires_all": [
	      "calorimetry",
	      "pressure_vessels"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Comparisons of compression, heating and expansion relate fuel use to mechanical work.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Heat Engine Cycles investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "steam_turbines",
	      "internal_combustion",
	      "jet_propulsion"
	    ]
	  },
	  {
	    "id": "pressure_vessels",
	    "name": "Pressure Vessels",
	    "direction": "Materials",
	    "day": 39000,
	    "chance": 0.002,
	    "requires": [
	      "forge_welding",
	      "standard_measures"
	    ],
	    "requires_all": [
	      "forge_welding",
	      "standard_measures"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Joined vessels are tested against internal pressure before use in engines and experiments.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Pressure Vessels investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "compressed_air_systems",
	      "reactor_engineering"
	    ]
	  },
	  {
	    "id": "chemical_distillation",
	    "name": "Chemical Distillation",
	    "direction": "Materials",
	    "day": 11000,
	    "chance": 0.002,
	    "requires": [
	      "sealed_vessels",
	      "kiln_control"
	    ],
	    "requires_all": [
	      "sealed_vessels",
	      "kiln_control"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Vapors are condensed separately from their heated mixtures to recover different fractions.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Chemical Distillation investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "fractional_distillation"
	    ]
	  },
	  {
	    "id": "fractional_distillation",
	    "name": "Fractional Distillation",
	    "direction": "Materials",
	    "day": 46000,
	    "chance": 0.002,
	    "requires": [
	      "chemical_distillation",
	      "precision_thermometry"
	    ],
	    "requires_all": [
	      "chemical_distillation",
	      "precision_thermometry"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Repeated vapor-liquid contact separates mixtures by measured boiling behavior.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Fractional Distillation investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "fuel_refining"
	    ]
	  },
	  {
	    "id": "electrochemical_cells",
	    "name": "Electrochemical Cells",
	    "direction": "Information",
	    "day": 36000,
	    "chance": 0.002,
	    "requires": [
	      "copper_casting",
	      "chemical_distillation"
	    ],
	    "requires_all": [
	      "copper_casting",
	      "chemical_distillation"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Paired materials and electrolytes produce repeatable electrical currents for experiments.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Electrochemical Cells investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "electrical_measurement"
	    ]
	  },
	  {
	    "id": "electrical_measurement",
	    "name": "Electrical Measurement",
	    "direction": "Information",
	    "day": 43000,
	    "chance": 0.002,
	    "requires": [
	      "electrochemical_cells",
	      "standard_measures"
	    ],
	    "requires_all": [
	      "electrochemical_cells",
	      "standard_measures"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Current, potential difference and resistance are compared using calibrated instruments.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Electrical Measurement investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "electromagnetic_induction"
	    ]
	  },
	  {
	    "id": "electromagnetic_induction",
	    "name": "Electromagnetic Induction",
	    "direction": "Information",
	    "day": 51000,
	    "chance": 0.002,
	    "requires": [
	      "electrical_measurement",
	      "experimental_controls"
	    ],
	    "requires_all": [
	      "electrical_measurement",
	      "experimental_controls"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Changing magnetic conditions produce measurable electrical currents in conducting circuits.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Electromagnetic Induction investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "electrical_generators",
	      "electric_motors"
	    ]
	  },
	  {
	    "id": "electrical_generators",
	    "name": "Electrical Generators",
	    "direction": "Materials",
	    "day": 59000,
	    "chance": 0.002,
	    "requires": [
	      "electromagnetic_induction",
	      "precision_machinery"
	    ],
	    "requires_all": [
	      "electromagnetic_induction",
	      "precision_machinery"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Rotating magnetic machinery converts mechanical input into sustained electrical output.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Electrical Generators investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "reactor_engineering"
	    ]
	  },
	  {
	    "id": "electric_motors",
	    "name": "Electric Motors",
	    "direction": "Materials",
	    "day": 62000,
	    "chance": 0.002,
	    "requires": [
	      "electromagnetic_induction",
	      "precision_machinery"
	    ],
	    "requires_all": [
	      "electromagnetic_induction",
	      "precision_machinery"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Controlled current and magnetic forces produce repeatable rotary mechanical work.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Electric Motors investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "electric_street_tramways"
	    ]
	  },
	  {
	    "id": "spectroscopy",
	    "name": "Spectroscopy",
	    "direction": "Information",
	    "day": 63000,
	    "chance": 0.002,
	    "requires": [
	      "experimental_optics",
	      "precision_thermometry"
	    ],
	    "requires_all": [
	      "experimental_optics",
	      "precision_thermometry"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Separated light patterns are compared to distinguish emitting and absorbing materials.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Spectroscopy investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "periodic_element_table"
	    ]
	  },
	  {
	    "id": "electron_physics",
	    "name": "Electron Physics",
	    "direction": "Information",
	    "day": 71000,
	    "chance": 0.002,
	    "requires": [
	      "vacuum_experiments",
	      "electrical_measurement"
	    ],
	    "requires_all": [
	      "vacuum_experiments",
	      "electrical_measurement"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Experiments with discharge and charged particles establish reproducible electronic behavior.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Electron Physics investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "radiation_measurement",
	      "atomic_physics"
	    ]
	  },
	  {
	    "id": "radiation_measurement",
	    "name": "Radiation Measurement",
	    "direction": "Information",
	    "day": 75000,
	    "chance": 0.002,
	    "requires": [
	      "electron_physics",
	      "statistical_inference"
	    ],
	    "requires_all": [
	      "electron_physics",
	      "statistical_inference"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Shielded detectors and counted events distinguish radiation exposure from instrumental background.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Radiation Measurement investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "nuclear_fission"
	    ]
	  },
	  {
	    "id": "nuclear_fission",
	    "name": "Nuclear Fission",
	    "direction": "Information",
	    "day": 89000,
	    "chance": 0.002,
	    "requires": [
	      "atomic_physics",
	      "radiation_measurement"
	    ],
	    "requires_all": [
	      "atomic_physics",
	      "radiation_measurement"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Measured nuclear fragmentation connects reaction products, released energy and neutron production.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Nuclear Fission investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "neutron_moderation",
	      "reactor_engineering"
	    ]
	  },
	  {
	    "id": "neutron_moderation",
	    "name": "Neutron Moderation",
	    "direction": "Information",
	    "day": 91000,
	    "chance": 0.002,
	    "requires": [
	      "nuclear_fission",
	      "experimental_controls"
	    ],
	    "requires_all": [
	      "nuclear_fission",
	      "experimental_controls"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Materials are compared for how they slow and absorb neutrons in a controlled reaction system.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Neutron Moderation investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "reactor_engineering"
	    ]
	  },
	  {
	    "id": "structural_load_testing",
	    "name": "Structural Load Testing",
	    "direction": "Information",
	    "day": 52000,
	    "chance": 0.002,
	    "requires": [
	      "standard_measures",
	      "workshop_standards",
	      "experimental_controls"
	    ],
	    "requires_all": [
	      "standard_measures",
	      "workshop_standards",
	      "experimental_controls"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Repeatable loads reveal failure margins and fatigue in structural members.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Structural Load Testing investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "powered_flight",
	      "advanced_airframes"
	    ]
	  },
	  {
	    "id": "aerodynamics",
	    "name": "Aerodynamics",
	    "direction": "Information",
	    "day": 68000,
	    "chance": 0.002,
	    "requires": [
	      "structural_load_testing",
	      "experimental_controls"
	    ],
	    "requires_all": [
	      "structural_load_testing",
	      "experimental_controls"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Controlled flow measurements compare lift, drag and stability of candidate surfaces.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Aerodynamics investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "wind_tunnel_testing",
	      "powered_flight"
	    ]
	  },
	  {
	    "id": "wind_tunnel_testing",
	    "name": "Wind Tunnel Testing",
	    "direction": "Information",
	    "day": 78000,
	    "chance": 0.002,
	    "requires": [
	      "aerodynamics",
	      "electric_motors"
	    ],
	    "requires_all": [
	      "aerodynamics",
	      "electric_motors"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "information"
	    ],
	    "observation": "Powered test sections compare airframes under repeatable flow and measured loads.",
	    "effects": {},
	    "production_contract": "A causal scientific or engineering foundation for the named downstream capabilities. Knowing the principle does not create an operating plant or award a global output bonus.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Wind Tunnel Testing investigations",
	        "requires_all": []
	      }
	    ],
	    "foundation_for": [
	      "advanced_airframes"
	    ]
	  }
	]
