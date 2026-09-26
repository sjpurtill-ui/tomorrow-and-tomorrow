extends RefCounted
## Exact reuse: no quantization. Per build, or held for one world by an owner
## that keys it on the world (see local_terrain._territory_height_samples).
var heights:Dictionary={}
var lands:Dictionary={}
var source_height:Callable
var source_land:Callable
## Source height evaluations (cache misses); lets long-lived owners bound size.
var misses:=0
func _init(height:Callable,land:Callable)->void:
	source_height=height;source_land=land
func height_at(x:float,z:float)->float:
	var row:Dictionary=heights.get_or_add(x,{})
	if not row.has(z):
		row[z]=source_height.call(x,z);misses+=1
	return float(row[z])
func land_at(point:Vector2)->bool:
	if not lands.has(point):lands[point]=source_land.call(point)
	return bool(lands[point])
