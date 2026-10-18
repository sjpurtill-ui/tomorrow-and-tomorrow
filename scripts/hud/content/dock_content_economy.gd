extends "res://scripts/hud/content/dock_content_base.gd"
const Charts:=preload("res://scripts/hud/strategic_chart_blocks.gd")
const Indicators:=preload("res://scripts/civilization_indicators.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const Purse:=preload("res://scripts/realm_purse.gd")
## The Food, Materials and Wealth docks (one section, three tabs). The rail
## names each tab, so the dock's title follows the tab the player opened.
const TITLES:=["Food","Materials","Wealth","Trade"]
const Memo:=preload("res://scripts/hud/content/dock_memo.gd")
## Costly parts of the pages, kept while what they are made from holds.
var memo:=Memo.new()
const EYEBROWS:=["What we eat and drink","What we build and make with","What we hold and owe","What passes between us and other peoples"]

func _current_sub()->int:
	var dock:Variant=hud.get("dock") if is_instance_valid(hud) else null
	return clampi(int(dock.sub) if dock!=null and is_instance_valid(dock) else 0,0,3)

func meta()->Dictionary:
	var sub:=_current_sub()
	return {
		"eyebrow":EYEBROWS[sub],
		"title":TITLES[sub],"serif":true,"title_size":38,"spread_tabs":true,
		"subtabs":["Food & water","Materials","Wealth","Trade"],
	}

func tab(sub:int)->Dictionary:
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary: return SettlementModel.with_local_population(func()->Dictionary: return _local_tab(sub)))

func _local_tab(sub:int)->Dictionary:
	match sub:
		1:
			var materials:=_materials_data()
			return {"kpis":[],"blocks":[materials]}
		2:return _wealth_tab()
		3:return {"kpis":[],"blocks":[{"type":"trade_board"}]}
	return _food_tab()

## The Food & water tab: this place's food and water. The common store holds
## goods and lives on Wealth (hud/purse_board.gd), as the treasury does.
func _food_tab()->Dictionary:
	var block:=_provisions_data()
	return {"kpis":[],"blocks":[block]}

func _open_section(section:String,sub:int)->void:
	if is_instance_valid(hud):hud.section_requested.emit(section,sub)

func signature()->Array:
	var result:Array=SettlementModel.with_city_resources(GameState.selected_player_settlement_id,_local_signature)
	result.append_array([selected_account,GameState.economy_stage,GameState.public_treasury,GameState.private_currency,GameState.currency_hoards,GameState.mutual_aid_reserve,GameState.weighed_metal_circulation,selected_material,materials_priorities,selected_food,show_priorities,GameState.settlement_network_revision,GameState.selected_player_settlement_id,GameState.elapsed_days,GameState.city_trade_shipments.size(),GameState.city_trade_history.size(),GovernmentPeopleSystem.revision])
	return result

func _local_signature()->Array:
	var metrics:Dictionary=GameState.simulation_metrics
	var food_report:Array=[]
	for key:String in ["food_days","food_reserve_days","food_net","food_production","food_eaten","food_spoilage","food_spoilage_by_type","food_preserved","food_harvest","food_workers","food_labor_share","food_sources","food_forecast_30","food_forecast_90","food_forecast_day","food_intake_ratio","food_consumption","food_home_need","food_home_eaten","fire_practice","food_preservation_inputs"]:
		food_report.append(metrics.get(key))
	return [hash(GameState.storage_works),hash(GameState.settlement_projects),hash(food_report),hash(GameState.food_stocks),hash(GameState.water_metrics),FoodSystem.issued_on_day(int(GameState.elapsed_days)),snappedf(ResourceSystem.stored_bulk(),0.1),snappedf(float(GameState.fire_practice.get("embers",0.0)),0.05),_material_reading_signature()]

## Equal-bulk exchanges and source changes can happen without advancing a day.
## Read only the displayed facts; no simulation pass or fresh random roll.
func _material_reading_signature()->int:
	var sources:Array=[]
	for deposit:Dictionary in ResourceSystem.visible_deposits():
		sources.append([deposit.get("id"),deposit.get("resource"),ResourceSystem.display_name(String(deposit.get("resource",""))),deposit.get("name"),deposit.get("stage"),deposit.get("blockers"),deposit.get("bottleneck"),deposit.get("remaining"),deposit.get("initial_amount"),deposit.get("delivered_today"),deposit.get("stock_at_source"),deposit.get("in_transit")])
	var names:Array=[]
	for key:String in GameState.resource_stockpiles:names.append([key,ResourceSystem.display_name(key)])
	return hash([GameState.resource_stockpiles,GameState.material_metrics,GameState.land_survey,sources,names])

func _trade_blocks()->Array:
	return [{"type":"deliveries_board","read":_delivery_data}]

func _delivery_data()->Dictionary:
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:
		var city:=SettlementModel.selected_settlement()
		var trade:=SettlementModel.city_trade_snapshot(String(city.get("id","")))
		trade.day=int(GameState.elapsed_days)
		return trade)

var selected_account:=""
## The Wealth tab: what the people own and can trade, goods first, and the
## treasury once it is coin (hud/purse_board.gd, which reads the realm itself
## and refreshes on its own), then this place's day's work and its
## households' money. Trade between peoples mounts its own board between
## them: one line, blocks.append(<its block>), where marked.
func _wealth_tab()->Dictionary:
	return {"kpis":[],"blocks":[{"type":"purse_board","mode":"wealth","on_open":_open_section,"ledger":_ledger_block()}]}

## This place's day's work and its households' money (hud/wealth_ledger.gd).
## The realm's treasury is the purse's, above: no town keeps its own.
func _ledger_block()->Dictionary:
	var city:=SettlementModel.settlement_record(GameState.selected_player_settlement_id)
	var stage:=GameState.economy_stage
	var accounts:Array=[]
	var history:Array=Charts.finance(GameState.selected_player_settlement_id).get("items",[]) if stage in ["currency","weighed_metal"] else []
	var definitions:Array=[["private_currency","Household money",GameState.private_currency,1],["hoards","Private hoards",GameState.currency_hoards,2],["aid","Mutual aid",GameState.mutual_aid_reserve,3]] if stage=="currency" else [["metal","Exchange metal",GameState.weighed_metal_circulation,-1]] if stage=="weighed_metal" else []
	for definition:Array in definitions:
		var points:Array=[]
		for row:Dictionary in history:points.append({"day":row.day,"value":row.get(definition[0],null)})
		accounts.append({"key":definition[0],"name":definition[1],"balance":float(definition[2]),"art":definition[3],"points":points})
	var block:={"type":"wealth_ledger","title":"Wealth","stage":stage,"city":city.get("name","Founding camp"),"leader":GovernmentPeopleSystem.settlement_leader(GameState.selected_player_settlement_id),"managed":city.get("auto_manage",true),"economy":Indicators.economy(),"history":GameState.economy_history.slice(maxi(0,GameState.economy_history.size()-12)),"conditions":{"health":float(GameState.population_health),"cohesion":float(GameState.simulation_metrics.get("cohesion",1.0)),"housing":float(GameState.simulation_metrics.get("housing_ratio",1.0))},"accounts":accounts,"selected":selected_account,"on_select":func(key:String):selected_account=key;hud.request_immediate_dock_refresh()}
	if not accounts.is_empty():block.on_history=focused_action("Past balances","",func()->Dictionary:return {"blocks":[Charts.finance(GameState.selected_player_settlement_id)]}).on_press
	return block

func open_expanded_tab(sub:int)->bool:
	return false

## Deliveries between this people's places, on the road and arrived.
func _economy_report(_kind:String)->Dictionary:
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:return {"blocks":_trade_blocks()})

var selected_food:=""
var show_priorities:=false
## The Food tab's one block (hud/food_folio.gd): the stores and the day's
## rations, the outlook, the water, the hands on food, where the food comes
## from, the fire and the deliveries on the road, all the engine's numbers.
func _provisions_data()->Dictionary:
	var metrics:Dictionary=GameState.simulation_metrics
	var id:=GameState.selected_player_settlement_id
	var city:=SettlementModel.settlement_record(id)
	var rows:Array=[]
	# Departing parties can draw from the live stock after the daily receipt.
	# Read current reserves, while keeping the receipt's flows and forecast dated.
	var stocks:Dictionary=GameState.food_stocks
	var stock_total:=float(stocks.get("Fresh food",0.0))+float(stocks.get("Stored food",0.0))
	var food_days:float=stock_total/float(metrics.food_consumption) if float(metrics.get("food_consumption",0.0))>0.0 else float(metrics.get("food_days",-1.0))
	# Who keeps each store from spoiling (food_care.gd): carriers the fresh,
	# keepers the stored, with the engine's own covers.
	var FoodCare:=preload("res://scripts/food_care.gd")
	var people:=maxf(1.0,GameState.population_exact)
	var hands:={"Fresh food":FoodCare.carrying_sentence(FoodCare.carry_cover_of(GameState),people),"Stored food":FoodCare.keeping_sentence(FoodCare.keep_cover_of(GameState),people)}
	for kind:String in ["Fresh food","Stored food"]:
		var amount:=float(stocks.get(kind,0));var waste:=float(metrics.get("food_spoilage_by_type",{}).get(kind,0))
		rows.append({"name":kind,"stock":amount,"lost":waste,"detail":String(hands.get(kind,""))})
	var management:=GovernmentPeopleSystem.settlement_management(id)
	var fire:Dictionary=metrics.get("fire_practice",{})
	var fuel:Dictionary=metrics.get("food_preservation_inputs",{})
	var deliveries:Array=[]
	var today:=int(GameState.elapsed_days)
	for shipment:Dictionary in GameState.city_trade_shipments:
		if String(shipment.get("destination_id",""))!=id or String(shipment.get("status",""))!="in_transit":continue
		var left:=maxi(0,ceili(float(shipment.get("arrival_day",today)))-today)
		deliveries.append({"resource":String(shipment.get("resource","")),"source_name":String(shipment.get("source_name","")),"quantity":float(shipment.get("quantity",0.0)),"when":"arrives today" if left<=0 else "arrives in "+Plain.span_text(left)})
	var block:={"type":"provisions","leader_name":String(management.get("leader",{}).get("name","")).get_slice(" ",0),"focus":String(management.get("focus","")),"city":String(city.get("name","Founding camp")),"managed":bool(city.get("auto_manage",true)),"can_direct":not city.is_empty() and String(city.get("occupied_by","")).is_empty(),
		"day":today,"flow_known":metrics.has_all(["food_production","food_eaten","food_spoilage","food_net"]),"forecast_day":metrics.get("food_forecast_day",-1),
		"rows":rows,"food_plan":GovernmentPeopleSystem.food_plan_words(),"lean":FoodCare.store_sentence(food_days) if food_days>=0.0 else "","food_days":food_days,"food_reserve_days":FoodSystem.reserve_estimate(float(metrics.get("food_consumption",0))).days,
		"storage_rows":preload("res://scripts/storage_works.gd").rows(["food","water"]),"on_expand_storage":_expand_storage.bind(id),"on_builders":assign_workers("Construction"),"capacity":FoodSystem._food_storage_capacity(),"food_workers":float(metrics.get("food_workers",0.0)),"food_share":float(metrics.get("food_labor_share",0.0)),
		"water":GameState.water_metrics.duplicate(true),"water_access":ResourceSystem.water_access_snapshot(),"forecast30":metrics.get("food_forecast_30",{}),"forecast90":metrics.get("food_forecast_90",{}),
		"sources":(metrics.get("food_sources",[]) as Array).duplicate(true),"fire":fire.duplicate(),"fuel":float(fuel.get("Timber",0.0)) if not fuel.is_empty() else -1.0,
		"history":_material_points(id,["food_days"]).get("food_days",[]),"deliveries":deliveries,
		"flow":{"Produced":metrics.get("food_production",0),"Taken":(metrics.get("food_harvest",{}) as Dictionary).get("Transferred",0.0),"Eaten":metrics.get("food_eaten",0),"Spoiled":metrics.get("food_spoilage",0),"Keeping":(metrics.get("food_preserved",{}) as Dictionary).get("lost",0.0),"Missions":FoodSystem.issued_on_day(today),"Net":metrics.get("food_net",0)},
		"on_assign":assign_workers("Food"),"on_assign_water":assign_workers("Logistics"),"on_talk":court({"settlement_id":id}),
		"on_focus":_provisions_focus,"has_deliveries":_has_food_deliveries(),"on_trade":focused_action("Deliveries between places","",_economy_report.bind("trade")).on_press}
	# Presence is meaningful: no daily report is not a day of zero production
	# or proof that everyone ate. Keep the presentation on the same receipt.
	for field:String in ["food_intake_ratio","food_consumption","food_home_need","food_home_eaten"]:
		if metrics.has(field):block["food_need" if field=="food_consumption" else field]=metrics[field]
	return block
func _has_food_deliveries()->bool:
	var trade:=SettlementModel.city_trade_snapshot(GameState.selected_player_settlement_id)
	return not (trade.get("shipments",[]) as Array).is_empty() or not (trade.get("history",[]) as Array).is_empty()

func _provisions_focus(focus:String)->void:
	var id:=GameState.selected_player_settlement_id
	if focus.is_empty():GovernmentPeopleSystem.restore_delegation(id)
	else:
		var result:=GovernmentPeopleSystem.set_settlement_focus(id,focus)
		if not bool(result.get("ok",false)):terrain._report_military_action({"message":String(result.get("reason","That cannot be asked just now."))})
	hud.request_immediate_dock_refresh()

var selected_material:=""
var materials_priorities:=false
var material_browse_state:Dictionary={"query":"","page":0,"sources_page":0}

## Each material's monthly counts for its spark, {key: [{day, value}]}, from
## the town's strategic history (monthly and yearly snapshots). They move only
## when a snapshot is taken, so they are kept until then.
func _material_points(id:String,keys:Array)->Dictionary:
	var ledger:Dictionary=GameState.strategic_history.get("scopes",{}).get(id,{})
	return memo.take("material_points",[id,keys,Memo.log_identity(ledger.get("monthly",[])),Memo.log_identity(ledger.get("annual",[]))],func()->Dictionary:
		var history:=preload("res://scripts/strategic_history.gd").points(GameState.strategic_history,id)
		var result:={}
		for key in keys:
			var points:Array=[]
			for observation:Dictionary in history:
				points.append({"day":observation.day,"value":observation.get(key,null)})
			result[key]=points
		return result)
func _materials_data()->Dictionary:
	var id:=GameState.selected_player_settlement_id
	var city:=SettlementModel.settlement_record(id)
	var metrics:Dictionary=GameState.material_metrics
	var grouped:Dictionary={}
	for deposit:Dictionary in ResourceSystem.visible_deposits():
		var key:=String(deposit.get("resource",""))
		if key.is_empty():continue
		var item:Dictionary=grouped.get(key,{"sites":[],"delivered":0.0})
		item.sites.append(deposit.duplicate(true));item.delivered+=float(deposit.get("delivered_today",0));grouped[key]=item
	for key:String in GameState.resource_stockpiles:
		if key!="Food" and float(GameState.resource_stockpiles[key])>.001 and not grouped.has(key):grouped[key]={"sites":[],"delivered":0.0}
	var trends:=_material_points(id,grouped.keys())
	var protected:=preload("res://scripts/local_material_reserves.gd").calculate()
	var rows:Array=[]
	for key:String in grouped:
		var item:Dictionary=grouped[key];var points:Array=trends[key]
		var details:Array[String]=[]
		var blocked:=false
		for site:Dictionary in item.sites:
			var blockers:Array=site.get("blockers",[])
			blocked=blocked or not blockers.is_empty()
			var condition:=", ".join(blockers) if not blockers.is_empty() else String(site.get("bottleneck",site.get("stage","Surveyed")))
			if ResourceSystem.deposit_exhausted(site):condition="worked out; nothing left to take"
			details.append(String(site.get("name",ResourceSystem.display_name(key)))+": "+condition.left(1).to_lower()+condition.substr(1))
		rows.append({"key":key,"name":ResourceSystem.display_name(key),"stock":float(GameState.resource_stockpiles.get(key,0)),"protected":float(protected.get(key,0)),"delivered":item.delivered,"points":points,"details":details,"blocked":blocked,"loss":float(metrics.get("losses_by_resource",{}).get(key,0))})
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var order:=["Timber","Stone","Clay","Fiber Plants","Copper Ore"]
		var ai:=order.find(a.key);var bi:=order.find(b.key)
		if ai!=bi:return (ai if ai>=0 else 999)<(bi if bi>=0 else 999)
		return String(a.name)<String(b.name))
	var incoming:Array=[]
	for shipment:Dictionary in GameState.city_trade_shipments:
		if String(shipment.get("destination_id",""))==id and String(shipment.get("status",""))=="in_transit":incoming.append(shipment.duplicate(true))
	var counted:PackedStringArray=[]
	for key:String in GameState.resource_stockpiles:
		if key!="Food" and float(GameState.resource_stockpiles[key])>=0.5 and ResourceSystem._is_material_resource(key):counted.append(ResourceSystem.display_name(key).to_lower())
	var land_reading:=ResourceSystem.land_reading()
	var land_condition:=ResourceSystem.land_heading(land_reading)
	var target_words:="toward %d" % roundi(float(land_reading.get("target",0.0))*100.0)
	land_condition=land_condition.replace(target_words,target_words+"%")
	land_condition=land_condition.left(1).to_upper()+land_condition.substr(1)+"."
	return {"type":"materials_ledger","storage_rows":preload("res://scripts/storage_works.gd").rows(),"on_expand_storage":_expand_storage.bind(id),"on_builders":assign_workers("Construction"),"title":"Materials","focus":String(GovernmentPeopleSystem.settlement_management(id).get("focus","")),"city":city.get("name","Founding camp"),"leader":GovernmentPeopleSystem.settlement_leader(id),"managed":city.get("auto_manage",true),"can_direct":not city.is_empty() and String(city.get("occupied_by","")).is_empty(),"storage":ResourceSystem.stored_bulk(),"capacity":ResourceSystem.storage_capacities().values().reduce(func(total:float,value:float):return total+value,0.0),"capacity_known":true,"hauling":metrics.get("flow_ratio",null),"waiting":metrics.get("at_source",null),"in_transit":metrics.get("in_transit",null),"land":ResourceSystem.land_words(),"cover":float(land_reading.get("cover",0.0)),"land_condition":land_condition,"counted":", ".join(counted),"rows":rows,"incoming":incoming,"day":GameState.elapsed_days,"selected":selected_material,"browse_state":material_browse_state,"priorities":materials_priorities,"on_select":func(key:String):selected_material=key;material_browse_state.sources_page=0;material_browse_state.sources_open=false;hud.request_immediate_dock_refresh(),"on_toggle":func():materials_priorities=not materials_priorities;hud.request_immediate_dock_refresh(),"on_map":terrain._toggle_resource_view,"on_assign":assign_workers("Extraction"),"on_assign_carriers":assign_workers("Logistics"),"on_focus":_provisions_focus,"on_trade":focused_action("Deliveries between places","",_economy_report.bind("trade")).on_press}

func _expand_storage(kind:String,id:String)->void:
	var storage=preload("res://scripts/storage_works.gd")
	var tracker=preload("res://scripts/order_tracker.gd")
	var card:=tracker.register(storage.title(kind).capitalize(),"buildings")
	var result:Dictionary=SettlementModel.with_city_resources(id,func()->Dictionary:
		var before:=storage.added(kind)
		var city:=SettlementModel.settlement_record(id)
		if not String(city.get("occupied_by","")).is_empty():return {"error":"Construction is unavailable while occupied."}
		if not city.is_empty() and SettlementModel.abandoned(city):return {"error":SettlementModel.left_reason(city)}
		var queued:Dictionary=storage.queue(kind) if city.is_empty() else preload("res://scripts/settlement_construction.gd").set_priority(id,storage.title(kind))
		queued["before"]=before
		return queued)
	if result.has("error"):tracker.refuse(card,String(result.error))
	else:
		tracker.supersede(card,"storage:%s:%s" % [id,kind])
		tracker.claim(card,"storage",{"kind":kind,"settlement_id":id,"before":result.before},"the builders","construction")
	terrain._report_military_action(result)
	hud.request_immediate_dock_refresh()
