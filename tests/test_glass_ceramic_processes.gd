extends GdUnitTestSuite
const K=preload("res://scripts/glass_ceramic_process_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const ITEMS=["graded_glass_cullet","cullet_glass","annealed_glass_blanks","annealed_optical_lenses","pottery_plaster_molds","stoneware_body","formed_stoneware_vessels","slip_cast_stoneware","fired_cast_stoneware","glazed_stoneware_vessels","stoneware_purified_brine"]
const INTERMEDIATES=["Graded Glass Cullet","Annealed Glass Blanks","Pottery Plaster Molds","Stoneware Body","Stoneware Vessels","Dry Cast Stoneware","Glazed Stoneware Vessels"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("ceramics",128)
func after_test()->void:WorldSimulation.clear()
func test_five_methods_have_operating_routes_and_no_flat_effects()->void:
	WorldSimulation.scoped("ceramics",func()->void:
		assert_int(K.entries().size()).is_equal(5)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for e:Dictionary in K.entries():assert_dict(e.effects).is_empty()
		for item:String in ITEMS:assert_bool(I.product(item).is_empty()).is_false())
