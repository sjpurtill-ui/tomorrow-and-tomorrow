extends Node

# Exceptional figures only. The population remains numerical cohorts.
const NAMES=preload("res://scripts/historical_name_generator.gd")
## Gifted children born among the people (geniuses.gd): their births, notice,
## coming of age and the effect they have while they live.
const GENIUSES=preload("res://scripts/geniuses.gd")
## Ordinary figures alive at once; gifted ones (geniuses.gd) have their own cap.
const MAX_LIVING:=12
const MAX_RECORDS:=512
const ROLES:={"General":"security","Admiral":"security","Air Commander":"security","Scholar":"knowledge","Physician":"health","Engineer":"infrastructure","Agronomist":"nutrition","Organizer":"institutions","Artist":"culture","Explorer":"logistics","Architect":"monuments","Quarrier":"production","Maker":"production","Carrier":"logistics"}
const CALLINGS:={"General":"training formations and keeping troops together","Admiral":"keeping ships at sea and crews fit to fight","Air Commander":"training aircrews and keeping aircraft flying","Scholar":"testing explanations and teaching apprentices","Physician":"comparing treatments and training healers","Engineer":"improving structures and teaching builders","Agronomist":"comparing harvests and preserving practical knowledge","Organizer":"improving public administration and teaching officials","Artist":"developing a shared artistic tradition","Explorer":"recording routes and teaching navigators","Architect":"designing great works and training master builders","Quarrier":"finding the good stone, timber and ore and teaching cutters and diggers","Maker":"making better things from what is cut and carried, and teaching makers","Carrier":"getting loads where they are needed before they spoil, and teaching carriers"}
## Callings only a gifted child grows into (geniuses.gd): never emerging on
## their own, like the commissioned roles.
const BORN_ROLES:=["Quarrier","Maker","Carrier"]
const UPBRINGINGS:=["a household of craftspeople, where mistakes had immediate costs","a farming family that kept careful accounts of good and bad years","a family of traveling traders, learning to listen before bargaining","a crowded household where sharing work mattered more than rank","a settlement on a trade route, surrounded by unfamiliar languages","a family of practical teachers who expected every claim to be demonstrated"]
const TURNING_POINTS:={"General":["Watching a poorly organized withdrawal convinced them that preparation saves lives.","An early dispute with a superior left them determined to earn loyalty rather than assume it."],"Admiral":["A ship lost on a lee shore through a captain's pride taught them to respect weather over courage.","Years as a junior officer on a crowded deck taught them that a crew fights as well as it is fed."],"Air Commander":["Watching crews fly into weather they had been told to ignore taught them to trust their airmen's judgment.","An early crash in training convinced them that careful maintenance saves more lives than bravery."],"Scholar":["Two teachers offered incompatible explanations of the same observation; they began keeping their own records.","A failed demonstration taught them to separate a pleasing explanation from a dependable one."],"Physician":["Conflicting advice during a household illness led them to compare treatments methodically.","They began by assisting an experienced healer and questioning which routines actually helped."],"Engineer":["Repeated repairs to the same structure led them to ask why it kept failing.","Their apprenticeship taught them that an elegant design is useless if nobody can maintain it."],"Agronomist":["Different harvests on neighboring plots inspired a habit of careful comparison.","A poor growing season made the preservation of practical knowledge a personal concern."],"Organizer":["A dispute over shared stores showed them how weak records can turn neighbors against one another.","They learned administration by reconciling promises with the work a community could actually perform."],"Artist":["The same story told differently by neighboring communities became a lasting source of fascination.","An exacting teacher demanded imitation; they became more interested in finding a voice of their own."],"Explorer":["An unreliable route description convinced them that knowledge must be usable by the next traveler.","Early journeys taught them to value local knowledge over confident guesses."],"Architect":["A collapsed granary roof taught them that ambition without measurement kills.","They carried stone for a master builder who never explained anything, and swore to teach differently."],"Quarrier":["A wall of stone that split along the wrong line taught them to read the grain before striking.","They watched diggers open the same poor pit year after year and went looking for a better one."],"Maker":["A tool that broke in a careless hand taught them that a thing is only as good as its weakest part.","They sat beside an old maker who never wasted a scrap, and learned to see the thing inside the stuff."],"Carrier":["A load of food spoiled on a slow road while people went hungry at its end.","They learned every path and ford by carrying for others, and how much a back can bear."]}
const TEMPERAMENTS:=["patient and exacting","bold and impatient","generous but proud","skeptical and persistent","eloquent but restless","quiet and uncompromising","inventive and stubborn","disciplined but suspicious"]
const MOTIVES:=["make useful knowledge available beyond a privileged few","prove that inherited methods can be improved","protect communities from the failures witnessed in youth","build a tradition that can survive its founder","earn recognition through work that others can verify","train successors capable of questioning their teacher"]
## Roles that appear only when a society commissions them (never by emergence).
const COMMISSIONED_ROLES:=["Architect","Admiral","Air Commander"]
## Living admirals or air commanders at most; more forces share them.
const BRANCH_COMMANDERS:=2
## A commander's own skills (0..1): command (battle power), tactics (the plans
## they can use, withdrawals), logistics (march pace, hunger in the field) and
## resolve (holding men together: desertion). Drawn once per figure from its
## own seed (never from the figure's creation draws, so older worlds keep
## their figures), each within SKILL_MIN..SKILL_MAX with one clear strength
## and one weakness, and grown by battles and days in the field.
const COMMAND_ROLES:=["General","Admiral","Air Commander"]
const COMMAND_SKILLS:=["command","tactics","logistics","resolve"]
const SKILL_MIN:=0.25
const SKILL_MAX:=0.85
## Growth: each battle fought, and each GROWTH_FIELD_DAYS in the field, up to
## GROWTH_CAP; old age (past AGE_DECLINE years) takes it back a little a year.
const GROWTH_PER_BATTLE:=0.015
const GROWTH_FIELD_DAYS:=90
const GROWTH_PER_SEASON:=0.01
const GROWTH_CAP:=0.92
const AGE_DECLINE:=62
## How much of a commander's skill is their own, and how much the realm's
## army as a whole lends them (its drill, doctrine, staff).
const OWN_WEIGHT:=0.75
## The record a general keeps (all counts): men lost and theirs, the march,
## hunger and desertion under them, and how they grew.
const RECORD_KEYS:=["men_lost","enemy_lost","march_km","march_days","hungry_days","deserted","field_days","grown_battles","grown_seasons","aged_years"]
## What a commander's temperament does to their skills, each a trade-off:
## the label stays hidden (docs/GENERAL_CAMPAIGN_DESIGN.md); the player sees
## only the numbers it moves.
const TEMPERAMENT_SKILLS:={
	"patient and exacting":{"logistics":0.05,"command":-0.03},
	"bold and impatient":{"command":0.05,"logistics":-0.05},
	"generous but proud":{"resolve":0.04,"tactics":-0.03},
	"skeptical and persistent":{"tactics":0.03,"logistics":0.02,"command":-0.04},
	"eloquent but restless":{"resolve":0.05,"logistics":-0.04},
	"quiet and uncompromising":{"command":0.03,"resolve":0.02,"tactics":-0.04},
	"inventive and stubborn":{"tactics":0.05,"resolve":-0.04},
	"disciplined but suspicious":{"resolve":0.05,"tactics":-0.03},
}
var people:Array[Dictionary]=[]
var used:Dictionary={}
var assignments:Dictionary={}
var seed_value:=0
var initialized:=false
var serial:=0
var last_day:=0
var last_emergence:=0
var panel:Control
var layer:CanvasLayer
## Gifted children and the gifted grown (geniuses.gd): the children as their
## own records, the grown as an index to their figure in `people`.
var geniuses:Array[Dictionary]=[]
## Each work's share more that its gifted add today (geniuses.gd refresh):
## {role: 0..0.40}, read by GameState.effective_workers.
var genius_bonus:Dictionary={}
var genius_serial:=0
## The day the gifted births were last counted (-1: not yet, as in an older
## save: counting starts on its first day, so nobody is born retroactively),
## and the people's births then.
var genius_since:=-1
var genius_births_seen:=0
## How many were born, noticed, missed (grew up ordinary), lost as children
## and grown: the engine's own tally, for tests and tuning.
var genius_tally:Dictionary={}

func ensure()->void:
	if initialized and seed_value==WorldSimulation.state.world_seed: return
	reset_for_new_world()
	initialized=true; seed_value=WorldSimulation.state.world_seed; last_day=int(WorldSimulation.state.elapsed_days); last_emergence=last_day
	for role in ROLES:
		if role not in COMMISSIONED_ROLES and role not in BORN_ROLES: _create(String(role),last_day)

func reset_for_new_world()->void:
	people.clear(); used.clear(); assignments.clear(); serial=0; initialized=false; last_day=0; last_emergence=0; _ids.map={}
	geniuses.clear(); genius_bonus={}; genius_serial=0; genius_since=-1; genius_births_seen=0; genius_tally={}
	if is_instance_valid(panel): panel.queue_free()

## A figure's name: the one place every figure's name comes from, the realm's
## own names for its era (era_names.gd), else the old traditions. `key` seeds
## the draw; `hint` is era_names' ({skill}). Another builder is giving each
## people its own language: re-point this and every figure follows.
func name_identity(key:int,woman:bool,tradition:String,hint:Dictionary={})->Dictionary:
	var owner:=String(WorldSimulation.actor_id) if String(WorldSimulation.actor_id)!="" else "player"
	var taken:Dictionary=preload("res://scripts/era_names.gd").used_in_court() if owner=="player" else {}
	for known in used: taken[known]=true
	var made:Dictionary=preload("res://scripts/era_names.gd").make(seed_value,key,woman,owner,taken,hint)
	if String(made.get("name",""))=="" or used.has(String(made.get("name",""))): made=NAMES.make(seed_value,key,woman,tradition,used)
	return made

func _create(role:String,day:int)->Dictionary:
	if people.size()>=MAX_RECORDS or living_count()>=MAX_LIVING: return {}
	var rng:=RandomNumberGenerator.new(); rng.seed=hash("%d:figure:%d" % [seed_value,serial])
	var traditions:Array=NAMES.POOLS.keys()
	var tradition:=String(traditions[posmod(seed_value+serial/8,traditions.size())])
	# The realm's own great figures carry the realm's names for its era.
	var identity:Dictionary=name_identity(serial,serial%2==0,tradition)
	serial+=1
	if identity.is_empty(): return {}
	used[identity.name]=true
	var age:=rng.randi_range(24,42)
	var p:Dictionary={"id":"figure_%d_%d" % [seed_value,serial],"name":identity.name,"tradition":tradition,"gender":"woman" if (serial-1)%2==0 else "man","role":role,"domain":ROLES[role],"born":day-age*365,"emerged":day,"death_day":-1,"natural_death":day+(rng.randi_range(58,86)-age)*365,"status":"living","talent":rng.randf_range(.65,.98),"temperament":TEMPERAMENTS[rng.randi_range(0,TEMPERAMENTS.size()-1)],"motive":MOTIVES[rng.randi_range(0,MOTIVES.size()-1)],"origin":NAMES.ORIGINS[rng.randi_range(0,NAMES.ORIGINS.size()-1)],"upbringing":UPBRINGINGS[rng.randi_range(0,UPBRINGINGS.size()-1)],"turning_point":TURNING_POINTS[role][rng.randi_range(0,1)],"supported":false,"work_days":0,"renown":0,"legacy":0.0,"events":[],"battle_keys":[],"recover_day":-1}
	people.append(p)
	_ids.map={}
	skills_of(p)
	_event(p,day,"Entered public life as a %s." % role.to_lower())
	return p

## Ordinary figures alive (the gifted grown have their own cap, geniuses.gd).
func living_count()->int:
	var count:=0
	for p in people:
		if p.status!="dead" and not p.has("genius"): count+=1
	return count

## An id index over the roster, held in an object so the save's reflection
## of this node's variables never carries it (save_system._capture_reflected
## skips objects); it is rebuilt from the roster whenever it misses.
class IdIndex:
	var map:Dictionary={}
var _ids:=IdIndex.new()

func by_id(id:String)->Dictionary:
	# Read many times a day (each band's general, each day).
	var at:Variant=_ids.map.get(id)
	if at!=null and int(at)<people.size() and String(people[int(at)].id)==id: return people[int(at)]
	_ids.map={}
	for i in people.size(): _ids.map[String(people[i].id)]=i
	at=_ids.map.get(id)
	return people[int(at)] if at!=null else {}

## A commander figure's own skills, drawn on first need from the figure's own
## seed (see COMMAND_SKILLS); {} for figures who command nothing.
func skills_of(p:Dictionary)->Dictionary:
	if p.is_empty() or not String(p.get("role","")) in COMMAND_ROLES: return {}
	# A record begins now: age's toll counts from today, never backwards.
	if not p.get("record") is Dictionary: p["record"]={"aged_years":float(maxi(0,(int(WorldSimulation.state.elapsed_days)-int(p.get("born",0)))/365-AGE_DECLINE))}
	if p.get("skills") is Dictionary and (p.skills as Dictionary).size()==COMMAND_SKILLS.size(): return p.skills
	var rng:=RandomNumberGenerator.new(); rng.seed=hash("%d:figure_skills:%s" % [seed_value,String(p.get("id",""))])
	var mean:=0.40+(clampf(float(p.get("talent",0.8)),0.65,0.98)-0.65)*0.6
	var skills:={}
	for key in COMMAND_SKILLS: skills[key]=clampf(rng.randfn(mean,0.10),SKILL_MIN,SKILL_MAX)
	var strong:=rng.randi_range(0,COMMAND_SKILLS.size()-1)
	var weak:=posmod(strong+1+rng.randi_range(0,COMMAND_SKILLS.size()-2),COMMAND_SKILLS.size())
	skills[COMMAND_SKILLS[strong]]=rng.randf_range(0.66,SKILL_MAX)
	skills[COMMAND_SKILLS[weak]]=rng.randf_range(SKILL_MIN,0.38)
	var shaped:Dictionary=TEMPERAMENT_SKILLS.get(String(p.get("temperament","")),{})
	for key in shaped: skills[key]=clampf(float(skills[key])+float(shaped[key]),SKILL_MIN,SKILL_MAX)
	p["skills"]=skills
	return skills

## One of a commander's skills as the bands under them get it: their own,
## with what the realm's army lends (`base`, the acting staff's), patronage
## and the realm's renowned soldiers.
func general_skill(p:Dictionary,skill:String,base:Dictionary)->float:
	var own:=float(skills_of(p).get(skill,float(p.get("talent",.8))*0.6))
	# A war leader of rare gift (geniuses.gd) leads above their own drawn skill.
	return clampf(own*OWN_WEIGHT+float(base.get(skill,.5))*(1.0-OWN_WEIGHT)+living_bonus(p)*.2+(multiplier("security")-1.0)*.1+GENIUSES.command_bonus(p),0,1)

## Adds to a general's record (RECORD_KEYS).
func note_record(id:String,key:String,amount:float)->void:
	if amount==0.0 or not key in RECORD_KEYS: return
	var p:=by_id(id)
	if p.is_empty(): return
	if not p.get("record") is Dictionary: p["record"]={}
	var record:Dictionary=p.record
	record[key]=float(record.get(key,0.0))+amount

## A day in the field for the general of a band (field_sustainment.gd): the
## days, the march and its pace, hunger; a season in the field grows them.
func note_field_day(id:String,span:float,marching:bool,km_day:float,hungry:bool)->void:
	var p:=by_id(id)
	if p.is_empty() or String(p.get("status",""))=="dead": return
	if not p.get("record") is Dictionary: p["record"]={}
	var record:Dictionary=p.record
	var before:=int(float(record.get("field_days",0.0)))/GROWTH_FIELD_DAYS
	record["field_days"]=float(record.get("field_days",0.0))+span
	if marching and km_day>0.0:
		record["march_days"]=float(record.get("march_days",0.0))+span
		record["march_km"]=float(record.get("march_km",0.0))+km_day*span
	if hungry: record["hungry_days"]=float(record.get("hungry_days",0.0))+span
	var seasons:=int(float(record.field_days))/GROWTH_FIELD_DAYS-before
	if seasons>0: _grow(p,["logistics","resolve"],GROWTH_PER_SEASON*seasons,"grown_seasons",seasons)

func _grow(p:Dictionary,keys:Array,amount:float,record_key:String,count:int)->void:
	var skills:=skills_of(p)
	if skills.is_empty(): return
	for key in keys:
		var was:=float(skills.get(key,0.5))
		skills[key]=maxf(was,minf(GROWTH_CAP,was+amount))
	var record:Dictionary=p.record
	record[record_key]=float(record.get(record_key,0.0))+count

## Old age takes a little back each year past AGE_DECLINE (advance()).
func _age(p:Dictionary,day:int)->void:
	var skills:=skills_of(p)
	if skills.is_empty(): return
	var years:=(day-int(p.born))/365-AGE_DECLINE
	var record:Dictionary=p.record
	var done:=int(float(record.get("aged_years",0.0)))
	if years<=done: return
	for key in COMMAND_SKILLS: skills[key]=maxf(SKILL_MIN*0.8,float(skills[key])-0.01*(years-done))
	record["aged_years"]=float(years)

func _event(p:Dictionary,day:int,text:String)->void:
	p.events.append({"day":day,"text":text})
	if p.events.size()>12: p.events.pop_front()

func advance(day:int)->void:
	ensure()
	if day<=last_day: return
	for p in people:
		if p.status=="dead": continue
		var end:=mini(day,int(p.natural_death))
		var available_start:=maxi(last_day,int(p.emerged))
		if p.status=="wounded": available_start=maxi(available_start,int(p.recover_day))
		if p.status=="wounded" and day>=int(p.recover_day):
			p.status="living"; _event(p,int(p.recover_day),"Recovered from battle wounds and returned to work.")
		if p.status=="living" and p.supported:
			var start:=available_start
			var before:=int(p.work_days)/365
			p.work_days+=maxi(0,end-start)
			var years:=int(p.work_days)/365-before
			if years>0:
				p.renown+=years*2
				_event(p,end,"Completed %d additional years of supported work: %s." % [years,CALLINGS[p.role]])
		if String(p.role) in COMMAND_ROLES: _age(p,end)
		if day>=int(p.natural_death): record_death(String(p.id),int(p.natural_death),"old age")
	last_day=day
	if day-last_emergence>=365*5:
		last_emergence=day
		var counts:Dictionary={}
		for role in ROLES:
			if role not in COMMISSIONED_ROLES and role not in BORN_ROLES: counts[role]=0
		for p in people:
			if p.status!="dead" and counts.has(p.role) and not p.has("genius"): counts[p.role]+=1
		var chosen:="General"
		for role in counts:
			if counts[role]<counts[chosen]: chosen=role
		_create(chosen,day)
	# Gifted children: born, noticed, grown, lost; and what the grown add.
	GENIUSES.advance(self,day)

func support(id:String)->Dictionary:
	ensure()
	var p:=by_id(id)
	if p.is_empty() or (p.status!="living" and not p.supported): return {"error":"Only living, available figures can receive patronage."}
	var count:=0
	for other in people:
		if other.supported and other.status!="dead": count+=1
	if not p.supported and count>=3: return {"error":"Three patronage places are filled. Withdraw support from someone first."}
	p.supported=not p.supported
	_event(p,int(WorldSimulation.state.elapsed_days),"Received public patronage." if p.supported else "Public patronage ended.")
	return {"ok":true}

func living_bonus(p:Dictionary)->float:
	return (.12+float(p.talent)*.18) if p.status=="living" and p.supported else 0.0

func multiplier(domain:String)->float:
	ensure()
	var living:=0.0; var legacy:=0.0
	for p in people:
		if p.domain!=domain: continue
		living+=living_bonus(p)
		if p.status=="dead": legacy+=float(p.legacy)
	return 1.0+minf(.4,living)+minf(.2,legacy)

func record_discovery(domain:String,title:String,day:int)->void:
	ensure()
	var best:Dictionary={}
	for p in people:
		if p.domain==domain and living_bonus(p)>0 and (best.is_empty() or float(p.talent)>float(best.talent)): best=p
	if best.is_empty(): return
	best.renown+=8
	_event(best,day,"Helped the community develop %s; the discovery belongs to its collective work." % title)

## A master builder for a Great Work. Reuses a living, unassigned architect when
## one exists; otherwise a new one enters public life. Falls back to a living
## Engineer when the roster of living figures is full. Returns {} if nobody can.
func commission_architect(day:int,slot:String)->Dictionary:
	ensure()
	var p:=by_id(String(assignments.get(slot,"")))
	if not p.is_empty() and p.status=="living": return p
	# A master builder of rare gift (geniuses.gd) is asked first.
	p=_free_gifted("Architect")
	if p.is_empty():
		for candidate in people:
			if candidate.role=="Architect" and candidate.status=="living" and not candidate.id in assignments.values(): p=candidate; break
	if p.is_empty(): p=_create("Architect",day)
	if p.is_empty():
		for candidate in people:
			if candidate.role=="Engineer" and candidate.status=="living" and not candidate.id in assignments.values(): p=candidate; break
	if p.is_empty(): return {}
	assignments[slot]=p.id
	if p.get("genius") is Dictionary: (p.genius as Dictionary)["led"]=day
	_event(p,day,"Commissioned as master builder of a great work.")
	return p

## A living, unassigned grown genius of this calling, or {}.
func _free_gifted(role:String)->Dictionary:
	var busy:=assignments.values()
	for candidate in people:
		if candidate.role==role and candidate.status=="living" and candidate.has("genius") and not candidate.id in busy: return candidate
	return {}

func release_assignment(slot:String)->void:
	assignments.erase(slot)

func note(id:String,day:int,text:String,renown:int=0)->void:
	var p:=by_id(id)
	if p.is_empty(): return
	p.renown=maxi(0,int(p.renown)+renown)
	_event(p,day,text)

func record_death(id:String,day:int,cause:String)->void:
	var p:=by_id(id)
	if p.is_empty() or p.status=="dead": return
	p.status="dead"; p.death_day=day; p.supported=false
	p.legacy=clampf(float(p.work_days)/365.0*.004+float(p.renown)*.001,0,.12)
	_event(p,day,"Died from %s. Their recorded work now contributes through its legacy." % cause)
	# No population decrement: these figures are already represented in aggregate demographics.

func commander(base:Dictionary,slot:String)->Dictionary:
	ensure()
	var p:=by_id(String(assignments.get(slot,"")))
	if p.is_empty() or p.status!="living":
		# A war leader of rare gift (geniuses.gd) is sent first.
		p=_free_gifted("General")
		if p.is_empty():
			for candidate in people:
				if candidate.role=="General" and candidate.status=="living" and not candidate.id in assignments.values(): p=candidate; break
		if p.is_empty(): p=_create("General",int(WorldSimulation.state.elapsed_days))
		if p.is_empty(): return base.duplicate(true)
		assignments[slot]=p.id
	return commander_record(p,base)

## The commander record a figure makes (their own skills, general_skill):
## what commander() puts on a band and leader_commands reads for a general.
func commander_record(p:Dictionary,base:Dictionary)->Dictionary:
	var result:=base.duplicate(true)
	result.name=p.name; result["figure_id"]=p.id; result["institutional"]=false
	result.erase("acting")
	for skill in COMMAND_SKILLS: result[skill]=general_skill(p,skill,base)
	# The own skills this record was drawn from: a band's record is drawn again
	# when they change (leader_commands.sync_commanders).
	result["own_skills"]=skills_of(p).duplicate()
	return result

## A force's general's record drawn again when stale: their own skills have
## changed since it was drawn (they grew, or the save is older than generals'
## own skills). `host` is the force's MilitaryCampaign; `base` caches its
## acting staff's record across calls. True when redrawn.
func sync_force(host:Node,force:Dictionary,base:Variant=null)->bool:
	var commander:Dictionary=force.get("commander",{}) if force.get("commander") is Dictionary else {}
	var id:=String(commander.get("figure_id",""))
	if id=="": return false
	var person:=by_id(id)
	if person.is_empty() or String(person.get("status",""))=="dead": return false
	var own:=skills_of(person)
	if own.is_empty() or (commander.get("own_skills") is Dictionary and (commander.own_skills as Dictionary)==own): return false
	var lent:Dictionary=base if base is Dictionary else {}
	if lent.is_empty(): lent.merge(host._acting_field_commander(false))
	var fresh:=commander_record(person,lent)
	# Keep what the record says about the force's own standing.
	for key in ["office","institutional"]:
		if commander.has(key) and not fresh.has(key): fresh[key]=commander[key]
	force["commander"]=fresh
	return true

## The named commander of a fleet or air wing (role "Admiral" or "Air
## Commander"): the living holder of `slot`, or a new figure from the realm's
## own names. {} when the roster of living figures is full.
func branch_commander(role:String,slot:String)->Dictionary:
	ensure()
	if role not in ["Admiral","Air Commander"]: return {}
	var p:=by_id(String(assignments.get(slot,"")))
	if not p.is_empty() and p.status in ["living","wounded"]: return p
	# Few enough to stay exceptional: at most two of each branch alive, and
	# never the last places of the roster. Beyond that one of them takes
	# several task forces or wings, as a fleet or air-group commander.
	var serving:Array=[]
	for candidate in people:
		if candidate.role==role and candidate.status=="living": serving.append(candidate)
	if serving.size()>=BRANCH_COMMANDERS or living_count()>=MAX_LIVING-2:
		if serving.is_empty(): return {}
		p=serving[posmod(hash(slot),serving.size())]
		assignments[slot]=p.id
		return p
	p=_create(role,int(WorldSimulation.state.elapsed_days))
	if p.is_empty(): return {}
	assignments[slot]=p.id
	_event(p,int(WorldSimulation.state.elapsed_days),"Given command at sea." if role=="Admiral" else "Given command of an air wing.")
	return p

func record_battle(result:Dictionary)->void:
	ensure()
	var term:Dictionary=result.get("termination",{})
	var day:=int(WorldSimulation.state.elapsed_days)
	var key:="%s:%s:%s" % [day,result.get("seed",0),result.get("round_count",0)]
	for side in ["attacker","defender"]:
		var force:Dictionary=result.get(side,{})
		var c:Dictionary=force.get("commander",{})
		var p:=by_id(String(c.get("figure_id","")))
		if p.is_empty() or p.status=="dead" or key in p.battle_keys: continue
		p.battle_keys.append(key)
		if p.battle_keys.size()>64: p.battle_keys.pop_front()
		p.renown+=3
		# Their record: our men lost under them and theirs, and a battle's
		# lessons in command and tactics.
		var other:Dictionary=result.get("defender" if side=="attacker" else "attacker",{})
		note_record(String(p.id),"men_lost",float(maxi(0,int(force.get("casualties",0)))))
		note_record(String(p.id),"enemy_lost",float(maxi(0,int(other.get("casualties",0)))))
		_grow(p,["command","tactics"],GROWTH_PER_BATTLE,"grown_battles",1)
		# Won or lost, by who broke (a fight nobody broke is neither).
		var defeated:=String(term.get("defeated",""))
		if defeated!="":
			var lost:=defeated==String(force.get("name",""))
			p["battles_lost" if lost else "battles_won"]=int(p.get("battles_lost" if lost else "battles_won",0))+1
		_event(p,day,"Led %s: %s; %d soldiers remained in the force." % [force.get("name","an army"),String(result.get("outcome","undecided")).replace("_"," "),int(force.get("remaining_troops",0))])
		if String(term.get("defeated",""))!=String(force.get("name","")): continue
		var fate:=String(term.get("commander_fate","escaped"))
		if fate=="killed": record_death(String(p.id),day,"battle wounds")
		elif fate=="captured": p.status="captured"; p.supported=false; _event(p,day,"Taken prisoner; unable to contribute while captive.")
		elif "wounded" in fate: p.status="wounded"; p.recover_day=day+180; _event(p,day,"Wounded in battle; recovery expected in 180 days.")

func resolve_captive(id:String,policy:String)->void:
	var p:=by_id(id)
	if p.is_empty() or p.status!="captured": return
	if policy=="execute": record_death(id,int(WorldSimulation.state.elapsed_days),"execution in captivity")
	elif policy in ["release","ransom"]:
		p.status="living"; _event(p,int(WorldSimulation.state.elapsed_days),"Returned from captivity through %s." % policy)

func biography(p:Dictionary)->String:
	if p.get("genius") is Dictionary: return GENIUSES.biography(p)
	var pronoun:="She" if p.gender=="woman" else "He"
	return "%s grew up near %s, in %s. %s entered public life at age %d.\n\n%s\n\n%s is %s, with an ambition to %s. Their work centers on %s." % [p.name,p.origin,p.get("upbringing","a working household"),pronoun,(int(p.emerged)-int(p.born))/365,p.get("turning_point","Early experience shaped a practical vocation."),pronoun,p.temperament,p.motive,CALLINGS[p.role]]


## A noticed gifted child comes of age (geniuses.gd): a figure of the work's
## calling, born when they were born, in public life from today. {} when the
## roster has no room left.
func create_genius(g:Dictionary,day:int,home_name:String)->Dictionary:
	if people.size()>=MAX_RECORDS: _forget_gifted_dead()
	if people.size()>=MAX_RECORDS: return {}
	var layer_id:=String(g.get("layer",""))
	var role:=String(GENIUSES.FIGURE_ROLE.get(layer_id,""))
	if not ROLES.has(role): return {}
	var rng:=RandomNumberGenerator.new(); rng.seed=hash("%d:genius_figure:%s" % [seed_value,String(g.get("id",""))])
	var traditions:Array=NAMES.POOLS.keys()
	var tradition:=String(traditions[posmod(seed_value+int(g.get("serial",0)),traditions.size())])
	serial+=1
	var gift:=clampf(float(g.get("gift",0.5)),0.0,1.0)
	var p:Dictionary={"id":"figure_%d_%d" % [seed_value,serial],"name":String(g.name),"tradition":tradition,"gender":"woman" if bool(g.get("female",false)) else "man","role":role,"domain":ROLES[role],
		"born":int(g.born),"emerged":day,"death_day":-1,"natural_death":int(g.born)+GENIUSES.OLDEST_YEARS*365,"status":"living","talent":GENIUSES.talent_of(gift),
		"temperament":TEMPERAMENTS[rng.randi_range(0,TEMPERAMENTS.size()-1)],"motive":MOTIVES[rng.randi_range(0,MOTIVES.size()-1)],"origin":home_name,"upbringing":"","turning_point":TURNING_POINTS[role][rng.randi_range(0,1)],
		"supported":false,"work_days":0,"renown":4,"legacy":0.0,"events":[],"battle_keys":[],"recover_day":-1,
		"genius":{"layer":layer_id,"gift":gift,"home":String(g.get("home","")),"noticed":int(g.get("noticed",day)),"grown":day,"pitched":-1,"led":-1}}
	used[String(p.name)]=true
	people.append(p)
	_ids.map={}
	skills_of(p)
	_event(p,int(g.get("noticed",day)),"Noticed as a child for a rare gift for %s." % String(GENIUSES.GIFT.get(layer_id,"their work")))
	_event(p,day,"Came of age and took up %s." % String(GENIUSES.GIFT.get(layer_id,"their work")))
	return p

## Makes room in a full roster: the longest-dead gifted figures nobody is
## assigned to are forgotten first (geniuses.gd KEEP_DEAD).
func _forget_gifted_dead()->void:
	var dead:Array=[]
	for p in people:
		if p.has("genius") and p.status=="dead" and not String(p.id) in assignments.values(): dead.append(p)
	if dead.size()<=0: return
	dead.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.death_day)<int(b.death_day))
	var keep:=mini(GENIUSES.KEEP_DEAD,dead.size()-1)
	for i in dead.size()-keep: people.erase(dead[i])
	_ids.map={}

func export_state()->Dictionary:
	ensure()
	return {"version":1,"seed":seed_value,"people":people.duplicate(true),"used":used.duplicate(true),"assignments":assignments.duplicate(true),"serial":serial,"last_day":last_day,"last_emergence":last_emergence}

func import_state(state:Dictionary)->Dictionary:
	if int(state.get("version",0))!=1 or int(state.get("seed",0))!=WorldSimulation.state.world_seed: return {"error":"Figure save has an incompatible version or world seed."}
	if not state.get("people",[]) is Array or state.people.size()>MAX_RECORDS: return {"error":"Invalid historical figure roster."}
	var ids:Dictionary={}; var names:Dictionary={}; var alive:=0; var gifted:=0
	for p in state.people:
		if not p is Dictionary or not p.has_all(["id","name","role","status","born","emerged","natural_death","death_day","talent","temperament","motive","origin","gender","domain","supported","work_days","renown","legacy","events","battle_keys","recover_day","tradition"]): return {"error":"Incomplete historical figure."}
		if ids.has(p.id) or names.has(p.name) or not ROLES.has(p.role) or p.status not in ["living","dead","captured","wounded"]: return {"error":"Invalid or duplicate historical figure."}
		if not p.events is Array or p.events.size()>12 or not p.battle_keys is Array or p.battle_keys.size()>64: return {"error":"Invalid historical figure history."}
		for field in ["born","emerged","natural_death","death_day","talent","work_days","renown","legacy","recover_day"]:
			if not (p[field] is int or p[field] is float) or not is_finite(float(p[field])): return {"error":"Invalid numeric figure field."}
		if p.domain!=ROLES[p.role] or float(p.talent)<0 or float(p.talent)>1 or float(p.legacy)<0 or float(p.legacy)>.12 or int(p.work_days)<0 or int(p.renown)<0: return {"error":"Invalid figure contribution."}
		for event in p.events:
			if not event is Dictionary or not event.has_all(["day","text"]): return {"error":"Invalid figure event."}
		# A commander's own skills and record (optional: older saves draw them on load).
		if p.has("skills"):
			if not p.skills is Dictionary or p.skills.size()>COMMAND_SKILLS.size(): return {"error":"Invalid figure skills."}
			for skill in p.skills:
				if not String(skill) in COMMAND_SKILLS or not (p.skills[skill] is float or p.skills[skill] is int) or not is_finite(float(p.skills[skill])) or float(p.skills[skill])<0.0 or float(p.skills[skill])>1.0: return {"error":"Invalid figure skill."}
		if p.has("record"):
			if not p.record is Dictionary or p.record.size()>RECORD_KEYS.size(): return {"error":"Invalid figure record."}
			for key in p.record:
				if not String(key) in RECORD_KEYS or not (p.record[key] is float or p.record[key] is int) or not is_finite(float(p.record[key])) or float(p.record[key])<0.0: return {"error":"Invalid figure record entry."}
		for count_key in ["battles_won","battles_lost"]:
			if p.has(count_key) and (not (p[count_key] is int or p[count_key] is float) or int(p[count_key])<0): return {"error":"Invalid figure battle count."}
		# A grown genius (optional: older saves have none; geniuses.gd).
		if p.has("genius") and not GENIUSES.valid_figure(p): return {"error":"Invalid gifted figure."}
		if p.status!="dead":
			if p.has("genius"): gifted+=1
			else: alive+=1
		ids[p.id]=true; names[p.name]=true
	if alive>MAX_LIVING or gifted>GENIUSES.MAX_LIVING or int(state.get("serial",0))<state.people.size(): return {"error":"Invalid figure count."}
	if not state.get("assignments",{}) is Dictionary: return {"error":"Invalid figure assignments."}
	for id in state.get("assignments",{}).values():
		if not ids.has(id): return {"error":"Unknown assigned figure."}
	people.assign(state.people.duplicate(true)); used=names; assignments=state.get("assignments",{}).duplicate(true)
	# Gifted children already named keep their names reserved.
	for g in geniuses:
		if String(g.get("name",""))!="": used[String(g.name)]=true
	serial=int(state.get("serial",people.size())); last_day=int(state.get("last_day",0)); last_emergence=int(state.get("last_emergence",0)); seed_value=WorldSimulation.state.world_seed; initialized=true
	_ids.map={}
	# Commanders saved before they had skills of their own draw them now, from
	# their own seed, the same as they would have been drawn.
	for p in people:
		if not (p.get("skills") is Dictionary and (p.skills as Dictionary).size()==COMMAND_SKILLS.size()): p.erase("skills")
		skills_of(p)
	return {"ok":true}

func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F10:
		open_chronicle(); get_viewport().set_input_as_handled()

func open_chronicle(id:String="")->void:
	ensure()
	if is_instance_valid(panel):
		if id=="": panel.queue_free(); return
		for i in people.size():
			if people[i].id==id: panel.index=i; panel.chapter=0; panel._refresh(); return
		return
	if not is_instance_valid(layer): layer=CanvasLayer.new(); layer.layer=80; add_child(layer)
	panel=preload("res://scripts/historical_figures_screen.gd").new()
	for i in people.size():
		if people[i].id==id: panel.index=i
	layer.add_child(panel)
