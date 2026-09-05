extends GdUnitTestSuite
const VISUALS:=preload("res://scripts/landscape_resource_visuals.gd")
func _source(x:float,remaining:float)->Dictionary:
	return {"landscape_source":"woodland_catchment","position":Vector3(x,0,0),"remaining":remaining,"initial_amount":100.0,"area_km2":9.0}
func test_cutting_is_local_and_regrowth_restores_cover()->void:
	var source:=_source(0,20)
	var areas:=VISUALS.areas_from_ledgers([[source]],Vector2.ZERO)
	assert_float(VISUALS.retained_at(Vector2.ZERO,areas)).is_equal_approx(0.2,0.001)
	assert_float(VISUALS.retained_at(Vector2(4,0),areas)).is_equal(1.0)
	source.remaining=80.0
	areas=VISUALS.areas_from_ledgers([[source]],Vector2.ZERO)
	assert_float(VISUALS.retained_at(Vector2.ZERO,areas)).is_equal_approx(0.8,0.001)
func test_multiple_city_ledgers_keep_their_geographic_footprints()->void:
	var areas:=VISUALS.areas_from_ledgers([[_source(0,20)],[_source(10,60)]],Vector2.ZERO)
	assert_float(VISUALS.retained_at(Vector2(10,0),areas)).is_equal_approx(0.6,0.001)
	assert_float(VISUALS.retained_at(Vector2(5,0),areas)).is_equal(1.0)
func test_fully_grown_and_nonwoodland_records_do_not_cut_terrain()->void:
	var ordinary:={"resource":"Timber","position":Vector3.ZERO,"remaining":0.0,"initial_amount":100.0}
	assert_int(VISUALS.areas_from_ledgers([[_source(0,100),ordinary]],Vector2.ZERO).size()).is_equal(0)
func test_gpu_area_budget_keeps_nearest_cutting()->void:
	var ledger:Array=[]
	for i in 90: ledger.append(_source(float(i)*10.0,20))
	var areas:=VISUALS.areas_from_ledgers([ledger],Vector2.ZERO)
	assert_int(areas.size()).is_equal(32)
	assert_float(areas[0].x).is_equal(0.0)
func test_materials_have_distinct_physical_surface_types()->void:
	assert_bool(VISUALS.surface_style("Limestone").outcrops).is_true()
	assert_bool(VISUALS.surface_style("Clay").outcrops).is_false()
	assert_bool(VISUALS.surface_style("Deep Aquifer").outcrops).is_false()
	assert_bool(VISUALS.surface_style("Copper Ore").rock==VISUALS.surface_style("Iron Ore").rock).is_false()
