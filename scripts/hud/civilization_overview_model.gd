extends RefCounted
const Indicators=preload("res://scripts/civilization_indicators.gd")

static func snapshot()->Dictionary:
	var state=WorldSimulation.state
	var settlements=WorldSimulation.settlements
	var result:={"population":state.population_total,"cities":[],"residents":0,"sheltered":0,"places":0,"life_years":0.0,"output":0.0,"science":0.0,"works":0,"building":0,"food_min":-1.0,"water_min":-1.0,"attention":0}
	result.materials={};result.cohesion=0.0;result.legitimacy=0.0;result.cohesion_population=0;result.legitimacy_population=0
	if state.player_settlements.is_empty():
		var local:=local_snapshot()
		result.residents=local.population;result.places=local.places;result.sheltered=mini(local.population,local.places)
		result.life_years=local.life*local.population;result.output=local.output;result.science=local.science
		result.food_min=local.food;result.water_min=local.water;result.materials=local.materials
		if local.cohesion>=0:result.cohesion=local.cohesion*local.population;result.cohesion_population=local.population
		if local.legitimacy>=0:result.legitimacy=local.legitimacy*local.population;result.legitimacy_population=local.population
	for city:Dictionary in state.player_settlements:
		var id:=String(city.id)
		var row:Dictionary=settlements.with_city_resources(id,func()->Dictionary:
			return settlements.with_local_population(func()->Dictionary:return local_snapshot()))
		row.id=id;row.name=String(city.get("name","Settlement"));row.primary=bool(city.get("primary",false))
		row.occupied=not String(city.get("occupied_by","")).is_empty()
		result.cities.append(row)
		if row.occupied:continue
		result.residents+=row.population;result.places+=row.places
		result.sheltered+=mini(row.population,row.places)
		result.life_years+=row.life*row.population
		result.output+=row.output;result.science+=row.science
		if row.cohesion>=0:result.cohesion+=row.cohesion*row.population;result.cohesion_population+=row.population
		if row.legitimacy>=0:result.legitimacy+=row.legitimacy*row.population;result.legitimacy_population+=row.population
		for item:String in row.materials:result.materials[item]=float(result.materials.get(item,0))+float(row.materials[item])
		result.works+=row.works;result.building+=row.building
		if row.food>=0:result.food_min=row.food if result.food_min<0 else minf(result.food_min,row.food)
		if row.water>=0:result.water_min=row.water if result.water_min<0 else minf(result.water_min,row.water)
		if not row.issues.is_empty():result.attention+=1
	result.life=result.life_years/maxi(1,result.residents)
	result.cities.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if a.issues.is_empty()!=b.issues.is_empty():return not a.issues.is_empty()
		return a.population>b.population)
	return result

static func local_snapshot()->Dictionary:
	var state=WorldSimulation.state
	var metrics:Dictionary=state.simulation_metrics
	var water:Dictionary=state.water_metrics
	var food_days:=float(metrics.get("food_days",-1))
	var water_days:=float(water.get("days",-1))
	var issues:Array[String]=[]
	if float(metrics.get("food_intake_ratio",1))<.99:issues.append("Food shortfall")
	elif food_days>=0 and food_days<7:issues.append("Low food reserve")
	if float(water.get("intake_ratio",1))<.99:issues.append("Water shortfall")
	if state.housing_capacity<state.population_total:issues.append("Shelter shortfall")
	var building:=0
	for plot:Dictionary in state.settlement_plots:
		if String(plot.get("status",""))=="under_construction":building+=1
	var materials:Dictionary={}
	for item:String in ["Timber","Stone","Clay","Fiber Plants"]:materials[item]=float(state.resource_stockpiles.get(item,0))
	return {"population":state.population_total,"places":int(state.housing_capacity),"food":food_days,"water":water_days,"water_met":float(water.get("intake_ratio",-1)),"life":state.projected_life_expectancy(),"output":Indicators.economy(state).gdp,"science":Indicators.science(state).capacity,"works":state.settlement_completed.size(),"building":building,"issues":issues,"materials":materials,"cohesion":float(metrics.get("cohesion",-1)),"legitimacy":float(metrics.get("legitimacy",-1))}
