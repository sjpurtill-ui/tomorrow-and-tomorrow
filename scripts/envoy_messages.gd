extends RefCounted
## What an envoy carries, and what a message of menace does when it lands.
##
## The catalogue: every purpose the send-envoys screen offers, in the order it
## offers them, with the gift each allows (required, optional, food only or
## none) and whether a token of menace may go instead.
##
## Menace: warn, threaten, demand and ultimatum. The receiving ruler answers
## when the envoys arrive (CivilizationSystem._process_diplomatic_mission calls
## arrive()), from real standing: how much their people dread the god, the
## two peoples' fighting strength, whether the god's past threats were kept,
## their ruler's temper and grudges, their friends, and how much is asked.
## They give way (a real, bounded change: tribute out of their ledger, ground
## off their territory, kin sent as a pledge, fighters stood down, a wrong
## owned), refuse (grudge, a hotter border, friends cooled toward you, arms
## readied), or lay hands on the messengers (envoys die; the survivors bring
## the news). The answer comes home with the envoys (homecoming()) into the
## court conversation.
##
## An ultimatum that is refused stands in a ledger until its deadline. Then
## they may give way late; otherwise the named consequence is due. "Close the
## frontier" is carried out by your people at once. "War" is on you: declare it
## within a season of the deadline or the threat is broken, and every people
## learns your threats can be empty (credibility falls, their dread fades, and
## the refusing people grows bolder in its own demands). Kept threats raise
## credibility and dread everywhere.
##
## Rivals answer in kind through the existing envoy occasions: rival_weight()
## tilts which business their envoys bring (never how often they come).
##
## State lives in the hall's saved state under the optional key "menace".
## Static helpers; reference with preload or load.

const Hall:=preload("res://scripts/audience_hall.gd")
const Rivals:=preload("res://scripts/rival_rulers.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const CV:=preload("res://scripts/character_voice.gd")
const EXCHANGE:=preload("res://scripts/civilization_exchange.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const LIVES_PATH:="res://scripts/court_lives.gd"
const PACTS_PATH:="res://scripts/trade_pacts.gd"

const HOSTILE:=["warn","threaten","demand","ultimatum"]
const ORDER:=["goodwill","open_trade","non_aggression","send_aid","leader_parley","seek_peace","declare_war","warn","threaten","demand","ultimatum"]
const GROUPS:={"friendship":"Friendship","war":"War and peace","menace":"Menace"}
## gift: required | optional | food | none. token: a token of menace may go.
const PURPOSES:={
	"goodwill":{"label":"Goodwill","line":"Good words and a gift from your stores.","group":"friendship","gift":"required","token":false},
	"open_trade":{"label":"Open trade","line":"Ask for a standing compact to trade fairly.","group":"friendship","gift":"optional","token":false},
	"non_aggression":{"label":"Promise of peace","line":"Ask that neither people raid the other.","group":"friendship","gift":"optional","token":false},
	"send_aid":{"label":"Food aid","line":"Carry food to a people who need it.","group":"friendship","gift":"food","token":false},
	"leader_parley":{"label":"Speak with their ruler","line":"Carry your own words to their ruler and bring the answer home.","group":"friendship","gift":"none","token":false},
	"seek_peace":{"label":"Seek peace","line":"Ask for a truce to end the war.","group":"war","gift":"optional","token":false},
	"declare_war":{"label":"Declare war","line":"Tell them to their face that war has begun.","group":"war","gift":"none","token":true},
	"warn":{"label":"Warn them off","line":"Tell them to keep away from your people.","group":"menace","gift":"none","token":true},
	"threaten":{"label":"Threaten","line":"Make them afraid of what you could do.","group":"menace","gift":"none","token":true},
	"demand":{"label":"Demand","line":"Ask for something they would rather keep.","group":"menace","gift":"none","token":true},
	"ultimatum":{"label":"Ultimatum","line":"A demand, a deadline, and what you will do if it passes.","group":"menace","gift":"none","token":true},
}
const BY:={"wrath":{"label":"The god's wrath","line":"Their fear of you as a god."},"spears":{"label":"Our spears","line":"Your fighters against theirs."}}
const DEMANDS:={
	"tribute":{"label":"Tribute","line":"A share of their stores, carried home by your envoys.","ask":0.10},
	"ground":{"label":"Yield ground","line":"They give up land at the border.","ask":0.20},
	"hostage":{"label":"A hostage","line":"Kin of their ruler comes to live among your people as a pledge.","ask":0.30},
	"withdraw":{"label":"Pull back","line":"Their fighters stand down and leave the border.","ask":0.10},
	"apology":{"label":"An apology","line":"Their ruler owns a wrong done to your people.","ask":0.08},
}
const CONSEQUENCES:={
	"war":{"label":"War","line":"You make war on them. If you do not, your threats lose their weight.","words":"we will come against you with spears"},
	"sever":{"label":"Close the frontier","line":"Every compact and standing exchange with them ends at the deadline.","words":"we will close the paths between us and end every exchange"},
}
const DEADLINES:=[91,182,365]
const DEADLINE_WORDS:={91:"one season",182:"two seasons",365:"a full year"}
const TOKENS:={
	"none":{"label":"Nothing","line":"Words alone.","dread":0.0,"weight":0.0,"grudge":0.0},
	"broken_spear":{"label":"A broken spear","line":"Laid before their ruler: this is what happens to spears raised against you.","dread":0.02,"weight":0.03,"grudge":0.05},
	"firebrand":{"label":"A blackened firebrand","line":"Laid before their ruler: fires can go out.","dread":0.03,"weight":0.04,"grudge":0.05},
	"raider_head":{"label":"The head of one of their fighters","line":"Only if your people have killed their fighters. Terrible; they will not forget it.","dread":0.08,"weight":0.07,"grudge":0.25},
}
const GRACE_DAYS:=91
const CREDIBILITY_START:=0.5
const STANCE_DAYS:=365
const LOG_MAX:=16
const ULTIMATUMS_MAX:=12

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func store()->Dictionary:
	ForeignDiplomacy.ensure()
	var s:Dictionary=ForeignDiplomacy.audiences
	if not s.get("menace") is Dictionary: s["menace"]={}
	var m:Dictionary=s.menace
	if not _num(m.get("credibility")): m["credibility"]=CREDIBILITY_START
	if not m.get("ultimatums") is Array: m["ultimatums"]=[]
	if not m.get("stances") is Dictionary: m["stances"]={}
	if not m.get("wronged_by") is Dictionary: m["wronged_by"]={}
	if not m.get("log") is Array: m["log"]=[]
	return m

static func _num(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func valid_state(data:Variant)->bool:
	## Optional save block; absent in older saves.
	if not data is Dictionary: return false
	if data.has("credibility") and (not _num(data.credibility) or float(data.credibility)<0.0 or float(data.credibility)>1.0): return false
	if data.has("ultimatums"):
		if not data.ultimatums is Array or (data.ultimatums as Array).size()>ULTIMATUMS_MAX: return false
		for u in data.ultimatums:
			if not u is Dictionary or not u.get("civ_id") is String or not _num(u.get("due")) or not _num(u.get("issued")): return false
			if not String(u.get("consequence","")) in CONSEQUENCES or not String(u.get("demand","")) in DEMANDS: return false
			if not String(u.get("status","")) in ["open","met","kept","broken","void"] or JSON.stringify(u).length()>1500: return false
	for key in ["stances","wronged_by"]:
		if data.has(key):
			if not data[key] is Dictionary or (data[key] as Dictionary).size()>256: return false
			for k in data[key]:
				if not k is String or not data[key][k] is Dictionary or JSON.stringify(data[key][k]).length()>600: return false
	if data.has("log"):
		if not data.log is Array or (data.log as Array).size()>LOG_MAX: return false
		for e in data.log:
			if not e is Dictionary or not _num(e.get("day")) or JSON.stringify(e).length()>1200: return false
	return true

static func valid_mission(data:Variant)->bool:
	## The menace record a traveling delegation carries.
	if not data is Dictionary or JSON.stringify(data).length()>8000: return false
	if not String(data.get("purpose","")) in HOSTILE: return false
	if data.has("by") and not String(data.by) in BY: return false
	if data.has("demand") and String(data.demand)!="" and not String(data.demand) in DEMANDS: return false
	if data.has("token") and not String(data.token) in TOKENS: return false
	if data.has("consequence") and String(data.consequence)!="" and not String(data.consequence) in CONSEQUENCES: return false
	if data.has("deadline") and (not _num(data.deadline) or not int(data.deadline) in DEADLINES): return false
	if data.has("words") and (not data.words is String or String(data.words).length()>1500): return false
	return true

static func _day()->int:
	return int(WorldSimulation.state.elapsed_days)

static func credibility()->float:
	return clampf(float(store().credibility),0.0,1.0)

static func _shift_credibility(delta:float)->void:
	store()["credibility"]=clampf(credibility()+delta,0.1,0.95)

static func stance(civ_id:String)->String:
	var entry:Variant=(store().stances as Dictionary).get(civ_id,{})
	if not entry is Dictionary or int(entry.get("until",0))<=_day(): return ""
	return String(entry.get("kind",""))

static func _set_stance(civ_id:String,kind:String,days:int=STANCE_DAYS)->void:
	(store().stances as Dictionary)[civ_id]={"kind":kind,"until":_day()+days}

static func _log(entry:Dictionary)->void:
	var list:Array=store().log
	entry["day"]=_day()
	list.push_front(entry)
	while list.size()>LOG_MAX: list.pop_back()

static func open_ultimatum(civ_id:String)->Dictionary:
	for u in store().ultimatums:
		if u is Dictionary and String(u.civ_id)==civ_id and String(u.status)=="open": return u
	return {}

# --------------------------------------------------------------------------
# Catalogue and gating
# --------------------------------------------------------------------------

static func gift_rule(purpose:String)->String:
	return String((PURPOSES.get(purpose,{}) as Dictionary).get("gift","none"))

static func allows_gift(purpose:String,resource:String)->bool:
	match gift_rule(purpose):
		"required","optional": return resource!="" or gift_rule(purpose)=="optional"
		"food": return resource=="Food"
	return resource==""

static func tokens_for(civ_id:String,purpose:String)->Array[String]:
	var out:Array[String]=[]
	if not bool((PURPOSES.get(purpose,{}) as Dictionary).get("token",false)): return out
	out.append("none"); out.append("broken_spear"); out.append("firebrand")
	if killed_their_fighters(civ_id): out.append("raider_head")
	return out

static func killed_their_fighters(civ_id:String)->bool:
	for record in WorldSimulation.world.war_history:
		if not record is Dictionary: continue
		var participants:Array=record.get("participants",[])
		if not "player" in participants or not civ_id in participants: continue
		if int(((record.get("casualties",{}) as Dictionary).get(civ_id,{}) as Dictionary).get("military_dead",0))>0: return true
	return false

static func grievance(civ_id:String)->String:
	## A real wrong this people did to yours, in plain words ("" if none).
	var wronged:Variant=(store().wronged_by as Dictionary).get(civ_id,{})
	if wronged is Dictionary and not (wronged as Dictionary).is_empty(): return String(wronged.get("text","what was done to your envoys"))
	for record in WorldSimulation.world.war_history:
		if record is Dictionary and civ_id in (record.get("participants",[]) as Array) and "player" in (record.get("participants",[]) as Array):
			if String((record.get("participants",[]) as Array)[0])==civ_id: return "the war they started against your people"
			return "the blood spilled between your peoples"
	for audience in Hall.state().get("history",[]):
		if audience is Dictionary and String(audience.get("civ_id",""))==civ_id and String(audience.get("kind",""))=="threat": return "the threats their envoys brought to your court"
	return ""

static func demands_for(civ_id:String)->Array[String]:
	var out:Array[String]=["tribute","ground","hostage","withdraw"]
	if grievance(civ_id)!="": out.append("apology")
	return out

static func availability(civ_id:String,purpose:String)->Dictionary:
	## Whether a message of menace can be sent at all ({} or {"error"}).
	var civ:=ForeignDiplomacy.civilization(civ_id)
	if civ.is_empty() or not bool(civ.get("alive",true)): return {"error":"That people is gone."}
	var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
	if int(relation.get("contact_level",0))<2: return {"error":"You have not met this people face to face."}
	if bool(relation.get("at_war",false)): return {"error":"You are already at war with %s. Send for peace, or let your generals speak." % String(civ.get("name",civ_id))}
	if purpose=="ultimatum" and not open_ultimatum(civ_id).is_empty():
		return {"error":"Your last ultimatum to %s still stands until %s." % [String(civ.get("name",civ_id)),Chronicle.date_label(int(open_ultimatum(civ_id).due))]}
	return {"ok":true}

static func tribute_terms(civ_id:String)->Dictionary:
	## What a tribute demand asks: their most plentiful good, scaled to their
	## size and never more than a third of what they hold.
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var pop:=maxf(20.0,float(civ.get("population",100.0)))
	var best:="Food"; var best_stock:=-1.0
	for resource in ["Food","Timber","Stone","Clay","Fiber Plants"]:
		var stock:=Hall.foreign_stock(civ_id,resource)
		if stock>best_stock: best_stock=stock; best=resource
	var amount:=clampf(pop*(0.25 if best=="Food" else 0.06),5.0,150.0)
	if best_stock>=0.0: amount=minf(amount,best_stock/3.0)
	return {"resource":best,"amount":Hall._nice(maxf(1.0,amount)),"ledger":best_stock>=0.0}

# --------------------------------------------------------------------------
# Standing and the likely answer
# --------------------------------------------------------------------------

static func _lives()->GDScript:
	return load(LIVES_PATH) as GDScript

static func standing(civ_id:String)->Dictionary:
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
	var lives:=_lives()
	var dread:=float(lives.call("rival_dread",civ_id)) if lives!=null else Divine.civ_dread(civ_id)
	var world=WorldSimulation.world
	var theirs:=maxf(1.0,float(world._military_power(civ))) if not civ.is_empty() and civ.has("military_population") else 1.0
	var ours:=maxf(1.0,float(world._player_military_power()))
	var ratio:=clampf(ours/theirs,0.25,4.0)
	var p:=Hall._personality(civ_id)
	var bold:=(float(p.get("assertiveness",0.5))+float(p.get("risk_tolerance",0.5)))*0.5
	var trait_id:=String(Rivals.character(civ_id).get("trait",""))
	var partners:=0
	if not civ.is_empty() and world.has_method("_diplomatic_network"): partners=int(world._diplomatic_network(civ).get("partners",0))
	return {"dread":dread,"ratio":ratio,"credibility":credibility(),"bold":bold,"trait":trait_id,"partners":partners,
		"grudge":Rivals.grudge_weight(civ_id),"opinion":float(relation.get("opinion",0.0)),"hostage":not Rivals.has_bond(civ_id,["hostage"]).is_empty(),"stance":stance(civ_id)}

static func ask_of(menace:Dictionary)->float:
	var purpose:=String(menace.get("purpose","threaten"))
	match purpose:
		"warn": return 0.0
		"threaten": return 0.05
		"demand": return float((DEMANDS.get(String(menace.get("demand","tribute")),{}) as Dictionary).get("ask",0.1))
		"ultimatum":
			var base:=float((DEMANDS.get(String(menace.get("demand","tribute")),{}) as Dictionary).get("ask",0.1))
			return base-(0.06 if String(menace.get("consequence","war"))=="war" else 0.03)
	return 0.1

static func score(civ_id:String,menace:Dictionary,view:Dictionary={})->float:
	## Above zero they give way; below, they refuse. No dice here.
	var s:=view if not view.is_empty() else standing(civ_id)
	var by:=String(menace.get("by","wrath"))
	var might:=clampf(log(float(s.ratio))/log(2.0)*0.25,-0.5,0.5)
	var wrath:=float(s.dread)*0.6+(float(s.credibility)-0.5)*0.4
	var backing:=wrath*(1.0 if by=="wrath" else 0.4)+might*(1.0 if by=="spears" else 0.4)
	var pride:=(float(s.bold)-0.5)*0.6+(0.1 if String(s.trait) in ["grudge","bluffer"] else 0.0)
	var allies:=minf(3.0,float(s.partners))*0.05
	var grudge:=minf(0.3,float(s.grudge)*0.12)
	var hate:=maxf(0.0,-float(s.opinion))*0.25
	var token:=float((TOKENS.get(String(menace.get("token","none")),{}) as Dictionary).get("weight",0.0))
	var mood:=0.1 if String(s.stance)=="cowed" else (-0.1 if String(s.stance) in ["emboldened","defiant"] else 0.0)
	return backing-pride-allies-grudge-hate-ask_of(menace)+(0.12 if bool(s.hostage) else 0.0)+token+mood

static func forecast(civ_id:String,menace:Dictionary)->Dictionary:
	var s:=standing(civ_id)
	var value:=score(civ_id,menace,s)
	var harm_possible:=String(menace.get("purpose",""))!="warn" and value<=-0.3 and float(s.bold)>0.55
	var words:="They will probably give way." if value>=0.1 else ("It could go either way." if value>=-0.1 else ("They will refuse, and may lay hands on your envoys." if harm_possible else "They will probably refuse."))
	if String(menace.get("purpose",""))=="warn": words="They will probably heed you." if value>=-0.05 else "They will probably shrug it off."
	var why:Array[String]=[]
	if float(s.dread)>=0.35: why.append("they dread you")
	elif float(s.dread)<0.12: why.append("they have little fear of you")
	if float(s.ratio)>=1.5: why.append("your fighters outnumber theirs")
	elif float(s.ratio)<=0.7: why.append("their fighters outnumber yours")
	if float(s.credibility)<=0.35: why.append("your past threats came to nothing")
	elif float(s.credibility)>=0.65: why.append("your threats have been carried out before")
	if float(s.bold)>=0.62: why.append("their ruler is proud")
	if int(s.partners)>=2: why.append("they have friends")
	if float(s.grudge)>=0.4: why.append("they hold grudges against you")
	return {"score":value,"answer":"comply" if value>=0.0 else "defy","words":words,"why":why,"harm_possible":harm_possible,"standing":s}

# --------------------------------------------------------------------------
# Sending
# --------------------------------------------------------------------------

static func build(purpose:String,choice:Dictionary)->Dictionary:
	## The menace record the envoys carry.
	var menace:={"purpose":purpose,"by":String(choice.get("by","wrath")),"token":String(choice.get("token","none")),"words":String(choice.get("words","")).strip_edges().substr(0,1500),"phrase":int(choice.get("phrase",0))}
	if not String(menace.by) in BY: menace.by="wrath"
	if not String(menace.token) in TOKENS: menace.token="none"
	if purpose in ["demand","ultimatum"]:
		menace["demand"]=String(choice.get("demand","tribute")) if String(choice.get("demand","tribute")) in DEMANDS else "tribute"
	if purpose=="ultimatum":
		menace["consequence"]=String(choice.get("consequence","war")) if String(choice.get("consequence","war")) in CONSEQUENCES else "war"
		menace["deadline"]=int(choice.get("deadline",182)) if int(choice.get("deadline",182)) in DEADLINES else 182
	return menace

static func check(civ_id:String,menace:Dictionary)->String:
	## "" or one plain line saying why this message cannot go.
	var gate:=availability(civ_id,String(menace.purpose))
	if gate.has("error"): return String(gate.error)
	if String(menace.token)!="none" and not String(menace.token) in tokens_for(civ_id,String(menace.purpose)): return "Your people have killed none of their fighters; there is no such token to send."
	if menace.has("demand") and not String(menace.demand) in demands_for(civ_id): return "They have done your people no wrong to apologise for."
	if String(menace.get("demand",""))=="hostage" and not Rivals.has_bond(civ_id,["hostage"]).is_empty(): return "Kin of their ruler already lives among your people."
	return ""

static func send(civ_id:String,purpose:String,choice:Dictionary)->Dictionary:
	if not purpose in HOSTILE: return {"error":"Not a message of menace."}
	var menace:=build(purpose,choice)
	var problem:=check(civ_id,menace)
	if problem!="": return {"error":problem}
	var result:Dictionary=WorldSimulation.world.dispatch_diplomat(civ_id,"",purpose)
	if result.has("error"): return result
	var mission:Dictionary=WorldSimulation.world.diplomatic_mission
	if menace.purpose=="demand" or menace.purpose=="ultimatum":
		if String(menace.demand)=="tribute": menace["tribute"]=tribute_terms(civ_id)
	menace["envoy_words"]=envoy_words(civ_id,menace)
	mission["menace"]=menace
	ForeignDiplomacy.remember(civ_id,"Envoys set out to %s." % String(PURPOSES[purpose].line).to_lower().trim_suffix("."))
	return result

# --------------------------------------------------------------------------
# Words (offline presets; the live voice replaces them when it answers)
# --------------------------------------------------------------------------

static func demand_words(civ_id:String,menace:Dictionary)->String:
	match String(menace.get("demand","tribute")):
		"tribute":
			var t:Dictionary=menace.get("tribute",tribute_terms(civ_id))
			return "%d %s from your stores" % [roundi(float(t.amount)),String(t.resource)]
		"ground": return "the ground at the border between our peoples"
		"hostage": return "one of your ruler's own kin, to live among us as a pledge"
		"withdraw": return "that your fighters leave our border and go home"
		"apology": return "that your ruler own %s" % (grievance(civ_id) if grievance(civ_id)!="" else "the wrong done to us")
	return "what is owed"

static func phrasings(civ_id:String,purpose:String,menace:Dictionary)->Array[String]:
	## Preset words for the envoy, in plain speech, era-safe (no goods or
	## tools the peoples may not have).
	var people:=Hall._civ_name(civ_id)
	var home:=String(WorldSimulation.state.settlement_name).strip_edges()
	var god:="the god of %s" % home if home!="" else "our god"
	var out:Array[String]=[]
	match purpose:
		"warn":
			out=["Keep your people away from ours. We will not send words a second time.",
				"%s has seen your fires too close to ours. Move them back." % god.capitalize(),
				"Hunt on your own side of the border. Our patience with %s is not endless." % people]
		"threaten":
			if String(menace.get("by","wrath"))=="spears":
				out=["Count our spears before you answer. We have counted yours.",
					"Cross us again and our fighters will come to your fires.",
					"We have more fighters than you think, and they are ready."]
			else:
				out=["%s is angry with %s. Its anger has fallen on its own people before, and it can fall on yours." % [god.capitalize(),people],
					"Our god has been patient with you. It will not be patient much longer.",
					"You have made our god angry. Pray you do not make it angrier."]
		"demand":
			var d:=demand_words(civ_id,menace)
			out=["Our ruler demands %s. Give it, and there is no quarrel between us." % d,
				"We have come for %s, and we will not go home without an answer." % d,
				"%s. That is what our ruler wants of you." % d.capitalize()]
		"ultimatum":
			var d2:=demand_words(civ_id,menace)
			var when:=String(DEADLINE_WORDS.get(int(menace.get("deadline",182)),"two seasons"))
			var then:=String((CONSEQUENCES.get(String(menace.get("consequence","war")),{}) as Dictionary).get("words","we will act"))
			out=["Our ruler demands %s. You have %s. If it is not done by then, %s." % [d2,when,then],
				"You have %s to give %s. After that, %s." % [when,d2,then],
				"Give %s within %s, or %s. Our ruler will not say it twice." % [d2,when,then]]
	var tags:=CV.era_tags(civ_id)
	var kept:Array[String]=[]
	for line in out:
		if CV.permits(line,tags): kept.append(line)
	return kept if not kept.is_empty() else out

static func envoy_words(civ_id:String,menace:Dictionary)->String:
	if String(menace.get("words",""))!="": return String(menace.words)
	var lines:=phrasings(civ_id,String(menace.purpose),menace)
	var line:=lines[clampi(int(menace.get("phrase",0)),0,lines.size()-1)] if not lines.is_empty() else ""
	var token:=String(menace.get("token","none"))
	if token!="none": line+=" (Your envoy lays %s before their ruler.)" % String(TOKENS[token].label).to_lower()
	return line

# --------------------------------------------------------------------------
# Arrival: the answer, and its real consequences
# --------------------------------------------------------------------------

static func _rng(civ_id:String,day:int)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("menace:%s:%d:%d" % [civ_id,day,int(GameState.world_seed)])
	return rng

static func arrive(mission:Dictionary,day:int)->Dictionary:
	## Called when the envoys reach them. Decides and applies the answer.
	var civ_id:=String(mission.get("civ_id",""))
	var menace:Dictionary=mission.get("menace",{}) if mission.get("menace") is Dictionary else {}
	if menace.is_empty(): menace=build(String(mission.get("purpose","threaten")),{}); mission["menace"]=menace
	var purpose:=String(menace.purpose)
	var rng:=_rng(civ_id,day)
	var s:=standing(civ_id)
	var value:=score(civ_id,menace,s)+rng.randf_range(-0.06,0.06)
	var answer:="comply" if value>=0.0 else "defy"
	if purpose=="warn": answer="heed" if value>=-0.05 else "scorn"
	elif value<=-0.35 and float(s.bold)>0.55 and rng.randf()<0.45: answer="harm"
	var result:={"answer":answer,"score":value,"day":day}
	var name:=Hall._civ_name(civ_id)
	var token:Dictionary=TOKENS.get(String(menace.get("token","none")),TOKENS.none)
	var effects:Array[String]=[]
	match answer:
		"heed":
			Divine.add_civ_dread(civ_id,0.04+float(token.dread)); Hall._shift_relation(civ_id,-0.02,-0.12)
			effects.append("The border should be quieter.")
		"scorn":
			Hall._shift_relation(civ_id,-0.04,0.05); Rivals.grudge(civ_id,"how you warned us off like strays",0.1,"warned:%d" % day)
			_set_stance(civ_id,"defiant",182)
			effects.append("They were not impressed.")
		"comply":
			var dread:=(0.12 if String(menace.by)=="wrath" else 0.06)+float(token.dread)+(0.03 if purpose=="ultimatum" else 0.0)
			Divine.add_civ_dread(civ_id,dread)
			Hall._shift_relation(civ_id,-0.03,-0.2)
			var clause:String={"threaten":"how we were made to bow to your threats","demand":"what we were made to give you","ultimatum":"the ultimatum we were made to obey"}.get(purpose,"what you forced on us")
			Rivals.grudge(civ_id,String(clause),0.12 if purpose=="threaten" else 0.18,"menace:%d" % day)
			if float(token.grudge)>0.0: Rivals.grudge(civ_id,String(token.label).to_lower()+" laid before our ruler",float(token.grudge),"token:%d" % day)
			_set_stance(civ_id,"cowed")
			if purpose=="ultimatum": _shift_credibility(0.05)
			if purpose in ["demand","ultimatum"]:
				var given:=_yield(civ_id,menace,result)
				if given!="": effects.append(given)
			effects.append("Their dread of you has grown, and so has their resentment.")
		"defy":
			Divine.add_civ_dread(civ_id,0.03)
			Hall._shift_relation(civ_id,-0.08,0.15+(0.05 if purpose=="ultimatum" else 0.0))
			Rivals.grudge(civ_id,"the threats your envoys brought us",0.2 if purpose=="threaten" else 0.25,"menace:%d" % day)
			if float(token.grudge)>0.0: Rivals.grudge(civ_id,String(token.label).to_lower()+" laid before our ruler",float(token.grudge),"token:%d" % day)
			_set_stance(civ_id,"defiant")
			var cooled:=_rally(civ_id)
			if cooled!="": effects.append(cooled)
			if float(s.bold)>=0.6 and float(s.ratio)<=1.1:
				_arm(civ_id,0.05)
				effects.append("They are readying their fighters.")
			if purpose=="ultimatum":
				_open_ultimatum(civ_id,menace,day)
				effects.append("Their deadline falls in %s." % Chronicle.date_label(day+int(menace.deadline)))
		"harm":
			var personnel:=maxi(1,int(mission.get("personnel",1)))
			var killed:=clampi(1+rng.randi_range(0,maxi(0,personnel/3-1)),1,maxi(1,personnel-1))
			if personnel<=1: killed=0
			result["killed"]=killed
			result["maimed"]=0 if killed>0 else 1
			Hall._shift_relation(civ_id,-0.1,0.25)
			_set_stance(civ_id,"defiant")
			_shift_credibility(-0.05)
			var wrong:="the envoys they killed at their fire" if killed>0 else "the envoy they maimed"
			(store().wronged_by as Dictionary)[civ_id]={"day":day,"text":wrong,"killed":killed}
			if purpose=="ultimatum": _open_ultimatum(civ_id,menace,day)
			effects.append("%s now owes your people for %s." % [name,wrong])
	result["effects"]=effects
	var words:=_offline_reply(civ_id,menace,result,rng)
	result["envoy_words"]=words.envoy
	result["reply"]=words.reply
	menace["result"]=result
	mission["menace"]=menace
	mission["proposal_resolved"]=true
	mission["accepted"]=answer in ["comply","heed"]
	mission["outcome"]=account(civ_id,menace)
	_log({"civ_id":civ_id,"purpose":purpose,"answer":answer})
	ForeignDiplomacy.remember(civ_id,{"heed":"We heeded the god's warning.","scorn":"We shrugged off the god's warning.","comply":"We gave way to the god's envoys.","defy":"We refused the god's envoys to their faces.","harm":"We laid hands on the god's envoys."}.get(answer,""))
	request_voice(mission)
	return result

static func _yield(civ_id:String,menace:Dictionary,result:Dictionary)->String:
	## The demand, met: a real, bounded change.
	var name:=Hall._civ_name(civ_id)
	var index:=Hall._civ_index(civ_id)
	match String(menace.get("demand","tribute")):
		"tribute":
			var t:Dictionary=menace.get("tribute",tribute_terms(civ_id))
			var amount:=float(t.amount)
			var sent:=0.0
			if Hall.foreign_stock(civ_id,String(t.resource))>=0.0:
				sent=EXCHANGE.take(civ_id,String(t.resource),amount)
			elif String(t.resource)=="Food" and index>=0:
				var civ:Dictionary=WorldSimulation.world.civilizations[index]
				var pop:=maxf(1.0,float(civ.get("population",1.0)))
				sent=minf(amount,maxf(0.0,float(civ.get("food_days",0.0)))*pop*0.3)
				civ["food_days"]=maxf(0.0,float(civ.get("food_days",0.0))-sent/pop)
			result["carry"]={"resource":String(t.resource),"amount":sent}
			return ("%s handed over %d %s; your envoys are carrying it home." % [name,roundi(sent),String(t.resource)]) if sent>=1.0 else "%s had nothing to give." % name
		"ground":
			if index<0: return ""
			var civ2:Dictionary=WorldSimulation.world.civilizations[index]
			var transfer:=minf(0.015,maxf(0.0,float(civ2.get("territory",0.1))-0.08))
			civ2["territory"]=float(civ2.get("territory",0.1))-transfer
			WorldSimulation.world.player_territory_balance=float(WorldSimulation.world.player_territory_balance)+transfer
			Rivals.bond(civ_id,"frontier","the ground we yielded to you",_day()+730)
			Hall._shift_relation(civ_id,0.0,-0.15)
			result["ground"]=transfer
			return "%s pulled its people back from the border ground; it is yours now." % name
		"hostage":
			var serial:=posmod(hash("%s:hostage:%d" % [civ_id,_day()]),90000)+40000
			var woman:=serial%2==0
			var identity:Dictionary=preload("res://scripts/era_names.gd").make(int(GameState.world_seed),serial,woman,civ_id,{Rivals.ruler_name(civ_id):true})
			var kin:=String(identity.get("name","")).get_slice(" ",0)
			if kin=="": kin="a child of their ruler"
			Rivals.bond(civ_id,"hostage","%s of our ruler's house, who lives among your people" % kin,_day()+1095,{"name":kin,"woman":woman})
			Rivals.grudge(civ_id,"our kin you hold as a pledge",0.15,"hostage:%d" % _day())
			Hall._shift_relation(civ_id,0.0,-0.15)
			result["hostage"]=kin
			result["hostage_woman"]=woman
			return "%s, of their ruler's own house, is coming home with your envoys as a pledge for three years." % kin
		"withdraw":
			if index>=0:
				var civ3:Dictionary=WorldSimulation.world.civilizations[index]
				civ3["military_readiness"]=clampf(float(civ3.get("military_readiness",0.3))-0.05,0.1,1.0)
			Hall._shift_relation(civ_id,0.0,-0.3)
			return "%s called its fighters back from the border." % name
		"apology":
			Hall._leader_trust(civ_id,-0.05)
			var metrics:Dictionary=WorldSimulation.state.simulation_metrics
			metrics["legitimacy"]=clampf(float(metrics.get("legitimacy",0.5))+0.01,0.0,1.0)
			(store().wronged_by as Dictionary).erase(civ_id)
			return "Their ruler owned the wrong before your envoys. Your people will hear of it."
	return ""

static func _rally(civ_id:String)->String:
	## A defiant people tells its friends; they cool toward you.
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var names:Array[String]=[]
	for other_id in (civ.get("relations",{}) as Dictionary):
		var link:Dictionary=civ.relations[other_id]
		if bool(link.get("at_war",false)) or not (String(link.get("treaty","none")) in ["trade","non_aggression"] or float(link.get("opinion",0.0))>=0.25): continue
		var friend:=ForeignDiplomacy.civilization(String(other_id))
		if friend.is_empty() or int((friend.get("player_relation",{}) as Dictionary).get("contact_level",0))<1: continue
		Hall._shift_relation(String(other_id),-0.03,0.02)
		names.append(String(friend.get("name",other_id)))
		if names.size()>=3: break
	if names.is_empty(): return ""
	return "Word has gone to their friends (%s), who think less of you for it." % ", ".join(PackedStringArray(names))

static func _arm(civ_id:String,amount:float)->void:
	var index:=Hall._civ_index(civ_id)
	if index<0: return
	var civ:Dictionary=WorldSimulation.world.civilizations[index]
	civ["military_readiness"]=clampf(float(civ.get("military_readiness",0.3))+amount,0.1,1.0)

static func _open_ultimatum(civ_id:String,menace:Dictionary,day:int)->void:
	var list:Array=store().ultimatums
	list.push_front({"civ_id":civ_id,"issued":day,"due":day+int(menace.get("deadline",182)),"demand":String(menace.get("demand","tribute")),"consequence":String(menace.get("consequence","war")),"status":"open","tribute":(menace.get("tribute",{}) as Dictionary).duplicate()})
	while list.size()>ULTIMATUMS_MAX:
		var dropped:=false
		for i in range(list.size()-1,-1,-1):
			if String((list[i] as Dictionary).get("status",""))!="open": list.remove_at(i); dropped=true; break
		if not dropped: list.pop_back()

# --------------------------------------------------------------------------
# The ruler's answer in words
# --------------------------------------------------------------------------

static func _offline_reply(civ_id:String,menace:Dictionary,result:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var persona:=CV.for_foreign_leader(civ_id)
	var purpose:=String(menace.purpose)
	var answer:=String(result.answer)
	var fact:=""
	match answer:
		"heed": fact=_pick(rng,["Tell your ruler we heard. Our people will keep to our side.","We want no quarrel over a hunting ground. We will keep away."])
		"scorn": fact=_pick(rng,["Our hunters go where the game goes. Tell your ruler that.","You sent people all this way to tell us where to walk? Go home."])
		"comply":
			match purpose:
				"threaten": fact=_pick(rng,["Tell your ruler we want no quarrel. We will keep away from your people.","We hear you. There is no need for anger between us."])
				_:
					match String(menace.get("demand","tribute")):
						"tribute":
							var carry:Dictionary=result.get("carry",{})
							fact=("Take the %d %s. Take it and go." % [roundi(float(carry.get("amount",0))),String(carry.get("resource","Food"))]) if float(carry.get("amount",0))>=1.0 else "Take whatever you can find. We have nothing more to give."
						"ground": fact="Have the ground, then. Our people will move back from it."
						"hostage": fact="%s will go with you. See that %s is treated well." % [String(result.get("hostage","My kin")),"she" if bool(result.get("hostage_woman",false)) else "he"]
						"withdraw": fact="Our fighters will come home from the border."
						"apology": fact="I own it. The wrong was ours, and I am sorry for it."
					if purpose=="ultimatum": fact+=" There will be no need for what you threatened."
		"defy":
			match purpose:
				"threaten": fact=_pick(rng,["We are not children to be frightened by words. Come, if you mean it.","Your ruler sends threats instead of fighters. We will see which arrives."])
				"demand": fact=_pick(rng,["You will get nothing from us by asking like this.","No. Tell your ruler to come and take it, if they can."])
				"ultimatum": fact=_pick(rng,["We heard your deadline. Do what you like when it comes.","Count the days if you want. We will not be counting."])
		"harm":
			var killed:=int(result.get("killed",0))
			fact="This is my answer." if killed>0 else "Take this one home, and let your ruler look at him."
	var bank:="farewell_warm" if answer in ["comply","heed"] else "farewell_cold"
	var manner:=String(Rivals._manner_line(persona,bank,rng)) if answer!="harm" else ""
	var reply:=(fact+" "+manner).strip_edges() if manner!="" and rng.randf()<0.6 else fact
	var envoy:=String(menace.get("envoy_words",""))
	if envoy=="": envoy=envoy_words(civ_id,menace)
	return {"envoy":envoy,"reply":reply}

static func _pick(rng:RandomNumberGenerator,lines:Array)->String:
	return String(lines[rng.randi_range(0,lines.size()-1)])

static func account(civ_id:String,menace:Dictionary)->String:
	## The whole return, as the court hears it.
	var result:Dictionary=menace.get("result",{})
	var voiced:Dictionary=menace.get("voiced",{}) if menace.get("voiced") is Dictionary else {}
	var envoy:=String(voiced.get("envoy_words",result.get("envoy_words","")))
	var reply:=String(voiced.get("reply",result.get("reply","")))
	var ruler:=Rivals.ruler_name(civ_id)
	var text:=""
	if String(result.get("answer",""))=="harm":
		var killed:=int(result.get("killed",0))
		text="Your envoy reports: “%s”\n\n%s answered with violence. %s" % [envoy,ruler,("%d of your envoys were killed; the rest were sent home to tell you." % killed) if killed>0 else "One of your envoys was maimed and sent home to tell you."]
		if reply!="": text+=" Their last words: “%s”" % reply
	else:
		text="Your envoy reports: “%s”\n\n%s answered: “%s”" % [envoy,ruler,reply]
	var effects:Array=result.get("effects",[])
	if not effects.is_empty(): text+="\n\n"+" ".join(PackedStringArray(effects))
	return text

# --------------------------------------------------------------------------
# Homecoming
# --------------------------------------------------------------------------

static func homecoming(mission:Dictionary,day:int)->void:
	var civ_id:=String(mission.get("civ_id",""))
	var menace:Dictionary=mission.get("menace",{}) if mission.get("menace") is Dictionary else {}
	var result:Dictionary=menace.get("result",{}) if menace.get("result") is Dictionary else {}
	if result.is_empty() or bool(result.get("home",false)): return
	result["home"]=true
	var killed:=int(result.get("killed",0))
	if killed>0:
		WorldSimulation.state.register_population_deaths(killed,"killed as envoys")
		mission["personnel"]=maxi(1,int(mission.get("personnel",1))-killed)
		WorldSimulation.world._record_world_event("Envoys killed","%s killed %d of your envoys at its fire. The survivors are home." % [Hall._civ_name(civ_id),killed],"diplomacy",day)
	var carry:Dictionary=result.get("carry",{}) if result.get("carry") is Dictionary else {}
	if float(carry.get("amount",0.0))>0.0:
		EXCHANGE.receive("player",String(carry.resource),float(carry.amount))
	mission["outcome"]=account(civ_id,menace)
	# The exchange joins the conversation with their ruler, as any envoy's does.
	var dialogue=WorldSimulation.dialogue
	if dialogue!=null and dialogue.has_method("_append"):
		var voiced:Dictionary=menace.get("voiced",{}) if menace.get("voiced") is Dictionary else {}
		dialogue._append(civ_id,"envoy",String(voiced.get("envoy_words",result.get("envoy_words",""))))
		var reply:=String(voiced.get("reply",result.get("reply","")))
		if reply!="": dialogue._append(civ_id,"assistant",reply)
		var t:Dictionary=dialogue.thread(civ_id)
		t["reply"]=reply
		t["status"]="Your envoys are home with this answer."

# --------------------------------------------------------------------------
# Deadlines
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	if WorldSimulation.actor_id!="player": return
	for u in store().ultimatums:
		if not u is Dictionary or String(u.status)!="open": continue
		var civ_id:=String(u.civ_id)
		var civ:=ForeignDiplomacy.civilization(civ_id)
		if civ.is_empty() or not bool(civ.get("alive",true)): u["status"]="void"; continue
		var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
		var at_war:=bool(relation.get("at_war",false)) and int(relation.get("war_started_day",-1))>=int(u.issued)
		if String(u.consequence)=="war" and at_war: _kept(u,day); continue
		if day<int(u.due): continue
		if not bool(u.get("reconsidered",false)):
			# At the deadline they weigh it again: dread may have grown.
			u["reconsidered"]=true
			var menace:={"purpose":"ultimatum","by":"wrath","demand":String(u.demand),"consequence":String(u.consequence),"tribute":u.get("tribute",{})}
			if score(civ_id,menace)>=0.12:
				var result:={}
				var given:=_yield(civ_id,menace,result)
				var carry:Dictionary=result.get("carry",{})
				if float(carry.get("amount",0.0))>0.0: EXCHANGE.receive("player",String(carry.resource),float(carry.amount))
				u["status"]="met"
				_shift_credibility(0.08); Divine.add_civ_dread(civ_id,0.06); _set_stance(civ_id,"cowed")
				_announce("%s Gives Way" % Hall._civ_name(civ_id).substr(0,40),"As your deadline came, %s gave way. %s" % [Hall._civ_name(civ_id),given],civ_id,"moment")
				ForeignDiplomacy.remember(civ_id,"At the deadline we gave the god what it demanded.")
				continue
		if String(u.consequence)=="sever":
			_sever(civ_id)
			_kept(u,day)
			continue
		if day>=int(u.due)+GRACE_DAYS: _broken(u,day)

static func _kept(u:Dictionary,day:int)->void:
	var civ_id:=String(u.civ_id)
	u["status"]="kept"; u["closed"]=day
	_shift_credibility(0.12)
	Divine.add_civ_dread(civ_id,0.10)
	for civ:Dictionary in WorldSimulation.world.civilizations:
		var other:=String(civ.get("id",""))
		if other=="" or other==civ_id or not bool(civ.get("alive",true)): continue
		if int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))>=2: Divine.add_civ_dread(other,0.03)
	var what:="war" if String(u.consequence)=="war" else "the closing of the frontier"
	_announce("A Threat Kept","You did what you told %s you would do: %s. Every people that hears of it will fear your word a little more." % [Hall._civ_name(civ_id),what],civ_id,"notice")
	ForeignDiplomacy.remember(civ_id,"The god did what it threatened. Its word is not empty.")

static func _broken(u:Dictionary,day:int)->void:
	var civ_id:=String(u.civ_id)
	u["status"]="broken"; u["closed"]=day
	_shift_credibility(-0.2)
	var d:=store_dread(civ_id)
	(Divine.store().civ_dread as Dictionary)[civ_id]={"v":maxf(0.0,d-0.15),"day":day}
	_set_stance(civ_id,"emboldened",540)
	Hall._shift_relation(civ_id,-0.02,0.0)
	_announce("An Empty Threat","%s refused your ultimatum and nothing happened. You swore %s and did not. Other peoples will weigh your threats more lightly now, and %s will ask more of you." % [Hall._civ_name(civ_id),String(CONSEQUENCES[String(u.consequence)].words).replace("we will ","to "),Hall._civ_name(civ_id)],civ_id,"moment")
	ForeignDiplomacy.remember(civ_id,"The god threatened war and never came. We laughed about it at the fire.")

static func store_dread(civ_id:String)->float:
	return Divine.civ_dread(civ_id)

static func _sever(civ_id:String)->void:
	var index:=Hall._civ_index(civ_id)
	if index<0: return
	var civ:Dictionary=WorldSimulation.world.civilizations[index]
	var relation:Dictionary=civ.get("player_relation",{})
	if String(relation.get("treaty","none")) in ["trade","non_aggression"]: relation["treaty"]="none"
	relation["trade"]=0.0
	relation["stance"]="watchful"
	relation["border_tension"]=clampf(float(relation.get("border_tension",0.0))+0.1,0.0,1.0)
	civ["player_relation"]=relation
	var pacts:=load(PACTS_PATH) as GDScript
	if pacts!=null:
		for pact in pacts.call("pacts",civ_id,true):
			if pact is Dictionary: pacts.call("cancel",String(pact.get("id","")),"player")

static func _announce(title:String,text:String,civ_id:String,tier:String)->void:
	Rivals._record(title,text,civ_id,tier)
	WorldSimulation.world._record_world_event(title,text,"diplomacy",_day())

# --------------------------------------------------------------------------
# Rivals answer in kind (weights only; the pace of visits is the hall's)
# --------------------------------------------------------------------------

static func rival_weight(situation_type:String,civ_id:String)->float:
	var kind:=stance(civ_id)
	var low:=credibility()<=0.35
	match situation_type:
		"tribute_demand","emboldened_demand":
			if kind=="cowed": return 0.4
			if kind=="emboldened": return 1.8
			if kind=="defiant": return 1.3
			return 1.3 if low else 1.0
		"test_of_resolve":
			if kind=="cowed": return 0.4
			if kind in ["defiant","emboldened"]: return 1.6
			return 1.2 if low else 1.0
		"dread_tribute":
			if kind=="cowed": return 1.6
			if kind=="emboldened": return 0.3
	return 1.0

# --------------------------------------------------------------------------
# The live voice: the envoy and the ruler speak in their own words, but the
# answer and its consequences were already decided by the engine.
# --------------------------------------------------------------------------

const VOICE_PROMPT:="""Speak as the named foreign leader in this fictional early-historical simulation. A god-ruler of another people sent an envoy with a message of menace. First write envoy_words: the envoy's own concise, in-world rendering of the god's message (do not copy the god's words verbatim). Then write reply: only the leader's spoken answer to the envoy. The outcome is ALREADY DECIDED and your reply must convey exactly it: OUTCOME. Do not invent any other transfer, promise, war, death, number or agreement. Speak plainly and concretely about the actual situation; never invent maxims, proverbs or riddles. Mention nothing the leader's people could not know or own in their era (see era). Never mention a game, system, screen, message, channel or rules. Return JSON: envoy_words (1–600 characters), reply (1–900 characters)."""

static func voice_available()->bool:
	return PronouncementInterpreter!=null and not PronouncementInterpreter._api_config().is_empty()

static func outcome_brief(civ_id:String,menace:Dictionary)->String:
	var result:Dictionary=menace.get("result",{})
	match String(result.get("answer","")):
		"heed": return "the leader heeds the warning and says their people will keep away"
		"scorn": return "the leader shrugs off the warning"
		"comply":
			var what:=demand_words(civ_id,menace) if menace.has("demand") else "to keep the peace"
			if String(menace.get("demand",""))=="tribute": what="%d %s" % [roundi(float((result.get("carry",{}) as Dictionary).get("amount",0))),String((result.get("carry",{}) as Dictionary).get("resource","Food"))]
			return "the leader gives way and agrees: %s" % what
		"defy": return "the leader refuses outright and is not afraid"
		"harm": return "the leader refuses and has %d of the envoys killed; the reply is the leader's last words to the survivors" % int(result.get("killed",0)) if int(result.get("killed",0))>0 else "the leader refuses and has one envoy maimed"
	return "the leader refuses"

static func request_voice(mission:Dictionary)->bool:
	var menace:Dictionary=mission.get("menace",{})
	if String(menace.get("words",""))=="" or not voice_available(): return false
	var config:Dictionary=PronouncementInterpreter._api_config()
	var civ_id:=String(mission.get("civ_id",""))
	var leader:=ForeignDiplomacy.leader(civ_id)
	var context:={"leader":String(leader.get("name","")),"people":Hall._civ_name(civ_id),"era":CV.era_tags(civ_id),"manner":String(Rivals.rival_character(civ_id).get("voice_name","")),
		"message_kind":String(menace.purpose),"backed_by":String(BY[String(menace.get("by","wrath"))].label),"token":String(TOKENS[String(menace.get("token","none"))].label)}
	if menace.has("demand"): context["demand"]=demand_words(civ_id,menace)
	if menace.has("deadline"): context["deadline"]=String(DEADLINE_WORDS.get(int(menace.deadline),"two seasons"))
	if menace.has("consequence"): context["consequence"]=String(CONSEQUENCES[String(menace.consequence)].words)
	var messages:=[{"role":"system","content":VOICE_PROMPT.replace("OUTCOME",outcome_brief(civ_id,menace))},{"role":"system","content":"KNOWN: "+JSON.stringify(context)},{"role":"user","content":"THE GOD'S WORDS TO THE ENVOY: "+JSON.stringify(String(menace.words))}]
	var payload:={"model":config.model,"messages":messages,"max_completion_tokens":900}
	if bool(config.get("structured_output",false)):
		payload["response_format"]={"type":"json_schema","json_schema":{"name":"envoy_menace","strict":true,"schema":{"type":"object","additionalProperties":false,"properties":{"envoy_words":{"type":"string"},"reply":{"type":"string"}},"required":["envoy_words","reply"]}}}
	var host:Node=WorldSimulation.dialogue as Node
	if host==null: return false
	var http:=HTTPRequest.new(); host.add_child(http); http.timeout=40; http.max_redirects=0; http.body_size_limit=65536
	var depart:=int(mission.get("depart_day",-1))
	http.request_completed.connect(func(result:int,code:int,_h:PackedStringArray,body:PackedByteArray)->void:
		http.queue_free()
		if result!=HTTPRequest.RESULT_SUCCESS or code<200 or code>=300: return
		var envelope:Variant=JSON.parse_string(body.get_string_from_utf8())
		if not envelope is Dictionary: return
		var choices:Variant=envelope.get("choices",[])
		if not choices is Array or (choices as Array).is_empty() or not choices[0] is Dictionary: return
		var content:=String(PronouncementInterpreter._content_text((choices[0] as Dictionary).get("message",{}).get("content","")))
		var value:Variant=JSON.parse_string(content.trim_prefix("```json").trim_suffix("```").strip_edges())
		var live:Dictionary=WorldSimulation.world.diplomatic_mission
		if String(live.get("civ_id",""))==civ_id and int(live.get("depart_day",-2))==depart: accept_voice(live,value))
	var error:=http.request(String(config.endpoint),PackedStringArray(["Content-Type: application/json","Authorization: Bearer "+String(config.api_key)]),HTTPClient.METHOD_POST,JSON.stringify(payload))
	if error!=OK: http.queue_free(); return false
	return true

static func accept_voice(mission:Dictionary,value:Variant)->bool:
	## Validated, bounded: the live words replace the preset ones only if they
	## stay in character and in era, and the envoys are not home yet.
	var menace:Dictionary=mission.get("menace",{})
	var result:Dictionary=menace.get("result",{}) if menace.get("result") is Dictionary else {}
	if result.is_empty() or bool(result.get("home",false)): return false
	if not value is Dictionary or not value.get("envoy_words") is String or not value.get("reply") is String: return false
	var envoy:=String(value.envoy_words).strip_edges()
	var reply:=String(value.reply).strip_edges()
	if envoy.is_empty() or reply.is_empty() or envoy.length()>600 or reply.length()>900: return false
	var dialogue=WorldSimulation.dialogue
	if dialogue!=null and dialogue.has_method("_reply_stays_in_character") and (not dialogue._reply_stays_in_character(reply) or not dialogue._reply_stays_in_character(envoy)): return false
	if dialogue!=null and dialogue.has_method("_envoy_uses_own_words") and not dialogue._envoy_uses_own_words(String(menace.get("words","")),envoy): return false
	var tags:=CV.era_tags(String(mission.get("civ_id","")))
	if not CV.permits(reply,tags) or not CV.permits(envoy,tags): return false
	reply=preload("res://scripts/plain_speech.gd").strip_or_keep(reply)
	if reply.strip_edges().is_empty(): return false
	menace["voiced"]={"envoy_words":envoy,"reply":reply}
	mission["outcome"]=account(String(mission.get("civ_id","")),menace)
	return true
