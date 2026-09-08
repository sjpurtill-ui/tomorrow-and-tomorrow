extends GdUnitTestSuite
class World extends Node:
	var feedback:Dictionary={}
	func _report_military_action(result:Dictionary)->void:feedback=result
class Shell extends Control:
	var refreshes:=0
	func request_immediate_dock_refresh()->void:refreshes+=1
func before_test()->void:
	GameState.reset_for_new_world(424242);SettlementModel.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(400)
	GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","position":Vector2(10,10),"primary":false,"population_share":.2,"founded_day":20})

func test_staffing_action_changes_only_requested_city_without_enlisting_people()->void:
	var world:World=auto_free(World.new());var shell:Shell=auto_free(Shell.new())
	var provider:=preload("res://scripts/hud/content/dock_content_military.gd").new(world,shell)
	var home_focus:=String(GameState.player_settlements[0].get("management_focus",""))
	var troops:=MilitaryCampaign._mobilized_count()
	var actions:Array=provider._training_staff_actions()
	assert_int(actions.size()).is_equal(2)
	actions[1].on_press.call()
	assert_str(String(GameState.player_settlements[1].management_focus)).is_equal("defense")
	assert_bool(GameState.player_settlements[1].auto_manage).is_false()
	assert_str(String(GameState.player_settlements[0].get("management_focus",""))).is_equal(home_focus)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(troops)
	assert_bool(provider._training_staff_actions()[1].disabled).is_true()
	assert_bool(world.feedback.has("message")).is_true()
	assert_int(shell.refreshes).is_equal(1)

func test_occupied_city_cannot_be_directed_from_army_preparation()->void:
	var world:World=auto_free(World.new());var shell:Shell=auto_free(Shell.new())
	var provider:=preload("res://scripts/hud/content/dock_content_military.gd").new(world,shell)
	GameState.player_settlements[1]["occupied_by"]="civ_1"
	assert_bool(provider._training_staff_actions()[1].disabled).is_true()
	provider._prioritize_training_staff("second")
	assert_bool(world.feedback.has("error")).is_true()
	assert_str(String(GameState.player_settlements[1].get("management_focus",""))).is_not_equal("defense")
