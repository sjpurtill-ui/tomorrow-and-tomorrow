extends RefCounted
const Rail=preload("res://scripts/rail_freight.gd")
const Stock=preload("res://scripts/bill_stock.gd")
## One maintenance reserve unit: a track panel, a brake set, timber and iron,
## held as raw materials and Civilian Goods so city trade can move it.
static var RESERVE_UNIT:=preload("res://scripts/goods_bills.gd").flatten({"Timber Rail Panels":1.0,"Rail Brake Sets":1.0,"Timber":1.0,"Wrought Iron":1.0})
static func maintenance_targets(city_id:String)->Dictionary:
	var needs:Dictionary={}
	for line:Dictionary in Rail.data().lines:
		if String(line.source_id)!=city_id or Rail.F.building(line):continue
		Stock.add_scaled(needs,RESERVE_UNIT,maxf(2,float(line.route.length_km)*.2))
	return needs
static func candidate()->Dictionary:
	var source:=Rail.local_city()
	if source.is_empty() or not Rail.available_city(source) or WorldSimulation.state.effective_workers("Construction")<4:return {}
	for gate:String in Rail.REQUIRED:
		if not bool(WorldSimulation.military._knowledge_gate(gate,.25).unlocked):return {}
	var options:Array[Dictionary]=[]
	for destination:Dictionary in WorldSimulation.state.player_settlements:
		if String(destination.id)==source or not Rail.available_city(String(destination.id)):continue
		var established:=false
		for delivery:Dictionary in WorldSimulation.state.city_trade_history:
			if source in [delivery.source_id,delivery.destination_id] and String(destination.id) in [delivery.source_id,delivery.destination_id]:established=true;break
		if not established:continue
		options.append(destination)
	options.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var origin:=WorldSimulation.settlements._record_position(Rail.city(source))
		return origin.distance_to(WorldSimulation.settlements._record_position(a))<origin.distance_to(WorldSimulation.settlements._record_position(b)))
	# Bound proposal surveys while allowing a blocked nearest city to be skipped.
	var surveyed:=0
	for destination:Dictionary in options:
		var exists:=false
		for line:Dictionary in Rail.data().lines:
			if source in [line.source_id,line.destination_id] and String(destination.id) in [line.source_id,line.destination_id]:exists=true;break
		if exists:continue
		if surveyed>=3:break
		surveyed+=1
		var terms:=Rail.quote(source,String(destination.id))
		if not terms.has("cost"):continue
		return {"source":source,"destination":String(destination.id),"terms":terms}
	return {}
## Installs a supplied line. Bills are raw materials and Civilian Goods, which
## no production line makes to order, so this never returns a production order.
static func recommendation()->Dictionary:
	if not WorldSimulation.state.resource_settlement_id.is_empty():return {}
	var option:=candidate()
	if not option.is_empty() and bool(option.terms.get("ok",false)):Rail.install(String(option.source),String(option.destination))
	return {}

## Raw materials and Civilian Goods the local city lacks for rail upkeep and
## its next proposed line.
static func shortfall()->Dictionary:
	var needs:=maintenance_targets(Rail.local_city())
	var option:=candidate()
	if not option.is_empty() and not bool(option.terms.get("ok",false)):
		for item:String in option.terms.cost:needs[item]=float(needs.get(item,0))+float(option.terms.cost[item])
	var result:Dictionary={}
	for item:String in needs:
		var missing:=float(needs[item])-float(WorldSimulation.state.resource_stockpiles.get(item,0))
		if missing>0:result[item]=missing
	return result
