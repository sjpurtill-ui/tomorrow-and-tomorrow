extends RefCounted
## Who carries the fighters' supply, and how much of it they can bring a day
## (docs/MILITARY_SYSTEM_V2.md §3, critic rounds 1 and 3).
##
## One load is one man's food for a day (about 1.5 kg). The Logistics workers
## are the drivers and porters: each drives a lorry or a cart if we have one,
## otherwise carries on his back.
##   porter  16 loads (about 25 kg), 20 km a day on open level ground
##   cart    250 loads (an ox cart, about 375 kg), 20 km a day; 700 once horse
##           freight wagons are adopted (horse_freight_wagons)
##   lorry   2,000 loads (about 3 t), 150 km a day; 40% more with driverless
##           freight
## Each kind goes out and back at its own pace: a band far off ties a porter
## up seven times as long as a lorry. Railway mobilization carries the long
## leg by train (up to 45% off every trip).
## A day's carrying is shared bread first: every band's and garrison's bread,
## then what is left for their kits' stores (fodder, fuel, rounds, spares).
## Tanks short of fuel never starve the infantry beside them.
##   food ratio    carrying against all the bread asked (the rations' share)
##   stores ratio  what is left against all the stores asked
## Horses graze: a band's fodder is asked only for what the country does not
## give. A garrison's town gives most of its bread, none of its fuel.

const Supply:=preload("res://scripts/supply_state.gd")
const Sustainment:=preload("res://scripts/field_sustainment.gd")
const Rations:=preload("res://scripts/field_rations.gd")

const PORTER_LOAD:=16.0
const CART_LOAD:=250.0
const WAGON_LOAD:=700.0
const LORRY_LOAD:=2000.0
const DRIVERLESS_BONUS:=0.4
const RATION:=1.12
const MIN_ROUND_TRIP:=Supply.MIN_ROUND_TRIP
const RAIL_SHARE:=Supply.RAIL_SHARE
## A garrison's town feeds most of it; carriers bring this share of its bread
## by default.
const GARRISON_CARRIED:=0.3
const LORRY_STOCK:="Supply Lorries"
const CART_STOCK:="Transport Carts"
## The kinds of carrier, with the supply field's pace key for each.
const KINDS:=["lorry","cart","porter"]
const ARM:={"lorry":"motor","cart":"wheeled","porter":"foot"}

## The fleet: drivers, what each drives, and the loads each kind moves a trip.
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
	var trip:={"lorry":float(lorries)*lorry_load,"cart":float(carts)*cart_load,"porter":float(porters)*PORTER_LOAD}
	return {"drivers":drivers,"lorries":lorries,"lorries_held":lorries_held,"carts":carts,"carts_held":carts_held,"porters":porters,
		"cart_load":cart_load,"lorry_load":lorry_load,"trip":trip,"loads":float(trip.lorry)+float(trip.cart)+float(trip.porter)}

## The kind of carrier moving most of our loads (the supply field's pace).
static func main_kind(fleet_row:Dictionary)->String:
	var best:="porter"
	var most:=-1.0
	for kind:String in KINDS:
		var trip:=float((fleet_row.get("trip",{}) as Dictionary).get(kind,0.0))
		if trip>most: most=trip; best=kind
	return best if most>0.0 else "porter"

## A force's asks of the carriers a day: {bread, stores}. A garrison's town
## gives part of its bread (none of its fuel); horses graze part of the fodder.
static func asks(force:Dictionary,graze:float=0.0)->Dictionary:
	var bread:=float(maxi(0,int(force.get("troops",0))))*RATION
	var demand:=Sustainment.stores_demand(force)
	var stores:=float(demand.loads)-float(demand.fodder)*clampf(graze,0.0,1.0)
	if force.has("region_id") and not force.has("army_id"):
		var required:=float(force.get("provisions_required_today",0.0))
		var local:=float(force.get("provisions_local_today",0.0))
		bread*=clampf(1.0-local/required,0.0,1.0) if required>0.0 else GARRISON_CARRIED
	return {"bread":bread,"stores":maxf(0.0,stores)}

## Loads a day a force asks of the carriers, bread and stores together (the
## supply map's line weight).
static func daily_loads(force:Dictionary)->float:
	var a:=asks(force)
	return float(a.bread)+float(a.stores)

## Days carriers spend going out and back for a day's loads over a haul of
## `days`, at least a day, the railway taking part of it.
static func round_trip(days:float,rail:float)->float:
	return Supply.carrier_round_trip(days,rail)

static func kind_round_trip(kind:String,effort:float,chill:float,rail:float)->float:
	return round_trip(Supply.haul_days(effort,String(ARM[kind]),chill),rail)

## The work: every band away and every garrison. {bread, stores, loads,
## sum_rt:{kind: Σ loads × round trip}, forces:[...]}.
static func demand(mc:Object,rail:float)->Dictionary:
	var bread:=0.0
	var stores:=0.0
	var sum_rt:={"lorry":0.0,"cart":0.0,"porter":0.0}
	var rows:=[]
	var forces:Array=[]
	for force:Dictionary in mc.field_armies:
		if int(force.get("troops",0))<=0 or mc.at_home_point(force): continue
		if bool(force.get("general_managed",false)) and WorldSimulation.campaign!=null and WorldSimulation.campaign.active: continue
		forces.append(force)
	for force:Dictionary in mc.occupation_forces:
		if int(force.get("troops",0))>0: forces.append(force)
	for force:Dictionary in forces:
		var reach:=Supply.haul_inputs_for(force)
		if not bool(reach.reachable): continue
		var graze:=Rations.forage_share(force) if force.has("army_id") else 0.0
		var a:=asks(force,graze)
		var loads:=float(a.bread)+float(a.stores)
		bread+=float(a.bread);stores+=float(a.stores)
		for kind:String in KINDS: sum_rt[kind]=float(sum_rt[kind])+loads*kind_round_trip(kind,float(reach.effort),float(reach.cold),rail)
		rows.append({"key":("army:%d" % int(force.get("army_id",0))) if force.has("army_id") else "held:%s" % String(force.get("region_id","")),"bread":float(a.bread),"stores":float(a.stores),"effort":float(reach.effort)})
	return {"bread":bread,"stores":stores,"loads":bread+stores,"sum_rt":sum_rt,"forces":rows}

## Share of the war leader's logistics and the people's supply practice.
static func efficiency(logistics:float,practice:float)->float:
	return 0.85+0.30*clampf(logistics,0.0,1.0)+0.15*clampf(practice,0.0,1.0)

## The day's reading: {food, stores, ratio (= food), moved (loads a day),
## demand (loads a day), bread, stores_asked, efficiency, rail, fleet,
## forces, preview (for the map), kind (the carrier moving most)}.
static func reading(mc:Object)->Dictionary:
	var adoption:=func(id:String)->float: return float(mc._adoption(id))
	var state:Variant=WorldSimulation.state
	var have:=fleet(state,adoption)
	var rail:=float(adoption.call("railway_mobilization"))
	var need:=demand(mc,rail)
	var logistics:=float((mc.home_army.get("commander",{}) as Dictionary).get("logistics",0.4)) if mc.home_army is Dictionary else 0.4
	var eff:=efficiency(logistics,float(adoption.call("supply_groups")))
	var preview:={"trip":(have.trip as Dictionary).duplicate(),"sum_rt":(need.sum_rt as Dictionary).duplicate(),"loads":float(need.loads),"bread":float(need.bread),"efficiency":eff,"rail":rail}
	var moved:=Supply.carried_a_day(preview)
	var food:=1.0 if float(need.bread)<=0.0 else clampf(moved/float(need.bread),0.0,1.0)
	var left:=maxf(0.0,moved-float(need.bread))
	var stores:=1.0 if float(need.stores)<=0.0 else clampf(left/float(need.stores),0.0,1.0)
	return {"food":food,"stores":stores,"ratio":food,"moved":moved,"demand":float(need.loads),"bread":float(need.bread),"stores_asked":float(need.stores),
		"efficiency":eff,"rail":rail,"fleet":have,"forces":need.forces,"preview":preview,"kind":main_kind(have)}

## Carts (or lorries) the carriers still lack to bring every load, never more
## than there are drivers for: the staff's building target.
static func wanted(mc:Object,item:String)->int:
	return wanted_from(mc.carrier_reading() if mc.has_method("carrier_reading") else reading(mc),item)

static func wanted_from(r:Dictionary,item:String)->int:
	var short:=maxf(0.0,float(r.demand)-float(r.moved))
	if short<=0.0: return 0
	var fl:Dictionary=r.fleet
	var preview:Dictionary=r.get("preview",{})
	var loads:=float(preview.get("loads",0.0))
	if loads<=0.0: return 0
	var kind:="lorry" if item=="supply_lorry" else "cart"
	var sum_rt:Dictionary=preview.get("sum_rt",{})
	var rt_new:=float(sum_rt.get(kind,0.0))/loads
	var rt_porter:=float(sum_rt.get("porter",0.0))/loads
	if rt_new<=0.0 or rt_porter<=0.0: return 0
	var per:=float(fl.lorry_load) if kind=="lorry" else float(fl.cart_load)
	# A driver moved from his back to a cart or lorry gains its loads a day.
	var gain:=(per/rt_new-PORTER_LOAD/rt_porter)*float(r.efficiency)
	if gain<=0.0: return 0
	return mini(int(fl.porters),ceili(short/gain))
