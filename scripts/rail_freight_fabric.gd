extends RefCounted
## Paid infrastructure and rolling-stock state. The owner provides the actual
## local stock and labor; this helper has no authority over cities or workers.
const Route=preload("res://scripts/rail_route_survey.gd")
const MAX_LINES:=16
const MAX_WAGONS:=8
const GAUGES:={900:{"wagon":"900 mm Rail Wagons","load":160.0},1435:{"wagon":"1435 mm Rail Wagons","load":240.0}}
const CONSTRUCTION_WORK_PER_KM:=20.0
const HAUL_SPEED_KM_PER_DAY:=24.0

static func empty_state()->Dictionary:
	return {"lines":[],"next_id":1,"last_day":-1}

static func installation_bill(route:Dictionary,gauge:int,wagons:int)->Dictionary:
	if not Route.valid(route) or not GAUGES.has(gauge) or wagons<1 or wagons>MAX_WAGONS:return {}
	var distance:=float(route.length_km)
	return {"Timber Rail Panels":ceil(distance*8.0),"Rail Gauge Templates":1.0,"Track Ballast":ceil(distance*40.0),"Timber":ceil(distance*12.0),String(GAUGES[gauge].wagon):float(wagons),"Rail Brake Sets":float(wagons)}

static func can_pay(stock:Dictionary,bill:Dictionary)->bool:
	for item:String in bill:
		if not Route.number(stock.get(item,0)) or float(stock.get(item,0))<float(bill[item]):return false
	return true

static func pay(stock:Dictionary,bill:Dictionary)->void:
	for item:String in bill:stock[item]=float(stock.get(item,0))-float(bill[item])

static func begin(data:Dictionary,source:String,destination:String,route:Dictionary,gauge:int,wagons:int,stock:Dictionary,day:int)->Dictionary:
	if source.is_empty() or destination.is_empty() or source==destination:return {"error":"Two distinct owned settlements are required."}
	if data.lines.size()>=MAX_LINES:return {"error":"The rail construction register is full."}
	for line:Dictionary in data.lines:
		if source in [line.source_id,line.destination_id] and destination in [line.source_id,line.destination_id]:return {"error":"These settlements already have a rail project."}
	var bill:=installation_bill(route,gauge,wagons)
	if bill.is_empty():return {"error":"The rail route, gauge or wagon count is unsupported."}
	if not can_pay(stock,bill):return {"error":"Supply the entire rail, wagon and brake bill locally before installation."}
	pay(stock,bill)
	var line:={"id":int(data.next_id),"source_id":source,"destination_id":destination,"gauge_mm":gauge,"wagons":wagons,"route":route.duplicate(true),"paid_materials":bill.duplicate(),"work_done":0.0,"work_required":maxf(10.0,float(route.length_km)*CONSTRUCTION_WORK_PER_KM),"last_work_day":-1,"started_day":day,"condition":1.0,"wagon_condition":1.0,"trip":{},"last_service_day":-1,"blocker":"Construction is not finished."}
	data.next_id=int(data.next_id)+1;data.lines.append(line)
	return {"ok":true,"line_id":line.id}

static func building(line:Dictionary)->bool:
	return float(line.work_done)<float(line.work_required)

static func construct(line:Dictionary,work:float,day:int)->float:
	if not building(line) or int(line.last_work_day)>=day or not line.trip.is_empty():return 0.0
	var used:=minf(maxf(0,work),float(line.work_required)-float(line.work_done))
	line.work_done=float(line.work_done)+used;line.last_work_day=day
	if not building(line):line.blocker=""
	return used

static func trip_quote(line:Dictionary,requested:float,available_workers:float,day:int)->Dictionary:
	if building(line) or not line.trip.is_empty() or int(line.last_service_day)>=day:return {}
	if float(line.condition)<.6 or float(line.wagon_condition)<.6:return {}
	var travel_days:=maxf(1.0,ceil(float(line.route.length_km)/HAUL_SPEED_KM_PER_DAY))
	var return_days:=travel_days*2.0
	var crew:=2.0+float(line.wagons)
	var available:=minf(maxf(0,requested),float(GAUGES[int(line.gauge_mm)].load)*int(line.wagons)*minf(float(line.condition),float(line.wagon_condition)))
	available=minf(available,maxf(0,available_workers-crew)*return_days/.005)
	if available<=.01:return {}
	var distance:=float(line.route.length_km)
	return {"ok":true,"quantity":available,"travel_days":travel_days,"return_day":day+return_days,"crew_workers":crew+available*.005/return_days,"worker_days":crew*return_days+available*.005,"cost":{"Timber":distance*.1,"Wrought Iron":distance*.01}}

static func commit_trip(line:Dictionary,plan:Dictionary,shipment_id:int,source:String,day:int,stock:Dictionary)->bool:
	# Recheck occupancy and payment at commitment. Cargo is issued separately by
	# the owning shipment transaction after reserving these same-stock charges.
	if not line.trip.is_empty() or building(line) or int(line.last_service_day)>=day or not can_pay(stock,plan.cost):return false
	pay(stock,plan.cost)
	line.trip={"shipment_id":shipment_id,"source_id":source,"departure_day":day,"return_day":float(plan.return_day),"crew_workers":float(plan.crew_workers),"worker_days":float(plan.worker_days),"quantity":float(plan.quantity)}
	line.condition=maxf(0,float(line.condition)-float(plan.quantity)*.000002)
	line.wagon_condition=maxf(0,float(line.wagon_condition)-float(line.route.length_km)*.0002)
	return true

static func maintain(line:Dictionary,stock:Dictionary,work:float,day:int)->float:
	if building(line) or not line.trip.is_empty() or int(line.last_service_day)>=day or work<=0:return 0.0
	var need:=maxf(1.0-float(line.condition),1.0-float(line.wagon_condition))
	var restored:=minf(need,work*.01)
	if restored<=0:return 0.0
	var bill:={"Timber Rail Panels":restored*maxf(1,float(line.route.length_km)),"Rail Brake Sets":restored*float(line.wagons),"Timber":restored*2.0}
	if not can_pay(stock,bill):return 0.0
	pay(stock,bill)
	line.condition=minf(1,float(line.condition)+restored);line.wagon_condition=minf(1,float(line.wagon_condition)+restored)
	line.last_service_day=day
	return restored/.01
