extends GdUnitTestSuite
func before_test()->void:
	GameState.reset_for_new_world(7511);MilitaryCampaign.reset_for_new_world()
	GameState.resource_stockpiles["Timber"]=100.0
	MilitaryCampaign.equipment_queue.clear()
func test_preview_is_read_only_and_order_reserves_exact_materials()->void:
	var stocks:=GameState.resource_stockpiles.duplicate(true)
	var inventory:=MilitaryCampaign.military_inventory.duplicate(true)
	for n in 10:assert_bool(MilitaryCampaign.equipment_production_quote("improvised",5).has("ok")).is_true()
	assert_dict(GameState.resource_stockpiles).is_equal(stocks)
	assert_array(MilitaryCampaign.equipment_queue).is_empty()
	var result:=MilitaryCampaign.queue_equipment_production("improvised",5)
	assert_int(int(result.get("queued",0))).is_equal(5)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(98.25)
	assert_dict(MilitaryCampaign.military_inventory).is_equal(inventory)
	assert_int(MilitaryCampaign.equipment_queue.size()).is_equal(1)
func test_shortage_and_invalid_orders_leave_state_unchanged()->void:
	GameState.resource_stockpiles.Timber=0.0
	var stocks:=GameState.resource_stockpiles.duplicate(true)
	for request in [["improvised",5],["improvised",0],["unknown",5]]:
		assert_bool(MilitaryCampaign.queue_equipment_production(request[0],request[1]).has("error")).is_true()
	assert_dict(GameState.resource_stockpiles).is_equal(stocks)
	assert_array(MilitaryCampaign.equipment_queue).is_empty()
func test_full_workshop_rechecks_capacity_before_reserving()->void:
	for n in MilitaryCampaign.production_line_capacity():
		assert_int(int(MilitaryCampaign.queue_equipment_production("improvised",1).get("queued",0))).is_equal(1)
	var stocks:=GameState.resource_stockpiles.duplicate(true)
	assert_bool(MilitaryCampaign.equipment_production_quote("improvised",1).has("error")).is_true()
	assert_bool(MilitaryCampaign.queue_equipment_production("improvised",1).has("error")).is_true()
	assert_dict(GameState.resource_stockpiles).is_equal(stocks)
