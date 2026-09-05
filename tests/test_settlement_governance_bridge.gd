extends GdUnitTestSuite


func before_test()->void:
	GameState.reset_for_new_world(716203)
	GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.ensure_population_total(1000)
	GameState.settlement_name="Keansburg"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(14.0,0.0,-9.0)
	GameState.food_stocks={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":5000.0,"Preserved food":1000.0}
	GameState.resource_stockpiles={"Food":6000.0,"Timber":500.0,"Fiber Plants":500.0}
	CivilizationSystem.register_player_origin(Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z))
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()


func test_named_convoy_becomes_a_selectable_managed_settlement()->void:
	var destination:=Vector2(GameState.settlement_founded_at.x+8.0,GameState.settlement_founded_at.z)
	var started:=SettlementModel.begin_settlement_convoy(destination,1.0,"Rivermeet")
	assert_bool(bool(started.ok)).is_true()
	assert_str(String(GameState.settlement_convoy.settlement_name)).is_equal("Rivermeet")
	GameState.elapsed_days=float(GameState.settlement_convoy.arrival_day)
	SettlementModel.update_settlement_convoy(destination,1.0)
	var completed:=SettlementModel.complete_settlement_convoy(destination)
	assert_bool(bool(completed.ok)).is_true()
	var new_id:=String((completed.settlement as Dictionary).id)
	assert_bool(bool(SettlementModel.select_settlement(new_id).ok)).is_true()
	assert_str(String(SettlementModel.selected_settlement_snapshot().name)).is_equal("Rivermeet")
	GovernmentPeopleSystem.process_day(int(GameState.elapsed_days)+30)
	assert_str(String(GovernmentPeopleSystem.settlement_leader(new_id).name)).is_not_empty()
	assert_bool(bool(GovernmentPeopleSystem.set_settlement_focus(new_id,"development").ok)).is_true()
	assert_str(String(GovernmentPeopleSystem.settlement_management(new_id).focus)).is_equal("development")
	assert_bool(bool(SettlementModel.rename_settlement(new_id,"Riverwatch").ok)).is_true()
	assert_str(String(SettlementModel.selected_settlement_snapshot().name)).is_equal("Riverwatch")
