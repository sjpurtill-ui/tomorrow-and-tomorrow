extends RefCounted
## The live model's small part in envoy business: with a connection, one cheap
## call per visit lets it choose, among the requests the state truly backs
## (AudienceHall keeps up to two alternatives beside its own choice), the one
## this ruler would most plausibly send now, and write the herald's headline
## and one plain sentence of what is at stake for them.
##
## It never invents business: it may only pick a candidate id from an enum,
## and its words are validated (length, era, numbers and names from the
## facts, no maxims, nothing about games or systems). Any failure, timeout or
## rejected output keeps the hall's deterministic choice, which is also the
## whole of offline play. The result is cached on the audience (request_ai),
## so a visit is never asked about twice.
##
## Transport lives in audience_voice.gd (pick_request); this file is pure.

const Hall:=preload("res://scripts/audience_hall.gd")
const CV:=preload("res://scripts/character_voice.gd")
const Plain:=preload("res://scripts/plain_speech.gd")
const DV:=preload("res://scripts/deal_value.gd")
const Deals:=preload("res://scripts/envoy_deals.gd")

const MAX_COMPLETION_TOKENS:=420
const TIMEOUT_SECONDS:=12.0
const HEADLINE_MAX:=70
const STAKES_MAX:=200
const META_PATTERN:="(?i)\\b(video ?games?|gameplay|game mechanics?|mechanics|players?|buttons?|json|ai|llm|language models?|prompts?|menus?|candidates?|schema)\\b"
## Capitalised words anyone may use besides the names in the facts.
const COMMON_CAPS:=["I","The","A","An","Our","Their","They","We","You","Your","It","Its","He","She","His","Her","Great","One","If","But","And","Now","This","That","Without","With","Before","After","When","Since","Every","No","Food","Timber","Stone","Clay","Fiber","Plants"]

const SYSTEM_PROMPT:="""You decide what a foreign envoy comes to ask of a god-ruler, in a fictional early history. You are given the sending people's real situation and a short list of CANDIDATE requests; each is true and possible. Choose the one this ruler would most plausibly send now: the most pressing need, the ruler's temper, and what they have already asked lately (prefer business unlike RECENT). Never invent new business, amounts, people or places.

Then write, plainly and concretely:
- headline: 3 to 9 lowercase words, a verb phrase that follows the people's name on a herald's banner (e.g. "asks to borrow food against the harvest", "wants the ford for its hunters").
- stakes: one sentence (at most 25 words) saying why this matters to them now, from the facts given. Use only names and numbers that appear in the facts.

Plain speech: no proverbs, maxims, riddles or poetic compounds. The world has only what the WORLD line lists; nothing else may appear, even as metaphor. Never mention games, systems, choices, candidates or lists.

Reply with JSON only: {"pick":"<candidate id>","headline":"...","stakes":"..."}"""

# --------------------------------------------------------------------------

static func wants(audience:Dictionary)->bool:
	## A newly arrived envoy, not yet heard, whose business has not been chosen.
	if audience.is_empty() or String(audience.get("origin",""))!="foreign" or String(audience.get("status",""))!="waiting": return false
	if audience.get("request_ai") is Dictionary or not (audience.get("lines",[]) as Array).is_empty(): return false
	var type:=Hall._situation_type(audience)
	if type in ["peace_feeler","war_support"] or (Hall._situation(audience) as Dictionary).has("arc"): return false
	return not (audience.get("request_alts",[]) as Array).is_empty() or bool(Hall._requests().call("handles",type))

static func mark(audience:Dictionary,mode:String,reason:String="",extra:Dictionary={})->void:
	var record:={"mode":mode,"reason":reason.substr(0,120),"day":int(GameState.elapsed_days)}
	record.merge(extra,true)
	audience["request_ai"]=record

static func candidates(audience:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[{"id":"c0","kind":String(audience.get("kind","")),"situation":Hall._situation(audience)}]
	var index:=1
	for alt in audience.get("request_alts",[]):
		if not alt is Dictionary: continue
		out.append({"id":"c%d" % index,"kind":String(alt.get("kind","")),"situation":alt.get("situation",{})})
		index+=1
	return out

static func _words(value:float,bands:Array)->String:
	for band in bands:
		if value<float(band[0]): return String(band[1])
	return String(bands[-1][1])

static func facts(audience:Dictionary,only:int=-1)->Dictionary:
	## Everything the model may draw on, as short plain lines, plus the names
	## and numbers its words may use.
	var civ_id:=String(audience.get("civ_id",""))
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
	var leader:=ForeignDiplomacy.leader(civ_id)
	var name:=String(audience.get("civ_name",civ.get("name",civ_id)))
	var tags:=CV.era_tags(civ_id)
	var wars:PackedStringArray=PackedStringArray()
	for id in Hall._third_wars(civ): wars.append(Hall._civ_name(String(id)))
	var lines:PackedStringArray=PackedStringArray()
	lines.append("WORLD: "+CV.world_line(tags))
	lines.append("THEM: %s, about %d people. Food: %s (about %d days). Health: %s. They are %s. %s" % [name,roundi(float(civ.get("population",0))),
		_words(float(civ.get("food_days",30)),[[12,"going hungry"],[22,"short"],[60,"fed"],[1e9,"plenty"]]),roundi(float(civ.get("food_days",30))),
		_words(float(civ.get("health",0.7)),[[0.45,"sickness everywhere"],[0.6,"many sick"],[1e9,"mostly well"]]),
		{"fortification":"raising defenses","expansion":"pushing out for new land","inquiry":"eager to learn","commerce":"busy with trade","growth":"growing fast","sustenance":"feeding themselves first"}.get(String(civ.get("strategy","")),"going about their lives"),
		("At war with %s." % ", ".join(wars)) if not wars.is_empty() else "At peace with their neighbours."])
	lines.append("TOWARD THE GOD'S PEOPLE: %s; the border is %s." % [_words(float(relation.get("opinion",0.0)),[[-0.4,"hostile"],[-0.1,"cool"],[0.15,"wary but civil"],[0.4,"friendly"],[1e9,"warm"]]),
		_words(float(relation.get("border_tension",0.0)),[[0.2,"quiet"],[0.45,"watchful"],[0.7,"tense"],[1e9,"close to violence"]])])
	var rivals:=load("res://scripts/rival_rulers.gd") as GDScript
	var ruler:=String(rivals.call("epithet",civ_id)) if rivals!=null else String(leader.get("name",""))
	if ruler!="": lines.append("RULER: %s (%s)." % [ruler,String(leader.get("temperament","")).to_lower()])
	var recent:PackedStringArray=PackedStringArray()
	for r in Hall._requests().call("recent_kinds",6):
		if String((r as Dictionary).get("a",""))==String(audience.get("id","")): continue
		recent.append("%s from %s, %d days ago" % [String(r.t).replace("_"," "),Hall._civ_name(String(r.c)),int(GameState.elapsed_days)-int(r.d)])
	lines.append("RECENT envoy business in this hall: %s." % ("; ".join(recent) if not recent.is_empty() else "none"))
	var sources:PackedStringArray=PackedStringArray([name,ruler,String(leader.get("name","")),String(GameState.settlement_name)])
	var numbers:={}
	for n in [roundi(float(civ.get("population",0))),roundi(float(civ.get("food_days",30)))]: numbers[str(n)]=true
	lines.append("CANDIDATES:")
	var listed:=candidates(audience)
	for index in listed.size():
		var s:Dictionary=listed[index].situation
		lines.append("%s [%s]: %s" % [String(listed[index].id),String(s.get("type","")).replace("_"," "),String(s.get("summary",""))])
		if only<0 or only==index: sources.append(String(s.get("summary","")))
	var number:=RegEx.new(); number.compile("\\d+")
	for m in number.search_all(" ".join(sources)): numbers[m.get_string()]=true
	var names:={}
	var cap:=RegEx.new(); cap.compile("\\b[A-Z][a-z'-]+\\b")
	for m in cap.search_all(" ".join(sources)): names[m.get_string()]=true
	for civ_entry in WorldSimulation.world.civilizations:
		for part in String(civ_entry.get("name","")).split(" ",false): names[part]=true
	var fact_tags:=CV.lexicon_tags_in(" ".join(sources))
	for t in tags:
		if not fact_tags.has(t): fact_tags.append(t)
	return {"text":"\n".join(lines),"numbers":numbers,"names":names,"tags":fact_tags}

static func response_format(ids:Array)->Dictionary:
	return {"type":"json_schema","json_schema":{"name":"envoy_request","strict":true,"schema":{"type":"object","additionalProperties":false,"required":["pick","headline","stakes"],
		"properties":{"pick":{"type":"string","enum":ids},"headline":{"type":"string"},"stakes":{"type":"string"}}}}}

static func build_payload(audience:Dictionary,config:Dictionary)->Dictionary:
	var f:=facts(audience)
	var ids:Array=[]
	for c in candidates(audience): ids.append(String(c.id))
	var payload:={"model":String(config.get("model","")),"max_completion_tokens":MAX_COMPLETION_TOKENS,"messages":[
		{"role":"system","content":SYSTEM_PROMPT},{"role":"user","content":String(f.text)}]}
	if "api.openai.com" in String(config.get("endpoint","")).to_lower(): payload["reasoning_effort"]="low"
	if bool(config.get("structured_output",false)): payload["response_format"]=response_format(ids)
	return payload

static func parse(body:PackedByteArray)->Dictionary:
	var parser:=JSON.new()
	if parser.parse(body.get_string_from_utf8())!=OK or not parser.data is Dictionary: return {}
	var envelope:Dictionary=parser.data
	if envelope.has("pick"): return envelope
	var content:=""
	var choices:Variant=envelope.get("choices",[])
	if choices is Array and not (choices as Array).is_empty() and choices[0] is Dictionary:
		var message:Variant=(choices[0] as Dictionary).get("message",{})
		if message is Dictionary: content=PronouncementInterpreter._content_text((message as Dictionary).get("content",""))
	if content.is_empty(): content=PronouncementInterpreter._content_text(envelope.get("output_text",""))
	var first:=content.find("{"); var last:=content.rfind("}")
	if first<0 or last<=first: return {}
	var inner:=JSON.new()
	if inner.parse(content.substr(first,last-first+1))!=OK or not inner.data is Dictionary: return {}
	return inner.data

static func text_problem(text:String,f:Dictionary,max_len:int,min_words:int)->String:
	## "" when the words may stand; otherwise why not.
	var clean:=text.strip_edges()
	if clean.length()>max_len: return "too long"
	if clean.split(" ",false).size()<min_words: return "too short"
	var meta:=RegEx.new(); meta.compile(META_PATTERN)
	if meta.search(clean)!=null: return "speaks of the machinery"
	if Plain.is_maxim(clean): return "a maxim"
	if not CV.permits(clean,f.get("tags",[])): return "outside what this people knows"
	var number:=RegEx.new(); number.compile("\\d+")
	for m in number.search_all(clean):
		if not (f.numbers as Dictionary).has(m.get_string()): return "a number not in the facts"
	var cap:=RegEx.new(); cap.compile("(?<![.!?]\\s)(?<!^)\\b[A-Z][a-z'-]+\\b")
	for m in cap.search_all(clean):
		var word:=m.get_string()
		if not (f.names as Dictionary).has(word) and not word in COMMON_CAPS: return "a name not in the facts (%s)" % word
	return ""

static func validate(parsed:Dictionary,audience:Dictionary)->Dictionary:
	## {pick_index, headline, stakes} or {error}.
	if parsed.is_empty(): return {"error":"reply was not the expected JSON"}
	var ids:Array=[]
	for c in candidates(audience): ids.append(String(c.id))
	var pick:=String(parsed.get("pick","")).strip_edges()
	if not pick in ids: return {"error":"picked an unknown candidate"}
	var f:=facts(audience,ids.find(pick))
	var headline:=String(parsed.get("headline","")).strip_edges().trim_suffix(".")
	headline=headline.substr(0,1).to_lower()+headline.substr(1)
	var stakes:=String(parsed.get("stakes","")).strip_edges()
	var out:={"pick_index":ids.find(pick)}
	# A bad phrase costs only the phrase; the choice itself still stands.
	if text_problem(headline,f,HEADLINE_MAX,3)=="" and headline.split(" ",false).size()<=10: out["headline"]=headline
	if text_problem(stakes,f,STAKES_MAX,4)=="":
		if not stakes.ends_with(".") and not stakes.ends_with("!"): stakes+="."
		out["stakes"]=Hall._cap_first(stakes)
	return out

static func apply(audience:Dictionary,parsed:Dictionary,model:String)->Dictionary:
	## Applies a validated choice; returns {ok, swapped, reason}.
	if not wants(audience): return {"ok":false,"swapped":false,"reason":"the envoy has already spoken"}
	var checked:=validate(parsed,audience)
	if checked.has("error"):
		mark(audience,"fallback",String(checked.error))
		return {"ok":false,"swapped":false,"reason":String(checked.error)}
	var index:=int(checked.pick_index)
	var swapped:=false
	if index>0:
		swapped=_swap(audience,index-1)
		if not swapped:
			mark(audience,"fallback","the chosen business could not be taken up")
			return {"ok":false,"swapped":false,"reason":"the chosen business could not be taken up"}
	var situation:=Hall._situation(audience)
	var ai:={"model":model.substr(0,60)}
	if checked.has("headline"): situation["headline"]=String(checked.headline); ai["headline"]=String(checked.headline)
	if checked.has("stakes"):
		ai["stakes"]=String(checked.stakes)
		situation["summary"]=(String(situation.get("summary",""))+" "+String(checked.stakes)).strip_edges().substr(0,600)
	situation["ai"]=ai
	audience["situation"]=situation
	mark(audience,"live","",{"pick":index,"swapped":swapped})
	_refresh_ledger(audience)
	return {"ok":true,"swapped":swapped,"reason":""}

static func _swap(audience:Dictionary,alt_index:int)->bool:
	var alts:Array=audience.get("request_alts",[])
	if alt_index<0 or alt_index>=alts.size() or not alts[alt_index] is Dictionary: return false
	var alt:Dictionary=alts[alt_index]
	var kind:=String(alt.get("kind",""))
	if not kind in Hall.KINDS: return false
	var old_situation:=Hall._situation(audience)
	var old:={"kind":String(audience.kind),"situation":old_situation.duplicate(true),"terms":(audience.get("terms",{}) as Dictionary).duplicate(),"news":(audience.get("news",{}) as Dictionary).duplicate()}
	(old.situation as Dictionary).erase("occasion")
	var situation:Dictionary=(alt.get("situation",{}) as Dictionary).duplicate(true)
	var occasion:Dictionary=old_situation.get("occasion",{}) if old_situation.get("occasion") is Dictionary else {}
	situation["occasion"]=occasion.duplicate(true)
	audience["kind"]=kind
	audience["terms"]=(alt.get("terms",{}) as Dictionary).duplicate() if alt.get("terms") is Dictionary else {}
	audience["news"]=(alt.get("news",{}) as Dictionary).duplicate() if alt.get("news") is Dictionary else {}
	audience["situation"]=situation
	audience.erase("hidden")
	alts[alt_index]=old
	var civ_id:=String(audience.civ_id)
	var fresh:Dictionary=Hall._envoy(civ_id,String(audience.id),kind,ForeignDiplomacy.leader(civ_id))
	(audience.speaker as Dictionary)["title"]=String(fresh.get("title",(audience.speaker as Dictionary).get("title","")))
	# The ruler behind the envoy dresses the new business (string, bluff).
	Hall._rivals().call("dress",audience,{"type":String(occasion.get("type","")),"key":"revised","data":{"text":String(occasion.get("text",""))}},int(GameState.elapsed_days))
	(load("res://scripts/envoy_aftermath.gd") as GDScript).call("dress",audience)
	Hall._requests().call("note_arrival",audience)
	return true

# --------------------------------------------------------------------------
# The god's typed answer to a request (online): one cheap call reads the words
# onto the same answers the cards offer, with at most a share and a repayment
# good; envoy_requests.gd's own reading goes first, and any failure leaves the
# words as plain conversation.
# --------------------------------------------------------------------------

const ANSWER_MAX_TOKENS:=200
const ANSWER_CONFIDENCE:=0.6
const ANSWER_SYSTEM:="""A god-ruler has answered a foreign envoy's request in their own words. Decide which of the listed ANSWERS those words give.
- answer: the id of the answer the words clearly choose. If the words ask a question, make conversation, or do not settle the request, answer "talk".
- share: if the ruler gives only part of the goods named in the answer, the fraction given (0.1 to 1); otherwise 1.
- repay: if the ruler asks to be repaid or paid in a different good (for a counter, the good asked instead), that good; otherwise "none".
- amount: if the ruler names how much of a good they want for a counter, that number; otherwise 0.
- confidence: 0 to 1, how sure you are.
Reply with JSON only: {"answer":"...","share":1,"repay":"none","amount":0,"confidence":0.9}"""

static func answer_ids(audience:Dictionary)->Array:
	var ids:Array=[]
	for option in Hall._requests().call("options",audience):
		if bool((option as Dictionary).get("enabled",true)): ids.append(String(option.id))
	# Counters may be asked in words where the card offers none (envoy_deals.gd).
	var type:=Hall._situation_type(audience)
	if type in Deals.COUNTER_GOOD and not "counter_good" in ids: ids.append("counter_good")
	if type in Deals.COUNTER_MORE and not "counter_more" in ids: ids.append("counter_more")
	return ids

static func answer_payload(audience:Dictionary,text:String,config:Dictionary)->Dictionary:
	var situation:=Hall._situation(audience)
	var lines:PackedStringArray=PackedStringArray()
	lines.append("REQUEST from %s (%s): %s" % [String(audience.get("civ_name","")),String(situation.get("headline","")),String(situation.get("summary","")).substr(0,500)])
	lines.append("ANSWERS:")
	for option in Hall._requests().call("options",audience):
		if bool((option as Dictionary).get("enabled",true)): lines.append("- %s: %s. %s" % [String(option.id),String(option.label),String(option.sub)])
	var listed:=answer_ids(audience)
	var shown:=PackedStringArray()
	for option in Hall._requests().call("options",audience): shown.append(String(option.id))
	if "counter_good" in listed and not "counter_good" in shown: lines.append("- counter_good: ask to be paid in another good instead (name it in repay, and the amount if one is named).")
	if "counter_more" in listed and not "counter_more" in shown: lines.append("- counter_more: ask for more of the same payment (the amount if one is named).")
	lines.append("- talk: the words do not settle the request.")
	lines.append("GOODS: "+", ".join(PackedStringArray(DV.GOODS)))
	lines.append("THE RULER SAID: <<%s>>" % text.strip_edges().replace("\n"," ").substr(0,400))
	var ids:=answer_ids(audience)+["talk"]
	var payload:={"model":String(config.get("model","")),"max_completion_tokens":ANSWER_MAX_TOKENS,"messages":[
		{"role":"system","content":ANSWER_SYSTEM},{"role":"user","content":"\n".join(lines)}]}
	if "api.openai.com" in String(config.get("endpoint","")).to_lower(): payload["reasoning_effort"]="low"
	if bool(config.get("structured_output",false)):
		payload["response_format"]={"type":"json_schema","json_schema":{"name":"envoy_answer","strict":true,"schema":{"type":"object","additionalProperties":false,"required":["answer","share","repay","amount","confidence"],
			"properties":{"answer":{"type":"string","enum":ids},"share":{"type":"number"},"repay":{"type":"string","enum":(DV.GOODS as Array)+["none"]},"amount":{"type":"number"},"confidence":{"type":"number"}}}}}
	return payload

static func read_answer(parsed:Dictionary,audience:Dictionary)->Dictionary:
	## {option, share?, repay_res?} for a confident, valid reading; {} otherwise.
	if parsed.is_empty(): return {}
	var answer:=String(parsed.get("answer","")).strip_edges()
	if not answer in answer_ids(audience): return {}
	var confidence:Variant=parsed.get("confidence",0.0)
	if not (confidence is float or confidence is int) or float(confidence)<ANSWER_CONFIDENCE: return {}
	var out:={"option":answer}
	var share:Variant=parsed.get("share",1.0)
	if (share is float or share is int) and float(share)>0.0 and float(share)<0.99 and answer in ["accept","gift"]: out["share"]=clampf(float(share),0.1,1.0)
	var repay:=String(parsed.get("repay","none"))
	if repay in DV.GOODS and Hall._situation_type(audience)=="food_loan" and answer in ["accept","partial"] and repay!="Food": out["repay_res"]=repay
	# A counter read from the god's words goes through the same rules as the
	# card's (envoy_deals.terms), checked again when it is answered.
	if answer.begins_with("counter_"):
		if repay in DV.GOODS: out["ask_res"]=repay
		var amount:Variant=parsed.get("amount",0)
		if (amount is float or amount is int) and float(amount)>0.0: out["ask_amt"]=float(amount)
	return out

static func _refresh_ledger(audience:Dictionary)->void:
	for entry in Hall.state().ledger:
		if entry is Dictionary and String(entry.get("audience_id",""))==String(audience.get("id","")):
			entry["kind"]=String(audience.kind)
			entry["situation"]=Hall._situation_type(audience)
			entry["ask"]=Hall._ask_key(audience)
			entry["summary"]=Hall._ledger_summary(audience)
			return
