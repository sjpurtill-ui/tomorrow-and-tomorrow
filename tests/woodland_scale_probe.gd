extends "res://tests/ground_surface_probe.gd"
## Land-material comparison on the actual terrain/camera path. No player saves.
## Water is deliberately absent from this material control; terrain_lod_probe
## separately captures complete land/water scenes at all four actual distances.
var baseline:=false
var receipts:Array[Dictionary]=[]

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("TomorrowCanopyTransitionTests") or OS.get_environment("TT_CAPTURE_OWNER")!="canopy-transition" or OS.get_executable_path().get_file()!="GodotCanopyProbe":
		push_error("Use the verified private Mac landscape capture runner.");get_tree().quit(2);return
	baseline=OS.get_environment("TT_WOODLAND_BASELINE")=="1"
	output="res://artifacts/woodland-scale/"
	call_deferred("run")

func difference(a:Image,b:Image)->float:
	if a.get_size()!=b.get_size():return INF
	var total:=0.0;var count:=0
	for y in range(16,a.get_height()-16,3):
		for x in range(16,a.get_width()-16,3):
			var p:=a.get_pixel(x,y);var q:=b.get_pixel(x,y)
			total+=absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b);count+=3
	return total/maxf(1,count)

func photograph(canvas:SubViewport,label:String)->Image:
	await settle()
	var picture:=canvas.get_texture().get_image()
	picture.save_png(output+label+("-before.png" if baseline else "-after.png"))
	await settle()
	check(picture.get_data()==canvas.get_texture().get_image().get_data(),label+" is stable while paused")
	return picture

func run()->void:
	for node:Node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for site:Array in [["temperate",Vector2(12000,-3800),[0,1,2,3]],["tropical",Vector2(400,-1000),[0]],["drylands",Vector2(6600,-3280),[0]]]:
		var label:=String(site[0]);var point:Vector2=site[1]
		var canvas:=view();canvas.size=Vector2i(1280,720)
		var terrain:=setup(873421);canvas.add_child(terrain);terrain.discovery_mask_texture=white_fog()
		GameState.elapsed_days=91.25
		var camera:=Camera3D.new();canvas.add_child(camera);terrain.camera=camera
		terrain.camera_target=Vector3(point.x,terrain._height_at(point.x,point.y),point.y)
		var physical_before:=terrain._biome_at(point.x,point.y)
		var deposits:=GameState.resource_deposits.duplicate(true)
		for level:int in site[2]:
			terrain.set_camera_distance_level(level);camera.size=terrain.zoom_target_size;terrain.zoom_target_size=-1;terrain._update_camera()
			var lod=terrain.TERRAIN_LOD;var span:float=lod.bucket(lod.view_span(camera.size,1280.0/720.0,terrain.camera_pitch));var center:Vector2=lod.center_for(point,span)
			var build:=BUILDER.new(lod.resolution_for(span),span,center,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at,terrain._terrain_seasonality_at)
			while not build.advance(5000):await get_tree().process_frame
			terrain._install_regional_patch({"mesh":build.commit(),"center":center,"span":span,"resolution":build.resolution,"heights":build.heights})
			terrain._refresh_seasonal_visuals();terrain._update_scale_lod()
			var material:ShaderMaterial=terrain.regional_terrain_patch.material_override
			var name:=label+"-distance-"+str(level)
			var picture:=await photograph(canvas,name)
			if baseline and label=="temperate" and level==0:
				var source:=FileAccess.open(output+"baseline-shader.txt",FileAccess.WRITE);source.store_string(material.shader.code)
			var row:={"site":label,"level":level,"point":str(point),"altitude_km":camera.position.y-terrain.camera_target.y,"vertical_span_km":camera.size,"biome":physical_before,"vertices":build.resolution*build.resolution}
			if not baseline and FileAccess.file_exists(output+name+"-before.png"):
				var previous:=Image.load_from_file(output+name+"-before.png");row.mean_channel_change=difference(picture,previous)
				if label=="drylands":check(picture.get_data()==previous.get_data(),"treeless drylands unchanged")
			print("WOODLAND_SITE ",JSON.stringify(row));receipts.append(row)
			if level==0:
				check(absf(camera.position.y-terrain.camera_target.y-3.048)<.001,label+" actual 10,000 ft altitude")
				# Changing coordinate frame must not swim the pattern at the same site.
				var original:=material.shader;var shifted:=Shader.new()
				shifted.code=original.code.replace("floor(CAMERA_POSITION_WORLD.xz/64.0)*64.0","(floor(CAMERA_POSITION_WORLD.xz/64.0)*64.0+vec2(64.0,-64.0))")
				material.shader=shifted;await settle()
				check(difference(picture,canvas.get_texture().get_image())<.0005,label+" texture stays fixed on coordinate reanchor")
				material.shader=original
				if label=="temperate":
					GameState.elapsed_days=273.75;terrain._refresh_seasonal_visuals();await photograph(canvas,label+"-winter")
					GameState.elapsed_days=91.25;terrain._refresh_seasonal_visuals()
					# A fully cut real catchment must remove the new canopy as well.
					material.set_shader_parameter("woodland_area_count",1)
					var areas:=PackedVector4Array([Vector4(point.x,point.y,10,0)]);areas.resize(32);material.set_shader_parameter("woodland_areas",areas)
					var cleared:=await photograph(canvas,"temperate-cleared")
					if not baseline and FileAccess.file_exists(output+"temperate-cleared-before.png"):
						check(cleared.get_data()==Image.load_from_file(output+"temperate-cleared-before.png").get_data(),"fully harvested canopy leaves original open ground")
					material.set_shader_parameter("woodland_area_count",0)
				# Exact fog equality checks both shader variants, not merely a color sample.
				var black:=Image.create(2,2,false,Image.FORMAT_RGBA8);black.fill(Color.BLACK)
				material.set_shader_parameter("discovery_mask",ImageTexture.create_from_image(black));material.set_shader_parameter("fog_current_origin",point+Vector2(1000,1000))
				var hidden:=await photograph(canvas,label+"-hidden")
				if not baseline and FileAccess.file_exists(output+label+"-hidden-before.png"):
					check(hidden.get_data()==Image.load_from_file(output+label+"-hidden-before.png").get_data(),"unknown "+label+" does not disclose canopy")
				material.set_shader_parameter("discovery_mask",terrain.discovery_mask_texture)
		check(physical_before==terrain._biome_at(point.x,point.y),label+" physical biome unchanged")
		check(deposits==GameState.resource_deposits,label+" resource records unchanged")
		canvas.queue_free();await settle()
	var receipt:=FileAccess.open(output+("before.json" if baseline else "after.json"),FileAccess.WRITE);receipt.store_string(JSON.stringify(receipts,"  "))
	WorldSimulation.clear();print("WOODLAND_SCALE_CAPTURE ","PASS" if errors==0 else "FAIL");get_tree().quit(errors)
