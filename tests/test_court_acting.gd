extends GdUnitTestSuite
## COURT ACTING (scripts/hud/court_acting.gd; clips from tools/blender/court_anims.py).
## The people of the court act like people, not mannequins:
## - every body has the shared clip library, built on its own skeleton;
## - a reaction plays over their stance and lets go of it, eased; a held one
##   (a kneel) stays until let go; a sitter keeps their seat and a staff stays
##   in its hand;
## - they blink every few seconds, breathe, shift, and look at what they
##   attend to within human limits;
## - the mouth follows the words' syllables and the head beats on stressed words;
## - moods show in the face, eased;
## - nothing moves while the court is out of sight, and a frame allocates nothing.
## Headless and quick: frames are stepped by hand.

const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const DT:=1.0/30.0
const CORE:=["gasp","flinch","laugh","laugh_polite","laugh_stifled","side_eye_l","side_eye_r","bow_shallow","bow_deep","bow_overdeep","kneel","defiant",
	"talk_explain","talk_emphatic","talk_hesitant","talk_plead","talk_one","talk_dismiss","scratch_head"]


func _figure(stance:="stand",variant:="male_adult")->Node3D:
	var f:Node3D=auto_free(Figure3D.new())
	f.set_meta(&"person_name","Test %s %s" % [variant,stance])
	add_child(f)
	assert_bool(f.setup({"variant":variant,"outfit":"tunic","hair":"cropped","stance":stance})).is_true()
	f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	f.play(f.rest_clip(),0.0,0.0)
	f.player.advance(0.0)
	return f


## Frames by hand: the stance clip, then the acting (as the skeleton runs it;
## the skeleton puts its poses back after each frame's modifiers).
func _run(f:Node3D,seconds:float)->void:
	var a=Acting.of(f)
	for i in int(round(seconds/DT)):
		_frame(f,a)


func _frame(f:Node3D,a)->void:
	f.skeleton.reset_bone_poses()
	f.player.advance(DT)
	a.step(DT)


func _hand(f:Node3D,side:="R")->Vector3:
	var b:int=f.skeleton.find_bone("hand."+side)
	return f.skeleton.get_bone_global_pose(b).origin


func _bone_y(f:Node3D,bone:String)->float:
	return f.skeleton.get_bone_global_pose(f.skeleton.find_bone(bone)).origin.y


func test_clips_play_at_their_own_length()->void:
	## Blender keys a frame each 1/30 s; the library must say so (a scene left at
	## 24 fps once played every clip 1.25 times slower than its face).
	for variant in Figure3D.VARIANTS:
		var lib:=Acting.library(variant)
		for clip in ["gasp","laugh","kneel","stance_guard"]:
			var anim:Animation=lib.get(clip)
			assert_object(anim).is_not_null()
			if anim==null:continue
			assert_float(anim.length).override_failure_message("%s %s lasts %.2f s, not %.2f" % [variant,clip,anim.length,Acting.clip_length(clip)]).is_equal_approx(Acting.clip_length(clip),0.04)


func test_every_body_has_the_shared_clip_library()->void:
	for clip in CORE:
		assert_bool(Acting.has_clip(clip)).override_failure_message("no %s in court_anims.json" % clip).is_true()
		var meta:=Acting.clip_meta(clip)
		assert_float(float(meta.get("length",0.0))).is_greater(0.5)
		assert_bool((meta.get("groups",{}) as Dictionary).has("arm_R")).is_true()
	for variant in Figure3D.VARIANTS:
		var lib:=Acting.library(variant)
		for clip in CORE:
			assert_bool(lib.has(clip)).override_failure_message("%s has no %s" % [variant,clip]).is_true()


func test_the_library_is_built_on_each_bodys_own_skeleton()->void:
	## The clips carry bone rotations from their own armature: it should be the
	## figure's (same bones, same rests). The acting fits a stale library onto a
	## rebuilt body, but hands then miss what they reach for: this says rebuild
	## (tools/blender/court_anims.py) after the bodies change.
	for variant in Figure3D.VARIANTS:
		var lib_root:=Acting.load_glb(Acting.DIR+"court_anims_%s.glb" % variant)
		var lib_skel:Skeleton3D=lib_root.find_children("*","Skeleton3D",true,false)[0]
		# the body as this checkout has it (the shared import cache may hold another's newer build)
		var body_root:=Acting.load_glb(Figure3D.DIR+"court_figure_%s.glb" % variant)
		var body_skel:Skeleton3D=body_root.find_children("*","Skeleton3D",true,false)[0]
		for i in body_skel.get_bone_count():
			var name:=body_skel.get_bone_name(i)
			if name in ["jaw","eye.L","eye.R","brow.L","brow.R","root"] or name.begins_with("neutral"):continue
			var j:=lib_skel.find_bone(name)
			assert_int(j).override_failure_message("%s: the library has no bone %s" % [variant,name]).is_greater_equal(0)
			if j<0:continue
			var a:=body_skel.get_bone_global_rest(i)
			var b:=lib_skel.get_bone_global_rest(j)
			assert_float(a.origin.distance_to(b.origin)).override_failure_message("%s %s rest moved" % [variant,name]).is_less(0.004)
			var angle:=a.basis.get_rotation_quaternion().angle_to(b.basis.get_rotation_quaternion())
			assert_float(rad_to_deg(angle)).override_failure_message("%s %s rest turned %.1f deg" % [variant,name,rad_to_deg(angle)]).is_less(2.0)
		lib_root.free();body_root.free()


func test_a_gasp_brings_a_hand_to_the_heart_and_lets_go()->void:
	var f:=_figure()
	_run(f,0.5)
	var rest_hand:=_hand(f)
	var length:=Acting.play(f,"gasp")
	assert_float(length).is_greater(1.0)
	_run(f,0.6)
	var a=Acting.of(f)
	assert_float(_hand(f).y-rest_hand.y).override_failure_message("the hand did not come up to the breast").is_greater(0.22)
	assert_float(a.face_now[Acting.CH_JAW]).is_greater(0.25)
	assert_float(a.face_now[Acting.CH_BROWS]).is_greater(0.4)
	_run(f,length)
	assert_float(_hand(f).distance_to(rest_hand)).override_failure_message("the hand did not go back down").is_less(0.06)


func test_a_kneel_holds_until_let_go()->void:
	var f:=_figure()
	_run(f,0.3)
	var stand:=_bone_y(f,"hips")
	Acting.play(f,"kneel")
	_run(f,3.0)
	assert_float(stand-_bone_y(f,"hips")).override_failure_message("not down on a knee").is_greater(0.25)
	_run(f,3.0)
	assert_float(stand-_bone_y(f,"hips")).override_failure_message("did not stay down").is_greater(0.25)
	Acting.stop(f)
	_run(f,1.2)
	assert_float(absf(stand-_bone_y(f,"hips"))).override_failure_message("did not get up again").is_less(0.03)


func test_a_new_reaction_crossfades_from_the_last()->void:
	var f:=_figure()
	_run(f,0.3)
	Acting.play(f,"bow_deep")
	_run(f,1.2)
	var before:=_hand(f)
	Acting.play(f,"defiant")
	var a=Acting.of(f)
	var fastest:=0.0
	var last:=before
	for i in 12:
		_frame(f,a)
		fastest=maxf(fastest,_hand(f).distance_to(last)/DT)
		last=_hand(f)
	# the hands travel from the bow to the folded arms, never jumping (a quick
	# human arm moves 3-5 m/s; a pop from one pose to another is 9 m/s and more)
	assert_float(fastest).is_less(5.0)


func test_a_sitter_keeps_their_seat_and_a_staff_its_hand()->void:
	var sitter:=_figure("sit")
	_run(sitter,0.3)
	var seat:=_bone_y(sitter,"hips")
	Acting.play(sitter,"gasp")
	_run(sitter,0.7)
	assert_float(absf(_bone_y(sitter,"hips")-seat)).override_failure_message("the sitter stood up to gasp").is_less(0.02)
	var holder:=_figure("staff")
	_run(holder,0.3)
	var grip:=_hand(holder,"R")
	Acting.play(holder,"gasp")
	_run(holder,0.7)
	assert_float(_hand(holder,"R").distance_to(grip)).override_failure_message("the staff left the hand").is_less(0.05)


func test_they_blink_every_few_seconds()->void:
	var f:=_figure()
	var a=Acting.of(f)
	var blinks:=0
	var shut:=false
	var longest:=0.0
	var closed_for:=0.0
	for i in int(12.0/DT):
		_frame(f,a)
		var now:bool=a.lids_now<0.35
		if now and not shut:blinks+=1
		closed_for=closed_for+DT if now else 0.0
		longest=maxf(longest,closed_for)
		shut=now
	assert_int(blinks).is_between(2,9)
	assert_float(longest).is_less(0.2)


func test_the_head_turns_to_what_they_look_at_within_limits()->void:
	var f:=_figure()
	_run(f,0.3)
	var head:int=f.skeleton.find_bone("head")
	var skel:Skeleton3D=f.skeleton
	var at:Vector3=skel.global_transform*skel.get_bone_global_pose(head).origin
	# three metres to their left, at their own height
	Acting.look_toward(f,at+f.global_transform.basis*Vector3(3.0,0.0,0.3),1.0)
	_run(f,1.2)
	var a=Acting.of(f)
	var fwd:Vector3=skel.get_bone_global_pose(head).basis.get_rotation_quaternion()*a._rest_gi[head]*Vector3.BACK
	assert_float(rad_to_deg(atan2(fwd.x,fwd.z))).override_failure_message("the head did not turn left").is_greater(45.0)
	# right behind them: they turn as far as a person can, no further
	Acting.look_toward(f,at+f.global_transform.basis*Vector3(0.2,0.0,-3.0),1.0)
	_run(f,1.2)
	assert_float(absf(a.look_yaw)).is_less_equal(75.01)


func test_idle_eyes_never_stare_out_at_the_viewer()->void:
	var f:=_figure()
	var a=Acting.of(f)
	var head:int=f.skeleton.find_bone("head")
	var ahead:=0
	var frames:=0
	for i in int(20.0/DT):
		_frame(f,a)
		if i%15!=0:continue
		var fwd:Vector3=(f.skeleton as Skeleton3D).get_bone_global_pose(head).basis.get_rotation_quaternion()*a._rest_gi[head]*Vector3.BACK
		frames+=1
		# straight out at the viewer: level and within a few degrees of dead ahead
		if absf(rad_to_deg(atan2(fwd.x,fwd.z)))<6.0 and absf(rad_to_deg(asin(clampf(fwd.y,-1.0,1.0))))<4.0:ahead+=1
	assert_float(float(ahead)/float(frames)).is_less(0.25)


func test_the_mouth_follows_the_words_and_the_head_beats()->void:
	var f:=_figure()
	var a=Acting.of(f)
	var line:="Count the stores again before the moon is full, and let the scribes write what they find."
	Acting.speak(f,line,4.0,{"gestures":false})
	assert_int(a._beats.size()).is_greater(0)
	assert_int(a._syl_t.size()).is_greater(15)
	var hi:=0.0
	var lo:=1.0
	for i in int(3.6/DT):
		_frame(f,a)
		hi=maxf(hi,a.face_now[Acting.CH_JAW]);lo=minf(lo,a.face_now[Acting.CH_JAW])
	assert_float(hi).is_greater(0.6)
	assert_float(lo).is_less(0.05)
	_run(f,0.6)
	assert_bool(a.speaking).is_false()
	assert_float(a.face_now[Acting.CH_JAW]).is_less(0.05)
	assert_array(Array(Acting._syllables("moon"))).is_equal([3,2])
	assert_array(Array(Acting._syllables("stores"))).is_equal([2])


func test_a_long_line_brings_a_gesture_where_a_hand_is_free()->void:
	var f:=_figure("stand")
	var a=Acting.of(f)
	Acting.speak(f,"We will not give them the ford! Send every spear we have!",4.0)
	assert_int(a._gest_clip.size()).is_greater(0)
	assert_str(a._gest_clip[0]).is_equal("talk_emphatic")
	var folded:=_figure("folded")
	var b=Acting.of(folded)
	Acting.speak(folded,"We will not give them the ford! Send every spear we have!",4.0)
	# arms folded: no hand free, so the words come from the head alone
	assert_int(b._gest_clip.size()).is_equal(0)


func test_moods_show_in_the_face_eased()->void:
	var f:=_figure()
	var a=Acting.of(f)
	Acting.set_mood(f,{"fear":1.0})
	_run(f,DT)
	assert_float(a.face_now[Acting.CH_WORRY]).override_failure_message("fear popped onto the face").is_less(0.2)
	_run(f,2.5)
	assert_float(a.face_now[Acting.CH_WORRY]).is_greater(0.6)
	Acting.set_mood(f,{"anger":1.0})
	_run(f,2.5)
	assert_float(a.face_now[Acting.CH_STERN]).is_greater(0.6)
	assert_float(a.face_now[Acting.CH_WORRY]).is_less(0.25)


func test_the_figures_own_mood_word_is_followed()->void:
	var f:=_figure()
	var a=Acting.of(f)
	f.set_mood("warm")
	_run(f,2.5)
	assert_float(a.face_now[Acting.CH_SMILE]).is_greater(0.3)


func test_nothing_moves_while_the_court_is_out_of_sight()->void:
	var f:=_figure()
	var a=Acting.of(f)
	_run(f,0.2)
	var clock:float=a._clock
	f.visible=false
	_run(f,1.0)
	assert_float(a._clock).is_equal(clock)
	f.visible=true
	Acting.paused_all=true
	_run(f,1.0)
	Acting.paused_all=false
	assert_float(a._clock).is_equal(clock)


func test_a_frame_of_acting_makes_no_objects()->void:
	var f:=_figure()
	var a=Acting.of(f)
	Acting.play(f,"laugh")
	Acting.speak(f,"So the river has eaten the lower field again.",3.0,{"gestures":false})
	_run(f,0.2)
	var before:=Performance.get_monitor(Performance.OBJECT_COUNT)
	for i in 60:
		_frame(f,a)
	assert_float(Performance.get_monitor(Performance.OBJECT_COUNT)).is_equal(before)


func test_acting_is_presentation_only()->void:
	## It reads the figure it moves and nothing else; it never touches the game.
	var text:=FileAccess.get_file_as_string("res://scripts/hud/court_acting.gd")
	for name in ["GameState","GovernmentPeopleSystem","SaveSystem","DiscoverySystem","HistoricalFigures","MilitaryCampaign","get_node(\"/root"]:
		assert_bool(text.contains(name)).override_failure_message("court_acting.gd reaches into %s" % name).is_false()


func test_the_stage_hook_takes_the_figure_first()->void:
	## CourtStage.acting (docs/COURT_STAGE_3D.md §5) calls act(figure, ...args).
	var service:=Acting.service()
	for method in ["play","look_at","mood","set_mood","speak","gesture","idle","hush","stop"]:
		assert_bool(service.has_method(method)).override_failure_message("the hook has no %s" % method).is_true()
	var f:=_figure()
	service.callv("play",[f,"bow_shallow"])
	service.callv("mood",[f,"afraid"])
	service.callv("gesture",[f,"nod"])
	var a=Acting.of(f)
	assert_str(a._a.clip).is_equal("bow_shallow")
	assert_float(a._mood_target[Acting.M_FEAR]).is_greater(0.5)
	assert_int(a._g).is_equal(Acting.GESTURES.find("nod"))
	# the clips also play plainly on the figure's own player
	assert_bool(f.player.has_animation("act/gasp")).is_true()


func test_real_frames_run_the_acting_and_nothing_piles_up()->void:
	## In the engine the skeleton runs the acting after the clip every frame
	## and restores its poses after drawing: what acting adds never accumulates.
	var f:Node3D=auto_free(Figure3D.new())
	add_child(f)
	f.setup({"variant":"female_adult","outfit":"hide","hair":"braids","stance":"sit"})
	f.play(f.rest_clip(),0.0,0.0)
	f.player.stop()
	var a=Acting.of(f)
	var hips:int=f.skeleton.find_bone("hips")
	var start:Vector3=(f.skeleton as Skeleton3D).get_bone_pose_position(hips)
	var clock:float=a._clock
	for i in 40:await get_tree().process_frame
	assert_float(a._clock).override_failure_message("the skeleton never ran the acting").is_greater(clock)
	assert_float(f.skeleton.get_bone_pose_position(hips).distance_to(start)).is_less(0.02)


func test_the_directors_acts_are_performed()->void:
	## court_director.gd lowers its beats to {act:"play", args:{clip, fallback,
	## hold, at, ...}} and {act:"mood", args:{vector, face, dur, hold}}: each act
	## the director asked for first has a performance here.
	var service=Acting.service()
	var f:=_figure()
	var a=Acting.of(f)
	for act in ["faint","half_catch","knees_knock","bow_deep","hide_behind","peek_out","yawn","doze","jerk_awake","snap_alert",
			"stifle_laugh","elbow","struggle_bundle","set_down_bundle","lift_bundle","drop_bowl","stand_firm","kneel_bound","bolt","flinch","wobble","step_back"]:
		var spec:Array=Acting.ACT_MAP.get(act,[])
		assert_bool(spec.is_empty()).override_failure_message("no performance for %s" % act).is_false()
		if String(spec[0])=="clip":
			var clip:=String(spec[1])
			for c in ([clip+"l",clip+"r"] if clip.ends_with("_") else [clip]):
				assert_bool(Acting.has_clip(c)).override_failure_message("%s wants %s, not in the library" % [act,c]).is_true()
	for act in ["gulp","shrug","tremble","freeze","straighten"]:
		assert_str(String(Acting.ACT_MAP[act][0])).is_equal("gesture")
	service.play(f,{"clip":"faint","beat":"faint","fallback":"kneel","hold":true,"speed":1.0,"blend":0.25,"at":""})
	assert_str(String(a._a.clip)).starts_with("faint_")
	assert_bool(a._a.hold).is_true()
	# a beat's face comes and goes: worried brows for the flinch's time
	service.mood(f,{"vector":{"fear":0.8},"name":"afraid","face":{"brows_worried":0.9,"eyes_wide":0.6},"dur":0.6,"hold":false,"beat":"flinch"})
	_run(f,0.3)
	assert_float(a.face_now[Acting.CH_WORRY]).is_greater(0.6)
	_run(f,1.5)
	assert_float(a._beat_w).is_less(0.05)
	# an unknown act plays the figure's own clip the director named
	var g:=_figure()
	service.play(g,{"clip":"no_such_act","beat":"no_such_act","fallback":"bow","hold":false,"speed":1.0,"blend":0.25})
	assert_str(String(g.clip)).is_equal("bow")


# --- round 2 ------------------------------------------------------------------------

func _head_yaw(f:Node3D)->float:
	var a=Acting.of(f)
	var head:int=f.skeleton.find_bone("head")
	var fwd:Vector3=(f.skeleton as Skeleton3D).get_bone_global_pose(head).basis.get_rotation_quaternion()*a._rest_gi[head]*Vector3.BACK
	return rad_to_deg(atan2(fwd.x,fwd.z))


func _head_pitch(f:Node3D)->float:
	var a=Acting.of(f)
	var head:int=f.skeleton.find_bone("head")
	var fwd:Vector3=(f.skeleton as Skeleton3D).get_bone_global_pose(head).basis.get_rotation_quaternion()*a._rest_gi[head]*Vector3.BACK
	return rad_to_deg(asin(clampf(fwd.y,-1.0,1.0)))


func test_the_big_laugh_throws_the_head_back_and_the_polite_one_does_not()->void:
	var f:=_figure()
	var a=Acting.of(f)
	Acting.set_ambient(f,0.0)
	_run(f,0.5)
	var rest_pitch:=_head_pitch(f)
	Acting.play(f,"laugh")
	_run(f,0.55)
	assert_float(_head_pitch(f)-rest_pitch).override_failure_message("the head did not go back").is_greater(14.0)
	assert_float(a.face_now[Acting.CH_JAW]).is_greater(0.5)
	assert_float(a.face_now[Acting.CH_SMILE]).is_greater(0.8)
	var g:=_figure()
	Acting.set_ambient(g,0.0)
	_run(g,0.5)
	var g_rest:=_head_pitch(g)
	Acting.play(g,"laugh_polite")
	_run(g,0.5)
	var lift:=_head_pitch(g)-g_rest
	assert_float(lift).is_between(2.0,14.0)


func test_a_side_eye_turns_the_head_and_narrows_the_lids()->void:
	var f:=_figure()
	var a=Acting.of(f)
	Acting.set_ambient(f,0.0)
	_run(f,0.5)
	var rest_yaw:=_head_yaw(f)
	Acting.play(f,"side_eye_l")
	_run(f,1.3)
	assert_float(_head_yaw(f)-rest_yaw).override_failure_message("the head did not turn to its left").is_greater(18.0)
	assert_float(a.face_now[Acting.CH_LIDS]).is_less(0.7)


func test_a_half_catch_takes_the_weight_on_bent_knees()->void:
	var f:=_figure()
	_run(f,0.3)
	var stand:=_bone_y(f,"hips")
	var hand0:=_hand(f,"L")
	Acting.play(f,"half_catch_l")
	_run(f,1.0)
	assert_float(stand-_bone_y(f,"hips")).override_failure_message("the knees did not bend to take them").is_greater(0.12)
	assert_float(_hand(f,"L").x-hand0.x).override_failure_message("the hands did not go out to them").is_greater(0.15)


func test_a_faint_never_goes_through_the_floor()->void:
	var f:=_figure()
	var a=Acting.of(f)
	_run(f,0.3)
	Acting.play(f,"faint_l")
	var lowest:=10.0
	for i in int(2.4/DT):
		_frame(f,a)
		for bone in ["foot.L","foot.R","toe.L","toe.R","shin.L","shin.R"]:
			lowest=minf(lowest,_bone_y(f,bone))
	assert_float(lowest).override_failure_message("a foot went %.3f m into the floor" % -lowest).is_greater(-0.02)
	assert_float(_bone_y(f,"hips")).override_failure_message("not down on the floor").is_less(0.35)


func test_stances_for_life_from_the_acting()->void:
	# the guard leans on the figure's staff: the stance under it is the staff's, the hand stays put
	var g:=_figure()
	Acting.idle(g,"guard")
	assert_str(String(g.stance)).is_equal("staff")
	var a=Acting.of(g)
	assert_str(String(a.base_stance)).is_equal("guard")
	_run(g,1.0)
	var lo:=_hand(g,"R");var hi:=_hand(g,"R")
	for i in int(8.0/DT):
		_frame(g,a)
		var h:=_hand(g,"R")
		lo=Vector3(minf(lo.x,h.x),minf(lo.y,h.y),minf(lo.z,h.z));hi=Vector3(maxf(hi.x,h.x),maxf(hi.y,h.y),maxf(hi.z,h.z))
	assert_float((hi-lo).length()).override_failure_message("the staff hand wandered %.3f m" % (hi-lo).length()).is_less(0.012)
	# an elder on a low seat sits lower than on a high one
	var low:=_figure()
	Acting.idle(low,"log",{"seat":0.30*low.body_height/1.72})
	var high:=_figure()
	Acting.idle(high,"log",{"seat":0.46*high.body_height/1.72})
	_run(low,1.0);_run(high,1.0)
	assert_float(_bone_y(high,"hips")-_bone_y(low,"hips")).is_between(0.08,0.24)
	# seated, a gasp does not stand them up
	var seat:=_bone_y(low,"hips")
	Acting.play(low,"gasp")
	_run(low,0.7)
	assert_float(absf(_bone_y(low,"hips")-seat)).is_less(0.02)
	# by the fire they crouch
	var fire:=_figure()
	Acting.idle(fire,"fire")
	_run(fire,1.0)
	assert_float(_bone_y(fire,"hips")).is_less(0.6)
	# and back to a stance of the figure's own: the acting's base goes
	Acting.idle(fire,"stand")
	_run(fire,1.0)
	assert_str(String(Acting.of(fire).base_stance)).is_empty()
	assert_float(_bone_y(fire,"hips")).is_greater(0.8)


func test_exits_are_plans_of_clips_the_library_has()->void:
	for style in ["bow","storm","storm_back","sober","led"]:
		var plan:Array=Acting.exit_plan(style)
		assert_int(plan.size()).is_greater(0)
		var leaves:=false
		for step:Dictionary in plan:
			var clip:=String(step.clip)
			assert_bool(Acting.has_clip(clip) or clip=="walk_out").override_failure_message("%s: no clip %s" % [style,clip]).is_true()
			if float(step.move)<0.0 and String(step.face)=="out":leaves=true
		assert_bool(leaves).override_failure_message("%s never leaves" % style).is_true()
	for clip in ["back_out","storm_walk","walk_sober","walk_led"]:
		assert_float(float(Acting.clip_meta(clip).get("speed_mps",0.0))).is_greater(0.3)


func test_a_walk_of_the_actings_own_runs_over_the_figures_walk()->void:
	## The stage puts the figure's own walk underneath and plays the acting's
	## walk over it (court_stage.gd _acted: storm_walk over walk_in, walk_led
	## over walk_out): the acting's walk runs on until the stage stops it. A
	## reaction left on when the figure sets off still lets go.
	for pair in [["storm_walk","walk_in"],["walk_led","walk_out"],["walk_sober","walk_out"],["back_out","walk_in"]]:
		var f:=_figure()
		var a=Acting.of(f)
		f.play(String(pair[1]),0.25,0.0)
		Acting.play(f,String(pair[0]),{"blend":0.25,"loop":true})
		_run(f,2.5)
		assert_object(a._a).override_failure_message("%s was let go under the figure's %s" % pair).is_not_null()
		assert_str(String(a._a.clip)).is_equal(String(pair[0]))
		assert_float(a._a.weight()).is_greater(0.95)
		Acting.stop(f,0.2)
		_run(f,0.5)
		assert_object(a._a).is_null()
	var g:=_figure()
	var ga=Acting.of(g)
	Acting.play(g,"kneel",{"blend":0.1})
	_run(g,0.4)
	assert_object(ga._a).is_not_null()
	g.play("walk_in",0.25,0.0)
	_run(g,0.6)
	assert_object(ga._a).override_failure_message("a kneel stayed on while the figure walked off").is_null()


func test_acted_walks_keep_their_gait_until_explicitly_stopped()->void:
	for pair:Array in [["storm_walk","walk_in"],["walk_led","walk_out"],["back_out","stand"]]:
		var f:=_figure()
		f.play(String(pair[1]),0.0,0.0)
		Acting.play(f,String(pair[0]),{"loop":true})
		var a=Acting.of(f)
		_run(f,0.8)
		assert_object(a._a).override_failure_message("%s stopped during its walk" % pair[0]).is_not_null()
		if a._a==null:continue
		assert_str(String(a._a.clip)).is_equal(String(pair[0]))
		assert_float(float(a._a.fade_from)).is_less(0.0)
		var foot:int=f.skeleton.find_bone("foot.L")
		var first:Vector3=f.skeleton.get_bone_global_pose(foot).origin
		var reach:=0.0
		for i in 15:
			_frame(f,a)
			reach=maxf(reach,first.distance_to(f.skeleton.get_bone_global_pose(foot).origin))
		assert_float(reach).override_failure_message("%s has no moving foot" % pair[0]).is_greater(0.02)
		Acting.stop(f,0.2)
		_run(f,0.4)
		assert_object(a._a).is_null()


func test_walking_still_releases_a_previous_held_reaction()->void:
	var f:=_figure()
	Acting.play(f,"kneel",{"hold":true})
	_run(f,0.5)
	f.play("walk_in",0.0,0.0)
	_run(f,0.5)
	assert_object(Acting.of(f)._a).is_null()


func test_speech_keeps_the_walk_and_face_instead_of_replacing_the_gait()->void:
	for acted in [false,true]:
		var f:=_figure()
		f.play("walk_in",0.0,0.0)
		if acted:Acting.play(f,"storm_walk",{"loop":true})
		Acting.speak(f,"Bring everyone through the doorway!",3.0)
		var a=Acting.of(f)
		assert_int(a._gest_t.size()).is_greater(0)
		_run(f,1.0)
		assert_bool(a.speaking).is_true()
		assert_int(a._gest_i).is_greater(0)
		if acted:
			assert_object(a._a).is_not_null()
			if a._a!=null:assert_str(String(a._a.clip)).is_equal("storm_walk")
		else:assert_object(a._a).is_null()


func test_walk_layers_follow_the_figure_pace_without_retiming_reactions()->void:
	var f:=_figure()
	f.play("walk_in",0.0,0.0)
	f.set(&"locomotion_rate",0.5)
	Acting.play(f,"storm_walk",{"loop":true,"speed":1.2})
	var a=Acting.of(f)
	_run(f,0.5)
	assert_float(float(a._a.t)).is_equal_approx(0.3,0.01)
	# The outgoing gait follows the same rate during its crossfade.
	Acting.play(f,"walk_led",{"loop":true,"blend":1.0})
	_run(f,0.2)
	assert_float(float(a._a.t)).is_equal_approx(0.1,0.01)
	assert_float(float(a._b.t)).is_equal_approx(0.42,0.01)
	f.play("stand",0.0,0.0)
	f.set(&"locomotion_rate",0.5)
	Acting.play(f,"gasp")
	_run(f,0.2)
	assert_float(float(a._a.t)).is_equal_approx(0.2,0.01)


func test_the_stage_calls_reach_the_acting()->void:
	## court_stage.gd _beat: acting.play(body, act, args) and acting.set_mood(body, vector).
	var service=Acting.service()
	var f:=_figure()
	var a=Acting.of(f)
	service.play(f,"faint",{"clip":"faint","beat":"faint","fallback":"kneel","hold":true,"speed":1.0,"blend":0.25,"at":"","dur":1.6})
	assert_str(String(a._a.clip)).starts_with("faint_")
	service.set_mood(f,{"fear":0.8})
	assert_bool(a._mood_explicit).is_false()
	_run(f,0.4)
	assert_float(a._mood[Acting.M_FEAR]).is_greater(0.4)
	_run(f,3.0)
	assert_float(a._mood[Acting.M_FEAR]).is_less(0.2)


func test_the_face_runs_on_the_figures_expression_morphs()->void:
	var f:=_figure()
	var mouth:MeshInstance3D
	for m in f._meshes:
		if String(m.name)=="Mouth":mouth=m
	if mouth==null or mouth.find_blend_shape_by_name(&"smile")<0:return
	Acting.set_mood(f,{"joy":1.0})
	f.set_mood("warm")   # J's own mood morph would double the smile: the acting keeps it at 0
	_run(f,2.5)
	assert_float(mouth.get_blend_shape_value(mouth.find_blend_shape_by_name(&"smile"))).is_greater(0.5)
	assert_float(mouth.get_blend_shape_value(mouth.find_blend_shape_by_name(&"mood_smile"))).is_less(0.01)
	var a=Acting.of(f)
	Acting.speak(f,"Bring me the oxen.",1.5,{"gestures":false})
	var most:=0.0
	for i in 30:
		_frame(f,a)
		for v in Acting.VISEMES:
			var idx:=mouth.find_blend_shape_by_name(StringName(v))
			if idx>=0:most=maxf(most,mouth.get_blend_shape_value(idx))
	assert_float(most).override_failure_message("no viseme moved").is_greater(0.5)


func test_the_painted_mouth_and_the_skin_under_it_move_together()->void:
	## A viseme or the jaw is on the skin, the painted mouth and a beard: all of
	## them move (the painted mouth once stayed shut over a dropping jaw).
	var f:Node3D=auto_free(Figure3D.new())
	add_child(f)
	f.setup({"variant":"male_adult","outfit":"tunic","hair":"cropped","beard":"beard_full","stance":"stand"})
	f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var a=Acting.of(f)
	Acting.speak(f,"Bring me the oxen, all of them, and the carts.",2.0,{"gestures":false})
	var peak:={}
	for i in 50:
		_frame(f,a)
		for m in f._meshes:
			if not m.visible or m.mesh==null:continue
			for key in ["v_aa","v_ee","v_oo","jaw_open"]:
				var idx:int=m.find_blend_shape_by_name(StringName(key))
				if idx<0:continue
				peak[String(m.name)]=maxf(float(peak.get(String(m.name),0.0)),m.get_blend_shape_value(idx))
	for part in ["Mouth","Body"]:
		assert_float(float(peak.get(part,0.0))).override_failure_message("%s never opened (%s)" % [part,str(peak)]).is_greater(0.4)
	if peak.has("beard_full"):assert_float(float(peak.beard_full)).is_greater(0.4)


func test_the_rooms_business_is_in_the_library()->void:
	for act in ["cough","keep_apart","rub_belly","pat_belly","sharpen_spear","rub_hands","stamp_feet","swat_fly","stretch","whisper","wring_hands","shush","fan_self","laugh_polite"]:
		var spec:Array=Acting.ACT_MAP.get(act,[])
		assert_bool(spec.is_empty()).override_failure_message("no performance for %s" % act).is_false()
		var clip:=String(spec[1])
		for c in ([clip+"l",clip+"r"] if clip.ends_with("_") else [clip]):
			assert_bool(Acting.has_clip(c)).override_failure_message("%s wants %s" % [act,c]).is_true()


# --- round 3 ------------------------------------------------------------------------

func test_every_act_the_director_speaks_has_a_performance()->void:
	## Every name in court_director.gd ACTS (people's, not the camera's or the
	## animals') is a clip, a gesture, a look or a face here: none falls back.
	var text:=FileAccess.get_file_as_string("res://scripts/hud/court_director.gd")
	var start:=text.find("const ACTS:={")
	if start<0:return
	var block:=text.substr(start,text.find("\n}",start)-start)
	var re:=RegEx.new();re.compile("(?m)^\\t\"([a-z_]+)\":\\{")
	var not_people:=["wide","push_in","reaction","two_shot","shake","hush","perk_up","whimper","hide_under","sniff","tail_wag","lie_down","chew","bleat","nibble","bark"]
	var missing:=PackedStringArray()
	for hit in re.search_all(block):
		var act:=hit.get_string(1)
		if act in not_people:continue
		var spec:Array=Acting.ACT_MAP.get(act,[])
		if spec.is_empty() and not Acting.has_clip(act):missing.append(act);continue
		if not spec.is_empty() and String(spec[0])=="clip":
			var clip:=String(spec[1])
			for c in ([clip+"l",clip+"r"] if clip.ends_with("_") else [clip]):
				if not Acting.has_clip(c):missing.append("%s->%s" % [act,c])
		if not spec.is_empty() and String(spec[0])=="gesture" and not Acting.GESTURES.has(String(spec[1])):missing.append("%s->%s" % [act,spec[1]])
	assert_array(Array(missing)).override_failure_message("no performance for: %s" % ", ".join(missing)).is_empty()


func test_the_new_gestures_move_the_head_and_end()->void:
	for g in ["nod_slow","look_round","deflate","lean_in","nod_proud","jerk_head","nod_on"]:
		var f:=_figure()
		var a=Acting.of(f)
		Acting.set_ambient(f,0.0)
		_run(f,0.4)
		var yaw0:=_head_yaw(f);var pitch0:=_head_pitch(f)
		Acting.gesture(f,g,1.0,1.0)
		var moved:=0.0
		for i in int(1.0/DT):
			_frame(f,a)
			moved=maxf(moved,absf(_head_yaw(f)-yaw0)+absf(_head_pitch(f)-pitch0))
		assert_float(moved).override_failure_message("%s did not move the head" % g).is_greater(2.0)
		_run(f,2.5)
		assert_int(a._g).override_failure_message("%s never ended" % g).is_equal(-1)


func test_a_catch_meets_the_fall_where_it_is()->void:
	var faller:=_figure("stand","female_adult")
	var catcher:=_figure()
	catcher.position=Vector3(0.75,0.0,0.0)   # she is on his right
	var fa=Acting.of(faller);var ca=Acting.of(catcher)
	Acting.play(faller,"faint_l")
	for i in 6:_frame(faller,fa);_frame(catcher,ca)
	Acting.service().play(catcher,"half_catch",{"beat":"half_catch","at":"","fallback":""})
	# without a cast key there is nobody to catch: the catch plays alone
	assert_str(String(ca._a.clip)).starts_with("half_catch")
	ca.catch(faller)
	assert_str(String(fa._a.clip)).starts_with("faint_caught_")
	assert_float(absf(ca._a.t-fa._a.t)).is_less(0.05)


func test_a_child_does_the_words_its_own_way()->void:
	var c:=_figure("stand","child")
	var a=Acting.of(c)
	for pair in [["wave","child_wave"],["giggle","child_giggle"],["copy","child_copy_bow"],["shushed","child_shushed"],
			["freeze","child_shushed"],["fidget","child_fidget"],["sit_down","sit_cross"],["run_to","child_run"]]:
		Acting.perform(c,{"beat":pair[0]})
		_frame(c,a)
		assert_str(String(a._a.clip) if a._a!=null else "").override_failure_message("a child's %s is not %s" % pair).is_equal(String(pair[1]))
	Acting.play(c,"hide_behind_l")
	assert_str(String(a._a.clip)).is_equal("child_hide_behind_l")
	Acting.play(c,"peek_out_r")
	assert_str(String(a._a.clip)).is_equal("child_peek_out_r")
	# a grown-up asked for a child's clip plays the grown-up's; the same words, the grown-up's way
	var g:=_figure()
	var ga=Acting.of(g)
	Acting.play(g,"child_wave")
	assert_str(String(ga._a.clip)).is_equal("wave")
	Acting.perform(g,{"beat":"giggle"})
	assert_str(String(ga._a.clip)).is_equal("laugh_stifled")
	# the child fidgets for life; a grown-up asked to fidget keeps its own stance
	Acting.idle(c,"fidget")
	assert_str(String(a.base_stance)).is_equal("fidget")
	Acting.idle(g,"fidget")
	assert_str(String(ga.base_stance)).is_empty()
	_run(c,1.0);_run(g,1.0)
	assert_float(float(Acting.clip_meta("child_run").get("speed_mps",0.0))).is_greater(1.0)


func test_a_child_hides_and_waves_without_leaving_the_floor()->void:
	for clip in ["child_hide_behind_l","child_copy_bow","child_wave","child_giggle","child_shushed","child_cling_r","child_fidget"]:
		var c:=_figure("stand","child")
		var a=Acting.of(c)
		_run(c,0.3)
		Acting.play(c,clip)
		var lowest:=10.0;var highest:=-10.0
		for i in int(minf(Acting.clip_length(clip),3.0)/DT):
			_frame(c,a)
			for bone in ["foot.L","foot.R","toe.L","toe.R"]:
				lowest=minf(lowest,_bone_y(c,bone));highest=maxf(highest,_bone_y(c,bone))
		assert_float(lowest).override_failure_message("%s: a foot %.3f m into the floor" % [clip,-lowest]).is_greater(-0.02)
		assert_float(highest).override_failure_message("%s: a foot %.3f m up" % [clip,highest]).is_less(0.25)


func test_sitting_cross_legged_is_on_the_floor_not_in_it()->void:
	for variant in ["male_adult","female_old","child"]:
		var f:=_figure("stand",variant)
		var a=Acting.of(f)
		_run(f,0.3)
		Acting.play(f,"sit_cross")
		var lowest:=10.0
		for i in int(1.8/DT):
			_frame(f,a)
			for bone in ["foot.L","foot.R","shin.L","shin.R","toe.L","toe.R"]:lowest=minf(lowest,_bone_y(f,bone))
		var k:float=f.body_height/1.72
		assert_float(lowest).override_failure_message("%s: a foot %.3f m into the floor" % [variant,-lowest]).is_greater(-0.02)
		assert_float(_bone_y(f,"hips")).override_failure_message("%s not down on the floor" % variant).is_less(0.32*k)
		assert_float(_bone_y(f,"hips")).override_failure_message("%s sat through the floor" % variant).is_greater(0.04)
		# and kept for life: the seat stays down
		Acting.idle(f,"cross")
		assert_str(String(a.base_stance)).is_equal("cross")
		_run(f,2.0)
		assert_float(_bone_y(f,"hips")).is_less(0.32*k)


func test_a_right_hand_twin_is_its_left_in_a_mirror()->void:
	## The file keeps only the left of a mirrored pair; the game makes the right.
	for pair in [["hide_behind_l","hide_behind_r"],["point_l","point_r"],["whisper_l","whisper_r"]]:
		assert_str(String(Acting.clip_meta(pair[1]).get("mirror_of",""))).is_equal(String(pair[0]))
		assert_object(Acting.library("male_adult").get(pair[1])).is_not_null()
		var lf:=_figure();var rf:=_figure()
		Acting.set_ambient(lf,0.0);Acting.set_ambient(rf,0.0)
		var la=Acting.of(lf);var ra=Acting.of(rf)
		Acting.play(lf,String(pair[0]));Acting.play(rf,String(pair[1]))
		for i in int(0.9/DT):_frame(lf,la);_frame(rf,ra)
		for bone in ["upper_arm","forearm","hand"]:
			var ql:Quaternion=lf.skeleton.get_bone_pose_rotation(lf.skeleton.find_bone(bone+".L"))
			var qr:Quaternion=rf.skeleton.get_bone_pose_rotation(rf.skeleton.find_bone(bone+".R"))
			var off:=rad_to_deg(Quaternion(ql.x,-ql.y,-ql.z,ql.w).angle_to(qr))
			assert_float(off).override_failure_message("%s %s is %.1f deg off its mirror" % [pair[1],bone,off]).is_less(6.0)


# --- executions (court_night/EXECUTIONS.md): slapstick timed to the frame ---------------

func _adults()->Array:
	var out:=[]
	for v in Figure3D.VARIANTS:
		if String(v)!="child":out.append(String(v))
	return out


func _place(f:Node3D,role:Dictionary)->void:
	var at:Array=role.get("at",[0.0,0.0,0.0])
	f.position=Vector3(float(at[0]),float(at[1]),float(at[2]))
	f.rotation_degrees.y=float(role.get("yaw",0.0))


func _head_middle(f:Node3D)->Vector3:
	var p:Transform3D=f.skeleton.global_transform*f.skeleton.get_bone_global_pose(f.skeleton.find_bone("head"))
	return p.origin+p.basis.y.normalized()*0.11*f.body_height/1.72


func test_every_execution_is_clips_every_adult_body_has()->void:
	for act:String in Acting.EXEC_PLANS:
		var plan:Dictionary=Acting.exec_plan(act)
		var roles:Dictionary=plan.roles
		assert_bool(roles.has("victim")).is_true()
		for role:String in roles:
			var r:Dictionary=roles[role]
			var clips:=[]
			if r.has("clip"):clips.append(String(r.clip))
			for c:Dictionary in r.get("clips",[]):clips.append(String(c.clip))
			for clip:String in clips:
				assert_bool(Acting.has_clip(clip)).override_failure_message("%s: no clip %s" % [act,clip]).is_true()
				assert_float(Acting.clip_length(clip)).is_less_equal(float(plan.length)+0.01)
				for v in _adults():
					assert_bool(Acting.library(v).has(clip)).override_failure_message("%s has no %s" % [v,clip]).is_true()
				# no gore is ever acted on a child: the child's body has none of it
				assert_bool(Acting.library("child").has(clip)).override_failure_message("the child has %s" % clip).is_false()
		# a part that flies or rolls leaves the victim's body at that moment
		for part:Dictionary in plan.parts:
			var victim:=String(roles.victim.get("clip",""))
			var split:=false
			for e:Dictionary in Acting.events(victim):
				if String(e.name)=="split" and String(e.get("part",""))==String(part.part) and absf(float(e.t)-float(part.t0))<0.05:split=true
			assert_bool(split).override_failure_message("%s: %s never splits off at %.2f" % [act,part.part,part.t0]).is_true()
	for clip in ["room_wipe_face","room_vomit","room_cover_eyes_peek","room_applaud_alone","room_flinch_splash","room_wince_crunch"]:
		assert_bool(Acting.has_clip(clip)).is_true()
		assert_bool(Acting.library("male_old").has(clip)).is_true()


func test_the_club_meets_the_head_on_the_crack()->void:
	var plan:=Acting.exec_plan("club_home_run")
	var victim:=_figure("stand","male_adult");var batter:=_figure("stand","male_young")
	_place(victim,plan.roles.victim);_place(batter,plan.roles.executioner)
	var va=Acting.of(victim);var ba=Acting.of(batter)
	var club:Node3D=auto_free(Node3D.new());add_child(club)
	Acting.hold(batter,club,"R")
	var heard:=[]
	ba.cue.connect(func(_f,e):heard.append(String(e.name)))
	Acting.play(victim,"exec_club_victim",{"blend":0.05});Acting.play(batter,"exec_club_batter",{"blend":0.05})
	for i in int(round(3.62/DT)):
		_frame(victim,va);_frame(batter,ba)
	var head:=_head_middle(victim)
	var sweet:=club.global_transform*Vector3(0.0,0.70,0.0)
	assert_float(sweet.distance_to(head)).override_failure_message("the club's head is %.2f m from the victim's head at the crack" % sweet.distance_to(head)).is_less(0.25)
	for want in ["tap","call_shot","kick","impact"]:
		assert_bool(want in heard).override_failure_message("no %s cue (%s)" % [want,heard]).is_true()
	assert_int(heard.find("tap")).is_less(heard.find("impact"))
	# the follow-through carries the club round over the left shoulder, high
	for i in int(0.3/DT):
		_frame(victim,va);_frame(batter,ba)
	assert_float((club.global_transform*Vector3(0.0,0.70,0.0)).y).is_greater(1.6)


func test_the_axe_sticks_bounces_and_lands_on_the_neck()->void:
	var plan:=Acting.exec_plan("three_swing_beheading")
	var victim:=_figure("stand","female_adult");var man:=_figure("stand","male_adult")
	_place(victim,plan.roles.victim);_place(man,plan.roles.executioner)
	var va=Acting.of(victim);var ma=Acting.of(man)
	var axe:Node3D=auto_free(Node3D.new());add_child(axe)
	Acting.hold(man,axe,"R")
	Acting.play(victim,"exec_block_victim",{"blend":0.05});Acting.play(man,"exec_axe_headsman",{"blend":0.05})
	var block:Dictionary=plan.things.block
	var top:=Vector3(float(block.at[0]),float(block.top),float(block.at[2]))
	var t:=0.0
	var blade_at:={}
	for moment in [1.95,5.5,8.7]:
		while t<moment-0.001:
			_frame(victim,va);_frame(man,ma);t+=DT
		blade_at[moment]=axe.global_transform*Vector3(0.0,0.66,0.07)
	var neck:Vector3=victim.skeleton.global_transform*victim.skeleton.get_bone_global_pose(victim.skeleton.find_bone("neck")).origin
	# the first sticks in the block, short of the neck; the second and third land on the neck
	assert_float((blade_at[1.95] as Vector3).distance_to(top)).override_failure_message("swing one lands %.2f m from the block" % (blade_at[1.95] as Vector3).distance_to(top)).is_less(0.30)
	assert_float((blade_at[8.7] as Vector3).distance_to(neck)).override_failure_message("the last swing lands %.2f m from the neck" % (blade_at[8.7] as Vector3).distance_to(neck)).is_less(0.25)
	assert_float(neck.y).is_between(float(block.top)-0.05,float(block.top)+0.20)


func test_the_cook_lids_the_pot_and_lets_go()->void:
	var cook:=_figure()
	var ca=Acting.of(cook)
	var lid:Node3D=auto_free(Node3D.new());add_child(lid)
	lid.global_position=Vector3(0.3,0.03,0.3)
	Acting.hold(cook,lid,"L")
	Acting.play(cook,"exec_cook_lid",{"blend":0.05})
	var t:=0.0
	while t<7.0:
		_frame(cook,ca);t+=DT
	assert_vector(lid.global_position).is_equal(Vector3(0.3,0.03,0.3))
	while t<7.65:
		_frame(cook,ca);t+=DT
	var put:=lid.global_position
	assert_float(put.y).is_between(0.45,0.85)
	while t<8.5:
		_frame(cook,ca);t+=DT
	assert_vector(lid.global_position).is_equal(put)


func test_parts_fly_and_roll_to_where_the_plan_says()->void:
	var arc:Dictionary=(Acting.exec_plan("club_home_run").parts as Array)[0]
	var from:=Vector3(0.0,1.2,0.0);var to:=Vector3(3.4,0.6,0.8)
	assert_vector(Acting.part_at(arc,from,to,float(arc.t0)).origin).is_equal_approx(from,Vector3.ONE*0.01)
	assert_vector(Acting.part_at(arc,from,to,float(arc.t1)).origin).is_equal_approx(to,Vector3.ONE*0.01)
	assert_float(Acting.part_at(arc,from,to,(float(arc.t0)+float(arc.t1))*0.5).origin.y).is_greater(2.0)
	var roll:Dictionary=(Acting.exec_plan("three_swing_beheading").parts as Array)[0]
	var end:=Acting.part_at(roll,Vector3(0,0.58,0.4),Vector3(0,0.11,1.9),float(roll.t1),Vector3(0,0,1))
	# at rest upright, its face (+Z) toward the god
	assert_float(end.basis.y.normalized().dot(Vector3.UP)).is_greater(0.95)
	assert_float(end.basis.z.normalized().dot(Vector3(0,0,1))).is_greater(0.95)


func test_a_child_covers_its_eyes_its_own_way()->void:
	var c:=_figure("stand","child")
	var a=Acting.of(c)
	Acting.perform(c,{"beat":"cover_eyes_peek"})
	_frame(c,a)
	assert_str(String(a._a.clip)).is_equal("child_cover_eyes_peek")
	var g:=_figure()
	var ga=Acting.of(g)
	Acting.perform(g,{"beat":"cover_eyes_peek"})
	assert_str(String(ga._a.clip)).is_equal("room_cover_eyes_peek")
