extends GdUnitTestSuite
class Terrain extends "res://scripts/local_terrain.gd":
	var samples:=0
	var full_reports:=0
	func _surface_material_catchments(origin:Vector3)->Dictionary:
		samples+=1
		return {"Timber":{"density":0.5,"position":origin,"seed":GameState.world_seed},"Stone":{"density":0.2},"Fiber Plants":{"density":0.1}}
	func _sample_civilization_geography(origin:Vector2)->Dictionary:
		full_reports+=1
		return {"surface_material_catchments":_cached_civilization_surface_materials(origin)}
func test_surface_search_does_not_sample_full_geography_and_returns_private_data()->void:
	var terrain:Terrain=auto_free(Terrain.new())
	var result:Dictionary=terrain._civilization_surface_materials(Vector2(20,40))
	assert_int(terrain.samples).is_equal(1);assert_int(terrain.full_reports).is_equal(0)
	result.Timber.density=0
	var again:Dictionary=terrain._civilization_surface_materials(Vector2(20,40))
	assert_float(again.Timber.density).is_equal(0.5)
	assert_int(terrain.samples).is_equal(1)
	var full:Dictionary=terrain._civilization_geography(Vector2(20,40))
	assert_dict(full.surface_material_catchments).is_equal(again)
	assert_int(terrain.samples).is_equal(1);assert_int(terrain.full_reports).is_equal(1)
func test_surface_cache_is_bounded_and_new_seeds_get_fresh_potential()->void:
	var terrain:Terrain=auto_free(Terrain.new())
	var previous:=GameState.world_seed
	for i in 520:terrain._civilization_surface_materials(Vector2(i,0))
	assert_int(terrain.civilization_surface_cache.size()).is_equal(512)
	var count:int=terrain.samples
	GameState.world_seed=previous+1
	var result:Dictionary=terrain._civilization_surface_materials(Vector2(519,0))
	assert_int(terrain.samples).is_equal(count+1)
	assert_int(result.Timber.seed).is_equal(previous+1)
	GameState.world_seed=previous
