extends RefCounted
const I=preload("res://scripts/civilization_indicators.gd")
static func snapshot()->Dictionary:
	var cities:Array=[]
	for city:Dictionary in GameState.player_settlements:
		if String(city.get("occupied_by","")) not in ["","player"]:continue
		var local:Dictionary=SettlementModel.with_city_resources(String(city.id),func()->Dictionary:return SettlementModel.with_local_population(_local))
		local.name=String(city.get("name","Settlement"));cities.append(local)
	if cities.is_empty() and GameState.player_settlements.is_empty():
		var local:=_local();local.name="Founding camp";cities.append(local)
	var totals:={"population":GameState.population_total,"cities":cities,"residents":0.0,"food_stock":0.0,"food_need":0.0,"food_produced":0.0,"food_eaten":0.0,"food_net":0.0,"water_stock":0.0,"water_need":0.0,"water_produced":0.0,"water_eaten":0.0,"science":0.0,"output":0.0,"minds":0.0,"life":0.0,"infant":0.0,"education":0.0,"food_shortages":0,"water_shortages":0,"food_reports":0,"water_reports":0}
	for city:Dictionary in cities:
		totals.residents+=city.population
		for key:String in ["food_stock","food_need","food_produced","food_eaten","food_net","water_stock","water_need","water_produced","water_eaten","science","output","minds"]:totals[key]+=city[key]
		for key:String in ["life","infant","education"]:totals[key]+=city[key]*city.population
		if city.food_report:totals.food_reports+=1
		if city.water_report:totals.water_reports+=1
		if city.food_report and city.food_eaten<city.food_need*.995:totals.food_shortages+=1
		if city.water_report and city.water_eaten<city.water_need*.995:totals.water_shortages+=1
	for key:String in ["life","infant","education"]:totals[key]/=maxf(1,totals.residents)
	totals.food_days=totals.food_stock/totals.food_need if totals.food_need>0 else -1.0
	totals.water_days=totals.water_stock/totals.water_need if totals.water_need>0 else -1.0
	return totals
static func _local()->Dictionary:
	var m:Dictionary=GameState.simulation_metrics;var w:Dictionary=GameState.water_metrics
	var food_need:=float(m.get("food_consumption",0));var water_need:=float(w.get("required_today",0))
	var s:=I.science();var h:=I.health()
	return {"population":GameState.population_total,"food_report":m.has("food_consumption"),"water_report":w.has("required_today"),"food_stock":float(m.get("food_total_stock",float(m.get("food_days",0))*food_need)),"food_need":food_need,"food_produced":float(m.get("food_production",0)),"food_eaten":float(m.get("food_eaten",food_need*float(m.get("food_intake_ratio",0)))),"food_net":float(m.get("food_net",0)),"water_stock":float(w.get("stored",float(w.get("days",0))*water_need)),"water_need":water_need,"water_produced":float(w.get("collected_today",0)),"water_eaten":water_need*float(w.get("intake_ratio",0)),"science":float(s.capacity),"minds":float(s.minds),"education":float(s.education),"output":float(I.economy().gdp),"life":float(h.life_expectancy),"infant":float(h.infant_mortality_per_1000)}
