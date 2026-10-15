extends GdUnitTestSuite
## Real controls through a deterministic guarded mutation boundary. No staged Apply.
const Screen=preload("res://scripts/hud/civilization_people_screen.gd")
const Manual=preload("res://scripts/manual_work.gd")
class SceneStub extends Control:
	signal role_anchors_changed(anchors:Dictionary)
	signal role_selected(role:String)
	var focused:=""
	var focuses:=0
	var refreshes:=0
	var weights:Dictionary={}
	var preview:=false
	var navigation:={"offset":Vector2(13,8),"zoom":.6}
	func configure(_context:Dictionary)->void:pass
	func update_state(_context:Dictionary)->void:refreshes+=1
	func set_workforce(next:Dictionary,proposed:=false)->void:weights=next.duplicate();preview=proposed
	func workforce_percentages()->Dictionary:return Screen.WorkforceCast.apportion(weights)
	func focus_role(role:String)->void:focused=role;focuses+=1;navigation={"offset":Vector2.ZERO,"zoom":1.0}
	func reset_view()->void:focused=""
	func navigation_state()->Dictionary:return navigation.duplicate()
	func restore_navigation_state(value:Dictionary)->void:navigation=value.duplicate()
class TestScreen extends Screen:
	func _make_settlement_view()->Control:return SceneStub.new()
var captures:=0
var evaluations:=0
var commits:Array=[]
var manual:=false
var revision:=1
var protect_food:=false
var available:=true
var reject_commit:=false
var counts:Dictionary={}
var screen:Control
func before_test()->void:
	captures=0;evaluations=0;commits=[];manual=false;revision=1;protect_food=false;available=true;reject_commit=false
	counts={}
	for role:String in Manual.ROLES:counts[role]=10
	counts.Food=20
	screen=TestScreen.new();add_child(screen);screen.size=Vector2(934,800);screen.setup(_block())
func after_test()->void:
	if is_instance_valid(screen):screen.free()
func _capture()->Dictionary:
	captures+=1
	return {"ok":true,"token":revision,"manual":manual,"counts":counts.duplicate(),"shares":counts.duplicate(),"original_counts":counts.duplicate(),"commands":[],"changes":[]}
func _step(draft:Dictionary,role:String,points:int)->Dictionary:
	var out:=draft.duplicate(true)
	var amount:=clampi(points,-int(out.counts[role]),int(out.counts.Food))
	out.counts[role]+=amount;out.counts.Food-=amount
	out.shares=out.counts.duplicate()
	out.commands.append({"role":role,"points":amount});out.has_changes=amount!=0
	return out
func _evaluate(draft:Dictionary)->Dictionary:
	evaluations+=1
	if not available:return {"ok":false,"reason":"The current allocation cannot be estimated."}
	var food:={"production":100.0,"required":95.0,"net":5.0,"stock":900.0,"forecast30":{"ending_rations":1000.0},"forecast90":{"ending_rations":1200.0}}
	var after:Dictionary=draft.counts.duplicate()
	if protect_food and not draft.commands.is_empty():after.Crafting-=2;after.Food+=2
	return {"ok":true,"before":{"food":food,"counts":counts.duplicate()},"after":{"food":food,"counts":after},"warnings":[{"kind":"safeguard","town":"Home"}] if protect_food else []}
func _commit(draft:Dictionary,take_control:bool)->Dictionary:
	if reject_commit or int(draft.token)!=revision:return {"ok":false,"stale":true,"reason":"The world changed; try again."}
	commits.append({"draft":draft.duplicate(true),"take_control":take_control});manual=true
	counts=draft.counts.duplicate()
	if protect_food:counts.Crafting-=2;counts.Food+=2
	revision+=1
	return {"ok":true,"counts":counts.duplicate()}
func _block()->Dictionary:
	var tasks:Array=[]
	for role:String in Manual.ROLES:tasks.append({"id":role,"label":role,"count":counts[role],"share":float(counts[role])/100.0})
	return {"type":"civilization_people","scene":{},"faces":[],"vitals":[],"story":{},"hearths":[],"tallies":[],"workforce_revision":[revision],"settlement_view":{},"labor":{"tasks":tasks,"able":100,"manual":manual},"workforce":{"capture":_capture,"step":_step,"evaluate":_evaluate,"commit":_commit}}
func test_role_navigation_reads_without_mutation_or_duplicate_focus()->void:
	for role:String in Manual.ROLES:
		screen.focus_work(role);screen.focus_work(role)
		assert_str(screen.settlement_view.focused).is_equal(role)
	assert_int(screen.settlement_view.focuses).is_equal(9)
	assert_array(commits).is_empty()
	assert_bool(screen.parts.labor.visible).is_false()
	assert_object(screen.find_child("ApplyWorkDraft",true,false)).is_null()
	assert_object(screen.find_child("CancelWorkDraft",true,false)).is_null()
func test_single_click_immediately_commits_and_moves_one_effective_figure()->void:
	screen.focus_work("Crafting");screen.increase_button.pressed.emit()
	assert_int(commits.size()).is_equal(1)
	assert_bool(commits[0].take_control).is_true()
	assert_int(counts.Crafting).is_equal(11)
	assert_int(screen.settlement_view.workforce_percentages().Crafting).is_equal(11)
	assert_bool(screen.settlement_view.preview).is_false()
	assert_str(screen.people_reading.text).is_equal("11 workers · 11%")
	assert_bool(screen.effect_graph.comparing).is_true()
func test_rapid_clicks_capture_latest_live_state_without_losing_steps()->void:
	screen.focus_work("Knowledge")
	for i in 3:screen.increase_button.pressed.emit()
	assert_int(commits.size()).is_equal(3)
	assert_int(counts.Knowledge).is_equal(13)
	assert_int(counts.Food).is_equal(17)
	assert_int(int(commits[2].draft.token)).is_equal(3)
	assert_int(captures).is_equal(4)
	assert_int(evaluations).is_equal(4)
func test_protected_counts_and_figures_follow_actual_commit_result()->void:
	screen.focus_work("Crafting");protect_food=true;screen.five_button.pressed.emit()
	assert_int(counts.Crafting).is_equal(13)
	assert_int(screen.settlement_view.workforce_percentages().Crafting).is_equal(13)
	assert_str(screen.people_reading.text).is_equal("13 workers · 13%")
	assert_str(screen.transfer_reading.text).contains("Food protection")
func test_failed_forecast_cannot_commit_and_keeps_current_figures()->void:
	screen.focus_work("Knowledge");available=false;screen.increase_button.pressed.emit()
	assert_array(commits).is_empty()
	assert_int(counts.Knowledge).is_equal(10)
	assert_dict(screen.settlement_view.weights).is_equal(counts)
	assert_str(screen.risk_reading.text).contains("cannot be estimated")
func test_rejected_token_does_not_mutate_and_next_click_is_fresh()->void:
	screen.focus_work("Knowledge");reject_commit=true;screen.increase_button.pressed.emit()
	assert_array(commits).is_empty()
	assert_str(screen.risk_reading.text).contains("world changed")
	reject_commit=false;revision+=1;screen.increase_button.pressed.emit()
	assert_int(commits.size()).is_equal(1)
	assert_int(counts.Knowledge).is_equal(11)
func test_live_refresh_and_dock_restore_keep_camera_pan_and_zoom()->void:
	screen.focus_work("Knowledge");screen.increase_button.pressed.emit()
	screen.settlement_view.navigation={"offset":Vector2(15,8),"zoom":.4}
	var saved:Dictionary=screen.view_state();var held_captures:=captures;var held_evaluations:=evaluations
	for i in 4:screen.update_block(_block());screen.restore_view_state(saved)
	await get_tree().process_frame
	assert_int(screen.settlement_view.focuses).is_equal(1)
	assert_dict(screen.settlement_view.navigation).is_equal(saved.work_navigation)
	assert_int(captures).is_equal(held_captures)
	assert_int(evaluations).is_equal(held_evaluations)
func test_new_reader_restores_navigation_without_reapplying_any_action()->void:
	screen.focus_work("Logistics");screen.increase_button.pressed.emit()
	screen.settlement_view.navigation={"offset":Vector2(5,3),"zoom":.7}
	var saved:Dictionary=screen.view_state();var held:=commits.size()
	var replacement:=TestScreen.new();add_child(replacement);replacement.size=Vector2(934,800);replacement.setup(_block());replacement.restore_view_state(saved)
	assert_str(replacement.active_role).is_equal("Logistics")
	assert_dict(replacement.settlement_view.navigation).is_equal(saved.work_navigation)
	assert_int(commits.size()).is_equal(held)
	assert_bool(replacement.handle_escape()).is_true()
	assert_bool(replacement.handle_escape()).is_false()
	replacement.free()
func test_buttons_and_data_bounds_stay_fixed_through_clicks_and_long_warning()->void:
	screen.focus_work("Crafting");await get_tree().process_frame;screen._fit_scene();await get_tree().process_frame
	var button:Rect2=screen.increase_button.get_global_rect()
	var panel:Rect2=screen.focus_panel.get_rect();var evidence:Rect2=screen.evidence_panel.get_rect()
	for i in 3:
		screen.increase_button.pressed.emit();screen.update_block(_block());await get_tree().process_frame
		assert_object(screen.increase_button.get_global_rect()).is_equal(button)
		assert_object(screen.focus_panel.get_rect()).is_equal(panel)
		assert_object(screen.evidence_panel.get_rect()).is_equal(evidence)
	screen.forecast.warnings=[{"kind":"starvation","town":"The southern settlement with a very long and descriptive place name"}]
	screen._refresh_focus();await get_tree().process_frame
	assert_object(screen.increase_button.get_global_rect()).is_equal(button)
func test_starvation_precedes_water_and_protection_in_visible_warning()->void:
	screen.focus_work("Crafting")
	screen.forecast.warnings=[{"kind":"safeguard","town":"Safe town"},{"kind":"starvation","town":"Hungry town"}]
	screen._refresh_focus()
	assert_str(screen.risk_reading.text).contains("Hungry town").contains("food is short now")
func test_overview_slots_do_not_repack_when_world_anchors_change()->void:
	await get_tree().process_frame;screen._fit_scene()
	var positions:={}
	for role:String in screen.markers:positions[role]=screen.markers[role].node.position
	screen._anchors_changed({"Food":Vector2(1,600),"Knowledge":Vector2(900,1)})
	for role:String in screen.markers:assert_object(screen.markers[role].node.position).is_equal(positions[role])
func test_zero_and_hundred_percent_boundaries_disable_correct_step()->void:
	counts.Knowledge=0;counts.Food=30;screen.update_block(_block());screen.focus_work("Knowledge")
	assert_bool(screen.decrease_button.disabled).is_true()
	assert_bool(screen.increase_button.disabled).is_false()
	for role:String in counts:counts[role]=0
	counts.Knowledge=100;screen.update_block(_block());screen._refresh_current()
	assert_bool(screen.increase_button.disabled).is_true()
	assert_bool(screen.five_button.disabled).is_true()
func test_no_workers_uses_unassigned_reserve_and_explicit_total()->void:
	for role:String in counts:counts[role]=0
	var empty:=_block();empty.labor.able=0;screen.update_block(empty)
	assert_int(screen.settlement_view.workforce_percentages().Unassigned).is_equal(100)
	assert_str(screen.scope_note.text).is_equal("0 assigned")
	assert_str(screen.figure_legend.text).is_equal("100 figures · no workers assigned")

func test_failed_boundary_command_does_not_disable_unapplied_last_five_percent()->void:
	for role:String in counts:counts[role]=0
	counts.Crafting=95;counts.Food=5;screen.update_block(_block());screen.focus_work("Crafting")
	reject_commit=true;screen.five_button.pressed.emit()
	assert_int(counts.Crafting).is_equal(95)
	assert_bool(screen.increase_button.disabled).is_false()
	assert_bool(screen.five_button.disabled).is_false()
	reject_commit=false;screen.five_button.pressed.emit()
	assert_int(counts.Crafting).is_equal(100)
	assert_bool(screen.increase_button.disabled).is_true()

func test_passive_changes_are_throttled_but_each_click_is_fresh()->void:
	screen.focus_work("Knowledge")
	var held:=captures
	for i in 5:revision+=1;screen.update_block(_block());await get_tree().process_frame
	assert_int(captures).is_equal(held)
	assert_str(screen.transfer_reading.text).contains("previous update")
	screen.increase_button.pressed.emit()
	assert_int(captures).is_equal(held+1)
	assert_int(commits.size()).is_equal(1)
