extends "res://tests/ground_surface_probe.gd"
## Capture-only: real streaming/camera path, old geometry comparison, and hidden
## geography controls. No main player scene, saves, or interactive audit window.
const LOD:=preload("res://scripts/terrain_lod.gd")
func _ready()->void:
	output="res://artifacts/terrain-lod/"
	get_window().title="TEST — Terrain distance audit"
	get_window().mode=Window.MODE_MINIMIZED
	call_deferred("run")
func covered(terrain:Terrain)->bool:
	var rect:=terrain.get_viewport().get_visible_rect()
	for corner:Vector2 in [Vector2.ZERO,Vector2(rect.end.x,0),rect.end,Vector2(0,rect.end.y)]:
		var ray:=terrain.camera.project_ray_normal(corner);var start:=terrain.camera.project_ray_origin(corner)
		var hit:=start+ray*((terrain.camera_target.y-start.y)/ray.y)
		if absf(hit.x-terrain.regional_patch_center.x)>terrain.regional_patch_span*.5 or absf(hit.z-terrain.regional_patch_center.y)>terrain.regional_patch_span*.5:return false
	return true
func stream(terrain:Terrain,label:String)->void:
	var start:=Time.get_ticks_msec();var preview_ms:=-1;var frames:Array[float]=[]
	var commits:Array[Dictionary]=[];var last_resolution:=terrain.regional_patch_resolution
	# The guarded background renderer shares the host with a live player. Bound
	# elapsed time as well as iterations: frame count alone prematurely timed out
	# valid fine refinement under host load, then indexed an unfinished cache.
	for frame in 12000:
		if Time.get_ticks_msec()-start>180000:break
		var frame_start:=Time.get_ticks_usec()
		terrain._update_world_streaming();terrain._advance_terrain_patch();terrain._update_scale_lod()
		if last_resolution!=terrain.regional_patch_resolution:
			commits.append({"resolution":terrain.regional_patch_resolution,"elapsed_ms":Time.get_ticks_msec()-start,"upload_us":terrain.terrain_patch_last_commit_usec})
			last_resolution=terrain.regional_patch_resolution
		if covered(terrain) and preview_ms<0:preview_ms=Time.get_ticks_msec()-start
		var desired:=LOD.bucket(LOD.view_span(terrain.camera.size,1.5,terrain.camera_pitch))
		if terrain.terrain_patch_job==null and covered(terrain) and is_equal_approx(terrain.regional_patch_span,desired) and terrain.regional_patch_resolution==LOD.resolution_for(desired):break
		await get_tree().process_frame
		frames.append(float(Time.get_ticks_usec()-frame_start)/1000.0)
	frames.sort()
	check(terrain.terrain_patch_job==null and covered(terrain),label+" refines to complete visible coverage")
	check(terrain.regional_terrain_patch.visible,label+" actual terrain remains visible")
	print("LOD_STREAM ",JSON.stringify({"label":label,"frames":frames.size(),"preview_ms":preview_ms,"ready_ms":Time.get_ticks_msec()-start,"resolution":terrain.regional_patch_resolution,"span":terrain.regional_patch_span,"spacing_km":terrain.regional_patch_span/float(terrain.regional_patch_resolution-1),"max_slice_us":terrain.terrain_patch_last_slice_usec,"commits_us":commits,"frame_p95_ms":frames[int(frames.size()*.95)] if not frames.is_empty() else 0}))
func run()->void:
	for node:Node in [GameState,MilitaryCampaign,CivilizationSystem]:node.set_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var canvas:=view();var terrain:=setup(873421);canvas.add_child(terrain);terrain.discovery_mask_texture=white_fog()
	terrain._build_terrain();terrain._build_water();var camera:=Camera3D.new();canvas.add_child(camera);terrain.camera=camera
	var point:=Vector2(55,0);terrain.camera_target=Vector3(point.x,terrain._height_at(point.x,point.y),point.y)
	for index:int in [3,2,1,0]:
		terrain.set_camera_distance_level(index);camera.size=terrain.zoom_target_size;terrain.zoom_preset_active=false;terrain.zoom_target_size=-1;terrain._update_camera()
		# Prior production geometry and cutout, using the same updated materials.
		if index>=2:
			if index==2:
				var span:=clampf(LOD.bucket(camera.size*2.9),.9,920)
				var old:=BUILDER.new(161,span,LOD.center_for(point,span),terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at)
				while not old.advance(5000):await get_tree().process_frame
				terrain._install_regional_patch({"mesh":old.commit(),"center":old.center,"span":span,"resolution":161,"heights":old.heights})
				terrain.province_terrain_mesh.material_override.set_shader_parameter("streamed_cutout",Vector4(old.center.x,old.center.y,span,1))
			else:
				terrain.province_terrain_mesh.material_override.set_shader_parameter("streamed_cutout",Vector4.ZERO)
				if terrain.regional_terrain_patch:terrain.regional_terrain_patch.visible=false
			await settle();canvas.get_texture().get_image().save_png(output+"distance-"+str(index)+"-before.png")
			# Restore the prior continental view after the old-region comparison so
			# the live pipeline must supply every new regional refinement stage.
			if index==2:terrain._install_regional_patch(terrain.terrain_patch_cache[0])
		await stream(terrain,"distance-"+str(index));await settle()
		if errors>0:
			canvas.queue_free();WorldSimulation.clear();get_tree().quit(errors);return
		canvas.get_texture().get_image().save_png(output+"distance-"+str(index)+"-after.png")
	# A covered pan should preserve the finished mesh while the shared sample
	# lattice supplies the next fine patch. Exercise the real request/install path.
	var old_mesh:MeshInstance3D=terrain.regional_terrain_patch
	terrain.camera_target.x+=terrain.regional_patch_span/12.0
	terrain._update_camera();terrain._update_world_streaming()
	check(terrain.terrain_patch_job!=null and terrain.terrain_patch_job.resolution==terrain.regional_patch_resolution,"covered pan requests full detail without a coarse replacement")
	terrain._advance_terrain_patch()
	check(terrain.regional_terrain_patch==old_mesh,"finished terrain stays visible during pan refinement")
	await stream(terrain,"pan-close");await settle()
	check(terrain.terrain_patch_last_reused_vertices>130000,"live pan reuses the overlapping completed samples")
	canvas.get_texture().get_image().save_png(output+"pan-close-after.png")
	# Cached and cancelled requests must still leave the real fallback behind.
	terrain.set_camera_distance_level(3);camera.size=terrain.zoom_target_size;terrain.zoom_target_size=-1;terrain._update_camera()
	terrain._update_world_streaming();terrain._advance_terrain_patch()
	terrain.camera_target.x+=8000;terrain._update_camera();terrain._update_world_streaming();terrain._update_scale_lod()
	check(terrain.province_terrain_mesh.visible,"global fallback remains during a cancelled/uncached view")
	check(terrain.terrain_patch_cancellations>0,"stale view job was cancelled")
	canvas.queue_free();await settle()
	# Same unlit fog must conceal land shape AND the shoreline, not only tint.
	canvas=view();terrain=setup(873421);canvas.add_child(terrain)
	var black:=Image.create(2,2,false,Image.FORMAT_RGBA8);black.fill(Color.BLACK);terrain.discovery_mask_texture=ImageTexture.create_from_image(black)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.6;camera.near=.05;camera.far=20;camera.position=Vector3(2000,10,0);canvas.add_child(camera);camera.look_at(Vector3(2000,0,0),Vector3.FORWARD)
	var concealed:Array[PackedByteArray]=[]
	for mode in 3:
		var mesh:=BUILDER.new(65,2.0,Vector2(2000,0),func(x:float,z:float)->float:return .25+(sin(x*10)*cos(z*6)*.15 if mode==0 else (0.0 if mode==1 else -.5)),func(_x:float,_z:float,_h:float)->Color:return Color(.4,.3,.2,0),func(_x:float,_z:float,_h:float)->Vector4:return Vector4(1.2,.8,.5,.3))
		while not mesh.advance(5000):await get_tree().process_frame
		terrain._install_regional_patch({"mesh":mesh.commit(),"center":mesh.center,"span":mesh.span,"resolution":mesh.resolution,"heights":mesh.heights})
		if mode==0:terrain._build_water()
		for material:ShaderMaterial in terrain.terrain_fog_materials:material.set_shader_parameter("fog_current_origin",Vector2(-2000,1000))
		terrain.coastal_water_material.set_shader_parameter("wave_speed",0.0)
		terrain.ocean_surface.material_override.set_shader_parameter("wave_speed",0.0)
		await settle();var picture:=canvas.get_texture().get_image();picture.save_png(output+"fog-"+str(mode)+".png");concealed.append(picture.get_data())
	check(concealed[0]==concealed[1] and concealed[1]==concealed[2],"unknown mountains, plains and ocean produce identical pixels")
	# A patch straddling the finite world edge must not invent land outside it.
	var edge:=Vector2(terrain.world_width*.5,0);var build:=BUILDER.new(33,2,edge,func(_x:float,_z:float)->float:return .2,func(_x:float,_z:float,_h:float)->Color:return Color(.4,.3,.2,0),func(_x:float,_z:float,_h:float)->Vector4:return Vector4(1.2,.8,.5,.3))
	while not build.advance(5000):await get_tree().process_frame
	terrain._install_regional_patch({"mesh":build.commit(),"center":edge,"span":2.0,"resolution":33,"heights":build.heights})
	for material:ShaderMaterial in terrain.terrain_fog_materials:material.set_shader_parameter("discovery_mask",white_fog())
	camera.position=Vector3(edge.x,10,0);camera.look_at(Vector3(edge.x,0,0),Vector3.FORWARD)
	await settle();var boundary:=canvas.get_texture().get_image();boundary.save_png(output+"planet-edge.png")
	terrain.regional_terrain_patch.visible=false;await settle();var ocean:=canvas.get_texture().get_image()
	check(boundary.get_pixel(800,360)==ocean.get_pixel(800,360),"streamed terrain stops at physical planet boundary")
	check(boundary.get_pixel(280,360)!=ocean.get_pixel(280,360),"land remains inside physical planet boundary")
	canvas.queue_free();await settle();WorldSimulation.clear();print("TERRAIN_LOD_CAPTURE ","PASS" if errors==0 else "FAIL");get_tree().quit(errors)
