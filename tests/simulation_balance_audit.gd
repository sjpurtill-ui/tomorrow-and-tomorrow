extends Node
## Controlled one-year stress scenarios; failures are invariants, not balance targets.
## Initial stores stay at the normal founding amount, deliberately stressing larger groups.
const Day=preload("res://scripts/civilization_day.gd")
var failures:Array[String]=[]
func _ready()->void:
	for scenario in [{"seed":4242,"people":60,"wood":0.65},{"seed":74119,"people":120,"wood":0.65},{"seed":991704,"people":240,"wood":0.01}]:
		WorldSimulation.clear()
		WorldSimulation.context_provider=func(origin:Vector2)->Dictionary:
			var wood:={"position":Vector3(origin.x,0,origin.y),"density":scenario.wood,"area_km2":9.0}
			return {"environment_profile":PlanetEnvironment.profile_at(origin),"surface_water_distance_km":0.1,"surface_water_recognized":true,"woodland_catchment":wood,"surface_material_catchments":{"Timber":wood,"Stone":{"position":Vector3(origin.x,0,origin.y),"density":0.35,"area_km2":9.0},"Fiber Plants":{"position":Vector3(origin.x,0,origin.y),"density":0.5,"area_km2":9.0}}}
		WorldSimulation.create_actor("audit",scenario.seed,Vector2.ZERO)
		WorldSimulation.enabled=true
		WorldSimulation.scoped("audit",func()->void:
			WorldSimulation.state.ensure_population_total(scenario.people)
			WorldSimulation.world.scout_land_authority=func(_p:Vector2)->bool:return true
		)
		WorldSimulation.submit("audit",{"kind":"ambition","id":"makers"})
		var founded:=WorldSimulation.submit("audit",{"kind":"found"})
		if founded.has("error"):failures.append(str(founded))
		for day in range(1,366):
			WorldSimulation.scoped("audit",func()->void:
				WorldSimulation.state.elapsed_days=day
				preload("res://scripts/civilization_controller.gd").choose_orders("audit")
				Day.advance(day,Day.context(Vector2.ZERO))
			)
			if day in [30,90,180,365]:
				WorldSimulation.scoped("audit",func()->void:
					var state:=WorldSimulation.state
					print("AUDIT_CHECKPOINT ",JSON.stringify({"seed":scenario.seed,"starting_population":scenario.people,"wood_density":scenario.wood,"day":day,"population":state.population_total,"food_days":state.simulation_metrics.get("food_days",0),"intake":state.simulation_metrics.get("food_intake_ratio",0),"built":state.settlement_completed,"timber":state.resource_stockpiles.get("Timber",0),"fiber":state.resource_stockpiles.get("Fiber Plants",0),"discoveries":state.known_discoveries.size(),"workers":state.population_allocations}))
				)
			if day%30==0:await get_tree().process_frame
		WorldSimulation.scoped("audit",func()->void:
			var state:=WorldSimulation.state
			if state.population_total<=0:failures.append("Settlement died: %s" % scenario.seed)
			if state.settlement_completed.size()<2:failures.append("Founding construction stalled: %s" % scenario.seed)
			for amount in state.resource_stockpiles.values():
				if not is_finite(float(amount)) or float(amount)<0:failures.append("Invalid material stock: %s" % scenario.seed)
			for key in ["food_days","food_intake_ratio"]:
				var amount:=float(state.simulation_metrics.get(key,-1))
				if not is_finite(amount) or amount<0:failures.append("Invalid %s: %s" % [key,scenario.seed])
		)
		var payload:=WorldSimulation.export_state()
		var restored:=WorldSimulation.import_state(bytes_to_var(var_to_bytes(payload)))
		if restored.has("error"):failures.append(str(restored))
		print("AUDIT_RESTORE ",scenario.seed," ",restored)
	WorldSimulation.clear()
	print("AUDIT_FAILURES ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
