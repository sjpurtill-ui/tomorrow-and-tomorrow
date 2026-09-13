extends RefCounted
const Rail=preload("res://scripts/rail_freight.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")
static func maintenance_targets(city_id:String)->Dictionary:
	var needs:Dictionary={}
	for line:Dictionary in Rail.data().lines:
		if String(line.source_id)!=city_id or Rail.F.building(line):continue
		for item:String in ["Timber Rail Panels","Rail Brake Sets","Timber","Wrought Iron"]:
			needs[item]=float(needs.get(item,0))+maxf(2,float(line.route.length_km)*.2)
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
static func recommendation()->Dictionary:
	if not WorldSimulation.state.resource_settlement_id.is_empty():return {}
	var needs:=maintenance_targets(Rail.local_city())
	var option:=candidate()
	if not option.is_empty():
		if bool(option.terms.get("ok",false)):Rail.install(String(option.source),String(option.destination))
		else:
			for item:String in option.terms.cost:needs[item]=float(needs.get(item,0))+float(option.terms.cost[item])
	for item:String in needs:
		if float(WorldSimulation.state.resource_stockpiles.get(item,0))>=float(needs[item]):continue
		var order:=Supply.supply(item,ceili(float(needs[item])),{})
		if not order.is_empty():return order
	return {}
