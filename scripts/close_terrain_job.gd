extends RefCounted
const GRID:=preload("res://scripts/close_terrain_mesh.gd")
var center:Vector2
var resolution:int
var span:float
var cursor:=0
var max_slice_usec:=0
var vertices:=PackedVector3Array()
var normals:=PackedVector3Array()
var colors:=PackedColorArray()
var sampler:Callable
var surface_sampler:Callable
var climate_uv:=PackedVector2Array()
var geology_uv:=PackedVector2Array()
func _init(grid_resolution:int,grid_span:float,grid_center:Vector2,sample:Callable,surface:Callable=Callable())->void:
	assert(grid_resolution>=2 and grid_span>0.0)
	resolution=grid_resolution
	span=grid_span
	center=grid_center
	sampler=sample
	surface_sampler=surface
	vertices.resize(resolution*resolution)
	normals.resize(vertices.size())
	colors.resize(vertices.size())
	if surface_sampler.is_valid():
		climate_uv.resize(vertices.size());geology_uv.resize(vertices.size())
func advance(budget_usec:int=2500)->bool:
	var started:=Time.get_ticks_usec()
	while cursor<vertices.size():
		var x:=center.x+(float(cursor%resolution)/(resolution-1)-0.5)*span
		var z:=center.y+(float(cursor/resolution)/(resolution-1)-0.5)*span
		var sample:Array=sampler.call(x,z)
		vertices[cursor]=Vector3(x,float(sample[0]),z)
		normals[cursor]=sample[1]
		colors[cursor]=sample[2]
		if surface_sampler.is_valid():
			var fields:Vector4=surface_sampler.call(x,z,float(sample[0]))
			climate_uv[cursor]=Vector2(fields.x,fields.y);geology_uv[cursor]=Vector2(fields.z,fields.w)
		cursor+=1
		if cursor%8==0 and Time.get_ticks_usec()-started>=budget_usec: break
	max_slice_usec=maxi(max_slice_usec,Time.get_ticks_usec()-started)
	return cursor==vertices.size()
func commit()->ArrayMesh:
	assert(cursor==vertices.size())
	return GRID.build(resolution,vertices,normals,colors,climate_uv,geology_uv)
