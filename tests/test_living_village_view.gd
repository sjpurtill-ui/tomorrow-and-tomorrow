extends GdUnitTestSuite
const View := preload("res://scripts/hud/living_village_view.gd")

class MapFixture extends Node3D:
	var camera: Camera3D
	var camera_target := Vector3(10, 2, 30)
	var camera_yaw := 0.2
	var camera_pitch := -1.2
	var zoom_target_size := -1.0
	var zoom_preset_active := false
	var zoom_log_velocity := 0.0
	var north_reset_active := false
	var pan_coast_velocity := Vector3.ZERO
	var key_pan_velocity := Vector2.ZERO
	var terrain_patch_job: RefCounted
	var close_terrain_job: RefCounted
	func _init() -> void:
		camera = Camera3D.new(); camera.size = 8.0; add_child(camera)
	func _height_at(_x: float, _z: float) -> float: return 2.0
	func _update_camera() -> void: camera.position = camera_target + Vector3(0, 2, 2)
	func _update_scale_lod() -> void: pass
	func settlement_patch_stats() -> Dictionary: return {"pending":0,"installed":1}

func _setup() -> Array:
	var map := MapFixture.new(); add_child(map); auto_free(map)
	var widget := View.new(); add_child(widget); auto_free(widget)
	widget.setup({"terrain":map,"state":{"id":"fixture","name":"Test", "day":20, "position":Vector2(1,3),"span":0.2}})
	widget.set_process(false)
	return [map, widget]

func test_portrait_uses_the_real_world_and_restores_map_view_on_close() -> void:
	var fixture := _setup(); var map: MapFixture = fixture[0]; var widget: Control = fixture[1]
	widget.call("_acquire")
	assert_object(widget.get("view").world_3d).is_same(map.get_viewport().world_3d)
	assert_bool(map.has_meta("village_portrait")).is_true()
	assert_vector(map.camera_target).is_equal(Vector3(1,2,3))
	widget.call("_release")
	assert_vector(map.camera_target).is_equal(Vector3(10,2,30))
	assert_float(map.camera.size).is_equal(8.0)
	assert_float(map.camera_yaw).is_equal(0.2)
	assert_bool(map.has_meta("village_portrait")).is_false()

func test_visit_keeps_the_view_but_a_later_dismissal_restores_it() -> void:
	var fixture := _setup(); var map: MapFixture = fixture[0]; var widget: Control = fixture[1]
	widget.call("_acquire")
	widget.call("_visit")
	widget.call("_release")
	assert_vector(map.camera_target).is_equal(Vector3(1,2,3))
	map.camera_target = Vector3(70,2,90);map.camera.size=14.0
	widget.call("_acquire")
	widget.call("_release")
	assert_vector(map.camera_target).is_equal(Vector3(70,2,90))
	assert_float(map.camera.size).is_equal(14.0)

func test_unfinished_terrain_does_not_enter_the_album() -> void:
	var fixture := _setup(); var map: MapFixture = fixture[0]; var widget: Control = fixture[1]
	assert_bool(widget.call("_ready_to_record")).is_true()
	map.terrain_patch_job = RefCounted.new()
	assert_bool(widget.call("_ready_to_record")).is_false()
