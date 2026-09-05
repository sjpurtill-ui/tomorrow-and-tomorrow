extends Node
func _ready()->void:
	assert(SaveSystem.load_game().has("ok"))
	GameState.civic_api_enabled=false
	var ci:=CivilizationSystem._civilization_index("civ_14")
	var relation:Dictionary=CivilizationSystem.civilizations[ci].player_relation
	print("ACTUAL_INTRUSION_STATE=",JSON.stringify({"day":GameState.elapsed_days,"population":GameState.population_total,"war":relation.get("at_war"),"treaty":relation.get("treaty"),"stance":relation.get("stance"),"armies":MilitaryCampaign.field_armies,"siege":MilitaryCampaign.active_siege,"engagement":MilitaryCampaign.active_engagement.get("status","none")}))

	var terrain:=preload("res://local_terrain.tscn").instantiate();add_child(terrain);terrain._set_game_speed(0)
	CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	var before:Dictionary=CivilizationSystem.city_intelligence.records.duplicate(true)
	for dimensions in [Vector2i(1280,720),Vector2i(1000,820)]:
		get_window().size=dimensions;get_window().content_scale_size=dimensions
		CivilizationSystem.city_intelligence.open("civ_14_region_05","civ_14")
		for frame in 12:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var screen=CivilizationSystem.city_intelligence.screen_layer.get_child(0)
		assert(screen.city_id=="civ_14_region_05")
		for control in [screen.send,screen.feedback,screen.cards.damage.note,screen.siege]:
			if control.is_visible_in_tree():
				if not get_viewport().get_visible_rect().encloses(control.get_global_rect()):print("OUTSIDE ",control.text," ",control.get_global_rect())
				assert(get_viewport().get_visible_rect().encloses(control.get_global_rect()))
		assert(CivilizationSystem.city_intelligence.records==before)
		get_viewport().get_texture().get_image().save_png("res://artifacts/foreign-report-%d.png" % dimensions.x)
	# Exercise the actual saved army's report action in this isolated process only.
	var live_screen=CivilizationSystem.city_intelligence.screen_layer.get_child(0)
	if not MilitaryCampaign.field_armies.is_empty():
		var army_population:=GameState.population_total
		live_screen._march()
		assert(MilitaryCampaign.field_armies[0].location_id=="civ_14_region_05")
		assert(MilitaryCampaign.offensive_campaign_availability("civ_14","civ_14_region_05").has("ok"))
		var battle:=MilitaryCampaign.launch_offensive("civ_14","civ_14_region_05")
		assert(not battle.has("error"))
		assert(CivilizationSystem.civilizations[ci].player_relation.at_war)
		assert(GameState.population_total==army_population)
		print("ACTUAL_SAVED_ARMY_ATTACK_PASS named arrival, surprise attack, war recorded, no population created; isolated only")
		MilitaryCampaign.active_engagement.clear();MilitaryCampaign.active_threat.clear()
	# Isolated reproduction: an army on marked ground inside the reported city.
	var city:Dictionary=CivilizationSystem.city_intelligence.known("player","civ_14_region_05")
	MilitaryCampaign.field_armies=[{"army_id":991,"name":"Probe field army","troops":6,"status":"stationed","location_id":"field_position","position":city.position.duplicate(true)}]
	assert(not MilitaryCampaign._movement_destination("civ_14_region_05").is_empty())
	var result:=MilitaryCampaign.move_field_army(991,"civ_14_region_05")
	assert(result.has("ok"));assert(MilitaryCampaign.field_armies[0].location_id=="civ_14_region_05")
	assert(MilitaryCampaign.field_armies[0].troops==6)
	get_window().size=Vector2i(1280,720);get_window().content_scale_size=Vector2i(1280,720)
	CivilizationSystem.city_intelligence.open("civ_14_region_05","civ_14")
	for frame in 12:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var screen=CivilizationSystem.city_intelligence.screen_layer.get_child(0)
	assert(screen.attack.visible and screen.siege.visible)
	assert(get_viewport().get_visible_rect().encloses(screen.siege.get_global_rect()))
	assert(CivilizationSystem.city_intelligence.records==before)
	get_viewport().get_texture().get_image().save_png("res://artifacts/foreign-report-military.png")
	print("FOREIGN_REPORT_PASS actual Fallow Moor, 1280x720 and 1000x820, unchanged evidence; synthetic nearby army receives named objective; visible attack/siege with blocker: ",screen.military_note.text)
	get_tree().quit()
