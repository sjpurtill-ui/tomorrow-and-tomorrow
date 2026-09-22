extends RefCounted
## Exact per-build reuse. No quantization, persistence, or cross-world cache.
var heights:Dictionary={}
var lands:Dictionary={}
var source_height:Callable
var source_land:Callable
func _init(height:Callable,land:Callable)->void:
	source_height=height;source_land=land
func height_at(x:float,z:float)->float:
	var row:Dictionary=heights.get_or_add(x,{})
	if not row.has(z):row[z]=source_height.call(x,z)
	return float(row[z])
func land_at(point:Vector2)->bool:
	if not lands.has(point):lands[point]=source_land.call(point)
	return bool(lands[point])
