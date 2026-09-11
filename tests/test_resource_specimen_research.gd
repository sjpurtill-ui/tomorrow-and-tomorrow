extends GdUnitTestSuite
const E=preload("res://scripts/society_exchange.gd")
func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(91423);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.elapsed_days=10;GameState.resource_deposits.clear();GameState.resource_stockpiles.clear()
func after_test()->void:
	GameState.elapsed_days=0;WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func sample(subject:String)->Dictionary:
	var item:={"id":"ground:0:0:test","kind":"specimen","name":"Returned mineral sample","source_id":"","source_name":"Visited ground","position":{"x":1.0,"z":0.0},"observed_day":1,"returned_day":2,"discovery_id":subject,"study":1.0,"work":60.0,"signals":["survey"]}
	GameState.society_exchange.collections[item.id]=item
	return item
func test_studied_foreign_ore_supports_assay_without_inventing_a_local_mine()->void:
	var item:=sample("ore_assaying")
	assert_bool(E.valid_item(item)).is_true()
	GameState.known_discoveries.assign(["kiln_control","standard_measures"])
	var entry:=DiscoverySystem.discovery_definition("ore_assaying")
	assert_bool(DiscoverySystem._discovery_is_eligible(entry,10)).is_true()
	assert_array(GameState.resource_deposits).is_empty()
	assert_dict(GameState.resource_stockpiles).is_empty()
	assert_bool("ore_assaying" in GameState.known_discoveries).is_false()
func test_study_return_date_and_actual_specimen_kind_are_required()->void:
	var item:=sample("ore_assaying")
	var requirements:Array=DiscoverySystem.discovery_definition("ore_assaying").resource_requirements
	item.study=.99
	assert_bool(DiscoverySystem._resource_requirements_met(requirements)).is_false()
	item.study=1.0;item.returned_day=11
	assert_bool(DiscoverySystem._resource_requirements_met(requirements)).is_false()
	item.returned_day=2;item.kind="knowledge"
	assert_bool(DiscoverySystem._resource_requirements_met(requirements)).is_false()
func test_specimen_does_not_replace_foundations_or_extraction_requirements()->void:
	sample("ore_assaying")
	GameState.known_discoveries.clear()
	assert_bool(DiscoverySystem._discovery_is_eligible(DiscoverySystem.discovery_definition("ore_assaying"),10)).is_false()
	for stage:String in ["accessible","developed"]:
		assert_bool(DiscoverySystem._resource_requirements_met([{"resource":"Copper Ore","stage":stage,"sample_sufficient":true}])).is_false()
	assert_bool(DiscoverySystem._resource_requirements_met([{"resource":"Copper Ore","stage":"surveyed"}])).is_false()
func test_wrong_material_and_artifacts_cannot_support_identification()->void:
	var item:=sample("iron_assaying")
	assert_bool(DiscoverySystem._resource_requirements_met(DiscoverySystem.discovery_definition("ore_assaying").resource_requirements)).is_false()
	item.discovery_id="ore_assaying";item.kind="artifact"
	assert_bool(E.studied_resource_sample("Copper Ore")).is_false()
func test_sample_permission_survives_catalog_normalization_and_save_roundtrip()->void:
	for subject:String in ["clay_shaping","stone_sorting","controlled_flaking","fiber_grading","timber_grading","salt_working","ore_assaying","iron_assaying","coal_grading"]:
		GameState.society_exchange.collections.clear();sample(subject)
		var restored:Dictionary=JSON.parse_string(JSON.stringify(GameState.society_exchange.collections))
		GameState.society_exchange.collections=restored
		assert_bool(DiscoverySystem._resource_requirements_met(DiscoverySystem.discovery_definition(subject).resource_requirements)).is_true()
