extends RefCounted
const Water=preload("res://scripts/water_conveyance.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")

static func local_context()->Dictionary:
	var state=WorldSimulation.state
	var point:=Vector2(state.settlement_founded_at.x,state.settlement_founded_at.z)
	if not state.resource_settlement_id.is_empty():
		var city:Dictionary=WorldSimulation.settlements.settlement_record(state.resource_settlement_id)
		if not city.is_empty():point=WorldSimulation.settlements._record_position(city)
	return preload("res://scripts/civilization_day.gd").context(point)

static func candidates()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var state=WorldSimulation.state
	if state.convoy_traveling or not state.settlement_site_committed or state.effective_workers("Construction")<4:return result
	if "gravity_conduit_grade_control" not in Water.adopted():return result
	if float(state.water_metrics.get("intake_ratio",1))>=.98 and float(state.water_metrics.get("source_distance_km",0))<.5:return result
	var context:=local_context()
	var height_at:Callable=context.get("terrain_height_at",Callable())
	var destination:Vector3=context.origin
	for source:Dictionary in context.get("water_conveyance_sources",[]):
		for material:String in ["ceramic","timber"]:
			var terms:=Water.quote(source,destination,height_at,material)
			if terms.has("cost"):
				result.append({"terms":terms,"source":source,"destination":destination,"height_at":height_at,"material":material})
	return result

static func targets(deliverable:Dictionary={})->Dictionary:
	var demand:Dictionary={}
	for line:Dictionary in Water.data().lines:
		if line.status!="active":continue
		var item:=String(preload("res://scripts/water_conveyance_fabric.gd").MATERIALS[line.material].item)
		demand[item]=float(demand.get(item,0))+1.0
		if "sewer_rodding_service" in Water.adopted():demand["Conduit Rodding Sets"]=1.0
	# A line under construction already owns its supplies; do not stock another
	# complete route simply because delivered service has not started yet.
	if not Water.data().lines.is_empty():return demand
	var options:=candidates()
	if not options.is_empty():
		var selected:Dictionary=options[0]
		# Prefer paid local sections, then a material we can manufacture. Imported
		# sections remain installable even when their manufacture is unknown.
		for option:Dictionary in options:
			if bool(option.terms.get("ok",false)):
				selected=option;break
			var item:=String(preload("res://scripts/water_conveyance_fabric.gd").MATERIALS[option.material].item)
			if float(deliverable.get(item,0))+float(WorldSimulation.state.resource_stockpiles.get(item,0))>=float(option.terms.cost.get(item,0)):
				selected=option;break
			var possible:=false
			for product:String in Supply.I.PRODUCTS:
				if String(Supply.I.PRODUCTS[product].output)!=item:continue
				if not Supply.P.recipe(WorldSimulation.military,product).has("error"):possible=true;break
			if possible:selected=option;break
		demand.merge(selected.terms.cost,true)
	return demand

static func install_supplied()->void:
	if not Water.data().lines.is_empty():return
	for candidate:Dictionary in candidates():
		if bool(candidate.terms.get("ok",false)):
			Water.install(candidate.source,candidate.destination,candidate.height_at,candidate.material)
			return

static func recommendation()->Dictionary:
	var state=WorldSimulation.state
	if not state.resource_settlement_id.is_empty():return {}
	install_supplied()
	var required:=targets()
	var deliverable:Dictionary=state.resource_stockpiles.duplicate()
	for city:Dictionary in state.player_settlements:
		if bool(city.get("primary",false)) or not String(city.get("occupied_by","")).is_empty():continue
		var needs:Dictionary=WorldSimulation.settlements.with_city_resources(String(city.id),func()->Dictionary:
			return WorldSimulation.settlements.with_local_population(func()->Dictionary:
				install_supplied()
				var result:=targets(deliverable)
				for item:String in result:
					result[item]=maxf(0,float(result[item])-float(state.resource_stockpiles.get(item,0))-WorldSimulation.settlements._city_incoming(String(city.id),item))
				return result))
		for item:String in needs:required[item]=float(required.get(item,0))+float(needs[item])
	for item:String in required:
		if float(state.resource_stockpiles.get(item,0))>=float(required[item]):continue
		var order:=Supply.supply(item,ceili(float(required[item])),{})
		if not order.is_empty():return order
	return {}
