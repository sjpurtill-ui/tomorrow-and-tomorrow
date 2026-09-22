extends GdUnitTestSuite
const U=preload("res://scripts/undertaking_system.gd")
const C=preload("res://scripts/undertaking_catalog.gd")
var city:Dictionary
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(921);SettlementModel.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.settlement_name="Test";GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	city=GameState.player_settlements[0]
	GameState.population_allocations={"Construction":20,"Crafting":10,"Food":20}
	GameState.resource_stockpiles={"Stone":10000.0,"Timber":10000.0,"Clay":10000.0,"Fiber Plants":10000.0}
	GameState.simulation_metrics={"food_intake_ratio":1.0,"labor_efficiency":1.0,"cohesion":1.0}
	GameState.water_metrics={"intake_ratio":1.0}
func record()->Dictionary:
	var r:={"id":"ancestor_ring","status":"building","policy":"careful","progress":0.0,"quality":0.0,"condition":1.0,"strain":0,"stalled_days":0,"operating_days":0,"last_day":0,"started":0,"reason":"Test","legacy":"Unproven"}
	city.undertakings=[r];return r
func test_paid_work_diverts_existing_builders_and_is_idempotent()->void:
	var baseline:=GameState.effective_workers("Construction")
	var r:=record()
	assert_float(GameState.effective_workers("Construction")).is_equal_approx(baseline*.8,.000001)
	U.advance_record(GameState,r,1)
	assert_float(float(r.progress)).is_greater(0)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal_approx(10000-float(r.progress)*240/4000,.000001)
	var before:=r.duplicate(true);U.advance_record(GameState,r,1);assert_dict(r).is_equal(before)
func test_shortages_stall_then_abandon_and_pressing_records_hardship()->void:
	var r:=record();GameState.simulation_metrics.food_intake_ratio=.5
	U.advance_record(GameState,r,1);assert_str(r.status).is_equal("stalled")
	r.stalled_days=1824;U.advance_record(GameState,r,2);assert_str(r.status).is_equal("abandoned")
	r=record();r.policy="press";U.advance_record(GameState,r,3)
	assert_float(float(r.progress)).is_greater(0);assert_int(r.strain).is_equal(1)
func test_completion_can_fail_and_functioning_sites_can_decay()->void:
	var r:=record();r.progress=3999;r.quality=1000
	U.advance_record(GameState,r,1);assert_str(r.status).is_equal("ruined")
	r=record();r.progress=3999;r.quality=3999
	U.advance_record(GameState,r,1);assert_str(r.status).is_equal("functioning")
	assert_float(U.benefit(GameState,"Administration")).is_greater(0)
	r.condition=.1501;GameState.resource_stockpiles={};U.advance_record(GameState,r,2)
	assert_str(r.status).is_equal("ruined");assert_float(U.benefit(GameState,"Administration")).is_equal(0.0)
func test_catalog_varies_by_world_and_records_roundtrip()->void:
	GameState.population_total=500
	GameState.known_discoveries=["clay_shaping","seed_selection","public_stores","framed_construction"]
	var a:=U.possibilities(city);assert_array(U.possibilities(city)).is_equal(a)
	var variants:Array=[]
	for seed in range(10):
		GameState.world_seed=seed;variants.append(hash(U.possibilities(city)))
	assert_bool(variants.any(func(v):return v!=variants[0])).is_true()
	var r:=record();var saved:Array=bytes_to_var(var_to_bytes([city]))
	assert_bool(U.valid(saved)).is_true();assert_dict(saved[0].undertakings[0]).is_equal(r)
	saved[0].undertakings[0].progress=NAN;assert_bool(U.valid(saved)).is_false()
func test_map_forms_and_ui_compile()->void:
	var r:=record();r.progress=2000
	var parent:=Node3D.new();add_child(parent)
	preload("res://scripts/undertaking_map_visual.gd").render([city],parent,func(_x,_z):return 0.0)
	assert_int(parent.get_child_count()).is_equal(1)
	assert_int(parent.get_child(0).get_child_count()).is_greater(2)
	assert_object(load("res://scripts/hud/content/dock_content_undertakings.gd")).is_not_null()
	assert_object(load("res://scripts/civilization_day.gd")).is_not_null()
	parent.free()


func test_authorization_and_daily_city_scope_preserve_selection()->void:
	GameState.population_total=500;GameState.population_exact=500
	GameState.known_discoveries=["clay_shaping","seed_selection","public_stores","framed_construction"]
	var offered:=U.possibilities(city)
	assert_array(offered).is_not_empty()
	if offered.is_empty():return
	var selected:=GameState.selected_player_settlement_id
	var result:=U.start(String(city.id),String(offered[0].id))
	assert_bool(result.has("ok")).is_true()
	if not result.has("ok"):return
	assert_bool(U.start(String(city.id),String(offered[0].id)).has("error")).is_true()
	U.advance_all(1)
	assert_float(float(city.undertakings[0].progress)).is_greater(0.0)
	assert_str(GameState.selected_player_settlement_id).is_equal(selected)
	assert_bool(U.valid(GameState.player_settlements)).is_true()

