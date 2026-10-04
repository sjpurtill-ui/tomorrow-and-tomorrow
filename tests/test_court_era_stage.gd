extends GdUnitTestSuite

const Stage:=preload("res://scripts/hud/court_stage.gd")
const Presentation:=preload("res://scripts/hud/court_presentation.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")

func test_rediscovery_redresses_the_same_identity_in_a_reused_registry()->void:
	var person:={"name":"Hena","person_id":81,"sex":"female","age":35}
	var registry:={}
	var early:=Stage.figure_look(person,registry,Presentation.from_knowledge([]))
	var modern:=Stage.figure_look(person,registry,Presentation.from_knowledge(["radio_broadcasting","garment_size_grading"]))
	assert_str(String(early.outfit)).is_equal("hide")
	assert_str(String(modern.outfit)).is_equal("business")
	for key in ["skin","face","hair","beard","hair_colour","variant","seed"]:
		assert_str(var_to_str(modern[key])).override_failure_message("period change altered identity: "+key).is_equal(var_to_str(early[key]))
	assert_str(var_to_str(Stage.figure_look(person,registry,Presentation.from_knowledge(["radio_broadcasting","garment_size_grading"])))).is_equal(var_to_str(modern))

func test_formal_clothes_keep_light_shirts_when_the_registry_spreads_people()->void:
	var profile:=Presentation.from_knowledge(["radio_broadcasting","garment_size_grading"])
	var registry:={}
	for i in 25:
		var look:=Stage.figure_look({"name":"Official","person_id":i,"age":35,"sex":"male"},registry,profile)
		assert_float((look.cloth[1] as Color).get_luminance()).is_greater(0.7)
		assert_bool(String(look.stance) in ["bowl","staff","crouch"]).is_false()

func test_later_institutions_use_the_hall_fallback_without_camp_stores()->void:
	for id in ["privy_state_council","parliamentary_council","ministerial_cabinet","executive_council"]:
		assert_str(CourtSet.kind_for(id,0)).is_equal("grand_hall")
	var court:Node3D=auto_free(CourtSet.build("executive_council",{"rustic_props":false,"dogs":false,"herds":false,"fowl":false,"food":1.0,"season":"summer"}))
	add_child(court)
	assert_array(court.animals).is_empty()
	for group in ["food","rack","spears"]:
		for prop:Node3D in court.props.get(group,[]):assert_bool(prop.visible).is_false()
	for flies:GPUParticles3D in court.flies:assert_bool(flies.visible).is_false()

func _stage()->Control:
	var stage:Control=auto_free(Stage.new());add_child(stage)
	stage.facts={"presentation":Presentation.from_knowledge(["radio_broadcasting","garment_size_grading"])}
	stage.three_d=false
	return stage

func test_default_departure_uses_each_persons_protocol_but_keeps_explicit_reactions()->void:
	var was_directing:=Stage.directing;Stage.directing=false
	var stage:=_stage()
	stage.facts["presentations"]={"visitor":Presentation.from_knowledge(["fitted_tailoring","royal_chancery_office"],{"id":"feudal_hall","rank":8,"lean":"throne"})}
	var main:Stage.Figure=stage.add_figure("main",{"name":"Official","age":35},"main")
	var visitor:Stage.Figure=stage.add_figure("visitor",{"name":"Visitor","age":30,"appearance_civ_id":"visitor"},"attendant")
	stage.conclude(0.0,"bow","pleased")
	assert_str(main.exit_style).is_equal("nod")
	assert_str(visitor.exit_style).is_equal("bow_small")
	var reacted:=_stage()
	var reverent:Stage.Figure=reacted.add_figure("main",{"name":"Reverent","age":35},"main")
	reacted.conclude(0.0,"bow","reverence")
	assert_str(reverent.exit_style).is_equal("bow")
	Stage.directing=was_directing

func test_nod_departure_reaches_walking_without_a_full_bow()->void:
	var was_acting:=Stage.acting;Stage.acting=Acting.service()
	var stage:=_stage()
	var figure:Stage.Figure=stage.add_figure("main",{"name":"Clerk","age":35},"main")
	var body:Node3D=Figure3D.new();stage.add_child(body)
	assert_bool(body.setup({"variant":"male_adult","outfit":"tunic","stance":"stand"})).is_true()
	figure.body3d=body;figure.rest_clip="stand"
	figure.leave(1.0,600.0,0.0,"nod")
	figure._move.pause();figure._move.custom_step(0.05)
	assert_str(String(body.clip)).is_not_equal("bow")
	for i in 30:figure._move.custom_step(0.1)
	assert_str(String(body.clip)).is_equal("walk_out")
	figure.finish_moves()
	assert_bool(body.visible).is_false()
	Stage.acting=was_acting

func test_routine_greeting_waits_until_the_walker_reaches_their_mark()->void:
	var was_acting:=Stage.acting;Stage.acting=Acting.service()
	var stage:=_stage()
	var figure:Stage.Figure=stage.add_figure("main",{"name":"Clerk","age":35},"main")
	var body:Node3D=Figure3D.new();stage.add_child(body)
	assert_bool(body.setup({"variant":"male_adult","outfit":"tunic","stance":"stand"})).is_true()
	figure.body3d=body;figure.rest_clip="stand";figure._stage=weakref(stage)
	figure.enter_from(-1.0,600.0,0.0)
	figure._move.pause()
	stage._beat({"who":"main","act":"play","args":{"beat":"nod","routine":true}})
	assert_bool(stage._pending_greetings.has("main")).is_true()
	assert_str(String(body.clip)).is_equal("walk_in")
	figure._move.custom_step(10.0)
	assert_bool(stage._pending_greetings.has("main")).is_false()
	assert_str(String(body.clip)).is_not_equal("walk_in")
	Stage.acting=was_acting
