extends Node3D
## Retained, human-scale furniture for occupied houses. This is one global map
## budget, not one budget per city, parcel, person, or country representative.
## Inputs/callbacks are world kilometres; collision work and instances use a
## nearby origin so sub-metre gaps survive planetary Vector2 coordinates.
const Meshes:=preload("res://scripts/settlement_yard_meshes.gd")
const Ink:=preload("res://scripts/settlement_ink.gd")
const Town:=preload("res://scripts/organic_town_visual.gd")
const MAX_HOUSES:=32
const MAX_PROPS:=96
const PROPS_PER_HOUSE:=3
const MAX_SOURCES:=256
const MAX_RECORDS:=8192
const MAX_CACHE:=128
const MAX_SPAN_KM:=.30
const VIEW_CELL_KM:=.032
const INDEX_CELL_KM:=.016
const REACH_KM:=.25
const CLEARANCE_KM:=.00025
const MAX_SLOPE_KM:=.00045
var height_at:Callable
var land_at:Callable
var revealed_at:Callable
var water_at:Callable
var _revision:=-1
var _view_key:Vector2=Vector2.INF
var _view_center:Vector2=Vector2.ZERO
var _origin:Vector2=Vector2.ZERO
var _sources:Array[Dictionary]=[]
var _source_dirty:=false
var _span:=INF
var _houses:Array[Dictionary]=[]
var _obstacles:Dictionary={}
var _roads:Dictionary={}
var _cache:Dictionary={}
var _selected:Array[Dictionary]=[]
var _pending:Array[Dictionary]=[]
var _batches:Dictionary={}
var _dirty:=true
var _needs_commit:=false
var source_rebuilds:=0
var placement_builds:=0
var batch_updates:=0
var last_request_usec:=0
var last_process_usec:=0
var max_process_usec:=0
var displayed:Array[Dictionary]=[]

func configure(height:Callable,physical_land:Callable,revealed:Callable=Callable(),physical_water:Callable=Callable())->void:
	height_at=height;land_at=physical_land;revealed_at=revealed;water_at=physical_water
	visible=false

## The adapter owns a cheap revision from installed plans, knowledge and the
## completed terrain surface. No ledger is queried or mutated by this layer.
func request(sources:Array[Dictionary],revision:int)->void:
	if revision==_revision:return
	_revision=revision;_sources=sources;_source_dirty=true;_dirty=true
	_pending.clear();_needs_commit=false
	# A removed/ruined house must never keep its old furniture while new work queues.
	displayed.clear()
	for node:MultiMeshInstance3D in _batches.values():node.multimesh.visible_instance_count=0

func _prepare_sources()->void:
	var began:=Time.get_ticks_usec()
	_source_dirty=false;source_rebuilds+=1
	_origin=_view_center.round();position=Vector3(_origin.x,0.0,_origin.y)
	_houses.clear();_obstacles.clear();_roads.clear();_cache.clear()
	var count:=0
	var road_count:=0
	for source:Dictionary in _sources.slice(0,MAX_SOURCES):
		var origin:Vector2=Vector2(source.get("origin",Vector2.ZERO))-_origin
		var plots:Array=source.get("plots",[])
		var by_id:Dictionary={}
		for plot:Dictionary in plots:by_id[int(plot.get("id",0))]=plot
		var crafts:=_crafts(source.get("knowledge",[]),plots)
		for road:Dictionary in source.get("routes",[]):
			if road_count>=MAX_RECORDS:break
			var points:PackedVector2Array=road.get("points",PackedVector2Array())
			var half_width:=Town.route_half_width(road)+CLEARANCE_KM
			if not bool(road.get("active",true)):continue
			for index in range(1,points.size()):
				if road_count>=MAX_RECORDS:break
				road_count+=1
				var a:=points[index-1]+origin;var b:=points[index]+origin
				for envelope:PackedVector2Array in Geometry2D.offset_polyline(PackedVector2Array([a,b]),half_width):
					_index(_roads,_bounds(envelope),{"polygon":envelope})
		for record:Dictionary in source.get("plan",{}).get("buildings",[]):
			if count>=MAX_RECORDS:break
			count+=1
			var cached_plot:Dictionary=record.get("plot",{})
			var plot_id:=int(record.get("plot_id",cached_plot.get("id",0)))
			# Geometry may be retained across monthly occupant changes. Eligibility
			# follows the live source plot, never an old render-plan dictionary.
			var plot:Dictionary=by_id.get(plot_id,{}) if not plots.is_empty() else cached_plot
			var at:Vector2=Vector2(record.get("position",Vector2.ZERO))+origin
			var footprint:=_world_polygon(record.get("footprint",PackedVector2Array()),origin)
			if footprint.is_empty():
				var radius:=maxf(.0018,float(record.get("radius",.003)))
				for step in 8:footprint.append(at+Vector2.from_angle(TAU*float(step)/8.0)*radius)
			var id:="%s/%s" % [String(source.get("id","root")),str(record.get("id",record.get("plot_id",count)))]
			var bounds:=_bounds(footprint)
			var house:={"id":id,"position":at,"angle":float(record.get("angle",0.0)),"footprint":footprint,"bounds":bounds,"plot":plot,"parcel":_world_polygon(plot.get("polygon",PackedVector2Array()),origin),"crafts":crafts}
			_index(_obstacles,bounds.grow(.006),house)
			if _occupied(plot,bool(source.get("representative_occupied",false))):_houses.append(house)
		if count>=MAX_RECORDS:break
	_dirty=true;_pending.clear();_needs_commit=false
	displayed.clear()
	for node:MultiMeshInstance3D in _batches.values():node.multimesh.visible_instance_count=0
	last_request_usec=Time.get_ticks_usec()-began

func set_view(center:Vector2,span:float)->void:
	_view_center=center
	_span=span
	visible=span<=MAX_SPAN_KM
	if not visible:return
	var key:=center.snapped(Vector2.ONE*VIEW_CELL_KM)
	if key==_view_key:return
	_view_key=key;_dirty=true
	if _view_key.distance_to(_origin)>32.0:_source_dirty=true

func process_jobs(budget_usec:int=1000,max_houses:int=4)->void:
	last_process_usec=0
	if not visible or max_houses<=0:return
	var began:=Time.get_ticks_usec()
	if _source_dirty:_prepare_sources()
	if _dirty:_select()
	var built:=0
	while not _pending.is_empty() and built<max_houses:
		var house:Dictionary=_pending.pop_front()
		_cache[String(house.id)]=_place(house);placement_builds+=1;built+=1
		_needs_commit=true
		if Time.get_ticks_usec()-began>=budget_usec:break
	# Commit only a complete selection; camera revisits reuse the same cached sites.
	if _pending.is_empty() and _needs_commit:_commit()
	last_process_usec=Time.get_ticks_usec()-began
	max_process_usec=maxi(max_process_usec,last_process_usec)

func stats()->Dictionary:
	return {"houses":_selected.size(),"props":displayed.size(),"batches":_batches.size(),"pending":_pending.size(),"cache":_cache.size(),"source_rebuilds":source_rebuilds,"placement_builds":placement_builds,"batch_updates":batch_updates,"last_request_usec":last_request_usec,"last_process_usec":last_process_usec,"max_process_usec":max_process_usec,"visible":visible,"origin":_origin}

func _select()->void:
	_dirty=false;_selected.clear();_pending.clear()
	var center:=_view_key-_origin
	for house:Dictionary in _houses:
		if Vector2(house.position).distance_squared_to(center)<=REACH_KM*REACH_KM:_selected.append(house)
	_selected.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var da:float=Vector2(a.position).distance_squared_to(center);var db:float=Vector2(b.position).distance_squared_to(center)
		return String(a.id)<String(b.id) if absf(da-db)<1e-12 else da<db)
	if _selected.size()>MAX_HOUSES:_selected.resize(MAX_HOUSES)
	var keep:Dictionary={}
	for house:Dictionary in _selected:
		keep[String(house.id)]=true
		if not _cache.has(String(house.id)):_pending.append(house)
	var cache_limit:=MAX_CACHE-_pending.size()
	if _cache.size()>cache_limit:
		for key:String in _cache.keys():
			if _cache.size()<=cache_limit:break
			if not keep.has(key):_cache.erase(key)
	_needs_commit=true

func _place(house:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var kinds:Array[String]=["woodpile"]
	var crafts:Dictionary=house.crafts
	if bool(crafts.pottery):kinds.append("pots")
	if bool(crafts.drying):kinds.append("drying_rack")
	if bool(crafts.grain):kinds.append("stored_grain")
	if bool(crafts.nets) and _near_water(house.position):kinds.append("fishing_net")
	# A stable rotation shares the optional furniture among neighboring homes;
	# no date, count, camera position or inventory amount selects the contents.
	var start:=posmod(hash(String(house.id)),kinds.size())
	for offset in kinds.size():
		if result.size()>=PROPS_PER_HOUSE:break
		var kind:String=kinds[(start+offset)%kinds.size()]
		var value:=_place_kind(house,kind,result)
		if not value.is_empty():result.append(value)
	return result

func _place_kind(house:Dictionary,kind:String,placed:Array[Dictionary])->Dictionary:
	var box:=Meshes.bounds(kind)
	var half:=Vector2(maxf(absf(box.position.x),absf(box.end.x)),maxf(absf(box.position.z),absf(box.end.z)))*.001+Vector2.ONE*CLEARANCE_KM
	var angle:=float(house.angle)
	var forward:=Vector2(sin(angle),cos(angle));var side:=Vector2(forward.y,-forward.x)
	var house_extent:=Vector2.ZERO
	for point:Vector2 in house.footprint:
		var delta:Vector2=point-Vector2(house.position)
		house_extent=house_extent.max(Vector2(absf(delta.dot(side)),absf(delta.dot(forward))))
	var offset:=posmod(hash(String(house.id)+":"+kind),8)
	for step in 12:
		var slot:=(offset+step)%8
		var directions:=[Vector2(-1,.35),Vector2(1,.35),Vector2(-1,-.55),Vector2(1,-.55),Vector2(-.65,-1),Vector2(.65,-1),Vector2(-.65,1),Vector2(.65,1)]
		var direction:Vector2=directions[slot]
		var gap:=.00045+float(step/8)*.0006
		var local:=Vector2(direction.x*(house_extent.x+half.x+gap),direction.y*(house_extent.y+half.y+gap))
		var at:Vector2=Vector2(house.position)+side*local.x+forward*local.y
		var footprint:=PackedVector2Array()
		for corner:Vector2 in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:footprint.append(at+side*corner.x*half.x+forward*corner.y*half.y)
		if not _clear(house,at,footprint,placed):continue
		var elevation:=_ground(at)
		var valid:=true
		for point:Vector2 in footprint:
			if absf(_ground(point)-elevation)>MAX_SLOPE_KM:valid=false;break
		if not valid:continue
		var basis:=Basis(Vector3.UP,angle).scaled(Vector3.ONE*.001)
		var transform:=Transform3D(basis,Vector3(at.x,elevation-box.position.y*.001+.00002,at.y))
		return {"house_id":house.id,"kind":kind,"position":at+_origin,"footprint":_world_polygon(footprint,_origin),"local_position":at,"local_footprint":footprint,"transform":transform}
	return {}

func _clear(house:Dictionary,at:Vector2,footprint:PackedVector2Array,placed:Array[Dictionary])->bool:
	var parcel:PackedVector2Array=house.parcel
	if parcel.size()<3 or not Geometry2D.clip_polygons(footprint,parcel).is_empty():return false
	var bounds:=_bounds(footprint)
	for other:Dictionary in _query(_obstacles,bounds):
		if bounds.intersects(other.bounds) and not Geometry2D.intersect_polygons(footprint,other.footprint).is_empty():return false
		# Disjoint nearest-house regions keep neighboring yards from stacking
		# furniture when camera selection changes, without moving either house.
		if String(other.id)==String(house.id):continue
		for point:Vector2 in footprint:
			var theirs:=point.distance_squared_to(other.position);var ours:=point.distance_squared_to(house.position)
			if theirs<ours-1e-12 or (absf(theirs-ours)<1e-12 and String(other.id)<String(house.id)):return false
	for other:Dictionary in placed:
		if not Geometry2D.intersect_polygons(footprint,other.local_footprint).is_empty():return false
	for road:Dictionary in _query(_roads,bounds):
		if not Geometry2D.intersect_polygons(footprint,road.polygon).is_empty():return false
	for sample in 9:
		var point:=at
		if sample<4:point=footprint[sample]
		elif sample<8:point=footprint[sample-4].lerp(footprint[(sample-3)%4],.5)
		if land_at.is_valid() and not bool(land_at.call(point+_origin)):return false
		if revealed_at.is_valid() and not bool(revealed_at.call(point+_origin)):return false
	return true

func _near_water(at:Vector2)->bool:
	if not water_at.is_valid():return false
	for radius:float in [.012,.032,.064]:
		for step in 8:
			var point:=at+_origin+Vector2.from_angle(TAU*float(step)/8.0)*radius
			if bool(water_at.call(point)) and (not revealed_at.is_valid() or bool(revealed_at.call(point))):return true
	return false

func _ground(point:Vector2)->float:return float(height_at.call(point+_origin)) if height_at.is_valid() else 0.0

func _commit()->void:
	_needs_commit=false;displayed.clear();batch_updates+=1
	var groups:Dictionary={}
	for house:Dictionary in _selected:
		for record:Dictionary in _cache.get(String(house.id),[]):
			if displayed.size()>=MAX_PROPS:break
			displayed.append(record)
			if not groups.has(record.kind):groups[record.kind]=[]
			groups[record.kind].append(record.transform)
	for kind:String in Meshes.KINDS:
		var transforms:Array=groups.get(kind,[])
		if transforms.is_empty() and not _batches.has(kind):continue
		var node:MultiMeshInstance3D=_batches.get(kind)
		if node==null:
			node=MultiMeshInstance3D.new();node.name="Yard_"+kind
			node.multimesh=MultiMesh.new();node.multimesh.transform_format=MultiMesh.TRANSFORM_3D
			node.multimesh.use_colors=true;node.multimesh.mesh=Meshes.mesh(kind)
			node.material_override=Ink.material();node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(node);_batches[kind]=node
		node.multimesh.instance_count=transforms.size()
		node.multimesh.visible_instance_count=-1
		for index in transforms.size():
			node.multimesh.set_instance_transform(index,transforms[index]);node.multimesh.set_instance_color(index,Color.WHITE)
		node.set_meta("source_transforms",transforms)

static func _occupied(plot:Dictionary,representative_occupied:bool=false)->bool:
	return String(plot.get("status","active"))=="active" and String(plot.get("land_use","")) in ["residential_compound","mixed_household","temporary_encampment"] and (representative_occupied or float(plot.get("resident_count",0))>0.0)

static func _crafts(knowledge:Array,plots:Array)->Dictionary:
	var known:Dictionary={}
	for entry:Variant in knowledge:known[String(entry.get("id","")) if entry is Dictionary else String(entry)]=true
	var any:=func(ids:Array)->bool:
		for id:String in ids:
			if known.has(id):return true
		return false
	var cultivated:=false
	for plot:Dictionary in plots:
		if String(plot.get("land_use",""))=="field" and String(plot.get("status","active"))=="active":cultivated=true;break
	return {"pottery":any.call(["clay_shaping","coiled_pottery","painted_pottery"]),"drying":any.call(["food_drying","indirect_solar_food_drying","smoking","fish_drying","meat_drying"]),"grain":cultivated and any.call(["seed_reserves","clay_lined_storage_pits","hermetic_grain_storage","grain_kept_in_ear","raised_granaries"]),"nets":any.call(["fish_weirs_and_traps","net_mesh_limits"])}

static func _world_polygon(value:Variant,origin:Vector2)->PackedVector2Array:
	var result:=PackedVector2Array()
	for point:Vector2 in value:result.append(point+origin)
	return result

static func _bounds(points:PackedVector2Array)->Rect2:
	if points.is_empty():return Rect2()
	var result:=Rect2(points[0],Vector2.ZERO)
	for point:Vector2 in points:result=result.expand(point)
	return result

static func _index(grid:Dictionary,bounds:Rect2,item:Dictionary)->void:
	var start:=Vector2i(floori(bounds.position.x/INDEX_CELL_KM),floori(bounds.position.y/INDEX_CELL_KM))
	var finish:=Vector2i(floori(bounds.end.x/INDEX_CELL_KM),floori(bounds.end.y/INDEX_CELL_KM))
	# Coarse made roads can be long. Cap their cell fanout and retain them in
	# one overflow bucket; this still clips them without a world-sized grid.
	if (finish.x-start.x+1)*(finish.y-start.y+1)>256:
		if not grid.has("long"):grid["long"]=[]
		grid["long"].append(item);return
	for x in range(start.x,finish.x+1):
		for y in range(start.y,finish.y+1):
			var cell:=Vector2i(x,y)
			if not grid.has(cell):grid[cell]=[]
			grid[cell].append(item)

static func _query(grid:Dictionary,bounds:Rect2)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	result.assign(grid.get("long",[]))
	var start:=Vector2i(floori(bounds.position.x/INDEX_CELL_KM),floori(bounds.position.y/INDEX_CELL_KM))
	var finish:=Vector2i(floori(bounds.end.x/INDEX_CELL_KM),floori(bounds.end.y/INDEX_CELL_KM))
	for x in range(start.x,finish.x+1):
		for y in range(start.y,finish.y+1):
			for entry:Dictionary in grid.get(Vector2i(x,y),[]):
				if entry not in result:result.append(entry)
	return result
