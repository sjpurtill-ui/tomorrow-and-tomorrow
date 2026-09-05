extends GdUnitTestSuite


func before_test()->void:
	_reset_world()


func test_committed_directive_reports_once_after_simulated_delay()->void:
	var order:=_committed_watch_order()
	var scheduled:=CivicImplementationSystem.schedule_order(order,10)
	assert_str(String(scheduled.get("state",""))).is_equal("pending")
	assert_int(int(scheduled.get("due_day",10))).is_greater(10)
	assert_int(GameState.council_inbox.size()).is_equal(0)
	GameState.simulation_metrics["security"]=minf(0.99,float(GameState.simulation_metrics.get("security",0.78))+0.04)
	var due_day:=int(scheduled.due_day)
	GameState.elapsed_days=due_day
	var events:=CivicImplementationSystem.process_day(due_day)
	assert_int(events.size()).is_equal(1)
	assert_int(GameState.council_inbox.size()).is_equal(1)
	assert_str(String(GameState.council_inbox[0].get("advisor",""))).is_equal("Aren Vale")
	assert_bool(String(GameState.council_inbox[0].get("report_outcome","")) in ["success","partial","failure"]).is_true()
	assert_bool("%" not in String(GameState.council_inbox[0].get("text",""))).is_true()
	assert_bool("→" not in String(GameState.council_inbox[0].get("text",""))).is_true()
	assert_str(String(order.implementation_followup.get("state",""))).is_equal("reported")
	CivicImplementationSystem.process_day(due_day+1)
	assert_int(GameState.council_inbox.size()).is_equal(1)


func test_lost_implementation_record_produces_bounded_failure_report()->void:
	var order:=_committed_watch_order()
	var scheduled:=CivicImplementationSystem.schedule_order(order,20)
	GameState.active_modifiers.clear()
	var due_day:=int(scheduled.due_day)
	GameState.elapsed_days=due_day
	CivicImplementationSystem.process_day(due_day)
	var outcome:Dictionary=order.get("implementation_followup",{})
	assert_str(String(outcome.get("outcome",""))).is_equal("failure")
	assert_str(String(outcome.get("report_text",""))).contains("did not take hold")
	assert_int((outcome.get("policy_results",[]) as Array).size()).is_equal(1)
	assert_bool(bool((outcome.policy_results as Array)[0].get("bounded",false))).is_true()


func test_recruitment_directive_waits_for_its_physical_party_and_reports_return()->void:
	var order:=_recruitment_order(77)
	CivilizationSystem.scout_missions=[{"mission_id":77,"target_kind":"recruit_people","target_id":"recruit_people"}]
	var scheduled:=CivicImplementationSystem.schedule_order(order,30)
	var due_day:=int(scheduled.due_day)
	GameState.elapsed_days=due_day
	assert_array(CivicImplementationSystem.process_day(due_day)).is_empty()
	assert_str(String(order.implementation_followup.get("state",""))).is_equal("pending")
	assert_int(GameState.council_inbox.size()).is_equal(0)
	CivilizationSystem.scout_missions.clear()
	CivilizationSystem.scout_reports.push_front({"mission_id":77,"mission_kind":"recruit_people","recruits":3,"returned_personnel":6,"lost_personnel":0})
	GameState.elapsed_days=due_day+1
	CivicImplementationSystem.process_day(due_day+1)
	assert_str(String(order.implementation_followup.get("outcome",""))).is_equal("success")
	assert_str(String(order.implementation_followup.get("report_text",""))).contains("chosen to join")
	assert_bool("3" not in String(order.implementation_followup.get("report_text",""))).is_true()


func test_recruitment_directive_reports_empty_handed_return_as_partial()->void:
	var order:=_recruitment_order(78)
	var scheduled:=CivicImplementationSystem.schedule_order(order,40)
	CivilizationSystem.scout_reports.push_front({"mission_id":78,"mission_kind":"recruit_people","recruits":0,"returned_personnel":6,"lost_personnel":0})
	var due_day:=int(scheduled.due_day)
	GameState.elapsed_days=due_day
	CivicImplementationSystem.process_day(due_day)
	assert_str(String(order.implementation_followup.get("outcome",""))).is_equal("partial")
	assert_str(String(order.implementation_followup.get("report_text",""))).contains("no one willing")


func _committed_watch_order()->Dictionary:
	var interpretation:=PronouncementInterpreter._local_interpretation("Expand the watch.")
	var order:=AdvisorSystem.execute_pronouncement("Expand the watch.",interpretation)
	order["settlement_id"]="player_settlement_1"
	order["leader_person_id"]=41
	order["addressed_to"]="Aren Vale"
	order["leader_title"]="Settlement leader"
	return order


func _recruitment_order(mission_id:int)->Dictionary:
	var definition:=GovernmentPolicyCatalog.definition("recruitment_expedition")
	var policy:Dictionary={
		"id":"recruitment_expedition","action":"enact","applied":true,"days":90.0,
		"magnitude":float(definition.get("magnitude",0.12)),"requested_magnitude":float(definition.get("magnitude",0.12)),
		"implementation_rate":0.64,"office_execution_factor":0.72,"operation_result":{"ok":true,"mission_id":mission_id},
	}
	var order:Dictionary={
		"id":"order_recruitment_%d" % mission_id,"type":"pronouncement","settlement_id":"player_settlement_1",
		"leader_person_id":41,"addressed_to":"Aren Vale","leader_title":"Settlement leader",
		"parameters":{"text":"Find people willing to join us.","interpretation":{"policies":[policy]}},
	}
	GameState.sovereign_orders.push_front(order)
	return order


func _reset_world()->void:
	PronouncementInterpreter.reset_for_new_world()
	GameState.reset_for_new_world(919191)
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	CivicImplementationSystem.reset_for_new_world()
	ConsequenceEngine.initialize()
	GameState.ensure_population_total(10_000)
	GameState.society_capacities["institutions"]=0.82
	GameState.society_capacities["security"]=0.78
	GameState.simulation_metrics["security"]=0.78
	GameState.simulation_metrics["legitimacy"]=0.68
	GameState.simulation_metrics["cohesion"]=0.64
	GameState.resource_stockpiles={"Food":300_000.0,"Freshwater":30_000.0,"Timber":2_000.0,"Stone":2_000.0,"Clay":1_000.0}
	GameState.food_stocks={"Dry staples":300_000.0}
	FoodSystem.reset_for_new_world()
	FoodSystem.initialize()
	var leader:={"person_id":41,"name":"Aren Vale","skills":{"Defense":100,"Administration":100,"Logistics":100},"relationships":{"sovereign":{"trust":1.0,"respect":1.0,"resentment":0.0}},"goals":[],"memories":[]}
	GameState.advisor_roster=[leader]
	GameState.leadership_positions={"Marshal":leader,"Steward":leader,"Envoy":leader,"Quartermaster":leader,"Scholar":leader}
