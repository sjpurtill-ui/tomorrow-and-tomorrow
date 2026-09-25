extends RefCounted
## Existing authored predicates; capabilities require paid physical consumers.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "bow_drill_drive",
    "name": "Bow-Drill Drive",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "cordage",
      "hafted_tools"
    ],
    "requires_all": [
      "cordage",
      "hafted_tools"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Bow-Drill Drive",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "research"
    ],
    "observation": "Convert reciprocating hand motion into controlled tool rotation",
    "effects": {},
    "production_items": [
      "bow_drill_sets"
    ],
    "production_contract": "Make bow-drill equipment with real cord, spindle and cutting material. Paid installed drills bore axle boxes that enter existing cart assembly; imported drill sets enable use without teaching their manufacture."
  },
  {
    "id": "treadle_lathe_drive",
    "name": "Treadle-Lathe Drive",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "bearing_surfaces",
      "crank_linkages"
    ],
    "requires_all": [
      "bearing_surfaces",
      "crank_linkages"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Treadle-Lathe Drive",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "research"
    ],
    "observation": "Supply controlled rotary work from a foot-operated mechanism",
    "effects": {},
    "production_items": [
      "treadle_lathes"
    ],
    "production_contract": "Pay for a foot-operated lathe frame and workholding, then spend manual workshop labor turning wooden axles for real carts. No electricity is created; the society-wide effect is a small era-scaled contribution, not a direct workshop bonus."
  },
  {
    "id": "water_powered_hammers",
    "name": "Water-Powered Hammers",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "water_mills",
      "crank_linkages"
    ],
    "requires_all": [
      "water_mills",
      "crank_linkages"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Water-Powered Hammers",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "research"
    ],
    "observation": "Drive repeated forging or processing blows from available water power",
    "effects": {},
    "production_items": [
      "water_hammer_drives"
    ],
    "production_contract": "Make and commission a maintained wheel-and-hammer assembly at a pinned revealed river site. Finite local hammer work drives forging only while source access, seasonal water availability, operators and replacement parts permit.",
    "operating_plants": [
      "water_hammer"
    ]
  },
  {
    "id": "mechanical_screw_presses",
    "name": "Mechanical Screw Presses",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "gear_ratios",
      "joinery"
    ],
    "requires_all": [
      "gear_ratios",
      "joinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Mechanical Screw Presses",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "research"
    ],
    "observation": "Apply controlled force through a qualified screw mechanism",
    "effects": {},
    "production_items": [
      "mechanical_screw_presses"
    ],
    "production_contract": "Make a fitted screw and frame, then use the installed press in paid paper dewatering and printing. Actual paper pulp, printing forms, ink and work remain necessary."
  },
  {
    "id": "cam_motion_design",
    "name": "Cam-Motion Design",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "measured_kinematics",
      "crank_linkages"
    ],
    "requires_all": [
      "measured_kinematics",
      "crank_linkages"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Cam-Motion Design",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "research"
    ],
    "observation": "Shape a rotating or sliding profile to generate declared follower motion",
    "effects": {},
    "production_items": [
      "cam_follower_sets"
    ],
    "production_contract": "Make a trial-fitted cam and follower assembly. Installed followers guide repeated paper pressing only with an actual electric motor and per-batch electricity; the manual press remains available."
  },
  {
    "id": "belt_power_transmission",
    "name": "Belt-Power Transmission",
    "direction": "Materials",
    "day": 0,
    "chance": 0.0025,
    "requires": [
      "fiber_grading",
      "bearing_surfaces"
    ],
    "requires_all": [
      "fiber_grading",
      "bearing_surfaces"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Belt-Power Transmission",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "research"
    ],
    "observation": "Transfer shaft work through a tensioned flexible drive",
    "effects": {},
    "production_items": [
      "woven_drive_belts",
      "belt_drive_sets"
    ],
    "production_contract": "Manufacture woven belts and aligned pulley assemblies. A commissioned belt-driven workshop consumes real electric drive, operators and replacement belts before providing bounded mechanical assistance.",
    "operating_plants": [
      "belt_workshop"
    ]
  }
]
