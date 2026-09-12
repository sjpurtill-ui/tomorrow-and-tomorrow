extends RefCounted
## Authored processing and assay equipment. Rates use aggregate ration units.
const METHODS := {
  "food_pounding_mortars": {
    "name": "Food Pounding Mortars",
    "requires_all": [],
    "requires_any": [
      [
        "stone_sorting",
        "hafted_tools"
      ]
    ],
    "rate": 18.0,
    "cost": {
      "Stone": 4,
      "Timber": 1
    },
    "inputs": {},
    "mode": "pound",
    "observation": "Break or separate suitable food material through controlled impact in a fitted receptacle. Compatible pounding tools, actual food and labor."
  },
  "hand_dough_forming": {
    "name": "Hand Dough Forming",
    "requires_all": [
      "grain_milling"
    ],
    "requires_any": [],
    "rate": 18.0,
    "cost": {
      "Timber": 2,
      "Clay": 2
    },
    "inputs": {
      "Freshwater": 0.08
    },
    "mode": "form",
    "observation": "Shape a prepared dough through repeated hand or simple-tool work. Suitable ingredients, working surface and skilled labor."
  },
  "dough_leavening": {
    "name": "Dough Leavening",
    "requires_all": [
      "fermentation_control",
      "flour_sifting"
    ],
    "requires_any": [],
    "rate": 16.0,
    "cost": {
      "Clay": 3,
      "Timber": 1
    },
    "inputs": {},
    "mode": "leaven",
    "observation": "Retain fermentation gases within a prepared dough structure. Flour, water, a maintained ferment and suitable conditions."
  },
  "controlled_baking": {
    "name": "Controlled Baking",
    "requires_all": [
      "kiln_control",
      "hand_dough_forming"
    ],
    "requires_any": [],
    "rate": 24.0,
    "cost": {
      "Clay": 6,
      "Stone": 4
    },
    "inputs": {
      "Timber": 0.03
    },
    "mode": "bake",
    "observation": "Apply a repeatable heating schedule to prepared food. Oven, fuel, monitoring and trained operators."
  },
  "fermentation_starter_cultures": {
    "name": "Fermentation Starter Cultures",
    "requires_all": [
      "fermentation_control"
    ],
    "requires_any": [
      [
        "experimental_controls"
      ]
    ],
    "rate": 12.0,
    "cost": {
      "Laboratory Glassware": 1,
      "Clay": 2
    },
    "inputs": {
      "Freshwater": 0.1
    },
    "mode": "culture",
    "observation": "Maintain and use characterized cultures for a specified food fermentation. Qualified cultures, suitable substrate, hygiene and controlled process conditions."
  },
  "cereal_dehulling": {
    "name": "Cereal Dehulling",
    "requires_all": [
      "grain_milling"
    ],
    "requires_any": [],
    "rate": 20.0,
    "cost": {
      "Stone": 4,
      "Woven Cloth": 1
    },
    "inputs": {},
    "mode": "dehull",
    "observation": "Separate protective grain coverings while limiting loss of edible material. Suitable grain, mechanical tools and practiced separation."
  },
  "starch_washing_separation": {
    "name": "Starch Washing Separation",
    "requires_all": [
      "food_pounding_mortars",
      "clean_water"
    ],
    "requires_any": [],
    "rate": 15.0,
    "cost": {
      "Woven Cloth": 2,
      "Clay": 3
    },
    "inputs": {
      "Freshwater": 0.2
    },
    "mode": "wash",
    "observation": "Separate suitable starch-rich fractions by controlled washing and settling. Recognized feedstock, suitable water, vessels and labor."
  },
  "postharvest_loss_measurement": {
    "name": "Postharvest Loss Measurement",
    "requires_all": [
      "material_accounting",
      "statistical_sampling"
    ],
    "requires_any": [],
    "rate": 80.0,
    "cost": {
      "Laboratory Glassware": 1,
      "Timber": 1
    },
    "inputs": {
      "Paper": 0.002
    },
    "mode": "loss",
    "observation": "Measure quantity and quality losses across defined handling stages with explicit boundaries. Representative observation, scales, condition assessment and records."
  },
  "food_batch_traceability": {
    "name": "Food-Batch Traceability",
    "requires_all": [
      "material_accounting",
      "cargo_seals"
    ],
    "requires_any": [],
    "rate": 100.0,
    "cost": {
      "Timber": 1,
      "Clay": 1
    },
    "inputs": {
      "Paper": 0.003
    },
    "mode": "trace",
    "observation": "Record ingredient sources, processing batches and destinations. Identified lots and reliable handling records."
  },
  "food_process_hazard_analysis": {
    "name": "Food-Process Hazard Analysis",
    "requires_all": [
      "food_batch_traceability"
    ],
    "requires_any": [
      [
        "thermal_process_validation",
        "experimental_controls"
      ]
    ],
    "rate": 80.0,
    "cost": {
      "Timber": 2,
      "Laboratory Glassware": 1
    },
    "inputs": {
      "Paper": 0.003
    },
    "mode": "review",
    "observation": "Identify process stages where failure can create a food hazard and define monitored controls. Qualified analysis, validated controls and operating records."
  },
  "food_acidity_measurement": {
    "name": "Food Acidity Measurement",
    "requires_all": [
      "standard_measures",
      "electrochemical_cells"
    ],
    "requires_any": [],
    "rate": 60.0,
    "cost": {
      "Laboratory Glassware": 2,
      "Copper Wire": 1
    },
    "inputs": {
      "Freshwater": 0.01
    },
    "mode": "acidity",
    "observation": "Measure a specified acidity property with calibrated food-analysis methods. Qualified testing, representative samples and retained process context."
  },
  "food_water_activity_measurement": {
    "name": "Food Water Activity Measurement",
    "requires_all": [
      "food_process_hazard_analysis",
      "humidity_measurement"
    ],
    "requires_any": [],
    "rate": 50.0,
    "cost": {
      "Laboratory Glassware": 2,
      "Woven Cloth": 1
    },
    "inputs": {
      "Freshwater": 0.01
    },
    "mode": "activity",
    "observation": "Measure available water in a defined food matrix against a validated method. Qualified instrument, representative samples and competent interpretation."
  },
  "food_package_leak_detection": {
    "name": "Food Package Leak Detection",
    "requires_all": [
      "food_package_barrier_testing"
    ],
    "requires_any": [
      [
        "pressure_vessels",
        "electrical_measurement"
      ]
    ],
    "rate": 70.0,
    "cost": {
      "Laboratory Glassware": 1,
      "Copper Wire": 1
    },
    "inputs": {
      "Freshwater": 0.02
    },
    "mode": "leak",
    "observation": "Test finished package integrity through a qualified non-destructive or sampling method. Suitable inspection equipment, samples and rejection controls."
  },
  "food_package_barrier_testing": {
    "name": "Food Package Barrier Testing",
    "requires_all": [
      "food_process_hazard_analysis"
    ],
    "requires_any": [
      [
        "experimental_controls"
      ]
    ],
    "rate": 60.0,
    "cost": {
      "Laboratory Glassware": 2,
      "Woven Cloth": 1
    },
    "inputs": {
      "Woven Cloth": 0.003
    },
    "mode": "barrier",
    "observation": "Measure package transmission and compatibility against a specified food-storage requirement. Representative packages, qualified tests and product evidence."
  },
  "humidity_measurement": {
    "name": "Humidity Measurement",
    "requires_all": [
      "precision_thermometry",
      "measurement_uncertainty"
    ],
    "requires_any": [],
    "rate": 100.0,
    "cost": {
      "Laboratory Glassware": 1,
      "Woven Cloth": 1
    },
    "inputs": {
      "Freshwater": 0.01
    },
    "mode": "humidity",
    "observation": "Measure atmospheric moisture through a qualified method. Suitable instruments, calibration and exposure."
  }
}

static func entries()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for id:String in METHODS:
		var spec:Dictionary=METHODS[id]
		result.append({"id":id,"name":spec.name,"direction":"Sustenance","day":0,"chance":.002,"requires":spec.requires_all.duplicate(),"requires_all":spec.requires_all.duplicate(),"requires_any":spec.requires_any.duplicate(true),"learning_routes":[{"id":"local","label":spec.name,"requires_all":[]}],"signals":["food","crafting","research"],"observation":spec.observation,"effects":{},"food_batch_method":id,"production_contract":"Paid equipment and shared Logistics time process finite cereal lots or consume representative samples. Inspection records apply to the examined lot; they do not provide universal safety or free food. Baking, fermentation and packaging need their actual inputs."})
	return result
