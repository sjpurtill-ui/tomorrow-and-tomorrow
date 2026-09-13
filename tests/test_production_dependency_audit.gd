extends GdUnitTestSuite
const Audit=preload("res://tools/production_dependency_audit.gd")
func recipe(output:String,materials:Dictionary={},tooling:Dictionary={},power:float=0)->Dictionary:
	return {"output":output,"gate":"method","materials":materials,"tooling":tooling,"power":power,"days":1.0}
func generator(cost:Dictionary)->Dictionary:
	return {"gate":"method","requires":[],"cost":cost,"inputs":{},"power":0.0,"services":{"electricity":1.0}}
func test_missing_stock_names_are_reported_instead_of_assumed()->void:
	var result:=Audit.audit({"lens":recipe("Lens",{"Imaginary Copper":1.0})},{},["Copper Ore"],["method"])
	assert_array(result.errors).contains(["lens: no source for Imaginary Copper (materials)"])
	assert_bool(result.closure_performed).is_false()
func test_self_tooling_cycle_requires_a_separate_bootstrap_recipe()->void:
	var products:={"precision":recipe("Tool",{"Ore":1.0},{"Tool":1.0})}
	assert_bool(Audit.audit(products,{},["Ore"],["method"]).blocked_products.has("precision")).is_true()
	products.simple=recipe("Tool",{"Ore":2.0})
	var before:=products.duplicate(true)
	assert_dict(Audit.audit(products,{},["Ore"],["method"]).blocked_products).is_empty()
	assert_dict(products).is_equal(before)
func test_electric_bootstrap_cycle_cannot_use_its_own_unbuilt_generator()->void:
	var products:={"solar":recipe("Solar Module",{"Ore":1.0},{},1.0)}
	var plants:={"solar":generator({"Solar Module":1.0})}
	var blocked:=Audit.audit(products,plants,["Ore"],["method"])
	assert_bool(blocked.blocked_products.has("solar")).is_true();assert_bool(blocked.blocked_plants.has("solar")).is_true()
	plants.steam=generator({"Ore":2.0})
	var reachable:=Audit.audit(products,plants,["Ore"],["method"])
	assert_dict(reachable.blocked_products).is_empty();assert_dict(reachable.blocked_plants).is_empty()
func test_coproducts_are_usable_only_after_their_recipe_is_fabricable()->void:
	var products:={"electrolysis":recipe("Hydrogen",{"Water":1.0},{},1.0),"oxygen_process":recipe("Useful Product",{"Oxygen":1.0})}
	products.electrolysis.co_products={"Oxygen":1.0}
	assert_bool(Audit.audit(products,{},["Water"],["method"]).blocked_products.has("oxygen_process")).is_true()
	var result:=Audit.audit(products,{"generator":generator({"Water":1.0})},["Water"],["method"])
	assert_dict(result.blocked_products).is_empty()
func test_empty_storage_is_not_a_source_of_electricity()->void:
	var products:={"powered":recipe("Product",{"Ore":1.0},{},1.0)}
	var bank:=generator({"Ore":1.0});bank.services={};bank.storage={"capacity":12.0}
	assert_bool(Audit.audit(products,{"bank":bank},["Ore"],["method"]).blocked_products.has("powered")).is_true()
func test_live_civilian_products_and_installations_have_structural_supply_paths()->void:
	var ids:Array=[];DiscoverySystem.initialize()
	for entry:Dictionary in DiscoverySystem.technology_catalog:ids.append(entry.id)
	var result:=Audit.audit(preload("res://scripts/civilian_industry.gd").PRODUCTS,preload("res://scripts/technology_operations.gd").PLANTS,ResourceSystem.catalog.keys()+preload("res://scripts/household_clothing.gd").HUNTING_BYPRODUCTS.keys(),ids,preload("res://scripts/nmr_acquisition.gd").dependency_routes())
	assert_array(result.errors).is_empty();assert_dict(result.blocked_products).is_empty();assert_dict(result.blocked_plants).is_empty()
	assert_int(int(result.reachable_products)).is_equal(int(result.product_count))

func test_invalid_quantities_work_and_power_are_rejected()->void:
	for field:String in ["days","power"]:
		var invalid:=recipe("Output",{"Ore":1.0});invalid[field]=NAN
		assert_array(Audit.audit({"invalid":invalid},{},["Ore"],["method"]).errors).is_not_empty()
	var invalid:=recipe("Output",{"Ore":-1.0})
	assert_array(Audit.audit({"invalid":invalid},{},["Ore"],["method"]).errors).is_not_empty()
	var plant:=generator({"Ore":-1.0})
	assert_array(Audit.audit({}, {"invalid":plant},["Ore"],["method"]).errors).is_not_empty()

func test_malformed_numeric_values_never_run_dependency_closure()->void:
	for value:Variant in ["many",true,null,[],{}]:
		for field:String in ["days","power"]:
			var invalid:=recipe("Output",{"Ore":1.0});invalid[field]=value
			var result:=Audit.audit({"invalid":invalid},{},["Ore"],["method"])
			assert_array(result.errors).is_not_empty();assert_bool(result.closure_performed).is_false()
			assert_int(int(result.reachable_products)).is_equal(0)
		var invalid:=recipe("Output",{"Ore":value})
		assert_bool(Audit.audit({"invalid":invalid},{},["Ore"],["method"]).closure_performed).is_false()
		var plant:=generator({"Ore":1.0});plant.services.electricity=value
		assert_bool(Audit.audit({}, {"invalid":plant},["Ore"],["method"]).closure_performed).is_false()
func test_unknown_gate_cannot_be_reported_as_reachable_production()->void:
	var result:=Audit.audit({"unknown":recipe("Output",{"Ore":1.0})},{},["Ore"],[])
	assert_array(result.errors).is_not_empty();assert_bool(result.closure_performed).is_false()
	assert_int(int(result.rounds)).is_equal(0)

func test_analytical_outputs_require_samples_references_and_operating_bench()->void:
	var products:={"consumer":recipe("Part",{"Measured Sample":1.0}),"reference":recipe("Reference",{"Ore":1.0})}
	var analysis:=recipe("Measured Sample",{"Sample":1.0,"Reference":1.0})
	analysis["services"]={"bench_time":4.0};analysis["requires"]=["solution_method"]
	var plant:=generator({"Ore":1.0});plant.services={"bench_time":1.0};plant.power=1.0
	var routes:={"assay":analysis};var ids:=["method","solution_method"]
	var blocked:=Audit.audit(products,{"bench":plant},["Ore","Sample"],ids,routes)
	assert_bool(blocked.blocked_products.has("consumer")).is_true()
	var passed:=Audit.audit(products,{"bench":plant,"generator":generator({"Ore":1.0})},["Ore","Sample"],ids,routes)
	assert_dict(passed.blocked_products).is_empty()
	assert_bool(passed.conditional_analysis_success_assumed).is_true()
	assert_bool(passed.campaign_verified).is_false()
	var missing_reference:=products.duplicate(true);missing_reference.erase("reference")
	assert_array(Audit.audit(missing_reference,{"bench":plant},["Ore","Sample"],ids,routes).errors).is_not_empty()
	assert_array(Audit.audit(products,{"bench":plant},["Ore","Sample"],["method"],routes).errors).contains(["assay: unknown discovery solution_method"])
