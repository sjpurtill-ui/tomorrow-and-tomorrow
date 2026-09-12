extends RefCounted
## Shared rules for physical encounters, finite household migration and learning.
## All records belong to GameState and therefore to the current civilization.
const PERSONALITY=preload("res://scripts/leader_personality.gd")
const COLLECTION_LIMIT:=32768 # Multiple acquisition records across the 5,000-discovery history.
const CONTACT_LIMIT:=1024
const CONTACT_RADIUS:=2.0
const OBJECTS:={"clay_shaping":["Clay trial vessel","Clay"],"pit_firing":["Fired clay trial piece","Clay"],"cordage":["Braided cord sample","Fiber Plants"],"basketry":["Woven container sample","Fiber Plants"],"stone_sorting":["Selected cutting stone","Stone"],"joinery":["Fitted timber joint","Timber"],"tallies":["Marked counting stick","Timber"]}
const CULTURE:=["oral_epics","festival_calendar","public_theatre","civic_games","comparative_chronicles","public_libraries","customary_law"]

static func empty_state()->Dictionary:
	return {"collections":{},"evidence":{},"origins":{},"integration":[],"connections":{},"outbound":{},"last_day":-1,"exposure":0.0,"migration_policy":"balanced","sharing_policy":"selective","history":[]}

static func data()->Dictionary:return WorldSimulation.state.society_exchange
static func owner_id(id:String)->String:return "player" if id=="human" else id
static func owner_state(id:String)->Node:
	id=owner_id(id)
	if id=="player":return GameState
	return WorldSimulation.actors.get(id,{}).get("systems",{}).get("GameState")
static func number(value:Variant)->bool:return (value is int or value is float) and is_finite(float(value))
static func valid(value:Variant)->bool:
	if not value is Dictionary:return false
	if value.is_empty():return false
	if not preload("res://scripts/scholar_visits.gd").valid(value.get("scholar_visits",{})):return false
	if not value.has_all(empty_state().keys()):return false
	if not preload("res://scripts/research_licenses.gd").valid(value.get("production_licenses",{})):return false
	for key:String in ["collections","evidence","origins","connections","outbound"]:
		if not value[key] is Dictionary or value[key].size()>(CONTACT_LIMIT if key in ["connections","outbound"] else COLLECTION_LIMIT):return false
	if value.migration_policy not in ["balanced","welcome","consolidate"] or value.sharing_policy not in ["open","selective","guarded"]:return false
	if not number(value.last_day) or not number(value.exposure) or value.exposure<0 or value.exposure>1:return false
	if not value.integration is Array or value.integration.size()>128 or not value.history is Array or value.history.size()>64:return false
	for group:Variant in value.integration:
		if not group is Dictionary or not group.has_all(["origin","count","remaining"]) or not group.origin is String:return false
		if not number(group.count) or not number(group.remaining) or group.count<0 or group.remaining<0 or group.remaining>group.count:return false
	for key:Variant in value.collections:
		if not valid_item(value.collections[key]) or key!=value.collections[key].id:return false
	for subject:Variant in value.evidence:
		var key:Variant=value.evidence[subject]
		if not subject is String or not key is String or not value.collections.has(key):return false
		if value.collections[key].discovery_id!=subject or value.collections[key].study!=1 or value.collections[key].get("partnership_protocol",false):return false
	for origin:Variant in value.origins.values():
		if not origin is Dictionary or not origin.has_all(["route","label","requires","collection_id","day"]):return false
		if not short_text(origin.route) or String(origin.route).is_empty() or not short_text(origin.label) or not short_text(origin.collection_id) or not number(origin.day) or origin.day<0 or not text_list(origin.requires,20):return false
	for ties:Variant in value.connections.values():
		if not ties is Dictionary or not ties.has_all(["last_visit","learned","shared","arrivals","departures","familiarity","respect","resentment"]):return false
		if not text_list(ties.learned,COLLECTION_LIMIT) or not text_list(ties.shared,COLLECTION_LIMIT):return false
		for field:String in ["last_visit","arrivals","departures","familiarity","respect","resentment"]:
			if not number(ties[field]) or ties[field]<(-1 if field=="last_visit" else 0):return false
		for field:String in ["familiarity","respect","resentment"]:
			if ties[field]>1:return false
		if ties.has("recruitment_truce_until") and (not number(ties.recruitment_truce_until) or ties.recruitment_truce_until<0):return false
		var agreement:Variant=ties.get("received_cooperation",{})
		if not agreement is Dictionary:return false
		if not agreement.is_empty():
			if agreement.get("kind") not in ["exchange","routes","restraint"] or agreement.get("domain") not in ["knowledge","logistics","culture"] or agreement.get("bonus") not in [.08,.12] or not number(agreement.get("until")) or agreement.until<0:return false
	for event:Variant in value.history:
		if not event is Dictionary or not short_text(event.get("text"),1000) or not number(event.get("day")):return false
	for intent:Variant in value.outbound.values():
		if not intent is Dictionary or not intent.has_all(["count","until","destination"]) or not number(intent.count) or intent.count<0 or not number(intent.until) or not short_text(intent.destination) or intent.count>1000000000000:return false
	return true

static func short_text(value:Variant,limit:int=240)->bool:return value is String and value.length()<=limit
static func text_list(value:Variant,limit:int)->bool:
	if not value is Array or value.size()>limit:return false
	for element:Variant in value:
		if not short_text(element):return false
	return true
static func valid_item(item:Variant)->bool:
	if not item is Dictionary or not item.has_all(["id","kind","name","source_id","source_name","position","observed_day","returned_day","discovery_id","study","work","signals"]):return false
	if item.kind not in ["artifact","knowledge","culture","specimen"]:return false
	if item.has("reverse_engineered"):
		if not item.reverse_engineered is bool or item.kind!="artifact":return false
		if item.reverse_engineered:
			if item.get("work")!=180.0 or item.get("id")!="reverse:"+String(item.get("discovery_id","")):return false
			var recipe:Dictionary=preload("res://scripts/research_specimens.gd").definition(String(item.get("specimen_item","")))
			if recipe.is_empty() or recipe.gate!=item.discovery_id:return false
			if item.get("research_purchase",false) or item.get("research_partnership",false) or item.get("partnership_protocol",false):return false
	if item.has("research_purchase") and (not item.research_purchase is bool or item.kind!="knowledge"):return false
	for flag:String in ["partnership_protocol","research_partnership"]:
		if item.has(flag) and (not item[flag] is bool or item.kind!="knowledge"):return false
	if item.get("partnership_protocol",false) and item.get("research_partnership",false):return false
	if item.get("partnership_protocol",false) or item.get("research_partnership",false):
		var protocol:bool=item.get("partnership_protocol",false)
		if item.get("work")!=(180.0 if protocol else 60.0) or item.get("research_purchase",false):return false
		if item.get("id")!=("partnership_protocol:" if protocol else "partnership_result:")+String(item.get("source_id",""))+":"+String(item.get("discovery_id","")):return false
	for field:String in ["id","name","source_id","source_name","discovery_id"]:
		if not short_text(item[field]):return false
	for field:String in ["observed_day","returned_day","study","work"]:
		if not number(item[field]) or item[field]<0:return false
	return item.study<=1 and item.work>=1 and item.work<=100000 and item.position is Dictionary and number(item.position.get("x")) and number(item.position.get("z")) and text_list(item.signals,30)
static func valid_mission(mission:Dictionary)->bool:
	if (mission.has("research_mode") or mission.has("scholar_contract") or mission.has("scholar_provisions")) and not mission.has("research_subject"):return false
	if mission.has("scholar_contract") and mission.get("research_mode","")!="scholar":return false
	if mission.has("scholar_provisions") and mission.get("research_mode","")!="scholar":return false
	if mission.get("research_mode","purchase") not in ["purchase","scholar","partnership","materials","license"]:return false
	for field:String in ["license_authorized","license_delivered"]:
		if mission.has(field) and mission.get("research_mode","")!="license":return false
	if mission.get("research_mode","")=="license" and not preload("res://scripts/research_licenses.gd").valid_mission(mission):return false
	var materials:bool=mission.get("research_mode","")=="materials"
	for field:String in ["materials_requested","material_cargo","materials_delivered"]:
		if mission.has(field) and not materials:return false
	if materials and not preload("res://scripts/research_materials.gd").valid(mission):return false
	if mission.has("partnership_phase") and (mission.get("research_mode","")!="partnership" or mission.partnership_phase not in ["propose","exchange"]):return false
	if mission.get("research_mode","")=="partnership" and (not mission.has("research_subject") or not mission.has("partnership_phase")):return false
	if mission.has("scholar_provisions") and (not number(mission.scholar_provisions) or mission.scholar_provisions<0):return false
	if mission.has("scholar_contract"):
		if not mission.scholar_contract is Dictionary or not preload("res://scripts/scholar_visits.gd").valid({mission.scholar_contract.get("id",""):mission.scholar_contract}):return false
	if not mission.has("research_subject") and (mission.has("research_refused") or mission.has("research_refunded")):return false
	if mission.has("research_subject"):
		if not short_text(mission.research_subject) or String(mission.research_subject).is_empty():return false
		for flag:String in ["research_refused","research_refunded"]:
			if mission.has(flag) and not mission[flag] is bool:return false
	var items:Variant=mission.get("carried_collections",[])
	if not items is Array or items.size()>256:return false
	for item:Variant in items:
		if not valid_item(item):return false
	if not text_list(mission.get("encountered_societies",[]),64):return false
	for flag:String in ["migration_resolved","exchange_returned"]:
		if mission.has(flag) and not mission[flag] is bool:return false
	if not number(mission.get("contact_exposure",0)) or mission.get("contact_exposure",0)<0 or mission.get("contact_exposure",0)>1:return false
	var shared:Variant=mission.get("shared_practices",[])
	if not shared is Array or shared.size()>64:return false
	for practice:Variant in shared:
		if not practice is Dictionary:return false
		for field:String in ["recipient","discovery_id","name"]:
			if not short_text(practice.get(field)):return false
	var reservation:Variant=mission.get("migrant_reservation",{})
	if not reservation is Dictionary:return false
	if not reservation.is_empty():
		for field:String in ["source","source_name","key"]:
			if not short_text(reservation.get(field)):return false
		for field:String in ["count","provisions","departed_day"]:
			if not number(reservation.get(field)) or reservation[field]<0:return false
		if reservation.count>1000000000000:return false
	return true

static func policy(migration:String,sharing:String)->Dictionary:
	if migration not in ["balanced","welcome","consolidate"] or sharing not in ["open","selective","guarded"]:return {"error":"Choose a supported reception and knowledge-sharing policy."}
	data().migration_policy=migration;data().sharing_policy=sharing
	return {"ok":true}

static func outbound_count()->int:
	var total:=0
	for value:Dictionary in data().outbound.values():total+=int(value.count)
	return total

static func pressure()->Dictionary:
	var unsettled:=0.0
	for group:Dictionary in data().integration:unsettled+=float(group.remaining)
	var population:=maxf(1,WorldSimulation.state.population_exact)
	var share:=clampf(unsettled/population,0,1)
	var housing:=clampf(float(WorldSimulation.state.housing_capacity)/population,0,1)
	var food:=clampf(float(WorldSimulation.state.simulation_metrics.get("food_intake_ratio",1)),0,1)
	var admin:=WorldSimulation.state.effective_workers("Administration")
	var burden:=maxf(0,unsettled-admin*8)/population
	return {"unsettled":unsettled,"unsettled_share":share,"administrative_load":burden*.25,"cohesion_cost":share*(.015+(1-housing)*.12+(1-food)*.15)+burden*.04,"health_cost":float(data().exposure)*(.02+(1-housing)*.08),"labor_cost":share*.08}

static func reception_snapshot()->Dictionary:
	var state:=WorldSimulation.state
	var population:=maxf(1,state.population_exact)
	var beds:=maxi(0,state.housing_capacity-ceili(population))
	var water:=float(state.water_metrics.get("intake_ratio",1))
	var food_days:=float(state.simulation_metrics.get("food_days",0))
	var administrative_room:=maxf(0,state.effective_workers("Administration")*12-float(pressure().unsettled))
	if data().migration_policy=="welcome":administrative_room*=1.5
	var inbound:=0
	for mission:Dictionary in WorldSimulation.world.scout_missions:
		if not bool(mission.get("migration_resolved",false)):inbound+=int(mission.get("migrant_reservation",{}).get("count",0))
	var room:=maxi(0,mini(beds,floori(administrative_room))-inbound)
	var reasons:Array[String]=[]
	if not state.settlement_site_committed:reasons.append("Found the settlement first.")
	if data().migration_policy=="consolidate":reasons.append("Reception policy is Consolidate; invitations are paused.")
	if beds-inbound<2:reasons.append("Housing: %d spare places after promised arrivals; at least 2 needed." % maxi(0,beds-inbound))
	if food_days<14:reasons.append("Food: %.1f days stored; 14 days needed before inviting households." % food_days)
	if water<.98:reasons.append("Water: %d%% of daily need supplied; 98%% needed." % roundi(water*100))
	if administrative_room-inbound<2:reasons.append("Reception staff can support %d more people; at least 2 needed. Administration helps households settle." % maxi(0,floori(administrative_room)-inbound))
	if not reasons.is_empty():room=0
	return {"capacity":room,"reasons":reasons,"message":"Room to invite up to %d people. Households decide whether to join." % room if room>=2 else "\n".join(reasons)}

static func reception_capacity()->int:
	return int(reception_snapshot().capacity)

static func attraction()->float:
	var s:=WorldSimulation.state;var m:=s.simulation_metrics
	return clampf(s.food_security*.3+minf(1,float(s.housing_capacity)/maxf(1,s.population_exact))*.2+s.population_health*.2+float(m.get("security",.4))*.15+float(m.get("cohesion",.5))*.15,0,1)

static func connection(id:String)->Dictionary:
	id=owner_id(id)
	if not data().connections.has(id):data().connections[id]={"last_visit":-1,"learned":[],"shared":[],"arrivals":0,"departures":0,"familiarity":0.0,"respect":0.0,"resentment":0.0}
	return data().connections[id]

static func log_event(message:String)->void:
	data().history.push_front({"day":int(WorldSimulation.state.elapsed_days),"text":message})
	if data().history.size()>64:data().history.resize(64)

static func sample_missions(system:Node,day:int)->void:
	if system.scout_missions.is_empty():return
	for mission:Dictionary in system.scout_missions:
		var end:=int(mission.get("actual_return_day",mission.return_day))
		if day<int(mission.start_day) or day>=end or int(mission.get("exchange_sample_day",-1))>=day:continue
		var position:Vector2=system.city_intelligence.mission_position(mission,day)
		mission["exchange_sample_day"]=day
		if not mission.has("encountered_societies"):mission.encountered_societies=[]
		if not mission.has("carried_collections"):mission.carried_collections=[]
		var traversed:Array[Vector2]=[]
		for step in range(9):traversed.append(system.city_intelligence.mission_position(mission,day-1+float(step)/8.0))
		for site:Dictionary in system.city_intelligence.sites(false):
			var id:=String(site.get("controller",site.civ_id))
			if id in mission.encountered_societies:continue
			var visited:=false
			for point:Vector2 in traversed:
				if point.distance_to(system.city_intelligence.vector(site.position))<=CONTACT_RADIUS and system._scout_segment_is_land(point,system.city_intelligence.vector(site.position)):visited=true;break
			if not visited:continue
			var index:int=system._civilization_index(id)
			if index<0 or owner_state(id)==null:continue
			if bool(system.civilizations[index].player_relation.get("at_war",false)):continue
			var region:Dictionary=system._region_location(String(site.city_id))
			if not region.is_empty():
				var actual:Dictionary=system.civilizations[int(region.owner_index)].strategic_regions[int(region.region_index)]
				if String(actual.get("controller",id))!=id:continue
			mission.encountered_societies.append(id)
			encounter(mission,id,String(system.civilizations[index].name),site.position,day)
		if mission.get("target_kind","") in ["explore","recruit_people"] and day%7==int(mission.get("mission_id",0))%7:sample_ground(system,mission,position,day)

static func encounter(mission:Dictionary,source:String,source_name:String,position:Dictionary,day:int)->void:
	if not mission.has("carried_collections"):mission.carried_collections=[]
	var recipient:=WorldSimulation.actor_id
	var source_state:=owner_state(source)
	if source_state==null or owner_id(source)==recipient:return
	var existing:Dictionary=data().collections
	var index:int=WorldSimulation.world._civilization_index(source)
	var opinion:=float(WorldSimulation.world.civilizations[index].player_relation.get("opinion",0)) if index>=0 else 0.0
	var material:Dictionary={}
	var carry_limit:=maxi(1,int(mission.get("personnel",2))/2)
	var sharing:String=source_state.society_exchange.sharing_policy
	var openness:=float(PERSONALITY.foreign(source_state.world_seed,source).openness)
	var willing:=sharing!="guarded" and opinion>-.35 and (sharing=="open" or openness+opinion>.25)
	if willing and mission.carried_collections.size()<carry_limit:
		var known:Array=source_state.known_discoveries.duplicate()
		known.sort_custom(func(a:String,b:String)->bool:
			var a_known:=a in WorldSimulation.state.known_discoveries;var b_known:=b in WorldSimulation.state.known_discoveries
			if a_known!=b_known:return not a_known
			return hash(source+a+str(mission.get("mission_id",0)))<hash(source+b+str(mission.get("mission_id",0))))
		for id:String in known:
			var key:="%s:%s" % [owner_id(source),id]
			if existing.has(key):continue
			var definition:Dictionary=WorldSimulation.discovery.discovery_definition(id)
			if definition.is_empty() or bool(definition.get("frontier",false)):continue
			var adopted:float=WorldSimulation.scoped(owner_id(source),func()->float:return WorldSimulation.discovery.adoption(id))
			if adopted<.35:continue
			var kind:="culture" if String(definition.get("dynamic",""))=="culture" or id in CULTURE else "knowledge"
			if kind!="culture" and not OBJECTS.has(id) and (id in WorldSimulation.state.known_discoveries or data().evidence.has(id)):continue
			if sharing=="selective" and kind!="culture" and not OBJECTS.has(id):continue
			var name:="An account of "+String(definition.name)
			if OBJECTS.has(id):
				var resource:=String(OBJECTS[id][1])
				var paid:bool=WorldSimulation.scoped(owner_id(source),func()->bool:
					if WorldSimulation.state.effective_workers("Crafting")<1 or float(WorldSimulation.state.resource_stockpiles.get(resource,0))<1:return false
					WorldSimulation.state.resource_stockpiles[resource]-=1
					return true)
				if paid:kind="artifact";name=String(OBJECTS[id][0])
			material={"id":key,"kind":kind,"name":name,"source_id":owner_id(source),"source_name":source_name,"position":position.duplicate(),"observed_day":day,"returned_day":day,"discovery_id":id,"study":0.0,"work":60.0 if kind=="culture" else 90.0,"signals":definition.get("signals",[]).duplicate(),"acquisition":"Shared during a peaceful visit"}
			mission.carried_collections.append(material)
			break
	# The contact itself exposes both traveling and receiving households to the
	# other environment; foreign identity is not an illness multiplier.
	var source_exposure:float=WorldSimulation.scoped(owner_id(source),func()->float:return float(WorldSimulation.food.current_environment_profile().get("hazards",{}).get("disease",0)))
	mission["contact_exposure"]=maxf(float(mission.get("contact_exposure",0)),source_exposure*.2)
	var visitor_exposure:=float(WorldSimulation.food.current_environment_profile().get("hazards",{}).get("disease",0))
	WorldSimulation.scoped(owner_id(source),func()->void:
		data().exposure=minf(1,float(data().exposure)+visitor_exposure*.2)
		connection(recipient).last_visit=day)
	share_practice(mission,source,position,day)
	if mission.get("target_kind","") in ["recruit_people","recruit_people_visit"]:invite_households(mission,source,source_name,day)

static func share_practice(mission:Dictionary,recipient:String,position:Dictionary,day:int)->void:
	if data().sharing_policy=="guarded":return
	var source:=WorldSimulation.actor_id
	var name:=WorldSimulation.state.settlement_name
	var target:=owner_state(recipient)
	if target==null:return
	for id:String in WorldSimulation.state.known_discoveries:
		var key:="%s:%s" % [owner_id(source),id]
		if target.society_exchange.collections.has(key):continue
		if WorldSimulation.discovery.adoption(id)<.35:continue
		var definition:Dictionary=WorldSimulation.discovery.discovery_definition(id)
		if definition.is_empty() or bool(definition.get("frontier",false)):continue
		var cultural:=String(definition.get("dynamic",""))=="culture" or id in CULTURE
		if not cultural and (id in target.known_discoveries or target.society_exchange.evidence.has(id)):continue
		if data().sharing_policy=="selective" and not cultural and not OBJECTS.has(id):continue
		var record:={"id":key,"kind":"culture" if cultural else "knowledge","name":"A visiting account of "+String(definition.name),"source_id":owner_id(source),"source_name":name,"position":position.duplicate(),"observed_day":day,"returned_day":day,"discovery_id":id,"study":0.0,"work":90.0,"signals":definition.get("signals",[]).duplicate(),"acquisition":"Taught by physically present travelers"}
		if target.society_exchange.collections.size()>=COLLECTION_LIMIT:return
		target.society_exchange.collections[key]=record
		if not mission.has("shared_practices"):mission.shared_practices=[]
		mission.shared_practices.append({"recipient":recipient,"discovery_id":id,"name":definition.name})
		return

static func envoy_arrived(system:Node,mission:Dictionary,day:int)->void:
	if String(mission.get("purpose",""))=="declare_war":return
	var id:=String(mission.get("civ_id",""));var index:int=system._civilization_index(id)
	if index<0 or owner_state(id)==null or bool(system.civilizations[index].player_relation.get("at_war",false)):return
	var location:Dictionary=mission.get("target_position",{})
	var actual:=false
	for site:Dictionary in system.city_intelligence.sites(false):
		if String(site.civ_id)==id and system.city_intelligence.vector(site.position).distance_to(system.city_intelligence.vector(location))<=CONTACT_RADIUS:actual=true;break
	if not actual:return
	mission["mission_id"]=-1-int(mission.get("depart_day",day))
	mission["encountered_societies"]=[id]
	encounter(mission,id,String(system.civilizations[index].name),location,day)
	preload("res://scripts/research_purchase.gd").negotiate(mission,id,String(system.civilizations[index].name),location,day)

static func recruitment_targets(system:Node)->Array[String]:
	# Receiving households is a separate decision at the actual encounter.
	# Lack of spare homes must not prevent peaceful visits or cultural exchange.
	var choices:Array[Dictionary]=[]
	for city:Dictionary in system.city_intelligence.known_cities():
		var id:=String(city.get("controller",""))
		if id=="" or owner_id(id)==WorldSimulation.actor_id:continue
		var index:int=system._civilization_index(id)
		if index<0 or bool(system.civilizations[index].player_relation.get("at_war",false)):continue
		var reserved:=false
		for mission:Dictionary in system.scout_missions:
			if owner_id(String(mission.get("target_civ_id","")))==owner_id(id):reserved=true
		if reserved:continue
		var age:=maxi(1,int(WorldSimulation.state.elapsed_days)-int(data().connections.get(id,{}).get("last_visit",-9999)))
		var value:float=system.player_world_origin.distance_to(system.city_intelligence.vector(city.position))*(1+90.0/age)
		choices.append({"target":"recruit:"+String(city.city_id),"score":value})
	choices.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.score<b.score if a.score!=b.score else a.target<b.target)
	var result:Array[String]=[]
	for choice:Dictionary in choices:result.append(choice.target)
	return result

static func recruitment_target(system:Node)->String:
	var targets:=recruitment_targets(system)
	return targets[0] if not targets.is_empty() else ""

static func invite_households(mission:Dictionary,source:String,source_name:String,day:int)->void:
	if mission.has("migrant_reservation"):return
	if day<int(known_relation(source).get("recruitment_truce_until",0)):
		mission["recruitment_reason"]="Our border understanding suspends invitations to each other’s households.";return
	var room:=reception_capacity()
	if room<2:mission["recruitment_reason"]="No invitation: "+String(reception_snapshot().message);return
	var recipient:=WorldSimulation.actor_id
	var our_attraction:=attraction()
	var familiarity:=float(connection(source).familiarity)
	var remaining_days:=maxi(1,int(mission.get("actual_return_day",mission.return_day))-day)
	var key:="%s:%s" % [recipient,str(mission.get("mission_id",0))]
	var result:Dictionary=WorldSimulation.scoped(owner_id(source),func()->Dictionary:
		var advantage:=our_attraction-attraction()+familiarity*.08
		if advantage<.06:return {"reason":"The households prefer their present living conditions and ties."}
		var free:=maxi(0,WorldSimulation.state.able_population()-WorldSimulation.military._mobilized_count()-WorldSimulation.world.mission_absent_personnel()-12)
		var delegates:=clampi(int(mission.get("personnel",2)),2,80)
		var people:=mini(room,mini(free,clampi(floori(advantage*delegates*4),2,delegates*2)))
		var provisions:=people*remaining_days*.55
		if people<2 or WorldSimulation.food.total_stored()-provisions<WorldSimulation.state.population_exact*.9*7:return {"reason":"No household can make this journey with adequate provisions."}
		WorldSimulation.food.issue_for_obligation(provisions,"migration","Households joining a returning party",remaining_days,people)
		data().outbound[key]={"count":people,"until":int(mission.get("actual_return_day",mission.return_day))+1,"destination":recipient}
		return {"source":source,"source_name":source_name,"key":key,"count":people,"provisions":provisions,"departed_day":day})
	if result.has("reason"):mission["recruitment_reason"]=result.reason;return
	mission["migrant_reservation"]=result
	mission["recruitment_reason"]="%d people accepted the invitation and are traveling with the party." % int(result.count)

# These investigations can use a returned physical sample. This never claims
# surveyed local reserves or supplies accessible/developed material gates.
const SPECIMEN_RESOURCES={"clay_shaping":"Clay","stone_sorting":"Stone","fiber_grading":"Fiber Plants","timber_grading":"Timber","controlled_flaking":"Flint","salt_working":"Salt","herbal_classification":"Medicinal Plants","ore_assaying":"Copper Ore","iron_assaying":"Iron Ore","coal_grading":"Coal","soil_assays":"Fertile Soil"}
static func studied_resource_sample(resource:String)->bool:
	if resource.is_empty():return false
	for item:Dictionary in data().collections.values():
		if item.get("kind","")!="specimen" or float(item.get("study",0))<1.0:continue
		if int(item.get("returned_day",0))>int(WorldSimulation.state.elapsed_days):continue
		if SPECIMEN_RESOURCES.get(String(item.get("discovery_id","")),"")==resource:return true
	return false

static func sample_ground(system:Node,mission:Dictionary,position:Vector2,day:int)->void:
	if not system.ground_survey_authority.is_valid() or mission.carried_collections.size()>=maxi(1,int(mission.personnel)/2):return
	if system._position_is_revealed(position):return
	var ground:Dictionary=system.ground_survey_authority.call(position)
	if ground.get("biome","")=="water":return
	var potentials:Dictionary=ground.get("resource_potentials",{})
	if potentials.is_empty():potentials=preload("res://scripts/civilization_day.gd").context(position).get("environment_profile",{}).get("resource_potentials",{})
	var choices:={
		"Clay":["Clay specimen","clay_shaping","clay"],"Stone":["Stone specimen","stone_sorting","stone"],"Fiber Plants":["Fiber specimen","fiber_grading","fiber"],
		"Timber":["Wood specimen","timber_grading","timber"],"Flint":["Flint specimen","controlled_flaking","stone"],"Salt":["Saline crust specimen","salt_working","salt"],
		"Medicinal Plants":["Botanical specimen","herbal_classification","foraging"],"Copper Ore":["Mineral specimen","ore_assaying","stone"],"Iron Ore":["Dense mineral specimen","iron_assaying","stone"],
		"Coal":["Dark combustible rock","coal_grading","stone"],"Fertile Soil":["Soil specimen","soil_assays","ecology"]}
	for resource:String in choices:
		if float(potentials.get(resource,0))<.35:continue
		var subject:=String(choices[resource][1])
		if subject in WorldSimulation.state.known_discoveries:continue
		var definition:=WorldSimulation.discovery.discovery_definition(subject)
		if definition.is_empty():continue
		var foundations:=true
		for requirement:String in definition.get("requires",[]):
			if requirement not in WorldSimulation.state.known_discoveries:foundations=false
		if not foundations:continue
		var already_collected:=false
		for collected:Dictionary in data().collections.values():
			if collected.kind=="specimen" and collected.discovery_id==subject:already_collected=true;break
		if already_collected:continue
		var key:="ground:%d:%d:%s" % [floori(position.x/24),floori(position.y/24),resource]
		if data().collections.has(key):continue
		var duplicate:=false
		for item:Dictionary in mission.carried_collections:
			if item.id==key or item.discovery_id==choices[resource][1]:duplicate=true
		if duplicate:continue
		mission.carried_collections.append({"id":key,"kind":"specimen","name":choices[resource][0],"source_id":"","source_name":String(ground.get("label","Surveyed ground")),"position":{"x":position.x,"z":position.y},"observed_day":day,"returned_day":day,"discovery_id":choices[resource][1],"study":0.0,"work":60.0,"signals":[choices[resource][2],"survey"],"acquisition":"Collected on physically visited, previously uncharted ground"})
		break

static func returned(mission:Dictionary,day:int)->Array[Dictionary]:
	var records:Array[Dictionary]=[]
	if bool(mission.get("exchange_returned",false)):return records
	if mission.get("research_mode","") in ["materials","license"] and day<int(mission.get("return_day",day+1)):return records
	mission["exchange_returned"]=true
	if mission.get("research_mode","")=="license":records.append_array(preload("res://scripts/research_licenses.gd").deliver(mission,day))
	if mission.get("research_mode","")=="materials":records.append_array(preload("res://scripts/research_materials.gd").deliver(mission,day))
	preload("res://scripts/research_purchase.gd").refund(mission)
	for item:Dictionary in mission.get("carried_collections",[]):
		if (item.get("research_purchase",false) or item.get("partnership_protocol",false) or item.get("research_partnership",false)) and mission.get("research_refused",false):continue
		if data().collections.has(String(item.id)) or data().collections.size()>=COLLECTION_LIMIT:continue
		var saved:=item.duplicate(true);saved.returned_day=day
		data().collections[String(item.id)]=saved
		records.append({"kind":saved.kind,"title":saved.name,"description":"%s · encountered day %d" % [saved.source_name,int(saved.observed_day)],"consequence":"Your knowledge workers will examine this. Its specific evidence becomes usable after study.","collection_id":saved.id,"position":saved.position.duplicate(),"discovery_id":saved.discovery_id})
	data().exposure=minf(1,float(data().exposure)+float(mission.get("contact_exposure",0)))
	for id:String in mission.get("encountered_societies",[]):connection(id).last_visit=day
	for sharing:Dictionary in mission.get("shared_practices",[]):
		var ties:=connection(String(sharing.recipient))
		if sharing.discovery_id not in ties.shared:ties.shared.append(sharing.discovery_id)
		records.append({"kind":"culture","title":"A practice carried outward","description":"The travelers demonstrated %s during their visit." % String(sharing.name),"consequence":"The receiving community can study it with its own people. Acceptance and adoption are their decision."})
	return records

static func arrive(mission:Dictionary,day:int)->int:
	var reservation:Dictionary=mission.get("migrant_reservation",{})
	if reservation.is_empty() or bool(mission.get("migration_resolved",false)):return 0
	mission["migration_resolved"]=true
	var source:=String(reservation.source);var recipient:=WorldSimulation.actor_id
	if owner_state(source)==null:return 0
	var result:Dictionary=WorldSimulation.scoped(owner_id(source),func()->Dictionary:
		var pending:Dictionary=data().outbound.get(String(reservation.key),{})
		if pending.is_empty():return {}
		data().outbound.erase(String(reservation.key))
		var departure:Dictionary=WorldSimulation.state.register_population_departures(int(pending.count),"Households emigrated to another civilization",{"children":1.0,"youth":1.0,"early_adults":1.0,"established_adults":1.0,"mature_adults":1.0,"elders":1.0})
		departure["cohorts"]=WorldSimulation.state.last_population_removal_by_cohort.duplicate()
		connection(recipient).departures+=int(departure.get("count",0))
		connection(recipient).resentment=minf(.4,float(connection(recipient).resentment)+float(departure.get("count",0))/maxf(1,WorldSimulation.state.population_exact)*.2)
		log_event("%d people moved to another community after a recruitment visit." % int(departure.get("count",0)))
		return departure)
	var count:=int(result.get("count",0))
	if count<=0:return 0
	WorldSimulation.state.register_population_arrivals(count,"Households from "+String(reservation.source_name),result.cohorts)
	var merged:=false
	for group:Dictionary in data().integration:
		if group.origin==source:group.count+=count;group.remaining+=count;merged=true;break
	if not merged:data().integration.append({"origin":source,"count":float(count),"remaining":float(count)})
	connection(source).arrivals+=count
	log_event("%d newcomers arrived from %s; reception and integration are under way." % [count,String(reservation.source_name)])
	return count

static func advance(day:int)->void:
	if day<=int(data().last_day):return
	var elapsed:=mini(7,maxi(1,day-int(data().last_day))) if int(data().last_day)>=0 else 1
	data().last_day=day
	preload("res://scripts/scholar_visits.gd").advance(day)
	for id:String in data().connections:
		var view_id:="human" if id=="player" and WorldSimulation.actor_id!="player" else id
		var index:int=WorldSimulation.world._civilization_index(view_id)
		if index>=0 and bool(WorldSimulation.world.civilizations[index].player_relation.get("at_war",false)):
			data().connections[id].erase("received_cooperation")
			data().connections[id].erase("recruitment_truce_until")
	data().exposure=maxf(0,float(data().exposure)-elapsed/90.0)
	for key:String in data().outbound.keys():
		if day>int(data().outbound[key].until):data().outbound.erase(key)
	var food:=clampf(float(WorldSimulation.state.simulation_metrics.get("food_intake_ratio",1)),0,1)
	var housing:=clampf(float(WorldSimulation.state.housing_capacity)/maxf(1,WorldSimulation.state.population_exact),0,1)
	var work:=WorldSimulation.state.effective_workers("Administration")*elapsed/60.0*food*housing
	for group:Dictionary in data().integration.duplicate():
		var used:=minf(work,float(group.remaining));group.remaining-=used;work-=used
		if group.remaining<=.001:data().integration.erase(group)
	# Study competes within the existing Knowledge workforce, not a free team.
	var study_work:=WorldSimulation.state.effective_workers("Knowledge")*.15*elapsed*food
	for item:Dictionary in data().collections.values():
		if study_work<=0:break
		if float(item.study)>=1 or day<int(item.returned_day):continue
		var supplies:=preload("res://scripts/paper_study.gd").use(study_work,(1-float(item.study))*float(item.work))
		supplies.progress+=preload("res://scripts/microscope_observation.gd").use(item,float(supplies.progress),(1-float(item.study))*float(item.work))
		item.study=minf(1,float(item.study)+float(supplies.progress)/float(item.work));study_work-=float(supplies.work)
		if item.study>=1:
			if item.get("partnership_protocol",false):
				log_event("Completed %s. Send a delegation to exchange findings with the partner." % String(item.name))
				continue
			var prior:Dictionary=data().collections.get(String(data().evidence.get(String(item.discovery_id),"")),{})
			if evidence_strength(item)>=evidence_strength(prior):data().evidence[String(item.discovery_id)]=String(item.id)
			var signals:Dictionary={}
			for signal_name:String in item.signals:signals[signal_name]=.65
			WorldSimulation.state.register_field_observations(signals,day+180)
			if item.source_id!="":
				var ties:=connection(String(item.source_id))
				if item.discovery_id not in ties.learned:ties.learned.append(item.discovery_id)
				ties.familiarity=minf(1,float(ties.familiarity)+.08)
				ties.respect=minf(.3,float(ties.respect)+(.05 if item.kind=="culture" else .03))
			log_event("Examined %s. Its evidence now supports the related investigation." % String(item.name))

static func evidence_strength(item:Dictionary)->float:
	if item.get("reverse_engineered",false):return 1.35
	if item.is_empty() or item.get("partnership_protocol",false):return 0.0
	if item.get("research_purchase",false):return 2.5
	if item.get("research_partnership",false):return 1.6
	return 1.0 if item.get("kind","")=="specimen" else 1.8

static func studying()->bool:
	for item:Dictionary in data().collections.values():
		if float(item.study)<1 and int(item.returned_day)<=int(WorldSimulation.state.elapsed_days):return true
	return false

static func known_relation(id:String)->Dictionary:
	return data().connections.get(owner_id(id),{}).duplicate(true)

static func diplomatic_value(id:String,p:Dictionary)->float:
	var ties:=known_relation(id)
	return float(ties.get("respect",0))*(.4+float(p.get("openness",.5))*.8)+float(ties.get("familiarity",0))*.1-float(ties.get("resentment",0))*float(p.get("assertiveness",.5))

static func counterpart_value(id:String,p:Dictionary)->float:
	var recipient:=WorldSimulation.actor_id
	if owner_state(id)==null:return 0
	return WorldSimulation.scoped(owner_id(id),func()->float:return diplomatic_value(recipient,p))

static func accept_accord(id:String,kind:String,domain:String,bonus:float,until:int)->void:
	var other:=owner_id(id);var initiator:=WorldSimulation.actor_id
	if owner_state(other)==null:return
	if kind=="restraint":connection(other)["recruitment_truce_until"]=until
	WorldSimulation.scoped(other,func()->void:
		connection(initiator)["received_cooperation"]={"domain":domain,"kind":kind,"bonus":bonus,"until":until}
		if kind=="restraint":connection(initiator)["recruitment_truce_until"]=until)
static func received_accord_bonus(domain:String)->float:
	var bonus:=0.0;var day:=int(WorldSimulation.state.elapsed_days)
	for id:String in data().connections:
		var accord:Dictionary=data().connections[id].get("received_cooperation",{})
		if accord.is_empty() or day>=int(accord.until) or accord.domain!=domain:continue
		var view_id:="human" if id=="player" and WorldSimulation.actor_id!="player" else id
		var index:int=WorldSimulation.world._civilization_index(view_id)
		if index<0 or bool(WorldSimulation.world.civilizations[index].player_relation.get("at_war",false)):continue
		# One undertaking per pair. A reciprocal proposal cannot stack it twice.
		var own:Dictionary=WorldSimulation.diplomacy.leaders.get(view_id,{}).get("accord",{})
		if not own.is_empty() and day<int(own.until):continue
		bonus+=float(accord.bonus)
	return bonus

static func leader_position(id:String,p:Dictionary)->Dictionary:
	var recipient:=WorldSimulation.actor_id
	if owner_state(id)==null:return {}
	return WorldSimulation.scoped(owner_id(id),func()->Dictionary:
		var ties:=known_relation(recipient)
		if float(ties.get("resentment",0))>.03 and float(p.get("assertiveness",.5))>.5:
			return {"title":"Households are leaving","line":"Your invitations are drawing people away from us. We need an understanding about how these journeys are conducted.","priority":"restraint"}
		if float(pressure().unsettled_share)>.12:
			return {"title":"Give our households time to settle","line":"Housing and local obligations need our attention. I want our officials to finish welcoming the people already here.","priority":"restraint"}
		if float(ties.get("respect",0))>.02:
			return {"title":"Your practices have earned a hearing","line":"Our people have learned from the accounts your travelers brought. I see value in keeping that exchange alive.","priority":"exchange"}
		return {})

static func relation_brief(id:String)->String:
	var ties:=known_relation(id)
	if ties.is_empty():return "No returned cultural exchange or migration record."
	return "%d practices studied · %d arrivals · %d departures. Respect %.0f%% · familiarity %.0f%%. These are recorded exchanges, not a measure of the other society's total knowledge." % [ties.get("learned",[]).size(),int(ties.get("arrivals",0)),int(ties.get("departures",0)),float(ties.get("respect",0))*100,float(ties.get("familiarity",0))*100]
