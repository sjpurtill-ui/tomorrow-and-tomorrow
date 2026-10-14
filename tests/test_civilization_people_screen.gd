extends GdUnitTestSuite
## Real controls against a deterministic read-only preview boundary. The renderer
## has its own world/geometry tests; this suite proves draft/apply UI semantics.
const Screen=preload("res://scripts/hud/civilization_people_screen.gd")
const Manual=preload("res://scripts/manual_work.gd")

class SceneStub extends Control:
	signal role_anchors_changed(anchors:Dictionary)
	signal role_selected(role:String)
	var focused:=""
	var refreshes:=0
	func configure(_context:Dictionary)->void:pass
	func update_state(_context:Dictionary)->void:refreshes+=1
	func focus_role(role:String)->void:focused=role
	func reset_view()->void:focused=""

class TestScreen extends Screen:
	func _make_settlement_view()->Control:return SceneStub.new()

var captures:=0
var evaluations:=0
var current_checks:=0
var commits:Array=[]
var manual:=false
var current:=true
var revision:=1
var screen:Control

func before_test()->void:
	captures=0;evaluations=0;current_checks=0;commits=[];manual=false;current=true;revision=1
	screen=TestScreen.new();add_child(screen);screen.size=Vector2(934,800);screen.setup(_block())

func after_test()->void:
	if is_instance_valid(screen):screen.free()

func _counts()->Dictionary:
	var counts:={}
	for role:String in Manual.ROLES:counts[role]=10
	counts.Food=20
	return counts

func _capture()->Dictionary:
	captures+=1;current=true
	return {"ok":true,"token":revision,"manual":manual,"counts":_counts(),"shares":_counts(),"original_counts":_counts(),"commands":[],"changes":[]}

func _step(draft:Dictionary,role:String,points:int)->Dictionary:
	var out:=draft.duplicate(true);out.counts[role]+=points;out.counts.Food-=points
	out.shares[role]+=points;out.shares.Food-=points
	out.commands.append({"role":role,"points":points})
	out.changes=[{"role":role,"before":10,"after":out.counts[role]},{"role":"Food","before":20,"after":out.counts.Food}]
	return out

func _evaluate(draft:Dictionary)->Dictionary:
	evaluations+=1
	var food:={"production":100.0,"required":95.0,"stock":900.0,"forecast30":{"ending_rations":1000.0},"forecast90":{"ending_rations":1200.0}}
	return {"ok":true,"before":{"food":food,"counts":_counts()},"after":{"food":food,"counts":draft.get("counts",{})},"warnings":[]}

func _current(_draft:Dictionary)->bool:current_checks+=1;return current
func _commit(draft:Dictionary,take_control:bool)->Dictionary:
	commits.append({"draft":draft.duplicate(true),"take_control":take_control});manual=true
	return {"ok":true}

func _block()->Dictionary:
	var tasks:Array=[]
	for role:String in Manual.ROLES:tasks.append({"id":role,"label":role,"count":_counts()[role],"share":float(_counts()[role])/100.0})
	return {"type":"civilization_people","scene":{},"faces":[],"vitals":[],"story":{},"hearths":[],"tallies":[],"workforce_revision":[revision],
		"settlement_view":{"name":"The actual town"},"labor":{"tasks":tasks,"able":100,"manual":manual},
		"workforce":{"capture":_capture,"step":_step,"evaluate":_evaluate,"is_current":_current,"commit":_commit}}

func test_every_role_opens_the_actual_camera_target_without_applying()->void:
	assert_int(screen.markers.size()).is_equal(9)
	for role:String in Manual.ROLES:
		(screen.markers[role].button as Button).pressed.emit()
		assert_str(screen.active_role).is_equal(role)
		assert_str(screen.settlement_view.focused).is_equal(role)
	assert_int(captures).is_equal(1)
	assert_array(commits).is_empty()
	assert_bool(screen.parts.labor.visible).is_false()

func test_draft_cancel_and_explicit_take_control_use_one_commit_boundary()->void:
	screen.focus_work("Construction")
	screen.five_button.pressed.emit()
	assert_array(commits).is_empty()
	assert_str(screen.apply_button.text).is_equal("Take control & apply")
	assert_int(screen.draft.counts.Construction).is_equal(15)
	screen.cancel_button.pressed.emit()
	assert_array(screen.draft.commands).is_empty()
	assert_array(commits).is_empty()
	screen.increase_button.pressed.emit();screen.apply_button.pressed.emit()
	assert_int(commits.size()).is_equal(1)
	assert_bool(commits[0].take_control).is_true()
	assert_str(commits[0].draft.commands[0].role).is_equal("Construction")

func test_running_world_change_rebases_and_requires_a_second_apply()->void:
	screen.focus_work("Crafting");screen.five_button.pressed.emit()
	revision+=1;current=false;screen.update_block(_block())
	assert_str(screen.apply_button.text).is_equal("Refresh preview")
	assert_int(current_checks).is_equal(0)
	screen.apply_button.pressed.emit()
	assert_array(commits).is_empty()
	assert_int(screen.draft.token).is_equal(revision)
	assert_int(screen.draft.counts.Crafting).is_equal(15)
	screen.apply_button.pressed.emit()
	assert_int(commits.size()).is_equal(1)

func test_live_refresh_preserves_camera_and_draft_without_expensive_capture()->void:
	screen.focus_work("Knowledge");screen.increase_button.pressed.emit()
	var held_captures:=captures;var held_evaluations:=evaluations
	for i in 4:screen.update_block(_block())
	assert_int(captures).is_equal(held_captures)
	assert_int(evaluations).is_equal(held_evaluations)
	assert_int(current_checks).is_equal(0)
	assert_str(screen.settlement_view.focused).is_equal("Knowledge")
	assert_int(screen.draft.commands.size()).is_equal(1)

func test_restored_reader_keeps_preview_and_escape_backs_out_before_discarding()->void:
	screen.focus_work("Logistics");screen.increase_button.pressed.emit()
	var saved:Dictionary=screen.view_state()
	var replacement:=TestScreen.new();add_child(replacement);replacement.size=Vector2(934,800);replacement.setup(_block());replacement.restore_view_state(saved)
	await get_tree().process_frame
	assert_str(replacement.active_role).is_equal("Logistics")
	assert_int(replacement.draft.commands.size()).is_equal(1)
	assert_bool(replacement.forecast.get("ok",false)).is_true()
	assert_bool(replacement.draft_stale).is_false()
	assert_bool(replacement.handle_escape()).is_true()
	assert_str(replacement.active_role).is_empty()
	assert_int(replacement.draft.commands.size()).is_equal(1)
	assert_bool(replacement.handle_escape()).is_true()
	assert_dict(replacement.draft).is_empty()
	assert_bool(replacement.handle_escape()).is_false()
	replacement.free()

func test_scrolling_records_does_not_grow_the_living_scene()->void:
	var scroll:=ScrollContainer.new();scroll.size=Vector2(934,620);add_child(scroll)
	screen.reparent(scroll)
	var spacer:=Control.new();spacer.custom_minimum_size.y=500;screen.add_child(spacer)
	await get_tree().process_frame
	screen._fit_scene()
	await get_tree().process_frame
	var height:float=screen.stage.custom_minimum_size.y
	scroll.scroll_vertical=180
	await get_tree().process_frame
	screen._fit_scene()
	assert_float(screen.stage.custom_minimum_size.y).is_equal(height)
	screen.reparent(self);scroll.free()
