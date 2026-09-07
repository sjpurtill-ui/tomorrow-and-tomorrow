extends GdUnitTestSuite
const POLICY:=preload("res://scripts/raid_policy.gd")
const MAP:=preload("res://scripts/local_terrain.gd")

func test_raids_need_a_real_party_and_a_plausible_observed_target() -> void:
	assert_bool(POLICY.worthwhile(3,1,0)).is_false()
	assert_bool(POLICY.worthwhile(8,.7,40)).is_false()
	assert_bool(POLICY.worthwhile(12,.8,8)).is_true()
	assert_bool(POLICY.worthwhile(12,.2,8)).is_false()

func test_only_outmatched_small_home_raids_are_routine() -> void:
	var threat:Dictionary={"incident_kind":"raid","estimated_strength":6,"enemy_force":{"readiness":.5}}
	assert_bool(POLICY.routine(threat,{"troops":30,"readiness":.6})).is_true()
	assert_bool(POLICY.routine(threat,{"troops":3,"readiness":.1})).is_false()
	threat.estimated_strength=100
	assert_bool(POLICY.routine(threat,{"troops":1000,"readiness":1})).is_false()
	threat.estimated_strength=6;threat.campaign_mode="offensive"
	assert_bool(POLICY.routine(threat,{"troops":30,"readiness":.6})).is_false()
	threat.campaign_mode="defensive";threat.target_region_id="occupied_city"
	assert_bool(POLICY.routine(threat,{"troops":30,"readiness":.6})).is_false()

func test_routine_notifications_do_not_pause_or_request_battle_view() -> void:
	var renderer:Node3D=auto_free(MAP.new())
	renderer.game_speed=3.0
	var threat:Dictionary={"routine_raid":true,"incident_kind":"raid"}
	renderer._on_military_threat_attention(threat)
	renderer._on_city_battle_started({"threat":threat})
	renderer._on_battle_attention({"threat":threat})
	assert_float(renderer.game_speed).is_equal(3.0)
	assert_bool(MilitaryCampaign.active_engagement.get("awaiting_player_view",false)).is_false()

func test_routine_raid_starts_without_visual_gate_and_advances_in_the_calendar() -> void:
	GameState.reset_for_new_world(4219);GameState.initialize_population_model()
	MilitaryCampaign.reset_for_new_world()
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Local watch",[{"id":1,"unit":"line_infantry","weapon":"spear","count":60,"equipment":60,"training":.8}],1,1)
	var renderer:Node3D=auto_free(MAP.new());renderer.game_speed=3.0
	MilitaryCampaign.battle_started.connect(renderer._on_city_battle_started)
	MilitaryCampaign._create_civilization_threat({"id":"routine_test","incident_kind":"raid","strength":6,"source_name":"Raiders","readiness":.4},"defensive")
	assert_bool(MilitaryCampaign.active_threat.get("routine_raid",false)).is_true()
	var started:Dictionary=MilitaryCampaign.respond_to_threat("defend")
	assert_bool(started.has("error")).is_false()
	assert_bool(MilitaryCampaign.active_engagement.get("awaiting_player_view",false)).is_false()
	var before:=MilitaryCampaign.battle_history.size()
	for day in 32:
		MilitaryCampaign._process_threat_day()
		if MilitaryCampaign.active_engagement.is_empty():break
	assert_bool(MilitaryCampaign.active_engagement.is_empty()).is_true()
	assert_int(MilitaryCampaign.battle_history.size()).is_greater(before)
	assert_float(renderer.game_speed).is_equal(3.0)
	MilitaryCampaign.battle_started.disconnect(renderer._on_city_battle_started)
	MilitaryCampaign.reset_for_new_world()
