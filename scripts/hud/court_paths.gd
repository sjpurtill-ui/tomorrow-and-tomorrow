extends RefCounted
## Walking room in the modelled court (L, for court_stage.gd): where people
## may put their feet, read once from the set's own models, and the way from
## one place to another that goes round the fire, the logs and benches, the
## racks and posts, the walls (through the door) and everyone standing.
##   var room := CourtPaths.room_of(court_set)       (made once a set build, cached)
##   var way := CourtPaths.route(room, from, to, people)
## from / to / people are in the set's own coordinates (x, z on the floor);
## people: Array of Vector3 (x, z, radius) for those standing about. Returns
## the floor points of the walk, first from and last to (empty: no way found,
## the caller walks straight).
## Presentation only: nothing here reads or changes the game's state.

const Self:=preload("res://scripts/hud/court_paths.gd")

## The floor's squares, in metres.
const CELL:=0.2
## What a walker bumps into: anything between ankle and head height.
const BAND_LOW:=0.12
const BAND_HIGH:=1.55
## Half a walking body's width (how far feet keep from a thing).
const WALKER:=0.22
## The fire's own ring (flames have no model to read).
const FIRE_RADIUS:=1.05
## Top-level parts of a set that are no obstacle: the ground and grass, the
## far scenery, what hangs on the walls or overhead, mats and carpets.
const OPEN_PARTS:=["Ground","Grass","Far","Debris","Roof","Rafters","Gables","ShadowCaster","Mats","Carpet","Floor","Canopy",
	"Shields","weave_hang","weave_banner","Trees","Shrubs","Sky"]

class Room:
	var origin:=Vector2.ZERO   # set x, z of square (0, 0)'s corner
	var width:=0
	var height:=0
	## Squares a walker cannot stand on (by the set's things), 1 = blocked.
	var blocked:=PackedByteArray()
	## Squares a thing of the set stands on (not widened), 1 = solid.
	var hard:=PackedByteArray()
	var astar:AStarGrid2D
	var key:=""

	func square(p:Vector2)->Vector2i:
		return Vector2i(floori((p.x-origin.x)/Self.CELL),floori((p.y-origin.y)/Self.CELL))

	func centre(c:Vector2i)->Vector2:
		return origin+(Vector2(c)+Vector2(0.5,0.5))*Self.CELL

	func inside(c:Vector2i)->bool:
		return c.x>=0 and c.y>=0 and c.x<width and c.y<height

	func is_blocked(c:Vector2i)->bool:
		return not inside(c) or blocked[c.y*width+c.x]!=0

static var _rooms:Dictionary={}

## The set's walking room (made from its models the first time it is asked
## for; the same set dressed the same way shares one).
static func room_of(court_set:Node3D)->Room:
	if court_set==null:return null
	var model:=court_set.get_node_or_null("Model") as Node3D
	var parts:Array=[]
	if model!=null:
		for child in model.get_children():
			if child is Node3D and _shown(child as Node3D,court_set) and not _open_part(String(child.name)):parts.append(child)
	var names:PackedStringArray=PackedStringArray()
	for part:Node3D in parts:names.append(String(part.name))
	var key:="%s|%s" % [String(court_set.get("kind")),"/".join(names)]
	if _rooms.has(key):return _rooms[key]
	var room:=Room.new();room.key=key
	# The floor: everywhere the set has a mark, the door and the way out,
	# and a margin round it.
	var lo:=Vector2(INF,INF);var hi:=Vector2(-INF,-INF)
	var points:Array[Vector2]=_mark_points(court_set)
	for p in points:lo=lo.min(p);hi=hi.max(p)
	if points.is_empty():lo=Vector2(-8,-6);hi=Vector2(8,6)
	lo-=Vector2(1.6,1.6);hi+=Vector2(1.6,1.6)
	room.origin=lo
	room.width=int(ceil((hi.x-lo.x)/CELL));room.height=int(ceil((hi.y-lo.y)/CELL))
	room.blocked.resize(room.width*room.height);room.blocked.fill(0)
	var hard:=PackedByteArray();hard.resize(room.width*room.height);hard.fill(0)
	for part:Node3D in parts:_draw_part(room,hard,part,court_set)
	# The fire.
	var fire:Variant=_mark_xz(court_set,"fire")
	if fire!=null:_disc(room,hard,fire as Vector2,FIRE_RADIUS)
	room.hard=hard
	# Widened by half a body: feet keep that far from anything.
	var reach:=int(ceil(WALKER/CELL))
	for y in room.height:
		for x in room.width:
			if hard[y*room.width+x]==0:continue
			for dy in range(-reach,reach+1):
				for dx in range(-reach,reach+1):
					if dx*dx+dy*dy>reach*reach+1:continue
					var c:=Vector2i(x+dx,y+dy)
					if room.inside(c):room.blocked[c.y*room.width+c.x]=1
	# The way in: the door and the way out beyond it are open, and the
	# doorway between them.
	var door:Variant=_mark_xz(court_set,"door");var out:Variant=_mark_xz(court_set,"door_out")
	if door!=null:_clear(room,door as Vector2,0.55)
	if out!=null:_clear(room,out as Vector2,0.55)
	if door!=null and out!=null:
		var a:Vector2=door;var b:Vector2=out
		var steps:=int(ceil(a.distance_to(b)/(CELL*0.5)))
		for i in steps+1:_clear(room,a.lerp(b,float(i)/float(maxi(steps,1))),0.4)
	room.astar=AStarGrid2D.new()
	room.astar.region=Rect2i(0,0,room.width,room.height)
	room.astar.cell_size=Vector2(CELL,CELL)
	room.astar.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	room.astar.default_compute_heuristic=AStarGrid2D.HEURISTIC_OCTILE
	room.astar.default_estimate_heuristic=AStarGrid2D.HEURISTIC_OCTILE
	room.astar.update()
	for y in room.height:
		for x in room.width:
			if room.blocked[y*room.width+x]!=0:room.astar.set_point_solid(Vector2i(x,y),true)
	if _rooms.size()>=8:_rooms.erase(_rooms.keys()[0])
	_rooms[key]=room
	return room

## The way from one floor point to another, round the set's things and the
## people standing about (Vector3(x, z, radius) each).
static func route(room:Room,from:Vector2,to:Vector2,people:Array=[])->PackedVector2Array:
	if room==null or room.astar==null:return PackedVector2Array()
	var start:=room.square(from);var goal:=room.square(to)
	if not room.inside(start) or not room.inside(goal):return PackedVector2Array()
	# Others standing about, for this walk only.
	var changed:Array[Vector2i]=[]
	for p in people:
		var who:Vector3=p
		var r:=who.z+WALKER
		var c0:=room.square(Vector2(who.x,who.y))
		var n:=int(ceil(r/CELL))
		for dy in range(-n,n+1):
			for dx in range(-n,n+1):
				var c:=c0+Vector2i(dx,dy)
				if not room.inside(c) or room.astar.is_point_solid(c):continue
				if room.centre(c).distance_to(Vector2(who.x,who.y))>r:continue
				room.astar.set_point_solid(c,true);changed.append(c)
	# Where they start and end is open to them (a seat on a log, a mark
	# by a post), and a step about it.
	var opened:Array[Vector2i]=[]
	for end:Vector2 in [from,to]:
		var e0:=room.square(end)
		for dy in range(-2,3):
			for dx in range(-2,3):
				var c:=e0+Vector2i(dx,dy)
				if not room.inside(c) or room.centre(c).distance_to(end)>0.36:continue
				if room.astar.is_point_solid(c):room.astar.set_point_solid(c,false);opened.append(c)
	var ids:Array[Vector2i]=room.astar.get_id_path(start,goal)
	var walk:=PackedVector2Array()
	if not ids.is_empty():
		var raw:=PackedVector2Array()
		raw.append(from)
		for i in range(1,ids.size()-1):raw.append(room.centre(ids[i]))
		raw.append(to)
		walk=_pulled(room,raw)
	for c in opened:room.astar.set_point_solid(c,true)
	for c in changed:room.astar.set_point_solid(c,false)
	return walk

## Whether a straight walk between two floor points is clear of everything.
static func clear_line(room:Room,a:Vector2,b:Vector2)->bool:
	var steps:=int(ceil(a.distance_to(b)/(CELL*0.4)))
	for i in range(1,steps):
		var c:=room.square(a.lerp(b,float(i)/float(steps)))
		if not room.inside(c) or room.astar.is_point_solid(c):return false
	return true

## Whether a floor point is open for a person to walk (a body's room from things).
static func open_at(room:Room,p:Vector2)->bool:
	return room!=null and not room.is_blocked(room.square(p))

## Whether a thing of the set (a log, a post, a rack, the fire) stands on a
## floor point itself.
static func solid_at(room:Room,p:Vector2)->bool:
	if room==null:return false
	var c:=room.square(p)
	return room.inside(c) and room.hard[c.y*room.width+c.x]!=0

# --- the room from the set's models ------------------------------------------------

## The way straightened: from each point, on to the furthest it can see.
static func _pulled(room:Room,raw:PackedVector2Array)->PackedVector2Array:
	var out:=PackedVector2Array([raw[0]])
	var i:=0
	while i<raw.size()-1:
		var j:=raw.size()-1
		while j>i+1 and not clear_line(room,raw[i],raw[j]):j-=1
		out.append(raw[j])
		i=j
	return out

static func _open_part(part_name:String)->bool:
	for word:String in OPEN_PARTS:
		if part_name.begins_with(word):return true
	return false

static func _shown(node:Node3D,top:Node)->bool:
	var n:Node=node
	while n!=null and n!=top:
		if n is Node3D and not (n as Node3D).visible:return false
		n=n.get_parent()
	return true

## A node's place in the set's own coordinates (in the tree or not).
static func _in_set(node:Node3D,top:Node)->Transform3D:
	var xf:=Transform3D.IDENTITY
	var n:Node=node
	while n!=null and n!=top:
		if n is Node3D:xf=(n as Node3D).transform*xf
		n=n.get_parent()
	return xf

static func _mark_points(court_set:Node3D)->Array[Vector2]:
	var out:Array[Vector2]=[]
	var marks:Variant=court_set.get("marks")
	if marks is Dictionary:
		for name:String in (marks as Dictionary).keys():
			var at:Variant=_mark_xz(court_set,name)
			if at!=null:out.append(at)
	return out

static func _mark_xz(court_set:Node3D,mark_name:String)->Variant:
	if not court_set.has_method("mark") or not bool(court_set.call("has_mark",mark_name)):return null
	var m:=court_set.call("mark",mark_name) as Node3D
	if m==null:return null
	var o:=_in_set(m,court_set).origin
	return Vector2(o.x,o.z)

## Every triangle of a part between ankle and head height, laid on the floor.
static func _draw_part(room:Room,hard:PackedByteArray,part:Node3D,top:Node3D)->void:
	var meshes:Array=[part] if part is MeshInstance3D else []
	meshes.append_array(part.find_children("*","MeshInstance3D",true,false))
	for node in meshes:
		var mi:=node as MeshInstance3D
		if mi==null or mi.mesh==null or not _shown(mi,top):continue
		var xf:=_in_set(mi,top)
		for s in mi.mesh.get_surface_count():
			var arrays:=mi.mesh.surface_get_arrays(s)
			if arrays.is_empty():continue
			var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var world:PackedVector3Array=xf*verts
			var index:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			if index.is_empty():
				index.resize(world.size())
				for i in world.size():index[i]=i
			# Which vertices lie in the band (most of a set lies outside it).
			var inband:=PackedByteArray();inband.resize(world.size())
			for i in world.size():
				var y:=world[i].y
				if y>=BAND_LOW and y<=BAND_HIGH:inband[i]=1
			var t:=0
			var count:=index.size()
			while t+2<count:
				var ia:=index[t];var ib:=index[t+1];var ic:=index[t+2]
				t+=3
				if inband[ia]==0 and inband[ib]==0 and inband[ic]==0:
					# none in the band: only a face that spans it (a post) counts
					var lo:=minf(world[ia].y,minf(world[ib].y,world[ic].y))
					var hi:=maxf(world[ia].y,maxf(world[ib].y,world[ic].y))
					if hi<BAND_LOW or lo>BAND_HIGH:continue
				var a:=world[ia];var b:=world[ib];var c:=world[ic]
				_triangle(room,hard,Vector2(a.x,a.z),Vector2(b.x,b.z),Vector2(c.x,c.z))

## A triangle's floor print: its edges, and its inside when it has one.
static func _triangle(room:Room,hard:PackedByteArray,a:Vector2,b:Vector2,c:Vector2)->void:
	# A small face (most of them): its corners' squares are enough.
	_mark(room,hard,a);_mark(room,hard,b);_mark(room,hard,c)
	var reach:=CELL*0.5
	if a.distance_squared_to(b)<=reach*reach and b.distance_squared_to(c)<=reach*reach and c.distance_squared_to(a)<=reach*reach:return
	_edge(room,hard,a,b);_edge(room,hard,b,c);_edge(room,hard,c,a)
	var area:=absf((b-a).cross(c-a))*0.5
	if area<CELL*CELL:return
	var lo:=room.square(a.min(b).min(c));var hi:=room.square(a.max(b).max(c))
	for y in range(maxi(lo.y,0),mini(hi.y,room.height-1)+1):
		for x in range(maxi(lo.x,0),mini(hi.x,room.width-1)+1):
			if Geometry2D.point_is_inside_triangle(room.centre(Vector2i(x,y)),a,b,c):hard[y*room.width+x]=1

static func _edge(room:Room,hard:PackedByteArray,p:Vector2,q:Vector2)->void:
	var steps:=int(ceil(p.distance_to(q)/(CELL*0.5)))
	for i in range(1,steps):_mark(room,hard,p.lerp(q,float(i)/float(steps)))

static func _mark(room:Room,hard:PackedByteArray,p:Vector2)->void:
	var c:=room.square(p)
	if room.inside(c):hard[c.y*room.width+c.x]=1

static func _disc(room:Room,hard:PackedByteArray,at:Vector2,r:float)->void:
	var n:=int(ceil(r/CELL))
	var c0:=room.square(at)
	for dy in range(-n,n+1):
		for dx in range(-n,n+1):
			var c:=c0+Vector2i(dx,dy)
			if room.inside(c) and room.centre(c).distance_to(at)<=r:hard[c.y*room.width+c.x]=1

static func _clear(room:Room,at:Vector2,r:float)->void:
	var n:=int(ceil(r/CELL))
	var c0:=room.square(at)
	for dy in range(-n,n+1):
		for dx in range(-n,n+1):
			var c:=c0+Vector2i(dx,dy)
			if room.inside(c) and room.centre(c).distance_to(at)<=r:room.blocked[c.y*room.width+c.x]=0
