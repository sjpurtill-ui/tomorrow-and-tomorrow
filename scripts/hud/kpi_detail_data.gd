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

# --- Hover cards ----------------------------------------------------------------
# The glance a top-bar chip gives on hover (hud/hover_card.gd): one plain sentence
# in the people's words, a few short facts with trend arrows, one small line or
# bar, and where to act. The city-by-city tallies above stay in the drawer.

static func card(id:String)->Dictionary:
	return card_from_totals(id,Model.snapshot())

static func card_from_totals(id:String,t:Dictionary)->Dictionary:
	var modern:=EraWords.reckoned()
	var hearth:=EraWords.hearth()
	var cities:=int(t.cities.size())
	var population:=int(t.population)
	var c:={"kicker":EraWords.word("kpi."+id,id.to_upper()),"value":"—","unit":"","headline":"","tone":"neutral","facts":[],"spark":[],"spark_label":"","meter":-1.0,"meter_label":"","action":""}
	match id:
		"population":
			var fed:=EraWords.fed(population,float(t.food_eaten),float(t.food_need))
			var hungry:=population-fed if fed>=0 else 0
			var vitals:=GameState.rolling_vital_balance(365)
			var net:=int(vitals.get("net",0))
			c.value=EraWords.people(population) if not modern else EraWords.grouped(population)
			if hungry>0:
				c.tone="warning"
				c.headline="%s went hungry today: the food eaten fell short of what all of us need." % EraWords.grouped(hungry)
			elif fed>=0:c.headline="Everyone ate their fill today; %s this year." % ("more are born than buried" if net>0 else "as many are buried as born" if net==0 else "more are buried than born")
			else:c.headline="The people are counted; what they ate today is not yet told."
			c.facts.append({"text":"%d born, %d buried since this time last year" % [int(vitals.get("births",0)),int(vitals.get("deaths",0))],"trend":signi(net),"good":net>=0})
			if fed>=0:
				c.meter=float(fed)/maxf(1.0,float(population))
				c.meter_label="%s of %s fed in full today" % [EraWords.grouped(fed),EraWords.grouped(population)]
			if cities>1:c.facts.append({"text":"Living at %s" % EraWords.places(cities)})
			c.action="Click for The People"+(" · ask the Steward at Court why some go hungry" if hungry>0 else "")
		"food","water":
			var food:=id=="food"
			var days:=float(t[id+"_days"])
			var shortages:=int(t[id+"_shortages"])
			var produced:=float(t[id+"_produced"])
			var need:=float(t[id+"_need"])
			c.value=EraWords.days(days) if days>=0 else "Not yet told"
			c.unit=("of food" if food else "of drinking water") if days>=0 else ""
			var gaining:=produced>=need
			if shortages>0:
				c.tone="warning"
				var without:=population-EraWords.fed(population,float(t[id+"_eaten"]),need) if need>0 else 0
				var lead:="Stores are running short: " if food else "Water is running short: "
				if without>0:c.headline=lead+"%s went %s today." % [EraWords.grouped(without),"hungry" if food else "thirsty"]
				else:c.headline=lead+"%s cannot meet the day's need." % EraWords.places(shortages)
			elif days<0:c.headline="No %s has been counted yet." % ("food" if food else "water")
			elif food:c.headline="%s at today's eating, and %s." % [_sentence_case(EraWords.store_span(days)),"more is brought in than eaten" if gaining else "we eat more than we bring in"]
			else:c.headline="Water held for %s at today's drinking, and %s." % [EraWords.days(days),"more is drawn than drunk" if gaining else "we drink more than we draw"]
			if need>0:
				var brought:=("Gathered" if hearth else "Brought in") if food else "Drawn"
				c.facts.append({"text":"%s %s today, %s %s" % [brought,_amount(produced),"eaten" if food else "drunk",_amount(need)],"trend":1 if produced>need*1.02 else -1 if produced<need*0.98 else 0,"good":gaining})
			if shortages>0 and cities>1:c.facts.append({"text":"Short at %s" % EraWords.places(shortages),"trend":-1,"good":false})
			if int(t[id+"_reports"])<cities:c.facts.append({"text":"Some %s have not yet sent word" % EraWords.word("places","places")})
			if cities<=1:
				c.spark=_history_days(GameState.food_history if food else GameState.water_history,"stored","required")
				if c.spark.size()>=3:c.spark_label="Days held, over the last %d days" % c.spark.size()
			c.action="Click for the %s tally · the Steward keeps the stores at Court" % ("stores" if food else "water")
		"goods":
			var coverage:=float(t.goods_coverage)
			var net:=float(t.goods_net)
			var short:=int(t.goods_shortages)
			c.value=EraWords.goods(coverage)
			c.unit="of what households need" if not hearth else ""
			if short>0:
				c.tone="warning"
				c.headline="%s lack the everyday tools, cords and pots they need." % EraWords.places(short)
			else:c.headline="Households have %s of the tools, cords and pots they expect, and crafts work only as well as this." % ("most" if coverage>=0.6 else "some")
			c.facts.append({"text":"More made than worn out" if net>0.05 else "Wearing out faster than made" if net<-0.05 else "Made about as fast as worn","trend":1 if net>0.05 else -1 if net<-0.05 else 0,"good":net>=-0.05})
			c.meter=coverage
			c.meter_label="Share of what is needed"
			c.action="Click for the Crafts tally"
		"health":
			c.value=EraWords.life(float(t.life))
			c.headline="A child born now may hope to see %s." % EraWords.life(float(t.life)) if not modern else "Life expectancy at birth, weighted across every city."
			var life_series:=_series(GameState.health_history,"life_expectancy",24)
			c.facts.append({"text":EraWords.babes_lost_sentence(float(t.infant))})
			if life_series.size()>=2:
				var change:=float(life_series[-1])-float(life_series[0])
				var unit_word:="winters" if hearth else "years"
				var text:="About as long as before"
				if change>=0.5:text="%d %s longer than before" % [maxi(1,roundi(change)),unit_word]
				elif change<=-0.5:text="%d %s shorter than before" % [maxi(1,roundi(-change)),unit_word]
				c.facts.append({"text":text,"trend":1 if change>=0.5 else -1 if change<=-0.5 else 0,"good":change>=0.0})
			if life_series.size()>=3:
				c.spark=life_series
				c.spark_label="How long we live, lately"
			if float(t.infant)>=250.0:c.tone="warning"
			c.action="Click to see what shortens our lives"
		"science":
			var keepers:=roundi(float(t.minds))
			if modern:
				c.value="%.1f" % float(t.science)
				c.unit="research capacity"
				c.headline="Researchers times their schooling, summed over every city."
				c.facts.append({"text":"%d researchers · %d%% schooled" % [keepers,roundi(float(t.education)*100.0)]})
			else:
				var known:=GameState.known_discoveries.size()
				c.value="%d ways" % known if hearth else "%d practices" % known
				var keeper_word:=("keeper" if keepers==1 else "keepers") if hearth else ("scholar" if keepers==1 else "scholars")
				c.headline="What the people know how to do, kept and taught by %d %s." % [keepers,keeper_word]
				c.facts.append({"text":"How well it is taught: %s" % EraWords.teaching(float(t.education))})
			c.action="Click for %s · what is being learned now" % EraWords.word("rail.inquiry","Research")
		"gdp":
			var per:=float(t.output)/maxf(1.0,float(population))
			if modern:
				c.value="%.1f" % float(t.output)
				c.unit="output / day"
				c.headline="All the work of every city in a day, in one measure."
				c.facts.append({"text":"%.2f per person" % per})
			else:
				c.value="%d hands" % roundi(float(t.output))
				c.headline="Full days of work done each day across the people."
				c.facts.append({"text":"About %.2f of a day's work for every person" % per})
			c.action="Click for the %s tally" % EraWords.word("rail.wealth","Wealth")
	return c

static func _sentence_case(text:String)->String:
	return text.left(1).to_upper()+text.substr(1)

## "309" or "4.5": whole numbers once the amount is large.
static func _amount(value:float)->String:
	return EraWords.grouped(roundi(value)) if absf(value)>=20.0 else "%.1f" % value

## Days of stores recorded in a history (one row a day), last 60 rows.
static func _history_days(history:Array,stock_key:String,need_key:String)->Array:
	var out:=[]
	for row:Dictionary in history.slice(maxi(0,history.size()-60)):
		var need:=float(row.get(need_key,0.0))
		if need>0.0:out.append(float(row.get(stock_key,0.0))/need)
	return out

static func _series(history:Array,key:String,count:int)->Array:
	var out:=[]
	for row:Dictionary in history.slice(maxi(0,history.size()-count)):
		if row.has(key):out.append(float(row[key]))
	return out
