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
	return {"blocks":[{"type":"production_queue","lines":lines,"total_lines":snapshot.lines.size(),"capacity":snapshot.capacity,"stocks":stocks,"selected":selected_line,"managed":bool(MilitaryCampaign.workshop.data.enabled),"owner":MilitaryCampaign.workshop.owner(),"on_select":_select,"on_action":_action,"on_detail":workshop._open_workshop_job,
		"on_add":focused_action("ADD PRODUCTION LINE","Known products",workshop._equipment_catalog).on_press,
		"on_manage":focused_action("WORKSHOP MANAGEMENT","Delegation",workshop._workshop_management_report).on_press,
		"on_history":focused_action("PRODUCTION HISTORY","Completed output",_history).on_press},{"type":"actions","items":[focused_action("EQUIPMENT REPAIRS","Restore damaged military equipment",_repairs)]}]}
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
	return {"blocks":[{"type":"production_board","lines":[],"receipts":MilitaryCampaign.workshop.data.receipts,"day":int(GameState.elapsed_days),"view_state":{"mode":1}}]}
func signature()->Array:
	return [MilitaryCampaign.production_lines_snapshot(),GameState.elapsed_days,selected_line,MilitaryCampaign.workshop.data.enabled]

func _repairs()->Dictionary:
	_ensure_workshop()
	var items:Array=[]
	for item:String in MilitaryCampaign.damaged_equipment:
		var count:=int(MilitaryCampaign.damaged_equipment[item])
		if count<=0:continue
		items.append(focused_action("REPAIR "+item.replace("_"," ").to_upper(),"%d damaged sets" % count,workshop._supply_order_report.bind("repair",item)))
	return {"blocks":[{"type":"text","text":"No equipment needs repair."}]} if items.is_empty() else {"blocks":[{"type":"actions","heading":"DAMAGED EQUIPMENT","items":items}]}
