extends RefCounted
## Validated commands usable by either controller. No arbitrary method dispatch.
static func execute(order:Dictionary)->Dictionary:
	match String(order.get("kind","")):
		"move":
			if not order.get("destination") is Vector2:return {"error":"Choose a map destination."}
			return preload("res://scripts/civilization_travel.gd").begin(order.destination)
		"ambition":return WorldSimulation.direction.choose(String(order.get("id","")))
		"research_emphasis":
			var domain:=String(order.get("domain",""))
			var weight:=int(order.get("weight",-1))
			if not WorldSimulation.state.research_subcategory_allocations.has(domain) or weight<0 or weight>12:return {"error":"Choose a research domain and emphasis from 0 to 12."}
			WorldSimulation.discovery.set_domain_research_priority(domain,weight)
			return {"ok":true}
		"found":
			if WorldSimulation.state.settlement_site_committed:return {"error":"The founding site is already committed."}
			var origin:=WorldSimulation.world.player_world_origin
			var context:=preload("res://scripts/civilization_day.gd").context(origin)
			if not WorldSimulation.world._scout_land_at(origin):return {"error":"Choose dry land."}
			var water:=WorldSimulation.resources.water_access_snapshot(context)
			if not bool(water.accessible):return {"error":"The known water source is too far away."}
			WorldSimulation.state.settlement_founded_at=Vector3(origin.x,0,origin.y)
			WorldSimulation.state.settlement_site_committed=true
			WorldSimulation.state.convoy_traveling=false
			WorldSimulation.state.founding_journey.clear()
			return {"ok":true}
		"settle":
			var destination:Variant=order.get("destination")
			if not destination is Vector2:return {"error":"Choose a destination on the map."}
			var context:=preload("res://scripts/civilization_day.gd").context(destination)
			if not WorldSimulation.world._scout_land_at(destination) or not bool(WorldSimulation.resources.water_access_snapshot(context).accessible):return {"error":"The destination needs dry land and known reachable water."}
			if not WorldSimulation.world._scout_segment_is_land(WorldSimulation.world.player_world_origin,destination):return {"error":"The founding route must cross traversable land."}
			return WorldSimulation.settlements.begin_settlement_convoy(destination,0.0,String(order.get("name","")))
		"society_policy":return preload("res://scripts/society_exchange.gd").policy(String(order.get("migration","balanced")),String(order.get("sharing","selective")))
		"scouting_policy":return WorldSimulation.world.scouting_staff.set_policy(float(order.get("share",0)),String(order.get("focus","exploration")))
		"scout":return WorldSimulation.world.dispatch_scouts(int(order.get("days",30)),String(order.get("target","open_world")),String(order.get("heading","")))
		"diplomacy":return WorldSimulation.world.dispatch_diplomat(String(order.get("target","")),"",String(order.get("action","goodwill")))
		"training_policy":return WorldSimulation.military.training_staff.set_policy(String(order.get("service","army")),String(order.get("policy","regular")))
		"deploy":return WorldSimulation.military.create_field_army(int(order.get("count",0)),String(order.get("name","")))
		"area":return WorldSimulation.military.command_hierarchy.create_region(String(order.get("service","army")),order.get("vertices",[]),String(order.get("name","")))
		"objective":return WorldSimulation.military.command_hierarchy.assign(String(order.get("command","army")),[],order.get("region",{}),String(order.get("mission","defend")),String(order.get("target","")),String(order.get("vision","")))
		"recruit":return WorldSimulation.military.raise_recruits(int(order.get("count",0)))
		"train":return WorldSimulation.military.start_training(String(order.get("unit","")),String(order.get("weapon","")),int(order.get("count",0)))
		"production_target":return WorldSimulation.military.configure_production_line(int(order.get("job",-1)),int(order.get("target",0)),bool(order.get("paused",false)))
		"production":return WorldSimulation.military.start_production_line(String(order.get("item","")),int(order.get("target",0)))
		"base":return WorldSimulation.military.joint_operations.build_base(String(order.get("city","")),String(order.get("service","")))
		"service_mission":return WorldSimulation.military.joint_operations.assign(int(order.get("force",0)),order.get("region",{}),String(order.get("mission","")))
		"commission":return WorldSimulation.military.joint_operations.commission(int(order.get("base",0)),String(order.get("unit","")),int(order.get("count",0)),String(order.get("name","")))
	return {"error":"Unknown civilization order."}
