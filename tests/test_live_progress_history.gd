extends GdUnitTestSuite
const Manager=preload("res://scripts/workshop_steward.gd")
class Hud extends "res://scripts/hud/command_rail_hud.gd":
	func _ready()->void:pass
class Provider extends RefCounted:
	var progress:={"value":10.0}
	func signature()->Array:return [progress]
class Dock extends PanelContainer:
	var provider:RefCounted=Provider.new()
	var sub:=0
	var refreshes:=0
	var progress:=ProgressBar.new()
	func _ready()->void:add_child(progress)
	func rebuild_body()->void:refreshes+=1;progress.value=provider.progress.value
func test_hover_does_not_freeze_progress_and_mutable_signatures_are_detected()->void:
	var hud:Control=auto_free(Hud.new());add_child(hud)
	var dock:PanelContainer=auto_free(Dock.new());hud.add_child(dock);hud.dock=dock
	dock.position=dock.get_global_mouse_position()-Vector2(50,50);dock.size=Vector2(200,200)
	hud.live_refresh_dock()
	assert_float(dock.progress.value).is_equal(10.0)
	dock.provider.progress.value=65.0
	hud.live_refresh_dock()
	assert_float(dock.progress.value).is_equal(65.0)
	assert_int(dock.refreshes).is_equal(2)
	var editor:=LineEdit.new();dock.add_child(editor);editor.text="saved value"
	assert_bool(hud._dock_interaction_active(dock)).is_false()
func test_output_totals_separate_settlements_and_survive_recent_receipt_limit()->void:
	GameState.reset_for_new_world(321)
	MilitaryCampaign.reset_for_new_world()
	var manager=MilitaryCampaign.workshop
	var job:={"item":"improvised","job_type":"production"}
	for day in 300:
		GameState.elapsed_days=day
		GameState.resource_settlement_id="a" if day%2==0 else "b"
		GameState.settlement_name="Alder" if day%2==0 else "Birch"
		var before:Dictionary=manager.output_stocks(job)
		MilitaryCampaign.military_inventory.improvised+=1
		manager.record(job,before)
	assert_int(manager.data.receipts.size()).is_equal(256)
	assert_int(manager.data.totals.size()).is_equal(2)
	for total:Dictionary in manager.data.totals.values():assert_float(float(total.quantity)).is_equal(150.0)
	var saved:Dictionary=manager.data.duplicate(true);manager.restore(saved)
	assert_dict(manager.data).is_equal(saved)
	assert_str(Manager.validate(saved)).is_empty()
	GameState.resource_settlement_id=""
func test_legacy_history_is_unknown_settlement_and_migrates_only_once()->void:
	var manager=Manager.new(MilitaryCampaign)
	manager.restore({"receipts":[{"day":10,"item":"improvised","resource":"improvised","kind":"production","quantity":3.0}]})
	assert_float(float(manager.data.totals.values()[0].quantity)).is_equal(3.0)
	assert_str(manager.data.totals.values()[0].settlement_name).is_equal("Settlement not recorded")
	manager.restore(manager.data.duplicate(true))
	assert_float(float(manager.data.totals.values()[0].quantity)).is_equal(3.0)
func test_history_rejects_invalid_totals()->void:
	assert_str(Manager.validate({"totals":{"bad":{"day":1,"item":"improvised","resource":"improvised","kind":"production","quantity":NAN}}})).is_not_empty()

func test_history_board_shows_old_recorded_quantities_under_settlement_names()->void:
	var board:Control=auto_free(preload("res://scripts/hud/production_board.gd").new());add_child(board)
	board.setup({"view_state":{"mode":1},"day":1000,"receipts":[{"day":1,"item":"improvised","resource":"improvised","kind":"production","quantity":12.0,"settlement_id":"a","settlement_name":"Alder"}]})
	var text:=""
	for label in board.find_children("*","Label",true,false):text+=label.text+"\n"
	assert_str(text).contains("Alder").contains("12").contains("Simple levy weapons")
	assert_str(text).not_contains("LATEST 30 DAYS")
