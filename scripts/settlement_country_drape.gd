extends RefCounted
## Split presentation ink along the actual regional mesh, without height queries.
## Grid = (world center x, world center z, width km, vertices per side), matching
## rendered_surface_height.gd. Coordinates inside the algorithm are grid cells.
const MAX_CELLS:=64
const MAX_ROWS:=128
const MAX_OUTPUT_TRIANGLES:=MAX_CELLS*8
const EPSILON:=0.000001


## Returns only the intersection with the grid. Empty means outside, invalid,
## or over budget; triangle_status distinguishes these cases. Every returned
## triangle is inside one of the grid's alternating terrain facets.
static func split_triangle(a:Vector2,b:Vector2,c:Vector2,ca:Color,cb:Color,cc:Color,grid:Vector4)->Array:
	var prepared:=_prepare(a,b,c,ca,cb,cc,grid)
	if prepared.status not in ["inside","clipped"]:return []
	var source:Array=prepared.source
	var triangles:Array=[]
	for span:Vector3i in prepared.row_spans:
		var z:=span.x
		for x in range(span.y,span.z+1):
			var first:=Vector2(x,z);var second:=first+Vector2.RIGHT
			var third:=first+Vector2.ONE;var fourth:=first+Vector2.DOWN
			var facets:Array=[[first,second,third],[first,third,fourth]] if (x+z)%2==0 else [[first,second,fourth],[third,fourth,second]]
			for facet:Array in facets:
				var polygon:=source
				for edge in 3:
					polygon=_clip(polygon,facet[edge],facet[(edge+1)%3])
					if polygon.size()<3:break
				for index in range(1,polygon.size()-1):
					if absf(_cross(polygon[index].point-polygon[0].point,polygon[index+1].point-polygon[0].point))<=EPSILON:continue
					var triangle:Array=[]
					for vertex:Dictionary in [polygon[0],polygon[index],polygon[index+1]]:
						triangle.append({"point":_world(vertex.point,grid),"color":vertex.color})
					triangles.append(triangle)
	assert(triangles.size()<=MAX_OUTPUT_TRIANGLES)
	return triangles


## Bounded preparation: clip to the grid, then at most MAX_ROWS row slabs.
## row_spans contains (row, first x cell, last x cell). Counting these narrow
## intervals admits diagonal strips without charging their empty bbox corners.
## No mesh cell is visited if their combined count exceeds MAX_CELLS.
static func triangle_status(a:Vector2,b:Vector2,c:Vector2,grid:Vector4)->Dictionary:
	var result:=_prepare(a,b,c,Color.WHITE,Color.WHITE,Color.WHITE,grid)
	result.erase("source")
	return result


static func contains_all(a:Vector2,b:Vector2,c:Vector2,grid:Vector4)->bool:
	if not _valid_grid(grid):return false
	for point:Vector2 in [a,b,c]:
		if not point.is_finite() or maxf(absf(point.x-grid.x),absf(point.y-grid.y))>grid.z*0.5:return false
	return true


static func _prepare(a:Vector2,b:Vector2,c:Vector2,ca:Color,cb:Color,cc:Color,grid:Vector4)->Dictionary:
	var spans:Array[Vector3i]=[]
	var result:={"status":"invalid","cell_min":Vector2i.ZERO,"cell_max":Vector2i(-1,-1),"cell_count":0,"row_spans":spans,"rows_scanned":0}
	if not _valid_grid(grid) or not a.is_finite() or not b.is_finite() or not c.is_finite():return result
	var source:Array=[{"point":_cell(a,grid),"color":ca},{"point":_cell(b,grid),"color":cb},{"point":_cell(c,grid),"color":cc}]
	if absf(_cross(source[1].point-source[0].point,source[2].point-source[0].point))<=EPSILON:return result
	result["source"]=source
	var end:=float(int(grid.w)-1)
	var corners:Array[Vector2]=[Vector2.ZERO,Vector2(end,0),Vector2(end,end),Vector2(0,end)]
	var clipped:=source
	for index in 4:
		clipped=_clip(clipped,corners[index],corners[(index+1)%4])
		if clipped.size()<3:
			result.status="outside"
			return result
	var low:Vector2=clipped[0].point;var high:=low
	for vertex:Dictionary in clipped:
		low=low.min(vertex.point);high=high.max(vertex.point)
	var last_cell:=int(grid.w)-2
	result.cell_min=Vector2i(clampi(floori(low.x),0,last_cell),clampi(floori(low.y),0,last_cell))
	result.cell_max=Vector2i(clampi(ceili(high.x)-1,0,last_cell),clampi(ceili(high.y)-1,0,last_cell))
	if result.cell_max.y-result.cell_min.y+1>MAX_ROWS:
		result.status="budget_exceeded"
		# A non-degenerate convex polygon crossing this many rows necessarily
		# needs more than MAX_CELLS. This is a lower bound, not a full count.
		result.cell_count=MAX_CELLS+1
		return result
	for row in range(result.cell_min.y,result.cell_max.y+1):
		result.rows_scanned+=1
		var slab:=_clip(clipped,Vector2(0,row),Vector2(1,row))
		slab=_clip(slab,Vector2(1,row+1),Vector2(0,row+1))
		if slab.size()<3:continue
		var first_x:float=slab[0].point.x;var last_x:=first_x
		for vertex:Dictionary in slab:
			first_x=minf(first_x,float(vertex.point.x));last_x=maxf(last_x,float(vertex.point.x))
		var x_low:=clampi(floori(first_x),0,last_cell)
		var x_high:=clampi(ceili(last_x)-1,0,last_cell)
		result.cell_count+=maxi(0,x_high-x_low+1)
		if int(result.cell_count)>MAX_CELLS:
			result.status="budget_exceeded"
			return result
		if x_high>=x_low:spans.append(Vector3i(row,x_low,x_high))
	result.status="inside" if contains_all(a,b,c,grid) else "clipped"
	return result


static func _valid_grid(grid:Vector4)->bool:
	# Vector2i cell indices use 32 bits. Real regional grids are much smaller.
	return grid.is_finite() and grid.z>0.0 and grid.w>=2.0 and grid.w<=2147483647.0


static func _cell(point:Vector2,grid:Vector4)->Vector2:
	return ((point-Vector2(grid.x,grid.y))/grid.z+Vector2(0.5,0.5))*float(int(grid.w)-1)


static func _world(point:Vector2,grid:Vector4)->Vector2:
	return Vector2(grid.x,grid.y)+(point/float(int(grid.w)-1)-Vector2(0.5,0.5))*grid.z


## Sutherland-Hodgman against the left half-plane of a directed facet edge.
## Colors follow the same edge parameter as positions, preserving the source
## triangle's affine RGBA field through clipping and fan triangulation.
static func _clip(polygon:Array,a:Vector2,b:Vector2)->Array:
	if polygon.is_empty():return []
	var output:Array=[]
	var edge:=b-a
	var previous:Dictionary=polygon[-1]
	var previous_distance:=_cross(edge,previous.point-a)
	for current:Dictionary in polygon:
		var distance:=_cross(edge,current.point-a)
		var inside:=distance>=0.0
		if inside!=(previous_distance>=0.0):
			var t:=clampf(previous_distance/(previous_distance-distance),0.0,1.0)
			var point:Vector2=(previous.point as Vector2).lerp(current.point,t)
			# Keep a generated intersection exactly on this grid-cell edge.
			var normal:=Vector2(-edge.y,edge.x)
			point-=normal*(_cross(edge,point-a)/maxf(edge.length_squared(),EPSILON))
			_append(output,{"point":point,"color":(previous.color as Color).lerp(current.color,t)})
		if inside:_append(output,current)
		previous=current;previous_distance=distance
	if output.size()>1 and (output[0].point as Vector2).distance_squared_to(output[-1].point)<=EPSILON*EPSILON:output.pop_back()
	return output


static func _append(output:Array,vertex:Dictionary)->void:
	if output.is_empty() or (output[-1].point as Vector2).distance_squared_to(vertex.point)>EPSILON*EPSILON:output.append(vertex)


static func _cross(a:Vector2,b:Vector2)->float:
	return float(a.x)*float(b.y)-float(a.y)*float(b.x)
