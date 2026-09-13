extends RefCounted
## Optional staple handling. All stocks use the same ration-equivalent energy
## unit as FoodSystem; separation and germination can lose food, never create it.
## This is an aggregate cereal share of cultivated staples, not a crop species map.
const LIMIT := 100
const STOCKS := ["grain","clean","tested","dry","flour","fine","bran","malt"]
const SPOILAGE := {"grain":.004,"clean":.002,"tested":.002,"dry":.0008,"flour":.003,"fine":.003,"bran":.004,"malt":.0015}
const METHODS := {
	"threshing_frames":{"name":"Threshing Frames","requires":["seed_selection","joinery"],"rate":30.0,"cost":{"Timber":4.0,"Stone":1.0,"Fiber Plants":1.0},"inputs":{},"power":0.0,"observation":"Frames and repeated impacts separate grain from harvested heads. Handling takes time and loses a small share of recoverable food."},
	"winnowing_practice":{"name":"Winnowing Practice","requires":["threshing_frames","seasonal_patterns","basketry"],"rate":40.0,"cost":{"Fiber Plants":2.0,"Timber":1.0},"inputs":{},"power":0.0,"observation":"Repeated tossing and sorting separate lighter residues from grain. Containers and handlers are required; discarded material is not extra food."},
	"grain_moisture_testing":{"name":"Grain-Moisture Testing","requires":["measurement_uncertainty","precision_thermometry","winnowing_practice"],"rate":60.0,"cost":{"Laboratory Glassware":1.0,"Timber":2.0,"Stone":1.0},"inputs":{"Timber":.005},"power":0.0,"observation":"Representative samples are compared before and after controlled drying. The sampled batch becomes eligible for monitored forced-air treatment."},
	"forced_air_grain_drying":{"name":"Forced-Air Grain Drying","requires":["grain_moisture_testing","electric_motors"],"rate":40.0,"cost":{"Electric Motors":1.0,"Insulated Cable":1.0,"Timber":4.0},"inputs":{},"power":.025,"observation":"Powered airflow dries an assessed grain batch. Fans, handlers and a finite electrical supply limit the volume treated."},
	"roller_grain_milling":{"name":"Roller Grain Milling","requires":["grain_milling","precision_machinery"],"rate":35.0,"cost":{"Precision Machine Tool Sets":1.0,"Electric Motors":1.0,"Steel":2.0},"inputs":{},"power":.04,"observation":"Driven rollers reduce grain through measured gaps. Their throughput requires deployed machinery, handlers and electricity."},
	"flour_sifting":{"name":"Flour Sifting","requires":["grain_milling","plain_weaving"],"rate":30.0,"cost":{"Woven Cloth":1.0,"Timber":2.0},"inputs":{},"power":0.0,"observation":"Meshes separate fine flour from edible bran. Both fractions remain in the food ledger; a small handling loss is recorded."},
	"grain_malting":{"name":"Grain Malting","requires":["germination_trials","food_drying"],"rate":15.0,"cost":{"Clay":3.0,"Timber":2.0},"inputs":{"Freshwater":.12,"Timber":.02},"power":0.0,"observation":"A portion of suitable grain is steeped, germinated and dried over four days. It is unavailable while in process and returns with less stored food energy."}
}
const HAND_MILL := {"name":"Rotary grain mill","requires":["grain_milling"],"rate":10.0,"cost":{"Stone":5.0,"Timber":2.0},"inputs":{},"power":0.0}
static func empty_state()->Dictionary:
	var stocks:Dictionary={}
	for key:String in STOCKS:stocks[key]=0.0
	return {"stocks":stocks,"tools":{},"batches":[],"last_day":-1,"report":{}}
static func data()->Dictionary:return WorldSimulation.state.grain_processing
static func entries()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for id:String in METHODS:
		var m:Dictionary=METHODS[id]
		result.append({"id":id,"name":m.name,"direction":"Sustenance","day":0,"chance":.002,"requires":m.requires.duplicate(),"requires_all":m.requires.duplicate(),"requires_any":[],"learning_routes":[{"id":"local","label":m.name,"requires_all":[]}],"signals":["food","crafting","storage"],"observation":m.observation,"effects":{},"grain_method":id,"production_contract":"Operates only with paid handling equipment, adopted knowledge and shared Logistics time. Grain and its fractions remain finite ration-equivalent stocks. Powered steps consume electricity; germination has a four-day delay and loses energy. Processed food contributes only when actually eaten."})
	return result
static func definition(id:String)->Dictionary:return HAND_MILL if id=="grain_milling" else METHODS.get(id,{})
static func quote(id:String)->Dictionary:
	var spec:=definition(id)
	if spec.is_empty():return {"error":"Unknown staple handling equipment."}
	if WorldSimulation.state.convoy_traveling or not WorldSimulation.state.settlement_site_committed:return {"error":"Settle before installing staple equipment."}
	for gate:String in spec.requires:
		if gate not in WorldSimulation.state.known_discoveries:return {"error":"The necessary practical foundations are not established."}
	if id not in WorldSimulation.state.known_discoveries or WorldSimulation.discovery.adoption(id)<.1:return {"error":"Adopt this method before installing equipment."}
	if int(data().tools.get(id,0))>=LIMIT:return {"error":"This settlement already has the maximum equipment count."}
	for item:String in spec.cost:
		if float(WorldSimulation.state.resource_stockpiles.get(item,0))<float(spec.cost[item]):return {"error":"Installation needs %s %s." % [spec.cost[item],item]}
	var costs:Array[String]=[]
	for item:String in spec.cost:costs.append("%.1f %s" % [float(spec.cost[item]),item])
	return {"ok":true,"cost":spec.cost.duplicate(),"message":"Install %s for %s. Operation also needs Logistics workers and continuing supplies." % [spec.name,", ".join(costs)]}
static func install(id:String)->Dictionary:
	var terms:=quote(id)
	if terms.has("error"):return terms
	for item:String in terms.cost:WorldSimulation.state.resource_stockpiles[item]=float(WorldSimulation.state.resource_stockpiles.get(item,0))-float(terms.cost[item])
	data().tools[id]=int(data().tools.get(id,0))+1
	return {"ok":true,"message":"Installed "+String(definition(id).name)}
static func available_total()->float:
	var result:=0.0
	for amount:float in data().stocks.values():result+=amount
	return result
static func in_process()->float:
	var result:=0.0
	for batch:Dictionary in data().batches:result+=float(batch.amount)
	return result
static func capacity(id:String,workers:float)->float:
	if int(data().tools.get(id,0))<=0 or id not in WorldSimulation.state.known_discoveries:return 0.0
	var spec:=definition(id)
	return minf(maxf(0,workers),float(data().tools[id]))*float(spec.rate)*clampf(WorldSimulation.discovery.adoption(id),0,1)
static func supplied_amount(id:String,requested:float,workers:float,usage:Dictionary={})->float:
	var amount:=minf(minf(maxf(0,requested),capacity(id,workers)),maxf(0,capacity(id,10000)-float(usage.get(id,0))));var spec:=definition(id)
	for item:String in spec.inputs:
		amount=minf(amount,maxf(0,float(WorldSimulation.state.resource_stockpiles.get(item,0)))/float(spec.inputs[item]))
	if float(spec.power)>0:amount=minf(amount,preload("res://scripts/technology_operations.gd").service("electricity")/float(spec.power))
	return maxf(0,amount)
static func charge(id:String,amount:float,report:Dictionary)->float:
	if amount<=0:return 0.0
	var spec:=definition(id)
	for item:String in spec.inputs:
		var used:=amount*float(spec.inputs[item])
		WorldSimulation.state.resource_stockpiles[item]=maxf(0,float(WorldSimulation.state.resource_stockpiles.get(item,0))-used)
		report.inputs[item]=float(report.inputs.get(item,0))+used
	if float(spec.power)>0:report.electricity+=preload("res://scripts/technology_operations.gd").consume_electricity(amount*float(spec.power))
	var work:=amount/maxf(.000001,float(spec.rate)*WorldSimulation.discovery.adoption(id))
	report.workers+=work;report.methods[id]=float(report.methods.get(id,0))+amount
	return work
static func transform(id:String,source:String,outputs:Dictionary,workers:float,report:Dictionary)->float:
	var amount:=supplied_amount(id,float(data().stocks[source]),workers,report.methods)
	if amount<=0:return 0.0
	data().stocks[source]-=amount
	var returned:=0.0
	for key:String in outputs:
		var output:=amount*float(outputs[key]);data().stocks[key]+=output;returned+=output
	report.loss+=maxf(0,amount-returned)
	return charge(id,amount,report)
static func advance(cultivated:float,logistics:float,demand:float,traveling:bool)->Dictionary:
	var ledger:=data();var day:=int(WorldSimulation.state.elapsed_days)
	if int(ledger.last_day)==day:return {"workers":0.0,"routed":0.0,"loss":0.0,"inputs":{},"methods":{},"electricity":0.0,"released":0.0,"committed":0.0}
	ledger.last_day=day
	var report:={"workers":0.0,"routed":0.0,"loss":0.0,"inputs":{},"methods":{},"electricity":0.0,"released":0.0,"committed":0.0}
	var workers:=maxf(0,logistics)*.20
	if not traveling and WorldSimulation.state.settlement_site_committed:
		for index in range(ledger.batches.size()-1,-1,-1):
			var batch:Dictionary=ledger.batches[index]
			if day<int(batch.ready_day):continue
			var finished:=minf(float(batch.amount),workers*float(METHODS.grain_malting.rate)*5.0)
			var work:=finished/float(METHODS.grain_malting.rate)*.2
			workers-=work;report.workers+=work
			var output:=finished*.88
			ledger.stocks.malt+=output;report.released+=output;report.loss+=finished-output
			batch.amount-=finished
			if batch.amount<.00000001:ledger.batches.remove_at(index)
	if traveling or not WorldSimulation.state.settlement_site_committed:ledger.report=report;return report
	# The same steward rule serves player and rival settlements. One affordable
	# setup at a time; sufficient food must remain and its input must exist.
	if WorldSimulation.food._stock_total()>maxf(1,demand)*7:
		var needed:={"threshing_frames":cultivated>0,"winnowing_practice":float(ledger.stocks.grain)>0,"grain_moisture_testing":float(ledger.stocks.clean)>0,"forced_air_grain_drying":float(ledger.stocks.tested)>0,"grain_milling":float(ledger.stocks.clean)+float(ledger.stocks.dry)>0,"roller_grain_milling":float(ledger.stocks.clean)+float(ledger.stocks.dry)>0,"flour_sifting":float(ledger.stocks.flour)>0,"grain_malting":float(ledger.stocks.clean)>0}
		for id:String in needed:
			if needed[id] and int(ledger.tools.get(id,0))==0 and not quote(id).has("error"):
				install(id);break
	# Finish downstream work before creating more partly processed stocks.
	workers-=transform("flour_sifting","flour",{"fine":.75,"bran":.23},workers,report)
	workers-=transform("forced_air_grain_drying","tested",{"dry":.995},workers,report)
	for source:String in ["dry","tested","clean"]:
		# Both tools share their own daily quota across every feedstock. A paid
		# handmill can handle the same stock after powered capacity is exhausted.
		for mill:String in ["roller_grain_milling","grain_milling"]:
			workers-=transform(mill,source,{"flour":.97},workers,report)
	# Germination may tie up only surplus; never reserve the last week's rations.
	var surplus:=maxf(0,WorldSimulation.food._stock_total()-maxf(0,demand)*7)
	var malt:=supplied_amount("grain_malting",minf(float(ledger.stocks.clean),surplus*.1),workers,report.methods)
	if malt>0 and ledger.batches.size()<32:
		ledger.stocks.clean-=malt;ledger.batches.append({"amount":malt,"ready_day":day+4});report.committed=malt
		workers-=charge("grain_malting",malt,report)
	workers-=transform("grain_moisture_testing","clean",{"tested":.999},workers,report)
	workers-=transform("winnowing_practice","grain",{"clean":.98},workers,report)
	# Reclassify only a cereal share of today's cultivation, never old mixed
	# stores, wild dried plants, or incoming trade/occupation rations.
	var routed:=supplied_amount("threshing_frames",maxf(0,cultivated)*.25,workers,report.methods)
	if routed>0:
		ledger.stocks.grain+=routed*.98;report.routed=routed;report.loss+=routed*.02
		charge("threshing_frames",routed,report)
	ledger.report=report
	return report
static func issue(requested:float,processed_only:bool=false)->Dictionary:
	var result:={"amount":0.0,"processed":0.0}
	for key:String in ["fine","flour","bran","malt","grain","clean","tested","dry"]:
		if processed_only and key not in ["fine","flour","bran","malt"]:continue
		var used:=minf(maxf(0,requested-float(result.amount)),float(data().stocks[key]))
		data().stocks[key]-=used;result.amount+=used
		if key in ["fine","flour","malt"]:result.processed+=used
	return result
static func discard(requested:float)->float:
	var removed:=float(issue(requested).amount)
	for index in range(data().batches.size()-1,-1,-1):
		var batch:Dictionary=data().batches[index]
		var amount:=minf(maxf(0,requested-removed),float(batch.amount))
		batch.amount-=amount;removed+=amount
		if batch.amount<.00000001:data().batches.remove_at(index)
	return removed
static func spoil(traveling:bool,multiplier:float)->float:
	var result:=0.0
	for key:String in STOCKS:
		var loss:=float(data().stocks[key])*float(SPOILAGE[key])*multiplier*(1.28 if traveling else 1.0)
		data().stocks[key]-=loss;result+=loss
	for batch:Dictionary in data().batches:
		var loss:=float(batch.amount)*.003*multiplier
		batch.amount-=loss;result+=loss
	return result
static func power_demand()->float:
	if WorldSimulation.state.convoy_traveling or not WorldSimulation.state.settlement_site_committed or not WorldSimulation.state.resource_settlement_id.is_empty():return 0.0
	var ledger:=data()
	var tested:=float(ledger.stocks.tested);var other:=float(ledger.stocks.dry)+float(ledger.stocks.clean)
	if tested+other<=0:return 0.0
	var logistics:=WorldSimulation.state.effective_workers("Logistics")
	var meals:Dictionary=load("res://scripts/food_preparation.gd").plan(logistics,float(WorldSimulation.food._calculate_demand(false).total),false)
	var workers:=maxf(0,logistics-float(meals.workers))*.20
	for batch:Dictionary in ledger.batches:
		if int(batch.ready_day)<=int(WorldSimulation.state.elapsed_days):workers=maxf(0,workers-float(batch.amount)/float(METHODS.grain_malting.rate)*.2)
	var sifted:=minf(float(ledger.stocks.flour),capacity("flour_sifting",workers))
	if sifted>0:workers-=sifted/(float(METHODS.flour_sifting.rate)*WorldSimulation.discovery.adoption("flour_sifting"))
	var dry:=minf(tested,capacity("forced_air_grain_drying",workers))
	var demand:=dry*float(METHODS.forced_air_grain_drying.power)
	if dry>0:workers-=dry/(float(METHODS.forced_air_grain_drying.rate)*WorldSimulation.discovery.adoption("forced_air_grain_drying"))
	var milled:=minf(other+tested-dry+dry*.995,capacity("roller_grain_milling",workers))
	return demand+milled*float(METHODS.roller_grain_milling.power)

static func valid(value:Variant)->bool:
	if not value is Dictionary or not value.has_all(["stocks","tools","batches","last_day","report"]):return false
	if not value.stocks is Dictionary or value.stocks.size()!=STOCKS.size() or not value.tools is Dictionary or value.tools.size()>METHODS.size()+1:return false
	for key:String in STOCKS:
		if not number(value.stocks.get(key)) or value.stocks[key]<0 or value.stocks[key]>1e12:return false
	for key:Variant in value.tools:
		if not key is String or definition(key).is_empty() or not number(value.tools[key]) or value.tools[key]!=floorf(float(value.tools[key])) or value.tools[key]<0 or value.tools[key]>LIMIT:return false
	if not number(value.last_day) or value.last_day< -1 or value.last_day!=floorf(float(value.last_day)) or not value.report is Dictionary:return false
	if value.report.size()>10:return false
	for key:Variant in value.report:
		if key in ["inputs","methods"]:
			if not value.report[key] is Dictionary or value.report[key].size()>16:return false
			for item:Variant in value.report[key]:
				if not item is String or not number(value.report[key][item]) or value.report[key][item]<0 or value.report[key][item]>1e12:return false
		elif key not in ["workers","routed","loss","electricity","released","committed"] or not number(value.report[key]) or value.report[key]<0 or value.report[key]>1e12:return false
	if not value.batches is Array or value.batches.size()>32:return false
	for batch:Variant in value.batches:
		if not batch is Dictionary or not number(batch.get("amount")) or batch.amount<=0 or batch.amount>1e12 or not number(batch.get("ready_day")) or batch.ready_day<0 or batch.ready_day!=floorf(float(batch.ready_day)):return false
	return true
static func valid_settlements(records:Variant)->bool:
	if not records is Array:return false
	for record:Variant in records:
		if not record is Dictionary or not record.get("local_resources",{}) is Dictionary:return false
		if not valid(record.get("local_resources",{}).get("grain_processing",empty_state())):return false
	return true
static func number(value:Variant)->bool:return (value is int or value is float) and is_finite(float(value))
