extends GdUnitTestSuite
const E=preload("res://scripts/society_exchange.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
const Purchase=preload("res://scripts/research_purchase.gd")
func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(777);DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();FoodSystem.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.ensure_population_total(200);GameState.settlement_site_committed=true;GameState.housing_capacity=280
	GameState.population_allocations.Knowledge=30;GameState.population_allocations.Administration=12
	GameState.food_security=1;GameState.population_health=.95;GameState.water_metrics={"intake_ratio":1.0}
	GameState.simulation_metrics={"food_days":60,"food_intake_ratio":1.0,"security":.9,"cohesion":.9}
	GameState.resource_stockpiles.Food=20000;GameState.food_stocks={"Preserved food":20000.0}
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	WorldSimulation.create_actor("neighbor",777,Vector2(30,0));WorldSimulation.actors.neighbor.controller="manual"
	WorldSimulation.scoped("neighbor",func()->void:
		WorldSimulation.state.ensure_population_total(200);WorldSimulation.state.settlement_site_committed=true;WorldSimulation.state.housing_capacity=140
		WorldSimulation.state.food_security=.6;WorldSimulation.state.population_health=.7
		WorldSimulation.state.simulation_metrics={"food_days":30,"food_intake_ratio":1.0,"security":.3,"cohesion":.3}
		WorldSimulation.state.population_allocations.Crafting=8
		WorldSimulation.state.resource_stockpiles.Clay=20.0;WorldSimulation.state.resource_stockpiles.Food=20000
		WorldSimulation.state.food_stocks={"Preserved food":20000.0}
		WorldSimulation.state.known_discoveries.assign(["clay_shaping"]);WorldSimulation.state.discovery_adoption.clay_shaping=1.0
		E.policy("balanced","open"))
	CivilizationSystem.civilizations.clear();CivilizationSystem.civilizations.append({"id":"neighbor","name":"Neighbor","world_position":Vector2(30,0),"strategic_regions":[],"player_relation":{"opinion":.3,"at_war":false}})
	DiscoverySystem.initialize()
	# Isolated normalized candidates only; production registration remains integrator-owned.
	for raw:Dictionary in preload("res://scripts/settlement_fabric_knowledge.gd").entries():
		var entry:Dictionary=DiscoverySystem._classify_discovery(raw)
		entry=preload("res://scripts/society_model.gd").new().normalize_discovery(entry)
		entry=preload("res://scripts/technology_branch_rules.gd").apply(entry)
		entry=preload("res://scripts/mathematics_knowledge.gd").apply(entry)
		entry=preload("res://scripts/mechanics_knowledge.gd").apply(entry)
		DiscoverySystem.catalog_by_id[entry.id]=entry
		DiscoverySystem.technology_catalog.append(entry)
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)

func after_test()->void:
	GameState.elapsed_days=0
	WorldSimulation.clear();CivilizationSystem.reset_for_new_world();DiscoverySystem.reset_for_new_world()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)


func prepare()->void:
	GameState.elapsed_days=100000
	GameState.known_discoveries.assign(["experimental_controls","public_schools"])
	GameState.resource_stockpiles.Stone=1000.0
	CivilizationSystem.civilizations[0].merge({"population":200,"production":.5,"logistics":.5,"food_days":30,"military_population":10},true)
	E.owner_state("neighbor").population_allocations.Knowledge=20
	CivilizationSystem.civilizations[0].player_relation.merge({"contact_level":2,"home_location_known":true,"home_position":{"x":30.0,"z":0.0}},true)
	CivilizationSystem.civilizations[0].strategic_regions=[{"id":"neighbor_city","role":"capital","name":"Neighbor city","map_x":.5,"map_y":.5,"position":Vector2(30,0),"controller":"neighbor","fortification":.2,"damage":0.0,"population":200,"strategic_weight":1.0}]


const Joint=preload("res://scripts/research_partnerships.gd")
func complete_trip()->Dictionary:
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	CivilizationSystem._process_diplomatic_mission(int(mission.arrival_day))
	var completed:=mission.duplicate(true)
	CivilizationSystem._process_diplomatic_mission(int(completed.return_day))
	GameState.elapsed_days=int(completed.return_day)
	return completed

func study(days:int,both:bool=true)->void:
	for n in days:
		GameState.elapsed_days+=1;E.advance(GameState.elapsed_days)
		if both:
			var day:=GameState.elapsed_days
			WorldSimulation.scoped("neighbor",func()->void:WorldSimulation.state.elapsed_days=day;E.advance(day))


func test_ten_joint_investigations_require_both_studies_and_paid_returned_findings()->void:
	for entry:Dictionary in preload("res://scripts/settlement_fabric_knowledge.gd").entries():
		before_test();prepare();WorldSimulation.enabled=true
		var subject:=String(entry.id)
		var normalized:Dictionary=DiscoverySystem.catalog_by_id[subject].duplicate(true)
		var peer:=E.owner_state("neighbor")
		peer.known_discoveries.assign(["public_schools","experimental_controls"])
		peer.elapsed_days=GameState.elapsed_days
		WorldSimulation.scoped("neighbor",func()->void:
			WorldSimulation.discovery.initialize()
			WorldSimulation.discovery.catalog_by_id[subject]=normalized
		)
		for parent:String in entry.requires_all:
			GameState.known_discoveries.append(parent);peer.known_discoveries.append(parent)
		for group:Array in entry.requires_any:
			GameState.known_discoveries.append(String(group.back()));peer.known_discoveries.append(String(group.back()))
		var payment:=float(GameState.resource_stockpiles.Stone)
		assert_bool(Joint.dispatch("neighbor",subject,"Stone").get("ok",false)).is_true()
		assert_float(float(GameState.resource_stockpiles.Stone)).is_less(payment)
		assert_bool(complete_trip().research_refused).is_false()
		var local_key:=Joint.key("neighbor",subject)
		var remote_key:=Joint.key("player",subject)
		study(100,false)
		assert_float(float(E.data().collections[local_key].study)).is_equal(1.0)
		assert_float(float(peer.society_exchange.collections[remote_key].study)).is_equal(0.0)
		assert_dict(P.evidence(subject)).is_empty()
		assert_bool(Joint.dispatch("neighbor",subject,"Stone").get("ok",false)).is_true()
		assert_bool(complete_trip().research_refused).is_true()
		assert_dict(P.evidence(subject)).is_empty()
		study(100)
		assert_float(float(peer.society_exchange.collections[remote_key].study)).is_equal(1.0)
		CivilizationSystem.civilizations[0].player_relation.at_war=true
		assert_bool(Joint.quote("neighbor",subject,"Stone").has("error")).is_true()
		CivilizationSystem.civilizations[0].player_relation.at_war=false
		payment=float(GameState.resource_stockpiles.Stone)
		assert_bool(Joint.dispatch("neighbor",subject,"Stone").get("ok",false)).is_true()
		assert_float(float(GameState.resource_stockpiles.Stone)).is_less(payment)
		assert_bool(complete_trip().research_refused).is_false()
		assert_dict(P.evidence(subject)).is_empty()
		study(40)
		assert_bool(P.evidence(subject).get("research_partnership",false)).is_true()
		assert_float(float(P.chosen(entry,GameState.elapsed_days).progress_multiplier)).is_equal(1.6)
		assert_bool(subject in GameState.known_discoveries).is_false()
		assert_bool(subject in peer.known_discoveries).is_false()
		assert_array(MilitaryCampaign.equipment_queue).is_empty()
