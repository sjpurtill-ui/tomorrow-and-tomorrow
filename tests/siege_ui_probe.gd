extends Node

func _ready()->void:
	GameState.reset_for_new_world(74017)
	GameState.ensure_population_total(10000)
	GameState.settlement_site_committed=true
	CivilizationSystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	MilitaryCampaign.settlement_defense["stage"]=2
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation["at_war"]=true
	MilitaryCampaign._create_civilization_threat({"source_civ_id":civ.id,"source_name":civ.name,"strength":1000,"incident_kind":"campaign"},"defensive")
	assert(MilitaryCampaign.begin_siege().get("ok",false))
	MilitaryCampaign.active_siege["days"]=42
	MilitaryCampaign.active_siege["blockade"]=.72
	MilitaryCampaign.active_siege["pressure"]=.3
	GameState.simulation_metrics["food_days"]=14.5
	var dock:=preload("res://scripts/hud/dock_panel.gd").new()
	get_window().size=Vector2i(640,900)
	get_window().content_scale_size=Vector2i(640,900)
	dock.position=Vector2(20,12); dock.size=Vector2(600,876)
	add_child(dock)
	var content:=preload("res://scripts/hud/content/dock_detail_war_planning.gd").new(null,null)
	dock.present(content)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/siege-ui.png")
	print("SIEGE_UI_PASS")
	get_tree().quit()
