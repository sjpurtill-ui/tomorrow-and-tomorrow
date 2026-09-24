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
	if status in ["building","stalled"]:return "%s · %s · %d%%" % [String(STATUS_WORDS.get(status,"Rising")),String(Works.STAGE_WORDS.get(String(item.get("stage","")),"")),roundi(float(item.get("progress",0))*100)]
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
		if site.get("decision") is Dictionary and not (site.decision as Dictionary).is_empty():
			items.append({"label":"HEAR THE MASTER BUILDER","sub":String((site.decision as Dictionary).get("prompt","A decision awaits")),"on_press":func()->void:_hear(work_id,id)})
		if ceremonies.has(work_id):
			items.append({"label":"HOLD THE DEDICATION","sub":"Envoys wait; the work stands ready to be named","on_press":func()->void:_dedicate(work_id)})
		if String(item.get("status","")) in ["building","stalled"]:
			items.append({"label":"PROTECT DAILY NEEDS","sub":"Fewer builders; pause during shortages","on_press":func()->void:U.direct(id,work_id,"careful");_refresh()})
			items.append({"label":"PRESS AHEAD","sub":"Half the builders, even through hardship","on_press":func()->void:U.direct(id,work_id,"press");_refresh()})
			items.append({"label":"WITHDRAW SUPPORT","sub":"Lay down the tools; the unfinished site remains","on_press":func()->void:U.direct(id,work_id,"abandon");_refresh()})
		items.append({"label":"OPEN IN OUR GREAT WORKS","sub":"History, effects, enshrined objects, decree","on_press":func()->void:_open_works("player/%s/%s" % [id,work_id])})
		blocks.append({"type":"actions","items":items})
	var warnings:=Works.api_list("forecast",["player"])
	if not warnings.is_empty():
		var rows:Array=[]
		for warning in warnings:
			if warning is Dictionary:rows.append({"name":"In %d days" % int(warning.get("in_days",0)),"detail":String(warning.get("text",""))})
		blocks.append({"type":"rows","heading":"THE WATCHING SKY FORESEES","items":rows})
	return {"blocks":blocks}
