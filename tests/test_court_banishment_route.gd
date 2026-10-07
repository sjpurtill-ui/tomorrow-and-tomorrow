extends GdUnitTestSuite
## The engine has already exiled this exact person. Presentation cannot
## remove another person, remove population again, or turn exile into death.
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
var _reduced:=false

func before_test()->void:
	var info:Dictionary=Fixtures.new(self).base(false);_civ=String(info.civ_id)
	Stage.directing=true;Stage.director=null;Stage.acting=null;Stage.use_sets=true
	Backdrop.tier_override=-1;Backdrop.Stages.stage_override="";Voice.knowledge_override.clear()
	GameState.known_discoveries.assign(["temple_high_steward","pictographic_records","plain_weaving"])
	GameState.elapsed_days=600*365;Executions.gore="full"
	_reduced=Motion.reduce_motion;Motion.reduce_motion=false
	_root_size=get_tree().root.size;get_tree().root.size=Vector2i(1920,1080)

func after_test()->void:
	Backdrop.tier_override=-1;Backdrop.Stages.stage_override="";Voice.knowledge_override.clear()
	Stage.director=null;Stage.acting=null;Executions.gore="full";Motion.reduce_motion=_reduced
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

func _assert_unbound_exile(stage:Control)->void:
	assert_bool(stage.custody()).is_true()
	if not stage.custody():return
	assert_str(String(stage._custody.get_meta("presentation",""))).is_equal("exile")
	assert_bool(stage.executing()).is_false();assert_bool(stage.beating()).is_false()
	assert_object(stage._custody._receiver).is_null();assert_object(stage._custody._cord).is_null()
	var body:Node3D=stage.figure(Stage.MAIN).body3d
	assert_bool(bool(body.get_meta("custody_bound",false))).is_false()
	for child in body.get_children():
		if not child.is_queued_for_deletion():assert_bool(String(child.name).begins_with("CustodyBinding")).is_false()

func test_actual_typed_exile_uses_same_person_and_skip_never_removes_population_twice()->void:
	var modal:Control=await _marshal();var stage:Control=modal.court_stage
	var victim:Variant=stage.figure(Stage.MAIN);var pid:=int(victim.person.person_id)
	_type(modal,"Exile him.")
	_assert_unbound_exile(stage)
	if not stage.custody():return
	var result:Dictionary=modal._custody_results[0]
	assert_bool(bool(result.executed)).is_true();assert_str(String(result.verb)).is_equal("exile")
	assert_int(int(result.target.person_id)).is_equal(pid)
	assert_str(String(GovernmentPeopleSystem.person_snapshot(pid).get("status",""))).is_equal("exiled")
	var population:=float(GameState.population_exact)
	assert_bool(victim.leaving).is_false();assert_bool(victim.body3d.visible).is_true()
	assert_object(stage.say(Stage.MAIN,"No stale speech while being expelled.",false,false)).is_null()
	var frame:Transform3D=stage.camera.global_transform
	stage.shot("reaction",{"target":Stage.MAIN,"weight":10})
	assert_bool(stage.camera.global_transform.is_equal_approx(frame)).is_true()
	assert_bool(modal.show_custody(result)).is_false()
	modal.advance()
	assert_bool(stage.custody()).is_false();assert_bool(victim.leaving).is_true()
	assert_bool(victim.body3d.visible).is_false();assert_bool(modal._executed).is_false()
	assert_float(float(GameState.population_exact)).is_equal(population)
	var departure:Variant=victim._move
	stage.conclude(0.0,"led");await await_idle_frame()
	assert_bool(victim._move==departure).is_true()

func test_actual_official_cast_out_menu_uses_its_exact_success_schema()->void:
	var modal:Control=await _marshal();var stage:Control=modal.court_stage
	var pid:=int(stage.figure(Stage.MAIN).person.person_id)
	var result:Dictionary=modal.divine("cast_out")
	assert_bool(bool(result.get("ok",false))).is_true()
	assert_int(int(result.get("person_id",0))).is_equal(pid)
	_assert_unbound_exile(stage)
	if stage.custody():stage.skip_custody()
	assert_str(String(GovernmentPeopleSystem.person_snapshot(pid).get("status",""))).is_equal("exiled")

func test_actual_persons_menu_exile_removes_old_cord_but_rejected_target_does_not()->void:
	var fixture:=await _known();var modal:Control=fixture.modal;var stage:Control=modal.court_stage
	var body:Node3D=stage.figure(Stage.MAIN).body3d
	modal.persons_choose({"action":"bind","params":{},"label":"Bind"})
	assert_bool(stage.custody()).is_true()
	if not stage.custody():return
	stage.skip_custody()
	assert_bool(bool(body.get_meta("custody_bound",false))).is_true()
	assert_bool(modal.show_custody({"executed":true,"verb":"exile","target":{"known_id":"absent","speaker":true}})).is_false()
	assert_bool(bool(body.get_meta("custody_bound",false))).is_true()
	var result:Dictionary=modal.persons_choose({"action":"exile","params":{},"label":"Exile"})
	assert_bool(bool(result.ok)).is_true();assert_str(String(fixture.person.status)).is_equal("exiled")
	_assert_unbound_exile(stage)
	if not stage.custody():return
	await await_idle_frame()
	assert_int(body.find_children("CustodyBinding*","",true,false).size()).is_zero()
	var population:=float(GameState.population_exact)
	stage.skip_custody()
	assert_bool(body.visible).is_false();assert_bool(bool(body.get_meta("custody_bound",false))).is_false()
	assert_float(float(GameState.population_exact)).is_equal(population)

func test_actual_typed_known_person_exile_preserves_known_id()->void:
	var fixture:=await _known();var modal:Control=fixture.modal;var stage:Control=modal.court_stage
	_type(modal,"Banish him.")
	_assert_unbound_exile(stage)
	if not stage.custody():return
	var result:Dictionary=modal._custody_results[0]
	assert_str(String(result.target.known_id)).is_equal(String(fixture.person.id))
	assert_str(String(fixture.person.status)).is_equal("exiled")
	stage.skip_custody()

func test_actual_foreign_envoy_exile_menu_returns_them_alive_without_deaths()->void:
	var audience:=Hall.debug_force("news",_civ)
	var modal:Control=await _open(String(audience.id));var stage:Control=modal.court_stage
	var population:=float(ForeignDiplomacy.civilization(_civ).population)
	var result:Dictionary=modal.act_on_envoy("envoy_exile")
	assert_str(String(result.get("envoy_state",""))).is_equal("driven out")
	_assert_unbound_exile(stage)
	if stage.custody():stage.skip_custody()
	assert_bool(stage.figure(Stage.MAIN).body3d.visible).is_false()
	assert_float(float(ForeignDiplomacy.civilization(_civ).population)).is_equal(population)

func test_forbidden_failed_refused_noop_and_dismissal_do_not_stage_exile()->void:
	var modal:Control=await _marshal();var stage:Control=modal.court_stage
	var pid:=int(stage.figure(Stage.MAIN).person.person_id)
	_type(modal,"Do not exile him.")
	assert_bool(stage.custody()).is_false()
	var result:={"executed":false,"verb":"exile","target":{"person_id":pid},"actor":{}}
	assert_bool(modal.show_custody(result)).is_false()
	result.executed=true;result["obedience"]={"id":"refuse"}
	assert_bool(modal.show_custody(result)).is_false()
	result.obedience={"id":"hesitate"}
	assert_bool(modal.show_custody(result)).is_false()
	result.erase("obedience");result["stage"]="none"
	assert_bool(modal.show_custody(result)).is_false()
	result.erase("stage");result.verb="dismiss"
	assert_bool(modal.show_custody(result)).is_false()
	assert_bool(modal.show_custody({"ok":false,"action":"exile","params":{}},true)).is_false()
	assert_bool(modal.show_custody({"ok":true,"action":"cast_out","removed":false,"person_id":pid})).is_false()
	assert_bool(stage.figure(Stage.MAIN).body3d.visible).is_true()

func test_explicit_absent_target_or_actor_never_substitutes_the_speaker()->void:
	var modal:Control=await _marshal();var stage:Control=modal.court_stage
	var pid:=int(stage.figure(Stage.MAIN).person.person_id)
	var result:={"executed":true,"verb":"exile","target":{"person_id":2147483000,"speaker":true},"actor":{}}
	assert_bool(modal.show_custody(result)).is_false()
	result.target={"person_id":pid};result.actor={"person_id":2147483000}
	assert_bool(modal.show_custody(result)).is_false()
	assert_bool(modal.show_custody({"ok":true,"action":"cast_out","removed":true,"person_id":2147483000})).is_false()
	assert_bool(stage.custody()).is_false();assert_bool(stage.figure(Stage.MAIN).body3d.visible).is_true()

func test_cancel_and_close_release_camera_and_transients_without_changing_exile()->void:
	var modal:Control=await _marshal();var stage:Control=modal.court_stage
	var body:Node3D=stage.figure(Stage.MAIN).body3d;var pid:=int(stage.figure(Stage.MAIN).person.person_id)
	_type(modal,"Exile him.");_assert_unbound_exile(stage)
	stage.cancel_custody()
	assert_bool(stage.custody()).is_false();assert_bool(body.visible).is_true()
	assert_bool(is_finite(float(stage._shot_until))).is_true()
	assert_str(String(GovernmentPeopleSystem.person_snapshot(pid).get("status",""))).is_equal("exiled")
	modal._close();await await_idle_frame()
	assert_bool(is_instance_valid(stage)).is_false()
	var fixture:=await _known();var next_modal:Control=fixture.modal
	var next_stage:Control=next_modal.court_stage
	next_modal.persons_choose({"action":"exile","params":{},"label":"Exile"})
	_assert_unbound_exile(next_stage)
	next_modal._close();await await_idle_frame()
	assert_bool(is_instance_valid(next_stage)).is_false()
	assert_str(String(fixture.person.status)).is_equal("exiled")

func test_reduced_motion_and_gore_off_preserve_unbound_departure()->void:
	var fixture:=await _known();var modal:Control=fixture.modal;var stage:Control=modal.court_stage
	Motion.reduce_motion=true;Executions.gore="off"
	var result:Dictionary=modal.persons_choose({"action":"exile","params":{},"label":"Exile"})
	assert_bool(bool(result.ok)).is_true()
	for index in 3:await await_idle_frame()
	assert_bool(stage.custody()).is_false();assert_bool(stage.executing()).is_false()
	assert_bool(stage.figure(Stage.MAIN).leaving).is_true()
	assert_bool(stage.figure(Stage.MAIN).body3d.visible).is_false()
	assert_bool(bool(stage.figure(Stage.MAIN).body3d.get_meta("custody_bound",false))).is_false()
	assert_str(String(fixture.person.status)).is_equal("exiled")

func test_named_official_remains_the_actual_banishment_actor()->void:
	var modal:Control=await _marshal();var stage:Control=modal.court_stage
	var victim:Variant=stage.figure(Stage.MAIN)
	var movement:=Stage.ExecStage.new();movement.stage=stage;movement.victim=Stage.MAIN
	var destination:Vector3=Stage.CustodyStage.exile_approach_point(victim.body3d,stage.court_set.door_points()[1],0)
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
	_type(modal,"%s, exile him." % String(actor.name))
	_assert_unbound_exile(stage)
	if not stage.custody():return
	var result:Dictionary=modal._custody_results[0]
	assert_int(int(result.actor.person_id)).is_equal(int(actor.person_id))
	assert_int(int(result.target.person_id)).is_equal(int(victim.person.person_id))
	assert_array(stage._custody.support_keys).contains([actor_key])
	stage.skip_custody()
