extends "res://scripts/hud/content/dock_content_base.gd"
## The Chronicle rail entry: the story of the people as a count of years
## (hud/chronicle_feed.gd): a mark for every year on a spiral from the
## founding, the chosen year's facts and moments as pictures, and the years
## one line each. The tellings are one choice away; one labelled checkbox adds
## every season's tally. The one place for history: its other tabs are the
## town's own record (its founding, discoveries and building, its people and
## stores over the years), births and deaths, and what was built.
const Chronicle:=preload("res://scripts/chronicle.gd")
const Years:=preload("res://scripts/hud/chronicle_year_model.gd")

func meta()->Dictionary:
	var voice:=Chronicle.voice()
	# Our nation's name once given: "THE STORY OF THE REEDFOLK" (nation_name.gd).
	var nation:=preload("res://scripts/nation_name.gd").in_sentence(String(GameState.nation_name))
	return {"eyebrow":"THE STORY OF %s" % (nation.to_upper() if nation!="" else "THE PEOPLE"),"title":String(voice.feed),"subtabs":["The years","Our town","Births and deaths","What was built"]}

func tab(sub:int)->Dictionary:
	if sub==1:return {"blocks":_town_blocks()}
	# The two ledgers that used to open as screens of their own, as tabs here.
	if sub==2:return preload("res://scripts/hud/content/dock_detail_population_ledger.gd").new(terrain,hud).tab(0)
	if sub==3:return preload("res://scripts/hud/content/dock_detail_building_ledger.gd").new(terrain,hud,GameState.selected_player_settlement_id).tab(0)
	var today:=int(GameState.elapsed_days)
	return {"blocks":[{"type":"chronicle_feed","entries":Chronicle.entries("whisper"),"voice":Chronicle.voice(),
		"years":Years.build(Chronicle.data(),today,int(GameState.population_total)),"today":today}]}

## The town's own record: its founding, every discovery and its building
## records, then its people and stores over the years.
func _town_blocks()->Array:
	var Charts:=preload("res://scripts/hud/strategic_chart_blocks.gd")
	var settlement:Dictionary=SettlementModel.selected_settlement_snapshot()
	var id:=String(settlement.get("id",""))
	var events:Array=preload("res://scripts/hud/settlement_history_data.gd").events(settlement,GameState.discovery_log,GameState.building_ledger)
	return [{"type":"chronicle","heading":"Our town through the years","events":events},Charts.population(id,true),Charts.reserves(id)]

func signature()->Array:
	var entries:Array=GameState.chronicle.get("entries",[])
	var annals:Array=GameState.chronicle.get("annals",[]) if GameState.chronicle.get("annals") is Array else []
	return [entries.size(),String((entries[0] as Dictionary).get("key","")) if not entries.is_empty() else "",GameState.known_discoveries.size(),annals.size(),int(GameState.elapsed_days)/365]
