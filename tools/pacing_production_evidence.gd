extends RefCounted
## Read-only campaign evidence, including recorded workshop output and current capacity.
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
		lines.append({"item":job.item,"reported_state":P.state(campaign,job),"completed_on_current_line":job.get("completed",0),"target_stock":job.get("target_stock",0),"progress_days":job.get("progress_days",0),"paused":job.get("paused",false),"pending_change":job.get("ai_turnover",{}).duplicate(true)})
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
	var military:Dictionary={}
	for item:String in campaign.EQUIPMENT_KNOWLEDGE:
		var ammunition:=String(campaign._ammunition_type_for(item))
		military[item]={"recipe_known":not P.recipe(campaign,item).has("error"),"stored":int(campaign.military_inventory.get(item,0)),"equipped":0,"ammunition_carried":0,"ammunition_required":0,"ammunition_stored":int(campaign.military_consumables.get(ammunition,0))}
	for force:Dictionary in [campaign.home_army]+campaign.field_armies+campaign.occupation_forces:
		for formation:Dictionary in force.get("formations",[]):
			var weapon:=String(formation.get("weapon",""))
			if military.has(weapon):
				military[weapon].equipped+=int(formation.get("equipment",0))
				military[weapon].ammunition_carried+=int(formation.get("ammunition",0))
				military[weapon].ammunition_required+=int(formation.get("ammunition_required",0))
	var household:Dictionary={}
	for product:String in preload("res://scripts/opening_craft_practice.gd").PRODUCTS.values():
		if float(state.resource_stockpiles.get(product,0))>0:household[product]=float(state.resource_stockpiles[product])
	var recorded:Dictionary={}
	for receipt:Dictionary in campaign.workshop.data.get("totals",{}).values():
		var resource:=String(receipt.resource)
		recorded[resource]=float(recorded.get(resource,0))+float(receipt.quantity)
	var result:={"lines":lines,"workforce":P.workforce(),"production_labor_share":campaign.production_labor_share,"recorded_output":recorded,"military_capabilities":military,"household_stocks":household,"available_civilian_recipes":methods.size(),"civilian_lines":lines.size(),"manufactured_stock_kinds":stocks.size(),"installed_units":installed,"units_under_construction":building,"remaining_daily_services":services,"operations_ledger_current":current}
	var government:=WorldSimulation.government
	var roster:={"recorded_people":government.people.size(),"active_roster":0,"officeholders":0,"central_officeholders":0,"settlement_leaders":0,"unappointed_candidates":0,"stage":government.government_stage}
	for person:Dictionary in government.people:
		if person.get("status","active")!="active":continue
		roster.active_roster+=1
		var central:=String(person.get("office_key",""))!=""
		var local:=String(person.get("local_leader_of",""))!=""
		roster.central_officeholders+=int(central)
		roster.settlement_leaders+=int(local)
		roster.officeholders+=int(central or local)
		roster.unappointed_candidates+=int(not central and not local)
	result["government"]=roster
	var food:=preload("res://scripts/leader_personality.gd").food_constraints(state.simulation_metrics)
	result["food_shortage"]=food.food_shortage
	result["delivery_shortage"]=food.delivery_shortage
	result["production_food_blocked"]=preload("res://scripts/civilization_controller.gd").production_food_blocked(food)
	if detailed:
		result["recorded_output_by_settlement"]=campaign.workshop.data.get("totals",{}).values().duplicate(true)
		result["land_training"]=campaign.training_queue.duplicate(true);result["recruits"]=campaign.aggregate_recruits;result["home_force"]=campaign.home_army.duplicate(true);result["field_forces"]=campaign.field_armies.duplicate(true)
		result["recipes"]=methods;result["lines"]=lines;result["plants"]=plants;result["manufactured_stocks"]=stocks
		result["limits"]="Stocks may be acquired rather than produced. Recorded output covers completed workshop production since tracking began and survives line changes; AI household crafts are not in that ledger. Current-line counts cover retained lines only. Reported line state is not guaranteed throughput. New-line blockers exclude electricity dispatch and line-slot capacity. Remaining daily services exclude work already consumed."
	return result
