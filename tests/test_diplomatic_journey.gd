extends GdUnitTestSuite
const Journey=preload("res://scripts/diplomatic_journey.gd")
const Pause=preload("res://scripts/hud/simulation_pause.gd")
class Simulation extends Node:
	var game_speed:=3.0
	func _set_game_speed(value:float)->void:game_speed=value

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
func test_opening_conversation_pauses_and_closing_restores_game()->void:
	GameState.reset_for_new_world(424242);CivilizationSystem.reset_for_new_world()
	var civ:Dictionary=CivilizationSystem.civilizations[0];civ.player_relation.contact_level=2
	var host:Simulation=auto_free(Simulation.new());get_tree().root.add_child(host)
	var previous:=get_tree().current_scene;get_tree().current_scene=host
	ForeignDiplomacy.open(String(civ.id))
	assert_float(host.game_speed).is_equal(0.0)
	assert_bool(is_instance_valid(ForeignDiplomacy.panel)).is_true()
	ForeignDiplomacy.panel.free()
	assert_float(host.game_speed).is_equal(3.0)
	get_tree().current_scene=previous
