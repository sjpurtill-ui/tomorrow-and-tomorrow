extends RefCounted
## The root settlement's geometry, shared by simulation and bounded visual seeds.
## Coordinates are local kilometres. Terrain callbacks receive world X/Z via
## context.settlement_origin; visibility is deliberately not a placement input.
## Arrays and caller dictionaries are never changed. An optional caller RNG is
## consumed exactly as the simulation's original household selector consumed it.

const HOUSEHOLD_ATTEMPTS:=72

static func founding_center(world_seed:int,index:int,total_count:int,land_use:String,rng:RandomNumberGenerator,attempt:int)->Vector2:
	var seed_angle:=float(abs(world_seed)%6283)*0.001
	if land_use=="communal":
		return Vector2.ZERO
	if land_use=="water":
		return Vector2.from_angle(seed_angle+PI*0.82+attempt*0.17)*rng.randf_range(0.066,0.084)
	if land_use=="waste":
		return Vector2.from_angle(seed_angle-PI*0.32+attempt*0.19)*rng.randf_range(0.080,0.105)
	var cluster_count:=3
	var cluster_index:int=(index*7+absi(world_seed))%cluster_count
	var cluster_angle:=seed_angle+float(cluster_index)*TAU/float(cluster_count)+sin(float(cluster_index*19+world_seed))*0.34
	var cluster_distance:=0.014+float(cluster_index%2)*0.008+rng.randf_range(-0.002,0.003)
	var cluster_center:=Vector2.from_angle(cluster_angle)*cluster_distance
	var local_angle:=seed_angle+float(index)*2.399963229728653+float(attempt)*1.37
	var local_radius:=rng.randf_range(0.004,0.016)+float(attempt)*0.0012
	if land_use=="storage":
		cluster_center*=0.45
		local_radius*=0.48
	elif land_use=="workshop":
		cluster_center*=0.74
		local_radius*=0.72
	var position:=cluster_center+Vector2.from_angle(local_angle)*local_radius
	# Preserve the founding hearth as a real nucleus. Household claims begin beyond
	# its shared working/meeting clearance instead of accidentally occupying it first.
	if land_use in ["residential_compound","mixed_household"] and position.length()<0.014:
		position=position.normalized()*0.014 if position.length()>0.0001 else Vector2.from_angle(local_angle)*0.014
	return position

static func irregular_polygon(center:Vector2,radius:float,plot_seed:int)->PackedVector2Array:
	var rng:=RandomNumberGenerator.new()
	rng.seed=plot_seed^0x5f3759df
	var vertices:=rng.randi_range(5,8)
	var rotation:=rng.randf_range(0.0,TAU)
	var polygon:=PackedVector2Array()
	for vertex_index in vertices:
		var angle:=rotation+TAU*float(vertex_index)/float(vertices)+rng.randf_range(-0.11,0.11)
		var vertex_radius:=radius*rng.randf_range(0.72,1.18)
		polygon.append(center+Vector2(cos(angle),sin(angle))*vertex_radius)
	return polygon

static func site_score(candidate:Vector2,radius:float,land_use:String,plots:Array,routes:Array,nuclei:Array,context:Dictionary={})->float:
	# Reject occupied ground first. The remaining terms make settlement growth
	# follow inherited lanes, useful nuclei, water and buildable terrain instead of
	# adding rings around an abstract population centre.
	for existing in plots:
		var existing_radius:=sqrt(polygon_area_km2(existing.get("polygon",PackedVector2Array()))/PI)
		if candidate.distance_to(Vector2(existing.get("centroid",Vector2.ZERO)))<(radius+existing_radius)*1.18:
			return -10000.0
	var nearest_route:=INF
	for route in routes:
		if not bool(route.get("active",true)): continue
		var points:PackedVector2Array=route.get("points",PackedVector2Array())
		for point_index in points.size()-1:
			nearest_route=minf(nearest_route,Geometry2D.get_closest_point_to_segment(candidate,points[point_index],points[point_index+1]).distance_to(candidate))
	var route_access:=exp(-nearest_route/0.018) if nearest_route<INF else 0.0
	var nucleus_pull:=0.0
	var nearest_nucleus_distance:=INF
	for nucleus in nuclei:
		if not bool(nucleus.get("active",true)): continue
		var distance:=candidate.distance_to(Vector2(nucleus.get("position",Vector2.ZERO)))
		nearest_nucleus_distance=minf(nearest_nucleus_distance,distance)
		nucleus_pull=maxf(nucleus_pull,float(nucleus.get("pull",1.0))*exp(-distance/0.14))
	var core_distance:=candidate.length()
	var compactness:=exp(-nearest_nucleus_distance/0.22) if nearest_nucleus_distance<INF else exp(-core_distance/0.22)
	var edge_preference:=exp(-absf(nearest_nucleus_distance-0.095)/0.065) if nearest_nucleus_distance<INF else exp(-absf(core_distance-0.095)/0.065)
	var score:=route_access*2.8+nucleus_pull*0.72
	if land_use=="storage": score+=compactness*1.25
	elif land_use in ["workshop","dirty_industry"]: score+=edge_preference*1.12-route_access*0.10
	else: score+=compactness*0.86
	var terrain_value:=terrain_score(candidate,context)
	return terrain_value if terrain_value<=-9000.0 else score+terrain_value

static func terrain_score(candidate:Vector2,context:Dictionary={})->float:
	var score:=0.0
	var origin:Vector3=context.get("settlement_origin",Vector3.ZERO)
	var world_x:=origin.x+candidate.x
	var world_z:=origin.z+candidate.y
	var buildable_callable:Callable=context.get("buildable_land_at",Callable())
	if buildable_callable.is_valid() and not bool(buildable_callable.call(world_x,world_z)): return -10000.0
	var height_callable:Callable=context.get("terrain_height_at",Callable())
	if height_callable.is_valid():
		var sample:=0.012
		var east_west:=absf(float(height_callable.call(world_x+sample,world_z))-float(height_callable.call(world_x-sample,world_z)))
		var north_south:=absf(float(height_callable.call(world_x,world_z+sample))-float(height_callable.call(world_x,world_z-sample)))
		var slope:=maxf(east_west,north_south)/(sample*2.0)
		if slope>0.34: return -10000.0
		score-=slope*3.2
	var river_callable:Callable=context.get("river_distance_at",Callable())
	if river_callable.is_valid():
		var river_distance:=float(river_callable.call(world_x,world_z))
		if river_distance<0.025: return -10000.0
		score+=exp(-absf(river_distance-0.16)/0.20)*0.24
	return score

static func household(world_seed:int,plot_id:int,plots:Array,routes:Array,nuclei:Array,context:Dictionary={},rng:RandomNumberGenerator=null)->Dictionary:
	var plot_seed:=hash("%d:settlement_growth:%d" % [world_seed,plot_id])
	if rng==null:
		rng=RandomNumberGenerator.new()
		rng.seed=plot_seed
	var radius:=rng.randf_range(0.007,0.010)
	var center:=Vector2.ZERO
	var best_center:=Vector2.ZERO
	var best_score:=-INF
	var anchors:Array[Dictionary]=[]
	for existing in plots:
		if String(existing.get("land_use","")) in ["residential_compound","mixed_household","communal","workshop"] and String(existing.get("status","")) not in ["ruin","reclaimed"]:
			anchors.append(existing)
	if anchors.is_empty(): return {}
	var active_nuclei:Array[Dictionary]=[]
	for nucleus in nuclei:
		if bool(nucleus.get("active",true)): active_nuclei.append(nucleus)
	var target_nucleus:Dictionary=active_nuclei[absi(plot_seed)%active_nuclei.size()] if not active_nuclei.is_empty() else {"id":1,"position":Vector2.ZERO}
	var target_nucleus_position:=Vector2(target_nucleus.get("position",Vector2.ZERO))
	anchors.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		return Vector2(a.get("centroid",Vector2.ZERO)).distance_to(target_nucleus_position)<Vector2(b.get("centroid",Vector2.ZERO)).distance_to(target_nucleus_position))
	var cluster_growth:=anchors.size()>=34 and plot_id%10 in [0,1,2]
	var cluster_phase:=floori(float(plot_id)/10.0)
	var cluster_angle:=fmod(float(hash("%d:outer_cluster:%d" % [world_seed,cluster_phase]))*0.000001,TAU)
	var cluster_target:=target_nucleus_position+Vector2.from_angle(cluster_angle)*((0.090+float(cluster_phase%4)*0.014) if cluster_growth else 0.0)
	for attempt in HOUSEHOLD_ATTEMPTS:
		var anchor_index:=mini(anchors.size()-1,floori(pow(rng.randf(),2.15)*float(anchors.size())))
		if cluster_growth:
			var outer_start:=clampi(floori(float(anchors.size())*0.62),0,anchors.size()-1)
			anchor_index=rng.randi_range(outer_start,anchors.size()-1)
		var anchor:Dictionary=anchors[anchor_index]
		var anchor_center:=Vector2(anchor.get("centroid",Vector2.ZERO))
		var anchor_polygon:PackedVector2Array=anchor.get("polygon",PackedVector2Array())
		var anchor_radius:=sqrt(polygon_area_km2(anchor_polygon)/PI)
		var nucleus_outward:=anchor_center-target_nucleus_position
		var outward:=nucleus_outward.normalized() if nucleus_outward.length()>0.004 else Vector2.from_angle(rng.randf()*TAU)
		var angle:=rng.randf()*TAU
		if rng.randf()<0.28:
			angle=outward.angle()+rng.randf_range(-0.92,0.92)
		center=anchor_center+Vector2.from_angle(angle)*(anchor_radius+radius+rng.randf_range(0.0022,0.0065))
		var score:=site_score(center,radius,"residential_compound",plots,routes,nuclei,context)
		# Most households infill, but a stable seeded minority follows the outer
		# frontage so a settlement develops irregular arms rather than a disk.
		if (plot_id+world_seed)%5==0: score+=exp(-absf(center.distance_to(target_nucleus_position)-0.11)/0.075)*0.82
		if cluster_growth: score+=exp(-center.distance_to(cluster_target)/0.075)*1.48
		if score>best_score:
			best_score=score
			best_center=center
	if best_score<=-9000.0: return {}
	center=best_center
	return {"center":center,"radius":radius,"polygon":irregular_polygon(center,radius,plot_seed),"seed":plot_seed}

static func route_points(start:Vector2,finish:Vector2,plot_id:int,world_seed:int,founding:bool=false,nearest_distance:float=-1.0)->PackedVector2Array:
	if nearest_distance<0.0: nearest_distance=start.distance_to(finish)
	var direction:=finish-start
	var side:=Vector2(-direction.y,direction.x).normalized()
	if founding:
		var bend_strength:=minf(0.005,nearest_distance*0.16)
		var bend_a:=start.lerp(finish,0.34)+side*sin(float(plot_id*37+world_seed))*bend_strength
		var bend_b:=start.lerp(finish,0.69)-side*sin(float(plot_id*19+world_seed)*0.73)*bend_strength*0.68
		return PackedVector2Array([start,bend_a,bend_b,finish])
	var bend_strength:=minf(0.004,nearest_distance*0.16)
	var bend_a:=start.lerp(finish,0.36)+side*sin(float(plot_id*29+world_seed))*bend_strength
	var bend_b:=start.lerp(finish,0.72)-side*sin(float(plot_id*17+world_seed)*0.67)*bend_strength*0.62
	return PackedVector2Array([start,bend_a,bend_b,finish])

static func polygon_area_km2(polygon:PackedVector2Array)->float:
	if polygon.size()<3: return 0.0
	var twice_area:=0.0
	for index in polygon.size():
		var next:=(index+1)%polygon.size()
		twice_area+=polygon[index].x*polygon[next].y-polygon[next].x*polygon[index].y
	return absf(twice_area)*0.5

static func polygon_centroid(polygon:PackedVector2Array)->Vector2:
	if polygon.is_empty(): return Vector2.ZERO
	var sum:=Vector2.ZERO
	for point in polygon: sum+=point
	return sum/float(polygon.size())
