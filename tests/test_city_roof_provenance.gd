extends GdUnitTestSuite
const Kit:=preload("res://scripts/settlement_architecture_kit.gd")
const Fixture:=preload("res://tests/city_evolution_visual_fixture.gd")

func before_test()->void:
	Fixture.initialize()

func _plot(plan:String="timber_span_on_rubble")->Dictionary:
	return {"id":1,"seed":12,"land_use":"mixed_household","fabric_generation":9,
		"storeys":2,"material_family":"stone","roof_plan":plan}

func _has_roof_code(mesh:Mesh,code:float)->bool:
	var colors:PackedColorArray=mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	for color in colors:
		# ArrayMesh stores these vertex colours as normalized RGBA8.
		if absf(color.a-code)<1.0/255.0:return true
	return false

func test_early_prepared_city_has_no_unrecorded_tiles_or_chimneys()->void:
	var snapshot:=Fixture.snapshot(200)
	assert_int(int(snapshot.tier)).is_equal(9)
	assert_bool("wall_chimneys" in GameState.known_discoveries).is_false()
	var before:=var_to_bytes([snapshot.plots,GameState.known_discoveries,GameState.discovery_adoption])
	for plot:Dictionary in snapshot.plots:
		assert_bool(Kit.chimney_for(plot)).is_false()
		assert_bool(_has_roof_code(Kit.mesh_for_plot(plot),Kit.ROOF_TILE)).is_false()
	assert_bool(before==var_to_bytes([snapshot.plots,GameState.known_discoveries,GameState.discovery_adoption])).is_true()

func test_recorded_roof_plan_selects_real_mesh_surface_and_flat_silhouette()->void:
	var timber:=Kit.mesh_for_plot(_plot())
	var tile:=Kit.mesh_for_plot(_plot("fired_tile_roof"))
	var slab:=Kit.mesh_for_plot(_plot("rubble_slab"))
	assert_bool(_has_roof_code(timber,Kit.ROOF_SHINGLE)).is_true()
	assert_bool(_has_roof_code(timber,Kit.ROOF_TILE)).is_false()
	assert_bool(_has_roof_code(tile,Kit.ROOF_TILE)).is_true()
	assert_bool(_has_roof_code(slab,Kit.ROOF_EARTH)).is_true()
	assert_float(slab.get_aabb().end.y).is_less(timber.get_aabb().end.y-1.0)
	assert_object(tile).is_not_same(timber)
	assert_object(slab).is_not_same(timber)

func test_missing_roof_records_keep_conservative_geometry_and_paid_tile_provenance()->void:
	var old:=_plot();old.erase("roof_plan")
	assert_bool(_has_roof_code(Kit.mesh_for_plot(old),Kit.ROOF_TILE)).is_false()
	old.building_materials={"id":"tiled_masonry","applied":["fired_roof_tiles"]}
	assert_bool(_has_roof_code(Kit.mesh_for_plot(old),Kit.ROOF_TILE)).is_true()
	old.building_materials={};old.supply_provenance={"Roof Tiles":2.0}
	assert_bool(_has_roof_code(Kit.mesh_for_plot(old),Kit.ROOF_TILE)).is_true()
	old.roof_plan="timber_span_on_rubble"
	assert_bool(_has_roof_code(Kit.mesh_for_plot(old),Kit.ROOF_TILE)).is_false()

func test_actual_chimney_practice_changes_mesh_but_age_and_unrelated_knowledge_do_not()->void:
	var plot:=_plot()
	var plain:=Kit.mesh_for_plot(plot)
	GameState.elapsed_days=3000.0*365.0
	GameState.known_discoveries=["fired_roof_tiles","structural_steel"]
	assert_object(Kit.mesh_for_plot(plot)).is_same(plain)
	GameState.known_discoveries.append("wall_chimneys")
	var chimney:=Kit.mesh_for_plot(plot)
	assert_bool(Kit.chimney_for(plot)).is_true()
	assert_int(chimney.surface_get_array_len(0)).is_greater(plain.surface_get_array_len(0))
	GameState.known_discoveries.clear()
	plot.building_materials={"applied":["wall_chimneys"]}
	assert_object(Kit.mesh_for_plot(plot)).is_same(chimney)
	plot.fabric_generation=4
	assert_bool(Kit.chimney_for(plot)).is_true()
	plot.building_materials={}
	assert_bool(Kit.chimney_for(plot)).is_false()

func test_flat_recorded_roofs_do_not_leave_floating_ridge_lanterns()->void:
	for type:String in Kit.TYPES:
		var mesh:=Kit.mesh_for("masonry_"+type,2,0,"stone|slab")
		assert_float(mesh.get_aabb().end.y).override_failure_message(type+" retains an unsupported ridge object").is_less_equal(6.7)
		assert_bool(_has_roof_code(mesh,Kit.ROOF_TILE)).is_false()

func test_modern_records_keep_current_silhouette_and_do_not_gain_pitched_roofs()->void:
	var plot:=_plot("rubble_slab");plot.fabric_generation=12;plot.storeys=8
	var original:=Kit.mesh_for("modern_terrace",8)
	var recorded:=Kit.mesh_for_plot(plot)
	assert_vector(recorded.get_aabb().size).is_equal_approx(original.get_aabb().size,Vector3.ONE*.001)
	assert_bool(_has_roof_code(recorded,Kit.ROOF_SLATE)).is_true()
