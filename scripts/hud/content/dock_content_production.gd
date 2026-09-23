extends "res://scripts/hud/content/dock_content_base.gd"
var workshop:RefCounted
var selected_line:=-1
func meta()->Dictionary:
	return {"eyebrow":"WORKSHOPS & EQUIPMENT", "title":"Production", "serif":true, "subtabs":["ALL","CIVILIAN","MILITARY"]}
func _ensure_workshop()->void:
	if workshop==null:workshop=preload("res://scripts/hud/content/dock_content_military.gd").new(terrain,hud)
func tab(sub:int)->Dictionary:
	_ensure_workshop()
	# Civilian manufactures are one Civilian Goods stock made by households;
	# workshop lines and recipes are military only.
	if sub==1:
		var civilian:=_household_blocks()
		return {"blocks":civilian if not civilian.is_empty() else [{"type":"text","heading":"CIVILIAN GOODS","text":"No city holds civilian goods yet."}]}
	var snapshot:=MilitaryCampaign.production_lines_snapshot()
	var lines:Array=snapshot.lines
	var stocks:Dictionary={}
	for resource in ["Timber","Fiber Plants","Stone","Clay","Copper Ore"]:
		if float(GameState.resource_stockpiles.get(resource,0))>0:stocks[resource]=GameState.resource_stockpiles[resource]
	var result:={"blocks":[{"type":"production_queue","lines":lines,"total_lines":snapshot.lines.size(),"capacity":snapshot.capacity,"stocks":stocks,"selected":selected_line,"managed":bool(MilitaryCampaign.workshop.data.enabled),"owner":MilitaryCampaign.workshop.owner(),"status":MilitaryCampaign.workshop.data.status,"on_select":_select,"on_action":_action,"on_detail":workshop._open_workshop_job,
		"on_add":focused_action("ADD PRODUCTION LINE","Known products",workshop._equipment_catalog).on_press,
		"on_manage":focused_action("WORKSHOP MANAGEMENT","Delegation",workshop._workshop_management_report).on_press,
		"on_history":focused_action("PRODUCTION HISTORY","Completed output",_history).on_press},{"type":"actions","items":[focused_action("EQUIPMENT UPKEEP","Staff repairs and supply constraints",_repairs)]}]}
	if sub==0:result.blocks.append_array(_household_blocks())
	result.blocks.append_array(_workshop_availability())
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
		var count:=int(MilitaryCampaign.damaged_equipment[item])+preload("res://scripts/routine_military_upkeep.gd").pending(MilitaryCampaign,item)
		if count<=0:continue
		items.append({"name":item.replace("_"," ").capitalize(),"value":"%d sets in upkeep" % count,"detail":preload("res://scripts/routine_military_upkeep.gd").status(MilitaryCampaign,item)})
	return {"blocks":[{"type":"text","text":"No equipment needs repair."}]} if items.is_empty() else {"blocks":[{"type":"rows","heading":"STAFF-MANAGED REPAIRS","items":items}]}

func _household_blocks()->Array:
	var blocks:Array=[]
	for city:Dictionary in GameState.player_settlements:
		var rows:Array=SettlementModel.with_city_resources(String(city.id),func()->Array:
			return SettlementModel.with_local_population(func()->Array:return _household_rows()))
		if not rows.is_empty():blocks.append({"type":"rows","heading":"CIVILIAN GOODS · "+String(city.name).to_upper(),"note":"Everyday tools, containers and fittings · separate from workshop lines","items":rows})
	var techniques:Array=_technique_rows()
	if not techniques.is_empty():blocks.append({"type":"rows","heading":"HOUSEHOLD TECHNIQUES","note":"Adopted techniques raise output and act in proportion to goods coverage","items":techniques})
	return blocks

static func _household_rows()->Array:
	var goods=preload("res://scripts/civilian_goods.gd")
	var report:Dictionary=GameState.civilian_goods.get("report",{})
	var current:=int(GameState.civilian_goods.get("last_day",-1))==int(GameState.elapsed_days)
	var made:=float(report.get("made",0.0)) if current else 0.0
	var worn:=float(report.get("worn",0.0)) if current else 0.0
	var coverage:=goods.coverage()
	var reason:=String(report.get("reason","")) if current else ""
	if reason.is_empty():reason="Replenishing as needed"
	return [{"name":"Civilian Goods","value":"%+.2f today" % (made-worn),"sub":"%.1f held of %.1f wanted (%d%%) · %s" % [goods.stock(),goods.target(),roundi(coverage*100.0),reason],"accent":Tokens.GREEN if coverage>=.8 else Tokens.AMBER}]

static func _technique_rows()->Array:
	var goods=preload("res://scripts/civilian_goods.gd")
	var rows:Array=[]
	for id:String in goods.TECHNIQUES:
		if id not in GameState.known_discoveries:continue
		var adoption:=DiscoverySystem.adoption(id)
		rows.append({"name":String(DiscoverySystem.discovery_definition(id).get("name",id.capitalize())),"value":"%d%% adopted" % roundi(adoption*100.0),"sub":"Acting at %d%% of its benefit" % roundi(adoption*goods.factor(id)*100.0),"accent":Tokens.GREEN if adoption>=.5 else Tokens.AMBER})
	return rows

func _workshop_availability()->Array:
	var production=preload("res://scripts/persistent_production.gd")
	var items:Array=[]
	for id:String in production.available_products(MilitaryCampaign):
		var blockers:Array=production.startup_blockers(MilitaryCampaign,id,{})
		items.append({"name":production.product_name(id),"sub":" · ".join(blockers) if not blockers.is_empty() else "Ready to order when needed","accent":Tokens.AMBER if not blockers.is_empty() else Tokens.GREEN})
		if items.size()>=6:break
	return [{"type":"rows","heading":"KNOWN WORKSHOP RECIPES","note":"Up to six recipes · use + for the full catalog. New lines need materials and setup tools.","items":items}] if not items.is_empty() else [{"type":"text","heading":"WORKSHOP RECIPES","text":"No workshop recipes are adopted in this category yet."}]
