extends GdUnitTestSuite
const Overlay=preload("res://scripts/hud/service_world_overlay.gd")
const Navy=preload("res://scripts/hud/naval_command_panel.gd")
const Air=preload("res://scripts/hud/air_command_panel.gd")
class TestTerrain extends Node3D:
	var camera:Camera3D
	func _height_at(_x:float,_z:float)->float:return 0.0
	func _terrain_hit(point:Vector2)->Dictionary:
		var origin:=camera.project_ray_origin(point)
		var normal:=camera.project_ray_normal(point)
		var world:=origin+normal*(-origin.y/normal.y)
		return {"position":world}

func before_test()->void:
	GameState.reset_for_new_world(424242);SettlementModel.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(400)
	GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()

func _text(node:Node)->String:
	var result:=""
	if node is Button or node is Label:result+=node.text+"\n"
	for child:Node in node.get_children():result+=_text(child)
	return result

func test_services_have_distinct_controls_and_no_secondary_map_camera()->void:
	var navy:CanvasLayer=auto_free(Navy.new());add_child(navy)
	var air:CanvasLayer=auto_free(Air.new());add_child(air)
	assert_str(_text(navy)).contains("Join selected companion's fleet").not_contains("Ferry wing")
	assert_str(_text(air)).contains("Ferry wing to selected carrier").not_contains("Join selected companion's fleet")
	assert_str(navy.domain).is_equal("navy");assert_str(air.domain).is_equal("air")
	assert_int(navy.pages.get_tab_count()).is_equal(3)
	assert_str(air.pages.get_tab_title(1)).is_equal("Airbases")
	assert_int(air.map.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_bool("camera" in air.map).is_false()

func test_world_projection_follows_actual_camera_and_boundary_survives_pan_zoom()->void:
	var terrain:TestTerrain=auto_free(TestTerrain.new());add_child(terrain)
	terrain.camera=Camera3D.new();terrain.add_child(terrain.camera)
	terrain.camera.projection=Camera3D.PROJECTION_ORTHOGONAL;terrain.camera.size=100
	terrain.camera.position=Vector3(0,100,50);terrain.camera.look_at(Vector3.ZERO)
	var overlay:Control=auto_free(Overlay.new());overlay.terrain=terrain;overlay.domain="air";add_child(overlay)
	var world:=Vector2(5,7)
	var first:Vector2=overlay.world_to_screen(world)
	var back:Dictionary=overlay.screen_to_world(first)
	assert_float(float(back.x)).is_equal_approx(world.x,.01)
	assert_float(float(back.z)).is_equal_approx(world.y,.01)
	overlay.begin_boundary()
	overlay.vertices=[{"x":0.0,"z":0.0},{"x":10.0,"z":0.0},{"x":10.0,"z":10.0}]
	var saved:Array=overlay.vertices.duplicate(true)
	terrain.camera.position.x+=20;terrain.camera.size=200
	assert_bool(first.distance_to(overlay.world_to_screen(world))>1).is_true()
	assert_array(overlay.vertices).is_equal(saved)
	overlay.finish_boundary("Air sector")
	assert_bool(overlay.drawing).is_false()
	assert_array(overlay.selected.vertices).is_equal(saved)
	assert_int(MilitaryCampaign.joint_operations.known_regions("navy").size()).is_equal(0)

func test_input_leaves_pan_zoom_to_world_and_escape_cancels_draft_first()->void:
	var air:CanvasLayer=auto_free(Air.new());add_child(air)
	air.map.begin_boundary();air.map.vertices=[{"x":1.0,"z":1.0}]
	var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true
	assert_bool(air.handle_map_input(wheel)).is_false()
	var middle:=InputEventMouseButton.new();middle.button_index=MOUSE_BUTTON_MIDDLE;middle.pressed=true
	assert_bool(air.handle_map_input(middle)).is_false()
	var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true
	assert_bool(air.handle_early_input(escape)).is_true()
	assert_bool(air.is_queued_for_deletion()).is_false()
	assert_bool(air.map.drawing).is_false()

func test_failed_boundary_stays_editable_and_does_not_save_invalid_region()->void:
	var overlay:Control=auto_free(Overlay.new());overlay.domain="air";add_child(overlay)
	overlay.begin_boundary();overlay.vertices=[{"x":0.0,"z":0.0},{"x":1.0,"z":1.0}]
	overlay.finish_boundary("Incomplete")
	assert_bool(overlay.drawing).is_true()
	assert_int(MilitaryCampaign.joint_operations.state.regions.size()).is_equal(0)
	overlay.undo_vertex();assert_int(overlay.vertices.size()).is_equal(1)
