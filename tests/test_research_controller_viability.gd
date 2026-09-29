extends GdUnitTestSuite
const C=preload("res://scripts/civilization_controller.gd")
const S=preload("res://scripts/civilization_strategy.gd")
const R=preload("res://scripts/research_600_catalog.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("research_ruler",91420)
func after_test()->void:WorldSimulation.clear()
func configure(remaining:String,weight:int)->void:
	for entry:Dictionary in WorldSimulation.discovery.technology_catalog:
		if entry.id!=remaining:WorldSimulation.state.known_discoveries.append(entry.id)
	for domain:String in S.DOMAINS:WorldSimulation.submit("research_ruler",{"kind":"research_emphasis","domain":domain,"weight":0})
	WorldSimulation.submit("research_ruler",{"kind":"research_emphasis","domain":"security","weight":weight})
func plan()->Dictionary:
	var weights:Dictionary={}
	for domain:String in S.DOMAINS:weights[domain]=.1
	weights.security=100.0
	return {"research_weights":weights,"goals":[{"title":"Defend the realm"}]}
func total()->int:
	var sum:=0
	for value in WorldSimulation.state.research_allocations.values():sum+=int(value)
	return sum
func test_blocked_favorite_field_yields_to_a_live_foundation()->void:
	var player_before:=GameState.research_allocations.duplicate(true)
	WorldSimulation.scoped("research_ruler",func()->void:
		configure("drainage",3)
		preload("res://scripts/opening_opportunities.gd").record("drainage",1000.0)
		C.research_orders("research_ruler",plan())
		# All attention goes where a question is open; the blocked favourite keeps none.
		assert_int(int(WorldSimulation.state.research_allocations.security)).is_equal(0)
		assert_int(int(WorldSimulation.state.research_allocations.infrastructure)).is_greater(0)
		assert_int(total()).is_equal(int(WorldSimulation.state.research_allocations.infrastructure))
		assert_int(total()).is_less_equal(R.ATTENTION_STEPS)
		WorldSimulation.discovery.refresh_investigations()
		assert_bool("drainage" in WorldSimulation.state.active_investigations.values()).is_true()
	)
	assert_dict(GameState.research_allocations).is_equal(player_before)
func test_the_plan_is_not_bound_to_the_emphasis_it_found()->void:
	# Steps are shares, not a budget: a ruler that found no emphasis at all lays
	# out a whole plan, in the steps the player's screen uses.
	WorldSimulation.scoped("research_ruler",func()->void:
		configure("drainage",0);preload("res://scripts/opening_opportunities.gd").record("drainage",1000.0)
		C.research_orders("research_ruler",plan())
		assert_int(total()).is_greater(0)
		for value in WorldSimulation.state.research_allocations.values():assert_int(int(value)).is_between(0,12)
	)
func test_emphasis_gives_no_research_without_researchers()->void:
	WorldSimulation.scoped("research_ruler",func()->void:
		configure("drainage",12)
		for role:String in WorldSimulation.state.population_allocations:WorldSimulation.state.population_allocations[role]=0
		for sub:String in WorldSimulation.state.research_subcategory_allocations.security:
			assert_float(float(WorldSimulation.discovery.research_capacity_for("security",sub).progress_multiplier)).is_equal(0.0)
	)
func test_no_viable_questions_preserves_the_rulers_preferred_allocation()->void:
	WorldSimulation.scoped("research_ruler",func()->void:
		configure("",3);C.research_orders("research_ruler",plan())
		# Nothing is open anywhere: the ruler's own preference stands, its
		# favourite holding the most attention.
		for domain:String in S.DOMAINS:
			assert_int(int(WorldSimulation.state.research_allocations[domain])).is_between(0,12)
			if domain!="security":assert_int(int(WorldSimulation.state.research_allocations[domain])).is_less(int(WorldSimulation.state.research_allocations.security))
	)
