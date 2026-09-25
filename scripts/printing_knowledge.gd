extends RefCounted
## Authored material preparation, reusable forms and impression methods.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "seed_oil_pressing",
    "name": "Seed Oil Pressing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "seed_selection",
      "stone_sorting"
    ],
    "requires_all": [
      "seed_selection",
      "stone_sorting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Seed Oil Pressing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Pressure separates oil from collected oil-bearing seeds; the resulting oil can serve as a printing-ink vehicle.",
    "effects": {},
    "production_items": [
      "pressed_seed_oil"
    ],
    "production_contract": "Paid workshop lines manufacture ink ingredients, reusable printing forms and printed sheets from actual stocks. Printed sheets support collection examination through finite consumption; no knowledge, paper, equipment or electricity is created by discovery."
  },
  {
    "id": "lampblack_capture",
    "name": "Lampblack Capture",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "charcoal",
      "clay_shaping"
    ],
    "requires_all": [
      "charcoal",
      "clay_shaping"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Lampblack Capture",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Restricted combustion and cool collecting surfaces recover fine carbon soot for pigment.",
    "effects": {},
    "production_items": [
      "captured_lampblack"
    ],
    "production_contract": "Paid workshop lines manufacture ink ingredients, reusable printing forms and printed sheets from actual stocks. Printed sheets support collection examination through finite consumption; no knowledge, paper, equipment or electricity is created by discovery."
  },
  {
    "id": "oil_based_printing_inks",
    "name": "Oil-Based Printing Inks",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "seed_oil_pressing",
      "lampblack_capture"
    ],
    "requires_all": [
      "seed_oil_pressing",
      "lampblack_capture"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Oil-Based Printing Inks",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Fine carbon pigment is worked into a prepared drying-oil vehicle that transfers from a printing surface to paper.",
    "effects": {},
    "production_items": ["oil_printing_ink", "earth_pigment_ink"],
    "production_contract": "Paid workshop lines manufacture ink ingredients, reusable printing forms and printed sheets from actual stocks. Printed sheets support collection examination through finite consumption; no knowledge, paper, equipment or electricity is created by discovery."
  },
  {
    "id": "relief_block_cutting",
    "name": "Relief Block Cutting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "printing_process",
      "joinery"
    ],
    "requires_all": [
      "printing_process",
      "joinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Relief Block Cutting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Cutting away nonprinting areas leaves raised images and characters that can be inked repeatedly.",
    "effects": {},
    "production_items": [
      "carved_printing_blocks"
    ],
    "production_contract": "Paid workshop lines manufacture ink ingredients, reusable printing forms and printed sheets from actual stocks. Printed sheets support collection examination through finite consumption; no knowledge, paper, equipment or electricity is created by discovery."
  },
  {
    "id": "wooden_movable_type",
    "name": "Wooden Movable Type",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "printing_process",
      "joinery",
      "standard_measures"
    ],
    "requires_all": [
      "printing_process",
      "joinery",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Wooden Movable Type",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Individually cut wooden characters can be aligned, locked into a form and rearranged for another text.",
    "effects": {},
    "production_items": ["wood_type_forms", "composed_wood_type_forms"],
    "production_contract": "Paid workshop lines manufacture ink ingredients, reusable printing forms and printed sheets from actual stocks. Printed sheets support collection examination through finite consumption; no knowledge, paper, equipment or electricity is created by discovery."
  },
  {
    "id": "hand_relief_printing",
    "name": "Hand Relief Printing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "paper_making",
      "oil_based_printing_inks"
    ],
    "requires_all": [
      "paper_making",
      "oil_based_printing_inks"
    ],
    "requires_any": [
      [
        "relief_block_cutting",
        "wooden_movable_type"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Hand Relief Printing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Hand pressure transfers an inked relief onto successive sheets without a powered press.",
    "effects": {},
    "production_items": ["hand_printed_sheets", "ochre_relief_sheets"],
    "production_contract": "Paid workshop lines manufacture ink ingredients, reusable printing forms and printed sheets from actual stocks. Printed sheets support collection examination through finite consumption; no knowledge, paper, equipment or electricity is created by discovery."
  },
  {
    "id": "screw_press_printing",
    "name": "Screw-Press Printing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "hand_relief_printing",
      "paper_sheet_pressing",
      "workshop_standards"
    ],
    "requires_all": [
      "hand_relief_printing",
      "paper_sheet_pressing",
      "workshop_standards"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Screw-Press Printing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A screw-driven platen applies controlled pressure across a prepared printing form.",
    "effects": {},
    "production_items": [
      "screw_printed_sheets"
    ],
    "production_contract": "Paid workshop lines manufacture ink ingredients, reusable printing forms and printed sheets from actual stocks. Printed sheets support collection examination through finite consumption; no knowledge, paper, equipment or electricity is created by discovery."
  },
  {
    "id": "cylinder_press_printing",
    "name": "Cylinder-Press Printing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "screw_press_printing",
      "bearing_surfaces",
      "gear_ratios"
    ],
    "requires_all": [
      "screw_press_printing",
      "bearing_surfaces",
      "gear_ratios"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Cylinder-Press Printing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A turning pressure cylinder brings paper across an inked form in a controlled rolling impression.",
    "effects": {},
    "production_items": ["cylinder_printed_sheets"],
    "production_contract": "Paid workshop lines manufacture ink ingredients, reusable printing forms and printed sheets from actual stocks. Printed sheets support collection examination through finite consumption; no knowledge, paper, equipment or electricity is created by discovery."
  }
]
