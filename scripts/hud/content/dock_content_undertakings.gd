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
	for r:Dictionary in city.get("undertakings",[]):
		var d:=C.get_definition(String(r.id))
		blocks.append({"type":"text","heading":U.display_name(r).to_upper(),"text":String(r.status).capitalize()+" · "+String(r.reason)})
		var building:bool=r.status in ["building","stalled"]
		var quality:float=float(r.quality)/maxf(.00001,float(r.progress)) if building else float(r.condition)
		blocks.append({"type":"bars","items":[{"name":"Construction","ratio":float(r.progress)/float(d.work),"value":"%.1f%%" % (100*float(r.progress)/float(d.work)),"color":Tokens.INK},{"name":"Workmanship" if building else "Condition","ratio":quality,"value":"%.0f%%" % (quality*100) if float(r.progress)>0 else "Unproven","color":Tokens.INK}]})
		var work:=float(r.get("last_work",0))
		var pace:="Paused" if r.status=="stalled" else ("Awaiting crew" if work<=0 else "%.1f years" % (maxf(0,float(d.work)-float(r.progress))/work/365.0))
		blocks.append({"type":"tiles","columns":3,"items":[{"label":"AT PRESENT PACE" if r.status in ["building","stalled"] else "MAINTAINED OPERATION","value":pace if r.status in ["building","stalled"] else "%.1f years" % (float(r.operating_days)/365.0),"note":"Estimate changes with labor and supplies" if r.status in ["building","stalled"] else "20 years needed for victory"},{"label":"HUMAN COST","value":"%d days" % int(r.strain),"note":"Work pressed through shortages"},{"label":"REPUTATION REACH","value":"%d societies" % r.get("heard_by",{}).size(),"note":String(r.legacy)}]})
		if float(r.progress)+.00001>=float(d.work):
			blocks.append({"type":"order","heading":"NAME THIS LANDMARK","placeholder":String(d.title),"value":String(r.get("custom_name","")),"max_length":60,"button_label":"SAVE NAME","helper":"Its name stays with its history, including any later ruins.","on_submit":func(field:LineEdit):terrain._report_military_action(U.rename(id,String(r.id),field.text));hud.request_immediate_dock_refresh()})
		if r.status=="functioning":
			blocks.append({"type":"text","heading":"CURRENT CONTRIBUTION","text":Rewards.description(String(r.id),float(r.condition))+"\nAlso +%.1f%% local %s effectiveness. Maintained %.1f years · Accounts carried to %d societies." % [float(d.bonus)*float(r.condition)*100,String(d.role).to_lower(),float(r.operating_days)/365.0,r.get("heard_by",{}).size()]})
		if r.status in ["building","stalled"]:
			blocks.append({"type":"actions","items":[{"label":"PROTECT DAILY NEEDS","sub":"20% of builders; pause during shortages","on_press":func():U.direct(id,String(r.id),"careful");hud.request_immediate_dock_refresh()},{"label":"PRESS AHEAD","sub":"50% of builders; continue through hardship","on_press":func():U.direct(id,String(r.id),"press");hud.request_immediate_dock_refresh()},{"label":"WITHDRAW SUPPORT","sub":"Leave the unfinished site in place","on_press":func():U.direct(id,String(r.id),"abandon");hud.request_immediate_dock_refresh()}]})
		var events:Array=[]
		for event:Dictionary in r.get("events",[]):events.append({"name":"Year %d · Day %d" % [int(event.day)/365+1,int(event.day)%365+1],"detail":String(event.text)})
		if not events.is_empty():blocks.append({"type":"rows","heading":"THIS LANDMARK'S HISTORY","items":events})
	var actions:Array=[]
	for d:Dictionary in U.possibilities(city):
		var bill:Array[String]=[]
		for material:String in d.cost:bill.append("%d %s" % [int(d.cost[material]),material])
		actions.append({"label":String(d.title),"sub":"%s · %.0f crew-days\n%s" % [", ".join(bill),float(d.work),Rewards.description(String(d.id))],"on_press":func():terrain._report_military_action(U.start(id,String(d.id),func(p:Vector2)->float:return terrain._close_surface_height_at(p.x,p.y),terrain._settlement_stage_land_at));hud.request_immediate_dock_refresh()})
	if not actions.is_empty():blocks.append({"type":"actions","heading":"POSSIBILITIES HERE","items":actions})
	else:blocks.append({"type":"text","text":"No new undertaking is available here yet. Local population, discoveries, environment and this world's opportunities determine what can be proposed during the first 300 years."})
	blocks.append(Rewards.victory_block(GameState))
	return {"blocks":blocks}
