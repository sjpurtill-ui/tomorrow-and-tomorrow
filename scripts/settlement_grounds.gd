extends RefCounted
## THE GROUND OF A LIVED PLACE (codex/beauty-3, extended in codex/beauty-4):
## the worn ground of every place the camera visits, painted into the land by
## the terrain shader (settlement_ground.gdshaderinc).
##
## Rasterized once from the real settlement fabric whenever it changes (never
## per frame) into one small texture over the settled square:
##   R  trodden bare earth: the recorded routes (width and traffic), each
##      dwelling's door yard and drip line, a path from every door to its
##      frontage route, the hearth ground, work yards and stores, and desire
##      paths out to the water point and the worked fields;
##   G  grass worn short around every dwelling and along the paths;
##   B  ash at the hearth, the midden, and the burnt ground of ruins.
## Eight slots share two texture arrays: slot 0 is the home settlement, slots
## 1-3 the player's other towns and the foreign cities the people have seen,
## whichever were drawn most recently near the camera (the farthest is let go
## first); slots 4-7 stream fixed home ground tiles beyond the old centre.
## Everything derives from plots, buildings and routes; nothing here
## changes the simulation or the save.

const RES:=512
const SLOTS:=8
const CITY_SLOTS:=4
## Four camera-local home tiles supplement the retained founding ground.
## Grid scale follows zoom, independently of population or city extent.
const TILE_KM:=0.512
const TILE_PAD_KM:=0.032
const MAX_TILE_CACHE:=12
const MIN_SIZE_KM:=0.14
const MAX_SIZE_KM:=1.1
const PAD_KM:=0.03
## Service parcels drawn as open ground (early_settlement_ground.gd's forms
## plus the maintained gathering ground at the hearth).
const HEARTH_FORMS:=["open_hearth_yard","maintained_gathering_ground","customary_precinct"]

## The home slot, as before (tests and tools read these).
static var texture:ImageTexture
## Worked ground: R cover, G row angle, B phase/pattern/worked, A crop/cover.
static var fields_texture:ImageTexture
static var origin_hi:=Vector2.ZERO
static var origin_lo:=Vector2.ZERO
static var size_km:=1.0
static var strength:=0.0
static var signature:=0
static var report:Dictionary={}
## Every slot, for the shader: two texture arrays and per-slot frames.
static var ground_layers:Texture2DArray
static var field_layers:Texture2DArray
static var slot_keys:PackedStringArray=PackedStringArray(["","","","","","","",""])
static var slot_signatures:PackedInt64Array=PackedInt64Array([0,0,0,0,0,0,0,0])
static var slot_centers:PackedVector2Array=PackedVector2Array([Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO])
static var slot_origins:PackedVector4Array=PackedVector4Array([Vector4.ZERO,Vector4.ZERO,Vector4.ZERO,Vector4.ZERO,Vector4.ZERO,Vector4.ZERO,Vector4.ZERO,Vector4.ZERO])
static var slot_frames:PackedVector4Array=PackedVector4Array([Vector4(1,0,0,0),Vector4(1,0,0,0),Vector4(1,0,0,0),Vector4(1,0,0,0),Vector4(1,0,0,0),Vector4(1,0,0,0),Vector4(1,0,0,0),Vector4(1,0,0,0)])
## Each slot's cultivated halo: radius km, strength, worked share, orchards.
static var slot_halos:PackedVector4Array=PackedVector4Array([Vector4.ZERO,Vector4.ZERO,Vector4.ZERO,Vector4.ZERO,Vector4.ZERO,Vector4.ZERO,Vector4.ZERO,Vector4.ZERO])
static var slot_reports:Array[Dictionary]=[{},{},{},{},{},{},{},{}]
static var slot_noise_offsets:PackedVector2Array=PackedVector2Array([Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO])
static var _tile_cache:Dictionary={}
static var _tile_inputs:Dictionary={}
static var _tile_view:=Vector2i(2147483647,2147483647)
static var _tile_level:=-1
static var _tile_revision:=0
static var _home_revision:=0
static var _home_paths:Array[Dictionary]=[]
static var _home_hearth:=Vector2.ZERO
static var _home_has_hearth:=false
static var _home_shares:Dictionary={}
static var _home_bearings:Array=[]
static var tile_builds:=0
static var tile_cache_hits:=0
static var _materials:Array[WeakRef]=[]
static var _brushes:Dictionary={}
## Places other than the home that have been drawn: key -> [plan, plots,
## routes, center]. The camera's nearest ones are painted, one per settled
## frame (serve); at most MAX_REQUESTS are remembered.
static var _requests:Dictionary={}
static var _served_at:=Vector2.INF
const MAX_REQUESTS:=64

## Registers a terrain material; it receives the current ground and every
## later rebuild (called by local_terrain.gd for each seasonal material).
static func bind(material:ShaderMaterial)->void:
	if material==null:return
	_materials.append(weakref(material))
	_apply(material)

static func _apply(material:ShaderMaterial)->void:
	material.set_shader_parameter("sg_frames",slot_frames)
	material.set_shader_parameter("sg_halos",slot_halos)
	material.set_shader_parameter("sg_noise_offsets",slot_noise_offsets)
	if ground_layers==null:return
	material.set_shader_parameter("settlement_ground",ground_layers)
	material.set_shader_parameter("settlement_fields",field_layers)
	material.set_shader_parameter("sg_origins",slot_origins)

static func _apply_all()->void:
	var alive:Array[WeakRef]=[]
	for ref in _materials:
		var material:=ref.get_ref() as ShaderMaterial
		if material==null:continue
		alive.append(ref)
		_apply(material)
	_materials=alive

## Clears the painted ground (a new world, or no settlement).
static func clear()->void:
	texture=null;fields_texture=null;strength=0.0;signature=0;report={}
	_requests.clear();_served_at=Vector2.INF
	_home_args.clear();_tile_cache.clear();_tile_inputs.clear()
	_home_paths.clear();_home_hearth=Vector2.ZERO;_home_has_hearth=false
	_home_shares.clear();_home_bearings.clear()
	_tile_view=Vector2i(2147483647,2147483647);_tile_revision=0;_home_revision=0
	_tile_level=-1
	tile_builds=0;tile_cache_hits=0
	for slot in SLOTS:
		slot_keys[slot]="";slot_signatures[slot]=0;slot_frames[slot]=Vector4(1,0,0,0);slot_reports[slot]={};slot_halos[slot]=Vector4.ZERO
	_apply_all()

## The home settlement's position (world km, x and z). While another town's
## resources are swapped in (SettlementModel.with_city_resources),
## settlement_founded_at is that town's, so the primary record alone names
## the home: a home at the origin must not make every other town "home".
static func home_center()->Vector2:
	var in_other_town:=not String(WorldSimulation.state.resource_settlement_id).is_empty()
	for settlement in GameState.player_settlements:
		if settlement is Dictionary and bool(settlement.get("primary",false)):
			var at:=_v2(settlement.get("position",Vector2.INF))
			if at!=Vector2.ZERO or in_other_town:return at
	return Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)

## Paints the home settlement into slot 0; any other town drawn through the
## same renderers (its own fabric swapped in) gets a slot of its own and never
## repaints the home.
static func build_if_home(plan:Dictionary,plots:Array[Dictionary],routes:Array[Dictionary],center:Vector3)->void:
	if Vector2(center.x,center.z).distance_to(home_center())>0.25:
		request("town:%d:%d" % [roundi(center.x*100.0),roundi(center.z*100.0)],plan,plots,routes,center)
		return
	build(plan,plots,routes,center)

## Remembers a place other than the home whose fabric was just drawn; its
## ground is painted when the camera settles near it (serve).
static func request(key:String,plan:Dictionary,plots:Array[Dictionary],routes:Array[Dictionary],center:Vector3)->void:
	if not _requests.has(key) and _requests.size()>=MAX_REQUESTS:
		# Forget the one farthest from this place.
		var worst:="";var far:=-1.0
		for other:String in _requests:
			var d:=Vector2((_requests[other][3] as Vector3).x,(_requests[other][3] as Vector3).z).distance_to(Vector2(center.x,center.z))
			if d>far:far=d;worst=other
		_requests.erase(worst)
	_requests[key]=[plan,plots,routes,center]
	var slot:=slot_keys.find(key)
	if slot>0:slot_signatures[slot]=-1
	_served_at=Vector2.INF

## Paints the nearest remembered place within `reach` km of `target` that is
## not painted yet (at most one per call; cheap when there is nothing to do).
## The map calls it on settled frames at settlement zoom.
static func serve(target:Vector2,reach:float,view:=Rect2())->void:
	if not view.has_area():view=Rect2(target-Vector2.ONE*reach,Vector2.ONE*reach*2.0)
	if _serve_home_tile(target,view):return
	if _requests.is_empty() or _served_at.distance_to(target)<reach*0.25:return
	var best:="";var nearest:=INF
	for key:String in _requests:
		var center:Vector3=_requests[key][3]
		var d:=Vector2(center.x,center.z).distance_to(target)
		if d>reach+MAX_SIZE_KM*0.5 or d>=nearest:continue
		var slot:=slot_keys.find(key)
		if slot>0 and slot_signatures[slot]!=-1 and slot_frames[slot].y>0.0:continue
		best=key;nearest=d
	if best=="":
		_served_at=target
		return
	var entry:Array=_requests[best]
	var plots:Array[Dictionary]=[];plots.assign(entry[1])
	var routes:Array[Dictionary]=[];routes.assign(entry[2])
	build_other(best,entry[0],plots,routes,entry[3],target)

## Paints a settlement other than the home (a player town or a seen foreign
## city) into a free slot, or the one farthest from it. Cheap when nothing
## changed.
static func build_other(key:String,plan:Dictionary,plots:Array[Dictionary],routes:Array[Dictionary],center:Vector3,camera_at:=Vector2.INF)->void:
	var near:=Vector2(center.x,center.z) if camera_at==Vector2.INF else camera_at
	var slot:=slot_keys.find(key)
	if slot<=0:
		slot=-1
		var farthest:=-1.0
		for candidate in range(1,CITY_SLOTS):
			if slot_keys[candidate]=="":slot=candidate;break
			var distance:=slot_centers[candidate].distance_to(near)
			if distance>farthest:farthest=distance;slot=candidate
		slot_keys[slot]=key
	slot_signatures[slot]=0
	_paint(slot,plan,plots,routes,center)

## Paints the ground for the home settlement. `plan` is the early-town layout
## (buildings with position, angle, radius and plot; may be empty), `plots`
## and `routes` the recorded fabric, `center` the settlement's world position.
## Cheap when nothing changed.
static func build(plan:Dictionary,plots:Array[Dictionary],routes:Array[Dictionary],center:Vector3)->void:
	slot_keys[0]="home"
	_home_args=[plan,plots,routes,center]
	var bearings:=_approach_bearings(Vector2(center.x,center.z))
	_home_shares=_labour();_home_bearings=bearings.duplicate()
	var revision:=hash([center,plan.is_empty(),_fabric_key(plots),_route_key(routes),_building_key(plan.get("buildings",[])),_home_shares,_works_near(center),bearings])
	if revision==_home_revision and slot_frames[0].y>0.0:return
	_home_revision=revision
	# Distant growth does not move or repaint the old centre's texture.
	_home_paths.clear();_home_hearth=Vector2.ZERO;_home_has_hearth=false
	for plot in plots:
		if _alive(plot) and String(plot.get("form","")) in HEARTH_FORMS:
			_home_hearth=_v2(plot.get("centroid",Vector2.ZERO));_home_has_hearth=true;break
	var core:=_in_rect(plan,plots,routes,Rect2(Vector2.ONE*(-MAX_SIZE_KM*0.5),Vector2.ONE*MAX_SIZE_KM))
	var core_frame:=_paint_rect(core.plan,core.plots,core.routes,_works_near(center))
	_home_paths=_derive_home_paths(plots,routes,bearings,core_frame)
	core=_in_rect(plan,plots,routes,Rect2(Vector2.ONE*(-MAX_SIZE_KM*0.5),Vector2.ONE*MAX_SIZE_KM))
	_paint(0,core.plan,core.plots,core.routes,center)

## Resolve connectivity once against the whole recorded settlement. Cropping
## records first can send the same field towards different hearths/routes on
## opposite sides of a texture seam, or omit the middle of a long footpath.
static func _derive_home_paths(plots:Array[Dictionary],routes:Array[Dictionary],bearings:Array,core:Rect2)->Array[Dictionary]:
	var points:=PackedVector2Array()
	for route in routes:
		if bool(route.get("active",true)):points.append_array(_points(route))
	if _home_has_hearth:points.append(_home_hearth)
	var paths:Array[Dictionary]=[]
	for plot in plots:
		if not _alive(plot):continue
		var use:=String(plot.get("land_use",""))
		var kind:="water" if use=="water" or String(plot.get("form",""))=="carried_water_point" else "field" if use=="field" else ""
		if kind=="":continue
		var target:=_polygon_near(plot,_home_hearth) if kind=="field" else _v2(plot.get("centroid",Vector2.ZERO))
		var start:=_nearest_point(points,target)
		if start.distance_to(target)<0.004 or start.distance_to(target)>0.4:continue
		paths.append({"kind":kind,"points":_wander(start,target,int(plot.get("seed",7)))})
	for index in bearings.size():
		var direction:=Vector2.from_angle(float(bearings[index]))
		var start:=_nearest_point(points,direction*0.05) if not points.is_empty() else Vector2.ZERO
		paths.append({"kind":"approach","points":_wander(start,core.get_center()+direction*core.size.x*0.75,index*131+7)})
	return paths

## Narrow a ground job to records whose paint can reach its fixed square.
## Whole route segments are retained so brush spacing agrees at tile seams.
static func _in_rect(plan:Dictionary,plots:Array[Dictionary],routes:Array[Dictionary],rect:Rect2)->Dictionary:
	var nearby:=rect.grow(0.09)
	var selected_plots:Array[Dictionary]=[]
	var selected_routes:Array[Dictionary]=[]
	var buildings:Array=[]
	for plot in plots:
		var polygon:=_polygon(plot)
		var bounds:=Rect2(_v2(plot.get("centroid",Vector2.ZERO)),Vector2.ZERO)
		for point in polygon:bounds=bounds.expand(point)
		if nearby.intersects(bounds,true):selected_plots.append(_ground_plot_snapshot(plot))
	for route in routes:
		var points:=_points(route)
		if points.is_empty():continue
		var bounds:=Rect2(points[0],Vector2.ZERO)
		for point in points:bounds=bounds.expand(point)
		if nearby.intersects(bounds,true):
			var copy:=route.duplicate();copy["points"]=points.duplicate()
			selected_routes.append(copy)
	for record in plan.get("buildings",[]):
		if nearby.has_point(Vector2(record.get("position",Vector2.ZERO))):
			var copy:Dictionary=record.duplicate();copy["plot"]=_ground_plot_snapshot(record.get("plot",{}))
			buildings.append(copy)
	var paths:Array[Dictionary]=[]
	for path in _home_paths:
		var points:PackedVector2Array=path.points
		var bounds:=Rect2(points[0],Vector2.ZERO)
		for point in points:bounds=bounds.expand(point)
		if nearby.intersects(bounds,true):paths.append(path)
	return {"plan":{"buildings":buildings,"_ground_fallback":plan.is_empty(),"_ground_paths":paths,"_ground_hearth":_home_hearth,"_ground_has_hearth":_home_has_hearth,"_ground_shares":_home_shares.duplicate(),"_ground_bearings":_home_bearings.duplicate()},"plots":selected_plots,"routes":selected_routes}

## Freeze only paint inputs: deep-copying saved building sites and unrelated
## simulation payloads would make a visual job unnecessarily expensive.
static func _ground_plot_snapshot(plot:Dictionary)->Dictionary:
	var copy:=plot.duplicate()
	copy["polygon"]=_polygon(plot).duplicate()
	if plot.get("damage") is Dictionary:copy["damage"]=(plot.damage as Dictionary).duplicate()
	return copy

## Installs at most one tile per settled frame. Four resident layers and twelve
## CPU image pairs bound memory independently of the city's total land area.
static func _serve_home_tile(target:Vector2,view:Rect2)->bool:
	if _home_args.is_empty():return false
	var center:Vector3=_home_args[3]
	var local:=target-Vector2(center.x,center.z)
	var layout:=preload("res://scripts/settlement_ground_view.gd").tile_layout(Rect2(view.position-Vector2(center.x,center.z),view.size))
	var cell:Vector2i=layout.cell
	var side:float=layout.side
	var pad:float=layout.pad
	if cell!=_tile_view or int(layout.level)!=_tile_level or _tile_revision!=_home_revision:
		_tile_view=cell;_tile_level=int(layout.level);_tile_revision=_home_revision;_tile_inputs.clear()
		var plots:Array[Dictionary]=[];plots.assign(_home_args[1])
		var routes:Array[Dictionary]=[];routes.assign(_home_args[2])
		for y in 2:
			for x in 2:
				var coordinate:=cell+Vector2i(x,y)
				var rect:=Rect2(Vector2(coordinate)*side,Vector2.ONE*side).grow(pad)
				# The founding square keeps its original detailed presentation.
				var inner:=rect.grow(-pad)
				var core:=slot_rect(0)
				var world_inner:=Rect2(inner.position+Vector2(center.x,center.z),inner.size)
				if core.encloses(world_inner):continue
				var args:=_in_rect(_home_args[0],plots,routes,rect)
				if args.plots.is_empty() and args.routes.is_empty() and args.plan.get("buildings",[]).is_empty() and args.plan.get("_ground_paths",[]).is_empty():continue
				args["rect"]=rect;args["center"]=center
				args["signature"]=_paint_key(args.plan,args.plots,args.routes,center,rect)
				_tile_inputs["home_tile:%d:%d:%d" % [_tile_level,coordinate.x,coordinate.y]]=args
	var wanted:Array=_tile_inputs.keys()
	wanted.sort_custom(func(a:String,b:String)->bool:return (_tile_inputs[a].rect as Rect2).get_center().distance_squared_to(local)<(_tile_inputs[b].rect as Rect2).get_center().distance_squared_to(local))
	for key:String in wanted:
		var args:Dictionary=_tile_inputs[key]
		var slot:=slot_keys.find(key)
		if slot>=CITY_SLOTS and slot_signatures[slot]==int(args.signature):continue
		if not _tile_cache.has(int(args.signature)):
			# Keep the preceding view resident until the new set is ready.
			# Raster work remains limited to one image pair per service call.
			_paint(CITY_SLOTS,args.plan,args.plots,args.routes,center,args.rect,true)
			return true
	for key:String in wanted:
		var args:Dictionary=_tile_inputs[key]
		var slot:=slot_keys.find(key)
		if slot>=CITY_SLOTS and slot_signatures[slot]==int(args.signature):continue
		if slot<CITY_SLOTS:
			for candidate in range(CITY_SLOTS,SLOTS):
				if slot_keys[candidate] not in wanted:slot=candidate;break
		if slot<CITY_SLOTS:continue
		slot_keys[slot]=key
		_paint(slot,args.plan,args.plots,args.routes,center,args.rect)
	var cleared:=false
	for slot in range(CITY_SLOTS,SLOTS):
		if slot_keys[slot]!="" and not _tile_inputs.has(slot_keys[slot]):
			slot_keys[slot]="";slot_signatures[slot]=0;slot_frames[slot].y=0.0
			cleared=true
	if cleared:_apply_all()
	return false

static var _home_args:Array=[]
## Where roads between places leave each town (settlement_roads.gd): world
## centre and bearings. Each town's ground wears an approach track out along
## them, so the road runs on into its streets.
static var approaches:Dictionary={}
static func set_approaches(value:Dictionary)->void:
	if hash(value)==hash(approaches):return
	approaches=value
	for slot in range(1,CITY_SLOTS):
		if slot_keys[slot]!="":slot_signatures[slot]=-1
	_served_at=Vector2.INF
	if not _home_args.is_empty():
		var plots:Array[Dictionary]=[];plots.assign(_home_args[1])
		var routes:Array[Dictionary]=[];routes.assign(_home_args[2])
		build(_home_args[0],plots,routes,_home_args[3])

static func _paint_key(plan:Dictionary,plots:Array[Dictionary],routes:Array[Dictionary],center:Vector3,frame:=Rect2())->int:
	var shares:Dictionary=plan._ground_shares.duplicate() if plan.has("_ground_shares") else _labour()
	for activity in shares:shares[activity]=snappedf(float(shares[activity]),0.1)
	var bearings:Array=plan._ground_bearings if plan.has("_ground_bearings") else _approach_bearings(Vector2(center.x,center.z))
	var fallback:=bool(plan.get("_ground_fallback",plan.is_empty()))
	var works:Array[Dictionary]=[]
	if not frame.has_area():works=_works_near(center)
	var paint_frame:=frame
	var fabric:int
	if plan.has("_ground_paths"):
		# The source revision still tracks the full settlement. A home paint job
		# only needs records that can leave ink, plus the actual framing and its
		# already-derived connectivity. An unrendered household inside that
		# frame must not repaint every inherited yard when it grows or repairs.
		paint_frame=frame if frame.has_area() else _paint_rect(plan,plots,routes,works)
		fabric=_paint_plot_key(plots,fallback)
	else:
		fabric=_fabric_key(plots)
	return hash([center,paint_frame,fallback,fabric,_route_key(routes),_building_key(plan.get("buildings",[])),plan.get("_ground_paths",[]),plan.get("_ground_hearth",Vector2.ZERO),plan.get("_ground_has_hearth",false),works,bearings,shares])

static func _paint_plot_key(plots:Array[Dictionary],fallback:bool)->int:
	var painted:Array[Dictionary]=[]
	for plot in plots:
		var use:=String(plot.get("land_use",""))
		var form:=String(plot.get("form",""))
		var status:=String(plot.get("status","active"))
		var field:=use=="field" and status!="reclaimed" and _polygon(plot).size()>=3
		var midden:=form=="refuse_and_latrine_ground" and status!="reclaimed"
		var service:=form in HEARTH_FORMS or form in ["open_work_yard","covered_work_yard","sheltered_work_area","guarded_cache","lined_storage_pits","protected_household_store","raised_timber_store","communal_store","carried_water_point","refuse_and_latrine_ground"] or use in ["market","civic","sacred"]
		var household:=fallback and use in ["residential_compound","mixed_household"]
		if field or midden or (_alive(plot) and (service or household)):painted.append(plot)
	return _fabric_key(painted)

## Road bearings leaving the town at `center` (world km).
static func _approach_bearings(center:Vector2)->Array:
	var out:Array=[]
	for key in approaches:
		var entry:Dictionary=approaches[key]
		if Vector2(entry.center).distance_to(center)<0.4:out.append_array(entry.bearings)
	return out

static func _paint_rect(plan:Dictionary,plots:Array[Dictionary],routes:Array[Dictionary],works:Array[Dictionary])->Rect2:
	var buildings:Array=plan.get("buildings",[])
	# The settled square: everything lived in, plus a margin. Far vacant
	# fields do not stretch it.
	var box:=Rect2(Vector2.ZERO,Vector2.ZERO)
	for record in buildings:box=box.expand(Vector2(record.position))
	for plot in plots:
		var use:=String(plot.get("land_use",""))
		var status:=String(plot.get("status","active"))
		if status in ["vacant","reclaimed"] and use=="field":continue
		var c:=_v2(plot.get("centroid",Vector2.ZERO))
		if c.length()>MAX_SIZE_KM*0.5:continue
		box=box.expand(c)
	# Great works of this settlement (sites in world km): each stands in a
	# worked yard with a path to it.
	for work in works:box=box.expand(Vector2(work.at))
	# Routes widen the square only near what is lived in (not the long
	# tracks out to far fields).
	var lived:=box.grow(0.04)
	for route in routes:
		if not bool(route.get("active",true)):continue
		for point in _points(route):
			if lived.has_point(point):box=box.expand(point)
	box=box.grow(PAD_KM)
	var side:=clampf(maxf(box.size.x,box.size.y),MIN_SIZE_KM,MAX_SIZE_KM)
	var mid:=box.get_center()
	var corner:=mid-Vector2(side,side)*0.5
	return Rect2(corner,Vector2.ONE*side)

static func _paint(slot:int,plan:Dictionary,plots:Array[Dictionary],routes:Array[Dictionary],center:Vector3,frame:=Rect2(),cache_only:=false)->void:
	var buildings:Array=plan.get("buildings",[])
	var works:Array[Dictionary]=[]
	if slot==0:works=_works_near(center)
	var bearings:Array=plan._ground_bearings if plan.has("_ground_bearings") else _approach_bearings(Vector2(center.x,center.z))
	var key:=_paint_key(plan,plots,routes,center,frame)
	if not cache_only and key==slot_signatures[slot] and ground_layers!=null and slot_frames[slot].y>0.0:return
	if not cache_only:slot_signatures[slot]=key
	var began:=Time.get_ticks_usec()
	var base_frame:=_paint_rect(plan,plots,routes,works)
	var side:=base_frame.size.x
	var mid:=base_frame.get_center()
	var corner:=base_frame.position
	if frame.has_area():side=frame.size.x;corner=frame.position
	if frame.has_area() and _tile_cache.has(key):
		if cache_only:return
		var cached:Dictionary=_tile_cache[key]
		_tile_cache.erase(key);_tile_cache[key]=cached
		_store(slot,cached.ground,cached.fields)
		slot_origins[slot]=cached.origin;slot_frames[slot]=cached.frame;slot_halos[slot]=Vector4.ZERO
		slot_noise_offsets[slot]=frame.position*1000.0
		slot_centers[slot]=Vector2(center.x,center.z)+frame.get_center();slot_reports[slot]=cached.report.duplicate()
		slot_reports[slot]["slot"]=slot
		tile_cache_hits+=1;_apply_all();return
	var image:=Image.create_empty(RES,RES,false,Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,1))
	var painter:={"image":image,"corner":corner,"texel":side/float(RES),"stamps":0}
	var shares:Dictionary=plan._ground_shares if plan.has("_ground_shares") else _labour()
	# --- G: grass worn short -------------------------------------------------
	for record in buildings:
		var plot:Dictionary=record.plot
		if String(plot.get("status","active")) in ["reclaimed"]:continue
		var reach:=maxf(float(record.get("radius",0.003))*4.5,0.013)
		_disc(painter,Vector2(record.position),reach,0.34,Color(0,1,0))
		# The broad clearing a village wears into its meadow, read from afar.
		_disc(painter,Vector2(record.position),0.03,0.14,Color(0,1,0))
	for plot in plots:
		if String(plot.get("form","")) in HEARTH_FORMS and _alive(plot):
			_disc(painter,_v2(plot.get("centroid",Vector2.ZERO)),0.024,0.42,Color(0,1,0))
		elif (plan.is_empty() or bool(plan.get("_ground_fallback",false))) and String(plot.get("land_use","")) in ["residential_compound","mixed_household"] and _alive(plot):
			_disc(painter,_v2(plot.get("centroid",Vector2.ZERO)),_plot_radius(plot)*1.4,0.26,Color(0,1,0))
	for route in routes:
		if not bool(route.get("active",true)):continue
		_line(painter,_points(route),maxf(float(route.get("width_m",1.2))*0.0022,0.0028),0.10,Color(0,1,0))
	# --- R: trodden bare earth ----------------------------------------------
	var hearth:=Vector2.ZERO
	var hearth_found:=false
	for plot in plots:
		if not _alive(plot):continue
		var form:=String(plot.get("form",""))
		var c:=_v2(plot.get("centroid",Vector2.ZERO))
		if form in HEARTH_FORMS:
			if not hearth_found:hearth=c;hearth_found=true
			var r:=clampf(_plot_radius(plot)*0.78,0.0045,0.012)
			_disc(painter,c,r,0.95,Color(1,0,0))
			_disc(painter,c,r*1.35,0.35,Color(1,0,0))
		elif form in ["open_work_yard","covered_work_yard","sheltered_work_area"]:
			_disc(painter,c,clampf(_plot_radius(plot)*0.55,0.003,0.008),0.62,Color(1,0,0))
		elif form in ["guarded_cache","lined_storage_pits","protected_household_store","raised_timber_store","communal_store"]:
			_disc(painter,c,clampf(_plot_radius(plot)*0.40,0.0025,0.006),0.45,Color(1,0,0))
		elif String(plot.get("land_use","")) in ["market","civic","sacred"]:
			# Courts and market grounds before the public buildings.
			_disc(painter,c,clampf(_plot_radius(plot)*0.85,0.005,0.02),0.80,Color(1,0,0))
		elif form=="carried_water_point":
			_disc(painter,c,0.0032,0.80,Color(1,0,0))
		elif form=="refuse_and_latrine_ground":
			_disc(painter,c,0.004,0.40,Color(1,0,0))
	# The recorded routes: width and wear from their traffic.
	for route in routes:
		if not bool(route.get("active",true)):continue
		var traffic:=clampf(float(route.get("traffic",0.5)),0.0,1.0)
		var width_m:=maxf(float(route.get("width_m",1.0)),0.8)
		var hierarchy:=String(route.get("hierarchy","path"))
		var kind:=String(route.get("kind","desire_path"))
		if hierarchy in ["lane","main_approach"]:width_m*=1.25
		if kind=="field_track":width_m*=0.8
		# Made streets (surface tier 2 and up) are full width and hard-worn.
		var made:=int(route.get("surface_tier",0))>=2
		_line(painter,_points(route),width_m*(0.50 if made else 0.36)*0.001+0.00014,1.0 if made else 0.55+0.40*traffic,Color(1,0,0))
	if plan.has("_ground_hearth"):
		hearth=plan._ground_hearth;hearth_found=bool(plan._ground_has_hearth)
	# Each home's door yard, the ring its eaves drip on, and its own path
	# to the route it fronts.
	var fronts:Dictionary={}
	for route in routes:
		if bool(route.get("active",true)):fronts[int(route.get("id",-1))]=_points(route)
	for record in buildings:
		var plot:Dictionary=record.plot
		var status:=String(plot.get("status","active"))
		if status in ["vacant","reclaimed"]:continue
		var position:=Vector2(record.position)
		var radius:=maxf(float(record.get("radius",0.003)),0.0018)
		var forward:=Vector2(sin(float(record.angle)),cos(float(record.angle)))
		var door:=position+forward*radius*0.95
		if status=="ruin":
			_disc(painter,position,radius*0.9,0.35,Color(1,0,0))
			continue
		_disc(painter,position,radius*1.25,0.50,Color(1,0,0))
		_disc(painter,door+forward*0.0014,maxf(radius*0.75,0.0024),0.85,Color(1,0,0))
		var route_points:PackedVector2Array=fronts.get(int(plot.get("frontage_route_id",-1)),PackedVector2Array())
		var nearest:=_nearest_on(route_points,door) if route_points.size()>=2 else (hearth if hearth_found else door)
		if nearest.distance_to(door)<0.06:
			_line(painter,_wander(door,nearest,int(plot.get("seed",1))),0.0007,0.70,Color(1,0,0))
	# Desire paths to the water point and the worked fields, worn by how many
	# hands fetch water and farm (the labour allocation).
	var all_points:PackedVector2Array=PackedVector2Array()
	for route in routes:
		if bool(route.get("active",true)):all_points.append_array(_points(route))
	if hearth_found:all_points.append(hearth)
	if plan.has("_ground_paths"):
		for path:Dictionary in plan._ground_paths:
			var kind:=String(path.kind)
			var track:PackedVector2Array=path.points
			if kind=="approach":
				_line(painter,track,0.0012,0.78,Color(1,0,0))
				_line(painter,track,0.0030,0.22,Color(0,1,0))
			else:
				var wear:=0.62+0.25*clampf(float(shares.get("carry",0.0)),0.0,1.0) if kind=="water" else 0.45+0.40*clampf(float(shares.get("farm",0.0)),0.0,1.0)
				_line(painter,track,0.0009,wear,Color(1,0,0))
	else:
		for plot in plots:
			if not _alive(plot):continue
			var use:=String(plot.get("land_use",""))
			var form:=String(plot.get("form",""))
			var target:=_v2(plot.get("centroid",Vector2.ZERO))
			var wear:=0.0
			if form=="carried_water_point" or use=="water":wear=0.62+0.25*clampf(float(shares.get("carry",0.0)),0.0,1.0)
			elif use=="field":wear=0.45+0.40*clampf(float(shares.get("farm",0.0)),0.0,1.0)
			else:continue
			if use=="field":target=_polygon_near(plot,hearth if hearth_found else Vector2.ZERO)
			var start:=_nearest_point(all_points,target)
			if start.distance_to(target)<0.004 or start.distance_to(target)>0.4:continue
			_line(painter,_wander(start,target,int(plot.get("seed",7))),0.0009,wear,Color(1,0,0))
		# The roads to other places: a worn approach from the lived ground out
		# to the edge of the painted square, where the road's ink takes over.
		for index in bearings.size():
			var out_dir:=Vector2.from_angle(float(bearings[index]))
			var start:=_nearest_point(all_points,out_dir*0.05) if not all_points.is_empty() else Vector2.ZERO
			var finish:=mid+out_dir*side*0.75
			var track:=_wander(start,finish,index*131+7)
			_line(painter,track,0.0012,0.78,Color(1,0,0))
			_line(painter,track,0.0030,0.22,Color(0,1,0))
	for work in works:
		var at:Vector2=work.at
		var building:=String(work.state)=="building"
		_disc(painter,at,0.030,0.30 if building else 0.18,Color(1,0,0))
		if building:_disc(painter,at+Vector2(0.018,0.012),0.008,0.75,Color(1,0,0))
		var start:=_nearest_point(all_points,at)
		if start.distance_to(at)>0.012 and start.distance_to(at)<0.5:
			_line(painter,_wander(start,at,hash(work.id)),0.0012,0.80 if building else 0.55,Color(1,0,0))
	# --- B: ash, midden, burnt ground ----------------------------------------
	if hearth_found:
		_disc(painter,hearth,0.0014,0.80,Color(0,0,1))
		_disc(painter,hearth,0.0028,0.22,Color(0,0,1))
	for plot in plots:
		var form:=String(plot.get("form",""))
		if form=="refuse_and_latrine_ground" and String(plot.get("status","active"))!="reclaimed":
			var c:=_v2(plot.get("centroid",Vector2.ZERO))
			_disc(painter,c,0.0026,0.55,Color(0,0,1))
			_disc(painter,c+Vector2(0.0024,-0.0012),0.0014,0.45,Color(0,0,1))
	for record in buildings:
		var plot:Dictionary=record.plot
		var fire:=clampf(float(plot.get("damage",{}).get("fire",0.0)),0.0,1.0)
		if String(plot.get("status","active"))=="ruin" or fire>0.2:
			_disc(painter,Vector2(record.position),float(record.get("radius",0.003))*0.85,0.28+0.45*fire,Color(0,0,1))
	image.generate_mipmaps()
	# --- Worked ground: fields and kitchen gardens ---------------------------
	var worked:=Image.create_empty(RES,RES,false,Image.FORMAT_RGBA8)
	worked.fill(Color(0,0,0,0))
	var field_count:=0
	for plot in plots:
		if String(plot.get("land_use",""))!="field" or String(plot.get("status","active")) in ["reclaimed"]:continue
		var polygon:=_polygon(plot)
		if polygon.size()<3:continue
		_fill_polygon(worked,corner,side/float(RES),polygon,_field_code(plot,polygon))
		field_count+=1
	# Kitchen gardens behind some homes, once the people cultivate at all.
	var gardens:=0
	if field_count>0 or float(shares.get("farm",0.0))>0.0:
		for record in buildings:
			var plot:Dictionary=record.plot
			if not _alive(plot) or String(plot.get("land_use","")) not in ["residential_compound","mixed_household"]:continue
			if absi(int(plot.get("seed",0))+int(record.get("variant",0))*7+roundi(Vector2(record.position).x*1e5))%3==0:continue
			var at:=Vector2(record.position)
			var angle:=float(record.angle)
			var back:=-Vector2(sin(angle),cos(angle))
			var radius:=maxf(float(record.get("radius",0.003)),0.0018)
			var middle:=at+back*(radius+0.0042)
			var across:=back.orthogonal()
			var half:=Vector2(0.0022,0.0030)
			var bed:=PackedVector2Array([middle-across*half.x-back*half.y,middle+across*half.x-back*half.y,middle+across*half.x+back*half.y,middle-across*half.x+back*half.y])
			var clear:=true
			for other in buildings:
				if other!=record and Vector2(other.position).distance_to(middle)<float(other.get("radius",0.003))+0.004:clear=false;break
			if not clear:continue
			_fill_polygon(worked,corner,side/float(RES),bed,Color(1.0,fposmod(angle,PI)/PI,(2.0+8.0*4.0+64.0)/255.0,(4.0*16.0+6.0)/255.0))
			gardens+=1
			if gardens>=48:break
	var world:=Vector2(center.x,center.z)+corner
	var hi:=Vector2(floorf(world.x/64.0)*64.0,floorf(world.y/64.0)*64.0)
	var lo:=world-hi
	var paint_report:={"fields":field_count,"gardens":gardens,"size_m":roundi(side*1000.0),"texel_m":snappedf(side*1000.0/RES,0.01),"stamps":int(painter.stamps),"build_usec":Time.get_ticks_usec()-began,"slot":slot}
	if frame.has_area():
		tile_builds+=1
		_tile_cache[key]={"ground":image,"fields":worked,"origin":Vector4(hi.x,hi.y,lo.x,lo.y),"frame":Vector4(side,1.0,side/18.0,0.0),"report":paint_report}
		while _tile_cache.size()>MAX_TILE_CACHE:_tile_cache.erase(_tile_cache.keys()[0])
		if cache_only:return
	_store(slot,image,worked)
	slot_centers[slot]=Vector2(center.x,center.z)
	slot_origins[slot]=Vector4(hi.x,hi.y,lo.x,lo.y)
	slot_frames[slot]=Vector4(side,1.0,0.0,0.0)
	slot_noise_offsets[slot]=corner*1000.0 if slot==0 or frame.has_area() else Vector2.ZERO
	if frame.has_area():slot_frames[slot].z=side/18.0;slot_centers[slot]=Vector2(center.x,center.z)+frame.get_center()
	# The cultivated halo: wider for a bigger, longer-farmed place; mostly
	# pasture and clearings where nobody farms yet.
	var farmed:=field_count>0 or float(shares.get("farm",0.0))>0.0
	var halo_km:=clampf(0.26+sqrt(float(maxi(buildings.size(),1)))*0.035+sqrt(float(field_count))*0.06,0.30,1.4)
	var orchards:=0.0
	for entry in GameState.discovery_log:
		if entry is Dictionary and String(entry.get("id","")) in ["fruit_tree_grafting","terraced_orchards","orchard","nut_orchards","citrus_orchards"]:orchards=1.0;break
	slot_halos[slot]=Vector4(halo_km,1.0 if slot==0 else 0.85,0.65 if farmed else 0.2,orchards if slot==0 else 0.0)
	# Home land use now streams from actual records across the camera view.
	# The old synthetic field halo would overlay invented parcels and clear
	# woodland through the recorded neighborhoods. Other places retain it.
	if slot==0 or frame.has_area():slot_halos[slot]=Vector4.ZERO
	slot_reports[slot]=paint_report
	if slot==0:
		if texture==null:texture=ImageTexture.create_from_image(image)
		else:texture.update(image)
		if fields_texture==null:fields_texture=ImageTexture.create_from_image(worked)
		else:fields_texture.update(worked)
		origin_hi=hi;origin_lo=lo;size_km=side;strength=1.0;signature=key
		report=slot_reports[0]
	_apply_all()

## Writes one slot's images into the shared texture arrays (created blank on
## first use: every layer the same size, format and mip chain).
static func _store(slot:int,ground:Image,worked:Image)->void:
	if ground_layers==null:
		var blank_ground:=Image.create_empty(RES,RES,true,Image.FORMAT_RGBA8)
		var blank_fields:=Image.create_empty(RES,RES,false,Image.FORMAT_RGBA8)
		var grounds:Array[Image]=[];var fields:Array[Image]=[]
		for i in SLOTS:
			grounds.append(blank_ground);fields.append(blank_fields)
		ground_layers=Texture2DArray.new();ground_layers.create_from_images(grounds)
		field_layers=Texture2DArray.new();field_layers.create_from_images(fields)
	ground_layers.update_layer(ground,slot)
	field_layers.update_layer(worked,slot)

## A slot's painted square (world km): origin corner and side.
static func slot_rect(slot:int)->Rect2:
	var o:=slot_origins[slot]
	return Rect2(Vector2(o.x+o.z,o.y+o.w),Vector2.ONE*slot_frames[slot].x)

const PHASES:=["","prepared","growing","mature","harvested","fallow","stressed"]
const PATTERNS:=["smallholder_mosaic","irrigated_beds","dryland_patchwork","consolidated_field_strips"]
const CROPS:=["grain","roots","pulses","fibre_crop","garden_beds"]

## A field's look for the shader: R cover, G row angle (0..pi), B phase +
## 8 x pattern (4 = kitchen garden) + 64 if hands are working it,
## A crop family x 16 + cover (0-15).
static func _field_code(plot:Dictionary,polygon:PackedVector2Array)->Color:
	# Rows run along the field's longest side.
	var longest:=0.0;var angle:=0.0
	for i in polygon.size():
		var edge:=polygon[(i+1)%polygon.size()]-polygon[i]
		if edge.length()>longest:longest=edge.length();angle=atan2(edge.y,edge.x)
	var phase:=maxi(PHASES.find(String(plot.get("cultivation_phase","prepared"))),1)
	var pattern:=maxi(PATTERNS.find(String(plot.get("field_pattern","smallholder_mosaic"))),0)
	var working:=1 if int(plot.get("worker_count",0))>0 and String(plot.get("status","active")) not in ["vacant","ruin"] else 0
	var crop:=maxi(CROPS.find(String(plot.get("crop_family","grain"))),0)
	var cover:=clampi(roundi(clampf(float(plot.get("crop_cover",0.1)),0.0,1.0)*15.0),0,15)
	return Color(1.0,fposmod(angle,PI)/PI,float(phase+8*pattern+64*working)/255.0,float(crop*16+cover)/255.0)

static func _polygon(plot:Dictionary)->PackedVector2Array:
	var raw:Variant=plot.get("polygon",PackedVector2Array())
	if raw is PackedVector2Array:return raw
	var out:=PackedVector2Array()
	if raw is Array:
		for p in raw:out.append(_v2(p))
	return out

## Scanline fill (native fill_rect per span): exact codes, no blending.
static func _fill_polygon(image:Image,corner:Vector2,texel:float,polygon:PackedVector2Array,code:Color)->void:
	var ys:=INF;var ye:=-INF
	for p in polygon:ys=minf(ys,p.y);ye=maxf(ye,p.y)
	var row_start:=maxi(0,floori((ys-corner.y)/texel))
	var row_end:=mini(RES-1,ceili((ye-corner.y)/texel))
	for row in range(row_start,row_end+1):
		var y:=corner.y+(float(row)+0.5)*texel
		var crossings:Array[float]=[]
		for i in polygon.size():
			var a:=polygon[i];var b:=polygon[(i+1)%polygon.size()]
			if (a.y<=y and b.y>y) or (b.y<=y and a.y>y):
				crossings.append(a.x+(y-a.y)/(b.y-a.y)*(b.x-a.x))
		crossings.sort()
		for k in range(0,crossings.size()-1,2):
			var x0:=maxi(0,roundi((crossings[k]-corner.x)/texel))
			var x1:=mini(RES,roundi((crossings[k+1]-corner.x)/texel))
			if x1>x0:image.fill_rect(Rect2i(x0,row,x1-x0,1),code)

## The home settlement's great works near `center`: site (settlement-local
## km), id and whether it is still rising.
static func _works_near(center:Vector3)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var home:=Vector2(center.x,center.z)
	for city in GameState.player_settlements:
		if not city is Dictionary:continue
		var point:=_v2(city.get("position",Vector2.INF))
		if point.distance_to(home)>0.25:continue
		var index:=0
		for r in city.get("undertakings",[]):
			if not r is Dictionary:continue
			var site:Dictionary=r.get("site",{"position":point+Vector2(0.18+index*0.12,0.16)})
			index+=1
			var at:=_v2(site.get("position",point))-home
			if at.length()>MAX_SIZE_KM*0.45:continue
			var status:=String(r.get("status",""))
			out.append({"at":at,"id":String(r.get("id","")),"state":"building" if status in ["building","stalled"] else status})
			if out.size()>=8:return out
	return out

static func _alive(plot:Dictionary)->bool:
	return String(plot.get("status","active")) not in ["vacant","reclaimed","ruin"]

static func _labour()->Dictionary:
	# Shares of the working people, from the real allocation (living_map.gd).
	var living:=preload("res://scripts/living_map.gd")
	var shares:Dictionary=living.activity_shares()
	var total:=0.0
	for key in shares:total+=float(shares[key])
	var out:Dictionary={}
	if total<=0.0:return out
	for key in shares:out[key]=float(shares[key])/total*4.0
	return out

static func _fabric_key(plots:Array[Dictionary])->int:
	var parts:=[]
	for plot in plots:parts.append([int(plot.get("id",0)),plot.get("status",""),plot.get("form",""),plot.get("land_use",""),_v2(plot.get("centroid",Vector2.ZERO)),_polygon(plot),plot.get("area_ha",0.01),plot.get("cultivation_phase","prepared"),plot.get("field_pattern","smallholder_mosaic"),plot.get("crop_family","grain"),roundi(float(plot.get("crop_cover",0.1))*15.0),int(plot.get("worker_count",0))>0,plot.get("seed",0)])
	return hash(parts)

static func _building_key(buildings:Array)->int:
	var parts:=[]
	for record in buildings:
		var plot:Dictionary=record.get("plot",{})
		parts.append([Vector2(record.get("position",Vector2.ZERO)),snappedf(float(record.get("angle",0.0)),0.01),record.get("radius",0.003),record.get("variant",0),plot.get("status","active"),plot.get("land_use",""),plot.get("frontage_route_id",-1),plot.get("seed",1),plot.get("damage",{}).get("fire",0.0)])
	return hash(parts)

static func _route_key(routes:Array[Dictionary])->int:
	var parts:=[]
	for route in routes:parts.append([int(route.get("id",0)),bool(route.get("active",true)),snappedf(float(route.get("traffic",0.0)),0.1),_points(route),route.get("width_m",1.0),route.get("hierarchy","path"),route.get("kind","desire_path"),route.get("surface_tier",0)])
	return hash(parts)

static func _v2(value:Variant)->Vector2:
	if value is Vector2:return value
	if value is Vector3:return Vector2((value as Vector3).x,(value as Vector3).z)
	return Vector2.ZERO

static func _points(route:Dictionary)->PackedVector2Array:
	var raw:Variant=route.get("points",PackedVector2Array())
	if raw is PackedVector2Array:return raw
	var out:=PackedVector2Array()
	if raw is Array:
		for p in raw:out.append(_v2(p))
	return out

static func _plot_radius(plot:Dictionary)->float:
	return sqrt(maxf(float(plot.get("area_ha",0.01)),0.0001)/100.0/PI)

static func _nearest_on(points:PackedVector2Array,to:Vector2)->Vector2:
	var best:=to;var distance:=INF
	for i in range(1,points.size()):
		var p:=Geometry2D.get_closest_point_to_segment(to,points[i-1],points[i])
		if p.distance_squared_to(to)<distance:best=p;distance=p.distance_squared_to(to)
	return best

static func _nearest_point(points:PackedVector2Array,to:Vector2)->Vector2:
	var best:=Vector2.ZERO;var distance:=INF
	for p in points:
		if p.distance_squared_to(to)<distance:best=p;distance=p.distance_squared_to(to)
	return best

static func _polygon_near(plot:Dictionary,to:Vector2)->Vector2:
	var polygon:Variant=plot.get("polygon",PackedVector2Array())
	var c:=_v2(plot.get("centroid",Vector2.ZERO))
	if not polygon is PackedVector2Array or (polygon as PackedVector2Array).size()<3:return c
	var best:=c;var distance:=INF
	var poly:PackedVector2Array=polygon
	for i in poly.size():
		var p:=Geometry2D.get_closest_point_to_segment(to,poly[i],poly[(i+1)%poly.size()])
		if p.distance_squared_to(to)<distance:best=p;distance=p.distance_squared_to(to)
	return best

## A footpath bends a little, the way people actually walk.
static func _wander(a:Vector2,b:Vector2,seed_value:int)->PackedVector2Array:
	var out:=PackedVector2Array([a])
	var length:=a.distance_to(b)
	if length<0.004:
		out.append(b);return out
	var side:=(b-a).orthogonal().normalized()
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var steps:=clampi(int(length/0.006),2,12)
	var drift:=0.0
	for i in range(1,steps):
		var t:=float(i)/float(steps)
		drift=clampf(drift+rng.randf_range(-0.35,0.35),-1.0,1.0)
		out.append(a.lerp(b,t)+side*drift*length*0.06*sin(t*PI))
	out.append(b)
	return out

# --- Rasterizing: soft brush stamps blended with Image.blend_rect (native) ----

static func _brush(radius_px:float,alpha:float,channel:Color)->Image:
	var r:=clampf(snappedf(radius_px,0.5),0.5,96.0)
	var a:=snappedf(clampf(alpha,0.02,1.0),0.02)
	var key:="%s|%s|%s" % [r,a,channel.to_html(false)]
	if _brushes.has(key):return _brushes[key]
	var n:=int(ceil(r))*2+2
	var image:=Image.create_empty(n,n,false,Image.FORMAT_RGBA8)
	var half:=float(n)*0.5
	for y in n:
		for x in n:
			var d:=Vector2(float(x)+0.5-half,float(y)+0.5-half).length()/maxf(r,0.5)
			var k:=1.0-smoothstep(0.55,1.0,d)
			image.set_pixel(x,y,Color(channel.r,channel.g,channel.b,a*k))
	if _brushes.size()>256:_brushes.clear()
	_brushes[key]=image
	return image

static func _stamp(painter:Dictionary,at:Vector2,radius:float,alpha:float,channel:Color)->void:
	var texel:float=painter.texel
	# Reject off-tile stamps before generating an expensive brush.
	var extent:=radius+texel*2.0
	if not Rect2(Vector2(painter.corner),Vector2.ONE*texel*RES).grow(extent).has_point(at):return
	var brush:=_brush(radius/texel,alpha,channel)
	var p:=(at-Vector2(painter.corner))/texel
	var n:=brush.get_width()
	var dst:=Vector2i(roundi(p.x-float(n)*0.5),roundi(p.y-float(n)*0.5))
	if dst.x>=RES or dst.y>=RES or dst.x+n<=0 or dst.y+n<=0:return
	(painter.image as Image).blend_rect(brush,Rect2i(0,0,n,n),dst)
	painter.stamps=int(painter.stamps)+1

static func _disc(painter:Dictionary,at:Vector2,radius:float,alpha:float,channel:Color)->void:
	_stamp(painter,at,radius,alpha,channel)

## A line of overlapping stamps; `alpha` is the line's final strength (the
## per-stamp alpha is lowered for the overlap).
static func _line(painter:Dictionary,points:PackedVector2Array,radius:float,alpha:float,channel:Color)->void:
	if points.size()<2:return
	var texel:float=painter.texel
	var spacing:=maxf(radius*0.45,texel*0.7)
	var overlap:=maxf(1.0,radius*2.0/spacing*0.55)
	var per:=1.0-pow(1.0-clampf(alpha,0.0,0.98),1.0/overlap)
	# A line uses one brush. Resolve its cached image and immutable painting
	# state once, rather than format a cache key and unpack a Dictionary for
	# every overlapping stamp (tens of thousands in a developed quarter).
	var image:Image=painter.image
	var corner:Vector2=painter.corner
	var bounds:=Rect2(corner,Vector2.ONE*texel*RES).grow(radius+texel*2.0)
	var brush:Image
	var source:=Rect2i()
	var n:=0
	var half:=0.0
	var stamps:=0
	for i in range(1,points.size()):
		var a:=points[i-1];var b:=points[i]
		var length:=a.distance_to(b)
		var steps:=maxi(1,ceili(length/spacing))
		# Clip the iteration, not the segment: adjacent tiles keep identical
		# stamp positions, while a long road costs only its on-tile length.
		var window:=_line_window(a,b,bounds)
		if window.x>window.y:continue
		if brush==null:
			brush=_brush(radius/texel,per,channel)
			n=brush.get_width();half=float(n)*0.5;source=Rect2i(0,0,n,n)
		for s in range(maxi(0,floori(window.x*steps)),mini(steps,ceili(window.y*steps)+1)):
			var at:=a.lerp(b,float(s)/float(steps))
			if not bounds.has_point(at):continue
			var p:=(at-corner)/texel
			var dst:=Vector2i(roundi(p.x-half),roundi(p.y-half))
			if dst.x>=RES or dst.y>=RES or dst.x+n<=0 or dst.y+n<=0:continue
			image.blend_rect(brush,source,dst)
			stamps+=1
	painter.stamps=int(painter.stamps)+stamps
	_stamp(painter,points[points.size()-1],radius,per,channel)

static func _line_window(a:Vector2,b:Vector2,rect:Rect2)->Vector2:
	var low:=0.0;var high:=1.0
	var delta:=b-a
	for axis in 2:
		if absf(delta[axis])<0.000000001:
			if a[axis]<rect.position[axis] or a[axis]>rect.end[axis]:return Vector2(1,0)
			continue
		var first:float=(rect.position[axis]-a[axis])/delta[axis]
		var last:float=(rect.end[axis]-a[axis])/delta[axis]
		low=maxf(low,minf(first,last));high=minf(high,maxf(first,last))
		if low>high:return Vector2(1,0)
	return Vector2(low,high)
