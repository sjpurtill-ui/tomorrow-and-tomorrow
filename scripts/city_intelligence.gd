extends RefCounted
## Evidence is a frozen observation, never a view onto today's hidden city.
const MAX_OBSERVERS:=64
const MAX_CITIES:=512
const SIGHT_RADIUS:=12.0
const FIELDS={"population":{"label":"Population","threshold":.25,"unit":"people"},"fortification":{"label":"Visible defenses","threshold":.35,"unit":"capacity"},"garrison":{"label":"Garrison","threshold":.55,"unit":"troops"},"production":{"label":"Workshops and production","threshold":.60,"unit":"capacity"},"logistics":{"label":"Roads and carrying capacity","threshold":.60,"unit":"capacity"},"supply":{"label":"Food reserve outlook","threshold":.75,"unit":"days"},"damage":{"label":"Visible damage","threshold":.35,"unit":"capacity"}}
var records:Dictionary={}
var system:Node

func _init(owner:Node=null)->void:
	system=owner if owner!=null else CivilizationSystem
var screen_layer:CanvasLayer

func sites(include_player:bool=true)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for civ:Dictionary in system.civilizations:
		var home:Vector2=system._civilization_world_position(civ)
		var capital:Dictionary={}
		for region:Dictionary in civ.strategic_regions:
			if region.role=="capital": capital=region
		for region:Dictionary in civ.strategic_regions:
			# The five existing urban regions already carry stable map coordinates.
			# Anchor the capital at the existing home, preserving relative geography.
			var offset:=Vector2((float(region.map_x)-float(capital.get("map_x",.5)))*220,(float(region.map_y)-float(capital.get("map_y",.5)))*180)
			result.append({"city_id":String(region.id),"civ_id":String(civ.id),"name":String(region.name),"position":point(home+offset),"primary":region.role=="capital"})
	if include_player:
		for city:Dictionary in GameState.player_settlements:
			var position:Variant=city.get("position",Vector2.ZERO)
			var location:=position as Vector2 if position is Vector2 else Vector2(float(position.get("x",0)),float(position.get("z",position.get("y",0))))
			result.append({"city_id":String(city.id),"civ_id":"player","name":String(city.get("name","Settlement")),"position":point(location),"primary":bool(city.get("primary",false))})
	return result

func point(value:Vector2)->Dictionary: return {"x":value.x,"z":value.y}
func vector(value:Dictionary)->Vector2: return Vector2(float(value.get("x",0)),float(value.get("z",0)))
func site(city_id:String)->Dictionary:
	for value:Dictionary in sites():
		if value.city_id==city_id: return value
	return {}

func primary_id(civ_id:String)->String:
	if civ_id=="player":
		for city:Dictionary in GameState.player_settlements:
			if bool(city.get("primary",false)): return String(city.id)
		return ""
	var index:int=system._civilization_index(civ_id)
	if index<0: return ""
	for region:Dictionary in system.civilizations[index].strategic_regions:
		if region.role=="capital": return String(region.id)
	return ""

func truth(city_id:String)->Dictionary:
	var place:=site(city_id)
	if place.is_empty(): return {}
	var values:Dictionary={}
	if place.civ_id=="player":
		var city:=SettlementModel.settlement_record(city_id)
		var local:=SettlementModel.city_resource_snapshot(city_id)
		var metrics:Dictionary=local.get("metrics",{})
		values={"population":float(local.get("population",0)),"production":float(metrics.get("material_capacity",0)),"logistics":float(metrics.get("logistics",0)),"supply":float(metrics.get("food_days",-1))}
		if bool(city.get("primary",false)):
			values["garrison"]=float(MilitaryCampaign.home_army.get("troops",0))
			values["fortification"]=clampf(float(MilitaryCampaign.settlement_defense.get("stage",0))/5.0,0,1)
		# Secondary cities do not have an independent garrison/defense ledger yet.
		place["controller"]=String(city.get("occupied_by","player"))
		if String(place.controller)!="player":values.erase("garrison")
	else:
		var location:Dictionary=system._region_location(city_id)
		if location.is_empty(): return {}
		var civ:Dictionary=system.civilizations[int(location.owner_index)]
		var region:Dictionary=civ.strategic_regions[int(location.region_index)]
		var controller_index:int=system._civilization_index(String(region.controller))
		if controller_index>=0: civ=system.civilizations[controller_index]
		var fort:=float(region.fortification)*(1.0-float(region.damage)*.65)
		values={"population":float(region.population),"fortification":fort,"damage":float(region.damage),"garrison":float(civ.military_population)*float(region.strategic_weight)*(.72+fort)*(.82+float(civ.logistics)*.36),"production":float(civ.production)*(1-float(region.damage)*.5),"logistics":float(civ.logistics)*(1-float(region.damage)*.3),"supply":float(civ.food_days)}
		if String(region.controller)=="player":
			for key in ["garrison","production","logistics","supply"]: values.erase(key)
		place["controller"]=String(region.controller)
	place["values"]=values
	return place

func capture(observer:String,city_id:String,quality:float,day:int,source:String,reference:String)->Dictionary:
	var actual:=truth(city_id)
	if actual.is_empty() or actual.civ_id==observer: return {}
	quality=clampf(quality,0, .9)
	var fields:Dictionary={}
	for key:String in FIELDS:
		if quality<float(FIELDS[key].threshold) or not actual.values.has(key) or float(actual.values[key])<0: continue
		var value:=float(actual.values[key])
		var rng:=RandomNumberGenerator.new(); rng.seed=hash(observer+city_id+key+reference)^day^GameState.world_seed
		var error:=lerpf(.65,.16,quality)
		var quantum:=.05 if FIELDS[key].unit=="capacity" else maxf(1,pow(10,floor(log(maxf(1,value))/log(10))-1))
		var width:=maxf(quantum,value*error)
		var center:=value+rng.randf_range(-.3,.3)*width
		var low:=maxf(0,floor((center-width)/quantum)*quantum)
		var high:float=ceil((center+width)/quantum)*quantum
		if FIELDS[key].unit=="capacity": high=minf(1,high)
		fields[key]={"low":low,"high":high,"observed_day":day,"quality":quality,"source":source,"reference":reference}
	return {"city_id":city_id,"civ_id":String(actual.civ_id) if quality>=.35 else "","name":String(actual.name) if quality>=.35 else "Unidentified settlement","position":actual.position.duplicate(true),"controller":String(actual.controller) if quality>=.35 else "","observed_day":day,"reported_day":day,"quality":quality,"source":source,"reference":reference,"fields":fields}

func location_record(place:Dictionary,day:int,source:String,reference:String)->Dictionary:
	return {"city_id":String(place.city_id),"civ_id":String(place.get("civ_id","")),"name":String(place.get("name","Reported settlement")),"position":place.position.duplicate(true),"controller":"","observed_day":day,"reported_day":day,"quality":.15,"source":source,"reference":reference,"fields":{}}

func publish(observer:String,observation:Dictionary,day:int)->void:
	if observation.is_empty(): return
	if not records.has(observer):
		if records.size()>=MAX_OBSERVERS: return
		records[observer]={}
	var book:Dictionary=records[observer]
	var id:=String(observation.city_id)
	if not book.has(id) and book.size()>=MAX_CITIES: return
	var previous:Dictionary=book.get(id,{})
	var next:=observation.duplicate(true); next.reported_day=day
	if not previous.is_empty():
		if int(previous.observed_day)>int(next.observed_day): return
		if next.civ_id=="": next.civ_id=previous.civ_id; next.name=previous.name; next.controller=previous.controller
		for field:String in previous.fields:
			if not next.fields.has(field): next.fields[field]=previous.fields[field].duplicate(true)
	book[id]=next
	if observer=="player":
		system._add_revealed_area(vector(next.position),SIGHT_RADIUS,"observed city")
		if next.civ_id!="":
			var index:int=system._civilization_index(next.civ_id)
			if index>=0:
				var relation:Dictionary=system.civilizations[index].player_relation
				relation.merge(system._set_contact_provenance(relation,day,String(next.source),vector(next.position),"city",id),true)
				relation.contact_level=2
				if id==primary_id(next.civ_id):
					relation.home_location_known=true; relation.home_position=next.position.duplicate(true); relation.home_location_source=next.source; relation.last_observed_day=next.observed_day

func known(observer:String,city_id:String,day:int=-1)->Dictionary:
	var value:Dictionary=records.get(observer,{}).get(city_id,{})
	if value.is_empty(): return {}
	var result:=value.duplicate(true)
	var today:=int(GameState.elapsed_days) if day<0 else day
	result["age_days"]=maxi(0,today-int(value.observed_day)) if int(value.observed_day)>=0 else -1
	result["freshness"]="date unknown" if int(value.observed_day)<0 else ("recent" if int(result.age_days)<=30 else ("aging" if int(result.age_days)<=180 else "stale"))
	for key:String in result.fields:
		var field:Dictionary=result.fields[key]
		var age:=maxi(0,today-int(field.observed_day))
		var spread:=minf(1.5,float(age)/365.0)
		field.low=maxf(0,float(field.low)*(1.0-minf(.9,spread)))
		field.high=float(field.high)*(1.0+spread)
		if FIELDS[key].unit=="capacity": field.high=minf(1,field.high)
		field["age_days"]=age; field["stale"]=age>180
	return result

func known_cities(observer:String="player",civ_id:String="")->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var book:Dictionary=records.get(observer,{})
	for id:String in book:
		var value:Dictionary=book[id]
		if civ_id=="" or value.civ_id==civ_id or value.controller==civ_id: result.append(known(observer,id))
	return result

func public_regions(civ_id:String)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var cities:=known_cities("player",civ_id)
	cities.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return String(a.city_id)<String(b.city_id))
	var front_selected:=false
	for city:Dictionary in cities:
		var row:Dictionary={"id":city.city_id,"name":city.name,"role":"observed city","controller":city.controller,"controller_label":controller_label(String(city.controller)),"original_controller":city.civ_id,"original_controller_label":controller_label(String(city.civ_id)),"position":city.position,"available":city.controller!="player","availability_reason":"Last-known location; current access and control must be checked on arrival.","foreign_holding":city.controller not in ["","player"] and city.controller!=city.civ_id,"intelligence":city}
		for key:String in ["population","fortification","damage","garrison"]:
			var estimate:Dictionary=city.fields.get(key,{})
			row[key]=(float(estimate.low)+float(estimate.high))*.5 if not estimate.is_empty() else -1.0
		row["approach_index"]=result.size()
		if city.civ_id==civ_id and city.controller not in ["player", ""]:
			row.available=not front_selected
			front_selected=true
		elif city.controller=="": row.available=false
		row["occupation_required"]=maxf(0,float(row.population))*.08
		result.append(row)
	return result

func seed_known_homes()->void:
	for civ:Dictionary in system.civilizations:
		var relation:Dictionary=civ.player_relation
		var id:=primary_id(String(civ.id))
		if bool(relation.get("home_location_known",false)) and not records.get("player",{}).has(id) and valid_point(relation.get("home_position",{})):
			publish("player",location_record({"city_id":id,"civ_id":String(civ.id),"name":"Reported home of %s" % String(civ.name),"position":relation.home_position},int(relation.get("last_observed_day",-1)),String(relation.get("home_location_source","earlier location report")),"home:"+String(civ.id)),int(GameState.elapsed_days))

func migrate()->void:
	seed_known_homes()
	var primary:=primary_id("player")
	if primary=="": return
	for civ:Dictionary in system.civilizations:
		var relation:Dictionary=civ.player_relation
		if float(relation.get("rival_player_trace_confidence",0))<.9 or "direct" not in String(relation.get("rival_player_trace_source","")): continue
		var position:Dictionary=relation.get("rival_player_trace_center",{})
		if valid_point(position): publish(String(civ.id),location_record({"city_id":primary,"civ_id":"player","name":"Reported player settlement","position":position},int(relation.get("rival_player_trace_day",-1)),"legacy returned direct encounter","legacy"),int(GameState.elapsed_days))

func stage(mission:Dictionary,observer:String,position:Vector2,quality:float,day:int,reference:String)->void:
	if not mission.has("city_observations"): mission["city_observations"]={}
	for place:Dictionary in sites():
		if place.civ_id==observer: continue
		if position.distance_to(vector(place.position))>SIGHT_RADIUS: continue
		var observation:=capture(observer,place.city_id,quality,day,"physical reconnaissance",reference)
		if not observation.is_empty(): mission.city_observations[place.city_id]=observation

func route_position(route:Array,fraction:float)->Vector2:
	if route.is_empty(): return Vector2(INF,INF)
	var total:float=system._scout_route_distance(route)
	var remaining:=total*clampf(fraction,0,1)
	for index:int in range(1,route.size()):
		var a:=vector(route[index-1]); var b:=vector(route[index]); var distance:=a.distance_to(b)
		if remaining<=distance: return a.lerp(b,remaining/maxf(.001,distance))
		remaining-=distance
	return vector(route[-1])

func sample_missions(day:int)->void:
	for mission:Dictionary in system.scout_missions:
		var start:=int(mission.start_day); var end:=int(mission.get("actual_return_day",mission.return_day))
		if day<start or day>=end: continue
		var progress:=float(day-start)/maxf(1,float(end-start))
		var fraction:=progress*2 if progress<=.5 else (1-progress)*2
		stage(mission,"player",route_position(mission.route,fraction),.45+clampf(GameState.combined_intelligence,0,1)*.4+(.15 if mission.get("target_kind")=="observe_city" else 0),day,"scout:%s" % str(mission.mission_id))
	for formation:Dictionary in system.foreign_formations:
		if formation.get("kind")!="scout" or not system._foreign_scout_is_active(formation,day): continue
		var due:=float(formation.depart_day)+float(formation.leg_days)*2
		if float(day)>=due: continue
		var index:int=system._civilization_index(String(formation.civ_id))
		if index<0: continue
		var civ:Dictionary=system.civilizations[index]
		stage(formation,String(civ.id),system._foreign_formation_position(formation,day),.45+float(civ.knowledge)*.4,day,"scout:%s:%s" % [String(formation.id),str(formation.depart_day)])

func deliver(mission:Dictionary,observer:String,day:int)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	# A fast-forward may skip observation ticks. The traveled route still proves
	# a location, but cannot reconstruct historical population or stores.
	var route:Array=mission.get("route",[])
	if route.is_empty() and mission.has_all(["point_a","point_b"]): route=[point(mission.point_a),point(mission.point_b)]
	if not route.is_empty():
		for place:Dictionary in sites():
			if place.civ_id==observer: continue
			if records.get(observer,{}).has(place.city_id) or mission.get("city_observations",{}).has(place.city_id): continue
			if system._route_distance_to_point(route,vector(place.position))>SIGHT_RADIUS: continue
			var unknown:=place.duplicate(true); unknown.name="Reported settlement"; unknown.civ_id=""
			var observation:=location_record(unknown,-1,"returned route; details undated","route")
			publish(observer,observation,day); result.append(known(observer,String(place.city_id),day))
	for observation:Dictionary in mission.get("city_observations",{}).values():
		publish(observer,observation,day); result.append(known(observer,String(observation.city_id),day))
	mission.erase("city_observations")
	return result

func observe_near_player(day:int)->void:
	if not GameState.settlement_site_committed: return
	var positions:Array[Vector2]=[]
	for place:Dictionary in sites():
		if place.civ_id=="player": positions.append(vector(place.position))
	for place:Dictionary in sites(false):
		for position:Vector2 in positions:
			if position.distance_to(vector(place.position))<=SIGHT_RADIUS:
				publish("player",capture("player",place.city_id,.45+clampf(GameState.combined_intelligence,0,1)*.4,day,"local observation","lookouts"),day); break

func player_estimate(observer:String,primary_only:bool=false)->Dictionary:
	var population:=0.0; var power:=0.0; var target:Dictionary={}
	var primary:=primary_id("player")
	for city:Dictionary in known_cities(observer,"player"):
		if primary_only and city.city_id!=primary: continue
		if int(city.age_days)<0 or int(city.age_days)>365: continue
		if city.city_id==primary: target=city
		var pop:Dictionary=city.fields.get("population",{})
		var guard:Dictionary=city.fields.get("garrison",{})
		if not pop.is_empty(): population+=(float(pop.low)+float(pop.high))*.5
		if not guard.is_empty(): power+=float(guard.high)
		elif not pop.is_empty(): power+=float(pop.high)*.08
	return {"population":population,"power":power,"target":target,"known":not target.is_empty()}

func controller_label(id:String)->String:
	if id=="player": return "Your settlement"
	var index:int=system._civilization_index(id)
	if index>=0 and int(system.civilizations[index].player_relation.get("contact_level",0))>=2: return String(system.civilizations[index].name)
	return "Unknown polity" if id!="" else "Unknown"

func describe(city:Dictionary)->String:
	if city.is_empty(): return "No report identifies this city."
	var lines:Array[String]=[String(city.name),"%s · observed day %s · report received day %d" % [String(city.freshness),"unknown" if int(city.observed_day)<0 else str(city.observed_day),int(city.reported_day)],"Source: %s (%s)" % [String(city.source),String(city.reference)],"Last reported control: %s" % controller_label(String(city.controller))]
	for key:String in FIELDS:
		var field:Dictionary=city.fields.get(key,{})
		var description:="Unknown — no observation supports an estimate."
		if not field.is_empty():
			var scale:=100.0 if FIELDS[key].unit=="capacity" else 1.0
			description="%s–%s %s · observed day %d%s" % [str(roundi(float(field.low)*scale)),str(roundi(float(field.high)*scale)),"%" if scale>1 else String(FIELDS[key].unit),int(field.observed_day)," · stale" if bool(field.stale) else ""]
		lines.append("%s: %s" % [String(FIELDS[key].label),description])
	lines.append("Local deposits and individual stores: unknown. A city's regional supply outlook is not an inventory of its warehouses.")
	return "\n\n".join(lines)

func open(city_id:String="",civ_id:String="")->void:
	if is_instance_valid(screen_layer): screen_layer.queue_free()
	screen_layer=CanvasLayer.new(); screen_layer.layer=87; system.add_child(screen_layer)
	var panel=preload("res://scripts/city_intelligence_screen.gd").new()
	panel.city_id=city_id; panel.civ_id=civ_id; screen_layer.add_child(panel)

func valid_carried(mission:Dictionary)->bool:
	var carried:Variant=mission.get("city_observations",{})
	if not carried is Dictionary or carried.size()>MAX_CITIES: return false
	for key in carried:
		if not valid_observation(carried[key]) or key!=carried[key].city_id: return false
	return true

func valid_point(value:Variant)->bool:
	return value is Dictionary and number(value.get("x")) and number(value.get("z")) and absf(float(value.x))<=30000 and absf(float(value.z))<=30000
func number(value:Variant)->bool: return (value is int or value is float) and is_finite(float(value))
func valid_observation(value:Variant)->bool:
	if not value is Dictionary or not value.has_all(["city_id","civ_id","name","position","controller","observed_day","reported_day","quality","source","reference","fields"]): return false
	for key:String in ["city_id","civ_id","name","controller","source","reference"]:
		if not value[key] is String or value[key].length()>200: return false
	if not valid_point(value.position) or not number(value.quality) or value.quality<0 or value.quality>1 or not number(value.observed_day) or value.observed_day<-1 or not number(value.reported_day) or value.reported_day<value.observed_day: return false
	if not value.fields is Dictionary or value.fields.size()>FIELDS.size(): return false
	for key in value.fields:
		var field:Variant=value.fields[key]
		if not FIELDS.has(key) or not field is Dictionary or not field.has_all(["low","high","observed_day","quality","source","reference"]): return false
		for metric:String in ["low","high","observed_day","quality"]:
			if not number(field[metric]): return false
		if field.low<0 or field.high<field.low or field.high>1e15 or field.observed_day<0 or field.quality<0 or field.quality>1 or not field.source is String or field.source.length()>200 or not field.reference is String or field.reference.length()>200: return false
	return true
func validate(value:Variant)->bool:
	if not value is Dictionary or value.size()>MAX_OBSERVERS: return false
	for observer in value:
		if not observer is String or observer.length()>80 or not value[observer] is Dictionary or value[observer].size()>MAX_CITIES: return false
		for city_id in value[observer]:
			if not valid_observation(value[observer][city_id]) or city_id!=value[observer][city_id].city_id: return false
	return true
