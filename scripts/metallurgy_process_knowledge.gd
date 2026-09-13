extends RefCounted
## Unregistered until paid processes, inspection, consumers and acquisition pass.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "material_phase_diagrams",
    "name": "Material Phase Diagrams",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "crystallography",
      "precision_thermometry"
    ],
    "requires_all": [
      "crystallography",
      "precision_thermometry"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Material Phase Diagrams",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Map stable or observed phase relations against declared composition and conditions",
    "effects": {},
    "operating_contract": "Characterized samples, controlled conditions and measurement evidence"
  },
  {
    "id": "steel_normalizing_control",
    "name": "Steel Normalizing Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "steel_refining"
    ],
    "requires_all": [
      "steel_refining"
    ],
    "requires_any": [
      [
        "material_phase_diagrams",
        "experimental_controls"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Steel Normalizing Control",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Apply a qualified thermal cycle to refine a steel's evaluated microstructure",
    "effects": {},
    "operating_contract": "Known steel composition, suitable furnace and structural or mechanical tests"
  },
  {
    "id": "induction_surface_hardening",
    "name": "Induction Surface Hardening",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "electromagnetic_induction",
      "hardened_edges"
    ],
    "requires_all": [
      "electromagnetic_induction",
      "hardened_edges"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Induction Surface Hardening",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Heat selected metal regions electromagnetically for a qualified hardening treatment",
    "effects": {},
    "operating_contract": "Compatible power equipment, workpiece, thermal control and inspection"
  },
  {
    "id": "metal_grain_size_measurement",
    "name": "Metal Grain Size Measurement",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "compound_microscopy"
    ],
    "requires_all": [
      "compound_microscopy"
    ],
    "requires_any": [
      [
        "material_phase_diagrams",
        "experimental_controls"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Metal Grain Size Measurement",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Measure representative grain structure using a defined preparation and counting method",
    "effects": {},
    "operating_contract": "Prepared samples, qualified imaging and analysts"
  },
  {
    "id": "residual_stress_assessment",
    "name": "Residual Stress Assessment",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "stress_strain_relations",
      "dimensional_metrology"
    ],
    "requires_all": [
      "stress_strain_relations",
      "dimensional_metrology"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Residual Stress Assessment",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Estimate retained internal stresses through qualified measurement and model assumptions",
    "effects": {},
    "operating_contract": "Suitable specimens, instruments and interpretation expertise"
  },
  {
    "id": "metal_fracture_toughness_testing",
    "name": "Metal Fracture Toughness Testing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "stress_strain_relations"
    ],
    "requires_all": [
      "stress_strain_relations"
    ],
    "requires_any": [
      [
        "cyclic_fatigue",
        "structural_load_testing"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Metal Fracture Toughness Testing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Measure resistance to crack extension under a defined qualified specimen condition",
    "effects": {},
    "operating_contract": "Representative material, calibrated loading equipment and trained analysis"
  },
  {
    "id": "welding_metallurgy",
    "name": "Welding Metallurgy",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "forge_welding",
      "material_phase_diagrams"
    ],
    "requires_all": [
      "forge_welding",
      "material_phase_diagrams"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Welding Metallurgy",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Relate joining thermal history to local microstructure and mechanical performance",
    "effects": {},
    "operating_contract": "Qualified joining equipment, known materials and inspection or test capacity"
  },
  {
    "id": "vacuum_metal_melting",
    "name": "Vacuum Metal Melting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "vacuum_pumps",
      "metal_casting_feed_design"
    ],
    "requires_all": [
      "vacuum_pumps",
      "metal_casting_feed_design"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Vacuum Metal Melting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Melt qualified metal under controlled reduced-pressure conditions to limit selected contamination",
    "effects": {},
    "operating_contract": "Compatible furnace, vacuum equipment, power and composition testing"
  },
  {
    "id": "investment_casting_process",
    "name": "Investment Casting Process",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "metal_casting_feed_design",
      "ceramic_slip_casting"
    ],
    "requires_all": [
      "metal_casting_feed_design",
      "ceramic_slip_casting"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Investment Casting Process",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "An expendable pattern creates a refractory casting mold.",
    "effects": {},
    "operating_contract": "Pay pattern, shell layers, drying, pattern removal, molten alloy and cleanup work; retain shrinkage and shell-failure checks."
  },
  {
    "id": "lost_foam_casting",
    "name": "Lost-Foam Casting",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "polymer_foam_cell_control",
      "metal_casting_feed_design"
    ],
    "requires_all": [
      "polymer_foam_cell_control",
      "metal_casting_feed_design"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Lost-Foam Casting",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Molten metal replaces an expendable foam pattern in a prepared mold.",
    "effects": {},
    "operating_contract": "Pay qualified foam patterns, coating, support media, metal and ventilation work; retain fill and residue inspection."
  },
  {
    "id": "honed_bore_finishing",
    "name": "Honed Bore Finishing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "cylinder_boring",
      "abrasive_grinding_control"
    ],
    "requires_all": [
      "cylinder_boring",
      "abrasive_grinding_control"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Honed Bore Finishing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Abrasive contact and controlled motion refine bore geometry.",
    "effects": {},
    "operating_contract": "Consume prepared bores, honing stones, fluid and machine work; inspect taper, roundness and surface condition."
  },
  {
    "id": "short_stroke_superfinishing",
    "name": "Short-Stroke Superfinishing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "cylindrical_grinding",
      "lubrication_regimes"
    ],
    "requires_all": [
      "cylindrical_grinding",
      "lubrication_regimes"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Short-Stroke Superfinishing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Light abrasive oscillation removes surface peaks.",
    "effects": {},
    "operating_contract": "Pay finishing media, fluid and controlled contact work on prequalified surfaces; measure retained roughness and geometry."
  }
]
