extends RefCounted
## Authored recessed-image methods and a separate rolling impression route.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "copperplate_preparation",
    "name": "Copperplate Preparation",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "copper_smelting",
      "standard_measures"
    ],
    "requires_all": [
      "copper_smelting",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Copperplate Preparation",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Hammering, flattening and polishing copper produces a smooth plate that can carry a reproducible recessed image.",
    "effects": {},
    "production_items": [
      "prepared_copperplates"
    ],
    "production_contract": "Staffed workshop lines consume actual metal, paper, ink and tooling. Plate stocks have method-specific wear and remain distinct from relief forms; completed impressions enter the existing finite Printed Sheets study supply. No automatic research or free materials."
  },
  {
    "id": "burin_engraving",
    "name": "Burin Engraving",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "copperplate_preparation",
      "printing_process"
    ],
    "requires_all": [
      "copperplate_preparation",
      "printing_process"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Burin Engraving",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A controlled cutting tool removes narrow metal shavings to leave recessed lines that retain ink.",
    "effects": {},
    "production_items": [
      "burin_engraved_plates"
    ],
    "production_contract": "Staffed workshop lines consume actual metal, paper, ink and tooling. Plate stocks have method-specific wear and remain distinct from relief forms; completed impressions enter the existing finite Printed Sheets study supply. No automatic research or free materials."
  },
  {
    "id": "drypoint_printmaking",
    "name": "Drypoint Printmaking",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "copperplate_preparation",
      "printing_process"
    ],
    "requires_all": [
      "copperplate_preparation",
      "printing_process"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Drypoint Printmaking",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A pointed tool scratches a plate and leaves raised burrs beside the furrows; both hold ink for a soft-edged impression.",
    "effects": {},
    "production_items": [
      "drypoint_plates"
    ],
    "production_contract": "Staffed workshop lines consume actual metal, paper, ink and tooling. Plate stocks have method-specific wear and remain distinct from relief forms; completed impressions enter the existing finite Printed Sheets study supply. No automatic research or free materials."
  },
  {
    "id": "mezzotint_printmaking",
    "name": "Mezzotint Printmaking",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "copperplate_preparation",
      "printing_process"
    ],
    "requires_all": [
      "copperplate_preparation",
      "printing_process"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Mezzotint Printmaking",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A serrated rocker roughens the plate; selective scraping and burnishing reduce retained ink to build tonal images.",
    "effects": {},
    "production_items": [
      "mezzotint_plates"
    ],
    "production_contract": "Staffed workshop lines consume actual metal, paper, ink and tooling. Plate stocks have method-specific wear and remain distinct from relief forms; completed impressions enter the existing finite Printed Sheets study supply. No automatic research or free materials."
  },
  {
    "id": "steelplate_engraving",
    "name": "Steelplate Engraving",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "burin_engraving",
      "steel_refining"
    ],
    "requires_all": [
      "burin_engraving",
      "steel_refining"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Steelplate Engraving",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Engravers adapt controlled cutting to steel plates, providing another metal supply route for recessed printing images.",
    "effects": {},
    "production_items": ["steel_engraved_plates", "steel_intaglio_sheets"],
    "production_contract": "Staffed workshop lines consume actual metal, paper, ink and tooling. Plate stocks have method-specific wear and remain distinct from relief forms; completed impressions enter the existing finite Printed Sheets study supply. No automatic research or free materials."
  },
  {
    "id": "rolling_intaglio_printing",
    "name": "Rolling Intaglio Printing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "paper_making",
      "oil_based_printing_inks",
      "bearing_surfaces"
    ],
    "requires_all": [
      "paper_making",
      "oil_based_printing_inks",
      "bearing_surfaces"
    ],
    "requires_any": [
      [
        "burin_engraving",
        "drypoint_printmaking",
        "mezzotint_printmaking",
        "steelplate_engraving"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Rolling Intaglio Printing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A rolling press forces damp paper against an inked, wiped plate, drawing ink out of recesses.",
    "effects": {},
    "production_items": ["intaglio_sheets", "drypoint_sheets", "mezzotint_sheets"],
    "production_contract": "Staffed workshop lines consume actual metal, paper, ink and tooling. Plate stocks have method-specific wear and remain distinct from relief forms; completed impressions enter the existing finite Printed Sheets study supply. No automatic research or free materials."
  }
]
