extends "res://tests/ground_surface_probe.gd"
## Paired material experiment; explicit flat geometry isolates fragment cost.
## Production geometry, climate and full-landscape captures are separate checks.
var rows:Array[Dictionary]=[]

func same_appearance(a:Image,b:Image,label:String,exact:bool=false)->bool:
	if a.get_size()!=b.get_size() or a.get_format()!=b.get_format():return false
	var left:=a.get_data();var right:=b.get_data()
	if left==right:return true
	if exact:return false
	# Branch compilation can shift a handful of final 8-bit rounding decisions.
	# Permit at most one code value in under 0.005% of pixels; hidden views must
	# remain byte-identical. This is not tolerance for changed texture or detail.
	if a.get_format()!=Image.FORMAT_RGBA8:return false
	var changed:Dictionary={};var maximum:=0
	for i in left.size():
		var delta:=absi(int(left[i])-int(right[i]))
		if delta>0:changed[i/4]=true;maximum=maxi(maximum,delta)
	print("TERRAIN_SHADER_ROUNDING ",JSON.stringify({"label":label,"pixels":changed.size(),"total":a.get_width()*a.get_height(),"max_byte":maximum}))
	return maximum<=1 and float(changed.size())/float(a.get_width()*a.get_height())<.00005

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("TomorrowCanopyTransitionTests") or OS.get_environment("TT_CAPTURE_OWNER")!="canopy-transition" or OS.get_executable_path().get_file()!="GodotCanopyProbe":
		push_error("Use the verified private landscape capture runner.");get_tree().quit(2);return
	output="res://artifacts/terrain-shader-cost/";call_deferred("run")

func sample(canvas:SubViewport)->Dictionary:
	for i in 20:await RenderingServer.frame_post_draw
	var gpu:Array[float]=[];var cpu:Array[float]=[];var frames:Array[float]=[]
	var previous:=Time.get_ticks_usec()
	for i in 64:
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec();frames.append(float(now-previous)/1000.0);previous=now
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(canvas.get_viewport_rid()))
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(canvas.get_viewport_rid()))
	gpu.sort();cpu.sort();frames.sort()
	return {"gpu_median_ms":gpu[32],"cpu_median_ms":cpu[32],"wall_median_ms":frames[32],"gpu_p95_ms":gpu[60],"gpu_positive_samples":gpu.filter(func(x:float)->bool:return x>0.0).size()}

func run()->void:
	for node:Node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var canvas:=view();canvas.size=Vector2i(1280,720)
	RenderingServer.viewport_set_measure_render_time(canvas.get_viewport_rid(),true)
	var terrain:=setup(873421);canvas.add_child(terrain);terrain.discovery_mask_texture=white_fog()
	var material:=terrain._create_terrain_material();var optimized:=material.shader
	# Capture this baseline from the prior revision in this isolated worktree.
	# Never silently turn a missing comparison into a successful self-comparison.
	if not FileAccess.file_exists(output+"baseline-shader.txt"):
		push_error("A reviewed prior-revision baseline shader is required.");get_tree().quit(2);return
	var original:=Shader.new();original.code=FileAccess.get_file_as_string(output+"baseline-shader.txt")
	check(original.code!=optimized.code,"baseline and production candidate are distinct")
	var camera:=Camera3D.new();canvas.add_child(camera);terrain.camera=camera;terrain.camera_target=Vector3(12000,.2,-3800)
	var mesh:=MeshInstance3D.new();mesh.material_override=material;canvas.add_child(mesh)
	for level:int in [0,1,2,3]:
		terrain.set_camera_distance_level(level);camera.size=terrain.zoom_target_size;terrain.zoom_target_size=-1;terrain._update_camera()
		var span:=camera.size*4
		var build:=BUILDER.new(17,span,Vector2(12000,-3800),func(_x:float,_z:float)->float:return .2,func(_x:float,_z:float,_h:float)->Color:return Color(.25,.34,.23,.67),func(_x:float,_z:float,_h:float)->Vector4:return Vector4(1.66,.535,.45,.20))
		while not build.advance(5000):await get_tree().process_frame
		mesh.mesh=build.commit()
		for visibility:String in ["known","hidden","edge"]:
			if visibility=="edge" and level not in [0,3]:continue
			var fog:=Image.create(64,64,false,Image.FORMAT_RGBA8);fog.fill(Color.WHITE if visibility=="known" else Color.BLACK)
			if visibility=="edge":
				for y in 64:
					for x in 64:fog.set_pixel(x,y,Color.WHITE if x>=32 else Color.BLACK)
			material.set_shader_parameter("discovery_mask",ImageTexture.create_from_image(fog))
			material.set_shader_parameter("fog_current_origin",Vector2(-17000,9000))
			# Put the real texture-mask boundary across the viewport, not outside it.
			var fog_coordinates:="(world_position.xz-vec2(12000.0,-3800.0))/vec2("+str(span)+")"
			var shifted:=Shader.new();shifted.code=original.code.replace("world_position.xz/fog_world_size",fog_coordinates)
			var shifted_candidate:=Shader.new();shifted_candidate.code=optimized.code.replace("world_position.xz/fog_world_size",fog_coordinates)
			var first:Image
			for pass_id:int in 4:
				var mode:="baseline" if pass_id in [0,3] else "candidate"
				material.shader=shifted if mode=="baseline" else shifted_candidate
				var result:=await sample(canvas)
				result.merge({"level":level,"visibility":visibility,"mode":mode,"pass":pass_id})
				var picture:=canvas.get_texture().get_image()
				if pass_id==0:
					first=picture
					if visibility=="known":
						var colors:Dictionary={}
						for y in range(20,700,20):
							for x in range(20,1260,20):colors[picture.get_pixel(x,y).to_rgba32()]=true
						check(colors.size()>8,"known terrain is rendered, not empty background")
				var label:=str(level)+" "+visibility+" "+mode+" "+str(pass_id)
				check(same_appearance(first,picture,label,visibility=="hidden"),"same appearance "+label)
				if pass_id<2:picture.save_png(output+"distance-"+str(level)+"-"+visibility+"-"+mode+".png")
				print("TERRAIN_SHADER_TIME ",JSON.stringify(result));rows.append(result)
	canvas.queue_free();await settle()
	await real_surfaces(original,optimized)
	WorldSimulation.clear()
	var receipt:=FileAccess.open(output+"measurements.json",FileAccess.WRITE);receipt.store_string(JSON.stringify(rows,"  "))
	print("TERRAIN_SHADER_COST_CAPTURE ","PASS" if errors==0 else "FAIL");get_tree().quit(errors)

func real_surfaces(original:Shader,optimized:Shader)->void:
	for point:Vector2 in [Vector2(12000,-3800),Vector2(6600,-3280),Vector2(10496.72,2000)]:
		var canvas:=view();canvas.size=Vector2i(1280,720)
		var terrain:=setup(873421);canvas.add_child(terrain);terrain.discovery_mask_texture=white_fog()
		var camera:=Camera3D.new();canvas.add_child(camera);terrain.camera=camera
		terrain.camera_target=Vector3(point.x,terrain._height_at(point.x,point.y),point.y)
		terrain.set_camera_distance_level(0);camera.size=terrain.zoom_target_size;terrain.zoom_target_size=-1;terrain._update_camera()
		var span:float=terrain.TERRAIN_LOD.bucket(terrain.TERRAIN_LOD.view_span(camera.size,1280.0/720.0,terrain.camera_pitch))
		var build:=BUILDER.new(385,span,point,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at,terrain._terrain_seasonality_at)
		while not build.advance(5000):await get_tree().process_frame
		terrain._install_regional_patch({"mesh":build.commit(),"center":point,"span":span,"resolution":385,"heights":build.heights})
		var material:ShaderMaterial=terrain.regional_terrain_patch.material_override
		for masked:bool in [false,true]:
			var fog:=Image.create(64,64,false,Image.FORMAT_RGBA8);fog.fill(Color.WHITE)
			if masked:
				for y in 64:
					for x in 32:fog.set_pixel(x,y,Color.BLACK)
			material.set_shader_parameter("discovery_mask",ImageTexture.create_from_image(fog));material.set_shader_parameter("fog_current_origin",point+Vector2(1000,1000))
			var first:Image
			for mode:int in 2:
				var variant:=Shader.new();variant.code=(original if mode==0 else optimized).code
				var coords:="(world_position.xz-vec2(%s,%s))/vec2(%s)" % [point.x,point.y,span]
				variant.code=variant.code.replace("world_position.xz/fog_world_size",coords);material.shader=variant
				await settle();var picture:=canvas.get_texture().get_image()
				picture.save_png(output+"real-%d-%d-%s-%d.png" % [point.x,point.y,str(masked),mode])
				if mode==0:first=picture
				else:check(same_appearance(first,picture,str(point)+" "+str(masked)),"real terrain and fog edge appearance unchanged at "+str(point)+" "+str(masked))
		canvas.queue_free();await settle()
