extends GdUnitTestSuite
const Figure=preload("res://scripts/hud/court_figure_3d.gd")
const Acting=preload("res://scripts/hud/court_acting.gd")
const Pose=preload("res://scripts/hud/court_pose_clearance.gd")
const BODIES:=["male_adult","female_adult","male_young","female_young","male_old","female_old","child"]
var saved:Dictionary

func before_test()->void:
	saved=Pose.overrides
	Pose.overrides={}
	for variant:String in BODIES:
		Pose.overrides[variant]={"stand":8.0,"sit_cross":{"spread":[[0.0,8.0],[.6,16.0],[1.6,5.0]],"flex":6.0},"stance_cross":{"spread":5.0,"flex":6.0}}

func after_test()->void:Pose.overrides=saved

func _figure(variant:="male_adult")->Figure:
	var f:=Figure.new();add_child(f);f.setup({"variant":variant,"outfit":"tunic"})
	return f

func _signature(animation:Animation)->Array:
	var result:Array=[animation.length,animation.step,animation.loop_mode]
	for track in animation.get_track_count():
		var item:Array=[animation.track_get_type(track),animation.track_get_path(track),animation.track_is_enabled(track),animation.track_get_interpolation_type(track),animation.track_get_interpolation_loop_wrap(track)]
		for key in animation.track_get_key_count(track):item.append([animation.track_get_key_time(track,key),animation.track_get_key_transition(track,key),animation.track_get_key_value(track,key)])
		result.append(item)
	return result

func test_fitting_preserves_source_timing_and_every_non_arm_track()->void:
	for variant:String in BODIES:_check_source_invariants(variant)

func _check_source_invariants(variant:String)->void:
	var f:=_figure(variant)
	for clip:String in Pose.CLIPS:
		var source:Animation=f.player.get_meta(&"pose_clearance_original_stand") if clip=="stand" else Acting.library(f.variant)[clip]
		var before:=_signature(source)
		var fitted:=Pose.fitted(source,f.skeleton,f.variant,clip)
		assert_object(fitted).is_not_same(source)
		assert_object(Pose.fitted(source,f.skeleton,f.variant,clip)).is_same(fitted)
		var after:=_signature(fitted)
		assert_array(after.slice(0,3)).is_equal(before.slice(0,3))
		for track in source.get_track_count():
			if Pose._arm_track(source,track,clip!="stand"):
				assert_array(after[track+3].slice(0,5)).is_equal(before[track+3].slice(0,5))
				for key in source.track_get_key_count(track):assert_array(after[track+3][key+5].slice(0,2)).is_equal(before[track+3][key+5].slice(0,2))
			else:assert_array(after[track+3]).is_equal(before[track+3])
		assert_array(_signature(source)).is_equal(before)
	f.free()

func test_actor_sampler_fits_only_cross_sit_and_keeps_consequences_and_props_exact()->void:
	var f:=_figure();var acting=Acting.of(f)
	var cross=acting._layer("sit_cross",{"at":.4,"speed":1.7,"blend":.25})
	assert_object(cross.anim).is_not_same(Acting.library(f.variant).sit_cross)
	assert_float(cross.t).is_equal(.4);assert_float(cross.speed).is_equal(1.7)
	assert_float(cross.blend_in).is_equal(.25)
	for clip:String in ["kneel","exec_club_batter","stance_guard","stance_bundle","bow_deep"]:
		var layer=acting._layer(clip,{})
		assert_object(layer.anim).is_same(Acting.library(f.variant)[clip])
	f.free()

func test_redress_preserves_stand_clock_pause_and_walking_resources()->void:
	var f:=_figure();var player:=f.player
	var stand:=player.get_animation("stand");var walking:=player.get_animation("walk_in")
	var walk_data:=_signature(walking)
	f.play("stand",0.0,0.0);player.advance(.43);player.speed_scale=1.4;player.pause()
	var time:=player.current_animation_position;var rate:=player.speed_scale
	for outfit:String in ["robe","tunic"]:
		f.look.outfit=outfit;f._dress()
		assert_object(player.get_animation("stand")).is_same(stand)
		assert_bool(player.is_playing()).is_false()
		assert_float(player.current_animation_position).is_equal_approx(time,.000001)
		assert_float(player.speed_scale).is_equal(rate)
	assert_object(player.get_animation("walk_in")).is_same(walking)
	assert_array(_signature(walking)).is_equal(walk_data)
	f.free()
