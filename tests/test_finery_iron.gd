extends GdUnitTestSuite
const K=preload("res://scripts/finery_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("potter",120)
func after_test()->void:WorldSimulation.clear()
func test_discovery_contracts_remove_unpaid_furnace_bonuses()->void:
	WorldSimulation.scoped("potter",func()->void:
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for entry:Dictionary in preload("res://scripts/resource_knowledge_catalog.gd").entries():
			if entry.id in ["coke_firing","blast_furnace"]:
				assert_dict(entry.effects).is_empty()
				assert_str(I.product(entry.production_items[0]).gate).is_equal(entry.id)
		assert_int(int(K.entries()[0].day)).is_equal(0)
	)
