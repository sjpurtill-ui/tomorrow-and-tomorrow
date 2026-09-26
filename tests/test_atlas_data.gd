extends GdUnitTestSuite
const Data:=preload("res://scripts/hud/atlas_data.gd")
func before_test()->void:
	GameState.reset_for_new_world(424242);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
func test_locked_outcomes_are_redacted_and_cannot_be_searched_by_secret_name()->void:
	var source:=DiscoverySystem.technology_tree()
	var next:Dictionary=DiscoverySystem.technology_frontier(source).next
	for row:Dictionary in source:
		# Next reachable questions are named on purpose; deeper ones stay redacted.
		if row.status!="LOCKED" or next.has(String(row.id)):continue
		var visible:=Data.inquiry(String(row.dynamic))
		for item:Dictionary in visible:
			if item.id!=row.id:continue
			assert_str(item.name).is_equal("Unexplored question")
			assert_dict(item.effects).is_empty()
		assert_array(Data.inquiry("",String(row.name))).is_empty()
		return
	fail("Fixture has no locked question")
func test_unknown_deposits_do_not_become_material_cards()->void:
	GameState.resource_deposits=[{"resource":"Secret ore","stage":"unknown","id":"secret"}]
	GameState.resource_stockpiles={}
	var cards:=Data.materials()
	assert_int(cards.size()).is_equal(1)
	assert_str(cards[0].id).is_equal("unknown")
func test_owned_stock_is_visible_without_inventing_a_deposit()->void:
	GameState.resource_deposits=[];GameState.resource_stockpiles={"Stone":27.0}
	var cards:=Data.materials()
	assert_str(cards[0].id).is_equal("Stone")
	assert_float(float(cards[0].stock)).is_equal(27.0)
	assert_int(int(cards[0].sites)).is_equal(0)
	assert_str(cards[0].unit).is_equal("bulk units")
	assert_str(cards[0].description).contains("27.0 bulk units stored")
func test_material_units_distinguish_water_portions_from_bulk_inventory()->void:
	GameState.resource_deposits=[];GameState.resource_stockpiles={"Freshwater":752.2,"Timber":238.1}
	var cards:=Data.materials();var units:Dictionary={}
	for card:Dictionary in cards:
		if card.known:units[card.id]=card.unit
	assert_str(units.Freshwater).is_equal("daily portions")
	assert_str(units.Timber).is_equal("bulk units")

func test_exhausted_sources_are_not_presented_as_accessible()->void:
	GameState.resource_deposits=[{"resource":"Stone","stage":"developed","id":"stone","remaining":0.0,"stock_at_source":0.0,"shipments":[],"delivered_today":0.0}]
	GameState.resource_stockpiles={"Stone":0.0}
	var cards:=Data.materials()
	assert_str(String(cards[0].status)).is_equal("EXHAUSTED")
	assert_int(int(cards[0].workable)).is_equal(0)
	assert_int(int(cards[0].exhausted)).is_equal(1)
