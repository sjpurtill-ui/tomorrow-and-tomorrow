extends RefCounted
const Care=preload("res://scripts/civilian_care.gd")
static func recommendation()->Dictionary:
	var needs:=Care.targets()
	for item:String in needs:
		if float(WorldSimulation.state.resource_stockpiles.get(item,0))>=float(needs[item]):continue
		var order:=preload("res://scripts/civilian_production_planner.gd").supply(item,ceili(float(needs[item])),{})
		if not order.is_empty():return order
	return {}
