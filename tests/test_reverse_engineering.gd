extends GdUnitTestSuite
const R=preload("res://scripts/reverse_engineering.gd")
const E=preload("res://scripts/society_exchange.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(91417);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.elapsed_days=0;GameState.food_security=1;GameState.population_health=1
	MilitaryCampaign.military_inventory.clear();MilitaryCampaign.damaged_equipment.clear()
	# faience is glassmaking's 600-year design foundation.
	GameState.known_discoveries.assign(["apprentice_contracts","workshop_standards","kiln_control","salt_working","faience"])
	GameState.resource_stockpiles.Glass=2.0
func after_test()->void:
	GameState.elapsed_days=0;WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func test_quote_is_read_only_and_begin_consumes_only_one_owned_example()->void:
	assert_bool(R.quote("glassmaking","glass_batch").has("error")).is_false()
	assert_float(float(GameState.resource_stockpiles.Glass)).is_equal(2.0)
	assert_bool(R.begin("glassmaking","glass_batch").get("ok",false)).is_true()
	assert_float(float(GameState.resource_stockpiles.Glass)).is_equal(1.0)
	assert_bool(R.begin("glassmaking","glass_batch").has("error")).is_true()
	assert_float(float(GameState.resource_stockpiles.Glass)).is_equal(1.0)
	assert_bool("glassmaking" in GameState.known_discoveries).is_false()
	assert_dict(P.evidence("glassmaking")).is_empty()
func test_missing_specimen_or_foundations_cannot_be_bypassed()->void:
	GameState.resource_stockpiles.Glass=0.0
	assert_bool(R.begin("glassmaking","glass_batch").has("error")).is_true()
	GameState.resource_stockpiles.Glass=2.0;GameState.known_discoveries.erase("faience")
	assert_bool(R.begin("glassmaking","glass_batch").has("error")).is_true()
	assert_float(float(GameState.resource_stockpiles.Glass)).is_equal(2.0)
	assert_dict(E.data().collections).is_empty()
func test_examination_needs_local_work_before_weaker_evidence_applies()->void:
	R.begin("glassmaking","glass_batch")
	GameState.population_allocations.Knowledge=0
	E.advance(1);GameState.elapsed_days=1
	assert_float(float(E.data().collections["reverse:glassmaking"].study)).is_equal(0.0)
	GameState.population_allocations.Knowledge=20
	for day in range(2,402):GameState.elapsed_days=day;E.advance(day)
	assert_float(float(P.evidence("glassmaking").study)).is_equal(1.0)
	assert_float(P.multiplier(DiscoverySystem.discovery_definition("glassmaking"))).is_equal(1.35)
	assert_bool("glassmaking" in GameState.known_discoveries).is_false()
func test_examined_specimen_cannot_replace_lost_local_foundations()->void:
	R.begin("glassmaking","glass_batch")
	var item:Dictionary=E.data().collections["reverse:glassmaking"]
	GameState.known_discoveries.erase("faience")
	for route:Dictionary in P.routes_for(DiscoverySystem.discovery_definition("glassmaking"),GameState.known_discoveries,{},item):assert_bool(route.ready).is_false()
func test_save_validation_accepts_progress_and_rejects_forged_contracts()->void:
	R.begin("glassmaking","glass_batch")
	var data:Dictionary=JSON.parse_string(JSON.stringify(E.data()))
	assert_bool(E.valid(data)).is_true()
	data.collections["reverse:glassmaking"].work=1.0
	assert_bool(E.valid(data)).is_false()
	data.collections["reverse:glassmaking"].work=180.0
	data.collections["reverse:glassmaking"].specimen_item="electrical_generator"
	assert_bool(E.valid(data)).is_false()
func test_stronger_existing_evidence_prevents_wasting_a_specimen()->void:
	R.begin("glassmaking","glass_batch")
	var item:Dictionary=E.data().collections["reverse:glassmaking"].duplicate(true)
	E.data().collections.clear();item.id="purchased";item.kind="knowledge";item.erase("reverse_engineered");item["research_purchase"]=true;item.study=1.0
	E.data().collections[item.id]=item;E.data().evidence.glassmaking=item.id
	assert_bool(R.begin("glassmaking","glass_batch").has("error")).is_true()
	assert_float(float(GameState.resource_stockpiles.Glass)).is_equal(1.0)

func test_another_civilizations_specimen_does_not_supply_local_examination()->void:
	WorldSimulation.create_actor("specimen_owner",981)
	WorldSimulation.scoped("specimen_owner",func()->void:WorldSimulation.state.resource_stockpiles.Glass=10.0)
	GameState.resource_stockpiles.Glass=0.0
	assert_bool(R.begin("glassmaking","glass_batch").has("error")).is_true()
	assert_float(float(WorldSimulation.scoped("specimen_owner",func()->float:return WorldSimulation.state.resource_stockpiles.Glass))).is_equal(10.0)

func _crossbow_foundations()->void:
	GameState.known_discoveries.append_array(["bow_craft","joinery"])
func test_military_example_consumes_only_unassigned_serviceable_inventory()->void:
	_crossbow_foundations()
	MilitaryCampaign.military_inventory.crossbow=2
	MilitaryCampaign.damaged_equipment.crossbow=4
	assert_bool(R.quote("crossbow_mechanism","military:crossbow").has("error")).is_false()
	assert_int(int(MilitaryCampaign.military_inventory.crossbow)).is_equal(2)
	assert_bool(R.begin("crossbow_mechanism","military:crossbow").get("ok",false)).is_true()
	assert_int(int(MilitaryCampaign.military_inventory.crossbow)).is_equal(1)
	assert_int(int(MilitaryCampaign.damaged_equipment.crossbow)).is_equal(4)
	assert_bool(R.begin("crossbow_mechanism","military:crossbow").has("error")).is_true()
	assert_int(int(MilitaryCampaign.military_inventory.crossbow)).is_equal(1)
	assert_bool("crossbow_mechanism" in GameState.known_discoveries).is_false()
	assert_bool(E.valid(JSON.parse_string(JSON.stringify(E.data())))).is_true()
func test_damaged_and_foreign_equipment_cannot_supply_examination()->void:
	_crossbow_foundations()
	MilitaryCampaign.damaged_equipment.crossbow=8
	WorldSimulation.create_actor("military_specimen_owner",984)
	WorldSimulation.scoped("military_specimen_owner",func()->void:WorldSimulation.military.military_inventory.crossbow=7)
	assert_bool(R.begin("crossbow_mechanism","military:crossbow").has("error")).is_true()
	assert_int(int(WorldSimulation.scoped("military_specimen_owner",func()->int:return WorldSimulation.military.military_inventory.crossbow))).is_equal(7)
	assert_dict(E.data().collections).is_empty()
func test_military_examination_requires_local_foundations_and_study()->void:
	MilitaryCampaign.military_inventory.crossbow=1
	assert_bool(R.begin("crossbow_mechanism","military:crossbow").has("error")).is_true()
	_crossbow_foundations()
	assert_bool(R.begin("crossbow_mechanism","military:crossbow").get("ok",false)).is_true()
	GameState.population_allocations.Knowledge=0
	E.advance(1);GameState.elapsed_days=1
	assert_float(float(E.data().collections["reverse:crossbow_mechanism"].study)).is_equal(0.0)
	GameState.population_allocations.Knowledge=20
	for day in range(2,402):GameState.elapsed_days=day;E.advance(day)
	assert_float(P.multiplier(DiscoverySystem.discovery_definition("crossbow_mechanism"))).is_equal(1.35)
	assert_bool("crossbow_mechanism" in GameState.known_discoveries).is_false()
func test_military_specimen_catalog_is_explicit_and_save_subject_cannot_be_forged()->void:
	const S=preload("res://scripts/research_specimens.gd")
	const U=preload("res://scripts/military_unit_catalog.gd")
	assert_int(S.MILITARY.size()).is_equal(17)
	for equipment:String in S.MILITARY:
		assert_str(String(U.EQUIPMENT_GATES.get(equipment,""))).is_equal(String(S.MILITARY[equipment]))
		assert_dict(DiscoverySystem.discovery_definition(S.MILITARY[equipment])).is_not_empty()
	assert_dict(S.definition("military:medical_kit")).is_empty()
	assert_dict(S.definition("military:fighter_equipment")).is_empty()
	_crossbow_foundations();MilitaryCampaign.military_inventory.crossbow=1
	R.begin("crossbow_mechanism","military:crossbow")
	var data:Dictionary=JSON.parse_string(JSON.stringify(E.data()))
	data.collections["reverse:crossbow_mechanism"].specimen_item="military:machine_gun"
	assert_bool(E.valid(data)).is_false()
