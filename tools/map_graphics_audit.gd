extends Node
func _arg(prefix:String,fallback:String)->String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix): return argument.trim_prefix(prefix)
	return fallback
func _ready()->void:
	GameState.reset_for_new_world(864209)
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	GameState.select_founding_focus("provision")
	var terrain:=preload("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	await get_tree().process_frame
	terrain._set_game_speed(0.0)
	terrain.set_process(false)
	CivilizationSystem.set_process(false)
	MilitaryCampaign.set_process(false)
	terrain.camera_target=terrain.settler_marker.position
	if "--river" in OS.get_cmdline_user_args():
		var river_z:=float(_arg("--river-z=","0"))
		var river_x:float=terrain._world_river_x(river_z)+float(_arg("--river-bank=","0"))
		terrain.camera_target=Vector3(river_x,terrain._height_at(river_x,river_z),river_z)
		var water:MeshInstance3D=terrain.get_node("RiverWater")
		var vertices:PackedVector3Array=water.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for segment in range(0,6080,137):
			var midpoint:Vector3=(vertices[segment*6]+vertices[segment*6+5])*0.5
			assert(terrain._main_river_distance_at(midpoint.x,midpoint.z)<0.001,"Rendered main river must match water-access geography")
		print("RIVER_AUDIT sampled authoritative course, main segments=6080")
	terrain.camera.size=float(_arg("--span=","5"))
	terrain.camera_pitch=deg_to_rad(-50.0)
	terrain._update_camera()
	if "--aerial" in OS.get_cmdline_user_args(): terrain._inspect_aerial_altitude()
	terrain._update_scale_lod()
	if "--aerial" in OS.get_cmdline_user_args():
		assert(absf(terrain.aerial_altitude_feet()-10000.0)<1.0,"Aerial altitude must follow actual land below the camera")
	var center:=get_viewport().get_visible_rect().size*0.5
	var before:Dictionary=terrain._terrain_hit(center)
	assert(not before.is_empty(),"Perspective picking must find terrain")
	var saved_span:float=terrain.camera.size
	terrain._zoom_camera_at_screen(center,saved_span*0.75)
	var after:Dictionary=terrain._terrain_hit(center)
	assert(not after.is_empty())
	assert((before.position as Vector3).distance_to(after.position)<0.03,"Zoom must preserve the point under the pointer")
	terrain._zoom_camera_at_screen(center,saved_span)
	if "--aerial" in OS.get_cmdline_user_args(): terrain._inspect_aerial_altitude()

	if "--war" in OS.get_cmdline_user_args():
		var center_position:Vector3=terrain.camera_target
		MilitaryCampaign.field_armies=[{"army_id":1,"name":"RIVER GUARD","troops":320,"position":{"x":center_position.x,"z":center_position.z},"status":"stationed","location_id":"player_home","supply_level":0.84,"formations":[{"unit":"line_infantry","count":320}]}]
		terrain.selected_army_id=1
		terrain._refresh_player_field_army_markers()
	terrain.hud.visible="--show-hud" in OS.get_cmdline_user_args()
	if terrain.settler_marker: terrain.settler_marker.visible=false
	for frame in 2000:
		terrain._update_world_streaming()
		terrain._advance_terrain_patch()
		if terrain.terrain_patch_job==null:
			terrain._update_world_streaming()
			if terrain.terrain_patch_job==null: break
		await get_tree().process_frame
	terrain._update_scale_lod()
	if "--revealed" in OS.get_cmdline_user_args():
		var mask:=Image.create(2,2,false,Image.FORMAT_RGBA8)
		mask.fill(Color.WHITE)
		var texture:=ImageTexture.create_from_image(mask)
		for material in terrain.terrain_fog_materials: material.set_shader_parameter("discovery_mask",texture)
	if _arg("--cut-retained=","")!="":
		var retained:=float(_arg("--cut-retained=","1"))
		var supply:=ResourceSystem._deposit("Timber",terrain.camera_target,0.8,1000.0,999)
		supply["landscape_source"]="woodland_catchment"
		supply["area_km2"]=9.0
		supply["remaining"]=1000.0*retained
		GameState.resource_deposits.append(supply)
		terrain._refresh_woodland_visuals(true)
		var base:float=terrain._biome_at(terrain.camera_target.x,terrain.camera_target.z).woodland
		assert(absf(terrain._woodland_density_at(terrain.camera_target.x,terrain.camera_target.z)-base*retained)<0.001,"Inspection must reflect saved harvest depletion")
		print("CUTTING_AUDIT retained=",retained," current_cover=",terrain._woodland_density_at(terrain.camera_target.x,terrain.camera_target.z))
	if "--outcrop" in OS.get_cmdline_user_args():
		CivilizationSystem.record_player_travel(Vector2(terrain.camera_target.x,terrain.camera_target.z))
		var crop:MeshInstance3D=terrain._resource_ground_indication({"resource":_arg("--rock=","Limestone"),"visual_stage":"surveyed","position":terrain.camera_target})
		terrain.add_child(crop)
		assert(crop.has_node("ExposedRockFaces"),"Rock occurrence must have physical outcrop geometry")
	if "--resources" in OS.get_cmdline_user_args():
		terrain._set_resource_view_enabled(true)
		terrain._refresh_discovered_resource_overlays()
		assert(terrain.resource_overlay_root.find_children("*","Sprite3D",true,false).is_empty(),"Land resources must not create billboard icons")
		for offset in [Vector2.ZERO,Vector2(0.5,0.5),Vector2(-1.0,0.5)]:
			var point:Vector2=Vector2(terrain.camera_target.x,terrain.camera_target.z)+offset
			var height:float=terrain._height_at(point.x,point.y)
			var tint:Color=terrain._terrain_color_at(point.x,point.y,height)
			assert(absf(tint.a-float(terrain._biome_at(point.x,point.y,height).woodland))<0.001,"Forest shading must carry the surveyed woodland density")
		CivilizationSystem.record_player_travel(Vector2(terrain.camera_target.x,terrain.camera_target.z))
		terrain._inspect_location(terrain.camera_target)
		assert(terrain.lens_panel!=null and terrain.lens_panel.visible,"Ground inspection must open its visible report")
		assert("tree cover" in terrain.lens_body.text or "RIVER CHANNEL" in terrain.lens_body.text,"Ground inspection must describe woodland independently of deposits")
		print("LAND_RESOURCE_AUDIT no icons; biome density matches terrain; catchment=",terrain._woodland_catchment(terrain.camera_target))
	for frame in 24: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output:=ProjectSettings.globalize_path(_arg("--output=","res://map_aerial_audit.png"))
	get_viewport().get_texture().get_image().save_png(output)
	print("MAP_AUDIT camera=",terrain.camera.position," target=",terrain.camera_target," span=",terrain.camera.size," image=",output)
	get_tree().quit()
