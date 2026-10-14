extends GdUnitTestSuite
const People:=preload("res://scripts/historical_figures_screen.gd")
const Report:=preload("res://scripts/hud/content/dock_detail_scout_report.gd")
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(90210)
	HistoricalFigures.reset_for_new_world();HistoricalFigures.ensure()
func test_person_reader_keeps_all_deeds_and_support_action()->void:
	var person:Dictionary=HistoricalFigures.people[0]
	for index in 7:person.events.append({"day":index,"text":"Recorded deed %d" % index})
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(1024,720);add_child(viewport)
	var view:=People.new();viewport.add_child(view)
	for frame in 4:await get_tree().process_frame
	assert_int(view.deeds_choices.get_child_count()).is_equal(3)
	assert_str(view.deed_reader.get_child(1).text).is_equal("Recorded deed 6")
	view.deeds_toggle.pressed.emit()
	assert_int(view.deeds_choices.get_child_count()).is_equal(6)
	view.deeds_search.text="Recorded deed 0";view.deeds_search.text_changed.emit("Recorded deed 0")
	assert_int(view.deeds_choices.get_child_count()).is_equal(1)
	assert_str(view.deed_reader.get_child(1).text).is_equal("Recorded deed 0")
	view._refresh()
	assert_str(view.deeds_search.text).is_equal("Recorded deed 0")
	assert_str(view.body.text).is_equal(WorldSimulation.figures.biography(person))
	assert_bool(person.supported).is_false()
	view.patron.pressed.emit()
	assert_bool(person.supported).is_true()
	assert_str(view.patron.text).is_equal("Withdraw support")
	assert_bool(Rect2(Vector2.ZERO,Vector2(1024,720)).encloses(view.patron.get_global_rect())).is_true()
func test_empty_scout_route_uses_compact_text_but_recorded_route_is_retained()->void:
	var report:={"mission_id":943,"day":0,"personnel":4,"journal":["A long road."],"route":[]}
	var provider=Report.new(null,null,report)
	var blocks:Array=provider.tab(1).blocks
	assert_array(blocks.filter(func(block:Dictionary):return block.get("type")=="expedition_chart")).is_empty()
	assert_array(blocks.filter(func(block:Dictionary):return block.get("text")=="They brought back no drawing of their road.")).has_size(1)
	report.route=[{"x":0.0,"z":0.0},{"x":25.0,"z":-40.0}]
	provider=Report.new(null,null,report)
	blocks=provider.tab(1).blocks
	var charts:Array=blocks.filter(func(block:Dictionary):return block.get("type")=="expedition_chart")
	assert_array(charts).has_size(1)
	assert_array(charts[0].route).is_equal(report.route)
