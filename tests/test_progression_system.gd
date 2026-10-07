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
	# One seat, as every people now has: the seat counts as the places its
	# people fill (one_seat.gd places), never a wall at the regional scale.
	GameState.player_settlements.clear()
	GameState.player_settlements.append({"id":"seat","primary":true})
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


func test_one_seat_counts_as_the_places_its_people_fill()->void:
	var OneSeat:=preload("res://scripts/one_seat.gd")
	assert_int(OneSeat.places(120.0,1,1)).is_equal(1)
	assert_int(OneSeat.places(50_000.0,1,1)).is_greater_equal(CATALOG.SETTLEMENT_FLOORS[3])
	assert_int(OneSeat.places(500_000.0,1,2)).is_greater_equal(CATALOG.SETTLEMENT_FLOORS[4])
	assert_int(OneSeat.places(12_000_000_000.0,1,8)).is_equal(OneSeat.MAX_PLACES)
	assert_int(OneSeat.places(100.0,1,5)).is_equal(5)
	for tier in CATALOG.POPULATION_FLOORS.size():
		assert_int(OneSeat.places(CATALOG.POPULATION_FLOORS[tier],1,1)).is_greater_equal(CATALOG.SETTLEMENT_FLOORS[tier])


func test_adoption_profile_updates_within_same_month()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(9241)
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	ProgressionSystem.reset_for_new_world()
	GameState.discovery_adoption["seasonal_patterns"]=.1
	GameState.elapsed_days=1
	ProgressionSystem.process_day(1)
	var before:=ProgressionSystem.cached_player_profile.duplicate(true)
	GameState.discovery_adoption["seasonal_patterns"]=.9
	GameState.elapsed_days=2
	ProgressionSystem.process_day(2)
	assert_bool(ProgressionSystem.cached_player_profile!=before).is_true()
	assert_dict(ProgressionSystem.cached_player_profile).is_equal(ProgressionSystem._build_player_discovery_profile())
