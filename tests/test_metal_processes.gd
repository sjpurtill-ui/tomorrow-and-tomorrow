extends GdUnitTestSuite
const K=preload("res://scripts/metal_process_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const ITEMS=["annealed_copper","annealed_copper_wire","case_hardened_gears","fed_copper_castings","brazed_steel_fittings","cast_fitted_vessels","arc_welded_panels","welded_pressure_vessels","spot_welded_panels","metal_cart_beds","continuous_steel_slabs","slab_rolled_sheets"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("metal",120)
func after_test()->void:WorldSimulation.clear()
func test_seven_methods_keep_distinct_paid_operating_recipes()->void:
	WorldSimulation.scoped("metal",func()->void:
		assert_int(K.entries().size()).is_equal(7)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for item:String in ITEMS:assert_bool(I.product(item).is_empty()).is_false()
		assert_float(float(I.product("arc_welded_panels").power)).is_greater(0.0)
		assert_bool(I.product("spot_welded_panels").materials.has("Steel Wire")).is_false()
	)
