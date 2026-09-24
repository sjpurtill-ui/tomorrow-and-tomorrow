extends "res://scripts/hud/content/dock_content_base.gd"
const Charts:=preload("res://scripts/hud/strategic_chart_blocks.gd")
const Indicators:=preload("res://scripts/civilization_indicators.gd")
var workshop_content:RefCounted
## ECONOMY section: Food & Water / Materials / Wealth.
## Replaces the provisions panel, the materials panel, and their overlays.

func meta()->Dictionary:
	return {
		"eyebrow":"ECONOMY · PROVISIONS & MATERIALS",
		"title":"Provisions","serif":true,"title_size":38,"spread_tabs":true,
		"subtabs":["FOOD & WATER","MATERIALS","WEALTH"],
	}

func tab(sub:int)->Dictionary:
	var data:Dictionary=SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary: return SettlementModel.with_local_population(func()->Dictionary: return _local_tab(sub)))
	if sub not in [0,1]: (data.blocks as Array).append({"type":"actions","items":[focused_action("CITY DELIVERIES","Routes, shipments and requirements",_economy_report.bind("trade"))]})
	return data

func _workshop_report()->Dictionary:
	if workshop_content==null:workshop_content=preload("res://scripts/hud/content/dock_content_military.gd").new(terrain,hud)
	return workshop_content._production_overview()

func _local_tab(sub:int)->Dictionary:
	match sub:
		1:return {"blocks":[_materials_data()]}
		2:return _wealth_tab()
	return {"blocks":[_provisions_data()]}

func _food_blocks(metrics:Dictionary)->Array:
	var produced:=float(metrics.get("food_production",0.0))
	var weather:=roundi(float(metrics.get("food_weather_factor",1.0))*100.0)
	var eaten:=float(metrics.get("food_eaten",0.0))
	var spoiled:=float(metrics.get("food_spoilage",0.0))
	var issued:=FoodSystem.issued_on_day(int(GameState.elapsed_days))
	var net:=float(metrics.get("food_net",0.0))
	var top:=maxf(1.0,maxf(produced,maxf(eaten,spoiled)))
	var flow_items:Array=[
		{"name":"Produced","value":"%+.0f" % produced,"ratio":produced/top,"color":Tokens.GREEN,"tip":"Rations produced today; current aggregate weather supports %d%% of ordinary yield" % weather},
		{"name":"Eaten","value":"−%.0f" % eaten,"ratio":eaten/top,"color":Tokens.TEAL,"tip":"Rations eaten today"},
		{"name":"Spoiled","value":"−%.0f" % spoiled,"ratio":spoiled/top,"color":Tokens.RED,"tip":"Rations lost to spoilage today"},
		{"name":"Missions","value":"−%.0f" % issued if issued>0.0 else "0","ratio":issued/top,"color":Tokens.MUTED,"tip":"Rations issued to departing missions"},
		{"name":"Net","value":"%+.0f" % net,"ratio":absf(net)/top,"color":Tokens.GREEN if net>=0.0 else Tokens.RED,"tip":"Today's net change to the reserve"},
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
		var sub_text:="ample store" if days_of_kind>999.0 else "%.1f days" % days_of_kind
		if amount<=0.05: sub_text="not yet produced" if String(food_type)=="Stored food" else "0 days"
		stock_items.append({
			"name":String(food_type),"sub":sub_text,
			"value":"%d · −%.0f" % [roundi(amount),lost] if lost>0.05 else str(roundi(amount)),
			"value_color":Tokens.BODY_2 if amount>0.05 else Tokens.MUTED,
			"accent":Tokens.GREEN if amount>0.05 else Color(0,0,0,0),
			"tip":"Stored rations · lost to spoilage today",
		})
	var source_items:Array=[]
	for source_variant in (metrics.get("food_sources",[]) as Array):
		var source:Dictionary=source_variant
		var amount:=float(source.get("produced",0.0))
		source_items.append({
			"name":String(source.get("name","Source")).capitalize(),
			"sub":String(source.get("access","unknown")),
			"value":"%+.0f" % amount if amount>0.05 else "0",
			"value_color":Tokens.GREEN if amount>0.05 else Tokens.MUTED,
			"accent":Tokens.GREEN if amount>0.05 else Color(0,0,0,0),
			"tip":"Today's production and current access for this source",
		})
	var blocks:Array=[Charts.reserves(GameState.selected_player_settlement_id),Charts.food_flow(GameState.selected_player_settlement_id),{"type":"bars","heading":"TODAY'S FLOW","note":"rations · weather %d%%" % weather,"items":flow_items}]
	var preparation:Dictionary=metrics.get("food_preparation",{})
	var fire:Dictionary=metrics.get("fire_practice",{})
	if not fire.is_empty():
		var fire_name:="Maintained embers" if bool(fire.get("available",false)) else "Fire unavailable"
		var source:=String(fire.get("source","none")).replace("_"," ").capitalize()
		blocks.append({"type":"rows","heading":"HEARTH FIRE","items":[{"name":fire_name,"sub":String(fire.get("status","No maintained fire")),"value":"%d%%" % roundi(clampf(float(fire.get("embers",0.0)),0.0,1.0)*100.0),"value_color":Tokens.GREEN if bool(fire.get("available",false)) else Tokens.RED,"accent":Tokens.AMBER if bool(fire.get("available",false)) else Color(0,0,0,0),"tip":"Source: %s · %.3f Timber used today to preserve or restore the fire" % [source,float(fire.get("maintenance_timber",0.0))]}]})
	if float(preparation.get("rations",0.0))>0.0:
		var inputs:Array[String]=[]
		for resource:String in preparation.get("inputs",{}):inputs.append("%.2f %s" % [float(preparation.inputs[resource]),resource])
		blocks.append({"type":"rows","heading":"MEAL PREPARATION","items":[{"name":String(DiscoverySystem.discovery_definition(String(preparation.method)).get("name","Prepared meals")),"sub":", ".join(inputs),"value":"%.1f rations" % float(preparation.rations),"tip":"Uses %.2f Logistics worker-days, shared with preservation. These rations are part of food eaten today." % float(preparation.get("workers_reserved",0.0))}]})
	var grain:Dictionary=metrics.get("grain_processing",{})
	var grain_items:Array=[]
	for kind:String in metrics.get("grain_stocks",{}):
		var stored:=float(metrics.grain_stocks[kind])
		if stored>0.001:grain_items.append({"name":kind.capitalize(),"value":"%.1f rations" % stored,"sub":"Included in available food"})
	if not grain_items.is_empty() or float(metrics.get("grain_in_process",0))>0:
		grain_items.append({"name":"Germinating","value":"%.1f rations" % float(metrics.get("grain_in_process",0)),"sub":"Unavailable until handling is complete"})
		grain_items.append({"name":"Processing loss today","value":"%.2f rations" % float(grain.get("loss",0)),"sub":"%.2f handler-days · %.2f electricity" % [float(grain.get("workers",0)),float(grain.get("electricity",0))]})
		blocks.append({"type":"rows","heading":"GRAIN PROCESSING","items":grain_items})
	var preservation_inputs:Dictionary=metrics.get("food_preservation_inputs",{})
	if not preservation_inputs.is_empty():
		blocks.append({"type":"rows","heading":"SMOKING FUEL","items":[{"name":"Timber used today","value":"%.2f" % float(preservation_inputs.get("Timber",0.0)),"sub":"Preserving meat and fish · shared processing staff"}]})
	if not stock_items.is_empty():
		blocks.append({"type":"rows","heading":"STORES BY KIND","note":"stock · lost today","items":stock_items})
	if not source_items.is_empty():
		blocks.append({"type":"rows","heading":"SOURCES","items":source_items})
	return blocks

func _materials_brief()->Dictionary:
	var material_metrics:Dictionary=GameState.material_metrics
	var stored:=ResourceSystem.stored_bulk()
	var capacity:=float(material_metrics.get("storage_capacity",0.0))
	var accessible:=0
	for deposit_variant in ResourceSystem.visible_deposits():
		var deposit:Dictionary=deposit_variant
		if String(deposit.get("stage","")) in ["accessible","developed"] and not ResourceSystem.deposit_exhausted(deposit):accessible+=1
	var raw:Dictionary=terrain._material_constraint_brief(material_metrics,accessible,capacity,stored)
	var status:=String(raw.get("status",""))
	var tone:="info" if "BALANCED" in status else "warn"
	return adapt_brief(raw,tone,"")

func _materials_blocks()->Array:
	var material_metrics:Dictionary=GameState.material_metrics
	var grouped:Dictionary={}
	for deposit_variant in ResourceSystem.visible_deposits():
		var deposit:Dictionary=deposit_variant
		var resource:=String(deposit.get("resource","Material"))
		var entry:Dictionary=grouped.get(resource,{"sites":0,"workable":0,"exhausted":0,"delivered":0.0,"bottleneck":""})
		entry.sites=int(entry.sites)+1
		if String(deposit.get("stage","")) in ["accessible","developed"]:
			if ResourceSystem.deposit_exhausted(deposit):entry.exhausted=int(entry.exhausted)+1
			else:entry.workable=int(entry.workable)+1
		entry.delivered=float(entry.delivered)+float(deposit.get("delivered_today",0.0))
		if String(entry.bottleneck)=="":
			entry.bottleneck=String((deposit.get("blockers",[]) as Array)[0]) if not (deposit.get("blockers",[]) as Array).is_empty() else String(deposit.get("bottleneck",""))
		grouped[resource]=entry
	var material_items:Array=[]
	for resource in grouped:
		var entry:Dictionary=grouped[resource]
		var workable:=int(entry.workable)
		var condition:="%d workable" % workable if workable>0 else "%d exhausted" % int(entry.exhausted) if int(entry.exhausted)>0 else String(entry.bottleneck).to_lower()
		material_items.append({
			"name":ResourceSystem.display_name(String(resource)),
			"sub":"%d site%s · %s" % [int(entry.sites),"" if int(entry.sites)==1 else "s",condition],
			"value":"%+.1f/day" % float(entry.delivered) if float(entry.delivered)>0.01 else "0",
			"value_color":Tokens.GREEN if float(entry.delivered)>0.01 else Tokens.MUTED,
			"accent":Tokens.GOLD if workable>0 else Color(0,0,0,0),
			"tip":ResourceSystem.plain_language_description(String(resource)) if ResourceSystem.plain_language_description(String(resource))!="" else "Recognized occurrences and today's delivered bulk",
		})
	if material_items.is_empty():
		material_items.append({"name":"Nothing recognized yet","sub":"Survey parties create clues and recognize deposits","value":"","tip":""})
	var stored:=ResourceSystem.stored_bulk()
	var capacity:=maxf(1.0,float(material_metrics.get("storage_capacity",1.0)))
	var flow_ratio:=clampf(float(material_metrics.get("flow_ratio",0.0)),0.0,1.0)
	var tool_quality:=clampf(0.25+DiscoverySystem.effect("tool_quality"),0.0,1.0)
	var constraint_items:Array=[
		{"name":"Hauling capacity","value":"%d%%" % roundi(flow_ratio*100.0),"ratio":flow_ratio,"color":Tokens.capacity_color(flow_ratio*100.0),"tip":"Share of extracted bulk actually delivered"},
		{"name":"Storage","value":"%d%%" % roundi(clampf(stored/capacity,0.0,1.0)*100.0),"ratio":clampf(stored/capacity,0.0,1.0),"color":Tokens.capacity_color(clampf(100.0-stored/capacity*100.0,0.0,100.0)),"tip":"Occupied share of aggregate bulk capacity"},
		{"name":"Tool quality","value":"%d%%" % roundi(tool_quality*100.0),"ratio":tool_quality,"color":Tokens.capacity_color(tool_quality*100.0),"tip":"Effect of makers and discovered practice on tools"},
	]
	var losses:Dictionary=material_metrics.get("losses_by_resource",{})
	for resource_variant in losses:
		constraint_items.append({"name":ResourceSystem.display_name(String(resource_variant))+" lost","value":"%.2f/day" % float(losses[resource_variant]),"ratio":clampf(float(losses[resource_variant])/maxf(1.0,float(GameState.resource_stockpiles.get(resource_variant,0.0))),0.0,1.0),"color":Tokens.RED,"tip":"Loss from decay, exposure, or the storage type required by this material being full."})
	var stock_names:Array=GameState.resource_stockpiles.keys()
	stock_names.sort_custom(func(a,b)->bool: return float(GameState.resource_stockpiles[b])<float(GameState.resource_stockpiles[a]))
	var storage_items:Array=[]
	for resource_name in stock_names:
		var amount:=float(GameState.resource_stockpiles[resource_name])
		if amount<0.05 or String(resource_name)=="Food": continue
		storage_items.append({
			"name":ResourceSystem.display_name(String(resource_name)),
			"sub":"","value":"%.0f" % amount if amount>=10.0 else "%.1f" % amount,
			"value_color":Tokens.INK,"accent":Tokens.TEAL,
			"tip":ResourceSystem.plain_language_description(String(resource_name)) if ResourceSystem.plain_language_description(String(resource_name))!="" else "Bulk units of %s held in settlement storage" % String(resource_name).to_lower(),
		})
	var storage_block:Dictionary={"type":"rows","heading":"IN STORAGE","note":"%.0f of %.0f bulk used" % [stored,capacity],"items":storage_items} if not storage_items.is_empty() else {"type":"text","heading":"IN STORAGE","text":"Nothing is stockpiled. Extraction delivers materials into storage; food is tracked in FOOD & WATER."}
	return [
		storage_block,
		{"type":"rows","heading":"RECOGNIZED MATERIALS","note":"sites · flow / day","items":material_items},
		{"type":"bars","heading":"CONSTRAINTS","items":constraint_items},
		{"type":"actions","items":[
			{"label":"SHOW RESOURCE LAYER","sub":"recognized deposits only","on_press":func()->void: hud.terrain._toggle_resource_view(),"tip":"Toggle the resource map layer"},
			{"label":"LOCAL LOGISTICS","sub":"direct this city’s carriers","primary":true,"on_press":func()->void: GovernmentPeopleSystem.set_settlement_focus(GameState.selected_player_settlement_id,"logistics"),"tip":"Ask this city’s leader to focus on logistics"},
		]},
	]

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
	var lines:Array[String]=[]
	if not bool(trade.capacity.ready): lines.append(String(trade.capacity.reason))
	else: lines.append("City leaders arrange deliveries from surplus stores over known, usable routes. Range %.0f km; speed %.0f km/day." % [float(trade.capacity.range_km),float(trade.capacity.speed_km_per_day)])
	for shipment in trade.shipments:
		lines.append("%s → %s: %.1f %s · arrives day %d" % [String(shipment.source_name),String(shipment.destination_name),float(shipment.quantity),String(shipment.resource),ceili(float(shipment.arrival_day))])
	var shown:=0
	for entry in trade.history:
		if String(entry.status)!="delivered": continue
		lines.append("Delivered %.1f %s: %s → %s · day %d" % [float(entry.delivered),String(entry.resource),String(entry.source_name),String(entry.destination_name),int(entry.day)])
		shown+=1
		if shown>=5: break
	if trade.shipments.is_empty(): lines.append("No deliveries in transit.")
	return {"type":"text","heading":"INTERCITY TRADE","text":"\n".join(lines)}

var selected_account:=""
var show_work:=false
func _wealth_tab()->Dictionary:
	var city:=SettlementModel.settlement_record(GameState.selected_player_settlement_id)
	var stage:=GameState.economy_stage
	var accounts:Array=[]
	var history:Array=Charts.finance(GameState.selected_player_settlement_id).get("items",[]) if stage in ["currency","weighed_metal"] else []
	var definitions:Array=[["treasury","Public treasury",GameState.public_treasury,0],["private_currency","Household money",GameState.private_currency,1],["hoards","Private hoards",GameState.currency_hoards,2],["aid","Mutual aid",GameState.mutual_aid_reserve,3]] if stage=="currency" else [["metal","Exchange metal",GameState.weighed_metal_circulation,-1]] if stage=="weighed_metal" else []
	for definition:Array in definitions:
		var points:Array=[]
		for row:Dictionary in history:points.append({"day":row.day,"value":row.get(definition[0],null)})
		accounts.append({"key":definition[0],"name":definition[1],"balance":float(definition[2]),"art":definition[3],"points":points})
	return {"blocks":[{"type":"wealth_ledger","title":"Wealth","stage":stage,"city":city.get("name","Founding camp"),"leader":GovernmentPeopleSystem.settlement_leader(GameState.selected_player_settlement_id),"managed":city.get("auto_manage",true),"economy":Indicators.economy(),"accounts":accounts,"selected":selected_account,"show_work":show_work,"on_select":func(key:String):selected_account="" if selected_account==key else key;hud.request_immediate_dock_refresh(),"on_work":func():show_work=not show_work;hud.request_immediate_dock_refresh(),"on_history":focused_action("Account history","",func()->Dictionary:return {"blocks":[Charts.finance(GameState.selected_player_settlement_id)]}).on_press,"on_stores":jump("economy",1),"on_policy":jump("government",0)}]}

func open_expanded_tab(sub:int)->bool:
	return false

func _food_overview()->Array:
	return [{"type":"text","heading":"READING THE RESERVES","text":"Days of food and water describe what is stored against current need. They are not a countdown while production continues. Local leaders handle routine provisioning."},
		{"type":"actions","heading":"UNDERSTAND THE SUPPLY","items":[
			focused_action("RESERVE OUTLOOK","History and seasonal forecast",_economy_report.bind("outlook")),
			focused_action("TODAY’S FOOD","Produced, eaten, spoiled and sent away",_economy_report.bind("flow")),
			focused_action("FOOD SOURCES","Where it comes from and what is stored",_economy_report.bind("sources")),
			focused_action("CITY DELIVERIES","Routes, shipments and requirements",_economy_report.bind("trade"))]},
		{"type":"actions","heading":"GIVE DIRECTION","items":[
			{"label":"LOCAL PRIORITY","sub":"Review the leader’s direction","on_press":jump("settlement",0)},
			{"label":"DISCUSS FOOD POLICY","sub":"Give your local leader an instruction, in the court","on_press":court({"settlement_id":String(SettlementModel.selected_settlement_snapshot().get("id",""))})}]}]

func _economy_report(kind:String)->Dictionary:
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:
		return SettlementModel.with_local_population(func()->Dictionary:
			if kind=="trade":return {"blocks":[_trade_block()]}
			var blocks:=_food_blocks(GameState.simulation_metrics)
			if kind=="outlook":return {"blocks":[blocks[0]]}
			if kind=="flow":return {"blocks":[blocks[1],blocks[2]]}
			return {"blocks":blocks.slice(3)}))

func _open_water()->void:
	hud.open_detail(preload("res://scripts/hud/content/focused_report.gd").new(terrain,hud,"WATER ACCESS",String(meta().title),_water_report,signature))

func _water_report()->Dictionary:
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:
		var water:Dictionary=GameState.water_metrics
		var access:=ResourceSystem.water_access_snapshot(terrain._discovery_context())
		var id:=GameState.selected_player_settlement_id
		var management:=GovernmentPeopleSystem.settlement_management(id)
		var recognized:=bool(access.get("recognized",false))
		var text:="No recognized freshwater source is recorded here. Direction can increase survey and carrying effort; it does not create water. Inspect charted terrain for a river or send scouts to learn about nearby ground."
		if recognized:text="%s · %.1f km away. %s"%[String(access.source_kind).capitalize(),float(access.distance_km),"Within collection reach. Household fetching and organized carriers supply the settlement." if bool(access.accessible) else "Beyond current collection reach. More carriers cannot make a distant source instantly accessible."]
		var daily:="The first daily collection report is pending. Unpause to advance the settlement; a zero before that report is not a measured shortage."
		if float(water.get("required_today",0))>0:daily="Daily drinking portions: %.0f collected last day / %.0f needed per day. Reserve: %.0f portions. One portion meets one person’s daily drinking need; this is an abstract unit, not liters. Collection changes as people work; choosing a priority does not refill stores."%[float(water.get("collected_today",0)),float(water.required_today),float(water.get("stored",0))]
		return {"brief":{"title":"Current direction: "+String(management.get("focus_label","Leader decides")),"why":String(management.get("focus_effect","Complete the Hearth Circle through normal work before directing a local leader."))},"blocks":[{"type":"text","heading":"THE SOURCE","text":text},{"type":"text","heading":"COLLECTION AND STORAGE","text":daily},{"type":"actions","items":[{"label":"PRIORITIZE WATER","sub":"Complete the Hearth Circle first" if management.is_empty() else "Ask the leader to change local work","disabled":management.is_empty(),"primary":true,"on_press":func()->void:
			var result:=GovernmentPeopleSystem.set_settlement_focus(id,"water")
			if not bool(result.get("ok",false)):terrain._report_military_action({"message":String(result.get("reason","Direction unavailable."))})
			hud.request_immediate_dock_refresh()},{"label":"LET LEADER DECIDE","sub":"Restore automatic local priorities","disabled":management.is_empty(),"on_press":func()->void:GovernmentPeopleSystem.restore_delegation(id);hud.request_immediate_dock_refresh()}]}]})

var selected_food:=""
var show_priorities:=false
func _provisions_data()->Dictionary:
	var metrics:Dictionary=GameState.simulation_metrics
	var city:=SettlementModel.settlement_record(GameState.selected_player_settlement_id)
	var rows:Array=[]
	var stocks:Dictionary=metrics.get("food_stocks",GameState.food_stocks)
	for group in [["Fresh food"],["Stored food"]]:
		var stock:=0.0;var lost:=0.0;var parts:Array[String]=[]
		for kind:String in group:
			var amount:=float(stocks.get(kind,0));var waste:=float(metrics.get("food_spoilage_by_type",{}).get(kind,0))
			stock+=amount;lost+=waste;parts.append("%s: %.1f rations · %.1f spoiled" % [kind,amount,waste])
		rows.append({"name":"Meat & fish" if group.size()>1 else group[0],"stock":stock,"lost":lost,"detail":"\n".join(parts)})
	return {"type":"provisions","city":String(city.get("name","Founding camp")),"managed":bool(city.get("auto_manage",true)),"can_direct":not city.is_empty() and String(city.get("occupied_by","")).is_empty(),"rows":rows,"food_days":metrics.get("food_days",0),"water":GameState.water_metrics.duplicate(true),"forecast30":metrics.get("food_forecast_30",{}),"forecast90":metrics.get("food_forecast_90",{}),"flow":{"Produced":metrics.get("food_production",0),"Eaten":metrics.get("food_eaten",0),"Spoiled":metrics.get("food_spoilage",0),"Missions":FoodSystem.issued_on_day(int(GameState.elapsed_days)),"Net":metrics.get("food_net",0)},"selected":selected_food,"priorities":show_priorities,"on_select":func(kind:String):selected_food="" if kind==selected_food else kind;hud.request_immediate_dock_refresh(),"on_toggle":func():show_priorities=not show_priorities;hud.request_immediate_dock_refresh(),"on_focus":_provisions_focus,"on_water":_open_water,"on_sources":focused_action("Sources","",_economy_report.bind("sources")).on_press,"on_history":focused_action("Reserve history","",_economy_report.bind("outlook")).on_press,"on_trade":focused_action("City deliveries","",_economy_report.bind("trade")).on_press}
func _provisions_focus(focus:String)->void:
	var id:=GameState.selected_player_settlement_id
	if focus.is_empty():GovernmentPeopleSystem.restore_delegation(id)
	else:
		var result:=GovernmentPeopleSystem.set_settlement_focus(id,focus)
		if not bool(result.get("ok",false)):terrain._report_military_action({"message":String(result.get("reason","Direction unavailable"))})
	hud.request_immediate_dock_refresh()

var selected_material:=""
var materials_priorities:=false
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
	var history:=preload("res://scripts/strategic_history.gd").points(GameState.strategic_history,id)
	var rows:Array=[]
	for key:String in grouped:
		var item:Dictionary=grouped[key];var points:Array=[]
		for observation:Dictionary in history:
			points.append({"day":observation.day,"value":observation.get(key,null)})
		var details:Array[String]=[]
		var blocked:=false
		for site:Dictionary in item.sites:
			var blockers:Array=site.get("blockers",[])
			blocked=blocked or not blockers.is_empty()
			var condition:=", ".join(blockers) if not blockers.is_empty() else String(site.get("bottleneck",site.get("stage","Surveyed")))
			if ResourceSystem.deposit_exhausted(site):condition="Exhausted"
			details.append(String(site.get("name",ResourceSystem.display_name(key)))+" · "+condition)
		rows.append({"key":key,"name":ResourceSystem.display_name(key),"stock":float(GameState.resource_stockpiles.get(key,0)),"delivered":item.delivered,"points":points,"details":details,"blocked":blocked,"loss":float(metrics.get("losses_by_resource",{}).get(key,0))})
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var order:=["Timber","Stone","Clay","Fiber Plants","Copper Ore"]
		var ai:=order.find(a.key);var bi:=order.find(b.key)
		if ai!=bi:return (ai if ai>=0 else 999)<(bi if bi>=0 else 999)
		return String(a.name)<String(b.name))
	var incoming:Array=[]
	for shipment:Dictionary in GameState.city_trade_shipments:
		if String(shipment.get("destination_id",""))==id and String(shipment.get("status",""))=="in_transit":incoming.append(shipment.duplicate(true))
	return {"type":"materials_ledger","title":"Materials","city":city.get("name","Founding camp"),"leader":GovernmentPeopleSystem.settlement_leader(id),"managed":city.get("auto_manage",true),"can_direct":not city.is_empty() and String(city.get("occupied_by","")).is_empty(),"storage":ResourceSystem.stored_bulk(),"capacity":float(metrics.get("storage_capacity",0)),"hauling":metrics.get("flow_ratio",null),"rows":rows,"incoming":incoming,"day":GameState.elapsed_days,"selected":selected_material,"priorities":materials_priorities,"on_select":func(key:String):selected_material="" if selected_material==key else key;hud.request_immediate_dock_refresh(),"on_toggle":func():materials_priorities=not materials_priorities;hud.request_immediate_dock_refresh(),"on_map":terrain._toggle_resource_view,"on_focus":_provisions_focus,"on_trade":focused_action("City deliveries","",_economy_report.bind("trade")).on_press,"on_atlas":func():preload("res://scripts/hud/knowledge_atlas.gd").open(terrain,hud,"materials")}
