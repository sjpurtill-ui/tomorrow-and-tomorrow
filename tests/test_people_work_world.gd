extends GdUnitTestSuite
const World=preload("res://scripts/hud/people_work_world.gd")

func test_all_roles_have_stable_room_for_the_entire_workforce()->void:
	var zones:=World.zones()
	assert_int(zones.size()).is_equal(9)
	for role:String in World.ROLES:
		var points:=World.work_positions(role,100)
		assert_int(points.size()).is_equal(100)
		assert_that(points.slice(0,7)).is_equal(World.work_positions(role,7))
		var occupied:=Rect2(Vector2(points[0].dot(World.RIGHT),points[0].dot(World.UP)),Vector2.ZERO)
		for index in points.size():
			occupied=occupied.expand(Vector2(points[index].dot(World.RIGHT),points[index].dot(World.UP)))
			assert_bool(Geometry2D.is_point_in_polygon(points[index],zones[role].polygon)).is_true()
			assert_bool(World.bounds().has_point(points[index])).is_true()
			for other in range(index):assert_float(points[index].distance_to(points[other])).is_greater(.0008)
			assert_float(points[index].distance_to(zones[role].scenery)).is_greater(.0048)
		assert_float(occupied.size.x).is_greater(.020)
		assert_float(occupied.size.y).is_greater(.014)

func test_every_transfer_uses_gates_and_misses_worksite_objects()->void:
	var zones:=World.zones()
	for from_role:String in World.ROLES:
		for to_role:String in World.ROLES:
			if from_role==to_role:continue
			var route:=World.path_for_transfer(from_role,to_role)
			assert_that(route[0]).is_equal(zones[from_role].gate)
			assert_that(route[-1]).is_equal(zones[to_role].gate)
			for index in range(1,route.size()):
				for role:String in World.ROLES:
					var center:Vector2=zones[role].scenery
					var nearest:=Geometry2D.get_closest_point_to_segment(center,route[index-1],route[index])
					assert_float(nearest.distance_to(center)).is_greater(.0055)

func test_scene_is_illustrative_and_keeps_model_data_untouched()->void:
	var before:=var_to_bytes([GameState.settlement_plots,GameState.settlement_routes,GameState.population_allocations])
	var parent:Node3D=auto_free(Node3D.new());add_child(parent)
	var result:=World.render(parent,func(at:Vector2,lift:float)->Vector3:return Vector3(at.x,lift,at.y))
	assert_bool(result.representative).is_true()
	assert_int(result.zones.size()).is_equal(9)
	assert_int(result.obstacles.size()).is_equal(9)
	for role:String in World.ROLES:assert_int(result.targets[role].size()).is_equal(100)
	assert_that(var_to_bytes([GameState.settlement_plots,GameState.settlement_routes,GameState.population_allocations])).is_equal(before)

func test_sprite_cell_boundaries_are_transparent()->void:
	for path:String in [World.SCENERY,World.ACTIVITY_GROUNDS]:
		var art:=Image.load_from_file(path)
		assert_object(art).is_not_null()
		for x in [0,art.get_width()/3,art.get_width()*2/3,art.get_width()-1]:
			for y in art.get_height():assert_float(art.get_pixel(x,y).a).is_less(.02)
		for x in art.get_width():assert_float(art.get_pixel(x,art.get_height()/2).a).is_less(.02)

func test_recorded_fabric_can_change_workshop_but_calendar_cannot()->void:
	assert_dict(World.recorded_style("Crafting",{"year":3000,"population":90000})).is_empty()
	var plot:=preload("res://tests/city_evolution_visual_fixture.gd").plot(5)
	plot.land_use="workshop";plot.form="covered_workshop";plot.material_family="timber";plot.status="active"
	var before:=var_to_bytes(plot)
	var style:=World.recorded_style("Crafting",{"snapshot":{"plots":[plot]}})
	assert_dict(style).is_not_empty()
	assert_that(var_to_bytes(plot)).is_equal(before)
	assert_dict(World.recorded_style("Food",{"snapshot":{"plots":[plot]}})).is_empty()

