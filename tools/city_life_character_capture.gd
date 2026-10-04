extends Node
## Private prepared-record visual probe. No saves or simulation loop. Uses the
## actual building renderer, LivingMap actors, smoke and placement helper.
## --out=<directory>; pairs a recorded masonry town with a modern low-rise block.
const Fixture=preload("res://tests/city_evolution_visual_fixture.gd")
const Early=preload("res://scripts/early_settlement_visual.gd")
const Living=preload("res://scripts/living_map.gd")
class Host extends Node3D:
	var camera:Camera3D
	var settler_marker:Node3D
	var camera_target:=Vector3.ZERO
	var game_speed:=1.0
	var travel_active:=false
	var seasonal_materials:Array[WeakRef]=[]
	func _height_at(_x:float,_z:float)->float:return 0.0
	func _settlement_stage_land_at(_point:Vector2)->bool:return true
	func _speed_hours_per_second()->float:return 24.0

func _ready()->void:call_deferred("_run")
func _run()->void:
	var out:="res://artifacts/city-life-character"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var renderer:=Fixture.FlatRenderer.new()
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=.14;camera.near=.0001;camera.far=5.0;add_child(camera);camera.make_current()
	var anchor:=Vector3(.1,0,.1)
	camera.position=anchor+Vector3(.08,.13,.16);camera.look_at(anchor+Vector3(.04,0,.005))
	renderer.camera=camera
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("c9c8b0")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=.8;add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-35,0);sun.light_energy=.9;add_child(sun)
	var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(.5,.5);ground.mesh=plane
	var ground_material:=StandardMaterial3D.new();ground_material.albedo_color=Color("929878");ground.material_override=ground_material
	ground.position=anchor+Vector3(0,-.0001,0);add_child(ground)
	var label:=Label.new();label.position=Vector2(24,18);label.add_theme_font_size_override("font_size",22);label.modulate=Color("26302b");add_child(label)
	for era in [1400,3000]:
		Fixture.initialize()
		var snapshot:=Fixture.snapshot(era)
		snapshot.plots.assign(snapshot.plots.slice(0,4))
		for i in snapshot.plots.size():
			var plot:Dictionary=snapshot.plots[i]
			plot.storeys=3;plot.seed=12+i*4
			plot.land_use=["mixed_household","workshop","storage","civic"][i]
			if era==1400:plot.roof_plan="fired_tile_roof";plot.building_materials={"applied":["wall_chimneys"]}
		GameState.settlement_plots=snapshot.plots;GameState.settlement_routes=snapshot.routes
		GameState.settlement_founded_at=anchor;GameState.settlement_site_committed=true
		GameState.population_total=200;GameState.population_allocations={"Crafting":40,"Logistics":40,"Construction":20,"Administration":10,"Knowledge":10}
		GameState.population_cohorts["children"]=42.0
		var city:=Node3D.new();city.position=anchor;add_child(city)
		Fixture.render(renderer,snapshot,city)
		var plan:=Early.layout(snapshot.plots,snapshot.routes,func(_p:Vector2)->bool:return true)
		Early.remember_layout(plan,snapshot.plots)
		var host:=Host.new();host.camera=camera;add_child(host)
		var layer:=Living.new();layer.terrain=host;host.add_child(layer);layer.set_process(false)
		preload("res://scripts/settlement_ink.gd").set_pixel(camera.size/900.0)
		label.text="TEST · Recorded %s frontages · bounded real-labour representatives" % ("masonry" if era==1400 else "modern")
		for frame in 20:
			for step in 5:Living.tick_clock(.1);layer._frame(.1)
			for worker:Dictionary in layer.workers:
				var at:Transform3D=layer._worker_transform(worker,false)
				assert(layer.navigation.open_at(Vector2(at.origin.x,at.origin.z)),"Worker entered a recorded building")
			if DisplayServer.get_name()!="headless":
				for draw in 2:await get_tree().process_frame
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(out.path_join("%d-frame-%02d.png" % [era,frame]))
		print("CITY_LIFE_CAPTURE ",era," ",JSON.stringify(layer.activity_report())," chimney_sources=",layer.smoke_sources.size()," hearth=",layer.hearth_active)
		host.queue_free();city.queue_free();await get_tree().process_frame
	renderer.settlement_fabric_shader=null;renderer.free()
	get_tree().quit()
