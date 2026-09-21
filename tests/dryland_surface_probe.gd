extends "res://tests/terrain_shader_cost_probe.gd"
## Native physical dryland appearance, controls, stability and paired cost.
var before_ground:String

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("TomorrowCanopyTransitionTests") or OS.get_environment("TT_CAPTURE_OWNER")!="canopy-transition" or OS.get_executable_path().get_file()!="GodotCanopyProbe":
		push_error("Use the verified private landscape capture runner.");get_tree().quit(2);return
	output="res://artifacts/dryland-surface/"
	if not FileAccess.file_exists(output+"baseline-ground.gdshaderinc.txt"):
		push_error("Reviewed prior ground include is required.");get_tree().quit(2);return
	before_ground=FileAccess.get_file_as_string(output+"baseline-ground.gdshaderinc.txt")
	call_deferred("run")

func baseline_for(material:ShaderMaterial)->Shader:
	var original:=Shader.new()
	original.code=material.shader.code.replace('#include "res://scripts/ground_surface.gdshaderinc"',before_ground)
	check(original.code!=material.shader.code,"explicit prior surface baseline")
	return original

func capture(canvas:SubViewport,name:String)->Image:
	await settle();var result:=canvas.get_texture().get_image();result.save_png(output+name+".png")
	await settle();check(result.get_data()==canvas.get_texture().get_image().get_data(),name+" paused pixels stable")
	return result

func run()->void:
	for node:Node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var scan:=setup(873421)
	var sites:Array=[{"name":"reference","point":Vector2(6600,-3280),"levels":[0,1,2,3]}]
	var families:Dictionary={}
	for z in range(-7800,7801,600):
		for x in range(-18000,18001,600):
			var h:=scan._height_at(x,z);var b:=scan._biome_at(x,z,h)
			if h<0.15 or h>6.0 or float(b.get("precipitation",1.0))>.30 or float(b.get("temperature",0.0))<.55:continue
			var f:=scan._terrain_surface_fields_at(x,z,h)
			for family:String in ["sedimentary","volcanic","metamorphic"]:
				var score:float=f.z if family=="sedimentary" else (f.w if family=="volcanic" else 1.0-f.z-f.w)
				if score>float(families.get(family,{}).get("score",-1.0)):families[family]={"name":family,"point":Vector2(x,z),"score":score,"levels":[0]}
	scan.free()
	for family:String in families:sites.append(families[family])
	sites.append({"name":"woodland","point":Vector2(12000,-3800),"levels":[0]})
	for site:Dictionary in sites:await real_site(site)
	await controls()
	WorldSimulation.clear()
	var receipt:=FileAccess.open(output+"measurements.json",FileAccess.WRITE);receipt.store_string(JSON.stringify(rows,"  "))
	print("DRYLAND_SURFACE_CAPTURE ","PASS" if errors==0 else "FAIL");get_tree().quit(errors)

func real_site(site:Dictionary)->void:
	var point:Vector2=site.point;var name:=String(site.name)
	var canvas:=view();canvas.size=Vector2i(1280,720)
	RenderingServer.viewport_set_measure_render_time(canvas.get_viewport_rid(),true)
	var terrain:=setup(873421);canvas.add_child(terrain);terrain.discovery_mask_texture=white_fog()
	GameState.elapsed_days=91.25
	var camera:=Camera3D.new();canvas.add_child(camera);terrain.camera=camera
	terrain.camera_target=Vector3(point.x,terrain._height_at(point.x,point.y),point.y)
	var biome:=terrain._biome_at(point.x,point.y);var resources:=GameState.resource_deposits.duplicate(true)
	print("DRYLAND_SITE ",JSON.stringify({"site":name,"point":str(point),"biome":biome,"fields":str(terrain._terrain_surface_fields_at(point.x,point.y,terrain.camera_target.y))}))
	for level:int in site.levels:
		terrain.set_camera_distance_level(level);camera.size=terrain.zoom_target_size;terrain.zoom_target_size=-1;terrain._update_camera()
		var lod=terrain.TERRAIN_LOD;var span:float=lod.bucket(lod.view_span(camera.size,1280.0/720.0,terrain.camera_pitch));var center:Vector2=lod.center_for(point,span)
		var build:=BUILDER.new(lod.resolution_for(span),span,center,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at,terrain._terrain_seasonality_at)
		while not build.advance(5000):await get_tree().process_frame
		terrain._install_regional_patch({"mesh":build.commit(),"center":center,"span":span,"resolution":build.resolution,"heights":build.heights})
		terrain._refresh_seasonal_visuals()
		var material:ShaderMaterial=terrain.regional_terrain_patch.material_override
		var candidate:=material.shader;var original:=baseline_for(material);var first:Image
		for pass_id:int in 4:
			var mode:="baseline" if pass_id in [0,3] else "candidate"
			material.shader=original if mode=="baseline" else candidate
			var measurement:=await sample(canvas);measurement.merge({"site":name,"level":level,"mode":mode,"pass":pass_id});rows.append(measurement)
			print("DRYLAND_TIME ",JSON.stringify(measurement))
			if pass_id>1:continue
			var picture:=await capture(canvas,name+"-"+str(level)+"-"+mode)
			if pass_id==0:first=picture
			elif name=="woodland" or level==3:check(same_appearance(first,picture,name),name+" wet or unresolved terrain preserved")
		material.shader=candidate
		if level==0:
			check(absf(camera.position.y-terrain.camera_target.y-3.048)<.001,name+" actual 10,000 ft")
			var expected:=await capture(canvas,name+"-stable")
			var shifted:=Shader.new();shifted.code=candidate.code.replace("floor(CAMERA_POSITION_WORLD.xz/64.0)*64.0","(floor(CAMERA_POSITION_WORLD.xz/64.0)*64.0+vec2(64.0,-64.0))")
			material.shader=shifted;await settle();check(image_difference(expected,canvas.get_texture().get_image())<.0005,name+" phase survives coordinate reanchor")
			var black:=Image.create(2,2,false,Image.FORMAT_RGBA8);black.fill(Color.BLACK)
			material.set_shader_parameter("discovery_mask",ImageTexture.create_from_image(black));material.set_shader_parameter("fog_current_origin",point+Vector2(1000,1000))
			material.shader=original;var hidden:=await capture(canvas,name+"-hidden-baseline")
			material.shader=candidate;await settle();check(same_appearance(hidden,canvas.get_texture().get_image(),name+" hidden",true),name+" fog stays identical")
			material.set_shader_parameter("discovery_mask",terrain.discovery_mask_texture)
	check(biome==terrain._biome_at(point.x,point.y),name+" biome unchanged")
	check(resources==GameState.resource_deposits,name+" deposits unchanged")
	canvas.queue_free();await settle()

func image_difference(a:Image,b:Image)->float:
	var total:=0.0;var count:=0
	for y in range(16,a.get_height()-16,3):
		for x in range(16,a.get_width()-16,3):
			var p:=a.get_pixel(x,y);var q:=b.get_pixel(x,y);total+=absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b);count+=3
	return total/maxf(1,count)

func controls()->void:
	var canvas:=view();canvas.size=Vector2i(1280,720);var terrain:=setup(873421);canvas.add_child(terrain);terrain.discovery_mask_texture=white_fog()
	var material:=terrain._create_terrain_material();var candidate:=material.shader;var original:=baseline_for(material)
	var camera:=Camera3D.new();canvas.add_child(camera);terrain.camera=camera;terrain.camera_target=Vector3(6600,.2,-3280)
	terrain.set_camera_distance_level(0);camera.size=terrain.zoom_target_size;terrain.zoom_target_size=-1;terrain._update_camera()
	var mesh:=MeshInstance3D.new();mesh.material_override=material;canvas.add_child(mesh)
	for spec:Array in [["warm-dry-sediment",.18,.8,.9,.05,0.0],["warm-dry-volcanic",.18,.8,.05,.9,0.0],["warm-dry-metamorphic",.18,.8,.05,.05,0.0],["wet",.8,.8,.9,.05,0.0],["cold",.18,.1,.9,.05,0.0],["woodland",.18,.8,.9,.05,1.0],["legacy",-1.0,.8,0.0,0.0,0.0]]:
		var build:=BUILDER.new(17,20,Vector2(6600,-3280),func(_x:float,_z:float)->float:return .2,func(_x:float,_z:float,_h:float)->Color:return Color(.5,.41,.26,spec[5]),func(_x:float,_z:float,_h:float)->Vector4:return Vector4(1.0+spec[1],spec[2],spec[3],spec[4]))
		while not build.advance(5000):await get_tree().process_frame
		mesh.mesh=build.commit();material.shader=original;var a:=await capture(canvas,spec[0]+"-control-baseline")
		material.shader=candidate;var b:=await capture(canvas,spec[0]+"-control-candidate")
		if spec[0] in ["wet","cold","woodland","legacy"]:check(same_appearance(a,b,spec[0]),spec[0]+" control unchanged")
		else:check(image_difference(a,b)>.01,spec[0]+" has visible parent-material surface")
	canvas.queue_free();await settle()
