extends Node

# Every interpreted pronouncement resolves to one of these definitions. Numeric
# effects are deterministic and never supplied by the generative service.
const EFFECT_LABELS := {
	"food_demand":"food demand","food_yield":"food yield","labor_multiplier":"labor efficiency",
	"health_target":"health","cohesion_target":"cohesion","knowledge_gain":"knowledge gain",
	"material_target":"material capacity","logistics_target":"logistics","security_target":"security",
	"ecology_delta":"ecology per day","legitimacy_target":"legitimacy","conception_support":"conception conditions"
}

# Observations report movement in a linked public simulation metric. They are
# deliberately labeled as observations, not causal attribution: weather,
# staffing, discoveries, conflict, and the economy continue to move the same
# values while a policy is active.
const EFFECT_OBSERVATIONS := {
	"food_demand":{"metric":"food_consumption","label":"daily food use","format":"quantity"},
	"food_yield":{"metric":"food_production","label":"daily food output","format":"quantity"},
	"labor_multiplier":{"metric":"labor_efficiency","label":"labor efficiency","format":"ratio"},
	"health_target":{"metric":"health","label":"health","format":"ratio"},
	"cohesion_target":{"metric":"cohesion","label":"cohesion","format":"ratio"},
	"knowledge_gain":{"metric":"knowledge","label":"knowledge","format":"ratio"},
	"material_target":{"metric":"material_capacity","label":"material capacity","format":"ratio"},
	"logistics_target":{"metric":"logistics","label":"logistics","format":"ratio"},
	"security_target":{"metric":"security","label":"security","format":"ratio"},
	"ecology_delta":{"metric":"ecology","label":"ecology","format":"ecology"},
	"legitimacy_target":{"metric":"legitimacy","label":"legitimacy","format":"ratio"},
	"conception_support":{"metric":"annual_conceptions_expected","label":"expected conceptions","format":"annual"}
}

const POLICIES := {
	"rationing":{"office":"Quartermaster","skills":["Administration","Logistics"],"magnitude":0.18,"days":90.0,"ripple":"Food stores last longer, while health and cohesion bear the restriction.","effects":{"food_demand":-0.30,"cohesion_target":-0.16}},
	"foraging_drive":{"office":"Quartermaster","skills":["Agriculture","Logistics"],"magnitude":0.18,"days":120.0,"ripple":"Immediate food yield rises, increasing ecological pressure.","effects":{"food_yield":0.42,"ecology_delta":-0.00048}},
	"conservation_order":{"office":"Quartermaster","skills":["Agriculture","Administration"],"magnitude":0.18,"days":365.0,"ripple":"Land recovery improves while near-term gathering yields fall.","effects":{"food_yield":-0.18,"ecology_delta":0.00055}},
	"care_rotation":{"office":"Steward","skills":["Medicine","Administration"],"magnitude":0.18,"days":120.0,"ripple":"Health improves while care duties reduce effective labor.","effects":{"labor_multiplier":-0.12,"health_target":0.26}},
	"expanded_watch":{"office":"Marshal","skills":["Strategy","Public Order"],"magnitude":0.18,"days":180.0,"ripple":"Security improves while the watch claims scarce labor.","effects":{"labor_multiplier":-0.04,"security_target":0.24}},
	"public_assembly":{"office":"Envoy","skills":["Oratory","Coalition Building"],"magnitude":0.18,"days":120.0,"ripple":"Legitimacy and cohesion improve while administration is occupied.","effects":{"labor_multiplier":-0.04,"cohesion_target":0.22,"legitimacy_target":0.18}},
	"emergency_building":{"office":"Steward","skills":["Construction","Delegation"],"magnitude":0.18,"days":120.0,"ripple":"Construction accelerates while other work loses priority.","effects":{"labor_multiplier":-0.06,"material_target":0.20}},
	"directed_inquiry":{"office":"Scholar","skills":["Research","Education"],"magnitude":0.16,"days":180.0,"ripple":"Directed inquiry accelerates knowledge while drawing labor into observation and study.","effects":{"labor_multiplier":-0.06,"knowledge_gain":0.65}},
	"craft_mobilization":{"office":"Quartermaster","skills":["Manufacturing","Delegation"],"magnitude":0.16,"days":120.0,"ripple":"Craft capacity rises while workshops claim labor from other duties.","effects":{"labor_multiplier":-0.06,"material_target":0.22}},
	"route_priority":{"office":"Quartermaster","skills":["Logistics","Engineering"],"magnitude":0.16,"days":240.0,"ripple":"Routes and carrying coordination improve while their upkeep consumes labor.","effects":{"labor_multiplier":-0.04,"logistics_target":0.24}},
	"labor_mobilization":{"office":"Steward","skills":["Discipline","Delegation"],"magnitude":0.14,"days":90.0,"ripple":"Output rises under intensified work, at a cost to health, cohesion, and legitimacy.","effects":{"labor_multiplier":0.16,"health_target":-0.10,"cohesion_target":-0.14,"legitimacy_target":-0.08}},
	"family_support":{"office":"Steward","skills":["Empathy","Medicine"],"magnitude":0.14,"days":365.0,"ripple":"Family support improves health, cohesion, and conception conditions while care claims labor.","effects":{"labor_multiplier":-0.06,"health_target":0.08,"cohesion_target":0.10,"conception_support":0.35}}
}

# These profiles connect policy to goals advisors already possess. They do not
# invent ideology or personality: reactions are deterministic matches against
# each named advisor's established goals, and repeal reverses the alignment.
const COUNCIL_GOAL_AFFINITIES := {
	"rationing":{"supports":["secure_supplies"],"strains":["protect_population","preserve_cohesion"]},
	"foraging_drive":{"supports":["secure_supplies"],"strains":["study_environment"]},
	"conservation_order":{"supports":["study_environment"],"strains":["secure_supplies"]},
	"care_rotation":{"supports":["protect_population","prevent_disease"],"strains":[]},
	"expanded_watch":{"supports":["secure_perimeter","maintain_readiness","survey_threats"],"strains":[]},
	"public_assembly":{"supports":["preserve_cohesion","avoid_feuds","formalize_administration"],"strains":[]},
	"emergency_building":{"supports":["establish_settlement","improve_infrastructure","secure_materials"],"strains":[]},
	"directed_inquiry":{"supports":["study_environment","preserve_knowledge","record_orders"],"strains":[]},
	"craft_mobilization":{"supports":["improve_infrastructure","secure_materials"],"strains":[]},
	"route_priority":{"supports":["expand_routes","avoid_isolation","create_exchange"],"strains":[]},
	"labor_mobilization":{"supports":["establish_settlement","improve_infrastructure","secure_materials"],"strains":["protect_population","preserve_cohesion","avoid_feuds"]},
	"family_support":{"supports":["protect_population","prevent_disease","preserve_cohesion"],"strains":[]}
}

func has_policy(policy_id:String)->bool:
	return POLICIES.has(policy_id)

func definition(policy_id:String)->Dictionary:
	return (POLICIES.get(policy_id,{}) as Dictionary).duplicate(true)

func public_contract()->Dictionary:
	var result:Dictionary={}
	for policy_id in POLICIES:
		var policy:Dictionary=POLICIES[policy_id]
		result[policy_id]={"office":policy.office,"default_magnitude":policy.magnitude,"default_days":policy.days,"consequence":policy.ripple}
	return result

func formatted_effects(effects:Dictionary,magnitude:float)->String:
	var lines:Array[String]=[]
	for channel in effects:
		if not EFFECT_LABELS.has(channel): continue
		var value:=float(effects[channel])*magnitude
		if String(channel)=="ecology_delta": lines.append("%s %+.4f/day" % [EFFECT_LABELS[channel],value])
		else: lines.append("%s %+.1f%%" % [EFFECT_LABELS[channel],value*100.0])
	return " • ".join(lines)

func observation_spec(channel:String)->Dictionary:
	return (EFFECT_OBSERVATIONS.get(channel,{}) as Dictionary).duplicate(true)

func council_goal_affinity(policy_id:String)->Dictionary:
	return (COUNCIL_GOAL_AFFINITIES.get(policy_id,{"supports":[],"strains":[]}) as Dictionary).duplicate(true)

func formatted_observation(channel:String,baseline:float,current:float)->String:
	var spec:=observation_spec(channel)
	if spec.is_empty(): return ""
	var delta:=current-baseline
	match String(spec.get("format","ratio")):
		"quantity": return "%s %+.1f/day (%.1f→%.1f)" % [spec.label,delta,baseline,current]
		"annual": return "%s %+.2f/year (%.2f→%.2f)" % [spec.label,delta,baseline,current]
		"ecology": return "%s %+.3f pp (%.2f%%→%.2f%%)" % [spec.label,delta*100.0,baseline*100.0,current*100.0]
		_: return "%s %+.2f pp (%.1f%%→%.1f%%)" % [spec.label,delta*100.0,baseline*100.0,current*100.0]

func validation_errors()->Array[String]:
	var errors:Array[String]=[]
	for channel in EFFECT_LABELS:
		if not EFFECT_OBSERVATIONS.has(channel): errors.append("effect channel %s has no observation metric" % channel)
	for policy_id in POLICIES:
		var policy:Dictionary=POLICIES[policy_id]
		if not COUNCIL_GOAL_AFFINITIES.has(policy_id): errors.append("%s has no council goal affinity" % policy_id)
		if String(policy.get("office","")).is_empty(): errors.append("%s has no office" % policy_id)
		if float(policy.get("magnitude",0.0))<0.05 or float(policy.get("magnitude",0.0))>0.25: errors.append("%s has an invalid default magnitude" % policy_id)
		if float(policy.get("days",0.0))<7.0 or float(policy.get("days",0.0))>730.0: errors.append("%s has an invalid default duration" % policy_id)
		for channel in (policy.get("effects",{}) as Dictionary):
			if not EFFECT_LABELS.has(channel): errors.append("%s uses unknown effect channel %s" % [policy_id,channel])
			if not policy.effects[channel] is float and not policy.effects[channel] is int: errors.append("%s effect %s is not numeric" % [policy_id,channel])
	return errors
