extends GdUnitTestSuite
const R=preload("res://scripts/technology_requirements.gd")
const D=preload("res://tools/technology-review/dormant_or_audit.gd")
const K=preload("res://scripts/field_botany_knowledge.gd")
func graph()->Array:
	var result:Array=[{"id":"experimental_controls"},{"id":"crop_calendars"},{"id":"biological_classification"}]
	for entry:Dictionary in K.entries():
		if entry.id in ["plant_transpiration_measurement","plant_pathology_diagnosis"]:result.append(entry)
	return result
func test_explicit_authored_dormant_or_preserves_exact_runtime_graph_and_predicates()->void:
	var catalog:=graph();var before:=catalog.duplicate(true)
	assert_int(R.validate(catalog).size()).is_equal(2)
	assert_array(R.validate(catalog,D.pending(catalog))).is_empty()
	assert_array(catalog).is_equal(before)
	assert_bool(R.evaluate(catalog[3],["experimental_controls"]).ready).is_false()
	assert_bool(R.evaluate(catalog[3],["experimental_controls","crop_calendars"]).ready).is_true()
	assert_array(R.parents(catalog[3])).contains(["experimental_controls","photosynthetic_process_analysis","crop_calendars"])
func test_unknown_malformed_duplicate_and_changed_authored_edges_are_rejected()->void:
	var catalog:=graph()
	for declarations:Array in [[{}],[{"child":"plant_transpiration_measurement","parent":"invented","group":["invented","crop_calendars"]}], [D.DECLARATIONS[0],D.DECLARATIONS[0]]]:
		assert_array(R.validate(catalog,declarations)).is_not_empty()
	catalog[3].requires_all.append("photosynthetic_process_analysis")
	assert_array(R.validate(catalog,D.DECLARATIONS)).is_not_empty()
	catalog=graph();catalog[3].requires_any[0].append("invented")
	assert_array(R.validate(catalog,D.DECLARATIONS)).is_not_empty()
func test_missing_live_alternative_and_unreachable_cycle_still_fail()->void:
	var catalog:=graph();catalog.remove_at(1)
	assert_array(R.validate(catalog,D.DECLARATIONS)).is_not_empty()
	catalog=graph();catalog[1].requires_all=["plant_transpiration_measurement"]
	var errors:=R.validate(catalog,D.DECLARATIONS)
	assert_array(errors).contains(["plant_transpiration_measurement: dormant OR has no reachable live alternative"])
	assert_array(errors).contains(["plant_transpiration_measurement: no reachable causal route (cycle or missing foundation)"])
func test_route_and_common_and_requirements_are_never_exempted()->void:
	var catalog:=graph()
	catalog[3].learning_routes=[{"id":"local","requires_all":["photosynthetic_process_analysis"]}]
	var errors:=R.validate(catalog,D.DECLARATIONS)
	assert_array(errors).contains(["plant_transpiration_measurement: unknown prerequisite photosynthetic_process_analysis"])
	catalog=graph();catalog[0].requires_all=["missing_instrument"]
	assert_array(R.validate(catalog,D.DECLARATIONS)).contains(["experimental_controls: unknown prerequisite missing_instrument"])
func test_expanded_route_factorization_preserves_predicates_and_acquisition_requirements()->void:
	var catalog:=graph();var expanded:Array=[]
	for entry:Dictionary in catalog:
		if String(entry.id).begins_with("plant_"):expanded.append(preload("res://scripts/knowledge_pathways.gd").graph_entry(entry))
		else:expanded.append(entry.duplicate(true))
	var before:=expanded.duplicate(true)
	var factored:=D.factor_common(expanded,catalog)
	assert_array(R.validate(factored,D.pending(factored))).is_empty()
	assert_array(expanded).is_equal(before)
	for known:Array in [[],["experimental_controls"],["experimental_controls","crop_calendars"],["biological_classification","experimental_controls"]]:
		for index:int in [3,4]:
			var expanded_ready:bool=R.evaluate(expanded[index].learning_routes[0],known).ready
			var factored_ready:bool=R.evaluate(factored[index],known).ready and R.evaluate(factored[index].learning_routes[0],known).ready
			assert_bool(factored_ready).is_equal(expanded_ready)
	expanded[3].learning_routes[0].requires_all.push_front("missing_local_instrument")
	factored=D.factor_common(expanded,catalog)
	assert_array(R.validate(factored,D.pending(factored))).contains(["plant_transpiration_measurement: unknown prerequisite missing_local_instrument"])
