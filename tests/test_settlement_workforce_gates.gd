extends GdUnitTestSuite
func before_test()->void:
	GameState.reset_for_new_world(424242);SettlementModel.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(2000)
	GameState.settlement_completed=["Hearth Circle","Open Work Area"]
	SettlementModel.ensure_founded()
	GameState.known_discoveries.append("aerostat_observation");GameState.discovery_adoption.aerostat_observation=1.0
	GameState.population_allocations.Construction=5
	GameState.population_allocations.Crafting=18
	for item:String in ["Timber","Stone","Iron Ore","Fiber Plants"]:GameState.resource_stockpiles[item]=1000.0
	assert_bool(MilitaryCampaign.joint_operations.build_base(String(GameState.player_settlements[0].id),"air").has("ok")).is_true()

func test_household_start_waits_for_reserved_builders_then_resumes()->void:
	assert_float(GameState.effective_workers("Construction")).is_equal(3.75)
	var stores:=GameState.resource_stockpiles.duplicate(true)
	var plots:=GameState.settlement_plots.duplicate(true)
	var events:Array[Dictionary]=[]
	assert_bool(SettlementModel._attempt_household_growth(120,events)).is_false()
	assert_dict(GameState.resource_stockpiles).is_equal(stores)
	assert_array(GameState.settlement_plots).is_equal(plots)
	var base:Dictionary=MilitaryCampaign.joint_operations.state.bases[0]
	base.construction_work=base.required_work
	assert_float(GameState.effective_workers("Construction")).is_equal(5.0)
	assert_bool(SettlementModel._attempt_household_growth(150,events)).is_true()

func test_workshop_start_uses_same_civilian_capacity_as_progress()->void:
	var stores:=GameState.resource_stockpiles.duplicate(true)
	var count:=GameState.settlement_plots.size()
	var events:Array[Dictionary]=[]
	SettlementModel._attempt_functional_growth(120,events)
	assert_int(GameState.settlement_plots.size()).is_equal(count)
	assert_dict(GameState.resource_stockpiles).is_equal(stores)
	GameState.population_allocations.Construction=6
	assert_float(GameState.effective_workers("Construction")).is_equal(4.5)
	SettlementModel._attempt_functional_growth(150,events)
	assert_int(GameState.settlement_plots.size()).is_equal(count+1)
	assert_str(String(GameState.settlement_plots.back().status)).is_equal("under_construction")

func test_injuries_do_not_create_extra_civilian_construction_capacity()->void:
	MilitaryCampaign.joint_operations.state.bases.clear()
	GameState.civilian_injuries={"limited":0.0,"severe":float(GameState.population_total)}
	var workers:=GameState.population_allocations.duplicate(true)
	var stores:=GameState.resource_stockpiles.duplicate(true)
	assert_float(GameState.effective_workers("Construction")).is_less(4.0)
	var events:Array[Dictionary]=[]
	assert_bool(SettlementModel._attempt_household_growth(120,events)).is_false()
	SettlementModel._attempt_functional_growth(120,events)
	assert_array(events).is_empty()
	assert_dict(GameState.resource_stockpiles).is_equal(stores)
	assert_dict(GameState.population_allocations).is_equal(workers)

func test_inherited_renewal_waits_for_available_builders()->void:
	GameState.settlement_founded_day=0
	GameState.settlement_completed.append("Lean-to Shelters")
	var stores:=GameState.resource_stockpiles.duplicate(true)
	var events:Array[Dictionary]=[]
	SettlementModel._evolve_inherited_fabric(360,events)
	assert_array(events).is_empty()
	assert_dict(GameState.resource_stockpiles).is_equal(stores)
	var base:Dictionary=MilitaryCampaign.joint_operations.state.bases[0]
	base.construction_work=base.required_work
	SettlementModel._evolve_inherited_fabric(450,events)
	assert_array(events).is_not_empty()

func test_two_thousand_person_quarter_requires_available_construction_capacity()->void:
	GameState.settlement_founded_day=0
	GameState.population_allocations.Construction=24
	GameState.population_allocations.Logistics=12
	GameState.population_allocations.Administration=8
	GameState.simulation_metrics.logistics=.52
	GameState.known_discoveries.append("route_memory")
	var stores:=GameState.resource_stockpiles.duplicate(true)
	var count:=GameState.settlement_plots.size()
	var events:Array[Dictionary]=[]
	var terrain:={"settlement_origin":GameState.settlement_founded_at,"buildable_land_at":func(_x:float,_z:float)->bool:return true,"terrain_height_at":func(_x:float,_z:float)->float:return 0.0,"river_distance_at":func(_x:float,_z:float)->float:return INF}
	SettlementModel._attempt_mature_district_expansion(1800,events,terrain)
	assert_array(events).is_empty()
	assert_dict(GameState.resource_stockpiles).is_equal(stores)
	var base:Dictionary=MilitaryCampaign.joint_operations.state.bases[0]
	base.construction_work=base.required_work
	SettlementModel._attempt_mature_district_expansion(1800,events,terrain)
	assert_array(events).is_not_empty()
	assert_int(GameState.settlement_plots.size()).is_greater(count)
