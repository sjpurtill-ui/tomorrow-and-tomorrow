extends GdUnitTestSuite
const Data=preload("res://scripts/hud/kpi_detail_data.gd")
const Chip=preload("res://scripts/hud/kpi_detail_chip.gd")
const HoverCard=preload("res://scripts/hud/hover_card.gd")
class HeaderTerrain extends Node:
	var game_speed:float=1.0
	func site_temperature_c(_day:float=-1.0)->float:return 20.0
class LiveHeader extends "res://scripts/hud/command_rail_hud.gd":
	func _ready()->void:
		_build_time_pill()
		_build_kpi_strip()
	func _layout()->void:pass
func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(4242)
	SettlementModel.reset_for_new_world()
	GameState.settlement_name="Test City"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
func test_all_six_panels_have_structured_data_and_build()->void:
	for id in ["population","food","water","health","science","gdp"]:
		var data:=Data.snapshot(id)
		assert_str(data.title).is_not_empty()
		assert_int(data.rows.size()).is_greater_equal(1)

## Hover cards are a glance: a headline sentence, at most four facts, no
## city-by-city table, and never taller than a third of the design screen.
func test_hover_cards_are_small_readable_cards()->void:
	var chip=auto_free(Chip.new());add_child(chip)
	for id in ["population","food","water","goods","health","science","gdp"]:
		chip.metric_id=id
		var spec:Dictionary=chip.hover_spec()
		assert_str(String(spec.headline)).is_not_empty()
		assert_int((spec.facts as Array).size()).is_less_equal(HoverCard.MAX_FACTS)
		for fact:Dictionary in spec.facts:assert_str(String(fact.text)).is_not_empty()
		var host=auto_free(HoverCard.new());add_child(host)
		host.show_for(chip,chip.hover_spec)
		assert_bool(host.card.visible).is_true()
		assert_float(host.card.size.x).is_equal(HoverCard.WIDTH)
		assert_float(host.card.size.y).is_less(360.0)
		assert_bool(host.card.mouse_filter==Control.MOUSE_FILTER_IGNORE).is_true()

func test_hover_card_stays_on_screen_under_its_anchor()->void:
	var view:=Vector2(1600,900)
	var size:=Vector2(300,220)
	# Under the chip, left edges aligned.
	var chip:=Rect2(800,6,120,46)
	var at:=HoverCard.place(chip,size,view)
	assert_vector(at).is_equal(Vector2(800,60))
	assert_bool(Rect2(at,size).intersects(chip)).is_false()
	# Near the right edge it flips to right-align with the chip, still on screen.
	var right_chip:=Rect2(1480,6,112,46)
	at=HoverCard.place(right_chip,size,view)
	assert_float(at.x+size.x).is_equal(right_chip.end.x)
	assert_bool(Rect2(Vector2.ZERO,view).encloses(Rect2(at,size))).is_true()
	assert_bool(Rect2(at,size).intersects(right_chip)).is_false()
	# Near the bottom it opens above.
	var low:=Rect2(700,820,100,40)
	at=HoverCard.place(low,size,view)
	assert_float(at.y+size.y).is_less_equal(low.position.y)

func test_hover_host_opens_once_and_switches_without_stacking()->void:
	var host=auto_free(HoverCard.new());add_child(host)
	var a:Button=auto_free(Chip.new());a.metric_id="food";add_child(a)
	var b:Button=auto_free(Chip.new());b.metric_id="water";add_child(b)
	host.attach(a,a.hover_spec);host.attach(b,b.hover_spec)
	assert_str(a.tooltip_text).is_empty()
	host._on_enter(a,a.hover_spec)
	assert_bool(host.card.visible).is_false()
	host._on_open_timeout()
	assert_bool(host.is_open()).is_true()
	assert_object(host.anchor).is_same(a)
	# Moving to the neighbour switches at once; one card node, one card shown.
	host._on_exit(a);host._on_enter(b,b.hover_spec)
	assert_object(host.anchor).is_same(b)
	assert_int(host.find_children("HoverCard","",true,false).size()).is_equal(1)
	host._on_exit(b)
	host.hide_card()
	assert_bool(host.card.visible).is_false()
func test_food_net_is_rations_not_production_ratio()->void:
	GameState.simulation_metrics={"food_days":12.0,"food_consumption":10.0,"food_balance":0.25,"food_net":-7.5,"food_intake_ratio":0.8}
	var data:=Data.snapshot("food")
	assert_str(data.rows[2].value).is_equal("-7.5 rations/day")
	assert_str(data.tone).is_equal("warning")
	assert_float(data.meter).is_equal(0.8)
func test_unmeasured_water_does_not_claim_needs_are_met()->void:
	GameState.water_metrics={}
	var data:=Data.snapshot("water")
	assert_float(data.meter).is_equal(-1.0)
	assert_str(data.value).is_equal("Awaiting report")
func test_selected_city_resources_do_not_leak_into_primary()->void:
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","primary":false,"position":Vector2(10,0),"population_share":0.25,"founded_day":0})
	var city:=SettlementModel.settlement_record("second")
	SettlementModel._ensure_city_resources(city)
	city.local_resources.water_metrics={"days":2.0,"required_today":20.0,"intake_ratio":0.5}
	GameState.water_metrics={"days":9.0,"required_today":60.0,"intake_ratio":1.0}
	GameState.selected_player_settlement_id="second"
	var data:=Data.snapshot("water")
	# Before writing, the whole people is "all our hearths" (era_words.gd).
	assert_str(data.scope).is_equal("All our hearths")
	assert_str(data.value).is_equal("7.3")
	assert_float(data.meter).is_equal(0.875)
	assert_float(float(GameState.water_metrics.days)).is_equal(9.0)
func test_population_panel_says_who_went_hungry()->void:
	GameState.simulation_metrics={"food_days":12.0,"food_consumption":10.0,"food_eaten":10.0}
	var fed_all:=Data.snapshot("population")
	assert_str(fed_all.status).contains("Everyone ate")
	assert_float(fed_all.meter).is_equal(1.0)
	GameState.simulation_metrics={"food_days":12.0,"food_consumption":10.0,"food_eaten":5.0}
	var short:=Data.snapshot("population")
	assert_str(short.tone).is_equal("warning")
	assert_str(short.status).contains("went hungry")
func test_topbar_compiles_with_custom_chips()->void:
	assert_object(load("res://scripts/hud/command_rail_hud.gd")).is_not_null()


func test_totals_are_independent_of_selection_and_show_both_cities()->void:
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","primary":false,"position":Vector2(10,0),"population_share":0.25,"founded_day":0})
	GameState.simulation_metrics={"food_consumption":60.0,"food_days":10.0,"food_production":65.0,"food_eaten":60.0,"labor_efficiency":0.8}
	SettlementModel.with_city_resources("second",func()->void:
		GameState.simulation_metrics={"food_consumption":20.0,"food_days":2.0,"food_production":5.0,"food_eaten":10.0,"labor_efficiency":0.4})
	var model=preload("res://scripts/hud/civilization_kpi_model.gd")
	var first:=model.snapshot()
	GameState.selected_player_settlement_id="second"
	var second:=model.snapshot()
	assert_dict(first).is_equal(second)
	assert_float(first.food_produced).is_equal(70.0)
	assert_float(first.food_days).is_equal(8.0)
	assert_int(first.food_shortages).is_equal(1)
	assert_float(first.output).is_equal(float(first.cities[0].output)+float(first.cities[1].output))
	assert_float(first.science).is_equal(float(first.cities[0].science)+float(first.cities[1].science))
	var detail:=Data.from_totals("food",first)
	assert_str(detail.rows[-1].label).is_equal("Rivermeet")
	assert_str(detail.rows[-1].value).contains("SHORTFALL")
	assert_float(float(GameState.simulation_metrics.food_days)).is_equal(10.0)

func test_food_batch_subset_cannot_zero_out_total_reserves()->void:
	GameState.simulation_metrics={"food_days":133.1,"food_consumption":42.0,"food_batch_stock":0.0,"food_eaten":42.0}
	var model=preload("res://scripts/hud/civilization_kpi_model.gd")
	assert_float(float(model.snapshot().food_days)).is_equal_approx(133.1,.000001)
	GameState.simulation_metrics.food_total_stock=420.0
	assert_float(float(model.snapshot().food_days)).is_equal_approx(10.0,.000001)
	GameState.simulation_metrics.food_total_stock=0.0
	assert_float(float(model.snapshot().food_days)).is_equal(0.0)

func test_header_refreshes_without_legacy_interface_or_navigation()->void:
	var terrain=auto_free(HeaderTerrain.new())
	var header=auto_free(LiveHeader.new())
	header.terrain=terrain
	add_child(header)
	header.set_process(false)
	GameState.simulation_metrics={"food_days":12.0,"food_consumption":10.0}
	GameState.water_metrics={"days":5.0,"required_today":10.0,"stored":50.0}
	GameState.elapsed_days=1.0
	header._process(.75)
	assert_str(header.kpi_chips.food.value.text).is_equal("12 days")
	assert_str(header.kpi_chips.water.value.text).is_equal("5 days")
	assert_str(header.time_text.text).contains("Day 2")
	GameState.simulation_metrics.food_days=9.0
	GameState.water_metrics.days=3.0
	GameState.water_metrics.stored=30.0
	GameState.elapsed_days=2.0
	header._process(.25)
	assert_str(header.kpi_chips.food.value.text).is_equal("12 days")
	header._process(.5)
	assert_str(header.kpi_chips.food.value.text).is_equal("9 days")
	assert_str(header.kpi_chips.water.value.text).is_equal("3 days")
	assert_str(header.time_text.text).contains("Day 3")


