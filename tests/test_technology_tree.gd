extends GdUnitTestSuite
func before_test()->void:
	GameState.reset_for_new_world(314159)
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
	CivilizationSystem.set_process(false)
func after_test()->void:
	GameState.elapsed_days=0.0
	CivilizationSystem.set_process(true)
func test_playable_tree_is_finite_unique_and_has_every_domain()->void:
	var ids:Dictionary={}
	var domains:Dictionary={}
	for entry in DiscoverySystem.technology_tree():
		assert_bool(ids.has(String(entry.id))).is_false()
		ids[String(entry.id)]=true
		domains[String(entry.dynamic)]=true
		assert_bool(bool(entry.get("frontier",false))).is_false()
		for parent in entry.get("requires",[]): assert_bool(DiscoverySystem.catalog_by_id.has(String(parent))).is_true()
		assert_int(DiscoverySystem.technology_depth(String(entry.id))).is_less(30)
	assert_int(ids.size()).is_greater(100)
	assert_int(domains.size()).is_equal(12)
func test_legacy_refinements_cannot_be_researched_again()->void:
	GameState.elapsed_days=2000000.0
	for entry in DiscoverySystem.catalog:
		if bool(entry.get("frontier",false)): assert_bool(DiscoverySystem._discovery_is_eligible(entry,2000000)).is_false()
func test_random_difficulty_is_bounded_reproducible_and_balanced()->void:
	var tech:=DiscoverySystem.discovery_definition("copper_smelting")
	var values:Dictionary={}
	var sum:=0.0
	for seed_value in 500:
		var value:=DiscoverySystem.research_difficulty(tech,seed_value)
		assert_float(value).is_between(0.85,1.15)
		assert_float(value).is_equal(DiscoverySystem.research_difficulty(tech,seed_value))
		values[value]=true
		sum+=value
	assert_int(values.size()).is_greater(400)
	assert_float(sum/500.0).is_between(0.97,1.03)
func test_randomness_cannot_bypass_metallurgy_prerequisites_or_materials()->void:
	GameState.elapsed_days=100000.0
	var tech:=DiscoverySystem.discovery_definition("bronze_alloying")
	assert_bool(DiscoverySystem._discovery_is_eligible(tech,100000)).is_false()
	GameState.known_discoveries.append("copper_casting")
	GameState.resource_deposits=[]
	assert_bool(DiscoverySystem._discovery_is_eligible(tech,100000)).is_false()
func test_rival_paths_differ_but_only_choose_viable_technologies()->void:
	GameState.elapsed_days=100000.0
	var choices:Dictionary={}
	for seed_value in 24:
		var civ:={"production":1.0,"logistics":1.0,"environment_profile":{"resource_potentials":{}},"discovery_profile":{"seed":seed_value,"technologies":[]}}
		var options:=DiscoverySystem.rival_research_candidates(civ,"knowledge")
		assert_int(options.size()).is_greater(0)
		choices[String(options[0].id)]=true
		for entry in options: assert_array(entry.requires).is_empty()
		for entry in DiscoverySystem.rival_research_candidates(civ,"production"): assert_bool(String(entry.id)=="bronze_alloying").is_false()
	assert_int(choices.size()).is_greater(1)
func test_explicit_target_preserves_unfinished_progress()->void:
	GameState.elapsed_days=1000.0
	GameState.discovery_progress["tallies"]=0.43
	assert_bool(bool(DiscoverySystem.select_research_target("tallies").ok)).is_true()
	DiscoverySystem.refresh_investigations()
	assert_str(String(GameState.active_investigations["knowledge::Preserved knowledge"])).is_equal("tallies")
	assert_float(float(GameState.discovery_progress.tallies)).is_equal(0.43)
	assert_bool(bool(DiscoverySystem.select_research_target("blast_furnace").ok)).is_false()
func test_material_tech_cannot_repeat_once_known()->void:
	GameState.known_discoveries.append("tallies")
	assert_bool(DiscoverySystem._discovery_is_eligible(DiscoverySystem.discovery_definition("tallies"),99999)).is_false()
func test_geography_changes_affinity_without_changing_cost_bound()->void:
	var tech:=DiscoverySystem.discovery_definition("caravanserais")
	assert_float(DiscoverySystem.research_affinity(tech,42,{"route_potential":1.0})).is_greater(DiscoverySystem.research_affinity(tech,42,{"route_potential":0.0}))

func test_prerequisite_graph_has_alternative_branches_and_no_cycles()->void:
	var remaining:Dictionary={}
	var completed:Dictionary={}
	var children:Dictionary={}
	for tech in DiscoverySystem.technology_catalog:
		remaining[String(tech.id)]=tech
		for parent in tech.get("requires",[]): children[String(parent)]=int(children.get(String(parent),0))+1
	var branched:=0
	for count in children.values():
		if int(count)>1: branched+=1
	assert_int(branched).is_greater(10)
	for pass_index in DiscoverySystem.technology_catalog.size():
		var advanced:=false
		for id in remaining.keys():
			var ready:=true
			for parent in remaining[id].get("requires",[]):
				if not completed.has(String(parent)): ready=false; break
			if ready:
				completed[id]=true
				remaining.erase(id)
				advanced=true
		if not advanced: break
	assert_dict(remaining).is_empty()
