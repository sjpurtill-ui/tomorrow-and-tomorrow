extends GdUnitTestSuite
const F=preload("res://scripts/research_foundations.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("foundation_ruler",91420)
func after_test()->void:WorldSimulation.clear()
func entry(id:String,parents:Array)->Dictionary:
	var item:Dictionary=WorldSimulation.discovery.discovery_definition("cordage").duplicate(true)
	item.id=id;item.requires=parents;item.requires_all=parents;item.requires_any=[];item.resource_requirements=[]
	item.learning_routes=[{"id":"local","requires_all":[]}]
	# Synthetic graph nodes: no calendar age or design conditions of their own.
	item.erase("earliest_year");item.erase("conditions")
	return item
func install(items:Array)->void:
	WorldSimulation.discovery.technology_catalog.assign(items)
	WorldSimulation.state.known_discoveries.clear()
	WorldSimulation.state.resource_deposits.clear()
func test_shared_foundation_is_recommended_without_granting_knowledge()->void:
	WorldSimulation.scoped("foundation_ruler",func()->void:
		install([entry("root",[]),entry("a",["root"]),entry("b",["root"])])
		var result:=F.recommendation()
		assert_str(result.id).is_equal("root")
		assert_int(result.opens.size()).is_equal(2)
		assert_array(WorldSimulation.state.known_discoveries).is_empty()
	)
func test_other_missing_common_foundations_do_not_count_as_opened_questions()->void:
	WorldSimulation.scoped("foundation_ruler",func()->void:
		install([entry("root",[]),entry("a",["root","unavailable"]),entry("b",["root"])])
		assert_dict(F.recommendation()).is_empty()
	)
func test_missing_material_and_already_open_alternatives_do_not_inflate_value()->void:
	WorldSimulation.scoped("foundation_ruler",func()->void:
		var a:=entry("a",["root"]);a.resource_requirements=[{"resource":"Tin Ore","stage":"accessible"}]
		var b:=entry("b",[]);b.learning_routes=[{"id":"local","requires_all":["root"]},{"id":"other","requires_all":[]}]
		install([entry("root",[]),a,b,entry("c",["root"])])
		assert_dict(F.recommendation()).is_empty()
	)
func test_duplicate_routes_count_one_child_and_or_routes_remain_valid()->void:
	WorldSimulation.scoped("foundation_ruler",func()->void:
		var a:=entry("a",[]);a.requires_any=[["root","other"]]
		a.learning_routes=[{"id":"local","requires_all":[]},{"id":"second","requires_all":[]}]
		install([entry("root",[]),a])
		assert_dict(F.recommendation()).is_empty()
		WorldSimulation.discovery.technology_catalog.append(entry("b",["root"]))
		assert_int(F.recommendation().opens.size()).is_equal(2)
	)
func test_controller_selects_foundation_with_existing_budget_and_no_material_intervention()->void:
	var player_before:=GameState.research_allocations.duplicate(true)
	WorldSimulation.scoped("foundation_ruler",func()->void:
		var root:=entry("cordage",[])
		install([root,entry("a",["cordage"]),entry("b",["cordage"])])
		WorldSimulation.discovery.catalog_by_id.cordage=root
		var weights:Dictionary={}
		for domain:String in preload("res://scripts/civilization_strategy.gd").DOMAINS:
			weights[domain]=1.0
			WorldSimulation.submit("foundation_ruler",{"kind":"research_emphasis","domain":domain,"weight":0})
		WorldSimulation.submit("foundation_ruler",{"kind":"research_emphasis","domain":"security","weight":3})
		preload("res://scripts/civilization_controller.gd").research_orders("foundation_ruler",{"research_weights":weights,"goals":[{"title":"Broaden practical knowledge"}]})
		var total:=0
		for amount in WorldSimulation.state.research_allocations.values():total+=int(amount)
		assert_int(total).is_equal(3)
		assert_bool("cordage" in WorldSimulation.state.active_investigations.values()).is_true()
		assert_array(WorldSimulation.state.known_discoveries).is_empty()
	)
	assert_dict(GameState.research_allocations).is_equal(player_before)
