extends Node
## Capture-only audit of real seeded ground plus explicit material controls.
const BUILDER:=preload("res://scripts/terrain_patch_builder.gd")
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
var errors:=0
var output:="res://artifacts/ground-surfaces/"
func _ready()->void:
	get_window().title="TEST — Ground surface audit";get_window().mode=Window.MODE_MINIMIZED;call_deferred("run")
func check(condition:bool,message:String)->void:
	print("GROUND ","PASS " if condition else "FAIL ",message)
	if not condition:errors+=1
func settle()->void:
	for i in 8:await get_tree().process_frame;RenderingServer.force_draw(false)
func setup(seed_value:int)->Terrain:
	GameState.reset_for_new_world(seed_value)
	var terrain:=Terrain.new();terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	return terrain
func white_fog()->ImageTexture:
	var image:=Image.create(2,2,false,Image.FORMAT_RGBA8);image.fill(Color.WHITE);return ImageTexture.create_from_image(image)
func environment(view:SubViewport)->void:
	var environment:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("0b1417");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("b8b6a9");env.ambient_light_energy=.29;env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;environment.environment=env;view.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-38,0);sun.light_color=Color("dfd1b5");sun.light_energy=.82;sun.shadow_enabled=false;view.add_child(sun)
func view()->SubViewport:
	var result:=SubViewport.new();result.size=Vector2i(1080,720);result.own_world_3d=true;result.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(result);environment(result);return result
func average(image:Image)->Color:
	var total:=Color(0,0,0,0);var count:=0
	for y in range(90,630,12):
		for x in range(120,960,12):total+=image.get_pixel(x,y);count+=1
	return total/float(count)
func run()->void:
	for node:Node in [GameState,MilitaryCampaign,CivilizationSystem]:node.set_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var places:Dictionary={}
	# Seek representative actual worlds, not prepainted biome flags.
	for seed_value:int in [873421,424242,271828]:
		var terrain:=setup(seed_value)
		for z in range(-8200,8201,410):
			for x in range(-18000,18001,600):
				var h:=terrain._height_at(x,z)
				if h<.03:continue
				var biome:=terrain._biome_at(x,z,h);var id:=String(biome.id)
				if id=="steppe" and biome.temperature<.65:continue
				if id in ["grassland","woodland"] and biome.temperature<.5:continue
				if not places.has(id):places[id]={"seed":seed_value,"point":Vector2(x,z),"biome":biome,"height":h}
		terrain.free()
		if places.has("steppe") and places.has("grassland") and places.has("woodland") and places.has("tundra"):break
	for id:String in ["steppe","grassland","woodland","tundra"]:
		check(places.has(id),"real generated example exists: "+id)
		if not places.has(id):continue
		var site:Dictionary=places[id];var terrain:=setup(site.seed);var canvas:=view();canvas.add_child(terrain);terrain.discovery_mask_texture=white_fog()
		var build:=BUILDER.new(201,8.0,site.point,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at)
		while not build.advance(5000):pass
		terrain._install_regional_patch({"mesh":build.commit(),"center":site.point,"span":8.0,"resolution":201,"heights":build.heights});terrain._build_water()
		var camera:=Camera3D.new();camera.fov=35;camera.near=.05;camera.far=100000;camera.position=Vector3(site.point.x,site.height+3.048,site.point.y+1.8);canvas.add_child(camera);camera.look_at(Vector3(site.point.x,site.height,site.point.y),Vector3.UP)
		await settle();canvas.get_texture().get_image().save_png(output+id+"-real-world.png")
		var profile:=PlanetEnvironment.profile_at(site.point,terrain._survey_ground_at(site.point))
		print("GROUND_SITE ",JSON.stringify({"biome":id,"seed":site.seed,"x":site.point.x,"z":site.point.y,"height_km":site.height,"rain":site.biome.precipitation,"warmth":site.biome.temperature,"geology":profile.geology,"max_slice_us":build.max_slice_usec}))
		canvas.queue_free();await settle()
	# Compare the same steep geometry with controlled geological families.
	var canvas:=view();var terrain:=setup(42);canvas.add_child(terrain);terrain.discovery_mask_texture=white_fog();var material:=terrain._create_terrain_material()
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.48;camera.near=.05;camera.far=10;camera.position=Vector3(0,4,0);canvas.add_child(camera);camera.look_at(Vector3(0,1,0),Vector3.FORWARD)
	var colors:Array[Color]=[]
	var mesh:=MeshInstance3D.new();mesh.material_override=material;canvas.add_child(mesh)
	for spec:Array in [["sedimentary",.92,.04],["igneous",.04,.92],["metamorphic",.04,.04]]:
		var build:=BUILDER.new(33,.8,Vector2.ZERO,func(x:float,_z:float)->float:return 1.0+x*1.8,func(_x:float,_z:float,_h:float)->Color:return Color(.42,.36,.24,0),func(_x:float,_z:float,_h:float)->Vector4:return Vector4(1.25,.8,spec[1],spec[2]))
		while not build.advance(100000):pass
		mesh.mesh=build.commit();await settle();var image:=canvas.get_texture().get_image();image.save_png(output+spec[0]+"-control.png");colors.append(average(image))
	check(colors[0].r>colors[1].r+.018,"sedimentary and igneous outcrops are visually distinct")
	check(colors[0].r/colors[0].g>colors[2].r/colors[2].g+.015,"warm sedimentary and cool metamorphic appearance")
	# Appearance cannot disclose geology through fog.
	var black:=Image.create(2,2,false,Image.FORMAT_RGBA8);black.fill(Color.BLACK);material.set_shader_parameter("discovery_mask",ImageTexture.create_from_image(black));material.set_shader_parameter("fog_current_origin",Vector2(1000,1000))
	await settle();var unknown:=canvas.get_texture().get_image()
	var flat:=BUILDER.new(33,.8,Vector2.ZERO,func(x:float,_z:float)->float:return 1.0+x*1.8,func(_x:float,_z:float,_h:float)->Color:return Color(.42,.36,.24,0),func(_x:float,_z:float,_h:float)->Vector4:return Vector4(1.25,.8,.92,.04))
	while not flat.advance(100000):pass
	mesh.mesh=flat.commit();await settle();check(unknown.get_data()==canvas.get_texture().get_image().get_data(),"fog conceals geological differences")
	canvas.queue_free();await settle()
	# Exercise the live four-distance camera and both real mesh LODs at a seeded
	# home range; only discovery is overridden so the complete view is inspectable.
	canvas=view();terrain=setup(873421);canvas.add_child(terrain);terrain.discovery_mask_texture=white_fog()
	terrain._build_terrain();terrain._build_water();camera=Camera3D.new();canvas.add_child(camera);terrain.camera=camera
	var point:=Vector2(55,0);terrain.camera_target=Vector3(point.x,terrain._height_at(point.x,point.y),point.y)
	for index in 4:
		terrain.set_camera_distance_level(index);camera.size=terrain.zoom_target_size;terrain._update_camera()
		if camera.size<=820:
			var span:=clampf(camera.size*3.0,.9,920)
			var ground:=BUILDER.new(201,span,point,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at)
			while not ground.advance(5000):pass
			terrain._install_regional_patch({"mesh":ground.commit(),"center":point,"span":span,"resolution":201,"heights":ground.heights})
		var cutout:=Vector4(point.x,point.y,terrain.regional_patch_span,1) if camera.size<=820 else Vector4.ZERO
		terrain.province_terrain_mesh.material_override.set_shader_parameter("streamed_cutout",cutout)
		if terrain.regional_terrain_patch:terrain.regional_terrain_patch.visible=camera.size<=820
		await settle();canvas.get_texture().get_image().save_png(output+"distance-"+str(index)+".png")
		print("GROUND_DISTANCE ",terrain.CAMERA_DISTANCE_LEVELS[index].name," altitude_km=",camera.position.y-terrain.camera_target.y," near=",camera.near," far=",camera.far)
	canvas.queue_free();await settle();WorldSimulation.clear();print("GROUND_SURFACE_CAPTURE ","PASS" if errors==0 else "FAIL");get_tree().quit(errors)
