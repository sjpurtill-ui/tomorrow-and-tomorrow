extends GdUnitTestSuite
const K=preload("res://scripts/type_composition_knowledge.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("types",994)
func after_test()->void:WorldSimulation.clear()
func test_catalog_preserves_wood_or_metal_composition_foundations()->void:
	WorldSimulation.scoped("types",func()->void:
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		assert_int(K.entries().size()).is_equal(2)
		assert_array(K.entries()[1].requires_all).is_equal(["phonetic_notation"])
		assert_array(K.entries()[1].requires_any).is_equal([["wooden_movable_type","metal_type_casting"]])
		var requirements=preload("res://scripts/technology_requirements.gd")
		assert_bool(requirements.evaluate(K.entries()[1],["phonetic_notation","wooden_movable_type"]).ready).is_true()
		assert_bool(requirements.evaluate(K.entries()[1],["phonetic_notation","metal_type_casting"]).ready).is_true()
		assert_bool(requirements.evaluate(K.entries()[1],["phonetic_notation"]).ready).is_false())
