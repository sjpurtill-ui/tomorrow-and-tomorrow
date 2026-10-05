extends GdUnitTestSuite
## Check the imported feet, not just the stage's travel clock. A planted foot
## must move backward relative to the body so forward travel cancels it.
const Figure:=preload("res://scripts/hud/court_figure_3d.gd")

func test_low_feet_sweep_backward_in_both_walks_on_every_body()->void:
	_assert_gait("average",true)

func test_varied_builds_keep_forward_gait_and_grounded_ankle_speed()->void:
	for build:String in ["stocky","lanky","round","slight"]:
		_assert_gait(build,false)

func _assert_gait(build:String,check_toe_speed:bool)->void:
	for variant:String in Figure.BODIES:
		var figure:=Figure.new();add_child(figure)
		assert_bool(figure.setup({"variant":variant,"outfit":"tunic","varied":true,"build":build,"tall":1.0})).is_true()
		figure.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		for clip:String in ["walk_in","walk_out"]:
			figure.play(clip,0.0,0.0)
			var seconds:=figure.clip_length(clip)
			for bone_name:String in ["foot.L","foot.R","toe.L","toe.R"]:
				var bone:=figure.skeleton.find_bone(bone_name)
				var points:Array[Vector3]=[]
				var heights:Array[float]=[]
				for frame in 121:
					figure.player.seek(seconds*float(frame)/120.0,true)
					var point:=figure.skeleton.to_global(figure.skeleton.get_bone_global_pose(bone).origin)
					points.append(point);heights.append(point.y)
				heights.sort()
				# Ankle and toe references sit at different heights. Contact is
				# within two scaled centimetres of each reference's floorward limit.
				var cutoff:=heights[0]+0.02*figure.body_height/Figure.REFERENCE_HEIGHT
				var planted:=0
				var backward:=0
				var slip:=0.0
				var pace:float=Figure.WALK_SPEED[clip]*figure.body_height/Figure.REFERENCE_HEIGHT
				for frame in 120:
					if maxf(points[frame].y,points[frame+1].y)>cutoff:continue
					var velocity:=(points[frame+1].z-points[frame].z)*120.0/seconds
					planted+=1
					if velocity<0.0:backward+=1
					slip+=absf(velocity+pace)
				var label:="%s %s %s %s" % [variant,build,clip,bone_name]
				assert_int(planted).override_failure_message(label+": no low-foot samples").is_greater(12)
				assert_int(backward).override_failure_message(label+": planted foot moves forward (moonwalk)").is_equal(planted)
				# Depth/height vary independently across builds. Toe rocking adds
				# tangential motion, so use the ankle for their speed calibration.
				if check_toe_speed or bone_name.begins_with("foot."):
					assert_float(slip/maxi(planted,1)).override_failure_message(label+": floor slip %.3f m/s at pace %.3f m/s" % [slip/maxi(planted,1),pace]).is_less(pace*0.5)
		figure.free()
