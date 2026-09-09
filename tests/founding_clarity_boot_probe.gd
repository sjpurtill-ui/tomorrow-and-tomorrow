extends Node
func _ready()->void:call_deferred("run")
func run()->void:
	GameState.reset_for_new_world(741991);CivilizationSystem.reset_for_new_world();GameState.select_founding_focus("provision")
	var map=load("res://local_terrain.tscn").instantiate();add_child(map)
	await get_tree().process_frame;await get_tree().process_frame
	get_window().size=Vector2i(1280,720);map.display_preferences.apply()
	await get_tree().process_frame;await get_tree().process_frame
	map._set_game_speed(0)
	map._update_time_interface();map._update_scale_lod()
	var failures:=0
	for level:Dictionary in map.CAMERA_DISTANCE_LEVELS:
		map.camera.size=float(level.width_km);map._update_camera();map._update_scale_lod();map.city_labels.refresh()
		if map.convoy_map_icon.visible or map.convoy_map_label.layers!=0 or map.city_labels.cards.is_empty():failures+=1
	map._open_founding_site_guide(map.settler_marker.position)
	await get_tree().process_frame;await get_tree().process_frame
	map.city_labels.refresh()
	if map.city_labels.cards.is_empty():failures+=1
	for card:Dictionary in map.city_labels.cards:
		if card.rect.intersects(map.founding_site_guide.panel.get_global_rect()):failures+=1
	print("FOUNDING REAL SCENE CHECKS failures=",failures," card=",map.city_labels.cards," review=",map.founding_site_guide.panel.get_global_rect())
	map.queue_free();await get_tree().process_frame;await get_tree().process_frame
	WorldSimulation.clear();get_tree().quit(failures)
