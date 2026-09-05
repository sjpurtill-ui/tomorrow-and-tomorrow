extends Node

# Exceptional figures only. The population remains numerical cohorts.
const NAMES=preload("res://scripts/historical_name_generator.gd")
const MAX_LIVING:=12
const MAX_RECORDS:=512
const ROLES:={"General":"security","Scholar":"knowledge","Physician":"health","Engineer":"infrastructure","Agronomist":"nutrition","Organizer":"institutions","Artist":"culture","Explorer":"logistics"}
const CALLINGS:={"General":"training formations and keeping troops together","Scholar":"testing explanations and teaching apprentices","Physician":"comparing treatments and training healers","Engineer":"improving structures and teaching builders","Agronomist":"comparing harvests and preserving practical knowledge","Organizer":"improving public administration and teaching officials","Artist":"developing a shared artistic tradition","Explorer":"recording routes and teaching navigators"}
const UPBRINGINGS:=["a household of craftspeople, where mistakes had immediate costs","a farming family that kept careful accounts of good and bad years","a family of traveling traders, learning to listen before bargaining","a crowded household where sharing work mattered more than rank","a settlement on a trade route, surrounded by unfamiliar languages","a family of practical teachers who expected every claim to be demonstrated"]
const TURNING_POINTS:={"General":["Watching a poorly organized withdrawal convinced them that preparation saves lives.","An early dispute with a superior left them determined to earn loyalty rather than assume it."],"Scholar":["Two teachers offered incompatible explanations of the same observation; they began keeping their own records.","A failed demonstration taught them to separate a pleasing explanation from a dependable one."],"Physician":["Conflicting advice during a household illness led them to compare treatments methodically.","They began by assisting an experienced healer and questioning which routines actually helped."],"Engineer":["Repeated repairs to the same structure led them to ask why it kept failing.","Their apprenticeship taught them that an elegant design is useless if nobody can maintain it."],"Agronomist":["Different harvests on neighboring plots inspired a habit of careful comparison.","A poor growing season made the preservation of practical knowledge a personal concern."],"Organizer":["A dispute over shared stores showed them how weak records can turn neighbors against one another.","They learned administration by reconciling promises with the work a community could actually perform."],"Artist":["The same story told differently by neighboring communities became a lasting source of fascination.","An exacting teacher demanded imitation; they became more interested in finding a voice of their own."],"Explorer":["An unreliable route description convinced them that knowledge must be usable by the next traveler.","Early journeys taught them to value local knowledge over confident guesses."]}
const TEMPERAMENTS:=["patient and exacting","bold and impatient","generous but proud","skeptical and persistent","eloquent but restless","quiet and uncompromising","inventive and stubborn","disciplined but suspicious"]
const MOTIVES:=["make useful knowledge available beyond a privileged few","prove that inherited methods can be improved","protect communities from the failures witnessed in youth","build a tradition that can survive its founder","earn recognition through work that others can verify","train successors capable of questioning their teacher"]
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

func ensure()->void:
	if initialized and seed_value==GameState.world_seed: return
	reset_for_new_world()
	initialized=true; seed_value=GameState.world_seed; last_day=int(GameState.elapsed_days); last_emergence=last_day
	for role in ROLES: _create(String(role),last_day)

func reset_for_new_world()->void:
	people.clear(); used.clear(); assignments.clear(); serial=0; initialized=false; last_day=0; last_emergence=0
	if is_instance_valid(panel): panel.queue_free()

func _create(role:String,day:int)->Dictionary:
	if people.size()>=MAX_RECORDS or living_count()>=MAX_LIVING: return {}
	var rng:=RandomNumberGenerator.new(); rng.seed=hash("%d:figure:%d" % [seed_value,serial])
	var traditions:Array=NAMES.POOLS.keys()
	var tradition:=String(traditions[posmod(seed_value+serial/8,traditions.size())])
	var identity:Dictionary=NAMES.make(seed_value,serial,serial%2==0,tradition,used)
	serial+=1
	if identity.is_empty(): return {}
	used[identity.name]=true
	var age:=rng.randi_range(24,42)
	var p:Dictionary={"id":"figure_%d_%d" % [seed_value,serial],"name":identity.name,"tradition":tradition,"gender":"woman" if (serial-1)%2==0 else "man","role":role,"domain":ROLES[role],"born":day-age*365,"emerged":day,"death_day":-1,"natural_death":day+(rng.randi_range(58,86)-age)*365,"status":"living","talent":rng.randf_range(.65,.98),"temperament":TEMPERAMENTS[rng.randi_range(0,TEMPERAMENTS.size()-1)],"motive":MOTIVES[rng.randi_range(0,MOTIVES.size()-1)],"origin":NAMES.ORIGINS[rng.randi_range(0,NAMES.ORIGINS.size()-1)],"upbringing":UPBRINGINGS[rng.randi_range(0,UPBRINGINGS.size()-1)],"turning_point":TURNING_POINTS[role][rng.randi_range(0,1)],"supported":false,"work_days":0,"renown":0,"legacy":0.0,"events":[],"battle_keys":[],"recover_day":-1}
	people.append(p)
	_event(p,day,"Entered public life as a %s." % role.to_lower())
	return p

func living_count()->int:
	var count:=0
	for p in people:
		if p.status!="dead": count+=1
	return count

func by_id(id:String)->Dictionary:
	for p in people:
		if p.id==id: return p
	return {}

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
		if day>=int(p.natural_death): record_death(String(p.id),int(p.natural_death),"old age")
	last_day=day
	if day-last_emergence>=365*5:
		last_emergence=day
		var counts:Dictionary={}
		for role in ROLES: counts[role]=0
		for p in people:
			if p.status!="dead": counts[p.role]+=1
		var chosen:="General"
		for role in counts:
			if counts[role]<counts[chosen]: chosen=role
		_create(chosen,day)

func support(id:String)->Dictionary:
	ensure()
	var p:=by_id(id)
	if p.is_empty() or (p.status!="living" and not p.supported): return {"error":"Only living, available figures can receive patronage."}
	var count:=0
	for other in people:
		if other.supported and other.status!="dead": count+=1
	if not p.supported and count>=3: return {"error":"Three patronage places are filled. Withdraw support from someone first."}
	p.supported=not p.supported
	_event(p,int(GameState.elapsed_days),"Received public patronage." if p.supported else "Public patronage ended.")
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
		p={}
		for candidate in people:
			if candidate.role=="General" and candidate.status=="living" and not candidate.id in assignments.values(): p=candidate; break
		if p.is_empty(): p=_create("General",int(GameState.elapsed_days))
		if p.is_empty(): return base.duplicate(true)
		assignments[slot]=p.id
	var result:=base.duplicate(true)
	result.name=p.name; result["figure_id"]=p.id; result["institutional"]=false
	for skill in ["command","tactics","logistics","resolve"]:
		result[skill]=clampf(float(base.get(skill,.5))*.75+float(p.talent)*.25+living_bonus(p)*.2+(multiplier("security")-1.0)*.1,0,1)
	return result

func record_battle(result:Dictionary)->void:
	ensure()
	var term:Dictionary=result.get("termination",{})
	var day:=int(GameState.elapsed_days)
	var key:="%s:%s:%s" % [day,result.get("seed",0),result.get("round_count",0)]
	for side in ["attacker","defender"]:
		var force:Dictionary=result.get(side,{})
		var c:Dictionary=force.get("commander",{})
		var p:=by_id(String(c.get("figure_id","")))
		if p.is_empty() or p.status=="dead" or key in p.battle_keys: continue
		p.battle_keys.append(key)
		if p.battle_keys.size()>64: p.battle_keys.pop_front()
		p.renown+=3
		_event(p,day,"Led %s: %s; %d soldiers remained in the force." % [force.get("name","an army"),String(result.get("outcome","undecided")).replace("_"," "),int(force.get("remaining_troops",0))])
		if String(term.get("defeated",""))!=String(force.get("name","")): continue
		var fate:=String(term.get("commander_fate","escaped"))
		if fate=="killed": record_death(String(p.id),day,"battle wounds")
		elif fate=="captured": p.status="captured"; p.supported=false; _event(p,day,"Taken prisoner; unable to contribute while captive.")
		elif "wounded" in fate: p.status="wounded"; p.recover_day=day+180; _event(p,day,"Wounded in battle; recovery expected in 180 days.")

func resolve_captive(id:String,policy:String)->void:
	var p:=by_id(id)
	if p.is_empty() or p.status!="captured": return
	if policy=="execute": record_death(id,int(GameState.elapsed_days),"execution in captivity")
	elif policy in ["release","ransom"]:
		p.status="living"; _event(p,int(GameState.elapsed_days),"Returned from captivity through %s." % policy)

func biography(p:Dictionary)->String:
	var pronoun:="She" if p.gender=="woman" else "He"
	return "%s grew up near %s, in %s. %s entered public life at age %d.\n\n%s\n\n%s is %s, with an ambition to %s. Their work centers on %s." % [p.name,p.origin,p.get("upbringing","a working household"),pronoun,(int(p.emerged)-int(p.born))/365,p.get("turning_point","Early experience shaped a practical vocation."),pronoun,p.temperament,p.motive,CALLINGS[p.role]]


func export_state()->Dictionary:
	ensure()
	return {"version":1,"seed":seed_value,"people":people.duplicate(true),"used":used.duplicate(true),"assignments":assignments.duplicate(true),"serial":serial,"last_day":last_day,"last_emergence":last_emergence}

func import_state(state:Dictionary)->Dictionary:
	if int(state.get("version",0))!=1 or int(state.get("seed",0))!=GameState.world_seed: return {"error":"Figure save has an incompatible version or world seed."}
	if not state.get("people",[]) is Array or state.people.size()>MAX_RECORDS: return {"error":"Invalid historical figure roster."}
	var ids:Dictionary={}; var names:Dictionary={}; var alive:=0
	for p in state.people:
		if not p is Dictionary or not p.has_all(["id","name","role","status","born","emerged","natural_death","death_day","talent","temperament","motive","origin","gender","domain","supported","work_days","renown","legacy","events","battle_keys","recover_day","tradition"]): return {"error":"Incomplete historical figure."}
		if ids.has(p.id) or names.has(p.name) or not ROLES.has(p.role) or p.status not in ["living","dead","captured","wounded"]: return {"error":"Invalid or duplicate historical figure."}
		if not p.events is Array or p.events.size()>12 or not p.battle_keys is Array or p.battle_keys.size()>64: return {"error":"Invalid historical figure history."}
		for field in ["born","emerged","natural_death","death_day","talent","work_days","renown","legacy","recover_day"]:
			if not (p[field] is int or p[field] is float) or not is_finite(float(p[field])): return {"error":"Invalid numeric figure field."}
		if p.domain!=ROLES[p.role] or float(p.talent)<0 or float(p.talent)>1 or float(p.legacy)<0 or float(p.legacy)>.12 or int(p.work_days)<0 or int(p.renown)<0: return {"error":"Invalid figure contribution."}
		for event in p.events:
			if not event is Dictionary or not event.has_all(["day","text"]): return {"error":"Invalid figure event."}
		if p.status!="dead": alive+=1
		ids[p.id]=true; names[p.name]=true
	if alive>MAX_LIVING or int(state.get("serial",0))<state.people.size(): return {"error":"Invalid figure count."}
	if not state.get("assignments",{}) is Dictionary: return {"error":"Invalid figure assignments."}
	for id in state.get("assignments",{}).values():
		if not ids.has(id): return {"error":"Unknown assigned figure."}
	people.assign(state.people.duplicate(true)); used=names; assignments=state.get("assignments",{}).duplicate(true)
	serial=int(state.get("serial",people.size())); last_day=int(state.get("last_day",0)); last_emergence=int(state.get("last_emergence",0)); seed_value=GameState.world_seed; initialized=true
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
