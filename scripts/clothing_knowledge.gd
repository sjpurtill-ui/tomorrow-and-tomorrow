extends RefCounted
const METHODS := {
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
  }
}

static func entries()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for id:String in METHODS:
		var spec:Dictionary=METHODS[id]
		result.append({"id":id,"name":spec.name,"direction":"Materials","day":0,"chance":.002,"requires":spec.requires_all.duplicate(),"requires_all":spec.requires_all.duplicate(),"requires_any":spec.requires_any.duplicate(true),"learning_routes":[{"id":"local","label":spec.name,"requires_all":[]}],"signals":["crafting","research"],"observation":spec.observation,"effects":{},"clothing_method":id,"production_contract":"Paid equipment, actual yarn or cloth, and shared Logistics work create knitted garments or woven wraps. Issued stocks wear; only their supplied condition and coverage reduce cold and storm exposure. Layering needs two garments; laundering uses water and drying time; moisture trials consume lining cloth and water."})
	return result
