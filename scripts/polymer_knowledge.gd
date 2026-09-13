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
      "silver_oxidation_catalyst",
      "alumina_catalyst_support",
      "ethene_oxidation_catalyst",
      "qualified_nickel_hydrogenation_catalyst"
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
  },
  {
    "id": "wood_methanol_recovery",
    "name": "Wood Methanol Recovery",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "charcoal_retorts",
      "chemical_distillation"
    ],
    "requires_all": [
      "charcoal_retorts",
      "chemical_distillation"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Wood Methanol Recovery",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Capture wood-carbonization vapors and separate a methanol-bearing fraction from watery condensate and tar; further refining distinguishes usable methanol from crude mixed solvent.",
    "effects": {},
    "production_items": [
      "wood_chemical_condensate",
      "wood_methanol_fraction"
    ],
    "production_contract": "Pay suitable Timber, retort and condenser capacity, heat, water, separation work and feed-quality trials; account for low variable methanol recovery and rejected watery or tarry fractions.; named physical feedstocks, installed tooling, shared labor and specified energy are consumed. Imported product grants no synthesis mastery."
  },
  {
    "id": "silver_cupellation",
    "name": "Silver Cupellation",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "lead_smelting",
      "ore_assaying"
    ],
    "requires_all": [
      "lead_smelting",
      "ore_assaying"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Silver Cupellation",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Oxidize the lead and base-metal carrier of a qualified silver-bearing metal charge, retaining a noble-metal-rich residue and separating oxidized material in a consumable hearth lining.",
    "effects": {},
    "production_items": [
      "cupelled_silver"
    ],
    "production_contract": "Pay assayed silver-bearing feed, any required lead collector, fuel, furnace work and lining replacement; retain slag/litharge and metal losses, and verify the recovered silver grade.; named physical feedstocks, installed tooling, shared labor and specified energy are consumed. Imported product grants no synthesis mastery."
  },
  {
    "id": "formaldehyde_synthesis",
    "name": "Formaldehyde Synthesis",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "industrial_catalyst_design",
      "chemical_distillation",
      "experimental_controls"
    ],
    "requires_all": [
      "industrial_catalyst_design",
      "chemical_distillation",
      "experimental_controls"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Formaldehyde Synthesis",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Convert qualified methanol through a selected catalytic oxidation/dehydrogenation route and absorb the resulting formaldehyde into a defined solution.",
    "effects": {},
    "production_items": [
      "formaldehyde_solution"
    ],
    "production_contract": "Pay named methanol feed, maintained qualified catalyst, controlled air handling, reaction and cooling capacity, water, separation work and output checks; retain catalyst wear and rejected fractions.; named physical feedstocks, installed tooling, shared labor and specified energy are consumed. Imported product grants no synthesis mastery."
  },
  {
    "id": "urea_synthesis",
    "name": "Urea Synthesis",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "pressure_vessels",
      "chemical_distillation",
      "experimental_controls"
    ],
    "requires_all": [
      "pressure_vessels",
      "chemical_distillation",
      "experimental_controls"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Urea Synthesis",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "React defined ammonia and carbon-dioxide feeds through the carbamate-to-urea pathway, separating product from unconverted material.",
    "effects": {},
    "production_items": [
      "separated_urea"
    ],
    "production_contract": "Pay named Ammonia and Carbon Dioxide, maintained pressure plant, heat, cooling and separation work; bounded recycle retains makeup requirements and losses, and product qualification consumes samples.; named physical feedstocks, installed tooling, shared labor and specified energy are consumed. Imported product grants no synthesis mastery."
  },
  {
    "id": "enzyme_catalysis",
    "name": "Enzyme Catalysis",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "fermentation_control",
      "chemical_distillation"
    ],
    "requires_all": [
      "fermentation_control",
      "chemical_distillation"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Enzyme Catalysis",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "research",
      "nature"
    ],
    "observation": "Identify biological catalysts that alter reaction rates under suitable conditions",
    "effects": {},
    "production_items": [
      "pancreatic_enzyme_fraction",
      "qualified_bating_protease",
      "enzyme_bated_hides"
    ],
    "production_contract": "Separate a finite rapidly decaying pancreatic fraction from actual hunted gland tissue, qualify its activity on hide samples, and spend specific protease in hide bating. Biological stocks lose activity daily; imported enzyme does not teach extraction."
  },
  {
    "id": "ring_opening_polymerization",
    "name": "Ring Opening Polymerization",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "industrial_catalyst_design"
    ],
    "requires_all": [
      "industrial_catalyst_design"
    ],
    "requires_any": [
      [
        "polymer_chain_models",
        "experimental_controls"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Ring Opening Polymerization",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Convert suitable cyclic monomers into a qualified polymer through ring-opening reactions",
    "effects": {},
    "production_contract": "Consumes named cyclic oxide and glycol initiation feed through paid stirred-reactor and cooling capacity into a distinct PEG diol. No isocyanate, polyurethane or universal resin is granted.",
    "production_items": [
      "ring_opened_peg_diol"
    ]
  },
  {
    "id": "metallurgical_mass_balances",
    "name": "Metallurgical Mass Balances",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "material_accounting",
      "ore_assaying"
    ],
    "requires_all": [
      "material_accounting",
      "ore_assaying"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Metallurgical Mass Balances",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Account for useful material and losses across a metallurgical process",
    "effects": {},
    "production_contract": "Measured feeds, products, residues and sampling; consume named material lots, samples, installed tooling, work and specified power through real downstream production.",
    "production_items": [
      "balanced_nickel_feed"
    ]
  },
  {
    "id": "nickel_metal_recovery",
    "name": "Nickel Metal Recovery",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "ore_assaying",
      "metallurgical_mass_balances"
    ],
    "requires_all": [
      "ore_assaying",
      "metallurgical_mass_balances"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Nickel Metal Recovery",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Separate and refine nickel from a characterized feed through a qualified process",
    "effects": {},
    "production_contract": "Suitable plant, reagents or heat, energy and controlled residues; consume named material lots, samples, installed tooling, work and specified power through real downstream production.",
    "production_items": [
      "prepared_nickel_oxide",
      "reduced_nickel"
    ]
  },
  {
    "id": "biomass_gasification",
    "name": "Biomass Gasification",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "charcoal",
      "gas_composition_analysis"
    ],
    "requires_all": [
      "charcoal",
      "gas_composition_analysis"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Biomass Gasification",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Convert biomass into a characterized combustible gas through controlled partial conversion",
    "effects": {},
    "production_contract": "Prepared feedstock, qualified reactor, gas cleaning and operators; consume named material lots, samples, installed tooling, work and specified power through real downstream production.",
    "production_items": [
      "biomass_producer_gas"
    ]
  },
  {
    "id": "gas_composition_analysis",
    "name": "Gas Composition Analysis",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "spectroscopy",
      "chemical_distillation"
    ],
    "requires_all": [
      "spectroscopy",
      "chemical_distillation"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Gas Composition Analysis",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Measure components of a gas mixture using calibrated separation or spectral response",
    "effects": {},
    "production_contract": "Sampling equipment, references and trained analysts; consume named material lots, samples, installed tooling, work and specified power through real downstream production.",
    "production_items": [
      "assayed_producer_gas"
    ]
  },
  {
    "id": "additive_step_polymerization",
    "name": "Additive Step Polymerization",
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
        "label": "Additive Step Polymerization",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Join functional molecules through qualified step reactions without a required small-molecule elimination",
    "effects": {},
    "production_items": [
      "addition_cured_belt_web"
    ],
    "production_contract": "Consumes separately produced polyol and diisocyanate feeds, cloth reinforcement, reaction work and cooling to form a dry-interior belt web. Cutting/splicing under belt-transmission knowledge supplies actual workshop maintenance belts; no universal resin or free strength effect."
  },
  {
    "id": "ethylene_oxide_synthesis",
    "name": "Ethylene Oxide Synthesis",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "industrial_catalyst_design",
      "chemical_distillation",
      "experimental_controls"
    ],
    "requires_all": [
      "industrial_catalyst_design",
      "chemical_distillation",
      "experimental_controls"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Ethylene Oxide Synthesis",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Oxidize qualified ethene over a separately qualified supported silver catalyst and separate ethylene oxide from competing reaction products.",
    "effects": {},
    "production_items": [
      "separated_ethylene_oxide"
    ],
    "production_contract": "Pay named ethene and oxygen feeds, reaction/cooling capacity, catalyst preparation and replacement, separation work and product checks; retain competing oxidation and rejected fractions.; named feedstocks and finite paid operating inputs are required. Imported material does not confer synthesis mastery."
  },
  {
    "id": "ethylene_glycol_hydrolysis",
    "name": "Ethylene Glycol Hydrolysis",
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
        "label": "Ethylene Glycol Hydrolysis",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "React a defined ethylene-oxide feed with water and separate monoethylene glycol from the resulting product mixture.",
    "effects": {},
    "production_items": [
      "separated_ethylene_glycol"
    ],
    "production_contract": "Pay actual oxide, water, controlled reaction and separation work, heat/cooling and grade checks; retain higher-glycol fractions and losses rather than claiming complete selective conversion.; named feedstocks and finite paid operating inputs are required. Imported material does not confer synthesis mastery."
  },
  {
    "id": "coal_light_oil_recovery",
    "name": "Coal Light-oil Recovery",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "coke_firing",
      "fractional_distillation"
    ],
    "requires_all": [
      "coke_firing",
      "fractional_distillation"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Coal Light-oil Recovery",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Capture coke-making byproduct streams and separate a light aromatic fraction from other condensates and gas.",
    "effects": {},
    "production_items": [
      "coal_light_oil",
      "separated_toluene"
    ],
    "production_contract": "Pay suitable coal, capture and separation equipment, cooling, heat and work; conserve paid coal across coke and recovered fractions with unrecovered residues.; named feedstocks and finite paid operating inputs are required. Imported material does not confer synthesis mastery."
  },
  {
    "id": "aromatic_nitration",
    "name": "Aromatic Nitration",
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
        "label": "Aromatic Nitration",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Convert a specified aromatic feed through a controlled nitration pathway and qualify its intended intermediate fraction.",
    "effects": {},
    "production_items": [
      "controlled_aromatic_nitration"
    ],
    "production_contract": "Pay named aromatic feed, prepared acid reagents, contained reaction/cooling capacity, separation and assay work; retain spent reagents and rejected fractions.; named feedstocks and finite paid operating inputs are required. Imported material does not confer synthesis mastery."
  },
  {
    "id": "aromatic_amine_hydrogenation",
    "name": "Aromatic Amine Hydrogenation",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "industrial_catalyst_design",
      "pressure_vessels"
    ],
    "requires_all": [
      "industrial_catalyst_design",
      "pressure_vessels"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Aromatic Amine Hydrogenation",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Reduce a named nitroaromatic intermediate with supplied hydrogen and a reaction-qualified catalyst into its corresponding amine feed.",
    "effects": {},
    "production_items": [
      "aromatic_amine_feed"
    ],
    "production_contract": "Pay characterized feed, hydrogen, catalyst preparation/replacement, controlled reactor capacity, separation and sample work; retain side products and grade failures.; named feedstocks and finite paid operating inputs are required. Imported material does not confer synthesis mastery."
  },
  {
    "id": "isocyanate_synthesis",
    "name": "Isocyanate Synthesis",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "chemical_distillation",
      "pressure_vessels",
      "experimental_controls"
    ],
    "requires_all": [
      "chemical_distillation",
      "pressure_vessels",
      "experimental_controls"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Isocyanate Synthesis",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Convert a defined amine with separately prepared industrial carbonylation feeds into the selected isocyanate product and separate residual material.",
    "effects": {},
    "production_items": [
      "qualified_isocyanate_feed"
    ],
    "production_contract": "Pay named amine and compatible carbonylation inputs, contained conversion and cooling capacity, separation, quality checks and residue handling; retain finite yield and losses.; named feedstocks and finite paid operating inputs are required. Imported material does not confer synthesis mastery."
  }
]
