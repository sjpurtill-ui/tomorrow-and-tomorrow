extends GdUnitTestSuite


func before_test()->void:
	_reset_directive_world(441177,10_000,true)


func test_offline_interpreter_recognizes_broad_directive_domains()->void:
	var cases:=[
		["Limit births through a one child policy.","birth_restrictions","demographic"],
		["Forcibly relocate the population.","population_resettlement","demographic"],
		["Conscript the population for compulsory service.","conscription_drive","military"],
		["Impose a wealth levy and tax the rich.","wealth_levy","economic"],
		["Deregulate markets and remove price controls.","market_deregulation","economic"],
		["Censor the press and suppress information.","information_control","social"],
		["Execute the sick.","mass_repression","military"]
	]
	for case in cases:
		var interpreted:Dictionary=PronouncementInterpreter._local_interpretation(String(case[0]))
		assert_int((interpreted.get("policies",[]) as Array).size()).is_equal(1)
		var policy:Dictionary=(interpreted.policies as Array)[0]
		assert_str(String(policy.get("id",""))).is_equal(String(case[1]))
		assert_str(String(GovernmentPolicyCatalog.directive_contract(String(policy.id)).get("domain",""))).is_equal(String(case[2]))


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
