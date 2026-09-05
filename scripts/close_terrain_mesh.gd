extends RefCounted
## Fixed-diagonal close grid, sampled once per vertex and indexed directly.
static func build(resolution:int,vertices:PackedVector3Array,normals:PackedVector3Array,colors:PackedColorArray)->ArrayMesh:
	assert(resolution>=2 and vertices.size()==resolution*resolution)
	assert(normals.size()==vertices.size() and colors.size()==vertices.size())
	var indices:=PackedInt32Array()
	indices.resize((resolution-1)*(resolution-1)*6)
	for z in resolution-1:
		for x in resolution-1:
			var offset:=(z*(resolution-1)+x)*6
			var a:=z*resolution+x
			var b:=a+1
			var d:=a+resolution
			var c:=d+1
			indices[offset]=a
			indices[offset+1]=b
			indices[offset+2]=c
			indices[offset+3]=a
			indices[offset+4]=c
			indices[offset+5]=d
	var arrays:Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_COLOR]=colors
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh
