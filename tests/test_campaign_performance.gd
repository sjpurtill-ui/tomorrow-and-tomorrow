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
func test_front_search_reuses_potential_but_invalidates_used_sites_and_logistics()->void:
	WorldSimulation.scoped("performance",func()->void:
		var resources:=WorldSimulation.resources
		var state:=WorldSimulation.state
		state.resource_deposits.clear();state.population_allocations.Logistics=6
		var context:={"origin":Vector3.ZERO}
		var first:=resources._next_surface_front("Timber","woodland_catchment",context,.08)
		assert_bool(first.is_empty()).is_false()
		var initial_calls:=calls
		assert_dict(resources._next_surface_front("Timber","woodland_catchment",context,.08)).is_equal(first)
		assert_int(calls).is_equal(initial_calls)
		var copy:=first.duplicate(true);copy.landscape_source="woodland_catchment";copy.resource="Timber"
		state.resource_deposits.append(copy)
		var second:=resources._next_surface_front("Timber","woodland_catchment",context,.08)
		assert_bool(second.position!=first.position).is_true()
		assert_int(calls).is_greater(initial_calls)
		var before:=calls;state.population_allocations.Logistics=30
		resources._next_surface_front("Timber","woodland_catchment",context,.08)
		assert_int(calls).is_greater(before)
		assert_bool(SaveSystem._capture_reflected(resources,SaveSystem.REFLECT_SKIP.ResourceSystem).has("_surface_front_cache")).is_false()
		resources.reset_for_new_world();assert_dict(resources._surface_front_cache).is_empty()
	)
func test_failed_searches_cache_and_changing_provider_rechecks_ground()->void:
	WorldSimulation.scoped("performance",func()->void:
		WorldSimulation.surface_material_provider=func(_point:Vector2)->Dictionary:calls+=1;return {}
		var resources:=WorldSimulation.resources;WorldSimulation.state.resource_deposits.clear()
		var context:={"origin":Vector3.ZERO}
		assert_dict(resources._next_surface_front("Timber","woodland_catchment",context,.08)).is_empty()
		var before:=calls
		assert_dict(resources._next_surface_front("Timber","woodland_catchment",context,.08)).is_empty()
		assert_int(calls).is_equal(before)
		WorldSimulation.surface_material_provider=surface
		assert_bool(resources._next_surface_front("Timber","woodland_catchment",context,.08).is_empty()).is_false()
		WorldSimulation.context_provider=func(_point:Vector2)->Dictionary:return {}
		assert_bool(WorldSimulation.surface_material_provider.is_valid()).is_false()
		for i in resources.SURFACE_FRONT_CACHE_LIMIT+2:
			WorldSimulation.surface_material_provider=surface
			resources._next_surface_front("Timber","woodland_catchment",{"origin":Vector3(i*10,0,0)},.08)
		assert_int(resources._surface_front_cache.size()).is_less_equal(resources.SURFACE_FRONT_CACHE_LIMIT)
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
