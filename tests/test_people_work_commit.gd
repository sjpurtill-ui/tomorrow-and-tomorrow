extends GdUnitTestSuite
const Fixture=preload("res://tests/test_workforce_preview.gd")
const Preview=preload("res://scripts/hud/workforce_preview.gd")
const Manual=preload("res://scripts/manual_work.gd")
const Provider=preload("res://scripts/hud/content/dock_content_overview.gd")
class RunningTerrain extends Node:
	var game_speed := 1.0

class Hud extends Control:
	signal section_requested(section:String,sub:int)
	var refreshes:=0
	var speed_requests:Array=[]
	func request_immediate_dock_refresh()->void:refreshes+=1
	func _on_speed_pressed(speed:int)->void:speed_requests.append(speed)
var fixture:Node
var hud:Hud
var provider:RefCounted
func before()->void:
	fixture=Fixture.new();fixture.before()
func after()->void:
	fixture.after();fixture.free()
func before_test()->void:
	fixture.before_test();hud=Hud.new();provider=Provider.new(null,hud)
func after_test()->void:
	provider=null;hud.free()
func test_noop_invalid_and_unconfirmed_drafts_cannot_take_control()->void:
	var initial:Dictionary=Preview.capture();var before:=Manual.counts()
	assert_bool(provider.commit_workforce(initial,true).ok).is_false()
	var changed:=Preview.step(initial,"Knowledge",5)
	assert_bool(provider.commit_workforce(changed,false).ok).is_false()
	var invalid:=changed.duplicate(false);invalid.commands=[{"role":"Not a role","points":5}]
	assert_bool(provider.commit_workforce(invalid,true).ok).is_false()
	assert_bool(PeopleDirection.automatic_work).is_true()
	assert_dict(Manual.counts()).is_equal(before)
	assert_int(hud.refreshes).is_equal(0)
func test_explicit_commit_matches_preview_and_requests_only_one_refresh()->void:
	var draft:=Preview.capture()
	for move:Array in [["Knowledge",5],["Construction",4],["Logistics",2]]:draft=Preview.step(draft,move[0],move[1])
	var expected:Dictionary=Preview.evaluate(draft)
	assert_bool(expected.ok).is_true()
	var result:Dictionary=provider.commit_workforce(draft,true)
	assert_bool(result.ok).is_true()
	assert_bool(PeopleDirection.automatic_work).is_false()
	assert_dict(Manual.counts()).is_equal(expected.after.counts)
	assert_dict(Manual.percents()).is_equal(draft.shares)
	assert_int(hud.refreshes).is_equal(1)
func test_changed_world_rejects_commit_and_explicit_pause_uses_existing_hud_path()->void:
	var draft:=Preview.step(Preview.capture(),"Construction",5)
	GameState.elapsed_days+=1
	var before:=Manual.counts()
	assert_bool(provider.commit_workforce(draft,true).get("stale",false)).is_true()
	assert_dict(Manual.counts()).is_equal(before)
	assert_bool(PeopleDirection.automatic_work).is_true()
	assert_array(hud.speed_requests).is_empty()
	provider.pause_to_plan()
	assert_array(hud.speed_requests).is_equal([0])
	assert_int(hud.refreshes).is_equal(1)

func test_click_during_pending_day_finishes_it_before_capturing_and_committing()->void:
	var Job=preload("res://scripts/day_job.gd")
	var job=Job.new()
	var old_day:=GameState.elapsed_days
	job.add_group("player",[Job.step("finish_pending",{},func()->void:
		GameState.elapsed_days+=1
		WorldSimulation.advancing=false
	)])
	WorldSimulation._day_job=job
	WorldSimulation.advancing=true
	assert_bool(provider.capture_workforce().ok).is_false()
	assert_float(GameState.elapsed_days).is_equal(old_day)
	var draft:Dictionary=provider.capture_workforce(true)
	assert_bool(draft.ok).is_true()
	assert_bool(WorldSimulation.day_in_progress()).is_false()
	assert_float(GameState.elapsed_days).is_equal(old_day+1)
	draft=Preview.step(draft,"Knowledge",5)
	var expected:=Preview.evaluate(draft)
	assert_bool(expected.ok).is_true()
	assert_bool(provider.commit_workforce(draft,true).ok).is_true()
	assert_dict(Manual.counts()).is_equal(expected.after.counts)
	assert_bool(PeopleDirection.automatic_work).is_false()
	assert_array(hud.speed_requests).is_empty()

func test_real_allocator_click_recovers_from_pending_day_read()->void:
	var View=preload("res://scripts/hud/people_allocator_screen.gd")
	var Job=preload("res://scripts/day_job.gd")
	var block:Dictionary=provider.tab(0).blocks[0]
	var job=Job.new()
	job.add_group("player",[Job.step("finish_pending",{},func()->void:
		WorldSimulation.advancing=false
	)])
	WorldSimulation._day_job=job
	WorldSimulation.advancing=true
	var screen=View.new()
	add_child(screen)
	screen.setup(block)
	assert_bool(screen.forecast.ok).is_false()
	screen.rows.Knowledge.steps[5].pressed.emit()
	assert_bool(screen.forecast.ok).is_true()
	assert_bool(PeopleDirection.automatic_work).is_false()
	assert_str(screen.refs.feedback.text).starts_with("Applied:")
	assert_dict(Manual.counts()).is_equal(screen.forecast.after.counts)
	screen.free()

func test_running_home_refresh_preserves_scroll_focus_and_control_geometry()->void:
	var terrain:=RunningTerrain.new()
	add_child(terrain)
	provider.terrain=terrain
	var panel=preload("res://scripts/hud/dock_panel.gd").new()
	add_child(panel)
	panel.size=Vector2(700,420)
	panel.present(provider,0)
	for frame in 6:await get_tree().process_frame
	var screen:Control=panel.body.find_child("CivilizationPeopleScreen",true,false)
	var button:Button=screen.rows.Knowledge.steps[1]
	button.grab_focus()
	panel.body_scroll.ensure_control_visible(button)
	for frame in 4:await get_tree().process_frame
	var scroll:int=panel.body_scroll.scroll_vertical
	assert_int(scroll).is_greater(0)
	var rect:=button.get_global_rect()
	var builds:int=panel.sections_built
	var longest:=0
	for day in 6:
		GameState.elapsed_days+=1
		var tick:=Time.get_ticks_usec()
		panel.rebuild_body()
		longest=maxi(longest,Time.get_ticks_usec()-tick)
		for frame in 4:await get_tree().process_frame
		assert_int(panel.body_scroll.scroll_vertical).is_equal(scroll)
		assert_object(button.get_global_rect()).is_equal(rect)
		assert_object(get_viewport().gui_get_focus_owner()).is_same(button)
		assert_int(panel.sections_built).is_equal(builds)
	print("Home live refresh fixture: slowest %.1fms across six days" % (float(longest)/1000.0))
	panel.free()
	provider.terrain=null
	terrain.free()
