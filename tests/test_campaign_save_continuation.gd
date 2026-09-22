extends GdUnitTestSuite
const DAY=preload("res://scripts/civilization_day.gd")

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()

func test_whole_game_load_preserves_research_and_opponent_next_day()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(9241)
	MilitaryCampaign.reset_for_new_world()
	GameState.opponent_count=3
	CivilizationSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
	WorldSimulation.context_provider=func(_point:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.start_world()
	for day in range(1,4):WorldSimulation.advance_day(day,DAY.context(Vector2.ZERO))
	var result:=preload("res://tools/verify_campaign_save.gd").verify(Vector2.ZERO,func()->void:pass)
	assert_bool(result.get("restored_equal",false)).override_failure_message(str(result.get("restore_detail",result))).is_true()
	assert_bool(result.get("continuation_equal",false)).override_failure_message(str(result.get("continuation_detail",result))).is_true()

func test_explicit_empty_army_templates_survive_import()->void:
	MilitaryCampaign.reset_for_new_world()
	MilitaryCampaign.army_templates.clear()
	var saved:=MilitaryCampaign.export_state()
	assert_array(saved.army_templates).is_empty()
	assert_bool(MilitaryCampaign.import_state(saved).get("ok",false)).is_true()
	assert_array(MilitaryCampaign.army_templates).is_empty()

func test_legacy_human_view_rebuild()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(9241)
	GameState.opponent_count=2
	CivilizationSystem.reset_for_new_world()
	WorldSimulation.start_world()
	var saved:=WorldSimulation.export_state()
	saved.erase("human_projection")
	assert_bool(WorldSimulation.import_state(saved).get("ok",false)).is_true()
	assert_bool(WorldSimulation.human_projection.is_empty()).is_false()
	WorldSimulation.refresh_views()
	for actor:Dictionary in WorldSimulation.actors.values():
		var found:=false
		for civ:Dictionary in actor.systems.CivilizationSystem.civilizations:
			if civ.id=="human":found=true
		assert_bool(found).is_true()

func test_explicit_empty_observer_view_survives_owned_import()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(9241)
	WorldSimulation.create_actor("isolated",9241,Vector2.ZERO)
	WorldSimulation.enabled=true
	WorldSimulation.scoped("isolated",func()->void:DAY.advance(1,DAY.context(Vector2.ZERO)))
	var saved:=WorldSimulation.export_state()
	assert_dict(saved.human_projection).is_empty()
	assert_bool(WorldSimulation.import_state(saved).get("ok",false)).is_true()
	assert_dict(WorldSimulation.human_projection).is_empty()
	var restored:=WorldSimulation.export_state()
	assert_bool(restored==saved).override_failure_message(str(preload("res://tools/verify_campaign_save.gd").details(saved,restored))).is_true()
