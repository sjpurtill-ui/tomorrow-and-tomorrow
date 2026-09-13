extends RefCounted
## Physical drive manufacture and supplied workshop commissioning.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "mechanical_clutches",
    "name": "Mechanical Clutches",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "friction_measurement",
      "bearing_surfaces"
    ],
    "requires_all": [
      "friction_measurement",
      "bearing_surfaces"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Mechanical Clutches",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Connect or release transmitted mechanical power through a qualified interface. Compatible drive, clutch, controls and maintenance.",
    "effects": {},
    "production_items": [
      "friction_clutches"
    ],
    "production_contract": "Finite civilian batches consume metals and existing tooling to make compatible drive components. Aligned indexing drives and generated gears are paid into a commissioned motor workshop; operators, electricity and replacement bearings/chains are required before mechanical assistance exists. Individually generated and hobbed gears are alternative production routes. Imported finished parts remain usable without mastering their manufacture. Quantities and work are game tuning, not engineering certification."
  },
  {
    "id": "ratchet_motion_control",
    "name": "Ratchet-Motion Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "gear_ratios",
      "hardened_edges"
    ],
    "requires_all": [
      "gear_ratios",
      "hardened_edges"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Ratchet-Motion Control",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Permit indexed motion in a declared direction through a qualified locking arrangement. Suitable mechanism, load evidence and inspection.",
    "effects": {},
    "production_items": [
      "ratchet_indexers"
    ],
    "production_contract": "Finite civilian batches consume metals and existing tooling to make compatible drive components. Aligned indexing drives and generated gears are paid into a commissioned motor workshop; operators, electricity and replacement bearings/chains are required before mechanical assistance exists. Individually generated and hobbed gears are alternative production routes. Imported finished parts remain usable without mastering their manufacture. Quantities and work are game tuning, not engineering certification."
  },
  {
    "id": "chain_power_transmission",
    "name": "Chain-Power Transmission",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "forge_welding",
      "gear_ratios"
    ],
    "requires_all": [
      "forge_welding",
      "gear_ratios"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Chain-Power Transmission",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Transfer rotary work through a qualified linked chain and matching wheels. Compatible components, lubrication and guarded operation.",
    "effects": {},
    "production_items": [
      "drive_chains"
    ],
    "production_contract": "Finite civilian batches consume metals and existing tooling to make compatible drive components. Aligned indexing drives and generated gears are paid into a commissioned motor workshop; operators, electricity and replacement bearings/chains are required before mechanical assistance exists. Individually generated and hobbed gears are alternative production routes. Imported finished parts remain usable without mastering their manufacture. Quantities and work are game tuning, not engineering certification."
  },
  {
    "id": "rolling_element_bearings",
    "name": "Rolling-Element Bearings",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "dimensional_metrology",
      "hardened_edges"
    ],
    "requires_all": [
      "dimensional_metrology",
      "hardened_edges"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Rolling-Element Bearings",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Support relative motion through qualified rolling contacts. Accurate components, lubrication, seals and inspection.",
    "effects": {},
    "production_items": [
      "rolling_bearings"
    ],
    "production_contract": "Finite civilian batches consume metals and existing tooling to make compatible drive components. Aligned indexing drives and generated gears are paid into a commissioned motor workshop; operators, electricity and replacement bearings/chains are required before mechanical assistance exists. Individually generated and hobbed gears are alternative production routes. Imported finished parts remain usable without mastering their manufacture. Quantities and work are game tuning, not engineering certification."
  },
  {
    "id": "shaft_alignment_methods",
    "name": "Shaft-Alignment Methods",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "dimensional_metrology",
      "bearing_surfaces"
    ],
    "requires_all": [
      "dimensional_metrology",
      "bearing_surfaces"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Shaft-Alignment Methods",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Measure and adjust connected shaft geometry against operating requirements. References, instruments and accessible machinery.",
    "effects": {},
    "production_items": [
      "aligned_drive_assemblies"
    ],
    "production_contract": "Finite civilian batches consume metals and existing tooling to make compatible drive components. Aligned indexing drives and generated gears are paid into a commissioned motor workshop; operators, electricity and replacement bearings/chains are required before mechanical assistance exists. Individually generated and hobbed gears are alternative production routes. Imported finished parts remain usable without mastering their manufacture. Quantities and work are game tuning, not engineering certification.",
    "operating_plants": [
      "geared_workshop"
    ]
  },
  {
    "id": "gear_tooth_generation",
    "name": "Gear-Tooth Generation",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "gear_ratios",
      "dimensional_metrology"
    ],
    "requires_all": [
      "gear_ratios",
      "dimensional_metrology"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Gear-Tooth Generation",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Produce matching tooth profiles through controlled cutting or forming. Qualified tooling, workholding and inspection.",
    "effects": {},
    "production_items": [
      "generated_gear_sets"
    ],
    "production_contract": "Finite civilian batches consume metals and existing tooling to make compatible drive components. Aligned indexing drives and generated gears are paid into a commissioned motor workshop; operators, electricity and replacement bearings/chains are required before mechanical assistance exists. Individually generated and hobbed gears are alternative production routes. Imported finished parts remain usable without mastering their manufacture. Quantities and work are game tuning, not engineering certification."
  },
  {
    "id": "gear_hobbing",
    "name": "Gear Hobbing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "gear_tooth_generation",
      "milling_cutter_relief"
    ],
    "requires_all": [
      "gear_tooth_generation",
      "milling_cutter_relief"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Gear Hobbing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Generate compatible gear teeth through synchronized tool and work motion. Qualified hob, machine, setup and inspection.",
    "effects": {},
    "production_items": [
      "gear_hobs",
      "hobbed_gear_sets"
    ],
    "production_contract": "Finite civilian batches consume metals and existing tooling to make compatible drive components. Aligned indexing drives and generated gears are paid into a commissioned motor workshop; operators, electricity and replacement bearings/chains are required before mechanical assistance exists. Individually generated and hobbed gears are alternative production routes. Imported finished parts remain usable without mastering their manufacture. Quantities and work are game tuning, not engineering certification."
  }
]
