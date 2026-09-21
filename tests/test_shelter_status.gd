extends GdUnitTestSuite
const Status=preload("res://scripts/hud/shelter_status.gd")
func test_starting_capacity_is_not_a_completed_building()->void:
	var report:=Status.describe(["Hearth Circle"],150,108)
	assert_bool(report.built).is_false()
	assert_str(report.detail).contains("No built shelters").contains("150 starting camp")
func test_finished_shelters_use_total_capacity()->void:
	var report:=Status.describe(["Hearth Circle","Lean-to Shelters"],240,108)
	assert_bool(report.built).is_true()
	assert_str(report.detail).contains("completed").contains("240 total")
func test_shortage_is_visible_even_with_completed_shelters()->void:
	var report:=Status.describe(["Lean-to Shelters"],240,300)
	assert_str(report.detail).contains("60 people beyond shelter capacity")
func test_zero_capacity_does_not_invent_starting_places()->void:
	var report:=Status.describe([],0,30)
	assert_bool(report.built).is_false()
	assert_str(report.detail).contains("0 starting camp").contains("30 people beyond")
