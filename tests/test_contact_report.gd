extends GdUnitTestSuite
const Provider=preload("res://scripts/hud/content/dock_detail_civ_report.gd")
func before_test()->void:
	GameState.reset_for_new_world(112358);CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
func test_unknown_reports_never_get_bars_or_live_population_estimates()->void:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation.contact_level=2;civ.player_relation.contact_intelligence=.9;civ.player_relation.met_day=45;civ.player_relation.contact_source="returned_scout_report";civ.player_relation.encounter_position={"x":10.0,"z":0.0}
	var provider=Provider.new(null,null,String(civ.id))
	var tab:Dictionary=provider.tab(0)
	for block:Dictionary in tab.blocks:assert_str(String(block.type)).is_not_equal("bars")
	assert_str(String(tab.kpis[1].value)).is_equal("Day 46")
	var known:=provider._civ()
	assert_bool(known.has("population")).is_false()
	assert_str(provider._reported_range(known,"population")).is_equal("Not yet observed")
	civ.population=999999.0
	assert_str(provider._reported_range(provider._civ(),"population")).is_equal("Not yet observed")
func test_home_record_preserves_real_returned_source_and_date()->void:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation.home_location_known=true;civ.player_relation.home_position={"x":10.0,"z":0.0};civ.player_relation.home_location_source="returned contact investigation";civ.player_relation.last_observed_day=75
	CivilizationSystem.city_intelligence.seed_known_homes()
	assert_str(String(civ.player_relation.home_location_source)).is_equal("returned contact investigation")
	assert_int(int(civ.player_relation.last_observed_day)).is_equal(75)
