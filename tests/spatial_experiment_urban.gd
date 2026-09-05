extends RefCounted
## A bounded 2km active front within a hypothetical larger metropolitan fabric.
## Synthetic street/building costs: NOT extracted from current settlement art.
var grid:AStarGrid2D
var cells:=0
var resolution:=0.025
var solid_count:=0
var identity:=0

func build(cell_km:float,front_id:int=0,span_km:float=2.0)->void:
	resolution=cell_km
	identity=front_id
	cells=roundi(span_km/resolution)+1
	grid=AStarGrid2D.new()
	grid.region=Rect2i(0,0,cells,cells)
	grid.cell_size=Vector2.ONE*resolution
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic=AStarGrid2D.HEURISTIC_OCTILE
	grid.default_estimate_heuristic=AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	for y in cells:
		for x in cells:
			var point:=Vector2(x,y)*resolution
			var blocked:=building_at(point,front_id)
			grid.set_point_solid(Vector2i(x,y),blocked)
			if blocked: solid_count+=1

func impossible_path()->PackedVector2Array:
	var goal:=Vector2i(cells-1,cells-1)
	for point in [goal+Vector2i(-1,0),goal+Vector2i(0,-1),goal+Vector2i(-1,-1)]: grid.set_point_solid(point,true)
	return grid.get_point_path(Vector2i.ZERO,goal)

static func building_at(point:Vector2,front_id:int=0)->bool:
	# 20m streets separating80m blocks; a broad curved river-side avenue remains
	# continuous. Suburbs lose some blocks but retain the same street network.
	var local_x:=fposmod(point.x,0.1)
	var local_y:=fposmod(point.y,0.1)
	if local_x<0.012 or local_x>0.088 or local_y<0.012 or local_y>0.088: return false
	if absf(point.y-(0.8+sin(point.x*2.0)*0.16))<0.035: return false
	var block:=Vector2i(floori(point.x/0.1),floori(point.y/0.1))
	if point.x>1.2 and posmod(block.x*31+block.y*17+front_id,4)==0: return false
	return true

func path(number:int)->PackedVector2Array:
	# Endpoints stay on streets at every tested resolution.
	var row:=roundi(float(number%10)*0.1/resolution)
	var target_row:=roundi((1.0+float(number%10)*0.1)/resolution)
	return grid.get_point_path(Vector2i(0,row),Vector2i(cells-1,target_row))

func changed_control(number:int)->void:
	# Local battle/control change invalidates a small blocked-edge neighborhood;
	# no global city rebuild is needed. These are costs, not ownership rules.
	var center:=Vector2i(roundi((0.3+float(number%10)*0.1)/resolution),roundi(1.0/resolution))
	for y in range(-2,3):
		for x in range(-2,3):
			var point:=center+Vector2i(x,y)
			if grid.is_in_boundsv(point) and not grid.is_point_solid(point): grid.set_point_weight_scale(point,1.0+float(number%4)*0.5)

func compressed(path_points:PackedVector2Array)->PackedVector2Array:
	if path_points.size()<3: return path_points
	var result:=PackedVector2Array([path_points[0]])
	for index in range(1,path_points.size()-1):
		var before:Vector2=(path_points[index]-path_points[index-1]).normalized()
		var after:Vector2=(path_points[index+1]-path_points[index]).normalized()
		if before.distance_to(after)>0.001: result.append(path_points[index])
	result.append(path_points[-1])
	return result
