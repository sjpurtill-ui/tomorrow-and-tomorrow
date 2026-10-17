extends GdUnitTestSuite
## Exercise the real category overrides and dock geometry, not just the widget.
const Rail=preload("res://scripts/hud/command_rail_hud.gd")
const Dock=preload("res://scripts/hud/dock_panel.gd")
const Provider=preload("res://scripts/hud/content/dock_content_production.gd")
const Fixture=preload("res://tests/hoi4_production_capture.gd")

func before_test()->void:Fixture.seed_early()
func after_test()->void:WorldSimulation.clear()

func _panel()->Control:
	var rail:Control=auto_free(Rail.new())
	var provider=Provider.new(null,null)
	rail.providers={"production":provider,"economy":load("res://scripts/hud/content/dock_content_economy.gd").new(null,null)}
	var dock:Control=auto_free(Dock.new());add_child(dock)
	dock.size=Vector2(620,850)
	dock.siblings=rail._pages_of(Rail.category_of("production"));dock.category_title="Economy"
	dock.present(provider,0)
	return dock

func test_real_economy_tabs_are_unique_and_alias_opens_military()->void:
	var dock:=_panel()
	var labels:Array=[]
	for button:Button in dock.tab_buttons:
		if button.visible:labels.append(button.text)
	assert_array(labels).is_equal(["Food","Materials","Wealth","Trade","Military","Civilian"])
	dock.present(dock.provider,2)
	var active:Array=dock._flat.filter(func(entry):return bool(entry.active))
	assert_int(active.size()).is_equal(1)
	assert_str(active[0].text).is_equal("Military")
	assert_str(dock.title_label.text).is_equal("PRODUCTION")
	dock.rebuild_body()
	assert_bool(dock.get_node("FolioPaper").visible).is_false()
	assert_that(dock.get_theme_stylebox("panel").bg_color).is_equal(Color("252a25"))
	dock.size.y=700
	await get_tree().process_frame
	assert_int(dock.title_label.get_theme_font_size("font_size")).is_equal(20)

func test_opening_catalog_never_hides_lines_and_fits_compact_dock()->void:
	var dock:=_panel()
	for frame in 8:await get_tree().process_frame
	var board:Control=dock.find_child("IllustratedProductionQueue",true,false)
	var row:Control=board.find_child("Line1",true,false)
	var action:Button=board._workspace_buttons.recipes
	action.button_pressed=true;action.pressed.emit()
	for frame in 8:await get_tree().process_frame
	assert_bool(row.is_visible_in_tree()).is_true()
	assert_bool(board._picker.is_visible_in_tree()).is_true()
	assert_float(board._picker.size.y).is_less(260)
	assert_float(row.size.y).is_less(145)
	assert_float(dock.size.x).is_equal_approx(620,1)
	assert_float(row.get_global_rect().end.x).is_less_equal(dock.get_global_rect().end.x)
	assert_bool(board.update_block(dock.provider.tab(0).blocks[0])).is_true()
	assert_object(board.find_child("Line1",true,false)).is_same(row)
	action.button_pressed=false;action.pressed.emit()
	assert_bool(board._picker.visible).is_false()
	assert_bool(row.is_visible_in_tree()).is_true()

func test_production_width_is_bounded_and_other_pages_keep_their_layout()->void:
	var rail:Control=auto_free(Rail.new())
	var dock:=_panel()
	for width in [1024,1280,1920,2808]:
		assert_float(rail._dock_width(dock,width)).is_equal(620.0)
	assert_float(rail._dock_width(dock,600)).is_less(600.0)
	dock.present(load("res://scripts/hud/content/dock_content_economy.gd").new(null,null),0)
	assert_float(rail._dock_width(dock,1920)).is_greater(620.0)
	assert_bool(dock.get_node("FolioPaper").visible).is_true()
