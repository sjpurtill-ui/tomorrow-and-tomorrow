extends GdUnitTestSuite
const Sheet = preload("res://scripts/hud/scouting_policy_panel.gd")
const Art = preload("res://scripts/hud/scouting_window_art.gd")
const Tokens = preload("res://scripts/hud/hud_tokens.gd")
var viewport: SubViewport
var sheet: Control

func before_test() -> void:
	WorldSimulation.clear()
	GameState.set_process(false); CivilizationSystem.set_process(false)
	GameState.reset_for_new_world(7751); CivilizationSystem.reset_for_new_world()
	GameState.ensure_population_total(360); GameState.elapsed_days=72
	GameState.settlement_site_committed=true
	ProgressionSystem.reset_for_new_world()
	CivilizationSystem.scouting_staff.set_policy(.05,"exploration")
	CivilizationSystem.scout_missions.assign([
		{"mission_id":1,"start_day":0,"return_day":90,"personnel":6,"provisions":297.0,"target_kind":"explore","target_label":"Northern hills"},
		{"mission_id":2,"start_day":50,"return_day":80,"personnel":6,"provisions":99.0,"target_kind":"recruit_people_visit","target_label":"Flintwick"}])
	viewport=SubViewport.new(); viewport.size=Vector2i(960,720); add_child(viewport)
	sheet=Sheet.new(); viewport.add_child(sheet)
	await await_idle_frame(); await await_idle_frame()

func after_test() -> void:
	viewport.queue_free(); await await_idle_frame()
	GameState.set_process(true); CivilizationSystem.set_process(true)

func test_live_policy_values_and_external_changes_do_not_issue_departures() -> void:
	assert_str(sheet.allocation.text).is_equal("5%")
	assert_str(sheet.staffing.text).contains("18 scouts · 12 away")
	var fog= _fog_snapshot()
	var missions=CivilizationSystem.scout_missions.duplicate(true)
	var food=FoodSystem.total_stored()
	CivilizationSystem.scouting_staff.set_policy(.02,"recruitment")
	sheet.refresh()
	assert_float(sheet.slider.value).is_equal(2.0)
	assert_bool(sheet.focus_buttons.recruitment.button_pressed).is_true()
	assert_array(CivilizationSystem.scout_missions).is_equal(missions)
	assert_float(FoodSystem.total_stored()).is_equal(food)
	assert_dict(_fog_snapshot()).is_equal(fog)

func _fog_snapshot() -> Dictionary:
	return CivilizationSystem.fog_snapshot().duplicate(true)

func test_party_controls_survive_days_and_keep_expanded_details() -> void:
	var toggle:Button=sheet.mission_rows[1].toggle
	toggle.pressed.emit()
	assert_bool(sheet.mission_rows[1].detail.visible).is_true()
	GameState.elapsed_days+=1; sheet.refresh()
	assert_object(sheet.mission_rows[1].toggle).is_same(toggle)
	assert_bool(sheet.mission_rows[1].detail.visible).is_true()
	assert_str(sheet.mission_rows[1].subtitle.text).contains("~17d")
	CivilizationSystem.scout_missions.remove_at(0); sheet.refresh()
	assert_int(sheet.mission_rows.size()).is_equal(1)
	assert_bool(sheet.mission_rows.has(1)).is_false()

func test_overdue_party_never_displays_secret_return_date_or_carried_finds() -> void:
	CivilizationSystem.scout_missions[0].actual_return_day=190
	CivilizationSystem.scout_missions[0].carried_collections=[{"name":"Secret object"}]
	GameState.elapsed_days=95; sheet.refresh()
	assert_str(sheet.mission_rows[1].subtitle.text).contains("5d overdue")
	assert_str(sheet.mission_rows[1].detail.text).not_contains("190")
	assert_bool(sheet.latest_card.visible).is_false()
	assert_str(sheet.collection_button.text).is_equal("Brought home · 0")

func test_art_and_latest_return_follow_the_actual_subject() -> void:
	var record={"name":"Selected cutting stone","kind":"specimen","discovery_id":"stone_sorting","source_name":"Northern hills","returned_day":70,"study":.5}
	GameState.society_exchange.collections.a=record
	sheet.refresh()
	assert_bool(sheet.latest_card.visible).is_true()
	assert_object(sheet.latest_image.texture).is_same(Art.STONE)
	GameState.society_exchange.collections.b={"name":"A remembered epic","kind":"culture","discovery_id":"oral_epics","source_name":"Flintwick","returned_day":72,"study":1.0}
	sheet.refresh()
	assert_str(sheet.latest_name.text).is_equal("A remembered epic")
	assert_bool(sheet.latest_image.texture==Art.STONE).is_false()
	assert_bool(Art.stone_find({"kind":"knowledge","discovery_id":"stone_sorting"})).is_false()

func test_small_windows_keep_fixed_close_and_done_controls_reachable() -> void:
	for shape:Vector2i in [Vector2i(960,720),Vector2i(640,520),Vector2i(340,640)]:
		viewport.size=shape
		await await_idle_frame(); await await_idle_frame()
		assert_bool(Rect2(Vector2.ZERO,shape).encloses(sheet.panel.get_global_rect())).is_true()
		assert_bool(sheet.panel.get_global_rect().encloses(sheet.close_button.get_global_rect())).is_true()
		assert_bool(sheet.panel.get_global_rect().encloses(sheet.done_button.get_global_rect())).is_true()
		assert_bool(sheet.panel.get_global_rect().encloses(sheet.slider.get_global_rect())).is_true()

func test_stopping_allocation_keeps_absent_parties_visible() -> void:
	sheet.slider.value=0
	assert_float(float(CivilizationSystem.scouting_staff.data.share)).is_equal(0.0)
	assert_int(sheet.mission_rows.size()).is_equal(2)
	assert_str(sheet.status.text).contains("finish and return")

func test_advanced_capability_retires_the_primitive_expedition_art() -> void:
	assert_bool(sheet.ancient).is_true()
	sheet.queue_free(); await await_idle_frame()
	ProgressionSystem.domain_levels.production=5
	sheet=Sheet.new(); viewport.add_child(sheet)
	await await_idle_frame()
	assert_bool(sheet.ancient).is_false()
	assert_bool(sheet.hero.get_child(0).texture==Art.HERO).is_false()
	assert_float(sheet.slider.value).is_equal(5.0)

func test_light_and_dark_preferences_keep_scouting_surfaces_readable()->void:
	var original:=Tokens.color_mode
	for mode:String in ["light","dark"]:
		Tokens.color_mode=mode
		sheet.queue_free();await await_idle_frame()
		sheet=Sheet.new();viewport.add_child(sheet);await await_idle_frame()
		var card:StyleBoxFlat=sheet.latest_card.get_theme_stylebox("panel")
		assert_float(card.bg_color.a).is_equal(1.0)
		for ink:Color in [Art.INK,Art.SOFT,Art.GOLD]:
			assert_float(contrast(ink,card.bg_color)).is_greater_equal(4.5)
			# Worst-case white texel at the panel's maximum texture opacity.
			assert_float(contrast(ink,Art.CLAY.lerp(Color.WHITE,.10))).is_greater_equal(4.5)
		var origin:StyleBoxFlat=sheet.origin_selector.get_theme_stylebox("normal")
		assert_float(contrast(sheet.origin_selector.get_theme_color("font_color"),origin.bg_color)).is_greater_equal(4.5)
		var popup:PopupMenu=sheet.origin_selector.get_popup()
		assert_float(contrast(popup.get_theme_color("font_color"),(popup.get_theme_stylebox("panel") as StyleBoxFlat).bg_color)).is_greater_equal(4.5)
	Tokens.color_mode=original

func contrast(a:Color,b:Color)->float:
	var first:=a.srgb_to_linear().get_luminance()
	var second:=b.srgb_to_linear().get_luminance()
	return (maxf(first,second)+.05)/(minf(first,second)+.05)
