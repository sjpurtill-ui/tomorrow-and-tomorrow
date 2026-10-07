extends RefCounted
## THE EYES AND THE WARY: trained people who live unseen among another people
## (our eyes), and trained people who watch for theirs among us (the wary).
## Both are raised as the army is: a training course with a length and a ration,
## a corps that grows by the course's intake and thins with the years, and a
## craft (0..1) that rises with training and service, capped by the age.
##
## Words follow the age (EraWords.stage): eyes and the wary at the hearth;
## watchers and gatekeepers once the people writes; spies and counter-
## intelligence in a reckoned age. Nothing early says "spy".
##
## What the corps changes, with the engine's numbers:
##   - An eye sent among them is one of ours trained to it (covert_ops.gd
##     launch): their stealth, nerve and tongue are the corps' craft, not a
##     volunteer's luck. An untrained volunteer still goes when none is ready.
##   - The wary set our odds of finding their eyes among us (covert_ops.gd
##     _catch_chance): coverage (the wary for our numbers) times craft.
##   - Watching our own people breeds DISTRUST: the more of the wary, the more
##     neighbours wonder who reports on whom, and every eye of theirs found
##     among us leaves the people asking who else might be one. Distrust is
##     taken from the people's cohesion (consequence_engine.gd).
##
## Kept on the court's saved record (ForeignDiplomacy.audiences["eyes"]).

const KEY:="eyes"
const VERSION:=1
const CORPS:=["eyes","wary"]

## [label, people taken into the course a year per 1,000 of our people]
const POLICIES:={"none":["None",0.0],"few":["A few",0.8],"steady":["Steady",2.0],"many":["Many",4.5]}
const POLICY_ORDER:=["none","few","steady","many"]

## The course by age: days long, food a trainee a day, the craft a graduate
## starts at, and the most the age can teach.
const COURSE:={
	"hearth":{"days":120.0,"food":0.3,"start":0.45,"cap":0.72},
	"lettered":{"days":180.0,"food":0.35,"start":0.55,"cap":0.84},
	"reckoned":{"days":300.0,"food":0.4,"start":0.65,"cap":0.94},
}
## Craft a trained member gains a year of service, up to the age's cap.
const SERVICE_GAIN:=0.02
## A member's keep while not in training (food a day): away from other work.
const KEEP_FOOD:=0.15
## Members lost to age, illness and leaving each year.
const ATTRITION:=0.04
## The wary needed per 1,000 of our people to watch everyone (coverage 1).
const FULL_WATCH_PER_K:=4.0
## Distrust (0..1): the share the wary's watching sets as its floor, what each
## eye of theirs found among us adds, how fast it fades toward the floor (a
## day), and how much of it is taken from cohesion.
const WATCH_DISTRUST:=0.18
const FOUND_DISTRUST:=0.08
const DISTRUST_FADE:=1.0/240.0
const COHESION_COST:=0.25

## The words of the age.
const WORDS:={
	"hearth":{"eye":"eye","eyes":"eyes","Eyes":"Eyes","wary":"the wary","Wary":"The wary","network":"listeners at their fires","train":"teach"},
	"lettered":{"eye":"watcher","eyes":"watchers","Eyes":"Watchers","wary":"gatekeepers","Wary":"Gatekeepers","network":"a watch among them","train":"train"},
	"reckoned":{"eye":"spy","eyes":"spies","Eyes":"Spies","wary":"counter-intelligence","Wary":"Counter-intelligence","network":"a spy network","train":"train"},
}

static func stage()->String:
	return preload("res://scripts/hud/era_words.gd").stage()

static func word(key:String)->String:
	return String((WORDS.get(stage(),WORDS.hearth) as Dictionary).get(key,key))

## "an eye", "a watcher", "a spy": the word of the age with its article.
static func an_eye()->String:
	var w:=word("eye")
	return ("an " if w.left(1) in ["a","e","i","o","u"] else "a ")+w

static func _day()->int:
	return int(GameState.elapsed_days)

static func state()->Dictionary:
	ForeignDiplomacy.ensure()
	var holder:Dictionary=ForeignDiplomacy.audiences
	var s:Variant=holder.get(KEY)
	if not s is Dictionary or int((s as Dictionary).get("version",0))!=VERSION:
		s={"version":VERSION,"distrust":0.0,"last_day":_day(),"carry":{}}
		for corps in CORPS: (s as Dictionary)[corps]={"policy":"none","members":0.0,"craft":0.0,"training":[]}
		holder[KEY]=s
	var d:Dictionary=s
	for corps in CORPS:
		if not d.get(corps) is Dictionary: d[corps]={"policy":"none","members":0.0,"craft":0.0,"training":[]}
		var c:Dictionary=d[corps]
		if not c.get("training") is Array: c["training"]=[]
	if not d.get("carry") is Dictionary: d["carry"]={}
	return d

static func valid_state(data:Variant)->bool:
	if not data is Dictionary: return false
	for corps in CORPS:
		if not (data as Dictionary).get(corps) is Dictionary: return false
	return true

static func policy(corps:String)->String:
	return String((state()[corps] as Dictionary).get("policy","none"))

static func set_policy(corps:String,value:String)->bool:
	if not corps in CORPS or not POLICIES.has(value): return false
	(state()[corps] as Dictionary)["policy"]=value
	return true

## Members ready (trained, at home or abroad counted together).
static func members(corps:String)->float:
	return float((state()[corps] as Dictionary).get("members",0.0))

static func craft(corps:String)->float:
	return clampf(float((state()[corps] as Dictionary).get("craft",0.0)),0.0,1.0)

static func in_training(corps:String)->float:
	var n:=0.0
	for t in (state()[corps] as Dictionary).training:
		if t is Dictionary: n+=float((t as Dictionary).get("count",0.0))
	return n

## How much of our people the wary can watch (0..1).
static func coverage()->float:
	var people:=maxf(1.0,float(GameState.population_exact))
	return clampf(members("wary")/(people/1000.0*FULL_WATCH_PER_K),0.0,1.0)

static func distrust()->float:
	return clampf(float(state().get("distrust",0.0)),0.0,1.0)

## What distrust takes from the people's cohesion target (consequence_engine).
static func cohesion_cost()->float:
	if Engine.get_main_loop()==null or String(WorldSimulation.actor_id)!="player": return 0.0
	var s:Variant=ForeignDiplomacy.audiences.get(KEY) if ForeignDiplomacy.audiences is Dictionary else null
	if not s is Dictionary: return 0.0
	return clampf(float((s as Dictionary).get("distrust",0.0)),0.0,1.0)*COHESION_COST

## One of theirs found living among us: the people wonder who else is.
static func found_among_us()->void:
	var s:=state()
	s["distrust"]=clampf(float(s.distrust)+FOUND_DISTRUST,0.0,1.0)

# --------------------------------------------------------------------------
# Daily: courses run, graduates join, service sharpens, the years thin
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	if String(WorldSimulation.actor_id)!="player": return
	var s:=state()
	var span:=maxi(1,day-int(s.get("last_day",day)))
	if day<=int(s.get("last_day",-1)): return
	s["last_day"]=day
	var course:Dictionary=COURSE.get(stage(),COURSE.hearth)
	var people:=maxf(1.0,float(GameState.population_exact))
	var food_need:=0.0
	for corps in CORPS:
		var c:Dictionary=s[corps]
		# Intake: the policy's yearly share, carried in fractions until a whole
		# person starts the course.
		var yearly:=float((POLICIES.get(String(c.policy),POLICIES.none) as Array)[1])*people/1000.0
		var carry:=float((s.carry as Dictionary).get(corps,0.0))+yearly*float(span)/365.0
		var starting:=floorf(carry)
		(s.carry as Dictionary)[corps]=carry-starting
		if starting>=1.0: (c.training as Array).append({"count":starting,"done":day+roundi(float(course.days))})
		# Graduates join at the age's starting craft (the corps' craft is the
		# weighted mean of who serves).
		for t in (c.training as Array).duplicate():
			var entry:Dictionary=t
			if day<int(entry.done): continue
			(c.training as Array).erase(t)
			var before:=float(c.members)
			var joined:=float(entry.count)
			c["members"]=before+joined
			c["craft"]=(float(c.craft)*before+float(course.start)*joined)/maxf(1.0,before+joined)
		# Service sharpens, up to what the age can teach; the years thin.
		if float(c.members)>0.0:
			c["craft"]=minf(float(course.cap),float(c.craft)+SERVICE_GAIN*float(span)/365.0) if float(c.craft)<float(course.cap) else float(c.craft)
			c["members"]=maxf(0.0,float(c.members)*(1.0-ATTRITION*float(span)/365.0))
		food_need+=in_training(corps)*float(course.food)+float(c.members)*KEEP_FOOD
	if food_need>0.0 and WorldSimulation.food!=null and WorldSimulation.food.has_method("issue_for_obligation"):
		WorldSimulation.food.issue_for_obligation(food_need*float(span),"eyes","%s and %s" % [word("Eyes"),word("wary")])
	_leaks(day)
	_accusations(day,span)
	# Distrust fades toward what the wary's watching keeps it at.
	var floor_:=coverage()*WATCH_DISTRUST
	var d:=float(s.distrust)
	s["distrust"]=move_toward(d,floor_,DISTRUST_FADE*float(span)) if d>floor_ else move_toward(d,floor_,DISTRUST_FADE*float(span)*0.5)

# --------------------------------------------------------------------------
# A trained eye for an errand
# --------------------------------------------------------------------------

## One trained eye leaves the corps for an errand (covert_ops.gd launch;
## volunteer_for builds the agent from the corps' craft).
static func take_eye()->bool:
	var c:Dictionary=state().eyes
	if float(c.members)<1.0: return false
	c["members"]=float(c.members)-1.0
	return true

## A trained eye home again rejoins the corps.
static func eye_home(agent:Dictionary)->void:
	if not bool(agent.get("trained",false)): return
	var c:Dictionary=state().eyes
	c["members"]=float(c.members)+1.0

# --------------------------------------------------------------------------
# Plain words for the board and the court
# --------------------------------------------------------------------------

static func summary()->Dictionary:
	var course:Dictionary=COURSE.get(stage(),COURSE.hearth)
	var out:={"stage":stage(),"distrust":distrust(),"coverage":coverage(),"course_days":int(course.days),"course_food":float(course.food),"cap":float(course.cap),
		"cohesion_cost":distrust()*COHESION_COST}
	for corps in CORPS:
		out[corps]={"policy":policy(corps),"policy_label":String((POLICIES.get(policy(corps),POLICIES.none) as Array)[0]),"members":members(corps),"craft":craft(corps),"training":in_training(corps)}
	return out


# --------------------------------------------------------------------------
# Secrecy: what is done with the news when one of theirs is found among us
# --------------------------------------------------------------------------
# Each choice trades the people's trust against vigilance and what we might
# learn. The choices grow with the age: a lettered people can seal it in its
# records; a reckoned one can let the enemy think nothing was noticed.

## [id, label, what it does] by the age that first offers it.
const SECRECY:=[
	["hush","Keep it among the council","Little distrust now; no one else watches harder; the secret may get out later, and worse for having been kept.","hearth"],
	["proclaim","Tell the people","Distrust rises at once, but every hearth watches strangers for a year (their eyes are caught more often) and their sender is warned off.","hearth"],
	["sweep","Search for others","The wary question everyone the stranger touched: any other of theirs among us may be found, but distrust surges, and a people short of trust starts accusing its own.","hearth"],
	["seal","Seal it in the records","Written down and kept from all but the council: no distrust, no leak, but the people learn nothing to be wary of.","lettered"],
	["play","Let them think we never noticed","We keep their channel open and feed it false word of us; their reading of us grows wrong, as long as they believe it.","reckoned"],
]
const LEAK_ODDS:=0.35
const LEAK_DAYS_MIN:=60
const LEAK_DAYS_MAX:=400
const VIGILANT_DAYS:=365
const VIGILANT_CATCH:=0.12
const SWEEP_DISTRUST:=0.14

static func secrecy_options()->Array:
	var order:={"hearth":0,"lettered":1,"reckoned":2}
	var now:=int(order.get(stage(),0))
	var out:Array=[]
	for row:Array in SECRECY:
		if int(order.get(String(row[3]),0))<=now: out.append({"id":String(row[0]),"label":String(row[1]),"sub":String(row[2])})
	return out

## The god's choice for one found among us. Returns {outcome, found:[...]}.
static func secrecy(choice:String,civ_id:String,day:int,seed:String)->Dictionary:
	var s:=state()
	var rng:=RandomNumberGenerator.new(); rng.seed=hash("%s:secrecy:%s" % [seed,choice])
	var out:={"outcome":"","found":[]}
	match choice:
		"hush":
			# The finding's own distrust is taken back to half; a leak may come.
			s["distrust"]=maxf(0.0,float(s.distrust)-FOUND_DISTRUST*0.5)
			if rng.randf()<LEAK_ODDS:
				var leaks:Array=s.get("leaks",[])
				leaks.append({"day":day+rng.randi_range(LEAK_DAYS_MIN,LEAK_DAYS_MAX),"amount":FOUND_DISTRUST*1.5})
				s["leaks"]=leaks
			out.outcome="Only the council knows. The people go on as before (the odds it gets out were %d in 100)." % roundi(LEAK_ODDS*100.0)
		"proclaim":
			s["distrust"]=clampf(float(s.distrust)+FOUND_DISTRUST*0.5,0.0,1.0)
			s["vigilant_until"]=day+VIGILANT_DAYS
			out.outcome="The news goes from hearth to hearth. Every stranger is watched for a year: their %s are caught more often (+%d in 100), though neighbours eye one another too." % [word("eyes"),roundi(VIGILANT_CATCH*100.0)]
		"sweep":
			s["distrust"]=clampf(float(s.distrust)+SWEEP_DISTRUST,0.0,1.0)
			var found:Array=preload("res://scripts/covert_ops.gd").sweep_incoming(day,clampf(0.35+coverage()*craft("wary")*0.5,0.2,0.85))
			out.found=found
			var accused:=0
			var cohesion:=clampf(float(GameState.simulation_metrics.get("cohesion",0.5)),0.0,1.0)
			if cohesion<0.5 and rng.randf()<(0.5-cohesion)*2.0:
				if not accuse(day,civ_id,"the search").is_empty(): accused=1
			out.outcome="%s question everyone the stranger touched. %s Distrust surges.%s" % [word("Wary"),("They found %d more of theirs among us." % found.size()) if not found.is_empty() else "No other of theirs was found.",(" A neighbour has been accused in the fear: they wait to be questioned.") if accused>0 else ""]
		"seal":
			s["distrust"]=maxf(0.0,float(s.distrust)-FOUND_DISTRUST)
			out.outcome="Written in the council's records and kept there. The people learn nothing of it."
		"play":
			s["distrust"]=maxf(0.0,float(s.distrust)-FOUND_DISTRUST)
			s["playing"]=civ_id
			out.outcome="Their channel stays open; what flows home through it now is ours to write."
	return out

## A secret kept too long got out: the distrust falls on us after all.
static func _leaks(day:int)->void:
	var s:=state()
	var leaks:Array=s.get("leaks",[])
	for l in leaks.duplicate():
		if day<int((l as Dictionary).day): continue
		leaks.erase(l)
		s["distrust"]=clampf(float(s.distrust)+float((l as Dictionary).amount),0.0,1.0)
		preload("res://scripts/chronicle.gd").record({"key":"eyes:leak:%d" % day,"title":"The Secret Gets Out","text":"Word that one of their %s lived among us, and that the council kept it quiet, has reached every hearth. People ask what else is kept from them." % word("eyes"),"tier":"notice","kind":"court","domain":"security"})

static func vigilance(day:int=-1)->float:
	if day<0: day=_day()
	return VIGILANT_CATCH if int(state().get("vigilant_until",-1))>day else 0.0

# --------------------------------------------------------------------------
# Accusations: a people short of trust turns on its own
# --------------------------------------------------------------------------

## Below this cohesion neighbours accuse neighbours of being their eyes.
const ACCUSE_BELOW:=0.45
## Accusations a year at the lowest trust (scaled by how low it is).
const ACCUSE_YEARLY:=4.0

static func _accusations(day:int,span:int)->void:
	var cohesion:=clampf(float(GameState.simulation_metrics.get("cohesion",0.5)),0.0,1.0)
	if cohesion>=ACCUSE_BELOW: return
	var depth:=(ACCUSE_BELOW-cohesion)/ACCUSE_BELOW
	var chance:=ACCUSE_YEARLY*depth*(0.5+distrust())*float(span)/365.0
	var rng:=RandomNumberGenerator.new(); rng.seed=hash("%d:accuse:%d" % [int(GameState.world_seed),day])
	if rng.randf()<chance: accuse(day,"","fear")

## One of ours accused of being an eye of a people we know. Most are
## innocent; one may truly be theirs (an eye of theirs among us now). The
## accused waits under guard to be questioned. {} when there is nobody to be
## accused of serving.
static func accuse(day:int,civ_id:String,why:String)->Dictionary:
	var Captives:=preload("res://scripts/captured_agents.gd")
	# One accused waiting at a time.
	for p in Captives.state().prisoners:
		if p is Dictionary and bool((p as Dictionary).get("accused",false)) and String((p as Dictionary).get("status",""))=="held": return {}
	var Covert:=preload("res://scripts/covert_ops.gd")
	var real:Dictionary=Covert.incoming_one(civ_id)
	if civ_id=="": civ_id=String(real.get("civ_id","")) if not real.is_empty() else Covert.a_known_people(day)
	if civ_id=="": return {}
	var p:Dictionary=Captives.take({"civ_id":civ_id,"kind":"watch"},day)
	var guilty:=not real.is_empty() and String(real.get("civ_id",""))==civ_id
	if guilty: Covert.remove_incoming(real)
	p["accused"]=true
	p["innocent"]=not guilty
	p["accused_why"]=why
	if not guilty: Captives.make_one_of_ours(p,day)
	s_distrust_bump(0.02)
	preload("res://scripts/chronicle.gd").record({"key":"eyes:accused:%s" % String(p.id),"title":"%s Is Accused" % String(p.name),
		"text":"%s is accused by neighbours of being an %s of %s. They wait under guard for you to question them and find the truth." % [String(p.name),word("eye"),Captives._the(civ_id)],
		"tier":"notice","kind":"court","domain":"security","action":{"kind":"prisoner","prisoner_id":String(p.id)}})
	return p

static func s_distrust_bump(amount:float)->void:
	var s:=state()
	s["distrust"]=clampf(float(s.distrust)+amount,0.0,1.0)
