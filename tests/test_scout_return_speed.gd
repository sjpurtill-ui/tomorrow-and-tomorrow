extends GdUnitTestSuite

class ReturnHud extends Control:
	var opened:Array=[]
	func open_detail(detail:Variant)->void:opened.append(detail)

func test_repeated_return_notifications_preserve_running_and_manual_pause()->void:
	var terrain:=preload("res://scripts/local_terrain.gd").new()
	var label:=Label.new()
	terrain.travel_status_label=label
	CivilizationSystem.scout_report_returned.connect(terrain._on_scout_report_returned)
	# A routine return (nothing new found) stays quiet.
	CivilizationSystem.scout_report_returned.emit({"mission_id":99,"day":100})
	assert_str(label.text).is_empty()
	# A newsworthy return points to the report, and never pauses or speeds play.
	for speed:float in [1.0,5.0,0.0]:
		terrain.game_speed=speed
		for party in 3:
			CivilizationSystem.scout_report_returned.emit({"mission_id":party,"day":100,"new_contact_count":1})
			assert_float(terrain.game_speed).is_equal(speed)
	# The report is told by the Chronicle's card; the status line points there.
	assert_str(label.text).contains("Chronicle")
	CivilizationSystem.scout_report_returned.disconnect(terrain._on_scout_report_returned)
	label.free()
	terrain.free()
