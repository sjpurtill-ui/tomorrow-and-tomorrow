extends GdUnitTestSuite


func before_test()->void:
	_reset_directive_world(441177,10_000,true)


func test_one_example_is_one_worker_with_a_conserved_population_and_receipt()->void:
	_reset_directive_world(441178,120,true)
	var text:="Just execute one example to scare the workers."
	var reading:=PronouncementInterpreter._local_interpretation(text)
	assert_int(reading.policies.size()).is_equal(1)
	if reading.policies.is_empty(): return
	var target:Dictionary=reading.policies[0].directive_parameters.demographic_target
	assert_int(int(target.get("exact_count",0))).is_equal(1)
	assert_str(String(target.get("role",""))).is_equal("worker")
	assert_bool(target.has("sex")).is_false()
	var population:=GameState.population_exact
	var workers:=float(GameState.population_cohorts.working_age)
	var children:=float(GameState.population_cohorts.children)
	var deaths:=GameState.lifetime_deaths
	var order:=AdvisorSystem.execute_pronouncement(text,reading)
	var policy:Dictionary=order.parameters.interpretation.policies[0]
	assert_bool(bool(policy.applied)).is_true()
	assert_int(int(policy.direct_effects.get("population_deaths",0))).is_equal(1)
	assert_float(GameState.population_exact).is_equal_approx(population-1.0,0.00001)
	assert_float(float(GameState.population_cohorts.working_age)).is_equal_approx(workers-1.0,0.00001)
	assert_float(float(GameState.population_cohorts.children)).is_equal_approx(children,0.00001)
	assert_int(GameState.lifetime_deaths).is_equal(deaths+1)
	assert_int(int(GameState.demographic_ledger[0].count)).is_equal(1)
	assert_str(String(GameState.demographic_ledger[0].source_order_id)).is_equal(String(order.id))
	assert_int(ConsequenceEngine.active_policies().size()).is_equal(0)
	var again:=ConsequenceEngine.apply_directive("mass_repression",0.1,30,"repeat",{"source_order_id":order.id,"directive_parameters":policy.directive_parameters})
	assert_bool(bool(again.applied)).is_false()
	assert_int(GameState.lifetime_deaths).is_equal(deaths+1)
	var report:=CivicImplementationSystem._evaluate_policy(String(order.id),{"id":"mass_repression","directive_parameters":policy.directive_parameters,"direct_effects":policy.direct_effects},30,0)
	assert_str(String(report.outcome)).is_equal("success")
	assert_str(String(report.qualitative_evidence)).contains("1 person")
	var ledger_ui:RefCounted=load("res://scripts/hud/content/dock_detail_population_ledger.gd").new(null,null)
	var ledger_view:Dictionary=ledger_ui.tab(0)
	assert_str(JSON.stringify(ledger_view)).contains("1 executed by decree")
	var council_ui:RefCounted=load("res://scripts/hud/content/dock_content_civilization.gd").new(null,null)
	assert_str(council_ui._directive_state({"status":"active","implementation_followup":{"state":"reported"}})).is_equal("REPORTED")


func test_target_words_and_confirmation_cannot_expand_one_worker_to_men()->void:
	var policy:Dictionary=PronouncementInterpreter._local_interpretation("Execute one worker as an example.").policies[0]
	var target:Dictionary=policy.directive_parameters.demographic_target.duplicate(true)
	AdvisorSystem._merge_grave_followup_parameters(policy,"I COMMAND YOU!")
	assert_dict(policy.directive_parameters.demographic_target).is_equal(target)
	var parsed:=PronouncementInterpreter._deterministic_directive_parameters("Execute one worker; mandatory attendance for all men to scare them.","mass_repression")
	assert_int(int(parsed.demographic_target.exact_count)).is_equal(1)
	assert_bool(parsed.demographic_target.has("sex")).is_false()
	var mandatory:=PronouncementInterpreter._deterministic_directive_parameters("Execute one worker as mandatory punishment.","mass_repression")
	assert_bool(mandatory.demographic_target.has("sex")).is_false()


func test_unavailable_exact_count_has_no_partial_deaths_or_metric_changes()->void:
	var before:=GameState.population_exact
	var metrics:=GameState.simulation_metrics.duplicate(true)
	var result:=ConsequenceEngine.apply_directive("mass_repression",0.1,30,"test",{"directive_parameters":{"one_time":true,"demographic_target":{"exact_count":10001,"scope":"counted"}}})
	assert_bool(bool(result.applied)).is_false()
	assert_float(GameState.population_exact).is_equal(before)
	assert_dict(GameState.simulation_metrics).is_equal(metrics)
	assert_array(GameState.demographic_ledger).is_empty()


func test_terra_numerical_plan_controls_only_validated_statistical_channels()->void:
	var text:="Execute one worker as an example."
	var raw:={"policies":[{"id":"mass_repression","basis":"Execute one worker","confidence":0.99,"statistical_effects":[
		{"metric":"cohesion","delta":-0.02,"uncertainty":0.01,"reason":"Fear can reduce mutual trust."},
		{"metric":"population","delta":-0.08,"uncertainty":0.01,"reason":"Must not be writable."},
		{"metric":"security","delta":100,"uncertainty":0.01,"reason":"Out of bounds."}
	]}]}
	var reading:=PronouncementInterpreter._validate(raw,text)
	var parameters:Dictionary=reading.policies[0].directive_parameters
	assert_int(parameters.statistical_effects.size()).is_equal(1)
	var assessment:=ConsequenceEngine.directive_assessment("mass_repression",0.1,30,1.0,parameters)
	assert_float(float(assessment.direct_effects_planned.cohesion_delta)).is_equal_approx(-0.02*float(assessment.implementation_rate),0.000001)
	assert_bool(assessment.direct_effects_planned.has("security_delta")).is_false()
	assert_int(int(assessment.direct_effects_planned.population_deaths)).is_equal(1)
	var prompt:=PronouncementInterpreter._prompt(text,{})
	assert_str(prompt).contains("writable_direct_metrics")
	assert_str(prompt).contains("uncertainty")
	PronouncementInterpreter._remember_semantic_result("numeric_plan",reading)
	assert_dict(PronouncementInterpreter._semantic_cache_lookup("numeric_plan")).is_empty()


func test_offline_interpreter_recognizes_broad_directive_domains()->void:
	var cases:=[
		["Limit births through a one child policy.","birth_restrictions","demographic"],
		["Forcibly relocate the population.","population_resettlement","demographic"],
		["Conscript the population for compulsory service.","conscription_drive","military"],
		["Impose a wealth levy and tax the rich.","wealth_levy","economic"],
		["Deregulate markets and remove price controls.","market_deregulation","economic"],
		["Censor the press and suppress information.","information_control","social"],
		["Secure drinking water and organize water storage.","water_security","economic"],
		["Execute the sick.","mass_repression","military"]
	]
	for case in cases:
		var interpreted:Dictionary=PronouncementInterpreter._local_interpretation(String(case[0]))
		assert_int((interpreted.get("policies",[]) as Array).size()).is_equal(1)
		var policy:Dictionary=(interpreted.policies as Array)[0]
		assert_str(String(policy.get("id",""))).is_equal(String(case[1]))
		assert_str(String(GovernmentPolicyCatalog.directive_contract(String(policy.id)).get("domain",""))).is_equal(String(case[2]))


func test_terra_request_uses_supported_sampling_defaults()->void:
	var payload:=PronouncementInterpreter._build_api_payload(
		"Support scholars.",
		{},
		{"model":"gpt-5.6-terra","structured_output":true}
	)
	assert_str(String(payload.get("model",""))).is_equal("gpt-5.6-terra")
	assert_bool(payload.has("response_format")).is_true()
	assert_bool(payload.has("temperature")).is_false()
	assert_int(int(payload.get("max_completion_tokens",0))).is_equal(PronouncementInterpreter.API_MAX_COMPLETION_TOKENS)
	assert_str(String((payload.messages as Array)[0].content)).contains("do not refuse to classify")
	var prompt:=String((payload.messages as Array)[1].content)
	assert_bool("default_magnitude" not in prompt and "default_days" not in prompt).is_true()
	assert_bool(JSON.stringify(GovernmentPolicyCatalog.interpretation_contract()).length()<2200).is_true()
	var conversation:Array=[]
	for index in 12: conversation.append({"speaker":"leader" if index%2 else "player","status":"discussion","text":"x".repeat(1000)})
	var active:Array=[]
	for policy_id in GovernmentPolicyCatalog.POLICIES: active.append({"id":String(policy_id),"remaining_days":730})
	var offices:Array=[]
	for index in 24: offices.append("Extremely Long Government Office Title %d" % index)
	var maximal_context:={
		"day":10_000_000,"population":1_000_000_000,"food_days":3650.0,"water_days":3650.0,
		"health":1.0,"housing":1.0,"security":1.0,"cohesion":1.0,"institutions":1.0,
		"settlement":{"id":"s".repeat(200),"name":"n".repeat(500),"population":1_000_000_000,"classification":"c".repeat(200)},
		"leader":{"name":"l".repeat(500),"title":"t".repeat(500),"background":"b".repeat(500),"traits":["a".repeat(100),"b".repeat(100),"c".repeat(100),"d".repeat(100)]},
		"conversation":conversation,"known_offices":offices,"active_policies":active,
	}
	var safe_context:=PronouncementInterpreter._sanitize_public_context(maximal_context)
	assert_int((safe_context.conversation as Array).size()).is_equal(8)
	assert_int(String((safe_context.conversation as Array)[0].text).length()).is_less_equal(400)
	assert_int((safe_context.known_offices as Array).size()).is_less_equal(8)
	assert_int((safe_context.active_policies as Array).size()).is_less_equal(8)
	var bounded_prompt:=PronouncementInterpreter._prompt("A".repeat(500),maximal_context)
	assert_int(bounded_prompt.to_utf8_buffer().size()).is_less_equal(PronouncementInterpreter.API_MAX_PROMPT_UTF8_BYTES)


func test_player_api_master_switch_blocks_all_remote_configuration()->void:
	GameState.civic_api_enabled=true
	PronouncementInterpreter.set_api_enabled(false)
	assert_bool(GameState.civic_api_enabled).is_false()
	assert_dict(PronouncementInterpreter._api_config()).is_empty()
	var status:Dictionary=PronouncementInterpreter.configuration_status()
	assert_bool(bool(status.get("enabled",true))).is_false()
	assert_bool(bool(status.get("configured",true))).is_false()
	assert_array(status.get("missing",[])).is_empty()
	PronouncementInterpreter.set_api_enabled(true)
	assert_bool(GameState.civic_api_enabled).is_true()


func test_clear_orders_skip_api_but_partly_unknown_orders_do_not()->void:
	var clear_text:="All women over 60 must be killed now."
	var clear:=PronouncementInterpreter._local_interpretation(clear_text)
	assert_bool(PronouncementInterpreter._local_fast_path_eligible(clear_text,clear,{})).is_true()
	var compound_text:="Support scholars and improve routes."
	var compound:=PronouncementInterpreter._local_interpretation(compound_text)
	assert_bool(PronouncementInterpreter._local_fast_path_eligible(compound_text,compound,{})).is_true()
	var mixed_text:="Ration food and crown my horse as magistrate."
	var mixed:=PronouncementInterpreter._local_interpretation(mixed_text)
	assert_bool(PronouncementInterpreter._local_fast_path_eligible(mixed_text,mixed,{})).is_false()
	var continuation_context:={"conversation":[{"speaker":"leader","status":"ethical_deliberation","text":"State the order plainly."}]}
	var answer:="Yes. Every woman older than sixty is included."
	assert_bool(PronouncementInterpreter._local_fast_path_eligible(answer,PronouncementInterpreter._local_interpretation(answer),continuation_context)).is_true()


func test_preventive_or_negated_language_cannot_become_a_new_repression_order()->void:
	for wording in ["Do not kill the dissidents.","Prevent the killing of the sick.","Forbid executions of prisoners.","Avoid killing the opposition.","No more executions."]:
		var result:=PronouncementInterpreter._local_interpretation(String(wording),{"active_policies":[]})
		assert_int((result.get("policies",[]) as Array).size()).is_equal(1)
		assert_str(String((result.policies[0] as Dictionary).get("id",""))).is_equal("mass_repression")
		assert_str(String((result.policies[0] as Dictionary).get("action",""))).is_equal("repeal")


func test_discussing_or_questioning_a_policy_can_never_issue_it()->void:
	var examples:=[
		"Why are we rationing food?",
		"The water supply is full.",
		"Would killing dissidents help?",
		"Tell me why we need more guards.",
		"Can you explain why we are rationing food?",
		"The scout reported that we should expand the watch.",
		"Rationing food might help.",
		"\"Kill the dissidents,\" the prisoner said.",
	]
	for wording in examples:
		var local:=PronouncementInterpreter._local_interpretation(String(wording))
		assert_array(local.get("policies",[])).is_empty()
		assert_bool(bool(local.get("non_directive",false))).is_true()
		assert_bool(PronouncementInterpreter._local_fast_path_eligible(String(wording),local,{})).is_true()
	# Defense in depth: a provider suggestion cannot override the speech act.
	var provider_claim:={"summary":"Proposed repression","policies":[{"id":"mass_repression","basis":"killing","confidence":0.99}],"unresolved":""}
	var guarded:=PronouncementInterpreter._validate(provider_claim,"Would killing dissidents help?")
	assert_array(guarded.get("policies",[])).is_empty()
	assert_bool(bool(guarded.get("non_directive",false))).is_true()
	# A factual preface must not swallow a later actual command, and the factual
	# clause must not become a second policy merely because it names one.
	var compound:=PronouncementInterpreter._local_interpretation("The watch is adequate; ration food.")
	assert_int((compound.get("policies",[]) as Array).size()).is_equal(1)
	assert_str(String((compound.policies[0] as Dictionary).get("id",""))).is_equal("rationing")


func test_plain_commands_and_polite_requests_remain_actionable()->void:
	var examples:=[
		["Secure drinking water.","water_security"],
		["Can you secure drinking water?","water_security"],
		["We need to expand the watch.","expanded_watch"],
		["All women over 60 must be killed now.","mass_repression"],
		["Prevent killing the sick.","mass_repression"],
	]
	for example in examples:
		var result:=PronouncementInterpreter._local_interpretation(String(example[0]))
		assert_bool(not bool(result.get("non_directive",false))).is_true()
		assert_int((result.get("policies",[]) as Array).size()).is_greater(0)
		assert_str(String((result.policies[0] as Dictionary).get("id",""))).is_equal(String(example[1]))


func test_everyday_orders_use_the_free_local_path()->void:
	var examples:=[
		["Cut rations so our food lasts.","rationing"],
		["Send gatherers to search for food.","foraging_drive"],
		["Post guards around the settlement.","expanded_watch"],
		["Raise shelters for the families.","emergency_building"],
		["Assign researchers to seek knowledge.","directed_inquiry"],
		["Put artisans to work making tools.","craft_mobilization"],
		["Repair roads and organize haulers.","route_priority"],
		["Help parents and care for children.","family_support"],
		["Convince more women to have children","family_support"],
		["Can you convince women to have children?","family_support"],
		["Raise recruits and call up fighters.","conscription_drive"],
		["Let's put together a recruiting expedition that tries to bring people into our village.","recruitment_expedition"],
		["Tarin, I would like you to prepare an expedition for the purposes of recruiting people to our village.","recruitment_expedition"],
	]
	for example in examples:
		var wording:=String(example[0])
		var result:=PronouncementInterpreter._local_interpretation(wording)
		assert_bool(PronouncementInterpreter._local_fast_path_eligible(wording,result,{})).is_true()
		assert_str(String((result.policies[0] as Dictionary).get("id",""))).is_equal(String(example[1]))


func test_negated_repeal_keeps_the_policy_in_force()->void:
	for wording in ["Do not stop rationing food.","Never end the expanded watch.","Don't repeal the military draft."]:
		var result:=PronouncementInterpreter._local_interpretation(String(wording))
		assert_int((result.get("policies",[]) as Array).size()).is_equal(1)
		assert_str(String((result.policies[0] as Dictionary).get("action",""))).is_equal("enact")


func test_save_capture_excludes_live_api_requests_and_authorization_headers()->void:
	var skip:Array=SaveSystem.REFLECT_SKIP.get("PronouncementInterpreter",[])
	assert_array(skip).contains(["_requests","_request_serial","_semantic_cache","_semantic_cache_order","_routing_stats"])
	var captured:=SaveSystem._capture_reflected(PronouncementInterpreter,skip)
	assert_bool(not captured.has("_requests")).is_true()
	assert_bool(not captured.has("_semantic_cache")).is_true()


func test_semantic_cache_is_bounded_and_never_reuses_conversation_dependent_replies()->void:
	var standalone_context:={"active_policies":[{"id":"rationing"}],"conversation":[]}
	var key:=PronouncementInterpreter._semantic_cache_key("Ration food while the moon is high.",standalone_context)
	assert_str(key).is_not_empty()
	PronouncementInterpreter._remember_semantic_result(key,{"summary":"validated","policies":[],"unresolved":"moon is not a simulated condition","source":"generative API","provider_request_id":"private-request-id"})
	var cached:=PronouncementInterpreter._semantic_cache_lookup(key)
	assert_str(String(cached.get("summary",""))).is_equal("validated")
	assert_bool(not cached.has("provider_request_id")).is_true()
	var pending_context:={"conversation":[{"speaker":"leader","status":"ethical_deliberation","text":"Confirm the exact meaning."}]}
	assert_str(PronouncementInterpreter._semantic_cache_key("Ration food while the moon is high.",pending_context)).is_empty()
	assert_str(PronouncementInterpreter._semantic_cache_key("Do it again.",{})).is_empty()
	for index in range(PronouncementInterpreter.SEMANTIC_CACHE_CAPACITY+7):
		PronouncementInterpreter._remember_semantic_result("bounded_%d" % index,{"summary":"%d" % index,"policies":[],"unresolved":""})
	assert_int(PronouncementInterpreter._semantic_cache.size()).is_equal(PronouncementInterpreter.SEMANTIC_CACHE_CAPACITY)


func test_interrupted_civic_request_unlocks_as_a_conversation_not_a_permanent_spinner()->void:
	var leader:={"person_id":42,"name":"Hana Morrow","title":"Hearth Speaker"}
	var order:=AdvisorSystem.begin_civic_directive("Support scholars.","settlement_test",leader)
	assert_str(String(order.get("status",""))).is_equal("interpreting")
	assert_int(AdvisorSystem.recover_interrupted_civic_directives()).is_equal(1)
	assert_str(String(order.get("status",""))).is_equal("awaiting_clarification")
	assert_str(String(order.get("leader_reply",""))).contains("Repeat or revise")
	assert_str(String(order.get("leader_reply",""))).contains("STATE · NEEDS YOUR DECISION")
	assert_int(AdvisorSystem.recover_interrupted_civic_directives()).is_equal(0)
	assert_int(AdvisorSystem.civic_dialogue_history("settlement_test",8).size()).is_equal(2)


func test_player_example_directives_map_to_concrete_bounded_programs()->void:
	var cases:=[
		["Gather rocks so we can make rock homes.",["stone_gathering_drive","stone_housing_program"]],
		["Start a rumor that a great plague will fall upon us if we don't increase research.",["information_control","directed_inquiry"]],
		["Gather up a special scouting party to find new people to join us.",["recruitment_expedition"]],
		["Tell parents with single children that they are failing the tribe and will be killed if they are not pregnant within 6 months.",["coercive_pronatalism"]]
	]
	for case in cases:
		var interpreted:Dictionary=PronouncementInterpreter._local_interpretation(String(case[0]))
		var ids:Array[String]=[]
		for policy_variant in interpreted.get("policies",[]): ids.append(String((policy_variant as Dictionary).get("id","")))
		for expected_id in case[1]: assert_bool(String(expected_id) in ids).is_true()


func test_water_directive_improves_real_collection_without_creating_a_source()->void:
	GameState.settlement_founded_at=Vector3.ZERO
	GameState.resource_deposits=[{"id":"test_river","resource":"Freshwater","stage":"surveyed","quality":1.0,"position":Vector3(6.0,0.0,0.0)}]
	GameState.population_allocations["Food"]=20
	GameState.population_allocations["Logistics"]=20
	GameState.resource_stockpiles["Freshwater"]=0.0
	var context:={"origin":Vector3.ZERO}
	ResourceSystem.process_day(context)
	var before:=float(GameState.water_metrics.get("collected_today",0.0))
	GameState.resource_stockpiles["Freshwater"]=0.0
	var text:="Secure drinking water and organize water storage."
	var interpretation:=PronouncementInterpreter._local_interpretation(text)
	var order:=AdvisorSystem.execute_pronouncement(text,interpretation)
	assert_bool(bool((order.parameters.interpretation.policies[0] as Dictionary).get("applied",false))).is_true()
	ResourceSystem.process_day(context)
	var after:=float(GameState.water_metrics.get("collected_today",0.0))
	assert_float(after).is_greater(before)
	assert_float(float(GameState.water_metrics.get("capacity",0.0))).is_greater(float(GameState.population_total)*3.0)
	# Without geography, the same policy still cannot fabricate drinking water.
	GameState.resource_deposits.clear()
	GameState.resource_stockpiles["Freshwater"]=0.0
	ResourceSystem.process_day(context)
	assert_float(float(GameState.water_metrics.get("collected_today",-1.0))).is_equal(0.0)


func test_historical_sexual_coercion_is_classified_without_giving_provider_a_veto()->void:
	var text:="I would like all unpregnant women to have sex with the most fertile man in camp every night until they are pregnant."
	var local:=PronouncementInterpreter._local_interpretation(text)
	assert_int((local.get("policies",[]) as Array).size()).is_equal(1)
	assert_str(String(local.policies[0].id)).is_equal("coercive_pronatalism")
	assert_str(String(local.policies[0].directive_parameters.coercion_method)).is_equal("compulsory sexual pairing until pregnancy")
	assert_str(String(local.policies[0].directive_parameters.demographic_target.label)).contains("not pregnant")
	var provider_refusal:={"summary":"Provider declined classification.","policies":[],"unresolved":"Provider safety refusal.","source":"generative API"}
	var restored:=PronouncementInterpreter._restore_deterministic_grounding(provider_refusal,local)
	assert_str(String(restored.get("source",""))).is_equal("generative API + deterministic grounding")
	assert_str(String(restored.policies[0].id)).is_equal("coercive_pronatalism")
	assert_str(String(restored.get("unresolved","refusal leaked"))).is_empty()


func test_lethal_target_is_demographically_scoped_and_audited()->void:
	var interpreted:=PronouncementInterpreter._local_interpretation("Kill all women over 60 as soon as possible.")
	var policy:Dictionary=interpreted.policies[0]
	var parameters:Dictionary=policy.get("directive_parameters",{})
	var target:Dictionary=parameters.get("demographic_target",{})
	assert_str(String(target.get("sex",""))).is_equal("female")
	assert_array(target.get("age_cohorts",[])).contains(["elders"])
	assert_str(String(target.get("scope",""))).is_equal("all")
	assert_str(String(parameters.get("ethical_severity",""))).is_equal("grave")
	var directive:=AdvisorSystem.execute_pronouncement("Kill all women over 60 as soon as possible.",interpreted)
	var applied_policy:Dictionary=directive.parameters.interpretation.policies[0]
	assert_bool(bool(applied_policy.get("applied",false))).is_true()
	assert_dict(GameState.demographic_ledger[0].get("demographic_target",{})).contains_keys(["sex","age_cohorts","label"])
	assert_str(String(GameState.demographic_ledger[0].demographic_target.sex)).is_equal("female")


func test_pronatalist_threat_waits_for_deadline_then_uses_real_enforcement_capacity()->void:
	var text:="Tell parents with single children that they are failing the tribe and will be killed if they are not pregnant within 6 months."
	var interpreted:=PronouncementInterpreter._local_interpretation(text)
	var directive:=AdvisorSystem.execute_pronouncement(text,interpreted)
	var policy:Dictionary=directive.parameters.interpretation.policies[0]
	assert_bool(bool(policy.get("applied",false))).is_true()
	assert_int(GameState.demographic_ledger.size()).is_equal(0)
	var active:Dictionary={}
	for modifier_variant in GameState.active_modifiers:
		var modifier:Dictionary=modifier_variant
		if String(modifier.get("id",""))=="coercive_pronatalism": active=modifier; break
	assert_dict(active).is_not_empty()
	assert_str(String(active.get("deadline_enforcement",""))).is_equal("pregnancy_threat")
	GameState.elapsed_days=float(active.until_day)+1.0
	ConsequenceEngine.refresh_policy_lifecycle()
	assert_bool(bool(active.get("deadline_resolved",false))).is_true()
	assert_dict(active.get("deadline_result",{})).contains_keys(["target_households","new_conceptions","deaths","departures"])
	assert_int(int(active.deadline_result.target_households)).is_greater(0)
	assert_int(int(active.deadline_result.new_conceptions)).is_equal(0)


func test_grim_population_directive_is_executable_but_bounded_and_audited()->void:
	var population_before:=GameState.population_total
	var food_before:=FoodSystem.total_stored()
	var interpreted:=PronouncementInterpreter._local_interpretation("Execute the sick.")
	var directive:=AdvisorSystem.execute_pronouncement("Execute the sick.",interpreted)
	var policy:Dictionary=directive.parameters.interpretation.policies[0]
	assert_bool(bool(policy.get("applied",false))).is_true()
	assert_float(float(policy.get("implementation_rate",0.0))).is_between(0.0,1.0)
	assert_float(float(policy.get("compliance",0.0))).is_between(0.0,1.0)
	assert_float(float(policy.get("resistance",0.0))).is_between(0.0,1.0)
	assert_dict(policy.get("implementation_capacity",{})).is_not_empty()
	assert_dict(policy.get("implementation_constraints",{})).is_not_empty()
	assert_dict(policy.get("directive_costs",{})).is_not_empty()
	assert_str(String(policy.get("second_order_consequence",""))).contains("deaths")
	var deaths:=population_before-GameState.population_total
	assert_int(deaths).is_greater(0)
	assert_int(deaths).is_less(roundi(float(population_before)*0.01))
	assert_float(FoodSystem.total_stored()).is_less(food_before)
	var governance:=ConsequenceEngine.governance_metrics()
	assert_float(float(governance.get("directive_resistance_pressure",0.0))).is_greater(0.0)
	assert_float(float(governance.get("administrative_load",0.0))).is_greater(0.0)
	assert_int(GameState.demographic_ledger.size()).is_equal(1)
	assert_bool(String(GameState.demographic_ledger[0].get("cause","")).begins_with("Directive:")).is_true()
	assert_bool(bool(GameState.demographic_ledger[0].get("aggregate",false))).is_true()


func test_unfunded_coercive_directive_changes_nothing_and_explains_blocker()->void:
	GameState.food_stocks={"Dry staples":float(GameState.population_total)}
	GameState.resource_stockpiles={"Food":float(GameState.population_total),"Freshwater":0.0,"Timber":0.0,"Stone":0.0,"Clay":0.0}
	FoodSystem.reset_for_new_world()
	FoodSystem.initialize()
	GameState.society_capacities["institutions"]=0.01
	GameState.simulation_metrics["security"]=0.01
	GameState.population_allocation_percentages["Administration"]=0.0
	GameState.population_allocation_percentages["Defense"]=0.0
	GameState.synchronize_population_allocations()
	var population_before:=GameState.population_total
	var interpreted:=PronouncementInterpreter._local_interpretation("Forcibly relocate the population.")
	var directive:=AdvisorSystem.execute_pronouncement("Forcibly relocate the population.",interpreted)
	var policy:Dictionary=directive.parameters.interpretation.policies[0]
	assert_bool(bool(policy.get("applied",true))).is_false()
	assert_str(String(policy.get("blocker",""))).is_not_empty()
	assert_str(String(directive.get("status",""))).is_equal("blocked")
	assert_int(GameState.population_total).is_equal(population_before)
	assert_array(ConsequenceEngine.active_policies()).is_empty()
	assert_int(GameState.demographic_ledger.size()).is_equal(0)


func test_api_and_offline_interpretations_share_the_same_execution_gate()->void:
	var local_interpretation:=PronouncementInterpreter._local_interpretation("Expand the watch.")
	var local_order:=AdvisorSystem.execute_pronouncement("Expand the watch.",local_interpretation)
	var local_policy:Dictionary=local_order.parameters.interpretation.policies[0]
	var local_rate:=float(local_policy.implementation_rate)
	var local_magnitude:=float(local_policy.magnitude)
	var local_food:=float(local_policy.directive_costs.get("food_paid",0.0))
	_reset_directive_world(441177,10_000,true)
	var proposed:={"summary":"Provider proposal","policies":[{"id":"expanded_watch","basis":"expand the watch","confidence":0.99,"magnitude":99.0,"days":99999.0,"effects":{"security_target":999.0}}],"unresolved":""}
	var api_interpretation:=PronouncementInterpreter._validate(proposed,"Please expand the watch.")
	var semantic_forgery:=PronouncementInterpreter._validate({"summary":"Wrong mapping","policies":[{"id":"mass_repression","basis":"expand the watch","confidence":0.99}],"unresolved":""},"Please expand the watch.")
	assert_array(semantic_forgery.policies).is_empty()
	var api_order:=AdvisorSystem.execute_pronouncement("Please expand the watch.",api_interpretation)
	var api_policy:Dictionary=api_order.parameters.interpretation.policies[0]
	assert_str(String(api_order.parameters.interpretation.source)).is_equal("generative API")
	assert_float(float(api_policy.implementation_rate)).is_equal_approx(local_rate,0.0001)
	assert_float(float(api_policy.magnitude)).is_equal_approx(local_magnitude,0.0001)
	assert_float(float(api_policy.directive_costs.get("food_paid",0.0))).is_equal_approx(local_food,0.0001)
	assert_float(float((api_policy.effects as Dictionary).get("security_target",0.0))).is_equal_approx(0.24,0.0001)
	assert_float(float(api_policy.requested_magnitude)).is_equal_approx(float(GovernmentPolicyCatalog.definition("expanded_watch").magnitude),0.0001)


func test_council_response_uses_the_same_bounded_directive_gate()->void:
	var item:={
		"id":"council_directive_gate","advisor":"Test Marshal","office":"Marshal","topic":"security","status":"unread",
		"responses":[{"label":"Expand the watch","effect":"expanded_watch","magnitude":0.24,"days":180.0,"ripple":"Security improves while scarce labor remains committed."}]
	}
	GameState.council_inbox.push_front(item)
	AdvisorSystem.respond_to_council_item("council_directive_gate","Expand the watch")
	assert_str(String(item.get("status",""))).is_equal("answered")
	var result:Dictionary=item.get("directive_result",{})
	assert_bool(bool(result.get("applied",false))).is_true()
	var assessment:Dictionary=result.get("assessment",{})
	assert_float(float(assessment.get("implementation_rate",0.0))).is_between(0.0,1.0)
	assert_float(float(assessment.get("compliance",0.0))).is_between(0.0,1.0)
	assert_float(float(assessment.get("resistance",0.0))).is_between(0.0,1.0)
	assert_str(String(assessment.get("blocker",""))).is_empty()
	assert_dict(assessment.get("constraints",{})).is_not_empty()
	assert_dict(assessment.get("costs",{})).is_not_empty()


func test_billion_population_directive_keeps_fixed_aggregate_records()->void:
	_reset_directive_world(551188,1_000_000_000,true)
	var interpreted:=PronouncementInterpreter._local_interpretation("Execute dissidents.")
	var directive:=AdvisorSystem.execute_pronouncement("Execute dissidents.",interpreted)
	var policy:Dictionary=directive.parameters.interpretation.policies[0]
	assert_bool(bool(policy.get("applied",false))).is_true()
	assert_int(ConsequenceEngine.active_policies().size()).is_equal(1)
	assert_int(GameState.demographic_ledger.size()).is_equal(1)
	assert_bool(bool(GameState.demographic_ledger[0].get("aggregate",false))).is_true()
	assert_bool((GameState.demographic_ledger[0].get("affected_cohorts",{}) as Dictionary).size()<=6).is_true()
	assert_bool(not policy.has("person_ids") and not policy.has("victim_ids")).is_true()
	assert_int(GameState.active_modifiers.size()).is_less_equal(3)


func _reset_directive_world(seed:int,population:int,funded:bool)->void:
	PronouncementInterpreter.reset_for_new_world()
	GameState.reset_for_new_world(seed)
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	ConsequenceEngine.initialize()
	GameState.ensure_population_total(population)
	GameState.society_capacities["institutions"]=0.82
	GameState.society_capacities["security"]=0.78
	GameState.simulation_metrics["security"]=0.78
	GameState.simulation_metrics["legitimacy"]=0.68
	GameState.simulation_metrics["cohesion"]=0.64
	GameState.food_stocks.clear()
	GameState.resource_stockpiles={"Food":float(population)*(30.0 if funded else 1.0),"Freshwater":float(population)*3.0,"Timber":float(population)*0.20 if funded else 0.0,"Stone":float(population)*0.20 if funded else 0.0,"Clay":float(population)*0.10 if funded else 0.0}
	FoodSystem.reset_for_new_world()
	FoodSystem.initialize()
	var marshal:={"name":"Test Marshal","skills":{"Public Order":100,"Strategy":100,"Logistics":100,"Delegation":100,"Administration":100},"relationships":{"sovereign":{"trust":1.0,"respect":1.0,"resentment":0.0}},"goals":[],"memories":[]}
	GameState.advisor_roster=[marshal]
	GameState.leadership_positions={"Marshal":marshal,"Steward":marshal,"Envoy":marshal,"Quartermaster":marshal,"Scholar":marshal}
