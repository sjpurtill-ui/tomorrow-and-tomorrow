extends GdUnitTestSuite
const K=preload("res://scripts/glassworking_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("glassworker",995)
func after_test()->void:WorldSimulation.clear()
func test_six_distinct_contracts_and_vessel_methods_are_civilian_goods()->void:
	WorldSimulation.scoped("glassworker",func()->void:
		assert_int(K.entries().size()).is_equal(6)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		# Vessel methods remain gated techniques, but vessels are Civilian Goods, not a workshop line.
		for item:String in ["core_glass_vessels","blown_glass_vessels","mold_glass_vessels","pressed_glass_vessels"]:
			var r:=I.product(item);WorldSimulation.state.known_discoveries.append(r.gate);WorldSimulation.state.discovery_adoption[r.gate]=1.0
			assert_str(String(P.recipe(WorldSimulation.military,item).get("error",""))).is_equal(P.CIVILIAN_ERROR)
			assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_false()
		assert_array(WorldSimulation.military.equipment_queue).is_empty()
	)
func test_hydrogen_flame_research_requires_a_hydrogen_production_route()->void:
	var requirements=preload("res://scripts/technology_requirements.gd")
	var spec:Dictionary={}
	for entry:Dictionary in K.entries():
		if entry.id=="hydrogen_flame_glassworking":spec=entry
	var known:Array=["glass_tube_drawing","chemical_distillation"]
	assert_bool(requirements.evaluate(spec,known).ready).is_false()
	for source:String in ["water_electrolysis","chloralkali_cells"]:
		known.append(source)
		assert_bool(requirements.evaluate(spec,known).ready).is_true()
		known.erase(source)
	known.append("water_electrolysis")
	known.erase("glass_tube_drawing")
	assert_bool(requirements.evaluate(spec,known).ready).is_false()


func test_live_hydrogen_flame_pathways_do_not_bypass_the_supply_foundation()->void:
	WorldSimulation.scoped("glassworker",func()->void:
		var entry:Dictionary=WorldSimulation.discovery.catalog_by_id["hydrogen_flame_glassworking"]
		var pathways=preload("res://scripts/knowledge_pathways.gd")
		var known:Array=["glass_tube_drawing","chemical_distillation"]
		assert_bool(pathways.chosen(entry,-1,known).is_empty()).is_true()
		for source:String in ["water_electrolysis","chloralkali_cells"]:
			known.append(source)
			assert_bool(pathways.chosen(entry,-1,known).is_empty()).is_false()
			known.erase(source)
	)
