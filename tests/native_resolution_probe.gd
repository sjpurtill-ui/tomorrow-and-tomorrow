extends Node
func _ready()->void:
	var prefs=preload("res://scripts/display_preferences.gd").new()
	prefs.config_path="res://artifacts/native-resolution-missing.cfg"
	add_child(prefs)
	get_window().size=Vector2i(1600,1000)
	for i in 3:await get_tree().process_frame
	assert(is_equal_approx(prefs.render_scale,1.0))
	assert(is_equal_approx(get_window().scaling_3d_scale,1.0))
	assert(get_window().content_scale_mode==Window.CONTENT_SCALE_MODE_CANVAS_ITEMS)
	prefs.config_path="res://artifacts/native-resolution-test.cfg"
	prefs.render_scale=.75;prefs.persist();prefs.queue_free()
	await get_tree().process_frame
	var restored=preload("res://scripts/display_preferences.gd").new()
	restored.config_path="res://artifacts/native-resolution-test.cfg";add_child(restored)
	assert(is_equal_approx(restored.render_scale,.75))
	restored.render_scale=1.0;restored.apply()
	assert(is_equal_approx(get_window().scaling_3d_scale,1.0))
	print("NATIVE_RESOLUTION_PASS: native default, full-resolution canvas, explicit lower preference retained, runtime native switch")
	get_tree().quit()
