extends GdUnitTestSuite

func before_test()->void:
	GameState.reset_for_new_world(551188);CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.set_scout_geography_authority(func(point:Vector2)->bool:return not(point.x>4 and point.x<6 and absf(point.y)<3))
	CivilizationSystem.revealed_areas=[{"x":0.0,"z":0.0,"radius":100.0}]
	MilitaryCampaign.field_armies=[{"army_id":1,"name":"Test Army","troops":10,"runner_count":1,"position":{"x":0.0,"z":0.0},"location_id":"player_home","status":"stationed","supply_level":1.0,"formations":[{"unit":"levy","weapon":"improvised","count":10,"training":.5,"personnel_condition":1.0}],"city_operation":{"test":"preserve on rejection"}}]

func after_test()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())

func test_dry_destination_across_water_is_rejected_without_mutating_order()->void:
	var before:=MilitaryCampaign.field_armies.duplicate(true)
	var result:=MilitaryCampaign.move_field_army_to_position(1,10,0)
	assert_str(String(result.error)).contains("Water blocks")
	assert_array(MilitaryCampaign.field_armies).is_equal(before)
	assert_bool(MilitaryCampaign.move_field_army_to_position(1,0,10).has("ok")).is_true()
	assert_dict(MilitaryCampaign.field_armies[0].position).is_equal(before[0].position)

func test_route_obstruction_stops_before_water_and_sends_report()->void:
	CivilizationSystem.set_scout_geography_authority(func(_point:Vector2)->bool:return true)
	assert_bool(MilitaryCampaign.move_field_army_to_position(1,10,0).has("ok")).is_true()
	CivilizationSystem.set_scout_geography_authority(func(point:Vector2)->bool:return not(point.x>4 and point.x<6))
	MilitaryCampaign._process_field_army_movement_day()
	assert_str(MilitaryCampaign.field_armies[0].status).is_equal("stationed")
	assert_float(float(MilitaryCampaign.field_armies[0].position.x)).is_equal(0.0)
	assert_str(MilitaryCampaign.field_armies[0].movement_block_reason).contains("Water blocks")
	assert_int(MilitaryCampaign.runner_messages.size()).is_greater(0)

func test_supply_shortfall_slows_real_march_and_resupply_restores_pace()->void:
	var full:=MilitaryCampaign._field_army_speed(MilitaryCampaign.field_armies[0])
	for day in 20:MilitaryCampaign.record_daily_provisions(100,0)
	var slow:=MilitaryCampaign._field_army_speed(MilitaryCampaign.field_armies[0])
	assert_float(slow).is_less(full)
	var order:=MilitaryCampaign.move_field_army_to_position(1,0,10)
	assert_str(String(order.message)).contains("march is slowed")
	for day in 25:MilitaryCampaign.record_daily_provisions(100,100)
	assert_float(MilitaryCampaign._field_army_speed(MilitaryCampaign.field_armies[0])).is_greater(slow)
