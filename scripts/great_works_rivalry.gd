extends RefCounted
## Great Works between rival owners: what each owner has actually observed of
## other owners' works, sabotage with real costs and risks, and what war does
## to works (capture follows the existing occupation, siege damage, looting of
## enshrined artifacts, restoration, and lasting grievances).
##
## Owner ids are global: "player" is the human civilization and every other id
## is a WorldSimulation actor. Inside an owner's scope the same people appear as
## "player" (itself) and "human" (the human civilization) in views; `view_id`
## and `global_owner` convert between the two.
##
## No bonus, labor, material or knowledge is created here. Every action pays
## from real stores and is reached through the validated civilization orders.
const Catalog=preload("res://scripts/undertaking_catalog.gd")
const Exchange=preload("res://scripts/society_exchange.gd")
const Artifacts=preload("res://scripts/artifact_collection.gd")
const PERSONALITY=preload("res://scripts/leader_personality.gd")
const U=preload("res://scripts/undertaking_system.gd")
const Effects=preload("res://scripts/undertaking_effects.gd")

const SIGHT_QUALITY:=.35         # a large construction site is visible at all
const IDENTIFY_QUALITY:=.55      # which named work it is can be judged
const NEWS_LIMIT:=40
const NEWS_MAX_AGE:=365*12       # older sightings are history, not news
const RACE_MAX_AGE:=365          # rulers only race against recent evidence
const SABOTAGE_AGENTS:=3
const SABOTAGE_COOLDOWN:=180
const SABOTAGE_SETBACK:=.04      # share of a work's total effort undone
const SIEGE_DAILY_WEAR:=.0015
const SIEGE_FLOOR:=.2            # sieges scar; only neglect finishes a ruin
const EVENT_LIMIT:=12
const GRIEVANCE_LIMIT:=12
const LOOT_LIMIT:=64
const FORM_WORDS:={"ring":"a great ring of standing stones","hall":"a great hall","basin":"a great walled basin","terrace":"great stepped terraces","kilns":"a great court of kilns","granary":"a great granary","orchard":"a great planted orchard","mound":"a great earthen mound"}

# ---------------------------------------------------------------- identities

static func global_owner(frame_id:String,scope_id:String="")->String:
	if scope_id.is_empty():scope_id=WorldSimulation.actor_id
	if frame_id=="player":return scope_id
	if frame_id=="human":return "player"
	return frame_id

static func view_id(owner:String,scope_id:String="")->String:
	## How `owner` is named inside `scope_id`'s own views.
	if scope_id.is_empty():scope_id=WorldSimulation.actor_id
	if owner==scope_id:return "player"
	return "human" if owner=="player" else owner

static func owners()->Array[String]:
	var ids:Array[String]=["player"]
	for id:String in WorldSimulation.actors:ids.append(id)
	ids.sort()
	return ids

static func owner_system(owner:String,system_name:String)->Node:
	if owner=="player":return WorldSimulation.get_tree().root.get_node_or_null(system_name) if WorldSimulation.is_inside_tree() else null
	return WorldSimulation.actors.get(owner,{}).get("systems",{}).get(system_name)

static func owner_state(owner:String)->Node:
	return Exchange.owner_state(owner)

static func definition(id:String)->Dictionary:
	return Catalog.get_definition(id)

static func fraction(record:Dictionary)->float:
	if String(record.get("status",""))=="functioning":return 1.0
	return U.fraction(record)

static func cities(owner:String)->Array:
	var state:=owner_state(owner)
	return state.player_settlements if state!=null else []

static func city_record(owner:String,city_id:String)->Dictionary:
	for city:Dictionary in cities(owner):
		if String(city.get("id",""))==city_id:return city
	return {}

static func work_record(owner:String,city_id:String,work_id:String)->Dictionary:
	for r:Dictionary in city_record(owner,city_id).get("undertakings",[]):
		if String(r.get("id",""))==work_id:return r
	return {}

static func holder(owner:String,city:Dictionary)->String:
	## The owner that actually controls a work: the existing occupation decides.
	var occupier:=String(city.get("occupied_by",""))
	if occupier.is_empty() or occupier=="player":return owner
	return global_owner(occupier,owner)

static func held_works(owner:String)->Array[Dictionary]:
	## Works this owner controls, including works in cities it occupies.
	var result:Array[Dictionary]=[]
	for source:String in owners():
		for city:Dictionary in cities(source):
			if holder(source,city)!=owner:continue
			for r:Dictionary in city.get("undertakings",[]):
				result.append({"owner":source,"holder":owner,"city_id":String(city.id),"city_name":String(city.get("name","")),"record":r,"captured":source!=owner})
	return result

static func relation(scope:String,other:String)->Dictionary:
	## `scope`'s own relation record for `other` (empty without a view).
	var world:=owner_system(scope,"CivilizationSystem")
	if world==null:return {}
	var name:=view_id(other,scope)
	for civ:Dictionary in world.civilizations:
		if String(civ.get("id",""))==name:return civ.get("player_relation",{})
	return {}

static func civ_name(scope:String,other:String)->String:
	var world:=owner_system(scope,"CivilizationSystem")
	if world!=null:
		var name:=view_id(other,scope)
		for civ:Dictionary in world.civilizations:
			if String(civ.get("id",""))==name and int(civ.get("player_relation",{}).get("contact_level",0))>=2:return String(civ.get("name","another people"))
	return "an unidentified people"

static func in_contact(scope:String,other:String)->bool:
	if scope==other:return true
	return int(relation(scope,other).get("contact_level",0))>=2

static func _rivalry(record:Dictionary)->Dictionary:
	if not record.get("rivalry") is Dictionary:record["rivalry"]={}
	var rv:Dictionary=record.rivalry
	for key in ["events","grievances","looted"]:
		if not rv.get(key) is Array:rv[key]=[]
	return rv

static func _push(list:Array,entry:Dictionary,limit:int)->void:
	list.push_front(entry)
	if list.size()>limit:list.resize(limit)

static func personality(owner:String)->Dictionary:
	## The sovereign persona each ruled owner already uses for strategy and
	## dialogue. The human's choices are its own: a neutral stand-in only.
	var state:=owner_state(owner)
	if owner=="player" or state==null:return {"openness":.5,"discipline":.5,"empathy":.5,"assertiveness":.5,"risk_tolerance":.5}
	return PERSONALITY.foreign(int(state.world_seed),owner)

static func _title(record:Dictionary)->String:
	return String(record.get("custom_name",definition(String(record.get("id",""))).get("title","great work")))

# ---------------------------------------------------------------- observation

static func sight(system:Object,actual:Dictionary,quality:float,day:int,key:String)->Array:
	## Called when a real observer captures a city (scouts, envoys, lookouts,
	## air reconnaissance, battle reports). Frozen at the observation day.
	if quality<SIGHT_QUALITY or actual.is_empty():return []
	var frame:=String(actual.get("civ_id",""))
	var owner:=global_owner(frame)
	var local:=String(actual.get("city_id",""))
	if frame!="player" and system!=null:
		var location:Dictionary=system._region_location(local)
		if location.is_empty():return []
		local=String(system.civilizations[int(location.owner_index)].strategic_regions[int(location.region_index)].get("local_city_id",""))
	if local.is_empty() or owner_state(owner)==null:return []
	var result:Array=[]
	for r:Dictionary in city_record(owner,local).get("undertakings",[]):
		var d:=definition(String(r.get("id","")))
		if d.is_empty():continue
		var rng:=RandomNumberGenerator.new();rng.seed=hash(key+":"+String(r.id))^day
		var error:=lerpf(.30,.06,clampf((quality-SIGHT_QUALITY)/(.9-SIGHT_QUALITY),0,1))
		var center:=fraction(r)+rng.randf_range(-.5,.5)*error
		var sighting:={"owner":owner,"local_city_id":local,"work_id":String(r.id) if quality>=IDENTIFY_QUALITY else "","form":String(d.get("form","")),"status":String(r.get("status","")),
			"progress_low":snappedf(clampf(center-error,0,1),.05),"progress_high":snappedf(clampf(center+error,0,1),.05),"quality":snappedf(quality,.01),"observed_day":day}
		if float(sighting.progress_high)<float(sighting.progress_low):sighting.progress_high=sighting.progress_low
		if sighting.status=="functioning":
			var c:=float(r.get("condition",1))+rng.randf_range(-.5,.5)*error
			sighting["condition_low"]=snappedf(clampf(c-error,0,1),.05);sighting["condition_high"]=snappedf(clampf(c+error,0,1),.05)
		if quality>=.6 and sighting.status=="building":sighting["pace"]="hurried" if String(r.get("policy",""))=="press" else "measured"
		result.append(sighting)
	return result

static func valid_sightings(value:Variant)->bool:
	if not value is Array or value.size()>32:return false
	for s:Variant in value:
		if not s is Dictionary or not s.has_all(["owner","local_city_id","work_id","form","status","progress_low","progress_high","quality","observed_day"]):return false
		for key:String in ["owner","local_city_id","work_id","form","status"]:
			if not s[key] is String or s[key].length()>120:return false
		for key:String in ["progress_low","progress_high","quality"]:
			if not Exchange.number(s[key]) or float(s[key])<0 or float(s[key])>1:return false
		if not Exchange.number(s.observed_day) or float(s.observed_day)<0 or float(s.progress_high)<float(s.progress_low):return false
	return true

static func _intel_book(observer:String)->Dictionary:
	var world:=owner_system(observer,"CivilizationSystem")
	if world==null or world.get("city_intelligence")==null:return {}
	return world.city_intelligence.records.get("player",{})

static func _today(observer:String)->int:
	var state:=owner_state(observer)
	return int(state.elapsed_days) if state!=null else int(WorldSimulation.state.elapsed_days)

static func rival_news_for(observer:String)->Array[Dictionary]:
	## Dated, uncertain items this owner learned through real channels only:
	## returned scout/envoy/lookout/air/battle city reports, travelers' accounts
	## recorded on physical encounters, and war events among peoples in contact.
	var today:=_today(observer)
	var best:Dictionary={}
	var items:Array[Dictionary]=[]
	var book:=_intel_book(observer)
	for city_key:String in book:
		var report:Dictionary=book[city_key]
		for s:Dictionary in report.get("works",[]):
			var owner:=String(s.owner)
			if owner==observer or today-int(s.observed_day)>NEWS_MAX_AGE:continue
			var item:=_sighting_item(observer,report,s,today)
			var key:=owner+"/"+String(s.local_city_id)+"/"+(String(s.work_id) if not String(s.work_id).is_empty() else String(s.form))
			if not best.has(key) or int(best[key].day)<int(item.day):best[key]=item
	for owner:String in owners():
		if owner==observer:continue
		for city:Dictionary in cities(owner):
			for r:Dictionary in city.get("undertakings",[]):
				var account:Dictionary=r.get("heard_by",{}).get(observer,{})
				if not account.is_empty():
					var key:=owner+"/"+String(city.id)+"/"+String(r.id)
					if not best.has(key) or int(best[key].day)<int(account.day):
						best[key]=_account_item(observer,owner,city,r,account,today)
				for event:Dictionary in r.get("rivalry",{}).get("events",[]):
					if today-int(event.day)>NEWS_MAX_AGE:continue
					var by:=String(event.get("by",""))
					if observer!=owner and observer!=by and not in_contact(observer,owner) and (by.is_empty() or not in_contact(observer,by)):continue
					if String(event.kind)=="sabotage" and observer!=owner and not bool(event.get("caught",false)):continue
					items.append(_event_item(observer,owner,city,r,event,today))
	for item:Dictionary in best.values():items.append(item)
	items.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.day)>int(b.day))
	if items.size()>NEWS_LIMIT:items.resize(NEWS_LIMIT)
	return items

static func _describe_work(s:Dictionary)->String:
	if not String(s.work_id).is_empty():return String(definition(String(s.work_id)).get("title","a great work"))
	return String(FORM_WORDS.get(String(s.form),"a great work"))

static func _sighting_item(observer:String,report:Dictionary,s:Dictionary,today:int)->Dictionary:
	var owner:=String(s.owner)
	var age:=today-int(s.observed_day)
	var who:=civ_name(observer,owner)
	var place:=String(report.get("name","an unnamed settlement"))
	var what:=_describe_work(s)
	var low:=roundi(float(s.progress_low)*100);var high:=roundi(float(s.progress_high)*100)
	var state_text:String={"building":"raising %s — perhaps %d–%d%% complete" % [what,low,high],"stalled":"%s, apparently idle — perhaps %d–%d%% complete" % [what,low,high],"functioning":"%s standing complete and in use" % what,"abandoned":"the unfinished remains of %s" % what,"ruined":"%s fallen into ruin" % what,"rival":"%s left unfinished as a rival monument" % what,"quarried":"the quarried footings of %s" % what}.get(String(s.status),what)
	if s.has("pace"):state_text+="; crews worked at a %s pace" % String(s.pace)
	var source:=String(report.get("source","a report"))
	var text:="%s, day %d (%s): %s at %s — %s. Confidence %s." % [source.left(1).to_upper()+source.substr(1),int(s.observed_day),"today" if age<=0 else "%d days old" % age,who.left(1).to_upper()+who.substr(1),place,state_text,_confidence_word(float(s.quality))]
	return {"kind":"sighting","day":int(s.observed_day),"reported_day":int(report.get("reported_day",s.observed_day)),"age_days":age,"stale":age>180,"owner":owner,"civ_name":who,"city_id":String(report.get("city_id","")),"local_city_id":String(s.local_city_id),"city_name":place,"work_id":String(s.work_id),"title":what,"form":String(s.form),"status":String(s.status),"progress_low":float(s.progress_low),"progress_high":float(s.progress_high),"confidence":float(s.quality),"source":String(report.get("source","")),"text":text}

static func _account_item(observer:String,owner:String,city:Dictionary,r:Dictionary,account:Dictionary,today:int)->Dictionary:
	var who:=civ_name(observer,owner)
	var age:=today-int(account.day)
	var title:=_title(r)
	return {"kind":"account","day":int(account.day),"reported_day":int(account.day),"age_days":age,"stale":age>365*5,"owner":owner,"civ_name":who,"city_id":"","local_city_id":String(city.id),"city_name":String(city.get("name","")) if in_contact(observer,owner) else "an undisclosed city","work_id":String(r.id),"title":title,"form":String(definition(String(r.id)).get("form","")),"status":"functioning","progress_low":1.0,"progress_high":1.0,"confidence":.5,"source":"travelers' accounts",
		"text":"Travelers from %s spoke of %s, standing and in use%s. Heard on day %d (%d days ago); accounts are secondhand." % [who,title," though raised at great human cost" if int(account.get("strain",0))>=180 else "",int(account.day),age]}

static func _event_item(observer:String,owner:String,city:Dictionary,r:Dictionary,event:Dictionary,today:int)->Dictionary:
	var by:=String(event.get("by",""))
	var title:=_title(r)
	var victim:=civ_name(observer,owner) if observer!=owner else "our people"
	var actor:=civ_name(observer,by) if observer!=by else "our forces"
	var place:=String(city.get("name","a city"))
	var text:=""
	match String(event.kind):
		"captured":text="%s took %s at %s from %s." % [actor.capitalize(),title,place,victim]
		"recovered":text="%s regained control of %s at %s." % [victim.capitalize(),title,place]
		"looted":text="%s carried off %s from %s at %s." % [actor.capitalize(),_treasures(int(event.get("count",0)),"enshrined treasure"),title,place]
		"returned":text="%s returned %s taken from %s." % [actor.capitalize(),_treasures(int(event.get("count",0)),"treasure"),title]
		"siege_damage":text="Siege works scarred %s at %s." % [title,place]
		"restored":text="Restoration work repaired %s at %s." % [title,place]
		"sabotage":text=("Agents of %s were caught sabotaging %s at %s." % [actor,title,place]) if bool(event.get("caught",false)) else "A mysterious collapse set back %s at %s." % [title,place]
	return {"kind":"war" if String(event.kind)!="sabotage" else "sabotage","event":String(event.kind),"day":int(event.day),"reported_day":int(event.day),"age_days":today-int(event.day),"stale":false,"owner":owner,"by":by,"civ_name":civ_name(observer,owner),"city_id":"","local_city_id":String(city.id),"city_name":place,"work_id":String(r.id),"title":title,"status":String(r.get("status","")),"confidence":1.0 if observer in [owner,by] else .7,"source":"direct experience" if observer in [owner,by] else "word through contacts","text":text}

static func _treasures(count:int,noun:String)->String:
	return "%d %s%s" % [count,noun,"" if count==1 else "s"]

static func _confidence_word(q:float)->String:
	return "high" if q>=.75 else ("fair" if q>=.55 else "low")

# ---------------------------------------------------------------- races

static func race_for(observer:String,work_id:String,own_fraction:float,news:Array=[])->Dictionary:
	## The best recent evidence of a rival pursuing the same world-unique work.
	if news.is_empty():news=rival_news_for(observer)
	var result:Dictionary={}
	for item:Dictionary in news:
		if String(item.get("work_id",""))!=work_id or String(item.owner)==observer:continue
		if String(item.kind) not in ["sighting","account"]:continue
		if String(item.status)=="functioning":
			return {"owner":item.owner,"claimed":true,"rival_ahead":true,"rival_mid":1.0,"day":int(item.day),"local_city_id":String(item.local_city_id),"allied":_allied(observer,String(item.owner))}
		if String(item.status) not in ["building","stalled"] or int(item.age_days)>RACE_MAX_AGE:continue
		# Assume the rival kept working since the report; the estimate stays uncertain.
		var mid:=(float(item.progress_low)+float(item.progress_high))*.5
		if result.is_empty() or mid>float(result.rival_mid):
			result={"owner":String(item.owner),"claimed":false,"rival_mid":mid,"rival_high":float(item.progress_high),"day":int(item.day),"age_days":int(item.age_days),"local_city_id":String(item.local_city_id),"city_id":String(item.city_id),"confidence":float(item.confidence),"allied":_allied(observer,String(item.owner))}
	if not result.is_empty():result["rival_ahead"]=float(result.rival_mid)>own_fraction
	return result

static func _allied(observer:String,other:String)->bool:
	return String(relation(observer,other).get("treaty","none")) not in ["","none"]

# ---------------------------------------------------------------- sabotage

static func sabotage(target:String,city_id:String,work_id:String)->Dictionary:
	## Runs in the saboteur's scope. Paid provisions, real agents, real risk.
	var source:=WorldSimulation.actor_id
	var state:=WorldSimulation.state
	var day:=int(state.elapsed_days)
	if target==source or owner_state(target)==null:return {"error":"Choose another civilization's work."}
	var sighting:Dictionary={}
	for report:Dictionary in _intel_book(source).values():
		for s:Dictionary in report.get("works",[]):
			if String(s.owner)==target and String(s.local_city_id)==city_id and String(s.work_id)==work_id and day-int(s.observed_day)<=RACE_MAX_AGE:
				sighting=s.duplicate();sighting["position"]=report.get("position",{})
	if sighting.is_empty():return {"error":"No recent report identifies that work and where it stands."}
	if not in_contact(source,target):return {"error":"Agents need known routes to that people."}
	var ties:=Exchange.connection(target)
	if day<int(ties.get("great_work_sabotage_day",-SABOTAGE_COOLDOWN))+SABOTAGE_COOLDOWN:return {"error":"Agents are still recovering from the last attempt."}
	var r:=work_record(target,city_id,work_id)
	if r.is_empty():return {"error":"The reported work is not where it was reported."}
	var home:=Vector2(state.settlement_founded_at.x,state.settlement_founded_at.z)
	var there:=Vector2(float(sighting.position.get("x",home.x)),float(sighting.position.get("z",home.y)))
	var days:=ceili(home.distance_to(there)/17.0)*2+10
	var rations:=float(SABOTAGE_AGENTS*days)
	var free:=state.able_population()-WorldSimulation.military._mobilized_count()-12
	if free<SABOTAGE_AGENTS:return {"error":"No agents can be spared from work and service."}
	if WorldSimulation.food.total_stored()-rations<state.population_exact*7:return {"error":"The agents' provisions would leave less than a week of food at home."}
	WorldSimulation.food.issue_for_obligation(rations,"sabotage","Agents sent abroad",days,SABOTAGE_AGENTS)
	ties["great_work_sabotage_day"]=day
	var own:=personality(source)
	var their:=personality(target)
	var chance:=clampf(.28+float(sighting.quality)*.3+float(own.get("risk_tolerance",.5))*.1-float(their.get("discipline",.5))*.2-(.1 if bool(relation(source,target).get("at_war",false)) else 0.0),.1,.6)
	var rng:=RandomNumberGenerator.new();rng.seed=state.world_seed^hash("sabotage:%s:%s:%s:%d" % [source,target,work_id,day])
	var success:=rng.randf()<chance
	var title:=_title(r)
	var place:=String(city_record(target,city_id).get("name","their city"))
	var rv:=_rivalry(r)
	if success:
		if String(r.status)=="functioning":r.condition=maxf(SIEGE_FLOOR,float(r.condition)-.08)
		else:
			var setback:=minf(float(r.progress),U.total_work(r)*SABOTAGE_SETBACK)
			var keep:=1.0-setback/maxf(.001,float(r.progress))
			r.progress=float(r.progress)-setback;r.quality=float(r.quality)*keep
		_push(rv.events,{"day":day,"kind":"sabotage","by":source,"caught":false},EVENT_LIMIT)
		U.record_event(r,day,"A sudden collapse; strangers had been seen near the works","sabotage")
		_notify(target,day,"COLLAPSE AT %s" % title.to_upper(),"Part of %s at %s gave way. Strangers had been seen near the works." % [title,place])
		return {"ok":true,"success":true,"chance":chance,"message":"Our agents set back %s at %s and returned unseen." % [title,place]}
	state.register_population_deaths(SABOTAGE_AGENTS,"Agents captured abroad")
	_push(rv.events,{"day":day,"kind":"sabotage","by":source,"caught":true},EVENT_LIMIT)
	_push(rv.grievances,{"day":day,"kind":"sabotage","by":source},GRIEVANCE_LIMIT)
	U.record_event(r,day,"Foreign saboteurs caught at the works","sabotage")
	_opinion(target,source,-.25,.15)
	_remember(target,source,"Your agents were caught sabotaging our %s at %s. We have not forgotten." % [title,place],"Their people caught our agents at their %s at %s." % [title,place])
	WorldSimulation.scoped(target,func()->void:
		var theirs:=Exchange.connection(source);theirs.resentment=minf(1,float(theirs.resentment)+.2))
	_notify(target,day,"SABOTEURS CAUGHT","Agents of %s were caught at %s working to bring down %s." % [civ_name(target,source),place,title])
	return {"ok":true,"success":false,"chance":chance,"message":"Our agents were caught at %s; they will not return, and %s knows who sent them." % [place,civ_name(source,target)]}

# ---------------------------------------------------------------- war

static func advance_world(day:int)->void:
	## Once per world day, in the human scope, after every owner has moved.
	if WorldSimulation.actor_id!="player":return
	for owner:String in owners():
		var military:=owner_system(owner,"MilitaryCampaign")
		var besieged:=""
		var pressure:=0.0
		if military!=null and not military.active_siege.is_empty() and String(military.active_siege.get("mode",""))=="defensive":
			besieged=String(military.active_siege.get("home_city",{}).get("id",military.active_siege.get("region_id","")))
			pressure=clampf(float(military.active_siege.get("pressure",0)),0,1)
		for city:Dictionary in cities(owner):
			var records:Array=city.get("undertakings",[])
			if records.is_empty():continue
			var current:=holder(owner,city)
			for r:Dictionary in records:
				if String(r.get("status","")) in ["abandoned","quarried"]:continue
				# Read without creating a block: untouched works keep their records unchanged.
				var previous:=String((r.get("rivalry",{}) as Dictionary).get("holder",owner)) if r.get("rivalry") is Dictionary else owner
				if previous!=current:_change_holder(owner,city,r,previous,current,day)
				if besieged==String(city.id):_siege_wear(owner,city,r,pressure,String(military.active_siege.get("id","")),day)

static func _change_holder(owner:String,city:Dictionary,r:Dictionary,previous:String,current:String,day:int)->void:
	var rv:=_rivalry(r)
	rv.holder=current
	var title:=_title(r);var place:=String(city.get("name","a city"))
	if current==owner:
		rv.erase("captured_by");rv["recovered_day"]=day
		_push(rv.events,{"day":day,"kind":"recovered","by":previous},EVENT_LIMIT)
		_push(rv.grievances,{"day":day,"kind":"recovered","by":previous},GRIEVANCE_LIMIT)
		U.record_event(r,day,"Returned to its builders' control","war")
		_notify(owner,day,"%s RECOVERED" % title.to_upper(),"%s at %s is again in our hands. What was taken from it is remembered." % [title,place])
		return
	rv["captured_by"]=current;rv["captured_day"]=day
	_push(rv.events,{"day":day,"kind":"captured","by":current},EVENT_LIMIT)
	_push(rv.grievances,{"day":day,"kind":"captured","by":current},GRIEVANCE_LIMIT)
	U.record_event(r,day,"Seized by foreign occupation","war")
	_opinion(owner,current,-.3,.2)
	_remember(owner,current,"Your armies seized our %s at %s. Our people will not forget." % [title,place],"Our armies hold your %s at %s." % [title,place])
	_notify(owner,day,"%s LOST" % title.to_upper(),"%s at %s now stands under %s occupation." % [title,place,civ_name(owner,current)])
	_notify(current,day,"%s TAKEN" % title.to_upper(),"Our occupation of %s places %s in our hands." % [place,title])
	# Captors decide by their own sovereign's character; the human decides
	# for itself through the same validated order.
	if current!="player" and not enshrined_ids(r).is_empty():
		var p:=personality(current)
		if (1.0-float(p.empathy))*.6+float(p.assertiveness)*.4>.55:
			WorldSimulation.submit(current,{"kind":"great_work_loot","owner":owner,"city":String(city.id),"id":String(r.id)})

static func _siege_wear(owner:String,city:Dictionary,r:Dictionary,pressure:float,siege_id:String,day:int)->void:
	var rv:=_rivalry(r)
	var wear:=SIEGE_DAILY_WEAR*(.5+pressure)
	if String(r.status)=="functioning":r.condition=maxf(minf(float(r.condition),SIEGE_FLOOR),float(r.condition)-wear)
	else:
		var setback:=minf(float(r.progress),U.total_work(r)*wear*.25)
		if float(r.progress)>0:r.quality=float(r.quality)*(1.0-setback/float(r.progress))
		r.progress=float(r.progress)-setback
	if String(rv.get("last_siege",""))!=siege_id:
		rv["last_siege"]=siege_id
		_push(rv.events,{"day":day,"kind":"siege_damage","by":""},EVENT_LIMIT)
		U.record_event(r,day,"Damaged during a siege","war")

static func enshrined_ids(r:Dictionary)->Array[String]:
	var result:Array[String]=[]
	for entry:Variant in r.get("enshrined",r.get("enshrined_artifacts",[])):
		var id:=String(entry.get("id","")) if entry is Dictionary else String(entry)
		if not id.is_empty():result.append(id)
	return result

static func _clear_enshrined(r:Dictionary,ids:Array)->void:
	for key:String in ["enshrined","enshrined_artifacts"]:
		if not r.get(key) is Array:continue
		var kept:Array=[]
		for entry:Variant in r[key]:
			var id:=String(entry.get("id","")) if entry is Dictionary else String(entry)
			if id not in ids:kept.append(entry)
		r[key]=kept

static func loot(owner:String,city_id:String,work_id:String)->Dictionary:
	## Runs in the occupier's scope: moves real enshrined items between the
	## two owners' society_exchange collections.
	var looter:=WorldSimulation.actor_id
	var city:=city_record(owner,city_id)
	if city.is_empty() or owner==looter or holder(owner,city)!=looter:return {"error":"Only an occupier holding the city can carry off its treasures."}
	var r:=work_record(owner,city_id,work_id)
	if r.is_empty():return {"error":"That work is not in this city."}
	var source:=owner_state(owner);var target:=owner_state(looter)
	var moved:Array[String]=[]
	for id:String in enshrined_ids(r):
		var item:Dictionary=source.society_exchange.collections.get(id,{})
		if item.get("kind","")!="artifact" or target.society_exchange.collections.has(id):continue
		Artifacts.move(source,target,item);moved.append(id)
	if moved.is_empty():return {"error":"Nothing enshrined remains to take."}
	_clear_enshrined(r,moved)
	var day:=int(WorldSimulation.state.elapsed_days)
	var rv:=_rivalry(r)
	for id:String in moved:_push(rv.looted,{"id":id,"by":looter,"day":day,"returned":false},LOOT_LIMIT)
	_push(rv.events,{"day":day,"kind":"looted","by":looter,"count":moved.size()},EVENT_LIMIT)
	_push(rv.grievances,{"day":day,"kind":"looted","by":looter},GRIEVANCE_LIMIT)
	U.record_event(r,day,"Enshrined treasures carried off by occupiers","war")
	for id:String in [owner,looter]:WorldSimulation.scoped(id,func()->void:WorldSimulation.state.society_exchange["artifact_bonuses"]=Artifacts.summary())
	var title:=_title(r);var place:=String(city.get("name","a city"))
	_opinion(owner,looter,-.3,.15)
	_remember(owner,looter,"Your soldiers stripped the treasures from our %s at %s." % [title,place],"We carried off the treasures of your %s at %s." % [title,place])
	# Observers who know either people hear of it and judge the looter.
	for observer:String in owners():
		if observer in [owner,looter] or observer=="player":continue
		if not (in_contact(observer,owner) or in_contact(observer,looter)):continue
		var p:=personality(observer)
		_opinion(observer,looter,-.06-.12*float(p.empathy),0.0)
	_notify(owner,day,"%s LOOTED" % title.to_upper(),"Occupiers carried off %d enshrined treasures from %s at %s." % [moved.size(),title,place])
	return {"ok":true,"count":moved.size(),"items":moved,"message":"%d treasures carried off from %s. Every people that hears of it will remember." % [moved.size(),title]}

static func return_loot(owner:String,work_id:String)->Dictionary:
	## Runs in the looter's scope: gives back items it still holds.
	var looter:=WorldSimulation.actor_id
	if owner==looter or owner_state(owner)==null:return {"error":"Choose the people the treasures were taken from."}
	if bool(relation(looter,owner).get("at_war",false)):return {"error":"Nothing can be returned while at war."}
	var source:=owner_state(looter);var target:=owner_state(owner)
	var day:=int(WorldSimulation.state.elapsed_days)
	var count:=0;var title:=""
	for city:Dictionary in cities(owner):
		for r:Dictionary in city.get("undertakings",[]):
			if String(r.id)!=work_id:continue
			var rv:=_rivalry(r)
			for entry:Dictionary in rv.looted:
				if String(entry.by)!=looter or bool(entry.returned):continue
				var item:Dictionary=source.society_exchange.collections.get(String(entry.id),{})
				if item.is_empty() or target.society_exchange.collections.has(String(entry.id)):continue
				Artifacts.move(source,target,item);entry.returned=true;count+=1
			if count>0:
				title=_title(r)
				_push(rv.events,{"day":day,"kind":"returned","by":looter,"count":count},EVENT_LIMIT)
				_push(rv.grievances,{"day":day,"kind":"returned","by":looter},GRIEVANCE_LIMIT)
	if count==0:return {"error":"We hold nothing taken from that work."}
	for id:String in [owner,looter]:WorldSimulation.scoped(id,func()->void:WorldSimulation.state.society_exchange["artifact_bonuses"]=Artifacts.summary())
	_opinion(owner,looter,.12,-.05)
	_remember(owner,looter,"You returned %d treasures of our %s. It is a beginning." % [count,title],"We returned the treasures of your %s." % title)
	_notify(owner,day,"TREASURES RETURNED","%s returned %d treasures taken from %s." % [civ_name(owner,looter).capitalize(),count,title])
	return {"ok":true,"count":count,"message":"%d treasures returned to their builders." % count}

static func restore(city_id:String,work_id:String)->Dictionary:
	## Runs in the owner's scope: repairs a damaged work from local stores.
	var owner:=WorldSimulation.actor_id
	var city:=city_record(owner,city_id)
	if city.is_empty() or holder(owner,city)!=owner:return {"error":"Only a city under our own control can restore its works."}
	var r:=work_record(owner,city_id,work_id)
	if r.is_empty() or String(r.get("status",""))!="functioning":return {"error":"Only a standing, functioning work can be restored."}
	var amount:=minf(.3,1.0-float(r.condition))
	if amount<.02:return {"error":"The work needs no restoration."}
	var d:=definition(work_id)
	return WorldSimulation.settlements.with_city_resources(city_id,func()->Dictionary:
		var stores:Dictionary=WorldSimulation.state.resource_stockpiles
		var bill:Dictionary={}
		for material:String in d.get("cost",{}):
			bill[material]=float(d.cost[material])*amount*.4
			if float(stores.get(material,0))<float(bill[material]):return {"error":"Restoration needs %.0f %s from local stores." % [float(bill[material]),material]}
		for material:String in bill:stores[material]=float(stores[material])-float(bill[material])
		r.condition=minf(1.0,float(r.condition)+amount)
		var day:=int(WorldSimulation.state.elapsed_days)
		var rv:=_rivalry(r)
		rv["restored_day"]=day
		_push(rv.events,{"day":day,"kind":"restored","by":""},EVENT_LIMIT)
		U.record_event(r,day,"Restored by local crews","war")
		return {"ok":true,"materials":bill,"message":"Restoration repaired %s." % _title(r)})

static func grievance(owner:String,other:String)->float:
	## A lasting reason for `owner` to distrust `other`, from its own works' histories.
	var today:=_today(owner)
	var total:=0.0
	for city:Dictionary in cities(owner):
		var held_by_other:=holder(owner,city)==other
		for r:Dictionary in city.get("undertakings",[]):
			var rv:Dictionary=r.get("rivalry",{})
			if rv.is_empty():continue
			if held_by_other:total+=.35
			for g:Dictionary in rv.get("grievances",[]):
				if String(g.get("by",""))!=other:continue
				var years:=float(today-int(g.day))/365.0
				match String(g.kind):
					"captured":if not held_by_other:total+=.12*maxf(0,1-years/30.0)
					"sabotage":total+=.15*maxf(0,1-years/10.0)
			for entry:Dictionary in rv.get("looted",[]):
				if String(entry.by)==other and not bool(entry.returned):total+=.05
	return clampf(total,0,.6)

static func _opinion(scope:String,toward:String,delta:float,tension:float)->void:
	## `scope`'s attitude toward `toward`. A ruled owner keeps it in its own view
	## (its ruler decides war and trade from it); the human sees a foreign
	## people's attitude in its own view of that people. The human's own
	## attitude is never set for it.
	var ledgers:Array=[]
	if scope!="player":ledgers.append([scope,toward])
	if toward=="player" and scope!="player":ledgers.append(["player",scope])
	for pair:Array in ledgers:
		if owner_state(String(pair[0]))==null or String(pair[0])==String(pair[1]):continue
		WorldSimulation.scoped(String(pair[0]),func()->void:
			var name:=view_id(String(pair[1]),String(pair[0]))
			for civ:Dictionary in WorldSimulation.world.civilizations:
				if String(civ.get("id",""))!=name:continue
				var rel:Dictionary=civ.player_relation
				rel["opinion"]=clampf(float(rel.get("opinion",0))+delta,-1,1)
				if tension!=0.0:rel["border_tension"]=clampf(float(rel.get("border_tension",0))+tension,0,1)
		)

static func _remember(victim:String,other:String,victim_words:String,other_words:String)->void:
	## Leader memories: in `other`'s conversations the victim's ruler recalls the
	## wrong; in the victim's conversations the other ruler recalls the deed.
	for pair in [[other,victim,victim_words],[victim,other,other_words]]:
		if owner_state(String(pair[0]))==null:continue
		WorldSimulation.scoped(String(pair[0]),func()->void:WorldSimulation.diplomacy.remember(view_id(String(pair[1]),String(pair[0])),String(pair[2])))

static func _notify(owner:String,day:int,title:String,text:String)->void:
	if owner_state(owner)==null:return
	WorldSimulation.scoped(owner,func()->void:
		WorldSimulation.state.simulation_events.push_front({"day":day,"title":title,"description":text,"domain":"diplomacy","severity":"major"})
		if owner=="player":WorldSimulation.world._record_world_event(title.capitalize(),text,"diplomacy",day,{"kind":"great_work_rivalry"})
	)

static func valid_rivalry(record:Dictionary)->bool:
	## For undertaking_system.valid(): the optional per-site rivalry block.
	if not record.has("rivalry"):return true
	var rv:Variant=record.rivalry
	if not rv is Dictionary:return false
	for key:String in ["holder","captured_by","last_siege"]:
		if rv.has(key) and (not rv[key] is String or rv[key].length()>120):return false
	for key:String in ["captured_day","recovered_day","restored_day"]:
		if rv.has(key) and (not rv[key] is int or rv[key]<0):return false
	for pair in [["events",EVENT_LIMIT],["grievances",GRIEVANCE_LIMIT],["looted",LOOT_LIMIT]]:
		var list:Variant=rv.get(pair[0],[])
		if not list is Array or list.size()>int(pair[1]):return false
		for entry:Variant in list:
			if not entry is Dictionary or not entry.get("day") is int or int(entry.day)<0:return false
			if pair[0]!="looted" and not entry.get("kind") is String:return false
			if pair[0]=="looted" and (not entry.get("id") is String or not entry.get("returned") is bool):return false
			if not entry.get("by","") is String:return false
	return true

# ---------------------------------------------------------------- effects
## G1's undertaking_effects.gd owns the effect values; this module decides who
## may act on them. Its held_works excludes captured cities; see `held_works`.

static func known_deterrence(observer:String,other:String)->float:
	## Deterrence only restrains a ruler who has actually learned of the work.
	if other==observer:return 0.0
	for item:Dictionary in rival_news_for(observer):
		if String(item.owner)==other and String(item.get("status",""))=="functioning" and String(item.kind) in ["sighting","account"]:
			return clampf(Effects.deterrence(other),0,.3)
	return 0.0

static func trade_routing(owner:String)->float:
	## Extra external-market access for foreign traders routed toward the holder
	## (0..0.40 from the effect, scaled to at most +0.10 access).
	return clampf(Effects.traffic_bonus(owner)*.25,0,.1)
