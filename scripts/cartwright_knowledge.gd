extends RefCounted
## Individually authored wheelwright and cart assembly practices.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "wheel_blank_jointing",
    "name": "Wheel Blank Jointing",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "joinery",
      "standard_measures"
    ],
    "requires_all": [
      "joinery",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Wheel Blank Jointing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "Joined and secured timber pieces form a broad blank from which a solid wheel can be cut.",
    "effects": {},
    "production_items": [
      "joined_wheel_blank"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  },
  {
    "id": "wheel_hub_boring",
    "name": "Wheel Hub Boring",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "joinery",
      "standard_measures"
    ],
    "requires_all": [
      "joinery",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Wheel Hub Boring",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "An accurately centered bore lets a wooden hub turn around its axle without excessive binding.",
    "effects": {},
    "production_items": [
      "bored_wheel_hubs"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  },
  {
    "id": "spoke_tenon_cutting",
    "name": "Spoke Tenon Cutting",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "joinery",
      "standard_measures"
    ],
    "requires_all": [
      "joinery",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Spoke Tenon Cutting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "Shaped spoke ends fit the hub and rim, transmitting loads through a wheel while leaving its center open.",
    "effects": {},
    "production_items": [
      "wheel_spokes"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  },
  {
    "id": "felloe_jointing",
    "name": "Felloe Jointing",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "joinery",
      "standard_measures"
    ],
    "requires_all": [
      "joinery",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Felloe Jointing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "Curved rim segments meet around the ends of the spokes to complete a continuous wheel perimeter.",
    "effects": {},
    "production_items": [
      "wheel_felloes"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  },
  {
    "id": "solid_wheel_assembly",
    "name": "Solid Wheel Assembly",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "wheel_blank_jointing",
      "wheel_hub_boring"
    ],
    "requires_all": [
      "wheel_blank_jointing",
      "wheel_hub_boring"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Solid Wheel Assembly",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "A matched pair of solid wheels joins broad wooden discs to bored hubs for a load-carrying cart.",
    "effects": {},
    "production_items": [
      "solid_wheel_pairs"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  },
  {
    "id": "spoked_wheel_assembly",
    "name": "Spoked Wheel Assembly",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "wheel_hub_boring",
      "spoke_tenon_cutting",
      "felloe_jointing"
    ],
    "requires_all": [
      "wheel_hub_boring",
      "spoke_tenon_cutting",
      "felloe_jointing"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Spoked Wheel Assembly",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "Hubs, spokes and curved rim segments are fitted into a pair of open wheels, using less timber than solid discs.",
    "effects": {},
    "production_items": [
      "spoked_wheel_pairs"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  },
  {
    "id": "iron_tyre_fitting",
    "name": "Iron Tyre Fitting",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "spoked_wheel_assembly",
      "forge_welding"
    ],
    "requires_all": [
      "spoked_wheel_assembly",
      "forge_welding"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Iron Tyre Fitting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "An iron hoop fitted around a wooden wheel binds its joints and supplies a wearing surface around the rim.",
    "effects": {},
    "production_items": [
      "iron_tired_wheels"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  },
  {
    "id": "wooden_axle_shaping",
    "name": "Wooden Axle Shaping",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "joinery",
      "standard_measures"
    ],
    "requires_all": [
      "joinery",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Wooden Axle Shaping",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "A straight axle is shaped with shoulders and wheel seats to carry the load while maintaining the spacing of its wheels.",
    "effects": {},
    "production_items": [
      "wooden_axles"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  },
  {
    "id": "wooden_axle_boxes",
    "name": "Wooden Axle Boxes",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "wooden_axle_shaping",
      "wheel_hub_boring"
    ],
    "requires_all": [
      "wooden_axle_shaping",
      "wheel_hub_boring"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Wooden Axle Boxes",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "Fitted bearing blocks support the moving axle connection and make its bearing surfaces replaceable.",
    "effects": {},
    "production_items": [
      "axle_boxes"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  },
  {
    "id": "axle_sleeve_fitting",
    "name": "Axle Sleeve Fitting",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "wooden_axle_boxes",
      "bearing_surfaces",
      "forge_welding"
    ],
    "requires_all": [
      "wooden_axle_boxes",
      "bearing_surfaces",
      "forge_welding"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Axle Sleeve Fitting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "Metal sleeves line a prepared bearing connection, separating its working surface from the surrounding wood.",
    "effects": {},
    "production_items": [
      "axle_sleeves"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  },
  {
    "id": "linchpin_retention",
    "name": "Linchpin Retention",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "wooden_axle_shaping",
      "joinery"
    ],
    "requires_all": [
      "wooden_axle_shaping",
      "joinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Linchpin Retention",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "Removable retaining pins secure the wheels at the axle ends while allowing a wheel to be removed for repair.",
    "effects": {},
    "production_items": [
      "cart_linchpins"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  },
  {
    "id": "cart_bed_framing",
    "name": "Cart Bed Framing",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "joinery",
      "treenail_fastening"
    ],
    "requires_all": [
      "joinery",
      "treenail_fastening"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Cart Bed Framing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "A braced load bed transfers cargo weight to its running gear without depending on a loose pile of boards.",
    "effects": {},
    "production_items": [
      "cart_beds"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  },
  {
    "id": "drawbar_fitting",
    "name": "Drawbar Fitting",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "joinery",
      "rope_laying"
    ],
    "requires_all": [
      "joinery",
      "rope_laying"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Drawbar Fitting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "A fitted drawbar carries pulling and steering loads from the hauling connection into the cart frame.",
    "effects": {},
    "production_items": [
      "cart_drawbars"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  },
  {
    "id": "haul_harness_weaving",
    "name": "Haul Harness Weaving",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "plain_weaving",
      "rope_laying"
    ],
    "requires_all": [
      "plain_weaving",
      "rope_laying"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Haul Harness Weaving",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "Broad woven pulling straps and joined ropes distribute a hauling load across a workable harness.",
    "effects": {},
    "production_items": [
      "haul_harness"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  },
  {
    "id": "cart_running_gear",
    "name": "Cart Running Gear",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "wooden_axle_shaping",
      "wooden_axle_boxes",
      "linchpin_retention",
      "cart_bed_framing",
      "drawbar_fitting",
      "haul_harness_weaving"
    ],
    "requires_all": [
      "wooden_axle_shaping",
      "wooden_axle_boxes",
      "linchpin_retention",
      "cart_bed_framing",
      "drawbar_fitting",
      "haul_harness_weaving"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "solid_wheels",
        "label": "Solid wheel cart building",
        "requires_all": [
          "solid_wheel_assembly"
        ]
      },
      {
        "id": "spoked_wheels",
        "label": "Spoked wheel cart building",
        "requires_all": [
          "spoked_wheel_assembly"
        ]
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "Matched wheels, axle fittings, a braced bed and hauling connections become a fitted cart assembly ready for final commissioning.",
    "effects": {},
    "production_items": [
      "cart_assembly_kits",
      "assembled_transport_cart"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  },
  {
    "id": "sleeved_cart_assembly",
    "name": "Sleeved Cart Assembly",
    "direction": "Infrastructure",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "cart_running_gear",
      "iron_tyre_fitting",
      "axle_sleeve_fitting"
    ],
    "requires_all": [
      "cart_running_gear",
      "iron_tyre_fitting",
      "axle_sleeve_fitting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Sleeved Cart Assembly",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "logistics"
    ],
    "observation": "Prepared iron-bound wheels and sleeved axle connections reduce final fitting work in a cart assembly shop.",
    "effects": {},
    "production_items": [
      "sleeved_cart_kits"
    ],
    "production_contract": "Finite workshop batches consume physical material and tooling. Cart components become assembled carts in the ordinary transport ledger; actual logistics labor is still required to deliver supplies. Discovery grants no vehicle, labor or global delivery multiplier."
  }
]
