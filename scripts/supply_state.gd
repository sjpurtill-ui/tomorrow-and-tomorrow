extends RefCounted
## ONE SUPPLY MODEL: how well each band, garrison and the home levy is fed
## today and why, and what a band would get at any point of the land.
## HOI4's supply in our own terms: hubs, the carriers' line and the country.
##
## A soldier's day of food away from home comes three ways (field_rations.gd,
## military_campaign.record_daily_provisions, which this model feeds):
##   carried  brought from our stores. What reaches a band is the carriers'
##            share of all the bread asked (carriers.gd: porters, carts and
##            lorries driven by the Logistics workers, each at its own pace,
##            bread first and stores after, military_campaign
##            ._field_transport_delivery_ratio) times the
##            HAUL: the share of a load the carriers do not eat on the road.
##            The haul falls with the days of hauling from the nearest hub
##            along the supply line, weighed as march_terrain.gd weighs ground
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
## The supply field: one multi-source search (Dijkstra) over a square
## lattice round home (its side doubling as our hubs and known land spread).
## In play it is built only on a worker thread, from the terrain's
## thread-safe fused sampler (terrain_patch_sampler.gd) and snapshots, never
## from the scene. The day's rations read one field for the whole day: the
## one built from the world as they found it at their first ask the day
## before (waiting a moment at most if that build is still under way; a
## slower build is taken the next day), so a saved game replays the same;
## a change reaches the rations a day or two later, as word reaches the
## quartermasters. A point off the lattice is reckoned by
## the straight line to the nearest hub (FALLBACK_FACTOR). Tests and tools
## with fixture ground build it on the spot (field(true)). The map's grid
## (hud/supply_map.gd) is terms() at the field's nodes and reads the same
## field as the rations, so the chart and the rations agree.
##
## Engine: military_campaign._force_provision_access asks haul_for(force);
## field_rations.forage_share asks forage_factor(force).
## Screens: of_force(), of_army_id(), at_point(), forces(), words().
## Static helpers; preload.

const FieldRations:=preload("res://scripts/field_rations.gd")
const Mechanics:=preload("res://scripts/research_mechanics.gd")
const March:=preload("res://scripts/march_terrain.gd")
const Sampler:=preload("res://scripts/terrain_patch_sampler.gd")
const TownNames:=preload("res://scripts/town_names.gd")

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
## Level km per km of straight line where no field covers a point (a road
## seldom runs straight; open country with some hills and woods).
const FALLBACK_FACTOR:=1.25
## Foraging: the typical richness of the land, the band size that forages
## at field_rations' stated rate, and the cap on the share.
const FORAGE_TYPICAL:=0.42
const SIZE_REF:=60.0
const FORAGE_SHARE_MAX:=0.6
## Ground weight when nothing is surveyed (tests, headless): open land.
const NEUTRAL_RICH:=FORAGE_TYPICAL
const NEUTRAL_SWING:=12.0

## The lattice: a square of CELLS x CELLS cells round home, its side a
## doubling of MIN_SIDE_KM wide enough for our hubs and the known land
## (padded), so it changes only when they outgrow it.
const CELLS:=64
const MIN_SIDE_KM:=128.0
const MAX_SIDE_KM:=8192.0
const CENTER_SNAP_KM:=64.0
const PAD_KM:=40.0
## The lattice never reaches farther than this beyond our hubs.
const MAX_MARGIN_KM:=1500.0
## Within this distance of a depot (a town we hold) a force stands in it.
const AT_DEPOT_KM:=3.0
## The longest the day's rations wait for a build of yesterday's world
## (ms); a build slower than that is taken the next day.
const WAIT_BUDGET_MS:=12.0
## Nodes within this many cells of a hub read their cost from the hub itself.
const NEAR_CELLS:=1.5
## terrain_patch_sampler lifts its heights by this much.
const SAMPLER_LIFT:=0.0006

const ROAD_WORDS:=["footpath","cart track","made road"]
## Neighbour steps (x, y), axial first.
const DX:=[1,-1,0,0,1,-1,1,-1]
const DY:=[0,0,1,-1,1,1,-1,-1]

static var _field:Dictionary={}
## Finished fields by key (the last few), not necessarily in hand.
static var _built:Dictionary={}
## The day the rations last took a field, and the world's key as they found
## it at that day's first ask (built for the next day).
static var _rations_day:=-1
static var _rations_key:=0
static var _job:BuildJob=null
static var _ground_cache:Dictionary={}
static var _known_cache:Array=[-1,-1,Rect2()]
static var _spec:Dictionary={}
static var _spec_sig:=0
static var _sampler:RefCounted=null
static var _sampler_key:=0
static var _tribs:Array=[]
static var _tribs_key:=0
static var _report_cache:Dictionary={}
static var _report_day:=-1
## Counters for tests and probes (never saved).
static var builds:=0
static var async_builds:=0
static var spec_builds:=0
## Main-thread time the rations spent waiting for a build (ms).
static var waited_ms:=0.0


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
# What the world gives the model (main thread)
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
	# The kind of carrier moving most of our loads sets the line's pace
	# (carriers.gd): one lorry among a thousand porters does not.
	var carriers:=load("res://scripts/carriers.gd")
	var adoption:=func(id:String)->float: return float(WorldSimulation.discovery.adoption(id)) if WorldSimulation.discovery!=null and id in s.known_discoveries else 0.0
	var fleet:Dictionary=carriers.fleet(s,adoption)
	var best:=String(carriers.main_kind(fleet))
	# A new kind takes over the line only once it clearly moves more (a fifth
	# more than the kind that had it): one cart or one worker does not flip
	# every band's haul back and forth.
	var owner:=(s as Object).get_instance_id()
	var held:=String(_main_kind.get(owner,best))
	var trips:Dictionary=fleet.get("trip",{})
	if held!=best and float(trips.get(best,0.0))<1.2*float(trips.get(held,0.0)): best=held
	_main_kind[owner]=best
	return String(carriers.ARM[best])

static var _main_kind:Dictionary={}

## Our hubs: home and our other settlements, then the towns we hold.
## Field depots our bands laid (field_depots.gd) join the held towns as relays.
## [{id, name, kind: home|town|held|depot, pos:Vector2, civ_id?, region_id?}]
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
			out.append({"id":"h:"+rid,"name":town_name(civ_id,rid,String(force.get("region_name","the held town"))),"kind":"held","pos":at,"civ_id":civ_id,"region_id":rid})
	var laid:Variant=mc.get("field_depots") if mc!=null else null
	if laid is Array:
		for d in laid:
			var depot:Dictionary=d
			out.append({"id":"d:%d" % int(depot.get("id",0)),"name":String(depot.get("name","Depot")),"kind":"depot","pos":Vector2(float(depot.x),float(depot.z))})
	return out

## A hub whose line starts from what reaching it cost (a held town or a
## field depot), as against our own stores.
static func is_relay(kind:String)->bool:
	return kind=="held" or kind=="depot"

## A town's name as the map shows it (town_names.gd: one name everywhere).
static func town_name(civ_id:String,region_id:String,fallback:String="")->String:
	return TownNames.of(civ_id,region_id,fallback)

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

## The terrain's fused sampler (its own copies of the noise: safe on any
## thread, whatever becomes of the terrain), kept per terrain and world.
static func _terrain_sampler(terrain:Object)->RefCounted:
	if terrain==null or terrain.get("continent_noise")==null or terrain.get("mountain_relief")==null: return null
	var key:=hash([terrain.get_instance_id(),int(GameState.world_seed)])
	if _sampler==null or key!=_sampler_key:
		_sampler=Sampler.from_terrain(terrain)
		_sampler_key=key
	return _sampler

## The tributaries' courses, copied once per terrain and world.
static func _tributaries(terrain:Object)->Array:
	var key:=hash([terrain.get_instance_id() if terrain!=null else 0,int(GameState.world_seed)])
	if key==_tribs_key: return _tribs
	_tribs=[]
	var courses:Variant=terrain.get("world_tributary_courses") if terrain!=null else null
	if courses is Array:
		for course in courses: _tribs.append(PackedVector3Array(course))
	_tribs_key=key
	return _tribs


# --------------------------------------------------------------------------
# The field's specification (main thread)
# --------------------------------------------------------------------------

## What a field would be built from, cheaply fingerprinted: the day and the
## counters that move when a hub, the known land, the carriers or the
## fixtures change. spec() is rebuilt only when this moves.
static func _signature()->int:
	var s:Variant=_state(); var world:Variant=_world(); var mc:Variant=_mc()
	if s==null or world==null: return 0
	var garrisons:=0
	if mc!=null:
		for f in mc.occupation_forces:
			if f is Dictionary and int((f as Dictionary).get("troops",0))>0: garrisons+=1
	var terrain:Object=March._terrain()
	return hash([int(s.elapsed_days),int(GameState.world_seed),bool(s.settlement_site_committed),(s.player_settlements as Array).size(),garrisons,
		mc.occupation_forces.size() if mc!=null else 0,hash(mc.get("field_depots")) if mc!=null else 0,int(world.fog_revision),(world.revealed_areas as Array).size(),
		float((s.resource_stockpiles as Dictionary).get("Transport Carts",0.0))>=1.0,"internal_combustion" in s.known_discoveries,
		hash(March.ground_override),hash(March.crossing_override),March.use_roads_override,March.roads_override.size(),hash(March.roads_override),
		March.bridge_override,terrain.get_instance_id() if terrain!=null else 0])

## Everything a field is built from, with its key; {} when there is no home
## or no ground to weigh (then every point is reckoned by the straight line).
static func spec()->Dictionary:
	var sig:=_signature()
	if sig!=0 and sig==_spec_sig: return _spec
	_spec_sig=sig
	_spec=_make_spec()
	spec_builds+=1
	return _spec

## Which world a field belongs to: the seed and the terrain (or fixture).
static func _world_id(terrain:Object,fixture:bool)->int:
	return hash([int(GameState.world_seed),terrain.get_instance_id() if terrain!=null else 0,fixture,hash(March.ground_override) if fixture else 0])

static func _make_spec()->Dictionary:
	var hub_list:=hubs()
	if hub_list.is_empty(): return {}
	var settlements:Array=[]
	var held:Array=[]
	for h:Dictionary in hub_list: (held if is_relay(String(h.kind)) else settlements).append(h)
	if settlements.is_empty(): return {}
	var terrain:Object=March._terrain()
	var fixture:=March.ground_override.is_valid()
	var sampler:=_terrain_sampler(terrain) if not fixture else null
	if sampler==null and not fixture: return {"hubs":hub_list,"no_ground":true}
	# A square round home, its side doubling as our hubs and known land spread
	# (128, 256, 512 ... km over CELLS cells): it changes a few times a game.
	var home:Vector2=settlements[0].pos
	for h:Dictionary in settlements:
		if String(h.kind)=="home": home=h.pos; break
	var center:=home.snapped(Vector2.ONE*CENTER_SNAP_KM)
	var hub_box:=Rect2(home,Vector2.ZERO)
	for h:Dictionary in hub_list: hub_box=hub_box.expand(h.pos)
	var box:=hub_box
	var known:=_known_box()
	if known.has_area(): box=box.merge(known.intersection(hub_box.grow(MAX_MARGIN_KM)))
	var need:=maxf(maxf(absf(box.position.x-center.x),absf(box.end.x-center.x)),maxf(absf(box.position.y-center.y),absf(box.end.y-center.y)))+PAD_KM
	var side:=MIN_SIDE_KM
	while side*0.5<need and side<MAX_SIDE_KM: side*=2.0
	var cell:=side/float(CELLS)
	var origin:=center-Vector2.ONE*side*0.5
	var n:=CELLS+1
	var who:=carrier()
	var roads:=March.roads()
	var geo_key:=hash([int(GameState.world_seed),origin,cell,n,fixture,hash(March.ground_override),terrain.get_instance_id() if terrain!=null else 0])
	var hub_rows:Array=[]
	for h:Dictionary in hub_list: hub_rows.append([String(h.id),String(h.kind),(h.pos as Vector2).snapped(Vector2.ONE*0.01)])
	var key:=hash([geo_key,who,hash(roads.map(func(r:Dictionary)->Array: return [r.a,r.b,r.tier])),March.bridge_tier(),hub_rows,hash(March.crossing_override)])
	return {"key":key,"geo_key":geo_key,"world":_world_id(terrain,fixture),"origin":origin,"cell":cell,"nx":n,"ny":n,"carrier":who,"mix":{String(CARRIERS[who].arm):1.0},
		"roads":roads.duplicate(true),"bridge":March.bridge_tier(),"settlements":settlements,"held":held,"hubs":hub_list,
		"sampler":sampler,"fixture":fixture,"crossing_fixture":March.crossing_override.is_valid(),
		"tribs":_tributaries(terrain) if sampler!=null else [],"seed":int(GameState.world_seed),
		"async":sampler!=null and not March.crossing_override.is_valid()}


# --------------------------------------------------------------------------
# Building the field (pure: any thread, from the spec alone)
# --------------------------------------------------------------------------

## A build on a worker thread, adopted on the main thread. `cancelled` asks
## it to stop at the next row.
class BuildJob:
	var spec:Dictionary
	var ground:Dictionary
	var model:GDScript
	var cancel:=[false]
	var result:Dictionary={}
	var task:=-1
	var ms:=0.0
	func _init(p_spec:Dictionary,p_ground:Dictionary,p_model:GDScript)->void:
		spec=p_spec; ground=p_ground; model=p_model
	func run()->void:
		var began:=Time.get_ticks_usec()
		result=model.call("build",spec,ground,cancel)
		ms=float(Time.get_ticks_usec()-began)/1000.0

## A square patch for the fused sampler: the lattice itself, nothing reused.
class PatchJob:
	var resolution:int
	var center:Vector2
	var span:float
	var reuse_resolution:=0
	var reuse_stride:=1
	var reuse_offset:=Vector2i.ZERO
	var reuse_center:=Vector2.ZERO
	var reuse_span:=1.0
	var reuse_vertices:=PackedVector3Array()
	var reuse_colors:=PackedColorArray()
	var reuse_climate:=PackedVector2Array()
	var reuse_geology:=PackedVector2Array()
	var reuse_seasons:=PackedFloat32Array()

## The great river's line at z (local_terrain._world_river_x), INF beyond it.
static func river_x(z:float,world_seed:int)->float:
	if absf(z)>760.0: return INF
	return -18.0+sin(z/128.0+float(world_seed%97)*0.031)*32.0+sin(z/57.0-0.8)*14.0+sin(z/21.0+1.7)*4.5

## The ground of every node: {h, slope, wood, wet, t, rain, rich, swing,
## land}. The terrain's sampler in play; fixture ground in tests (main
## thread). {} when cancelled.
static func sample_ground(spec:Dictionary,cancel:Array=[false])->Dictionary:
	var nx:=int(spec.nx); var ny:=int(spec.ny); var n:=nx*ny
	var origin:Vector2=spec.origin; var cell:=float(spec.cell)
	# Packed arrays are values: fill these, then hand them over at the end.
	var h:=PackedFloat32Array(); var slope:=PackedFloat32Array(); var wood:=PackedFloat32Array(); var wet:=PackedFloat32Array()
	var t:=PackedFloat32Array(); var rain:=PackedFloat32Array(); var rich:=PackedFloat32Array(); var swing:=PackedFloat32Array()
	h.resize(n); slope.resize(n); wood.resize(n); wet.resize(n); t.resize(n); rain.resize(n); rich.resize(n); swing.resize(n)
	var land:=PackedByteArray(); land.resize(n)
	var sampler:RefCounted=spec.get("sampler")
	if sampler!=null:
		var job:=PatchJob.new()
		job.resolution=nx
		job.center=origin+Vector2.ONE*float(nx-1)*0.5*cell
		job.span=float(nx-1)*cell
		var world_seed:=int(spec.seed)
		for y in ny:
			if bool(cancel[0]): return {}
			var rows:Array=sampler.sample_rows(job,y,1)
			var heights:PackedFloat32Array=rows[0]; var colors:PackedColorArray=rows[2]; var climate:PackedVector2Array=rows[3]; var seasons:PackedFloat32Array=rows[5]
			var z:=origin.y+float(y)*cell
			var rx:=river_x(z,world_seed)
			for x in nx:
				var i:=y*nx+x
				var raw:=heights[x]-SAMPLER_LIFT
				h[i]=raw
				land[i]=1 if raw>0.015 else 0
				wood[i]=colors[x].a if land[i]==1 else 0.0
				rain[i]=clampf(climate[x].x-1.0,0.0,1.0); t[i]=climate[x].y; swing[i]=seasons[x]
				# local_terrain._biome_from_climate's wet classes, as march_terrain reads them.
				var rd:=absf(origin.x+float(x)*cell-rx) if is_finite(rx) else INF
				if t[i]>=0.16 and raw<=6.0:
					if rd<3.2 and raw<3.0: wet[i]=0.45
					elif rain[i]>0.70 and raw<0.9 and rd<18.0: wet[i]=1.0
				rich[i]=richness(rain[i],wood[i],wet[i],raw)
		# Slope across the lattice (the ground a cell's carriers climb).
		for y in ny:
			for x in nx:
				var i:=y*nx+x
				var gx:=(h[y*nx+mini(x+1,nx-1)]-h[y*nx+maxi(x-1,0)])/(cell*float(mini(x+1,nx-1)-maxi(x-1,0)))
				var gz:=(h[mini(y+1,ny-1)*nx+x]-h[maxi(y-1,0)*nx+x])/(cell*float(mini(y+1,ny-1)-maxi(y-1,0)))
				slope[i]=Vector2(gx,gz).length()
	else:
		for i in n:
			var p:=origin+Vector2(float(i%nx),float(i/nx))*cell
			var g:Dictionary=March.ground_at(p)
			h[i]=float(g.get("h",0.25)); slope[i]=float(g.get("slope",0.0)); wood[i]=float(g.get("wood",0.0)); wet[i]=float(g.get("wet",0.0))
			t[i]=float(g.get("t",-1.0)); rain[i]=float(g.get("rain",0.5))
			land[i]=1 if h[i]>0.015 else 0
			rich[i]=richness(rain[i],wood[i],wet[i],h[i])
			swing[i]=NEUTRAL_SWING
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

## River crossing on the step a->b (march_terrain.crossing, from the spec's
## own copies): "" | "ford" | "deep".
static func _crossing(a:Vector2,b:Vector2,world_seed:int,segments:Array)->String:
	var ra:=river_x(a.y,world_seed); var rb:=river_x(b.y,world_seed)
	if is_finite(ra) and is_finite(rb) and signf(a.x-ra)!=signf(b.x-rb) and absf(a.x-ra)+absf(b.x-rb)>0.0:
		var t:=absf(a.x-ra)/maxf(0.0001,absf(a.x-ra)+absf(b.x-rb))
		var z:=lerpf(a.y,b.y,t)
		return "ford" if fposmod(z+float(posmod(world_seed,997)),37.0)<4.0 else "deep"
	for seg:Array in segments:
		if Geometry2D.segment_intersects_segment(a,b,seg[0],seg[1])!=null: return "ford"
	return ""

## The whole field for a spec: costs (level km of hauling from the nearest
## hub), the hub each node draws on, and the line back to it. {} when
## cancelled. Touches nothing but the spec and its own arrays.
static func build(spec:Dictionary,ground:Dictionary={},cancel:Array=[false])->Dictionary:
	var began:=Time.get_ticks_usec()
	var nx:=int(spec.nx); var ny:=int(spec.ny); var n:=nx*ny
	var origin:Vector2=spec.origin; var cell:=float(spec.cell)
	var mix:Dictionary=spec.mix
	var sampled_ms:=0.0
	if ground.is_empty() or int(ground.get("geo_key",0))!=int(spec.geo_key):
		ground=sample_ground(spec,cancel)
		if ground.is_empty(): return {}
		ground["geo_key"]=int(spec.geo_key)
		sampled_ms=float(Time.get_ticks_usec()-began)/1000.0
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
	for i in n:
		fac[i]=March.factor({"slope":slope[i],"wood":wood[i],"wet":wet[i]},mix,road[i]) if land[i]==1 else INF
	if bool(cancel[0]): return {}
	# River crossings: the great river where a step changes its side; a
	# tributary where a step crosses one of its segments near the step.
	var world_seed:=int(spec.get("seed",0))
	var fixture_crossings:=bool(spec.get("crossing_fixture",false))
	var side:=PackedInt32Array(); side.resize(n)
	var buckets:={}
	if not fixture_crossings and spec.get("sampler")!=null:
		for y in ny:
			var rx:=river_x(origin.y+float(y)*cell,world_seed)
			if not is_finite(rx): continue
			for x in nx: side[y*nx+x]=1 if origin.x+float(x)*cell-rx>0.0 else -1
		for course:PackedVector3Array in spec.get("tribs",[]):
			for k in range(1,course.size()):
				var p:=Vector2(course[k-1].x,course[k-1].z); var q:=Vector2(course[k].x,course[k].z)
				var steps:=maxi(1,ceili(p.distance_to(q)/(cell*0.5)))
				for s in steps+1:
					var m:=p.lerp(q,float(s)/float(steps))
					var x:=roundi((m.x-origin.x)/cell); var y:=roundi((m.y-origin.y)/cell)
					if x<0 or y<0 or x>=nx or y>=ny: continue
					var list:Array=buckets.get(y*nx+x,[])
					if list.is_empty() or list[list.size()-1][0]!=p: list.append([p,q])
					buckets[y*nx+x]=list
	var climb_k:=March._mix_value(March.CLIMB_K,mix)
	var bridged:=int(spec.bridge)>=1
	var ecost:=PackedFloat32Array(); ecost.resize(n*8); ecost.fill(INF)
	for y in ny:
		if bool(cancel[0]): return {}
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
				var kind:=""
				if fixture_crossings:
					kind=March.crossing(origin+Vector2(float(x),float(y))*cell,origin+Vector2(float(xx),float(yy))*cell)
				elif (side[i]!=0 and side[j]!=0 and side[i]!=side[j]) or buckets.has(i) or buckets.has(j):
					var segs:Array=(buckets.get(i,[]) as Array)+(buckets.get(j,[]) as Array)
					kind=_crossing(origin+Vector2(float(x),float(y))*cell,origin+Vector2(float(xx),float(yy))*cell,world_seed,segs)
				if kind!="": e+=March.crossing_cost(kind,mix,bridged and road[i]>=0 and road[j]>=0)
				ecost[i*8+k]=e
	# From our own hubs first; then the held towns join as depots.
	var sources:Array=[]
	for h_row:Dictionary in spec.settlements: sources.append({"id":String(h_row.id),"name":String(h_row.name),"kind":String(h_row.kind),"pos":h_row.pos,"base":0.0})
	var field:={"key":int(spec.key),"geo_key":int(spec.geo_key),"world":int(spec.get("world",0)),"origin":origin,"cell":cell,"nx":nx,"ny":ny,"carrier":String(spec.carrier),"mix":mix,
		"ground":ground,"road":road,"fac":fac,"sources":sources}
	var found:=_search(field,ecost,sources,cancel)
	if found.is_empty(): return {}
	var held:Array=spec.get("held",[])
	if not held.is_empty():
		field["cost"]=found.cost
		field["src"]=found.src
		for h_row:Dictionary in held:
			var reach:=_bilinear(field,found.cost,h_row.pos)
			if not is_finite(reach): continue
			# The settlement whose line stocks this depot.
			var node:=_node_near(field,h_row.pos)
			var via:=int((found.src as PackedInt32Array)[node]) if node>=0 else -1
			sources.append({"id":String(h_row.id),"name":String(h_row.name),"kind":String(h_row.kind),"pos":h_row.pos,"base":reach*RELAY,"region_id":String(h_row.get("region_id","")),"civ_id":String(h_row.get("civ_id","")),
				"via":String((sources[via] as Dictionary).name) if via>=0 and via<sources.size() else ""})
		found=_search(field,ecost,sources,cancel)
		if found.is_empty(): return {}
	field["cost"]=found.cost; field["src"]=found.src; field["parent"]=found.parent
	field["sources"]=sources
	field["ms"]=float(Time.get_ticks_usec()-began)/1000.0
	field["sample_ms"]=sampled_ms
	return field

## Dijkstra from the sources' seeds over the precomputed edge costs.
static func _search(field:Dictionary,ecost:PackedFloat32Array,sources:Array,cancel:Array=[false])->Dictionary:
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
	var popped:=0
	while hi.size()>0:
		var i:=_pop(hf,hi)
		if closed[i]==1: continue
		closed[i]=1
		popped+=1
		if popped%2048==0 and bool(cancel[0]): return {}
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
# The field in hand (main thread)
# --------------------------------------------------------------------------

## The field the screens read. While the day's rations have taken a field
## today, that one (so the chart and the rations agree); otherwise the
## newest finished. In play it never builds here: a worker builds what the
## world wants. sync=true builds it here and now: tests and tools only.
## Fixture ground (tests) always builds on the spot.
static func field(sync:=false)->Dictionary:
	var s:=spec()
	if s.is_empty() or bool(s.get("no_ground",false)): return {}
	_same_world(s)
	_poll()
	var key:=int(s.key)
	if _key(_field)!=key:
		if sync or not bool(s.get("async",false)): _take(_built.get(key,{}) if _built.has(key) else _build_now(s))
		elif _rations_day!=today() and _built.has(key): _take(_built[key])
	if bool(s.get("async",false)) and _job==null and _key(_field)!=key and not _built.has(key): _start(s)
	return _field

## The field the day's rations read: fixed for the day, the one built from
## the world as the rations found it at their first ask the day before
## (waiting WAIT_BUDGET_MS at most if its build is still under way, fully
## only when nothing is in hand yet), so a saved game replays the same.
## The world as found today is built for tomorrow.
static func rations_field()->Dictionary:
	var s:=spec()
	if s.is_empty() or bool(s.get("no_ground",false)): return {}
	_same_world(s)
	var d:=today()
	if d==_rations_day: return _field
	_poll()
	var key:=int(s.key)
	var wanted:=_rations_key if _rations_key!=0 else key
	if _key(_field)!=wanted and not _built.has(wanted):
		if not bool(s.get("async",false)):
			if wanted==key: _build_now(s)
		elif _job!=null and int(_job.spec.key)==wanted:
			# Nothing in hand (a load): wait for it. Otherwise wait a moment
			# at most; a build slower than a day is taken the next day.
			_await_job(-1.0 if _field.is_empty() else WAIT_BUDGET_MS)
		elif _field.is_empty() and wanted==key:
			_build_now(s)
	if _built.has(wanted): _take(_built[wanted])
	_rations_key=key
	_rations_day=d
	# Tomorrow's field: under way from now.
	if bool(s.get("async",false)) and _key(_field)!=key and not _built.has(key):
		if _job!=null and int(_job.spec.key)!=key: _discard_job()
		if _job==null: _start(s)
	return _field

## Starts a worker build when the world has moved on from the field in
## hand. Cheap: the map calls it a few times a second.
static func prefetch()->void:
	field(false)

## Whether the field in hand is the one the world wants now.
static func current()->bool:
	var s:=spec()
	return not s.is_empty() and _key(_field)==int(s.get("key",-1))

## Whether a worker build is under way.
static func building()->bool:
	return _job!=null

static func _key(f:Dictionary)->int:
	return int(f.get("key",0))

static func _take(f:Dictionary)->void:
	if f.is_empty() or _key(f)==_key(_field): return
	_field=f
	_report_cache.clear()

static func _build_now(s:Dictionary)->Dictionary:
	builds+=1
	var f:=build(s,_cached_ground(s))
	_keep(f)
	return f

## A field or a build of another world (a new game, a new terrain) is
## never read: forget them.
static func _same_world(s:Dictionary)->void:
	var world:=int(s.get("world",0))
	if not _field.is_empty() and int(_field.get("world",0))!=world:
		_field={}; _built.clear(); _report_cache.clear(); _rations_key=0; _rations_day=-1
	if _job!=null and int(_job.spec.get("world",0))!=world: _discard_job()

static func _cached_ground(s:Dictionary)->Dictionary:
	return _ground_cache.get(int(s.geo_key),{})

## Keeps a finished field (the last few, by key) and its ground.
static func _keep(f:Dictionary)->void:
	if f.is_empty(): return
	_built[_key(f)]=f
	while _built.size()>4: _built.erase(_built.keys()[0])
	_ground_cache[int(f.geo_key)]=f.ground
	while _ground_cache.size()>2: _ground_cache.erase(_ground_cache.keys()[0])

static func _start(s:Dictionary)->void:
	_hook_quit()
	_job=BuildJob.new(s,_cached_ground(s),load("res://scripts/supply_state.gd"))
	_job.task=WorkerThreadPool.add_task(_job.run,false,"Supply field")
	async_builds+=1

## Waits for the worker build (budget_ms<0: until it is done).
static func _await_job(budget_ms:float)->void:
	if _job==null: return
	var began:=Time.get_ticks_usec()
	if budget_ms<0.0:
		WorkerThreadPool.wait_for_task_completion(_job.task)
		_finish_job()
	else:
		while not WorkerThreadPool.is_task_completed(_job.task) and float(Time.get_ticks_usec()-began)<budget_ms*1000.0: OS.delay_usec(250)
		_poll()
	waited_ms+=float(Time.get_ticks_usec()-began)/1000.0

## Takes a finished worker build into the kept fields.
static func _poll()->void:
	if _job==null or not WorkerThreadPool.is_task_completed(_job.task): return
	WorkerThreadPool.wait_for_task_completion(_job.task)
	_finish_job()

static func _finish_job()->void:
	var done:=_job
	_job=null
	if done==null or done.result.is_empty(): return
	var s:=spec()
	if int(done.result.get("world",0))!=int(s.get("world",-1)): return
	_keep(done.result)

## Stops any worker build and waits for it (it stops at its next row).
static func _discard_job()->void:
	if _job==null: return
	_job.cancel[0]=true
	if _job.task>=0: WorkerThreadPool.wait_for_task_completion(_job.task)
	_job=null

## For the terrain's exit and a new world: no build outlives the world.
static func shutdown()->void:
	_discard_job()

static var _quit_hooked:=false
## Waits for any worker build when the scene tree comes down (quit), even
## where no map node is there to do it.
static func _hook_quit()->void:
	if _quit_hooked: return
	var tree:=Engine.get_main_loop() as SceneTree
	if tree==null or tree.root==null: return
	tree.root.tree_exiting.connect(Callable(load("res://scripts/supply_state.gd"),"shutdown"))
	_quit_hooked=true

## Forget every field (tests; a new world).
static func reset()->void:
	_discard_job()
	_field={}; _built.clear(); _rations_key=0; _rations_day=-1
	_ground_cache.clear(); _report_cache.clear(); _report_day=-1
	_known_cache=[-1,-1,Rect2()]; _spec={}; _spec_sig=0
	_sampler=null; _sampler_key=0; _tribs=[]; _tribs_key=0


# --------------------------------------------------------------------------
# Reading the field at a point
# --------------------------------------------------------------------------

## A lattice value at a point, bilinear over the reached nodes round it
## (INF when none of them is reached or the point is off the lattice).
static func _bilinear(field:Dictionary,values:PackedFloat32Array,p:Vector2)->float:
	var nx:=int(field.nx); var ny:=int(field.ny)
	var fx:=(p.x-(field.origin as Vector2).x)/float(field.cell)
	var fy:=(p.y-(field.origin as Vector2).y)/float(field.cell)
	if fx<0.0 or fy<0.0 or fx>float(nx-1) or fy>float(ny-1): return INF
	var x0:=clampi(floori(fx),0,maxi(0,nx-2)); var y0:=clampi(floori(fy),0,maxi(0,ny-2))
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
		var node:=roundi(fy)*nx+roundi(fx)
		return values[node] if node>=0 and node<values.size() else INF
	return total/weight

## Bilinear over all nodes (land or not), for ground values.
static func _bilinear_any(field:Dictionary,values:PackedFloat32Array,p:Vector2)->float:
	var nx:=int(field.nx); var ny:=int(field.ny)
	var fx:=(p.x-(field.origin as Vector2).x)/float(field.cell)
	var fy:=(p.y-(field.origin as Vector2).y)/float(field.cell)
	if fx<0.0 or fy<0.0 or fx>float(nx-1) or fy>float(ny-1): return INF
	var x0:=clampi(floori(fx),0,maxi(0,nx-2)); var y0:=clampi(floori(fy),0,maxi(0,ny-2))
	var u:=clampf(fx-float(x0),0.0,1.0); var v:=clampf(fy-float(y0),0.0,1.0)
	var x1:=mini(x0+1,nx-1); var y1:=mini(y0+1,ny-1)
	return lerpf(lerpf(values[y0*nx+x0],values[y0*nx+x1],u),lerpf(values[y1*nx+x0],values[y1*nx+x1],u),v)

## Whether the field's lattice covers a point.
static func covers(field:Dictionary,p:Vector2)->bool:
	if field.is_empty() or not p.is_finite(): return false
	var fx:=(p.x-(field.origin as Vector2).x)/float(field.cell)
	var fy:=(p.y-(field.origin as Vector2).y)/float(field.cell)
	return fx>=0.0 and fy>=0.0 and fx<=float(int(field.nx)-1) and fy<=float(int(field.ny)-1)

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

## Level km of hauling from the nearest hub to p, and which hub:
## {effort, source (index into the sources), sources, fallback}.
## Off the field (or with none), the straight line from the nearest hub.
static func effort_at(field:Dictionary,p:Vector2)->Dictionary:
	if not p.is_finite(): return {"effort":INF,"source":-1,"sources":[],"fallback":true}
	if not covers(field,p): return _fallback_effort(p)
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
	return {"effort":effort,"source":source,"sources":sources,"fallback":false}

## The straight line from the nearest hub (a held town counts as a depot).
static func _fallback_effort(p:Vector2)->Dictionary:
	var s:=spec()
	var hub_list:Array=s.get("hubs",[])
	if hub_list.is_empty(): hub_list=hubs()
	var sources:Array=[]
	var settlements:Array=[]
	for h:Dictionary in hub_list:
		if not is_relay(String(h.kind)): settlements.append(h); sources.append({"id":String(h.id),"name":String(h.name),"kind":String(h.kind),"pos":h.pos,"base":0.0})
	for h:Dictionary in hub_list:
		if not is_relay(String(h.kind)): continue
		var reach:=INF; var via:=""
		for home:Dictionary in settlements:
			var e:=(home.pos as Vector2).distance_to(h.pos)*FALLBACK_FACTOR
			if e<reach: reach=e; via=String(home.name)
		if is_finite(reach): sources.append({"id":String(h.id),"name":String(h.name),"kind":String(h.kind),"pos":h.pos,"base":reach*RELAY,"via":via})
	var best:=INF; var source:=-1
	for k in sources.size():
		var e:=float((sources[k] as Dictionary).base)+((sources[k] as Dictionary).pos as Vector2).distance_to(p)*FALLBACK_FACTOR
		if e<best: best=e; source=k
	return {"effort":best,"source":source,"sources":sources,"fallback":true}

## The supply line from the hub to p: [hub, ..., p] (along the field; a
## straight line where the field does not reach).
static func route_to(field:Dictionary,p:Vector2)->PackedVector2Array:
	var out:=PackedVector2Array()
	if not p.is_finite(): return out
	if not covers(field,p):
		var e:=_fallback_effort(p)
		if int(e.source)>=0: out.append(((e.sources as Array)[int(e.source)] as Dictionary).pos); out.append(p)
		return out
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
	var nx:=int(field.get("nx",0)); var ny:=int(field.get("ny",0))
	for k in range(1,route.size()):
		var a:=route[k-1]; var b:=route[k]
		var d:=a.distance_to(b)
		km+=d
		if road.is_empty(): continue
		var mid:=a.lerp(b,0.5)
		var fx:=roundi((mid.x-(field.origin as Vector2).x)/float(field.cell)); var fy:=roundi((mid.y-(field.origin as Vector2).y)/float(field.cell))
		if fx<0 or fy<0 or fx>=nx or fy>=ny: continue
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
## The coldest day (by cold()) on or after `day` where `at` stands: the
## seasons turn opposite ways north and south of the equator line.
static func coldest_day(at:Vector2,day:int)->int:
	var phase:=91 if at.y>0.0 else 274
	var deep:=day-posmod(day,365)+phase
	if deep<day: deep+=365
	return deep

static func haul_days(effort:float,who:String,chill:float)->float:
	if not is_finite(effort): return INF
	var c:Dictionary=CARRIERS.get(who,CARRIERS.foot)
	return effort/float(c.pace)*(1.0+float(March.WINTER_K.get(String(c.arm),0.5))*chill)

## Share of a load the carriers eat for each day of hauling beyond FREE_DAYS,
## with the people's supply endurance (research: pack animals, waystations,
## food caches and travel food; research_mechanics.gd haul_loss_factor_of).
static func carrier_loss(who:String,endurance:float=0.0)->float:
	var c:Dictionary=CARRIERS.get(who,CARRIERS.foot)
	return float(c.loss)*Mechanics.haul_loss_factor_of(endurance)

## Share of a load that reaches the band after that many days of hauling.
static func haul_share(days:float,who:String,endurance:float=0.0)->float:
	if not is_finite(days): return 0.0
	return clampf(1.0-carrier_loss(who,endurance)*maxf(0.0,days-FREE_DAYS),0.0,1.0)

## The effort at which the carriers still deliver `share` of a load in mild weather.
static func reach_effort(who:String,share:float=REACH_HAUL,endurance:float=0.0)->float:
	var c:Dictionary=CARRIERS.get(who,CARRIERS.foot)
	return (FREE_DAYS+(1.0-share)/carrier_loss(who,endurance))*float(c.pace)

## How well a band of this size forages this country today, as a factor on
## field_rations' base shares: the land's richness, the season, the size.
static func forage_factor_from(rich:float,chill:float,troops:int)->float:
	var area:=clampf(rich/FORAGE_TYPICAL,0.3,1.5)
	var season:=1.0-0.7*chill
	var size:=clampf(pow(SIZE_REF/float(maxi(1,troops)),0.25),0.6,1.1)
	return clampf(area*season*size,0.2,1.5)

## The land at a point: {rich, t, swing, cold}. From the field; off it, from
## the marching ground (main thread) or open land.
static func land_at(field:Dictionary,p:Vector2,day:int)->Dictionary:
	var rich:=NEUTRAL_RICH; var t:=-1.0; var swing:=NEUTRAL_SWING
	if covers(field,p):
		var g:Dictionary=field.ground
		rich=_bilinear_any(field,g.rich,p); t=_bilinear_any(field,g.t,p); swing=_bilinear_any(field,g.swing,p)
	elif p.is_finite() and March.has_ground():
		var gd:=March.ground_at(p)
		if not gd.is_empty():
			rich=richness(float(gd.get("rain",0.5)),float(gd.get("wood",0.0)),float(gd.get("wet",0.0)),float(gd.get("h",0.25)))
			t=float(gd.get("t",-1.0))
			if March._terrain()!=null: swing=float(PlanetEnvironment.seasonality_at(p))
	return {"rich":rich,"t":t,"swing":swing,"cold":cold(day,p,t,swing)}

## Home under siege: the share of carts that get out (military_campaign).
static func siege_factor()->float:
	var mc:Variant=_mc()
	if mc==null or not mc.has_method("siege_home_food_access"): return 1.0
	return clampf(float(mc.siege_home_food_access()),0.0,1.0)


# --------------------------------------------------------------------------
# The day's terms at a point (one function for the rations, the screens and
# the map's grid)
# --------------------------------------------------------------------------

## The model at a point for a band of `troops`: transport (the carriers'
## share at all), stores (the share the stores could send), siege (the
## share of carts a besieged home lets out) and endurance (the people's
## supply endurance) are the day's inputs, read once by the caller (day_inputs()).
static func terms(field:Dictionary,p:Vector2,day:int,troops:int,moving:bool,transport:float,stores:float,siege:float,endurance:float=0.0,preview:Dictionary={})->Dictionary:
	var who:=String(field.carrier) if not field.is_empty() else carrier()
	var e:=effort_at(field,p)
	var land:=land_at(field,p,day)
	var chill:=float(land.cold)
	# A band not yet out (the map, a point): its share with every band already
	# out on the carriers too.
	if not preview.is_empty(): transport=preview_ratio(preview,float(e.effort),chill,troops)
	var days:=haul_days(float(e.effort),who,chill)
	var haul:=haul_share(days,who,endurance)
	var source:=int(e.source)
	var sources:Array=e.sources
	var hub:Dictionary=(sources[source] as Dictionary) if source>=0 and source<sources.size() else {}
	if not hub.is_empty() and (String(hub.kind)=="home" or is_relay(String(hub.kind))): haul*=siege
	var carried:=clampf(transport*haul*stores,0.0,1.0)
	var base:=FieldRations.FORAGE_MOVING if moving else FieldRations.FORAGE_STATIONED
	var share:=minf(FORAGE_SHARE_MAX,base*forage_factor_from(float(land.rich),chill,troops))
	var foraged:=(1.0-carried)*share
	return {"ratio":clampf(carried+foraged,0.0,1.0),"carried":carried,"foraged":foraged,"local":0.0,"air":0.0,"haul":haul,"transport":transport,"stores":stores,
		"effort":float(e.effort),"days":days,"cold":chill,"rich":float(land.rich),"forage_share":share,"hub":hub,"carrier":who,"fallback":bool(e.fallback)}

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
static func grid(field:Dictionary,troops:int,inputs:Dictionary,known:PackedByteArray,cancel:Array=[false])->Dictionary:
	var n:=int(field.nx)*int(field.ny)
	var ratio:=PackedFloat32Array(); ratio.resize(n); ratio.fill(-1.0)
	var carried:=PackedFloat32Array(); carried.resize(n)
	var haul:=PackedFloat32Array(); haul.resize(n)
	var land:PackedByteArray=(field.ground as Dictionary).land
	var day:=int(inputs.get("day",0))
	for i in n:
		if i%512==0 and bool(cancel[0]): return {}
		if land[i]==0 or i>=known.size() or known[i]==0: continue
		var t:=terms(field,node_pos(field,i),day,troops,false,float(inputs.transport),float(inputs.stores),float(inputs.siege),float(inputs.get("endurance",0.0)),inputs.get("preview",{}))
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
	var preview:Dictionary={}
	if mc!=null and mc.has_method("carrier_reading"): preview=(mc.carrier_reading() as Dictionary).get("preview",{})
	return {"transport":transport,"stores":stores,"siege":siege_factor(),"endurance":endurance_today(),"day":today(),"preview":preview}

## The people's supply endurance (research_mechanics.gd), 0 without a people.
static func endurance_today()->float:
	if WorldSimulation==null or WorldSimulation.discovery==null: return 0.0
	return Mechanics.supply_endurance()


# --------------------------------------------------------------------------
# The engine's two questions (never wait for a field)
# --------------------------------------------------------------------------

## Share of the carriers' food that reaches this force today: the haul
## along its supply line and a besieged home's gate (1 with no place or no
## home). military_campaign._force_provision_access.
static func haul_for(force:Dictionary)->float:
	var p:=force_pos(force)
	if not p.is_finite() or hubs_empty(): return 1.0
	var f:=rations_field()
	var e:=effort_at(f,p)
	if not is_finite(float(e.effort)): return 0.0
	var who:=String(f.carrier) if not f.is_empty() else carrier()
	var land:=land_at(f,p,today())
	var haul:=haul_share(haul_days(float(e.effort),who,float(land.cold)),who,endurance_today())
	var source:=int(e.source)
	var sources:Array=e.sources
	if source>=0 and source<sources.size() and String((sources[source] as Dictionary).kind) in ["home","held"]: haul*=siege_factor()
	return haul

## Days of hauling from our nearest hub to this force today (0 with no place
## or no hub, INF where no carrier can reach it): the carriers' round trip
## (carriers.gd) is built on it.
static func haul_days_for(force:Dictionary)->float:
	var p:=force_pos(force)
	if not p.is_finite() or hubs_empty(): return 0.0
	var f:=rations_field()
	var e:=effort_at(f,p)
	if not is_finite(float(e.effort)): return INF
	var who:=String(f.carrier) if not f.is_empty() else carrier()
	return haul_days(float(e.effort),who,float(land_at(f,p,today()).cold))

## The haul to this force from our nearest hub: {reachable, effort (level
## km), cold}. Unplaced forces or no hubs: reachable at no effort.
static func haul_inputs_for(force:Dictionary)->Dictionary:
	var p:=force_pos(force)
	if not p.is_finite() or hubs_empty(): return {"reachable":true,"effort":0.0,"cold":0.0}
	var f:=rations_field()
	var e:=effort_at(f,p)
	if not is_finite(float(e.effort)): return {"reachable":false,"effort":INF,"cold":0.0}
	return {"reachable":true,"effort":float(e.effort),"cold":float(land_at(f,p,today()).cold)}

## Carriers' round trip for a day's loads over a haul of `days`: out and
## back, at least a day, the railway taking up to RAIL_SHARE of it.
const MIN_ROUND_TRIP:=1.0
const RAIL_SHARE:=0.45
const CARRIER_ARMS:={"lorry":"motor","cart":"wheeled","porter":"foot"}
static func carrier_round_trip(days:float,rail:float)->float:
	if not is_finite(days): return INF
	return maxf(MIN_ROUND_TRIP,2.0*maxf(0.0,days))*(1.0-RAIL_SHARE*clampf(rail,0.0,1.0))

## Loads a day the fleet brings (carriers.gd preview: each kind's trip load
## over its load-weighted mean round trip), with an extra band of
## `extra_loads` whose round trips are `extra_rt` (the map's preview).
static func carried_a_day(preview:Dictionary,extra_loads:float=0.0,extra_rt:Dictionary={})->float:
	var loads:=float(preview.get("loads",0.0))+extra_loads
	var trip:Dictionary=preview.get("trip",{})
	var sum_rt:Dictionary=preview.get("sum_rt",{})
	var eff:=float(preview.get("efficiency",1.0))
	var total:=0.0
	for kind in trip:
		var mean_rt:=(float(sum_rt.get(kind,0.0))+extra_loads*float(extra_rt.get(kind,MIN_ROUND_TRIP)))/loads if loads>0.0 else MIN_ROUND_TRIP
		if mean_rt>0.0 and is_finite(mean_rt): total+=float(trip[kind])/mean_rt
	return total*eff

## The share of its bread a new band of `troops` would get carried here, on
## top of every band already out: the map is honest about sending one more.
static func preview_ratio(preview:Dictionary,effort:float,chill:float,troops:int)->float:
	if preview.is_empty() or not is_finite(effort): return 0.0 if not is_finite(effort) else 1.0
	var bread:=float(maxi(1,troops))*1.12
	var rt:={}
	for kind in CARRIER_ARMS: rt[kind]=carrier_round_trip(haul_days(effort,String(CARRIER_ARMS[kind]),chill),float(preview.get("rail",0.0)))
	var moved:=carried_a_day(preview,bread,rt)
	return clampf(moved/(float(preview.get("bread",0.0))+bread),0.0,1.0)

static func hubs_empty()->bool:
	var s:=spec()
	return s.is_empty() or (s.get("hubs",[]) as Array).is_empty()

## How well this force forages where it stands today, as a factor on
## field_rations' base shares (1 when it has no place).
static func forage_factor(force:Dictionary)->float:
	var p:=force_pos(force)
	if not p.is_finite(): return 1.0
	var land:=land_at(rations_field(),p,today())
	return forage_factor_from(float(land.rich),float(land.cold),int(force.get("troops",0)))


# --------------------------------------------------------------------------
# Reports for the screens
# --------------------------------------------------------------------------

## What a band of `troops` (-1: the middle one of our bands out) would get at
## this point today, standing (or moving).
## one_more: a band not yet out (the map's land note), sharing the carriers
## with every band already out; false reads the carriers as they are today.
static func at_point(point:Vector2,troops:int=-1,moving:=false,one_more:=true)->Dictionary:
	if troops<0: troops=typical_troops()
	var f:=field()
	var d:=day_inputs()
	var t:=terms(f,point,int(d.day),troops,moving,float(d.transport),float(d.stores),float(d.siege),float(d.endurance),d.get("preview",{}) if one_more else {})
	var report:=_report_from_terms(f,t,point)
	report["force_kind"]="point"; report["troops"]=troops
	report["words"]=words(report)
	return report

## The size the map's wash is drawn for: the middle one of our bands out,
## else the home levy, else 30.
static func typical_troops()->int:
	var mc:Variant=_mc()
	var sizes:Array=[]
	if mc!=null:
		for a in mc.field_armies:
			if a is Dictionary and int((a as Dictionary).get("troops",0))>0: sizes.append(int((a as Dictionary).troops))
		if sizes.is_empty() and int((mc.home_army as Dictionary).get("troops",0))>0: sizes.append(int(mc.home_army.troops))
	if sizes.is_empty(): return 30
	sizes.sort()
	return int(sizes[sizes.size()/2])

static func _report_from_terms(f:Dictionary,t:Dictionary,p:Vector2)->Dictionary:
	var hub:Dictionary=t.hub
	var route:=route_to(f,p) if not hub.is_empty() else PackedVector2Array()
	var roads:=route_roads(f,route) if route.size()>=2 else {"km":0.0,"road":0.0,"tier":-1}
	var ratio:=float(t.ratio)
	# Standing at a depot of ours, its line is the settlement that stocks it.
	var hub_name:=String(hub.get("name","")); var hub_kind:=String(hub.get("kind",""))
	if is_relay(hub_kind) and String(hub.get("via",""))!="" and (hub.get("pos",Vector2.INF) as Vector2).distance_to(p)<=AT_DEPOT_KM:
		hub_name=String(hub.via); hub_kind="home"
	var report:={"ratio":ratio,"state":state_of(ratio),"carried":float(t.carried),"foraged":float(t.foraged),"local":float(t.local),"air":0.0,
		"haul":float(t.haul),"transport":float(t.transport),"stores":float(t.stores),"days":float(t.days),"effort":float(t.effort),
		"km":float(roads.km),"road":ROAD_WORDS[int(roads.tier)] if int(roads.tier)>=0 and float(roads.road)>=0.5 else "","road_share":float(roads.road),
		"hub":hub_name,"hub_kind":hub_kind,"hub_position":hub.get("pos",Vector2.INF),
		"season":"winter" if float(t.cold)>=0.3 else "","cold":float(t.cold),"rich":float(t.rich),"carrier":String(t.carrier),
		"route":route,"position":p,"siege":"","blockade":"","hungry_days":0.0,"hungry":false,"supply_level":ratio,"fallback":bool(t.fallback)}
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
	var cache_key:=hash([kind,int(force.get("army_id",0)),String(force.get("region_id","")),int(force.get("provision_day",-1)),float(force.get("provision_ratio",-1.0)),p.snapped(Vector2.ONE*0.05) if p.is_finite() else Vector2.ZERO,int(force.get("troops",0)),int(_field.get("key",0)),String(force.get("status",""))])
	if _report_cache.has(cache_key): return _report_cache[cache_key]
	var report:Dictionary
	var at_home:bool=kind=="home" or (mc!=null and kind=="field" and bool(mc._army_is_home(force)))
	if at_home:
		var ratio:=clampf(float(force.get("provision_ratio",1.0)),0.0,1.0)
		var s:Variant=_state()
		report={"ratio":ratio,"state":state_of(ratio),"carried":ratio,"foraged":0.0,"local":0.0,"air":0.0,"haul":1.0,"transport":1.0,"stores":ratio,
			"days":0.0,"effort":0.0,"km":0.0,"road":"","road_share":0.0,"hub":String(s.settlement_name) if s!=null else "home","hub_kind":"home","hub_position":p,
			"season":"","cold":0.0,"rich":NEUTRAL_RICH,"carrier":carrier(),"route":PackedVector2Array(),"position":p,"at_home":true,"fallback":false}
	else:
		var f:=field()
		var d:=day_inputs()
		var moving:=String(force.get("status","stationed"))=="moving"
		var t:=terms(f,p,int(d.day),int(force.get("troops",0)),moving,float(d.transport),float(d.stores),float(d.siege),float(d.endurance))
		report=_report_from_terms(f,t,p)
		# The same line on the coldest day of the coming year where the band
		# stands, with today's carriers: the warning before the snow.
		if kind=="field" and p.is_finite():
			var deep:=coldest_day(p,int(d.day))
			var w:=terms(f,p,deep,int(force.get("troops",0)),false,float(d.transport),float(d.stores),float(d.siege),float(d.endurance))
			if float(w.cold)>0.0: report["winter"]={"ratio":float(w.ratio),"in_days":deep-int(d.day),"cold":float(w.cold)}
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
	report["name"]=town_name(String(force.get("civ_id","")),String(force.region_id),String(force.get("region_name",""))) if kind=="garrison" else String(force.get("name",""))
	report["troops"]=int(force.get("troops",0))
	report["supply_level"]=clampf(float(force.get("supply_level",report.ratio)),0.0,1.0)
	report["hungry_days"]=float(force.get("hungry_days",0.0))
	report["hungry"]=FieldRations.is_hungry(force)
	# What hunger has cost the band so far, and its fodder, fuel and rounds
	# (field_sustainment.gd): the war leader states these numbers.
	# Only while hunger is recent (a month since the last loss); older sorrow
	# stays in the chronicle, not in today's report.
	var hunger_recent:=today()-int(force.get("hunger_last_day",-100000))<=30
	report["hunger_losses"]=(force.get("hunger_losses",{}) as Dictionary).duplicate() if force.get("hunger_losses") is Dictionary and hunger_recent else {}
	report["stores_share"]=clampf(float(force.get("stores_share",1.0)),0.0,1.0)
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
			report.siege="besieging %s: the siege holds while they are fed" % String((siege.get("threat",{}) as Dictionary).get("target_region_name","the town"))
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

## "4 days", "a day", "half a day".
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
	var from:="from" if String(report.get("hub_kind",""))!="held" else "from our depot at"
	return "%s %s %s%s" % [days_words(float(report.days)),from,hub,way]

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
