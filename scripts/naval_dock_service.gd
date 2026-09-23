extends RefCounted
## Physical dock construction and finite repair access. The JointOperations
## owner must validate port ownership and provide that port's actual inventory.
const Stock=preload("res://scripts/bill_stock.gd")
## Former named-part bill; docks built before Civilian Goods recorded it.
const BILL_SOURCE={"Launch Cradles":4.0,"Timber":200.0,"Stone":200.0,"Rope Coils":8.0,"Rigging Blocks":8.0}
## Cradles, rope and blocks paid as raw materials and Civilian Goods.
static var BILL:=preload("res://scripts/goods_bills.gd").flatten(BILL_SOURCE).duplicate()
## One rope coil's worth of access upkeep.
static var ROPE:=Stock.unit("Rope Coils")
const REQUIRED_WORK:=240.0
const DAILY_ACCESS:=20.0
## Relative handling loads, not engineering displacement certificates.
const HULL_LOAD={"war_canoe":1.0,"galley":20.0}

static func begin(base:Dictionary,stock:Dictionary,known:Array,day:int)->Dictionary:
	if base.get("domain","")!="navy":return {"error":"A naval port is required."}
	if float(base.get("condition",0))<=.1 or float(base.get("construction_work",0))<float(base.get("required_work",INF)):
		return {"error":"Complete the port before building dock access."}
	if "dry_dock_services" not in known:return {"error":"Qualify supported out-of-water vessel access first."}
	if base.has("dock_service"):return {"error":"This port already has a dock project."}
	for item:String in BILL:
		if float(stock.get(item,0))<float(BILL[item]):return {"error":"Dock construction needs %.1f %s." % [float(BILL[item]),item]}
	for item:String in BILL:stock[item]=float(stock.get(item,0))-float(BILL[item])
	base.dock_service={"kind":"timber_lift_access","work_done":0.0,"work_required":REQUIRED_WORK,"started_day":day,"last_work_day":-1,"access_day":-1,"access_used":0.0,"paid_materials":BILL.duplicate()}
	return {"ok":true}

static func building(base:Dictionary)->bool:
	var dock:Dictionary=base.get("dock_service",{})
	return not dock.is_empty() and float(dock.work_done)<float(dock.work_required)

static func construct(base:Dictionary,available_work:float,day:int)->float:
	if not building(base):return 0.0
	var dock:Dictionary=base.dock_service
	if int(dock.last_work_day)>=day:return 0.0
	dock.last_work_day=day
	var used:=minf(maxf(0,available_work),float(dock.work_required)-float(dock.work_done))
	dock.work_done=float(dock.work_done)+used
	return used

static func handling_load(force:Dictionary)->float:
	if force.get("domain","")!="navy":return 0.0
	var total:=0.0
	for id:String in force.get("units",{}):
		if int(force.units[id])<=0:continue
		# Mixed formations containing an unsupported hull receive no assumption
		# of universal dock access. Larger facilities need separate qualification.
		if not HULL_LOAD.has(id):return 0.0
		total+=float(HULL_LOAD[id])*int(force.units[id])
	return total

static func remaining_access(base:Dictionary,day:int)->float:
	var dock:Dictionary=base.get("dock_service",{})
	if dock.is_empty() or building(base) or float(base.get("condition",0))<=.1:return 0.0
	if day<int(dock.access_day):return 0.0
	return maxf(0,DAILY_ACCESS-(float(dock.access_used) if int(dock.access_day)==day else 0.0))

static func access_quote(base:Dictionary,force:Dictionary,day:int,requested:float)->Dictionary:
	var load:=handling_load(force)
	if load<=0:return {"error":"Installed lift access does not support this formation's hulls."}
	var work:=minf(maxf(0,requested),remaining_access(base,day))
	if work<=0:return {"error":"No completed dock access remains today."}
	var cost:=Stock.scaled(ROPE,work*.01)
	cost["Timber"]=float(cost.get("Timber",0.0))+work*.2
	return {"ok":true,"work":work,"hull_load":load,"cost":cost}

static func pay_access(base:Dictionary,force:Dictionary,stock:Dictionary,day:int,requested:float)->Dictionary:
	# Always quote again against current usage; no caller can reuse a stale bill.
	var quote:=access_quote(base,force,day,requested)
	if quote.has("error"):return quote
	for item:String in quote.cost:
		if float(stock.get(item,0))<float(quote.cost[item]):return {"error":"Dock access needs maintained "+item+" supplies."}
	for item:String in quote.cost:stock[item]=float(stock.get(item,0))-float(quote.cost[item])
	var dock:Dictionary=base.dock_service
	if int(dock.access_day)!=day:dock.access_day=day;dock.access_used=0.0
	dock.access_used=float(dock.access_used)+float(quote.work)
	return quote

static func repair_plan(base:Dictionary,force:Dictionary,day:int,crew_work:float,afloat_rate:float,survey_known:bool)->Dictionary:
	if int(force.get("dock_service_day",-1))>=day:return {}
	var load:=handling_load(force)
	if load<=0:return {}
	var available:=minf(load,minf(maxf(0,crew_work),remaining_access(base,day)))
	var observation:Dictionary=force.get("hull_survey",{})
	var fresh:=not observation.is_empty() and day-int(observation.day)<30 and absf(float(observation.condition)-float(force.condition))<=.1
	var inspection:=load*.1 if survey_known and not fresh and available>=load*.1 else 0.0
	var multiplier:=.02 if fresh or inspection>0 else .01
	var extra:=minf(maxf(0,1.0-float(force.condition)-afloat_rate),multiplier*maxf(0,available-inspection)/load)
	var work:=inspection+extra/multiplier*load
	if work<=0:return {}
	var result:=access_quote(base,force,day,work)
	if result.has("error"):return {}
	result.extra_rate=extra;result.inspection_work=inspection
	return result

static func commit_repair_access(base:Dictionary,force:Dictionary,plan:Dictionary,day:int)->void:
	# Owner calls only after checking and paying the combined repair/access bill.
	var dock:Dictionary=base.dock_service
	if int(dock.access_day)!=day:dock.access_day=day;dock.access_used=0.0
	dock.access_used=float(dock.access_used)+float(plan.work)
	force.dock_service_day=day
	if float(plan.inspection_work)>0:
		force.hull_survey={"day":day,"condition":float(force.condition),"base_id":int(base.id),"work":float(plan.inspection_work)}

static func number(value:Variant,minimum:float,maximum:float,whole:bool=false)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=minimum and float(value)<=maximum and (not whole or float(value)==floorf(float(value)))

static func valid_dock(value:Variant)->bool:
	if not value is Dictionary:return false
	if value.get("kind","")!="timber_lift_access":return false
	if not number(value.get("work_required"),.001,10000) or not number(value.get("work_done"),0,float(value.work_required)):return false
	for key:String in ["started_day","last_work_day","access_day"]:
		if not number(value.get(key),0 if key=="started_day" else -1,100000000,true):return false
	if not number(value.get("access_used"),0,DAILY_ACCESS):return false
	var paid:Variant=value.get("paid_materials")
	if not paid is Dictionary:return false
	# Accept the flattened bill and the named-part bill of older docks.
	for bill:Dictionary in [BILL,BILL_SOURCE]:
		if paid.size()!=bill.size():continue
		var matched:=true
		for item:String in bill:
			if not number(paid.get(item),.001,100000):matched=false;break
		if matched:return true
	return false

static func valid_force_fields(force:Dictionary)->bool:
	if force.has("dock_service_day") and not number(force.dock_service_day,0,100000000,true):return false
	if not force.has("hull_survey"):return true
	var survey:Variant=force.hull_survey
	if not survey is Dictionary:return false
	return number(survey.get("day"),0,100000000,true) and number(survey.get("base_id"),1,100000000,true) and number(survey.get("condition"),0,1) and number(survey.get("work"),.000001,DAILY_ACCESS)
