extends "res://scripts/hud/content/dock_content_base.gd"
var workshop:RefCounted
var selected_line:=-1
func meta()->Dictionary:
	return {"eyebrow":"WORKSHOPS & EQUIPMENT", "title":"Production", "serif":true, "subtabs":["ALL","CIVILIAN","MILITARY"]}
func _ensure_workshop()->void:
	if workshop==null:workshop=preload("res://scripts/hud/content/dock_content_military.gd").new(terrain,hud)
func tab(sub:int)->Dictionary:
	_ensure_workshop()
	var snapshot:=MilitaryCampaign.production_lines_snapshot()
	var lines:Array=snapshot.lines
	if sub>0:lines=lines.filter(func(line:Dictionary)->bool:return (String(line.get("job_type",""))=="civilian")==(sub==1))
	var stocks:Dictionary={}
	for resource in ["Timber","Fiber Plants","Stone","Clay","Copper Ore"]:
		if float(GameState.resource_stockpiles.get(resource,0))>0:stocks[resource]=GameState.resource_stockpiles[resource]
	var result:={"blocks":[{"type":"production_queue","lines":lines,"total_lines":snapshot.lines.size(),"capacity":snapshot.capacity,"stocks":stocks,"selected":selected_line,"managed":bool(MilitaryCampaign.workshop.data.enabled),"owner":MilitaryCampaign.workshop.owner(),"status":MilitaryCampaign.workshop.data.status,"on_select":_select,"on_action":_action,"on_detail":workshop._open_workshop_job,
		"on_add":focused_action("ADD PRODUCTION LINE","Known products",workshop._equipment_catalog).on_press,
		"on_manage":focused_action("WORKSHOP MANAGEMENT","Delegation",workshop._workshop_management_report).on_press,
		"on_history":focused_action("PRODUCTION HISTORY","Completed output",_history).on_press},{"type":"actions","items":[focused_action("EQUIPMENT REPAIRS","Restore damaged military equipment",_repairs)]}]}
	if sub!=2:result.blocks.append_array(_household_blocks())
	result.blocks.append_array(_workshop_availability(sub))
	return result
func _select(id:int)->void:
	selected_line=-1 if selected_line==id else id;hud.request_immediate_dock_refresh()
func _action(id:int,action:String,value:float)->void:
	var result:Dictionary={"error":"That line is no longer active."}
	for job:Dictionary in MilitaryCampaign.equipment_queue:
		if int(job.id)!=id:continue
		match action:
			"delegate":result=MilitaryCampaign.workshop.delegate_line(id)
			"pause":result=MilitaryCampaign.configure_production_line(id,int(job.target_stock),not bool(job.paused))
			"target":result=MilitaryCampaign.configure_production_line(id,int(value),bool(job.paused))
			"priority":
				result=MilitaryCampaign.configure_production_line(id,int(job.target_stock),bool(job.paused))
				if not result.has("error"):result=MilitaryCampaign.set_production_line_allocation(id,value)
		break
	terrain._report_military_action(result);hud.request_immediate_dock_refresh()
func _history()->Dictionary:
	return {"blocks":[{"type":"production_board","lines":[],"receipts":MilitaryCampaign.workshop.data.receipts,"totals":MilitaryCampaign.workshop.data.totals,"day":int(GameState.elapsed_days),"view_state":{"mode":1}}]}
func signature()->Array:
	return [MilitaryCampaign.production_lines_snapshot(),GameState.elapsed_days,selected_line,MilitaryCampaign.workshop.data.enabled,MilitaryCampaign.workshop.owner(),MilitaryCampaign.workshop.data.status]

func _repairs()->Dictionary:
	_ensure_workshop()
	var items:Array=[]
	for item:String in MilitaryCampaign.damaged_equipment:
		var count:=int(MilitaryCampaign.damaged_equipment[item])
		if count<=0:continue
		items.append(focused_action("REPAIR "+item.replace("_"," ").to_upper(),"%d damaged sets" % count,workshop._supply_order_report.bind("repair",item)))
	return {"blocks":[{"type":"text","text":"No equipment needs repair."}]} if items.is_empty() else {"blocks":[{"type":"actions","heading":"DAMAGED EQUIPMENT","items":items}]}

func _household_blocks()->Array:
	var blocks:Array=[]
	for city:Dictionary in GameState.player_settlements:
		var rows:Array=SettlementModel.with_city_resources(String(city.id),func()->Array:
			return SettlementModel.with_local_population(func()->Array:return _household_rows()))
		if not rows.is_empty():blocks.append({"type":"rows","heading":"HOUSEHOLD CRAFTS · "+String(city.name).to_upper(),"note":"Actual daily output · separate from workshop lines","items":rows})
	blocks.append({"type":"text","text":"Household crafts replenish tools, bindings and containers as people need them. Their output is now included in history; older lifetime totals were not recorded."})
	return blocks

static func _household_rows()->Array:
	var craft=preload("res://scripts/opening_craft_practice.gd")
	var made:Dictionary=GameState.opening_craft_practice.get("report",{}).get("made",{})
	var current:=int(GameState.opening_craft_practice.get("last_day",-1))==int(GameState.elapsed_days)
	var rows:Array=[]
	for id:String in craft.ORDER:
		if id not in GameState.known_discoveries:continue
		var product:=String(craft.PRODUCTS[id])
		var stock:=craft.stock(product)
		var amount:=float(made.get(product,0)) if current else 0.0
		var reason:="Replenishing as needed"
		if DiscoverySystem.adoption(id)<.1:reason="Practice not yet adopted"
		elif stock>=craft.target(id)*1.19:reason="Stock target met"
		elif GameState.convoy_traveling or not GameState.settlement_site_committed:reason="Needs a settled workplace"
		elif GameState.effective_workers("Crafting")<=0:reason="No craftspeople assigned"
		elif bool(craft.RECIPES[id].get("fire",false)) and not preload("res://scripts/fire_practice.gd").available():reason="Needs maintained fire"
		else:
			for input:String in craft.RECIPES[id].inputs:
				if craft.stock(input)<=.000001:reason="Needs "+input;break
		rows.append({"name":product,"value":"+%.3f today" % amount,"sub":"%.2f in stores · %s" % [stock,reason],"accent":Tokens.GREEN if amount>0 else Tokens.AMBER})
	return rows

func _workshop_availability(sub:int)->Array:
	var production=preload("res://scripts/persistent_production.gd")
	var industry=preload("res://scripts/civilian_industry.gd")
	var items:Array=[]
	for id:String in production.available_products(MilitaryCampaign):
		var civilian:=not industry.product(id).is_empty()
		if sub==1 and not civilian or sub==2 and civilian:continue
		var blockers:Array=production.startup_blockers(MilitaryCampaign,id,{})
		items.append({"name":production.product_name(id),"sub":" · ".join(blockers) if not blockers.is_empty() else "Ready to order when needed","accent":Tokens.AMBER if not blockers.is_empty() else Tokens.GREEN})
		if items.size()>=6:break
	return [{"type":"rows","heading":"KNOWN WORKSHOP RECIPES","note":"Up to six recipes · use + for the full catalog. New lines need materials and setup tools.","items":items}] if not items.is_empty() else [{"type":"text","heading":"WORKSHOP RECIPES","text":"No workshop recipes are adopted in this category yet."}]
