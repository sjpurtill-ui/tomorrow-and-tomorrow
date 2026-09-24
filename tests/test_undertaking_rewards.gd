extends GdUnitTestSuite
const R=preload("res://scripts/undertaking_rewards.gd")
const U=preload("res://scripts/undertaking_system.gd")
const C=preload("res://scripts/undertaking_catalog.gd")
var city:Dictionary
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(921);SettlementModel.reset_for_new_world()
	GameState.settlement_name="Test";GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	city=GameState.player_settlements[0];city.undertakings=[]
	GameState.elapsed_days=365*25
func completed(id:String)->Dictionary:
	var work:float=C.get_definition(id).work
	var r:={"id":id,"status":"functioning","policy":"careful","progress":work,"quality":work,"condition":1.0,"strain":0,"stalled_days":0,"operating_days":365*20,"last_day":365*25,"started":0,"reason":"Maintained","legacy":"Enduring"}
	city.undertakings.append(r)
	return r
func test_food_storage_and_preservation_are_real_and_do_not_create_food()->void:
	GameState.food_stocks={FoodSystem.FRESH:100.0,FoodSystem.STORED:100.0}
	var capacity:float=FoodSystem._food_storage_capacity()
	var before:Dictionary=GameState.food_stocks.duplicate(true)
	var ordinary:Dictionary=FoodSystem._spoil(false)
	GameState.food_stocks=before.duplicate(true)
	var r:=completed("common_stores")
	assert_float(FoodSystem._food_storage_capacity()).is_equal(capacity+18000.0)
	assert_dict(GameState.food_stocks).is_equal(before)
	var preserved:Dictionary=FoodSystem._spoil(false)
	assert_float(float(preserved[FoodSystem.FRESH])).is_equal_approx(float(ordinary[FoodSystem.FRESH])*.75,.000001)
	assert_float(float(preserved[FoodSystem.STORED])).is_equal_approx(float(ordinary[FoodSystem.STORED])*.75,.000001)
	r.status="ruined"
	assert_float(FoodSystem._food_storage_capacity()).is_equal(capacity)
func test_crafting_research_and_attraction_change_existing_systems()->void:
	GameState.population_allocations={"Crafting":10,"Knowledge":10}
	var craft:float=GameState.effective_workers("Crafting")
	var research:float=GameState.effective_workers("Knowledge")
	var exchange=preload("res://scripts/society_exchange.gd")
	var attraction:float=exchange.attraction()
	completed("kiln_court");completed("star_steps");var sanctuary:=completed("safe_passage")
	assert_float(GameState.effective_workers("Crafting")).is_equal_approx(craft*1.18,.000001)
	assert_float(GameState.effective_workers("Knowledge")).is_equal_approx(research*1.17,.000001)
	assert_float(exchange.attraction()).is_equal_approx(minf(1,attraction+.08),.000001)
	sanctuary.condition=.5
	assert_float(R.local_bonus(GameState,"attraction")).is_equal(.04)
func test_reputation_requires_carried_accounts_and_ages()->void:
	var r:=completed("stone_crown")
	assert_float(R.diplomatic_bonus(GameState,"foreign_a",9125)).is_equal(0.0)
	R.share_accounts(GameState,"foreign_a",9125)
	assert_float(R.diplomatic_bonus(GameState,"foreign_a",9125)).is_equal(.10)
	assert_float(R.diplomatic_bonus(GameState,"foreign_b",9125)).is_equal(0.0)
	r.strain=180;R.share_accounts(GameState,"foreign_a",9125)
	assert_float(R.diplomatic_bonus(GameState,"foreign_a",9125)).is_equal(.05)
	assert_float(R.diplomatic_bonus(GameState,"foreign_a",9125+365*30)).is_equal(0.0)
func test_history_records_wonders_and_never_awards_victory()->void:
	completed("common_stores");completed("star_steps");var crown:=completed("stone_crown")
	R.share_accounts(GameState,"foreign_a",9125);R.share_accounts(GameState,"foreign_b",9125)
	crown.strain=180
	var record:=R.history(GameState)
	assert_int(int(record.attempted)).is_equal(3)
	assert_int(int(record.standing)).is_equal(3)
	assert_int(int(record.enduring)).is_equal(3)
	assert_int(int(record.kinds)).is_equal(3)
	assert_int(int(record.known_by)).is_equal(2)
	assert_int(int(record.costly)).is_equal(1)
	# There is no victory: nothing is ever awarded or written.
	assert_bool(record.has("ready") or record.has("award")).is_false()
	U.advance_all(9126)
	assert_bool(city.has("wonder_victory")).is_false()
	# Old saves that carry a retired award still load.
	city.wonder_victory={"day":9125,"costly":1}
	var saved:Array=bytes_to_var(var_to_bytes(GameState.player_settlements))
	assert_bool(U.valid(saved)).is_true()
	saved[0].undertakings[0].heard_by.foreign_a.condition=NAN
	assert_bool(U.valid(saved)).is_false()
func test_rewards_are_local_and_water_storage_does_not_create_water()->void:
	var before:Dictionary=GameState.resource_stockpiles.duplicate(true)
	var rain:=completed("rain_court")
	assert_float(R.local_bonus(GameState,"water_capacity")).is_equal(7200.0)
	assert_dict(GameState.resource_stockpiles).is_equal(before)
	GameState.resource_settlement_id="another_city"
	assert_float(R.local_bonus(GameState,"water_capacity")).is_equal(0.0)
	GameState.resource_settlement_id=""
	rain.status="stalled"
	assert_float(R.local_bonus(GameState,"water_capacity")).is_equal(0.0)

