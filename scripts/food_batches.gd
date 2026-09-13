extends RefCounted
## Finite cereal lots and paid, lot-specific observations. The condition values
## are game abstractions, not physical assays or predictions of food safety.
const K=preload("res://scripts/food_batch_knowledge.gd")
const R=preload("res://scripts/technology_requirements.gd")
const G=preload("res://scripts/grain_processing.gd")
const Selected=preload("res://scripts/selected_food_processing.gd")
const LIMIT:=96
const KINDS:=["meal","dehulled","starch","residue","dough","leavened","bread","starter","wet_parboiled","parboiled","solar_drying","solar_dried"]+Selected.KINDS
const UNAVAILABLE:=["dough","leavened","starter","wet_parboiled","solar_drying"]+Selected.KINDS
const ASSAYS:=["humidity","trace","loss","acidity","activity","review","barrier","leak"]
static func empty_state()->Dictionary:return {"tools":{},"lots":[],"next_id":1,"last_day":-1,"report":{}}
static func data()->Dictionary:return WorldSimulation.state.food_batches
static func quote(id:String)->Dictionary:
	if not K.METHODS.has(id):return {"error":"Unknown food equipment."}
	var spec:Dictionary=K.METHODS[id]
	if WorldSimulation.state.convoy_traveling or not WorldSimulation.state.settlement_site_committed:return {"error":"Settle before installing food equipment."}
	if id not in WorldSimulation.state.known_discoveries or WorldSimulation.discovery.adoption(id)<.1 or not R.evaluate(spec,WorldSimulation.state.known_discoveries).ready:return {"error":"Adopt this method and its practical foundations first."}
	if int(data().tools.get(id,0))>=100:return {"error":"Equipment limit reached."}
	for item:String in spec.cost:
		if float(WorldSimulation.state.resource_stockpiles.get(item,0))<float(spec.cost[item]):return {"error":"Installation needs %.1f %s."%[float(spec.cost[item]),item]}
	return {"ok":true,"cost":spec.cost.duplicate(),"message":"Install %s; operation also needs shared Logistics workers and continuing supplies."%spec.name}
static func install(id:String)->Dictionary:
	var terms:=quote(id)
	if terms.has("error"):return terms
	for item:String in terms.cost:WorldSimulation.state.resource_stockpiles[item]-=float(terms.cost[item])
	data().tools[id]=int(data().tools.get(id,0))+1
	return {"ok":true,"message":"Installed "+String(K.METHODS[id].name)}
static func total(include_work:bool=false)->float:
	var value:=0.0
	for lot:Dictionary in data().lots:
		if include_work or lot.kind not in UNAVAILABLE:value+=float(lot.amount)
	return value
static func available_total()->float:return total()
static func in_process()->float:return total(true)-total()
static func capacity(id:String,workers:float)->float:
	if id not in WorldSimulation.state.known_discoveries:return 0.0
	return minf(maxf(0,workers),float(data().tools.get(id,0)))*float(K.METHODS[id].rate)*clampf(WorldSimulation.discovery.adoption(id),0,1)
static func supplied(id:String,requested:float,workers:float,report:Dictionary)->float:
	var amount:=minf(minf(maxf(0,requested),capacity(id,workers)),maxf(0,capacity(id,10000)-float(report.methods.get(id,0))))
	for item:String in K.METHODS[id].inputs:
		amount=minf(amount,maxf(0,float(WorldSimulation.state.resource_stockpiles.get(item,0)))/float(K.METHODS[id].inputs[item]))
	return amount
static func charge(id:String,amount:float,report:Dictionary)->float:
	if amount<=0:return 0.0
	var spec:Dictionary=K.METHODS[id]
	for item:String in spec.inputs:
		var used:=amount*float(spec.inputs[item]);WorldSimulation.state.resource_stockpiles[item]-=used
		report.inputs[item]=float(report.inputs.get(item,0))+used
	var work:=amount/maxf(.000001,float(spec.rate)*WorldSimulation.discovery.adoption(id))
	report.workers+=work;report.methods[id]=float(report.methods.get(id,0))+amount
	return work
static func add_lot(kind:String,amount:float,day:int,origin:float=-1.0)->Dictionary:
	if amount<=.000001 or data().lots.size()>=LIMIT:return {}
	var lot:={"id":int(data().next_id),"kind":kind,"amount":amount,"origin":amount if origin<0 else origin,"created":day,"ready":day,"observations":{},"seal":0.0}
	data().next_id+=1;data().lots.append(lot);return lot
static func withdraw(lot:Dictionary,amount:float)->float:
	amount=minf(maxf(0,amount),float(lot.amount))
	var origin:=float(lot.origin)*amount/maxf(.000001,float(lot.amount))
	lot.amount-=amount;lot.origin-=origin
	return origin
static func clean_empty()->void:
	for i in range(data().lots.size()-1,-1,-1):
		if float(data().lots[i].amount)<.000001:data().lots.remove_at(i)
static func eligible(lot:Dictionary,mode:String,day:int)->bool:
	if int(lot.ready)>day:return false
	match mode:
		"form":return lot.kind=="meal"
		"wash":return lot.kind=="meal"
		"leaven":return lot.kind=="dough"
		"bake":return lot.kind in ["dough","leavened"]
		"culture":return lot.kind=="meal"
		"humidity":return lot.kind=="bread" and not lot.observations.has(mode)
		"trace","loss","acidity":return lot.kind=="bread" and not lot.observations.has(mode)
		"activity":return lot.kind=="bread" and lot.observations.has("humidity") and not lot.observations.has(mode)
		"review":return lot.kind=="bread" and lot.observations.has("trace") and lot.observations.has("activity") and lot.observations.has("acidity") and not lot.observations.has(mode)
		"barrier":return lot.kind=="bread" and lot.observations.has("review") and (not lot.observations.has(mode) or float(lot.seal)<=.75)
		"leak":return lot.kind=="bread" and lot.observations.has("barrier") and (not lot.observations.has(mode) or day-int(lot.observations[mode])>=3)
	return false
static func starter_available(day:int)->float:
	var amount:=0.0
	for lot:Dictionary in data().lots:
		if lot.kind=="starter" and int(lot.ready)<=day:amount+=float(lot.amount)
	return amount
static func consume_starter(amount:float,day:int)->void:
	for lot:Dictionary in data().lots:
		if lot.kind!="starter" or int(lot.ready)>day:continue
		var used:=minf(amount,float(lot.amount));withdraw(lot,used);amount-=used
		if amount<=.000001:break
static func process_lot(id:String,lot:Dictionary,workers:float,report:Dictionary,day:int)->float:
	var mode:String=K.METHODS[id].mode
	if not eligible(lot,mode,day):return 0.0
	var amount:=supplied(id,float(lot.amount),workers,report)
	# Limit commitments to surplus; measurements consume only small samples.
	if mode in ["form","culture","leaven"]:
		amount=minf(amount,maxf(0,WorldSimulation.food._stock_total()-float(WorldSimulation.food._calculate_demand(false).total)*7)*.1)
	if mode=="wash":amount=minf(amount,float(lot.amount)*.25)
	if mode=="culture":amount=minf(amount,maxf(0,float(WorldSimulation.food._calculate_demand(false).total)*.02-starter_available(day)))
	if amount<=.000001:return 0.0
	var replaces:=amount>=float(lot.amount)-.000001
	var slots:int=LIMIT-data().lots.size()+(1 if replaces else 0)
	if slots<(2 if mode=="wash" else 1):return 0.0
	var origin:=withdraw(lot,amount)
	if replaces:data().lots.erase(lot)
	var output:Dictionary
	if mode in ASSAYS:
		var sample:=0.0 if mode=="trace" else amount*.002
		output=add_lot(String(lot.kind),amount-sample,day,origin)
		output.created=lot.created;output.observations=lot.observations.duplicate(true);output.seal=lot.seal
		report.loss+=sample
		match mode:
			"trace":output.observations.trace=int(lot.id)
			"loss":output.observations.loss=maxf(0,1-float(output.amount)/maxf(.000001,origin))
			"humidity":output.observations.humidity=clampf(float(WorldSimulation.food._environment_mix().get("precipitation",.5)),0,1)
			"acidity":output.observations.acidity=0.35 if bool(lot.observations.get("fermented",false)) else .7
			"activity":output.observations.activity=clampf(.3+float(lot.observations.humidity)*.2+float(day-int(lot.created))*.01,0,1)
			"review":output.observations.review=day
			"barrier":
				output.observations.barrier=day;output.seal=1.0
				output.observations.erase("leak");output.observations.erase("leak_pass")
			"leak":output.observations.leak=day;output.observations.leak_pass=float(output.seal)>.75
	else:
		match mode:
			"form":output=add_lot("dough",amount*.995,day,origin)
			"wash":
				output=add_lot("starch",amount*.72,day,origin*.75)
				add_lot("residue",amount*.25,day,origin*.25)
			"culture":output=add_lot("starter",amount*.9,day,origin);output.ready=day+2
			"leaven":
				var starter:=minf(amount*.01,starter_available(day));consume_starter(starter,day)
				output=add_lot("leavened",(amount+starter)*.97,day,origin+starter)
				output.ready=day+(1 if starter>=amount*.00999 else 2);output.observations.fermented=true
				report.loss+=starter*.03
			"bake":
				output=add_lot("bread",amount*.95,day,origin)
				output.observations.fermented=bool(lot.observations.get("fermented",false))
		report.loss+=amount*(.03 if mode in ["wash","leaven"] else (.1 if mode=="culture" else (.05 if mode=="bake" else .005)))
	return charge(id,amount,report)
static func advance(logistics:float,demand:float,traveling:bool)->Dictionary:
	var day:=int(WorldSimulation.state.elapsed_days)
	var report:={"workers":0.0,"loss":0.0,"inputs":{},"methods":{}}
	if int(data().last_day)==day:return report
	data().last_day=day
	if traveling or not WorldSimulation.state.settlement_site_committed:data().report=report;return report
	var workers:=maxf(0,logistics)*.2
	workers-=Selected.process(workers,demand,report,day)
	workers-=condition_grain(workers,demand,report,day)
	# Both player and rival use this same paid, input-aware steward.
	if WorldSimulation.food._stock_total()>maxf(1,demand)*7:
		for id:String in K.METHODS:
			var needed:=false;var mode:String=K.METHODS[id].mode
			if mode=="pound":needed=float(G.data().stocks.clean)>0
			elif mode=="form":needed=float(G.data().stocks.flour)+float(G.data().stocks.fine)>0
			elif mode=="dehull":needed=float(G.data().stocks.grain)>0
			for lot:Dictionary in data().lots:
				if eligible(lot,mode,day):needed=true;break
			if needed and int(data().tools.get(id,0))==0 and not quote(id).has("error"):install(id);break
	# Downstream operations see only lots present at the start of their turn.
	# Fermentation precedes baking so adopted leavening can retain its real delay.
	for mode:String in ["culture","leaven","bake","humidity","trace","loss","acidity","activity","review","barrier","leak","wash","form"]:
		var id:=""
		for candidate:String in K.METHODS:
			if K.METHODS[candidate].mode==mode:id=candidate;break
		for lot:Dictionary in data().lots.duplicate():
			workers-=process_lot(id,lot,workers,report,day)
			if workers<=.000001:break
		clean_empty()
	# Admit only existing grain, never relabel mixed or imported food as cereal.
	for id:String in ["hand_dough_forming","food_pounding_mortars","cereal_dehulling"]:
		for source:String in (["fine","flour"] if id=="hand_dough_forming" else (["clean"] if id=="food_pounding_mortars" else ["grain"])):
			if data().lots.size()>=LIMIT:break
			var amount:=supplied(id,minf(float(G.data().stocks[source]),maxf(0,WorldSimulation.food._stock_total()-demand*7)*.1),workers,report)
			if amount<=.000001:continue
			var yield_ratio:=.995 if id=="hand_dough_forming" else .96
			G.data().stocks[source]-=amount;add_lot("dough" if id=="hand_dough_forming" else ("meal" if id=="food_pounding_mortars" else "dehulled"),amount*yield_ratio,day,amount)
			report.loss+=amount*(1-yield_ratio);workers-=charge(id,amount,report)
	data().report=report;return report
static func issue(requested:float,discard_work:bool=false)->Dictionary:
	var result:={"amount":0.0,"processed":0.0}
	for lot:Dictionary in data().lots:
		if not discard_work and lot.kind in UNAVAILABLE:continue
		var used:=minf(maxf(0,requested-float(result.amount)),float(lot.amount))
		withdraw(lot,used);result.amount+=used
		if lot.kind in ["bread","parboiled","solar_dried"]:result.processed+=used
	clean_empty();return result
static func discard(amount:float)->float:return float(issue(amount,true).amount)
static func spoil(traveling:bool,multiplier:float)->float:
	var lost:=0.0;var day:=int(WorldSimulation.state.elapsed_days)
	for lot:Dictionary in data().lots:
		var rate:=.004 if lot.kind in ["meal","dehulled","starch","residue"] else (.04 if lot.kind=="starter" else .015)
		if lot.kind in ["parboiled","solar_dried"]:rate=.0015
		if lot.kind in ["wet_parboiled","solar_drying"]:rate=.025
		if lot.kind=="bread" and bool(lot.observations.get("leak_pass",false)) and day-int(lot.observations.get("leak",-10))<3 and float(lot.seal)>.75:rate*=.35
		var loss:=minf(float(lot.amount),float(lot.amount)*rate*maxf(0,multiplier)*(1.3 if traveling else 1))
		lot.amount-=loss;lost+=loss;lot.seal=maxf(0,float(lot.seal)-.08)
	clean_empty();return lost
static func number(value:Variant)->bool:return (value is float or value is int) and is_finite(float(value))
static func valid(value:Variant)->bool:
	if not value is Dictionary or not value.has_all(["tools","lots","next_id","last_day","report"]):return false
	if not value.tools is Dictionary or value.tools.size()>K.METHODS.size() or not value.lots is Array or value.lots.size()>LIMIT:return false
	for id:Variant in value.tools:
		if not id is String or not K.METHODS.has(id) or not number(value.tools[id]) or value.tools[id]<0 or value.tools[id]>100 or value.tools[id]!=floorf(float(value.tools[id])):return false
	for key:String in ["next_id","last_day"]:
		if not number(value[key]) or value[key]!=floorf(float(value[key])) or value[key]< (1 if key=="next_id" else -1) or value[key]>1e12:return false
	if value.has("selected_harvest_day") and (not number(value.selected_harvest_day) or float(value.selected_harvest_day)!=floorf(float(value.selected_harvest_day)) or float(value.selected_harvest_day)<-1 or float(value.selected_harvest_day)>1e12):return false
	var ids:Dictionary={}
	for lot:Variant in value.lots:
		if not lot is Dictionary or not lot.has_all(["id","kind","amount","origin","created","ready","observations","seal"]) or lot.kind not in KINDS:return false
		if not Selected.valid_lot(lot):return false
		for key:String in ["id","amount","origin","created","ready","seal"]:
			if not number(lot[key]) or lot[key]<0 or lot[key]>1e12:return false
		if lot.amount<=0 or lot.origin<lot.amount-.00001 or lot.seal>1 or lot.id<1 or lot.id>=value.next_id or lot.ready<lot.created or ids.has(lot.id):return false
		for key:String in ["id","created","ready"]:
			if lot[key]!=floorf(float(lot[key])):return false
		ids[lot.id]=true
		if not lot.observations is Dictionary or lot.observations.size()>12:return false
		for key:Variant in lot.observations:
			if key in ["fermented","leak_pass"]:
				if not lot.observations[key] is bool:return false
			elif key in ASSAYS:
				if not number(lot.observations[key]) or lot.observations[key]<0 or lot.observations[key]>1e12:return false
			else:return false
	if not value.report is Dictionary or value.report.size()>4:return false
	for key:Variant in value.report:
		if key in ["inputs","methods"]:
			if not value.report[key] is Dictionary or value.report[key].size()>32:return false
			for item:Variant in value.report[key]:
				if not item is String or not number(value.report[key][item]) or value.report[key][item]<0 or value.report[key][item]>1e12:return false
		elif key not in ["workers","loss"] or not number(value.report[key]) or value.report[key]<0 or value.report[key]>1e12:return false
	return true
static func valid_settlements(records:Variant)->bool:
	if not records is Array:return false
	for record:Variant in records:
		if not record is Dictionary or not record.get("local_resources",{}) is Dictionary:return false
		if not valid(record.get("local_resources",{}).get("food_batches",empty_state())):return false
	return true

# This is the existing aggregate cereal share, not a claim that every crop is
# suitable for rice-style parboiling. All amounts are ration-energy equivalents.
static func solar_factor(environment:Dictionary,day:int)->float:
	var temperature:=PlanetEnvironment.ambient_temperature_c(environment,day)
	return clampf((temperature-5.0)/20.0,0,1)*clampf((.9-float(environment.get("precipitation",.5)))/.7,0,1)
static func dry_capacity(id:String,requested:float,workers:float,report:Dictionary,weather:float)->float:
	var factor:=weather if id=="indirect_solar_food_drying" else 1.0
	var amount:=minf(maxf(0,requested),minf(capacity(id,workers)*factor,maxf(0,capacity(id,10000)*factor-float(report.methods.get(id,0)))))
	if id=="grain_parboiling":amount=minf(amount,maxf(0,float(WorldSimulation.state.resource_stockpiles.get("Timber",0)))/.015)
	return amount
static func pay_drying(id:String,amount:float,report:Dictionary,weather:float)->float:
	if amount<=.000001:return 0.0
	var factor:=weather if id=="indirect_solar_food_drying" else 1.0
	var work:=amount/(float(K.METHODS[id].rate)*WorldSimulation.discovery.adoption(id)*factor)
	if id=="grain_parboiling":
		var fuel:=amount*.015;WorldSimulation.state.resource_stockpiles.Timber-=fuel
		report.inputs["Timber"]=float(report.inputs.get("Timber",0))+fuel
	report.workers+=work;report.methods[id]=float(report.methods.get(id,0))+amount
	return work
static func condition_grain(workers:float,demand:float,report:Dictionary,day:int)->float:
	var before:=workers
	var weather:=solar_factor(WorldSimulation.food.current_environment_profile(),day)
	var surplus:=maxf(0,WorldSimulation.food._stock_total()-maxf(0,demand)*7)
	# Existing automatic installation pays local stock, one setup per day here.
	if surplus>0:
		for id:String in ["grain_parboiling","indirect_solar_food_drying"]:
			var needed:=float(G.data().stocks.grain)>0 if id=="grain_parboiling" else float(WorldSimulation.state.food_stocks.get("Fresh plants",0))>0 and weather>0
			for lot:Dictionary in data().lots:
				if lot.kind=="wet_parboiled" or (id=="indirect_solar_food_drying" and lot.kind=="solar_drying"):needed=true
			if needed and int(data().tools.get(id,0))==0 and not quote(id).has("error"):install(id);break
	# Finish existing lots before committing more food. Solar drying and fuelled
	# drying are actual alternative services, each with one shared daily quota.
	for lot:Dictionary in data().lots.duplicate():
		if lot.kind not in ["wet_parboiled","solar_drying"] or int(lot.ready)>day:continue
		for id:String in ["indirect_solar_food_drying","grain_parboiling"]:
			if lot.kind=="solar_drying" and id=="grain_parboiling":continue
			var amount:=dry_capacity(id,float(lot.amount),workers,report,weather)
			if amount<=.000001:continue
			var replaces:=amount>=float(lot.amount)-.000001
			if not replaces and data().lots.size()>=LIMIT:continue
			var origin:=withdraw(lot,amount)
			if replaces:data().lots.erase(lot)
			var ratio:=.995 if lot.kind=="wet_parboiled" else .92
			add_lot("parboiled" if lot.kind=="wet_parboiled" else "solar_dried",amount*ratio,day,origin)
			report.loss+=amount*(1-ratio);workers-=pay_drying(id,amount,report,weather)
			if replaces:break
	clean_empty()
	# Grain heating and chamber loading each consume the available daily quota.
	surplus=maxf(0,WorldSimulation.food._stock_total()-maxf(0,demand)*7)
	var amount:=supplied("grain_parboiling",minf(float(G.data().stocks.grain),surplus*.1),workers,report)
	if amount>.000001 and data().lots.size()<LIMIT:
		G.data().stocks.grain-=amount
		var lot:=add_lot("wet_parboiled",amount*.97,day,amount);lot.ready=day+2
		report.loss+=amount*.03;workers-=charge("grain_parboiling",amount,report)
	surplus=maxf(0,WorldSimulation.food._stock_total()-maxf(0,demand)*7)
	amount=dry_capacity("indirect_solar_food_drying",minf(float(WorldSimulation.state.food_stocks.get("Fresh plants",0)),surplus*.1),workers,report,weather)
	if amount>.000001 and data().lots.size()<LIMIT:
		WorldSimulation.state.food_stocks["Fresh plants"]-=amount
		var lot:=add_lot("solar_drying",amount,day);lot.ready=day+1
		workers-=pay_drying("indirect_solar_food_drying",amount,report,weather)
	return before-workers
