extends Node
var failures:Array[String]=[]
func check(condition:bool,message:String)->void:
	if not condition: failures.append(message)
func _ready()->void:
	var original:=HistoricalFigures.export_state()
	var existing_population:int=GameState.population_total
	HistoricalFigures.reset_for_new_world(); HistoricalFigures.ensure()
	var initial:=HistoricalFigures.export_state()
	HistoricalFigures.reset_for_new_world(); HistoricalFigures.ensure()
	check(HistoricalFigures.export_state()==initial,"same seed changed identities")
	var used:Dictionary={}
	for tradition in HistoricalNameGenerator.POOLS:
		for woman in [true,false]:
			for i in 192:
				var generated:=HistoricalNameGenerator.make(123,i,woman,tradition,used)
				check(not generated.is_empty(),"name generator exhausted early")
				if not generated.is_empty(): used[generated.name]=true
	check(used.size()==1536,"name combinations not unique")
	check(HistoricalFigures.people.size()==8,"missing founding vocations")
	var scholar:Dictionary=HistoricalFigures.people[1]
	var physician:Dictionary=HistoricalFigures.people[2]
	check(HistoricalFigures.multiplier("knowledge")==1.0,"unsupported figure grants research")
	HistoricalFigures.support(scholar.id)
	check(HistoricalFigures.multiplier("knowledge")>1.2,"patronage has no mechanical benefit")
	HistoricalFigures.support(physician.id); HistoricalFigures.support(HistoricalFigures.people[3].id)
	check(HistoricalFigures.support(HistoricalFigures.people[4].id).has("error"),"patronage cap bypassed")
	HistoricalFigures.advance(365*3)
	var work:int=scholar.work_days
	HistoricalFigures.advance(365*3)
	check(scholar.work_days==work,"duplicate daily processing accrued work")
	HistoricalFigures.record_discovery("knowledge","Test discovery",365*3)
	check(scholar.renown>=8,"discovery did not enter biography")
	HistoricalFigures.record_death(scholar.id,365*3,"test battle")
	var legacy:float=scholar.legacy
	HistoricalFigures.record_death(scholar.id,365*3,"duplicate")
	check(scholar.legacy==legacy and legacy>0,"death duplicated or erased legacy")
	check(HistoricalFigures.multiplier("knowledge")>1.0 and HistoricalFigures.multiplier("knowledge")<1.2,"legacy not smaller than living benefit")
	check(GameState.population_total==existing_population,"figure death double-counted population")
	var commander:=HistoricalFigures.commander({"command":.5},"home")
	var original_id:String=commander.figure_id
	HistoricalFigures.record_battle({"seed":44,"round_count":2,"attacker":{"name":"A","commander":commander,"remaining_troops":100},"defender":{},"termination":{"defeated":"A","commander_fate":"killed"},"outcome":"defender_victory"})
	check(HistoricalFigures.by_id(original_id).status=="dead","battle did not kill named figure")
	check(HistoricalFigures.commander({"command":.5},"home").figure_id!=original_id,"dead general returned to command")
	var captive:=HistoricalFigures.commander({"command":.5},"test_captive")
	HistoricalFigures.record_battle({"seed":45,"round_count":1,"attacker":{"name":"C","commander":captive,"remaining_troops":50},"defender":{},"termination":{"defeated":"C","commander_fate":"captured"},"outcome":"defender_victory"})
	check(HistoricalFigures.by_id(captive.figure_id).status=="captured","captured general remained available")
	HistoricalFigures.resolve_captive(captive.figure_id,"release")
	check(HistoricalFigures.by_id(captive.figure_id).status=="living","released general did not return")
	var saved:=HistoricalFigures.export_state()
	var json_saved:Dictionary=JSON.parse_string(JSON.stringify(saved))
	check(HistoricalFigures.import_state(json_saved).get("ok",false),"JSON save round trip rejected")
	check(HistoricalFigures.by_id(original_id).status=="dead","save resurrected general")
	var invalid:=saved.duplicate(true); invalid.people.append(invalid.people[0])
	check(HistoricalFigures.import_state(invalid).has("error"),"invalid duplicate roster accepted")
	check(HistoricalFigures.people.size()==saved.people.size(),"failed import partially changed state")
	HistoricalFigures.advance(365*300)
	check(HistoricalFigures.living_count()<=12 and HistoricalFigures.people.size()<=512,"roster grew beyond bounds")
	check(HistoricalFigures.multiplier("knowledge")<=1.6,"stacked legacy bypassed cap")
	HistoricalFigures.import_state(original)
	if failures.is_empty(): print("HISTORICAL_FIGURES PASS: 1536 unique names, deterministic bios, patronage, discovery deeds, death, legacy, succession, JSON saves, bounded growth")
	else:
		for message in failures: push_error(message)
	get_tree().quit(0 if failures.is_empty() else 1)
