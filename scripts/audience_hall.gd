extends RefCounted
## Audience Hall engine. The world comes to the ruler: foreign envoys bring
## gifts, requests, tribute demands and news; officials petition about real
## conditions, grievances and ambitions. This is the only place the hall
## changes world state. Voice text never moves goods or relations; it may only
## nudge the bounded room `mood`, which adds at most ±0.03 opinion at resolve.
##
## State lives in ForeignDiplomacy.audiences and is saved with that system.
## Reference with preload (no class_name; the runtime class cache is not
## rebuilt outside the editor).

const EXCHANGE:=preload("res://scripts/civilization_exchange.gd")
const SOCIETY:=preload("res://scripts/society_exchange.gd")
const NAMES:=preload("res://scripts/historical_name_generator.gd")
const RESOURCES:=["Food","Timber","Stone","Clay","Fiber Plants"]
const KINDS:=["gift","request","threat","news","petition","report","great_work","wonder_proposal"]
## Kinds raised by our own people (origin "court").
const COURT_KINDS:=["petition","report","great_work","wonder_proposal"]
const WORK_KINDS:=["great_work","wonder_proposal"]
const GREAT_WORKS_PATH:="res://scripts/great_works_audience.gd"
const REPORT_SOURCES:=["scouts","envoys","expedition"]
const REPORT_FACTS_MAX:=24
const TOPICS:=["food","health","housing","security","grievance","ambition"]
const REACTIONS:=["delighted","pleased","neutral","offended","furious"]
const EXPIRY_DAYS:=20
const QUEUE_MAX:=4
const HISTORY_MAX:=30
const LINES_MAX:=60
const GAP_DAYS:=3
const COURT_MAX:=4
const MOOD_OPINION:=0.03

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func state()->Dictionary:
	ForeignDiplomacy.ensure()
	var s:Dictionary=ForeignDiplomacy.audiences
	if not s.has("version"): s["version"]=1
	if not s.get("queue") is Array: s["queue"]=[]
	if not s.get("history") is Array: s["history"]=[]
	if not s.get("next_foreign") is Dictionary: s["next_foreign"]={}
	if not s.get("next_court") is Dictionary: s["next_court"]={}
	if not s.has("last_arrival_day"): s["last_arrival_day"]=-9999
	if not s.has("serial"): s["serial"]=0
	if not s.has("summon_immediately"): s["summon_immediately"]=true
	ForeignDiplomacy.audiences=s
	return s

static func waiting()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for audience in state().queue:
		if String(audience.get("status",""))=="waiting": result.append(audience)
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.arrived_day)<int(b.arrived_day) or (int(a.arrived_day)==int(b.arrived_day) and _serial_of(a)<_serial_of(b)))
	return result

static func find(id:String)->Dictionary:
	var s:=state()
	for list_key in ["queue","history"]:
		for audience in s[list_key]:
			if String(audience.get("id",""))==id: return audience
	return {}

static func _serial_of(audience:Dictionary)->int:
	return int(String(audience.get("id","aud_0")).trim_prefix("aud_"))

static func _day()->int:
	return int(GameState.elapsed_days)

static func _great_works()->GDScript:
	## Great Works audiences (architects, rival races, forecasts); loaded lazily
	## because that module reaches back into this one.
	return load(GREAT_WORKS_PATH) as GDScript if ResourceLoader.exists(GREAT_WORKS_PATH) else null

static func _rng(key:String,day:int)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:audience:%s:%d" % [int(GameState.world_seed),key,day])
	return rng

# --------------------------------------------------------------------------
# Daily arrivals and expiry
# --------------------------------------------------------------------------

static func daily(day:int)->Array[Dictionary]:
	var arrivals:Array[Dictionary]=[]
	if WorldSimulation.actor_id!="player": return arrivals
	var s:=state()
	_expire(day)
	_schedule_new(day)
	if day-int(s.last_arrival_day)<GAP_DAYS or waiting().size()>=QUEUE_MAX: return arrivals
	# Gather everyone due, most overdue first; the first that can truthfully be
	# generated arrives. Others stay due and arrive after the gap.
	var due:Array=[]
	for civ_id in s.next_foreign:
		if int(s.next_foreign[civ_id])<=day and not _has_waiting("foreign",String(civ_id),0) and not ForeignDiplomacy.civilization(String(civ_id)).is_empty():
			due.append({"origin":"foreign","key":String(civ_id),"due":int(s.next_foreign[civ_id])})
	for person_key in s.next_court:
		if int(s.next_court[person_key])<=day and not _has_waiting("court","",int(person_key)):
			due.append({"origin":"court","key":String(person_key),"due":int(s.next_court[person_key])})
	due.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.due)<int(b.due) or (int(a.due)==int(b.due) and String(a.key)<String(b.key)))
	for entry:Dictionary in due:
		var audience:Dictionary={}
		if entry.origin=="foreign":
			audience=_generate_foreign(String(entry.key),day,"")
			var rng:=_rng("next:"+String(entry.key),day)
			s.next_foreign[entry.key]=day+(_foreign_interval(String(entry.key),rng) if not audience.is_empty() else rng.randi_range(4,9))
		else:
			audience=_generate_petition(int(entry.key),day,"")
			var rng2:=_rng("court_next:"+String(entry.key),day)
			s.next_court[entry.key]=day+(rng2.randi_range(30,60) if not audience.is_empty() else rng2.randi_range(12,24))
		if audience.is_empty(): continue
		_enqueue(audience,day)
		arrivals.append(audience)
		break
	return arrivals

static func _has_waiting(origin:String,civ_id:String,person_id:int)->bool:
	for audience in state().queue:
		if String(audience.get("status",""))!="waiting" or String(audience.origin)!=origin: continue
		if origin=="foreign" and String(audience.civ_id)==civ_id: return true
		if origin=="court" and int(audience.speaker.get("person_id",0))==person_id: return true
	return false

static func _schedule_new(day:int)->void:
	var s:=state()
	for civ in WorldSimulation.world.civilizations:
		var id:=String(civ.get("id",""))
		if id=="" or s.next_foreign.has(id) or not bool(civ.get("alive",true)): continue
		if ForeignDiplomacy.civilization(id).is_empty(): continue
		var met:=int(civ.player_relation.get("met_day",-1))
		var base:=met if met>=0 and day-met<15 else day
		s.next_foreign[id]=base+_rng("first:"+id,base).randi_range(6,15)
	var present:Dictionary={}
	for person in _officials():
		var key:=str(int(person.person_id))
		present[key]=true
		if not s.next_court.has(key): s.next_court[key]=day+_rng("court_first:"+key,day).randi_range(12,45)
	for key in s.next_court.keys():
		if not present.has(String(key)): s.next_court.erase(key)

static func _foreign_interval(civ_id:String,rng:RandomNumberGenerator)->int:
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var p:Dictionary=ForeignDiplomacy.leader(civ_id).get("personality",{})
	var relation:Dictionary=civ.get("player_relation",{})
	var urgency:=clampf(float(p.get("assertiveness",.5))*.35+float(relation.get("border_tension",0))*.45+maxf(0,-float(relation.get("opinion",0)))*.3+(.25 if bool(relation.get("at_war",false)) else 0.0),0,1)
	return clampi(roundi(lerpf(40.0,18.0,urgency)+rng.randf_range(-5,5)),18,40)

static func _expire(day:int)->void:
	var s:=state()
	for audience in s.queue.duplicate():
		if String(audience.status)!="waiting" or day<int(audience.expires_day): continue
		audience.status="expired"
		if audience.kind=="wonder_proposal":
			audience.outcome="%s gave up waiting to pitch their great work; the idea is shelved." % String(audience.speaker.name)
		elif audience.kind=="great_work":
			# Works never deadlock: the council answers stage gates after its own delay.
			audience.outcome="%s could wait no longer; the matter of %s passed to the council." % [String(audience.speaker.name),String((audience.get("great_work",{}) as Dictionary).get("title","the work"))]
		elif audience.origin=="foreign":
			var id:=String(audience.civ_id)
			_shift_relation(id,-0.04,0.0)
			var leader:=ForeignDiplomacy.leader(id)
			if not leader.is_empty(): leader.trust=clampf(float(leader.trust)-0.03,-1,1)
			ForeignDiplomacy.remember(id,"Our envoy %s waited %d days in the ruler's antechamber and was never received. They came home insulted." % [String(audience.speaker.name),int(day-int(audience.arrived_day))])
			audience.outcome="%s waited %d days without an audience and has left, insulted. %s thinks less of you (opinion −0.04, trust −0.03)." % [String(audience.speaker.name),int(day-int(audience.arrived_day)),String(audience.civ_name)]
		else:
			var pid:=int(audience.speaker.person_id)
			GovernmentPeopleSystem.adjust_person_relationship(pid,0,0,0.04)
			var matter:String="their report on %s" % String(audience.get("report",{}).get("subject_name","what they found")) if audience.kind=="report" else _topic_words(String(audience.petition.get("topic","")))
			GovernmentPeopleSystem.record_person_memory(pid,"Asked for an audience about %s and was left waiting until the matter went stale." % matter,"audience",0.55,{"emotion":"slighted","outcome":"expired"})
			audience.outcome="%s gave up waiting for an audience about %s. Resentment rose (+0.04)." % [String(audience.speaker.name),matter]
		_archive(audience)

static func _enqueue(audience:Dictionary,day:int)->void:
	var s:=state()
	s.queue.append(audience)
	s.last_arrival_day=day

static func _archive(audience:Dictionary)->void:
	var s:=state()
	s.queue.erase(audience)
	s.history.push_front(audience)
	if s.history.size()>HISTORY_MAX: s.history.resize(HISTORY_MAX)

static func _new_audience(origin:String,kind:String,day:int)->Dictionary:
	var s:=state()
	s.serial=int(s.serial)+1
	return {"id":"aud_%d" % int(s.serial),"origin":origin,"kind":kind,"civ_id":"","civ_name":"",
		"speaker":{"name":"","title":"","person_id":0,"role":"envoy" if origin=="foreign" else "official"},
		"arrived_day":day,"expires_day":day+EXPIRY_DAYS,"status":"waiting","terms":{},"news":{},"petition":{},"report":{},
		"lines":[],"outcome":"","option_id":"","mood":0.0}

# --------------------------------------------------------------------------
# Stores (always read the real ledgers)
# --------------------------------------------------------------------------

static func player_stock(resource:String)->float:
	return float(WorldSimulation.scoped("player",func()->float:
		return WorldSimulation.food.total_stored() if resource=="Food" else maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get(resource,0.0)))))

static func foreign_stock(civ_id:String,resource:String)->float:
	## -1 when the polity has no simulated ledger (it cannot hand over goods).
	if SOCIETY.owner_state(civ_id)==null or not WorldSimulation.actors.has(SOCIETY.owner_id(civ_id)): return -1.0
	return float(WorldSimulation.scoped(SOCIETY.owner_id(civ_id),func()->float:
		return WorldSimulation.food.total_stored() if resource=="Food" else maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get(resource,0.0)))))

static func _player_population()->float:
	return maxf(1.0,float(GameState.population_exact))

static func _nice(amount:float)->float:
	if amount>=60: return float(roundi(amount/10.0)*10)
	if amount>=20: return float(roundi(amount/5.0)*5)
	return float(maxi(1,roundi(amount)))

static func _debit_player(resource:String,amount:float)->float:
	return EXCHANGE.take("player",resource,amount)

static func _credit_civ(civ_id:String,resource:String,amount:float)->void:
	var index:=_civ_index(civ_id)
	if SOCIETY.owner_state(civ_id)!=null and WorldSimulation.actors.has(SOCIETY.owner_id(civ_id)):
		EXCHANGE.receive(civ_id,resource,amount)
	elif resource=="Food" and index>=0:
		var civ:Dictionary=WorldSimulation.world.civilizations[index]
		civ["food_days"]=clampf(float(civ.get("food_days",0.0))+amount/maxf(1.0,float(civ.get("population",1.0))),0.0,180.0)
	if index>=0:
		var target:Dictionary=WorldSimulation.world.civilizations[index]
		target["gift_value_received"]=maxf(0.0,float(target.get("gift_value_received",0.0)))+amount

# --------------------------------------------------------------------------
# Relations
# --------------------------------------------------------------------------

static func _civ_index(civ_id:String)->int:
	for index in WorldSimulation.world.civilizations.size():
		if String(WorldSimulation.world.civilizations[index].get("id",""))==civ_id: return index
	return -1

static func _shift_relation(civ_id:String,opinion:float,tension:float,extra:Dictionary={})->void:
	var index:=_civ_index(civ_id)
	if index<0: return
	var civ:Dictionary=WorldSimulation.world.civilizations[index]
	var relation:Dictionary=civ.get("player_relation",{})
	relation["opinion"]=clampf(float(relation.get("opinion",0.0))+opinion,-1.0,1.0)
	relation["border_tension"]=clampf(float(relation.get("border_tension",0.0))+tension,0.0,1.0)
	for key in extra: relation[key]=extra[key]
	civ["player_relation"]=relation
	WorldSimulation.world.civilizations[index]=civ

static func _leader_trust(civ_id:String,delta:float)->void:
	var leader:=ForeignDiplomacy.leader(civ_id)
	if leader.is_empty(): return
	leader.trust=clampf(float(leader.trust)+delta,-1.0,1.0)

static func _personality(civ_id:String)->Dictionary:
	var p:Dictionary=ForeignDiplomacy.leader(civ_id).get("personality",{})
	return p if not p.is_empty() else {"openness":.5,"discipline":.5,"empathy":.5,"assertiveness":.5,"risk_tolerance":.5}

static func _hungry(civ:Dictionary)->bool:
	return float(civ.get("food_days",30.0))<22.0

# --------------------------------------------------------------------------
# Foreign generation
# --------------------------------------------------------------------------

static func _generate_foreign(civ_id:String,day:int,forced_kind:String)->Dictionary:
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var leader:=ForeignDiplomacy.leader(civ_id)
	if civ.is_empty() or leader.is_empty(): return {}
	var rng:=_rng("foreign:%s:%d" % [civ_id,int(state().serial)],day)
	var p:=_personality(civ_id)
	var relation:Dictionary=civ.player_relation
	var opinion:=float(relation.get("opinion",0))
	var tension:=float(relation.get("border_tension",0))
	var war:=bool(relation.get("at_war",false))
	var trust:=float(leader.get("trust",0))
	var size_ratio:=float(civ.get("population",100))/_player_population()
	var candidates:Dictionary={
		"gift":_gift_terms(civ_id,civ,rng),
		"request":_request_terms(civ,rng),
		"threat":_threat_terms(civ,rng),
		"news":_news_fact(civ_id,rng),
	}
	var weights:Dictionary={
		"gift":0.0 if war else maxf(0.0,0.7+float(p.empathy)*1.0+float(p.openness)*0.4+maxf(0,opinion)*1.6+trust*0.8+(0.4 if String(relation.get("treaty",""))=="trade" else 0.0)-tension*0.9),
		"request":0.0 if war else maxf(0.0,0.45+(1.5 if _hungry(civ) else 0.0)+maxf(0,opinion)*0.7+(1-float(p.discipline))*0.35+(0.3 if String(civ.get("strategy","")) in ["expansion","fortification","growth"] else 0.0)),
		"threat":maxf(0.02,pow(float(p.assertiveness),2)*1.8+tension*2.0+maxf(0,-opinion)*1.3+float(p.risk_tolerance)*0.45+float(civ.get("aggression",0.3))*0.8-float(p.empathy)*0.9+(1.5 if war else 0.0))*clampf(size_ratio,0.35,1.8),
		"news":0.55+float(p.openness)*0.9,
	}
	var chosen:=""
	if forced_kind!="":
		if candidates.get(forced_kind,{}).is_empty(): return {}
		chosen=forced_kind
	else:
		var total:=0.0
		for kind in weights:
			if candidates[kind].is_empty(): weights[kind]=0.0
			total+=float(weights[kind])
		if total<=0.0: return {}
		var roll:=rng.randf()*total
		for kind in ["gift","request","threat","news"]:
			roll-=float(weights[kind])
			if float(weights[kind])>0.0 and roll<=0.0: chosen=kind; break
		if chosen=="":
			for kind in ["news","gift","request","threat"]:
				if float(weights[kind])>0.0: chosen=kind; break
	var audience:=_new_audience("foreign",chosen,day)
	audience.civ_id=civ_id
	audience.civ_name=String(civ.get("name",civ_id))
	audience.speaker=_envoy(civ_id,String(audience.id),chosen,leader)
	if chosen=="news": audience.news=candidates.news
	else: audience.terms=candidates[chosen]
	return audience

static func _envoy(civ_id:String,audience_id:String,kind:String,leader:Dictionary)->Dictionary:
	var serial:=posmod(hash(civ_id),10000)
	var traditions:Array=NAMES.POOLS.keys()
	var tradition:String=traditions[serial%traditions.size()]
	var envoy_serial:=posmod(hash(civ_id+":"+audience_id),100000)+10000
	var identity:Dictionary=NAMES.make(int(GameState.world_seed),envoy_serial,envoy_serial%2==0,tradition,{String(leader.get("name","")):true})
	var leader_name:=String(leader.get("name","their leader"))
	var titles:Dictionary={
		"gift":["Gift-bearer of %s","Friend of the house of %s","Hand of %s"],
		"request":["Petitioner for %s","Voice of %s","Messenger of %s"],
		"threat":["Herald of %s","Spear-speaker of %s","Envoy of %s"],
		"news":["Road-walker for %s","Listener of %s","Messenger of %s"],
	}
	var options:Array=titles.get(kind,titles.news)
	return {"name":String(identity.get("name","A traveling envoy")),"title":String(options[envoy_serial%options.size()]) % leader_name,"person_id":0,"role":"envoy"}

static func _gift_terms(civ_id:String,civ:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var p:=_personality(civ_id)
	var best:={}
	var best_score:=0.0
	for resource in RESOURCES:
		var stock:=foreign_stock(civ_id,resource)
		if stock<=0.0: continue
		if resource=="Food" and _hungry(civ): continue
		var cap:=_player_population()*(1.6 if resource=="Food" else 0.35)*(0.6+float(p.empathy)*0.8)
		var amount:=_nice(minf(stock*rng.randf_range(0.05,0.12),cap*rng.randf_range(0.7,1.2)))
		if amount<5.0 or amount>stock: continue
		var score:=amount/maxf(1.0,cap)*rng.randf_range(0.6,1.4)
		if score>best_score: best_score=score; best={"resource":resource,"amount":amount}
	return best

static func _request_terms(civ:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var wants:Array=[]
	if _hungry(civ): wants.append("Food")
	match String(civ.get("strategy","")):
		"expansion","growth": wants.append_array(["Timber","Fiber Plants"])
		"fortification": wants.append_array(["Stone","Timber"])
		"commerce": wants.append_array(["Clay","Fiber Plants"])
		"inquiry": wants.append("Clay")
		_: wants.append_array(["Food","Timber"])
	var others:Array=RESOURCES.duplicate()
	for index in others.size():
		var swap:=rng.randi_range(index,others.size()-1)
		var t:Variant=others[index]; others[index]=others[swap]; others[swap]=t
	for resource in others:
		if resource not in wants: wants.append(resource)
	var their_pop:=maxf(20.0,float(civ.get("population",100)))
	for resource:String in wants:
		var stock:=player_stock(resource)
		var want:=their_pop*(0.6 if resource=="Food" else 0.12)*rng.randf_range(0.7,1.3)
		var amount:=_nice(minf(want,stock*0.3))
		if amount>=5.0 and amount<=stock: return {"resource":resource,"amount":amount}
	return {}

static func _threat_terms(civ:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var best:={}
	var best_value:=0.0
	var their_pop:=maxf(20.0,float(civ.get("population",100)))
	for resource in RESOURCES:
		var stock:=player_stock(resource)
		var demand:=_nice(minf(stock*rng.randf_range(0.25,0.45),their_pop*(1.2 if resource=="Food" else 0.3)))
		if demand<8.0 or demand>stock: continue
		var value:=demand*(0.6 if resource=="Food" else 1.0)*rng.randf_range(0.8,1.2)
		if value>best_value: best_value=value; best={"resource":resource,"amount":demand}
	return best

static func _news_fact(civ_id:String,rng:RandomNumberGenerator)->Dictionary:
	## Real facts about third civilizations only.
	var facts:Array=[]
	var civs:Array=WorldSimulation.world.civilizations
	var player_pop:=_player_population()
	for first in civs:
		var first_id:=String(first.get("id",""))
		if first_id==civ_id or not bool(first.get("alive",true)): continue
		var name:=String(first.get("name",first_id))
		for other_id in (first.get("relations",{}) as Dictionary):
			if String(other_id)<=first_id and String(other_id)!=civ_id: continue
			var relation:Dictionary=first.relations[other_id]
			var other_index:=_civ_index(String(other_id))
			if other_index<0 or not bool(civs[other_index].get("alive",true)): continue
			var other_name:=String(civs[other_index].get("name",other_id))
			if bool(relation.get("at_war",false)):
				var text:String="%s and %s are at war." % [name,other_name] if String(other_id)!=civ_id else "%s is at war with %s, the people who sent this envoy." % [name,other_name]
				facts.append({"w":3.0,"f":{"subject_civ_id":first_id,"subject_civ_name":name,"fact_kind":"war","fact":text}})
			elif float(relation.get("border_tension",0))>0.6 and String(other_id)!=civ_id:
				facts.append({"w":1.4,"f":{"subject_civ_id":first_id,"subject_civ_name":name,"fact_kind":"border_tension","fact":"The border between %s and %s is tense; each watches the other." % [name,other_name]}})
		if bool(first.player_relation.get("at_war",false)):
			facts.append({"w":2.2,"f":{"subject_civ_id":first_id,"subject_civ_name":name,"fact_kind":"war_with_you","fact":"%s remains at war with your people." % name}})
		var food_days:=float(first.get("food_days",30))
		if food_days<12.0:
			facts.append({"w":2.6,"f":{"subject_civ_id":first_id,"subject_civ_name":name,"fact_kind":"famine","fact":"%s is going hungry; its stores would last only about %d days." % [name,maxi(0,roundi(food_days))]}})
		elif food_days>90.0:
			facts.append({"w":0.9,"f":{"subject_civ_id":first_id,"subject_civ_name":name,"fact_kind":"plenty","fact":"%s has full granaries, enough for about %d days." % [name,roundi(food_days)]}})
		var strategy_words:Dictionary={"fortification":"is raising defenses and drilling its fighters","expansion":"is pushing out to claim new land","inquiry":"is pouring effort into learning","commerce":"is busy with trade and traveling merchants","growth":"is growing its households quickly","sustenance":"is putting its strength into feeding itself"}
		var strategy:=String(first.get("strategy",""))
		if strategy_words.has(strategy):
			facts.append({"w":1.3 if strategy in ["fortification","expansion"] else 0.8,"f":{"subject_civ_id":first_id,"subject_civ_name":name,"fact_kind":"strategy","fact":"%s %s." % [name,strategy_words[strategy]]}})
		var pop:=float(first.get("population",0))
		if pop>0:
			var ratio:=pop/player_pop
			var comparison:="about as many as yours" if ratio>0.8 and ratio<1.25 else ("more than twice your number" if ratio>=2.0 else ("more than yours" if ratio>=1.25 else ("fewer than half yours" if ratio<=0.5 else "fewer than yours")))
			var rounded:=maxi(10,roundi(pop/10.0)*10) if pop<500 else roundi(pop/50.0)*50
			facts.append({"w":0.7,"f":{"subject_civ_id":first_id,"subject_civ_name":name,"fact_kind":"size","fact":"%s numbers roughly %d people, %s." % [name,rounded,comparison]}})
	if facts.is_empty(): return {}
	var total:=0.0
	for entry in facts: total+=float(entry.w)
	var roll:=rng.randf()*total
	for entry in facts:
		roll-=float(entry.w)
		if roll<=0.0: return (entry.f as Dictionary).duplicate()
	return (facts[-1].f as Dictionary).duplicate()

# --------------------------------------------------------------------------
# Court petitions
# --------------------------------------------------------------------------

static func _officials()->Array[Dictionary]:
	## Central officeholders first, then settlement leaders; unique by person.
	var result:Array[Dictionary]=[]
	var seen:Dictionary={}
	if WorldSimulation.actor_id!="player": return result
	for office in GovernmentPeopleSystem.active_offices():
		var person:=GovernmentPeopleSystem.officeholder(String(office.key))
		if person.is_empty() or seen.has(int(person.person_id)): continue
		person["office_key"]=String(office.key)
		seen[int(person.person_id)]=true
		result.append(person)
	for settlement in GameState.player_settlements:
		var leader:=GovernmentPeopleSystem.settlement_leader(String(settlement.get("id","")))
		if leader.is_empty() or seen.has(int(leader.person_id)): continue
		var place:=String(settlement.get("name",""))
		leader["office_title"]=String(leader.get("title","Local leader"))+(" of "+place if place!="" else "")
		leader["office_key"]="settlement"
		leader["settlement_id"]=String(settlement.get("id",""))
		seen[int(leader.person_id)]=true
		result.append(leader)
	return result

static func _official(person_id:int)->Dictionary:
	for person in _officials():
		if int(person.person_id)==person_id: return person
	return {}

static func conditions()->Dictionary:
	var metrics:Dictionary=GameState.simulation_metrics
	var pop:=_player_population()
	var housing:=clampf(float(GameState.housing_capacity)/pop,0.0,2.0)
	var water:Dictionary=GameState.water_metrics
	var threat:=0.0
	var threat_name:=""
	for civ in WorldSimulation.world.civilizations:
		var relation:Dictionary=civ.get("player_relation",{})
		if int(relation.get("contact_level",0))<1: continue
		var level:=float(relation.get("border_tension",0))+(0.6 if bool(relation.get("at_war",false)) else 0.0)
		if level>threat: threat=level; threat_name=String(civ.get("name",""))
	return {"food_days":float(metrics.get("food_days",30.0)),"food_intake":float(metrics.get("food_intake_ratio",1.0)),
		"health":float(GameState.population_health),"security":float(metrics.get("security",0.4)),"cohesion":float(metrics.get("cohesion",0.58)),
		"housing_ratio":housing,"water_intake":float(water.get("intake_ratio",1.0)) if bool(water.get("source_accessible",true)) or float(water.get("required_today",0))>0 else 1.0,
		"foreign_threat":threat,"threat_name":threat_name,"population":pop}

static func _generate_petition(person_id:int,day:int,forced_topic:String)->Dictionary:
	var person:=_official(person_id)
	if person.is_empty(): return {}
	var rng:=_rng("petition:%d:%d" % [person_id,int(state().serial)],day)
	var c:=conditions()
	var office:=String(person.get("office_key",""))
	var rel:Dictionary=person.get("relationships",{}).get("sovereign",{})
	var traits:Array=person.get("traits",[])
	var open_topics:Dictionary={}
	for audience in state().queue:
		if String(audience.status)=="waiting" and audience.origin=="court": open_topics[String(audience.petition.get("topic",""))]=true
	var relevance:=func(offices:Array)->float:return 1.0 if office in offices else (0.7 if office=="settlement" else 0.35)
	var choices:Dictionary={}
	var food_severity:=clampf((22.0-float(c.food_days))/22.0,0,1)+clampf((0.97-float(c.food_intake))*4.0,0,1)
	if food_severity>0.05:
		var decree:="Ration food for thirty days" if float(c.food_days)<10.0 else "Send gatherers to find food"
		choices["food"]={"w":food_severity*2.2*relevance.call(["Steward","Quartermaster"]),"summary":"Food stores would last about %d days; people are %s." % [maxi(0,roundi(float(c.food_days))),"already eating less than they need" if float(c.food_intake)<0.97 else "counting portions"],"decree":decree}
	var water_gap:=clampf((0.95-float(c.water_intake))*3.0,0,1)
	var health_gap:=clampf((0.62-float(c.health))*3.0,0,1)
	if water_gap>0.05 or health_gap>0.05:
		var water_first:=water_gap>health_gap
		choices["health"]={"w":maxf(water_gap,health_gap)*2.0*relevance.call(["Steward","Scholar"]),
			"summary":"People are not getting enough clean water; the sick are multiplying." if water_first else "Illness is spreading; health across the settlements has fallen to about %d%%." % roundi(float(c.health)*100),
			"decree":"Secure water and dig wells" if water_first else "Organize healers to care for the sick"}
	var housing_gap:=clampf((1.0-float(c.housing_ratio))*2.5,0,1)
	if housing_gap>0.05:
		var homeless:=maxi(1,roundi(float(c.population)-float(GameState.housing_capacity)))
		choices["housing"]={"w":housing_gap*1.8*relevance.call(["Steward","Quartermaster"]),"summary":"About %d people have no proper shelter." % homeless,"decree":"Build shelters"}
	var security_gap:=clampf((0.36-float(c.security))*2.5,0,1)+clampf((float(c.foreign_threat)-0.45)*1.6,0,1)
	if security_gap>0.05:
		var summary:String="The watch is thin; the settlements feel unsafe." if String(c.threat_name)=="" or float(c.foreign_threat)<0.45 else "%s presses on the frontier and the watch is too thin to answer it." % String(c.threat_name)
		choices["security"]={"w":security_gap*2.0*relevance.call(["Marshal"]),"summary":summary,"decree":"Raise a watch and post guards"}
	var resentment:=float(rel.get("resentment",0))
	var trust:=float(rel.get("trust",0.5))
	if resentment>0.15 or trust<0.35:
		var why:="feels their counsel has been ignored" if trust<0.35 else "nurses a grudge from past slights"
		if float(person.get("pride",0.5))>0.65: why="feels their standing has been insulted"
		choices["grievance"]={"w":(resentment*3.0+maxf(0,0.4-trust)*2.5)*(0.7+float(person.get("pride",0.5))*0.6),"summary":"%s %s." % [String(person.name),why],"decree":""}
	var ambitious:=0.25+(0.6 if "Ambitious" in traits else 0.0)+(0.3 if "Bold" in traits or "Inventive" in traits or "Curious" in traits else 0.0)+(0.25 if String(person.get("doctrine",""))=="directive" else 0.0)
	var ambition_decree:String=String({"Scholar":"Support scholars and fund research","Quartermaster":"Expand workshops and make tools","Marshal":"Post guards and patrol the frontier","Envoy":"Hold a public council to hear the people","Steward":"Improve roads and organize haulers"}.get(office,"Hold a public council to hear the people"))
	if String(person.get("doctrine",""))=="representative": ambition_decree="Hold a public council to hear the people"
	elif "Curious" in traits or "Inventive" in traits: ambition_decree="Support scholars and fund research"
	var ambition_summary:String=String({"Support scholars and fund research":"%s wants more hands set to inquiry, under their eye.","Expand workshops and make tools":"%s wants the workshops enlarged and tools made in earnest.","Post guards and patrol the frontier":"%s wants patrols along the frontier, commanded by them.","Hold a public council to hear the people":"%s wants a public council where the people can be heard.","Improve roads and organize haulers":"%s wants the roads improved and hauling organized."}.get(ambition_decree,"%s has a plan.")) % String(person.name)
	choices["ambition"]={"w":ambitious,"summary":ambition_summary,"decree":ambition_decree}
	var topic:=""
	if forced_topic!="":
		if not choices.has(forced_topic): return {}
		topic=forced_topic
	else:
		var total:=0.0
		for key in choices:
			if open_topics.has(key): choices[key].w=float(choices[key].w)*0.15
			total+=float(choices[key].w)
		if total<0.3 and rng.randf()>total/0.3: return {}
		var roll:=rng.randf()*total
		for key in TOPICS:
			if not choices.has(key): continue
			roll-=float(choices[key].w)
			if roll<=0.0: topic=key; break
		if topic=="": topic="ambition"
	var audience:=_new_audience("court","petition",day)
	audience.speaker={"name":String(person.name),"title":String(person.get("office_title","Official")),"person_id":person_id,"role":"official"}
	audience.petition={"topic":topic,"summary":String(choices[topic].summary),"suggested_decree":String(choices[topic].decree)}
	return audience

static func _topic_words(topic:String)->String:
	return {"food":"the food stores","health":"the sick and the water","housing":"shelter for the people","security":"the watch","grievance":"a personal grievance","ambition":"a proposal of their own"}.get(topic,"a matter of state")

# --------------------------------------------------------------------------
# Court bench
# --------------------------------------------------------------------------

static func court(id:String)->Array[Dictionary]:
	var audience:=find(id)
	var result:Array[Dictionary]=[]
	var speaker_id:=int(audience.get("speaker",{}).get("person_id",0)) if not audience.is_empty() else 0
	for person in _officials():
		if int(person.person_id)==speaker_id: continue
		result.append(person)
		if result.size()>=COURT_MAX: break
	return result

# --------------------------------------------------------------------------
# Options and resolution
# --------------------------------------------------------------------------

static func _terms_text(terms:Dictionary)->String:
	if terms.is_empty(): return ""
	return "%d %s" % [roundi(float(terms.amount)),String(terms.resource)]

static func _courtesy_terms(audience:Dictionary)->Dictionary:
	## A return gift about 40% of what was offered, in whatever the player holds most of.
	var value:=float(audience.terms.get("amount",0))*0.4
	var best:="";var best_stock:=0.0
	for resource in RESOURCES:
		var stock:=player_stock(resource)
		if stock>best_stock: best_stock=stock; best=resource
	if best=="": best=String(audience.terms.get("resource","Food"))
	return {"resource":best,"amount":_nice(maxf(3.0,value))}

static func _reward_terms()->Dictionary:
	var best:="";var best_stock:=0.0
	for resource in RESOURCES:
		var stock:=player_stock(resource)
		if stock>best_stock: best_stock=stock; best=resource
	if best=="": best="Food"
	return {"resource":best,"amount":_nice(clampf(_player_population()*(0.08 if best=="Food" else 0.03),3.0,40.0))}

static func _option(id:String,label:String,sub:String,tone:String,enabled:bool=true,reason:String="")->Dictionary:
	return {"id":id,"label":label,"sub":sub,"enabled":enabled,"reason":"" if enabled else reason,"tone":tone}

static func _short(resource:String,amount:float)->String:
	var have:=player_stock(resource)
	if have+0.0001>=amount: return ""
	return "Your stores hold only %d %s." % [floori(have),resource]

static func options(id:String)->Array[Dictionary]:
	var audience:=find(id)
	var result:Array[Dictionary]=[]
	if audience.is_empty() or String(audience.status)!="waiting": return result
	var terms:Dictionary=audience.terms
	var text:=_terms_text(terms)
	match String(audience.kind):
		"gift":
			var courtesy:=_courtesy_terms(audience)
			var short:=_short(String(courtesy.resource),float(courtesy.amount))
			result.append(_option("accept","Accept the gift","Receive %s from %s." % [text,audience.civ_name],"warm"))
			result.append(_option("accept_return","Accept and send a courtesy gift","Receive %s; send back %s." % [text,_terms_text(courtesy)],"warm",short=="",short))
			result.append(_option("refuse","Refuse the gift","Send it back unopened. They will take offence.","hostile"))
		"request":
			var half:={"resource":terms.resource,"amount":_nice(float(terms.amount)*0.5)}
			var short_full:=_short(String(terms.resource),float(terms.amount))
			var short_half:=_short(String(half.resource),float(half.amount))
			result.append(_option("grant","Grant it in full","Give %s to %s." % [text,audience.civ_name],"warm",short_full=="",short_full))
			result.append(_option("grant_half","Grant half","Give %s and no more." % _terms_text(half),"neutral",short_half=="",short_half))
			result.append(_option("refuse","Refuse","Keep your stores.%s" % (" They are hungry and may not forget it." if _hungry(ForeignDiplomacy.civilization(String(audience.civ_id))) else ""),"hostile"))
		"threat":
			var short_pay:=_short(String(terms.resource),float(terms.amount))
			result.append(_option("pay","Pay the tribute","Hand over %s to ease the frontier." % text,"neutral",short_pay=="",short_pay))
			result.append(_option("defy","Refuse to pay","Send the herald home empty-handed.","hostile"))
			result.append(_option("counter","Answer threat with threat","Warn them your people will meet force at the border.","hostile"))
		"news":
			var reward:=_reward_terms()
			var short_reward:=_short(String(reward.resource),float(reward.amount))
			result.append(_option("thank","Thank the messenger","Courteous thanks; the news is noted.","warm"))
			result.append(_option("reward","Reward the messenger","Send %s home with them." % _terms_text(reward),"warm",short_reward=="",short_reward))
		"great_work","wonder_proposal":
			var gwa:=_great_works()
			if gwa!=null:
				for option:Dictionary in gwa.call("options",audience): result.append(option)
		"report":
			var reward_food:=_scout_reward()
			var short_food:=_short("Food",reward_food)
			result.append(_option("reward_scouts","Well done — reward the scouts","Give the party %d Food from the stores." % roundi(reward_food),"warm",short_food=="",short_food))
			var subject:=String(audience.get("report",{}).get("subject_civ_id",""))
			if subject!="" and not CivilizationSystem._scout_target_option("contact:"+subject).is_empty():
				var proposal:Dictionary=CivilizationSystem.contact_investigation_proposal(subject)
				var sub:String=String(proposal.get("message","Send a party back to look closer.")) if proposal.get("ok",false) else "Send a party back to look closer."
				result.append(_option("send_back","Send them back for a closer look",sub,"neutral",bool(proposal.get("ok",false)),String(proposal.get("error",""))))
			result.append(_option("dismiss","Dismiss","Thank them briefly and move on.","hostile"))
		"petition":
			var petition:Dictionary=audience.petition
			if String(petition.get("topic",""))=="grievance":
				result.append(_option("apologise","Acknowledge the wrong","Admit the slight and make amends in words.","warm"))
				result.append(_option("rebuke","Rebuke them","Remind them whom they serve.","hostile"))
			else:
				var decree:=String(petition.get("suggested_decree",""))
				result.append(_option("decree","Issue their decree","\"%s\"" % decree,"warm",decree!="","They have no decree to propose."))
				result.append(_option("promise","Promise to consider it","Warm words, no order yet.","neutral"))
				result.append(_option("dismiss","Dismiss the petition","Send them away. They will resent it.","hostile"))
	return result

static func resolve(id:String,option_id:String)->Dictionary:
	var audience:=find(id)
	if audience.is_empty() or String(audience.status)!="waiting": return {"ok":false,"outcome":"No audience is waiting.","reaction":"neutral"}
	var chosen:={}
	for option in options(id):
		if String(option.id)==option_id: chosen=option
	if chosen.is_empty(): return {"ok":false,"outcome":"That answer is not open to you here.","reaction":"neutral"}
	if not bool(chosen.enabled): return {"ok":false,"outcome":String(chosen.reason),"reaction":"neutral"}
	var result:Dictionary
	if audience.kind in WORK_KINDS:
		var gwa:=_great_works()
		if gwa==null: return {"ok":false,"outcome":"The master builder has left.","reaction":"neutral"}
		result=gwa.call("resolve",audience,option_id)
		if not bool(result.get("ok",false)): return {"ok":false,"outcome":String(result.get("outcome","That cannot be done now.")),"reaction":"neutral"}
	elif audience.origin=="foreign": result=_resolve_foreign(audience,option_id)
	elif audience.kind=="report": result=_resolve_report(audience,option_id)
	else: result=_resolve_petition(audience,option_id)
	audience.status="resolved"
	audience.outcome=String(result.outcome)
	audience.option_id=option_id
	_archive(audience)
	result["ok"]=true
	return result

static func _mood_opinion(audience:Dictionary)->float:
	return clampf(float(audience.get("mood",0.0)),-1.0,1.0)*MOOD_OPINION

static func _resolve_foreign(audience:Dictionary,option_id:String)->Dictionary:
	var civ_id:=String(audience.civ_id)
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var p:=_personality(civ_id)
	var leader:=ForeignDiplomacy.leader(civ_id)
	var proud:=String(leader.get("temperament",""))=="Proud guardian"
	var terms:Dictionary=audience.terms
	var resource:=String(terms.get("resource",""))
	var amount:=float(terms.get("amount",0))
	var mood:=_mood_opinion(audience)
	var outcome:=""
	var reaction:="neutral"
	var memory:=""
	match "%s:%s" % [audience.kind,option_id]:
		"gift:accept","gift:accept_return":
			var got:=EXCHANGE.take(civ_id,resource,amount)
			var received:=EXCHANGE.receive("player",resource,got) if got>0.0 else 0.0
			outcome="You accepted %d %s from %s." % [roundi(received),resource,audience.civ_name]
			if received+0.5<amount: outcome+=" Only %d of the promised %d actually arrived." % [roundi(received),roundi(amount)]
			if option_id=="accept_return":
				var courtesy:=_courtesy_terms(audience)
				var sent:=_debit_player(String(courtesy.resource),float(courtesy.amount))
				_credit_civ(civ_id,String(courtesy.resource),sent)
				_shift_relation(civ_id,0.08+mood,-0.04)
				_leader_trust(civ_id,0.07)
				outcome+=" You sent %d %s back as a courtesy." % [roundi(sent),String(courtesy.resource)]
				reaction="delighted"
				memory="The ruler received our gift of %d %s and sent %d %s in return. A gracious house." % [roundi(received),resource,roundi(sent),String(courtesy.resource)]
			else:
				_shift_relation(civ_id,0.04+mood,-0.02)
				_leader_trust(civ_id,0.04)
				reaction="pleased"
				memory="The ruler accepted our gift of %d %s." % [roundi(received),resource]
		"gift:refuse":
			var sting:=0.05+(0.04 if proud else 0.0)
			_shift_relation(civ_id,-sting+mood,0.02)
			_leader_trust(civ_id,-0.05)
			reaction="furious" if proud else "offended"
			outcome="You refused %s's gift of %s. It went home unopened; they are %s." % [audience.civ_name,_terms_text(terms),"deeply insulted" if proud else "offended"]
			memory="The ruler refused our gift of %s in front of their court." % _terms_text(terms)
		"request:grant","request:grant_half":
			var give:=amount if option_id=="grant" else _nice(amount*0.5)
			var sent:=_debit_player(resource,give)
			_credit_civ(civ_id,resource,sent)
			var need_bonus:=0.03 if resource=="Food" and _hungry(civ) else 0.0
			if option_id=="grant":
				_shift_relation(civ_id,0.06+need_bonus+mood,-0.05)
				_leader_trust(civ_id,0.06)
				reaction="delighted"
				outcome="You gave %d %s to %s." % [roundi(sent),resource,audience.civ_name]
				memory="We asked for %d %s and the ruler gave all of it." % [roundi(amount),resource]
			else:
				_shift_relation(civ_id,0.02+need_bonus*0.5+mood,-0.02)
				_leader_trust(civ_id,0.02)
				reaction="neutral" if float(p.assertiveness)>0.62 else "pleased"
				outcome="You gave %d %s to %s, half of what they asked." % [roundi(sent),resource,audience.civ_name]
				memory="We asked for %d %s; the ruler gave half." % [roundi(amount),resource]
		"request:refuse":
			var hungry_and_hard:=_hungry(civ) and float(p.assertiveness)>0.55
			_shift_relation(civ_id,-0.03+mood,0.08 if hungry_and_hard else 0.0)
			_leader_trust(civ_id,-0.03)
			reaction="neutral" if float(p.empathy)>0.65 and float(civ.player_relation.get("opinion",0))>0.2 else "offended"
			outcome="You refused %s's request for %s." % [audience.civ_name,_terms_text(terms)]
			if hungry_and_hard: outcome+=" They are hungry and proud; border tension rose."
			memory="We asked the ruler for %s and were refused%s." % [_terms_text(terms)," while our children went hungry" if _hungry(civ) else ""]
		"threat:pay":
			var paid:=_debit_player(resource,amount)
			_credit_civ(civ_id,resource,paid)
			_shift_relation(civ_id,0.02+mood,-0.15)
			reaction="pleased"
			outcome="You paid %d %s in tribute to %s. The frontier eased." % [roundi(paid),resource,audience.civ_name]
			var lost:Array=[]
			for person in court(String(audience.id)):
				if float(person.get("pride",0.5))>0.6:
					GovernmentPeopleSystem.adjust_person_relationship(int(person.person_id),0,-0.05,0.01)
					GovernmentPeopleSystem.record_person_memory(int(person.person_id),"Watched the ruler pay %d %s in tribute to %s." % [roundi(paid),resource,audience.civ_name],"audience",0.5,{"emotion":"shame"})
					lost.append(String(person.name))
			if not lost.is_empty(): outcome+=" %s lost some respect for you." % ", ".join(lost)
			memory="The ruler paid our demand of %d %s. They can be pressed." % [roundi(paid),resource]
		"threat:defy":
			_shift_relation(civ_id,-0.05+mood,0.08)
			_leader_trust(civ_id,-0.04)
			var requested:="call_bluff" if float(p.assertiveness)>0.6 and float(p.risk_tolerance)>0.5 else "warn"
			var posture:=ForeignDiplomacy.apply_conversation_reaction(civ_id,requested,"We will not pay your tribute.","The ruler refused our demand for %s." % _terms_text(terms))
			var actual:=String(posture.get("actual","unchanged"))
			reaction="furious" if actual in ["harden_border","mobilize","call_bluff"] else "offended"
			outcome="You refused %s's demand for %s. %s" % [audience.civ_name,_terms_text(terms),_posture_words(actual,String(audience.civ_name))]
			memory="The ruler refused our demand for %s." % _terms_text(terms)
		"threat:counter":
			_leader_trust(civ_id,-0.05)
			var posture2:=ForeignDiplomacy.apply_conversation_reaction(civ_id,"harden_border","Our armies will meet yours at the border if you come for what is ours.","The ruler answered our demand with a threat of their own.")
			var actual2:=String(posture2.get("actual","unchanged"))
			if mood!=0.0: _shift_relation(civ_id,mood,0.0)
			reaction="furious" if actual2 in ["harden_border","mobilize","call_bluff"] or float(p.assertiveness)>0.55 else "offended"
			outcome="You answered %s's demand with a threat of force. %s" % [audience.civ_name,_posture_words(actual2,String(audience.civ_name))]
			memory="The ruler answered our demand with threats."
		"news:thank":
			_shift_relation(civ_id,0.015+mood,0.0)
			var subject_id:=String(audience.news.get("subject_civ_id",""))
			var learned:=""
			var subject_index:=_civ_index(subject_id)
			if subject_index>=0 and not ForeignDiplomacy.civilization(subject_id).is_empty():
				var subject:Dictionary=WorldSimulation.world.civilizations[subject_index]
				var relation:Dictionary=subject.player_relation
				relation["contact_intelligence"]=clampf(float(relation.get("contact_intelligence",0))+0.05,0.0,1.0)
				subject["player_relation"]=relation
				WorldSimulation.world.civilizations[subject_index]=subject
				learned=" What you know of %s grew a little." % String(subject.get("name",subject_id))
			reaction="pleased"
			outcome="You thanked %s's messenger for news of %s.%s" % [audience.civ_name,String(audience.news.get("subject_civ_name","a neighbor")),learned]
			memory="Our messenger brought the ruler news and was thanked."
		"news:reward":
			var reward:=_reward_terms()
			var sent2:=_debit_player(String(reward.resource),float(reward.amount))
			_credit_civ(civ_id,String(reward.resource),sent2)
			_shift_relation(civ_id,0.04+mood,0.0)
			_leader_trust(civ_id,0.03)
			reaction="delighted"
			outcome="You rewarded %s's messenger with %d %s." % [audience.civ_name,roundi(sent2),String(reward.resource)]
			memory="Our messenger came home with %d %s from the ruler's hand." % [roundi(sent2),String(reward.resource)]
	if memory!="": ForeignDiplomacy.remember(civ_id,memory)
	return {"outcome":outcome,"reaction":reaction}

static func _posture_words(actual:String,name:String)->String:
	match actual:
		"call_bluff": return "%s means to call your bluff; the frontier is close to open conflict." % name
		"mobilize": return "%s is mustering fighters and hardening its border." % name
		"harden_border": return "%s is hardening its border." % name
		"warn": return "%s answered with a warning but did not move." % name
		"conciliate": return "%s chose to calm matters." % name
	return "%s made no change in its posture." % name

static func _resolve_petition(audience:Dictionary,option_id:String)->Dictionary:
	var pid:=int(audience.speaker.person_id)
	var person:=_official(pid)
	var name:=String(audience.speaker.name)
	var petition:Dictionary=audience.petition
	var mood:=_mood_opinion(audience)
	var pride:=float(person.get("pride",0.5))
	var suspicion:=float(person.get("suspicion",0.5))
	var outcome:=""
	var reaction:="neutral"
	var memory:=""
	var emotion:="duty"
	match option_id:
		"decree":
			GovernmentPeopleSystem.adjust_person_relationship(pid,0.06+mood,0.03,-0.03)
			reaction="delighted"; emotion="vindicated"
			outcome="You took up %s's petition and ordered: \"%s\"." % [name,String(petition.suggested_decree)]
			memory="Petitioned about %s; the ruler issued my decree: %s." % [_topic_words(String(petition.topic)),String(petition.suggested_decree)]
		"promise":
			GovernmentPeopleSystem.adjust_person_relationship(pid,0.02+mood,0.0,-0.01)
			reaction="neutral" if suspicion>0.6 else "pleased"; emotion="hope"
			outcome="You promised %s the matter of %s would be considered. No order has been given." % [name,_topic_words(String(petition.topic))]
			memory="Petitioned about %s; the ruler promised to consider it." % _topic_words(String(petition.topic))
		"dismiss":
			GovernmentPeopleSystem.adjust_person_relationship(pid,-0.03+mood,0.0,0.05)
			reaction="furious" if pride>0.7 else "offended"; emotion="slighted"
			outcome="You dismissed %s's petition. Their resentment rose." % name
			memory="Petitioned about %s and was dismissed." % _topic_words(String(petition.topic))
		"apologise":
			GovernmentPeopleSystem.adjust_person_relationship(pid,0.05+mood,0.0,-0.08)
			reaction="pleased"; emotion="relief"
			outcome="You acknowledged %s's grievance. Their resentment eased." % name
			memory="Brought a grievance before the ruler, who acknowledged the wrong."
		"rebuke":
			GovernmentPeopleSystem.adjust_person_relationship(pid,-0.05+mood,0.02,0.06)
			reaction="furious" if pride>0.65 else "offended"; emotion="anger"
			outcome="You rebuked %s before the court. They will remember it." % name
			memory="Brought a grievance before the ruler and was rebuked in front of the court."
	if memory!="": GovernmentPeopleSystem.record_person_memory(pid,memory,"audience",0.6,{"emotion":emotion,"outcome":option_id})
	return {"outcome":outcome,"reaction":reaction}

static func _scout_reward()->float:
	return _nice(clampf(_player_population()*0.05,5.0,30.0))

static func _resolve_report(audience:Dictionary,option_id:String)->Dictionary:
	var pid:=int(audience.speaker.get("person_id",0))
	var name:=String(audience.speaker.name)
	var report:Dictionary=audience.get("report",{})
	var subject:=String(report.get("subject_name","what they found"))
	if subject=="": subject="what they found"
	var mood:=_mood_opinion(audience)
	var outcome:=""
	var reaction:="neutral"
	var memory:=""
	match option_id:
		"reward_scouts":
			var paid:=_debit_player("Food",_scout_reward())
			if pid>0: GovernmentPeopleSystem.adjust_person_relationship(pid,0.05+mood,0.02,-0.02)
			reaction="delighted"
			outcome="You rewarded %s's scouts with %d Food for their report on %s." % [name,roundi(paid),subject]
			memory="Reported on %s; the ruler rewarded my scouts with %d Food." % [subject,roundi(paid)]
		"send_back":
			var sent:Dictionary=CivilizationSystem.investigate_known_contact(String(report.get("subject_civ_id","")))
			if sent.has("error"):
				outcome="The scouts could not be sent back: %s" % String(sent.error)
			else:
				if pid>0: GovernmentPeopleSystem.adjust_person_relationship(pid,0.02+mood,0.02,0.0)
				outcome="You sent %s's scouts back to look closer at %s. %s" % [name,subject,String(sent.get("message",""))]
				reaction="pleased"
				memory="Reported on %s; the ruler sent us back for a closer look." % subject
		"dismiss":
			if pid>0: GovernmentPeopleSystem.adjust_person_relationship(pid,-0.02+mood,0.0,0.03)
			reaction="offended"
			outcome="You heard %s's report on %s and dismissed them." % [name,subject]
			memory="Reported on %s; the ruler barely listened." % subject
	if memory!="" and pid>0: GovernmentPeopleSystem.record_person_memory(pid,memory,"audience",0.5,{"emotion":"pride" if reaction=="delighted" else "duty","outcome":option_id})
	return {"outcome":outcome,"reaction":reaction}

static func enqueue(record:Dictionary)->Dictionary:
	## Accept a prebuilt audience (used for Chief Scout "report"). The hall assigns
	## id, dates and status. Reports are never refused for a full antechamber; the
	## oldest waiting petition is set aside (without penalty) to make room.
	## Returns the stored audience, or {} when the record is invalid.
	var kind:=String(record.get("kind","report"))
	if kind not in KINDS: return {}
	var origin:=String(record.get("origin","court" if kind in COURT_KINDS else "foreign"))
	if origin not in ["foreign","court"] or (origin=="court")!=(kind in COURT_KINDS): return {}
	var speaker:Variant=record.get("speaker",{})
	if not speaker is Dictionary or String(speaker.get("name","")).strip_edges()=="": return {}
	var day:=_day()
	var audience:=_new_audience(origin,kind,day)
	audience.speaker={"name":String(speaker.name).substr(0,100),"title":String(speaker.get("title","")).substr(0,100),
		"person_id":int(speaker.get("person_id",0)) if _num(speaker.get("person_id",0)) else 0,"role":"official" if origin=="court" else "envoy"}
	audience.civ_id=String(record.get("civ_id","")).substr(0,64)
	audience.civ_name=String(record.get("civ_name","")).substr(0,100)
	if kind=="report":
		var report:Variant=record.get("report",{})
		if not _valid_report(report): return {}
		audience.report=(report as Dictionary).duplicate(true)
		if audience.civ_id=="": audience.civ_id=String(report.get("subject_civ_id",""))
		if audience.civ_name=="": audience.civ_name=String(report.get("subject_name",""))
	elif kind=="wonder_proposal":
		var gwp:=_great_works()
		var pitch:Variant=record.get("wonder_proposal",{})
		if gwp==null or not bool(gwp.call("valid_proposal",pitch)): return {}
		audience["wonder_proposal"]=(pitch as Dictionary).duplicate(true)
	elif kind=="great_work":
		var gwa:=_great_works()
		var facts:Variant=record.get("great_work",{})
		if gwa==null or not bool(gwa.call("valid",facts)): return {}
		audience["great_work"]=(facts as Dictionary).duplicate(true)
		if record.get("petition",{}) is Dictionary: audience.petition=(record.get("petition",{}) as Dictionary).duplicate(true)
		# A stage gate waits as long as the council does; other matters keep the usual patience.
		if _num(record.get("expires_day",null)) and int(record.expires_day)>day: audience.expires_day=mini(int(record.expires_day),day+120)
	else:
		for key in ["terms","news","petition"]:
			if record.get(key,{}) is Dictionary: audience[key]=(record.get(key,{}) as Dictionary).duplicate(true)
	var lines:Array=[]
	if record.get("lines") is Array:
		for line in record.lines:
			if line is Dictionary: lines.append(line)
	if not _valid_audience(audience): return {}
	if waiting().size()>=QUEUE_MAX:
		for old in waiting():
			if old.kind=="petition":
				old.status="expired"
				old.outcome="Set aside so %s could be heard; %s may ask again." % ["a great work" if kind in WORK_KINDS else "the scouts' report",String(old.speaker.name)]
				_archive(old)
				break
	_enqueue(audience,day)
	for line in lines: append_line(String(audience.id),line)
	return audience

static func _valid_report(report:Variant)->bool:
	if not report is Dictionary: return false
	if not report.get("facts",[]) is Array or (report.get("facts",[]) as Array).size()>REPORT_FACTS_MAX: return false
	for fact in report.get("facts",[]):
		if fact is String:
			if String(fact).length()>600: return false
		elif fact is Dictionary:
			if JSON.stringify(fact).length()>1200: return false
		else: return false
	if not report.get("subject_civ_id","") is String or not report.get("subject_name","") is String: return false
	if report.has("source") and report.source not in REPORT_SOURCES: return false
	if report.has("observed_day") and not _num(report.observed_day): return false
	return true

## Wonder proposals: the ruler's current pick and a vision described in words.
static func proposal_choice(id:String,choice:Dictionary)->Dictionary:
	var audience:=find(id)
	var gwp:=_great_works()
	if audience.is_empty() or String(audience.status)!="waiting" or audience.kind!="wonder_proposal" or gwp==null: return {"error":"No proposal is before you."}
	return gwp.call("set_choice",audience,choice)

static func proposal_describe(id:String,text:String,mapping:Dictionary={})->Dictionary:
	var audience:=find(id)
	var gwp:=_great_works()
	if audience.is_empty() or String(audience.status)!="waiting" or audience.kind!="wonder_proposal" or gwp==null: return {"error":"No proposal is before you."}
	return gwp.call("describe",audience,text,mapping)

static func defer(id:String)->void:
	var audience:=find(id)
	if audience.is_empty() or String(audience.status)!="waiting": return
	audience["deferred_day"]=_day()

# --------------------------------------------------------------------------
# Scene support
# --------------------------------------------------------------------------

static func append_line(id:String,line:Dictionary)->void:
	var audience:=find(id)
	if audience.is_empty(): return
	var clean:={
		"speaker":String(line.get("speaker","")).substr(0,80),
		"role":String(line.get("role","narrator")) if String(line.get("role","")) in ["envoy","official","ruler","narrator"] else "narrator",
		"person_id":int(line.get("person_id",0)) if (line.get("person_id",0) is int or line.get("person_id",0) is float) else 0,
		"civ_id":String(line.get("civ_id","")).substr(0,64),
		"text":String(line.get("text","")).strip_edges().substr(0,1200),
		"day":int(line.get("day",_day())) if (line.get("day") is int or line.get("day") is float) else _day(),
		"aside":bool(line.get("aside",false)),
	}
	if clean.text=="": return
	var lines:Array=audience.lines
	lines.append(clean)
	while lines.size()>LINES_MAX: lines.remove_at(0)

static func apply_mood(id:String,shift:float)->void:
	var audience:=find(id)
	if audience.is_empty() or String(audience.status)!="waiting" or not is_finite(shift): return
	audience.mood=clampf(float(audience.get("mood",0.0))+clampf(shift,-0.25,0.25),-1.0,1.0)

static func _words(value:float,bands:Array)->String:
	## bands: [[threshold,word],...] ascending; first threshold value<= wins.
	for band in bands:
		if value<=float(band[0]): return String(band[1])
	return String(bands[-1][1])

static func voice_context(id:String)->Dictionary:
	var audience:=find(id)
	if audience.is_empty(): return {}
	var c:=conditions()
	var context:={
		"audience_id":id,"origin":audience.origin,"kind":audience.kind,"status":audience.status,
		"speaker":(audience.speaker as Dictionary).duplicate(),"terms":(audience.terms as Dictionary).duplicate(),"terms_text":_terms_text(audience.terms),
		"news":(audience.news as Dictionary).duplicate(),"petition":(audience.petition as Dictionary).duplicate(),"report":(audience.get("report",{}) as Dictionary).duplicate(true),
		"days_waiting":_day()-int(audience.arrived_day),"days_until_leaving":int(audience.expires_day)-_day(),"mood":float(audience.mood),
		"player_settlement":String(GameState.settlement_name),"player_population":roundi(float(c.population)),
		"food_situation":_words(float(c.food_days),[[7,"the stores are nearly empty"],[16,"food is short"],[35,"food is adequate but not generous"],[1e9,"the stores are well stocked"]]),
		"health_situation":_words(float(c.health),[[0.45,"sickness is widespread"],[0.62,"many are unwell"],[1e9,"people are mostly healthy"]]),
		"housing_situation":"some people lack shelter" if float(c.housing_ratio)<1.0 else "everyone has a roof",
		"court":[],
	}
	if not audience.terms.is_empty():
		context["player_stock_of_terms"]=floori(player_stock(String(audience.terms.resource)))
	for person in court(id):
		context.court.append({"name":String(person.name),"title":String(person.get("office_title","")),"person_id":int(person.person_id),"disposition":String(GovernmentPeopleSystem.leader_disposition(person).get("id","pragmatic")),"traits":(person.get("traits",[]) as Array).duplicate()})
	if audience.origin=="foreign":
		var civ:=ForeignDiplomacy.civilization(String(audience.civ_id))
		var leader:=ForeignDiplomacy.leader(String(audience.civ_id))
		var relation:Dictionary=civ.get("player_relation",{})
		var wars:Array=[]
		if bool(relation.get("at_war",false)): wars.append("at war with the ruler's people")
		for other_id in (civ.get("relations",{}) as Dictionary):
			if bool(civ.relations[other_id].get("at_war",false)):
				var index:=_civ_index(String(other_id))
				if index>=0: wars.append("at war with %s" % String(WorldSimulation.world.civilizations[index].get("name",other_id)))
		var goals:Array=[]
		for goal in leader.get("goals",[]): goals.append(String(goal.get("title","")))
		context["civ"]={"id":String(audience.civ_id),"name":String(audience.civ_name),"population":roundi(float(civ.get("population",0))),"strategy":String(civ.get("strategy","")),
			"opinion":_words(float(relation.get("opinion",0)),[[-0.4,"hostile"],[-0.1,"cool"],[0.15,"wary but civil"],[0.4,"friendly"],[1e9,"warm"]]),
			"border":_words(float(relation.get("border_tension",0)),[[0.2,"quiet"],[0.45,"watchful"],[0.7,"tense"],[1e9,"on the edge of violence"]]),
			"at_war_with_player":bool(relation.get("at_war",false)),"treaty":String(relation.get("treaty","none")),"wars":wars,
			"food":_words(float(civ.get("food_days",30)),[[12,"going hungry"],[22,"short of food"],[60,"fed"],[1e9,"well provisioned"]])}
		context["leader"]={"name":String(leader.get("name","")),"temperament":String(leader.get("temperament","")),"bio":String(leader.get("bio","")),"goals":goals.slice(0,3),
			"trust":_words(float(leader.get("trust",0)),[[-0.3,"distrustful"],[0.1,"undecided"],[1e9,"trusting"]])}
	else:
		if audience.kind in WORK_KINDS:
			var gwa:=_great_works()
			if gwa!=null: context["wonder_proposal" if audience.kind=="wonder_proposal" else "great_work"]=gwa.call("voice_facts",audience)
		var person:=_official(int(audience.speaker.person_id))
		if not person.is_empty():
			var rel:Dictionary=person.get("relationships",{}).get("sovereign",{})
			context["petitioner"]={"name":String(person.name),"title":String(person.get("office_title","")),"traits":(person.get("traits",[]) as Array).duplicate(),"background":String(person.get("background","")),"doctrine":String(person.get("doctrine","")),
				"disposition":String(GovernmentPeopleSystem.leader_disposition(person).get("id","pragmatic")),
				"trust":_words(float(rel.get("trust",0.5)),[[0.35,"low"],[0.65,"moderate"],[1e9,"high"]]),"resentment":_words(float(rel.get("resentment",0)),[[0.1,"none"],[0.3,"some"],[1e9,"deep"]])}
	return context

static func debug_force(kind:String,civ_id:String="")->Dictionary:
	## Test/capture helper: create one audience now, bypassing pacing but never
	## the truth rules (no audience if the stores cannot back it).
	if kind not in KINDS: return {}
	var day:=_day()
	var audience:={}
	if kind=="report":
		return _debug_report(civ_id)
	if kind=="wonder_proposal":
		var gwp:=_great_works()
		if gwp==null: return {}
		var pitched:Dictionary=gwp.call("proposal_audience",{"trigger":{"kind":"debug","text":"A test of the court's imagination."}})
		if pitched.is_empty(): pitched=gwp.call("ruler_proposal")
		return pitched
	if kind=="great_work":
		## civ_id may name a work id; the first pending stage gate otherwise.
		var gwa:=_great_works()
		if gwa==null: return {}
		for pending in gwa.call("api_list","pending_decisions"):
			if not pending is Dictionary: continue
			if civ_id!="" and String(pending.get("work_id",""))!=civ_id: continue
			var made:Dictionary=gwa.call("decision_audience",String(pending.get("work_id","")),String(pending.get("city_id","")))
			if not made.is_empty(): return made
			for waiting_audience in waiting():
				if String(waiting_audience.kind)=="great_work" and String((waiting_audience.get("great_work",{}) as Dictionary).get("work_id",""))==String(pending.get("work_id","")): return waiting_audience
		return {}
	if kind=="petition":
		var topic:=civ_id if civ_id in TOPICS else ""
		for person in _officials():
			audience=_generate_petition(int(person.person_id),day,topic)
			if not audience.is_empty(): break
	else:
		var ids:Array=[civ_id] if civ_id!="" else []
		if ids.is_empty():
			for civ in WorldSimulation.world.civilizations: ids.append(String(civ.get("id","")))
		for id in ids:
			if ForeignDiplomacy.civilization(String(id)).is_empty(): continue
			audience=_generate_foreign(String(id),day,kind)
			if not audience.is_empty(): break
	if audience.is_empty(): return {}
	_enqueue(audience,day)
	return audience

static func _debug_report(civ_id:String)->Dictionary:
	## Build a report from real facts about a contacted civilization.
	var civ:={}
	for candidate in WorldSimulation.world.civilizations:
		var id:=String(candidate.get("id",""))
		if (civ_id=="" or id==civ_id) and not ForeignDiplomacy.civilization(id).is_empty(): civ=candidate; break
	if civ.is_empty(): return {}
	var speaker:=GovernmentPeopleSystem.officeholder("ChiefScout")
	if speaker.is_empty():
		var officials:=_officials()
		speaker=officials[0] if not officials.is_empty() else {"name":"A returning scout","office_title":"Scout","person_id":0}
	var pop:=float(civ.get("population",0))
	var facts:Array=[
		{"kind":"population","text":"about %d people" % (roundi(pop/10.0)*10),"value":roundi(pop),"certainty":0.6},
		{"kind":"strategy","text":String(civ.get("strategy","")),"certainty":0.5},
		{"kind":"food","text":"granaries low" if float(civ.get("food_days",30))<22 else "granaries full","certainty":0.5},
	]
	return enqueue({"kind":"report","origin":"court","speaker":{"name":String(speaker.name),"title":String(speaker.get("office_title","Chief Scout")),"person_id":int(speaker.get("person_id",0))},
		"report":{"facts":facts,"subject_civ_id":String(civ.id),"subject_name":String(civ.get("name","")),"source":"scouts","observed_day":maxi(0,_day()-4)}})

# --------------------------------------------------------------------------
# Save validation
# --------------------------------------------------------------------------

static func _num(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func validate_state(data:Variant)->bool:
	if not data is Dictionary: return false
	if (data as Dictionary).is_empty(): return true
	for key in ["queue","history"]:
		if not data.get(key,[]) is Array or (data.get(key,[]) as Array).size()>(QUEUE_MAX*4 if key=="queue" else HISTORY_MAX): return false
		for audience in data.get(key,[]):
			if not _valid_audience(audience): return false
	for key in ["next_foreign","next_court"]:
		if not data.get(key,{}) is Dictionary or (data.get(key,{}) as Dictionary).size()>256: return false
		for entry in data.get(key,{}):
			if not entry is String or not _num(data[key][entry]): return false
	for key in ["last_arrival_day","serial"]:
		if data.has(key) and not _num(data[key]): return false
	if data.has("summon_immediately") and not data.summon_immediately is bool: return false
	return true

static func _valid_audience(a:Variant)->bool:
	if not a is Dictionary: return false
	if not a.has_all(["id","origin","kind","civ_id","speaker","arrived_day","expires_day","status","lines","mood"]): return false
	if not a.id is String or a.origin not in ["foreign","court"] or a.kind not in KINDS or a.status not in ["waiting","resolved","expired"]: return false
	if not a.civ_id is String or not a.speaker is Dictionary or String(a.speaker.get("name","")).length()>100: return false
	if not _num(a.arrived_day) or not _num(a.expires_day) or not _num(a.mood) or absf(float(a.mood))>1.0: return false
	if not a.lines is Array or a.lines.size()>LINES_MAX: return false
	for line in a.lines:
		if not line is Dictionary or not line.get("text","") is String or String(line.get("text","")).length()>2000: return false
	var terms:Variant=a.get("terms",{})
	if not terms is Dictionary: return false
	if not (terms as Dictionary).is_empty() and (terms.get("resource","") not in RESOURCES or not _num(terms.get("amount")) or float(terms.amount)<0): return false
	if not a.get("news",{}) is Dictionary or not a.get("petition",{}) is Dictionary: return false
	var topic:=String((a.get("petition",{}) as Dictionary).get("topic",""))
	if a.kind=="petition" and topic not in TOPICS: return false
	if a.kind=="report" and not _valid_report(a.get("report",{})): return false
	if a.kind=="great_work":
		var gwa:=_great_works()
		if gwa==null or not bool(gwa.call("valid",a.get("great_work",{}))): return false
	if a.kind=="wonder_proposal":
		var gwp:=_great_works()
		if gwp==null or not bool(gwp.call("valid_proposal",a.get("wonder_proposal",{}))): return false
	return true
