extends RefCounted
## Rations and material quantities are game units. No new food or labor authority.
const FRESH=["Fresh plants","Fresh meat","Fish"]
const METHODS={
	"hearth_roasting_control":{"rate":8.0,"inputs":{"Timber":0.03}},
	"earth_oven_cooking":{"rate":12.0,"inputs":{"Timber":0.015,"Stone":0.002}},
	"food_steaming_vessels":{"rate":10.0,"inputs":{"Timber":0.02,"Freshwater":0.04}}
}
const STAFF_SHARE:=0.1
const QUALITY_BONUS:=0.04

static func entries()->Array[Dictionary]:
	return ENTRIES
const ENTRIES=[
	{
		"id": "hearth_roasting_control",
		"name": "Hearth Roasting Control",
		"direction": "Sustenance",
		"day": 0,
		"chance": 0.005,
		"requires": [
			"hearth_heat_retention"
		],
		"requires_all": [
			"hearth_heat_retention"
		],
		"requires_any": [],
		"signals": [
			"food",
			"crafting",
			"research"
		],
		"observation": "Manage distance and exposure of suitable food to a controlled hearth",
		"effects": {},
		"meal_preparation": "hearth_roasting_control",
		"production_contract": "Prepares consumed fresh food with adopted practice, real fuel and up to one tenth of Logistics staff, competing with preservation. Earth ovens use stone upkeep; steaming uses water and vessel upkeep. Prepared share contributes at most 4 percentage points to diet quality; no calories or storage life are created.",
		"learning_routes": [
			{
				"id": "local",
				"label": "Hearth Roasting Control practice",
				"requires_all": []
			}
		]
	},
	{
		"id": "earth_oven_cooking",
		"name": "Earth Oven Cooking",
		"direction": "Sustenance",
		"day": 0,
		"chance": 0.005,
		"requires": [
			"hearth_roasting_control"
		],
		"requires_all": [
			"hearth_roasting_control"
		],
		"requires_any": [],
		"signals": [
			"food",
			"crafting",
			"research"
		],
		"observation": "Retain and transfer heat through an enclosed heated-earth or stone cooking arrangement",
		"effects": {},
		"meal_preparation": "earth_oven_cooking",
		"production_contract": "Prepares consumed fresh food with adopted practice, real fuel and up to one tenth of Logistics staff, competing with preservation. Earth ovens use stone upkeep; steaming uses water and vessel upkeep. Prepared share contributes at most 4 percentage points to diet quality; no calories or storage life are created.",
		"learning_routes": [
			{
				"id": "local",
				"label": "Earth Oven Cooking practice",
				"requires_all": []
			}
		]
	},
	{
		"id": "food_steaming_vessels",
		"name": "Food Steaming Vessels",
		"direction": "Sustenance",
		"day": 0,
		"chance": 0.005,
		"requires": [
			"hearth_roasting_control"
		],
		"requires_all": [
			"hearth_roasting_control"
		],
		"requires_any": [
			[
				"clay_shaping",
				"basketry"
			]
		],
		"signals": [
			"food",
			"crafting",
			"research"
		],
		"observation": "Transfer heat to food through a qualified steam-producing vessel arrangement",
		"effects": {},
		"meal_preparation": "food_steaming_vessels",
		"production_contract": "Prepares consumed fresh food with adopted practice, real fuel and up to one tenth of Logistics staff, competing with preservation. Earth ovens use stone upkeep; steaming uses water and vessel upkeep. Prepared share contributes at most 4 percentage points to diet quality; no calories or storage life are created.",
		"learning_routes": [
			{
				"id": "local",
				"label": "Food Steaming Vessels practice",
				"requires_all": []
			}
		]
	}
]


# Select the most productive supplied method. Reserve time before preservation;
# execute only against meals eaten and remaining supplies, so interrupted supply
# cannot create free preparation. Unused reserved time is conservative idle time.
static func plan(logistics:float, demand:float, traveling:bool)->Dictionary:
	var state=WorldSimulation.state
	var best:Dictionary={"method":"","capacity":0.0,"workers":0.0,"inputs":{},"rate":0.0}
	preload("res://scripts/fire_practice.gd").ensure_initialized()
	if traveling or not state.settlement_site_committed or logistics<=0 or demand<=0 or not preload("res://scripts/fire_practice.gd").available():return best
	var food:=0.0
	for category:String in FRESH:food+=maxf(0.0,float(state.food_stocks.get(category,0.0)))
	for id:String in METHODS:
		if id not in state.known_discoveries:continue
		var adoption:=clampf(WorldSimulation.discovery.adoption(id),0.0,1.0)
		var rate:=float(METHODS[id].rate)*adoption
		if rate<=0:continue
		var inputs:Dictionary=METHODS[id].inputs.duplicate()
		if id=="food_steaming_vessels":
			if "clay_shaping" in state.known_discoveries and float(state.resource_stockpiles.get("Clay",0.0))>0:inputs["Clay"]=0.002
			elif "basketry" in state.known_discoveries:inputs["Fiber Plants"]=0.002
			else:continue
		var capacity:=minf(food,minf(demand,logistics*STAFF_SHARE*rate))
		for resource:String in inputs:capacity=minf(capacity,maxf(0.0,float(state.resource_stockpiles.get(resource,0.0)))/float(inputs[resource]))
		if capacity>float(best.capacity):best={"method":id,"capacity":capacity,"workers":capacity/rate,"inputs":inputs,"rate":rate}
	return best


static func prepare(plan:Dictionary, consumed:Dictionary)->Dictionary:
	var result:Dictionary={"method":String(plan.get("method","")),"rations":0.0,"inputs":{},"workers_reserved":float(plan.get("workers",0.0)),"quality_bonus":0.0}
	var total:=0.0
	var fresh:=0.0
	for category:String in consumed:
		total+=maxf(0.0,float(consumed[category]))
		if category in FRESH:fresh+=maxf(0.0,float(consumed[category]))
	var amount:=minf(fresh,maxf(0.0,float(plan.get("capacity",0.0))))
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	var inputs:Dictionary=plan.get("inputs",{})
	for resource:String in inputs:amount=minf(amount,maxf(0.0,float(stocks.get(resource,0.0)))/float(inputs[resource]))
	if amount<=0:return result
	for resource:String in inputs:
		var spent:=amount*float(inputs[resource])
		stocks[resource]=maxf(0.0,float(stocks.get(resource,0.0))-spent)
		result.inputs[resource]=spent
	result.rations=amount
	result.quality_bonus=QUALITY_BONUS*amount/maxf(total,0.001)
	return result
