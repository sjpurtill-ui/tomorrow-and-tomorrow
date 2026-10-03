extends RefCounted
## One aggregate stock of everyday made things: tools, bindings, containers,
## vessels, mats and fittings, counted in one unit (a goods-worth). Makers
## (Crafting) make it from a basket of what is cut, dug and carried;
## households wear it out. Discoveries such as basketry or pottery are
## techniques: once adopted they apply their listed effects in proportion to
## how well households are supplied (goods coverage), and they raise how much
## each maker makes and how much a household expects to hold.
##
## Goods are the first currency (docs/PEOPLE_FIRST.md D). Makers make for the
## homes first, then for barter: goods held beyond the homes' need change
## hands for food and materials at home (economy_system.gd, the barter stage)
## and buy resources, arms and people from other peoples (trade_ledger.gd
## goods_deal). A maker's output follows how well people work (the working
## efficiency, which carries the business sector's factor). While the watch
## lacks arms, some makers make arms instead (weapons_stock.gd): those hands
## make no household goods that day.

const Arms:=preload("res://scripts/weapons_stock.gd")
const GOODS:="Civilian Goods"
## Techniques that used to be individual household products. Order is the
## order they are listed in the production panel.
const TECHNIQUES:=["controlled_flaking","cordage","food_drying","smoking","hafted_tools","basketry","clay_shaping","pit_firing","clay_tempering","sealed_vessels","joinery"]
## Goods each person expects to hold once a technique is fully adopted.
const TARGET_PER_PERSON:={
	"controlled_flaking":.030,"cordage":.040,"food_drying":.025,"smoking":.012,
	"hafted_tools":.020,"basketry":.025,
	"clay_shaping":.030,"pit_firing":.025,"clay_tempering":.022,"sealed_vessels":.018,"joinery":.015
}
## Holding every household keeps before any technique is adopted.
const BASE_TARGET_PER_PERSON:=.02
## Share of the stock households use up each day.
const DAILY_WEAR:=.004
## Share of Crafting workers' time spent on household goods.
const CRAFT_SHARE:=.18
## Goods one maker makes in that time before techniques, at full working
## efficiency: four at the usual pace (REFERENCE_EFFICIENCY).
const BASE_RATE:=5.0
## The working efficiency read before the day's first reading exists.
const REFERENCE_EFFICIENCY:=.8
## Beyond the homes' need, makers make goods for barter up to this many
## goods-worth a head held, only from materials beyond BARTER_MATERIAL_FLOOR
## of what the stores want (the builders' share stays in store).
const SURPLUS_PER_HEAD:=4.0
const BARTER_MATERIAL_FLOOR:=.5
## A people of many makers splits the work and learns from itself: each maker
## makes up to SPECIALIZATION more once MAKERS_FULL of the people make, none
## at MAKERS_START or fewer (a balanced people), and the homes and market hold
## up to HOLD_MORE more goods a head. A little beyond history's best for a
## people all in on making and trade; its costs are the hands not on food,
## the watch or learning.
const SPECIALIZATION:=.15
const MAKERS_START:=.05
const MAKERS_FULL:=.20
const HOLD_MORE:=.5
## Output gained per fully adopted technique.
const TECHNIQUE_OUTPUT:=.05
## Raw materials per goods-unit and the basket they are drawn from. A missing
## material is replaced by the others; output stops only when all run out.
const RAW_PER_UNIT:=.16
const BASKET:={"Fiber Plants":.32,"Timber":.30,"Clay":.18,"Stone":.12,"Flint":.08}
## Food rations of sealed storage each unit of goods provides once sealed
## vessels are adopted, at the former vessel share of the household target.
const SEALED_STORAGE_SHARE:=.018/.267
const RATIONS_PER_SEALED_UNIT:=18.0
## Former product stocks folded into goods when an older save is loaded.
const LEGACY_PRODUCTS:=["Flaked Stone Tools","Cordage Bundles","Drying Mats","Smoke Frames","Hafted Tool Sets","Woven Containers","Unfired Clay Vessels","Fired Clay Vessels","Tempered Clay Vessels","Sealed Clay Vessels","Joined Timber Components"]

static func empty_state()->Dictionary:
	return {"initialized":true,"last_day":-1,"report":{}}

static func data()->Dictionary:
	return WorldSimulation.state.civilian_goods

static func stock()->float:
	return maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get(GOODS,0.0)))

static func _stock_of(item:String)->float:
	return maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get(item,0.0)))

## Goods the current population expects to hold, given adopted techniques.
static func target()->float:
	var per_person:=BASE_TARGET_PER_PERSON
	for id:String in TECHNIQUES:
		if id in WorldSimulation.state.known_discoveries:per_person+=float(TARGET_PER_PERSON[id])*clampf(WorldSimulation.discovery.adoption(id),0.0,1.0)
	return maxf(.25,WorldSimulation.state.population_exact*per_person)

## Stock relative to what households expect, 0 to 1.
static func coverage()->float:
	return clampf(stock()/target(),0.0,1.0)

## Output multiplier from adopted techniques.
static func technique_output()->float:
	var total:=1.0
	for id:String in TECHNIQUES:
		if id in WorldSimulation.state.known_discoveries:total+=TECHNIQUE_OUTPUT*clampf(WorldSimulation.discovery.adoption(id),0.0,1.0)
	return total

## Sealed food storage, in rations, provided by adopted sealed vessels.
static func sealed_storage_rations()->float:
	if "sealed_vessels" not in WorldSimulation.state.known_discoveries:return 0.0
	return stock()*SEALED_STORAGE_SHARE*RATIONS_PER_SEALED_UNIT*clampf(WorldSimulation.discovery.adoption("sealed_vessels"),0.0,1.0)

## How well people work today (the working efficiency, consequence_engine.gd;
## it carries the business sector's factor, enterprise.gd).
static func efficiency()->float:
	return clampf(float(WorldSimulation.state.simulation_metrics.get("labor_efficiency",REFERENCE_EFFICIENCY)),.2,1.6)

## Goods one maker makes a day now: CRAFT_SHARE of the day x BASE_RATE x
## techniques x how well people work.
static func goods_per_maker_day()->float:
	return goods_per_maker_day_at_full_pace()*efficiency()

## The same at full pace (working efficiency 1): what a maker-day of arms
## forgoes in goods (weapons_stock.gd cost_per_fighter).
static func goods_per_maker_day_at_full_pace()->float:
	return CRAFT_SHARE*BASE_RATE*technique_output()*specialization()

## Makers on arms in the place in scope (its latest day's making): they give
## the whole day to arms, so game_state.gd effective_workers("Crafting") leaves
## them out of every other making work. A record older than a week counts
## none.
static func arms_hands(state:Variant)->float:
	var goods:Variant=state.civilian_goods
	if not goods is Dictionary:return 0.0
	var report:Variant=(goods as Dictionary).get("report",{})
	if not report is Dictionary:return 0.0
	if int(state.elapsed_days)-int((goods as Dictionary).get("last_day",-99999))>7:return 0.0
	return maxf(0.0,float((report as Dictionary).get("arms_hands",0.0)))

## Every maker in scope, those on arms included.
static func makers()->float:
	return maxf(0.0,WorldSimulation.state.effective_workers("Crafting"))+arms_hands(WorldSimulation.state)

## The share of the people who make (Crafting).
static func makers_share()->float:
	return clampf(makers()/maxf(1.0,WorldSimulation.state.population_exact),0.0,1.0)

## How much more each maker makes when many make: 1 up to 1 + SPECIALIZATION.
static func specialization()->float:
	return 1.0+SPECIALIZATION*clampf((makers_share()-MAKERS_START)/(MAKERS_FULL-MAKERS_START),0.0,1.0)

## Goods held beyond the homes' need: what can change hands.
static func spare()->float:
	return maxf(0.0,stock()-target())

## The most goods the homes and the market hold before makers stop.
static func ceiling()->float:
	var many:=clampf((makers_share()-MAKERS_START)/(MAKERS_FULL-MAKERS_START),0.0,1.0)
	return target()*1.20+capital_reserve()+maxf(1.0,WorldSimulation.state.population_exact)*SURPLUS_PER_HEAD*(1.0+HOLD_MORE*many)

## What `amount` goods-worth is worth now in food (rations), at the people's
## own prices (trade_prices.gd, the one table).
static func worth_in_rations(amount:float=1.0)->float:
	var prices:=preload("res://scripts/trade_prices.gd")
	return amount*prices.in_scope(GOODS)/maxf(.01,prices.in_scope("Food"))

## What `amount` goods buy now at the people's own prices: {good: units}.
static func buys(amount:float,goods:Array=["Food","Timber","Stone","Fiber Plants"])->Dictionary:
	var prices:=preload("res://scripts/trade_prices.gd")
	var value:=amount*prices.in_scope(GOODS)
	var out:={}
	for good:String in goods:out[good]=value/maxf(.01,prices.in_scope(good))
	return out

## Takes goods from the stock for a use (learners' writing stuff and tools, a
## purchase): never more than is held. Returns what was taken.
static func draw(amount:float)->float:
	var taken:=minf(maxf(0.0,amount),stock())
	if taken>0.0:WorldSimulation.state.resource_stockpiles[GOODS]=stock()-taken
	return taken

static func capital_reserve()->float:
	# Goods also build the first local plant. A small city's household target must
	# not keep its stock permanently below one paid installation.
	var state=WorldSimulation.state
	if not state.resource_settlement_id.is_empty():return 0.0
	var ops=preload("res://scripts/technology_operations.gd")
	var reserve:=0.0
	for plant:String in ops.PLANTS:
		var spec:Dictionary=ops.PLANTS[plant]
		var record:Dictionary=ops.data().plants.get(plant,{})
		if int(record.get("installed",0))+int(record.get("building",0))>0:continue
		var ready:=true
		for gate:String in [String(spec.gate)]+spec.get("requires",[]):
			if gate not in state.known_discoveries or WorldSimulation.discovery.adoption(gate)<.25:ready=false;break
		if ready:reserve=maxf(reserve,float(spec.cost.get(GOODS,0.0)))
	return reserve

# Ids with a special factor below; techniques use goods coverage; others are 1.0.
const FACTOR_SPECIAL:={"kiln_control":true,"lime_burning":true,"lime_mortar":true,"latrine_siting":true,"protected_wellheads":true,"rainwater_cisterns":true,"water_settling_basins":true,"seed_selection":true,"animal_taming":true,"pack_animals":true,"domesticated_mounts":true,"mounted_scouts":true,"wound_cleaning":true,"clean_water":true,"public_stores":true,"framed_construction":true}

## Share of a discovery's listed effect that currently operates.
static func factor(id:String)->float:
	if not FACTOR_SPECIAL.has(id):return coverage() if id in TECHNIQUES else 1.0
	if id=="kiln_control":return clampf(preload("res://scripts/technology_operations.gd").service("kiln_heat")/4.0,0.0,1.0)
	if id=="lime_burning":
		var lime:=_stock_of("Quicklime")+_stock_of("Slaked Lime")+_stock_of("Building Mortar")
		return clampf(lime/maxf(.5,WorldSimulation.state.population_exact*.02),0.0,1.0)
	# Building techniques act through the city's built fabric: its construction
	# era must have reached masonry or framed halls, at its current condition.
	if id=="lime_mortar":
		var form:Dictionary=WorldSimulation.settlements.city_form()
		return clampf(float(form.condition),0.0,1.0) if float(form.tier)>=3.0 else 0.0
	if id in ["latrine_siting","protected_wellheads","rainwater_cisterns","water_settling_basins"]:
		return preload("res://scripts/water_waste_works.gd").factor(id)
	if id in ["seed_selection","animal_taming","pack_animals","domesticated_mounts","mounted_scouts"]:
		return preload("res://scripts/opening_opportunities.gd").practice_factor(id)
	# These practices are services rather than durable goods. Their health
	# effects operate only for the share of today's local population that received
	# the additional water their use requires. ResourceSystem records this after
	# drinking water has been allocated first.
	if id=="wound_cleaning":
		return clampf(float(WorldSimulation.state.water_metrics.get("wound_cleaning_coverage",0.0)),0.0,1.0)
	if id=="clean_water":
		return clampf(float(WorldSimulation.state.water_metrics.get("clean_water_coverage",0.0)),0.0,1.0)
	if id=="public_stores":
		if "Public Stores" not in WorldSimulation.state.settlement_completed:return 0.0
		var population:=maxf(1.0,WorldSimulation.state.population_exact)
		var logistics:=WorldSimulation.state.effective_workers("Logistics")/maxf(1.0,population*.04)
		var administration:=WorldSimulation.state.effective_workers("Administration")/maxf(1.0,population*.02)
		return clampf(minf(logistics,administration),0.0,1.0)
	# framed_construction: a Framed Hall stands and builders keep it in use.
	if "Framed Hall" not in WorldSimulation.state.settlement_completed:return 0.0
	var best_condition:=clampf(float(WorldSimulation.settlements.city_form().condition),0.0,1.0)
	var population:=maxf(1.0,WorldSimulation.state.population_exact)
	var staffing:=WorldSimulation.state.effective_workers("Construction")/maxf(1.0,population*.03)
	return clampf(minf(best_condition,staffing),0.0,1.0)

static func ensure_initialized()->void:
	if not bool(data().get("initialized",false)):data().initialized=true
	if not bool(data().get("migrated",false)):
		# Older saves hold the former household products as separate stocks.
		var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
		var folded:=0.0
		for item:String in LEGACY_PRODUCTS:
			if stocks.has(item):folded+=maxf(0.0,float(stocks[item]));stocks.erase(item)
		if folded>0.0:stocks[GOODS]=stock()+folded
		data().migrated=true

static func workshop_input_reserve()->Dictionary:
	# Household work and ordered production share crafting labor. When inputs
	# are scarce, household work must not consume the workshop's entire share
	# simply because it runs first. Only reserve actual outstanding recipe bills.
	if not WorldSimulation.state.resource_settlement_id.is_empty():return {}
	var host=WorldSimulation.military
	var share:=maxf(0.0,host.production_labor_share)
	if share<=0:return {}
	var bills:Dictionary={}
	for job:Dictionary in host.equipment_queue:
		if not bool(job.get("persistent",false)) or bool(job.get("paused",false)):continue
		if int(job.get("target_stock",0))>0 and host.PersistentProduction.stock(host,job)>=int(job.target_stock):continue
		var remaining:=clampf(1.0-float(job.get("progress_days",0))/maxf(.001,float(job.work_per_item)),0.0,1.0)
		for item:String in job.get("materials",{}):bills[item]=float(bills.get(item,0))+float(job.materials[item])*remaining
	for item:String in bills:bills[item]=minf(float(bills[item]),_stock_of(item)*share/(share+.18))
	return bills

## Share of the stock worn out each day today: DAILY_WEAR, slowed by the
## people's repair skill (research_mechanics.gd goods_wear_factor).
static func daily_wear()->float:
	return DAILY_WEAR*preload("res://scripts/research_mechanics.gd").goods_wear_factor()

## One day of household goods: wear since the last call, then the day's
## making. Arms come first while the watch lacks them (weapons_stock.gd);
## the other makers make for the homes, then for barter. A multi-day step
## (day_span.gd) makes `span` days of work.
static func advance()->Dictionary:
	ensure_initialized()
	var day:=int(WorldSimulation.state.elapsed_days)
	if int(data().get("last_day",-1))==day:return data().get("report",{}).duplicate(true)
	var elapsed:=maxi(1,day-int(data().get("last_day",day-1)))
	data().last_day=day
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	var worn:=stock()*(1.0-pow(1.0-daily_wear(),elapsed))
	if worn>0.0:stocks[GOODS]=stock()-worn
	var report:Dictionary={"workers":0.0,"made":0.0,"worn":worn/elapsed,"inputs":{},"coverage":0.0,"target":target(),"reason":"","for_barter":0.0,"worth":0.0,"per_maker":0.0,"arms_made":0.0,"arms_hands":0.0,"arms_kind":"","arms_inputs":{}}
	if not WorldSimulation.state.settlement_site_committed or WorldSimulation.state.convoy_traveling:
		report.reason="Needs a settled workplace"
	else:
		var all_makers:=makers()
		var pace:=efficiency()
		var reserve:=workshop_input_reserve()
		# Arms first, while the watch lacks them: those hands make no goods today.
		var arms:=Arms.make(all_makers,pace,reserve)
		report.arms_made=float(arms.sets);report.arms_hands=float(arms.hands);report.arms_kind=String(arms.kind);report.arms_inputs=arms.inputs
		var labor:=maxf(0.0,all_makers-float(arms.hands))*CRAFT_SHARE*WorldSimulation.span
		# Techniques, and how well people work (the business sector's factor included).
		var rate:=BASE_RATE*technique_output()*pace*specialization()
		report.per_maker=CRAFT_SHARE*rate
		var need:=maxf(0.0,float(report.target)*1.20+capital_reserve()-stock())
		var room:=maxf(0.0,ceiling()-stock())
		var spendable:Dictionary={}
		var raw_available:=0.0
		for item:String in BASKET:
			spendable[item]=maxf(0.0,_stock_of(item)-float(reserve.get(item,0)))
			raw_available+=float(spendable[item])
		if labor<=0.0:report.reason="No craftspeople assigned"
		elif room<=0.0:report.reason="Homes and the market are full"
		elif raw_available<=.000001:report.reason="Needs timber, fiber, clay, stone or flint"
		# For the homes first, from any material on hand.
		var for_homes:=_make_from(spendable,minf(minf(labor*rate,need),room),report.inputs)
		# Then for barter, only from what the builders' stores can spare.
		var for_barter:=0.0
		var left:=labor*rate-for_homes
		if left>.000001 and room-for_homes>.000001:
			var population:=maxf(1.0,WorldSimulation.state.population_exact)
			var beyond:Dictionary={}
			for item:String in BASKET:
				var floor_:=float(WorldSimulation.economy._desired_stock(item,population))*BARTER_MATERIAL_FLOOR if WorldSimulation.economy!=null else 0.0
				beyond[item]=minf(float(spendable[item]),maxf(0.0,_stock_of(item)-floor_))
			for_barter=_make_from(beyond,minf(left,room-for_homes),report.inputs)
			if for_barter<=.000001 and for_homes<=.000001 and report.reason=="" and need<=0.0:report.reason="No materials to spare for barter"
		var amount:=for_homes+for_barter
		if amount>.000001:
			stocks[GOODS]=stock()+amount
			report.made=amount/WorldSimulation.span
			report.for_barter=for_barter/WorldSimulation.span
			report.workers=amount/rate/WorldSimulation.span
			report.reason="Making goods for barter" if for_barter>.000001 else "Replenishing as needed"
		elif report.reason=="" and need<=0.0:report.reason="Stock target met"
	report.worth=worth_in_rations(float(report.made))
	report.coverage=coverage()
	data().report=report
	WorldSimulation.military.workshop.record_household({GOODS:float(report.made)})
	WorldSimulation.discovery.refresh_operating_effects()
	return report.duplicate(true)

## Makes up to `amount` goods from `spendable` (by basket weight among the
## materials on hand; a short one is covered by the rest), drawing from the
## stores. Returns what was made.
static func _make_from(spendable:Dictionary,amount:float,inputs:Dictionary)->float:
	var raw:=0.0
	for item:String in BASKET:raw+=float(spendable.get(item,0.0))
	amount=minf(amount,raw/RAW_PER_UNIT)
	if amount<=.000001:return 0.0
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	var needed:=amount*RAW_PER_UNIT
	for pass_index in 2:
		var weight_total:=0.0
		for item:String in BASKET:
			if float(spendable.get(item,0.0))>.000001:weight_total+=float(BASKET[item])
		if weight_total<=0.0 or needed<=.000001:break
		var drawn_total:=0.0
		for item:String in BASKET:
			if float(spendable.get(item,0.0))<=.000001:continue
			var drawn:=minf(float(spendable[item]),needed*float(BASKET[item])/weight_total)
			spendable[item]=float(spendable[item])-drawn
			stocks[item]=maxf(0.0,_stock_of(item)-drawn)
			inputs[item]=float(inputs.get(item,0.0))+drawn
			drawn_total+=drawn
		needed-=drawn_total
	return amount-maxf(0.0,needed)/RAW_PER_UNIT

## WHAT MAKING DOES, in the engine's numbers (for the People view,
## role_effects.gd): what the makers make now, and what ten more would make.
## {now, plus_ten} in twelve words or fewer each (the People view's lines),
## and `numbers`: goods a day now and with ten more, their worth in rations,
## goods per maker, arms a day now and with ten more, a set's cost.
static func role_effect(role:String="Crafting")->Dictionary:
	if role!="Crafting":return {}
	var report:Dictionary=data().get("report",{})
	var per:=goods_per_maker_day()
	var made:=float(report.get("made",0.0))
	var arms_now:=float(report.get("arms_made",0.0))
	var cost:=Arms.cost_per_fighter()
	var plan:=Arms.plan()
	var arms_ten:=10.0*float(plan.get("share",0.0))*efficiency()/maxf(.01,float(cost.maker_days)) if int(plan.get("wanted",0))>0 else 0.0
	var room:=maxf(0.0,ceiling()-stock())
	var goods_ten:=minf(10.0*per,room) if String(report.get("reason",""))!="Needs timber, fiber, clay, stone or flint" else 0.0
	var now:="%s goods a day, worth %s rations." % [_n(made),_n(worth_in_rations(made))]
	if arms_now>0.001:now="%s goods and arms for %s a day." % [_n(made),_n(arms_now)]
	var ten:="Ten more: about %s more goods a day." % _n(goods_ten)
	if arms_ten>0.001:ten="Ten more: %s more goods, or arms for %s more." % [_n(goods_ten),_n(arms_ten)]
	if goods_ten<=.001 and room<=0.0:ten="Ten more: nothing; homes and market hold all they can."
	return {"role":"Crafting","now":now,"plus_ten":ten,"ten_more":ten,"numbers":{"goods_day":made,"goods_day_ten_more":made+goods_ten,"worth_day":worth_in_rations(made),"per_maker":per,
		"arms_day":arms_now,"arms_day_ten_more":arms_now+arms_ten,"arms_cost_maker_days":float(cost.maker_days),"arms_cost_goods":float(cost.worth_goods),"stock":stock(),"spare":spare()}}

## The keeper's line of fact on making (court_facts.gd): goods made today and
## their worth, goods held and beyond the homes' use, arms in store against
## the watch, and what a set costs.
static func court_line()->String:
	var report:Dictionary=data().get("report",{})
	var made:=float(report.get("made",0.0))
	var cost:=Arms.cost_per_fighter()
	return "Making: %s goods made today, worth %s rations; %s goods held, %s beyond the homes' use. Arms in store for %d fighters; the watch is %d, carrying %d; arming one (%s) takes %s maker-days and goods worth %s." % [_n(made),_n(worth_in_rations(made)),_n(stock()),_n(spare()),Arms.weapons_held(),roundi(Arms.watch()),Arms.weapons_issued(),String(cost.kind),_n(float(cost.maker_days)),_n(float(cost.worth_goods))]

static func _n(value:float)->String:
	if value>=10.0:return str(roundi(value))
	return str(snappedf(value,0.1))

static func valid(value:Variant)->bool:
	if not value is Dictionary or not (value.get("initialized",false) is bool):return false
	var last:Variant=value.get("last_day",-1)
	if not (last is int or last is float) or not is_finite(float(last)) or float(last)<-1 or float(last)>1e12 or float(last)!=floorf(float(last)):return false
	if not value.get("report",{}) is Dictionary:return false
	if value.has("arms") and not value.arms is Dictionary:return false
	return (value.report as Dictionary).size()<=16

static func valid_settlements(records:Variant)->bool:
	if not records is Array:return false
	for record:Variant in records:
		if not record is Dictionary or not record.get("local_resources",{}) is Dictionary:return false
		var local:Dictionary=record.get("local_resources",{})
		if not valid(local.get("civilian_goods",empty_state())):return false
	return true
