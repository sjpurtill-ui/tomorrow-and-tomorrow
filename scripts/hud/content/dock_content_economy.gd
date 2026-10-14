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
			return {"kpis":preload("res://scripts/hud/materials_ledger.gd").kpis(materials),"blocks":[materials]}
		2:return _wealth_tab()
		3:return {"kpis":preload("res://scripts/hud/trade_board.gd").kpis(),"blocks":[{"type":"trade_board"}]}
	return _food_tab()

## The Food & water tab: this place's food and water. The common store holds
## goods and lives on Wealth (hud/purse_board.gd), as the treasury does.
func _food_tab()->Dictionary:
	var block:=_provisions_data()
	return {"kpis":preload("res://scripts/hud/food_folio.gd").kpis(block),"blocks":[block]}

func _open_section(section:String,sub:int)->void:
	if is_instance_valid(hud):hud.section_requested.emit(section,sub)

func signature()->Array:
	var result:Array=SettlementModel.with_city_resources(GameState.selected_player_settlement_id,_local_signature)
	result.append_array([selected_account,GameState.economy_stage,GameState.public_treasury,GameState.private_currency,GameState.currency_hoards,GameState.mutual_aid_reserve,GameState.weighed_metal_circulation,selected_material,materials_priorities,selected_food,show_priorities,GameState.settlement_network_revision,GameState.selected_player_settlement_id,GameState.elapsed_days,GameState.city_trade_shipments.size(),GameState.city_trade_history.size(),GovernmentPeopleSystem.revision])
	return result

func _local_signature()->Array:
	var metrics:Dictionary=GameState.simulation_metrics
	return [snappedf(float(metrics.get("food_days",0.0)),0.1),snappedf(float(metrics.get("food_net",0.0)),0.1),snappedf(ResourceSystem.stored_bulk(),0.1),snappedf(float(GameState.water_metrics.get("days",0.0)),0.1),snappedf(float(GameState.fire_practice.get("embers",0.0)),0.05)]

func _trade_block()->Dictionary:
	var city:=SettlementModel.selected_settlement()
	var trade:=SettlementModel.city_trade_snapshot(String(city.get("id","")))
	var today:=int(GameState.elapsed_days)
	var lines:Array[String]=[]
	if not bool(trade.capacity.ready): lines.append(String(trade.capacity.reason))
	else: lines.append("Your settlement leaders send spare stores to each other along known paths, up to %s km away, travelling about %s km a day." % [Plain.number(float(trade.capacity.range_km)),Plain.number(float(trade.capacity.speed_km_per_day))])
	for shipment in trade.shipments:
		var left:=maxi(0,ceili(float(shipment.arrival_day))-today)
		lines.append("%s %s on the way from %s to %s; arrives %s." % [Plain.number(float(shipment.quantity)),String(shipment.resource).to_lower(),String(shipment.source_name),String(shipment.destination_name),"today" if left<=0 else "in "+Plain.span_text(left)])
	var shown:=0
	for entry in trade.history:
		if String(entry.status)!="delivered": continue
		var ago:=maxi(0,today-int(entry.day))
		lines.append("%s %s arrived at %s from %s, %s." % [Plain.number(float(entry.delivered)),String(entry.resource).to_lower(),String(entry.destination_name),String(entry.source_name),"today" if ago<=0 else Plain.span_text(ago)+" ago"])
		shown+=1
		if shown>=5: break
	if trade.shipments.is_empty(): lines.append("Nothing is on the road just now.")
	return {"type":"text","heading":"Deliveries between places","text":"
".join(lines)}

var selected_account:=""
## The Wealth tab: what the people own and can trade, goods first, and the
## treasury once it is coin (hud/purse_board.gd, which reads the realm itself
## and refreshes on its own), then this place's day's work and its
## households' money. Trade between peoples mounts its own board between
## them: one line, blocks.append(<its block>), where marked.
func _wealth_tab()->Dictionary:
	return {"kpis":preload("res://scripts/hud/purse_board.gd").kpis(),"blocks":[{"type":"purse_board","mode":"wealth","on_open":_open_section,"ledger":_ledger_block()}]}

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
	var block:={"type":"wealth_ledger","title":"Wealth","stage":stage,"city":city.get("name","Founding camp"),"leader":GovernmentPeopleSystem.settlement_leader(GameState.selected_player_settlement_id),"managed":city.get("auto_manage",true),"economy":Indicators.economy(),"history":GameState.economy_history.slice(maxi(0,GameState.economy_history.size()-12)),"conditions":{"health":float(GameState.population_health),"cohesion":float(GameState.simulation_metrics.get("cohesion",1.0)),"housing":float(GameState.simulation_metrics.get("housing_ratio",1.0))},"accounts":accounts,"selected":selected_account,"on_select":func(key:String):selected_account="" if selected_account==key else key;hud.request_immediate_dock_refresh()}
	if not accounts.is_empty():block.on_history=focused_action("Past balances","",func()->Dictionary:return {"blocks":[Charts.finance(GameState.selected_player_settlement_id)]}).on_press
	return block

func open_expanded_tab(sub:int)->bool:
	return false

## Deliveries between this people's places, on the road and arrived.
func _economy_report(_kind:String)->Dictionary:
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:return {"blocks":[_trade_block()]})

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
	var stocks:Dictionary=metrics.get("food_stocks",GameState.food_stocks)
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
	return {"type":"provisions","leader_name":String(management.get("leader",{}).get("name","")).get_slice(" ",0),"focus":String(management.get("focus","")),"city":String(city.get("name","Founding camp")),"managed":bool(city.get("auto_manage",true)),"can_direct":not city.is_empty() and String(city.get("occupied_by","")).is_empty(),
		"rows":rows,"food_plan":GovernmentPeopleSystem.food_plan_words(),"lean":FoodCare.store_sentence(float(metrics.get("food_days",-1.0))) if metrics.has("food_days") else "","food_days":metrics.get("food_days",-1.0),
		"capacity":FoodSystem._food_storage_capacity(),"food_workers":_food_hands().x,"food_share":_food_hands().y,
		"water":GameState.water_metrics.duplicate(true),"water_access":ResourceSystem.water_access_snapshot(),"forecast30":metrics.get("food_forecast_30",{}),"forecast90":metrics.get("food_forecast_90",{}),
		"sources":(metrics.get("food_sources",[]) as Array).duplicate(true),"fire":fire.duplicate(),"fuel":float(fuel.get("Timber",0.0)) if not fuel.is_empty() else -1.0,
		"history":_material_points(id,["food_days"]).get("food_days",[]),"deliveries":deliveries,
		"flow":{"Produced":metrics.get("food_production",0),"Taken":(metrics.get("food_harvest",{}) as Dictionary).get("Transferred",0.0),"Eaten":metrics.get("food_eaten",0),"Spoiled":metrics.get("food_spoilage",0),"Keeping":(metrics.get("food_preserved",{}) as Dictionary).get("lost",0.0),"Missions":FoodSystem.issued_on_day(today),"Net":metrics.get("food_net",0)},
		"on_focus":_provisions_focus,"has_deliveries":_has_food_deliveries(),"on_trade":focused_action("Deliveries between places","",_economy_report.bind("trade")).on_press}
## Those getting food and their share of those who can work, by the Home
## People page's own reckoning (people_model.gd labor: manual_work.gd counts
## and percents), so both screens say the same.
func _food_hands()->Vector2:
	for row:Dictionary in preload("res://scripts/hud/people_model.gd").labor():
		if String(row.get("id",""))=="Food":return Vector2(float(row.get("count",0)),float(row.get("share",0))/100.0)
	return Vector2.ZERO

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
		rows.append({"key":key,"name":ResourceSystem.display_name(key),"stock":float(GameState.resource_stockpiles.get(key,0)),"delivered":item.delivered,"points":points,"details":details,"blocked":blocked,"loss":float(metrics.get("losses_by_resource",{}).get(key,0))})
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var order:=["Timber","Stone","Clay","Fiber Plants","Copper Ore"]
		var ai:=order.find(a.key);var bi:=order.find(b.key)
		if ai!=bi:return (ai if ai>=0 else 999)<(bi if bi>=0 else 999)
		return String(a.name)<String(b.name))
	var incoming:Array=[]
	for shipment:Dictionary in GameState.city_trade_shipments:
		if String(shipment.get("destination_id",""))==id and String(shipment.get("status",""))=="in_transit":incoming.append(shipment.duplicate(true))
	# Each kind of store: the bulk held in it against its room
	# (resource_system.gd _storage_capacities, each material's profile store).
	var held_by_kind:={}
	for key:String in GameState.resource_stockpiles:
		if key=="Food" or not ResourceSystem._is_material_resource(key):continue
		var profile:=ResourceSystem.material_profile(key)
		held_by_kind[String(profile.store)]=float(held_by_kind.get(String(profile.store),0.0))+float(GameState.resource_stockpiles[key])*float(profile.bulk)
	var rooms:=ResourceSystem.storage_capacities()
	var store_kinds:Array=[]
	for kind:String in ["yard","dry","covered","sealed","secure"]:
		if float(held_by_kind.get(kind,0.0))<0.5 and float(rooms.get(kind,0.0))<0.5:continue
		store_kinds.append({"kind":kind,"held":float(held_by_kind.get(kind,0.0)),"room":float(rooms.get(kind,0.0))})
	var counted:PackedStringArray=[]
	for key:String in GameState.resource_stockpiles:
		if key!="Food" and float(GameState.resource_stockpiles[key])>=0.5 and ResourceSystem._is_material_resource(key):counted.append(ResourceSystem.display_name(key).to_lower())
	return {"type":"materials_ledger","title":"Materials","focus":String(GovernmentPeopleSystem.settlement_management(id).get("focus","")),"city":city.get("name","Founding camp"),"leader":GovernmentPeopleSystem.settlement_leader(id),"managed":city.get("auto_manage",true),"can_direct":not city.is_empty() and String(city.get("occupied_by","")).is_empty(),"storage":ResourceSystem.stored_bulk(),"capacity":float(metrics.get("storage_capacity",0)),"hauling":metrics.get("flow_ratio",null),"land":ResourceSystem.land_words(),"cover":float(ResourceSystem.land_reading().get("cover",0.0)),"counted":", ".join(counted),"store_kinds":store_kinds,"rows":rows,"incoming":incoming,"day":GameState.elapsed_days,"selected":selected_material,"priorities":materials_priorities,"on_select":func(key:String):selected_material="" if selected_material==key else key;hud.request_immediate_dock_refresh(),"on_toggle":func():materials_priorities=not materials_priorities;hud.request_immediate_dock_refresh(),"on_map":terrain._toggle_resource_view,"on_focus":_provisions_focus,"on_trade":focused_action("Deliveries between places","",_economy_report.bind("trade")).on_press}
