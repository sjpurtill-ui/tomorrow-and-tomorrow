extends RefCounted
const METHODS := {
  "leather_goods_patterning": {
  "name": "Leather-Goods Patterning",
  "requires_all": [
    "hide_tanning",
    "garment_pattern_cutting"
  ],
  "requires_any": [],
  "rate": 1.5,
  "cost": {
    "Stone": 2,
    "Timber": 3,
    "Recovered Bone": 0.1,
    "Flexible Leather": 0.2
  },
  "inputs": {
    "Flexible Leather": 0.65,
    "Spun Yarn": 0.1
  },
  "mode": "leather",
  "observation": "Cut and fit compatible flexible leather into sewn outer garments; repair worn pieces with leather patches.",
  "production_contract": "Paid fitting tools, flexible leather, thread and shared Logistics work create bounded garment lots. Actual issued condition affects coverage; wet exposure increases wear. Textile washing, wicking and cloth repairs do not service leather. Compatible patch repairs consume leather and thread without creating garments. Imported finished leather does not grant tanning mastery."
},
  "knitted_loop_fabrics": {
    "name": "Knitted-Loop Fabrics",
    "requires_all": [
      "drop_spindles"
    ],
    "requires_any": [
      [
        "cordage"
      ]
    ],
    "rate": 2,
    "cost": {
      "Timber": 2,
      "Stone": 1
    },
    "inputs": {
      "Spun Yarn": 1
    },
    "mode": "knit",
    "observation": "Build a fabric from intermeshed yarn loops. Suitable yarn, tools and skilled work"
  },
  "twill_weave_structures": {
    "name": "Twill-Weave Structures",
    "requires_all": [
      "plain_weaving"
    ],
    "requires_any": [],
    "rate": 3,
    "cost": {
      "Loom Weights": 2,
      "Timber": 4
    },
    "inputs": {
      "Spun Yarn": 1.2
    },
    "mode": "twill",
    "observation": "Arrange interlacings in repeated offset sequences. Suitable loom, yarn and practiced weaver"
  },
  "pile_fabric_weaving": {
    "name": "Pile-Fabric Weaving",
    "requires_all": [
      "plain_weaving"
    ],
    "requires_any": [],
    "rate": 2,
    "cost": {
      "Loom Weights": 3,
      "Timber": 5
    },
    "inputs": {
      "Spun Yarn": 1.6
    },
    "mode": "pile",
    "observation": "Form raised loops or cut surfaces over a supporting woven ground. Compatible yarn, loom arrangement and finishing"
  },
  "layered_clothing_design": {
    "name": "Layered-Clothing Design",
    "requires_all": [
      "fiber_grading",
      "seasonal_patterns"
    ],
    "requires_any": [],
    "rate": 8,
    "cost": {
      "Timber": 2
    },
    "inputs": {},
    "mode": "layer",
    "observation": "Arrange worn materials around observed thermal, moisture and movement needs. Suitable clothing, fit and actual wearing conditions"
  },
  "mechanical_washing_machines": {
    "name": "Mechanical Washing Machines",
    "requires_all": [
        "textile_laundering_practice",
        "crank_linkages",
        "electric_motors"
    ],
    "requires_any": [],
    "rate": 24.0,
    "cost": {
        "Electric Motors": 1,
        "Wrought Iron": 3,
        "Timber": 4
    },
    "inputs": {
        "Freshwater": 0.3,
        "Laundry Soap": 0.02
    },
    "power": 0.05,
    "mode": "machine_wash",
    "observation": "A supplied motor drives a washing vessel; water, cleaning agent and operators remain necessary.",
    "production_contract": "The implemented electrical appliance consumes generated electricity, manufactured laundry soap, water and Logistics work. Daily installed capacity is shared across lots. Wet garments remain unavailable until the following day and mechanical washing causes a small condition loss. Human and water drives remain future alternatives."
},
  "textile_laundering_practice": {
    "name": "Textile-Laundering Practice",
    "requires_all": [
      "clean_water",
      "fiber_grading"
    ],
    "requires_any": [],
    "rate": 12,
    "cost": {
      "Clay": 3,
      "Timber": 2
    },
    "inputs": {
      "Freshwater": 0.8
    },
    "mode": "wash",
    "observation": "Clean selected textiles while respecting material and contamination conditions. Usable water, labor, suitable agents where needed and drying access"
  },
  "textile_moisture_transport": {
    "name": "Textile Moisture Transport",
    "requires_all": [
      "fiber_grading",
      "experimental_controls"
    ],
    "requires_any": [],
    "rate": 6,
    "cost": {
      "Woven Cloth": 1,
      "Clay": 2
    },
    "inputs": {
      "Freshwater": 0.2,
      "Woven Cloth": 0.08
    },
    "mode": "wick",
    "observation": "Characterize and shape movement of moisture through a textile assembly. Suitable fibers, structures and representative tests"
  },
  "bone_needle_sewing": {
    "name": "Bone-Needle Sewing",
    "requires_all": [
      "hafted_tools",
      "cordage"
    ],
    "requires_any": [],
    "rate": 2,
    "cost": {
      "Recovered Bone": 0.1,
      "Stone": 1,
      "Timber": 1
    },
    "inputs": {
      "Woven Cloth": 0.7,
      "Spun Yarn": 0.1
    },
    "mode": "sew",
    "observation": "Join suitable flexible material using a prepared needle and thread. Needles, thread, material and practiced hands",
    "production_contract": "Actual post-siege hunting harvest supplies bounded recovered bone for paid needles. Cloth and yarn are consumed to sew garments; cutting templates reduce cloth offcuts, and graded patterns support repeated fitted work. Repairs consume compatible cloth, yarn and shared Logistics time to restore the treated share of existing garment condition, never new garment quantity. Supply, equipment and daily quotas constrain operation."
  },
  "garment_pattern_cutting": {
    "name": "Garment-Pattern Cutting",
    "requires_all": [
      "bone_needle_sewing",
      "standard_measures"
    ],
    "requires_any": [],
    "rate": 1.5,
    "cost": {
      "Timber": 2,
      "Stone": 1,
      "Woven Cloth": 1,
      "Recovered Bone": 0.1
    },
    "inputs": {
      "Woven Cloth": 0.55,
      "Spun Yarn": 0.1
    },
    "mode": "fit",
    "observation": "Translate a declared fit into cut pieces and assembly references. Suitable material, measurements, tools and skilled fitting",
    "production_contract": "Actual post-siege hunting harvest supplies bounded recovered bone for paid needles. Cloth and yarn are consumed to sew garments; cutting templates reduce cloth offcuts, and graded patterns support repeated fitted work. Repairs consume compatible cloth, yarn and shared Logistics time to restore the treated share of existing garment condition, never new garment quantity. Supply, equipment and daily quotas constrain operation."
  },
  "garment_size_grading": {
    "name": "Garment-Size Grading",
    "requires_all": [
      "garment_pattern_cutting",
      "statistical_sampling"
    ],
    "requires_any": [],
    "rate": 2.5,
    "cost": {
      "Timber": 2,
      "Paper": 3,
      "Woven Cloth": 1,
      "Recovered Bone": 0.1
    },
    "inputs": {
      "Woven Cloth": 0.55,
      "Spun Yarn": 0.1,
      "Paper": 0.01
    },
    "mode": "grade",
    "observation": "Develop a declared family of garment dimensions from representative body evidence. Measurements, pattern expertise and fit trials",
    "production_contract": "Actual post-siege hunting harvest supplies bounded recovered bone for paid needles. Cloth and yarn are consumed to sew garments; cutting templates reduce cloth offcuts, and graded patterns support repeated fitted work. Repairs consume compatible cloth, yarn and shared Logistics time to restore the treated share of existing garment condition, never new garment quantity. Supply, equipment and daily quotas constrain operation."
  },
  "textile_repair_methods": {
    "name": "Textile Repair Methods",
    "requires_all": [
      "bone_needle_sewing",
      "fiber_grading"
    ],
    "requires_any": [],
    "rate": 8,
    "cost": {
      "Timber": 1,
      "Recovered Bone": 0.05
    },
    "inputs": {
      "Woven Cloth": 0.08,
      "Spun Yarn": 0.03
    },
    "mode": "repair",
    "observation": "Restore selected damaged textile structures through compatible repair. Suitable material, tools and practiced workers",
    "production_contract": "Actual post-siege hunting harvest supplies bounded recovered bone for paid needles. Cloth and yarn are consumed to sew garments; cutting templates reduce cloth offcuts, and graded patterns support repeated fitted work. Repairs consume compatible cloth, yarn and shared Logistics time to restore the treated share of existing garment condition, never new garment quantity. Supply, equipment and daily quotas constrain operation."
  },
  "textile_durability_testing": {
    "name": "Textile Durability Testing",
    "requires_all": [
        "textile_repair_methods",
        "measurement_uncertainty"
    ],
    "requires_any": [],
    "rate": 2.0,
    "cost": {
        "Timber": 2,
        "Stone": 2,
        "Paper": 2
    },
    "inputs": {
        "Freshwater": 0.1,
        "Paper": 0.02
    },
    "mode": "test",
    "observation": "Removed garment samples undergo five dated paid wear-and-wash cycles; their observed condition is recorded separately from issued stock.",
    "production_contract": "A quarter-garment sample is removed from usable inventory for five daily test cycles. Each cycle needs installed equipment, water, paper and shared Logistics time. Recorded condition loss describes this game test only; no garment, repair or global durability bonus is created."
}
}

static func entries()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for id:String in METHODS:
		var spec:Dictionary=METHODS[id]
		result.append({"id":id,"name":spec.name,"direction":"Materials","day":0,"chance":.002,"requires":spec.requires_all.duplicate(),"requires_all":spec.requires_all.duplicate(),"requires_any":spec.requires_any.duplicate(true),"learning_routes":[{"id":"local","label":spec.name,"requires_all":[]}],"signals":["crafting","research"],"observation":spec.observation,"effects":{},"clothing_method":id,"production_contract":spec.get("production_contract","Paid equipment, actual yarn or cloth, and shared Logistics work create knitted garments or woven wraps. Issued stocks wear; only their supplied condition and coverage reduce cold and storm exposure. Layering needs two garments; laundering uses water and drying time; moisture trials consume lining cloth and water.")})
	return result
