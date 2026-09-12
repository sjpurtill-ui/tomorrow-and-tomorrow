extends GdUnitTestSuite
const C=preload("res://scripts/civilization_controller.gd")
const S=preload("res://scripts/civilization_strategy.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("research_ruler",91420)
func after_test()->void:WorldSimulation.clear()
func configure(remaining:String,budget:int)->void:
	for entry:Dictionary in WorldSimulation.discovery.technology_catalog:
		if entry.id!=remaining:WorldSimulation.state.known_discoveries.append(entry.id)
	for domain:String in S.DOMAINS:WorldSimulation.submit("research_ruler",{"kind":"research_emphasis","domain":domain,"weight":0})
	WorldSimulation.submit("research_ruler",{"kind":"research_emphasis","domain":"security","weight":budget})
func plan()->Dictionary:
	var weights:Dictionary={}
	for domain:String in S.DOMAINS:weights[domain]=.1
	weights.security=100.0
	return {"research_weights":weights,"goals":[{"title":"Defend the realm"}]}
func test_blocked_favorite_field_yields_to_a_live_foundation_without_extra_budget()->void:
	var player_before:=GameState.research_allocations.duplicate(true)
	WorldSimulation.scoped("research_ruler",func()->void:
		configure("drainage",3)
		C.research_orders("research_ruler",plan())
		assert_int(int(WorldSimulation.state.research_allocations.infrastructure)).is_equal(3)
		assert_int(int(WorldSimulation.state.research_allocations.security)).is_equal(0)
		var total:=0
		for value in WorldSimulation.state.research_allocations.values():total+=int(value)
		assert_int(total).is_equal(3)
		WorldSimulation.discovery.refresh_investigations()
		assert_bool("drainage" in WorldSimulation.state.active_investigations.values()).is_true()
	)
	assert_dict(GameState.research_allocations).is_equal(player_before)
func test_zero_emphasis_is_not_replaced_with_free_research()->void:
	WorldSimulation.scoped("research_ruler",func()->void:
		configure("drainage",0);C.research_orders("research_ruler",plan())
		for value in WorldSimulation.state.research_allocations.values():assert_int(int(value)).is_equal(0)
	)
func test_no_viable_questions_preserves_the_rulers_preferred_allocation()->void:
	WorldSimulation.scoped("research_ruler",func()->void:
		configure("",3);C.research_orders("research_ruler",plan())
		assert_int(int(WorldSimulation.state.research_allocations.security)).is_equal(3)
	)
