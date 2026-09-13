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
      "ldpe_molding_grade",
      "ldpe_blow_grade",
      "polypropylene_molding_grade"
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
      "purified_ethene_feed",
      "qualified_cationic_c4_feed",
      "purified_propene_feed"
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
      "injected_telephone_covers",
      "injected_wash_bottle_closures",
      "injected_pp_wash_closures"
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
      "qualified_nickel_hydrogenation_catalyst",
      "formed_alumina_supports",
      "formed_ethene_catalyst",
      "anhydrous_aluminum_chloride",
      "refined_alumina_supports",
      "catalyst_ethyl_chloride",
      "ethylaluminum_cocatalyst",
      "purified_titanium_chloride",
      "reduced_titanium_catalyst"
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
      "enzyme_bated_hides",
      "wash_bottle_bating_assay"
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
      "ring_opened_peg_diol",
      "controlled_chain_peg"
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
      "addition_cured_belt_web",
      "recovered_blend_belt_web",
      "recovered_blend_drive_belts"
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
  },
  {
    "id": "polymer_blow_molding",
    "name": "Polymer Blow Molding",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "polymer_melt_rheology",
      "compressed_air_systems"
    ],
    "requires_all": [
      "polymer_melt_rheology",
      "compressed_air_systems"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Polymer Blow Molding",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Expand a qualified polymer preform against a mold through controlled pressure",
    "effects": {},
    "production_contract": "Qualified parison resin, compressed air, mold tooling and power produce hollow rinse-bottle bodies. Separately molded closures and leak testing produce water dispensers used in paid enzyme assays. No pressure-vessel, sterile, hot-liquid or universal-solvent qualification.",
    "production_items": [
      "blown_wash_bottle_bodies",
      "assembled_water_wash_bottles",
      "pp_closure_wash_bottles"
    ]
  },
  {
    "id": "polymer_solution_processing",
    "name": "Polymer Solution Processing",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "polymer_chain_models",
      "chemical_distillation"
    ],
    "requires_all": [
      "polymer_chain_models",
      "chemical_distillation"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Polymer Solution Processing",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Form and recover qualified polymer material through controlled dissolution and solvent handling",
    "effects": {},
    "production_contract": "Qualified water-soluble PEG binder is dissolved, applied to alumina powder and dried into pressable granules. Condensate remains a typed process stream, not potable water. Paid forming, binder removal and catalyst qualification supply real oxidation operations.",
    "production_items": [
      "qualified_peg_binder",
      "aqueous_peg_binder",
      "recovered_water_peg_binder",
      "dried_peg_alumina_granules",
      "size_qualified_peg_binder"
    ]
  },
  {
    "id": "polymer_solvent_recovery",
    "name": "Polymer Solvent Recovery",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "polymer_solution_processing",
      "fractional_distillation"
    ],
    "requires_all": [
      "polymer_solution_processing",
      "fractional_distillation"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Polymer Solvent Recovery",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Recover suitable solvent from a characterized polymer-process stream",
    "effects": {},
    "production_contract": "Separates a typed PEG dryer condensate with finite yield, fuel, power and quality-control work. Recovered water can only replace make-up water in the compatible binder recipe; it does not grant drinking-water or general solvent stock.",
    "production_items": [
      "recovered_peg_process_water"
    ]
  },
  {
    "id": "polymer_molecular_weight_control",
    "name": "Polymer Molecular-Weight Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "polymer_chain_models",
      "measurement_uncertainty"
    ],
    "requires_all": [
      "polymer_chain_models",
      "measurement_uncertainty"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Polymer Molecular-Weight Control",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Characterize and control the distribution of polymer chain sizes",
    "effects": {},
    "production_contract": "Assay and meter a finite starter stock, then characterize a separately synthesized PEG batch against reference material. Controlled synthesis still requires ring-opening knowledge and operating reactor/cooling services. Application testing remains separate; this does not certify arbitrary stock or grant monodispersity.",
    "production_items": [
      "metered_peg_starter",
      "characterized_controlled_peg"
    ]
  },
  {
    "id": "polymer_additive_formulation",
    "name": "Polymer-Additive Formulation",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "thermoplastic_processing",
      "experimental_controls"
    ],
    "requires_all": [
      "thermoplastic_processing",
      "experimental_controls"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Polymer-Additive Formulation",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Assess modifiers against declared material properties and exposure conditions",
    "effects": {},
    "production_contract": "Finite screened carbonate and LDPE feed a tested formulation. Gas expansion and destructive cell/compression qualification produce enclosed insulation panels; cold storage still requires refrigeration machinery, operators, power and maintenance. No structural, fireproof or universal polymer-grade claim.",
    "production_items": [
      "polymer_carbonate_filler",
      "formulated_foam_ldpe",
      "polybutene_panel_sealant"
    ]
  },
  {
    "id": "polymer_foam_cell_control",
    "name": "Polymer Foam Cell Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "polymer_additive_formulation",
      "polymer_melt_rheology"
    ],
    "requires_all": [
      "polymer_additive_formulation",
      "polymer_melt_rheology"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Polymer Foam Cell Control",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Control and measure cell structure in a qualified expanded polymer material",
    "effects": {},
    "production_contract": "Finite screened carbonate and LDPE feed a tested formulation. Gas expansion and destructive cell/compression qualification produce enclosed insulation panels; cold storage still requires refrigeration machinery, operators, power and maintenance. No structural, fireproof or universal polymer-grade claim.",
    "production_items": [
      "expanded_ldpe_foam",
      "qualified_ldpe_foam",
      "foam_cold_store_panels",
      "polybutene_sealed_cold_panels",
      "exposure_tested_cold_panels",
      "aluminum_faced_cold_panels"
    ],
    "operating_plants": [
      "foam_insulated_cold_store"
    ]
  },
  {
    "id": "selective_polymer_depolymerization",
    "name": "Selective Polymer Depolymerization",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "polymer_chain_models",
      "industrial_catalyst_design"
    ],
    "requires_all": [
      "polymer_chain_models",
      "industrial_catalyst_design"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Selective Polymer Depolymerization",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Deconstruct a specified polymer into qualified recoverable intermediates through a selected process",
    "effects": {},
    "production_contract": "Clean virgin-route PU belt offcuts undergo paid glycolysis and separation. The recovered mixture is kept distinct from virgin PEG and is qualified only as a limited blend with fresh material. Recovered-blend cutting waste is not automatically accepted by this once-recycled feed specification.",
    "production_items": [
      "pu_offcut_glycolysis",
      "qualified_recovered_pu_blend"
    ]
  },
  {
    "id": "ionic_chain_polymerization",
    "name": "Ionic Chain Polymerization",
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
        "label": "Ionic Chain Polymerization",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Build polymer chains through qualified ionic active centers under controlled conditions",
    "effects": {},
    "production_contract": "Qualified mixed C4 feed and dry Lewis-acid reagent undergo controlled cationic chain growth with paid heat removal and catalyst separation. Low-molecular-weight polybutene supplies a qualified panel sealant, not high-molecular-weight rubber or pure polyisobutylene.",
    "production_items": [
      "cationic_polybutene"
    ]
  },
  {
    "id": "polymer_weathering_trials",
    "name": "Polymer Weathering Trials",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "polymer_additive_formulation",
      "statistical_inference"
    ],
    "requires_all": [
      "polymer_additive_formulation",
      "statistical_inference"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Polymer Weathering Trials",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Measure property changes under specified light, moisture and temperature exposure",
    "effects": {},
    "production_contract": "Reserves a finite sealant specimen batch and requires thirty distinct observed exposure days with paid operators and power. Qualification remains bounded to that exposure; it does not grant indefinite service life. Tested material feeds a separate panel assembly recipe.",
    "production_items": [
      "exposed_panel_sealant"
    ]
  },
  {
    "id": "alumina_refining",
    "name": "Alumina Refining",
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
        "label": "Alumina Refining",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Separate a qualified aluminum-oxide feed from suitable mineral sources",
    "effects": {},
    "production_contract": "Finite recognized bauxite is digested, separated, precipitated and calcined with paid chemical plant, water, reagents, fuel and power. Refined alumina supplies separately formed and qualified catalyst supports.",
    "production_items": [
      "bauxite_alumina_refining",
      "electrolysis_grade_aluminum_chloride"
    ]
  },
  {
    "id": "aluminum_electrolysis",
    "name": "Aluminum Electrolysis",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "alumina_refining",
      "electrical_generators",
      "electrochemical_cells"
    ],
    "requires_all": [
      "alumina_refining",
      "electrical_generators",
      "electrochemical_cells"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Aluminum Electrolysis",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Reduce qualified alumina to aluminum through a maintained electrolytic process",
    "effects": {},
    "production_contract": "A purified aluminum-chloride feed is electrolyzed in a paid mixed sodium/potassium-chloride bath with graphite apparatus, substantial electrical demand and finite make-up salts. Metal and captured chlorine appear only on completion. This is a chloride-route implementation, not an assumed fluoride bath.",
    "production_items": [
      "chloride_aluminum_electrolysis"
    ]
  },
  {
    "id": "coordination_polymerization",
    "name": "Coordination Polymerization",
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
        "label": "Coordination Polymerization",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Use a qualified coordination catalyst system to control chain growth and selected structure",
    "effects": {},
    "production_contract": "Qualified propene and separately prepared titanium/alkylaluminum catalysts produce a raw polypropylene batch with finite cooling, work and chemical supply. Paid spectral characterization remains separate from rheological/application qualification. Raw resin does not grant a universal forming grade.",
    "production_items": [
      "coordination_polypropylene",
      "controlled_propene_ethene_copolymer"
    ]
  },
  {
    "id": "polymer_tacticity_characterization",
    "name": "Polymer Tacticity Characterization",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "coordination_polymerization",
      "spectroscopy"
    ],
    "requires_all": [
      "coordination_polymerization",
      "spectroscopy"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Polymer Tacticity Characterization",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Measure stereochemical ordering in a qualified polymer against a defined analytical method",
    "effects": {},
    "production_contract": "Qualified propene and separately prepared titanium/alkylaluminum catalysts produce a raw polypropylene batch with finite cooling, work and chemical supply. Paid spectral characterization remains separate from rheological/application qualification. Raw resin does not grant a universal forming grade.",
    "production_items": [
      "spectrally_qualified_polypropylene"
    ]
  },
  {
    "id": "copolymer_sequence_control",
    "name": "Copolymer Sequence Control",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "polymer_molecular_weight_control"
    ],
    "requires_all": [
      "polymer_molecular_weight_control"
    ],
    "requires_any": [
      [
        "radical_chain_polymerization",
        "ionic_chain_polymerization",
        "coordination_polymerization"
      ]
    ],
    "learning_routes": [
      {
        "id": "local",
        "label": "Copolymer Sequence Control",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Control and characterize incorporation of different monomer units within a specified copolymer",
    "effects": {},
    "production_contract": "Metered mixed monomers supply a separate copolymer synthesis route. Raw composition alone does not establish sequence: sequence-sensitive analytical qualification and an application consumer remain required before family acceptance.",
    "production_items": [
      "metered_propene_ethene_feed"
    ]
  },
  {
    "id": "nuclear_magnetic_resonance_spectroscopy",
    "name": "Nuclear Magnetic Resonance Spectroscopy",
    "direction": "Materials",
    "day": 0,
    "chance": 0.002,
    "requires": [
      "atomic_physics",
      "spectroscopy",
      "resonant_tuned_circuits",
      "precision_thermometry"
    ],
    "requires_all": [
      "atomic_physics",
      "spectroscopy",
      "resonant_tuned_circuits",
      "precision_thermometry"
    ],
    "requires_any": [],
    "learning_routes": [
      {
        "id": "local",
        "label": "Nuclear Magnetic Resonance Spectroscopy",
        "requires_all": []
      }
    ],
    "signals": [
      "crafting",
      "materials",
      "research"
    ],
    "observation": "Observe radio-frequency responses of selected nuclear spins in a stable magnetic field to distinguish resolved chemical environments.",
    "effects": {},
    "production_items": [
      "nmr_field_assembly",
      "nmr_probe_receiver",
      "nmr_bench_assembly",
      "nmr_methanol_reference"
    ],
    "production_contract": "Physical field and RF/thermal assemblies consume real capital, work and energy. The installed bench supplies unqualified instrument time only; reference qualification, sample-specific resolved spectra and downstream grade acceptance remain required."
  }
]
