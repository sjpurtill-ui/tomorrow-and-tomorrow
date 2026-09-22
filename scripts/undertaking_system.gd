extends RefCounted
const Catalog=preload("res://scripts/undertaking_catalog.gd")
const Rewards=preload("res://scripts/undertaking_rewards.gd")
static func current_city(state:Node)->Dictionary:
	for city:Dictionary in state.player_settlements:
		if String(city.id)==String(state.resource_settlement_id) or (state.resource_settlement_id.is_empty() and bool(city.get("primary",false))):return city
	return {}
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
		if r.status=="functioning" and d.get("role","")==role:bonus+=float(d.bonus)*float(r.condition)
	if role=="Crafting":bonus+=Rewards.local_bonus(state,"craft")
	if role=="Knowledge":bonus+=Rewards.local_bonus(state,"research")
	return minf(.30,bonus)
static func possibilities(city:Dictionary)->Array:
	var result:Array=[]
	var state=WorldSimulation.state
	if city.is_empty() or int(state.elapsed_days)>365*300:return result
	var profile:=PlanetEnvironment.profile_at(city.get("position",Vector2.ZERO))
	for d:Dictionary in Catalog.all():
		# Stable opportunity selection; no reroll when opening the screen or loading.
		if posmod(hash("%d/%s/%s" % [state.world_seed,city.id,d.id]),100)>=45:continue
		if state.population_total<int(d.population):continue
		if not String(d.discovery).is_empty() and d.discovery not in state.known_discoveries:continue
		var rain:=float(profile.get("precipitation",.5))
		if d.environment=="dry" and rain>.45:continue
		if d.environment=="wet" and rain<.5:continue
		if d.environment=="woodland" and String(profile.get("biome",""))!="woodland":continue
		var exists:=false
		for r:Dictionary in city.get("undertakings",[]):
			if r.id==d.id:exists=true
		if not exists:result.append(d)
	return result
static func start(city_id:String,id:String,site_height:Callable=Callable(),site_land:Callable=Callable())->Dictionary:
	var city:=WorldSimulation.settlements.settlement_record(city_id)
	if city.is_empty() or String(city.get("occupied_by","")) not in ["","player"]:return {"error":"No controlled settlement selected."}
	return WorldSimulation.settlements.with_city_resources(city_id,func()->Dictionary:
		return WorldSimulation.settlements.with_local_population(func()->Dictionary:
			for r:Dictionary in city.get("undertakings",[]):
				if r.status in ["building","stalled"]:return {"error":"This settlement already supports an undertaking."}
			var eligible:=false
			for d:Dictionary in possibilities(city):
				if d.id==id:eligible=true
			if not eligible:return {"error":"This opportunity is not available here."}
			var height:Callable=site_height if site_height.is_valid() else PlanetEnvironment.world_height_at
			var land:Callable=site_land if site_land.is_valid() else PlanetEnvironment.is_land
			var site:=preload("res://scripts/undertaking_sites.gd").choose(city,WorldSimulation.state.settlement_plots,WorldSimulation.state.world_seed,height,land)
			if site.is_empty():return {"error":"No clear, gentle land is available near this settlement for a landmark."}
			if not city.has("undertakings"):city.undertakings=[]
			city.undertakings.append({"id":id,"status":"building","policy":"careful","progress":0.0,"quality":0.0,"condition":1.0,"strain":0,"stalled_days":0,"operating_days":0,"last_day":int(WorldSimulation.state.elapsed_days),"started":int(WorldSimulation.state.elapsed_days),"reason":"Foundations authorized; staff organize the work.","legacy":"An ambition, not yet an achievement"})
			city.undertakings[-1].site=site
			record_event(city.undertakings[-1],int(WorldSimulation.state.elapsed_days),"Foundations authorized")
			WorldSimulation.state.settlement_network_revision+=1
			return {"ok":true,"message":"A clear site is reserved. Local crews will begin the undertaking."}))
static func direct(city_id:String,id:String,order:String)->void:
	var city:=WorldSimulation.settlements.settlement_record(city_id)
	if String(city.get("occupied_by","")) not in ["","player"]:return
	for r:Dictionary in city.get("undertakings",[]):
		if r.id!=id or r.status not in ["building","stalled"]:continue
		if order=="abandon":
			r.status="abandoned";r.reason="Support withdrawn; unfinished remains endure.";r.legacy="An unfinished promise"
			record_event(r,int(WorldSimulation.state.elapsed_days),"Support withdrawn")
		elif order in ["careful","press"]:r.policy=order
	WorldSimulation.state.settlement_network_revision+=1
static func advance_all(day:int)->void:
	for city:Dictionary in WorldSimulation.state.player_settlements:
		if String(city.get("occupied_by","")) not in ["","player"]:continue
		if city.get("undertakings",[]).is_empty():continue
		WorldSimulation.settlements.with_city_resources(String(city.id),func()->void:
			WorldSimulation.settlements.with_local_population(func()->void:
				for r:Dictionary in city.undertakings:advance_record(WorldSimulation.state,r,day)))
	Rewards.record_victory(WorldSimulation.state,day)
static func advance_record(state:Node,r:Dictionary,day:int)->void:
	if day<=int(r.last_day):return
	# The calendar calls once per day. Loading never awards skipped work.
	r.last_day=day
	r.last_work=0.0
	var d:=Catalog.get_definition(String(r.id))
	var m:Dictionary=state.simulation_metrics
	var need:=minf(float(m.get("food_intake_ratio",1)),float(state.water_metrics.get("intake_ratio",1)))
	if r.status in ["abandoned","ruined"]:return
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
			record_event(r,day,"Lost to neglect")
		elif int(r.operating_days)>=3650:r.legacy="Enduring achievement" if int(r.strain)<180 else "Enduring, but remembered for its human cost"
		return
	var allocated:=float(state.population_allocations.get("Construction",0))
	var remaining:float=state.effective_workers("Construction")
	var fraction:=.50 if r.policy=="press" else .20
	var labor:float=remaining/maxf(.01,1-share(state))*fraction if allocated>0 else 0.0
	var leader:Dictionary=WorldSimulation.government.person_snapshot(int(current_city(state).get("leader_person_id",0)))
	var competence:=float((leader.get("skills",{}) as Dictionary).get("Construction",50.0))/100.0
	var quality:=clampf(float(m.get("labor_efficiency",.72))*.4+float(m.get("cohesion",.5))*.2+minf(1,state.effective_workers("Crafting")/8)*.2+competence*.2,.1,1)
	var work:=minf(labor*quality,float(d.work)-float(r.progress))
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
	for material:String in d.cost:state.resource_stockpiles[material]-=float(d.cost[material])*work/float(d.work)
	r.quality+=work*quality;r.progress+=work
	r.last_work=work
	if float(r.progress)+.00001>=float(d.work):
		r.condition=clampf(float(r.quality)/float(d.work),.1,1)
		r.status="functioning" if r.condition>=.5 else "ruined"
		r.legacy="Useful, not yet renowned" if r.status=="functioning" else "An embarrassing failure: the finished work could not serve its purpose"
		if r.status=="functioning" and int(r.strain)>=180:r.legacy="An achievement built through hardship"
		record_event(r,day,"Completed and functioning" if r.status=="functioning" else "Completed, but failed to function")
		state.settlement_network_revision+=1
static func valid(cities:Array)->bool:
	for city in cities:
		if not city is Dictionary or not city.get("undertakings",[]) is Array:return false
		var seen:Array=[]
		for r in city.get("undertakings",[]):
			if not r is Dictionary or not r.get("id","") is String:return false
			if Catalog.get_definition(r.id).is_empty() or r.id in seen:return false
			if r.has("custom_name") and (not r.custom_name is String or not valid_name(r.custom_name)):return false
			if r.has("site") and not preload("res://scripts/undertaking_sites.gd").valid(r.site):return false
			if r.has("last_work") and (not (r.last_work is float or r.last_work is int) or not is_finite(float(r.last_work)) or float(r.last_work)<0):return false
			if not r.get("events",[]) is Array or r.get("events",[]).size()>12:return false
			for event in r.get("events",[]):
				if not event is Dictionary or not event.get("day") is int or event.day<0 or not event.get("text") is String:return false
			seen.append(r.id)
			var definition:=Catalog.get_definition(r.id)
			if r.get("status","") not in ["building","stalled","functioning","abandoned","ruined"] or r.get("policy","") not in ["careful","press"]:return false
			for key:String in ["progress","quality","condition","strain","stalled_days","operating_days","last_day","started"]:
				if not (r.get(key) is float or r.get(key) is int) or not is_finite(float(r[key])) or float(r[key])<0:return false
			if float(r.progress)>float(definition.work)+.001 or float(r.quality)>float(r.progress)+.001 or float(r.condition)>1:return false
			if not r.get("reason") is String or not r.get("legacy") is String:return false
		if not Rewards.valid(city):return false
	return true



static func display_name(record:Dictionary)->String:
	return String(record.get("custom_name",Catalog.get_definition(String(record.id)).get("title","Undertaking")))

static func record_event(record:Dictionary,day:int,message:String)->void:
	if not record.has("events"):record.events=[]
	record.events.push_front({"day":day,"text":message})
	if record.events.size()>12:record.events.resize(12)
static func rename(city_id:String,id:String,title:String)->Dictionary:
	var city:=WorldSimulation.settlements.settlement_record(city_id)
	if city.is_empty() or String(city.get("occupied_by","")) not in ["","player"]:return {"error":"Choose a settlement you control."}
	title=title.strip_edges()
	if not valid_name(title):return {"error":"Use a name of 1–60 characters on a single line."}
	for record:Dictionary in city.get("undertakings",[]):
		if record.id!=id:continue
		if float(record.progress)+.00001<float(Catalog.get_definition(id).work):return {"error":"You can name this undertaking when construction finishes."}
		record.custom_name=title
		WorldSimulation.state.settlement_network_revision+=1
		return {"ok":true,"message":"Named "+title+"."}
	return {"error":"That undertaking is no longer recorded here."}
static func valid_name(title:String)->bool:
	if title.is_empty() or title.length()>60 or title!=title.strip_edges():return false
	for index in title.length():
		if title.unicode_at(index)<32 or title.unicode_at(index)==127:return false
	return true
