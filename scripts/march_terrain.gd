extends RefCounted
## THE ONE MEASURE OF MARCHING GROUND.
##
## How long ground takes an army to cross, from the terrain the map draws:
## slope (hills and mountains), forest cover, marsh, rivers (a ford is
## cheap, deep water costs days, a bridge on our road almost nothing), the
## roads between our places (a path, a cart track, a made road), and
## winter cold. Every march time in the game comes from here:
##   - the general's route (army_land_route.gd A*) weighs each step with
##     edge_effort(), so armies go round mountains, through passes, to fords
##     and along roads;
##   - profile() lays the same weights along the chosen road: the effort
##     ("level km") needed to reach each point of it;
##   - days() and walk_day() spend a day's march (the army's pace on open
##     level ground, military_campaign._field_army_speed) against that
##     profile, the first to state "about N days", the second to move the
##     army each day, so the stated days and the days walked agree.
## Rival formations use the same profile (rival_land_routes.gd).
##
## Arms: a column moves at its slowest element on each kind of ground.
## Foot, mounted, wheeled (guns, siege trains, carts) and motor (lorries,
## tracks) suffer differently; mix_of() reads a force's formations (and the
## cart train that hauls its food) into {class: open-ground pace ratio}.
## Historical calibration (sustained daily marches): foot 15-25 km/day on
## open ground, about half in forest or hills, a third or less in marsh and
## mountains; made roads about 15% faster for foot and much faster for carts.
## Static helpers; preload.

const Roads:=preload("res://scripts/settlement_roads.gd")
const UnitCatalog:=preload("res://scripts/military_unit_catalog.gd")

## Profile sampling step along a road (km), and the longest stored leg.
const SAMPLE_KM:=0.5
const LEG_MAX_KM:=3.0
const MAX_POINTS:=160
## Slope probe radius (km): the ground a column's width actually climbs.
const SLOPE_PROBE_KM:=0.5
## A lattice point this close to one of our roads is on it.
const ROAD_HALF_KM:=0.35
const MAX_FACTOR:=12.0

## Time on a kind of ground relative to open level ground, per arm.
const SLOPE_K:={"foot":3.5,"mounted":4.5,"wheeled":7.0,"motor":6.0}
const WOOD_K:={"foot":0.8,"mounted":1.2,"wheeled":2.0,"motor":2.5}
const WET_K:={"foot":1.6,"mounted":2.2,"wheeled":3.0,"motor":3.5}
## Level km of march per km climbed (Naismith: 600 m of ascent ~ 5 km).
const CLIMB_K:={"foot":7.0,"mounted":7.0,"wheeled":11.0,"motor":5.0}
## Roads by tier (0 footpath, 1 cart track, 2 made road): the pace on the
## road itself, and how much of the ground's penalty the road leaves.
const ROAD_BASE:=[{"foot":1.0,"mounted":1.0,"wheeled":0.95,"motor":0.95},{"foot":0.95,"mounted":0.95,"wheeled":0.8,"motor":0.75},{"foot":0.85,"mounted":0.88,"wheeled":0.65,"motor":0.55}]
const ROAD_RELIEF:=[0.6,0.35,0.15]
## One crossing, in level km: a ford, deep water (rafts, swimming the
## animals, days of it), a bridge on our road.
const FORD_COST:={"foot":2.0,"mounted":1.5,"wheeled":5.0,"motor":4.0}
const DEEP_COST:={"foot":28.0,"mounted":28.0,"wheeled":45.0,"motor":40.0}
const BRIDGE_COST:=0.4
## Winter: how much slower at full cold (-8 C and below).
const WINTER_K:={"foot":0.5,"mounted":0.7,"wheeled":0.7,"motor":0.4}

## Tests inject fixture ground; the game reads the map's own terrain.
## ground_override: Callable(Vector2)->{h, slope, wood, wet, t}
## crossing_override: Callable(Vector2,Vector2)->"" | "ford" | "deep"
## roads_override: [{a:Vector2, b:Vector2, tier:int}], bridge_override -1/0/1/2
static var ground_override:Callable=Callable()
static var crossing_override:Callable=Callable()
static var roads_override:Array=[]
static var use_roads_override:=false
static var bridge_override:=-1

static var _road_cache_key:=""
static var _road_cache:Array=[]
static var _trib_key:=-1
static var _trib_bounds:Array=[]


static func reset_overrides()->void:
	ground_override=Callable(); crossing_override=Callable(); roads_override=[]; use_roads_override=false; bridge_override=-1
	_road_cache_key=""; _road_cache=[]


# --------------------------------------------------------------------------
# The ground
# --------------------------------------------------------------------------

## The rendered terrain behind the land authority, or null (tests, headless).
static func _terrain()->Object:
	var world:Variant=WorldSimulation.world if WorldSimulation!=null else null
	if world==null: return null
	var auth:Variant=(world as Object).get("scout_land_authority")
	if not auth is Callable or not (auth as Callable).is_valid(): return null
	var o:Object=(auth as Callable).get_object()
	if o!=null and o.has_method("_height_at") and o.has_method("_climate_at") and o.has_method("_biome_from_climate"): return o
	return null


## Whether there is any ground to weigh (else every land step costs the same).
static func has_ground()->bool:
	return ground_override.is_valid() or _terrain()!=null


## {h, slope, wood, wet, t} at a point of land ({} when unknown).
static func ground_at(p:Vector2)->Dictionary:
	if ground_override.is_valid(): return ground_override.call(p)
	var terrain:=_terrain()
	if terrain==null: return {}
	var h:float=terrain.call("_height_at",p.x,p.y)
	var hx:float=terrain.call("_height_at",p.x+SLOPE_PROBE_KM,p.y)
	var hz:float=terrain.call("_height_at",p.x,p.y+SLOPE_PROBE_KM)
	var slope:=Vector2((hx-h)/SLOPE_PROBE_KM,(hz-h)/SLOPE_PROBE_KM).length()
	var climate:Dictionary=terrain.call("_climate_at",p.x,p.y,h)
	var biome:Dictionary=terrain.call("_biome_from_climate",p.x,p.y,h,climate)
	var id:=String(biome.get("id",""))
	var wet:=1.0 if id=="wetland" else (0.45 if id=="floodplain" else 0.0)
	return {"h":h,"slope":slope,"wood":float(biome.get("woodland",0.0)),"wet":wet,"t":float(climate.get("temperature",0.5)),"rain":float(climate.get("precipitation",0.5))}


## River crossing on the straight step a->b: "" | "ford" | "deep".
static func crossing(a:Vector2,b:Vector2)->String:
	if crossing_override.is_valid(): return String(crossing_override.call(a,b))
	var terrain:=_terrain()
	if terrain==null or not terrain.has_method("_world_river_x"): return ""
	# The great river: deep, but for its fords (a riffle every ~37 km).
	var ra:float=terrain.call("_world_river_x",a.y)
	var rb:float=terrain.call("_world_river_x",b.y)
	if is_finite(ra) and is_finite(rb) and signf(a.x-ra)!=signf(b.x-rb) and absf(a.x-ra)+absf(b.x-rb)>0.0:
		var t:=absf(a.x-ra)/maxf(0.0001,absf(a.x-ra)+absf(b.x-rb))
		var z:=lerpf(a.y,b.y,t)
		return "ford" if fposmod(z+float(posmod(int(GameState.world_seed),997)),37.0)<4.0 else "deep"
	# Its tributaries: smaller water, fordable.
	var tribs:Variant=terrain.get("world_tributary_courses")
	if tribs is Array and not (tribs as Array).is_empty():
		_index_tribs(tribs)
		var box:=Rect2(a,Vector2.ZERO).expand(b)
		for k in _trib_bounds.size():
			if not (_trib_bounds[k] as Rect2).intersects(box): continue
			var course:Array=tribs[k]
			for i in course.size()-1:
				var p:Vector3=course[i]; var q:Vector3=course[i+1]
				if Geometry2D.segment_intersects_segment(a,b,Vector2(p.x,p.z),Vector2(q.x,q.z))!=null: return "ford"
	return ""

## Whether any river runs through this box (else crossings need no test).
static func rivers_near(box:Rect2)->bool:
	if crossing_override.is_valid(): return true
	var terrain:=_terrain()
	if terrain==null or not terrain.has_method("_world_river_x"): return false
	for k in 17:
		var z:=lerpf(box.position.y,box.end.y,float(k)/16.0)
		var x:float=terrain.call("_world_river_x",z)
		if is_finite(x) and x>=box.position.x-1.0 and x<=box.end.x+1.0: return true
	var tribs:Variant=terrain.get("world_tributary_courses")
	if tribs is Array and not (tribs as Array).is_empty():
		_index_tribs(tribs)
		for r:Rect2 in _trib_bounds:
			if r.intersects(box): return true
	return false

static func _index_tribs(tribs:Array)->void:
	var key:=hash([tribs.size(),int(GameState.world_seed)])
	if key==_trib_key: return
	_trib_key=key; _trib_bounds=[]
	for course in tribs:
		var r:=Rect2()
		var first:=true
		for p:Vector3 in course:
			if first: r=Rect2(Vector2(p.x,p.z),Vector2.ZERO); first=false
			else: r=r.expand(Vector2(p.x,p.z))
		_trib_bounds.append(r.grow(0.1))


## Our roads: [{a, b, tier}] (the links between our places and the towns we
## know, as settlement_roads.gd draws them), and the bridge tier.
static func roads()->Array:
	if use_roads_override: return roads_override
	var day:=int(WorldSimulation.state.elapsed_days) if WorldSimulation!=null and WorldSimulation.state!=null else 0
	if not "Hearth Circle" in GameState.settlement_completed: return []
	var know:=Roads.knowledge()
	var key:="%d:%d:%d:%d" % [int(GameState.world_seed),day,int(know.get("tier",0)),GameState.player_settlements.size()]
	if key==_road_cache_key: return _road_cache
	_road_cache_key=key
	_road_cache=[]
	var places:=places_for_roads()
	for link in Roads.links(places):
		_road_cache.append({"a":places[link[0]][0],"b":places[link[1]][0],"tier":int(know.get("tier",0))})
	return _road_cache

static func bridge_tier()->int:
	if bridge_override>=0: return bridge_override
	return int(Roads.knowledge().get("bridge",0))

## The places the road network joins (mirrors settlement_roads._places()).
static func places_for_roads()->Array:
	var home:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
	var out:Array=[]
	for settlement in GameState.player_settlements:
		if not settlement is Dictionary: continue
		var at:Variant=settlement.get("position",Vector2.ZERO)
		if not at is Vector2 or (at as Vector2)==Vector2.ZERO: continue
		if bool(settlement.get("primary",false)): home=at
		out.append([at,0.10,"p:"+String(settlement.get("id",""))])
	if out.is_empty(): out.append([home,0.10,"p:home"])
	if CivilizationSystem!=null and CivilizationSystem.city_intelligence!=null:
		for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player","",false,home,Roads.MAX_LINK_KM*1.4):
			var location:Dictionary=city.get("position",{})
			out.append([Vector2(float(location.get("x",0.0)),float(location.get("z",0.0))),0.12,"f:"+String(city.get("city_id",""))])
	out.sort_custom(func(a:Array,b:Array)->bool:return (a[0] as Vector2).distance_squared_to(home)<(b[0] as Vector2).distance_squared_to(home))
	if out.size()>Roads.MAX_NODES: out.resize(Roads.MAX_NODES)
	return out

## Road tier at a point (-1 off every road), within `half` km of one.
static func road_at(p:Vector2,road_list:Array,half:float=ROAD_HALF_KM)->int:
	var best:=-1
	for r:Dictionary in road_list:
		var a:Vector2=r.a; var b:Vector2=r.b
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))<=half: best=maxi(best,int(r.tier))
	return best


# --------------------------------------------------------------------------
# Arms
# --------------------------------------------------------------------------

const _DEFAULT_PACE:={"levy":24.0,"line_infantry":26.0,"skirmisher":32.0,"cavalry":55.0,"siege_engineer":14.0,"field_artillery":18.0,"rifle_infantry":28.0,"machine_gun_company":22.0,"motorized_infantry":140.0,"armored_formation":95.0,"modern_artillery":80.0}

static func arm_of(unit:String)->String:
	var movement:=String(UnitCatalog.archetype(unit).get("movement","foot"))
	match movement:
		"mounted": return "mounted"
		"wheeled": return "wheeled"
		"motorized","tracked": return "motor"
	return "foot"

## {class: pace ratio to the slowest element} for a force. A force hauling
## its food on carts (the home's cart stock) brings a wheeled train.
static func mix_of(force:Dictionary)->Dictionary:
	var paces:={}
	for formation_variant in force.get("formations",[]):
		if not formation_variant is Dictionary: continue
		var formation:Dictionary=formation_variant
		if int(formation.get("count",0))<=0: continue
		var unit:=String(formation.get("unit","levy"))
		var pace:=float(UnitCatalog.archetype(unit).get("pace_km_day",_DEFAULT_PACE.get(unit,24.0)))
		var arm:=arm_of(unit)
		paces[arm]=minf(float(paces.get(arm,INF)),pace)
	if paces.is_empty(): return {"foot":1.0}
	var slowest:=INF
	for arm in paces: slowest=minf(slowest,float(paces[arm]))
	var mix:={}
	for arm in paces: mix[arm]=slowest/maxf(0.1,float(paces[arm]))
	if _carts_haul(force) and not mix.has("motor"): mix["wheeled"]=maxf(float(mix.get("wheeled",0.0)),1.0)
	return mix

static func _carts_haul(force:Dictionary)->bool:
	if force.has("train"): return bool(force.train)
	if WorldSimulation==null or WorldSimulation.state==null: return false
	var carts:=float(WorldSimulation.state.resource_stockpiles.get("Transport Carts",0.0))
	return carts>=maxf(1.0,float(force.get("troops",0))/96.0)

static func mix_key(mix:Dictionary)->String:
	var keys:=mix.keys(); keys.sort()
	var parts:=PackedStringArray()
	for k in keys: parts.append("%s:%.2f" % [k,float(mix[k])])
	return ",".join(parts)


# --------------------------------------------------------------------------
# Costs
# --------------------------------------------------------------------------

## Time factor of one arm on this ground (1 = open level ground).
static func class_factor(g:Dictionary,arm:String,road:int=-1)->float:
	var slope_f:=exp(float(SLOPE_K.get(arm,3.5))*maxf(0.0,float(g.get("slope",0.0))-0.02))
	var wood_f:=1.0+float(WOOD_K.get(arm,0.8))*clampf(float(g.get("wood",0.0)),0.0,1.0)
	var wet_f:=1.0+float(WET_K.get(arm,1.6))*clampf(float(g.get("wet",0.0)),0.0,1.0)
	var base:=1.0
	if road>=0:
		var tier:=clampi(road,0,2)
		var keep:=float(ROAD_RELIEF[tier])
		base=float((ROAD_BASE[tier] as Dictionary).get(arm,1.0))
		wood_f=1.0+(wood_f-1.0)*keep; wet_f=1.0+(wet_f-1.0)*keep
		slope_f=1.0+(slope_f-1.0)*maxf(keep,0.5)
	return minf(MAX_FACTOR,base*slope_f*wood_f*wet_f)

## A force's time factor on this ground: its slowest element there.
static func factor(g:Dictionary,mix:Dictionary,road:int=-1)->float:
	if g.is_empty(): return (_road_only(mix,road) if road>=0 else 1.0)
	var worst:=0.0
	for arm in mix: worst=maxf(worst,class_factor(g,String(arm),road)*float(mix[arm]))
	return maxf(worst,0.1)

static func _road_only(mix:Dictionary,road:int)->float:
	var worst:=0.0
	for arm in mix: worst=maxf(worst,float((ROAD_BASE[clampi(road,0,2)] as Dictionary).get(String(arm),1.0))*float(mix[arm]))
	return worst

static func _mix_value(table:Dictionary,mix:Dictionary)->float:
	var worst:=0.0
	for arm in mix: worst=maxf(worst,float(table.get(String(arm),0.0))*float(mix[arm]))
	return worst

## The lowest factor any ground can have for this force (for A*'s estimate).
static func floor_factor(mix:Dictionary,road_list:Array)->float:
	if road_list.is_empty(): return 1.0
	return minf(1.0,_road_only(mix,2 if road_list.any(func(r:Dictionary)->bool: return int(r.tier)>=2) else (1 if road_list.any(func(r:Dictionary)->bool: return int(r.tier)>=1) else 0)))

## Extra level km for one crossing.
static func crossing_cost(kind:String,mix:Dictionary,bridged:bool)->float:
	if kind=="": return 0.0
	if bridged: return BRIDGE_COST
	return _mix_value(FORD_COST if kind=="ford" else DEEP_COST,mix)

## The effort (level km) of one straight step between two sampled points.
static func edge_effort(a:Vector2,b:Vector2,ga:Dictionary,gb:Dictionary,mix:Dictionary,road_a:int=-1,road_b:int=-1,wet_ford:bool=false)->float:
	var length:=a.distance_to(b)
	var e:=length*(factor(ga,mix,road_a)+factor(gb,mix,road_b))*0.5
	if not ga.is_empty() and not gb.is_empty():
		var climb:=maxf(0.0,float(gb.get("h",0.0))-float(ga.get("h",0.0)))
		if climb>0.0: e+=climb*_mix_value(CLIMB_K,mix)*(0.5 if road_a>=0 and road_b>=0 else 1.0)
	var kind:=crossing(a,b) if length>0.0 else ""
	if kind=="" and wet_ford: kind="ford"
	e+=crossing_cost(kind,mix,road_a>=0 and road_b>=0 and bridge_tier()>=1)
	return e


# --------------------------------------------------------------------------
# A road's profile, the stated days and the daily march
# --------------------------------------------------------------------------

## The context A* and profile() need: {mix, key, roads, fmin, ground}.
static func context(mix:Dictionary={"foot":1.0})->Dictionary:
	var road_list:=roads()
	var ground:=has_ground()
	if not ground and road_list.is_empty() and not crossing_override.is_valid(): return {}
	var terrain_id:=0
	var t:=_terrain()
	if t!=null: terrain_id=t.get_instance_id()
	var key:="%s|%d|%d|%d|%d" % [mix_key(mix),hash(road_list.map(func(r:Dictionary)->Array: return [r.a,r.b,r.tier])),bridge_tier(),terrain_id,hash(ground_override)]
	return {"mix":mix,"key":key,"roads":road_list,"fmin":floor_factor(mix,road_list),"ground":ground}

## Lays the effort along a road: start, then the legs (Vector2) after it.
## Returns {points:[Vector2] (subdivided, last = the goal), e:[cumulative
## level km to each point], t:[climate temperature per point or -1],
## effort_km, length_km, ground:{why...}}. land (optional) marks wading.
static func profile(start:Vector2,legs:Array,mix:Dictionary,land:Callable=Callable())->Dictionary:
	var road_list:=roads()
	var points:Array[Vector2]=[]
	var marks:=PackedFloat32Array()
	var temps:=PackedFloat32Array()
	var total:=0.0
	var length:=0.0
	var why:={"hills":0.0,"forest":0.0,"marsh":0.0,"rivers":0.0,"road":0.0}
	var prev:=start
	var grounded:=has_ground()
	var gp:=ground_at(prev) if grounded else {}
	var rp:=road_at(prev,road_list) if not road_list.is_empty() else -1
	var was_wet:=false
	var all_legs:Array[Vector2]=[]
	for leg in legs: all_legs.append(leg if leg is Vector2 else Vector2(float(leg.x),float(leg.z)))
	var total_len:=0.0
	var q:=start
	for leg in all_legs: total_len+=q.distance_to(leg); q=leg
	var leg_max:=maxf(LEG_MAX_KM,total_len/float(MAX_POINTS))
	for leg:Vector2 in all_legs:
		var d:=prev.distance_to(leg)
		var steps:=maxi(1,ceili(d/SAMPLE_KM))
		var pieces:=maxi(1,ceili(d/leg_max))
		var per_piece:=maxi(1,ceili(float(steps)/float(pieces)))
		var from:=prev
		for s in range(1,steps+1):
			var p:=from.lerp(leg,float(s)/float(steps))
			var wet_now:=land.is_valid() and not bool(land.call(p))
			var gq:=ground_at(p) if grounded and not wet_now else ({} if not grounded else gp)
			var rq:=road_at(p,road_list) if not road_list.is_empty() else -1
			# A strip of water on the road (a stream, a ford): waded once.
			var wading:=wet_now and not was_wet
			was_wet=wet_now
			var step_len:=prev.distance_to(p)
			var e:=edge_effort(prev,p,gp,gq,mix,rp,rq,wading)
			if not gq.is_empty():
				var h:=float(gq.get("h",0.0))
				why.hills+=step_len*maxf(0.0,factor({"slope":float(gq.get("slope",0.0))},mix)-1.0)+maxf(0.0,h-float(gp.get("h",h)))*_mix_value(CLIMB_K,mix)
				why.forest+=step_len*maxf(0.0,factor({"wood":float(gq.get("wood",0.0))},mix)-1.0)
				why.marsh+=step_len*maxf(0.0,factor({"wet":float(gq.get("wet",0.0))},mix)-1.0)
			if rq>=0: why.road+=step_len
			var kind:=crossing(prev,p)
			if kind!="" or wading: why.rivers+=1.0
			total+=e; length+=step_len
			prev=p; gp=gq; rp=rq
			if s%per_piece==0 or s==steps:
				points.append(p); marks.append(total); temps.append(float(gq.get("t",-1.0)) if not gq.is_empty() else -1.0)
	return {"points":points,"e":marks,"t":temps,"effort_km":total,"length_km":length,"ground":why}

## Packs a profiled road for a save: [{x,z,e,t}].
static func pack(prof:Dictionary)->Array:
	var out:Array=[]
	var pts:Array=prof.get("points",[])
	var marks:PackedFloat32Array=prof.get("e",PackedFloat32Array())
	var temps:PackedFloat32Array=prof.get("t",PackedFloat32Array())
	for i in pts.size():
		var p:Vector2=pts[i]
		var row:={"x":p.x,"z":p.y,"e":float(marks[i]) if i<marks.size() else 0.0}
		if i<temps.size() and temps[i]>=0.0: row["t"]=snappedf(float(temps[i]),0.001)
		out.append(row)
	return out

## Whether a packed road carries its effort marks.
static func profiled(packed:Variant)->bool:
	if not packed is Array or (packed as Array).is_empty(): return false
	for p in packed:
		if not p is Dictionary or not (p as Dictionary).has("e"): return false
	return true

static func total_effort(packed:Array)->float:
	return float((packed[-1] as Dictionary).get("e",0.0)) if not packed.is_empty() else 0.0

## Position and km walked after `effort` level km along a packed road.
static func at_effort(origin:Vector2,packed:Array,effort:float)->Dictionary:
	var prev:=origin; var prev_e:=0.0; var km:=0.0
	for row in packed:
		var p:=Vector2(float(row.x),float(row.z)); var e:=float(row.get("e",0.0))
		var d:=prev.distance_to(p)
		if effort<=e:
			var f:=clampf((effort-prev_e)/maxf(0.000001,e-prev_e),0.0,1.0)
			return {"position":prev.lerp(p,f),"km":km+d*f,"t":float(row.get("t",-1.0))}
		km+=d; prev=p; prev_e=e
	return {"position":prev,"km":km,"t":float((packed[-1] as Dictionary).get("t",-1.0)) if not packed.is_empty() else -1.0}

## How much slower a day's march is in the cold at a place (season model:
## PlanetEnvironment's mean temperature and seasonal swing for the ground).
static func winter_factor(day:int,at:Vector2,climate_t:float,mix:Dictionary)->float:
	if climate_t<0.0: return 1.0
	var swing:=12.0
	if PlanetEnvironment!=null and PlanetEnvironment.has_method("seasonality_at"): swing=float(PlanetEnvironment.seasonality_at(at))
	var hemisphere:=-1.0 if at.y>0.0 else 1.0
	var celsius:=lerpf(-6.0,28.0,climate_t)+sin(fmod(float(day),365.0)/365.0*TAU)*hemisphere*swing
	var cold:=clampf((2.0-celsius)/10.0,0.0,1.0)
	return 1.0+_mix_value(WINTER_K,mix)*cold

## One day's march: the effort walked by the end of `day`, from `done`.
## The same step states the days (days()) and moves the army (daily).
static func walk_day(origin:Vector2,packed:Array,done:float,pace:float,day:int,mix:Dictionary)->float:
	var total:=total_effort(packed)
	var here:=at_effort(origin,packed,done)
	var budget:=maxf(2.0,pace)/winter_factor(day,here.position,float(here.t),mix)
	return minf(total,done+budget)

## Days of march to the end of a packed road, walking from `done` with a
## day's pace (open ground), day by day from the day after `today`.
static func days(origin:Vector2,packed:Array,pace:float,today:int,mix:Dictionary,done:float=0.0)->int:
	var total:=total_effort(packed)
	if total-done<=0.001: return 0
	var n:=0
	while done<total-0.001 and n<3650:
		n+=1
		done=walk_day(origin,packed,done,pace,today+n,mix)
	return n

## Plain words for what slows a road ("over hills and through forest").
static func ground_words(prof:Dictionary)->String:
	var why:Dictionary=prof.get("ground",{})
	var length:=maxf(0.1,float(prof.get("length_km",0.0)))
	var parts:=PackedStringArray()
	if float(why.get("hills",0.0))>length*0.15: parts.append("over hills" if float(why.hills)<length*0.8 else "over mountains")
	if float(why.get("forest",0.0))>length*0.12: parts.append("through forest")
	if float(why.get("marsh",0.0))>length*0.1: parts.append("through marsh")
	if float(why.get("rivers",0.0))>=1.0: parts.append("across a river" if float(why.rivers)<2.0 else "across rivers")
	if float(why.get("road",0.0))>length*0.5: parts.append("mostly by road")
	if parts.is_empty(): return ""
	if parts.size()==1: return parts[0]
	return ", ".join(parts.slice(0,parts.size()-1))+" and "+parts[-1]
