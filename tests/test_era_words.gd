extends GdUnitTestSuite
## Fun audit item #5: the HUD speaks the people's era (era_words.gd), the rail
## leads with Court / People / Known World / Chronicle with the ledgers in a
## drawer, and no fleet or air service is offered before boats or flight.
## Player-facing words follow what the people know: carts wait for the wheel,
## saddles for the pack saddle, bullets for guns; an ore is named by its look
## until its metal is known; the air is felt until there is a thermometer.
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Rail:=preload("res://scripts/hud/command_rail_hud.gd")
const UnitMap:=preload("res://scripts/hud/content/military_unit_map.gd")
const Voice:=preload("res://scripts/character_voice.gd")
const ResourceNames:=preload("res://scripts/resource_names.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Hud:=preload("res://scripts/hud/command_rail_hud.gd")
const MODERN:=["GDP","IMR","‰","edu","SCIENCE","Navy","Air Force"]

class HeaderTerrain extends Node:
	var game_speed:float=1.0
	func site_temperature_c(_day:float=-1.0)->float:return 20.0

class RailOnly extends "res://scripts/hud/command_rail_hud.gd":
	func _ready()->void:
		_build_rail()
	func _layout()->void:pass
	func _position_toolbar()->void:pass

class WideHeader extends "res://scripts/hud/command_rail_hud.gd":
	func _ready()->void:
		_build_time_pill()
		_build_kpi_strip()
	func _layout()->void:
		if time_pill:time_pill.position=Vector2(Tokens.DOCK_X,6)
		var view:=get_viewport_rect().size
		for id in ["population","water"]:(kpi_chips[id].chip as Control).visible=view.x>=1280
		(kpi_chips.goods.chip as Control).visible=not EraWords.hearth()
		(kpi_chips.gdp.chip as Control).visible=not EraWords.hearth()
		kpi_strip.reset_size()
		kpi_strip.position=Vector2(maxf(Tokens.DOCK_X,view.x-Tokens.EDGE_MARGIN-kpi_strip.size.x),6)

class LiveHeader extends "res://scripts/hud/command_rail_hud.gd":
	func _ready()->void:
		_build_time_pill()
		_build_kpi_strip()
	func _layout()->void:pass

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(4242)
	SettlementModel.reset_for_new_world()
	GameState.settlement_name="Test Hearth"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	MilitaryCampaign.reset_for_new_world()
	Chronicle.pending_cards.clear()

func after_test()->void:
	Voice.knowledge_override.clear()

func _next_frame()->void:
	await get_tree().process_frame

func test_stages_follow_writing_and_printing()->void:
	assert_str(EraWords.stage()).is_equal("hearth")
	GameState.known_discoveries.append("pictographic_records")
	await _next_frame()
	assert_str(EraWords.stage()).is_equal("lettered")
	GameState.known_discoveries.append("printing_process")
	await _next_frame()
	assert_str(EraWords.stage()).is_equal("reckoned")

func test_the_people_count_in_their_own_words()->void:
	assert_str(EraWords.people(118)).is_equal("118 souls")
	assert_str(EraWords.life(31.4)).is_equal("31 winters")
	assert_str(EraWords.babes_lost(173.0)).is_equal("17 in 100 babes die")
	assert_str(EraWords.babes_lost_sentence(173.0)).contains("before their first winter")
	assert_str(EraWords.days(48.3)).is_equal("48 days")
	assert_str(EraWords.days(5.0)).is_equal("5 days")
	assert_str(EraWords.days(4.5)).is_equal("4.5 days")
	assert_str(EraWords.babes_lost_short(283.0)).is_equal("28 in 100 babes lost")
	assert_str(EraWords.went_without(12,"hungry")).is_equal("12 went hungry")
	assert_int(EraWords.fed(120,45.0,60.0)).is_equal(90)
	GameState.known_discoveries.append("printing_process")
	await _next_frame()
	assert_str(EraWords.babes_lost(173.0)).is_equal("IMR 173‰")
	assert_str(EraWords.word("kpi.gdp")).is_equal("REAL GDP / DAY")

func test_stores_are_told_in_moons_then_weeks_then_days()->void:
	assert_str(EraWords.store_span(67.0)).is_equal("food for two moons")
	assert_str(EraWords.store_span(5.2)).is_equal("food for five days")
	assert_str(EraWords.register()).is_equal("TOLD AT THE FIRE")
	GameState.known_discoveries.append("pictographic_records")
	await _next_frame()
	assert_str(EraWords.store_span(67.0)).is_equal("food for two months")
	assert_str(EraWords.register()).is_equal("FROM THE REGISTERS")
	GameState.known_discoveries.append("printing_process")
	await _next_frame()
	assert_str(EraWords.store_span(67.0)).is_equal("food for 67 days")
	assert_str(EraWords.register()).is_equal("FROM THE CENSUS")

func test_no_fleet_before_boats_and_no_air_service_before_flight()->void:
	assert_bool(EraWords.has_boats()).is_false()
	assert_bool(EraWords.has_flight()).is_false()
	var map:=UnitMap.new(null,null)
	assert_array(map.meta().subtabs).is_equal(["50 LAND"])
	GameState.known_discoveries.append("river_craft")
	assert_bool(EraWords.has_boats()).is_true()
	assert_array(map.meta().subtabs).is_equal(["50 LAND","NAVAL CHAIN"])
	GameState.known_discoveries.append("aerostat_observation")
	assert_bool(EraWords.has_flight()).is_true()
	assert_array(map.meta().subtabs).is_equal(["50 LAND","NAVAL CHAIN","AIR CHAIN"])
	# The air tab reads the air chain even though it is only the third tab.
	var rows:Array=(map.tab(2).blocks as Array)[1].items
	assert_bool(rows.is_empty()).is_false()

func test_the_top_strip_uses_no_modern_statistics_before_writing()->void:
	var header=auto_free(LiveHeader.new())
	header.terrain=auto_free(HeaderTerrain.new())
	add_child(header)
	header.set_process(false)
	GameState.simulation_metrics={"food_days":12.0,"food_consumption":10.0,"food_eaten":10.0}
	GameState.water_metrics={"days":5.0,"required_today":10.0,"stored":50.0}
	header._refresh_words()
	header._refresh_kpis()
	var shown:PackedStringArray=[]
	for id in header.kpi_chips:
		var parts:Dictionary=header.kpi_chips[id]
		shown.append((parts.caption as Label).text);shown.append((parts.value as Label).text);shown.append((parts.delta as Label).text)
	var text:=" | ".join(shown)
	for word in MODERN:assert_str(text).not_contains(word)
	# Who ate is told under PEOPLE; there is no second head count.
	for id in header.kpi_chips:assert_str((header.kpi_chips[id].caption as Label).text).is_not_equal("BELLIES FILLED")
	assert_str((header.kpi_chips.population.delta as Label).text).is_equal("all fed")
	assert_str((header.kpi_chips.water.value as Label).text).is_equal("5 days")
	assert_str((header.kpi_chips.health.delta as Label).text).contains("in 100 babes lost")
	# Some went hungry: the note says how many and the chip turns to a warning.
	GameState.simulation_metrics={"food_days":12.0,"food_consumption":10.0,"food_eaten":7.5}
	header._refresh_kpis()
	var hungry:=GameState.population_total-EraWords.fed(GameState.population_total,7.5,10.0)
	assert_int(hungry).is_greater(0)
	assert_str((header.kpi_chips.population.delta as Label).text).is_equal("%d went hungry" % hungry)
	assert_object((header.kpi_chips.population.accent as ColorRect).color).is_equal(Rail.Tokens.RED)

func test_every_top_strip_value_fits_in_full_at_1280()->void:
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(1280,720);add_child(canvas)
	var header=auto_free(WideHeader.new())
	header.terrain=auto_free(HeaderTerrain.new())
	canvas.add_child(header)
	header.set_process(false)
	header.size=Vector2(1280,720)
	GameState.known_discoveries.clear()
	for i in 115:GameState.known_discoveries.append("lore_%d" % i)
	GameState.simulation_metrics={"food_days":124.0,"food_consumption":10.0,"food_eaten":8.0}
	GameState.water_metrics={"days":5.0,"required_today":10.0,"stored":50.0,"intake_ratio":0.8}
	header._refresh_words()
	header._refresh_kpis()
	for i in 3:await _next_frame()
	header._layout()
	for i in 2:await _next_frame()
	assert_bool((header.kpi_chips.gdp.chip as Control).visible).is_false()
	assert_str((header.kpi_chips.science.value as Label).text).is_equal("115 ways")
	assert_float(header.kpi_strip.position.x).is_greater_equal(header.time_pill.position.x+header.time_pill.size.x+8.0)
	for id in header.kpi_chips:
		var parts:Dictionary=header.kpi_chips[id]
		if not (parts.chip as Control).visible:continue
		for key in ["caption","value","delta"]:
			var label:Label=parts[key]
			var need:=label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x
			assert_float(need).override_failure_message("%s %s '%s' needs %.0f, has %.0f" % [id,key,label.text,need,label.size.x]).is_less_equal(label.size.x+0.5)

func test_the_rail_leads_with_the_fantasy_and_folds_the_ledgers()->void:
	var rail=auto_free(RailOnly.new())
	add_child(rail)
	await _next_frame()
	var primary:Array=[]
	for spec in Rail.SECTIONS:
		if not bool(spec.get("drawer",false)):primary.append(String(spec.id))
	assert_array(primary).is_equal(["overview","world","chronicle"])
	assert_str((rail.rail_labels.overview as Label).text).is_equal("The People")
	assert_str(rail.drawer_label.text).starts_with("Tallies")
	# Court + the People + Known World + Chronicle + the drawer: five entries.
	var visible:=0
	for id in rail.rail_buttons:
		if (rail.rail_buttons[id] as Control).is_visible_in_tree():visible+=1
	assert_int(visible).is_equal(3)
	assert_bool(rail.drawer_box.visible).is_false()
	rail.toggle_drawer()
	assert_bool(rail.drawer_box.visible).is_true()
	rail.toggle_drawer()
	# Opening a ledger keeps its drawer open so the lit entry stays in view.
	rail.set_active_section("economy")
	assert_bool(rail.drawer_box.visible).is_true()
	rail.set_active_section("")
	assert_bool(rail.drawer_box.visible).is_false()

func test_carts_saddles_and_bullets_wait_for_their_discoveries()->void:
	var text:="A cartload of hides went by cart. Clay Sling Bullets and a pack saddle. Riders on horseback with guns."
	var early:=Voice.era_plain(text,[])
	assert_str(early).is_equal("A sledge-load of hides went by sledge. Clay Sling Stones and a pack frame. Runners on foot with fire-tubes.")
	assert_array(Voice.lexicon_hits(early,[])).is_empty()
	assert_str(Voice.era_plain(text,["wheel","saddles","riding","guns"])).is_equal(text)
	# A saddle quern is a grinding stone, and a potter's wheel is not a cart.
	assert_str(Voice.era_plain("grain on the saddle quern; wheel-thrown pots",[])).is_equal("grain on the saddle quern; wheel-thrown pots")

func test_wheel_words_open_with_the_real_wheel_discoveries()->void:
	Voice.knowledge_override["player"]=[]
	assert_str(Voice.era_plain_for("an ox cart","player")).is_equal("an ox sledge")
	Voice.knowledge_override["player"]=["solid_wheel_assembly"]
	assert_bool(Voice.era_tags("player").has("wheel")).is_true()
	assert_str(Voice.era_plain_for("an ox cart","player")).is_equal("an ox cart")
	Voice.knowledge_override["player"]=["pack_saddles"]
	var tags:=Voice.era_tags("player")
	assert_bool(tags.has("saddles") and not tags.has("riding")).is_true()
	assert_str(Voice.era_plain_for("Wooden Pack Saddles for the cavalry","player")).is_equal("Wooden Pack Saddles for the swift runners")

func test_the_chronicle_retells_what_the_people_cannot_name()->void:
	Voice.knowledge_override["player"]=[]
	for id in ["copper_outcrop_signs","ore_assaying","copper_smelting"]:GameState.known_discoveries.erase(id)
	var told:=Chronicle.record({"title":"The carts come home","text":"Two wagons of Copper Ore arrived.","tier":"notice"})
	assert_str(String(told.title)).is_equal("The sledges come home")
	assert_str(String(told.text)).is_equal("Two sledges of Green-stained Stone arrived.")

func test_ores_keep_their_look_until_the_metal_is_known()->void:
	assert_str(ResourceNames.label("Copper Ore",[])).is_equal("Green-stained Stone")
	assert_str(ResourceNames.label("Copper Ore",["copper_smelting"])).is_equal("Copper Ore")
	assert_str(ResourceNames.label("Iron Ore",["copper_smelting"])).is_equal("Heavy Red Stone")
	assert_str(ResourceNames.label("Iron Ore",["bloomery_smelting"])).is_equal("Iron Ore")
	assert_str(ResourceNames.label("Fiber Plants",[])).is_equal("Plant Fiber")
	assert_str(ResourceNames.plain("Prospectors locate Iron Ore",[])).is_equal("Prospectors locate Heavy Red Stone")
	GameState.known_discoveries.erase("copper_outcrop_signs");GameState.known_discoveries.erase("ore_assaying");GameState.known_discoveries.erase("copper_smelting")
	var card:=ExpeditionFindings.deposit_card({"resource":"Copper Ore","position":Vector3.ZERO,"id":"d1","quality":0.5},12)
	assert_str(String(card.title)+String(card.description)+String(card.consequence)).not_contains("copper")

func test_the_air_is_felt_until_a_thermometer()->void:
	assert_str(Hud.temperature_words(14.2,"↑",[])).is_equal("Mild ↑")
	assert_str(Hud.temperature_words(-12.0,"→",[])).is_equal("Bitter cold →")
	assert_str(Hud.temperature_words(40.0,"↓",[])).is_equal("Scorching ↓")
	assert_str(Hud.temperature_words(14.2,"↑",["precision_thermometry"])).is_equal("14°C ↑")
