extends "res://tests/ground_surface_probe.gd"
## Real generated sites. Diagnostic close views are explicitly separate from presets.
func _ready()->void:
	output="res://artifacts/canopy-transition/"
	get_window().title="TEST — Canopy transition capture";get_window().mode=Window.MODE_MINIMIZED
	call_deferred("run")

func plants(terrain:Node)->Array:
	var result:Array=[]
	if terrain.close_vegetation_root==null:return result
	for node:Node in terrain.close_vegetation_root.get_children():
		if node is MultiMeshInstance3D:
			for i in node.multimesh.instance_count:
				result.append([node.name,node.multimesh.get_instance_transform(i),node.multimesh.get_instance_color(i),node.multimesh.get_instance_custom_data(i)])
	return result

func run()->void:
	if not OS.get_user_data_dir().ends_with("TomorrowCanopyTransitionTests"):
		push_error("Use isolated canopy-test userdata.");get_tree().quit(2);return
	for node:Node in [GameState,MilitaryCampaign,CivilizationSystem]:node.set_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var suffix:="before" if "--before" in OS.get_cmdline_user_args() else "after"
	for site:Array in [["temperate",Vector2(12000,-3800)],["tropical",Vector2(400,-1000)],["drylands",Vector2(6600,-3280)]]:
		var label:=String(site[0]);var point:Vector2=site[1]
		var canvas:=view();canvas.size=Vector2i(1280,720)
		var terrain:=setup(873421);canvas.add_child(terrain);terrain.discovery_mask_texture=white_fog()
		GameState.elapsed_days=91.25
		var camera:=Camera3D.new();canvas.add_child(camera);terrain.camera=camera
		var height:=terrain._height_at(point.x,point.y);terrain.camera_target=Vector3(point.x,height,point.y)
		terrain.settler_marker=Area3D.new();terrain.add_child(terrain.settler_marker);terrain.settler_marker.position=terrain.camera_target
		terrain.camera_input_msec=-1000
		terrain.set_camera_distance_level(0);camera.size=terrain.zoom_target_size;terrain.zoom_target_size=-1;terrain._update_camera()
		var lod=terrain.TERRAIN_LOD;var span:float=lod.bucket(lod.view_span(camera.size,1280.0/720.0,terrain.camera_pitch));var center:Vector2=lod.center_for(point,span)
		var build:=BUILDER.new(lod.resolution_for(span),span,center,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at,terrain._terrain_seasonality_at)
		while not build.advance(5000):await get_tree().process_frame
		terrain._install_regional_patch({"mesh":build.commit(),"center":center,"span":span,"resolution":build.resolution,"heights":build.heights})
		terrain._build_detail_terrain_patch(terrain.camera_target);terrain._refresh_seasonal_visuals();terrain._update_scale_lod()
		check(terrain.close_vegetation_root==null,label+" first aerial view defers hidden vegetation")
		var original:Array=[];var constructed:=false;var root_id:=0
		for spec:Array in [["10000ft-wide",Vector2i(1280,720),-1.0],["10000ft-standard",Vector2i(960,720),-1.0],["diagnostic-edge",Vector2i(1280,720),.72],["diagnostic-crowns",Vector2i(1280,720),.30]]:
			canvas.size=spec[1];terrain.set_camera_distance_level(0)
			camera.size=terrain.zoom_target_size if float(spec[2])<0 else float(spec[2]);terrain.zoom_target_size=-1
			# These are completed, stationary camera placements, not active gestures.
			terrain.camera_input_msec=-1000
			terrain._update_camera();terrain._update_scale_lod();await settle()
			var visible:=terrain.close_vegetation_root!=null and terrain.close_vegetation_root.visible
			if not constructed and float(spec[2])<0:
				check(terrain.close_vegetation_root==null,label+" hidden aerial update does not construct plants")
			elif not constructed:
				check(terrain.close_vegetation_root!=null,label+" visible diagnostic constructs the deferred patch")
				if terrain.close_vegetation_root!=null:
					original=plants(terrain);constructed=true;root_id=terrain.close_vegetation_root.get_instance_id()
			else:
				check(original==plants(terrain) and root_id==terrain.close_vegetation_root.get_instance_id(),label+" subsequent zoom retains the constructed patch")
			var picture:=canvas.get_texture().get_image();picture.save_png(output+label+"-"+String(spec[0])+"-"+suffix+".png")
			print("CANOPY_SITE ",JSON.stringify({"label":label,"view":spec[0],"point":str(point),"biome":terrain._biome_at(point.x,point.y,height),"width":canvas.size.x,"height":canvas.size.y,"altitude_km":camera.position.y-height,"camera_size":camera.size,"plants":plants(terrain).size(),"constructed":constructed,"visible":visible}))
			if float(spec[2])<0:check(absf(camera.position.y-height-3.048)<.001,label+" uses real 10,000 ft altitude at "+String(spec[0]))
			await settle();check(picture.get_data()==canvas.get_texture().get_image().get_data(),label+" paused frame fixed at "+String(spec[0]))
		if not constructed:
			check(false,label+" requires a constructed close diagnostic before identity and fog checks")
			canvas.queue_free();await settle();continue
		for level in 4:
			terrain.set_camera_distance_level(level);camera.size=terrain.zoom_target_size;terrain.zoom_target_size=-1
			terrain._update_camera();terrain._update_scale_lod()
			check(constructed and original==plants(terrain) and root_id==terrain.close_vegetation_root.get_instance_id(),label+" distance "+str(level)+" preserves constructed crown identities")
			check(not terrain.close_vegetation_root.visible,label+" distance "+str(level)+" hides constructed foliage")
		camera.size=.30;terrain._update_camera();terrain._update_scale_lod();await settle()
		# Unknown vegetation must not reveal the finite patch, even in the diagnostic.
		var fog:=Image.create(2,2,false,Image.FORMAT_RGBA8);fog.fill(Color.BLACK)
		for reference:WeakRef in terrain.vegetation_fog_materials:
			var material:ShaderMaterial=reference.get_ref()
			if material:material.set_shader_parameter("discovery_mask",ImageTexture.create_from_image(fog));material.set_shader_parameter("fog_current_origin",point+Vector2(1000,1000))
		await settle();var hidden:=canvas.get_texture().get_image()
		terrain.close_vegetation_root.hide();await settle()
		check(hidden.get_data()==canvas.get_texture().get_image().get_data(),label+" foliage remains hidden by fog")
		canvas.queue_free();await settle()
	WorldSimulation.clear();print("CANOPY_TRANSITION_CAPTURE ","PASS" if errors==0 else "FAIL");get_tree().quit(errors)
