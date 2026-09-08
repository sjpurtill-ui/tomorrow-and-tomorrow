extends RefCounted
## Fleets and wings share the campaign's clock, population and equipment stores.
const C=preload("res://scripts/joint_force_catalog.gd")
const MISSIONS:Dictionary={
	"navy":{"hold":"Hold in port","patrol":"Patrol","strike_force":"Strike force","convoy_raiding":"Convoy raiding","convoy_escort":"Convoy escort","invasion_support":"Naval invasion support"},
	"air":{"hold":"Stand down","air_superiority":"Air superiority","interception":"Interception","close_air_support":"Close air support","logistics_strike":"Logistics strike","strategic_bombing":"Strategic bombing","naval_strike":"Naval strike","reconnaissance":"Reconnaissance","air_supply":"Air supply"}}
const REGION_KM:=500.0
const MAX_FORCES:=128
var host:Node
var state:Dictionary={"bases":[],"forces":[],"contacts":{},"events":[],"convoys":[],"next_id":1,"last_day":-1}
func _init(campaign:Node)->void:host=campaign
func reset()->void:state={"bases":[],"forces":[],"contacts":{},"events":[],"convoys":[],"next_id":1,"last_day":-1}
func personnel()->int:
	var total:=0
	for force:Dictionary in state.forces:
		if String(force.owner)=="player":total+=crew(force)
	return total
func crew(force:Dictionary)->int:
	var total:=0
	for id:String in force.units:total+=int(force.units[id])*int(C.UNITS[id].crew)
	return total
func base(id:int)->Dictionary:
	for value:Dictionary in state.bases:
		if int(value.id)==id:return value
	return {}
func force(id:int)->Dictionary:
	for value:Dictionary in state.forces:
		if int(value.id)==id:return value
	return {}
func _id()->int:
	var id:=int(state.next_id);state.next_id=id+1;return id
func region_at(point:Vector2,domain:String)->Dictionary:
	var x:=floori(point.x/REGION_KM);var z:=floori(point.y/REGION_KM)
	return {"id":"%s:%d:%d" % [domain,x,z],"domain":domain,"name":"%s %d / %d" % ["Sea region" if domain=="navy" else "Air region",x,z],"position":{"x":(x+.5)*REGION_KM,"z":(z+.5)*REGION_KM}}
func point(record:Dictionary)->Vector2:return Vector2(float(record.position.x),float(record.position.z))
func known_regions(domain:String)->Array:
	var result:Dictionary={}
	var places:Array=[]
	for city:Dictionary in GameState.player_settlements:
		var position:Vector2=city.get("position",Vector2.ZERO);places.append(position)
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player","",false):places.append(point(city))
	for location:Vector2 in places:
		for x in range(-1,2):
			for z in range(-1,2):
				var region:=region_at(location+Vector2(x,z)*REGION_KM,domain)
				if domain=="navy" and not _has_water(point(region)):continue
				result[region.id]=region
	return result.values().slice(0,128)
func _has_water(center:Vector2)->bool:
	if not CivilizationSystem.scout_land_authority.is_valid():return false
	for offset:Vector2 in [Vector2.ZERO,Vector2(200,0),Vector2(-200,0),Vector2(0,200),Vector2(0,-200)]:
		if not CivilizationSystem._scout_land_at(center+offset):return true
	return false
func coastal_site(city:Dictionary)->Dictionary:
	if not CivilizationSystem.scout_land_authority.is_valid():return {"error":"Return to the world map so coastlines can be checked."}
	var origin:Vector2=city.get("position",Vector2.ZERO)
	for radius:float in [.1,.5,1.0,2.0,5.0]:
		for direction in 32:
			var location:=origin+Vector2.from_angle(TAU*float(direction)/32.0)*radius
			if not CivilizationSystem._scout_land_at(location):return {"position":{"x":location.x,"z":location.y}}
	return {"error":"This city has no coast within 5 km. Choose a coastal city for a naval base."}
func build_base(city_id:String,domain:String)->Dictionary:
	if domain not in MISSIONS:return {"error":"Choose a naval base or airfield."}
	var city:=SettlementModel.settlement_record(city_id)
	if city.is_empty() or not String(city.get("occupied_by","")).is_empty():return {"error":"Choose an unoccupied city you own."}
	for existing:Dictionary in state.bases:
		if existing.city_id==city_id and existing.domain==domain:return {"error":"This city already has this base or construction project."}
	var gate:Dictionary=host._knowledge_gate("river_craft" if domain=="navy" else "aerostat_observation",.10)
	if not bool(gate.unlocked):return {"error":String(gate.reason)}
	var location:Vector2=city.get("position",Vector2.ZERO)
	if domain=="navy":
		var site:=coastal_site(city)
		if site.has("error"):return site
		location=point(site)
	var costs:Dictionary={"Timber":50.0,"Stone":30.0} if domain=="navy" else {"Timber":30.0,"Stone":60.0,"Iron Ore":10.0}
	for material:String in costs:
		if float(GameState.resource_stockpiles.get(material,0))<float(costs[material]):return {"error":"Base construction needs %.0f %s; %.0f in stores." % [costs[material],ResourceSystem.display_name(material),float(GameState.resource_stockpiles.get(material,0))]}
	for material:String in costs:GameState.resource_stockpiles[material]-=costs[material]
	var record:={"id":_id(),"owner":"player","city_id":city_id,"name":String(city.get("name","City"))+(" Naval Base" if domain=="navy" else " Airfield"),"domain":domain,"position":{"x":location.x,"z":location.y},"capacity":100 if domain=="air" else 20,"condition":1.0,"construction_work":0.0,"required_work":30.0}
	state.bases.append(record)
	return {"ok":true,"message":"Base construction started. Construction workers complete 30 work-days before crews can operate here."}
func base_ready(record:Dictionary)->bool:
	return not record.is_empty() and float(record.construction_work)>=float(record.required_work) and float(record.condition)>.1
func base_owned(record:Dictionary,owner:String="player")->bool:
	if record.is_empty() or String(record.owner)!=owner:return false
	if owner!="player":return true
	var city:=SettlementModel.settlement_record(String(record.city_id))
	return not city.is_empty() and String(city.get("occupied_by","")).is_empty()
func available_base(domain:String)->bool:
	for record:Dictionary in state.bases:
		if record.domain==domain and base_ready(record) and base_owned(record):return true
	return false
func commission(base_id:int,type_id:String,count:int,name:String="")->Dictionary:
	if not C.UNITS.has(type_id) or count<=0 or count>100:return {"error":"Select a valid hull or aircraft count (1–100)."}
	if state.forces.size()>=MAX_FORCES:return {"error":"The force command limit is reached."}
	var record:=base(base_id);var unit:Dictionary=C.UNITS[type_id]
	if not base_ready(record) or not base_owned(record) or String(record.domain)!=String(unit.domain):return {"error":"Choose an operational owned base for this force."}
	var gate:Dictionary=host._knowledge_gate(String(unit.gate),.10)
	if not bool(gate.unlocked):return {"error":String(gate.reason)}
	if int(host.military_inventory.get(String(unit.equipment),0))<count:return {"error":"Produce %d %s first; only %d in reserve." % [count,unit.label,int(host.military_inventory.get(String(unit.equipment),0))]}
	var needed:=count*int(unit.crew)
	if needed>maxi(0,host.recruitment_capacity()-host._mobilized_count()):return {"error":"This force needs %d crew; %d military service places are free." % [needed,maxi(0,host.recruitment_capacity()-host._mobilized_count())]}
	host.military_inventory[String(unit.equipment)]-=count
	var groups:Dictionary={};groups[type_id]=count
	var entry:={"id":_id(),"owner":"player","name":name if name!="" else String(unit.label)+(" Task Force" if unit.domain=="navy" else " Wing"),"domain":unit.domain,"base_id":base_id,"units":groups,"authorized":groups.duplicate(true),"mission":"hold","region":{},"status":"Training crews","training":0.0,"condition":1.0,"experience":0.0,"efficiency":0.0,"auto_replace":true,"repair_threshold":.6,"fuel_used":0,"loss_fraction":0.0,"damage":0.0}
	state.forces.append(entry)
	return {"ok":true,"id":entry.id,"message":"Crews and equipment committed. Training begins at the base; choose a region and mission when ready."}
func missions_for(record:Dictionary)->Array[String]:
	var result:Array[String]=["hold"]
	if record.is_empty():return result
	for id:String in record.units:
		var preferred:=String(C.UNITS[id].mission)
		if preferred not in result:result.append(preferred)
		var extra:Array=[]
		if record.domain=="navy":
			if id in ["fleet_support","amphibious_ship"]:extra=["convoy_escort"]
			elif id in ["submarine","nuclear_submarine"]:extra=["patrol","convoy_raiding"]
			else:extra=["patrol","strike_force","convoy_raiding","convoy_escort"]
		elif id in ["fighter","heavy_fighter","jet_fighter"]:extra=["air_superiority","interception"]
		elif id in ["tactical_bomber","jet_bomber"]:extra=["strategic_bombing","logistics_strike","close_air_support"]
		for mission:String in extra:
			if mission not in result:result.append(mission)
	return result
func assign(id:int,region:Dictionary,mission:String)->Dictionary:
	var record:=force(id)
	if record.is_empty() or record.owner!="player":return {"error":"Select your task force or wing."}
	if mission not in missions_for(record):return {"error":"This force is not equipped for that mission."}
	if mission!="hold":
		if region.get("domain","")!=record.domain or not region.has("position"):return {"error":"Choose the matching sea or air region."}
		var origin:=base(int(record.base_id))
		if not base_owned(origin):return {"error":"Your home base is unavailable."}
		if point(origin).distance_to(point(region))>range_km(record)+REGION_KM*.5:return {"error":"This region is outside the force's range from its home base."}
		if record.domain=="navy" and not _has_water(point(region)):return {"error":"Naval missions need a sea region."}
	record.region=region.duplicate(true);record.mission=mission
	return {"ok":true,"message":"Mission assigned. Crews handle operations; the force reports range, training, fuel or repair blockers here."}
func range_km(record:Dictionary)->float:
	var reach:=INF
	for id:String in record.units:
		if int(record.units[id])>0:reach=minf(reach,float(C.UNITS[id].range_km))
	return 0.0 if is_inf(reach) else reach
func configure(id:int,replace:bool,threshold:float)->Dictionary:
	var record:=force(id)
	if record.is_empty() or record.owner!="player":return {"error":"Select your force."}
	record.auto_replace=replace;record.repair_threshold=clampf(threshold,.2,.9)
	return {"ok":true,"message":"Replacement and repair policy updated."}
func disband(id:int)->Dictionary:
	var record:=force(id)
	if record.is_empty() or record.owner!="player":return {"error":"Select your force."}
	if record.mission!="hold":return {"error":"Stand the force down before disbanding."}
	for type_id:String in record.units:
		var item:=String(C.UNITS[type_id].equipment);host.military_inventory[item]=int(host.military_inventory.get(item,0))+int(record.units[type_id])
	state.forces.erase(record)
	return {"ok":true,"message":"Surviving equipment returned to reserve and crews released from service."}
func _hostile(a:String,b:String)->bool:
	if a==b:return false
	if a!="player" and b!="player":return false
	var index:=CivilizationSystem._civilization_index(b if a=="player" else a)
	return index>=0 and bool(CivilizationSystem.civilizations[index].player_relation.at_war)
func _power(record:Dictionary,key:String)->float:
	var value:=0.0
	for id:String in record.units:value+=float(C.UNITS[id].get(key,0))*int(record.units[id])
	return value*float(record.condition)*(.5+.5*float(record.training))*float(record.efficiency)
func _event(message:String)->void:
	state.events.push_front({"day":int(state.last_day),"text":message})
	if state.events.size()>80:state.events.resize(80)
func _losses(record:Dictionary,damage:float)->void:
	record.damage=float(record.damage)+maxf(0,damage)
	record.condition=maxf(.1,float(record.condition)-damage*.015)
	for id:String in record.units:
		var durability:=maxf(1.0,float(C.UNITS[id].defense)*3.0)
		var lost:=mini(int(record.units[id]),floori(float(record.damage)/durability))
		if lost<=0:continue
		record.units[id]-=lost;record.damage-=lost*durability
		var deaths:=lost*int(C.UNITS[id].crew)
		if record.owner=="player":GameState.register_population_deaths(deaths,"Naval or air combat")
		else:
			var index:=CivilizationSystem._civilization_index(String(record.owner))
			if index>=0:CivilizationSystem.civilizations[index]=CivilizationSystem._remove_foreign_scout_population(CivilizationSystem.civilizations[index],deaths,true)
		_event("%s lost %d %s." % [record.name,lost,C.UNITS[id].label])
func _replace(record:Dictionary)->void:
	if record.owner!="player" or not bool(record.auto_replace):return
	for id:String in record.authorized:
		var unit:Dictionary=C.UNITS[id]
		var count:=mini(maxi(0,int(record.authorized[id])-int(record.units.get(id,0))),int(host.military_inventory.get(String(unit.equipment),0)))
		count=mini(count,maxi(0,host.recruitment_capacity()-host._mobilized_count())/maxi(1,int(unit.crew)))
		if count<=0:continue
		host.military_inventory[String(unit.equipment)]-=count;record.units[id]=int(record.units.get(id,0))+count
		record.training=minf(float(record.training),.7)
func advance(day:int)->void:
	if day<=int(state.last_day):return
	state.last_day=day
	for record:Dictionary in state.bases:
		if not base_owned(record):continue
		if not base_ready(record):
			var projects:=0
			for project:Dictionary in state.bases:
				if base_owned(project) and not base_ready(project):projects+=1
			record.construction_work=minf(float(record.required_work),float(record.construction_work)+maxf(0,GameState.effective_workers("Construction"))*.1/maxi(1,projects))
	for record:Dictionary in state.forces:
		record.efficiency=0.0;record.fuel_used=0
		var origin:=base(int(record.base_id))
		if not base_ready(origin) or not base_owned(origin,String(record.owner)):record.status="Home base unavailable";continue
		_replace(record)
		if crew(record)<=0:record.status="Waiting for replacement equipment and crew";continue
		if float(record.training)<1.0:
			var days:=1.0
			for id:String in record.units:days=maxf(days,float(C.UNITS[id].training_days))
			record.training=minf(1,float(record.training)+1.0/days);record.status="Training crews · %d%%" % roundi(float(record.training)*100);continue
		if float(record.condition)<float(record.repair_threshold):
			if record.owner=="player" and float(GameState.resource_stockpiles.get("Iron Ore",0))>=.1:
				GameState.resource_stockpiles["Iron Ore"]-=.1;record.condition=minf(1,float(record.condition)+.025)
			record.status="Repairing at base";continue
		if record.mission=="hold" or record.region.is_empty():record.status="Standing by at base";continue
		if point(origin).distance_to(point(record.region))>range_km(record)+REGION_KM*.5:record.status="Region outside base range";continue
		if record.mission=="strike_force" and not _has_contact(record):record.status="In port · waiting for a patrol contact";continue
		var fuel:=0
		var hardware:=0
		for id:String in record.units:
			fuel+=int(C.UNITS[id].fuel_per_day)*int(record.units[id]);hardware+=int(record.units[id])
		if record.owner=="player" and int(host.military_consumables.get("fuel",0))<fuel:record.status="No fuel · produce fuel or stand down other missions";continue
		if record.owner=="player":host.military_consumables.fuel=int(host.military_consumables.get("fuel",0))-fuel
		record.fuel_used=fuel
		var stationed:=0
		for other:Dictionary in state.forces:
			if other.base_id==record.base_id:
				for count in other.units.values():stationed+=int(count)
		var crowding:=minf(1,float(origin.capacity)/maxf(1,stationed))
		var distance:=point(origin).distance_to(point(record.region))
		var coverage:=clampf((range_km(record)-distance+REGION_KM*.5)/REGION_KM,.1,1)
		var climate:=PlanetEnvironment.profile_at(point(record.region))
		var weather:=clampf(FoodSystem._weather_yield_factor(climate,float(day)),.52,1.0)
		record.efficiency=crowding*coverage*weather*float(origin.condition)
		record.status="On mission · %d%% efficiency" % roundi(float(record.efficiency)*100)
		record.experience=minf(1,float(record.experience)+.001)
	_detect_and_fight()
	for key in state.contacts.keys():
		if day-int(state.contacts[key].day)>5:state.contacts.erase(key)
func _has_contact(record:Dictionary)->bool:
	for contact:Dictionary in state.contacts.values():
		if contact.observer==record.owner and contact.region==String(record.region.get("id","")) and int(state.last_day)-int(contact.day)<=2:return true
	return false
func _detect_and_fight()->void:
	for observer:Dictionary in state.forces:
		if float(observer.efficiency)<=0:continue
		for target:Dictionary in state.forces:
			if not _hostile(String(observer.owner),String(target.owner)) or target.region.is_empty() or observer.region.is_empty():continue
			if point(observer.region).distance_to(point(target.region))>REGION_KM*.1:continue
			if observer.domain=="navy" and target.domain=="air":continue
			var detected:=_power(observer,"detection")/(5.0+_power(target,"defense"))
			if float(posmod(int(state.last_day)+int(observer.id)*7+int(target.id)*13,100))/100.0>clampf(detected,.05,.95):continue
			state.contacts["%s:%d" % [observer.owner,target.id]]={"observer":observer.owner,"target":target.id,"region":observer.region.id,"day":state.last_day,"name":target.name}
			if observer.mission in ["patrol","reconnaissance","air_supply","convoy_escort","invasion_support"]:continue
			if observer.domain=="air" and target.domain=="navy" and observer.mission!="naval_strike":continue
			if observer.domain=="air" and target.domain=="air" and observer.mission not in ["air_superiority","interception"]:continue
			var defense:=maxf(1,_power(target,"defense"))
			_losses(target,_power(observer,"attack")/defense*.15)
func export_state()->Dictionary:return state.duplicate(true)
func import_state(payload:Dictionary)->void:
	reset()
	for key:String in state:
		if payload.has(key):state[key]=payload[key].duplicate(true) if payload[key] is Dictionary or payload[key] is Array else payload[key]
func validate(payload:Variant)->String:
	if not payload is Dictionary:return "Invalid joint-force state."
	if payload.is_empty():return ""
	for key in state:
		if not payload.has(key):return "Incomplete joint-force state: "+String(key)
	for key in ["bases","forces","events","convoys"]:
		if not payload.get(key,[]) is Array:return "Invalid joint-force list."
	if not payload.contacts is Dictionary:return "Invalid contact reports."
	if not _whole_number(payload.next_id,1) or not _whole_number(payload.last_day,-1):return "Invalid joint-force clock or identifier."
	if payload.bases.size()>256 or payload.contacts.size()>MAX_FORCES*MAX_FORCES or payload.events.size()>80:return "Joint-force state exceeds bounded limits."
	if payload.get("forces",[]).size()>MAX_FORCES:return "Too many joint forces."
	var ids:Dictionary={}
	var bases:Dictionary={}
	for record in payload.bases:
		if not record is Dictionary:return "Invalid base."
		for key in ["id","owner","city_id","name","domain","position","capacity","condition","construction_work","required_work"]:
			if not record.has(key):return "Incomplete base."
		if not _whole_number(record.id,1) or ids.has(record.id) or int(record.id)>=int(payload.next_id):return "Invalid base identifier."
		if record.domain not in MISSIONS or not _valid_position(record.position):return "Invalid base domain or position."
		for key in ["owner","city_id","name"]:
			if not record[key] is String or record[key].is_empty():return "Invalid base identity."
		for key in ["capacity","condition","construction_work","required_work"]:
			if not _finite_nonnegative(record[key]):return "Invalid base capacity or condition."
		if float(record.capacity)<1 or float(record.required_work)<=0 or float(record.condition)>1:return "Invalid base limits."
		ids[record.id]=true;bases[record.id]=record
	for record in payload.get("forces",[]):
		if not record is Dictionary or record.get("domain","") not in MISSIONS or not record.get("units",{}) is Dictionary:return "Invalid fleet or wing."
		for key in ["id","owner","name","base_id","authorized","mission","region","status","training","condition","experience","efficiency","auto_replace","repair_threshold","fuel_used","damage"]:
			if not record.has(key):return "Incomplete fleet or wing."
		if not _whole_number(record.id,1) or ids.has(record.id) or int(record.id)>=int(payload.next_id):return "Invalid force identifier."
		if not bases.has(record.base_id) or bases[record.base_id].domain!=record.domain or bases[record.base_id].owner!=record.owner:return "Invalid force home base."
		ids[record.id]=true
		if not record.authorized is Dictionary or record.authorized.size()!=record.units.size():return "Invalid force establishment."
		if not record.auto_replace is bool or not _finite_nonnegative(record.repair_threshold) or float(record.repair_threshold)>1:return "Invalid repair policy."
		for key in ["owner","name","status"]:
			if not record[key] is String:return "Invalid force identity."
		if record.mission not in MISSIONS[record.domain] or not record.region is Dictionary:return "Invalid force mission."
		if record.mission!="hold" and (record.region.get("domain","")!=record.domain or not _valid_position(record.region.get("position",{})) or not record.region.get("id",null) is String):return "Invalid mission region."
		for id in record.units:
			if not C.UNITS.has(id) or C.UNITS[id].domain!=record.domain or not _whole_number(record.units[id],0):return "Invalid joint-force equipment."
			if not _whole_number(record.authorized.get(id,-1),0) or int(record.authorized[id])<int(record.units[id]) or int(record.authorized[id])>100:return "Invalid authorized equipment."
		for field in ["training","condition","efficiency","experience","damage"]:
			var value:Variant=record.get(field,0)
			if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0:return "Invalid joint-force condition."
			if field!="damage" and float(value)>1:return "Invalid joint-force readiness."
	for contact in payload.contacts.values():
		if not contact is Dictionary:return "Invalid contact."
		for key in ["observer","target","region","day","name"]:
			if not contact.has(key):return "Incomplete contact."
		if not _whole_number(contact.day,0) or not _whole_number(contact.target,1):return "Invalid contact date or target."
	return ""

func _whole_number(value:Variant,minimum:int)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=minimum and floor(float(value))==float(value)
func _finite_nonnegative(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=0
func _valid_position(value:Variant)->bool:
	if not value is Dictionary:return false
	for key in ["x","z"]:
		var coordinate:Variant=value.get(key,null)
		if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)):return false
	return true
