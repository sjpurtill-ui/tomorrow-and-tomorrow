extends GdUnitTestSuite
var operations:RefCounted
var base_id:int
func before_test()->void:
	GameState.reset_for_new_world(424242);SettlementModel.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(400)
	GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	operations=MilitaryCampaign.joint_operations
	GameState.known_discoveries.append("aerostat_observation");GameState.discovery_adoption["aerostat_observation"]=1.0
	for item:String in ["Timber","Stone","Iron Ore"]:GameState.resource_stockpiles[item]=1000.0
	assert_bool(operations.build_base(String(GameState.player_settlements[0].id),"air").has("ok")).is_true()
	base_id=int(operations.state.bases[0].id)
	operations.state.bases[0].construction_work=30.0
	MilitaryCampaign.military_inventory["observation_balloon_equipment"]=2

func test_commission_uses_real_equipment_and_population_then_disband_returns_it()->void:
	var people:=GameState.population_total
	var before:=MilitaryCampaign._mobilized_count()
	var receipt:Dictionary=operations.commission(base_id,"observation_balloon",2)
	assert_bool(receipt.has("ok")).is_true()
	assert_int(MilitaryCampaign.military_inventory.observation_balloon_equipment).is_equal(0)
	assert_int(MilitaryCampaign._mobilized_count()-before).is_equal(6)
	assert_int(MilitaryCampaign.personnel_ledger().naval_air).is_equal(6)
	assert_int(MilitaryCampaign.population_commitment_snapshot().total).is_equal(MilitaryCampaign._mobilized_count())
	assert_float(float(GameState.population_total)).is_equal(float(people))
	assert_bool(operations.disband(receipt.id).has("ok")).is_true()
	assert_int(MilitaryCampaign.military_inventory.observation_balloon_equipment).is_equal(2)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(before)

func test_missing_gear_and_locked_aircraft_do_not_allocate_crews()->void:
	var before:Dictionary=operations.export_state()
	assert_bool(operations.commission(base_id,"observation_balloon",3).has("error")).is_true()
	assert_bool(operations.commission(base_id,"jet_fighter",1).has("error")).is_true()
	assert_dict(operations.export_state()).is_equal(before)

func test_invalid_mission_and_out_of_range_orders_are_rejected()->void:
	var receipt:Dictionary=operations.commission(base_id,"observation_balloon",1)
	var region:Dictionary=operations.region_at(Vector2(10000,10000),"air")
	assert_bool(operations.assign(receipt.id,region,"strategic_bombing").has("error")).is_true()
	assert_bool(operations.assign(receipt.id,region,"reconnaissance").has("error")).is_true()
	assert_str(operations.force(receipt.id).mission).is_equal("hold")

func test_joint_save_round_trip_and_corruption_rejection_are_transactional()->void:
	operations.commission(base_id,"observation_balloon",1)
	var before:Dictionary=operations.export_state()
	assert_str(operations.validate(before)).is_empty()
	operations.reset();operations.import_state(before)
	assert_dict(operations.export_state()).is_equal(before)
	var saved:=MilitaryCampaign.export_state()
	saved.joint_operations.forces[0].base_id=9999
	assert_bool(MilitaryCampaign.import_state(saved).has("error")).is_true()
	assert_dict(operations.export_state()).is_equal(before)
	saved.joint_operations=before.duplicate(true);saved.joint_operations.forces[0].units={"invalid":1}
	assert_bool(MilitaryCampaign.import_state(saved).has("error")).is_true()
	assert_dict(operations.export_state()).is_equal(before)
	operations.import_state({})
	assert_int(operations.personnel()).is_equal(0)
	assert_bool(operations.state.has("next_id")).is_true()

func test_training_daily_clock_does_not_repeat_same_day()->void:
	GameState.food_stocks={"Preserved food":10000.0}
	GameState.resource_stockpiles["Fiber Plants"]=1000.0
	GameState.resource_stockpiles["Bitumen"]=1000.0
	var receipt:Dictionary=operations.commission(base_id,"observation_balloon",1)
	operations.advance(1)
	var trained:=float(operations.force(receipt.id).training)
	assert_float(trained).is_greater(0)
	operations.advance(1)
	assert_float(float(operations.force(receipt.id).training)).is_equal(trained)
