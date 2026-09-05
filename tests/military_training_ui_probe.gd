extends Node
func _ready()->void:
	GameState.reset_for_new_world(73129)
	GameState.select_founding_focus("provision")
	DiscoverySystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	PeopleDirection.choose("military")
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
	terrain.hud.open_dock("military",1)
	terrain.hud.dock.present(provider,1)
	await get_tree().process_frame
	var live_bindings:Array=[]
	_collect_bindings(terrain.hud.dock,live_bindings)
	var deploy_button:Button
	for binding:Node in live_bindings:
		if binding.property=="disabled" and binding.target is Button:
			deploy_button=binding.target
	assert(deploy_button!=null and not deploy_button.disabled)
	var button_id:=deploy_button.get_instance_id()
	MilitaryCampaign.pending_aftermath={"test":"pending"}
	for binding:Node in live_bindings: binding.refresh()
	assert(deploy_button.disabled and deploy_button.tooltip_text.contains("aftermath"))
	MilitaryCampaign.pending_aftermath.clear()
	for binding:Node in live_bindings: binding.refresh()
	assert(not deploy_button.disabled and deploy_button.get_instance_id()==button_id)
	assert(String(provider.tab(0).kpis[0].value)=="122")
	terrain.camera.size=12000.0
	terrain.zoom_target_size=14000.0
	var fog:Array=CivilizationSystem.revealed_areas.duplicate(true)
	provider._deploy_build(1)
	assert(not terrain.hud.dock.visible)
	assert(terrain.camera.size<=18.0 and terrain.zoom_target_size<0.0)
	assert(CivilizationSystem.revealed_areas==fog)
	assert(terrain.player_field_army_markers[str(terrain.selected_army_id)].visible)
	assert(terrain.camera_target.distance_to(Vector3(float(MilitaryCampaign.field_armies[0].position.x),terrain.camera_target.y,float(MilitaryCampaign.field_armies[0].position.z)))<.001)
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/deployed-army.png")
	assert(int(terrain.selected_army_id)==int(MilitaryCampaign.field_armies[0].army_id))
	assert(String(provider.tab(0).kpis[0].value)=="122")
	assert(String(provider.tab(0).kpis[1].value)=="100")
	var army_copy:Dictionary=MilitaryCampaign.field_armies[0].duplicate(true)
	var known:Dictionary=army_copy.position.duplicate(true)
	MilitaryCampaign.field_armies[0].status="moving"
	MilitaryCampaign.field_armies[0].location_id="field"
	MilitaryCampaign.field_armies[0].position={"x":float(known.x)+400,"z":float(known.z)+400}
	terrain._select_army_and_focus(int(army_copy.army_id))
	assert(Vector2(terrain.camera_target.x,terrain.camera_target.z).distance_to(Vector2(float(known.x),float(known.z)))<.001,"Focus leaked live coordinates past runner report")
	assert(CivilizationSystem.revealed_areas==fog)
	MilitaryCampaign.field_armies[0]=army_copy
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

func _collect_bindings(node:Node,result:Array)->void:
	if node.get_script()==preload("res://scripts/hud/live_value_binding.gd"): result.append(node)
	for child:Node in node.get_children(): _collect_bindings(child,result)
