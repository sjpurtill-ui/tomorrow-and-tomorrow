extends RefCounted
## ONE SUPPLY MODEL: how well each band, garrison and the home levy is fed
## today and why, and what a band would get at any point of the land.
## HOI4's supply in our own terms: hubs, the carriers' line and the country.
##
## A soldier's day of food away from home comes three ways (field_rations.gd,
## military_campaign.record_daily_provisions, which this model feeds):
##   carried  brought from our stores. What reaches a band is the carriers'
##            capacity at all (military_campaign._field_transport_delivery_ratio:
##            haulers, carts, the commander's care, supply groups) times the
##            HAUL: the share of a load the carriers do not eat on the road.
##            The haul falls with the days of hauling from the nearest hub
##            along the supply line, weighed on march_terrain.gd's ground
##            (hills, forest, marsh, rivers, our roads), and slows in winter.
##   foraged  found in the country: a share of what the carriers did not
##            bring (field_rations.forage_share), richer in green, wooded,
##            watered land, poor in winter and poorer for a host than a band.
##   local    a held town feeds its own garrison (field_rations.gd).
##
## Hubs are home and our other settlements (their stores). A held town is a
## depot on the line: the carts rest and stores gather there, so a line
## from it starts at RELAY of the cost of reaching it. When home is under
## siege, carts get out only as far as the besiegers let them.
##
## The supply field: one multi-source search (Dijkstra) over a lattice laid
## across our hubs, bands and known land, cached and rebuilt only when a hub,
## a road, the carriers or the lattice change (on a worker thread for the
## map, on the spot when the day's rations need it). Every point query is
## that field read at the point plus the day's terms (season, carriers,
## stores). The map's grid (hud/supply_map.gd) is this same function at the
## lattice's nodes, so the chart and the rations always agree.
##
## Engine: military_campaign._force_provision_access asks haul_for(force);
## field_rations.forage_share asks forage_factor(force).
## Screens: of_force(), of_army_id(), at_point(), forces(), words().
## Static helpers; preload.

const FieldRations:=preload("res://scripts/field_rations.gd")
const March:=preload("res://scripts/march_terrain.gd")

## A day's ration from this share up is a fed day (FieldRations.HUNGRY_BELOW);
## below STARVING_BELOW the band is going hungry (field_rations.short_words).
const WELL_FROM:=0.75
const STARVING_BELOW:=0.45

## The carriers: their pace on open level ground (km a day) and the share of
## a load they eat for each day of hauling beyond the first FREE_DAYS.
## Porters carry about 25 kg and eat about 1 kg a day each way (Engels'
## reckoning puts a porter's useful reach near two weeks). Ox carts carry
## far more for their teams' fodder; lorries are fast and burn fuel.
const CARRIERS:={
	"foot":{"pace":20.0,"loss":0.08,"words":"porters","arm":"foot"},
	"wheeled":{"pace":20.0,"loss":0.05,"words":"carts","arm":"wheeled"},
	"motor":{"pace":150.0,"loss":0.03,"words":"lorries","arm":"motor"},
}
const FREE_DAYS:=1.5
## A held town as a depot: the line from it starts at this share of the cost
## of reaching it from our own hubs.
const RELAY:=0.5
## The carts' reach, as the map draws it: where half a load still arrives.
const REACH_HAUL:=0.5
## Foraging: the typical richness of the land (CaravanLeader.forage_quality),
## the band size that forages at the stated rate, and the bounds.
const FORAGE_TYPICAL:=0.42
const SIZE_REF:=60.0
const FORAGE_SHARE_MAX:=0.6
## Ground weight when the map is not surveyed (tests, headless): open land.
const NEUTRAL_RICH:=FORAGE_TYPICAL
const NEUTRAL_SWING:=12.0

## The lattice: at most MAX_NODES a side, cells from the ladder (km), the
## bounds padded and snapped to SNAP cells so small moves rebuild nothing.
const MAX_NODES:=96
const CELL_LADDER:=[2.0,4.0,8.0,16.0,32.0,64.0]
const PAD_KM:=40.0
const SNAP:=8
## The lattice never reaches farther than this beyond our hubs.
const MAX_MARGIN_KM:=1500.0
## Nodes within this many cells of a hub read their cost from the hub itself.
const NEAR_CELLS:=1.5

const ROAD_WORDS:=["footpath","cart track","made road"]
## Neighbour steps (x, y), axial first.
const DX:=[1,-1,0,0,1,-1,1,-1]
const DY:=[0,0,1,-1,1,1,-1,-1]

static var _field:Dictionary={}
static var _job:BuildJob=null
static var _ground_cache:Dictionary={}
static var _known_cache:Array=[-1,-1,Rect2()]
static var _report_cache:Dictionary={}
static var _report_day:=-1
## Counters for tests and probes (never saved).
static var builds:=0
static var async_builds:=0


# --------------------------------------------------------------------------
# States and colours
# --------------------------------------------------------------------------

## "well" | "strained" | "starving" for a share of a day's food.
static func state_of(ratio:float)->String:
	if ratio>=WELL_FROM-0.0001: return "well"
	if ratio<STARVING_BELOW: return "starving"
	return "strained"

## Bars, glyphs and washes (HudTokens accents).
static func state_color(state:String)->Color:
	match state:
		"well": return HudTokens.GREEN
		"strained": return HudTokens.AMBER
		"starving": return HudTokens.RED
	return HudTokens.MUTED

## Text on paper (the accents' text-safe twins).
static func state_text_color(state:String)->Color:
	match state:
		"well": return HudTokens.GREEN_TEXT
		"strained": return HudTokens.AMBER_TEXT
		"starving": return HudTokens.RED_TEXT
	return HudTokens.MUTED

## Plain words for a state: "fed", "short of food", "going hungry".
static func state_words(state:String)->String:
	return String({"well":"fed","strained":"short of food","starving":"going hungry"}.get(state,""))


# --------------------------------------------------------------------------
# What the world gives the model
# --------------------------------------------------------------------------

static func _state()->Variant: return WorldSimulation.state if WorldSimulation!=null else null
static func _mc()->Variant: return WorldSimulation.military if WorldSimulation!=null else null
static func _world()->Variant: return WorldSimulation.world if WorldSimulation!=null else null
static func today()->int:
	var s:Variant=_state()
	return int(s.elapsed_days) if s!=null else 0

## Who carries our food to the field: "foot" (porters), "wheeled" (carts)
## or "motor" (lorries).
static func carrier()->String:
	var s:Variant=_state()
	if s==null: return "foot"
	if "internal_combustion" in s.known_discoveries and WorldSimulation.discovery!=null and float(WorldSimulation.discovery.adoption("internal_combustion"))>=0.5: return "motor"
	if float((s.resource_stockpiles as Dictionary).get("Transport Carts",0.0))>=1.0: return "wheeled"
	return "foot"

## Our hubs: home and our other settlements, then the towns we hold.
## [{id, name, kind: home|town|held, pos:Vector2, civ_id?, region_id?}]
static func hubs()->Array:
	var out:Array=[]
	var s:Variant=_state()
	var world:Variant=_world()
	if s==null or world==null or not bool(s.settlement_site_committed): return out
	if world.has_method("scout_origin_options"):
		for o:Dictionary in world.scout_origin_options():
			var at:Variant=o.get("position",Vector2.ZERO)
			if not at is Vector2 or not (at as Vector2).is_finite(): continue
			var name:=String(o.get("label",""))
			if bool(o.get("primary",false)) and String(s.settlement_name)!="": name=String(s.settlement_name)
			out.append({"id":"p:"+String(o.get("id","home")),"name":name if name!="" else "home","kind":"home" if bool(o.get("primary",false)) else "town","pos":at})
	if out.is_empty():
		out.append({"id":"p:home","name":String(s.settlement_name) if String(s.settlement_name)!="" else "home","kind":"home","pos":world.player_world_origin})
	var mc:Variant=_mc()
	if mc!=null and not (mc.occupation_forces as Array).is_empty():
		var Ledger=load("res://scripts/town_ledger.gd")
		var Pursuit=load("res://scripts/pursuit.gd")
		for f in mc.occupation_forces:
			var force:Dictionary=f
			if int(force.get("troops",0))<=0: continue
			var civ_id:=String(force.get("civ_id",""))
			var rid:=String(force.get("region_id",""))
			var hold:Dictionary=Ledger.hold(civ_id,rid)
			if not bool(hold.get("held",false)): continue
			var at:Vector2=Pursuit.town_position(rid)
			if not at.is_finite(): continue
			out.append({"id":"h:"+rid,"name":String(force.get("region_name","the held town")),"kind":"held","pos":at,"civ_id":civ_id,"region_id":rid})
	return out

## Where a force stands (Vector2.INF when it has no place).
static func force_pos(force:Dictionary)->Vector2:
	if force.has("region_id") and not force.has("army_id"):
		var Pursuit=load("res://scripts/pursuit.gd")
		var at:Vector2=Pursuit.town_position(String(force.region_id))
		if at.is_finite(): return at
	var p:Variant=force.get("position",{})
	if p is Dictionary and (p as Dictionary).has("x"): return Vector2(float(p.x),float(p.get("z",p.get("y",0.0))))
	if p is Vector2: return p
	return Vector2.INF

## The known land's bounds (cached per fog revision).
static func _known_box()->Rect2:
	var world:Variant=_world()
	if world==null: return Rect2()
	var areas:Array=world.revealed_areas
	var revision:=int(world.fog_revision)
	if int(_known_cache[0])==revision and int(_known_cache[1])==areas.size(): return _known_cache[2]
	var box:=Rect2()
	var first:=true
	for a in areas:
		if not a is Dictionary: continue
		var area:Dictionary=a
		var r:=maxf(0.0,float(area.get("radius",0.0)))
		var pts:Array=[]
		if String(area.get("kind","circle"))=="trail" and (area.get("points",[]) as Array).size()>=1: pts=area.points
		else: pts=[{"x":area.get("x",0.0),"z":area.get("z",0.0)}]
		for q in pts:
			if not q is Dictionary: continue
			var c:=Vector2(float(q.get("x",0.0)),float(q.get("z",0.0)))
			var b:=Rect2(c-Vector2(r,r),Vector2(r,r)*2.0)
			box=b if first else box.merge(b)
			first=false
	_known_cache=[revision,areas.size(),box]
	return box


# --------------------------------------------------------------------------
# The field's specification (main thread)
# --------------------------------------------------------------------------

## Everything a field is built from, with its key. {} when there is no home.
static func spec()->Dictionary:
	var hub_list:=hubs()
	if hub_list.is_empty(): return {}
	var settlements:Array=[]
	var held:Array=[]
	for h:Dictionary in hub_list: (held if String(h.kind)=="held" else settlements).append(h)
	if settlements.is_empty(): return {}
	var hub_box:=Rect2(settlements[0].pos,Vector2.ZERO)
	for h:Dictionary in hub_list: hub_box=hub_box.expand(h.pos)
	var box:=hub_box
	var mc:Variant=_mc()
	if mc!=null:
		for a in mc.field_armies:
			if not a is Dictionary or int((a as Dictionary).get("troops",0))<=0: continue
			var at:=force_pos(a)
			if at.is_finite(): box=box.expand(at)
	var known:=_known_box()
	if known.has_area(): box=box.merge(known)
	var limit:=hub_box.grow(MAX_MARGIN_KM)
	box=box.grow(PAD_KM).intersection(limit)
	var cell:=float(CELL_LADDER[CELL_LADDER.size()-1])
	for c in CELL_LADDER:
		var snap:=float(c)*float(SNAP)
		var lo:=Vector2(floorf(box.position.x/snap)*snap,floorf(box.position.y/snap)*snap)
		var hi:=Vector2(ceilf(box.end.x/snap)*snap,ceilf(box.end.y/snap)*snap)
		if maxf(hi.x-lo.x,hi.y-lo.y)/float(c)+1.0<=float(MAX_NODES): cell=float(c); break
	var grain:=cell*float(SNAP)
	var origin:=Vector2(floorf(box.position.x/grain)*grain,floorf(box.position.y/grain)*grain)
	var far:=Vector2(ceilf(box.end.x/grain)*grain,ceilf(box.end.y/grain)*grain)
	var nx:=mini(MAX_NODES,roundi((far.x-origin.x)/cell)+1)
	var ny:=mini(MAX_NODES,roundi((far.y-origin.y)/cell)+1)
	var who:=carrier()
	var mix:={String(CARRIERS[who].arm):1.0}
	var roads:=March.roads()
	var terrain:Object=March._terrain()
	var grounded:=March.has_ground()
	var world:Variant=_world()
	var land:Callable=Callable()
	if not grounded and world!=null and world.get("scout_land_authority") is Callable and (world.scout_land_authority as Callable).is_valid(): land=world.scout_land_authority
	var geo_key:=hash([int(GameState.world_seed),origin,cell,nx,ny,grounded,terrain.get_instance_id() if terrain!=null else 0,hash(March.ground_override),land.hash() if land.is_valid() else 0])
	var hub_rows:Array=[]
	for h:Dictionary in hub_list: hub_rows.append([String(h.id),String(h.kind),(h.pos as Vector2).snapped(Vector2.ONE*0.01)])
	var key:=hash([geo_key,who,hash(roads.map(func(r:Dictionary)->Array: return [r.a,r.b,r.tier])),March.bridge_tier(),hub_rows,hash(March.crossing_override)])
	if terrain!=null:
		# Worker builds read these; settle them here, on the main thread.
		PlanetEnvironment.prepare_macro_sampling()
		March.rivers_near(Rect2(origin,Vector2(float(nx-1),float(ny-1))*cell))
	return {"key":key,"geo_key":geo_key,"origin":origin,"cell":cell,"nx":nx,"ny":ny,"carrier":who,"mix":mix,"roads":roads.duplicate(true),"bridge":March.bridge_tier(),
		"settlements":settlements,"held":held,"grounded":grounded,"terrain":terrain,"land":land,"seed":int(GameState.world_seed)}


# --------------------------------------------------------------------------
# Building the field (pure: any thread)
# --------------------------------------------------------------------------

## A build on a worker thread (the map's), adopted on the main thread.
class BuildJob:
	var spec:Dictionary
	var ground:Dictionary
	var model:GDScript
	var result:Dictionary={}
	var task:=-1
	func _init(p_spec:Dictionary,p_ground:Dictionary,p_model:GDScript)->void:
		spec=p_spec; ground=p_ground; model=p_model
	func run()->void:
		result=model.call("build",spec,ground)

## The ground of every node: {h, slope, wood, wet, t, rain, rich, swing, land}.
static func sample_ground(spec:Dictionary)->Dictionary:
	var nx:=int(spec.nx); var ny:=int(spec.ny); var n:=nx*ny
	var origin:Vector2=spec.origin; var cell:=float(spec.cell)
	var grounded:=bool(spec.grounded)
	var land_fn:Callable=spec.get("land",Callable())
	# Packed arrays are values: fill these, then hand them over at the end.
	var h:=PackedFloat32Array(); var slope:=PackedFloat32Array(); var wood:=PackedFloat32Array(); var wet:=PackedFloat32Array()
	var t:=PackedFloat32Array(); var rain:=PackedFloat32Array(); var rich:=PackedFloat32Array(); var swing:=PackedFloat32Array()
	h.resize(n); slope.resize(n); wood.resize(n); wet.resize(n); t.resize(n); rain.resize(n); rich.resize(n); swing.resize(n)
	var land:=PackedByteArray(); land.resize(n)
	var seasons:=grounded and spec.get("terrain")!=null
	for i in n:
		var p:=origin+Vector2(float(i%nx),float(i/nx))*cell
		if grounded:
			var g:Dictionary=March.ground_at(p)
			h[i]=float(g.get("h",0.25)); slope[i]=float(g.get("slope",0.0)); wood[i]=float(g.get("wood",0.0)); wet[i]=float(g.get("wet",0.0))
			t[i]=float(g.get("t",-1.0)); rain[i]=float(g.get("rain",0.5))
			land[i]=1 if h[i]>0.015 else 0
			rich[i]=richness(rain[i],wood[i],wet[i],h[i]) if g.has("rain") or g.has("wood") else NEUTRAL_RICH
		else:
			h[i]=0.25; t[i]=-1.0; rain[i]=0.5; rich[i]=NEUTRAL_RICH
			land[i]=1 if (not land_fn.is_valid() or bool(land_fn.call(p))) else 0
		swing[i]=float(PlanetEnvironment.seasonality_unchecked(p)) if seasons else NEUTRAL_SWING
	return {"h":h,"slope":slope,"wood":wood,"wet":wet,"t":t,"rain":rain,"rich":rich,"swing":swing,"land":land}

## How much a band finds in this country: wild food and game as
## PlanetEnvironment counts them (profile_at's forage, game and soil), and
## what farmed land yields to requisition. Watered woods and good fields are
## rich; dry steppe and bare upland are poor.
static func richness(rain:float,wood:float,wet:float,h:float)->float:
	var forage:=clampf(rain*0.60+wood*0.30+(0.25 if wet>=0.99 else 0.0),0.0,1.0)
	var open:=wood<0.42 and wet<0.99 and rain>=0.36 and h<=6.0
	var game:=clampf(wood*(1.60-wood)+(0.20 if open else 0.0),0.0,1.0)
	# PlanetEnvironment._fertility by the biome the ground reads as.
	var soil:=0.55+rain*0.25
	if h>6.0: soil=0.05
	elif wet>=0.99: soil=0.60
	elif wet>=0.4: soil=0.95
	elif wood>0.42: soil=0.34
	elif rain<0.36: soil=0.14
	return clampf(forage*0.4+game*0.3+soil*0.3,0.0,1.2)

## The whole field for a spec: ground, costs (level km of hauling from the
## nearest hub), the hub each node draws on, and the line back to it.
static func build(spec:Dictionary,ground:Dictionary={})->Dictionary:
	var began:=Time.get_ticks_usec()
	var nx:=int(spec.nx); var ny:=int(spec.ny); var n:=nx*ny
	var origin:Vector2=spec.origin; var cell:=float(spec.cell)
	var mix:Dictionary=spec.mix
	if ground.is_empty() or int(ground.get("geo_key",0))!=int(spec.geo_key):
		ground=sample_ground(spec)
		ground["geo_key"]=int(spec.geo_key)
	var h:PackedFloat32Array=ground.h; var land:PackedByteArray=ground.land
	# Our roads, laid on the lattice (tier at each node, -1 off the road).
	var road:=PackedInt32Array(); road.resize(n); road.fill(-1)
	var half:=maxf(March.ROAD_HALF_KM,cell*0.6)
	for r:Dictionary in spec.roads:
		var a:Vector2=r.a; var b:Vector2=r.b
		var steps:=maxi(1,ceili(a.distance_to(b)/(cell*0.5)))
		for s in steps+1:
			var q:=a.lerp(b,float(s)/float(steps))
			var cx:=roundi((q.x-origin.x)/cell); var cy:=roundi((q.y-origin.y)/cell)
			for oy in range(-1,2):
				for ox in range(-1,2):
					var x:=cx+ox; var y:=cy+oy
					if x<0 or y<0 or x>=nx or y>=ny: continue
					var node:=origin+Vector2(float(x),float(y))*cell
					if node.distance_to(Geometry2D.get_closest_point_to_segment(node,a,b))<=half: road[y*nx+x]=maxi(road[y*nx+x],int(r.tier))
	# Each node's time factor for the carriers on its ground and road.
	var fac:=PackedFloat32Array(); fac.resize(n)
	var slope:PackedFloat32Array=ground.slope; var wood:PackedFloat32Array=ground.wood; var wet:PackedFloat32Array=ground.wet
	var grounded:=bool(spec.grounded)
	for i in n:
		if land[i]==0: fac[i]=INF; continue
		fac[i]=March.factor({"slope":slope[i],"wood":wood[i],"wet":wet[i]} if grounded else {},mix,road[i])
	# River crossings: the great river where a step changes its side, a
	# tributary where a step touches one (march_terrain.crossing decides).
	var terrain:Object=spec.get("terrain")
	var side:=PackedInt32Array(); side.resize(n)
	var trib:=PackedByteArray(); trib.resize(n)
	var all_edges:=March.crossing_override.is_valid()
	if terrain!=null and grounded and not all_edges:
		if terrain.has_method("_world_river_x"):
			for y in ny:
				var z:=origin.y+float(y)*cell
				var rx:=float(terrain.call("_world_river_x",z))
				if not is_finite(rx): continue
				for x in nx:
					var dx:=origin.x+float(x)*cell-rx
					side[y*nx+x]=1 if dx>0.0 else -1
		var tribs:Variant=terrain.get("world_tributary_courses")
		if tribs is Array:
			for course in tribs:
				var prev:=Vector2.INF
				for v in course:
					var q:=Vector2(float(v.x),float(v.z))
					if prev.is_finite():
						var steps:=maxi(1,ceili(prev.distance_to(q)/(cell*0.5)))
						for s in steps+1:
							var m:=prev.lerp(q,float(s)/float(steps))
							var x:=roundi((m.x-origin.x)/cell); var y:=roundi((m.y-origin.y)/cell)
							if x>=0 and y>=0 and x<nx and y<ny: trib[y*nx+x]=1
					prev=q
	var climb_k:=March._mix_value(March.CLIMB_K,mix)
	var bridged:=int(spec.bridge)>=1
	var ecost:=PackedFloat32Array(); ecost.resize(n*8); ecost.fill(INF)
	for y in ny:
		for x in nx:
			var i:=y*nx+x
			if land[i]==0: continue
			for k in 8:
				var xx:=x+int(DX[k]); var yy:=y+int(DY[k])
				if xx<0 or yy<0 or xx>=nx or yy>=ny: continue
				var j:=yy*nx+xx
				if land[j]==0: continue
				var diagonal:=k>=4
				if diagonal and (land[y*nx+xx]==0 or land[yy*nx+x]==0): continue
				var e:=cell*(1.41421356 if diagonal else 1.0)*(fac[i]+fac[j])*0.5
				var climb:=h[j]-h[i]
				if climb>0.0: e+=climb*climb_k*(0.5 if road[i]>=0 and road[j]>=0 else 1.0)
				if all_edges or (side[i]!=0 and side[j]!=0 and side[i]!=side[j]) or trib[i]==1 or trib[j]==1:
					var a:=origin+Vector2(float(x),float(y))*cell
					var b:=origin+Vector2(float(xx),float(yy))*cell
					var kind:=March.crossing(a,b)
					if kind!="": e+=March.crossing_cost(kind,mix,bridged and road[i]>=0 and road[j]>=0)
				ecost[i*8+k]=e
	# From our own hubs first; then the held towns join as depots.
	var sources:Array=[]
	for h_row:Dictionary in spec.settlements: sources.append({"id":String(h_row.id),"name":String(h_row.name),"kind":String(h_row.kind),"pos":h_row.pos,"base":0.0})
	var field:={"key":int(spec.key),"geo_key":int(spec.geo_key),"origin":origin,"cell":cell,"nx":nx,"ny":ny,"carrier":String(spec.carrier),"mix":mix,
		"ground":ground,"road":road,"fac":fac,"sources":sources}
	var pass1:=_search(field,ecost,sources)
	var held:Array=spec.get("held",[])
	if not held.is_empty():
		field["cost"]=pass1.cost
		for h_row:Dictionary in held:
			var reach:=_bilinear(field,pass1.cost,h_row.pos)
			if not is_finite(reach): continue
			sources.append({"id":String(h_row.id),"name":String(h_row.name),"kind":"held","pos":h_row.pos,"base":reach*RELAY,"region_id":String(h_row.get("region_id","")),"civ_id":String(h_row.get("civ_id",""))})
		pass1=_search(field,ecost,sources)
	field["cost"]=pass1.cost; field["src"]=pass1.src; field["parent"]=pass1.parent
	field["sources"]=sources
	field["ms"]=float(Time.get_ticks_usec()-began)/1000.0
	return field

## Dijkstra from the sources' seeds over the precomputed edge costs.
static func _search(field:Dictionary,ecost:PackedFloat32Array,sources:Array)->Dictionary:
	var nx:=int(field.nx); var ny:=int(field.ny); var n:=nx*ny
	var origin:Vector2=field.origin; var cell:=float(field.cell)
	var land:PackedByteArray=(field.ground as Dictionary).land
	var fac:PackedFloat32Array=field.fac
	var cost:=PackedFloat32Array(); cost.resize(n); cost.fill(INF)
	var src:=PackedInt32Array(); src.resize(n); src.fill(-1)
	var parent:=PackedInt32Array(); parent.resize(n); parent.fill(-1)
	var closed:=PackedByteArray(); closed.resize(n)
	var hf:=PackedFloat32Array(); var hi:=PackedInt32Array()
	var off:=PackedInt32Array()
	for k in 8: off.append(int(DY[k])*nx+int(DX[k]))
	for s_index in sources.size():
		var s:Dictionary=sources[s_index]
		var at:Vector2=s.pos
		var fx:=(at.x-origin.x)/cell; var fy:=(at.y-origin.y)/cell
		# The nodes round the hub, each at its own distance from it.
		for oy in range(-1,3):
			for ox in range(-1,3):
				var x:=floori(fx)+ox; var y:=floori(fy)+oy
				if x<0 or y<0 or x>=nx or y>=ny: continue
				var i:=y*nx+x
				if land[i]==0: continue
				var node:=origin+Vector2(float(x),float(y))*cell
				if node.distance_to(at)>cell*NEAR_CELLS: continue
				var c:=float(s.base)+node.distance_to(at)*fac[i]
				if c<cost[i]:
					cost[i]=c; src[i]=s_index; parent[i]=-1
					_push(hf,hi,c,i)
	while hi.size()>0:
		var i:=_pop(hf,hi)
		if closed[i]==1: continue
		closed[i]=1
		var ci:=cost[i]
		var base:=i*8
		for k in 8:
			var e:=ecost[base+k]
			if e>=INF: continue
			var j:=i+off[k]
			if closed[j]==1: continue
			var c:=ci+e
			if c<cost[j]:
				cost[j]=c; src[j]=src[i]; parent[j]=i
				_push(hf,hi,c,j)
	return {"cost":cost,"src":src,"parent":parent}

static func _push(f:PackedFloat32Array,ids:PackedInt32Array,priority:float,id:int)->void:
	f.append(priority); ids.append(id)
	var c:=f.size()-1
	while c>0:
		var p:=(c-1)/2
		if f[p]<=f[c]: break
		var tf:=f[p]; f[p]=f[c]; f[c]=tf
		var ti:=ids[p]; ids[p]=ids[c]; ids[c]=ti
		c=p

static func _pop(f:PackedFloat32Array,ids:PackedInt32Array)->int:
	var top:=ids[0]
	var last:=f.size()-1
	f[0]=f[last]; ids[0]=ids[last]
	f.resize(last); ids.resize(last)
	var c:=0
	while true:
		var l:=c*2+1; var r:=l+1; var m:=c
		if l<last and f[l]<f[m]: m=l
		if r<last and f[r]<f[m]: m=r
		if m==c: break
		var tf:=f[m]; f[m]=f[c]; f[c]=tf
		var ti:=ids[m]; ids[m]=ids[c]; ids[c]=ti
		c=m
	return top


# --------------------------------------------------------------------------
# The current field (main thread)
# --------------------------------------------------------------------------

## The field for the world as it stands. sync: build it now if needed (the
## day's rations); else start a build on a worker and return the last one
## (the map), which may be {} or older.
static func field(sync:=true)->Dictionary:
	var s:=spec()
	if s.is_empty(): return {}
	if int(_field.get("key",0))==int(s.key): return _field
	_poll(int(s.key))
	if int(_field.get("key",0))==int(s.key): return _field
	if _job!=null and int(_job.spec.key)==int(s.key):
		if not sync: return _field
		WorkerThreadPool.wait_for_task_completion(_job.task)
		_adopt(int(s.key))
		return _field
	if not sync:
		if _job==null: _start(s)
		return _field
	builds+=1
	_field=build(s,_cached_ground(s))
	_ground_cache[int(s.geo_key)]=_field.ground
	_trim_cache()
	_report_cache.clear()
	return _field

## Starts a worker build for the current world when it differs from the
## field in hand. Cheap to call every frame or so (the map does).
static func prefetch()->void:
	field(false)

## Whether the field in hand matches the world as it stands.
static func current()->bool:
	var s:=spec()
	return not s.is_empty() and int(_field.get("key",0))==int(s.key)

static func _cached_ground(s:Dictionary)->Dictionary:
	return _ground_cache.get(int(s.geo_key),{})

static func _trim_cache()->void:
	while _ground_cache.size()>2: _ground_cache.erase(_ground_cache.keys()[0])

static func _start(s:Dictionary)->void:
	_job=BuildJob.new(s,_cached_ground(s),load("res://scripts/supply_state.gd"))
	_job.task=WorkerThreadPool.add_task(_job.run,false,"Supply field")
	async_builds+=1

static func _poll(wanted:int)->void:
	if _job==null: return
	if not WorkerThreadPool.is_task_completed(_job.task): return
	WorkerThreadPool.wait_for_task_completion(_job.task)
	_adopt(wanted)

## Takes a finished worker build. It replaces the field in hand when it is
## what the world wants now, or when the one in hand is no better (older).
static func _adopt(wanted:int)->void:
	var done:=_job
	_job=null
	if done.result.is_empty(): return
	_ground_cache[int(done.result.geo_key)]=done.result.ground
	_trim_cache()
	if int(done.result.key)==wanted or int(_field.get("key",0))!=wanted:
		_field=done.result
		_report_cache.clear()

## Forget every field (tests; a new world).
static func reset()->void:
	if _job!=null and _job.task>=0: WorkerThreadPool.wait_for_task_completion(_job.task)
	_job=null; _field={}; _ground_cache.clear(); _report_cache.clear(); _report_day=-1
	_known_cache=[-1,-1,Rect2()]


# --------------------------------------------------------------------------
# Reading the field at a point
# --------------------------------------------------------------------------

## A lattice value at a point, bilinear over the land nodes around it
## (INF when none of them is reached).
static func _bilinear(field:Dictionary,values:PackedFloat32Array,p:Vector2)->float:
	var nx:=int(field.nx); var ny:=int(field.ny)
	var fx:=(p.x-(field.origin as Vector2).x)/float(field.cell)
	var fy:=(p.y-(field.origin as Vector2).y)/float(field.cell)
	if fx<0.0 or fy<0.0 or fx>float(nx-1) or fy>float(ny-1): return INF
	var x0:=mini(floori(fx),nx-2); var y0:=mini(floori(fy),ny-2)
	if nx<2: x0=0
	if ny<2: y0=0
	var u:=fx-float(x0); var v:=fy-float(y0)
	var total:=0.0; var weight:=0.0
	for corner in 4:
		var x:=x0+(corner&1); var y:=y0+(corner>>1)
		if x>=nx or y>=ny: continue
		var w:=(u if corner&1 else 1.0-u)*(v if corner>>1 else 1.0-v)
		var value:=values[y*nx+x]
		if w<=0.0 or not is_finite(value): continue
		total+=value*w; weight+=w
	if weight<=0.0:
		# At a node exactly (or all weight on unreached corners): the node itself.
		var node:=roundi(fy)*nx+roundi(fx)
		return values[node] if node>=0 and node<values.size() else INF
	return total/weight

## The node nearest a point, among the reached ones round it (-1 if none).
static func _node_near(field:Dictionary,p:Vector2)->int:
	var nx:=int(field.nx); var ny:=int(field.ny)
	var cost:PackedFloat32Array=field.cost
	var fx:=(p.x-(field.origin as Vector2).x)/float(field.cell)
	var fy:=(p.y-(field.origin as Vector2).y)/float(field.cell)
	var best:=-1; var best_d:=INF
	for oy in range(0,2):
		for ox in range(0,2):
			var x:=clampi(floori(fx)+ox,0,nx-1); var y:=clampi(floori(fy)+oy,0,ny-1)
			var i:=y*nx+x
			if not is_finite(cost[i]): continue
			var d:=Vector2(float(x),float(y)).distance_to(Vector2(fx,fy))
			if d<best_d: best_d=d; best=i
	return best

## Level km of hauling from the nearest hub to p, and which hub: {effort, source}.
static func effort_at(field:Dictionary,p:Vector2)->Dictionary:
	if field.is_empty() or not p.is_finite(): return {"effort":INF,"source":-1}
	var cost:PackedFloat32Array=field.cost
	var effort:=_bilinear(field,cost,p)
	var node:=_node_near(field,p)
	var source:=int((field.src as PackedInt32Array)[node]) if node>=0 else -1
	# Close by a hub, the hub itself is the measure (its lattice seeds agree).
	var cell:=float(field.cell)
	var sources:Array=field.sources
	var f_here:=_bilinear(field,field.fac,p)
	if not is_finite(f_here): f_here=1.0
	for k in sources.size():
		var s:Dictionary=sources[k]
		var d:=(s.pos as Vector2).distance_to(p)
		if d>cell*NEAR_CELLS: continue
		var direct:=float(s.base)+d*f_here
		if direct<effort: effort=direct; source=k
	return {"effort":effort,"source":source}

## The supply line from the hub to p along the field: [hub, ..., p].
static func route_to(field:Dictionary,p:Vector2)->PackedVector2Array:
	var out:=PackedVector2Array()
	if field.is_empty() or not p.is_finite(): return out
	var node:=_node_near(field,p)
	if node<0: return out
	var nx:=int(field.nx)
	var origin:Vector2=field.origin; var cell:=float(field.cell)
	var parent:PackedInt32Array=field.parent
	var chain:=PackedVector2Array()
	var walk:=node
	var guard:=0
	while walk>=0 and guard<100000:
		chain.append(origin+Vector2(float(walk%nx),float(walk/nx))*cell)
		walk=parent[walk]; guard+=1
	var src:=int((field.src as PackedInt32Array)[node])
	var hub:Vector2=(field.sources[src] as Dictionary).pos if src>=0 and src<(field.sources as Array).size() else chain[chain.size()-1]
	out.append(hub)
	for k in range(chain.size()-1,-1,-1): out.append(chain[k])
	out.append(p)
	return out

## Share of the route's length on our roads by tier, and its length:
## {km, road: fraction on any road, tier: the road most of it keeps (-1)}.
static func route_roads(field:Dictionary,route:PackedVector2Array)->Dictionary:
	var km:=0.0
	var by:=[0.0,0.0,0.0]
	var road:PackedInt32Array=field.get("road",PackedInt32Array())
	var nx:=int(field.get("nx",1))
	for k in range(1,route.size()):
		var a:=route[k-1]; var b:=route[k]
		var d:=a.distance_to(b)
		km+=d
		var mid:=a.lerp(b,0.5)
		var fx:=roundi((mid.x-(field.origin as Vector2).x)/float(field.cell)); var fy:=roundi((mid.y-(field.origin as Vector2).y)/float(field.cell))
		if fx<0 or fy<0 or fx>=nx or fy>=int(field.ny): continue
		var tier:=road[fy*nx+fx]
		if tier>=0: by[clampi(tier,0,2)]=float(by[clampi(tier,0,2)])+d
	var on:=float(by[0])+float(by[1])+float(by[2])
	var best:=-1
	for t in 3:
		if float(by[t])>0.0 and (best<0 or float(by[t])>float(by[best])): best=t
	return {"km":km,"road":on/maxf(0.001,km),"tier":best}


# --------------------------------------------------------------------------
# Season, haul and forage
# --------------------------------------------------------------------------

## How cold a place is today (0 mild .. 1 hard winter), from its climate
## warmth t (0..1, <0 unknown) and seasonal swing (march_terrain.winter_factor).
static func cold(day:int,at:Vector2,t:float,swing:float)->float:
	if t<0.0: return 0.0
	var hemisphere:=-1.0 if at.y>0.0 else 1.0
	var celsius:=lerpf(-6.0,28.0,t)+sin(fmod(float(day),365.0)/365.0*TAU)*hemisphere*swing
	return clampf((2.0-celsius)/10.0,0.0,1.0)

## Days of hauling for this much effort by these carriers in this cold.
static func haul_days(effort:float,who:String,chill:float)->float:
	if not is_finite(effort): return INF
	var c:Dictionary=CARRIERS.get(who,CARRIERS.foot)
	return effort/float(c.pace)*(1.0+float(March.WINTER_K.get(String(c.arm),0.5))*chill)

## Share of a load that reaches the band after that many days of hauling.
static func haul_share(days:float,who:String)->float:
	if not is_finite(days): return 0.0
	var c:Dictionary=CARRIERS.get(who,CARRIERS.foot)
	return clampf(1.0-float(c.loss)*maxf(0.0,days-FREE_DAYS),0.0,1.0)

## The effort at which the carriers still deliver `share` of a load in mild weather.
static func reach_effort(who:String,share:float=REACH_HAUL)->float:
	var c:Dictionary=CARRIERS.get(who,CARRIERS.foot)
	return (FREE_DAYS+(1.0-share)/float(c.loss))*float(c.pace)

## How well a band of this size forages this country today, as a factor on
## field_rations' base shares: the land's richness, the season, the size.
static func forage_factor_from(rich:float,chill:float,troops:int)->float:
	var area:=clampf(rich/FORAGE_TYPICAL,0.3,1.5)
	var season:=1.0-0.7*chill
	var size:=clampf(pow(SIZE_REF/float(maxi(1,troops)),0.25),0.6,1.1)
	return clampf(area*season*size,0.2,1.5)

## The terms of the land at a point: {rich, t, swing, cold}.
static func land_at(field:Dictionary,p:Vector2,day:int)->Dictionary:
	var rich:=NEUTRAL_RICH; var t:=-1.0; var swing:=NEUTRAL_SWING
	var inside:=false
	if not field.is_empty() and p.is_finite():
		var g:Dictionary=field.ground
		var r:=_bilinear_any(field,g.rich,p)
		if is_finite(r):
			inside=true
			rich=r; t=_bilinear_any(field,g.t,p); swing=_bilinear_any(field,g.swing,p)
	if not inside and p.is_finite() and March.has_ground():
		var gd:=March.ground_at(p)
		if not gd.is_empty():
			rich=richness(float(gd.get("rain",0.5)),float(gd.get("wood",0.0)),float(gd.get("wet",0.0)),float(gd.get("h",0.25)))
			t=float(gd.get("t",-1.0))
			swing=float(PlanetEnvironment.seasonality_at(p))
	return {"rich":rich,"t":t,"swing":swing,"cold":cold(day,p,t,swing)}

## Bilinear over all nodes (land or not) for ground values.
static func _bilinear_any(field:Dictionary,values:PackedFloat32Array,p:Vector2)->float:
	var nx:=int(field.nx); var ny:=int(field.ny)
	var fx:=(p.x-(field.origin as Vector2).x)/float(field.cell)
	var fy:=(p.y-(field.origin as Vector2).y)/float(field.cell)
	if fx<0.0 or fy<0.0 or fx>float(nx-1) or fy>float(ny-1): return INF
	var x0:=clampi(floori(fx),0,maxi(0,nx-2)); var y0:=clampi(floori(fy),0,maxi(0,ny-2))
	var u:=clampf(fx-float(x0),0.0,1.0); var v:=clampf(fy-float(y0),0.0,1.0)
	var x1:=mini(x0+1,nx-1); var y1:=mini(y0+1,ny-1)
	var a:=lerpf(values[y0*nx+x0],values[y0*nx+x1],u)
	var b:=lerpf(values[y1*nx+x0],values[y1*nx+x1],u)
	return lerpf(a,b,v)

## Home under siege: the share of carts that get out (military_campaign).
static func siege_factor()->float:
	var mc:Variant=_mc()
	if mc==null or not mc.has_method("siege_home_food_access"): return 1.0
	return clampf(float(mc.siege_home_food_access()),0.0,1.0)


# --------------------------------------------------------------------------
# The day's terms at a point (one function for the rations, the screens and
# the map's grid)
# --------------------------------------------------------------------------

## The model at a point for a band of `troops`: transport (carriers' share
## at all), stores (share the stores could send), siege (share of carts that
## get out of a besieged home) are the day's inputs, read once by the caller.
static func terms(field:Dictionary,p:Vector2,day:int,troops:int,moving:bool,transport:float,stores:float,siege:float)->Dictionary:
	var who:=String(field.get("carrier",carrier())) if not field.is_empty() else carrier()
	var e:=effort_at(field,p)
	var land:=land_at(field,p,day)
	var chill:=float(land.cold)
	var days:=haul_days(float(e.effort),who,chill)
	var haul:=haul_share(days,who)
	var source:=int(e.source)
	var hub:Dictionary=(field.sources[source] as Dictionary) if source>=0 and source<(field.get("sources",[]) as Array).size() else {}
	if not hub.is_empty() and String(hub.kind) in ["home","held"]: haul*=siege
	var carried:=clampf(transport*haul*stores,0.0,1.0)
	var base:=FieldRations.FORAGE_MOVING if moving else FieldRations.FORAGE_STATIONED
	var share:=minf(FORAGE_SHARE_MAX,base*forage_factor_from(float(land.rich),chill,troops))
	var foraged:=(1.0-carried)*share
	return {"ratio":clampf(carried+foraged,0.0,1.0),"carried":carried,"foraged":foraged,"local":0.0,"air":0.0,"haul":haul,"transport":transport,"stores":stores,
		"effort":float(e.effort),"days":days,"cold":chill,"rich":float(land.rich),"forage_share":share,"hub":hub,"carrier":who}

## A node's place on the land.
static func node_pos(field:Dictionary,i:int)->Vector2:
	var nx:=int(field.nx)
	return (field.origin as Vector2)+Vector2(float(i%nx),float(i/nx))*float(field.cell)

## Which nodes of the field lie on land our people know (the map tints only
## those). Main thread: CivilizationSystem's revealed chart.
static func known_mask(field:Dictionary)->PackedByteArray:
	var out:=PackedByteArray()
	if field.is_empty(): return out
	var n:=int(field.nx)*int(field.ny)
	out.resize(n)
	var world:Variant=_world()
	var land:PackedByteArray=(field.ground as Dictionary).land
	for i in n:
		if land[i]==0: continue
		out[i]=1 if world!=null and bool(world._position_is_revealed(node_pos(field,i))) else 0
	return out

## The map's grid: the model at every node for a band of `troops`, standing,
## with the day's inputs (day_inputs()). {ratio, carried, haul} per node,
## ratio -1 where the land is unknown (known[i]==0) or water. Exactly
## terms() at each node, so the chart and at_point() agree. Pure given its
## inputs: a worker thread may run it.
static func grid(field:Dictionary,troops:int,inputs:Dictionary,known:PackedByteArray)->Dictionary:
	var n:=int(field.nx)*int(field.ny)
	var ratio:=PackedFloat32Array(); ratio.resize(n); ratio.fill(-1.0)
	var carried:=PackedFloat32Array(); carried.resize(n)
	var haul:=PackedFloat32Array(); haul.resize(n)
	var land:PackedByteArray=(field.ground as Dictionary).land
	var day:=int(inputs.get("day",0))
	for i in n:
		if land[i]==0 or i>=known.size() or known[i]==0: continue
		var t:=terms(field,node_pos(field,i),day,troops,false,float(inputs.transport),float(inputs.stores),float(inputs.siege))
		ratio[i]=float(t.ratio); carried[i]=float(t.carried); haul[i]=float(t.haul)
	return {"ratio":ratio,"carried":carried,"haul":haul,"troops":troops,"day":day,"key":int(field.get("key",0))}

## The carriers' share of need at all today, and the stores' (day inputs).
static func day_inputs()->Dictionary:
	var mc:Variant=_mc()
	var transport:=1.0
	if mc!=null and mc.has_method("_field_transport_delivery_ratio"): transport=clampf(float(mc._field_transport_delivery_ratio()),0.0,1.0)
	var s:Variant=_state()
	var stores:=1.0
	if s!=null: stores=clampf(float((s.simulation_metrics as Dictionary).get("food_intake_ratio",1.0)),0.0,1.0)
	return {"transport":transport,"stores":stores,"siege":siege_factor(),"day":today()}


# --------------------------------------------------------------------------
# The engine's two questions
# --------------------------------------------------------------------------

## Share of the carriers' food that reaches this force today (1 when it has
## no place, no home or no field): the haul along its supply line, and a
## besieged home's gate. military_campaign._force_provision_access.
static func haul_for(force:Dictionary)->float:
	var p:=force_pos(force)
	if not p.is_finite(): return 1.0
	var f:=field(true)
	if f.is_empty(): return 1.0
	var e:=effort_at(f,p)
	if not is_finite(float(e.effort)): return 0.0
	var land:=land_at(f,p,today())
	var haul:=haul_share(haul_days(float(e.effort),String(f.carrier),float(land.cold)),String(f.carrier))
	var source:=int(e.source)
	if source>=0 and source<(f.sources as Array).size() and String((f.sources[source] as Dictionary).kind) in ["home","held"]: haul*=siege_factor()
	return haul

## How well this force forages where it stands today, as a factor on
## field_rations' base shares (1 when it has no place or no field).
static func forage_factor(force:Dictionary)->float:
	var p:=force_pos(force)
	if not p.is_finite(): return 1.0
	var f:=field(true)
	var land:=land_at(f,p,today())
	return forage_factor_from(float(land.rich),float(land.cold),int(force.get("troops",0)))


# --------------------------------------------------------------------------
# Reports for the screens
# --------------------------------------------------------------------------

## What a band of `troops` (-1: our largest band out, else 30) would get at
## this point today, standing (or moving).
static func at_point(point:Vector2,troops:int=-1,moving:=false)->Dictionary:
	if troops<0: troops=typical_troops()
	var f:=field(true)
	var d:=day_inputs()
	var t:=terms(f,point,int(d.day),troops,moving,float(d.transport),float(d.stores),float(d.siege))
	var report:=_report_from_terms(f,t,point)
	report["force_kind"]="point"; report["troops"]=troops
	report["words"]=words(report)
	return report

## The size the map's wash is drawn for: our largest band out, else the
## home levy, else 30.
static func typical_troops()->int:
	var mc:Variant=_mc()
	var best:=0
	if mc!=null:
		for a in mc.field_armies:
			if a is Dictionary: best=maxi(best,int((a as Dictionary).get("troops",0)))
		if best<=0: best=int((mc.home_army as Dictionary).get("troops",0))
	return best if best>0 else 30

static func _report_from_terms(f:Dictionary,t:Dictionary,p:Vector2)->Dictionary:
	var hub:Dictionary=t.hub
	var route:=route_to(f,p) if not hub.is_empty() else PackedVector2Array()
	var roads:=route_roads(f,route) if route.size()>=2 else {"km":0.0,"road":0.0,"tier":-1}
	var ratio:=float(t.ratio)
	var report:={"ratio":ratio,"state":state_of(ratio),"carried":float(t.carried),"foraged":float(t.foraged),"local":float(t.local),"air":0.0,
		"haul":float(t.haul),"transport":float(t.transport),"stores":float(t.stores),"days":float(t.days),"effort":float(t.effort),
		"km":float(roads.km),"road":ROAD_WORDS[int(roads.tier)] if int(roads.tier)>=0 and float(roads.road)>=0.5 else "","road_share":float(roads.road),
		"hub":String(hub.get("name","")),"hub_kind":String(hub.get("kind","")),"hub_position":hub.get("pos",Vector2.INF),
		"season":"winter" if float(t.cold)>=0.3 else "","cold":float(t.cold),"rich":float(t.rich),"carrier":String(t.carrier),
		"route":route,"position":p,"siege":"","blockade":"","hungry_days":0.0,"hungry":false,"supply_level":ratio}
	report["why"]=why(report)
	return report

## A force as it stands today: the engine's own numbers for the day
## (military_campaign.record_daily_provisions) with the line it draws on.
static func of_force(force:Dictionary)->Dictionary:
	if force.is_empty(): return {}
	var mc:Variant=_mc()
	var day:=today()
	if day!=_report_day: _report_cache.clear(); _report_day=day
	var kind:="garrison" if force.has("region_id") and not force.has("army_id") else ("home" if mc!=null and force==mc.home_army else "field")
	var p:=force_pos(force)
	var cache_key:=hash([kind,int(force.get("army_id",0)),String(force.get("region_id","")),int(force.get("provision_day",-1)),float(force.get("provision_ratio",-1.0)),p.snapped(Vector2.ONE*0.05) if p.is_finite() else Vector2.ZERO,int(force.get("troops",0)),int(_field.get("key",0))])
	if _report_cache.has(cache_key): return _report_cache[cache_key]
	var report:Dictionary
	var at_home:bool=kind=="home" or (mc!=null and kind=="field" and bool(mc._army_is_home(force)))
	if at_home:
		var ratio:=clampf(float(force.get("provision_ratio",1.0)),0.0,1.0)
		var s:Variant=_state()
		report={"ratio":ratio,"state":state_of(ratio),"carried":ratio,"foraged":0.0,"local":0.0,"air":0.0,"haul":1.0,"transport":1.0,"stores":ratio,
			"days":0.0,"effort":0.0,"km":0.0,"road":"","road_share":0.0,"hub":String(s.settlement_name) if s!=null else "home","hub_kind":"home","hub_position":p,
			"season":"","cold":0.0,"rich":NEUTRAL_RICH,"carrier":carrier(),"route":PackedVector2Array(),"position":p,"at_home":true}
	else:
		var f:=field(true)
		var d:=day_inputs()
		var moving:=String(force.get("status","stationed"))=="moving"
		var t:=terms(f,p,int(d.day),int(force.get("troops",0)),moving,float(d.transport),float(d.stores),float(d.siege))
		report=_report_from_terms(f,t,p)
		# The day's actual rations, as the engine recorded them.
		var need:=float(force.get("provisions_required_today",0.0))
		if int(force.get("provision_day",-99))>=day-1 and need>0.0:
			var ratio:=clampf(float(force.get("provision_ratio",0.0)),0.0,1.0)
			report.ratio=ratio; report.state=state_of(ratio)
			report.carried=clampf(float(force.get("provisions_delivered_today",0.0))/need,0.0,1.0)
			report.foraged=clampf(float(force.get("provisions_foraged_today",0.0))/need,0.0,1.0)
			report.local=clampf(float(force.get("provisions_local_today",0.0))/need,0.0,1.0)
			report["recorded"]=true
		elif kind=="garrison":
			# Not yet recorded today: the town's own share first, then the carts.
			var region:Dictionary=_world().region_snapshot(String(force.get("civ_id","")),String(force.get("region_id",""))) if _world()!=null else {}
			var local:=FieldRations.occupation_local_share(region)
			var carried:=(1.0-local)*float(report.carried)
			report.local=local; report.carried=carried; report.foraged=0.0
			report.ratio=clampf(local+carried,0.0,1.0); report.state=state_of(float(report.ratio))
	report["force_kind"]=kind
	report["army_id"]=int(force.get("army_id",0))
	report["region_id"]=String(force.get("region_id",""))
	report["name"]=String(force.get("name",force.get("region_name","")))
	report["troops"]=int(force.get("troops",0))
	report["supply_level"]=clampf(float(force.get("supply_level",report.ratio)),0.0,1.0)
	report["hungry_days"]=float(force.get("hungry_days",0.0))
	report["hungry"]=FieldRations.is_hungry(force)
	_siege_and_blockade(report,force)
	report["why"]=why(report)
	report["words"]=words(report)
	_report_cache[cache_key]=report
	return report

## A field army by id ({} if we have none by that id).
static func of_army_id(army_id:int)->Dictionary:
	var mc:Variant=_mc()
	if mc==null: return {}
	for a in mc.field_armies:
		if a is Dictionary and int((a as Dictionary).get("army_id",0))==army_id: return of_force(a)
	return {}

## Every band out, every garrison, and the home levy (when it has fighters).
static func forces()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var mc:Variant=_mc()
	if mc==null: return out
	for a in mc.field_armies:
		if a is Dictionary and int((a as Dictionary).get("troops",0))>0: out.append(of_force(a))
	for g in mc.occupation_forces:
		if g is Dictionary and int((g as Dictionary).get("troops",0))>0: out.append(of_force(g))
	if int((mc.home_army as Dictionary).get("troops",0))>0: out.append(of_force(mc.home_army))
	return out

static func _siege_and_blockade(report:Dictionary,force:Dictionary)->void:
	var mc:Variant=_mc()
	if mc==null: return
	var siege:Dictionary=mc.active_siege
	if not siege.is_empty():
		if String(siege.get("mode",""))=="offensive" and int(siege.get("army_id",siege.get("home_force_id",-1)))==int(force.get("army_id",-2)):
			report.siege="besieging %s: the siege holds while they are fed" % String(siege.get("target_name",siege.get("city_name","the town")))
		elif String(siege.get("mode",""))=="defensive" and String(report.get("hub_kind",""))=="home" and siege_factor()<1.0:
			report.siege="home is besieged: %d%% of the carts get out" % roundi(siege_factor()*100.0)
	var ops:Variant=mc.get("joint_operations")
	if ops!=null and not ((ops.state as Dictionary).get("blockades",{}) as Dictionary).is_empty():
		var closure:=float(ops.blockade_closure("player"))
		if closure>0.0: report.blockade="our ports are blockaded (%d%% closed)" % roundi(closure*100.0)


# --------------------------------------------------------------------------
# Words
# --------------------------------------------------------------------------

## Whole percentages that add up to the whole (largest remainder).
static func percents(total:float,parts:Array)->Array:
	var whole:=roundi(clampf(total,0.0,1.0)*100.0)
	var floors:Array=[]; var rema:Array=[]; var sum:=0
	var scale:=float(whole)/maxf(0.0001,total*100.0) if total>0.0 else 0.0
	for p in parts:
		var v:=maxf(0.0,float(p))*100.0*scale
		floors.append(floori(v)); rema.append(v-floorf(v)); sum+=floori(v)
	var order:=range(parts.size())
	order.sort_custom(func(a:int,b:int)->bool: return float(rema[a])>float(rema[b]))
	var k:=0
	while sum<whole and k<order.size():
		floors[order[k]]=int(floors[order[k]])+1; sum+=1; k+=1
	return floors

## "4 days", "a day", "half a day", "under half a day".
static func days_words(days:float)->String:
	if not is_finite(days): return "beyond the carriers' reach"
	if days<0.35: return "a short haul"
	if days<0.75: return "half a day"
	if days<1.5: return "a day"
	return "%d days" % roundi(days)

## "4 days from Seanstone by cart track".
static func line_words(report:Dictionary)->String:
	var hub:=String(report.get("hub",""))
	if hub=="" or not is_finite(float(report.get("days",INF))): return "no road back to our stores"
	var way:=""
	var road:=String(report.get("road",""))
	if road!="": way=" by "+road
	elif float(report.get("road_share",0.0))>=0.15: way=" partly by road"
	else: way=" across open country"
	var d:=days_words(float(report.days))
	var from:="from" if String(report.get("hub_kind",""))!="held" else "from our depot at"
	return "%s %s %s%s" % [d,from,hub,way]

## One plain line: "Gets 60% of its food: 35% foraged, 25% carried; 4 days
## from Seanstone by cart track."
static func words(report:Dictionary)->String:
	if report.is_empty(): return ""
	var ratio:=float(report.get("ratio",0.0))
	if bool(report.get("at_home",false)):
		return "At home: fed from the stores (%d%%)." % roundi(ratio*100.0)
	var parts:Array=[]; var names:Array=[]
	var town:=String(report.get("name","the town")) if String(report.get("force_kind",""))=="garrison" else "the town"
	for row in [["local",float(report.get("local",0.0)),"from %s" % town],["foraged",float(report.get("foraged",0.0)),"foraged"],["carried",float(report.get("carried",0.0)),"carried"]]:
		if float(row[1])>0.004: parts.append(float(row[1])); names.append(String(row[2]))
	var pcts:=percents(ratio,parts)
	var shares:PackedStringArray=PackedStringArray()
	for k in parts.size():
		if int(pcts[k])>0: shares.append("%d%% %s" % [int(pcts[k]),String(names[k])])
	var head:="Gets %d%% of its food" % roundi(ratio*100.0)
	if String(report.get("force_kind",""))=="point": head="A band of %d here would get %d%% of its food" % [int(report.get("troops",0)),roundi(ratio*100.0)]
	var text:=head+(": "+", ".join(shares) if not shares.is_empty() else "")
	text+="; "+line_words(report)+"."
	var hungry:=float(report.get("hungry_days",0.0))
	if bool(report.get("hungry",false)) and hungry>=1.0: text+=" Hungry %d days." % roundi(hungry)
	return text

## The short reasons behind the numbers, plainest first.
static func why(report:Dictionary)->PackedStringArray:
	var out:=PackedStringArray()
	if bool(report.get("at_home",false)):
		out.append("at home, fed from the stores"); return out
	out.append(line_words(report))
	var who:=String((CARRIERS.get(String(report.get("carrier","foot")),CARRIERS.foot) as Dictionary).words)
	var haul:=float(report.get("haul",1.0))
	if haul<0.97: out.append("the %s eat %d%% of each load on the way" % [who,roundi((1.0-haul)*100.0)])
	var transport:=float(report.get("transport",1.0))
	if transport<0.97: out.append("we have carriers for %d%% of what the fighters need" % roundi(transport*100.0))
	if float(report.get("stores",1.0))<0.97: out.append("the stores are short")
	if String(report.get("season",""))=="winter": out.append("winter: the carts are slow and there is little to forage")
	var rich:=float(report.get("rich",NEUTRAL_RICH))
	if rich<FORAGE_TYPICAL*0.7: out.append("poor country to forage")
	elif rich>FORAGE_TYPICAL*1.25: out.append("rich country to forage")
	if String(report.get("siege",""))!="": out.append(String(report.siege))
	if String(report.get("blockade",""))!="": out.append(String(report.blockade))
	return out
