extends Node

const SOCIETAL_VALUES_MODEL:=preload("res://scripts/societal_values_model.gd")

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
	GameState.initialize_population_model()
	GameState.synchronize_population_allocations()
	if GameState.resource_stockpiles.is_empty():
		ResourceSystem.initialize()
	GameState.simulation_metrics["health"] = GameState.population_health

func directive_assessment(effect_id:String,requested_magnitude:float,duration_days:float,office_execution:float=1.0,directive_parameters:Dictionary={})->Dictionary:
	initialize()
	if not GovernmentPolicyCatalog.has_policy(effect_id):
		return {"can_apply":false,"blocker":"No simulated institution recognizes this directive.","id":effect_id}
	var contract:=GovernmentPolicyCatalog.directive_contract(effect_id)
	if contract.is_empty():
		return {"can_apply":false,"blocker":"This directive has no bounded implementation contract.","id":effect_id}
	var population:=maxf(1.0,GameState.population_exact)
	var administration_share:=float(GameState.population_allocations.get("Administration",0))/population
	var defense_share:=float(GameState.population_allocations.get("Defense",0))/population
	var institutions:=clampf(float(GameState.society_capacities.get("institutions",0.0)),0.0,1.0)
	var security:=clampf(float(GameState.simulation_metrics.get("security",GameState.society_capacities.get("security",0.0))),0.0,1.0)
	var legitimacy:=clampf(float(GameState.simulation_metrics.get("legitimacy",0.5)),0.0,1.0)
	var cohesion:=clampf(float(GameState.simulation_metrics.get("cohesion",0.5)),0.0,1.0)
	var administration_capacity:=clampf(institutions*0.62+clampf(administration_share/0.06,0.0,1.0)*0.38,0.0,1.0)
	var security_capacity:=clampf(security*0.72+clampf(defense_share/0.08,0.0,1.0)*0.28,0.0,1.0)
	var administration_required:=clampf(float(contract.get("administration_required",0.0)),0.0,1.0)
	var security_required:=clampf(float(contract.get("security_required",0.0)),0.0,1.0)
	var administration_factor:=1.0 if administration_required<=0.0001 else clampf(administration_capacity/administration_required,0.0,1.0)
	var security_factor:=1.0 if security_required<=0.0001 else clampf(security_capacity/security_required,0.0,1.0)
	var knowledge_factor:=1.0
	var missing_discoveries:Array[String]=[]
	for discovery_variant in contract.get("required_discoveries",[]):
		var discovery:=String(discovery_variant)
		if discovery not in GameState.known_discoveries: missing_discoveries.append(discovery)
	if not missing_discoveries.is_empty(): knowledge_factor=0.0
	var recognized_resource:=String(contract.get("recognized_resource",""))
	var resource_recognition_factor:=1.0
	if not recognized_resource.is_empty():
		var recognized:=float(GameState.resource_stockpiles.get(recognized_resource,0.0))>0.0001
		for deposit_variant in GameState.resource_deposits:
			var deposit:Dictionary=deposit_variant
			if String(deposit.get("resource",""))==recognized_resource and String(deposit.get("stage","unknown"))!="unknown": recognized=true; break
		resource_recognition_factor=1.0 if recognized else 0.0
	var coercion:=clampf(float(contract.get("coercion",0.0)),0.0,1.0)
	var compliance:=clampf(0.12+legitimacy*0.38+cohesion*0.34+(1.0-coercion)*0.12+security_capacity*coercion*0.28,0.05,0.98)
	var resistance:=clampf(1.0-compliance+coercion*(1.0-security_capacity)*0.25,0.0,1.0)
	var requested:=clampf(requested_magnitude,0.0,0.25)
	var duration:=clampf(duration_days,7.0,730.0)
	var stored_food:=maxf(0.0,float(_food_system().call("total_stored")))
	var food_reserve_floor:=population*2.0
	var food_available:=maxf(0.0,stored_food-food_reserve_floor)
	var food_requested:=population*maxf(0.0,float(contract.get("food_rations_per_capita",0.0)))*requested
	var material_available:=_directive_material_available()
	var material_requested:=population/1000.0*maxf(0.0,float(contract.get("material_bulk_per_1000",0.0)))*requested
	var food_factor:=1.0 if food_requested<=0.0001 else clampf(food_available/food_requested,0.0,1.0)
	var material_factor:=1.0 if material_requested<=0.0001 else clampf(material_available/material_requested,0.0,1.0)
	var resource_factor:=minf(food_factor,material_factor)
	var active_count:=active_policies().size()
	var capacity_slots:=maxi(1,1+floori(institutions*6.0)+floori(clampf(administration_share/0.04,0.0,1.0)*2.0))
	var capacity_factor:=clampf(float(maxi(0,capacity_slots-active_count))/float(capacity_slots),0.08,1.0)
	var operation:=String(contract.get("operation",""))
	var operation_quote:Dictionary={}
	var operation_factor:=1.0
	if operation=="recruitment_scouts":
		var mission_days:=_scout_operation_days(duration)
		operation_quote=CivilizationSystem.scout_mission_quote(mission_days,"recruit_people")
		operation_factor=1.0 if bool(operation_quote.get("can_dispatch",false)) else 0.0
	var implementation_rate:=clampf(clampf(office_execution,0.0,1.12)*administration_factor*security_factor*resource_factor*capacity_factor*knowledge_factor*resource_recognition_factor*operation_factor*(0.45+compliance*0.55),0.0,1.0)
	var effective_magnitude:=clampf(requested*implementation_rate,0.0,0.25)
	var blockers:Array[String]=[]
	if administration_factor<0.25: blockers.append("administrative coverage is far below the directive's requirement")
	if security_factor<0.25: blockers.append("enforcement capacity is far below the directive's requirement")
	if food_factor<0.25: blockers.append("physical food stores cannot fund implementation while preserving a two-day reserve")
	if material_factor<0.25: blockers.append("physical material stores cannot fund implementation")
	if capacity_factor<=0.081: blockers.append("the current administration is already carrying more standing directives than it can execute")
	if not missing_discoveries.is_empty(): blockers.append("the required practice is not known: %s" % ", ".join(missing_discoveries).replace("_"," "))
	if resource_recognition_factor<=0.0: blockers.append("no recognized %s source or stored supply exists" % recognized_resource.to_lower())
	if operation_factor<=0.0: blockers.append(String(operation_quote.get("blocker",operation_quote.get("error","the physical expedition cannot depart"))))
	var direct_plan:Dictionary={}
	var counted_target:Dictionary=directive_parameters.get("demographic_target",{})
	var counted_action:=effect_id=="mass_repression" and counted_target.has("exact_count")
	for channel_variant in (contract.get("direct_effects",{}) as Dictionary):
		var channel:=String(channel_variant)
		var coefficient:=float((contract.direct_effects as Dictionary)[channel])
		if channel=="population_deaths_share":
			var target:Dictionary=directive_parameters.get("demographic_target",{})
			var target_population:=_directive_target_population(target,population)
			var raw_deaths:=floori((target_population if String(target.get("scope",""))=="all" else population*maxf(0.0,coefficient)*requested)*implementation_rate)
			var annual_capacity:=_remaining_directive_death_capacity(population,security_capacity)
			if counted_action:
				annual_capacity=floori(float(GameState.population_cohorts.get("working_age",0))*security_capacity)
				# A person is indivisible. Require the full explicit count; never round
				# a single act down through standing-policy magnitude/compliance.
				raw_deaths=maxi(0,int(target.exact_count))
				if raw_deaths>floori(target_population) or raw_deaths>annual_capacity or implementation_rate<=0.0:
					raw_deaths=0
			direct_plan["population_deaths"]=mini(raw_deaths,annual_capacity)
		else:
			direct_plan[channel]=clampf(coefficient*requested*implementation_rate,-0.08,0.08)
	var estimates:=DecreeStatistics.validate(directive_parameters.get("statistical_effects",[]))
	if counted_action:
		# Scale fallback social consequences to the actual fraction affected.
		var scale:=clampf(float(direct_plan.get("population_deaths",0))/maxf(1.0,population*requested),0.0,1.0)
		for channel in direct_plan:
			if channel!="population_deaths": direct_plan[channel]*=scale
	if not estimates.is_empty():
		# The accepted model plan replaces direct metric defaults, avoiding double counting.
		for metric in DecreeStatistics.METRICS: direct_plan.erase(metric+"_delta")
		for estimate in estimates: direct_plan[String(estimate.metric)+"_delta"]=float(estimate.delta)*implementation_rate
	var can_apply:=effective_magnitude>=0.0025
	if counted_action: can_apply=int(direct_plan.get("population_deaths",0))==int(counted_target.exact_count) and int(counted_target.exact_count)>0
	var blocker:=""
	if not can_apply:
		blocker="; ".join(blockers) if not blockers.is_empty() else "Implementation capacity is too low to produce a measurable effect."
		if counted_action: blocker="The requested count is %d; eligible population is %d and available enforcement capacity is %d. No one was killed and no effects were applied." % [int(counted_target.exact_count),floori(_directive_target_population(counted_target,population)),floori(float(GameState.population_cohorts.get("working_age",0))*security_capacity)]
	return {
		"id":effect_id,"domain":String(contract.get("domain","social")),"can_apply":can_apply,
		"blocker":blocker,"limitations":blockers,
		"requested_magnitude":requested,"effective_magnitude":effective_magnitude,"duration_days":duration,
		"implementation_rate":implementation_rate,"office_execution":clampf(office_execution,0.0,1.12),
		"capacity":{"active":active_count,"slots":capacity_slots,"factor":capacity_factor},
		"constraints":{"administration":{"available":administration_capacity,"required":administration_required,"factor":administration_factor},"security":{"available":security_capacity,"required":security_required,"factor":security_factor},"knowledge":{"missing":missing_discoveries,"factor":knowledge_factor},"recognized_resource":{"name":recognized_resource,"factor":resource_recognition_factor},"operation":{"kind":operation,"quote":operation_quote,"factor":operation_factor}},
		"costs":{"food_requested":food_requested,"food_available":food_available,"food_planned":food_requested*implementation_rate,"materials_requested":material_requested,"materials_available":material_available,"materials_planned":material_requested*implementation_rate},
		"compliance":compliance,"resistance":resistance,"coercion":coercion,"direct_effects_planned":direct_plan,
		"second_order_consequence":String(contract.get("second_order","The directive changes simulated conditions.")),"directive_parameters":directive_parameters.duplicate(true),"operation":operation,"operation_quote":operation_quote,"deadline_enforcement":String(contract.get("deadline_enforcement","")),"bounded":true
	}

func _scout_operation_days(requested_days:float)->int:
	var best:=90
	var distance:=INF
	for candidate in [30,90,180,365]:
		var candidate_distance:=absf(float(candidate)-requested_days)
		if candidate_distance<distance:
			distance=candidate_distance
			best=candidate
	return best

func _directive_target_population(target:Dictionary,population:float)->float:
	if target.is_empty(): return population
	GameState.initialize_population_model()
	var eligible:=0.0
	var age_cohorts:Array=target.get("age_cohorts",[])
	if age_cohorts.is_empty(): eligible=population
	else:
		for cohort_variant in age_cohorts:
			eligible+=maxf(0.0,float(GameState.population_cohorts.get(String(cohort_variant),0.0)))
	var sex:=String(target.get("sex",""))
	if sex in ["female","male"]:
		eligible*=clampf(float(GameState.population_cohorts.get(sex,population*0.5))/maxf(1.0,population),0.0,1.0)
	return clampf(eligible,0.0,maxf(0.0,population-1.0))

func apply_directive(effect_id:String,requested_magnitude:float,duration_days:float,source:String,metadata:Dictionary={},office_execution:float=1.0)->Dictionary:
	var source_id:=String(metadata.get("source_order_id",""))
	if not source_id.is_empty():
		for prior in GameState.active_modifiers:
			if String(prior.get("source_order_id",""))==source_id and String(prior.get("id",""))==effect_id:
				return {"applied":false,"stale":true,"error":"This order already has an execution record."}
	var directive_parameters:Dictionary=metadata.get("directive_parameters",{})
	var assessment:=directive_assessment(effect_id,requested_magnitude,duration_days,office_execution,directive_parameters)
	assessment["source_order_id"]=String(metadata.get("source_order_id",""))
	if not bool(assessment.get("can_apply",false)):
		return {"applied":false,"assessment":assessment,"error":String(assessment.get("blocker","Directive cannot be implemented."))}
	if String(assessment.get("operation",""))=="recruitment_scouts":
		var mission_days:=_scout_operation_days(float(assessment.get("duration_days",90.0)))
		var operation_result:=CivilizationSystem.dispatch_scouts(mission_days,"recruit_people")
		if not bool(operation_result.get("ok",false)):
			return {"applied":false,"assessment":assessment,"error":String(operation_result.get("error","The recruitment expedition could not depart."))}
		assessment["operation_result"]=operation_result.duplicate(true)
		_add_event("Recruitment Expedition Ordered",String(operation_result.get("message",source)),"demographic","notice")
		return {"applied":true,"assessment":assessment,"direct_effects":{},"costs":{"food_paid":float((operation_result.get("status",{}) as Dictionary).get("provisions",0.0)),"materials_paid":0.0},"operation_result":operation_result}
	var directive_metadata:=metadata.duplicate(true)
	directive_metadata["directive_domain"]=String(assessment.domain)
	directive_metadata["implementation_rate"]=float(assessment.implementation_rate)
	directive_metadata["implementation_capacity"]=(assessment.capacity as Dictionary).duplicate(true)
	directive_metadata["implementation_constraints"]=(assessment.constraints as Dictionary).duplicate(true)
	directive_metadata["directive_costs"]=(assessment.costs as Dictionary).duplicate(true)
	directive_metadata["compliance"]=float(assessment.compliance)
	directive_metadata["resistance"]=float(assessment.resistance)
	directive_metadata["coercion"]=float(assessment.coercion)
	directive_metadata["direct_effects_planned"]=(assessment.direct_effects_planned as Dictionary).duplicate(true)
	directive_metadata["second_order_consequence"]=String(assessment.second_order_consequence)
	directive_metadata["directive_parameters"]=(assessment.get("directive_parameters",{}) as Dictionary).duplicate(true)
	var deadline_enforcement:=String(assessment.get("deadline_enforcement",""))
	if not deadline_enforcement.is_empty():
		directive_metadata["deadline_enforcement"]=deadline_enforcement
		directive_metadata["deadline_resolved"]=false
		directive_metadata["deadline_baseline_pregnancies"]=GameState.estimated_active_pregnancies()
		directive_metadata["deadline_baseline_conceptions"]=GameState.lifetime_conceptions
		directive_metadata["deadline_target_households"]=_pronatalist_target_households()
	var applied:=apply_policy(effect_id,float(assessment.effective_magnitude),float(assessment.duration_days),source,directive_metadata)
	if not applied:
		return {"applied":false,"assessment":assessment,"stale":true,"error":"A newer or identical directive already controls this policy."}
	var costs:Dictionary=assessment.costs
	var food_paid:=float(_food_system().call("issue_for_obligation",float(costs.get("food_planned",0.0)),"directive","Directive: %s" % effect_id.replace("_"," "),float(assessment.duration_days),0))
	var materials_paid:=_withdraw_directive_materials(float(costs.get("materials_planned",0.0)))
	costs["food_paid"]=food_paid
	costs["materials_paid"]=materials_paid
	assessment["costs"]=costs
	var direct_effects:=_apply_directive_direct_effects(effect_id,assessment)
	assessment["direct_effects_applied"]=direct_effects
	for modifier_variant in GameState.active_modifiers:
		var modifier:Dictionary=modifier_variant
		if String(modifier.get("id",""))!=effect_id or String(modifier.get("source_order_id",""))!=String(metadata.get("source_order_id","")): continue
		modifier["directive_costs"]=costs.duplicate(true)
		modifier["direct_effects_applied"]=direct_effects.duplicate(true)
		if bool(directive_parameters.get("one_time",false)):
			# Retain the receipt for saves/reviews, without a standing repression program.
			modifier["effects"]={}
			modifier["ended_reason"]="completed"
			modifier["until_day"]=GameState.elapsed_days-0.001
		break
	var consequence:=String(assessment.second_order_consequence)
	var implementation_phrase:="Implementation is broad" if float(assessment.implementation_rate)>=0.72 else "Implementation is uneven" if float(assessment.implementation_rate)>=0.36 else "Implementation is narrow"
	var resistance_phrase:="Open resistance is widespread" if float(assessment.resistance)>=0.60 else "Resistance is visible" if float(assessment.resistance)>=0.35 else "Little open resistance is yet visible"
	_add_event("Directive Implemented","%s %s; %s. %s" % [source,implementation_phrase,resistance_phrase,consequence],String(assessment.domain),"danger" if float(assessment.resistance)>=0.60 else "warning" if float(assessment.resistance)>=0.35 else "notice")
	return {"applied":true,"assessment":assessment,"direct_effects":direct_effects,"costs":costs}

func _pronatalist_target_households()->int:
	# Households are not individual agents. Infer a conservative bounded count from
	# the fixed age cohorts: the smaller of likely parents and children, discounted
	# to approximate one-child households. This remains O(1) at world scale.
	GameState.initialize_population_model()
	var likely_parents:=float(GameState.population_cohorts.get("youth",0.0))*0.22+float(GameState.population_cohorts.get("early_adults",0.0))*0.62+float(GameState.population_cohorts.get("established_adults",0.0))*0.68+float(GameState.population_cohorts.get("mature_adults",0.0))*0.18
	var children:=float(GameState.population_cohorts.get("children",0.0))
	return clampi(roundi(minf(likely_parents,children)*0.46),0,maxi(0,roundi(GameState.population_exact/3.0)))

func _directive_material_available()->float:
	var total:=0.0
	for resource_variant in GameState.resource_stockpiles:
		var resource:=String(resource_variant)
		if resource in ["Food","Freshwater"]: continue
		total+=maxf(0.0,float(GameState.resource_stockpiles.get(resource,0.0)))
	return total

func _withdraw_directive_materials(requested:float)->float:
	var remaining:=maxf(0.0,requested)
	var resources:Array[String]=[]
	for resource_variant in GameState.resource_stockpiles:
		var resource:=String(resource_variant)
		if resource not in ["Food","Freshwater"]: resources.append(resource)
	resources.sort()
	for resource in resources:
		if remaining<=0.0001: break
		var stored:=maxf(0.0,float(GameState.resource_stockpiles.get(resource,0.0)))
		var used:=minf(stored,remaining)
		GameState.resource_stockpiles[resource]=stored-used
		remaining-=used
	return maxf(0.0,requested-remaining)

func _remaining_directive_death_capacity(population:float,security_capacity:float)->int:
	var recent:=0
	var current_day:=int(GameState.elapsed_days)
	for record_variant in GameState.demographic_ledger:
		var record:Dictionary=record_variant
		if current_day-int(record.get("day",current_day))>365: continue
		if String(record.get("cause","")).begins_with("Directive:"): recent+=maxi(0,int(record.get("count",0)))
	var annual_capacity:=mini(maxi(0,roundi(population)-1),roundi(float(GameState.population_allocations.get("Defense",0))*3.0+population*security_capacity*0.002))
	return maxi(0,annual_capacity-recent)

func _apply_directive_direct_effects(effect_id:String,assessment:Dictionary)->Dictionary:
	var applied:Dictionary={}
	var planned:Dictionary=assessment.get("direct_effects_planned",{})
	var metric_map:={"health_delta":"health","cohesion_delta":"cohesion","knowledge_delta":"knowledge","security_delta":"security","ecology_delta":"ecology","legitimacy_delta":"legitimacy"}
	for channel_variant in planned:
		var channel:=String(channel_variant)
		if channel=="population_deaths":
			var requested_deaths:=maxi(0,int(planned[channel]))
			var parameters:Dictionary=assessment.get("directive_parameters",{})
			var target:Dictionary=parameters.get("demographic_target",{})
			target=target.duplicate(true)
			target["source_order_id"]=String(assessment.get("source_order_id",""))
			var description:="The order executed %s once." % String(target.get("label","the specified count")) if bool(parameters.get("one_time",false)) else String(assessment.get("second_order_consequence","Deaths resulted from directive enforcement."))
			var death_result:=GameState.register_directive_population_deaths(requested_deaths,effect_id,description,target)
			applied[channel]=int(death_result.get("count",0))
			# Some targeted people flee or hide when enforcement is visible. Departures
			# are living population loss, not falsely recorded casualties.
			if requested_deaths>0 and not bool(parameters.get("one_time",false)) and float(assessment.get("resistance",0.0))>0.30:
				var departures:=floori(float(requested_deaths)*float(assessment.get("resistance",0.0))*0.45)
				var departure_result:=GameState.register_population_departures(departures,"Flight from directive: %s" % effect_id.replace("_"," "))
				applied["population_departures"]=int(departure_result.get("count",0))
			continue
		if not metric_map.has(channel): continue
		var metric:=String(metric_map[channel])
		var before:=float(GameState.simulation_metrics.get(metric,GameState.population_health if metric=="health" else 0.5))
		var after:=clampf(before+float(planned[channel]),0.01,0.99)
		GameState.simulation_metrics[metric]=after
		if metric=="health": GameState.population_health=after
		applied[channel]=after-before
	return applied

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
			_add_event("Directive Overtaken","A newer %s directive was already in force when this interpretation arrived; the older submission changed no variables." % effect_id.replace("_"," "),"institutions","notice")
			return false
	# A standing policy supersedes its previous version instead of becoming an
	# exploitable stack of repeated identical pronouncements.
	var superseded:=false
	var prior_magnitude:=0.0
	for modifier in GameState.active_modifiers:
		if bool(metadata.get("directive_parameters",{}).get("one_time",false)): break
		if String(modifier.get("id",""))==effect_id and String(modifier.get("kind",""))=="policy" and GameState.elapsed_days<=float(modifier.get("until_day",-INF)):
			superseded=true
			prior_magnitude=float(modifier.get("magnitude",0.0))
			_refresh_policy_observation_record(modifier)
			modifier["until_day"]=GameState.elapsed_days-0.001
			modifier["ended_day"]=GameState.elapsed_days
			modifier["ended_reason"]="superseded"
			modifier["superseded_by_order_id"]=String(metadata.get("source_order_id",""))
	if superseded: _record_policy_churn(clampf(0.025+absf(prior_magnitude-clampf(magnitude,-0.35,0.35))*0.12,0.025,0.07),"A standing %s directive was replaced before its term ended." % effect_id.replace("_"," "))
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
	_add_event("Directive Issued",source,"policy","notice")
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
	if repealed and longest_remaining>7.0: _record_policy_churn(clampf(0.025+longest_remaining/3650.0*0.025,0.025,0.06),"A standing %s directive was rescinded before its term ended." % effect_id.replace("_"," "))
	_add_event("Directive Rescinded",source if repealed else "No active %s directive remained to rescind." % effect_id.replace("_"," "),"policy","notice")
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
			if String(modifier.get("kind",""))=="policy" and not bool(modifier.get("deadline_resolved",true)):
				_resolve_deadline_enforcement(modifier)
			if String(modifier.get("kind",""))=="policy": _refresh_policy_observation_record(modifier)
			modifier["ended_reason"]="expired"
			modifier["ended_day"]=float(modifier.get("until_day",GameState.elapsed_days))

func _resolve_deadline_enforcement(policy:Dictionary)->void:
	policy["deadline_resolved"]=true
	if String(policy.get("deadline_enforcement",""))!="pregnancy_threat": return
	var target_households:=maxi(0,int(policy.get("deadline_target_households",0)))
	var new_conceptions:=maxi(0,GameState.lifetime_conceptions-int(policy.get("deadline_baseline_conceptions",GameState.lifetime_conceptions)))
	var noncompliant:=maxi(0,target_households-mini(target_households,new_conceptions))
	var parameters:Dictionary=policy.get("directive_parameters",{})
	var target:Dictionary=parameters.get("demographic_target",{})
	var security_capacity:=clampf(float(GameState.simulation_metrics.get("security",0.0)),0.0,1.0)
	var executable:=mini(noncompliant,_remaining_directive_death_capacity(maxf(1.0,GameState.population_exact),security_capacity))
	var enforced:=floori(float(executable)*clampf(float(policy.get("implementation_rate",0.0)),0.0,1.0))
	var death_result:=GameState.register_directive_population_deaths(enforced,String(policy.get("id","coercive_pronatalism")),"Parents in households that did not meet the pregnancy threat were killed when its deadline arrived.",target)
	var killed:=int(death_result.get("count",0))
	var flight_result:=GameState.register_population_departures(floori(float(noncompliant)*clampf(float(policy.get("resistance",0.0)),0.0,1.0)*0.24),"Flight from pregnancy enforcement")
	var fled:=int(flight_result.get("count",0))
	var legitimacy:=float(GameState.simulation_metrics.get("legitimacy",0.5))
	var cohesion:=float(GameState.simulation_metrics.get("cohesion",0.5))
	GameState.simulation_metrics["legitimacy"]=clampf(legitimacy-0.01-minf(0.08,float(killed+fled)/maxf(1.0,GameState.population_exact)*0.22),0.01,0.99)
	GameState.simulation_metrics["cohesion"]=clampf(cohesion-0.008-minf(0.06,float(killed+fled)/maxf(1.0,GameState.population_exact)*0.18),0.01,0.99)
	policy["deadline_result"]={"target_households":target_households,"new_conceptions":new_conceptions,"noncompliant_households":noncompliant,"deaths":killed,"departures":fled}
	var description:="The pregnancy deadline passed."
	if killed>0 or fled>0: description+=" Enforcement killed %d people; %d fled or disappeared from the census." % [killed,fled]
	elif noncompliant>0: description+=" The threatened punishment exceeded the settlement's actual enforcement reach, and no deaths were carried out."
	else: description+=" Recorded conceptions met the threatened quota; no deadline killing was attempted."
	_add_event("Pregnancy Threat Deadline",description,"population","danger" if killed>0 else "warning")

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
		if metric.is_empty(): continue
		var value:Variant
		if metric.begins_with("stockpile:"):
			value=GameState.resource_stockpiles.get(metric.trim_prefix("stockpile:"),0.0)
		elif GameState.simulation_metrics.has(metric):
			value=GameState.simulation_metrics[metric]
		else:
			continue
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
	var resistance_pressure:=0.0
	var compliance_weighted:=0.0
	var directive_weight:=0.0
	var offices:Dictionary={}
	for policy in active:
		var execution:=maxf(0.35,float(policy.get("execution_factor",0.62)))
		var weight:=absf(float(policy.get("magnitude",0.0)))
		var resistance:=clampf(float(policy.get("resistance",0.0)),0.0,1.0)
		administrative_load+=weight*(0.10+maxf(0.0,1.0-execution)*0.08+resistance*0.08)
		resistance_pressure+=weight*resistance
		compliance_weighted+=weight*clampf(float(policy.get("compliance",1.0)),0.0,1.0)
		directive_weight+=weight
		offices[String(policy.get("office","Council"))]=int(offices.get(String(policy.get("office","Council")),0))+1
	var churn:=maxf(0.0,modifier_strength("policy_churn"))
	administrative_load=clampf(administrative_load+churn*0.25,0.0,0.30)
	return {"active_policy_count":active.size(),"administrative_load":administrative_load,"policy_churn":churn,"directive_resistance_pressure":clampf(resistance_pressure,0.0,0.35),"directive_compliance":compliance_weighted/directive_weight if directive_weight>0.0001 else 1.0,"council_support":_council_support(),"office_policy_counts":offices}

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
	var directive_resistance:=float(governance.get("directive_resistance_pressure",0.0))
	var council_support:=float(governance.council_support)
	var foreign_effects:Dictionary=CivilizationSystem.player_effects()

	var prior_health := float(previous.get("health",GameState.population_health))
	var prior_cohesion := float(previous.get("cohesion",0.58))
	var permanent_housing_ratio := clampf(float(GameState.housing_capacity)/population,0.15,1.12)
	var mobile_shelter_ratio:=clampf(0.20+carriers/maxf(1.0,population*0.10)*0.27+builders/maxf(1.0,population*0.12)*0.17,0.18,0.72)
	mobile_shelter_ratio+=DiscoverySystem.effect("mobile_shelter")
	mobile_shelter_ratio=clampf(mobile_shelter_ratio,0.18,0.86)
	var housing_ratio := mobile_shelter_ratio if traveling else permanent_housing_ratio
	var labor_efficiency := clampf(0.34+prior_health*0.34+prior_cohesion*0.18+housing_ratio*0.12,0.25,1.08)
	labor_efficiency*=lerpf(0.82,1.08,clampf(float(dynamics.get("labor",0.5)),0.0,1.0))
	labor_efficiency*=(1.0+policy_effect("labor_multiplier")+GameState.founding_effect("labor_multiplier")+ProgressionSystem.effect("labor_efficiency"))*(1.0-administrative_load)
	# Scouts, envoys, and moving settlement populations are real aggregate
	# commitments absent from ordinary work until they arrive or return. One
	# bounded ratio changes output without traveler or person records.
	labor_efficiency*=1.0-clampf(float(foreign_effects.get("labor_absence",foreign_effects.get("scout_labor_absence",0.0)))*0.72,0.0,0.44)
	labor_efficiency=clampf(labor_efficiency,0.20,1.12)

	var ecology := float(previous.get("ecology",0.88))
	var food_result:Dictionary=_food_system().process_day({"traveling":traveling},labor_efficiency,ecology)
	var environment:Dictionary=_food_system().current_environment_profile()
	var environmental_hazards:Dictionary=environment.get("hazards",{})
	var disease_pressure:=clampf(float(environmental_hazards.get("disease",0.0)),0.0,1.0)
	var cold_pressure:=clampf(float(environmental_hazards.get("cold",0.0)),0.0,1.0)
	var heat_pressure:=clampf(float(environmental_hazards.get("heat",0.0)),0.0,1.0)
	var storm_pressure:=clampf(float(environmental_hazards.get("storm",0.0)),0.0,1.0)
	var environmental_resilience:=clampf(float(environment.get("ecological_resilience",0.5)),0.0,1.0)
	var industrial_activity:=clampf(float(GameState.material_metrics.get("extracted_today",0.0))/maxf(1.0,population*0.08),0.0,2.0)
	var food_production:=float(food_result.food_production)
	var food_consumption:=float(food_result.food_consumption)
	var food_stored:=float(GameState.resource_stockpiles.get("Food",0.0))
	var food_days:=float(food_result.food_days)
	var production_ratio:=float(food_result.food_balance)+1.0
	var intake_ratio:=float(food_result.food_intake_ratio)
	var malnutrition:=float(food_result.malnutrition_burden)
	var water_intake:=clampf(float(GameState.water_metrics.get("intake_ratio",0.0)),0.0,1.0)
	if intake_ratio<0.95:
		GameState.consecutive_food_shortage_days+=1.0
	else:
		GameState.consecutive_food_shortage_days=maxf(0.0,GameState.consecutive_food_shortage_days-2.0)
	if water_intake<0.98:
		GameState.consecutive_water_shortage_days+=1.0
	else:
		GameState.consecutive_water_shortage_days=maxf(0.0,GameState.consecutive_water_shortage_days-2.0)
	if traveling and housing_ratio<0.68:
		GameState.convoy_exposure_days+=1.0-housing_ratio
	else:
		GameState.convoy_exposure_days=maxf(0.0,GameState.convoy_exposure_days-1.5)
	var food_security_target := clampf(0.05+minf(1.0,food_days/45.0)*0.30+minf(1.15,production_ratio)*0.25+intake_ratio*0.18+float(food_result.food_diet_quality)*0.12+GameState.nutrition_reserve*0.10-malnutrition*0.24,0.02,0.98)
	GameState.food_security = lerpf(GameState.food_security,food_security_target,0.055)

	var clean_water_bonus := DiscoverySystem.effect("health_protection")+DiscoverySystem.effect("water_safety")*0.25-DiscoverySystem.effect("disease_exposure")*0.18
	var water_health_penalty:=pow(1.0-water_intake,1.35)*0.62
	var shelter_bonus := 0.0
	if "Hearth Circle" in GameState.settlement_completed: shelter_bonus += 0.05
	if "Lean-to Shelters" in GameState.settlement_completed: shelter_bonus += 0.12
	var travel_health_penalty:=0.0
	if traveling:
		travel_health_penalty=0.08+maxf(0.0,0.62-housing_ratio)*0.30+minf(0.24,GameState.consecutive_food_shortage_days*0.009)
	var process_health_cost:=(DiscoverySystem.effect("health_risk")+DiscoverySystem.effect("pollution")*0.22+DiscoverySystem.effect("water_pollution")*0.18)*industrial_activity
	var environmental_health_cost:=disease_pressure*maxf(0.18,1.0-DiscoverySystem.effect("sanitation"))*0.045+(cold_pressure*0.024+heat_pressure*0.018)*maxf(0.0,0.92-housing_ratio)
	var health_target := clampf(0.18+GameState.food_security*0.43+float(food_result.food_diet_quality)*0.06+housing_ratio*0.16+clean_water_bonus+shelter_bonus-modifier_strength("sickly_arrival")+policy_effect("health_target")+GameState.founding_effect("health_target")+ProgressionSystem.effect("health_protection")*0.12-ProgressionSystem.effect("disease_exposure")*0.08-travel_health_penalty-malnutrition*0.28-process_health_cost-water_health_penalty-environmental_health_cost,0.02,0.97)
	GameState.population_health = lerpf(GameState.population_health,health_target,0.022)
	GameState.simulation_metrics["water_intake_ratio"]=water_intake
	GameState.simulation_metrics["water_days"]=float(GameState.water_metrics.get("days",0.0))
	GameState.simulation_metrics["environment_profile"]=environment.duplicate(true)
	GameState.simulation_metrics["environmental_health_cost"]=environmental_health_cost

	var admin_coverage := clampf(stewards/maxf(1.0,population*0.035),0.0,1.25)
	var work_strain := clampf((food_workers+extractors+builders)/able_population,0.0,1.0)
	var economic_social_pressure:=float(GameState.economy_metrics.get("social_pressure",0.0))
	var cohesion_target := clampf(0.24+GameState.food_security*0.26+housing_ratio*0.15+admin_coverage*0.20+DiscoverySystem.effect("state_capacity")*0.08+DiscoverySystem.effect("cohesion")*0.10+ProgressionSystem.effect("cohesion")*0.10+ProgressionSystem.effect("legitimacy")*0.06+(1.0-work_strain)*0.08-modifier_strength("divided_camp")+policy_effect("cohesion_target")+GameState.founding_effect("cohesion_target")-administrative_load*0.10-policy_churn*0.16-directive_resistance*0.18+economic_social_pressure*0.55+float(foreign_effects.treaty_count)*0.006-float(foreign_effects.war_count)*0.018-float(foreign_effects.get("war_exhaustion",0.0))*0.12-float(foreign_effects.get("occupation_burden",0.0))*0.16+SOCIETAL_VALUES_MODEL.simulation_effect(GameState.societal_values,"cohesion"),0.08,0.96)
	var cohesion := lerpf(prior_cohesion,cohesion_target,0.014)

	var inquiry_points := 0
	for value in GameState.research_allocations.values(): inquiry_points += int(value)
	var focus_quality := 1.0 if inquiry_points <= maxi(1,int(observers)) else clampf(observers/maxf(1.0,float(inquiry_points)),0.15,1.0)
	var knowledge := float(previous.get("knowledge",0.18))
	var knowledge_gain := observers*labor_efficiency*focus_quality/maxf(3000.0,population*92.0)*(1.0+DiscoverySystem.effect("knowledge_rate"))*lerpf(0.55,1.45,GameState.combined_intelligence)
	knowledge += knowledge_gain*(1.0+modifier_strength("curious_youth")+policy_effect("knowledge_gain")+GameState.founding_effect("knowledge_gain")+ProgressionSystem.effect("knowledge_rate")+SOCIETAL_VALUES_MODEL.simulation_effect(GameState.societal_values,"knowledge"))
	knowledge += float(foreign_effects.knowledge_exchange)/365.0
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
	var material_target := clampf(0.05+craft_coverage*0.38+minf(1.0,float(accessible_count)/4.0)*0.25+knowledge*0.18+workshop_function*0.12+DiscoverySystem.effect("tool_quality")*0.30+DiscoverySystem.effect("craft_output")*0.22+ProgressionSystem.effect("tool_quality")*0.22+ProgressionSystem.effect("craft_output")*0.18+modifier_strength("skilled_craftspeople")+policy_effect("material_target")+GameState.founding_effect("material_target"),0.02,0.96)
	if "Open Work Area" in GameState.settlement_completed: material_target += 0.08
	var material_capacity := lerpf(float(previous.get("material_capacity",0.12)),material_target,0.012)
	var logistics_target := clampf(0.05+carriers/maxf(1.0,population*0.08)*0.55+material_capacity*0.18+storage_function*0.10+DiscoverySystem.effect("haul_capacity")*0.18+DiscoverySystem.effect("route_speed")*0.12+ProgressionSystem.effect("haul_capacity")*0.14+ProgressionSystem.effect("route_speed")*0.10+policy_effect("logistics_target")+GameState.founding_effect("logistics_target")+float(foreign_effects.market_access_bonus)*0.24,0.03,0.95)
	var logistics := lerpf(float(previous.get("logistics",0.16)),logistics_target,0.016)
	var security_target := clampf(0.10+guards/maxf(1.0,population*0.05)*0.42+cohesion*0.24+logistics*0.12+DiscoverySystem.effect("warfare_readiness")*0.14+ProgressionSystem.effect("warfare_readiness")*0.12+ProgressionSystem.effect("security_efficiency")*0.10-modifier_strength("migratory_pressure")+policy_effect("security_target")+GameState.founding_effect("security_target")+float(foreign_effects.security_support)-float(foreign_effects.hostile_pressure)*0.18+SOCIETAL_VALUES_MODEL.simulation_effect(GameState.societal_values,"security"),0.04,0.96)
	var security := lerpf(float(previous.get("security",0.38)),security_target,0.016)

	var extraction_pressure := extractors/able_population
	var foraging_pressure := maxf(0.0,food_workers/able_population-0.48)
	var ecology_delta := 0.00010+(environmental_resilience-ecology)*0.00018+modifier_strength("sacred_land")*0.00032+policy_effect("ecology_delta")+GameState.founding_effect("ecology_delta")+ProgressionSystem.effect("ecology_recovery")*0.00040-ProgressionSystem.effect("ecological_pressure")*0.00024-ProgressionSystem.effect("pollution")*0.00018+SOCIETAL_VALUES_MODEL.simulation_effect(GameState.societal_values,"ecology")*0.00040
	ecology_delta -= extraction_pressure*0.00052+foraging_pressure*0.00105
	ecology_delta-=(DiscoverySystem.effect("pollution")+DiscoverySystem.effect("water_pollution"))*industrial_activity*0.0009
	ecology = clampf(ecology+ecology_delta,0.04,1.0)
	var legitimacy_target := clampf(0.12+GameState.food_security*0.26+GameState.population_health*0.18+cohesion*0.20+security*0.10+admin_coverage*0.10+DiscoverySystem.effect("legitimacy")*0.12+float(dynamics.get("institutions",0.25))*0.05+(council_support-0.5)*0.06+policy_effect("legitimacy_target")-administrative_load*0.12-policy_churn*0.18-directive_resistance*0.24+economic_social_pressure+float(foreign_effects.treaty_count)*0.008-float(foreign_effects.war_count)*0.018-float(foreign_effects.get("war_exhaustion",0.0))*0.10-float(foreign_effects.get("occupation_burden",0.0))*0.22+SOCIETAL_VALUES_MODEL.simulation_effect(GameState.societal_values,"legitimacy"),0.06,0.96)
	var legitimacy := lerpf(float(previous.get("legitimacy",0.62)),legitimacy_target,0.012)

	# Mortality is accumulated as population-level risk, while reproduction is
	# resolved by numeric reproductive cohorts: conception, gestation, loss,
	# delivery, parentage, postpartum recovery, and maternal/neonatal outcomes.
	var birth_crisis:=intake_ratio<0.82 or malnutrition>0.38
	var mortality_components := {
		# Natural mortality is derived from the same age-specific life table shown
		# to the player. An older population therefore produces more deaths than a
		# younger one under otherwise identical conditions.
		"Natural causes":GameState.current_natural_mortality_rate(housing_ratio),
		"Hunger":0.0,
		"Illness":maxf(0.0,0.50-GameState.population_health)*0.055*maxf(0.35,1.0+DiscoverySystem.effect("disease_exposure")-DiscoverySystem.effect("sanitation"))+disease_pressure*maxf(0.10,1.0-DiscoverySystem.effect("sanitation"))*0.005,
		"Exposure":maxf(0.0,0.68-housing_ratio)*(0.24 if traveling else 0.040)+(cold_pressure*0.018+heat_pressure*0.012+storm_pressure*0.006)*maxf(0.0,0.92-housing_ratio),
		"Travel exhaustion":0.0,
		"Insecurity":maxf(0.0,0.30-security)*0.025
	}
	mortality_components["Dehydration"]=_dehydration_mortality_rate(water_intake,GameState.consecutive_water_shortage_days)
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
	var mortality_result:Dictionary={}
	if deaths_today>0:
		mortality_result=GameState.register_population_deaths(deaths_today,dominant_cause)
	var reproduction:=GameState.process_reproduction_day({
		"health":GameState.population_health,"food_security":GameState.food_security,
		"housing_ratio":housing_ratio,"cohesion":cohesion,"traveling":traveling,
		"birth_crisis":birth_crisis,"absent_adults":float(foreign_effects.get("population_absent",0)),
		"conception_support":DiscoverySystem.effect("conception_support")+policy_effect("conception_support")+GameState.founding_effect("conception_support")+ProgressionSystem.effect("conception_support"),
		"maternal_safety":DiscoverySystem.effect("maternal_safety"),"neonatal_survival":DiscoverySystem.effect("neonatal_survival")
	})
	var births_today:=int(reproduction.get("births_count",0))
	var events: Array[Dictionary] = []
	if births_today>0:
		var birth_cause:="Birth during migration" if traveling else "Births"
		events.append(_record_demographic_change("birth",births_today,birth_cause,food_days,production_ratio,housing_ratio,{"children":births_today}))
	if deaths_today>0:
		events.append(_record_demographic_change("death",deaths_today,dominant_cause,food_days,production_ratio,housing_ratio,mortality_result.get("affected_cohorts",{})))
	var maternal_deaths:=int(reproduction.get("maternal_deaths_count",0))
	if maternal_deaths>0:
		events.append(_record_demographic_change("death",maternal_deaths,"Complications of childbirth",food_days,production_ratio,housing_ratio,{"reproductive_age":maternal_deaths}))
	var neonatal_deaths:=int(reproduction.get("neonatal_deaths_count",0))
	if neonatal_deaths>0:
		events.append(_record_demographic_change("death",neonatal_deaths,"Neonatal complications",food_days,production_ratio,housing_ratio,{"children":neonatal_deaths}))
	var pregnancy_losses:=int(reproduction.get("pregnancy_losses_count",0))
	if pregnancy_losses>0:
		events.append(_add_event("Pregnancy Losses","%d pregnancies ended before delivery under current health, nutrition, shelter, and care conditions." % pregnancy_losses,"population","warning"))
	var stillbirths:=int(reproduction.get("stillbirths_count",0))
	if stillbirths>0:
		events.append(_add_event("Stillbirths","%d births were lost at delivery under current maternal and neonatal conditions." % stillbirths,"population","warning"))
	var annual_birth_rate:=float(reproduction.get("projected_birth_rate",0.0))

	var settlement_score := clampf(float(GameState.settlement_completed.size())/8.0,0.0,1.0)
	GameState.simulation_metrics = {
		"health":GameState.population_health,"housing_ratio":housing_ratio,"housing_capacity":GameState.housing_capacity,"labor_efficiency":labor_efficiency,"cohesion":cohesion,"knowledge":knowledge,
		"material_capacity":material_capacity,"logistics":logistics,"security":security,"ecology":ecology,"legitimacy":legitimacy,
		"governance_administrative_load":administrative_load,"governance_policy_churn":policy_churn,"governance_council_support":council_support,"governance_active_policies":int(governance.active_policy_count),
		"resource_access":float(accessible_count),"settlement":settlement_score,"population":GameState.population_exact,
		"annual_birth_rate":annual_birth_rate,"annual_death_rate":annual_death_rate,"traveling":traveling,
		"mortality_components":mortality_components.duplicate(true),
		"active_pregnancies":int(reproduction.get("active_pregnancies",0)),"eligible_parents":int(reproduction.get("eligible_parents",0)),
		"annual_conceptions_expected":float(reproduction.get("annual_conceptions_expected",0.0)),"projected_live_births":float(reproduction.get("projected_live_births",0.0)),
		"births_expected_next_year":float(reproduction.get("births_expected_next_year",0.0)),
		"mobile_shelter_ratio":mobile_shelter_ratio,"food_shortage_days":GameState.consecutive_food_shortage_days,
		"water_intake_ratio":water_intake,"water_days":float(GameState.water_metrics.get("days",0.0)),"water_shortage_days":GameState.consecutive_water_shortage_days,
		"water_collected_today":float(GameState.water_metrics.get("collected_today",0.0)),"water_required_today":float(GameState.water_metrics.get("required_today",population)),"water_source_distance_km":float(GameState.water_metrics.get("source_distance_km",-1.0)),
		"travel_speed_factor":_travel_speed_factor(GameState.population_health,GameState.food_security,production_ratio,food_stored,traveling),
		"survey_capacity":surveyors*labor_efficiency*(1.0+GameState.founding_effect("survey_output")+ProgressionSystem.effect("knowledge_rate")*0.35),"construction_capacity":builders*labor_efficiency*(1.0+workshop_function*0.10)*(1.0+GameState.founding_effect("construction_output")+ProgressionSystem.effect("construction_rate")),"combined_intelligence":GameState.combined_intelligence,
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
	GameState.record_health_history()

	var forecast_90:Dictionary=food_result.get("food_forecast_90",{})
	var forecast_shortage:=int(forecast_90.get("first_shortage_day",-1))
	if forecast_shortage>0: _threshold_event(events,"projected_food_shortage","Shortage Forecast","At the present allocation and seasonal outlook, the stores fail in about %d days. The projection includes expected harvest and spoilage." % forecast_shortage,"food","danger",20)
	elif food_days < 14.0 and float(food_result.food_net)<0.0: _threshold_event(events,"low_food","Stores Are Falling","Only %.1f days remain and today's provision balance is %+.1f rations." % [food_days,float(food_result.food_net)],"food","warning",30)
	if food_days < 3.0 and (float(food_result.food_net)<0.0 or intake_ratio<0.98):
		var famine_title:="Hunger on the Road" if traveling else "Hunger in the Camp"
		var famine_description:="The convoy has nearly exhausted its provisions. Travel, health, and population are now at immediate risk." if traveling else "Food stores are nearly gone. Health and population will now deteriorate rapidly."
		_threshold_event(events,"famine",famine_title,famine_description,"health","critical",12)
	if traveling and food_stored<=0.001 and intake_ratio<0.98: _threshold_event(events,"convoy_without_provisions","The Convoy Is Living Hand to Mouth","No provisions remain. Route foraging supplies only %d%% of today's need; body reserves are at %d%%." % [roundi(intake_ratio*100.0),roundi(GameState.nutrition_reserve*100.0)],"food","critical",7)
	if water_intake<0.95:
		var source_distance:=float(GameState.water_metrics.get("source_distance_km",-1.0))
		var water_place:="No reachable drinking-water source is recorded." if source_distance<0.0 else "The nearest usable source is %.1f km away." % source_distance
		var water_severity:="critical" if water_intake<0.65 or (water_intake<0.82 and GameState.consecutive_water_shortage_days>=2.0) else "warning"
		var water_remedy:="River access remains intact; increase collection or distribution capacity." if String(GameState.water_metrics.get("source_origin",""))=="mapped_hydrology" and source_distance<=1.5 else "Increase Food or Logistics work, or move closer to visible water."
		_threshold_event(events,"water_shortfall","Drinking Water Is Short","Collection supplied only %d%% of today's need. %s %s" % [roundi(water_intake*100.0),water_place,water_remedy],"health",water_severity,2)
	if GameState.population_health < 0.46: _threshold_event(events,"ill_health","Widespread Illness","Poor nutrition, exposure, and water conditions are reducing effective labor.","health","danger",45)
	if ecology < 0.55: _threshold_event(events,"ecology_strain","The Land Is Thinning","Gatherers report longer journeys and diminishing returns near the settlement.","ecology","warning",120)
	if legitimacy < 0.42: _threshold_event(events,"authority_strain","Directives Meet Resistance","Hardship and weak administration are eroding compliance with sovereign priorities.","legitimacy","warning",60)
	return events


func _dehydration_mortality_rate(water_intake:float,shortage_days:float)->float:
	## A small collection miss is a warning and lost resilience, not mass death.
	## Lethality rises non-linearly as the actual drinking deficit becomes severe;
	## a complete sustained loss of water remains rapidly catastrophic.
	var deficit:=clampf(1.0-water_intake,0.0,1.0)
	var shortage_ramp:=clampf((shortage_days-1.0)/4.0,0.0,1.0)
	return pow(deficit,3.0)*(0.35+shortage_ramp*5.0)

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

func _record_demographic_change(kind: String,count: int,cause: String,food_days: float,production_ratio: float,housing_ratio: float,affected_cohorts:Dictionary={}) -> Dictionary:
	var location:=_population_location()
	var day:=int(GameState.elapsed_days)
	var water_intake:=clampf(float(GameState.water_metrics.get("intake_ratio",0.0)),0.0,1.0)
	var water_distance:=float(GameState.water_metrics.get("source_distance_km",-1.0))
	var cause_detail:=""
	match cause:
		"Hunger": cause_detail="Food stores were exhausted and daily production met only %d%% of need." % roundi(production_ratio*100.0)
		"Dehydration": cause_detail="Drinking-water collection met only %d%% of need%s." % [roundi(water_intake*100.0)," from a source %.1f km away" % water_distance if water_distance>=0.0 else "; no reachable source was recorded"]
		"Illness": cause_detail="Poor health was the strongest mortality pressure."
		"Exposure": cause_detail="Shelter covered only %d%% of the population." % roundi(housing_ratio*100.0)
		"Travel exhaustion": cause_detail="Sustained travel, inadequate shelter, and declining strength made the journey fatal."
		"Insecurity": cause_detail="Low security was the strongest exceptional mortality pressure."
		"Births": cause_detail="Food security, health, shelter, and social stability supported new births."
		"Birth during migration": cause_detail="A child was born during a provisioned stage of the migration."
		"Complications of childbirth": cause_detail="The parent died during or immediately after delivery."
		"Neonatal complications": cause_detail="The newborn died during the immediate period after birth."
		_: cause_detail="No exceptional crisis outweighed ordinary mortality."
	var cohort_detail:=" Affected cohorts: %s." % ", ".join(PackedStringArray(affected_cohorts.keys())) if not affected_cohorts.is_empty() else ""
	var description:="%s %s Health: %d%%. Stored provisions: %.1f days. Food today: %d%%. Drinking water today: %d%%. Shelter: %d%%.%s" % [cause_detail,"Location: %s." % location,roundi(GameState.population_health*100.0),food_days,roundi(production_ratio*100.0),roundi(water_intake*100.0),roundi(housing_ratio*100.0),cohort_detail]
	var noun:="birth" if kind=="birth" else "death"
	var title:="%d %s%s at %s" % [count,noun,"" if count==1 else "s",location]
	var record:={
		"id":"demographic_%s_%d_%d" % [kind,day,GameState.demographic_ledger.size()],
		"day":day,"start_day":day,"end_day":day,"title":title,"description":description,
		"domain":"population","severity":"demographic","kind":kind,"count":count,
		"cause":cause,"location":location,"food_days":food_days,"production_ratio":production_ratio,"water_intake_ratio":water_intake,"water_source_distance_km":water_distance,
		"health":GameState.population_health,"housing_ratio":housing_ratio,"population_after":GameState.population_total,"affected_cohorts":affected_cohorts.duplicate(true),
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
			recent["water_intake_ratio"]=water_intake
			recent["water_source_distance_km"]=water_distance
			recent["health"]=GameState.population_health
			recent["housing_ratio"]=housing_ratio
			recent["population_after"]=GameState.population_total
			var recent_cohorts:Dictionary=recent.get("affected_cohorts",{})
			for cohort in affected_cohorts:
				recent_cohorts[cohort]=float(recent_cohorts.get(cohort,0.0))+float(affected_cohorts[cohort])
			recent["affected_cohorts"]=recent_cohorts
			var total:=int(recent.count)
			recent["title"]="%d %s%s at %s" % [total,noun,"" if total==1 else "s",location]
			recent["description"]=description
			GameState.demographic_ledger[0]=recent
			for i in GameState.simulation_events.size():
				if String(GameState.simulation_events[i].get("id",""))==String(recent.id):
					GameState.simulation_events[i]=recent
					break
			return recent
	GameState.demographic_ledger.push_front(record)
	if GameState.demographic_ledger.size()>120: GameState.demographic_ledger.resize(120)
	GameState.simulation_events.push_front(record)
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
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


func _threshold_event(events: Array[Dictionary],id: String,title: String,description: String,domain: String,severity: String,cooldown: int) -> void:
	var last_day := int(GameState.last_simulation_event_days.get(id,-100000))
	if int(GameState.elapsed_days)-last_day<cooldown: return
	GameState.last_simulation_event_days[id]=int(GameState.elapsed_days)
	var event := _add_event(title,description,domain,severity)
	event["condition_id"]=id
	event["recurring_condition"]=true
	events.append(event)

func _add_event(title: String,description: String,domain: String,severity: String) -> Dictionary:
	var event := {"day":int(GameState.elapsed_days),"title":title,"description":description,"domain":domain,"severity":severity}
	GameState.simulation_events.push_front(event)
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
	return event
