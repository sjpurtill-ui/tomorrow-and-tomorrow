extends GdUnitTestSuite

class SiegeFixture extends "res://scripts/diplomatic_commitments.gd":
	var siege:Dictionary={}
	func siege_info(_id:String)->Dictionary: return siege

func before_test()->void:
	GameState.reset_for_new_world(424242)
	SettlementModel.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	ForeignDiplomacy.reset_for_new_world(); ForeignDiplomacy.ensure()
	GameState.civic_api_enabled=false
	GameState.initialize_population_model(); GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded(); GovernmentPeopleSystem.initialize()
	FoodSystem.reset_for_new_world(); FoodSystem.initialize(); FoodSystem.receive_external_food(100000)
	GameState.resource_stockpiles.Timber=100
	for index:int in 3:
		var civ:Dictionary=CivilizationSystem.civilizations[index]
		civ.player_relation.contact_level=2; civ.player_relation.opinion=.5
		civ.player_relation.home_location_known=true
		civ.player_relation.home_position={"x":CivilizationSystem.player_world_origin.x+1+index,"z":CivilizationSystem.player_world_origin.y}
	for civ:Dictionary in CivilizationSystem.civilizations:
		for relation:Dictionary in civ.relations.values(): relation.opinion=.5

func id(index:int=0)->String: return String(CivilizationSystem.civilizations[index].id)
func model(): return ForeignDiplomacy.commitments
func finish()->void:
	GameState.elapsed_days=int(CivilizationSystem.diplomatic_mission.return_day)
	CivilizationSystem._process_diplomatic_mission(int(GameState.elapsed_days))

func test_protection_is_carried_and_replay_cannot_duplicate_commitments()->void:
	var food:=FoodSystem.total_stored()
	assert_bool(model().send(id(),model().terms("protection")).get("ok",false)).is_true()
	var mission:=CivilizationSystem.diplomatic_mission.duplicate(true)
	assert_dict(model().state.pacts).is_empty()
	assert_bool(model().resolve(id(),mission).has("error")).is_true()
	assert_float(FoodSystem.total_stored()).is_less(food)
	finish()
	assert_bool(model().state.pacts.has(id())).is_true()
	assert_bool(model().resolve(id(),mission).has("error")).is_true()
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(100.0)

func test_independent_members_consult_disagree_admit_and_leave()->void:
	assert_bool(model().send(id(),model().terms("found_faction")).get("ok",false)).is_true(); finish()
	assert_int(model().faction().members.size()).is_equal(2)
	var candidate:Dictionary=CivilizationSystem.civilizations[1]
	candidate.player_relation.opinion=-.1
	assert_bool(model().send(id(1),model().terms("join_faction")).get("ok",false)).is_true(); finish()
	assert_int(model().faction().members.size()).is_equal(2)
	assert_bool(model().faction().votes[id(1)].accept).is_false()
	candidate.player_relation.opinion=.5
	FoodSystem.receive_external_food(100000)
	assert_bool(model().send(id(1),model().terms("join_faction")).get("ok",false)).is_true(); finish()
	assert_int(model().faction().members.size()).is_equal(3)
	assert_bool(model().send(id(),model().terms("leave_faction")).get("ok",false)).is_true(); finish()
	assert_dict(model().faction()).is_empty()
	assert_int(model().faction(id()).members.size()).is_equal(2)
	assert_bool(model().send(id(),model().terms("join_faction")).get("ok",false)).is_true(); finish()
	assert_int(model().faction().members.size()).is_equal(3)

func test_goal_reallocates_bounded_effort_and_war_debate_does_not_declare_war()->void:
	model().send(id(),model().terms("found_faction")); finish()
	model().send(id(),model().terms("set_goal","exchange")); finish()
	var original:Dictionary=CivilizationSystem._allocation_for("sustenance")
	var adjusted:Dictionary=model().policy_allocations(id(),original)
	var sum_before:=0.0; var sum_after:=0.0
	for value in original.values(): sum_before+=float(value)
	for value in adjusted.values(): sum_after+=float(value)
	assert_float(sum_after).is_equal_approx(sum_before,.00001)
	assert_float(float(adjusted.knowledge)).is_greater(float(original.knowledge))
	model().send(id(),model().terms("debate_war","defense",id(2))); finish()
	assert_bool(CivilizationSystem.civilizations[2].player_relation.at_war).is_false()
	assert_bool(model().faction().votes[id()].accept).is_false()

func test_conversation_drafts_do_not_ratify_and_survive_failure_and_save()->void:
	ForeignDiplomacy.leader(id())["audience_day"]=0
	var proposal:Dictionary=model().terms("found_faction","routes")
	assert_bool(ForeignDialogue.accept(id(),{"reply":"Let us discuss a league of safe roads.","accord":"","tone":"equals","generous":false,"commitment":proposal})).is_true()
	assert_dict(model().faction()).is_empty()
	ForeignDialogue.ask(id(),"What would you expect from us?")
	assert_bool(ForeignDialogue.thread(id()).retryable).is_true()
	assert_dict(ForeignDialogue.thread(id()).draft.commitment).is_equal(proposal)
	var saved:=ForeignDiplomacy.export_state()
	assert_bool(ForeignDiplomacy.import_state(JSON.parse_string(JSON.stringify(saved))).get("ok",false)).is_true()
	assert_dict(ForeignDialogue.thread(id()).draft.commitment).is_equal(proposal)
	var context:=JSON.stringify(ForeignDialogue.known_context(id()))
	assert_bool(context.contains("military_population") or context.contains("food_days")).is_false()

func fixture()->SiegeFixture:
	var result:=SiegeFixture.new()
	CivilizationSystem._start_war("player",id(1),"defend","",1,"Organized rival invasion")
	result.state.pacts[id()]={"since":0,"trigger":"defensive_siege","obligation":result.OBLIGATION}
	result.siege={"id":"siege_test","active":true,"attacker_id":id(1),"defender_id":"player","start_day":1,"target_position":{"x":0,"z":0}}
	return result

func test_trigger_requires_actual_matching_siege_and_prior_promise()->void:
	var value:=fixture()
	value.notify_attack(id(2),"player","fake",1)
	assert_array(value.state.obligations).is_empty()
	value.notify_attack(id(1),"player","siege_test",1)
	value.notify_attack(id(1),"player","siege_test",1)
	assert_int(value.state.obligations.size()).is_equal(1)
	value.state.pacts.clear()
	assert_bool(value.covered(id(),"player","siege_test")).is_false()

func test_player_started_war_does_not_trigger_defensive_coverage()->void:
	var value:=fixture()
	CivilizationSystem.war_history.clear()
	CivilizationSystem._start_war("player",id(1),"limited","",1,"War declared by the player")
	value.notify_attack(id(1),"player","siege_test",1)
	assert_array(value.state.obligations).is_empty()

func test_late_joining_cannot_retroactively_create_defensive_obligations()->void:
	model().send(id(),model().terms("found_faction")); finish()
	var league:Dictionary=model().faction()
	var day:=int(GameState.elapsed_days)+1
	model().send(id(1),model().terms("join_faction")); finish()
	assert_int(int(league.joined[id(1)])).is_greater(day)
	model().create_obligations(id(2),"player","existing_war",day)
	for obligation:Dictionary in model().state.obligations: assert_str(String(obligation.donor)).is_not_equal(id(1))

func test_ally_war_request_waits_for_message_and_does_not_invent_a_siege()->void:
	model().send(id(),model().terms("protection")); finish()
	var started:=int(GameState.elapsed_days)+1
	CivilizationSystem._start_war(id(1),id(),"limited","",started,"A physically carried declaration follows escalating border pressure")
	GameState.elapsed_days=started; model().observe_ally_wars()
	assert_array(model().state.obligations).is_empty()
	GameState.elapsed_days=started+30; model().observe_ally_wars()
	assert_int(model().state.obligations.size()).is_equal(1)
	assert_str(model().state.obligations[0].donor).is_equal("player")
	assert_bool(String(model().state.obligations[0].siege_id).begins_with("war:")).is_true()
	assert_array(model().state.relief).is_empty()
	var aid:=CivilizationSystem.dispatch_diplomat(id(),"Food","send_aid")
	assert_bool(aid.get("ok",false)).is_true()
	assert_str(model().state.obligations[0].status).is_equal("requested")
	finish()
	assert_str(model().state.obligations[0].status).is_equal("food_aid_delivered")

func test_actual_save_load_preserves_ratified_and_traveling_terms()->void:
	model().send(id(),model().terms("found_faction")); finish()
	model().send(id(1),model().terms("join_faction"))
	var saved:=ForeignDiplomacy.export_state()
	var mission:=CivilizationSystem.diplomatic_mission.duplicate(true)
	var slot:="protection_factions_test"
	assert_array(CivilizationSystem.validate_state()).is_empty()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	ForeignDiplomacy.reset_for_new_world(); CivilizationSystem.diplomatic_mission.clear()
	var result:=SaveSystem.load_game(slot)
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	assert_dict(ForeignDiplomacy.export_state()).is_equal(saved)
	assert_dict(CivilizationSystem.diplomatic_mission).is_equal(mission)
	finish()
	assert_int(model().faction().members.size()).is_equal(3)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))

func test_relief_conserves_donor_stocks_travels_and_receipt_is_one_use()->void:
	var value:=fixture(); value.notify_attack(id(1),"player","siege_test",1)
	var donor:Dictionary=CivilizationSystem.civilizations[0]
	donor.population=1000.0; donor.military_population=100.0; donor.food_days=100.0; donor.military_readiness=.8
	var population:=float(donor.population); var troops:=float(donor.military_population); var food:=float(donor.food_days)*population
	var quote:=value.relief_quote(id(),"player","siege_test")
	assert_bool(quote.get("ok",false)).is_true()
	var result:=value.dispatch_relief(id(),"player","siege_test")
	assert_bool(result.get("ok",false)).is_true()
	assert_bool(value.validate(JSON.parse_string(JSON.stringify(value.state)))).is_true()
	var corrupt:=value.state.duplicate(true); corrupt.relief[0].food*=2
	assert_bool(value.validate(corrupt)).is_false()
	assert_float(float(donor.population)).is_equal(population)
	assert_float(float(donor.military_population)+int(quote.troops)).is_equal(troops)
	assert_float(float(donor.food_days)*population+float(quote.food)).is_equal_approx(food,.00001)
	assert_bool(value.consume_receipt(result.receipt_id,"siege_test").has("error")).is_true()
	var receipt:Dictionary=value.state.relief[0]
	GameState.elapsed_days=int(receipt.due_day); receipt.status="delivered"
	assert_bool(value.consume_receipt(result.receipt_id,"wrong").has("error")).is_true()
	assert_bool(value.consume_receipt(result.receipt_id,"siege_test").get("ok",false)).is_true()
	assert_bool(value.consume_receipt(result.receipt_id,"siege_test").has("error")).is_true()
	assert_bool(value.complete_relief(result.receipt_id,int(receipt.troops)+1,0).has("error")).is_true()
	assert_bool(value.complete_relief(result.receipt_id,int(receipt.troops),float(receipt.food)).get("ok",false)).is_true()
	assert_float(float(donor.military_population)).is_less(troops)
	GameState.elapsed_days=int(receipt.due_day); value.advance_relief(int(GameState.elapsed_days))
	assert_float(float(donor.military_population)).is_equal(troops)
	assert_array(value.state.relief).is_empty()
	assert_float(float(donor.food_days)*population).is_less(food)

func test_unaffordable_relief_is_not_created_and_save_validation_is_atomic()->void:
	var value:=fixture(); value.notify_attack(id(1),"player","siege_test",1)
	CivilizationSystem.civilizations[0].food_days=2
	assert_bool(value.dispatch_relief(id(),"player","siege_test").has("error")).is_true()
	assert_array(value.state.relief).is_empty()
	model().send(id(),model().terms("protection")); finish()
	var saved:=ForeignDiplomacy.export_state()
	var corrupt:=saved.duplicate(true); corrupt.commitments.pacts[id()].since=-1
	assert_bool(ForeignDiplomacy.import_state(corrupt).has("error")).is_true()
	assert_dict(ForeignDiplomacy.export_state()).is_equal(saved)
	saved.erase("commitments")
	assert_bool(ForeignDiplomacy.import_state(saved).get("ok",false)).is_true()
	assert_dict(model().state.pacts).is_empty()
