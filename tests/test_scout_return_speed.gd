extends GdUnitTestSuite

func test_repeated_return_notifications_preserve_running_and_manual_pause()->void:
	var terrain:=preload("res://scripts/local_terrain.gd").new()
	var label:=Label.new()
	terrain.travel_status_label=label
	CivilizationSystem.scout_report_returned.connect(terrain._on_scout_report_returned)
	for speed:float in [1.0,5.0,0.0]:
		terrain.game_speed=speed
		for party in 3:
			CivilizationSystem.scout_report_returned.emit({"mission_id":party,"day":100})
			assert_float(terrain.game_speed).is_equal(speed)
	assert_str(label.text).contains("WORLD > SCOUTING")
	CivilizationSystem.scout_report_returned.disconnect(terrain._on_scout_report_returned)
	label.free()
	terrain.free()
