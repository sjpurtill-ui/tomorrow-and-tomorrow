extends GdUnitTestSuite
const K=preload("res://scripts/intaglio_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("engraver",996)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_plate_methods_reconverge_without_requiring_relief_printing()->void:
	WorldSimulation.scoped("engraver",func()->void:
		assert_int(K.entries().size()).is_equal(6)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var graph:Dictionary=preload("res://scripts/knowledge_pathways.gd").graph_entry(K.entries().back()).learning_routes[0]
		var known:Array=["paper_making","oil_based_printing_inks","bearing_surfaces"]
		var requirements=preload("res://scripts/technology_requirements.gd")
		assert_bool(requirements.evaluate(graph,known).ready).is_false()
		for method:String in ["burin_engraving","drypoint_printmaking","mezzotint_printmaking","steelplate_engraving"]:
			var branch:=known.duplicate();branch.append(method)
			assert_bool(requirements.evaluate(graph,branch).ready).is_true()
	)
func test_relief_forms_cannot_replace_intaglio_plate_tooling()->void:
	WorldSimulation.scoped("engraver",func()->void:
		var recipe:=I.product("intaglio_sheets");learn(recipe.gate);var state=WorldSimulation.state
		for resource:String in recipe.materials:state.resource_stockpiles[resource]=10.0
		for resource:String in recipe.tooling:state.resource_stockpiles[resource]=10.0
		state.resource_stockpiles["Engraved Copper Plates"]=0.0;state.resource_stockpiles["Printing Forms"]=10.0
		assert_bool(WorldSimulation.military.start_production_line("intaglio_sheets",1).get("ok",false)).is_false()
		assert_float(float(state.resource_stockpiles["Printing Forms"])).is_equal(10.0)
	)
