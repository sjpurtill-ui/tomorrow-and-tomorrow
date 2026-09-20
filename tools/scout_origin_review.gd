extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var state=root.get_node("GameState");var world=root.get_node("CivilizationSystem");var settlements=root.get_node("SettlementModel")
	state.reset_for_new_world(89121);world.initialize()
	state.population_exact=1000.0;state.population_total=1000
	state.population_cohorts.clear();state.initialize_population_model()
	state.player_settlements.assign([
		{"id":"home","name":"Large town","primary":true,"position":Vector2.ZERO},
		{"id":"small","name":"Small hamlet","primary":false,"position":Vector2(5,5),"population_share":.04}])
	var staff=world.scouting_staff
	staff.set_policy(.1,"exploration");staff.set_origin("small")
	var national_before:float=state.population_exact
	var pool:Dictionary=world.scout_origin_staffing("small")
	assert(is_equal_approx(float(pool.population),40.0) and pool.adults>12 and pool.available<=12)
	assert(staff.snapshot().target==4)
	world.scout_missions.append({"mission_id":1,"personnel":30,"origin_city_id":"home"})
	assert(staff.snapshot().away==0 and staff.snapshot().target==4)
	world.scout_missions.append({"mission_id":2,"personnel":4,"origin_city_id":"small"})
	assert(staff.snapshot().away==4 and world.scout_origin_staffing("small").available<=8)
	world.scout_missions.clear()
	world.scout_land_authority=func(_position:Vector2)->bool:return true
	var quote:Dictionary=world.scout_mission_quote(30,"open_world","north",40,false,"small")
	assert(not quote.can_dispatch and "Small hamlet" in quote.blocker)
	var before_count:int=world.scout_missions.size()
	assert(world.dispatch_scouts(30,"open_world","north",40,false,"small").has("error"))
	assert(world.scout_missions.size()==before_count and state.population_exact==national_before)
	staff.set_origin("home");assert(staff.snapshot().target==96)
	# Provisions must be taken from the same settlement as the party.
	var food=root.get_node("FoodSystem")
	var home_food:float=food.total_stored()
	settlements.with_city_resources("small",func()->void:state.food_stocks={"Dry staples":2000.0})
	var local_food:float=settlements.with_city_resources("small",func()->float:return food.total_stored())
	var departure:Dictionary=world.dispatch_scouts(30,"open_world","north",4,false,"small")
	assert(departure.get("ok",false))
	var issued:float=world.scout_missions[-1].provisions
	assert(issued>0 and is_equal_approx(food.total_stored(),home_food))
	assert(is_equal_approx(float(settlements.with_city_resources("small",func()->float:return food.total_stored())),local_food-issued))
	print("SCOUT_LOCAL_TARGET_COMMITMENTS_DISPATCH_FOOD_OK")
	quit()
