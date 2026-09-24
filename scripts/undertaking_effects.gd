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
const DETERRENCE:={"stone_crown":.15,"returning_arch":.08,"assembly_dome":.12}
const TRAFFIC:={"safe_passage":.20,"harbor_lamp":.12,"joining_water":.12,"grand_terminus":.15,"sky_harbor":.20}
const FORECAST_DAYS:={"star_steps":120,"watching_tower":365}
const COVENANT_CAP:={"common_stores":6000.0,"covenant_vaults":24000.0}
const MEMORY_CAP:={"long_song":12,"chronicle_house":24}
const RESTORE_PER_YEAR:={"long_song":1,"chronicle_house":3}
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
		if effect.is_empty() or String(d.effect)==effect:
			var item:Dictionary=entry.duplicate()
			item.definition=d
			result.append(item)
	return result

static func deterrence(owner:String)->float:
	var total:=0.0
	for item:Dictionary in held_works(owner,"deterrence"):total+=float(DETERRENCE.get(String(item.record.id),.05))*float(item.record.condition)
	return minf(.25,total)

static func traffic_bonus(owner:String)->float:
	var total:=0.0
	for item:Dictionary in held_works(owner,"traffic"):total+=float(TRAFFIC.get(String(item.record.id),.05))*float(item.record.condition)
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
static func describe(id:String,condition:float=1.0)->String:
	var d:=Catalog.get_definition(id)
	match String(d.get("effect","")):
		"watching_sky":return "Warns of lean seasons and famine up to %d days ahead." % roundi(float(FORECAST_DAYS.get(id,120))*maxf(.25,condition))
		"covenant":return "Seals up to %d rations of real surplus against famine; released when people go hungry." % roundi(float(COVENANT_CAP.get(id,6000))*condition)
		"long_song":return "Keeps up to %d leaders' memories for successors and restores up to %d lost discoveries a year." % [int(MEMORY_CAP.get(id,12)),int(RESTORE_PER_YEAR.get(id,1))]
		"deterrence":return "Rivals' willingness to make war on you falls by up to %d%%." % roundi(float(DETERRENCE.get(id,.05))*condition*100)
		"traffic":return "Envoys, traders and refugees are %d%% more likely to route toward you." % roundi(float(TRAFFIC.get(id,.05))*condition*100)
	return String(d.get("effect_text",""))

# --- Daily effects (called from advance_all inside the owner's scope) ---------
static func advance_city(state:Node,city:Dictionary,day:int,days:int)->void:
	var U:=_system()
	for r:Dictionary in city.get("undertakings",[]):
		if not U.held(r):continue
		match String(Catalog.get_definition(String(r.id)).effect):
			"covenant":_covenant(state,r,days)
			"long_song":
				# Monthly review keeps the cost trivial.
				if posmod(day,30)<maxi(1,days):_long_song(state,r,day)

## The covenant moves food, never creates it: sealed rations leave stored food
## and return to it exactly. Sealing only draws on comfortable surplus.
static func _covenant(state:Node,r:Dictionary,days:int)->void:
	var cap:=float(COVENANT_CAP.get(String(r.id),6000.0))*float(r.condition)
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
	var cap:=int(MEMORY_CAP.get(id,12))
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
		if int(archive.restored)>=int(RESTORE_PER_YEAR.get(id,1)):break
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
		var reach:=roundi(float(FORECAST_DAYS.get(String(item.record.id),120))*maxf(.25,float(item.record.condition)))
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
