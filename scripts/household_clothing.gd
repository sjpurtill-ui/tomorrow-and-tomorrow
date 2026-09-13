extends RefCounted
## Garment units serve one resident each. Condition and exposure coefficients
## are aggregate game balances, not fabric-performance measurements.
const K=preload("res://scripts/clothing_knowledge.gd")
const R=preload("res://scripts/technology_requirements.gd")
const Barriers=preload("res://scripts/textile_barriers.gd")
const LIMIT:=48
const FINISH_FABRICS:={"tannin":"tannin dyed","resist":"resist patterned","printed":"block printed","calendered":"calendered"}
const QUILT_REPAIR_INPUTS:={"Plant-Fiber Quilt Batts":.08,"Woven Cloth":.08,"Spun Yarn":.03}
const HUNTING_BYPRODUCTS:={"Pancreatic Tissue": "Selected gland tissue from actual newly hunted rations, bounded and rapidly decaying","Recovered Animal Fat": "Actual newly hunted rations, once per local day; bounded stock and daily decay","Raw Hides": "Actual newly hunted rations, once per local day; bounded stock and daily decay"}
const BONE_RESOURCE:="Recovered Bone"
const CREATION_MODES:=["knit","twill","pile","sew","fit","grade","leather","tied","quilt","rain_shell"]
const INSULATION:={"knit":.32,"twill":.25,"pile":.48,"sew":.32,"fit":.42,"grade":.42,"leather":.32,"tied":.25,"quilt":.50,"rain_shell":.18}
static func empty_state()->Dictionary:return {"tools":{},"lots":[],"bone_stock":0.0,"last_day":-1,"report":{}}
static func data()->Dictionary:return WorldSimulation.state.household_clothing
static func available(item:String)->float:
	return float(data().get("bone_stock",0)) if item==BONE_RESOURCE else float(WorldSimulation.state.resource_stockpiles.get(item,0))
static func spend(item:String,amount:float)->void:
	if item==BONE_RESOURCE:data().bone_stock=maxf(0,available(item)-amount)
	else:WorldSimulation.state.resource_stockpiles[item]=maxf(0,available(item)-amount)
static func materials(id:String,installation:bool=false)->Dictionary:
	var result:Dictionary=K.METHODS[id].cost.duplicate() if installation else K.METHODS[id].inputs.duplicate()
	# Existing sewing/cutting skills can use an imported figured fabric. Pattern
	# origin is retained in the garment lot; it grants no insulation multiplier.
	if String(K.METHODS[id].mode) in ["sew","fit","grade","tied","quilt"] and result.has("Woven Cloth") and available("Figured Cloth")>=float(result["Woven Cloth"]):
		result["Figured Cloth"]=result["Woven Cloth"];result.erase("Woven Cloth")
	return result
static func leather_count()->float:
	var amount:=0.0
	for lot:Dictionary in data().lots:
		if lot.kind=="leather":amount+=float(lot.amount)
	return amount
static func leather_target(population:float)->float:
	var state=WorldSimulation.state
	var id:="leather_goods_patterning"
	if state.convoy_traveling or not state.settlement_site_committed or id not in state.known_discoveries or WorldSimulation.discovery.adoption(id)<.1 or not R.evaluate(K.METHODS[id],state.known_discoveries).ready:return 0.0
	var amount:=maxf(0,population*1.1-count())*.65
	for lot:Dictionary in data().lots:
		if lot.kind=="leather" and float(lot.condition)>=.15 and float(lot.condition)<.6:amount+=float(lot.amount)*.08
	if int(data().tools.get(id,0))==0 and amount>0:amount+=.2
	return minf(6,ceilf(amount))
static func compatible_service(mode:String,lot:Dictionary)->bool:
	if lot.kind=="rain_shell" and mode in ["layer","wick","repair","test"]:return false
	return (lot.kind!="leather" or mode not in ["wash","machine_wash","wick","repair","test"]) and not (lot.kind=="quilt" and mode=="repair")
static func figured_count()->float:
	var amount:=0.0
	for lot:Dictionary in data().lots:
		if String(lot.get("fabric","plain"))=="figured":amount+=float(lot.amount)
	return amount
static func figured_target(population:float)->float:
	var state=WorldSimulation.state
	if state.convoy_traveling or not state.settlement_site_committed or count()>=population*1.1:return 0.0
	for id:String in ["bone_needle_sewing","garment_pattern_cutting","garment_size_grading"]:
		if id in state.known_discoveries and WorldSimulation.discovery.adoption(id)>=.1 and R.evaluate(K.METHODS[id],state.known_discoveries).ready:
			return minf(6,ceilf(maxf(0,population*.25-figured_count())*.7))
	return 0.0
static func quote(id:String)->Dictionary:
	if not K.METHODS.has(id):return {"error":"Unknown clothing equipment."}
	if float(K.METHODS[id].get("power",0))>0 and not WorldSimulation.state.resource_settlement_id.is_empty():return {"error":"This city has no connected electricity service for this equipment."}
	if WorldSimulation.state.convoy_traveling or not WorldSimulation.state.settlement_site_committed:return {"error":"Settle before installing clothing equipment."}
	if id not in WorldSimulation.state.known_discoveries or WorldSimulation.discovery.adoption(id)<.1 or not R.evaluate(K.METHODS[id],WorldSimulation.state.known_discoveries).ready:return {"error":"Adopt the method and its foundations first."}
	if int(data().tools.get(id,0))>=100:return {"error":"Equipment limit reached."}
	var costs:=materials(id,true)
	for item:String in costs:
		if available(item)<float(costs[item]):return {"error":"Installation needs %.1f %s."%[float(costs[item]),item]}
	return {"ok":true,"cost":costs,"message":"Install %s; ongoing supplies and shared Logistics work are required."%K.METHODS[id].name}
static func install(id:String)->Dictionary:
	var terms:=quote(id)
	if terms.has("error"):return terms
	for item:String in terms.cost:spend(item,float(terms.cost[item]))
	data().tools[id]=int(data().tools.get(id,0))+1
	return {"ok":true,"message":"Installed "+String(K.METHODS[id].name)}
static func count()->float:
	var n:=0.0
	for lot:Dictionary in data().lots:n+=float(lot.amount)
	return n
static func add(kind:String,amount:float,condition:float=1,soil:float=0,layered:bool=false,wick:bool=false,ready:int=0,fabric:String="plain",barrier:Dictionary={},finish_strength:float=1.0)->bool:
	if amount<=0 or (fabric not in ["plain","figured"] and not FINISH_FABRICS.has(fabric)) or not is_finite(finish_strength) or finish_strength<0 or finish_strength>1:return false
	if kind=="rain_shell" and barrier.is_empty():barrier=Barriers.fresh()
	for lot:Dictionary in data().lots:
		if lot.kind==kind and lot.layered==layered and lot.wick==wick and int(lot.ready)==ready and String(lot.get("fabric","plain"))==fabric and (kind!="rain_shell" or lot.get("barrier",Barriers.fresh())==barrier):
			var total:=float(lot.amount)+amount
			lot.condition=(float(lot.condition)*float(lot.amount)+condition*amount)/total
			lot.soil=(float(lot.soil)*float(lot.amount)+soil*amount)/total
			if FINISH_FABRICS.has(fabric):lot.finish_strength=(float(lot.get("finish_strength",1))*float(lot.amount)+finish_strength*amount)/total
			lot.amount=total;return true
	if data().lots.size()>=LIMIT:return false
	var added:={"kind":kind,"amount":amount,"condition":condition,"soil":soil,"layered":layered,"wick":wick,"ready":ready,"fabric":fabric}
	if kind=="rain_shell":added.barrier=barrier.duplicate(true)
	if FINISH_FABRICS.has(fabric):added.finish_strength=finish_strength
	data().lots.append(added);return true
static func coverage(population:float,day:int)->Dictionary:
	var cold:=0.0;var storm:=0.0;var worn:=0.0
	# Bounded stock can exceed residents during replacement. Never count more
	# than one issued garment assembly per resident, including layered pairs.
	for lot:Dictionary in data().lots:
		if int(lot.ready)>day:continue
		var issued:=minf(float(lot.amount),maxf(0,population-worn));worn+=issued
		var service:=issued*float(lot.condition)*(1.0-.35*float(lot.soil))
		var insulation:=float(INSULATION[lot.kind])
		cold+=service*minf(.8,insulation+(.25 if lot.layered else 0))
		storm+=service*(Barriers.storm_factor(lot) if lot.kind=="rain_shell" else .30 if lot.wick else .10)
	return {"cold":clampf(cold/maxf(1,population),0,.8),"storm":clampf(storm/maxf(1,population),0,.5),"issued":worn}
static func power_demand()->float:
	var state=WorldSimulation.state
	var seam_demand:=Barriers.power_demand(load("res://scripts/household_clothing.gd"))
	var id:="mechanical_washing_machines"
	if not state.resource_settlement_id.is_empty() or state.convoy_traveling or not state.settlement_site_committed or id not in state.known_discoveries:return seam_demand
	var rate:=float(K.METHODS[id].rate)*clampf(WorldSimulation.discovery.adoption(id),0,1)
	var laundry_workers:=maxf(0,state.effective_workers("Logistics")*.2-seam_demand/.2)
	var amount:=minf(float(data().tools.get(id,0))*rate,laundry_workers*rate)
	var dirty:=0.0
	var remaining_wear:=maxf(0,WorldSimulation.settlements.primary_population_exact())
	for lot:Dictionary in data().lots:
		if int(lot.ready)>int(state.elapsed_days) or not compatible_service("machine_wash",lot):continue
		var used:=minf(float(lot.amount),remaining_wear);remaining_wear-=used
		var new_soil:=.025*used/maxf(.000001,float(lot.amount)) if int(data().last_day)<int(state.elapsed_days) else 0.0
		if float(lot.soil)+new_soil>=.35:dirty+=float(lot.amount)
	amount=minf(amount,dirty)
	var inputs:=materials(id)
	for item:String in inputs:amount=minf(amount,maxf(0,available(item))/float(inputs[item]))
	return seam_demand+amount*float(K.METHODS[id].power)

static func test_cycles(workers:float,population:float,day:int,report:Dictionary)->void:
	var id:="textile_durability_testing"
	if not data().has("trials"):data().trials={}
	var before_work:=float(report.workers)
	for kind:String in CREATION_MODES:
		if kind in ["leather","rain_shell"]:continue
		var trial:Dictionary=data().trials.get(kind,{})
		if not trial.is_empty() and (int(trial.last_day)>=day or (int(trial.cycles)>=5 and day-int(trial.last_day)<30)):continue
		if quota(id,maxf(0,workers-(float(report.workers)-before_work)),report)<1.0-.000000001:break
		if trial.is_empty() or int(trial.cycles)>=5:
			if count()-population<.25:continue
			var sample:Dictionary={}
			for lot:Dictionary in data().lots:
				if lot.kind==kind and int(lot.ready)<=day and float(lot.amount)>=.25:sample=lot;break
			if sample.is_empty():continue
			trial={"started":day,"last_day":day,"cycles":0,"before":float(sample.condition),"condition":float(sample.condition),"sample":.25}
			sample.amount-=.25;data().trials[kind]=trial
		# A declared accelerated game protocol, not a clinical or textile rating.
		# Each dated cycle needs real water, paper and finite equipment/crew time.
		trial.condition=maxf(0,float(trial.condition)-.02)
		trial.cycles+=1;trial.last_day=day
		charge(id,1,report)
	for i in range(data().lots.size()-1,-1,-1):
		if float(data().lots[i].amount)<.000001:data().lots.remove_at(i)

static func quota(id:String,workers:float,report:Dictionary,override_inputs:Dictionary={})->float:
	if id not in WorldSimulation.state.known_discoveries:return 0
	var rate:=float(K.METHODS[id].rate)*clampf(WorldSimulation.discovery.adoption(id),0,1)
	var amount:=minf(maxf(0,workers)*rate,maxf(0,float(data().tools.get(id,0))*rate-float(report.methods.get(id,0))))
	var inputs:=materials(id) if override_inputs.is_empty() else override_inputs
	for item:String in inputs:amount=minf(amount,maxf(0,available(item))/float(inputs[item]))
	var power:=float(K.METHODS[id].get("power",0))
	if power>0:amount=minf(amount,preload("res://scripts/technology_operations.gd").service("electricity")/power)
	return amount
static func charge(id:String,amount:float,report:Dictionary,override_inputs:Dictionary={})->void:
	var inputs:=materials(id) if override_inputs.is_empty() else override_inputs
	for item:String in inputs:
		var used:=float(inputs[item])*amount
		spend(item,used)
		report.inputs[item]=float(report.inputs.get(item,0))+used
	var power:=float(K.METHODS[id].get("power",0))*amount
	if power>0:
		preload("res://scripts/technology_operations.gd").consume_electricity(power)
		report.inputs["Electricity"]=float(report.inputs.get("Electricity",0))+power
	report.methods[id]=float(report.methods.get(id,0))+amount
	report.workers+=amount/maxf(.000001,float(K.METHODS[id].rate)*WorldSimulation.discovery.adoption(id))
static func operate(id:String,workers:float,population:float,day:int,report:Dictionary)->void:
	var mode:=String(K.METHODS[id].mode)
	if mode in ["rain_shell","seal_rain_seams"]:
		Barriers.operate(load("res://scripts/household_clothing.gd"),id,workers,population,day,report);return
	if mode=="test":test_cycles(workers,population,day,report);return
	var washing:=mode in ["wash","machine_wash"]
	if mode in CREATION_MODES:
		var spent_before:=float(report.workers)
		if mode in ["leather","quilt"]:
			var patches:={"Flexible Leather":.08,"Spun Yarn":.03} if mode=="leather" else QUILT_REPAIR_INPUTS
			for lot:Dictionary in data().lots:
				if lot.kind!=mode or int(lot.ready)>day or float(lot.condition)<.15 or float(lot.condition)>=.6:continue
				var repaired:=minf(float(lot.amount),quota(id,maxf(0,workers-(float(report.workers)-spent_before)),report,patches))
				if repaired<=.000001:continue
				lot.condition=float(lot.condition)+minf(.3,.85-float(lot.condition))*repaired/float(lot.amount)
				charge(id,repaired,report,patches)
		var amount:=minf(quota(id,maxf(0,workers-(float(report.workers)-spent_before)),report),maxf(0,population*1.1-count()))
		var fabric:=String(K.METHODS[id].get("fabric","figured" if materials(id).has("Figured Cloth") else "plain"))
		if amount>0 and add(mode,amount,1,0,false,false,0,fabric):charge(id,amount,report)
		return
	var used_before:=float(report.workers)
	for lot:Dictionary in data().lots.duplicate():
		if int(lot.ready)>day or not compatible_service(mode,lot):continue
		if mode=="layer" and (lot.layered or float(lot.condition)<.7):continue
		if washing and float(lot.soil)<.35:continue
		if mode=="wick" and lot.wick:continue
		if mode=="repair":
			if float(lot.condition)>=.6 or float(lot.condition)<.15:continue
			var repaired:=minf(float(lot.amount),quota(id,maxf(0,workers-(float(report.workers)-used_before)),report))
			if repaired<=.000001:continue
			lot.condition=float(lot.condition)+minf(.3,.85-float(lot.condition))*repaired/float(lot.amount)
			charge(id,repaired,report);continue
		var multiplier:=2.0 if mode=="layer" else 1.0
		var amount:=minf(float(lot.amount)/multiplier,quota(id,maxf(0,workers-(float(report.workers)-used_before)),report))
		# Keep enough unlayered garments for everyone before pairing spares.
		if mode=="layer":amount=minf(amount,maxf(0,count()-population))
		if amount<=.000001:continue
		# Admit output before withdrawing or charging; a full ledger waits safely.
		if not add(String(lot.kind),amount,maxf(0,float(lot.condition)-(.002 if mode=="machine_wash" else 0)),0 if washing else float(lot.soil),bool(lot.layered) or mode=="layer",bool(lot.wick) or mode=="wick",day+1 if washing else 0,String(lot.get("fabric","plain")),{},float(lot.get("finish_strength",1))*(.6 if lot.get("fabric")=="calendered" else .96) if washing else float(lot.get("finish_strength",1))):continue
		lot.amount-=amount*multiplier
		charge(id,amount,report)
	for i in range(data().lots.size()-1,-1,-1):
		if float(data().lots[i].amount)<.000001:data().lots.remove_at(i)
static func advance(workers:float,population:float,traveling:bool,hunted_rations:float=0)->Dictionary:
	var day:=int(WorldSimulation.state.elapsed_days)
	if int(data().last_day)==day:return {"workers":0.0,"coverage":coverage(population,day)}
	data().last_day=day
	# Raw hides are local hunting byproducts, not a conversion of stored meat.
	# The existing once-per-day clothing guard also owns decay and collection.
	# Selected gland tissue supports a specific protease process. Existing daily
	# guard scopes harvest and biological activity loss to this settlement.
	var tissue:=maxf(0,available("Pancreatic Tissue"))*.25
	if "enzyme_catalysis" in WorldSimulation.state.known_discoveries and WorldSimulation.discovery.adoption("enzyme_catalysis")>=.1 and is_finite(hunted_rations):tissue+=maxf(0,hunted_rations)*.0002
	WorldSimulation.state.resource_stockpiles["Pancreatic Tissue"]=minf(maxf(0,population)*.001,tissue)
	for enzyme:String in ["Pancreatic Enzyme Fraction","Bating Protease"]:
		if WorldSimulation.state.resource_stockpiles.has(enzyme):WorldSimulation.state.resource_stockpiles[enzyme]=maxf(0,available(enzyme))*(.5 if enzyme=="Pancreatic Enzyme Fraction" else .98)
	var fat:=maxf(0,available("Recovered Animal Fat"))*.75
	var raw:=maxf(0,available("Raw Hides"))*.75
	var tanning:="hide_tanning" in WorldSimulation.state.known_discoveries and WorldSimulation.discovery.adoption("hide_tanning")>=.1
	var parchment:="parchment_record_preparation" in WorldSimulation.state.known_discoveries and WorldSimulation.discovery.adoption("parchment_record_preparation")>=.1
	if is_finite(hunted_rations):
		if tanning or parchment:raw+=maxf(0,hunted_rations)*.001
		if tanning:fat+=maxf(0,hunted_rations)*.0005
	WorldSimulation.state.resource_stockpiles["Recovered Animal Fat"]=minf(maxf(0,population)*.01,fat)
	WorldSimulation.state.resource_stockpiles["Raw Hides"]=minf(maxf(0,population)*.02,raw)
	# Non-edible byproduct of actual newly hunted food, never imported meat,
	# opening food stores or a forecast. Collected once per local day.
	var recovered:=0.0
	if "bone_needle_sewing" in WorldSimulation.state.known_discoveries and WorldSimulation.discovery.adoption("bone_needle_sewing")>=.1 and is_finite(hunted_rations):recovered=maxf(0,hunted_rations)*.002
	data().bone_stock=minf(maxf(0,population)*.05,available(BONE_RESOURCE)+recovered)
	var report:={"workers":0.0,"inputs":{},"methods":{},"discarded":0.0}
	var remaining_wear:=maxf(0,population)
	for lot:Dictionary in data().lots:
		if int(lot.ready)<=day:
			lot.ready=0
			var used:=minf(float(lot.amount),remaining_wear);remaining_wear-=used
			var share:=used/maxf(.000001,float(lot.amount))
			var wear:=.008 if traveling else .004
			if lot.kind=="leather":wear+=.004*clampf(float(WorldSimulation.food.current_environment_profile().get("precipitation",.5)),0,1)
			lot.condition=maxf(0,float(lot.condition)-wear*share)
			lot.soil=minf(1,float(lot.soil)+.025*share)
			if FINISH_FABRICS.has(String(lot.get("fabric","plain"))):lot.finish_strength=maxf(0,float(lot.get("finish_strength",1))-(.003 if lot.fabric=="calendered" else .001)*share)
	for i in range(data().lots.size()-1,-1,-1):
		if float(data().lots[i].condition)<.15:report.discarded+=float(data().lots[i].amount);data().lots.remove_at(i)
	var budget:=maxf(0,workers)*.2
	if not traveling:
		# Same paid steward for every owner; install only usable equipment.
		for id:String in K.METHODS:
			if int(data().tools.get(id,0))>0:continue
			if K.METHODS[id].mode=="test" and count()-population<.25:continue
			var supplied:=true
			var inputs:=materials(id)
			for item:String in inputs:
				if available(item)<float(inputs[item]):supplied=false
			if budget>0 and supplied and (count()>0 or K.METHODS[id].mode in CREATION_MODES) and not quote(id).has("error"):
				install(id);break
		for id:String in K.METHODS:
			operate(id,maxf(0,budget-float(report.workers)),population,day,report)
	data().report=report
	return {"workers":report.workers,"coverage":coverage(population,day)}
static func number(value:Variant)->bool:return (value is float or value is int) and is_finite(float(value))
static func valid(value:Variant)->bool:
	if not value is Dictionary or not value.has_all(["tools","lots","last_day","report"]):return false
	if not number(value.get("bone_stock",0)) or float(value.get("bone_stock",0))<0 or float(value.get("bone_stock",0))>1e12:return false
	if not value.tools is Dictionary or value.tools.size()>K.METHODS.size() or not value.lots is Array or value.lots.size()>LIMIT:return false
	if not number(value.last_day) or value.last_day< -1 or value.last_day>1e12 or value.last_day!=floorf(float(value.last_day)):return false
	for id:Variant in value.tools:
		if not id is String or not K.METHODS.has(id) or not number(value.tools[id]) or value.tools[id]<0 or value.tools[id]>100 or value.tools[id]!=floorf(float(value.tools[id])):return false
	for lot:Variant in value.lots:
		if not lot is Dictionary or not lot.has_all(["kind","amount","condition","soil","layered","wick","ready"]):return false
		if lot.kind not in CREATION_MODES or not lot.layered is bool or not lot.wick is bool:return false
		if lot.kind=="rain_shell" and not Barriers.valid(lot.get("barrier",Barriers.fresh())):return false
		if not lot.get("fabric","plain") is String or (lot.get("fabric","plain") not in ["plain","figured"] and not FINISH_FABRICS.has(lot.get("fabric"))):return false
		if lot.has("finish_strength") and (not FINISH_FABRICS.has(lot.get("fabric")) or not number(lot.finish_strength) or lot.finish_strength<0 or lot.finish_strength>1):return false
		for key:String in ["amount","condition","soil","ready"]:
			if not number(lot[key]) or lot[key]<0 or lot[key]>1e12:return false
		if lot.amount<=0 or lot.condition>1 or lot.soil>1 or lot.ready!=floorf(float(lot.ready)):return false
	if not Barriers.valid_profile(value.get("sealing_profile",{"heat":1.0,"pressure":1.0})):return false
	var trials:Variant=value.get("trials",{})
	if not trials is Dictionary or trials.size()>CREATION_MODES.size():return false
	for kind:Variant in trials:
		if kind not in CREATION_MODES or kind in ["leather","rain_shell"] or not trials[kind] is Dictionary:return false
		var trial:Dictionary=trials[kind]
		if not trial.has_all(["started","last_day","cycles","before","condition","sample"]):return false
		for key:String in ["started","last_day","cycles","before","condition","sample"]:
			if not number(trial[key]) or float(trial[key])<0:return false
		if trial.started+trial.cycles-1>trial.last_day or trial.last_day>1e12 or trial.started!=floorf(float(trial.started)) or trial.last_day!=floorf(float(trial.last_day)):return false
		if trial.cycles<1 or trial.cycles>5 or trial.cycles!=floorf(float(trial.cycles)) or trial.before>1 or trial.condition>trial.before or trial.sample!=.25:return false
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
