extends RefCounted
## Authored wooden hull, sail, rig and launch practices. No date unlock gates.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "rope_laying",
    "name": "Rope Laying",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "cordage",
      "standard_measures"
    ],
    "requires_all": [
      "cordage",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Rope Laying",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "Strands laid against their own twist share a load without immediately unravelling. A ropewalk produces repeatable working lengths.",
    "effects": {},
    "production_items": [
      "laid_rope"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  },
  {
    "id": "sail_panel_cutting",
    "name": "Sail Panel Cutting",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "plain_weaving",
      "standard_measures"
    ],
    "requires_all": [
      "plain_weaving",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Sail Panel Cutting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "Measured cloth panels preserve the intended outline and distribute the seams of a sail.",
    "effects": {},
    "production_items": [
      "sail_panel"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  },
  {
    "id": "sail_seaming",
    "name": "Sail Seaming",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "sail_panel_cutting",
      "cordage"
    ],
    "requires_all": [
      "sail_panel_cutting",
      "cordage"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Sail Seaming",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "Joined panels and reinforced edges transfer wind loads into the ropes that support and trim a sail.",
    "effects": {},
    "production_items": [
      "seamed_sails"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  },
  {
    "id": "wooden_sheave_blocks",
    "name": "Wooden Sheave Blocks",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "compound_pulleys",
      "joinery"
    ],
    "requires_all": [
      "compound_pulleys",
      "joinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Wooden Sheave Blocks",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "Grooved wooden wheels turn inside bound shells, guiding running rope while reducing the effort of hauling a sail.",
    "effects": {},
    "production_items": [
      "rigging_blocks"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  },
  {
    "id": "standing_running_rigging",
    "name": "Standing and Running Rigging",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "rope_laying",
      "wooden_sheave_blocks"
    ],
    "requires_all": [
      "rope_laying",
      "wooden_sheave_blocks"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Standing and Running Rigging",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "Fixed stays support the mast while separate moving lines hoist and trim the sails. Their coordinated layout makes a working rig.",
    "effects": {},
    "production_items": [
      "ship_rigging"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  },
  {
    "id": "keel_scarfing",
    "name": "Keel Scarfing",
    "direction": "Movement",
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
        "label": "Keel Scarfing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "Long overlapping joints unite shorter timbers into the longitudinal backbone of a larger hull.",
    "effects": {},
    "production_items": [
      "scarfed_keel"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  },
  {
    "id": "grown_frame_selection",
    "name": "Grown Frame Selection",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "joinery",
      "river_craft"
    ],
    "requires_all": [
      "joinery",
      "river_craft"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Grown Frame Selection",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "Naturally curved timber is selected so its grain follows the shape of a ship frame instead of cutting across the bend.",
    "effects": {},
    "production_items": [
      "grown_ship_frames"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  },
  {
    "id": "frame_moulding",
    "name": "Frame Moulding",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "grown_frame_selection",
      "standard_measures"
    ],
    "requires_all": [
      "grown_frame_selection",
      "standard_measures"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Frame Moulding",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "Reusable patterns transfer a planned hull section to a sequence of frames, reducing repeated fitting work.",
    "effects": {},
    "production_items": [
      "moulded_ship_frames"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  },
  {
    "id": "plank_spiling",
    "name": "Plank Spiling",
    "direction": "Movement",
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
        "label": "Plank Spiling",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "Offsets taken from a curved hull are transferred to a plank blank, preserving the changing width needed along its length.",
    "effects": {},
    "production_items": [
      "spiled_planks"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  },
  {
    "id": "caulking_fiber_preparation",
    "name": "Caulking Fiber Preparation",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "cordage",
      "river_craft"
    ],
    "requires_all": [
      "cordage",
      "river_craft"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Caulking Fiber Preparation",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "Separated fibers are worked into compressible strands that can pack the joints between hull planks.",
    "effects": {},
    "production_items": [
      "caulking_fiber"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  },
  {
    "id": "treenail_fastening",
    "name": "Treenail Fastening",
    "direction": "Movement",
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
        "label": "Treenail Fastening",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "Close-fitting wooden pins fasten planking to its supporting frames, providing a fastening route without a supply of metal nails.",
    "effects": {},
    "production_items": [
      "treenails"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  },
  {
    "id": "hull_seam_caulking",
    "name": "Hull Seam Caulking",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "caulking_fiber_preparation",
      "plank_spiling"
    ],
    "requires_all": [
      "caulking_fiber_preparation",
      "plank_spiling"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Hull Seam Caulking",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "Driven fiber and a sealing compound close plank seams while allowing limited movement of the wooden hull.",
    "effects": {},
    "production_items": [
      "sealed_planking"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  },
  {
    "id": "carvel_frame_construction",
    "name": "Carvel Frame Construction",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "keel_scarfing",
      "grown_frame_selection",
      "hull_seam_caulking",
      "treenail_fastening"
    ],
    "requires_all": [
      "keel_scarfing",
      "grown_frame_selection",
      "hull_seam_caulking",
      "treenail_fastening"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Carvel Frame Construction",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "Planks fitted edge to edge over a supporting frame form a smooth outer hull. The frames establish its shape before the planking closes it.",
    "effects": {},
    "production_items": [
      "carvel_hull_sections",
      "heavy_carvel_hull_sections"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  },
  {
    "id": "clinker_shell_construction",
    "name": "Clinker Shell Construction",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "keel_scarfing",
      "plank_spiling",
      "caulking_fiber_preparation",
      "forge_welding"
    ],
    "requires_all": [
      "keel_scarfing",
      "plank_spiling",
      "caulking_fiber_preparation",
      "forge_welding"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Clinker Shell Construction",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "Overlapping strakes are fastened together as a shell before its internal supports are fitted, offering a different construction sequence from frame-first building.",
    "effects": {},
    "production_items": [
      "clinker_hull_sections"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  },
  {
    "id": "mast_making",
    "name": "Mast Making",
    "direction": "Movement",
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
        "label": "Mast Making",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "Selected straight timber is shaped into spars with reinforced attachment points for the loads of sails and rigging.",
    "effects": {},
    "production_items": [
      "ship_masts"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  },
  {
    "id": "launching_cradles",
    "name": "Launching Cradles",
    "direction": "Movement",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "joinery",
      "keel_scarfing"
    ],
    "requires_all": [
      "joinery",
      "keel_scarfing"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Launching Cradles",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "timber",
      "materials"
    ],
    "observation": "A fitted supporting cradle carries a completed hull along prepared ways during launching, becoming reusable shipyard tooling.",
    "effects": {},
    "production_items": [
      "launch_cradle"
    ],
    "production_contract": "Paid workshop batches manufacture physical shipyard components. Components are consumed by hull, sail and rig assembly; commissioned ships still require equipment, crews, a ready base and construction work. Discovery grants no vessel or global combat bonus."
  }
]
