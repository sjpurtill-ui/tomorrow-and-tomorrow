extends RefCounted
## Physical opening craft stocks. Knowledge permits work; it does not provide
## tools, bindings, containers, or fitted timber by itself.

const ORDER:= ["controlled_flaking","cordage","food_drying","smoking","hafted_tools","basketry","clay_shaping","pit_firing","clay_tempering","sealed_vessels","joinery"]
const PRODUCTS:={
	"controlled_flaking":"Flaked Stone Tools","cordage":"Cordage Bundles","hafted_tools":"Hafted Tool Sets",
	"food_drying":"Drying Mats","smoking":"Smoke Frames","basketry":"Woven Containers",
	"clay_shaping":"Unfired Clay Vessels","pit_firing":"Fired Clay Vessels",
	"clay_tempering":"Tempered Clay Vessels","sealed_vessels":"Sealed Clay Vessels",
	"joinery":"Joined Timber Components"
}
const TARGET_PER_PERSON:={
	"controlled_flaking":.030,"cordage":.040,"food_drying":.025,"smoking":.012,
	"hafted_tools":.020,"basketry":.025,
	"clay_shaping":.030,"pit_firing":.025,"clay_tempering":.022,"sealed_vessels":.018,"joinery":.015
}
const DECAY:={
	"Flaked Stone Tools":.004,"Cordage Bundles":.008,"Drying Mats":.010,"Smoke Frames":.006,
	"Hafted Tool Sets":.004,"Woven Containers":.003,
	"Unfired Clay Vessels":.020,"Fired Clay Vessels":.0005,"Tempered Clay Vessels":.0004,
	"Sealed Clay Vessels":.0006,"Joined Timber Components":.003
}
const RECIPES:={
	"controlled_flaking":{"rate":6.0,"inputs":{"Flint":.04}},
	"cordage":{"rate":8.0,"inputs":{"Fiber Plants":.05}},
	# Drying begins with woven surfaces rather than requiring the later basketry
	# discovery. Smoke frames are simple timber-and-stone supports; their use,
	# unlike their construction, still requires a maintained fire.
	"food_drying":{"rate":5.0,"inputs":{"Fiber Plants":.10}},
	"smoking":{"rate":3.0,"inputs":{"Timber":.12,"Stone":.05}},
	"hafted_tools":{"rate":3.0,"inputs":{"Flaked Stone Tools":.15,"Timber":.08,"Cordage Bundles":.08}},
	"basketry":{"rate":4.0,"inputs":{"Fiber Plants":.12,"Cordage Bundles":.04}},
	"clay_shaping":{"rate":5.0,"inputs":{"Clay":.10,"Freshwater":.03}},
	"pit_firing":{"rate":4.0,"inputs":{"Unfired Clay Vessels":1.0,"Timber":.06},"fire":true},
	"clay_tempering":{"rate":3.5,"inputs":{"Clay":.10,"Stone":.03,"Freshwater":.03,"Timber":.06},"fire":true},
	"sealed_vessels":{"rate":3.0,"inputs":{"Tempered Clay Vessels":1.0,"Fiber Plants":.03}},
	"joinery":{"rate":2.0,"inputs":{"Timber":.20,"Hafted Tool Sets":.03}}
}

static func empty_state()->Dictionary:
	return {"initialized":true,"last_day":-1,"report":{}}

static func data()->Dictionary:
	return WorldSimulation.state.opening_craft_practice

static func stock(item:String)->float:
	return maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get(item,0.0)))

static func target(id:String)->float:
	return maxf(.25,WorldSimulation.state.population_exact*float(TARGET_PER_PERSON[id]))

static func capital_reserve()->Dictionary:
	# Household stocks also supply the first local installation. A small city's
	# per-person target must not keep its stock permanently below one paid build.
	var state=WorldSimulation.state
	if not state.resource_settlement_id.is_empty():return {}
	var ops=preload("res://scripts/technology_operations.gd")
	var reserve:Dictionary={}
	for plant:String in ops.PLANTS:
		var spec:Dictionary=ops.PLANTS[plant]
		var record:Dictionary=ops.data().plants.get(plant,{})
		if int(record.get("installed",0))+int(record.get("building",0))>0:continue
		var ready:=true
		for gate:String in [String(spec.gate)]+spec.get("requires",[]):
			if gate not in state.known_discoveries or WorldSimulation.discovery.adoption(gate)<.25:ready=false;break
		if not ready:continue
		for item:String in spec.cost:
			if item in PRODUCTS.values():reserve[item]=maxf(float(reserve.get(item,0)),float(spec.cost[item]))
	return reserve

static func factor(id:String)->float:
	if id=="kiln_control":return clampf(preload("res://scripts/technology_operations.gd").service("kiln_heat")/4.0,0.0,1.0)
	if id=="lime_burning":
		var lime:=stock("Quicklime")+stock("Slaked Lime")+stock("Building Mortar")
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
	# These practices are services rather than durable craft stocks. Their health
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
	if id=="framed_construction":
		var best_condition:=0.0
		for plot:Dictionary in WorldSimulation.state.settlement_plots:
			if String(plot.get("form",""))!="timber_frame_hall":continue
			if String(plot.get("status","active")) in ["vacant","ruin","reclaimed","under_construction"]:continue
			best_condition=maxf(best_condition,clampf(float(plot.get("condition",0.0)),0.0,1.0))
		if best_condition<=0.0:return 0.0
		var population:=maxf(1.0,WorldSimulation.state.population_exact)
		var staffing:=WorldSimulation.state.effective_workers("Construction")/maxf(1.0,population*.03)
		return clampf(minf(best_condition,staffing),0.0,1.0)
	if not PRODUCTS.has(id):return 1.0
	var product:=String(PRODUCTS[id])
	if id=="clay_shaping":
		return clampf((stock(product)+stock("Fired Clay Vessels"))/target(id),0.0,1.0)
	return clampf(stock(product)/target(id),0.0,1.0)

static func ensure_initialized()->void:
	if bool(data().get("initialized",false)):return
	data().initialized=true

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
	for item:String in bills:bills[item]=minf(float(bills[item]),stock(item)*share/(share+.18))
	return bills

static func advance()->Dictionary:
	ensure_initialized()
	var day:=int(WorldSimulation.state.elapsed_days)
	if int(data().get("last_day",-1))==day:return data().get("report",{}).duplicate(true)
	var elapsed:=maxi(1,day-int(data().get("last_day",day-1)))
	data().last_day=day
	for product:String in DECAY:
		if stock(product)>0:
			WorldSimulation.state.resource_stockpiles[product]=stock(product)*pow(1.0-float(DECAY[product]),elapsed)
	var report:Dictionary={"workers":0.0,"made":{},"inputs":{},"coverage":{}}
	if WorldSimulation.state.settlement_site_committed and not WorldSimulation.state.convoy_traveling:
		var remaining:=maxf(0.0,WorldSimulation.state.effective_workers("Crafting")*.18)
		var reserve:=capital_reserve()
		var workshop_reserve:=workshop_input_reserve()
		for id:String in ORDER:
			if remaining<=.000001:break
			if id not in WorldSimulation.state.known_discoveries or WorldSimulation.discovery.adoption(id)<.1:continue
			var recipe:Dictionary=RECIPES[id]
			if bool(recipe.get("fire",false)) and not preload("res://scripts/fire_practice.gd").available():continue
			var product:=String(PRODUCTS[id]);var rate:=float(recipe.rate)
			var amount:=minf(remaining*rate,maxf(0.0,target(id)*1.20+float(reserve.get(product,0))-stock(product)))
			for item:String in recipe.inputs:
				amount=minf(amount,maxf(0.0,stock(item)-float(workshop_reserve.get(item,0)))/float(recipe.inputs[item]))
			if amount<=.000001:continue
			for item:String in recipe.inputs:
				var used:=amount*float(recipe.inputs[item])
				WorldSimulation.state.resource_stockpiles[item]=maxf(0.0,stock(item)-used)
				report.inputs[item]=float(report.inputs.get(item,0.0))+used
			WorldSimulation.state.resource_stockpiles[product]=stock(product)+amount
			report.made[product]=amount
			var work:=amount/rate;remaining-=work;report.workers+=work
	for id:String in ORDER:report.coverage[id]=factor(id)
	data().report=report
	WorldSimulation.military.workshop.record_household(report.made)
	WorldSimulation.discovery.refresh_operating_effects()
	return report.duplicate(true)

static func valid(value:Variant)->bool:
	if not value is Dictionary or not (value.get("initialized",false) is bool):return false
	var last:Variant=value.get("last_day",-1)
	if not (last is int or last is float) or not is_finite(float(last)) or float(last)<-1 or float(last)>1e12 or float(last)!=floorf(float(last)):return false
	if not value.get("report",{}) is Dictionary:return false
	return (value.report as Dictionary).size()<=4

static func valid_settlements(records:Variant)->bool:
	if not records is Array:return false
	for record:Variant in records:
		if not record is Dictionary or not record.get("local_resources",{}) is Dictionary:return false
		var local:Dictionary=record.get("local_resources",{})
		if not valid(local.get("opening_craft_practice",empty_state())):return false
	return true
