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

func test_fabric_purchase_requires_paid_delivery_and_local_study_without_tools_or_mastery()->void:
	for entry:Dictionary in preload("res://scripts/settlement_fabric_knowledge.gd").entries():
		before_test();prepare()
		var subject:=String(entry.id)
		for parent:String in live(entry).requires_all:GameState.known_discoveries.append(parent)
		for alternatives:Array in live(entry).requires_any:
			GameState.known_discoveries.append(String(alternatives[-1]))
		var peer:=E.owner_state("neighbor")
		peer.known_discoveries.append(subject);peer.discovery_adoption[subject]=1.0
		var before:=float(GameState.resource_stockpiles.Stone)
		assert_bool(Purchase.dispatch("neighbor",subject,"Stone").get("ok",false)).is_true()
		assert_float(float(GameState.resource_stockpiles.Stone)).is_less(before)
		var mission:Dictionary=CivilizationSystem.diplomatic_mission
		E.envoy_arrived(CivilizationSystem,mission,int(mission.arrival_day))
		assert_bool(mission.research_refused).is_false()
		Purchase.prepare_return(mission);E.returned(mission,int(mission.return_day))
		assert_dict(P.evidence(subject)).is_empty()
		GameState.population_allocations.Knowledge=60
		for day in range(100007,100100):E.advance(day)
		assert_bool(P.evidence(subject).get("research_purchase",false)).is_true()
		assert_bool(subject in GameState.known_discoveries).is_false()
		assert_float(P.multiplier(live(entry))).is_equal(2.5)
		assert_array(MilitaryCampaign.equipment_queue).is_empty()
		assert_float(float(GameState.resource_stockpiles.get("Building Shade Lattices",0))).is_equal(0.0)

func test_all_foundations_and_each_alternative_survive_imported_evidence()->void:
	var entries:=preload("res://scripts/settlement_fabric_knowledge.gd").entries()
	var source:={"id":"studied_foreign_sample","kind":"artifact","source_name":"Neighbor"}
	for entry:Dictionary in entries:
		var known:Array=live(entry).requires_all.duplicate()
		for group:Array in live(entry).requires_any:known.append(group[0])
		for route:Dictionary in P.routes_for(live(entry),known,{},source):assert_bool(route.ready).is_true()
		for parent:String in live(entry).requires_all:
			var missing:=known.duplicate();missing.erase(parent)
			for route:Dictionary in P.routes_for(live(entry),missing,{},source):assert_bool(route.ready).is_false()
		for group:Array in live(entry).requires_any:
			var missing:=known.duplicate()
			for parent:String in group:missing.erase(parent)
			for route:Dictionary in P.routes_for(live(entry),missing,{},source):assert_bool(route.ready).is_false()
			for parent:String in group:
				var alternate:=missing.duplicate();alternate.append(parent)
				for route:Dictionary in P.routes_for(live(entry),alternate,{},source):assert_bool(route.ready).is_true()
		for recipe:String in entry.get("production_items",[]):
			assert_str(String(preload("res://scripts/civilian_industry.gd").product(recipe).gate)).is_equal(String(entry.id))

func test_all_fabric_scholar_visits_pay_for_temporary_subject_specific_teaching()->void:
	var scholars=preload("res://scripts/scholar_visits.gd")
	for entry:Dictionary in preload("res://scripts/settlement_fabric_knowledge.gd").entries():
		before_test();prepare()
		var subject:=String(entry.id)
		assert_bool(scholars.quote("neighbor",subject,"Stone").has("error")).is_true()
		for parent:String in live(entry).requires_all:GameState.known_discoveries.append(parent)
		for group:Array in live(entry).requires_any:GameState.known_discoveries.append(String(group.back()))
		var provider:=E.owner_state("neighbor")
		provider.known_discoveries.append(subject);provider.discovery_adoption[subject]=1.0
		provider.elapsed_days=100000
		var workers:float=provider.effective_workers("Knowledge")
		var population:float=provider.population_exact
		var payment:=float(GameState.resource_stockpiles.Stone)
		var food:=float(GameState.resource_stockpiles.Food)
		assert_bool(scholars.dispatch("neighbor",subject,"Stone").get("ok",false)).is_true()
		assert_float(float(GameState.resource_stockpiles.Stone)).is_less(payment)
		assert_float(float(GameState.resource_stockpiles.Food)).is_less(food)
		var mission:Dictionary=CivilizationSystem.diplomatic_mission
		E.envoy_arrived(CivilizationSystem,mission,int(mission.arrival_day))
		assert_bool(mission.research_refused).is_false()
		provider.elapsed_days=mission.arrival_day
		assert_float(provider.effective_workers("Knowledge")).is_equal(workers-1)
		assert_float(scholars.bonus(subject,int(mission.return_day))).is_equal(1.0)
		Purchase.prepare_return(mission)
		assert_float(scholars.bonus(subject,int(mission.return_day))).is_equal(1.5)
		assert_float(scholars.bonus("cordage",int(mission.return_day))).is_equal(1.0)
		var visit:Dictionary=bytes_to_var(var_to_bytes(E.data().scholar_visits))
		assert_bool(scholars.valid(visit)).is_true()
		assert_float(scholars.bonus(subject,int(mission.scholar_contract.leave_day))).is_equal(1.0)
		provider.elapsed_days=mission.scholar_contract.home_day
		assert_float(provider.effective_workers("Knowledge")).is_equal(workers)
		assert_float(provider.population_exact).is_equal(population)
		assert_bool(subject in GameState.known_discoveries).is_false()
		assert_array(MilitaryCampaign.equipment_queue).is_empty()

## Foundations as the live catalog defines them (600-year design overrides included).
func live(entry:Dictionary)->Dictionary:
	return DiscoverySystem.discovery_definition(String(entry.id))
