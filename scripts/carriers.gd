extends RefCounted
## Who carries the fighters' supply, and how much of it they can move
## (docs/MILITARY_SYSTEM_V2.md §3 and critic round 1).
##
## One load is one man's food for a day (about 1.5 kg). The Logistics workers
## are the drivers and porters: each drives a lorry or a cart if we have one,
## otherwise carries on his back.
##   porter  16 loads (about 25 kg)
##   cart    250 loads (an ox cart, about 375 kg); 700 once horse freight
##           wagons are adopted (horse_freight_wagons)
##   lorry   2,000 loads (about 3 t); 40% more with driverless freight
## Moving a band's loads for a day over a line of d haul days ties up
## carriers for the round trip, 2d days (at least a day). Push twice as far
## and it takes twice the carts. Railway mobilization moves the long leg by
## train: the carriers' round trip shrinks by up to 60%.
## The day's transport share (military_campaign._field_transport_delivery_ratio)
## is what the carriers can move against what the bands away ask, times the
## war leader's logistics and the people's supply practice.

const Supply:=preload("res://scripts/supply_state.gd")
const Sustainment:=preload("res://scripts/field_sustainment.gd")

const PORTER_LOAD:=16.0
const CART_LOAD:=250.0
const WAGON_LOAD:=700.0
const LORRY_LOAD:=2000.0
const DRIVERLESS_BONUS:=0.4
const RATION:=1.12
const MIN_ROUND_TRIP:=1.0
const RAIL_SHARE:=0.6
## A garrison's town feeds most of it; carriers bring this share by default.
const GARRISON_CARRIED:=0.3
const LORRY_STOCK:="Supply Lorries"
const CART_STOCK:="Transport Carts"

## The fleet: drivers, what each drives, and the loads they move per trip.
static func fleet(state:Variant,adoption:Callable)->Dictionary:
	var drivers:=0
	var lorries_held:=0
	var carts_held:=0
	if state!=null:
		drivers=maxi(0,int((state.population_allocations as Dictionary).get("Logistics",0)))
		lorries_held=maxi(0,int(float((state.resource_stockpiles as Dictionary).get(LORRY_STOCK,0.0))))
		carts_held=maxi(0,int(float((state.resource_stockpiles as Dictionary).get(CART_STOCK,0.0))))
	var lorries:=mini(lorries_held,drivers)
	var carts:=mini(carts_held,drivers-lorries)
	var porters:=drivers-lorries-carts
	var cart_load:=lerpf(CART_LOAD,WAGON_LOAD,clampf(float(adoption.call("horse_freight_wagons")),0.0,1.0))
	var lorry_load:=LORRY_LOAD*(1.0+DRIVERLESS_BONUS*clampf(float(adoption.call("driverless_highway_freight")),0.0,1.0))
	return {"drivers":drivers,"lorries":lorries,"lorries_held":lorries_held,"carts":carts,"carts_held":carts_held,"porters":porters,
		"cart_load":cart_load,"lorry_load":lorry_load,"loads":float(lorries)*lorry_load+float(carts)*cart_load+float(porters)*PORTER_LOAD}

## Loads a day a force asks of the carriers: its men's food and its kits'
## stores (equipment_ledger supply). A garrison asks only what its town does
## not give.
static func daily_loads(force:Dictionary)->float:
	var loads:=float(maxi(0,int(force.get("troops",0))))*RATION+float(Sustainment.stores_demand(force).loads)
	if force.has("region_id") and not force.has("army_id"):
		var required:=float(force.get("provisions_required_today",0.0))
		var local:=float(force.get("provisions_local_today",0.0))
		var carried:=clampf(1.0-local/required,0.0,1.0) if required>0.0 else GARRISON_CARRIED
		loads*=carried
	return loads

## Days the carriers spend going out and back for one day's loads.
static func round_trip(days:float,rail:float)->float:
	if not is_finite(days): return INF
	return maxf(MIN_ROUND_TRIP,2.0*maxf(0.0,days))*(1.0-RAIL_SHARE*clampf(rail,0.0,1.0))

## The carriers' work: every band away and every garrison, in load-days.
## {demand, forces:[{key, loads, days, load_days}]}
static func demand(mc:Object,rail:float)->Dictionary:
	var total:=0.0
	var rows:=[]
	for force:Dictionary in mc.field_armies:
		if int(force.get("troops",0))<=0 or mc.at_home_point(force): continue
		if bool(force.get("general_managed",false)) and WorldSimulation.campaign!=null and WorldSimulation.campaign.active: continue
		var days:=float(Supply.haul_days_for(force))
		var loads:=daily_loads(force)
		var load_days:=loads*round_trip(days,rail) if is_finite(days) else 0.0
		total+=load_days
		rows.append({"key":"army:%d" % int(force.get("army_id",0)),"loads":loads,"days":days,"load_days":load_days})
	for force:Dictionary in mc.occupation_forces:
		if int(force.get("troops",0))<=0: continue
		var days:=float(Supply.haul_days_for(force))
		var loads:=daily_loads(force)
		var load_days:=loads*round_trip(days,rail) if is_finite(days) else 0.0
		total+=load_days
		rows.append({"key":"held:%s" % String(force.get("region_id","")),"loads":loads,"days":days,"load_days":load_days})
	return {"demand":total,"forces":rows}

## Share of the war leader's logistics and the people's supply practice.
static func efficiency(logistics:float,practice:float)->float:
	return 0.85+0.30*clampf(logistics,0.0,1.0)+0.15*clampf(practice,0.0,1.0)

## The day's transport share and what it came from.
static func reading(mc:Object)->Dictionary:
	var adoption:=func(id:String)->float: return float(mc._adoption(id))
	var state:Variant=WorldSimulation.state
	var have:=fleet(state,adoption)
	var rail:=float(adoption.call("railway_mobilization"))
	var need:=demand(mc,rail)
	var logistics:=float((mc.home_army.get("commander",{}) as Dictionary).get("logistics",0.4)) if mc.home_army is Dictionary else 0.4
	var eff:=efficiency(logistics,float(adoption.call("supply_groups")))
	var moved:=float(have.loads)*eff
	var ratio:=1.0 if float(need.demand)<=0.0 else clampf(moved/float(need.demand),0.0,1.0)
	return {"ratio":ratio,"moved":moved,"demand":float(need.demand),"efficiency":eff,"rail":rail,"fleet":have,"forces":need.forces}

## Carts (or lorries) the carriers still lack to move every load, never more
## than there are drivers for: the staff's building target.
static func wanted(mc:Object,item:String)->int:
	return wanted_from(mc.carrier_reading() if mc.has_method("carrier_reading") else reading(mc),item)

static func wanted_from(r:Dictionary,item:String)->int:
	var short:=maxf(0.0,float(r.demand)-float(r.moved))
	if short<=0.0: return 0
	var fl:Dictionary=r.fleet
	var per:=float(fl.lorry_load) if item=="supply_lorry" else float(fl.cart_load)
	var gain:=(per-PORTER_LOAD)*float(r.efficiency)
	if gain<=0.0: return 0
	return mini(int(fl.porters),ceili(short/gain))
