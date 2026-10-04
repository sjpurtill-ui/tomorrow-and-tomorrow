extends GdUnitTestSuite
const Figure=preload("res://scripts/hud/court_figure_3d.gd")
const Stage=preload("res://scripts/hud/court_stage.gd")
const Acting=preload("res://scripts/hud/court_acting.gd")
const Director=preload("res://scripts/hud/court_director.gd")
var previous:Array

func before_test()->void:
	previous=[Stage.acting,Stage.director,Stage.sound]
	Stage.acting=Acting.service();Stage.director=Director.new();Stage.sound=null

func after_test()->void:
	Stage.acting=previous[0];Stage.director=previous[1];Stage.sound=previous[2]

func _body()->Figure:
	var f:Figure=auto_free(Figure.new());add_child(f)
	f.setup({"variant":"male_adult","outfit":"business"})
	f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	Acting.of(f).set_process(false)
	return f

func _stage()->Stage:
	var s:Stage=auto_free(Stage.new());add_child(s);s.size=Vector2(1200,700)
	s._clock=s.create_tween();s._clock.tween_interval(100.0);s._clock.pause()
	for i in 3:
		var key:="p%d" % i
		var f:=Stage.Figure.new();s.figure_layer.add_child(f)
		var body:=Figure.new();s.view3d.add_child(body)
		body.setup({"variant":"male_adult","outfit":"business"})
		body.position=Vector3(i*1.5,0,0)
		body.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		Acting.of(body).set_process(false)
		f.body3d=body;f._stage=weakref(s);f.person={"name":key};f.role="court"
		s.figures[key]=f;s.cast_order.append(key)
	return s

func _advance(a:Node,seconds:float)->void:
	for i in ceili(seconds/0.02):
		var dt:=minf(0.02,seconds-i*0.02)
		a.skel.reset_bone_poses();a.fig.player.advance(dt);a._step(dt)

func test_director_looks_carry_their_lifetime()->void:
	var beats:=Director.lower([{"t":0.0,"who":"p0","act":"exchange_look","args":{"at":"p1","dur":0.4}}])
	var gaze:Dictionary=beats.filter(func(b:Dictionary)->bool:return b.act=="look_at")[0]
	assert_float(float(gaze.args.get("dur",-1.0))).is_equal(0.4)

func test_temporary_look_expires_and_freed_target_releases()->void:
	var f:=_body();var a=Acting.of(f)
	Stage.acting.look_at(f,{"target":Vector3(2,1,3),"dur":0.2},null)
	_advance(a,0.24)
	assert_int(a._look_kind).is_equal(0)
	var other:=Node3D.new();add_child(other)
	Stage.acting.look_at(f,{"target":other,"dur":5.0},null)
	other.visible=false;_advance(a,0.02)
	assert_int(a._look_kind).is_equal(0)
	other.visible=true
	Stage.acting.look_at(f,{"target":other,"dur":5.0},null)
	other.free();_advance(a,0.02)
	assert_int(a._look_kind).is_equal(0)

func test_expiring_old_look_does_not_clear_a_newer_look()->void:
	var f:=_body();var a=Acting.of(f)
	Stage.acting.look_at(f,{"target":Vector3(2,1,3),"dur":0.2},null)
	_advance(a,0.1)
	Stage.acting.look_at(f,{"target":Vector3(-2,1,3),"dur":0.6},null)
	_advance(a,0.15)
	assert_int(a._look_kind).is_equal(1)
	assert_vector(a._look_point).is_equal(Vector3(-2,1,3))
	_advance(a,0.5)
	assert_int(a._look_kind).is_equal(0)

func test_new_speaker_supersedes_a_temporary_exchange_and_tracks_the_speaker()->void:
	var s:=_stage();var listener=s.figure("p1");var a=Acting.of(listener.body3d)
	Stage.acting.look_at(listener.body3d,{"target":Vector3(-5,2,0),"dur":5.0},s)
	listener.listen_to(s.figure("p0"))
	assert_int(a._look_kind).is_equal(0)
	assert_object(a.get("_attention_target")).is_same(s.figure("p0").body3d)

func test_listener_turns_are_staggered_and_old_speaker_callbacks_cancel()->void:
	var s:=_stage();s._turn_to("p0",3.0)
	assert_bool(s.figure("p1").body3d._gaze_on).is_false()
	var pending:Tween=s.get("_attention_tween")
	assert_object(pending).is_not_null()
	if pending==null:return
	pending.pause();pending.custom_step(0.7)
	assert_object(Acting.of(s.figure("p1").body3d).get("_attention_target")).is_same(s.figure("p0").body3d)
	s._turn_to("p2",3.0)
	var fresh:Tween=s.get("_attention_tween");fresh.pause();fresh.custom_step(0.7)
	assert_bool(pending.is_valid()).is_false()
	assert_object(Acting.of(s.figure("p1").body3d).get("_attention_target")).is_same(s.figure("p2").body3d)

func test_stale_director_look_cannot_steal_a_new_speakers_attention()->void:
	var s:=_stage();s._turn_to("p0",3.0)
	var epoch:int=s.get("_attention_epoch")
	s._turn_to("p2",3.0)
	var pending:Tween=s.get("_attention_tween");pending.pause();pending.custom_step(0.7)
	s._beat({"attention_epoch":epoch,"who":"p1","act":"look_at","args":{"target":"away","dur":4.0}})
	assert_int(Acting.of(s.figure("p1").body3d)._look_kind).is_equal(0)

func test_live_god_focus_does_not_duplicate_the_standalone_directors_ripple()->void:
	var cast:=[{"key":"p0","role":"main"},{"key":"p1","role":"court"},{"key":"p2","role":"court"}]
	var standalone:=Director.beats_for({"kind":"god_speaks"},cast,{},17,{})
	var staged:=Director.beats_for({"kind":"god_speaks","attention_staged":true},cast,{},17,{})
	assert_bool(standalone.any(func(b:Dictionary)->bool:return b.act=="look_up")).is_true()
	assert_bool(staged.any(func(b:Dictionary)->bool:return b.act=="look_up")).is_false()
	var other:=standalone.filter(func(b:Dictionary)->bool:return b.act!="look_up")
	assert_str(var_to_str(staged)).is_equal(var_to_str(other))

func test_conversation_focus_expires_returns_from_glances_and_preserves_protected_acts()->void:
	var s:=_stage();var f=s.figure("p1");var a=Acting.of(f.body3d)
	f.listen_to(s.figure("p0"),1.0)
	Stage.acting.look_at(f.body3d,{"target":Vector3(3,1,3),"dur":0.2},s)
	_advance(a,0.24)
	assert_int(a._look_kind).is_equal(0)
	assert_object(a.get("_attention_target")).is_same(s.figure("p0").body3d)
	_advance(a,0.8)
	assert_object(a.get("_attention_target")).is_null()
	for clip:String in ["kneel","storm_walk","exec_club_batter","stance_bundle"]:
		a.act(clip,{"hold":true});var layer=a._a
		f.listen_to(s.figure("p2"));f.look_up();f.speak(2.0)
		assert_object(a._a).is_same(layer)
		assert_object(a.get("_attention_target")).is_null()

func test_overlapping_hush_does_not_release_the_longer_hold()->void:
	var s:=_stage();var a=Acting.of(s.figure("p0").body3d)
	s.hush(4.0);s._clock.custom_step(0.5);s.hush(0.4)
	s._hush_tween.pause();s._hush_tween.custom_step(0.5)
	assert_bool(a.hushed).is_true()
	s._clock.custom_step(3.6);s._hush_tween.custom_step(4.0)
	assert_bool(a.hushed).is_false()

func test_ambient_cannot_replace_speech_kneel_walk_exit_or_execution()->void:
	var s:=_stage();var f=s.figure("p0");var a=Acting.of(f.body3d)
	var idle:={"who":"p0","act":"scratch","args":{}}
	for clip:String in ["kneel","walk_sober","storm_walk","exec_club_batter","stance_bundle"]:
		a.act(clip,{"hold":true});var layer=a._a
		s._ambient_beat(idle)
		assert_object(a._a).override_failure_message("ambient replaced "+clip).is_same(layer)
	a._a=null;a._b=null;a.talk("Here is the report.",3.0)
	s._ambient_beat(idle)
	assert_object(a._a).is_null()

func test_hush_reschedules_overdue_ambient_instead_of_a_catchup_burst()->void:
	var s:=_stage()
	s._ambient=[{"who":"p0","act":"scratch","args":{},"every":[8.0,14.0],"next":0.0},
		{"who":"p1","act":"scratch","args":{},"every":[8.0,14.0],"next":0.0}]
	s.hush(4.0)
	for item:Dictionary in s._ambient:assert_float(float(item.next)).is_greater(4.0)
	assert_float(float(s._ambient[0].next)).is_not_equal(float(s._ambient[1].next))

func test_pre_tree_attention_keeps_only_the_latest_request()->void:
	var s:Stage=auto_free(Stage.new())
	s._focus_conversation("god",3.0)
	s._focus_conversation("main",2.0)
	assert_int(s._attention_epoch).is_equal(2)
	add_child(s)
	await await_idle_frame()
	await await_idle_frame()
	assert_int(s._attention_epoch).is_equal(3)
