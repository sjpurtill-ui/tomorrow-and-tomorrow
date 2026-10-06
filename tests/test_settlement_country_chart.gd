extends GdUnitTestSuite
const CHART=preload("res://scripts/settlement_country_chart.gd")

func test_chart_diameter_stays_small_without_enlarging_physical_roofs()->void:
	for span in [2.0,30.0,100.0,300.0,1000.0,18000.0]:
		var diameter:=CHART.diameter_for(span,900.0)
		assert_float(diameter).is_less_equal(4.0)
		assert_float(diameter/span*900.0).is_less_equal(14.0)
	assert_float(CHART.diameter_for(30.0,900.0)/30.0*900.0).is_equal_approx(14.0,0.001)
	assert_float(CHART.diameter_for(300.0,900.0)/300.0*900.0).is_greater_equal(10.0)

func test_factual_site_states_get_distinct_marks()->void:
	assert_str(CHART.motif_for({"kind":"homestead"})).is_equal("field")
	assert_str(CHART.motif_for({"kind":"herder"})).is_equal("pasture")
	assert_str(CHART.motif_for({"kind":"site","resource":"Timber","category":"active"})).is_equal("wood")
	assert_str(CHART.motif_for({"kind":"site","resource":"Timber","category":"depleted"})).is_equal("cut_wood")
	assert_str(CHART.motif_for({"kind":"site","resource":"Timber","category":"regrowing"})).is_equal("young_wood")
	assert_str(CHART.motif_for({"kind":"site","resource":"Stone"})).is_equal("quarry")
	assert_str(CHART.motif_for({"kind":"site","resource":"Fiber Plants"})).is_equal("fiber")
	assert_str(CHART.motif_for({})).is_empty()

func test_chart_keeps_the_record_position_and_samples_ground_once()->void:
	var source:={"id":"farm:one","kind":"homestead","position":Vector2(1234,5678),"rotation":0.4}
	var before:=source.duplicate(true)
	var calls:=[0]
	var node:MeshInstance3D=auto_free(CHART.create(source,func(point:Vector2)->float:
		calls[0]+=1
		assert_vector(point).is_equal(source.position)
		return 2.0))
	assert_int(calls[0]).is_equal(1)
	assert_dict(source).is_equal(before)
	assert_str(node.get_meta("country_chart_record")).is_equal("farm:one")
	var arrays:=node.mesh.surface_get_arrays(0)
	for vertex:Vector3 in arrays[Mesh.ARRAY_VERTEX]:
		assert_vector(vertex).is_equal_approx(Vector3(1234,2.0002,5678),Vector3.ONE*0.00001)
	var offsets:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV2]
	assert_int(offsets.size()).is_equal((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	var furthest:=0.0
	for offset:Vector2 in offsets:
		assert_float(offset.length()).is_less_equal(0.5)
		furthest=maxf(furthest,offset.length())
	assert_float(furthest).is_greater(0.25)
	assert_vector(node.custom_aabb.size).is_equal(Vector3(4,0.02,4))
	assert_vector(node.mesh.custom_aabb.size).is_equal(Vector3(4,0.02,4))

func test_all_motifs_have_a_fixed_small_stroke_budget()->void:
	for motif in ["field","fiber","pasture","wood","cut_wood","young_wood","quarry","mineral"]:
		var lines:Array=CHART._lines(motif)
		assert_int(lines.size()).is_greater(0)
		assert_int(lines.size()).is_less_equal(CHART.MAX_STROKES)
