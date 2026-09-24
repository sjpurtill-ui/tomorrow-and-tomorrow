extends RefCounted
## Great Works facade for UI, dialogue, AI controllers and integration.
## Every function takes an optional owner/observer (default "player") and runs
## under that owner's scope, so AI civilizations use exactly the same rules.
const U=preload("res://scripts/undertaking_system.gd")
const Catalog=preload("res://scripts/undertaking_catalog.gd")
const Effects=preload("res://scripts/undertaking_effects.gd")
const Rewards=preload("res://scripts/undertaking_rewards.gd")
const Exchange=preload("res://scripts/civilization_exchange.gd")
const RIVALRY_PATH:="res://scripts/great_works_rivalry.gd"
const AUDIENCE_PATH:="res://scripts/audience_hall.gd"
const LESSER_ALLURE:=1.5
const RIVAL_ALLURE:=.5
const SPIKE_YEARS:=5.0
const MAX_ENSHRINED_ALLURE:=12.0

# --- Catalog and world view -----------------------------------------------------
## Rival progress as the observer has actually learned it (sightings, travelers'
## accounts, war news) from the rivalry module; never the world's true state.
static func _news_by_work(observer:String)->Dictionary:
	var result:={}
	for item:Dictionary in rival_news_for(observer):
		var id:=String(item.get("work_id",""))
		if id.is_empty():continue
		if not result.has(id):result[id]=[]
		result[id].append(item)
	return result

static func _claimant_known(observer:String,claim:Dictionary,news:Array)->bool:
	if String(claim.owner)==observer or String(claim.get("holder",""))==observer:return true
	for item:Dictionary in news:
		if String(item.owner)==String(claim.owner) and String(item.get("status","")) in ["functioning","ruined"]:return true
	return false

## All works: era, form, upgrade chain, lore, effect text, decree, claimed_by as
## the observer knows it ("" unclaimed, "unknown" if the claimant is unheard of).
## That a work is claimed is public: nobody else may begin it.
static func catalog(observer:String="player")->Array[Dictionary]:
	var claims:=U.claims()
	var news:=_news_by_work(observer)
	var result:Array[Dictionary]=[]
	for d:Dictionary in Catalog.all():
		var entry:=d.duplicate(true)
		entry.era_title=String(Catalog.ERA_TITLES.get(d.era,"")).to_upper()
		entry.upgrades_to=Catalog.upgrades_of(String(d.id))
		entry.effect_text=Effects.describe(String(d.id)) if not String(d.effect).is_empty() else String(d.effect_text)
		var claim:Dictionary=claims.get(d.id,{})
		entry.claimed_by="" if claim.is_empty() else (String(claim.owner) if _claimant_known(observer,claim,news.get(d.id,[])) else "unknown")
		result.append(entry)
	return result

## Contact test used by dialogue: same people, a returned journey, or a meeting.
static func knows(observer:String,owner:String)->bool:
	if observer==owner:return true
	var s:=U.owner_state(observer)
	if s!=null and s.society_exchange.get("connections",{}).has(owner):return true
	if observer!="player" and not WorldSimulation.actors.has(observer):return false
	return WorldSimulation.scoped(observer,func()->bool:
		for civ:Dictionary in WorldSimulation.world.civilizations:
			if Exchange.recipient(String(civ.id))!=owner:continue
			var relation:Dictionary=civ.get("player_relation",{})
			return int(relation.get("contact_level",0))>0 or int(relation.get("met_day",-1))>=0
		return false)

## Per work: {id,title,era,status,claimant,claimant_name,claim_day,known_sites,
## your_site}. `known_sites` come from rivalry news (dated, uncertain ranges);
## "in_progress" means you build it or have heard of someone building it.
static func world_status(observer:String="player")->Array[Dictionary]:
	var claims:=U.claims()
	var news:=_news_by_work(observer)
	var s:=U.owner_state(observer)
	var result:Array[Dictionary]=[]
	for d:Dictionary in Catalog.all():
		var id:=String(d.id)
		var entry:={"id":id,"title":String(d.title),"era":String(d.era),"status":"unclaimed","claimant":"","claimant_name":"","claim_day":-1,"known_sites":[],"your_site":{}}
		var items:Array=news.get(id,[])
		var claim:Dictionary=claims.get(id,{})
		if not claim.is_empty():
			entry.status="claimed"
			if _claimant_known(observer,claim,items):
				entry.claimant=String(claim.owner);entry.claimant_name=U.owner_name(String(claim.owner));entry.claim_day=int(claim.day);entry.name=String(claim.name)
			else:entry.claimant="unknown";entry.claimant_name="an unknown people"
		for item:Dictionary in items:
			if String(item.get("status","")) not in ["building","stalled"]:continue
			entry.known_sites.append({"owner":String(item.owner),"name":String(item.get("civ_name","")),"city_name":String(item.get("city_name","")),"progress_low":float(item.get("progress_low",0)),"progress_high":float(item.get("progress_high",1)),"as_of":int(item.day),"confidence":float(item.get("confidence",0)),"source":String(item.get("source","")),"text":String(item.get("text",""))})
			if entry.status=="unclaimed":entry.status="in_progress"
		if s!=null:
			for city:Dictionary in s.player_settlements:
				var r:=U.find(city,id)
				if r.is_empty():continue
				entry.your_site={"owner":observer,"city_id":String(city.id),"city_name":String(city.get("name","")),"status":String(r.status),"progress":U.fraction(r),"stage":U.stage_of(r)}
				if entry.status=="unclaimed" and r.status in ["building","stalled"]:entry.status="in_progress"
		result.append(entry)
	return result

## Full record of one site: stage, architect, events, decisions, condition,
## history layers, enshrined artifact ids and any pending decision/ceremony.
static func site(city_id:String,id:String,owner:String="player")->Dictionary:
	return WorldSimulation.scoped(owner,func()->Dictionary:
		var city:=WorldSimulation.settlements.settlement_record(city_id)
		var r:=U.find(city,id)
		if r.is_empty():return {}
		var result:=r.duplicate(true)
		result.merge({"city_id":city_id,"city_name":String(city.get("name","")),"title":String(Catalog.get_definition(id).title),"display_name":U.display_name(r),"stage":U.stage_of(r),"fraction":U.fraction(r),"total_work":U.total_work(r),"claimed":U.completed(r),"effect_text":Effects.describe(id,float(r.condition)),"reward_text":Rewards.description(id,float(r.condition))},true)
		if not r.get("decision",{}).is_empty():
			result.options=WorldSimulation.settlements.with_city_resources(city_id,func()->Array:return U.decision_options(WorldSimulation.state,r))
		return result)

# --- Decisions and ceremonies --------------------------------------------------
static func pending_decisions(owner:String="player")->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	WorldSimulation.scoped(owner,func()->void:
		for city:Dictionary in WorldSimulation.state.player_settlements:
			if not U.controlled(city):continue
			for r:Dictionary in city.get("undertakings",[]):
				var decision:Dictionary=r.get("decision",{})
				if decision.is_empty():continue
				var architect:Dictionary=r.get("architect",{})
				var options:Array=WorldSimulation.settlements.with_city_resources(String(city.id),func()->Array:return U.decision_options(WorldSimulation.state,r))
				result.append({"work_id":String(r.id),"city_id":String(city.id),"city_name":String(city.get("name","")),"title":U.display_name(r),"key":String(decision.key),"stage":String(decision.get("stage",U.stage_of(r))),"day":int(decision.day),"prompt":String(decision.get("prompt","")),"architect_id":String(architect.get("id","")),"architect_name":String(architect.get("name","")),"options":options}))
	return result

static func decide(city_id:String,work_id:String,option_id:String,owner:String="player")->Dictionary:
	return WorldSimulation.scoped(owner,func()->Dictionary:return U.decide(city_id,work_id,option_id))

static func pending_ceremonies(owner:String="player")->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	WorldSimulation.scoped(owner,func()->void:
		for city:Dictionary in WorldSimulation.state.player_settlements:
			for r:Dictionary in city.get("undertakings",[]):
				var ceremony:Dictionary=r.get("ceremony",{})
				if String(ceremony.get("status",""))!="pending":continue
				var attendees:Array=[]
				for attendee:Dictionary in ceremony.get("attendees",[]):attendees.append({"civ_id":String(attendee.civ_id),"name":String(attendee.name),"gift":(attendee.get("gift",{}) as Dictionary).duplicate()})
				result.append({"work_id":String(r.id),"city_id":String(city.id),"city_name":String(city.get("name","")),"title":U.display_name(r),"day":int(ceremony.day),"attendees":attendees,"name_suggestions":(ceremony.get("name_suggestions",[]) as Array).duplicate()}))
	return result

static func dedicate(city_id:String,work_id:String,name:String,owner:String="player")->Dictionary:
	return WorldSimulation.scoped(owner,func()->Dictionary:return U.dedicate(city_id,work_id,name))

## {day,work_id,city_id,kind,text,figure_ids}, newest first.
static func recent_events(limit:int=20,owner:String="player")->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var s:=U.owner_state(owner)
	if s==null:return result
	for city:Dictionary in s.player_settlements:
		for r:Dictionary in city.get("undertakings",[]):
			for event:Dictionary in r.get("events",[]):
				result.append({"day":int(event.day),"work_id":String(r.id),"city_id":String(city.id),"kind":String(event.get("kind","history")),"text":String(event.text),"figure_ids":(event.get("figure_ids",[]) as Array).duplicate()})
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.day)>int(b.day))
	if result.size()>limit:result.resize(maxi(0,limit))
	return result

## Observable rival progress (dated, uncertain), supplied by the rivalry module.
static func rival_news_for(observer:String)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if not ResourceLoader.exists(RIVALRY_PATH):return result
	var script:=load(RIVALRY_PATH) as GDScript
	if script==null:return result
	for method in ["rival_news_for","news_for"]:
		if _has_static(script,method):
			var items:Variant=script.call(method,observer)
			if items is Array:
				for item in items:
					if item is Dictionary:result.append(item)
			return result
	return result

static func _has_static(script:GDScript,method:String)->bool:
	for info:Dictionary in script.get_script_method_list():
		if String(info.get("name",""))==method:return true
	return false

## Optional Audience Hall hand-off; harmless when that branch is absent.
static func notify_audience(kind:String,payload:Dictionary)->void:
	if not ResourceLoader.exists(AUDIENCE_PATH):return
	var script:=load(AUDIENCE_PATH) as GDScript
	if script==null:return
	for info:Dictionary in script.get_script_method_list():
		if String(info.get("name",""))=="enqueue" and (info.get("args",[]) as Array).size()==1:
			var item:=payload.duplicate(true);item.kind="great_work_"+kind
			script.call("enqueue",item)
			return

# --- Allure, artifacts and effects ------------------------------------------------
## Great Works are the largest allure source. {value,breakdown:[{source,value,text}]}
static func allure_contribution(owner:String="player")->Dictionary:
	var s:=U.owner_state(owner)
	var result:={"value":0.0,"breakdown":[]}
	if s==null:return result
	var today:=int(s.elapsed_days)
	for entry:Dictionary in Effects.controlled_records(owner):
		var r:Dictionary=entry.record
		var d:=Catalog.get_definition(String(r.id))
		var name:=U.display_name(r)
		if bool(r.get("lesser",false)) and r.status=="functioning":
			_add(result,String(r.id),LESSER_ALLURE*float(r.condition),"%s, a lesser monument" % name)
			continue
		if r.status=="rival":
			_add(result,String(r.id),RIVAL_ALLURE,"%s, an unfinished rival that visitors come to see" % name)
			continue
		if not U.held(r):continue
		_add(result,String(r.id),float(d.allure)*float(r.condition)*float(r.get("allure_scale",1.0)),"%s (%s Great Work%s)" % [name,String(Catalog.ERA_TITLES.get(d.era,"")),", held by conquest" if bool(entry.captured) else ""])
		var ceremony:Dictionary=r.get("ceremony",{})
		if String(ceremony.get("status",""))=="dedicated":
			var fade:=clampf(1.0-float(today-int(ceremony.get("dedicated_day",today)))/(365.0*SPIKE_YEARS),0,1)
			if fade>0:_add(result,String(r.id),float(ceremony.get("allure",0))*fade,"The dedication of %s is still talked about" % name)
		# Enshrined objects belong to the builder's collection until looted.
		var builder:=U.owner_state(String(entry.owner))
		var collections:Dictionary=builder.society_exchange.get("collections",{}) if builder!=null else {}
		var shrine:=0.0
		for artifact_id in r.get("enshrined",[]):
			var item:Dictionary=collections.get(artifact_id,{})
			if item.get("kind","")!="artifact":continue
			shrine+=minf(4.0,log(1.0+preload("res://scripts/artifact_collection.gd").prestige(item)))
		if shrine>0:_add(result,String(r.id),minf(MAX_ENSHRINED_ALLURE,shrine),"Pilgrims visit the objects enshrined in %s" % name)
	return result
static func _add(result:Dictionary,source:String,value:float,text:String)->void:
	if value<=0:return
	result.value=float(result.value)+value
	result.breakdown.append({"source":source,"value":snappedf(value,.01),"text":text})

## Enshrine an artifact the owner actually holds in a held work with shrine room.
static func enshrine(city_id:String,work_id:String,artifact_id:String,owner:String="player")->Dictionary:
	return WorldSimulation.scoped(owner,func()->Dictionary:
		var city:=WorldSimulation.settlements.settlement_record(city_id)
		if city.is_empty() or not U.controlled(city):return {"error":"Choose a settlement you control."}
		var r:=U.find(city,work_id)
		if r.is_empty() or not U.held(r):return {"error":"Only a finished, functioning Great Work can house enshrined objects."}
		var slots:=int(Catalog.get_definition(work_id).get("shrine_slots",0))
		if slots<=0:return {"error":"This work has no place for enshrined objects."}
		var collections:Dictionary=WorldSimulation.state.society_exchange.get("collections",{})
		var item:Dictionary=collections.get(artifact_id,{})
		if item.get("kind","")!="artifact":return {"error":"Your people do not hold that artifact."}
		for other_city:Dictionary in WorldSimulation.state.player_settlements:
			for other:Dictionary in other_city.get("undertakings",[]):
				if artifact_id in other.get("enshrined",[]):return {"error":"That object is already enshrined."}
		if not r.has("enshrined"):r.enshrined=[]
		# Objects traded or looted away stop counting; their slots can be refilled.
		var held_now:Array=[]
		for existing in r.enshrined:
			if collections.has(existing):held_now.append(existing)
		r.enshrined=held_now
		if r.enshrined.size()>=mini(slots,8):return {"error":"Every place in this work is filled."}
		r.enshrined.append(artifact_id)
		item["enshrined_in"]=work_id
		var day:=int(WorldSimulation.state.elapsed_days)
		U.record_event(r,day,"%s was enshrined in %s" % [String(item.get("name","An artifact")),U.display_name(r)],"enshrine")
		WorldSimulation.state.settlement_network_revision+=1
		return {"ok":true,"message":"%s is enshrined in %s." % [String(item.get("name","The artifact")),U.display_name(r)]})

static func forecast(owner:String="player")->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for item in Effects.forecast(owner):result.append(item)
	return result

static func deterrence(owner:String)->float:return Effects.deterrence(owner)
static func traffic_bonus(owner:String)->float:return Effects.traffic_bonus(owner)
static func decree_options(owner:String="player")->Array:return Effects.decree_options(owner)
static func famine_reserve(owner:String="player")->float:return Effects.famine_reserve(owner)

# --- Pursuit helpers (AI and player alike) ----------------------------------------
## Works the owner could begin now: [{city_id,city_name,work_id,title,era,upgrade}].
static func candidates(owner:String="player")->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	WorldSimulation.scoped(owner,func()->void:
		for city:Dictionary in WorldSimulation.state.player_settlements:
			if not U.controlled(city):continue
			var busy:=false
			for r:Dictionary in city.get("undertakings",[]):
				if r.status in ["building","stalled"]:busy=true
			if busy:continue
			for d:Dictionary in WorldSimulation.settlements.with_city_resources(String(city.id),func()->Array:return U.possibilities(city)):
				result.append({"city_id":String(city.id),"city_name":String(city.get("name","")),"work_id":String(d.id),"title":String(d.title),"era":String(d.era),"upgrade":not String(d.upgrade_from).is_empty()}))
	return result

static func start(city_id:String,work_id:String,owner:String="player",site_height:Callable=Callable(),site_land:Callable=Callable())->Dictionary:
	return WorldSimulation.scoped(owner,func()->Dictionary:return U.start(city_id,work_id,site_height,site_land))

static func repurpose(city_id:String,work_id:String,owner:String="player")->Dictionary:
	return WorldSimulation.scoped(owner,func()->Dictionary:return U.repurpose(city_id,work_id))

static func quarry(city_id:String,work_id:String,owner:String="player")->Dictionary:
	return WorldSimulation.scoped(owner,func()->Dictionary:return U.quarry(city_id,work_id))

static func claims()->Dictionary:return U.claims()
