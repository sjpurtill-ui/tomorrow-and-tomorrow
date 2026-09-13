extends RefCounted
## Garment units serve one resident each. Condition and exposure coefficients
## are aggregate game balances, not fabric-performance measurements.
const K=preload("res://scripts/clothing_knowledge.gd")
const R=preload("res://scripts/technology_requirements.gd")
const LIMIT:=48
static func empty_state()->Dictionary:return {"tools":{},"lots":[],"last_day":-1,"report":{}}
static func data()->Dictionary:return WorldSimulation.state.household_clothing
static func quote(id:String)->Dictionary:
	if not K.METHODS.has(id):return {"error":"Unknown clothing equipment."}
	if WorldSimulation.state.convoy_traveling or not WorldSimulation.state.settlement_site_committed:return {"error":"Settle before installing clothing equipment."}
	if id not in WorldSimulation.state.known_discoveries or WorldSimulation.discovery.adoption(id)<.1 or not R.evaluate(K.METHODS[id],WorldSimulation.state.known_discoveries).ready:return {"error":"Adopt the method and its foundations first."}
	if int(data().tools.get(id,0))>=100:return {"error":"Equipment limit reached."}
	for item:String in K.METHODS[id].cost:
		if float(WorldSimulation.state.resource_stockpiles.get(item,0))<float(K.METHODS[id].cost[item]):return {"error":"Installation needs %.1f %s."%[float(K.METHODS[id].cost[item]),item]}
	return {"ok":true,"cost":K.METHODS[id].cost.duplicate(),"message":"Install %s; ongoing supplies and shared Logistics work are required."%K.METHODS[id].name}
static func install(id:String)->Dictionary:
	var terms:=quote(id)
	if terms.has("error"):return terms
	for item:String in terms.cost:WorldSimulation.state.resource_stockpiles[item]-=float(terms.cost[item])
	data().tools[id]=int(data().tools.get(id,0))+1
	return {"ok":true,"message":"Installed "+String(K.METHODS[id].name)}
static func count()->float:
	var n:=0.0
	for lot:Dictionary in data().lots:n+=float(lot.amount)
	return n
static func add(kind:String,amount:float,condition:float=1,soil:float=0,layered:bool=false,wick:bool=false,ready:int=0)->bool:
	if amount<=0:return false
	for lot:Dictionary in data().lots:
		if lot.kind==kind and lot.layered==layered and lot.wick==wick and int(lot.ready)==ready:
			var total:=float(lot.amount)+amount
			lot.condition=(float(lot.condition)*float(lot.amount)+condition*amount)/total
			lot.soil=(float(lot.soil)*float(lot.amount)+soil*amount)/total
			lot.amount=total;return true
	if data().lots.size()>=LIMIT:return false
	data().lots.append({"kind":kind,"amount":amount,"condition":condition,"soil":soil,"layered":layered,"wick":wick,"ready":ready});return true
static func coverage(population:float,day:int)->Dictionary:
	var cold:=0.0;var storm:=0.0;var worn:=0.0
	# Bounded stock can exceed residents during replacement. Never count more
	# than one issued garment assembly per resident, including layered pairs.
	for lot:Dictionary in data().lots:
		if int(lot.ready)>day:continue
		var issued:=minf(float(lot.amount),maxf(0,population-worn));worn+=issued
		var service:=issued*float(lot.condition)*(1.0-.35*float(lot.soil))
		var insulation:=.48 if lot.kind=="pile" else (.32 if lot.kind=="knit" else .25)
		cold+=service*minf(.8,insulation+(.25 if lot.layered else 0))
		storm+=service*(.30 if lot.wick else .10)
	return {"cold":clampf(cold/maxf(1,population),0,.8),"storm":clampf(storm/maxf(1,population),0,.3),"issued":worn}
static func quota(id:String,workers:float,report:Dictionary)->float:
	if id not in WorldSimulation.state.known_discoveries:return 0
	var rate:=float(K.METHODS[id].rate)*clampf(WorldSimulation.discovery.adoption(id),0,1)
	var amount:=minf(maxf(0,workers)*rate,maxf(0,float(data().tools.get(id,0))*rate-float(report.methods.get(id,0))))
	for item:String in K.METHODS[id].inputs:amount=minf(amount,maxf(0,float(WorldSimulation.state.resource_stockpiles.get(item,0)))/float(K.METHODS[id].inputs[item]))
	return amount
static func charge(id:String,amount:float,report:Dictionary)->void:
	for item:String in K.METHODS[id].inputs:
		var used:=float(K.METHODS[id].inputs[item])*amount
		WorldSimulation.state.resource_stockpiles[item]-=used
		report.inputs[item]=float(report.inputs.get(item,0))+used
	report.methods[id]=float(report.methods.get(id,0))+amount
	report.workers+=amount/maxf(.000001,float(K.METHODS[id].rate)*WorldSimulation.discovery.adoption(id))
static func operate(id:String,workers:float,population:float,day:int,report:Dictionary)->void:
	var mode:=String(K.METHODS[id].mode)
	if mode in ["knit","twill","pile"]:
		var amount:=minf(quota(id,workers,report),maxf(0,population*1.1-count()))
		if amount>0 and add(mode,amount):charge(id,amount,report)
		return
	var used_before:=float(report.workers)
	for lot:Dictionary in data().lots.duplicate():
		if int(lot.ready)>day:continue
		if mode=="layer" and (lot.layered or float(lot.condition)<.7):continue
		if mode=="wash" and float(lot.soil)<.35:continue
		if mode=="wick" and lot.wick:continue
		var multiplier:=2.0 if mode=="layer" else 1.0
		var amount:=minf(float(lot.amount)/multiplier,quota(id,maxf(0,workers-(float(report.workers)-used_before)),report))
		# Keep enough unlayered garments for everyone before pairing spares.
		if mode=="layer":amount=minf(amount,maxf(0,count()-population))
		if amount<=.000001:continue
		# Admit output before withdrawing or charging; a full ledger waits safely.
		if not add(String(lot.kind),amount,float(lot.condition),0 if mode=="wash" else float(lot.soil),bool(lot.layered) or mode=="layer",bool(lot.wick) or mode=="wick",day+1 if mode=="wash" else 0):continue
		lot.amount-=amount*multiplier
		charge(id,amount,report)
	for i in range(data().lots.size()-1,-1,-1):
		if float(data().lots[i].amount)<.000001:data().lots.remove_at(i)
static func advance(workers:float,population:float,traveling:bool)->Dictionary:
	var day:=int(WorldSimulation.state.elapsed_days)
	if int(data().last_day)==day:return {"workers":0.0,"coverage":coverage(population,day)}
	data().last_day=day
	var report:={"workers":0.0,"inputs":{},"methods":{},"discarded":0.0}
	var remaining_wear:=maxf(0,population)
	for lot:Dictionary in data().lots:
		if int(lot.ready)<=day:
			lot.ready=0
			var used:=minf(float(lot.amount),remaining_wear);remaining_wear-=used
			var share:=used/maxf(.000001,float(lot.amount))
			lot.condition=maxf(0,float(lot.condition)-(.008 if traveling else .004)*share)
			lot.soil=minf(1,float(lot.soil)+.025*share)
	for i in range(data().lots.size()-1,-1,-1):
		if float(data().lots[i].condition)<.15:report.discarded+=float(data().lots[i].amount);data().lots.remove_at(i)
	var budget:=maxf(0,workers)*.2
	if not traveling:
		# Same paid steward for every owner; install only usable equipment.
		for id:String in K.METHODS:
			if int(data().tools.get(id,0))>0:continue
			var supplied:=true
			for item:String in K.METHODS[id].inputs:
				if float(WorldSimulation.state.resource_stockpiles.get(item,0))<float(K.METHODS[id].inputs[item]):supplied=false
			if budget>0 and supplied and (count()>0 or K.METHODS[id].mode in ["knit","twill","pile"]) and not quote(id).has("error"):
				install(id);break
		for id:String in K.METHODS:
			operate(id,maxf(0,budget-float(report.workers)),population,day,report)
	data().report=report
	return {"workers":report.workers,"coverage":coverage(population,day)}
static func number(value:Variant)->bool:return (value is float or value is int) and is_finite(float(value))
static func valid(value:Variant)->bool:
	if not value is Dictionary or not value.has_all(["tools","lots","last_day","report"]):return false
	if not value.tools is Dictionary or value.tools.size()>K.METHODS.size() or not value.lots is Array or value.lots.size()>LIMIT:return false
	if not number(value.last_day) or value.last_day< -1 or value.last_day>1e12 or value.last_day!=floorf(float(value.last_day)):return false
	for id:Variant in value.tools:
		if not id is String or not K.METHODS.has(id) or not number(value.tools[id]) or value.tools[id]<0 or value.tools[id]>100 or value.tools[id]!=floorf(float(value.tools[id])):return false
	for lot:Variant in value.lots:
		if not lot is Dictionary or not lot.has_all(["kind","amount","condition","soil","layered","wick","ready"]):return false
		if lot.kind not in ["knit","twill","pile"] or not lot.layered is bool or not lot.wick is bool:return false
		for key:String in ["amount","condition","soil","ready"]:
			if not number(lot[key]) or lot[key]<0 or lot[key]>1e12:return false
		if lot.amount<=0 or lot.condition>1 or lot.soil>1 or lot.ready!=floorf(float(lot.ready)):return false
	if not value.report is Dictionary or value.report.size()>4:return false
	for key:Variant in value.report:
		if key in ["inputs","methods"]:
			if not value.report[key] is Dictionary or value.report[key].size()>32:return false
			for item:Variant in value.report[key]:
				if not item is String or not number(value.report[key][item]) or value.report[key][item]<0 or value.report[key][item]>1e12:return false
		elif key not in ["workers","discarded"] or not number(value.report[key]) or value.report[key]<0 or value.report[key]>1e12:return false
	return true
static func valid_settlements(records:Variant)->bool:
	if not records is Array:return false
	for record:Variant in records:
		if not record is Dictionary or not record.get("local_resources",{}) is Dictionary:return false
		if not valid(record.get("local_resources",{}).get("household_clothing",empty_state())):return false
	return true
