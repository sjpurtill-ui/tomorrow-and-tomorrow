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
## By sea the party first walks to the shore of our land that way, however far,
## and puts out from there. It may sail on past where its boats dare stand off
## from land: that is the gamble. Water in sight of a coast counts a fifth
## (COAST_WEIGHT) of water out of sight of land, so
##     0.5 ^ (walk km / land endurance) x 0.5 ^ ((coast km x 0.2 + open km) / sea endurance)
## the walk being the way to the shore and the push inland where they land
## (INLAND_SHARE of the reach).
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
## A km sailed in sight of a coast, against a km out of sight of land.
const COAST_WEIGHT:=0.2
## An expedition asks after the people of any country it enters: it meets a
## people whose home lies within this of its track, or within their own land.
const MEET_KM:=150.0
## Ashore at the far end the party pushes on inland along its heading: this
## share of the reach, within these bounds, km.
const INLAND_SHARE:=0.3
const INLAND_MIN_KM:=120.0
const INLAND_MAX_KM:=800.0
## An expedition reads the signs of a people (smoke, tracks, worked ground)
## from at least this far off, and brings home a rumour of where they lie.
const SIGNS_KM:=400.0
## A home with open water within this of it can be reached in boats, km.
const HARBOUR_KM:=20.0
## A route with less than this share new to our charts brings home little.
const STALE_SHARE:=0.08
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
	var craft:Dictionary={}
	if by_sea:
		craft=sea_ready()
		if not bool(craft.ok):out.blocker=String(craft.reason);return out
		plan=_walk_then_sail(world,origin,heading,reach_km,craft)
		days=int(plan.get("days",0))
	else:
		plan=_push_on_foot(origin,heading,reach_km,world)
	out.route_plan=plan
	if not bool(plan.get("ok",false)):out.blocker=String(plan.get("reason","No way %s can be found." % heading));return out
	var km:=_farthest(plan.route,origin)
	if not by_sea:days=ceili(2.0*float(plan.distance_km)/walk_km_a_day()*1.15+10.0)
	out.km=km
	out.days=days
	out.provisions=float(party)*float(days)*RATION
	out.chance=return_chance(km,false)
	if by_sea:
		var voyage:Dictionary=plan.voyage
		var open:=float(voyage.get("open_km",0.0))
		var coast:=maxf(0.0,float(voyage.get("sea_km",0.0))-open)
		out.walk_km=float(plan.get("approach_km",0.0))
		out.inland_km=float(plan.get("inland_km",0.0))
		out.open_km=open
		out.coast_km=coast
		out.dare_km=float(craft.offshore_km)
		out.chance=clampf(pow(0.5,(float(out.walk_km)+float(out.inland_km))/maxf(1.0,endurance_km(false)))*pow(0.5,(coast*COAST_WEIGHT+open)/maxf(1.0,endurance_km(true))),0.01,0.99)
	# How much of the way our charts do not already hold.
	var way:=_route_km(plan.route)
	out.fresh_km=_fresh_km(plan.route,world)
	out.stale=way>1.0 and float(out.fresh_km)<way*STALE_SHARE
	out.label="an expedition %s %s" % ["by sea" if by_sea else "overland",heading]
	var staffing:Dictionary=world.scout_origin_staffing(String(origin_option.id))
	if away(world).size()>=AT_ONCE:out.blocker="%d expeditions are already away; wait for one to come home or be given up." % AT_ONCE
	elif int(staffing.available)<party:out.blocker="Only %d adults can be spared after other work and those already away." % int(staffing.available)
	elif float(staffing.food)+0.0001<float(out.provisions):out.blocker="They need %d food for %d days; %d is stored." % [ceili(float(out.provisions)),days,floori(float(staffing.food))]
	out.ok=String(out.blocker)==""
	return out

## By sea: on foot to the shore of our land that way (however far that is),
## then a pushed voyage of `reach_km` from there (sea_voyage.gd push), sailing
## past where the boats dare stand off if the bearing asks it. One route, the
## voyage's marks moved along by the walk. Planned once per heading, reach,
## boats and charted map: the card re-quotes as the god chooses.
static var _voyages:={}
static func _walk_then_sail(world:Node,origin:Vector2,heading:String,reach_km:float,craft:Dictionary)->Dictionary:
	if not world.scout_land_authority.is_valid():return {"ok":false,"reason":"No terrain survey is available. Unknown water cannot be charted."}
	var key:=var_to_str([world.get_instance_id(),origin,heading,reach_km,craft,world.fog_revision,int(world.next_scout_mission_id)])
	if _voyages.has(key):return (_voyages[key] as Dictionary).duplicate(true)
	# Where to put out from: the shore our land ends at that way, the shores a
	# half-turn to either side of it (a bay or a lake is no way out to sea), or
	# the water by home. The voyage that makes farthest along the bearing is taken.
	var bearing:=deg_to_rad(float(world.SCOUT_HEADINGS[heading]))
	var along:=Vector2.from_angle(bearing)
	var names:Array=world.SCOUT_HEADINGS.keys()
	var at:=names.find(heading)
	var walks:Array=[{}]
	for way:String in [heading,String(names[posmod(at-1,names.size())]),String(names[posmod(at+1,names.size())])]:
		var walk:=_push_on_foot(origin,way,4000.0,world,true)
		if bool(walk.get("ok",false)):walks.append(walk)
	var sea_days:=ceili(2.0*reach_km/float(craft.sail_km_per_day)*1.25+30.0)
	var plan:={"ok":false,"reason":"Our boats find no coast to make %s." % heading}
	var best:=-INF
	var tried:Array=[]
	for walk:Dictionary in walks:
		var land:Array=walk.get("route",[{"x":origin.x,"z":origin.y}])
		var walked:=float(walk.get("distance_km",0.0))
		var shore:=Vector2(float(land[-1].x),float(land[-1].z))
		if tried.any(func(p:Vector2)->bool:return p.distance_to(shore)<40.0):continue
		tried.append(shore)
		# The boats as they are, but free to hold the bearing out of sight of land.
		var bold:=SeaVoyage.capability()
		bold["offshore_km"]=1000000.0
		var planner:=SeaVoyage.new(world,shore,bold)
		planner.push=true
		var trial:Dictionary=planner.plan(sea_days,_seed(heading,reach_km,true,world),heading)
		if not bool(trial.get("ok",false)):
			if not bool(plan.ok) and walked>1.0:plan.reason="They can walk %d km to the shore, but %s" % [roundi(walked),String(trial.get("reason","find no water to put a boat into there.")).to_lower()]
			continue
		var sea_route:Array=trial.route
		var landing:Dictionary=sea_route[int(trial.voyage.landing_index)]
		var made:=(Vector2(float(landing.x),float(landing.z))-origin).dot(along)
		if made<=best:continue
		best=made
		var route:Array=land.duplicate(true)
		for k in range(1,sea_route.size()):route.append((sea_route[k] as Dictionary).duplicate())
		var shift:=land.size()-1
		var voyage:Dictionary=(trial.voyage as Dictionary).duplicate(true)
		voyage.sea_start=int(voyage.sea_start)+shift
		voyage.landing_index=int(voyage.landing_index)+shift
		voyage.walk_to_boat_km=roundf(walked+float(voyage.get("walk_to_boat_km",0.0)))
		voyage.craft_label=String(craft.label)
		plan=trial
		plan.route=route
		plan.voyage=voyage
		plan.distance_km=_route_km(route)
		plan["approach_km"]=walked
		plan["days"]=sea_days+ceili(2.0*walked/walk_km_a_day()*1.15)
		plan.planned_heading=world._compass_phrase(origin,Vector2(float(landing.x),float(landing.z)))
	# Ashore: on inland along the heading, in place of the scouts' short look round.
	if bool(plan.get("ok",false)):
		var voyage:Dictionary=plan.voyage
		var route:Array=(plan.route as Array).slice(0,int(voyage.landing_index)+1)
		var landing:Dictionary=route[-1]
		var inland:=_push_on_foot(Vector2(float(landing.x),float(landing.z)),heading,clampf(reach_km*INLAND_SHARE,INLAND_MIN_KM,INLAND_MAX_KM),world)
		if bool(inland.get("ok",false)):
			var steps:Array=inland.route
			for k in range(1,steps.size()):route.append((steps[k] as Dictionary).duplicate())
			plan["days"]=int(plan.days)+ceili(2.0*float(inland.distance_km)/walk_km_a_day()*1.15)-int(clampf(float(sea_days)*0.125,2.0,45.0))
			voyage.shore_km=roundf(float(inland.distance_km))
			plan.route=route
			plan.distance_km=_route_km(route)
		plan["inland_km"]=float(voyage.get("shore_km",0.0))
	if _voyages.size()>=24:_voyages.clear()
	_voyages[key]=plan.duplicate(true)
	return plan

## The length of a route, km.
static func _route_km(route:Array)->float:
	var total:=0.0
	for k in range(1,route.size()):total+=Vector2(float(route[k-1].x),float(route[k-1].z)).distance_to(Vector2(float(route[k].x),float(route[k].z)))
	return total

## How much of a route lies off our charts, km (sampled along it).
static func _fresh_km(route:Array,world:Node)->float:
	var fresh:=0.0
	for k in range(1,route.size()):
		var a:=Vector2(float(route[k-1].x),float(route[k-1].z));var b:=Vector2(float(route[k].x),float(route[k].z))
		var length:=a.distance_to(b)
		var steps:=clampi(ceili(length/12.0),1,60)
		for i in steps:
			if not bool(world._position_is_revealed(a.lerp(b,(float(i)+0.5)/float(steps)))):fresh+=length/float(steps)
	return fresh

## A land route pushed `reach_km` toward `heading` in legs, each walked on dry
## ground (the scouts' own planner), until the reach is spent or the land ends.
static func _push_on_foot(origin:Vector2,heading:String,reach_km:float,world:Node=null,to_the_shore:bool=false)->Dictionary:
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
	# For a voyage: the last short stretch down to the water itself.
	if to_the_shore and stop!="":
		for creep in 3:
			if points.size()>=ROUTE_POINTS:break
			var last:Dictionary=world._plan_open_scout_route(leg*0.25/float(creep+1),rng,heading,here)
			if not bool(last.get("ok",false)):break
			var tail:Array=last.route
			var edge:=Vector2(float(tail[-1].x),float(tail[-1].z))
			if edge.distance_to(origin)<=here.distance_to(origin)+1.0 or points.size()+tail.size()-1>ROUTE_POINTS:continue
			for k in range(1,tail.size()):points.append((tail[k] as Dictionary).duplicate())
			walked+=float(last.get("distance_km",here.distance_to(edge)))
			here=edge
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
		"expedition":{"chance":float(q.chance),"km":float(q.km),"endurance_km":float(q.endurance_km),"reach_km":float(q.reach_km),"by_sea":sea,"walk_km":float(q.get("walk_km",0.0)),"open_km":float(q.get("open_km",0.0)),"fresh_km":float(q.get("fresh_km",0.0))}}
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

## An expedition that reads a people's signs within SIGNS_KM goes to look:
## from the nearest dry point of its track it walks to them if the land
## allows a way no longer than half again that distance; one that came by
## sea coasts round in its boats to a home that stands by the water. Where it left its
## track, or INF when the signs lie too far or over water.
static func followed_signs(world:Node,route:Array,home:Vector2,by_boat:bool=false)->Vector2:
	var from:=Vector2.INF
	var near:=INF
	# The nearest point of the track itself if it is dry, else its nearest dry turn.
	var closest:Dictionary=world._closest_route_encounter(route,home)
	if closest.position is Vector2 and bool(world._scout_land_at(closest.position)):from=closest.position;near=float(closest.distance)
	for p:Dictionary in (route if not from.is_finite() else []):
		var at:=Vector2(float(p.x),float(p.z))
		if at.distance_to(home)<near and bool(world._scout_land_at(at)):near=at.distance_to(home);from=at
	if not from.is_finite() or near>SIGNS_KM:return Vector2.INF
	# A harbour town's mark can sit on the waterline: the dry ground beside it.
	if not bool(world._scout_land_at(home)):
		var beside:=Vector2.INF
		for ring:float in [1.0,2.0,4.0,8.0]:
			for k in 8:
				var p:=home+Vector2.from_angle(TAU*float(k)/8.0)*ring
				if not beside.is_finite() and bool(world._scout_land_at(p)):beside=p
		if not beside.is_finite():return Vector2.INF
		home=beside
	var way:Dictionary=world._plan_scout_land_route(from,home)
	if bool(way.get("ok",false)) and float(way.get("distance_km",INF))<=SIGNS_KM*1.5:return from
	# No way overland: a party that came in boats coasts round to a home that
	# stands by the water (HARBOUR_KM of it).
	if not by_boat:return Vector2.INF
	for k in 16:
		if not bool(world._scout_land_at(home+Vector2.from_angle(TAU*float(k)/16.0)*HARBOUR_KM)):return from
	return Vector2.INF

## A computer ruler's expeditions, at its monthly review, by the one rule
## (the people in scope): when its scouting staff has found nothing new to
## chart, its boats are fit for the sea, it is fed and none of its own is
## away, it sends one by sea: toward word of a people it has not met when it
## holds any (hearsay_over_the_sea), else a new direction each time, round
## the compass from one its own; the farther reach every other round. It will not send
## one over charted water, nor at worse than LEADERS_LEAST_CHANCE, nor more
## often than LEADERS_EVERY_DAYS. Same quote, same odds, same roll as ours.
##
## It stakes no more of its people than they can bear. The party is
## LEADERS_PARTY_SHARE of the people (PARTY_MIN to LEADERS_PARTY), and after
## sending one it waits until the lives it expects to lose, party x the chance
## of no return, are at most LEADERS_STAKE of its people a year:
##     wait = 365 x party x (1 - chance) / (people x LEADERS_STAKE) days
## never less than LEADERS_EVERY_DAYS. So 8,000 people at 1 in 10 send a party
## about once a year, 1,500 one in six years, 200 one in a generation. (Sent
## every half year whatever their number, 200 people buried some 3,600 at sea
## in 180 years, and no people outgrew what its boats took.)
const LEADERS_EVERY_DAYS:=180
const LEADERS_LEAST_CHANCE:=0.04
const LEADERS_PARTY:=20
const LEADERS_PARTY_SHARE:=0.01
const LEADERS_STAKE:=0.002

## How many a ruler of `people` sends.
static func leaders_party(people:float)->int:
	return clampi(roundi(people*LEADERS_PARTY_SHARE),PARTY_MIN,LEADERS_PARTY)

## Days a ruler of `people` waits after sending `party` at `chance` of return.
static func leaders_wait(people:float,party:int,chance:float)->int:
	var at_stake:=float(party)*(1.0-clampf(chance,0.0,1.0))
	return maxi(LEADERS_EVERY_DAYS,ceili(365.0*at_stake/maxf(0.01,people*LEADERS_STAKE)))
static func leaders_decide(plan:Dictionary={})->Dictionary:
	if WorldSimulation.actor_id=="player":return {}
	var world:Node=WorldSimulation.world
	var state:Node=WorldSimulation.state
	if world==null or not bool(state.settlement_site_committed) or bool(state.convoy_traveling):return {}
	var staff:Dictionary=world.scouting_staff.data
	var day:=int(state.elapsed_days)
	if day<int(staff.get("expedition_next_day",0)):return {}
	if bool(plan.get("hungry",false)) or float(staff.get("share",0.0))<=0.0:return {}
	if int(staff.get("fruitless",0))<1 and int(staff.get("land_fruitless",0))<1:return {}
	if not away(world).is_empty() or not bool(sea_ready().ok):return {}
	staff["expedition_next_day"]=day+LEADERS_EVERY_DAYS
	var turn:=int(staff.get("expedition_turn",0))
	staff["expedition_turn"]=turn+1
	var names:Array=world.SCOUT_HEADINGS.keys()
	# Round the compass three points at a time (every direction in eight tries).
	var heading:=String(names[posmod(absi(hash(String(WorldSimulation.actor_id)))+turn*3,names.size())])
	# Word of a people not yet met comes first: the compass point nearest it,
	# every other try (the open round goes on between).
	var aimed:=_word_to_follow(world,day)
	if aimed.is_finite() and turn%2==0:
		heading=String(names[posmod(roundi(rad_to_deg(fposmod((aimed-Vector2(world.player_world_origin)).angle(),TAU))/45.0),names.size())])
	var people:=maxf(1.0,float(state.population_exact))
	var party:=leaders_party(people)
	var q:=quote(heading,2500.0 if (turn>>3)%2==1 else 1200.0,true,party,world)
	if not bool(q.ok) or bool(q.get("stale",false)) or float(q.get("chance",0.0))<LEADERS_LEAST_CHANCE:return {"tried":heading,"sent":false,"why":String(q.get("blocker","")) if not bool(q.ok) else ("charted" if bool(q.get("stale",false)) else "too far")}
	var sent:=send(heading,float(q.reach_km),true,party,world)
	if bool(sent.get("ok",false)):staff["expedition_next_day"]=day+leaders_wait(people,party,float(q.chance))
	return {"tried":heading,"sent":bool(sent.get("ok",false)),"why":String(sent.get("error",""))}

## Where the freshest word of a people this one has not met points, or INF.
static func _word_to_follow(world:Node,day:int)->Vector2:
	var best:=Vector2.INF
	var newest:=-1
	for lead:Dictionary in world.rumor_network.list_leads("player",day):
		var met:=false
		for civ:Dictionary in world.civilizations:
			if String(civ.get("id",""))==String(lead.get("subject","")) and int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))>=2:met=true
		if met or int(lead.get("observed_day",0))<=newest:continue
		newest=int(lead.get("observed_day",0))
		best=world.rumor_network.vector(lead.center)
	return best

## WORD FROM OVER THE SEA. A people whose boats go to sea now and then hears
## of a people it has not met: worked timber on the tide, a storm-blown boat,
## a tale from the fishing grounds. Once a month for each people (the one in
## scope), for each unmet people, at
##     0.04 x its sea endurance / the distance   (0.2% to 3% a month)
## seeded. It is a rumour only: a rough place, wide of the truth, on the
## rumours map with the rest, and something to send an expedition toward.
## Never a meeting. Returns the peoples heard of.
const HEARSAY_RATE:=0.04
static func hearsay_over_the_sea(world:Node,day:int)->Array:
	var heard:=[]
	var actor:=String(WorldSimulation.actor_id)
	if posmod(day,30)!=posmod(absi(hash(actor+":sea_hearsay")),30):return heard
	var state:Node=WorldSimulation.state
	if not bool(state.settlement_site_committed) or bool(state.convoy_traveling):return heard
	var endurance:=endurance_km(true)
	if endurance<=0.0:return heard
	var home:Vector2=world.player_world_origin
	for civ:Dictionary in world.civilizations:
		if not bool(civ.get("alive",true)):continue
		var relation:Dictionary=civ.get("player_relation",{})
		if int(relation.get("contact_level",0))>=1:continue
		var id:=String(civ.get("id",""))
		if world.rumor_network.list_leads("player",day).any(func(lead:Dictionary)->bool:return String(lead.get("subject",""))==id):continue
		var there:Vector2=world._civilization_world_position(civ)
		var distance:=there.distance_to(home)
		if distance<1.0:continue
		var rng:=RandomNumberGenerator.new()
		rng.seed=int(world.last_world_seed)^day*40503^hash(actor+">"+id)
		if rng.randf()>=clampf(HEARSAY_RATE*endurance/distance,0.002,0.03):continue
		var wide:=clampf(distance*0.3,150.0,1500.0)
		var center:Vector2=world._bounded_world_point(there+Vector2.from_angle(rng.randf_range(-PI,PI))*wide*rng.randf_range(0.2,0.7))
		var lead:Dictionary=world.rumor_network.observation("player",id,"a people our fishers heard of",center,wide,day,"worked timber on the tide and a storm-blown boat's tale")
		lead.confidence=0.2
		if not bool(world.rumor_network.receive("player",lead,day)):continue
		heard.append(id)
		if actor=="player":
			_tell("WORD OF ANOTHER PEOPLE","Our fishers bring in worked timber that none of ours cut, and tell of a boat seen far out that was not ours. Some people live somewhere to the %s, by land or over the water we cannot say. It is on the map of rumours; scouts or an expedition could look for them." % String(world._compass_phrase(home,center)).to_lower(),"notice")
	return heard

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
