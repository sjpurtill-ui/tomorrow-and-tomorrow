extends RefCounted
## Relief uses a donor's ordinary trained formations, equipment and food stores.
static func quote(donor:String,target:Dictionary)->Dictionary:
	return WorldSimulation.scoped(preload("res://scripts/civilization_combat.gd").owner(donor),func()->Dictionary:
		var host:=WorldSimulation.military
		if host.command_hierarchy.battle.engaged(0):return {"error":"The donor's home force is already in battle."}
		if host.field_armies.size()>=host.field_army_capacity():return {"error":"The donor has no available command capacity."}
		var origin:=WorldSimulation.world.player_world_origin
		var destination:=Vector2(float(target.x),float(target.z))
		var route:=WorldSimulation.world._plan_scout_land_route(origin,destination)
		if not bool(route.get("ok",false)):return {"error":"No traversable land route can carry this relief force."}
		var days:=maxi(3,ceili(float(route.get("distance_km",origin.distance_to(destination)))/17.0))
		var available:=mini(int(host.home_army.get("troops",0)),floori(host._mobilized_count()*.2))
		var spare:=maxf(0,WorldSimulation.food.total_stored()-WorldSimulation.state.population_exact*20)
		var per_troop:=float(days*2+30)*.55
		var troops:=mini(available,floori(spare/maxf(1,per_troop)))
		if troops<3 or float(host.home_army.get("readiness",0))<.2:return {"error":"The donor cannot spare trained troops and their real provisions."}
		return {"ok":true,"troops":troops,"food":troops*per_troop,"travel_days":days,"travel_food":float(troops*days)*.55,"camp_food":float(troops)*30*.55,"route":route.route,"origin":origin,"destination":destination}
	)
static func reserve(donor:String,offer:Dictionary)->Dictionary:
	return WorldSimulation.scoped(preload("res://scripts/civilization_combat.gd").owner(donor),func()->Dictionary:
		var formed:=WorldSimulation.military.create_field_army(int(offer.troops),"Allied relief")
		if formed.has("error"):return formed
		WorldSimulation.food.issue_for_obligation(float(offer.food),"allied_relief","Provisions carried by allied relief",int(offer.travel_days)*2+30,int(offer.troops))
		var id:=int(formed.army.army_id)
		var index:=WorldSimulation.military._field_army_index(id)
		WorldSimulation.military.field_armies[index]["relief_assignment"]=true
		return {"owned_actor":WorldSimulation.actor_id,"owned_army":id,"route":offer.route,"origin":offer.origin,"destination":offer.destination}
	)
static func advance(receipt:Dictionary,day:int)->void:
	WorldSimulation.scoped(String(receipt.owned_actor),func()->void:
		var index:=WorldSimulation.military._field_army_index(int(receipt.owned_army))
		if index<0:return
		var force:Dictionary=WorldSimulation.military.field_armies[index]
		var progress:=clampf(1.0-float(int(receipt.due_day)-day)/maxf(1,float(receipt.travel_days)),0,1)
		var fraction:=1.0-progress if String(receipt.status)=="returning" else (progress if String(receipt.status)=="outbound" else 1.0)
		var point:=WorldSimulation.world.city_intelligence.route_position(receipt.route,fraction)
		force.position={"x":point.x,"z":point.y}
		force.location_id="allied_relief";force.location_name="Allied siege approaches"
	)
static func strength(receipt:Dictionary)->int:
	return WorldSimulation.scoped(String(receipt.owned_actor),func()->int:
		var index:=WorldSimulation.military._field_army_index(int(receipt.owned_army))
		return int(WorldSimulation.military.field_armies[index].troops) if index>=0 else 0
	)
static func restore(receipt:Dictionary)->void:
	WorldSimulation.scoped(String(receipt.owned_actor),func()->void:
		var index:=WorldSimulation.military._field_army_index(int(receipt.owned_army))
		if index>=0:
			var force:Dictionary=WorldSimulation.military.field_armies[index]
			force.erase("relief_assignment")
			force.location_id="player_home";force.location_name=WorldSimulation.state.settlement_name;force.status="stationed"
			var home:=WorldSimulation.world.player_world_origin
			force.position={"x":home.x,"z":home.y}
		WorldSimulation.food.receive_external_food(float(receipt.unused_food))
	)
