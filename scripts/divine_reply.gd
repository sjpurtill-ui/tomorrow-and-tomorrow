extends RefCounted
## How an official first answers the god's order: an opening in their own
## lifelong manner or public demeanour, and the order quoted back in their
## voice. Deterministic per order text, so the same words always get the same
## answer, while different orders get different ones. Static; preload.

const Lines:=preload("res://scripts/court_lives_lines.gd")
const CV:=preload("res://scripts/character_voice.gd")

static func _hash(salt:String,part:String)->int:
	return posmod(hash("%d|%s|%s" % [int(GameState.world_seed),part,salt]),2147483647)

static func _choose(options:Array,salt:String,part:String)->String:
	if options.is_empty(): return ""
	return String(options[_hash(salt,part)%options.size()])

static func _model(leader:Dictionary)->String:
	if leader.is_empty(): return ""
	return String(CV.for_person(leader).get("model",""))

static func opening(leader:Dictionary,disposition:String,salt:String)->String:
	## One short sentence: the speaker's manner or their demeanour today.
	var own:Array=(Lines.BANKS.get(_model(leader),{}) as Dictionary).get("open",[])
	var mood:Array=Lines.DISPOSITION_OPEN.get(disposition,Lines.DISPOSITION_OPEN.pragmatic)
	var tags:Array=CV.era_tags("player")
	var pool:Array=[]
	for line in own+mood:
		if CV.permits(String(line),tags): pool.append(line)
	return _choose(pool,salt,"open")

static func gist(text:String)->String:
	var clean:=text.strip_edges().trim_suffix(".").trim_suffix("!").strip_edges()
	for lead in ["i order that ","i order ","i command that ","i command ","i want you to ","you will ","please "]:
		if clean.to_lower().begins_with(lead): clean=clean.substr(lead.length())
	return clean

static func quote(leader:Dictionary,text:String,salt:String)->String:
	## The order said back in the speaker's own words, or "" when too long.
	var said:=gist(text)
	if said.length()<3 or said.length()>90 or said.contains("\n"): return ""
	var low:=said.substr(0,1).to_lower()+said.substr(1) if not said.begins_with("I ") else said
	var cap:=said.substr(0,1).to_upper()+said.substr(1)
	var own:Array=(Lines.BANKS.get(_model(leader),{}) as Dictionary).get("quote",[])
	var pool:Array=own+(Lines.GENERIC.quote as Array)
	var template:=_choose(pool,salt,"quote")
	last_frame="quote:%d" % pool.find(template)
	var out:=template.replace("{order}",cap).replace("{order_low}",low).replace("{order_cap}",cap)
	return out.substr(0,1).to_upper()+out.substr(1)

## How a reply first takes up the order. Said back word for word only now
## and then; more often by what it is ("The feast, then."), by who starts it
## and when ("Tesk and I will start on the ditch at first light."), or not at
## all, the speaker going straight to what they will do.
const TAKE_UP:=[
	"{topic_cap}, then.","{topic_cap} it is.","You want {topic}. Good.","{topic_cap}. Yes.","{topic_cap}: I understand what you want.",
]
const WHO_WHEN:=[
	"{helper} and I will start on {topic} {when}.","I will have {helper} on {topic} {when}.","{topic_cap} starts {when}; {helper} will help me.",
]
const WHEN:=["at first light","tomorrow","this evening","after the next meal","before the moon turns","today"]
## The frame the last reply used (probes count variety).
static var last_frame:=""

static func acknowledge(leader:Dictionary,text:String,salt:String,topic_words:String)->String:
	## The first words about the order, or "" to go straight to the work.
	var roll:=_hash(salt,"frame")%100
	var cap:=topic_words.substr(0,1).to_upper()+topic_words.substr(1)
	if topic_words=="" or topic_words=="the work": roll=mini(roll,24)
	if roll<25:
		var quoted:=quote(leader,text,salt)
		if quoted!="": return quoted
		last_frame="none"
		return ""
	if roll<50:
		var i:=_hash(salt,"take")%TAKE_UP.size()
		last_frame="take:%d" % i
		return String(TAKE_UP[i]).replace("{topic_cap}",cap).replace("{topic}",topic_words)
	if roll<80:
		var helper:=_helper(leader,salt)
		var j:=_hash(salt,"who")%WHO_WHEN.size()
		var when:=String(WHEN[_hash(salt,"when")%WHEN.size()])
		last_frame="who:%d" % j
		var line:=String(WHO_WHEN[j]).replace("{helper}",helper).replace("{topic_cap}",cap).replace("{topic}",topic_words).replace("{when}",when)
		return line.substr(0,1).to_upper()+line.substr(1)
	last_frame="none"
	return ""

static func _helper(leader:Dictionary,salt:String)->String:
	## Someone the speaker will start the work with: another of the court.
	var names:Array[String]=[]
	for person in (load("res://scripts/audience_hall.gd") as GDScript).call("_officials"):
		if int(person.get("person_id",0))!=int(leader.get("person_id",-1)): names.append(String(person.get("name","")).get_slice(" ",0))
	if names.is_empty(): return "the young ones"
	return names[_hash(salt,"helper")%names.size()]

static func topic(policies:Array,text:String)->String:
	## What the reply calls the order: "the feast", "the rain-calling", or the
	## catalog work by name.
	for policy_variant in policies:
		if not policy_variant is Dictionary: continue
		var policy:Dictionary=policy_variant
		var plan:Dictionary=(policy.get("directive_parameters",{}) as Dictionary).get("custom_plan",{}) if policy.get("directive_parameters") is Dictionary else {}
		var natures:Array=plan.get("natures",[])
		if natures.has("miracle") or float(plan.get("feasibility",1.0))<0.2:
			var wish:=String(load("res://scripts/court_lives.gd").call("_wish_of",text))
			return String(Lines.MIRACLE_TOPICS.get(wish,Lines.MIRACLE_TOPICS.any))
		for nature in natures:
			if Lines.TOPIC_BY_NATURE.has(String(nature)): return String(Lines.TOPIC_BY_NATURE[String(nature)])
		var id:=String(policy.get("id",""))
		if id!="" and id!="custom_directive": return GovernmentPolicyCatalog.display_name(id).to_lower()
	return "the work"

static func _topic_fill(template:String,topic_words:String)->String:
	var cap:=topic_words.substr(0,1).to_upper()+topic_words.substr(1)
	return template.replace("{topic_cap}",cap).replace("{topic}",topic_words)

static func capacity(band:String,salt:String,fallback:String,topic_words:String="")->String:
	if salt=="" or topic_words=="": return fallback
	return _topic_fill(_choose(Lines.CAPACITY.get(band,[fallback]),salt,"capacity"),topic_words)

static func report_back(salt:String,when:String,topic_words:String="")->String:
	if salt=="" or topic_words=="": return "This is underway. I will report back around %s with what actually happened." % when
	return _topic_fill(_choose(Lines.REPORT_BACK,salt,"report"),topic_words).replace("{when}",when)

static func leads_with_opening(salt:String)->bool:
	## About a fifth of replies that take up the order also open in the
	## speaker's manner; replies that go straight to the work always do.
	return _hash(salt,"lead")%10<2

static func miracle_body(summary:String,act:String,risk:String)->String:
	## "No one has ever done such a thing, but …": a rite fitted to the wish.
	var wish:=String(load("res://scripts/custom_directive.gd").call("miracle_kind",summary))
	var acts:Array=Lines.MIRACLE_ACTS.get(wish,Lines.MIRACLE_ACTS.any)
	var chosen_act:=_choose(acts,summary,"miracle_act") if act=="try it, with every rite we know" else "I will %s" % act
	var lead:=_choose(Lines.MIRACLE_LEADS,summary,"miracle_lead")
	var chosen_risk:=_choose(Lines.MIRACLE_RISKS,summary,"miracle_risk") if risk.begins_with("If nothing comes of it") else (risk.trim_suffix(".")+"." if risk!="" else "")
	var act_text:=chosen_act if chosen_act.begins_with("I ") else chosen_act.substr(0,1).to_lower()+chosen_act.substr(1)
	return ("%s %s. %s" % [lead,act_text,chosen_risk]).strip_edges()
