extends Node3D
## CLOSE WOODS (codex/beauty-2): trees in the round wherever the camera goes.
##
## The home settlement has always had a patch of 3D crowns (local_terrain.gd
## _rebuild_close_vegetation) and everywhere else the painted canopy stood in
## at close zoom. This layer streams the same crowns, with the same material,
## atlas and wind sway, around the camera in square chunks of land:
## - bounded: at most MAX_CHUNKS chunks and MAX_CROWNS_PER_CHUNK crowns each,
##   one draw call per chunk;
## - streamed: chunks nearest the view are built first, a slice at a time
##   within a per-frame budget (never a whole rebuild in one frame), and are
##   kept a while when the camera leaves so a return is instant;
## - no popping: each chunk fades in over the painted canopy under it and
##   fades out before it is freed, the whole layer follows the same zoom
##   hand-off as the home patch, and its outer edge is a soft circle around
##   the view instead of a square;
## - stable: every tree comes from its world cell's own seed, so a chunk
##   rebuilt later grows the very same trees;
## - it steps aside inside the home patch, whose crowns fade out where these
##   fade in.
## Visual only: nothing here touches the simulation, resources or the save.

const LandscapeCover:=preload("res://scripts/landscape_cover.gd")
const NODE_NAME:="CloseWoods"
const CHUNK_KM:=0.16
const SPACING_KM:=0.0072
const MAX_CHUNKS:=25
const KEEP_CHUNKS:=36                   ## built chunks kept (visible or resting)
const MAX_CROWNS_PER_CHUNK:=420
const BUDGET_USEC:=900                  ## build time per frame, at most
const BUDGET_MOVING_USEC:=500
const FADE_IN_S:=0.6
const FADE_OUT_S:=0.4
const LATTICE:=5                        ## woodland samples per chunk side
const EDGE_INNER:=0.55                  ## soft circular edge, in view heights
const EDGE_OUTER:=0.95

static var enabled:=true

var terrain:Node3D
var chunks:Dictionary={}                ## Vector2i -> record
var queue:Array[Vector2i]=[]
var material_pool:Array[ShaderMaterial]=[]
var crown_mesh:Mesh
var frame_usec:=0.0
var build_usec_total:=0
var last_target:=Vector3(INF,0,INF)
var last_size:=-1.0

static func ensure(host:Node3D)->Node3D:
	if not enabled or host==null or not is_instance_valid(host):return null
	if not host.has_method("_vegetation_surface_material"):return null
	var layer:=host.get_node_or_null(NODE_NAME) as Node3D
	if layer==null:
		layer=(load("res://scripts/close_woods.gd") as GDScript).new()
		layer.name=NODE_NAME
		layer.set("terrain",host)
		host.add_child(layer)
	return layer

func _process(delta:float)->void:
	if terrain==null or not is_instance_valid(terrain):return
	var began:=Time.get_ticks_usec()
	_frame(delta)
	frame_usec=lerpf(frame_usec,float(Time.get_ticks_usec()-began),0.05)

## How strongly close crowns show at this zoom (the home patch's hand-off).
func zoom_strength()->float:
	var camera:Camera3D=terrain.get("camera")
	if camera==null:return 0.0
	var viewport_size:=get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1600,900)
	return LandscapeCover.detail_strength(camera.size,viewport_size.x/maxf(1.0,viewport_size.y))

func _frame(delta:float)->void:
	var camera:Camera3D=terrain.get("camera")
	if camera==null:return
	var strength:=zoom_strength()
	var target:Vector3=terrain.get("camera_target") if terrain.get("camera_target") is Vector3 else Vector3.ZERO
	var size:=camera.size
	var reach:=_reach(size)
	if strength>0.001 and (Vector2(target.x-last_target.x,target.z-last_target.z).length()>CHUNK_KM*0.25 or absf(size-last_size)>size*0.1):
		last_target=target;last_size=size
		_plan(target,reach)
	# Build a slice of the nearest waiting chunk.
	if strength>0.001 and not queue.is_empty():
		var moving:=bool(terrain.call("_camera_in_motion")) if terrain.has_method("_camera_in_motion") else false
		_build_some(BUDGET_MOVING_USEC if moving else BUDGET_USEC)
	# Fades and the soft edge: a few uniform writes per visible chunk.
	var edge:=Vector4(target.x,target.z,maxf(reach*EDGE_INNER/EDGE_OUTER,0.05),reach)
	var gone:Array[Vector2i]=[]
	for cell:Vector2i in chunks:
		var record:Dictionary=chunks[cell]
		if not record.has("node"):continue
		var wanted:=bool(record.get("wanted",false)) and strength>0.001
		var fade:=float(record.get("fade",0.0))
		fade=clampf(fade+(delta/FADE_IN_S if wanted else -delta/FADE_OUT_S),0.0,1.0)
		record["fade"]=fade
		var node:MultiMeshInstance3D=record.node
		var material:=node.material_override as ShaderMaterial
		node.visible=material!=null and fade*strength>0.002
		if node.visible:
			material.set_shader_parameter("lod_fade",fade*strength)
			material.set_shader_parameter("close_patch",edge)
		elif fade<=0.0 and not wanted and chunks.size()>KEEP_CHUNKS:
			gone.append(cell)
	for cell in gone:_free_chunk(cell)

func _reach(size:float)->float:
	## Radius (km) of land given close crowns: the view's half-width, bounded.
	var viewport_size:=get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1600,900)
	var aspect:=viewport_size.x/maxf(1.0,viewport_size.y)
	return clampf(size*aspect*0.62,0.12,CHUNK_KM*2.4)

func _plan(target:Vector3,reach:float)->void:
	var center:=Vector2(target.x,target.z)
	var wanted:Array[Vector2i]=[]
	var span:=ceili(reach/CHUNK_KM)
	var home_cell:=Vector2i(floori(center.x/CHUNK_KM),floori(center.y/CHUNK_KM))
	for dz in range(-span,span+1):
		for dx in range(-span,span+1):
			var cell:=home_cell+Vector2i(dx,dz)
			if _chunk_distance(cell,center)<=reach+CHUNK_KM*0.5:wanted.append(cell)
	wanted.sort_custom(func(a:Vector2i,b:Vector2i)->bool:return _chunk_distance(a,center)<_chunk_distance(b,center))
	if wanted.size()>MAX_CHUNKS:wanted.resize(MAX_CHUNKS)
	for cell:Vector2i in chunks:(chunks[cell] as Dictionary)["wanted"]=false
	queue.clear()
	for cell in wanted:
		if not chunks.has(cell):chunks[cell]={"cell":cell,"cursor":0}
		var record:Dictionary=chunks[cell]
		record["wanted"]=true
		if not record.has("node"):queue.append(cell)
	# Resting chunks beyond the keep budget, farthest first, are released.
	if chunks.size()>KEEP_CHUNKS:
		var resting:Array=chunks.keys().filter(func(c:Vector2i)->bool:return not bool(chunks[c].get("wanted",false)))
		resting.sort_custom(func(a:Vector2i,b:Vector2i)->bool:return _chunk_distance(a,center)>_chunk_distance(b,center))
		for cell:Vector2i in resting:
			if chunks.size()<=KEEP_CHUNKS:break
			if float(chunks[cell].get("fade",0.0))<=0.0:_free_chunk(cell)

func _chunk_distance(cell:Vector2i,center:Vector2)->float:
	return (Vector2(cell)*CHUNK_KM+Vector2.ONE*CHUNK_KM*0.5).distance_to(center)

func _build_some(budget_usec:int)->void:
	var began:=Time.get_ticks_usec()
	while not queue.is_empty() and Time.get_ticks_usec()-began<budget_usec:
		var cell:Vector2i=queue[0]
		if not chunks.has(cell):
			queue.pop_front();continue
		var record:Dictionary=chunks[cell]
		if _build_step(record,began,budget_usec):
			_finish_chunk(record)
			queue.pop_front()
	build_usec_total+=Time.get_ticks_usec()-began

## Advance one chunk's construction; true once all its cells are placed.
func _build_step(record:Dictionary,began:int,budget_usec:int)->bool:
	var cell:Vector2i=record.cell
	var origin:=Vector2(cell)*CHUNK_KM
	if not record.has("lattice"):
		# Woodland on a coarse lattice (the biome is costly to sample), the
		# canopy tint and climate from the chunk's middle.
		var lattice:PackedFloat32Array=[]
		for j in LATTICE:
			for i in LATTICE:
				var p:=origin+Vector2(float(i),float(j))/float(LATTICE-1)*CHUNK_KM
				lattice.append(LandscapeCover.canopy_density(terrain.call("_biome_at",p.x,p.y)))
		record["lattice"]=lattice
		var middle:=origin+Vector2.ONE*CHUNK_KM*0.5
		var biome:Dictionary=terrain.call("_biome_at",middle.x,middle.y)
		record["biome"]=biome
		record["climate"]=terrain.call("_vegetation_climate",Vector3(middle.x,0.0,middle.y))
		record["transforms"]=[];record["colors"]=[]
		var candidates:=LandscapeCover.candidates(middle,CHUNK_KM*0.5-0.00001,SPACING_KM,int(GameState.world_seed))
		record["candidates"]=candidates
		record["clearings"]=_clearings_near(middle)
		return false
	var candidates:Array=record.candidates
	var transforms:Array=record.transforms
	var colors:Array=record.colors
	var cursor:=int(record.cursor)
	var home:Vector2=terrain.get("close_vegetation_center") if terrain.get("close_vegetation_center") is Vector2 else Vector2(INF,INF)
	var home_active:=is_instance_valid(terrain.get("close_vegetation_root")) and home.x!=INF
	var sea:=_sea_level()
	var rng:=RandomNumberGenerator.new()
	while cursor<candidates.size():
		if Time.get_ticks_usec()-began>=budget_usec:
			record["cursor"]=cursor
			return false
		var candidate:Dictionary=candidates[cursor]
		cursor+=1
		if transforms.size()>=MAX_CROWNS_PER_CHUNK:continue
		var point:Vector2=candidate.point
		rng.seed=int(candidate.seed)
		var density:=_lattice_density(record.lattice,(point-origin)/CHUNK_KM)
		var keep:=smoothstep(0.22,0.70,density)*0.92
		# The home patch keeps its own crowns; these fade in where its fade out.
		if home_active:
			keep*=smoothstep(LandscapeCover.PATCH_INNER_KM,LandscapeCover.PATCH_RADIUS_KM,point.distance_to(home))
		# Other towns and foreign cities stand in their own clearings.
		for clearing:Vector3 in record.clearings:
			keep*=smoothstep(clearing.z*0.75,clearing.z*1.3,point.distance_to(Vector2(clearing.x,clearing.y)))
		if rng.randf()>=keep:continue
		var height:float=terrain.call("_close_surface_height_at",point.x,point.y)
		if height<=sea+0.0004:continue
		var scale:=rng.randf_range(0.74,1.30)
		var basis:=Basis().rotated(Vector3.UP,rng.randf()*TAU).scaled(Vector3(scale*rng.randf_range(0.74,1.10),scale*rng.randf_range(0.74,1.18),scale))
		transforms.append(Transform3D(basis,Vector3(point.x,height+0.00125*scale,point.y)))
		var tint:Color=LandscapeCover.canopy_tint(record.biome,rng.randf())
		# Atlas cell in alpha (the vegetation shader's per-instance variant).
		var variant:int=LandscapeCover.CROWN_ATLAS_CELLS[LandscapeCover.crown_variant(transforms[-1].origin)]
		tint.a=float(variant)/15.0
		colors.append(tint)
	record["cursor"]=cursor
	return true

## Clearings round the places people live near a chunk (x, z, radius km):
## the player's other towns, and the foreign cities the people know. People
## fell the trees for building, fuel and fields before they build (codex/beauty-4).
func _clearings_near(middle:Vector2)->Array[Vector3]:
	var out:Array[Vector3]=[]
	var reach:=CHUNK_KM+0.4
	for settlement in GameState.player_settlements:
		if not settlement is Dictionary or bool(settlement.get("primary",false)):continue
		var at:Variant=settlement.get("position",Vector2.INF)
		if not at is Vector2 or (at as Vector2).distance_to(middle)>reach:continue
		var people:=float(settlement.get("population",60))
		out.append(Vector3((at as Vector2).x,(at as Vector2).y,clampf(0.07+sqrt(maxf(people,1.0))*0.004,0.08,0.28)))
	var intelligence:Variant=CivilizationSystem.get("city_intelligence")
	if intelligence!=null:
		for city:Dictionary in intelligence.known_cities("player","",false,middle,reach):
			var location:Dictionary=city.get("position",{})
			var at:=Vector2(float(location.get("x",INF)),float(location.get("z",INF)))
			if at.distance_to(middle)>reach:continue
			out.append(Vector3(at.x,at.y,0.10))
	return out

var _sea:=NAN
func _sea_level()->float:
	if is_nan(_sea):
		var constants:Dictionary=terrain.get_script().get_script_constant_map() if terrain.get_script() else {}
		_sea=float(constants.get("SEA_LEVEL",0.0))
	return _sea

static func _lattice_density(lattice:PackedFloat32Array,uv:Vector2)->float:
	var g:=Vector2(clampf(uv.x,0.0,1.0),clampf(uv.y,0.0,1.0))*float(LATTICE-1)
	var i:=mini(int(g.x),LATTICE-2);var j:=mini(int(g.y),LATTICE-2)
	var f:=g-Vector2(i,j)
	var a:=lattice[j*LATTICE+i];var b:=lattice[j*LATTICE+i+1]
	var c:=lattice[(j+1)*LATTICE+i];var d:=lattice[(j+1)*LATTICE+i+1]
	return lerpf(lerpf(a,b,f.x),lerpf(c,d,f.x),f.y)

func _finish_chunk(record:Dictionary)->void:
	var transforms:Array=record.transforms
	record.erase("candidates");record.erase("lattice")
	record["fade"]=0.0
	if transforms.is_empty():
		# Open ground: remember it is done, draw nothing.
		record["node"]=_empty_node()
		return
	if crown_mesh==null:crown_mesh=terrain.call("_create_irregular_canopy_mesh",0.0037,0.00235)
	var multi:=MultiMesh.new()
	multi.transform_format=MultiMesh.TRANSFORM_3D
	multi.use_colors=true
	multi.use_custom_data=true
	multi.mesh=crown_mesh
	multi.instance_count=transforms.size()
	var climate:Color=record.climate
	for i in transforms.size():
		multi.set_instance_transform(i,transforms[i])
		multi.set_instance_color(i,record.colors[i])
		multi.set_instance_custom_data(i,climate)
	var node:=MultiMeshInstance3D.new()
	node.name="Woods_%d_%d" % [record.cell.x,record.cell.y]
	node.multimesh=multi
	node.material_override=_take_material()
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.visible=false
	add_child(node)
	record["node"]=node
	record.erase("transforms");record.erase("colors")
	record["crowns"]=transforms.size()

func _empty_node()->MultiMeshInstance3D:
	var node:=MultiMeshInstance3D.new()
	node.visible=false
	add_child(node)
	return node

func _take_material()->ShaderMaterial:
	if not material_pool.is_empty():return material_pool.pop_back()
	# The terrain's own crown material (atlas, seasons, fog, wind sway), with
	# the atlas cell read per crown (-2).
	var material:ShaderMaterial=terrain.call("_vegetation_surface_material",0,-2)
	material.set_shader_parameter("lod_fade",0.0)
	return material

func _free_chunk(cell:Vector2i)->void:
	var record:Dictionary=chunks.get(cell,{})
	chunks.erase(cell)
	queue.erase(cell)
	if record.has("node") and is_instance_valid(record.node):
		var node:MultiMeshInstance3D=record.node
		if node.material_override is ShaderMaterial and material_pool.size()<MAX_CHUNKS:
			material_pool.append(node.material_override as ShaderMaterial)
		node.queue_free()

## For probes and tests.
func report()->Dictionary:
	var built:=0;var visible:=0;var crowns:=0
	for cell in chunks:
		var record:Dictionary=chunks[cell]
		if record.has("node"):
			built+=1
			crowns+=int(record.get("crowns",0))
			if (record.node as Node3D).visible:visible+=1
	return {"chunks":chunks.size(),"built":built,"visible":visible,"queued":queue.size(),"crowns":crowns,"frame_usec":snappedf(frame_usec,0.1),"build_usec_total":build_usec_total}
