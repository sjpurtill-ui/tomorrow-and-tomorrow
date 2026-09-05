extends Node

func _ready()->void:
	GameState.reset_for_new_world(424242)
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	var intel=CivilizationSystem.city_intelligence
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ids:Array[String]=[]
	for index in 3:
		var id:=String(civ.strategic_regions[index].id); ids.append(id)
		intel.publish("player",intel.capture("player",id,.8 if index==0 else .3,20,"returned scout expedition","party 12"),45)
	GameState.elapsed_days=75
	var terrain=preload("res://scripts/local_terrain.gd").new()
	for id in ids:
		var p:Dictionary=intel.known("player",id).position
		assert(terrain._contact_encounter_at(Vector3(p.x,0,p.z)).city_id==id)
	terrain.free()
	get_window().title="City intelligence UI test (isolated; closes automatically)"
	get_window().size=Vector2i(1000,820)
	get_window().content_scale_size=Vector2i(1000,820)
	intel.open(ids[0])
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var screen=intel.screen_layer.get_child(0)
	assert(screen.selector.item_count==3)
	assert(get_viewport().get_visible_rect().encloses(screen.send.get_global_rect()))
	get_viewport().get_texture().get_image().save_png("res://artifacts/city-intelligence-ui.png")
	print("CITY_INTELLIGENCE_UI_PASS: three independent map hit targets and selector records; controls inside viewport")
	get_tree().quit()
