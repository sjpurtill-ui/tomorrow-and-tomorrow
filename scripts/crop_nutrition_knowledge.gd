extends RefCounted
## Individually authored nutrient and industrial-feedstock capabilities.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "nutrient_response_trials",
    "name": "Nutrient Response Trials",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "soil_assays",
      "experimental_controls"
    ],
    "requires_all": [
      "soil_assays",
      "experimental_controls"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Nutrient Response Trials",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "food",
      "research"
    ],
    "observation": "Comparable plots separate the response to supplied plant nutrients from differences in soil, water and seed.",
    "effects": {},
    "production_items": [],
    "production_contract": "Farmers use prepared nitrogen and phosphate inputs together for up to 25% additional cultivation output at full adoption. Applications fill at most a week of expected uptake; retained reserves are local, finite and consumed by cultivation. No bonus applies without both nutrients, cultivation work and a settled site. Baseline soil fertility remains separate.",
    "nutrient_application": true
  },
  {
    "id": "mineral_nitrate_dressing",
    "name": "Mineral Nitrate Dressing",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "nitrate_cultivation",
      "nutrient_response_trials"
    ],
    "requires_all": [
      "nitrate_cultivation",
      "nutrient_response_trials"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Mineral Nitrate Dressing",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "food",
      "research"
    ],
    "observation": "Prepared mineral nitrate is accounted for as a crop input instead of treating a nearby deposit as an automatic harvest gain.",
    "effects": {},
    "production_items": [
      "nitrate_fertilizer"
    ],
    "production_contract": "Manufactured inputs use finite stocks, installed tooling, shared Crafting labor and specified electricity. Fertilizer reaches crops only through local nutrient application and uptake; quantities are abstract game batches."
  },
  {
    "id": "sulfur_dioxide_recovery",
    "name": "Sulfur Dioxide Recovery",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "sulfur_purification",
      "sealed_vessels"
    ],
    "requires_all": [
      "sulfur_purification",
      "sealed_vessels"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Sulfur Dioxide Recovery",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "food",
      "research"
    ],
    "observation": "Contained processing recovers a sulfur-bearing gas stream as a chemical feedstock.",
    "effects": {},
    "production_items": [
      "recovered_sulfur_dioxide"
    ],
    "production_contract": "Manufactured inputs use finite stocks, installed tooling, shared Crafting labor and specified electricity. Fertilizer reaches crops only through local nutrient application and uptake; quantities are abstract game batches."
  },
  {
    "id": "sulfuric_acid_production",
    "name": "Sulfuric Acid Production",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "sulfur_dioxide_recovery",
      "chemical_distillation",
      "pressure_vessels"
    ],
    "requires_all": [
      "sulfur_dioxide_recovery",
      "chemical_distillation",
      "pressure_vessels"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Sulfuric Acid Production",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "food",
      "research"
    ],
    "observation": "A controlled chemical process turns a recovered sulfur feed into an acid used to transform mineral materials.",
    "effects": {},
    "production_items": [
      "sulfuric_acid"
    ],
    "production_contract": "Manufactured inputs use finite stocks, installed tooling, shared Crafting labor and specified electricity. Fertilizer reaches crops only through local nutrient application and uptake; quantities are abstract game batches."
  },
  {
    "id": "phosphate_solubilization",
    "name": "Phosphate Solubilization",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "phosphate_dressing",
      "sulfuric_acid_production",
      "nutrient_response_trials"
    ],
    "requires_all": [
      "phosphate_dressing",
      "sulfuric_acid_production",
      "nutrient_response_trials"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Phosphate Solubilization",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "food",
      "research"
    ],
    "observation": "Chemical treatment makes more of a phosphate feed available to crops, at the cost of another manufactured input.",
    "effects": {},
    "production_items": [
      "soluble_phosphate_fertilizer"
    ],
    "production_contract": "Manufactured inputs use finite stocks, installed tooling, shared Crafting labor and specified electricity. Fertilizer reaches crops only through local nutrient application and uptake; quantities are abstract game batches."
  },
  {
    "id": "compressed_air_systems",
    "name": "Compressed Air Systems",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "pressure_vessels",
      "electric_motors"
    ],
    "requires_all": [
      "pressure_vessels",
      "electric_motors"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Compressed Air Systems",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "food",
      "research"
    ],
    "observation": "Powered compressors and sealed receivers deliver an air feed for industrial separation.",
    "effects": {},
    "production_items": [
      "compressed_air"
    ],
    "production_contract": "Manufactured inputs use finite stocks, installed tooling, shared Crafting labor and specified electricity. Fertilizer reaches crops only through local nutrient application and uptake; quantities are abstract game batches."
  },
  {
    "id": "cryogenic_air_separation",
    "name": "Cryogenic Air Separation",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "compressed_air_systems",
      "mechanical_refrigeration",
      "chemical_distillation"
    ],
    "requires_all": [
      "compressed_air_systems",
      "mechanical_refrigeration",
      "chemical_distillation"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Cryogenic Air Separation",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "food",
      "research"
    ],
    "observation": "Cooling and separation recover distinct nitrogen and oxygen streams from processed air.",
    "effects": {},
    "production_items": [
      "separated_air"
    ],
    "production_contract": "Manufactured inputs use finite stocks, installed tooling, shared Crafting labor and specified electricity. Fertilizer reaches crops only through local nutrient application and uptake; quantities are abstract game batches."
  },
  {
    "id": "water_electrolysis",
    "name": "Water Electrolysis",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "electrochemical_cells",
      "electrical_generators",
      "pressure_vessels"
    ],
    "requires_all": [
      "electrochemical_cells",
      "electrical_generators",
      "pressure_vessels"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Water Electrolysis",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "food",
      "research"
    ],
    "observation": "Powered separated cells split a water feed into recoverable hydrogen and oxygen streams.",
    "effects": {},
    "production_items": [
      "electrolytic_hydrogen"
    ],
    "production_contract": "Manufactured inputs use finite stocks, installed tooling, shared Crafting labor and specified electricity. Fertilizer reaches crops only through local nutrient application and uptake; quantities are abstract game batches."
  },
  {
    "id": "iron_ammonia_catalysts",
    "name": "Iron Ammonia Catalysts",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "bloomery_smelting",
      "experimental_controls",
      "chemical_distillation"
    ],
    "requires_all": [
      "bloomery_smelting",
      "experimental_controls",
      "chemical_distillation"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Iron Ammonia Catalysts",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "food",
      "research"
    ],
    "observation": "Prepared iron catalyst material supports ammonia synthesis without becoming the main chemical feedstock.",
    "effects": {},
    "production_items": [
      "ammonia_catalysts"
    ],
    "production_contract": "Manufactured inputs use finite stocks, installed tooling, shared Crafting labor and specified electricity. Fertilizer reaches crops only through local nutrient application and uptake; quantities are abstract game batches."
  },
  {
    "id": "catalytic_ammonia_synthesis",
    "name": "Catalytic Ammonia Synthesis",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "iron_ammonia_catalysts",
      "cryogenic_air_separation",
      "pressure_vessels"
    ],
    "requires_all": [
      "iron_ammonia_catalysts",
      "cryogenic_air_separation",
      "pressure_vessels"
    ],
    "requires_any": [
      [
        "chloralkali_cells",
        "water_electrolysis"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Catalytic Ammonia Synthesis",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "food",
      "research"
    ],
    "observation": "An energy-consuming catalytic process combines nitrogen and hydrogen into ammonia for further manufacture.",
    "effects": {},
    "production_items": [
      "synthetic_ammonia"
    ],
    "production_contract": "Manufactured inputs use finite stocks, installed tooling, shared Crafting labor and specified electricity. Fertilizer reaches crops only through local nutrient application and uptake; quantities are abstract game batches."
  },
  {
    "id": "ammonium_sulfate_fertilizer",
    "name": "Ammonium Sulfate Fertilizer",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "catalytic_ammonia_synthesis",
      "sulfuric_acid_production",
      "nutrient_response_trials"
    ],
    "requires_all": [
      "catalytic_ammonia_synthesis",
      "sulfuric_acid_production",
      "nutrient_response_trials"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Ammonium Sulfate Fertilizer",
        "requires_all": []
      }
    ],
    "signals": [
      "materials",
      "food",
      "research"
    ],
    "observation": "Manufactured ammonia and acid supply a storable nitrogen fertilizer independently of a local nitrate deposit.",
    "effects": {},
    "production_items": [
      "ammonium_sulfate"
    ],
    "production_contract": "Manufactured inputs use finite stocks, installed tooling, shared Crafting labor and specified electricity. Fertilizer reaches crops only through local nutrient application and uptake; quantities are abstract game batches."
  }
]
