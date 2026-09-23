extends RefCounted
## Installation bills, independent of the provider of finished pipe sections.
const Route=preload("res://scripts/water_conveyance_route.gd")
const Stock=preload("res://scripts/bill_stock.gd")
const MATERIALS={
	"ceramic":{"item":"Fired Clay Conduits","gate":"clay_pipe_socket_jointing","leakage":0.12,"decay":0.0006},
	"timber":{"item":"Wooden Conduits","gate":"joinery","leakage":0.18,"decay":0.0012}
}
## Sections, mortar, fit gauges, bedding and rod sets are paid as the raw
## materials and Civilian Goods of their former recipes; the names are units.
static var MORTAR:=Stock.unit("Building Mortar")
static var FIT_GAUGES:=Stock.unit("Conduit Fit Gauges")
static var BEDDING:=Stock.unit("Conduit Bedding")
static var RODDING:=Stock.unit("Conduit Rodding Sets")

## Raw materials and Civilian Goods for one conduit section or repair unit.
static func section_unit(material:String)->Dictionary:
	return Stock.unit(String(MATERIALS[material].item)) if MATERIALS.has(material) else {}

static func quote(route:Dictionary,material:String,known:Array,stock:Dictionary)->Dictionary:
	if not MATERIALS.has(material):return {"error":"Choose a supported conduit material."}
	var blocker:=Route.gravity_blocker(route)
	if not blocker.is_empty():return {"error":blocker}
	if "gravity_conduit_grade_control" not in known:return {"error":"Qualify the gravity alignment before installing a line."}
	var spec:Dictionary=MATERIALS[material]
	if spec.gate not in known:return {"error":"Local crews need the joining practice for these sections."}
	# Recompute length from validated survey evidence; a supplied quote cannot
	# obtain cheaper construction by changing a cached length field.
	var length:=0.0
	for index in route.samples.size()-1:
		var a:Vector3=route.samples[index];var b:Vector3=route.samples[index+1]
		length+=Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z))
	var units:=maxi(1,ceili(length*10.0))
	var bill:=Stock.scaled(section_unit(material),float(units))
	var leakage:=float(spec.leakage)
	var decay:=float(spec.decay)
	var work_required:=float(units)*4.0
	var applied:Array[String]=[String(spec.gate),"gravity_conduit_grade_control"]
	# Optional practices apply when their own materials are on hand, checked
	# separately as before; the final bill check covers the combined total.
	if material=="ceramic" and "lime_mortar" in known and Stock.affordable(stock,MORTAR)>=units*.1:
		Stock.add_scaled(bill,MORTAR,units*.1);leakage*=.8;applied.append("lime_mortar")
	else:bill["Clay"]=float(bill.get("Clay",0.0))+float(units)*0.2
	if "ceramic_pipe_fit_gauges" in known and material=="ceramic" and Stock.affordable(stock,FIT_GAUGES)>=.1:
		Stock.add_scaled(bill,FIT_GAUGES,.1);leakage*=.8;applied.append("ceramic_pipe_fit_gauges")
	if "rigid_pipe_bedding" in known and Stock.affordable(stock,BEDDING)>=units*.2:
		Stock.add_scaled(bill,BEDDING,units*.2);decay*=.7;applied.append("rigid_pipe_bedding")
	# Supported case: a rigid line on paid bedding, assessed during construction.
	# Extra crew work covers checking support and correcting bedding placement;
	# this does not certify arbitrary overburden, traffic loads, or pressure.
	if "buried_pipe_load_assessment" in known and "rigid_pipe_bedding" in applied:
		work_required+=float(units)
		applied.append("buried_pipe_load_assessment");decay*=.85
	for item:String in bill:
		if float(stock.get(item,0))<float(bill[item]):return {"error":"Installation needs %.2f %s." % [float(bill[item]),item],"cost":bill}
	return {"ok":true,"material":material,"cost":bill,"length_km":length,"work_required":work_required,"leakage":leakage,"decay":decay,"applied":applied,"route":route.duplicate(true)}

static func begin(terms:Dictionary,stock:Dictionary,day:int)->Dictionary:
	if not bool(terms.get("ok",false)):return {"error":"A feasible installation quote is required."}
	# The owner must call quote immediately before begin; recheck material stock
	# here so an intervening purchase cannot spend the same delivered sections.
	for item:String in terms.cost:
		if float(stock.get(item,0))<float(terms.cost[item]):return {"error":"The quoted materials are no longer available."}
	for item:String in terms.cost:stock[item]=float(stock.get(item,0))-float(terms.cost[item])
	return {"ok":true,"line":{"material":terms.material,"route":terms.route.duplicate(true),"supply_provenance":terms.cost.duplicate(true),"work_required":terms.work_required,"work_done":0.0,"status":"under_construction","condition":1.0,"obstruction":0.0,"leakage":terms.leakage,"decay":terms.decay,"applied":terms.applied.duplicate(),"started_day":day,"last_work_day":-1,"last_service_day":-1}}

static func advance_construction(line:Dictionary,available_work:float,day:int)->float:
	if String(line.get("status",""))!="under_construction" or int(line.get("last_work_day",-1))>=day:return 0.0
	line.last_work_day=day
	var used:=minf(maxf(0.0,available_work),maxf(0.0,float(line.work_required)-float(line.work_done)))
	line.work_done=float(line.work_done)+used
	if float(line.work_done)>=float(line.work_required):line.status="active"
	return used
