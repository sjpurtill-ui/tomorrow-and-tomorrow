extends Node

# Every interpreted pronouncement resolves to one of these definitions. Numeric
# effects are deterministic and never supplied by the generative service.
const EFFECT_LABELS := {
	"food_demand":"food demand","food_yield":"food yield","labor_multiplier":"labor efficiency",
	"water_collection":"water collection","water_storage":"water storage",
	"health_target":"health","cohesion_target":"cohesion","knowledge_gain":"knowledge gain",
	"material_target":"material capacity","logistics_target":"logistics","security_target":"security",
	"ecology_delta":"ecology per day","legitimacy_target":"legitimacy","conception_support":"conception conditions"
	,"stone_priority":"stone collection priority","construction_rate":"construction pace"
}

# Player-facing program names. Parser identifiers stay internal so leaders and
# reports never speak in snake_case catalog labels.
const POLICY_DISPLAY_NAMES := {
	"rationing":"reduced rations",
	"foraging_drive":"an emergency food-gathering drive",
	"conservation_order":"harvest restrictions",
	"water_security":"organized water collection and storage",
	"care_rotation":"a community care rotation",
	"expanded_watch":"an expanded watch",
	"public_assembly":"a public assembly",
	"emergency_building":"an emergency building program",
	"directed_inquiry":"a directed research effort",
	"craft_mobilization":"a workshop mobilization",
	"route_priority":"priority work on roads and hauling",
	"labor_mobilization":"compulsory labor assignments",
	"family_support":"family support and care",
	"birth_restrictions":"birth restrictions",
	"population_resettlement":"forced resettlement",
	"mass_repression":"the lethal repression order",
	"conscription_drive":"a conscription drive",
	"wealth_levy":"a levy on concentrated wealth",
	"market_deregulation":"looser market controls",
	"information_control":"an information-control campaign",
	"stone_gathering_drive":"a stone-gathering drive",
	"stone_housing_program":"a stone-housing program",
	"coercive_pronatalism":"the coercive pregnancy order",
	"recruitment_expedition":"a recruitment expedition",
}

# Observations report movement in a linked public simulation metric. They are
# deliberately labeled as observations, not causal attribution: weather,
# staffing, discoveries, conflict, and the economy continue to move the same
# values while a policy is active.
const EFFECT_OBSERVATIONS := {
	"food_demand":{"metric":"food_consumption","label":"daily food use","format":"quantity"},
	"food_yield":{"metric":"food_production","label":"daily food output","format":"quantity"},
	"water_collection":{"metric":"water_collected_today","label":"daily water collected","format":"quantity"},
	"water_storage":{"metric":"water_days","label":"carried water reserve","format":"quantity"},
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
	,"stone_priority":{"metric":"stockpile:Stone","label":"stored stone","format":"quantity"}
	,"construction_rate":{"metric":"housing_capacity","label":"usable housing places","format":"quantity"}
}

const POLICIES := {
	"rationing":{"office":"Quartermaster","skills":["Administration","Logistics"],"magnitude":0.18,"days":90.0,"ripple":"Food stores last longer, while health and cohesion bear the restriction.","effects":{"food_demand":-0.30,"cohesion_target":-0.16}},
	"foraging_drive":{"office":"Quartermaster","skills":["Provisioning","Logistics"],"magnitude":0.18,"days":120.0,"ripple":"Immediate food yield rises, increasing ecological pressure.","effects":{"food_yield":0.42,"ecology_delta":-0.00048}},
	"conservation_order":{"office":"Quartermaster","skills":["Provisioning","Knowledge"],"magnitude":0.18,"days":365.0,"ripple":"Land recovery improves while near-term gathering yields fall.","effects":{"food_yield":-0.18,"ecology_delta":0.00055}},
	"water_security":{"office":"Quartermaster","skills":["Provisioning","Logistics"],"magnitude":0.18,"days":180.0,"ripple":"People organize fetching, vessels, and distribution around a recognized water source; carrying claims labor and cannot create water where none is reachable.","effects":{"labor_multiplier":-0.05,"water_collection":1.20,"water_storage":2.50,"logistics_target":0.08}},
	"care_rotation":{"office":"Steward","skills":["Provisioning","Administration"],"magnitude":0.18,"days":120.0,"ripple":"Health improves while care duties reduce effective labor.","effects":{"labor_multiplier":-0.12,"health_target":0.26}},
	"expanded_watch":{"office":"Marshal","skills":["Defense","Administration"],"magnitude":0.18,"days":180.0,"ripple":"Security improves while the watch claims scarce labor.","effects":{"labor_multiplier":-0.04,"security_target":0.24}},
	"public_assembly":{"office":"Envoy","skills":["Diplomacy","Administration"],"magnitude":0.18,"days":120.0,"ripple":"Legitimacy and cohesion improve while administration is occupied.","effects":{"labor_multiplier":-0.04,"cohesion_target":0.22,"legitimacy_target":0.18}},
	"emergency_building":{"office":"Steward","skills":["Construction","Administration"],"magnitude":0.18,"days":120.0,"ripple":"Construction accelerates while other work loses priority.","effects":{"labor_multiplier":-0.06,"material_target":0.20}},
	"directed_inquiry":{"office":"Scholar","skills":["Knowledge","Administration"],"magnitude":0.16,"days":180.0,"ripple":"Directed inquiry accelerates knowledge while drawing labor into observation and study.","effects":{"labor_multiplier":-0.06,"knowledge_gain":0.65}},
	"craft_mobilization":{"office":"Quartermaster","skills":["Construction","Logistics"],"magnitude":0.16,"days":120.0,"ripple":"Craft capacity rises while workshops claim labor from other duties.","effects":{"labor_multiplier":-0.06,"material_target":0.22}},
	"route_priority":{"office":"Quartermaster","skills":["Logistics","Construction"],"magnitude":0.16,"days":240.0,"ripple":"Routes and carrying coordination improve while their upkeep consumes labor.","effects":{"labor_multiplier":-0.04,"logistics_target":0.24}},
	"labor_mobilization":{"office":"Steward","skills":["Administration","Defense"],"magnitude":0.14,"days":90.0,"ripple":"Output rises under intensified work, at a cost to health, cohesion, and legitimacy.","effects":{"labor_multiplier":0.16,"health_target":-0.10,"cohesion_target":-0.14,"legitimacy_target":-0.08}},
	"family_support":{"office":"Steward","skills":["Provisioning","Diplomacy"],"magnitude":0.14,"days":365.0,"ripple":"Family support improves health, cohesion, and conception conditions while care claims labor.","effects":{"labor_multiplier":-0.06,"health_target":0.08,"cohesion_target":0.10,"conception_support":0.35}},
	"birth_restrictions":{"office":"Steward","skills":["Administration","Provisioning"],"magnitude":0.14,"days":365.0,"ripple":"Birth restrictions reduce conception while enforcement strains health, cohesion, and legitimacy.","effects":{"conception_support":-0.55,"health_target":-0.04,"cohesion_target":-0.12,"legitimacy_target":-0.14}},
	"population_resettlement":{"office":"Marshal","skills":["Logistics","Defense"],"magnitude":0.16,"days":180.0,"ripple":"Forced relocation concentrates control and routes while displacement causes exposure, resistance, and loss.","effects":{"labor_multiplier":-0.12,"health_target":-0.08,"cohesion_target":-0.18,"logistics_target":0.12,"security_target":0.08,"legitimacy_target":-0.16}},
	"mass_repression":{"office":"Marshal","skills":["Defense","Administration"],"magnitude":0.12,"days":90.0,"ripple":"Lethal repression may suppress an immediate threat, but deaths, fear, resistance, lost knowledge, and legitimacy damage persist.","effects":{"labor_multiplier":-0.10,"health_target":-0.12,"cohesion_target":-0.35,"knowledge_gain":-0.18,"security_target":0.22,"legitimacy_target":-0.42}},
	"conscription_drive":{"office":"Marshal","skills":["Defense","Administration"],"magnitude":0.16,"days":180.0,"ripple":"Conscription increases mobilization readiness while removing labor and creating resistance; it does not create trained or equipped units.","effects":{"labor_multiplier":-0.16,"cohesion_target":-0.08,"security_target":0.30,"legitimacy_target":-0.06}},
	"wealth_levy":{"office":"Steward","skills":["Administration","Diplomacy"],"magnitude":0.16,"days":180.0,"ripple":"A wealth levy redirects existing capacity toward common stores while collection occupies labor and provokes resistance.","effects":{"labor_multiplier":-0.06,"cohesion_target":0.06,"material_target":0.18,"legitimacy_target":0.08}},
	"market_deregulation":{"office":"Envoy","skills":["Diplomacy","Logistics"],"magnitude":0.14,"days":180.0,"ripple":"Looser exchange rules improve material and route coordination while inequality pressure strains cohesion and legitimacy.","effects":{"cohesion_target":-0.08,"material_target":0.14,"logistics_target":0.14,"legitimacy_target":-0.05}},
	"information_control":{"office":"Marshal","skills":["Defense","Administration"],"magnitude":0.16,"days":180.0,"ripple":"Information controls ease short-term coordination at the cost of knowledge, trust, and legitimacy.","effects":{"cohesion_target":0.05,"knowledge_gain":-0.30,"security_target":0.10,"legitimacy_target":-0.20}}
	,"stone_gathering_drive":{"office":"Quartermaster","skills":["Provisioning","Logistics"],"magnitude":0.18,"days":120.0,"ripple":"Available extractors and carriers favor recognized stone sources; food, repair, and other materials receive less labor.","effects":{"labor_multiplier":-0.05,"material_target":0.12,"stone_priority":1.80}}
	,"stone_housing_program":{"office":"Steward","skills":["Construction","Administration"],"magnitude":0.16,"days":365.0,"ripple":"Builders replace or extend housing with stone where the material, access, and learned practice permit; other construction waits.","effects":{"labor_multiplier":-0.08,"material_target":0.08,"construction_rate":0.55,"stone_priority":0.80}}
	,"coercive_pronatalism":{"office":"Steward","skills":["Administration","Defense"],"magnitude":0.14,"days":180.0,"ripple":"Threats may drive some conceptions, concealment, or flight; coercion harms health, family trust, cohesion, and legitimacy, and any promised punishment still requires real enforcement capacity.","effects":{"labor_multiplier":-0.05,"conception_support":0.42,"health_target":-0.08,"cohesion_target":-0.24,"legitimacy_target":-0.30}}
	,"recruitment_expedition":{"office":"Steward","skills":["Logistics","Diplomacy"],"magnitude":0.12,"days":90.0,"ripple":"A physical scouting party searches reachable country for people willing to join; it consumes provisions and may return late, empty-handed, diminished, or not at all.","effects":{}}
}

# Every recognized directive, whether interpreted locally or proposed by an API,
# receives one deterministic implementation contract here. The API never sees
# or supplies these numeric constraints. Costs are physical aggregate quantities;
# direct effects are bounded one-time shocks, while POLICIES contains the slower
# standing effects that continue through the normal simulation.
const DIRECTIVE_CONTRACTS := {
	"rationing":{"domain":"economic","administration_required":0.10,"security_required":0.00,"coercion":0.28,"food_rations_per_capita":0.0,"material_bulk_per_1000":0.0,"direct_effects":{"cohesion_delta":-0.008}},
	"foraging_drive":{"domain":"economic","administration_required":0.08,"security_required":0.00,"coercion":0.08,"food_rations_per_capita":0.0,"material_bulk_per_1000":0.0,"direct_effects":{"ecology_delta":-0.002}},
	"conservation_order":{"domain":"economic","administration_required":0.14,"security_required":0.05,"coercion":0.22,"food_rations_per_capita":0.0,"material_bulk_per_1000":0.0,"direct_effects":{}},
	"water_security":{"domain":"economic","administration_required":0.12,"security_required":0.00,"coercion":0.04,"food_rations_per_capita":0.02,"material_bulk_per_1000":0.0,"direct_effects":{}},
	"care_rotation":{"domain":"demographic","administration_required":0.18,"security_required":0.00,"coercion":0.02,"food_rations_per_capita":0.08,"material_bulk_per_1000":0.0,"direct_effects":{"health_delta":0.006}},
	"expanded_watch":{"domain":"military","administration_required":0.12,"security_required":0.10,"coercion":0.18,"food_rations_per_capita":0.03,"material_bulk_per_1000":0.0,"direct_effects":{}},
	"public_assembly":{"domain":"social","administration_required":0.16,"security_required":0.00,"coercion":0.00,"food_rations_per_capita":0.02,"material_bulk_per_1000":0.0,"direct_effects":{"cohesion_delta":0.006,"legitimacy_delta":0.006}},
	"emergency_building":{"domain":"economic","administration_required":0.20,"security_required":0.00,"coercion":0.06,"food_rations_per_capita":0.04,"material_bulk_per_1000":0.80,"direct_effects":{}},
	"directed_inquiry":{"domain":"social","administration_required":0.18,"security_required":0.00,"coercion":0.00,"food_rations_per_capita":0.04,"material_bulk_per_1000":0.12,"direct_effects":{}},
	"craft_mobilization":{"domain":"economic","administration_required":0.18,"security_required":0.00,"coercion":0.10,"food_rations_per_capita":0.03,"material_bulk_per_1000":0.45,"direct_effects":{}},
	"route_priority":{"domain":"economic","administration_required":0.20,"security_required":0.00,"coercion":0.04,"food_rations_per_capita":0.04,"material_bulk_per_1000":0.65,"direct_effects":{}},
	"labor_mobilization":{"domain":"economic","administration_required":0.16,"security_required":0.10,"coercion":0.55,"food_rations_per_capita":0.02,"material_bulk_per_1000":0.0,"direct_effects":{"health_delta":-0.006,"cohesion_delta":-0.008,"legitimacy_delta":-0.006}},
	"family_support":{"domain":"demographic","administration_required":0.20,"security_required":0.00,"coercion":0.00,"food_rations_per_capita":0.10,"material_bulk_per_1000":0.0,"direct_effects":{"health_delta":0.005,"cohesion_delta":0.005}},
	"birth_restrictions":{"domain":"demographic","administration_required":0.24,"security_required":0.16,"coercion":0.65,"food_rations_per_capita":0.02,"material_bulk_per_1000":0.0,"direct_effects":{"health_delta":-0.004,"cohesion_delta":-0.010,"legitimacy_delta":-0.012}},
	"population_resettlement":{"domain":"demographic","administration_required":0.34,"security_required":0.34,"coercion":0.78,"food_rations_per_capita":0.16,"material_bulk_per_1000":0.18,"direct_effects":{"population_deaths_share":0.008,"health_delta":-0.012,"cohesion_delta":-0.018,"legitimacy_delta":-0.018}},
	"mass_repression":{"domain":"military","administration_required":0.42,"security_required":0.50,"coercion":0.96,"food_rations_per_capita":0.03,"material_bulk_per_1000":0.05,"direct_effects":{"population_deaths_share":0.040,"health_delta":-0.012,"cohesion_delta":-0.030,"legitimacy_delta":-0.040}},
	"conscription_drive":{"domain":"military","administration_required":0.26,"security_required":0.30,"coercion":0.48,"food_rations_per_capita":0.08,"material_bulk_per_1000":0.12,"direct_effects":{"cohesion_delta":-0.008,"legitimacy_delta":-0.006}},
	"wealth_levy":{"domain":"economic","administration_required":0.28,"security_required":0.12,"coercion":0.34,"food_rations_per_capita":0.01,"material_bulk_per_1000":0.0,"direct_effects":{}},
	"market_deregulation":{"domain":"economic","administration_required":0.18,"security_required":0.00,"coercion":0.00,"food_rations_per_capita":0.0,"material_bulk_per_1000":0.0,"direct_effects":{}},
	"information_control":{"domain":"social","administration_required":0.30,"security_required":0.30,"coercion":0.62,"food_rations_per_capita":0.01,"material_bulk_per_1000":0.0,"direct_effects":{"knowledge_delta":-0.008,"legitimacy_delta":-0.014}}
	,"stone_gathering_drive":{"domain":"economic","administration_required":0.14,"security_required":0.00,"coercion":0.20,"food_rations_per_capita":0.02,"material_bulk_per_1000":0.0,"recognized_resource":"Stone","direct_effects":{}}
	,"stone_housing_program":{"domain":"economic","administration_required":0.20,"security_required":0.00,"coercion":0.16,"food_rations_per_capita":0.04,"material_bulk_per_1000":0.40,"recognized_resource":"Stone","required_discoveries":["stone_selection"],"direct_effects":{}}
	,"coercive_pronatalism":{"domain":"demographic","administration_required":0.28,"security_required":0.30,"coercion":0.90,"food_rations_per_capita":0.02,"material_bulk_per_1000":0.0,"deadline_enforcement":"pregnancy_threat","direct_effects":{"health_delta":-0.008,"cohesion_delta":-0.018,"legitimacy_delta":-0.024}}
	,"recruitment_expedition":{"domain":"demographic","administration_required":0.10,"security_required":0.00,"coercion":0.02,"food_rations_per_capita":0.0,"material_bulk_per_1000":0.0,"operation":"recruitment_scouts","direct_effects":{}}
}

# These profiles connect policy to goals advisors already possess. They do not
# invent ideology or personality: reactions are deterministic matches against
# each council institution's established priorities, and repeal reverses the alignment.
const COUNCIL_GOAL_AFFINITIES := {
	"rationing":{"supports":["secure_supplies"],"strains":["protect_population","preserve_cohesion"]},
	"foraging_drive":{"supports":["secure_supplies"],"strains":["study_environment"]},
	"conservation_order":{"supports":["study_environment"],"strains":["secure_supplies"]},
	"water_security":{"supports":["secure_supplies","protect_population","improve_infrastructure"],"strains":[]},
	"care_rotation":{"supports":["protect_population","prevent_disease"],"strains":[]},
	"expanded_watch":{"supports":["secure_perimeter","maintain_readiness","survey_threats"],"strains":[]},
	"public_assembly":{"supports":["preserve_cohesion","avoid_feuds","formalize_administration"],"strains":[]},
	"emergency_building":{"supports":["establish_settlement","improve_infrastructure","secure_materials"],"strains":[]},
	"directed_inquiry":{"supports":["study_environment","preserve_knowledge","record_orders"],"strains":[]},
	"craft_mobilization":{"supports":["improve_infrastructure","secure_materials"],"strains":[]},
	"route_priority":{"supports":["expand_routes","avoid_isolation","create_exchange"],"strains":[]},
	"labor_mobilization":{"supports":["establish_settlement","improve_infrastructure","secure_materials"],"strains":["protect_population","preserve_cohesion","avoid_feuds"]},
	"family_support":{"supports":["protect_population","prevent_disease","preserve_cohesion"],"strains":[]},
	"birth_restrictions":{"supports":["formalize_administration"],"strains":["protect_population","preserve_cohesion"]},
	"population_resettlement":{"supports":["secure_perimeter","formalize_administration"],"strains":["protect_population","preserve_cohesion","avoid_feuds"]},
	"mass_repression":{"supports":["secure_perimeter"],"strains":["protect_population","preserve_cohesion","avoid_feuds","preserve_knowledge"]},
	"conscription_drive":{"supports":["secure_perimeter","maintain_readiness"],"strains":["protect_population","preserve_cohesion"]},
	"wealth_levy":{"supports":["secure_materials","formalize_administration"],"strains":["create_exchange","avoid_feuds"]},
	"market_deregulation":{"supports":["create_exchange","expand_routes"],"strains":["preserve_cohesion"]},
	"information_control":{"supports":["secure_perimeter","formalize_administration"],"strains":["preserve_knowledge","preserve_cohesion"]}
	,"stone_gathering_drive":{"supports":["secure_materials","improve_infrastructure"],"strains":["secure_supplies"]}
	,"stone_housing_program":{"supports":["establish_settlement","improve_infrastructure"],"strains":["secure_supplies","secure_materials"]}
	,"coercive_pronatalism":{"supports":["formalize_administration"],"strains":["protect_population","preserve_cohesion","avoid_feuds"]}
	,"recruitment_expedition":{"supports":["avoid_isolation","expand_routes","protect_population"],"strains":["secure_supplies"]}
}

func has_policy(policy_id:String)->bool:
	return POLICIES.has(policy_id)

func definition(policy_id:String)->Dictionary:
	return (POLICIES.get(policy_id,{}) as Dictionary).duplicate(true)

func display_name(policy_id:String)->String:
	return String(POLICY_DISPLAY_NAMES.get(policy_id,String(policy_id).replace("_"," ")))

func directive_contract(policy_id:String)->Dictionary:
	var contract:Dictionary=(DIRECTIVE_CONTRACTS.get(policy_id,{}) as Dictionary).duplicate(true)
	if contract.is_empty(): return {}
	var definition_value:=definition(policy_id)
	contract["id"]=policy_id
	contract["office"]=String(definition_value.get("office","Council"))
	contract["second_order"]=String(definition_value.get("ripple","The directive changes simulated conditions."))
	return contract

func public_contract()->Dictionary:
	var result:Dictionary={}
	for policy_id in POLICIES:
		var policy:Dictionary=POLICIES[policy_id]
		result[policy_id]={"office":policy.office,"default_magnitude":policy.magnitude,"default_days":policy.days,"consequence":policy.ripple}
	return result

func interpretation_contract()->Dictionary:
	# The remote model only chooses IDs. Costs, duration, feasibility, and effects
	# remain deterministic, so sending those values wastes tokens and falsely
	# implies that the provider may tune the simulation.
	var meanings:Dictionary={
		"rationing":"reduce food portions","foraging_drive":"prioritize gathering, hunting, or finding food",
		"conservation_order":"protect land or restrict harvesting","care_rotation":"organize healing and care",
		"water_security":"organize drinking water collection, carrying, storage, or distribution",
		"expanded_watch":"increase guards, patrols, or defense","public_assembly":"hold a public council or assembly",
		"emergency_building":"prioritize shelter, housing, or construction","directed_inquiry":"prioritize research or investigation",
		"craft_mobilization":"prioritize workshops, artisans, or production","route_priority":"prioritize roads, hauling, or logistics",
		"labor_mobilization":"impose work quotas or compulsory labor","family_support":"support families, childcare, or voluntary births",
		"birth_restrictions":"restrict births or impose contraception","population_resettlement":"force relocation or deportation",
		"mass_repression":"kill, execute, purge, or exterminate a group","conscription_drive":"impose military conscription or service",
		"wealth_levy":"tax or seize concentrated wealth","market_deregulation":"remove market or price controls",
		"information_control":"censor, propagandize, or seed rumors","stone_gathering_drive":"prioritize gathering or quarrying stone",
		"stone_housing_program":"build housing from stone","coercive_pronatalism":"compel sex, pregnancy, or births through threats",
		"recruitment_expedition":"send scouts to recruit new people",
	}
	var result:Dictionary={}
	for policy_id in POLICIES: result[policy_id]=String(meanings.get(policy_id,String(policy_id).replace("_"," ")))
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
		if not POLICY_DISPLAY_NAMES.has(policy_id): errors.append("%s has no player-facing display name" % policy_id)
		if not COUNCIL_GOAL_AFFINITIES.has(policy_id): errors.append("%s has no council goal affinity" % policy_id)
		if not DIRECTIVE_CONTRACTS.has(policy_id): errors.append("%s has no directive implementation contract" % policy_id)
		if String(policy.get("office","")).is_empty(): errors.append("%s has no office" % policy_id)
		for skill_variant in (policy.get("skills",[]) as Array):
			if String(skill_variant) not in GovernmentPeopleSystem.SKILL_KEYS: errors.append("%s uses obsolete government skill %s" % [policy_id,String(skill_variant)])
		if float(policy.get("magnitude",0.0))<0.05 or float(policy.get("magnitude",0.0))>0.25: errors.append("%s has an invalid default magnitude" % policy_id)
		if float(policy.get("days",0.0))<7.0 or float(policy.get("days",0.0))>730.0: errors.append("%s has an invalid default duration" % policy_id)
		for channel in (policy.get("effects",{}) as Dictionary):
			if not EFFECT_LABELS.has(channel): errors.append("%s uses unknown effect channel %s" % [policy_id,channel])
			if not policy.effects[channel] is float and not policy.effects[channel] is int: errors.append("%s effect %s is not numeric" % [policy_id,channel])
		var contract:Dictionary=DIRECTIVE_CONTRACTS.get(policy_id,{})
		if String(contract.get("domain","")) not in ["demographic","economic","military","social"]: errors.append("%s has an invalid directive domain" % policy_id)
		for required_value in ["administration_required","security_required","coercion","food_rations_per_capita","material_bulk_per_1000"]:
			if not contract.get(required_value,null) is float and not contract.get(required_value,null) is int: errors.append("%s directive contract lacks numeric %s" % [policy_id,required_value])
		for direct_channel in (contract.get("direct_effects",{}) as Dictionary):
			if String(direct_channel) not in ["population_deaths_share","health_delta","cohesion_delta","knowledge_delta","security_delta","ecology_delta","legitimacy_delta"]: errors.append("%s uses unknown direct-effect channel %s" % [policy_id,direct_channel])
	return errors
