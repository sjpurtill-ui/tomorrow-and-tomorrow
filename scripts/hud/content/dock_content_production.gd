extends "res://scripts/hud/content/dock_content_base.gd"
## Production dock, HOI4-style. One "production_queue" block carries every
## number the screen shows: materials with their trend, workshop hands, the
## equipment the bands have against what they need, each line as a compact
## row view, and the cards that start a line. The controls call the existing
## production actions (and the hands / order helpers of PersistentProduction).
const Plain:=preload("res://scripts/hud/production_plain.gd")
const Upkeep:=preload("res://scripts/routine_military_upkeep.gd")
const Logistics:=preload("res://scripts/equipment_logistics.gd")
const P:=preload("res://scripts/persistent_production.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
## Stock target a line started from a card keeps; changed on its row.
const START_TARGET:=10
const STORE_RESOURCES:=["Timber","Fiber Plants","Stone","Clay","Copper Ore"]
## Actions the screen shows by itself changing; only their errors need a note.
const QUIET_ACTIONS:=["hands","move","move_to","target","pause"]
var workshop:RefCounted
func meta()->Dictionary:
	return {"eyebrow":"WORKSHOPS & EQUIPMENT", "title":"Production", "serif":true, "subtabs":["All","Civilian","Military"], "fit_height":true}
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
		var context:=line_context(snapshot)
		var stock:=Logistics.rows(MilitaryCampaign,snapshot)
		var pool:=P.hands(MilitaryCampaign)
		block.merge({"lines":line_views(lines,context,stock,pool),"capacity":snapshot.capacity,"context":context,
			"materials":_stores(lines),"hands":{"total":int(pool.total),"lines":int(pool.lines)},"boatyards":_boatyards(),"stock":stock,
			"managed":bool(MilitaryCampaign.workshop.data.enabled),"owner":MilitaryCampaign.workshop.owner(),"status":MilitaryCampaign.workshop.data.status,
			"repairs":_repair_list(),"recipes":recipe_list(lines,stock),"start_target":START_TARGET,
			"on_action":_action,"on_detail":workshop._open_workshop_job,"on_header":_header_action,"on_start":_start,
			"on_add":focused_action("ADD PRODUCTION LINE","Known products",workshop._equipment_catalog).on_press,
			"on_manage":focused_action("WORKSHOP MANAGEMENT","Delegation",workshop._workshop_management_report).on_press,
			"on_history":focused_action("PRODUCTION HISTORY","Completed output",_history).on_press})
	return {"blocks":[block]}

## Every line as the compact row draws it (see Plain.line_view), in list
## order: rank is priority for scarce materials.
static func line_views(lines:Array,context:Dictionary,stock:Array,pool:Dictionary)->Array:
	var by_item:={}
	for row:Dictionary in stock:by_item[String(row.item)]=row
	var need:=Logistics.needs(MilitaryCampaign)
	var owner:=Plain.officer(MilitaryCampaign.workshop.owner())
	var today:=int(GameState.elapsed_days)
	var learn:=0.0025*(.65+MilitaryCampaign._adoption("workshop_standards"))
	var views:Array=[]
	for index in lines.size():
		var line:Dictionary=lines[index]
		var item:=String(line.get("item",""))
		var category:=Logistics.category(item)
		var extra:={"name":P.product_name(item),"hands":int((pool.by_line as Dictionary).get(int(line.get("id",0)),0)),"hands_exact":float((pool.exact as Dictionary).get(int(line.get("id",0)),0.0)),"hands_step":Plain.hands_step(float(pool.total)),
			"badge":Logistics.line_badge(line,MilitaryCampaign,need),"stock":by_item.get(item,{}),"ship":category=="boats","today":today,
			"learn_per_day":learn,"office":String(owner.get("office","")) if not owner.is_empty() else "","auto":category in ["weapons","ammunition"],"owner":MilitaryCampaign.workshop.owner()}
		var view:=Plain.line_view(line,context,extra)
		view.rank=index+1;view.count=lines.size()
		view.hands_total=int(pool.total)
		view.description=P.product_description(item)
		view.auto_ready=not owner.is_empty()
		if view.has("ready_day"):
			view.bar_text="Ready "+EraWords.when(int(view.ready_day))
			view.tip=String(view.tip)+"\nNext one ready about %s (%s)." % [EraWords.when(int(view.ready_day)),Plain.duration_text(float(view.ready_days))]
		views.append(view)
	return views

## Hook for codex/auto-arm: if the workshop steward exposes
## line_plan(id)->{count,reason,officer}, attach it to the line as "staff_plan"
## unless the snapshot already carries one. The line's tooltip then says,
## e.g., "The Quartermaster is making 22 simple levy weapons for the new levy."
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

## Materials for the header strip: what the lines use, then the common
## building materials in store, with the week's trend and the lines' daily use.
func _stores(lines:Array)->Array:
	var names:Array[String]=[]
	var use:={}
	for line:Dictionary in lines:
		for input:Dictionary in line.get("materials_status",[]):
			var key:=String(input.get("resource",""))
			if key.is_empty():continue
			if key not in names:names.append(key)
			use[key]=float(use.get(key,0.0))+float(input.get("per_day",0.0))
	for resource:String in STORE_RESOURCES:
		if resource not in names and float(GameState.resource_stockpiles.get(resource,0))>0:names.append(resource)
	var result:Array=[]
	for resource:String in names:
		result.append({"resource":resource,"name":ResourceSystem.display_name(resource),"amount":float(GameState.resource_stockpiles.get(resource,0)),
			"trend":Logistics.material_trend(resource),"use":float(use.get(resource,0.0))})
	return result

## Ready naval landings the player owns: HOI4's dockyards.
static func _boatyards()->int:
	var count:=0
	var operations=MilitaryCampaign.joint_operations
	if operations==null:return 0
	for record:Dictionary in operations.state.get("bases",[]):
		if String(record.get("domain",""))=="navy" and operations.base_ready(record) and operations.base_owned(record):count+=1
	return count

func _action(id:int,action:String,value:float)->void:
	var result:Dictionary={"error":"That line is no longer active."}
	for job:Dictionary in MilitaryCampaign.equipment_queue:
		if int(job.id)!=id:continue
		var name:=P.product_name(String(job.get("item","")))
		match action:
			"delegate":result=MilitaryCampaign.workshop.delegate_line(id)
			"auto":
				if value>0.5:result=MilitaryCampaign.workshop.delegate_line(id)
				else:
					result=MilitaryCampaign.configure_production_line(id,int(job.target_stock),bool(job.paused))
					if not result.has("error"):result.message="You run %s now." % name.to_lower()
			"pause":result=MilitaryCampaign.configure_production_line(id,int(job.target_stock),not bool(job.paused))
			"target":result=MilitaryCampaign.configure_production_line(id,maxi(0,int(value)),bool(job.paused))
			"priority":
				result=MilitaryCampaign.configure_production_line(id,int(job.target_stock),bool(job.paused))
				if not result.has("error"):result=MilitaryCampaign.set_production_line_allocation(id,value)
			"hands":result=P.add_hands(MilitaryCampaign,id,value)
			"move":result=P.move(MilitaryCampaign,id,MilitaryCampaign.equipment_queue.find(job)+int(value))
			"move_to":result=P.move(MilitaryCampaign,id,int(value))
			"close":result=MilitaryCampaign.cancel_equipment_job(id)
		break
	if action in QUIET_ACTIONS and not result.has("error"):
		if hud!=null:hud.request_immediate_dock_refresh()
		return
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
	return [MilitaryCampaign.production_lines_snapshot(),GameState.elapsed_days,MilitaryCampaign.workshop.data.enabled,MilitaryCampaign.workshop.owner(),MilitaryCampaign.workshop.data.status,MilitaryCampaign.damaged_equipment,MilitaryCampaign.production_labor_share]

## Damaged sets waiting for staff repair (the stock strip shows them as a
## badge on each kind; this list serves the standalone report).
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

## Every known workshop recipe as a picker card: what one item needs, who it
## arms, and the one short reason it cannot start yet. Era-gated: only what
## the people know how to make.
static func recipe_list(lines:Array,stock:Array=[])->Array:
	var production=MilitaryCampaign.PersistentProduction
	var short:={}
	for row:Dictionary in stock:short[String(row.item)]=int(row.get("deficit",0))
	var running:Array[String]=[]
	for line:Dictionary in lines:running.append(String(line.get("item","")))
	var gate:Dictionary=MilitaryCampaign._production_line_gate()
	var result:Array=[]
	for item:String in production.available_products(MilitaryCampaign):
		var recipe:Dictionary=production.recipe(MilitaryCampaign,item)
		var needs:Array[String]=[]
		var materials:Dictionary=recipe.get("materials",{})
		var keys:=materials.keys();keys.sort_custom(func(a,b)->bool:return float(materials[a])>float(materials[b]))
		var bill:Array=[]
		for resource:String in keys:bill.append({"resource":resource,"name":ResourceSystem.display_name(resource),"amount":float(materials[resource])})
		for resource:String in keys.slice(0,3):needs.append("%s %s" % [Plain.number(float(materials[resource])),ResourceSystem.display_name(resource).to_lower()])
		if keys.size()>3:needs.append("%d more" % (keys.size()-3))
		var text:=("Each needs "+", ".join(needs)) if not needs.is_empty() else "Needs no materials"
		var blockers:Array=production.startup_blockers(MilitaryCampaign,item,{})
		var reason:=""
		var full:=""
		if item in running:pass
		elif gate.has("error"):
			full=" ".join([String(gate.error)]+blockers);reason="No free line"
		elif not blockers.is_empty():
			full=" ".join(blockers);reason=Plain.blocker_text(String(blockers[0]))
		var category:=Logistics.category(item)
		result.append({"item":item,"name":production.product_name(item),"group":_group(item),"category":category,"needs":text,"materials":bill,
			"arms":Logistics.arms(item),"description":production.product_description(item),"blocker":reason,"blocker_full":full,"running":item in running,"start_target":START_TARGET,"deficit":int(short.get(item,0))})
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var ga:=Logistics.CATEGORY_ORDER.find(String(a.category));var gb:=Logistics.CATEGORY_ORDER.find(String(b.category))
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
		if amount>0.0:basket.append({"resource":resource,"name":ResourceSystem.display_name(resource),"amount":amount})
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
