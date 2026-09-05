extends Node
func _ready()->void:
	GameState.reset_for_new_world(864209)
	var terrain:=preload("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	await get_tree().process_frame
	terrain._set_game_speed(0); terrain.set_process(false)
	CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var position:=CivilizationSystem.player_world_origin+Vector2(150,150)
	civ.player_relation.contact_level=2; civ.player_relation.met_day=0
	civ.player_relation.contact_source="returned_scout_report"
	civ.player_relation.encounter_position={"x":position.x-10,"z":position.y}
	civ.player_relation.home_location_known=true
	civ.player_relation.home_position={"x":position.x,"z":position.y}
	CivilizationSystem.city_intelligence.seed_known_homes()
	var fog:Array=CivilizationSystem.revealed_areas.duplicate(true)
	terrain.camera.size=300; terrain.zoom_target_size=300
	var provider=preload("res://scripts/hud/content/dock_detail_civ_report.gd").new(terrain,terrain.hud,String(civ.id))
	var clicked:=false
	for block:Dictionary in provider.tab(0).blocks:
		if block.get("type")=="actions":
			for action:Dictionary in block.items:
				if action.label=="SHOW HOME ON MAP": action.on_press.call(); clicked=true
	assert(clicked)
	terrain._refresh_contact_encounter_markers()
	assert(terrain.camera.size<=18 and terrain.zoom_target_size<0)
	assert(Vector2(terrain.camera_target.x,terrain.camera_target.z).distance_to(position)<.001)
	var city_id:=CivilizationSystem.city_intelligence.primary_id(String(civ.id))
	assert(terrain.contact_encounter_markers.has(city_id))
	assert(terrain.contact_encounter_markers[city_id].visible)
	assert(terrain.contact_encounter_markers[city_id].get_node("SettlementLabel").visible)
	assert(CivilizationSystem.revealed_areas==fog)
	print("HOME_FOCUS_PASS: actual detail action, reported location, readable label, zoom override cleared, fog unchanged")
	get_tree().quit()
