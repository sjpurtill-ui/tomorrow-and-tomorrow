extends GdUnitTestSuite
const KIT=preload("res://scripts/settlement_architecture_kit.gd")
const EARLY=preload("res://scripts/early_settlement_visual.gd")
const KNOWLEDGE=preload("res://scripts/settlement_architecture_knowledge.gd")
func before_test()->void:
	GameState.reset_for_new_world(42);SettlementModel.reset_for_new_world()
func test_twenty_four_distinct_building_meshes_have_finite_physical_dimensions()->void:
	var fingerprints:Dictionary={}
	for family:String in KIT.FAMILIES:
		for type:String in KIT.TYPES:
			var mesh:=KIT.mesh_for(family+"_"+type,3)
			var box:=mesh.get_aabb()
			assert_float(box.size.x).is_between(1,12)
			assert_float(box.size.z).is_between(1,12)
			assert_float(box.size.y).is_between(1,20)
			var data:=mesh.surface_get_arrays(0)
			fingerprints[hash(var_to_bytes(data))]=true
	assert_int(fingerprints.size()).is_equal(24)
func test_recorded_generation_selects_building_family_without_repainting_old_homes()->void:
	var plot:={"id":1,"seed":12,"land_use":"mixed_household","fabric_generation":4,"storeys":2}
	assert_str(KIT.kind(plot)).is_equal("masonry_terrace")
	GameState.known_discoveries=["structural_steel","reinforced_concrete","safety_lifts"]
	GameState.elapsed_days=900000
	assert_str(KIT.kind(plot)).is_equal("masonry_terrace")
	plot.fabric_generation=11
	assert_str(KIT.kind(plot)).is_equal("industrial_terrace")
	plot.fabric_generation=12
	assert_str(KIT.kind(plot)).is_equal("modern_terrace")
func test_completed_modern_parcels_use_shared_placement_and_render_batches()->void:
	var plot:={"id":1,"seed":12,"land_use":"mixed_household","fabric_generation":12,"storeys":8,"form":"metropolitan_mixed_block","status":"active","area_ha":.5,"roof_coverage":.3,"polygon":PackedVector2Array([Vector2(-.06,-.06),Vector2(.06,-.06),Vector2(.06,.06),Vector2(-.06,.06)]),"centroid":Vector2.ZERO,"frontage_route_id":1}
	var plots:Array[Dictionary]=[plot]
	var routes:Array[Dictionary]=[{"id":1,"active":true,"points":PackedVector2Array([Vector2(-.08,0),Vector2(.08,0)]),"width_m":3.0}]
	var plan:=EARLY.layout(plots,routes,func(_p:Vector2):return true)
	assert_int(plan.buildings.size()).is_greater(0)
	for record:Dictionary in plan.buildings:
		assert_bool(Geometry2D.clip_polygons(record.footprint,plot.polygon).is_empty()).is_true()
		assert_str(String(record.early_kind)).is_equal("modern_terrace")
	var parent:Node3D=auto_free(Node3D.new())
	EARLY.render(plan,Vector3.ZERO,func(_x:float,_z:float):return 0.0,parent)
	assert_int(parent.get_child_count()).is_greater(0)
	assert_str(String(parent.get_child(0).name)).starts_with("SettlementArchitecture_")
	EARLY.remember_layout(plan,plots)
	var again:=EARLY.layout(plots,routes,func(_p:Vector2):return true)
	assert_int(again.buildings.size()).is_equal(plan.buildings.size())
	assert_vector(again.buildings[0].position).is_equal(plan.buildings[0].position)
func test_modern_fabric_requires_adopted_construction_knowledge()->void:
	assert_int(KNOWLEDGE.ceiling()).is_equal(10)
	GameState.known_discoveries=["structural_steel","reinforced_concrete","safety_lifts"]
	assert_int(KNOWLEDGE.ceiling()).is_equal(10)
	GameState.discovery_adoption={"structural_steel":1.0,"reinforced_concrete":1.0,"safety_lifts":1.0}
	assert_int(KNOWLEDGE.ceiling()).is_equal(12)
	var cost:Dictionary=SettlementModel._fabric_upgrade_cost({"land_use":"mixed_household"},12)
	assert_bool(cost.has("Iron Ore") and cost.has("Limestone") and cost.has("Fine Sand")).is_true()
