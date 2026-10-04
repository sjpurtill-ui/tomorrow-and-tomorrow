extends GdUnitTestSuite
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")

func test_quality_downgrade_keeps_close_shadows_and_restores_full_room_reach()->void:
	# Exercise the actual light factory and live quality changes without
	# loading a room. The GPU companion measures the rendered edge itself.
	var room:Node3D=auto_free(CourtSet.new())
	room._make_lights()
	var light:DirectionalLight3D=room.sun
	var energy:=light.light_energy
	var direction:=light.transform
	assert_int(light.directional_shadow_mode).is_equal(DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS)
	for setting in ["high","low","high"]:
		room.set_quality(setting)
		assert_object(room.sun).is_same(light)
		assert_bool(light.shadow_enabled).is_true()
		assert_float(light.light_energy).is_equal(energy)
		assert_bool(light.transform.is_equal_approx(direction)).is_true()
		assert_float(light.directional_shadow_max_distance).is_equal(18.0 if setting=="low" else 30.0)
		assert_int(light.directional_shadow_mode).is_equal(DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if setting=="low" else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS)
		assert_float(light.directional_shadow_split_1*light.directional_shadow_max_distance).is_equal_approx(3.6,0.001)
		assert_bool(light.directional_shadow_blend_splits).is_false()
		assert_float(light.shadow_normal_bias).is_equal_approx(1.2,0.001)
		if setting=="high":assert_float(light.directional_shadow_split_3*light.directional_shadow_max_distance).is_greater_equal(15.0)
	assert_float(light.light_angular_distance).is_equal(0.0 if RenderingServer.get_current_rendering_method()=="gl_compatibility" else 1.2)
