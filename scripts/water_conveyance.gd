extends RefCounted
## Installed local infrastructure; Freshwater remains owned by ResourceSystem.
const Fabric=preload("res://scripts/water_conveyance_fabric.gd")
const Route=preload("res://scripts/water_conveyance_route.gd")
const LIMIT:=8

static func data()->Dictionary:return WorldSimulation.state.water_conveyance
static func adopted()->Array:
	var result:Array=[]
	for id:String in WorldSimulation.state.known_discoveries:
		if WorldSimulation.discovery.adoption(id)>=.25:result.append(id)
	return result

static func quote(source:Dictionary,destination:Vector3,height_at:Callable,material:String)->Dictionary:
	if not WorldSimulation.state.settlement_site_committed or WorldSimulation.state.convoy_traveling:return {"error":"Settle before installing a water line."}
	if data().lines.size()>=LIMIT:return {"error":"This settlement has reached its local line limit."}
	for line:Dictionary in data().lines:
		if String(line.route.source_id)==String(source.get("id","")):
			return {"error":"This settlement already has a line assigned to that intake."}
	var route:=Route.survey(source,destination,height_at)
	if not bool(route.get("ok",false)):return {"error":route.get("reason","Route is unavailable.")}
	return Fabric.quote(route,material,adopted(),WorldSimulation.state.resource_stockpiles)

static func install(source:Dictionary,destination:Vector3,height_at:Callable,material:String)->Dictionary:
	var terms:=quote(source,destination,height_at,material)
	if terms.has("error"):return terms
	var result:=Fabric.begin(terms,WorldSimulation.state.resource_stockpiles,int(WorldSimulation.state.elapsed_days))
	if result.has("error"):return result
	var line:Dictionary=result.line
	line.id=int(data().next_id);data().next_id=int(data().next_id)+1
	data().lines.append(line)
	return {"ok":true,"message":"Supplied water line awaits construction work.","line_id":line.id}

static func construction_work(available_work:float,day:int)->float:
	var remaining:=maxf(0.0,available_work)
	for line:Dictionary in data().lines:
		remaining-=Fabric.advance_construction(line,remaining,day)
	return maxf(0.0,available_work)-remaining

static func delivery(context:Dictionary,day:int,budget:float)->float:
	if int(data().last_day)>=day:return 0.0
	data().last_day=day
	var total:=0.0;var lost:=0.0
	var sources:Array=context.get("water_conveyance_sources",[])
	var origin:Variant=context.get("origin")
	for line:Dictionary in data().lines:
		line.delivered_today=0.0;line.blocker=""
		if String(line.status)!="active":continue
		line.condition=maxf(0.0,float(line.condition)-float(line.decay))
		line.obstruction=minf(1.0,float(line.obstruction)+.0004)
		if WorldSimulation.state.convoy_traveling or not Route.finite_point(origin):
			line.blocker="The settlement is traveling or its location is unavailable.";continue
		var destination:Vector3=line.route.destination
		if Vector2(origin.x,origin.z).distance_to(Vector2(destination.x,destination.z))>.01:
			line.blocker="This installed line serves another settlement location.";continue
		var source:Dictionary={}
		for candidate:Dictionary in sources:
			if String(candidate.get("id",""))!=String(line.route.source_id) or not bool(candidate.get("revealed",false)):continue
			if not Route.finite_point(candidate.get("position")):continue
			if candidate.position.distance_to(line.route.source_position)>.01:continue
			source=candidate;break
		if source.is_empty():line.blocker="The installed intake is not currently confirmed available.";continue
		if float(line.condition)<=.1:line.blocker="The line needs structural repair.";continue
		# Throughput is a game service quantity, not a hydraulic engineering rating.
		var capacity:=120.0*float(line.condition)*(1.0-float(line.obstruction))
		var leakage:=clampf(float(line.leakage)+(1.0-float(line.condition))*.3,0,1)
		var delivered:=minf(maxf(0.0,budget-total),capacity*(1.0-leakage))
		line.delivered_today=delivered;total+=delivered
		lost+=delivered*leakage/maxf(.0001,1.0-leakage)
	data().report={"day":day,"delivered":total,"lost":lost}
	return total

static func maintain(line_id:int,work:float,clear_obstruction:bool=false)->float:
	if work<=0:return 0.0
	var known:=adopted()
	for line:Dictionary in data().lines:
		if int(line.id)!=line_id or String(line.status)!="active":continue
		if clear_obstruction and "sewer_rodding_service" not in known:return 0.0
		var field:="obstruction" if clear_obstruction else "condition"
		var need:=float(line.obstruction) if clear_obstruction else 1.0-float(line.condition)
		var amount:=minf(need,work*.01)
		var item:="Conduit Rodding Sets" if clear_obstruction else String(Fabric.MATERIALS[line.material].item)
		var stock:=maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get(item,0)))
		amount=minf(amount,stock/2.0)
		WorldSimulation.state.resource_stockpiles[item]=stock-amount*2.0
		line[field]=float(line[field])-amount if clear_obstruction else float(line[field])+amount
		return amount/.01
	return 0.0
