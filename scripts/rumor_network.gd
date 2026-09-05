extends RefCounted
## Bounded, observer-owned accounts. Copying an account never creates evidence.
const OBSERVERS:=64
const LEADS:=32
const PACKETS:=4
const HOPS:=8
const MAX_AGE:=3650
var system:Node
var books:Dictionary={}
var revision:=0
var last_day:=-1
var screen_layer:CanvasLayer
func _init(owner:Node)->void: system=owner
func point(p:Vector2)->Dictionary: return {"x":p.x,"z":p.y}
func vector(p:Dictionary)->Vector2: return Vector2(float(p.x),float(p.z))
func home(observer:String)->Vector2:
	if observer=="player": return system.player_world_origin
	var i:int=system._civilization_index(observer)
	return system._civilization_world_position(system.civilizations[i]) if i>=0 else Vector2.ZERO
func title(observer:String)->String:
	if observer=="player": return "your people"
	var i:int=system._civilization_index(observer)
	return String(system.civilizations[i].name) if i>=0 else "unidentified travelers"
func observation(observer:String,subject:String,name:String,position:Vector2,radius:float,day:int,source:String)->Dictionary:
	# One attributed root per observer, subject and year; repeated stories from
	# the same source do not masquerade as independent corroboration.
	return {"id":"%s:%s:%d" % [observer,subject,day/365],"subject":subject,"name":name,"center":point(position),"radius":maxf(40,radius),"confidence":.55,"observed_day":day,"reported_day":day,"origin":observer,"source":source,"heard_position":point(position),"via":title(observer),"path":[observer],"attempts":0,"searched":[]}
func receive(observer:String,lead:Dictionary,day:int)->bool:
	if not valid_lead(lead) or lead.subject==observer or day-int(lead.observed_day)>MAX_AGE: return false
	if observer in lead.path and not (lead.path.size()==1 and String(lead.origin)==observer): return false
	if not books.has(observer):
		if books.size()>=OBSERVERS: return false
		books[observer]={}
	var book:Dictionary=books[observer]
	if book.has(lead.id): return false
	var copy:=lead.duplicate(true)
	if observer not in copy.path:
		if copy.path.size()>=HOPS: return false
		copy.path.append(observer)
	copy.reported_day=day
	copy.attempts=0; copy.searched=[]
	if book.size()>=LEADS:
		var oldest:String=book.keys()[0]
		for key:String in book:
			if int(book[key].observed_day)<int(book[oldest].observed_day): oldest=key
		if int(copy.observed_day)<int(book[oldest].observed_day): return false
		book.erase(oldest)
	book[copy.id]=copy; revision+=1
	return true
func known(observer:String,id:String,day:int)->Dictionary:
	var saved:Dictionary=books.get(observer,{}).get(id,{})
	if saved.is_empty(): return {}
	var result:=saved.duplicate(true)
	var age:=maxi(0,day-int(saved.observed_day))
	result["age"]=age
	result.radius=minf(6000,float(saved.radius)+float(age)*.15)
	result.confidence=float(saved.confidence)/(1+float(age)/365.0)
	result["state"]="stale" if age>365 else "aging" if age>60 else "recent"
	result["conflicting"]=false
	for other:Dictionary in books.get(observer,{}).values():
		if other.subject==saved.subject and other.id!=saved.id and vector(other.center).distance_to(vector(saved.center))>float(other.radius)+float(saved.radius): result.conflicting=true
	return result
func list_leads(observer:String,day:int)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for id:String in books.get(observer,{}):
		var lead:=known(observer,id,day)
		if int(lead.age)<=MAX_AGE: result.append(lead)
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.confidence)>float(b.confidence) if a.confidence!=b.confidence else String(a.id)<String(b.id))
	return result
func packet(lead:Dictionary,sender:String)->Dictionary:
	var copy:=lead.duplicate(true)
	for key in ["resolved","age","state","conflicting"]: copy.erase(key)
	copy.confidence=float(copy.confidence)*.8
	copy.radius=minf(6000,float(copy.radius)+30)
	copy.via=title(sender)
	return copy
func prepare(mission:Dictionary,observer:String,day:int)->void:
	mission["rumor_outbox"]=[]; mission["rumor_inbox"]=[]; mission["rumor_visits"]=[]
	for lead:Dictionary in list_leads(observer,day).slice(0,PACKETS): mission.rumor_outbox.append(packet(lead,observer))
func exchange(mission:Dictionary,observer:String,host:String,position:Vector2,day:int)->void:
	if observer==host or host in mission.get("rumor_visits",[]): return
	if not mission.has("rumor_visits"): mission["rumor_visits"]=[]
	if mission.rumor_visits.size()>=8: return
	mission.rumor_visits.append(host)
	# The host learns of the visitors here, not the visitors' secret home.
	receive(host,observation(host,observer,title(observer),position,80,day,"visiting travelers seen locally"),day)
	for lead:Dictionary in mission.get("rumor_outbox",[]):
		var heard:=lead.duplicate(true); heard["heard_position"]=point(position)
		receive(host,heard,day)
	if not mission.has("rumor_inbox"): mission["rumor_inbox"]=[]
	var local:=observation(observer,host,title(host),position,40,day,"people met on the journey")
	if mission.rumor_inbox.size()<LEADS: mission.rumor_inbox.append(local)
	for lead:Dictionary in list_leads(host,day).slice(0,PACKETS):
		if observer in lead.path or lead.subject==observer: continue
		if mission.rumor_inbox.size()<LEADS:
			var carried:=packet(lead,host); carried["heard_position"]=point(position)
			mission.rumor_inbox.append(carried)
func deliver(mission:Dictionary,observer:String,day:int)->int:
	var count:=0
	for lead:Dictionary in mission.get("rumor_inbox",[]):
		if receive(observer,lead,day): count+=1
	mission.erase("rumor_inbox")
	return count
func sample(day:int)->void:
	if day==last_day: return
	last_day=day
	for observer:String in books:
		var book:Dictionary=books[observer]
		for id:String in book.keys():
			if day-int(book[id].observed_day)>MAX_AGE:
				book.erase(id); revision+=1
	# Only primary meeting places exchange capital-held accounts. We do not
	# pretend remote villages instantly possess a polity's latest reports.
	var hosts:Array[Dictionary]=[]
	for civ:Dictionary in system.civilizations:
		if bool(civ.get("alive",true)): hosts.append({"id":String(civ.id),"position":system._civilization_world_position(civ)})
	if GameState.settlement_site_committed: hosts.append({"id":"player","position":system.player_world_origin})
	for mission:Dictionary in system.scout_missions:
		var start:=int(mission.start_day); var end:=int(mission.get("actual_return_day",mission.return_day))
		if day<start or day>=end: continue
		var f:=float(day-start)/maxf(1,end-start)
		visit_at(mission,"player",system.city_intelligence.route_position(mission.route,f*2 if f<=.5 else (1-f)*2),hosts,day)
	for mission:Dictionary in system.foreign_formations:
		if mission.kind not in ["scout","expedition"] or day<int(mission.depart_day) or day<int(mission.get("disabled_until_day",0)) or bool(mission.get("rumor_waiting",false)): continue
		var observer:=String(mission.civ_id)
		if mission.kind=="expedition":
			var cycle:=floori(float(day-int(mission.depart_day))/(maxf(1,float(mission.leg_days))*2))
			if cycle>int(mission.get("rumor_cycle",0)):
				deliver(mission,observer,day); prepare(mission,observer,day); mission["rumor_cycle"]=cycle
		visit_at(mission,observer,system._foreign_formation_position(mission,day),hosts,day)
func visit_at(mission:Dictionary,observer:String,position:Vector2,hosts:Array[Dictionary],day:int)->void:
	for host:Dictionary in hosts:
		if host.id!=observer and position.distance_to(host.position)<=12: exchange(mission,observer,host.id,position,day)
func search_point(observer:String,lead:Dictionary,sequence:int,max_range:float)->Vector2:
	# Same deterministic area sampling for player and AI. No hidden city lookup.
	var center:=vector(lead.center)
	var angle:=fposmod(float(abs(String(lead.id).hash()+observer.hash()))*.000001+float(sequence)*2.39996323,TAU)
	var radius:=float(lead.radius)*sqrt(fposmod(float(sequence+1)*.61803398875,1.0))
	var target:Vector2=system._bounded_world_point(center+Vector2.from_angle(angle)*radius)
	var origin:=home(observer)
	if target.distance_to(origin)>max_range: target=origin+origin.direction_to(target)*max_range
	return target
func plan(observer:String,id:String,sequence:int,max_range:float,day:int)->Dictionary:
	var lead:=known(observer,id,day)
	if lead.is_empty() or int(lead.age)>MAX_AGE: return {"ok":false,"reason":"That lead is no longer available."}
	var target:=search_point(observer,lead,sequence,max_range)
	if target.distance_to(vector(lead.center))>float(lead.radius): return {"ok":false,"reason":"The reported region is beyond this expedition's reach. Choose a longer journey."}
	var route:Dictionary=system._plan_scout_land_route(home(observer),target)
	if not bool(route.get("ok",false)): return route
	if float(route.get("distance_km",INF))>max_range: return {"ok":false,"reason":"The land route to this search corridor exceeds the expedition's range."}
	route["search_position"]=point(target); route["lead"]=lead
	return route
func finish_search(mission:Dictionary,observer:String,day:int,found:bool)->String:
	var id:=String(mission.get("rumor_lead_id",""))
	var book:Dictionary=books.get(observer,{})
	if not book.has(id): return "The original lead is no longer retained. Only the party's actual observations are recorded."
	var lead:Dictionary=book[id]
	lead.attempts=int(lead.attempts)+1
	lead["resolved"]=found
	var searched:Array=lead.searched
	searched.append({"day":day,"position":mission.get("target_position",lead.center).duplicate(true),"found":found})
	if searched.size()>4: searched.pop_front()
	if not found: lead.confidence=maxf(.03,float(lead.confidence)*.8)
	revision+=1
	return "The search returned a physical observation of the reported people. See the dated city report." if found else "No confirming city observation returned from this corridor. Other parts of the reported region remain unsearched; the lead is less reliable."
func describe(lead:Dictionary)->String:
	var direction:String=system._compass_phrase(system.player_world_origin,vector(lead.center))
	var confidence:="moderate" if float(lead.confidence)>=.35 else "weak" if float(lead.confidence)>=.15 else "faint"
	return "%s · %s · %s confidence · area about %.0f km across\nHeard via %s; observation day %d, received day %d. %d returned search(es).%s" % [direction.capitalize(),String(lead.state),confidence,float(lead.radius)*2,String(lead.via),int(lead.observed_day),int(lead.reported_day),int(lead.attempts)," Accounts point to different areas." if bool(lead.conflicting) else ""]
func valid_lead(value:Variant)->bool:
	if not value is Dictionary or not value.has_all(["id","subject","name","center","radius","confidence","observed_day","reported_day","origin","source","via","path","attempts","searched"]): return false
	for key:String in ["id","subject","name","origin","source","via"]:
		if not value[key] is String or value[key].length()>200: return false
	if not system.city_intelligence.valid_point(value.center): return false
	if not value.get("heard_position",{}) is Dictionary: return false
	if not value.get("heard_position",{}).is_empty() and not system.city_intelligence.valid_point(value.heard_position): return false
	for key:String in ["radius","confidence","observed_day","reported_day","attempts"]:
		if not system.city_intelligence.number(value[key]): return false
	if value.radius<40 or value.radius>6000 or value.confidence<0 or value.confidence>1 or value.observed_day<0 or value.reported_day<value.observed_day or value.attempts<0: return false
	if not value.path is Array or value.path.size()>HOPS or not value.searched is Array or value.searched.size()>4: return false
	if value.path.is_empty() or value.path[0]!=value.origin: return false
	if value.has("resolved") and not value.resolved is bool: return false
	var unique:Dictionary={}
	for entry in value.path:
		if not entry is String or entry.length()>80 or unique.has(entry): return false
		unique[entry]=true
	for area in value.searched:
		if not area is Dictionary or not system.city_intelligence.valid_point(area.get("position")) or not system.city_intelligence.number(area.get("day")) or not area.get("found") is bool: return false
	return true
func validate(value:Variant)->bool:
	if not value is Dictionary or value.size()>OBSERVERS: return false
	for observer in value:
		if not observer is String or observer.length()>80 or not value[observer] is Dictionary or value[observer].size()>LEADS: return false
		for id in value[observer]:
			if not valid_lead(value[observer][id]) or id!=value[observer][id].id: return false
	return true
func valid_carried(mission:Dictionary)->bool:
	for key:String in ["rumor_inbox","rumor_outbox"]:
		var values:Variant=mission.get(key,[])
		if not values is Array or values.size()>(LEADS if key=="rumor_inbox" else PACKETS): return false
		for lead in values:
			if not valid_lead(lead): return false
	var visits:Variant=mission.get("rumor_visits",[])
	if not visits is Array or visits.size()>8: return false
	for host in visits:
		if not host is String or host.length()>80: return false
	return true

func record_cities(observer:String,reports:Array,day:int)->void:
	for city:Dictionary in reports:
		if String(city.get("civ_id",""))=="" or int(city.get("observed_day",-1))<0: continue
		var lead:=observation(observer,String(city.civ_id),title(String(city.civ_id)),vector(city.position),60,int(city.observed_day),"returned settlement observation")
		lead["resolved"]=true
		lead.heard_position={} # A city report does not record where its author heard a story.
		receive(observer,lead,day)
func ai_plan(formation:Dictionary,civ:Dictionary,day:int)->bool:
	var observer:=String(civ.id)
	var leads:=list_leads(observer,day).filter(func(lead:Dictionary)->bool: return not bool(lead.get("resolved",false)))
	leads.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.confidence)/(1+int(a.attempts))>float(b.confidence)/(1+int(b.attempts)))
	if leads.is_empty(): return false
	# Reuse the existing one-party record and military personnel; no new people.
	var personnel:=clampi(roundi(float(civ.population)*.012),6,80)
	var available:=float(civ.get("food_days",0))*float(civ.population)
	var maximum:float=minf(system._foreign_scout_operational_range(civ),system._foreign_scout_speed_km_per_day(civ)*365*.5)
	for lead:Dictionary in leads.slice(0,PACKETS):
		if float(civ.military_population)<personnel or float(civ.population)<personnel+12: break
		var route:=plan(observer,lead.id,int(formation.search_sequence),maximum,day)
		if not bool(route.get("ok",false)): continue
		var duration:=maxi(30,ceili(float(route.distance_km)*2/system._foreign_scout_speed_km_per_day(civ)))
		var provisions:=float(personnel)*duration*.55
		if duration>365 or available<provisions: continue
		civ.food_days=maxf(0,float(civ.food_days)-provisions/maxf(1,float(civ.population)))
		formation["route"]=route.route.duplicate(true)
		formation.point_b=vector(route.search_position); formation.leg_days=float(duration)*.5
		formation["rumor_lead_id"]=lead.id; formation["target_position"]=route.search_position
		formation["rumor_subject"]=lead.subject; formation["rumor_provisions"]=provisions
		formation["rumor_personnel"]=personnel; formation.strength_share=float(personnel)/maxf(1,float(civ.military_population))
		return true
	# A named investigation cannot bypass missing land knowledge or provisions.
	formation["rumor_waiting"]=true; formation.point_b=formation.point_a; formation.leg_days=15.0
	return true

func open_map(terrain:Node)->void:
	if is_instance_valid(screen_layer): screen_layer.queue_free()
	screen_layer=CanvasLayer.new(); screen_layer.layer=87; system.add_child(screen_layer)
	var panel=preload("res://scripts/hud/rumor_map.gd").new()
	panel.terrain=terrain; screen_layer.add_child(panel)
