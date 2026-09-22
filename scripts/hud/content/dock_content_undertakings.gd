extends "res://scripts/hud/content/dock_content_base.gd"
const U=preload("res://scripts/undertaking_system.gd")
const C=preload("res://scripts/undertaking_catalog.gd")
const Rewards=preload("res://scripts/undertaking_rewards.gd")
func tab(_sub:int)->Dictionary:
	var id:=GameState.selected_player_settlement_id
	return SettlementModel.with_city_resources(id,func()->Dictionary:return SettlementModel.with_local_population(func()->Dictionary:return _local(id)))
func _local(id:String)->Dictionary:
	var city:=SettlementModel.settlement_record(id)
	var blocks:Array=[{"type":"text","heading":"GREAT UNDERTAKINGS · "+String(city.get("name","Found a settlement first")),"text":"Authorize an ambition. Your people must make it work. Materials, building labor, hardship and continued care determine what survives."}]
	blocks.append(Rewards.victory_block(GameState))
	for r:Dictionary in city.get("undertakings",[]):
		var d:=C.get_definition(String(r.id))
		blocks.append({"type":"rows","heading":U.display_name(r).to_upper(),"items":[{"name":"%.0f%% · %s" % [100*float(r.progress)/float(d.work),String(r.status).capitalize()],"detail":String(r.reason)+"\n"+String(r.legacy),"sub":"Condition %.0f%% · %d days pressed through shortages" % [float(r.condition)*100,int(r.strain)]}]})
		if float(r.progress)+.00001>=float(d.work):
			blocks.append({"type":"order","heading":"NAME THIS LANDMARK","placeholder":String(d.title),"value":String(r.get("custom_name","")),"max_length":60,"button_label":"SAVE NAME","helper":"Its name stays with its history, including any later ruins.","on_submit":func(field:LineEdit):terrain._report_military_action(U.rename(id,String(r.id),field.text));hud.request_immediate_dock_refresh()})
		if r.status=="functioning":
			blocks.append({"type":"text","heading":"CURRENT CONTRIBUTION","text":Rewards.description(String(r.id),float(r.condition))+"\nAlso +%.1f%% local %s effectiveness. Maintained %.1f years · Accounts carried to %d societies." % [float(d.bonus)*float(r.condition)*100,String(d.role).to_lower(),float(r.operating_days)/365.0,r.get("heard_by",{}).size()]})
		if r.status in ["building","stalled"]:
			blocks.append({"type":"actions","items":[{"label":"PROTECT DAILY NEEDS","sub":"20% of builders; pause during shortages","on_press":func():U.direct(id,String(r.id),"careful");hud.request_immediate_dock_refresh()},{"label":"PRESS AHEAD","sub":"50% of builders; continue through hardship","on_press":func():U.direct(id,String(r.id),"press");hud.request_immediate_dock_refresh()},{"label":"WITHDRAW SUPPORT","sub":"Leave the unfinished site in place","on_press":func():U.direct(id,String(r.id),"abandon");hud.request_immediate_dock_refresh()}]})
	var actions:Array=[]
	for d:Dictionary in U.possibilities(city):
		var bill:Array[String]=[]
		for material:String in d.cost:bill.append("%d %s" % [int(d.cost[material]),material])
		actions.append({"label":String(d.title),"sub":"%s · %.0f crew-days\n%s" % [", ".join(bill),float(d.work),Rewards.description(String(d.id))],"on_press":func():terrain._report_military_action(U.start(id,String(d.id)));hud.request_immediate_dock_refresh()})
	if not actions.is_empty():blocks.append({"type":"actions","heading":"POSSIBILITIES HERE","items":actions})
	else:blocks.append({"type":"text","text":"No new undertaking is available here yet. Local population, discoveries, environment and this world's opportunities determine what can be proposed during the first 300 years."})
	return {"blocks":blocks}
