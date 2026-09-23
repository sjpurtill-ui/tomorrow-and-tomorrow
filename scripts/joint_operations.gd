extends RefCounted
## Fleets and wings share the campaign's clock, population and equipment stores.
const B=preload("res://scripts/joint_battle.gd")
const C=preload("res://scripts/joint_force_catalog.gd")
const MISSIONS:Dictionary={
	"navy":{"hold":"Hold in port","patrol":"Patrol","strike_force":"Strike force","convoy_raiding":"Convoy raiding","convoy_escort":"Convoy escort","invasion_support":"Naval invasion support","transport":"Transport troops or supplies"},
	"air":{"hold":"Stand down","air_superiority":"Air superiority","interception":"Interception","close_air_support":"Close air support","logistics_strike":"Logistics strike","strategic_bombing":"Strategic bombing","naval_strike":"Naval strike","port_strike":"Port strike","reconnaissance":"Reconnaissance","air_supply":"Air supply","transport":"Transport troops"}}
const R=preload("res://scripts/joint_regions.gd")
const Dock=preload("res://scripts/naval_dock_service.gd")
const MAX_FORCES:=128
var geography=preload("res://scripts/joint_geography.gd").new()
var logistics=preload("res://scripts/joint_logistics.gd").new(self)
var effects=preload("res://scripts/joint_effects.gd").new(self)
var rival=preload("res://scripts/joint_rivals.gd").new(self)
var host:Node
var state:Dictionary={"bases":[],"forces":[],"contacts":{},"events":[],"convoys":[],"regions":[],"rival_orders":{},"next_id":1,"last_day":-1}
func _init(campaign:Node)->void:host=campaign
func reset()->void:
	geography.route_cache.clear()
	state={"bases":[],"forces":[],"contacts":{},"events":[],"convoys":[],"regions":[],"rival_orders":{},"next_id":1,"last_day":-1}
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
func region_at(location:Vector2,domain:String)->Dictionary:
	# A point query for local effects and transit exposure, never a world-grid region.
	return {"id":"point:%s:%s" % [domain,str(location)],"domain":domain,"name":"Local operating area","position":{"x":location.x,"z":location.y},"point_query":true}
func point(record:Dictionary)->Vector2:return Vector2(float(record.position.x),float(record.position.z))
func known_regions(domain:String)->Array:
	return state.regions.filter(func(region:Dictionary):return region.domain==domain and region.owner=="player")
func create_region(domain:String,vertices:Array,title:String="",owner:String="player")->Dictionary:
	if domain not in MISSIONS:return {"error":"Choose air or navy."}
	var error:=R.validate(vertices)
	if error!="":return {"error":error}
	if state.regions.size()>=R.MAX_REGIONS:return {"error":"The campaign already has 128 operating areas."}
	var region:={"id":"area:%d" % _id(),"domain":domain,"owner":owner,"name":title.strip_edges().left(80),"vertices":vertices.duplicate(true)}
	var center:=R.bounds(region).get_center()
	region.position={"x":center.x,"z":center.y}
	if region.name=="":region.name=("Sea area " if domain=="navy" else "Air area ")+str(state.regions.size()+1)
	if domain=="navy" and geography.sea_point(region,center).is_empty():return {"error":"Draw a sea area that includes navigable water."}
	state.regions.append(region)
	return {"ok":true,"region":region,"message":"Operating boundary saved. Assign a force and mission to this area."}
func remove_region(id:String)->Dictionary:
	for force:Dictionary in state.forces:
		if force.region.get("id","")==id:return {"error":"Stand down forces assigned to this area before deleting it."}
	for index in state.regions.size():
		if state.regions[index].id==id and state.regions[index].owner=="player":
			state.regions.remove_at(index);return {"ok":true,"message":"Operating area deleted."}
	return {"error":"Select one of your operating areas."}
func _has_water(center:Vector2)->bool:

	for offset:Vector2 in [Vector2.ZERO,Vector2(200,0),Vector2(-200,0),Vector2(0,200),Vector2(0,-200)]:
		if not geography.is_land(center+offset):return true
	return false
func coastal_site(city:Dictionary)->Dictionary:

	var origin:Vector2=city.get("position",Vector2.ZERO)
	for radius:float in [.1,.5,1.0,2.0,5.0]:
		for direction in 32:
			var location:=origin+Vector2.from_angle(TAU*float(direction)/32.0)*radius
			if not geography.is_land(location):return {"position":{"x":location.x,"z":location.y}}
	return {"error":"This city has no coast within 5 km. Choose a coastal city for a naval base."}
func build_base(city_id:String,domain:String)->Dictionary:
	if domain not in MISSIONS:return {"error":"Choose a naval base or airfield."}
	var city:=WorldSimulation.settlements.settlement_record(city_id)
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
	var paid:Dictionary=WorldSimulation.settlements.with_city_resources(city_id,func():
		for material:String in costs:
			if float(WorldSimulation.state.resource_stockpiles.get(material,0))<float(costs[material]):return {"error":"Base construction needs %.0f %s; %.0f in this city's stores." % [costs[material],WorldSimulation.resources.display_name(material),float(WorldSimulation.state.resource_stockpiles.get(material,0))]}
		for material:String in costs:WorldSimulation.state.resource_stockpiles[material]-=costs[material]
		return {"ok":true})
	if paid.has("error"):return paid
	var record:={"id":_id(),"owner":"player","city_id":city_id,"name":String(city.get("name","City"))+(" Naval Base" if domain=="navy" else " Airfield"),"domain":domain,"position":{"x":location.x,"z":location.y},"capacity":100 if domain=="air" else 20,"condition":1.0,"construction_work":0.0,"required_work":30.0}
	state.bases.append(record)
	return {"ok":true,"message":"Base construction started. Construction workers complete 30 work-days before crews can operate here."}
func base_ready(record:Dictionary)->bool:
	return not record.is_empty() and float(record.construction_work)>=float(record.required_work) and float(record.condition)>.1
func base_owned(record:Dictionary,owner:String="player")->bool:
	if record.is_empty() or String(record.owner)!=owner:return false
	if owner!="player":
		var truth:Dictionary=WorldSimulation.world.city_intelligence.truth(String(record.city_id))
		return not truth.is_empty() and String(truth.get("controller",truth.get("civ_id","")))==owner
	var city:=WorldSimulation.settlements.settlement_record(String(record.city_id))
	return not city.is_empty() and String(city.get("occupied_by","")).is_empty()
func available_base(domain:String)->bool:
	for record:Dictionary in state.bases:
		if record.domain==domain and base_ready(record) and base_owned(record):return true
	return false
func build_dock(base_id:int)->Dictionary:
	var port:=base(base_id)
	if not base_owned(port) or not base_ready(port):return {"error":"Choose an owned, completed naval port."}
	var known:Array=[]
	for id:String in ["dry_dock_services","hull_condition_surveys"]:
		if bool(host._knowledge_gate(id,.25).unlocked):known.append(id)
	var result:Dictionary=WorldSimulation.settlements.with_city_resources(String(port.city_id),func()->Dictionary:
		return Dock.begin(port,WorldSimulation.state.resource_stockpiles,known,int(WorldSimulation.state.elapsed_days)))
	if result.has("ok"):result.message="Dock construction started for canoe and ram-galley access; port construction crews share the work."
	return result

func commission_quote(base_id:int,type_id:String,count:int)->Dictionary:
	if not C.UNITS.has(type_id) or count<=0 or count>100:return {"error":"Select a valid hull or aircraft count (1–100)."}
	if state.forces.size()>=MAX_FORCES:return {"error":"The force command limit is reached."}
	var record:=base(base_id);var unit:Dictionary=C.UNITS[type_id]
	if not base_ready(record) or not base_owned(record) or String(record.domain)!=String(unit.domain):return {"error":"Choose an operational owned base for this force."}
	var gate:Dictionary=host._knowledge_gate(String(unit.gate),.10)
	if not bool(gate.unlocked):return {"error":String(gate.reason)}
	if int(host.military_inventory.get(String(unit.equipment),0))<count:return {"error":"Produce %d %s first; only %d in reserve." % [count,unit.label,int(host.military_inventory.get(String(unit.equipment),0))]}
	var needed:=count*int(unit.crew)
	if needed>maxi(0,host.recruitment_capacity()-host._mobilized_count()):return {"error":"This force needs %d crew; %d military service places are free." % [needed,maxi(0,host.recruitment_capacity()-host._mobilized_count())]}
	var policy:Dictionary=host.training_staff.policy(String(unit.domain))
	return {"ok":true,"crew":needed,"reserve":int(host.military_inventory.get(String(unit.equipment),0)),"training_days":ceili(host.training_staff.service_days(float(unit.training_days))/maxf(.001,float(policy.intake))) if policy.id!="suspended" else -1}

func commission(base_id:int,type_id:String,count:int,name:String="")->Dictionary:
	var quote:=commission_quote(base_id,type_id,count)
	if quote.has("error"):return quote
	var record:=base(base_id);var unit:Dictionary=C.UNITS[type_id]
	host.military_inventory[String(unit.equipment)]-=count
	var groups:Dictionary={};groups[type_id]=count
	var entry:={"id":_id(),"owner":"player","name":name if name!="" else String(unit.label)+(" Task Force" if unit.domain=="navy" else " Wing"),"domain":unit.domain,"base_id":base_id,"units":groups,"authorized":groups.duplicate(true),"mission":"hold","region":{},"status":"Training crews","training":0.0,"condition":1.0,"experience":0.0,"efficiency":0.0,"auto_replace":true,"repair_threshold":.6,"fuel_used":0,"loss_fraction":0.0,"damage":0.0}
	entry["position"]=record.position.duplicate(true);entry["route"]=[];entry["carrier_id"]=0;entry["fleet_id"]=entry.id;entry["regions"]=[]
	state.forces.append(entry)
	return {"ok":true,"id":entry.id,"message":"Crews and equipment committed. Training begins at the base; choose a region and mission when ready."}
func missions_for(record:Dictionary)->Array[String]:
	var result:Array[String]=["hold"]
	if record.is_empty():return result
	for id:String in record.units:
		if int(record.units[id])<=0:continue
		var preferred:=String(C.UNITS[id].mission)
		if preferred not in result:result.append(preferred)
		var extra:Array=[]
		if int(C.UNITS[id].get("cargo_capacity",0))>0 and "transport" not in result:result.append("transport")
		if record.domain=="navy":
			if id in ["fleet_support","amphibious_ship"]:extra=["convoy_escort"]
			elif id in ["submarine","nuclear_submarine"]:extra=["patrol","convoy_raiding"]
			else:extra=["patrol","strike_force","convoy_raiding","convoy_escort"]
		elif id in ["fighter","heavy_fighter","jet_fighter"]:extra=["air_superiority","interception"]
		elif id in ["tactical_bomber","jet_bomber"]:extra=["strategic_bombing","logistics_strike","close_air_support"]
		elif id=="naval_bomber":extra=["naval_strike","port_strike"]
		for mission:String in extra:
			if mission not in result:result.append(mission)
	return result
func assign(id:int,region:Dictionary,mission:String)->Dictionary:
	var record:=force(id)
	if record.is_empty() or record.owner!="player":return {"error":"Select your task force or wing."}
	if mission not in missions_for(record):return {"error":"This force is not equipped for that mission."}
	if logistics.busy(id):return {"error":"This force is carrying a convoy. Complete or recall that operation first."}
	if mission=="transport":return {"error":"Choose a destination and cargo through Transport; crews need a concrete embarkation order."}
	if not _valid_position(region.get("position",{})) and mission!="hold":return {"error":"Choose a valid region on the world map."}
	if mission!="hold":
		if region.get("domain","")!=record.domain or not region.has("position"):return {"error":"Choose the matching sea or air region."}
		var origin:=base(int(record.base_id))
		if not base_owned(origin):return {"error":"Your home base is unavailable."}
		if R.validate(region.get("vertices",[]))!="":return {"error":"Draw and finish an operating boundary first."}
		var carrier:=force(int(record.get("carrier_id",0)))
		var launch:=point(origin) if carrier.is_empty() else force_position(carrier)
		if R.coverage(region,launch,range_km(record))<=0:return {"error":"This area is outside the force's range from its base or carrier."}
	# Standing down a deck wing stops sorties without silently moving it to land.
	if mission=="hold" and record.domain=="air" and int(record.get("carrier_id",0))>0:
		record.mission="hold";record.region={};record.regions=[];record.route=[];record.pending_carrier_id=0
		record.status="Standing by on carrier deck"
		return {"ok":true,"message":"Sorties stopped. The wing remains aboard its carrier; use Rebase to transfer ashore."}
	var destination:=point(base(int(record.base_id)))
	if mission!="hold":
		destination=point(region)
		if record.domain=="navy":
			var water:=geography.sea_point(region,force_position(record))
			if water.is_empty():return {"error":"This region has no navigable water."}
			destination=preload("res://scripts/joint_geography.gd").unpack(water)
			if mission!="strike_force":
				var route:=set_route(record,destination)
				if route.has("error"):return route
	else:
		var route:=set_route(record,destination)
		if route.has("error"):return route
	if mission=="hold" and record.domain=="air":record.carrier_id=0;record.pending_carrier_id=0
	record.region=region.duplicate(true);record.mission=mission
	record.regions=[] if region.is_empty() else [region.duplicate(true)]
	record.mission_destination=preload("res://scripts/joint_geography.gd").pack(destination)
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
func organized_at_home(record:Dictionary)->bool:
	if record.is_empty() or record.mission!="hold" or not record.get("route",[]).is_empty() or logistics.busy(int(record.id)):return false
	if int(record.get("carrier_id",0))>0 or int(record.get("pending_carrier_id",0))>0:return false
	var home:=base(int(record.base_id))
	return base_ready(home) and base_owned(home,String(record.owner)) and force_position(record).distance_to(point(home))<2

func disband(id:int)->Dictionary:
	var record:=force(id)
	if record.is_empty() or record.owner!="player":return {"error":"Select your force."}
	if not organized_at_home(record):return {"error":"Return to an operational home base and stand down before disbanding. Carrier wings must rebase ashore."}
	for wing:Dictionary in state.forces:
		if int(wing.get("carrier_id",0))==id or int(wing.get("pending_carrier_id",0))==id:return {"error":"Transfer the attached or incoming air wings before disbanding this carrier task force."}
	for type_id:String in record.units:
		var item:=String(C.UNITS[type_id].equipment);host.military_inventory[item]=int(host.military_inventory.get(item,0))+int(record.units[type_id])
	state.forces.erase(record)
	return {"ok":true,"message":"Surviving equipment returned to reserve and crews released from service."}
func _hostile(a:String,b:String)->bool:
	if a==b:return false
	if a!="player" and b!="player":
		var index:=WorldSimulation.world._civilization_index(a)
		return index>=0 and bool(WorldSimulation.world.civilizations[index].get("relations",{}).get(b,{}).get("at_war",false))
	var index:=WorldSimulation.world._civilization_index(b if a=="player" else a)
	return index>=0 and bool(WorldSimulation.world.civilizations[index].player_relation.get("at_war",false))
func _power(record:Dictionary,key:String)->float:
	var value:=0.0
	for id:String in record.units:value+=float(C.UNITS[id].get(key,0))*int(record.units[id])
	return value*float(record.condition)*(.5+.5*float(record.training))*(.7+.3*float(record.get("proficiency",.45)))*float(record.efficiency)
func _event(message:String,domain:String="")->void:
	state.events.push_front({"day":int(state.last_day),"text":message,"domain":domain})
	if state.events.size()>80:state.events.resize(80)
func _losses(record:Dictionary,damage:float)->void:
	record.damage=float(record.damage)+maxf(0,damage)
	record.condition=maxf(.1,float(record.condition)-damage*.015)
	for id:String in record.units:
		var durability:=maxf(1.0,float(C.UNITS[id].defense)*3.0)
		var lost:=mini(int(record.units[id]),floori(float(record.damage)/durability))
		if lost<=0:continue
		record.units[id]-=lost;record.damage-=lost*durability
		var deaths:=0 if id in ["recon_drone","strike_drone"] else lost*int(C.UNITS[id].crew)
		if record.owner=="player":WorldSimulation.state.register_population_deaths(deaths,"Killed in battle")
		else:
			var index:=WorldSimulation.world._civilization_index(String(record.owner))
			if index>=0:WorldSimulation.world.civilizations[index]=WorldSimulation.world._remove_foreign_scout_population(WorldSimulation.world.civilizations[index],deaths,true)
		if record.owner=="player" or state.contacts.has("player:%d" % int(record.id)):_event("%s lost %d %s." % [record.name,lost,C.UNITS[id].label],String(record.domain))
func _replace(record:Dictionary)->void:
	if record.owner!="player" or not bool(record.auto_replace):return
	for id:String in record.authorized:
		var unit:Dictionary=C.UNITS[id]
		var count:=mini(maxi(0,int(record.authorized[id])-int(record.units.get(id,0))),int(host.military_inventory.get(String(unit.equipment),0)))
		count=mini(count,maxi(0,host.recruitment_capacity()-host._mobilized_count())/maxi(1,int(unit.crew)))
		if count<=0:continue
		host.military_inventory[String(unit.equipment)]-=count;record.units[id]=int(record.units.get(id,0))+count
		record.training=minf(float(record.training),.7)
func construction_share(city_id:String="")->float:
	var selected:=city_id
	if selected.is_empty():
		for city:Dictionary in WorldSimulation.state.player_settlements:
			if bool(city.get("primary",false)):selected=String(city.id);break
	for record:Dictionary in state.bases:
		if record.owner=="player" and record.city_id==selected and base_owned(record) and (float(record.construction_work)<float(record.required_work) or Dock.building(record)):return .25
	return 0.0

func force_position(record:Dictionary)->Vector2:
	var carrier:=force(int(record.get("carrier_id",0)))
	if not carrier.is_empty():return force_position(carrier)
	return preload("res://scripts/joint_geography.gd").unpack(record.get("position",base(int(record.base_id)).get("position",{})))

func speed(record:Dictionary)->float:
	var value:=INF
	for id:String in record.units:
		if int(record.units[id])>0:value=minf(value,maxf(20,float(C.UNITS[id].speed_km_day)))
	return 0.0 if is_inf(value) else value

func set_route(record:Dictionary,destination:Vector2)->Dictionary:
	var origin:=force_position(record)
	var result:Dictionary
	if record.domain=="navy":result=geography.sea_route(origin,destination)
	else:result={"points":[preload("res://scripts/joint_geography.gd").pack(destination)],"distance":origin.distance_to(destination)}
	if result.has("error"):return result
	record.route=result.points.duplicate(true);record.position=preload("res://scripts/joint_geography.gd").pack(origin)
	return result

func rebase(id:int,base_id:int)->Dictionary:
	var record:=force(id);var destination:=base(base_id)
	if record.is_empty() or record.owner!="player" or not base_ready(destination) or not base_owned(destination) or destination.domain!=record.domain:return {"error":"Choose a ready owned base for this force."}
	if logistics.busy(id):return {"error":"Finish or recall the current transport first."}
	if force_position(record).distance_to(point(destination))>range_km(record):return {"error":"The new base is beyond this force's ferry range."}
	var result:=set_route(record,point(destination))
	if result.has("error"):return result
	record.base_id=base_id;record.carrier_id=0;record.pending_carrier_id=0;record.mission="hold";record.region={};record.regions=[];record.status="Rebasing"
	return {"ok":true,"message":"Crews are moving the force to its new home base."}

func attach_carrier(wing_id:int,carrier_id:int)->Dictionary:
	var wing:=force(wing_id);var carrier:=force(carrier_id)
	if wing.is_empty() or carrier.is_empty() or wing.owner!="player" or carrier.owner!="player" or wing.domain!="air" or carrier.domain!="navy":return {"error":"Select an owned air wing and carrier task force."}
	var gate:Dictionary=host._knowledge_gate("carrier_aviation",.1)
	if not bool(gate.unlocked):return {"error":gate.reason}
	for id:String in wing.units:
		if not bool(C.UNITS[id].get("carrier_capable",false)):return {"error":"This aircraft cannot operate from a carrier deck."}
	var capacity:=carrier_capacity(carrier);var occupied:=0
	for other:Dictionary in state.forces:
		if (int(other.get("carrier_id",0))==carrier_id or int(other.get("pending_carrier_id",0))==carrier_id) and int(other.id)!=wing_id:occupied+=hardware(other)
	if capacity<occupied+hardware(wing):return {"error":"Carrier deck capacity is %d; %d aircraft places are free." % [capacity,maxi(0,capacity-occupied)]}
	if logistics.busy(wing_id):return {"error":"Finish or recall this wing's transport before ferrying to a carrier."}
	if force_position(wing).distance_to(force_position(carrier))>range_km(wing):return {"error":"The carrier is beyond ferry range."}
	var transfer:=set_route(wing,force_position(carrier))
	if transfer.has("error"):return transfer
	wing.pending_carrier_id=carrier_id;wing.carrier_id=0;wing.mission="hold";wing.region={};wing.regions=[]
	return {"ok":true,"message":"Wing is ferrying to the carrier. Missions operate from the deck after arrival."}

func carrier_capacity(record:Dictionary)->int:
	var count:=0
	for id:String in record.units:count+=int(record.units[id])*int(C.UNITS[id].carrier_capacity)
	return count
func hardware(record:Dictionary)->int:
	var count:=0
	for amount in record.units.values():count+=int(amount)
	return count

func merge_forces(first_id:int,second_id:int)->Dictionary:
	var first:=force(first_id);var second:=force(second_id)
	if first.is_empty() or second.is_empty() or first_id==second_id or first.owner!="player" or second.owner!="player" or first.domain!=second.domain:return {"error":"Choose two different owned forces of the same service."}
	if not organized_at_home(first) or not organized_at_home(second) or first.base_id!=second.base_id:return {"error":"Both forces must be standing down at the same base."}
	if first.domain=="air" and first.units.keys()!=second.units.keys():return {"error":"An air wing uses one compatible aircraft type."}
	for id:String in second.units:
		if int(first.authorized.get(id,0))+int(second.authorized[id])>100:return {"error":"Split this larger force into additional task forces or wings."}
	var first_crew:=crew(first);var second_crew:=crew(second)
	first.proficiency=(float(first.get("proficiency",.45))*first_crew+float(second.get("proficiency",.45))*second_crew)/maxf(1,first_crew+second_crew)
	first.staff_training_day=maxi(int(first.get("staff_training_day",-1)),int(second.get("staff_training_day",-1)))
	first.training_fuel_fraction=float(first.get("training_fuel_fraction",0))+float(second.get("training_fuel_fraction",0))
	for id:String in second.units:
		first.units[id]=int(first.units.get(id,0))+int(second.units[id]);first.authorized[id]=int(first.authorized.get(id,0))+int(second.authorized[id])
	first.training=minf(float(first.training),float(second.training));first.condition=minf(float(first.condition),float(second.condition))
	for wing:Dictionary in state.forces:
		if int(wing.get("carrier_id",0))==second_id:wing.carrier_id=first_id
		if int(wing.get("pending_carrier_id",0))==second_id:wing.pending_carrier_id=first_id
	state.forces.erase(second)
	return {"ok":true,"message":"Forces combined; personnel and equipment totals are unchanged."}

func fuel_cost(record:Dictionary)->int:
	var fuel:=0
	for id:String in record.units:fuel+=int(C.UNITS[id].fuel_per_day)*int(record.units[id])
	return fuel
func pay_fuel(record:Dictionary)->bool:
	var fuel:=fuel_cost(record)
	if record.owner=="player":
		if int(host.military_consumables.get("fuel",0))<fuel:return false
		host.military_consumables.fuel=int(host.military_consumables.get("fuel",0))-fuel
	else:
		if not rival.spend(String(record.owner),float(fuel)*.25):return false
	record.fuel_used=fuel
	return true

func mission_factors(record:Dictionary,region:Dictionary,day:int)->Dictionary:
	var origin:=base(int(record.base_id))
	var carrier:=force(int(record.get("carrier_id",0)))
	var origin_point:=point(origin) if carrier.is_empty() else force_position(carrier)
	var coverage:=R.coverage(region,origin_point,range_km(record)) if not region.is_empty() else 0.0
	var stationed:=0
	for other:Dictionary in state.forces:
		if carrier.is_empty() and other.base_id==record.base_id and int(other.get("carrier_id",0))==0:stationed+=hardware(other)
		elif not carrier.is_empty() and int(other.get("carrier_id",0))==int(carrier.id):stationed+=hardware(other)
	var capacity:=float(origin.get("capacity",0)) if carrier.is_empty() else float(carrier_capacity(carrier))
	# Airbase/deck capacity limits sorties. A crowded port limits repair berths,
	# not the fighting efficiency of a fleet already at sea.
	var crowding:=minf(1,capacity/maxf(1,stationed)) if record.domain=="air" else 1.0
	var climate:=PlanetEnvironment.profile_at(point(region)) if not region.is_empty() else PlanetEnvironment.profile_at(origin_point)
	var weather:=clampf(WorldSimulation.food._weather_yield_factor(climate,float(day)),.52,1.0)
	var base_condition:=float(origin.get("condition",0)) if carrier.is_empty() else float(carrier.condition)
	return {"coverage":coverage,"crowding":crowding,"weather":weather,"base_condition":base_condition,"condition":float(record.condition),"stationed":stationed,"capacity":int(capacity),"efficiency":coverage*crowding*weather*base_condition*float(record.condition)}

func readiness(id:int,region:Dictionary={})->Dictionary:
	return readiness_for(force(id),region)

func readiness_for(record:Dictionary,region:Dictionary={})->Dictionary:
	# Accept a read-only detachment preview without replacing the live force.
	if record.is_empty():return {"blockers":["Select a task force or air wing."],"efficiency":0.0}
	var area:Dictionary=region if not region.is_empty() else record.get("region",{})
	var result:=mission_factors(record,area,maxi(0,int(state.last_day)))
	var blockers:Array[String]=[]
	var origin:=base(int(record.base_id))
	if not base_ready(origin) or not base_owned(origin,String(record.owner)):blockers.append("Home base unavailable — rebase to an operational friendly base.")
	var missing:=0
	for type_id:String in record.authorized:missing+=maxi(0,int(record.authorized[type_id])-int(record.units.get(type_id,0)))
	result.missing_equipment=missing
	if hardware(record)==0:blockers.append("No equipment — produce replacements for this force.")
	var training_days:=1.0
	for type_id:String in record.units:
		if int(record.units[type_id])>0:training_days=maxf(training_days,host.training_staff.service_days(float(C.UNITS[type_id].training_days))/maxf(.001,float(host.training_staff.policy(String(record.domain),String(record.owner)).intake)))
	result.training_days=ceili((1.0-float(record.training))*training_days)
	if float(record.training)<1 and host.training_staff.policy(String(record.domain),String(record.owner)).id=="suspended":
		result.training_days=-1;blockers.append("Initial instruction is suspended by service policy.")
	elif int(result.training_days)>0:blockers.append("Training: about %d days before supply and base-capacity delays." % int(result.training_days))
	if bool(record.get("repairing",false)) or float(record.condition)<maxf(.8,float(record.repair_threshold)):blockers.append("Repairs required at home base before resuming the mission.")
	if not record.get("route",[]).is_empty():blockers.append("Under way — mission starts after arrival.")
	if area.is_empty():blockers.append("No region assigned — draw or select a region on the map.")
	elif float(result.coverage)<=0:blockers.append("Selected region is beyond operating range.")
	if record.owner=="player" and fuel_cost(record)>int(host.military_consumables.get("fuel",0)):blockers.append("Insufficient fuel: %d/day required, %d available." % [fuel_cost(record),int(host.military_consumables.get("fuel",0))])
	result.fuel_per_day=fuel_cost(record);result.blockers=blockers
	return result

func repair_costs(record:Dictionary,rate:float=.04)->Dictionary:
	var costs:Dictionary={}
	for type_id:String in record.units:
		# Hull repairs draw the same raw materials and Civilian Goods as building.
		var bill:=preload("res://scripts/goods_bills.gd").flatten(C.UNITS[type_id].materials)
		for material:String in bill:
			costs[material]=float(costs.get(material,0))+float(bill[material])*int(record.units[type_id])*.005*(rate/.04)
	return costs

func repair_at_base(record:Dictionary,origin:Dictionary)->Dictionary:
	if not base_owned(origin,String(record.owner)) or not base_ready(origin) or force_position(record).distance_to(point(origin))>=2:return {"error":"Repairs require access to the owned home port."}
	var waiting:=0
	for other:Dictionary in state.forces:
		if other.base_id==record.base_id and (bool(other.get("repairing",false)) or float(other.condition)<float(other.repair_threshold)) and force_position(other).distance_to(point(origin))<2:waiting+=hardware(other)
	var rate:=minf(1.0-float(record.condition),.04*minf(1,float(origin.capacity)/maxi(1,waiting)))
	var costs:=repair_costs(record,rate)
	var paid:Dictionary
	var day:=int(WorldSimulation.state.elapsed_days)
	if record.owner=="player":
		paid=WorldSimulation.settlements.with_city_resources(String(origin.city_id),func()->Dictionary:
			var stock:Dictionary=WorldSimulation.state.resource_stockpiles
			var dock_plan:=Dock.repair_plan(origin,record,day,float(crew(record))*.25*WorldSimulation.state.population_health,rate,bool(host._knowledge_gate("hull_condition_surveys",.25).unlocked))
			if bool(dock_plan.get("ok",false)):
				var combined:=repair_costs(record,rate+float(dock_plan.extra_rate))
				for material:String in dock_plan.cost:combined[material]=float(combined.get(material,0))+float(dock_plan.cost[material])
				var affordable:=true
				for material:String in combined:
					if float(stock.get(material,0))<float(combined[material]):affordable=false;break
				if affordable:
					for material:String in combined:stock[material]=float(stock.get(material,0))-float(combined[material])
					Dock.commit_repair_access(origin,record,dock_plan,day)
					return {"ok":true,"rate":rate+float(dock_plan.extra_rate),"dock":true}
			# A dock shortage does not remove existing material-paid afloat repair.
			var shortages:Array[String]=[]
			for material:String in costs:
				var available:=float(stock.get(material,0))
				if available<float(costs[material]):shortages.append("%.1f %s (%.1f available)" % [float(costs[material]),WorldSimulation.resources.display_name(material),available])
			if not shortages.is_empty():return {"error":"Repairs waiting for "+", ".join(shortages)+" at "+String(origin.name)}
			for material:String in costs:stock[material]=float(stock.get(material,0))-float(costs[material])
			return {"ok":true,"rate":rate})
	else:
		var total:=0.0
		for amount in costs.values():total+=float(amount)
		paid={"ok":true} if rival.spend(String(record.owner),total) else {"error":"Repairs waiting for supplies"}
	if paid.has("error"):return paid
	record.condition=minf(1,float(record.condition)+float(paid.get("rate",rate)))
	return {"ok":true,"message":"Repairing at %s · %d%% condition" % [origin.name,roundi(float(record.condition)*100)]}

func advance(day:int)->void:
	if day<=int(state.last_day):return
	state.last_day=day
	rival.advance(day)
	# Detach deck wings before an empty task force receives replacement hulls.
	for wing:Dictionary in state.forces:
		var carrier_id:=int(wing.get("carrier_id",wing.get("pending_carrier_id",0)))
		if carrier_id<=0:carrier_id=int(wing.get("pending_carrier_id",0))
		if carrier_id<=0:continue
		var carrier:=force(carrier_id)
		if carrier.is_empty() or carrier_capacity(carrier)<=0:
			var origin:=force_position(wing)
			wing.carrier_id=0;wing.pending_carrier_id=0;wing.position=preload("res://scripts/joint_geography.gd").pack(origin);wing.mission="hold";wing.region={}
			set_route(wing,point(base(int(wing.base_id))))
	var projects:Dictionary={}
	for record:Dictionary in state.bases:
		if record.owner!="player" or not base_owned(record):continue
		var count:=int(float(record.construction_work)<float(record.required_work))+int(Dock.building(record))
		projects[record.city_id]=int(projects.get(record.city_id,0))+count
	for record:Dictionary in state.bases:
		if record.owner!="player" or not base_owned(record) or int(projects.get(record.city_id,0))<=0:continue
		WorldSimulation.settlements.with_city_resources(String(record.city_id),func():
			WorldSimulation.settlements.with_local_population(func():
				var share:=WorldSimulation.state.effective_workers("Construction",true)*.25*.1/int(projects[record.city_id])
				if float(record.construction_work)<float(record.required_work):
					record.construction_work=minf(float(record.required_work),float(record.construction_work)+share)
				if Dock.building(record):Dock.construct(record,share,day)))
	for record:Dictionary in state.forces:
		record.efficiency=0.0;record.fuel_used=0
		var origin:=base(int(record.base_id))
		var carrier:=force(int(record.get("carrier_id",0)))
		if int(record.get("carrier_id",0))>0 and (carrier.is_empty() or carrier_capacity(carrier)<=0):
			record.carrier_id=0;record.mission="hold";record.region={};record.status="Carrier lost · diverting to land base"
			host.training_staff.pause_service_training(record,day,String(record.status))
			set_route(record,point(origin));continue
		if not base_ready(origin) or not base_owned(origin,String(record.owner)):
			record.status="Home base unavailable · rebase to a friendly port or airfield"
			host.training_staff.pause_service_training(record,day,String(record.status));continue
		var at_base:bool=force_position(record).distance_to(point(origin))<2 and record.get("route",[]).is_empty()
		if hardware(record)==0:record.position=origin.position.duplicate(true);record.route=[]
		if at_base or hardware(record)==0:_replace(record)
		if crew(record)<=0:
			record.status="Waiting for replacement equipment and crew"
			host.training_staff.pause_service_training(record,day,String(record.status));continue
		if host.training_staff.service_training(record,origin,day):continue
		if float(record.condition)<float(record.repair_threshold):record["repairing"]=true
		if bool(record.get("repairing",false)) and not logistics.busy(int(record.id)):
			if not at_base:
				if record.get("route",[]).is_empty() or preload("res://scripts/joint_geography.gd").unpack(record.route.back()).distance_to(point(origin))>1:set_route(record,point(origin))
			else:
				var repaired:=repair_at_base(record,origin)
				if float(record.condition)>=.98:record.repairing=false
				record.status=String(repaired.get("error",repaired.get("message","Repairing at base")))
				host.training_staff.report_service_training(record,String(record.status));continue

		if logistics.busy(int(record.id)):
			if not pay_fuel(record):record.status="Transport halted · no fuel";continue
			record.efficiency=float(record.condition);record.status="Transporting";continue
		if record.domain=="navy" and not at_base and not bool(record.get("repairing",false)) and record.mission in ["patrol","strike_force","convoy_raiding"]:
			var contact:=latest_naval_contact(record)
			if not contact.is_empty():
				var destination:=preload("res://scripts/joint_geography.gd").unpack(contact.position)
				if force_position(record).distance_to(destination)>1 and (record.get("route",[]).is_empty() or preload("res://scripts/joint_geography.gd").unpack(record.route.back()).distance_to(destination)>1):set_route(record,destination)
			elif record.mission=="strike_force" and (record.get("route",[]).is_empty() or preload("res://scripts/joint_geography.gd").unpack(record.route.back()).distance_to(point(origin))>1):set_route(record,point(origin))
		if record.mission=="strike_force" and at_base:
			if not _has_contact(record):record.status="In port · waiting for a patrol contact";continue
			var contact:=latest_naval_contact(record)
			var route:=set_route(record,preload("res://scripts/joint_geography.gd").unpack(contact.position))
			if route.has("error"):record.status=String(route.error);continue
		if record.domain=="navy" and at_base and record.mission not in ["hold","strike_force"] and not record.region.is_empty():
			var destination:=preload("res://scripts/joint_geography.gd").unpack(record.get("mission_destination",record.region.position))
			if destination.distance_to(force_position(record))>2:
				var route:=set_route(record,destination)
				if route.has("error"):record.status=String(route.error);continue
		var naval_activity:=""
		if record.domain=="navy" and record.mission in ["patrol","convoy_raiding"] and not bool(record.get("repairing",false)) and record.get("route",[]).is_empty() and not record.region.is_empty() and latest_naval_contact(record).is_empty():
			var search:Dictionary=geography.patrol_route(record.region,force_position(record),point(origin),range_km(record),speed(record),hash("%d:%d:%d" % [WorldSimulation.state.world_seed,int(record.id),day]))
			if not search.is_empty():
				record.route=search.points
				naval_activity="Patrolling" if record.mission=="patrol" else "Searching for convoys"
			else:naval_activity="On station · no clear search leg"
		if record.mission=="hold" and record.get("route",[]).is_empty():record.status="Standing by on carrier deck" if not carrier.is_empty() else "Standing by at base";continue
		var factors:Dictionary={}
		# A moving carrier can take a standing air order out of range. Ground
		# those sorties before billing fuel; ferry and repair flights still move.
		if record.domain=="air" and record.get("route",[]).is_empty() and int(record.get("pending_carrier_id",0))<=0 and not bool(record.get("repairing",false)):
			if record.region.is_empty():record.status="Grounded · choose an operating region";continue
			factors=mission_factors(record,record.region,day)
			if float(factors.coverage)<=0:record.status="Grounded · operating area out of range";continue
		if not pay_fuel(record):record.status="No fuel · produce fuel or stand down other missions";continue
		if int(record.get("pending_carrier_id",0))>0:
			var target:=force(int(record.pending_carrier_id))
			if not target.is_empty():set_route(record,force_position(target))
		if not record.get("route",[]).is_empty():
			preload("res://scripts/joint_geography.gd").travel(record,speed(record))
			if not record.route.is_empty():record.status="Under way";continue
		if int(record.get("pending_carrier_id",0))>0:
			record.carrier_id=int(record.pending_carrier_id);record.pending_carrier_id=0;record.status="Arrived on carrier deck";continue
		if bool(record.get("repairing",false)):record.status="Returning for repairs";continue
		if record.mission=="hold":record.status="Arrived at base";continue
		if record.region.is_empty():record.status="Choose an operating region";continue
		if factors.is_empty():factors=mission_factors(record,record.region,day)
		if float(factors.coverage)<=0:record.status="Area outside current base range";continue
		record.efficiency=float(factors.efficiency)*(1.0-float(record.get("training_attending",0))/maxf(1,crew(record))*.5)
		record.status="%s · %d%% efficiency" % ["On mission" if naval_activity.is_empty() else naval_activity,roundi(float(record.efficiency)*100)]
		record.experience=minf(1,float(record.experience)+.001)
	_detect_and_fight()
	effects.advance(day)
	logistics.advance(day)
	for key in state.contacts.keys():
		if day-int(state.contacts[key].day)>5:state.contacts.erase(key)
func latest_naval_contact(record:Dictionary)->Dictionary:
	var newest:Dictionary={}
	for contact:Dictionary in state.contacts.values():
		if contact.observer!=record.owner or contact.get("domain","")!="navy" or int(state.last_day)-int(contact.day)>2:continue
		if not _hostile(String(record.owner),String(contact.get("owner",""))) or not R.contains(record.region,preload("res://scripts/joint_geography.gd").unpack(contact.get("position",{}))):continue
		if newest.is_empty() or int(contact.day)>int(newest.day):newest=contact
	return newest
func _has_contact(record:Dictionary)->bool:
	return not latest_naval_contact(record).is_empty()

func docked(record:Dictionary)->bool:
	return record.domain=="navy" and force_position(record).distance_to(point(base(int(record.base_id))))<2 and record.get("route",[]).is_empty()

func can_attack(observer:Dictionary,target:Dictionary)->bool:
	return can_attack_contact(observer,target,force_position(target),docked(target))

func can_attack_contact(observer:Dictionary,target:Dictionary,target_position:Vector2,target_docked:bool)->bool:
	if observer.mission in ["hold","reconnaissance","air_supply","invasion_support","transport"]:return false
	if observer.domain=="air":
		if target.domain=="air":
			# Air superiority and interception engage flying aircraft, not parked
			# wings across the map. Ground attacks are a different mission chain.
			if float(target.efficiency)<=0 or target.mission=="hold":return false
			if observer.mission not in ["air_superiority","interception"]:return false
			return observer.mission!="interception" or target.mission not in ["air_superiority","interception"]
		return (observer.mission=="port_strike" and target_docked) or (observer.mission=="naval_strike" and not target_docked)
	if target.domain!="navy" or target_docked or bool(observer.get("repairing",false)):return false
	var reach:=2.0
	for type_id:String in observer.units:
		if int(observer.units[type_id])<=0:continue
		if type_id in ["missile_patrol","missile_destroyer","nuclear_submarine"]:reach=maxf(reach,120)
		elif type_id in ["destroyer","light_cruiser","heavy_cruiser","battleship","submarine","ironclad","torpedo_boat"]:reach=maxf(reach,30)
	return force_position(observer).distance_to(target_position)<=reach

func _detect_and_fight()->void:
	if WorldSimulation.enabled:return
	var damage:Dictionary={}
	for observer:Dictionary in state.forces:
		if float(observer.efficiency)<=0 or observer.region.is_empty():continue
		for target:Dictionary in state.forces:
			if not _hostile(String(observer.owner),String(target.owner)):continue
			var target_position:=force_position(target)
			if target.domain=="air" and float(target.efficiency)>0 and not target.region.is_empty():target_position=point(target.region)
			var overlap:=R.overlap(observer.region,target.region) if target.domain=="air" and observer.domain=="air" and float(target.efficiency)>0 else (1.0 if R.contains(observer.region,target_position) else 0.0)
			if overlap<=0:continue
			if observer.domain=="navy" and (target.domain=="air" or force_position(observer).distance_to(target_position)>maxf(20,minf(150,speed(observer)*.25))):continue
			var rng:=RandomNumberGenerator.new();rng.seed=WorldSimulation.state.world_seed^int(state.last_day)*104729^int(observer.id)*32452843^int(target.id)*49979687
			var detected:=_power(observer,"detection")/(5.0+_power(target,"defense"))*B.detection_multiplier(observer,target)*overlap
			if rng.randf()>clampf(detected,.08,.98):continue
			state.contacts["%s:%d" % [observer.owner,target.id]]={"observer":observer.owner,"target":target.id,"region":observer.region.id,"day":state.last_day,"name":target.name,"position":preload("res://scripts/joint_geography.gd").pack(target_position),"owner":target.owner,"domain":target.domain}
			if not can_attack(observer,target):continue
			var defense:=maxf(1,_power(target,"defense")/maxi(1,hardware(target)))
			damage[target.id]=float(damage.get(target.id,0))+_power(observer,"attack")/defense*.12*rng.randf_range(.7,1.3)*overlap*B.damage_multiplier(observer,target)
	for id in damage:
		var target:=force(int(id))
		if not target.is_empty():_losses(target,float(damage[id]))

var screen:CanvasLayer
func open_service(domain:String)->void:
	if domain=="army":open_hierarchy(domain);return
	if domain not in ["navy","air"]:return
	var terrain:Node=host.get_tree().current_scene
	if terrain==null or not terrain.has_method("_terrain_hit"):return
	if is_instance_valid(screen):
		if screen.domain==domain:return
		screen.free()
	if terrain.hud:
		terrain.hud.close_detail();terrain.hud.close_dock()
	screen=preload("res://scripts/hud/naval_command_panel.gd").new() if domain=="navy" else preload("res://scripts/hud/air_command_panel.gd").new()
	screen.terrain=terrain
	host.get_tree().root.add_child(screen)

func open_hierarchy(domain:String)->void:
	if domain not in ["army","navy","air"]:return
	var terrain:Node=host.get_tree().current_scene
	if terrain==null or not terrain.has_method("_terrain_hit"):return
	if is_instance_valid(screen):screen.free()
	if terrain.hud:terrain.hud.close_detail();terrain.hud.close_dock()
	screen=load("res://scripts/hud/command_hierarchy_panel.gd").new()
	screen.domain=domain;screen.terrain=terrain
	host.get_tree().root.add_child(screen)

func split_force(id:int)->Dictionary:
	var original:=force(id)
	if original.is_empty() or original.owner!="player" or not organized_at_home(original):return {"error":"Stand the force down at base before splitting it."}
	if hardware(original)<2 or state.forces.size()>=MAX_FORCES:return {"error":"At least two craft and a free command record are required."}
	var copy:=original.duplicate(true);copy.id=_id();copy.name=String(original.name)+" Detachment"
	for type_id:String in original.units:
		var count:=floori(float(original.units[type_id])*.5)
		var authorized:=maxi(count,floori(float(original.authorized[type_id])*.5))
		copy.units[type_id]=count;copy.authorized[type_id]=authorized
		original.units[type_id]-=count;original.authorized[type_id]-=authorized
	if hardware(copy)==0:
		for type_id:String in original.units:
			if int(original.units[type_id])<=0:continue
			var extra:=maxi(0,1-int(copy.authorized[type_id]))
			copy.units[type_id]=1;copy.authorized[type_id]=maxi(1,int(copy.authorized[type_id]))
			original.units[type_id]-=1;original.authorized[type_id]-=extra
			break
	state.forces.append(copy)
	return {"ok":true,"id":copy.id,"message":"Force split into two commands with the same total crew and equipment."}

func group_fleet(id:int,other_id:int)->Dictionary:
	var record:=force(id);var other:=force(other_id)
	if record.is_empty() or other.is_empty() or record.owner!="player" or other.owner!="player" or record.domain!="navy" or other.domain!="navy":return {"error":"Choose two owned naval task forces."}
	record.fleet_id=int(other.get("fleet_id",other.id))
	return {"ok":true,"message":"Task forces now share a fleet. Each retains its own mission, composition and home port."}

func export_state()->Dictionary:return state.duplicate(true)
func import_state(payload:Dictionary)->void:
	if validate(payload)!="":return
	reset()
	for key:String in state:
		if payload.has(key):state[key]=payload[key].duplicate(true) if payload[key] is Dictionary or payload[key] is Array else payload[key]
func validate(payload:Variant)->String:
	if not payload is Dictionary:return "Invalid joint-force state."
	if payload.is_empty():return ""
	for key in ["bases","forces","contacts","events","next_id","last_day"]:
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
		if record.has("dock_service") and (record.domain!="navy" or not Dock.valid_dock(record.dock_service)):return "Invalid dock construction or access ledger."
		ids[record.id]=true;bases[record.id]=record
	for record in payload.get("forces",[]):
		if not record is Dictionary or record.get("domain","") not in MISSIONS or not record.get("units",{}) is Dictionary:return "Invalid fleet or wing."
		for key in ["id","owner","name","base_id","authorized","mission","region","status","training","condition","experience","efficiency","auto_replace","repair_threshold","fuel_used","damage"]:
			if not record.has(key):return "Incomplete fleet or wing."
		if not _whole_number(record.id,1) or ids.has(record.id) or int(record.id)>=int(payload.next_id):return "Invalid force identifier."
		if not bases.has(record.base_id) or bases[record.base_id].domain!=record.domain or bases[record.base_id].owner!=record.owner:return "Invalid force home base."
		ids[record.id]=true
		if not Dock.valid_force_fields(record):return "Invalid hull survey or service date."
		if not record.authorized is Dictionary or record.authorized.size()!=record.units.size():return "Invalid force establishment."
		if not record.auto_replace is bool or not _finite_nonnegative(record.repair_threshold) or float(record.repair_threshold)>1:return "Invalid repair policy."
		for key in ["owner","name","status"]:
			if not record[key] is String:return "Invalid force identity."
		if record.mission not in MISSIONS[record.domain] or not record.region is Dictionary:return "Invalid force mission."
		if record.mission!="hold" and (record.region.get("domain","")!=record.domain or not _valid_position(record.region.get("position",{})) or not record.region.get("id",null) is String):return "Invalid mission region."
		for id in record.units:
			if not C.UNITS.has(id) or C.UNITS[id].domain!=record.domain or not _whole_number(record.units[id],0):return "Invalid joint-force equipment."
			if not _whole_number(record.authorized.get(id,-1),0) or int(record.authorized[id])<int(record.units[id]) or int(record.authorized[id])>100:return "Invalid authorized equipment."
		for field in ["training","condition","efficiency","experience","damage","proficiency"]:
			var value:Variant=record.get(field,0)
			if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0:return "Invalid joint-force condition."
			if field!="damage" and float(value)>1:return "Invalid joint-force readiness."
	for contact in payload.contacts.values():
		if not contact is Dictionary:return "Invalid contact."
		for key in ["observer","target","region","day","name"]:
			if not contact.has(key):return "Incomplete contact."
		if not _whole_number(contact.day,0) or not _whole_number(contact.target,1):return "Invalid contact date or target."
	return _validate_extended(payload,bases,ids)

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

func _validate_extended(payload:Dictionary,bases:Dictionary,ids:Dictionary)->String:
	if not payload.get("regions",[]) is Array or payload.get("regions",[]).size()>R.MAX_REGIONS:return "Invalid operating area list."
	var area_ids:Dictionary={}
	for region in payload.get("regions",[]):
		if not region is Dictionary or not region.get("id",null) is String or not region.get("name",null) is String or not region.get("owner",null) is String:return "Invalid operating area identity."
		if area_ids.has(region.id) or region.get("domain","") not in MISSIONS or not _valid_position(region.get("position",{})):return "Invalid operating area."
		if R.validate(region.get("vertices",[]))!="":return "Invalid operating boundary."
		area_ids[region.id]=true
	for record:Dictionary in payload.forces:
		if record.has("position") and not _valid_position(record.position):return "Invalid force position."
		if not _valid_route(record.get("route",[])):return "Invalid force route."
		if record.region.has("vertices") and R.validate(record.region.vertices)!="":return "Invalid force boundary."
		for key in ["carrier_id","pending_carrier_id","fleet_id"]:
			if not _whole_number(record.get(key,0),0):return "Invalid force attachment."
		for key in ["fuel_used","loss_fraction"]:
			if not _finite_nonnegative(record.get(key,0)):return "Invalid force expenditure."
		for key in ["carrier_id","pending_carrier_id"]:
			var carrier_id:=int(record.get(key,0))
			if carrier_id==0:continue
			var carrier:Dictionary={}
			for candidate:Dictionary in payload.forces:
				if int(candidate.id)==carrier_id:carrier=candidate;break
			if record.domain!="air" or carrier.is_empty() or carrier.owner!=record.owner or carrier.domain!="navy" or carrier_capacity(carrier)<=0:return "Invalid carrier attachment."
	if not payload.get("convoys",[]) is Array or payload.get("convoys",[]).size()>MAX_FORCES+64:return "Invalid transport list."
	for convoy in payload.get("convoys",[]):
		if not convoy is Dictionary:return "Invalid transport."
		for key in ["id","force_id","source_base","army_id","initial_hardware","last_hardware"]:
			if not _whole_number(convoy.get(key,null),0):return "Invalid transport identifier or load."
		if ids.has(convoy.id) or int(convoy.id)>=int(payload.next_id) or not ids.has(convoy.force_id) or not bases.has(convoy.source_base):return "Invalid transport reference."
		ids[convoy.id]=true
		for key in ["food","delivered"]:
			if not _finite_nonnegative(convoy.get(key,null)):return "Invalid transport cargo."
		for key in ["position","destination_position"]:
			if not _valid_position(convoy.get(key,null)):return "Invalid transport destination."
		if not _valid_route(convoy.get("route",null)) or convoy.get("status","") not in ["preparing","outbound","returning","returned","lost"]:return "Invalid transport route or status."
		for key in ["owner","destination_id","destination_owner"]:
			if not convoy.get(key,null) is String:return "Invalid transport ownership."
		if not convoy.get("invasion",null) is bool or not _whole_number(convoy.get("depart_day",null),-1):return "Invalid transport departure."
	var orders:Variant=payload.get("rival_orders",{})
	if not orders is Dictionary or orders.size()>256:return "Invalid rival production."
	for owner in orders:
		var order:Variant=orders[owner]
		if not owner is String or not order is Dictionary or not C.UNITS.has(order.get("unit","")) or not bases.has(order.get("base_id",0)) or not _finite_nonnegative(order.get("progress",null)):return "Invalid rival production order."
	return ""
func _valid_route(route:Variant)->bool:
	if not route is Array or route.size()>8192:return false
	for position in route:
		if not _valid_position(position):return false
	return true
