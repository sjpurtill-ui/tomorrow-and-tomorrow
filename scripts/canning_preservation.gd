extends RefCounted
## Current-day plant capacity converts actual surplus, never creates food.
const Ops=preload("res://scripts/technology_operations.gd")
const YIELD:=0.90
static func preserve(daily_demand:float,traveling:bool)->Dictionary:
	var result:Dictionary={}
	var state=WorldSimulation.state
	if traveling or not state.settlement_site_committed:return result
	var capacity:=Ops.service("food_preservation")
	if capacity<=0:return result
	capacity=minf(capacity,preload("res://scripts/canning_capacity.gd").available_input(state.food_stocks,daily_demand))
	for food:String in preload("res://scripts/canning_capacity.gd").PERISHABLES:
		var amount:=minf(capacity,maxf(0,float(state.food_stocks.get(food,0.0))))
		if amount<=0:continue
		state.food_stocks[food]-=amount
		state.food_stocks["Preserved food"]=float(state.food_stocks.get("Preserved food",0.0))+amount*YIELD
		Ops.data().services["food_preservation"]-=amount
		result[food]=amount
		capacity-=amount
	return result
