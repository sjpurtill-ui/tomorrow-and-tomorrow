extends Node

# One bounded causal model drives the early civilization. Narrative systems may
# choose from these pressures, but only this file turns them into numbers.

var initialized := false

func _food_system() -> Node:
	return get_node("/root/FoodSystem")

func reset_for_new_world()->void:
	initialized=false

func initialize() -> void:
	if initialized:
		return
	initialized = true
	GameState.initialize_citizen_registry()
	GameState.synchronize_population_allocations()
	if GameState.resource_stockpiles.is_empty():
		GameState.resource_stockpiles = {"Food":GameState.population_exact*30.0,"Timber":0.0,"Stone":0.0,"Clay":0.0,"Fiber Plants":4.0}
	GameState.simulation_metrics["health"] = GameState.population_health

func apply_campaign_goal(goal: Dictionary) -> void:
	initialize()
	GameState.campaign_goal = goal.duplicate(true)
	GameState.campaign_goal_status = "active"
	GameState.active_modifiers.clear()
	for proposed in goal.get("pressures",[]):
		var pressure: Dictionary = proposed.duplicate(true)
		var duration_years := clampf(float(pressure.get("duration_years",8.0)),0.25,200.0)
		pressure["until_day"] = GameState.elapsed_days+duration_years*365.0
		GameState.active_modifiers.append(pressure)
	_add_event("Mandate Received",String(goal.get("title","A civilization must be made.")),"mandate","major")

func apply_policy(effect_id: String,magnitude: float,duration_days: float,source: String,metadata:Dictionary={})->bool:
	initialize()
	var incoming_sequence:=int(metadata.get("source_order_sequence",0))
	var incoming_order_id:=String(metadata.get("source_order_id",""))
	for existing_variant in GameState.active_modifiers:
		var existing:Dictionary=existing_variant
		if String(existing.get("id",""))!=effect_id or String(existing.get("kind",""))!="policy" or GameState.elapsed_days>float(existing.get("until_day",-INF)): continue
		if incoming_order_id!="" and String(existing.get("source_order_id",""))==incoming_order_id: return false
		var existing_sequence:=int(existing.get("source_order_sequence",0))
		if incoming_sequence>0 and existing_sequence>incoming_sequence:
			_add_event("Order Overtaken","A newer %s order was already in force when this interpretation arrived; the older submission changed no variables." % effect_id.replace("_"," "),"institutions","notice")
			return false
	# A standing policy supersedes its previous version instead of becoming an
	# exploitable stack of repeated identical pronouncements.
	var superseded:=false
	var prior_magnitude:=0.0
	for modifier in GameState.active_modifiers:
		if String(modifier.get("id",""))==effect_id and String(modifier.get("kind",""))=="policy" and GameState.elapsed_days<=float(modifier.get("until_day",-INF)):
			superseded=true
			prior_magnitude=float(modifier.get("magnitude",0.0))
			_refresh_policy_observation_record(modifier)
			modifier["until_day"]=GameState.elapsed_days-0.001
			modifier["ended_day"]=GameState.elapsed_days
			modifier["ended_reason"]="superseded"
			modifier["superseded_by_order_id"]=String(metadata.get("source_order_id",""))
	if superseded: _record_policy_churn(clampf(0.025+absf(prior_magnitude-clampf(magnitude,-0.35,0.35))*0.12,0.025,0.07),"A standing %s order was replaced before its term ended." % effect_id.replace("_"," "))
	var effects:Dictionary=(metadata.get("effects",{}) as Dictionary).duplicate(true)
	if effects.is_empty() and GovernmentPolicyCatalog.has_policy(effect_id): effects=GovernmentPolicyCatalog.definition(effect_id).get("effects",{})
	var record:={"id":effect_id,"kind":"policy","effects":effects,"magnitude":clampf(magnitude,-0.35,0.35),"started_day":GameState.elapsed_days,"until_day":GameState.elapsed_days+clampf(duration_days,1.0,3650.0),"description":source}
	var observation_baseline:=_capture_policy_observation(effects)
	var observation_baseline_days:Dictionary={}
	for metric in observation_baseline: observation_baseline_days[metric]=GameState.elapsed_days
	record["observation_baseline"]=observation_baseline
	record["observation_baseline_days"]=observation_baseline_days
	record["observation_latest"]=observation_baseline.duplicate(true)
	record["observation_updated_day"]=GameState.elapsed_days
	for key in metadata:
		if String(key)=="effects": continue
		record[key]=metadata[key]
	GameState.active_modifiers.append(record)
	_prune_policy_history()
	_add_event("Order Issued",source,"policy","notice")
	return true

func repeal_policy(effect_id:String,source:String,metadata:Dictionary={})->bool:
	initialize()
	var repealed:=false
	var longest_remaining:=0.0
	for modifier in GameState.active_modifiers:
		if String(modifier.get("id",""))!=effect_id or String(modifier.get("kind",""))!="policy": continue
		if GameState.elapsed_days>float(modifier.get("until_day",-INF)): continue
		longest_remaining=maxf(longest_remaining,float(modifier.get("until_day",GameState.elapsed_days))-GameState.elapsed_days)
		_refresh_policy_observation_record(modifier)
		modifier["until_day"]=GameState.elapsed_days-0.001
		modifier["repealed_day"]=GameState.elapsed_days
		modifier["ended_day"]=GameState.elapsed_days
		modifier["ended_reason"]="repealed"
		for key in metadata: modifier["repeal_"+String(key)]=metadata[key]
		repealed=true
	if repealed and longest_remaining>7.0: _record_policy_churn(clampf(0.025+longest_remaining/3650.0*0.025,0.025,0.06),"A standing %s order was rescinded before its term ended." % effect_id.replace("_"," "))
	_add_event("Order Rescinded",source if repealed else "No active %s order remained to rescind." % effect_id.replace("_"," "),"policy","notice")
	_prune_policy_history()
	return repealed

func _record_policy_churn(magnitude:float,description:String)->void:
	GameState.active_modifiers.append({"id":"policy_churn","kind":"governance","magnitude":clampf(magnitude,0.0,0.10),"started_day":GameState.elapsed_days,"until_day":GameState.elapsed_days+120.0,"description":description})
	_add_event("Policy Reversal",description,"institutions","warning")

func refresh_policy_lifecycle()->void:
	for modifier_variant in GameState.active_modifiers:
		var modifier:Dictionary=modifier_variant
		if String(modifier.get("kind","")) not in ["policy","governance"] or modifier.has("ended_reason"): continue
		if GameState.elapsed_days>float(modifier.get("until_day",INF)):
			if String(modifier.get("kind",""))=="policy": _refresh_policy_observation_record(modifier)
			modifier["ended_reason"]="expired"
			modifier["ended_day"]=float(modifier.get("until_day",GameState.elapsed_days))

func _prune_policy_history(limit:=400)->void:
	refresh_policy_lifecycle()
	if GameState.active_modifiers.size()<=limit: return
	var retained_orders:Dictionary={}
	for order_variant in GameState.sovereign_orders: retained_orders[String((order_variant as Dictionary).get("id",""))]=true
	while GameState.active_modifiers.size()>limit:
		var remove_index:=-1
		for index in GameState.active_modifiers.size():
			var modifier:Dictionary=GameState.active_modifiers[index]
			if String(modifier.get("kind","")) not in ["policy","governance"] or not modifier.has("ended_reason"): continue
			if String(modifier.get("kind",""))=="policy" and retained_orders.has(String(modifier.get("source_order_id",""))): continue
			remove_index=index
			break
		if remove_index<0: break
		GameState.active_modifiers.remove_at(remove_index)

func modifier_strength(effect_id: String) -> float:
	var result := 0.0
	for modifier in GameState.active_modifiers:
		if String(modifier.get("id","")) != effect_id:
			continue
		if GameState.elapsed_days > float(modifier.get("until_day",INF)):
			continue
		result += clampf(float(modifier.get("magnitude",0.0)),-0.35,0.35)
	return clampf(result,-0.50,0.50)

func policy_effect(channel:String)->float:
	var result:=0.0
	for modifier_variant in GameState.active_modifiers:
		var modifier:Dictionary=modifier_variant
		if String(modifier.get("kind",""))!="policy" or GameState.elapsed_days>float(modifier.get("until_day",-INF)): continue
		var effects:Dictionary=modifier.get("effects",{})
		if effects.is_empty() and GovernmentPolicyCatalog.has_policy(String(modifier.get("id",""))): effects=GovernmentPolicyCatalog.definition(String(modifier.id)).get("effects",{})
		if not effects.has(channel): continue
		result+=clampf(float(modifier.get("magnitude",0.0)),-0.35,0.35)*float(effects[channel])
	return clampf(result,-1.0,1.0)

func policy_observation(policy:Dictionary)->Dictionary:
	if policy.is_empty(): return {"summary":"No linked metric baseline is available yet.","metrics":[],"days_elapsed":0.0}
	if String(policy.get("kind","policy"))=="policy" and not policy.has("ended_reason") and GameState.elapsed_days<=float(policy.get("until_day",INF)):
		_refresh_policy_observation_record(policy)
	var baseline:Dictionary=policy.get("observation_baseline",{})
	var latest:Dictionary=policy.get("observation_latest",{})
	var baseline_days:Dictionary=policy.get("observation_baseline_days",{})
	var effects:Dictionary=policy.get("effects",{})
	var lines:Array[String]=[]
	var metrics:Array[Dictionary]=[]
	var seen_metrics:Dictionary={}
	for channel_variant in effects:
		var channel:=String(channel_variant)
		var spec:=GovernmentPolicyCatalog.observation_spec(channel)
		var metric:=String(spec.get("metric",""))
		if metric.is_empty() or seen_metrics.has(metric) or not baseline.has(metric) or not latest.has(metric): continue
		seen_metrics[metric]=true
		var baseline_value:=float(baseline[metric])
		var current_value:=float(latest[metric])
		var expected_direction:=signf(float(effects[channel])*float(policy.get("magnitude",0.0)))
		var delta:=current_value-baseline_value
		var line:=GovernmentPolicyCatalog.formatted_observation(channel,baseline_value,current_value)
		if not line.is_empty(): lines.append(line)
		metrics.append({"channel":channel,"metric":metric,"label":String(spec.get("label",metric)),"baseline":baseline_value,"current":current_value,"delta":delta,"expected_direction":expected_direction,"moving_with_expected_direction":absf(delta)<0.000001 or signf(delta)==expected_direction,"baseline_day":float(baseline_days.get(metric,policy.get("started_day",GameState.elapsed_days)))})
	var end_day:=minf(GameState.elapsed_days,float(policy.get("ended_day",policy.get("until_day",GameState.elapsed_days)))) if policy.has("ended_reason") else GameState.elapsed_days
	var days_elapsed:=maxf(0.0,end_day-float(policy.get("started_day",end_day)))
	return {"summary":" • ".join(lines) if not lines.is_empty() else "Linked metric baseline will form after the next simulation day.","metrics":metrics,"days_elapsed":days_elapsed,"updated_day":float(policy.get("observation_updated_day",policy.get("started_day",end_day))),"disclaimer":"Observed movement also reflects staffing, resources, environment, conflict, discoveries, and other policies."}

func _capture_policy_observation(effects:Dictionary)->Dictionary:
	var snapshot:Dictionary={}
	for channel_variant in effects:
		var spec:=GovernmentPolicyCatalog.observation_spec(String(channel_variant))
		var metric:=String(spec.get("metric",""))
		if metric.is_empty() or not GameState.simulation_metrics.has(metric): continue
		var value=GameState.simulation_metrics[metric]
		if value is float or value is int: snapshot[metric]=float(value)
	return snapshot

func _refresh_policy_observation_record(policy:Dictionary)->void:
	var effects:Dictionary=policy.get("effects",{})
	if effects.is_empty() and GovernmentPolicyCatalog.has_policy(String(policy.get("id",""))): effects=GovernmentPolicyCatalog.definition(String(policy.id)).get("effects",{})
	var current:=_capture_policy_observation(effects)
	var baseline:Dictionary=policy.get("observation_baseline",{})
	var baseline_days:Dictionary=policy.get("observation_baseline_days",{})
	for metric in current:
		if not baseline.has(metric):
			baseline[metric]=current[metric]
			baseline_days[metric]=GameState.elapsed_days
	policy["observation_baseline"]=baseline
	policy["observation_baseline_days"]=baseline_days
	policy["observation_latest"]=current
	policy["observation_updated_day"]=GameState.elapsed_days

func _refresh_all_policy_observations()->void:
	for modifier_variant in GameState.active_modifiers:
		var modifier:Dictionary=modifier_variant
		if String(modifier.get("kind",""))!="policy" or modifier.has("ended_reason") or GameState.elapsed_days>float(modifier.get("until_day",-INF)): continue
		_refresh_policy_observation_record(modifier)

func active_policies()->Array[Dictionary]:
	refresh_policy_lifecycle()
	var result:Array[Dictionary]=[]
	for modifier_variant in GameState.active_modifiers:
		var modifier:Dictionary=modifier_variant
		if String(modifier.get("kind",""))!="policy": continue
		if GameState.elapsed_days>float(modifier.get("until_day",-INF)): continue
		var policy:=modifier.duplicate(true)
		if (policy.get("effects",{}) as Dictionary).is_empty() and GovernmentPolicyCatalog.has_policy(String(policy.get("id",""))): policy["effects"]=GovernmentPolicyCatalog.definition(String(policy.id)).get("effects",{})
		policy["remaining_days"]=maxf(0.0,float(policy.get("until_day",GameState.elapsed_days))-GameState.elapsed_days)
		result.append(policy)
	result.sort_custom(func(a:Dictionary,b:Dictionary): return float(a.get("until_day",INF))<float(b.get("until_day",INF)))
	return result

func governance_metrics()->Dictionary:
	refresh_policy_lifecycle()
	var active:=active_policies()
	var administrative_load:=0.0
	var offices:Dictionary={}
	for policy in active:
		var execution:=maxf(0.35,float(policy.get("execution_factor",0.62)))
		administrative_load+=absf(float(policy.get("magnitude",0.0)))*(0.10+maxf(0.0,1.0-execution)*0.08)
		offices[String(policy.get("office","Council"))]=int(offices.get(String(policy.get("office","Council")),0))+1
	var churn:=maxf(0.0,modifier_strength("policy_churn"))
	administrative_load=clampf(administrative_load+churn*0.25,0.0,0.30)
	return {"active_policy_count":active.size(),"administrative_load":administrative_load,"policy_churn":churn,"council_support":_council_support(),"office_policy_counts":offices}

func _council_support()->float:
	if GameState.advisor_roster.is_empty(): return 0.5
	var total:=0.0
	var count:=0
	for advisor_variant in GameState.advisor_roster:
		var advisor:Dictionary=advisor_variant
		var relationship:Dictionary=advisor.get("relationships",{}).get("sovereign",{})
		if relationship.is_empty(): continue
		total+=float(relationship.get("trust",0.5))*0.45+float(relationship.get("respect",0.5))*0.35+(1.0-float(relationship.get("resentment",0.0)))*0.20
		count+=1
	return clampf(total/maxi(1,count),0.0,1.0)

func process_day(context: Dictionary) -> Array[Dictionary]:
	initialize()
	refresh_policy_lifecycle()
	GameState.synchronize_population_allocations()
	var previous: Dictionary = GameState.simulation_metrics.duplicate(true)
	var traveling:=bool(context.get("traveling",GameState.convoy_traveling))
	GameState.convoy_traveling=traveling
	var population := maxf(1.0,GameState.population_exact)
	var able_population := maxf(1.0,float(GameState.able_population()))
	var food_workers := float(GameState.population_allocations.get("Food",0))
	var surveyors := float(GameState.population_allocations.get("Survey",0))
	var extractors := float(GameState.population_allocations.get("Extraction",0))
	var builders := float(GameState.population_allocations.get("Construction",0))
	var makers := float(GameState.population_allocations.get("Crafting",0))
	var military_campaign:=get_node_or_null("/root/MilitaryCampaign")
	if military_campaign!=null and military_campaign.has_method("civilian_crafting_fraction"):
		makers*=clampf(float(military_campaign.civilian_crafting_fraction()),0.0,1.0)
	var carriers := float(GameState.population_allocations.get("Logistics",0))
	var observers := float(GameState.population_allocations.get("Knowledge",0))
	var stewards := float(GameState.population_allocations.get("Administration",0))
	var guards := float(GameState.population_allocations.get("Defense",0))
	var dynamics:=GameState.society_capacities
	var governance:=governance_metrics()
	var administrative_load:=float(governance.administrative_load)
	var policy_churn:=float(governance.policy_churn)
	var council_support:=float(governance.council_support)

	var prior_health := float(previous.get("health",GameState.population_health))
	var prior_cohesion := float(previous.get("cohesion",0.58))
	var permanent_housing_ratio := clampf(float(GameState.housing_capacity)/population,0.15,1.12)
	var mobile_shelter_ratio:=clampf(0.20+carriers/maxf(1.0,population*0.10)*0.27+builders/maxf(1.0,population*0.12)*0.17,0.18,0.72)
	mobile_shelter_ratio+=DiscoverySystem.effect("mobile_shelter")
	mobile_shelter_ratio=clampf(mobile_shelter_ratio,0.18,0.86)
	var housing_ratio := mobile_shelter_ratio if traveling else permanent_housing_ratio
	var labor_efficiency := clampf(0.34+prior_health*0.34+prior_cohesion*0.18+housing_ratio*0.12,0.25,1.08)
	labor_efficiency*=lerpf(0.82,1.08,clampf(float(dynamics.get("labor",0.5)),0.0,1.0))
	labor_efficiency*=(1.0+policy_effect("labor_multiplier"))*(1.0-administrative_load)
	labor_efficiency=clampf(labor_efficiency,0.20,1.12)

	var ecology := float(previous.get("ecology",0.88))
	var food_result:Dictionary=_food_system().process_day({"traveling":traveling},labor_efficiency,ecology)
	var industrial_activity:=clampf(float(GameState.material_metrics.get("extracted_today",0.0))/maxf(1.0,population*0.08),0.0,2.0)
	var food_production:=float(food_result.food_production)
	var food_consumption:=float(food_result.food_consumption)
	var food_stored:=float(GameState.resource_stockpiles.get("Food",0.0))
	var food_days:=float(food_result.food_days)
	var production_ratio:=float(food_result.food_balance)+1.0
	var intake_ratio:=float(food_result.food_intake_ratio)
	var malnutrition:=float(food_result.malnutrition_burden)
	if intake_ratio<0.95:
		GameState.consecutive_food_shortage_days+=1.0
	else:
		GameState.consecutive_food_shortage_days=maxf(0.0,GameState.consecutive_food_shortage_days-2.0)
	if traveling and housing_ratio<0.68:
		GameState.convoy_exposure_days+=1.0-housing_ratio
	else:
		GameState.convoy_exposure_days=maxf(0.0,GameState.convoy_exposure_days-1.5)
	var food_security_target := clampf(0.05+minf(1.0,food_days/45.0)*0.30+minf(1.15,production_ratio)*0.25+intake_ratio*0.18+float(food_result.food_diet_quality)*0.12+GameState.nutrition_reserve*0.10-malnutrition*0.24,0.02,0.98)
	GameState.food_security = lerpf(GameState.food_security,food_security_target,0.055)

	var clean_water_bonus := DiscoverySystem.effect("health_protection")+DiscoverySystem.effect("water_safety")*0.25-DiscoverySystem.effect("disease_exposure")*0.18
	var shelter_bonus := 0.0
	if "Hearth Circle" in GameState.settlement_completed: shelter_bonus += 0.05
	if "Lean-to Shelters" in GameState.settlement_completed: shelter_bonus += 0.12
	var travel_health_penalty:=0.0
	if traveling:
		travel_health_penalty=0.08+maxf(0.0,0.62-housing_ratio)*0.30+minf(0.24,GameState.consecutive_food_shortage_days*0.009)
	var process_health_cost:=(DiscoverySystem.effect("health_risk")+DiscoverySystem.effect("pollution")*0.22+DiscoverySystem.effect("water_pollution")*0.18)*industrial_activity
	var health_target := clampf(0.18+GameState.food_security*0.43+float(food_result.food_diet_quality)*0.06+housing_ratio*0.16+clean_water_bonus+shelter_bonus-modifier_strength("sickly_arrival")+policy_effect("health_target")-travel_health_penalty-malnutrition*0.28-process_health_cost,0.05,0.97)
	GameState.population_health = lerpf(GameState.population_health,health_target,0.022)

	var admin_coverage := clampf(stewards/maxf(1.0,population*0.035),0.0,1.25)
	var work_strain := clampf((food_workers+extractors+builders)/able_population,0.0,1.0)
	var economic_social_pressure:=float(GameState.economy_metrics.get("social_pressure",0.0))
	var cohesion_target := clampf(0.24+GameState.food_security*0.26+housing_ratio*0.15+admin_coverage*0.20+DiscoverySystem.effect("state_capacity")*0.08+DiscoverySystem.effect("cohesion")*0.10+(1.0-work_strain)*0.08-modifier_strength("divided_camp")+policy_effect("cohesion_target")-administrative_load*0.10-policy_churn*0.16+economic_social_pressure*0.55,0.08,0.96)
	var cohesion := lerpf(prior_cohesion,cohesion_target,0.014)

	var inquiry_points := 0
	for value in GameState.research_allocations.values(): inquiry_points += int(value)
	var focus_quality := 1.0 if inquiry_points <= maxi(1,int(observers)) else clampf(observers/maxf(1.0,float(inquiry_points)),0.15,1.0)
	var knowledge := float(previous.get("knowledge",0.18))
	var knowledge_gain := observers*labor_efficiency*focus_quality/maxf(3000.0,population*92.0)*(1.0+DiscoverySystem.effect("knowledge_rate"))*lerpf(0.55,1.45,GameState.combined_intelligence)
	knowledge += knowledge_gain*(1.0+modifier_strength("curious_youth")+policy_effect("knowledge_gain"))
	knowledge += float(GameState.known_discoveries.size())/240000.0
	knowledge = clampf(knowledge,0.0,1.0)

	var accessible_count := 0
	for deposit in GameState.resource_deposits:
		if String(deposit.get("stage","unknown")) in ["accessible","developed"]: accessible_count += 1
	var workshop_function:=0.0
	var storage_function:=0.0
	for plot in GameState.settlement_plots:
		if String(plot.get("status","")) not in ["active","stressed","damaged"]: continue
		var use:=String(plot.get("land_use",""))
		if use not in ["workshop","storage"]: continue
		var staffing:=clampf(float(plot.get("worker_count",0))/maxf(1.0,float(plot.get("worker_capacity",1))),0.0,1.0)
		var function:=staffing*clampf(float(plot.get("condition",0.0)),0.0,1.0)
		if use=="workshop": workshop_function+=function
		else: storage_function+=function
	workshop_function=clampf(workshop_function/3.0,0.0,1.0)
	storage_function=clampf(storage_function/3.0,0.0,1.0)
	var craft_coverage := clampf(makers/maxf(1.0,population*0.05),0.0,1.25)
	var material_target := clampf(0.05+craft_coverage*0.38+minf(1.0,float(accessible_count)/4.0)*0.25+knowledge*0.18+workshop_function*0.12+DiscoverySystem.effect("tool_quality")*0.30+DiscoverySystem.effect("craft_output")*0.22+modifier_strength("skilled_craftspeople")+policy_effect("material_target"),0.02,0.96)
	if "Open Work Area" in GameState.settlement_completed: material_target += 0.08
	var material_capacity := lerpf(float(previous.get("material_capacity",0.12)),material_target,0.012)
	var logistics_target := clampf(0.05+carriers/maxf(1.0,population*0.08)*0.55+material_capacity*0.18+storage_function*0.10+DiscoverySystem.effect("haul_capacity")*0.18+DiscoverySystem.effect("route_speed")*0.12+policy_effect("logistics_target"),0.03,0.95)
	var logistics := lerpf(float(previous.get("logistics",0.16)),logistics_target,0.016)
	var security_target := clampf(0.10+guards/maxf(1.0,population*0.05)*0.42+cohesion*0.24+logistics*0.12+DiscoverySystem.effect("warfare_readiness")*0.14-modifier_strength("migratory_pressure")+policy_effect("security_target"),0.04,0.96)
	var security := lerpf(float(previous.get("security",0.38)),security_target,0.016)

	var extraction_pressure := extractors/able_population
	var foraging_pressure := maxf(0.0,food_workers/able_population-0.48)
	var ecology_delta := 0.00018+modifier_strength("sacred_land")*0.00032+policy_effect("ecology_delta")
	ecology_delta -= extraction_pressure*0.00052+foraging_pressure*0.00105
	ecology_delta-=(DiscoverySystem.effect("pollution")+DiscoverySystem.effect("water_pollution"))*industrial_activity*0.0009
	ecology = clampf(ecology+ecology_delta,0.04,1.0)
	var legitimacy_target := clampf(0.12+GameState.food_security*0.26+GameState.population_health*0.18+cohesion*0.20+security*0.10+admin_coverage*0.10+DiscoverySystem.effect("legitimacy")*0.12+float(dynamics.get("institutions",0.25))*0.05+(council_support-0.5)*0.06+policy_effect("legitimacy_target")-administrative_load*0.12-policy_churn*0.18+economic_social_pressure,0.06,0.96)
	var legitimacy := lerpf(float(previous.get("legitimacy",0.62)),legitimacy_target,0.012)

	# Mortality is accumulated as population-level risk, while reproduction is
	# resolved by the named citizens themselves: conception, gestation, loss,
	# delivery, parentage, postpartum recovery, and maternal/neonatal outcomes.
	var birth_crisis:=intake_ratio<0.82 or malnutrition>0.38
	var mortality_components := {
		"Natural causes":0.008+(1.0-GameState.population_health)*0.005,
		"Hunger":0.0,
		"Illness":maxf(0.0,0.50-GameState.population_health)*0.055*maxf(0.35,1.0+DiscoverySystem.effect("disease_exposure")-DiscoverySystem.effect("sanitation")),
		"Exposure":maxf(0.0,0.68-housing_ratio)*(0.24 if traveling else 0.040),
		"Travel exhaustion":0.0,
		"Insecurity":maxf(0.0,0.30-security)*0.025
	}
	mortality_components["Work accidents"]=(0.002+extraction_pressure*0.025)*industrial_activity*maxf(0.15,1.0+DiscoverySystem.effect("disaster_risk")-DiscoverySystem.effect("mine_safety"))
	if intake_ratio<0.98 or malnutrition>0.05:
		var shortage_ramp:=clampf((GameState.consecutive_food_shortage_days-5.0)/45.0,0.0,1.0)
		mortality_components["Hunger"]=maxf(0.0,1.0-intake_ratio)*(0.08+shortage_ramp*0.90)+malnutrition*0.42
	if traveling:
		var exhaustion_ramp:=clampf((GameState.convoy_exposure_days-4.0)/45.0,0.0,1.0)
		mortality_components["Travel exhaustion"]=maxf(0.0,0.72-housing_ratio)*(0.08+exhaustion_ramp*0.32)
	var annual_death_rate := 0.0
	for component_rate in mortality_components.values():
		annual_death_rate+=float(component_rate)
	GameState.simulation_metrics["annual_death_rate"]=annual_death_rate
	GameState.simulation_metrics["mortality_components"]=mortality_components.duplicate(true)
	GameState.death_progress+=population*annual_death_rate/365.0
	var deaths_today:=floori(GameState.death_progress)
	GameState.death_progress-=deaths_today
	if GameState.population_total-deaths_today<1:
		deaths_today=maxi(0,GameState.population_total-1)
	var dominant_cause := "Natural causes"
	for cause in mortality_components:
		if float(mortality_components[cause])>float(mortality_components[dominant_cause]):
			dominant_cause=String(cause)
	var deceased_names:Array[String]=[]
	if deaths_today>0:
		deceased_names=GameState.register_deaths(deaths_today,dominant_cause)
	var reproduction:=GameState.process_reproduction_day({
		"health":GameState.population_health,"food_security":GameState.food_security,
		"housing_ratio":housing_ratio,"cohesion":cohesion,"traveling":traveling,
		"birth_crisis":birth_crisis,"conception_support":DiscoverySystem.effect("conception_support")+policy_effect("conception_support"),
		"maternal_safety":DiscoverySystem.effect("maternal_safety"),"neonatal_survival":DiscoverySystem.effect("neonatal_survival")
	})
	var births_today:=int((reproduction.get("births",[]) as Array).size())
	var born_names:Array[String]=[]
	var parentage:Array[String]=[]
	for newborn_variant in reproduction.get("births",[]):
		var newborn:Dictionary=newborn_variant
		born_names.append(String(newborn.get("name","Unnamed newborn")))
		var mother:=GameState.citizen_by_id(int(newborn.get("mother_id",-1)))
		var father:=GameState.citizen_by_id(int(newborn.get("father_id",-1)))
		parentage.append("%s — child of %s and %s" % [String(newborn.get("name","Unnamed newborn")),String(mother.get("name","unknown")),String(father.get("name","unknown"))])
	GameState.population_total=maxi(1,GameState.living_citizen_count())
	GameState.population_exact=float(GameState.population_total)
	var events: Array[Dictionary] = []
	if births_today>0:
		var birth_cause:="Birth during migration" if traveling else "Births"
		events.append(_record_demographic_change("birth",births_today,birth_cause,food_days,production_ratio,housing_ratio,born_names," Parentage: %s." % "; ".join(parentage)))
	if deaths_today>0:
		events.append(_record_demographic_change("death",deaths_today,dominant_cause,food_days,production_ratio,housing_ratio,deceased_names))
	var reproductive_deaths_by_cause:Dictionary={}
	for death_variant in reproduction.get("deaths",[]):
		var death:Dictionary=death_variant
		var cause:=String(death.get("cause","Reproductive complications"))
		if not reproductive_deaths_by_cause.has(cause): reproductive_deaths_by_cause[cause]=[]
		(reproductive_deaths_by_cause[cause] as Array).append(String(death.get("name","Unknown")))
	for cause in reproductive_deaths_by_cause:
		var people:Array=reproductive_deaths_by_cause[cause]
		var typed_people:Array[String]=[]
		for person_name in people: typed_people.append(String(person_name))
		events.append(_record_demographic_change("death",typed_people.size(),String(cause),food_days,production_ratio,housing_ratio,typed_people))
	for loss_variant in reproduction.get("losses",[]):
		var loss:Dictionary=loss_variant
		var reason:=String(loss.get("reason","Pregnancy loss"))
		var loss_title:="Stillbirth" if reason=="Stillbirth" else "Pregnancy Lost"
		var loss_event:=_add_event(loss_title,"%s's pregnancy ended after %d days of gestation. Recorded cause: %s. Conditions at the time: health %d%%, stores %.1f days, shelter %d%%." % [String(loss.get("mother","Unknown")),int(loss.get("gestation_days",0)),reason,roundi(GameState.population_health*100.0),food_days,roundi(housing_ratio*100.0)],"population","warning")
		events.append(loss_event)
	var annual_birth_rate:=float(reproduction.get("projected_birth_rate",0.0))

	var settlement_score := clampf(float(GameState.settlement_completed.size())/8.0,0.0,1.0)
	GameState.simulation_metrics = {
		"health":GameState.population_health,"labor_efficiency":labor_efficiency,"cohesion":cohesion,"knowledge":knowledge,
		"material_capacity":material_capacity,"logistics":logistics,"security":security,"ecology":ecology,"legitimacy":legitimacy,
		"governance_administrative_load":administrative_load,"governance_policy_churn":policy_churn,"governance_council_support":council_support,"governance_active_policies":int(governance.active_policy_count),
		"resource_access":float(accessible_count),"settlement":settlement_score,"population":GameState.population_exact,
		"annual_birth_rate":annual_birth_rate,"annual_death_rate":annual_death_rate,"traveling":traveling,
		"mortality_components":mortality_components.duplicate(true),
		"active_pregnancies":int(reproduction.get("active_pregnancies",0)),"eligible_parents":int(reproduction.get("eligible_parents",0)),
		"annual_conceptions_expected":float(reproduction.get("annual_conceptions_expected",0.0)),"projected_live_births":float(reproduction.get("projected_live_births",0.0)),
		"births_expected_next_year":float(reproduction.get("births_expected_next_year",0.0)),
		"mobile_shelter_ratio":mobile_shelter_ratio,"food_shortage_days":GameState.consecutive_food_shortage_days,
		"travel_speed_factor":_travel_speed_factor(GameState.population_health,GameState.food_security,production_ratio,food_stored,traveling),
		"survey_capacity":surveyors*labor_efficiency,"construction_capacity":builders*labor_efficiency*(1.0+workshop_function*0.10),"combined_intelligence":GameState.combined_intelligence,
		"workshop_function":workshop_function,"storage_function":storage_function
	}
	for dynamic_name in GameState.society_capacities:
		GameState.simulation_metrics["society_"+String(dynamic_name)]=GameState.society_capacities[dynamic_name]
	for food_metric in food_result:
		GameState.simulation_metrics[food_metric]=food_result[food_metric]
	for material_metric in GameState.material_metrics:
		GameState.simulation_metrics["material_"+String(material_metric)]=GameState.material_metrics[material_metric]
	_refresh_all_policy_observations()
	GameState.simulation_trends.clear()
	for key in GameState.simulation_metrics:
		if previous.has(key) and GameState.simulation_metrics[key] is float:
			GameState.simulation_trends[key]=float(GameState.simulation_metrics[key])-float(previous[key])

	var forecast_90:Dictionary=food_result.get("food_forecast_90",{})
	var forecast_shortage:=int(forecast_90.get("first_shortage_day",-1))
	if forecast_shortage>0: _threshold_event(events,"projected_food_shortage","Shortage Forecast","At the present allocation and seasonal outlook, the stores fail in about %d days. The projection includes expected harvest and spoilage." % forecast_shortage,"food","danger",20)
	elif food_days < 14.0 and float(food_result.food_net)<0.0: _threshold_event(events,"low_food","Stores Are Falling","Only %.1f days remain and today's provision balance is %+.1f rations." % [food_days,float(food_result.food_net)],"food","warning",30)
	if food_days < 3.0 and (float(food_result.food_net)<0.0 or intake_ratio<0.98):
		var famine_title:="Hunger on the Road" if traveling else "Hunger in the Camp"
		var famine_description:="The convoy has nearly exhausted its provisions. Travel, health, and population are now at immediate risk." if traveling else "Food stores are nearly gone. Health and population will now deteriorate rapidly."
		_threshold_event(events,"famine",famine_title,famine_description,"health","critical",12)
	if traveling and food_stored<=0.001 and intake_ratio<0.98: _threshold_event(events,"convoy_without_provisions","The Convoy Is Living Hand to Mouth","No provisions remain. Route foraging supplies only %d%% of today's need; body reserves are at %d%%." % [roundi(intake_ratio*100.0),roundi(GameState.nutrition_reserve*100.0)],"food","critical",7)
	if GameState.population_health < 0.46: _threshold_event(events,"ill_health","Widespread Illness","Poor nutrition, exposure, and water conditions are reducing effective labor.","health","danger",45)
	if ecology < 0.55: _threshold_event(events,"ecology_strain","The Land Is Thinning","Gatherers report longer journeys and diminishing returns near the settlement.","ecology","warning",120)
	if legitimacy < 0.42: _threshold_event(events,"authority_strain","Orders Meet Resistance","Hardship and weak administration are eroding compliance with sovereign priorities.","legitimacy","warning",60)
	_check_goal(events)
	return events

func _population_location() -> String:
	if GameState.convoy_traveling:
		return "the traveling people in %s" % GameState.province_name
	if GameState.settlement_completed.is_empty():
		return "the halted founding convoy in %s" % GameState.province_name
	if GameState.settlement_name.strip_edges()!="":
		return "%s in %s" % [GameState.settlement_name,GameState.province_name]
	if GameState.settlement_completed.size()<3:
		return "the founding camp in %s" % GameState.province_name
	return "the settlement in %s" % GameState.province_name

func _record_demographic_change(kind: String,count: int,cause: String,food_days: float,production_ratio: float,housing_ratio: float,people: Array[String],identity_context:="") -> Dictionary:
	var location:=_population_location()
	var day:=int(GameState.elapsed_days)
	var cause_detail:=""
	match cause:
		"Hunger": cause_detail="Food stores were exhausted and daily production met only %d%% of need." % roundi(production_ratio*100.0)
		"Illness": cause_detail="Poor health was the strongest mortality pressure."
		"Exposure": cause_detail="Shelter covered only %d%% of the population." % roundi(housing_ratio*100.0)
		"Travel exhaustion": cause_detail="Sustained travel, inadequate shelter, and declining strength made the journey fatal."
		"Insecurity": cause_detail="Low security was the strongest exceptional mortality pressure."
		"Births": cause_detail="Food security, health, shelter, and social stability supported new births."
		"Birth during migration": cause_detail="A child was born during a provisioned stage of the migration."
		"Complications of childbirth": cause_detail="The parent died during or immediately after delivery."
		"Neonatal complications": cause_detail="The newborn died during the immediate period after birth."
		_: cause_detail="No exceptional crisis outweighed ordinary mortality."
	var identity_detail:=" Those recorded: %s." % ", ".join(people) if not people.is_empty() else ""
	var description:="%s %s Health: %d%%. Stored provisions: %.1f days. Shelter: %d%%.%s%s" % [cause_detail,"Location: %s." % location,roundi(GameState.population_health*100.0),food_days,roundi(housing_ratio*100.0),identity_detail,identity_context]
	var noun:="birth" if kind=="birth" else "death"
	var title:="%d %s%s at %s" % [count,noun,"" if count==1 else "s",location]
	var record:={
		"id":"demographic_%s_%d_%d" % [kind,day,GameState.demographic_ledger.size()],
		"day":day,"start_day":day,"end_day":day,"title":title,"description":description,
		"domain":"population","severity":"demographic","kind":kind,"count":count,
		"cause":cause,"location":location,"food_days":food_days,"production_ratio":production_ratio,
		"health":GameState.population_health,"housing_ratio":housing_ratio,"population_after":GameState.population_total,"people":people.duplicate(),
		"traveling":GameState.convoy_traveling,"food_shortage_days":GameState.consecutive_food_shortage_days
	}
	# Consecutive changes from the same pressure are grouped into a readable
	# episode while preserving its first and last day.
	if not GameState.demographic_ledger.is_empty():
		var recent:Dictionary=GameState.demographic_ledger[0]
		if String(recent.get("kind",""))==kind and String(recent.get("cause",""))==cause and String(recent.get("location",""))==location and day-int(recent.get("end_day",day))<=14:
			recent["count"]=int(recent.get("count",0))+count
			recent["end_day"]=day
			recent["day"]=day
			recent["food_days"]=food_days
			recent["production_ratio"]=production_ratio
			recent["health"]=GameState.population_health
			recent["housing_ratio"]=housing_ratio
			recent["population_after"]=GameState.population_total
			var recent_people:Array=recent.get("people",[])
			recent_people.append_array(people)
			recent["people"]=recent_people
			var total:=int(recent.count)
			recent["title"]="%d %s%s at %s" % [total,noun,"" if total==1 else "s",location]
			recent["description"]=description
			GameState.demographic_ledger[0]=recent
			for i in GameState.simulation_events.size():
				if String(GameState.simulation_events[i].get("id",""))==String(recent.id):
					GameState.simulation_events[i]=recent
					break
			if kind=="birth": GameState.lifetime_births+=count
			else: GameState.lifetime_deaths+=count
			return recent
	GameState.demographic_ledger.push_front(record)
	if GameState.demographic_ledger.size()>120: GameState.demographic_ledger.resize(120)
	GameState.simulation_events.push_front(record)
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
	if kind=="birth": GameState.lifetime_births+=count
	else: GameState.lifetime_deaths+=count
	return record

func _travel_speed_factor(health: float,food_security: float,production_ratio: float,food_stored: float,traveling: bool) -> float:
	if not traveling:
		return 1.0
	var factor:=0.22+health*0.46+food_security*0.24
	if food_stored<=0.001:
		factor*=clampf(0.24+production_ratio*0.62,0.22,0.78)
	factor*=1.0-clampf(GameState.convoy_exposure_days/240.0,0.0,0.28)
	return clampf(factor,0.12,1.0)

func discovery_multiplier() -> float:
	initialize()
	return clampf(0.40+float(GameState.simulation_metrics.get("knowledge",0.18))*0.45+float(GameState.simulation_metrics.get("labor_efficiency",0.72))*0.18+GameState.combined_intelligence*0.55+DiscoverySystem.effect("observation_rate")*0.20,0.35,1.65)

func tools_factor() -> float:
	initialize()
	return clampf(0.18+float(GameState.simulation_metrics.get("material_capacity",0.12))*0.92,0.18,1.10)

func survey_factor() -> float:
	return clampf(float(GameState.simulation_metrics.get("labor_efficiency",0.72))*(1.0+modifier_strength("mineral_signs")),0.25,1.45)

func goal_progress() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for condition in GameState.campaign_goal.get("conditions",[]):
		var metric := String(condition.get("metric",""))
		var target := float(condition.get("target",1.0))
		var current := _metric_value(metric)
		var direction := String(condition.get("direction","above"))
		var achieved := current>=target if direction=="above" else current<=target
		var progress := clampf(current/maxf(0.0001,target),0.0,1.0) if direction=="above" else clampf(target/maxf(0.0001,current),0.0,1.0)
		results.append({"metric":metric,"target":target,"current":current,"direction":direction,"achieved":achieved,"progress":progress})
	return results

func _metric_value(metric: String) -> float:
	if metric=="population": return GameState.population_exact
	if metric=="discoveries": return float(GameState.known_discoveries.size())
	if metric=="completed_works": return float(GameState.settlement_completed.size())
	return float(GameState.simulation_metrics.get(metric,0.0))

func _check_goal(events: Array[Dictionary]) -> void:
	if GameState.campaign_goal_status!="active" or GameState.campaign_goal.is_empty(): return
	var complete := true
	for condition in goal_progress():
		if not bool(condition.achieved): complete=false
	var deadline := float(GameState.campaign_goal.get("horizon_years",80.0))*365.0
	if complete:
		GameState.campaign_goal_status="achieved"
		var event := _add_event("Mandate Fulfilled","The civilization has fulfilled every condition of its founding mandate.","mandate","triumph")
		events.append(event)
	elif GameState.elapsed_days>deadline:
		GameState.campaign_goal_status="failed"
		var event := _add_event("Mandate Broken","The founding horizon has passed with essential promises unfulfilled.","mandate","critical")
		events.append(event)

func _threshold_event(events: Array[Dictionary],id: String,title: String,description: String,domain: String,severity: String,cooldown: int) -> void:
	var last_day := int(GameState.last_simulation_event_days.get(id,-100000))
	if int(GameState.elapsed_days)-last_day<cooldown: return
	GameState.last_simulation_event_days[id]=int(GameState.elapsed_days)
	var event := _add_event(title,description,domain,severity)
	events.append(event)

func _add_event(title: String,description: String,domain: String,severity: String) -> Dictionary:
	var event := {"day":int(GameState.elapsed_days),"title":title,"description":description,"domain":domain,"severity":severity}
	GameState.simulation_events.push_front(event)
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
	return event
