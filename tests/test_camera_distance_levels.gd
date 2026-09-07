extends GdUnitTestSuite
class CameraTerrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _height_at(_x:float,_z:float)->float:return 0.0
	func _terrain_hit(_screen:Vector2)->Dictionary:return {}

func fixture()->Node3D:
	var terrain:Node3D=auto_free(CameraTerrain.new())
	add_child(terrain)
	terrain.camera=Camera3D.new();terrain.add_child(terrain.camera)
	terrain.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	return terrain

func test_four_agreed_distances_have_physical_altitudes_and_fivefold_scale()->void:
	var terrain:=fixture()
	assert_array(terrain.CAMERA_DISTANCE_LEVELS.map(func(level:Dictionary)->String:return level.name)).is_equal(["10,000 ft","50,000 ft","Region","Continent"])
	for index in [0,1]:
		terrain.set_camera_distance_level(index)
		terrain.camera.size=terrain.zoom_target_size;terrain._update_camera()
		assert_float(terrain.aerial_altitude_feet()).is_equal_approx(10000.0 if index==0 else 50000.0,1.0)
	assert_float(terrain._distance_camera_size(1)/terrain._distance_camera_size(0)).is_equal_approx(5.0,.0001)

func test_wheel_burst_advances_one_level_without_instant_jump_or_overshoot()->void:
	var terrain:=fixture()
	terrain.camera.size=terrain._distance_camera_size(0)
	var original:float=terrain.camera.size
	for input in 20:terrain._step_camera_distance(Vector2.ZERO,1.0)
	assert_int(terrain.camera_distance_level()).is_equal(1)
	assert_float(terrain.camera.size).is_equal(original)
	var destination:float=terrain.zoom_target_size
	for frame in 360:
		var previous:float=terrain.camera.size
		terrain._process_smooth_camera(1.0/60.0)
		assert_float(terrain.camera.size).is_greater_equal(previous)
		assert_float(terrain.camera.size).is_less_equal(destination+.00001)
	assert_float(terrain.camera.size).is_equal_approx(destination,.0001)

func test_fine_zoom_is_slow_and_cannot_bank_an_unbounded_burst()->void:
	var terrain:=fixture();terrain.camera.size=5.0
	terrain._queue_camera_zoom(Vector2.ZERO,-1.0)
	assert_float(terrain.zoom_target_size).is_equal_approx(5.0/1.12,.00001)
	for input in 100:terrain._queue_camera_zoom(Vector2.ZERO,-1.0)
	assert_float(terrain.zoom_target_size).is_greater_equal(5.0/1.6)
