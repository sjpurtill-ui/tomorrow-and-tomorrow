extends RefCounted
## Sea voyages: a scouting party puts to sea from the nearest shore, sails a
## coast or crosses open water as far as its boats and its way-finding allow,
## lands on a far shore, walks inland, walks back to the boat and sails home
## the way it came.
##
## The route is one physical record like a land party's: home → launch →
## sea waypoints → the boat's last mooring → the landing → the walk inland. The
## party travels it out and back (scout_progress.gd), so everything on it is
## charted only on return. `voyage.landing_index` marks where the walk begins.
##
## Reach comes from what the people know of boats, sails and way-finding,
## weighted by how widely each is practised (adoption). The weights below are
## the whole rule; nothing else grants a ship.

## Hulls, rigs and way-finding, and what each adds to seaworthiness at full
## adoption. Sums near 0.3 make a coast-hugging boat; past 1.0 an ocean ship.
const CRAFT:={
	"hide_floats":0.04,"river_craft":0.10,"reed_bundle_boats":0.07,"hide_covered_boats":0.12,
	"plank_extended_dugouts":0.12,"coastal_watercraft":0.25,"keel_scarfing":0.08,
	"clinker_shell_construction":0.12,"carvel_frame_construction":0.15,
	"sail_panel_cutting":0.06,"sail_seaming":0.06,"mast_making":0.10,
	"wayfinding_stars":0.10,"star_rise_markers":0.04,"named_four_winds":0.05,
	"galley_navigation":0.10,"ocean_sailing":0.25,
}
## Below this a people has boats for rivers and the shallows only.
const MIN_SEAWORTHINESS:=0.30
## Of the hull entries, at least this much: sails and stars need a boat.
const MIN_HULL:=0.15
const HULLS:=["hide_floats","river_craft","reed_bundle_boats","hide_covered_boats","plank_extended_dugouts","coastal_watercraft","keel_scarfing","clinker_shell_construction","carvel_frame_construction"]
## Waypoint budget inside SCOUT_ROUTE_POINT_LIMIT (24): home and launch, the
## sea legs, the landing, the walk inland.
const SEA_POINT_LIMIT:=14
const SHORE_POINT_LIMIT:=6
## The farthest from home a party walks to its boat.
const LAUNCH_SEARCH_KM:=60.0
const NODE_LIMIT:=700

var world:Node
var origin:Vector2
var explorer:RefCounted
var craft:Dictionary

static func seaworthiness()->float:
	var known:Array=WorldSimulation.state.known_discoveries
	var total:=0.0
	for id:String in CRAFT:
		if id in known: total+=float(CRAFT[id])*WorldSimulation.discovery.adoption(id)
	return total

static func hull()->float:
	var known:Array=WorldSimulation.state.known_discoveries
	var total:=0.0
	for id:String in HULLS:
		if id in known: total+=float(CRAFT[id])*WorldSimulation.discovery.adoption(id)
	return total

## What the people's boats can do: whether they can put to sea, how far they
## dare stand off from land, and how far they make good in a day.
static func capability()->Dictionary:
	var sea:=seaworthiness()
	var reach:float=preload("res://scripts/research_mechanics.gd").sea_reach()
	if hull()<MIN_HULL or sea<MIN_SEAWORTHINESS:
		return {"ok":false,"seaworthiness":sea,"reason":"Our boats are for rivers and the shallows. Sea voyages need sturdier hulls, sails or way-finding practised widely."}
	var over:=sea-MIN_SEAWORTHINESS
	# Open water grows faster than linearly: hugging the coast first, then
	# island hops, then crossings out of sight of land.
	var offshore:=clampf((12.0+400.0*over*over)*reach,10.0,1600.0)
	var speed:=clampf(22.0+28.0*minf(sea,1.2),22.0,60.0)
	var label:="coast-hugging boats" if offshore<40.0 else ("boats that cross to islands in sight" if offshore<120.0 else ("ships that sail out of sight of land" if offshore<500.0 else "ocean-going ships"))
	return {"ok":true,"seaworthiness":sea,"offshore_km":roundf(offshore),"sail_km_per_day":roundf(speed),"label":label}

## Danger of the sea for the party's odds (ScoutSurvival terrain scale, 0..1):
## worse for poor boats, worse the more of the voyage is out of sight of land.
static func danger(sea:float,open_share:float)->float:
	return clampf(0.32+0.30*(1.0-clampf(sea,0.0,1.0))+0.20*clampf(open_share,0.0,1.0),0.2,0.8)

func _init(owner:Node,start:Vector2,abilities:Dictionary)->void:
	world=owner;origin=start;craft=abilities

func _in_world(point:Vector2)->bool:
	return absf(point.x)<=world.CIVILIZATION_WORLD_RADIUS_X_KM and absf(point.y)<=world.CIVILIZATION_WORLD_RADIUS_Z_KM

func _water(point:Vector2)->bool:
	return _in_world(point) and not world._scout_land_at(point)

## Every sample of the segment is water: a boat does not sail across a cape.
func _sea_segment(a:Vector2,b:Vector2)->bool:
	# The scouts' land sampling interval; the start point is already known wet.
	var samples:=clampi(ceili(a.distance_to(b)/maxf(.5,float(world.SCOUT_LAND_SAMPLE_KM))),1,512)
	if not _water(a):return false
	for i in range(1,samples+1):
		if not _water(a.lerp(b,float(i)/float(samples))):return false
	return true

## The nearest land within `radius` of a water point, or INF when out of
## sight of land.
func _shore_near(point:Vector2,radius:float)->Vector2:
	for i in 8:
		var probe:=point+Vector2.RIGHT.rotated(float(i)*TAU/8.0)*radius
		if _in_world(probe) and world._scout_land_at(probe):return probe
	return Vector2.INF

## The nearest water a party can walk to from home and push off into, with
## the last dry point on the way. Rings outward from home, every direction.
func launch_point()->Dictionary:
	# A harbour town's own mark can sit on the waterline: the boats are here.
	if not world._scout_land_at(origin):
		if not _water(origin):return {}
		var away:=Vector2.RIGHT
		for i in 8:
			var probe:=Vector2.RIGHT.rotated(float(i)*TAU/8.0)
			if world._scout_land_at(origin+probe*4.0):away=-probe;break
		return {"shore":origin,"water":origin,"walk_km":0.0,"bearing":away.angle()}
	for r:float in [1.0,2.0,4.0,7.0,12.0,20.0,32.0,45.0,LAUNCH_SEARCH_KM]:
		var best:={}
		for i in 24:
			var direction:=Vector2.RIGHT.rotated(float(i)*TAU/24.0)
			var water:=origin+direction*r
			if not _water(water):continue
			# Walk out until the first wet sample; the ground up to it must be dry.
			var shore:=origin
			var steps:=maxi(2,ceili(r/.5))
			for s in range(1,steps+1):
				var p:=origin.lerp(water,float(s)/float(steps))
				if not world._scout_land_at(p):water=p;break
				shore=p
			if not world._scout_segment_is_land(origin,shore):continue
			# A puddle is not a sea: open water must run on past the launch.
			if not _water(water+direction*6.0) and not _water(water+direction.rotated(.6)*6.0) and not _water(water+direction.rotated(-.6)*6.0):continue
			if best.is_empty() or origin.distance_to(shore)<float(best.walk_km):
				best={"shore":shore,"water":water,"walk_km":origin.distance_to(shore),"bearing":direction.angle()}
		if not best.is_empty():return best
	return {}

## Best-first search over water from the launch. Nodes within sight of land
## (a shore probe hits) reset the open-water count; a node farther out than
## the boats dare is never entered. The voyage ends at the shore node whose
## path saw the most uncharted coast.
func search(launch:Vector2,budget:float,bearing:float,step:float)->Dictionary:
	var offshore:=float(craft.offshore_km)
	var sight:=clampf(step,3.0,25.0)
	var nodes:Array[Dictionary]=[{"point":launch,"distance":0.0,"open":0.0,"fresh":0.0,"parent":-1,"score":0.0,"shore":_shore_near(launch,sight)}]
	var visited:Dictionary={Vector2i.ZERO:true}
	var pending:Array[int]=[0]
	var best:=-1
	var directions:Array[Vector2]=[]
	var turn:=posmod(roundi(bearing/(PI*.25)),8)
	for i in 8:directions.append(Vector2.RIGHT.rotated(float((i+turn)%8)*PI*.25))
	while not pending.is_empty() and nodes.size()<NODE_LIMIT:
		var selected:=0
		for i in range(1,pending.size()):
			if float(nodes[pending[i]].score)>float(nodes[pending[selected]].score):selected=i
		var index:=pending[selected];pending.remove_at(selected)
		var current:Dictionary=nodes[index]
		for direction:Vector2 in directions:
			var point:Vector2=current.point+direction*step
			var key:=Vector2i(roundi((point.x-launch.x)/step),roundi((point.y-launch.y)/step))
			if visited.has(key):continue
			var distance:=float(current.distance)+step
			if distance>budget:continue
			if not _water(point) or not _sea_segment(current.point,point):visited[key]=true;continue
			var shore:=_shore_near(point,sight)
			var open:=0.0 if is_finite(shore.x) else float(current.open)+step
			if open>offshore:continue
			visited[key]=true
			# Coast in view is what a voyage is for; empty sea charts little.
			var weight:=1.0 if is_finite(shore.x) else .35
			var fresh:float=float(current.fresh)+step*weight*explorer.novelty(shore if is_finite(shore.x) else point)
			var value:float=(fresh+distance*.10+origin.distance_to(point)*.15)/maxf(1.0,budget)
			nodes.append({"point":point,"distance":distance,"open":open,"fresh":fresh,"parent":index,"score":value,"shore":shore})
			var next:=nodes.size()-1;pending.append(next)
			if is_finite(shore.x) and (best<0 or value>float(nodes[best].score)):best=next
	if best<=0:return {"ok":false}
	var path:Array[Vector2]=[]
	var open_km:=0.0
	var i:=best
	while i>=0:
		path.push_front(nodes[i].point)
		if int(nodes[i].parent)>=0 and not is_finite(Vector2(nodes[i].shore).x):open_km+=step
		i=int(nodes[i].parent)
	return {"ok":true,"path":path,"landing":nodes[best].shore,"sea_km":float(nodes[best].distance),"open_km":open_km}

## Straight sea legs where the water allows, never longer than the boats may
## stand off from land on either side.
func compress(path:Array[Vector2])->Array[Vector2]:
	if path.size()<2:return path
	var reach:=float(craft.offshore_km)*2.0+40.0
	var out:Array[Vector2]=[path[0]]
	var anchor:=0
	while anchor<path.size()-1:
		var next:=path.size()-1
		while next>anchor+1 and (path[anchor].distance_to(path[next])>reach or not _sea_segment(path[anchor],path[next])):next-=1
		out.append(path[next]);anchor=next
	return out

## A planned voyage for `duration_days`, or {ok:false, reason}.
func plan(duration_days:int,seed_value:int,heading:String="")->Dictionary:
	if not bool(craft.get("ok",false)):return {"ok":false,"reason":String(craft.get("reason","Our boats cannot put to sea."))}
	var launch:=launch_point()
	if launch.is_empty():return {"ok":false,"reason":"No open water lies within %d km of home to put a boat into." % int(LAUNCH_SEARCH_KM)}
	var logistics:=clampf(float(WorldSimulation.state.simulation_metrics.get("logistics",0.16)),0.0,1.0)
	var walk:=14.0*(0.72+logistics*0.28)
	# Half the days out, half back. Of the outward half: the walk to the boat,
	# a quarter ashore at the far end, the rest at sea.
	var half:=float(duration_days)*.5
	var to_boat:=float(launch.walk_km)/walk
	var ashore_days:=clampf(half*.25,2.0,45.0)
	var sea_days:=half-to_boat-ashore_days
	if sea_days<1.0:return {"ok":false,"reason":"The walk to the shore leaves no days for sailing on a trip this short."}
	var budget:=sea_days*float(craft.sail_km_per_day)
	var bearing:=float(launch.bearing)
	if world.SCOUT_HEADINGS.has(heading):bearing=deg_to_rad(float(world.SCOUT_HEADINGS[heading]))
	else:
		var rng:=RandomNumberGenerator.new();rng.seed=seed_value
		bearing+=rng.randf_range(-1.2,1.2)
	explorer=preload("res://scripts/scout_frontier.gd").new(world,budget,bearing,origin)
	var found:={}
	var sea_points:Array[Vector2]=[]
	# Steps no coarser than the boats may stand off from land, or every step out
	# of sight of the coast would end the search a few legs from home.
	var step:=clampf(minf(budget/40.0,float(craft.offshore_km)*.4),4.0,40.0)
	for attempt in 3:
		var result:=search(launch.water,budget,bearing,step)
		if bool(result.get("ok",false)):
			var legs:=compress(result.path)
			if legs.size()<=SEA_POINT_LIMIT:found=result;sea_points=legs;break
		step*=2.0
	if found.is_empty():return {"ok":false,"reason":"Our boats found no coast to make within %d days' sailing." % int(sea_days)}
	var landing:Vector2=found.landing
	var points:Array[Vector2]=[origin]
	if Vector2(launch.shore).distance_to(origin)>.5:points.append(launch.shore)
	var sea_start:=points.size()
	points.append_array(sea_points)
	var landing_index:=points.size()
	points.append(landing)
	# The walk inland from the boat, over ground nobody has charted if any.
	var shore_km:=0.0
	var inland:=landing-Vector2(sea_points[-1])
	var walker:=preload("res://scripts/scout_frontier.gd").new(world,ashore_days*.5*walk,inland.angle(),landing)
	var ashore:Dictionary=walker.search(clampf(walker.budget/12.0,1.0,24.0),96)
	if bool(ashore.get("ok",false)):
		var steps:Array=ashore.route
		for k in range(1,mini(steps.size(),SHORE_POINT_LIMIT+1)):
			var p:=Vector2(float(steps[k].x),float(steps[k].z))
			if not world._scout_segment_is_land(points[-1],p):break
			shore_km+=points[-1].distance_to(p);points.append(p)
	var route:Array[Dictionary]=world._scout_route_dictionaries(points)
	var sea_km:=0.0
	for k in range(sea_start+1,landing_index+1):sea_km+=points[k-1].distance_to(points[k])
	var plan_result:={"ok":true,"route":route,"distance_km":world._scout_route_distance(route),"travel_mode":"sea","target_reachable":true,
		"ordered_heading":heading if world.SCOUT_HEADINGS.has(heading) else "","planned_heading":world._compass_phrase(origin,landing),
		"voyage":{"sea_start":sea_start,"landing_index":landing_index,"sea_km":roundf(sea_km),"shore_km":roundf(shore_km),"open_km":roundf(float(found.open_km)),"walk_to_boat_km":roundf(float(launch.walk_km)),"seaworthiness":float(craft.seaworthiness),"craft_label":String(craft.label)}}
	plan_result["novelty"]=explorer.score(plan_result)
	plan_result["fresh_km"]=explorer.fresh_km(plan_result)
	plan_result["terrain_danger"]=danger(float(craft.seaworthiness),float(found.open_km)/maxf(1.0,sea_km))
	return plan_result
