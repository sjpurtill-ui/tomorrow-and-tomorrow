extends GdUnitTestSuite
const P=preload("res://scripts/knowledge_pathways.gd")
const R=preload("res://scripts/technology_requirements.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("scaling",318)
func after_test()->void:WorldSimulation.clear()
func reference_ready(entry:Dictionary,known:Variant,context:Dictionary,source:Dictionary)->bool:
	for route:Dictionary in P.routes_for(entry,known,context,source):
		if bool(route.ready) and float(route.support)+float(route.progress_multiplier)+(.05 if route.id=="local" else .1)>-1:return true
	return false
func test_boolean_pathways_match_descriptive_routes_across_catalog_and_missing_foundations()->void:
	WorldSimulation.scoped("scaling",func()->void:
		var all:Dictionary={}
		for entry in WorldSimulation.discovery.technology_catalog:all[entry.id]=true
		for entry in WorldSimulation.discovery.technology_catalog:
			var parents:=P.definition_parents(entry)
			var known:=R.index_known(parents)
			for membership:Variant in [{},known,all]:
				assert_bool(P.ready_for(entry,membership,{})).is_equal(reference_ready(entry,membership,{},{}))
			if not parents.is_empty():
				known.erase(parents[0])
				assert_bool(P.ready_for(entry,known,{})).is_equal(reference_ready(entry,known,{},{}))
	)
func test_experimental_support_imported_copies_and_score_floor_match()->void:
	var entry:={"id":"smoking","requires_all":["common"],"requires_any":[["a","b"],["c","d"]],"requires":["wood"],"signals":["fire","food"]}
	var item:={"id":"neighbor:smoking","kind":"knowledge","source_name":"Neighbor","source_id":"neighbor","discovery_id":"smoking"}
	for known:Array in [["common","a","c","charcoal"],["common","b","d","wood"],["charcoal"],[]]:
		for context:Dictionary in [{},{"fire":.499},{"fire":.5},{"fire":4.0,"food":-.5}]:
			for source:Dictionary in [{},item]:
				assert_bool(P.ready_for(entry,known,context,source)).is_equal(reference_ready(entry,known,context,source))
	entry.learning_routes=[{"id":"experimental_trial","label":"Trial","requires_all":["wood"],"requires_any":[[]],"progress_multiplier":-2.0}]
	for alternatives:Array in [[[]],[]]:
		entry.learning_routes[0].requires_any=alternatives
		for score:float in [-2.0,-1.1,-1.05,-1.0,0.0,1.0]:
			entry.learning_routes[0].progress_multiplier=score
			for source:Dictionary in [{},item]:
				for context:Dictionary in [{},{"fire":2}]:
					assert_bool(P.ready_for(entry,["common","a","c","wood"],context,source)).is_equal(reference_ready(entry,["common","a","c","wood"],context,source))
func test_bulk_preservation_matches_scalar_for_adoption_staffing_and_travel()->void:
	WorldSimulation.scoped("scaling",func()->void:
		var state:=WorldSimulation.state;var discovery:=WorldSimulation.discovery
		state.known_discoveries.clear()
		for entry in discovery.technology_catalog:
			state.known_discoveries.append(String(entry.id));state.discovery_adoption[entry.id]=float(posmod(String(entry.id).hash(),101))/100.0
		var types:Array=["Fresh plants","Fresh meat","Fish","Dry staples","Preserved food","Unknown food"]
		for settled in [false,true]:
			state.settlement_site_committed=settled
			for traveling in [false,true]:
				for workers in [0,20]:
					state.population_allocations.Logistics=workers;state.population_allocations.Crafting=workers
					var bulk:=discovery.food_storage_multipliers(types,traveling)
					for food:String in types:assert_float(bulk[food]).is_equal(discovery.food_storage_multiplier(food,traveling))
		state.discovery_adoption.clear()
		var unadopted:=discovery.food_storage_multipliers(types,false)
		for food:String in types:assert_float(unadopted[food]).is_equal(discovery.food_storage_multiplier(food,false))
	)
func test_public_material_profile_is_an_independent_copy()->void:
	WorldSimulation.scoped("scaling",func()->void:
		for resource in ["Timber","Copper Ore","Unlisted mineral"]:
			var before:=WorldSimulation.resources.material_profile(resource)
			var modified:=WorldSimulation.resources.material_profile(resource);modified.bulk=999
			assert_dict(WorldSimulation.resources.material_profile(resource)).is_equal(before)
	)
