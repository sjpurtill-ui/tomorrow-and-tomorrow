extends GdUnitTestSuite
## Exercise native Control focus and key dispatch, rather than emitting pressed.
## Reuse the deterministic preview boundary from the existing interaction suite.
const Fixture=preload("res://tests/test_civilization_people_screen.gd")

var fixture:Fixture
var viewport:SubViewport
var tab_path:PackedStringArray=[]

func before_test()->void:
	viewport=SubViewport.new();viewport.size=Vector2i(1000,800)
	viewport.handle_input_locally=true;add_child(viewport)
	fixture=Fixture.new();viewport.add_child(fixture);fixture.before_test()
	await get_tree().process_frame
	await get_tree().process_frame

func after_test()->void:
	fixture.after_test()
	viewport.queue_free()
	await get_tree().process_frame

func _key(code:Key)->void:
	for down:bool in [true,false]:
		var event:=InputEventKey.new()
		event.keycode=code;event.physical_keycode=code;event.pressed=down
		viewport.push_input(event,true)
		await get_tree().process_frame

func _tab_to(target:Control)->bool:
	tab_path.clear()
	for step in 24:
		await _key(KEY_TAB)
		var focused:=viewport.gui_get_focus_owner()
		tab_path.append(String(focused.name) if focused!=null else "<no focus>")
		if focused!=null:
			assert_bool(focused.is_visible_in_tree()).override_failure_message("Tab reached a hidden control").is_true()
			for role:String in fixture.screen.markers:
				assert_bool(focused==fixture.screen.markers[role].button).override_failure_message("Hidden overview marker remained in the focused-work Tab path: "+role).is_false()
		if focused==target:return true
	return false

func test_enter_and_tab_reach_assignment_and_apply_without_hidden_overview_stops()->void:
	var screen:Control=fixture.screen
	var assign:Button=screen.markers.Construction.button
	assign.grab_focus()
	assert_bool(viewport.gui_get_focus_owner()==assign).is_true()
	await _key(KEY_ENTER)
	assert_str(screen.active_role).is_equal("Construction")
	assert_array(fixture.commits).is_empty()
	for role:String in screen.markers:
		assert_bool((screen.markers[role].button as Control).is_visible_in_tree()).is_false()
	var reached:=await _tab_to(screen.increase_button)
	assert_bool(reached).override_failure_message("Keyboard could not reach the worker increase action after entering its worksite: "+", ".join(tab_path)).is_true()
	if not reached:return
	await _key(KEY_ENTER)
	assert_int(screen.draft.counts.Construction).is_equal(11)
	assert_int(screen.draft.counts.Food).is_equal(19)
	assert_array(fixture.commits).is_empty()
	reached=await _tab_to(screen.apply_button)
	assert_bool(reached).override_failure_message("Keyboard could not reach Apply after editing workers: "+", ".join(tab_path)).is_true()
	if not reached:return
	await _key(KEY_ENTER)
	assert_int(fixture.commits.size()).is_equal(1)
	if fixture.commits.is_empty():return
	assert_bool(fixture.commits[0].take_control).is_true()
	assert_str(fixture.commits[0].draft.commands[0].role).is_equal("Construction")
	reached=await _tab_to(screen.overview_button)
	assert_bool(reached).override_failure_message("Keyboard could not return to the settlement after applying: "+", ".join(tab_path)).is_true()
	if not reached:return
	await _key(KEY_ENTER)
	assert_str(screen.active_role).is_empty()
	assert_bool(assign.is_visible_in_tree()).is_true()
	assert_bool(viewport.gui_get_focus_owner()==assign).override_failure_message("Returning to overview must restore focus to the originating work-area action").is_true()
