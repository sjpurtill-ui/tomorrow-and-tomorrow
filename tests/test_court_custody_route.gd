extends GdUnitTestSuite
## Real order/menu judgments feed a nonfatal presentation, never a second ledger.
const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Persons:=preload("res://scripts/court_persons.gd")
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")
const Executions:=preload("res://scripts/hud/court_executions.gd")
const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Voice:=preload("res://scripts/character_voice.gd")
const Motion:=preload("res://scripts/hud/motion.gd")
var _root_size:=Vector2i.ZERO
var _civ:=""
var _reduced_motion:=false

func before_test()->void:
	var info:Dictionary=Fixtures.new(self).base(false);_civ=String(info.civ_id)
	Stage.directing=true;Stage.director=null;Stage.acting=null;Stage.use_sets=true
	Backdrop.tier_override=-1;Backdrop.Stages.stage_override="";Voice.knowledge_override.clear()
	GameState.known_discoveries.assign(["temple_high_steward","pictographic_records","plain_weaving"])
	GameState.elapsed_days=600*365;Executions.gore="full"
	_reduced_motion=Motion.reduce_motion;Motion.reduce_motion=false
	_root_size=get_tree().root.size;get_tree().root.size=Vector2i(1920,1080)

func after_test()->void:
	Backdrop.tier_override=-1;Backdrop.Stages.stage_override="";Voice.knowledge_override.clear()
	Stage.director=null;Stage.acting=null;Executions.gore="full"
	Motion.reduce_motion=_reduced_motion
	get_tree().root.size=_root_size

func _open(id:String)->Control:
	assert_str(id).is_not_empty()
	var modal:Control=auto_free(Modal.new());modal.audience_id=id;add_child(modal)
	for index in 4:await await_idle_frame()
	modal.skip_reveal();await await_idle_frame();modal.court_stage.settle()
	assert_str(String(modal.court_stage.court_set.kind)).is_equal("chapter_03")
	return modal

func _marshal()->Control:
	var marshal:Dictionary=GovernmentPeopleSystem.officeholder("Marshal")
	return await _open(String(Hall.summon({"person_id":int(marshal.person_id)}).get("id","")))

func _known(age:=45)->Dictionary:
	var person:=Persons.create({"sex":"male","trade":"gatherer"})
	person.born_day=int(GameState.elapsed_days)-age*365
	var audience:=Persons.summon_ref({"kind":"known","id":String(person.id)},"")
	return {"person":person,"modal":await _open(String(audience.id))}

func _type(modal:Control,words:String)->void:
	modal.speech_input.text=words;modal._speak()

func test_actual_typed_arrest_escorts_the_same_living_official_only_once()->void:
	var modal:Control=await _marshal();var stage:Control=modal.court_stage
	var victim:Variant=stage.figure(Stage.MAIN);var pid:=int(victim.person.person_id)
	var population:=float(GameState.population_exact)
	stage.say(Stage.MAIN,"Old words must not continue during seizure.",false,false)
	_type(modal,"Arrest him.")
	assert_bool(stage.custody()).is_true()
	if not stage.custody():return
	var result:Dictionary=modal._custody_results[0]
	assert_bool(bool(result.executed)).is_true()
	assert_str(String(result.verb)).is_equal("detain")
	assert_int(int(result.target.person_id)).is_equal(pid)
	assert_bool(modal._executed).is_false();assert_bool(stage.executing()).is_false()
	assert_bool(victim.leaving).is_false()
	assert_object(stage.say(Stage.MAIN,"No talking through restraint.",false,false)).is_null()
	assert_bool(modal.show_custody(result)).is_false()
	var held:Transform3D=stage.camera.global_transform
	var camera:Camera3D=stage.camera;var view:=camera.get_viewport().get_visible_rect().size
	for key:String in stage._custody.get_meta("participant_keys",[]):
		var body:Node3D=stage.figure(key).body3d
		for point:Vector3 in [body.global_position,body.head_top()]:
			var pixel:=camera.unproject_position(point)
			assert_bool(camera.is_position_behind(point)).is_false()
			assert_float(pixel.y).is_between(float(stage.top_inset),view.y-20.0)
	stage.shot("reaction",{"target":Stage.MAIN,"weight":10})
	assert_bool(stage.camera.global_transform.is_equal_approx(held)).is_true()
	stage.conclude(0.0,"led")
	assert_bool(victim.leaving).is_false()
	modal.advance()
	assert_bool(stage.custody()).is_false()
	assert_bool(victim.leaving).is_true();assert_bool(victim.body3d.visible).is_false()
	var departure:Variant=victim._move
	stage.conclude(0.0,"led")
	await await_idle_frame()
	assert_bool(victim._move==departure).is_true()
	assert_bool(victim.body3d.visible).is_false()
	assert_str(String(GovernmentPeopleSystem.person_snapshot(pid).get("status",""))).is_equal("detained")
	assert_float(float(GameState.population_exact)).is_equal(population)
	assert_bool(modal.show_custody(result)).is_false()

func test_actual_envoy_menu_seizes_and_holds_without_a_death()->void:
	var audience:=Hall.debug_force("news",_civ)
	var modal:Control=await _open(String(audience.id));var stage:Control=modal.court_stage
	var population:=float(ForeignDiplomacy.civilization(_civ).population)
	var result:Dictionary=modal.act_on_envoy("envoy_detain")
	assert_str(String(result.get("envoy_state",""))).is_equal("bound")
	assert_bool(stage.custody()).is_true()
	if not stage.custody():return
	assert_int(modal._custody_results.size()).is_equal(1)
	stage.skip_custody()
	assert_bool(stage.custody()).is_false();assert_bool(stage.executing()).is_false()
	assert_bool(stage.figure(Stage.MAIN).body3d.visible).is_false()
	assert_float(float(ForeignDiplomacy.civilization(_civ).population)).is_equal(population)

func test_actual_persons_bind_stays_visible_then_free_removes_binding()->void:
	var fixture:=await _known();var person:Dictionary=fixture.person
	var modal:Control=fixture.modal;var stage:Control=modal.court_stage
	var victim:Variant=stage.figure(Stage.MAIN)
	var bound:=Persons.perform(modal.audience_id,"bind",{})
	modal._after_persons(bound)
	assert_bool(stage.custody()).is_true()
	if not stage.custody():return
	assert_str(String(person.status)).is_equal("living")
	assert_bool(bool(person.bound)).is_true()
	stage.skip_custody()
	assert_bool(stage.custody()).is_false();assert_bool(victim.leaving).is_false()
	assert_bool(victim.body3d.visible).is_true()
	assert_bool(bool(victim.body3d.get_meta("custody_bound",false))).is_true()
	assert_str(String(Hall.find(modal.audience_id).status)).is_equal("waiting")
	var freed:=Persons.perform(modal.audience_id,"free",{})
	modal._after_persons(freed)
	assert_bool(bool(freed.ok)).is_true()
	assert_bool(bool(person.get("bound",false))).is_false()
	assert_bool(bool(victim.body3d.get_meta("custody_bound",false))).is_false()
	assert_bool(victim.body3d.visible).is_true();assert_bool(victim.leaving).is_false()

func test_rejected_order_and_absent_explicit_ids_do_not_arrest_the_speaker()->void:
	var modal:Control=await _marshal();var stage:Control=modal.court_stage
	var pid:=int(stage.figure(Stage.MAIN).person.person_id)
	var result:={"executed":false,"verb":"detain","target":{"person_id":pid},"actor":{}}
	assert_bool(modal.show_custody(result)).is_false()
	result.executed=true;result.verb="demote"
	assert_bool(modal.show_custody(result)).is_false()
	result.verb="detain";result.obedience={"id":"refuse"}
	assert_bool(modal.show_custody(result)).is_false()
	result.erase("obedience");result.target={"person_id":2147483000,"speaker":true}
	assert_bool(modal.show_custody(result)).is_false()
	result.target={"person_id":pid};result.actor={"person_id":2147483000}
	assert_bool(modal.show_custody(result)).is_false()
	assert_bool(stage.custody()).is_false();assert_bool(stage.figure(Stage.MAIN).body3d.visible).is_true()

func test_reduced_motion_settles_actual_binding_and_still_allows_release()->void:
	var fixture:=await _known();var person:Dictionary=fixture.person
	var modal:Control=fixture.modal;var stage:Control=modal.court_stage
	var victim:Variant=stage.figure(Stage.MAIN)
	Motion.reduce_motion=true
	var bound:=Persons.perform(modal.audience_id,"bind",{})
	modal._after_persons(bound)
	for index in 3:await await_idle_frame()
	assert_bool(bool(bound.ok)).is_true();assert_bool(bool(person.bound)).is_true()
	assert_bool(stage.custody()).is_false()
	assert_bool(victim.body3d.visible).is_true();assert_bool(victim.leaving).is_false()
	assert_bool(bool(victim.body3d.get_meta("custody_bound",false))).is_true()
	assert_float(float(stage._shot_until)).is_less(INF)
	var freed:=Persons.perform(modal.audience_id,"free",{})
	modal._after_persons(freed)
	assert_bool(bool(freed.ok)).is_true();assert_bool(bool(person.get("bound",false))).is_false()
	assert_bool(bool(victim.body3d.get_meta("custody_bound",false))).is_false()
	assert_bool(victim.body3d.visible).is_true();assert_bool(victim.leaving).is_false()

func test_gore_off_keeps_non_graphic_arrest_but_child_binding_uses_fallback()->void:
	var modal:Control=await _marshal();Executions.gore="off"
	_type(modal,"Arrest him.")
	assert_bool(modal.court_stage.custody()).is_true()
	modal.court_stage.cancel_custody();modal._close();await await_idle_frame()
	var fixture:=await _known(10);var child_modal:Control=fixture.modal
	var result:=Persons.perform(child_modal.audience_id,"bind",{})
	child_modal._after_persons(result)
	assert_bool(bool(result.ok)).is_true()
	assert_bool(child_modal.court_stage.custody()).is_false()
	assert_bool(child_modal.court_stage.figure(Stage.MAIN).body3d.visible).is_true()
	assert_bool(bool(fixture.person.bound)).is_true()

func test_cancel_clears_scene_and_camera_without_undoing_detention()->void:
	var modal:Control=await _marshal();var stage:Control=modal.court_stage
	var victim:Variant=stage.figure(Stage.MAIN);var pid:=int(victim.person.person_id)
	_type(modal,"Arrest him.")
	assert_bool(stage.custody()).is_true()
	stage.cancel_custody()
	assert_bool(stage.custody()).is_false();assert_bool(victim.leaving).is_false()
	assert_bool(victim.body3d.visible).is_true()
	assert_bool(bool(victim.body3d.get_meta("custody_bound",false))).is_false()
	assert_bool(is_finite(float(stage._shot_until))).is_true()
	stage.shot("reaction",{"target":Stage.MAIN,"weight":1,"time":0.0})
	assert_str(String(stage.rig.current_shot)).is_equal("reaction")
	assert_str(String(GovernmentPeopleSystem.person_snapshot(pid).get("status",""))).is_equal("detained")

func test_skip_during_arrival_settles_the_authorized_terminal_condition()->void:
	var modal:Control=await _marshal();var stage:Control=modal.court_stage
	var victim:Variant=stage.figure(Stage.MAIN)
	victim.enter_from(-1.0,1.0,0.0);await await_idle_frame()
	_type(modal,"Arrest him.")
	assert_bool(stage.custody()).is_true()
	if not stage.custody():return
	assert_str(String(stage._custody.get_meta("custody_state",""))).is_equal("waiting_for_arrivals")
	modal.advance()
	assert_bool(stage.custody()).is_false();assert_object(stage._custody_start).is_null()
	assert_bool(victim.leaving).is_true();assert_bool(victim.body3d.visible).is_false()
	await await_idle_frame();assert_object(stage.get_node_or_null("Custody")).is_null()

func test_switching_audience_clears_the_old_retained_binding()->void:
	var fixture:=await _known();var modal:Control=fixture.modal
	var old_stage:Control=modal.court_stage;var old_body:Node3D=old_stage.figure(Stage.MAIN).body3d
	modal._after_persons(Persons.perform(modal.audience_id,"bind",{}))
	assert_bool(old_stage.custody()).is_true()
	if not old_stage.custody():return
	old_stage.skip_custody()
	assert_bool(bool(old_body.get_meta("custody_bound",false))).is_true()
	var next:=Hall.debug_force("news",_civ)
	modal.show_audience(String(next.id))
	if is_instance_valid(old_body):assert_bool(bool(old_body.get_meta("custody_bound",false))).is_false()
	assert_bool(modal.court_stage.custody()).is_false()
	assert_int(modal._custody_results.size()).is_equal(0)

func test_typed_named_official_is_preserved_as_the_arresting_actor()->void:
	var modal:Control=await _marshal();var stage:Control=modal.court_stage
	var victim:Variant=stage.figure(Stage.MAIN)
	var movement:=Stage.ExecStage.new();movement.stage=stage;movement.victim=Stage.MAIN
	var destination:Vector3=Stage.CustodyStage.approach_point(victim.body3d,0)
	var actor_key:=""
	for key:String in stage.cast_order:
		var person:Variant=stage.figure(key);var pid:=int(person.person.get("person_id",0))
		if key!=Stage.MAIN and person.role=="court" and pid>0 and pid!=int(victim.person.person_id) and movement._walk_path(key,destination).size()>=2:
			actor_key=key;break
	movement.free()
	assert_str(actor_key).is_not_empty()
	if actor_key.is_empty():return
	var actor:Dictionary=stage.figure(actor_key).person
	GovernmentPeopleSystem.adjust_person_bonds(int(actor.person_id),{"fear":1.0})
	_type(modal,"%s, arrest him." % String(actor.name))
	assert_bool(stage.custody()).is_true()
	if not stage.custody():return
	var result:Dictionary=modal._custody_results[0]
	assert_int(int(result.actor.person_id)).is_equal(int(actor.person_id))
	assert_int(int(result.target.person_id)).is_equal(int(victim.person.person_id))
	assert_array(stage._custody.support_keys).contains([actor_key])
	stage.skip_custody()

func test_authoritative_free_during_binding_cancels_transients_before_release()->void:
	var fixture:=await _known();var modal:Control=fixture.modal;var stage:Control=modal.court_stage
	modal._after_persons(Persons.perform(modal.audience_id,"bind",{}))
	assert_bool(stage.custody()).is_true()
	if not stage.custody():return
	modal._after_persons(Persons.perform(modal.audience_id,"free",{}))
	assert_bool(stage.custody()).is_false()
	assert_bool(bool(fixture.person.get("bound",false))).is_false()
	assert_bool(bool(stage.figure(Stage.MAIN).body3d.get_meta("custody_bound",false))).is_false()
	assert_bool(stage.figure(Stage.MAIN).body3d.visible).is_true()
	await await_idle_frame();assert_object(stage.get_node_or_null("Custody")).is_null()

func test_later_adjudicated_execution_releases_the_retained_binding_first()->void:
	var fixture:=await _known();var modal:Control=fixture.modal;var stage:Control=modal.court_stage
	var body:Node3D=stage.figure(Stage.MAIN).body3d
	modal._after_persons(Persons.perform(modal.audience_id,"bind",{}))
	assert_bool(stage.custody()).is_true()
	if not stage.custody():return
	stage.skip_custody()
	assert_bool(bool(body.get_meta("custody_bound",false))).is_true()
	var judgment:=Persons.perform(modal.audience_id,"execute",{})
	assert_bool(bool(judgment.ok)).is_true()
	assert_str(String(fixture.person.status)).is_equal("dead")
	var population:=float(GameState.population_exact)
	assert_bool(stage.execute("club",Stage.MAIN)).is_true()
	assert_bool(bool(body.get_meta("custody_bound",false))).is_false()
	stage.skip_execution()
	assert_float(float(GameState.population_exact)).is_equal(population)
