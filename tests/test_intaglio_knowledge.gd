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
func test_copper_to_impressions_consumes_ink_water_paper_and_reusable_tooling()->void:
	WorldSimulation.scoped("engraver",func()->void:
		var state=WorldSimulation.state
		state.resource_stockpiles.merge({"Refined Copper":2.0,"Stone":20.0,"Wrought Iron":20.0,"Timber":20.0,"Shaft Bearings":2.0,"Woven Cloth":2.0,"Paper":5.0,"Printing Ink":1.0,"Freshwater":2.0},true)
		for item:String in ["prepared_copperplates","drypoint_plates","drypoint_sheets"]:
			var recipe:=I.product(item);learn(recipe.gate)
			assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,job,float(recipe.days))
			assert_int(int(job.completed)).is_equal(1)
			WorldSimulation.military.cancel_equipment_job(int(job.id))
		assert_float(float(state.resource_stockpiles["Printed Sheets"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Copper Printing Plates"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Drypoint Plates"])).is_equal_approx(.9,.000001)
		assert_float(float(state.resource_stockpiles["Printing Ink"])).is_equal_approx(.88,.000001)
		assert_float(float(state.resource_stockpiles.Freshwater)).is_equal_approx(1.8,.000001)
		assert_float(float(state.resource_stockpiles.Paper)).is_equal(4.0)
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

func test_method_specific_plate_wear_is_paid_for_every_impression()->void:
	WorldSimulation.scoped("engraver",func()->void:
		for item:String in ["intaglio_sheets","drypoint_sheets","mezzotint_sheets","steel_intaglio_sheets"]:
			var recipe:=I.product(item);learn(recipe.gate);var state=WorldSimulation.state
			for resource:String in recipe.materials:state.resource_stockpiles[resource]=10.0
			for resource:String in recipe.tooling:state.resource_stockpiles[resource]=10.0
			var plate:=""
			for resource:String in recipe.materials:
				if resource.ends_with("Plates"):plate=resource
			state.resource_stockpiles[plate]=1.0
			state.resource_stockpiles["Printed Sheets"]=0.0
			assert_bool(WorldSimulation.military.start_production_line(item,2).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,job,float(recipe.days))
			var saved:Dictionary=JSON.parse_string(JSON.stringify(job))
			assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
			WorldSimulation.military.equipment_queue[-1]=saved
			P.advance(WorldSimulation.military,saved,float(recipe.days));P.advance(WorldSimulation.military,saved,10.0)
			assert_int(int(saved.completed)).is_equal(2)
			assert_float(float(state.resource_stockpiles[plate])).is_equal_approx(1.0-2.0*float(recipe.materials[plate]),.000001)
			WorldSimulation.military.cancel_equipment_job(int(job.id))
	)
