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

## The town's great works as board rows (hud/buildings_board.gd): each work
## with its mark, state, bar and time left, what it does in a few figures
## (its odds and builders while it rises, its gifts and repair once it
## stands), the master builder's question, the dedication and the builders'
## orders as verbs on the row; then the sky's warnings and the works of other
## peoples we have heard of. No screen behind the page but the 3D model.
func _local(id:String)->Dictionary:
	var city:=SettlementModel.settlement_record(id)
	var cards:Array=[]
	var ceremonies:={}
	for entry in Works.api_list("pending_ceremonies",["player"]):
		if entry is Dictionary:ceremonies[String(entry.get("work_id",""))]=true
	var count:=0
	for item in Works.api_list("works",["player"]):
		if not item is Dictionary or String(item.get("city_id",""))!=id:continue
		count+=1
		var work_id:=String(item.get("work_id",""))
		var status:=String(item.get("status",""))
		var rising:=status in ["building","stalled"]
		var site:=Works.api_dict("site",[id,work_id])
		var shape:=String(item.get("visual",item.get("form","")))
		var row:={"section":"works","key":"work_"+work_id,"texture":preload("res://scripts/resource_icons.gd").great_work_texture(shape,"ruined" if status=="ruined" else ("building" if rising else "standing"),48),
			"name":String(item.get("name","A great work")),"sub":_row_words(item),"detail":_work_detail(item,id,work_id)}
		var outcome:=String(item.get("outcome",""))
		match status:
			"building":row["tag"]={"text":"Rising","tone":"good"}
			"stalled":row["tag"]={"text":"Idle","tone":"bad","tip":String(item.get("idle",""))}
			"functioning":row["tag"]={"text":"A triumph" if outcome=="triumph" else ("Flawed" if outcome=="flawed" else "Standing"),"tone":"good" if outcome!="flawed" else "warn"}
			"ruined":row["tag"]={"text":"Fallen" if outcome=="collapse" else "Ruin","tone":"bad"}
			_:row["tag"]={"text":String(STATUS_WORDS.get(status,status.capitalize())),"tone":"note"}
		if rising:
			row["bar"]={"ratio":float(item.get("progress",0)),"color":Tokens.GOLD if status=="building" else Tokens.RED}
			row["value"]="%d%%" % roundi(float(item.get("progress",0))*100.0)
		elif status=="functioning":
			row["bar"]={"ratio":float(item.get("condition",1.0)),"color":Tokens.GREEN,"tip":"Its repair: its gifts act at this."}
			row["value"]="%d%%" % roundi(float(item.get("condition",1.0))*100.0)
		var effects:Array=[]
		for line:Dictionary in _impact(item,site):
			# The same for every work: told in the row's tooltip, not on it.
			if String(line.label) in ["Materials","A ruin","Upkeep"]:
				row.detail=String(row.detail)+"
%s: %s" % [String(line.label),String(line.get("words",""))]
				continue
			# Standing, its repair is the row's figure: each gift says its first clause.
			var value:=String(line.value)
			if status=="functioning" and String(line.label) in ["What it gives","Its own power"]:value=_clause(String(line.get("words","")))
			effects.append({"label":String(line.label),"value":value,"tone":String(line.get("tone","plain")),"tip":String(line.get("words",""))})
		if not effects.is_empty():row["effects"]=effects
		var actions:Array=[]
		if site.get("decision") is Dictionary and not (site.decision as Dictionary).is_empty():
			actions.append({"label":"Hear","primary":true,"tip":String((site.decision as Dictionary).get("prompt","The master builder asks for your word.")),"on_press":func()->void:_hear(work_id,id)})
		if ceremonies.has(work_id):
			actions.append({"label":"Dedicate","primary":true,"tip":"Envoys wait; the work stands ready to be named.","on_press":func()->void:_dedicate(work_id)})
		actions.append({"label":"View","tip":"Rotate the model, see its rising courses, and watch time pass.","on_press":func()->void:_open_works("player/%s/%s" % [id,work_id])})
		row["actions"]=actions
		if rising:
			var policy:=String(site.get("policy","careful"))
			row["choice"]={"selected":policy,"options":[
				{"id":"careful","label":"Spare daily needs","tip":"A fifth of the builders; it pauses in shortages.","on_press":func()->void:U.direct(id,work_id,"careful");_refresh()},
				{"id":"press","label":"Press ahead","tip":"Half the builders, even through hardship.","on_press":func()->void:U.direct(id,work_id,"press");_refresh()},
				{"id":"abandon","label":"Withdraw","tip":"Lay down the tools; the unfinished site remains.","on_press":func()->void:U.direct(id,work_id,"abandon");_refresh()}]}
		cards.append(row)
	cards.append_array(_next_works())
	for warning in Works.api_list("forecast",["player"]):
		if warning is Dictionary:cards.append({"section":"sky","key":"sky_%d" % cards.size(),"icon":"danger","name":"In %d days" % int(warning.get("in_days",0)),"sub":String(warning.get("text","")),"detail":String(warning.get("text",""))})
	for news:Dictionary in preload("res://scripts/great_works.gd").known_foreign_works("player"):
		var low:=float(news.get("progress_low",0.0));var high:=float(news.get("progress_high",low))
		var row:={"section":"abroad","key":"abroad_%d" % cards.size(),"icon":"shrine","name":String(news.get("title",news.get("form","A great work"))).capitalize() if String(news.get("title",""))=="" else String(news.title),
			"sub":"%s · %s" % [String(news.get("civ_name","")),String(news.get("city_name",""))],"detail":String(news.get("text","")),
			"tag":{"text":String(news.get("status","")).capitalize(),"tone":"note","tip":"Heard %s ago." % preload("res://scripts/hud/production_plain.gd").span_text(float(news.get("age_days",0)))}}
		if String(news.get("status",""))=="building":row["bar"]={"ratio":(low+high)*0.5,"color":Tokens.RULE_STRONG,"width":70,"tip":"Somewhere between %d%% and %d%% raised, as last heard." % [roundi(low*100.0),roundi(high*100.0)]}
		cards.append(row)
	var sections:=[
		{"id":"works","heading":"Great works of %s" % String(city.get("name","the town")),"span":true,"note":"none yet" if count==0 else "",
			"actions":[{"label":"Conceive","primary":count==0,"tip":"Call the court and hear what they dream of: a wonder conceived from who we are.","on_press":_conceive}]},
		{"id":"next","heading":"What the people could raise next","span":true},
		{"id":"sky","heading":"The watching sky foresees"},
		{"id":"abroad","heading":"Other peoples' works","note":"as last heard" if cards.any(func(c:Dictionary)->bool:return String(c.section)=="abroad") else ""}]
	return {"blocks":[{"type":"town_works","board":true,"sections":sections,"cards":cards}]}

## The great works the people would put to the court today, as rows: each
## idea's form, the engine's odds that it stands (wonder_concept.gd assess and
## odds), how long it would take, and its bill against the stores as pips. The
## court hears them in full (Conceive).
func _next_works()->Array:
	var Concept:=preload("res://scripts/wonder_concept.gd")
	var rows:Array=[]
	for concept:Dictionary in Concept.conceive("player",{},3):
		var assessed:Dictionary=Concept.assess(concept)
		var ambition:=String(concept.get("ambition","grand"))
		var o:Dictionary=Concept.odds(float(assessed.get("score",0.5)),ambition)
		var stands:=float(o.triumph)+float(o.success)+float(o.flawed)
		var needs:Array=[]
		var cost:Dictionary=assessed.get("costs",concept.get("cost",{}))
		var keys:Array=cost.keys()
		keys.sort_custom(func(x:Variant,y:Variant)->bool:return float(cost[x])>float(cost[y]))
		for resource in keys.slice(0,3):needs.append({"resource":String(resource),"have":float(GameState.resource_stockpiles.get(String(resource),0.0)),"need":float(cost[resource])})
		var days:=float(assessed.get("duration_estimate",0))
		rows.append({"section":"next","key":"idea_"+String(concept.get("token","")),"texture":preload("res://scripts/resource_icons.gd").great_work_texture(String(concept.get("shape","")),"building",48),
			"name":String(concept.get("name","A great work")),"sub":_purpose_words(String(concept.get("title",""))),
			"bar":{"ratio":stands,"color":Tokens.GREEN if stands>=0.75 else (Tokens.AMBER if stands>=0.5 else Tokens.RED),"tip":"The engine's odds today: a triumph %d%%, it stands %d%%, flawed %d%%, it falls %d%%." % [roundi(float(o.triumph)*100.0),roundi(float(o.success)*100.0),roundi(float(o.flawed)*100.0),roundi(float(o.collapse)*100.0)]},
			"value":"%d%% stands" % roundi(stands*100.0),"value_width":84,"tag":{"text":ambition.capitalize(),"tone":"note"},
			"effects":[{"label":"Takes","value":preload("res://scripts/hud/production_plain.gd").span_text(days) if days>0.0 else "unknown","tone":"plain","tip":"At today's builders."}],
			"needs":needs,"detail":"%s
%s" % [String(concept.get("effect_text","")),String(assessed.get("spoken",""))],
			"actions":[{"label":"Hear it","tip":"The court puts this idea and the others to you; you choose.","on_press":_conceive}]})
	return rows

## A work's few words beside its name: where it stands in the raising and
## how long to go (or why it is idle), or who built it once it stands.
func _row_words(item:Dictionary)->String:
	var status:=String(item.get("status",""))
	if status in ["building","stalled"]:
		var stage:=String(Works.STAGE_WORDS.get(String(item.get("stage","")),""))
		var idle:=String(item.get("idle",""))
		var asks:=String(item.get("asks",""))
		var why:=idle if idle!="" else (asks if asks!="" else preload("res://scripts/undertaking_map_visual.gd").time_left_words(int(item.get("days_left",-1))))
		var parts:PackedStringArray=[]
		for part:String in [stage,why]:
			if part!="":parts.append(part)
		return " · ".join(parts)
	if status=="ruined" and String(item.get("outcome",""))=="collapse":return "a folly, fallen"
	return ("built by %s" % String(item.architect)) if String(item.get("architect",""))!="" else ""

## The first clause of an effect's words, short enough for a chip.
static func _clause(words:String)->String:
	var first:=words.get_slice(";",0).strip_edges()
	if first.contains(" · "):first=first.get_slice(" · ",1)
	# The part before a colon says it; never cut mid-word with dots.
	if first.length()>44 and first.contains(":"):first=first.get_slice(":",0).strip_edges()
	if first.length()>44:
		var kept:PackedStringArray=[]
		for word in first.split(" "):
			if " ".join(kept+PackedStringArray([word])).length()>44:break
			kept.append(word)
		while not kept.is_empty() and String(kept[kept.size()-1]).to_lower() in ["for","of","to","and","the","a","with","in","on","by"]:kept.remove_at(kept.size()-1)
		first=" ".join(kept)
	return _grouped_numbers(first)

## "Grand archive to keep what we know": its purpose, "to keep what we know"
## (the ambition has its own tag).
static func _purpose_words(title:String)->String:
	var at:=title.find(" to ")
	return title.substr(at+1) if at>=0 else title.to_lower()

## "98200 rations" as "98,200 rations".
static func _grouped_numbers(text:String)->String:
	var digits:=RegEx.create_from_string("\\b\\d{4,}\\b")
	var out:=text
	for found in digits.search_all(text):out=out.replace(found.get_string(),preload("res://scripts/hud/era_words.gd").grouped(int(found.get_string())))
	return out

## A work's tooltip: its lore, its master builder and the court's reckoning.
func _work_detail(item:Dictionary,id:String,work_id:String)->String:
	var lines:PackedStringArray=[]
	var lore:=String(item.get("ruin_lore","")) if String(item.get("status",""))=="ruined" else String(item.get("lore",""))
	if not lore.is_empty():lines.append(lore)
	if not String(item.get("architect","")).is_empty():lines.append("Master builder: %s." % String(item.architect))
	if String(item.get("status","")) in ["building","stalled"]:
		var assessment:Dictionary=Works.site_feasibility(id,work_id)
		if not assessment.is_empty():lines.append("The court reckons it %s." % Works.odds_words(float(assessment.get("score",.5))))
	return "
".join(lines) if not lines.is_empty() else String(item.get("name","A great work"))

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
