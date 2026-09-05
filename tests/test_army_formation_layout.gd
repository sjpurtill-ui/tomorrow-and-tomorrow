extends GdUnitTestSuite

func test_large_equipment_does_not_form_an_infantry_width_procession()->void:
	assert_int(ArmyFigureFormation.group_frontage_columns(5,10.0,6.0)).is_equal(3)
	assert_int(ArmyFigureFormation.group_frontage_columns(40,10.0,9.0)).is_equal(8)

func test_group_frontage_is_bounded_for_empty_and_partial_ranks()->void:
	assert_int(ArmyFigureFormation.group_frontage_columns(0,10.0,6.0)).is_equal(0)
	for amount in [1,2,3,5,40,256]:
		for pitch in [1.25,3.2,6.0,9.0]:
			var columns:=ArmyFigureFormation.group_frontage_columns(amount,10.0,pitch)
			assert_int(columns).is_greater_equal(1)
			assert_int(columns).is_less_equal(amount)

func test_mixed_arms_retain_distinct_clearance()->void:
	assert_float(ArmyFigureFormation.visual_spacing("line_infantry",1.25)).is_equal(1.25)
	assert_float(ArmyFigureFormation.visual_spacing("war_elephant",1.25)).is_equal(6.0)
	assert_float(ArmyFigureFormation.visual_spacing("counterweight_trebuchet",1.25)).is_equal(9.0)
