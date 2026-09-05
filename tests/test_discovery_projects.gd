extends GdUnitTestSuite


func before_test()->void:
	GameState.reset_for_new_world(314159)
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()


func _activate_project(discovery_id:String,observers:int=2)->Dictionary:
	var discovery:Dictionary=DiscoverySystem.discovery_definition(discovery_id)
	var dynamic_id:=String(discovery.dynamic)
	var subcategory:=String(discovery.subcategory)
	var allocations:Dictionary=GameState.research_subcategory_allocations.get(dynamic_id,{})
	allocations[subcategory]=observers
	GameState.research_subcategory_allocations[dynamic_id]=allocations
	GameState.active_investigations["%s::%s" % [dynamic_id,subcategory]]=discovery_id
	GameState.discovery_progress[discovery_id]=0.24
	return discovery


func test_active_project_explains_question_method_unlock_and_bottleneck()->void:
	var discovery:=_activate_project("seasonal_patterns")
	var records:=DiscoverySystem.active_investigation_records()
	var matches:=records.filter(func(record:Dictionary)->bool: return String(record.id)==String(discovery.id))
	assert_int(matches.size()).is_equal(1)
	var project:Dictionary=matches[0]
	assert_str(String(project.name)).is_equal(String(discovery.name))
	assert_str(String(project.discovery_name)).is_equal(String(discovery.name))
	assert_str(String(project.project_goal)).is_not_equal("")
	assert_str(String(project.project_method)).is_not_equal("")
	assert_str(String(project.unlock_summary)).is_not_equal("")
	assert_str(String(project.bottleneck)).is_not_equal("")
	assert_int(int(project.observer_allocation)).is_equal(2)
	assert_int(int(project.estimated_days)).is_greater(0)


func test_project_unlock_text_reports_real_bounded_effects()->void:
	var text:=DiscoverySystem._effect_summary({"food_output":0.012,"disease_exposure":-0.004})
	assert_str(text).contains("Food Output +1.2%")
	assert_str(text).contains("Disease Exposure -0.4%")


func test_macro_research_priority_auto_allocates_only_inside_the_chosen_domain()->void:
	for dynamic_id in GameState.research_allocations:
		GameState.research_allocations[dynamic_id]=0
		for subcategory in (GameState.research_subcategory_allocations[dynamic_id] as Dictionary):
			GameState.research_subcategory_allocations[dynamic_id][subcategory]=0
	DiscoverySystem.set_domain_research_priority("nutrition",5)
	var nutrition_total:=0
	var staffed_subcategories:=0
	for value in (GameState.research_subcategory_allocations.nutrition as Dictionary).values():
		nutrition_total+=int(value)
		if int(value)>0: staffed_subcategories+=1
	assert_int(nutrition_total).is_equal(5)
	assert_int(staffed_subcategories).is_between(1,4)
	assert_int(int(GameState.research_allocations.nutrition)).is_equal(5)
	for dynamic_id in GameState.research_subcategory_allocations:
		if String(dynamic_id)=="nutrition": continue
		var outside_total:=0
		for value in (GameState.research_subcategory_allocations[dynamic_id] as Dictionary).values(): outside_total+=int(value)
		assert_int(outside_total).is_equal(0)
	DiscoverySystem.set_domain_research_priority("nutrition",2)
	nutrition_total=0
	for value in (GameState.research_subcategory_allocations.nutrition as Dictionary).values(): nutrition_total+=int(value)
	assert_int(nutrition_total).is_equal(2)


func test_billion_population_does_not_create_additional_research_records()->void:
	var fixed_catalog_size:=DiscoverySystem.catalog.size()
	assert_int(fixed_catalog_size).is_greater_equal(4_608)
	var small_capacity:=float(DiscoverySystem.research_capacity_for("knowledge","Preserved knowledge").progress_multiplier)
	GameState.ensure_population_total(1_000_000_000)
	_activate_project("seasonal_patterns",1)
	DiscoverySystem.refresh_investigations()
	var planetary_capacity:=float(DiscoverySystem.research_capacity_for("knowledge","Preserved knowledge").progress_multiplier)
	assert_int(DiscoverySystem.catalog.size()).is_equal(fixed_catalog_size)
	assert_int(GameState.active_investigations.size()).is_less_equal(48)
	assert_float(planetary_capacity).is_greater(small_capacity)
	assert_int(int(DiscoverySystem.research_program_summary().researchers)).is_greater(10_000_000)


func test_research_priority_divides_the_aggregate_workforce_and_shapes_throughput()->void:
	for dynamic_id in GameState.research_subcategory_allocations:
		for subcategory in (GameState.research_subcategory_allocations[dynamic_id] as Dictionary):
			GameState.research_subcategory_allocations[dynamic_id][subcategory]=0
	GameState.research_subcategory_allocations.knowledge["Preserved knowledge"]=3
	GameState.research_subcategory_allocations.security["Military readiness"]=1
	GameState.ensure_population_total(100_000)
	var records_capacity:=DiscoverySystem.research_capacity_for("knowledge","Preserved knowledge")
	var military_capacity:=DiscoverySystem.research_capacity_for("security","Military readiness")
	assert_float(float(records_capacity.workforce_share)).is_equal_approx(0.75,0.0001)
	assert_float(float(military_capacity.workforce_share)).is_equal_approx(0.25,0.0001)
	assert_float(float(records_capacity.researchers)).is_equal_approx(float(military_capacity.researchers)*3.0,0.1)
	assert_float(float(records_capacity.progress_multiplier)).is_greater(float(military_capacity.progress_multiplier))
	var summary:=DiscoverySystem.research_program_summary()
	assert_int(int(summary.active_lines)).is_equal(2)
	assert_int(int(summary.emphasis_total)).is_equal(4)


func test_thousands_of_hidden_routes_resolve_into_concrete_non_repetitive_milestones()->void:
	var frontier:Array=(DiscoverySystem.catalog as Array).filter(func(discovery:Dictionary)->bool: return bool(discovery.get("frontier",false)))
	assert_int(frontier.size()).is_equal(4_608)
	var names:Dictionary={}
	var mechanisms:Dictionary={}
	var observations:Dictionary={}
	var milestones:Dictionary={}
	var threads:Dictionary={}
	var routes:Dictionary={}
	var discoveries_per_thread:Dictionary={}
	var modern_count:=0
	for discovery_variant in frontier:
		var discovery:Dictionary=discovery_variant
		var name:=String(discovery.get("name",""))
		names[name]=true
		mechanisms[String(discovery.get("mechanism_signature",""))]=true
		observations[String(discovery.get("observation",""))]=true
		var milestone_key:=String(discovery.get("milestone_key",""))
		milestones[milestone_key]=true
		var thread_key:=String(discovery.get("thread_key",""))
		threads[thread_key]=true
		routes[String(discovery.get("route_key",""))]=true
		discoveries_per_thread[thread_key]=int(discoveries_per_thread.get(thread_key,0))+1
		assert_str(name).is_not_empty()
		for forbidden_prefix in ["Mapped ","Compared ","Repeated ","Standardized ","Measured ","Validated "]:
			assert_bool(name.begins_with(forbidden_prefix)).is_false()
		assert_str(String(discovery.get("observation",""))).contains("The established practice is")
		assert_str(String(discovery.get("observation",""))).contains("Core finding:")
		assert_str(String(discovery.get("observation",""))).contains("New operating capability:")
		assert_str(String(discovery.get("observation",""))).contains("Social consequence:")
		assert_str(String(discovery.get("social_consequence",""))).is_not_empty()
		assert_str(String(discovery.get("ability_reason",""))).starts_with("Because ")
		assert_str(String(discovery.get("line_name",""))).is_not_empty()
		if int(discovery.get("maturity",0))==12:
			modern_count+=1
			assert_bool(name.ends_with("Integrated Science")).is_true()
	assert_int(names.size()).is_equal(4_608)
	assert_int(mechanisms.size()).is_equal(4_608)
	assert_int(observations.size()).is_equal(4_608)
	assert_int(milestones.size()).is_equal(4_608)
	assert_int(threads.size()).is_equal(48)
	assert_int(routes.size()).is_equal(384)
	for discovery_count in discoveries_per_thread.values(): assert_int(int(discovery_count)).is_equal(96)
	assert_int(modern_count).is_equal(384)


func test_established_library_consolidates_legacy_permutation_spam_into_one_knowledge_line()->void:
	var selected:Array=[]
	for discovery_variant in DiscoverySystem.catalog:
		var discovery:Dictionary=discovery_variant
		if not bool(discovery.get("frontier",false)): continue
		if String(discovery.get("dynamic",""))!="culture" or String(discovery.get("subcategory",""))!="Collective memory": continue
		if int(discovery.get("lens_index",-1))!=7: continue
		if int(discovery.get("maturity",0))>6: continue
		selected.append(discovery)
	selected.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.maturity)<int(b.maturity))
	for discovery_variant in selected:
		var discovery:Dictionary=discovery_variant
		GameState.known_discoveries.append(String(discovery.id))
		GameState.discovery_log.push_front({"id":discovery.id,"day":int(discovery.day),"name":"Compared Regional Dated Oral History Recitations","description":"legacy procedural wording"})
	var threads:=DiscoverySystem.established_knowledge_threads()
	assert_int(threads.size()).is_equal(1)
	var thread:Dictionary=threads[0]
	assert_str(String(thread.name)).is_equal("Dated Oral History Recitations")
	assert_int(int(thread.breakthrough_count)).is_equal(6)
	assert_str(String(thread.latest_breakthrough)).not_contains("Compared Regional")
	assert_str(String(thread.record_summary)).contains("6 historical refinements")


func test_emphasis_selects_the_live_frontier_without_exposing_hidden_catalog()->void:
	for dynamic_id in GameState.research_subcategory_allocations:
		for subcategory in (GameState.research_subcategory_allocations[dynamic_id] as Dictionary):
			GameState.research_subcategory_allocations[dynamic_id][subcategory]=0
	GameState.research_subcategory_allocations.knowledge["Preserved knowledge"]=3
	DiscoverySystem.refresh_investigations()
	assert_int(GameState.active_investigations.size()).is_equal(1)
	assert_bool(GameState.active_investigations.has("knowledge::Preserved knowledge")).is_true()
	var snapshot:=DiscoverySystem.frontier_snapshot("knowledge")
	assert_bool(bool(snapshot.catalog_hidden)).is_true()
	assert_bool(snapshot.has("total_count")).is_false()
	assert_int(int(snapshot.active.size())).is_equal(1)
	assert_str(String(snapshot.opportunity_signal)).is_not_empty()


func test_completed_line_redirects_observers_without_player_micromanagement()->void:
	for dynamic_id in GameState.research_subcategory_allocations:
		for subcategory in (GameState.research_subcategory_allocations[dynamic_id] as Dictionary):
			GameState.research_subcategory_allocations[dynamic_id][subcategory]=0
	var exhausted_channel:="knowledge::Preserved knowledge"
	GameState.research_subcategory_allocations.knowledge["Preserved knowledge"]=3
	GameState.research_allocations.knowledge=3
	GameState.elapsed_days=5000.0
	for definition_variant in (DiscoverySystem.catalog_by_channel.get(exhausted_channel,[]) as Array):
		var definition:Dictionary=definition_variant
		var id:=String(definition.get("id",""))
		if id!="" and id not in GameState.known_discoveries: GameState.known_discoveries.append(id)
	DiscoverySystem.refresh_investigations()
	assert_int(int(GameState.research_subcategory_allocations.knowledge["Preserved knowledge"])).is_equal(0)
	var redirected_total:=0
	for value in (GameState.research_subcategory_allocations.knowledge as Dictionary).values(): redirected_total+=int(value)
	assert_int(redirected_total).is_equal(3)
	for dynamic_id in GameState.research_subcategory_allocations:
		if String(dynamic_id)=="knowledge": continue
		for value in (GameState.research_subcategory_allocations[dynamic_id] as Dictionary).values(): assert_int(int(value)).is_equal(0)
	assert_int(GameState.active_investigations.size()).is_greater(0)
