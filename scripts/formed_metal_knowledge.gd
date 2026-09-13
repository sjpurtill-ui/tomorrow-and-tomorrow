extends RefCounted
## Forming creates typed components; existing owners perform production and use.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "metal_spinning_forming",
    "name": "Metal Spinning Forming",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "centre_lathe_assembly",
      "sheet_steel_rolling"
    ],
    "requires_all": [
      "centre_lathe_assembly",
      "sheet_steel_rolling"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Metal Spinning Forming",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A roller forms a rotating blank around a mandrel.",
    "effects": {},
    "production_items": [
      "metal_spinning_tool_sets",
      "spun_motor_shrouds"
    ],
    "production_contract": "Paid mandrels, rollers, compatible sheet, lubricant and trim/cutting work form rotationally symmetric motor shrouds. Existing motor assembly consumes the actual shroud with qualified leads, winding material and bearings. A shroud is not a pressure vessel or universal protective housing."
  },
  {
    "id": "rotary_swaging",
    "name": "Rotary Swaging",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "precision_machinery",
      "toolbit_heat_treatment"
    ],
    "requires_all": [
      "precision_machinery",
      "toolbit_heat_treatment"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Rotary Swaging",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Repeated radial die blows reduce a rod or tube profile.",
    "effects": {},
    "production_items": [
      "rotary_swaging_dies",
      "swaged_terminal_pins"
    ],
    "production_contract": "Make matched dies and spend repeated radial forming work on a specified copper terminal-pin blank. Finished pins are consumed in a separate paid joining and continuity-check operation for motor leads. Unformed blanks do not substitute for shaped pins; die wear and rejected-material allowance are paid."
  },
  {
    "id": "tube_rotary_draw_bending",
    "name": "Tube Rotary-Draw Bending",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "precision_machinery",
      "stress_strain_relations"
    ],
    "requires_all": [
      "precision_machinery",
      "stress_strain_relations"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Tube Rotary-Draw Bending",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "A rotating bend die draws tubing around a fixed radius.",
    "effects": {},
    "production_items": [
      "tube_bend_tool_sets",
      "formed_steel_pipe_bends"
    ],
    "production_contract": "Make matched bending dies/supports and pay forming work on already bored steel tubes. The resulting bend is not pressure-rated stock: a separately known joining/water-test operation consumes it with fittings and water before existing Pressure Pipe Fittings can be produced."
  },
  {
    "id": "roll_formed_sections",
    "name": "Roll-Formed Sections",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "sheet_steel_rolling",
      "shaft_alignment_methods"
    ],
    "requires_all": [
      "sheet_steel_rolling",
      "shaft_alignment_methods"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Roll-Formed Sections",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Successive roll stands progressively bend a strip profile.",
    "effects": {},
    "production_items": [
      "channel_roll_tool_sets",
      "roll_formed_channels"
    ],
    "production_contract": "Pay aligned roll stands, sheet, cutoff wear, drive electricity and work into steel channels. A separate structural-load-test operation assembles and checks actual press frames using fasteners and sacrificial test material; pneumatic press assembly consumes those frames. Forming alone grants no structural certification."
  },
  {
    "id": "centrifugal_tube_casting",
    "name": "Centrifugal Tube Casting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "metal_casting_feed_design",
      "precision_machinery"
    ],
    "requires_all": [
      "metal_casting_feed_design",
      "precision_machinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Centrifugal Tube Casting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Rotation distributes molten alloy along a tubular mold wall.",
    "effects": {},
    "production_items": [
      "centrifugal_tube_molds",
      "centrifugal_steel_tube_blanks"
    ],
    "production_contract": "Pay a balanced rotating mold, alloy feed, furnace fuel, drive power and cooling to produce tubular steel blanks. Later boring removes the retained inner allowance and inspects the bore before tube bending and separate pressure-joint qualification. Raw cast blanks cannot bypass those consumers or claim a universal pressure rating."
  }
]
