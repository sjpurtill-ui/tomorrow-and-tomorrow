extends GdUnitTestSuite
var calls:=0
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("performance",774)
	WorldSimulation.context_provider=func(_point:Vector2)->Dictionary:return {}
	WorldSimulation.surface_material_provider=surface
	calls=0
func after_test()->void:
	WorldSimulation.context_provider=Callable();WorldSimulation.clear()
func surface(point:Vector2)->Dictionary:
	calls+=1
	return {"Timber":{"density":.6,"area_km2":9.0,"position":Vector3(point.x,0,point.y)}}
func _settled()->Dictionary:
	return {"settled":true,"origin":Vector3.ZERO}

func test_ground_is_surveyed_once_and_a_low_pool_opens_only_new_rings()->void:
	WorldSimulation.scoped("performance",func()->void:
		var resources:=WorldSimulation.resources
		var state:=WorldSimulation.state
		state.resource_deposits.clear();state.population_allocations.Logistics=6
		resources.ensure_pools(_settled())
		var pool:=preload("res://scripts/material_pools.gd").pool_of("Timber")
		assert_bool(pool.is_empty()).is_false()
		# Timber opens ring 1; stone and fibre, finding none, look out to the
		# carriers' second ring. Each ring is sampled once for every kind.
		assert_int(int(pool.ring)).is_equal(1)
		var initial_calls:=calls
		assert_int(initial_calls).is_equal(8+16)
		for day in 5:resources.ensure_pools(_settled())
		assert_int(calls).is_equal(initial_calls)
		pool.remaining=0.0
		resources.ensure_pools(_settled())
		assert_int(int(pool.ring)).is_equal(2)
		assert_int(calls).is_equal(initial_calls)
		# More carriers reach one ring farther: only its 24 cells are new.
		state.population_allocations.Logistics=12;pool.remaining=0.0
		resources.ensure_pools(_settled())
		assert_int(int(pool.ring)).is_equal(3)
		assert_int(calls-initial_calls).is_equal(24)
		assert_bool(SaveSystem._capture_reflected(resources,SaveSystem.REFLECT_SKIP.ResourceSystem).has("_surface_rings")).is_false()
		resources.reset_for_new_world();assert_dict(resources._surface_rings).is_empty()
	)
func test_empty_ground_is_not_resurveyed_and_a_new_provider_rechecks_it()->void:
	WorldSimulation.scoped("performance",func()->void:
		WorldSimulation.surface_material_provider=func(_point:Vector2)->Dictionary:calls+=1;return {}
		var resources:=WorldSimulation.resources;WorldSimulation.state.resource_deposits.clear()
		WorldSimulation.state.population_allocations.Logistics=6
		resources.ensure_pools(_settled())
		assert_array(WorldSimulation.state.resource_deposits).is_empty()
		var before:=calls
		for day in 3:resources.ensure_pools(_settled())
		assert_int(calls).is_equal(before)
		WorldSimulation.surface_material_provider=surface
		resources.ensure_pools(_settled())
		assert_bool(preload("res://scripts/material_pools.gd").pool_of("Timber").is_empty()).is_false()
		for i in resources.SURFACE_RING_ORIGIN_LIMIT+2:
			resources._surveyed_ring(Vector2(i*10,0),1)
		assert_int(resources._surface_rings.size()).is_less_equal(resources.SURFACE_RING_ORIGIN_LIMIT)
	)
func test_observer_summary_leaves_full_city_forecast_and_history_intact()->void:
	WorldSimulation.scoped("performance",func()->void:
		WorldSimulation.state.settlement_site_committed=true
		WorldSimulation.state.settlement_completed=["Hearth Circle"]
		WorldSimulation.settlements.ensure_founded()
		var city:Dictionary=WorldSimulation.state.player_settlements[0]
		WorldSimulation.state.simulation_metrics={"material_capacity":.4,"logistics":.7,"food_days":130.0,"food_forecast_90":{"ending_food":9000},"food_demand":{"children":10}}
		var full:=WorldSimulation.settlements.city_resource_snapshot(city.id,false)
		var summary:=WorldSimulation.settlements.city_resource_snapshot(city.id,false,true)
		assert_dict(summary.metrics).is_equal({"material_capacity":.4,"logistics":.7,"food_days":130.0})
		assert_dict(full.metrics).is_equal(WorldSimulation.state.simulation_metrics)
		summary.metrics.food_days=0
		assert_float(WorldSimulation.state.simulation_metrics.food_days).is_equal(130.0)
		assert_dict(WorldSimulation.state.simulation_metrics.food_forecast_90).is_equal({"ending_food":9000})
	)
