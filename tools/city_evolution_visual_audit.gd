extends Node
## Private GPU/headless audit of the live map's building and street renderer.
const Fixture=preload("res://tests/city_evolution_visual_fixture.gd")
func _ready()->void:call_deferred("_run")
func _run()->void:
	Fixture.initialize()
	var out:="res://artifacts/city-evolution"
	var roof_only:=OS.get_cmdline_user_args().has("--roof-only")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var renderer:=Fixture.FlatRenderer.new()
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=.30;camera.near=.0001;camera.far=5.0
	camera.position=Vector3(.27,.25,.41);add_child(camera);camera.look_at(Vector3(.085,0,.09));camera.make_current()
	renderer.camera=camera
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("c9c8b0")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=.8;add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-35,0);sun.light_energy=.9;add_child(sun)
	var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(1,1);ground.mesh=plane
	var mask:=Image.create(2,2,false,Image.FORMAT_RGB8);mask.fill(Color.WHITE)
	renderer.discovery_mask_texture=ImageTexture.create_from_image(mask)
	ground.material_override=renderer._create_terrain_material();ground.position.y=-.0001;add_child(ground)
	var label:=Label.new();label.position=Vector2(30,25);label.add_theme_font_size_override("font_size",24);label.modulate=Color("26302b");add_child(label)
	var results:Array=[]
	for year in ([] if roof_only else range(0,3001,200)):
		var snapshot:=Fixture.snapshot(year);var city:=Node3D.new();add_child(city)
		var result:=Fixture.render(renderer,snapshot,city);results.append(result)
		renderer._paint_settlement_grounds(Vector3.ZERO)
		label.text="TEST · Prepared city records · Year %d\nGeneration %d · %d plots · recorded capacity %d" % [year,result.tier,result.plots,result.capacity]
		preload("res://scripts/settlement_ink.gd").set_pixel(camera.size/900.0)
		if DisplayServer.get_name()!="headless":
			for frame in 3:await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out.path_join("year-%04d.png" % year))
		print("CITY_EVOLUTION ",JSON.stringify(result))
		city.queue_free();await get_tree().process_frame
	var file:=FileAccess.open(out.path_join("metrics.json"),FileAccess.WRITE);file.store_string(JSON.stringify(results,"\t"));file.close()
	if DisplayServer.get_name()!="headless":await _roof_outline_probe(camera,label,out)
	renderer.settlement_fabric_shader=null;renderer.free()
	get_tree().quit()

func _roof_outline_probe(camera:Camera3D,label:Label,out:String)->void:
	var ink:=preload("res://scripts/settlement_ink.gd")
	ink.set_pixel(camera.size/900.0)
	var mesh:=Fixture.Kit.mesh_for("modern_terrace",3)
	var probes:Array[MeshInstance3D]=[]
	for side in [-1,1]:
		var node:=MeshInstance3D.new();node.mesh=mesh;node.scale=Vector3.ONE*.001;node.position=Vector3(side*.025,0,0)
		node.material_override=ink.material() if side<0 else ink.architecture_material()
		add_child(node);probes.append(node)
	camera.position=Vector3(0,.3,0);camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	label.text="TEST · Same thin roof slab at the same map pixel size\nLegacy radial outline (left) / surface outline (right)"
	for frame in 3:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image:=get_viewport().get_texture().get_image()
	var samples:Array[float]=[]
	for node in probes:
		# Camera projection is in the logical viewport; canvas stretch can make
		# the saved image a different resolution from that coordinate space.
		var screen:=camera.unproject_position(node.position+Vector3(0,.0093,0))*Vector2(image.get_size())/get_viewport().get_visible_rect().size
		samples.append(image.get_pixelv(Vector2i(screen)).get_luminance())
	image.save_png(out.path_join("roof-outline-regression.png"))
	print("CITY_ROOF_OUTLINE ",JSON.stringify({"legacy_luminance":samples[0],"architecture_luminance":samples[1]}))
	assert(samples[1]>samples[0]+.15,"Flat roof material must remain visible above its inked underside")
	for node in probes:node.queue_free()
