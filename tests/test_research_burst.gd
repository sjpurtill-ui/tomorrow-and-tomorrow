extends GdUnitTestSuite
## A foundation found late must not hold a whole tree shut, and the rush of
## learning it frees reads as one line, not a flood (the player's year-96 rush:
## a woodland people knapped flint for 96 years without Stone Selection, then
## learned about 75 practices of their age within one year).
const Chronicle:=preload("res://scripts/chronicle.gd")
const Research600:=preload("res://scripts/research_600_catalog.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(90210)
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.research_notification_mode="milestones"
	Chronicle.pending_cards.clear()

func after_test()->void:
	WorldSimulation.clear()

## Home ground with no loose stone and no flint of its own.
func _stoneless_home()->void:
	GameState.player_settlements=[{"id":"home","environment_profile":{"resource_potentials":{"Stone":0.0,"Flint":0.0,"Limestone":0.0}}}]
	GameState.resource_deposits=[]
	GameState.resource_stockpiles["Stone"]=0.0

func _stone_selection_open()->bool:
	var entry:=DiscoverySystem.discovery_definition("stone_sorting")
	return DiscoverySystem._resource_requirements_met(entry.get("resource_requirements",[]))

func test_worked_flint_or_limestone_is_stone_known()->void:
	_stoneless_home()
	assert_bool(_stone_selection_open()).is_false()
	GameState.resource_deposits=[{"resource":"Clay","stage":"developed"}]
	assert_bool(_stone_selection_open()).is_false()
	GameState.resource_deposits=[{"resource":"Flint","stage":"developed"}]
	assert_bool(_stone_selection_open()).is_true()
	GameState.resource_deposits=[{"resource":"Limestone","stage":"recognized"}]
	assert_bool(_stone_selection_open()).is_true()
	# Stage for stage: a limestone clue is not a surveyed quarry face.
	var quarry:=DiscoverySystem.discovery_definition("quarry_reading")
	assert_bool(DiscoverySystem._resource_requirements_met(quarry.get("resource_requirements",[]))).is_false()
	GameState.resource_deposits=[{"resource":"Limestone","stage":"surveyed"}]
	assert_bool(DiscoverySystem._resource_requirements_met(quarry.get("resource_requirements",[]))).is_true()

func test_home_flint_is_home_stone()->void:
	_stoneless_home()
	GameState.player_settlements=[{"id":"home","environment_profile":{"resource_potentials":{"Stone":0.0,"Flint":0.19}}}]
	assert_bool(_stone_selection_open()).is_true()
	# The design conditions and rivals read stone the same way.
	assert_bool((DiscoverySystem.research_600_player_society().resources as Dictionary).has("Stone")).is_true()
	assert_float(Research600.potential({"Stone":0.0,"Flint":0.19},"Stone")).is_equal(0.19)
	assert_float(Research600.potential({"Flint":0.5},"Clay")).is_equal(0.0)

## `count` unknown questions of one field, none an era milestone.
func _field_run(count:int)->Array:
	var by_field:Dictionary={}
	for id in DiscoverySystem.catalog_by_id:
		if id in GameState.known_discoveries or String(id) in Chronicle.RESEARCH_MILESTONES:continue
		var field:=String((DiscoverySystem.catalog_by_id[id] as Dictionary).get("dynamic",""))
		if field=="":continue
		var list:Array=by_field.get(field,[])
		list.append(String(id));by_field[field]=list
		if list.size()>=count:return list
	return []

func test_a_rush_of_learning_is_one_ledger_line()->void:
	var run:=_field_run(12)
	assert_int(run.size()).is_equal(12)
	GameState.known_discoveries.append_array(run)
	# The first in its field is a moment; ten repeats come in one season.
	GameState.elapsed_days=100.0
	Chronicle.ingest_day({"discoveries":[{"id":run[0],"day":100}],"progression":[]})
	for i in range(1,11):
		GameState.elapsed_days=100.0+i*3
		Chronicle.ingest_day({"discoveries":[{"id":run[i],"day":100+i*3}],"progression":[]})
	# A new season tells the rush.
	GameState.elapsed_days=190.0
	Chronicle.ingest_day({"discoveries":[{"id":run[11],"day":190}],"progression":[]})
	var ledger:=GameState.simulation_events.filter(func(e:Dictionary)->bool:return String(e.get("id","")).begins_with("chronicle_discovery:"))
	# The moment, the season's first LEARNED_LEDGER_LINES, and the new season's first.
	assert_int(ledger.size()).is_equal(1+Chronicle.LEARNED_LEDGER_LINES+1)
	var rush:=GameState.simulation_events.filter(func(e:Dictionary)->bool:return String(e.get("id","")).begins_with("chronicle_learned:"))
	assert_int(rush.size()).is_equal(1)
	assert_str(String(rush[0].title)).is_equal("What the summer taught: 10 new ways")
	assert_str(String(rush[0].description)).contains("This season the people learned 10 new ways, among them")
	# Four names, never the whole list.
	var named:=0
	for i in range(1,11):
		var name:=String(DiscoverySystem.player_facing_discovery_event({"id":run[i]}).get("name",run[i])).to_lower()
		if String(rush[0].description).contains(name):named+=1
	assert_int(named).is_equal(Chronicle.LIST_NAMES)
	# Every finding is still kept in the season's tally and the chronicle.
	var batch:Dictionary=Chronicle.entries("whisper").filter(func(e:Dictionary)->bool:return String(e.get("key","")).begins_with("learned:"))[0]
	assert_int((batch.learned as Array).size()).is_equal(10)

func test_a_quiet_season_keeps_its_plain_list()->void:
	var run:=_field_run(4)
	assert_int(run.size()).is_equal(4)
	GameState.known_discoveries.append_array(run)
	GameState.elapsed_days=100.0
	Chronicle.ingest_day({"discoveries":[{"id":run[0],"day":100}],"progression":[]})
	for i in [1,2]:
		GameState.elapsed_days=100.0+i*10
		Chronicle.ingest_day({"discoveries":[{"id":run[i],"day":100+i*10}],"progression":[]})
	GameState.elapsed_days=190.0
	Chronicle.ingest_day({"discoveries":[{"id":run[3],"day":190}],"progression":[]})
	assert_int(GameState.simulation_events.filter(func(e:Dictionary)->bool:return String(e.get("id","")).begins_with("chronicle_learned:")).size()).is_equal(0)
	var batch:Dictionary=Chronicle.entries("whisper").filter(func(e:Dictionary)->bool:return String(e.get("key","")).begins_with("learned:"))[0]
	assert_str(String(batch.title)).is_equal("What the summer taught")
	assert_str(String(batch.text)).contains("This season the people learned:")
