extends RefCounted
## Individually authored optical instrument-making capabilities.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "lens_centering",
    "name": "Lens Centering",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "optical_lenses",
      "experimental_optics"
    ],
    "requires_all": [
      "optical_lenses",
      "experimental_optics"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Lens Centering",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "crafting",
      "materials"
    ],
    "observation": "Lenses are seated around a common optical axis so an assembled instrument can retain its intended image.",
    "effects": {},
    "production_items": [
      "centered_lens_mount"
    ],
    "production_contract": "Manufactured optical components consume real stocks, tooling and shared Crafting work. A commissioned microscopy bench consumes slide supplies and operators to assist examination of returned physical specimens, not arbitrary cultural knowledge."
  },
  {
    "id": "eyepiece_design",
    "name": "Eyepiece Design",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lens_centering"
    ],
    "requires_all": [
      "lens_centering"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Eyepiece Design",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "crafting",
      "materials"
    ],
    "observation": "A second lens assembly presents the image formed by an objective to an observer.",
    "effects": {},
    "production_items": [
      "microscope_eyepiece"
    ],
    "production_contract": "Manufactured optical components consume real stocks, tooling and shared Crafting work. A commissioned microscopy bench consumes slide supplies and operators to assist examination of returned physical specimens, not arbitrary cultural knowledge."
  },
  {
    "id": "fine_focus_stages",
    "name": "Fine-Focus Stages",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "precision_machinery",
      "bearing_surfaces"
    ],
    "requires_all": [
      "precision_machinery",
      "bearing_surfaces"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Fine-Focus Stages",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "crafting",
      "materials"
    ],
    "observation": "A guided specimen platform can move through small controlled focus adjustments.",
    "effects": {},
    "production_items": [
      "focus_stage"
    ],
    "production_contract": "Manufactured optical components consume real stocks, tooling and shared Crafting work. A commissioned microscopy bench consumes slide supplies and operators to assist examination of returned physical specimens, not arbitrary cultural knowledge."
  },
  {
    "id": "illumination_apertures",
    "name": "Illumination Apertures",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "experimental_optics",
      "workshop_standards"
    ],
    "requires_all": [
      "experimental_optics",
      "workshop_standards"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Illumination Apertures",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "crafting",
      "materials"
    ],
    "observation": "Controlled openings and collecting optics regulate illumination reaching a specimen.",
    "effects": {},
    "production_items": [
      "microscope_illuminator"
    ],
    "production_contract": "Manufactured optical components consume real stocks, tooling and shared Crafting work. A commissioned microscopy bench consumes slide supplies and operators to assist examination of returned physical specimens, not arbitrary cultural knowledge."
  },
  {
    "id": "specimen_slide_mounting",
    "name": "Specimen Slide Mounting",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "glassmaking",
      "standard_measures"
    ],
    "requires_all": [
      "glassmaking",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Specimen Slide Mounting",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "crafting",
      "materials"
    ],
    "observation": "Flat transparent mounts support small samples in a repeatable viewing position.",
    "effects": {},
    "production_items": [
      "specimen_slides"
    ],
    "production_contract": "Manufactured optical components consume real stocks, tooling and shared Crafting work. A commissioned microscopy bench consumes slide supplies and operators to assist examination of returned physical specimens, not arbitrary cultural knowledge."
  },
  {
    "id": "compound_microscopy",
    "name": "Compound Microscopy",
    "direction": "Information",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "eyepiece_design",
      "fine_focus_stages",
      "illumination_apertures",
      "specimen_slide_mounting"
    ],
    "requires_all": [
      "eyepiece_design",
      "fine_focus_stages",
      "illumination_apertures",
      "specimen_slide_mounting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Compound Microscopy",
        "requires_all": []
      }
    ],
    "signals": [
      "research",
      "crafting",
      "materials"
    ],
    "observation": "An aligned objective, eyepiece, stage and illumination system reveal structure in prepared small specimens.",
    "effects": {},
    "production_items": [
      "compound_microscope"
    ],
    "production_contract": "Manufactured optical components consume real stocks, tooling and shared Crafting work. A commissioned microscopy bench consumes slide supplies and operators to assist examination of returned physical specimens, not arbitrary cultural knowledge.",
    "operating_plants": [
      "microscopy_bench"
    ]
  }
]
