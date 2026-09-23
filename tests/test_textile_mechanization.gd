extends GdUnitTestSuite
const K=preload("res://scripts/textile_mechanization.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("mill_ruler",995)
func after_test()->void:WorldSimulation.clear()
func test_six_mechanisms_have_valid_distinct_contracts()->void:
	WorldSimulation.scoped("mill_ruler",func()->void:
		assert_int(K.entries().size()).is_equal(6)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)
