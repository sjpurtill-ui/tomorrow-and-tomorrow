extends RefCounted
## Authored mechanical principles connecting empirical practice to engineering.
const MODELS={
  "counterweight_cranes": {
    "requires": [
      "compound_pulleys",
      "centers_of_mass"
    ],
    "label": "Balanced lifting trains"
  },
  "water_mills": {
    "requires": [
      "gear_ratios",
      "flow_continuity"
    ],
    "label": "Matched water flow and gearing"
  },
  "grain_milling": {
    "requires": [
      "bearing_surfaces",
      "flywheel_smoothing"
    ],
    "label": "Steady supported mill drive"
  },
  "precision_machinery": {
    "requires": [
      "lubrication_regimes",
      "crank_linkages"
    ],
    "label": "Controlled motion and bearing films"
  },
  "coastal_watercraft": {
    "requires": [
      "displacement_buoyancy"
    ],
    "label": "Calculated loaded displacement"
  },
  "canal_locks": {
    "requires": [
      "hydrostatic_pressure"
    ],
    "label": "Calculated gate loading"
  },
  "mine_drainage": {
    "requires": [
      "flow_continuity",
      "crank_linkages"
    ],
    "label": "Calculated pump displacement"
  },
  "aerodynamics": {
    "requires": [
      "viscous_resistance",
      "momentum_balance"
    ],
    "label": "Conserved momentum and viscous flow"
  },
  "structural_load_testing": {
    "requires": [
      "stress_strain_relations",
      "column_buckling"
    ],
    "label": "Material response and stability"
  },
  "advanced_airframes": {
    "requires": [
      "cyclic_fatigue",
      "elastic_deformation"
    ],
    "label": "Repeated-load structural assessment"
  },
  "steam_propulsion": {
    "requires": [
      "mechanical_work_energy",
      "feedback_governors"
    ],
    "label": "Governed power transmission"
  },
  "electric_motors": {
    "requires": [
      "rotational_dynamics",
      "bearing_surfaces"
    ],
    "label": "Matched torque and shaft support"
  },
  "wind_tunnel_testing": {
    "requires": [
      "flow_continuity",
      "viscous_resistance"
    ],
    "label": "Flow-consistent test interpretation"
  },
  "safety_lifts": {
    "requires": [
      "compound_pulleys",
      "mechanical_oscillation"
    ],
    "label": "Controlled lifting and transient motion"
  }
}
static func entries()->Array[Dictionary]:
	return [
	  {
	    "id": "lever_moments",
	    "name": "Lever Moments",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "wedges_and_levers",
	      "ratio_proportion"
	    ],
	    "requires_all": [
	      "wedges_and_levers",
	      "ratio_proportion"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Measured lever arms relate balancing loads to their distances from a fulcrum.",
	    "effects": {},
	    "foundation_for": [
	      "centers_of_mass",
	      "compound_pulleys",
	      "mechanical_work_energy"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "centers_of_mass",
	    "name": "Centers of Mass",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "lever_moments",
	      "geometric_survey"
	    ],
	    "requires_all": [
	      "lever_moments",
	      "geometric_survey"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Suspension and balance trials locate the effective point at which a body\u2019s weight acts.",
	    "effects": {},
	    "foundation_for": [
	      "counterweight_cranes"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "compound_pulleys",
	    "name": "Compound Pulleys",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "rope_rigging",
	      "lever_moments"
	    ],
	    "requires_all": [
	      "rope_rigging",
	      "lever_moments"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Multiple moving sheaves exchange a longer rope travel for a smaller lifting force.",
	    "effects": {},
	    "foundation_for": [
	      "counterweight_cranes",
	      "safety_lifts"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "gear_ratios",
	    "name": "Gear Ratios",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "joinery",
	      "ratio_proportion"
	    ],
	    "requires_all": [
	      "joinery",
	      "ratio_proportion"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Counting meshing teeth predicts changes in rotational speed and torque.",
	    "effects": {},
	    "foundation_for": [
	      "crank_linkages",
	      "water_mills"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone. Enables the named physical workshop components; batch materials, setup tooling and finite workshop work are consumed to create them.",
	    "production_items": [
	      "gear_sets"
	    ]
	  },
	  {
	    "id": "crank_linkages",
	    "name": "Crank Linkages",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "gear_ratios",
	      "standard_measures"
	    ],
	    "requires_all": [
	      "gear_ratios",
	      "standard_measures"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Pinned links convert continuous rotation into a controlled reciprocating stroke.",
	    "effects": {},
	    "foundation_for": [
	      "precision_machinery",
	      "mine_drainage"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone. Enables the named physical workshop components; batch materials, setup tooling and finite workshop work are consumed to create them.",
	    "production_items": [
	      "crank_assemblies"
	    ]
	  },
	  {
	    "id": "flywheel_smoothing",
	    "name": "Flywheel Smoothing",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "gear_ratios",
	      "centers_of_mass"
	    ],
	    "requires_all": [
	      "gear_ratios",
	      "centers_of_mass"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "A weighted rotating wheel carries motion between intermittent driving strokes.",
	    "effects": {},
	    "foundation_for": [
	      "grain_milling"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone. Enables the named physical workshop components; batch materials, setup tooling and finite workshop work are consumed to create them.",
	    "production_items": [
	      "flywheels"
	    ]
	  },
	  {
	    "id": "bearing_surfaces",
	    "name": "Bearing Surfaces",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "copper_casting",
	      "workshop_standards"
	    ],
	    "requires_all": [
	      "copper_casting",
	      "workshop_standards"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Replaceable fitted surfaces carry rotating shafts while controlling clearance and wear.",
	    "effects": {},
	    "foundation_for": [
	      "lubrication_regimes",
	      "grain_milling",
	      "electric_motors"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone. Enables the named physical workshop components; batch materials, setup tooling and finite workshop work are consumed to create them.",
	    "production_items": ["bronze_bushed_bearings"]
	  },
	  {
	    "id": "friction_measurement",
	    "name": "Friction Measurement",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "standard_measures",
	      "experimental_controls"
	    ],
	    "requires_all": [
	      "standard_measures",
	      "experimental_controls"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Repeated pull tests distinguish the forces needed to begin and sustain sliding.",
	    "effects": {},
	    "foundation_for": [
	      "lubrication_regimes",
	      "viscous_resistance"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "lubrication_regimes",
	    "name": "Lubrication Regimes",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "bearing_surfaces",
	      "friction_measurement"
	    ],
	    "requires_all": [
	      "bearing_surfaces",
	      "friction_measurement"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Load and speed trials distinguish boundary contact from motion supported by a lubricant film.",
	    "effects": {},
	    "foundation_for": [
	      "precision_machinery"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "displacement_buoyancy",
	    "name": "Displacement and Buoyancy",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "river_craft",
	      "fractional_quantities"
	    ],
	    "requires_all": [
	      "river_craft",
	      "fractional_quantities"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Comparing displaced water with carried weight explains when loaded bodies float.",
	    "effects": {},
	    "foundation_for": [
	      "coastal_watercraft"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "hydrostatic_pressure",
	    "name": "Hydrostatic Pressure",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "water_settling_basins",
	      "standard_measures"
	    ],
	    "requires_all": [
	      "water_settling_basins",
	      "standard_measures"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Water columns reveal that pressure increases with depth and acts on enclosing surfaces.",
	    "effects": {},
	    "foundation_for": [
	      "flow_continuity",
	      "canal_locks"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "flow_continuity",
	    "name": "Flow Continuity",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "hydrostatic_pressure",
	      "ratio_proportion"
	    ],
	    "requires_all": [
	      "hydrostatic_pressure",
	      "ratio_proportion"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Measured flows through changing sections balance incoming and outgoing fluid quantities.",
	    "effects": {},
	    "foundation_for": [
	      "viscous_resistance",
	      "water_mills",
	      "mine_drainage",
	      "wind_tunnel_testing"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "viscous_resistance",
	    "name": "Viscous Resistance",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "flow_continuity",
	      "friction_measurement"
	    ],
	    "requires_all": [
	      "flow_continuity",
	      "friction_measurement"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Controlled passages reveal how fluid viscosity and wall contact oppose motion.",
	    "effects": {},
	    "foundation_for": [
	      "aerodynamics",
	      "wind_tunnel_testing"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "elastic_deformation",
	    "name": "Elastic Deformation",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "standard_measures",
	      "timber_grading"
	    ],
	    "requires_all": [
	      "standard_measures",
	      "timber_grading"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Repeated bending tests separate recoverable shape changes from permanent damage.",
	    "effects": {},
	    "foundation_for": [
	      "stress_strain_relations",
	      "advanced_airframes"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "stress_strain_relations",
	    "name": "Stress\u2013Strain Relations",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "elastic_deformation",
	      "ratio_proportion"
	    ],
	    "requires_all": [
	      "elastic_deformation",
	      "ratio_proportion"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Loads compared with cross section and relative extension characterize material response.",
	    "effects": {},
	    "foundation_for": [
	      "column_buckling",
	      "cyclic_fatigue",
	      "structural_load_testing"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "column_buckling",
	    "name": "Column Buckling",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "stress_strain_relations",
	      "similar_triangles"
	    ],
	    "requires_all": [
	      "stress_strain_relations",
	      "similar_triangles"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Slender loaded members fail by sideways instability before their material is crushed.",
	    "effects": {},
	    "foundation_for": [
	      "structural_load_testing"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "cyclic_fatigue",
	    "name": "Cyclic Fatigue",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "stress_strain_relations",
	      "experimental_controls"
	    ],
	    "requires_all": [
	      "stress_strain_relations",
	      "experimental_controls"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Repeated loading reveals cracks and failure even below a single-load failure threshold.",
	    "effects": {},
	    "foundation_for": [
	      "advanced_airframes"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "measured_kinematics",
	    "name": "Measured Kinematics",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "standard_measures",
	      "tallies"
	    ],
	    "requires_all": [
	      "standard_measures",
	      "tallies"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Repeated position and time measurements distinguish speed from acceleration.",
	    "effects": {},
	    "foundation_for": [
	      "inertial_motion",
	      "mechanical_work_energy",
	      "mechanical_oscillation"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "inertial_motion",
	    "name": "Inertial Motion",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "measured_kinematics",
	      "friction_measurement"
	    ],
	    "requires_all": [
	      "measured_kinematics",
	      "friction_measurement"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Low-resistance motion distinguishes persistence of motion from forces that change it.",
	    "effects": {},
	    "foundation_for": [
	      "momentum_balance"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "momentum_balance",
	    "name": "Momentum Balance",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "inertial_motion",
	      "ratio_proportion"
	    ],
	    "requires_all": [
	      "inertial_motion",
	      "ratio_proportion"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Collision and recoil measurements compare transferred motion across interacting bodies.",
	    "effects": {},
	    "foundation_for": [
	      "rotational_dynamics",
	      "aerodynamics"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "mechanical_work_energy",
	    "name": "Mechanical Work and Energy",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "lever_moments",
	      "measured_kinematics"
	    ],
	    "requires_all": [
	      "lever_moments",
	      "measured_kinematics"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Force acting through distance relates lifting, motion and losses in machines.",
	    "effects": {},
	    "foundation_for": [
	      "steam_propulsion"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "rotational_dynamics",
	    "name": "Rotational Dynamics",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "momentum_balance",
	      "centers_of_mass",
	      "gear_ratios"
	    ],
	    "requires_all": [
	      "momentum_balance",
	      "centers_of_mass",
	      "gear_ratios"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Torque and mass distribution explain changes in angular motion.",
	    "effects": {},
	    "foundation_for": [
	      "feedback_governors",
	      "electric_motors"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "mechanical_oscillation",
	    "name": "Mechanical Oscillation",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "elastic_deformation",
	      "measured_kinematics"
	    ],
	    "requires_all": [
	      "elastic_deformation",
	      "measured_kinematics"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "Pendulums and spring-loaded bodies reveal repeatable periods and damping.",
	    "effects": {},
	    "foundation_for": [
	      "safety_lifts"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone."
	  },
	  {
	    "id": "feedback_governors",
	    "name": "Feedback Governors",
	    "direction": "Information",
	    "day": 12000,
	    "chance": 0.002,
	    "requires": [
	      "rotational_dynamics",
	      "crank_linkages",
	      "mechanical_oscillation"
	    ],
	    "requires_all": [
	      "rotational_dynamics",
	      "crank_linkages",
	      "mechanical_oscillation"
	    ],
	    "signals": [
	      "research",
	      "crafting",
	      "construction"
	    ],
	    "observation": "A speed-sensitive linkage changes the drive input to resist unwanted speed changes.",
	    "effects": {},
	    "foundation_for": [
	      "steam_propulsion"
	    ],
	    "production_contract": "Provides a distinct mechanical method for the named downstream investigations. Relevant model-assisted routes gain 15% research throughput; practical routes remain. No machine, workforce or operating output is created by knowledge alone. Enables the named physical workshop components; batch materials, setup tooling and finite workshop work are consumed to create them.",
	    "production_items": [
	      "mechanical_governors"
	    ]
	  }
	]


static func apply(entry:Dictionary)->Dictionary:
	if not MODELS.has(String(entry.id)):return entry
	var original:Array=entry.get("learning_routes",[]).duplicate(true)
	# Existing empirical approaches and their common AND/OR foundations remain.
	if original.is_empty():
		original=[{"id":"local","label":"Local practice","requires_all":entry.get("requires",[]).duplicate()}]
		var alternatives:Dictionary=preload("res://scripts/knowledge_pathways.gd").ALTERNATIVES
		if alternatives.has(String(entry.id)):
			var alternate:Dictionary=alternatives[String(entry.id)].duplicate(true)
			alternate["id"]="experimental";original.append(alternate)
	var result:Array=original.duplicate(true)
	for route:Dictionary in original:
		if String(route.id).contains("mechanical:"):continue
		var id:=("experimental:" if String(route.id).begins_with("experimental") else "")+"mechanical:"+String(route.id)
		var present:=false
		for existing:Dictionary in result:
			if existing.id==id:present=true;break
		if present:continue
		var model:Dictionary=route.duplicate(true)
		model.id=id;model.label=String(MODELS[String(entry.id)].label)+" · "+String(route.get("label","local practice"))
		model["requires_all"]=route.get("requires_all",route.get("requires",[])).duplicate()
		model.requires_all.append_array(MODELS[String(entry.id)].requires)
		model["progress_multiplier"]=float(route.get("progress_multiplier",1.0))*1.15
		result.append(model)
	entry["learning_routes"]=result
	return entry
