extends RefCounted
## THE REALM'S PURSE: one account the god commands for the whole people.
##
## Every town keeps its own stores, and its households keep their own money;
## the realm's account is one, and it holds only what is really in it.
## Before coinage it is the common store: goods (civilian_goods.gd: tools,
## cord, baskets, pots, the first money) the levy took out of each town's
## own stores, counted in goods (one goods-worth held, one in the purse).
## After coinage it is the treasury: coin, with the metal that backs it, and
## the goods still taken in kind, counted in coin at the market price (the
## unit changes once, at coinage: _sync_unit). The balance is what is held:
## the coin, and the goods in kind (balance - coin). After coinage the goods
## are kept at one book price (book_price, today's price at coinage), so a
## goods-worth in is a goods-worth out whatever goods fetch.
##
## IN: the levy, a share of what every town brings in, taken by each town's
##   own economy day (accrue(): what the realm's hands reach, less what is
##   hidden): goods out of that town's stores, only what it holds beyond its
##   homes' need (civilian_goods.gd spare); after coinage the share on goods
##   sold for money in coin, from households, with its backing (as
##   artifact_collection.gd moves coin between peoples). And what other
##   systems put in (deposit(): tolls, tribute, spoils, sales).
## OUT, reckoned once a month for the month just past (settle()): what wore
##   out in the store (the homes' own wear on goods), old debts, the
##   soldiers' pay, food for hungry towns (bought from towns with food to
##   spare, with the store's goods or coin), paid crews and the scholars'
##   keep, each as far as the purse holds out; and what other systems pay
##   (spend(): gifts, purchases). Pay puts the goods and coin back where
##   people live (_hand_out).
##
## Every people keeps its own purse in its own scope (WorldSimulation.state
## .realm_purse), by the same rules; a computer ruler sets the same levers by
## its nature (civilization_controller.gd purse_orders).
##
## The seam other systems use: balance(), deposit(amount, why),
## spend(amount, why) -> bool, unit_word(), account_name(), history(),
## season() (the last season's money in and out) and forecast() (a season
## at today's settings). Static; preload.

const Levers:=preload("res://scripts/office_levers.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Goods:=preload("res://scripts/civilian_goods.gd")
const Prices:=preload("res://scripts/trade_prices.gd")

## 3: the store holds goods, not food (a version-2 store's food goes back to
## the capital's stores once: _food_back).
const VERSION:=3
## The levy's levels, lightest first, as shares of the most the age can take.
const LEVELS:=["light","usual","heavy"]
const LEVEL_NAMES:={"light":"Light","usual":"Usual","heavy":"Heavy"}
const LEVEL_SHARE:={"light":0.25,"usual":0.5,"heavy":1.0}
## The most a levy can take of what is brought in, by what the people know.
## Historical ranges: a chief's tribute and feast dues about a tenth of the
## harvest; early states, their temples and storehouses about a fifth (the
## "fifth part" of the harvest); coin-paying states a fifth, and those that
## count every household (clerks, registers, courts) up to a third.
const STAGE_CAP:={"subsistence":0.10,"weighed_metal":0.20,"currency":0.20}
const CAPACITY_CAP_BONUS:=0.15
## The plain fractions a levy is set at, so its words are exact.
const FRACTIONS:=[[1,40],[1,30],[1,20],[1,15],[1,12],[1,10],[1,8],[1,6],[1,5],[1,4],[1,3],[2,5]]
const NUMBER_WORDS:={1:"one",2:"two",3:"three",4:"four",5:"five",6:"six",8:"eight",10:"ten",12:"twelve",15:"fifteen",20:"twenty",30:"thirty",40:"forty"}
## What a levy costs in goodwill, in points of 100 at its heaviest (the
## economy's social pressure: trust in the chiefs takes it whole, holding
## together a little over half). Custom bears a light levy without complaint.
const LEVY_TRUST:=0.06
const LEVY_FREE_SHARE:=0.2
## The spending lines, in the order the purse pays them when it runs short.
const LINES:=["army","relief","crews","scholars"]
const LINE_NAMES:={"army":"Pay the soldiers","relief":"Feed hungry towns","crews":"Hire crews","scholars":"Fund the scholars"}
const DEFAULT_LINES:={"army":true,"relief":false,"crews":false,"scholars":false}
## Pay a day, as a share of what one person brings in a day, on top of their
## rations: a soldier at arms (home, field or garrison), one in drill, waiting
## or hurt, a scholar's keep, a hired builder's wage. Soldiers were paid about
## what a labourer earned (a day's wage for a day's service); a keep for
## scholars and builders is a smaller sum beside their food.
const PAY_SOLDIER:=0.5
const PAY_RESERVE:=0.25
const PAY_SCHOLAR:=0.15
const PAY_CREW:=0.15
## What full funding buys: research this much faster (patrons' keep frees a
## scholar's whole day), building this much faster (paid hands work longer
## and come from other work).
const SCHOLARS_MAX:=0.12
const CREWS_MAX:=0.15
## Who the pay reaches, for the wealth of the poorer households: food for the
## hungry all of it, builders and soldiers mostly common folk, scholars few.
const REDISTRIBUTION_WEIGHT:={"relief":1.0,"crews":0.8,"army":0.5,"scholars":0.2,"debts":0.0}
## Relief: a town is hungry under HUNGRY_DAYS of food; food is bought (with
## the store's goods, or coin) from towns holding more than SELLER_DAYS (down to SELLER_KEEP) to bring each
## hungry town to RELIEF_TARGET days, at most RELIEF_SHARE of the purse a
## month while the line is on. All are set from the lean buffer
## (food_care.gd LEAN_DAYS, the store food security counts), in this order:
## HUNGRY_DAYS < RELIEF_TARGET < SELLER_KEEP < SELLER_DAYS, so no seller is
## left hungry. The levy takes goods, never food.
const LEAN_DAYS:=preload("res://scripts/food_care.gd").LEAN_DAYS
const HUNGRY_DAYS:=LEAN_DAYS*0.75
const RELIEF_TARGET:=LEAN_DAYS
const SELLER_DAYS:=LEAN_DAYS*2.0
const SELLER_KEEP:=LEAN_DAYS*1.5
const RELIEF_SHARE:=0.25
## Old public debts are paid back at most this share of the purse a month.
const DEBT_SHARE:=0.25
const MONTH_DAYS:=30
const SEASON_DAYS:=91.25
const LEDGER_LIMIT:=48
const MONTHS_KEPT:=3
## Coin collected in a day is at most this share of the households' own coin.
const COIN_DRAW:=0.25
## One unit of backing metal for every 2.5 coin (economy_system issue ceiling).
const BACKING_RATIO:=0.4
## Taxing the rich (government_policy_catalog wealth_levy): the richest fifth
## pay this share of what their share of the work brings in, at the
## policy's ordinary strength.
const RICH_RATE:=0.05
const POLICY_STRENGTH:=0.16
## A place's own money, as the capital keeps it on the people's state.
const MONEY_FIELDS:=["economy_stage","currency_supply","public_treasury","private_currency","public_debt","military_arrears","civil_arrears"]


# --- The account ---------------------------------------------------------------

static func _fresh()->Dictionary:
	return {"version":VERSION,"balance":0.0,"coin":0.0,"backing":{},"levy":"usual","rate":0.0,"cap":0.0,"take":0.0,"stage":"subsistence",
		"lines":DEFAULT_LINES.duplicate(),"line_days":{},"funded":{"army":1.0,"relief":1.0,"crews":1.0,"scholars":1.0},
		"month":_empty_month(),"months":[],"last_settle_day":-1,"ledger":[],
		"unpaid_months":0,"desertion_carry":0.0,"deserted":0,"last_army":{},"debt":0.0,"events":{},"redistribution":0.0,"migrated":false,"unit":"goods","book_price":1.0}

static func _empty_month()->Dictionary:
	return {"levy":0.0,"rich":0.0,"charter":0.0,"assessed":0.0,"evaded":0.0,"output":0.0,"person_days":0.0,"coin":0.0,"deposits":0.0,"short":0.0,
		"army":0.0,"relief":0.0,"crews":0.0,"scholars":0.0,"debts":0.0,"spent":0.0,"spoiled":0.0,"army_due":0.0,"rations":0.0}

## This people's purse, made whole: a missing field takes its default, and an
## older world's town treasuries are merged once (at the realm's own level).
## A purse kept before the store held what it counted is counted again once
## (_recount).
static func state()->Dictionary:
	var s=WorldSimulation.state
	var purse:Dictionary=s.realm_purse
	if int(purse.get("version",0))!=VERSION or not purse.has("lines"):
		var older:=not purse.has("unit") and (float(purse.get("balance",0.0))>0.0 or not (purse.get("ledger",[]) as Array).is_empty())
		_mark_food_store(purse)
		var fresh:=_fresh()
		for key in fresh:
			if not purse.has(key):purse[key]=fresh[key]
		purse["version"]=VERSION
		if older:purse["recount"]=true
	if String(s.resource_settlement_id)=="":
		if not bool(purse.get("migrated",false)):_merge_town_money(purse)
		if bool(purse.get("recount",false)):_recount(purse)
		if purse.has("food_back"):_food_back(purse)
	return purse

## A store kept in food (version 2, its unit "ration" or its food at a book
## price in coin) is marked once, to give its food back (_food_back).
static func _mark_food_store(purse:Dictionary)->void:
	if not purse.has("unit") or int(purse.get("version",0))!=2:return
	var food:=maxf(0.0,float(purse.get("balance",0.0))-float(purse.get("coin",0.0)))
	var rations:=food if String(purse.unit)!="coin" else food/maxf(0.2,float(purse.get("book_price",1.0)))
	purse["food_back"]=rations
	purse.balance=float(purse.get("coin",0.0))
	purse["unit"]="coin" if String(purse.unit)=="coin" else "goods"
	purse["book_price"]=1.0

## Once, at the realm's own level: the food an older store held goes back
## into the capital's stores (it was real food), and the store starts again
## in goods. Coin stays.
static func _food_back(purse:Dictionary)->void:
	var rations:=maxf(0.0,float(purse.get("food_back",0.0)))
	purse.erase("food_back")
	if String(purse.unit)=="coin":purse["book_price"]=goods_price()
	if rations<0.5 or WorldSimulation.food==null:return
	WorldSimulation.food.receive_external_food(rations)
	_note(purse,0.0,"The common store keeps goods now, not food: its %s rations went back into %s's stores" % [number(rations),String(WorldSimulation.state.settlement_name)],"recount")

static func balance()->float:
	return float(state().balance)


# --- What the store holds -------------------------------------------------------

## Counted in goods (before coinage) or in coin (after): the purse's unit.
static func in_kind()->bool:
	var purse:Dictionary=WorldSimulation.state.realm_purse
	return String(purse.get("unit","goods"))!="coin"

## A goods-worth's market price where the day runs now (its base price,
## trade_prices.gd, before prices are kept).
static func goods_price()->float:
	return _price(Goods.GOODS)

## Food's market price where the day runs now, the same way.
static func food_price()->float:
	return _price("Food")

static func _price(good:String)->float:
	var held:Variant=WorldSimulation.state.market_prices.get(good)
	return maxf(0.05,float(held) if held!=null else Prices.base(good))

## A value at the economy's market prices, in the purse's unit: goods at
## this place's goods price before coinage, coin after.
static func units(value:float)->float:
	return value/goods_price() if in_kind() else value

## The coin a goods-worth of the store's goods is kept at (1 before coinage).
static func _book()->float:
	if in_kind():return 1.0
	return maxf(0.05,float((WorldSimulation.state.realm_purse as Dictionary).get("book_price",1.0)))

## The purse's goods in kind, counted in goods.
static func _goods_of(amount:float)->float:
	return amount/_book()

## Goods of the store in the purse's unit.
static func _units_of_goods(goods:float)->float:
	return goods*_book()

## Goods the store holds now.
static func held_goods()->float:
	var purse:=state()
	return _goods_of(maxf(0.0,float(purse.balance)-float(purse.coin)))

## What the store's goods are worth in food at today's prices, in rations.
static func goods_in_rations(goods:float)->float:
	return goods*goods_price()/food_price()

## Takes `amount` of the levy in kind (in the purse's unit) out of the
## stores of the place whose day runs now: goods, only what its homes can
## spare beyond their need (civilian_goods.gd spare). After coinage `amount`
## is coin: the goods it buys at this town's price are taken, and kept at
## the book price. Returns {taken, short}, in the purse's unit.
static func _take_goods(amount:float)->Dictionary:
	if amount<=0.0:return {"taken":0.0,"short":0.0}
	var wanted:=amount if in_kind() else amount/goods_price()
	# Nothing beyond the homes' own need: nothing to read further.
	var stock:=Goods.stock()
	var spare:=Goods.spare() if stock>0.0001 and stock>Goods.target() else 0.0
	var took:=Goods.draw(minf(wanted,spare)) if spare>0.0001 else 0.0
	return {"taken":_units_of_goods(took),"short":_units_of_goods(maxf(0.0,wanted-took))}

## Puts `amount` of the store's goods back in common hands: in the place `to`
## names, else in every town of ours by its share of the people. Called at
## the realm's own level (the monthly reckoning, the court, the screens).
static func _hand_out(amount:float,to:Dictionary={})->void:
	var goods:=_goods_of(amount)
	if goods<=0.0001:return
	var places:=_places()
	var paid_to:Array=[]
	if not to.is_empty():
		for place:Dictionary in places:
			if bool(place.primary)==bool(to.get("primary",false)) and (bool(place.primary) or String((place.record as Dictionary).get("id",""))==String(to.get("id",""))):paid_to=[place]
	if paid_to.is_empty():paid_to=places
	var total:=0.0
	for place:Dictionary in paid_to:total+=maxf(0.0001,float(place.share))
	for place:Dictionary in paid_to:
		var part:=goods*maxf(0.0001,float(place.share))/total
		if bool(place.primary):_receive_goods(part)
		else:WorldSimulation.settlements.with_city_resources(String((place.record as Dictionary).get("id","")),func()->void:_receive_goods(part))

## Goods into the stores of the place whose day runs now.
static func _receive_goods(goods:float)->void:
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	stocks[Goods.GOODS]=maxf(0.0,float(stocks.get(Goods.GOODS,0.0)))+goods

## The unit follows the age, once: at coinage the goods held in kind are
## counted in coin at the market price (and back, should coin be lost).
static func _sync_unit(purse:Dictionary)->void:
	var unit:="coin" if String(WorldSimulation.state.economy_stage)=="currency" else "goods"
	if String(purse.get("unit","goods"))==unit:return
	var goods:=maxf(0.0,float(purse.balance)-float(purse.coin))
	if unit=="coin":
		# The goods are kept at today's price from now on: a goods-worth in, a goods-worth out.
		purse["book_price"]=goods_price()
		purse.balance=float(purse.coin)+goods*float(purse.book_price)
	else:
		purse.balance=float(purse.coin)+goods/maxf(0.05,float(purse.get("book_price",1.0)))
	purse["unit"]=unit

## What the purse holds, in the people's words: "340 coin".
static func amount_text(value:float)->String:
	return "%s %s" % [number(value),unit_word()]

static func number(value:float)->String:
	if absf(value)<9.95 and absf(value)>=0.05:return ("%.1f" % value).trim_suffix(".0")
	return EraWords.grouped(roundi(value))

## Puts value into the purse from outside the levy: tolls, tribute, spoils,
## sales, in the purse's unit. Taken in kind (goods held for all), never as new
## coin: the caller has taken it out of somewhere else. Returns what was
## taken in.
static func deposit(amount:float,why:String)->float:
	if not is_finite(amount) or amount<=0.0:return 0.0
	var purse:=state()
	purse.balance=float(purse.balance)+amount
	(purse.month as Dictionary).deposits=float(purse.month.deposits)+amount
	_note(purse,amount,why,"in")
	return amount

## Pays from the purse for something outside its lines (gifts, purchases from
## other peoples): all or nothing. Coin paid this way leaves the realm with
## the metal that backs it, and goods in kind leave with it. Returns whether
## it was paid.
static func spend(amount:float,why:String)->bool:
	if not is_finite(amount) or amount<0.0:return false
	if amount<=0.0:return true
	var purse:=state()
	if float(purse.balance)+0.0001<amount:return false
	var coin:=_coin_part(purse,amount)
	purse.balance=maxf(0.0,float(purse.balance)-amount)
	if coin>0.0:
		purse.coin=maxf(0.0,float(purse.coin)-coin)
		_move_backing(purse.backing,{},coin*BACKING_RATIO)
	(purse.month as Dictionary).spent=float(purse.month.spent)+amount
	_note(purse,-amount,why,"out")
	return true

## Pays the realm's own people for work done in the place whose day runs now
## (wages for a great work's crews): coin goes to that place's households
## with its backing; the rest is goods from the store, into that place's
## stores. All or nothing. Returns whether it was paid.
static func pay_home(amount:float,why:String)->bool:
	if not is_finite(amount) or amount<0.0:return false
	if amount<=0.0:return true
	var purse:=state()
	if float(purse.balance)+0.0001<amount:return false
	var coin:=_coin_part(purse,amount)
	purse.balance=maxf(0.0,float(purse.balance)-amount)
	if coin>0.0:
		var s=WorldSimulation.state
		purse.coin=maxf(0.0,float(purse.coin)-coin)
		if String(s.economy_stage)=="currency":
			s.private_currency=float(s.private_currency)+coin
			s.currency_supply=float(s.currency_supply)+coin
			_move_backing(purse.backing,s.monetary_reserve_metals,coin*BACKING_RATIO)
		else:
			s.resource_stockpiles["Coin"]=float(s.resource_stockpiles.get("Coin",0.0))+coin
			_move_backing(purse.backing,{},coin*BACKING_RATIO)
	if amount-coin>0.0001:_receive_goods(_goods_of(amount-coin))
	(purse.month as Dictionary).crews=float(purse.month.crews)+amount
	_note(purse,-amount,why,"out")
	return true

## The coin and its backing another people's purse holds (a sale between
## peoples, artifact_collection.gd): {coin, backing}.
static func held_coin(owner_state:Object)->Dictionary:
	var purse:=_ensure(owner_state.get("realm_purse"))
	var backing:=0.0
	for value in (purse.backing as Dictionary).values():backing+=maxf(0.0,float(value))
	return {"coin":float(purse.coin),"backing":backing}

## Coin paid from one people's purse into another's, with the metal that
## backs it (a sale between peoples). Returns what moved.
static func move_coin(from_state:Object,to_state:Object,value:float,why:String)->float:
	var from:=_ensure(from_state.get("realm_purse"))
	var to:=_ensure(to_state.get("realm_purse"))
	var moved:=minf(maxf(0.0,value),float(from.coin))
	if moved<=0.0:return 0.0
	from.coin=float(from.coin)-moved;from.balance=maxf(0.0,float(from.balance)-moved)
	to.coin=float(to.coin)+moved;to.balance=float(to.balance)+moved
	_move_backing(from.backing,to.backing,moved*BACKING_RATIO)
	_note(from,-moved,why,"out");_note(to,moved,why,"in")
	return moved

## Another people's purse made whole without merging their towns' money
## (their own first reading does that, in their own scope).
static func _ensure(purse:Variant)->Dictionary:
	if not purse is Dictionary:return _fresh()
	var held:Dictionary=purse
	# A purse kept before the store held what it counted is still counted
	# again on its own people's first reading (state()), even when trade
	# between peoples touches it first.
	if not held.has("unit") and (float(held.get("balance",0.0))>0.0 or not (held.get("ledger",[]) as Array).is_empty()):held["recount"]=true
	var fresh:=_fresh()
	for key in fresh:
		if not held.has(key):held[key]=fresh[key]
	return held

## The purse's record, newest first: {day, amount, why, kind, balance}.
static func history()->Array:
	return (state().ledger as Array).duplicate(true)

static func _note(purse:Dictionary,amount:float,why:String,kind:String)->void:
	var ledger:Array=purse.ledger
	ledger.push_front({"day":int(WorldSimulation.state.elapsed_days),"amount":amount,"why":why,"kind":kind,"balance":float(purse.balance)})
	if ledger.size()>LEDGER_LIMIT:ledger.resize(LEDGER_LIMIT)


# --- Words by age ----------------------------------------------------------------

## The realm's money stage: the capital's, read at the realm's own level and
## kept for readings made inside a town's day.
static func stage()->String:
	var s=WorldSimulation.state
	var purse:Dictionary=s.realm_purse
	if String(s.resource_settlement_id)=="":
		var now:=String(s.economy_stage)
		if not purse.is_empty():
			purse["stage"]=now
			if purse.has("unit"):_sync_unit(purse)
		return now
	return String(purse.get("stage","subsistence"))

## What the account is called: before coinage it holds goods, the common
## store, counted in goods (whatever metal the people work: the store is
## not silver). After coinage, the treasury: "coin" once the people keep
## registers or public credit (character_voice.gd era gates), else "silver".
static var _form_key:=""
static var _form_value:="store"
static func _form()->String:
	var at:=stage()
	if at!="currency" or in_kind():return "store"
	var owner:=WorldSimulation.actor_id if WorldSimulation.actor_id!="" else "player"
	# Read once a day per people and age: the screens ask every second.
	var key:="%s|%s|%d|%d" % [owner,at,int(WorldSimulation.state.elapsed_days),(WorldSimulation.state.known_discoveries as Array).size()]
	if key==_form_key:return _form_value
	var voice:=load("res://scripts/character_voice.gd") as GDScript
	var tags:Array=voice.call("era_tags",owner) if voice!=null else []
	_form_value="coin" if tags.has("coin") else "silver"
	_form_key=key
	return _form_value

static func account_name()->String:
	match _form():
		"coin","silver":return "the treasury"
	return "the common store"

static func unit_word()->String:
	match _form():
		"coin":return "coin"
		"silver":return "silver"
	return "goods"

## Before coinage, pay is goods from the store; then coin (or silver).
static func pay_word()->String:
	match _form():
		"coin":return "coin"
		"silver":return "silver"
	return "goods"

## What the levy is reckoned on, in the people's words: everything a
## household brings in, paid in goods (or coin) out of what it holds.
static func harvest_word()->String:
	return "what every household brings in"


# --- The levy --------------------------------------------------------------------

## How much a ruler can count and collect: the hands that reach the people
## (office_levers.reach: a few hundred people are known face to face; past
## that, clerks and custom carry it) and the tallies and registers that keep
## what is owed.
static func reach()->float:
	var records:=maxf(WorldSimulation.discovery.adoption("tallies"),WorldSimulation.discovery.adoption("property_registers"))
	return clampf(Levers.reach()*(0.8+records*0.2),0.2,1.0)

## The state's capacity to assess every household (reach, records, settled
## custom), 0..1: past 0.6 after coinage it lifts the most a levy can take.
static func capacity()->float:
	var s=WorldSimulation.state
	var records:=maxf(WorldSimulation.discovery.adoption("tallies"),WorldSimulation.discovery.adoption("property_registers"))
	var institutions:=clampf(float(s.society_capacities.get("institutions",0.25)),0.0,1.0)
	return clampf(Levers.reach()*0.4+records*0.3+institutions*0.3,0.0,1.0)

static func cap_now()->float:
	var at:=stage()
	var cap:=float(STAGE_CAP.get(at,0.10))
	if at=="currency":cap+=CAPACITY_CAP_BONUS*clampf((capacity()-0.6)/0.4,0.0,1.0)
	return cap

## A level's share of every harvest, at the plain fraction just under it.
static func level_rate(level:String,cap:float)->float:
	var raw:=cap*float(LEVEL_SHARE.get(level,0.5))
	var best:=1.0/40.0
	for f:Array in FRACTIONS:
		var value:=float(f[0])/float(f[1])
		if value<=raw+0.00001:best=value
	return best

## "one part in twenty", "two parts in five".
static func rate_words(rate:float)->String:
	for f:Array in FRACTIONS:
		if absf(float(f[0])/float(f[1])-rate)<0.0005:
			var top:=int(f[0]);var bottom:=int(f[1])
			return "%s %s in %s" % [String(NUMBER_WORDS.get(top,str(top))),"part" if top==1 else "parts",String(NUMBER_WORDS.get(bottom,str(bottom)))]
	return "%d in 100" % roundi(rate*100.0)

## The share of what is reached that is hidden or never paid: more under a
## heavier levy and a distrusted ruler, less with settled custom and a good
## treasurer (office_levers.gd: -4 to +6 in 100).
static func evasion(rate:float,cap:float)->float:
	var s=WorldSimulation.state
	var legitimacy:=clampf(float(s.simulation_metrics.get("legitimacy",0.5)),0.0,1.0)
	var institutions:=clampf(float(s.society_capacities.get("institutions",0.25)),0.0,1.0)
	return clampf(0.04+rate/maxf(0.01,cap)*0.12+(1.0-legitimacy)*0.12-institutions*0.06-Levers.value("Treasurer"),0.02,0.45)

## How heavily a levy weighs, 0..0.8: nothing for a light one custom expects.
static func burden(rate:float,cap:float)->float:
	return clampf(rate/maxf(0.01,cap)-LEVY_FREE_SHARE,0.0,0.8)

## The levy's weight on the people's goodwill now (economy_system social
## pressure): trust in the chiefs takes it whole, holding together 0.55 of it.
static func levy_pressure()->float:
	var purse:Dictionary=WorldSimulation.state.realm_purse
	if purse.is_empty() or not bool(WorldSimulation.state.settlement_site_committed):return 0.0
	return burden(float(purse.get("rate",0.0)),float(purse.get("cap",0.10)))*LEVY_TRUST

## The share of their work households give up to the levy now (the welfare
## drag the economy's household reading takes).
static func take()->float:
	var purse:Dictionary=WorldSimulation.state.realm_purse
	return 0.0 if purse.is_empty() else clampf(float(purse.get("take",0.0)),0.0,0.5)

static func _refresh_rate(purse:Dictionary)->void:
	if String(WorldSimulation.state.resource_settlement_id)!="":return
	purse["stage"]=String(WorldSimulation.state.economy_stage)
	purse["cap"]=cap_now()
	purse["rate"]=level_rate(String(purse.levy),float(purse.cap))
	purse["take"]=float(purse.rate)*reach()*(1.0-evasion(float(purse.rate),float(purse.cap)))
	_sync_unit(purse)
	# The economy's old statutory rate follows the realm's levy.
	WorldSimulation.state.tax_rate=float(purse.rate)

## A level as the engine takes it now: {level, name, rate, words, reach,
## evasion, take, per_day, per_season, trust, cohesion, hidden_one_in}.
static func quote(level:String)->Dictionary:
	var cap:=cap_now()
	var rate:=level_rate(level,cap)
	var r:=reach()
	var ev:=evasion(rate,cap)
	var take_share:=rate*r*(1.0-ev)
	var output:=output_per_day()
	var weight:=burden(rate,cap)*LEVY_TRUST
	return {"level":level,"name":String(LEVEL_NAMES.get(level,level)),"rate":rate,"cap":cap,"words":rate_words(rate),"reach":r,"evasion":ev,"take":take_share,
		"per_day":output*take_share,"per_season":output*take_share*SEASON_DAYS,"trust":weight*100.0,"cohesion":weight*55.0,"hidden_one_in":maxi(2,roundi(1.0/maxf(0.01,ev)))}

## The levy in the place whose economy runs now (EconomySystem.process_day,
## in each town's own scope, the capital's first): the share of what it
## brought in that the realm's hands reach, less what is hidden, in the
## purse's unit. After coinage the share of it on goods sold for money is
## paid in coin, with its backing. The rest is taken in kind: goods out of
## this town's stores beyond its homes' need (what a town
## without that much cannot give is left with it: "short"). Returns the
## day's account for the economy's report.
static func accrue(real_accounts:Dictionary,monetization:float)->Dictionary:
	var s=WorldSimulation.state
	var purse:=state()
	_sweep_treasury(purse)
	var out:={"levy":0.0,"assessed":0.0,"evaded":0.0,"coin":0.0,"rich":0.0,"rate":float(purse.get("rate",0.0)),"reach":0.0,"evasion":0.0,"output":0.0,"short":0.0,"charter":0.0}
	if not bool(s.settlement_site_committed) or bool(s.convoy_traveling):return out
	if float(purse.get("rate",0.0))<=0.0:_refresh_rate(purse)
	var span:=float(WorldSimulation.span)
	var output:=units(maxf(0.0,float(real_accounts.get("daily_output_value",0.0))))
	var rate:=float(purse.get("rate",0.0))
	var r:=reach()
	var ev:=evasion(rate,float(purse.get("cap",0.10)))
	var assessed:=output*rate*span
	var reached:=assessed*r
	var evaded:=reached*ev
	var rich:=rich_levy(output)*span
	var owed:=reached-evaded+rich
	var coin:=0.0
	# One draw on the households' coin a day, shared by the levy and any
	# charter fees: never more than COIN_DRAW of what they hold.
	var coin_cap:=maxf(0.0,float(s.private_currency))*COIN_DRAW
	if String(s.economy_stage)=="currency" and not in_kind() and owed>0.0:
		# Only what changes hands for money is paid in coin (the day's traded
		# goods at the share money settles); the rest of the harvest's share is
		# taken in kind. The coin never outruns the households' own purses.
		var exchanged:=maxf(0.0,float(real_accounts.get("observed_trade",0.0)))*clampf(monetization,0.0,1.0)
		coin=minf(minf(owed,exchanged*rate*r*(1.0-ev)*span),coin_cap)
		if coin>0.0:
			s.private_currency=float(s.private_currency)-coin
			s.currency_supply=maxf(0.0,float(s.currency_supply)-coin)
			_move_backing(s.monetary_reserve_metals,purse.backing,coin*BACKING_RATIO)
	var took:=_take_goods(owed-coin)
	var short:=float(took.short)
	var levy:=coin+float(took.taken)
	purse.balance=float(purse.balance)+levy
	purse.coin=float(purse.coin)+coin
	# Charter fees (or the state works' surplus): a share of the business
	# sector's part of the day's output, taken with the levy as far as the
	# keepers reach (enterprise.gd purse_rate). After coinage it is paid in
	# coin within the day's one draw on the households' coin (what the levy
	# left of it); the rest in kind, out of this town's own stores, never past
	# what it can spare.
	var charter:=0.0
	var fee_rate:=float(_business().call("purse_rate"))
	if fee_rate>0.0:
		var fee_owed:=output*float(_business().call("share"))*fee_rate*r*span
		var fee_coin:=0.0
		if String(s.economy_stage)=="currency" and not in_kind() and fee_owed>0.0:
			fee_coin=minf(fee_owed*clampf(monetization,0.0,1.0),maxf(0.0,coin_cap-coin))
			if fee_coin>0.0:
				s.private_currency=float(s.private_currency)-fee_coin
				s.currency_supply=maxf(0.0,float(s.currency_supply)-fee_coin)
				_move_backing(s.monetary_reserve_metals,purse.backing,fee_coin*BACKING_RATIO)
		var fee_goods:=_take_goods(fee_owed-fee_coin)
		charter=fee_coin+float(fee_goods.taken)
		purse.balance=float(purse.balance)+charter
		purse.coin=float(purse.coin)+fee_coin
		coin+=fee_coin
	var month:Dictionary=purse.month
	month.levy=float(month.levy)+levy;month.rich=float(month.rich)+rich;month.assessed=float(month.assessed)+assessed;month.evaded=float(month.evaded)+evaded
	month.output=float(month.output)+output*span;month.person_days=float(month.person_days)+float(s.population_exact)*span;month.coin=float(month.coin)+coin
	month["short"]=float(month.get("short",0.0))+short
	month["charter"]=float(month.get("charter",0.0))+charter
	# The state works' surplus is told apart from charter fees, by the stance
	# on the day it was taken (a change mid-month splits the month's line).
	if charter>0.0 and String(_business().call("stance"))=="state":month["state_surplus"]=float(month.get("state_surplus",0.0))+charter
	# Where it came from: each town's own day is levied in its own scope.
	if not month.get("towns") is Dictionary: month["towns"]={}
	var town_id:=String(s.resource_settlement_id)
	var town:Dictionary=(month.towns as Dictionary).get(town_id,{"levy":0.0,"evaded":0.0,"unreached":0.0,"short":0.0,"output":0.0,"people":0.0,"days":0.0})
	town.levy=float(town.levy)+maxf(0.0,levy-rich);town.evaded=float(town.evaded)+evaded;town.unreached=float(town.unreached)+assessed-reached
	town["short"]=float(town.get("short",0.0))+short
	town["charter"]=float(town.get("charter",0.0))+charter
	town.output=float(town.output)+output*span;town.people=float(town.people)+float(s.population_exact)*span;town.days=float(town.days)+span
	(month.towns as Dictionary)[town_id]=town
	out.merge({"levy":levy,"assessed":assessed,"evaded":evaded,"coin":coin,"rich":rich,"reach":r,"evasion":ev,"output":output,"short":short,"charter":charter},true)
	return out

## The business sector (enterprise.gd), loaded on first use: it preloads
## this script, so this one reaches it by path.
const ENTERPRISE_PATH:="res://scripts/enterprise.gd"
static var _business_script:GDScript
static func _business()->GDScript:
	if _business_script==null:_business_script=load(ENTERPRISE_PATH)
	return _business_script

## Charter fees (or the state works' surplus) a day at today's work and
## stance, in the purse's unit.
static func charter_per_day()->float:
	var rate:=float(_business().call("purse_rate"))
	if rate<=0.0:return 0.0
	return output_per_day()*float(_business().call("share"))*rate*reach()

## Taxing the rich (government_policy_catalog wealth_levy, while it holds):
## the richest fifth pay RICH_RATE of what their share of the day brings in.
static func rich_levy(output:float)->float:
	var strength:=clampf(-float(WorldSimulation.consequences.policy_effect("wealth_concentration")),0.0,0.35)
	if strength<=0.0:return 0.0
	var shares:Array=WorldSimulation.state.wealth_shares
	var top:=float(shares[4]) if shares.size()==5 else 0.35
	return output*top*RICH_RATE*strength/POLICY_STRENGTH

## Coin a town's old treasury still receives (museum fees, legacy paths) is
## the realm's: it leaves the town's circulation with its backing.
static func _sweep_treasury(purse:Dictionary)->void:
	var s=WorldSimulation.state
	var held:=float(s.public_treasury)
	if held<=0.0001:return
	s.public_treasury=0.0
	s.currency_supply=maxf(0.0,float(s.currency_supply)-held)
	_move_backing(s.monetary_reserve_metals,purse.backing,held*BACKING_RATIO)
	purse.balance=float(purse.balance)+held
	purse.coin=float(purse.coin)+held
	(purse.month as Dictionary).deposits=float(purse.month.deposits)+held


# --- What it costs -----------------------------------------------------------------

## Soldiers the pay is owed to: {at_arms, reserve} (home, field and garrison
## troops at arms; recruits, trainees, the hurt and missing in reserve).
static func soldiers()->Dictionary:
	var mc=WorldSimulation.military
	if mc==null:return {"at_arms":0,"reserve":0}
	var at_arms:=int(mc.home_army.get("troops",0))+int(mc.field_army_active_personnel())+int(mc.occupation_active_personnel())
	var all:=int(mc._mobilized_count())
	return {"at_arms":at_arms,"reserve":maxi(0,all-at_arms)}

## What one person brings in a day, in the purse's unit (the month's own
## count when there is one, else today's towns).
static func output_per_head()->float:
	var purse:Dictionary=WorldSimulation.state.realm_purse
	var month:Dictionary=purse.get("month",{}) if not purse.is_empty() else {}
	if float(month.get("person_days",0.0))>=float(WorldSimulation.state.population_exact)*3.0:
		return maxf(0.05,float(month.output)/float(month.person_days))
	return maxf(0.05,output_per_day()/maxf(1.0,float(WorldSimulation.state.population_exact)))

## A town its people left (settlement_model.abandoned, dry_towns.gd): it
## earns, pays and eats nothing.
static func _left(city:Dictionary)->bool:
	return String(city.get("status",""))=="abandoned"

## What the whole realm brings in a day (each town's own reading), in the
## purse's unit.
static func output_per_day()->float:
	var s=WorldSimulation.state
	if String(s.resource_settlement_id)!="":return units(_output_of(s.economy_metrics))
	var total:=_output_of(s.economy_metrics)
	for city:Dictionary in s.player_settlements:
		if bool(city.get("primary",false)) or not String(city.get("occupied_by","")).is_empty() or _left(city):continue
		var local:Variant=city.get("local_resources",{})
		if local is Dictionary:total+=_output_of((local as Dictionary).get("economy_metrics",{}))
	return units(total)

static func _output_of(metrics:Variant)->float:
	if not metrics is Dictionary:return 0.0
	var real:Variant=(metrics as Dictionary).get("real_economy",{})
	return maxf(0.0,float((real as Dictionary).get("daily_output_value",0.0))) if real is Dictionary else 0.0

## What a line costs a day now (relief buys only what hungry towns need).
static func line_cost_per_day(line:String,oph:float=-1.0)->float:
	if oph<0.0:oph=output_per_head()
	var s=WorldSimulation.state
	match line:
		"army":
			var n:=soldiers()
			return (float(n.at_arms)*PAY_SOLDIER+float(n.reserve)*PAY_RESERVE)*oph
		# Wages are paid per head at the work (GameState.workers_at), never
		# for the extra work a great work's favour or a gifted person adds.
		"scholars":return maxf(0.0,float(s.workers_at("Knowledge")))*PAY_SCHOLAR*oph
		"crews":return maxf(0.0,float(s.workers_at("Construction")))*PAY_CREW*oph
	return 0.0

## Research pace while the scholars are kept (discovery_system progress).
static func scholars_factor()->float:
	var purse:Dictionary=WorldSimulation.state.realm_purse
	if purse.is_empty() or not bool((purse.get("lines",{}) as Dictionary).get("scholars",false)):return 1.0
	return 1.0+SCHOLARS_MAX*clampf(float((purse.get("funded",{}) as Dictionary).get("scholars",1.0)),0.0,1.0)

## Building pace added while crews are paid (settlement_construction daily work).
static func crews_bonus()->float:
	var purse:Dictionary=WorldSimulation.state.realm_purse
	if purse.is_empty() or not bool((purse.get("lines",{}) as Dictionary).get("crews",false)):return 0.0
	return CREWS_MAX*clampf(float((purse.get("funded",{}) as Dictionary).get("crews",1.0)),0.0,1.0)

## The share of the realm's output last month that pay put back in common
## hands (the economy's wealth shares read it: the chief's redistribution).
static func redistribution()->float:
	var purse:Dictionary=WorldSimulation.state.realm_purse
	return 0.0 if purse.is_empty() else clampf(float(purse.get("redistribution",0.0)),0.0,0.25)


# --- The ruler's levers --------------------------------------------------------------

## Sets the levy: {ok, changed, level, before, quote}.
static func set_levy(level:String)->Dictionary:
	var purse:=state()
	if not level in LEVELS:return {"ok":false,"error":"The levy is light, usual or heavy."}
	var before:=String(purse.levy)
	purse.levy=level
	_refresh_rate(purse)
	if before!=level:_note(purse,0.0,"The levy is now %s: %s" % [String(LEVEL_NAMES[level]).to_lower(),rate_words(float(purse.rate))],"levy")
	return {"ok":true,"changed":before!=level,"level":level,"before":before,"quote":quote(level)}

## One step lighter (-1) or heavier (+1).
static func step_levy(direction:int)->Dictionary:
	var at:=LEVELS.find(String(state().levy))
	var next:=clampi(at+signi(direction),0,LEVELS.size()-1)
	var result:=set_levy(String(LEVELS[next]))
	if next==at:result["at_end"]=true
	return result

## Turns a spending line on or off: {ok, changed, line, on, cost_per_season}.
static func set_line(line:String,on:bool)->Dictionary:
	var purse:=state()
	if not line in LINES:return {"ok":false,"error":"No such spending."}
	var lines:Dictionary=purse.lines
	var before:=bool(lines.get(line,false))
	lines[line]=on
	var today:=int(WorldSimulation.state.elapsed_days)
	if on and not before:
		(purse.line_days as Dictionary)[line]=today
		# They work in good faith until the month's reckoning says otherwise.
		(purse.funded as Dictionary)[line]=1.0
	if before!=on:_note(purse,0.0,"%s: %s" % [String(LINE_NAMES[line]),"on" if on else "off"],"line")
	return {"ok":true,"changed":before!=on,"line":line,"on":on,"cost_per_season":line_cost_per_day(line)*SEASON_DAYS}

static func line_on(line:String)->bool:
	return bool((state().lines as Dictionary).get(line,false))

## A computer ruler's or a screen's order: {kind:"purse", levy?, lines?}.
static func order(o:Dictionary)->Dictionary:
	var said:Array=[]
	if o.has("levy"):
		var r:=set_levy(String(o.levy))
		if not bool(r.get("ok",false)):return {"error":String(r.get("error",""))}
		said.append(r)
	var lines:Variant=o.get("lines",{})
	if lines is Dictionary:
		for line in lines:
			var r:=set_line(String(line),bool(lines[line]))
			if not bool(r.get("ok",false)):return {"error":String(r.get("error",""))}
			said.append(r)
	return {"ok":true,"results":said}


# --- The month's reckoning -------------------------------------------------------------

## Once a month (civilization_day.gd "purse" step; returns at once on other
## days and inside a town's day): the month's levy is told, and the purse
## pays for the month just past, as far as it holds out: old debts, the
## soldiers, food for hungry towns, crews, the scholars' keep.
static func settle(day:int)->Dictionary:
	var s=WorldSimulation.state
	if String(s.resource_settlement_id)!="":return {}
	var purse:=state()
	var last:=int(purse.get("last_settle_day",-1))
	if last<0 or last>day:
		purse.last_settle_day=day
		_refresh_rate(purse)
		return {}
	if floori(float(day)/MONTH_DAYS)<=floori(float(last)/MONTH_DAYS):return {}
	var days:=float(clampi(day-last,1,120))
	var month:Dictionary=purse.month
	var oph:=output_per_head()
	var report:={"day":day,"days":days,"levy":float(month.levy),"paid":{},"due":{},"army":{},"relief":{}}
	if float(month.levy)>0.0:
		_note(purse,float(month.levy),"The month's levy, %d in 100 of it hidden" % roundi(float(month.evaded)/maxf(0.001,float(month.assessed)*maxf(0.01,reach()))*100.0),"levy")
	# Charter fees (or the state works' surplus) came in with the levy: told
	# on their own line, so the record explains the balance.
	var surplus:=float(month.get("state_surplus",0.0))
	var fees:=maxf(0.0,float(month.get("charter",0.0))-surplus)
	if fees>0.0:_note(purse,fees,"The month's charter fees","charter")
	if surplus>0.0:_note(purse,surplus,"The month's surplus from the state works","charter")
	# The store's goods wear as the homes' own goods do.
	var worn:=_spoil(purse,days)
	if worn>=0.5:_note(purse,-worn,"Worn out in the store","out")
	if float(purse.debt)>0.0:
		var repay:=minf(float(purse.debt),float(purse.balance)*DEBT_SHARE)
		repay=_pay_out(purse,repay,"debts")
		purse.debt=maxf(0.0,float(purse.debt)-repay)
		if repay>0.0:_note(purse,-repay,"Old debts repaid to households","out")
	var lines:Dictionary=purse.lines
	var line_days:Dictionary=purse.line_days
	for line:String in LINES:
		var on:=bool(lines.get(line,false))
		var since:=maxi(last,int(line_days.get(line,last)))
		var worked:=float(clampi(day-since,0,120))
		match line:
			"army":
				var due:=line_cost_per_day("army",oph)*days
				month.army_due=due
				var paid:=_pay_out(purse,due,"army") if on else 0.0
				var unpaid:=clampf(1.0-paid/due,0.0,1.0) if due>0.01 else 0.0
				report.army=_army_reckoning(purse,unpaid,day,paid,due,on)
				report.due["army"]=due;report.paid["army"]=paid
				if paid>0.0:_note(purse,-paid,"The soldiers' pay, in %s" % pay_word(),"out")
			"relief":
				if on:
					var bought:=buy_relief(float(purse.balance)*RELIEF_SHARE,true)
					report.relief=bought
			"crews","scholars":
				if not on:continue
				var due:=line_cost_per_day(line,oph)*worked
				var paid:=_pay_out(purse,due,line)
				(purse.funded as Dictionary)[line]=clampf(paid/due,0.0,1.0) if due>0.01 else 1.0
				report.due[line]=due;report.paid[line]=paid
				if paid>0.0:_note(purse,-paid,"The scholars' keep" if line=="scholars" else "The crews' wages","out")
	_close_month(purse,days)
	purse.last_settle_day=day
	_refresh_rate(purse)
	return report

## The month told and kept (the last MONTHS_KEPT make the season), and what
## pay put back in common hands this month.
static func _close_month(purse:Dictionary,days:float)->void:
	var month:Dictionary=purse.month
	month["days"]=days
	var back:=0.0
	for line in REDISTRIBUTION_WEIGHT:back+=float(month.get(line,0.0))*float(REDISTRIBUTION_WEIGHT[line])
	purse.redistribution=clampf(back/maxf(1.0,float(month.output)),0.0,0.25)
	var months:Array=purse.months
	months.push_front(month.duplicate(true))
	if months.size()>MONTHS_KEPT:months.resize(MONTHS_KEPT)
	purse.month=_empty_month()

## Unpaid soldiers lose heart and some go home (MilitaryCampaign.pay_shortfall,
## bounded there); paid again, they take heart. Told once an episode.
static func _army_reckoning(purse:Dictionary,unpaid:float,day:int,paid:float,due:float,on:bool)->Dictionary:
	var mc=WorldSimulation.military
	var shortfall:=mc!=null and mc.has_method("pay_shortfall")
	if unpaid<=0.001:
		var was:=int(purse.unpaid_months)
		purse.unpaid_months=0
		if shortfall:mc.pay_shortfall(0.0,0,0.0)
		if was>0 and due>0.0:_tell("The soldiers are paid again","After %d %s short, the soldiers have their %s again: %s this month." % [was,"month" if was==1 else "months",pay_word(),amount_text(paid)],"purse_paid_%d" % day)
		purse.last_army={"day":day,"unpaid":0.0,"paid":paid,"due":due}
		return purse.last_army
	purse.unpaid_months=int(purse.unpaid_months)+1
	var result:Dictionary=mc.pay_shortfall(unpaid,int(purse.unpaid_months),float(purse.desertion_carry)) if shortfall else {}
	purse.desertion_carry=float(result.get("carry",0.0))
	var deserted:=int(result.get("deserted",0))
	purse.deserted=int(purse.deserted)+deserted
	purse.last_army={"day":day,"unpaid":unpaid,"paid":paid,"due":due,"months":int(purse.unpaid_months),"deserted":deserted,"will_lost":float(result.get("will_lost",0.0)),
		"readiness_before":float(result.get("readiness_before",0.0)),"readiness_after":float(result.get("readiness_after",0.0)),"chosen":not on}
	var why:="You stopped their pay" if not on else "%s ran short: %s of %s owed was paid" % [_cap(account_name()),amount_text(paid),amount_text(due)]
	if int(purse.unpaid_months)==1 or deserted>0:
		_tell("The soldiers go unpaid" if deserted==0 else "Unpaid soldiers desert","%s. Their will fell %d points%s." % [why,roundi(float(result.get("will_lost",0.0))*100.0),(" and %d went home" % deserted) if deserted>0 else ""],"purse_unpaid_%d" % day)
	return purse.last_army

static func _tell(title:String,text:String,key:String)->void:
	if WorldSimulation.actor_id!="player":return
	var chronicle:=load("res://scripts/chronicle.gd") as GDScript
	if chronicle!=null:chronicle.call("record",{"title":title,"text":text,"tier":"notice","kind":"war","key":key,"action":{"kind":"section","section":"economy","sub":2}})

static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)


# --- Paying out ------------------------------------------------------------------------

## Pays `amount` (or what is left) out of the purse to the realm's own people:
## coin to households where people live, by their share of the people, with
## its backing; the rest goods from the common store. `to` names the
## one place paid (relief bought from a town pays that town's sellers).
static func _pay_out(purse:Dictionary,amount:float,line:String,to:Dictionary={})->float:
	var paid:=minf(maxf(0.0,amount),maxf(0.0,float(purse.balance)))
	if paid<=0.0001:return 0.0
	var coin:=_coin_part(purse,paid)
	purse.balance=maxf(0.0,float(purse.balance)-paid)
	if coin>0.0:_scatter_coin(purse,coin,to)
	# The rest is goods from the store, back in the hands of those paid.
	_hand_out(paid-coin,to)
	var month:Dictionary=purse.month
	month[line]=float(month.get(line,0.0))+paid
	return paid

## What wears out of the store's goods over `days`, at the homes' own wear
## on goods (civilian_goods.gd daily_wear): taken off the balance and kept in
## the month. Returns it.
static func _spoil(purse:Dictionary,days:float)->float:
	var goods:=maxf(0.0,float(purse.balance)-float(purse.coin))
	if goods<=0.0 or days<=0.0:return 0.0
	var lost:=goods*_wear(days)
	purse.balance=maxf(float(purse.coin),float(purse.balance)-lost)
	var month:Dictionary=purse.month
	month["spoiled"]=float(month.get("spoiled",0.0))+lost
	return lost

## The share of the store's goods that wears out in `days`.
static func _wear(days:float)->float:
	return 1.0-pow(1.0-clampf(Goods.daily_wear(),0.0,1.0),maxf(0.0,days))

## The coin in a payment: the purse pays coin and goods in the share it holds them.
static func _coin_part(purse:Dictionary,amount:float)->float:
	var held:=float(purse.balance)
	if held<=0.0001:return 0.0
	return minf(float(purse.coin),amount*clampf(float(purse.coin)/held,0.0,1.0))

static func _scatter_coin(purse:Dictionary,coin:float,to:Dictionary={})->void:
	var places:=_places()
	var paid_to:Array=[]
	if not to.is_empty():
		for place:Dictionary in places:
			if bool(place.primary)==bool(to.get("primary",false)) and (bool(place.primary) or String((place.record as Dictionary).get("id",""))==String(to.get("id",""))):paid_to=[place]
	if paid_to.is_empty():paid_to=places
	var coined:=paid_to.filter(func(p:Dictionary)->bool:return String((p.local as Dictionary).get("economy_stage",""))=="currency")
	purse.coin=maxf(0.0,float(purse.coin)-coin)
	if coined.is_empty():
		# No household of ours keeps coin there: the metal goes into the stores.
		WorldSimulation.state.resource_stockpiles["Coin"]=float(WorldSimulation.state.resource_stockpiles.get("Coin",0.0))+coin
		_move_backing(purse.backing,{},coin*BACKING_RATIO)
		return
	var total:=0.0
	for place:Dictionary in coined:total+=maxf(0.0001,float(place.share))
	for place:Dictionary in coined:
		var part:=coin*maxf(0.0001,float(place.share))/total
		var local:Dictionary=place.local
		local["private_currency"]=float(local.get("private_currency",0.0))+part
		local["currency_supply"]=float(local.get("currency_supply",0.0))+part
		var reserve:Variant=(WorldSimulation.state.monetary_reserve_metals if bool(place.primary) else local.get("monetary_reserve_metals",{}))
		if reserve is Dictionary:_move_backing(purse.backing,reserve,part*BACKING_RATIO)
		_store(place)

## Each place that keeps its own money: {record, local, primary, share}. A
## town's local is its own resource record; the capital's a copy of its money
## fields on the people's state, written back by _store().
static func _places()->Array:
	var s=WorldSimulation.state
	var out:Array=[]
	var towns_share:=0.0
	var capital_record:Dictionary={}
	for city:Dictionary in s.player_settlements:
		if bool(city.get("primary",false)):capital_record=city;continue
		if not String(city.get("occupied_by","")).is_empty() or _left(city):continue
		var local:Variant=city.get("local_resources",{})
		if not local is Dictionary or (local as Dictionary).is_empty():continue
		var share:=maxf(0.0,float(city.get("population_share",0.0)))
		towns_share+=share
		out.append({"record":city,"local":local,"primary":false,"share":share})
	var capital:={}
	for field in MONEY_FIELDS:capital[field]=s.get(field)
	out.push_front({"record":capital_record,"local":capital,"primary":true,"share":maxf(0.01,1.0-minf(towns_share,0.99))})
	return out

static func _store(place:Dictionary)->void:
	if not bool(place.primary):return
	for field in MONEY_FIELDS:WorldSimulation.state.set(field,(place.local as Dictionary)[field])

## Moves metal of `value` from one backing to another, each kind in turn
## (into `to` under its own name). Returns the value moved.
static func _move_backing(from:Dictionary,to:Dictionary,value:float)->float:
	var remaining:=maxf(0.0,value)
	var moved:=0.0
	var names:Array=from.keys()
	names.sort()
	for metal in names:
		if remaining<=0.000001:break
		var held:=maxf(0.0,float(from.get(metal,0.0)))
		var taken:=minf(held,remaining)
		if taken<=0.0:continue
		from[metal]=held-taken
		if float(from[metal])<=0.000001:from.erase(metal)
		to[metal]=float(to.get(metal,0.0))+taken
		remaining-=taken
		moved+=taken
	return moved


# --- Food for the hungry ------------------------------------------------------------------

## Whether the people trade at known prices (comparison values recorded):
## only then can the purse buy food at the market price.
static func market_open()->bool:
	return int(WorldSimulation.state.economy_metrics.get("price_observations",0))>0

## Each town's food: [{id, name, primary, record, days, need, food, price,
## goods_price, position}] (prices at the town's own market).
static func food_places()->Array:
	var s=WorldSimulation.state
	var out:Array=[]
	for city:Dictionary in s.player_settlements:
		# An empty place (dry_towns.gd) neither buys nor sells food.
		if not String(city.get("occupied_by","")).is_empty() or _left(city):continue
		var primary:=bool(city.get("primary",false))
		var metrics:Dictionary=s.simulation_metrics if primary else (city.get("resource_metrics",{}) as Dictionary)
		var local:Dictionary={} if primary else (city.get("local_resources",{}) as Dictionary)
		if not primary and local.is_empty():continue
		var stores:Dictionary=s.resource_stockpiles if primary else (local.get("resource_stockpiles",{}) as Dictionary)
		var prices:Dictionary=s.market_prices if primary else (local.get("market_prices",{}) as Dictionary)
		var need:=maxf(0.1,float(metrics.get("food_consumption",WorldSimulation.settlements._settlement_population(city))))
		out.append({"id":String(city.get("id","")),"name":String(city.get("name","")),"primary":primary,"record":city,"days":float(metrics.get("food_days",float(stores.get("Food",0.0))/need)),
			"need":need,"food":float(stores.get("Food",0.0)),"price":maxf(0.05,float(prices.get("Food",Prices.base("Food")))),"goods_price":maxf(0.05,float(prices.get(Goods.GOODS,Prices.base(Goods.GOODS)))),"position":city.get("position",Vector2.ZERO)})
	return out

## Food for hungry towns, up to `budget` from the purse: food bought from
## towns with food to spare, at the seller's own food price, paid with the
## store's goods (bartered, at the goods price) and, after coinage, coin in
## the share the purse holds them. The payment goes to the seller's
## households and stores; the food goes on the road to each hungry town.
## {spent, rations, deliveries:[{to, from, rations, price, days}], reason}:
## price is what a ration cost in the purse's unit. Nothing is sent without
## a hungry town; nothing is bought without a market and a town with food to
## sell.
static func buy_relief(budget:float,standing:=false)->Dictionary:
	var purse:=state()
	var out:={"spent":0.0,"rations":0.0,"deliveries":[],"reason":""}
	var limit:=minf(maxf(0.0,budget),float(purse.balance))
	if limit<=0.01:out.reason="%s is empty" % account_name();return out
	var places:=food_places()
	var hungry:=places.filter(func(p:Dictionary)->bool:return float(p.days)<HUNGRY_DAYS)
	if hungry.is_empty():out.reason="no town is hungry; every town has %d days of food or more" % int(HUNGRY_DAYS);return out
	hungry.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.days)<float(b.days))
	var speed:=maxf(4.0,float(WorldSimulation.settlements.city_trade_capacity().get("speed_km_per_day",8.0)))
	var month:Dictionary=purse.month
	var sellers:=places.filter(func(p:Dictionary)->bool:return float(p.days)>SELLER_DAYS)
	var bought:=0.0;var paid:=0.0
	if market_open() and not sellers.is_empty():
		for h:Dictionary in hungry:
			var want:=maxf(0.0,(RELIEF_TARGET-float(h.days))*float(h.need)-_incoming_food(String(h.id)))
			for seller:Dictionary in sellers:
				if want<=1.0 or limit<=0.01:break
				if String(seller.id)==String(h.id):continue
				var spare:=maxf(0.0,(float(seller.days)-SELLER_KEEP)*float(seller.need))
				# What a ration costs in the purse's unit at the seller's prices.
				var price:=float(seller.price)/(float(seller.goods_price) if in_kind() else 1.0)
				var quantity:=minf(want,minf(spare,limit/maxf(0.0001,price)))
				if quantity<1.0:continue
				var sold:float=WorldSimulation.settlements.with_city_resources(String(seller.id),func()->float:return WorldSimulation.food.issue_for_obligation(quantity,"relief","Sold for %s's hungry" % String(h.name)))
				if sold<=0.01:continue
				var cost:=minf(sold*price,float(purse.balance))
				_pay_seller(purse,cost,{"id":String(seller.id),"primary":bool(seller.primary)})
				month["relief"]=float(month.get("relief",0.0))+cost
				month.rations=float(month.rations)+sold
				var from_at:Vector2=seller.position if seller.position is Vector2 else Vector2.ZERO
				var to_at:Vector2=h.position if h.position is Vector2 else Vector2.ZERO
				var travel:=maxf(1.0,ceilf(from_at.distance_to(to_at)/speed))
				_ship(seller,h,sold,travel,"Bought for the hungry with %s, at %s %s a ration." % [account_name(),number(price),unit_word()])
				seller.days=float(seller.days)-sold/maxf(0.1,float(seller.need))
				limit-=cost;want-=sold;bought+=sold;paid+=cost
				out.spent=float(out.spent)+cost;out.rations=float(out.rations)+sold
				(out.deliveries as Array).append({"to":String(h.name),"from":String(seller.name),"rations":sold,"price":price,"days":travel})
	if paid>0.0:_note(purse,-paid,"Food bought for the hungry: %s rations" % number(bought),"out")
	if float(out.rations)<=0.0 and String(out.reason)=="":
		out.reason="there is no market yet" if not market_open() else ("no town of ours has food to sell" if sellers.is_empty() else "the towns with food to spare are already sending what they can")
	return out

## Pays a seller of food from the purse: coin and goods in the share it
## holds them, to that town's households and stores.
static func _pay_seller(purse:Dictionary,cost:float,to:Dictionary)->void:
	var coin:=_coin_part(purse,cost)
	purse.balance=maxf(0.0,float(purse.balance)-cost)
	if coin>0.0:_scatter_coin(purse,coin,to)
	_hand_out(cost-coin,to)

static func _incoming_food(town_id:String)->float:
	var total:=0.0
	for shipment:Dictionary in WorldSimulation.state.city_trade_shipments:
		if String(shipment.get("destination_id",""))==town_id and String(shipment.get("resource",""))=="Food":total+=float(shipment.get("quantity",0.0))
	return total

## The food goes on the road as a delivery between towns (settlement_model
## receive_city_trade_arrivals brings it in, as it does every delivery).
static func _ship(seller:Dictionary,buyer:Dictionary,quantity:float,travel:float,reason:String)->void:
	var s=WorldSimulation.state
	var shipment:={"id":s.next_city_trade_id,"source_id":String(seller.id),"source_name":String(seller.name),"destination_id":String(buyer.id),"destination_name":String(buyer.name),
		"resource":"Food","quantity":quantity,"departure_day":s.elapsed_days,"arrival_day":s.elapsed_days+travel,"travel_days":travel,"status":"in_transit","day":int(s.elapsed_days),
		"reason":reason}
	s.next_city_trade_id=int(s.next_city_trade_id)+1
	s.city_trade_shipments.append(shipment)


# --- Merging an older world's money ------------------------------------------------------

## Once, for a purse kept before the store held what it counted: the levy was
## only written down, never taken out of the towns' stores, and nothing in
## the tally rotted, so it grew for generations past anything held. What
## stays is a year of the levy at its own last pace (what a store filled
## from the levy and drawn on by pay could hold); the rest was never there,
## and the record says so. The months kept start again in the new unit.
static func _recount(purse:Dictionary)->void:
	purse.erase("recount")
	var coined:=String(WorldSimulation.state.economy_stage)=="currency"
	purse["unit"]="coin" if coined else "goods"
	var price:=goods_price()
	purse["book_price"]=price
	var said:=maxf(0.0,float(purse.balance)-float(purse.coin))
	var held:=said if coined else said/price
	# A year of the levy, from the months kept (the old unit, at today's price).
	var levy:=0.0;var days:=0.0
	for m in purse.get("months",[]):
		if m is Dictionary:levy+=float((m as Dictionary).get("levy",0.0));days+=float((m as Dictionary).get("days",float(MONTH_DAYS)))
	var year:=(levy/maxf(1.0,days)*365.0)*(1.0 if coined else 1.0/price)
	_refresh_rate(purse)
	year=maxf(year,float(quote(String(purse.levy)).per_day)*365.0)
	var kept:=minf(held,maxf(0.0,year))
	purse.balance=float(purse.coin)+kept
	purse.months=[]
	purse.month=_empty_month()
	if held-kept>=1.0:
		_note(purse,0.0,"Counted again: %s holds %s, not the %s the tallies said. The levy had been written down but never taken from the towns' stores." % [account_name(),amount_text(kept),number(held)],"recount")


## Once, on the first reading of an older world: every town's treasury, its
## public debt and the pay its soldiers were owed become the realm's. A
## treasury first repays what it owes its own households; what is left of the
## debt (and the soldiers' arrears) is the realm's to repay. Each treasury's
## coin leaves its town's circulation with the metal that backs it. Old civil
## arrears were each town's own upkeep, which the realm now pays: forgiven.
static func _merge_town_money(purse:Dictionary)->void:
	purse.migrated=true
	var merged:=0.0
	var places:=0
	for place:Dictionary in _places():
		var local:Dictionary=place.local
		var treasury:=maxf(0.0,float(local.get("public_treasury",0.0)))
		var debt:=maxf(0.0,float(local.get("public_debt",0.0)))
		var repay:=minf(treasury,debt)
		if repay>0.0:
			treasury-=repay;debt-=repay
			local["private_currency"]=float(local.get("private_currency",0.0))+repay
		purse.debt=float(purse.debt)+debt+maxf(0.0,float(local.get("military_arrears",0.0)))
		local["public_debt"]=0.0;local["military_arrears"]=0.0;local["civil_arrears"]=0.0
		local["public_treasury"]=0.0
		if treasury>0.0:
			local["currency_supply"]=maxf(0.0,float(local.get("currency_supply",0.0))-treasury)
			var reserve:Variant=(WorldSimulation.state.monetary_reserve_metals if bool(place.primary) else local.get("monetary_reserve_metals",{}))
			if reserve is Dictionary:_move_backing(reserve,purse.backing,treasury*BACKING_RATIO)
			purse.balance=float(purse.balance)+treasury
			purse.coin=float(purse.coin)+treasury
			merged+=treasury;places+=1
		_store(place)
	var rate:=float(WorldSimulation.state.tax_rate)
	purse.levy="light" if rate<0.045 else ("usual" if rate<=0.10 else "heavy")
	if merged>0.0:_note(purse,merged,"One town's treasury becomes the realm's account" if places==1 else "%d towns' treasuries become the realm's one account" % places,"in")
	if float(purse.debt)>0.0:_note(purse,0.0,"Old debts carried by the realm: %s" % number(float(purse.debt)),"debt")
	_refresh_rate(purse)


# --- Reading it -------------------------------------------------------------------------

## The last season's money in and out (the last three monthly reckonings, and
## this month so far): {in:{levy, rich, deposits}, out:{army, relief, crews,
## scholars, debts, spent, spoiled}, total_in, total_out, days, rations,
## army_due, short}.
static func season()->Dictionary:
	var purse:=state()
	var months:Array=[purse.month]+(purse.months as Array)
	var inn:={"levy":0.0,"rich":0.0,"charter":0.0,"deposits":0.0}
	var out:={"army":0.0,"relief":0.0,"crews":0.0,"scholars":0.0,"debts":0.0,"spent":0.0,"spoiled":0.0}
	var days:=float(clampi(int(WorldSimulation.state.elapsed_days)-int(purse.get("last_settle_day",0)),0,120))
	var rations:=0.0
	var army_due:=0.0
	var short:=0.0
	for index in months.size():
		var m:Dictionary=months[index]
		for key in inn:inn[key]=float(inn[key])+float(m.get(key,0.0))
		for key in out:out[key]=float(out[key])+float(m.get(key,0.0))
		rations+=float(m.get("rations",0.0));army_due+=float(m.get("army_due",0.0));short+=float(m.get("short",0.0))
		# The month under way counts its days so far (above); the rest their own.
		if index>0:days+=float(m.get("days",0.0))
	inn.levy=maxf(0.0,float(inn.levy)-float(inn.rich))
	var total_in:=0.0
	for key in inn:total_in+=float(inn[key])
	var total_out:=0.0
	for key in out:total_out+=float(out[key])
	return {"in":inn,"out":out,"total_in":total_in,"total_out":total_out,"days":days,"rations":rations,"army_due":army_due,"short":short}

## A season at today's settings: what comes in and goes out, line by line,
## in the purse's unit, with what the store's goods would wear out in a
## season at today's rate. {levy, rich, in, lines:{line:{on, per_season, who}}, rot,
## out, net, balance, seasons_left}.
static func forecast()->Dictionary:
	var purse:=state()
	var q:=quote(String(purse.levy))
	var oph:=output_per_head()
	var rich:=rich_levy(output_per_day())*SEASON_DAYS
	var lines:={}
	var out:=0.0
	var n:=soldiers()
	var s=WorldSimulation.state
	var who:={"army":"%s at arms, %s in drill" % [EraWords.grouped(int(n.at_arms)),EraWords.grouped(int(n.reserve))],
		"scholars":"%s at research" % EraWords.grouped(roundi(float(s.workers_at("Knowledge")))),
		"crews":"%s builders" % EraWords.grouped(roundi(float(s.workers_at("Construction")))),"relief":"towns under %d days of food" % int(HUNGRY_DAYS)}
	for line:String in LINES:
		var on:=bool((purse.lines as Dictionary).get(line,false))
		var per:=line_cost_per_day(line,oph)*SEASON_DAYS
		if line=="relief":per=float(season().out.relief)
		lines[line]={"on":on,"per_season":per,"who":String(who.get(line,""))}
		if on:out+=per
	var rot:=maxf(0.0,float(purse.balance)-float(purse.coin))*_wear(SEASON_DAYS)
	out+=rot
	var charter:=charter_per_day()*SEASON_DAYS
	var income:=float(q.per_season)+rich+charter
	var net:=income-out
	return {"levy":float(q.per_season),"rich":rich,"charter":charter,"in":income,"lines":lines,"rot":rot,"out":out,"net":net,"balance":float(purse.balance),"quote":q,
		"seasons_left":(float(purse.balance)/-net) if net<-0.01 else -1.0,"debt":float(purse.debt)}

## Where the purse's coming-in comes from, a season at the pace of the last
## months kept (the month under way when none is kept yet): each town's levy
## on what its people make, what households hid from it, what lay beyond the
## keepers' reach, what towns could not give (the keepers leave every home
## the goods it needs), the rich's levy and what other
## systems paid in. {towns:[{id, name, levy, evaded, unreached, short,
## people}], rich, deposits, evaded, unreached, short, coin_share}.
static func sources()->Dictionary:
	var purse:=state()
	var months:Array=(purse.months as Array).duplicate()
	if months.is_empty(): months=[purse.month]
	var days:=0.0
	var towns:={}
	var rich:=0.0; var deposits:=0.0; var coin:=0.0; var levy_all:=0.0; var charter:=0.0
	for m in months:
		if not m is Dictionary: continue
		var d:=float((m as Dictionary).get("days",float(MONTH_DAYS)))
		# The month under way: as many days as its towns have been levied.
		if is_same(m,purse.month):
			d=1.0
			for id in (m.get("towns",{}) as Dictionary): d=maxf(d,float(((m.towns as Dictionary)[id] as Dictionary).get("days",0.0)))
		days+=d
		rich+=float(m.get("rich",0.0)); deposits+=float(m.get("deposits",0.0)); coin+=float(m.get("coin",0.0)); levy_all+=float(m.get("levy",0.0))+float(m.get("charter",0.0)); charter+=float(m.get("charter",0.0))
		for id in (m.get("towns",{}) as Dictionary):
			var t:Dictionary=(m.towns as Dictionary)[id]
			var into:Dictionary=towns.get_or_add(String(id),{"levy":0.0,"evaded":0.0,"unreached":0.0,"short":0.0,"people":0.0,"days":0.0})
			for k in ["levy","evaded","unreached","short","people","days"]: into[k]=float(into[k])+float(t.get(k,0.0))
	var scale:=SEASON_DAYS/maxf(1.0,days)
	var out:Array=[]
	var evaded:=0.0; var unreached:=0.0; var short:=0.0
	for id in towns:
		var t:Dictionary=towns[id]
		var name:=String(WorldSimulation.state.settlement_name) if String(id)=="" else String(WorldSimulation.settlements.settlement_record(String(id)).get("name",String(id)))
		var row:={"id":String(id),"name":name,"levy":float(t.levy)*scale,"evaded":float(t.evaded)*scale,"unreached":float(t.unreached)*scale,"short":float(t.short)*scale,"people":roundi(float(t.people)/maxf(1.0,float(t.days)))}
		evaded+=float(row.evaded); unreached+=float(row.unreached); short+=float(row.short)
		out.append(row)
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.levy)>float(b.levy))
	return {"towns":out,"rich":rich*scale,"charter":charter*scale,"deposits":deposits*scale,"evaded":evaded,"unreached":unreached,"short":short,"coin_share":clampf(coin/maxf(0.001,levy_all),0.0,1.0) if levy_all>0.0 else 0.0,"days":days}

## What the purse would buy at today's food price, in rations (-1 with no
## market): the store's goods at the goods price, and its coin.
static func buys_rations()->float:
	if not market_open():return -1.0
	return goods_in_rations(held_goods())+float(state().coin)/food_price()


# --- Realm-wide news --------------------------------------------------------------------

## Whether a recurring economic condition may be told again now: one cooldown
## for the whole realm, however many towns meet it (economy_system.gd).
static func event_due(key:String,cooldown:int)->bool:
	var s=WorldSimulation.state
	var purse:Dictionary=s.realm_purse
	if purse.is_empty():purse=state()
	if not purse.get("events") is Dictionary:purse["events"]={}
	var events:Dictionary=purse.events
	var today:=int(s.elapsed_days)
	if int(events.get(key,-100000))+cooldown>today:return false
	events[key]=today
	if events.size()>64:
		var oldest:="";var at:=today
		for k in events:
			if int(events[k])<at:at=int(events[k]);oldest=String(k)
		if oldest!="":events.erase(oldest)
	return true
