extends GdUnitTestSuite
const Culture:=preload("res://scripts/settlement_culture_visual.gd")
const Ink:=preload("res://scripts/settlement_ink.gd")
const Early:=preload("res://scripts/early_settlement_visual.gd")
const Keys:=preload("res://scripts/settlement_visual_keys.gd")
class Terrain extends "res://scripts/local_terrain.gd":
	var vegetation_builds:=0
	var requests:=0
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _settlement_model()->Node:return SettlementModel
	func _height_at(_x:float,_z:float)->float:return .05
	func _close_surface_height_at(_x:float,_z:float)->float:return .05
	func _settlement_stage_land_at(_point:Vector2)->bool:return true
	func _prime_organic_town_plan(_center:Vector3)->bool:return false
	func _paint_settlement_grounds(_center:Vector3)->void:pass
	func _rebuild_close_vegetation(_center:Vector3)->void:vegetation_builds+=1
	func _request_settlement_visual_patches(_center:Vector3,_plots:Array[Dictionary],_routes:Array[Dictionary],_lod:int,_profile:Dictionary,_defense:Dictionary)->void:requests+=1

func before_test()->void:GameState.reset_for_new_world(910164)

func _profile(ordered:bool)->Dictionary:
	var order:=.8 if ordered else .3
	var openness:=.3 if ordered else .8
	return Culture.capture({"lived":{"centralization":order,"hierarchy":order,"openness":openness,"experimentation":openness,"pluralism":openness}},["clay_shaping","lime_mortar","mineral_pigment_preparation","pictographic_records"])

func _plot(family:="earth",generation:=0)->Dictionary:
	return {"id":1,"seed":91,"centroid":Vector2.ZERO,"polygon":PackedVector2Array([Vector2(-.02,-.02),Vector2(.02,-.02),Vector2(.02,.02),Vector2(-.02,.02)]),"frontage_route_id":1,"area_ha":.16,"roof_coverage":.3,"resident_count":12,"material_family":family,"land_use":"residential_compound","form":"compact_courtyard_row" if generation>0 else ("timber_household" if family=="timber" else "earthen_household"),"roof_plan":"timber_ridge" if family=="timber" else "courtyard_flat","status":"active","condition":.8,"storeys":1,"fabric_generation":generation}

func _plots(plot:Dictionary)->Array[Dictionary]:return [plot]
func _routes()->Array[Dictionary]:return [{"id":1,"kind":"camp_path","width_m":.6,"points":PackedVector2Array([Vector2(-.025,0),Vector2(.025,0)])}]
func _land(_point:Vector2)->bool:return true
func _height(_x:float,_z:float)->float:return .05
func _draw(plan:Dictionary)->Node3D:
	var parent:Node3D=auto_free(Node3D.new())
	Early.render(plan,Vector3.ZERO,_height,parent)
	return parent

func _batches(root:Node3D)->Array[MultiMeshInstance3D]:
	var result:Array[MultiMeshInstance3D]=[]
	for child:Node in root.get_children():
		if child is MultiMeshInstance3D and child.has_meta("cultural_codes"):result.append(child)
	return result

func _snapshot(root:Node3D)->Array:
	var result:Array=[]
	for child:MultiMeshInstance3D in _batches(root):
		result.append([String(child.name),child.multimesh.mesh.get_instance_id(),child.material_override.get_instance_id(),child.get_meta("source_transforms"),child.multimesh.instance_count])
	result.sort_custom(func(a:Array,b:Array)->bool:return a[0]<b[0])
	return result

func _codes(root:Node3D)->Array[Color]:
	var result:Array[Color]=[]
	for child:MultiMeshInstance3D in _batches(root):result.append_array(child.get_meta("cultural_codes"))
	return result

func test_early_town_and_later_cultures_share_exact_meshes_materials_and_sites()->void:
	for spec:Array in [["earth",0],["timber",0],["earth",6]]:
		var plot:=_plot(spec[0],spec[1]);var plots:=_plots(plot)
		var plan:=Early.layout(plots,_routes(),_land)
		assert_int(plan.buildings.size()).is_greater(0)
		if plan.buildings.is_empty():continue
		Early.remember_layout(plan,plots)
		var geometry:=Keys.placement(plots,_routes())
		var neutral:=_draw(plan);var original:=_snapshot(neutral)
		for code:Color in _codes(neutral):assert_object(code).is_equal(Color(0,0,0,0))
		plot.cultural_appearance=_profile(true)
		var first:=_draw(Keys.refresh_plan(plan,plots));var expected:=Ink.cultural_data(plot)
		assert_array(_snapshot(first)).is_equal(original)
		for code:Color in _codes(first):assert_object(code).is_equal(expected)
		plot.cultural_appearance=_profile(false)
		var second:=_draw(Keys.refresh_plan(plan,plots))
		assert_array(_snapshot(second)).is_equal(original)
		assert_int(Keys.placement(plots,_routes())).is_equal(geometry)
		assert_array(_codes(second)).is_not_equal(_codes(first))
		assert_int(first.get_child_count()).is_equal(neutral.get_child_count())
		assert_int(second.get_child_count()).is_equal(neutral.get_child_count())

func test_different_cultures_stay_in_one_shared_geometry_batch()->void:
	var first:=_plot();first.cultural_appearance=_profile(true)
	var second:=_plot();second.id=2;second.seed=93;second.centroid=Vector2(.06,0);second.frontage_route_id=2;second.cultural_appearance=_profile(false)
	for index in second.polygon.size():second.polygon[index]+=Vector2(.06,0)
	var plots:Array[Dictionary]=[first,second]
	var routes:=_routes();routes.append({"id":2,"kind":"camp_path","width_m":.6,"points":PackedVector2Array([Vector2(.035,0),Vector2(.085,0)])})
	var plan:=Early.layout(plots,routes,_land);var parent:=_draw(plan)
	var batches:=_batches(parent)
	assert_int(batches.size()).is_equal(1)
	if batches.is_empty():return
	assert_int(batches[0].multimesh.instance_count).is_equal(plan.buildings.size())
	assert_bool(batches[0].multimesh.use_custom_data).is_true()
	assert_array(_codes(parent)).contains([Ink.cultural_data(first),Ink.cultural_data(second)])
	assert_object(batches[0].material_override).is_same(Ink.material())

func test_construction_walls_and_roofs_inherit_finish_without_painting_bare_frames()->void:
	var plot:=_plot("earth",6);plot.cultural_appearance=_profile(true);plot.status="under_construction"
	var plots:=_plots(plot);var plan:=Early.layout(plots,_routes(),_land)
	var expected:=Ink.cultural_data(plot)
	for stage in 4:
		plot.construction_progress=float(stage)*.25
		var parent:=_draw(Keys.refresh_plan(plan,plots))
		assert_array(_codes(parent)).is_not_empty()
		for code:Color in _codes(parent):assert_object(code).is_equal(expected if stage>=2 else Color(0,0,0,0))
	plot.status="active"
	var complete:=_draw(Keys.refresh_plan(plan,plots))
	for code:Color in _codes(complete):assert_object(code).is_equal(expected)

func test_appearance_key_normalizes_stamps_and_never_changes_placement()->void:
	var plot:=_plot();var geometry:=Keys.placement(_plots(plot),_routes());var neutral:=Keys.appearance(plot)
	for invalid:Variant in ["invalid",{"version":2,"roof":4},{"version":1,"door":INF}]:
		plot.cultural_appearance=invalid
		assert_int(Keys.appearance(plot)).is_equal(neutral)
		assert_object(Ink.cultural_data(plot)).is_equal(Color(0,0,0,0))
	plot.cultural_appearance=_profile(true);var first:=Keys.appearance(plot)
	assert_int(first).is_not_equal(neutral)
	plot.cultural_appearance["unrelated_date"]=900000
	assert_int(Keys.appearance(plot)).is_equal(first)
	plot.cultural_appearance=_profile(false)
	assert_int(Keys.appearance(plot)).is_not_equal(first)
	assert_int(Keys.placement(_plots(plot),_routes())).is_equal(geometry)

func test_shared_shader_receives_finite_palettes_and_keeps_roof_glass_tags()->void:
	var ordinary:=Ink.material();var architecture:=Ink.architecture_material()
	assert_object(Ink.material()).is_same(ordinary)
	assert_object(Ink.architecture_material()).is_same(architecture)
	for material:ShaderMaterial in [ordinary,architecture]:
		var roofs:PackedVector3Array=material.get_shader_parameter("culture_roofs")
		var walls:PackedVector3Array=material.get_shader_parameter("culture_plasters")
		assert_int(roofs.size()).is_equal(4);assert_int(walls.size()).is_equal(4)
		assert_float(float(material.get_shader_parameter("culture_roof_mix"))).is_equal(Culture.ROOF_MIX)
		assert_str(material.shader.code).contains("culture_codes = INSTANCE_CUSTOM")
		assert_str(material.shader.code).contains("step(0.84,COLOR.a)")
		assert_str(material.shader.code).contains("step(COLOR.a, 0.985)*step(0.90, COLOR.a)")

func test_recorded_finish_refresh_is_city_scoped_and_keeps_vegetation_and_sites()->void:
	var plot:=_plot();plot.cultural_appearance=_profile(true)
	GameState.initialize_population_model();GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_plots=_plots(plot);GameState.settlement_routes=_routes();GameState.elapsed_days=11
	SettlementModel.ensure_founded()
	var terrain:Terrain=auto_free(Terrain.new())
	terrain.camera=Camera3D.new();terrain.camera.size=.5;terrain.add_child(terrain.camera)
	terrain.settler_marker=Area3D.new();terrain.add_child(terrain.settler_marker)
	terrain.settlement_blip=MeshInstance3D.new();terrain.add_child(terrain.settlement_blip)
	terrain._refresh_settlement_footprint()
	assert_int(terrain.requests).is_equal(1)
	var original:=terrain._settlement_cultural_visual_signature()
	var vegetation:=terrain.vegetation_builds
	var placement:=Keys.placement(GameState.settlement_plots,GameState.settlement_routes)
	var morphology:=terrain._settlement_morphology_visual_signature()
	for day in 4:
		GameState.elapsed_days+=1
		terrain._refresh_settlement_footprint()
		assert_int(terrain._settlement_cultural_visual_signature()).is_equal(original)
	assert_int(terrain.requests).is_equal(1)
	# The model's actual adoption/renewal event increments this existing revision.
	plot.cultural_appearance=_profile(false);GameState.morphology_revision+=1
	terrain._refresh_settlement_footprint()
	assert_int(terrain.requests).is_equal(2)
	assert_int(terrain._settlement_cultural_visual_signature()).is_not_equal(original)
	assert_str(terrain._settlement_morphology_visual_signature()).is_equal(morphology)
	assert_int(terrain.vegetation_builds).is_equal(vegetation)
	assert_int(terrain.settlement_layout_builds).is_zero()
	assert_int(Keys.placement(GameState.settlement_plots,GameState.settlement_routes)).is_equal(placement)
	GameState.resource_settlement_id="cultural_test_secondary";plot.cultural_appearance=_profile(true)
	assert_int(terrain._settlement_cultural_visual_signature()).is_equal(original)
	assert_int(terrain.cached_cultural_visual_signatures.size()).is_equal(2)
	# Aggregate fallback uses the same bounded finish without losing its alpha tag.
	var source:=Color(.52,.39,.27,.94)
	var plain:=_plot()
	assert_object(terrain._cultural_surface_tone(source,plain)).is_equal(source)
	assert_object(terrain._cultural_surface_tone(source,plain,true)).is_equal(source)
	for wall:bool in [false,true]:
		var painted:Color=terrain._cultural_surface_tone(source,plot,wall)
		assert_object(painted).is_not_equal(source)
		assert_float(painted.a).is_equal(source.a)
	plain.material_family="organic";plain.cultural_appearance=_profile(true)
	assert_object(terrain._cultural_surface_tone(source,plain,true)).is_equal(source)
