extends RefCounted
## Love and dread. To their own people the ruler is a god, and every official
## holds that god in some mixture of love (reverence, devotion) and dread
## (terror of the god's anger). Both are durable fields on the person's
## `relationships.sovereign` record: "fear" already existed; "love" is an
## optional field, derived from trust, respect, obligation and resentment until
## the god first moves it (so older saves read sensibly and stay valid).
##
## The god's wrath and favour are presence, words and real decrees, never
## miracles: terrifying an official, demanding penance, casting them out
## (exile: removal from office and from the realm's service), striking them
## down (execution through GovernmentPeopleSystem), blessing, a boon paid out
## of the real stores, raising them up. Each moves the target and the watching
## court by bounded amounts graded by personality.
##
## Consequences: dread buys compliance and costs candour (frightened officials
## overpromise and soften bad news); love buys candour, initiative and loyalty.
## Dread fused with resentment first shows in speech (the official is
## "warned"), then may become quiet sabotage of the work and, past a higher
## threshold, flight from the god's reach.
##
## Court-wide state (recent acts, who has begun to think of fleeing, how much
## each foreign people dreads the ruler) lives in the hall's saved state under
## the optional key "divine". Static helpers; reference with preload.

const WRATH:=["terrify","penance","cast_out","strike_down"]
const FAVOR:=["bless","boon","raise_up"]
const TERMINAL:=["cast_out","strike_down"]
## Acts the live voice's `divine` field may report on the one before the god.
## Every other spoken order (death, exile, gifts, ...) is read and carried out
## by court_commands.gd.
const SPOKEN:=["terrify","penance","bless","raise_up"]
const ACTIONS:={
	"terrify":{"label":"Terrify them","sub":"Let your fury fill the hall. Dread rises; so may resentment.","tone":"wrath"},
	"penance":{"label":"Demand penance","sub":"They must fast and keep vigil to regain your favour.","tone":"wrath"},
	"cast_out":{"label":"Cast them out","sub":"Exile: stripped of office and sent beyond the hearths.","tone":"wrath"},
	"strike_down":{"label":"Strike them down","sub":"Have them put to death before the court.","tone":"wrath"},
	"bless":{"label":"Bless them","sub":"Your open favour, before everyone.","tone":"favor"},
	"boon":{"label":"Grant a boon","sub":"A real gift from the stores.","tone":"favor"},
	"raise_up":{"label":"Raise them up","sub":"Honour them above their peers.","tone":"favor"},
}
const EVENTS_MAX:=24
const FLIGHT_WARN:=0.18     ## risk at which it first shows in their speech
const FLIGHT_ACT:=0.34      ## risk at which, after warning, they may actually go
const WARN_DAYS:=20         ## days of telegraphing before flight is possible
const CALM_BELOW:=0.10      ## warned officials who calm below this stop thinking of it
const CIV_DREAD_HALF_LIFE:=180.0
const SABOTAGE_MAX:=0.12

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func store()->Dictionary:
	ForeignDiplomacy.ensure()
	var s:Dictionary=ForeignDiplomacy.audiences
	if not s.get("divine") is Dictionary: s["divine"]={}
	var d:Dictionary=s.divine
	if not d.get("events") is Array: d["events"]=[]
	if not d.get("warned") is Dictionary: d["warned"]={}
	if not d.get("civ_dread") is Dictionary: d["civ_dread"]={}
	if not d.has("last_day"): d["last_day"]=-1
	return d

static func _num(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func valid_state(data:Variant)->bool:
	## Optional save block; absent in older saves.
	if not data is Dictionary: return false
	if data.has("events"):
		if not data.events is Array or (data.events as Array).size()>EVENTS_MAX: return false
		for e in data.events:
			if not e is Dictionary or not _num(e.get("day")) or not String(e.get("action","")) in WRATH+FAVOR+["terrify_envoy","flight","slay_envoy","maim_envoy","shame_envoy"] or JSON.stringify(e).length()>1200: return false
	if data.has("warned"):
		if not data.warned is Dictionary or (data.warned as Dictionary).size()>300: return false
		for k in data.warned:
			if not k is String or not _num(data.warned[k]): return false
	if data.has("civ_dread"):
		if not data.civ_dread is Dictionary or (data.civ_dread as Dictionary).size()>256: return false
		for k in data.civ_dread:
			var entry:Variant=data.civ_dread[k]
			if not k is String or not entry is Dictionary or not _num(entry.get("v")) or not _num(entry.get("day")) or float(entry.v)<0.0 or float(entry.v)>1.0: return false
	if data.has("last_day") and not _num(data.last_day): return false
	return true

static func _day()->int:
	return int(GameState.elapsed_days)

static func events(limit:int=6,person_id:int=0)->Array[Dictionary]:
	## Most recent first. person_id>0: acts on or witnessed by that person.
	var out:Array[Dictionary]=[]
	for e in store().events:
		if not e is Dictionary: continue
		if person_id>0 and int(e.get("person_id",0))!=person_id and not person_id in (e.get("witnesses",[]) as Array): continue
		out.append(e)
		if out.size()>=limit: break
	return out

static func _record_event(entry:Dictionary)->void:
	var list:Array=store().events
	list.push_front(entry)
	while list.size()>EVENTS_MAX: list.pop_back()

# --------------------------------------------------------------------------
# Reading a person
# --------------------------------------------------------------------------

static func sovereign(person:Dictionary)->Dictionary:
	var rel:Variant=(person.get("relationships",{}) as Dictionary).get("sovereign",{}) if person.get("relationships") is Dictionary else {}
	return rel if rel is Dictionary else {}

static func derived_love(rel:Dictionary)->float:
	## Before the god has moved it, love is read from how the person already
	## stands: trust and respect warm it, obligation binds it, resentment sours it.
	return clampf(0.12+float(rel.get("trust",0.5))*0.42+float(rel.get("respect",0.5))*0.22+float(rel.get("obligation",0.4))*0.14-float(rel.get("resentment",0.0))*0.45,0.0,1.0)

static func love_of(person:Dictionary)->float:
	var rel:=sovereign(person)
	if _num(rel.get("love",null)): return clampf(float(rel.love),0.0,1.0)
	return derived_love(rel)

static func dread_of(person:Dictionary)->float:
	return clampf(float(sovereign(person).get("fear",0.0)),0.0,1.0)

static func read(love:float,dread:float,resentment:float)->Dictionary:
	## The one-line in-world read of a love/dread state.
	if dread>=0.55 and resentment>=0.35: return {"id":"hates_dread","read":"fears you and hates you for it"}
	if love>=0.62 and dread>=0.45: return {"id":"worships","read":"worships you"}
	if dread>=0.55: return {"id":"terror","read":"obeys out of terror"}
	if love>=0.62 and dread<0.2: return {"id":"fearless_love","read":"loves you and fears nothing"}
	if love>=0.55: return {"id":"reveres","read":"reveres you"}
	if resentment>=0.28: return {"id":"resents","read":"quietly resents you"}
	if dread>=0.32: return {"id":"wary","read":"keeps a careful distance"}
	if love<0.3: return {"id":"cold","read":"serves without warmth"}
	return {"id":"dutiful","read":"serves you dutifully"}

static func regard(person:Dictionary)->Dictionary:
	if person.is_empty(): return {}
	var rel:=sovereign(person)
	var love:=love_of(person)
	var dread:=dread_of(person)
	var resentment:=clampf(float(rel.get("resentment",0.0)),0.0,1.0)
	var out:=read(love,dread,resentment)
	out["love"]=love; out["dread"]=dread; out["resentment"]=resentment
	out["trust"]=clampf(float(rel.get("trust",0.5)),0.0,1.0)
	out["candor"]=candor(person)
	out["risk"]=flight_risk(person)
	out["warned"]=warned(int(person.get("person_id",0)))
	return out

static func candor(person:Dictionary)->float:
	## How straight their reports are: honesty, warmed by love, bent by dread.
	var honesty:=clampf(float(person.get("honesty",0.5)),0.0,1.0)
	return clampf(honesty*0.65+love_of(person)*0.35-maxf(0.0,dread_of(person)-0.3)*0.7,0.0,1.0)

static func forecast_bias(person:Dictionary)->float:
	## Extra optimism in a leader's forecast. The frightened overpromise (the
	## honest less so); the loving report closer to the truth.
	var honesty:=clampf(float(person.get("honesty",0.5)),0.0,1.0)
	var dread:=dread_of(person)
	var love:=love_of(person)
	# Love does not add pessimism; it tempers flattery (forecast_bias_scale).
	return maxf(0.0,dread-0.3)*0.26*(1.0-0.5*honesty)*(1.0-0.5*clampf((love-0.55)/0.45,0.0,1.0))

static func forecast_error_scale(person:Dictionary)->float:
	## The loving tell you what they actually see: their forecasts wander less.
	return 1.0-0.45*clampf((love_of(person)-0.5)/0.5,0.0,1.0)

static func forecast_bias_scale(person:Dictionary)->float:
	## Love also tempers the flattery of an ordinarily flattering disposition.
	return 1.0-0.5*clampf((love_of(person)-0.55)/0.45,0.0,1.0)

static func willingness_shift(person:Dictionary)->float:
	## Dread makes people comply; love makes them want to; dread soured by
	## resentment makes compliance brittle.
	var rel:=sovereign(person)
	var dread:=dread_of(person)
	var love:=love_of(person)
	return dread*0.20+maxf(0.0,love-0.5)*0.20-dread*float(rel.get("resentment",0.0))*0.25

static func flight_risk(person:Dictionary)->float:
	var rel:=sovereign(person)
	var dread:=dread_of(person)
	var resentment:=float(rel.get("resentment",0.0))
	if dread<0.5 or resentment<0.3: return 0.0
	return clampf((dread-0.5)*1.1+(resentment-0.3)*1.3-maxf(0.0,love_of(person)-0.4)*0.6-float(rel.get("obligation",0.4))*0.15,0.0,1.0)

static func warned(person_id:int)->bool:
	return person_id>0 and (store().warned as Dictionary).has(str(person_id))

static func sabotage(person:Dictionary)->float:
	## A telegraphed, dread-and-resentment-soured official quietly drags their
	## feet: a bounded cut to how well their orders are carried out.
	if WorldSimulation.actor_id!="player": return 0.0
	if not warned(int(person.get("person_id",0))): return 0.0
	var rel:=sovereign(person)
	var dread:=dread_of(person)
	var resentment:=float(rel.get("resentment",0.0))
	if dread<0.5 or resentment<0.35: return 0.0
	return clampf((dread-0.5)*0.25+(resentment-0.35)*0.3,0.0,SABOTAGE_MAX)

# --------------------------------------------------------------------------
# Fading: feelings drift back toward who the person is; memories stay
# --------------------------------------------------------------------------
## Dread fades in weeks, love over seasons, resentment slowly and only once it
## has gone unprovoked. A big act "holds" dread: while held it fades at the
## slow rate (an execution witnessed lingers a season or two; a scolding is
## gone in weeks). Every rate is a closed-form exponential over elapsed days,
## so one multi-day step equals the same days taken one at a time.
## Optional per-person stamps on relationships.sovereign (absent in older
## saves): fade_day (last day faded), dread_hold (day the hold ends),
## resent_day (last day resentment rose).
const DREAD_HALF_LIFE:=24.0
const DREAD_HELD_HALF_LIFE:=240.0
const LOVE_HALF_LIFE:=150.0
const RESENT_HALF_LIFE:=300.0
const RESENT_QUIET_DAYS:=40
## Days an act holds the dread it caused, on its target and on the watchers.
const TARGET_HOLD:={"terrify":7,"penance":5}
const WITNESS_HOLD:={"terrify":3,"penance":2,"cast_out":45,"strike_down":110}

static func dread_baseline(person:Dictionary)->float:
	## Ordinary awe of the god: the timid and suspicious carry more of it.
	var courage:=clampf(float(person.get("courage",0.5)),0.0,1.0)
	var suspicion:=clampf(float(person.get("suspicion",0.5)),0.0,1.0)
	var traits:Array=person.get("traits",[]) if person.get("traits") is Array else []
	var base:=0.04+0.20*(1.0-courage)+0.05*suspicion
	if "Cautious" in traits: base+=0.04
	if "Humble" in traits: base+=0.03
	if "Bold" in traits: base-=0.03
	return clampf(base,0.02,0.32)

static func love_baseline(person:Dictionary)->float:
	## Standing warmth: how they stand with the ruler (trust, respect,
	## obligation; resentment sours love separately) and their own warmth.
	var rel:=sovereign(person)
	var standing:=derived_love({"trust":rel.get("trust",0.5),"respect":rel.get("respect",0.5),"obligation":rel.get("obligation",0.4),"resentment":0.0})
	var personality:Dictionary=person.get("personality",{}) if person.get("personality") is Dictionary else {}
	var warmth:=0.3+0.4*clampf(float(personality.get("empathy",0.5)),0.0,1.0)
	var traits:Array=person.get("traits",[]) if person.get("traits") is Array else []
	var base:=standing*0.75+warmth*0.25
	if "Warm" in traits or "Generous" in traits: base+=0.03
	if "Skeptical" in traits or "Severe" in traits: base-=0.03
	return clampf(base,0.05,0.9)

static func resentment_floor(person:Dictionary)->float:
	## The proud keep a sliver of every grievance.
	return 0.04*clampf(float(person.get("pride",0.5)),0.0,1.0)

static func _stamp(rel:Dictionary,key:String,fallback:int)->int:
	return int(float(rel[key])) if _num(rel.get(key,null)) else fallback

static func _toward(value:float,base:float,exponent:float)->float:
	return clampf(base+(value-base)*exp(-exponent),0.0,1.0)

static func _split(from:int,to:int,until:int)->Vector2:
	## Days of [from,to) before `until` (x) and after it (y).
	var held:=clampi(until-from,0,to-from)
	return Vector2(held,to-from-held)

static func fade(person:Dictionary,day:int)->bool:
	## Moves the person's sovereign feelings toward their baselines for the
	## days since they last faded. Mutates person in place; true if changed.
	if not person.get("relationships") is Dictionary: return false
	var rels:Dictionary=person.relationships
	if not rels.get("sovereign") is Dictionary: return false
	var rel:Dictionary=rels.sovereign
	var from:=_stamp(rel,"fade_day",-1)
	if from==day: return false
	rel["fade_day"]=day
	if from<0 or from>day: return true
	var courage:=clampf(float(person.get("courage",0.5)),0.0,1.0)
	var ln2:=log(2.0)
	# Dread: the timid take longer to stop shaking.
	var dread_scale:=0.8+0.6*(1.0-courage)
	var dread_days:=_split(from,day,_stamp(rel,"dread_hold",-1))
	var dread_exp:=dread_days.x*ln2/(DREAD_HELD_HALF_LIFE*dread_scale)+dread_days.y*ln2/(DREAD_HALF_LIFE*dread_scale)
	rel["fear"]=_toward(float(rel.get("fear",0.0)),dread_baseline(person),dread_exp)
	# Love, once the god has moved it, drifts back slowly toward their warmth.
	if _num(rel.get("love",null)):
		rel["love"]=_toward(float(rel.love),love_baseline(person),float(day-from)*ln2/LOVE_HALF_LIFE)
	# Resentment only eases after a quiet spell, and never below its floor.
	var resentment:=float(rel.get("resentment",0.0))
	var floor_value:=resentment_floor(person)
	if resentment>floor_value:
		var quiet:=_split(from,day,_stamp(rel,"resent_day",-100000)+RESENT_QUIET_DAYS)
		var pride:=clampf(float(person.get("pride",0.5)),0.0,1.0)
		rel["resentment"]=_toward(resentment,floor_value,quiet.y*ln2/(RESENT_HALF_LIFE*(0.7+0.6*pride)))
	return true

# --------------------------------------------------------------------------
# The people as a whole and foreign peoples
# --------------------------------------------------------------------------

static func people_regard(officials:Array)->Dictionary:
	## The people's regard, read from the officials who speak for them and from
	## the realm's legitimacy and cohesion, plus the memory of recent wrath.
	var love_sum:=0.0; var dread_sum:=0.0; var res_sum:=0.0; var n:=0
	for person in officials:
		if not person is Dictionary: continue
		love_sum+=love_of(person); dread_sum+=dread_of(person); res_sum+=float(sovereign(person).get("resentment",0.0)); n+=1
	var metrics:Dictionary=GameState.simulation_metrics
	var standing:=float(metrics.get("legitimacy",0.5))*0.6+float(metrics.get("cohesion",0.5))*0.4
	var love:=(love_sum/n*0.55+standing*0.45) if n>0 else standing
	var echo:=0.0
	for e in store().events:
		var age:=_day()-int(e.get("day",0)) if e is Dictionary else 9999
		if age>365: continue
		# The memory of wrath fades from the people's talk over a few months.
		echo+=float({"strike_down":0.08,"slay_envoy":0.08,"maim_envoy":0.06,"shame_envoy":0.03,"cast_out":0.05,"terrify":0.02,"penance":0.01}.get(String(e.get("action","")),0.0))*pow(0.5,maxf(0.0,float(age))/90.0)
	var dread:=clampf((dread_sum/n if n>0 else 0.1)*0.75+minf(0.3,echo),0.0,1.0)
	var resentment:=res_sum/n if n>0 else 0.0
	var out:=read(clampf(love,0.0,1.0),dread,resentment)
	out["love"]=clampf(love,0.0,1.0); out["dread"]=dread; out["resentment"]=resentment
	out["read"]=_people_words(String(out.id))
	return out

static func _people_words(id:String)->String:
	return String({"hates_dread":"your people fear you and hate you for it","worships":"your people worship you","terror":"your people obey out of terror",
		"fearless_love":"your people love you and fear nothing","reveres":"your people revere you","resents":"your people quietly resent you",
		"wary":"your people keep a careful distance","cold":"your people serve without warmth","dutiful":"your people serve dutifully"}.get(id,"your people serve dutifully"))

static func civ_dread(civ_id:String)->float:
	var entry:Variant=(store().civ_dread as Dictionary).get(civ_id,{})
	if not entry is Dictionary or not _num(entry.get("v")): return 0.0
	return clampf(float(entry.v)*pow(0.5,maxf(0.0,float(_day()-int(entry.get("day",_day()))))/CIV_DREAD_HALF_LIFE),0.0,1.0)

static func add_civ_dread(civ_id:String,amount:float)->float:
	var value:=clampf(civ_dread(civ_id)+clampf(amount,0.0,0.4),0.0,1.0)
	(store().civ_dread as Dictionary)[civ_id]={"v":value,"day":_day()}
	while (store().civ_dread as Dictionary).size()>256: (store().civ_dread as Dictionary).erase((store().civ_dread as Dictionary).keys()[0])
	return value

static func foreign_regard(civ_id:String)->Dictionary:
	## How a foreign people regards the ruler, from real relations: opinion and
	## their leader's trust (reverence), remembered terror and border tension (dread).
	var civ:Dictionary=ForeignDiplomacy.civilization(civ_id)
	if civ.is_empty(): return {}
	var leader:Dictionary=ForeignDiplomacy.leader(civ_id)
	var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
	var reverence:=clampf(0.5+float(relation.get("opinion",0.0))*0.35+float(leader.get("trust",0.0))*0.15,0.0,1.0)
	var tension:=clampf(float(relation.get("border_tension",0.0)),0.0,1.0)
	var dread:=clampf(civ_dread(civ_id)+tension*0.3,0.0,1.0)
	var id:="undecided"; var words:="are undecided about you"
	if bool(relation.get("at_war",false)): id="war"; words="are at war with you"
	elif dread>=0.55 and reverence>=0.55: id="awe"; words="hold you in awe"
	elif dread>=0.55: id="fear"; words="fear your wrath"
	elif reverence>=0.65: id="honor"; words="honour you"
	elif reverence<=0.3: id="scorn"; words="think little of you"
	elif tension>=0.5: id="wary"; words="watch you warily"
	return {"id":id,"read":words,"love":reverence,"dread":dread,"name":String(civ.get("name",civ_id))}

# --------------------------------------------------------------------------
# Acts of the god
# --------------------------------------------------------------------------

static func response_to(action:String,person:Dictionary)->String:
	## How the target meets the act: a proud and brave soul defies wrath, a
	## timid or terrified one breaks; favour lands as relief or as vindication.
	var courage:=float(person.get("courage",0.5))
	var pride:=float(person.get("pride",0.5))
	var dread:=dread_of(person)
	match action:
		"terrify","penance":
			if pride>0.7 and courage>0.65 and dread<0.6: return "defy"
			if courage<0.45 or dread>=0.5: return "cower"
			return "endure"
		"bless","boon","raise_up":
			if dread>=0.45: return "relief"
			return "blessed"
	return "none"

static func target_deltas(action:String,person:Dictionary)->Dictionary:
	var courage:=clampf(float(person.get("courage",0.5)),0.0,1.0)
	var pride:=clampf(float(person.get("pride",0.5)),0.0,1.0)
	var defiant:=response_to(action,person)=="defy"
	match action:
		"terrify":
			var gain:=(0.14+0.12*(1.0-courage))*(0.6 if defiant else 1.0)
			return {"fear":gain,"love":-0.03,"resentment":0.02+0.07*pride+(0.05 if defiant else 0.0),"trust":-0.02}
		"penance":
			return {"fear":0.07*(0.6 if defiant else 1.0),"obligation":0.08,"respect":0.02,"love":-0.01,"resentment":0.05*pride+(0.04 if defiant else 0.0)}
		"bless": return {"love":0.12,"fear":-0.05,"resentment":-0.06,"trust":0.04}
		"boon": return {"love":0.08,"obligation":0.10,"resentment":-0.05,"trust":0.03}
		"raise_up": return {"respect":0.10,"love":0.06,"obligation":0.06,"resentment":-0.03}
	return {}

static func witness_deltas(action:String,witness:Dictionary)->Dictionary:
	var courage:=clampf(float(witness.get("courage",0.5)),0.0,1.0)
	var pride:=clampf(float(witness.get("pride",0.5)),0.0,1.0)
	match action:
		"terrify": return {"fear":0.04*(1.2-courage),"resentment":0.01*pride}
		"penance": return {"fear":0.02*(1.2-courage)}
		"cast_out": return {"fear":0.07*(1.2-courage),"love":-0.02,"resentment":0.02*pride}
		"strike_down": return {"fear":0.10+0.08*(1.0-courage),"love":-0.05,"trust":-0.04,"resentment":0.02+0.05*pride}
		"bless": return {"love":0.015,"resentment":0.02 if pride>0.7 else 0.0}
		"boon": return {"love":0.01,"resentment":0.02 if pride>0.65 else 0.0}
		"raise_up": return {"resentment":0.03} if pride>0.6 else {"respect":0.01}
	return {}

static func witness_response(action:String,witness:Dictionary)->String:
	var d:=witness_deltas(action,witness)
	if action in WRATH:
		if float(witness.get("pride",0.5))>0.72 and float(witness.get("courage",0.5))>0.68: return "unbowed"
		return "shaken"
	return "envy" if float(d.get("resentment",0.0))>0.0 else "glad"

const TARGET_MEMORY:={
	"terrify":["The god's fury broke over me before the whole court. I have not stopped shaking.","The god raged at me in the hall. I stood, but I will not forget it.","The god's anger fell on me in the hall; I bore it."],
	"penance":["The god demanded penance of me. I will fast and keep vigil until I am forgiven.","The god demanded penance of me before the court. I will do it, and remember it.","The god demanded penance of me; I will pay it."],
	"bless":["The god blessed me before the whole court.","The god blessed me in the hall, and the dread went out of me."],
	"boon":["The god gave me a gift from the stores with their own hand.","The god gave me a gift from the stores, and my fear eased."],
	"raise_up":["The god raised me up above my peers before the court.","The god raised me up in the hall; I can breathe again."],
}
const WITNESS_MEMORY:={
	"terrify":"I watched the god's fury fall on %s in the hall.",
	"penance":"I watched the god demand penance of %s.",
	"cast_out":"I watched the god cast %s out of the realm.",
	"strike_down":"I watched %s put to death at the god's word, in the hall.",
	"bless":"I watched the god bless %s before us all.",
	"boon":"I watched the god give %s a gift from the stores.",
	"raise_up":"I watched the god raise %s above the rest of us.",
}

static func apply_to_court(action:String,target:Dictionary,witnesses:Array)->Dictionary:
	## Bond shifts for the target (unless removed) and each witness, with
	## memories. Returns what happened to each, for the voice and the tests.
	var pid:=int(target.get("person_id",0))
	var name:=String(target.get("name","them"))
	var result:={"action":action,"person_id":pid,"response":response_to(action,target),"witnesses":{}}
	if pid>0 and not action in TERMINAL:
		var deltas:=target_deltas(action,target)
		var applied:=deltas.duplicate()
		if TARGET_HOLD.has(action): applied["hold_days"]=int(TARGET_HOLD[action])
		result["after"]=GovernmentPeopleSystem.adjust_person_bonds(pid,applied)
		var bank:Array=TARGET_MEMORY.get(action,[])
		if not bank.is_empty():
			var index:=0
			if action in ["terrify","penance"]: index={"cower":0,"defy":1,"endure":2}.get(String(result.response),2)
			elif String(result.response)=="relief": index=1
			GovernmentPeopleSystem.record_person_memory(pid,String(bank[mini(index,bank.size()-1)]),"divine",0.85 if action in WRATH else 0.7,{"emotion":{"cower":"terror","defy":"defiance","endure":"dread","relief":"relief","blessed":"awe"}.get(String(result.response),"awe"),"outcome":action})
	for witness in witnesses:
		if not witness is Dictionary: continue
		var wid:=int(witness.get("person_id",0))
		if wid<=0 or wid==pid: continue
		var wd:=witness_deltas(action,witness)
		var witnessed:=wd.duplicate()
		if WITNESS_HOLD.has(action): witnessed["hold_days"]=int(WITNESS_HOLD[action])
		var after:=GovernmentPeopleSystem.adjust_person_bonds(wid,witnessed)
		(result.witnesses as Dictionary)[wid]={"deltas":wd,"after":after,"response":witness_response(action,witness)}
		if action in ["strike_down","cast_out","terrify","raise_up"] or float(wd.get("resentment",0.0))>0.0:
			GovernmentPeopleSystem.record_person_memory(wid,String(WITNESS_MEMORY.get(action,"I watched the god act on %s.")) % name,"divine",0.8 if action in TERMINAL else 0.5,{"emotion":"dread" if action in WRATH else ("envy" if float(wd.get("resentment",0.0))>0.0 else "awe"),"outcome":action})
	var witness_ids:Array=[]
	for wid in (result.witnesses as Dictionary): witness_ids.append(int(wid))
	_record_event({"day":_day(),"action":action,"person_id":pid,"name":name.substr(0,80),"witnesses":witness_ids.slice(0,6)})
	if action in TERMINAL:
		(store().warned as Dictionary).erase(str(pid))
	return result

static func record_envoy_terror(civ_id:String,civ_name:String,envoy_name:String,amount:float)->void:
	add_civ_dread(civ_id,amount)
	_record_event({"day":_day(),"action":"terrify_envoy","person_id":0,"name":envoy_name.substr(0,80),"civ_id":civ_id.substr(0,64),"civ_name":civ_name.substr(0,80),"witnesses":[]})

static func record_envoy_harm(civ_id:String,civ_name:String,envoy_name:String,harm:String,amount:float)->void:
	## Violence done to a foreign envoy: their people's dread rises, and our own
	## people talk of it (the echo in people_regard).
	add_civ_dread(civ_id,amount)
	var action:=String({"kill":"slay_envoy","mutilate":"maim_envoy"}.get(harm,"shame_envoy"))
	_record_event({"day":_day(),"action":action,"person_id":0,"name":envoy_name.substr(0,80),"civ_id":civ_id.substr(0,64),"civ_name":civ_name.substr(0,80),"witnesses":[]})

# --------------------------------------------------------------------------
# Daily: telegraphing, then flight
# --------------------------------------------------------------------------

static func daily(day:int,officials:Array)->Array[Dictionary]:
	## Watches for officials whose dread has curdled with resentment. First it
	## shows in their speech (warned); after WARN_DAYS, if it still runs high,
	## they may slip away. Returns the flights that happened today.
	var fled:Array[Dictionary]=[]
	var d:=store()
	if int(d.last_day)==day: return fled
	d["last_day"]=day
	var warned_map:Dictionary=d.warned
	var present:Dictionary={}
	for person in officials:
		if not person is Dictionary: continue
		var pid:=int(person.get("person_id",0))
		if pid<=0: continue
		present[str(pid)]=true
		var risk:=flight_risk(person)
		var key:=str(pid)
		if not warned_map.has(key):
			if risk>=FLIGHT_WARN:
				warned_map[key]=day
				GovernmentPeopleSystem.record_person_memory(pid,"Began to think of slipping away beyond the hills, out of the god's reach.","divine",0.7,{"emotion":"dread","outcome":"thinks_of_flight"})
			continue
		if risk<CALM_BELOW:
			warned_map.erase(key)
			continue
		if day-int(warned_map[key])<WARN_DAYS or risk<FLIGHT_ACT or posmod(day-int(warned_map[key]),10)!=0: continue
		var rng:=RandomNumberGenerator.new()
		rng.seed=hash("%d|flight|%d|%d" % [int(GameState.world_seed),pid,day])
		if rng.randf()>=risk*0.3: continue
		var gone:=GovernmentPeopleSystem.person_departs(pid,"fled")
		if bool(gone.get("ok",false)):
			warned_map.erase(key)
			_record_event({"day":day,"action":"flight","person_id":pid,"name":String(person.get("name","")).substr(0,80),"witnesses":[]})
			fled.append(gone)
	for key in warned_map.keys():
		if not present.has(String(key)): warned_map.erase(key)
	return fled

# --------------------------------------------------------------------------
# Words
# --------------------------------------------------------------------------

## The ruler's own words, read offline. Only spoken acts; exile, execution and
## gifts need the explicit decree.
const INTENT_PATTERNS:=[
	["terrify","(?i)\\b(i (will|shall|could|can) (destroy|crush|burn|break|unmake|smite|end|ruin|flay|bury|drown|scatter) (you|thee)|destroy you|tremble|kneel before me|on your knees|bow (down )?before me|fear me|dread me|feel my (wrath|fury|anger)|my (wrath|fury) (will|shall)|you (will|shall) (die|suffer|burn|perish|weep)|how dare you|grovel|i am your god|beneath my heel|i will have your (head|hide|skin))\\b"],
	["penance","(?i)\\b(penance|atone|atonement|make amends to me|repent|fast (and|until|for)|keep vigil|beg my forgiveness|earn back my favou?r)\\b"],
	["bless","(?i)\\b(i bless (you|thee)|bless(ed)? be you|my blessing (is|upon|on)|you have my (blessing|favou?r)|i am pleased with you|i favou?r you)\\b"],
	["raise_up","(?i)\\b(i raise you|i (will|shall) raise you|i exalt you|i elevate you|i honou?r you above|rise,? (and )?stand among|first among)\\b"],
]

static func intent(text:String)->String:
	var clean:=text.strip_edges()
	if clean.is_empty() or clean.length()>400: return ""
	for pair in INTENT_PATTERNS:
		var re:=RegEx.new(); re.compile(String(pair[1]))
		if re.search(clean)!=null: return String(pair[0])
	return ""

static func meter_words(love:float,dread:float)->String:
	## Two short gauges for a list row.
	return "love %s · dread %s" % [_band(love),_band(dread)]

static func _band(v:float)->String:
	if v>=0.75: return "overwhelming"
	if v>=0.55: return "high"
	if v>=0.35: return "some"
	if v>=0.15: return "little"
	return "none"

static func meter_texture(love:float,dread:float,size:int=24)->Texture2D:
	## A tiny two-bar gauge for list rows: love (gold) above, dread (red) below.
	var image:=Image.create(size,size,false,Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,0))
	var h:=int(size*0.28)
	var y_love:=int(size*0.18); var y_dread:=int(size*0.56)
	var track:=Color(0.5,0.5,0.5,0.35)
	image.fill_rect(Rect2i(0,y_love,size,h),track)
	image.fill_rect(Rect2i(0,y_dread,size,h),track)
	image.fill_rect(Rect2i(0,y_love,maxi(1,roundi(clampf(love,0.0,1.0)*size)),h),Color("d9a93a"))
	image.fill_rect(Rect2i(0,y_dread,maxi(1,roundi(clampf(dread,0.0,1.0)*size)),h),Color("c2453a"))
	return ImageTexture.create_from_image(image)
