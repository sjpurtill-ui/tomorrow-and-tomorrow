extends RefCounted
## Read-only evidence of current stocks/lines/plants, never a lifetime output ledger.
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
static func capture(detailed:bool=false)->Dictionary:
	var state=WorldSimulation.state;var campaign=WorldSimulation.military
	var stocks:Dictionary={};var methods:Array=[];var lines:Array=[];var plants:Array=[]
	for recipe:Dictionary in I.PRODUCTS.values():
		for resource:String in [recipe.output]+recipe.get("co_products",{}).keys():
			var amount:=float(state.resource_stockpiles.get(resource,0))
			if amount>0:stocks[resource]=amount
	for item:String in I.PRODUCTS:
		if P.recipe(campaign,item).has("error"):continue
		var row:={"item":item,"gate":I.PRODUCTS[item].gate}
		if detailed:
			row["new_line_blockers"]=P.startup_blockers(campaign,item)
			row["electricity_per_batch"]=float(I.PRODUCTS[item].get("power",0))
		methods.append(row)
	for job:Dictionary in campaign.equipment_queue:
		if I.product(String(job.get("item",""))).is_empty():continue
		lines.append({"item":job.item,"reported_state":P.state(campaign,job),"completed_on_current_line":job.get("completed",0),"target_stock":job.get("target_stock",0),"progress_days":job.get("progress_days",0),"paused":job.get("paused",false)})
	var current:=int(Ops.data().last_day)==int(state.elapsed_days)
	var installed:=0;var building:=0
	for id:String in Ops.data().plants:
		var record:Dictionary=Ops.data().plants[id]
		installed+=int(record.installed);building+=int(record.building)
		plants.append({"id":id,"installed":record.installed,"building":record.building,"enabled":record.enabled,"running":record.get("running_units",0) if current else 0,"stored_energy":record.get("stored_energy",0)})
	var services:Dictionary={}
	for service:String in Ops.data().services:
		var available:=Ops.service(service)
		if available>0:services[service]=available
	var result:={"available_civilian_recipes":methods.size(),"civilian_lines":lines.size(),"manufactured_stock_kinds":stocks.size(),"installed_units":installed,"units_under_construction":building,"remaining_daily_services":services,"operations_ledger_current":current}
	var food:=preload("res://scripts/leader_personality.gd").food_constraints(state.simulation_metrics)
	result["food_shortage"]=food.food_shortage
	result["delivery_shortage"]=food.delivery_shortage
	result["production_food_blocked"]=preload("res://scripts/civilization_controller.gd").production_food_blocked(food)
	if detailed:
		result["recipes"]=methods;result["lines"]=lines;result["plants"]=plants;result["manufactured_stocks"]=stocks
		result["limits"]="Stocks may be acquired rather than produced. Completed counts cover retained current lines only. Reported line state is not guaranteed throughput. New-line blockers exclude electricity dispatch and line-slot capacity. Remaining daily services exclude work already consumed."
	return result
