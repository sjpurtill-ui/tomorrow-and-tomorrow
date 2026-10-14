extends GdUnitTestSuite
## Assignment shortcuts use normal navigation, preserve the live labor ledger,
## and focus only if the player has not navigated elsewhere before the idle tick.
const Base:=preload("res://scripts/hud/content/dock_content_base.gd")

class WorkView extends Control:
	var focused:=""
	func focus_work(role:String)->void:focused=role
	func handle_escape()->bool:
		if focused.is_empty():return false
		focused=""
		return true

class WorkDock extends PanelContainer:
	var provider:RefCounted
	var body_scroll:=ScrollContainer.new()
	func _init()->void:add_child(body_scroll)

class Provider extends RefCounted:
	var spatial:=true
	func meta()->Dictionary:return {"spatial_view":spatial}

class Hud extends "res://scripts/hud/command_rail_hud.gd":
	func _ready()->void:pass
	func set_active_section(section:String)->void:active_section=section

var hud:Hud
var work:WorkView
var opened:Array=[]

func before_test()->void:
	hud=Hud.new();add_child(hud)
	hud.dock=WorkDock.new();hud.add_child(hud.dock)
	hud.dock.provider=Provider.new()
	hud.detail_dock=WorkDock.new();hud.add_child(hud.detail_dock);hud.detail_dock.hide()
	work=WorkView.new();work.name="CivilizationPeopleScreen";hud.dock.add_child(work)
	opened=[]
	hud.section_requested.connect(func(section:String,sub:int)->void:
		opened.append([section,sub]);hud.active_section=section;hud.dock.show())

func after_test()->void:
	hud.queue_free()
	await get_tree().process_frame

func test_assignment_route_focuses_after_navigation_without_changing_live_work()->void:
	var before:Dictionary=GameState.population_allocations.duplicate(true)
	var provider:=Base.new(null,hud)
	provider.assign_workers("Construction").call()
	assert_array(opened).is_equal([["overview",0]])
	assert_str(work.focused).is_empty()
	await get_tree().process_frame
	assert_str(work.focused).is_equal("Construction")
	assert_dict(GameState.population_allocations).is_equal(before)
	assert_bool(hud.handle_escape()).is_true()
	assert_str(work.focused).is_empty()
	assert_bool(hud.dock.visible).is_true()
	assert_bool(hud.handle_escape()).is_true()
	assert_bool(hud.dock.visible).is_false()

func test_later_navigation_cancels_pending_work_focus()->void:
	hud.focus_people_work("Food")
	hud.section_requested.emit("inquiry",0)
	await get_tree().process_frame
	assert_str(work.focused).is_empty()
	assert_str(hud.active_section).is_equal("inquiry")

func test_living_view_gets_room_without_widening_other_reports()->void:
	assert_float(hud._dock_width(hud.dock,2869.0)).is_equal(1600.0)
	hud.dock.provider.spatial=false
	assert_float(hud._dock_width(hud.dock,2869.0)).is_equal(hud.Folio.page_width(2869.0))
	hud.dock.provider.spatial=true
	assert_float(hud._dock_width(hud.dock,1024.0)).is_less_equal(1024.0-hud.Folio.RAIL_WIDTH)
