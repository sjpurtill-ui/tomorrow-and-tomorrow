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
const CORE:=["gasp","flinch","laugh","laugh_stifled","side_eye_l","side_eye_r","bow_shallow","bow_deep","bow_overdeep","kneel","defiant",
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
	# the hands travel from the bow to the folded arms, never jumping: under 3 m/s
	assert_float(fastest).is_less(3.0)


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
