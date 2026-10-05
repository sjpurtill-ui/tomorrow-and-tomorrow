extends GdUnitTestSuite
## Dates the player reads are a year and a day of the year, never the raw
## count of days since the founding (calendar_date.gd).

const CalendarDate:=preload("res://scripts/calendar_date.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

func test_a_day_reads_as_year_and_day()->void:
	assert_str(CalendarDate.words(0)).is_equal("year 1, day 1")
	assert_str(CalendarDate.words(364)).is_equal("year 1, day 365")
	assert_str(CalendarDate.words(365)).is_equal("year 2, day 1")
	assert_str(CalendarDate.words(54718,true)).is_equal("Year 150, day 334")
	assert_str(CalendarDate.words(-1)).is_equal("an unknown day")
	assert_str(EraWords.date(54718)).is_equal("year 150, day 334")

## Every script that now writes its dates this way still compiles.
func test_the_scripts_that_show_dates_compile()->void:
	for path:String in ["res://scripts/calendar_date.gd","res://scripts/audience_hall.gd","res://scripts/audience_voice.gd","res://scripts/chief_scout.gd","res://scripts/city_intelligence.gd","res://scripts/civilization_exchange.gd","res://scripts/court_persons.gd","res://scripts/custom_directive.gd","res://scripts/decree_statistics.gd","res://scripts/diplomatic_commitments.gd","res://scripts/discovery_system.gd","res://scripts/general_campaign_map.gd","res://scripts/general_campaign_screen.gd","res://scripts/great_works_rivalry.gd","res://scripts/hud/audience_modal.gd","res://scripts/hud/content/dock_content_military.gd","res://scripts/hud/content/dock_detail_building_ledger.gd","res://scripts/hud/content/dock_detail_war_planning.gd","res://scripts/hud/era_words.gd","res://scripts/knowledge_pathways.gd","res://scripts/local_terrain.gd","res://scripts/military_campaign.gd","res://scripts/rail_freight.gd","res://scripts/realm_orders.gd","res://scripts/research_licenses.gd","res://scripts/rumor_network.gd","res://scripts/scholar_visits.gd","res://scripts/sec_acquisition.gd","res://scripts/society_exchange.gd","res://scripts/trade_ledger.gd","res://scripts/undertaking_system.gd","res://scripts/war_map_marks.gd","res://scripts/water_conveyance.gd"]:
		var script:=load(path) as GDScript
		assert_object(script).override_failure_message(path).is_not_null()
		assert_bool(script.can_instantiate()).override_failure_message(path).is_true()
