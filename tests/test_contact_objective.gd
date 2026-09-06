extends GdUnitTestSuite
var system:Node
func before_test()->void:
	GameState.reset_for_new_world(112358);GameState.resource_stockpiles={"Food":5000.0};GameState.settlement_site_committed=true
	MilitaryCampaign.reset_for_new_world()
	system=auto_free(preload("res://scripts/civilization_system.gd").new());system.reset_for_new_world();system.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
func test_unknown_societies_cannot_be_objectives()->void:
	assert_bool(system.contact_investigation_proposal("civ_01").has("error")).is_true()
func test_known_objective_uses_real_quote_and_rejects_duplicate_dispatch()->void:
	var civ:Dictionary=system.civilizations[0]
	civ.player_relation.contact_level=2;civ.player_relation.met_day=0;civ.player_relation.contact_source="returned_scout_report";civ.player_relation.encounter_position={"x":16.0,"z":0.0}
	var before:=FoodSystem.total_stored()
	var proposal:Dictionary=system.contact_investigation_proposal(String(civ.id))
	assert_bool(proposal.has("ok")).is_true();assert_int(int(proposal.duration)).is_equal(30)
	assert_float(FoodSystem.total_stored()).is_equal(before)
	var result:Dictionary=system.investigate_known_contact(String(civ.id))
	assert_bool(result.has("error")).is_false()
	assert_float(FoodSystem.total_stored()).is_equal(before-float(proposal.provisions))
	assert_int(system.scout_missions.size()).is_equal(1)
	assert_bool(system.investigate_known_contact(String(civ.id)).has("error")).is_true()
	assert_int(system.scout_missions.size()).is_equal(1)
