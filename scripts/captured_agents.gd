extends RefCounted
## CAPTURED AGENTS: a spy or assassin our watch takes is a person, held under
## guard, questioned before the god and given a fate, by stated odds and
## seeded rolls from the one ledger (docs/ADJUDICATION.md). Every people runs
## the same rules: our own agents taken abroad are judged by that people's
## ruler with the same odds, decided by that ruler's temper.
##
## THE PRISONER
##   Named in their own people's tongue (era_names.gd, people_language.gd),
##   drawn in their people's look (people_appearance.gd), with a temper, a
##   courage, a loyalty to their ruler (from that ruler's character,
##   rival_rulers.gd) and a family at home or none. They hold a FACT SHEET made
##   from the ledger when they were taken: who sent them and that ruler's
##   temper, their errand and its target, their people's fighters and food (at
##   the precision of their rank), their people's plans, and whether others
##   came. Each fact carries one coherent falsehood beside it. A held prisoner
##   eats a ration a day from our stores and may escape, at stated odds a
##   month that our watch sets.
##
## QUESTIONING (player-initiated: the notice's "Bring them before you", or the
##   court's list of those held under guard). Five questions, three manners
##   (gentle, firm, in terror). Whether they talk and whether they lie are two
##   seeded rolls whose odds are shown before the god asks; terror raises both.
##   A lie is recorded false in the ledger with the truth beside it, and is
##   shown false once our own intelligence contradicts it (a watcher's report
##   after it, another prisoner's true word, the prisoner won over, a spy of
##   theirs taken after "I came alone", a raid after "they want peace").
##   The god's wrath and favour (terrify, bless, feed and tend, strike down)
##   move their dread, love and treatment, and so every later odds.
##
## FATES (each card shows its real effects and odds):
##   execute       our people's dread rises; their people hear of it on stated
##                 odds (a grudge, their view of us falls); their schemes
##                 against us are rarer for a year either way (deterrence).
##   send home     with a message (a warning, a threat, an offer of peace, a
##                 demand; the god's own words recorded as spoken). On arrival
##                 their ruler's answer is rolled from temper and relation;
##                 relations, grudges and deterrence follow, and a reply may
##                 come later through the ordinary envoy occasions.
##   turn them     a course of care and teaching (weeks; a ration, better food
##                 and a carer's lost work a day). Won over: they join our
##                 people (+1), tell all they know truly (past lies shown
##                 false) and may be sent back as our eyes (a double agent, a
##                 plant op with stated odds of being found). Unmoved: still
##                 held. Pretending: they seem won over, then flee home or
##                 fire a store before fleeing (small, bounded).
##   keep          the default: a ration a day and the monthly escape odds.
##                 (An exchange or ransom can hang off "held" later: hook
##                 ransom_terms().)
##
## State: ForeignDiplomacy.audiences["captives"], saved with the court; older
## saves start empty. Static helpers; preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const CV:=preload("res://scripts/character_voice.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const Look:=preload("res://scripts/people_appearance.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const OfficeLevers:=preload("res://scripts/office_levers.gd")
const EXCHANGE:=preload("res://scripts/civilization_exchange.gd")
const COVERT_PATH:="res://scripts/covert_ops.gd"
const RIVALS_PATH:="res://scripts/rival_rulers.gd"
const WAR_PATH:="res://scripts/war_loop.gd"
const Food:=preload("res://scripts/food_system.gd")

const KEY:="captives"
const VERSION:=1
const RECORDS_MAX:=24
const ABROAD_MAX:=16
const SAID_MAX:=20
const LIVE:=["held","turning","joined"]

const TOPICS:=["sender","mission","strength","plans","others"]
const MANNERS:=["gentle","firm","terror"]
const MESSAGES:=["warning","threat","peace","demand"]

## A ration a day for a held prisoner (food_system.gd: one adult-equivalent
## daily ration).
const RATION:=1.0
## Better food while they are tended (on top of the ration).
const CARE_FOOD:=0.5
## How long deterrence lasts after an execution (days).
const DETER_DAYS:=365
## A double agent sends word this often (covert_ops PLANT_REPORT_DAYS).
const DOUBLE_REPORT_DAYS:=90
## A blessing or a gift of food given to one prisoner counts again only after
## this many days (re-summoning them does not renew it).
const FAVOUR_DAYS:=30

const QUESTION_LABELS:={"sender":"Who sent you?","mission":"What were you sent to do?","strength":"How strong is your people?","plans":"What are they planning?","others":"Are there others?"}
const MANNER_LABELS:={"gentle":"Ask gently ▾","firm":"Ask firmly ▾","terror":"Ask in terror ▾"}
## The god's words for each question, as the menus say them.
const ASKED:={
	"gentle":{"sender":"No one will harm you here. Who sent you?","mission":"Eat first. Then tell me what you were sent to do.","strength":"Tell me of your people. How many fighters, and how much food?","plans":"What do your people mean to do? You are safe to say it.","others":"Did anyone else come with you? No harm comes to you for saying."},
	"firm":{"sender":"Who sent you?","mission":"What were you sent to do?","strength":"How strong is your people?","plans":"What are they planning?","others":"Are there others?"},
	"terror":{"sender":"Who sent you? Speak, or the guards start on your fingers.","mission":"What were you sent to do? Lie to me and you burn.","strength":"How many fighters? The truth, or you will beg to tell it.","plans":"What are your people planning? Speak!","others":"Who else came with you? Name them, or die slowly."},
}
const TEMPERS:=["quiet and watchful","hot-tempered","sly","stubborn","proud","timid","earnest","sullen"]

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func _day()->int:
	return int(GameState.elapsed_days)

static func _rng(key:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:captive:%s" % [int(GameState.world_seed),key])
	return rng

static func _covert()->GDScript: return load(COVERT_PATH) as GDScript
static func _rivals()->GDScript: return load(RIVALS_PATH) as GDScript
static func _war()->GDScript: return load(WAR_PATH) as GDScript

static func state()->Dictionary:
	ForeignDiplomacy.ensure()
	var holder:Dictionary=ForeignDiplomacy.audiences
	var s:Variant=holder.get(KEY)
	if not s is Dictionary or int((s as Dictionary).get("world_seed",GameState.world_seed))!=int(GameState.world_seed):
		s={"version":VERSION,"world_seed":int(GameState.world_seed),"serial":0,"prisoners":[],"abroad":[],"deterred":{},"stats":{}}
		holder[KEY]=s
	var d:Dictionary=s
	for key in ["prisoners","abroad"]:
		if not d.get(key) is Array: d[key]=[]
	for key in ["deterred","stats"]:
		if not d.get(key) is Dictionary: d[key]={}
	if not (d.get("serial") is int or d.get("serial") is float): d["serial"]=0
	return d

static func valid_state(data:Variant)->bool:
	## Optional save block; absent in older saves.
	if not data is Dictionary: return false
	var d:Dictionary=data
	if d.is_empty(): return true
	if not d.get("prisoners",[]) is Array or (d.get("prisoners",[]) as Array).size()>RECORDS_MAX*2: return false
	if not d.get("abroad",[]) is Array or (d.get("abroad",[]) as Array).size()>ABROAD_MAX*2: return false
	if not d.get("deterred",{}) is Dictionary or not d.get("stats",{}) is Dictionary: return false
	for p in d.get("prisoners",[]):
		if not p is Dictionary or not (p as Dictionary).get("id","") is String or not (p as Dictionary).get("name","") is String: return false
		if not String((p as Dictionary).get("status","")) in ["held","turning","joined","executed","sent_home","escaped","fled","double","dead"]: return false
		if not (p as Dictionary).get("facts",[]) is Array or not (p as Dictionary).get("said",[]) is Array: return false
		if JSON.stringify(p).length()>16000: return false
	for a in d.get("abroad",[]):
		if not a is Dictionary: return false
	return JSON.stringify(d).length()<=250000

static func _stat(key:String,amount:int=1)->void:
	var stats:Dictionary=state().stats
	stats[key]=int(stats.get(key,0))+amount

static func forget()->void:
	## For tests: clear the captives without touching the rest of the save.
	var s:=state()
	s.prisoners=[]; s.abroad=[]; s.deterred={}; s.stats={}; s.serial=0

static func summary()->Dictionary:
	var s:=state()
	var by:Dictionary={}
	for p in s.prisoners: by[String((p as Dictionary).get("status",""))]=int(by.get(String((p as Dictionary).get("status","")),0))+1
	return {"prisoners":(s.prisoners as Array).size(),"by_status":by,"abroad":(s.abroad as Array).size(),"stats":(s.stats as Dictionary).duplicate()}

static func by_id(id:String)->Dictionary:
	for p in state().prisoners:
		if p is Dictionary and String((p as Dictionary).get("id",""))==id: return p
	return {}

static func is_held(id:String)->bool:
	return String(by_id(id).get("status","")) in LIVE

static func held(limit:int=12)->Array:
	## Live prisoners (held, in care, won over), newest first.
	var out:Array=[]
	for p in state().prisoners:
		if String((p as Dictionary).get("status","")) in LIVE: out.append(p)
		if out.size()>=limit: break
	return out

static func is_prisoner_audience(audience_id:String)->bool:
	return Hall.find(audience_id).has("prisoner_id")

static func prisoner_of(audience_id:String)->Dictionary:
	var a:=Hall.find(audience_id)
	if a.is_empty() or not a.has("prisoner_id"): return {}
	return by_id(String(a.prisoner_id))

static func _trim()->void:
	var list:Array=state().prisoners
	var guard:=0
	while list.size()>RECORDS_MAX and guard<64:
		guard+=1
		var drop:=-1
		for i in range(list.size()-1,-1,-1):
			if not String((list[i] as Dictionary).get("status","")) in LIVE and String((list[i] as Dictionary).get("status",""))!="double": drop=i; break
		if drop<0: drop=list.size()-1
		list.remove_at(drop)

# --------------------------------------------------------------------------
# Their people and their ruler
# --------------------------------------------------------------------------

static func _civ(civ_id:String)->Dictionary:
	var index:=Hall._civ_index(civ_id)
	return WorldSimulation.world.civilizations[index] if index>=0 and WorldSimulation.world!=null else {}

static func _relation(civ_id:String)->Dictionary:
	var civ:=_civ(civ_id)
	return civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}

static func _name(civ_id:String)->String:
	return Hall._civ_name(civ_id)

static func _the(civ_id:String)->String:
	var name:=_name(civ_id)
	return name if name.to_lower().begins_with("the ") else "the "+name

static func _upper_first(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)

static func _tier(civ_id:String)->int:
	return int(CV.era_tier(CV.era_tags(civ_id)))

static func _ruler(civ_id:String)->String:
	## Their ruler's name. Their own agent knows it even when we have not met
	## the ruler yet: the same name ForeignDiplomacy.leader gives on meeting.
	var known:=String(_rivals().call("ruler_name",civ_id))
	if known!="their ruler" and known!="": return known
	var serial:=posmod(hash(civ_id),10000)
	var made:=String(EraNames.make(int(GameState.world_seed),serial,serial%2==0,civ_id,{}).get("name",""))
	return made if made!="" else "our %s" % _ruler_word(civ_id)

static func _ruler_given(civ_id:String)->String:
	return _ruler(civ_id).get_slice(" ",0)

static func _ruler_word(civ_id:String)->String:
	return "chief" if _tier(civ_id)<2 else "ruler"

static func _ruler_she(civ_id:String)->bool:
	var c:Dictionary=_rivals().call("character",civ_id)
	if c.is_empty(): return posmod(hash(civ_id),10000)%2==0
	return bool(c.get("woman",false))

static func _temper(civ_id:String)->Dictionary:
	## The ruler's temper as the odds read it: personality (0..1 each), trait,
	## grudge (0..1), view of us and trust, our dread with them, their strength
	## against ours.
	var p:=Hall._personality(civ_id)
	var view:Dictionary=_rivals().call("rival_character",civ_id)
	var regard:=DIVINE.foreign_regard(civ_id)
	var rel:=_relation(civ_id)
	var ratio:=1.0
	if not _civ(civ_id).is_empty(): ratio=float(_war().call("ratio",civ_id))
	return {"a":float(p.get("assertiveness",0.5)),"r":float(p.get("risk_tolerance",0.5)),"e":float(p.get("empathy",0.5)),"d":float(p.get("discipline",0.5)),"o":float(p.get("openness",0.5)),
		"trait":String(view.get("trait","")),"trait_words":String(view.get("trait_words","")),"grudge":clampf(float(view.get("grudge_weight",0.0))/1.5,0.0,1.0),
		"opinion":clampf(float(rel.get("opinion",0.0)),-1.0,1.0),"trust":clampf(float(ForeignDiplomacy.leader(civ_id).get("trust",0.0)),-1.0,1.0),
		"dread":clampf(float(regard.get("dread",DIVINE.civ_dread(civ_id))),0.0,1.0),"ratio":clampf(ratio,0.2,5.0),
		"hot":bool(rel.get("at_war",false)) or bool(_war().call("hot",civ_id)),"at_war":bool(rel.get("at_war",false))}

# --------------------------------------------------------------------------
# Taking a prisoner: identity and the fact sheet
# --------------------------------------------------------------------------

static func take(spy:Dictionary,day:int)->Dictionary:
	## One of theirs taken by our watch (covert_ops._catch_incoming). Returns
	## the prisoner record.
	var s:=state()
	s.serial=int(s.serial)+1
	var serial:=int(s.serial)
	var civ_id:=String(spy.get("civ_id",""))
	var kind:=String(spy.get("kind","watch"))
	var key:="pr:%s:%d:%d" % [civ_id,day,serial]
	var rng:=_rng(key)
	var woman:=rng.randf()<0.3
	var taken:Dictionary={}
	for p in s.prisoners: taken[String((p as Dictionary).get("name",""))]=true
	var identity:Dictionary=EraNames.make(int(GameState.world_seed),60000+serial,woman,civ_id,taken)
	var name:=String(identity.get("name",""))
	if name=="": name="A stranger of %s" % _name(civ_id)
	var tier:=_tier(civ_id)
	var rank:="kinsman" if tier<1 else ("sworn" if tier<2 else "trained")
	if kind=="assassinate": rank="chief's man" if tier<2 else "trained"
	var temper:=String(TEMPERS[rng.randi_range(0,TEMPERS.size()-1)])
	var courage:=rng.randf_range(0.45,0.9) if kind=="assassinate" else rng.randf_range(0.25,0.8)
	if temper=="timid": courage-=0.15
	elif temper in ["proud","hot-tempered","stubborn"]: courage+=0.08
	# Loyalty to their ruler, from that ruler's character: a disciplined,
	# commanding ruler binds men harder; a grudge-holder's men share the grudge;
	# the chief's own man is bound by blood or oath.
	var t:=_temper(civ_id)
	var loyalty:=0.35+float(t.d)*0.2+float(t.a)*0.12+(0.06 if String(t.trait)=="grudge" else 0.0)+(0.15 if kind=="assassinate" else 0.0)+(0.05 if rank=="trained" else 0.0)+rng.randf_range(-0.1,0.12)
	var regard:=DIVINE.foreign_regard(civ_id)
	var age:=rng.randi_range(20,40) if kind=="assassinate" else rng.randi_range(18,46)
	var spouse:=age>=20 and rng.randf()<0.6
	var children:=rng.randi_range(1,4) if spouse and age>=24 and rng.randf()<0.75 else 0
	var profile:=Look.profile(civ_id)
	var skin:Array=profile.get("skin",[]) if profile.get("skin") is Array else []
	var hair:Array=profile.get("hair",[]) if profile.get("hair") is Array else []
	var cloth:Array=profile.get("cloth",[]) if profile.get("cloth") is Array else []
	var p:={
		"id":"pr_%d" % serial,"serial":serial,"seed":key,"civ_id":civ_id,"civ_name":_name(civ_id),"kind":kind,"rank":rank,
		"name":name,"given":String(identity.get("given",name.get_slice(" ",0))),"sex":"female" if woman else "male","age":age,
		"look":{"skin":String(skin[rng.randi_range(0,skin.size()-1)]) if not skin.is_empty() else "","hair":String(hair[rng.randi_range(0,hair.size()-1)]) if not hair.is_empty() else "",
			"cloth":String(cloth[rng.randi_range(0,cloth.size()-1)]) if not cloth.is_empty() else "","words":String(profile.get("words",""))},
		"temper":temper,"courage":snappedf(clampf(courage,0.05,0.95),0.01),"loyalty":snappedf(clampf(loyalty,0.1,0.95),0.01),
		"family":{"spouse":spouse,"children":children},
		"love":snappedf(clampf(float(regard.get("love",0.4))*0.5,0.05,0.6),0.01),"dread":snappedf(clampf(float(regard.get("dread",0.15))+0.15,0.05,0.9),0.01),
		"treatment":0.0,"status":"held","taken_day":day,"status_day":day,"where":_town(),
		"target":_target_for(kind,rng),"facts":[],"said":[],"asked":{},"divine":[],"food_spent":0.0,"hungry_days":0,
		"audience_id":"","feigned":false,
	}
	p["facts"]=make_facts(p,day)
	(s.prisoners as Array).push_front(p)
	_trim()
	# Any earlier "I came alone" from a prisoner of the same people is shown
	# false by this one's taking.
	_contradict_others(civ_id,day,String(p.id))
	_stat("taken")
	return p

static func age_now(p:Dictionary)->int:
	## Their real age today (taken at `age`, on `taken_day`).
	return int(p.get("age",30))+floori(float(maxi(0,_day()-int(p.get("taken_day",_day()))))/365.0)

static func _cohort_of(age:int)->String:
	for key in GameState.POPULATION_AGE_COHORTS:
		var span:Vector2=GameState.POPULATION_COHORT_AGE_RANGES[key]
		if float(age)<span.y: return String(key)
	return "elders"

static func _joins_our_count(p:Dictionary,source:String)->void:
	## Won over (or seeming so): one person of their own age group and sex
	## joins our people's count.
	var cohort:=_cohort_of(age_now(p))
	p["counted"]={"cohort":cohort,"sex":String(p.get("sex","male")),"day":_day()}
	GameState.register_population_arrivals(1,source,{cohort:1.0},1.0 if String(p.get("sex",""))=="female" else 0.0)

static func _leaves_our_count(p:Dictionary,reason:String,death:bool)->void:
	## One counted among us leaves it as who they are: their own age group
	## and sex, by a death or a departure. Nothing when they were never counted.
	if not p.has("counted"): return
	var cohort:=_cohort_of(age_now(p))
	var sex:=String(p.get("sex","male"))
	p.erase("counted")
	if death:
		var done:Dictionary=GameState.register_population_deaths_by_cell([{"cohort":cohort,"sex":sex,"count":1}],"prisoner_put_to_death",reason,String(p.get("name","")))
		if int(done.get("count",0))<=0: GameState.register_population_deaths(1,reason)
	else:
		var only:={}
		for key in GameState.POPULATION_AGE_COHORTS: only[key]=1.0 if key==cohort else 0.0
		var gone:Dictionary=GameState.register_population_departures(1,reason,only,sex)
		if int(gone.get("count",0))<=0: GameState.register_population_departures(1,reason)

static func _town()->String:
	var n:=String(GameState.settlement_name).strip_edges()
	return n if n!="" else "our town"

static func _target_for(kind:String,rng:RandomNumberGenerator)->Dictionary:
	## Whom an assassin was sent for: one of the god's own officials, the war
	## leader first (it is from the ledger: they hold that office now).
	if kind!="assassinate": return {}
	var officials:Array[Dictionary]=Hall._officials()
	for office in ["Marshal","Steward"]:
		for person in officials:
			if String(person.get("office_key",""))==office: return {"name":String(person.get("name","")),"title":String(person.get("office_title","")).to_lower(),"person_id":int(person.get("person_id",0))}
	if not officials.is_empty():
		var pick:Dictionary=officials[rng.randi_range(0,officials.size()-1)]
		return {"name":String(pick.get("name","")),"title":String(pick.get("office_title","")).to_lower(),"person_id":int(pick.get("person_id",0))}
	return {"name":"","title":"whoever speaks for the god in this hall","person_id":0}

static func _nice(x:float)->int:
	if x>=1000.0: return roundi(x/50.0)*50
	if x>=100.0: return roundi(x/10.0)*10
	if x>=20.0: return roundi(x/5.0)*5
	return maxi(0,roundi(x))

static func _width(rank:String)->float:
	## How closely an agent of this rank knows their own people's numbers.
	match rank:
		"kinsman": return 0.5
		"sworn": return 0.3
		"chief's man": return 0.25
	return 0.15

static func _fighters(civ_id:String)->int:
	if _civ(civ_id).is_empty(): return 0
	return int(_war().call("_their_fighters",civ_id))

static func _others_now(civ_id:String,except_id:String="")->int:
	## Other agents of theirs in our lands or on the road to them now.
	var n:=0
	for spy in (_covert().call("state") as Dictionary).get("incoming",[]):
		if String((spy as Dictionary).get("civ_id",""))==civ_id and String((spy as Dictionary).get("prisoner_id",""))!=except_id: n+=1
	return n

static func make_facts(p:Dictionary,day:int)->Array:
	## What the prisoner actually knows, from the ledger, at their rank's
	## precision; each with one coherent falsehood. [{topic,text,lie,value,lie_value}]
	var civ_id:=String(p.civ_id)
	var rng:=_rng(String(p.seed)+":facts")
	var who:=_ruler(civ_id)
	var given:=_ruler_given(civ_id)
	var word:=_ruler_word(civ_id)
	var she:=_ruler_she(civ_id)
	var t:=_temper(civ_id)
	var out:Array=[]
	# Who sent them, and that ruler's temper.
	var temper_words:=String(t.trait_words)
	var sender:="%s, our %s, sent me.%s" % [who,word," %s %s." % ["She" if she else "He",temper_words] if temper_words!="" else ""]
	var other:=_other_people(civ_id,rng)
	var sender_lie:="%s paid me to come. My own people know nothing of it." % _upper_first(_the(other)) if other!="" else "No one sent me. I came on my own, to trade."
	out.append({"topic":"sender","text":sender,"lie":sender_lie,"value":civ_id,"lie_value":other})
	# Their errand and its target.
	var mission:="To watch your town: to count your fighters and your stores, and carry word home to %s." % given
	var mission_lie:="I came to trade. Nothing more."
	if String(p.kind)=="assassinate":
		var target:Dictionary=p.get("target",{}) if p.get("target") is Dictionary else {}
		var whom:=("your %s, %s" % [String(target.get("title","war leader")),String(target.get("name",""))]) if String(target.get("name",""))!="" else String(target.get("title","whoever speaks for the god"))
		mission="To kill %s. %s wanted it done before the next moon." % [whom,given]
		mission_lie="Only to watch and count, and to go home."
	out.append({"topic":"mission","text":mission,"lie":mission_lie,"value":String(p.kind),"lie_value":"trade" if String(p.kind)!="assassinate" else "watch"})
	# Their strength: fighters and food, at their rank's precision.
	var fighters:=_fighters(civ_id)
	var food:=float(_civ(civ_id).get("food_days",30.0))
	var w:=_width(String(p.rank))
	var strength:=""
	if fighters<=0: strength="We keep no fighters to speak of; every grown man hunts and fights when he must. Our food would last about %d days." % _nice(food)
	else: strength="We have between %s and %s fighters, and food for about %d days." % [EraWords.grouped(_nice(float(fighters)*(1.0-w))),EraWords.grouped(_nice(float(fighters)*(1.0+w))),_nice(food)]
	var boast:=float(t.a)>=0.5
	var scale:=rng.randf_range(2.2,3.0) if boast else rng.randf_range(0.35,0.5)
	var lie_fighters:=maxf(12.0,float(maxi(fighters,8))*scale)
	var lie_food:=food*(2.0 if boast else 0.5)
	var strength_lie:="We have between %s and %s fighters, and food for about %d days." % [EraWords.grouped(_nice(lie_fighters*(1.0-w))),EraWords.grouped(_nice(lie_fighters*(1.0+w))),_nice(lie_food)]
	out.append({"topic":"strength","text":strength,"lie":strength_lie,"value":fighters,"lie_value":roundi(lie_fighters),"food":roundi(food)})
	# Their plans, from the war ledger.
	var plans:=_plans(civ_id,String(p.rank),day)
	var peace_lie:="%s wants only peace with you. No one at our fires speaks of raiding." % given
	var war_lie:="%s is gathering men to come at you before the cold season." % given
	out.append({"topic":"plans","text":String(plans.text),"lie":war_lie if String(plans.value)=="peace" else peace_lie,"value":String(plans.value),"lie_value":"hostile" if String(plans.value)=="peace" else "peace"})
	# Others.
	var others:=_others_now(civ_id,String(p.get("id","")))
	var others_text:="No one else came with me." if others<=0 else "%s more of us %s on the road behind me." % [EraWords.count_word(others).capitalize(),"is" if others==1 else "are"]
	var others_lie:="Three more are already among your people." if others<=0 else "I came alone."
	out.append({"topic":"others","text":others_text,"lie":others_lie,"value":others,"lie_value":3 if others<=0 else 0})
	return out

static func _other_people(civ_id:String,rng:RandomNumberGenerator)->String:
	var pool:Array=[]
	if WorldSimulation.world==null: return ""
	for civ in WorldSimulation.world.civilizations:
		var id:=String((civ as Dictionary).get("id",""))
		if id=="" or id=="player" or id==civ_id or not bool((civ as Dictionary).get("alive",true)): continue
		pool.append(id)
	if pool.is_empty(): return ""
	return String(pool[rng.randi_range(0,pool.size()-1)])

static func _plans(civ_id:String,rank:String,day:int)->Dictionary:
	## What their people mean to do, from the war ledger: {text, value:"hostile"|"peace"}.
	var given:=_ruler_given(civ_id)
	var rel:=_relation(civ_id)
	var front:Dictionary=_war().call("_peek",civ_id)
	var pending:Dictionary=front.get("pending",{}) if front.get("pending") is Dictionary else {}
	if bool(rel.get("at_war",false)): return {"text":"We are at war with you, and %s means to keep at it until you yield." % given,"value":"hostile"}
	if not pending.is_empty():
		var due:=int(pending.get("day",day))-day
		var when:="soon" if rank=="kinsman" else ("within %d days" % maxi(1,due) if due>0 else "any day now")
		var cause:=String(pending.get("cause",""))
		return {"text":"%s means to send men against you %s%s." % [given,when,(", over "+cause) if cause!="" and rank!="kinsman" else ""],"value":"hostile"}
	if bool(_war().call("feuding",civ_id)): return {"text":"The feud stands. Our men will come again; %s has not let it go." % given,"value":"hostile"}
	var civ:=_civ(civ_id)
	for other_id in (civ.get("relations",{}) as Dictionary):
		var r:Variant=(civ.relations as Dictionary)[other_id]
		if r is Dictionary and (bool((r as Dictionary).get("at_war",false))):
			return {"text":"We are fighting %s; that is where our men go." % _the(String(other_id)),"value":"peace"}
	var view:Dictionary=_rivals().call("rival_character",civ_id)
	var grudges:Array=view.get("grudges",[]) if view.get("grudges") is Array else []
	if not grudges.is_empty():
		return {"text":"%s has not forgotten %s. Nothing is set for now, but %s watches you." % [given,String((grudges[0] as Dictionary).get("text","an old wrong")),"she" if _ruler_she(civ_id) else "he"],"value":"hostile"}
	var goals:Array=ForeignDiplomacy.leader(civ_id).get("goals",[]) if ForeignDiplomacy.leader(civ_id).get("goals") is Array else []
	var want:=String((goals[0] as Dictionary).get("title","")).to_lower() if not goals.is_empty() and goals[0] is Dictionary else "be left alone to hunt and grow"
	return {"text":"%s plans nothing against you that I know of. %s wants to %s." % [given,"She" if _ruler_she(civ_id) else "He",want],"value":"peace"}

static func fact(p:Dictionary,topic:String)->Dictionary:
	for f in p.get("facts",[]):
		if String((f as Dictionary).get("topic",""))==topic: return f
	return {}

# --------------------------------------------------------------------------
# Questioning: stated odds, seeded rolls, answers from the fact sheet only
# --------------------------------------------------------------------------

static func ask_odds(p:Dictionary,topic:String,manner:String)->Dictionary:
	## Whether they talk, and whether what they say is a lie. Stated before the
	## god asks; the roll uses exactly these. A won-over prisoner always talks
	## (and only lies if they are pretending).
	var love:=clampf(float(p.get("love",0.3)),0.0,1.0)
	var dread:=clampf(float(p.get("dread",0.2)),0.0,1.0)
	var loyalty:=clampf(float(p.get("loyalty",0.5)),0.0,1.0)
	var courage:=clampf(float(p.get("courage",0.5)),0.0,1.0)
	var kind:=clampf(float(p.get("treatment",0.0)),-1.0,1.0)
	var rounds:=int((p.get("asked",{}) as Dictionary).get(topic,0))
	var talk:=0.36+dread*0.30+love*0.30+kind*0.10-loyalty*0.30-courage*0.15+float(mini(rounds,4))*0.05
	talk+=float({"gentle":0.0,"firm":0.10,"terror":0.28}.get(manner,0.1))
	talk+=float({"sender":0.08,"mission":0.0,"strength":0.0,"plans":-0.05,"others":-0.05}.get(topic,0.0))
	var lie:=0.08+loyalty*0.30+courage*0.10-love*0.20-kind*0.05
	lie+=float({"gentle":-0.04,"firm":0.06,"terror":0.25}.get(manner,0.06))
	lie+=float({"others":0.05,"plans":0.03}.get(topic,0.0))
	talk=clampf(talk,0.03,0.95); lie=clampf(lie,0.02,0.85)
	if String(p.get("status",""))=="joined":
		talk=1.0
		lie=clampf(lie,0.02,0.85) if bool(p.get("feigned",false)) else 0.0
	return {"talk":snappedf(talk,0.0001),"lie":snappedf(lie,0.0001),"topic":topic,"manner":manner,"rounds":rounds}

static func pct(x:float)->String:
	return "%d in 100" % clampi(roundi(x*100.0),0,100)

static func choices(audience_id:String)->Array[Dictionary]:
	## The offline menus: each question in each manner, with its stated odds.
	var out:Array[Dictionary]=[]
	var p:=prisoner_of(audience_id)
	var a:=Hall.find(audience_id)
	if p.is_empty() or a.is_empty() or String(a.get("status",""))!="waiting" or not String(p.get("status","")) in LIVE: return out
	for manner in MANNERS:
		if String(p.status)=="joined" and manner!="gentle": continue
		for topic in TOPICS:
			var odds:=ask_odds(p,topic,manner)
			var known:=_last_said(p,topic)
			var tail:=""
			if not known.is_empty() and bool(known.get("talked",false)) and String(p.status)!="joined": tail=" · already answered"
			elif String(p.status)=="joined": tail=" · tells it" if not bool(p.get("feigned",false)) else " · tells it"
			else: tail=" · answers %s; if so, a lie %s" % [pct(float(odds.talk)),pct(float(odds.lie))]
			out.append({"action":"prisoner_ask","label":String(QUESTION_LABELS[topic])+tail,"group":manner,"params":{"topic":topic,"manner":manner},"odds":odds})
	return out

static func _last_said(p:Dictionary,topic:String)->Dictionary:
	var said:Array=p.get("said",[]) if p.get("said") is Array else []
	for i in range(said.size()-1,-1,-1):
		if String((said[i] as Dictionary).get("topic",""))==topic: return said[i]
	return {}

static func _say(audience_id:String,p:Dictionary,text:String)->void:
	if audience_id=="" or Hall.find(audience_id).is_empty(): return
	Hall.append_line(audience_id,{"speaker":String(p.name),"role":"official","person_id":0,"text":text,"day":_day()})

static func _narrate(audience_id:String,text:String,about:String="")->void:
	if audience_id=="" or Hall.find(audience_id).is_empty(): return
	var line:={"speaker":"","role":"narrator","person_id":0,"text":text,"day":_day()}
	if about!="": line["about"]=about
	Hall.append_line(audience_id,line)

static func _god(audience_id:String,text:String)->void:
	if audience_id=="" or Hall.find(audience_id).is_empty() or text.strip_edges()=="": return
	Hall.append_line(audience_id,{"speaker":"You","role":"ruler","person_id":0,"text":text,"day":_day()})

static func decide_question(p:Dictionary,topic:String,manner:String)->Dictionary:
	## The seeded rolls for this question now, without applying them. Same
	## record, same counters: same rolls (viewing never rolls again).
	var odds:=ask_odds(p,topic,manner)
	var rounds:=int(odds.rounds)
	var rng:=_rng("q|%s|%s|%d|%s" % [String(p.get("seed",p.get("id",""))),topic,rounds,manner])
	var r_talk:=rng.randf()
	var r_lie:=rng.randf()
	var talked:=r_talk<float(odds.talk)
	var lied:=talked and r_lie<float(odds.lie)
	return {"odds":odds,"r_talk":r_talk,"r_lie":r_lie,"talked":talked,"lied":lied}

static func ask(audience_id:String,topic:String,manner:String,echo:String="")->Dictionary:
	## One question put to the prisoner before the god. Answered from the fact
	## sheet only: the true fact, its recorded falsehood, or silence.
	var p:=prisoner_of(audience_id)
	var a:=Hall.find(audience_id)
	if p.is_empty() or a.is_empty() or String(a.get("status",""))!="waiting": return {"ok":false,"handled":false,"outcome":"No prisoner is before you."}
	if not topic in TOPICS: return {"ok":false,"handled":false,"outcome":"That is not something they can be asked."}
	if not manner in MANNERS: manner="firm"
	if String(p.status)=="joined": manner="gentle"
	_god(audience_id,echo if echo.strip_edges()!="" else String(ASKED[manner][topic]))
	a["prisoner_manner"]=manner
	var f:=fact(p,topic)
	var prior:=_last_said(p,topic)
	var given:=String(p.given)
	# An answer already given stands: they say it again (no new roll), unless
	# they have since been won over and now tell it truly.
	if not prior.is_empty() and bool(prior.get("talked",false)) and not (String(p.status)=="joined" and bool(prior.get("lied",false)) and not bool(p.get("feigned",false))):
		_say(audience_id,p,"I told you already. %s" % String(prior.get("text","")))
		return {"ok":true,"handled":true,"action":"prisoner_ask","repeat":true,"talked":true,"lied":bool(prior.get("lied",false)),"said":prior,"odds":ask_odds(p,topic,manner),
			"beat":{"beat":"talks","topic":topic,"manner":manner,"talked":true,"lied":bool(prior.get("lied",false))},"outcome":""}
	var d:=decide_question(p,topic,manner)
	var odds:Dictionary=d.odds
	var talked:=bool(d.talked)
	var lied:=bool(d.lied)
	var entry:={"day":_day(),"topic":topic,"manner":manner,"p_talk":float(odds.talk),"p_lie":float(odds.lie),"r_talk":snappedf(float(d.r_talk),0.0001),"r_lie":snappedf(float(d.r_lie),0.0001),
		"talked":talked,"lied":lied,"text":"","truth":"","found_false":false,"found_by":""}
	# Manner first: the room acts it out, and their love, dread and how they
	# have been treated move (after the roll: the odds stated were the odds used).
	match manner:
		"terror":
			_narrate(audience_id,"The guards drag %s to the floor before the god; the hall goes still." % given,given)
			_shift(p,-0.05,0.15,-0.15)
		"gentle":
			_narrate(audience_id,"The guards loosen %s's bonds and set water before them." % given,given)
			# Kindness counts once a day, however many gentle questions.
			if int(p.get("gentle_day",-1))!=_day():
				p["gentle_day"]=_day()
				_shift(p,0.03,0.0,0.05)
		_:
			_shift(p,0.0,0.03,0.0)
	if talked:
		entry.text=String(f.get("lie","")) if lied else String(f.get("text",""))
		if lied: entry.truth=String(f.get("text",""))
		_say(audience_id,p,String(entry.text))
	else:
		entry.text=""
		_say(audience_id,p,_refusal(p,manner))
	var said:Array=p.said
	said.append(entry)
	while said.size()>SAID_MAX: said.pop_front()
	var asked:Dictionary=p.asked
	asked[topic]=int(asked.get(topic,0))+1
	_narrate(audience_id,"(%s: the odds %s would answer were %s; that the answer would be a lie, %s.)" % ["Answered" if talked else "No answer",given,pct(float(odds.talk)),pct(float(odds.lie))])
	# A true word now shows any earlier lie on the same matter false (this
	# prisoner's or another of the same people's).
	if talked and not lied: _contradict_by_truth(String(p.civ_id),topic,f,String(p.id),"%s's own word" % given)
	_stat("asked")
	if talked: _stat("talked")
	if lied: _stat("lied")
	return {"ok":true,"handled":true,"action":"prisoner_ask","talked":talked,"lied":lied,"said":entry,"odds":odds,"outcome":"",
		"beat":{"beat":("lies" if lied else "talks") if talked else ("terror" if manner=="terror" else "refuses"),"topic":topic,"manner":manner,"talked":talked,"lied":lied}}

static func _refusal(p:Dictionary,manner:String)->String:
	var temper:=String(p.get("temper",""))
	if manner=="terror": return "Kill me, then. I will not say it." if float(p.get("courage",0.5))>=0.5 else "Please... I cannot. They would kill my family."
	if manner=="gentle": return "You feed me, and still I will not say it."
	match temper:
		"hot-tempered": return "Ask until your throat bleeds. I say nothing."
		"sly": return "What would you give me for it? Nothing? Then nothing."
		"proud": return "I do not answer to you."
		"timid": return "I... I cannot say."
	return "I will say nothing."

static func _shift(p:Dictionary,love:float,dread:float,treatment:float)->void:
	p["love"]=snappedf(clampf(float(p.get("love",0.3))+love,0.0,1.0),0.01)
	p["dread"]=snappedf(clampf(float(p.get("dread",0.2))+dread,0.0,1.0),0.01)
	p["treatment"]=snappedf(clampf(float(p.get("treatment",0.0))+treatment,-1.0,1.0),0.01)

# --------------------------------------------------------------------------
# What was said, and when our own intelligence shows it false
# --------------------------------------------------------------------------

static func _contradict_by_truth(civ_id:String,topic:String,true_fact:Dictionary,except_id:String,by:String)->void:
	## A true word on a matter shows earlier lies on it false (same people).
	for q in state().prisoners:
		var rec:Dictionary=q
		if String(rec.get("civ_id",""))!=civ_id: continue
		for e in rec.get("said",[]):
			var s:Dictionary=e
			if String(s.get("topic",""))!=topic or not bool(s.get("lied",false)) or bool(s.get("found_false",false)): continue
			if String(rec.get("id",""))==except_id or topic in ["sender","strength","plans"]:
				s["found_false"]=true; s["found_by"]=by

static func _contradict_others(civ_id:String,day:int,new_id:String)->void:
	## A spy of theirs taken after another said "I came alone".
	for q in state().prisoners:
		var rec:Dictionary=q
		if String(rec.get("civ_id",""))!=civ_id or String(rec.get("id",""))==new_id: continue
		for e in rec.get("said",[]):
			var s:Dictionary=e
			if String(s.get("topic",""))=="others" and bool(s.get("lied",false)) and not bool(s.get("found_false",false)) and int(fact(rec,"others").get("value",0))>0 and int(s.get("day",0))<=day:
				s["found_false"]=true; s["found_by"]="another of theirs taken after it"

static func refresh_contradictions()->void:
	## Our own intelligence, read now: a watch report or a source's word on
	## that people after a statement on their strength; a raid or a feud after
	## "they want peace". Cheap; called daily and when the board reads.
	var learned:Array=(_covert().call("state") as Dictionary).get("learned",[])
	# A false word from a double agent who only pretended: shown false by any
	# later true report on that people (learned is newest first).
	for i in learned.size():
		var f:Dictionary=learned[i]
		if not bool(f.get("false",false)) or bool(f.get("found_false",false)): continue
		for j in range(0,i):
			var later:Dictionary=learned[j]
			if String(later.get("civ_id",""))==String(f.get("civ_id","")) and not bool(later.get("false",false)) and int(later.get("day",0))>int(f.get("day",0)):
				f["found_false"]=true; f["found_by"]="a later report: %s" % String(f.get("truth",""))
				break
	for q in state().prisoners:
		var rec:Dictionary=q
		var civ_id:=String(rec.get("civ_id",""))
		for e in rec.get("said",[]):
			var s:Dictionary=e
			if not bool(s.get("lied",false)) or bool(s.get("found_false",false)): continue
			var said_day:=int(s.get("day",0))
			match String(s.get("topic","")):
				"strength":
					for l in learned:
						# Only a true report shows a word false (a pretender's own false
						# word from among them shows nothing).
						if bool((l as Dictionary).get("false",false)): continue
						if String((l as Dictionary).get("civ_id",""))==civ_id and int((l as Dictionary).get("day",0))>=said_day:
							s["found_false"]=true; s["found_by"]="our watcher's count: about %s fighters" % EraWords.grouped(_nice(float(fact(rec,"strength").get("value",0))))
							break
				"plans":
					if String(fact(rec,"plans").get("value",""))=="hostile":
						var front:Dictionary=_war().call("_peek",civ_id)
						if int(front.get("last_harm",-99999))>said_day or bool(_relation(civ_id).get("at_war",false)):
							s["found_false"]=true; s["found_by"]="their men came against us after it"

static func said_rows(p:Dictionary)->Array:
	## What they said, as the court records it: [{topic, text, found_false, found_by, day}].
	var out:Array=[]
	for e in p.get("said",[]):
		var s:Dictionary=e
		if not bool(s.get("talked",false)): continue
		out.append({"topic":String(s.topic),"text":String(s.text),"found_false":bool(s.get("found_false",false)),"found_by":String(s.get("found_by","")),"day":int(s.get("day",0))})
	return out

# --------------------------------------------------------------------------
# The court: summoning, the stage, regard
# --------------------------------------------------------------------------

static func title_of(p:Dictionary)->String:
	var who:="an assassin" if String(p.get("kind",""))=="assassinate" else "a spy"
	match String(p.get("status","")):
		"turning": return "%s of %s, in the carers' keeping" % [who,_the(String(p.civ_id))]
		"joined": return "once %s of %s, now one of us" % [who,_the(String(p.civ_id))]
	return "%s of %s, held under guard" % [who,_the(String(p.civ_id))]

static func summon(id:String)->Dictionary:
	## Bring them before the god: a summons audience of their own. Their
	## first words are said at once (from what they are), so nothing is
	## invented for them.
	var p:=by_id(id)
	if p.is_empty() or not String(p.get("status","")) in LIVE: return {}
	var open:=Hall.find(String(p.get("audience_id","")))
	if not open.is_empty() and String(open.get("status",""))=="waiting": return open
	var day:=_day()
	var audience:=Hall._new_audience("court","summons",day)
	var sex:=String(p.get("sex","male"))
	audience.speaker={"name":String(p.name).substr(0,100),"title":title_of(p).substr(0,100),"person_id":0,"role":"official","prisoner_id":id,"prisoner_civ_id":String(p.civ_id),"sex":sex,"look":(p.get("look",{}) as Dictionary).duplicate()}
	audience.petition={"topic":"summons","summary":"%s is brought before you under guard." % String(p.name),"suggested_decree":""}
	audience.situation={"type":"summons","ask":"summons:prisoner:%s:%d" % [id,day],"headline":"is brought before you","summary":"%s, %s, is brought before you." % [String(p.name),title_of(p)],"occasion":{"type":"summons","text":"the ruler sent for them","day":day,"crisis":false}}
	audience["summoned"]=true
	audience["prisoner_id"]=id
	audience["holder_key"]="prisoner:"+id
	audience["prisoner_manner"]="firm"
	if not Hall._valid_audience(audience): return {}
	Hall._enqueue(audience,day)
	p["audience_id"]=String(audience.id)
	var given:=String(p.given)
	var bound:=String(p.status)=="held"
	if String(p.status)=="joined":
		_narrate(String(audience.id),"%s comes in freely, in the clothes of our people." % given,given)
		_say(String(audience.id),p,"You sent for me. I will tell you what you ask.")
	else:
		_narrate(String(audience.id),"%s is led in between %s guards, %s." % [given,"three" if String(p.kind)=="assassinate" else "two","hands bound" if bound else "unbound, from the carers' hut"],given)
		var first:=_opening(p)
		if first!="": _say(String(audience.id),p,first)
		else: _narrate(String(audience.id),"%s keeps silent, eyes on the floor." % given,given)
	_stat("summoned")
	return audience

static func _opening(p:Dictionary)->String:
	match String(p.get("temper","")):
		"proud": return "I am %s of %s. I will not kneel to you." % [String(p.given),_the(String(p.civ_id))]
		"timid": return "Do not hurt me. I only did what I was told."
		"hot-tempered": return "Do it quickly, whatever you mean to do."
		"sly": return "A god who keeps prisoners. What does the god want with me?"
		"earnest": return "I came to do my people's work. Ask, and we will see."
		"stubborn": return "I have nothing to say to you."
		"sullen": return "Get on with it."
	return ""

static func stage_view(audience_id:String)->Dictionary:
	## For the court stage (builder L): how to stand and act the prisoner.
	var p:=prisoner_of(audience_id)
	if p.is_empty(): return {}
	var last:Dictionary=(p.said as Array).back() if not (p.said as Array).is_empty() else {}
	return {"prisoner":true,"bound":String(p.status)=="held","guards":(3 if String(p.kind)=="assassinate" else 2) if String(p.status)!="joined" else 0,
		"civ_id":String(p.civ_id),"sex":String(p.get("sex","male")),"look":(p.get("look",{}) as Dictionary).duplicate(),"mood":_mood(p),
		"manner":String(Hall.find(audience_id).get("prisoner_manner","firm")),
		"last_beat":{} if last.is_empty() else {"kind":("lies" if bool(last.lied) else "talks") if bool(last.talked) else "refuses","topic":String(last.topic)}}

static func _mood(p:Dictionary)->String:
	if String(p.get("status",""))=="joined": return "won"
	var dread:=float(p.get("dread",0.2)); var love:=float(p.get("love",0.3))
	if dread>=0.7: return "broken"
	if dread>=0.45: return "afraid"
	if love>=0.45: return "calm"
	return "defiant"

static func regard(audience_id:String)->Dictionary:
	var p:=prisoner_of(audience_id)
	if p.is_empty(): return {}
	var love:=float(p.get("love",0.3)); var dread:=float(p.get("dread",0.2))
	var read:="defies you"
	match _mood(p):
		"won": read="is one of us now"
		"broken": read="is broken by terror"
		"afraid": read="is afraid of you"
		"calm": read="is softening toward you"
	if float(p.get("treatment",0.0))<=-0.4 and dread>=0.45: read="fears you and hates you for it"
	return {"id":"terror" if dread>=0.55 else ("reveres" if love>=0.55 else "wary"),"read":read,"love":love,"dread":dread,"name":String(p.given)}

static func voice_view(audience_id:String)->Dictionary:
	## The facts the live voice may use: who they are and what they have SAID
	## (never what they hold back).
	var p:=prisoner_of(audience_id)
	if p.is_empty(): return {}
	var said:Array=[]
	for r in said_rows(p): said.append("%s: %s%s" % [String(r.topic),String(r.text)," (shown false)" if bool(r.found_false) else ""])
	return {"name":String(p.name),"people":String(p.civ_name),"errand":"assassin" if String(p.kind)=="assassinate" else "spy","temper":String(p.temper),"status":String(p.status),
		"said_so_far":said,"rule":"The prisoner says only what is listed in said_so_far; anything else asked, they refuse or stay silent."}

static func dossier_rows(audience_id:String)->Array:
	## "What you know" in the prisoner's audience: [key, text, tone]; tone
	## "false" marks a word our own intelligence has shown false.
	var p:=prisoner_of(audience_id)
	if p.is_empty(): return []
	refresh_contradictions()
	var rows:Array=[]
	rows.append(["Taken","%s, in %s" % [EraWords.ago(int(p.taken_day)),String(p.get("where","our town"))],""])
	var fam:Dictionary=p.get("family",{}) if p.get("family") is Dictionary else {}
	var home:="no one" if not bool(fam.get("spouse",false)) and int(fam.get("children",0))<=0 else ("a %s%s" % ["husband" if String(p.get("sex",""))=="female" else "wife",(" and %s children" % EraWords.count_word(int(fam.children))) if int(fam.get("children",0))>0 else ""])
	rows.append(["Bearing","%s; courage %.2f; loyalty to %s %.2f; family at home: %s" % [String(p.temper),float(p.courage),_ruler_given(String(p.civ_id)),float(p.loyalty),home],""])
	rows.append(["Kept","%s; escape %s a month" % ["%d Food a day" % roundi(RATION) if String(p.status)=="held" else "%.1f Food a day in care" % _care_cost_day(),pct(escape_odds(p))],""])
	if float(p.get("hunger",0.0))>0.0: rows.append(["Hungry","%d days unfed: they resent it, and try the guards harder" % int(p.get("hungry_days",0)),"false"])
	for r in said_rows(p):
		var text:=String(r.text)
		if bool(r.found_false): rows.append(["Said (false)","%s — shown false by %s" % [text,String(r.found_by)],"false"])
		else: rows.append(["Said",text,""])
	return rows

# --------------------------------------------------------------------------
# The god's wrath and favour on the prisoner
# --------------------------------------------------------------------------

const DIVINE_ACTS:={
	"terrify":{"label":"Terrify them","tone":"wrath"},
	"strike_down":{"label":"Strike them down","tone":"wrath"},
	"bless":{"label":"Bless them","tone":"favor"},
	"boon":{"label":"Feed and tend them","tone":"favor"},
}
const BOON_FOOD:=3.0

static func _act_deltas(action:String)->Array:
	## [love, dread, treatment]
	match action:
		"terrify": return [-0.05,0.25,-0.2]
		"bless": return [0.12,-0.03,0.1]
		"boon": return [0.1,-0.05,0.2]
	return [0.0,0.0,0.0]

static func divine_options(audience:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var p:=by_id(String(audience.get("prisoner_id","")))
	if p.is_empty() or String(audience.get("status",""))!="waiting" or not String(p.status) in LIVE: return out
	var done:Array=audience.get("divine",[]) if audience.get("divine") is Array else []
	var manner:=String(audience.get("prisoner_manner","firm"))
	for action in DIVINE_ACTS:
		var spec:Dictionary=DIVINE_ACTS[action]
		var sub:=""
		var enabled:bool=not (action in done)
		var reason:="" if enabled else "Already done in this audience."
		var last:=int((p.get("favours",{}) as Dictionary).get(action,-99999)) if p.get("favours") is Dictionary else -99999
		if enabled and action in ["bless","boon"] and _day()-last<FAVOUR_DAYS:
			enabled=false; reason="Given %d days ago; it counts again in %d days." % [_day()-last,FAVOUR_DAYS-(_day()-last)]
		if action=="strike_down":
			var o:=fate_odds(p)
			sub="Put them to death here. Our people's dread rises; %s hear of it %s." % [_the(String(p.civ_id)),pct(float(o.learn))]
		else:
			var dl:Array=_act_deltas(action)
			var after:=p.duplicate(true)
			_shift(after,float(dl[0]),float(dl[1]),float(dl[2]))
			var before_o:=ask_odds(p,"plans",manner); var after_o:=ask_odds(after,"plans",manner)
			var bt:=turn_odds(p); var at:=turn_odds(after)
			sub="%s %s. %s questions answered %d → %d in 100, a lie %d → %d in 100; won over by care %d → %d in 100." % [
				{"terrify":"Dread rises","bless":"Love rises","boon":"They eat; love rises"}.get(action,""),
				"%.2f → %.2f" % [float(p.dread),float(after.dread)] if action=="terrify" else "%.2f → %.2f" % [float(p.love),float(after.love)],
				manner.capitalize(),roundi(float(before_o.talk)*100.0),roundi(float(after_o.talk)*100.0),roundi(float(before_o.lie)*100.0),roundi(float(after_o.lie)*100.0),roundi(float(bt.converted)*100.0),roundi(float(at.converted)*100.0)]
			if action=="boon":
				sub+=" Costs %d Food." % roundi(BOON_FOOD)
				var short:=Hall._short("Food",BOON_FOOD)
				if enabled and short!="": enabled=false; reason=short
		out.append({"id":action,"label":String(spec.label),"sub":sub,"tone":String(spec.tone),"enabled":enabled,"reason":reason})
	return out

static func divine(audience:Dictionary,action:String,words:String="")->Dictionary:
	var p:=by_id(String(audience.get("prisoner_id","")))
	if p.is_empty() or String(audience.get("status",""))!="waiting": return {"ok":false,"outcome":"No prisoner is before you."}
	var chosen:={}
	for o in divine_options(audience):
		if String(o.id)==action: chosen=o
	if chosen.is_empty(): return {"ok":false,"outcome":"That is not open to you here."}
	if not bool(chosen.enabled): return {"ok":false,"outcome":String(chosen.reason)}
	var done:Array=audience.get("divine",[]) if audience.get("divine") is Array else []
	done.append(action); audience["divine"]=done
	if action=="strike_down":
		audience["prisoner_words"]=words
		var r:=resolve(audience,"pr_execute")
		r["action"]="strike_down"; r["terminal"]=true; r["removed"]=true; r["person_id"]=0; r["name"]=String(p.name)
		return r
	var id:=String(audience.id)
	var given:=String(p.given)
	var before:={"love":float(p.love),"dread":float(p.dread)}
	var dl:Array=_act_deltas(action)
	_shift(p,float(dl[0]),float(dl[1]),float(dl[2]))
	p["divine"]=((p.get("divine",[]) as Array)+[action]).slice(-8)
	if action in ["bless","boon"]:
		if not p.get("favours") is Dictionary: p["favours"]={}
		(p.favours as Dictionary)[action]=_day()
	var outcome:=""
	var response:="cower"
	match action:
		"terrify":
			_narrate(id,"The god's fury falls on %s before the whole court." % given,given)
			_say(id,p,"Mercy... mercy." if float(p.courage)<0.55 else "Do what you will. I am not afraid of you.")
			response="cower" if float(p.courage)<0.55 else "defy"
			outcome="You terrified %s: dread %.2f → %.2f." % [given,float(before.dread),float(p.dread)]
		"bless":
			_narrate(id,"You bless %s before the whole court." % given,given)
			_say(id,p,"A god blesses the one who came to harm the god's people?")
			response="relief"
			outcome="You blessed %s: love %.2f → %.2f." % [given,float(before.love),float(p.love)]
		"boon":
			var paid:=EXCHANGE.take("player","Food",BOON_FOOD)
			p["food_spent"]=float(p.get("food_spent",0.0))+paid
			_narrate(id,"Food and a warm cloak are brought for %s." % given,given)
			_say(id,p,"...Thank you.")
			response="relief"
			outcome="You fed and tended %s (%d Food from the stores): love %.2f → %.2f." % [given,roundi(paid),float(before.love),float(p.love)]
	Hall.apply_mood(id,-0.2 if action=="terrify" else 0.2)
	_stat("divine_"+action)
	return {"ok":true,"action":action,"terminal":false,"removed":false,"person_id":0,"name":String(p.name),"response":response,"outcome":outcome,"reaction":"offended" if action=="terrify" else "pleased",
		"beat":{"beat":"terror" if action=="terrify" else "favour","topic":"","manner":String(audience.get("prisoner_manner","firm"))}}

# --------------------------------------------------------------------------
# Fates: odds and effects, the same for every people
# --------------------------------------------------------------------------

static func _watch()->float:
	return clampf(float(GameState.population_allocations.get("Defense",0))/maxf(1.0,float(GameState.population_exact)*0.08),0.0,1.0)

static func escape_core(watch:float,edge:float,cohesion:float,courage:float,harsh:bool,tended:bool,hunger:float)->float:
	## The one rule for a held person's month, whoever holds them: the
	## keepers' watch, their spymaster's hand and their cohesion against the
	## prisoner's courage; harsh keeping and hunger make them try harder.
	return clampf(0.08-watch*0.05-edge*0.3-cohesion*0.02+courage*0.04+(0.02 if harsh else 0.0)-(0.02 if tended else 0.0)+clampf(hunger,0.0,1.0)*0.04,0.01,0.15)

static func escape_odds(p:Dictionary)->float:
	## A month's odds of one of theirs held here slipping our guards.
	return escape_core(_watch(),OfficeLevers.intrigue_edge("ChiefScout"),clampf(float(GameState.simulation_metrics.get("cohesion",0.5)),0.0,1.0),
		float(p.get("courage",0.5)),float(p.get("treatment",0.0))<=-0.3,String(p.get("status",""))=="turning",float(p.get("hunger",0.0)))

static func abroad_escape_odds(rec:Dictionary)->float:
	## The same month for one of ours held among them: their wariness of us
	## is their watch; their people's cohesion; our agent's nerve.
	var civ_id:=String(rec.get("civ_id",""))
	var watch:=clampf(float(_covert().call("_wariness",civ_id)),0.0,1.0)
	var cohesion:=clampf(float(_civ(civ_id).get("cohesion",0.5)),0.0,1.0)
	return escape_core(watch,0.0,cohesion,float(rec.get("nerve",0.5)),false,false,0.0)

static func _care_cost_day()->float:
	## A tended prisoner's day: the ration, better food, and a carer's lost
	## work (what a food worker brings in a day, food_system.gd).
	var year:=float(_day())/365.0
	return RATION+CARE_FOOD+Food.BASE_SUBSISTENCE_YIELD_CALIBRATION*Food.harvest_settled(year)

static func turn_days(p:Dictionary)->int:
	return 28+roundi(clampf(float(p.get("loyalty",0.5)),0.0,1.0)*28.0)

static func turn_odds(p:Dictionary,holder:String="player")->Dictionary:
	## A course of care and teaching: won over, unmoved or only pretending.
	## Their loyalty and family at home hold them; love, kind keeping and the
	## keepers' own people's regard of their ruler draw them; terror sours it.
	## holder: whose keeping (a foreign people works on one of ours the same way).
	var love:=clampf(float(p.get("love",0.3)),0.0,1.0)
	var kind:=clampf(float(p.get("treatment",0.0)),-1.0,1.0)
	var loyalty:=clampf(float(p.get("loyalty",0.5)),0.0,1.0)
	var dread:=clampf(float(p.get("dread",0.2)),0.0,1.0)
	var fam:Dictionary=p.get("family",{}) if p.get("family") is Dictionary else {}
	var family:=bool(fam.get("spouse",false)) or int(fam.get("children",0))>0
	var our_love:=0.5
	var standing:=0.5
	if holder=="player":
		our_love=clampf(float(Hall.people_regard().get("love",0.5)),0.0,1.0)
		standing=clampf(float(GameState.simulation_metrics.get("legitimacy",0.5)),0.0,1.0)
	else:
		our_love=clampf(float(_civ(holder).get("cohesion",0.5)),0.0,1.0)
		standing=our_love
	var converted:=clampf(0.15+love*0.35+kind*0.15+our_love*0.15+standing*0.1-loyalty*0.35-(0.12 if family else 0.0)-maxf(0.0,dread-0.4)*0.2,0.05,0.8)
	var feigned:=clampf(0.08+loyalty*0.18+(0.1 if String(p.get("temper",""))=="sly" else 0.0)+float(p.get("courage",0.5))*0.05-love*0.05,0.03,0.35)
	var unmoved:=1.0-converted-feigned
	if unmoved<0.05:
		var over:=0.05-unmoved
		converted-=over; unmoved=0.05
	return {"converted":snappedf(converted,0.0001),"feigned":snappedf(feigned,0.0001),"unmoved":snappedf(unmoved,0.0001),"days":turn_days(p),"food_day":snappedf(_care_cost_day(),0.01),"family":family}

static func learn_odds(p:Dictionary)->float:
	## Whether their people hear of an execution: contact, their own spies
	## still among us, a writing people's networks, an assassin's renown.
	var civ_id:=String(p.civ_id)
	var contact:=int(_relation(civ_id).get("contact_level",1))
	return clampf(0.35+0.1*float(maxi(0,contact-1))+(0.15 if String(p.kind)=="assassinate" else 0.0)+(0.1 if _others_now(civ_id)>0 else 0.0)+(0.1 if _tier(civ_id)>=2 else 0.0),0.15,0.9)

static func message_odds(civ_id:String,kind:String)->float:
	## Their ruler's answer to a message their own man carries home: heed a
	## warning, bow to a threat, take an offer of peace, meet a demand. A
	## persuasive people's words are heeded more (standing.gd message_edge).
	var Standing:=preload("res://scripts/standing.gd")
	var said:=Standing.message_edge(Standing.art_of("player","persuasion"))
	var t:=_temper(civ_id)
	var a:=float(t.a); var r:=float(t.r); var e:=float(t.e); var d:=float(t.d); var g:=float(t.grudge); var D:=float(t.dread); var R:=float(t.ratio)
	match kind:
		"warning": return snappedf(clampf(0.30+D*0.35+e*0.15+d*0.10-a*0.25-g*0.15-(R-1.0)*0.1+said,0.05,0.9),0.0001)
		"threat": return snappedf(clampf(0.20+D*0.45+(1.0-r)*0.15-a*0.25-g*0.15-(R-1.0)*0.15-(0.1 if String(t.trait) in ["bluffer","grudge"] else 0.0)+said,0.03,0.85),0.0001)
		"peace": return snappedf(clampf(0.25+e*0.25+float(t.opinion)*0.25+float(t.trust)*0.15+0.10-g*0.25-a*0.10-(0.1 if bool(t.at_war) else 0.0)+said,0.05,0.9),0.0001)
		"demand": return snappedf(clampf(0.15+D*0.45+(1.0-a)*0.15-g*0.20-(R-1.0)*0.15+(0.05 if String(t.trait)=="ledger" else 0.0)+said,0.03,0.8),0.0001)
	return clampf(0.3+said,0.05,0.9)

static func fate_odds(p:Dictionary)->Dictionary:
	var civ_id:=String(p.civ_id)
	var msgs:Dictionary={}
	for kind in MESSAGES: msgs[kind]=message_odds(civ_id,kind)
	return {"learn":learn_odds(p),"messages":msgs,"days":int(_covert().call("travel_days",civ_id,"")),"turn":turn_odds(p),"escape":escape_odds(p),"ration":RATION}

static func message_words(kind:String,civ_id:String)->String:
	var given:=_ruler_given(civ_id)
	match kind:
		"warning": return "Tell %s: send no more of your people to creep about our fires. The next one dies." % given
		"threat": return "Tell %s: if another of yours comes in secret, the god's people will come to your hearths in force." % given
		"peace": return "Tell %s: the god sends you back your man alive. Let there be peace between our peoples." % given
		"demand": return "Tell %s to keep %s spies at home, and to send the god a gift for this insult." % [given,"her" if _ruler_she(civ_id) else "his"]
	return ""

static func message_label(kind:String)->String:
	return {"warning":"A warning","threat":"A threat","peace":"An offer of peace","demand":"A demand"}.get(kind,kind)

static func classify_message(words:String)->String:
	var w:=words.to_lower()
	if RegEx.create_from_string("\\b(peace|friend|friends|alive|mercy|trade with|no quarrel|forgive|kin)\\b").search(w)!=null: return "peace"
	if RegEx.create_from_string("\\b(kill|burn|destroy|crush|come for|war|slaughter|wipe|ruin|raze|my wrath|you will die|hunt you)\\b").search(w)!=null: return "threat"
	if RegEx.create_from_string("\\b(send (us|me|the god)|pay|give|tribute|owe|bring|must send|gift for|hand over|return)\\b").search(w)!=null: return "demand"
	return "warning"

static func options(audience:Dictionary)->Array[Dictionary]:
	## The fate cards, each with its real effects and odds.
	var out:Array[Dictionary]=[]
	var p:=by_id(String(audience.get("prisoner_id","")))
	if p.is_empty() or String(audience.get("status",""))!="waiting": return out
	var o:=fate_odds(p)
	var civ_id:=String(p.civ_id)
	var given:=String(p.given)
	var ruler:=_ruler_given(civ_id)
	var msgs:Dictionary=o.messages
	if String(p.status)=="joined":
		var dbl:=double_odds(p)
		out.append(Hall._option("pr_double","Send them back as our eyes","%s goes home to %s and sends us word every %d days (true word: their numbers and plans sharpen ours) while feeding them false word of us. Found out %s each time word comes; then %s judges them." % [given,_the(civ_id),DOUBLE_REPORT_DAYS,pct(float(dbl.found)),ruler],"neutral"))
		out.append(Hall._option("pr_dismiss","That will be all","%s goes back to work among our people." % given,"neutral"))
		return out
	var t:Dictionary=o.turn
	out.append(Hall._option("pr_execute","Put them to death","Our people's dread of you rises a little. %s hear of it %s: then %s holds a grudge and their view of us falls. Either way they send fewer agents for about a year (half as many if they hear, a fifth fewer if not)." % [_upper_first(_the(civ_id)),pct(float(o.learn)),ruler],"hostile"))
	out.append(Hall._option("pr_send","Send them home with a message","%d days' walk to %s; they carry your words and what they saw of us. %s's answer: a warning heeded %s, a threat bows %s %s, peace taken %s, a demand met %s." % [int(o.days),ruler,ruler,pct(float(msgs.warning)),"her" if _ruler_she(civ_id) else "him",pct(float(msgs.threat)),pct(float(msgs.peace)),pct(float(msgs.demand))],"neutral"))
	var turn:=Hall._option("pr_turn","Turn them: care and teaching","About %d weeks with the carers. At the end: won over %s, unmoved %s, only pretending %s.%s" % [roundi(float(t.days)/7.0),pct(float(t.converted)),pct(float(t.unmoved)),pct(float(t.feigned))," A family at home pulls at them." if bool(t.family) else ""],"warm")
	turn["cost_words"]="%.1f Food a day (ration, better food, a carer's lost work), about %d in all" % [float(t.food_day),roundi(float(t.food_day)*float(t.days))]
	if String(p.status)=="turning":
		turn["enabled"]=false; turn["reason"]="Already with the carers: %d days to go." % maxi(0,int(p.get("turn_end",_day()))-_day())
	out.append(turn)
	out.append(Hall._option("pr_keep","Keep them under guard" if String(p.status)=="held" else "Back to the carers","%d Food a day; escape %s a month. You can bring them before you again.%s" % [roundi(RATION),pct(float(o.escape))," (A ransom or an exchange may be asked for them later.)" if String(p.status)=="held" else ""],"neutral"))
	return out

static func message_choices(p:Dictionary)->Array:
	var out:Array=[]
	var civ_id:=String(p.civ_id)
	for kind in MESSAGES:
		var odds:=message_odds(civ_id,kind)
		var verb:String={"warning":"heeds it","threat":"bows to it","peace":"takes it","demand":"meets it"}[kind]
		out.append({"id":"pr_send:%s" % kind,"label":"%s · %s %s %s" % [message_label(kind),_ruler_given(civ_id),verb,pct(odds)],"tip":message_words(kind,civ_id),"odds":odds})
	return out

static func resolve(audience:Dictionary,option_id:String)->Dictionary:
	## A fate chosen (a card, typed words, or the god's wrath). Concludes the
	## audience unless it asks which words go home with them.
	var p:=by_id(String(audience.get("prisoner_id","")))
	if p.is_empty() or String(audience.get("status",""))!="waiting": return {"ok":false,"outcome":"No prisoner is before you.","reaction":"neutral"}
	var words:=String(audience.get("prisoner_words",""))
	audience.erase("prisoner_words")
	var id:=String(audience.id)
	var result:Dictionary
	if option_id=="pr_send":
		if words.strip_edges()=="":
			return {"ok":false,"outcome":"Which words go home with %s?" % String(p.given),"reaction":"neutral","choices":message_choices(p),"ask":"Which words go home with %s? Choose, or say them yourself." % String(p.given)}
		option_id="pr_send:"+classify_message(words)
	if option_id.begins_with("pr_send:"):
		var kind:=option_id.trim_prefix("pr_send:")
		if not kind in MESSAGES: return {"ok":false,"outcome":"That message is not open to you.","reaction":"neutral"}
		if words.strip_edges()=="":
			words=message_words(kind,String(p.civ_id))
			_god(id,words)
		result=send_home(p,kind,words,id)
		option_id="pr_send"
	else:
		match option_id:
			"pr_execute": result=execute(p,words,id)
			"pr_turn":
				if String(p.status)!="held": return {"ok":false,"outcome":"They are already with the carers." if String(p.status)=="turning" else "They are one of us already.","reaction":"neutral"}
				result=begin_turning(p,id)
			"pr_keep": result=keep(p,id)
			"pr_double":
				if String(p.status)!="joined": return {"ok":false,"outcome":"Only one won over to us can go back as our eyes.","reaction":"neutral"}
				result=send_double(p,id)
			"pr_dismiss":
				result={"outcome":"%s went back to work among our people." % String(p.given),"reaction":"neutral","action":"dismiss"}
			_: return {"ok":false,"outcome":"That answer is not open to you here.","reaction":"neutral"}
	if not bool(result.get("ok",true)): return result
	_narrate(id,String(result.get("outcome","")))
	# The fate goes into the chronicle (keeping them asks nothing new).
	var told:String={"pr_execute":"%s Put to Death","pr_send":"%s Sent Home","pr_turn":"%s Given to the Carers","pr_double":"%s Sent Back as Our Eyes"}.get(option_id,"")
	if told!="": _tell(told % String(p.name),String(result.get("outcome","")),_day())
	p["audience_id"]=""
	audience.status="resolved"
	audience.outcome=String(result.get("outcome","")).substr(0,600)
	audience.option_id=option_id.substr(0,40)
	Hall._archive(audience)
	Hall._ledger_close(audience,option_id,String(result.get("reaction","neutral")),String(audience.outcome))
	result["ok"]=true
	result["prisoner_id"]=String(p.id)
	return result

static func execute(p:Dictionary,words:String,audience_id:String="")->Dictionary:
	var civ_id:=String(p.civ_id)
	var day:=_day()
	var learn:=learn_odds(p)
	var heard:=_rng(String(p.seed)+":learn").randf()<learn
	var ours:=p.has("counted")
	p["status"]="executed"; p["status_day"]=day
	p["fate"]={"kind":"executed","day":day,"learn":learn,"heard":heard,"words":words.substr(0,300),"was_ours":ours}
	# One counted among us now (won over, or seeming so): a death of our people.
	if ours: _leaves_our_count(p,"%s, once of %s, was put to death at the god's word." % [String(p.name),_name(civ_id)],true)
	DIVINE.record_people_act("harsh_law")
	var ruler:=_ruler_given(civ_id)
	var tail:=""
	if heard:
		_rivals().call("grudge",civ_id,"the killing of %s, whom the god's people took" % String(p.name),0.3,"prisoner:%s" % String(p.id))
		Hall._shift_relation(civ_id,-0.05,0.06)
		DIVINE.add_civ_dread(civ_id,0.1)
		ForeignDiplomacy.remember(civ_id,"The god's people put our %s %s to death." % ["assassin" if String(p.kind)=="assassinate" else "watcher",String(p.name)])
		tail="%s heard of it (the odds were %s): %s holds a grudge, and their view of us falls. They will send half as many agents for about a year." % [_upper_first(_the(civ_id)),pct(learn),ruler]
		_deter(civ_id,DETER_DAYS,0.5,"execution")
	else:
		tail="%s have not heard of it (the odds they would were %s); their %s simply never comes home. They will send a fifth fewer agents for about a year." % [_upper_first(_the(civ_id)),pct(learn),"man" if String(p.get("sex",""))!="female" else "woman"]
		_deter(civ_id,DETER_DAYS,0.8,"execution")
	_stat("executed")
	return {"ok":true,"action":"execute","verb":"kill","terminal":true,"removed":true,"executed":true,"reaction":"furious","words":words,"heard":heard,"learn":learn,
		"outcome":"%s, %s, was put to death at your word. Our people's dread of you rises a little. %s" % [String(p.name),title_of(p).get_slice(",",0),tail]}

static func send_home(p:Dictionary,kind:String,words:String,_audience_id:String="")->Dictionary:
	var civ_id:=String(p.civ_id)
	var day:=_day()
	var days:=int(_covert().call("travel_days",civ_id,""))
	var odds:=message_odds(civ_id,kind)
	p["status"]="sent_home"; p["status_day"]=day
	p["fate"]={"kind":"sent_home","day":day,"message":kind,"words":words.substr(0,400),"arrive_day":day+days,"odds":odds,"answered":false}
	_leaves_our_count(p,"Sent home to %s" % _name(civ_id),false)
	_stat("sent_home")
	var verb:String={"warning":"heeds a warning","threat":"bows to a threat","peace":"takes an offer of peace","demand":"meets a demand"}[kind]
	return {"ok":true,"action":"send","verb":"send","terminal":true,"removed":true,"reaction":"neutral","words":words,"message":kind,"odds":odds,"days":days,
		"outcome":"%s sets out for %s with your words, about %d days on foot. %s's answer is decided when they arrive: the odds %s %s are %s. They will also tell %s what they saw of us." % [String(p.given),_the(civ_id),days,_ruler_given(civ_id),_ruler_given(civ_id),verb,pct(odds),_ruler_given(civ_id)]}

static func begin_turning(p:Dictionary,_audience_id:String="")->Dictionary:
	var t:=turn_odds(p)
	var day:=_day()
	p["status"]="turning"; p["status_day"]=day
	p["course"]=int(p.get("course",0))+1
	p["turn_start"]=day; p["turn_end"]=day+int(t.days); p["turn_odds"]=t
	_stat("turning")
	return {"ok":true,"action":"turn","verb":"turn","terminal":true,"removed":true,"reaction":"neutral","odds":t,
		"outcome":"%s is given to the carers for about %d weeks of care and teaching, at %.1f Food a day (about %d in all). At the end: won over %s, unmoved %s, only pretending %s." % [String(p.given),roundi(float(t.days)/7.0),float(t.food_day),roundi(float(t.food_day)*float(t.days)),pct(float(t.converted)),pct(float(t.unmoved)),pct(float(t.feigned))]}

static func keep(p:Dictionary,_audience_id:String="")->Dictionary:
	if String(p.status)=="joined":
		# One counted among us, bound again: they leave our count for the guards'.
		_leaves_our_count(p,"Put under guard again",false)
		p["status"]="held"; p["status_day"]=_day()
		return {"ok":true,"action":"keep","verb":"keep","terminal":true,"reaction":"offended",
			"outcome":"%s is bound and put under guard again: %d Food a day; the odds of an escape are %s a month." % [String(p.given),roundi(RATION),pct(escape_odds(p))]}
	if String(p.status)=="turning":
		return {"ok":true,"action":"keep","verb":"keep","terminal":true,"reaction":"neutral","outcome":"%s goes back to the carers." % String(p.given)}
	return {"ok":true,"action":"keep","verb":"keep","terminal":true,"reaction":"neutral",
		"outcome":"%s is taken back under guard: %d Food a day; the odds of an escape are %s a month." % [String(p.given),roundi(RATION),pct(escape_odds(p))]}

static func ransom_terms(_p:Dictionary)->Dictionary:
	## Hook: an exchange or ransom for a held prisoner (envoy_requests.gd
	## captive business). Nothing yet.
	return {}

# --------------------------------------------------------------------------
# Deterrence: their schemes against us, rarer for a while
# --------------------------------------------------------------------------

static func _deter(civ_id:String,days:int,factor:float,why:String)->void:
	var deterred:Dictionary=state().deterred
	var until:=_day()+days
	var old:Dictionary=deterred.get(civ_id,{}) if deterred.get(civ_id) is Dictionary else {}
	if not old.is_empty() and int(old.get("until",0))>until and float(old.get("factor",1.0))<=factor: return
	deterred[civ_id]={"until":until,"factor":clampf(minf(factor,float(old.get("factor",1.0)) if int(old.get("until",0))>_day() else factor),0.0,1.0),"why":why}

## Whether we hold one of their agents under guard now (held or being won over).
static func holds_from(civ_id:String)->bool:
	for p in state().prisoners:
		if p is Dictionary and String((p as Dictionary).get("civ_id",""))==civ_id and String((p as Dictionary).get("status","")) in ["held","turning"]: return true
	return false

static func scheme_factor(civ_id:String)->float:
	## How much of their usual scheming against us goes on now (covert_ops
	## _rival_scheme_chance).
	var entry:Variant=(state().deterred as Dictionary).get(civ_id)
	if not entry is Dictionary or int((entry as Dictionary).get("until",0))<=_day(): return 1.0
	return clampf(float((entry as Dictionary).get("factor",1.0)),0.0,1.0)

# --------------------------------------------------------------------------
# Daily: food, escapes, the course of care, messages arriving, the pretenders
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	if WorldSimulation.actor_id!="player": return
	var s:=state()
	for q in (s.prisoners as Array).duplicate():
		var p:Dictionary=q
		match String(p.get("status","")):
			"held":
				_feed(p,RATION)
				_maybe_escape(p,day)
			"turning":
				# A day the care was not paid for is a day the course waits.
				if not _feed(p,_care_cost_day()): p["turn_end"]=int(p.get("turn_end",day))+1
				if day>=int(p.get("turn_end",day)): _end_turning(p,day)
				else: _maybe_escape(p,day)
			"joined":
				if bool(p.get("feigned",false)) and day>=int(p.get("betray_day",1<<30)): _betray(p,day)
			"sent_home":
				var fate:Dictionary=p.get("fate",{}) if p.get("fate") is Dictionary else {}
				if not bool(fate.get("answered",false)) and day>=int(fate.get("arrive_day",day)): _message_arrives(p,day)
	for r in (s.abroad as Array).duplicate(): _abroad_daily(r as Dictionary,day)
	refresh_contradictions()

static func _feed(p:Dictionary,amount:float)->bool:
	## A day's food from our stores. Unfed, they go hungry: resentment (kind
	## keeping and love fall) and a hunger that makes them try the guards.
	var paid:=EXCHANGE.take("player","Food",amount)
	p["food_spent"]=snappedf(float(p.get("food_spent",0.0))+paid,0.01)
	if paid+0.001<amount:
		p["hungry_days"]=int(p.get("hungry_days",0))+1
		p["hunger"]=snappedf(clampf(float(p.get("hunger",0.0))+0.1,0.0,1.0),0.01)
		_shift(p,-0.01,0.0,-0.02)
		return false
	if float(p.get("hunger",0.0))>0.0: p["hunger"]=snappedf(maxf(0.0,float(p.hunger)-0.05),0.01)
	return true

static func _maybe_escape(p:Dictionary,day:int)->void:
	var since:=day-int(p.get("taken_day",day))
	if since<=0 or since%30!=0: return
	var odds:=escape_odds(p)
	if _rng("esc|%s|%d" % [String(p.seed),int(since/30.0)]).randf()>=odds: return
	p["status"]="escaped"; p["status_day"]=day
	p["fate"]={"kind":"escaped","day":day,"odds":odds}
	_carried_home(String(p.civ_id),0.1)
	if float(p.get("treatment",0.0))<=-0.3: _rivals().call("grudge",String(p.civ_id),"how the god's people used our %s" % String(p.given),0.15,"prisoner_used:%s" % String(p.id))
	_close_audience(p,"%s slipped the guards." % String(p.given))
	_tell("%s Escaped" % String(p.name),"%s, held under guard since %s, slipped the guards in the night and is gone toward %s, carrying what they saw of us (the odds were %s a month)." % [String(p.name),EraWords.ago(int(p.taken_day)),_the(String(p.civ_id)),pct(odds)],day)
	_stat("escaped")

static func _carried_home(civ_id:String,amount:float)->void:
	## What one of theirs saw of us reaches their ruler.
	var index:=Hall._civ_index(civ_id)
	if index<0: return
	var rel:Dictionary=_relation(civ_id)
	rel["rival_player_intelligence"]=clampf(float(rel.get("rival_player_intelligence",0.0))+amount,0.0,1.0)

static func turn_key(p:Dictionary)->String:
	## Each course of care rolls on its own: the record and the course number.
	return "turn|%s|%d" % [String(p.seed),int(p.get("course",1))]

static func _end_turning(p:Dictionary,day:int)->void:
	var t:Dictionary=p.get("turn_odds",{}) if p.get("turn_odds") is Dictionary else turn_odds(p)
	var roll:=_rng(turn_key(p)).randf()
	var given:=String(p.given)
	p["turn_roll"]=snappedf(roll,0.0001)
	if roll<float(t.converted)+float(t.feigned):
		var feigned:=roll>=float(t.converted)
		p["status"]="joined"; p["status_day"]=day; p["feigned"]=feigned
		_joins_our_count(p,"Won over from %s" % _name(String(p.civ_id)))
		if feigned: p["betray_day"]=day+_rng("betray|"+turn_key(p)).randi_range(20,60)
		# Both tell everything: a true convert truly, one pretending from their
		# prepared lies (kept false in the ledger). The god sees the same.
		_tell_everything(p)
		# Told the same either way: the god sees what the prisoner shows.
		_tell("%s Is Won Over" % String(p.name),"After %d days with the carers, %s says they are one of us now, and will answer anything you ask. (The odds were: won over %s, only pretending %s.)" % [day-int(p.get("turn_start",day)),String(p.name),pct(float(t.converted)),pct(float(t.feigned))],day,true,String(p.id))
		_stat("feigned" if feigned else "converted")
	else:
		p["status"]="held"; p["status_day"]=day
		_tell("%s Is Unmoved" % String(p.name),"After %d days with the carers, %s is still loyal to %s, and is held under guard again (the odds of that were %s)." % [day-int(p.get("turn_start",day)),given,_ruler_given(String(p.civ_id)),pct(float(t.unmoved))],day,true,String(p.id))
		_stat("unmoved")

static func _tell_everything(p:Dictionary)->void:
	## Won over (or seeming so), every matter is told. A true convert tells it
	## truly, and every earlier lie of theirs is shown false by it. One only
	## pretending tells their prepared lies, kept false in the ledger with the
	## truth beside them; on the screen the two read alike.
	var feigned:=bool(p.get("feigned",false))
	for f in p.get("facts",[]):
		var topic:=String((f as Dictionary).topic)
		var prior:=_last_said(p,topic)
		if not prior.is_empty() and bool(prior.get("talked",false)) and (feigned or not bool(prior.get("lied",false))): continue
		var text:=String((f as Dictionary).lie) if feigned else String((f as Dictionary).text)
		(p.said as Array).append({"day":_day(),"topic":topic,"manner":"gentle","p_talk":1.0,"p_lie":0.0,"r_talk":0.0,"r_lie":1.0,"talked":true,"lied":feigned,
			"text":text,"truth":String((f as Dictionary).text) if feigned else "","found_false":false,"found_by":"","told_when_won":true,"rolled":false})
		if not feigned: _contradict_by_truth(String(p.civ_id),topic,f,String(p.id),"%s's own word once won over" % String(p.given))
	while (p.said as Array).size()>SAID_MAX: (p.said as Array).pop_front()

static func _betray(p:Dictionary,day:int)->void:
	## The pretender's end: they flee home, or fire a store before fleeing.
	var rng:=_rng("betray_how|"+turn_key(p))
	var burn:=rng.randf()<0.4
	var lost:=0.0
	if burn:
		var have:=Hall.player_stock("Food")
		lost=EXCHANGE.take("player","Food",minf(30.0,maxf(0.0,have*0.04)))
	p["status"]="fled"; p["status_day"]=day
	p["fate"]={"kind":"fled","day":day,"burned":roundi(lost)}
	_leaves_our_count(p,"Fled home to %s" % _name(String(p.civ_id)),false)
	_carried_home(String(p.civ_id),0.15)
	# Their lies are lies: shown false now.
	for e in p.get("said",[]):
		if bool((e as Dictionary).get("lied",false)): (e as Dictionary)["found_false"]=true; (e as Dictionary)["found_by"]="their flight: they were only pretending"
	_close_audience(p,"%s fled." % String(p.given))
	var text:="%s was only pretending to be one of us, and fled in the night toward %s with what they saw of us%s." % [String(p.name),_the(String(p.civ_id)),("; before going they fired a store, and about %d Food burned" % roundi(lost)) if lost>0.0 else ""]
	_tell("%s Was Pretending" % String(p.name),text,day)
	_stat("betrayed")

static func _message_arrives(p:Dictionary,day:int)->void:
	## Their own man reaches home with the god's words: the ruler's answer is
	## rolled now from temper and relation, and the relation follows.
	var fate:Dictionary=p.fate
	var civ_id:=String(p.civ_id)
	var kind:=String(fate.message)
	# The odds stated when they were sent are the odds rolled now.
	var odds:=float(fate.get("odds",message_odds(civ_id,kind)))
	var yes:=_rng("msg|%s" % String(p.seed)).randf()<odds
	fate["answered"]=true; fate["answer_odds"]=odds; fate["yes"]=yes; fate["answer_day"]=day
	var ruler:=_ruler_given(civ_id)
	var who:=_the(civ_id)
	# Their man came home alive: a little goodwill; and what he saw goes with him.
	Hall._shift_relation(civ_id,0.03,0.0)
	_carried_home(civ_id,0.12)
	var text:=""
	var reply:=""
	match kind:
		"warning":
			if yes:
				_deter(civ_id,365,0.3,"warning heeded"); Hall._shift_relation(civ_id,0.0,-0.04); DIVINE.add_civ_dread(civ_id,0.05)
				text="%s heeded your warning (the odds were %s): they will send few agents for a year." % [ruler,pct(odds)]
			else:
				_rivals().call("grudge",civ_id,"the god's warning, carried by our own man",0.15,"warned:%s" % String(p.id)); Hall._shift_relation(civ_id,0.0,0.04)
				text="%s scorned your warning (the odds %s would heed it were %s), and holds it against us." % [ruler,ruler,pct(odds)]
		"threat":
			if yes:
				_deter(civ_id,540,0.25,"threat"); DIVINE.add_civ_dread(civ_id,0.12); Hall._shift_relation(civ_id,-0.03,0.0)
				text="%s bowed to your threat (the odds were %s): their agents will stay home for a long while, and they fear you more." % [ruler,pct(odds)]
			else:
				_rivals().call("grudge",civ_id,"the god's threat, carried by our own man",0.3,"threatened:%s" % String(p.id)); Hall._shift_relation(civ_id,-0.06,0.12)
				text="%s would not bow to your threat (the odds were %s): the border grows tense, and %s holds a grudge." % [ruler,pct(odds),ruler]
				reply="dread_test"
		"peace":
			if yes:
				Hall._shift_relation(civ_id,0.08,-0.08); Hall._leader_trust(civ_id,0.06); _rivals().call("settle_grudges",civ_id,0.3)
				text="%s took your offer of peace (the odds were %s): their view of us warms, and old grudges ease." % [ruler,pct(odds)]
				reply="peace_possible" if bool(_relation(civ_id).get("at_war",false)) else ("feud_peace" if bool(_war().call("feuding",civ_id)) else "relation_warm")
			else:
				text="%s let your offer of peace pass (the odds %s would take it were %s); still, their own came home alive." % [ruler,ruler,pct(odds)]
		"demand":
			if yes:
				_deter(civ_id,730,0.2,"demand met"); DIVINE.add_civ_dread(civ_id,0.08)
				text="%s met your demand (the odds were %s): no more agents for two years, and a gift may come." % [ruler,pct(odds)]
				reply="dread_tribute"
			else:
				_rivals().call("grudge",civ_id,"the god's demand, carried by our own man",0.25,"demanded:%s" % String(p.id)); Hall._shift_relation(civ_id,0.0,0.08)
				text="%s refused your demand (the odds %s would meet it were %s)." % [ruler,ruler,pct(odds)]
	ForeignDiplomacy.remember(civ_id,"The god sent our %s home alive with these words: \"%s\"" % [String(p.given),String(fate.get("words","")).substr(0,300)])
	if reply!="":
		Hall._add_occasion({"key":"prisoner_reply:%s" % String(p.id),"type":reply,"civ_id":civ_id,"day":day,"not_before":day+rngi(String(p.seed),20,60),"expires":day+300,
			"data":{"text":"the answer to the words the god sent home with %s" % String(p.given),"prisoner_reply":{"kind":kind,"yes":yes}}})
		text+=" An envoy may come with their answer."
	fate["answer"]=text
	_tell("Word from %s" % _name(civ_id),"%s reached %s with your %s. %s" % [String(p.given),who,String({"warning":"warning","threat":"threat","peace":"offer of peace","demand":"demand"}.get(kind,kind)),text],day)
	_stat("answered_"+kind)

static func rngi(seed_key:String,lo:int,hi:int)->int:
	return _rng("reply|"+seed_key).randi_range(lo,hi)

static func _close_audience(p:Dictionary,outcome:String)->void:
	var a:=Hall.find(String(p.get("audience_id","")))
	if not a.is_empty() and String(a.get("status",""))=="waiting": Hall.conclude(String(a.id),outcome,"prisoner_gone")
	p["audience_id"]=""

static func _tell(title:String,text:String,day:int,bring:bool=false,id:String="")->void:
	var entry:={"key":"captive:%d:%s" % [day,title.substr(0,30)],"title":title.substr(0,70),"text":text,"tier":"notice","kind":"court","domain":"security"}
	if bring and id!="": entry["action"]={"kind":"prisoner","prisoner_id":id}
	else: entry["action"]={"kind":"section","section":"military"}
	Chronicle.record(entry)

# --------------------------------------------------------------------------
# A won-over prisoner sent back as our eyes (a double agent)
# --------------------------------------------------------------------------

static func double_odds(p:Dictionary)->Dictionary:
	## Each time word comes (every DOUBLE_REPORT_DAYS): the odds they are
	## found out among their own people, by their wariness, the agent's nerve,
	## and their cunning against ours (standing.gd catch_edge: the same rule
	## every agent meets, ours among them and theirs among us).
	var civ_id:=String(p.civ_id)
	var wary:=float(_covert().call("_wariness",civ_id))
	var nerve:=clampf(float(p.get("courage",0.5)),0.0,1.0)
	var Standing:=preload("res://scripts/standing.gd")
	var watched:=Standing.catch_edge(Standing.art_of(civ_id,"cunning"),Standing.art_of("player","cunning"))
	return {"found":snappedf(clampf(0.06+wary*0.15-nerve*0.04+watched,0.03,0.3),0.0001),"every":DOUBLE_REPORT_DAYS}

static func send_double(p:Dictionary,_audience_id:String="")->Dictionary:
	var civ_id:=String(p.civ_id)
	var agent:={"key":"captive:%s" % String(p.id),"name":String(p.name),"given":String(p.given),"stealth":0.7,"nerve":float(p.courage),"blade":0.3,"poison":0.2,"tongue":0.6,
		"source":"turned","person_id":0,"figure_id":"","known_id":"","prisoner_id":String(p.id)}
	var op:Dictionary=_covert().call("launch","plant",civ_id,"","none",agent,"",true)
	if op.has("error"): return {"ok":false,"outcome":String(op.error),"reaction":"neutral"}
	var odds:=double_odds(p)
	(op.odds as Dictionary)["success"]=1.0
	# The stated odds of being found, the same whoever they truly serve; one
	# only pretending is their ruler's own and is never rolled for
	# (covert_ops _plant_report).
	(op.odds as Dictionary)["caught"]=float(odds.found)
	op["stated_found"]=float(odds.found)
	op["double"]=true
	op["double_feigned"]=bool(p.get("feigned",false))
	op["prisoner_id"]=String(p.id)
	p["status"]="double"; p["status_day"]=_day()
	p["fate"]={"kind":"double","day":_day(),"op_id":int(op.id),"found":float(odds.found)}
	_leaves_our_count(p,"Sent back among %s as our eyes" % _name(civ_id),false)
	_stat("doubles")
	return {"ok":true,"action":"double","verb":"send","terminal":true,"reaction":"neutral",
		"outcome":"%s goes home to %s as our eyes. Word every %d days; found out %s each time." % [String(p.given),_the(civ_id),DOUBLE_REPORT_DAYS,pct(float(odds.found))]}

# --------------------------------------------------------------------------
# Typed words in the prisoner's audience (online typing; the same core)
# --------------------------------------------------------------------------

const Q_RE:={
	"sender":"\\b(who sent you|who sends you|who is your (master|chief|lord|ruler|king|queen)|whom do you serve|who do you serve|whose (man|woman|spy|creature) are you|who gave you (this|the) (order|task)|who are you working for|who are you with)\\b",
	"mission":"\\b(what were you sent (to do|for)|why are you here|why did you come|what did you come (here )?(to do|for)|what (was|is) your (task|errand|mission|purpose|job)|what were you doing|who were you (sent )?to kill|what did you want here|(did|were) you (come|sent) to)\\b",
	"strength":"\\b(how strong|how many (fighters|warriors|spears|men|soldiers|bows)|how big is your (army|host|band)|your (numbers|strength|army|warriors|fighters)|how much food|your (stores|food))\\b",
	"plans":"\\b(what (are|is) (they|your people|your chief|your master|he|she) (planning|plotting|going to do)|what do (they|your people) (plan|mean|intend|want)|what does (your|their) (chief|ruler|master|lord) (want|plan|mean|intend)|(their|your) plans?|will they (attack|raid|come)|are they coming|do they mean (war|to attack))\\b",
	"others":"\\b(are there (any )?others|any more of you|who else|how many of you|anyone else|did (anyone|someone) come with you|are you alone|accomplices?|others like you|more of you)\\b",
}
const TERROR_RE:="\\b(or i will|or you (die|burn)|or else|tear|flay|burn you|my wrath|fear me|kneel|scream|cut (off )?your|kill you|your fingers|your eyes|die slowly|or the guards|beg)\\b|!{2,}"
const GENTLE_RE:="\\b(please|gently|do not be afraid|don't be afraid|you are safe|you're safe|no harm|eat|drink|friend|kindly|in peace|i mean you no)\\b"
const NOT_RE:="\\b(do not|don't|dont|never|no one is to|nobody is to|must not|mustn't|shall not)\\b"
const EXECUTE_RE:="\\b((execute|kill|slay|behead|hang|strangle|drown|burn|impale|stone|spear|club|flay|crush|boil|saw|quarter|bury|trample) (him|her|them|this (man|woman|one|spy|assassin|wretch|dog))|put (him|her|them) to death|cut (his|her|their) throat|(feed|throw) (him|her|them) (to|into|in)|death to (him|her|them)|off with (his|her|their) head|strike (him|her|them) down)\\b"
const SEND_RE:="\\b(send (him|her|them) (back|home)|let (him|her|them) go( home)?|release (him|her|them)|go (back|home) (and|to) tell|carry (this|my|these) (word|words|message)|tell your (chief|master|ruler|lord|king|queen|people)|(drive|cast|throw) (him|her|them) out|(exile|banish) (him|her|them))\\b"
## Harm short of death (a flogging, a branding): the god's terror on them.
const HARM_RE:="\\b(flog|whip|beat|maim|torture|brand|cut|break) (him|her|them)\\b|\\b(break|cut off|take) (his|her|their) (fingers|hand|hands|ear|ears|nose)\\b"
const TURN_RE:="\\b(turn (him|her|them)|win (him|her|them) over|convert (him|her|them)|make (him|her|them) one of us|teach (him|her|them) our ways|care for (him|her|them)|propaganda|nurse (him|her|them)|feed (him|her|them) and teach|show (him|her|them) our ways)\\b"
const KEEP_RE:="\\b(keep (him|her|them) (under guard|bound|locked|here|prisoner)|take (him|her|them) away|lock (him|her|them) up|throw (him|her|them) in|back to (his|her|their) (cell|pit|hut)|hold (him|her|them))\\b"
## Others than the one before the god. A line whose object is the ambiguous
## "them" (or "their") AFTER a mention of others ("find the others and kill
## them") is about the others, never the prisoner's death, keeping, turning
## or harm. A singular him or her (a name reads as him or her) always means
## the prisoner: "kill him as a warning to the others" kills them.
const OTHERS_RE:="\\b(the others|others|the rest|accomplices?|anyone else|whoever|all of them|every one of them|the spies|their spies|(their|his|her) (chief|ruler|people|men|kin|family|spies|friends))\\b"
const DOUBLE_RE:="\\b(send (him|her|them) back as (our|my) (eyes|spy|agent)|spy for us|be our eyes|go back and spy)\\b"

static func read(text:String)->Dictionary:
	## The god's words in a prisoner's audience: a question in a manner, or a
	## fate (with the words recorded as spoken). {} when they hold neither.
	var lower:=text.strip_edges().to_lower()
	if lower=="": return {}
	var negated:=RegEx.create_from_string(NOT_RE).search(lower)!=null
	if not negated:
		if RegEx.create_from_string(DOUBLE_RE).search(lower)!=null: return {"kind":"fate","option":"pr_double","words":text.strip_edges()}
		if RegEx.create_from_string(SEND_RE).search(lower)!=null:
			var kind:=classify_message(text)
			return {"kind":"fate","option":"pr_send:"+kind,"words":text.strip_edges(),"message":kind}
		if _aimed_at_prisoner(EXECUTE_RE,lower) and not lower.ends_with("?"): return {"kind":"fate","option":"pr_execute","words":text.strip_edges()}
		if _aimed_at_prisoner(TURN_RE,lower): return {"kind":"fate","option":"pr_turn","words":text.strip_edges()}
		if _aimed_at_prisoner(KEEP_RE,lower): return {"kind":"fate","option":"pr_keep","words":text.strip_edges()}
	for topic in TOPICS:
		if RegEx.create_from_string(String(Q_RE[topic])).search(lower)!=null:
			var manner:="firm"
			if RegEx.create_from_string(TERROR_RE).search(lower)!=null or text.count("!")>=2: manner="terror"
			elif RegEx.create_from_string(GENTLE_RE).search(lower)!=null: manner="gentle"
			return {"kind":"question","topic":topic,"manner":manner}
	return {}

static func _aimed_at_prisoner(pattern:String,lower:String)->bool:
	## The pattern's act falls on the prisoner: it matches, and its object is
	## not the ambiguous "them"/"their" following a mention of others.
	var found:=RegEx.create_from_string(pattern).search(lower)
	if found==null: return false
	var plural:=RegEx.create_from_string("\\b(them|their)\\b").search(found.get_string())!=null
	if not plural: return true
	return RegEx.create_from_string(OTHERS_RE).search(lower.substr(0,found.get_start()))==null

static func _as_pronoun(p:Dictionary,text:String)->String:
	## "Put Gavo Tesh to death" reads as "put him to death".
	var out:=text
	var pro:="her" if String(p.get("sex",""))=="female" else "him"
	for n in [String(p.get("name","")),String(p.get("given",""))]:
		if n.strip_edges().length()>=2: out=out.replacen(n,pro)
	return out

static func hear(audience_id:String,text:String)->Dictionary:
	## The modal's path for typed words. A question is asked and answered
	## here; a fate returns {"option"} for the cards' own path (choose), with
	## the words kept for it; an act of wrath or favour returns {"divine"}.
	var a:=Hall.find(audience_id)
	var p:=prisoner_of(audience_id)
	if a.is_empty() or p.is_empty() or String(a.get("status",""))!="waiting": return {"handled":false}
	var r:=read(_as_pronoun(p,text))
	if String(r.get("kind",""))=="question":
		return ask(audience_id,String(r.topic),String(r.manner),text)
	if String(r.get("kind",""))=="fate":
		_god(audience_id,text)
		a["prisoner_words"]=text.strip_edges()
		return {"handled":true,"option":String(r.option),"words":text.strip_edges()}
	var act:=Hall.divine_intent(audience_id,text)
	if act=="" and _aimed_at_prisoner(HARM_RE,_as_pronoun(p,text).to_lower()) and RegEx.create_from_string(NOT_RE).search(text.to_lower())==null: act="terrify"
	if act!="": return {"handled":true,"divine":act}
	# A question the prisoner was not asked in any form they can answer, or
	# talk: they hold their tongue, and the questions they can be asked are
	# offered. An order for someone else goes on to the court as usual.
	var asks:=text.strip_edges().ends_with("?")
	# An order for the court's own business (war, the home, the realm, a
	# covert act, a council directive) goes on to the court as usual.
	if not asks and _court_business(text,audience_id): return {"handled":false}
	_god(audience_id,text)
	if String(p.status)=="joined": _say(audience_id,p,"I do not know what you mean. Ask me who sent me, what I came for, how strong my people are, what they plan, or whether others came.")
	else: _narrate(audience_id,"%s says nothing to that." % String(p.given),String(p.given))
	_narrate(audience_id,"(%s can be asked who sent them, what they were sent to do, how strong their people are, what they plan, and whether others came.)" % String(p.given))
	return {"handled":true,"speech":true,"talk":true,"outcome":""}

static func _court_business(text:String,audience_id:String)->bool:
	if not ((load("res://scripts/court_war_orders.gd") as GDScript).call("read",text,"",audience_id) as Dictionary).is_empty(): return true
	if not ((load("res://scripts/covert_orders.gd") as GDScript).call("read",text,"",audience_id) as Dictionary).is_empty(): return true
	if not ((load("res://scripts/home_orders.gd") as GDScript).call("read",text) as Dictionary).is_empty(): return true
	if not ((load("res://scripts/realm_orders.gd") as GDScript).call("read",text) as Dictionary).is_empty(): return true
	return Hall.is_directive(text)

static func hear_command(audience_id:String,text:String)->Dictionary:
	## court_commands.hear's path (office orders, the "Put to death" menu, the
	## live command router): a fate in plain words is carried out at once,
	## shaped as a command result. {} when the words hold no fate.
	var a:=Hall.find(audience_id)
	if a.is_empty() or prisoner_of(audience_id).is_empty(): return {}
	var r:=read(_as_pronoun(prisoner_of(audience_id),text))
	if String(r.get("kind",""))!="fate": return {}
	a["prisoner_words"]=text.strip_edges()
	_god(audience_id,text)
	var done:=Hall.resolve(audience_id,String(r.option))
	if not bool(done.get("ok",false)): return {}
	return {"handled":true,"ok":true,"act":"command","verb":String(done.get("verb","kill")),"action":String(done.get("action","")),"text":text,"insist":false,"actor":{},"target":{},
		"actor_name":"","target_name":String(by_id(String(done.get("prisoner_id",""))).get("name","")),"executed":true,"terminal":true,"removed":bool(done.get("removed",false)),
		"outcome":String(done.get("outcome","")),"stage":"done","reaction":String(done.get("reaction","neutral")),"effects":{},"obedience":{"id":"obey","manner":"guards"},"witness_ids":[],
		"prisoner_id":String(done.get("prisoner_id",""))}

# --------------------------------------------------------------------------
# PARITY: our own agents taken abroad, judged by that ruler's temper
# --------------------------------------------------------------------------

static func abroad_odds(civ_id:String,kind:String)->Dictionary:
	## What their ruler does with one of ours taken among them: put to death,
	## sent home with a message, held and worked on to turn them, or kept.
	var t:=_temper(civ_id)
	var x:=0.20+float(t.a)*0.25+(1.0-float(t.e))*0.25+float(t.grudge)*0.15+(0.25 if bool(t.hot) else 0.0)+(0.25 if kind=="assassinate" else 0.0)+(0.1 if String(t.trait)=="grudge" else 0.0)
	var s:=0.15+float(t.e)*0.30+float(t.dread)*0.35+(1.0-float(t.r))*0.10+(0.1 if String(t.trait) in ["matchmaker","ledger"] else 0.0)
	var u:=0.10+float(t.o)*0.20+float(t.d)*0.15+(0.10 if _tier(civ_id)>=2 else 0.0)+(0.05 if String(t.trait)=="magpie" else 0.0)
	var k:=0.10+float(t.d)*0.10
	if kind=="double": x+=1.0   # a traitor among their own: death, nearly always
	var total:=x+s+u+k
	return {"execute":snappedf(x/total,0.0001),"send":snappedf(s/total,0.0001),"turn":snappedf(u/total,0.0001),"keep":snappedf(k/total,0.0001)}

static func _our_loyalty(agent:Dictionary)->float:
	var people:=Hall.people_regard()
	return clampf(float(people.get("love",0.5))*0.6+float(agent.get("nerve",0.5))*0.3+0.1,0.05,0.95)

static func judge_ours(op:Dictionary,day:int,doing:String)->Dictionary:
	## One of ours taken alive among them (covert_ops: a caught watcher, a
	## source found, an assassin taken). Their ruler decides by temper with
	## stated odds and a seeded roll; told to the god plainly.
	var civ_id:=String(op.get("civ_id",""))
	var kind:="double" if bool(op.get("double",false)) and not bool(op.get("double_feigned",false)) else String(op.get("kind","watch"))
	var odds:=abroad_odds(civ_id,kind)
	var roll:=_rng("abroad|%d|%s|%d" % [int(op.get("id",0)),civ_id,day]).randf()
	var choice:="keep"
	var acc:=0.0
	for c in ["execute","send","turn","keep"]:
		acc+=float(odds[c])
		if roll<acc: choice=c; break
	var agent:Dictionary=_covert().call("_op_agent",op)
	var ruler:=_ruler_given(civ_id)
	var who:=String(op.get("agent_name",agent.get("name","our agent")))
	var rec:={"op_id":int(op.get("id",0)),"civ_id":civ_id,"agent":String(op.get("agent","")),"name":who,"given":String(op.get("agent_given","")),"kind":kind,"day":day,"odds":odds,"roll":snappedf(roll,0.0001),
		"choice":choice,"status":"","doing":doing,"loyalty":_our_loyalty(agent),"nerve":clampf(float(agent.get("nerve",0.5)),0.0,1.0)}
	var text:=""
	match choice:
		"execute":
			rec.status="executed"
			_our_agent_dies(op,agent,civ_id)
			text="%s had %s put to death (the odds %s would were %s)." % [ruler,who,ruler,pct(float(odds.execute))]
		"send":
			var mk:=_their_message_kind(civ_id)
			rec.status="coming_home"; rec["message"]=mk; rec["words"]=_their_words(mk,civ_id); rec["arrive_day"]=day+int(_covert().call("travel_days",civ_id,""))
			text="%s is sending %s home with a message (the odds of that were %s); they walk for about %d days." % [ruler,who,pct(float(odds.send)),int(rec.arrive_day)-day]
		"turn":
			# Worked on in their keeping, as we work on theirs: the same
			# turn_odds, our agent's love of the god as their loyalty.
			var t:=turn_odds(held_view(rec),civ_id)
			var conv:=float(t.converted)
			var feign:=float(t.feigned)
			var r2:=_rng("abroad_turn|%d|%s" % [int(op.get("id",0)),civ_id]).randf()
			rec["turn_odds"]=t
			rec["turn_roll"]=snappedf(r2,0.0001)
			rec.status="held_abroad"
			rec["release_day"]=day+28+_rng("abroad_days|%d" % int(op.get("id",0))).randi_range(0,28)
			rec["turned"]="converted" if r2<conv else ("feigned" if r2<conv+feign else "unmoved")
			text="%s holds %s under guard (the odds %s would hold them, rather than kill them or send them home, were %s)." % [ruler,who,ruler,pct(float(odds.keep)+float(odds.turn))]
		_:
			rec.status="held_abroad"
			text="%s holds %s under guard (the odds %s would hold them, rather than kill them or send them home, were %s)." % [ruler,who,ruler,pct(float(odds.keep)+float(odds.turn))]
	rec["told"]=text
	var list:Array=state().abroad
	list.push_front(rec)
	while list.size()>ABROAD_MAX: list.pop_back()
	_stat("ours_judged_"+choice)
	return rec

static func held_view(rec:Dictionary)->Dictionary:
	## One of ours in their keeping, as turn_odds reads a prisoner: our love
	## of the god is their loyalty; they are kept plainly, neither kind nor cruel.
	return {"love":0.2,"treatment":0.0,"loyalty":float(rec.get("loyalty",0.5)),"dread":0.3,"courage":float(rec.get("nerve",0.5)),"temper":"","family":{"spouse":false,"children":0}}

static func _their_message_kind(civ_id:String)->String:
	var t:=_temper(civ_id)
	if float(t.a)>=0.6: return "threat"
	if String(t.trait)=="ledger": return "demand"
	if float(t.e)>=0.6: return "peace"
	return "warning"

static func _their_words(kind:String,civ_id:String)->String:
	var given:=_ruler_given(civ_id)
	match kind:
		"threat": return "Tell your god: send another to creep among us, and %s's men will come to your fires." % given
		"demand": return "Tell your god: %s wants a gift for this insult, or will remember it." % given
		"peace": return "Tell your god: %s sends you back your own, alive. Let it end here." % given
	return "Tell your god: keep your people at home. The next one we find, we kill."

static func _our_agent_dies(op:Dictionary,agent:Dictionary,civ_id:String)->void:
	## One of ours put to death abroad: one death of our people, in the same
	## ledgers as any other (a named person's own record too).
	var reason:="Put to death by %s" % _name(civ_id)
	var source:=String(agent.get("source",""))
	if source=="turned":
		# One of theirs won over and sent back: they left our count when they
		# went; their death is among their own people.
		var turned:=by_id(String(agent.get("prisoner_id","")))
		if not turned.is_empty():
			turned["status"]="dead"; turned["status_day"]=_day()
			turned["fate"]={"kind":"dead","day":_day(),"why":"found out among %s and put to death" % _the(civ_id)}
		var kept0:Dictionary=(_covert().call("state") as Dictionary).agents.get(String(op.get("agent","")),{})
		if not kept0.is_empty(): kept0["judged"]="executed"
		return
	var pid:=int(agent.get("person_id",0))
	var done:=false
	if source=="person" and pid>0:
		var person:=GovernmentPeopleSystem.person_snapshot(pid)
		if not person.is_empty() and String(person.get("status",""))=="active":
			# The government's own quiet path: dead first (no succession names
			# them again), their offices passed on, one truthful event, and no
			# cost to our legitimacy or cohesion: the god did not kill them.
			var gone:Dictionary=GovernmentPeopleSystem.person_died_abroad(pid,reason)
			if bool(gone.get("ok",false)):
				var age:=floori(float(_day()-int(person.get("born_day",_day()-30*365)))/365.0)
				var dead:Dictionary=GameState.register_population_deaths_by_cell([{"cohort":_cohort_of(age),"sex":String(person.get("sex","male")),"count":1}],"put_to_death_abroad","%s was put to death by %s." % [String(person.get("name","")),_name(civ_id)],String(person.get("name","")))
				done=int(dead.get("count",0))>0
	elif source=="figure" and String(agent.get("figure_id",""))!="":
		HistoricalFigures.record_death(String(agent.figure_id),_day(),reason)
	elif source=="known" and String(agent.get("known_id",""))!="":
		var known:Dictionary=(load("res://scripts/court_persons.gd") as GDScript).call("by_id",String(agent.known_id))
		if not known.is_empty(): known["status"]="dead"
	if not done: GameState.register_population_deaths(1,reason)
	# Their record keeps "caught"; what their ruler did is beside it.
	var kept:Dictionary=(_covert().call("state") as Dictionary).agents.get(String(op.get("agent","")),{})
	if not kept.is_empty(): kept["judged"]="executed"

static func _abroad_daily(rec:Dictionary,day:int)->void:
	match String(rec.get("status","")):
		"coming_home":
			if day>=int(rec.get("arrive_day",day)): _ours_home(rec,day)
		"held_abroad":
			# The same monthly chance to slip the guards our prisoners have.
			var since:=day-int(rec.get("day",day))
			if since>0 and since%30==0:
				var odds:=abroad_escape_odds(rec)
				var roll:=_rng("abroad_esc|%d|%s|%d" % [int(rec.get("op_id",0)),String(rec.civ_id),int(since/30.0)]).randf()
				if roll<odds:
					rec.status="home"; rec["home_day"]=day; rec["escape"]={"odds":odds,"roll":snappedf(roll,0.0001),"month":int(since/30.0)}
					_tell("%s Came Home" % String(rec.name),"%s slipped the guards among %s and came home (the odds were %s a month)." % [String(rec.name),_the(String(rec.civ_id)),pct(odds)],day)
					_covert().call("record_agent",{"key":String(rec.agent),"name":String(rec.name)},"watch",String(rec.civ_id),"home")
					_stat("ours_escaped")
					return
			if String(rec.get("turned",""))!="" and day>=int(rec.get("release_day",1<<30)):
				match String(rec.turned):
					"converted":
						# Theirs now, though they say they slipped away: their
						# word to us is false from here (the ledger knows).
						rec.status="home_turned"
						rec["home_day"]=day
						_carried_home(String(rec.civ_id),0.08)
						_tell("%s Came Home" % String(rec.name),"%s came home from %s, saying they slipped the guards in the night." % [String(rec.name),_the(String(rec.civ_id))],day)
						_covert().call("record_agent",{"key":String(rec.agent),"name":String(rec.name)},"watch",String(rec.civ_id),"home")
					"feigned":
						# Ours all along: they pretended to be won, and bring true word.
						rec.status="home"
						rec["home_day"]=day
						_covert().call("_sharpen",String(rec.civ_id),"",0.8,day,String(rec.name))
						_tell("%s Came Home" % String(rec.name),"%s came home from %s. %s let them go believing them won over; they were not, and they bring true word of %s's numbers." % [String(rec.name),_the(String(rec.civ_id)),_ruler_given(String(rec.civ_id)),_the(String(rec.civ_id))],day)
						_covert().call("record_agent",{"key":String(rec.agent),"name":String(rec.name)},"watch",String(rec.civ_id),"home")
					_:
						rec["turned"]=""   # unmoved: kept, as before
		"home_turned":
			# Their eyes among us, until found: each season, our watch may see
			# it, on our watch's odds against a spy of theirs (their cunning
			# against ours: they turned them).
			var since:=day-int(rec.get("home_day",day))
			if since>0 and since%90==0:
				_carried_home(String(rec.civ_id),0.05)
				var found:=clampf(float(_covert().call("_catch_chance",String(rec.civ_id)))*0.3,0.05,0.4)
				if _rng("found|%d|%d" % [int(rec.op_id),int(since/90.0)]).randf()<found:
					rec.status="found_out"
					_tell("%s Was Theirs" % String(rec.name),"Our watch found that %s was turned while held by %s; since coming home they have carried word of us to %s (the odds our watch would see it each season were %s)." % [String(rec.name),_the(String(rec.civ_id)),_ruler_given(String(rec.civ_id)),pct(found)],day)
					_stat("ours_turned_found")

static func _ours_home(rec:Dictionary,day:int)->void:
	var civ_id:=String(rec.civ_id)
	var kind:=String(rec.get("message","warning"))
	rec.status="home"
	match kind:
		"threat": Hall._shift_relation(civ_id,-0.02,0.08)
		"peace": Hall._shift_relation(civ_id,0.05,-0.05)
		"demand": Hall._add_occasion({"key":"their_demand:%d" % int(rec.op_id),"type":"relation_cool","civ_id":civ_id,"day":day,"not_before":day+20,"expires":day+300,"data":{"text":"what %s demanded for our agent" % _ruler_given(civ_id)}})
		_: Hall._shift_relation(civ_id,0.0,0.03)
	_tell("%s Came Home" % String(rec.name),"%s came home from %s. %s let them go with %s: \"%s\"" % [String(rec.name),_the(civ_id),_ruler_given(civ_id),message_label(kind).to_lower(),String(rec.get("words",""))],day)
	_covert().call("record_agent",{"key":String(rec.agent),"name":String(rec.name)},"watch",civ_id,"home")

static func abroad(limit:int=8)->Array:
	var out:Array=[]
	for r in state().abroad:
		out.append(r)
		if out.size()>=limit: break
	return out

# --------------------------------------------------------------------------
# Reads for the board and the court
# --------------------------------------------------------------------------

static func status_words(p:Dictionary)->String:
	match String(p.get("status","")):
		"held": return "held under guard"
		"turning": return "with the carers, %d days to go" % maxi(0,int(p.get("turn_end",_day()))-_day())
		"joined": return "won over, one of us now"
		"executed": return "put to death"
		"sent_home":
			var fate:Dictionary=p.get("fate",{}) if p.get("fate") is Dictionary else {}
			return "sent home with %s" % message_label(String(fate.get("message",""))).to_lower() if not bool(fate.get("answered",false)) else "sent home; %s" % String(fate.get("answer","")).get_slice(" (",0)
		"escaped": return "escaped"
		"fled": return "fled; was only pretending"
		"double": return "sent back as our eyes"
	return String(p.get("status",""))

static func board_rows(limit:int=6)->Array:
	## The War screen's prisoners: one line each, then what they said (a word
	## shown false is marked).
	refresh_contradictions()
	var out:Array=[]
	for q in state().prisoners:
		var p:Dictionary=q
		var line:="%s, %s · %s" % [String(p.name),title_of(p).get_slice(",",0),status_words(p)]
		if String(p.status)=="held": line+=" · escape %s a month" % pct(escape_odds(p))
		out.append(line)
		for r in said_rows(p):
			out.append("   said: %s%s" % [String(r.text),(" — FALSE: "+String(r.found_by)) if bool(r.found_false) else ""])
		if out.size()>=limit*3: break
	for r in state().abroad:
		out.append("Ours: %s" % String((r as Dictionary).get("told","")))
		if out.size()>=limit*4: break
	return out

static func caught_fate(id:String)->String:
	var p:=by_id(id)
	return "" if p.is_empty() else status_words(p)
