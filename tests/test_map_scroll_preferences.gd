extends GdUnitTestSuite
const Preferences=preload("res://scripts/display_preferences.gd")
const CONFIG_PATH:="user://map-scroll-preferences-test.cfg"
class Map extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _height_at(_x:float,_z:float)->float:return 0.0
	func _terrain_hit(_screen:Vector2)->Dictionary:return {}

func before_test()->void:
	if FileAccess.file_exists(CONFIG_PATH):DirAccess.remove_absolute(CONFIG_PATH)
func after_test()->void:
	if FileAccess.file_exists(CONFIG_PATH):DirAccess.remove_absolute(CONFIG_PATH)

func fixture()->Node3D:
	var map:Node3D=auto_free(Map.new());add_child(map)
	map.camera=Camera3D.new();map.add_child(map.camera);map.camera.size=100.0;map._update_camera()
	map.display_preferences=Preferences.new();map.display_preferences.config_path=CONFIG_PATH
	map.add_child(map.display_preferences)
	return map

func test_setting_changes_live_pan_distance_and_reopens_at_saved_value()->void:
	var map:=fixture()
	var controls:VBoxContainer=auto_free(VBoxContainer.new());add_child(controls)
	map.display_preferences.add_navigation_controls(controls)
	var slider:=controls.get_node("MapScrollSpeed") as HSlider
	slider.value=1.0;map._pan_camera_gesture(Vector2(30,20))
	var original:Vector3=map.camera_target
	slider.value=7.5;map.camera_target=Vector3.ZERO;map._pan_camera_gesture(Vector2(30,20))
	assert_vector(map.camera_target).is_equal_approx(original*7.5,Vector3.ONE*.0001)
	assert_float(map.camera.size).is_equal(100.0)
	assert_float(map.zoom_target_size).is_equal(-1.0)
	var restored:=Preferences.new();restored.config_path=CONFIG_PATH;map.add_child(restored)
	assert_float(restored.map_scroll_speed).is_equal(7.5)
	var reopened:VBoxContainer=auto_free(VBoxContainer.new());add_child(reopened);restored.add_navigation_controls(reopened)
	assert_float((reopened.get_node("MapScrollSpeed") as HSlider).value).is_equal(7.5)
	var row:=reopened.get_child(1)
	(row.get_child(1) as Button).pressed.emit()
	assert_float(restored.map_scroll_speed).is_equal(4.0)
	var saved:=ConfigFile.new();assert_int(saved.load(CONFIG_PATH)).is_equal(OK)
	assert_float(float(saved.get_value("camera","map_scroll_speed"))).is_equal(4.0)

func test_legacy_settings_gain_faster_default_and_other_settings_survive_scroll_changes()->void:
	var config:=ConfigFile.new();config.set_value("display","music_volume",.35)
	config.set_value("display","render_scale",.5);config.set_value("display","ui_scale",1.5)
	assert_int(config.save(CONFIG_PATH)).is_equal(OK)
	var map:=fixture();assert_float(map.display_preferences.map_scroll_speed).is_equal(4.0)
	map.display_preferences.map_scroll_speed=12.0;map.display_preferences.persist()
	var restored:=Preferences.new();restored.config_path=CONFIG_PATH;map.add_child(restored)
	assert_float(restored.map_scroll_speed).is_equal(12.0)
	assert_float(restored.music_volume).is_equal(.35)
	assert_float(restored.render_scale).is_equal(.5)
	assert_float(restored.ui_scale).is_equal(1.5)

func test_saved_scroll_speed_is_bounded_and_invalid_values_use_the_default()->void:
	for example in [[0.0,.5],[99.0,12.0],[NAN,4.0],[INF,4.0],["bad",4.0]]:
		var config:=ConfigFile.new();config.set_value("camera","map_scroll_speed",example[0]);config.save(CONFIG_PATH)
		var map:=fixture()
		assert_float(map.display_preferences.map_scroll_speed).is_equal(float(example[1]))

func test_keyboard_adjustments_in_settings_do_not_pan_the_background_map()->void:
	var map:=fixture();map.world_menu_panel=Control.new();map.add_child(map.world_menu_panel)
	Input.action_press("ui_right");map._process_camera_navigation(.5);Input.action_release("ui_right")
	assert_vector(map.camera_target).is_equal(Vector3.ZERO)
