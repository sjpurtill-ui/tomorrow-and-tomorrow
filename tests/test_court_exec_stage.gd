extends GdUnitTestSuite
## AN EXECUTION IN THE MODELLED COURT (court_stage.gd execute, court_exec_stage.gd).
## - it plays only on someone standing in the hall, never on a child, never
##   under gore "off";
## - a club home run takes their head off and into the pot, and they are gone
##   at the end; a click brings it all to its end at once;
## - "mild" makes no blood and no flying head;
## - the old sober exit is not played again for one already put to death.
## Presentation only. Offline; never calls a real API or writes a save file.

const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Modal:=preload("res://scripts/hud/audience_modal.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Executions:=preload("res://scripts/hud/court_executions.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")

var _root_size:=Vector2i.ZERO

func before_test()->void:
	Stage.directing=true
	Stage.director=null
	Stage.acting=null
	Stage.use_sets=true
	Fixtures.new(self).base(false)
	_root_size=get_tree().root.size
	get_tree().root.size=Vector2i(1920,1080)

func after_test()->void:
	Stage.director=null
	Stage.acting=null
	Executions.gore="full"
	Executions.last_used=""
	get_tree().root.size=_root_size

func _ready_or_skip()->bool:
	return CourtSet.available() and Figure3D.available()

func _home_audience()->String:
	var marshal:Dictionary=GovernmentPeopleSystem.officeholder("Marshal")
	var target:={"person_id":int(marshal.get("person_id",0))} if not marshal.is_empty() else (Hall.summonable()[0].target as Dictionary)
	return String(Hall.summon(target).get("id",""))

func _open(id:String)->Control:
	var modal:Control=auto_free(Modal.new())
	modal.audience_id=id
	add_child(modal)
	for i in 4:await await_idle_frame()
	modal.skip_reveal()
	await await_idle_frame()
	modal.court_stage.settle()
	return modal

func _named(stage:Control,prefix:String)->int:
	var n:=0
	for node in stage.court_set.find_children(prefix+"*","",true,false):
		if is_instance_valid(node) and not (node as Node).is_queued_for_deletion():n+=1
	return n

func test_a_club_home_run_takes_the_head_into_the_pot_and_a_click_ends_it()->void:
	if not _ready_or_skip():return
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	var main:Stage.Figure=stage.figure(Stage.MAIN)
	assert_bool(stage.execute("club",Stage.MAIN,"","Heha")).is_true()
	assert_bool(stage.executing()).is_true()
	# run it to just after the blow
	for i in 40:await await_idle_frame()
	var exec:Node=stage.get_node("Execution")
	for t in stage._beat_sets:
		if t is Tween and (t as Tween).is_valid():(t as Tween).custom_step(3.2)
	await await_idle_frame()
	assert_int(_named(stage,"Exec_pot")).is_equal(1)
	assert_int(_named(stage,"ExecHead")).is_equal(1)
	assert_int(_named(stage,"ExecBlood")).is_greater_equal(1)
	# a click: everything to its end
	stage.skip_execution()
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(stage.executing()).is_false()
	assert_bool(main.leaving).is_true()
	assert_bool(main.body3d.visible).is_false()
	assert_int(_named(stage,"ExecHead")).is_equal(0)
	assert_int(_named(stage,"Exec_club")).is_equal(0)
	assert_str(String(stage._caption.label.text) if is_instance_valid(stage._caption) else "").contains("cooking pot")
	# the leave-taking does not play the sober fall again
	stage.conclude(0.0,"fall")
	assert_bool(main.body3d.visible).is_false()

func test_mild_makes_no_blood_and_no_flying_head()->void:
	if not _ready_or_skip():return
	Executions.gore="mild"
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	assert_bool(stage.execute("behead",Stage.MAIN,"","Heha")).is_true()
	for i in 4:
		for t in stage._beat_sets:
			if t is Tween and (t as Tween).is_valid():(t as Tween).custom_step(2.0)
		await await_idle_frame()
		assert_int(_named(stage,"ExecBlood")).is_equal(0)
		assert_int(_named(stage,"ExecHead")).is_equal(0)
		assert_int(_named(stage,"ExecPool")).is_equal(0)

func test_never_on_a_child_and_never_under_off()->void:
	if not _ready_or_skip():return
	var modal:Control=await _open(_home_audience())
	var stage:Control=modal.court_stage
	Executions.gore="off"
	assert_bool(stage.execute("club",Stage.MAIN)).is_false()
	Executions.gore="full"
	var main:Stage.Figure=stage.figure(Stage.MAIN)
	main.person["age"]=9
	assert_bool(stage.execute("club",Stage.MAIN)).is_false()
	assert_bool(stage.executing()).is_false()
