extends "res://tests/focused_journey_probe.gd"
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_FocusedJourney_Test"))
	GameState.reset_for_new_world(551188);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();ProgressionSystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();ConsequenceEngine.reset_for_new_world();CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.select_founding_focus("provision");PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	terrain=preload("res://local_terrain.tscn").instantiate();add_child(terrain);terrain._set_game_speed(0);await frames();hud=terrain.hud
	get_window().content_scale_size=Vector2i.ZERO;get_window().size=Vector2i(1280,900);await frames()
	for size in [Vector2i(1280,900),Vector2i(800,600)]:
		get_window().size=size;await frames()
		hud.open_dock("inquiry",0);await capture("inquiry-%d"%size.x)
		await click_label("KNOWLEDGE & SOCIETY");await capture("inquiry-directions-%d"%size.x)
		await click_label("Security");await capture("inquiry-security-%d"%size.x)
		var weight:=int(GameState.research_allocations.security)
		var people:=GameState.population_total
		var known:=GameState.known_discoveries.duplicate()
		await click_label("MORE ATTENTION")
		assert(int(GameState.research_allocations.security)==weight+1)
		assert(GameState.population_total==people and GameState.known_discoveries==known)
		await click_label("LESS ATTENTION");assert(int(GameState.research_allocations.security)==weight)
		await click_label("CURRENT INVESTIGATIONS");await capture("inquiry-evidence-%d"%size.x)
		await click_control(hud.detail_dock.close_button)
		await click_label("RESEARCH WORK");await click_label("PRIORITIZE RESEARCH")
		var id:=SettlementModel._primary_settlement_id()
		assert(String(SettlementModel.settlement_record(id).management_focus)=="research")
		assert(not bool(SettlementModel.settlement_record(id).auto_manage))
		await capture("inquiry-work-%d"%size.x)
		await click_label("DELEGATE PRIORITY");assert(bool(SettlementModel.settlement_record(id).auto_manage))
		assert(GameState.population_total==people and GameState.known_discoveries==known)
	print("INQUIRY_JOURNEY_PASS two sizes, meaningful direction, actual priority changes and delegation, no invented knowledge or people")
	get_tree().quit()
