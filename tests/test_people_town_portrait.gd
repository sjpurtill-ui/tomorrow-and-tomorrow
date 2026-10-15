extends GdUnitTestSuite
const Portrait = preload("res://scripts/hud/people_town_portrait.gd")

func test_population_selects_density_at_boundaries_in_both_directions() -> void:
	for pair: Array in [[0,"camp"],[120,"camp"],[149,"camp"],[150,"hearth"],[399,"hearth"],[400,"village"],[1499,"village"],[1500,"town"],[5999,"town"],[6000,"large_town"],[10000,"large_town"],[149,"camp"]]:
		assert_str(Portrait.stage({"population": pair[0]}).id).is_equal(pair[1])

func test_selection_does_not_depend_on_worker_count_calendar_or_edit_its_input() -> void:
	var input := {"population": 120, "allocations": {"Food": 2000}, "year": 4000}
	var before := var_to_bytes(input)
	assert_str(Portrait.stage(input).id).is_equal("camp")
	assert_that(var_to_bytes(input)).is_equal(before)
	var selected := Portrait.stage(input)
	selected.id = "modified"
	assert_str(Portrait.stage(input).id).is_equal("camp")

func test_every_portrait_has_a_real_image_and_selectable_work_areas() -> void:
	for population: int in [120, 300, 750, 2400, 6000]:
		var context := {"population": population}
		assert_bool(FileAccess.file_exists(Portrait.texture_path(context))).is_true()
		var areas := Portrait.areas(context)
		assert_int(areas.size()).is_equal(9)
		for role: String in Portrait.ROLES:
			var area: Dictionary = areas[role]
			assert_bool(Geometry2D.is_point_in_polygon(area.anchor, area.polygon)).is_true()
			assert_bool(area.focus.has_point(area.anchor)).is_true()
			for point: Vector2 in area.polygon:
				assert_bool(point.x >= 0 and point.x <= 1 and point.y >= 0 and point.y <= 1).is_true()
