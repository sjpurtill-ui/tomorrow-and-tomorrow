class_name ProgressionSystemTest
extends GdUnitTestSuite

const CATALOG:=preload("res://scripts/civilization_progression_catalog.gd")


func before_test()->void:
	CivilizationSystem.set_process(false)
	GameState.reset_for_new_world(602214)
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
	CivilizationSystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()


func after_test()->void:
	GameState.elapsed_days=0.0
	CivilizationSystem.set_process(true)

func test_discovery_field_contains_thousands_without_becoming_a_visible_checklist()->void:
	assert_int(CATALOG.DOMAINS.size()).is_equal(12)
	assert_int(DiscoverySystem.catalog.size()).is_greater_equal(4_608)
	var counts:Dictionary={}
	for domain in CATALOG.DOMAINS: counts[domain]=0
	for definition_variant in DiscoverySystem.catalog:
		var definition:Dictionary=definition_variant
		var domain:=String(definition.get("dynamic",""))
		if domain in CATALOG.DOMAINS: counts[domain]=int(counts[domain])+1
	for domain in CATALOG.DOMAINS: assert_int(int(counts[domain])).is_greater_equal(384)
	var snapshot:=ProgressionSystem.tree_snapshot()
	assert_bool(bool(snapshot.catalog_hidden)).is_true()
	assert_bool(snapshot.has("total_count")).is_false()
	for record_variant in snapshot.domains:
		assert_bool((record_variant as Dictionary).has("nodes")).is_false()


func test_world_seed_changes_viable_traditions_but_is_reproducible()->void:
	var channel:="nutrition::Daily supply"
	var first:=DiscoverySystem.candidate_ids_for_channel(channel,602214,48)
	var repeat:=DiscoverySystem.candidate_ids_for_channel(channel,602214,48)
	var other:=DiscoverySystem.candidate_ids_for_channel(channel,919191,48)
	assert_array(first).is_equal(repeat)
	assert_array(first).is_not_equal(other)
	assert_int(first.size()).is_greater_equal(2)
	for id in first: assert_bool(bool(DiscoverySystem.discovery_definition(id).get("frontier",false))).is_false()


func test_population_alone_never_creates_civilizational_capability()->void:
	GameState.ensure_population_total(12_000_000_000)
	ProgressionSystem.process_day(0)
	for domain in CATALOG.DOMAINS:
		assert_int(ProgressionSystem.domain_tier(domain)).is_equal(0)
		var next:Dictionary=ProgressionSystem.node_status(domain,1)
		assert_bool(bool(next.unlocked)).is_false()
		assert_int((next.blockers as Array).size()).is_greater(0)


func test_player_can_reach_planetary_scale_from_broad_mature_discovery_bodies()->void:
	GameState.ensure_population_total(12_000_000_000)
	GameState.settlement_site_committed=true
	GameState.player_settlements.clear()
	for index in 64: GameState.player_settlements.append({"id":index+1,"population":187_500_000.0})
	for domain in CATALOG.DOMAINS: GameState.society_capacities[domain]=0.96
	var selected_counts:Dictionary={}
	for domain in CATALOG.DOMAINS: selected_counts[domain]=0
	# Four early maturities across every subcondition and tradition establish
	# breadth; the integrated-science records establish deep mature traditions.
	for definition_variant in DiscoverySystem.catalog:
		var definition:Dictionary=definition_variant
		var domain:=String(definition.get("dynamic",""))
		if domain not in CATALOG.DOMAINS or not bool(definition.get("frontier",false)): continue
		var maturity:=int(definition.get("maturity",0))
		if maturity>4 and maturity!=12: continue
		if int(selected_counts[domain])>=160: continue
		var id:=String(definition.id)
		GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=0.82
		selected_counts[domain]=int(selected_counts[domain])+1
	CivilizationSystem.player_territory_balance=4.0
	CivilizationSystem.revealed_areas=[{"x":0.0,"z":0.0,"radius":25_000.0,"source":"planetary chart","day":0}]
	for index in CivilizationSystem.civilizations.size(): CivilizationSystem.civilizations[index].player_relation["contact_level"]=2
	ProgressionSystem.reset_for_new_world()
	ProgressionSystem.process_day(0)
	for domain in CATALOG.DOMAINS:
		assert_int(int(selected_counts[domain])).is_greater_equal(144)
		assert_int(ProgressionSystem.domain_tier(domain)).is_equal(8)
	assert_int(ProgressionSystem.domain_levels.size()).is_equal(12)
	assert_int(ProgressionSystem.unlock_log.size()).is_less_equal(ProgressionSystem.MAX_TRANSITION_LOG)
	assert_array(ProgressionSystem.validate_state()).is_empty()


func _planetary_rival_profile(civ_id:String)->Dictionary:
	var profile:=ProgressionSystem.initial_rival_discovery_profile(civ_id,"inquiry","inquiry")
	for domain in CATALOG.DOMAINS:
		profile.domains[domain]["count"]=160
		profile.domains[domain]["maturity"]=12
		profile.domains[domain]["breadth"]=4
		profile.domains[domain]["lens_count"]=8
		profile.domains[domain]["adoption"]=0.82
	return profile


func test_computer_civilizations_pay_the_same_discovery_and_reach_requirements()->void:
	var population:=12_000_000_000.0
	var civ:Dictionary={
		"id":"test_rival","population":population,"food_capacity":population*1.20,"food_days":120.0,
		"health":0.96,"cohesion":0.96,"knowledge":0.96,"production":0.96,"logistics":0.96,
		"institutions":0.96,"ecology":0.96,"military_readiness":0.96,"territory":4.0,
		"settlement_count":256,"world_reach":0.50,"adaptability":0.9,"founding_focus":"inquiry",
		"strategy":"inquiry","allocations":CivilizationSystem._allocation_for("inquiry"),
		"progression_tiers":CivilizationSystem._initial_progression_tiers(),
		"discovery_profile":_planetary_rival_profile("test_rival")
	}
	var blocked:=ProgressionSystem.advance_rival(civ)
	for domain in CATALOG.DOMAINS: assert_int(int(blocked.progression_tiers[domain])).is_less(8)
	civ["world_reach"]=1.0
	var planetary:=ProgressionSystem.advance_rival(civ)
	for domain in CATALOG.DOMAINS: assert_int(int(planetary.progression_tiers[domain])).is_equal(8)


func test_rival_focuses_create_divergent_bounded_discovery_histories()->void:
	var provision:Dictionary={"id":"provisioner","population":800.0,"food_capacity":900.0,"food_days":50.0,"health":0.75,"cohesion":0.65,"knowledge":0.32,"production":0.28,"logistics":0.25,"institutions":0.30,"ecology":0.75,"military_readiness":0.45,"territory":1.0,"settlement_count":2,"world_reach":0.05,"adaptability":0.55,"founding_focus":"provision","strategy":"sustenance","allocations":CivilizationSystem._allocation_for("sustenance"),"progression_tiers":CivilizationSystem._initial_progression_tiers()}
	var defense:=provision.duplicate(true)
	defense["id"]="defender"
	defense["founding_focus"]="defense"
	defense["strategy"]="fortification"
	defense["allocations"]=CivilizationSystem._allocation_for("fortification")
	for _month in 60:
		GameState.elapsed_days=float((_month+1)*30)
		provision=ProgressionSystem.advance_rival(provision)
		defense=ProgressionSystem.advance_rival(defense)
	var provision_domains:Dictionary=provision.discovery_profile.domains
	var defense_domains:Dictionary=defense.discovery_profile.domains
	assert_int(int(provision_domains.nutrition.count)).is_greater(int(defense_domains.nutrition.count))
	assert_float(float(defense.discovery_profile.emphasis.security)).is_greater(float(provision.discovery_profile.emphasis.security))
	assert_float(float(provision.discovery_profile.emphasis.nutrition)).is_greater(float(defense.discovery_profile.emphasis.nutrition))
	assert_bool(provision_domains!=defense_domains).is_true()
	assert_int((provision.discovery_profile.momentum as Dictionary).size()).is_equal(12)


func test_rival_research_population_and_allocation_compound_without_person_entities()->void:
	var base:Dictionary={"id":"scale_test","population":120.0,"food_capacity":140.0,"food_days":60.0,"health":0.78,"cohesion":0.70,"knowledge":0.34,"production":0.30,"logistics":0.28,"institutions":0.32,"ecology":0.75,"military_readiness":0.40,"territory":1.0,"settlement_count":1,"world_reach":0.04,"adaptability":0.62,"founding_focus":"inquiry","strategy":"inquiry","allocations":CivilizationSystem._allocation_for("inquiry"),"progression_tiers":CivilizationSystem._initial_progression_tiers()}
	var small:=base.duplicate(true)
	var large:=base.duplicate(true)
	large["population"]=1_000_000_000.0
	large["food_capacity"]=1_150_000_000.0
	var earlier_completion:=false
	for _cycle in 24:
		GameState.elapsed_days=float((_cycle+1)*30)
		small=ProgressionSystem.advance_rival(small)
		large=ProgressionSystem.advance_rival(large)
		earlier_completion=earlier_completion or (large.discovery_profile.get("technologies",[]) as Array).size()>(small.discovery_profile.get("technologies",[]) as Array).size()
	var small_findings:=0
	var large_findings:=0
	for domain in CATALOG.DOMAINS:
		small_findings+=int(small.discovery_profile.domains[domain].count)
		large_findings+=int(large.discovery_profile.domains[domain].count)
	assert_float(float(large.discovery_profile.research_workforce)).is_greater(float(small.discovery_profile.research_workforce)*1_000_000.0)
	assert_int(int(large.discovery_profile.research_slots)).is_greater(int(small.discovery_profile.research_slots))
	assert_int(large_findings).is_greater_equal(small_findings)
	assert_bool(earlier_completion).is_true()
	assert_int((large.discovery_profile.domains as Dictionary).size()).is_equal(12)
