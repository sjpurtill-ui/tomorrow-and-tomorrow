extends RefCounted
## A BEATEN BAND WITHDRAWS AND RECOVERS.
##
## Rival field armies reach the observer as formations rebuilt each day from
## fresh sightings (civilization_combat.troop_views), so a stand-down written
## on the formation itself was lost overnight: a band that had recovered a
## little morale could be pursued and fought again every day ("waves").
##
## The observer's own CivilizationSystem keeps what it learned about each
## formation, keyed by its stable id ("civ:army:7", "civ_01_patrol"), in
## `formation_memory`, and lays it back over every rebuilt view:
##   - stand-down: out of reach (not sighted, not engaged) until `until`;
##   - morale: from what the band had left after the fight back to whole,
##     over RECOVERY_DAYS; a fight before then meets the band as it is.
## Historical sense: a band broken in the field scattered home, and its men
## came back to a war leader over weeks to a couple of months; a band that
## was only shaken reformed within a fortnight or two.
##
## Pure over the memory dictionary and formation records; no scene access.

## A band beaten in the field (broken, routed, driven off) stands down this long.
const BEATEN_DAYS:=45
## A band only shaken (morale under this after the fight) regroups this long.
const SHAKEN_DAYS:=15
const SHAKEN_MORALE:=0.42
## Morale returns to whole over this many days from the fight.
const RECOVERY_DAYS:=75
const MAX_ENTRIES:=64


## What a fight did to a rival formation. rival: the rival side of the
## battle record; home_name: our force's name; termination: the record's.
static func remember(memory:Dictionary,formation_id:String,day:int,rival:Dictionary,termination:Dictionary)->Dictionary:
	if formation_id=="": return {}
	var morale:=clampf(float(rival.get("morale",1.0)),0.0,1.0)
	var name:=String(rival.get("name",""))
	var beaten:=(name!="" and String(termination.get("defeated",""))==name) or String(termination.get("type",""))=="mutual_withdrawal" or morale<=0.15
	var until:=day+(BEATEN_DAYS if beaten else (SHAKEN_DAYS if morale<SHAKEN_MORALE else 0))
	var previous:Dictionary=memory.get(formation_id,{})
	var entry:={"day":day,"until":maxi(until,int(previous.get("until",0))),"morale":morale,"beaten":beaten}
	memory[formation_id]=entry
	while memory.size()>MAX_ENTRIES:
		var oldest:="";var oldest_day:=1<<40
		for key in memory:
			if int((memory[key] as Dictionary).get("day",0))<oldest_day: oldest_day=int(memory[key].day); oldest=String(key)
		memory.erase(oldest)
	return entry


## Morale the band can bring to a fight on `day` (1.0 when nothing is known).
static func morale_cap(memory:Dictionary,formation_id:String,day:int)->float:
	var entry:Dictionary=memory.get(formation_id,{})
	if entry.is_empty(): return 1.0
	var t:=clampf(float(day-int(entry.day))/float(RECOVERY_DAYS),0.0,1.0)
	return lerpf(float(entry.morale),1.0,t)


static func standing_down(memory:Dictionary,formation_id:String,day:int)->bool:
	return day<int((memory.get(formation_id,{}) as Dictionary).get("until",0))


## Lay the memory back over freshly rebuilt formation views; forget what has
## healed.
static func apply(memory:Dictionary,formations:Array,day:int)->void:
	for key in memory.keys():
		if day>int((memory[key] as Dictionary).get("day",0))+RECOVERY_DAYS: memory.erase(key)
	if memory.is_empty(): return
	for index in formations.size():
		var formation:Dictionary=formations[index]
		var id:=String(formation.get("id",""))
		if not memory.has(id): continue
		var entry:Dictionary=memory[id]
		formation["disabled_until_day"]=maxi(int(formation.get("disabled_until_day",0)),int(entry.until))
		formation["readiness"]=minf(float(formation.get("readiness",1.0)),maxf(0.08,morale_cap(memory,id,day)))
		formation["morale_cap"]=morale_cap(memory,id,day)


static func valid(memory:Variant)->bool:
	if not memory is Dictionary or (memory as Dictionary).size()>MAX_ENTRIES: return false
	for key in memory:
		var entry:Variant=memory[key]
		if not entry is Dictionary or not (entry as Dictionary).has_all(["day","until","morale"]): return false
	return true
