extends GdUnitTestSuite
## Actual modal order and menu routes, with the engine's nonfatal judgment.
const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Persons:=preload("res://scripts/court_persons.gd")
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")
const Executions:=preload("res://scripts/hud/court_executions.gd")
const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Voice:=preload("res://scripts/character_voice.gd")
var _root_size:=Vector2i.ZERO
var _civ:=""


func before_test()->void:
	var info:Dictionary=Fixtures.new(self).base(false)
	_civ=String(info.civ_id)
	Stage.directing=true;Stage.director=null;Stage.acting=null;Stage.use_sets=true
	Backdrop.tier_override=-1;Backdrop.Stages.stage_override="";Voice.knowledge_override.clear()
	GameState.known_discoveries.assign(["temple_high_steward","pictographic_records","plain_weaving"])
	GameState.elapsed_days=600*365
	Executions.gore="full";Executions.last_used=""
	_root_size=get_tree().root.size;get_tree().root.size=Vector2i(1920,1080)


func after_test()->void:
	Backdrop.tier_override=-1;Backdrop.Stages.stage_override="";Voice.knowledge_override.clear()
	Stage.director=null;Stage.acting=null;Executions.gore="full"
	get_tree().root.size=_root_size


func _open(id:String)->Control:
	assert_str(id).is_not_empty()
	var modal:Control=auto_free(Modal.new())
	modal.audience_id=id;add_child(modal)
	for index in 4:await await_idle_frame()
	modal.skip_reveal();await await_idle_frame();modal.court_stage.settle()
	assert_object(modal.court_stage.court_set).is_not_null()
	assert_str(String(modal.court_stage.court_set.kind)).is_equal("chapter_03")
	return modal


func _marshal()->Control:
	var marshal:Dictionary=GovernmentPeopleSystem.officeholder("Marshal")
	return await _open(String(Hall.summon({"person_id":int(marshal.person_id)}).get("id","")))


func _type(modal:Control,words:String)->void:
	modal.speech_input.text=words
	modal._speak()


func test_typed_flogging_stages_actual_victim_once_and_skip_keeps_them_alive()->void:
	var modal:Control=await _marshal()
	var stage:Control=modal.court_stage
	var victim:Variant=stage.figure(Stage.MAIN)
	var population:=float(GameState.population_exact)
	stage.say(Stage.MAIN,"These are my old words.",false,false)
	_type(modal,"Flog him.")
	assert_bool(stage.beating()).is_true()
	if not stage.beating():return
	assert_int(modal._beating_results.size()).is_equal(1)
	var result:Dictionary=modal._beating_results[0]
	assert_bool(bool(result.executed)).is_true()
	assert_str(String(result.harm)).is_equal("beat")
	assert_int(int(result.target.person_id)).is_equal(int(victim.person.person_id))
	assert_str(String(stage._beating.victim)).is_equal(Stage.MAIN)
	assert_bool(stage.executing()).is_false()
	assert_str(stage.exec_method).is_empty()
	assert_bool(modal._executed).is_false()
	assert_object(stage.say(Stage.MAIN,"Do not restart a talking pose.",false,false)).is_null()
	for child in stage.bubble_layer.get_children():
		if child is Stage.Bubble and String(child.speaker)==Stage.MAIN:assert_bool(child.visible and not child.dropping).is_false()
	assert_bool(modal.show_beating(result)).is_false()
	modal.advance()
	assert_bool(stage.beating()).is_false()
	assert_bool(victim.leaving).is_false()
	assert_bool(victim.body3d.visible).is_true()
	assert_float(float(GameState.population_exact)).is_equal(population)
	assert_bool(modal.show_beating(result)).is_false()


func test_envoy_wrath_menu_starts_one_beating_and_holds_nonfatal_departure()->void:
	var audience:=Hall.debug_force("news",_civ)
	var modal:Control=await _open(String(audience.id))
	var stage:Control=modal.court_stage
	var victim:Variant=stage.figure(Stage.MAIN)
	var population:=float(ForeignDiplomacy.civilization(_civ).population)
	var result:Dictionary=modal.act_on_envoy("envoy_flog")
	assert_str(String(result.get("envoy_state",""))).is_equal("beaten")
	assert_bool(stage.beating()).is_true()
	if not stage.beating():return
	assert_int(modal._beating_results.size()).is_equal(1)
	assert_str(modal._exit_style).is_equal("led")
	var lines:Array=Hall.find(modal.audience_id).lines
	modal._last_line=lines[-1];modal.rendered_lines=lines.size();modal.revealing=false
	modal._process(0.0)
	assert_bool(victim.leaving).is_false()
	assert_bool(modal._leave_when_quiet).is_true()
	stage.skip_beating()
	modal._process(0.0)
	assert_bool(victim.leaving).is_true()
	assert_bool(stage.executing()).is_false()
	assert_float(float(ForeignDiplomacy.civilization(_civ).population)).is_equal(population)


func test_failed_order_missing_actor_or_unrelated_harm_cannot_start_beating()->void:
	var modal:Control=await _marshal()
	var pid:int=modal.court_stage.figure(Stage.MAIN).person.person_id
	var result:={"executed":false,"verb":"maim","harm":"beat","target":{"person_id":pid},"actor":{}}
	assert_bool(modal.show_beating(result)).is_false()
	result.executed=true;result.harm="mutilate"
	assert_bool(modal.show_beating(result)).is_false()
	result.harm="beat";result.actor={"person_id":2147483000,"name":"Absent person"}
	assert_bool(modal.show_beating(result)).is_false()
	result.actor={};result.target={"person_id":2147483000,"name":"Absent person"}
	assert_bool(modal.show_beating(result)).is_false()
	assert_bool(modal.court_stage.beating()).is_false()


func test_gore_off_suppresses_animation_but_keeps_the_actual_nonfatal_order()->void:
	var modal:Control=await _marshal()
	Executions.gore="off"
	_type(modal,"Flog him.")
	assert_bool(modal.court_stage.beating()).is_false()
	assert_bool(modal.court_stage.executing()).is_false()
	assert_bool(modal.court_stage.figure(Stage.MAIN).body3d.visible).is_true()
	assert_str(String(Hall.find(modal.audience_id).get("status",""))).is_equal("waiting")


func test_mild_route_reaches_mild_helper_and_close_cancels_without_death()->void:
	var modal:Control=await _marshal()
	Executions.gore="mild"
	_type(modal,"Flog him.")
	var stage:Control=modal.court_stage
	assert_bool(stage.beating()).is_true()
	if not stage.beating():return
	assert_str(String(stage._beating.style)).is_equal("mild")
	var victim:Variant=stage.figure(Stage.MAIN)
	modal._close()
	assert_bool(stage.beating()).is_false()
	assert_bool(victim.body3d.visible).is_true()
	assert_bool(victim.leaving).is_false()


func test_known_person_judgment_preserves_identity_and_child_gate()->void:
	for age in [32,10]:
		var known:=Persons.create({"sex":"male","trade":"gatherer"})
		known.born_day=int(GameState.elapsed_days)-age*365
		var summoned:=Persons.summon_ref({"kind":"known","id":String(known.id)},"")
		var modal:Control=await _open(String(summoned.id))
		var stage:Control=modal.court_stage
		var victim:Variant=stage.figure(Stage.MAIN)
		assert_str(String(victim.person.known_id)).is_equal(String(known.id))
		assert_int(int(victim.person.age)).is_equal(age)
		var result:=Persons.perform(modal.audience_id,"maim",{"harm":"beat"})
		assert_bool(bool(result.ok)).is_true()
		modal._after_persons(result)
		assert_bool(stage.beating()).is_equal(age>=15)
		assert_str(String(known.status)).is_equal("living")
		assert_bool(bool(known.get("flogged",false))).is_true()
		if stage.beating():stage.skip_beating()
		modal._close()
		await await_idle_frame()


func test_unstageable_actual_order_releases_busy_state_without_hiding_victim()->void:
	var modal:Control=await _marshal()
	var stage:Control=modal.court_stage
	# No supporting adult remains in this room. The real order still stands;
	# presentation must fall back cleanly instead of holding the modal forever.
	for key:String in stage.cast_order:
		if key!=Stage.MAIN:stage.figure(key).leaving=true
	_type(modal,"Flog him.")
	assert_bool(stage.beating()).is_false()
	assert_bool(stage.executing()).is_false()
	assert_bool(stage.figure(Stage.MAIN).body3d.visible).is_true()


func test_skip_while_target_is_arriving_cancels_the_deferred_start()->void:
	var modal:Control=await _marshal()
	var stage:Control=modal.court_stage
	var victim:Variant=stage.figure(Stage.MAIN)
	victim.enter_from(-1.0,1.0,0.0)
	await await_idle_frame()
	assert_float(float(victim.arriving_in())).is_greater(0.0)
	_type(modal,"Flog him.")
	assert_bool(stage.beating()).is_true()
	if not stage.beating():return
	assert_str(String(stage._beating.get_meta("beating_state",""))).is_equal("waiting_for_arrivals")
	modal.advance()
	assert_bool(stage.beating()).is_false()
	assert_object(stage._beating_start).is_null()
	assert_bool(victim.leaving).is_false()
	await await_idle_frame()
	assert_object(stage.get_node_or_null("Beating")).is_null()


func _assert_punishment_in_frame(stage:Control)->void:
	var camera:Camera3D=stage.camera
	var view:=camera.get_viewport().get_visible_rect().size
	for key:String in stage._beating.get_meta("participant_keys",[]):
		var body:Node3D=stage.figure(key).body3d
		var points:=PackedVector3Array([body.global_position,body.call("head_top")])
		if key==Stage.MAIN:
			var floor:Vector3=stage.court_set.to_local(body.global_position)
			floor.y=0.0;floor=stage.court_set.to_global(floor)
			for corner:Vector2 in [Vector2(-0.65,-0.65),Vector2(0.65,-0.65),Vector2(0.65,0.65),Vector2(-0.65,0.65)]:
				points.append(floor+Vector3(corner.x,0.0,corner.y))
		for point:Vector3 in points:
			assert_bool(camera.is_position_behind(point)).is_false()
			var pixel:=camera.unproject_position(point)
			assert_float(pixel.x).is_greater_equal(4.0)
			assert_float(pixel.x).is_less_equal(view.x-4.0)
			assert_float(pixel.y).is_greater_equal(float(stage.top_inset))
			assert_float(pixel.y).is_less_equal(view.y-20.0)


func test_actual_beating_claims_full_figure_and_floor_frame_through_approach()->void:
	var modal:Control=await _marshal()
	var stage:Control=modal.court_stage
	_type(modal,"Flog him.")
	assert_bool(stage.beating()).is_true()
	if not stage.beating():return
	_assert_punishment_in_frame(stage)
	var first_revision:=int(stage._beating.get_meta("frame_revision",0))
	assert_int(first_revision).is_greater(0)
	# Let the real approach finish: the second fit must use the attackers'
	# new positions, not the court seats they occupied before the order.
	await get_tree().create_timer(4.4).timeout
	assert_bool(stage.beating()).is_true()
	if not stage.beating():return
	assert_int(int(stage._beating.get_meta("frame_revision",0))).is_greater(first_revision)
	_assert_punishment_in_frame(stage)
	var held:Transform3D=stage.camera.global_transform
	stage.shot("reaction",{"target":Stage.MAIN,"weight":10,"time":0.0})
	stage.shot("shake",{"strength":1.0,"weight":10})
	assert_bool(stage.camera.global_transform.is_equal_approx(held)).is_true()
	assert_str(String(stage.rig.current_shot)).is_equal("still")
	stage._frame_all(0.0)
	_assert_punishment_in_frame(stage)
	stage.skip_beating()
	assert_bool(stage.beating()).is_false()
	stage.shot("reaction",{"target":Stage.MAIN,"weight":1,"time":0.0})
	assert_str(String(stage.rig.current_shot)).is_equal("reaction")


func test_typed_explicit_official_remains_the_actual_beating_actor()->void:
	var modal:Control=await _marshal()
	var stage:Control=modal.court_stage
	var actor_key:=""
	var victim:Variant=stage.figure(Stage.MAIN)
	# Pick a distinct official with an actual traversable approach. A seated
	# official trapped behind furniture is an intentional presentation fallback.
	var movement:=Stage.ExecStage.new();movement.stage=stage;movement.victim=Stage.MAIN
	var front:Vector3=stage.camera.global_position-victim.body3d.global_position
	front.y=0.0;front=front.normalized()
	var destination:Vector3=victim.body3d.global_position+front.rotated(Vector3.UP,deg_to_rad(78.0))*0.62
	for key:String in stage.cast_order:
		var person:Variant=stage.figure(key)
		var pid:=int(person.person.get("person_id",0))
		if key!=Stage.MAIN and person.role=="court" and pid>0 and pid!=int(victim.person.person_id) and movement._walk_path(key,destination).size()>=2:
			actor_key=key;break
	movement.free()
	assert_str(actor_key).is_not_empty()
	if actor_key.is_empty():return
	var actor:Dictionary=stage.figure(actor_key).person
	GovernmentPeopleSystem.adjust_person_bonds(int(actor.person_id),{"fear":1.0})
	_type(modal,"%s, flog him." % String(actor.name))
	if not stage.beating():print("BEATING_ACTOR_DIAGNOSTIC ",JSON.stringify({"actor":actor.name,"actor_id":actor.person_id,"victim_id":victim.person.person_id,"lines":Hall.find(modal.audience_id).get("lines",[])}))
	assert_bool(stage.beating()).is_true()
	if not stage.beating():return
	var result:Dictionary=modal._beating_results[0]
	assert_bool(bool(result.executed)).is_true()
	assert_int(int(result.actor.person_id)).is_equal(int(actor.person_id))
	assert_array(stage._beating.attackers).contains([actor_key])
	stage.skip_beating()


func test_cancel_releases_camera_claim_when_the_same_stage_survives()->void:
	var modal:Control=await _marshal()
	var stage:Control=modal.court_stage
	_type(modal,"Flog him.")
	assert_bool(stage.beating()).is_true()
	if not stage.beating():return
	assert_bool(is_inf(float(stage._shot_until))).is_true()
	stage.cancel_beating()
	assert_bool(stage.beating()).is_false()
	assert_bool(is_finite(float(stage._shot_until))).is_true()
	stage.shot("reaction",{"target":Stage.MAIN,"weight":1,"time":0.0})
	assert_str(String(stage.rig.current_shot)).is_equal("reaction")
	assert_bool(stage.figure(Stage.MAIN).body3d.visible).is_true()
