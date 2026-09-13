extends RefCounted
## Physical dock construction and finite repair access. The JointOperations
## owner must validate port ownership and provide that port's actual inventory.
const BILL={"Launch Cradles":4.0,"Timber":200.0,"Stone":200.0,"Rope Coils":8.0,"Rigging Blocks":8.0}
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
	return {"ok":true,"work":work,"hull_load":load,"cost":{"Timber":work*.2,"Rope Coils":work*.01}}

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
