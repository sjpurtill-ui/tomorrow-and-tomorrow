extends "res://scripts/hud/content/dock_content_base.gd"
## Great Works in the dock: this settlement's works at a glance, with doors
## into the full screen ("Our Great Works"), the court's pitch (Audience Hall)
## and any waiting dedication (the ceremony). Decisions are heard from the
## master builder in person; the dock never duplicates those forms.
const U=preload("res://scripts/undertaking_system.gd")
const Works=preload("res://scripts/great_works_audience.gd")
const STATUS_WORDS:={"building":"Rising","stalled":"Idle","functioning":"Standing","ruined":"A ruin","abandoned":"Abandoned"}

func tab(_sub:int)->Dictionary:
	var id:=GameState.selected_player_settlement_id
	return SettlementModel.with_city_resources(id,func()->Dictionary:return SettlementModel.with_local_population(func()->Dictionary:return _local(id)))
func _refresh()->void:hud.request_immediate_dock_refresh()

func _director()->Node:
	return terrain.find_child("AudienceDirector",true,false) if is_instance_valid(terrain) else null

func _open_works(focus:String="")->void:
	var director:=_director()
	if director!=null and director.has_method("open_works"):director.call("open_works",focus)

func _conceive()->void:
	var director:=_director()
	if director!=null and director.has_method("open_conception"):director.call("open_conception")

func _hear(work_id:String,city_id:String)->void:
	var made:=Works.decision_audience(work_id,city_id,true)
	var audience_id:=String(made.get("id",""))
	if audience_id.is_empty():
		for audience:Dictionary in Works._waiting_of("great_work"):
			if String((audience.get("great_work",{}) as Dictionary).get("work_id",""))==work_id:audience_id=String(audience.id)
	var director:=_director()
	if not audience_id.is_empty() and director!=null and director.has_method("open_audience"):director.call("open_audience",audience_id)

func _dedicate(work_id:String)->void:
	var director:=_director()
	if director!=null and director.has_method("open_ceremony"):director.call("open_ceremony",work_id)

func _status(item:Dictionary)->String:
	var status:=String(item.get("status",""))
	var outcome:=String(item.get("outcome",""))
	if status=="ruined" and outcome=="collapse":return "A folly, fallen"
	if status in ["building","stalled"]:return _building_words(item)
	if status=="functioning" and outcome in ["triumph","flawed"]:return "Standing · %s" % ("a triumph" if outcome=="triumph" else "flawed")
	return String(STATUS_WORDS.get(status,status.capitalize()))

func _local(id:String)->Dictionary:
	var city:=SettlementModel.settlement_record(id)
	var blocks:Array=[{"type":"text","heading":"GREAT WORKS · "+String(city.get("name","Found a settlement first")),"text":"A great work is our own idea: a wonder conceived from who we are and what we have lived through. It may rise beyond its drawings, stand flawed, or fall as a folly. Materials, hands, knowledge, the people's mood and your choices decide."}]
	blocks.append({"type":"actions","items":[
		{"label":"CONCEIVE A GREAT WORK","sub":"Call the court and hear what they dream of","on_press":_conceive},
		{"label":"OUR GREAT WORKS","sub":"Every work we have raised or tried to, and the works of other peoples","on_press":func()->void:_open_works()}]})
	var ceremonies:={}
	for entry in Works.api_list("pending_ceremonies",["player"]):
		if entry is Dictionary:ceremonies[String(entry.get("work_id",""))]=true
	for item in Works.api_list("works",["player"]):
		if not item is Dictionary or String(item.get("city_id",""))!=id:continue
		var work_id:=String(item.get("work_id",""))
		var text:=_status(item)
		var lore:=String(item.get("ruin_lore","")) if String(item.get("status",""))=="ruined" else String(item.get("lore",""))
		if not lore.is_empty():text+="\n"+lore
		if not String(item.get("architect","")).is_empty():text+="\nMaster builder: %s." % String(item.architect)
		if String(item.get("status","")) in ["building","stalled"]:
			var assessment:Dictionary=Works.site_feasibility(id,work_id)
			if not assessment.is_empty():text+="\nThe court reckons it %s." % Works.odds_words(float(assessment.get("score",.5)))
		blocks.append({"type":"text","heading":String(item.get("name","A great work")).to_upper(),"text":text})
		if String(item.get("status","")) in ["building","stalled"]:
			blocks.append({"type":"bars","items":[{"name":"Raised","ratio":float(item.get("progress",0)),"value":"%d%%" % roundi(float(item.get("progress",0))*100),"color":Tokens.INK}]})
		var items:Array=[]
		var site:=Works.api_dict("site",[id,work_id])
		var impact:=_impact(item,site)
		if not impact.is_empty():blocks.append({"type":"impact_lines","heading":"What %s does" % String(item.get("name","it")),"lines":impact,"columns":1})
		if site.get("decision") is Dictionary and not (site.decision as Dictionary).is_empty():
			items.append({"label":"HEAR THE MASTER BUILDER","sub":String((site.decision as Dictionary).get("prompt","A decision awaits")),"on_press":func()->void:_hear(work_id,id)})
		if ceremonies.has(work_id):
			items.append({"label":"HOLD THE DEDICATION","sub":"Envoys wait; the work stands ready to be named","on_press":func()->void:_dedicate(work_id)})
		if String(item.get("status","")) in ["building","stalled"]:
			items.append({"label":"PROTECT DAILY NEEDS","sub":"Fewer builders; pause during shortages","on_press":func()->void:U.direct(id,work_id,"careful");_refresh()})
			items.append({"label":"PRESS AHEAD","sub":"Half the builders, even through hardship","on_press":func()->void:U.direct(id,work_id,"press");_refresh()})
			items.append({"label":"WITHDRAW SUPPORT","sub":"Lay down the tools; the unfinished site remains","on_press":func()->void:U.direct(id,work_id,"abandon");_refresh()})
		items.append({"label":"INSPECT IN 3D","sub":"Rotate the model, see its rising courses, and watch time pass","on_press":func()->void:_open_works("player/%s/%s" % [id,work_id])})
		blocks.append({"type":"actions","items":items})
	var warnings:=Works.api_list("forecast",["player"])
	if not warnings.is_empty():
		var rows:Array=[]
		for warning in warnings:
			if warning is Dictionary:rows.append({"name":"In %d days" % int(warning.get("in_days",0)),"detail":String(warning.get("text",""))})
		blocks.append({"type":"rows","heading":"THE WATCHING SKY FORESEES","items":rows})
	return {"blocks":blocks}

## What a great work does, from the engine's own records: while it rises,
## the builders it takes and its odds on completion (wonder_concept.gd odds)
## with what each outcome costs; once it stands, what it gives (its rewards
## and effect, undertaking_rewards.gd and undertaking_effects.gd), its
## repair and the upkeep that keeps it from ruin (undertaking_system.gd).
func _impact(item:Dictionary,site:Dictionary)->Array:
	var lines:Array=[]
	var status:=String(item.get("status",""))
	if status in ["building","stalled"]:
		var careful:=String(site.get("policy","careful"))!="press"
		var share:=20 if careful else 50
		lines.append({"label":"Builders taken","value":"%d%%" % share,"words":"%s: %d of every 100 builders work on it, so homes and other works go slower. Food workers are never taken." % ["Protecting daily needs" if careful else "Pressing ahead",share],"tone":"bad"})
		var assessment:Dictionary=site.get("assessment",{}) if site.get("assessment") is Dictionary else {}
		if assessment.has("score"):
			var odds:Dictionary=preload("res://scripts/wonder_concept.gd").odds(float(assessment.score),String(item.get("ambition","grand")))
			if assessment.get("odds") is Dictionary and not (assessment.odds as Dictionary).is_empty():odds=assessment.odds
			lines.append({"label":"When it is finished","value":"%d%% falls" % roundi(float(odds.get("collapse",0.0))*100.0),
				"words":"The engine's odds today: a triumph %d%%, it stands %d%%, it stands flawed %d%%, it falls %d%%. A fall kills some of its builders and costs cohesion and legitimacy; a triumph raises both." % [roundi(float(odds.get("triumph",0.0))*100.0),roundi(float(odds.get("success",0.0))*100.0),roundi(float(odds.get("flawed",0.0))*100.0),roundi(float(odds.get("collapse",0.0))*100.0)],"tone":"bad" if float(odds.get("collapse",0.0))>=0.2 else "plain"})
			# The builders' share of the odds and the payoff, stated (built_fabric.gd).
			if String(assessment.get("stated",""))!="":
				lines.append({"label":"The builders","value":"x%.2f if it stands" % float(assessment.get("payoff",1.0)),"words":String(assessment.stated),"tone":"plain"})
		lines.append({"label":"Materials","value":"as it rises","words":"Stone, timber and the rest are drawn from the stores as the work is done; when they run out it stalls, and after five idle years it is abandoned.","tone":"plain"})
	elif status=="functioning":
		for key in ["reward_text","effect_text"]:
			var said:=String(site.get(key,"")).strip_edges()
			if said!="":lines.append({"label":"What it gives" if key=="reward_text" else "Its own power","value":"%d%%" % roundi(float(item.get("condition",1.0))*100.0),"words":said,"tone":"good"})
		lines.append({"label":"Upkeep","value":"1% a year","words":"Each year it takes a hundredth of what it cost in materials, fed people and at least one builder. Without them it wears down; at 15% it is a ruin, about four years of neglect. Its gifts act at its repair.","tone":"plain"})
	elif status=="ruined":
		lines.append({"label":"A ruin","value":"nothing","words":"It gives nothing now. The site can be quarried for part of what was put into it.","tone":"bad"})
	return lines


## A work under way: rising (how far, how long to go at today's pace, or that
## the builders await your word) or idle (and why), in the words the map card uses.
func _building_words(item:Dictionary)->String:
	var Visual=preload("res://scripts/undertaking_map_visual.gd")
	var idle:=String(item.get("idle",""))
	var stage:=String(Works.STAGE_WORDS.get(String(item.get("stage","")),""))
	var line:="Idle" if idle!="" else "Rising"
	if stage!="":line+=" · "+stage
	line+=" · "+Visual.percent_words(float(item.get("progress",0)))
	var asks:=String(item.get("asks",""))
	var why:=idle if idle!="" else (asks if asks!="" else Visual.time_left_words(int(item.get("days_left",-1))))
	return line+(" · "+why if why!="" else "")
