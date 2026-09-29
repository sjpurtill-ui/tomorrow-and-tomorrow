extends GdUnitTestSuite
## One rule for every people: researchers make the research, emphasis only
## directs it, and computer rulers and a delegating player plan the same way.
const R=preload("res://scripts/research_600_catalog.gd")
const S=preload("res://scripts/civilization_strategy.gd")
const C=preload("res://scripts/civilization_controller.gd")
const Society=preload("res://scripts/society_model.gd")
const P=preload("res://scripts/leader_personality.gd")
const Culture=preload("res://scripts/cultural_inheritance.gd")
const SENSIBLE:={"demography":2,"nutrition":3,"health":3,"labor":2,"knowledge":2,"production":3,"infrastructure":2,"logistics":1,"ecology":1,"institutions":1,"security":1,"culture":1}

func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("parity",4242)
func after_test()->void:WorldSimulation.clear()

## Lays each line's steps over its subcategories directly (no redistribution).
func _lay_out(steps_by_line:Dictionary)->void:
	var allocations:Dictionary=WorldSimulation.state.research_subcategory_allocations
	for line:String in allocations:
		var subs:Dictionary=allocations[line]
		var keys:Array=subs.keys()
		for key in keys:subs[key]=0
		for i in int(steps_by_line.get(line,0)):subs[keys[i%keys.size()]]=int(subs[keys[i%keys.size()]])+1
	WorldSimulation.discovery._rebuild_research_domain_totals()

## Every staffed line's part of the work (before food, tools and schooling).
func _work()->float:
	var work:=0.0
	var allocations:Dictionary=WorldSimulation.state.research_subcategory_allocations
	for line:String in allocations:
		for sub:String in allocations[line]:
			if int(allocations[line][sub])>0:work+=float(WorldSimulation.discovery.research_capacity_for(line,sub).team_scale)
	return work

func test_the_same_researchers_make_the_same_progress_under_any_emphasis()->void:
	WorldSimulation.scoped("parity",func()->void:
		WorldSimulation.state.population_allocations.Knowledge=60
		var researchers:=float(WorldSimulation.state.effective_workers("Knowledge"))
		assert_float(researchers).is_greater(R.RESEARCH_TEAMS)
		var everything:Dictionary={}
		for line:String in S.DOMAINS:everything[line]=12
		var totals:Array[float]=[]
		# One favourite, the old four-step rival plan, a sensible spread, and every
		# line at twelve on all 48 channels.
		for plan:Dictionary in [{"security":4},{"knowledge":1,"production":1,"infrastructure":1,"nutrition":1},SENSIBLE,everything]:
			_lay_out(plan)
			totals.append(_work())
		for value in totals:assert_float(value).is_equal_approx(R.team_capacity(researchers),.0001)
	)

func test_piling_people_onto_one_line_has_diminishing_returns()->void:
	WorldSimulation.scoped("parity",func()->void:
		WorldSimulation.state.population_allocations.Knowledge=60
		var allocations:Dictionary=WorldSimulation.state.research_subcategory_allocations
		_lay_out({})
		var knowledge:String=allocations.knowledge.keys()[0];var culture:String=allocations.culture.keys()[0]
		allocations.knowledge[knowledge]=4;allocations.culture[culture]=1
		var heavy:=float(WorldSimulation.discovery.research_capacity_for("knowledge",knowledge).team_scale)
		var light:=float(WorldSimulation.discovery.research_capacity_for("culture",culture).team_scale)
		assert_float(heavy).is_greater(light)
		assert_float(heavy).is_less(light*4.0)
		# A small band has too few people for returns to diminish: work follows emphasis.
		WorldSimulation.state.population_allocations.Knowledge=1
		heavy=float(WorldSimulation.discovery.research_capacity_for("knowledge",knowledge).team_scale)
		light=float(WorldSimulation.discovery.research_capacity_for("culture",culture).team_scale)
		assert_float(heavy).is_equal_approx(light*4.0,.0001)
	)

func test_steps_of_attention_are_read_as_shares()->void:
	var small:={"knowledge":1,"health":1,"security":0}
	var large:={"knowledge":6,"health":6,"security":0}
	assert_dict(R.attention_steps(small)).is_equal(R.attention_steps(large))
	assert_float(R.attention_steps(small).knowledge).is_equal_approx(R.ATTENTION_STEPS/2.0,.0001)
	assert_float(R.keepers_asked(small)).is_equal(R.keepers_asked(large))
	WorldSimulation.scoped("parity",func()->void:
		WorldSimulation.state.population_allocations.Knowledge=3
		var doubled:Dictionary={}
		for line:String in SENSIBLE:doubled[line]=int(SENSIBLE[line])*2
		_lay_out(SENSIBLE)
		var inputs:=WorldSimulation.discovery.society_model.capacity_inputs()
		_lay_out(doubled)
		var again:=WorldSimulation.discovery.society_model.capacity_inputs()
		for key:String in ["attention","overwork","fields"]:assert_float(float(again[key])).is_equal_approx(float(inputs[key]),.0001)
	)

func test_a_focus_moves_benefit_between_lines_and_costs_no_more_than_it_brings()->void:
	var even:=1.0/12.0
	for plan:Dictionary in [{"knowledge":12},{"knowledge":1,"production":1,"infrastructure":1,"nutrition":1},SENSIBLE,{"security":3,"logistics":2,"nutrition":1}]:
		var total:=0.0
		for line in plan:total+=float(plan[line])
		var focus:Dictionary={}
		for line:String in plan:
			var share:=float(plan[line])/total
			if share>even:focus[line]=(share-even)/(1.0-even)
		var neglect:=Society.neglect_for(focus)
		var moved:=0.0
		for line:String in Society.DYNAMICS:moved+=Society.practice_scale(line,focus,neglect)-1.0
		assert_float(moved).is_equal_approx(0.0,.000001)
	# All attention on one line: each other line gives up an eleventh of the gain.
	assert_float(Society.neglect_for({"knowledge":1.0})).is_equal_approx(Society.SPECIALIZATION_HEADROOM/11.0,.000001)

func test_computer_rulers_plan_in_the_players_steps()->void:
	var plan:=S.preferences({"openness":.6,"discipline":.4,"empathy":.7,"assertiveness":.3,"risk_tolerance":.5},{"food_days":120,"food_intake_ratio":1})
	var steps:=S.research_plan(plan.research_weights)
	var total:=0
	for line:String in S.DOMAINS:
		assert_int(int(steps[line])).is_between(1,12)
		total+=int(steps[line])
	assert_int(total).is_equal(R.ATTENTION_STEPS)
	# A strong favourite can hold as much as any player gives it.
	var favourite:Dictionary={}
	for line:String in S.DOMAINS:favourite[line]=.1
	favourite.security=100.0
	var leaning:=S.research_plan(favourite)
	assert_int(int(leaning.security)).is_equal(12)
	# A field the ruler does not weigh at all gets nothing.
	favourite.culture=0.0
	assert_int(int(S.research_plan(favourite).culture)).is_equal(0)

func test_a_ruler_is_not_held_to_the_emphasis_it_started_with()->void:
	WorldSimulation.scoped("parity",func()->void:
		var before:=0
		for value in WorldSimulation.state.research_allocations.values():before+=int(value)
		C.research_orders("parity",C.current_plan("parity"))
		var after:=0;var fields:=0
		for value in WorldSimulation.state.research_allocations.values():
			after+=int(value)
			if int(value)>0:fields+=1
		assert_int(after).is_greater(before)
		assert_int(fields).is_greater(4)
	)

func test_delegated_research_is_the_rulers_planner_with_the_peoples_culture()->void:
	var saved:={"allocations":GameState.research_allocations.duplicate(true),"subcategories":GameState.research_subcategory_allocations.duplicate(true),"active":GameState.active_investigations.duplicate(true),"targets":GameState.research_targets.duplicate(true)}
	PeopleDirection.ensure()
	var memory:Dictionary=PeopleDirection.cultural_memory.duplicate(true)
	var flags:=[PeopleDirection.auto_scouting,PeopleDirection.auto_research,PeopleDirection.inclination_review_day]
	var day:=int(GameState.elapsed_days)
	PeopleDirection.auto_scouting=false;PeopleDirection.auto_research=true
	PeopleDirection.cultural_memory=Culture.empty()
	Culture.record(PeopleDirection.cultural_memory,"parity:inquiry","inquiry",day,10.0)
	for line:String in S.DOMAINS:DiscoverySystem.set_domain_research_priority(line,1 if line in ["nutrition","health","knowledge","ecology"] else 0)
	var start:={"allocations":GameState.research_allocations.duplicate(true),"subcategories":GameState.research_subcategory_allocations.duplicate(true),"active":GameState.active_investigations.duplicate(true),"targets":GameState.research_targets.duplicate(true)}
	PeopleDirection.inclination_review_day=-1
	PeopleDirection.apply_inclinations(day)
	var delegated:=GameState.research_allocations.duplicate(true)
	# The very planner a computer ruler uses; the people's own values stand in
	# for a ruler's temperament.
	var tendency:=P.from_values(GameState.societal_values)
	var plan:=C.current_plan("player",tendency)
	assert_dict(plan.personality).is_equal(tendency)
	GameState.research_allocations=start.allocations.duplicate(true);GameState.research_subcategory_allocations=start.subcategories.duplicate(true)
	GameState.active_investigations=start.active.duplicate(true);GameState.research_targets=start.targets.duplicate(true)
	C.research_orders("player",plan)
	assert_dict(GameState.research_allocations).is_equal(delegated)
	var fields:=0
	for value in delegated.values():
		if int(value)>0:fields+=1
	assert_int(fields).is_greater(4)
	# The chosen ambition leans the plan: inquiry's fields get more than an even share.
	assert_int(maxi(int(delegated.knowledge),int(delegated.health))).is_greater(2)
	PeopleDirection.cultural_memory=memory
	PeopleDirection.auto_scouting=flags[0];PeopleDirection.auto_research=flags[1];PeopleDirection.inclination_review_day=flags[2]
	GameState.research_allocations=saved.allocations;GameState.research_subcategory_allocations=saved.subcategories
	GameState.active_investigations=saved.active;GameState.research_targets=saved.targets

func test_the_peoples_tendency_comes_from_the_values_they_live_by()->void:
	var open_minds:={"lived":{"openness":.9,"experimentation":.9,"hierarchy":.2,"collective_obligation":.5,"centralization":.5,"common_stewardship":.5,"restorative_justice":.5,"ecological_restraint":.5}}
	var closed:={"lived":{"openness":.1,"experimentation":.1,"hierarchy":.8,"collective_obligation":.5,"centralization":.5,"common_stewardship":.5,"restorative_justice":.5,"ecological_restraint":.5}}
	var a:=P.from_values(open_minds);var b:=P.from_values(closed)
	assert_float(float(a.openness)).is_greater(float(b.openness))
	assert_float(float(a.assertiveness)).is_less(float(b.assertiveness))
	for tendency:Dictionary in [a,b,P.from_values({})]:
		for axis:String in P.AXES:assert_float(float(tendency[axis])).is_between(.12,.92)
