extends Node
const Index=preload("res://tests/spatial_experiment_index.gd")
const Urban=preload("res://tests/spatial_experiment_urban.gd")
var results:Array=[]
var terrain:Node
var index:RefCounted
var markers:MultiMeshInstance3D
var origin:Vector3
var heights:=PackedFloat32Array()

func _ready()->void:
	AudioServer.set_bus_mute(0,true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	GameState.reset_for_new_world(184271)
	PeopleDirection.reset_for_new_world(); PeopleDirection.choose("makers")
	get_window().size=Vector2i(1280,720)
	get_window().content_scale_size=Vector2i(1920,1080)
	terrain=load("res://local_terrain.tscn").instantiate(); add_child(terrain)
	terrain.game_speed=0
	origin=terrain.camera_target
	markers=MultiMeshInstance3D.new()
	markers.multimesh=MultiMesh.new()
	markers.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	var mesh:=SphereMesh.new(); mesh.radius=0.008; mesh.height=0.016; mesh.radial_segments=6; mesh.rings=3
	markers.multimesh.mesh=mesh
	markers.multimesh.instance_count=4096
	markers.multimesh.visible_instance_count=0
	var material:=StandardMaterial3D.new(); material.albedo_color=Color("e3b655")
	markers.material_override=material; add_child(markers)
	var points:=PackedVector2Array()
	var rng:=RandomNumberGenerator.new(); rng.seed=7151
	heights.resize(8192)
	for id in 100000:
		var point:=Vector2(rng.randf_range(-1,1),rng.randf_range(-1,1)) if id<8192 else Vector2(rng.randf_range(10,20000),rng.randf_range(10,20000))
		points.append(point)
		if id<8192: heights[id]=terrain._height_at(origin.x+point.x,origin.z+point.y)
	index=Index.new(); index.build(points,0.25)
	var known_points:=PackedVector2Array()
	for id in range(0,384,2): known_points.append(points[id])
	var known_index:=Index.new(); known_index.build(known_points,0.25)
	var front:=Urban.new(); front.build(0.025)
	var modes:Array=["baseline","culled384","culled8192","culled384_with_replanning","known_index384"]
	var reversed:bool="--reverse" in OS.get_cmdline_user_args()
	if reversed: modes.reverse()
	for mode in modes:
		var frames:Array[float]=[]; var index_cost:Array[float]=[]; var path_cost:Array[float]=[]
		var visible_max:=0
		terrain.camera_target=origin; terrain.camera.size=4.0; terrain.zoom_target_size=-1.0; terrain._update_camera()
		for warmup in 120: await get_tree().process_frame
		var last:=Time.get_ticks_usec()
		for frame in 360:
			if frame%60==0:
				terrain.zoom_target_size=0.6 if (frame/60)%2==0 else 4.0
				terrain.zoom_pointer=get_viewport().get_visible_rect().size*0.5
				terrain.camera_target=origin+Vector3(0.2*sin(frame*0.02),0,0.2*cos(frame*0.02))
			var started:=Time.get_ticks_usec()
			var visible:=0
			if mode!="baseline":
				var center:=Vector2(terrain.camera_target.x-origin.x,terrain.camera_target.z-origin.z)
				var query_index:RefCounted=known_index if mode=="known_index384" else index
				for candidate in query_index.nearby(center,minf(3.0,terrain.camera.size*1.5)):
					var id:int=candidate*2 if mode=="known_index384" else candidate
					# Knowledge is an independent filter. This test never promotes
					# unknown entities simply because they are spatially close.
					if id%2!=0 or id>=(8192 if mode=="culled8192" else 384): continue
					var point:Vector2=index.positions[id]
					markers.multimesh.set_instance_transform(visible,Transform3D(Basis.IDENTITY,Vector3(origin.x+point.x,heights[id]+0.03,origin.z+point.y)))
					visible+=1
			markers.multimesh.visible_instance_count=visible
			visible_max=maxi(visible_max,visible)
			index_cost.append(float(Time.get_ticks_usec()-started)/1000.0)
			started=Time.get_ticks_usec()
			if mode=="culled384_with_replanning" and frame%6==0:
				front.changed_control(frame)
				front.path(frame)
			path_cost.append(float(Time.get_ticks_usec()-started)/1000.0)
			await get_tree().process_frame
			var now:=Time.get_ticks_usec()
			frames.append(float(now-last)/1000.0); last=now
		results.append({"mode":mode,"frames":_stats(frames),"cull_and_upload":_stats(index_cost),"planning":_stats(path_cost),"visible_max":visible_max,"world_entities":100000,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
		print("SPATIAL_GPU_SAMPLE ",JSON.stringify(results.back()))
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://artifacts/spatial-"+mode+".png")
	var file:=FileAccess.open("res://artifacts/spatial-gpu-reverse.json" if reversed else "res://artifacts/spatial-gpu.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(results,"\t")); file.close()
	print("SPATIAL_GPU_DONE")
	terrain.queue_free(); markers.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _stats(samples:Array[float])->Dictionary:
	samples.sort()
	return {"p50_ms":samples[samples.size()/2],"p95_ms":samples[int(samples.size()*0.95)],"p99_ms":samples[int(samples.size()*0.99)],"max_ms":samples.back()}
