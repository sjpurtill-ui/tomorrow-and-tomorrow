extends RefCounted
## Transformative Great Work effects. Every effect requires a held (claimed,
## functioning, not lesser) work in a settlement its owner still controls, and
## scales with condition. Everything is bounded and explained in text.
##
## Implemented here (player-side systems, all owners alike):
##   watching_sky - forecast(): lean-season and famine warnings ahead of time
##   covenant     - seals a famine reserve from real surplus, releases it in shortage
##   long_song    - archives leaders' memories and adopted knowledge; restores both
## Exposed as data for AI/controller wiring (G2 / integration):
##   deterrence(owner) - 0..0.25 reduction to rivals' war propensity toward owner
##   traffic_bonus(owner) - 0..0.40 extra envoy/trader/refugee routing weight
const Catalog=preload("res://scripts/undertaking_catalog.gd")
const FoodScript=preload("res://scripts/food_system.gd")
## Legacy founding works keep fixed magnitudes; conceived works scale by their
## stored strength (ambition × outcome, 0.25..3.4), always bounded.
const DETERRENCE:={"stone_crown":.15}
const TRAFFIC:={"safe_passage":.20}
const FORECAST_DAYS:={"star_steps":120}
const COVENANT_CAP:={"common_stores":6000.0}
const MEMORY_CAP:={"long_song":12}
const RESTORE_PER_YEAR:={"long_song":1}
const CIVIC_DAILY:=.00004
const CIVIC_CEILING:=.85

## Effect family of a record: stored for conceived works, catalog for legacy.
static func family(r:Dictionary)->String:
	var effect:Variant=r.get("effect")
	if effect is Dictionary and not (effect as Dictionary).is_empty():return String(effect.get("family",""))
	return String(Catalog.get_definition(String(r.id)).get("effect",""))
static func strength(r:Dictionary)->float:
	var effect:Variant=r.get("effect")
	if effect is Dictionary and (effect as Dictionary).has("strength"):return clampf(float(effect.strength),0,4)
	return 1.0
static func deterrence_of(r:Dictionary)->float:return float(DETERRENCE[String(r.id)]) if DETERRENCE.has(String(r.id)) else minf(.25,.10*strength(r))
static func traffic_of(r:Dictionary)->float:return float(TRAFFIC[String(r.id)]) if TRAFFIC.has(String(r.id)) else minf(.40,.12*strength(r))
static func forecast_days(r:Dictionary)->int:return int(FORECAST_DAYS[String(r.id)]) if FORECAST_DAYS.has(String(r.id)) else mini(365,roundi(120*strength(r)))
static func covenant_cap(r:Dictionary)->float:return float(COVENANT_CAP[String(r.id)]) if COVENANT_CAP.has(String(r.id)) else minf(24000.0,6000.0*strength(r))
static func memory_cap(r:Dictionary)->int:return int(MEMORY_CAP[String(r.id)]) if MEMORY_CAP.has(String(r.id)) else (24 if strength(r)>=1.5 else 12)
static func restore_rate(r:Dictionary)->int:return int(RESTORE_PER_YEAR[String(r.id)]) if RESTORE_PER_YEAR.has(String(r.id)) else (3 if strength(r)>=1.5 else 1)
const MAX_ARCHIVED_DISCOVERIES:=4096

static func _system()->GDScript:return load("res://scripts/undertaking_system.gd")

## Every work in settlements `owner` controls, including captured ones:
## [{record, city:{id,name}, owner (builder), captured}]. Control follows the
## existing occupation through the rivalry module when it is present.
static func controlled_records(owner:String)->Array:
	var U:=_system()
	var result:Array=[]
	var rivalry:GDScript=U.rivalry_script()
	if rivalry!=null:
		for entry:Dictionary in rivalry.call("held_works",owner):
			result.append({"record":entry.record,"city":{"id":String(entry.city_id),"name":String(entry.city_name)},"owner":String(entry.owner),"captured":bool(entry.captured)})
		return result
	var state:Node=U.owner_state(owner)
	if state==null:return result
	for city:Dictionary in state.player_settlements:
		if String(city.get("occupied_by","")) not in ["","player"]:continue
		for r:Dictionary in city.get("undertakings",[]):result.append({"record":r,"city":{"id":String(city.id),"name":String(city.get("name",""))},"owner":owner,"captured":false})
	return result

## Held (claimed, functioning, not lesser) works an owner controls, optionally
## of one effect family. Captured works serve their occupier.
static func held_works(owner:String,effect:String="")->Array:
	var U:=_system()
	var result:Array=[]
	for entry:Dictionary in controlled_records(owner):
		var r:Dictionary=entry.record
		if not U.held(r):continue
		var d:=Catalog.get_definition(String(r.id))
		if effect.is_empty() or family(r)==effect:
			var item:Dictionary=entry.duplicate()
			item.definition=d
			result.append(item)
	return result

static func deterrence(owner:String)->float:
	var total:=0.0
	for item:Dictionary in held_works(owner,"deterrence"):total+=deterrence_of(item.record)*float(item.record.condition)
	return minf(.25,total)

static func traffic_bonus(owner:String)->float:
	var total:=0.0
	for item:Dictionary in held_works(owner,"traffic"):total+=traffic_of(item.record)*float(item.record.condition)
	return minf(.40,total)

## One unique decree per held work (text only; integration may add dialogue).
static func decree_options(owner:String)->Array:
	var result:Array=[]
	for item:Dictionary in held_works(owner):
		var decree:Dictionary=item.definition.decree
		if decree.is_empty():continue
		result.append({"work_id":String(item.record.id),"city_id":String(item.city.id),"id":String(decree.id),"label":String(decree.label),"text":String(decree.text)})
	return result

## Human-readable summary of what a work does beyond its catalog bonus.
static func describe(id:String,condition:float=1.0,record:Dictionary={})->String:
	var d:=Catalog.get_definition(id)
	var r:Dictionary=record if not record.is_empty() else {"id":id}
	if record.is_empty() and bool(d.get("concept",false)):
		# Before completion: describe a successful outcome at the design's ambition.
		r={"id":id,"effect":{"family":String(d.effect),"strength":load("res://scripts/wonder_concept.gd").pay(String(d.ambition),"success")}}
	match family(r):
		"watching_sky":return "Warns of lean seasons and famine up to %d days ahead." % roundi(float(forecast_days(r))*maxf(.25,condition))
		"covenant":return "Seals up to %d rations of real surplus against famine; released when people go hungry." % roundi(covenant_cap(r)*condition)
		"long_song":return "Keeps up to %d leaders' memories for successors and restores up to %d lost discoveries a year." % [memory_cap(r),restore_rate(r)]
		"deterrence":return "Rivals' willingness to make war on you falls by up to %d%%." % roundi(deterrence_of(r)*condition*100)
		"traffic":return "Envoys, traders and refugees are %d%% more likely to route toward you." % roundi(traffic_of(r)*condition*100)
		"civic":return "Steadies cohesion and legitimacy while it stands."
	return String(d.get("effect_text",""))

# --- Daily effects (called from advance_all inside the owner's scope) ---------
static func advance_city(state:Node,city:Dictionary,day:int,days:int)->void:
	var U:=_system()
	for r:Dictionary in city.get("undertakings",[]):
		if not U.held(r):continue
		match family(r):
			"covenant":_covenant(state,r,days)
			"civic":_civic(state,r,days)
			"long_song":
				# Monthly review keeps the cost trivial.
				if posmod(day,30)<maxi(1,days):_long_song(state,r,day)

## The covenant moves food, never creates it: sealed rations leave stored food
## and return to it exactly. Sealing only draws on comfortable surplus.
static func _covenant(state:Node,r:Dictionary,days:int)->void:
	var cap:=covenant_cap(r)*float(r.condition)
	var reserve:=float(r.get("covenant",0.0))
	var stocks:Dictionary=state.food_stocks
	var stored:=float(stocks.get(FoodScript.STORED,0.0))
	var consumption:=maxf(.01,float(state.simulation_metrics.get("food_consumption",state.population_exact)))
	var total:=0.0
	for amount in stocks.values():total+=float(amount)
	var intake:=float(state.simulation_metrics.get("food_intake_ratio",1.0))
	var moved:=0.0
	if intake<.95 or total/consumption<10.0:
		moved=-minf(reserve,consumption*.5*days)
	elif intake>=.99 and total/consumption>45.0 and reserve<cap:
		moved=minf(minf(stored*.004*days,cap-reserve),maxf(0,total-consumption*45.0))
	if absf(moved)<=.0001:return
	stocks[FoodScript.STORED]=stored-moved
	r.covenant=reserve+moved
	state.resource_stockpiles["Food"]=total-moved
	if moved<0 and (reserve+moved)<=.0001:
		preload("res://scripts/undertaking_system.gd").record_event(r,int(state.elapsed_days),"The Covenant's last sealed rations were given out","covenant")

## A standing work of shared purpose slowly steadies cohesion and legitimacy,
## never above a ceiling and never faster than CIVIC_DAILY × strength per day.
static func _civic(state:Node,r:Dictionary,days:int)->void:
	var m:Dictionary=state.simulation_metrics
	var step:=CIVIC_DAILY*strength(r)*float(r.condition)*days
	for key in ["cohesion","legitimacy"]:
		var value:=float(m.get(key,.5))
		if value<CIVIC_CEILING:m[key]=minf(CIVIC_CEILING,value+step)

static func famine_reserve(owner:String)->float:
	var total:=0.0
	for item:Dictionary in held_works(owner,"covenant"):total+=float(item.record.get("covenant",0.0))
	return total

## The Long Song remembers what leaders learned and what the people knew.
static func _long_song(state:Node,r:Dictionary,day:int)->void:
	var id:=String(r.id)
	if not r.has("archive"):r.archive={"memories":[],"discoveries":[],"restored_year":-1,"restored":0}
	var archive:Dictionary=r.archive
	var memories:Array=archive.memories
	var cap:=memory_cap(r)
	var government=WorldSimulation.government
	var holders:Array=[]
	for office_key in state.leadership_positions:
		var pid:=int((state.leadership_positions[office_key] as Dictionary).get("person_id",0))
		if pid>0 and pid not in holders:holders.append(pid)
	holders.sort()
	# Archive consequential memories.
	for pid:int in holders:
		var person:Dictionary=government.person_snapshot(pid) if government!=null and government.has_method("person_snapshot") else {}
		for memory in person.get("memories",[]):
			if not memory is Dictionary or bool(memory.get("inherited",false)) or float(memory.get("importance",0))<.7:continue
			var summary:=String(memory.get("summary",""))
			if summary.is_empty() or _has_summary(memories,summary):continue
			memories.append({"summary":summary.substr(0,320),"kind":String(memory.get("kind","civic")).substr(0,48),"importance":float(memory.get("importance",.7)),"day":int(memory.get("created_day",day))})
	memories.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.importance)>float(b.importance) or (float(a.importance)==float(b.importance) and int(a.day)<int(b.day)))
	if memories.size()>cap:memories.resize(cap)
	# Successors inherit what their predecessors learned (two memories a month each).
	if government!=null and government.has_method("record_person_memory"):
		for pid:int in holders:
			var person:Dictionary=government.person_snapshot(pid)
			var known:Array=person.get("memories",[])
			var taught:=0
			for memory:Dictionary in memories:
				if taught>=2:break
				if _has_summary(known,String(memory.summary)):continue
				government.record_person_memory(pid,String(memory.summary),"inherited",float(memory.importance)*.8,{"inherited":true})
				taught+=1
	# Adopted knowledge: archive it, and restore losses at a bounded yearly rate.
	var sung:Array=archive.discoveries
	for discovery in state.known_discoveries:
		if sung.size()>=MAX_ARCHIVED_DISCOVERIES:break
		if String(discovery) not in sung:sung.append(String(discovery))
	var year:=day/365
	if int(archive.restored_year)!=year:archive.restored_year=year;archive.restored=0
	for discovery in sung:
		if int(archive.restored)>=restore_rate(r):break
		if String(discovery) in state.known_discoveries:continue
		state.known_discoveries.append(String(discovery))
		archive.restored=int(archive.restored)+1
		preload("res://scripts/undertaking_system.gd").record_event(r,day,"The Long Song restored forgotten knowledge: %s" % String(discovery).replace("_"," "),"memory")

static func _has_summary(list:Array,summary:String)->bool:
	for item in list:
		if item is Dictionary and String(item.get("summary",""))==summary:return true
	return false

static func valid_archive(archive:Variant)->bool:
	if not archive is Dictionary:return false
	if archive.is_empty():return true
	if not archive.get("memories") is Array or archive.memories.size()>24 or not archive.get("discoveries") is Array or archive.discoveries.size()>MAX_ARCHIVED_DISCOVERIES:return false
	for memory in archive.memories:
		if not memory is Dictionary or not memory.get("summary") is String or not memory.get("day") is int:return false
		if not (memory.get("importance") is float or memory.get("importance") is int):return false
	for discovery in archive.discoveries:
		if not discovery is String:return false
	return archive.get("restored_year",0) is int and archive.get("restored",0) is int

# --- Watching Sky -------------------------------------------------------------
## Season and famine warnings for an owner who holds a Watching Sky work.
## [{kind:"lean_season"|"famine", in_days, start_day, end_day, severity, text}]
static func forecast(owner:String="player")->Array:
	var works:=held_works(owner,"watching_sky")
	if works.is_empty():return []
	var horizon:=0
	var source:=""
	for item:Dictionary in works:
		var reach:=roundi(float(forecast_days(item.record))*maxf(.25,float(item.record.condition)))
		if reach>horizon:horizon=reach;source=String(item.definition.title)
	return WorldSimulation.scoped(owner,func()->Array:
		var result:Array=[]
		var state=WorldSimulation.state
		var today:=int(state.elapsed_days)
		var food=WorldSimulation.food
		if food==null or not food.has_method("_weather_yield_factor"):return result
		var profile:Dictionary=food._environment_mix()
		var span_start:=-1;var worst:=1.0
		for offset in range(0,horizon+7,7):
			var factor:float=food._weather_yield_factor(profile,float(today+offset)) if offset<=horizon else 1.0
			if factor<.92:
				if span_start<0:span_start=offset
				worst=minf(worst,factor)
			elif span_start>=0:
				result.append({"kind":"lean_season","in_days":span_start,"start_day":today+span_start,"end_day":today+offset,"severity":snappedf(1.0-worst,.01),"text":"%s foresees a lean season in about %d days, lasting some %d days: harvests near %d%% of normal." % [source,span_start,offset-span_start,roundi(worst*100)]})
				span_start=-1;worst=1.0
			if result.size()>=6:break
		var outlook:Variant=state.simulation_metrics.get("food_forecast_90",{})
		if outlook is Dictionary and int(outlook.get("first_shortage_day",-1))>0:
			var shortage:=int(outlook.first_shortage_day)
			result.push_front({"kind":"famine","in_days":shortage,"start_day":today+shortage,"end_day":today+shortage,"severity":1.0,"text":"%s warns that stores run short in about %d days unless harvests or rations change." % [source,shortage]})
		return result)
