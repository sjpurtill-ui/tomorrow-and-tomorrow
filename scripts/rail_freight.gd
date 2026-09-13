extends RefCounted
const F=preload("res://scripts/rail_freight_fabric.gd")
const R=preload("res://scripts/rail_route_survey.gd")
const REQUIRED=["rail_gauge_standards","rail_track_foundations","wagonway_haulage","rail_vehicle_braking"]
static func data()->Dictionary:return WorldSimulation.state.rail_freight
static func city(id:String)->Dictionary:return WorldSimulation.settlements.settlement_record(id)
static func available_city(id:String)->bool:
	var record:=city(id)
	return not record.is_empty() and String(record.get("occupied_by","")).is_empty()
static func local_city()->String:
	if not WorldSimulation.state.resource_settlement_id.is_empty():return WorldSimulation.state.resource_settlement_id
	for record:Dictionary in WorldSimulation.state.player_settlements:
		if bool(record.get("primary",false)):return String(record.id)
	return ""
static func terrain_for(id:String)->Dictionary:
	var context:=preload("res://scripts/civilization_day.gd").context(WorldSimulation.settlements._record_position(city(id)))
	return {"height_at":context.get("terrain_height_at",Callable()),"land_at":context.get("buildable_land_at",Callable()),"river_distance_at":context.get("river_distance_at",Callable()),"known_at":func(x:float,z:float)->bool:return bool(WorldSimulation.settlements.known_route_assessment(Vector2(x,z),Vector2(x,z)).get("known",false))}
static func line_for(id:int)->Dictionary:
	for line:Dictionary in data().lines:
		if int(line.id)==id:return line
	return {}
static func quote(source:String,destination:String,gauge:int=900,wagons:int=2,waypoints:Array=[],terrain:Dictionary={})->Dictionary:
	if WorldSimulation.state.convoy_traveling or not WorldSimulation.state.settlement_site_committed:return {"error":"Settle before building a rail route."}
	if source==destination or not available_city(source) or not available_city(destination):return {"error":"Two accessible owned settlements are required."}
	for id:String in REQUIRED:
		if not bool(WorldSimulation.military._knowledge_gate(id,.25).unlocked):return {"error":"Adopt "+id.replace("_"," ")+" before building an operating wagonway."}
	if data().lines.size()>=F.MAX_LINES:return {"error":"The rail register is full."}
	for line:Dictionary in data().lines:
		if source in [line.source_id,line.destination_id] and destination in [line.source_id,line.destination_id]:return {"error":"These settlements already have a rail project."}
	var origin:=WorldSimulation.settlements._record_position(city(source))
	var finish:=WorldSimulation.settlements._record_position(city(destination))
	var path:Array=waypoints.duplicate()
	if path.is_empty():path=[Vector3(origin.x,0,origin.y),Vector3(finish.x,0,finish.y)]
	if path.size()<2 or not R.finite_point(path.front()) or not R.finite_point(path.back()):return {"error":"The rail alignment is invalid."}
	if Vector2(path.front().x,path.front().z).distance_to(origin)>.00001 or Vector2(path.back().x,path.back().z).distance_to(finish)>.00001:return {"error":"The rail alignment must join the selected settlements."}
	var route:=R.survey(path,terrain_for(source) if terrain.is_empty() else terrain)
	if route.has("error"):return route
	var bill:=F.installation_bill(route,gauge,wagons)
	if bill.is_empty():return {"error":"The selected rail gauge or wagon count is unsupported."}
	var supplied:bool=WorldSimulation.settlements.with_city_resources(source,func()->bool:return F.can_pay(WorldSimulation.state.resource_stockpiles,bill))
	return {"ok":supplied,"error":"" if supplied else "Deliver the required rail materials, wagons and brakes to the construction city.","cost":bill,"route":route,"gauge_mm":gauge,"wagons":wagons,"work_required":maxf(10,float(route.length_km)*F.CONSTRUCTION_WORK_PER_KM)}
static func install(source:String,destination:String,gauge:int=900,wagons:int=2,waypoints:Array=[],terrain:Dictionary={})->Dictionary:
	var terms:=quote(source,destination,gauge,wagons,waypoints,terrain)
	if not bool(terms.get("ok",false)):return terms
	return WorldSimulation.settlements.with_city_resources(source,func()->Dictionary:
		return F.begin(data(),source,destination,terms.route,gauge,wagons,WorldSimulation.state.resource_stockpiles,int(WorldSimulation.state.elapsed_days)))
static func accessible(line:Dictionary,check_terrain:bool=false)->bool:
	if not available_city(String(line.source_id)) or not available_city(String(line.destination_id)):return false
	var origin:=WorldSimulation.settlements._record_position(city(String(line.source_id)))
	var finish:=WorldSimulation.settlements._record_position(city(String(line.destination_id)))
	if origin.distance_to(Vector2(line.route.origin.x,line.route.origin.z))>.001 or finish.distance_to(Vector2(line.route.destination.x,line.route.destination.z))>.001:return false
	if check_terrain:
		var current:=R.survey(line.route.waypoints,terrain_for(String(line.source_id)))
		if not bool(current.get("ok",false)) or current.samples.size()!=line.route.samples.size():return false
		for index in current.samples.size():
			if current.samples[index].distance_to(line.route.samples[index])>.001:return false
	return true
static func construction_sites()->int:
	var count:=0
	for line:Dictionary in data().lines:
		if String(line.source_id)!=local_city() or not accessible(line) or not line.trip.is_empty():continue
		if F.building(line) or minf(float(line.condition),float(line.wagon_condition))<.95:count+=1
	return count
static func construction_work(work:float,day:int)->float:
	var count:=construction_sites()
	if count<=0:return 0.0
	var used:=0.0
	for line:Dictionary in data().lines:
		if String(line.source_id)!=local_city() or not accessible(line) or not line.trip.is_empty():continue
		if F.building(line):used+=F.construct(line,work/count,day)
		elif minf(float(line.condition),float(line.wagon_condition))<.95:used+=F.maintain(line,WorldSimulation.state.resource_stockpiles,work/count,day)
	return used
static func advance(day:int)->void:
	if int(data().last_day)>=day:return
	var gap:=maxi(0,day-int(data().last_day)) if int(data().last_day)>=0 else 0
	data().last_day=day
	for line:Dictionary in data().lines:
		if not F.building(line):line.condition=maxf(0,float(line.condition)-gap*.00005)
		if line.trip.is_empty():continue
		var cargo_pending:=false
		for shipment:Dictionary in WorldSimulation.state.city_trade_shipments:
			if int(shipment.id)==int(line.trip.shipment_id):cargo_pending=true;break
		if day>=float(line.trip.return_day) and not cargo_pending and accessible(line):line.trip={}
static func reserved_workers(source:String)->float:
	var reserved:=0.0
	for line:Dictionary in data().lines:
		if not line.trip.is_empty() and String(line.trip.source_id)==source:reserved+=float(line.trip.crew_workers)
	return reserved
static func dispatch_quote(source:String,destination:String,resource:String,requested:float,available_workers:float)->Dictionary:
	for line:Dictionary in data().lines:
		if source not in [line.source_id,line.destination_id] or destination not in [line.source_id,line.destination_id] or source==destination:continue
		if not accessible(line,true):line.blocker="The installed route or an endpoint is no longer available.";continue
		var plan:=F.trip_quote(line,requested,available_workers,int(WorldSimulation.state.elapsed_days))
		if plan.is_empty():continue
		return WorldSimulation.settlements.with_city_resources(source,func()->Dictionary:
			if resource=="Food":WorldSimulation.food.initialize()
			var stock:Dictionary=WorldSimulation.state.resource_stockpiles
			if not F.can_pay(stock,plan.cost):return {}
			# A cargo can be the same material as upkeep; reserve upkeep first.
			var cargo:=minf(float(plan.quantity),maxf(0,float(stock.get(resource,0))-float(plan.cost.get(resource,0))))
			var adjusted:=F.trip_quote(line,cargo,available_workers,int(WorldSimulation.state.elapsed_days))
			if adjusted.is_empty():return {}
			adjusted.line_id=int(line.id);return adjusted)
	return {}
static func issue_dispatch(source:String,destination:String,resource:String,requested:float,workers:float,shipment_id:int)->Dictionary:
	var plan:=dispatch_quote(source,destination,resource,requested,workers)
	if plan.is_empty():return {}
	var line:=line_for(int(plan.line_id))
	return WorldSimulation.settlements.with_city_resources(source,func()->Dictionary:
		var stock:Dictionary=WorldSimulation.state.resource_stockpiles
		var before:=line.duplicate(true)
		if not F.commit_trip(line,plan,shipment_id,source,int(WorldSimulation.state.elapsed_days),stock):return {}
		var sent:=0.0
		if resource=="Food":sent=WorldSimulation.food.issue_for_obligation(float(plan.quantity),"city_trade","Rail delivery to "+String(city(destination).get("name",destination)),float(plan.travel_days),0)
		else:
			sent=minf(float(plan.quantity),maxf(0,float(stock.get(resource,0))))
			stock[resource]=float(stock.get(resource,0))-sent
		if sent<=0:
			for item:String in plan.cost:stock[item]=float(stock.get(item,0))+float(plan.cost[item])
			line.clear();line.merge(before,true);return {}
		var duration:=float(line.trip.return_day)-float(line.trip.departure_day)
		line.trip.quantity=sent
		line.trip.crew_workers=2.0+int(line.wagons)+sent*.005/duration
		line.trip.worker_days=float(line.trip.crew_workers)*duration
		line.condition=maxf(0,float(before.condition)-sent*.000002)
		line.blocker=""
		return {"quantity":sent,"travel_days":float(plan.travel_days),"crew_workers":float(line.trip.crew_workers),"line_id":int(line.id)})
static func delivery_available(shipment:Dictionary)->bool:
	var line:=line_for(int(shipment.get("rail_line_id",0)))
	return not line.is_empty() and accessible(line)
static func describe()->String:
	var text:="Rail freight\n"
	if data().lines.is_empty():return text+"No installed wagonway."
	for line:Dictionary in data().lines:
		text+="%s → %s · %d mm · %d wagons\n" % [String(city(String(line.source_id)).get("name",line.source_id)),String(city(String(line.destination_id)).get("name",line.destination_id)),int(line.gauge_mm),int(line.wagons)]
		if F.building(line):text+="Construction %.1f / %.1f work\n" % [float(line.work_done),float(line.work_required)]
		else:text+="Track %d%% · wagons %d%%\n" % [roundi(float(line.condition)*100),roundi(float(line.wagon_condition)*100)]
		if not line.trip.is_empty():text+="Crew and wagons committed through day %d; pending cargo or blocked return can extend this.\n" % int(line.trip.return_day)
		if not String(line.blocker).is_empty():text+=String(line.blocker)+"\n"
	return text
