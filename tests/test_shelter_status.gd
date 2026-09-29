extends GdUnitTestSuite
const Status=preload("res://scripts/hud/shelter_status.gd")
func test_starting_capacity_is_not_a_completed_building()->void:
	var report:=Status.describe(["Hearth Circle"],150,108)
	assert_bool(report.built).is_false()
	assert_str(report.detail).contains("No shelters built yet").contains("cover 150 people").contains("Everyone has a roof")
func test_finished_shelters_use_total_capacity()->void:
	var report:=Status.describe(["Hearth Circle","Lean-to Shelters"],240,108)
	assert_bool(report.built).is_true()
	assert_str(report.detail).contains("are built").contains("240 people in all")
func test_the_carried_tents_are_named_when_known()->void:
	var report:=Status.describe(["Hearth Circle","Lean-to Shelters"],240,97,150)
	assert_str(report.detail).contains("240 people in all, 150 of them in the tents carried on the journey").contains("Everyone has a roof")
	# All built here, or not known: nothing about tents.
	assert_str(Status.describe(["Lean-to Shelters"],240,97,0).detail).not_contains("tents")
	assert_str(Status.describe(["Lean-to Shelters"],240,97).detail).not_contains("tents")
func test_shortage_is_visible_even_with_completed_shelters()->void:
	var report:=Status.describe(["Lean-to Shelters"],240,300)
	assert_str(report.detail).contains("60 people sleep in the open")
func test_zero_capacity_does_not_invent_starting_places()->void:
	var report:=Status.describe([],0,30)
	assert_bool(report.built).is_false()
	assert_str(report.detail).contains("cover 0 people").contains("30 people sleep in the open")
