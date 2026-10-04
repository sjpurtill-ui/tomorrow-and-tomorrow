extends GdUnitTestSuite
## THE WATER TILE TELLS THE TRUTH (hud/water_watch.gd, crisis_system.gd,
## dwindling_cause.gd, command_rail_hud.gd, kpi_detail_data.gd).
## The user, at year 61: "I lost 11 to thirst and THIS NEVER BUDGED!" beside a
## WATER tile at 5.3 days. Their save: the dry year "the Year the Springs
## Failed" (days 21556-21682) killed 4 at its middle and 7 at its end, written
## as thirst, while all three towns drank their fill from full stores (the
## dry year's toll is planned from how dry the season is, never from the
## store). So:
## - a dry year's own toll is written under its own cause, never thirst, with
##   the same ages taken; an older save's are re-read once, shallow spells
##   (found in the sickness & disaster log) included; its thirst, now that it
##   drains the water (test_dry_years_drain_water.gd), is thirst;
## - the People card says "lost to the dry year";
## - the WATER tile turns amber in a dry year and says its dead; red with the
##   worst town named when anyone went thirsty; amber when a town's store is
##   nearly gone; the hover card gives the water forecast's own numbers and
##   what more carriers or a cistern would save.
## Offline; never calls a real API.

const Crisis:=preload("res://scripts/crisis_system.gd")
const Watch:=preload("res://scripts/hud/water_watch.gd")
const Data:=preload("res://scripts/hud/kpi_detail_data.gd")
const Dwindling:=preload("res://scripts/dwindling_cause.gd")
const Rail:=preload("res://scripts/hud/command_rail_hud.gd")

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
	ForeignDiplomacy.ensure()
	ForeignDiplomacy.audiences.erase("crises")
	GameState.settlement_name="Ashleyfire"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	Crisis.onsets_enabled=false


func after_test()->void:
	Crisis.onsets_enabled=true


## The three towns of the user's save on its last day: every store full,
## everyone drinking (Ashleyfire, Seanlyfire, Wallyfire).
func _users_towns()->Dictionary:
	var cities:=[
		{"name":"Ashleyfire","population":115,"water_report":true,"water_stock":606.0,"water_capacity":728.3,"water_need":114.8,"water_produced":165.1,"water_eaten":114.8},
		{"name":"Seanlyfire","population":81,"water_report":true,"water_stock":428.2,"water_capacity":514.6,"water_need":81.1,"water_produced":116.7,"water_eaten":81.1},
		{"name":"Wallyfire","population":58,"water_report":true,"water_stock":306.9,"water_capacity":368.9,"water_need":58.2,"water_produced":83.6,"water_eaten":58.2},
	]
	var t:={"cities":cities,"water_stock":0.0,"water_capacity":0.0,"water_need":0.0}
	for city:Dictionary in cities:
		for key in ["water_stock","water_capacity","water_need"]:t[key]=float(t[key])+float(city[key])
	t["water_days"]=float(t.water_stock)/float(t.water_need)
	return t


## The user's dry year at its middle: 4 dead, carried by custom ("carry").
func _springs_failed(deaths:int=4)->Dictionary:
	return {"id":"c140","type":"drought","kind":"drought","phase":"mid","name":"the Year the Springs Failed","start":21556,"end_day":21682,
		"deaths":deaths,"thirst":0,"dead":[],"pop0":261,"sev":0.33415129256561904,"draw":0.06018884114340828,"m":0.045,"mult":1.0,"choice":"carry","mid_choice":"hold"}


func test_a_dry_year_kills_under_its_own_cause_not_thirst()->void:
	GameState.ensure_population_total(200)
	GameState.settlement_founded_day=0
	GameState.elapsed_days=900.0
	GameState.water_metrics={"stored":1000.0,"capacity":1200.0,"required_today":180.0,"intake_ratio":1.0,"days":5.6,"collected_today":250.0}
	var c:={"id":"c9","type":"drought","pop0":200,"m":0.06,"mult":1.0,"deaths":0,"dead":[]}
	var killed:=Crisis._kill(c,5,"mid")
	assert_int(killed).is_equal(5)
	var causes:=GameState.rolling_death_causes(365)
	assert_int(int(causes.get(Crisis.DROUGHT_CAUSE,0))).is_equal(5)
	assert_bool(causes.has("Dehydration")).is_false()
	assert_str(String(Crisis.TYPES.drought.cause)).is_equal("Drought")
	# The same ages as before: only the words changed.
	assert_dict(GameState._mortality_weights_for("Drought")).is_equal(GameState._mortality_weights_for("Dehydration"))


## A dry year's own toll goes under its own cause: run to its end with every
## store full, no one is written as thirst.
func test_a_dry_year_run_to_its_end_writes_no_thirst()->void:
	GameState.ensure_population_total(2000)
	GameState.settlement_founded_day=0
	var day:=-1
	for d in range(400,20000,17):
		if Crisis.drought_depth(d)<0.17:day=d;break
	assert_int(day).is_greater(0)
	GameState.elapsed_days=float(day)
	GameState.death_cause_days.clear()
	var x:=Crisis.inputs(day)
	x["weather_season"]=0.87;x["pop"]=2000.0
	Crisis._open_drought(day,x)
	var c:=Crisis._active_of("drought")
	# A dry season deep enough that its own toll surely kills among 2,000.
	c.sev=0.5
	for d in range(day+1,int(c.end_day)+60):
		GameState.elapsed_days=float(d)
		GameState.water_metrics={"stored":11000.0,"capacity":12600.0,"required_today":2000.0,"intake_ratio":1.0,"days":5.5,"collected_today":2800.0}
		if (Crisis.state().active as Dictionary).has(String(c.id)):Crisis._advance(c,d,Crisis.inputs(d))
	assert_int(int(c.deaths)).is_greater(0)
	var causes:=GameState.rolling_death_causes(365)
	assert_int(int(causes.get("Drought",0))).is_equal(int(c.deaths))
	assert_bool(causes.has("Dehydration")).is_false()


func test_the_users_dry_year_is_reread_as_the_dry_year_once()->void:
	GameState.elapsed_days=22024.0
	var s:=Crisis.state()
	(s.history as Array).push_front({"id":"c140","type":"drought","name":"the Year the Springs Failed","start":21556,"end":21682,"deaths":11})
	(s.history as Array).push_front({"id":"c148","type":"sickness","name":"the Coughing Winter of year 60","start":21744,"end":21800,"deaths":0})
	(s.flags as Dictionary).erase("drought_cause_v2")
	GameState.death_cause_days.assign([
		{"day":21600,"cause":"Dehydration","count":4},{"day":21659,"cause":"Natural causes","count":1},
		{"day":21682,"cause":"Dehydration","count":7},{"day":21700,"cause":"Natural causes","count":1},
		# A real thirst death outside the dry year stays thirst.
		{"day":21990,"cause":"Dehydration","count":2}])
	Crisis.reconcile_drought_causes(s)
	var all:=GameState.rolling_death_causes(500)
	assert_int(int(all.get("Drought",0))).is_equal(11)
	assert_int(int(all.get("Dehydration",0))).is_equal(2)
	assert_int(int(all.get("Natural causes",0))).is_equal(2)
	# Once only: the rows stand as they are on a second pass.
	var rows:=GameState.death_cause_days.duplicate(true)
	Crisis.reconcile_drought_causes(s)
	assert_array(GameState.death_cause_days).is_equal(rows)


func test_a_dry_year_never_takes_more_than_it_killed_from_thirst()->void:
	GameState.elapsed_days=5000.0
	var s:=Crisis.state()
	(s.history as Array).push_front({"id":"c3","type":"drought","name":"the Dry Year of year 12","start":4300,"end":4420,"deaths":6})
	(s.flags as Dictionary).erase("drought_cause_v2")
	GameState.death_cause_days.assign([{"day":4400,"cause":"Dehydration","count":9}])
	Crisis.reconcile_drought_causes(s)
	var all:=GameState.rolling_death_causes(1000)
	assert_int(int(all.get("Drought",0))).is_equal(6)
	assert_int(int(all.get("Dehydration",0))).is_equal(3)


## A shallow dry spell closes without a history line: its dead are found in
## the sickness & disaster log (the review's catch).
func test_a_shallow_spells_dead_are_reread_from_the_log()->void:
	GameState.elapsed_days=5000.0
	var s:=Crisis.state()
	(s.flags as Dictionary).erase("drought_cause_v2")
	preload("res://scripts/hardship_log.gd").note("c7@4300",{"crisis":"c7","type":"drought","name":"the Dry Year of year 12","start":4300,"end":4400,"dead":2})
	GameState.death_cause_days.assign([{"day":4350,"cause":"Dehydration","count":2},{"day":4900,"cause":"Dehydration","count":1}])
	Crisis.reconcile_drought_causes(s)
	var all:=GameState.rolling_death_causes(1000)
	assert_int(int(all.get("Drought",0))).is_equal(2)
	assert_int(int(all.get("Dehydration",0))).is_equal(1)
	# The WATER card hears of it too.
	assert_array(Watch.recent_droughts(1000).map(func(d:Dictionary)->String:return String(d.id))).contains(["c7"])


func test_the_people_card_names_the_dry_year_not_thirst()->void:
	assert_str(Dwindling.misfortune({"Drought":7,"Natural causes":13},7)).is_equal("7 lost to the dry year")
	assert_str(Dwindling.misfortune({"Dehydration":7,"Natural causes":13},7)).is_equal("7 lost to thirst")
	# The user's card, from their ledgers: born 13, buried 20 in the year,
	# 7 of the dry year's dead still inside it (written as thirst by the save).
	GameState.elapsed_days=22024.0
	var s:=Crisis.state()
	(s.history as Array).push_front({"id":"c140","type":"drought","name":"the Year the Springs Failed","start":21556,"end":21682,"deaths":11})
	(s.flags as Dictionary).erase("drought_cause_v2")
	GameState.death_cause_days.assign([{"day":21600,"cause":"Dehydration","count":4},{"day":21682,"cause":"Dehydration","count":7},{"day":21700,"cause":"Natural causes","count":13}])
	GameState.vital_statistics_tracking_start_day=20000
	GameState.vital_statistics_history.assign([{"day":21682,"births":0,"deaths":7},{"day":21700,"births":13,"deaths":13}])
	var card:=Data.card("population")
	assert_str(String(card.headline)).is_equal("More are buried than born: 7 lost to the dry year.")


func test_the_water_tile_in_the_users_dry_year()->void:
	GameState.elapsed_days=21600.0
	var ahead:={"now":{"thirst":6.2,"toll":0.9,"total":7.1,"dry_day":21610},"carriers":{"total":5.0},"cistern":{"total":6.0},
		"extra_carriers":13,"cisterns_known":false,"store_days":5.3,"today":21600.0}
	var read:=Watch.read(_users_towns(),_drought_reading(_springs_failed()),{},[],ahead)
	assert_str(String(read.tone)).is_equal("dry")
	assert_str(String(read.notes[0])).is_equal("dry year: 4 dead")
	assert_float(float(read.days)).is_equal_approx(5.28,0.01)
	assert_str(String(read.headline)).is_equal("Everyone drank their fill today, but the dry year is drying the springs: they give about 2 in 10 of what they did, and the stores still hold.")
	var texts:=PackedStringArray()
	for fact:Dictionary in read.facts:texts.append(String(fact.text))
	assert_array(Array(texts)).is_equal(["The Year the Springs Failed has taken 4 so far","About 7 more may die as things stand: 6 of thirst and one of the heat and the failed forage",
		"13 more on the water path would save about 2; cisterns, once the people learn to line them, would save about one","The stores run dry in about 10 days","No one died of thirst in the last year"])
	assert_str(String(read.status)).contains("Thirst is the water ledger's own count once the stores run out: at its worst the springs give 2 in 10 of what they did after the wells hold their part")
	assert_str(String(read.status)).contains("Going short of water also makes sickness likelier")
	assert_str(String(read.status)).contains("9.3 in 1,000 of the 261 people at this dryness, half that when everyone drinks.")


## The running dry year as drought_now reads it from the crisis ledger.
func _drought_reading(c:Dictionary)->Dictionary:
	(Crisis.state().active as Dictionary)[String(c.id)]=c
	var reading:=Watch.drought_now()
	assert_str(String(reading.get("id",""))).is_equal(String(c.id))
	return reading


func test_after_the_dry_year_the_tile_is_calm_and_the_card_says_what_it_took()->void:
	var read:=Watch.read(_users_towns(),{},{"Drought":7,"Natural causes":13},[{"id":"c140","name":"the Year the Springs Failed","deaths":11,"end":21682}])
	assert_str(String(read.tone)).is_equal("calm")
	assert_array(read.notes).is_equal(["of drinking water"])
	var texts:=PackedStringArray()
	for fact:Dictionary in read.facts:texts.append(String(fact.text))
	# Why 5.3 never moved: the stores were full, as full as they can be.
	assert_array(Array(texts)).is_equal(["The stores are full: they hold 6.3 days at most","The Year the Springs Failed took 11","No one died of thirst in the last year"])
	# A dry year that drained the water: its thirst is part of its dead.
	var drained:=Watch.read(_users_towns(),{},{"Dehydration":6,"Drought":5},[{"id":"c9","name":"the Dry Year of year 70","deaths":11,"thirst":6,"end":21682}])
	assert_str(String((drained.facts[1] as Dictionary).text)).is_equal("The Dry Year of year 70 took 11, 6 of them of thirst")


func test_a_town_gone_thirsty_is_named_with_its_days()->void:
	var t:=_users_towns()
	var sean:Dictionary=t.cities[1]
	sean.water_stock=0.0;sean.water_produced=40.5;sean.water_eaten=40.5;sean.population=80;sean.water_need=81.0
	var read:=Watch.read(t)
	assert_str(String(read.tone)).is_equal("short")
	assert_str(String(read.where)).is_equal("Seanlyfire")
	assert_float(float(read.days)).is_equal(0.0)
	assert_str(String(read.notes[0])).is_equal("Seanlyfire: 40 thirsty")
	assert_str(String(read.headline)).is_equal("Water is running short at Seanlyfire: nothing left in store, and 40 went thirsty today.")
	# One town alone: no name needed.
	var lone:={"cities":[sean],"water_days":0.0}
	assert_array(Watch.read(lone).notes).is_equal(["40 went thirsty"])


func test_a_store_nearly_gone_turns_amber_before_anyone_goes_thirsty()->void:
	var t:=_users_towns()
	var wally:Dictionary=t.cities[2]
	wally.water_stock=116.4;wally.water_produced=40.0
	var read:=Watch.read(t)
	assert_str(String(read.tone)).is_equal("low")
	assert_str(String(read.notes[0])).is_equal("Wallyfire running low")
	assert_str(String(read.headline)).is_equal("Water is running low at Wallyfire: 2 days held, and less is drawn than drunk. All drank their fill today.")


## No thirst forecast: the card says so, and gives no reason why more hands
## would not help (the review's catch).
func test_no_thirst_forecast_says_so()->void:
	GameState.elapsed_days=21600.0
	var ahead:={"now":{"thirst":0.2,"toll":0.9,"total":1.1,"dry_day":-1},"carriers":{"total":1.1},"cistern":{"total":1.1},
		"extra_carriers":13,"cisterns_known":true,"store_days":5.3,"today":21600.0}
	var read:=Watch.read(_users_towns(),_drought_reading(_springs_failed()),{},[],ahead)
	var texts:=PackedStringArray()
	for fact:Dictionary in read.facts:texts.append(String(fact.text))
	assert_array(Array(texts)).contains(["No one is forecast to go thirsty: the stores and the far pools hold"])
	for text in texts:assert_str(text).not_contains("More hands would not help")

func test_the_strip_turns_amber_in_a_dry_year_and_red_when_thirsty()->void:
	GameState.elapsed_days=21600.0
	var header=auto_free(LiveHeader.new())
	header.terrain=auto_free(HeaderTerrain.new())
	add_child(header)
	header.set_process(false)
	GameState.ensure_population_total(100)
	GameState.simulation_metrics={"food_days":49.0,"food_consumption":10.0,"food_eaten":10.0}
	GameState.water_metrics={"days":5.3,"required_today":10.0,"stored":53.0,"collected_today":14.0,"intake_ratio":1.0}
	header._refresh_kpis()
	assert_str(header.kpi_chips.water.value.text).is_equal("5.3 days")
	assert_str(header.kpi_chips.water.delta.text).is_equal("of drinking water")
	(Crisis.state().active as Dictionary)["c140"]=_springs_failed()
	header._refresh_kpis()
	assert_str(header.kpi_chips.water.value.text).is_equal("5.3 days")
	assert_str(header.kpi_chips.water.delta.text).is_equal("dry year: 4 dead")
	assert_object(header.kpi_chips.water.delta.get_theme_color("font_color")).is_equal(Rail.Tokens.text_for(Rail.Tokens.AMBER))
	# The dead of the dry year move the tile even when no store moves.
	(Crisis.state().active.c140 as Dictionary).deaths=6
	header._refresh_kpis()
	assert_str(header.kpi_chips.water.delta.text).is_equal("dry year: 6 dead")
	# Someone went thirsty: red, whatever the dry year.
	GameState.water_metrics={"days":0.0,"required_today":10.0,"stored":0.0,"collected_today":6.0,"intake_ratio":0.6}
	header._refresh_kpis()
	assert_str(header.kpi_chips.water.value.text).is_equal("under a day")
	assert_str(header.kpi_chips.water.delta.text).ends_with("went thirsty")
	assert_object((header.kpi_chips.water.accent as ColorRect).color).is_equal(Rail.Tokens.RED)
	# A name too long for the chip gives way to the shorter words.
	var note:String=header._fitting_note("water",["Llanqakarawyuqfire: 40 thirsty","Llanqakarawyuqfire short","40 went thirsty"])
	assert_str(note).is_equal("40 went thirsty")
	assert_str(header._fitting_note("water",["dry year: 4 dead","a dry year"])).is_equal("dry year: 4 dead")


func test_the_water_card_gives_the_dry_years_numbers()->void:
	GameState.elapsed_days=21600.0
	GameState.water_metrics={"days":5.3,"required_today":10.0,"stored":53.0,"collected_today":14.0,"intake_ratio":1.0}
	(Crisis.state().active as Dictionary)["c140"]=_springs_failed()
	var card:=Data.card("water")
	assert_str(String(card.tone)).is_equal("warning")
	assert_str(String(card.headline)).starts_with("Everyone drank their fill today, but the dry year is drying the springs: they give about 2 in 10")
	var drawer:=Data.snapshot("water")
	assert_str(String(drawer.status)).contains("half that when everyone drinks")
