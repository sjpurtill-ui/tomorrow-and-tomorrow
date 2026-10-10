extends RefCounted
## EXPEDITIONS: a party sent to push as far as it can in one direction, by
## land or by sea, and come home with what lies there, as the great voyages
## and overland journeys did. Unlike the scouts' rounds (scouting_staff.gd),
## an expedition is the god's own commission: a heading, how far to push,
## how many go, on foot or by boat when the boats allow it.
##
## The farther it pushes, the fewer come home. Each people has an ENDURANCE:
## the distance out at which half of such parties are never seen again
##     land: 650 km x pace (logistics, roads and route knowledge, mounts)
##     sea:  250 km + 1.6 x how far its boats stand out of sight of land
## and the chance of coming home from `km` out is
##     0.5 ^ (km / endurance)
## stated before it sails and rolled once, seeded, when it is due (resolve()).
## A party that comes home brings a wide band of charted country (REVEAL_KM
## each side of its track), meets the peoples it passed and loses some on the
## road; one that does not is first overdue, then given up, with everyone in
## it. The mission rides the scouts' own machinery (civilization_system.gd
## scout_missions), so its route, its return and its reports are theirs.
## Static; preload.

const SeaVoyage:=preload("res://scripts/sea_voyage.gd")
const ScoutSurvival:=preload("res://scripts/scout_survival.gd")

## How far to push, km one way.
const REACHES:=[300,600,1200,2500,5000]
const PARTY_MIN:=12
const PARTY_MAX:=200
const PARTY_DEFAULT:=40
## Expeditions away at once.
const AT_ONCE:=2
## Charted each side of a returning expedition's track, km.
const REVEAL_KM:=32.0
## Food a person a day on the road (as the scouts).
const RATION:=0.55
## Of those who come home, this share of the odds against is lost on the way.
const ROAD_TOLL:=0.3
const LAND_ENDURANCE_KM:=650.0
## A land leg the planner walks at a time, km.
const LEG_KM:=260.0
const ROUTE_POINTS:=24

## The people's pace on foot over open country, km a day.
static func walk_km_a_day()->float:
	var logistics:=clampf(float(WorldSimulation.state.simulation_metrics.get("logistics",0.16)),0.0,1.0)
	var knowledge:=clampf(WorldSimulation.discovery.effect("route_speed")+WorldSimulation.progression.effect("route_speed"),0.0,0.60)
	var mounts:=1.0+WorldSimulation.discovery.adoption("mounted_scouts")*0.50
	return 14.0*(0.72+logistics*0.28)*(1.0+knowledge)*mounts

## How far out half of such parties still come home, km.
static func endurance_km(by_sea:bool)->float:
	if by_sea:
		var craft:=SeaVoyage.capability()
		if not bool(craft.get("ok",false)):return 0.0
		return 250.0+1.6*float(craft.offshore_km)
	return LAND_ENDURANCE_KM*walk_km_a_day()/14.0

## The chance of coming home from `km` out.
static func return_chance(km:float,by_sea:bool)->float:
	var half:=endurance_km(by_sea)
	if half<=0.0:return 0.0
	return clampf(pow(0.5,maxf(0.0,km)/half),0.01,0.99)

## Whether the boats can carry an expedition: {ok, label, reason}.
static func sea_ready()->Dictionary:
	var craft:=SeaVoyage.capability()
	if not bool(craft.get("ok",false)):return {"ok":false,"reason":String(craft.get("reason","Our boats cannot put to sea."))}
	return {"ok":true,"label":String(craft.label),"offshore_km":float(craft.offshore_km),"sail_km_per_day":float(craft.sail_km_per_day)}

static func away(world:Node=null)->Array:
	if world==null:world=CivilizationSystem
	return (world.scout_missions as Array).filter(func(m:Dictionary)->bool:return m.has("expedition"))

## What sending an expedition would take and risk: {ok, blocker, heading,
## by_sea, reach_km, km (how far the route really pushes), days, party,
## provisions, chance, endurance_km, route_plan, origin, label}.
static func quote(heading:String,reach_km:float,by_sea:bool,party:int=PARTY_DEFAULT,world:Node=null)->Dictionary:
	if world==null:world=CivilizationSystem
	heading=heading.to_lower().strip_edges()
	party=clampi(party,PARTY_MIN,PARTY_MAX)
	var origin_option:Dictionary=world._scout_origin("")
	var origin:Vector2=origin_option.position
	var out:={"ok":false,"blocker":"","heading":heading,"by_sea":by_sea,"reach_km":reach_km,"party":party,"origin":origin,"origin_city_id":String(origin_option.id),"origin_label":String(origin_option.label),"endurance_km":endurance_km(by_sea)}
	if not world.SCOUT_HEADINGS.has(heading):out.blocker="Choose a direction.";return out
	var plan:Dictionary
	var days:=0
	if by_sea:
		var craft:=sea_ready()
		if not bool(craft.ok):out.blocker=String(craft.reason);return out
		# Out and back at sail, a walk to the boat and some days ashore at the far end.
		days=ceili(2.0*reach_km/float(craft.sail_km_per_day)*1.25+30.0)
		plan=_voyage(world,origin,days,_seed(heading,reach_km,true,world),heading)
	else:
		plan=_push_on_foot(origin,heading,reach_km,world)
	out.route_plan=plan
	if not bool(plan.get("ok",false)):out.blocker=String(plan.get("reason","No way %s can be found." % heading));return out
	var km:=_farthest(plan.route,origin)
	if not by_sea:days=ceili(2.0*float(plan.distance_km)/walk_km_a_day()*1.15+10.0)
	out.km=km
	out.days=days
	out.provisions=float(party)*float(days)*RATION
	out.chance=return_chance(km,by_sea)
	out.label="an expedition %s %s" % ["by sea" if by_sea else "overland",heading]
	var staffing:Dictionary=world.scout_origin_staffing(String(origin_option.id))
	if away(world).size()>=AT_ONCE:out.blocker="%d expeditions are already away; wait for one to come home or be given up." % AT_ONCE
	elif int(staffing.available)<party:out.blocker="Only %d adults can be spared after other work and those already away." % int(staffing.available)
	elif float(staffing.food)+0.0001<float(out.provisions):out.blocker="They need %d food for %d days; %d is stored." % [ceili(float(out.provisions)),days,floori(float(staffing.food))]
	out.ok=String(out.blocker)==""
	return out

## A pushed voyage (sea_voyage.gd push), planned once per heading, reach,
## boats and charted map: the card re-quotes as the god chooses.
static var _voyages:={}
static func _voyage(world:Node,origin:Vector2,days:int,seed_value:int,heading:String)->Dictionary:
	if not world.scout_land_authority.is_valid():return {"ok":false,"reason":"No terrain survey is available. Unknown water cannot be charted."}
	var craft:=SeaVoyage.capability()
	var key:=var_to_str([world.get_instance_id(),origin,days,seed_value,heading,craft,world.fog_revision])
	if _voyages.has(key):return (_voyages[key] as Dictionary).duplicate(true)
	var planner:=SeaVoyage.new(world,origin,craft)
	planner.push=true
	var plan:Dictionary=planner.plan(days,seed_value,heading)
	if _voyages.size()>=24:_voyages.clear()
	_voyages[key]=plan.duplicate(true)
	return plan

## A land route pushed `reach_km` toward `heading` in legs, each walked on dry
## ground (the scouts' own planner), until the reach is spent or the land ends.
static func _push_on_foot(origin:Vector2,heading:String,reach_km:float,world:Node=null)->Dictionary:
	if world==null:world=CivilizationSystem
	if not world.scout_land_authority.is_valid():return {"ok":false,"reason":"No terrain survey is available. Unknown ground cannot be assumed to be land."}
	var points:Array[Dictionary]=[{"x":origin.x,"z":origin.y}]
	var here:=origin
	var walked:=0.0
	var leg:=maxf(LEG_KM,reach_km/16.0)
	var stop:=""
	var rng:=RandomNumberGenerator.new();rng.seed=_seed(heading,reach_km,false,world)
	while walked<reach_km-1.0 and points.size()<ROUTE_POINTS:
		var plan:Dictionary=world._plan_open_scout_route(minf(leg,reach_km-walked),rng,heading,here)
		if not bool(plan.get("ok",false)):stop="the land gives out";break
		var route:Array=plan.route
		var end:Dictionary=route[-1]
		var there:=Vector2(float(end.x),float(end.z))
		# A leg that only circles back is the end of the land that way.
		if there.distance_to(origin)<=here.distance_to(origin)+leg*0.25:stop="the land turns back on itself";break
		if points.size()+route.size()-1>ROUTE_POINTS:break
		for k in range(1,route.size()):points.append((route[k] as Dictionary).duplicate())
		walked+=float(plan.get("distance_km",here.distance_to(there)))
		here=there
	if points.size()<2:return {"ok":false,"reason":"Our people find no way %s on foot from home." % heading}
	return {"ok":true,"route":points,"distance_km":walked,"travel_mode":"land","target_reachable":true,"ordered_heading":heading,"planned_heading":world._compass_phrase(origin,here),"stopped":stop}

static func _farthest(route:Array,origin:Vector2)->float:
	var far:=0.0
	for p:Dictionary in route:far=maxf(far,Vector2(float(p.x),float(p.z)).distance_to(origin))
	return far

static func _seed(heading:String,reach_km:float,by_sea:bool,world:Node=null)->int:
	if world==null:world=CivilizationSystem
	return int(world.last_world_seed)^heading.hash()^roundi(reach_km)*7919^(104729 if by_sea else 0)^int(world.next_scout_mission_id)*2654435761

## Sends it: food issued now, the party counted away until it is home or given
## up. {ok, mission_id, message} or {error}.
static func send(heading:String,reach_km:float,by_sea:bool,party:int=PARTY_DEFAULT,world:Node=null)->Dictionary:
	if world==null:world=CivilizationSystem
	var q:=quote(heading,reach_km,by_sea,party,world)
	if not bool(q.ok):return {"error":String(q.blocker)}
	var plan:Dictionary=q.route_plan
	var start:=int(WorldSimulation.state.elapsed_days)
	var issued:float=WorldSimulation.settlements.with_city_resources(String(q.origin_city_id),func()->float:return WorldSimulation.food.issue_for_obligation(float(q.provisions),"scouting","Expedition %s" % String(q.heading),float(q.days),int(q.party)))
	if issued+0.0001<float(q.provisions):return {"error":"The stores changed before the expedition could be provisioned."}
	var origin:Vector2=q.origin
	var route:Array[Dictionary]=[]
	route.assign(plan.route)
	var sea:=bool(q.by_sea)
	var id:=int(world.next_scout_mission_id)
	var mission:={"mission_id":id,"start_day":start,"return_day":start+int(q.days),"duration_days":int(q.days),"personnel":int(q.party),"population_sources":{"productive":int(q.party)},"provisions":issued,
		"route":route,"planned_distance":float(plan.get("distance_km",q.km)),"ordered_heading":String(q.heading),"planned_heading":String(plan.get("planned_heading",q.heading)),
		"origin_city_id":String(q.origin_city_id),"origin_label":String(q.origin_label),"origin_position":{"x":origin.x,"z":origin.y},
		"target_id":"open_world","target_kind":"explore","target_civ_id":"","target_city_id":"","target_label":String(q.label).to_upper(),"target_position":{},"reached_target":true,
		"travel_mode":"sea" if sea else "land","route_status":"outbound_and_returning","concealment":0.75,"evasion":0.85,
		"terrain_danger":float(plan.get("terrain_danger",0.5)) if sea else float(world._scout_terrain_danger(route)),"veterancy":float(world.scouting_staff.veterancy()),
		"expedition":{"chance":float(q.chance),"km":float(q.km),"endurance_km":float(q.endurance_km),"reach_km":float(q.reach_km),"by_sea":sea}}
	if sea:mission["voyage"]=(plan.voyage as Dictionary).duplicate(true)
	var variance:int=world._scout_timing_variance(int(q.days),id,start)
	mission["timing_variance_days"]=variance
	mission["actual_return_day"]=maxi(start+2,start+int(q.days)+variance)
	world.next_scout_mission_id=id+1
	(world.scout_missions as Array).append(mission)
	var message:="%d of our people set out %s, %s %s from %s, to push %d km and come home. They carry %d food for about %d days. Of expeditions pushed so far, about %d in 100 come home." % [int(q.party),"by boat" if sea else "on foot",String(q.heading),"across the sea" if sea else "overland",String(q.origin_label),roundi(float(q.km)),roundi(issued),int(q.days),roundi(float(q.chance)*100.0)]
	world._record_world_event("Expedition departs",message,"diplomacy",start)
	_tell("AN EXPEDITION SETS OUT",message,"notice")
	return {"ok":true,"mission_id":id,"message":message}

## When an expedition is due (civilization_system.gd _complete_scout_mission):
## the seeded roll against its stated chance. Lost, it is first overdue (its
## return pushed back) and then given up; returns true while it is not home.
static func resolve(mission:Dictionary,day:int,world:Node=null)->bool:
	if world==null:world=CivilizationSystem
	var e:Dictionary=mission.expedition
	if bool(e.get("lost",false)):
		var count:=int(mission.get("personnel",0))
		WorldSimulation.state.register_population_deaths(count,"lost on an expedition")
		var text:="No word has come from the %d who went %s %s since they left %d days ago. They are given up: whatever they found is lost with them." % [count,"by sea" if bool(e.by_sea) else "overland",String(mission.get("ordered_heading","")),day-int(mission.start_day)]
		world._record_world_event("Expedition given up",text,"diplomacy",day)
		_tell("THE EXPEDITION IS GIVEN UP",text,"major")
		_remember(mission,"lost",count,day,world)
		world._erase_scout_mission(mission)
		return true
	if e.has("rolled"):return false
	var rng:=RandomNumberGenerator.new()
	rng.seed=int(world.last_world_seed)^int(mission.mission_id)*1000003^int(mission.start_day)*7907
	var roll:=rng.randf()
	e.rolled=roll
	if roll<float(e.chance):return false
	e.lost=true
	var wait:=maxi(30,roundi(float(mission.get("duration_days",90))*0.3))
	mission.actual_return_day=day+wait
	mission.return_day=maxi(int(mission.return_day),day)
	_tell("THE EXPEDITION IS OVERDUE","The expedition %s %s was due home and has not come. We wait for word another %d days." % ["by sea" if bool(e.by_sea) else "overland",String(mission.get("ordered_heading","")),wait],"notice")
	return true

## The road home for one that returns: of those who went, some die on the way
## in proportion to the odds against (ROAD_TOLL). As _resolve_party_fate's.
static func homecoming(mission:Dictionary,day:int,world:Node=null)->Dictionary:
	if world==null:world=CivilizationSystem
	var e:Dictionary=mission.expedition
	var personnel:=maxi(1,int(mission.get("personnel",1)))
	var rng:=RandomNumberGenerator.new()
	rng.seed=int(world.last_world_seed)^int(mission.mission_id)*7919^day*31
	var lost:=0
	var each:=(1.0-float(e.chance))*ROAD_TOLL
	for i in personnel:
		if rng.randf()<each:lost+=1
	lost=mini(lost,personnel-1)
	if lost>0:WorldSimulation.state.register_population_deaths(lost,"lost on an expedition")
	var line:="All %d came home." % personnel if lost==0 else "%d of the %d who went came home; %d died on the way." % [personnel-lost,personnel,lost]
	world.scouting_staff.record_homecoming(personnel-lost,personnel,lost,day)
	_remember(mission,"home",personnel-lost,day,world)
	_tell("THE EXPEDITION COMES HOME","The expedition %s %s is home from %d km out. %s Their charts are ours." % ["by sea" if bool(e.by_sea) else "overland",String(mission.get("ordered_heading","")),roundi(float(e.km)),line],"major")
	return {"lost":lost,"stayed":0,"returned":personnel-lost,"line":line,"mishap":"","death_chance":1.0-float(e.chance)}

## The god's people remember their expeditions: [{day, heading, by_sea, km,
## outcome, count}], latest last, at most 24.
static func _remember(mission:Dictionary,outcome:String,count:int,day:int,world:Node=null)->void:
	if world==null:world=CivilizationSystem
	var log:Array=(world.scouting_staff.data as Dictionary).get_or_add("expeditions",[])
	var e:Dictionary=mission.expedition
	log.append({"day":day,"heading":String(mission.get("ordered_heading","")),"by_sea":bool(e.by_sea),"km":float(e.km),"chance":float(e.chance),"outcome":outcome,"count":count})
	while log.size()>24:log.pop_front()

static func history(world:Node=null)->Array:
	if world==null:world=CivilizationSystem
	return (world.scouting_staff.data as Dictionary).get("expeditions",[])

static func _tell(title:String,text:String,severity:String)->void:
	WorldSimulation.state.simulation_events.push_front({"day":int(WorldSimulation.state.elapsed_days),"title":title,"description":text,"domain":"diplomacy","severity":severity})
	if WorldSimulation.state.simulation_events.size()>80:WorldSimulation.state.simulation_events.resize(80)
