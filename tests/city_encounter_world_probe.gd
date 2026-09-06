extends "res://tests/manual_city_siege.gd"
var city_meshes:Array=[]
func meshes(node:Node)->Array:
	var result:Array=[]
	if node is MeshInstance3D:result.append(node.mesh.get_rid())
	for child in node.get_children():result.append_array(meshes(child))
	return result
func capture(name:String)->void:
	for frame in 6:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/city-world-"+name+".png")
func continuity()->void:
	assert(meshes(terrain.contact_encounter_markers[city_id])==city_meshes,"The city meshes must survive the encounter transition")
func _ready()->void:
	await super._ready()
	for frame in 10:await get_tree().process_frame
	city_meshes=meshes(terrain.contact_encounter_markers[city_id]);assert(not city_meshes.is_empty())
	await capture("approach")
	CivilizationSystem.city_intelligence.open(city_id)
	await capture("city-orders")
	CivilizationSystem.city_intelligence.screen_layer.queue_free()
	for frame in 4:await get_tree().process_frame
	var marker:Node3D=terrain.player_field_army_markers[str(army_id)]
	await click(terrain.camera.unproject_position(marker.global_position))
	for frame in 5:await get_tree().process_frame
	await click(besiege_button.get_global_rect().get_center())
	for frame in 8:await get_tree().process_frame
	var siege:CanvasLayer=get_tree().root.get_meta("persistent_siege_view")
	assert(siege.viewport.world_3d==terrain.get_world_3d());continuity()
	await capture("siege")
	await click(siege.assault.get_global_rect().get_center())
	for frame in 10:await get_tree().process_frame
	var hud:BattleGraphicsScreen=MilitaryCommandUI.battle_graphics
	assert(hud.view.live_terrain==terrain and hud.viewport.world_3d==terrain.get_world_3d());continuity()
	assert(hud.view.landscape.ground==null,"Live-world encounter must not build a second ground patch")
	await capture("assault-overview")
	await click(hud.camera_buttons.frontline.get_global_rect().get_center())
	await capture("uniforms")
	for group:Dictionary in hud.view.groups:
		var pose:Transform3D=group.batch.multimesh.get_instance_transform(0)
		var world:Vector3=hud.view.armies[group.side].to_global(pose.origin)
		assert(absf(world.y-terrain._close_surface_height_at(world.x,world.z))<.003)
		assert(group.batch.material_override.get_shader_parameter("faction_color")==hud.view.faction_colors[group.side])
	for index in hud.plates.size():
		if not hud.plates[index].node.visible:continue
		for other in range(index+1,hud.plates.size()):
			if hud.plates[other].node.visible:assert(not hud.plates[index].node.get_global_rect().intersects(hud.plates[other].node.get_global_rect()))
	await click(hud.order_buttons.hold.get_global_rect().get_center())
	await click(hud.resolve_button.get_global_rect().get_center())
	await get_tree().create_timer(1.3).timeout
	await capture("contact")
	await click(hud.skip_button.get_global_rect().get_center())
	continuity()
	await capture("round-result")
	hud._close()
	for frame in 8:await get_tree().process_frame
	continuity();await capture("return")
	print("CITY_WORLD_PASS same world and city mesh RIDs through approach, siege, assault, result and return; grounded actors; distinct factions; nonoverlapping labels")
	get_tree().quit()
