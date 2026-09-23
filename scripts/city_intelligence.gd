extends RefCounted
## Evidence is a frozen observation, never a view onto today's hidden city.
const MAX_OBSERVERS:=64
const MAX_CITIES:=512
const SIGHT_RADIUS:=12.0
const FIELDS={"population":{"label":"Population","threshold":.25,"unit":"people"},"fortification":{"label":"Visible defenses","threshold":.35,"unit":"capacity"},"garrison":{"label":"Garrison","threshold":.55,"unit":"troops"},"production":{"label":"Workshops and production","threshold":.60,"unit":"capacity"},"logistics":{"label":"Roads and carrying capacity","threshold":.60,"unit":"capacity"},"supply":{"label":"Food reserve outlook","threshold":.75,"unit":"days"},"damage":{"label":"Visible damage","threshold":.35,"unit":"capacity"},"science":{"label":"Legacy science index","threshold":.45,"unit":"capacity"},"gdp":{"label":"GDP (labor-equivalent output)","threshold":.45,"unit":"worker-days/day"},"health":{"label":"Legacy health index","threshold":.45,"unit":"capacity"},"science_capacity":{"label":"Science capacity","threshold":.45,"unit":"researcher-equivalents"},"education":{"label":"Average education","threshold":.45,"unit":"capacity"},"life_expectancy":{"label":"Life expectancy","threshold":.45,"unit":"years"},"infant_mortality":{"label":"Infant mortality","threshold":.45,"unit":"deaths/1,000 births"}}
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
			if not bool(region.get("settlement_founded",true)):continue
			# The five existing urban regions already carry stable map coordinates.
			# Anchor the capital at the existing home, preserving relative geography.
			var offset:=Vector2((float(region.map_x)-float(capital.get("map_x",.5)))*220,(float(region.map_y)-float(capital.get("map_y",.5)))*180)
			result.append({"city_id":String(region.id),"civ_id":String(civ.id),"name":String(region.name),"position":point(region.get("position",home+offset)),"primary":region.role=="capital"})
	if include_player:
		for city:Dictionary in WorldSimulation.state.player_settlements:
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
		for city:Dictionary in WorldSimulation.state.player_settlements:
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
		var city:=WorldSimulation.settlements.settlement_record(city_id)
		var local:=WorldSimulation.settlements.city_resource_snapshot(city_id)
		var metrics:Dictionary=local.get("metrics",{})
		values={"population":float(local.get("population",0)),"production":float(metrics.get("material_capacity",0)),"logistics":float(metrics.get("logistics",0)),"supply":float(metrics.get("food_days",-1))}
		values.merge(_civic_observation(city_id))
		if bool(city.get("primary",false)):
			values["garrison"]=float(WorldSimulation.military.home_army.get("troops",0))
			values["fortification"]=clampf(float(WorldSimulation.military.settlement_defense.get("stage",0))/5.0,0,1)
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
		values={"population":float(region.population),"fortification":fort,"damage":float(region.damage),"garrison":system.land_military_population(civ)*float(region.strategic_weight)*(.72+fort)*(.82+float(civ.logistics)*.36),"production":float(civ.production)*(1-float(region.damage)*.5),"logistics":float(civ.logistics)*(1-float(region.damage)*.3),"supply":float(civ.food_days)}
		if bool(civ.get("shared_rules",false)):
			var local:Dictionary=region.get("local_metrics",{})
			values={"population":float(region.population),"fortification":fort,"damage":float(region.damage),"garrison":int(region.get("garrison",0)),"production":float(local.get("material_capacity",0)),"logistics":float(local.get("logistics",0)),"supply":float(local.get("food_days",0))}
		if String(region.controller)=="player":
			for key in ["garrison","production","logistics","supply"]: values.erase(key)
		elif bool(civ.get("shared_rules",false)) and WorldSimulation.actors.has(String(civ.id)) and region.has("local_city_id"):
			values.merge(WorldSimulation.scoped(String(civ.id),func()->Dictionary:return _civic_observation(String(region.local_city_id))))
		else:
			# Legacy societies have indices, but no city-level GDP ledger.
			values["science"]=float(civ.get("knowledge",0))
			values["health"]=float(civ.get("health",0))
		place["controller"]=String(region.controller)
	place["values"]=values
	return place

func _civic_observation(city_id:String)->Dictionary:
	return WorldSimulation.settlements.with_city_resources(city_id,func()->Dictionary:
		return WorldSimulation.settlements.with_local_population(func()->Dictionary:
			var state:=WorldSimulation.state
			var science:=CivilizationIndicators.science(state)
			var health:=CivilizationIndicators.health(state,WorldSimulation.discovery)
			return {"gdp":CivilizationIndicators.economy(state).gdp,"science_capacity":science.capacity,"education":science.education,"life_expectancy":health.life_expectancy,"infant_mortality":health.infant_mortality_per_1000}))

func capture(observer:String,city_id:String,quality:float,day:int,source:String,reference:String,observation_days:int=1)->Dictionary:
	var actual:=truth(city_id)
	if actual.is_empty() or actual.civ_id==observer: return {}
	quality=clampf(quality,0, .9)
	var fields:Dictionary={}
	for key:String in FIELDS:
		if quality<float(FIELDS[key].threshold) or not actual.values.has(key) or float(actual.values[key])<0: continue
		var value:=float(actual.values[key])
		var rng:=RandomNumberGenerator.new(); rng.seed=hash(observer+city_id+key+reference)^day^WorldSimulation.state.world_seed
		# Repeated days of physically present observation improve counting, not
		# days spent travelling. Stores remain harder to assess than inhabitants.
		var days:=clampi(observation_days,1,366)
		var error:=maxf(.035,lerpf(.65,.16,quality)/sqrt(float(days))) if key=="population" else maxf(.10,lerpf(.65,.16,quality)/pow(float(days),.25))
		var quantum:=.025 if FIELDS[key].unit=="capacity" else .1 if key=="science_capacity" else maxf(1,pow(10,floor(log(maxf(1,value))/log(10))-2))
		var width:=maxf(quantum,value*error)
		var center:=value+rng.randf_range(-.3,.3)*width
		var low:=maxf(0,floor((center-width)/quantum)*quantum)
		var high:float=ceil((center+width)/quantum)*quantum
		if FIELDS[key].unit=="capacity": high=minf(1,high)
		fields[key]={"low":low,"high":high,"observed_day":day,"quality":quality,"source":source,"reference":reference,"observation_days":clampi(observation_days,1,366)}
	return {"city_id":city_id,"civ_id":String(actual.civ_id) if quality>=.35 else "","name":String(actual.name) if quality>=.35 else "Unidentified settlement","position":actual.position.duplicate(true),"controller":String(actual.controller) if quality>=.35 else "","observed_day":day,"reported_day":day,"quality":quality,"source":source,"reference":reference,"observation_days":clampi(observation_days,1,366),"fields":fields}

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
	for field:Dictionary in next.fields.values():field["reported_day"]=day
	if not previous.is_empty():
		if int(previous.observed_day)>int(next.observed_day): return
		if next.civ_id=="": next.civ_id=previous.civ_id; next.name=previous.name; next.controller=previous.controller
		for field:String in previous.fields:
			if not next.fields.has(field):
				next.fields[field]=previous.fields[field].duplicate(true)
				if not next.fields[field].has("reported_day"):next.fields[field]["reported_day"]=int(previous.reported_day)
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
	var today:=int(WorldSimulation.state.elapsed_days) if day<0 else day
	result["age_days"]=maxi(0,today-int(value.observed_day)) if int(value.observed_day)>=0 else -1
	result["freshness"]="date unknown" if int(value.observed_day)<0 else ("recent" if int(result.age_days)<=30 else ("aging" if int(result.age_days)<=180 else "stale"))
	for key:String in result.fields:
		var field:Dictionary=result.fields[key]
		var age:=maxi(0,today-int(field.observed_day))
		# Original evidence stays intact. This planning band is an unverified
		# projection, with separate rates for residents, troops, stores and fabric.
		field["observed_low"]=float(field.low);field["observed_high"]=float(field.high)
		var rate:float={"population":.20,"garrison":2.0,"supply":4.0,"fortification":.15,"production":.40,"logistics":.20,"damage":.50,"science":.20,"health":.40,"gdp":.40,"science_capacity":.20,"education":.20,"life_expectancy":.10,"infant_mortality":.40}[key]
		var center:float=(float(field.low)+float(field.high))*.5
		var scale:=1.0 if FIELDS[key].unit=="capacity" else maxf(1,center)
		var drift:=scale*rate*minf(3.0,float(age)/365.0)
		field.low=maxf(0,float(field.low)-drift)
		field.high=float(field.high)+drift
		if FIELDS[key].unit=="capacity": field.high=minf(1,field.high)
		field["age_days"]=age; field["stale"]=age>180
	return result

func known_cities(observer:String="player",civ_id:String="",age_estimates:bool=true,center:Vector2=Vector2.INF,radius:float=INF)->Array[Dictionary]:
	# Geometry depicts the last observation. Its size must not grow merely because
	# uncertainty widens with time; ordinary reports still use aged estimates.
	var result:Array[Dictionary]=[]
	var book:Dictionary=records.get(observer,{})
	for id:String in book:
		var value:Dictionary=book[id]
		# Map callers reject distant records before copying their report histories.
		if is_finite(radius):
			var location:Dictionary=value.get("position",{})
			if Vector2(float(location.get("x",0)),float(location.get("z",0))).distance_squared_to(center)>radius*radius:continue
		if civ_id=="" or value.civ_id==civ_id or value.controller==civ_id:
			result.append(known(observer,id) if age_estimates else value.duplicate(true))
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
			publish("player",location_record({"city_id":id,"civ_id":String(civ.id),"name":"Reported home of %s" % String(civ.name),"position":relation.home_position},int(relation.get("last_observed_day",-1)),String(relation.get("home_location_source","earlier location report")),"home:"+String(civ.id)),int(WorldSimulation.state.elapsed_days))

func migrate()->void:
	seed_known_homes()
	var primary:=primary_id("player")
	if primary=="": return
	for civ:Dictionary in system.civilizations:
		var relation:Dictionary=civ.player_relation
		if float(relation.get("rival_player_trace_confidence",0))<.9 or "direct" not in String(relation.get("rival_player_trace_source","")): continue
		var position:Dictionary=relation.get("rival_player_trace_center",{})
		if valid_point(position): publish(String(civ.id),location_record({"city_id":primary,"civ_id":"player","name":"Reported player settlement","position":position},int(relation.get("rival_player_trace_day",-1)),"legacy returned direct encounter","legacy"),int(WorldSimulation.state.elapsed_days))

## `places` lets one sampling pass reuse a single sites() list; staging only
## records observations and never changes the cities that list is built from.
func stage(mission:Dictionary,observer:String,position:Vector2,quality:float,day:int,reference:String,places:Array=[])->void:
	if not mission.has("city_observations"): mission["city_observations"]={}
	for place:Dictionary in (places if not places.is_empty() else sites()):
		if place.civ_id==observer: continue
		if position.distance_to(vector(place.position))>SIGHT_RADIUS: continue
		var prior:Dictionary=mission.city_observations.get(place.city_id,{})
		if int(prior.get("observed_day",-1))>=day:continue
		var days:=mini(366,int(prior.get("observation_days",0))+1)
		var practiced:=clampf(quality+.18*(1.0-exp(-float(days-1)/10.0)),0,.9)
		var observation:=capture(observer,place.city_id,practiced,day,"physical reconnaissance",reference,days)
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

func mission_position(mission:Dictionary,day:float)->Vector2:
	var start:=float(mission.get("start_day",day))
	var end:=float(mission.get("actual_return_day",mission.get("return_day",start+1)))
	var total:=maxf(1,end-start)
	var elapsed:=clampf(day-start,0,total)
	# Older active missions retain their original timing; new targeted missions
	# persist the travel allowance from their dispatch quote.
	if bool(mission.get("circuit",false)) and mission.get("route_status","")!="turning_back":return route_position(mission.get("route",[]),elapsed/total)
	var leg:=clampf(float(mission.get("travel_leg_days",total*.5)),.5,total*.5)
	if mission.get("route_status","")=="turning_back":leg=total*.5
	var fraction:=elapsed/leg if elapsed<leg else (1.0 if elapsed<=total-leg else (total-elapsed)/leg)
	return route_position(mission.get("route",[]),fraction)

func sample_missions(day:int)->void:
	var places:Array=[]
	for mission:Dictionary in system.scout_missions:
		var start:=int(mission.start_day); var end:=int(mission.get("actual_return_day",mission.return_day))
		if day<start or day>=end: continue
		if places.is_empty():places=sites()
		stage(mission,"player",mission_position(mission,day),.45+clampf(WorldSimulation.state.combined_intelligence,0,1)*.4+(.15 if mission.get("target_kind")=="observe_city" else 0),day,"scout:%s" % str(mission.mission_id),places)
	for formation:Dictionary in system.foreign_formations:
		if formation.get("kind")!="scout" or not system._foreign_scout_is_active(formation,day): continue
		var due:=float(formation.depart_day)+float(formation.leg_days)*2
		if float(day)>=due: continue
		var index:int=system._civilization_index(String(formation.civ_id))
		if index<0: continue
		var civ:Dictionary=system.civilizations[index]
		if places.is_empty():places=sites()
		stage(formation,String(civ.id),system._foreign_formation_position(formation,day),.45+float(civ.knowledge)*.4,day,"scout:%s:%s" % [String(formation.id),str(formation.depart_day)],places)

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
	if not WorldSimulation.state.settlement_site_committed: return
	var positions:Array[Vector2]=[]
	for place:Dictionary in sites():
		if place.civ_id=="player": positions.append(vector(place.position))
	for place:Dictionary in sites(false):
		for position:Vector2 in positions:
			if position.distance_to(vector(place.position))<=SIGHT_RADIUS:
				publish("player",capture("player",place.city_id,.45+clampf(WorldSimulation.state.combined_intelligence,0,1)*.4,day,"local observation","lookouts"),day); break

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
			description="%s–%s %s · observed day %d%s" % [str(roundi(float(field.get("observed_low",field.low))*scale)),str(roundi(float(field.get("observed_high",field.high))*scale)),"%" if scale>1 else String(FIELDS[key].unit),int(field.observed_day)," · stale" if bool(field.stale) else ""]
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
	if value.has("observation_days") and (not number(value.observation_days) or value.observation_days<1 or value.observation_days>366):return false
	for key in value.fields:
		var field:Variant=value.fields[key]
		if not FIELDS.has(key) or not field is Dictionary or not field.has_all(["low","high","observed_day","quality","source","reference"]): return false
		if field.has("observation_days") and (not number(field.observation_days) or field.observation_days<1 or field.observation_days>366):return false
		for metric:String in ["low","high","observed_day","quality"]:
			if not number(field[metric]): return false
		if field.has("reported_day") and (not number(field.reported_day) or field.reported_day<field.observed_day):return false
		if field.low<0 or field.high<field.low or field.high>1e15 or field.observed_day<0 or field.quality<0 or field.quality>1 or not field.source is String or field.source.length()>200 or not field.reference is String or field.reference.length()>200: return false
	return true
func validate(value:Variant)->bool:
	if not value is Dictionary or value.size()>MAX_OBSERVERS: return false
	for observer in value:
		if not observer is String or observer.length()>80 or not value[observer] is Dictionary or value[observer].size()>MAX_CITIES: return false
		for city_id in value[observer]:
			if not valid_observation(value[observer][city_id]) or city_id!=value[observer][city_id].city_id: return false
	return true
