extends RefCounted
const METHODS := {
	"textile_dye_fixation":{"name": "Textile-Dye Fixation", "requires_all": ["textile_dye_extraction", "experimental_controls"], "requires_any": [], "rate": 1.5, "cost": {"Hand Sewing Needle Sets": 1, "Timber": 2}, "inputs": {"Fixed Tannin Cloth": 1, "Spun Yarn": 0.05}, "mode": "fit", "fabric": "tannin", "observation": "Qualify a dyeing process that retains intended color on a specific fiber", "production_items": ["scoured_plant_cloth", "textile_ferrous_mordant", "tannin_mordanted_cloth", "checked_tannin_cloth", "iron_liquor_mordant", "printed_tannin_cloth"], "production_contract": "Selected compatible plant-fiber material and actual colorants, water, fuel, equipment and work produce distinct finished cloth. Five-percent destructive batch allowance represents nominal wash/appearance checks, not instrument telemetry or universal colorfastness certification. Garments retain their finish identity while use and washing fade it. Decoration adds no cold, storm, strength or health bonus."},
	"resist_dye_patterning":{"name": "Resist-Dye Patterning", "requires_all": ["textile_dye_fixation", "cordage"], "requires_any": [], "rate": 1.5, "cost": {"Hand Sewing Needle Sets": 1, "Timber": 2}, "inputs": {"Resist-Patterned Cloth": 1, "Spun Yarn": 0.05}, "mode": "fit", "fabric": "resist", "observation": "Prevent dye access to selected areas through a qualified resist method", "production_items": ["bound_resist_cloth", "resist_tannin_bath", "checked_resist_cloth"], "production_contract": "Selected compatible plant-fiber material and actual colorants, water, fuel, equipment and work produce distinct finished cloth. Five-percent destructive batch allowance represents nominal wash/appearance checks, not instrument telemetry or universal colorfastness certification. Garments retain their finish identity while use and washing fade it. Decoration adds no cold, storm, strength or health bonus."},
	"textile_printing":{"name": "Textile Printing", "requires_all": ["textile_dye_fixation", "printing_process"], "requires_any": [], "rate": 1.5, "cost": {"Hand Sewing Needle Sets": 1, "Timber": 2}, "inputs": {"Checked Printed Cloth": 1, "Spun Yarn": 0.05}, "mode": "fit", "fabric": "printed", "observation": "Apply qualified color patterns to a textile surface through repeatable printing", "production_items": ["textile_printing_blocks", "tannin_printing_paste", "checked_printed_cloth", "hand_block_printed_cloth"], "production_contract": "Selected compatible plant-fiber material and actual colorants, water, fuel, equipment and work produce distinct finished cloth. Five-percent destructive batch allowance represents nominal wash/appearance checks, not instrument telemetry or universal colorfastness certification. Garments retain their finish identity while use and washing fade it. Decoration adds no cold, storm, strength or health bonus."},
	"textile_calendering":{"name": "Textile Calendering", "requires_all": ["plain_weaving", "mechanical_screw_presses"], "requires_any": [], "rate": 1.5, "cost": {"Hand Sewing Needle Sets": 1, "Timber": 2}, "inputs": {"Calendered Cloth": 1, "Spun Yarn": 0.05}, "mode": "fit", "fabric": "calendered", "observation": "Finish a qualified fabric through controlled pressure and surface contact", "production_items": ["wooden_roll_calendering"], "production_contract": "Selected compatible plant-fiber material and actual colorants, water, fuel, equipment and work produce distinct finished cloth. Five-percent destructive batch allowance represents nominal wash/appearance checks, not instrument telemetry or universal colorfastness certification. Garments retain their finish identity while use and washing fade it. Decoration adds no cold, storm, strength or health bonus."},

	"textile_waterproofing":{"name": "Textile Waterproofing", "requires_all": ["plain_weaving", "adhesive_bond_design"], "requires_any": [], "rate": 1.5, "cost": {"Timber": 2, "Laboratory Glassware": 0.1}, "inputs": {"Stitched Rain-Shell Panels": 1}, "mode": "rain_shell", "observation": "Coat a compatible woven backing, assemble a rain shell and pay for three dated wet-flex checks before relying on its limited water barrier.", "production_items": ["textile_coating_machine", "textile_coating_grade", "polyethylene_coated_textile", "stitched_rain_shell_panels"], "production_contract": "A selected polyethylene-coated woven shell consumes actual coating stock, machinery, power and shared Logistics work. Three paid observed wet-flex cycles qualify the actual garment lot; missing water or work cannot advance them. The non-breathable shell has modest insulation and limited storm protection, with unsealed needle holes remaining a separate weakness. Wear and washing remove qualification; compatible paid repairs and retesting are needed. No chemical, pathogen, immersion or universal waterproof rating is granted."},
	"garment_seam_sealing":{"name": "Garment Seam Sealing", "requires_all": ["textile_waterproofing", "sewing_machine_mechanisms"], "requires_any": [], "rate": 1, "cost": {"Textile Heat-Sealing Tools": 1, "Timber": 1}, "inputs": {"Polyethylene Seam Tape": 0.06}, "power": 0.2, "mode": "seal_rain_seams", "observation": "Bond compatible tape across the stitched seams of a qualified coated shell with controlled heat and pressure, then complete three paid dated leak checks.", "production_items": ["textile_heat_sealing_tools", "compatible_polyethylene_seam_tape"], "production_contract": "Only an actual qualified coated rain-shell lot can receive compatible sealing tape. Paid equipment, electricity and Logistics work control the selected heat/pressure profile; insufficient adhesion fails and excess heat damages the shell. Three later paid wet-flex observations qualify those seams. Washing, wear and repair invalidate qualification. Seam sealing reduces a bounded rain-exposure loss, never establishes total garment sealing or chemical protection. Ordinary cloth and loose tape receive no benefit."},
	"zipper_chain_closures":{"name": "Zipper Chain Closures", "requires_all": ["sewing_machine_mechanisms", "dimensional_metrology"], "requires_any": [], "rate": 2, "cost": {"Treadle Sewing Machines": 1, "Timber": 2}, "inputs": {"Zippered Garment Fronts": 1, "Woven Cloth": 0.5, "Spun Yarn": 0.05, "Sewing Service Parts": 0.003}, "mode": "fit", "observation": "Fit matched element rows, a compatible slider and end stops to reinforced tapes; cycle-check the closure and sew the checked front into a fitted garment.", "production_items": ["zipper_forming_dies", "zipper_tape_pairs", "zipper_element_rows", "zipper_slider_stops", "matched_zipper_chains", "checked_garment_zippers", "zippered_garment_fronts"], "production_contract": "One selected light aluminum zipper design uses real tapes, elements, slider/stops, forming tools and paid matching, cycling and attachment work. Checked fronts feed ordinary fitted garments through shared Logistics labor. Loose rows or sliders cannot replace a finished closure. A five-percent destructive qualification allowance represents batch checks on nominal compatible parts, not a geometric sensor simulation or guaranteed arbitrary-stock acceptance. No waterproofing, fatigue-life or insulation bonus is granted; the resulting garment retains existing aggregate textile wear and repair."},
	"leather_thickness_skiving":{"name": "Leather Thickness Skiving", "requires_all": ["leather_goods_patterning", "dimensional_metrology"], "requires_any": [], "rate": 1.1, "cost": {"Leather Skiving Knives": 1, "Timber": 2, "Hand Sewing Needle Sets": 0.1}, "inputs": {"Folded Skived Leather Panels": 1, "Flexible Leather": 0.2, "Spun Yarn": 0.05}, "mode": "leather", "observation": "Gauge actual leather blanks, remove controlled edge layers, check remaining material and fold the thinned edges into sewn garment seams.", "production_items": ["leather_skiving_knives", "leather_edge_blanks", "skived_leather_panels", "checked_skived_panels", "folded_skived_panels"], "production_contract": "Paid knives, supports and gauges prepare a selected flexible-leather seam. Cutting and skiving retain finite named offcuts; they do not create extra full-grade leather. A five-percent destructive trial allowance checks nominal compatible panels before folding and stitching. Checked panels and additional leather/thread feed existing leather garments through shared Logistics labor; unskived blanks cannot substitute. This is a selected hand-knife production route, not a universal thickness or seam-strength certificate. Untouched leather gains no strength, tanning or waterproofing effect. Existing leather wear and compatible patch repair remain in use."},
	"buttonhole_edge_reinforcement":{"name": "Buttonhole Edge Reinforcement", "requires_all": ["bone_needle_sewing", "garment_pattern_cutting"], "requires_any": [], "rate": 1.8, "cost": {"Hand Sewing Needle Sets": 1, "Timber": 2}, "inputs": {"Button-Closed Garment Fronts": 1, "Woven Cloth": 0.5, "Spun Yarn": 0.06}, "mode": "fit", "observation": "Bind cut cloth openings with edge stitches and reinforced ends, fit matched buttons, and check the closure before joining fronts into fitted garments.", "production_items": ["closure_sewing_needles", "matched_wooden_buttons", "reinforced_buttonhole_panels", "checked_button_fronts"], "production_contract": "Selected wooden-button closures use shaped steel hand needles, real cloth/thread and finite cutting, sewing and pull-check work. Checked fronts and remaining cloth become ordinary fitted garments through shared Logistics labor. Unreinforced cloth and loose buttons cannot substitute for checked fronts. The small qualification allowance consumes trial material; no universal pull rating, automatic resistance gain or warmth bonus is granted. Garment wear and repair remain aggregate textile behavior."},
	"snap_fastener_closures":{"name": "Snap Fastener Closures", "requires_all": ["leather_goods_patterning", "elastic_deformation"], "requires_any": [], "rate": 1.2, "cost": {"Timber": 2, "Recovered Bone": 0.1, "Garment Snap Forming Dies": 1}, "inputs": {"Snap-Fastened Leather Panels": 1, "Flexible Leather": 0.33, "Spun Yarn": 0.08}, "mode": "leather", "observation": "Form matching stud/socket hardware with resilient spring rings, set it in supported compatible leather tabs, and check repeated engagement and attachment before garment assembly.", "production_items": ["garment_snap_dies", "garment_snap_shells", "garment_snap_rings", "matched_garment_snaps", "gauged_leather_closure_tabs", "checked_snap_leather_panels"], "production_contract": "A selected ring-spring closure consumes shaped shell parts and tempered spring rings, then matching and cycle-check work. Gauged supported leather tabs and actual matched snaps undergo paid setting and attachment checks. Checked panels feed ordinary leather garments through existing Logistics labor. Raw hides, ungauged tabs and shell parts alone cannot substitute. Dimensions and qualification yield describe one compatible game design, not arbitrary substrate certification; surrounding leather keeps its existing wear and repair behavior, without a waterproofing, strength or insulation bonus."},
"textile_braiding":{"name": "Textile Braiding", "requires_all": ["cordage", "yarn_tension_control"], "requires_any": [], "rate": 2.5, "cost": {"Timber": 2, "Stone": 1}, "inputs": {"Woven Cloth": 0.8, "Braided Garment Cords": 0.15}, "mode": "tied", "observation": "Interlace yarn paths under controlled tension to make garment cords, then use actual cords to fasten woven wraps.", "production_items": ["braided_garment_cords"], "production_contract": "Finite Crafting work and yarn make distinct braided garment cords. Paid fitting equipment, real cloth/cords and shared Logistics work supply tied wraps. Twisted rope cannot substitute; braid knowledge gives no lifting rating or insulation bonus. Imported cord stock never adds discovery mastery."},"quilted_layer_assembly":{"name": "Quilted Layer Assembly", "requires_all": ["bone_needle_sewing", "layered_clothing_design"], "requires_any": [], "rate": 0.8, "cost": {"Timber": 3, "Recovered Bone": 0.1}, "inputs": {"Woven Cloth": 1.1, "Plant-Fiber Quilt Batts": 0.65, "Spun Yarn": 0.15}, "mode": "quilt", "observation": "Stitch cloth faces around actual prepared plant-fiber filling so it stays distributed in an insulated garment.", "production_items": ["plant_fiber_quilt_batts"], "production_contract": "Paid preparation makes finite plant-fiber batts. Needles, cloth, filling, thread and shared Logistics work make quilted garments whose issued condition controls bounded insulation. Decorative stitching alone supplies no warmth. Quilt repair consumes replacement filling as well as cloth/thread; ordinary cloth repair cannot restore it. Coefficients represent a selected plant-fiber assembly, not a measured thermal certification."},
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
  "sewing_machine_mechanisms": {
  "name": "Sewing-Machine Mechanisms",
  "requires_all": [
    "bone_needle_sewing",
    "cam_motion_design"
  ],
  "requires_any": [],
  "rate": 6.0,
  "cost": {
    "Treadle Sewing Machines": 1.0,
    "Timber": 1.0
  },
  "inputs": {
    "Woven Cloth": 0.7,
    "Spun Yarn": 0.12,
    "Sewing Service Parts": 0.005
  },
  "mode": "sew",
  "production_items": [
    "sewing_service_parts",
    "treadle_sewing_machines"
  ],
  "observation": "Coordinate needle, shuttle and cloth feed using a paid manual treadle mechanism.",
  "production_contract": "Paid parts and trial-fitted treadle machines support faster ordinary sewing through existing finite Logistics work and equipment quotas. Actual cloth, both sewing threads and replacement needle/feed parts are consumed. Garments keep existing sewn quality, figured-fabric identity, wear, care and save behavior; no electricity, free work, new insulation bonus or arbitrary fabric qualification is granted."
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
    "production_contract": "Ordinary local hunting supplies bounded bone for paid needles. Early sewing can join raw hides with prepared plant fiber; woven cloth and spun yarn become the preferred route when supplied. Cutting templates reduce later cloth offcuts, and graded patterns support repeated fitted work. Repairs consume compatible material and shared Logistics time to restore the treated share of existing garment condition, never new garment quantity. Supply, equipment and daily quotas constrain operation."
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
		if spec.has("production_items"):result.back()["production_items"]=spec.production_items.duplicate()
	return result
