extends RefCounted
## Court commands: the god's word is law.
##
## Everything the ruler types in the Court (a summoned official, an envoy, the
## court at rest once someone answers) is read here as a speech act: question,
## statement, command, threat or blessing. Commands name who must act (the
## actor: "Ansel", "you", the guards by default) and on whom ("him", "the war
## leader", "Zuri"), resolved against the people actually present or known.
##
## The ENGINE decides first. Obedience comes from the actor's love and dread
## of the god (divine_regard.gd): almost always they obey (the frightened at
## once, the loving with reluctance when the act is cruel); a loving, gentle
## hand may hesitate once and plead, and the god's insistence ("I DEMAND IT")
## settles it; a genuine refusal is rare (dread nearly gone, courage high,
## pride or resentment high) and always has consequences: they flee, or the
## court seizes them and they kneel bound before you. The act itself goes
## through the real systems (execution/exile/imprisonment through
## GovernmentPeopleSystem, goods through the real stores, scouts and envoys
## through CivilizationSystem, every other order through the civic pipeline
## or the custom-directive seam below). The voice is then told what happened
## and only describes it.
##
## Any other order goes through custom_order(): the civic pipeline for a
## settlement leader or a catalog policy, otherwise the universal
## custom-directive path (custom_directive.gd). `custom_directive_handler`
## (func(text, context)->{ok, outcome}) may override it.
## Static helpers; reference with preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const CV:=preload("res://scripts/character_voice.gd")
const CustomDirective:=preload("res://scripts/custom_directive.gd")

const ACTS:=["question","statement","command","threat","blessing"]
const VERBS:=["kill","exile","detain","penance","terrify","bless","boon","raise","demote","appoint","give","take","send","order"]
## Acts done to a person by a person: the ones a gentle hand balks at.
const CRUEL:=["kill","detain","exile"]
const LIVE_CONFIDENCE:=0.6
const PENDING_DAYS:=2

static var custom_directive_handler:Callable=Callable()

# --------------------------------------------------------------------------
# Lexicon
# --------------------------------------------------------------------------

const INSIST_PATTERN:="(?i)^\\s*(i demand it|i command it|i insist|do it|do it now|now|obey|obey me|obey your god|you heard me|did you not hear me|do as i (say|said|command)|i said do it|i said (kill|strike|do)|i will be obeyed|i gave you an order|do what i (say|said|command)|you will do it|at once|go on|carry it out)\\b[\\s!.]*$"
## [verb, pattern]; checked in order. Patterns match the verb phrase only.
const VERB_PATTERNS:=[
	["kill","(?i)\\b(kill|kills|slay|slaughter|execute|behead|murder|butcher|stab|strangle|throttle|hang|smite|gut|decapitate|strike [\\w' ]{0,30}?down|cut [\\w' ]{0,24}?(throat|down)|put [\\w' ]{0,30}?to death|take (his|her|their) (head|life)|end (his|her|their) (life|days)|break (his|her|their) neck|off with (his|her|their) head|death to|make (him|her|them) (die|bleed)|spill (his|her|their) blood|bleed (him|her|them))\\b"],
	["exile","(?i)\\b(exile|banish|expel|cast [\\w' ]{0,30}?out|drive [\\w' ]{0,30}?out|throw [\\w' ]{0,30}?out|send [\\w' ]{0,30}?away (forever|for good|from the realm)|out of my (sight|realm|lands) forever)\\b"],
	["detain","(?i)\\b(imprison|jail|gaol|lock [\\w' ]{0,30}?up|bind (him|her|them|(?-i:[A-Z])\\w+)|chain|shackle|arrest|detain|seize (him|her|them)|put [\\w' ]{0,30}?under guard|take [\\w' ]{0,24}?prisoner|throw [\\w' ]{0,30}?in(to)? the pit)\\b"],
	["penance","(?i)\\b(penance|atone|repent|keep vigil)\\b"],
	["demote","(?i)\\b(demote|dismiss|strip [\\w' ]{0,30}?of (his|her|their)? ?(office|rank|post|title)|remove [\\w' ]{0,30}?from (office|post|rank)|relieve [\\w' ]{0,30}?of (his|her|their)? ?(office|duties|post))\\b"],
	["appoint","(?i)\\b(appoint|install|make [\\w' ]{1,30}? (our|the|my|your) new |make [\\w' ]{1,30}? (our|the|my) |name [\\w' ]{1,30}? (as )?(our|the|my) )"],
	["raise","\\b(?i:(promote|exalt|elevate|raise [\\w' ]{0,30}?up))\\b|\\b(?i:honou?r) ((?i:him|her|them)|[A-Z]\\w+)\\b"],
	["boon","(?i)\\b(reward|boon)\\b"],
	["bless","\\b(?i:bless) ((?i:him|her|them)|[A-Z]\\w+)\\b"],
	["send","(?i)\\b((send|dispatch) [\\w' ]{0,40}?(to scout|scouting|scouts|to explore|exploring|outriders|an envoy|envoys|a messenger|messengers|an embassy|to (?-i:[A-Z])\\w+)|go (and )?(scout|explore)|scout the|explore the)\\b"],
]
const GIVE_PATTERN:="(?i)\\b(give|hand|grant|bestow|send|bring)\\b"
const TAKE_PATTERN:="(?i)\\b(take|seize|confiscate|strip)\\b"
const ORDER_LEADS:=["i order that ","i order ","i command that ","i command ","i want you to ","i need you to ","i demand that ","i demand ","i decree that ","i decree ","you will ","you shall ","you must ","see that ","see to it that ","make sure ","let ","have "]
const IMPERATIVES:=["go","come","bring","fetch","make","dig","plant","hunt","gather","build","raise","feed","ration","guard","watch","train","clear","move","prepare","ready","double","halve","cut","burn","tell","find","get","take","keep","hold","open","close","set","call","summon","march","attack","defend","fortify","scout","sow","reap","harvest","store","share","stop","start","begin","finish","double","count","mend","repair","clean","carry","lead","muster","warn","teach","show","search","track","herd","fish","cook","dry","smoke","weave","fire","bake"]
const RESOURCE_WORDS:={"food":"Food","meat":"Food","grain":"Food","provisions":"Food","rations":"Food","timber":"Timber","wood":"Timber","logs":"Timber","stone":"Stone","stones":"Stone","clay":"Clay","fiber":"Fiber Plants","fibre":"Fiber Plants","fibers":"Fiber Plants","reeds":"Fiber Plants","flax":"Fiber Plants"}
const NUMBER_WORDS:={"a dozen":12,"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,"eleven":11,"twelve":12,"fifteen":15,"twenty":20,"thirty":30,"forty":40,"fifty":50,"sixty":60,"a hundred":100,"hundred":100}
const OFFICE_WORDS:={"war leader":"Marshal","warleader":"Marshal","marshal":"Marshal","watch captain":"Marshal","pathfinder":"ChiefScout","chief scout":"ChiefScout","chief of scouts":"ChiefScout","hearth chief":"Steward","steward":"Steward","keeper of stores":"Quartermaster","quartermaster":"Quartermaster","lore keeper":"Scholar","scholar":"Scholar","messenger":"Envoy"}
const PRONOUNS:=["himself","herself","themselves","yourself","him","her","them","he","she","they","you","this one","that one","the traitor","the wretch","this wretch","the fool","this fool","that fool","the dog","this dog","that dog","the coward","this coward"]
const HEADINGS:=["northeast","northwest","southeast","southwest","north","south","east","west"]
const REFUSAL_PATTERN:="(?i)\\b(i (will|shall) not (do|kill|fight|strike|harm|hurt|obey|lift|raise|touch|slay|bind|cast|take|go|carry)|i won't (do|kill|fight|strike|harm|hurt|obey|go)|i refuse|i cannot do|i can't do|i will never|never will i|not by my hand|find another hand|another hand|give the order to another|ask another)\\b"

# --------------------------------------------------------------------------
# Speech acts
# --------------------------------------------------------------------------

static func _re(pattern:String)->RegEx:
	var re:=RegEx.new(); re.compile(pattern)
	return re

static func classify(text:String)->Dictionary:
	## Offline reading of the ruler's words. Always returns
	## {act, verb, verb_at, confidence, insist, resource, amount, heading, order}.
	var clean:=text.strip_edges()
	var out:={"act":"statement","verb":"none","verb_at":-1,"verb_end":-1,"confidence":0.3,"insist":false,"resource":"","amount":0.0,"heading":"","text":clean}
	if clean.is_empty(): return out
	var lower:=clean.to_lower()
	if _re(INSIST_PATTERN).search(clean)!=null:
		out.act="command"; out.insist=true; out.confidence=0.8
		return out
	var question:=clean.ends_with("?")
	if not question:
		for lead:String in ["what","why","how","who","whom","where","when","tell me"]:
			if lower.begins_with(lead+" "): question=true; break
	if question:
		out.act="question"; out.confidence=0.8
		return out
	var resource:=_resource_in(lower)
	out.resource=resource
	out.amount=_amount_in(lower)
	for h:String in HEADINGS:
		if _re("\\b%s\\b" % h).search(lower)!=null: out.heading=h; break
	# Goods first: "give Zuri 20 food", "take their stone".
	if resource!="":
		var give:=_re(GIVE_PATTERN).search(clean)
		if give!=null and not " from " in lower:
			return _verb(out,"give",give)
		var take:=_re(TAKE_PATTERN).search(clean)
		if take!=null: return _verb(out,"take",take)
	for pair in VERB_PATTERNS:
		var m:=_re(String(pair[1])).search(clean)
		if m!=null: return _verb(out,String(pair[0]),m)
	var spoken:=DIVINE.intent(clean)
	if spoken=="terrify": out.act="threat"; out.verb="terrify"; out.confidence=0.8; return out
	if spoken in ["bless","raise_up"]: out.act="blessing"; out.verb="bless" if spoken=="bless" else "raise"; out.confidence=0.8; return out
	if _imperative(clean): out.act="command"; out.verb="order"; out.confidence=0.65; return out
	return out

static func _verb(out:Dictionary,verb:String,m:RegExMatch)->Dictionary:
	out.act="command"; out.verb=verb; out.verb_at=m.get_start(); out.verb_end=m.get_end(); out.confidence=0.85
	return out

static func _resource_in(lower:String)->String:
	for word:String in RESOURCE_WORDS:
		if _re("\\b%s\\b" % word).search(lower)!=null: return String(RESOURCE_WORDS[word])
	return ""

static func _amount_in(lower:String)->float:
	var m:=_re("\\b(\\d+(?:\\.\\d+)?)\\b").search(lower)
	if m!=null: return float(m.get_string(1))
	for word:String in NUMBER_WORDS:
		if _re("\\b%s\\b" % word).search(lower)!=null: return float(NUMBER_WORDS[word])
	return 0.0

static func _strip_leads(text:String)->String:
	var clean:=text.strip_edges()
	var lower:=clean.to_lower()
	for lead:String in ORDER_LEADS:
		if lower.begins_with(lead): return clean.substr(lead.length()).strip_edges()
	return clean

static func _imperative(text:String)->bool:
	var lower:=text.strip_edges().to_lower()
	for lead:String in ORDER_LEADS:
		if lower.begins_with(lead): return true
	# Drop a vocative ("Ansel, gather the hunters").
	var comma:=lower.find(",")
	if comma>0 and comma<28 and lower.substr(0,comma).split(" ",false).size()<=3: lower=lower.substr(comma+1).strip_edges()
	for lead:String in ORDER_LEADS:
		if lower.begins_with(lead): return true
	var words:=lower.split(" ",false)
	if words.is_empty(): return false
	var first:=String(words[0]).trim_suffix("!").trim_suffix(".").trim_suffix(",")
	return first in IMPERATIVES or first in PronouncementInterpreter.DIRECTIVE_VERBS

# --------------------------------------------------------------------------
# Who is here
# --------------------------------------------------------------------------

static func roster(audience:Dictionary)->Array[Dictionary]:
	## Everyone a reference may land on: the one before you, the court
	## present, every other official known, and an envoy's own person.
	var out:Array[Dictionary]=[]
	if audience.is_empty(): return out
	var id:=String(audience.get("id",""))
	var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker") is Dictionary else {}
	var speaker_pid:=int(speaker.get("person_id",0))
	var present:Dictionary={}
	for p:Dictionary in Hall.court(id): present[int(p.person_id)]=true
	if String(audience.get("origin",""))=="foreign":
		out.append({"key":"envoy","kind":"envoy","person_id":0,"figure_id":"","name":String(speaker.get("name","the envoy")),"title":"envoy","office_key":"","settlement_id":"","civ_id":String(audience.get("civ_id","")),"speaker":true,"present":true})
	elif speaker_pid<=0:
		var holder:Dictionary=Hall._matter_holder(audience)
		var figure:=String(holder.get("figure_id",""))
		if figure=="" and String(audience.get("holder_key","")).begins_with("figure:"): figure=String(audience.holder_key).trim_prefix("figure:")
		if figure!="":
			out.append({"key":"figure:"+figure,"kind":"figure","person_id":0,"figure_id":figure,"name":String(speaker.get("name","")),"title":String(speaker.get("title","")),"office_key":"","settlement_id":"","speaker":true,"present":true})
	for p:Dictionary in Hall._officials():
		var pid:=int(p.person_id)
		out.append({"key":"person:%d" % pid,"kind":"official","person_id":pid,"figure_id":"","name":String(p.get("name","")),"title":String(p.get("office_title","")),
			"office_key":String(p.get("office_key","")),"settlement_id":String(p.get("settlement_id","")),"speaker":pid==speaker_pid and speaker_pid>0,"present":pid==speaker_pid or present.has(pid)})
	return out

static func _entry(list:Array[Dictionary],key:String)->Dictionary:
	for e:Dictionary in list:
		if String(e.key)==key: return e
	return {}

static func _speaker_entry(list:Array[Dictionary])->Dictionary:
	for e:Dictionary in list:
		if bool(e.speaker): return e
	return {}

static func _name_keys(e:Dictionary)->Array[String]:
	var keys:Array[String]=[]
	# Given name, a one-word byname, or the whole epithet; never "who" or "the"
	# out of "Oren Who Found the Ford" (era_names.gd).
	keys.append_array(preload("res://scripts/era_names.gd").name_keys(String(e.name)))
	return keys

static func _title_keys(e:Dictionary)->Array[String]:
	var keys:Array[String]=[]
	var title:=String(e.get("title","")).to_lower().strip_edges()
	if title!="":
		keys.append(title)
		if " of " in title: keys.append(title.get_slice(" of ",0))
	for word:String in OFFICE_WORDS:
		if String(OFFICE_WORDS[word])==String(e.get("office_key","")): keys.append(word)
	if String(e.kind)=="envoy":
		for w:String in ["envoy","messenger","herald","emissary"]: keys.append(w)
	if String(e.kind)=="figure" and "war" in title:
		for w:String in ["war leader","general"]: keys.append(w)
	return keys

static func mentions(text:String,list:Array[Dictionary])->Array[Dictionary]:
	## Every reference to a person in the words, in order:
	## {at, end, key (entry key, "" for a pronoun), word, by:"name"|"title"|"pronoun"|"guards"|"god"}.
	var found:Array[Dictionary]=[]
	var taken:Dictionary={}
	var lower:=text.to_lower()
	for by:String in ["name","title"]:
		# Present people first, so a shared first name lands on who is here.
		var ordered:=list.duplicate()
		ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(bool(a.present))>int(bool(b.present)))
		for e:Dictionary in ordered:
			var keys:Array[String]=_name_keys(e) if by=="name" else _title_keys(e)
			keys.sort_custom(func(a:String,b:String)->bool:return a.length()>b.length())
			for k:String in keys:
				for m in _re("\\b%s\\b" % _escape(k)).search_all(lower):
					var at:=m.get_start()
					if _overlaps(taken,at,m.get_end()): continue
					for i in range(at,m.get_end()): taken[i]=true
					found.append({"at":at,"end":m.get_end(),"key":String(e.key),"word":k,"by":by})
	for m in _re("\\b(guards?|warriors|my (warriors|guards|spears))\\b").search_all(lower):
		if not _overlaps(taken,m.get_start(),m.get_end()): found.append({"at":m.get_start(),"end":m.get_end(),"key":"","word":m.get_string(),"by":"guards"})
	for p:String in PRONOUNS:
		for m in _re("\\b%s\\b" % _escape(p)).search_all(lower):
			if _overlaps(taken,m.get_start(),m.get_end()): continue
			for i in range(m.get_start(),m.get_end()): taken[i]=true
			found.append({"at":m.get_start(),"end":m.get_end(),"key":"","word":p,"by":"pronoun"})
	for m in _re("\\b(me|myself)\\b").search_all(lower):
		if not _overlaps(taken,m.get_start(),m.get_end()): found.append({"at":m.get_start(),"end":m.get_end(),"key":"","word":m.get_string(),"by":"god"})
	found.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.at)<int(b.at))
	return found

static func _escape(text:String)->String:
	var out:=""
	for c in text:
		out+=("\\"+c) if c in ".^$*+?()[]{}|\\-" else c
	return out

static func _overlaps(taken:Dictionary,from:int,to:int)->bool:
	for i in range(from,to):
		if taken.has(i): return true
	return false

static func _salient(audience:Dictionary,list:Array[Dictionary],exclude:String)->Dictionary:
	## Who "him"/"her"/"the traitor" means: the last person the god dealt with,
	## else the one standing before the god, else the last to speak.
	var focus:Dictionary=audience.get("command_focus",{}) if audience.get("command_focus") is Dictionary else {}
	var last:=_entry(list,String(focus.get("last_ref","")))
	if not last.is_empty() and String(last.key)!=exclude: return last
	var speaker:=_speaker_entry(list)
	if not speaker.is_empty() and String(speaker.key)!=exclude: return speaker
	var lines:Array=audience.get("lines",[])
	for i in range(lines.size()-1,-1,-1):
		var pid:=int((lines[i] as Dictionary).get("person_id",0))
		if pid<=0: continue
		var e:=_entry(list,"person:%d" % pid)
		if not e.is_empty() and String(e.key)!=exclude: return e
	return {}

static func resolve_ref(ref:String,audience:Dictionary,list:Array[Dictionary],actor_key:String="")->Dictionary:
	## A live classifier's reference ("Ansel", "him", "the war leader").
	var clean:=ref.strip_edges()
	if clean=="": return {}
	var lower:=clean.to_lower()
	if "before me" in lower or "in front of me" in lower or "before you" in lower:
		var speaker:=_speaker_entry(list)
		if not speaker.is_empty() and String(speaker.key)!=actor_key: return speaker
	var found:=mentions(clean,list)
	if not lower in ["me","myself","the god","god"]: found=found.filter(func(m:Dictionary)->bool:return String(m.by)!="god")
	if found.is_empty(): return _salient(audience,list,actor_key)
	return _land(found[0],audience,list,actor_key)

static func _land(m:Dictionary,audience:Dictionary,list:Array[Dictionary],actor_key:String)->Dictionary:
	var by:=String(m.by)
	if by in ["name","title"]: return _entry(list,String(m.key))
	if by=="pronoun":
		var word:=String(m.word)
		if word in ["yourself","himself","herself","themselves"] and actor_key!="": return _entry(list,actor_key)
		if word=="you":
			var speaker:=_speaker_entry(list)
			if not speaker.is_empty() and String(speaker.key)!=actor_key: return speaker
		return _salient(audience,list,actor_key)
	if by=="god": return {"key":"god","kind":"god","name":"the god"}
	return {}

# --------------------------------------------------------------------------
# Obedience: the engine decides, the voice only describes
# --------------------------------------------------------------------------

static func obedience(actor:Dictionary,verb:String,insist:bool,roll:float)->Dictionary:
	## {id:"obey"|"reluctant"|"hesitate"|"refuse", manner, chance}
	if actor.is_empty() or int(actor.get("person_id",0))<=0: return {"id":"obey","manner":"guards","chance":0.0}
	var dread:=DIVINE.dread_of(actor)
	var love:=DIVINE.love_of(actor)
	var rel:=DIVINE.sovereign(actor)
	var resentment:=clampf(float(rel.get("resentment",0.0)),0.0,1.0)
	var courage:=clampf(float(actor.get("courage",0.5)),0.0,1.0)
	var pride:=clampf(float(actor.get("pride",0.5)),0.0,1.0)
	var personality:Dictionary=actor.get("personality",{}) if actor.get("personality") is Dictionary else {}
	var empathy:=clampf(float(personality.get("empathy",0.5)),0.0,1.0)
	var cruel:=verb in CRUEL
	var chance:=0.0
	if dread<=0.15 and courage>=0.75 and (resentment>=0.35 or pride>=0.75):
		chance=clampf(0.2+(courage-0.75)*2.0+maxf(0.0,resentment-0.35)*1.2+maxf(0.0,pride-0.75)*1.0-dread*2.0,0.0,0.95)
		if not cruel: chance*=0.3
		if insist: chance*=0.7
	if roll<chance: return {"id":"refuse","manner":"defiant","chance":chance}
	var manner:="trembling" if dread>=0.5 else ("grim" if cruel else "ready")
	if cruel and verb=="kill" and not insist and love>=0.6 and dread<0.4 and empathy>=0.5: return {"id":"hesitate","manner":"stricken","chance":chance}
	if cruel and (love>=0.55 or empathy>=0.62 or insist): return {"id":"reluctant","manner":"stricken" if love>=0.55 else manner,"chance":chance}
	return {"id":"obey","manner":manner,"chance":chance}

static func _roll(audience:Dictionary,key:String)->float:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|command|%s|%s|%d|%d" % [int(GameState.world_seed),String(audience.get("id","")),key,int(GameState.elapsed_days),(audience.get("lines",[]) as Array).size()])
	return rng.randf()

static func _person(e:Dictionary)->Dictionary:
	if e.is_empty() or int(e.get("person_id",0))<=0: return {}
	var p:=Hall._official(int(e.person_id))
	return p if not p.is_empty() else GovernmentPeopleSystem.person_snapshot(int(e.person_id))

# --------------------------------------------------------------------------
# Hearing the god
# --------------------------------------------------------------------------

static func hear(id:String,text:String,context:Dictionary={})->Dictionary:
	## The ruler spoke. Returns {handled:false, act} for questions, statements
	## and acts the ordinary flow already carries; otherwise the engine's full
	## result (see _result) after the act. context: {terrain, civic_settlement,
	## live:{act,verb,actor_ref,target_ref,object,confidence}, echoed:bool}.
	var audience:=Hall.find(id)
	var clean:=text.strip_edges().replace("\n"," ").substr(0,400)
	if audience.is_empty() or String(audience.get("status",""))!="waiting" or clean.is_empty(): return {"handled":false,"act":"statement"}
	var list:=roster(audience)
	var cls:=classify(clean)
	var live:Dictionary=context.get("live",{}) if context.get("live") is Dictionary else {}
	var from_live:=false
	if not live.is_empty() and (String(cls.act) in ["statement","question"] or String(cls.verb) in ["none","order"]):
		var lact:=String(live.get("act",""))
		var lverb:=String(live.get("verb","none"))
		if lact=="command" and lverb in VERBS and float(live.get("confidence",0.0))>=LIVE_CONFIDENCE:
			cls.act="command"; cls.verb=lverb; cls.confidence=float(live.confidence); from_live=true
			var obj:=String(live.get("object","")).to_lower()
			if String(cls.resource)=="": cls.resource=_resource_in(obj)
			if float(cls.amount)<=0.0: cls.amount=_amount_in(obj)
			for h:String in HEADINGS:
				if String(cls.heading)=="" and h in obj: cls.heading=h
	var insist:=bool(cls.insist)
	if insist:
		var pending:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
		if not pending.is_empty() and Hall._day()-int(pending.get("day",-99))<=PENDING_DAYS:
			return _perform(id,audience,list,String(pending.verb),_entry(list,String(pending.get("actor",""))),_entry(list,String(pending.get("target",""))),clean,cls,true,context)
		# No pending order: the god repeats the last command they gave here.
		var lines:Array=audience.get("lines",[])
		for i in range(lines.size()-1,-1,-1):
			var line:Dictionary=lines[i]
			if String(line.get("role",""))!="ruler": continue
			var said:=String(line.get("text",""))
			if said==clean: continue
			var again:=classify(said)
			if String(again.act)=="command" and not bool(again.insist) and String(again.verb)!="none":
				var parts:=_parties(said,again,audience,list,{})
				return _perform(id,audience,list,String(again.verb),parts.actor,parts.target,clean,again,true,context)
		return {"handled":false,"act":"command","verb":"none"}
	if String(cls.act)!="command" and String(cls.act)!="threat" and String(cls.act)!="blessing": return {"handled":false,"act":String(cls.act)}
	var parts2:=_parties(clean,cls,audience,list,live if from_live else {})
	var actor:Dictionary=parts2.actor
	var target:Dictionary=parts2.target
	var speaker:=_speaker_entry(list)
	if String(cls.act) in ["threat","blessing"]:
		# Aimed at the one before you, the ordinary spoken act already carries it.
		if target.is_empty() or String(target.get("kind",""))!="official" or String(target.key)==String(speaker.get("key","")): return {"handled":false,"act":String(cls.act)}
	if String(cls.verb)=="order" and String(context.get("civic_settlement",""))!="" and (actor.is_empty() or String(actor.key)==String(speaker.get("key",""))):
		return {"handled":false,"act":"command","verb":"order"}   # the settlement leader's civic conversation carries it
	return _perform(id,audience,list,String(cls.verb),actor,target,clean,cls,false,context)

static func _parties(text:String,cls:Dictionary,audience:Dictionary,list:Array[Dictionary],live:Dictionary)->Dictionary:
	## Who must act and on whom.
	var found:=mentions(text,list)
	var verb:=String(cls.verb)
	var at:=int(cls.verb_at)
	var actor:Dictionary={}
	var actor_mention:Dictionary={}
	var guards:=false
	var lower:=text.to_lower()
	for m:Dictionary in found:
		if String(m.by)=="guards" and (at<0 or int(m.at)<at): guards=true
	if not live.is_empty():
		var aref:=String(live.get("actor_ref",""))
		if aref!="" and not aref.to_lower() in ["you","the god","god","i","me"]: actor=resolve_ref(aref,audience,list,"")
		elif aref.to_lower()=="you": actor=_speaker_entry(list)
	if actor.is_empty() and not guards and at>=0:
		for m:Dictionary in found:
			if String(m.by) in ["name","title"] and int(m.at)<at:
				var between:=lower.substr(int(m.end),at-int(m.end)).strip_edges()
				between=between.trim_prefix(",").trim_prefix("—").trim_prefix("-").strip_edges()
				if between in ["","now","you","shall","must","will","go","go and","you will","you must"] or between.begins_with(",") :
					actor=_entry(list,String(m.key)); actor_mention=m
		# Vocative at the end: "Kill him, Ansel!"
		if actor.is_empty() and not found.is_empty():
			var last:Dictionary=found[found.size()-1]
			if String(last.by) in ["name","title"] and int(last.at)>at and lower.substr(int(last.end)).strip_edges().trim_suffix("!").trim_suffix(".").strip_edges()=="" and lower.substr(0,int(last.at)).strip_edges().ends_with(","):
				actor=_entry(list,String(last.key)); actor_mention=last
	if actor.is_empty() and not guards and at<0:
		for m:Dictionary in found:
			if String(m.by) in ["name","title"] and int(m.at)==0: actor=_entry(list,String(m.key)); actor_mention=m
	if actor.is_empty() and not guards and verb in ["give","send","order","take"]:
		actor=_speaker_entry(list)
	var actor_key:=String(actor.get("key",""))
	var target:Dictionary={}
	if not live.is_empty() and String(live.get("target_ref",""))!="":
		target=resolve_ref(String(live.target_ref),audience,list,actor_key)
	if target.is_empty():
		var candidates:Array[Dictionary]=[]
		for m:Dictionary in found:
			if m==actor_mention or String(m.by)=="guards": continue
			if String(m.by)=="god" and not verb in CRUEL: continue   # "a stone to me" is not a target
			if verb=="appoint" and String(m.by)=="title" and not candidates.is_empty(): continue
			candidates.append(m)
		var chosen:Dictionary={}
		for m:Dictionary in candidates:
			if at<0 or int(m.at)>=at: chosen=m; break
		if chosen.is_empty() and not candidates.is_empty(): chosen=candidates[0]
		if not chosen.is_empty(): target=_land(chosen,audience,list,actor_key)
	if target.is_empty() and verb in ["kill","exile","detain","penance","demote","raise","bless","boon","terrify"]:
		target=_salient(audience,list,actor_key)
	if verb in ["send","order"] and target.is_empty(): target=actor
	return {"actor":actor,"target":target,"guards":guards}

static func _perform(id:String,audience:Dictionary,list:Array[Dictionary],verb:String,actor:Dictionary,target:Dictionary,text:String,cls:Dictionary,insist:bool,context:Dictionary)->Dictionary:
	if not bool(context.get("echoed",false)):
		Hall.append_line(id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":text,"day":Hall._day(),"aside":false})
	var r:=_result(verb,actor,target,text,insist)
	audience.erase("pending_command")
	if String(target.get("kind",""))=="god":
		r.outcome="No hand in the hall will turn on the god. The whole court falls on its face."
		r.stage="prostrate"
		_apply_court(id,"terrify",{},[])
		return r
	# The engine decides obedience before anything is done or voiced.
	var person:=_person(actor)
	var ob:=obedience(person,verb,insist,_roll(audience,verb+String(actor.get("key",""))))
	# The actor may not be the victim; a self-strike becomes the guards'.
	if not actor.is_empty() and String(actor.key)==String(target.get("key","")) and verb in CRUEL:
		actor={}; ob={"id":"obey","manner":"guards","chance":0.0}; r.actor={}
	r.obedience=ob
	_focus(audience,target,actor)
	match String(ob.id):
		"hesitate":
			audience["pending_command"]={"verb":verb,"actor":String(actor.get("key","")),"target":String(target.get("key","")),"day":Hall._day(),"text":text.substr(0,200)}
			r.stage="hesitate"
			r.outcome="%s has not done it. They hold back and plead with you; your word still stands." % String(actor.name)
			return r
		"refuse":
			return _refusal(id,audience,list,r,person,verb)
	match verb:
		"kill","exile","detain": return _punish(id,audience,list,r,verb,actor,target)
		"penance","terrify","bless","boon","raise": return _spoken_act(id,audience,r,verb,target)
		"demote": return _demote(id,audience,r,target)
		"appoint": return _appoint(id,audience,r,target,text)
		"give": return _give(id,audience,r,target,cls)
		"take": return _take(id,audience,r,target,cls)
		"send": return _send(id,audience,r,actor,cls,context,text)
	return _order(id,audience,r,actor,text,context)

static func _result(verb:String,actor:Dictionary,target:Dictionary,text:String,insist:bool)->Dictionary:
	return {"handled":true,"ok":true,"act":"command","verb":verb,"text":text,"insist":insist,"actor":actor.duplicate(),"target":target.duplicate(),
		"actor_name":String(actor.get("name","")),"target_name":String(target.get("name","")),"executed":false,"terminal":false,"removed":false,
		"outcome":"","stage":verb,"reaction":"neutral","effects":{},"obedience":{"id":"obey","manner":"guards"},"witness_ids":[]}

static func _focus(audience:Dictionary,target:Dictionary,actor:Dictionary)->void:
	var key:=String(target.get("key",""))
	if key=="" or key=="god": key=String(actor.get("key",""))
	if key!="": audience["command_focus"]={"last_ref":key,"day":Hall._day()}

static func _witness_ids(id:String,exclude:Array)->Array:
	var out:Array=[]
	var audience:=Hall.find(id)
	var speaker_pid:=int((audience.get("speaker",{}) as Dictionary).get("person_id",0))
	if speaker_pid>0 and not speaker_pid in exclude and not Hall._official(speaker_pid).is_empty(): out.append(speaker_pid)
	for p:Dictionary in Hall.court(id):
		if not int(p.person_id) in exclude and not int(p.person_id) in out: out.append(int(p.person_id))
	return out

static func _apply_court(id:String,action:String,target:Dictionary,exclude:Array)->Dictionary:
	var watchers:Array=[]
	for wid in _witness_ids(id,exclude):
		var p:=Hall._official(int(wid))
		if not p.is_empty(): watchers.append(p)
	return DIVINE.apply_to_court(action,target,watchers)

# --------------------------------------------------------------------------
# Acts
# --------------------------------------------------------------------------

static func _punish(id:String,audience:Dictionary,list:Array[Dictionary],r:Dictionary,verb:String,actor:Dictionary,target:Dictionary)->Dictionary:
	var kind:=String(target.get("kind",""))
	var name:=String(target.get("name","them"))
	var by:=String(actor.get("name",""))
	var hand:=" by %s's hand" % by if by!="" else ""
	var action:=String({"kill":"strike_down","exile":"cast_out","detain":"detain"}.get(verb,"strike_down"))
	if kind=="official":
		var pid:=int(target.person_id)
		var before:=_witness_ids(id,[pid])
		if action=="detain":
			var person:=_person(target)
			var gone:=GovernmentPeopleSystem.person_departs(pid,"detained")
			if not bool(gone.get("ok",false)): return _fallback(id,r,String(gone.get("reason","")))
			r.effects=_apply_court(id,"penance",person,[pid])
			GovernmentPeopleSystem.record_person_memory(pid,"The god had me bound and put under guard before the whole court.","divine",0.85,{"emotion":"terror","outcome":"detained"})
			r.outcome="%s was bound and put under guard at your word%s, stripped of office.%s" % [name,hand," %s took up the work." % ", ".join(PackedStringArray(gone.get("successors",[]))) if not (gone.get("successors",[]) as Array).is_empty() else ""]
			r.removed=true
		else:
			var done:=Hall.divine(id,action,String(r.text),pid,{"agent_name":by,"agent_pid":int(actor.get("person_id",0)),"quiet":true})
			if not bool(done.get("ok",false)): return _fallback(id,r,String(done.get("outcome","")))
			r.effects=done.get("effects",{}); r.outcome=String(done.outcome); r.removed=true
			r.terminal=bool(done.get("terminal",false)); r.reaction=String(done.get("reaction","furious")); r.successor=String(done.get("successor",""))
		r.witness_ids=before
		if bool(target.get("speaker",false)) and not r.terminal:
			r.terminal=true
			Hall.conclude(id,String(r.outcome),action)
	elif kind=="figure":
		var figure:Dictionary=HistoricalFigures.by_id(String(target.figure_id))
		var day:=Hall._day()
		if verb=="kill": HistoricalFigures.record_death(String(target.figure_id),day,"execution at the ruler's word")
		elif not figure.is_empty():
			figure["status"]="exiled" if verb=="exile" else "detained"; figure["supported"]=false
			HistoricalFigures.note(String(target.figure_id),day,"Cast out of the realm by the ruler's word." if verb=="exile" else "Bound and put under guard by the ruler's word.")
		var metrics:Dictionary=GameState.simulation_metrics
		metrics["legitimacy"]=clampf(float(metrics.get("legitimacy",0.5))-(0.05 if verb=="kill" else 0.02),0.01,0.99)
		metrics["cohesion"]=clampf(float(metrics.get("cohesion",0.5))-(0.03 if verb=="kill" else 0.01),0.01,0.99)
		r.witness_ids=_witness_ids(id,[])
		r.effects=_apply_court(id,action if action!="detain" else "cast_out",{"person_id":0,"name":name},[])
		r.outcome=String({"kill":"%s was killed%s at your word, before the court. It cost you legitimacy and cohesion.","exile":"%s was cast out of the realm%s at your word.","detain":"%s was bound and put under guard%s at your word."}.get(verb,"%s was dealt with%s at your word.")) % [name,hand]
		r.removed=true; r.terminal=true; r.reaction="furious"
		Hall.conclude(id,String(r.outcome),action)
	elif kind=="envoy":
		return _punish_envoy(id,audience,r,verb,actor)
	else:
		return _fallback(id,r,"")
	r.executed=true
	if not actor.is_empty() and int(actor.get("person_id",0))>0: _hand_of_the_god(r,actor,target,verb)
	return r

static func _hand_of_the_god(r:Dictionary,actor:Dictionary,target:Dictionary,verb:String)->void:
	## The one who carried it out carries it after: dread of the god, and for
	## the gentle, a wound that becomes resentment.
	var person:=_person(actor)
	if person.is_empty(): return
	var personality:Dictionary=person.get("personality",{}) if person.get("personality") is Dictionary else {}
	var empathy:=clampf(float(personality.get("empathy",0.5)),0.0,1.0)
	var reluctant:=String((r.obedience as Dictionary).get("id",""))=="reluctant"
	var deltas:={"fear":0.06 if verb=="kill" else 0.03,"love":-0.07 if reluctant else -0.03,"obligation":0.03,
		"resentment":(0.05+0.06*empathy) if reluctant else 0.01*empathy,"hold_days":60 if verb=="kill" else 20}
	r["actor_after"]=GovernmentPeopleSystem.adjust_person_bonds(int(actor.person_id),deltas)
	var name:=String(target.get("name","them"))
	var memory:=String({"kill":"At the god's word I killed %s with my own hands, before the whole court.","exile":"At the god's word I drove %s out of the realm.","detain":"At the god's word I bound %s and put them under guard."}.get(verb,"At the god's word I acted against %s.")) % name
	GovernmentPeopleSystem.record_person_memory(int(actor.person_id),memory,"divine",0.9 if verb=="kill" else 0.7,{"emotion":"horror" if reluctant else "duty","outcome":"carried_out_"+verb})

static func _punish_envoy(id:String,audience:Dictionary,r:Dictionary,verb:String,actor:Dictionary)->Dictionary:
	var civ_id:=String(audience.civ_id)
	var civ_name:=String(audience.get("civ_name",civ_id))
	var name:=String((audience.speaker as Dictionary).get("name","the envoy"))
	var by:=String(actor.get("name",""))
	var hand:=" by %s's hand" % by if by!="" else ""
	match verb:
		"kill":
			Hall._shift_relation(civ_id,-0.45,0.4); Hall._leader_trust(civ_id,-0.35)
			DIVINE.add_civ_dread(civ_id,0.3)
			ForeignDiplomacy.remember(civ_id,"Our envoy %s was put to death in the ruler's hall." % name)
			r.outcome="%s, envoy of %s, was killed%s at your word. Their people will hear of it: hatred and dread of you both rise, and the border grows dangerous." % [name,civ_name,hand]
		"detain":
			Hall._shift_relation(civ_id,-0.3,0.3); Hall._leader_trust(civ_id,-0.25)
			DIVINE.add_civ_dread(civ_id,0.18)
			ForeignDiplomacy.remember(civ_id,"Our envoy %s was seized and held captive in the ruler's hall." % name)
			r.outcome="%s, envoy of %s, was bound and held%s at your word. Their people take it as a grave insult." % [name,civ_name,hand]
		_:
			Hall._shift_relation(civ_id,-0.12,0.08); Hall._leader_trust(civ_id,-0.1)
			DIVINE.add_civ_dread(civ_id,0.06)
			ForeignDiplomacy.remember(civ_id,"Our envoy %s was driven out of the ruler's hall." % name)
			r.outcome="%s, envoy of %s, was driven out of your hall%s. Their people will feel the slight." % [name,civ_name,hand]
	r.executed=true; r.removed=true; r.terminal=true; r.reaction="furious"
	r.witness_ids=_witness_ids(id,[])
	r.effects=_apply_court(id,"strike_down" if verb=="kill" else "cast_out",{"person_id":0,"name":name},[])
	Hall.conclude(id,String(r.outcome),"envoy_"+verb)
	return r

static func _spoken_act(id:String,audience:Dictionary,r:Dictionary,verb:String,target:Dictionary)->Dictionary:
	var action:=String({"raise":"raise_up"}.get(verb,verb))
	if String(target.get("kind",""))=="envoy":
		if action=="terrify":
			var done:=Hall.divine(id,"terrify",String(r.text))
			r.merge(done,true); r.handled=true; r.executed=bool(done.get("ok",false)); r.stage="terrify"
			return r
		action="bless"
	if String(target.get("kind",""))!="official": return _fallback(id,r,"")
	var done2:=Hall.divine(id,action,String(r.text),int(target.person_id),{"quiet":true})
	if not bool(done2.get("ok",false)):
		# Already done here, or the stores cannot pay: say so plainly.
		r.outcome=String(done2.get("outcome",""))
		if r.outcome=="": r.outcome="It is already done."
		r.stage="none"
		return r
	r.effects=done2.get("effects",{}); r.outcome=String(done2.outcome); r.response=String(done2.get("response",""))
	r.reaction=String(done2.get("reaction","neutral")); r.executed=true; r.stage=verb
	if done2.has("terms"): r.terms=done2.terms
	r.witness_ids=_witness_ids(id,[int(target.person_id)])
	return r

static func _demote(id:String,audience:Dictionary,r:Dictionary,target:Dictionary)->Dictionary:
	if String(target.get("kind",""))!="official": return _fallback(id,r,"")
	var removed:Dictionary
	if String(target.office_key)=="settlement": removed=GovernmentPeopleSystem.remove_settlement_leader(String(target.settlement_id),"dismiss")
	else: removed=GovernmentPeopleSystem.remove_central_officeholder(String(target.office_key),"dismiss")
	if not bool(removed.get("ok",false)): return _fallback(id,r,String(removed.get("reason","")))
	var pid:=int(target.person_id)
	GovernmentPeopleSystem.adjust_person_bonds(pid,{"resentment":0.12,"fear":0.05,"respect":-0.06})
	GovernmentPeopleSystem.record_person_memory(pid,"The god stripped me of my office before the whole court.","divine",0.8,{"emotion":"shame","outcome":"demoted"})
	var heir:=String((removed.get("successor",{}) as Dictionary).get("name",""))
	r.outcome="%s was stripped of office at your word.%s" % [String(target.name)," %s holds it now." % heir if heir!="" else ""]
	r.executed=true; r.reaction="offended"; r.witness_ids=_witness_ids(id,[pid])
	if bool(target.get("speaker",false)):
		r.terminal=true
		Hall.conclude(id,String(r.outcome),"demote")
	return r

static func _office_in(text:String)->String:
	var lower:=text.to_lower()
	for office:Dictionary in GovernmentPeopleSystem.active_offices():
		var title:=String(GovernmentPeopleSystem.office_definition(String(office.key)).get("title","")).to_lower()
		if title!="" and _re("\\b%s\\b" % _escape(title)).search(lower)!=null: return String(office.key)
	var keys:=OFFICE_WORDS.keys()
	keys.sort_custom(func(a:Variant,b:Variant)->bool:return String(a).length()>String(b).length())
	for word in keys:
		if _re("\\b%s\\b" % _escape(String(word))).search(lower)!=null: return String(OFFICE_WORDS[word])
	return ""

static func _appoint(id:String,audience:Dictionary,r:Dictionary,target:Dictionary,text:String)->Dictionary:
	if String(target.get("kind",""))!="official": return _fallback(id,r,"")
	var office:=_office_in(text)
	var pid:=int(target.person_id)
	if office=="" or not GovernmentPeopleSystem.office_is_active(office) or String(target.office_key)==office:
		return _spoken_act(id,audience,r,"raise",target)
	var former:Dictionary=GovernmentPeopleSystem.officeholder(office)
	var appointed:=GovernmentPeopleSystem.mark_central_appointment(pid,office)
	if appointed.is_empty(): return _spoken_act(id,audience,r,"raise",target)
	GovernmentPeopleSystem.adjust_person_bonds(pid,{"respect":0.08,"love":0.05,"obligation":0.06})
	GovernmentPeopleSystem.record_person_memory(pid,"The god made me %s before the whole court." % String(appointed.get("office_title",office)),"divine",0.8,{"emotion":"awe","outcome":"appointed"})
	if not former.is_empty() and int(former.person_id)!=pid:
		GovernmentPeopleSystem.adjust_person_bonds(int(former.person_id),{"resentment":0.1,"respect":-0.04})
		GovernmentPeopleSystem.record_person_memory(int(former.person_id),"The god gave my office to %s before the court." % String(target.name),"divine",0.7,{"emotion":"shame","outcome":"replaced"})
	r.outcome="%s is now %s by your word.%s" % [String(target.name),String(appointed.get("office_title",office))," %s no longer holds it." % String(former.name) if not former.is_empty() and int(former.person_id)!=pid else ""]
	r.executed=true; r.reaction="delighted"; r.stage="appoint"; r.witness_ids=_witness_ids(id,[pid])
	return r

static func _give(id:String,audience:Dictionary,r:Dictionary,target:Dictionary,cls:Dictionary)->Dictionary:
	var resource:=String(cls.resource) if String(cls.resource)!="" else "Food"
	var want:=float(cls.amount)
	if want<=0.0: want=float(Hall._boon_terms().amount)
	want=clampf(want,1.0,5000.0)
	var stock:=Hall.player_stock(resource)
	var paid:=0.0
	if stock>=1.0: paid=Hall._debit_player(resource,minf(want,floorf(stock)))
	r.terms={"resource":resource,"amount":paid}
	var who:=String(target.get("name","them"))
	if paid<=0.0:
		r.outcome="Your stores hold no %s to give %s." % [resource,who]
		r.stage="none"; r.executed=false
		return r
	var short:=" (all the stores held)" if paid+0.001<want else ""
	match String(target.get("kind","")):
		"envoy":
			var civ_id:=String(audience.civ_id)
			Hall._credit_civ(civ_id,resource,paid)
			Hall._shift_relation(civ_id,clampf(paid/400.0,0.01,0.12),-clampf(paid/800.0,0.0,0.06))
			ForeignDiplomacy.remember(civ_id,"The ruler gave our envoy %d %s to carry home." % [roundi(paid),resource])
			r.outcome="You gave %d %s to %s to carry home to %s%s." % [roundi(paid),resource,who,String(audience.get("civ_name","their people")),short]
			r.reaction="pleased"
		"official":
			var pid:=int(target.person_id)
			r.effects=_apply_court(id,"boon",_person(target),[pid])
			r.outcome="You gave %s %d %s from the stores%s." % [who,roundi(paid),resource,short]
			r.reaction="delighted"; r.witness_ids=_witness_ids(id,[pid])
		_:
			r.outcome="%d %s left the stores at your word%s." % [roundi(paid),resource,short]
	r.executed=true; r.stage="give"
	return r

static func _take(id:String,audience:Dictionary,r:Dictionary,target:Dictionary,cls:Dictionary)->Dictionary:
	var resource:=String(cls.resource) if String(cls.resource)!="" else "Food"
	var want:=clampf(float(cls.amount) if float(cls.amount)>0.0 else 20.0,1.0,2000.0)
	if String(audience.get("origin",""))=="foreign" and (String(target.get("kind",""))=="envoy" or target.is_empty()):
		var civ_id:=String(audience.civ_id)
		var theirs:=Hall.foreign_stock(civ_id,resource)
		var got:=0.0
		if theirs>0.0:
			got=Hall.EXCHANGE.take(civ_id,resource,minf(want,theirs))
			if got>0.0: Hall.EXCHANGE.receive("player",resource,got)
		Hall._shift_relation(civ_id,-0.15,0.12); Hall._leader_trust(civ_id,-0.12)
		DIVINE.add_civ_dread(civ_id,0.08)
		ForeignDiplomacy.remember(civ_id,"The ruler seized %s from our people through our envoy." % resource.to_lower())
		r.terms={"resource":resource,"amount":got}
		r.outcome=("Your guards took %d %s from the stores of %s. Their people will call it theft." % [roundi(got),resource,String(audience.get("civ_name",""))]) if got>0.0 else "Your guards turned out the envoy's packs; %s had no %s to seize, and will remember the insult." % [String(audience.get("civ_name","their people")),resource.to_lower()]
		r.executed=true; r.stage="take"; r.reaction="furious"
		return r
	# Officials keep nothing apart from the common stores: a fine becomes penance.
	if String(target.get("kind",""))=="official":
		var done:=_spoken_act(id,audience,r,"penance",target)
		if bool(done.executed): done.outcome="%s holds nothing apart from the common stores; the fine becomes penance. %s" % [String(target.name),String(done.outcome)]
		return done
	return _fallback(id,r,"")

static func _send(id:String,audience:Dictionary,r:Dictionary,actor:Dictionary,cls:Dictionary,context:Dictionary,text:String)->Dictionary:
	var lower:=text.to_lower()
	var civ:Dictionary={}
	for c:Dictionary in WorldSimulation.world.civilizations:
		var cname:=String(c.get("name","")).to_lower()
		if cname!="" and cname in lower: civ=c; break
	var who:=String(actor.get("name",""))
	if not civ.is_empty() and (_re("(?i)\\b(envoy|envoys|messenger|embassy|word)\\b").search(text)!=null or not "scout" in lower):
		var sent:Dictionary=CivilizationSystem.dispatch_diplomat(String(civ.id))
		if sent.has("error"): return _order(id,audience,r,actor,text,context,String(sent.error))
		r.outcome="Envoys set out for %s at your word. %s" % [String(civ.get("name","")),String(sent.get("message","")).get_slice(".",0)+"."]
	else:
		var heading:=String(cls.heading)
		var sent2:Dictionary=CivilizationSystem.dispatch_scouts(30,"open_world",heading)
		if sent2.has("error"): return _order(id,audience,r,actor,text,context,String(sent2.error))
		r.outcome="A scouting party sets out%s at your word%s. %s" % [" to the "+heading if heading!="" else ""," under "+who if who!="" else "",String(sent2.get("message","")).get_slice(".",0)+"."]
	if int(actor.get("person_id",0))>0:
		GovernmentPeopleSystem.adjust_person_bonds(int(actor.person_id),{"obligation":0.02,"respect":0.01})
		GovernmentPeopleSystem.record_person_memory(int(actor.person_id),"The god sent me out: %s" % text.substr(0,160),"divine",0.6,{"emotion":"duty","outcome":"sent"})
	r.executed=true; r.stage="send"; r.reaction="pleased"
	return r

static func _order(id:String,audience:Dictionary,r:Dictionary,actor:Dictionary,text:String,context:Dictionary,blocker:String="")->Dictionary:
	## Any other order: the actor takes it up and it goes to the council.
	var ctx:=context.duplicate()
	ctx["audience_id"]=id
	ctx["actor"]=actor.duplicate()
	if String(actor.get("office_key",""))=="settlement": ctx["settlement_id"]=String(actor.get("settlement_id",""))
	elif not _person(actor).is_empty() and String(_person(actor).get("local_leader_of",""))!="": ctx["settlement_id"]=String(_person(actor).local_leader_of)
	var words:=_strip_vocative(text,actor)
	var routed:=custom_order(words,ctx)
	if int(actor.get("person_id",0))>0:
		GovernmentPeopleSystem.adjust_person_bonds(int(actor.person_id),{"obligation":0.02,"fear":0.01})
		GovernmentPeopleSystem.record_person_memory(int(actor.person_id),"The god gave me an order before the court: %s" % words.substr(0,160),"divine",0.55,{"emotion":"duty","outcome":"ordered"})
	var who:=String(actor.get("name",""))
	r.outcome=("%s%s " % [blocker+" " if blocker!="" else "","%s takes up your order." % who if who!="" else "Your order is taken up."])+String(routed.get("outcome",""))
	r.route=String(routed.get("route",""))
	r.executed=true; r.stage="order"; r.reaction="neutral"
	r.verb="order"
	return r

static func _strip_vocative(text:String,actor:Dictionary)->String:
	var clean:=text.strip_edges()
	for k:String in _name_keys(actor)+_title_keys(actor):
		var re:=_re("(?i)^(the )?%s\\s*[,:\\-—]?\\s*" % _escape(k))
		var m:=re.search(clean)
		if m!=null and m.get_end()<clean.length(): return clean.substr(m.get_end()).strip_edges()
	return clean

static func custom_order(text:String,context:Dictionary)->Dictionary:
	## Orders the court has no dedicated act for. A settlement leader's order,
	## or one the civic catalog recognises, goes through the civic pipeline
	## (which answers in the leader's voice and falls back to the custom
	## directive itself); anything else is applied at once through the
	## universal custom-directive path (custom_directive.gd): bounded changes
	## on DecreeStatistics parameters, real costs, side effects. Never refused.
	## custom_directive_handler, when set, is asked first.
	if custom_directive_handler.is_valid():
		var handled:Variant=custom_directive_handler.call(text,context)
		if handled is Dictionary and bool((handled as Dictionary).get("ok",false)): return handled
	var terrain:Variant=context.get("terrain",null)
	var sid:=String(context.get("settlement_id",""))
	var civic:=terrain is Object and is_instance_valid(terrain) and (terrain as Object).has_method("issue_civic_directive_text")
	if civic and (sid!="" or Hall.is_directive(text)):
		if sid!="": SettlementModel.select_settlement(sid)
		(terrain as Object).call("issue_civic_directive_text",text)
		return {"ok":true,"route":"civic","outcome":"It goes out to the council to be carried out."}
	var plan:=CustomDirective.offline_plan(text)
	if plan.is_empty(): plan=CustomDirective.attempt_plan(text)
	var policy:=CustomDirective.policy_from_plan(plan)
	var actor:Dictionary=context.get("actor",{}) if context.get("actor") is Dictionary else {}
	var execution:=0.8
	var person:=_person(actor)
	if not person.is_empty():
		var office:=String(person.get("office_key","Steward"))
		execution=clampf(float(AdvisorSystem.execution_modifier_for_advisor(person,office if office!="settlement" else "Steward",["Administration"])),0.2,1.2)
	var order_id:="court_%s_%d_%d" % [String(context.get("audience_id","")),Hall._day(),hash(text)%100000]
	var applied:Dictionary=ConsequenceEngine.apply_directive(CustomDirective.ID,CustomDirective.MAIN_MAGNITUDE,float(policy.get("days",CustomDirective.DEFAULT_DAYS)),"court_command",
		{"source_order_id":order_id,"directive_parameters":policy.get("directive_parameters",{})},execution)
	if not bool(applied.get("applied",false)):
		if civic:
			(terrain as Object).call("issue_civic_directive_text",text)
			return {"ok":true,"route":"civic","outcome":"It goes out to the council to be carried out."}
		return {"ok":true,"route":"recorded","outcome":"It is remembered, to be carried out."}
	var rate:=float((applied.get("assessment",{}) as Dictionary).get("implementation_rate",0.5))
	var words:="broadly" if rate>=0.72 else ("unevenly" if rate>=0.36 else "only narrowly")
	return {"ok":true,"route":"custom_directive","order_id":order_id,"plan":plan,"applied":applied,
		"outcome":"Your order %s is being carried out %s." % [CustomDirective.display_name(plan),words]}

static func _refusal(id:String,audience:Dictionary,list:Array[Dictionary],r:Dictionary,person:Dictionary,verb:String)->Dictionary:
	## Rare and consequential: the brave, unafraid and embittered say no, and
	## then flee the god's reach, or the court seizes them for your judgment.
	var pid:=int(person.get("person_id",0))
	var name:=String(person.get("name","They"))
	var courage:=clampf(float(person.get("courage",0.5)),0.0,1.0)
	var flee:=courage>=0.8 and _roll(audience,"flee%d" % pid)<0.6
	GovernmentPeopleSystem.record_person_memory(pid,"I refused the god's command before the whole court.","divine",0.9,{"emotion":"defiance","outcome":"refused"})
	r.witness_ids=_witness_ids(id,[pid])
	if flee:
		var gone:=GovernmentPeopleSystem.person_departs(pid,"fled")
		r.stage="refuse_flee"; r.removed=bool(gone.get("ok",false))
		r.outcome="%s refused your command and fled the hall, beyond the reach of your guards.%s" % [name," %s took up the work." % ", ".join(PackedStringArray(gone.get("successors",[]))) if not (gone.get("successors",[]) as Array).is_empty() else ""]
		r.effects=_apply_court(id,"cast_out",{"person_id":0,"name":name},[pid])
		if bool((r.actor as Dictionary).get("speaker",false)):
			r.terminal=true
			Hall.conclude(id,String(r.outcome),"fled")
	else:
		GovernmentPeopleSystem.adjust_person_bonds(pid,{"fear":0.3,"resentment":0.1,"love":-0.05,"hold_days":30})
		r.stage="refuse_seized"
		r.outcome="%s refused your command. The court seized them; they kneel bound before you, awaiting your judgment." % name
		r.effects=_apply_court(id,"terrify",{"person_id":0,"name":name},[pid])
		audience["command_focus"]={"last_ref":"person:%d" % pid,"day":Hall._day()}
	r.executed=false; r.reaction="furious"
	return r

static func _fallback(id:String,r:Dictionary,reason:String)->Dictionary:
	## The act could not land as spoken (no one by that name, or the office
	## machinery refused): still a result, never silence.
	r.stage="none"
	r.outcome=(reason+" " if reason!="" else "")+"Nobody here answers to that; the court waits for you to name who you mean."
	return r

# --------------------------------------------------------------------------
# Words for the voice: stage directions and reactions
# --------------------------------------------------------------------------

const WEAPONS_STONE:=["a flint knife","a stone axe","a hardwood club","a fire-hardened spear","a bone dagger","a heavy hand-stone"]
const WEAPONS_METAL:=["a bronze blade","an iron sword","a copper axe","an iron-headed spear"]
## By how they kill, so a club never "opens a throat".
const BLADES:=["an iron sword","a bronze blade","a flint knife","a bone dagger","an obsidian knife"]
const CLUBS:=["a stone axe","a hardwood club","a heavy hand-stone","a copper axe"]

static func weapons(tags:Array)->Array[String]:
	var out:Array[String]=[]
	var metal:=tags.has("metal")
	for w:String in (WEAPONS_METAL if metal else [])+WEAPONS_STONE:
		if CV.permits(w,tags): out.append(w)
	return out

## Bracketed stage directions, per engine outcome. Tokens: {actor} {target}
## {weapon} {res} {amt}. "their/them" throughout: no one's sex is assumed.
const STAGE:={
	"kill_by":["[{actor} crosses the floor in three strides and drives {blade} into {target}'s throat; blood sprays across the hearthstones and the court cries out.]",
		"[{actor} seizes {target} by the hair and opens their neck with {blade}; {target} falls, and the watchers shrink back from the spreading dark.]",
		"[{actor} brings {club} down on {target}'s skull once, then again; the body slumps to the floor and nobody in the hall breathes.]",
		"[{actor} catches {target} as they rise and drives {blade} up under the ribs; {target} sags, and someone at the back retches.]"],
	"kill_by_reluctant":["[{actor}'s hands shake, but {blade} goes into {target}'s throat all the same; blood soaks their arms and they stand weeping over the body.]",
		"[{actor} whispers something to {target}, then cuts them down with {blade}; the court turns its faces from the blood pooling by the fire.]",
		"[{actor} closes their eyes and swings {club}; {target} drops without a sound, and {actor} does not look down.]"],
	"kill_guards":["[The guards drag {target} to the centre of the hall and break their skull with {club}; the court stares at the floor.]",
		"[Two guards pin {target} to the ground and {weapon} does the rest; blood runs between the floor stones as the court stands frozen.]",
		"[{target} is hauled out past the fire; one cry comes from outside, then silence, and the guards return with {blade} dripping.]"],
	"exile":["[{target} is stripped of every mark of office and driven out past the last hearth with nothing but the clothes on their back.]",
		"[Spear points herd {target} to the edge of the camp and push them out into the dark; the court listens to the footsteps fade.]"],
	"detain":["[{target}'s arms are wrenched behind them and their wrists bound with rawhide cord; they are dragged away to be kept under guard.]",
		"[{target} is thrown to the floor and tied hand and foot; the guards haul them off under watch while the court looks away.]"],
	"give":["[Bearers carry {amt} {res} out of the stores and heap it at {target}'s feet; every eye in the court follows the loads.]",
		"[{amt} {res} is brought out and laid before {target}, who stares at the pile and then at you.]"],
	"take":["[The guards tear open the envoy's packs and haul the goods away; the envoy watches, white to the lips.]",
		"[Your guards strip the envoy's bearers of their loads while the envoy stands rigid with fury.]"],
	"penance":["[{target} sinks to their knees and presses their brow to the cold ground, beginning the fast.]",
		"[{target} unbelts, kneels in the ashes at the edge of the fire, and bows their head for the vigil.]"],
	"terrify":["[{target} goes grey and sinks to the floor as the god's anger fills the hall.]"],
	"bless":["[{target} bows low while the court watches, the god's favour settling on them like the warmth of a fire.]",
		"[The court draws back to give {target} room; they stand straighter than anyone has seen them stand.]"],
	"raise":["[The court parts as {target} is brought forward and set in the place of honour nearest the fire.]"],
	"appoint":["[The marks of office are taken from their old keeper and hung on {target} before the whole court.]",
		"[{target} is led to the seat of the office and the court rises to acknowledge them.]"],
	"boon":["[A gift from the stores is carried in and set before {target}; they touch it as if it might vanish.]"],
	"demote":["[{target}'s marks of office are taken from them before the whole court; they stand bare and silent.]"],
	"send":["[{actor} bows, gathers their gear and strides out of the hall, already calling for companions.]",
		"[{actor} touches their brow to the floor and is gone before the fire settles, shouting for packs and water skins.]"],
	"order":["[{actor} bows and goes out to see it done; word of the order runs ahead of them through the camp.]",
		"[{actor} is on their feet at once and out through the door, calling names as they go.]"],
	"hesitate":["[{actor} takes up {blade}, then freezes; the point trembles a hand's breadth from {target}, and every eye turns to you.]",
		"[{actor} steps toward {target} with {weapon}, stops, and falls to their knees instead, the weapon still in hand.]"],
	"refuse_flee":["[{actor} lets {weapon} fall, turns, and runs out of the hall into the dark before the guards can close on them.]",
		"[{actor} flings {weapon} at the fire and bolts through the door; by the time the guards reach it they are gone into the night.]"],
	"refuse_seized":["[{actor} throws {weapon} down; the others fall on them at once and force them to their knees before you, arms bound.]",
		"[{actor} refuses and the court is on them in a heartbeat, dragging them to the floor and binding them before your seat.]"],
	"prostrate":["[The whole court falls on its face; nobody dares so much as lift their eyes toward you.]"],
	"envoy_kill":["[The guards seize {target} and cut them down where they stand with {blade}; their blood runs over the gifts they carried.]",
		"[{target} has no time to cry out; {blade} opens their throat and the envoy's bearers flee screaming from the hall.]"],
	"envoy_detain":["[{target} is thrown down and bound with cord while their bearers are driven out, wailing, to carry word home.]"],
	"envoy_exile":["[{target} is hustled out of the hall at spear point, their gifts kicked after them into the dirt.]"],
}

static func stage_key(result:Dictionary)->String:
	var stage:=String(result.get("stage",""))
	var target:Dictionary=result.get("target",{}) if result.get("target") is Dictionary else {}
	var has_actor:=String(result.get("actor_name",""))!="" and not (result.get("actor",{}) as Dictionary).is_empty()
	if String(target.get("kind",""))=="envoy" and stage in ["kill","detain","exile"]: return "envoy_"+stage
	if stage=="kill":
		if not has_actor: return "kill_guards"
		return "kill_by_reluctant" if String((result.get("obedience",{}) as Dictionary).get("id",""))=="reluctant" else "kill_by"
	return stage if STAGE.has(stage) else ""

static func stage_bank(result:Dictionary)->Array:
	return STAGE.get(stage_key(result),[])

static func _pick(list:Array,tags:Array,rng:RandomNumberGenerator,fallback:String)->String:
	var pool:Array=[]
	for w in list:
		if CV.permits(String(w),tags): pool.append(w)
	# The newest the era allows are the ones at hand; keep a little variety.
	if pool.is_empty(): return fallback
	return String(pool[rng.randi_range(0,mini(1,pool.size()-1)) if tags.has("metal") else rng.randi_range(0,pool.size()-1)])

static func stage_tokens(result:Dictionary,tags:Array,rng:RandomNumberGenerator)->Dictionary:
	var terms:Dictionary=result.get("terms",{}) if result.get("terms") is Dictionary else {}
	var any:=weapons(tags)
	var weapon:=String(any[rng.randi_range(0,any.size()-1)]) if not any.is_empty() else "bare hands"
	var out:={"actor":String(result.get("actor_name","")),"target":String(result.get("target_name","")),"weapon":weapon,
		"blade":_pick(BLADES,tags,rng,"a sharpened stone"),"club":_pick(CLUBS,tags,rng,"a heavy stone"),
		"res":String(terms.get("resource","")).to_lower(),"amt":"%d" % roundi(float(terms.get("amount",0.0))) if terms.has("amount") else ""}
	if String(out.actor)=="": out.erase("actor")
	return out

## Reactions (opener x closer pairs, as in divine_voice.gd).
const REACTION:={
	"obey_deed":[["It is done, {address}.","As you commanded.","Your word was my hand.","I did not falter.","You spoke, and it is finished."],
		["Command me again.","Nobody will question it.","The hall is yours.","Let it be a lesson to every one of us.","I would do it again."]],
	"reluctant_deed":[["It is done.","I have done as you commanded.","My hands obeyed you.","You are my god, and it is done."],
		["Do not ask me to wash them yet.","I will carry it all my days.","I pray I never do it again.","Let no one say I was slow."]],
	"obey_task":[["At once, {address}.","I go now.","It will be done.","As you command."],
		["You will hear of it soon.","I come back only when it is done.","Nothing will stop me.","I am already on my way."]],
	"plead":[["Do not ask this of me, {address}.","Not by my hand, I beg you.","Mercy, for them and for me.","I have eaten at their fire."],
		["Say it once more and I will do it.","If you will it again, I will obey.","Let another hand do it, or say the word again.","I will obey, but I beg you to think."]],
	"refuse":[["No. Not this, {address}.","I will not do this thing.","You may be a god; I am still a person."],
		["Do with me what you will.","Find another hand.","I will not carry this on my soul."]],
	"receive":[["You honour me, {address}.","This is more than I earned.","My household will eat well."],
		["I will not forget it.","I will repay it in work.","Everyone saw your hand open."]],
	"seized":[["Let me go.","I only said what was true.","Strike, then."],
		["I am still not sorry.","My kin will remember this.","I have nothing more to say."]],
}

static func reaction_bank(key:String)->Array:
	var pair:Array=REACTION.get(key,[])
	if pair.size()<2: return []
	var out:Array=[]
	for a in pair[0]:
		for b in pair[1]: out.append("%s %s" % [String(a),String(b)])
	return out

static func actor_reaction_key(result:Dictionary)->String:
	var ob:=String((result.get("obedience",{}) as Dictionary).get("id","obey"))
	var stage:=String(result.get("stage",""))
	match ob:
		"hesitate": return "plead"
		"refuse": return "refuse"
		"reluctant": return "reluctant_deed" if stage in ["kill","exile","detain"] else "obey_task"
	if stage in ["kill","exile","detain"]: return "obey_deed"
	if stage in ["send","order"]: return "obey_task"
	return ""

## What the voice is told: the engine's decision in plain words.
static func decided_words(result:Dictionary)->String:
	var ob:Dictionary=result.get("obedience",{}) if result.get("obedience") is Dictionary else {}
	var actor:=String(result.get("actor_name",""))
	var parts:PackedStringArray=PackedStringArray()
	parts.append("WHAT ACTUALLY HAPPENED (decided; describe it, never change it): "+String(result.get("outcome","")))
	match String(ob.get("id","obey")):
		"obey": if actor!="": parts.append("%s OBEYED%s." % [actor," at once, trembling" if String(ob.get("manner",""))=="trembling" else ", without hesitating"])
		"reluctant": parts.append("%s OBEYED, reluctantly: it cost them; they did it anyway." % actor)
		"hesitate": parts.append("%s HESITATED: they have NOT done it yet; they plead once with the god. The god's word still stands; if the god insists they will do it." % actor)
		"refuse": parts.append("%s REFUSED. %s" % [actor,"They fled the hall." if String(result.get("stage",""))=="refuse_flee" else "The court seized them; they kneel bound before the god."])
	if bool(result.get("removed",false)) and String(result.get("target_name",""))!="": parts.append("%s is gone and does not speak." % String(result.target_name))
	return " ".join(parts)
