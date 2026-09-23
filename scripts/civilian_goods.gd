extends RefCounted
## One aggregate stock of everyday made things: tools, bindings, containers,
## vessels, mats and fittings. Crafting workers make it from a basket of raw
## materials; households wear it out. Discoveries such as basketry or pottery
## are techniques: once adopted they apply their listed effects in proportion
## to how well households are supplied (goods coverage), and they raise how much
## each craftsperson makes and how much a household expects to hold.

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
## Goods one craftsperson makes in a day before techniques.
const BASE_RATE:=4.0
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
	if id=="lime_mortar":
		var best:=0.0
		for plot:Dictionary in WorldSimulation.state.settlement_plots:
			if String(plot.get("form",""))!="lime_masonry_household" or String(plot.get("status","active")) in ["ruin","reclaimed","under_construction"]:continue
			best=maxf(best,clampf(float(plot.get("condition",0.0)),0.0,1.0))
		return best
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
	# framed_construction
	var best_condition:=0.0
	for plot:Dictionary in WorldSimulation.state.settlement_plots:
		if String(plot.get("form",""))!="timber_frame_hall":continue
		if String(plot.get("status","active")) in ["vacant","ruin","reclaimed","under_construction"]:continue
		best_condition=maxf(best_condition,clampf(float(plot.get("condition",0.0)),0.0,1.0))
	if best_condition<=0.0:return 0.0
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

## One day of household goods: wear since the last call, then production.
## A multi-day step (day_span.gd) produces `span` days of craft work.
static func advance()->Dictionary:
	ensure_initialized()
	var day:=int(WorldSimulation.state.elapsed_days)
	if int(data().get("last_day",-1))==day:return data().get("report",{}).duplicate(true)
	var elapsed:=maxi(1,day-int(data().get("last_day",day-1)))
	data().last_day=day
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	var worn:=stock()*(1.0-pow(1.0-DAILY_WEAR,elapsed))
	if worn>0.0:stocks[GOODS]=stock()-worn
	var report:Dictionary={"workers":0.0,"made":0.0,"worn":worn/elapsed,"inputs":{},"coverage":0.0,"target":target(),"reason":""}
	if not WorldSimulation.state.settlement_site_committed or WorldSimulation.state.convoy_traveling:
		report.reason="Needs a settled workplace"
	else:
		var labor:=maxf(0.0,WorldSimulation.state.effective_workers("Crafting")*CRAFT_SHARE)*WorldSimulation.span
		var rate:=BASE_RATE*technique_output()
		var wanted:=maxf(0.0,float(report.target)*1.20+capital_reserve()-stock())
		var reserve:=workshop_input_reserve()
		var spendable:Dictionary={}
		var raw_available:=0.0
		for item:String in BASKET:
			spendable[item]=maxf(0.0,_stock_of(item)-float(reserve.get(item,0)))
			raw_available+=float(spendable[item])
		var amount:=minf(minf(labor*rate,wanted),raw_available/RAW_PER_UNIT)
		if labor<=0.0:report.reason="No craftspeople assigned"
		elif wanted<=0.0:report.reason="Stock target met"
		elif raw_available<=.000001:report.reason="Needs timber, fiber, clay, stone or flint"
		if amount>.000001:
			var needed:=amount*RAW_PER_UNIT
			# Draw by basket weight among the materials on hand; if one runs short,
			# the rest cover the remainder.
			for pass_index in 2:
				var weight_total:=0.0
				for item:String in BASKET:
					if float(spendable[item])>.000001:weight_total+=float(BASKET[item])
				if weight_total<=0.0 or needed<=.000001:break
				var drawn_total:=0.0
				for item:String in BASKET:
					if float(spendable[item])<=.000001:continue
					var drawn:=minf(float(spendable[item]),needed*float(BASKET[item])/weight_total)
					spendable[item]=float(spendable[item])-drawn
					stocks[item]=maxf(0.0,_stock_of(item)-drawn)
					report.inputs[item]=float(report.inputs.get(item,0.0))+drawn
					drawn_total+=drawn
				needed-=drawn_total
			amount-=maxf(0.0,needed)/RAW_PER_UNIT
			stocks[GOODS]=stock()+amount
			report.made=amount/WorldSimulation.span
			report.workers=amount/rate/WorldSimulation.span
			report.reason="Replenishing as needed"
	report.coverage=coverage()
	data().report=report
	WorldSimulation.military.workshop.record_household({GOODS:float(report.made)})
	WorldSimulation.discovery.refresh_operating_effects()
	return report.duplicate(true)

static func valid(value:Variant)->bool:
	if not value is Dictionary or not (value.get("initialized",false) is bool):return false
	var last:Variant=value.get("last_day",-1)
	if not (last is int or last is float) or not is_finite(float(last)) or float(last)<-1 or float(last)>1e12 or float(last)!=floorf(float(last)):return false
	if not value.get("report",{}) is Dictionary:return false
	return (value.report as Dictionary).size()<=8

static func valid_settlements(records:Variant)->bool:
	if not records is Array:return false
	for record:Variant in records:
		if not record is Dictionary or not record.get("local_resources",{}) is Dictionary:return false
		var local:Dictionary=record.get("local_resources",{})
		if not valid(local.get("civilian_goods",empty_state())):return false
	return true
