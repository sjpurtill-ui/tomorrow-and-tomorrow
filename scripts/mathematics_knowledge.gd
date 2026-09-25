extends RefCounted
## Individually authored mathematical capabilities and optional model-assisted routes.
const MODELS={
  "geometric_survey": {
    "requires": [
      "similar_triangles"
    ],
    "label": "Geometric construction and similarity"
  },
  "regional_maps": {
    "requires": [
      "trigonometry",
      "coordinate_geometry"
    ],
    "label": "Calculated coordinate mapping"
  },
  "precision_thermometry": {
    "requires": [
      "measurement_uncertainty"
    ],
    "label": "Quantified calibration uncertainty"
  },
  "electrical_measurement": {
    "requires": [
      "dimensional_analysis"
    ],
    "label": "Dimensionally checked measurement models"
  },
  "structural_load_testing": {
    "requires": [
      "vector_analysis",
      "matrix_algebra"
    ],
    "label": "Calculated force and displacement models"
  },
  "aerodynamics": {
    "requires": [
      "differential_equations",
      "vector_analysis"
    ],
    "label": "Mathematical flow models"
  },
  "wind_tunnel_testing": {
    "requires": [
      "dimensional_analysis",
      "statistical_sampling"
    ],
    "label": "Scaled and sampled tunnel experiments"
  },
  "heat_engine_cycles": {
    "requires": [
      "integral_calculus",
      "logarithms"
    ],
    "label": "Calculated cycle relationships"
  },
  "spectroscopy": {
    "requires": [
      "harmonic_analysis"
    ],
    "label": "Harmonic signal analysis"
  },
  "neutron_moderation": {
    "requires": [
      "probability_theory",
      "numerical_integration"
    ],
    "label": "Statistical transport calculations"
  },
  "precision_machinery": {
    "requires": [
      "dimensional_metrology"
    ],
    "label": "Calibrated precision standards"
  },
  "mechanical_refrigeration": {
    "requires": [
      "constrained_optimization"
    ],
    "label": "Constrained refrigeration design"
  },
  "statistical_inference": {
    "requires": [
      "statistical_sampling",
      "least_squares_estimation"
    ],
    "label": "Sampling and fitted statistical models"
  },
  "crystallography": {
    "requires": [
      "coordinate_geometry",
      "matrix_algebra"
    ],
    "label": "Coordinate and symmetry models"
  },
  "band_theory": {
    "requires": [
      "complex_numbers",
      "harmonic_analysis"
    ],
    "label": "Mathematical wave models"
  }
}
static func entries()->Array[Dictionary]:
	return [
	  {
	    "id": "fractional_quantities",
	    "name": "Fractional Quantities",
	    "direction": "Information",
	    "day": 600,
	    "chance": 0.002,
	    "requires": [
	      "tallies",
	      "standard_measures"
	    ],
	    "requires_all": [
	      "tallies",
	      "standard_measures"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Parts of a measured whole are named and compared so shares and remainders can be recorded.",
	    "effects": {},
	    "foundation_for": [
	      "ratio_proportion",
	      "outflow_water_clock"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "ratio_proportion",
	    "name": "Ratios and Proportions",
	    "direction": "Information",
	    "day": 1800,
	    "chance": 0.002,
	    "requires": [
	      "fractional_quantities"
	    ],
	    "requires_all": [
	      "fractional_quantities"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Equivalent ratios connect mixtures, scale, exchange and measured quantities.",
	    "effects": {},
	    "foundation_for": [
	      "similar_triangles",
	      "dimensional_analysis"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "straightedge_compass",
	    "name": "Straightedge and Compass Construction",
	    "direction": "Information",
	    "day": 2400,
	    "chance": 0.002,
	    "requires": [
	      "cordage",
	      "standard_measures"
	    ],
	    "requires_all": [
	      "cordage",
	      "standard_measures"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Lines and circles generate repeatable geometric constructions without relying on a drawing by eye.",
	    "effects": {},
	    "foundation_for": [
	      "similar_triangles",
	      "demonstrated_geometry"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "similar_triangles",
	    "name": "Similar Triangles",
	    "direction": "Information",
	    "day": 5200,
	    "chance": 0.002,
	    "requires": [
	      "straightedge_compass",
	      "ratio_proportion"
	    ],
	    "requires_all": [
	      "straightedge_compass",
	      "ratio_proportion"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Corresponding sides of equal-angle triangles permit indirect measurement across inaccessible distances.",
	    "effects": {},
	    "foundation_for": [
	      "trigonometry",
	      "geometric_survey"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "trigonometry",
	    "name": "Trigonometric Methods",
	    "direction": "Information",
	    "day": 15000,
	    "chance": 0.002,
	    "requires": [
	      "similar_triangles",
	      "place_value"
	    ],
	    "requires_all": [
	      "similar_triangles",
	      "place_value"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Tabulated relationships between angles and side lengths support calculations of height, direction and distance.",
	    "effects": {},
	    "foundation_for": [
	      "vector_analysis",
	      "harmonic_analysis",
	      "regional_maps"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "symbolic_algebra",
	    "name": "Symbolic Algebra",
	    "direction": "Information",
	    "day": 16000,
	    "chance": 0.002,
	    "requires": [
	      "place_value",
	      "fractional_quantities"
	    ],
	    "requires_all": [
	      "place_value",
	      "fractional_quantities"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Unknown quantities are represented and manipulated while preserving the equality of expressions.",
	    "effects": {},
	    "foundation_for": [
	      "coordinate_geometry",
	      "matrix_algebra",
	      "dimensional_analysis"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "polynomial_equations",
	    "name": "Polynomial Equations",
	    "direction": "Information",
	    "day": 21000,
	    "chance": 0.002,
	    "requires": [
	      "symbolic_algebra"
	    ],
	    "requires_all": [
	      "symbolic_algebra"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Powers of unknown quantities are organized into equations whose roots describe possible solutions.",
	    "effects": {},
	    "foundation_for": [
	      "complex_numbers",
	      "numerical_root_finding"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "logarithms",
	    "name": "Logarithms",
	    "direction": "Information",
	    "day": 32000,
	    "chance": 0.002,
	    "requires": [
	      "ratio_proportion",
	      "symbolic_algebra"
	    ],
	    "requires_all": [
	      "ratio_proportion",
	      "symbolic_algebra"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Multiplicative relationships are represented on additive scales for calculation and comparison.",
	    "effects": {},
	    "foundation_for": [
	      "heat_engine_cycles"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "coordinate_geometry",
	    "name": "Coordinate Geometry",
	    "direction": "Information",
	    "day": 35000,
	    "chance": 0.002,
	    "requires": [
	      "symbolic_algebra",
	      "straightedge_compass"
	    ],
	    "requires_all": [
	      "symbolic_algebra",
	      "straightedge_compass"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Numerical coordinates connect geometric shapes to equations and measured positions.",
	    "effects": {},
	    "foundation_for": [
	      "differential_calculus",
	      "vector_analysis",
	      "regional_maps",
	      "crystallography"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "differential_calculus",
	    "name": "Differential Calculus",
	    "direction": "Information",
	    "day": 41000,
	    "chance": 0.002,
	    "requires": [
	      "coordinate_geometry",
	      "polynomial_equations"
	    ],
	    "requires_all": [
	      "coordinate_geometry",
	      "polynomial_equations"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Limiting changes describe instantaneous rates, local slopes and sensitivity to variation.",
	    "effects": {},
	    "foundation_for": [
	      "differential_equations",
	      "vector_analysis",
	      "constrained_optimization"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "integral_calculus",
	    "name": "Integral Calculus",
	    "direction": "Information",
	    "day": 42000,
	    "chance": 0.002,
	    "requires": [
	      "coordinate_geometry",
	      "fractional_quantities"
	    ],
	    "requires_all": [
	      "coordinate_geometry",
	      "fractional_quantities"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Accumulations are described by limits of sums, connecting local variation with total quantities.",
	    "effects": {},
	    "foundation_for": [
	      "differential_equations",
	      "numerical_integration",
	      "harmonic_analysis",
	      "heat_engine_cycles"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "differential_equations",
	    "name": "Differential Equations",
	    "direction": "Information",
	    "day": 46000,
	    "chance": 0.002,
	    "requires": [
	      "differential_calculus",
	      "integral_calculus"
	    ],
	    "requires_all": [
	      "differential_calculus",
	      "integral_calculus"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Relations involving rates of change describe evolving mechanical and physical systems.",
	    "effects": {},
	    "foundation_for": [
	      "aerodynamics"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "complex_numbers",
	    "name": "Complex Numbers",
	    "direction": "Information",
	    "day": 34000,
	    "chance": 0.002,
	    "requires": [
	      "polynomial_equations"
	    ],
	    "requires_all": [
	      "polynomial_equations"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "An extended number system represents solutions and transformations unavailable on the real number line.",
	    "effects": {},
	    "foundation_for": [
	      "harmonic_analysis",
	      "band_theory"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "vector_analysis",
	    "name": "Vector Analysis",
	    "direction": "Information",
	    "day": 52000,
	    "chance": 0.002,
	    "requires": [
	      "coordinate_geometry",
	      "trigonometry",
	      "differential_calculus"
	    ],
	    "requires_all": [
	      "coordinate_geometry",
	      "trigonometry",
	      "differential_calculus"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Magnitude and direction are combined in calculations of forces, motion and changing fields.",
	    "effects": {},
	    "foundation_for": [
	      "structural_load_testing",
	      "aerodynamics"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "matrix_algebra",
	    "name": "Matrix Algebra",
	    "direction": "Information",
	    "day": 51000,
	    "chance": 0.002,
	    "requires": [
	      "symbolic_algebra",
	      "place_value"
	    ],
	    "requires_all": [
	      "symbolic_algebra",
	      "place_value"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Rectangular arrays organize coupled linear equations and transformations.",
	    "effects": {},
	    "foundation_for": [
	      "least_squares_estimation",
	      "structural_load_testing",
	      "crystallography"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "combinatorics",
	    "name": "Combinatorial Counting",
	    "direction": "Information",
	    "day": 19000,
	    "chance": 0.002,
	    "requires": [
	      "place_value",
	      "tallies"
	    ],
	    "requires_all": [
	      "place_value",
	      "tallies"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Arrangements and selections are counted without listing every possibility.",
	    "effects": {},
	    "foundation_for": [
	      "binomial_coefficient_triangle"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "probability_theory",
	    "name": "Probability Theory",
	    "direction": "Information",
	    "day": 36000,
	    "chance": 0.002,
	    "requires": [
	      "combinatorics",
	      "fractional_quantities"
	    ],
	    "requires_all": [
	      "combinatorics",
	      "fractional_quantities"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Uncertain outcomes are represented by coherent numerical likelihoods rather than single predictions.",
	    "effects": {},
	    "foundation_for": [
	      "statistical_sampling",
	      "measurement_uncertainty",
	      "neutron_moderation"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "statistical_sampling",
	    "name": "Statistical Sampling",
	    "direction": "Information",
	    "day": 50000,
	    "chance": 0.002,
	    "requires": [
	      "probability_theory"
	    ],
	    "requires_all": [
	      "probability_theory"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Selected observations are used to estimate a larger population while accounting for sampling variation.",
	    "effects": {},
	    "foundation_for": [
	      "wind_tunnel_testing",
	      "statistical_inference"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations.",
	    "requires_any": [
	      [
	        "census_rolls",
	        "case_records"
	      ]
	    ]
	  },
	  {
	    "id": "least_squares_estimation",
	    "name": "Least-Squares Estimation",
	    "direction": "Information",
	    "day": 53000,
	    "chance": 0.002,
	    "requires": [
	      "matrix_algebra",
	      "measurement_uncertainty"
	    ],
	    "requires_all": [
	      "matrix_algebra",
	      "measurement_uncertainty"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Model parameters are fitted to observations by minimizing squared residual differences.",
	    "effects": {},
	    "foundation_for": [
	      "statistical_inference"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "measurement_uncertainty",
	    "name": "Measurement Uncertainty",
	    "direction": "Information",
	    "day": 48000,
	    "chance": 0.002,
	    "requires": [
	      "probability_theory",
	      "standard_measures"
	    ],
	    "requires_all": [
	      "probability_theory",
	      "standard_measures"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Measured values are reported with assessed uncertainty from instruments, procedures and repeated observations.",
	    "effects": {},
	    "foundation_for": [
	      "least_squares_estimation",
	      "dimensional_metrology",
	      "precision_thermometry"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "dimensional_analysis",
	    "name": "Dimensional Analysis",
	    "direction": "Information",
	    "day": 50000,
	    "chance": 0.002,
	    "requires": [
	      "ratio_proportion",
	      "symbolic_algebra",
	      "standard_measures"
	    ],
	    "requires_all": [
	      "ratio_proportion",
	      "symbolic_algebra",
	      "standard_measures"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Physical equations are checked and scaled using dimensions and dimensionless relationships.",
	    "effects": {},
	    "foundation_for": [
	      "electrical_measurement",
	      "wind_tunnel_testing"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "numerical_root_finding",
	    "name": "Numerical Root Finding",
	    "direction": "Information",
	    "day": 37000,
	    "chance": 0.002,
	    "requires": [
	      "polynomial_equations",
	      "place_value"
	    ],
	    "requires_all": [
	      "polynomial_equations",
	      "place_value"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Successive numerical approximations locate equation solutions that lack a convenient exact expression.",
	    "effects": {},
	    "foundation_for": [
	      "constrained_optimization"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "numerical_integration",
	    "name": "Numerical Integration",
	    "direction": "Information",
	    "day": 49000,
	    "chance": 0.002,
	    "requires": [
	      "integral_calculus",
	      "place_value"
	    ],
	    "requires_all": [
	      "integral_calculus",
	      "place_value"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Weighted samples approximate accumulated quantities when direct symbolic integration is impractical.",
	    "effects": {},
	    "foundation_for": [
	      "neutron_moderation"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "constrained_optimization",
	    "name": "Constrained Optimization",
	    "direction": "Information",
	    "day": 58000,
	    "chance": 0.002,
	    "requires": [
	      "differential_calculus",
	      "numerical_root_finding"
	    ],
	    "requires_all": [
	      "differential_calculus",
	      "numerical_root_finding"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Design choices are compared against an objective while respecting explicit limits on available quantities.",
	    "effects": {},
	    "foundation_for": [
	      "mechanical_refrigeration"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "harmonic_analysis",
	    "name": "Harmonic Analysis",
	    "direction": "Information",
	    "day": 55000,
	    "chance": 0.002,
	    "requires": [
	      "complex_numbers",
	      "trigonometry",
	      "integral_calculus"
	    ],
	    "requires_all": [
	      "complex_numbers",
	      "trigonometry",
	      "integral_calculus"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Signals and spatial patterns are decomposed into oscillating components for analysis.",
	    "effects": {},
	    "foundation_for": [
	      "spectroscopy",
	      "band_theory"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  },
	  {
	    "id": "dimensional_metrology",
	    "name": "Precision Dimensional Metrology",
	    "direction": "Information",
	    "day": 54000,
	    "chance": 0.002,
	    "requires": [
	      "measurement_uncertainty",
	      "geometric_survey",
	      "workshop_standards"
	    ],
	    "requires_all": [
	      "measurement_uncertainty",
	      "geometric_survey",
	      "workshop_standards"
	    ],
	    "signals": [
	      "information",
	      "research",
	      "crafting"
	    ],
	    "observation": "Reference standards, calibrated instruments and uncertainty budgets make small dimensions comparable between workshops.",
	    "effects": {},
	    "foundation_for": [
	      "precision_machinery"
	    ],
	    "production_contract": "Provides the named mathematical foundations for downstream knowledge and model-assisted investigations. It creates no physical equipment and does not replace practical foundations."
	  }
	]

static func apply(entry:Dictionary)->Dictionary:
	if not MODELS.has(String(entry.id)):return entry
	var original:Array=entry.get("learning_routes",[]).duplicate(true)
	# Existing empirical approaches and their common AND/OR foundations remain.
	if original.is_empty():original=[{"id":"local","label":"Local practice","requires_all":entry.get("requires",[]).duplicate()}]
	var result:Array=original.duplicate(true)
	for route:Dictionary in original:
		if String(route.id).begins_with("mathematical:"):continue
		var id:="mathematical:"+String(route.id)
		var present:=false
		for existing:Dictionary in result:
			if existing.id==id:present=true;break
		if present:continue
		var model:Dictionary=route.duplicate(true)
		model.id=id;model.label=String(MODELS[String(entry.id)].label)+" · "+String(route.get("label","local practice"))
		model["requires_all"]=route.get("requires_all",route.get("requires",[])).duplicate()
		model.requires_all.append_array(MODELS[String(entry.id)].requires)
		model["progress_multiplier"]=float(route.get("progress_multiplier",1.0))*1.2
		result.append(model)
	entry["learning_routes"]=result
	return entry
