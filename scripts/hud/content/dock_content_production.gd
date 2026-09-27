extends "res://scripts/hud/content/dock_content_base.gd"
## Production dock. One "production_queue" block carries everything the screen
## shows; the controls call the existing production actions unchanged.
const Plain:=preload("res://scripts/hud/production_plain.gd")
const Upkeep:=preload("res://scripts/routine_military_upkeep.gd")
## Stock target a line started from the recipe list keeps; changed on its card.
const START_TARGET:=10
const STORE_RESOURCES:=["Timber","Fiber Plants","Stone","Clay","Copper Ore"]
var workshop:RefCounted
func meta()->Dictionary:
	return {"eyebrow":"WORKSHOPS & EQUIPMENT", "title":"Production", "serif":true, "subtabs":["All","Civilian","Military"]}
func _ensure_workshop()->void:
	if workshop==null:workshop=preload("res://scripts/hud/content/dock_content_military.gd").new(terrain,hud)
func tab(sub:int)->Dictionary:
	_ensure_workshop()
	# Civilian manufactures are one Civilian Goods stock made by households;
	# workshop lines and recipes are military only.
	var mode:=String(["all","civilian","military"][clampi(sub,0,2)])
	var block:={"type":"production_queue","mode":mode}
	if mode!="military":
		block.households=household_cards()
		block.techniques=_technique_list()
	if mode!="civilian":
		var snapshot:=MilitaryCampaign.production_lines_snapshot()
		var lines:Array=with_staff_plans(snapshot.lines)
		block.merge({"lines":lines,"capacity":snapshot.capacity,"context":line_context(snapshot),"stores":_stores(lines),
			"managed":bool(MilitaryCampaign.workshop.data.enabled),"owner":MilitaryCampaign.workshop.owner(),"status":MilitaryCampaign.workshop.data.status,
			"repairs":_repair_list(),"recipes":recipe_list(lines),"start_target":START_TARGET,
			"on_action":_action,"on_detail":workshop._open_workshop_job,"on_header":_header_action,"on_start":_start,
			"on_add":focused_action("ADD PRODUCTION LINE","Known products",workshop._equipment_catalog).on_press,
			"on_manage":focused_action("WORKSHOP MANAGEMENT","Delegation",workshop._workshop_management_report).on_press,
			"on_history":focused_action("PRODUCTION HISTORY","Completed output",_history).on_press})
	return {"blocks":[block]}

## Hook for codex/auto-arm: if the workshop steward exposes
## line_plan(id)->{count,reason,officer}, attach it to the line as "staff_plan"
## unless the snapshot already carries one. The screen then says, e.g., "The
## Quartermaster is making 22 simple levy weapons for the new levy (about 40
## days; short of timber)."
static func with_staff_plans(lines:Array)->Array:
	var steward=MilitaryCampaign.workshop
	if steward==null or not steward.has_method("line_plan"):return lines
	var result:Array=[]
	for line:Dictionary in lines:
		var copy:=line
		if not line.has("staff_plan"):
			var plan:Variant=steward.line_plan(int(line.get("id",-1)))
			if plan is Dictionary and not (plan as Dictionary).is_empty():copy=line.duplicate();copy["staff_plan"]=plan
		result.append(copy)
	return result

static func line_context(snapshot:Dictionary)->Dictionary:
	## What line_story needs to name a slow line's real limit, and the material
	## every line still needs so shared shortages can be pointed out.
	var demand:Dictionary={}
	for line:Dictionary in snapshot.get("lines",[]):
		var target:=int(line.get("target_stock",0))
		if not bool(line.get("persistent",false)) or target<=0:continue
		var remaining:=maxf(0.0,target-int(line.get("stock",0)))
		for input:Dictionary in line.get("materials_status",[]):
			var key:=String(input.get("resource",input.get("name","")))
			demand[key]=float(demand.get(key,0.0))+float(input.get("per_item",0.0))*remaining
	return {"workforce":snapshot.get("workforce",{}),"labor_share":float(snapshot.get("labor_share",1.0)),"line_count":(snapshot.get("lines",[]) as Array).size(),"demand":demand}

func _stores(lines:Array)->Array:
	var names:Array[String]=[]
	for line:Dictionary in lines:
		for input:Dictionary in line.get("materials_status",[]):
			var key:=String(input.get("resource",""))
			if not key.is_empty() and key not in names:names.append(key)
	for resource:String in STORE_RESOURCES:
		if resource not in names and float(GameState.resource_stockpiles.get(resource,0))>0:names.append(resource)
	var result:Array=[]
	for resource:String in names:
		result.append({"resource":resource,"name":ResourceSystem.display_name(resource),"amount":float(GameState.resource_stockpiles.get(resource,0))})
	return result

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
	_report(result)
## "take_over": staff stop scheduling; "hand_back": staff schedule every unpaused line.
func _header_action(kind:String)->void:
	var manager=MilitaryCampaign.workshop
	_report(manager.set_enabled(false) if kind=="take_over" else manager.delegate_lines())
func _start(item:String)->void:
	_report(MilitaryCampaign.start_production_line(item,START_TARGET))
func _report(result:Dictionary)->void:
	if terrain!=null:terrain._report_military_action(result)
	if hud!=null:hud.request_immediate_dock_refresh()
func _history()->Dictionary:
	return {"blocks":[{"type":"production_board","lines":[],"receipts":MilitaryCampaign.workshop.data.receipts,"totals":MilitaryCampaign.workshop.data.totals,"day":int(GameState.elapsed_days),"view_state":{"mode":1}}]}
func signature()->Array:
	return [MilitaryCampaign.production_lines_snapshot(),GameState.elapsed_days,MilitaryCampaign.workshop.data.enabled,MilitaryCampaign.workshop.owner(),MilitaryCampaign.workshop.data.status,MilitaryCampaign.damaged_equipment]

## Damaged sets waiting for staff repair, shown on the screen itself.
func _repair_list()->Array:
	var items:Array=[]
	for item:String in MilitaryCampaign.damaged_equipment:
		var count:=int(MilitaryCampaign.damaged_equipment[item])+Upkeep.pending(MilitaryCampaign,item)
		if count<=0:continue
		items.append({"item":item,"name":MilitaryCampaign.PersistentProduction.product_name(item),"count":count,"status":Upkeep.status(MilitaryCampaign,item)})
	return items

## The same list as a standalone report.
func _repairs()->Dictionary:
	_ensure_workshop()
	var items:Array=[]
	for repair:Dictionary in _repair_list():
		items.append({"name":String(repair.name),"value":"%d set%s damaged" % [int(repair.count),"" if int(repair.count)==1 else "s"],"detail":String(repair.status)})
	return {"blocks":[{"type":"text","text":"No equipment needs repair."}]} if items.is_empty() else {"blocks":[{"type":"rows","heading":"Damaged equipment","items":items}]}

## Every known workshop recipe, grouped, with what one item needs and the one
## short reason it cannot start yet.
static func recipe_list(lines:Array)->Array:
	var production=MilitaryCampaign.PersistentProduction
	var running:Array[String]=[]
	for line:Dictionary in lines:running.append(String(line.get("item","")))
	var gate:Dictionary=MilitaryCampaign._production_line_gate()
	var result:Array=[]
	for item:String in production.available_products(MilitaryCampaign):
		var recipe:Dictionary=production.recipe(MilitaryCampaign,item)
		var needs:Array[String]=[]
		var materials:Dictionary=recipe.get("materials",{})
		var keys:=materials.keys();keys.sort_custom(func(a,b)->bool:return float(materials[a])>float(materials[b]))
		for resource:String in keys.slice(0,3):needs.append("%s %s" % [Plain.number(float(materials[resource])),ResourceSystem.display_name(resource).to_lower()])
		if keys.size()>3:needs.append("%d more" % (keys.size()-3))
		var text:=("Each needs "+", ".join(needs)) if not needs.is_empty() else "Needs no materials"
		var blockers:Array=production.startup_blockers(MilitaryCampaign,item,{})
		var reason:=""
		var full:=""
		if not blockers.is_empty():
			full=" ".join(blockers);reason=Plain.blocker_text(String(blockers[0]))
		elif gate.has("error"):
			full=String(gate.error);reason=Plain.blocker_text(full)
		result.append({"item":item,"name":production.product_name(item),"group":_group(item),"needs":text,"blocker":reason,"blocker_full":full,"running":item in running})
	var order:=["Weapons and gear","Ammunition","Carts","Ships and aircraft"]
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var ga:=order.find(String(a.group));var gb:=order.find(String(b.group))
		return ga<gb if ga!=gb else String(a.name)<String(b.name))
	return result

static func _group(item:String)->String:
	if not preload("res://scripts/joint_force_catalog.gd").by_equipment(item).is_empty():return "Ships and aircraft"
	if item=="transport_cart":return "Carts"
	if MilitaryCampaign.CONSUMABLE_KNOWLEDGE.has(item):return "Ammunition"
	return "Weapons and gear"

## One card of household goods per city, read inside that city's resources.
func household_cards()->Array:
	var cards:Array=[]
	for city:Dictionary in GameState.player_settlements:
		var card:Dictionary=SettlementModel.with_city_resources(String(city.id),func()->Dictionary:
			return SettlementModel.with_local_population(func()->Dictionary:return _household_card()))
		if card.is_empty():continue
		card.merge({"id":String(city.id),"city":String(city.name)})
		cards.append(card)
	return cards

static func _household_card()->Dictionary:
	var goods=preload("res://scripts/civilian_goods.gd")
	var report:Dictionary=GameState.civilian_goods.get("report",{})
	var current:=int(GameState.civilian_goods.get("last_day",-1))==int(GameState.elapsed_days)
	var basket:Array=[]
	for resource:String in goods.BASKET:
		var amount:=float(GameState.resource_stockpiles.get(resource,0.0))
		if amount>0.0:basket.append({"name":ResourceSystem.display_name(resource),"amount":amount})
	return {"stock":goods.stock(),"target":goods.target(),"coverage":goods.coverage(),"made":float(report.get("made",0.0)) if current else 0.0,
		"worn":float(report.get("worn",0.0)) if current else goods.stock()*goods.DAILY_WEAR,"reason":String(report.get("reason","")) if current else "","basket":basket}

## Household goods as dock rows (used by tests and older reports).
static func _household_rows()->Array:
	var goods=preload("res://scripts/civilian_goods.gd")
	var card:=_household_card()
	var reason:=String(card.reason)
	if reason.is_empty():reason="Replenishing as needed"
	return [{"name":"Civilian Goods","value":"%+.2f today" % (float(card.made)-float(card.worn)),"sub":"%.1f held of %.1f wanted (%d%%) · %s" % [goods.stock(),goods.target(),roundi(float(card.coverage)*100.0),reason],"accent":Tokens.GREEN if float(card.coverage)>=.8 else Tokens.AMBER}]

static func _technique_list()->Array:
	var goods=preload("res://scripts/civilian_goods.gd")
	var rows:Array=[]
	for id:String in goods.TECHNIQUES:
		if id not in GameState.known_discoveries:continue
		var adoption:=DiscoverySystem.adoption(id)
		rows.append({"id":id,"name":String(DiscoverySystem.discovery_definition(id).get("name",id.capitalize())),"adoption":adoption,"working":adoption*goods.factor(id)})
	return rows

static func _technique_rows()->Array:
	var rows:Array=[]
	for technique:Dictionary in _technique_list():
		var adoption:=float(technique.adoption)
		rows.append({"name":String(technique.name),"value":"%d%% adopted" % roundi(adoption*100.0),"sub":"Acting at %d%% of its benefit" % roundi(float(technique.working)*100.0),"accent":Tokens.GREEN if adoption>=.5 else Tokens.AMBER})
	return rows
