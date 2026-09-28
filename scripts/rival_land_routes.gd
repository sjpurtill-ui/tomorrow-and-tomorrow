extends RefCounted
## RIVAL ARMIES MARCH BY LAND TOO.
##
## A rival's aggregate field formations (patrols, expeditions, exploring
## scouts: CivilizationSystem.foreign_formations) used to slide on the straight
## line point_a -> point_b, across bays and seas alike. Each one now follows
## the same land road the player's armies take (army_land_route.gd: bounded
## A*, taut dry legs, wading small streams, cached), and its march time grows
## with the real length of that road.
##
## - Planning is spread over days: at most PLANS_PER_DAY searches a day, in a
##   fixed order (deterministic for a seed), never from a per-frame getter.
## - Until its road is planned a formation holds at its own home (point_a).
## - With no land road at all (another landmass, no way round) it stays home;
##   it never walks on water. (Rival sea transport is not modelled here.)
## - Formations with their own planned route (rumour-led scouts, whose route
##   comes from the scout planner) or a commanded position (live rivals moved
##   by land_command.gd) are left alone.
## - Without a terrain survey (headless tools, early boot) the old straight
##   line stands: there is no ground to plan over.
##
## Fields added to a formation (additive; saved with it):
##   land_route        [{x,z},...] from point_a to point_b along the road
##   land_route_key    which point_a/point_b the road was planned for
##   land_route_state  "ok" | "none"
##   land_route_km     the road's length
##   land_leg_base     the scheduler's straight-line leg_days, before scaling
##   land_route_effort the road's effort in level km (march_terrain.gd); each
##                     land_route point also carries "e", the effort to it,
##                     so the formation slows on hills, in forest and marsh
##                     exactly as our own armies do.
## Static helpers; preload.

const Route:=preload("res://scripts/army_land_route.gd")
const March:=preload("res://scripts/march_terrain.gd")

const PLANS_PER_DAY:=3
## Lattice cells across a rival's straight line (army_land_route.gd).
const RIVAL_CELLS_ACROSS:=28.0
const MAX_ROUTE_POINTS:=96
## How far along the road a sighting's plausible way ahead reaches (km).
const ROAD_AHEAD_KM:=40.0

static func land()->Callable:
	return Route.world_land()

static func key(f:Dictionary)->String:
	var a:=Vector2(f.get("point_a",Vector2.ZERO)); var b:=Vector2(f.get("point_b",a))
	return "%.2f,%.2f>%.2f,%.2f" % [a.x,a.y,b.x,b.y]

static func managed(f:Dictionary)->bool:
	## Formations whose movement this module owns.
	return not f.has("command_position") and (f.get("route",[]) as Array).is_empty()

static func pending(f:Dictionary)->bool:
	return managed(f) and String(f.get("land_route_key",""))!=key(f)

static func plan(f:Dictionary,ground:Callable=Callable())->Dictionary:
	## Plans one formation's road in place. Returns the search result.
	if not ground.is_valid(): ground=land()
	if not ground.is_valid(): return {"error":"no survey"}
	var a:=Vector2(f.get("point_a",Vector2.ZERO)); var b:=Vector2(f.get("point_b",a))
	var fresh:=String(f.get("land_route_key",""))!=key(f)
	if fresh or not f.has("land_leg_base"): f["land_leg_base"]=float(f.get("leg_days",30.0))
	var straight:=a.distance_to(b)
	var mix:=mix_of(f)
	# The same measure as our armies, on a coarser lattice: up to
	# PLANS_PER_DAY of these are planned inside one day's tick.
	var ctx:=March.context(mix)
	if not ctx.is_empty(): ctx["cells_across"]=RIVAL_CELLS_ACROSS; ctx["key"]=String(ctx.key)+"|rival"
	var found:=Route.find(a,b,ground,true,ctx)
	if not found.has("error") and not found.has("e"): found=Route._with_profile(a,found.get("points",[]),mix,ground,found)
	f["land_route_key"]=key(f)
	if found.has("error"):
		f["land_route_state"]="none"
		f["land_route"]=[]
		f["land_route_km"]=0.0
		f["land_route_effort"]=0.0
		f["leg_days"]=float(f.land_leg_base)
		return found
	var pts:Array=found.get("points",[])
	var marks:PackedFloat32Array=found.get("e",PackedFloat32Array())
	var points:Array=[{"x":a.x,"z":a.y,"e":0.0}]
	# Bounded: keep every k-th point (always the last) with its effort mark.
	var stride:=maxi(1,ceili(float(pts.size())/float(MAX_ROUTE_POINTS-1)))
	for i in pts.size():
		if i%stride!=0 and i!=pts.size()-1: continue
		var p:Vector2=pts[i]
		points.append({"x":p.x,"z":p.y,"e":float(marks[i]) if i<marks.size() else 0.0})
	points[-1]["x"]=b.x; points[-1]["z"]=b.y
	var effort:=float(found.get("effort_km",found.length_km))
	f["land_route_state"]="ok"
	f["land_route"]=points
	f["land_route_km"]=float(found.length_km)
	f["land_route_effort"]=effort
	# March time grows with the real road and its ground (march_terrain.gd):
	# a detour round a bay, or hills and forest on the way, take longer.
	var ratio:=effort/straight if straight>0.05 else 1.0
	f["leg_days"]=clampf(float(f.land_leg_base)*maxf(1.0,ratio),1.0,1800.0)
	return found

## A rival formation's arms (its unit when it is known), for the ground's weights.
static func mix_of(f:Dictionary)->Dictionary:
	var unit:=String(f.get("formation_unit",f.get("unit","")))
	if unit=="": return {"foot":1.0}
	return {March.arm_of(unit):1.0}

## Where along a planned road a formation stands at this fraction of its
## march: the fraction of the road's effort, so rough stretches take longer.
static func point_at(road:Array[Vector2],marks:PackedFloat32Array,fraction:float)->Vector2:
	var total:=0.0
	for k in road.size()-1: total+=road[k].distance_to(road[k+1])
	if marks.size()!=road.size() or marks[-1]<=0.0:
		return Route.point_along(road[0],road.slice(1),total*clampf(fraction,0.0,1.0))
	var want:=marks[-1]*clampf(fraction,0.0,1.0)
	for k in road.size()-1:
		if want<=marks[k+1]:
			var f:=clampf((want-marks[k])/maxf(0.000001,marks[k+1]-marks[k]),0.0,1.0)
			return road[k].lerp(road[k+1],f)
	return road[-1]

static func _marks(f:Dictionary)->PackedFloat32Array:
	var out:=PackedFloat32Array()
	for p in f.get("land_route",[]):
		if not p is Dictionary or not (p as Dictionary).has("e"): return PackedFloat32Array()
		out.append(float(p.e))
	return out

static func advance(formations:Array,day:int,ground:Callable=Callable(),budget:int=PLANS_PER_DAY)->int:
	## Plans up to `budget` pending roads, in formation order. Returns how many.
	if not ground.is_valid(): ground=land()
	if not ground.is_valid(): return 0
	var done:=0
	for index in formations.size():
		if done>=budget: break
		var f:Variant=formations[index]
		if not f is Dictionary or not pending(f): continue
		plan(f,ground)
		done+=1
	return done

static func position(f:Dictionary,progress:float)->Vector2:
	## Where a managed formation stands at this fraction of its leg, or INF when
	## the old straight line applies (not managed, or no survey).
	if not managed(f): return Vector2.INF
	var a:=Vector2(f.get("point_a",Vector2.ZERO))
	if pending(f): return a if land().is_valid() else Vector2.INF
	if String(f.get("land_route_state",""))!="ok": return a
	var road:=Route.unpack(f.get("land_route",[]))
	if road.size()<2: return a
	return point_at(road,_marks(f),progress)

static func phase(f:Dictionary,day:float)->Dictionary:
	## The same out-and-back timing CivilizationSystem uses: {progress, outbound}.
	var leg:=maxf(1.0,float(f.get("leg_days",90.0)))
	var cycle:=fposmod(maxf(0.0,day-float(f.get("depart_day",0))),leg*2.0)
	var t:=cycle/leg
	return {"progress":clampf(t if t<=1.0 else 2.0-t,0.0,1.0),"outbound":t<=1.0}

static func motion_at(f:Dictionary,day:float)->Dictionary:
	var ph:=phase(f,day)
	return motion(f,float(ph.progress),bool(ph.outbound))

static func motion(f:Dictionary,progress:float,outbound:bool)->Dictionary:
	## What an observer sees of a marching formation: whether it moves, its
	## heading (the war map's convention) and the plausible road ahead,
	## bounded to ROAD_AHEAD_KM. {} when it is not moving on a planned road.
	if not managed(f) or pending(f) or String(f.get("land_route_state",""))!="ok": return {}
	var road:=Route.unpack(f.get("land_route",[]))
	if road.size()<2: return {}
	# Where it stands: the same effort fraction position() uses.
	var here_on:=point_at(road,_marks(f),progress)
	if not outbound: road.reverse()
	var total:=0.0
	for k in road.size()-1: total+=road[k].distance_to(road[k+1])
	if total<0.1: return {}
	var walked:=0.0
	var best_d:=INF
	var run:=0.0
	for k in road.size()-1:
		var c:=Geometry2D.get_closest_point_to_segment(here_on,road[k],road[k+1])
		var d:=c.distance_to(here_on)
		if d<best_d: best_d=d; walked=run+road[k].distance_to(c)
		run+=road[k].distance_to(road[k+1])
	var here:=Route.point_along(road[0],road.slice(1),walked)
	var ahead:=PackedVector2Array([here])
	var reach:=walked
	while ahead.size()<8 and reach<total:
		reach=minf(total,reach+ROAD_AHEAD_KM/6.0)
		ahead.append(Route.point_along(road[0],road.slice(1),reach))
		if reach-walked>=ROAD_AHEAD_KM: break
	if ahead.size()<2: return {}
	var direction:=(ahead[1]-ahead[0])
	if direction.length()<0.0001: return {}
	var heading:=-Vector2(0,-1).angle_to(direction)
	var packed:Array=[]
	for p in ahead: packed.append({"x":p.x,"z":p.y})
	return {"moving":true,"heading":heading,"road_ahead":packed}

static func valid(f:Dictionary)->String:
	## Save validation for the added fields; "" when fine.
	if not f.has("land_route"): return ""
	var road:Variant=f.get("land_route")
	if not road is Array or (road as Array).size()>MAX_ROUTE_POINTS: return "Foreign formation land route is malformed."
	for p in road:
		if not p is Dictionary or not is_finite(float(p.get("x",NAN))) or not is_finite(float(p.get("z",NAN))): return "Foreign formation land route has an invalid point."
	if String(f.get("land_route_state","ok")) not in ["ok","none"]: return "Foreign formation land route state is invalid."
	if not is_finite(float(f.get("land_route_km",0.0))) or not is_finite(float(f.get("land_leg_base",1.0))) or not is_finite(float(f.get("land_route_effort",0.0))): return "Foreign formation land route length is invalid."
	return ""
