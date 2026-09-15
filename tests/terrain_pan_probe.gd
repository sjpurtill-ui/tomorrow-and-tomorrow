extends "res://tests/ground_surface_probe.gd"
## Paired full-rebuild versus completed-sample reuse at the same live camera.
const LOD:=preload("res://scripts/terrain_lod.gd")
var measurements:Array[Dictionary]=[]

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("TomorrowCanopyTransitionTests") or OS.get_environment("TT_CAPTURE_OWNER")!="canopy-transition":
		push_error("Use the private background capture runner.");get_tree().quit(2);return
	output="res://artifacts/terrain-pan/"
	call_deferred("run")

func measure(terrain:Terrain,center:Vector2,span:float,prior:Dictionary,label:String)->RefCounted:
	var build:=BUILDER.new(LOD.resolution_for(span),span,center,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at,terrain._terrain_seasonality_at,prior)
	var began:=Time.get_ticks_msec();var work_usec:=0;var slices:=0
	while true:
		var start:=Time.get_ticks_usec()
		var done:bool=build.advance(3000)
		work_usec+=Time.get_ticks_usec()-start;slices+=1
		if done:break
		await get_tree().process_frame
	# Elapsed time inside advance(), excluding frame waits; OS preemption can
	# still contribute. This is not an operating-system thread CPU-time counter.
	var row:={"label":label,"center":str(center),"resolution":build.resolution,"sampled":build.sampled_vertices,"reused":build.reused_vertices,"build_ms":float(work_usec)/1000.0,"wall_ms":Time.get_ticks_msec()-began,"slices":slices,"max_slice_us":build.max_slice_usec}
	measurements.append(row);print("TERRAIN_PAN_TIME ",JSON.stringify(row))
	return build

func install(terrain:Terrain,build:RefCounted)->void:
	terrain._install_regional_patch({"mesh":build.commit(),"center":build.center,"span":build.span,"resolution":build.resolution,"heights":build.heights})

func run()->void:
	for node:Node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for site:int in 2:
		var point:=Vector2(55,0) if site==0 else Vector2(6600,-3280)
		var canvas:=view();var terrain:=setup(873421);canvas.add_child(terrain);terrain.discovery_mask_texture=white_fog()
		var camera:=Camera3D.new();canvas.add_child(camera);terrain.camera=camera
		terrain.camera_target=Vector3(point.x,terrain._height_at(point.x,point.y),point.y)
		terrain.set_camera_distance_level(0);camera.size=terrain.zoom_target_size;terrain.zoom_target_size=-1;terrain._update_camera()
		var span:=LOD.bucket(LOD.view_span(camera.size,1.5,terrain.camera_pitch))
		var center:=LOD.center_for(point,span)
		var source:=await measure(terrain,center,span,{},str(site)+" initial")
		install(terrain,source);terrain._build_water();await settle()
		canvas.get_texture().get_image().save_png(output+str(site)+"-before-pan.png")
		var next:=center+Vector2(span/12.0,0)
		terrain.camera_target.x+=span/12.0;terrain._update_camera()
		var reused:=await measure(terrain,next,span,source.completed_samples(),str(site)+" reused")
		install(terrain,reused);await settle()
		var actual:=canvas.get_texture().get_image();actual.save_png(output+str(site)+"-reused.png")
		var full:=await measure(terrain,next,span,{},str(site)+" full")
		install(terrain,full);await settle()
		var expected:=canvas.get_texture().get_image();expected.save_png(output+str(site)+"-full.png")
		check(actual.get_data()==expected.get_data(),"panned image is pixel-identical to full rebuild at site "+str(site))
		check(reused.reused_vertices>reused.vertices.size()*.85,"at least 85% of finished terrain samples survive a pan")
		check(reused.vertices==full.vertices and reused.normals==full.normals,"geometry and edge normals match full rebuild")
		canvas.queue_free();await settle()
	var file:=FileAccess.open(output+"measurements.json",FileAccess.WRITE);file.store_string(JSON.stringify(measurements,"  "));file.close()
	WorldSimulation.clear();print("TERRAIN_PAN_CAPTURE ","PASS" if errors==0 else "FAIL");get_tree().quit(errors)
