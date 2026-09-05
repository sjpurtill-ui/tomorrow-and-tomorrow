extends Node
func _ready()->void:
	var loaded:=SaveSystem.load_game()
	if loaded.has("error"):push_error(str(loaded));get_tree().quit(1);return
	GameState.civic_api_enabled=false
	var report:=CivilizationSystem.city_intelligence.known("player","civ_14_region_05")
	print("SAVED_CITY=",JSON.stringify(report))
	print("SAVED_MILITARY=",JSON.stringify({"home":MilitaryCampaign.home_army,"recruits":MilitaryCampaign.aggregate_recruits,"queue":MilitaryCampaign.training_queue,"injuries":MilitaryCampaign.training_injury_pool}))
	var fog:=CivilizationSystem.revealed_areas.duplicate(true)
	var terrain:=preload("res://local_terrain.tscn").instantiate();add_child(terrain);terrain._set_game_speed(0)
	CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	terrain._focus_known_world_point("civ_14","settlement")
	for frame in 120:await get_tree().process_frame
	terrain._refresh_contact_encounter_markers()
	var marker:Node3D=terrain.contact_encounter_markers.get("civ_14_region_05")
	assert(marker!=null and marker.visible)
	assert(marker.find_children("*","MeshInstance3D",true,false).size()==3)
	assert(CivilizationSystem.revealed_areas==fog)
	print("CITY_GEOMETRY=",marker.get_child(0).building_count," camera=",terrain.camera.size," target=",terrain.camera_target)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/fallow-moor-close.png")
	print("FOREIGN_CITY_CAMPAIGN_PASS actualsavedknownlocation, terrainfabric, focus, unchangedfog")
	get_tree().quit()
