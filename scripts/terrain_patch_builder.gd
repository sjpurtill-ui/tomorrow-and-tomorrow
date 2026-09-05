extends RefCounted
## Builds one bounded terrain mesh in small main-thread slices. Only the finished
## mesh replaces the visible patch; height/color callables never cross threads.
var resolution:int
var span:float
var center:Vector2
var vertices:=PackedVector3Array()
var heights:=PackedFloat32Array()
var normals:=PackedVector3Array()
var colors:=PackedColorArray()
var indices:=PackedInt32Array()
var cursor:=0
var phase:=0
var sample_height:Callable
var sample_color:Callable
var max_slice_usec:=0

func _init(grid_resolution:int,patch_span:float,patch_center:Vector2,height_fn:Callable,color_fn:Callable)->void:
	resolution=grid_resolution; span=patch_span; center=patch_center
	sample_height=height_fn; sample_color=color_fn
	heights.resize(resolution*resolution)
	vertices.resize(resolution*resolution); normals.resize(vertices.size()); colors.resize(vertices.size())
	indices.resize((resolution-1)*(resolution-1)*6)

func advance(budget_usec:int=2500)->bool:
	var started:=Time.get_ticks_usec()
	var total:=vertices.size()
	var spacing:=span/float(resolution-1)
	# Close relief uses a twenty-metre derivative baseline so ridge cusps do not
	# become hard lighting seams. Geometry and authoritative heights are unchanged.
	var normal_radius:=maxi(1,ceili(0.02/spacing))
	while phase<2:
		var x_index:=cursor%resolution
		var z_index:=cursor/resolution
		if phase==0:
			var x:=center.x+(float(x_index)/float(resolution-1)-0.5)*span
			var z:=center.y+(float(z_index)/float(resolution-1)-0.5)*span
			var height:float=sample_height.call(x,z)+0.0006
			vertices[cursor]=Vector3(x,height,z)
			heights[cursor]=height
			colors[cursor]=sample_color.call(x,z,height)
		else:
			var left:=maxi(0,x_index-normal_radius); var right:=mini(resolution-1,x_index+normal_radius)
			var up:=maxi(0,z_index-normal_radius); var down:=mini(resolution-1,z_index+normal_radius)
			var dx:=(vertices[z_index*resolution+right].y-vertices[z_index*resolution+left].y)/(float(right-left)*spacing)
			var dz:=(vertices[down*resolution+x_index].y-vertices[up*resolution+x_index].y)/(float(down-up)*spacing)
			normals[cursor]=Vector3(-dx,1.0,-dz).normalized()
			if x_index<resolution-1 and z_index<resolution-1:
				var a:=cursor; var b:=a+1; var d:=a+resolution; var c:=d+1
				var offset:=(z_index*(resolution-1)+x_index)*6
				var corners:=[a,b,c,a,c,d] if (x_index+z_index)%2==0 else [a,b,d,b,c,d]
				for corner in 6: indices[offset+corner]=corners[corner]
		cursor+=1
		if cursor>=total: phase+=1; cursor=0
		if cursor%32==0 and Time.get_ticks_usec()-started>=budget_usec: break
	max_slice_usec=maxi(max_slice_usec,Time.get_ticks_usec()-started)
	return phase==2

func commit()->ArrayMesh:
	assert(phase==2)
	var arrays:Array=[]; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_COLOR]=colors; arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh
