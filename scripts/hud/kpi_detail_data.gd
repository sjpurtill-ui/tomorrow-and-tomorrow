extends RefCounted
const Model=preload("res://scripts/hud/civilization_kpi_model.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
static func snapshot(id:String)->Dictionary:
	return from_totals(id,Model.snapshot())
static func from_totals(id:String,t:Dictionary)->Dictionary:
	var modern:=EraWords.reckoned()
	var hearth:=EraWords.hearth()
	var r:={"title":"","scope":EraWords.word("scope","Entire civilization"),"value":"—","unit":"","rows":[],"status":"","tone":"neutral","meter":-1.0,"meter_label":"","footer":"Click the stat to open its full view"}
	match id:
		"population":
			var vitals:=GameState.rolling_vital_balance(365)
			if modern:r.merge({"title":"Population","value":str(t.population),"unit":"people","status":"%+d natural change · last 12 months" % int(vitals.get("net",0))},true)
			else:r.merge({"title":"The People","value":EraWords.grouped(int(t.population)),"unit":"souls" if hearth else "people","status":"%s born than buried since this time last year" % ("%d more" % int(vitals.get("net",0)) if int(vitals.get("net",0))>=0 else "%d fewer" % -int(vitals.get("net",0)))},true)
			# The chip's note: how many were fed in full today, and who went hungry.
			var fed:=EraWords.fed(int(t.population),float(t.food_eaten),float(t.food_need))
			if fed>=0:
				var hungry:=int(t.population)-fed
				r.rows.append({"label":"Fed in full today" if not modern else "Fully fed today","value":"%s of %s" % [EraWords.grouped(fed),EraWords.grouped(int(t.population))]})
				r.meter=float(fed)/maxf(1.0,float(t.population));r.meter_label="Fed in full today"
				if hungry>0:
					r.tone="warning"
					r.status="%s went hungry today: the food eaten fell short of what everyone needs. %s" % [EraWords.grouped(hungry),r.status]
				else:r.status="Everyone ate their fill today. %s" % r.status
		"food","water":
			var food:=id=="food";var days:=float(t[id+"_days"]);var shortages:=int(t[id+"_shortages"])
			r.merge({"title":("Food reserves" if modern else "Stores of food") if food else "Drinking water","value":"%.1f" % days if days>=0 else "Awaiting report","unit":"days · total stores / daily need" if modern else ("days, eating as we eat today" if food else "days, drinking as we drink today"),"status":"%d cities have a shortfall" % shortages if shortages>0 else "Reserves are held locally; city breakdown below.","tone":"warning" if shortages>0 else "neutral"},true)
			r.rows.append({"label":"Produced today" if food else "Collected today","value":"%.1f" % float(t[id+"_produced"])})
			r.rows.append({"label":"Required today","value":"%.1f" % float(t[id+"_need"])})
			if food:r.rows.append({"label":"Net reserve change","value":"%+.1f rations/day" % float(t.food_net)})
			if float(t[id+"_need"])>0:
				r.meter=clampf(float(t[id+"_eaten"])/float(t[id+"_need"]),0,1);r.meter_label="Civilization need met today" if modern else ("Bellies filled today" if food else "Thirst slaked today")
			if int(t[id+"_reports"])<t.cities.size():r.status+=" Some city reports are pending."
		"goods":
			r.merge({"title":"Civilian Goods" if not hearth else "Tools & gear","value":"%d%%" % roundi(float(t.goods_coverage)*100.0) if not hearth else EraWords.goods(float(t.goods_coverage)),"unit":"of what households expect" if not hearth else "of the hearths have the tools, cords and bags they need","status":"%d cities are below half their expected goods" % int(t.goods_shortages) if int(t.goods_shortages)>0 else "Everyday tools, containers and fittings. Adopted techniques act in proportion to this coverage.","tone":"warning" if int(t.goods_shortages)>0 else "neutral","meter":float(t.goods_coverage),"meter_label":"Goods coverage"},true)
			r.rows.append({"label":"Held","value":"%.1f of %.1f expected" % [float(t.goods_stock),float(t.goods_target)]})
			r.rows.append({"label":"Net change","value":"%+.2f / day" % float(t.goods_net)})
		"health":r.merge({"title":EraWords.life_title(),"value":"%.1f" % t.life if modern else str(roundi(float(t.life))),"unit":EraWords.life_unit(),"status":"Population-weighted projection under current conditions" if modern else EraWords.babes_lost_sentence(float(t.infant))},true)
		"science":
			if modern:r.merge({"title":"Research capacity","value":"%.1f" % t.science,"unit":"effective research capacity","status":"Sum of each city's research effort × its education"},true)
			else:r.merge({"title":"Lore" if hearth else "Learning","value":str(GameState.known_discoveries.size()),"unit":"ways the people know" if hearth else "practices the people know","status":"%d %s keep, test and teach what is known." % [roundi(float(t.minds)),"people" if roundi(float(t.minds))!=1 else "person"]},true)
		"gdp":
			if modern:r.merge({"title":"Daily economic output","value":"%.1f" % t.output,"unit":"output-equivalent units / day","status":"%.2f per person · all city output combined" % (float(t.output)/maxi(1,int(t.population)))},true)
			elif hearth:
				var fed:=EraWords.fed(int(t.population),float(t.food_eaten),float(t.food_need))
				r.merge({"title":"Bellies filled","value":str(fed) if fed>=0 else "—","unit":"of %d fed in full today" % int(t.population),"status":"The work of about %d hands keeps the hearths fed, clothed and sheltered." % roundi(float(t.output))},true)
			else:r.merge({"title":"Daily labour","value":str(roundi(float(t.output))),"unit":"full days of work done each day","status":"About %.2f of a full day's work for every person counted." % (float(t.output)/maxi(1,int(t.population)))},true)
	for city:Dictionary in t.cities:
		var value:=""
		match id:
			"population":value="%d residents" % city.population if modern else EraWords.people(int(city.population))
			"food","water":
				var need:=float(city[id+"_need"])
				value="Awaiting report" if not bool(city[id+"_report"]) else "%.1f made / %.1f needed\n%.1f reserve days%s" % [city[id+"_produced"],need,float(city[id+"_stock"])/maxf(.01,need)," · SHORTFALL" if float(city[id+"_eaten"])<need*.995 else ""]
			"health":value="%.1f years · %.0f‰ infant mortality" % [city.life,city.infant] if modern else "%s · %s" % [EraWords.life(float(city.life)),EraWords.babes_lost(float(city.infant))]
			"science":value="%.1f capacity\n%.1f minds × %.0f%% education" % [city.science,city.minds,float(city.education)*100] if modern else "%d keeping the lore" % roundi(float(city.minds))
			"gdp":
				if modern:value="%.1f output / day" % city.output
				elif hearth:
					var city_fed:=EraWords.fed(int(city.population),float(city.food_eaten),float(city.food_need))
					value="%s of %d fed · %d hands at work" % [str(city_fed) if city_fed>=0 else "—",int(city.population),roundi(float(city.output))]
				else:value="%d days of work a day" % roundi(float(city.output))
			"goods":value="%.1f held / %.1f expected · %+.2f / day" % [city.goods_stock,city.goods_target,city.goods_net]
		r.rows.append({"label":String(city.name),"value":value})
	return r
