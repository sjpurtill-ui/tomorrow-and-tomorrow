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
	if "--surface-supplies" in OS.get_cmdline_user_args():
		var fields:Dictionary=terrain._surface_material_catchments(terrain.camera_target)
		GameState.resource_deposits=[]
		ResourceSystem._ensure_surface_material_supplies({"settled":true,"origin":terrain.camera_target,"surface_material_catchments":fields})
		for resource in ["Stone","Fiber Plants"]:
			if float(fields[resource].density)<(0.03 if resource=="Stone" else 0.08): continue
			var found:=false
			for deposit in GameState.resource_deposits:
				if String(deposit.resource)==resource: found=true
			assert(found,"Surface terrain must produce the matching local source")
		print("SURFACE_SUPPLY_AUDIT fields=",fields," sources=",GameState.resource_deposits.size())
	if "--river-cpu-drape" in OS.get_cmdline_user_args():
		var height_field:Image=terrain.river_terrain_height_texture.get_image()
		var height_grid:Vector4=terrain.river_terrain_grid
		for river in terrain.river_overlays:
			var arrays:Array=river.mesh.surface_get_arrays(0)
			var positions:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			for index in positions.size():
				var point:=positions[index]
				if maxf(absf(point.x-height_grid.x),absf(point.z-height_grid.y))<height_grid.z*0.49:
					point.y=_grid_height(height_field,height_grid,point)+(0.0037 if river.name=="RiverWater" else 0.0021)
					positions[index]=point
			arrays[Mesh.ARRAY_VERTEX]=positions
			var mesh:=ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			river.mesh=mesh
			var material:ShaderMaterial=river.material_override
			material.shader.code=material.shader.code.replace("if(terrain_grid.z>0.0", "if(false && terrain_grid.z>0.0")
	if "--river-samples" in OS.get_cmdline_user_args():
		var field:Image=terrain.river_terrain_height_texture.get_image()
		var grid:Vector4=terrain.river_terrain_grid
		var water:MeshInstance3D=terrain.get_node("RiverWater")
		var mesh_points:PackedVector3Array=water.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var maximum_gap:=0.0
		for index in range(0,6080*6,3):
			var a:=mesh_points[index]
			var b:=mesh_points[index+1]
			var c:=mesh_points[index+2]
			if Vector2(a.x,a.z).distance_to(Vector2(terrain.camera_target.x,terrain.camera_target.z))>3.0: continue
			var triangle_center:Vector3=(a+b+c)/3.0
			var corner_height:=(_grid_height(field,grid,a)+_grid_height(field,grid,b)+_grid_height(field,grid,c))/3.0
			maximum_gap=maxf(maximum_gap,_grid_height(field,grid,triangle_center)-corner_height)
		print("RIVER_SURFACE_GAP ",maximum_gap," near=",terrain.camera.near," far=",terrain.camera.far)
	if "--river-lift" in OS.get_cmdline_user_args():
		for river in terrain.river_overlays:
			var material:ShaderMaterial=river.material_override
			material.shader.code=material.shader.code.replace("(river_water?0.0037:0.0021)","0.05")
		print("RIVER_GRID ",terrain.river_terrain_grid," height range center=",terrain.river_terrain_height_texture.get_image().get_pixel(int(terrain.river_terrain_grid.w)/2,int(terrain.river_terrain_grid.w)/2))
	if "--river-depth" in OS.get_cmdline_user_args():
		for river in terrain.river_overlays:
			var material:ShaderMaterial=river.material_override
			material.shader.code=material.shader.code.replace(", depth_test_disabled", "")
	if "--hide-rivers" in OS.get_cmdline_user_args():
		for river in terrain.river_overlays: river.visible=false
	if "--no-terrain-shadows" in OS.get_cmdline_user_args():
		terrain.regional_terrain_patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		terrain.province_terrain_mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if "--hide-ocean" in OS.get_cmdline_user_args():
		for child in terrain.get_children():
			if child is MeshInstance3D and child.mesh is PlaneMesh and child.mesh.size.x>1000.0:
				print("HIDDEN_PLANE ",child.name," y=",child.position.y)
				child.visible=false
	if "--flat-terrain" in OS.get_cmdline_user_args():
		var plain:=StandardMaterial3D.new()
		plain.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		plain.albedo_color=Color(0.5,0.6,0.4)
		terrain.regional_terrain_patch.material_override=plain
	for frame in 24: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output:=ProjectSettings.globalize_path(_arg("--output=","res://map_aerial_audit.png"))
	get_viewport().get_texture().get_image().save_png(output)
	print("MAP_AUDIT camera=",terrain.camera.position," target=",terrain.camera_target," span=",terrain.camera.size," image=",output)
	get_tree().quit()

func _grid_height(field:Image,grid:Vector4,point:Vector3)->float:
	var coord:Vector2=(Vector2(point.x,point.z)-Vector2(grid.x,grid.y))/grid.z+Vector2(0.5,0.5)
	coord*=grid.w-1.0
	var x:=clampi(floori(coord.x),0,int(grid.w)-2)
	var y:=clampi(floori(coord.y),0,int(grid.w)-2)
	var f:=coord-Vector2(x,y)
	var a:=field.get_pixel(x,y).r
	var b:=field.get_pixel(x+1,y).r
	var c:=field.get_pixel(x+1,y+1).r
	var d:=field.get_pixel(x,y+1).r
	if (x+y)%2==0:
		return a+(b-a)*f.x+(c-b)*f.y if f.x>=f.y else a+(c-d)*f.x+(d-a)*f.y
	return a+(b-a)*f.x+(d-a)*f.y if f.x+f.y<=1.0 else c+(d-c)*(1.0-f.x)+(b-c)*(1.0-f.y)
