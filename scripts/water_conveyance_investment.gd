extends RefCounted
const Water=preload("res://scripts/water_conveyance.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")

static func recommendation()->Dictionary:
	var state=WorldSimulation.state
	if state.convoy_traveling or not state.settlement_site_committed or state.effective_workers("Construction")<4:return {}
	if not state.resource_settlement_id.is_empty():return {}
	if "gravity_conduit_grade_control" not in Water.adopted():return {}
	if float(state.water_metrics.get("intake_ratio",1))>=.98 and float(state.water_metrics.get("source_distance_km",0))<.5:return {}
	var context:=preload("res://scripts/civilization_day.gd").context(Vector2(state.settlement_founded_at.x,state.settlement_founded_at.z))
	var height_at:Callable=context.get("terrain_height_at",Callable())
	for source:Dictionary in context.get("water_conveyance_sources",[]):
		for material:String in ["ceramic","timber"]:
			var terms:=Water.quote(source,state.settlement_founded_at,height_at,material)
			if bool(terms.get("ok",false)):
				Water.install(source,state.settlement_founded_at,height_at,material)
				return {}
			for item:String in terms.get("cost",{}):
				if float(state.resource_stockpiles.get(item,0))>=float(terms.cost[item]):continue
				var order:=Supply.supply(item,ceili(float(terms.cost[item])),{})
				if not order.is_empty():return order
	return {}
