extends RefCounted
## Exact circle/capsule queries accelerated by spatial buckets. This index never
## adds knowledge; it contains only the same physical chart records as the map.
const CELL:=128.0
# Very long or numerous segments fall back to exact checks, not unlimited buckets.
const MAX_BUCKET_REFERENCES:=262144
var bucket_references:=0
var buckets:Dictionary={}
var wide:Array[Dictionary]=[]
func _init(records:Array)->void:
	for record:Dictionary in records:
		var radius:=maxf(0,float(record.get("radius",0)))
		var points:Array=record.get("points",[])
		if record.get("kind","circle")=="trail" and points.size()>=2:
			for i in range(1,points.size()):add_segment(point(points[i-1]),point(points[i]),radius)
		else:
			var center:=Vector2(float(record.get("x",0)),float(record.get("z",0)))
			add_segment(center,center,radius)
func point(value:Dictionary)->Vector2:return Vector2(float(value.get("x",0)),float(value.get("z",0)))
func add_segment(a:Vector2,b:Vector2,radius:float)->void:
	var segment:={"a":a,"b":b,"radius":radius}
	var low:=Vector2i(floori((minf(a.x,b.x)-radius)/CELL),floori((minf(a.y,b.y)-radius)/CELL))
	var high:=Vector2i(floori((maxf(a.x,b.x)+radius)/CELL),floori((maxf(a.y,b.y)+radius)/CELL))
	var cells:=(high.x-low.x+1)*(high.y-low.y+1)
	if cells>512 or bucket_references+cells>MAX_BUCKET_REFERENCES:wide.append(segment);return
	bucket_references+=cells
	for x in range(low.x,high.x+1):
		for y in range(low.y,high.y+1):
			var key:=Vector2i(x,y)
			if not buckets.has(key):buckets[key]=[]
			buckets[key].append(segment)
func contains(position:Vector2)->bool:
	for segment:Dictionary in buckets.get(Vector2i(floori(position.x/CELL),floori(position.y/CELL)),[]):
		if touches(segment,position):return true
	for segment:Dictionary in wide:
		if touches(segment,position):return true
	return false
func touches(segment:Dictionary,position:Vector2)->bool:
	return position.distance_to(Geometry2D.get_closest_point_to_segment(position,segment.a,segment.b))<=float(segment.radius)
