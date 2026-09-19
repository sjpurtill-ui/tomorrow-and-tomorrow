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
		assert_vector(icon.custom_minimum_size).is_equal(Vector2(26,26))

func test_government_screen_has_no_candidate_picker_and_removal_auto_replaces()->void:
	var terrain:Terrain=auto_free(Terrain.new())
	var hud:Hud=auto_free(Hud.new())
	var provider=GovernmentContent.new(terrain,hud)
	assert_array(provider.meta().subtabs).contains_exactly(["OFFICEHOLDERS","POLICY"])
	var before:=GovernmentPeopleSystem.officeholder("Steward")
	var page:Dictionary=provider.tab(0)
	var labels:Array[String]=[]
	for block:Dictionary in page.blocks:
		if String(block.get("type",""))!="actions":continue
		for item:Dictionary in block.items:labels.append(String(item.label))
	assert_array(labels).contains(["DISMISS","EXECUTE"])
	assert_bool(labels.any(func(label:String)->bool:return "APPOINT" in label or "CANDIDATE" in label)).is_false()
	for block:Dictionary in page.blocks:
		if String(block.get("type",""))=="actions":
			(block.items[0].on_press as Callable).call()
			break
	assert_bool(bool(terrain.last_report.get("ok",false))).is_true()
	assert_int(int(GovernmentPeopleSystem.officeholder("Steward").person_id)).is_not_equal(int(before.person_id))
	assert_int(hud.refreshes).is_equal(1)
