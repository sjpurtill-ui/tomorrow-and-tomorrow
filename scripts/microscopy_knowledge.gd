extends RefCounted
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "laboratory_notebooks",
    "name": "Laboratory Notebooks",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "formal_archives",
      "experimental_controls"
    ],
    "requires_all": [
      "formal_archives",
      "experimental_controls"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Laboratory Notebooks",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "nature",
      "information"
    ],
    "observation": "Record methods, observations, deviations and dates while work occurs",
    "effects": {},
    "operating_contract": "Finite local culture and field specimens, paid instruments and controlled dated observations qualify specific starter or crop evidence; no species identification, free material or automatic benefit."
  },
  {
    "id": "experimental_protocol_publication",
    "name": "Experimental Protocol Publication",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "laboratory_notebooks",
      "printing_process"
    ],
    "requires_all": [
      "laboratory_notebooks",
      "printing_process"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Experimental Protocol Publication",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "nature",
      "information"
    ],
    "observation": "Publish enough method detail for another group to attempt reproduction",
    "effects": {},
    "operating_contract": "Finite local culture and field specimens, paid instruments and controlled dated observations qualify specific starter or crop evidence; no species identification, free material or automatic benefit."
  },
  {
    "id": "microscopic_cell_observation",
    "name": "Microscopic Cell Observation",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "compound_microscopy",
      "specimen_slide_mounting"
    ],
    "requires_all": [
      "compound_microscopy",
      "specimen_slide_mounting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Microscopic Cell Observation",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "nature",
      "information"
    ],
    "observation": "Observe recurring small structures in suitable biological preparations",
    "effects": {},
    "operating_contract": "Finite local culture and field specimens, paid instruments and controlled dated observations qualify specific starter or crop evidence; no species identification, free material or automatic benefit."
  },
  {
    "id": "cell_theory",
    "name": "Cell Theory",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "microscopic_cell_observation",
      "comparative_anatomy"
    ],
    "requires_all": [
      "microscopic_cell_observation",
      "comparative_anatomy"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Cell Theory",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "nature",
      "information"
    ],
    "observation": "Relate organism structure and growth to cells and their continuity",
    "effects": {},
    "operating_contract": "Finite local culture and field specimens, paid instruments and controlled dated observations qualify specific starter or crop evidence; no species identification, free material or automatic benefit."
  },
  {
    "id": "cell_division_observation",
    "name": "Cell-Division Observation",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "microscopic_cell_observation",
      "experimental_controls"
    ],
    "requires_all": [
      "microscopic_cell_observation",
      "experimental_controls"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Cell-Division Observation",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "nature",
      "information"
    ],
    "observation": "Compare successive cellular states during growth and reproduction",
    "effects": {},
    "operating_contract": "Finite local culture and field specimens, paid instruments and controlled dated observations qualify specific starter or crop evidence; no species identification, free material or automatic benefit."
  },
  {
    "id": "tissue_histology",
    "name": "Tissue Histology",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "cell_theory",
      "specimen_slide_mounting"
    ],
    "requires_all": [
      "cell_theory",
      "specimen_slide_mounting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Tissue Histology",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "nature",
      "information"
    ],
    "observation": "Compare organized cellular patterns within different tissues",
    "effects": {},
    "operating_contract": "Finite local culture and field specimens, paid instruments and controlled dated observations qualify specific starter or crop evidence; no species identification, free material or automatic benefit."
  },
  {
    "id": "biological_staining",
    "name": "Biological Staining",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "microscopic_cell_observation",
      "chemical_distillation"
    ],
    "requires_all": [
      "microscopic_cell_observation",
      "chemical_distillation"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Biological Staining",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "nature",
      "information"
    ],
    "observation": "Use selective contrast to distinguish structures in biological preparations",
    "effects": {},
    "operating_contract": "Finite local culture and field specimens, paid instruments and controlled dated observations qualify specific starter or crop evidence; no species identification, free material or automatic benefit."
  },
  {
    "id": "microbial_observation",
    "name": "Microbial Observation",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "compound_microscopy"
    ],
    "requires_all": [
      "compound_microscopy"
    ],
    "requires_any": [
      [
        "fermentation_control",
        "clean_water"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Microbial Observation",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "nature",
      "information"
    ],
    "observation": "Observe microscopic organisms associated with changing biological materials",
    "effects": {},
    "operating_contract": "Finite local culture and field specimens, paid instruments and controlled dated observations qualify specific starter or crop evidence; no species identification, free material or automatic benefit."
  },
  {
    "id": "microbial_isolation_methods",
    "name": "Microbial Isolation Methods",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "microbial_observation",
      "experimental_controls"
    ],
    "requires_all": [
      "microbial_observation",
      "experimental_controls"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Microbial Isolation Methods",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "nature",
      "information"
    ],
    "observation": "Separate mixed biological observations into reproducible identified laboratory subjects",
    "effects": {},
    "operating_contract": "Finite local culture and field specimens, paid instruments and controlled dated observations qualify specific starter or crop evidence; no species identification, free material or automatic benefit."
  },
  {
    "id": "microbial_growth_measurement",
    "name": "Microbial Growth Measurement",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "microbial_isolation_methods",
      "statistical_sampling"
    ],
    "requires_all": [
      "microbial_isolation_methods",
      "statistical_sampling"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Microbial Growth Measurement",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "nature",
      "information"
    ],
    "observation": "Measure changes in an identified microbial population under declared conditions",
    "effects": {},
    "operating_contract": "Finite local culture and field specimens, paid instruments and controlled dated observations qualify specific starter or crop evidence; no species identification, free material or automatic benefit."
  },
  {
    "id": "aseptic_laboratory_practice",
    "name": "Aseptic Laboratory Practice",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "microbial_isolation_methods",
      "experimental_protocol_publication"
    ],
    "requires_all": [
      "microbial_isolation_methods",
      "experimental_protocol_publication"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Aseptic Laboratory Practice",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "nature",
      "information"
    ],
    "observation": "Maintain separation between intended biological material and contaminating sources",
    "effects": {},
    "operating_contract": "Finite local culture and field specimens, paid instruments and controlled dated observations qualify specific starter or crop evidence; no species identification, free material or automatic benefit."
  },
  {
    "id": "instrument_sterilization",
    "name": "Instrument Sterilization",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "precision_thermometry",
      "experimental_controls"
    ],
    "requires_all": [
      "precision_thermometry",
      "experimental_controls"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Instrument Sterilization",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "nature",
      "information"
    ],
    "observation": "Apply and verify a validated process for reusable clinical instruments",
    "effects": {},
    "operating_contract": "Finite local culture and field specimens, paid instruments and controlled dated observations qualify specific starter or crop evidence; no species identification, free material or automatic benefit."
  },
  {
    "id": "cell_culture_methods",
    "name": "Cell-Culture Methods",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "cell_theory",
      "aseptic_laboratory_practice"
    ],
    "requires_all": [
      "cell_theory",
      "aseptic_laboratory_practice"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Cell-Culture Methods",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "nature",
      "information"
    ],
    "observation": "Maintain defined cells outside their original tissue environment",
    "effects": {},
    "operating_contract": "Finite local culture and field specimens, paid instruments and controlled dated observations qualify specific starter or crop evidence; no species identification, free material or automatic benefit."
  },
  {
    "id": "live_cell_time_lapse",
    "name": "Live Cell Time Lapse",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "cell_culture_methods",
      "microscopic_cell_observation"
    ],
    "requires_all": [
      "cell_culture_methods",
      "microscopic_cell_observation"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Live Cell Time Lapse",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "nature",
      "information"
    ],
    "observation": "Record qualified living-cell changes over time while monitoring observation effects",
    "effects": {},
    "operating_contract": "Finite local culture and field specimens, paid instruments and controlled dated observations qualify specific starter or crop evidence; no species identification, free material or automatic benefit."
  }
]
