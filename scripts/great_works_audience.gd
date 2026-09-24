extends RefCounted
## Great Works in the Audience Hall (REVISION 2: conceived wonders).
##
## Two audience kinds, both raised by our own people (origin "court"):
##   "wonder_proposal": an official or would-be architect pitches 1–3 wonders
##       conceived from who we are (GreatWorks.conceive), or the ruler calls
##       for one; the ruler picks a concept (or describes one in words:
##       GreatWorks.concept_from_words), an ambition and a city, hears the court
##       weigh the odds (GreatWorks.assess factors, never a bare number) and
##       commissions it (GreatWorks.commission).
##   "great_work": the master builder or an official about a work under way —
##       modes "decision" (stage gates: options are exactly the engine's and
##       resolve through GreatWorks.decide), "event" (collapse, accident,
##       strike, fire, poaching), "outcome" (collapse/folly, abandoned),
##       "news" (word of another people's work) and "forecast" (Watching Sky).
##
## Truth rules: every answer resolves through the facade or pays from real
## stores; voice text never changes state. The hall owns queueing and expiry.
## Engine calls are resolved dynamically so this UI keeps compiling while the
## engine evolves; a missing call degrades to "not available", never a crash.
##
## Engine hook: GreatWorks.notify_audience("proposal", {trigger:{kind,text},
## concepts?:[...], proposer?:{person_id}|{figure_id}}) raises a pitch; the
## daily scan also reads GreatWorks.pending_proposals("player") if it exists.

const GW_PATH:="res://scripts/great_works.gd"
const CONCEPT_PATH:="res://scripts/wonder_concept.gd"
const U_PATH:="res://scripts/undertaking_system.gd"
const HALL_PATH:="res://scripts/audience_hall.gd"
const MODES:=["decision","event","outcome","news","forecast"]
const EVENT_KINDS:=["collapse","accident","strike","fire","poaching"]
const FAILED_STATUSES:=["collapsed","collapse","folly","failed"]
const FOLLY_EVENTS:=["folly","collapsed"]
const ABANDONED_STATUSES:=["abandoned"]
const AMBITIONS:=["modest","grand","audacious"]
const AMBITION_WORDS:={"modest":"Modest","grand":"Grand","audacious":"Audacious"}
const SEEN_MAX:=64
const FRESH_DAYS:=45
const TONES:={"ambitious":"warm","generous":"warm","gentle":"warm","prudent":"neutral","costly":"neutral","harsh":"hostile","firm":"hostile"}
const STAGE_WORDS:={"foundations":"Foundations","raising":"Raising","crowning":"Crowning","dedication":"Dedication"}
const STAGE_BANDS:=[[.25,"foundations"],[.70,"raising"],[.999,"crowning"],[9.0,"dedication"]]
const FORECAST_OFFICES:=["Scholar","ChiefScout","Steward"]
const NEWS_OFFICES:=["ChiefScout","Envoy","Steward"]
const PROPOSAL_OFFICES:={"knowledge":"Scholar","memory":"Scholar","heavens":"Scholar","food":"Quartermaster","flood":"Quartermaster","harvest":"Quartermaster","war":"Marshal","awe":"Marshal","defense":"Marshal","trade":"Envoy","welcome":"Envoy"}

## Tests may replace the facade with a double exposing the same static API.
static var facade_override:Object=null

# ---------------------------------------------------------------- engine access

static func _hall()->GDScript:
	return load(HALL_PATH) as GDScript

static func facade()->Object:
	if facade_override!=null:return facade_override
	return load(GW_PATH) if ResourceLoader.exists(GW_PATH) else null

static func _has(source:Object,method:String)->bool:
	if source==null:return false
	if source is Script:
		for info:Dictionary in (source as Script).get_script_method_list():
			if String(info.get("name",""))==method:return true
		return false
	return source.has_method(method)

static func has_api(method:String)->bool:
	return _has(facade(),method)

static func api(method:String,arguments:Array=[],fallback:Variant=null)->Variant:
	if not has_api(method):return fallback
	var result:Variant=facade().callv(method,arguments)
	return fallback if result==null else result

static func api_list(method:String,arguments:Array=[])->Array:
	var result:Variant=api(method,arguments,[])
	return result if result is Array else []

static func api_dict(method:String,arguments:Array=[])->Dictionary:
	var result:Variant=api(method,arguments,{})
	return result if result is Dictionary else {}

static func engine(method:String,arguments:Array=[],fallback:Variant=null)->Variant:
	## undertaking_system helpers (site records), when present.
	var system:Object=load(U_PATH) if ResourceLoader.exists(U_PATH) else null
	if not _has(system,method):return fallback
	var result:Variant=system.callv(method,arguments)
	return fallback if result==null else result

static func find_work(city:Dictionary,work_id:String)->Dictionary:
	for r in city.get("undertakings",[]):
		if r is Dictionary and String((r as Dictionary).get("id",""))==work_id:return r
	return {}

static func fraction(r:Dictionary)->float:
	var value:Variant=engine("fraction",[r],null)
	if value is float or value is int:return clampf(float(value),0,1)
	return clampf(float(r.get("fraction",r.get("progress_fraction",0.0))),0,1)

static func stage_of(r:Dictionary)->String:
	if not String(r.get("stage","")).is_empty():return String(r.stage)
	var value:Variant=engine("stage_of",[r],null)
	if value is String:return String(value)
	var f:=fraction(r)
	for band:Array in STAGE_BANDS:
		if f<float(band[0]):return String(band[1])
	return "dedication"

static func record_event(r:Dictionary,day:int,text:String,kind:String)->void:
	if _has(load(U_PATH) if ResourceLoader.exists(U_PATH) else null,"record_event"):engine("record_event",[r,day,text,kind])
	else:
		if not r.get("events") is Array:r["events"]=[]
		(r.events as Array).push_front({"day":day,"text":text,"kind":kind})

# ---------------------------------------------------------------- reading concepts

static func words(value:Variant)->String:
	if value is Dictionary:
		for key in ["title","name","label","text","id"]:
			if not String((value as Dictionary).get(key,"")).is_empty():return String(value[key])
		return ""
	return String(value) if value!=null else ""

static func concept_name(concept:Dictionary)->String:
	var title:=words(concept.get("name",concept.get("title","")))
	return title if not title.is_empty() else "An unnamed work"

static func concept_form(concept:Dictionary)->String:
	## The conceived form (tower, stair, dam…); "form" is the map silhouette family.
	return words(concept.get("shape",concept.get("form","hall"))).to_lower()

static func visual_form(concept:Dictionary)->String:
	return words(concept.get("form",concept.get("visual","hall"))).to_lower()

static func purpose_label(purpose:String)->String:
	if purpose.is_empty() or not ResourceLoader.exists(CONCEPT_PATH):return purpose.replace("_"," ")
	var table:Variant=(load(CONCEPT_PATH) as GDScript).get_script_constant_map().get("PURPOSES",{})
	if table is Dictionary and (table as Dictionary).has(purpose):return String(((table as Dictionary)[purpose] as Dictionary).get("label",purpose.replace("_"," ")))
	return purpose.replace("_"," ")

static func concept_purpose(concept:Dictionary)->String:
	if not String(concept.get("purpose_text","")).is_empty():return String(concept.purpose_text)
	return purpose_label(words(concept.get("purpose","")))

static func concept_lore(concept:Dictionary)->String:
	return words(concept.get("lore",concept.get("description","")))

static func odds_words(score:float)->String:
	if score<.2:return "folly, most likely"
	if score<.4:return "a long gamble"
	if score<.6:return "an even wager"
	if score<.8:return "likely, with care"
	return "as sure as stone gets"

static func duration_words(value:Variant)->String:
	if value is String:return String(value)
	if value is int or value is float:
		var days:=float(value)
		if days<=0:return ""
		if days<365.0:return "under a year"
		var years:=roundi(days/365.0)
		return "about %d year%s" % [years,"" if years==1 else "s"]
	if value is Dictionary:
		var inner:Variant=(value as Dictionary).get("days",null)
		if inner is int or inner is float:return duration_words(inner)
		return words(value)
	return ""

static func costs_words(value:Variant)->String:
	if value is Dictionary:
		var parts:Array[String]=[]
		for key in (value as Dictionary):
			var amount:Variant=value[key]
			if amount is int or amount is float:parts.append("%d %s" % [roundi(float(amount)),String(key).to_lower()])
		return ", ".join(parts)
	return words(value)

# ---------------------------------------------------------------- places and people

static func _player_city(city_id:String)->Dictionary:
	for city:Dictionary in GameState.player_settlements:
		if String(city.get("id",""))==city_id:return city
	return {}

static func _city_of(work_id:String)->Dictionary:
	for city:Dictionary in GameState.player_settlements:
		if not find_work(city,work_id).is_empty():return city
	return {}

static func _site_record(city_id:String,work_id:String)->Dictionary:
	var city:=_player_city(city_id)
	return find_work(city,work_id) if not city.is_empty() else {}

static func default_city_id()->String:
	var selected:=String(GameState.selected_player_settlement_id)
	if not _player_city(selected).is_empty():return selected
	for city:Dictionary in GameState.player_settlements:
		if bool(city.get("primary",false)):return String(city.id)
	return String((GameState.player_settlements[0] as Dictionary).get("id","")) if not GameState.player_settlements.is_empty() else ""

static func work_title(r:Dictionary)->String:
	for key in ["custom_name","name","title"]:
		if not String(r.get(key,"")).is_empty():return String(r[key])
	var concept:Dictionary=r.get("concept",{}) if r.get("concept") is Dictionary else {}
	if not concept.is_empty():return concept_name(concept)
	var shown:Variant=engine("display_name",[r],"")
	return String(shown) if not String(shown).is_empty() else String(r.get("id","A great work")).replace("_"," ").capitalize()

static func work_form(r:Dictionary)->String:
	if not String(r.get("form","")).is_empty():return String(r.form)
	var concept:Dictionary=r.get("concept",{}) if r.get("concept") is Dictionary else {}
	if not concept.is_empty():return concept_form(concept)
	var catalog_path:="res://scripts/undertaking_catalog.gd"
	if ResourceLoader.exists(catalog_path):
		var definition:Variant=(load(catalog_path) as GDScript).call("get_definition",String(r.get("id","")))
		if definition is Dictionary:return String((definition as Dictionary).get("form","hall"))
	return "hall"

static func work_facts(city:Dictionary,r:Dictionary)->Dictionary:
	var architect:Dictionary=r.get("architect",{}) if r.get("architect") is Dictionary else {}
	var concept:Dictionary=r.get("concept",{}) if r.get("concept") is Dictionary else {}
	return {"work_id":String(r.get("id","")),"city_id":String(city.get("id","")),"city_name":String(city.get("name","")),
		"title":work_title(r),"form":work_form(r),"purpose":concept_purpose(concept) if not concept.is_empty() else words(r.get("purpose","")),
		"ambition":String(r.get("ambition",concept.get("ambition",""))),"stage":stage_of(r),"progress":snappedf(fraction(r),.001),
		"architect_id":String(architect.get("id","")),"architect_name":String(architect.get("name","")),
		"style":String(architect.get("style","")),"vision":snappedf(float(architect.get("vision",.5)),.01),"ego":snappedf(float(architect.get("ego",.5)),.01),
		"temperament":String(architect.get("temperament",""))}

static func _architect_speaker(facts:Dictionary)->Dictionary:
	var who:=String(facts.get("architect_name",""))
	if who.is_empty():
		var steward:=_office_speaker(["Steward"])
		if not steward.is_empty():return steward
		who="The master builder"
	return {"name":who,"title":"Master Builder of %s" % String(facts.get("title","the work")),"person_id":0}

static func _office_speaker(keys:Array)->Dictionary:
	for key in keys:
		var person:Dictionary=GovernmentPeopleSystem.officeholder(String(key))
		if not person.is_empty():return {"name":String(person.name),"title":String(person.get("office_title",key)),"person_id":int(person.person_id)}
	return {}

static func _would_be_architect()->Dictionary:
	## A living, unassigned master builder or engineer who might raise it.
	var assigned:Array=HistoricalFigures.assignments.values()
	for role in ["Architect","Engineer"]:
		for p:Dictionary in HistoricalFigures.people:
			if String(p.get("role",""))==role and String(p.get("status",""))=="living" and not String(p.id) in assigned:return p
	return {}

static func _waiting_of(kind:String)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for audience:Dictionary in _hall().call("waiting"):
		if String(audience.get("kind",""))==kind:result.append(audience)
	return result

static func _has_waiting(mode:String,work_id:String,key:String)->bool:
	for audience:Dictionary in _waiting_of("great_work"):
		var gw:Dictionary=audience.get("great_work",{})
		if String(gw.get("mode",""))==mode and String(gw.get("work_id",""))==work_id and (key.is_empty() or String(gw.get("key",""))==key):return true
	return false

static func _room()->bool:
	return (_hall().call("waiting") as Array).size()<int(_hall().get_script_constant_map().get("QUEUE_MAX",4))

# ---------------------------------------------------------------- conception

## An audience pitching wonders. payload: {trigger:{kind,text}, concepts:[...],
## proposer:{person_id:int}|{figure_id:String}, origin:"engine"|"ruler"}.
## Concepts come from GreatWorks.conceive when none are supplied.
static func proposal_audience(payload:Dictionary={})->Dictionary:
	var trigger:Dictionary=payload.get("trigger",{}) if payload.get("trigger") is Dictionary else {}
	var ruler:=String(payload.get("origin",""))=="ruler"
	if not ruler and not _waiting_of("wonder_proposal").is_empty():return {}
	var concepts:Array=[]
	var supplied:Variant=payload.get("concepts",[])
	if supplied is Array:
		for concept in supplied:
			if concept is Dictionary:concepts.append((concept as Dictionary).duplicate(true))
	if concepts.is_empty():
		for concept in api_list("conceive",["player",trigger]):
			if concept is Dictionary:concepts.append((concept as Dictionary).duplicate(true))
	if concepts.size()>3:concepts.resize(3)
	if concepts.is_empty() and not ruler:return {}
	var first_ambition:=String((concepts[0] as Dictionary).get("proposed_ambition","grand")) if not concepts.is_empty() else "grand"
	var speaker:={}
	var figure_id:=""
	var proposer:Dictionary=payload.get("proposer",{}) if payload.get("proposer") is Dictionary else {}
	if int(proposer.get("person_id",0))>0:
		var person:Dictionary=GovernmentPeopleSystem.person_snapshot(int(proposer.person_id))
		if not person.is_empty():speaker={"name":String(person.name),"title":String(person.get("office_title",person.get("title","Official"))),"person_id":int(person.person_id)}
	elif not String(proposer.get("figure_id","")).is_empty():
		var figure:Dictionary=HistoricalFigures.by_id(String(proposer.figure_id))
		if not figure.is_empty():
			speaker={"name":String(figure.name),"title":"%s, who would build it" % String(figure.get("role","Architect")).capitalize(),"person_id":0}
			figure_id=String(figure.id)
	if speaker.is_empty():
		var figure2:=_would_be_architect()
		if not figure2.is_empty() and not ruler:
			speaker={"name":String(figure2.name),"title":"%s, who would build it" % String(figure2.get("role","Architect")).capitalize(),"person_id":0}
			figure_id=String(figure2.id)
		else:
			var office:=String(PROPOSAL_OFFICES.get(String(trigger.get("kind","")),"Steward"))
			speaker=_office_speaker([office,"Steward","Scholar","Quartermaster"])
	if speaker.is_empty():return {}
	var proposal_record:={"trigger":{"kind":String(trigger.get("kind","ruler" if ruler else "")),"text":String(trigger.get("text","The ruler calls for a great work." if ruler else ""))},
		"concepts":concepts,"chosen":0,"ambition":first_ambition if first_ambition in AMBITIONS else "grand","city_id":default_city_id(),"origin":"ruler" if ruler else "engine","figure_id":figure_id}
	return _hall().call("enqueue",{"kind":"wonder_proposal","origin":"court","speaker":speaker,"wonder_proposal":proposal_record})

## Opened from the works screen: the ruler calls for a great work.
static func ruler_proposal()->Dictionary:
	for audience:Dictionary in _waiting_of("wonder_proposal"):return audience
	return proposal_audience({"origin":"ruler","trigger":{"kind":"ruler","text":"The ruler calls for a great work worthy of our people."}})

static func proposal(audience:Dictionary)->Dictionary:
	return audience.get("wonder_proposal",{}) if audience.get("wonder_proposal") is Dictionary else {}

static func chosen_concept(audience:Dictionary)->Dictionary:
	var p:=proposal(audience)
	var concepts:Array=p.get("concepts",[])
	if concepts.is_empty():return {}
	var index:=clampi(int(p.get("chosen",0)),0,concepts.size()-1)
	return concepts[index] if concepts[index] is Dictionary else {}

## The ruler's current pick. choice: {chosen:int, ambition:String, city_id:String}.
static func set_choice(audience:Dictionary,choice:Dictionary)->Dictionary:
	var p:=proposal(audience)
	if p.is_empty():return {"error":"No proposal is before you."}
	if choice.has("chosen"):p["chosen"]=clampi(int(choice.chosen),0,maxi(0,(p.get("concepts",[]) as Array).size()-1))
	if choice.has("ambition") and String(choice.ambition) in AMBITIONS:p["ambition"]=String(choice.ambition)
	if choice.has("city_id") and not _player_city(String(choice.city_id)).is_empty():p["city_id"]=String(choice.city_id)
	return {"ok":true}

## The ruler describes a vision in words; it joins the concepts and is chosen.
## `mapping` is an optional model reply ({form,purpose,ambition}) bounded by
## GreatWorks.concept_from_mapping; the offline keyword mapping is the fallback.
static func describe(audience:Dictionary,text:String,mapping:Dictionary={})->Dictionary:
	var p:=proposal(audience)
	var clean:=text.strip_edges().replace("\n"," ").substr(0,400)
	if p.is_empty() or clean.is_empty():return {"error":"Describe the work you imagine."}
	var concept:={}
	if not mapping.is_empty():concept=api_dict("concept_from_mapping",[mapping,clean,"player"])
	if concept.is_empty() or concept.has("error"):concept=api_dict("concept_from_words",[clean,"player"])
	if concept.is_empty() or concept.has("error"):return {"error":String(concept.get("error","Your builders cannot picture that yet."))}
	concept["described_by_ruler"]=true
	var concepts:Array=p.get("concepts",[])
	for index in concepts.size():
		if concepts[index] is Dictionary and bool((concepts[index] as Dictionary).get("described_by_ruler",false)):
			concepts.remove_at(index)
			break
	concepts.append(concept)
	if concepts.size()>4:concepts.pop_front()
	p["concepts"]=concepts
	p["chosen"]=concepts.size()-1
	return {"ok":true,"concept":concept}

## Feasibility of the current pick at the chosen ambition.
static func at_ambition(concept:Dictionary,ambition:String)->Dictionary:
	if concept.is_empty():return {}
	var retargeted:=api_dict("retarget",[concept,ambition])
	var result:=retargeted if not retargeted.is_empty() else concept.duplicate(true)
	result["ambition"]=ambition
	return result

static func assessment(audience:Dictionary)->Dictionary:
	var concept:=chosen_concept(audience)
	if concept.is_empty():return {}
	var ask:=at_ambition(concept,String(proposal(audience).get("ambition","grand")))
	ask["city_id"]=String(proposal(audience).get("city_id",""))
	return api_dict("assess",[ask,"player"])

# ---------------------------------------------------------------- work audiences

static func decision_audience(work_id:String,city_id:String="")->Dictionary:
	var city:=_player_city(city_id) if not city_id.is_empty() else _city_of(work_id)
	if city.is_empty():return {}
	var r:=find_work(city,work_id)
	var decision:Dictionary=r.get("decision",{}) if r.get("decision") is Dictionary else {}
	if decision.is_empty():return {}
	var key:=String(decision.get("key",""))
	if _has_waiting("decision",work_id,key):return {}
	var facts:=work_facts(city,r)
	facts.merge({"mode":"decision","key":key,"text":String(decision.get("prompt","")),"posed_day":int(decision.get("day",GameState.elapsed_days))},true)
	var patience:=90
	if ResourceLoader.exists(U_PATH):patience=int((load(U_PATH) as GDScript).get_script_constant_map().get("PLAYER_DECISION_DAYS",90))
	return _hall().call("enqueue",{"kind":"great_work","origin":"court","speaker":_architect_speaker(facts),"great_work":facts,
		"expires_day":int(decision.get("day",GameState.elapsed_days))+patience})

static func event_audience(work_id:String,kind:String,text:String,day:int)->Dictionary:
	if kind not in EVENT_KINDS or not _room():return {}
	var city:=_city_of(work_id)
	var r:=find_work(city,work_id) if not city.is_empty() else {}
	if r.is_empty() or _has_waiting("event",work_id,""):return {}
	var facts:=work_facts(city,r)
	facts.merge({"mode":"event","key":kind,"text":text,"event_day":day},true)
	var speaker:=_architect_speaker(facts)
	if kind=="poaching":speaker=_office_speaker(["Steward","Quartermaster"])
	if speaker.is_empty():return {}
	return _hall().call("enqueue",{"kind":"great_work","origin":"court","speaker":speaker,"great_work":facts})

## A grave scene when a work collapses into folly, or a brief one when abandoned.
static func outcome_audience(work:Dictionary)->Dictionary:
	var work_id:=String(work.get("work_id",work.get("id","")))
	var city_id:=String(work.get("city_id",""))
	var city:=_player_city(city_id) if not city_id.is_empty() else _city_of(work_id)
	var r:=find_work(city,work_id) if not city.is_empty() else {}
	if r.is_empty() or _has_waiting("outcome",work_id,""):return {}
	var status:=String(work.get("status",r.get("status","")))
	var key:="abandoned" if status in ABANDONED_STATUSES else "collapse"
	var facts:=work_facts(city,r)
	var dead:Array=[]
	for person in work.get("dead",work.get("victims",r.get("victims",[]))):dead.append(String(person))
	var ruin_lore:=String(work.get("ruin_lore",r.get("ruin_lore","")))
	if dead.is_empty() and not ruin_lore.is_empty():
		var names:=RegEx.new()
		names.compile("finished\\. (.+?) died beneath it")
		var found:=names.search(ruin_lore)
		if found!=null and found.get_string(1)!="No one":
			for part in found.get_string(1).replace(" and ",", ").split(", ",false):dead.append(part.strip_edges())
	facts.merge({"mode":"outcome","key":key,"text":String(work.get("text",ruin_lore if not ruin_lore.is_empty() else r.get("reason",""))),"ruin_name":String(work.get("ruin_name",facts.title)),
		"dead":dead,"lore":ruin_lore if not ruin_lore.is_empty() else String(r.get("legacy","")),"outcome_day":int(work.get("outcome_day",GameState.elapsed_days))},true)
	var speaker:=_architect_speaker(facts)
	if speaker.is_empty():return {}
	return _hall().call("enqueue",{"kind":"great_work","origin":"court","speaker":speaker,"great_work":facts})

static func news_audience(item:Dictionary)->Dictionary:
	var speaker:=_office_speaker(NEWS_OFFICES)
	if speaker.is_empty() or not _room():return {}
	var facts:={"mode":"news","key":String(item.get("status","building")),"work_id":String(item.get("work_id",item.get("id",""))),"title":String(item.get("name",item.get("title","a great work"))),
		"form":String(item.get("form","")),"purpose":words(item.get("purpose","")),"text":String(item.get("text","")),"civ_name":String(item.get("civ_name","")),
		"as_of":int(item.get("day",item.get("as_of",0))),"confidence":float(item.get("confidence",.5)),"source":String(item.get("source",""))}
	return _hall().call("enqueue",{"kind":"great_work","origin":"court","speaker":speaker,"great_work":facts,"civ_id":String(item.get("owner","")),"civ_name":String(item.get("civ_name",""))})

static func forecast_audience(item:Dictionary)->Dictionary:
	var speaker:=_office_speaker(FORECAST_OFFICES)
	if speaker.is_empty():
		GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"THE WATCHING SKY WARNS","description":String(item.get("text","")),"domain":"food","severity":"major"})
		return {}
	var famine:=String(item.get("kind",""))=="famine"
	var facts:={"mode":"forecast","key":String(item.get("kind","lean_season")),"text":String(item.get("text","")),"title":String(item.get("source","the sky-watchers")),
		"in_days":int(item.get("in_days",0)),"start_day":int(item.get("start_day",0)),"end_day":int(item.get("end_day",0)),"severity":float(item.get("severity",0))}
	return _hall().call("enqueue",{"kind":"great_work","origin":"court","speaker":speaker,"great_work":facts,
		"petition":{"topic":"food","summary":String(item.get("text","")),"suggested_decree":"Ration food for thirty days" if famine or float(item.get("severity",0))>=.25 else "Send gatherers to find food"}})

# ---------------------------------------------------------------- daily scan

static func _seen()->Dictionary:
	var s:Dictionary=_hall().call("state")
	if not s.get("great_works_seen") is Dictionary:s["great_works_seen"]={}
	return s.great_works_seen

static func _statuses()->Dictionary:
	## Last seen status per site, so an abandonment is noticed once as it happens.
	var s:Dictionary=_hall().call("state")
	if not s.get("great_works_status") is Dictionary:s["great_works_status"]={}
	var table:Dictionary=s.great_works_status
	if table.size()>64:table.clear()
	return table

static func _mark(key:String,day:int)->bool:
	## True the first time a key is seen.
	var seen:=_seen()
	if seen.has(key):return false
	seen[key]=day
	while seen.size()>SEEN_MAX:
		var oldest:=""
		var oldest_day:=1<<30
		for entry:String in seen:
			if int(seen[entry])<oldest_day:
				oldest_day=int(seen[entry])
				oldest=entry
		seen.erase(oldest)
	return true

## Once per game day after AudienceHall.daily. Returns new audiences.
static func daily(day:int)->Array[Dictionary]:
	var arrivals:Array[Dictionary]=[]
	if WorldSimulation.actor_id!="player":return arrivals
	retire_settled()
	for pending in api_list("pending_decisions"):
		if not pending is Dictionary:continue
		var made:=decision_audience(String(pending.get("work_id","")),String(pending.get("city_id","")))
		if not made.is_empty():arrivals.append(made)
	for event in api_list("recent_events",[12]):
		if not event is Dictionary:continue
		var kind:=String(event.get("kind",""))
		if kind not in EVENT_KINDS or day-int(event.get("day",0))>3:continue
		if not _mark("event:%s:%s:%d" % [String(event.get("work_id","")),kind,int(event.get("day",0))],day):continue
		var made_event:=event_audience(String(event.get("work_id","")),kind,String(event.get("text","")),int(event.get("day",day)))
		if not made_event.is_empty():arrivals.append(made_event)
	for event in api_list("recent_events",[12]):
		if not event is Dictionary or String(event.get("kind","")) not in FOLLY_EVENTS or day-int(event.get("day",0))>3:continue
		if not _mark("outcome:%s:collapse:%d" % [String(event.get("work_id","")),int(event.get("day",0))],day):continue
		var made_folly:=outcome_audience({"work_id":String(event.get("work_id","")),"city_id":String(event.get("city_id","")),"status":"collapse","text":String(event.get("text",""))})
		if not made_folly.is_empty():arrivals.append(made_folly)
	var statuses:=_statuses()
	for work in api_list("works",["player"]):
		if not work is Dictionary:continue
		var work_key:=String(work.get("city_id",""))+"/"+String(work.get("work_id",work.get("id","")))
		var status:=String(work.get("status",""))
		var before:=String(statuses.get(work_key,""))
		statuses[work_key]=status
		if before.is_empty() or before==status or status not in ABANDONED_STATUSES:continue
		var made_outcome:=outcome_audience(work)
		if not made_outcome.is_empty():arrivals.append(made_outcome)
	for item in api_list("forecast",["player"]):
		if not item is Dictionary:continue
		if String(item.get("kind",""))=="lean_season" and float(item.get("severity",0))<.12:continue
		if not _mark("forecast:%s:%d" % [String(item.get("kind","")),floori(float(item.get("start_day",day))/30.0)],day):continue
		var made_forecast:=forecast_audience(item)
		if not made_forecast.is_empty():arrivals.append(made_forecast)
		break
	for item in api_list("known_foreign_works",["player"]):
		if not item is Dictionary:continue
		if day-int(item.get("day",item.get("as_of",-9999)))>FRESH_DAYS:continue
		if not _mark("news:%s:%s:%s" % [String(item.get("owner","")),String(item.get("work_id",item.get("id",item.get("name","")))),String(item.get("status",""))],day):continue
		var made_news:=news_audience(item)
		if not made_news.is_empty():arrivals.append(made_news)
		break
	for trigger in api_list("pending_proposals",["player"]):
		if not trigger is Dictionary:continue
		var made_pitch:=proposal_audience(trigger)
		if not made_pitch.is_empty():arrivals.append(made_pitch)
	return arrivals

static func retire_settled()->void:
	var hall:=_hall()
	for audience:Dictionary in _waiting_of("great_work"):
		if not stale(audience):continue
		var gw:Dictionary=audience.get("great_work",{})
		audience["status"]="resolved"
		audience["outcome"]="The %s question at %s was already settled." % [String(gw.get("key","")).replace("_"," "),String(gw.get("title",""))]
		audience["option_id"]="settled"
		hall.call("_archive",audience)

static func stale(audience:Dictionary)->bool:
	var gw:Dictionary=audience.get("great_work",{})
	if String(gw.get("mode",""))!="decision":return false
	var r:=_site_record(String(gw.get("city_id","")),String(gw.get("work_id","")))
	var decision:Dictionary=r.get("decision",{}) if r.get("decision") is Dictionary else {}
	return r.is_empty() or String(decision.get("key",""))!=String(gw.get("key",""))

# ---------------------------------------------------------------- options

static func _option(id:String,label:String,sub:String,tone:String,enabled:bool=true,reason:String="")->Dictionary:
	return {"id":id,"label":label,"sub":sub,"enabled":enabled,"reason":"" if enabled else reason,"tone":tone}

static func _food_gift()->float:
	return float(maxi(5,roundi(clampf(float(GameState.population_exact)*.05,5.0,60.0))))

static func _stock(resource:String)->float:
	return float(_hall().call("player_stock",resource))

static func _debit_food(amount:float)->float:
	return float(_hall().call("_debit_player","Food",amount))

static func options(audience:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if String(audience.get("kind",""))=="wonder_proposal":
		var concept:=chosen_concept(audience)
		var p:=proposal(audience)
		var city:=_player_city(String(p.get("city_id","")))
		var enabled:=not concept.is_empty() and not city.is_empty() and has_api("commission")
		var reason:="Choose a work to raise." if concept.is_empty() else ("Choose a city to raise it in." if city.is_empty() else "Your builders cannot begin just now.")
		var label:="Commission %s" % concept_name(concept) if not concept.is_empty() else "Commission it"
		result.append(_option("commission",label,"%s ambition, at %s. A master builder begins the foundations." % [String(AMBITION_WORDS.get(String(p.get("ambition","grand")),"Grand")),String(city.get("name","our city"))],"warm",enabled,reason))
		result.append(_option("later","Not yet","Keep the idea; nothing is spent. They may ask again.","neutral"))
		result.append(_option("dismiss","Folly — send them away","Nothing is spent; the one who pitched it will resent it.","hostile"))
		return result
	var gw:Dictionary=audience.get("great_work",{})
	match String(gw.get("mode","")):
		"decision":
			if stale(audience):
				result.append(_option("settled","The matter is settled","The question was already answered; thank them and move on.","neutral"))
				return result
			for pending in api_list("pending_decisions"):
				if not pending is Dictionary:continue
				if String(pending.get("work_id",""))!=String(gw.get("work_id","")) or String(pending.get("city_id",""))!=String(gw.get("city_id","")):continue
				for option in pending.get("options",[]):
					if not option is Dictionary:continue
					var sub:=String(option.get("sub",""))
					var odds:=words(option.get("odds",option.get("feasibility_text","")))
					if not odds.is_empty():sub+=" "+odds
					result.append(_option(String(option.get("id","")),String(option.get("label",option.get("id",""))),sub,String(TONES.get(String(option.get("tone","")),"neutral")),bool(option.get("enabled",true)),String(option.get("reason",""))))
		"event":
			var food:=_food_gift()
			var short:="" if _stock("Food")>=food else "The stores cannot spare %d Food." % roundi(food)
			match String(gw.get("key","")):
				"accident":
					result.append(_option("honor_dead","Honor the dead","Send %d Food to the families and name the dead at the works; cohesion rises." % roundi(food),"warm",short.is_empty(),short))
					result.append(_option("press_on","Work goes on","No cost; the crews remember that nobody stopped.","hostile"))
				"strike":
					var wage:=food*2.0
					var short_wage:="" if _stock("Food")>=wage else "The stores cannot spare %d Food." % roundi(wage)
					result.append(_option("meet_demands","Meet their demands","Pay %d Food in extra rations; the crews return to work at once." % roundi(wage),"warm",short_wage.is_empty(),short_wage))
					result.append(_option("wait_out","Wait them out","No cost; the works stay silent until the strike ends.","hostile"))
				"collapse","fire":
					result.append(_option("careful","Rebuild with care","Protect daily needs: fewer builders, no work through shortages.","neutral"))
					result.append(_option("press","Press ahead","Half the builders on the works, even through hardship.","hostile"))
				_:
					result.append(_option("acknowledge","So be it","Thank them for the report.","neutral"))
		"outcome":
			if String(gw.get("key",""))=="abandoned":
				result.append(_option("acknowledge","Let it stand as it is","The unfinished work remains; its story is kept.","neutral"))
				return result
			var dead:Array=gw.get("dead",[])
			var mourning:=_mourning_cost(dead.size())
			var short2:="" if _stock("Food")>=mourning else "The stores cannot spare %d Food." % roundi(mourning)
			result.append(_option("mourn","Mourn together","%d Food to the families%s; the ruin is named and remembered. Cohesion rises a little." % [roundi(mourning)," of the dead" if not dead.is_empty() else " of the crews"],"warm",short2.is_empty(),short2))
			if not String(gw.get("architect_id","")).is_empty():
				result.append(_option("blame","Lay the blame on %s" % String(gw.get("architect_name","the builder")),"The master builder is disgraced before the court; a little of the shame lifts from your seat.","hostile"))
			result.append(_option("defy","We will raise another","Refuse the omen: the court is asked for a new work. Nothing is spent yet.","neutral"))
		"news":
			result.append(_option("noted","Noted","Thank them for the word.","neutral"))
			result.append(_option("answer","Answer it with a work of our own","The court is asked to conceive a great work. Nothing is spent yet.","warm"))
		"forecast":
			var decree:=String((audience.get("petition",{}) as Dictionary).get("suggested_decree",""))
			if not decree.is_empty():result.append(_option("decree","Proclaim it: %s" % decree.to_lower(),"Issued to the civic council as a decree now, before the lean days arrive.","warm"))
			if decree!="Send gatherers to find food":result.append(_option("decree_gather","Send gatherers out","Issued to the civic council: send gatherers to find food.","neutral"))
			result.append(_option("noted","Noted","Thank them; plan later.","neutral"))
	return result

static func _mourning_cost(dead:int)->float:
	return roundf(_food_gift()*(1.0+float(dead)*.25))

# ---------------------------------------------------------------- resolve

## {ok, outcome, reaction, decree?, conceive?}. ok=false leaves the audience waiting.
static func resolve(audience:Dictionary,option_id:String)->Dictionary:
	var speaker:Dictionary=audience.get("speaker",{})
	var pid:=int(speaker.get("person_id",0))
	var speaker_name:=String(speaker.get("name",""))
	var day:=int(GameState.elapsed_days)
	if String(audience.get("kind",""))=="wonder_proposal":
		return _resolve_proposal(audience,option_id,pid)
	var gw:Dictionary=audience.get("great_work",{})
	var title:=String(gw.get("title","the work"))
	var r:=_site_record(String(gw.get("city_id","")),String(gw.get("work_id","")))
	match String(gw.get("mode","")):
		"decision":
			if option_id=="settled":return {"ok":true,"outcome":"The question at %s had already been answered." % title,"reaction":"neutral"}
			var result:=api_dict("decide",[String(gw.get("city_id","")),String(gw.get("work_id","")),option_id])
			if result.is_empty() or result.has("error"):return {"ok":false,"outcome":String(result.get("error","The master builder cannot do that now.")),"reaction":"neutral"}
			var ego:=float(gw.get("ego",.5))
			var reaction:="pleased"
			match option_id:
				"grander","honor":reaction="delighted"
				"practical","protect":reaction="offended" if ego>.6 else "neutral"
				"refuse":reaction="furious" if ego>.7 else "offended"
				"volunteers":reaction="neutral" if ego>.6 else "pleased"
			var architect_id:=String(gw.get("architect_id",""))
			if not architect_id.is_empty():HistoricalFigures.note(architect_id,day,"Brought the %s question for %s before the ruler's court." % [String(gw.get("key","")),title])
			return {"ok":true,"outcome":String(result.get("message","")),"reaction":reaction}
		"event":
			match option_id:
				"honor_dead":
					var paid:=_debit_food(_food_gift())
					GameState.simulation_metrics["cohesion"]=clampf(float(GameState.simulation_metrics.get("cohesion",.5))+.01,.01,.99)
					if not r.is_empty():record_event(r,day,"The ruler honored those who died at the works; %d Food went to their families." % roundi(paid),"memorial")
					return {"ok":true,"outcome":"You sent %d Food to the families of the dead at %s. Cohesion rose a little." % [roundi(paid),title],"reaction":"pleased"}
				"meet_demands":
					var wage:=_debit_food(_food_gift()*2.0)
					if not r.is_empty():
						r.erase("halt_until")
						record_event(r,day,"The strike ended when the ruler paid %d Food in extra rations." % roundi(wage),"strike")
					return {"ok":true,"outcome":"You paid %d Food in extra rations; the crews of %s are back at work." % [roundi(wage),title],"reaction":"delighted"}
				"careful","press":
					engine("direct",[String(gw.get("city_id","")),String(gw.get("work_id","")),option_id])
					return {"ok":true,"outcome":("Work on %s now protects daily needs." if option_id=="careful" else "Half the builders now press ahead on %s, through hardship if need be.") % title,"reaction":"pleased" if option_id=="press" else "neutral"}
				"press_on":return {"ok":true,"outcome":"Work at %s goes on without pause." % title,"reaction":"neutral"}
				"wait_out":return {"ok":true,"outcome":"The crews of %s stay out until the strike runs its course." % title,"reaction":"offended"}
			return {"ok":true,"outcome":"You heard %s's account of %s." % [speaker_name,title],"reaction":"neutral"}
		"outcome":
			var ruin:=String(gw.get("ruin_name",title))
			match option_id:
				"mourn":
					var dead:Array=gw.get("dead",[])
					var paid2:=_debit_food(_mourning_cost(dead.size()))
					GameState.simulation_metrics["cohesion"]=clampf(float(GameState.simulation_metrics.get("cohesion",.5))+.01,.01,.99)
					if not r.is_empty():record_event(r,day,"The people mourned together at %s; %d Food went to the families." % [ruin,roundi(paid2)],"memorial")
					return {"ok":true,"outcome":"You mourned with the people at %s and sent %d Food to the families. Cohesion rose a little." % [ruin,roundi(paid2)],"reaction":"pleased"}
				"blame":
					var architect_id2:=String(gw.get("architect_id",""))
					if not architect_id2.is_empty():HistoricalFigures.note(architect_id2,day,"Disgraced before the court for the fall of %s." % ruin,-10)
					GameState.simulation_metrics["legitimacy"]=clampf(float(GameState.simulation_metrics.get("legitimacy",.5))+.01,.01,.99)
					if not r.is_empty():record_event(r,day,"The ruler laid the blame for %s on %s." % [ruin,String(gw.get("architect_name","the master builder"))],"blame")
					return {"ok":true,"outcome":"You laid the fall of %s on %s. A little of the shame lifts from your seat; the builder's name will carry it." % [ruin,String(gw.get("architect_name","the master builder"))],"reaction":"furious"}
				"defy":
					if not r.is_empty():record_event(r,day,"The ruler refused the omen and called for a new work.","defiance")
					return {"ok":true,"outcome":"You refused to let %s be the last word. The court will bring you a new work." % ruin,"reaction":"delighted","conceive":true}
			return {"ok":true,"outcome":"%s stands as it was left." % title,"reaction":"neutral"}
		"news":
			if pid>0:GovernmentPeopleSystem.adjust_person_relationship(pid,.02,0,0)
			if option_id=="answer":return {"ok":true,"outcome":"You heard of %s and resolved that your people will answer it." % title,"reaction":"delighted","conceive":true}
			return {"ok":true,"outcome":"You thanked %s for word of %s." % [speaker_name,title],"reaction":"neutral"}
		"forecast":
			var decree:=""
			if option_id=="decree":decree=String((audience.get("petition",{}) as Dictionary).get("suggested_decree",""))
			elif option_id=="decree_gather":decree="Send gatherers to find food"
			if pid>0:
				GovernmentPeopleSystem.adjust_person_relationship(pid,.04 if not decree.is_empty() else .01,0,0)
				GovernmentPeopleSystem.record_person_memory(pid,"Brought the Watching Sky's warning to the ruler%s." % (", who acted on it at once" if not decree.is_empty() else ""),"audience",.5,{"emotion":"vindicated" if not decree.is_empty() else "duty","outcome":option_id})
			if decree.is_empty():return {"ok":true,"outcome":"You noted the warning: %s" % String(gw.get("text","")),"reaction":"neutral"}
			return {"ok":true,"outcome":"You heeded the warning and proclaimed: \"%s\"." % decree,"reaction":"delighted","decree":decree}
	return {"ok":false,"outcome":"That answer is not open to you here.","reaction":"neutral"}

static func _resolve_proposal(audience:Dictionary,option_id:String,pid:int)->Dictionary:
	var p:=proposal(audience)
	var concept:=chosen_concept(audience)
	var figure_id:=String(p.get("figure_id",""))
	var day:=int(GameState.elapsed_days)
	match option_id:
		"commission":
			var ambition:=String(p.get("ambition","grand"))
			var result:=api_dict("commission",[String(p.get("city_id","")),at_ambition(concept,ambition),ambition,"player"])
			if result.is_empty() or result.has("error"):return {"ok":false,"outcome":String(result.get("error","Your builders cannot begin just now.")),"reaction":"neutral"}
			if pid>0:
				GovernmentPeopleSystem.adjust_person_relationship(pid,.05,.02,-.02)
				GovernmentPeopleSystem.record_person_memory(pid,"Pitched %s to the ruler, who commissioned it." % concept_name(concept),"audience",.6,{"emotion":"vindicated","outcome":"commission"})
			if not figure_id.is_empty():HistoricalFigures.note(figure_id,day,"Pitched %s to the ruler, who commissioned it." % concept_name(concept),4)
			var message:=String(result.get("message","%s is commissioned at %s ambition." % [concept_name(concept),String(AMBITION_WORDS.get(ambition,"Grand"))]))
			return {"ok":true,"outcome":message,"reaction":"delighted","work_id":String(result.get("work_id",result.get("id","")))}
		"later":
			if pid>0:GovernmentPeopleSystem.adjust_person_relationship(pid,.01,0,0)
			return {"ok":true,"outcome":"You kept the idea of %s for another day. Nothing was spent." % concept_name(concept),"reaction":"neutral"}
		"dismiss":
			if pid>0:
				GovernmentPeopleSystem.adjust_person_relationship(pid,-.02,0,.04)
				GovernmentPeopleSystem.record_person_memory(pid,"Pitched %s to the ruler and was called a fool for it." % concept_name(concept),"audience",.55,{"emotion":"slighted","outcome":"dismiss"})
			if not figure_id.is_empty():HistoricalFigures.note(figure_id,day,"Their pitch for %s was dismissed as folly." % concept_name(concept))
			return {"ok":true,"outcome":"You called %s a folly and sent its champion away. They will remember it." % concept_name(concept),"reaction":"offended"}
	return {"ok":false,"outcome":"That answer is not open to you here.","reaction":"neutral"}

# ---------------------------------------------------------------- voice facts

static func factors(assess:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for factor in assess.get("factors",[]):
		if factor is Dictionary:
			var effect:Variant=(factor as Dictionary).get("effect",0)
			var helps:=(float(effect)>=0.0) if (effect is float or effect is int) else String(effect) in ["helps","good","positive","+"]
			result.append({"name":String(factor.get("name","")),"helps":helps,"text":String(factor.get("text",""))})
	return result

static func voice_facts(audience:Dictionary)->Dictionary:
	if String(audience.get("kind",""))=="wonder_proposal":
		var p:=proposal(audience)
		var concepts:Array=[]
		for concept in p.get("concepts",[]):
			if concept is Dictionary:concepts.append({"name":concept_name(concept),"form":concept_form(concept),"purpose":concept_purpose(concept),"lore":concept_lore(concept),"motive":String((concept as Dictionary).get("motive",""))})
		var assess:=assessment(audience)
		return {"trigger":String((p.get("trigger",{}) as Dictionary).get("text","")),"concepts":concepts,"chosen":concept_name(chosen_concept(audience)),
			"ambition":String(p.get("ambition","grand")),"city":String(_player_city(String(p.get("city_id",""))).get("name","")),
			"odds_in_words":odds_words(float(assess.get("score",.5))) if not assess.is_empty() else "","spoken_verdict":String(assess.get("spoken","")),"factors":factors(assess),
			"costs":costs_words(assess.get("costs",{})),"duration":duration_words(assess.get("duration_estimate",""))}
	var gw:Dictionary=(audience.get("great_work",{}) as Dictionary).duplicate(true)
	gw["progress_percent"]=roundi(float(gw.get("progress",0))*100)
	gw["stage_words"]=String(STAGE_WORDS.get(String(gw.get("stage","")),""))
	if String(gw.get("mode",""))=="decision":
		var feasible:=site_feasibility(String(gw.get("city_id","")),String(gw.get("work_id","")))
		if not feasible.is_empty():
			gw["odds_in_words"]=odds_words(float(feasible.get("score",.5)))
			gw["spoken_verdict"]=String(feasible.get("spoken",""))
			gw["factors"]=factors(feasible)
	var labels:Array=[]
	for option:Dictionary in options(audience):labels.append("%s (%s)" % [String(option.label),String(option.sub)])
	gw["answers_before_the_ruler"]=labels
	gw.erase("architect_id")
	return gw

static func site_feasibility(city_id:String,work_id:String)->Dictionary:
	var site:=api_dict("site",[city_id,work_id])
	for key in ["feasibility","assessment"]:
		if site.get(key) is Dictionary:return site[key]
	return {}

static func valid(value:Variant)->bool:
	if not value is Dictionary:return false
	var gw:Dictionary=value
	if String(gw.get("mode","")) not in MODES:return false
	for key in ["work_id","city_id","key","title","text"]:
		if gw.has(key) and not gw[key] is String:return false
	return JSON.stringify(gw).length()<=4000

static func valid_proposal(value:Variant)->bool:
	if not value is Dictionary:return false
	var p:Dictionary=value
	if not p.get("concepts",[]) is Array or (p.get("concepts",[]) as Array).size()>4:return false
	for concept in p.get("concepts",[]):
		if not concept is Dictionary:return false
	if not (p.get("chosen",0) is int or p.get("chosen",0) is float):return false
	if String(p.get("ambition","grand")) not in AMBITIONS:return false
	return JSON.stringify(p).length()<=16000
