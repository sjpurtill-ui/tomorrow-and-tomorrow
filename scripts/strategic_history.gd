extends RefCounted
## Aggregate observed snapshots. No inferred past, foreign data or resident rows.
const MONTHLY_LIMIT:=120
const ANNUAL_LIMIT:=256
static func capture_scopes()->Dictionary:
	var scopes:={"civilization":{"population":GameState.population_total}}
	for city in GameState.player_settlements:
		var id:=String(city.get("id",""))
		if id.is_empty(): continue
		var row:={"population":roundi(SettlementModel._settlement_population(city))}
		var primary:=bool(city.get("primary",false))
		var local:Dictionary=city.get("local_resources",{})
		var metrics:Dictionary=GameState.simulation_metrics if primary else local.get("simulation_metrics",{})
		var water:Dictionary=GameState.water_metrics if primary else local.get("water_metrics",{})
		var stocks:Dictionary=GameState.resource_stockpiles if primary else local.get("resource_stockpiles",{})
		var stage:=String(GameState.economy_stage if primary else local.get("economy_stage","subsistence"))
		var accounts:={"treasury":"public_treasury","private_currency":"private_currency","hoards":"currency_hoards","aid":"mutual_aid_reserve"} if stage=="currency" else {"metal":"weighed_metal_circulation"} if stage=="weighed_metal" else {}
		for key in accounts:
			var field:String=accounts[key]
			if primary or local.has(field): row[key]=GameState.get(field) if primary else local[field]
		for field in ["food_days","food_production","food_eaten"]:
			if metrics.has(field): row[field]=maxf(0.0,float(metrics[field]))
		if water.has("days"): row["water_days"]=maxf(0.0,float(water.days))
		if not stocks.is_empty():
			for field in ["Timber","Stone","Clay","Fiber Plants"]: row[field]=maxf(0.0,float(stocks.get(field,0.0)))
		scopes[id]=row
	return scopes

static func record(history:Dictionary,day:int,scopes:Dictionary)->void:
	if history.has("last_day") and day-int(history.last_day)<30: return
	history["last_day"]=day
	var ledgers:Dictionary=history.get("scopes",{})
	for id in ledgers.keys():
		if not scopes.has(id): ledgers.erase(id)
	for id in scopes:
		var ledger:Dictionary=ledgers.get(id,{"monthly":[],"annual":[]})
		var row:Dictionary=scopes[id].duplicate(true)
		row["day"]=day
		var monthly:Array=ledger.monthly
		monthly.append(row)
		while monthly.size()>MONTHLY_LIMIT: monthly.pop_front()
		var annual:Array=ledger.annual
		if not annual.is_empty() and int(annual[-1].day)/365==day/365: annual[-1]=row.duplicate(true)
		else: annual.append(row.duplicate(true))
		while annual.size()>ANNUAL_LIMIT: annual.pop_front()
		ledgers[id]=ledger
	history["scopes"]=ledgers

static func sample()->void:
	var day:=int(GameState.elapsed_days)
	if GameState.strategic_history.has("last_day") and day-int(GameState.strategic_history.last_day)<30: return
	record(GameState.strategic_history,day,capture_scopes())

static func points(history:Dictionary,scope:String)->Array:
	var ledger:Dictionary=history.get("scopes",{}).get(scope,{})
	var monthly:Array=ledger.get("monthly",[])
	var result:Array=[]
	var boundary:=int(monthly[0].day) if not monthly.is_empty() else 2147483647
	for row in ledger.get("annual",[]):
		if int(row.day)<boundary: result.append(row.duplicate(true))
	result.append_array(monthly.duplicate(true))
	return result

static func available_points(scope:String,series:Array)->Array:
	var rows:Dictionary={}
	if scope=="civilization":
		for entry in GameState.demographic_ledger:
			if entry.has("day") and entry.has("population_after"): rows[int(entry.day)]={"day":int(entry.day),"population":int(entry.population_after)}
	else:
		var city:Dictionary=SettlementModel.settlement_record(scope)
		var primary:=bool(city.get("primary",false))
		var local:Dictionary=city.get("local_resources",{})
		var food:Array=GameState.food_history if primary else local.get("food_history",[])
		var water:Array=GameState.water_history if primary else local.get("water_history",[])
		var economy:Array=GameState.economy_history if primary else local.get("economy_history",[])
		for entry in economy:
			if not entry.has("day"): continue
			var row:Dictionary=rows.get(int(entry.day),{"day":int(entry.day)})
			if String(entry.get("stage",""))=="currency":
				if entry.has("treasury"): row["treasury"]=entry.treasury
				if entry.has("currency_hoards"): row["hoards"]=entry.currency_hoards
			elif String(entry.get("stage",""))=="weighed_metal" and entry.has("metal_circulation"): row["metal"]=entry.metal_circulation
			rows[int(entry.day)]=row
		for entry in food:
			if not entry.has("day"): continue
			var row:={"day":int(entry.day)}
			if entry.has("produced"): row["food_production"]=entry.produced
			if entry.has("eaten"): row["food_eaten"]=entry.eaten
			if entry.has("stored") and float(entry.get("required",0))>0: row["food_days"]=float(entry.stored)/float(entry.required)
			rows[int(entry.day)]=row
		for entry in water:
			if not entry.has("day"): continue
			var row:Dictionary=rows.get(int(entry.day),{"day":int(entry.day)})
			if entry.has("stored") and float(entry.get("required",0))>0: row["water_days"]=float(entry.stored)/float(entry.required)
			rows[int(entry.day)]=row
	for entry in points(GameState.strategic_history,scope):
		var row:Dictionary=rows.get(int(entry.day),{})
		row.merge(entry,true)
		rows[int(entry.day)]=row
	var days:Array=rows.keys()
	days.sort()
	var result:Array=[]
	for day in days:
		for line in series:
			if rows[day].has(line.key): result.append(rows[day]);break
	# Existing logs are independently bounded; cap rendered observation count too.
	if result.size()>1200: result=result.slice(result.size()-1200)
	return result

static func block(id:String,title:String,scope:String,unit:String,series:Array,note:String)->Dictionary:
	return {"type":"trend_chart","id":id+":"+scope,"heading":title,"scope":scope,"unit":unit,"series":series,"items":available_points(scope,series),"description":note+" Existing recorded logs plus monthly snapshots for 10 years and older annual snapshots (up to 256 years). Unrecorded history is unavailable."}
