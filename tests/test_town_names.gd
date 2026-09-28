extends GdUnitTestSuite
## ONE NAME FOR A TOWN (scripts/town_names.gd) and towns that keep their
## regions (world_simulation.project). A held town is named as the map's
## label names it by the court, the war chart's garrison tag, the army bar
## and the supply map; and when a people's capital falls and another town
## becomes their capital, no region turns into another town: every town keeps
## its region, its name and its place.

const TownNames:=preload("res://scripts/town_names.gd")
const Supply:=preload("res://scripts/supply_state.gd")

var _processing:Dictionary={}
var civ_id:=""
var town_id:=""

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(4242);GameState.civic_api_enabled=false
	FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.settlement_site_committed=true;GameState.settlement_name="Seanstone"
	Supply.reset()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ_id=String(civ.id)
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren";region["population"]=300.0
	town_id=String(region.id)

func after_test()->void:
	Supply.reset()
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	GameState.reset_for_new_world(4242)
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))

## Tsaren taken and held; the chart's record of it says `charted`.
func _hold(charted:String)->void:
	var day:=int(GameState.elapsed_days)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",town_id,.8,day,"field campaign report","capture"),day)
	var at:=CivilizationSystem.player_world_origin+Vector2(60,0)
	CivilizationSystem.city_intelligence.records.player[town_id]["position"]={"x":at.x,"z":at.y}
	CivilizationSystem.city_intelligence.records.player[town_id]["name"]=charted
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ri:=CivilizationSystem._region_index(civ,town_id)
	civ.strategic_regions[ri]["controller"]="player"
	MilitaryCampaign.occupation_forces.assign([{"civ_id":civ_id,"region_id":town_id,"region_name":"Tsaren","troops":17,"formations":[],"supply_level":1.0,"commander":{"name":"Rovik Ashdown"}}])


func test_a_town_is_named_as_the_map_names_it()->void:
	# The world's name, when the chart has no record of the town.
	assert_str(TownNames.of(civ_id,town_id,"what we were told")).is_equal("Tsaren")
	# The chart's own record comes first; a scout's placeholder does not.
	_hold("Nseko")
	assert_str(TownNames.of(civ_id,town_id,"Tsaren")).is_equal("Nseko")
	CivilizationSystem.city_intelligence.records.player[town_id]["name"]="Reported home of the Esurai"
	assert_str(TownNames.of(civ_id,town_id,"Tsaren")).is_equal("Tsaren")
	# Nothing known of it at all: what the caller was told.
	assert_str(TownNames.of("","no_such_town","Kelvra")).is_equal("Kelvra")
	assert_str(Supply.town_name(civ_id,"no_such_town","Kelvra")).is_equal("Kelvra")

func test_the_court_the_war_chart_and_the_army_bar_name_a_held_town_as_the_map_does()->void:
	_hold("Nseko")
	var Facts=load("res://scripts/court_facts.gd")
	var sheet:Dictionary=Facts.sheet(["war"])
	var garrisons:Array=sheet.garrisons
	assert_int(garrisons.size()).is_equal(1)
	assert_str(String(garrisons[0].town)).is_equal("Nseko")
	for t:Dictionary in sheet.towns:
		if String(t.region_id)==town_id: assert_str(String(t.name)).is_equal("Nseko")
	assert_str(String(Facts.text(sheet))).contains("Nseko: 17 fighters")
	assert_str(String(Facts.text(sheet))).not_contains("Tsaren: 17 fighters")
	var WarOrders=load("res://scripts/court_war_orders.gd")
	assert_str(String((WarOrders.held_towns()[0] as Dictionary).name)).is_equal("Nseko")
	var Overlay=load("res://scripts/hud/war_front_overlay.gd")
	var inputs:Array=Overlay._garrison_inputs()
	assert_int(inputs.size()).is_equal(1)
	assert_str(String(inputs[0].town)).is_equal("Nseko")
	var Bar=load("res://scripts/hud/army_bar_model.gd")
	var card:Dictionary=Bar._garrison_card(MilitaryCampaign,MilitaryCampaign.occupation_forces[0])
	assert_str(JSON.stringify(card)).contains("Nseko")
	assert_str(JSON.stringify(card)).not_contains("Tsaren")
	assert_str(String(Supply.of_force(MilitaryCampaign.occupation_forces[0]).name)).is_equal("Nseko")


# --------------------------------------------------------------------------
# Towns keep their regions (world_simulation.project)
# --------------------------------------------------------------------------

## A home and three towns, each at its own place.
func _towns()->Array:
	SettlementModel.reset_for_new_world()
	GameState.settlement_completed.append("Hearth Circle")
	SettlementModel._ensure_primary_settlement_record()
	GameState.ensure_population_total(400)
	var primary:Dictionary=GameState.player_settlements[0]
	primary["name"]="Seanstone"
	var names:=["Ashford","Brenwick","Coldharbour"]
	for k in names.size():
		var town:Dictionary=primary.duplicate(true)
		town.id="settlement_%03d" % (k+2); town.sequence=k+2
		town.primary=false; town.name=names[k]; town.population_share=.1
		town.position=Vector2(40.0*float(k+1),10.0)
		GameState.player_settlements.append(town)
	return GameState.player_settlements

## {city id: [region id, name, position, controller, role]} from a projection.
func _bindings(summary:Dictionary)->Dictionary:
	var out:={}
	for region:Dictionary in summary.strategic_regions:
		if not bool(region.get("settlement_founded",false)): continue
		out[String(region.local_city_id)]=[String(region.id),String(region.name),region.position,String(region.controller),String(region.get("role",""))]
	return out

func test_a_capital_that_falls_keeps_its_region_and_every_town_keeps_its_name()->void:
	var towns:=_towns()
	var summary:Dictionary=CivilizationSystem.civilizations[0].duplicate(true)
	WorldSimulation.project(summary)
	var before:=_bindings(summary)
	assert_int(before.size()).is_equal(4)
	var old_capital:=String(towns[0].id)
	assert_str(String(before[old_capital][4])).is_equal("capital")
	# The capital falls; another town becomes the capital, as siege_recovery
	# hands the capital on (its own _activate_capital).
	towns[0]["occupied_by"]="rival_x"
	MilitaryCampaign.recovery._activate_capital(towns[2])
	assert_bool(bool(towns[2].primary)).is_true()
	assert_bool(bool(towns[0].primary)).is_false()
	WorldSimulation.project(summary)
	var after:=_bindings(summary)
	assert_int(after.size()).is_equal(4)
	for city_id in before:
		# Same region, same name, same place for every town.
		assert_str(String(after[city_id][0])).is_equal(String(before[city_id][0]))
		assert_str(String(after[city_id][1])).is_equal(String(before[city_id][1]))
		assert_that(after[city_id][2]).is_equal(before[city_id][2])
	# The fallen capital's region is still that town, now the occupier's; the
	# new capital stands in its own region. Regions keep their roles.
	assert_str(String(after[old_capital][3])).is_equal("rival_x")
	assert_str(String(after[String(towns[2].id)][0])).is_not_equal(String(after[old_capital][0]))
	for city_id in before: assert_str(String(after[city_id][4])).is_equal(String(before[city_id][4]))

func test_a_town_taken_leaves_the_others_named_and_placed()->void:
	var towns:=_towns()
	var summary:Dictionary=CivilizationSystem.civilizations[0].duplicate(true)
	WorldSimulation.project(summary)
	var before:=_bindings(summary)
	towns[1]["occupied_by"]="rival_x"
	WorldSimulation.project(summary)
	var after:=_bindings(summary)
	for city_id in before:
		assert_str(String(after[city_id][0])).is_equal(String(before[city_id][0]))
		assert_str(String(after[city_id][1])).is_equal(String(before[city_id][1]))
	assert_str(String(after[String(towns[1].id)][3])).is_equal("rival_x")

func test_a_copied_regions_old_towns_do_not_hold_its_regions()->void:
	# A summary whose regions name towns not in this network (a copy, a stale
	# save) is bound afresh, in the same places as ever.
	_towns()
	var summary:Dictionary=CivilizationSystem.civilizations[0].duplicate(true)
	for region:Dictionary in summary.strategic_regions: region["local_city_id"]="elsewhere_%s" % String(region.id)
	var count:=(summary.strategic_regions as Array).size()
	WorldSimulation.project(summary)
	assert_int((summary.strategic_regions as Array).size()).is_equal(count)
	var capital:Dictionary=summary.strategic_regions[4]
	assert_str(String(capital.local_city_id)).is_equal(String(GameState.player_settlements[0].id))
	assert_str(String((summary.strategic_regions[0] as Dictionary).local_city_id)).is_equal(String(GameState.player_settlements[1].id))
