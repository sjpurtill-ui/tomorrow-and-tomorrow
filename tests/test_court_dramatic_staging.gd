extends GdUnitTestSuite
const Stage:=preload("res://scripts/hud/court_stage.gd")
const Director:=preload("res://scripts/hud/court_director.gd")
const Camera:=preload("res://scripts/hud/court_camera.gd")
const Motion:=preload("res://scripts/hud/motion.gd")
const Fixtures:=preload("res://tests/test_court_director.gd")
var saved:Array

class Body extends Node3D:
	var mood:="neutral"
	var height:=1.7
	func head_top()->Vector3:return global_position+Vector3.UP*height
	func set_mood(value:String)->void:mood=value

class Room extends Node3D:
	var effects:Array=[]
	func animal(_kind:String)->Node3D:return null
	func god_light(target:Node3D,tone:String,_hold:float,_amount:=1.0)->void:effects.append([target,tone])
	func god_moment(target:Node3D,tone:String,_hold:float)->void:effects.append([target,tone])

class Rig extends Node:
	var calls:Array=[]
	func set_insets(_a:float,_b:float,_c:float,_d:float)->void:pass
	func address(body:Node3D,_seconds:float,whole:bool)->void:calls.append(["address",body,whole])
	func push_in(body:Node3D,_seconds:float)->void:calls.append(["push_in",body])
	func reaction(body:Node3D,_seconds:float)->void:calls.append(["reaction",body])
	func shake(_strength:float)->void:calls.append(["shake"])
	func wide(_cast:Array,_seconds:float,_lead:Variant=null)->void:calls.append(["wide"])

func before_test()->void:
	saved=[Stage.director,Stage.acting,Stage.sound,Motion.reduce_motion]
	Stage.director=null;Stage.acting=null;Stage.sound=null;Motion.reduce_motion=false

func after_test()->void:
	Stage.director=saved[0];Stage.acting=saved[1];Stage.sound=saved[2];Motion.reduce_motion=saved[3]

func _stage()->Stage:
	var s:Stage=auto_free(Stage.new());add_child(s)
	s.court_set=Room.new();s.view3d.add_child(s.court_set)
	s.rig=Rig.new();s.view3d.add_child(s.rig)
	for key:String in ["main","official"]:
		var f:=Stage.Figure.new();s.figure_layer.add_child(f)
		var body:=Body.new();s.view3d.add_child(body)
		f.body3d=body;f.spot=body;f.role=key;f.person={"name":key}
		s.figures[key]=f;s.cast_order.append(key)
	return s

func _shots(beats:Array)->Array:
	var out:Array=[]
	for beat:Dictionary in beats:
		if beat.who!="camera" or not bool(beat.args.get("dramatic",false)):continue
		var copy:Dictionary=beat.duplicate(true)
		if copy.act!="shot":copy.args["name"]=copy.act
		out.append(copy)
	return out

func test_address_and_favour_have_one_move_then_a_readable_hold()->void:
	for event:Dictionary in [{"kind":"god","seconds":3.0},{"kind":"divine","action":"bless","target":"main","response":"blessed","witnesses":{"p1":"envy"}}]:
		var beats:=Director.beats_for(event,Fixtures.home_cast(),Fixtures.full_facts(100),24)
		var shots:=_shots(beats)
		assert_int(shots.size()).is_equal(2)
		if shots.size()!=2:continue
		assert_str(shots[0].args.name).is_equal("push_in")
		assert_str(shots[1].args.name).is_equal("wide")
		assert_float(float(shots[0].t)).is_greater(0.1)
		assert_float(float(shots[1].t)-float(shots[0].t)-float(shots[0].args.seconds)).is_greater(1.4)
		if event.kind=="divine":
			assert_bool(beats.any(func(b:Dictionary)->bool:return b.who=="p1" and b.act=="side_eye")).is_true()

func test_terror_keeps_full_response_and_defiance_authoritative()->void:
	for response:String in ["cower","defy"]:
		var beats:=Director.beats_for({"kind":"divine","action":"terrify","target":"main","response":response},Fixtures.home_cast(),Fixtures.full_facts(100),31)
		var shots:=_shots(beats)
		assert_bool(shots.is_empty()).is_false()
		if shots.is_empty():continue
		assert_bool(shots[0].args.whole).is_equal(response=="cower")
		var kneels:=beats.filter(func(b:Dictionary)->bool:return b.who=="main" and b.act=="kneel")
		if response=="cower":
			assert_int(kneels.size()).is_equal(1)
			if kneels.is_empty():continue
			assert_float(float(kneels[0].t)).is_equal_approx(2.05,0.001)
			assert_float(float(shots[-1].t)).is_greater(float(kneels[0].t)+2.5)
		else:
			assert_int(kneels.size()).is_equal(0)
			assert_bool(beats.any(func(b:Dictionary)->bool:return b.who=="main" and b.act=="stand_firm" and is_equal_approx(float(b.t),0.55))).is_true()

func test_named_missing_leaving_or_freed_target_never_uses_main_or_claims_camera()->void:
	var s:=_stage()
	assert_object(s._addressed({})).is_same(s.figure("main").body3d)
	for state:String in ["missing","leaving","hidden","freed"]:
		var key:="absent" if state=="missing" else "official"
		if state=="leaving":s.figure(key).leaving=true
		if state=="hidden":s.figure(key).leaving=false;s.figure(key).body3d.visible=false
		if state=="freed":s.figure(key).body3d.free()
		assert_object(s._addressed({"target":key})).is_null()
		s._set_answers("divine",{"action":"bless","target":key})
		s.shot("push_in",{"target":key,"weight":4,"dramatic":true})
		assert_int(s.rig.calls.size()).is_equal(0)
		assert_float(s._shot_until).is_equal(0.0)
	assert_int(s.court_set.effects.size()).is_equal(0)

func test_new_speech_or_close_expires_only_cosmetic_camera_callbacks()->void:
	var s:=_stage()
	for kind:String in ["line","close","divine","execution"]:
		s._staging_epoch+=1
		var old:={"dramatic":true,"staging_epoch":s._staging_epoch,"subject":"main","target":"main","weight":4,"until":s._now()+8.0}
		s.shot("push_in",old)
		s.event(kind,{"who":"official","method":"club"})
		var count:int=s.rig.calls.size()
		s.shot("wide",old);s.shot("shake",old)
		assert_int(s.rig.calls.size()).is_equal(count)
		# A physical callback from the same earlier timeline is still played.
		s._beat({"who":"main","act":"mood","args":{"name":"dread","hold":true}})
		assert_str(s.figure("main").own_mood).is_equal("dread")

func test_queued_camera_weight_does_not_change_with_later_event()->void:
	var s:=_stage();Stage.director=Director.new()
	s.event("divine",{"action":"bless","target":"main","response":"blessed"})
	var shots:=_shots(s._last_beats)
	assert_int(shots.size()).is_equal(2)
	s._event_weight=1;s._event_end=0.0
	for beat:Dictionary in shots:
		assert_int(int(beat.args.weight)).is_equal(4)
		assert_float(float(beat.args.until)).is_greater(s._now()+3.0)

func test_execution_blocks_presence_move_return_and_shake_for_all_retained_methods()->void:
	var s:=_stage()
	for method:String in ["club","fire","dogs","behead"]:
		s.exec_method=method;s._exec=Node.new();s.add_child(s._exec)
		var before:int=s.rig.calls.size()
		for name:String in ["push_in","wide","shake"]:
			s.shot(name,{"target":"main","dramatic":true,"weight":4})
		assert_int(s.rig.calls.size()).is_equal(before)
		s.shot("wide",{"weight":5})
		assert_int(s.rig.calls.size()).is_equal(before+1)
		s._exec.free();s._exec=null

func test_dramatic_hold_is_not_interrupted_by_ambient_reaction_shots()->void:
	var s:=_stage()
	s.shot("push_in",{"target":"main","dramatic":true,"weight":4,"until":s._now()+5.0})
	s.shot("reaction",{"target":"official","weight":4})
	assert_int(s.rig.calls.size()).is_equal(1)
	s.shot("wide",{"dramatic":true,"weight":4})
	assert_int(s.rig.calls.size()).is_equal(2)

func test_address_framing_holds_still_and_respects_insets_and_reduced_motion()->void:
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(1280,720);viewport.own_world_3d=true;add_child(viewport)
	var camera:=Camera.new();viewport.add_child(camera);camera.set_process(false)
	var body:=Body.new();viewport.add_child(body)
	camera.set_insets(65,45,10,240)
	for height:float in [1.18,1.7]:
		body.height=height
		camera.address(body,0.8,true)
		camera._process(0.8)
		assert_bool(camera.is_moving()).is_false()
		var held:=camera.transform
		camera._process(1.0)
		assert_bool(held.is_equal_approx(camera.transform)).is_true()
		assert_float(rad_to_deg(camera.rotation.y)).is_equal_approx(camera.base_yaw,0.001)
		for p:Vector3 in [body.head_top()+Vector3.UP*.12,body.position-Vector3.UP*.1]:
			var pixel:=camera.unproject_position(p)
			assert_float(pixel.x).is_between(10.0,1040.0)
			assert_float(pixel.y).is_between(65.0,675.0)
	camera.shake(0.5)
	assert_bool(camera.is_moving()).is_true()
	Motion.reduce_motion=true
	camera.address(body,1.2,false);camera.shake(0.5)
	assert_bool(camera.is_moving()).is_false()
	assert_float(camera._trauma).is_equal(0.0)
	assert_bool(camera.transform.is_finite()).is_true()

func test_named_god_address_uses_the_same_subject_as_the_light()->void:
	for key:String in ["p1","missing"]:
		var shots:=_shots(Director.beats_for({"kind":"god","target":key},Fixtures.home_cast(),Fixtures.full_facts(100),8))
		assert_int(shots.size()).is_equal(2 if key=="p1" else 0)
		if not shots.is_empty():assert_str(shots[0].args.target).is_equal(key)

func test_every_presence_camera_callback_expires_after_speech()->void:
	var s:=_stage();Stage.director=Director.new()
	s.event("divine",{"action":"terrify","target":"main","response":"defy"})
	var shots:Array=s._last_beats.filter(func(b:Dictionary)->bool:return b.act=="shot")
	assert_bool(shots.is_empty()).is_false()
	s.event("line",{"who":"official","text":"We have heard."})
	var count:int=s.rig.calls.size()
	for beat:Dictionary in shots:
		assert_bool(beat.args.has("staging_epoch")).is_true()
		s._beat(beat)
	assert_int(s.rig.calls.size()).is_equal(count)

func test_subject_freed_before_deferred_presence_cannot_claim_release_or_shake()->void:
	var s:=_stage();Stage.director=Director.new()
	s.event("divine",{"action":"terrify","target":"official","response":"cower"})
	var pending:=_shots(s._last_beats)
	assert_int(pending.size()).is_equal(3)
	s.figure("official").body3d.free()
	for beat:Dictionary in pending:s._beat(beat)
	assert_int(s.rig.calls.size()).is_equal(0)
	assert_float(s._shot_until).is_equal(0.0)
