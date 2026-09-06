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

func test_ammunition_and_cart_quotes_reserve_only_on_order()->void:
	for id:String in ["bow_craft","joinery"]:GameState.known_discoveries.append(id);GameState.discovery_adoption[id]=1.0
	GameState.resource_stockpiles["Fiber Plants"]=100.0;GameState.resource_stockpiles.Stone=100.0
	var before:=GameState.resource_stockpiles.duplicate(true)
	assert_bool(MilitaryCampaign.consumable_production_quote("arrows",5).has("ok")).is_true()
	assert_bool(MilitaryCampaign.transport_cart_quote(1).has("ok")).is_true()
	assert_dict(GameState.resource_stockpiles).is_equal(before)
	var ammo:=MilitaryCampaign.queue_consumable_production("arrows",5)
	assert_int(int(ammo.get("queued",0))).is_equal(5)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(99.6,.0001)
	MilitaryCampaign.cancel_equipment_job(int(ammo.id))
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(100,.0001)
	var carts:=MilitaryCampaign.queue_transport_cart_production(1)
	assert_int(int(carts.get("queued",0))).is_equal(1)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(92,.0001)
	assert_float(float(GameState.resource_stockpiles["Fiber Plants"])).is_equal(98.5)
func test_repair_preview_matches_available_damaged_items_and_returns_on_cancel()->void:
	MilitaryCampaign.damaged_equipment.improvised=3
	var quote:=MilitaryCampaign.equipment_repair_quote("improvised",5)
	assert_int(int(quote.amount)).is_equal(3)
	assert_int(int(MilitaryCampaign.damaged_equipment.improvised)).is_equal(3)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(100,.0001)
	var result:=MilitaryCampaign.queue_equipment_repair("improvised",5)
	assert_int(int(result.queued)).is_equal(3)
	assert_int(int(MilitaryCampaign.damaged_equipment.improvised)).is_equal(0)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(100-.35*3*.18,.0001)
	MilitaryCampaign.cancel_equipment_job(int(result.id))
	assert_int(int(MilitaryCampaign.damaged_equipment.improvised)).is_equal(3)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(100,.0001)
func test_missing_knowledge_does_not_spend_or_queue()->void:
	assert_bool(MilitaryCampaign.queue_consumable_production("arrows",1).has("error")).is_true()
	assert_bool(MilitaryCampaign.queue_transport_cart_production(1).has("error")).is_true()
	assert_array(MilitaryCampaign.equipment_queue).is_empty()
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(100,.0001)
