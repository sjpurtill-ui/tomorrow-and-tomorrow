extends RefCounted
## Great Works engine. Every civilization (player or AI) uses these same
## functions inside its own WorldSimulation scope; nothing here is player-only.
## Records live on each owner's settlements (`city.undertakings`). A work is
## world-unique: the first owner to finish it claims it, and every other site of
## the same work becomes a named unfinished rival monument.
const Catalog=preload("res://scripts/undertaking_catalog.gd")
const Rewards=preload("res://scripts/undertaking_rewards.gd")
const Sites=preload("res://scripts/undertaking_sites.gd")
const Effects=preload("res://scripts/undertaking_effects.gd")
const Exchange=preload("res://scripts/civilization_exchange.gd")
const NAMES=preload("res://scripts/historical_name_generator.gd")
const STATUSES:=["building","stalled","functioning","abandoned","ruined","rival","quarried"]
const STAGES:=["foundations","raising","crowning","dedication"]
## Stage gates. Each raises one decision when construction reaches it.
const GATES:=[[.25,"design"],[.45,"stores"],[.70,"labor"]]
const DECISION_KEYS:=["design","stores","labor","demand"]
const EVENT_KINDS:=["collapse","accident","strike","ingenious","omen","demand","poaching","fire"]
const PLAYER_DECISION_DAYS:=90
const AI_DECISION_DAYS:=2
const PLAYER_CEREMONY_DAYS:=90
const AI_CEREMONY_DAYS:=7
const EVENT_CHANCE_PER_MILLE:=3
const MAX_STAGE_EVENTS:=2
const GIFT_RESOURCES:=["Stone","Timber","Clay","Fiber Plants","Salt","Medicinal Plants","Copper Ore","Tin Ore","Iron Ore","Coal","Civilian Goods"]

# --- Owners and identity ------------------------------------------------------
static func owners()->Array:
	var ids:Array=["player"]
	var others:Array=WorldSimulation.actors.keys();others.sort()
	ids.append_array(others)
	return ids
static func owner_state(owner:String)->Node:
	return preload("res://scripts/society_exchange.gd").owner_state(owner)
static func owner_name(owner:String)->String:
	if owner in ["player","human"]:
		return GameState.settlement_name if not GameState.settlement_name.is_empty() else "Your people"
	var identity:Dictionary=WorldSimulation.actors.get(owner,{}).get("identity",{})
	return String(identity.get("name",owner))
static func is_ai(owner:String)->bool:
	return owner!="player" and String(WorldSimulation.actors.get(owner,{}).get("controller",""))=="ai"
## A settlement is controlled by the scoped owner when nobody else occupies it.
static func controlled(city:Dictionary)->bool:
	return String(city.get("occupied_by","")) in ["",WorldSimulation.actor_id]
static func current_city(state:Node)->Dictionary:
	for city:Dictionary in state.player_settlements:
		if String(city.id)==String(state.resource_settlement_id) or (state.resource_settlement_id.is_empty() and bool(city.get("primary",false))):return city
	return {}

# --- Record helpers -----------------------------------------------------------
static func total_work(r:Dictionary)->float:
	return float(Catalog.get_definition(String(r.id)).get("work",1.0))*float(r.get("work_scale",1.0))
static func fraction(r:Dictionary)->float:
	return clampf(float(r.get("progress",0))/maxf(.001,total_work(r)),0,1)
static func stage_of(r:Dictionary)->String:
	if r.status in ["functioning","ruined"] and fraction(r)>=1:return "dedication"
	var f:=fraction(r)
	return "foundations" if f<.25 else ("raising" if f<.70 else "crowning")
## A finished, non-lesser work (functioning or its ruin) holds a world claim.
static func completed(r:Dictionary)->bool:
	return not bool(r.get("lesser",false)) and String(r.get("status","")) in ["functioning","ruined"] and float(r.get("progress",0))+.00001>=total_work(r)
static func held(r:Dictionary)->bool:
	return completed(r) and r.status=="functioning"
static func display_name(record:Dictionary)->String:
	return String(record.get("custom_name",Catalog.get_definition(String(record.id)).get("title","Undertaking")))
static func record_event(record:Dictionary,day:int,message:String,kind:String="",figure_ids:Array=[])->void:
	if not record.has("events"):record.events=[]
	var event:={"day":day,"text":message}
	if not kind.is_empty():event.kind=kind
	if not figure_ids.is_empty():event.figure_ids=figure_ids.duplicate()
	record.events.push_front(event)
	if record.events.size()>12:record.events.resize(12)
static func find(city:Dictionary,id:String)->Dictionary:
	for r:Dictionary in city.get("undertakings",[]):
		if String(r.id)==id:return r
	return {}
static func _seed()->int:return int(WorldSimulation.state.world_seed)
static func _roll(parts:String)->int:return absi(hash("%d/%s" % [_seed(),parts]))

## Lazily adds fields introduced by Great Works to a legacy record. Gates below
## current progress count as already passed; legacy work is never re-gated.
static func migrate(r:Dictionary)->void:
	if r.has("gates"):return
	var passed:Array=[]
	for gate:Array in GATES:
		if fraction(r)>=float(gate[0]):passed.append(gate[1])
	r.gates=passed
	if not r.has("decisions"):r.decisions=[]
	if not r.has("work_scale"):r.work_scale=1.0
	if not r.has("speed"):r.speed=1.0
	if not r.has("allure_scale"):r.allure_scale=1.0

## G2's rivalry module (observation, war, sabotage). Loaded lazily: it preloads
## this script. Absent in stripped builds; callers treat null as "no rivalry".
static func rivalry_script()->GDScript:
	const PATH:="res://scripts/great_works_rivalry.gd"
	if not ResourceLoader.exists(PATH):return null
	return load(PATH) as GDScript
static func rivalry_race(observer:String,work_id:String,own_fraction:float)->Dictionary:
	var rivalry:=rivalry_script()
	if rivalry==null:return {}
	var race:Variant=rivalry.call("race_for",observer,work_id,own_fraction)
	return race if race is Dictionary else {}

# --- World claims -------------------------------------------------------------
## Every claimed work in the world: {work_id:{owner,holder,city_id,city_name,day,name}}.
## Upgrade layers keep their earlier claims. Earliest claim wins; ties resolve by
## owner order, which never depends on who is human.
static func claims()->Dictionary:
	var result:={}
	for owner:String in owners():
		var s:=owner_state(owner)
		if s==null:continue
		for city:Dictionary in s.player_settlements:
			for r:Dictionary in city.get("undertakings",[]):
				if completed(r):_claim(result,String(r.id),owner,city,r,int(r.get("claimed_day",0)))
				for layer in r.get("layers",[]):
					if layer is Dictionary:_claim(result,String(layer.get("id","")),owner,city,r,int(layer.get("claimed_day",0)))
	return result
static func _claim(result:Dictionary,id:String,owner:String,city:Dictionary,r:Dictionary,day:int)->void:
	if id.is_empty() or (result.has(id) and int(result[id].day)<=day):return
	var occupier:=String(city.get("occupied_by",""))
	var holder:String=owner if occupier.is_empty() or occupier=="player" else Exchange.recipient(occupier)
	result[id]={"owner":owner,"holder":holder,"city_id":String(city.get("id","")),"city_name":String(city.get("name","")),"day":day,"name":display_name(r),"status":String(r.status),"current_id":String(r.id)}
static func claim_of(id:String)->Dictionary:
	return claims().get(id,{})
## Every active site of a work across the world (for races, rumors and AI).
static func sites_of(id:String)->Array:
	var result:Array=[]
	for owner:String in owners():
		var s:=owner_state(owner)
		if s==null:continue
		for city:Dictionary in s.player_settlements:
			var r:=find(city,id)
			if r.is_empty() or r.status not in ["building","stalled"]:continue
			result.append({"owner":owner,"city_id":String(city.id),"city_name":String(city.get("name","")),"progress":fraction(r),"stage":stage_of(r),"started":int(r.get("started",0))})
	return result

static func _owner_ids(state:Node)->Dictionary:
	var result:={}
	for city:Dictionary in state.player_settlements:
		for r:Dictionary in city.get("undertakings",[]):
			if r.status not in ["abandoned","quarried"]:result[String(r.id)]=String(city.id)
			for layer in r.get("layers",[]):
				if layer is Dictionary:result[String(layer.get("id",""))]=String(city.id)
	return result

# --- Existing labor accounting -----------------------------------------------
static func share(state:Node)->float:
	var total:=0.0
	for r:Dictionary in current_city(state).get("undertakings",[]):
		if r.status in ["building","stalled"]:total+=.50 if r.policy=="press" else .20
		elif r.status=="functioning":total+=.02
	return minf(.65,total)
static func benefit(state:Node,role:String)->float:
	var bonus:=0.0
	for r:Dictionary in current_city(state).get("undertakings",[]):
		var d:=Catalog.get_definition(String(r.id))
		if r.status=="functioning" and not bool(r.get("lesser",false)) and d.get("role","")==role:bonus+=float(d.bonus)*float(r.condition)
	if role=="Crafting":bonus+=Rewards.local_bonus(state,"craft")
	if role=="Knowledge":bonus+=Rewards.local_bonus(state,"research")
	return minf(.30,bonus)

# --- Availability -------------------------------------------------------------
## Works the scoped owner may begin in this settlement: unclaimed in the world,
## not already pursued by this owner, discoveries/population/environment met.
static func possibilities(city:Dictionary)->Array:
	var result:Array=[]
	var state=WorldSimulation.state
	if city.is_empty():return result
	var profile:=PlanetEnvironment.profile_at(city.get("position",Vector2.ZERO))
	var claimed:=claims()
	var own:=_owner_ids(state)
	for d:Dictionary in Catalog.all():
		if claimed.has(d.id) or own.has(d.id):continue
		if state.population_total<int(d.population):continue
		var known:=true
		for requirement:String in d.requires:
			if requirement not in state.known_discoveries:known=false
		if not known:continue
		var rain:=float(profile.get("precipitation",.5))
		if d.environment=="dry" and rain>.45:continue
		if d.environment=="wet" and rain<.5:continue
		if d.environment=="woodland" and String(profile.get("biome",""))!="woodland":continue
		if not String(d.upgrade_from).is_empty():
			var base:=find(city,String(d.upgrade_from))
			if base.is_empty() or not held(base):continue
		result.append(d)
	return result

# --- Authorization ------------------------------------------------------------
static func start(city_id:String,id:String,site_height:Callable=Callable(),site_land:Callable=Callable())->Dictionary:
	var city:=WorldSimulation.settlements.settlement_record(city_id)
	if city.is_empty() or not controlled(city):return {"error":"No controlled settlement selected."}
	return WorldSimulation.settlements.with_city_resources(city_id,func()->Dictionary:
		return WorldSimulation.settlements.with_local_population(func()->Dictionary:
			for r:Dictionary in city.get("undertakings",[]):
				if r.status in ["building","stalled"]:return {"error":"This settlement already supports an undertaking."}
			var eligible:=false
			for d:Dictionary in possibilities(city):
				if d.id==id:eligible=true
			var resumed:=find(city,id)
			if resumed.get("status","")=="abandoned" and claim_of(id).is_empty():eligible=true
			if not eligible:return {"error":"This opportunity is not available here."}
			var day:=int(WorldSimulation.state.elapsed_days)
			var d:=Catalog.get_definition(id)
			var record:Dictionary
			if not String(d.upgrade_from).is_empty():
				record=find(city,String(d.upgrade_from))
				_push_layer(record,day)
				record.id=id
				_reset_building(record,day)
				record.reason="Rebuilding in place; the older work closes while crews raise the new one."
				record.legacy="An ambition built on an older achievement"
				record_event(record,day,"Rebuilding begins: %s will rise from %s" % [String(d.title),display_name(record)],"upgrade")
			elif not resumed.is_empty():
				record=resumed
				migrate(record)
				record.status="building";record.stalled_days=0;record.last_day=day
				record.reason="Work resumes on the abandoned site."
				record.legacy="An ambition, not yet an achievement"
				record_event(record,day,"Work resumes on the abandoned site","resume")
			else:
				var height:Callable=site_height if site_height.is_valid() else PlanetEnvironment.world_height_at
				var land:Callable=site_land if site_land.is_valid() else PlanetEnvironment.is_land
				var site:=Sites.choose(city,WorldSimulation.state.settlement_plots,WorldSimulation.state.world_seed,height,land)
				if site.is_empty():return {"error":"No clear, gentle land is available near this settlement for a landmark."}
				if not city.has("undertakings"):city.undertakings=[]
				record={"id":id}
				_reset_building(record,day)
				record.site=site
				city.undertakings.append(record)
				record_event(record,day,"Foundations authorized")
			record.architect=_commission_architect(String(city.id),id,day)
			if not record.architect.is_empty():
				record_event(record,day,"%s accepts the commission as master builder" % String(record.architect.name),"architect",[String(record.architect.id)])
			WorldSimulation.state.settlement_network_revision+=1
			return {"ok":true,"message":"A clear site is reserved. Local crews will begin the great work."}))

static func _reset_building(r:Dictionary,day:int)->void:
	r.merge({"status":"building","policy":"careful","progress":0.0,"quality":0.0,"condition":1.0,"strain":0,"stalled_days":0,"operating_days":0,"last_day":day,"started":day,"reason":"Foundations authorized; staff organize the work.","legacy":"An ambition, not yet an achievement","gates":[],"decisions":[],"work_scale":1.0,"speed":1.0,"allure_scale":1.0,"quality_bonus":0.0},true)
	for key in ["decision","ceremony","claimed_day","dedicated_day","halt_until","stage_events","last_work"]:r.erase(key)

static func _push_layer(r:Dictionary,day:int)->void:
	if not r.has("layers"):r.layers=[]
	r.layers.append({"id":String(r.id),"title":String(Catalog.get_definition(String(r.id)).title),"name":display_name(r),"claimed_day":int(r.get("claimed_day",0)),"from":int(r.get("started",0)),"to":day,"condition":float(r.condition),"operating_days":int(r.operating_days),"strain":int(r.strain),"architect":String(r.get("architect",{}).get("name",""))})
	if r.layers.size()>8:r.layers.pop_front()

static func _commission_architect(city_id:String,id:String,day:int)->Dictionary:
	var figures=WorldSimulation.figures
	if figures==null or not figures.has_method("commission_architect"):return {}
	var p:Dictionary=figures.commission_architect(day,"work:%s:%s" % [city_id,id])
	if p.is_empty():return {}
	var h:=_roll("architect/"+String(p.id))
	var vision:=.25+float(h%700)/1000.0
	var ego:=.15+float((h/700)%800)/1000.0
	var style:String=["austere","soaring","ornate","practical","daring","severe","harmonious","monumental"][(h/560000)%8]
	return {"id":String(p.id),"name":String(p.name),"vision":vision,"ego":ego,"talent":float(p.get("talent",.7)),"style":style,"temperament":String(p.get("temperament","")),"mood":0,"since":day}

# --- Player/AI directions ------------------------------------------------------
static func direct(city_id:String,id:String,order:String)->void:
	var city:=WorldSimulation.settlements.settlement_record(city_id)
	if city.is_empty() or not controlled(city):return
	for r:Dictionary in city.get("undertakings",[]):
		if r.id!=id or r.status not in ["building","stalled"]:continue
		if order=="abandon":
			var day:=int(WorldSimulation.state.elapsed_days)
			if not r.get("layers",[]).is_empty():
				_revert_layer(r,day)
			else:
				r.status="abandoned";r.reason="Support withdrawn; unfinished remains endure.";r.legacy="An unfinished promise"
				r.erase("decision")
				record_event(r,day,"Support withdrawn")
		elif order in ["careful","press"]:r.policy=order
	WorldSimulation.state.settlement_network_revision+=1

static func _revert_layer(r:Dictionary,day:int)->void:
	var layer:Dictionary=r.layers.pop_back()
	var abandoned:=display_name(r)
	r.id=String(layer.id)
	var work:=float(Catalog.get_definition(r.id).work)
	r.merge({"status":"functioning","progress":work,"quality":work*float(layer.condition),"condition":float(layer.condition),"operating_days":int(layer.operating_days),"strain":int(layer.strain),"claimed_day":int(layer.claimed_day),"work_scale":1.0,"reason":"The rebuilding was abandoned; the older work reopens.","legacy":"Useful, not yet renowned"},true)
	for key in ["decision","ceremony","halt_until","stage_events"]:r.erase(key)
	var passed:Array=[]
	for gate:Array in GATES:passed.append(gate[1])
	r.gates=passed
	record_event(r,day,"Rebuilding abandoned; %s reopens" % abandoned,"upgrade")

# --- Daily advance ------------------------------------------------------------
static func advance_all(day:int)->void:
	var owner:=WorldSimulation.actor_id
	for city:Dictionary in WorldSimulation.state.player_settlements:
		if not controlled(city):continue
		if city.get("undertakings",[]).is_empty():continue
		WorldSimulation.settlements.with_city_resources(String(city.id),func()->void:
			WorldSimulation.settlements.with_local_population(func()->void:
				# A multi-day step (day_span.gd) keeps upkeep daily.
				for covered in range(day-WorldSimulation.span+1,day+1):
					for r:Dictionary in city.undertakings:advance_record(WorldSimulation.state,r,covered,city)
				for r:Dictionary in city.undertakings:_resolve_waiting(r,city,day,owner)
				Effects.advance_city(WorldSimulation.state,city,day,WorldSimulation.span)))
	Rewards.record_victory(WorldSimulation.state,day)

## Decisions and ceremonies wait for their owner; AI owners answer promptly, and
## a player's council answers after a long silence so work never deadlocks.
static func _resolve_waiting(r:Dictionary,city:Dictionary,day:int,owner:String)->void:
	var ai:=is_ai(owner)
	var decision:Dictionary=r.get("decision",{})
	if not decision.is_empty() and day-int(decision.get("day",day))>=(AI_DECISION_DAYS if ai else PLAYER_DECISION_DAYS):
		var choice:=auto_option(WorldSimulation.state,r,ai)
		if not choice.is_empty():_apply_decision(WorldSimulation.state,r,String(city.id),choice,day,not ai)
	var ceremony:Dictionary=r.get("ceremony",{})
	if String(ceremony.get("status",""))=="pending" and day-int(ceremony.get("day",day))>=(AI_CEREMONY_DAYS if ai else PLAYER_CEREMONY_DAYS):
		var names:Array=ceremony.get("name_suggestions",[])
		_dedicate_record(r,city,String(names[0]) if not names.is_empty() else display_name(r),day,not ai)

static func advance_record(state:Node,r:Dictionary,day:int,city:Dictionary={})->void:
	if day<=int(r.last_day):return
	# The calendar calls once per day. Loading never awards skipped work.
	r.last_day=day
	r.last_work=0.0
	migrate(r)
	var d:=Catalog.get_definition(String(r.id))
	var m:Dictionary=state.simulation_metrics
	var need:=minf(float(m.get("food_intake_ratio",1)),float(state.water_metrics.get("intake_ratio",1)))
	if r.status in ["abandoned","ruined","rival","quarried"]:return
	if r.status=="functioning":
		var maintained:bool=need>=.95 and state.effective_workers("Construction")>=1
		for material:String in d.cost:
			if float(state.resource_stockpiles.get(material,0))<float(d.cost[material])/36500.0:maintained=false
		if maintained:
			for material:String in d.cost:state.resource_stockpiles[material]-=float(d.cost[material])/36500.0
			r.condition=minf(1,float(r.condition)+.0002);r.operating_days+=1
		else:r.condition=maxf(0,float(r.condition)-.0005)
		r.reason="Staff maintain the site." if maintained else "Maintenance faltering: labor, provisions or materials are missing."
		if r.condition<=.15:
			r.status="ruined";r.legacy="A lost achievement"
			record_event(r,day,"Lost to neglect","ruin")
		elif int(r.operating_days)>=3650:r.legacy="Enduring achievement" if int(r.strain)<180 else "Enduring, but remembered for its human cost"
		return
	var city_id:=String(city.get("id",""))
	# Someone else finished first: this site becomes an unfinished rival.
	var rival_claim:=claim_of(String(r.id))
	if not rival_claim.is_empty():
		_become_rival(r,rival_claim,day)
		state.settlement_network_revision+=1
		return
	if not r.get("decision",{}).is_empty():
		r.reason="Awaiting a decision at the %s gate." % String(r.decision.get("key","")).replace("_"," ")
		return
	for gate:Array in GATES:
		if fraction(r)>=float(gate[0]) and String(gate[1]) not in r.gates:
			_pose(r,String(gate[1]),day)
			return
	if int(r.get("halt_until",-1))>day:
		r.reason="Crews have laid down their tools; work resumes on day %d." % (int(r.halt_until)%365+1)
		return
	var allocated:=float(state.population_allocations.get("Construction",0))
	var remaining:float=state.effective_workers("Construction")
	var fraction_of_crew:=.50 if r.policy=="press" else .20
	var labor:float=remaining/maxf(.01,1-share(state))*fraction_of_crew*float(r.get("speed",1.0)) if allocated>0 else 0.0
	var leader:Dictionary=WorldSimulation.government.person_snapshot(int(current_city(state).get("leader_person_id",0)))
	var competence:=float((leader.get("skills",{}) as Dictionary).get("Construction",50.0))/100.0
	var quality:=clampf(float(m.get("labor_efficiency",.72))*.4+float(m.get("cohesion",.5))*.2+minf(1,state.effective_workers("Crafting")/8)*.2+competence*.2,.1,1)
	var architect:Dictionary=r.get("architect",{})
	if not architect.is_empty():quality=clampf(quality*(1+(float(architect.vision)-.5)*.1+float(architect.talent)*.05)+float(r.get("quality_bonus",0)),.1,1)
	var work:=minf(labor*quality,total_work(r)-float(r.progress))
	var reason:="Building with local crews and materials."
	if need<.95:
		if r.policy=="careful":work=0;reason="Paused to protect food and water needs."
		else:r.strain+=1;work*=maxf(0,need);reason="Work continues during shortages; resentment accumulates."
	if labor<=0:reason="No building crew available."
	for material:String in d.cost:
		var affordable:=float(state.resource_stockpiles.get(material,0))/maxf(.00001,float(d.cost[material])/float(d.work))
		if affordable<work:work=maxf(0,affordable);reason="Waiting for "+material.to_lower()+"."
	r.reason=reason
	if work<=.00001:
		r.status="stalled";r.stalled_days+=1
		if int(r.stalled_days)>=365*5:
			r.status="abandoned";r.legacy="A promise the settlement could not sustain"
			record_event(r,day,"Abandoned after five years without progress")
		return
	r.status="building";r.stalled_days=0
	_spend(state,d,work)
	r.quality+=work*quality;r.progress+=work
	r.last_work=work
	if not architect.is_empty():_roll_event(state,r,city_id,day)
	if float(r.progress)+.00001>=total_work(r):_complete(state,r,city,day)

static func _spend(state:Node,d:Dictionary,work:float)->void:
	for material:String in d.cost:state.resource_stockpiles[material]=float(state.resource_stockpiles.get(material,0))-float(d.cost[material])*work/float(d.work)
static func _affordable_work(state:Node,d:Dictionary,work:float)->float:
	for material:String in d.cost:
		work=minf(work,maxf(0,float(state.resource_stockpiles.get(material,0)))/maxf(.00001,float(d.cost[material])/float(d.work)))
	return maxf(0,work)

static func _become_rival(r:Dictionary,claim:Dictionary,day:int)->void:
	r.status="rival";r.erase("decision")
	r.reason="%s finished first; this site stands unfinished." % owner_name(String(claim.owner))
	r.legacy="An unfinished rival to %s" % String(claim.name)
	if not r.has("custom_name"):r.custom_name=("The Unfinished "+String(Catalog.get_definition(String(r.id)).title)).substr(0,60)
	r.rival_of={"owner":String(claim.owner),"day":int(claim.day)}
	record_event(r,day,"%s claimed %s first; the site becomes an unfinished rival monument" % [owner_name(String(claim.owner)),String(claim.name)],"rival")
	_release_architect(r,day,"The rival work was finished first; the commission ended unfinished.")

static func _release_architect(r:Dictionary,day:int,text:String,renown:int=0)->void:
	var architect:Dictionary=r.get("architect",{})
	if architect.is_empty() or WorldSimulation.figures==null or not WorldSimulation.figures.has_method("note"):return
	WorldSimulation.figures.note(String(architect.id),day,text,renown)
	for slot in WorldSimulation.figures.assignments.keys():
		if String(WorldSimulation.figures.assignments[slot])==String(architect.id) and String(slot).begins_with("work:"):WorldSimulation.figures.release_assignment(String(slot))

static func _complete(state:Node,r:Dictionary,city:Dictionary,day:int)->void:
	# Another owner may have finished earlier today; recheck before claiming.
	var claim:=claim_of(String(r.id))
	if not claim.is_empty():
		_become_rival(r,claim,day)
		state.settlement_network_revision+=1
		return
	var d:=Catalog.get_definition(String(r.id))
	r.condition=clampf(float(r.quality)/total_work(r),.1,1)
	r.status="functioning" if r.condition>=.5 else "ruined"
	r.claimed_day=day
	r.legacy="Useful, not yet renowned" if r.status=="functioning" else "An embarrassing failure: the finished work could not serve its purpose"
	if r.status=="functioning" and int(r.strain)>=180:r.legacy="An achievement built through hardship"
	record_event(r,day,"Completed and functioning" if r.status=="functioning" else "Completed, but failed to function","complete")
	if r.status=="functioning":
		_release_architect(r,day,"Completed %s, a great work of the world." % String(d.title),20)
		if not city.is_empty():_plan_ceremony(state,r,city,day)
	else:_release_architect(r,day,"Finished %s, but it failed to serve its purpose." % String(d.title))
	state.settlement_network_revision+=1

# --- Decisions ----------------------------------------------------------------
static func _pose(r:Dictionary,key:String,day:int)->void:
	var architect:Dictionary=r.get("architect",{})
	var who:=String(architect.get("name","The master builder"))
	var title:=String(Catalog.get_definition(String(r.id)).title)
	var prompt:=""
	match key:
		"design":prompt="The foundations of %s are laid. %s, %s in style, asks whether to raise a grander design or keep it practical." % [title,who,String(architect.get("style","practical"))]
		"stores":prompt="The walls of %s are rising. Crews ask whether the settlement's stored food should feed a larger workforce." % title
		"labor":prompt="%s nears its crowning. Who will do the heaviest lifting: paid crews, a levy of forced labor, or volunteers?" % title
		"demand":prompt="%s demands that %s bear their mark and that the finest materials be reserved for the crown." % [who,title]
	r.decision={"key":key,"stage":stage_of(r),"day":day,"prompt":prompt}
	if key!="demand" and key not in r.gates:r.gates.append(key)
	if WorldSimulation.actor_id=="player":load("res://scripts/great_works.gd").notify_audience("decision",{"work_id":String(r.id),"key":key,"prompt":prompt,"day":day})
	record_event(r,day,"A decision is needed: "+key.replace("_"," "),"decision",[String(architect.id)] if not architect.is_empty() else [])

## Options for a record's pending decision; `enabled` reflects real stocks now.
static func decision_options(state:Node,r:Dictionary)->Array:
	var key:=String(r.get("decision",{}).get("key",""))
	var d:=Catalog.get_definition(String(r.id))
	var remaining:=maxf(0,total_work(r)-float(r.progress))
	var architect:Dictionary=r.get("architect",{})
	match key:
		"design":
			return [_option("grander","A grander design","+25% total work and materials; +35% allure when finished; the architect is pleased","ambitious"),
				_option("practical","A practical design","-15% total work; +5% workmanship; -20% allure","prudent")]
		"stores":
			var rations:=_pour_rations(state,r)
			var food_days:=_food_days(state)
			var enough:=food_days>=30.0 and rations>=1.0
			return [_option("pour","Pour the stores in","Spend %d stored rations to feed extra crews: about %d crew-days of work at once" % [roundi(rations),roundi(minf(rations*.5,minf(total_work(r)*.10,remaining)))],"costly",enough,"" if enough else "Less than a month of food is stored."),
				_option("protect","Protect the stores","No food is spent; a proud architect may chafe","prudent")]
		"labor":
			var wage:=_wage_cost(state,r)
			var can_pay:=_can_pay(state,wage)
			return [_option("paid","Pay the crews","Costs %s; +15%% pace; cohesion rises" % _wage_text(state,wage),"generous",can_pay,"" if can_pay else "Neither the treasury nor the stores can meet the wage."),
				_option("levy","Levy forced labor","+40% pace; 90 days of recorded hardship; cohesion and legitimacy fall","harsh"),
				_option("volunteers","Rely on volunteers","-15% pace; +10% allure; goodwill","gentle")]
		"demand":
			var honor_ok:=true
			for material:String in d.cost:
				if float(state.resource_stockpiles.get(material,0))<float(d.cost[material])*.10:honor_ok=false
			return [_option("honor","Honor %s's demand" % String(architect.get("name","the architect")),"Reserve 10% more materials now; +15% allure; their name joins the work","generous",honor_ok,"" if honor_ok else "The stockpiles cannot spare the finest materials."),
				_option("refuse","Refuse","No cost now; a proud architect (ego %d%%) may walk away" % roundi(float(architect.get("ego",0))*100),"firm")]
	return []
static func _option(id:String,label:String,sub:String,tone:String,enabled:bool=true,reason:String="")->Dictionary:
	return {"id":id,"label":label,"sub":sub,"tone":tone,"enabled":enabled,"reason":reason}

static func _food_days(state:Node)->float:
	var consumption:=maxf(.01,float(state.simulation_metrics.get("food_consumption",state.population_exact)))
	var total:=0.0
	for amount in state.food_stocks.values():total+=float(amount)
	return total/consumption
static func _pour_rations(state:Node,r:Dictionary)->float:
	var total:=0.0
	for amount in state.food_stocks.values():total+=float(amount)
	return minf(total*.25,minf(total_work(r)*.10,maxf(0,total_work(r)-float(r.progress)))*2.0)
static func _wage_cost(_state:Node,r:Dictionary)->float:
	return maxf(1,(total_work(r)-float(r.progress))*.02)
static func _can_pay(state:Node,wage:float)->bool:
	if String(state.economy_stage)=="currency" and float(state.public_treasury)>=wage:return true
	var total:=0.0
	for amount in state.food_stocks.values():total+=float(amount)
	return total>=wage*2
static func _wage_text(state:Node,wage:float)->String:
	return "%d coin from the treasury" % roundi(wage) if String(state.economy_stage)=="currency" and float(state.public_treasury)>=wage else "%d rations" % roundi(wage*2)

## Scoped-owner decision. Returns {ok,message} or {error}.
static func decide(city_id:String,work_id:String,option_id:String)->Dictionary:
	var city:=WorldSimulation.settlements.settlement_record(city_id)
	if city.is_empty() or not controlled(city):return {"error":"Choose a settlement you control."}
	var r:=find(city,work_id)
	if r.is_empty() or r.get("decision",{}).is_empty():return {"error":"No decision is pending for this work."}
	return WorldSimulation.settlements.with_city_resources(city_id,func()->Dictionary:
		var chosen:={}
		for option:Dictionary in decision_options(WorldSimulation.state,r):
			if option.id==option_id:chosen=option
		if chosen.is_empty():return {"error":"That choice is not offered."}
		if not bool(chosen.enabled):return {"error":String(chosen.reason)}
		return _apply_decision(WorldSimulation.state,r,city_id,option_id,int(WorldSimulation.state.elapsed_days),false))

## The choice an AI (or a player's council after long silence) makes.
static func auto_option(state:Node,r:Dictionary,ai:bool)->String:
	var options:=decision_options(state,r)
	var enabled:={}
	for option:Dictionary in options:
		if bool(option.enabled):enabled[option.id]=true
	var d:=Catalog.get_definition(String(r.id))
	# Rulers race only against what they have actually learned (rivalry news).
	var race:=rivalry_race(WorldSimulation.actor_id,String(r.id),fraction(r))
	var racing:=not race.is_empty() and not bool(race.get("claimed",false))
	match String(r.decision.get("key","")):
		"design":
			var ample:=true
			for material:String in d.cost:
				if float(state.resource_stockpiles.get(material,0))<float(d.cost[material])*.5:ample=false
			return "grander" if ai and ample and not racing else "practical"
		"stores":return "pour" if enabled.has("pour") and (_food_days(state)>=120 or (ai and racing and _food_days(state)>=60)) else "protect"
		"labor":
			if ai and racing and float(state.simulation_metrics.get("cohesion",.5))>=.55:return "levy"
			return "paid" if ai and enabled.has("paid") else "volunteers"
		"demand":return "honor" if enabled.has("honor") and ai else "refuse"
	return ""

static func _apply_decision(state:Node,r:Dictionary,city_id:String,option:String,day:int,council:bool)->Dictionary:
	var key:=String(r.decision.get("key",""))
	var d:=Catalog.get_definition(String(r.id))
	var architect:Dictionary=r.get("architect",{})
	var m:Dictionary=state.simulation_metrics
	var text:=""
	match option:
		"grander":
			r.work_scale=float(r.work_scale)*1.25;r.allure_scale=float(r.allure_scale)*1.35
			if not architect.is_empty():architect.mood=int(architect.mood)+1
			text="A grander design was chosen; the work grows by a quarter."
		"practical":
			r.work_scale=maxf(float(r.progress)/float(d.work)+.01,float(r.work_scale)*.85)
			r.allure_scale=float(r.allure_scale)*.8;r.quality_bonus=float(r.get("quality_bonus",0))+.05
			if not architect.is_empty() and float(architect.ego)>.6:architect.mood=int(architect.mood)-1
			text="A practical design was chosen; the work shrinks and steadies."
		"pour":
			var rations:=_pour_rations(state,r)
			var issued:float=WorldSimulation.food.issue_for_obligation(rations,"great_work","Crews for "+String(d.title))
			var gain:=_affordable_work(state,d,minf(issued*.5,maxf(0,total_work(r)-float(r.progress))))
			_spend(state,d,gain)
			r.progress+=gain;r.quality+=gain*.6
			text="%d rations fed extra crews; %d crew-days of work were done at once." % [roundi(issued),roundi(gain)]
		"protect":
			if not architect.is_empty() and float(architect.ego)>.6:architect.mood=int(architect.mood)-1
			text="The stores were protected."
		"paid":
			var wage:=_wage_cost(state,r)
			if String(state.economy_stage)=="currency" and float(state.public_treasury)>=wage:state.public_treasury-=wage
			else:WorldSimulation.food.issue_for_obligation(wage*2,"great_work","Wages for "+String(d.title))
			r.speed=float(r.speed)*1.15;m.cohesion=clampf(float(m.get("cohesion",.5))+.02,.01,.99)
			text="The crews are paid; the pace quickens."
		"levy":
			r.speed=float(r.speed)*1.4;r.strain=int(r.strain)+90
			m.cohesion=clampf(float(m.get("cohesion",.5))-.05,.01,.99);m.legitimacy=clampf(float(m.get("legitimacy",.5))-.03,.01,.99)
			text="Forced labor was levied; the work quickens and the hardship is recorded."
		"volunteers":
			r.speed=float(r.speed)*.85;r.allure_scale=float(r.allure_scale)*1.1;m.cohesion=clampf(float(m.get("cohesion",.5))+.01,.01,.99)
			text="Volunteers carry the load; slower, but freely given."
		"honor":
			for material:String in d.cost:state.resource_stockpiles[material]=float(state.resource_stockpiles.get(material,0))-float(d.cost[material])*.10
			r.allure_scale=float(r.allure_scale)*1.15
			if not architect.is_empty():
				architect.honored=true;architect.mood=int(architect.mood)+1
				if WorldSimulation.figures!=null and WorldSimulation.figures.has_method("note"):WorldSimulation.figures.note(String(architect.id),day,"Their demand for the finest materials was honored.",8)
			text="The architect's demand was honored."
		"refuse":
			if not architect.is_empty() and float(architect.ego)>.7:
				_replace_architect(r,city_id,day,"%s walked away from the work in anger." % String(architect.name))
				text="The demand was refused; the architect left and a successor took over."
			else:
				if not architect.is_empty():architect.mood=int(architect.mood)-1
				text="The demand was refused; the architect stays, resentful."
		_:return {"error":"Unknown choice."}
	if not r.has("decisions"):r.decisions=[]
	r.decisions.append({"key":key,"option":option,"day":day,"council":council})
	if r.decisions.size()>16:r.decisions.pop_front()
	r.erase("decision")
	record_event(r,day,("The council, hearing no word, decided: " if council else "Decided: ")+text,"decision",[String(architect.get("id",""))] if not architect.is_empty() else [])
	state.settlement_network_revision+=1
	return {"ok":true,"message":text}

static func _replace_architect(r:Dictionary,city_id:String,day:int,text:String)->void:
	var old:Dictionary=r.get("architect",{})
	_release_architect(r,day,text)
	r.quality=float(r.quality)*.97
	var fresh:=_commission_architect(city_id,String(r.id),day)
	if not fresh.is_empty() and fresh.id==old.get("id",""):fresh={}
	r.architect=fresh
	if not fresh.is_empty():record_event(r,day,"%s takes over as master builder" % String(fresh.name),"architect",[String(fresh.id)])

# --- Deterministic construction events ---------------------------------------
static func _roll_event(state:Node,r:Dictionary,city_id:String,day:int)->void:
	var h:=_roll("%s/%s/%d" % [city_id,String(r.id),day])
	# Crews settle in before anything notable happens.
	if h%1000>=EVENT_CHANCE_PER_MILLE or day-int(r.get("started",0))<30:return
	var stage:=stage_of(r)
	if not r.has("stage_events"):r.stage_events={}
	if int(r.stage_events.get(stage,0))>=MAX_STAGE_EVENTS:return
	var architect:Dictionary=r.architect
	var rivals:=sites_of(String(r.id)).size()>1
	var levy:=false
	for past:Dictionary in r.get("decisions",[]):
		if past.option=="levy":levy=true
	var weights:={"collapse":18,"accident":16,"strike":28 if levy else 14,"ingenious":18,"omen":16,"demand":12 if float(architect.ego)>.55 and not _had_demand(r) else 0,"poaching":6 if rivals else 0,"fire":6}
	var total:=0
	for w in weights.values():total+=int(w)
	var pick:=(h/1000)%total
	var kind:=""
	for k:String in EVENT_KINDS:
		pick-=int(weights[k])
		if pick<0:kind=k;break
	r.stage_events[stage]=int(r.stage_events.get(stage,0))+1
	var d:=Catalog.get_definition(String(r.id))
	var title:=String(d.title)
	var ids:Array=[String(architect.id)]
	match kind:
		"collapse":
			var lost:=minf(float(r.progress),total_work(r)*.03)
			var q:=float(r.quality)*lost/maxf(.001,float(r.progress))
			r.progress-=lost;r.quality=maxf(0,float(r.quality)-q)
			record_event(r,day,"A section of %s collapsed; %d crew-days of work were lost." % [title,roundi(lost)],"collapse",ids)
		"accident":
			var count:=1+(h/97)%3
			var victims:=_victim_names(h,count)
			if state.has_method("register_directive_population_deaths"):state.register_directive_population_deaths(victims.size(),"great_work_accident","%s died building %s." % [" and ".join(victims),title])
			r.strain=int(r.strain)+10
			record_event(r,day,"%s died when a hoist failed at %s." % [", ".join(victims),title],"accident",ids)
		"strike":
			r.halt_until=day+10
			record_event(r,day,"The crews of %s struck for ten days%s." % [title," against the levy" if levy else " over rations and danger"],"strike",ids)
		"ingenious":
			var gain:=_affordable_work(state,d,minf(total_work(r)*.02,maxf(0,total_work(r)-float(r.progress))))
			_spend(state,d,gain);r.progress+=gain;r.quality+=gain
			if WorldSimulation.figures!=null and WorldSimulation.figures.has_method("note"):WorldSimulation.figures.note(String(architect.id),day,"Devised an ingenious solution at %s." % title,3)
			record_event(r,day,"%s devised an ingenious lifting frame; %d crew-days were saved." % [String(architect.name),roundi(gain)],"ingenious",ids)
		"omen":
			var m:Dictionary=state.simulation_metrics
			if (h/13)%2==0:
				r.allure_scale=float(r.allure_scale)*1.05;m.cohesion=clampf(float(m.get("cohesion",.5))+.01,.01,.99)
				record_event(r,day,"A flight of white birds circled %s at dawn; people call it a blessing." % title,"omen",ids)
			else:
				m.cohesion=clampf(float(m.get("cohesion",.5))-.01,.01,.99)
				record_event(r,day,"A cracked keystone at %s is whispered to be an ill omen." % title,"omen",ids)
		"demand":
			if r.get("decision",{}).is_empty():_pose(r,"demand",day)
		"poaching":
			var rival:=_rival_owner(r)
			_replace_architect(r,city_id,day,"Lured away by %s to build their rival %s." % [owner_name(rival),title])
			record_event(r,day,"%s lured our master builder away." % owner_name(rival),"poaching",ids)
		"fire":
			var lost:=minf(float(r.progress),total_work(r)*.02)
			var q:=float(r.quality)*lost/maxf(.001,float(r.progress))
			r.progress-=lost;r.quality=maxf(0,float(r.quality)-q)
			record_event(r,day,"Scaffolds at %s burned at night; the cause was never found." % title,"fire",ids)

static func _had_demand(r:Dictionary)->bool:
	for past:Dictionary in r.get("decisions",[]):
		if past.key=="demand":return true
	return String(r.get("decision",{}).get("key",""))=="demand"
static func _rival_owner(r:Dictionary)->String:
	for site:Dictionary in sites_of(String(r.id)):
		if String(site.owner)!=WorldSimulation.actor_id:return String(site.owner)
	return "rivals"
static func _victim_names(h:int,count:int)->Array:
	var names:Array=[]
	var traditions:Array=NAMES.POOLS.keys()
	var used:={}
	for i in count:
		var identity:Dictionary=NAMES.make(_seed(),100000+h%100000+i*7,(h+i)%2==0,String(traditions[(h/7+i)%traditions.size()]),used)
		if identity.is_empty():continue
		used[identity.name]=true;names.append(String(identity.name))
	return names

# --- Dedication ---------------------------------------------------------------
static func _plan_ceremony(state:Node,r:Dictionary,_city:Dictionary,day:int)->void:
	var attendees:Array=[]
	var civs:Array=WorldSimulation.world.civilizations if WorldSimulation.world!=null else []
	for civ:Dictionary in civs:
		var relation:Dictionary=civ.get("player_relation",{})
		if bool(relation.get("at_war",false)):continue
		if int(relation.get("contact_level",0))<=0 and int(relation.get("met_day",-1))<0:continue
		var owner:=Exchange.recipient(String(civ.id))
		if owner==WorldSimulation.actor_id:continue
		var opinion:=float(relation.get("opinion",0))
		if opinion<-.25:continue
		attendees.append({"civ_id":owner,"name":String(civ.get("name",owner)),"opinion":opinion,"gift":_gift_plan(owner,opinion)})
	attendees.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.opinion)>float(b.opinion) or (float(a.opinion)==float(b.opinion) and String(a.civ_id)<String(b.civ_id)))
	if attendees.size()>4:attendees.resize(4)
	r.ceremony={"day":day,"status":"pending","attendees":attendees,"name_suggestions":_name_suggestions(state,r)}
	if WorldSimulation.actor_id=="player":load("res://scripts/great_works.gd").notify_audience("ceremony",{"work_id":String(r.id),"day":day,"attendees":attendees.duplicate(true)})

static func _gift_plan(owner:String,opinion:float)->Dictionary:
	# The human player's stores are never given away automatically; the player
	# gives gifts through diplomacy instead.
	var s:=owner_state(owner)
	if s==null or opinion<=0 or owner=="player":return {}
	var best:="";var stock:=0.0
	for resource:String in GIFT_RESOURCES:
		var amount:=float(s.resource_stockpiles.get(resource,0))
		if amount>stock:best=resource;stock=amount
	var gift:=floorf(minf(stock*.02*(.5+opinion),300))
	return {"resource":best,"amount":gift} if gift>=5 else {}

static func _name_suggestions(state:Node,r:Dictionary)->Array:
	var d:=Catalog.get_definition(String(r.id))
	var result:Array=[display_name(r)]
	var place:=String(state.settlement_name)
	if not place.is_empty():result.append(("%s of %s" % [String(d.title),place]).substr(0,60))
	var architect:Dictionary=r.get("architect",{})
	if bool(architect.get("honored",false)):result.append(("%s's %s" % [String(architect.name).get_slice(" ",0),String(d.title)]).substr(0,60))
	result.append(("The %s Wonder" % String(Catalog.ERA_TITLES.get(d.era,"First"))).substr(0,60))
	var unique:Array=[]
	for name in result:
		if name not in unique and valid_name(String(name)):unique.append(name)
	return unique

## Names the work, receives real gifts from attending civilizations' stores,
## writes the chronicle and marks the dedication for allure and reputation.
static func dedicate(city_id:String,work_id:String,title:String)->Dictionary:
	var city:=WorldSimulation.settlements.settlement_record(city_id)
	if city.is_empty() or not controlled(city):return {"error":"Choose a settlement you control."}
	var r:=find(city,work_id)
	if String(r.get("ceremony",{}).get("status",""))!="pending":return {"error":"No dedication is waiting for this work."}
	title=title.strip_edges()
	if not valid_name(title):return {"error":"Use a name of 1–60 characters on a single line."}
	return _dedicate_record(r,city,title,int(WorldSimulation.state.elapsed_days),false)

static func _dedicate_record(r:Dictionary,city:Dictionary,title:String,day:int,council:bool)->Dictionary:
	var owner:=WorldSimulation.actor_id
	var ceremony:Dictionary=r.ceremony
	var received:Array=[]
	var present:Array=[]
	for attendee:Dictionary in ceremony.get("attendees",[]):
		var civ:=String(attendee.civ_id)
		if civ!="player" and not WorldSimulation.actors.has(civ):continue
		present.append(String(attendee.name))
		var gift:Dictionary=attendee.get("gift",{})
		if not gift.is_empty():
			var taken:=Exchange.take(civ,String(gift.resource),float(gift.amount))
			var delivered:=Exchange.receive(owner,String(gift.resource),taken,String(city.id))
			attendee.delivered=delivered
			if delivered>0:received.append("%d %s from %s" % [roundi(delivered),String(gift.resource).to_lower(),String(attendee.name)])
		# Witnesses carry the account home: real reputation, not a flat bonus.
		if not r.has("heard_by"):r.heard_by={}
		r.heard_by[civ]={"day":day,"condition":float(r.condition),"strain":int(r.strain)}
		WorldSimulation.scoped(civ,func()->void:
			var ties:Dictionary=preload("res://scripts/society_exchange.gd").connection(owner)
			ties.respect=minf(1,float(ties.get("respect",0))+.04))
	if title!=String(Catalog.get_definition(String(r.id)).title):r.custom_name=title
	ceremony.status="dedicated";ceremony.dedicated_day=day;ceremony.council=council
	ceremony.allure=8.0+4.0*present.size()+(2.0 if not received.is_empty() else 0.0)
	r.dedicated_day=day
	var text:="%s was dedicated in %s%s.%s" % [title,String(city.get("name","the city")),(" before envoys of "+", ".join(present)) if not present.is_empty() else "",(" Gifts: "+"; ".join(received)+".") if not received.is_empty() else ""]
	record_event(r,day,text,"dedication",[String(r.get("architect",{}).get("id",""))] if not r.get("architect",{}).is_empty() else [])
	var state=WorldSimulation.state
	state.simulation_events.push_front({"day":day,"title":"GREAT WORK DEDICATED","description":text,"domain":"culture","severity":"major"})
	if state.simulation_events.size()>80:state.simulation_events.resize(80)
	var world=WorldSimulation.world
	if world!=null and "chronicle" in world and world.chronicle!=null and world.chronicle.has_method("_event"):world.chronicle._event(day,"Great Work",text)
	state.settlement_network_revision+=1
	return {"ok":true,"message":text,"gifts":received}

# --- Rival monuments ------------------------------------------------------------
## Turn an unfinished rival into a lesser working monument: allure, no claim.
static func repurpose(city_id:String,work_id:String)->Dictionary:
	var city:=WorldSimulation.settlements.settlement_record(city_id)
	if city.is_empty() or not controlled(city):return {"error":"Choose a settlement you control."}
	var r:=find(city,work_id)
	if r.get("status","")!="rival":return {"error":"Only an unfinished rival monument can be repurposed."}
	var day:=int(WorldSimulation.state.elapsed_days)
	r.status="functioning";r.lesser=true
	r.condition=clampf(float(r.quality)/maxf(.001,float(r.progress)),.3,1)
	r.legacy="Repurposed from an unfinished rival";r.reason="Maintained as a lesser monument."
	record_event(r,day,"Repurposed as a lesser monument","repurpose")
	WorldSimulation.state.settlement_network_revision+=1
	return {"ok":true,"message":"%s now serves as a lesser monument." % display_name(r)}

## Quarry an unfinished rival for 40% of the materials already built into it.
static func quarry(city_id:String,work_id:String)->Dictionary:
	var city:=WorldSimulation.settlements.settlement_record(city_id)
	if city.is_empty() or not controlled(city):return {"error":"Choose a settlement you control."}
	var r:=find(city,work_id)
	if r.get("status","") not in ["rival","abandoned"]:return {"error":"Only unfinished remains can be quarried."}
	var d:=Catalog.get_definition(work_id)
	var day:=int(WorldSimulation.state.elapsed_days)
	return WorldSimulation.settlements.with_city_resources(city_id,func()->Dictionary:
		var recovered:Array=[]
		for material:String in d.cost:
			var amount:=float(d.cost[material])*float(r.progress)/float(d.work)*.4
			WorldSimulation.state.resource_stockpiles[material]=float(WorldSimulation.state.resource_stockpiles.get(material,0))+amount
			recovered.append("%d %s" % [roundi(amount),material.to_lower()])
		r.status="quarried";r.progress=float(r.progress)*.2;r.quality=float(r.quality)*.2
		r.legacy="Quarried; only footings remain";r.reason="Stone and timber were carried away for other work."
		record_event(r,day,"Quarried: "+", ".join(recovered),"quarry")
		WorldSimulation.state.settlement_network_revision+=1
		return {"ok":true,"message":"Recovered "+", ".join(recovered)+"."})

# --- Validation and naming --------------------------------------------------------
static func valid(cities:Array)->bool:
	for city in cities:
		if not city is Dictionary or not city.get("undertakings",[]) is Array:return false
		var seen:Array=[]
		for r in city.get("undertakings",[]):
			if not r is Dictionary or not r.get("id","") is String:return false
			if Catalog.get_definition(r.id).is_empty() or r.id in seen:return false
			if r.has("custom_name") and (not r.custom_name is String or not valid_name(r.custom_name)):return false
			if r.has("site") and not Sites.valid(r.site):return false
			if r.has("last_work") and (not _number(r.last_work) or float(r.last_work)<0):return false
			if not r.get("events",[]) is Array or r.get("events",[]).size()>12:return false
			for event in r.get("events",[]):
				if not event is Dictionary or not event.get("day") is int or event.day<0 or not event.get("text") is String:return false
			seen.append(r.id)
			if r.get("status","") not in STATUSES or r.get("policy","") not in ["careful","press"]:return false
			for key:String in ["progress","quality","condition","strain","stalled_days","operating_days","last_day","started"]:
				if not _number(r.get(key)) or float(r[key])<0:return false
			for key:String in ["work_scale","speed","allure_scale"]:
				if r.has(key) and (not _number(r[key]) or float(r[key])<.2 or float(r[key])>4):return false
			if r.has("quality_bonus") and (not _number(r.quality_bonus) or absf(float(r.quality_bonus))>.5):return false
			if float(r.progress)>total_work(r)+.001 or float(r.quality)>float(r.progress)+.001 or float(r.condition)>1:return false
			if not r.get("reason") is String or not r.get("legacy") is String:return false
			if not _valid_extras(r):return false
		if not Rewards.valid(city):return false
	return true
static func _number(value:Variant)->bool:return (value is int or value is float) and is_finite(float(value))
static func _valid_extras(r:Dictionary)->bool:
	for key:String in ["claimed_day","dedicated_day","halt_until"]:
		if r.has(key) and (not r[key] is int or int(r[key])<-1):return false
	if r.has("lesser") and not r.lesser is bool:return false
	for key:String in ["gates","decisions","layers","enshrined"]:
		if r.has(key) and not r[key] is Array:return false
	for gate in r.get("gates",[]):
		if not gate is String or gate not in DECISION_KEYS:return false
	if r.get("decisions",[]).size()>16 or r.get("layers",[]).size()>8 or r.get("enshrined",[]).size()>8:return false
	for past in r.get("decisions",[]):
		if not past is Dictionary or not past.get("key") is String or not past.get("option") is String or not past.get("day") is int:return false
	for layer in r.get("layers",[]):
		if not layer is Dictionary or Catalog.get_definition(String(layer.get("id",""))).is_empty() or not layer.get("claimed_day",0) is int:return false
	for item in r.get("enshrined",[]):
		if not item is String or item.is_empty():return false
	for key:String in ["decision","ceremony","architect","stage_events","rival_of","archive"]:
		if r.has(key) and not r[key] is Dictionary:return false
	var decision:Dictionary=r.get("decision",{})
	if not decision.is_empty() and (String(decision.get("key","")) not in DECISION_KEYS or not decision.get("day") is int):return false
	var ceremony:Dictionary=r.get("ceremony",{})
	if not ceremony.is_empty():
		if String(ceremony.get("status","")) not in ["pending","dedicated"] or not ceremony.get("attendees",[]) is Array or ceremony.attendees.size()>8:return false
		for attendee in ceremony.attendees:
			if not attendee is Dictionary or not attendee.get("civ_id") is String or not attendee.get("gift",{}) is Dictionary:return false
			var gift:Dictionary=attendee.get("gift",{})
			if not gift.is_empty() and (not _number(gift.get("amount")) or float(gift.amount)<0 or float(gift.amount)>1000):return false
	var architect:Dictionary=r.get("architect",{})
	if not architect.is_empty():
		if not architect.get("id") is String or not architect.get("name") is String:return false
		for key:String in ["vision","ego","talent"]:
			if not _number(architect.get(key)) or float(architect[key])<0 or float(architect[key])>1.5:return false
	if r.has("covenant") and (not _number(r.covenant) or float(r.covenant)<0 or float(r.covenant)>100000):return false
	if not Effects.valid_archive(r.get("archive",{})):return false
	var rivalry:=rivalry_script()
	return rivalry==null or bool(rivalry.call("valid_rivalry",r))

static func rename(city_id:String,id:String,title:String)->Dictionary:
	var city:=WorldSimulation.settlements.settlement_record(city_id)
	if city.is_empty() or not controlled(city):return {"error":"Choose a settlement you control."}
	title=title.strip_edges()
	if not valid_name(title):return {"error":"Use a name of 1–60 characters on a single line."}
	for record:Dictionary in city.get("undertakings",[]):
		if record.id!=id:continue
		if float(record.progress)+.00001<total_work(record) and record.status!="rival":return {"error":"You can name this undertaking when construction finishes."}
		record.custom_name=title
		WorldSimulation.state.settlement_network_revision+=1
		return {"ok":true,"message":"Named "+title+"."}
	return {"error":"That undertaking is no longer recorded here."}
static func valid_name(title:String)->bool:
	if title.is_empty() or title.length()>60 or title!=title.strip_edges():return false
	for index in title.length():
		if title.unicode_at(index)<32 or title.unicode_at(index)==127:return false
	return true
