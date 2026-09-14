extends GdUnitTestSuite

class ReturnHud extends Control:
	var opened:Array=[]
	func open_detail(detail:Variant)->void:opened.append(detail)

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

func test_return_digest_queues_reports_and_opens_the_newest_without_pausing()->void:
	var terrain:Node=auto_free(preload("res://scripts/local_terrain.gd").new())
	var hud:ReturnHud=auto_free(ReturnHud.new())
	add_child(hud)
	var notice:CanvasLayer=preload("res://scripts/hud/scout_return_notice.gd").announce(terrain,hud,{"mission_id":1,"day":20,"recruitment_account":{"summary":"No household accepted."}})
	preload("res://scripts/hud/scout_return_notice.gd").announce(terrain,hud,{"mission_id":2,"day":21,"recruits":3})
	await get_tree().process_frame
	assert_int(notice.reports.size()).is_equal(2)
	assert_str(notice.open_button.text).contains("3 newcomers arrived")
	notice.open_latest()
	assert_int(hud.opened.size()).is_equal(1)
	assert_int(notice.reports.size()).is_equal(1)
	assert_str(notice.open_button.text).contains("Recruitment party returned")
