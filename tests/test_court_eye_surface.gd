extends GdUnitTestSuite
const Merge=preload("res://scripts/hud/court_figure_merge.gd")
const Figure=preload("res://scripts/hud/court_figure_3d.gd")

func test_fallback_eye_layers_keep_pupil_and_glint_above_the_iris()->void:
	for lit in [true,false]:
		var iris:=Figure.material("IRIS",Color("5a3a22"),0,lit)
		var pupil:=Figure.material("PUPIL",Color("140d08"),0,lit)
		var glint:=Figure.material("EYE_SHINE",Color.WHITE,0,lit)
		assert_int(pupil.render_priority).is_greater(iris.render_priority)
		assert_int(glint.render_priority).is_greater(pupil.render_priority)

func test_each_eye_gets_its_own_surface_despite_asymmetric_spacing()->void:
	var vertices:=PackedVector3Array([
		Vector3(-0.060,1.5,0.0),Vector3(-0.020,1.52,0.0),Vector3(-0.040,1.51,0.0),
		Vector3(0.025,1.48,0.0),Vector3(0.070,1.51,0.0),Vector3(0.0475,1.495,0.0)])
	var before:=vertices.duplicate()
	var uv:PackedVector2Array=Merge._feature_uv(vertices)
	for start in [0,3]:
		assert_float(uv[start].distance_to(Vector2.ZERO)).is_less(0.0001)
		assert_float(uv[start+1].distance_to(Vector2.ONE)).is_less(0.0001)
		assert_float(uv[start+2].distance_to(Vector2(0.5,0.5))).is_less(0.0001)
	assert_bool(vertices==before).is_true()

func test_eye_details_keep_their_scale_on_child_and_adult_bodies()->void:
	var vertices:=PackedVector3Array([Vector3(-0.05,1.5,0),Vector3(-0.02,1.52,0),Vector3(-0.035,1.51,0)])
	var small:=vertices.duplicate()
	for i in small.size():small[i]=small[i]*0.65+Vector3(0,0.2,0)
	var adult:PackedVector2Array=Merge._feature_uv(vertices)
	var child:PackedVector2Array=Merge._feature_uv(small)
	for i in adult.size():assert_float(adult[i].distance_to(child[i])).is_less(0.0001)

func test_degenerate_feature_has_finite_coordinates()->void:
	var uv:PackedVector2Array=Merge._feature_uv(PackedVector3Array([Vector3(0.03,1.5,0),Vector3(0.03,1.5,0)]))
	for point in uv:assert_bool(point.is_finite()).is_true()

func test_brow_clearance_survives_expression_and_does_not_change_source()->void:
	var source:=ArrayMesh.new();source.blend_shape_mode=Mesh.BLEND_SHAPE_MODE_NORMALIZED
	source.add_blend_shape("brows_up")
	var a:=[];a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(.02,1.5,0),Vector3(.04,1.5,0),Vector3(.03,1.51,0)])
	a[Mesh.ARRAY_NORMAL]=PackedVector3Array([Vector3.BACK,Vector3.BACK,Vector3.BACK])
	a[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2])
	var shape:=[];shape.resize(Mesh.ARRAY_MAX)
	shape[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(.02,1.51,0),Vector3(.04,1.51,0),Vector3(.03,1.52,0)])
	shape[Mesh.ARRAY_NORMAL]=a[Mesh.ARRAY_NORMAL]
	source.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a,[shape])
	var part:MeshInstance3D=auto_free(MeshInstance3D.new());part.mesh=source
	var before:=source.surface_get_arrays(0)
	var built:=Merge._arrays([[part,0,"BROW"]],{},["brows_up"])
	for i in 3:
		var resting:Vector3=built.arrays[Mesh.ARRAY_VERTEX][i]
		var raised:Vector3=built.shapes[0][Mesh.ARRAY_VERTEX][i]
		assert_float(resting.z).is_greater(0.0)
		assert_float(raised.z).is_equal_approx(resting.z,0.00001)
		assert_float(raised.y-resting.y).is_equal_approx(0.01,0.00001)
	assert_bool(source.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==before[Mesh.ARRAY_VERTEX]).is_true()
