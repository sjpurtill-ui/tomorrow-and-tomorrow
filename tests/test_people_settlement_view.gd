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
