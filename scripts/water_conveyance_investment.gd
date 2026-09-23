extends RefCounted
const Water=preload("res://scripts/water_conveyance.gd")
const Fabric=preload("res://scripts/water_conveyance_fabric.gd")

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
	if not Water.is_adopted("gravity_conduit_grade_control"):return result
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
	# Repair reserves are raw materials and Civilian Goods, so city trade can
	# move them: one section per active line and one rod set in total.
	var demand:Dictionary={}
	var rodding:=false
	for line:Dictionary in Water.data().lines:
		if line.status!="active":continue
		Fabric.Stock.add_scaled(demand,Fabric.section_unit(String(line.material)),1.0)
		rodding=rodding or Water.is_adopted("sewer_rodding_service")
	if rodding:Fabric.Stock.add_scaled(demand,Fabric.RODDING,1.0)
	# A line under construction already owns its supplies; do not stock another
	# complete route simply because delivered service has not started yet.
	if not Water.data().lines.is_empty():return demand
	var options:=candidates()
	if not options.is_empty():
		var selected:Dictionary=options[0]
		# Prefer a line paid locally, then one whose whole bill local and
		# deliverable stocks cover; otherwise the first (ceramic) option.
		for option:Dictionary in options:
			if bool(option.terms.get("ok",false)):
				selected=option;break
			var covered:=true
			for item:String in option.terms.cost:
				if float(deliverable.get(item,0))+float(WorldSimulation.state.resource_stockpiles.get(item,0))<float(option.terms.cost[item]):covered=false;break
			if covered:selected=option;break
		demand.merge(selected.terms.cost,true)
	return demand

static func install_supplied()->void:
	if not Water.data().lines.is_empty():return
	for candidate:Dictionary in candidates():
		if bool(candidate.terms.get("ok",false)):
			Water.install(candidate.source,candidate.destination,candidate.height_at,candidate.material)
			return

## Installs supplied lines in every accessible city. Bills are raw materials
## and Civilian Goods, which city trade moves (settlement_model reads
## targets()); no production order is placed, so this always returns {}.
static func recommendation()->Dictionary:
	var state=WorldSimulation.state
	if not state.resource_settlement_id.is_empty():return {}
	install_supplied()
	for city:Dictionary in state.player_settlements:
		if bool(city.get("primary",false)) or not String(city.get("occupied_by","")).is_empty():continue
		WorldSimulation.settlements.with_city_resources(String(city.id),func()->void:
			WorldSimulation.settlements.with_local_population(func()->void:install_supplied()))
	return {}
