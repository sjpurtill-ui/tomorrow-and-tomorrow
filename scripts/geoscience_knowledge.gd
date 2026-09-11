extends RefCounted
## Individually authored field and interpretive methods, not generated variants.
const GROUPS=["identification","mapping","sampling","interpretation","estimation"]
const MAX_IMPROVEMENT:=0.75
static func entries()->Array[Dictionary]:
	return [
	  {
	    "id": "mineral_streak_tests",
	    "name": "Mineral Streak Tests",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "stone_sorting",
	      "pit_firing"
	    ],
	    "requires_all": [
	      "stone_sorting",
	      "pit_firing"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "Powder rubbed onto a consistent pale surface reveals diagnostic colors that weathered outer faces can conceal.",
	    "method": "Compare fresh surfaces and powder streaks from several samples before assigning a mineral identity.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "identification",
	      "resources": [
	        "Iron Ore",
	        "Copper Ore",
	        "Lead Ore",
	        "Graphite",
	        "Sulfur"
	      ],
	      "recognition": 0.12,
	      "survey": 0.04
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  },
	  {
	    "id": "mineral_cleavage",
	    "name": "Cleavage and Fracture Classification",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "stone_sorting",
	      "quarry_reading"
	    ],
	    "requires_all": [
	      "stone_sorting",
	      "quarry_reading"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "Repeated breaks distinguish flat cleavage planes from irregular and conchoidal fractures.",
	    "method": "Record how fresh pieces split and compare those patterns across outcrops.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "identification",
	      "resources": [
	        "Stone",
	        "Flint",
	        "Limestone",
	        "Graphite"
	      ],
	      "recognition": 0.1,
	      "survey": 0.08
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  },
	  {
	    "id": "comparative_mineral_hardness",
	    "name": "Comparative Mineral Hardness",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "controlled_flaking",
	      "standard_measures"
	    ],
	    "requires_all": [
	      "controlled_flaking",
	      "standard_measures"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "A repeatable scratch sequence separates resistance to scratching from toughness under impact.",
	    "method": "Rank paired scratch tests rather than judging stones by color or how hard they seem to strike.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "identification",
	      "resources": [
	        "Stone",
	        "Flint",
	        "Limestone",
	        "Graphite",
	        "Copper Ore",
	        "Tin Ore",
	        "Lead Ore",
	        "Iron Ore",
	        "Uranium Ore"
	      ],
	      "recognition": 0.12,
	      "survey": 0.06
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  },
	  {
	    "id": "mineral_specific_gravity",
	    "name": "Mineral Specific Gravity",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "fractional_quantities",
	      "standard_measures",
	      "displacement_buoyancy"
	    ],
	    "requires_all": [
	      "fractional_quantities",
	      "standard_measures",
	      "displacement_buoyancy"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "Mass compared with displaced water distinguishes dense ore minerals from visually similar gangue.",
	    "method": "Weigh representative pieces and compare their displacement against the same water reference.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "identification",
	      "resources": [
	        "Copper Ore",
	        "Tin Ore",
	        "Lead Ore",
	        "Iron Ore",
	        "Uranium Ore",
	        "Graphite",
	        "Sulfur"
	      ],
	      "recognition": 0.15,
	      "survey": 0.08
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  },
	  {
	    "id": "relative_stratigraphy",
	    "name": "Relative Stratigraphy",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "quarry_reading",
	      "route_memory"
	    ],
	    "requires_all": [
	      "quarry_reading",
	      "route_memory"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "Superposition and interruptions in layered ground establish an order of deposition without needing absolute dates.",
	    "method": "Trace exposed layers and record which beds overlie or cut across others.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "mapping",
	      "resources": [
	        "Coal",
	        "Clay",
	        "Limestone",
	        "Salt",
	        "Phosphate Rock",
	        "Deep Aquifer",
	        "Peat"
	      ],
	      "recognition": 0.08,
	      "survey": 0.14
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  },
	  {
	    "id": "lithologic_correlation",
	    "name": "Lithologic Correlation",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "relative_stratigraphy",
	      "mineral_cleavage",
	      "regional_maps"
	    ],
	    "requires_all": [
	      "relative_stratigraphy",
	      "mineral_cleavage",
	      "regional_maps"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "Repeated rock assemblages allow separated exposures to be compared without assuming every similar-looking layer is identical.",
	    "method": "Correlate texture, mineral content and neighboring beds across recorded localities.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "mapping",
	      "resources": [
	        "Coal",
	        "Clay",
	        "Limestone",
	        "Salt",
	        "Phosphate Rock",
	        "Deep Aquifer",
	        "Peat",
	        "Copper Ore",
	        "Tin Ore",
	        "Lead Ore",
	        "Iron Ore",
	        "Uranium Ore"
	      ],
	      "recognition": 0.1,
	      "survey": 0.16
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  },
	  {
	    "id": "geologic_cross_sections",
	    "name": "Geologic Cross Sections",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "geometric_survey",
	      "relative_stratigraphy",
	      "similar_triangles"
	    ],
	    "requires_all": [
	      "geometric_survey",
	      "relative_stratigraphy",
	      "similar_triangles"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "Surface positions and layer inclinations can be reconciled in a vertical reconstruction of the ground.",
	    "method": "Draw sections through measured exposures and revise them when new observations disagree.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "mapping",
	      "resources": [
	        "Coal",
	        "Clay",
	        "Limestone",
	        "Salt",
	        "Phosphate Rock",
	        "Deep Aquifer",
	        "Peat",
	        "Copper Ore",
	        "Tin Ore",
	        "Lead Ore",
	        "Iron Ore",
	        "Uranium Ore"
	      ],
	      "recognition": 0.06,
	      "survey": 0.2
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  },
	  {
	    "id": "structural_geologic_mapping",
	    "name": "Structural Geologic Mapping",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "geologic_cross_sections",
	      "trigonometry",
	      "regional_maps"
	    ],
	    "requires_all": [
	      "geologic_cross_sections",
	      "trigonometry",
	      "regional_maps"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "Faults, folds and joint orientations explain why mineralized and water-bearing zones depart from simple horizontal layers.",
	    "method": "Measure orientations and connect structural observations across mapped exposures.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "mapping",
	      "resources": [
	        "Copper Ore",
	        "Tin Ore",
	        "Lead Ore",
	        "Iron Ore",
	        "Uranium Ore",
	        "Stone",
	        "Deep Aquifer"
	      ],
	      "recognition": 0.08,
	      "survey": 0.22
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  },
	  {
	    "id": "sediment_provenance",
	    "name": "Sediment Provenance",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "relative_stratigraphy",
	      "mineral_specific_gravity",
	      "seasonal_patterns"
	    ],
	    "requires_all": [
	      "relative_stratigraphy",
	      "mineral_specific_gravity",
	      "seasonal_patterns"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "Grain composition and transport patterns connect downstream sediment to possible upstream source rocks.",
	    "method": "Compare sorted sediment at successive locations while accounting for transport and seasonal flow.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "sampling",
	      "resources": [
	        "Tin Ore",
	        "Copper Ore",
	        "Iron Ore",
	        "Fine Sand"
	      ],
	      "recognition": 0.16,
	      "survey": 0.08
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  },
	  {
	    "id": "systematic_channel_sampling",
	    "name": "Systematic Channel Sampling",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "ore_assaying",
	      "standard_measures",
	      "geometric_survey"
	    ],
	    "requires_all": [
	      "ore_assaying",
	      "standard_measures",
	      "geometric_survey"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "Continuous measured cuts across an exposure reduce the bias of collecting only its richest-looking fragments.",
	    "method": "Keep sample widths, locations and barren intervals in the record alongside promising assays.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "sampling",
	      "resources": [
	        "Copper Ore",
	        "Tin Ore",
	        "Lead Ore",
	        "Iron Ore",
	        "Uranium Ore",
	        "Coal"
	      ],
	      "recognition": 0.06,
	      "survey": 0.2
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  },
	  {
	    "id": "geochemical_baselines",
	    "name": "Geochemical Baselines",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "chemical_distillation",
	      "statistical_sampling",
	      "systematic_channel_sampling"
	    ],
	    "requires_all": [
	      "chemical_distillation",
	      "statistical_sampling",
	      "systematic_channel_sampling"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "Local background variation must be understood before an unusual concentration can be treated as an exploration clue.",
	    "method": "Compare consistent sample media and analytical procedures across representative background ground.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "interpretation",
	      "resources": [
	        "Copper Ore",
	        "Tin Ore",
	        "Lead Ore",
	        "Iron Ore",
	        "Uranium Ore",
	        "Sulfur",
	        "Phosphate Rock",
	        "Nitrates"
	      ],
	      "recognition": 0.18,
	      "survey": 0.12
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  },
	  {
	    "id": "geochemical_anomaly_mapping",
	    "name": "Geochemical Anomaly Mapping",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "geochemical_baselines",
	      "regional_maps",
	      "measurement_uncertainty"
	    ],
	    "requires_all": [
	      "geochemical_baselines",
	      "regional_maps",
	      "measurement_uncertainty"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "Spatially coherent chemical departures become follow-up targets after background variation and analytical uncertainty are considered.",
	    "method": "Map departures from local baselines and test whether neighboring samples reproduce the pattern.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "interpretation",
	      "resources": [
	        "Copper Ore",
	        "Tin Ore",
	        "Lead Ore",
	        "Iron Ore",
	        "Uranium Ore",
	        "Sulfur",
	        "Phosphate Rock",
	        "Nitrates"
	      ],
	      "recognition": 0.2,
	      "survey": 0.18
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  },
	  {
	    "id": "grade_tonnage_models",
	    "name": "Grade\u2013Tonnage Models",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "ore_assaying",
	      "statistical_sampling",
	      "geologic_cross_sections",
	      "ratio_proportion"
	    ],
	    "requires_all": [
	      "ore_assaying",
	      "statistical_sampling",
	      "geologic_cross_sections",
	      "ratio_proportion"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "Likely grade and deposit size must be considered together rather than extrapolating a rich specimen into an entire orebody.",
	    "method": "Compare measured geometry with distributions from sampled occurrences and retain uncertainty.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "estimation",
	      "resources": [
	        "Copper Ore",
	        "Tin Ore",
	        "Lead Ore",
	        "Iron Ore",
	        "Uranium Ore",
	        "Coal"
	      ],
	      "recognition": 0.04,
	      "survey": 0.24
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  },
	  {
	    "id": "spatial_variograms",
	    "name": "Spatial Variograms",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "statistical_inference",
	      "coordinate_geometry",
	      "systematic_channel_sampling"
	    ],
	    "requires_all": [
	      "statistical_inference",
	      "coordinate_geometry",
	      "systematic_channel_sampling"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "Pairs of spatially separated samples reveal how mineral measurements vary with distance and direction.",
	    "method": "Compare differences between sample pairs over several separation distances and orientations.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "estimation",
	      "resources": [
	        "Copper Ore",
	        "Tin Ore",
	        "Lead Ore",
	        "Iron Ore",
	        "Uranium Ore",
	        "Coal",
	        "Phosphate Rock"
	      ],
	      "recognition": 0.04,
	      "survey": 0.2
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  },
	  {
	    "id": "resource_kriging",
	    "name": "Resource Kriging",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "spatial_variograms",
	      "matrix_algebra",
	      "least_squares_estimation"
	    ],
	    "requires_all": [
	      "spatial_variograms",
	      "matrix_algebra",
	      "least_squares_estimation"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "Spatial covariance allows estimates between samples to carry explicit weights and estimation uncertainty.",
	    "method": "Solve weighted spatial estimates and test them against withheld sample measurements.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "estimation",
	      "resources": [
	        "Copper Ore",
	        "Tin Ore",
	        "Lead Ore",
	        "Iron Ore",
	        "Uranium Ore",
	        "Coal",
	        "Phosphate Rock"
	      ],
	      "recognition": 0.04,
	      "survey": 0.28
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  },
	  {
	    "id": "orebody_block_models",
	    "name": "Orebody Block Models",
	    "direction": "Nature",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "geologic_cross_sections",
	      "resource_kriging",
	      "grade_tonnage_models"
	    ],
	    "requires_all": [
	      "geologic_cross_sections",
	      "resource_kriging",
	      "grade_tonnage_models"
	    ],
	    "signals": [
	      "survey",
	      "materials",
	      "research"
	    ],
	    "observation": "A three-dimensional partition reconciles sampled grades with geologic boundaries and volumes without treating unsampled ground as known ore.",
	    "method": "Estimate bounded blocks, retain uncertain regions and revise the model as sampling proceeds.",
	    "effects": {},
	    "prospecting_profile": {
	      "group": "estimation",
	      "resources": [
	        "Copper Ore",
	        "Tin Ore",
	        "Lead Ore",
	        "Iron Ore",
	        "Uranium Ore",
	        "Coal",
	        "Phosphate Rock"
	      ],
	      "recognition": 0.02,
	      "survey": 0.3
	    },
	    "production_contract": "Improves the effective contribution of assigned Survey workers for the listed resources after adoption. Within each method family only the strongest applicable method contributes; combined improvement is capped at 75%. Does not bypass recognition rules, expose unknown sites, grant access, create stocks or alter reserves."
	  }
	]

static func factors()->Dictionary:
	# Build once per local resource day; never cache across owners or adoption changes.
	if WorldSimulation.state.effective_workers("Survey")<=0:return {}
	var strongest:Dictionary={}
	for id:String in WorldSimulation.state.known_discoveries:
		var entry:Dictionary=WorldSimulation.discovery.catalog_by_id.get(id,{})
		var profile:Dictionary=entry.get("prospecting_profile",{})
		if profile.is_empty():continue
		var adoption:=WorldSimulation.discovery.adoption(id)
		if adoption<=0:continue
		for resource:String in profile.resources:
			if not strongest.has(resource):strongest[resource]={"recognition":{},"survey":{}}
			for phase:String in ["recognition","survey"]:
				var groups:Dictionary=strongest[resource][phase]
				var group:=String(profile.group)
				groups[group]=maxf(float(groups.get(group,0.0)),float(profile.get(phase,0.0))*adoption)
	var result:Dictionary={}
	for resource:String in strongest:
		result[resource]={}
		for phase:String in ["recognition","survey"]:
			var total:=0.0
			for value:float in strongest[resource][phase].values():total+=value
			result[resource][phase]=1.0+minf(MAX_IMPROVEMENT,total)
	return result

static func factor(resource:String,phase:String)->float:
	return float(factors().get(resource,{}).get(phase,1.0))
