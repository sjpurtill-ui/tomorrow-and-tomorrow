extends GdUnitTestSuite
## Renamed research ids stay loadable: saves written with the old ids migrate
## to the current ids, and the live catalog only carries the current ones.
const Aliases=preload("res://scripts/discovery_id_aliases.gd")
const Industry=preload("res://scripts/civilian_industry.gd")

func test_saved_payload_strings_keys_and_stocks_move_to_current_ids()->void:
	var payload:={"reflected_GameState":{
		"known_discoveries":["fire_control","portland_cement_clinker","saint_monday_custom"],
		"discovery_adoption":{"portland_cement_clinker":.4,"fire_control":1.0},
		"active_investigations":{"infrastructure":"postmortem_caesarean_rule"},
		"discovery_log":[{"id":"penny_daily_press","day":12}],
		"resource_stockpiles":{"Portland Cement":3.0,"Clinker Cement":1.0,"Stone":5.0}}}
	var migrated:Dictionary=Aliases.migrate(payload)
	var state:Dictionary=migrated.reflected_GameState
	assert_array(state.known_discoveries).is_equal(["fire_control","clinker_cement","idle_weekstart_custom"])
	assert_float(float(state.discovery_adoption.clinker_cement)).is_equal(.4)
	assert_bool(state.discovery_adoption.has("portland_cement_clinker")).is_false()
	assert_str(String(state.active_investigations.infrastructure)).is_equal("postmortem_incision_delivery")
	assert_str(String(state.discovery_log[0].id)).is_equal("cheap_daily_press")
	assert_float(float(state.resource_stockpiles["Clinker Cement"])).is_equal(4.0)
	assert_bool(state.resource_stockpiles.has("Portland Cement")).is_false()
	assert_float(float(state.resource_stockpiles.Stone)).is_equal(5.0)

func test_catalog_and_recipes_use_only_current_ids()->void:
	WorldSimulation.clear()
	DiscoverySystem.initialize()
	var ids:Dictionary={}
	for entry:Dictionary in DiscoverySystem.technology_catalog:ids[String(entry.id)]=true
	for old:String in Aliases.ALIASES:
		var renamed:=String(Aliases.ALIASES[old])
		assert_bool(ids.has(old)).override_failure_message(old+" is still a discovery id").is_false()
		assert_bool(Industry.PRODUCTS.has(old)).override_failure_message(old+" is still a recipe id").is_false()
		if old==old.to_lower():
			assert_bool(ids.has(renamed) or Industry.PRODUCTS.has(renamed)).override_failure_message(renamed+" is missing").is_true()
	for recipe:Dictionary in Industry.PRODUCTS.values():
		assert_bool(Aliases.ALIASES.has(String(recipe.output))).is_false()
		assert_bool(Aliases.ALIASES.has(String(recipe.gate))).is_false()
