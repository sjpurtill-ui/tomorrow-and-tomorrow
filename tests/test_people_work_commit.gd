extends GdUnitTestSuite
const Fixture=preload("res://tests/test_workforce_preview.gd")
const Preview=preload("res://scripts/hud/workforce_preview.gd")
const Manual=preload("res://scripts/manual_work.gd")
const Provider=preload("res://scripts/hud/content/dock_content_overview.gd")
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
