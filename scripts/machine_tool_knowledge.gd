extends RefCounted
## Individually authored machine construction and metrology practices.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "three_plate_lapping",
    "name": "Three-Plate Lapping",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "standard_measures",
      "stone_sorting"
    ],
    "requires_all": [
      "standard_measures",
      "stone_sorting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Three-Plate Lapping",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Three reference surfaces are compared and worked against one another so a matching curve does not masquerade as a plane.",
    "effects": {},
    "production_items": [
      "surface_plates"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "straightedge_scraping",
    "name": "Straightedge Scraping",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "three_plate_lapping",
      "forge_welding"
    ],
    "requires_all": [
      "three_plate_lapping",
      "forge_welding"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Straightedge Scraping",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "High spots are removed from a metal straightedge against a reference surface, providing a portable guide for fitting longer ways.",
    "effects": {},
    "production_items": [
      "scraped_straightedges"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "machine_way_scraping",
    "name": "Machine-Way Scraping",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "straightedge_scraping",
      "bearing_surfaces"
    ],
    "requires_all": [
      "straightedge_scraping",
      "bearing_surfaces"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Machine-Way Scraping",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Bearing contact is checked along a guideway and high spots are scraped away so a carriage can move without rocking or binding.",
    "effects": {},
    "production_items": [
      "scraped_machine_ways"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "lead_screw_cutting",
    "name": "Lead-Screw Cutting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "standard_measures",
      "steel_refining",
      "gear_ratios"
    ],
    "requires_all": [
      "standard_measures",
      "steel_refining",
      "gear_ratios"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Lead-Screw Cutting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A repeated helical thread converts controlled rotation into a reproducible length of carriage travel.",
    "effects": {},
    "production_items": [
      "machine_lead_screws"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "split_feed_nuts",
    "name": "Split Feed Nuts",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lead_screw_cutting",
      "copper_smelting"
    ],
    "requires_all": [
      "lead_screw_cutting",
      "copper_smelting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Split Feed Nuts",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A matching split nut can engage a lead screw for a controlled feed and disengage it for repositioning.",
    "effects": {},
    "production_items": [
      "machine_feed_nuts"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "cross_slide_assembly",
    "name": "Cross-Slide Assembly",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "machine_way_scraping",
      "lead_screw_cutting",
      "split_feed_nuts"
    ],
    "requires_all": [
      "machine_way_scraping",
      "lead_screw_cutting",
      "split_feed_nuts"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Cross-Slide Assembly",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Intersecting guided slides and screw feeds set a cutting tool across the work rather than relying on unsupported hand pressure.",
    "effects": {},
    "production_items": [
      "machine_cross_slides"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "four_jaw_chucks",
    "name": "Four-Jaw Chucks",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lead_screw_cutting",
      "forge_welding"
    ],
    "requires_all": [
      "lead_screw_cutting",
      "forge_welding"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Four-Jaw Chucks",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Four independently adjusted jaws grip a workpiece and allow its working surface to be centered even when its outer shape is irregular.",
    "effects": {},
    "production_items": [
      "four_jaw_chucks"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "tailstock_fitting",
    "name": "Tailstock Fitting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "straightedge_scraping",
      "lead_screw_cutting",
      "bearing_surfaces"
    ],
    "requires_all": [
      "straightedge_scraping",
      "lead_screw_cutting",
      "bearing_surfaces"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Tailstock Fitting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "An aligned sliding support steadies the far end of a rotating workpiece or advances a tool along its center line.",
    "effects": {},
    "production_items": [
      "lathe_tailstocks"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "toolbit_heat_treatment",
    "name": "Tool-Bit Heat Treatment",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "steel_refining",
      "charcoal"
    ],
    "requires_all": [
      "steel_refining",
      "charcoal"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Tool-Bit Heat Treatment",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Heating, hardening and tempering prepare small steel cutting edges that retain useful hardness while resisting fracture.",
    "effects": {},
    "production_items": [
      "steel_tool_bits"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "centre_lathe_assembly",
    "name": "Centre-Lathe Assembly",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "cross_slide_assembly",
      "four_jaw_chucks",
      "tailstock_fitting",
      "toolbit_heat_treatment"
    ],
    "requires_all": [
      "cross_slide_assembly",
      "four_jaw_chucks",
      "tailstock_fitting",
      "toolbit_heat_treatment"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Centre-Lathe Assembly",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Aligned ways, a controlled slide, a gripping spindle and an opposing support form a machine for turning work about a stable axis.",
    "effects": {},
    "production_items": [
      "metalworking_lathes"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "drill_bit_fluting",
    "name": "Drill-Bit Fluting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "toolbit_heat_treatment",
      "standard_measures"
    ],
    "requires_all": [
      "toolbit_heat_treatment",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Drill-Bit Fluting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Cutting lips and flutes are formed together so a drill can cut a round hole and carry its chips away.",
    "effects": {},
    "production_items": [
      "fluted_drill_bits"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "quill_feed_mechanisms",
    "name": "Quill Feed Mechanisms",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "centre_lathe_assembly",
      "bearing_surfaces",
      "lead_screw_cutting"
    ],
    "requires_all": [
      "centre_lathe_assembly",
      "bearing_surfaces",
      "lead_screw_cutting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Quill Feed Mechanisms",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A guided quill advances a rotating spindle toward the work while supporting its bearings and preserving alignment.",
    "effects": {},
    "production_items": [
      "drill_quills"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "column_drilling_machines",
    "name": "Column Drilling Machines",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "quill_feed_mechanisms",
      "drill_bit_fluting"
    ],
    "requires_all": [
      "quill_feed_mechanisms",
      "drill_bit_fluting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Column Drilling Machines",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A supported drilling head and fixed work table control the feed of a drill into a secured workpiece.",
    "effects": {},
    "production_items": [
      "column_drills"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "milling_cutter_relief",
    "name": "Milling Cutter Relief",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "toolbit_heat_treatment",
      "centre_lathe_assembly"
    ],
    "requires_all": [
      "toolbit_heat_treatment",
      "centre_lathe_assembly"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Milling Cutter Relief",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Clearance behind successive cutting edges lets a rotating multi-tooth cutter remove material without rubbing its whole flank on the work.",
    "effects": {},
    "production_items": [
      "relieved_milling_cutters"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "milling_table_feeds",
    "name": "Milling Table Feeds",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "cross_slide_assembly",
      "machine_way_scraping"
    ],
    "requires_all": [
      "cross_slide_assembly",
      "machine_way_scraping"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Milling Table Feeds",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A rigid table moves a secured workpiece along controlled intersecting feeds beneath a rotating cutter.",
    "effects": {},
    "production_items": [
      "milling_tables"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "milling_spindle_heads",
    "name": "Milling Spindle Heads",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "centre_lathe_assembly",
      "column_drilling_machines",
      "gear_ratios"
    ],
    "requires_all": [
      "centre_lathe_assembly",
      "column_drilling_machines",
      "gear_ratios"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Milling Spindle Heads",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A supported spindle and its gear drive carry the cutting loads of a milling arbor without depending on a loose hand-held shaft.",
    "effects": {},
    "production_items": [
      "milling_spindle_heads"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "horizontal_milling_machines",
    "name": "Horizontal Milling Machines",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "milling_table_feeds",
      "milling_spindle_heads",
      "milling_cutter_relief"
    ],
    "requires_all": [
      "milling_table_feeds",
      "milling_spindle_heads",
      "milling_cutter_relief"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Horizontal Milling Machines",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A rigid bed joins controlled table movement to a supported horizontal cutting spindle, allowing repeated flat and shaped cuts.",
    "effects": {},
    "production_items": [
      "horizontal_mills"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "worm_dividing_heads",
    "name": "Worm Dividing Heads",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "horizontal_milling_machines",
      "gear_ratios"
    ],
    "requires_all": [
      "horizontal_milling_machines",
      "gear_ratios"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Worm Dividing Heads",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A worm reduction and indexed spindle divide a full turn into repeatable positions for evenly spaced machining operations.",
    "effects": {},
    "production_items": [
      "dividing_heads"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "drill_jig_bushings",
    "name": "Drill Jig Bushings",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "centre_lathe_assembly",
      "column_drilling_machines"
    ],
    "requires_all": [
      "centre_lathe_assembly",
      "column_drilling_machines"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Drill Jig Bushings",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Fitted guide sleeves locate a drill while providing a replaceable wearing surface inside a drilling fixture.",
    "effects": {},
    "production_items": [
      "drill_jig_bushings"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "drill_jig_layout",
    "name": "Drill Jig Layout",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "drill_jig_bushings",
      "horizontal_milling_machines",
      "standard_measures"
    ],
    "requires_all": [
      "drill_jig_bushings",
      "horizontal_milling_machines",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Drill Jig Layout",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A measured fixture locates both the workpiece and its drill guides so a hole pattern can be repeated across multiple parts.",
    "effects": {},
    "production_items": [
      "drill_jigs"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "gauge_block_lapping",
    "name": "Gauge-Block Lapping",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "three_plate_lapping",
      "precision_machinery",
      "precision_thermometry"
    ],
    "requires_all": [
      "three_plate_lapping",
      "precision_machinery",
      "precision_thermometry"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Gauge-Block Lapping",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Hardened measuring blocks are finished with flat parallel faces and compared under controlled conditions to transfer a reference length.",
    "effects": {},
    "production_items": [
      "gauge_blocks"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "bench_vise_screws",
    "name": "Bench-Vise Screws",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lead_screw_cutting",
      "split_feed_nuts",
      "column_drilling_machines"
    ],
    "requires_all": [
      "lead_screw_cutting",
      "split_feed_nuts",
      "column_drilling_machines"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Bench-Vise Screws",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A guided moving jaw and fitted screw hold a workpiece against a fixed jaw while leaving both hands free for the machining task.",
    "effects": {},
    "production_items": [
      "machine_bench_vises"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "basic_machine_shops",
    "name": "Basic Machine Shops",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "centre_lathe_assembly",
      "column_drilling_machines",
      "bench_vise_screws"
    ],
    "requires_all": [
      "centre_lathe_assembly",
      "column_drilling_machines",
      "bench_vise_screws"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Basic Machine Shops",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Turning, drilling and secure bench work are fitted together as an accountable set of machines ready for workshop installation.",
    "effects": {},
    "production_items": [
      "basic_machine_tool_sets"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  },
  {
    "id": "precision_toolrooms",
    "name": "Precision Toolrooms",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "basic_machine_shops",
      "horizontal_milling_machines",
      "worm_dividing_heads",
      "drill_jig_layout",
      "gauge_block_lapping"
    ],
    "requires_all": [
      "basic_machine_shops",
      "horizontal_milling_machines",
      "worm_dividing_heads",
      "drill_jig_layout",
      "gauge_block_lapping"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Precision Toolrooms",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Milling, indexed workholding, fixtures and dimensional references join the basic machines in a shop equipped for controlled repeat production.",
    "effects": {},
    "production_items": [
      "precision_machine_tool_sets"
    ],
    "production_contract": "Physical workshop batches consume actual materials, setup tooling and finite labor to create machine components. Complete tool sets must be installed with motors, commissioning work, operators and electricity before they provide powered workshop service. Knowledge alone grants no machine or global production bonus."
  }
]
