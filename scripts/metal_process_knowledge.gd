extends RefCounted
## Paid metal processing, joining and qualified downstream assemblies.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "metal_annealing_control",
    "name": "Metal Annealing Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "hardened_edges"
    ],
    "requires_all": [
      "hardened_edges"
    ],
    "requires_any": [
      [
        "precision_thermometry",
        "kiln_control"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Metal Annealing Control",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Relate controlled thermal treatment to measured metal hardness and workability. Suitable metal, heating equipment, skilled handling and property checks.",
    "effects": {},
    "production_items": [
      "annealed_copper"
    ],
    "production_contract": "Paid workshop processes consume metal, fuel, water, tooling and finite work. Annealed wire, case-hardened gears, cast/brazed vessel parts and welded panels feed existing motors, generators and carts. Continuous casting prepares steel for subsequent rolling; it does not refine ore. Arc and spot welding require real shared electricity, and their panels have different qualified uses. Compatible imported parts can be used without manufacture mastery; quantities are game balances, not industrial certification."
  },
  {
    "id": "surface_carburization",
    "name": "Surface Carburization",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "hardened_edges",
      "charcoal"
    ],
    "requires_all": [
      "hardened_edges",
      "charcoal"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Surface Carburization",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Enrich a suitable metal surface with carbon through a qualified thermal process. Compatible metal, controlled carbon source, thermal equipment and case assessment.",
    "effects": {},
    "production_items": ["case_hardened_edges"],
    "production_contract": "Paid workshop processes consume metal, fuel, water, tooling and finite work. Annealed wire, case-hardened gears, cast/brazed vessel parts and welded panels feed existing motors, generators and carts. Continuous casting prepares steel for subsequent rolling; it does not refine ore. Arc and spot welding require real shared electricity, and their panels have different qualified uses. Compatible imported parts can be used without manufacture mastery; quantities are game balances, not industrial certification."
  },
  {
    "id": "metal_casting_feed_design",
    "name": "Metal Casting Feed Design",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "copper_casting"
    ],
    "requires_all": [
      "copper_casting"
    ],
    "requires_any": [
      [
        "flow_continuity",
        "experimental_controls"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Metal Casting Feed Design",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Arrange mold filling and solidification feed paths for an evaluated casting. Suitable mold, melt, casting staff and defect inspection.",
    "effects": {},
    "production_items": [
      "fed_copper_castings"
    ],
    "production_contract": "Paid workshop processes consume metal, fuel, water, tooling and finite work. Annealed wire, case-hardened gears, cast/brazed vessel parts and welded panels feed existing motors, generators and carts. Continuous casting prepares steel for subsequent rolling; it does not refine ore. Arc and spot welding require real shared electricity, and their panels have different qualified uses. Compatible imported parts can be used without manufacture mastery; quantities are game balances, not industrial certification."
  },
  {
    "id": "brazed_joint_qualification",
    "name": "Brazed Joint Qualification",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "copper_casting"
    ],
    "requires_all": [
      "copper_casting"
    ],
    "requires_any": [
      [
        "forge_welding",
        "experimental_controls"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Brazed Joint Qualification",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Qualify a lower-melting filler joint between compatible surfaces without melting the base members. Suitable filler, surface preparation, heat source and inspection.",
    "effects": {},
    "production_items": [
      "brazed_steel_fittings"
    ],
    "production_contract": "Paid workshop processes consume metal, fuel, water, tooling and finite work. Annealed wire, case-hardened gears, cast/brazed vessel parts and welded panels feed existing motors, generators and carts. Continuous casting prepares steel for subsequent rolling; it does not refine ore. Arc and spot welding require real shared electricity, and their panels have different qualified uses. Compatible imported parts can be used without manufacture mastery; quantities are game balances, not industrial certification."
  },
  {
    "id": "arc_welding_processes",
    "name": "Arc Welding Processes",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "electrical_measurement"
    ],
    "requires_all": [
      "electrical_measurement"
    ],
    "requires_any": [
      [
        "electric_arc_furnaces",
        "electrical_generators"
      ],
      [
        "forge_welding"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Arc Welding Processes",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Use a controlled electrical arc to form a qualified metal joint. Compatible power source, consumables, shielding where required and skilled operators.",
    "effects": {},
    "production_items": [
      "arc_welded_panels"
    ],
    "production_contract": "Paid workshop processes consume metal, fuel, water, tooling and finite work. Annealed wire, case-hardened gears, cast/brazed vessel parts and welded panels feed existing motors, generators and carts. Continuous casting prepares steel for subsequent rolling; it does not refine ore. Arc and spot welding require real shared electricity, and their panels have different qualified uses. Compatible imported parts can be used without manufacture mastery; quantities are game balances, not industrial certification."
  },
  {
    "id": "resistance_welding",
    "name": "Resistance Welding",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "electrical_measurement"
    ],
    "requires_all": [
      "electrical_measurement"
    ],
    "requires_any": [
      [
        "forge_welding"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Resistance Welding",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Generate localized joining heat through controlled electrical resistance and force. Compatible equipment, joint surfaces, power and inspection.",
    "effects": {},
    "production_items": [
      "spot_welded_panels"
    ],
    "production_contract": "Paid workshop processes consume metal, fuel, water, tooling and finite work. Annealed wire, case-hardened gears, cast/brazed vessel parts and welded panels feed existing motors, generators and carts. Continuous casting prepares steel for subsequent rolling; it does not refine ore. Arc and spot welding require real shared electricity, and their panels have different qualified uses. Compatible imported parts can be used without manufacture mastery; quantities are game balances, not industrial certification."
  },
  {
    "id": "continuous_metal_casting",
    "name": "Continuous Metal Casting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "steel_refining",
      "metal_casting_feed_design"
    ],
    "requires_all": [
      "steel_refining",
      "metal_casting_feed_design"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Continuous Metal Casting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Solidify a controlled metal stream into a continuously withdrawn shape. Qualified caster, cooling, melt supply and operators.",
    "effects": {},
    "production_items": [
      "continuous_steel_slabs"
    ],
    "production_contract": "Paid workshop processes consume metal, fuel, water, tooling and finite work. Annealed wire, case-hardened gears, cast/brazed vessel parts and welded panels feed existing motors, generators and carts. Continuous casting prepares steel for subsequent rolling; it does not refine ore. Arc and spot welding require real shared electricity, and their panels have different qualified uses. Compatible imported parts can be used without manufacture mastery; quantities are game balances, not industrial certification."
  }
]
