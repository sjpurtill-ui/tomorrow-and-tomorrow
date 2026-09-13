extends RefCounted
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "habitat_observation_records",
    "name": "Habitat Observation Records",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "herbal_classification",
      "seasonal_patterns"
    ],
    "requires_all": [
      "herbal_classification",
      "seasonal_patterns"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Habitat Observation Records",
        "requires_all": []
      }
    ],
    "signals": [
      "food",
      "nature",
      "information"
    ],
    "observation": "Record organisms alongside the places and seasonal conditions where they occur",
    "effects": {},
    "operating_contract": "Paid local crop cohorts, dated controlled observations and retained seed provenance support a bounded context-specific cultivation application; discovery alone grants no seed, evidence or harvest benefit."
  },
  {
    "id": "comparative_anatomy",
    "name": "Comparative Anatomy",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "herbal_classification",
      "habitat_observation_records"
    ],
    "requires_all": [
      "herbal_classification",
      "habitat_observation_records"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Comparative Anatomy",
        "requires_all": []
      }
    ],
    "signals": [
      "food",
      "nature",
      "information"
    ],
    "observation": "Compare the arrangement and form of structures across organisms",
    "effects": {},
    "operating_contract": "Paid local crop cohorts, dated controlled observations and retained seed provenance support a bounded context-specific cultivation application; discovery alone grants no seed, evidence or harvest benefit."
  },
  {
    "id": "biological_classification",
    "name": "Biological Classification",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "herbal_classification",
      "habitat_observation_records"
    ],
    "requires_all": [
      "herbal_classification",
      "habitat_observation_records"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Biological Classification",
        "requires_all": []
      }
    ],
    "signals": [
      "food",
      "nature",
      "information"
    ],
    "observation": "Group organisms using explicit diagnostic traits and revisable relationships",
    "effects": {},
    "operating_contract": "Paid local crop cohorts, dated controlled observations and retained seed provenance support a bounded context-specific cultivation application; discovery alone grants no seed, evidence or harvest benefit."
  },
  {
    "id": "biological_reference_collections",
    "name": "Biological Reference Collections",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "biological_classification",
      "formal_archives"
    ],
    "requires_all": [
      "biological_classification",
      "formal_archives"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Biological Reference Collections",
        "requires_all": []
      }
    ],
    "signals": [
      "food",
      "nature",
      "information"
    ],
    "observation": "Retain identified examples linked to collection and observation records",
    "effects": {},
    "operating_contract": "Paid local crop cohorts, dated controlled observations and retained seed provenance support a bounded context-specific cultivation application; discovery alone grants no seed, evidence or harvest benefit."
  },
  {
    "id": "developmental_stage_series",
    "name": "Developmental Stage Series",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "comparative_anatomy"
    ],
    "requires_all": [
      "comparative_anatomy"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Developmental Stage Series",
        "requires_all": []
      }
    ],
    "signals": [
      "food",
      "nature",
      "information"
    ],
    "observation": "Compare organisms at successive stages of development",
    "effects": {},
    "operating_contract": "Paid local crop cohorts, dated controlled observations and retained seed provenance support a bounded context-specific cultivation application; discovery alone grants no seed, evidence or harvest benefit."
  },
  {
    "id": "heredity_experiments",
    "name": "Heredity Experiments",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "progeny_rows",
      "controlled_pollination"
    ],
    "requires_all": [
      "progeny_rows",
      "controlled_pollination"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Heredity Experiments",
        "requires_all": []
      }
    ],
    "signals": [
      "food",
      "nature",
      "information"
    ],
    "observation": "Compare trait patterns across controlled parentage and successive generations",
    "effects": {},
    "operating_contract": "Paid local crop cohorts, dated controlled observations and retained seed provenance support a bounded context-specific cultivation application; discovery alone grants no seed, evidence or harvest benefit."
  },
  {
    "id": "plant_transpiration_measurement",
    "name": "Plant Transpiration Measurement",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "experimental_controls"
    ],
    "requires_all": [
      "experimental_controls"
    ],
    "requires_any": [
      [
        "photosynthetic_process_analysis",
        "crop_calendars"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Plant Transpiration Measurement",
        "requires_all": []
      }
    ],
    "signals": [
      "food",
      "nature",
      "information"
    ],
    "observation": "Measure water loss through plants in relation to environmental and physiological conditions",
    "effects": {},
    "operating_contract": "Paid local crop cohorts, dated controlled observations and retained seed provenance support a bounded context-specific cultivation application; discovery alone grants no seed, evidence or harvest benefit."
  },
  {
    "id": "plant_pathology_diagnosis",
    "name": "Plant Pathology Diagnosis",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "biological_classification"
    ],
    "requires_all": [
      "biological_classification"
    ],
    "requires_any": [
      [
        "germ_theory",
        "experimental_controls"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Plant Pathology Diagnosis",
        "requires_all": []
      }
    ],
    "signals": [
      "food",
      "nature",
      "information"
    ],
    "observation": "Distinguish plausible causes of plant damage using qualified organism and environmental evidence",
    "effects": {},
    "operating_contract": "Paid local crop cohorts, dated controlled observations and retained seed provenance support a bounded context-specific cultivation application; discovery alone grants no seed, evidence or harvest benefit."
  },
  {
    "id": "plant_resistance_trait_trials",
    "name": "Plant Resistance Trait Trials",
    "direction": "Sustenance",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "heredity_experiments",
      "plant_pathology_diagnosis"
    ],
    "requires_all": [
      "heredity_experiments",
      "plant_pathology_diagnosis"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Plant Resistance Trait Trials",
        "requires_all": []
      }
    ],
    "signals": [
      "food",
      "nature",
      "information"
    ],
    "observation": "Evaluate inherited plant responses to a defined naturally occurring stress under reviewed trials",
    "effects": {},
    "operating_contract": "Paid local crop cohorts, dated controlled observations and retained seed provenance support a bounded context-specific cultivation application; discovery alone grants no seed, evidence or harvest benefit."
  }
]
