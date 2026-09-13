extends RefCounted
## Authored predicates with documented plate-fitting causal correction.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "shield_equipment_fitting",
    "name": "Shield-Equipment Fitting",
    "direction": "Warfare",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "shield_wall",
      "timber_grading"
    ],
    "requires_all": [
      "shield_wall",
      "timber_grading"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Shield-Equipment Fitting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "security",
      "research"
    ],
    "observation": "Match shield shape, grip and carrying arrangements to the user's formation role",
    "effects": {},
    "production_items": [
      "fitted_shields"
    ],
    "production_contract": "Manufacture a fitted shield with selected wood, binding and covering; pay assembly and carrying-fit work. Complete spear-and-shield equipment must enter inventory and be issued to infantry before its coverage contributes to defense."
  },
  {
    "id": "textile_armor_layering",
    "name": "Textile Armor Layering",
    "direction": "Warfare",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "plain_weaving",
      "shield_equipment_fitting"
    ],
    "requires_all": [
      "plain_weaving",
      "shield_equipment_fitting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Textile Armor Layering",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "security",
      "research"
    ],
    "observation": "Qualify layered textile protection against defined equipment and environmental conditions",
    "effects": {},
    "production_items": [
      "padded_armor"
    ],
    "production_contract": "Manufacture Padded Armor with paid local material, fitted assembly and workshop labor; assemble complete spear equipment for existing infantry. Protection applies only to issued equipment, is reduced by enemy penetration, and grants no knowledge-only force bonus. Suitable cloth, assembly labor and inspection."
  },
  {
    "id": "lamellar_armor_assembly",
    "name": "Lamellar-Armor Assembly",
    "direction": "Warfare",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "cordage"
    ],
    "requires_all": [
      "cordage"
    ],
    "requires_any": [
      [
        "bronze_alloying",
        "hardened_edges"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Lamellar-Armor Assembly",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "security",
      "research"
    ],
    "observation": "Join overlapping protective elements into a wearable articulated assembly",
    "effects": {},
    "production_items": [
      "lamellar_armor"
    ],
    "production_contract": "Manufacture Lamellar Armor with paid local material, fitted assembly and workshop labor; assemble complete spear equipment for existing infantry. Protection applies only to issued equipment, is reduced by enemy penetration, and grants no knowledge-only force bonus. Qualified plates, fastening materials, makers and fit assessment."
  },
  {
    "id": "scale_armor_attachment",
    "name": "Scale Armor Attachment",
    "direction": "Warfare",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "plain_weaving"
    ],
    "requires_all": [
      "plain_weaving"
    ],
    "requires_any": [
      [
        "lamellar_armor_assembly",
        "shield_equipment_fitting"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Scale Armor Attachment",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "security",
      "research"
    ],
    "observation": "Attach overlapping protective elements to a qualified backing while retaining intended flexibility",
    "effects": {},
    "production_items": [
      "scale_armor"
    ],
    "production_contract": "Manufacture Scale Armor with paid local material, fitted assembly and workshop labor; assemble complete spear equipment for existing infantry. Protection applies only to issued equipment, is reduced by enemy penetration, and grants no knowledge-only force bonus. Compatible scales, backing, fastenings and armorers."
  },
  {
    "id": "mail_armor_fabrication",
    "name": "Mail-Armor Fabrication",
    "direction": "Warfare",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "wire_drawing",
      "hardened_edges"
    ],
    "requires_all": [
      "wire_drawing",
      "hardened_edges"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Mail-Armor Fabrication",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "security",
      "research"
    ],
    "observation": "Make a flexible protective mesh from joined metal elements",
    "effects": {},
    "production_items": [
      "mail_armor"
    ],
    "production_contract": "Manufacture Mail Armor with paid local material, fitted assembly and workshop labor; assemble complete spear equipment for existing infantry. Protection applies only to issued equipment, is reduced by enemy penetration, and grants no knowledge-only force bonus. Skilled makers, suitable metal, inspection and repair labor."
  },
  {
    "id": "articulated_plate_armor",
    "name": "Articulated Plate Armor",
    "direction": "Warfare",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "hardened_edges",
      "standard_measures"
    ],
    "requires_all": [
      "hardened_edges",
      "standard_measures"
    ],
    "requires_any": [
      [
        "sheet_steel_rolling",
        "structural_load_testing"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Articulated Plate Armor",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "security",
      "research"
    ],
    "observation": "Fit shaped protective plates so joints retain useful movement",
    "effects": {},
    "production_items": [
      "forged_plate_armor",
      "sheet_plate_armor"
    ],
    "production_contract": "Manufacture Fitted Plate Armor with paid local material, fitted assembly and workshop labor; assemble complete spear equipment for existing infantry. Protection applies only to issued equipment, is reduced by enemy penetration, and grants no knowledge-only force bonus. Forming capability, tailored fitting, attendants and maintenance."
  }
]
