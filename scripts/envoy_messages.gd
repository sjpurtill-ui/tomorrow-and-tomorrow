extends RefCounted
const AiWire:=preload("res://scripts/ai_wire.gd")
## What an envoy carries, and what a message of menace does when it lands.
##
## The catalogue: every purpose the court's compose area offers, with the gift
## each allows (required, optional, food only or none) and whether a token of
## menace may go instead.
##
## Menace: warn, threaten, demand and ultimatum. The receiving ruler answers
## when the envoys arrive (CivilizationSystem._process_diplomatic_mission calls
## arrive()). The answer follows what the court can see of them: reverence
## (awe of the god) and dread (fear of it), then the two peoples' fighting
## strength, whether the god's past threats were kept, their ruler's temper,
## grudges and friends, and how much is asked. A god's wrath works through
## awe and fear; our spears work through strength. They give way (awed,
## terrified or grudging: a real, bounded change such as tribute from their
## ledger, ground off their territory, kin sent as a pledge, fighters stood
## down, a wrong owned), refuse (proud, scornful, backed by friends, or, for a
## revering people asked too much, shaken and betrayed), or lay hands on the
## messengers (envoys die; the survivors bring the news).
##
## The answer comes home into the court conversation with that ruler: your
## words, your envoy's account, the ruler's reply (voiced live when the AI is
## on, from the decided outcome and rich facts; otherwise several sentences in
## their own manner) and a plain note of what is now in motion.
##
## A refused ultimatum stands until its deadline. They may give way late;
## otherwise the court hears the deadline has passed. "Close the frontier" is
## carried out by your people at once. "War" is on you: declare it within a
## season or the threat is broken, and every people learns your threats can be
## empty. Kept threats raise credibility and dread everywhere.
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
## gift: required | optional | food | none. token: a token of menace may go.
const PURPOSES:={
	"goodwill":{"label":"Goodwill","line":"Good words and a gift from your stores.","group":"friendship","gift":"required","token":false},
	"open_trade":{"label":"Open trade","line":"Ask for a standing compact to trade fairly.","group":"friendship","gift":"optional","token":false},
	"non_aggression":{"label":"Promise of peace","line":"Ask that neither people raid the other.","group":"friendship","gift":"optional","token":false},
	"send_aid":{"label":"Food aid","line":"Carry food to a people who need it.","group":"friendship","gift":"food","token":false},
	"leader_parley":{"label":"Speak with their ruler","line":"Carry your own words to their ruler and bring the answer home.","group":"talk","gift":"none","token":false},
	"seek_peace":{"label":"Seek peace","line":"Ask for a truce to end the war.","group":"war","gift":"optional","token":false},
	"declare_war":{"label":"Declare war","line":"Tell them to their face that war has begun.","group":"war","gift":"none","token":true},
	"warn":{"label":"Warn them off","line":"Tell them to keep away from your people.","group":"menace","gift":"none","token":true},
	"threaten":{"label":"Threaten","line":"Make them afraid of what you could do.","group":"menace","gift":"none","token":true},
	"demand":{"label":"Demand","line":"Ask for something they would rather keep.","group":"menace","gift":"none","token":true},
	"ultimatum":{"label":"Ultimatum","line":"A demand, a deadline, and what you will do if it passes.","group":"menace","gift":"none","token":true},
}
const BY:={"wrath":{"label":"The god's wrath","line":"Their awe and fear of you as a god."},"spears":{"label":"Our warriors","line":"Your fighters against theirs."}}
const DEMANDS:={
	"tribute":{"label":"Tribute","line":"A share of their stores, carried home by your envoys.","ask":0.0},
	"ground":{"label":"Yield ground","line":"They give up land at the border.","ask":0.20},
	"hostage":{"label":"A hostage","line":"Kin of their ruler comes to live among your people as a pledge.","ask":0.30},
	"withdraw":{"label":"Pull back","line":"Their fighters stand down and leave the border.","ask":0.10},
	"apology":{"label":"An apology","line":"Their ruler owns a wrong done to your people.","ask":0.08},
	# They bow for good (world_answer.gd): tribute every season through the
	# trade ledger, a hostage at our court, their raiders kept home.
	"submit":{"label":"Bow to us","line":"They become tributaries: tribute every season and a son of their ruler's house as a pledge; their raiders stay home while they pay.","ask":0.32},
}
## Tribute sizes: the share of their stock of that good, and what it weighs.
const SIZES:={
	"modest":{"label":"Modest","share":0.08,"ask":0.06,"line":"Enough to notice. They can bear it."},
	"heavy":{"label":"Heavy","share":0.18,"ask":0.14,"line":"It will hurt them this year."},
	"crushing":{"label":"Crushing","share":0.35,"ask":0.26,"line":"A third of what they hold. Outrageous to a friend."},
}
## What a revering people finds outrageous from the god it honours: asked
## this, awe turns to a sense of betrayal (weighted by their awe).
const OUTRAGE:={"crushing":0.30,"hostage":0.20,"ground":0.10}
const TRIBUTE_GOODS:=["Food","Timber","Stone","Clay","Fiber Plants"]
const CONSEQUENCES:={
	"war":{"label":"War","line":"You make war on them. If you do not, your threats lose their weight."},
	"sever":{"label":"Close the frontier","line":"Every compact and standing exchange with them ends at the deadline."},
}
## What the consequence is called, matched to what backs the message.
## voice: "god" (the god's own words), "envoy" (the envoy telling the god),
## "plain" (facts for the live voice).
const CONSEQUENCE_WORDS:={
	"war":{"wrath":{"god":"I will send my people against you with spears","envoy":"you will send your people against them with spears","plain":"the god will send its people against them with spears"},
		"spears":{"god":"my warriors will come against you","envoy":"your warriors will come against them","plain":"the god's warriors will come against them"}},
	"sever":{"wrath":{"god":"I will turn my face from you, and every path and exchange between our peoples will close","envoy":"you will turn your face from them and close every path and exchange between your peoples","plain":"the god will turn its face from them and every path and exchange between the peoples will close"},
		"spears":{"god":"I will close every path between us and end every exchange","envoy":"you will close every path between your peoples and end every exchange","plain":"the god's people will close every path between the peoples and end every exchange"}},
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
## Uniform swing on each answer; the preview's chance comes from it.
const NOISE:=0.06

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
	if not data is Dictionary or JSON.stringify(data).length()>12000: return false
	if not String(data.get("purpose","")) in HOSTILE: return false
	if data.has("by") and not String(data.by) in BY: return false
	if data.has("demand") and String(data.demand)!="" and not String(data.demand) in DEMANDS: return false
	if data.has("size") and not String(data.size) in SIZES: return false
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
		"required": return resource!=""
		"optional": return true
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
	if not bool((load("res://scripts/world_answer.gd") as GDScript).call("is_tributary",civ_id)): out.append("submit")
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

# --------------------------------------------------------------------------
# Tribute: sized to matter to them
# --------------------------------------------------------------------------

static func their_stock(civ_id:String,resource:String)->Dictionary:
	## {amount, known}: their ledger when it exists, else an estimate from
	## their size and days of food (never zero for Food).
	var ledger:=Hall.foreign_stock(civ_id,resource)
	if ledger>=0.0: return {"amount":ledger,"known":true}
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var pop:=maxf(20.0,float(civ.get("population",100.0)))
	if resource=="Food": return {"amount":pop*maxf(20.0,float(civ.get("food_days",30.0))),"known":false}
	return {"amount":pop*(0.6 if resource=="Timber" else 0.3),"known":false}

static func tribute_terms(civ_id:String,resource:String="",size:String="heavy")->Dictionary:
	## What a tribute demand asks: a real share of what they hold of a good.
	## With no good named, the one they hold most of.
	if not size in SIZES: size="heavy"
	var best:=resource
	if not best in TRIBUTE_GOODS:
		best="Food"; var most:=-1.0
		for good:String in TRIBUTE_GOODS:
			var have:=float(their_stock(civ_id,good).amount)
			if have>most: most=have; best=good
	var stock:=their_stock(civ_id,best)
	var have2:=float(stock.amount)
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var pop:=maxf(20.0,float(civ.get("population",100.0)))
	var share:=float(SIZES[size].share)
	# Never trivial: at least a few days' food for every one of them (or the
	# like for other goods), never more than the share of what they hold.
	var floor_amount:=pop*(2.0 if best=="Food" else 0.1)*share/0.08
	var amount:=maxf(have2*share,minf(floor_amount,have2*0.35))
	amount=minf(amount,have2*0.35)
	return {"resource":best,"amount":Hall._nice(maxf(1.0,amount)),"size":size,"stock":have2,"known":bool(stock.known),"share":share}

static func tribute_options(civ_id:String)->Array[Dictionary]:
	## Each good they hold, with what a heavy demand would take.
	var out:Array[Dictionary]=[]
	for good:String in TRIBUTE_GOODS:
		var stock:=their_stock(civ_id,good)
		if float(stock.amount)<5.0: continue
		out.append({"resource":good,"stock":float(stock.amount),"known":bool(stock.known)})
	return out

# --------------------------------------------------------------------------
# Standing and the likely answer
# --------------------------------------------------------------------------

static func _lives()->GDScript:
	return load(LIVES_PATH) as GDScript

static func standing(civ_id:String)->Dictionary:
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
	# Exactly what the court's portrait shows: reverence and dread.
	var regard:=Divine.foreign_regard(civ_id)
	var world=WorldSimulation.world
	var theirs:=maxf(1.0,float(world._military_power(civ))) if not civ.is_empty() and civ.has("military_population") else 1.0
	var ours:=maxf(1.0,float(world._player_military_power()))
	var ratio:=clampf(ours/theirs,0.25,4.0)
	var p:=Hall._personality(civ_id)
	var bold:=(float(p.get("assertiveness",0.5))+float(p.get("risk_tolerance",0.5)))*0.5
	var trait_id:=String(Rivals.character(civ_id).get("trait",""))
	var friends:Array[String]=[]
	for other_id in (civ.get("relations",{}) as Dictionary):
		var link:Dictionary=civ.relations[other_id]
		if bool(link.get("at_war",false)) or not (String(link.get("treaty","none")) in ["trade","non_aggression"] or float(link.get("opinion",0.0))>=0.25): continue
		var index:=Hall._civ_index(String(other_id))
		if index>=0: friends.append(String(WorldSimulation.world.civilizations[index].get("name",other_id)))
	return {"reverence":float(regard.get("love",0.5)),"dread":float(regard.get("dread",0.0)),"ratio":ratio,"credibility":credibility(),"bold":bold,"trait":trait_id,
		"partners":friends.size(),"friends":friends,"grudge":Rivals.grudge_weight(civ_id),"opinion":float(relation.get("opinion",0.0)),
		"hostage":not Rivals.has_bond(civ_id,["hostage"]).is_empty(),"stance":stance(civ_id)}

static func ask_of(menace:Dictionary)->float:
	var purpose:=String(menace.get("purpose","threaten"))
	var demand:=String(menace.get("demand","tribute"))
	var base:=float((DEMANDS.get(demand,{}) as Dictionary).get("ask",0.1))
	if demand=="tribute": base=float((SIZES.get(String(menace.get("size","heavy")),SIZES.heavy) as Dictionary).ask)
	match purpose:
		"warn": return 0.0
		"threaten": return 0.05
		"demand": return base
		"ultimatum": return base-(0.06 if String(menace.get("consequence","war"))=="war" else 0.03)
	return 0.1

static func awe_of(s:Dictionary)->float:
	## 0 below reverence 0.45, 1 at full reverence.
	return clampf((float(s.reverence)-0.45)/0.55,0.0,1.0)

static func score(civ_id:String,menace:Dictionary,view:Dictionary={})->float:
	## At or above zero they give way; below, they refuse. No dice here.
	var s:=view if not view.is_empty() else standing(civ_id)
	var wrath:=String(menace.get("by","wrath"))=="wrath"
	var might:=clampf(log(float(s.ratio))/log(2.0)*0.25,-0.5,0.5)
	var awe:=awe_of(s)*0.55
	var fear:=float(s.dread)*0.6
	var word:=(float(s.credibility)-0.5)*0.3
	# The god's wrath works through awe and fear; our warriors through strength.
	var backing:=(awe+fear+word+might*0.3) if wrath else (might+fear*0.3+word*0.6)
	var pride:=(float(s.bold)-0.5)*0.5+(0.08 if String(s.trait) in ["grudge","bluffer"] else 0.0)
	# Friends shield you from spears far better than from a god.
	var allies:=minf(3.0,float(s.partners))*(0.02 if wrath else 0.05)
	var grudge:=minf(0.25,float(s.grudge)*0.1)
	var hate:=maxf(0.0,-float(s.opinion))*0.2
	var token:=float((TOKENS.get(String(menace.get("token","none")),{}) as Dictionary).get("weight",0.0))
	var mood:=0.1 if String(s.stance)=="cowed" else (-0.1 if String(s.stance) in ["emboldened","defiant"] else 0.0)
	var outrage:=0.0
	if wrath:
		var what:=String(menace.get("size","")) if String(menace.get("demand",""))=="tribute" else String(menace.get("demand",""))
		outrage=float(OUTRAGE.get(what,0.0))*awe_of(s)
	return 0.05+backing-outrage-pride-allies-grudge-hate-ask_of(menace)+(0.12 if bool(s.hostage) else 0.0)+token+mood

static func chance(value:float,warn:bool=false)->float:
	## The chance the answer is yes, given the uniform swing.
	var line:=-0.05 if warn else 0.0
	return clampf((value-line+NOISE)/(2.0*NOISE),0.0,1.0)

static func forecast(civ_id:String,menace:Dictionary)->Dictionary:
	var s:=standing(civ_id)
	var value:=score(civ_id,menace,s)
	var warn:=String(menace.get("purpose",""))=="warn"
	var p:=chance(value,warn)
	var harm_possible:=not warn and value<=-0.3 and float(s.bold)>0.55 and float(s.reverence)<0.5
	var words:=""
	if warn: words="They will almost surely heed you." if p>=0.9 else ("They will probably heed you." if p>=0.6 else ("It could go either way." if p>=0.4 else "They will probably shrug it off."))
	else:
		if p>=0.9: words="They will almost surely give way."
		elif p>=0.6: words="They will probably give way."
		elif p>=0.4: words="It could go either way."
		elif harm_possible: words="They will refuse, and may lay hands on your envoys."
		else: words="They will probably refuse."
	var why:Array[String]=[]
	var wrath:=String(menace.get("by","wrath"))=="wrath"
	if wrath and float(s.reverence)>=0.62: why.append("they revere you")
	elif wrath and float(s.reverence)<0.45: why.append("they do not revere you")
	if float(s.dread)>=0.35: why.append("they dread you")
	elif float(s.dread)<0.12 and float(s.reverence)<0.62: why.append("they have little fear of you")
	if float(s.ratio)>=1.5: why.append("your fighters outnumber theirs")
	elif float(s.ratio)<=0.7: why.append("their fighters outnumber yours")
	if float(s.credibility)<=0.35: why.append("your past threats came to nothing")
	elif float(s.credibility)>=0.65: why.append("your threats have been carried out before")
	if float(s.bold)>=0.62: why.append("their ruler is proud")
	if int(s.partners)>=2 and not wrath: why.append("they have friends")
	if float(s.grudge)>=0.4: why.append("they hold grudges against you")
	var outrageous:=String(menace.get("size",""))=="crushing" if String(menace.get("demand",""))=="tribute" else String(menace.get("demand","")) in ["hostage"]
	if wrath and outrageous and float(s.reverence)>=0.62: why.append("so much, from the god they honour, would feel like betrayal")
	return {"score":value,"chance":p,"answer":"comply" if value>=0.0 else "defy","words":words,"why":why,"harm_possible":harm_possible,"standing":s}

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
		if String(menace.demand)=="tribute":
			menace["size"]=String(choice.get("size","heavy")) if String(choice.get("size","heavy")) in SIZES else "heavy"
			menace["good"]=String(choice.get("good","")) if String(choice.get("good","")) in TRIBUTE_GOODS else ""
	if purpose=="ultimatum":
		menace["consequence"]=String(choice.get("consequence","war")) if String(choice.get("consequence","war")) in CONSEQUENCES else "war"
		menace["deadline"]=int(choice.get("deadline",182)) if int(choice.get("deadline",182)) in DEADLINES else 182
	return menace

static func priced(civ_id:String,menace:Dictionary)->Dictionary:
	## The record with its tribute sized against their stores now.
	if String(menace.get("demand",""))=="tribute": menace["tribute"]=tribute_terms(civ_id,String(menace.get("good","")),String(menace.get("size","heavy")))
	return menace

static func check(civ_id:String,menace:Dictionary)->String:
	## "" or one plain line saying why this message cannot go.
	var gate:=availability(civ_id,String(menace.purpose))
	if gate.has("error"): return String(gate.error)
	if String(menace.token)!="none" and not String(menace.token) in tokens_for(civ_id,String(menace.purpose)): return "Your people have killed none of their fighters; there is no such token to send."
	if menace.has("demand") and String(menace.demand)=="submit" and bool((load("res://scripts/world_answer.gd") as GDScript).call("is_tributary",civ_id)): return "%s already bows to you and pays its tribute." % Hall._civ_name(civ_id)
	if menace.has("demand") and not String(menace.demand) in demands_for(civ_id): return "They have done your people no wrong to apologise for."
	if String(menace.get("demand",""))=="hostage" and not Rivals.has_bond(civ_id,["hostage"]).is_empty(): return "Kin of their ruler already lives among your people."
	return ""

static func send(civ_id:String,purpose:String,choice:Dictionary)->Dictionary:
	if not purpose in HOSTILE: return {"error":"Not a message of menace."}
	var menace:=priced(civ_id,build(purpose,choice))
	var problem:=check(civ_id,menace)
	if problem!="": return {"error":problem}
	var result:Dictionary=WorldSimulation.world.dispatch_diplomat(civ_id,"",purpose)
	if result.has("error"): return result
	var mission:Dictionary=WorldSimulation.world.diplomatic_mission
	menace["brief"]=brief(civ_id,menace)
	mission["menace"]=menace
	# Your own words open the exchange in the conversation with their ruler.
	var dialogue=WorldSimulation.dialogue
	if dialogue!=null and dialogue.has_method("_append"):
		dialogue._append(civ_id,"user",String(menace.brief))
		dialogue.thread(civ_id)["status"]="Your envoys are on the road with your message."
		if dialogue.has_signal("changed"): dialogue.changed.emit(civ_id)
	return result

# --------------------------------------------------------------------------
# Words
# --------------------------------------------------------------------------

static func _god(civ_id:String="")->String:
	# Our nation's name once given ("the god of the Reedfolk"), else the home town's.
	var nation:=String(WorldSimulation.state.nation_name).strip_edges()
	if nation!="": return "the god of %s" % preload("res://scripts/nation_name.gd").in_sentence(nation)
	var home:=String(WorldSimulation.state.settlement_name).strip_edges()
	return "the god of %s" % home if home!="" else "our god"

static func demand_words(civ_id:String,menace:Dictionary,speaker:String="us")->String:
	## The demand as a noun phrase. speaker "us": our envoy to them.
	match String(menace.get("demand","tribute")):
		"tribute":
			var t:Dictionary=menace.get("tribute",{}) if menace.get("tribute") is Dictionary and not (menace.tribute as Dictionary).is_empty() else tribute_terms(civ_id,String(menace.get("good","")),String(menace.get("size","heavy")))
			return "%d %s from your stores" % [roundi(float(t.amount)),String(t.resource).to_lower()]
		"ground": return "the ground at the border between our peoples"
		"hostage": return "one of your ruler's own kin, to live among us as a pledge"
		"withdraw": return "that your fighters leave our border and go home"
		"apology": return "that your ruler own %s" % (grievance(civ_id) if grievance(civ_id)!="" else "the wrong done to us")
		"submit": return "that your people bow to %s: tribute every season, and a son of your ruler's house among us as a pledge" % _god(civ_id)
	return "what is owed"

static func short_demand(civ_id:String,menace:Dictionary)->String:
	## The demand as the ruler names it back: "340 food", "the border ground".
	match String(menace.get("demand","tribute")):
		"tribute":
			var t:Dictionary=menace.get("tribute",{}) if menace.get("tribute") is Dictionary and not (menace.tribute as Dictionary).is_empty() else tribute_terms(civ_id,String(menace.get("good","")),String(menace.get("size","heavy")))
			return "%d %s" % [roundi(float(t.amount)),String(t.resource).to_lower()]
		"ground": return "the border ground"
		"hostage": return "one of my own kin"
		"withdraw": return "our fighters off the border"
		"apology": return "an apology"
		"submit": return "that we bow to you"
	return "what you ask"

static func consequence_words(menace:Dictionary,voice:String="god")->String:
	var by:=String(menace.get("by","wrath"))
	var by_words:Dictionary=(CONSEQUENCE_WORDS.get(String(menace.get("consequence","war")),CONSEQUENCE_WORDS.war) as Dictionary).get(by,CONSEQUENCE_WORDS.war.wrath)
	return String(by_words.get(voice,by_words.plain))

static func phrasings(civ_id:String,purpose:String,menace:Dictionary)->Array[String]:
	## What the god says, in plain speech, era-safe. Backing and consequence
	## always agree: the god's wrath names the god; our warriors name warriors.
	var people:=Hall._civ_name(civ_id)
	var wrath:=String(menace.get("by","wrath"))=="wrath"
	var out:Array[String]=[]
	match purpose:
		"warn":
			out=["Keep your people away from ours. I will not send words a second time.",
				"I have seen your fires too close to my people's. Move them back." if wrath else "My warriors have seen your fires too close to ours. Move them back.",
				"Hunt on your own side of the border. My patience with %s is not endless." % people]
		"threaten":
			if wrath:
				out=["I am angry with %s. My anger has fallen on my own people before, and it can fall on yours." % people,
					"I have been patient with you. I will not be patient much longer.",
					"You have made me angry. Do not make me angrier."]
			else:
				out=["Count my warriors before you answer. I have counted yours.",
					"Cross my people again and my warriors will come to your fires.",
					"I have more fighters than you think, and they are ready."]
		"demand":
			var d:=demand_words(civ_id,menace)
			if wrath:
				out=["I demand %s. Give it, and my anger passes over you." % d,
					"I ask %s of you. Refuse me at your peril." % d,
					"%s. That is what I require of %s." % [d.capitalize(),people]]
			else:
				out=["I demand %s. Give it, and my warriors stay at home." % d,
					"Give %s, or answer to my fighters." % d,
					"%s. My warriors wait on your answer." % d.capitalize()]
		"ultimatum":
			var d2:=demand_words(civ_id,menace)
			var when:=String(DEADLINE_WORDS.get(int(menace.get("deadline",182)),"two seasons"))
			var then:=consequence_words(menace,"god")
			out=["I demand %s. You have %s. If it is not done by then, %s." % [d2,when,then],
				"You have %s to give %s. After that, %s." % [when,d2,then],
				"Give %s within %s, or %s. I will not say it twice." % [d2,when,then]]
	var tags:=CV.era_tags(civ_id)
	var kept:Array[String]=[]
	for line in out:
		if CV.permits(line,tags): kept.append(line)
	return kept if not kept.is_empty() else out

static func brief(civ_id:String,menace:Dictionary)->String:
	## The god's own words: typed, or the chosen phrasing.
	if String(menace.get("words",""))!="": return String(menace.words)
	var lines:=phrasings(civ_id,String(menace.purpose),menace)
	return lines[clampi(int(menace.get("phrase",0)),0,lines.size()-1)] if not lines.is_empty() else ""

static func envoy_account(civ_id:String,menace:Dictionary,rng:RandomNumberGenerator=null)->String:
	## Your envoy telling you, in their own voice, what they said there.
	if rng==null: rng=_rng(civ_id,_day())
	var ruler:=Rivals.given(civ_id)
	var people:=Hall._civ_name(civ_id)
	var wrath:=String(menace.get("by","wrath"))=="wrath"
	var backing:="that you are angry with them" if wrath else "how many warriors stand behind you"
	var open:=_pick(rng,["I stood before %s with half of %s listening" % [ruler,people],"They brought me to %s's fire" % ruler,"%s heard me out in front of their elders" % ruler])
	var said:=""
	match String(menace.purpose):
		"warn": said="%s, and I told them to keep their people away from yours. I said you would not send words twice." % open
		"threaten": said="%s, and I told them %s, and what that could mean for them." % [open,backing]
		"demand": said="%s, and I told them %s. Then I named what you want: %s." % [open,backing,demand_words(civ_id,menace).replace("your stores","their stores").replace("your ruler","their ruler")]
		"ultimatum":
			said="%s, and I told them %s. I named what you want, %s, and gave them %s. And I told them plainly what follows if it does not come: %s." % [open,backing,demand_words(civ_id,menace).replace("your stores","their stores").replace("your ruler","their ruler"),String(DEADLINE_WORDS.get(int(menace.get("deadline",182)),"two seasons")),consequence_words(menace,"envoy")]
	var token:=String(menace.get("token","none"))
	if token!="none": said+=" Then I laid %s at their feet." % String(TOKENS[token].label).to_lower()
	if String(menace.get("words",""))!="": said+=" I kept to the sense of your words."
	return said

# --------------------------------------------------------------------------
# Arrival: the answer, and its real consequences
# --------------------------------------------------------------------------

static func _rng(civ_id:String,day:int)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("menace:%s:%d:%d" % [civ_id,day,int(GameState.world_seed)])
	return rng

static func mood_of(answer:String,s:Dictionary,menace:Dictionary)->String:
	## How the answer feels: awed, terrified or grudging when they give way;
	## betrayed, allied, proud or scornful when they refuse.
	var wrath:=String(menace.get("by","wrath"))=="wrath"
	match answer:
		"comply","heed":
			if wrath and float(s.reverence)>=0.62: return "awed"
			if float(s.dread)>=0.4: return "terrified"
			return "grudging"
		"defy","scorn":
			if wrath and float(s.reverence)>=0.62: return "betrayed"
			if int(s.partners)>=2 and not wrath: return "allied"
			if float(s.bold)>=0.58 or String(s.trait) in ["grudge","bluffer"]: return "proud"
			return "scornful"
	return "violent"

static func arrive(mission:Dictionary,day:int)->Dictionary:
	## Called when the envoys reach them. Decides and applies the answer.
	var civ_id:=String(mission.get("civ_id",""))
	var menace:Dictionary=mission.get("menace",{}) if mission.get("menace") is Dictionary else {}
	if menace.is_empty(): menace=build(String(mission.get("purpose","threaten")),{}); mission["menace"]=menace
	if String(menace.get("demand",""))=="tribute" and not menace.get("tribute") is Dictionary: priced(civ_id,menace)
	var purpose:=String(menace.purpose)
	var rng:=_rng(civ_id,day)
	var s:=standing(civ_id)
	var before:=Divine.foreign_regard(civ_id)
	var value:=score(civ_id,menace,s)+rng.randf_range(-NOISE,NOISE)
	var answer:="comply" if value>=0.0 else "defy"
	if purpose=="warn": answer="heed" if value>=-0.05 else "scorn"
	elif value<=-0.35 and float(s.bold)>0.55 and float(s.reverence)<0.5 and rng.randf()<0.45: answer="harm"
	var mood:=mood_of(answer,s,menace)
	var result:={"answer":answer,"mood":mood,"score":value,"day":day}
	var name:=Hall._civ_name(civ_id)
	var token:Dictionary=TOKENS.get(String(menace.get("token","none")),TOKENS.none)
	var effects:Array[String]=[]
	var doing:Array[String]=[]
	match answer:
		"heed":
			Divine.add_civ_dread(civ_id,0.04+float(token.dread)); Hall._shift_relation(civ_id,-0.02,-0.12)
			doing.append("They are keeping their people back from the border.")
		"scorn":
			Hall._shift_relation(civ_id,-0.04,0.05); Rivals.grudge(civ_id,"how you warned us off like strays",0.1,"warned:%d" % day)
			_set_stance(civ_id,"defiant",182)
			doing.append("They go on as before.")
		"comply":
			var dread:=(0.12 if String(menace.by)=="wrath" else 0.06)+float(token.dread)+(0.03 if purpose=="ultimatum" else 0.0)
			if mood=="awed": dread*=0.5
			Divine.add_civ_dread(civ_id,dread)
			Hall._shift_relation(civ_id,-0.01 if mood=="awed" else -0.03,-0.2)
			var clause:String={"threaten":"how we were made to bow to your threats","demand":"what we were made to give you","ultimatum":"the ultimatum we were made to obey"}.get(purpose,"what you forced on us")
			var weight:=(0.12 if purpose=="threaten" else 0.18)*(0.4 if mood=="awed" else 1.0)
			Rivals.grudge(civ_id,clause,weight,"menace:%d" % day)
			if float(token.grudge)>0.0: Rivals.grudge(civ_id,String(token.label).to_lower()+" laid before our ruler",float(token.grudge),"token:%d" % day)
			_set_stance(civ_id,"cowed")
			if purpose=="ultimatum": _shift_credibility(0.05)
			if purpose in ["demand","ultimatum"]:
				var given:=_yield(civ_id,menace,result)
				if given!="": doing.append(given)
			else: doing.append("They are keeping away from your people.")
		"defy":
			Divine.add_civ_dread(civ_id,0.05 if mood=="betrayed" else 0.03)
			if mood=="betrayed":
				# A revering people shaken: their reverence falls hard.
				Hall._shift_relation(civ_id,-0.18,0.1+(0.05 if purpose=="ultimatum" else 0.0))
				Hall._leader_trust(civ_id,-0.12)
				Rivals.grudge(civ_id,"the god we honoured turned its anger on us",0.2,"betrayed:%d" % day)
			else:
				Hall._shift_relation(civ_id,-0.08,0.15+(0.05 if purpose=="ultimatum" else 0.0))
				Rivals.grudge(civ_id,"the threats your envoys brought us",0.2 if purpose=="threaten" else 0.25,"menace:%d" % day)
			if float(token.grudge)>0.0: Rivals.grudge(civ_id,String(token.label).to_lower()+" laid before our ruler",float(token.grudge),"token:%d" % day)
			_set_stance(civ_id,"defiant")
			var cooled:=_rally(civ_id)
			if cooled!="": doing.append(cooled)
			if float(s.bold)>=0.6 and float(s.ratio)<=1.1:
				_arm(civ_id,0.05)
				result["arming"]=true
				doing.append("Their fighters are gathering.")
			if purpose=="ultimatum": _open_ultimatum(civ_id,menace,day)
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
	var after:=Divine.foreign_regard(civ_id)
	result["regard_before"]={"love":float(before.get("love",0.5)),"dread":float(before.get("dread",0.0))}
	result["regard_after"]={"love":float(after.get("love",0.5)),"dread":float(after.get("dread",0.0))}
	result["effects"]=effects
	result["doing"]=doing
	result["friends"]=(s.friends as Array).duplicate()
	var words:=_offline_reply(civ_id,menace,result,s,rng)
	result["envoy_words"]=words.envoy
	result["reply"]=words.reply
	menace["result"]=result
	mission["menace"]=menace
	mission["proposal_resolved"]=true
	mission["accepted"]=answer in ["comply","heed"]
	mission["outcome"]=account(civ_id,menace)
	_log({"civ_id":civ_id,"purpose":purpose,"answer":answer,"mood":mood})
	ForeignDiplomacy.remember(civ_id,{"heed":"We heeded the god's warning.","scorn":"We shrugged off the god's warning.","comply":"We gave way to the god's envoys.","defy":"We refused the god's envoys to their faces.","harm":"We laid hands on the god's envoys."}.get(answer,""))
	request_voice(mission)
	return result

static func _yield(civ_id:String,menace:Dictionary,result:Dictionary)->String:
	## The demand, met: a real, bounded change.
	var name:=Hall._civ_name(civ_id)
	var index:=Hall._civ_index(civ_id)
	match String(menace.get("demand","tribute")):
		"tribute":
			var t:Dictionary=menace.get("tribute",{}) if menace.get("tribute") is Dictionary and not (menace.tribute as Dictionary).is_empty() else tribute_terms(civ_id,String(menace.get("good","")),String(menace.get("size","heavy")))
			var amount:=float(t.amount)
			var sent:=0.0
			if Hall.foreign_stock(civ_id,String(t.resource))>=0.0:
				sent=EXCHANGE.take(civ_id,String(t.resource),amount)
			elif index>=0:
				# No ledger: the estimate stands in, and Food comes off their days.
				var civ:Dictionary=WorldSimulation.world.civilizations[index]
				sent=amount
				if String(t.resource)=="Food":
					var pop:=maxf(1.0,float(civ.get("population",1.0)))
					civ["food_days"]=maxf(0.0,float(civ.get("food_days",0.0))-sent/pop)
			result["carry"]={"resource":String(t.resource),"amount":sent}
			return ("%s handed over %d %s. Your envoys are carrying it home." % [name,roundi(sent),String(t.resource)]) if sent>=1.0 else "%s had nothing to give." % name
		"ground":
			if index<0: return ""
			var civ2:Dictionary=WorldSimulation.world.civilizations[index]
			var transfer:=minf(0.015,maxf(0.0,float(civ2.get("territory",0.1))-0.08))
			civ2["territory"]=float(civ2.get("territory",0.1))-transfer
			WorldSimulation.world.player_territory_balance=float(WorldSimulation.world.player_territory_balance)+transfer
			Rivals.bond(civ_id,"frontier","the ground we yielded to you",_day()+730)
			Hall._shift_relation(civ_id,0.0,-0.15)
			result["ground"]=transfer
			return "%s is pulling its people back from the border ground. It is yours now." % name
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
			return "%s is calling its fighters back from the border." % name
		"submit":
			var answer:=load("res://scripts/world_answer.gd") as GDScript
			if bool(answer.call("is_tributary",civ_id)): return "%s already bows to you." % name
			var terms:Dictionary=answer.call("terms",civ_id)
			var bound:=String(answer.call("_bind",civ_id,_day(),float(terms.value),String(terms.hostage),"At your word, "))
			result["submitted"]=true
			return bound
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
	return "They have sent word to their friends (%s), who think less of you for it." % ", ".join(PackedStringArray(names))

static func _arm(civ_id:String,amount:float)->void:
	var index:=Hall._civ_index(civ_id)
	if index<0: return
	var civ:Dictionary=WorldSimulation.world.civilizations[index]
	civ["military_readiness"]=clampf(float(civ.get("military_readiness",0.3))+amount,0.1,1.0)

static func _open_ultimatum(civ_id:String,menace:Dictionary,day:int)->void:
	var list:Array=store().ultimatums
	list.push_front({"civ_id":civ_id,"issued":day,"due":day+int(menace.get("deadline",182)),"demand":String(menace.get("demand","tribute")),"consequence":String(menace.get("consequence","war")),"by":String(menace.get("by","wrath")),"status":"open","tribute":(menace.get("tribute",{}) as Dictionary).duplicate(),"size":String(menace.get("size","heavy"))})
	while list.size()>ULTIMATUMS_MAX:
		var dropped:=false
		for i in range(list.size()-1,-1,-1):
			if String((list[i] as Dictionary).get("status",""))!="open": list.remove_at(i); dropped=true; break
		if not dropped: list.pop_back()

# --------------------------------------------------------------------------
# The ruler's answer in words (offline). Several sentences in their manner,
# naming the demand and amount, their reasons, and what they will do.
# --------------------------------------------------------------------------

const REPLIES:={
	"heed:awed":["Tell your god we heard, and that it had no need to be angry with us. {people} will keep to our own side of the border.","We honour your god; we did not mean to crowd it. My hunters will keep back, and I will tell them why."],
	"heed:terrified":["We heard. My hunters will keep well back from your people from today. Tell your god there is no need for more.","Enough. We will move our fires back. Nobody here wants your god's anger."],
	"heed:grudging":["We will keep to our side, for now. Not because you told us to, but because I do not want a quarrel over a hunting ground.","Tell your ruler we heard. My people will keep away. I will remember that you sent warnings instead of greetings."],
	"scorn:proud":["My hunters go where the game goes. I do not ask your leave, and I will not start now.","You sent people all this way to tell us where to walk? Go home and tell your ruler we walk where we please."],
	"scorn:scornful":["Your god has never shown itself to us. We will hunt where we always have.","I have heard your warning. Nobody at my fire is afraid of it."],
	"scorn:betrayed":["We have honoured your god, and this is how it speaks to us? We will go where we must. I am sorry you think us enemies.","I did not think the god we honour would send warnings to our fire. We will not be ordered about, even by you."],
	"scorn:allied":["We have friends who hunt beside us. We will go where we please, and they with us.","Tell your ruler we are not alone out here. We will not be warned off."],
	"comply:awed":["You did not need to send threats. We have always honoured your god. {Demand} will be ready before your envoys leave, and my own people will carry it to the edge of our land.","I keep your god's name at our fire. If it asks {demand}, it will have {demand}. It is a hard thing to ask of us, and my people will feel it, but we will not set ourselves against a god we honour."],
	"comply:terrified":["Take it. Take {demand} and tell your god we gave it without a word. My people are frightened of you, and I am not ashamed to say I am too. Only let this be the end of it.","We have heard what your god does to those who cross it. You will have {demand}. Tell your ruler we want no quarrel, and that we will keep far from your people."],
	"comply:grudging":["You will have {demand}. Not because you frightened me, but because I will not lose my young men over it this year. Count it carefully. I will be counting what it cost us too.","Fine. {Demand}, then. My people will go short for it, and they will know whose envoys came asking. We will remember this day."],
	"threat:awed":["There is no need for anger. We have honoured your god since we first heard its name, and we will keep away from your people.","Tell your god we meant no offence. We will give your people no cause to be angry with us."],
	"threat:terrified":["We hear you. We want no quarrel with your god. My people will keep far from yours.","Enough. Tell your ruler we will do nothing to anger them. Nobody here wants what you threaten."],
	"threat:grudging":["We hear you. We will keep away from your people, but do not think we are afraid. We simply have better things to do than fight you this year.","Very well. There will be no quarrel from our side. Tell your ruler that threats are a poor way to keep a neighbour."],
	"defy:betrayed":["We have honoured your god since the first day we heard of it, and this is how it answers us? {Demand} would strip my people bare. I will not do it. Tell your god that {people} is not afraid, only sorry it has chosen to be our enemy.","My people keep your god's name at our fire. Now your envoy stands there and threatens us. No. You will not have {demand}. I do not know what we did to deserve this, but I will not buy your god's favour with what my people need to live."],
	"defy:proud":["No. {Demand} is more than you will ever get from us by sending threats. If your warriors want it, let them come and try to carry it away. My fighters will be waiting.","I have heard threats before, and I am still here. You will not have {demand}. Go home and tell your ruler we are sharpening our spears, and we will not be the ones to run."],
	"defy:scornful":["Your god? We have never seen your god do anything. We will not give {demand} to a people who send envoys to frighten us. Go home before the light goes.","I asked around my fire whether anyone fears your god. Nobody does. You will get nothing from us, least of all {demand}."],
	"defy:allied":["We are not alone out here. {Friends} are our friends, and they will hear of this before your envoys are home. You will get nothing from us.","You think we stand alone? {Friends} would not let us be robbed. No, you will not have {demand}."],
	"harm:violent":["This is my answer. Take it home to your god.","Take this one home, and let your ruler look at what threats buy."],
}
const THREAT_DEFY:={
	"betrayed":"We have honoured your god, and this is how it answers us? We are not afraid, only sorry you have chosen to be our enemy.",
	"proud":"We are not children to be frightened by words. If your warriors want to come, let them come. We will be ready.",
	"scornful":"Your ruler sends threats instead of fighters. We have never seen your god do anything, and we will not start trembling now.",
	"allied":"We have friends, and they will hear how you speak to us. Your threats do not frighten us.",
}

static func _offline_reply(civ_id:String,menace:Dictionary,result:Dictionary,s:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var persona:=CV.for_foreign_leader(civ_id)
	var purpose:=String(menace.purpose)
	var answer:=String(result.answer)
	var mood:=String(result.get("mood","grudging"))
	var key:="%s:%s" % [answer,mood]
	if purpose=="threaten" and answer=="comply": key="threat:"+mood
	var fact:=""
	if purpose=="threaten" and answer=="defy": fact=String(THREAT_DEFY.get(mood,THREAT_DEFY.proud))
	else: fact=_pick(rng,REPLIES.get(key,REPLIES.get("%s:proud" % answer,["We have heard you."])))
	var demand:=short_demand(civ_id,menace)
	if answer=="comply" and String(menace.get("demand",""))=="tribute":
		var carry:Dictionary=result.get("carry",{})
		demand="%d %s" % [roundi(float(carry.get("amount",0))),String(carry.get("resource","Food")).to_lower()]
	var friends:Array=result.get("friends",[])
	fact=fact.replace("{demand}",demand).replace("{Demand}",demand.substr(0,1).to_upper()+demand.substr(1)).replace("{people}",Hall._civ_name(civ_id)).replace("{Friends}"," and ".join(PackedStringArray(friends.slice(0,2))) if not friends.is_empty() else "Our neighbours")
	# What they will do, said aloud.
	var after:=""
	match answer:
		"comply":
			match String(menace.get("demand","")):
				"hostage": after="%s will go with your envoys. See that %s is fed and kept warm." % [String(result.get("hostage","My kin")),"she" if bool(result.get("hostage_woman",false)) else "he"]
				"ground": after="My people will move back from it before the season turns."
				"withdraw": after="My fighters will be home before the moon turns."
				"apology": after="The wrong was ours. I say it in front of my own people."
			if purpose=="ultimatum": after+=(" " if after!="" else "")+"There will be no need for what you threatened."
		"defy":
			if purpose=="ultimatum": after="Count your %s if you like. We will not be counting." % String(DEADLINE_WORDS.get(int(menace.get("deadline",182)),"seasons"))
			if bool(result.get("arming",false)) and not "fighters" in fact: after+=(" " if after!="" else "")+"My fighters are already gathering."
	var manner:=String(Rivals._manner_line(persona,"farewell_warm" if answer in ["comply","heed"] and mood!="grudging" else "farewell_cold",rng)) if answer!="harm" else ""
	# Their manner, in a line that fits a ruler at their own fire (not a traveller's).
	for word in ["home","carry","road","journey"]:
		if word in manner.to_lower(): manner=""
	var reply:=(fact+" "+after).strip_edges()
	if manner!="" and rng.randf()<0.5: reply+=" "+manner
	return {"envoy":envoy_account(civ_id,menace,rng),"reply":reply.strip_edges()}

static func _pick(rng:RandomNumberGenerator,lines:Array)->String:
	return String(lines[rng.randi_range(0,lines.size()-1)])

static func account(civ_id:String,menace:Dictionary)->String:
	## The whole return, as one account (history, Chief Scout report).
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
	var note:=consequence_note(civ_id,menace)
	if note!="": text+="\n\n"+note
	return text

static func _band(value:float)->String:
	if value<0.15: return "faint"
	if value<0.35: return "slight"
	if value<0.55: return "real"
	if value<0.75: return "strong"
	return "overwhelming"

static func _their(text:String)->String:
	## A grudge is kept in their own words ("what we were made to give"); the
	## note tells it from your side.
	var out:=text
	for pair:Array in [["\\bwe\\b","they"],["\\bour\\b","their"],["\\bus\\b","them"]]:
		var rule:=RegEx.new();rule.compile(String(pair[0]));out=rule.sub(out,String(pair[1]),true)
	return out

static func consequence_note(civ_id:String,menace:Dictionary)->String:
	## What is now in motion, in plain words.
	var result:Dictionary=menace.get("result",{})
	if result.is_empty(): return ""
	var lines:PackedStringArray=PackedStringArray()
	for line in result.get("effects",[]): lines.append(String(line))
	for line in result.get("doing",[]): lines.append(String(line))
	var before:Dictionary=result.get("regard_before",{})
	var after:Dictionary=result.get("regard_after",{})
	if not before.is_empty() and not after.is_empty():
		var moved:PackedStringArray=PackedStringArray()
		var dr:=float(after.dread)-float(before.dread)
		var rv:=float(after.love)-float(before.love)
		if absf(dr)>=0.02: moved.append("their dread of you is %s now (%s)" % [_band(float(after.dread)),"up" if dr>0 else "down"])
		if absf(rv)>=0.02: moved.append("their reverence is %s (%s)" % [_band(float(after.love)),"up" if rv>0 else "down"])
		if not moved.is_empty(): lines.append(("; ".join(moved)).substr(0,1).to_upper()+("; ".join(moved)).substr(1)+".")
	var top:=Rivals._top_grudge(Rivals.character(civ_id)) if not Rivals.character(civ_id).is_empty() else {}
	if not top.is_empty() and int(top.get("day",-1))>=int(result.get("day",0)): lines.append("They will remember %s." % _their(String(top.text)))
	if String(menace.purpose)=="ultimatum" and String(result.answer) in ["defy","harm"]:
		var due:=int(result.get("day",_day()))+int(menace.get("deadline",182))
		if String(menace.get("consequence","war"))=="war":
			lines.append("Their deadline is %s. If they have not given way by then, you are bound to %s before %s, or your threats lose their weight." % [Chronicle.date_label(due),"send your spears against them" if _feud(civ_id) else "make war on them",Chronicle.date_label(due+GRACE_DAYS)])
		else:
			lines.append("Their deadline is %s. If they have not given way by then, your people will close the frontier with them." % Chronicle.date_label(due))
	return " ".join(lines)

# --------------------------------------------------------------------------
# Homecoming: told in the conversation (after the live voice, if it is on)
# --------------------------------------------------------------------------

static func homecoming(mission:Dictionary,day:int)->void:
	var civ_id:=String(mission.get("civ_id",""))
	var menace:Dictionary=mission.get("menace",{}) if mission.get("menace") is Dictionary else {}
	var result:Dictionary=menace.get("result",{}) if menace.get("result") is Dictionary else {}
	if result.is_empty() or bool(result.get("home",false)): return
	result["home"]=true
	result["home_day"]=day
	var killed:=int(result.get("killed",0))
	if killed>0:
		WorldSimulation.state.register_population_deaths(killed,"killed as envoys")
		mission["personnel"]=maxi(1,int(mission.get("personnel",1))-killed)
		WorldSimulation.world._record_world_event("Envoys killed","%s killed %d of your envoys at its fire. The survivors are home." % [Hall._civ_name(civ_id),killed],"diplomacy",day)
	var carry:Dictionary=result.get("carry",{}) if result.get("carry") is Dictionary else {}
	if float(carry.get("amount",0.0))>0.0:
		EXCHANGE.receive("player",String(carry.resource),float(carry.amount))
	mission["outcome"]=account(civ_id,menace)
	if String(menace.get("voice",""))=="pending":
		# The live voice is still choosing its words; it tells when it answers
		# (or daily() tells the preset words if it never does).
		var dialogue=WorldSimulation.dialogue
		if dialogue!=null and dialogue.has_method("thread"):dialogue.thread(civ_id)["status"]="Your envoys are home; their account is being set down."
		return
	tell(civ_id,menace)

static func tell(civ_id:String,menace:Dictionary)->void:
	## The exchange joins the conversation with their ruler, once.
	var result:Dictionary=menace.get("result",{})
	if result.is_empty() or bool(result.get("told",false)): return
	result["told"]=true
	var voiced:Dictionary=menace.get("voiced",{}) if menace.get("voiced") is Dictionary else {}
	var envoy:=String(voiced.get("envoy_words",result.get("envoy_words","")))
	var reply:=String(voiced.get("reply",result.get("reply","")))
	var note:=consequence_note(civ_id,menace)
	var dialogue=WorldSimulation.dialogue
	if dialogue!=null and dialogue.has_method("_append"):
		if envoy!="": dialogue._append(civ_id,"envoy",envoy)
		if reply!="": dialogue._append(civ_id,"assistant",reply)
		if note!="": dialogue._append(civ_id,"note",note.substr(0,1700))
		var t:Dictionary=dialogue.thread(civ_id)
		t["reply"]=reply
		t["status"]="Your envoys are home with this answer."
		if dialogue.has_signal("changed"): dialogue.changed.emit(civ_id)
	var kind:String={"warn":"warning","threaten":"threat","demand":"demand","ultimatum":"ultimatum"}.get(String(menace.purpose),"message")
	var answer:String={"heed":"heeded it","scorn":"shrugged it off","comply":"gave way","defy":"refused","harm":"laid hands on your envoys"}.get(String(result.answer),"answered")
	_announce("%s Answers Your %s" % [Hall._civ_name(civ_id).substr(0,40),String(kind).capitalize()],"You sent %s your %s. %s %s: “%s” %s" % [Hall._civ_name(civ_id),kind,Rivals.given(civ_id),answer,reply.substr(0,240),note],civ_id,"moment" if String(result.answer) in ["defy","harm"] else "notice")

# --------------------------------------------------------------------------
# Deadlines
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	if WorldSimulation.actor_id!="player": return
	_tell_stale(day)
	for u in store().ultimatums:
		if not u is Dictionary or String(u.status)!="open": continue
		var civ_id:=String(u.civ_id)
		var civ:=ForeignDiplomacy.civilization(civ_id)
		if civ.is_empty() or not bool(civ.get("alive",true)): u["status"]="void"; continue
		var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
		var at_war:=bool(relation.get("at_war",false)) and int(relation.get("war_started_day",-1))>=int(u.issued)
		# Against a small people nobody declares anything: the threat is kept
		# when our spears strike them (war_loop.gd feud).
		if not at_war and _feud(civ_id): at_war=bool((load(WAR_LOOP_PATH) as GDScript).call("struck_since",civ_id,int(u.issued)))
		if String(u.consequence)=="war" and at_war: _kept(u,day); continue
		if day<int(u.due): continue
		if not bool(u.get("reconsidered",false)):
			# At the deadline they weigh it again: dread may have grown.
			u["reconsidered"]=true
			var menace:={"purpose":"ultimatum","by":String(u.get("by","wrath")),"demand":String(u.demand),"consequence":String(u.consequence),"tribute":u.get("tribute",{}),"size":String(u.get("size","heavy"))}
			if score(civ_id,menace)>=0.12:
				var result:={}
				var given:=_yield(civ_id,menace,result)
				var carry:Dictionary=result.get("carry",{})
				if float(carry.get("amount",0.0))>0.0: EXCHANGE.receive("player",String(carry.resource),float(carry.amount))
				u["status"]="met"
				_shift_credibility(0.08); Divine.add_civ_dread(civ_id,0.06); _set_stance(civ_id,"cowed")
				_court_hears(civ_id,"%s Gives Way" % Hall._civ_name(civ_id).substr(0,40),"As your deadline came, %s gave way. %s" % [Hall._civ_name(civ_id),given],"moment")
				ForeignDiplomacy.remember(civ_id,"At the deadline we gave the god what it demanded.")
				continue
		if String(u.consequence)=="sever":
			_sever(civ_id)
			_kept(u,day)
			continue
		if not bool(u.get("announced",false)):
			u["announced"]=true
			if _feud(civ_id): _court_hears(civ_id,"The Deadline Passes","Your deadline for %s has come and they have not given way. You swore to send your spears against them. Strike before %s, or every people will learn your threats are empty." % [Hall._civ_name(civ_id),Chronicle.date_label(int(u.due)+GRACE_DAYS)],"moment")
			else: _court_hears(civ_id,"The Deadline Passes","Your deadline for %s has come and they have not given way. You swore war. Declare it before %s, or every people will learn your threats are empty." % [Hall._civ_name(civ_id),Chronicle.date_label(int(u.due)+GRACE_DAYS)],"moment")
		if day>=int(u.due)+GRACE_DAYS: _broken(u,day)

## A small people (conflict_scale.gd): our threat of war is a threat of spears,
## kept by a strike, never by a declaration.
const WAR_LOOP_PATH:="res://scripts/war_loop.gd"
static func _feud(civ_id:String)->bool:
	return not preload("res://scripts/conflict_scale.gd").formal(civ_id)

static func _tell_stale(day:int)->void:
	## A live voice that never answered (lost to a reload): tell the preset words.
	for record in WorldSimulation.world.diplomatic_history:
		if not record is Dictionary or not record.get("menace") is Dictionary: continue
		var menace:Dictionary=record.menace
		var result:Dictionary=menace.get("result",{}) if menace.get("result") is Dictionary else {}
		if result.is_empty() or bool(result.get("told",false)) or not bool(result.get("home",false)): continue
		if String(menace.get("voice",""))=="pending" and day-int(result.get("home_day",day))<2: continue
		menace["voice"]="failed"
		tell(String(record.get("civ_id","")),menace)

static func _court_hears(civ_id:String,title:String,text:String,tier:String)->void:
	## A Chronicle card that opens the court on this people, and a line in the
	## conversation with their ruler.
	_announce(title,text,civ_id,tier)
	var dialogue=WorldSimulation.dialogue
	if dialogue!=null and dialogue.has_method("_append"):
		dialogue._append(civ_id,"note",text.substr(0,1700))
		if dialogue.has_signal("changed"): dialogue.changed.emit(civ_id)

static func _kept(u:Dictionary,day:int)->void:
	var civ_id:=String(u.civ_id)
	u["status"]="kept"; u["closed"]=day
	_shift_credibility(0.12)
	Divine.add_civ_dread(civ_id,0.10)
	for civ:Dictionary in WorldSimulation.world.civilizations:
		var other:=String(civ.get("id",""))
		if other=="" or other==civ_id or not bool(civ.get("alive",true)): continue
		if int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))>=2: Divine.add_civ_dread(other,0.03)
	var what:=("your spears struck them" if _feud(civ_id) else "war") if String(u.consequence)=="war" else "the closing of the frontier"
	_court_hears(civ_id,"A Threat Kept","You did what you told %s you would do: %s. Every people that hears of it will fear your word a little more." % [Hall._civ_name(civ_id),what],"notice")
	ForeignDiplomacy.remember(civ_id,"The god did what it threatened. Its word is not empty.")

static func _broken(u:Dictionary,day:int)->void:
	var civ_id:=String(u.civ_id)
	u["status"]="broken"; u["closed"]=day
	_shift_credibility(-0.2)
	var d:=Divine.civ_dread(civ_id)
	(Divine.store().civ_dread as Dictionary)[civ_id]={"v":maxf(0.0,d-0.15),"day":day}
	_set_stance(civ_id,"emboldened",540)
	Hall._shift_relation(civ_id,-0.02,0.0)
	var feud:=_feud(civ_id)
	_court_hears(civ_id,"An Empty Threat","%s refused your ultimatum and nothing happened. %s Other peoples will weigh your threats more lightly now, and %s will ask more of you." % [Hall._civ_name(civ_id),"You swore to send your spears and never did." if feud else "You swore war and did not make it.",Hall._civ_name(civ_id)],"moment")
	ForeignDiplomacy.remember(civ_id,"The god threatened %s and never came. We laughed about it at the fire." % ("its spears" if feud else "war"))

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
	## The Chronicle (court_lives record): its card opens the court on them.
	Rivals._record(title,text.substr(0,580),civ_id,tier)

static func ties(civ_id:String)->Array[Dictionary]:
	## What menace has set in motion with this people, for the court's
	## "What you know": {text,tip,tone} with tone "danger" or "note".
	var out:Array[Dictionary]=[]
	var u:=open_ultimatum(civ_id)
	if not u.is_empty():
		var what:="war" if String(u.consequence)=="war" else "closing the frontier"
		out.append({"text":"Your ultimatum · due %s" % Chronicle.date_label(int(u.due)),"tip":"If they have not given way by then, you are bound to %s%s." % [what," within a season, or your threats lose their weight" if String(u.consequence)=="war" else ""],"tone":"danger"})
	match stance(civ_id):
		"cowed": out.append({"text":"Cowed by your threats","tip":"They gave way to you and ask less of you for now.","tone":"note"})
		"defiant": out.append({"text":"Defying your threats","tip":"They refused you and may test you in turn.","tone":"danger"})
		"emboldened": out.append({"text":"Laughs at your threats","tip":"Your last threat came to nothing; they will ask more of you.","tone":"danger"})
	return out

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
# The live voice: when the AI is on, the ruler ALWAYS answers in their own
# words, from the decided outcome and rich facts. The engine decided the
# outcome and its consequences; the words may not add to them.
# --------------------------------------------------------------------------

const VOICE_PROMPT:="""Speak as the named foreign leader in this fictional early-historical simulation. Another people's ruler, whom their people treat as a living god, sent an envoy with a message of menace. First write envoy_words: the envoy reporting back to their god, in the envoy's own voice and first person, what they said at the leader's fire (keep the god's meaning; do not copy the god's words verbatim). Then write reply: the leader's own spoken answer to the envoy, three to six sentences, in the leader's manner (see manner and temper). The outcome is ALREADY DECIDED and the reply must convey exactly it: OUTCOME. Name the actual demand and amount if there is one. Give the leader's real reasons from the facts (awe or fear of the god, pride, friends, grudges, their stores) and say plainly what they will do next. A leader who gives way sounds awed, frightened or grudging as the mood says; one who refuses states defiance in character and hints at what comes next. Do not invent any other transfer, promise, war, death, number, place or agreement; every number you use must appear in the facts. Speak plainly and concretely; never invent maxims, proverbs or riddles. Mention nothing the leader's people could not know or own in their era (see era). Never mention a game, system, screen, message, channel or rules. Return JSON: envoy_words (1–600 characters), reply (1–900 characters)."""

const MOOD_WORDS:={"awed":"in awe of the god, giving way out of reverence","terrified":"frightened, giving way out of fear","grudging":"grudging, giving way only to avoid a fight","betrayed":"shaken and betrayed: they revered the god and this demand wounds them","proud":"proud and defiant","scornful":"scornful: they neither revere nor fear the god","allied":"defiant, trusting in their friends","violent":"violent"}

static func voice_available()->bool:
	return PronouncementInterpreter!=null and not PronouncementInterpreter._api_config().is_empty()

static func outcome_brief(civ_id:String,menace:Dictionary)->String:
	var result:Dictionary=menace.get("result",{})
	var mood:=String(MOOD_WORDS.get(String(result.get("mood","")),""))
	match String(result.get("answer","")):
		"heed": return "the leader heeds the warning and says their people will keep away; mood: "+mood
		"scorn": return "the leader shrugs off the warning; mood: "+mood
		"comply":
			var what:=short_demand(civ_id,menace) if menace.has("demand") else "to keep away from the god's people"
			if String(menace.get("demand",""))=="tribute": what="%d %s" % [roundi(float((result.get("carry",{}) as Dictionary).get("amount",0))),String((result.get("carry",{}) as Dictionary).get("resource","Food")).to_lower()]
			return "the leader gives way and agrees: %s; mood: %s" % [what,mood]
		"defy": return "the leader refuses outright%s; mood: %s" % [" and is gathering fighters" if bool(result.get("arming",false)) else "",mood]
		"harm":
			if int(result.get("killed",0))>0: return "the leader refuses and has %d of the envoys killed; the reply is the leader's last words to the survivors" % int(result.get("killed",0))
			return "the leader refuses and has one envoy maimed; the reply is the leader's words to the survivor"
	return "the leader refuses"

static func voice_facts(civ_id:String,menace:Dictionary)->Dictionary:
	var leader:=ForeignDiplomacy.leader(civ_id)
	var result:Dictionary=menace.get("result",{})
	var character:=Rivals.rival_character(civ_id)
	var s:Dictionary=standing(civ_id)
	var facts:={"leader":String(leader.get("name","")),"people":Hall._civ_name(civ_id),"era":CV.era_tags(civ_id),"manner":String(character.get("voice_name","")),
		"temper":String(leader.get("temperament","")),"known_for":String(character.get("trait_words","")),"reverence_for_the_god":_band(float(s.reverence)),"dread_of_the_god":_band(float(s.dread)),
		"message_kind":String(menace.purpose),"backed_by":String(BY[String(menace.get("by","wrath"))].label),"token":String(TOKENS[String(menace.get("token","none"))].label),
		"their_friends":(s.friends as Array).slice(0,3),"their_grudges":(Rivals.prompt_view(civ_id).get("grudges",[]) as Array).slice(0,3),
		"their_memories":(leader.get("memories",[]) as Array).slice(0,4).map(func(m:Variant)->String:return String((m as Dictionary).get("text","")) if m is Dictionary else ""),
		"mood":String(result.get("mood",""))}
	if menace.has("demand"):
		facts["demand"]=demand_words(civ_id,menace)
		if String(menace.demand)=="tribute":
			var t:Dictionary=menace.get("tribute",{})
			facts["demand_amount"]=roundi(float(t.get("amount",0)))
			facts["their_stores_of_it"]="about %d" % roundi(float(t.get("stock",0)))
	if menace.has("deadline"): facts["deadline"]=String(DEADLINE_WORDS.get(int(menace.deadline),"two seasons"))
	if menace.has("consequence"): facts["consequence"]=consequence_words(menace,"plain")
	if int(result.get("killed",0))>0: facts["envoys_killed"]=int(result.killed)
	if String(result.get("hostage",""))!="": facts["hostage"]=String(result.hostage)
	return facts

static func voice_messages(civ_id:String,menace:Dictionary)->Array:
	return [{"role":"system","content":VOICE_PROMPT.replace("OUTCOME",outcome_brief(civ_id,menace))},{"role":"system","content":"KNOWN FACTS: "+JSON.stringify(voice_facts(civ_id,menace))},{"role":"user","content":"THE GOD'S WORDS TO THE ENVOY: "+JSON.stringify(brief(civ_id,menace))}]

static func request_voice(mission:Dictionary)->bool:
	var menace:Dictionary=mission.get("menace",{})
	if not voice_available(): return false
	var config:Dictionary=PronouncementInterpreter._api_config()
	var civ_id:=String(mission.get("civ_id",""))
	var payload:={"model":config.model,"messages":voice_messages(civ_id,menace),"max_completion_tokens":1200}
	if bool(config.get("structured_output",false)):
		payload["response_format"]={"type":"json_schema","json_schema":{"name":"envoy_menace","strict":true,"schema":{"type":"object","additionalProperties":false,"properties":{"envoy_words":{"type":"string"},"reply":{"type":"string"}},"required":["envoy_words","reply"]}}}
	var host:Node=WorldSimulation.dialogue as Node
	if host==null: return false
	var http:=HTTPRequest.new(); host.add_child(http); http.timeout=45; http.max_redirects=0; http.body_size_limit=65536
	var depart:=int(mission.get("depart_day",-1))
	menace["voice"]="pending"
	http.request_completed.connect(func(result:int,code:int,_h:PackedStringArray,body:PackedByteArray)->void:
		http.queue_free()
		var value:Variant=null
		if result==HTTPRequest.RESULT_SUCCESS and code>=200 and code<300:
			var envelope:Variant=JSON.parse_string(body.get_string_from_utf8())
			if envelope is Dictionary and envelope.get("choices") is Array and not (envelope.choices as Array).is_empty() and envelope.choices[0] is Dictionary:
				var content:=String(PronouncementInterpreter._content_text((envelope.choices[0] as Dictionary).get("message",{}).get("content","")))
				value=JSON.parse_string(content.trim_prefix("```json").trim_suffix("```").strip_edges())
		voice_answered(civ_id,depart,value))
	var error:=AiWire.send(http,config,PackedStringArray(["Content-Type: application/json","Authorization: Bearer "+String(config.api_key)]),payload)
	if error!=OK:
		http.queue_free(); menace["voice"]="failed"; return false
	return true

static func find_mission(civ_id:String,depart:int)->Dictionary:
	## The traveling delegation, or its record once home.
	var live:Dictionary=WorldSimulation.world.diplomatic_mission
	if String(live.get("civ_id",""))==civ_id and int(live.get("depart_day",-2))==depart: return live
	for record in WorldSimulation.world.diplomatic_history:
		if record is Dictionary and String(record.get("civ_id",""))==civ_id and int(record.get("depart_day",-2))==depart: return record
	return {}

static func voice_answered(civ_id:String,depart:int,value:Variant)->bool:
	## The live voice came back (value null on failure). Tells the exchange if
	## the envoys are already home.
	var mission:=find_mission(civ_id,depart)
	if mission.is_empty() or not mission.get("menace") is Dictionary: return false
	var menace:Dictionary=mission.menace
	var ok:=value!=null and accept_voice(mission,value)
	menace["voice"]="voiced" if ok else "failed"
	var result:Dictionary=menace.get("result",{})
	if bool(result.get("home",false)): tell(civ_id,menace)
	return ok

static func accept_voice(mission:Dictionary,value:Variant)->bool:
	## Validated, bounded: the live words replace the preset ones only if they
	## stay in character and era, use no number the facts lack, keep to the
	## decided answer, and the exchange has not been told yet.
	var menace:Dictionary=mission.get("menace",{})
	var result:Dictionary=menace.get("result",{}) if menace.get("result") is Dictionary else {}
	if result.is_empty() or bool(result.get("told",false)): return false
	if not value is Dictionary or not value.get("envoy_words") is String or not value.get("reply") is String: return false
	var envoy:=String(value.envoy_words).strip_edges()
	var reply:=String(value.reply).strip_edges()
	if envoy.is_empty() or reply.is_empty() or envoy.length()>600 or reply.length()>900: return false
	var civ_id:=String(mission.get("civ_id",""))
	var dialogue=WorldSimulation.dialogue
	if dialogue!=null and dialogue.has_method("_reply_stays_in_character") and (not dialogue._reply_stays_in_character(reply) or not dialogue._reply_stays_in_character(envoy)): return false
	if dialogue!=null and dialogue.has_method("_envoy_uses_own_words") and not dialogue._envoy_uses_own_words(brief(civ_id,menace),envoy): return false
	var tags:=CV.era_tags(civ_id)
	if not CV.permits(reply,tags) or not CV.permits(envoy,tags): return false
	# No invented numbers: every figure must be in the facts.
	var known:=JSON.stringify(voice_facts(civ_id,menace))+" "+brief(civ_id,menace)
	var Pacts:=load(PACTS_PATH) as GDScript
	for n in Pacts.call("numbers_in",reply+" "+envoy):
		if not str(n) in known: return false
	# Keep to the decided answer.
	var low:=reply.to_lower()
	var answer:=String(result.get("answer",""))
	if answer=="comply" and (low.begins_with("no.") or low.begins_with("no,") or "you will not have" in low or "we will not give" in low): return false
	if answer=="defy" and ("take the" in low and "go" in low and not "not" in low): return false
	reply=preload("res://scripts/plain_speech.gd").strip_or_keep(reply)
	if reply.strip_edges().is_empty(): return false
	menace["voiced"]={"envoy_words":envoy,"reply":reply}
	mission["outcome"]=account(civ_id,menace)
	return true
