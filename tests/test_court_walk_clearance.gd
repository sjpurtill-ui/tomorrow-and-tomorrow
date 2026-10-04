extends GdUnitTestSuite
const Figure=preload("res://scripts/hud/court_figure_3d.gd")
const Clearance=preload("res://scripts/hud/court_walk_clearance.gd")

func _signature(animation:Animation)->Array:
	var result:Array=[animation.length,animation.step,animation.loop_mode]
	for track in animation.get_track_count():
		var item:Array=[animation.track_get_type(track),animation.track_get_path(track),animation.track_is_enabled(track),animation.track_get_interpolation_type(track),animation.track_get_interpolation_loop_wrap(track)]
		for key in animation.track_get_key_count(track):item.append([animation.track_get_key_time(track,key),animation.track_get_key_transition(track,key),animation.track_get_key_value(track,key)])
		result.append(item)
	return result

func test_all_bodies_change_only_walking_upper_arm_rotations_and_keep_sources_immutable()->void:
	for variant:String in Figure.BODIES:
		var figure:=Figure.new();add_child(figure);figure.setup({"variant":variant,"outfit":"tunic"})
		var sources:Dictionary=figure.player.get_meta(&"walk_clearance_originals")
		for clip:String in Clearance.CLIPS:
			Clearance.configure(figure.player,figure.skeleton,variant,"tunic")
			var source:Animation=sources[clip];var before:=_signature(source)
			var fitted:=figure.player.get_animation(clip)
			assert_object(fitted).is_not_same(source)
			var actual:=_signature(fitted);assert_array(actual.slice(0,3)).is_equal(before.slice(0,3))
			var changed:=0
			for track in source.get_track_count():
				var path:=String(source.track_get_path(track))
				if source.track_get_type(track)==Animation.TYPE_ROTATION_3D and (path.ends_with(":upper_arm.L") or path.ends_with(":upper_arm.R")):
					changed+=1
					assert_array(actual[track+3].slice(0,5)).is_equal(before[track+3].slice(0,5))
					for key in source.track_get_key_count(track):
						assert_array(actual[track+3][key+5].slice(0,2)).is_equal(before[track+3][key+5].slice(0,2))
						assert_float(rad_to_deg(source.track_get_key_value(track,key).angle_to(fitted.track_get_key_value(track,key)))).is_equal_approx(Clearance.degrees_for(variant,"tunic"),.01)
				else:assert_array(actual[track+3]).is_equal(before[track+3])
			assert_int(changed).is_equal(2)
			Clearance.configure(figure.player,figure.skeleton,variant,"courtcoat")
			assert_array(_signature(source)).is_equal(before)
		figure.free()

func test_redress_keeps_walk_clock_rate_pause_and_reuses_unaccumulated_fit()->void:
	var figure:=Figure.new();add_child(figure);figure.setup({"variant":"female_old","outfit":"tunic"})
	var player:AnimationPlayer=figure.player
	var originals:Dictionary=player.get_meta(&"walk_clearance_originals")
	var first:=player.get_animation("walk_in")
	var seated:=player.get_animation("sit_talk")
	figure.play("walk_in",0.0,0.0);player.speed_scale=1.4;player.advance(.37)
	var at:=player.current_animation_position
	var rate:=player.speed_scale
	for outfit:String in ["courtcoat","business","medieval","tunic"]:
		figure.look.outfit=outfit;figure._dress()
		assert_str(player.current_animation).is_equal("walk_in")
		assert_float(player.current_animation_position).is_equal_approx(at,.000001)
		assert_float(player.speed_scale).is_equal(rate)
		assert_bool(player.is_playing()).is_true()
		assert_object(player.get_animation("sit_talk")).is_same(seated)
	assert_object(player.get_animation("walk_in")).is_same(first)
	player.pause();figure.look.outfit="formal";figure._dress()
	assert_bool(player.is_playing()).is_false()
	assert_float(player.current_animation_position).is_equal_approx(at,.000001)
	Clearance.configure(player,figure.skeleton,figure.variant,"tunic",0.0)
	assert_array(_signature(player.get_animation("walk_in"))).is_equal(_signature(originals.walk_in))
	assert_array(_signature(player.get_animation("walk_out"))).is_equal(_signature(originals.walk_out))
	assert_int(Clearance._cache.size()).is_less_equal(Clearance.CACHE_LIMIT)
	figure.free()

func test_two_figures_reuse_cached_fits_without_sharing_mutable_walk_resources()->void:
	var first:=Figure.new();var second:=Figure.new();add_child(first);add_child(second)
	first.setup({"variant":"female_adult","outfit":"business"})
	var cached:=Clearance._cache.size()
	second.setup({"variant":"female_adult","outfit":"business"})
	assert_int(Clearance._cache.size()).is_equal(cached)
	assert_object(first.player.get_animation_library(&"")).is_not_same(second.player.get_animation_library(&""))
	assert_object(first.player.get_animation("walk_in")).is_not_same(second.player.get_animation("walk_in"))
	var unaltered:=_signature(second.player.get_animation("walk_in"))
	Clearance.configure(first.player,first.skeleton,first.variant,"courtcoat")
	assert_array(_signature(second.player.get_animation("walk_in"))).is_equal(unaltered)
	first.free();second.free()

func test_reverse_playback_rate_and_cache_eviction_do_not_change_live_clips()->void:
	var figure:=Figure.new();add_child(figure);figure.setup({"variant":"male_adult","outfit":"business"})
	var player:AnimationPlayer=figure.player
	player.speed_scale=1.25;player.play("walk_out",0.0,-.6,true);player.advance(.2)
	var speed:=player.get_playing_speed();var at:=player.current_animation_position
	Clearance.configure(player,figure.skeleton,figure.variant,"robe")
	assert_float(player.get_playing_speed()).is_equal_approx(speed,.000001)
	assert_float(player.current_animation_position).is_equal_approx(at,.000001)
	var source:Animation=player.get_meta(&"walk_clearance_originals").walk_out
	var original:=_signature(source)
	for degree in range(1,40):Clearance.configure(player,figure.skeleton,figure.variant,"robe",float(degree))
	assert_int(Clearance._cache.size()).is_less_equal(Clearance.CACHE_LIMIT)
	assert_array(_signature(source)).is_equal(original)
	assert_float(player.get_playing_speed()).is_equal_approx(speed,.000001)
	figure.free()

func test_redress_during_zero_speed_or_pause_preserves_reverse_custom_speed()->void:
	var first:=Figure.new();var control:=Figure.new();add_child(first);add_child(control)
	for figure:Node in [first,control]:
		figure.setup({"variant":"female_old","outfit":"business"})
		figure.player.play("walk_in",0.0,-.6,true);figure.player.advance(.2)
	var at:float=first.player.current_animation_position
	first.player.queue("stand")
	var queued:=first.player.get_queue()
	first.player.speed_scale=0.0
	first.look.outfit="robe";first._dress()
	assert_bool(first.player.get_queue()==queued).is_true()
	first.player.speed_scale=1.0
	assert_float(first.player.get_playing_speed()).is_equal(control.player.get_playing_speed())
	assert_float(first.player.current_animation_position).is_equal(at)
	first.player.pause();control.player.pause()
	var arm:int=first.skeleton.find_bone("upper_arm.L")
	var before:Quaternion=first.skeleton.get_bone_pose_rotation(arm)
	first.look.outfit="formal";first._dress()
	assert_bool(first.player.is_playing()).is_false()
	assert_float(before.angle_to(first.skeleton.get_bone_pose_rotation(arm))).is_greater(.01)
	first.player.play();control.player.play()
	assert_float(first.player.get_playing_speed()).is_equal(control.player.get_playing_speed())
	assert_float(first.player.current_animation_position).is_equal(control.player.current_animation_position)
	first.free();control.free()
