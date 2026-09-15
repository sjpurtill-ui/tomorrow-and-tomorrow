extends GdUnitTestSuite
const BLOCKS:=preload("res://scripts/hud/dock_blocks.gd")
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	var report:Dictionary={}
	func _report_military_action(result:Dictionary)->void:report=result
class Hud extends Control:
	var refreshed:=false
	func request_immediate_dock_refresh()->void:refreshed=true

func before_test()->void:
	GameState.reset_for_new_world(873421)
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_name="Test Town"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()

func test_every_available_office_can_be_filled_by_stable_person_id()->void:
	GameState.ensure_population_total(12000)
	GameState.society_capacities["institutions"]=.74
	GovernmentPeopleSystem.government_stage=4
	var people:=GovernmentPeopleSystem.living_people()
	var index:=0
	for office:Dictionary in GovernmentPeopleSystem.active_offices():
		var result:=AdvisorSystem.appoint_person(int(people[index].person_id),String(office.key))
		assert_bool(bool(result.get("ok",false))).is_true()
		assert_int(int(GovernmentPeopleSystem.officeholder(String(office.key)).person_id)).is_equal(int(people[index].person_id))
		index+=1

func test_locked_office_reports_a_reason_and_changes_nothing()->void:
	GovernmentPeopleSystem.government_stage=0
	var person:Dictionary=GovernmentPeopleSystem.living_people()[0]
	var before:=GameState.leadership_positions.duplicate(true)
	var result:=AdvisorSystem.appoint_person(int(person.person_id),"Scholar")
	assert_bool(bool(result.ok)).is_false()
	assert_str(String(result.error)).contains("not available")
	assert_dict(GameState.leadership_positions).is_equal(before)

func test_appointment_does_not_depend_on_transient_advisor_roster()->void:
	GameState.ensure_population_total(300)
	GovernmentPeopleSystem.government_stage=1
	var person:Dictionary=GovernmentPeopleSystem.candidates_for_office("Quartermaster")[0]
	GameState.advisor_roster.clear()
	assert_bool(bool(AdvisorSystem.appoint_person(int(person.person_id),"Quartermaster").ok)).is_true()

func test_provider_keeps_own_shortlist_and_requests_immediate_feedback()->void:
	GameState.ensure_population_total(12000)
	GameState.society_capacities["institutions"]=.74
	GovernmentPeopleSystem.government_stage=4
	var terrain:Terrain=auto_free(Terrain.new())
	var hud:Hud=auto_free(Hud.new())
	var provider:=preload("res://scripts/hud/content/dock_detail_appointments.gd").new(terrain,hud,"Quartermaster")
	var candidate:Dictionary=provider.candidates[0]
	terrain.leader_candidates.clear()
	var action:Dictionary=provider.tab(0).blocks[1].items[0]
	(action.on_press as Callable).call()
	assert_bool(bool(terrain.report.get("ok",false))).is_true()
	assert_int(int(GovernmentPeopleSystem.officeholder("Quartermaster").person_id)).is_equal(int(candidate.person_id))
	assert_bool(hud.refreshed).is_true()

func test_clickable_rows_have_one_keyboard_and_mouse_hit_target()->void:
	var parent:VBoxContainer=auto_free(VBoxContainer.new());add_child(parent)
	var count:=[0]
	BLOCKS.render(parent,[{"type":"rows","items":[{"name":"Quartermaster","sub":"Vacant","value":"APPOINT","on_click":func():count[0]+=1}]}])
	var row:PanelContainer=parent.find_children("*","PanelContainer",true,false)[0]
	assert_int(row.focus_mode).is_equal(Control.FOCUS_ALL)
	for control:Node in row.find_children("*","Control",true,false):assert_int(control.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	row.gui_input.emit(click)
	assert_int(count[0]).is_equal(1)
	var enter:=InputEventAction.new();enter.action="ui_accept";enter.pressed=true
	row.gui_input.emit(enter)
	assert_int(count[0]).is_equal(2)
