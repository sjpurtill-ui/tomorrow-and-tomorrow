extends RefCounted
## Private, bounded display parcels. Uses the root's exact geometry and built
## forms; never creates people, supplies, construction or simulation settlements.
const GEOMETRY=preload("res://scripts/settlement_plot_geometry.gd")
const MAX_SEEDS:=24
const MAX_PARCELS:=24
const MAX_OBSTACLES:=64
const NUCLEUS_SCALE:=8.0
static var _centres:Dictionary={}

static func centres(seed_value:int,count:int,root_radius:float)->Array[Vector2]:
	var key:=str([seed_value,snappedf(root_radius,0.001)])
	if not _centres.has(key):
		if _centres.size()>=16:_centres.erase(_centres.keys()[0])
		var parcel:=GEOMETRY.irregular_polygon(Vector2.ZERO,root_radius/NUCLEUS_SCALE,seed_value)
		_centres[key]={"points":[],"plots":[{"id":0,"centroid":Vector2.ZERO,"polygon":parcel,"land_use":"communal","status":"active"}],"routes":[]}
	var state:Dictionary=_centres[key]
	while state.points.size()<mini(count,MAX_SEEDS):
		var index:int=state.points.size()+1
		var nuclei:Array=[{"id":1,"position":Vector2.ZERO,"pull":1.0,"active":true}]
		var proposal:=GEOMETRY.household(seed_value,index,state.plots,state.routes,nuclei)
		if proposal.is_empty():break
		var at:=GEOMETRY.polygon_centroid(proposal.polygon)
		var nearest:=Vector2.ZERO;var distance:=at.length()
		for point:Vector2 in state.points:
			if at.distance_to(point)<distance:nearest=point;distance=at.distance_to(point)
		state.points.append(at)
		# A seed reserves room for the same founding parcels the root begins with.
		state.plots.append({"id":index,"centroid":at,"polygon":GEOMETRY.irregular_polygon(at,0.070/NUCLEUS_SCALE,seed_value+index),"land_use":"mixed_household","status":"active"})
		state.routes.append({"id":index,"points":GEOMETRY.route_points(at,nearest,index,seed_value),"active":true})
	var result:Array[Vector2]=[]
	for point:Vector2 in (state.points as Array).slice(0,count):result.append(point*NUCLEUS_SCALE)
	return result

static func begin(record:Dictionary,previous:Dictionary={})->Dictionary:
	var spec:Dictionary=record.get("settlement_growth",{})
	var state:=previous.duplicate(true)
	if state.is_empty():state={"plots":[],"routes":[],"next":0}
	state["seed"]=int(spec.get("seed",hash(record.get("id",""))))
	state["target"]=clampi(int(spec.get("parcels",6)),1,MAX_PARCELS)
	state["origin"]=record.get("position",Vector2.ZERO)
	state["templates"]=spec.get("templates",[])
	state["obstacles"]=spec.get("obstacles",[])
	state["neighbours"]=spec.get("neighbours",[])
	state["nuclei"]=[{"id":1,"position":Vector2.ZERO,"pull":1.0,"active":true}]
	return state

## Stable neighboring claims prevent two independently prepared seeds sharing
## a roof footprint. These edges are constraints only, never drawn as cells.
static func owns(spec:Dictionary,point:Vector2)->bool:
	for neighbour:Vector2 in spec.get("neighbours",[]):
		if point.distance_squared_to(neighbour)<point.length_squared():return false
	return true

## Exactly one founding/growth claim per cooperative renderer step. Existing
## claims and routes are retained when population rises, including old centres.
static func advance(state:Dictionary,land_world:Callable,height_world:Callable)->bool:
	if int(state.next)>=int(state.target):return true
	var index:=int(state.next);state.next=index+1
	var seed_value:=int(state.seed);var plot_id:=index+1
	var origin:Vector2=state.origin
	var context:={"settlement_origin":Vector3(origin.x,0,origin.y)}
	context["buildable_land_at"]=func(x:float,z:float)->bool:return owns(state,Vector2(x,z)-origin) and (not land_world.is_valid() or bool(land_world.call(Vector2(x,z))))
	if height_world.is_valid():context["terrain_height_at"]=func(x:float,z:float)->float:return float(height_world.call(Vector2(x,z)))
	var plots:Array=state.plots
	var occupied:Array=plots.duplicate(false);occupied.append_array(state.obstacles)
	var plot_seed:=hash("%d:settlement_plot:%d" % [seed_value,plot_id])
	var rng:=RandomNumberGenerator.new();rng.seed=plot_seed
	var polygon:=PackedVector2Array()
	if index==0:
		if GEOMETRY.site_score(Vector2.ZERO,0.009,"communal",occupied,state.routes,state.nuclei,context)>-9000.0:
			polygon=GEOMETRY.irregular_polygon(Vector2.ZERO,0.009,plot_seed)
	elif index<6:
		var radius:=rng.randf_range(0.0065,0.0105)
		for attempt in 32:
			var center:=GEOMETRY.founding_center(seed_value,index,5,"residential_compound",rng,attempt)
			if GEOMETRY.site_score(center,radius,"residential_compound",occupied,state.routes,state.nuclei,context)<=-9000.0:continue
			polygon=GEOMETRY.irregular_polygon(center,radius,plot_seed);break
	else:
		var proposal:=GEOMETRY.household(seed_value,plot_id,occupied,state.routes,state.nuclei,context)
		if not proposal.is_empty():polygon=proposal.polygon;plot_seed=int(proposal.seed)
	if polygon.is_empty():return int(state.next)>=int(state.target)
	var center:=GEOMETRY.polygon_centroid(polygon)
	var templates:Array=state.templates
	var plot:Dictionary=templates[posmod(hash(str(plot_seed)+":form"),templates.size())].duplicate(true) if not templates.is_empty() else {"form":"portable_shelter_cluster","roof_plan":"ridge_light_shelter","material_family":"organic","storeys":1}
	plot.merge({"id":plot_id,"seed":plot_seed,"polygon":polygon,"centroid":center,"area_ha":GEOMETRY.polygon_area_km2(polygon)*100.0,
		"land_use":"mixed_household" if index%4==1 else "residential_compound","status":"active","roof_coverage":0.24,
		"condition":0.82,"resident_count":0,"resident_capacity":0,"frontage_route_id":plot_id,"nucleus_id":1},true)
	if index==0:plot.merge({"land_use":"communal","form":"open_hearth_yard","roof_coverage":0.0},true)
	var nearest:=Vector2.ZERO;var distance:=INF
	for prior:Dictionary in plots:
		var point:Vector2=prior.centroid
		if center.distance_to(point)<distance:nearest=point;distance=center.distance_to(point)
	state.routes.append({"id":plot_id,"kind":"desire_path","points":GEOMETRY.route_points(center,nearest,plot_id,seed_value,index<5),"width_m":0.9,"condition":0.4,"active":true})
	plots.append(plot)
	return int(state.next)>=int(state.target)
