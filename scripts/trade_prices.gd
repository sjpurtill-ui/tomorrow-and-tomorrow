extends RefCounted
## THE ONE PRICE TABLE for goods that pass between peoples.
##
## A good is worth what the people's own economy says it is worth
## (economy_system.gd): the market price its people have observed
## (state.market_prices, once tallies and measures let them compare values),
## else the economy's reference value (EconomySystem.BASE_VALUES). Each people
## reads its own table in its own scope, so two peoples may value the same
## flint differently; the seller's price sets what it sells for.
##
## A few goods the economy does not price yet stand on a good it does
## (STANDS_ON): a flint is worth two loads of stone. When economy_system.gd
## prices them itself, its price wins and STANDS_ON is never read.
##
## Trade pacts (trade_pacts.gd), envoys' asks and gifts (envoy_requests.gd)
## and trade between peoples (trade_ledger.gd) all read this table; none keeps
## a second one. Static; preload.

## Goods economy_system.gd does not price yet: [the priced good, how many of it].
const STANDS_ON:={"Flint":["Stone",2.0]}
## A good nobody has priced at all (never read for the goods peoples trade).
const UNPRICED:=1.0

## The reference values of the one table (economy_system.gd BASE_VALUES).
static func base(good:String)->float:
	var table:Dictionary=EconomySystem.BASE_VALUES
	if table.has(good):return float(table[good])
	if STANDS_ON.has(good):
		var on:Array=STANDS_ON[good]
		return float(table.get(String(on[0]),UNPRICED))*float(on[1])
	return UNPRICED

## What `good` is worth to the people in scope now: its observed market
## price, or the reference value.
static func in_scope(good:String)->float:
	var state=WorldSimulation.state
	if state==null:return base(good)
	var prices:Dictionary=state.market_prices
	var observed:=int((state.economy_metrics as Dictionary).get("price_observations",0))>0
	if observed and prices.has(good):return maxf(0.01,float(prices[good]))
	if STANDS_ON.has(good):
		var on:Array=STANDS_ON[good]
		var under:=String(on[0])
		if observed and prices.has(under):return maxf(0.01,float(prices[under])*float(on[1]))
	return base(good)

## What `good` is worth to `owner` ("player" or a civilization id). A people
## the world does not simulate has no market of its own: the reference value.
static func value(good:String,owner:String="player")->float:
	if owner=="" or owner=="player" or owner=="human":
		return float(WorldSimulation.scoped("player",func()->float:return in_scope(good)))
	if not WorldSimulation.actors.has(owner):return base(good)
	return float(WorldSimulation.scoped(owner,func()->float:return in_scope(good)))

## Every listed good's worth to `owner`, rounded for words and prompts.
static func table(goods:Array,owner:String="player")->Dictionary:
	var out:={}
	for good:String in goods:out[good]=snappedf(value(good,owner),0.01)
	return out
