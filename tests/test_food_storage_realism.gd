extends GdUnitTestSuite
const Model=preload("res://scripts/food_storage_model.gd")
const Care=preload("res://scripts/food_care.gd")
const Stores=preload("res://scripts/storage_works.gd")
const Build=preload("res://scripts/settlement_construction.gd")

func before_test()->void:
	WorldSimulation.clear()
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]:node.set_process(false)
	_configure()
func after_test()->void:
	WorldSimulation.span=1;WorldSimulation.clear()
func _configure()->void:
	var s=WorldSimulation.state
	s.reset_for_new_world(6409);s.ensure_population_total(100)
	WorldSimulation.discovery.reset_for_new_world();WorldSimulation.discovery.initialize()
	WorldSimulation.food.reset_for_new_world()
	s.known_discoveries.clear();s.discovery_adoption={};s.elapsed_days=120
	s.settlement_site_committed=true;s.convoy_traveling=false;s.resource_settlement_id=""
	s.settlement_completed.assign(["Hearth Circle","Storage Pits"])
	s.population_allocations.merge({"Administration":2,"Construction":20,"Logistics":0},true)
	s.food_stocks={"Fresh food":1000.0,"Stored food":50000.0}
	s.resource_stockpiles={};s.storage_works={};s.leadership_positions={}
func test_reserve_estimate_counts_rot_and_matches_daily_consumption()->void:
	var estimated:=Model.reserve_days(0,50000,100,.04,.003)
	var held:=50000.0;var full_days:=0
	while held>0:
		held*=.997
		if held<100:break
		held-=100;full_days+=1
	assert_float(estimated).is_less(350.)
	assert_float(estimated).is_greater(float(full_days)-1)
	assert_float(estimated).is_less(float(full_days)+1)
	assert_float(Model.reserve_days(200,300,100,0,0)).is_equal_approx(5.,.000001)
	assert_float(Model.reserve_days(200,300,0,.1,.01)).is_equal(-1.)
func test_fresh_reserve_spoils_while_consuming_and_stored_reserve_ages()->void:
	var all_stored:=Model.reserve_days(0,1000,10,.1,.001)
	var mixed:=Model.reserve_days(500,500,10,.1,.001)
	assert_float(mixed).is_less(all_stored)
	assert_float(mixed).is_greater(0.)
func test_climate_and_store_workload_change_losses_without_a_stock_cap()->void:
	assert_float(Model.climate_factor(30,.9)).is_greater(Model.climate_factor(5,.1)*2)
	assert_float(Care.keep_cover(2,100,3000)).is_equal(1.)
	assert_float(Care.keep_cover(2,100,50000)).is_less(.1)
	var crowded:=float(WorldSimulation.food._spoilage_rates(false)[1])
	GameState.food_stocks["Stored food"]=3000.0
	assert_float(float(WorldSimulation.food._spoilage_rates(false)[1])).is_less(crowded)
func test_more_capacity_does_not_preserve_food_or_change_reserve_estimate()->void:
	var before:=WorldSimulation.food._spoilage_rates(false)
	var reserve:=WorldSimulation.food.reserve_estimate(100)
	GameState.storage_works={"capacity":{"food":500000.0}}
	assert_array(WorldSimulation.food._spoilage_rates(false)).is_equal(before)
	assert_dict(WorldSimulation.food.reserve_estimate(100)).is_equal(reserve)
	assert_dict(WorldSimulation.food._apply_storage_capacity()).is_empty()
func test_same_daily_losses_and_reserve_rules_for_player_and_opponent()->void:
	var player:=_reading()
	WorldSimulation.create_actor("food_parity",6409)
	var opponent:Dictionary=WorldSimulation.scoped("food_parity",func()->Dictionary:_configure();return _reading())
	assert_dict(opponent).is_equal(player)
	assert_float(float(GameState.food_stocks["Stored food"])).is_equal(float(player.remaining))
func _reading()->Dictionary:
	var food=WorldSimulation.food
	var estimate:Dictionary=food.reserve_estimate(100)
	var lost:Dictionary=food._spoil(false)
	return {"estimate":estimate,"lost":lost,"remaining":WorldSimulation.state.food_stocks["Stored food"]}
func test_batched_opponent_loss_still_accounts_for_each_day()->void:
	GameState.population_allocations.Administration=0
	GameState.food_stocks={"Fresh food":1000.0,"Stored food":50000.0}
	for i in 5:WorldSimulation.food._spoil(false)
	var daily:=GameState.food_stocks.duplicate()
	GameState.food_stocks={"Fresh food":1000.0,"Stored food":50000.0};WorldSimulation.span=5
	WorldSimulation.food._spoil(false);WorldSimulation.span=1
	for key:String in daily:assert_float(float(GameState.food_stocks[key])).is_equal_approx(float(daily[key]),.00001)
func test_player_and_opponent_expansion_pay_the_same_material_bill()->void:
	var player:=_expand()
	WorldSimulation.create_actor("storage_parity",6409)
	var opponent:Dictionary=WorldSimulation.scoped("storage_parity",func()->Dictionary:_configure();return _expand())
	assert_dict(opponent).is_equal(player)
	assert_float(float(player.capacity)).is_greater(0.)
	for amount:float in player.left.values():assert_float(amount).is_zero()
func _expand()->Dictionary:
	var p:Dictionary={}
	for candidate:Dictionary in Stores.projects():
		if candidate.storage_kind=="food":p=candidate;break
	var state=WorldSimulation.state
	state.resource_stockpiles=p.materials.duplicate(true)
	Stores.queue("food");state.settlement_projects[p.name]=float(p.days)
	var events:=Build.process_day()
	assert_int(events.size()).is_equal(1)
	return {"capacity":Stores.added("food"),"bill":p.materials,"work":p.days,"left":state.resource_stockpiles.duplicate(true)}
