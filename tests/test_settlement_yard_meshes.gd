extends GdUnitTestSuite
const Yards:=preload("res://scripts/settlement_yard_meshes.gd")
const Shapes:=preload("res://scripts/settlement_kit_shapes.gd")

func _hits(mesh:Mesh,x:float,y:float)->bool:
	for surface in mesh.get_surface_count():
		var arrays:=mesh.surface_get_arrays(surface)
		var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		var count:=indices.size() if not indices.is_empty() else points.size()
		for offset in range(0,count,3):
			var a:int=indices[offset] if not indices.is_empty() else offset
			var b:int=indices[offset+1] if not indices.is_empty() else offset+1
			var c:int=indices[offset+2] if not indices.is_empty() else offset+2
			if Geometry3D.ray_intersects_triangle(Vector3(x,y,2),Vector3.FORWARD,points[a],points[b],points[c])!=null:return true
	return false

func test_five_groups_reuse_exact_existing_assets_and_have_finite_cache()->void:
	for kind:String in ["woodpile","pots","drying_rack"]:
		assert_object(Yards.mesh(kind)).is_same(Shapes.prop(kind))
	for kind:String in Yards.KINDS:
		assert_object(Yards.mesh(kind)).is_not_null()
		assert_object(Yards.mesh(kind)).is_same(Yards.mesh(kind))
	for index in 30:assert_object(Yards.mesh("unknown%d" % index)).is_null()
	assert_int(Yards._meshes.size()).is_equal(5)

func test_every_prop_is_small_opaque_bounded_geometry_with_measured_placement_envelope()->void:
	for kind:String in Yards.KINDS:
		var mesh:=Yards.mesh(kind);var bounds:=Yards.bounds(kind)
		assert_int(Yards.triangles(kind)).is_between(1,Yards.MAX_TRIANGLES)
		assert_float(Yards.height_m(kind)).is_between(.15,2.0)
		assert_float(Yards.radius_m(kind)).is_between(.25,1.6)
		assert_float(bounds.position.y).is_greater_equal(-.06)
		for surface in mesh.get_surface_count():
			var arrays:=mesh.surface_get_arrays(surface)
			var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
			assert_int(points.size()).is_equal(colors.size())
			for point:Vector3 in points:
				assert_bool(bounds.grow(.00001).has_point(point)).is_true()
				assert_float(Vector2(point.x,point.z).length()).is_less_equal(Yards.radius_m(kind)+.00001)
			for color:Color in colors:assert_float(color.a).is_equal(1.0)
			assert_object(mesh.surface_get_material(surface)).is_null()

func test_fishing_net_has_visible_cords_and_real_open_cells_instead_of_alpha_card()->void:
	var net:=Yards.mesh("fishing_net")
	# Sample every one of the 24 gaps. A filled or translucent rectangle
	# masquerading as a net would intersect these rays and fail the check.
	for column in Yards.NET_COLUMNS-1:
		for row in Yards.NET_ROWS-1:
			var x:=lerpf(Yards.NET_LEFT,Yards.NET_RIGHT,(float(column)+.5)/float(Yards.NET_COLUMNS-1))
			var y:=lerpf(Yards.NET_BOTTOM,Yards.NET_TOP,(float(row)+.5)/float(Yards.NET_ROWS-1))
			assert_bool(_hits(net,x,y)).is_false()
	# Cord interiors intersect from the front, so the lattice is actual mesh.
	for column in Yards.NET_COLUMNS:
		var x:=lerpf(Yards.NET_LEFT,Yards.NET_RIGHT,float(column)/float(Yards.NET_COLUMNS-1))
		assert_bool(_hits(net,x+.007,.77)).is_true()
	for row in Yards.NET_ROWS:
		var y:=lerpf(Yards.NET_BOTTOM,Yards.NET_TOP,float(row)/float(Yards.NET_ROWS-1))
		assert_bool(_hits(net,.13,y+.007)).is_true()
