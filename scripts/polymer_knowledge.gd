extends RefCounted
## Partial polymer family; delivery remains HELD.
static func entries()->Array[Dictionary]:
	return [
  {
    "id": "hydrocarbon_steam_cracking",
    "name": "Hydrocarbon Steam Cracking",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "fuel_refining",
      "pressure_vessels",
      "precision_thermometry"
    ],
    "requires_all": [
      "fuel_refining",
      "pressure_vessels",
      "precision_thermometry"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Hydrocarbon Steam Cracking",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Thermally cleave a suitable hydrocarbon feed with steam dilution, quench and separation into a finite mixture of lighter chemical streams.",
    "effects": {},
    "production_items": [
      "steam_cracked_ethene"
    ],
    "production_contract": "Uses named feedstock batches, installed tooling, shared Crafting labor and specified daily power/services. Material qualification consumes the specific batch and samples; ownership of imported output grants no manufacturing mastery."
  },
  {
    "id": "polymer_chain_models",
    "name": "Polymer-Chain Models",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "chemical_distillation",
      "experimental_controls"
    ],
    "requires_all": [
      "chemical_distillation",
      "experimental_controls"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Polymer-Chain Models",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Relate macromolecular structure to observed material behavior",
    "effects": {},
    "production_items": [
      "characterized_ldpe"
    ],
    "production_contract": "Uses named feedstock batches, installed tooling, shared Crafting labor and specified daily power/services. Material qualification consumes the specific batch and samples; ownership of imported output grants no manufacturing mastery."
  },
  {
    "id": "polymer_film_extrusion",
    "name": "Polymer Film Extrusion",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "polymer_melt_rheology",
      "precision_machinery"
    ],
    "requires_all": [
      "polymer_melt_rheology",
      "precision_machinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Polymer Film Extrusion",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Form a continuous qualified polymer film through controlled die flow and cooling",
    "effects": {},
    "production_items": [
      "ldpe_film_extrusion",
      "ldpe_formed_sheet"
    ],
    "production_contract": "Uses named feedstock batches, installed tooling, shared Crafting labor and specified daily power/services. Material qualification consumes the specific batch and samples; ownership of imported output grants no manufacturing mastery."
  },
  {
    "id": "polymer_melt_rheology",
    "name": "Polymer Melt Rheology",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "thermoplastic_processing",
      "viscous_resistance"
    ],
    "requires_all": [
      "thermoplastic_processing",
      "viscous_resistance"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Polymer Melt Rheology",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Measure flow response of a polymer melt under defined thermal and deformation conditions",
    "effects": {},
    "production_items": [
      "ldpe_film_grade",
      "ldpe_molding_grade"
    ],
    "production_contract": "Uses named feedstock batches, installed tooling, shared Crafting labor and specified daily power/services. Material qualification consumes the specific batch and samples; ownership of imported output grants no manufacturing mastery."
  },
  {
    "id": "polymer_monomer_purification",
    "name": "Polymer Monomer Purification",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "experimental_controls"
    ],
    "requires_all": [
      "experimental_controls"
    ],
    "requires_any": [
      [
        "fractional_distillation",
        "chemical_distillation"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Polymer Monomer Purification",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Qualify feed monomers by separating and measuring process-relevant impurities",
    "effects": {},
    "production_items": [
      "purified_ethene_feed"
    ],
    "production_contract": "Uses named feedstock batches, installed tooling, shared Crafting labor and specified daily power/services. Material qualification consumes the specific batch and samples; ownership of imported output grants no manufacturing mastery."
  },
  {
    "id": "polymer_reaction_heat_management",
    "name": "Polymer Reaction Heat Management",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "calorimetry"
    ],
    "requires_all": [
      "calorimetry"
    ],
    "requires_any": [
      [
        "radical_chain_polymerization",
        "condensative_step_polymerization",
        "additive_step_polymerization"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Polymer Reaction Heat Management",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Measure and control heat release and removal in a qualified polymer production process",
    "effects": {},
    "production_items": [
      "polymer_cooling_circuit"
    ],
    "production_contract": "Uses named feedstock batches, installed tooling, shared Crafting labor and specified daily power/services. Material qualification consumes the specific batch and samples; ownership of imported output grants no manufacturing mastery.",
    "operating_plants": [
      "polymer_cooling_circuit"
    ]
  },
  {
    "id": "radical_chain_polymerization",
    "name": "Radical Chain Polymerization",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "polymer_monomer_purification"
    ],
    "requires_all": [
      "polymer_monomer_purification"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Radical Chain Polymerization",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Build polymer chains through controlled radical propagation with evaluated product properties",
    "effects": {},
    "production_items": [
      "radical_ldpe_resin",
      "polymer_pressure_reactor"
    ],
    "production_contract": "Uses named feedstock batches, installed tooling, shared Crafting labor and specified daily power/services. Material qualification consumes the specific batch and samples; ownership of imported output grants no manufacturing mastery.",
    "operating_plants": [
      "polymer_pressure_reactor"
    ]
  },
  {
    "id": "thermoplastic_processing",
    "name": "Thermoplastic Processing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "polymer_chain_models",
      "precision_thermometry"
    ],
    "requires_all": [
      "polymer_chain_models",
      "precision_thermometry"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Thermoplastic Processing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Shape qualified polymers through reversible softening and cooling within their process window",
    "effects": {},
    "production_items": [
      "ldpe_pelletizing"
    ],
    "production_contract": "Uses named feedstock batches, installed tooling, shared Crafting labor and specified daily power/services. Material qualification consumes the specific batch and samples; ownership of imported output grants no manufacturing mastery."
  },
  {
    "id": "polymer_injection_molding",
    "name": "Polymer Injection Molding",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "polymer_melt_rheology",
      "precision_machinery"
    ],
    "requires_all": [
      "polymer_melt_rheology",
      "precision_machinery"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Polymer Injection Molding",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Fill a qualified mold with controlled polymer flow and solidification",
    "effects": {},
    "production_contract": "Consumes compatible grade or formed sheet, paid process tooling, shared workshop work and energy into fitted low-load telephone covers. Covers retain a timber internal mounting base; they do not replace pressure vessels or structural machine parts.",
    "production_items": [
      "injected_telephone_covers"
    ]
  },
  {
    "id": "polymer_thermoforming",
    "name": "Polymer Thermoforming",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "thermoplastic_processing"
    ],
    "requires_all": [
      "thermoplastic_processing"
    ],
    "requires_any": [
      [
        "vacuum_pumps",
        "compressed_air_systems",
        "precision_machinery"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Polymer Thermoforming",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Shape a heated qualified polymer sheet against compatible tooling",
    "effects": {},
    "production_contract": "Consumes compatible grade or formed sheet, paid process tooling, shared workshop work and energy into fitted low-load telephone covers. Covers retain a timber internal mounting base; they do not replace pressure vessels or structural machine parts.",
    "production_items": [
      "formed_telephone_covers"
    ]
  },
  {
    "id": "industrial_catalyst_design",
    "name": "Industrial Catalyst Design",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "experimental_controls",
      "chemical_distillation"
    ],
    "requires_all": [
      "experimental_controls",
      "chemical_distillation"
    ],
    "requires_any": [
      [
        "iron_ammonia_catalysts",
        "enzyme_catalysis",
        "sulfuric_acid_production"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Industrial Catalyst Design",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Relate a catalyst's composition and accessible structure to a declared process reaction",
    "effects": {},
    "production_contract": "Uses named chemical feeds, paid sample qualification, consumed materials and shared workshop work. Interior bonded wood is restricted to indoor equipment panels; adhesive is not interchangeable across substrates or exterior structural uses.",
    "production_items": [
      "silver_oxidation_catalyst"
    ]
  },
  {
    "id": "condensative_step_polymerization",
    "name": "Condensative Step Polymerization",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "polymer_monomer_purification"
    ],
    "requires_all": [
      "polymer_monomer_purification"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Condensative Step Polymerization",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Join functional molecules through qualified step reactions that release small-molecule products",
    "effects": {},
    "production_contract": "Uses named chemical feeds, paid sample qualification, consumed materials and shared workshop work. Interior bonded wood is restricted to indoor equipment panels; adhesive is not interchangeable across substrates or exterior structural uses.",
    "production_items": [
      "urea_formaldehyde_resin"
    ]
  },
  {
    "id": "adhesive_bond_design",
    "name": "Adhesive-Bond Design",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "experimental_controls"
    ],
    "requires_all": [
      "experimental_controls"
    ],
    "requires_any": [
      [
        "joinery",
        "elastic_deformation"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Adhesive-Bond Design",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Join prepared surfaces with a qualified bonding material and load-bearing interface",
    "effects": {},
    "production_contract": "Uses named chemical feeds, paid sample qualification, consumed materials and shared workshop work. Interior bonded wood is restricted to indoor equipment panels; adhesive is not interchangeable across substrates or exterior structural uses.",
    "production_items": [
      "qualified_uf_wood_adhesive"
    ]
  },
  {
    "id": "engineered_wood_lamination",
    "name": "Engineered Wood Lamination",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "adhesive_bond_design",
      "timber_grading"
    ],
    "requires_all": [
      "adhesive_bond_design",
      "timber_grading"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Engineered Wood Lamination",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Bond graded wood elements into a qualified structural product",
    "effects": {},
    "production_contract": "Uses named chemical feeds, paid sample qualification, consumed materials and shared workshop work. Interior bonded wood is restricted to indoor equipment panels; adhesive is not interchangeable across substrates or exterior structural uses.",
    "production_items": [
      "laminated_interior_panels"
    ]
  }
]
