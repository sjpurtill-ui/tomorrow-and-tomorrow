extends RefCounted
## Role-specific teaching practices; not automatic soldier upgrades.
static func entries()->Array[Dictionary]:
	return [
	  {
	    "id": "skirmish_pair_drill",
	    "name": "Skirmish Pair Drill",
	    "direction": "Warfare",
	    "day": 650,
	    "chance": 0.002,
	    "requires": [
	      "bow_craft"
	    ],
	    "requires_all": [
	      "bow_craft"
	    ],
	    "requires_any": [
	      [
	        "formation_drill",
	        "oral_epics"
	      ]
	    ],
	    "signals": [
	      "warfare",
	      "crafting",
	      "information"
	    ],
	    "observation": "Partners practice alternating observation and movement so a dispersed screen can remain mutually supporting.",
	    "effects": {},
	    "training_profile": {
	      "skirmisher": 0.15,
	      "slinger": 0.15,
	      "javelineer": 0.15,
	      "light_infantry": 0.15
	    },
	    "production_contract": "Shortens newly scheduled training for the named roles as this teaching practice spreads. Existing orders, staffing, equipment and supply requirements remain authoritative.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Skirmish Pair Drill",
	        "requires_all": []
	      }
	    ]
	  },
	  {
	    "id": "mounted_remount_school",
	    "name": "Mounted Remount School",
	    "direction": "Warfare",
	    "day": 2200,
	    "chance": 0.002,
	    "requires": [
	      "domesticated_mounts",
	      "apprentice_contracts"
	    ],
	    "requires_all": [
	      "domesticated_mounts",
	      "apprentice_contracts"
	    ],
	    "requires_any": [],
	    "signals": [
	      "warfare",
	      "crafting",
	      "information"
	    ],
	    "observation": "Experienced handlers teach riders to change mounts, check tack and manage a working remount string.",
	    "effects": {},
	    "training_profile": {
	      "cavalry": 0.15,
	      "light_cavalry": 0.15,
	      "horse_archer": 0.15
	    },
	    "production_contract": "Shortens newly scheduled training for the named roles as this teaching practice spreads. Existing orders, staffing, equipment and supply requirements remain authoritative.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Mounted Remount School",
	        "requires_all": []
	      }
	    ]
	  },
	  {
	    "id": "siege_crew_rehearsals",
	    "name": "Siege Crew Rehearsals",
	    "direction": "Warfare",
	    "day": 4600,
	    "chance": 0.002,
	    "requires": [
	      "siege_engineering",
	      "standard_measures"
	    ],
	    "requires_all": [
	      "siege_engineering",
	      "standard_measures"
	    ],
	    "requires_any": [],
	    "signals": [
	      "warfare",
	      "crafting",
	      "information"
	    ],
	    "observation": "Crews rehearse assembly, safe loading and coordinated operation before transporting engines into a siege.",
	    "effects": {},
	    "training_profile": {
	      "siege_engineer": 0.15,
	      "ram_crew": 0.15,
	      "catapult_crew": 0.15,
	      "trebuchet_crew": 0.15
	    },
	    "production_contract": "Shortens newly scheduled training for the named roles as this teaching practice spreads. Existing orders, staffing, equipment and supply requirements remain authoritative.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Siege Crew Rehearsals",
	        "requires_all": []
	      }
	    ]
	  },
	  {
	    "id": "mountain_field_school",
	    "name": "Mountain Field School",
	    "direction": "Warfare",
	    "day": 9200,
	    "chance": 0.002,
	    "requires": [
	      "route_memory"
	    ],
	    "requires_all": [
	      "route_memory"
	    ],
	    "requires_any": [
	      [
	        "military_staffs",
	        "professional_corps"
	      ]
	    ],
	    "signals": [
	      "warfare",
	      "crafting",
	      "information"
	    ],
	    "observation": "Instructors teach route selection, load distribution and group movement over steep broken ground.",
	    "effects": {},
	    "training_profile": {
	      "mountain_infantry": 0.15,
	      "light_infantry": 0.15
	    },
	    "production_contract": "Shortens newly scheduled training for the named roles as this teaching practice spreads. Existing orders, staffing, equipment and supply requirements remain authoritative.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Mountain Field School",
	        "requires_all": []
	      }
	    ]
	  },
	  {
	    "id": "range_estimation_drill",
	    "name": "Range Estimation Drill",
	    "direction": "Warfare",
	    "day": 18000,
	    "chance": 0.002,
	    "requires": [
	      "standard_measures"
	    ],
	    "requires_all": [
	      "standard_measures"
	    ],
	    "requires_any": [
	      [
	        "crossbow_mechanism",
	        "rifled_barrels"
	      ]
	    ],
	    "signals": [
	      "warfare",
	      "crafting",
	      "information"
	    ],
	    "observation": "Measured ranges and repeated observation teach shooters to estimate distance and correct their aim.",
	    "effects": {},
	    "training_profile": {
	      "crossbowman": 0.15,
	      "sharpshooter": 0.15,
	      "rifle_infantry": 0.15
	    },
	    "production_contract": "Shortens newly scheduled training for the named roles as this teaching practice spreads. Existing orders, staffing, equipment and supply requirements remain authoritative.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Range Estimation Drill",
	        "requires_all": []
	      }
	    ]
	  },
	  {
	    "id": "gun_detachment_school",
	    "name": "Gun Detachment School",
	    "direction": "Warfare",
	    "day": 26000,
	    "chance": 0.002,
	    "requires": [
	      "powder_artillery",
	      "workshop_standards"
	    ],
	    "requires_all": [
	      "powder_artillery",
	      "workshop_standards"
	    ],
	    "requires_any": [],
	    "signals": [
	      "warfare",
	      "crafting",
	      "information"
	    ],
	    "observation": "Gun detachments rehearse loading, laying and withdrawal with assigned duties and inspected equipment.",
	    "effects": {},
	    "training_profile": {
	      "field_artillery": 0.15,
	      "bombard_crew": 0.15,
	      "horse_artillery": 0.15
	    },
	    "production_contract": "Shortens newly scheduled training for the named roles as this teaching practice spreads. Existing orders, staffing, equipment and supply requirements remain authoritative.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Gun Detachment School",
	        "requires_all": []
	      }
	    ]
	  },
	  {
	    "id": "engineer_demonstration_ranges",
	    "name": "Engineer Demonstration Ranges",
	    "direction": "Warfare",
	    "day": 39000,
	    "chance": 0.002,
	    "requires": [
	      "siege_engineering",
	      "experimental_controls"
	    ],
	    "requires_all": [
	      "siege_engineering",
	      "experimental_controls"
	    ],
	    "requires_any": [
	      [
	        "professional_corps",
	        "military_staffs"
	      ]
	    ],
	    "signals": [
	      "warfare",
	      "crafting",
	      "information"
	    ],
	    "observation": "Instructors use controlled obstacles and repeated demonstrations to teach field engineering procedures.",
	    "effects": {},
	    "training_profile": {
	      "combat_engineer": 0.15,
	      "siege_engineer": 0.15
	    },
	    "production_contract": "Shortens newly scheduled training for the named roles as this teaching practice spreads. Existing orders, staffing, equipment and supply requirements remain authoritative.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Engineer Demonstration Ranges",
	        "requires_all": []
	      }
	    ]
	  },
	  {
	    "id": "mechanized_crew_school",
	    "name": "Mechanized Crew School",
	    "direction": "Warfare",
	    "day": 74000,
	    "chance": 0.002,
	    "requires": [
	      "armored_vehicles",
	      "workshop_standards",
	      "military_staffs"
	    ],
	    "requires_all": [
	      "armored_vehicles",
	      "workshop_standards",
	      "military_staffs"
	    ],
	    "requires_any": [],
	    "signals": [
	      "warfare",
	      "crafting",
	      "information"
	    ],
	    "observation": "Drivers, mechanics and commanders train together on servicing routines and coordinated vehicle movement.",
	    "effects": {},
	    "training_profile": {
	      "armored_formation": 0.15,
	      "motorized_infantry": 0.15
	    },
	    "production_contract": "Shortens newly scheduled training for the named roles as this teaching practice spreads. Existing orders, staffing, equipment and supply requirements remain authoritative.",
	    "learning_routes": [
	      {
	        "id": "local",
	        "label": "Mechanized Crew School",
	        "requires_all": []
	      }
	    ]
	  }
	]
