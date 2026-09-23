extends RefCounted
const F=preload("res://scripts/rail_freight_fabric.gd")
const R=preload("res://scripts/rail_route_survey.gd")
const Stock=preload("res://scripts/bill_stock.gd")
static func number(v:Variant,low:float,high:float,whole:bool=false)->bool:
	return R.number(v) and float(v)>=low and float(v)<=high and (not whole or floorf(float(v))==float(v))
static func identity(v:Variant)->bool:return v is String and not v.is_empty() and v.length()<=160
static func valid(value:Variant)->bool:
	if not value is Dictionary or not value.get("lines") is Array or value.lines.size()>F.MAX_LINES:return false
	if not number(value.get("next_id"),1,1000000,true) or not number(value.get("last_day"),-1,100000000,true):return false
	var ids:Dictionary={};var pairs:Dictionary={}
	for line:Variant in value.lines:
		if not line is Dictionary or not number(line.get("id"),1,int(value.next_id)-1,true) or ids.has(int(line.id)):return false
		ids[int(line.id)]=true
		if not identity(line.get("source_id")) or not identity(line.get("destination_id")) or line.source_id==line.destination_id:return false
		var pair:Array=[line.source_id,line.destination_id];pair.sort()
		var key:=str(pair)
		if pairs.has(key):return false
		pairs[key]=true
		if not number(line.get("gauge_mm"),1,2000,true) or not F.GAUGES.has(int(line.gauge_mm)) or not number(line.get("wagons"),1,F.MAX_WAGONS,true):return false
		if not R.valid(line.get("route")):return false
		# Lines paid before Civilian Goods recorded the named-part bill.
		var paid:Variant=line.get("paid_materials")
		if not Stock.same(paid,F.installation_bill(line.route,int(line.gauge_mm),int(line.wagons))) and not Stock.same(paid,F.legacy_installation_bill(line.route,int(line.gauge_mm),int(line.wagons))):return false
		var required:=maxf(10,float(line.route.length_km)*F.CONSTRUCTION_WORK_PER_KM)
		if not number(line.get("work_required"),required,required) or not number(line.get("work_done"),0,required):return false
		for field:String in ["condition","wagon_condition"]:
			if not number(line.get(field),0,1):return false
		for field:String in ["started_day","last_work_day","last_service_day"]:
			if not number(line.get(field),0 if field=="started_day" else -1,100000000,true):return false
		if not line.get("blocker","") is String or String(line.get("blocker","")).length()>500:return false
		if not line.get("trip") is Dictionary:return false
		var trip:Dictionary=line.trip
		if trip.is_empty():continue
		if F.building(line) or not number(trip.get("shipment_id"),1,100000000,true) or trip.get("source_id") not in [line.source_id,line.destination_id]:return false
		if not number(trip.get("departure_day"),0,100000000,true) or not number(trip.get("return_day"),float(trip.departure_day)+2,100000010):return false
		var duration:=2.0*maxf(1,ceil(float(line.route.length_km)/F.HAUL_SPEED_KM_PER_DAY))
		if absf(float(trip.return_day)-float(trip.departure_day)-duration)>.00001:return false
		if not number(trip.get("quantity"),.000001,float(F.GAUGES[int(line.gauge_mm)].load)*int(line.wagons)):return false
		var crew:=2.0+int(line.wagons)+float(trip.quantity)*.005/duration
		if not number(trip.get("crew_workers"),crew-.00001,crew+.00001) or not number(trip.get("worker_days"),crew*duration-.00001,crew*duration+.00001):return false
	return true
static func valid_state(state:Dictionary)->bool:
	var value:Variant=state.get("rail_freight",F.empty_state())
	if not valid(value):return false
	var lines:Dictionary={}
	for line:Dictionary in value.lines:lines[int(line.id)]=line
	if not state.get("city_trade_shipments",[]) is Array:return false
	var cargo_ids:Dictionary={}
	for shipment:Variant in state.get("city_trade_shipments",[]):
		if not shipment is Dictionary:return false
		if shipment.get("transport_mode","")!="rail":continue
		if not number(shipment.get("rail_line_id"),1,999999,true) or not lines.has(int(shipment.rail_line_id)):return false
		var line:Dictionary=lines[int(shipment.rail_line_id)]
		var trip:Dictionary=line.trip
		if trip.is_empty() or shipment.get("id")!=trip.shipment_id or shipment.get("source_id")!=trip.source_id:return false
		if shipment.get("destination_id") not in [line.source_id,line.destination_id] or shipment.destination_id==shipment.source_id:return false
		if not number(shipment.get("quantity"),float(trip.quantity),float(trip.quantity)):return false
		if cargo_ids.has(int(trip.shipment_id)):return false
		cargo_ids[int(trip.shipment_id)]=true
		var travel:=maxf(1,ceil(float(line.route.length_km)/F.HAUL_SPEED_KM_PER_DAY))
		var departure:=float(trip.departure_day)
		if not number(shipment.get("departure_day"),departure,departure):return false
		if not number(shipment.get("travel_days"),travel,travel):return false
		if not number(shipment.get("arrival_day"),departure+travel,departure+travel):return false
		if not identity(shipment.get("resource")):return false
	return true
