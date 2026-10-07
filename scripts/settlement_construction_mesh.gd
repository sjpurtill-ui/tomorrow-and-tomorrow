extends RefCounted
## Metres, in the completed kit's own coordinates. No calendar, placement,
## terrain or state access: the caller supplies the actual work milestone.
## New buildings reveal courses, an open frame, walls and finally the exact
## recorded roof. Refits return scaffolding only; the old building stays put.
const MAX_SOURCE_TRIANGLES:=40000
const MAX_SOURCE_SURFACES:=16
const MAX_FRAME_EDGES:=24
const MAX_FRAME_LEVELS:=4
const MAX_CACHE_ENTRIES:=128
const MAX_SOURCE_ENTRIES:=24
static var _cache:Dictionary={}
static var _sources:Dictionary={}

static func cache_key(final_mesh:Mesh,plot:Dictionary,milestone:int,retrofit:=false)->String:
	if final_mesh==null:return ""
	return "%d|%s|%d|%s" % [final_mesh.get_instance_id(),String(plot.get("material_family","")),0 if retrofit else clampi(milestone,0,3),str(retrofit)]

static func clear_cache()->void:
	_cache.clear();_sources.clear()

static func mesh(final_mesh:Mesh,plot:Dictionary,milestone:int)->Mesh:
	if final_mesh==null:return null
	if milestone>=3:return final_mesh
	var key:=cache_key(final_mesh,plot,milestone)
	if _cache.has(key):return _cache[key]
	var source:=_source(final_mesh)
	if source.is_empty():return null
	var stage:=clampi(milestone,0,2)
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var emitted:=0
	if stage<=1:
		for triangle:Dictionary in source.triangles:
			emitted+=_below(surface,triangle,float(source.foundation_top))
		if stage==1:emitted+=_frame(surface,source,plot,0.0)
	else:
		for triangle:Dictionary in source.triangles:
			if bool(triangle.wall) or float(triangle.top)<=float(source.foundation_top):
				_emit(surface,triangle.points,triangle.colors,triangle.normals);emitted+=1
	if emitted==0:return null
	var built:=surface.commit()
	built.set_meta("construction_stage",stage)
	built.set_meta("construction_source_bounds",final_mesh.get_aabb())
	built.set_meta("construction_source_triangles",int(source.triangles.size()))
	built.set_meta("construction_triangles",emitted)
	built.set_meta("construction_frame_edges",source.edges.size() if stage==1 else 0)
	built.set_meta("construction_roof_triangles",0)
	_remember(_cache,key,built,MAX_CACHE_ENTRIES)
	return built

static func retrofit_mesh(final_mesh:Mesh,plot:Dictionary,milestone:int)->Mesh:
	if final_mesh==null:return null
	var key:=cache_key(final_mesh,plot,milestone,true)
	if _cache.has(key):return _cache[key]
	var source:=_source(final_mesh)
	if source.is_empty():return null
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# A narrow scaffold outside the actual wall sections, never a replacement
	# house. At most 12 cm beyond the final kit envelope, not another lot.
	var count:=_frame(surface,source,plot,0.12)
	if count==0:return null
	var built:=surface.commit()
	built.set_meta("construction_retrofit_overlay",true)
	built.set_meta("construction_stage",0)
	built.set_meta("construction_source_bounds",final_mesh.get_aabb())
	built.set_meta("construction_frame_edges",source.edges.size())
	built.set_meta("construction_triangles",count)
	_remember(_cache,key,built,MAX_CACHE_ENTRIES)
	return built

static func _remember(cache:Dictionary,key:Variant,value:Variant,limit:int)->void:
	if cache.size()>=limit:cache.erase(cache.keys()[0])
	cache[key]=value

static func _source(mesh:Mesh)->Dictionary:
	var key:=mesh.get_instance_id()
	if _sources.has(key):return _sources[key]
	if mesh.get_surface_count()>MAX_SOURCE_SURFACES:return {}
	var bounds:=mesh.get_aabb()
	var foundation_top:=bounds.position.y+clampf(bounds.size.y*0.07,0.08,0.24)
	var triangles:Array[Dictionary]=[]
	var edges:Dictionary={}
	for part in mesh.get_surface_count():
		if mesh is ArrayMesh and mesh.surface_get_primitive_type(part)!=Mesh.PRIMITIVE_TRIANGLES:continue
		var arrays:=mesh.surface_get_arrays(part)
		var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR]!=null else PackedColorArray()
		var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL]!=null else PackedVector3Array()
		var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		var count:=indices.size() if not indices.is_empty() else vertices.size()
		if triangles.size()+count/3>MAX_SOURCE_TRIANGLES:return {}
		for offset in range(0,count-2,3):
			var points:=PackedVector3Array();var tones:=PackedColorArray();var face_normals:=PackedVector3Array()
			for corner in 3:
				var index:=indices[offset+corner] if not indices.is_empty() else offset+corner
				points.append(vertices[index]);tones.append(colors[index] if colors.size()==vertices.size() else Color.WHITE)
				face_normals.append(normals[index] if normals.size()==vertices.size() else Vector3.ZERO)
			var cross:Vector3=(points[1]-points[0]).cross(points[2]-points[0])
			var area:=cross.length()*0.5
			if area<0.0000001:continue
			var normal:=cross.normalized()
			if face_normals[0].length_squared()<0.1:face_normals.fill(-normal)
			var top:=maxf(points[0].y,maxf(points[1].y,points[2].y))
			var base:=minf(points[0].y,minf(points[1].y,points[2].y))
			# Existing roof material codes (.92..98) and glass (.86) are explicit
			# kit tags. Untagged early roofs are sloping/horizontal surfaces;
			# their vertical gable ends remain part of the wall, as built.
			var code:=float(tones[0].a)
			var roof_material:=code>=0.915 and code<=0.985
			var glass:=absf(code-0.86)<0.005
			var wall:=absf(normal.y)<0.25 and not roof_material and not glass
			var triangle:Dictionary={"points":points,"colors":tones,"normals":face_normals,"top":top,"wall":wall}
			triangles.append(triangle)
			# Authored envelopes scale an early workshop's thin post faces below
			# .08 m². Keep those real supports; the 24-edge cap bounds the frame.
			if wall and top-base>0.35 and area>0.02:
				_wall_edge(edges,points,base,top,area)
	var ordered:Array=edges.values()
	ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.weight)>float(b.weight))
	if ordered.size()>MAX_FRAME_EDGES:ordered.resize(MAX_FRAME_EDGES)
	var source:Dictionary={"mesh":mesh,"bounds":bounds,"foundation_top":foundation_top,"triangles":triangles,"edges":ordered}
	_remember(_sources,key,source,MAX_SOURCE_ENTRIES)
	return source

static func _wall_edge(edges:Dictionary,points:PackedVector3Array,base:float,top:float,area:float)->void:
	var a:=Vector2(points[0].x,points[0].z);var b:=a;var length:=0.0
	for i in 3:
		for j in range(i+1,3):
			var p:=Vector2(points[i].x,points[i].z);var q:=Vector2(points[j].x,points[j].z)
			if p.distance_squared_to(q)>length:a=p;b=q;length=p.distance_squared_to(q)
	# Early open workshops have 13 cm posts rather than broad wall panels.
	# Their actual edges still carry a frame/scaffold; do not discard them.
	if length<0.035*0.035:return
	if a.x>b.x or (is_equal_approx(a.x,b.x) and a.y>b.y):
		var swap:=a;a=b;b=swap
	var key:="%s|%s" % [a.snapped(Vector2.ONE*.001),b.snapped(Vector2.ONE*.001)]
	if edges.has(key):
		var edge:Dictionary=edges[key];edge.base=minf(float(edge.base),base);edge.top=maxf(float(edge.top),top);edge.weight+=area
	else:edges[key]={"a":a,"b":b,"base":base,"top":top,"weight":area}

static func _frame(surface:SurfaceTool,source:Dictionary,plot:Dictionary,offset:float)->int:
	var bounds:AABB=source.bounds
	var limit:=bounds.grow(offset)
	var width:=clampf(minf(bounds.size.x,bounds.size.z)*0.016,0.045,0.11)
	var tone:=Color("69503a")
	if String(plot.get("material_family","")) in ["iron","steel","metal"]:tone=Color("555b5c")
	elif String(plot.get("material_family",""))=="concrete":tone=Color("9a9589")
	var columns:Dictionary={};var count:=0
	for edge:Dictionary in source.edges:
		var a:=Vector3(edge.a.x,float(edge.base),edge.a.y)
		var b:=Vector3(edge.b.x,float(edge.base),edge.b.y)
		var up:=float(edge.top)
		if offset>0.0:
			var midpoint:=(a+b)*.5-bounds.get_center();midpoint.y=0.0
			if midpoint.length_squared()>0.0001:
				var outward:=midpoint.normalized()*offset*.6;a+=outward;b+=outward
		for foot:Vector3 in [a,b]:
			var key:=str(foot.snapped(Vector3.ONE*.01))
			if not columns.has(key):columns[key]={"foot":foot,"top":up}
			else:columns[key].top=maxf(float(columns[key].top),up)
		var levels:=clampi(ceili((up-a.y)/3.0),1,MAX_FRAME_LEVELS)
		for level in range(1,levels+1):
			var y:=lerpf(a.y,up,float(level)/float(levels))
			count+=_beam(surface,Vector3(a.x,y,a.z),Vector3(b.x,y,b.z),width,tone,limit)
	for column:Dictionary in columns.values():
		var foot:Vector3=column.foot
		count+=_beam(surface,foot,Vector3(foot.x,float(column.top),foot.z),width,tone,limit)
	return count

static func _beam(surface:SurfaceTool,a:Vector3,b:Vector3,radius:float,tone:Color,limit:AABB)->int:
	var delta:=b-a
	if delta.length()<0.001:return 0
	var y:=delta.normalized();var axis:=Vector3.RIGHT if absf(y.dot(Vector3.UP))>.95 else Vector3.UP
	var x:=y.cross(axis).normalized();var z:=x.cross(y).normalized()
	var points:=PackedVector3Array()
	for end:Vector3 in [a,b]:
		for pair:Vector2 in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
			points.append((end+x*pair.x*radius+z*pair.y*radius).clamp(limit.position,limit.end))
	for face:Array in [[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]]:
		for ids:Array in [[face[0],face[1],face[2]],[face[0],face[2],face[3]]]:
			var vertices:=PackedVector3Array([points[ids[0]],points[ids[1]],points[ids[2]]])
			var n:=-(vertices[1]-vertices[0]).cross(vertices[2]-vertices[0]).normalized()
			_emit(surface,vertices,PackedColorArray([tone,tone,tone]),PackedVector3Array([n,n,n]))
	return 12

static func _below(surface:SurfaceTool,triangle:Dictionary,height:float)->int:
	var vertices:Array[Dictionary]=[]
	for index in 3:vertices.append({"p":triangle.points[index],"c":triangle.colors[index],"n":triangle.normals[index]})
	var clipped:Array[Dictionary]=[]
	for index in vertices.size():
		var a:Dictionary=vertices[index];var b:Dictionary=vertices[(index+1)%vertices.size()]
		var inside_a:=float(a.p.y)<=height;var inside_b:=float(b.p.y)<=height
		if inside_a:clipped.append(a)
		if inside_a!=inside_b:
			var t:=clampf((height-float(a.p.y))/(float(b.p.y)-float(a.p.y)),0.0,1.0)
			clipped.append({"p":(a.p as Vector3).lerp(b.p,t),"c":(a.c as Color).lerp(b.c,t),"n":(a.n as Vector3).lerp(b.n,t).normalized()})
	for index in range(1,clipped.size()-1):
		var p:=PackedVector3Array();var c:=PackedColorArray();var n:=PackedVector3Array()
		for vertex:Dictionary in [clipped[0],clipped[index],clipped[index+1]]:p.append(vertex.p);c.append(vertex.c);n.append(vertex.n)
		_emit(surface,p,c,n)
	return maxi(0,clipped.size()-2)

static func _emit(surface:SurfaceTool,points:PackedVector3Array,colors:PackedColorArray,normals:PackedVector3Array)->void:
	for index in 3:
		surface.set_color(colors[index]);surface.set_normal(normals[index]);surface.add_vertex(points[index])
