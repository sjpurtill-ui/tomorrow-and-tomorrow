extends "res://tests/terrain_precision_probe.gd"
## Real seeded sites, live mesh/crown shaders and the actual four-distance camera.
func _ready()->void:
	output="res://artifacts/seasonal-landscape/"
	get_window().title="TEST — Seasonal landscape audit";get_window().mode=Window.MODE_MINIMIZED;call_deferred("run")
func snapshot_plants(terrain:Node)->Array:
	var result:Array=[]
	if terrain.close_vegetation_root==null:return result
	for node:Node in terrain.close_vegetation_root.get_children():
		if node is MultiMeshInstance3D:
			for i in node.multimesh.instance_count:
				result.append([node.name,node.multimesh.get_instance_transform(i),node.multimesh.get_instance_color(i),node.multimesh.get_instance_custom_data(i)])
	return result
func run()->void:
	for node:Node in [GameState,MilitaryCampaign,CivilizationSystem]:node.set_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var sites:Dictionary={"drylands":Vector2(6600,-3280),"cold_barrens":Vector2(-17400,-7790)}
	var seeker:=setup(873421)
	for z in range(-6200,6201,200):
		for x in range(-12000,12001,400):
			var h:=seeker._height_at(x,z)
			if h<.1:continue
			var biome:=seeker._biome_at(x,z,h)
			var point:=Vector2(x,z)
			if biome.woodland>.6 and biome.temperature>.35 and biome.temperature<.58:
				var label:="north_woodland" if z<0 else "south_woodland"
				if not sites.has(label):sites[label]=point
			if biome.precipitation>.65 and biome.temperature>.86 and not sites.has("tropical_woodland"):sites.tropical_woodland=point
			if biome.precipitation>.42 and biome.precipitation<.55 and biome.temperature>.35 and biome.temperature<.52 and not sites.has("grassland"):sites.grassland=point
	seeker.free()
	for label:String in ["north_woodland","south_woodland","tropical_woodland","grassland"]:check(sites.has(label),"actual generated "+label+" found")
	for label:String in sites:
		var point:Vector2=sites[label];var canvas:=view();var terrain:=setup(873421);canvas.add_child(terrain);terrain.discovery_mask_texture=white_fog()
		var camera:=Camera3D.new();canvas.add_child(camera);terrain.camera=camera
		var h:=terrain._height_at(point.x,point.y);var climate:=terrain._climate_at(point.x,point.y,h)
		var profile:=PlanetEnvironment.profile_at(point,{"height":h,"temperature":climate.temperature,"precipitation":climate.precipitation})
		terrain.camera_target=Vector3(point.x,h,point.y);terrain.set_camera_distance_level(0);camera.size=terrain.zoom_target_size;terrain.zoom_target_size=-1;terrain._update_camera()
		var lod=terrain.TERRAIN_LOD;var span:float=lod.bucket(lod.view_span(camera.size,1.5,terrain.camera_pitch));var center:Vector2=lod.center_for(point,span)
		var builder:=BUILDER.new(lod.resolution_for(span),span,center,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at,terrain._terrain_seasonality_at)
		while not builder.advance(5000):await get_tree().process_frame
		terrain._install_regional_patch({"mesh":builder.commit(),"center":center,"span":span,"resolution":builder.resolution,"heights":builder.heights})
		terrain._build_detail_terrain_patch(Vector3(point.x,h,point.y));terrain._update_scale_lod()
		var geometry:RID=terrain.regional_terrain_patch.mesh.get_rid()
		var plants:=snapshot_plants(terrain)
		var images:Dictionary={}
		for day:float in [91.25,273.75]:
			GameState.elapsed_days=day;terrain._refresh_seasonal_visuals();await settle()
			var picture:=canvas.get_texture().get_image();picture.save_png(output+label+"-day-"+str(int(day))+".png");images[int(day)]=picture
			print("SEASONAL_SITE ",JSON.stringify({"label":label,"seed":873421,"point":str(point),"height":h,"biome":terrain._biome_at(point.x,point.y,h).id,"rain":climate.precipitation,"warmth":climate.temperature,"seasonality_c":profile.seasonality_c,"day":day,"temperature_c":PlanetEnvironment.ambient_temperature_c(profile,day),"altitude_km":camera.position.y-h,"plants":plants.size(),"builder_slice_us":builder.max_slice_usec}))
		check(geometry==terrain.regional_terrain_patch.mesh.get_rid() and plants==snapshot_plants(terrain),label+" calendar leaves geometry and crown identities unchanged")
		var change:=difference(images[91],images[273]);print("SEASONAL_IMAGE_CHANGE ",label," ",change)
		if label in ["drylands","tropical_woodland","cold_barrens"]:check(change<.0005,label+" does not acquire an invented winter climate or green desert")
		else:check(change>.001,label+" visibly responds to its real seasonal temperature")
		if label in ["north_woodland","south_woodland"]:
			var early:=average(images[91]);var late:=average(images[273])
			check(early.g/early.r>late.g/late.r+.02 if label=="north_woodland" else late.g/late.r>early.g/early.r+.02,label+" is greener in its own hemisphere's warm season")
		# Pause/repeat is pixel identical: no wall-time seasonal animation.
		await settle();check(images[273].get_data()==canvas.get_texture().get_image().get_data(),label+" stays visually fixed while calendar is paused")
		if label=="north_woodland":
			# Explicit close diagnostic of existing rendered crown art, not a player view.
			camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.30;camera.near=.01;camera.far=20
			camera.position=Vector3(point.x,h+1,point.y);camera.basis=Basis(Vector3.RIGHT,Vector3(0,0,-1),Vector3.UP)
			# The aerial views correctly defer this layer. Build it now so the
			# crown diagnostic cannot silently pass with no crowns on screen.
			terrain._rebuild_close_vegetation(Vector3(point.x,h,point.y));terrain._update_scale_lod()
			var diagnostic_plants:=snapshot_plants(terrain)
			check(not diagnostic_plants.is_empty(),"close seasonal diagnostic includes actual woodland plants")
			for day:float in [91.25,273.75]:
				GameState.elapsed_days=day;terrain._refresh_seasonal_visuals();await settle();canvas.get_texture().get_image().save_png(output+"crown-diagnostic-"+str(int(day))+".png")
				check(diagnostic_plants==snapshot_plants(terrain),"close seasonal diagnostic retains plant identities at day "+str(day))
			# Seasonal color cannot disclose vegetation/ground through fog.
			var fog:=Image.create(2,2,false,Image.FORMAT_RGBA8);fog.fill(Color.BLACK)
			for reference:WeakRef in terrain.woodland_visual_materials:
				var material:ShaderMaterial=reference.get_ref()
				if material:material.set_shader_parameter("discovery_mask",ImageTexture.create_from_image(fog));material.set_shader_parameter("fog_current_origin",Vector2(1000,1000))
			await settle();var hidden:=canvas.get_texture().get_image()
			GameState.elapsed_days=91.25;terrain._refresh_seasonal_visuals();await settle();check(hidden.get_data()==canvas.get_texture().get_image().get_data(),"fog conceals seasonal ground and foliage changes")
		canvas.queue_free();await settle()
	WorldSimulation.clear();print("SEASONAL_LANDSCAPE_CAPTURE ","PASS" if errors==0 else "FAIL");get_tree().quit(errors)
