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
	# Exercise the registered, fully normalized production catalog.
	for raw:Dictionary in preload("res://scripts/settlement_fabric_knowledge.gd").entries():
		assert_bool(DiscoverySystem.catalog_by_id.has(raw.id)).is_true()
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

const Reverse=preload("res://scripts/reverse_engineering.gd")
func test_ten_owned_examples_require_foundations_consumption_and_local_examination()->void:
	for entry:Dictionary in preload("res://scripts/settlement_fabric_knowledge.gd").entries():
		before_test();prepare()
		var subject:=String(entry.id)
		var item:=String(entry.production_items[0])
		var output:=String(preload("res://scripts/civilian_industry.gd").product(item).output)
		GameState.known_discoveries.append_array(["apprentice_contracts","workshop_standards"])
		GameState.resource_stockpiles[output]=2.0
		assert_bool(Reverse.quote(subject,item).has("error")).is_true()
		for parent:String in live(entry).requires_all:GameState.known_discoveries.append(parent)
		for group:Array in live(entry).requires_any:GameState.known_discoveries.append(group[0])
		assert_bool(Reverse.begin(subject,item).get("ok",false)).is_true()
		assert_float(float(GameState.resource_stockpiles[output])).is_equal(1.0)
		assert_bool(Reverse.begin(subject,item).has("error")).is_true()
		assert_dict(P.evidence(subject)).is_empty()
		GameState.population_allocations.Knowledge=0
		E.advance(100001)
		assert_float(float(E.data().collections["reverse:"+subject].study)).is_equal(0.0)
		GameState.population_allocations.Knowledge=40
		for day in range(100002,100302):GameState.elapsed_days=day;E.advance(day)
		assert_float(P.multiplier(DiscoverySystem.catalog_by_id[subject])).is_equal(1.35)
		assert_bool(subject in GameState.known_discoveries).is_false()
		assert_array(MilitaryCampaign.equipment_queue).is_empty()

## Foundations as the live catalog defines them (600-year design overrides included).
func live(entry:Dictionary)->Dictionary:
	return DiscoverySystem.discovery_definition(String(entry.id))
