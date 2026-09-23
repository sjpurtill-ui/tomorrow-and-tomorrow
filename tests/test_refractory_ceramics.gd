extends GdUnitTestSuite
const K=preload("res://scripts/refractory_ceramics_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("potter",115)
func after_test()->void:WorldSimulation.clear()
func test_authored_branch_has_valid_distinct_production_contracts()->void:
	WorldSimulation.scoped("potter",func()->void:
		assert_int(K.entries().size()).is_equal(6)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for entry:Dictionary in K.entries():
			assert_int(int(entry.day)).is_equal(0);assert_dict(entry.effects).is_empty()
			assert_str(I.product(entry.production_items[0]).gate).is_equal(entry.id)
	)
