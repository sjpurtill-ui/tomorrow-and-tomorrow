extends GdUnitTestSuite
const Data=preload("res://scripts/hud/people_settlement_scene.gd")
const View=preload("res://scripts/hud/people_settlement_view.gd")
const Fixture=preload("res://tests/city_evolution_visual_fixture.gd")

func _context()->Dictionary:
	var plot:=Fixture.plot(1)
	var routes:Array[Dictionary]=[{"id":1,"active":true,"points":PackedVector2Array([Vector2(-.025,.022),Vector2(.025,.022)]),"width_m":2}]
	return {"plots":[plot],"routes":routes,"population":93,"origin":Vector3.ZERO}

func test_snapshot_is_detached_and_calendar_never_upgrades_fabric()->void:
	var context:=_context();var copy:=Data.snapshot(context);var key:=Data.signature(copy)
	context.plots[0].condition=.1
	assert_float(copy.plots[0].condition).is_equal(.94)
	context["population"]=9000;context["year"]=5000
	context.plots[0].condition=.94
	assert_int(Data.signature(Data.snapshot(context))).is_equal(key)
	context.plots[0]["construction_progress"]=.5
	context.plots[0].status="under_construction"
	assert_int(Data.signature(Data.snapshot(context))).is_not_equal(key)

func test_role_locations_use_recorded_parcels_and_explain_shared_ground()->void:
	var context:=_context();var field:=Fixture.plot(2,Vector2(.04,0));field.land_use="field"
	var workshop:=Fixture.plot(3,Vector2(.08,0));workshop.land_use="workshop"
	var plots:Array[Dictionary]=[];plots.assign(context.plots);plots.append(field);plots.append(workshop)
	var roles:=Data.zones(plots,[])
	assert_int(roles.size()).is_equal(9)
	assert_bool(roles.Food.physical).is_true();assert_array(roles.Food.plot_ids).is_equal([2])
	assert_bool(roles.Crafting.physical).is_true();assert_array(roles.Crafting.plot_ids).is_equal([3])
	assert_bool(roles.Defense.physical).is_false()
	assert_str(roles.Defense.source).is_equal("Shared work ground")

func test_view_reuses_geometry_focus_projects_and_people_are_bounded()->void:
	var context:=_context();var before:=var_to_bytes(context)
	var town:Control=auto_free(View.new());add_child(town);town.size=Vector2(900,600);town.configure(context)
	assert_that(var_to_bytes(context)).is_equal(before)
	assert_int(town.geometry_builds).is_equal(1)
	context.population=500000;town.update_state(context)
	assert_int(town.geometry_builds).is_equal(1)
	assert_int(town.visual_people_count).is_equal(View.MAX_PEOPLE)
	town.focus_role("Crafting");town._process(.1)
	assert_str(town.focused_role).is_equal("Crafting")
	assert_int(town.role_screen_positions().size()).is_equal(9)
	for point:Vector2 in town.role_screen_positions().values():assert_bool(point.is_finite()).is_true()
	context.plots[0].damage={"fire":.4};town.update_state(context)
	assert_int(town.geometry_builds).is_equal(2)
	assert_str(town.focused_role).is_equal("Crafting")
	town.reset_view();assert_str(town.focused_role).is_empty()

func test_recorded_expansion_changes_footprint_without_population_guess()->void:
	var context:=_context();var first:=Data.snapshot(context);var early:=Data.bounds(first.plots,first.routes)
	context.plots.append(Fixture.plot(2,Vector2(.14,.1)))
	var second:=Data.snapshot(context);var later:=Data.bounds(second.plots,second.routes)
	assert_bool(later.size.x>early.size.x).is_true();assert_bool(later.size.y>early.size.y).is_true()

func test_water_service_is_not_painted_as_a_pond_and_people_material_is_private()->void:
	var context:=_context()
	context.routes=[]
	context.plots[0].land_use="water"
	context.plots[0].form="carried_water_point"
	var town:Control=auto_free(View.new());add_child(town);town.size=Vector2(900,600);town.configure(context)
	assert_object(town.model.get_node_or_null("RecordedGroundAndRoutes")).is_null()
	assert_object(town.model.get_node_or_null("RecordedWaterCourses")).is_null()
	var shared:ShaderMaterial=preload("res://scripts/map_life_ink.gd").material("person")
	var visible_before:bool=shared.get_shader_parameter("map_people_visible")
	town.update_state(_context())
	assert_object(town._people_paint).is_not_same(shared)
	assert_bool(town._people_paint.get_shader_parameter("map_people_visible")).is_true()
	assert_bool(shared.get_shader_parameter("map_people_visible")).is_equal(visible_before)
	assert_int(town.camera.projection).is_equal(Camera3D.PROJECTION_PERSPECTIVE)

func test_clothing_follows_recorded_knowledge_and_supply_without_rebuilding_town()->void:
	var context:=_context()
	context["population"]=93
	context["clothing_knowledge"]=[]
	context["clothing_context"]={"adoption":{},"coverage":1.0}
	var town:Control=auto_free(View.new());add_child(town);town.size=Vector2(900,600);town.configure(context)
	var first_key:int=town._people_key
	var first_builds:int=town.geometry_builds
	var shared:ShaderMaterial=preload("res://scripts/map_life_ink.gd").material("person")
	var shared_shader:=shared.shader.code
	context.clothing_knowledge=["plain_weaving"]
	context.clothing_context={"adoption":{"plain_weaving":1.0},"coverage":1.0}
	town.update_state(context)
	assert_int(town._people_key).is_not_equal(first_key)
	assert_int(town.geometry_builds).is_equal(first_builds)
	var woven_key:int=town._people_key
	context.clothing_context.coverage=0.0
	town.update_state(context)
	assert_int(town._people_key).is_not_equal(woven_key)
	assert_int(town.geometry_builds).is_equal(first_builds)
	assert_str(shared.shader.code).is_equal(shared_shader)

func test_painted_buildings_preserve_roof_material_and_construction_truth()->void:
	var art=preload("res://scripts/hud/people_settlement_art.gd")
	var tent:Dictionary={"form":"portable_shelter_cluster","material_family":"organic","roof_plan":"ridge_light_shelter","land_use":"residential_compound","storeys":1,"status":"active"}
	assert_int(art.building_style({"plot":tent}).cell).is_equal(0)
	tent.status="under_construction";tent.construction_progress=.5
	assert_dict(art.building_style({"plot":tent})).is_empty()
	tent.status="ruin"
	assert_dict(art.building_style({"plot":tent})).is_empty()
	var house:Dictionary={"form":"earthen_household","material_family":"earth","roof_plan":"irregular_flat","land_use":"residential_compound","storeys":1,"status":"active"}
	assert_str(art.building_style({"plot":house}).atlas).is_equal(art.ROOFS)
	assert_int(art.building_style({"plot":house}).cell).is_equal(0)
	house.roof_plan="thatched_ridge"
	assert_int(art.building_style({"plot":house}).cell).is_equal(4)

func test_mature_paint_requires_recorded_floors_roof_and_installed_chimney()->void:
	var art=preload("res://scripts/hud/people_settlement_art.gd")
	var plot:Dictionary={"form":"dense_mixed_frontage","material_family":"stone","roof_plan":"thatched_ridge","land_use":"residential_compound","storeys":2,"fabric_generation":5,"status":"active"}
	assert_dict(art.building_style({"plot":plot})).is_empty()
	plot.building_materials={"applied":["wall_chimneys"]}
	assert_int(art.building_style({"plot":plot}).cell).is_equal(2)
	plot.storeys=3
	assert_dict(art.building_style({"plot":plot})).is_empty()
	plot.roof_plan="fired_tile_roof"
	assert_int(art.building_style({"plot":plot}).cell).is_equal(3)
	plot.storeys=8
	assert_dict(art.building_style({"plot":plot})).is_empty()

func test_painted_atlas_regions_stay_inside_fractional_cells()->void:
	var art=preload("res://scripts/hud/people_settlement_art.gd")
	for path:String in [art.BUILDINGS,art.DETAILS,art.MATURE,art.ROOFS]:
		var texture:Texture2D=art.atlas(path);var rows:=2 if path in [art.MATURE,art.ROOFS] else 3
		var columns:=3 if path==art.ROOFS else 4
		for cell in rows*columns:
			var region:Rect2i=art.region(path,cell,rows,columns)
			assert_bool(region.has_area()).is_true()
			assert_bool(Rect2i(0,0,texture.get_width(),texture.get_height()).encloses(region)).is_true()
			assert_int(region.position.x).is_greater_equal(roundi(float(cell%columns)*texture.get_width()/columns))
			assert_int(region.end.x).is_less_equal(roundi(float(cell%columns+1)*texture.get_width()/columns))
