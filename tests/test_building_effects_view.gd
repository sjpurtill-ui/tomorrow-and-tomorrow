extends GdUnitTestSuite
const Model=preload("res://scripts/building_effect_readings.gd")
const View=preload("res://scripts/hud/building_effects_view.gd")
const Board=preload("res://scripts/hud/buildings_board.gd")
var fixture
func before_test()->void:
	fixture=load("res://tests/test_construction_city_tab.gd").new();add_child(fixture);fixture.before_test();fixture._found(100,["Hearth Circle","Storage Pits","Lean-to Shelters"],150)
func after_test()->void:
	fixture.after_test();fixture.queue_free();await get_tree().process_frame
func test_current_capacity_and_bonuses_match_existing_engine_and_do_not_mutate()->void:
	var allocations:=GameState.population_allocations.duplicate(true);var stocks:=GameState.resource_stockpiles.duplicate(true)
	var rows:=Model.capacity();var c:Dictionary=SettlementModel.city_capacities()
	assert_int(rows.size()).is_equal(5)
	assert_float(float(rows[0].left)).is_equal(100.0);assert_float(float(rows[0].right)).is_equal(150.0)
	assert_float(float(rows[3].left)).is_equal_approx(float(c.workshop_function)*100,.0001)
	assert_str(rows[3].effects[0].value).is_equal("+%.2f pts"%(float(c.workshop_function)*12))
	assert_str(rows[4].effects[0].value).is_equal("+%.2f pts"%(float(c.storage_function)*10))
	assert_dict(GameState.population_allocations).is_equal(allocations);assert_dict(GameState.resource_stockpiles).is_equal(stocks)
func test_housing_shortage_changes_actual_risk_comparisons()->void:
	var roomy:=Model.homes();GameState.housing_capacity=20
	var crowded:=Model.homes()
	var a:Dictionary=roomy.filter(func(r:Dictionary):return r.id=="Outbreaks")[0]
	var b:Dictionary=crowded.filter(func(r:Dictionary):return r.id=="Outbreaks")[0]
	assert_float(float(b.right)).is_greater(float(a.right))
	assert_bool(b.bad).is_true()
	assert_array(crowded.map(func(r:Dictionary):return r.id)).contains(["Childbirth","Exposure"])
func test_effect_sections_show_every_metric_without_a_selection_browser()->void:
	var provider=preload("res://scripts/hud/content/dock_content_construction.gd").new(fixture.terrain,fixture.hud)
	for id:String in ["does","homes"]:
		var block:Dictionary=provider.tab(1).blocks[0];block.view_state={"section":id}
		var board:Control=auto_free(Board.new());add_child(board);board.setup(block)
		assert_object(board.browser).is_null()
		var effects:=board.find_child("BuildingEffects",true,false)
		assert_object(effects).is_not_null()
		assert_int(effects.get_child_count()).is_equal(5 if id=="does" else 8)
		assert_object(board.find_child("WhatItDoes",true,false)).is_null()
func test_narrow_and_large_numbers_fit_and_resize_without_recreating_tiles()->void:
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(500,900);add_child(canvas)
	var view:=View.new();canvas.add_child(view);view.size=Vector2(468,800)
	var rows:=Model.capacity();rows[0].left=20000000;rows[0].right=19000000
	view.setup(rows)
	for i in 4:await get_tree().process_frame
	var tile:Control=view.get_child(0)
	assert_int(view.columns).is_equal(1)
	assert_float(view.get_combined_minimum_size().x).is_less_equal(468)
	view.size.x=1200;view._fit();assert_int(view.columns).is_equal(3)
	assert_object(view.get_child(0)).is_same(tile)
