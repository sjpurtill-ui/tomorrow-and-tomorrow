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
		1:return {"blocks":[_materials_data()]}
		2:return _wealth_tab()
		3:return {"blocks":[{"type":"trade_board"}]}
	return _food_tab()

## The Food & water tab: this place's food and water, then the common store
## while it is food (hud/purse_board.gd "store": the levy, what it pays for).
## After coinage the treasury is coin and lives on Wealth.
func _food_tab()->Dictionary:
	var blocks:Array=[_provisions_data()]
	if Purse.in_kind():blocks.append({"type":"purse_board","mode":"store","on_open":_open_section})
	return {"blocks":blocks}

func _open_section(section:String,sub:int)->void:
	if is_instance_valid(hud):hud.section_requested.emit(section,sub)

func _food_blocks(metrics:Dictionary)->Array:
	var produced:=float(metrics.get("food_production",0.0))
	var weather:=roundi(float(metrics.get("food_weather_factor",1.0))*100.0)
	var eaten:=float(metrics.get("food_eaten",0.0))
	var spoiled:=float(metrics.get("food_spoilage",0.0))
	var issued:=FoodSystem.issued_on_day(int(GameState.elapsed_days))
	var net:=float(metrics.get("food_net",0.0))
	var top:=maxf(1.0,maxf(produced,maxf(eaten,spoiled)))
	var flow_items:Array=[
		{"name":"Came in","value":"+%s" % Plain.number(produced),"ratio":produced/top,"color":Tokens.GREEN,"tip":"Rations gathered, hunted, fished or harvested today. The weather allows about %d%% of a normal day's yield." % weather},
		{"name":"Eaten","value":"−%s" % Plain.number(eaten),"ratio":eaten/top,"color":Tokens.TEAL,"tip":"Rations eaten today"},
		{"name":"Spoiled","value":"−%s" % Plain.number(spoiled),"ratio":spoiled/top,"color":Tokens.RED,"tip":"Rations that went bad in store today"},
		{"name":"Sent with parties","value":"−%s" % Plain.number(issued) if issued>0.0 else "none","ratio":issued/top,"color":Tokens.MUTED,"tip":"Rations carried away by parties leaving today"},
		{"name":"Change to stores","value":("+" if net>=0.0 else "−")+Plain.number(absf(net)),"ratio":absf(net)/top,"color":Tokens.GREEN if net>=0.0 else Tokens.RED,"tip":"How much the stores grew or shrank today"},
	]
	var stocks:Dictionary=metrics.get("food_stocks",GameState.food_stocks)
	var spoilage_by_type:Dictionary=metrics.get("food_spoilage_by_type",{})
	var eaten_per_day:=maxf(0.5,eaten)
	var stock_items:Array=[]
	for food_type in FoodSystem.FOOD_TYPES:
		var amount:=float(stocks.get(food_type,0.0))
		var lost:=float(spoilage_by_type.get(food_type,0.0))
		if amount<=0.05 and lost<=0.05 and String(food_type) not in ["Fresh food","Stored food"]: continue
		var days_of_kind:=amount/eaten_per_day
		var sub_text:="enough alone for years" if days_of_kind>999.0 else "enough alone for "+Plain.span_text(days_of_kind)
		if amount<=0.05: sub_text="none made yet" if String(food_type)=="Stored food" else "none left"
		stock_items.append({
			"name":String(food_type),"sub":sub_text+("; %s spoil a day" % Plain.number(lost) if lost>0.05 else ""),
			"value":"%s rations" % Plain.number(amount),
			"value_color":Tokens.BODY_2 if amount>0.05 else Tokens.MUTED,
			"accent":Tokens.GREEN if amount>0.05 else Color(0,0,0,0),
			"tip":"Rations of this kind in store, and how long they would feed everyone on their own",
		})
	var source_items:Array=[]
	for source_variant in (metrics.get("food_sources",[]) as Array):
		var source:Dictionary=source_variant
		var amount:=float(source.get("produced",0.0))
		var sub:=String(source.get("access","unknown")).capitalize()
		var ground:=float(source.get("source_health",1.0))
		if source.has("renewable") and ground<0.95:sub+="; the land holds about %d in 10 of what it once did" % roundi(ground*10.0)
		if bool(source.get("overused",false)):sub+="; we take more than grows back"
		source_items.append({
			"name":String(source.get("name","Source")).capitalize(),
			"sub":sub,
			"value":"+%s a day" % Plain.number(amount) if amount>0.05 else "nothing today",
			"value_color":(Tokens.AMBER if bool(source.get("overused",false)) else Tokens.GREEN) if amount>0.05 else Tokens.MUTED,
			"accent":Tokens.GREEN if amount>0.05 else Color(0,0,0,0),
			"tip":"Rations this source gave today" if not source.has("renewable") else "Rations this source gave today. The land nearby grows back about %s rations a day of it; taking more thins the game, fish or plants until they are rested." % Plain.number(float(source.renewable)),
		})
	var blocks:Array=[Charts.reserves(GameState.selected_player_settlement_id),Charts.food_flow(GameState.selected_player_settlement_id),{"type":"bars","heading":"Today's food","note":"in rations","items":flow_items}]
	var preparation:Dictionary=metrics.get("food_preparation",{})
	var fire:Dictionary=metrics.get("fire_practice",{})
	if not fire.is_empty():
		var lit:=bool(fire.get("available",false))
		var source:=String(fire.get("source","none")).replace("_"," ").capitalize()
		var timber:=float(fire.get("maintenance_timber",0.0))
		blocks.append({"type":"rows","heading":"Hearth fire","note":"how strong the embers are","items":[{"name":"Embers kept alight" if lit else "No fire","sub":String(fire.get("status","No one is keeping a fire")),"value":"%d%%" % roundi(clampf(float(fire.get("embers",0.0)),0.0,1.0)*100.0),"value_color":Tokens.GREEN if lit else Tokens.RED,"accent":Tokens.AMBER if lit else Color(0,0,0,0),"tip":"Lit by: %s. Keeping it alive burned %s wood today." % [source,Plain.number(timber)]}]})
	if float(preparation.get("rations",0.0))>0.0:
		var inputs:Array[String]=[]
		for resource:String in preparation.get("inputs",{}):inputs.append("%s %s" % [Plain.number(float(preparation.inputs[resource])),resource])
		blocks.append({"type":"rows","heading":"Meal preparation","items":[{"name":String(DiscoverySystem.discovery_definition(String(preparation.method)).get("name","Prepared meals")),"sub":"Uses "+", ".join(inputs),"value":"%.1f rations" % float(preparation.rations),"tip":"These cooked meals are part of today's food eaten. The same hands also smoke and dry food for keeping."}]})
	var grain:Dictionary=metrics.get("grain_processing",{})
	var grain_items:Array=[]
	for kind:String in metrics.get("grain_stocks",{}):
		var stored:=float(metrics.grain_stocks[kind])
		if stored>0.001:grain_items.append({"name":kind.capitalize(),"value":"%s rations" % Plain.number(stored),"sub":"Counted in the food stores"})
	if not grain_items.is_empty() or float(metrics.get("grain_in_process",0))>0:
		grain_items.append({"name":"Being sprouted","value":"%s rations" % Plain.number(float(metrics.get("grain_in_process",0))),"sub":"Not ready to eat until the work is done"})
		grain_items.append({"name":"Lost in the work today","value":"%s rations" % Plain.number(float(grain.get("loss",0))),"sub":"Some grain is always lost in threshing and sprouting"})
		blocks.append({"type":"rows","heading":"Grain work","items":grain_items})
	var preservation_inputs:Dictionary=metrics.get("food_preservation_inputs",{})
	if not preservation_inputs.is_empty():
		blocks.append({"type":"rows","heading":"Smoking fuel","items":[{"name":"Wood burned today","value":Plain.number(float(preservation_inputs.get("Timber",0.0))),"sub":"To smoke meat and fish so they keep"}]})
	if not stock_items.is_empty():
		blocks.append({"type":"rows","heading":"Stores by kind","items":stock_items})
	if not source_items.is_empty():
		blocks.append({"type":"rows","heading":"Where food comes from","items":source_items})
	return blocks

func signature()->Array:
	var result:Array=SettlementModel.with_city_resources(GameState.selected_player_settlement_id,_local_signature)
	result.append_array([selected_account,show_work,GameState.economy_stage,GameState.public_treasury,GameState.private_currency,GameState.currency_hoards,GameState.mutual_aid_reserve,GameState.weighed_metal_circulation,selected_material,materials_priorities,selected_food,show_priorities,GameState.settlement_network_revision,GameState.selected_player_settlement_id,GameState.elapsed_days,GameState.city_trade_shipments.size(),GameState.city_trade_history.size(),GovernmentPeopleSystem.revision])
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
var show_work:=false
## The Wealth tab: what the people own and can trade, goods first, and the
## treasury once it is coin (hud/purse_board.gd, which reads the realm itself
## and refreshes on its own), then this place's day's work and its
## households' money. Trade between peoples mounts its own board between
## them: one line, blocks.append(<its block>), where marked.
func _wealth_tab()->Dictionary:
	var blocks:Array=[{"type":"purse_board","mode":"wealth","on_open":_open_section}]
	# Trade between peoples (econ-trade) mounts its board here.
	blocks.append(_ledger_block())
	return {"blocks":blocks}

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
	return {"type":"wealth_ledger","title":"Wealth","stage":stage,"city":city.get("name","Founding camp"),"leader":GovernmentPeopleSystem.settlement_leader(GameState.selected_player_settlement_id),"managed":city.get("auto_manage",true),"economy":Indicators.economy(),"history":GameState.economy_history.slice(maxi(0,GameState.economy_history.size()-12)),"conditions":{"health":float(GameState.population_health),"cohesion":float(GameState.simulation_metrics.get("cohesion",1.0)),"housing":float(GameState.simulation_metrics.get("housing_ratio",1.0))},"accounts":accounts,"selected":selected_account,"show_work":show_work,"on_select":func(key:String):selected_account="" if selected_account==key else key;hud.request_immediate_dock_refresh(),"on_work":func():show_work=not show_work;hud.request_immediate_dock_refresh(),"on_history":focused_action("Past balances","",func()->Dictionary:return {"blocks":[Charts.finance(GameState.selected_player_settlement_id)]}).on_press,"on_stores":jump("economy",1),"on_policy":court({})}

func open_expanded_tab(sub:int)->bool:
	return false

func _economy_report(kind:String)->Dictionary:
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:
		return SettlementModel.with_local_population(func()->Dictionary:
			if kind=="trade":return {"blocks":[_trade_block()]}
			var blocks:=_food_blocks(GameState.simulation_metrics)
			if kind=="outlook":return {"blocks":[blocks[0]]}
			if kind=="flow":return {"blocks":[blocks[1],blocks[2]]}
			return {"blocks":blocks.slice(3)}))

func _open_water()->void:
	hud.open_detail(preload("res://scripts/hud/content/focused_report.gd").new(terrain,hud,"Water",String(meta().title),_water_report,signature))

func _water_report()->Dictionary:
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:
		var water:Dictionary=GameState.water_metrics
		var access:=ResourceSystem.water_access_snapshot(terrain._discovery_context())
		var id:=GameState.selected_player_settlement_id
		var management:=GovernmentPeopleSystem.settlement_management(id)
		var leader:=String(management.get("leader",{}).get("name","the leader")).get_slice(" ",0)
		var recognized:=bool(access.get("recognized",false))
		var text:="No stream, spring or lake is known near here. More carriers cannot make water appear: scouts or a closer look at the map may find a source."
		if recognized:text="%s, %s km away. %s"%[String(access.source_kind).capitalize(),Plain.number(float(access.distance_km)),"Close enough to fetch every day; households and carriers bring it in." if bool(access.accessible) else "Too far to fetch every day. More carriers will not bring it closer."]
		var daily:="Water is counted at the end of each day. Let a day pass for the first count."
		if float(water.get("required_today",0))>0:
			var reading:=preload("res://scripts/hud/home_plain.gd").water(water)
			daily="%s. Yesterday %s drinks were fetched for the %s needed each day, and %s are kept in store. One drink here is one person's water for a day." % [String(reading.headline),Plain.number(float(water.get("collected_today",0))),Plain.number(float(water.required_today)),Plain.number(float(water.get("stored",0)))]
		var water_focus:=not bool(management.get("auto_manage",true)) and String(management.get("focus",""))=="water"
		return {"brief":{"title":("You asked %s for more hands on water" % leader) if water_focus else ("%s decides the water work" % leader.capitalize() if bool(management.get("auto_manage",true)) else "You asked %s for more hands on other work" % leader),"why":String(management.get("focus_effect","The Hearth Circle must be finished before you can ask the leader for anything."))},"blocks":[{"type":"text","heading":"Where the water comes from","text":text},{"type":"text","heading":"Fetching and storing","text":daily},{"type":"actions","items":[{"label":"More hands on water"+(" (now)" if water_focus else ""),"sub":"Finish the Hearth Circle first" if management.is_empty() else "Ask %s to put more people on water" % leader,"disabled":management.is_empty(),"primary":water_focus,"on_press":func()->void:
			var result:=GovernmentPeopleSystem.set_settlement_focus(id,"water")
			if not bool(result.get("ok",false)):terrain._report_military_action({"message":String(result.get("reason","That cannot be asked just now."))})
			hud.request_immediate_dock_refresh()},{"label":"Let %s decide" % leader+(" (now)" if bool(management.get("auto_manage",true)) else ""),"sub":"The leader spreads the work across what the place needs","disabled":management.is_empty(),"primary":bool(management.get("auto_manage",true)),"on_press":func()->void:GovernmentPeopleSystem.restore_delegation(id);hud.request_immediate_dock_refresh()}]}]})

var selected_food:=""
var show_priorities:=false
func _provisions_data()->Dictionary:
	var metrics:Dictionary=GameState.simulation_metrics
	var city:=SettlementModel.settlement_record(GameState.selected_player_settlement_id)
	var rows:Array=[]
	var stocks:Dictionary=metrics.get("food_stocks",GameState.food_stocks)
	# Who keeps each store from spoiling (food_care.gd): carriers the fresh,
	# keepers the stored, with the engine's own covers.
	var FoodCare:=preload("res://scripts/food_care.gd")
	var people:=maxf(1.0,GameState.population_exact)
	var hands:={"Fresh food":FoodCare.carrying_sentence(FoodCare.carry_cover_of(GameState),people),"Stored food":FoodCare.keeping_sentence(FoodCare.keep_cover_of(GameState),people)}
	for group in [["Fresh food"],["Stored food"]]:
		var stock:=0.0;var lost:=0.0;var parts:Array[String]=[]
		for kind:String in group:
			var amount:=float(stocks.get(kind,0));var waste:=float(metrics.get("food_spoilage_by_type",{}).get(kind,0))
			stock+=amount;lost+=waste;parts.append("%s: %s rations in store, %s spoiled today. %s" % [kind,Plain.number(amount),Plain.number(waste),String(hands.get(kind,""))])
		rows.append({"name":"Meat & fish" if group.size()>1 else group[0],"stock":stock,"lost":lost,"detail":"\n".join(parts)})
	var management:=GovernmentPeopleSystem.settlement_management(GameState.selected_player_settlement_id)
	return {"type":"provisions","leader_name":String(management.get("leader",{}).get("name","")).get_slice(" ",0),"focus":String(management.get("focus","")),"city":String(city.get("name","Founding camp")),"managed":bool(city.get("auto_manage",true)),"can_direct":not city.is_empty() and String(city.get("occupied_by","")).is_empty(),"rows":rows,"food_plan":GovernmentPeopleSystem.food_plan_words(),"lean":FoodCare.store_sentence(float(metrics.get("food_days",-1.0))) if metrics.has("food_days") else "","food_days":metrics.get("food_days",-1.0),"water":GameState.water_metrics.duplicate(true),"forecast30":metrics.get("food_forecast_30",{}),"forecast90":metrics.get("food_forecast_90",{}),"flow":{"Produced":metrics.get("food_production",0),"Eaten":metrics.get("food_eaten",0),"Spoiled":metrics.get("food_spoilage",0),"Missions":FoodSystem.issued_on_day(int(GameState.elapsed_days)),"Net":metrics.get("food_net",0)},"selected":selected_food,"priorities":show_priorities,"on_select":func(kind:String):selected_food="" if kind==selected_food else kind;hud.request_immediate_dock_refresh(),"on_toggle":func():show_priorities=not show_priorities;hud.request_immediate_dock_refresh(),"on_focus":_provisions_focus,"on_water":_open_water,"on_sources":focused_action("Where food comes from","",_economy_report.bind("sources")).on_press,"on_history":focused_action("Past seasons","",_economy_report.bind("outlook")).on_press,"on_trade":focused_action("Deliveries between places","",_economy_report.bind("trade")).on_press}
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
	return {"type":"materials_ledger","title":"Materials","focus":String(GovernmentPeopleSystem.settlement_management(id).get("focus","")),"city":city.get("name","Founding camp"),"leader":GovernmentPeopleSystem.settlement_leader(id),"managed":city.get("auto_manage",true),"can_direct":not city.is_empty() and String(city.get("occupied_by","")).is_empty(),"storage":ResourceSystem.stored_bulk(),"capacity":float(metrics.get("storage_capacity",0)),"hauling":metrics.get("flow_ratio",null),"land":ResourceSystem.land_words(),"rows":rows,"incoming":incoming,"day":GameState.elapsed_days,"selected":selected_material,"priorities":materials_priorities,"on_select":func(key:String):selected_material="" if selected_material==key else key;hud.request_immediate_dock_refresh(),"on_toggle":func():materials_priorities=not materials_priorities;hud.request_immediate_dock_refresh(),"on_map":terrain._toggle_resource_view,"on_focus":_provisions_focus,"on_trade":focused_action("Deliveries between places","",_economy_report.bind("trade")).on_press}
