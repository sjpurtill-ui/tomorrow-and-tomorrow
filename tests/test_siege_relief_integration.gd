extends "res://tests/test_diplomatic_commitments.gd"

func before_test()->void:
	super.before_test()
	MilitaryCampaign.reset_for_new_world()
	var donor:Dictionary=CivilizationSystem.civilizations[0]
	donor.population=1000.0; donor.military_population=100.0
	donor.cohorts=CivilizationSystem._scaled_cohorts(donor.cohorts,1000.0)

func actual_siege()->String:
	model().send(id(),model().terms("protection")); finish()
	GameState.elapsed_days+=1
	CivilizationSystem._start_war("player",id(1),"defend","",int(GameState.elapsed_days),"Organized rival invasion")
	CivilizationSystem.civilizations[1].player_relation["at_war"]=true
	CivilizationSystem.civilizations[1].player_relation["treaty"]="war"
	MilitaryCampaign.settlement_defense["stage"]=2
	MilitaryCampaign._create_civilization_threat({"source_civ_id":id(1),"source_name":"Invading force","strength":500,"incident_kind":"campaign"},"defensive")
	assert_bool(MilitaryCampaign.begin_siege().get("ok",false)).is_true()
	return String(MilitaryCampaign.active_siege.id)

func test_real_relief_arrives_saves_supports_and_returns_with_conserved_accounts()->void:
	var siege_id:=actual_siege()
	var donor:Dictionary=CivilizationSystem.civilizations[0]
	donor.food_days=120.0; donor.military_readiness=.8
	var military:=float(donor.military_population)
	var population:=float(donor.population)
	var player_population:=GameState.population_total
	var food:=float(donor.food_days)*population
	var quote:Dictionary=model().relief_quote(id(),"player",siege_id)
	assert_bool(quote.get("ok",false)).override_failure_message(str(quote)).is_true()
	var departure:Dictionary=model().dispatch_relief(id(),"player",siege_id)
	assert_bool(departure.get("ok",false)).is_true()
	assert_array(MilitaryCampaign.active_siege.relief).is_empty()
	var receipt:Dictionary=model().state.relief[0]
	GameState.elapsed_days=int(receipt.due_day)-1
	model().advance_relief(int(GameState.elapsed_days))
	assert_array(MilitaryCampaign.active_siege.relief).is_empty()
	GameState.elapsed_days+=1; model().advance_relief(int(GameState.elapsed_days))
	assert_int(MilitaryCampaign.active_siege.relief.size()).is_equal(1)
	assert_str(String(receipt.status)).is_equal("camped")
	assert_bool(MilitaryCampaign.receive_siege_relief(siege_id,String(receipt.id)).has("error")).is_true()
	MilitaryCampaign.last_processed_day=int(GameState.elapsed_days)
	MilitaryCampaign._process_siege_day()
	var camp:Dictionary=MilitaryCampaign.active_siege.relief[0]
	assert_float(float(camp.food)).is_equal_approx(float(quote.camp_food)-float(quote.troops)*.55,.0001)
	var slot:="siege_relief_integration_test"
	assert_array(CivilizationSystem.validate_state()).is_empty()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	MilitaryCampaign.active_siege.clear(); ForeignDiplomacy.reset_for_new_world()
	var restored:=SaveSystem.load_game(slot)
	assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_int(MilitaryCampaign.active_siege.relief.size()).is_equal(1)
	assert_str(String(model().state.relief[0].status)).is_equal("camped")
	var unused:=float(MilitaryCampaign.active_siege.relief[0].food)
	MilitaryCampaign._end_siege("Relief integration ceasefire")
	receipt=model().state.relief[0]
	assert_str(String(receipt.status)).is_equal("returning")
	donor=CivilizationSystem.civilizations[0]
	assert_float(float(donor.military_population)).is_less(military)
	GameState.elapsed_days=int(receipt.due_day); model().advance_relief(int(GameState.elapsed_days))
	assert_array(model().state.relief).is_empty()
	assert_float(float(donor.military_population)).is_equal_approx(military,.0001)
	assert_float(float(donor.population)).is_equal(population)
	assert_int(GameState.population_total).is_equal(player_population)
	assert_float(float(donor.food_days)*population).is_equal_approx(food-float(quote.food)+unused,.001)

func test_relief_for_ended_siege_returns_without_player_camp_or_people()->void:
	var siege_id:=actual_siege()
	CivilizationSystem.civilizations[0].food_days=120
	CivilizationSystem.civilizations[0].military_readiness=.8
	assert_bool(model().dispatch_relief(id(),"player",siege_id).get("ok",false)).is_true()
	var receipt:Dictionary=model().state.relief[0]
	MilitaryCampaign._end_siege("Ended before arrival")
	GameState.elapsed_days=int(receipt.due_day); model().advance_relief(int(GameState.elapsed_days))
	assert_str(String(receipt.status)).is_equal("returning")
	assert_dict(MilitaryCampaign.active_siege).is_empty()
