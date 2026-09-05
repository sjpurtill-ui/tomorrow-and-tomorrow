extends Node
func _ready()->void:
	GameState.reset_for_new_world(73129)
	DiscoverySystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	var terrain:=preload("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	await get_tree().process_frame
	await get_tree().process_frame
	terrain._set_game_speed(0.0)
	terrain.set_process(false)
	CivilizationSystem.set_process(false)
	MilitaryCampaign.set_process(false)
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[{"id":1,"unit":"levy","weapon":"improvised","count":122,"equipment":122,"training":0.4}],0.8,0.7)
	MilitaryCampaign.army_templates=[{"template_id":1,"name":"Test army","entries":[{"unit":"levy","weapon":"improvised","count":100}]}]
	var provider:RefCounted=load("res://scripts/hud/content/dock_content_military.gd").new(terrain,terrain.hud)
	for tab_index in 4:
		terrain.hud.dock.present(provider,tab_index)
		await get_tree().process_frame
	assert(String(provider.tab(0).kpis[0].value)=="122")
	provider._deploy_build(1)
	assert(int(terrain.selected_army_id)==int(MilitaryCampaign.field_armies[0].army_id))
	assert(String(provider.tab(0).kpis[0].value)=="122")
	assert(String(provider.tab(0).kpis[1].value)=="100")
	assert(MilitaryCampaign.start_training_program("route_rehearsal").has("ok"))
	MilitaryCampaign.command_development["logistics"]=0.08
	MilitaryCampaign.training_program["progress_days"]=3.0
	terrain.hud.dock.present(provider,2)
	await get_tree().process_frame
	assert(bool(SaveSystem.save_game("military_training_probe").get("ok",false)))
	MilitaryCampaign.command_development.clear()
	MilitaryCampaign.training_program.clear()
	assert(bool(SaveSystem.load_game("military_training_probe").get("ok",false)))
	assert(float(MilitaryCampaign.command_development.logistics)==0.08)
	assert(float(MilitaryCampaign.training_program.progress_days)==3.0)
	assert(MilitaryCampaign._mobilized_count()==122)
	DirAccess.remove_absolute(SaveSystem.slot_path("military_training_probe"))
	print("MILITARY_TRAINING_UI_PASS: four tabs, exact deployment, stable total, selected army, exercise and shared skills survive save/load")
	get_tree().quit()
