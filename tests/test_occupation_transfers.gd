extends GdUnitTestSuite
func before_test()->void:
	GameState.reset_for_new_world(424242);GameState.civic_api_enabled=false
	SettlementModel.reset_for_new_world(); CivilizationSystem.reset_for_new_world();CivilizationSystem.initialize();MilitaryCampaign.reset_for_new_world()
	GameState.initialize_population_model();GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.housing_capacity=10000
	FoodSystem.reset_for_new_world();FoodSystem.initialize()
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.strategic_regions[0].controller="player";civ.food_days=100
	var start:Dictionary=CivilizationSystem.city_intelligence.site(region_id()).position
	CivilizationSystem.player_world_origin=Vector2(float(start.x)+120,float(start.z))
	MilitaryCampaign.occupation_forces.append({"civ_id":civ_id(),"region_id":region_id(),"troops":10})
func model(): return MilitaryCampaign.occupation_transfers
func civ_id()->String:return String(CivilizationSystem.civilizations[0].id)
func region_id()->String:return String(CivilizationSystem.civilizations[0].strategic_regions[0].id)
func total()->float:
	var result:=GameState.population_exact
	for civ:Dictionary in CivilizationSystem.civilizations:result+=float(civ.population)
	for convoy:Dictionary in model().data.transfers:result+=float(convoy.people)
	return result
func test_transit_conserves_population_and_food_then_arrives_once()->void:
	var before:=total();var player_before:=GameState.population_exact
	var food_before:=float(CivilizationSystem.civilizations[0].food_days)*float(CivilizationSystem.civilizations[0].population)
	var result:Dictionary=model().depart(civ_id(),region_id(),5,"citizen")
	assert_bool(result.has("ok")).is_true()
	assert_float(total()).is_equal_approx(before,.00001)
	assert_float(GameState.population_exact).is_equal(player_before)
	var convoy:Dictionary=model().data.transfers[0]
	var food_after:=float(CivilizationSystem.civilizations[0].food_days)*float(CivilizationSystem.civilizations[0].population)
	assert_float(food_after+float(convoy.food)).is_equal_approx(food_before,.00001)
	model().advance(1)
	assert_int(model().data.transfers.size()).is_equal(1)
	assert_float(float(model().data.transfers[0].traveled)).is_greater(0.0)
	var saved:Dictionary=JSON.parse_string(JSON.stringify(model().data))
	assert_array(preload("res://scripts/occupation_transfers.gd").validate(saved)).is_empty()
	model().data=saved
	model().advance(20)
	assert_int(model().data.transfers.size()).is_equal(0)
	assert_float(GameState.population_exact).is_equal(player_before+5.0)
	assert_float(total()).is_equal_approx(before,.00001)
	model().advance(20)
	assert_float(GameState.population_exact).is_equal(player_before+5.0)
func test_no_route_or_capacity_rejects_without_removing_people()->void:
	var before:=total()
	GameState.housing_capacity=0
	assert_bool(model().depart(civ_id(),region_id(),5,"penal").has("error")).is_true()
	GameState.housing_capacity=10000
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return false)
	assert_bool(model().depart(civ_id(),region_id(),5,"penal").has("error")).is_true()
	assert_float(total()).is_equal(before)
func test_emancipation_keeps_origin_and_harm()->void:
	assert_bool(model().depart(civ_id(),region_id(),5,"enslaved").has("ok")).is_true()
	model().advance(1);model().advance(20)
	var group:Dictionary=model().data.groups[0]
	var harm:=float(group.grievance)
	assert_str(String(group.status)).is_equal("enslaved")
	assert_bool(model().emancipate(int(group.id)).has("ok")).is_true()
	assert_str(String(group.status)).is_equal("citizen")
	assert_str(String(group.origin)).is_equal(civ_id())
	assert_float(float(group.grievance)).is_equal(harm)
func test_no_room_at_arrival_waits_and_consumes_finite_food()->void:
	var before:=GameState.population_exact
	assert_bool(model().depart(civ_id(),region_id(),5,"citizen").has("ok")).is_true()
	GameState.housing_capacity=0
	model().advance(1);model().advance(20)
	assert_int(model().data.transfers.size()).is_equal(1)
	assert_bool(bool(model().data.transfers[0].arrived)).is_true()
	assert_float(GameState.population_exact).is_equal(before)
	assert_float(float(model().data.transfers[0].food)).is_equal(0.0)
