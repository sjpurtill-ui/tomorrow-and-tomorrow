extends RefCounted
## Invest against visible perishable stocks, paid inputs and assigned workers.
const Ops=preload("res://scripts/technology_operations.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")
const Preservation=preload("res://scripts/canning_preservation.gd")
static func recommendation()->Dictionary:
	var state=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {}
	var condition:=clampf(float(state.population_health)*float(state.simulation_metrics.get("labor_efficiency",.72)),0,1)
	if condition<=0:return {}
	var spec:Dictionary=Ops.PLANTS.cannery
	for gate:String in [spec.gate]+spec.requires:
		if gate not in state.known_discoveries or WorldSimulation.discovery.adoption(gate)<.25:return {}
	var operators:=0.0
	for id:String in Ops.data().plants:
		var record:Dictionary=Ops.data().plants[id]
		if not bool(record.enabled):continue
		if int(record.building)>0:return {}
		operators+=int(record.installed)*float(Ops.PLANTS[id].workers)
	var plant:Dictionary=Ops.data().plants.get("cannery",{})
	if not plant.is_empty() and not bool(plant.enabled):return {}
	var installed:=int(plant.get("installed",0))
	if installed>=Ops.LIMIT:return {}
	if state.effective_workers("Crafting")+Ops.reserved_workers(state)<operators+float(spec.workers)+1.0:return {}
	var daily_loss:=0.0
	var storage:=.72 if "Storage Pits" in state.settlement_completed else 1.0
	storage*=maxf(.30,1.0+WorldSimulation.discovery.effect("food_spoilage"))
	var cooling:=Ops.refrigeration_multiplier(Ops.service("cold_storage"),state.food_stocks)
	for food:String in state.food_stocks:
		var amount:=maxf(0,float(state.food_stocks[food]))
		if food not in ["Fresh food","Fish","Fresh meat","Fresh plants"]:continue
		daily_loss+=amount*float(WorldSimulation.food.SPOILAGE[food])*storage*WorldSimulation.discovery.food_storage_multiplier(food,false)*cooling
	var demand:=maxf(0,float(WorldSimulation.food._calculate_demand(false).total))
	var capacity:=float(spec.services.food_preservation)*condition
	# A nominal month of current surplus justifies one additional installation.
	if preload("res://scripts/canning_capacity.gd").available_input(state.food_stocks,demand)<capacity*(installed+1)*30.0:return {}
	if daily_loss<capacity*(1.0-Preservation.YIELD)*(installed+1):return {}
	var first:Dictionary={}
	# Check all consumables before committing an upstream line; raw shortages block.
	for resource:String in spec.inputs:
		var target:=ceili(float(spec.inputs[resource])*(installed+1)*30.0)
		if float(state.resource_stockpiles.get(resource,0))>=target:continue
		var part:=Supply.supply(resource,target,{})
		if part.is_empty():return {}
		if first.is_empty():first=part
	if not first.is_empty():return first
	if not Ops.quote("cannery").has("error"):return {"kind":"plant_install","plant":"cannery","count":1}
	for resource:String in spec.cost:
		if float(state.resource_stockpiles.get(resource,0))>=float(spec.cost[resource]):continue
		var part:=Supply.supply(resource,ceili(float(spec.cost[resource])),{})
		if part.is_empty():return {}
		if first.is_empty():first=part
	return first
