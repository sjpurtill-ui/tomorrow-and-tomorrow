extends Control
## Private desktop technical specimens. The live fabric upgrade path prepares
## the records; labels are not predictions of a player's campaign at a year.
const HISTORY=preload("res://tests/city_evolution_visual_fixture.gd")
const ERA=preload("res://scripts/settlement_country_era.gd")
const VISUAL=preload("res://scripts/settlement_country_visual.gd")
const INK=preload("res://scripts/settlement_ink.gd")
var views:Array[Dictionary]=[]
var report:Array[Dictionary]=[]
const OUT:="res://artifacts/people-grown-land/country-era-specimens"

func _ready()->void:call_deferred("_run")

func _run()->void:
	if not "--country-era-capture" in OS.get_cmdline_user_args():get_tree().quit(2);return
	if not ProjectSettings.globalize_path("user://").contains("TomorrowPeopleGrownLandQA"):
		push_error("Requires private QA userdata override");get_tree().quit(2);return
	AudioServer.set_bus_mute(0,true)
	get_window().size=Vector2i(1600,900)
	get_window().content_scale_size=Vector2i(1600,900)
	HISTORY.initialize()
	var background:=ColorRect.new();background.color=Color("eee6d6")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	_label("TEST · prepared construction specimens",Vector2(20,10),26)
	_label("Live country renderer · actual completed forms · no campaign forecast · no people",Vector2(20,43),17)
	var column:=0
	for year in [1000,2000,3000]:
		var specimen:Dictionary=HISTORY.snapshot(year)
		var profile:Dictionary=ERA.capture(GameState.known_discoveries,{},specimen.plots)
		var seed_value:=157
		# Choose an actual highest-generation variant from this prepared palette,
		# retaining the selector itself; never manufacture a descriptor for display.
		var expected:="modern_villa" if int(specimen.tier)>=12 else ("industrial_villa" if int(specimen.tier)>=11 else "masonry_villa")
		for candidate in range(157,257):
			if String(ERA.home(profile,str(candidate)).kind)==expected:seed_value=candidate;break
		var descriptor:Dictionary=ERA.home(profile,str(seed_value))
		var x:=16+column*528
		_label("Prepared year %d · tier %d" % [year,specimen.tier],Vector2(x,78),21)
		_label("%s · %d storeys · %s" % [descriptor.kind,descriptor.storeys,descriptor.material],Vector2(x,108),14)
		var close:=_view(Vector2(x,135),Vector2i(512,460),0.08,profile,seed_value,false)
		var fields:=_view(Vector2(x,637),Vector2i(512,222),0.22,profile,seed_value,true)
		_label("80 m house detail",Vector2(x,602),16)
		_label("Four retained field parcels · 220 m view",Vector2(x,864),14)
		views.append({"year":year,"close":close,"fields":fields})
		report.append({"year_label":year,"fixture":"prepared construction, not campaign forecast","actual_tier":specimen.tier,"home":descriptor,"source_plots":specimen.plots.size(),"field_count":4,"buildings":2,"mesh_size_m":str(ERA.mesh(descriptor).get_aabb().size)})
		column+=1
	INK.set_pixel(0.08/460.0)
	for frame in 8:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/people-grown-land"))
	for view:Dictionary in views:
		(view.close as SubViewport).get_texture().get_image().save_png(OUT+"-%d-homes.png" % view.year)
		(view.fields as SubViewport).get_texture().get_image().save_png(OUT+"-%d-fields.png" % view.year)
	get_viewport().get_texture().get_image().save_png(OUT+".png")
	var file:=FileAccess.open(OUT+".json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("COUNTRY_ERA_CAPTURE ",JSON.stringify(report))
	get_tree().quit(0)

func _label(text:String,at:Vector2,font_size:int)->void:
	var label:=Label.new();label.text=text;label.position=at
	label.add_theme_color_override("font_color",Color("44392c"))
	label.add_theme_font_size_override("font_size",font_size);add_child(label)

func _view(at:Vector2,pixels:Vector2i,span:float,profile:Dictionary,seed_value:int,fields:bool)->SubViewport:
	var container:=SubViewportContainer.new();container.position=at;container.size=pixels
	container.stretch=true;add_child(container)
	var viewport:=SubViewport.new();viewport.size=pixels;viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_4X;container.add_child(viewport)
	var world:=Node3D.new();viewport.add_child(world)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("d5d2b5")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("f1e7cb")
	environment.environment.ambient_light_energy=0.8;world.add_child(environment)
	var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2.ONE
	ground.mesh=plane;var paint:=StandardMaterial3D.new();paint.albedo_color=Color("a6a07d")
	paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ground.material_override=paint;ground.position.y=-0.0001;world.add_child(ground)
	var visual:=VISUAL.new();world.add_child(visual)
	visual.configure(func(_point:Vector2)->float:return 0.0,func(_point:Vector2)->bool:return true)
	var context:={"country_appearance":ERA.render_profile(profile),"style":{},"origin":Vector2.ZERO,"road_tier":0}
	var patch:=Node3D.new();world.add_child(patch)
	if fields:
		var record:={"id":"prepared_farm","kind":"homestead","group":"homesteads","position":Vector2.ZERO,"field_radius_km":0.10,"buildings":2,"track_from":Vector2(0,-0.10)}
		visual._build_patch(patch,record,context)
	else:visual._add_homes(patch,Vector2.ZERO,2,seed_value,context)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=span;camera.near=0.0001;camera.far=3.0
	world.add_child(camera);camera.position=Vector3(0.035,0.080,0.085) if not fields else Vector3(0.035,0.22,0.10)
	camera.look_at(Vector3.ZERO);camera.current=true
	return viewport
