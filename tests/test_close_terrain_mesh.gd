extends GdUnitTestSuite
const GRID:=preload("res://scripts/close_terrain_mesh.gd")
func test_indexed_grid_preserves_fixed_diagonal_surface_attributes()->void:
	var calls:=[0]
	var height:=func(x:float,z:float)->float:
		calls[0]+=1
		return x*x*0.2-z*0.3
	var normal:=func(_x:float,_z:float)->Vector3:return Vector3(-0.2,1,0.3).normalized()
	var color:=func(_x:float,_z:float,h:float)->Color:return Color(0.2,0.4,h*0.1+0.5,0.3)
	var positions:=PackedVector3Array()
	var normals:=PackedVector3Array()
	var colors:=PackedColorArray()
	for z in 5:
		for x in 5:
			var point:=Vector2(3,4)+(Vector2(x,z)/4.0-Vector2(0.5,0.5))*2.0
			var h:float=height.call(point.x,point.y)
			positions.append(Vector3(point.x,h,point.y))
			normals.append(normal.call(point.x,point.y))
			colors.append(color.call(point.x,point.y,h))
	var actual:=GRID.build(5,positions,normals,colors).surface_get_arrays(0)
	assert_int(calls[0]).is_equal(25)
	var reference:=SurfaceTool.new()
	reference.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in 4:
		for x in 4:
			for corner in [Vector2i(x,z),Vector2i(x+1,z),Vector2i(x+1,z+1),Vector2i(x,z),Vector2i(x+1,z+1),Vector2i(x,z+1)]:
				var point:=Vector2(3,4)+(Vector2(corner)/4.0-Vector2(0.5,0.5))*2.0
				var h:float=height.call(point.x,point.y)
				reference.set_normal(normal.call(point.x,point.y))
				reference.set_color(color.call(point.x,point.y,h))
				reference.add_vertex(Vector3(point.x,h,point.y))
	reference.index()
	var expected:=reference.commit().surface_get_arrays(0)
	assert_int(actual[Mesh.ARRAY_INDEX].size()).is_equal(96)
	for attribute in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_COLOR]:
		for corner_index in 96:
			assert_bool(actual[attribute][actual[Mesh.ARRAY_INDEX][corner_index]]==expected[attribute][expected[Mesh.ARRAY_INDEX][corner_index]]).is_true()
