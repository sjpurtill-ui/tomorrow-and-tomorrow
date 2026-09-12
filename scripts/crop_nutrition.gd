extends RefCounted
## Added fertilizer-derived reserves above the existing ambient soil model.
## Units are abstract cultivation inputs, not chemical measurements.
const GATE:="nutrient_response_trials"
const NUTRIENTS:=["nitrogen","phosphorus"]
const MAX_RESERVE:=1000000000.0
const INPUTS:={"Nitrate Fertilizer":{"nitrogen":1.0},"Ammonium Sulfate":{"nitrogen":1.0},"Soluble Phosphate":{"phosphorus":1.0},"Ground Phosphate":{"phosphorus":0.3}}
static func empty_state()->Dictionary:return {"nitrogen":0.0,"phosphorus":0.0}
static func valid(value:Variant)->bool:
	if not value is Dictionary or value.size()!=2:return false
	for key:String in NUTRIENTS:
		var amount:Variant=value.get(key)
		if not (amount is int or amount is float) or not is_finite(float(amount)) or float(amount)<0 or float(amount)>MAX_RESERVE:return false
	return true
static func valid_settlements(records:Variant)->bool:
	if not records is Array:return false
	for record:Variant in records:
		if not record is Dictionary:return false
		var local:Variant=record.get("local_resources",{})
		if not local is Dictionary or not valid(local.get("cultivation_nutrients",empty_state())):return false
	return true
static func adoption()->float:
	if GATE not in WorldSimulation.state.known_discoveries:return 0.0
	return clampf(WorldSimulation.discovery.adoption(GATE),0,1)
static func plan(base_harvest:float,stocks:Dictionary,reserves:Dictionary,adopted:float)->Dictionary:
	# Read-only quote: callers explicitly decide whether to commit its returned balances.
	var next:=reserves.duplicate(true)
	var used:Dictionary={}
	var report:={"base_harvest":maxf(0,base_harvest),"bonus":0.0,"harvest":maxf(0,base_harvest),"inputs":used,"reserves":next,"adoption":clampf(adopted,0,1)}
	if base_harvest<=0 or adopted<=0:return report
	# Retention losses prevent an abandoned reserve from lasting indefinitely
	# whenever cultivation operates. Existing ambient fertility remains separate.
	next.nitrogen=float(next.nitrogen)*.998
	next.phosphorus=float(next.phosphorus)*.9995
	var demand:={"nitrogen":base_harvest*.01,"phosphorus":base_harvest*.006}
	for resource:String in INPUTS:
		var profile:Dictionary=INPUTS[resource]
		var nutrient:String=profile.keys()[0]
		var concentration:=float(profile[nutrient])
		var target:=minf(MAX_RESERVE,float(demand[nutrient])*7.0*clampf(adopted,0,1))
		var quantity:=minf(maxf(0,float(stocks.get(resource,0))),maxf(0,target-float(next[nutrient]))/concentration)
		if quantity>0:
			used[resource]=quantity
			next[nutrient]=float(next[nutrient])+quantity*concentration
	var coverage:=minf(1,minf(float(next.nitrogen)/float(demand.nitrogen),float(next.phosphorus)/float(demand.phosphorus)))
	coverage*=clampf(adopted,0,1)
	for nutrient:String in NUTRIENTS:next[nutrient]=maxf(0,float(next[nutrient])-float(demand[nutrient])*coverage)
	report.bonus=base_harvest*.25*coverage
	report.harvest=base_harvest+float(report.bonus)
	return report
static func cultivation(base_harvest:float,commit:bool=false)->Dictionary:
	var report:=plan(base_harvest,WorldSimulation.state.resource_stockpiles,WorldSimulation.state.cultivation_nutrients,adoption())
	if commit:
		for resource:String in report.inputs:WorldSimulation.state.resource_stockpiles[resource]=maxf(0,float(WorldSimulation.state.resource_stockpiles[resource])-float(report.inputs[resource]))
		WorldSimulation.state.cultivation_nutrients=report.reserves
	return report
static func projection(base_harvest:float,stocks:Dictionary,reserves:Dictionary,adopted:float)->Dictionary:
	var report:=plan(base_harvest,stocks,reserves,adopted)
	for resource:String in report.inputs:stocks[resource]=maxf(0,float(stocks[resource])-float(report.inputs[resource]))
	reserves.merge(report.reserves,true)
	return report
