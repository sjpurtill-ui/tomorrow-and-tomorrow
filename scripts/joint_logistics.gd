extends RefCounted
const G=preload("res://scripts/joint_geography.gd")
const C=preload("res://scripts/joint_force_catalog.gd")
var _owner:WeakRef
var op:RefCounted:
	get:return _owner.get_ref()
func _init(operations:RefCounted)->void:_owner=weakref(operations)
func busy(force_id:int)->bool:
	for convoy:Dictionary in op.state.convoys:
		if int(convoy.force_id)==force_id and convoy.status in ["preparing","outbound","returning"]:return true
	return false
func capacity(force:Dictionary)->int:
	var count=0
	for id:String in force.units:count+=int(force.units[id])*int(C.UNITS[id].get("cargo_capacity",0))
	return count

func start(force_id:int,destination_id:String,food:float=0,army_id:int=0)->Dictionary:
	var force:Dictionary=op.force(force_id)
	if force.is_empty() or force.owner!="player" or busy(force_id):return {"error":"Choose an available transport force."}
	if food<0 or not is_finite(food):return {"error":"Cargo must be a finite, positive amount."}
	if float(force.training)<1:return {"error":"Transport crews must finish training."}
	var home:Dictionary=op.base(int(force.base_id))
	if not op.base_ready(home) or not op.base_owned(home) or op.force_position(force).distance_to(op.point(home))>2:return {"error":"Return the transport to its operational home base before loading."}
	var destination=WorldSimulation.world.city_intelligence.site(destination_id)
	if destination.is_empty():return {"error":"Choose a city destination."}
	var enemy=String(destination.civ_id)!="player"
	if enemy and (not op._hostile("player",String(destination.civ_id)) or WorldSimulation.world.city_intelligence.known("player",destination_id).is_empty()):return {"error":"An invasion needs a known city belonging to a civilization at war with you."}
	var army:Dictionary={}
	if army_id>0:
		var index=int(op.host._field_army_index(army_id))
		if index<0:return {"error":"Choose a deployed field army."}
		army=op.host.field_armies[index]
		if bool(army.get("embarked",false)) or String(army.get("status",""))=="moving" or G.unpack(army.get("position",{})).distance_to(op.point(home))>10:return {"error":"The army must assemble at the transport's home base first."}
		if force.domain=="air":
			for formation:Dictionary in army.get("formations",[]):
				if formation.unit not in ["paratrooper","air_assault"]:return {"error":"Air deployment requires paratroopers or air-assault infantry; heavy formations require sea transport."}
	var people=int(army.get("troops",0))
	if enemy and people<=0:return {"error":"Choose an army for this invasion."}
	if food+people<=0:return {"error":"Choose food cargo or an army to transport."}
	if food+people>capacity(force):return {"error":"Transport capacity is %d; this load needs %.0f places." % [capacity(force),food+people]}
	var target=op.point(destination)
	var region:Dictionary=op.region_at(target,String(force.domain))
	if op.point(home).distance_to(target)>op.range_km(force):return {"error":"The destination is beyond transport range."}
	if force.domain=="navy":
		var coast:Dictionary=op.coastal_site({"position":target})
		if coast.has("error"):return coast
		target=op.point(coast)
	if enemy and op.effects.control("player",region)<(.7 if force.domain=="air" else .5):return {"error":"Establish %d%% %s control before invasion departure." % [70 if force.domain=="air" else 50,"air" if force.domain=="air" else "naval"]}
	var path:Dictionary=op.geography.sea_route(op.point(home),target) if force.domain=="navy" else {"points":[G.pack(target)],"distance":op.point(home).distance_to(target)}
	if path.has("error"):return path
	var available:float=WorldSimulation.settlements.with_city_resources(String(home.city_id),func():return WorldSimulation.food.total_stored())
	if available<food:return {"error":"The embarkation city has %.1f food; this convoy needs %.1f." % [available,food]}
	var issued:float=WorldSimulation.settlements.with_city_resources(String(home.city_id),func():return WorldSimulation.food.issue_for_obligation(food,"military","Naval or air transport cargo",0,0))
	if not army.is_empty():army.embarked=true;army.status="embarked"
	force.mission="transport";force.region=region
	var record={"id":op._id(),"owner":"player","force_id":force_id,"source_base":home.id,"destination_id":destination_id,"destination_owner":destination.civ_id,"destination_position":destination.position.duplicate(true),"position":home.position.duplicate(true),"route":path.points.duplicate(true),"food":issued,"army_id":army_id,"status":"preparing" if enemy else "outbound","depart_day":int(op.state.last_day)+(14 if enemy else 0),"initial_hardware":op.hardware(force),"last_hardware":op.hardware(force),"invasion":enemy,"delivered":0.0}
	op.state.convoys.append(record)
	return {"ok":true,"message":"Cargo and troops assigned. Crews handle transit; escorts and regional control determine exposure to attack."}

func recall(convoy_id:int)->Dictionary:
	for convoy:Dictionary in op.state.convoys:
		if int(convoy.id)!=convoy_id or convoy.status not in ["preparing","outbound"]:continue
		var force:Dictionary=op.force(int(convoy.force_id));var home:Dictionary=op.base(int(convoy.source_base))
		if force.is_empty() or home.is_empty():return {"error":"Transport or home base is unavailable."}
		var route:Dictionary=op.geography.sea_route(G.unpack(convoy.position),op.point(home)) if force.domain=="navy" else {"points":[home.position.duplicate(true)]}
		if route.has("error"):return route
		convoy.route=route.points;convoy.status="returning"
		return {"ok":true,"message":"The convoy is returning with its surviving cargo and troops."}
	return {"error":"No active convoy with that identifier."}

func advance(day:int)->void:
	for convoy:Dictionary in op.state.convoys:
		if convoy.status not in ["preparing","outbound","returning"]:continue
		var force:Dictionary=op.force(int(convoy.force_id))
		if force.is_empty():continue
		if convoy.status=="preparing":
			if day<int(convoy.depart_day):force.status="Preparing invasion · %d days" % (int(convoy.depart_day)-day);continue
			if op.effects.control(String(convoy.owner),force.region)<(.7 if force.domain=="air" else .5):force.status="Invasion waiting for regional control";continue
			convoy.status="outbound"
		if float(force.efficiency)<=0:continue
		var region:Dictionary=op.region_at(G.unpack(convoy.position),String(force.domain))
		var raiding=op.effects.mission_power(String(convoy.owner),region,"convoy_raiding",true)
		var escorts=op.effects.mission_power(String(convoy.owner),region,"convoy_escort",false)
		if force.domain=="navy" and raiding>0:op._losses(force,raiding/(1+escorts)*.5)
		var hulls=int(op.hardware(force));var previous=maxi(1,int(convoy.last_hardware))
		if hulls<previous:
			var lost_fraction=float(previous-hulls)/previous
			convoy.food=float(convoy.food)*(1-lost_fraction)
			if int(convoy.army_id)>0:op.host.apply_transport_casualties(int(convoy.army_id),lost_fraction)
			convoy.last_hardware=hulls
		if hulls<=0:
			convoy.status="lost";force.mission="hold";force.region={};force.position=op.base(int(force.base_id)).position.duplicate(true)
			op._event("%s transport lost at sea or in the air." % String(force.name));continue
		var arrived=G.travel(convoy,op.speed(force));force.position=convoy.position.duplicate(true)
		var index=int(op.host._field_army_index(int(convoy.army_id)))
		if index>=0:op.host.field_armies[index].position=convoy.position.duplicate(true)
		if not arrived:continue
		if convoy.status=="returning":
			var home:Dictionary=op.base(int(convoy.source_base))
			WorldSimulation.settlements.with_city_resources(String(home.city_id),func():WorldSimulation.food.receive_external_food(float(convoy.food)))
			convoy.food=0.0
			_disembark(convoy,home.position)
			convoy.status="returned";force.mission="hold";force.region={}
			op._event(String(force.name)+" returned to base.")
		else:
			if not bool(convoy.invasion):
				var destination:Dictionary=WorldSimulation.settlements.settlement_record(String(convoy.destination_id))
				if destination.is_empty() or not String(destination.get("occupied_by","")).is_empty():
					op._event("Destination unavailable; returning loaded transport to its base.")
					recall(int(convoy.id));continue
				WorldSimulation.settlements.with_city_resources(String(convoy.destination_id),func():WorldSimulation.food.receive_external_food(float(convoy.food)))
				convoy.delivered=convoy.food;convoy.food=0.0
			_disembark(convoy,convoy.destination_position)
			if bool(convoy.invasion) and index>=0:
				var order:Dictionary=op.host.order_city_operation(int(convoy.army_id),String(convoy.destination_owner),String(convoy.destination_id),true)
				op._event("Landing completed. "+String(order.get("message",order.get("error","The general has the army ashore."))))
			convoy.army_id=0
			var result=recall(int(convoy.id))
			if result.has("error"):force.status=String(result.error)
	while op.state.convoys.size()>64:
		var removed=false
		for convoy:Dictionary in op.state.convoys:
			if convoy.status not in ["preparing","outbound","returning"]:op.state.convoys.erase(convoy);removed=true;break
		if not removed:break

func _disembark(convoy:Dictionary,position:Dictionary)->void:
	var index=int(op.host._field_army_index(int(convoy.army_id)))
	if index>=0:
		var army:Dictionary=op.host.field_armies[index]
		army.position=position.duplicate(true);army.embarked=false;army.status="stationed";army.location_id="field_position";army.location_name="Landing area";army.destination_id=""
	# Clear only after an invasion order has consumed its army reference.
	if convoy.status=="returning":convoy.army_id=0
