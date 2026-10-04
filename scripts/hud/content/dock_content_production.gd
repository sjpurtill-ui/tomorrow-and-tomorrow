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
## A store the benches use that would run out sooner than this is said on All.
const RUNS_OUT_DAYS:=90.0
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
	# Three distinct pages: All is a short overview (how the makers' hands
	# split, and the one or two things that need the god); Civilian is what
	# the makers make for the homes and for barter (one Civilian Goods stock);
	# Military is arms, the workshop lines and war gear, the one place arms
	# live.
	var mode:=String(["all","civilian","military"][clampi(sub,0,2)])
	var block:={"type":"production_queue","mode":mode,"on_open":func(section:String,page:int)->void:
		if is_instance_valid(hud):hud.section_requested.emit(section,page)}
	# Every page leads with the flow chart: materials into the benches, out to
	# what the makers make (flow_model). Military needs the towns' arms too.
	var cards:=household_cards()
	if mode!="military":
		block.households=cards
	var snapshot:=MilitaryCampaign.production_lines_snapshot()
	var pool:=P.hands(MilitaryCampaign)
	block.flow=flow_model(cards,snapshot.get("lines",[]),pool)
	if mode=="civilian":
		# Goods to spare and their worth in rations, priced in the realm's own
		# scope (pricing inside a town's scope would leave its prices behind).
		var spare:=0.0
		for card:Dictionary in cards:spare+=float(card.get("spare",0.0))
		block.spare_worth=preload("res://scripts/civilian_goods.gd").worth_in_rations(spare)
		block.techniques=_technique_list()
		block.carts=_carts()
	if mode!="civilian":
		var stock:=Logistics.rows(MilitaryCampaign,snapshot)
		if mode=="all":
			block.overview=overview(block.households,stock,pool,snapshot,block.flow)
			return {"blocks":[block]}
		var lines:Array=with_staff_plans(snapshot.lines)
		var context:=line_context(snapshot)
		block.arms=arms_reading()
		block.merge({"lines":line_views(lines,context,stock,pool),"capacity":snapshot.capacity,"context":context,
			"materials":_stores(lines),"hands":{"total":int(pool.total),"lines":int(pool.lines)},"boatyards":_boatyards(),"stock":stock,
			"managed":bool(MilitaryCampaign.workshop.data.enabled),"owner":workshop_owner(),"status":MilitaryCampaign.workshop.data.status,
			"repairs":_repair_list(),"recipes":recipe_list(lines,stock),"start_target":START_TARGET,
			"on_action":_action,"on_detail":workshop._open_workshop_job,"on_header":_header_action,"on_start":_start,
			"on_add":focused_action("ADD PRODUCTION LINE","Known products",workshop._equipment_catalog).on_press,
			"on_manage":focused_action("WORKSHOP MANAGEMENT","Delegation",workshop._workshop_management_report).on_press,
			"on_history":focused_action("PRODUCTION HISTORY","Completed output",_history).on_press})
	return {"blocks":[block]}

## The All page: how the makers' hands split between the homes, the
## workshop lines and arms, what they make a day, who runs the workshops,
## and at most two things that need the god (each with the page that
## answers it). Every number is the engine's (persistent_production.gd
## hands, civilian_goods.gd, weapons_stock.gd, equipment_logistics.gd).
static func overview(cards:Array,stock:Array,pool:Dictionary,snapshot:Dictionary,flow:Dictionary={})->Dictionary:
	var Goods:=preload("res://scripts/civilian_goods.gd")
	var Arms:=preload("res://scripts/weapons_stock.gd")
	var Queue:=preload("res://scripts/hud/production_queue.gd")
	var report:Dictionary=WorldSimulation.state.civilian_goods.get("report",{})
	var made:=0.0
	for card:Dictionary in cards:made+=float(card.get("made",0.0))
	var attention:Array=[]
	# A store the benches draw on that the week's trend would empty soon.
	var soonest:Dictionary={}
	for material:Dictionary in flow.get("materials",[]):
		if material.has("days_left") and float(material.days_left)<RUNS_OUT_DAYS and (soonest.is_empty() or float(material.days_left)<float(soonest.days_left)):soonest=material
	if not soonest.is_empty():
		attention.append({"text":"%s runs out in %s" % [String(soonest.name),Plain.span_text(float(soonest.days_left))],"sub":"%s in store, falling about %s a day" % [Plain.number(float(soonest.amount)),Plain.number(-float(soonest.trend))],"tone":"red" if float(soonest.days_left)<30.0 else "amber","page":1})
	for row:Dictionary in stock:
		var deficit:=int(row.get("deficit",0))
		if deficit<=0:continue
		var said:=Queue.cover_words(deficit,int(row.get("needed",0)),float(row.get("making_per_day",0.0)),float(row.get("days_to_cover",0.0)),not (row.get("lines",[]) as Array).is_empty())
		attention.append({"text":"The bands are short %d %s" % [deficit,String(row.get("name",row.get("item",""))).to_lower()],"sub":String(said.text).trim_prefix("short %d · " % deficit),"tone":String(said.tone),"page":2})
	var wanted:=Arms.arms_wanted()
	if wanted>0:
		var hands:=Goods.arms_hands(WorldSimulation.state)
		attention.append({"text":"The watch lacks %d %s of arms" % [wanted,"set" if wanted==1 else "sets"],"sub":("%s makers are making them" % Plain.number(hands)) if hands>=0.05 else "no maker is making them now","tone":"amber" if hands>=0.05 else "red","page":2})
	for card:Dictionary in cards:
		var story:=Queue.household_story(card)
		if String(story.tone)!="good" and float(card.get("coverage",1.0))<0.98:
			attention.append({"text":"%s: %s" % [String(card.get("city","")),String(story.held).trim_suffix(".")],"sub":String(story.eta),"tone":"red" if String(story.tone)=="bad" else "amber","page":1})
	var owner:=workshop_owner()
	return {"hands_total":int(pool.get("total",0)),"hands_lines":int(pool.get("lines",0)),"hands_arms":Goods.arms_hands(WorldSimulation.state),
		"goods_made":made,"arms_made":float(report.get("arms_made",0.0)),"lines":(snapshot.get("lines",[]) as Array).size(),"capacity":int(snapshot.get("capacity",0)),
		"owner":owner,"managed":bool(MilitaryCampaign.workshop.data.enabled),"status":String(MilitaryCampaign.workshop.data.status),"attention":attention}

## Arms for the watch (weapons_stock.gd): sets held and carried against the
## watch, what is still wanted, what the makers make a day, and one set's cost.
static func arms_reading()->Dictionary:
	var Goods:=preload("res://scripts/civilian_goods.gd")
	var Arms:=preload("res://scripts/weapons_stock.gd")
	var report:Dictionary=WorldSimulation.state.civilian_goods.get("report",{})
	return {"held":Arms.weapons_held(),"issued":Arms.weapons_issued(),"watch":roundi(Arms.watch()),"wanted":Arms.arms_wanted(),
		"made":float(report.get("arms_made",0.0)),"hands":Goods.arms_hands(WorldSimulation.state),"cost":Arms.cost_per_fighter(),
		"share":Arms.ARMS_SHARE,"war_share":Arms.WAR_SHARE,"item":String(Arms.made_kit().get("item","spear"))}

## Carts in store, and whether the people know how to make them (they are
## made on the workshop lines).
static func _carts()->Dictionary:
	var known:=false
	for item:String in MilitaryCampaign.PersistentProduction.available_products(MilitaryCampaign):
		if item=="transport_cart":known=true
	return {"count":int(GameState.resource_stockpiles.get("Transport Carts",0)),"known":known}

## Every line as the compact row draws it (see Plain.line_view), in list
## order: rank is priority for scarce materials.
static func line_views(lines:Array,context:Dictionary,stock:Array,pool:Dictionary)->Array:
	# The bands' needs and the workshop's officer are read per line: with no
	# line there is nothing to read them for.
	if lines.is_empty():return []
	var by_item:={}
	for row:Dictionary in stock:by_item[String(row.item)]=row
	var need:=Logistics.needs(MilitaryCampaign)
	var owner_words:=workshop_owner()
	var owner:=Plain.officer(owner_words)
	var today:=int(GameState.elapsed_days)
	var learn:=0.0025*(.65+MilitaryCampaign._adoption("workshop_standards"))
	var views:Array=[]
	for index in lines.size():
		var line:Dictionary=lines[index]
		var item:=String(line.get("item",""))
		var category:=Logistics.category(item)
		var extra:={"name":P.product_name(item),"hands":int((pool.by_line as Dictionary).get(int(line.get("id",0)),0)),"hands_exact":float((pool.exact as Dictionary).get(int(line.get("id",0)),0.0)),"hands_step":Plain.hands_step(float(pool.total)),
			"badge":Logistics.line_badge(line,MilitaryCampaign,need),"stock":by_item.get(item,{}),"ship":category=="boats","today":today,
			"learn_per_day":learn,"office":String(owner.get("office","")) if not owner.is_empty() else "","auto":category in ["weapons","ammunition"],"owner":owner_words}
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
	var line_name:="workshop";var was_paused:=false
	for job:Dictionary in MilitaryCampaign.equipment_queue:
		if int(job.id)==id:line_name=P.product_name(String(job.get("item",""))).to_lower();was_paused=bool(job.get("paused",false))
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
	# A click that changes a line is an order with its card; dragged
	# shares, moves and hands are adjustments, not orders.
	if action in ["pause","close","delegate","auto"]:
		var words:={"pause":("Resume the %s line" if was_paused else "Pause the %s line"),"close":"Close the %s line","delegate":"Hand the %s line to the staff","auto":"Change who runs the %s line"}
		preload("res://scripts/order_tracker.gd").setting_order(String(words[action]) % line_name,result,"production","the workshops","production")
	if action in QUIET_ACTIONS and not result.has("error"):
		if hud!=null:hud.request_immediate_dock_refresh()
		return
	_report(result)
## "take_over": staff stop scheduling; "hand_back": staff schedule every unpaused line.
func _header_action(kind:String)->void:
	var manager=MilitaryCampaign.workshop
	_report(manager.set_enabled(false) if kind=="take_over" else manager.delegate_lines())
func _start(item:String)->void:
	var result:=MilitaryCampaign.start_production_line(item,START_TARGET)
	preload("res://scripts/order_tracker.gd").workshop_order("Keep %d %s in store" % [START_TARGET,P.product_name(item).to_lower()],result,item,START_TARGET,true)
	_report(result)
func _report(result:Dictionary)->void:
	if terrain!=null:terrain._report_military_action(result)
	if hud!=null:hud.request_immediate_dock_refresh()
func _history()->Dictionary:
	return {"blocks":[{"type":"production_board","lines":[],"receipts":MilitaryCampaign.workshop.data.receipts,"totals":MilitaryCampaign.workshop.data.totals,"day":int(GameState.elapsed_days),"view_state":{"mode":1}}]}
func signature()->Array:
	return [MilitaryCampaign.production_lines_snapshot(),GameState.elapsed_days,MilitaryCampaign.workshop.data.enabled,workshop_owner(),MilitaryCampaign.workshop.data.status,MilitaryCampaign.damaged_equipment,MilitaryCampaign.production_labor_share]

## MilitaryCampaign.workshop.owner() in the same words, read without copying
## the officeholders' whole records (that copy made this 0.75 s check cost
## 2.5 ms): the first of Quartermaster and Steward that is held.
## tests/test_dock_content_cache.gd holds the two equal.
static func workshop_owner()->String:
	for office:String in ["Quartermaster","Steward"]:
		var holder:Dictionary=WorldSimulation.state.leadership_positions.get(office,{})
		if holder.is_empty():continue
		var pid:=int(holder.get("person_id",0))
		for person:Dictionary in WorldSimulation.government.people:
			if int(person.get("person_id",0))==pid:return "%s · %s" % [String(person.name),office]
	return "No workshop officeholder"

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

## One card of household goods per city, read inside that city's resources
## (the Wealth page sums them too, so both screens say the same).
static func household_cards()->Array:
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
	var spare:=goods.spare()
	return {"stock":goods.stock(),"spare":spare,"target":goods.target(),"coverage":goods.coverage(),"made":float(report.get("made",0.0)) if current else 0.0,
		"worn":float(report.get("worn",0.0)) if current else goods.stock()*goods.daily_wear(),"reason":String(report.get("reason","")) if current else "","basket":basket,
		# Goods the learners took today (research_600_catalog.gd learning_goods).
		"learners":float(report.get("learners",0.0)) if current else 0.0,
		# Today's materials in and goods out (civilian_goods.gd advance), for the flow chart.
		"for_barter":float(report.get("for_barter",0.0)) if current else 0.0,"inputs":(report.get("inputs",{}) as Dictionary).duplicate() if current else {},
		"arms_made":float(report.get("arms_made",0.0)) if current else 0.0,"arms_hands":float(report.get("arms_hands",0.0)) if current else 0.0,
		"arms_inputs":(report.get("arms_inputs",{}) as Dictionary).duplicate() if current else {},"workers":float(report.get("workers",0.0)) if current else 0.0}

## THE FLOW CHART (hud/production_flow.gd): what the makers' hands make today,
## from what, and what it does for us. Every number is the engine's:
##   materials  the stores (GameState.resource_stockpiles) with the week's
##              trend (equipment_logistics.gd material_trend); `days_left`
##              when the trend would empty a store the benches draw on;
##   benches    the household benches (civilian_goods.gd: makers, goods made
##              today), the arms bench (weapons_stock.gd: hands on arms, sets
##              made) and the workshop lines (persistent_production.gd);
##   outputs    goods for the homes, goods for barter, arms for the watch and
##              each line's product;
##   links      a day's flow along each ribbon. Materials in are the day's
##              draws (report inputs, scaled to one day by what was made: the
##              basket's RAW_PER_UNIT a good, the arms age's materials a set).
##              A `dry` link is a material a bench wants and cannot get, with
##              its words ("no flint: arms stalled").
static func flow_model(cards:Array,lines:Array,hands:Dictionary)->Dictionary:
	var Goods:=preload("res://scripts/civilian_goods.gd")
	var Arms:=preload("res://scripts/weapons_stock.gd")
	var goods_in:={};var arms_in:={}
	var made:=0.0;var barter:=0.0;var arms_made:=0.0;var arms_hands:=0.0;var workers:=0.0
	var reasons:={}
	for card:Dictionary in cards:
		var card_made:=float(card.get("made",0.0))
		made+=card_made;barter+=float(card.get("for_barter",0.0))
		workers+=float(card.get("workers",0.0))
		_scaled_into(goods_in,card.get("inputs",{}),card_made*Goods.RAW_PER_UNIT)
		var sets:=float(card.get("arms_made",0.0))
		arms_made+=sets;arms_hands+=float(card.get("arms_hands",0.0))
		var age:Dictionary=Arms.set_age()
		var raw:=0.0
		for item:String in age.materials:raw+=float(age.materials[item])
		_scaled_into(arms_in,card.get("arms_inputs",{}),sets*raw)
		var reason:=String(card.get("reason",""))
		if reason!="":reasons[reason]=int(reasons.get(reason,0))+1
	var links:Array=[]
	var resources:Array[String]=[]
	for item:String in goods_in:
		if float(goods_in[item])>0.0001:links.append({"from":item,"to":"goods","per_day":float(goods_in[item])});_add_unique(resources,item)
	# A town whose makers have no raw materials: the basket runs dry there.
	if int(reasons.get("Needs timber, fiber, clay, stone or flint",0))>0 and made<0.01:
		for item:String in Goods.BASKET:
			links.append({"from":item,"to":"goods","per_day":0.0,"dry":true,"words":"no %s: goods stalled" % ResourceSystem.display_name(item).to_lower()});_add_unique(resources,item)
	for item:String in arms_in:
		if float(arms_in[item])>0.0001:links.append({"from":item,"to":"arms","per_day":float(arms_in[item])});_add_unique(resources,item)
	var wanted:=Arms.arms_wanted()
	var arms_stalled:=""
	if wanted>0 and arms_made<0.001:
		var kit:=Arms.arms_age()
		if kit.is_empty():arms_stalled="no weapon our makers make arms our fighters"
		else:
			var age:Dictionary=kit.age
			var short:Array[String]=[]
			if String(age.id)=="stone":
				var raw:=0.0
				for item:String in Arms.STONE_BASKET:raw+=Arms._usable(item)
				if raw<Arms._raw_per_set(age):short.assign(Arms.STONE_BASKET)
			else:
				for item:String in age.materials:
					if Arms._usable(item)<float(age.materials[item]):short.append(item)
			for item:String in short:
				links.append({"from":item,"to":"arms","per_day":0.0,"dry":true,"words":"no %s: arms stalled" % ResourceSystem.display_name(item).to_lower()});_add_unique(resources,item)
			if short.is_empty():arms_stalled="no makers free for arms"
	# The workshop lines: what each working line draws and makes a day.
	var outputs:Array=[
		{"id":"homes","kind":"homes","name":"For the homes","per_day":maxf(0.0,made-barter),"unit":"goods"},
		{"id":"barter","kind":"barter","name":"For barter","per_day":barter,"unit":"goods"}]
	links.append({"from":"goods","to":"homes","per_day":maxf(0.0,made-barter)})
	links.append({"from":"goods","to":"barter","per_day":barter})
	var show_arms:=wanted>0 or arms_made>0.0001
	if show_arms:
		outputs.append({"id":"watch","kind":"watch","name":"Arms for the watch","per_day":arms_made,"unit":"sets"})
		links.append({"from":"arms","to":"watch","per_day":arms_made,"dry":arms_made<0.001 and wanted>0,"words":""})
	var line_hands:=float(hands.get("lines",0))
	var line_out:=0.0
	var line_count:=0
	for line:Dictionary in lines:
		if bool(line.get("paused",false)):continue
		line_count+=1
		var item:=String(line.get("item",""))
		var per_day:=float(line.get("output_per_day",0.0))
		var wants:=int(line.get("target_stock",0))<=0 or int(line.get("stock",0))<int(line.get("target_stock",0))
		line_out+=per_day
		var out_id:="line:%d" % int(line.get("id",0))
		outputs.append({"id":out_id,"kind":"gear","item":item,"name":P.product_name(item),"per_day":per_day,"unit":"","stock":int(line.get("stock",0)),"target":int(line.get("target_stock",0))})
		links.append({"from":"lines","to":out_id,"per_day":per_day})
		for input:Dictionary in line.get("materials_status",[]):
			var resource:=String(input.get("resource",""))
			if resource.is_empty():continue
			_add_unique(resources,resource)
			var short:=wants and float(input.get("stored",0.0))<float(input.get("per_item",0.0))
			links.append({"from":resource,"to":"lines","per_day":float(input.get("per_day",0.0)) if not short else 0.0,"dry":short,
				"words":("no %s: %s stalled" % [ResourceSystem.display_name(resource).to_lower(),P.product_name(item).to_lower()]) if short else ""})
	var benches:Array=[{"id":"goods","kind":_goods_bench(),"name":"Household benches","hands":maxf(0.0,float(hands.get("total",0))-line_hands-arms_hands),"per_day":made,"unit":"goods",
		"stalled":"" if made>=0.01 or int(reasons.get("Stock target met",0))+int(reasons.get("Homes and the market are full",0))>0 else _plain_reason(reasons)}]
	if show_arms:benches.append({"id":"arms","kind":"anvil" if String(Arms.set_age().id)!="stone" else "knapping","name":"Arms bench","hands":arms_hands,"per_day":arms_made,"unit":"sets","stalled":arms_stalled,"wanted":wanted})
	if line_count>0:benches.append({"id":"lines","kind":"bench","name":"Workshop lines","hands":line_hands,"per_day":line_out,"unit":"","stalled":""})
	var materials:Array=[]
	for item:String in resources:
		var amount:=float(GameState.resource_stockpiles.get(item,0.0))
		var trend:Dictionary=Logistics.material_trend(item)
		var per_day:=float(trend.get("per_day",0.0))
		var row:={"resource":item,"name":ResourceSystem.display_name(item),"amount":amount,"trend":per_day,"trend_days":int(trend.get("days",0))}
		if per_day<-0.0001 and amount>0.0:row.days_left=amount/-per_day
		materials.append(row)
	materials.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return _material_used(links,String(a.resource))>_material_used(links,String(b.resource)))
	return {"materials":materials,"benches":benches,"outputs":outputs,"links":links,"makers":int(hands.get("total",0)),"goods":made,"barter":barter,"arms":arms_made,"wanted":wanted}

static func _scaled_into(total:Dictionary,inputs:Dictionary,day_amount:float)->void:
	var drawn:=0.0
	for item:String in inputs:drawn+=maxf(0.0,float(inputs[item]))
	if drawn<=0.0 or day_amount<=0.0:return
	for item:String in inputs:total[item]=float(total.get(item,0.0))+maxf(0.0,float(inputs[item]))*day_amount/drawn

static func _add_unique(list:Array[String],item:String)->void:
	if item not in list:list.append(item)

static func _material_used(links:Array,item:String)->float:
	var used:=0.0
	for link:Dictionary in links:
		if String(link.from)==item:used+=float(link.per_day)+(0.0001 if bool(link.get("dry",false)) else 0.0)
	return used

## The household bench as the people's era makes it: an anvil once metal is
## worked, a kiln once clay is fired, a basket once baskets are woven, and
## knapping before all of them.
static func _goods_bench()->String:
	var known:Array=GameState.known_discoveries
	if String(preload("res://scripts/weapons_stock.gd").set_age().id)!="stone":return "anvil"
	if "pit_firing" in known or "clay_tempering" in known:return "kiln"
	if "basketry" in known:return "basket"
	return "knapping"

static func _plain_reason(reasons:Dictionary)->String:
	for reason:String in ["Needs timber, fiber, clay, stone or flint","No craftspeople assigned","Needs a settled workplace"]:
		if reasons.has(reason):return {"Needs timber, fiber, clay, stone or flint":"no raw materials","No craftspeople assigned":"no makers at work","Needs a settled workplace":"no settled place to work"}[reason]
	return ""

## Household goods as dock rows (used by tests and older reports).
static func _household_rows()->Array:
	var goods=preload("res://scripts/civilian_goods.gd")
	var card:=_household_card()
	var reason:=String(card.reason)
	if reason.is_empty():reason="Replenishing as needed"
	return [{"name":"Civilian Goods","value":"%+.2f today" % (float(card.made)-float(card.worn)-float(card.get("learners",0.0))),"sub":"%.1f held of %.1f wanted (%d%%) · %s" % [goods.stock(),goods.target(),roundi(float(card.coverage)*100.0),reason],"accent":Tokens.GREEN if float(card.coverage)>=.8 else Tokens.AMBER}]

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
