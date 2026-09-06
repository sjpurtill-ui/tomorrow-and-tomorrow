extends GdUnitTestSuite

func before_test()->void:
	GameState.reset_for_new_world(551188);CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();GameState.civic_api_enabled=false
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	var force:Dictionary=MilitaryCampaign.simulator.create_formation_force("Test army",[{"unit":"line_infantry","weapon":"spear","count":240,"equipment":240,"training":.7}],.9,.85)
	force.merge({"army_id":1,"general_managed":true,"position":{"x":0.0,"z":0.0},"status":"stationed","location_id":"player_home","supply_level":1.0,"runner_count":1})
	MilitaryCampaign.field_armies=[force]
	GeneralCampaign.active=true
	GeneralCampaign.state={"seed":42,"army_id":1,"cell":Vector2i.ZERO,"origin":Vector2.ZERO,"general_name":"General","character":{"care":.8,"loyalty":.6,"ambition":.48,"resentment":.0},"food":2150.4,"exhaustion":0.0,"proposal":{},"mission":{},"outcome":"","turn":0,"status":"deliberating","treatment":[],"reports":[],"messages":[],"losses":0,"rivals":[{"id":"one","name":"Bracken Hold","cell":Vector2i(5,0),"home":Vector2i(5,0),"force":force.duplicate(true),"food":2150.4,"reserve_food":0.0,"control":"rival","plan":"hold","seen":{},"last_signature":"","adaptations":0,"model_events":0}],"seen":{"one":{"home":Vector2i(5,0),"cell":Vector2i(5,0),"name":"Bracken Hold","troops":240,"day":0}},"events":[]}
	GeneralCampaign._build_grid()

func after_test()->void:
	GeneralCampaign.reset_for_new_world();CivilizationSystem.set_scout_geography_authority(Callable())

func test_questions_and_hypotheticals_never_become_local_orders()->void:
	for text in ["Could we attack Bracken Hold?","What if we attack Bracken Hold?","Do not attack Bracken Hold","They said attack Bracken Hold","Why did you withdraw?"]:
		assert_str(GeneralDialogue.local_order(text).action).is_equal("discuss")
	assert_str(GeneralDialogue.local_order("attack Bracken Hold").action).is_equal("attack")

func test_unknown_and_unsupported_are_distinct_from_refusal()->void:
	assert_str(GeneralCampaign.validate_order({"action":"attack","target":"secret"}).kind).is_equal("impossible")
	assert_str(GeneralCampaign.validate_order({"action":"teleport"}).kind).is_equal("unsupported")

func test_speaking_and_proposing_do_not_advance_or_move()->void:
	var day:=GameState.elapsed_days
	assert_bool(GeneralCampaign.propose({"action":"attack","target":"one"}).has("ok")).is_true()
	assert_float(GameState.elapsed_days).is_equal(day)
	assert_bool(GeneralCampaign.resolving).is_false()
	assert_bool(GeneralCampaign.state.cell==Vector2i.ZERO).is_true()

func test_short_supplies_prompt_objection_and_explicit_override_can_be_refused()->void:
	GeneralCampaign.state.food=1
	GeneralCampaign.propose({"action":"attack","target":"one"})
	assert_str(GeneralCampaign.commit_proposal().kind).is_equal("objection")
	assert_str(GeneralCampaign.commit_proposal(true).kind).is_equal("refusal")
	assert_bool(GeneralCampaign.resolving).is_false()
	assert_bool(GeneralCampaign.state.cell==Vector2i.ZERO).is_true()

func test_different_character_can_obey_same_costly_override()->void:
	GeneralCampaign.state.food=1
	GeneralCampaign.state.character={"care":.2,"loyalty":.9,"ambition":.8,"resentment":0}
	GeneralCampaign.propose({"action":"attack","target":"one"})
	assert_bool(GeneralCampaign.commit_proposal(true).has("ok")).is_true()
	assert_bool(GeneralCampaign.resolving).is_true()
	assert_bool(GeneralCampaign.state.cell==Vector2i.ZERO).is_true()

func test_hidden_grid_routes_around_water_and_rejects_disconnected_destination()->void:
	CivilizationSystem.set_scout_geography_authority(func(p:Vector2)->bool:return not(p.x>3 and p.x<7 and absf(p.y)<3))
	GeneralCampaign._build_grid()
	var path:=GeneralCampaign.route(Vector2i.ZERO,Vector2i(5,0))
	assert_int(path.size()).is_greater(5)
	for c in path:assert_bool(CivilizationSystem._scout_land_at(GeneralCampaign.world_position(c))).is_true()
	GeneralCampaign.cells.erase(Vector2i(5,0))
	assert_array(GeneralCampaign.route(Vector2i.ZERO,Vector2i(5,0))).is_empty()

func test_time_budget_is_exact_and_pause_preserves_committed_step()->void:
	GeneralCampaign.propose({"action":"defend","target":"home"});GeneralCampaign.commit_proposal()
	assert_float(GeneralCampaign.consume_time(1)).is_equal(.5)
	GeneralCampaign.pause_to_speak()
	assert_float(GeneralCampaign.consume_time(500)).is_equal(0.0)
	GeneralCampaign.resume()
	assert_float(GeneralCampaign.consume_time(500)).is_equal(.5)

func test_no_enemy_position_leak_into_general_context()->void:
	GeneralCampaign.state.authority="oath";GeneralCampaign.state.war="test"
	GeneralCampaign.state.rivals[0].cell=Vector2i(15,15)
	assert_bool(GeneralCampaign.public_context().known_rivals[0].cell==Vector2i(5,0)).is_true()

func test_legacy_direct_order_cannot_override_general_mission()->void:
	assert_str(MilitaryCampaign.move_field_army_to_position(1,10,0).error).contains("general")

func test_bad_model_contract_does_not_change_proposal()->void:
	assert_bool(GeneralDialogue._accept({"reply":"Done","action":"destroy_everything","target":"one"})).is_false()
	assert_dict(GeneralCampaign.state.proposal).is_empty()

func test_new_order_during_pause_preserves_committed_leg_then_replaces_mission()->void:
	GeneralCampaign.propose({"action":"attack","target":"one"});GeneralCampaign.commit_proposal()
	GeneralCampaign.consume_time(.5);GeneralCampaign.pause_to_speak()
	var remaining:=GeneralCampaign.budget
	GeneralCampaign.propose({"action":"withdraw","target":"home"})
	assert_bool(GeneralCampaign.commit_proposal().has("ok")).is_true()
	assert_str(GeneralCampaign.state.next_mission.action).is_equal("withdraw")
	assert_float(GeneralCampaign.budget).is_equal(remaining)
	assert_str(GeneralCampaign.state.mission.action).is_equal("attack")

func test_model_misclassifying_question_cannot_commit_an_attack()->void:
	GeneralCampaign.state.messages.append({"role":"user","content":"What would attacking cost?"})
	GeneralDialogue._accept({"reply":"It would be costly.","action":"attack","target":"one"})
	assert_dict(GeneralCampaign.state.proposal).is_empty()
	assert_bool(GeneralCampaign.resolving).is_false()

func test_saved_partial_commitment_resumes_without_free_time_or_teleport()->void:
	var second:Dictionary=GeneralCampaign.state.rivals[0].duplicate(true);second.id="two";GeneralCampaign.state.rivals.append(second)
	GeneralCampaign.propose({"action":"attack","target":"one"});GeneralCampaign.commit_proposal();GeneralCampaign.consume_time(.5)
	var remaining:=GeneralCampaign.budget
	var saved:=GeneralCampaign.export_state()
	assert_bool(GeneralCampaign.import_state(saved).has("ok")).is_true()
	assert_bool(GeneralCampaign.resolving).is_true()
	assert_float(GeneralCampaign.budget).is_equal(remaining)
	assert_str(GeneralCampaign.state.status).is_equal("paused during execution")
	assert_bool(GeneralCampaign.state.cell==Vector2i.ZERO).is_true()

func test_prepaid_force_is_excluded_from_home_food_and_free_delivery()->void:
	GameState.population_exact=1200;GameState.population_total=1200;GameState.population_cohorts.clear();GameState.initialize_population_model()
	var prepaid:Dictionary=FoodSystem._calculate_aggregate_demand(false)
	assert_float(float(prepaid.army_field)).is_equal(0.0)
	GeneralCampaign.army().supply_level=.1
	MilitaryCampaign.record_daily_provisions(50,50)
	assert_float(float(GeneralCampaign.army().supply_level)).is_equal(.1)
	GeneralCampaign.active=false
	var ordinary:Dictionary=FoodSystem._calculate_aggregate_demand(false)
	assert_float(float(ordinary.total)).is_greater(float(prepaid.total))

func test_difficulty_adaptation_uses_observation_not_hidden_location()->void:
	var r:Dictionary=GeneralCampaign.state.rivals[0]
	GeneralCampaign.state.turn=1;GeneralCampaign.difficulty="easy"
	GeneralCampaign._rival_decision(r,1)
	assert_int(r.adaptations).is_equal(0)
	GeneralCampaign.difficulty="hard"
	GeneralCampaign._rival_decision(r,1)
	assert_int(r.adaptations).is_equal(1)
	assert_str(r.plan).is_equal("pressure")
	r.seen={"cell":Vector2i(1,1),"troops":60,"day":0}
	GeneralCampaign._rival_decision(r,1)
	assert_str(r.plan).is_equal("intercept")
	assert_int(GeneralDialogue.usage.size()).is_equal(0)
