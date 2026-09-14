extends GdUnitTestSuite
const Notices=preload("res://scripts/hud/research_announcements.gd")
const DiscoveryPopup=preload("res://scripts/hud/discovery_popup.gd")
const Pause=preload("res://scripts/hud/simulation_pause.gd")
class Host extends Node:
	var game_speed:=3.0
	func _set_game_speed(value:float)->void:game_speed=value
func before_test()->void:
	GameState.reset_for_new_world(314159);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.known_discoveries.append_array(["food_drying","drainage","cordage"])
func fixture(width:int=1200,height:int=900)->Dictionary:
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(width,height);add_child(canvas)
	var host:=Host.new();canvas.add_child(host)
	var hud:=Control.new();host.add_child(hud)
	return {"canvas":canvas,"host":host,"hud":hud}
func test_routine_findings_do_not_pause_and_are_deduplicated()->void:
	var f:=fixture()
	var digest:=Notices.announce(f.host,f.hud,[{"id":"food_drying","day":12},{"id":"drainage","day":12}])
	assert_float(f.host.game_speed).is_equal(3.0)
	assert_int(digest.unread).is_equal(2)
	assert_bool(f.hud.has_meta("discovery_popup")).is_false()
	Notices.announce(f.host,f.hud,[{"id":"food_drying","day":12}])
	assert_int(digest.unread).is_equal(2)
	digest.clear()
	assert_bool(digest.notice.visible).is_false()
	assert_float(f.host.game_speed).is_equal(3.0)

func test_milestones_pause_while_routine_results_remain_in_digest()->void:
	GameState.known_discoveries.append("powered_flight")
	var f:=fixture()
	var digest:=Notices.announce(f.host,f.hud,[{"id":"powered_flight","day":100},{"id":"drainage","day":100}])
	assert_int(digest.unread).is_equal(1)
	assert_float(f.host.game_speed).is_equal(0.0)
	var popup:Variant=f.hud.get_meta("discovery_popup")
	assert_str(popup.current.id).is_equal("powered_flight")
	popup.close()
	assert_float(f.host.game_speed).is_equal(3.0)

func test_quiet_mode_never_pauses_even_for_first_discovery()->void:
	GameState.research_notification_mode="quiet"
	GameState.known_discoveries.assign(["seed_selection"])
	var f:=fixture()
	var digest:=Notices.announce(f.host,f.hud,[{"id":"seed_selection","day":1}])
	assert_float(f.host.game_speed).is_equal(3.0)
	assert_int(digest.unread).is_equal(1)

func test_all_mode_preserves_individual_announcements()->void:
	GameState.research_notification_mode="all"
	var f:=fixture()
	var digest:=Notices.announce(f.host,f.hud,[{"id":"drainage","day":1}])
	assert_int(digest.unread).is_equal(0)
	assert_float(f.host.game_speed).is_equal(0.0)
	f.hud.get_meta("discovery_popup").close()

func test_digest_fits_small_viewport_without_a_fullscreen_input_surface()->void:
	var f:=fixture(360,640)
	var digest:=Notices.announce(f.host,f.hud,[{"id":"drainage","day":1}])
	for i in 5:await get_tree().process_frame
	assert_bool(Rect2(0,0,360,640).encloses(digest.notice.get_global_rect())).is_true()
	assert_bool(Rect2(0,0,360,640).encloses(digest.open_button.get_global_rect())).is_true()
	assert_str(digest.latest_label.text).is_equal("Ground Drainage")
	assert_str(digest.date_label.text).is_equal("Y1 · D2")
	assert_bool(digest.open_button.clip_text).is_true()
	assert_int(digest.get_child_count()).is_equal(1)

func test_invalid_saved_preference_rejected_before_world_mutation()->void:
	var known:=GameState.known_discoveries.duplicate()
	var result:=SaveSystem._validate_human_payload({"reflected_GameState":{"research_notification_mode":"not_a_mode"}},777)
	assert_bool(result.has("error")).is_true()
	assert_array(GameState.known_discoveries).is_equal(known)

func test_unknown_findings_cannot_leak_into_digest()->void:
	var f:=fixture()
	var digest:=Notices.announce(f.host,f.hud,[{"id":"reactor_engineering","day":1}])
	assert_int(digest.unread).is_equal(0)
	assert_float(f.host.game_speed).is_equal(3.0)
	assert_bool(f.hud.has_meta("discovery_popup")).is_false()

func test_reflected_state_keeps_notification_preference()->void:
	GameState.research_notification_mode="quiet"
	var state:=SaveSystem._capture_reflected(GameState,[])
	assert_str(state.research_notification_mode).is_equal("quiet")
	GameState.research_notification_mode="all"
	SaveSystem._apply_reflected(GameState,{"research_notification_mode":state.research_notification_mode})
	assert_str(GameState.research_notification_mode).is_equal("quiet")
