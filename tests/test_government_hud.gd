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

func test_government_screen_has_no_candidate_picker_and_sends_officials_to_court()->void:
	var terrain:Terrain=auto_free(Terrain.new())
	var hud:Hud=auto_free(Hud.new())
	var provider=GovernmentContent.new(terrain,hud)
	assert_array(provider.meta().subtabs).contains_exactly(["Officials","Standing orders"])
	var page:Dictionary=provider.tab(0)
	assert_int(page.kpis.size()).is_equal(0)
	assert_bool(page.brief.is_empty()).is_true()
	assert_int(page.blocks.size()).is_equal(1)
	assert_str(String(page.blocks[0].type)).is_equal("cabinet")
	var item:Dictionary=page.blocks[0].items[0]
	# One-click dismissal and execution are gone: consequential acts are spoken in court.
	assert_bool(item.has("on_dismiss")).is_false()
	assert_bool(item.has("on_execute")).is_false()
	assert_bool(item.on_summon is Callable).is_true()
	assert_str(String(item.fit_words)).is_not_empty()
	assert_bool(item.has("label")).is_false()

func test_vacant_office_has_empty_seat_and_no_person_or_summon()->void:
	var cabinet:Control=auto_free(preload("res://scripts/hud/government_cabinet_widget.gd").new())
	cabinet.setup({"items":[{"office_key":"Steward","office_title":"First Speaker","vacant":true,"name":"Vacant"}]})
	assert_object(cabinet.find_child("EmptySeat",true,false)).is_not_null()
	for node_name in ["Portrait","OfficeFit","CabinetSummon","CabinetDismiss","CabinetExecute"]:
		assert_object(cabinet.find_child(node_name,true,false)).is_null()

func test_occupied_office_reads_fit_in_words_and_only_summons()->void:
	var cabinet:Control=auto_free(preload("res://scripts/hud/government_cabinet_widget.gd").new())
	var actions:Array[String]=[]
	cabinet.setup({"legitimacy":0.72,"support":0.4,"items":[{"office_key":"Steward","office_title":"First Speaker","name":"Test Person","fit":0.0,"skills":[{"name":"Oratory","value":70}],"on_summon":func()->void:actions.append("summon")}]})
	assert_object(cabinet.find_child("Portrait",true,false)).is_not_null()
	assert_object(cabinet.find_child("OfficeSeal",true,false)).is_not_null()
	assert_str((cabinet.find_child("OfficeFit",true,false) as Label).text).is_equal("Badly suited to the office")
	assert_str((cabinet.find_child("OfficeSkills",true,false) as Label).text).is_equal("Best at: oratory (skilled)")
	assert_object(cabinet.find_child("CabinetDismiss",true,false)).is_null()
	assert_object(cabinet.find_child("CabinetExecute",true,false)).is_null()
	(cabinet.find_child("CabinetSummon",true,false) as Button).pressed.emit()
	assert_array(actions).contains_exactly(["summon"])
