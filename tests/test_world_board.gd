extends GdUnitTestSuite
const Content=preload("res://scripts/hud/content/dock_content_world.gd")
class Terrain extends Node:
	var plans:=0
	func _diplomat_action_presentation(_status:Dictionary,count:int)->Dictionary:return {"disabled":count==0,"tooltip":"Locate a settlement"}
	func _open_scout_dispatch_panel()->void:plans+=1
	func _open_diplomat_dispatch_panel()->void:pass
class TestHud extends Control:
	var opened:RefCounted
	func open_detail(value:RefCounted)->void:opened=value
func test_known_world_uses_returned_reports_and_opens_archive()->void:
	var terrain:=Terrain.new();add_child(terrain)
	var hud:=TestHud.new();add_child(hud)
	var content:=Content.new(terrain,hud)
	var data:Dictionary=content.tab(0)
	assert_str(String(data.blocks[0].type)).is_equal("known_world")
	var model:Dictionary=data.blocks[0].model
	assert_int(int(model.counters.reports)).is_equal(CivilizationSystem.scout_reports.size())
	(model.actions.archive as Callable).call()
	assert_bool(hud.opened!=null).is_true()
	(model.actions.plan as Callable).call()
	assert_int(terrain.plans).is_equal(1)
	hud.free();terrain.free()
func test_known_world_fits_narrow_and_wide_docks()->void:
	var terrain:=Terrain.new();add_child(terrain)
	var hud:=TestHud.new();add_child(hud)
	for width:float in [700.0,1200.0]:
		var panel:=preload("res://scripts/hud/dock_panel.gd").new();add_child(panel)
		panel.size=Vector2(width,850)
		panel.present(Content.new(terrain,hud),0)
		for frame in range(6):await get_tree().process_frame
		assert_float(panel.size.x).is_less_equal(width)
		var board:Node=panel.find_child("KnownWorldBoard",true,false)
		assert_bool(board!=null).is_true()
		assert_int(board.columns.columns).is_equal(1 if width==700 else 2)
		panel.free()
	hud.free();terrain.free()

func test_returned_finding_opens_its_report_and_live_count_updates()->void:
	var terrain:=Terrain.new();add_child(terrain)
	var hud:=TestHud.new();add_child(hud)
	var content:=Content.new(terrain,hud)
	var before:=content.signature()
	var old_reports:Array=CivilizationSystem.scout_reports.duplicate(true)
	CivilizationSystem.scout_reports.push_front({"mission_id":998,"day":int(GameState.elapsed_days),"target_label":"Northern valley","discoveries":[{"kind":"resource","title":"Copper outcrop","description":"Recorded by the returning scouts."}]})
	var data:Dictionary=content.tab(0)
	assert_bool(content.signature()!=before).is_true()
	var found:=false
	for group:Dictionary in data.blocks[0].model.finds:
		for item:Dictionary in group.items:
			if item.title=="Copper outcrop":
				found=true;(item.on_open as Callable).call()
				assert_bool(hud.opened!=null).is_true()
	assert_bool(found).is_true()
	CivilizationSystem.scout_reports.assign(old_reports)
	hud.free();terrain.free()
