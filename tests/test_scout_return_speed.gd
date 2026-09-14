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
	assert_str(notice.title.text).contains("3 newcomers arrived")
	assert_str(notice.open_button.text).is_equal("Open illustrated report  →")
	notice.open_latest()
	assert_int(hud.opened.size()).is_equal(1)
	assert_int(notice.reports.size()).is_equal(1)
	assert_str(notice.title.text).contains("Recruitment party returned")

func test_return_card_is_bounded_and_uses_explicit_type()->void:
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(360,640);add_child(canvas)
	var terrain:Node=auto_free(preload("res://scripts/local_terrain.gd").new())
	var hud:ReturnHud=auto_free(ReturnHud.new());canvas.add_child(hud)
	var notice:CanvasLayer=preload("res://scripts/hud/scout_return_notice.gd").announce(terrain,hud,{"mission_id":1,"day":3132,"discoveries":[{"kind":"artifact","title":"A deliberately very long returned artifact title that must remain inside the notification card","description":"A long account that must wrap without forcing the action beyond the available viewport."}]})
	for i in 5:await get_tree().process_frame
	assert_bool(Rect2(0,0,360,640).encloses(notice.notice.get_global_rect())).is_true()
	assert_bool(Rect2(0,0,360,640).encloses(notice.open_button.get_global_rect())).is_true()
	assert_bool(notice.open_button.clip_text).is_true()
	assert_object(notice.title.get_theme_font("font")).is_not_null()
	var item:={"kind":"artifact","artifact_origin":"prehistoric","art_collection":"prehistoric-v1","source_id":"","catalogue_id":0}
	assert_str(notice._preview_texture({},item).resource_path).is_equal("res://assets/ui/artifacts/prehistoric-v1/artifact-0000.png")
