extends RefCounted
## WHAT A DEAL IS WORTH TO EACH SIDE, in rations' worth.
##
## A good is worth its price on the one price table (trade_prices.gd) times
## how much the people needs more of it: each unit is worth price x (wanted /
## held), never under FLOOR nor over CEIL of its price. `wanted` is the
## holding the people's own economy wants (economy_system.gd _desired_stock:
## 30 days of food a head, a timber and a half, a stone and a fifth, ...);
## `held` is what its stores hold now. So 100 Food is worth about 100 rations
## to a people holding the 30 days it wants, about 20 to one with 150 days in
## store (food beyond what is eaten before it rots buys little), and twice
## its price to one down to a fortnight. Giving is weighed the same way down
## the stores: 100 Food out of 150 days costs about 20; out of a fortnight,
## twice its price.
##
## Hands and people are worth what they make: a person-day is a day of the
## people's output a head (trade_ledger.person_worth / 365, a day's food at
## least); a person gone for good is a year of it, the price families fetch
## on the trade ledger.
##
## A good a people's economy does not know yet (copper ore before anyone can
## work it) is worth FLOOR of its price to it, unless it is one of the basic
## goods every people uses (trade_ledger.BASIC).
##
## Every people is weighed the same way, the god's and the computer rulers'
## (standing-and-balance-direction): only what each holds and wants differs.
## Read-only; static; preload.

const PRICES:=preload("res://scripts/trade_prices.gd")
const LEDGER_PATH:="res://scripts/trade_ledger.gd"

## A unit is worth price x (wanted / held), within these shares of its price.
const FLOOR:=0.1
const CEIL:=2.0
## Slices the stores are walked in when a deal moves many units.
const SLICES:=8
## Goods a people may pay or be paid in on an envoy's business, besides
## Food and the five stores the hall knows (audience_hall.RESOURCES).
const GOODS:=["Food","Timber","Stone","Clay","Fiber Plants","Flint","Salt","Medicinal Plants","Copper Ore","Tin Ore","Iron Ore","Coal","Civilian Goods"]
## Goods every people uses whether or not its economy has priced them.
const BASIC:=["Food","Flint","Stone","Timber","Clay","Fiber Plants","Civilian Goods"]
## The year a person's work is reckoned over (trade_ledger FAMILY_YEAR_DAYS).
const YEAR:=365.0

static func _ledger()->GDScript:
	return load(LEDGER_PATH) as GDScript

static func owner_of(id:String)->String:
	return "player" if id in ["","player","human"] else id

static func simulated(owner:String)->bool:
	owner=owner_of(owner)
	return owner=="player" or WorldSimulation.actors.has(owner)

static func _civ(owner:String)->Dictionary:
	for c in CivilizationSystem.civilizations:
		if c is Dictionary and String((c as Dictionary).get("id",""))==owner: return c
	return {}

static func population(owner:String)->float:
	owner=owner_of(owner)
	if owner=="player": return maxf(1.0,float(GameState.population_exact))
	if WorldSimulation.actors.has(owner): return float(WorldSimulation.scoped(owner,func()->float:return maxf(1.0,float(WorldSimulation.state.population_exact))))
	return maxf(1.0,float(_civ(owner).get("population",100.0)))

## What the people's stores hold of `good` now.
static func held(owner:String,good:String)->float:
	owner=owner_of(owner)
	if not simulated(owner):
		return maxf(0.0,float(_civ(owner).get("food_days",30.0)))*population(owner) if good=="Food" else 0.0
	return float(WorldSimulation.scoped(owner,func()->float:
		if good=="Food": return WorldSimulation.food.total_stored()
		return maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get(good,0.0)))))

## The holding the people's own economy wants of `good`.
static func wanted(owner:String,good:String)->float:
	owner=owner_of(owner)
	var pop:=population(owner)
	if not simulated(owner):
		# No economy of its own: the same reckoning, by its head count.
		return float(WorldSimulation.scoped("player",func()->float:return maxf(1.0,float(WorldSimulation.economy._desired_stock(good,pop)))))
	return float(WorldSimulation.scoped(owner,func()->float:return maxf(1.0,float(WorldSimulation.economy._desired_stock(good,pop)))))

## Whether the people's economy knows the good (holds it, has priced it or
## found where it lies), or it is a basic good every people uses.
static func usable(owner:String,good:String)->bool:
	if good in BASIC: return true
	owner=owner_of(owner)
	if not simulated(owner): return false
	return bool(WorldSimulation.scoped(owner,func()->bool:
		var stock:=maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get(good,0.0)))
		return bool(WorldSimulation.economy._resource_is_economically_known(good,stock))))

## Its stores against its want: 1.0 holds what it wants, 5.0 five times.
static func depth(owner:String,good:String)->float:
	return held(owner,good)/maxf(0.001,wanted(owner,good))

## One unit's worth, as a share of its price, at this depth of the stores.
static func factor_at(store_depth:float)->float:
	return clampf(1.0/maxf(0.0001,store_depth),FLOOR,CEIL)

## The price on the one table (trade_prices.gd) the people reckons in.
static func price(owner:String,good:String)->float:
	return PRICES.value(good,owner_of(owner))

static func _mean_factor(want:float,from:float,to:float)->float:
	## The mean worth of a unit as the stores go from `from` to `to`.
	if to<from: var t:=from; from=to; to=t
	if to-from<0.0001: return factor_at(from/maxf(0.001,want))
	var sum:=0.0
	for i in SLICES:
		var at:=from+(to-from)*(float(i)+0.5)/float(SLICES)
		sum+=factor_at(at/maxf(0.001,want))
	return sum/float(SLICES)

## One reading of a people's stores of a good: {h held, w wanted, p price,
## u usable}. The worth functions below take either an owner and a good or
## such a reading (so a bisection reads the stores once).
static func reading(owner:String,good:String)->Dictionary:
	return {"h":held(owner,good),"w":wanted(owner,good),"p":price(owner,good),"u":usable(owner,good)}

static func in_reading(r:Dictionary,qty:float)->float:
	if qty<=0.0: return 0.0
	var f:=_mean_factor(float(r.w),float(r.h),float(r.h)+qty) if bool(r.u) else FLOOR
	return float(r.p)*qty*f

static func out_reading(r:Dictionary,qty:float)->float:
	if qty<=0.0: return 0.0
	return float(r.p)*qty*_mean_factor(float(r.w),maxf(0.0,float(r.h)-qty),float(r.h))

## What receiving `qty` of `good` is worth to `owner`, in rations' worth.
static func worth_in(owner:String,good:String,qty:float)->float:
	return in_reading(reading(owner,good),qty)

## What giving up `qty` of `good` costs `owner`, in rations' worth.
static func worth_out(owner:String,good:String,qty:float)->float:
	return out_reading(reading(owner,good),qty)

## One unit's worth to `owner` now (the first unit received).
static func unit_worth(owner:String,good:String)->float:
	if not usable(owner,good): return price(owner,good)*FLOOR
	return price(owner,good)*factor_at(depth(owner,good))

## A day of one person's work: the people's output a head, a day's food at least.
static func day_of_work(owner:String)->float:
	var ledger:=_ledger()
	if ledger==null: return price(owner,"Food")
	return float(ledger.call("person_worth",owner_of(owner)))/YEAR

## A person gone for good: a year of their work (the families price).
static func person(owner:String)->float:
	var ledger:=_ledger()
	if ledger==null: return YEAR*price(owner,"Food")
	return float(ledger.call("person_worth",owner_of(owner)))

## Days of food in store: the people's own reading where it keeps one.
static func food_days(owner:String)->float:
	owner=owner_of(owner)
	if owner=="player": return float(GameState.simulation_metrics.get("food_days",held(owner,"Food")/population(owner)))
	var civ:=_civ(owner)
	if not simulated(owner): return float(civ.get("food_days",30.0))
	return held(owner,"Food")*30.0/maxf(1.0,wanted(owner,"Food"))

## How many units of the reading's good give a worth of `target` when
## received (bisection; at most `most`).
static func qty_for_worth(r:Dictionary,target:float,most:float)->float:
	if target<=0.0 or most<=0.0: return 0.0
	if in_reading(r,most)<=target: return most
	var lo:=0.0
	var hi:=most
	for i in 22:
		var mid:=(lo+hi)*0.5
		if in_reading(r,mid)<target: lo=mid
		else: hi=mid
	return hi

## How many units of the reading's good cost `target` to give up (at most `most`).
static func qty_for_cost(r:Dictionary,target:float,most:float)->float:
	if target<=0.0 or most<=0.0: return 0.0
	if out_reading(r,most)<=target: return most
	var lo:=0.0
	var hi:=most
	for i in 22:
		var mid:=(lo+hi)*0.5
		if out_reading(r,mid)<target: lo=mid
		else: hi=mid
	return hi

## Words for a store's depth: "150 days of food in store, 30 wanted" or
## "20 Stone in store, 240 wanted".
static func depth_words(owner:String,good:String)->String:
	if good=="Food":
		var days:=food_days(owner)
		var d:=depth(owner,"Food")
		return "%d days of food in store, %d wanted" % [roundi(days),roundi(days/d) if d>0.01 else 30]
	return "%d %s in store, %d wanted" % [roundi(held(owner,good)),good,roundi(wanted(owner,good))]
