extends GdUnitTestSuite
const Content=preload("res://scripts/hud/content/dock_content_world.gd")
class Terrain extends Node:
	func _diplomat_action_presentation(_status:Dictionary,count:int)->Dictionary:return {"disabled":count==0,"tooltip":"Locate a settlement"}
	func _open_scout_dispatch_panel()->void:pass
	func _open_diplomat_dispatch_panel()->void:pass
class TestHud extends Control:
	var opened:RefCounted
	func open_detail(value:RefCounted)->void:opened=value
func test_world_board_uses_returned_reports_and_opens_archive()->void:
	var terrain:=Terrain.new();add_child(terrain)
	var hud:=TestHud.new();add_child(hud)
	var content:=Content.new(terrain,hud)
	var data:Dictionary=content.tab(0)
	assert_str(String(data.blocks[0].type)).is_equal("world_board")
	assert_str(String(data.blocks[0].actions[1].label)).contains(str(CivilizationSystem.scout_reports.size()))
	data.blocks[0].actions[1].on_press.call()
	assert_bool(hud.opened!=null).is_true()
	hud.free();terrain.free()
func test_world_board_fits_narrow_and_wide_docks()->void:
	var terrain:=Terrain.new();add_child(terrain)
	var hud:=TestHud.new();add_child(hud)
	for width:float in [700.0,1200.0]:
		var panel:=preload("res://scripts/hud/dock_panel.gd").new();add_child(panel)
		panel.size=Vector2(width,850)
		panel.present(Content.new(terrain,hud),0)
		for frame in range(6):await get_tree().process_frame
		assert_float(panel.size.x).is_less_equal(width)
		var board:Node=panel.find_child("WorldBoard",true,false)
		assert_bool(board!=null).is_true()
		assert_bool(board.columns.vertical).is_equal(width==700)
		panel.free()
	hud.free();terrain.free()

func test_returned_finding_opens_its_report_and_live_count_updates()->void:
	var terrain:=Terrain.new();add_child(terrain)
	var hud:=TestHud.new();add_child(hud)
	var content:=Content.new(terrain,hud)
	var before:=content.signature()
	var old_reports:Array=CivilizationSystem.scout_reports.duplicate(true)
	CivilizationSystem.scout_reports.append({"mission_id":998,"day":int(GameState.elapsed_days),"target_label":"Northern valley","discoveries":[{"kind":"resource","title":"Copper outcrop","description":"Recorded by the returning scouts."}]})
	var data:Dictionary=content.tab(0)
	assert_bool(content.signature()!=before).is_true()
	var found:=false
	for item:Dictionary in data.blocks[0].sections[0].items:
		if item.title=="Copper outcrop":
			found=true;item.on_press.call()
			assert_bool(hud.opened!=null).is_true()
	assert_bool(found).is_true()
	CivilizationSystem.scout_reports.assign(old_reports)
	hud.free();terrain.free()


func test_report_rows_wrap_and_keep_actions_inside_narrow_board()->void:
	var board:=preload("res://scripts/hud/world_board.gd").new()
	add_child(board)
	board.size=Vector2(500,700)
	var opened:={"value":false}
	board.setup({"title":"Explore beyond the familiar","subtitle":"0 parties away · 2 available","actions":[],"sections":[{"title":"RECENT DISCOVERIES","items":[{"tag":"Year 1, Day 71 · FINDINGS","title":"A scraper renewed by breaking · inside the working hollow","detail":"Northern valley","unread":true,"action":"Read report","on_press":func():opened.value=true}]},{"title":"ON THE HORIZON","items":[]}]})
	for frame in range(6):await get_tree().process_frame
	assert_float(board.get_combined_minimum_size().x).is_less_equal(500.0)
	var button:Button=board.find_children("*","Button",true,false)[0]
	assert_float(button.get_global_rect().end.x).is_less_equal(board.get_global_rect().end.x)
	button.pressed.emit()
	assert_bool(opened.value).is_true()
	board.free()
