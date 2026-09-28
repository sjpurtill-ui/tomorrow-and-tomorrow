extends RefCounted
## A town we took and hold, as our own garrison knows it: exact figures from
## the world itself, never a scout's estimate. Our fighters live there, so
## there is nothing stale to warn about and no range to guess across.
##
## report(city_id) -> {} when we do not hold it (the scouting view applies), or
## {city_id, civ_id, name, people ("the Esurai"), since, since_words,
##  residents, home_name, home_population, garrison, needed, enough,
##  general, talk_target, happened:[String], rule, rule_note, resistance,
##  resistance_words, mood_words, food_words, food_eaten, food_local,
##  food_sent, tribute, walls, walls_words, damage, damage_words,
##  rebuilding, lead, facts:{key: sentence}}
## Every figure is read live; the report is rebuilt on each call.
const Ownership=preload("res://scripts/map_ownership.gd")
const Governance=preload("res://scripts/occupation_governance.gd")
const FieldRations=preload("res://scripts/field_rations.gd")
const Measures=preload("res://scripts/occupation_measures.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
const P=preload("res://scripts/hud/paper_sheet.gd")

## How we rule it, in plain words (occupation_governance.gd POLICIES).
const RULE_WORDS:={"stewardship":"Governed as ours","self_rule":"Their own elders","equal_citizenship":"As our own people","military_rule":"By the spear","forced_labor":"Enslaved"}
const RESISTANCE:=["They accept our rule","A few grumble at our rule","Many resent our rule","They resist us openly","They are close to rising against us"]
const WELFARE:=["they suffer badly","they go without","they get by","they live well"]
const TRUST:=["do not trust us","barely trust us","somewhat trust us","trust us"]
const DAMAGE:=["The town stands whole","Some of it is damaged","Much of it lies broken","Most of it is in ruins"]

static func _level(value:float,words:Array)->String:
	return String(words[clampi(int(clampf(value,0.0,1.0)*words.size()),0,words.size()-1)])

static func _n(value:int)->String:
	return EraWords.grouped(maxi(0,value))

## "Year 96 · Spring" -> " in the spring of Year 96" (sentence form).
static func _in_season(when:String)->String:
	if when=="":return ""
	var parts:=when.split(" · ")
	return " in the %s of %s" % [parts[1].to_lower(),parts[0]] if parts.size()==2 else " in "+when

static func _first_up(text:String)->String:
	return text.left(1).to_upper()+text.substr(1) if text!="" else text

## Is this town ours right now, in the world itself?
static func held(city_id:String)->bool:
	return not Ownership.player_hold(city_id).is_empty()

static func report(city_id:String)->Dictionary:
	var hold:=Ownership.player_hold(city_id)
	if hold.is_empty():return {}
	var civ_id:=String(hold.original)
	var region:Dictionary=CivilizationSystem.region_snapshot(civ_id,city_id)
	if region.is_empty():return {}
	var force:Dictionary=MilitaryCampaign.occupation_force_for_region(civ_id,city_id)
	var name:=String(region.get("name","the town"))
	var home_name:=String(GameState.settlement_name) if String(GameState.settlement_name)!="" else "home"
	var out:={"city_id":city_id,"civ_id":civ_id,"name":name,"people":Ownership.people(civ_id),"since":int(hold.since),
		"since_words":EraWords.when(int(hold.since)) if int(hold.since)>=0 else "","home_name":home_name,"home_population":int(GameState.population_total)}
	out.residents=maxi(0,roundi(float(region.get("population",0.0))))
	# Our garrison and who leads it.
	out.garrison=maxi(0,int(force.get("troops",0)))
	out.needed=ceili(CivilizationSystem.occupation_requirement(CivilizationSystem.civilizations[CivilizationSystem._civilization_index(civ_id)],region))
	var control:Dictionary=CivilizationSystem.occupation_control(civ_id,city_id) if int(out.garrison)>0 else {"error":"none"}
	out.enough=int(out.garrison)>0 and not control.has("error")
	var leader:Dictionary=P.general_for(force) if not force.is_empty() else P.war_leader()
	out.general=String(leader.get("name",""))
	out.talk_target=(leader.get("target",{}) as Dictionary).duplicate()
	var commander:=String((force.get("commander",{}) as Dictionary).get("name","")) if force.get("commander") is Dictionary else ""
	out.commander=commander
	# How they take our rule.
	var gov:=Governance.state(region)
	var rules:Dictionary=Governance.POLICIES.get(String(gov.policy),Governance.POLICIES.stewardship)
	out.rule=String(RULE_WORDS.get(String(gov.policy),rules.get("label","Our own way")))
	out.resistance=float(region.get("resistance",0.5))
	out.resistance_words=_level(float(out.resistance),RESISTANCE)
	out.mood_words="%s, and they %s" % [_first_up(_level(float(gov.welfare),WELFARE)),_level(float(gov.trust),TRUST)]
	# Walls and damage, as fact.
	out.damage=clampf(float(region.get("damage",0.0)),0.0,1.0)
	out.walls=clampf(float(region.get("fortification",0.0))*(1.0-float(out.damage)*.65),0.0,1.0)
	# Same thresholds as the sketch draws them: stakes up to .55, a wall above.
	out.walls_words="No wall worth the name" if float(out.walls)<=.1 else "A low fence of stakes" if float(out.walls)<=.3 else "A palisade of stakes rings the houses" if float(out.walls)<=.55 else "High walls, kept in repair" if float(out.walls)<=.8 else "Strong walls all round"
	out.rebuilding=bool(gov.get("reconstruction",false))
	out.damage_words=_level(float(out.damage),DAMAGE)+("; rebuilding is under way" if bool(out.rebuilding) else "" if float(out.damage)<.25 else "; no one is rebuilding it")
	# Food: what the garrison eats, what the town gives, what home sends.
	var eaten:=float(force.get("provisions_required_today",0.0))
	var local:=float(force.get("provisions_local_today",0.0))
	var sent:=float(force.get("provisions_delivered_today",0.0))
	out.food_eaten=roundi(eaten);out.food_local=roundi(local);out.food_sent=roundi(sent)
	var share:=FieldRations.occupation_local_share(region)
	if int(out.garrison)<=0:out.food_words="No one of ours eats there."
	elif eaten>=0.5:
		out.food_words="Our fighters there eat %s Food a day. %s gives %s of it and %s sends %s." % [_n(roundi(eaten)),name,_n(roundi(local)),home_name,_n(roundi(sent))]
		if roundi(local+sent)<roundi(eaten):out.food_words+=" They go short by %s." % _n(roundi(eaten-local-sent))
	else:
		out.food_words="%s feeds about %d in 10 of our fighters' meals there; %s sends the rest." % [name,clampi(roundi(share*10.0),0,10),home_name]
	# What happened there since we took it.
	var fate:Dictionary=force.get("fate",{}) if force.get("fate") is Dictionary else {}
	var happened:Array[String]=[]
	if int(fate.get("killed",0))>0:happened.append("%s of its people were put to the sword." % _n(int(fate.killed)))
	var road:=_on_the_road(civ_id,city_id)
	var arrived:=_arrived(city_id)
	if int(fate.get("captives",0))>0:happened.append("%s women and children were led away as captives." % _n(int(fate.captives)))
	if int(fate.get("moved",0))>0:happened.append("%s of its people set out to live in %s." % [_n(int(fate.moved)),home_name])
	for status:String in road:
		var walk:Dictionary=road[status]
		var days:=int(walk.days)
		happened.append("%s %s on the road to %s, %s." % [_n(int(walk.people)),"captives are" if status=="enslaved" else "people bound to labour are" if status=="penal" else "people are",home_name,"about a day away" if days<=1 else "about %d days away" % days])
	for status:String in arrived:
		happened.append("%s from %s now live in %s %s." % [_n(int(arrived[status])),name,home_name,"as slaves" if status=="enslaved" else "as bonded labourers" if status=="penal" else "as our own people"])
	if int(fate.get("tribute",0))>0:happened.append("We took %s Food from their stores as tribute." % _n(int(fate.tribute)))
	# What our garrison is doing with its people now (occupation_measures.gd).
	out.measures=Measures.report_lines(civ_id,city_id)
	if happened.is_empty():
		# While measures run, the card note is theirs; the last order waits behind it.
		var note:=String(force.get("note_before" if bool(force.get("measure_note",false)) else "fate_note","")).strip_edges()
		if note!="":happened.append("Last order: %s." % note.trim_suffix("."))
		elif (out.measures as Array).is_empty():happened.append("Nothing has been done to its people since we took it.")
	out.happened=happened
	out.tribute=int(fate.get("tribute",0))
	# One plain opening sentence.
	var lead:="%s is ours, taken from %s%s. %s people live there now" % [name,String(out.people),_in_season(String(out.since_words)),_n(int(out.residents))]
	if int(out.garrison)>0:lead+=" and %s of our fighters hold it%s." % [_n(int(out.garrison))," under "+P.first_name(String(out.commander if commander!="" else out.general)) if (commander!="" or String(out.general)!="") else ""]
	else:lead+="; none of our fighters are left there."
	out.lead=lead
	var compare:=""
	if int(out.home_population)>0:compare=" %s has %s." % [home_name,_n(int(out.home_population))]
	out.facts={
		"population":"%s people live in %s now.%s" % [_n(int(out.residents)),name,compare],
		"garrison":("%s of ours hold it. It needs about %s to keep order; %s." % [_n(int(out.garrison)),_n(int(out.needed)),"they are enough" if bool(out.enough) else "they are too few, or too hungry"]) if int(out.garrison)>0 else "No one of ours guards it.",
		"supply":String(out.food_words),
		"fortification":String(out.walls_words)+".",
		"damage":String(out.damage_words)+".",
		"resistance":"%s. %s." % [String(out.resistance_words),String(out.mood_words)],
	}
	if not (out.measures as Array).is_empty():
		var said:PackedStringArray=PackedStringArray()
		for m:Dictionary in out.measures:said.append(String(m.text))
		out.facts["measures"]=" ".join(said)
	return out

## People walking home from this town now, by status: {status: {people, days}}.
static func _on_the_road(civ_id:String,city_id:String)->Dictionary:
	var out:={}
	for transfer:Dictionary in MilitaryCampaign.occupation_transfers.data.get("transfers",[]):
		if String(transfer.get("region",""))!=city_id or String(transfer.get("source",civ_id))!=civ_id:continue
		var status:=String(transfer.get("status","citizen"))
		var row:Dictionary=out.get(status,{"people":0,"days":0})
		row.people=int(row.people)+int(transfer.get("people",0))
		var left:=maxf(0.0,float(transfer.get("distance",0.0))-float(transfer.get("traveled",0.0)))
		row.days=maxi(int(row.days),ceili(left/12.0))
		out[status]=row
	return out

## People from this town already living among us, by status.
static func _arrived(city_id:String)->Dictionary:
	var out:={}
	var total:=float(GameState.population_exact) if float(GameState.population_exact)>0 else float(GameState.population_total)
	for group:Dictionary in MilitaryCampaign.occupation_transfers.data.get("groups",[]):
		if String(group.get("origin_region",""))!=city_id:continue
		var status:=String(group.get("status","citizen"))
		out[status]=int(out.get(status,0))+roundi(float(group.get("share",0.0))*total)
	return out

## The chart's hover card for a town we hold: exact figures and no report age.
static func card_summary(report:Dictionary)->Dictionary:
	if report.is_empty():return {}
	var stats:Array[Dictionary]=[
		{"key":"population","label":"PEOPLE","value":_n(int(report.residents)),"detail":"live there now"},
		{"key":"garrison","label":"OUR GARRISON","value":_n(int(report.garrison)),"detail":("under "+P.first_name(String(report.commander if String(report.commander)!="" else report.general))) if String(report.commander)!="" or String(report.general)!="" else ("enough" if bool(report.enough) else "too few")},
		{"key":"resistance","label":"THEIR MOOD","value":_mood_short(float(report.resistance)),"detail":"to our rule"},
		{"key":"damage","label":"THE TOWN","value":_town_short(report),"detail":"rebuilding" if bool(report.rebuilding) else ""},
	]
	return {"stats":stats,"held":true,"level":5,"status":"Our garrison is there","heading":"Held"}

static func _mood_short(resistance:float)->String:
	return _level(resistance,["Calm","Grumbling","Resentful","Resisting","Near revolt"])

static func _town_short(report:Dictionary)->String:
	return _level(float(report.damage),["Whole","Some damage","Much broken","Mostly ruins"])
