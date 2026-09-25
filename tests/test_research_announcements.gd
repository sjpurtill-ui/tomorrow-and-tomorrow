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
## Research news has one home, the Chronicle: there is no research toast or
## unread counter, and nothing pauses. Only the player's own "every discovery"
## choice opens the full reading card as well.
func test_routine_and_milestone_findings_raise_no_toast_or_popup()->void:
	GameState.known_discoveries.append("powered_flight")
	var f:=fixture()
	assert_object(Notices.announce(f.host,f.hud,[{"id":"food_drying","day":12},{"id":"drainage","day":12},{"id":"powered_flight","day":12}])).is_null()
	assert_bool(f.hud.has_meta("discovery_popup")).is_false()
	assert_bool(f.hud.has_meta("research_digest")).is_false()
	assert_int(f.hud.get_child_count()).is_equal(0)
	assert_float(f.host.game_speed).is_equal(3.0)

func test_quiet_mode_never_pauses_even_for_first_discovery()->void:
	GameState.research_notification_mode="quiet"
	GameState.known_discoveries.assign(["seed_selection"])
	var f:=fixture()
	assert_object(Notices.announce(f.host,f.hud,[{"id":"seed_selection","day":1}])).is_null()
	assert_float(f.host.game_speed).is_equal(3.0)

func test_all_mode_opens_the_reading_card_without_pausing()->void:
	GameState.research_notification_mode="all"
	var f:=fixture()
	var popup:=Notices.announce(f.host,f.hud,[{"id":"drainage","day":1}])
	assert_object(popup).is_not_null()
	assert_float(f.host.game_speed).is_equal(3.0)
	f.hud.get_meta("discovery_popup").close()

func test_invalid_saved_preference_rejected_before_world_mutation()->void:
	var known:=GameState.known_discoveries.duplicate()
	var result:=SaveSystem._validate_human_payload({"reflected_GameState":{"research_notification_mode":"not_a_mode"}},777)
	assert_bool(result.has("error")).is_true()
	assert_array(GameState.known_discoveries).is_equal(known)

func test_unknown_findings_cannot_leak_into_a_card()->void:
	GameState.research_notification_mode="all"
	var f:=fixture()
	assert_object(Notices.announce(f.host,f.hud,[{"id":"reactor_engineering","day":1}])).is_null()
	assert_float(f.host.game_speed).is_equal(3.0)
	assert_bool(f.hud.has_meta("discovery_popup")).is_false()

func test_reflected_state_keeps_notification_preference()->void:
	GameState.research_notification_mode="quiet"
	var state:=SaveSystem._capture_reflected(GameState,[])
	assert_str(state.research_notification_mode).is_equal("quiet")
	GameState.research_notification_mode="all"
	SaveSystem._apply_reflected(GameState,{"research_notification_mode":state.research_notification_mode})
	assert_str(GameState.research_notification_mode).is_equal("quiet")
