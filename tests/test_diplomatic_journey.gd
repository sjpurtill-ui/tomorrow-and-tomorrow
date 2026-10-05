extends GdUnitTestSuite
const Journey=preload("res://scripts/diplomatic_journey.gd")
const Pause=preload("res://scripts/hud/simulation_pause.gd")
class Simulation extends Node:
	var game_speed:=3.0
	func _set_game_speed(value:float)->void:game_speed=value
class Map extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _update_time_interface()->void:pass

## The scene a test swapped out as current, put back even when it fails.
var _previous_scene:Node
var _swapped_scene:=false

func after_test()->void:
	if _swapped_scene:get_tree().current_scene=_previous_scene
	_swapped_scene=false;_previous_scene=null

func test_journey_preserves_destination_and_schedules_without_live_tracking()->void:
	var mission:={"depart_day":10,"arrival_day":20,"return_day":30,"destination":"Kassul","target_position":{"x":50,"z":17},"origin_position":{"x":0,"z":0},"distance_km":52.8}
	var outbound:=Journey.describe(mission,15)
	assert_str(outbound.phase).is_equal("Outbound")
	assert_float(outbound.progress).is_equal(.25)
	assert_str(outbound.destination).is_equal("Kassul")
	assert_dict(outbound.target_position).is_equal(mission.target_position)
	assert_bool(outbound.has("current_position")).is_false()
	assert_str(Journey.describe(mission,21).phase).is_equal("Returning")
	assert_float(Journey.describe(mission,31).progress).is_equal(1.0)
	assert_str(Journey.describe(mission,31).phase).is_equal("Home")
func test_nested_dialogs_restore_speed_only_after_both_close()->void:
	var host:Simulation=auto_free(Simulation.new())
	var first:=Pause.new();var second:=Pause.new()
	first.acquire(host);second.acquire(host)
	assert_float(host.game_speed).is_equal(0.0)
	first.release();assert_float(host.game_speed).is_equal(0.0)
	second.release();assert_float(host.game_speed).is_equal(3.0)
	second.release();assert_float(host.game_speed).is_equal(3.0)
func test_dialog_does_not_resume_a_previously_paused_game()->void:
	var host:Simulation=auto_free(Simulation.new());host.game_speed=0
	var pause:=Pause.new();pause.acquire(host);pause.release()
	assert_float(host.game_speed).is_equal(0.0)
## Word with a foreign ruler happens inside the court: ForeignDiplomacy.open
## hands the conversation to the court director (the standalone diplomacy
## panel was retired when every leader dealing moved into the one court). The
## court pauses the game while it is open; closing it restores the speed.
func test_opening_conversation_pauses_and_closing_restores_game()->void:
	var id:=String(preload("res://tests/diplomacy_fixture.gd").build_fixture())
	var host:Simulation=auto_free(Simulation.new());get_tree().root.add_child(host)
	_previous_scene=get_tree().current_scene;_swapped_scene=true;get_tree().current_scene=host
	var director:Node=auto_free(preload("res://scripts/audience_director.gd").new())
	get_tree().root.add_child(director);director.set_process(false)
	ForeignDiplomacy.open(id)
	var court:Control=director.modal
	assert_bool(is_instance_valid(court)).override_failure_message("ForeignDiplomacy.open did not reach the court").is_true()
	if not is_instance_valid(court):return
	assert_str(String(court.mode)).is_equal("foreign")
	assert_str(String(court.foreign_civ)).is_equal(id)
	assert_float(host.game_speed).is_equal(0.0)
	court.free()
	assert_float(host.game_speed).is_equal(3.0)
	# Drain the deferred opening transition after an immediate close.
	await get_tree().process_frame

func test_map_speed_controls_cannot_run_time_through_a_conversation()->void:
	GameState.founding_focus="provision"
	var host:Node=auto_free(Map.new());host.game_speed=3.0
	var pause:=Pause.new();pause.acquire(host)
	host._set_game_speed(5.0)
	assert_float(float(host.game_speed)).is_equal(0.0)
	pause.release()
	assert_float(float(host.game_speed)).is_equal(3.0)
