extends "res://scripts/hud/content/dock_content_base.gd"
const Charts:=preload("res://scripts/hud/strategic_chart_blocks.gd")
## ECONOMY section: Food & Water / Materials / Who Eats.
## Replaces the provisions panel, the materials panel, and their overlays.

func meta()->Dictionary:
	return {
		"eyebrow":"ECONOMY · PROVISIONS & MATERIALS",
		"title":"%s · Provisions" % String(SettlementModel.selected_settlement().get("name","Settlement")),
		"subtabs":["FOOD & WATER","MATERIALS","WHO EATS","WEALTH"],
	}

func tab(sub:int)->Dictionary:
	var data:Dictionary=SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary: return SettlementModel.with_local_population(func()->Dictionary: return _local_tab(sub)))
	if sub!=0: (data.blocks as Array).append({"type":"actions","items":[focused_action("CITY DELIVERIES","Routes, shipments and requirements",_economy_report.bind("trade"))]})
	return data

func _local_tab(sub:int)->Dictionary:
	if sub==3: return _wealth_tab()
	var metrics:Dictionary=GameState.simulation_metrics
	var water:Dictionary=GameState.water_metrics
	var food_days:=float(metrics.get("food_days",0.0))
	var net:=float(metrics.get("food_net",0.0))
	var intake:=roundi(clampf(float(metrics.get("food_intake_ratio",1.0)),0.0,1.2)*100.0)
	var diet:=roundi(clampf(float(metrics.get("food_diet_quality",0.0)),0.0,1.0)*100.0)
	var water_days:=float(water.get("days",0.0))
	var water_intake:=roundi(clampf(float(water.get("intake_ratio",1.0)),0.0,1.2)*100.0)
	var forecast:Dictionary=metrics.get("food_forecast_90",{})
	var shortage_day:=int(forecast.get("first_shortage_day",-1))
	var kpis:Array=[
		{"label":"FOOD RESERVE","value":"%.1f days" % food_days,"delta":"%+.0f/day" % net,"delta_color":Tokens.GREEN if net>=0.0 else Tokens.RED,"accent":Tokens.AMBER,"tip":"Days of adult-equivalent rations in store"},
		{"label":"INTAKE","value":"%d%%" % intake,"delta":"diet %d%%" % diet,"delta_color":Tokens.MUTED,"accent":Tokens.TEAL,"tip":"Share of today's ration need actually received"},
		{"label":"WATER","value":"%.1f days" % water_days,"delta":"%d%%" % water_intake,"delta_color":Tokens.GREEN if water_intake>=100 else Tokens.RED,"accent":Tokens.TEAL,"tip":"Stored drinking water"},
		{"label":"OUTLOOK","value":"%d d" % shortage_day if shortage_day>0 else "clear","delta":"to shortage" if shortage_day>0 else "90-day forecast","delta_color":Tokens.RED if shortage_day>0 else Tokens.GREEN,"accent":Tokens.RED if shortage_day>0 else Tokens.GREEN,"tip":"90-day seasonal forecast"},
	]
	var day:=int(GameState.elapsed_days)
	var raw_brief:Dictionary=terrain._provisions_decision_brief(metrics,water,FoodSystem.issued_on_day(day))
	if not water.has("required_today"):
		raw_brief={"status":"First collection report pending","why":"The settlement has not completed its first day of water collection.","next":"Review nearby water access, then let time advance to see actual collection."}
	elif water_intake<98:
		raw_brief["next"]="Review water access and ask the local leader to prioritize water. The leader assigns the work; a direction cannot create a missing source."
	var status:=String(raw_brief.get("status",""))
	var tone:="info" if "STABLE" in status else ("danger" if ("SHORTAGE" in status or "SHORTFALL" in status) else "warn")
	var brief:=adapt_brief(raw_brief,tone,"WATER ACCESS",func()->void:_open_water())
	match sub:
		1: return {"kpis":kpis,"brief":_materials_brief(),"blocks":[Charts.stocks(GameState.selected_player_settlement_id)]+_materials_blocks()}
		2: return {"kpis":kpis,"brief":brief,"blocks":_who_eats_blocks(metrics)}
	return {"kpis":[kpis[0],kpis[2]],"brief":brief,"blocks":_food_overview()}

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
		if amount<=0.05 and lost<=0.05 and String(food_type) not in ["Fresh plants","Preserved food"]: continue
		var days_of_kind:=amount/eaten_per_day
		var sub_text:="ample store" if days_of_kind>999.0 else "%.1f days" % days_of_kind
		if amount<=0.05: sub_text="not yet produced" if String(food_type)=="Preserved food" else "0 days"
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
		if float((deposit_variant as Dictionary).get("access",0.0))>0.5: accessible+=1
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
		var entry:Dictionary=grouped.get(resource,{"sites":0,"accessible":0,"delivered":0.0,"bottleneck":""})
		entry.sites=int(entry.sites)+1
		if float(deposit.get("access",0.0))>0.5: entry.accessible=int(entry.accessible)+1
		entry.delivered=float(entry.delivered)+float(deposit.get("delivered_today",0.0))
		if String(entry.bottleneck)=="": entry.bottleneck=String(deposit.get("bottleneck",""))
		grouped[resource]=entry
	var material_items:Array=[]
	for resource in grouped:
		var entry:Dictionary=grouped[resource]
		var accessible:=int(entry.accessible)
		material_items.append({
			"name":ResourceSystem.display_name(String(resource)),
			"sub":"%d site%s · %s" % [int(entry.sites),"" if int(entry.sites)==1 else "s","reachable" if accessible>0 else String(entry.bottleneck).to_lower()],
			"value":"%+.1f/day" % float(entry.delivered) if float(entry.delivered)>0.01 else "0",
			"value_color":Tokens.GREEN if float(entry.delivered)>0.01 else Tokens.MUTED,
			"accent":Tokens.GOLD if accessible>0 else Color(0,0,0,0),
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
			{"label":"SHOW RESOURCE LAYER","sub":"recognized deposits only","on_press":func()->void: hud._on_layer_toggle("resources"),"tip":"Toggle the resource map layer"},
			{"label":"LOCAL LOGISTICS","sub":"direct this city’s carriers","primary":true,"on_press":func()->void: GovernmentPeopleSystem.set_settlement_focus(GameState.selected_player_settlement_id,"logistics"),"tip":"Ask this city’s leader to focus on logistics"},
		]},
	]

func _who_eats_blocks(metrics:Dictionary)->Array:
	var demand:Dictionary=metrics.get("food_demand_breakdown",{})
	var base:=float(demand.get("children",0.0))+float(demand.get("adults",0.0))+float(demand.get("elders",0.0))
	var labor:=float(demand.get("labor",0.0))
	var climate:=float(demand.get("climate",0.0))
	var pregnancy:=float(demand.get("pregnancy",0.0))+float(demand.get("lactation",0.0))
	var top:=maxf(1.0,base)
	var items:Array=[
		{"name":"Base metabolism","value":"%.0f" % base,"ratio":base/top,"color":Tokens.TEAL,"tip":"Children, adults, and elders at rest"},
		{"name":"Physical work","value":"%.1f" % labor,"ratio":labor/top,"color":Tokens.TEAL,"tip":"Extra need from assigned labor"},
		{"name":"Cold season","value":"%.1f" % climate,"ratio":climate/top,"color":Tokens.TEAL,"tip":"Extra need from climate"},
		{"name":"Pregnancy & lactation","value":"%.1f" % pregnancy,"ratio":pregnancy/top,"color":Tokens.TEAL,"tip":"Extra need from pregnancy and infant care"},
	]
	return [
		{"type":"bars","heading":"DAILY DEMAND","note":"rations","items":items},
		{"type":"text","heading":"MISSIONS & CONVOYS","text":terrain._provisions_commitment_summary()},
	]

func signature()->Array:
	var result:Array=SettlementModel.with_city_resources(GameState.selected_player_settlement_id,_local_signature)
	result.append_array([GameState.selected_player_settlement_id,GameState.elapsed_days,GameState.city_trade_shipments.size(),GameState.city_trade_history.size(),GovernmentPeopleSystem.revision])
	return result

func _local_signature()->Array:
	var metrics:Dictionary=GameState.simulation_metrics
	return [snappedf(float(metrics.get("food_days",0.0)),0.1),snappedf(float(metrics.get("food_net",0.0)),0.1),snappedf(ResourceSystem.stored_bulk(),0.1),snappedf(float(GameState.water_metrics.get("days",0.0)),0.1)]

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

func _wealth_tab()->Dictionary:
	var blocks:Array=[Charts.stocks(GameState.selected_player_settlement_id)]
	if GameState.economy_stage in ["currency","weighed_metal"]: blocks.append(Charts.finance(GameState.selected_player_settlement_id))
	else: blocks.append({"type":"text","heading":"WEALTH BEFORE MONEY","text":"This economy uses direct allocation and reciprocity. Material stores above belong to the selected city. No issued-currency treasury or household-currency trend exists yet."})
	blocks.append({"type":"text","heading":"WHAT THESE ACCOUNTS COVER","text":"Goods and reserves are physical wealth. Currency balances are separate city accounts and must not be added to material units. The current aggregate records do not provide a historical monetary valuation of buildings, land, private enterprises or household possessions."})
	return {"kpis":[],"brief":{},"blocks":blocks}

func open_expanded_tab(sub:int)->bool:
	if sub!=1:return false
	preload("res://scripts/hud/knowledge_atlas.gd").open(terrain,hud,"materials")
	return true

func _food_overview()->Array:
	return [{"type":"text","heading":"READING THE RESERVES","text":"Days of food and water describe what is stored against current need. They are not a countdown while production continues. Local leaders handle routine provisioning."},
		{"type":"actions","heading":"UNDERSTAND THE SUPPLY","items":[
			focused_action("RESERVE OUTLOOK","History and seasonal forecast",_economy_report.bind("outlook")),
			focused_action("TODAY’S FOOD","Produced, eaten, spoiled and sent away",_economy_report.bind("flow")),
			focused_action("FOOD SOURCES","Where it comes from and what is stored",_economy_report.bind("sources")),
			focused_action("CITY DELIVERIES","Routes, shipments and requirements",_economy_report.bind("trade"))]},
		{"type":"actions","heading":"GIVE DIRECTION","items":[
			{"label":"LOCAL PRIORITY","sub":"Review the leader’s direction","on_press":jump("settlement",0)},
			{"label":"DISCUSS FOOD POLICY","sub":"Give an instruction to your council","on_press":jump("civ",2)}]}]

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
