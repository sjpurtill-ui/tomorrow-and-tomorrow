extends GdUnitTestSuite
## Merging must preserve the lighting of authored face and expression morphs.
const Merge=preload("res://scripts/hud/court_figure_merge.gd")
const EPSILON:=0.001

func _triangle(raise_x:=0.0,raise_y:=0.0)->PackedVector3Array:
	return PackedVector3Array([Vector3.ZERO,Vector3(1.0,0.0,raise_x),Vector3(0.0,1.0,raise_y)])

func _normal(vertices:PackedVector3Array)->Vector3:
	return (vertices[1]-vertices[0]).cross(vertices[2]-vertices[0]).normalized()

func _target(vertices:PackedVector3Array,normal:=Vector3.ZERO)->Array:
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	var n:=_normal(vertices) if normal==Vector3.ZERO else normal
	arrays[Mesh.ARRAY_NORMAL]=PackedVector3Array([n,n,n])
	return arrays

func _part(targets:Dictionary)->MeshInstance3D:
	var mesh:=ArrayMesh.new()
	mesh.blend_shape_mode=Mesh.BLEND_SHAPE_MODE_NORMALIZED
	var shapes:=[]
	for key:String in targets:
		mesh.add_blend_shape(StringName(key));shapes.append(targets[key])
	var arrays:=_target(_triangle())
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,shapes)
	var part:MeshInstance3D=auto_free(MeshInstance3D.new())
	part.mesh=mesh
	return part

func _entry(part:MeshInstance3D)->Array:
	return [part,0,"SKIN"]

func _assert_normals(normals:PackedVector3Array,want:Vector3)->void:
	assert_int(normals.size()).is_equal(3)
	for actual in normals:
		assert_bool(actual.is_finite()).is_true()
		assert_float(actual.length()).is_equal_approx(1.0,EPSILON)
		assert_float(actual.distance_to(want)).is_less(EPSILON)

func test_identity_turns_normals_at_stationary_vertices()->void:
	var raised:=_triangle(0.0,0.5)
	var part:=_part({"face_jaw":_target(raised)})
	var built:=Merge._arrays([_entry(part)],{"jaw":1.0},[])
	var positions:PackedVector3Array=built.arrays[Mesh.ARRAY_VERTEX]
	assert_bool(positions[0].is_equal_approx(Vector3.ZERO)).is_true()
	assert_bool(positions[1].is_equal_approx(Vector3.RIGHT)).is_true()
	# The face normal is determined geometrically, including unchanged corners.
	_assert_normals(built.arrays[Mesh.ARRAY_NORMAL],_normal(positions))

func test_expression_retains_its_authored_normals()->void:
	var smile:=_triangle(0.6,0.0)
	var part:=_part({"smile":_target(smile)})
	var merged:=Merge._merge([_entry(part)],{},true)
	assert_int(merged.get_blend_shape_count()).is_equal(1)
	assert_str(String(merged.get_blend_shape_name(0))).is_equal("smile")
	var shape:Array=merged.surface_get_blend_shape_arrays(0)[0]
	_assert_normals(shape[Mesh.ARRAY_NORMAL],_normal(smile))
	assert_float((shape[Mesh.ARRAY_NORMAL] as PackedVector3Array)[0].distance_to(Vector3.BACK)).is_greater(0.1)

func test_expression_keeps_raw_weighted_identity_normal_delta()->void:
	var jaw:=_triangle(0.0,0.8)
	var smile:=_triangle(0.6,0.0)
	var part:=_part({"face_jaw":_target(jaw),"smile":_target(smile)})
	var weight:=0.65
	var built:=Merge._arrays([_entry(part)],{"jaw":weight},["smile"])
	var raw_identity:=(_normal(jaw)-Vector3.BACK)*weight
	var expected:=(_normal(smile)+raw_identity).normalized()
	_assert_normals(built.shapes[0][Mesh.ARRAY_NORMAL],expected)
	# Normalizing the identity before applying it to the expression loses
	# part of the authored delta; this case distinguishes the two operations.
	var premature:=(_normal(smile)+(Vector3.BACK+raw_identity).normalized()-Vector3.BACK).normalized()
	assert_float(expected.distance_to(premature)).is_greater(0.005)

func test_part_without_expression_retains_its_baked_identity_normals()->void:
	var smile_part:=_part({"smile":_target(_triangle(0.4,0.0))})
	var jaw:=_triangle(0.0,0.7)
	var still_part:=_part({"face_jaw":_target(jaw)})
	var built:=Merge._arrays([_entry(smile_part),_entry(still_part)],{"jaw":1.0},["smile"])
	var normals:PackedVector3Array=built.shapes[0][Mesh.ARRAY_NORMAL]
	assert_int(normals.size()).is_equal(6)
	_assert_normals(normals.slice(0,3),_normal(_triangle(0.4,0.0)))
	_assert_normals(normals.slice(3,6),_normal(jaw))
	assert_int((built.shapes[0][Mesh.ARRAY_VERTEX] as PackedVector3Array).size()).is_equal(normals.size())

func test_negative_identity_weight_preserves_normal_only_changes()->void:
	# Authored smooth normals can change even where the entire local patch
	# stays put, as adjacent geometry outside this patch deforms.
	var authored:=Vector3(0.2,-0.5,1.0).normalized()
	var part:=_part({"face_cheek":_target(_triangle(),authored)})
	var built:=Merge._arrays([_entry(part)],{"cheek":-0.75},[])
	_assert_normals(built.arrays[Mesh.ARRAY_NORMAL],(Vector3.BACK-(authored-Vector3.BACK)*0.75).normalized())
	assert_bool((built.arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array)==_triangle()).is_true()

func test_cancelled_identity_normals_keep_a_finite_unit_direction()->void:
	var part:=_part({"face_jaw":_target(_triangle(),Vector3.FORWARD)})
	var built:=Merge._arrays([_entry(part)],{"jaw":0.5},["smile"])
	_assert_normals(built.arrays[Mesh.ARRAY_NORMAL],Vector3.BACK)
	_assert_normals(built.shapes[0][Mesh.ARRAY_NORMAL],Vector3.BACK)

func test_merging_does_not_mutate_cached_source_mesh_arrays()->void:
	var part:=_part({"face_jaw":_target(_triangle(0.0,0.5)),"smile":_target(_triangle(0.4,0.0))})
	var before:Array=part.mesh.surface_get_arrays(0).duplicate(true)
	var before_shapes:Array=part.mesh.surface_get_blend_shape_arrays(0).duplicate(true)
	var merged:=Merge._merge([_entry(part)],{"jaw":0.8},true)
	assert_int(merged.get_blend_shape_count()).is_equal(1)
	assert_str(String(merged.get_blend_shape_name(0))).is_equal("smile")
	var after:=part.mesh.surface_get_arrays(0)
	var after_shapes:=part.mesh.surface_get_blend_shape_arrays(0)
	for channel in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL]:
		assert_bool(after[channel]==before[channel]).is_true()
		for index in before_shapes.size():assert_bool(after_shapes[index][channel]==before_shapes[index][channel]).is_true()
