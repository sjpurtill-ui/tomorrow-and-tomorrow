extends RefCounted
const Model=preload("res://scripts/hud/civilization_kpi_model.gd")
static func snapshot(id:String)->Dictionary:
	return from_totals(id,Model.snapshot())
static func from_totals(id:String,t:Dictionary)->Dictionary:
	var r:={"title":"","scope":"Entire civilization","value":"—","unit":"","rows":[],"status":"","tone":"neutral","meter":-1.0,"meter_label":"","footer":"Click the stat to open its full view"}
	match id:
		"population":
			var vitals:=GameState.rolling_vital_balance(365)
			r.merge({"title":"Population","value":str(t.population),"unit":"people","status":"%+d natural change · last 12 months" % int(vitals.get("net",0))},true)
		"food","water":
			var food:=id=="food";var days:=float(t[id+"_days"]);var shortages:=int(t[id+"_shortages"])
			r.merge({"title":"Food reserves" if food else "Drinking water","value":"%.1f" % days if days>=0 else "Awaiting report","unit":"days · total stores / daily need","status":"%d cities have a shortfall" % shortages if shortages>0 else "Reserves are held locally; city breakdown below.","tone":"warning" if shortages>0 else "neutral"},true)
			r.rows.append({"label":"Produced today" if food else "Collected today","value":"%.1f" % float(t[id+"_produced"])})
			r.rows.append({"label":"Required today","value":"%.1f" % float(t[id+"_need"])})
			if food:r.rows.append({"label":"Net reserve change","value":"%+.1f rations/day" % float(t.food_net)})
			if float(t[id+"_need"])>0:
				r.meter=clampf(float(t[id+"_eaten"])/float(t[id+"_need"]),0,1);r.meter_label="Civilization need met today"
			if int(t[id+"_reports"])<t.cities.size():r.status+=" Some city reports are pending."
		"goods":
			r.merge({"title":"Civilian Goods","value":"%d%%" % roundi(float(t.goods_coverage)*100.0),"unit":"of what households expect","status":"%d cities are below half their expected goods" % int(t.goods_shortages) if int(t.goods_shortages)>0 else "Everyday tools, containers and fittings. Adopted techniques act in proportion to this coverage.","tone":"warning" if int(t.goods_shortages)>0 else "neutral","meter":float(t.goods_coverage),"meter_label":"Goods coverage"},true)
			r.rows.append({"label":"Held","value":"%.1f of %.1f expected" % [float(t.goods_stock),float(t.goods_target)]})
			r.rows.append({"label":"Net change","value":"%+.2f / day" % float(t.goods_net)})
		"health":r.merge({"title":"Health & survival","value":"%.1f" % t.life,"unit":"years · life expectancy","status":"Population-weighted projection under current conditions"},true)
		"science":r.merge({"title":"Research capacity","value":"%.1f" % t.science,"unit":"effective research capacity","status":"Sum of each city's research effort × its education"},true)
		"gdp":r.merge({"title":"Daily economic output","value":"%.1f" % t.output,"unit":"output-equivalent units / day","status":"%.2f per person · all city output combined" % (float(t.output)/maxi(1,int(t.population)))},true)
	for city:Dictionary in t.cities:
		var value:=""
		match id:
			"population":value="%d residents" % city.population
			"food","water":
				var need:=float(city[id+"_need"])
				value="Awaiting report" if not bool(city[id+"_report"]) else "%.1f made / %.1f needed\n%.1f reserve days%s" % [city[id+"_produced"],need,float(city[id+"_stock"])/maxf(.01,need)," · SHORTFALL" if float(city[id+"_eaten"])<need*.995 else ""]
			"health":value="%.1f years · %.0f‰ infant mortality" % [city.life,city.infant]
			"science":value="%.1f capacity\n%.1f minds × %.0f%% education" % [city.science,city.minds,float(city.education)*100]
			"gdp":value="%.1f output / day" % city.output
			"goods":value="%.1f held / %.1f expected · %+.2f / day" % [city.goods_stock,city.goods_target,city.goods_net]
		r.rows.append({"label":String(city.name),"value":value})
	return r
