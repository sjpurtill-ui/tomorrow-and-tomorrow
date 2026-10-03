extends RefCounted
## WEAPONS: arms for one fighter a set, made by makers from what is cut, dug
## and carried, and kept in store until the watch takes them up
## (docs/PEOPLE_FIRST.md D, docs/ECONOMY_SYSTEM.md "Goods, barter and arms").
##
## Arms are always dear. A set costs a maker many days and real materials
## (AGES: a spear and a bow early, bronze, iron, muskets and rifles later).
## Makers turn to arms only while the watch lacks them: ARMS_SHARE of the
## makers in peace, WAR_SHARE at war (every people by the same rule). Those
## makers give the whole day to arms: they make no household goods, and the
## rest of the makers' work (tools and materials, putting food by, the
## workshops) is short of them too (game_state.gd effective_workers reads
## civilian_goods.gd arms_hands).
##
## The store is "Arms" in each place's own stores (resource_stockpiles), one
## unit a set: the capital's and every town's. It wears as other durable
## things in a yard do (resource_system.gd's mineral rate, about 5 in 100 a
## year), and is priced by the economy (economy_system.gd BASE_VALUES). Only
## these made sets pass to other peoples (trade_ledger.gd GOODS), and only
## those beyond what the watch still lacks. The old armoury
## (military_campaign.gd military_inventory: spears, bows and the like not yet
## issued) arms the watch and counts as held for it, so an older save keeps
## every arm it had and nothing is moved on load; it is never traded, given
## or paid away.
##
## THE MILITARY'S API (call in the people's own scope, outside a town's day):
##   weapons_held()->int       whole sets held for the watch, realm-wide (made
##                             sets in every store, and the old armoury).
##   take_weapons(n)->int      takes up to n sets for the watch (made sets: the
##                             capital's first, then the towns'; then the old
##                             armoury, the cheapest kits first); exact: a part
##                             set left over stays in store. Returns how many.
##   return_weapons(n)->int    sets carried back into store (fighters stand
##                             down); never more than were taken.
##   lose_weapons(n)->int      sets lost with the fallen or in a rout.
##   weapons_issued()->int     sets the watch carries now (taken, less returned
##                             and lost). Stays 0 until the military calls
##                             take_weapons (workstream E).
##   cost_per_fighter()->Dictionary  what one set costs now: kind, maker_days,
##                             materials, goods_forgone, worth_goods,
##                             worth_rations, quality.
##   weapons_quality()->float  how good the arms our makers make now: 1 for a
##                             spear and a bow, up to 4 for automatic rifles.
##   arms_wanted()->int        sets still to be made: the watch, less what it
##                             carries and what is held.
## A fighter with no set fights with improvised arms. Static; preload.

const GOOD:="Arms"
## One fighter's arms by age: the best whose knowledge is held (adoption at a
## quarter, as elsewhere) and whose materials are in store. maker_days are
## days of one maker at full pace; quality is what the arms are worth in a
## fight against a spear and a bow.
const AGES:=[
	{"id":"stone","kind":"a spear and a bow","needs":"","maker_days":10.0,"materials":{"Timber":1.4,"Flint":0.3,"Fiber Plants":0.4},"quality":1.0},
	{"id":"bronze","kind":"a bronze spear, a shield and a bow","needs":"bronze_weaponry","maker_days":16.0,"materials":{"Timber":1.2,"Copper Ore":1.0,"Tin Ore":0.15,"Fiber Plants":0.3},"quality":1.35},
	{"id":"iron","kind":"an iron spear, a sword and a shield","needs":"bloomery_smelting","maker_days":14.0,"materials":{"Timber":1.0,"Iron Ore":1.4,"Coal":0.6},"quality":1.6},
	{"id":"firearms","kind":"a musket and a bayonet","needs":"matchlock_drill","maker_days":18.0,"materials":{"Iron Ore":2.0,"Timber":0.8,"Coal":1.2},"quality":2.2},
	{"id":"rifles","kind":"a rifle","needs":"metallic_cartridges","maker_days":9.0,"materials":{"Iron Ore":2.4,"Coal":2.0,"Timber":0.4},"quality":3.0},
	{"id":"automatic","kind":"an automatic rifle","needs":"automatic_actions","maker_days":7.0,"materials":{"Iron Ore":3.0,"Coal":2.5},"quality":4.0},
]
## Spear-and-bow arms take what is at hand: a missing one of these is made up
## from the others (flint from stone, cord from wood), as household goods are.
const STONE_BASKET:=["Timber","Flint","Stone","Fiber Plants"]
const STONE_WEIGHTS:={"Timber":1.4,"Flint":0.3,"Stone":0.15,"Fiber Plants":0.4}
## Sets the people want for each of the watch.
const ARMS_PER_WATCHER:=1.0
## The share of the makers on arms while the watch lacks them: in peace, at war.
const ARMS_SHARE:=0.2
const WAR_SHARE:=0.4
## The old armoury's kits that arm a fighter (equipment_ledger.gd families).
const ARMOURY_FAMILIES:=["hand","missile","firearm","mount"]

## The equipment rows (loaded when first read: the ledger reaches far into
## the game, and a preload here would tie every reader of goods to it).
static var _ledger_script:GDScript
static func _ledger()->GDScript:
	if _ledger_script==null:_ledger_script=load("res://scripts/equipment_ledger.gd") as GDScript
	return _ledger_script

# --- The record -----------------------------------------------------------------

## The realm's record of arms (the capital's own civilian goods record:
## saved with it; a town's record keeps only its own making).
static func record()->Dictionary:
	var goods:Dictionary=WorldSimulation.state.civilian_goods
	if not goods.get("arms") is Dictionary:goods["arms"]={}
	var r:Dictionary=goods.arms
	for key in ["issued","made","taken","returned","lost"]:
		if not r.has(key):r[key]=0.0
	return r

## The realm's plan for today, made in the people's own scope each morning
## (plan_day); kept per people for the towns' days (never saved).
static var _plans:={}

static func _owner()->String:
	return WorldSimulation.actor_id if String(WorldSimulation.actor_id)!="" else "player"

# --- Knowledge and cost ---------------------------------------------------------

static func _held(id:String)->bool:
	if id=="":return true
	return id in WorldSimulation.state.known_discoveries and WorldSimulation.discovery.adoption(id)>=0.25

## The best age whose knowledge is held (whatever is in store).
static func known_age()->Dictionary:
	var best:Dictionary=AGES[0]
	for age:Dictionary in AGES:
		if _held(String(age.needs)):best=age
	return best

static func _stock_of(item:String)->float:
	return maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get(item,0.0)))

## Materials the workshops' standing orders have claimed (civilian_goods.gd
## workshop_input_reserve), set for the length of one make().
static var _reserved:Dictionary={}

## What of a material arms may use: the store less the workshops' claim.
static func _usable(item:String)->float:
	return maxf(0.0,_stock_of(item)-float(_reserved.get(item,0.0)))

## Whether one set of this age can be made from the stores in scope.
static func _can_make(age:Dictionary)->bool:
	if String(age.id)=="stone":
		var raw:=0.0
		for item:String in STONE_BASKET:raw+=_usable(item)
		return raw>=_raw_per_set(age)
	for item:String in age.materials:
		if _usable(item)<float(age.materials[item]):return false
	return true

static func _raw_per_set(age:Dictionary)->float:
	var total:=0.0
	for item:String in age.materials:total+=float(age.materials[item])
	return total

## The age the makers make now: the best known whose materials are in store,
## else the best known lower one that can be made, else spear and bow.
static func making_age()->Dictionary:
	var known:=known_age()
	var index:=AGES.find(known)
	for i in range(index,-1,-1):
		if _can_make(AGES[i]):return AGES[i]
	return AGES[0]

## What arming one fighter costs now, in the engine's numbers: the maker-days
## at full pace, the materials, and its worth in goods. goods_forgone is the
## household goods those maker-days would have made (a slower people takes
## more days for a set but makes fewer goods a day: the pace cancels); the
## makers' other work lost that day (tools and materials, food put by, the
## workshops) is a cost beside it, not counted in goods.
static func cost_per_fighter()->Dictionary:
	var age:=known_age()
	var goods:=load("res://scripts/civilian_goods.gd") as GDScript
	var goods_rate:=float(goods.call("goods_per_maker_day_at_full_pace"))
	var goods_price:=_price("Civilian Goods")
	var materials_worth:=0.0
	for item:String in age.materials:materials_worth+=float(age.materials[item])*_price(item)
	var forgone:=float(age.maker_days)*goods_rate
	var worth_goods:=forgone+materials_worth/maxf(0.01,goods_price)
	return {"age":String(age.id),"kind":String(age.kind),"maker_days":float(age.maker_days),"materials":(age.materials as Dictionary).duplicate(),
		"goods_forgone":forgone,"worth_goods":worth_goods,"worth_rations":worth_goods*goods_price/maxf(0.01,_price("Food")),"quality":float(age.quality)}

static func weapons_quality()->float:
	return float(known_age().quality)

static func _price(item:String)->float:
	return preload("res://scripts/trade_prices.gd").in_scope(item)

# --- The store ------------------------------------------------------------------

## Made sets in the stores of the place in scope (fractions count toward the next).
static func stock()->float:
	return _stock_of(GOOD)

## The towns' stores (never the capital's; a town in its own day reads its
## own through stock()).
static func _town_stores()->Array:
	var out:Array=[]
	if WorldSimulation.settlements==null:return out
	for record_:Variant in WorldSimulation.state.player_settlements:
		if not record_ is Dictionary or bool((record_ as Dictionary).get("primary",false)):continue
		var local:Variant=(record_ as Dictionary).get("local_resources")
		if not local is Dictionary or not (local as Dictionary).get("resource_stockpiles") is Dictionary:continue
		var stores:Dictionary=(local as Dictionary).resource_stockpiles
		if is_same(stores,WorldSimulation.state.resource_stockpiles):continue
		out.append(stores)
	return out

## Made sets in every store of the realm (the capital's and the towns'); in a
## town's own day, that town's.
static func store_exact()->float:
	if String(WorldSimulation.state.resource_settlement_id)!="":return stock()
	var total:=stock()
	for stores:Dictionary in _town_stores():total+=maxf(0.0,float(stores.get(GOOD,0.0)))
	return total

## Sets in the old armoury not yet issued (kits that arm a fighter).
static func armoury_sets()->int:
	var military=WorldSimulation.military
	if military==null:return 0
	var inventory:Variant=military.get("military_inventory")
	if not inventory is Dictionary:return 0
	var total:=0
	for item:String in (inventory as Dictionary):
		if _arms_kit(item):total+=maxi(0,int(inventory[item]))
	return total

static func _arms_kit(item:String)->bool:
	if item=="improvised":return false
	if item.ends_with("_spear"):return true
	return String(_ledger().call("family",item)) in ARMOURY_FAMILIES

## Every set held for the watch, realm-wide, as a float: made sets and the old armoury.
static func held_exact()->float:
	return store_exact()+float(armoury_sets())

static func weapons_held()->int:
	return floori(held_exact()+0.000001)

static func weapons_issued()->int:
	var r:Variant=WorldSimulation.state.civilian_goods.get("arms")
	return maxi(0,roundi(float((r as Dictionary).get("issued",0.0)))) if r is Dictionary else 0

## Made sets another people could have: those beyond what the watch still
## lacks once the armoury and what it carries are counted (the trade ledger's
## holding of "Arms" and the economy's wanted holding read these two).
static func trade_holding()->float:
	return store_exact()

static func trade_wanted()->float:
	return maxf(0.0,watch()*ARMS_PER_WATCHER-float(weapons_issued())-float(armoury_sets()))

## Takes up to n whole sets for the watch, exactly: made sets first (the
## capital's, then the towns'), then the old armoury's kits, the cheapest
## first. A part set left when a kit makes up the last of it goes into the
## capital's store, so nothing is lost. Returns how many were taken.
static func take_weapons(n:int)->int:
	var want:=mini(maxi(0,n),weapons_held())
	if want<=0:return 0
	var left:=float(want)
	left-=_take_from(WorldSimulation.state.resource_stockpiles,left)
	for stores:Dictionary in _town_stores():
		if left<=0.000001:break
		left-=_take_from(stores,left)
	if left>0.000001:
		var kits:=ceili(left-0.000001)
		var got:=_take_from_armoury(kits)
		left-=float(got)
		# A whole kit covered a part set: the rest of it stays in store.
		if left<-0.000001:WorldSimulation.state.resource_stockpiles[GOOD]=stock()-left
	var r:=record()
	r.issued=float(r.issued)+want
	r.taken=float(r.taken)+want
	return want

static func _take_from(stores:Dictionary,amount:float)->float:
	var have:=maxf(0.0,float(stores.get(GOOD,0.0)))
	var out:=minf(have,amount)
	if out>0.0:stores[GOOD]=have-out
	return out

## A kit's worth for the order of drawing (its materials and its workshop days).
static func _kit_worth(item:String)->float:
	var row:Dictionary=_ledger().call("row",item)
	var worth:=float(row.get("days",1.0))*6.0
	var materials:Variant=row.get("materials",{})
	if materials is Dictionary:
		for material:String in (materials as Dictionary):worth+=float(materials[material])*preload("res://scripts/trade_prices.gd").base(material)
	return worth

static func _take_from_armoury(count:int)->int:
	var military=WorldSimulation.military
	if military==null or count<=0:return 0
	var inventory:Dictionary=military.military_inventory
	var items:Array=inventory.keys().filter(func(item:String)->bool:return _arms_kit(item) and int(inventory[item])>0)
	items.sort_custom(func(a:String,b:String)->bool:return _kit_worth(a)<_kit_worth(b) or (_kit_worth(a)==_kit_worth(b) and a<b))
	var taken:=0
	for item:String in items:
		if taken>=count:break
		var out:=mini(count-taken,maxi(0,int(inventory[item])))
		inventory[item]=int(inventory[item])-out
		taken+=out
	return taken

## Made sets that leave for another people (traded): the capital's first, then
## the towns'. Never the old armoury, never sets the watch carries. Returns
## what left.
static func remove(amount:float)->float:
	var want:=minf(maxf(0.0,amount),store_exact())
	if want<=0.000001:return 0.0
	var left:=want
	left-=_take_from(WorldSimulation.state.resource_stockpiles,left)
	for stores:Dictionary in _town_stores():
		if left<=0.000001:break
		left-=_take_from(stores,left)
	return want-maxf(0.0,left)

## Sets carried back into the capital's store.
static func return_weapons(n:int)->int:
	var r:=record()
	var back:=mini(maxi(0,n),weapons_issued())
	if back<=0:return 0
	WorldSimulation.state.resource_stockpiles[GOOD]=stock()+back
	r.issued=float(r.issued)-back
	r.returned=float(r.returned)+back
	return back

## Sets lost with the fallen or in a rout.
static func lose_weapons(n:int)->int:
	var r:=record()
	var gone:=mini(maxi(0,n),weapons_issued())
	r.issued=float(r.issued)-gone
	r.lost=float(r.lost)+gone
	return gone

# --- The plan: how many to make, and how many hands -------------------------------

## The watch: the people on keeping watch (the military's manpower).
static func watch()->float:
	return maxf(0.0,float(WorldSimulation.state.population_allocations.get("Defense",0)))

## At war or in a feud with any people, read the same from either side (the
## trade ledger's own test, trade_ledger.gd blocked: a war, or a feud hot on
## either side of it).
static func at_war()->bool:
	var ledger:=load("res://scripts/trade_ledger.gd") as GDScript
	if ledger==null:return false
	var owner:=_owner()
	for other:Variant in ledger.call("owners"):
		if String(other)==owner:continue
		if String(ledger.call("blocked",owner,String(other))) in ["war","feud"]:return true
	return false

## Sets still wanted: the watch's arms, less what it carries and what is held.
static func arms_wanted()->int:
	return maxi(0,ceili(watch()*ARMS_PER_WATCHER-0.000001)-weapons_issued()-weapons_held())

## The realm's plan, made each morning in the people's own scope (before any
## place makes anything): sets wanted, the share of makers on arms, and what
## the places have made toward it today.
static func plan_day()->Dictionary:
	if String(WorldSimulation.state.resource_settlement_id)!="":return plan()
	var wanted:=arms_wanted()
	var war:=wanted>0 and at_war()
	var share:=(WAR_SHARE if war else ARMS_SHARE) if wanted>0 else 0.0
	var p:={"day":int(WorldSimulation.state.elapsed_days),"wanted":wanted,"share":share,"war":war,"made":0.0}
	_plans[_owner()]=p
	var r:=record()
	r["plan"]={"wanted":wanted,"share":share,"war":war}
	return p

## Today's plan (made now when no place has made it yet today).
static func plan()->Dictionary:
	var p:Variant=_plans.get(_owner())
	if p is Dictionary and int((p as Dictionary).get("day",-1))==int(WorldSimulation.state.elapsed_days):return p
	var local:=WorldSimulation.settlements!=null and bool(WorldSimulation.settlements._local_population_scope)
	if String(WorldSimulation.state.resource_settlement_id)=="" and not local:return plan_day()
	return {"day":int(WorldSimulation.state.elapsed_days),"wanted":0,"share":0.0,"war":false,"made":0.0}

## One place's day of arms-making, from its own makers and stores (less what
## the workshops' standing orders have claimed: `reserve`). Returns {hands,
## sets, kind, inputs, reason}: `hands` makers spent the whole day on arms.
static func make(makers:float,efficiency:float,reserve:Dictionary={})->Dictionary:
	_reserved=reserve
	var out:=_make(makers,efficiency)
	_reserved={}
	return out

static func _make(makers:float,efficiency:float)->Dictionary:
	var out:={"hands":0.0,"sets":0.0,"kind":"","inputs":{},"reason":""}
	var p:=plan()
	var share:=float(p.get("share",0.0))
	var left:=float(p.get("wanted",0))-float(p.get("made",0.0))
	if share<=0.0 or left<=0.000001:
		out.reason="The watch has the arms it needs" if share<=0.0 else "Enough arms made today"
		return out
	if makers<=0.0 or efficiency<=0.0:
		out.reason="No makers"
		return out
	var age:=making_age()
	out.kind=String(age.kind)
	var span:=float(WorldSimulation.span)
	var work:=makers*share*efficiency*span
	var sets:=minf(work/float(age.maker_days),left)
	# Materials: what one set takes, from the stores in scope.
	if String(age.id)=="stone":
		var raw:=0.0
		for item:String in STONE_BASKET:raw+=_usable(item)
		sets=minf(sets,raw/_raw_per_set(age))
	else:
		for item:String in age.materials:sets=minf(sets,_usable(item)/float(age.materials[item]))
	# Only what the materials really drawn make.
	if sets>0.000001:sets=_draw(age,sets,out.inputs)
	if sets<=0.000001:
		out.reason="Needs %s" % _needs_words(age)
		return out
	WorldSimulation.state.resource_stockpiles[GOOD]=stock()+sets
	p["made"]=float(p.get("made",0.0))+sets
	out.sets=sets/span
	out.hands=sets*float(age.maker_days)/efficiency/span
	out.reason="Arming the watch"
	var r:=record()
	r.made=float(r.made)+sets
	return out

static func _needs_words(age:Dictionary)->String:
	var names:PackedStringArray=[]
	for item:String in (STONE_BASKET if String(age.id)=="stone" else (age.materials as Dictionary).keys()):names.append(String(item).to_lower())
	return ", ".join(names)

## Draws the materials for `sets` sets from the stores in scope; returns the
## sets they make (fewer when a material ran short).
static func _draw(age:Dictionary,sets:float,inputs:Dictionary)->float:
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	if String(age.id)!="stone":
		for item:String in age.materials:sets=minf(sets,_usable(item)/float(age.materials[item]))
		for item:String in age.materials:
			var used:=float(age.materials[item])*sets
			stocks[item]=maxf(0.0,_stock_of(item)-used)
			inputs[item]=float(inputs.get(item,0.0))+used
		return sets
	# Spear and bow: each by its weight in the set, a short one made up by the rest.
	var per_set:=_raw_per_set(age)
	var needed:=sets*per_set
	var drawn_all:=0.0
	for pass_index in 3:
		var weight_total:=0.0
		for item:String in STONE_BASKET:
			if _usable(item)>0.000001:weight_total+=float(STONE_WEIGHTS[item])
		if weight_total<=0.0 or needed<=0.000001:break
		var drawn_total:=0.0
		for item:String in STONE_BASKET:
			if _usable(item)<=0.000001:continue
			var drawn:=minf(_usable(item),needed*float(STONE_WEIGHTS[item])/weight_total)
			stocks[item]=_stock_of(item)-drawn
			inputs[item]=float(inputs.get(item,0.0))+drawn
			drawn_total+=drawn
		needed-=drawn_total
		drawn_all+=drawn_total
	return drawn_all/per_set
