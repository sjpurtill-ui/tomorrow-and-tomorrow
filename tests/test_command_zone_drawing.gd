extends GdUnitTestSuite
const Overlay=preload("res://scripts/hud/service_world_overlay.gd")
const CommandUI=preload("res://scripts/hud/command_hierarchy_panel.gd")
class Map extends Overlay:
	func screen_to_world(point:Vector2)->Dictionary:return {"x":point.x/20,"z":point.y/20}
	func world_to_screen(point:Vector2)->Vector2:return point*20
func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(424242)
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	PeopleDirection.reset_for_new_world()
	CivilizationSystem.revealed_areas=[{"x":0.0,"z":0.0,"radius":100000.0}]
	CivilizationSystem.set_scout_geography_authority(func(_at:Vector2)->bool:return true)
	MilitaryCampaign.joint_operations.geography.land_query=func(_at:Vector2)->bool:return true
func after_test()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
func _map()->Map:
	var map:Map=auto_free(Map.new());map.domain="army";add_child(map);map.begin_boundary();return map
func _click(map:Map,point:Vector2,button:int=MOUSE_BUTTON_LEFT)->void:
	var event:=InputEventMouseButton.new();event.pressed=true;event.position=point;event.button_index=button
	assert_bool(map.handle_map_input(event)).is_true()
func test_right_click_closes_triangle_without_removing_last_corner()->void:
	var map:=_map()
	_click(map,Vector2(0,0));_click(map,Vector2(100,0));_click(map,Vector2(100,100))
	_click(map,Vector2(150,150),MOUSE_BUTTON_RIGHT)
	assert_bool(map.drawing).is_false()
	assert_int(map.selected.vertices.size()).is_equal(3)
	assert_float(map.selected.vertices[2].z).is_equal(5.0)
	assert_bool(Overlay.R.contains(map.selected,Vector2(4,1))).is_true()
func test_snaps_to_first_corner_and_click_closes_without_duplicate_endpoint()->void:
	var map:=_map()
	_click(map,Vector2.ZERO);_click(map,Vector2(100,0));_click(map,Vector2(100,100))
	var point:=map.snapped_vertex(Vector2(4,3))
	assert_float(float(point.x)).is_equal(0.0)
	assert_float(float(point.z)).is_equal(0.0)
	_click(map,Vector2(4,3))
	assert_bool(map.drawing).is_false()
	assert_int(map.selected.vertices.size()).is_equal(3)
func test_alignment_snaps_and_incomplete_right_click_stops_without_saving()->void:
	var map:=_map();_click(map,Vector2.ZERO)
	var point:=map.snapped_vertex(Vector2(100,3))
	assert_float(float(point.z)).is_equal(0.0)
	_click(map,Vector2(100,3))
	_click(map,Vector2(120,80),MOUSE_BUTTON_RIGHT)
	assert_bool(map.drawing).is_false()
	assert_bool(map.selected.is_empty()).is_true()
func test_command_controls_have_matching_theme_surfaces()->void:
	var panel:CanvasLayer=auto_free(CommandUI.new());add_child(panel)
	assert_object(panel.panel.theme).is_not_null()
	assert_bool(panel.panel.theme.has_stylebox("panel","TabContainer")).is_true()
	assert_bool(panel.panel.theme.has_stylebox("title_button_normal","Tree")).is_true()
	panel.map.begin_boundary();panel.map.vertices=[{"x":0.0,"z":0.0},{"x":5.0,"z":0.0}]
	var undo:=InputEventKey.new();undo.pressed=true;undo.keycode=KEY_BACKSPACE
	assert_bool(panel.handle_early_input(undo)).is_true()
	assert_int(panel.map.vertices.size()).is_equal(1)
