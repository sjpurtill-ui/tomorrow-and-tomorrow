extends RefCounted
## Experiment only. Continuous positions remain authoritative; this lookup is
## a disposable broad phase, not a movement grid, renderer, or save authority.
var cell_size:=0.25
var positions:=PackedVector2Array()
var buckets:Dictionary={}

func build(points:PackedVector2Array,size_km:float)->void:
	assert(size_km>0.0)
	cell_size=size_km
	positions=points.duplicate()
	buckets.clear()
	for id in positions.size():
		var key:=_cell(positions[id])
		if not buckets.has(key): buckets[key]=[]
		buckets[key].append(id)

func move(id:int,position:Vector2)->void:
	var previous:=_cell(positions[id])
	var next:=_cell(position)
	positions[id]=position
	if previous==next: return
	buckets[previous].erase(id)
	if buckets[previous].is_empty(): buckets.erase(previous)
	if not buckets.has(next): buckets[next]=[]
	buckets[next].append(id)

func nearby(point:Vector2,radius:float)->PackedInt32Array:
	var found:=PackedInt32Array()
	var first:=_cell(point-Vector2.ONE*radius)
	var last:=_cell(point+Vector2.ONE*radius)
	for y in range(first.y,last.y+1):
		for x in range(first.x,last.x+1):
			for id in buckets.get(Vector2i(x,y),[]):
				if positions[id].distance_squared_to(point)<=radius*radius: found.append(id)
	return found

func _cell(point:Vector2)->Vector2i:
	return Vector2i(floori(point.x/cell_size),floori(point.y/cell_size))

func control_occupancy(ids:PackedInt32Array,control_cell_km:float)->Dictionary:
	# Aggregate tactical presence, not automatic political ownership. Even/odd
	# identifies the two synthetic sides; each record represents100 personnel.
	var control:Dictionary={}
	for id in ids:
		var key:=Vector2i(floori(positions[id].x/control_cell_km),floori(positions[id].y/control_cell_km))
		var counts:Vector2i=control.get(key,Vector2i.ZERO)
		if id%2==0: counts.x+=100
		else: counts.y+=100
		control[key]=counts
	return control
