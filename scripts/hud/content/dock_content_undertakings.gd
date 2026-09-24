extends "res://scripts/hud/content/dock_content_base.gd"
const U=preload("res://scripts/undertaking_system.gd")
const C=preload("res://scripts/undertaking_catalog.gd")
const Rewards=preload("res://scripts/undertaking_rewards.gd")
const GW=preload("res://scripts/great_works.gd")
const Art=preload("res://scripts/hud/undertaking_art.gd")
func tab(_sub:int)->Dictionary:
	var id:=GameState.selected_player_settlement_id
	return SettlementModel.with_city_resources(id,func()->Dictionary:return SettlementModel.with_local_population(func()->Dictionary:return _local(id)))
func _refresh()->void:hud.request_immediate_dock_refresh()
func _local(id:String)->Dictionary:
	var city:=SettlementModel.settlement_record(id)
	var blocks:Array=[{"type":"text","heading":"GREAT WORKS · "+String(city.get("name","Found a settlement first")),"text":"Each Great Work exists once in the world. Rivals may race you for it; the first to finish claims it. Materials, building labor, your architect's vision, hard choices and continued care determine what survives."}]
	for r:Dictionary in city.get("undertakings",[]):
		var d:=C.get_definition(String(r.id))
		var texture:=Art.texture(String(r.id))
		if Art.Early.active() and texture!=null:blocks.append({"type":"image","texture":texture,"height":180,"heading":"DESIGN STUDY · "+String(r.status).to_upper(),"tip":"Illustration of the intended design. Actual progress, condition and legacy are shown below."})
		var building:bool=r.status in ["building","stalled"]
		var architect:Dictionary=r.get("architect",{})
		var header:=String(r.status).capitalize()+" · "+(U.stage_of(r).capitalize()+" · " if building else "")+String(r.reason)
		if not architect.is_empty():header+="\nMaster builder: %s — %s style, vision %d%%, ego %d%%." % [String(architect.name),String(architect.get("style","")),roundi(float(architect.vision)*100),roundi(float(architect.ego)*100)]
		if not String(d.get("lore","")).is_empty():header+="\n"+String(d.lore)
		blocks.append({"type":"text","heading":U.display_name(r).to_upper()+" · "+String(C.ERA_TITLES.get(d.get("era",""),"")).to_upper(),"text":header})
		var total:=U.total_work(r)
		var quality:float=float(r.quality)/maxf(.00001,float(r.progress)) if building else float(r.condition)
		blocks.append({"type":"bars","items":[{"name":"Construction","ratio":U.fraction(r),"value":"%.1f%%" % (100*U.fraction(r)),"color":Tokens.INK},{"name":"Workmanship" if building else "Condition","ratio":quality,"value":"%.0f%%" % (quality*100) if float(r.progress)>0 else "Unproven","color":Tokens.INK}]})
		var work:=float(r.get("last_work",0))
		var pace:="Paused" if r.status=="stalled" else ("Awaiting crew" if work<=0 else "%.1f years" % (maxf(0,total-float(r.progress))/work/365.0))
		blocks.append({"type":"tiles","columns":3,"items":[{"label":"AT PRESENT PACE" if building else "MAINTAINED OPERATION","value":pace if building else "%.1f years" % (float(r.operating_days)/365.0),"note":"Estimate changes with labor and supplies" if building else "20 years needed for victory"},{"label":"HUMAN COST","value":"%d days" % int(r.strain),"note":"Work pressed through shortages or levies"},{"label":"REPUTATION REACH","value":"%d societies" % r.get("heard_by",{}).size(),"note":String(r.legacy)}]})
		if building:
			var race:=U.rivalry_race("player",String(r.id),U.fraction(r))
			if not race.is_empty() and not bool(race.get("claimed",false)):blocks.append({"type":"text","heading":"A RACE","text":"A report from day %d says %s also build this work, perhaps %d%% complete. Whoever finishes first claims it; the other site will stand unfinished." % [int(race.day),U.owner_name(String(race.owner)),roundi(float(race.rival_mid)*100)]})
		var decision:Dictionary=r.get("decision",{})
		if not decision.is_empty():
			var options:Array=[]
			for option:Dictionary in U.decision_options(GameState,r):
				var option_id:=String(option.id)
				options.append({"label":String(option.label),"sub":String(option.sub) if bool(option.enabled) else String(option.reason),"disabled":not bool(option.enabled),"on_press":func():terrain._report_military_action(U.decide(id,String(r.id),option_id));_refresh()})
			blocks.append({"type":"actions","heading":"DECISION · "+String(decision.get("stage","")).to_upper(),"items":options})
			blocks.append({"type":"text","text":String(decision.get("prompt",""))+"\nIf you give no answer, the council decides after %d days." % U.PLAYER_DECISION_DAYS})
		var ceremony:Dictionary=r.get("ceremony",{})
		if String(ceremony.get("status",""))=="pending":
			var guests:Array[String]=[]
			for attendee:Dictionary in ceremony.get("attendees",[]):
				var gift:Dictionary=attendee.get("gift",{})
				guests.append(String(attendee.name)+(" (bringing %d %s)" % [int(gift.amount),String(gift.resource).to_lower()] if not gift.is_empty() else ""))
			var suggestions:Array=ceremony.get("name_suggestions",[])
			blocks.append({"type":"order","heading":"DEDICATE AND NAME THIS GREAT WORK","placeholder":String(suggestions[0]) if not suggestions.is_empty() else String(d.title),"value":"","max_length":60,"button_label":"DEDICATE","helper":("Envoys present: "+", ".join(guests)+". " if not guests.is_empty() else "No foreign envoys attend. ")+"Suggested: "+", ".join(suggestions),"on_submit":func(field:LineEdit):terrain._report_military_action(U.dedicate(id,String(r.id),field.text if not field.text.strip_edges().is_empty() else (String(suggestions[0]) if not suggestions.is_empty() else String(d.title))));_refresh()})
		elif float(r.progress)+.00001>=total or r.status=="rival":
			blocks.append({"type":"order","heading":"NAME THIS LANDMARK","placeholder":String(d.title),"value":String(r.get("custom_name","")),"max_length":60,"button_label":"SAVE NAME","helper":"Its name stays with its history, including any later ruins.","on_submit":func(field:LineEdit):terrain._report_military_action(U.rename(id,String(r.id),field.text));_refresh()})
		if r.status=="functioning":
			var text:=Rewards.description(String(r.id),float(r.condition))+"\nAlso +%.1f%% local %s effectiveness. Maintained %.1f years · Accounts carried to %d societies." % [float(d.bonus)*float(r.condition)*100,String(d.role).to_lower(),float(r.operating_days)/365.0,r.get("heard_by",{}).size()]
			if bool(r.get("lesser",false)):text="A lesser monument: it draws visitors but claims no Great Work and gives no special reward."
			var decree:Dictionary=d.get("decree",{})
			if not decree.is_empty() and not bool(r.get("lesser",false)):text+="\nDecree available: %s — %s" % [String(decree.label),String(decree.text)]
			if not r.get("enshrined",[]).is_empty():text+="\nEnshrined objects: %d of %d places." % [r.enshrined.size(),int(d.get("shrine_slots",0))]
			blocks.append({"type":"text","heading":"CURRENT CONTRIBUTION","text":text})
		if r.status=="rival":
			blocks.append({"type":"actions","heading":"AN UNFINISHED RIVAL","items":[{"label":"REPURPOSE","sub":"Maintain it as a lesser monument that draws visitors","on_press":func():terrain._report_military_action(U.repurpose(id,String(r.id)));_refresh()},{"label":"QUARRY IT","sub":"Recover 40% of the materials built into it","on_press":func():terrain._report_military_action(U.quarry(id,String(r.id)));_refresh()}]})
		if building:
			blocks.append({"type":"actions","items":[{"label":"PROTECT DAILY NEEDS","sub":"20% of builders; pause during shortages","on_press":func():U.direct(id,String(r.id),"careful");_refresh()},{"label":"PRESS AHEAD","sub":"50% of builders; continue through hardship","on_press":func():U.direct(id,String(r.id),"press");_refresh()},{"label":"WITHDRAW SUPPORT","sub":"Leave the unfinished site in place" if r.get("layers",[]).is_empty() else "Abandon the rebuilding; the older work reopens","on_press":func():U.direct(id,String(r.id),"abandon");_refresh()}]})
		var events:Array=[]
		for event:Dictionary in r.get("events",[]):events.append({"name":"Year %d · Day %d" % [int(event.day)/365+1,int(event.day)%365+1],"detail":String(event.text)})
		for layer:Dictionary in r.get("layers",[]):events.append({"name":"Earlier layer","detail":"%s, Years %d–%d" % [String(layer.get("name",layer.get("title",""))),int(layer.get("from",0))/365+1,int(layer.get("to",0))/365+1]})
		if not events.is_empty():blocks.append({"type":"rows","heading":"THIS LANDMARK'S HISTORY","items":events})
	var actions:Array=[]
	for d:Dictionary in U.possibilities(city):
		var bill:Array[String]=[]
		for material:String in d.cost:bill.append("%d %s" % [int(d.cost[material]),material])
		var race:=U.rivalry_race("player",String(d.id),0.0)
		var racing:=0 if race.is_empty() or bool(race.get("claimed",false)) else 1
		actions.append({"label":String(d.title),"texture":Art.texture(String(d.id)),"tip":String(d.get("lore","")),"sub":"%s%s · %s · %.0f crew-days%s\n%s" % ["REBUILD IN PLACE · " if not String(d.upgrade_from).is_empty() else "",String(C.ERA_TITLES.get(d.era,"")).to_upper(),", ".join(bill),float(d.work)," · rivals building" if racing>0 else "",Rewards.description(String(d.id))],"on_press":func():terrain._report_military_action(U.start(id,String(d.id),func(p:Vector2)->float:return terrain._close_surface_height_at(p.x,p.y),terrain._settlement_stage_land_at));_refresh()})
	if not actions.is_empty():blocks.append({"type":"actions","heading":"GREAT WORKS POSSIBLE HERE","items":actions})
	else:blocks.append({"type":"text","text":"No new Great Work is available here yet. Discoveries, population, environment and what rivals have already claimed determine what can be proposed."})
	var warnings:=GW.forecast("player")
	if not warnings.is_empty():
		var rows:Array=[]
		for warning:Dictionary in warnings:rows.append({"name":"In %d days" % int(warning.in_days),"detail":String(warning.text)})
		blocks.append({"type":"rows","heading":"THE WATCHING SKY FORESEES","items":rows})
	blocks.append(Rewards.victory_block(GameState))
	return {"blocks":blocks}
