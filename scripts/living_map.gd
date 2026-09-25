extends Node3D
## THE LIVING MAP — the god's people seen from a few hundred metres up.
##
## Presentation only. Nothing here changes the simulation or the save:
## - Workers. A small, capped number of visible people (never one per person)
##   do today's real work. Their mix is read from the labour allocation
##   (GameState.population_allocations, owned by GovernmentPeopleSystem) and,
##   for food, from the day's food sources (gathering, hunting, fishing,
##   cultivation). They walk out to the woods, the water or the fields, work,
##   and carry the load home; builders go to plots under construction.
## - The hearth. A fire with firelight on the ground and smoke from the homes;
##   more smoke as the people grow (bounded).
## - Marks of the day. A birth lights a small flare over a home; a death sends
##   a mourners' procession to the burial ground; returning scouts are seen
##   walking home. Court rites stay in rite_marks.gd, which borrows these
##   figures for its processions and mourners.
## - Seasons. The shared seasonal terrain shader is told whether the year is
##   warming or cooling, so the land greens in spring and dries in summer as
##   well as browning and snowing in winter.
## - The opening camera starts about 200 m above the travelling people.
##
## Everything is procedural (no image assets) and bounded: at most
## MAX_WORKERS + MAX_EVENT_FIGURES figures in two draw calls, MAX_PLUMES smoke
## columns in one, MAX_FLARES flares, and no scene lights. Nothing moves or
## costs a frame when the camera is too far away to see it.

const NODE_NAME:="LivingMap"
const UNIT:=0.001                  ## one metre in map units (km)
const FIGURE_SCALE:=1.6            ## people read at 200 m without looking like giants
const MAX_WORKERS:=40
const MAX_EVENT_FIGURES:=18
const MAX_PLUMES:=8
const PUFFS_PER_PLUME:=8
const MAX_FLARES:=4
const MAX_PROCESSIONS:=2
const MAX_PARTIES:=1
const FIGURE_MAX_VIEW:=2.2         ## camera.size (km) beyond which figures are not drawn
const SMOKE_MAX_VIEW:=6.5
const OPENING_ALTITUDE_M:=200.0
const WALK_MPS:=4.2                ## a brisk, time-lapsed walk
const HEIGHT_CELL:=0.003           ## 3 m ground-height lattice for walking figures
const HEIGHT_CACHE_MAX:=6000
const POSES:={"walk":0,"gather":1,"chop":2,"fish":3,"fire":4,"talk":5,"mourn":6,"watch":7,"craft":8}
## What each labour role looks like when a representative does it.
const ROLE_ACTIVITY:={"Survey":"survey","Extraction":"haul","Construction":"build","Crafting":"craft","Logistics":"carry","Knowledge":"fire","Administration":"council","Defense":"watch"}
const FOOD_ACTIVITY:={"Wild gathering":"gather","Hunting":"hunt","Fishing":"fish","Cultivation":"farm"}
const CLOTH:=[Color(0.46,0.35,0.24),Color(0.55,0.47,0.33),Color(0.38,0.33,0.27),Color(0.52,0.40,0.30),Color(0.42,0.44,0.36),Color(0.60,0.52,0.40)]

## Probes compare before/after in one build; the player never changes it.
static var enabled:=true
static var _figure_mesh:ArrayMesh
static var _figure_material:ShaderMaterial
static var _smoke_material:ShaderMaterial
static var _glow_material:ShaderMaterial
static var _flare_material:ShaderMaterial
static var _clock:=0.0
static var _clock_frame:=-1

var terrain:Node3D
var anchor:=Vector3.ZERO
var settled:=false
var workers:Array[Dictionary]=[]
var events:Array[Dictionary]=[]          ## procession / party walkers
var flares:Array[Dictionary]=[]
var spots:Dictionary={}                   ## activity -> Array[Vector2] (anchor-local km)
var homes:Array[Vector2]=[]
var chimneys:Array[Vector2]=[]
var burial:=Vector2.ZERO
var labor_signature:=""
var site_signature:=""
var worker_mm:MultiMeshInstance3D
var event_mm:MultiMeshInstance3D
var smoke_mm:MultiMeshInstance3D
var hearth_root:Node3D
var flame:Node3D
var glow:MeshInstance3D
var last_born:=-1
var last_buried:=-1
var tally_start:=-1
var travel_heading:=Vector2(1,0)
var rng:=RandomNumberGenerator.new()
var figures_visible:=false
var last_report:Dictionary={}
var seasonal_count:=-1
var smoke_legibility:=1.0
var frame_usec:=0.0
var day_usec:=0.0
var smoke_signature:=""
var relocated:=false
var height_cache:Dictionary={}
var land_signature:=""
var land_spots:Dictionary={}

# --------------------------------------------------------------------------
# Hooks called by the map (two lines in local_terrain.gd)
# --------------------------------------------------------------------------

static func open_on_people(host:Node3D)->void:
	## The first frame of a new game: about 200 m above the travelling people.
	var layer:=ensure(host)
	if layer==null: return
	layer.set_season(GameState.elapsed_days)
	if GameState.settlement_site_committed or GameState.elapsed_days>1.0: return
	var camera:Camera3D=host.get("camera")
	if camera==null or not host.has_method("_inspect_aerial_altitude"): return
	host.call("_inspect_aerial_altitude",OPENING_ALTITUDE_M*3.280839895)

static func refresh(host:Node3D)->void:
	## Once per committed day. Cheap when nothing changed.
	var layer:=ensure(host)
	if layer!=null: layer.day_tick()

static func ensure(host:Node3D)->Node3D:
	if not enabled or host==null or not is_instance_valid(host): return null
	var layer:=host.get_node_or_null(NODE_NAME) as Node3D
	if layer==null:
		layer=(load("res://scripts/living_map.gd") as GDScript).new()
		layer.name=NODE_NAME
		layer.set("terrain",host)
		host.add_child(layer)
	return layer

static func tick_clock(delta:float)->float:
	## One shared animation clock for every figure, advanced once per frame.
	var frame:=Engine.get_process_frames()
	if frame!=_clock_frame:
		_clock_frame=frame
		_clock+=delta
		if _figure_material: _figure_material.set_shader_parameter("anim_clock",_clock)
		if _smoke_material: _smoke_material.set_shader_parameter("anim_clock",_clock)
		if _glow_material: _glow_material.set_shader_parameter("anim_clock",_clock)
		if _flare_material: _flare_material.set_shader_parameter("anim_clock",_clock)
	return _clock

# --------------------------------------------------------------------------
# Lifecycle
# --------------------------------------------------------------------------

func _ready()->void:
	rng.seed=hash("living_map|%d" % int(GameState.world_seed))
	worker_mm=_figure_batch("Workers",MAX_WORKERS)
	event_mm=_figure_batch("Processions",MAX_EVENT_FIGURES)
	_build_smoke()
	_build_hearth()
	if CivilizationSystem.has_signal("scout_report_returned") and not CivilizationSystem.scout_report_returned.is_connected(_on_scout_returned):
		CivilizationSystem.scout_report_returned.connect(_on_scout_returned)
	day_tick()

func _exit_tree()->void:
	if CivilizationSystem.has_signal("scout_report_returned") and CivilizationSystem.scout_report_returned.is_connected(_on_scout_returned):
		CivilizationSystem.scout_report_returned.disconnect(_on_scout_returned)

func day_tick()->void:
	if terrain==null or not is_instance_valid(terrain): return
	var began:=Time.get_ticks_usec()
	_day()
	day_usec=lerpf(day_usec,float(Time.get_ticks_usec()-began),0.05) if day_usec>0.0 else float(Time.get_ticks_usec()-began)

func _day()->void:
	set_season(GameState.elapsed_days)
	var marker:Node3D=terrain.get("settler_marker")
	var now_settled:=GameState.settlement_site_committed and GameState.settlement_founded_at!=Vector3.ZERO
	var next_anchor:Vector3=GameState.settlement_founded_at if now_settled else (marker.position if marker else Vector3.ZERO)
	if next_anchor.distance_to(anchor)>0.0005 or now_settled!=settled:
		var step:=Vector2(next_anchor.x-anchor.x,next_anchor.z-anchor.z)
		if not now_settled and anchor!=Vector3.ZERO and step.length()>0.001: travel_heading=step.normalized()
		anchor=next_anchor
		settled=now_settled
		position=anchor
		site_signature=""
		relocated=true
		height_cache.clear()
		for worker in workers: worker.erase("slot")
	# On the march nobody goes out to work: the column needs no work sites.
	if not settled and bool(terrain.get("travel_active")):
		_refresh_workers()
		_watch_hearth_tally()
		return
	_refresh_site()
	_refresh_workers()
	_refresh_smoke()
	_watch_hearth_tally()

func set_season(day:float)->void:
	## Tell the shared terrain/vegetation seasonal shader whether the year is
	## warming (spring) or cooling (autumn); season_wave() already gives the
	## warmth. Same calendar, same hemisphere convention.
	if terrain==null: return
	var list:Variant=terrain.get("seasonal_materials")
	if not list is Array: return
	var turn:=cos(fmod(day,365.0)/365.0*TAU)
	for reference in list:
		var material:=(reference as WeakRef).get_ref() as ShaderMaterial if reference is WeakRef else null
		if material:
			material.set_shader_parameter("season_turn",turn)
			material.set_shader_parameter("season_contrast",1.0)

# --------------------------------------------------------------------------
# Where people go
# --------------------------------------------------------------------------

func _refresh_site()->void:
	# Work sites follow the town as it grows, re-read at most twice a month.
	var signature:="%s|%d|%d|%s" % [anchor,floori(GameState.elapsed_days/15.0),GameState.settlement_plots.size(),settled]
	if signature==site_signature: return
	site_signature=signature
	homes.clear(); chimneys.clear(); spots.clear()
	var builds:Array[Vector2]=[]
	var workshops:Array[Vector2]=[]
	var stores:Array[Vector2]=[]
	var fields:Array[Vector2]=[]
	if settled:
		# Nearest plots first: a large city keeps its figures in the old heart.
		var ordered:Array[Dictionary]=[]
		for plot:Dictionary in GameState.settlement_plots:
			if _v2(plot.get("centroid",Vector2.ZERO)).length()<=0.45: ordered.append(plot)
		ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return _v2(a.get("centroid",Vector2.ZERO)).length_squared()<_v2(b.get("centroid",Vector2.ZERO)).length_squared())
		for plot:Dictionary in ordered.slice(0,160):
			var at:=_v2(plot.get("centroid",Vector2.ZERO))
			if at.length()>0.45: continue
			var status:=String(plot.get("status","active"))
			var use:=String(plot.get("land_use",""))
			if status in ["ruin","reclaimed"]: continue
			if status=="under_construction": builds.append(at); continue
			var sites:Array=plot.get("visual_building_sites",[]) if plot.get("visual_building_sites") is Array else []
			var door:=at
			if not sites.is_empty() and sites[0] is Dictionary: door=_v2((sites[0] as Dictionary).get("position",at))
			match use:
				"residential_compound","mixed_household","temporary_encampment":
					homes.append(door)
					if use=="mixed_household": workshops.append(door)
				"workshop": workshops.append(door)
				"storage": stores.append(door)
				"field": fields.append(at)
	if homes.is_empty():
		# The camp: shelters in a loose ring around the fire.
		for i in 7:
			var a:=float(i)*TAU/7.0+0.4
			homes.append(Vector2(cos(a),sin(a))*(0.014+0.004*float(i%3)))
	for i in mini(MAX_PLUMES-1,homes.size()): chimneys.append(homes[i])
	var center:=Vector2(anchor.x,anchor.z)
	var land_key:="%s" % anchor
	if land_key!=land_signature:
		# The land around a site does not move: sample it once per site.
		land_signature=land_key
		var woods:=_ring_spots(center,[0.07,0.12,0.18],"woodland",6)
		var open:=_ring_spots(center,[0.06,0.10,0.15],"open",6)
		land_spots={"gather":woods if not woods.is_empty() else open,"open":open}
		land_spots["haul"]=_ring_spots(center,[0.10,0.16,0.22],"woodland",4)
		if (land_spots.haul as Array).is_empty(): land_spots["haul"]=land_spots.gather
		land_spots["hunt"]=_ring_spots(center,[0.24,0.30],"open",4)
		land_spots["survey"]=_ring_spots(center,[0.32,0.38],"open",4)
		land_spots["watch"]=_ring_spots(center,[0.07,0.085],"open",6)
		land_spots["fish"]=_water_spots(center)
		if (land_spots.fish as Array).is_empty(): land_spots["fish"]=land_spots.gather
		burial=_burial_ground(center)
		_place_hearth()
	for key in land_spots: spots[key]=land_spots[key]
	spots["farm"]=fields if not fields.is_empty() else land_spots.open
	spots["build"]=builds if not builds.is_empty() else homes.slice(0,4)
	spots["craft"]=workshops if not workshops.is_empty() else homes.slice(0,3)
	spots["carry"]=stores if not stores.is_empty() else [Vector2(0.006,-0.004)]
	var ring:Array[Vector2]=[]
	for i in 6: ring.append(Vector2(cos(float(i)*TAU/6.0),sin(float(i)*TAU/6.0))*0.0045)
	spots["fire"]=ring
	spots["council"]=ring
	if relocated:
		# New ground: everyone sets out again from a home here.
		relocated=false
		for worker in workers:
			worker["home"]=homes[rng.randi_range(0,homes.size()-1)]
			worker.erase("pos")
			_start_leg(worker,0)

func _ring_spots(center:Vector2,radii:Array,want:String,count:int)->Array[Vector2]:
	var scored:Array[Dictionary]=[]
	var land:=terrain.has_method("_settlement_stage_land_at")
	var wood:=terrain.has_method("_woodland_density_at")
	for r in radii:
		for i in 12:
			var a:=float(i)*TAU/12.0+float(r)*7.0
			var local:=Vector2(cos(a),sin(a))*float(r)
			var world:=center+local
			if land and not bool(terrain.call("_settlement_stage_land_at",world)): continue
			var score:=rng.randf()*0.2
			if want=="woodland" and wood: score+=float(terrain.call("_woodland_density_at",world.x,world.y))
			scored.append({"at":local,"score":score})
	scored.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.score)>float(b.score))
	var result:Array[Vector2]=[]
	for entry in scored.slice(0,count): result.append(entry.at)
	return result

func _water_spots(center:Vector2)->Array[Vector2]:
	if not terrain.has_method("_surface_water_site_near"): return []
	var water:Vector3=terrain.call("_surface_water_site_near",Vector3(center.x,anchor.y,center.y))
	var local:=Vector2(water.x,water.z)-center
	if local.length()>0.6 or local.length()<0.001: return []
	# Stand on the bank, a few metres short of the water, a little apart.
	var toward:=local.normalized()
	var side:=Vector2(-toward.y,toward.x)
	var result:Array[Vector2]=[]
	for i in 3:
		var bank:=local-toward*0.008+side*(float(i)-1.0)*0.012
		if not terrain.has_method("_settlement_stage_land_at") or bool(terrain.call("_settlement_stage_land_at",center+bank)): result.append(bank)
	return result

func _burial_ground(center:Vector2)->Vector2:
	var base:=float(posmod(int(GameState.world_seed),628))/100.0
	for i in 8:
		var a:=base+float(i)*TAU/8.0
		var local:=Vector2(cos(a),sin(a))*0.065
		if not terrain.has_method("_settlement_stage_land_at") or bool(terrain.call("_settlement_stage_land_at",center+local)): return local
	return Vector2(0.065,0)

# --------------------------------------------------------------------------
# Workers: a bounded, labour-true crowd
# --------------------------------------------------------------------------

static func figure_budget(population:int)->int:
	if population<=0: return 0
	# More people, a few more figures: 60 -> 17, 120 -> 24, 480+ -> 40.
	return clampi(roundi(24.0*sqrt(float(population)/120.0)),mini(population,8),MAX_WORKERS)

static func activity_shares()->Dictionary:
	## Real labour, as worker counts per visible activity. Food workers are
	## split by what today's food actually came from.
	var shares:Dictionary={}
	var alloc:Dictionary=GameState.population_allocations
	var food_workers:=maxf(0.0,float(alloc.get("Food",0)))
	var sources:Array=GameState.simulation_metrics.get("food_sources",[]) if GameState.simulation_metrics.get("food_sources") is Array else []
	var produced:=0.0
	for source in sources:
		if source is Dictionary and FOOD_ACTIVITY.has(String(source.get("name",""))): produced+=maxf(0.0,float(source.get("produced",0.0)))
	if produced>0.0:
		for source in sources:
			if not source is Dictionary or not FOOD_ACTIVITY.has(String(source.get("name",""))): continue
			var activity:=String(FOOD_ACTIVITY[String(source.name)])
			shares[activity]=float(shares.get(activity,0.0))+food_workers*maxf(0.0,float(source.get("produced",0.0)))/produced
	elif food_workers>0.0:
		shares["gather"]=food_workers
	for role in ROLE_ACTIVITY:
		var count:=maxf(0.0,float(alloc.get(role,0)))
		if count>0.0: shares[ROLE_ACTIVITY[role]]=float(shares.get(ROLE_ACTIVITY[role],0.0))+count
	return shares

static func allocate(shares:Dictionary,budget:int)->Dictionary:
	## Largest remainder: the visible mix matches the real mix to within one figure.
	var total:=0.0
	for key in shares: total+=float(shares[key])
	var result:Dictionary={}
	if total<=0.0 or budget<=0: return result
	var assigned:=0
	var remainders:Array[Dictionary]=[]
	for key in shares:
		var exact:=float(budget)*float(shares[key])/total
		result[key]=floori(exact); assigned+=int(result[key])
		remainders.append({"key":key,"r":exact-floorf(exact)})
	remainders.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.r)>float(b.r) if not is_equal_approx(float(a.r),float(b.r)) else String(a.key)<String(b.key))
	for i in budget-assigned: result[remainders[i%remainders.size()].key]=int(result[remainders[i%remainders.size()].key])+1
	return result

func _refresh_workers()->void:
	var shares:=activity_shares()
	var budget:=figure_budget(GameState.population_total)
	var counts:=allocate(shares,budget)
	var signature:="%s|%d" % [JSON.stringify(counts),int(settled)]
	last_report={"population":GameState.population_total,"budget":budget,"figures":counts,"labor":shares}
	if signature==labor_signature: return
	labor_signature=signature
	var wanted:Array[String]=[]
	var keys:=counts.keys()
	keys.sort()
	for key in keys:
		for i in int(counts[key]): wanted.append(String(key))
	# Keep people already doing a wanted job; retrain the rest.
	var kept:Array[Dictionary]=[]
	var pool:=wanted.duplicate()
	for worker in workers:
		if String(worker.act) in pool:
			pool.erase(String(worker.act)); kept.append(worker)
	for act in pool:
		var worker:={"act":act,"phase":rng.randf(),"cloth":rng.randi_range(0,CLOTH.size()-1),"home":homes[rng.randi_range(0,homes.size()-1)] if not homes.is_empty() else Vector2.ZERO}
		kept.append(worker)
		_start_leg(worker,3,rng.randf_range(0.0,6.0))
	workers=kept
	worker_mm.multimesh.visible_instance_count=workers.size()
	for i in workers.size(): worker_mm.multimesh.set_instance_color(i,CLOTH[int(workers[i].cloth)])

func _pick(act:String)->Vector2:
	var list:Array=spots.get(act,[])
	if list.is_empty(): return Vector2.ZERO
	return _v2(list[rng.randi_range(0,list.size()-1)])+Vector2(rng.randf_range(-1,1),rng.randf_range(-1,1))*0.004

func _start_leg(worker:Dictionary,stage:int,duration:float=-1.0)->void:
	## stage 0 walk out, 1 work, 2 walk home (often loaded), 3 rest at home.
	var act:=String(worker.act)
	var at:Vector2=worker.get("pos",worker.home)
	worker["stage"]=stage
	worker["t"]=0.0
	worker["carry"]=false
	match stage:
		0:
			var spot:=_pick(act)
			worker["spot"]=spot
			_set_path(worker,at,spot)
			worker["pose"]=POSES.walk
		1:
			worker["from"]=at; worker["to"]=at
			worker["dur"]=duration if duration>=0.0 else rng.randf_range(5.0,11.0)
			worker["pose"]=_work_pose(act)
			if act in ["fire","council"]: worker["dur"]=rng.randf_range(9.0,18.0)
			if act=="watch": worker["dur"]=rng.randf_range(6.0,10.0)
		2:
			var home:Vector2=worker.home
			if act=="carry": home=_pick("build") if rng.randf()<0.5 else worker.home
			if act in ["watch","fire","council"]: home=_pick(act)
			_set_path(worker,at,home)
			worker["pose"]=POSES.walk
			worker["carry"]=act in ["gather","haul","hunt","fish","farm","carry","survey"]
		_:
			worker["from"]=at; worker["to"]=at
			worker["dur"]=duration if duration>=0.0 else rng.randf_range(1.5,4.0)
			worker["pose"]=POSES.talk
	worker["h0"]=_local_height(worker.from)
	worker["h1"]=_local_height(worker.to)
	worker["hm"]=_local_height((worker.from+worker.to)*0.5)

func _work_pose(act:String)->int:
	match act:
		"gather","farm": return POSES.gather
		"haul","build": return POSES.chop
		"fish": return POSES.fish
		"fire": return POSES.fire
		"council","carry","survey","hunt": return POSES.talk
		"watch": return POSES.watch
		"craft": return POSES.craft
	return POSES.talk

func _set_path(worker:Dictionary,from:Vector2,to:Vector2)->void:
	worker["from"]=from; worker["to"]=to
	worker["dur"]=maxf(0.6,from.distance_to(to)/(WALK_MPS*UNIT*_pace()))

func _local_height(local:Vector2)->float:
	## Ground height under a figure, relative to the anchor. The rendered-surface
	## sample costs a few hundred microseconds, so corners of a 3 m lattice are
	## sampled once per site and interpolated: people walk the same paths daily.
	var cell:=local/HEIGHT_CELL
	var base:=Vector2i(floori(cell.x),floori(cell.y))
	var f:=cell-Vector2(base)
	var a:=_corner_height(base)
	var b:=_corner_height(base+Vector2i(1,0))
	var c:=_corner_height(base+Vector2i(0,1))
	var d:=_corner_height(base+Vector2i(1,1))
	return lerpf(lerpf(a,b,f.x),lerpf(c,d,f.x),f.y)+0.00012

func _corner_height(corner:Vector2i)->float:
	if height_cache.has(corner): return float(height_cache[corner])
	if height_cache.size()>=HEIGHT_CACHE_MAX: height_cache.clear()
	var world:=Vector2(anchor.x,anchor.z)+Vector2(corner)*HEIGHT_CELL
	var h:=anchor.y
	if terrain.has_method("_harvest_ground_height_at"): h=float(terrain.call("_harvest_ground_height_at",world))
	elif terrain.has_method("_height_at"): h=float(terrain.call("_height_at",world.x,world.y))
	height_cache[corner]=h-anchor.y
	return h-anchor.y

func _pace()->float:
	if terrain==null: return 1.0
	var hours:=float(terrain.call("_speed_hours_per_second")) if terrain.has_method("_speed_hours_per_second") else 12.0
	return clampf(sqrt(maxf(hours/24.0,0.01))*1.3,0.55,2.3)

func _paused()->bool:
	return terrain==null or float(terrain.get("game_speed"))<=0.0

func _advance_worker(worker:Dictionary,delta:float)->void:
	worker["t"]=float(worker.t)+delta
	var dur:=float(worker.dur)
	if float(worker.t)<dur: return
	var at:Vector2=worker.to
	worker["pos"]=at
	match int(worker.stage):
		0: _start_leg(worker,1)
		1: _start_leg(worker,2)
		2: _start_leg(worker,3)
		_: _start_leg(worker,0)

func _worker_transform(worker:Dictionary,traveling:bool)->Transform3D:
	var from:Vector2=worker.from
	var to:Vector2=worker.to
	var k:=clampf(float(worker.t)/maxf(0.001,float(worker.dur)),0.0,1.0)
	var at:=from.lerp(to,k)
	# Quadratic through the mid-path sample: feet follow a rise or a dip.
	var h0:=float(worker.h0); var h1:=float(worker.h1); var hm:=float(worker.hm)
	var h:=h0*(1.0-k)*(1.0-2.0*k)+hm*4.0*k*(1.0-k)+h1*k*(2.0*k-1.0)
	var facing:=(to-from)
	if facing.length()<0.0001:
		facing=Vector2(-at.x,-at.y) if at.length()>0.001 else Vector2(0,1)
		if int(worker.pose)==POSES.fish or int(worker.pose)==POSES.watch: facing=-facing
	if traveling:
		# On the march: a loose column beside the wagons, all facing the road.
		var slot:=int(worker.get("slot",0))
		at=Vector2(float(slot%3)-1.0,floorf(float(slot)/3.0)-3.0)*0.0042
		at=Vector2(at.x*travel_heading.y+at.y*travel_heading.x,-at.x*travel_heading.x+at.y*travel_heading.y)
		at+=Vector2(sin(_clock*0.3+float(slot)),cos(_clock*0.23+float(slot)*1.7))*0.0006
		h=float(worker.get("march_h",0.0))
		facing=travel_heading
	var basis:=Basis.looking_at(Vector3(facing.x,0,facing.y).normalized(),Vector3.UP).scaled(Vector3.ONE*UNIT*FIGURE_SCALE)
	return Transform3D(basis,Vector3(at.x,h,at.y))

func _process(delta:float)->void:
	if terrain==null or not is_instance_valid(terrain): return
	var began:=Time.get_ticks_usec()
	_frame(delta)
	# A running cost measure for probes (exponential average, microseconds).
	frame_usec=lerpf(frame_usec,float(Time.get_ticks_usec()-began),0.05)

func _frame(delta:float)->void:
	var paused:=_paused()
	tick_clock(0.0 if paused else delta)
	# Newly streamed terrain and vegetation must match the season at once.
	var seasonal:Variant=terrain.get("seasonal_materials")
	if seasonal is Array and (seasonal as Array).size()!=seasonal_count:
		seasonal_count=(seasonal as Array).size()
		set_season(GameState.elapsed_days)
	var camera:Camera3D=terrain.get("camera")
	var size:=camera.size if camera else 999.0
	var near:=camera!=null and Vector2(camera.position.x-anchor.x,camera.position.z-anchor.z).length()<maxf(3.0,size*3.0)
	figures_visible=size<=FIGURE_MAX_VIEW and near
	worker_mm.visible=figures_visible
	event_mm.visible=figures_visible and not events.is_empty()
	smoke_mm.visible=size<=SMOKE_MAX_VIEW and near
	# From 10,000 ft a real 35 m plume is a few pixels; let it swell (bounded).
	var legible:=clampf(size/0.55,1.0,2.6)
	if absf(legible-smoke_legibility)>0.02:
		smoke_legibility=legible
		smoke_material().set_shader_parameter("legibility",legible)
	var traveling:=not settled and bool(terrain.get("travel_active"))
	# The camp fire burns whenever the people stop, and at the settled hearth.
	hearth_root.visible=size<=SMOKE_MAX_VIEW and near and not traveling
	smoke_mm.visible=smoke_mm.visible and not traveling
	if not paused:
		for worker in workers:
			if not traveling: _advance_worker(worker,delta)
		_advance_events(delta)
		_advance_flares(delta)
		if flame and hearth_root.visible:
			flame.scale=Vector3(1.0,1.0+0.14*sin(_clock*9.0)+0.07*sin(_clock*23.0),1.0)
	# Paused, people hold still where they stand (the clock is stopped); they
	# are still placed every visible frame, which costs a few microseconds.
	if not figures_visible: return
	var pace:=_pace()
	var mm:=worker_mm.multimesh
	for i in workers.size():
		var worker:Dictionary=workers[i]
		if traveling and not worker.has("slot"):
			worker["slot"]=i; worker["march_h"]=_local_height(Vector2.ZERO)
		elif not traveling and worker.has("slot"):
			worker.erase("slot")
		mm.set_instance_transform(i,_worker_transform(worker,traveling))
		var pose:=POSES.walk if traveling else int(worker.pose)
		var moving:=pose==POSES.walk
		mm.set_instance_custom_data(i,Color(float(worker.phase),float(pose),1.0 if bool(worker.carry) or traveling else 0.0,pace*(1.0 if moving else 0.8)))
	_draw_events()

# --------------------------------------------------------------------------
# Hearth, firelight and smoke
# --------------------------------------------------------------------------

func _build_hearth()->void:
	hearth_root=Node3D.new(); hearth_root.name="Hearth"; add_child(hearth_root)
	var stone:=SphereMesh.new(); stone.radius=0.32*UNIT; stone.height=0.42*UNIT; stone.radial_segments=6; stone.rings=3
	var stone_material:=StandardMaterial3D.new(); stone_material.albedo_color=Color(0.40,0.38,0.35); stone_material.roughness=0.95
	for i in 9:
		var a:=float(i)*TAU/9.0
		_mesh(hearth_root,stone,stone_material,Vector3(cos(a),0.12,sin(a))*1.5*UNIT)
	flame=Node3D.new(); flame.name="Flame"; hearth_root.add_child(flame)
	var outer:=CylinderMesh.new(); outer.top_radius=0.0; outer.bottom_radius=0.95*UNIT; outer.height=2.6*UNIT; outer.radial_segments=7
	var core:=CylinderMesh.new(); core.top_radius=0.0; core.bottom_radius=0.5*UNIT; core.height=1.7*UNIT; core.radial_segments=6
	_mesh(flame,outer,_emissive(Color(1.0,0.52,0.14),2.6),Vector3(0,1.3*UNIT,0))
	_mesh(flame,core,_emissive(Color(1.0,0.84,0.42),3.4),Vector3(0,0.85*UNIT,0),0.5)
	var disc:=PlaneMesh.new(); disc.size=Vector2(14.0,14.0)*UNIT
	glow=_mesh(hearth_root,disc,glow_material(),Vector3(0,0.35*UNIT,0))
	hearth_root.visible=false

func _place_hearth()->void:
	if hearth_root==null: return
	hearth_root.position=Vector3(0,_local_height(Vector2.ZERO)-0.00012,0)

func _emissive(color:Color,energy:float)->StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=color; m.emission_enabled=true; m.emission=color; m.emission_energy_multiplier=energy
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _mesh(parent:Node3D,mesh:Mesh,material:Material,at:Vector3,yaw:float=0.0)->MeshInstance3D:
	var node:=MeshInstance3D.new(); node.mesh=mesh; node.material_override=material
	node.position=at; node.rotation.y=yaw
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node

func _build_smoke()->void:
	var quad:=QuadMesh.new(); quad.size=Vector2.ONE
	var multimesh:=MultiMesh.new()
	multimesh.transform_format=MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data=true
	multimesh.mesh=quad
	multimesh.instance_count=MAX_PLUMES*PUFFS_PER_PLUME
	multimesh.visible_instance_count=0
	smoke_mm=MultiMeshInstance3D.new(); smoke_mm.name="HearthSmoke"
	smoke_mm.multimesh=multimesh; smoke_mm.material_override=smoke_material()
	smoke_mm.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Puffs rise ~35 m and drift; keep them from being culled at the edge.
	smoke_mm.custom_aabb=AABB(Vector3(-0.6,-0.1,-0.6),Vector3(1.2,0.3,1.2))
	add_child(smoke_mm)

static func plume_count(population:int)->int:
	## The central hearth, and one more smoking home per ~30 people (bounded).
	if population<=0: return 0
	return clampi(1+floori(float(population)/30.0),1,MAX_PLUMES)

func _refresh_smoke()->void:
	var plumes:=plume_count(GameState.population_total)
	var sources:Array[Vector2]=[Vector2.ZERO]
	for chimney in chimneys:
		if sources.size()>=plumes: break
		sources.append(chimney)
	var winter:=clampf(-PlanetEnvironment.season_wave({"position":Vector2(anchor.x,anchor.z)},GameState.elapsed_days),0.0,1.0)
	var signature:="%s|%s|%d" % [anchor,sources,roundi(winter*8.0)]
	last_report["plumes"]=sources.size()
	if signature==smoke_signature: return
	smoke_signature=signature
	var mm:=smoke_mm.multimesh
	var index:=0
	for p in sources.size():
		var base:=sources[p]
		var h:=_local_height(base)+(0.0012 if p==0 else 0.0035)
		for k in PUFFS_PER_PLUME:
			mm.set_instance_transform(index,Transform3D(Basis.IDENTITY,Vector3(base.x,h,base.y)))
			# x: age offset, y: strength (home fires burn harder in winter), z: jitter
			mm.set_instance_custom_data(index,Color(float(k)/float(PUFFS_PER_PLUME)+float(p)*0.137,(1.0 if p==0 else 0.55)+winter*0.35,rng.randf(),0))
			index+=1
	mm.visible_instance_count=index

# --------------------------------------------------------------------------
# Marks of the day: births, deaths, scouts home
# --------------------------------------------------------------------------

func _watch_hearth_tally()->void:
	## HearthCount keeps the season's births and burials; a new season's tally
	## starts at zero, so the tally's start day tells the two apart.
	var season:Dictionary=GameState.hearth_season
	var start:=int(season.get("start_day",-1))
	var born:=int(season.get("born",0))
	var buried:=int(season.get("buried",0))
	if tally_start<0 and last_born<0:
		tally_start=start; last_born=born; last_buried=buried
		return
	var new_born:=born-(last_born if start==tally_start else 0)
	var new_buried:=buried-(last_buried if start==tally_start else 0)
	tally_start=start; last_born=born; last_buried=buried
	if not settled: return
	for i in mini(maxi(0,new_born),2): _flare(homes[rng.randi_range(0,homes.size()-1)] if not homes.is_empty() else Vector2.ZERO)
	if new_buried>0: _procession(new_buried)

func _flare(at:Vector2)->void:
	## A birth: a small warm light over a home, rising and fading.
	if flares.size()>=MAX_FLARES:
		var oldest:Dictionary=flares.pop_front()
		(oldest.node as Node).queue_free()
	var quad:=QuadMesh.new(); quad.size=Vector2.ONE
	var node:=MeshInstance3D.new(); node.name="BirthFlare"; node.mesh=quad
	node.material_override=flare_material()
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.position=Vector3(at.x,_local_height(at)+0.004,at.y)
	node.set_instance_shader_parameter("age",0.0)
	add_child(node)
	flares.append({"node":node,"t":0.0,"dur":6.0})

func _advance_flares(delta:float)->void:
	for flare in flares.duplicate():
		flare["t"]=float(flare.t)+delta
		var node:=flare.node as MeshInstance3D
		var k:=float(flare.t)/float(flare.dur)
		if k>=1.0:
			node.queue_free(); flares.erase(flare); continue
		node.set_instance_shader_parameter("age",k)
		node.position.y+=delta*0.0018

func _procession(dead:int)->void:
	## A death: mourners carry the dead from a home to the burial ground,
	## stand a while, and go home.
	if _count_events("procession")>=MAX_PROCESSIONS: return
	var from:=homes[rng.randi_range(0,homes.size()-1)] if not homes.is_empty() else Vector2.ZERO
	var mourners:=clampi(4+dead,5,7)
	_add_group("procession",mourners,[from,from.lerp(burial,0.5)+Vector2(0.006,-0.004),burial],POSES.mourn,0.45,6.0,true)

func _on_scout_returned(report:Dictionary)->void:
	## Returning scouts are seen on the last stretch of their road home.
	if not settled or _count_events("party")>=MAX_PARTIES: return
	var walkers:=clampi(int(report.get("personnel",3))-int(report.get("lost_personnel",0)),1,6)
	var heading:=Vector2(1,0).rotated(rng.randf()*TAU)
	var route:Array=report.get("return_route",[]) if report.get("return_route") is Array else []
	if route.is_empty() and report.get("route") is Array: route=report.route
	if route.size()>=2:
		var near_home:=_v2(route[route.size()-2]) if not (report.get("return_route",[]) as Array).is_empty() else _v2(route[1])
		var away:=near_home-Vector2(anchor.x,anchor.z)
		if away.length()>0.001: heading=away.normalized()
	var start:=heading*0.34
	var path:Array[Vector2]=[start,start*0.5+Vector2(-heading.y,heading.x)*0.02,Vector2(0.004,0.003)]
	_add_group("party",walkers,path,POSES.walk,1.0,4.0,false,true)
	last_report["last_party"]={"walkers":walkers,"day":int(report.get("day",GameState.elapsed_days))}

func _count_events(kind:String)->int:
	var groups:Dictionary={}
	for walker in events:
		if String(walker.kind)==kind: groups[int(walker.group)]=true
	return groups.size()

func _add_group(kind:String,count:int,path:Array[Vector2],pose:int,pace:float,linger:float,bier:bool,carry:bool=false)->void:
	var group:=rng.randi()
	for i in count:
		if events.size()>=MAX_EVENT_FIGURES: break
		var offset:=Vector2(float(i%2)-0.5,-floorf(float(i)/2.0))*0.0022
		var points:Array[Vector2]=[]
		var heights:PackedFloat32Array=[]
		for point in path:
			points.append(point)
			heights.append(_local_height(point))
		events.append({"kind":kind,"group":group,"points":points,"heights":heights,"offset":offset,"t":-float(i)*0.25,"pace":pace,"pose":pose,"linger":linger,"carry":carry or (bier and i<2),"phase":rng.randf(),"cloth":0 if kind=="procession" else rng.randi_range(0,CLOTH.size()-1)})
	event_mm.multimesh.visible_instance_count=events.size()

func _event_length(walker:Dictionary)->float:
	var points:Array[Vector2]=walker.points
	var total:=0.0
	for i in points.size()-1: total+=points[i].distance_to(points[i+1])
	return total

func _advance_events(delta:float)->void:
	if events.is_empty(): return
	var done:Array[Dictionary]=[]
	for walker in events:
		walker["t"]=float(walker.t)+delta
		var walk_time:=_event_length(walker)/(WALK_MPS*UNIT*float(walker.pace)*_pace())
		if float(walker.t)>walk_time+float(walker.linger): done.append(walker)
	for walker in done: events.erase(walker)
	event_mm.multimesh.visible_instance_count=events.size()

func _draw_events()->void:
	var mm:=event_mm.multimesh
	var pace:=_pace()
	for i in events.size():
		var walker:Dictionary=events[i]
		var points:Array[Vector2]=walker.points
		var heights:PackedFloat32Array=walker.heights
		var distance:=maxf(0.0,float(walker.t))*WALK_MPS*UNIT*float(walker.pace)*pace
		var at:=points[0]
		var h:=heights[0]
		var facing:=points[1]-points[0]
		var arrived:=true
		for s in points.size()-1:
			var length:=points[s].distance_to(points[s+1])
			if distance<=length:
				var k:=distance/maxf(length,0.00001)
				at=points[s].lerp(points[s+1],k); h=lerpf(heights[s],heights[s+1],k)
				facing=points[s+1]-points[s]; arrived=false
				break
			distance-=length
		if arrived:
			at=points[-1]; h=heights[-1]
		var side:=Vector2(-facing.y,facing.x).normalized() if facing.length()>0.00001 else Vector2(1,0)
		var ahead:=facing.normalized() if facing.length()>0.00001 else Vector2(0,1)
		var offset:Vector2=walker.offset
		at+=side*offset.x+ahead*offset.y
		var basis:=Basis.looking_at(Vector3(ahead.x,0,ahead.y),Vector3.UP).scaled(Vector3.ONE*UNIT*FIGURE_SCALE)
		mm.set_instance_transform(i,Transform3D(basis,Vector3(at.x,h,at.y)))
		var pose:=int(walker.pose)
		if arrived: pose=POSES.talk if String(walker.kind)=="party" else POSES.mourn+100
		mm.set_instance_custom_data(i,Color(float(walker.phase),float(pose),1.0 if bool(walker.carry) and not arrived else 0.0,pace*float(walker.pace)))
		mm.set_instance_color(i,Color(0.24,0.22,0.21) if String(walker.kind)=="procession" else CLOTH[int(walker.cloth)])

# --------------------------------------------------------------------------
# Probe / test surface
# --------------------------------------------------------------------------

func activity_report()->Dictionary:
	## Visible people against real labour, for probes and tests.
	var report:=last_report.duplicate(true)
	var visible:Dictionary={}
	var moving:=0
	for worker in workers:
		visible[String(worker.act)]=int(visible.get(String(worker.act),0))+1
		if int(worker.pose)!=POSES.talk: moving+=1
	report["visible"]=visible
	report["workers"]=workers.size()
	report["animated"]=moving
	report["event_walkers"]=events.size()
	report["flares"]=flares.size()
	report["figures_drawn"]=figures_visible
	report["frame_usec"]=snappedf(frame_usec,0.1)
	report["day_usec"]=snappedf(day_usec,0.1)
	var labor:Dictionary=report.get("labor",{})
	var total:=0.0
	for key in labor: total+=float(labor[key])
	var worst:=0.0
	if total>0.0 and workers.size()>0:
		for key in labor:
			worst=maxf(worst,absf(float(visible.get(key,0))/float(workers.size())-float(labor[key])/total))
	report["max_share_error"]=worst
	return report

static func _v2(value:Variant)->Vector2:
	if value is Vector2: return value
	if value is Vector3: return Vector2((value as Vector3).x,(value as Vector3).z)
	if value is Dictionary: return Vector2(float((value as Dictionary).get("x",0.0)),float((value as Dictionary).get("z",(value as Dictionary).get("y",0.0))))
	return Vector2.ZERO

# --------------------------------------------------------------------------
# Shared procedural figure (also used by rite_marks.gd)
# --------------------------------------------------------------------------

func _figure_batch(label:String,count:int)->MultiMeshInstance3D:
	var multimesh:=MultiMesh.new()
	multimesh.transform_format=MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data=true
	multimesh.use_colors=true
	multimesh.mesh=figure_mesh()
	multimesh.instance_count=count
	multimesh.visible_instance_count=0
	var node:=MultiMeshInstance3D.new(); node.name=label
	node.multimesh=multimesh; node.material_override=figure_material()
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.custom_aabb=AABB(Vector3(-0.6,-0.1,-0.6),Vector3(1.2,0.2,1.2))
	add_child(node)
	return node

static func figure_mesh()->ArrayMesh:
	## A low-poly person in metres, feet at the origin, facing -Z. UV.x names
	## the part the shader moves: 0 body, 1/2 legs, 3/4 arms, 5 load, 6 tool.
	## UV.y picks the colour; cloth takes the figure's instance colour.
	if _figure_mesh: return _figure_mesh
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# UV.y picks the colour: 0 cloth (the figure's own colour), 1 skin,
	# 2 hair and leggings, 3 a carried bundle, 4 wood.
	_box(st,Vector3(0,1.17,0),Vector3(0.36,0.56,0.22),0,0,0.78)     # tunic
	_box(st,Vector3(0,0.93,0),Vector3(0.40,0.12,0.25),0,0,1.0)      # hem
	_box(st,Vector3(0,1.58,0),Vector3(0.20,0.24,0.21),1,0)            # head
	_box(st,Vector3(0,1.71,0.01),Vector3(0.22,0.07,0.23),2,0)         # hair
	_box(st,Vector3(-0.10,0.45,0),Vector3(0.13,0.90,0.14),2,1)        # legs
	_box(st,Vector3(0.10,0.45,0),Vector3(0.13,0.90,0.14),2,2)
	_box(st,Vector3(-0.25,1.14,0),Vector3(0.10,0.56,0.11),0,3,0.85)  # arms
	_box(st,Vector3(0.25,1.14,0),Vector3(0.10,0.56,0.11),0,4,0.85)
	_box(st,Vector3(-0.25,0.83,0),Vector3(0.09,0.09,0.09),1,3)        # hands
	_box(st,Vector3(0.25,0.83,0),Vector3(0.09,0.09,0.09),1,4)
	_box(st,Vector3(0,1.30,0.22),Vector3(0.44,0.40,0.28),3,5)         # bundle
	_box(st,Vector3(0,0.5,0),Vector3(0.035,1.0,0.035),4,6)            # tool: unit length along +Y
	st.generate_normals()
	_figure_mesh=st.commit()
	return _figure_mesh

static func _box(st:SurfaceTool,center:Vector3,size:Vector3,colour:int,part:int,taper:float=1.0)->void:
	var h:=size*0.5
	var top:=Vector2(h.x*taper,h.z*taper)
	var c:=[Vector3(-h.x,-h.y,-h.z),Vector3(h.x,-h.y,-h.z),Vector3(h.x,-h.y,h.z),Vector3(-h.x,-h.y,h.z),
		Vector3(-top.x,h.y,-top.y),Vector3(top.x,h.y,-top.y),Vector3(top.x,h.y,top.y),Vector3(-top.x,h.y,top.y)]
	var faces:=[[0,1,2,3],[7,6,5,4],[0,4,5,1],[1,5,6,2],[2,6,7,3],[3,7,4,0]]
	for face in faces:
		for index in [0,2,1,0,3,2]:
			st.set_uv(Vector2(float(part),float(colour)))
			st.add_vertex(center+(c[face[index]] as Vector3))

static func figure_material()->ShaderMaterial:
	if _figure_material: return _figure_material
	var shader:=Shader.new()
	shader.code=FIGURE_SHADER
	_figure_material=ShaderMaterial.new(); _figure_material.shader=shader
	_figure_material.set_shader_parameter("anim_clock",_clock)
	return _figure_material

static func smoke_material()->ShaderMaterial:
	if _smoke_material: return _smoke_material
	var shader:=Shader.new(); shader.code=SMOKE_SHADER
	_smoke_material=ShaderMaterial.new(); _smoke_material.shader=shader
	return _smoke_material

static func glow_material()->ShaderMaterial:
	if _glow_material: return _glow_material
	var shader:=Shader.new(); shader.code=GLOW_SHADER
	_glow_material=ShaderMaterial.new(); _glow_material.shader=shader
	return _glow_material

static func flare_material()->ShaderMaterial:
	if _flare_material: return _flare_material
	var shader:=Shader.new(); shader.code=FLARE_SHADER
	_flare_material=ShaderMaterial.new(); _flare_material.shader=shader
	return _flare_material

const FIGURE_SHADER:="""
shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform float anim_clock = 0.0;
varying vec3 v_color;

mat3 rot_x(float a) { float c = cos(a); float s = sin(a); return mat3(vec3(1.0,0.0,0.0), vec3(0.0,c,s), vec3(0.0,-s,c)); }

void vertex() {
	float part = floor(UV.x + 0.5);
	float code = INSTANCE_CUSTOM.y;
	float still = code > 99.5 ? 1.0 : 0.0;   // a mourner who has arrived stands bowed
	float pose = floor(mod(code, 100.0) + 0.5);
	float carry = INSTANCE_CUSTOM.z;
	float t = anim_clock * max(INSTANCE_CUSTOM.w, 0.2) + INSTANCE_CUSTOM.x * 6.2831;
	float leg = 0.0; float arm_l = 0.0; float arm_r = 0.0; float bend = 0.0;
	float lower = 0.0; float bob = 0.0; float tool_len = 0.0;
	vec3 tool_dir = vec3(0.0, 1.0, 0.0);
	if (pose < 0.5 || pose == 6.0) {
		float w = pose == 6.0 ? 0.55 : 1.0;
		float s = sin(t * 7.0) * (1.0 - still);
		leg = 0.55 * w * s; arm_l = -0.45 * w * s; arm_r = -arm_l;
		bob = 0.035 * abs(cos(t * 7.0)) * (1.0 - still);
		if (pose == 6.0) { bend = -0.30 - 0.15 * still; arm_l = 0.25 + 0.2 * still; arm_r = 0.25 + 0.2 * still; }
		if (carry > 0.5) { arm_l = 0.95; arm_r = 0.95; }
	} else if (pose == 1.0) {
		bend = -0.95 + 0.12 * sin(t * 1.7);
		arm_l = 1.15 + 0.35 * sin(t * 3.1); arm_r = 1.0 + 0.35 * sin(t * 3.1 + 1.9);
	} else if (pose == 2.0) {
		float s = sin(t * 5.0);
		bend = -0.22; arm_r = 1.5 + 1.3 * max(s, -0.4); arm_l = 1.2 + 0.9 * max(s, -0.4); tool_len = 0.7;
	} else if (pose == 3.0) {
		bend = -0.06; arm_l = 1.0; arm_r = 1.1 + 0.06 * sin(t * 1.3); tool_len = 2.8;
		tool_dir = normalize(vec3(0.0, 0.55, -0.85));
	} else if (pose == 4.0) {
		lower = 0.26; leg = -0.8; bend = -0.30; arm_l = 1.0 + 0.25 * sin(t * 1.1); arm_r = 0.9 + 0.25 * sin(t * 1.4 + 1.0);
	} else if (pose == 5.0) {
		arm_r = 0.4 + 0.6 * max(0.0, sin(t * 1.3)); bend = 0.03 * sin(t * 0.7);
	} else if (pose == 7.0) {
		arm_r = 0.35; tool_len = 2.1; tool_dir = vec3(0.0, 1.0, 0.0);
	} else {
		lower = 0.26; leg = -0.8; bend = -0.45; arm_r = 1.2 + 0.7 * max(sin(t * 6.0), -0.3); arm_l = 1.0; tool_len = 0.35;
	}
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	vec3 hip = vec3(0.0, 0.88, 0.0);
	if (part == 1.0 || part == 2.0) {
		float a = (pose == 4.0 || pose == 8.0) ? leg : (part == 1.0 ? leg : -leg);
		mat3 r = rot_x(a); v = r * (v - hip) + hip; n = r * n;
	}
	if (part == 3.0 || part == 4.0 || part == 6.0) {
		vec3 shoulder = vec3(part == 3.0 ? -0.25 : 0.25, 1.40, 0.0);
		mat3 r = rot_x(part == 3.0 ? arm_l : arm_r);
		if (part == 6.0) {
			vec3 hand = r * (vec3(0.25, 0.83, 0.0) - shoulder) + shoulder;
			vec3 dir = pose == 2.0 || pose == 8.0 ? r * vec3(0.0, 0.0, -1.0) : tool_dir;
			v = hand + dir * (v.y * tool_len) + vec3(v.x, 0.0, v.z) * step(0.01, tool_len);
		} else {
			v = r * (v - shoulder) + shoulder; n = r * n;
		}
	}
	if (part == 5.0) { v = mix(vec3(0.0, 1.3, 0.12), v, step(0.5, carry)); }
	if (part != 1.0 && part != 2.0) {
		mat3 r = rot_x(bend); v = r * (v - hip) + hip; n = r * n;
	}
	v.y += bob - lower;
	VERTEX = v;
	NORMAL = normalize(n);
	float colour = floor(UV.y + 0.5);
	v_color = colour < 0.5 ? COLOR.rgb : (colour < 1.5 ? vec3(0.62, 0.46, 0.34) : (colour < 2.5 ? vec3(0.28, 0.23, 0.18) : (colour < 3.5 ? vec3(0.55, 0.45, 0.29) : vec3(0.36, 0.27, 0.18))));
}

void fragment() {
	ALBEDO = v_color;
	ROUGHNESS = 0.9;
}
"""

const SMOKE_SHADER:="""
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;
uniform float anim_clock = 0.0;
uniform float plume_height = 0.036;
uniform vec2 wind = vec2(0.010, 0.004);
uniform float legibility = 1.0;   // puffs swell a little when seen from far up
varying float v_alpha;
varying float v_age;
void vertex() {
	float strength = INSTANCE_CUSTOM.y;
	float rate = 0.075 + 0.02 * INSTANCE_CUSTOM.z;
	float age = fract(anim_clock * rate + INSTANCE_CUSTOM.x);
	vec3 offset = vec3(wind.x * age * age * strength, plume_height * age * (0.55 + 0.45 * strength), wind.y * age * age);
	offset.xz += vec2(sin(anim_clock * 0.7 + INSTANCE_CUSTOM.z * 6.0), cos(anim_clock * 0.5 + INSTANCE_CUSTOM.x * 9.0)) * 0.0012 * age;
	offset *= legibility;
	float size = (0.0022 + 0.0085 * age) * (0.65 + 0.5 * strength) * legibility;
	vec4 center = MODELVIEW_MATRIX * vec4(offset, 1.0);
	VERTEX = center.xyz + vec3(VERTEX.xy * size, 0.0);
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_alpha = smoothstep(0.0, 0.10, age) * (1.0 - smoothstep(0.45, 1.0, age)) * clamp(strength, 0.0, 1.2);
	v_age = age;
}
void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float soft = 1.0 - smoothstep(0.25, 1.0, d);
	ALBEDO = mix(vec3(0.42, 0.41, 0.40), vec3(0.80, 0.80, 0.78), v_age);
	ALPHA = soft * v_alpha * 0.55;
}
"""

const GLOW_SHADER:="""
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, fog_disabled;
uniform float anim_clock = 0.0;
void fragment() {
	// Firelight pooled on the ground around the hearth, flickering.
	float d = length(UV - vec2(0.5)) * 2.0;
	float flicker = 0.85 + 0.10 * sin(anim_clock * 11.0) + 0.05 * sin(anim_clock * 29.0);
	float fall = pow(clamp(1.0 - d, 0.0, 1.0), 3.0);
	ALBEDO = vec3(1.0, 0.50, 0.18) * fall * 0.38 * flicker;
}
"""

const FLARE_SHADER:="""
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;
uniform float anim_clock = 0.0;
instance uniform float age = 0.0;
varying float v_fade;
void vertex() {
	float size = 0.004 + 0.010 * sqrt(age);
	vec4 center = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	VERTEX = center.xyz + vec3(VERTEX.xy * size, 0.0);
	v_fade = smoothstep(0.0, 0.08, age) * (1.0 - smoothstep(0.5, 1.0, age));
}
void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float d = length(p);
	float core = pow(clamp(1.0 - d, 0.0, 1.0), 3.0);
	float rays = pow(clamp(1.0 - abs(p.x * p.y) * 18.0, 0.0, 1.0), 4.0) * clamp(1.0 - d, 0.0, 1.0);
	float twinkle = 0.85 + 0.15 * sin(anim_clock * 6.0);
	ALBEDO = vec3(1.0, 0.86, 0.55) * (core + rays * 0.6) * v_fade * twinkle * 1.6;
}
"""
