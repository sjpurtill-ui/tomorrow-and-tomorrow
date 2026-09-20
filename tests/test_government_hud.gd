extends GdUnitTestSuite

const GovernmentContent:=preload("res://scripts/hud/content/dock_content_government.gd")
const CommandRail:=preload("res://scripts/hud/command_rail_hud.gd")
const NavIcon:=preload("res://scripts/hud/nav_icon.gd")

class Terrain extends Node:
	var last_report:Dictionary={}
	func _report_military_action(result:Dictionary)->void:last_report=result

class Hud extends Control:
	var refreshes:=0
	func request_immediate_dock_refresh()->void:refreshes+=1

func before_test()->void:
	GameState.reset_for_new_world(991704)
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_name="Test Town"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()

func test_rail_has_distinct_government_destination_and_drawn_icons()->void:
	assert_bool(CommandRail.SECTIONS.any(func(item:Dictionary)->bool:return String(item.id)=="government")).is_true()
	for section:Dictionary in CommandRail.SECTIONS:
		var icon:Control=auto_free(NavIcon.new(String(section.id)))
		assert_str(icon.icon_id).is_equal(String(section.id))
		assert_vector(icon.custom_minimum_size).is_equal(Vector2(30,30))

func test_government_screen_has_no_candidate_picker_and_removal_auto_replaces()->void:
	var terrain:Terrain=auto_free(Terrain.new())
	var hud:Hud=auto_free(Hud.new())
	var provider=GovernmentContent.new(terrain,hud)
	assert_array(provider.meta().subtabs).contains_exactly(["OFFICEHOLDERS","POLICY"])
	var before:=GovernmentPeopleSystem.officeholder("Steward")
	var page:Dictionary=provider.tab(0)
	assert_int(page.kpis.size()).is_equal(0)
	assert_bool(page.brief.is_empty()).is_true()
	assert_int(page.blocks.size()).is_equal(1)
	assert_str(String(page.blocks[0].type)).is_equal("cabinet")
	var item:Dictionary=page.blocks[0].items[0]
	assert_bool(item.on_dismiss is Callable).is_true()
	assert_bool(item.on_execute is Callable).is_true()
	assert_bool(item.has("label")).is_false()
	(item.on_dismiss as Callable).call()
	assert_bool(bool(terrain.last_report.get("ok",false))).is_true()
	assert_int(int(GovernmentPeopleSystem.officeholder("Steward").person_id)).is_not_equal(int(before.person_id))
	assert_int(hud.refreshes).is_equal(1)

func test_vacant_office_has_empty_seat_and_no_person_or_removal_controls()->void:
	var cabinet:Control=auto_free(preload("res://scripts/hud/government_cabinet_widget.gd").new())
	cabinet.setup({"items":[{"office_key":"Steward","office_title":"First Speaker","vacant":true,"name":"Vacant"}]})
	assert_object(cabinet.find_child("EmptySeat",true,false)).is_not_null()
	for node_name in ["Portrait","OfficeFit","CabinetDismiss","CabinetExecute"]:
		assert_object(cabinet.find_child(node_name,true,false)).is_null()

func test_occupied_office_keeps_distinct_removal_callbacks_and_zero_fit()->void:
	var cabinet:Control=auto_free(preload("res://scripts/hud/government_cabinet_widget.gd").new())
	var actions:Array[String]=[]
	cabinet.setup({"items":[{"office_key":"Steward","office_title":"First Speaker","name":"Test Person","fit":0.0,"on_dismiss":func()->void:actions.append("dismiss"),"on_execute":func()->void:actions.append("execute")}]})
	assert_object(cabinet.find_child("Portrait",true,false)).is_not_null()
	assert_object(cabinet.find_child("OfficeSeal",true,false)).is_not_null()
	assert_object(cabinet.find_child("OfficeFit",true,false)).is_not_null()
	(cabinet.find_child("CabinetDismiss",true,false) as Button).pressed.emit()
	(cabinet.find_child("CabinetExecute",true,false) as Button).pressed.emit()
	assert_array(actions).contains_exactly(["dismiss","execute"])
