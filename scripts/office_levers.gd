extends RefCounted
## OFFICE LEVERS: what the one who holds each office changes, as a number the
## engine applies and the screens show. Every people runs on the same rules:
## each reading takes the holder from the current actor scope
## (WorldSimulation.state.leadership_positions), so a rival's keeper of
## stores spares or spoils their stores exactly as ours does.
##
## A lever is read from the holder's own skills (government_people_system.gd
## SKILL_KEYS, 0..100) weighted for the lever. An ordinary holder (every skill
## ORDINARY_SKILL) moves nothing; a holder SKILL_SPAN above ordinary reaches
## the lever's best end, one SKILL_SPAN below its worst. Realistic holders
## (one strength at 72-93, one weakness at 14-36) land within about two
## thirds of either end, so the ends below stay inside historical ranges.
##
##   office          lever        engine hook                         range
##   Steward         labour       consequence_engine labour efficiency x0.95 .. x1.06
##   Quartermaster   spoilage     food_system._spoilage_rates          x1.15 .. x0.80
##   Scholar         forgetting   society_model idle loss of practices x1.20 .. x0.60
##   ChiefScout      scout_cover  scouts' concealment and evasion      -0.02 .. +0.08
##   Envoy           envoy_sway   foreign_diplomacy.forecast score     -0.05 .. +0.10
##   Justice         resistance   consequence_engine directive resistance x1.15 .. x0.75
##   HighPriest      devotion     divine_regard.people_regard love     -0.02 .. +0.06
##   Treasurer       compliance   economy_system tax compliance        -0.04 .. +0.06
##   Marshal         (the home commander: military_campaign._marshal_commander)
##
## Scale, from 120 people to billions: a lever applies as
## 1 + (lever - 1) * reach (an added lever as lever * reach). reach is 1 while
## the people number FULL_REACH_POPULATION or fewer (the headman knows
## everyone); above that it eases, over REACH_BLEND people, to what the
## clerks carry: clamp(admin_coverage * (0.6 + 0.4 * institutions),
## MIN_REACH, 1), admin_coverage as consequence_engine.gd reads it. A great
## minister without clerks is wasted; a strong bureaucracy carries a poor one.
##
## Before an office exists the Headman (Steward) stands in for the stores, the
## lore and the messengers (government_people_system.executing_office) and
## carries STAND_IN_SHARE of that lever. An office that exists but stands
## vacant works as a poor holder would (VACANT_SCORE).
## Static; preload. No save fields: every number is read from the holders.

const ORDINARY_SKILL:=47.0
const SKILL_SPAN:=33.0
const FULL_REACH_POPULATION:=500.0
const REACH_BLEND:=1500.0
const MIN_REACH:=0.25
const STAND_IN_SHARE:=0.5
## How far below ordinary an empty office works (in SKILL_SPANs).
const VACANT_SCORE:=-0.5
## The orders an office carries go this much faster or slower at most.
const ORDER_PACE_MIN:=0.70
const ORDER_PACE_MAX:=1.35

## The rank at which each central office opens (government_people_system.gd
## OFFICE_DEFINITIONS; test_office_levers checks they agree).
const UNLOCK:={"Steward":0,"ChiefScout":0,"Quartermaster":1,"Marshal":2,"Scholar":3,"Envoy":4}

const LEVERS:={
	"Steward":{"id":"labour","kind":"mul","worst":0.95,"best":1.06,"skills":{"Administration":0.55,"Construction":0.25,"Diplomacy":0.20},"stand_in":false},
	"Quartermaster":{"id":"spoilage","kind":"mul","worst":1.15,"best":0.80,"skills":{"Provisioning":0.65,"Logistics":0.20,"Administration":0.15},"stand_in":true},
	"Scholar":{"id":"forgetting","kind":"mul","worst":1.20,"best":0.60,"skills":{"Knowledge":0.75,"Administration":0.25},"stand_in":true},
	"ChiefScout":{"id":"scout_cover","kind":"add","worst":-0.02,"best":0.08,"skills":{"Logistics":0.40,"Knowledge":0.35,"Defense":0.25},"stand_in":false},
	"Envoy":{"id":"envoy_sway","kind":"add","worst":-0.05,"best":0.10,"skills":{"Diplomacy":0.75,"Logistics":0.15,"Knowledge":0.10},"stand_in":true},
	"Justice":{"id":"resistance","kind":"mul","worst":1.15,"best":0.75,"skills":{"Administration":0.50,"Knowledge":0.30,"Diplomacy":0.20},"stand_in":false},
	"HighPriest":{"id":"devotion","kind":"add","worst":-0.02,"best":0.06,"skills":{"Diplomacy":0.60,"Knowledge":0.40},"stand_in":false},
	"Treasurer":{"id":"compliance","kind":"add","worst":-0.04,"best":0.06,"skills":{"Administration":0.50,"Provisioning":0.30,"Logistics":0.20},"stand_in":false},
}

## Each lever in words: what it does for the better and for the worse, and
## the short form for "Iska would ..." ({n} is the size in the lever's unit).
const WORDS:={
	"labour":{"up":"Gets {n}% more work done","down":"Gets {n}% less work done","zero":"Gets as much work done as an ordinary one","would_up":"would get {n}% more","would_down":"would get {n}% less","unit":"%"},
	"spoilage":{"up":"Saves {n}% of what would rot","down":"Lets {n}% more of the stores rot","zero":"As much rots as under an ordinary one","would_up":"would save {n}%","would_down":"would let {n}% more rot","unit":"%"},
	"forgetting":{"up":"Unused ways are forgotten {n}% slower","down":"Unused ways are forgotten {n}% faster","zero":"Unused ways are forgotten as under an ordinary one","would_up":"would slow it {n}%","would_down":"would speed it {n}%","unit":"%"},
	"scout_cover":{"up":"Scouts are caught {n}% less often","down":"Scouts are caught {n}% more often","zero":"Scouts are caught as often as under an ordinary one","would_up":"would make it {n}% less","would_down":"would make it {n}% more","unit":"%"},
	"envoy_sway":{"up":"Envoys win {n} points more favour (25 makes a yes)","down":"Envoys lose {n} points of favour (25 makes a yes)","zero":"Envoys win as much favour as an ordinary one's","would_up":"would win {n} more","would_down":"would lose {n}","unit":" points"},
	"resistance":{"up":"Standing orders meet {n}% less resistance","down":"Standing orders meet {n}% more resistance","zero":"Standing orders meet as much resistance as under an ordinary one","would_up":"would ease it {n}%","would_down":"would stiffen it {n}%","unit":"%"},
	"devotion":{"up":"The people's love of the god +{n} points","down":"The people's love of the god -{n} points","zero":"The people's love of the god as under an ordinary one","would_up":"would raise it {n}","would_down":"would lower it {n}","unit":" points"},
	"compliance":{"up":"{n} more in 100 pay what they owe","down":"{n} fewer in 100 pay what they owe","zero":"As many pay what they owe as under an ordinary one","would_up":"would bring {n} more","would_down":"would bring {n} fewer","unit":" in 100"},
}

## How a lever's applied value shows as a size: percent off neutral for
## multipliers, points for added levers (scout cover shows the change in the
## chance a party is caught, from the base cover a party has).
static func size_of(lever_id:String,value:float)->int:
	match lever_id:
		"scout_cover": return roundi(absf(1.0-scout_risk_ratio(value))*100.0)
		"envoy_sway","devotion","compliance": return roundi(absf(value)*100.0)
	return roundi(absf(value-1.0)*100.0)

## Better for the people (or our envoys) than an ordinary holder.
static func is_better(lever_id:String,value:float)->bool:
	match lever_id:
		"spoilage","forgetting","resistance": return value<1.0
		"labour": return value>1.0
	return value>0.0

## The chance a scouting party is caught with `cover` added to its
## concealment and evasion, against the base party (civilization_system
## _scout_capture risk: (1 - concealment*0.48) * (1 - evasion*0.38) from
## concealment 0.80 and evasion 0.86).
static func scout_risk_ratio(cover:float)->float:
	var base:=(1.0-0.80*0.48)*(1.0-0.86*0.38)
	var with:=(1.0-clampf(0.80+cover,0.0,1.0)*0.48)*(1.0-clampf(0.86+cover,0.0,1.0)*0.38)
	return with/base


# --- Who holds the office ---------------------------------------------------

static func _government()->Variant:
	return WorldSimulation.government if WorldSimulation!=null else null

static func _positions()->Dictionary:
	return WorldSimulation.state.leadership_positions if WorldSimulation!=null and WorldSimulation.state!=null else {}

## Who works an office's lever now: {person, share, acting, vacant, open}.
## share is how much of the lever they carry (STAND_IN_SHARE standing in, 0
## while no such office can exist yet).
static func holder_of(office:String)->Dictionary:
	var out:={"person":{},"share":0.0,"acting":false,"vacant":false,"open":false}
	var gov:Variant=_government()
	var positions:=_positions()
	if gov==null: return out
	var stage:=int(gov.government_stage)
	var spec:Dictionary=LEVERS.get(office,{})
	if UNLOCK.has(office):
		if stage<int(UNLOCK[office]):
			if bool(spec.get("stand_in",false)):
				var steward:Dictionary=positions.get("Steward",{})
				if steward.is_empty(): return out
				out.person=steward; out.share=STAND_IN_SHARE; out.acting=true; out.open=true
			return out
		out.open=true
		var person:Dictionary=positions.get(office,{})
		if person.is_empty() or bool(person.get("acting",false)) and int(person.get("person_id",0))<=0:
			out.vacant=true; out.share=1.0
			return out
		out.person=person; out.share=1.0
		return out
	# Offices discoveries add (priests, judges, a treasury) exist only while held.
	var held:Dictionary=positions.get(office,{})
	if held.is_empty(): return out
	out.person=held; out.share=1.0; out.open=true
	return out


# --- A person's lever ---------------------------------------------------------

static func _skill(person:Dictionary,skill:String)->float:
	var skills:Dictionary=person.get("skills",{}) if person.get("skills") is Dictionary else {}
	if skills.has(skill): return clampf(float(skills[skill]),0.0,100.0)
	var gov:Variant=_government()
	if gov!=null and not person.is_empty(): return float(gov.skill_value(person,skill,ORDINARY_SKILL))
	return ORDINARY_SKILL

## The weighted skill a lever reads (0..100).
static func score(person:Dictionary,office:String)->float:
	var spec:Dictionary=LEVERS.get(office,{})
	var weights:Dictionary=spec.get("skills",{})
	if person.is_empty() or weights.is_empty(): return ORDINARY_SKILL
	var total:=0.0
	var sum:=0.0
	for skill in weights:
		total+=_skill(person,String(skill))*float(weights[skill])
		sum+=float(weights[skill])
	return total/maxf(0.001,sum)

## Where a score sits between the lever's ends: -1 worst, 0 ordinary, 1 best.
static func position(skill_score:float)->float:
	return clampf((skill_score-ORDINARY_SKILL)/SKILL_SPAN,-1.0,1.0)

## The lever at a position, before reach and stand-in.
static func at(office:String,t:float)->float:
	var spec:Dictionary=LEVERS.get(office,{})
	if spec.is_empty(): return 1.0
	var neutral:=1.0 if String(spec.kind)=="mul" else 0.0
	if t>=0.0: return neutral+t*(float(spec.best)-neutral)
	return neutral+(-t)*(float(spec.worst)-neutral)

## A person's own lever in an office: their skills, then their traits
## (TRAIT_LEVERS), before reach and stand-in.
static func person_lever(person:Dictionary,office:String)->float:
	var spec:Dictionary=LEVERS.get(office,{})
	if spec.is_empty(): return 1.0
	var raw:=at(office,position(score(person,office)))
	raw+=trait_delta(person,String(spec.id))
	return _bounded(office,raw)

## Keeps a lever within its stated ends (traits may push a holder to an end,
## never past it).
static func _bounded(office:String,raw:float)->float:
	var spec:Dictionary=LEVERS.get(office,{})
	if spec.is_empty(): return raw
	return clampf(raw,minf(float(spec.worst),float(spec.best)),maxf(float(spec.worst),float(spec.best)))

## A lever as it applies over the people: reach and the stand-in's share.
static func applied(office:String,raw:float,share:float=1.0,reach_now:float=-1.0)->float:
	var spec:Dictionary=LEVERS.get(office,{})
	if spec.is_empty(): return 1.0
	var r:=reach() if reach_now<0.0 else reach_now
	var neutral:=1.0 if String(spec.kind)=="mul" else 0.0
	return neutral+(raw-neutral)*r*clampf(share,0.0,1.0)

## The lever the engine applies now in this actor's scope: 1.0 (or 0.0 for
## an added lever) when nobody holds or stands in for the office.
static func value(office:String)->float:
	var spec:Dictionary=LEVERS.get(office,{})
	if spec.is_empty(): return 1.0
	var neutral:=1.0 if String(spec.kind)=="mul" else 0.0
	if WorldSimulation==null or WorldSimulation.state==null: return neutral
	var who:=holder_of(office)
	if float(who.share)<=0.0: return neutral
	var raw:=at(office,VACANT_SCORE) if bool(who.vacant) else person_lever(who.person,office)
	return applied(office,raw,float(who.share))


## The labour lever over the whole people: the headman's hand on the
## capital's share of the people, each town leader's own hand on their town's
## (the same lever, read from their skills: town leaders are the headmen of
## their towns), by population share. One settlement: the headman's alone.
static func labour()->float:
	var steward:=value("Steward")
	if WorldSimulation==null or WorldSimulation.state==null: return steward
	var settlements:Array=WorldSimulation.state.player_settlements
	if settlements.size()<=1: return steward
	var gov:Variant=_government()
	if gov==null: return steward
	var by_id:Dictionary={}
	for person in gov.people: by_id[int((person as Dictionary).get("person_id",0))]=person
	var r:=reach()
	var towns:=0.0
	var share_sum:=0.0
	for settlement_variant in settlements:
		var settlement:Dictionary=settlement_variant
		if bool(settlement.get("primary",false)): continue
		var share:=maxf(0.0,float(settlement.get("population_share",0.0)))
		if share<=0.0: continue
		var leader:Dictionary=by_id.get(int(settlement.get("leader_person_id",0)),{})
		var lever:=1.0
		if not leader.is_empty() and String(leader.get("status",""))=="active": lever=applied("Steward",person_lever(leader,"Steward"),1.0,r)
		else: lever=applied("Steward",at("Steward",VACANT_SCORE),1.0,r)
		towns+=share*lever
		share_sum+=share
	share_sum=minf(share_sum,0.99)
	return steward*(1.0-share_sum)+towns

## A town leader's hand on their town's work, as labour() applies it
## (1.04 = 4% more work done).
static func town_labour(person:Dictionary)->float:
	if person.is_empty(): return applied("Steward",at("Steward",VACANT_SCORE))
	return applied("Steward",person_lever(person,"Steward"))


# --- Reach ------------------------------------------------------------------

static var _reach_key:=""
static var _reach_value:=1.0

## How much of a minister's lever reaches the people (see the header).
static func reach()->float:
	if WorldSimulation==null or WorldSimulation.state==null: return 1.0
	var state=WorldSimulation.state
	var population:=float(state.population_exact)
	if population<=FULL_REACH_POPULATION: return 1.0
	var key:="%s|%d|%d|%d" % [String(WorldSimulation.actor_id),int(state.world_seed),int(state.elapsed_days),roundi(population)]
	if key==_reach_key: return _reach_value
	var stewards:=float(state.effective_workers("Administration"))
	var coverage:=clampf(stewards*(1.0+preload("res://scripts/civic_building_effects.gd").effect("admin_reach"))/maxf(1.0,population*0.035),0.0,1.25)
	var institutions:=clampf(float(state.society_capacities.get("institutions",0.0)),0.0,1.0)
	var clerks:=clampf(coverage*(0.6+0.4*institutions),MIN_REACH,1.0)
	_reach_value=lerpf(1.0,clerks,clampf((population-FULL_REACH_POPULATION)/REACH_BLEND,0.0,1.0))
	_reach_key=key
	return _reach_value

static func clear_cache()->void:
	_reach_key=""


# --- Intrigue (spies and assassins) ------------------------------------------

## The hand an office brings to covert work (covert_ops.gd), as an added
## edge 0..~0.1, read from the holder's own skills with reach, exactly as the
## listed levers are. The Pathfinder is the eyes abroad and the watch at home
## (Logistics, Knowledge, Defense); the war leader sharpens a killer's reach
## (Defense, Knowledge). No LEVERS entry: this edge has no card of its own and
## does not change the government screen; it is read straight from the holder,
## so a rival's Pathfinder runs their spies exactly as ours does.
const INTRIGUE_SKILLS:={"ChiefScout":{"Logistics":0.4,"Knowledge":0.35,"Defense":0.25},"Marshal":{"Defense":0.5,"Knowledge":0.3,"Administration":0.2}}
const INTRIGUE_BEST:=0.10

static func intrigue_edge(office:String,reach_now:float=-1.0)->float:
	var weights:Dictionary=INTRIGUE_SKILLS.get(office,{})
	if weights.is_empty() or WorldSimulation==null or WorldSimulation.state==null: return 0.0
	var who:=order_holder(office)
	var person:Dictionary=who.person if who.person is Dictionary else {}
	if person.is_empty(): return 0.0
	var total:=0.0; var sum:=0.0
	for skill in weights:
		total+=_skill(person,String(skill))*float(weights[skill]); sum+=float(weights[skill])
	var skill:=total/maxf(0.001,sum)
	# Ordinary holder (47) gives nothing; SKILL_SPAN above reaches the best edge.
	var raw:=clampf((skill-ORDINARY_SKILL)/SKILL_SPAN,-1.0,1.0)*INTRIGUE_BEST
	var r:=reach() if reach_now<0.0 else reach_now
	return clampf(raw*r*(STAND_IN_SHARE if bool(who.acting) else 1.0),-INTRIGUE_BEST,INTRIGUE_BEST)


# --- Traits with trade-offs --------------------------------------------------

## What a holder's traits add to the levers they work, in each lever's own
## units, and to the pace of the orders they carry (order_pace, as a share).
## Each trait helps one thing and costs another (docs: leadership audit 4).
const TRAIT_LEVERS:={
	"Frugal":{"spoilage":-0.08,"order_pace":-0.04},
	"Generous":{"devotion":0.02,"spoilage":0.05},
	"Cautious":{"scout_cover":0.03,"order_pace":-0.05},
	"Bold":{"scout_cover":-0.02,"order_pace":0.05},
	"Severe":{"resistance":-0.08,"devotion":-0.02,"compliance":0.02},
	"Warm":{"devotion":0.02,"resistance":0.04},
	"Methodical":{"forgetting":-0.10,"order_pace":0.04,"labour":-0.01},
	"Inventive":{"forgetting":0.08,"labour":0.01},
	"Traditional":{"forgetting":-0.12,"envoy_sway":-0.02},
	"Curious":{"forgetting":-0.06,"spoilage":0.03},
	"Diplomatic":{"envoy_sway":0.03,"resistance":0.03},
	"Skeptical":{"envoy_sway":-0.02,"spoilage":-0.03},
	"Forceful":{"order_pace":0.06,"resistance":0.06},
	"Patient":{"labour":0.01,"order_pace":-0.03},
	"Pragmatic":{"order_pace":0.03,"devotion":-0.01},
	"Principled":{"compliance":0.02,"envoy_sway":-0.01},
	"Humble":{"devotion":0.01,"order_pace":-0.02},
	"Ambitious":{},
}

static func trait_delta(person:Dictionary,lever_id:String)->float:
	var total:=0.0
	var traits:Variant=person.get("traits",[])
	if not traits is Array: return 0.0
	for t in traits:
		total+=float((TRAIT_LEVERS.get(String(t),{}) as Dictionary).get(lever_id,0.0))
	return total

## The traits that move a lever, in words: "Frugal (saves 8% more)".
static func trait_notes(person:Dictionary,lever_id:String)->Array[String]:
	var out:Array[String]=[]
	var traits:Variant=person.get("traits",[])
	if not traits is Array: return out
	for t in traits:
		var delta:=float((TRAIT_LEVERS.get(String(t),{}) as Dictionary).get(lever_id,0.0))
		if delta!=0.0: out.append(String(t))
	return out


# --- Orders by office ---------------------------------------------------------

## The ordinary holder every comparison is made against: every skill
## ORDINARY_SKILL, an even temper, a middling bond with the god.
static func ordinary_person()->Dictionary:
	var skills:={}
	for skill in ["Administration","Provisioning","Construction","Logistics","Knowledge","Defense","Diplomacy"]: skills[skill]=ORDINARY_SKILL
	return {"person_id":0,"name":"","skills":skills,"traits":[],"experience_months":0,
		"personality":{"openness":0.5,"discipline":0.5,"empathy":0.5,"assertiveness":0.5,"risk_tolerance":0.5},
		"relationships":{"sovereign":{"trust":0.5,"respect":0.5,"fear":0.0,"resentment":0.0,"obligation":0.4}}}

## The skills the orders of an office are carried out with: its two most
## weighted skills (government_people_system OFFICE_SKILL_WEIGHTS).
const ORDER_SKILLS:={"Steward":["Administration","Diplomacy"],"Quartermaster":["Provisioning","Logistics"],"Marshal":["Defense","Administration"],
	"Scholar":["Knowledge","Administration"],"Envoy":["Diplomacy","Logistics"],"ChiefScout":["Logistics","Knowledge"],
	"HighPriest":["Diplomacy","Knowledge"],"Justice":["Administration","Knowledge"],"Treasurer":["Administration","Provisioning"]}

## How much faster (or slower) the orders an office carries go under a
## person than under an ordinary holder: their execution (advisor_system:
## skills, fit, bond with the god, quiet sabotage) over the ordinary
## holder's, with reach and their traits, bounded ORDER_PACE_MIN..MAX.
static func person_order_pace(person:Dictionary,office:String,reach_now:float=-1.0)->float:
	if person.is_empty() or WorldSimulation==null or WorldSimulation.advisors==null: return 1.0
	var skills:Array=ORDER_SKILLS.get(office,["Administration"])
	var advisors:Variant=WorldSimulation.advisors
	var theirs:=float(advisors.execution_modifier_for_advisor(person,office,skills))
	var ordinary:=float(advisors.execution_modifier_for_advisor(ordinary_person(),office,skills))
	var ratio:=theirs/maxf(0.05,ordinary)+trait_delta(person,"order_pace")
	var r:=reach() if reach_now<0.0 else reach_now
	return clampf(1.0+(ratio-1.0)*r,ORDER_PACE_MIN,ORDER_PACE_MAX)

## The office that carries a stand-in office's orders (the Headman while it
## is not yet open), and that office's holder: {office, person, acting}.
static func order_holder(office:String)->Dictionary:
	var gov:Variant=_government()
	if gov==null: return {"office":office,"person":{},"acting":false}
	var executing:=String(gov.executing_office(office))
	var person:Dictionary=_positions().get(executing,{})
	if bool(person.get("acting",false)) and int(person.get("person_id",0))<=0: person={}
	return {"office":executing,"person":person,"acting":executing!=office}

## The pace of an office's orders now (1.0 with nobody to carry them).
static func order_pace(office:String)->float:
	var who:=order_holder(office)
	if (who.person as Dictionary).is_empty(): return 1.0
	return person_order_pace(who.person,String(who.office))

## Which office carries each kind of order (home_orders.gd, realm_orders.gd;
## the families of court_office_orders.gd).
const ORDER_OFFICE:={
	"arm":"Quartermaster","line":"Quartermaster","carts":"Quartermaster","repair":"Quartermaster","stop_making":"Quartermaster","ration":"Quartermaster","provisions":"Quartermaster",
	"levy":"Marshal","recruit":"Marshal","stand_down":"Marshal","deploy":"Marshal","training":"Marshal","camp_drill":"Marshal",
	"build":"Steward","defences":"Steward","found_town":"Steward","society":"Steward","work_pace":"Steward","sick_apart":"Steward","clean_water":"Steward","town_focus":"Steward",
	"scouting":"ChiefScout","scout_party":"ChiefScout",
	"research":"Scholar","inquiry":"Scholar",
	"envoy":"Envoy","declare_war":"Envoy",
}

## Workshop jobs an order put in hand go at the keeper's pace.
const WORKSHOP_KINDS:=["arm","line","carts","repair"]

## An order at home carried out (home_orders.perform): the office that
## carries it sets its pace and yield, and the report says so with the
## numbers. Workshop jobs it queued (ids from `job_from`, the workshop's next
## job id before the order) take the keeper's pace; a ration saves more (and
## harms less) under a good keeper. Returns `done` with "holder" {office,
## name, pace} and the note added to its outcome.
static func with_holder(done:Dictionary,job_from:int=-1)->Dictionary:
	if not bool(done.get("ok",false)): return done
	var kind:=String(done.get("kind",""))
	if not ORDER_OFFICE.has(kind): return done
	var office:=String(ORDER_OFFICE[kind])
	var who:=order_holder(office)
	var person:Dictionary=who.person
	if person.is_empty(): return done
	var pace:=person_order_pace(person,String(who.office))
	done["holder"]={"office":String(who.office),"for_office":office,"name":String(person.get("name","")),"person_id":int(person.get("person_id",0)),"pace":pace}
	var mc:Variant=WorldSimulation.military
	if kind in WORKSHOP_KINDS and mc!=null and job_from>=0:
		var paced:=0
		for job in mc.equipment_queue:
			if int((job as Dictionary).get("id",-1))>=job_from and _pace_job(mc,int((job as Dictionary).get("id",-1)),pace): paced+=1
		done["holder_paced_jobs"]=paced
	if kind=="ration": _pace_ration(pace)
	var note:=order_note(kind,office,who,pace,done)
	if note!="":
		done["holder_note"]=note
		done["outcome"]=(String(done.get("outcome",""))+" "+note).strip_edges()
	return done

static func _pace_job(mc:Variant,id:int,pace:float)->bool:
	if id<0 or absf(pace-1.0)<0.005: return false
	var queue:Array=mc.equipment_queue
	for index in queue.size():
		var job:Dictionary=queue[index]
		if int(job.get("id",-1))!=id or job.has("holder_pace"): continue
		job["work_per_item"]=float(job.get("work_per_item",1.0))/pace
		job["required_days"]=float(job.get("required_days",0.0))/pace
		job["holder_pace"]=pace
		queue[index]=job
		return true
	return false

## The ration a keeper sets: they find more to spare and starve fewer
## (realm_orders._set_ration's modifier).
static func _pace_ration(pace:float)->void:
	var mods:Array=WorldSimulation.state.active_modifiers
	for index in range(mods.size()-1,-1,-1):
		var mod:Variant=mods[index]
		if not mod is Dictionary or not String((mod as Dictionary).get("id","")).begins_with("court_ration") or bool((mod as Dictionary).get("holder_paced",false)): continue
		var effects:Dictionary=(mod as Dictionary).get("effects",{})
		effects["food_demand"]=float(effects.get("food_demand",0.0))*pace
		effects["health_target"]=float(effects.get("health_target",0.0))/pace
		mod["effects"]=effects
		mod["holder_paced"]=true
		mods[index]=mod
		return

## The note on an order's report: who carries it, and what their hand does to
## it against an ordinary holder, with the engine's numbers.
static func order_note(kind:String,office:String,who:Dictionary,pace:float,done:Dictionary={})->String:
	var person:Dictionary=who.person
	var given:=String(person.get("name","")).get_slice(" ",0)
	if given=="": return ""
	var title:=office_title(String(who.office)).to_lower()
	var ordinary:="an ordinary %s" % title
	var pct:=roundi(absf(pace-1.0)*100.0)
	var faster:="%d%% faster" % pct if pace>=1.0 else "%d%% slower" % pct
	if pct==0: faster="at the pace"
	var by:=" (standing in for the %s)" % office_title(office).to_lower() if bool(who.get("acting",false)) else ""
	match kind:
		"arm","line","carts","repair":
			return "%s%s has the workshops at it %s than %s would." % [given,by,faster,ordinary] if pct>0 else "%s%s has the workshops at it as %s would." % [given,by,ordinary]
		"ration":
			return "%s%s keeps the ration: %d in 100 less is eaten, against %d under %s." % [given,by,roundi(0.75*0.2*pace*100.0),roundi(0.75*0.2*100.0),ordinary]
		"provisions":
			return "%s%s sees to the stores: %s." % [given,by,_lever_sentence("Quartermaster",value("Quartermaster")).to_lower()]
		"levy","recruit","training","camp_drill":
			# Drill goes at the home commander's pace (military_campaign
			# _process_training_program_day instruction: command).
			var mc:Variant=WorldSimulation.military
			if mc==null or not mc.home_army is Dictionary: return ""
			var home:Dictionary=(mc.home_army as Dictionary).get("commander",{}) if (mc.home_army as Dictionary).get("commander") is Dictionary else {}
			if home.is_empty(): return ""
			var gain:=drill_gain(home,marshal_command(ordinary_person()))
			var size:=roundi(absf(gain)*100.0)
			if size==0: return ""
			return "Under %s the drill goes %d%% %s than under an ordinary %s." % [String(home.get("name","the war leader")).get_slice(" ",0),size,"faster" if gain>=0.0 else "slower",office_title("Marshal").to_lower()]
		"build","defences","found_town","society","work_pace","sick_apart","clean_water","town_focus":
			var labour:=value("Steward")
			var size:=roundi(absf(labour-1.0)*100.0)
			var work:="%d%% %s work gets done under them than under %s" % [size,"more" if labour>=1.0 else "less",ordinary] if size>0 else "as much work gets done as under %s" % ordinary
			return "%s%s sees to it: %s." % [given,by,work]
		"scouting","scout_party":
			var cover:=value("ChiefScout")
			var size2:=size_of("scout_cover",cover)
			if size2==0: return ""
			return "%s%s sees to the parties: they are caught %d%% %s often than under %s." % [given,by,size2,"less" if cover>=0.0 else "more",ordinary]
		"research","inquiry":
			# Each line of study goes at its leader's execution
			# (discovery_system.research_leadership, research_pace).
			var field:=String(done.get("field",""))
			if field=="" and kind=="inquiry" and WorldSimulation.discovery!=null: field=String((WorldSimulation.discovery.discovery_definition(String(done.get("id",""))) as Dictionary).get("dynamic",""))
			if field=="" or WorldSimulation.discovery==null: return ""
			var lead:Dictionary=WorldSimulation.discovery.research_leadership(field)
			var leader:Dictionary=_positions().get(String(lead.get("office","")),{})
			if leader.is_empty(): return ""
			var line_pace:=research_pace(leader,String(lead.office),lead.get("skills",[]))
			var line_pct:=roundi(absf(line_pace-1.0)*100.0)
			if line_pct==0: return ""
			return "%s leads that line of study: it goes %d%% %s than under an ordinary %s." % [String(leader.get("name","")).get_slice(" ",0),line_pct,"faster" if line_pace>=1.0 else "slower",office_title(String(lead.office)).to_lower()]
		"envoy","declare_war":
			var sway:=value("Envoy")
			var points:=size_of("envoy_sway",sway)
			if points==0: return ""
			return "%s%s carries our word: %d points %s favour than %s would win (25 makes a yes)." % [given,by,points,"more" if sway>=0.0 else "less",ordinary]
	return ""


# --- Words for the screens ----------------------------------------------------

static func office_title(office:String)->String:
	var gov:Variant=_government()
	if gov!=null and gov.has_method("office_definition"):
		var title:=String((gov.office_definition(office) as Dictionary).get("title",""))
		if title!="" and title!=office: return title
	return String({"Steward":"Headman","Quartermaster":"Keeper of Stores","Marshal":"War Leader","Scholar":"Lore Keeper","ChiefScout":"Pathfinder","Envoy":"Messenger","HighPriest":"Priest","Justice":"Arbiter","Treasurer":"Treasurer"}.get(office,office))

static func _fill(template:String,n:int)->String:
	return template.replace("{n}",str(n))

## A lever's effect in a short sentence: "Saves 12% of what would rot".
static func _lever_sentence(office:String,lever:float)->String:
	var spec:Dictionary=LEVERS.get(office,{})
	if spec.is_empty(): return ""
	var id:=String(spec.id)
	var words:Dictionary=WORDS.get(id,{})
	var n:=size_of(id,lever)
	if n==0: return String(words.get("zero",""))
	return _fill(String(words.get("up" if is_better(id,lever) else "down","")),n)

static func _would(office:String,lever:float)->String:
	var spec:Dictionary=LEVERS.get(office,{})
	var id:=String(spec.get("id",""))
	var words:Dictionary=WORDS.get(id,{})
	var n:=size_of(id,lever)
	if n==0: return "would change nothing"
	return _fill(String(words.get("would_up" if is_better(id,lever) else "would_down","")),n)

## The best estimate the court can make of a person's lever in an office,
## and how sure it is: {value, low, high, sure}. The estimate errs by a
## seeded amount that shrinks with service (experience_months) and with how
## long the court has known them; the holder's own lever is the engine's,
## exact.
static func estimate(person:Dictionary,office:String)->Dictionary:
	var spec:Dictionary=LEVERS.get(office,{})
	var truth:=person_lever(person,office)
	if spec.is_empty(): return {"value":truth,"low":truth,"high":truth,"sure":1.0}
	var months:=float(person.get("experience_months",0))
	var known_days:=0.0
	if WorldSimulation!=null and WorldSimulation.state!=null:
		known_days=maxf(0.0,float(WorldSimulation.state.elapsed_days)-float(person.get("known_since_day",WorldSimulation.state.elapsed_days)))
	var sure:=clampf(months/48.0+known_days/(365.0*8.0),0.0,1.0)
	var span:=absf(float(spec.best)-float(spec.worst))*0.35*(1.0-sure)
	var seed_value:=int(WorldSimulation.state.world_seed) if WorldSimulation!=null and WorldSimulation.state!=null else 0
	var noise:=float(posmod(hash("%d:lever_guess:%s:%d" % [seed_value,office,int(person.get("person_id",0))]),2001)-1000)/1000.0
	var guess:=_bounded(office,truth+noise*span*0.6)
	return {"value":guess,"low":_bounded(office,guess-span*0.5),"high":_bounded(office,guess+span*0.5),"sure":sure}

## The free people who could hold an office, best estimate first: those in
## no central office (and not its holder). [{person, estimate}].
static func shortlist(office:String,limit:int=3)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var gov:Variant=_government()
	if gov==null or not LEVERS.has(office): return out
	var holder_id:=int((_positions().get(office,{}) as Dictionary).get("person_id",0))
	for person_variant in gov.people:
		var person:Dictionary=person_variant
		if String(person.get("status",""))!="active" or String(person.get("office_key",""))!="": continue
		if int(person.get("person_id",0))==holder_id: continue
		out.append({"person":person,"estimate":estimate(person,office)})
	var spec:Dictionary=LEVERS[office]
	var lower_better:=String(spec.kind)=="mul" and float(spec.best)<1.0
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var av:=float(a.estimate.value); var bv:=float(b.estimate.value)
		if absf(av-bv)<0.00001: return int(a.person.get("person_id",0))<int(b.person.get("person_id",0))
		return av<bv if lower_better else av>bv)
	if out.size()>limit: out.resize(limit)
	return out

## One office's lever for the government card: {lever_id, text, tip,
## holder, ordinary, best:{name, person_id, value, low, high}}. text reads
## "Saves 12% of what would rot · an ordinary keeper of stores 0% · Iska
## would save 17%". {} for an office with no lever.
static func card(office:String)->Dictionary:
	var spec:Dictionary=LEVERS.get(office,{})
	if spec.is_empty(): return {}
	var id:=String(spec.id)
	var who:=holder_of(office)
	var lever:=value(office)
	var title:=office_title(office).to_lower()
	var parts:PackedStringArray=PackedStringArray()
	parts.append(_lever_sentence(office,lever))
	var unit:=String((WORDS.get(id,{}) as Dictionary).get("unit","%"))
	parts.append("an ordinary %s %s" % [title,"0%" if unit=="%" else "0"+unit])
	var best:Dictionary={}
	# Nobody can be named to an office not yet open: only the stand-in counts.
	var list:Array=shortlist(office,1) if not bool(who.acting) else []
	if not list.is_empty():
		var cand:Dictionary=list[0]
		var est:Dictionary=cand.estimate
		var shown:=applied(office,float(est.value))
		best={"name":String(cand.person.get("name","")),"person_id":int(cand.person.get("person_id",0)),"value":shown,"low":applied(office,float(est.low)),"high":applied(office,float(est.high)),"sure":float(est.sure)}
		parts.append("%s %s" % [String(best.name).get_slice(" ",0),_would(office,shown)])
	var r:=reach()
	var tip:="The engine applies this every day. %s" % _how_it_works(office)
	if bool(who.acting): tip+=" No %s sits yet: %s stands in and carries half of it." % [title,String((who.person as Dictionary).get("name","the headman"))]
	if r<0.995: tip+=" With %s people, our clerks carry %d in 100 of an official's hand to them." % [_count(float(WorldSimulation.state.population_exact)),roundi(r*100.0)]
	if not best.is_empty() and float(best.sure)<0.95:
		tip+=" %s is a guess from their record: somewhere between %s." % [String(best.name).get_slice(" ",0),_range_words(office,float(best.low),float(best.high))]
	var notes:=trait_notes(who.person,id) if not (who.person as Dictionary).is_empty() else []
	if not notes.is_empty(): tip+=" Their nature counts too: %s." % ", ".join(PackedStringArray(notes)).to_lower()
	return {"lever_id":id,"text":" · ".join(parts),"tip":tip,"holder":lever,"ordinary":applied(office,at(office,0.0)),"best":best,"acting":bool(who.acting),"vacant":bool(who.vacant)}

## Two ends of a guess, the smaller first: "+14% and +20%".
static func _range_words(office:String,a:float,b:float)->String:
	var id:=String((LEVERS.get(office,{}) as Dictionary).get("id",""))
	var sa:=float(size_of(id,a))*(1.0 if is_better(id,a) else -1.0)
	var sb:=float(size_of(id,b))*(1.0 if is_better(id,b) else -1.0)
	return "%s and %s" % [_range_word(office,a),_range_word(office,b)] if sa<=sb else "%s and %s" % [_range_word(office,b),_range_word(office,a)]

static func _range_word(office:String,lever:float)->String:
	var id:=String((LEVERS.get(office,{}) as Dictionary).get("id",""))
	var n:=size_of(id,lever)
	if n==0: return "no change"
	var unit:=String((WORDS.get(id,{}) as Dictionary).get("unit","%"))
	return "%s%d%s" % ["+" if is_better(id,lever) else "-",n,unit]

static func _count(n:float)->String:
	if n>=1_000_000_000.0: return "%.1f billion" % (n/1_000_000_000.0)
	if n>=1_000_000.0: return "%.1f million" % (n/1_000_000.0)
	if n>=10_000.0: return "%d thousand" % roundi(n/1000.0)
	return str(roundi(n))

static func _how_it_works(office:String)->String:
	match office:
		"Steward": return "How much work every hand gets done, from food to building (labour efficiency x0.95 to x1.06)."
		"Quartermaster": return "How much of the stored and fresh food rots each day (spoilage x1.15 to x0.80)."
		"Scholar": return "How fast ways nobody practises are forgotten (x1.20 to x0.60)."
		"ChiefScout": return "Scouting parties' concealment and evasion (-0.02 to +0.08), so fewer are caught."
		"Envoy": return "The favour our proposals win with another ruler (-5 to +10 points; 25 makes a yes)."
		"Justice": return "The resistance standing orders meet (x1.15 to x0.75), and so the unrest they stir."
		"HighPriest": return "The people's love of the god (-2 to +6 points)."
		"Treasurer": return "How many of those who owe dues pay them (-4 to +6 in 100)."
	return ""

## The work line for an official's card: how much better (or worse) their
## orders and their lines of study go than an ordinary holder's.
static func work_line(office:String,person:Dictionary)->String:
	if person.is_empty() or office=="" or office=="settlement": return ""
	var pace:=person_order_pace(person,office)
	var pct:=roundi(absf(pace-1.0)*100.0)
	if pct==0: return "Their orders and studies go as an ordinary holder's would"
	return "Their orders and studies go %d%% %s than an ordinary holder's" % [pct,"faster" if pace>=1.0 else "slower"]


# --- The war leader at home -------------------------------------------------

## How much of the war leader's command is their own (the rest is what the
## realm's watch and supply lend any war leader).
const MARSHAL_OWN:=0.80

## The home commander a person makes as war leader
## (military_campaign._marshal_commander reads it here): their own skills,
## as every official has them, so a war leader's strength and weakness show:
## command from Defense, Administration and Knowledge; tactics from Defense
## and Knowledge; logistics from Logistics and Provisioning; resolve from
## their courage, Defense and Administration. {command, tactics, logistics,
## resolve}, 0..1.
static func marshal_command(person:Dictionary)->Dictionary:
	if WorldSimulation==null or WorldSimulation.state==null or person.is_empty(): return {"command":0.5,"tactics":0.5,"logistics":0.5,"resolve":0.5}
	var state=WorldSimulation.state
	var security:=clampf(float(state.society_capacities.get("security",0.38)),0.0,1.0)
	var supply:=clampf(float(state.society_capacities.get("logistics",0.16)),0.0,1.0)
	var defense:=_skill(person,"Defense")/100.0
	var administration:=_skill(person,"Administration")/100.0
	var knowledge:=_skill(person,"Knowledge")/100.0
	var courage:=clampf(float(person.get("courage",0.5)),0.0,1.0)
	var own:={"command":0.60*defense+0.25*administration+0.15*knowledge,"tactics":0.55*defense+0.45*knowledge,
		"logistics":0.65*_skill(person,"Logistics")/100.0+0.35*_skill(person,"Provisioning")/100.0,"resolve":0.50*courage+0.30*defense+0.20*administration}
	return {"command":clampf(float(own.command)*MARSHAL_OWN+security*(1.0-MARSHAL_OWN),0.0,1.0),"tactics":clampf(float(own.tactics)*MARSHAL_OWN+security*(1.0-MARSHAL_OWN),0.0,1.0),
		"logistics":clampf(float(own.logistics)*MARSHAL_OWN+supply*(1.0-MARSHAL_OWN),0.0,1.0),"resolve":clampf(float(own.resolve)*MARSHAL_OWN+security*(1.0-MARSHAL_OWN),0.0,1.0)}

## How much harder the home band fights under a commander than under
## another (combat_simulator.command_factor, for a band of `men`), as a
## share: 0.04 = 4% harder.
static func fight_gain(command:Dictionary,against:Dictionary,men:float=0.0)->float:
	var cs:=preload("res://scripts/combat_simulator.gd")
	return cs.command_factor(float(command.get("command",0.5)),men)/maxf(0.01,cs.command_factor(float(against.get("command",0.5)),men))-1.0

## How much faster drill goes under a commander than under another
## (military_campaign._process_training_program_day's instruction).
static func drill_gain(command:Dictionary,against:Dictionary)->float:
	var security:=float(WorldSimulation.state.society_capacities.get("security",0.38))
	var base:=0.48+security*0.20
	return (base+float(command.get("command",0.5))*0.22)/maxf(0.01,base+float(against.get("command",0.5))*0.22)-1.0

## The war leader's card: how the home band fights and drills under them,
## against an ordinary war leader and the best free candidate.
static func marshal_card()->Dictionary:
	var positions:=_positions()
	var holder:Dictionary=positions.get("Marshal",{})
	var title:=office_title("Marshal").to_lower()
	if holder.is_empty() or (bool(holder.get("acting",false)) and int(holder.get("person_id",0))<=0): return {}
	var ordinary:=marshal_command(ordinary_person())
	var theirs:=marshal_command(holder)
	var men:=float((WorldSimulation.military.home_army as Dictionary).get("troops",0)) if WorldSimulation.military!=null and WorldSimulation.military.home_army is Dictionary else 0.0
	var fight:=fight_gain(theirs,ordinary,men)
	var drill:=drill_gain(theirs,ordinary)
	var parts:PackedStringArray=PackedStringArray()
	parts.append("The home band fights %d%% %s and drills %d%% %s" % [roundi(absf(fight)*100.0),"harder" if fight>=0.0 else "softer",roundi(absf(drill)*100.0),"faster" if drill>=0.0 else "slower"])
	parts.append("an ordinary %s 0%%" % title)
	var best:Dictionary={}
	var top:=-INF
	var gov:Variant=_government()
	if gov!=null:
		for person_variant in gov.people:
			var person:Dictionary=person_variant
			if String(person.get("status",""))!="active" or String(person.get("office_key",""))!="" or int(person.get("person_id",0))==int(holder.get("person_id",0)): continue
			var gain:=fight_gain(marshal_command(person),ordinary,men)
			if gain>top: top=gain; best=person
	if not best.is_empty():
		parts.append("%s would make it %d%% %s" % [String(best.get("name","")).get_slice(" ",0),roundi(absf(top)*100.0),"harder" if top>=0.0 else "softer"])
	return {"lever_id":"home_command","text":" · ".join(parts),"tip":"How hard the band at home fights (battle power x0.85 to x1.15 by command) and how fast its drill goes. Bands under a named general take that general's skills instead.","holder":fight,"ordinary":0.0,"best":{"name":String(best.get("name","")),"person_id":int(best.get("person_id",0)),"value":top} if not best.is_empty() else {}}

## How much faster a line of study goes under a person than under an
## ordinary holder of its office (advisor_system execution, as
## discovery_system._leader_factor applies it; no reach there).
static func research_pace(person:Dictionary,office:String,skills:Array)->float:
	if WorldSimulation==null or WorldSimulation.advisors==null: return 1.0
	var advisors:Variant=WorldSimulation.advisors
	var ordinary:=float(advisors.execution_modifier_for_advisor(ordinary_person(),office,skills))
	var theirs:=float(advisors.execution_modifier_for_advisor(person,office,skills)) if not person.is_empty() else float(advisors.execution_modifier_for_advisor({},office,skills))
	return theirs/maxf(0.05,ordinary)


## What a change of hands does, said when the god appoints someone:
## "Iska's hand as keeper of stores: saves 17% of what would rot (Ama's:
## saves 12%)." The war leader's in how the home band fights. "" without a
## lever.
static func appointment_note(office:String,person:Dictionary,former:Dictionary)->String:
	if person.is_empty(): return ""
	var title:=office_title(office).to_lower()
	var given:=String(person.get("name","")).get_slice(" ",0)
	var before:=String(former.get("name","")).get_slice(" ",0) if not former.is_empty() and int(former.get("person_id",0))!=int(person.get("person_id",0)) else ""
	if office=="Marshal":
		var ordinary:=marshal_command(ordinary_person())
		var men:=float((WorldSimulation.military.home_army as Dictionary).get("troops",0)) if WorldSimulation.military!=null and WorldSimulation.military.home_army is Dictionary else 0.0
		var theirs:=fight_gain(marshal_command(person),ordinary,men)
		var line:="%s's hand as %s: the home band fights %d%% %s than under an ordinary one" % [given,title,roundi(absf(theirs)*100.0),"harder" if theirs>=0.0 else "softer"]
		if before!="":
			var was:=fight_gain(marshal_command(former),ordinary,men)
			line+=" (%s's: %d%% %s)" % [before,roundi(absf(was)*100.0),"harder" if was>=0.0 else "softer"]
		return line+"."
	if not LEVERS.has(office): return ""
	var lever:=applied(office,person_lever(person,office))
	var note:="%s's hand as %s: %s" % [given,title,_lever_sentence(office,lever).to_lower()]
	if before!="": note+=" (%s's: %s)" % [before,_lever_sentence(office,applied(office,person_lever(former,office))).to_lower()]
	return note+"."

## One candidate's hand against the dead (or outgoing) holder's, for the
## mourning's choice: "would save 15% of what would rot, a guess between +10%
## and +20% (Ada saved: saves 12% of what would rot)". For a town, the
## town's work; for the war leader, how the home band fights.
static func compare_line(office:String,candidate:Dictionary,dead:Dictionary)->String:
	if candidate.is_empty(): return ""
	var dead_given:=String(dead.get("name","")).get_slice(" ",0)
	if office in ["settlement","SettlementLeader"]:
		var c:=town_labour(candidate)
		var line:="their town's work %+d%%" % roundi((c-1.0)*100.0)
		if not dead.is_empty(): line+=" (%s's: %+d%%)" % [dead_given,roundi((town_labour(dead)-1.0)*100.0)]
		return line
	if office=="Marshal":
		var ordinary:=marshal_command(ordinary_person())
		var gain:=fight_gain(marshal_command(candidate),ordinary)
		var line2:="the home band would fight %d%% %s" % [roundi(absf(gain)*100.0),"harder" if gain>=0.0 else "softer"]
		if not dead.is_empty():
			var was:=fight_gain(marshal_command(dead),ordinary)
			line2+=" (%s's: %d%% %s)" % [dead_given,roundi(absf(was)*100.0),"harder" if was>=0.0 else "softer"]
		return line2
	if not LEVERS.has(office): return ""
	var est:=estimate(candidate,office)
	var guess:=applied(office,float(est.value))
	var line3:=_would(office,guess)
	if float(est.sure)<0.9: line3+=", a guess between %s" % _range_words(office,applied(office,float(est.low)),applied(office,float(est.high)))
	if not dead.is_empty(): line3+=" (%s's: %s)" % [dead_given,_lever_sentence(office,applied(office,person_lever(dead,office))).to_lower()]
	return line3

## The shortlist for an office's card: up to `limit` free people, best
## judged first, each {person_id, name, text, tip}: "Iska would save 15%"
## with the guess's range in the tip, which narrows as they serve and as the
## court comes to know them.
static func shortlist_rows(office:String,limit:int=3)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	if office=="Marshal":
		var gov:Variant=_government()
		if gov==null: return out
		var ordinary:=marshal_command(ordinary_person())
		for row:Dictionary in gov.shortlist("Marshal",limit):
			var person:Dictionary=gov.person_snapshot(int(row.person_id))
			if person.is_empty(): continue
			var gain:=fight_gain(marshal_command(person),ordinary)
			var spread:=0.06*(1.0-float(row.get("sure",0.0)))
			var guess:=gain+(float(row.get("fit",0.5))-float(gov.office_competency(person,"Marshal")))*0.3
			out.append({"person_id":int(row.person_id),"name":String(row.name),"text":"%s: the home band %+d%%" % [String(row.name).get_slice(" ",0),roundi(guess*100.0)],
				"tip":"A guess from their record: the home band would fight between %+d%% and %+d%% under them. Summon them to the court and say \"make %s our %s\" to appoint them." % [roundi((guess-spread)*100.0),roundi((guess+spread)*100.0),String(row.name).get_slice(" ",0),office_title(office).to_lower()]})
		return out
	if not LEVERS.has(office) or bool(holder_of(office).acting): return out
	for cand:Dictionary in shortlist(office,limit):
		var person:Dictionary=cand.person
		var est:Dictionary=cand.estimate
		var guess:=applied(office,float(est.value))
		var given:=String(person.get("name","")).get_slice(" ",0)
		var tip:="%s %s." % [given,_would(office,guess)]
		if float(est.sure)<0.9: tip+=" A guess from their record: between %s; the longer they serve, the surer it gets." % _range_words(office,applied(office,float(est.low)),applied(office,float(est.high)))
		tip+=" Summon them to the court and say \"make %s our %s\" to appoint them." % [given,office_title(office).to_lower()]
		out.append({"person_id":int(person.get("person_id",0)),"name":String(person.get("name","")),"text":"%s %s" % [given,_would(office,guess)],"tip":tip})
	return out
