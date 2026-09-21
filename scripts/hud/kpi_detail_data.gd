extends RefCounted
const Indicators=preload("res://scripts/civilization_indicators.gd")
static func snapshot(id:String)->Dictionary:
	var overall:=GameState.population_total
	var vitals:=GameState.rolling_vital_balance(365)
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:
		return SettlementModel.with_local_population(func()->Dictionary:return _local(id,overall,vitals)))
static func _row(label:String,value:String)->Dictionary:
	return {"label":label,"value":value}
static func _amount(data:Dictionary,key:String,suffix:String="")->String:
	return "%.1f%s" % [float(data[key]),suffix] if data.has(key) else "Awaiting report"
static func _local(id:String,overall:int,vitals:Dictionary)->Dictionary:
	var city:=SettlementModel.settlement_record(GameState.selected_player_settlement_id)
	var m:Dictionary=GameState.simulation_metrics
	var w:Dictionary=GameState.water_metrics
	var result:={"title":"","scope":String(city.get("name","Founding camp")),"value":"—","unit":"","rows":[],"status":"","tone":"neutral","meter":-1.0,"meter_label":"","footer":"Click the stat to open its full view"}
	match id:
		"population":
			result.merge({"title":"Population","scope":"All settlements","value":str(overall),"unit":"people","status":"%+d natural change · last 12 months" % int(vitals.get("net",0)),"rows":[_row("Births · last 12 months",str(vitals.get("births",0))),_row("Deaths · last 12 months",str(vitals.get("deaths",0))),_row("Residents · "+String(city.get("name","selected city")),str(GameState.population_total)),_row("Able to work · selected city",str(GameState.able_population()))]},true)
		"food":
			result.merge({"title":"Food reserves","value":_amount(m,"food_days"),"unit":"days of rations","rows":[_row("Produced today",_amount(m,"food_production"," rations")),_row("Required today",_amount(m,"food_consumption"," rations")),_row("Eaten today",_amount(m,"food_eaten"," rations")),_row("Lost to spoilage",_amount(m,"food_spoilage"," rations")),_row("Net reserve change",_amount(m,"food_net"," rations/day"))]},true)
			if m.has("food_intake_ratio"):
				result.meter=clampf(float(m.food_intake_ratio),0,1);result.meter_label="Today's food need met"
				result.status="Food shortfall today" if result.meter<.995 else "Today's food need met"
				result.tone="warning" if result.meter<.995 else "good"
			else:result.status="Waiting for the first daily food report"
		"water":
			result.merge({"title":"Drinking water","value":_amount(w,"days"),"unit":"days in reserve","rows":[_row("Collected today",_amount(w,"collected_today")),_row("Required today",_amount(w,"required_today")),_row("Stored after use",_amount(w,"stored")),_row("Storage capacity",_amount(w,"capacity"))]},true)
			if w.has("intake_ratio") and float(w.get("required_today",0))>0:
				result.meter=clampf(float(w.intake_ratio),0,1);result.meter_label="Today's drinking need met"
				result.status="Water shortfall today" if result.meter<.995 else "Today's drinking need met"
				result.tone="warning" if result.meter<.995 else "good"
			else:result.status="Waiting for the first daily water report"
		"health":
			var h:=Indicators.health()
			result.merge({"title":"Health & survival","value":"%.1f" % float(h.life_expectancy),"unit":"years · life expectancy at birth","status":"Projection under current conditions","rows":[_row("First-month infant deaths","%.0f per 1,000 births" % float(h.infant_mortality_per_1000)),_row("Population health","%d%%" % roundi(GameState.population_health*100)),_row("Food need met",_amount_percent(m,"food_intake_ratio")),_row("Water need met",_amount_percent(w,"intake_ratio"))]},true)
		"science":
			var s:=Indicators.science()
			result.merge({"title":"Research capacity","value":"%.1f" % float(s.capacity),"unit":"effective research capacity","status":"Research effort × average education","meter":float(s.education),"meter_label":"Average education","rows":[_row("Research effort","%.1f researcher-equivalents" % float(s.minds)),_row("Average education","%d%%" % roundi(float(s.education)*100)),_row("Resulting capacity","%.1f × %.2f = %.1f" % [s.minds,s.education,s.capacity])]},true)
		"gdp":
			var e:=Indicators.economy()
			result.merge({"title":"Daily economic output","value":"%.1f" % float(e.gdp),"unit":"output-equivalent units / day","status":"Effective labor × productivity","rows":[_row("Output per person","%.2f / day" % float(e.gdp_per_capita)),_row("Assigned workers","%.0f" % float(e.assigned_workers)),_row("Effective worker-days","%.1f" % float(e.effective_workers)),_row("Labor productivity","%.0f%%" % (float(e.productivity)*100)),_row("Not assigned",str(maxi(0,GameState.able_population()-int(e.assigned_workers))))]},true)
	return result
static func _amount_percent(data:Dictionary,key:String)->String:
	return "%d%%" % roundi(float(data[key])*100) if data.has(key) else "Awaiting report"
