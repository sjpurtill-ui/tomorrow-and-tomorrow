extends RefCounted
## Planet-scale render rasters for LocalTerrain (codex/terrain-bake).
##
## Streamed terrain patches whose vertex spacing is at least a raster cell read
## height, colour, surface fields and seasonality from a per-seed lattice with
## bilinear filtering instead of evaluating the procedural sampler per vertex.
## Region-scale and closer patches always use the procedural authority, so close
## terrain is unchanged. The rasters are visual only: no gameplay, save or
## simulation query reads them. Lattice nodes hold exact samples (colour and
## surface fields quantized to the RGBA8 the vertex format stores anyway).
##
## Level 0 covers the planet on a 1921x961 lattice (~20.9 km cells; every fourth
## node is a 481x241 global-mesh vertex). Level 1 is a 3x finer (~7 km) window,
## ~8,000 km wide so a continental (4,988 km) patch can pan ~1,500 km around
## the settled region before it re-centres off-thread. Bakes run one at
## a time on a single background thread (level 0, then the planet land mask, then
## level 1) and are cached in user:// by seed and generator fingerprint.

const BAKE:=preload("res://scripts/terrain_macro_bake.gd")
const PLANET_WIDTH_KM:=40075.0
const PLANET_DEPTH_KM:=20004.0
const LEVEL0_COLUMNS:=1921
const LEVEL0_ROWS:=961
const LEVEL1_NODES:=1153
const LEVEL1_DIVISOR:=3
const RENDER_VERSION:=2
const CACHE_DIR:="user://terrain_macro"
## Patch sampling convention: the builder lifts every sample by this much and
## derives colour/fields/seasonality at the lifted height.
const PATCH_LIFT:=0.0006
const START_DELAY_SEC:=1.5
const RECENTER_MIN_INTERVAL_MSEC:=8000
## Window centres snap to this grid so revisited regions reuse cached windows;
## a 4,988 km patch still fits within +/-1,500 km of an 8,000 km window centre.
const LEVEL1_FOCUS_GRID_KM:=2000.0
const LEVEL1_CACHE_KEEP:=6
const WORLD_SCRIPT_PATH:="res://scripts/local_terrain.gd"

var terrain:Node
var enabled:=true
var levels:Array=[null,null]
var pending:Array=[null,null]
var patches_served:=0
var level1_recenters:=0
var _elapsed:=0.0
var _requested:=false
var _focus:=Vector2.ZERO
var _recenter_focus:=Vector2.INF
var _last_recenter_msec:=-RECENTER_MIN_INTERVAL_MSEC


class Raster extends RefCounted:
	var level:=0
	var origin:=Vector2.ZERO
	var cell:=Vector2.ONE
	var columns:=0
	var rows:=0
	var seed_value:=0
	var bake:RefCounted
	var heights:=PackedFloat32Array()
	var seasons:=PackedFloat32Array()
	var colors:=PackedInt32Array()
	var fields:=PackedInt32Array()

	func extent()->Rect2:
		return Rect2(origin,cell*Vector2(columns-1,rows-1))

	func covers(center:Vector2,span:float)->bool:
		var area:=extent()
		var half:=span*0.5
		return center.x-half>=area.position.x and center.y-half>=area.position.y and center.x+half<=area.end.x and center.y+half<=area.end.y


func bind(owner:Node,seamless:bool,allow_subclass:bool=false)->void:
	## Only the unmodified seamless world scene bakes: test doubles that replace
	## individual samplers must keep sampling through their own overrides.
	var script:Script=owner.get_script()
	enabled=enabled and seamless and (allow_subclass or (script!=null and script.resource_path==WORLD_SCRIPT_PATH))
	terrain=owner if enabled else null


func tick(delta:float)->void:
	## Called from LocalTerrain._process. Starts the bakes shortly after load so
	## they neither compete with world configuration nor run in unit tests that
	## never process frames, then assembles finished rasters.
	if not enabled or terrain==null:return
	if not _requested:
		_elapsed+=delta
		if _elapsed>=START_DELAY_SEC:request(_focus_point())
		return
	poll()


func _focus_point()->Vector2:
	var anchor:Vector3=GameState.settlement_founded_at if GameState.settlement_site_committed else terrain.get("world_start_position")
	return Vector2(anchor.x,anchor.z)


func request(focus:Vector2)->void:
	if not enabled or terrain==null:return
	_requested=true
	_focus=focus
	_advance_chain()


func poll()->void:
	if PlanetEnvironment.macro_bake_running():PlanetEnvironment.poll_macro_bake()
	for index in 2:
		# A different world (loaded save) needs its own rasters.
		var installed:Raster=levels[index]
		if installed!=null and installed.seed_value!=int(GameState.world_seed):levels[index]=null
	for index in 2:
		var raster:Raster=pending[index]
		if raster==null:continue
		var bake:BAKE=raster.bake
		if int(GameState.world_seed)!=raster.seed_value:
			bake.cancel();pending[index]=null;continue
		if not bake.poll():
			if not bake.running():pending[index]=null
			continue
		pending[index]=null
		raster.heights=bake.channels[0]
		raster.seasons=bake.channels[1]
		raster.colors=bake.channels[2]
		raster.fields=bake.channels[3]
		levels[index]=raster
		_upgrade_running_job()
	_advance_chain()


func _upgrade_running_job()->void:
	## A continental patch still sampling procedurally when a fitting raster lands
	## restarts on the raster (a few hundred ms instead of seconds more of noise).
	var job:RefCounted=terrain.get("terrain_patch_job")
	if job==null or job.get("macro_raster")!=null or int(job.get("phase"))>=2:return
	var raster:=raster_for(job.get("center"),float(job.get("span")),int(job.get("resolution")))
	if raster==null:return
	job.set("macro_raster",raster)
	job.set("_raster_bound",false)
	job.set("cursor",0)
	job.set("phase",0)


func _busy()->bool:
	return pending[0]!=null or pending[1]!=null or PlanetEnvironment.macro_bake_running()


func _advance_chain()->void:
	## One bake at a time: planet render level, planet land mask, regional level.
	if not _requested or _busy():return
	if levels[0]==null:pending[0]=_start_level(0,Vector2.ZERO);return
	if not PlanetEnvironment.macro_bake_ready():
		PlanetEnvironment.request_macro_bake()
		if PlanetEnvironment.macro_bake_running():return
	if levels[1]==null:pending[1]=_start_level(1,_focus);return
	if _recenter_focus!=Vector2.INF:
		if (levels[1] as Raster).origin==_level1_origin(_recenter_focus):
			_recenter_focus=Vector2.INF;return
		pending[1]=_start_level(1,_recenter_focus)
		_recenter_focus=Vector2.INF
		level1_recenters+=1


func ready()->bool:
	return levels[0]!=null and levels[1]!=null and PlanetEnvironment.macro_bake_ready()


func cancel()->void:
	for index in 2:
		var raster:Raster=pending[index]
		if raster!=null:(raster.bake as BAKE).cancel()
		pending[index]=null


func set_enabled(value:bool)->void:
	enabled=value


func raster_for(center:Vector2,span:float,resolution:int)->Raster:
	## The finest ready level whose cell is no larger than the patch spacing and
	## which contains the whole patch; null keeps the procedural sampler.
	if not enabled or resolution<2:return null
	var spacing:=span/float(resolution-1)
	for index in [1,0]:
		var raster:Raster=levels[index]
		if raster==null or raster.seed_value!=int(GameState.world_seed):continue
		if raster.cell.x>spacing*1.000001 or raster.cell.y>spacing*1.000001:continue
		if raster.covers(center,span):
			patches_served+=1
			return raster
		if index==1:_maybe_recenter(center,span)
	return null


func _maybe_recenter(center:Vector2,span:float)->void:
	## A continental patch outside the fine window: queue a window around it. The
	## current window stays in use until the replacement is ready.
	if Time.get_ticks_msec()-_last_recenter_msec<RECENTER_MIN_INTERVAL_MSEC:return
	var window:=_level1_cell()*float(LEVEL1_NODES-1)
	if span>minf(window.x,window.y)*0.9:return
	_last_recenter_msec=Time.get_ticks_msec()
	_recenter_focus=center
	var current:Raster=levels[1]
	if current!=null and current.origin==_level1_origin(center):_recenter_focus=Vector2.INF;return
	_advance_chain()


static func level0_cell()->Vector2:
	return Vector2(PLANET_WIDTH_KM/float(LEVEL0_COLUMNS-1),PLANET_DEPTH_KM/float(LEVEL0_ROWS-1))


func _level1_cell()->Vector2:
	return level0_cell()/float(LEVEL1_DIVISOR)


func _level1_origin(focus:Vector2)->Vector2:
	## Grid-snapped centre, then snapped to the level-1 lattice and kept on the planet.
	var planet_origin:=Vector2(-PLANET_WIDTH_KM*0.5,-PLANET_DEPTH_KM*0.5)
	var cell:=_level1_cell()
	var size:=cell*float(LEVEL1_NODES-1)
	var desired:=(focus/LEVEL1_FOCUS_GRID_KM).round()*LEVEL1_FOCUS_GRID_KM-size*0.5
	desired.x=clampf(desired.x,planet_origin.x,planet_origin.x+PLANET_WIDTH_KM-size.x)
	desired.y=clampf(desired.y,planet_origin.y,planet_origin.y+PLANET_DEPTH_KM-size.y)
	return planet_origin+((desired-planet_origin)/cell).floor()*cell


func _start_level(index:int,focus:Vector2)->Raster:
	var raster:=Raster.new()
	raster.level=index
	raster.seed_value=int(GameState.world_seed)
	var planet_origin:=Vector2(-PLANET_WIDTH_KM*0.5,-PLANET_DEPTH_KM*0.5)
	if index==0:
		raster.cell=level0_cell()
		raster.columns=LEVEL0_COLUMNS
		raster.rows=LEVEL0_ROWS
		raster.origin=planet_origin
	else:
		raster.cell=_level1_cell()
		raster.columns=LEVEL1_NODES
		raster.rows=LEVEL1_NODES
		raster.origin=_level1_origin(focus)
	PlanetEnvironment.prepare_macro_sampling()
	var bake:=BAKE.new()
	raster.bake=bake
	var sampler:=func(first:int,count:int)->Array:return _sample_band(raster,first,count)
	var nodes:=raster.columns*raster.rows
	bake.start(raster.rows,8,sampler,_cache_path(raster),PackedInt32Array([nodes,nodes,nodes,nodes]),2 if index==0 else LEVEL1_CACHE_KEEP)
	return raster


func _cache_path(raster:Raster)->String:
	## Seed, lattice geometry and exact samples at fixed probes: a generator or
	## lattice change produces a different key instead of a stale raster.
	var context:=HashingContext.new();context.start(HashingContext.HASH_SHA256)
	var values:=PackedFloat64Array([raster.origin.x,raster.origin.y,raster.cell.x,raster.cell.y,float(raster.columns),float(raster.rows)])
	for probe in 16:
		var point:=raster.origin+raster.cell*Vector2(float((probe*389)%raster.columns),float((probe*211)%raster.rows))
		var sample:=vertex_sample(terrain,point.x,point.y,true)
		var color:Color=sample[2];var surface:Vector4=sample[3]
		values.append_array(PackedFloat64Array([float(sample[0]),float(sample[1]),color.r,color.g,color.b,color.a,surface.x,surface.y,surface.z,surface.w]))
	context.update(values.to_byte_array())
	return "%s/render_l%d_v%d_s%d_%s.bin" % [CACHE_DIR,raster.level,RENDER_VERSION,raster.seed_value,context.finish().hex_encode().substr(0,16)]


func _sample_band(raster:Raster,first:int,count:int)->Array:
	## Worker thread. Calls only pure samplers (no caches, no scene access).
	var nodes:=raster.columns*count
	var heights:=PackedFloat32Array();heights.resize(nodes)
	var seasons:=PackedFloat32Array();seasons.resize(nodes)
	var colors:=PackedInt32Array();colors.resize(nodes)
	var fields:=PackedInt32Array();fields.resize(nodes)
	var index:=0
	for row in range(first,first+count):
		for column in raster.columns:
			# Round through Vector2 exactly as the patch builder does.
			var point:=Vector2(raster.origin.x+float(column)*raster.cell.x,raster.origin.y+float(row)*raster.cell.y)
			var sample:=vertex_sample(terrain,point.x,point.y,true)
			heights[index]=float(sample[0])
			seasons[index]=float(sample[1])
			colors[index]=(sample[2] as Color).to_rgba32()
			var surface:Vector4=sample[3]
			fields[index]=Color(surface.x-1.0,surface.y,surface.z,surface.w).to_rgba32()
			index+=1
	return [heights,seasons,colors,fields]


static func vertex_sample(owner:Object,x:float,z:float,patch_convention:bool)->Array:
	## Thread-safe equivalent of LocalTerrain's per-vertex sampler chain
	## (_height_at, _terrain_seasonality_at, _terrain_color_at and
	## _terrain_surface_fields_at) without the single-sample climate cache those
	## functions share. Returns [height, seasonality, colour, fields]; with the
	## patch convention the height is the raw sample and derived values use the
	## lifted height, exactly as TerrainPatchBuilder does.
	var raw:float=owner._height_at(x,z)
	var height:=raw+PATCH_LIFT if patch_convention else raw
	var climate:Dictionary=owner._climate_at(x,z,height)
	var biome:Dictionary
	if height<0.0:biome=owner._biome_at(x,z,height)
	else:biome=owner._biome_from_climate(x,z,height,climate)
	var color:Color=biome.color
	color.a=float(biome.woodland)
	var position:=Vector2(x,z)
	var geology:Dictionary=PlanetEnvironment._geology(position,height)
	var total:=maxf(.001,float(geology.sedimentary)+float(geology.igneous)+float(geology.metamorphic))
	var fields:=Vector4(1.0+clampf(float(climate.precipitation),0,1),clampf(float(climate.temperature),0,1),float(geology.sedimentary)/total,float(geology.igneous)/total)
	return [raw,PlanetEnvironment.seasonality_unchecked(position),color,fields]


func stats()->Dictionary:
	var result:Dictionary={"patches_served":patches_served,"level1_recenters":level1_recenters}
	for index in 2:
		var raster:Raster=levels[index]
		if raster==null:continue
		var bake:BAKE=raster.bake
		result["level%d" % index]={"columns":raster.columns,"rows":raster.rows,"cell_km":[raster.cell.x,raster.cell.y],"origin":[raster.origin.x,raster.origin.y],"bake_ms":bake.elapsed_ms(),"from_cache":bake.from_cache,"bytes":raster.columns*raster.rows*16}
	return result
