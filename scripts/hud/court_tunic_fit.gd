extends RefCounted
## Ease only the tunic's lower front panel off the moving thighs. Imported
## geometry, every skin weight and the body's conservative coverage stay intact.
const CACHE_LIMIT:=14
const EASE_METRES:=.008
static var _cache:Dictionary={}

static func fitted(source:Mesh,height:float)->Mesh:
	if not source is ArrayMesh:return source
	var key:="%d:%.4f" % [source.get_instance_id(),height]
	if _cache.has(key):return _cache[key]
	# These shipped tunics store float vertex positions. Never reinterpret a
	# future compressed buffer as floats; the asset regression enforces this.
	for surface in source.get_surface_count():
		if int(source.surface_get_format(surface))&Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES:return source
	var made:=source.duplicate() as ArrayMesh
	var packed:Array=source.get("_surfaces").duplicate(true)
	var hem:=source.get_aabb().position.y;var k:=height/1.72
	for surface in source.get_surface_count():
		var arrays:=source.surface_get_arrays(surface);var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var format:int=source.surface_get_format(surface)
		var stride:=RenderingServer.mesh_surface_get_format_vertex_stride(format,points.size())
		var offset:=RenderingServer.mesh_surface_get_format_offset(format,points.size(),Mesh.ARRAY_VERTEX)
		var data:PackedByteArray=packed[surface].vertex_data
		for vertex in points.size():
			var p:=points[vertex]
			var rise:=smoothstep(hem+.06*k,hem+.16*k,p.y)
			var top:=1.0-smoothstep(height*.52,height*.59,p.y)
			var front:=smoothstep(.015*k,.065*k,p.z)
			data.encode_float(offset+stride*vertex+8,p.z+EASE_METRES*k*rise*top*front)
		packed[surface].vertex_data=data
		var bounds:AABB=packed[surface].aabb
		packed[surface].aabb=bounds.expand(bounds.end+Vector3(0,0,EASE_METRES*k))
		var bone_bounds:Array=packed[surface].bone_aabbs
		for bone in bone_bounds.size():bone_bounds[bone]=bone_bounds[bone].grow(EASE_METRES*k)
		packed[surface].bone_aabbs=bone_bounds
	made.clear_surfaces();made.set("_surfaces",packed)
	if _cache.size()>=CACHE_LIMIT:_cache.erase(_cache.keys()[0])
	_cache[key]=made
	return made
