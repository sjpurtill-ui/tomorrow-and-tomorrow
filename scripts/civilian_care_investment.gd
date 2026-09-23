extends RefCounted
const Care=preload("res://scripts/civilian_care.gd")
## Care supplies are raw materials and Civilian Goods, which city trade moves
## (settlement_model reads Care.targets()); no production order is placed.
static func recommendation()->Dictionary:
	return {}

## Care supplies the local stock lacks.
static func shortfall()->Dictionary:
	var needs:=Care.targets()
	var result:Dictionary={}
	for item:String in needs:
		var missing:=float(needs[item])-float(WorldSimulation.state.resource_stockpiles.get(item,0))
		if missing>0:result[item]=missing
	return result
