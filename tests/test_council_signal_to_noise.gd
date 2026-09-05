extends GdUnitTestSuite


func before_test()->void:
	GameState.reset_for_new_world(741991)
	AdvisorSystem.reset_for_new_world()
	AdvisorSystem.initialize()
	var steward:={
		"name":"Test Steward","traits":[],"skills":{},"background":"Trader and Mediator",
		"relationships":{"sovereign":{"trust":0.5,"respect":0.5,"fear":0.0,"resentment":0.0,"obligation":0.5}},
		"beliefs":[],"memories":[],"goals":[],"honesty":0.7,"courage":0.6,"pride":0.4,"suspicion":0.3
	}
	GameState.advisor_roster=[steward]
	GameState.leadership_positions={"Steward":steward}


func test_observational_economy_warning_does_not_become_fake_decision()->void:
	var item:Dictionary=AdvisorSystem.generate_consequence_item({
		"title":"Exchange Under Strain","description":"The same market pressure persists.",
		"domain":"economy","severity":"warning","condition_id":"economy_market_seizure"
	})
	assert_dict(item).is_empty()
	assert_int(GameState.council_inbox.size()).is_equal(0)


func test_repeated_unread_condition_updates_one_card_instead_of_spamming()->void:
	var event:={"title":"Stores Are Falling","description":"Stores are falling.","domain":"food","severity":"warning","condition_id":"low_food"}
	var first:Dictionary=AdvisorSystem.generate_consequence_item(event)
	assert_dict(first).is_not_empty()
	GameState.elapsed_days=30.0
	var updated:Dictionary=AdvisorSystem.generate_consequence_item(event)
	assert_str(String(updated.get("id",""))).is_equal(String(first.get("id","")))
	assert_int(GameState.council_inbox.size()).is_equal(1)
	assert_int(int(GameState.council_inbox[0].get("occurrences",0))).is_equal(2)
	assert_int(int(GameState.council_inbox[0].get("day",-1))).is_equal(30)


func test_answered_condition_stays_quiet_until_escalation_or_a_year()->void:
	var event:={"title":"Stores Are Falling","description":"Stores are falling.","domain":"food","severity":"warning","condition_id":"low_food"}
	var first:Dictionary=AdvisorSystem.generate_consequence_item(event)
	first["status"]="answered"
	first["response"]="Impose measured rationing"
	GameState.elapsed_days=60.0
	assert_dict(AdvisorSystem.generate_consequence_item(event)).is_empty()
	assert_int(GameState.council_inbox.size()).is_equal(1)
	var escalation:=event.duplicate(true)
	escalation["severity"]="danger"
	GameState.elapsed_days=61.0
	assert_dict(AdvisorSystem.generate_consequence_item(escalation)).is_not_empty()
	assert_int(GameState.council_inbox.size()).is_equal(2)


func test_council_view_filters_routine_acknowledgments_from_decisions()->void:
	GameState.council_inbox.push_front({
		"id":"routine","topic":"economy","status":"unread",
		"responses":[{"label":"Acknowledge","effect":"","ripple":"No order changes."}]
	})
	AdvisorSystem.generate_consequence_item({"title":"Stores Are Falling","description":"Stores are falling.","domain":"food","severity":"warning","condition_id":"low_food"})
	var decisions:Array[Dictionary]=AdvisorSystem.council_decision_items()
	assert_int(decisions.size()).is_equal(1)
	assert_str(String(decisions[0].get("condition_key",""))).is_equal("low_food")
	assert_int(AdvisorSystem.routine_report_count()).is_equal(1)
