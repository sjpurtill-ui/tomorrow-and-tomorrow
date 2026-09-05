extends Node
## A bounded cast of named people who embody government. The population remains
## aggregate; these records are actual members sampled from it, not extra people
## and not one runtime entity per citizen. At planetary scale the cast remains
## capped while offices, titles, experience, succession, and local delegation
## continue to matter.

const ValuesModel:=preload("res://scripts/societal_values_model.gd")
const MAX_GOVERNMENT_PEOPLE:=96
const MAX_PERSON_MEMORIES:=20
const MONTH_DAYS:=30

const GIVEN_NAMES:=[
	"Alda","Ansel","Arin","Bera","Cassian","Dara","Edda","Elian","Enna","Farid","Galen","Hana",
	"Ilya","Iona","Joren","Kaia","Leif","Mara","Niko","Oren","Rhea","Sana","Tarin","Vera",
]
const FAMILY_NAMES:=[
	"Alder","Ashfield","Briar","Cairn","Dawn","Ember","Farrow","Flint","Grove","Hearth","Ivers",
	"Kestrel","Lark","Morrow","North","Oak","Reed","Stone","Thorne","Vale","Ward","Wells","Yarrow","Wren",
]
const TRAITS:=[
	"Patient","Forceful","Curious","Methodical","Warm","Skeptical","Bold","Cautious","Frugal","Generous",
	"Traditional","Inventive","Diplomatic","Severe","Pragmatic","Principled","Ambitious","Humble",
]
const SKILL_KEYS:=["Administration","Provisioning","Construction","Logistics","Knowledge","Defense","Diplomacy"]
const OFFICE_SKILL_WEIGHTS:Dictionary={
	"Steward":{"Administration":0.48,"Diplomacy":0.22,"Provisioning":0.18,"Knowledge":0.12},
	"Quartermaster":{"Provisioning":0.46,"Logistics":0.30,"Administration":0.14,"Construction":0.10},
	"Marshal":{"Defense":0.50,"Administration":0.18,"Logistics":0.17,"Knowledge":0.15},
	"Scholar":{"Knowledge":0.62,"Administration":0.18,"Diplomacy":0.12,"Logistics":0.08},
	"Envoy":{"Diplomacy":0.54,"Logistics":0.22,"Knowledge":0.14,"Administration":0.10},
	"SettlementLeader":{"Administration":0.32,"Provisioning":0.23,"Construction":0.18,"Logistics":0.15,"Diplomacy":0.12},
}
const DYNAMIC_SKILL_WEIGHTS:Dictionary={
	"demography":{"Provisioning":0.48,"Diplomacy":0.32,"Knowledge":0.20},
	"nutrition":{"Provisioning":0.62,"Logistics":0.23,"Knowledge":0.15},
	"health":{"Provisioning":0.42,"Knowledge":0.38,"Administration":0.20},
	"labor":{"Administration":0.52,"Construction":0.28,"Diplomacy":0.20},
	"knowledge":{"Knowledge":0.68,"Administration":0.20,"Diplomacy":0.12},
	"production":{"Construction":0.48,"Logistics":0.32,"Knowledge":0.20},
	"infrastructure":{"Construction":0.58,"Administration":0.24,"Logistics":0.18},
	"logistics":{"Logistics":0.62,"Administration":0.23,"Diplomacy":0.15},
	"ecology":{"Knowledge":0.50,"Provisioning":0.30,"Logistics":0.20},
	"institutions":{"Administration":0.58,"Diplomacy":0.28,"Knowledge":0.14},
	"security":{"Defense":0.62,"Administration":0.23,"Logistics":0.15},
	"culture":{"Diplomacy":0.58,"Knowledge":0.27,"Administration":0.15},
}
# Compatibility is deliberately one-way: new people are authored with the seven
# canonical skills above, while surviving saves and older systems can ask for a
# more specific aptitude and receive a transparent composite rather than a
# silent default of 35.
const LEGACY_SKILL_WEIGHTS:Dictionary={
	"Agriculture":{"Provisioning":0.78,"Knowledge":0.22},
	"Medicine":{"Provisioning":0.50,"Knowledge":0.38,"Administration":0.12},
	"Research":{"Knowledge":0.82,"Administration":0.18},
	"Education":{"Knowledge":0.62,"Diplomacy":0.23,"Administration":0.15},
	"Manufacturing":{"Construction":0.58,"Logistics":0.27,"Knowledge":0.15},
	"Engineering":{"Construction":0.62,"Knowledge":0.23,"Logistics":0.15},
	"Delegation":{"Administration":0.66,"Diplomacy":0.22,"Logistics":0.12},
	"Trade":{"Logistics":0.55,"Diplomacy":0.35,"Administration":0.10},
	"Natural Science":{"Knowledge":0.72,"Provisioning":0.18,"Logistics":0.10},
	"Law":{"Administration":0.68,"Diplomacy":0.20,"Knowledge":0.12},
	"Strategy":{"Defense":0.58,"Knowledge":0.24,"Logistics":0.18},
	"Tactics":{"Defense":0.62,"Knowledge":0.23,"Logistics":0.15},
	"Public Order":{"Defense":0.52,"Administration":0.38,"Diplomacy":0.10},
	"Oratory":{"Diplomacy":0.72,"Administration":0.18,"Knowledge":0.10},
	"Coalition Building":{"Diplomacy":0.58,"Administration":0.30,"Logistics":0.12},
	"Empathy":{"Diplomacy":0.62,"Provisioning":0.25,"Knowledge":0.13},
	"Discipline":{"Administration":0.45,"Defense":0.35,"Construction":0.20},
	"Judgment":{"Administration":0.42,"Knowledge":0.38,"Diplomacy":0.20},
	"Creativity":{"Knowledge":0.55,"Construction":0.25,"Diplomacy":0.20},
	"Stress Tolerance":{"Defense":0.45,"Administration":0.35,"Provisioning":0.20},
}
const CANONICAL_FROM_LEGACY:Dictionary={
	"Administration":["Administration","Delegation","Law","Public Order"],
	"Provisioning":["Agriculture","Medicine"],
	"Construction":["Construction","Engineering","Manufacturing"],
	"Logistics":["Logistics","Trade"],
	"Knowledge":["Research","Education","Natural Science"],
	"Defense":["Strategy","Tactics","Public Order","Discipline"],
	"Diplomacy":["Diplomacy","Oratory","Coalition Building","Empathy"],
}
const BASE_ALLOCATIONS:Dictionary={"Food":42.0,"Survey":8.0,"Extraction":11.0,"Construction":11.0,"Crafting":7.0,"Logistics":7.0,"Knowledge":6.0,"Administration":4.0,"Defense":4.0}
const FOCUS_LABELS:Dictionary={
	"establishment":"ESTABLISH THE PLACE","water":"IMPROVE WATER SUPPLY","provisions":"SECURE PROVISIONS",
	"logistics":"IMPROVE LOCAL LOGISTICS","shelter":"BUILD SHELTER","defense":"HOLD THE GROUND","development":"DEVELOP LOCAL CAPACITY","research":"EXPAND RESEARCH","balanced":"BALANCED STEWARDSHIP",
}
const FOCUS_EFFECTS:Dictionary={
	"logistics":"More labor goes to carrying, route work, and coordinating deliveries.",
	"establishment":"More labor goes to building, carrying, provisioning, and basic coordination.",
	"water":"More labor goes to finding water, improving access, and carrying it reliably.",
	"provisions":"More labor goes to food production, carrying, and surveying.",
	"shelter":"More labor goes to construction, materials, and carrying.",
	"defense":"More labor goes to the watch, supply, and defensive works.",
	"development":"More labor goes to construction, extraction, craft, and research.",
	"research":"More labor goes to research, field observation, and preserving knowledge.",
	"balanced":"Labor remains spread across ordinary local needs.",
}
const PUBLIC_STRENGTHS:Dictionary={
	"Administration":"People recall them settling obligations and disputes without losing track of either",
	"Provisioning":"They are repeatedly trusted with harvests, stores, and lean seasons",
	"Construction":"Their name is attached to works that were actually finished",
	"Logistics":"They have a reputation for getting people and goods where they were promised",
	"Knowledge":"Others rely on their observations and memory when accounts conflict",
	"Defense":"They are known for organizing watches and keeping people ready",
	"Diplomacy":"They have ended quarrels and carried difficult messages without worsening them",
}
const PUBLIC_DOUBTS:Dictionary={
	"Administration":"Complicated obligations may outrun their record",
	"Provisioning":"Scarcity may expose gaps in their judgment of stores and supply",
	"Construction":"They have little visible record of organizing difficult works",
	"Logistics":"Long routes and competing demands may exceed what they have managed before",
	"Knowledge":"Their conclusions are not yet trusted when evidence is incomplete",
	"Defense":"It is unclear how they would act under threat or sustained pressure",
	"Diplomacy":"Their handling of rivals and divided loyalties remains uncertain",
}

var people:Array[Dictionary]=[]
var next_person_id:=1
var last_processed_month:=-1
var government_stage:=0
var revision:=0
var initializing:=false


func reset_for_new_world()->void:
	people=[]
	next_person_id=1
	last_processed_month=-1
	government_stage=0
	revision=0
	initializing=false


func initialize(reconcile_stage:bool=true)->void:
	if "Hearth Circle" not in GameState.settlement_completed or GameState.player_settlements.is_empty(): return
	if initializing: return
	initializing=true
	# Re-evaluate the structure when a save is opened as well as when a new world
	# begins. Earlier builds allowed abstract institutional capacity to create a
	# modern-sized cabinet in a settlement of 120 people; this also migrates those
	# worlds back to a government their actual civic scale can support.
	if people.is_empty():
		_update_government_stage(false)
	elif reconcile_stage and _stage_from_conditions()<government_stage:
		# A read-only panel may repair an impossible oversized legacy structure, but
		# normal expansion waits for process_day so it receives a dated event.
		_update_government_stage(false)
	_ensure_pool()
	_synchronize_office_holders()
	_ensure_local_leaders()
	_sync_advisor_roster()
	initializing=false


func process_day(day:int)->Array[Dictionary]:
	# Let the dated monthly transition below record expansion or consolidation;
	# ordinary UI initialization may reconcile an older save silently.
	initialize(false)
	if people.is_empty(): return []
	var month:=day/MONTH_DAYS
	# Local leaders rebalance ordinary labor every day. Mortality, succession and
	# institutional expansion remain monthly, but survival cannot wait up to thirty
	# days for the next government tick.
	if month<=last_processed_month:
		_delegate_settlements(day)
		return []
	last_processed_month=month
	# Treat the monthly transaction as one synchronization pass. Candidate lookup
	# must not recursively initialize the system midway through succession, or it
	# can perform the appointment before the dated event is recorded.
	initializing=true
	var events:Array[Dictionary]=[]
	_process_lifespans(day,events)
	_update_government_stage(true,events)
	_ensure_pool()
	_synchronize_office_holders(events,true)
	_ensure_local_leaders(events)
	_delegate_settlements(day)
	_sync_advisor_roster()
	initializing=false
	return events


func _stage_from_conditions()->int:
	var population:=GameState.population_total
	var settlements:=GameState.player_settlements.size()
	var institutions:=clampf(float(GameState.society_capacities.get("institutions",0.0)),0.0,1.0)
	var stage:=0
	# Offices appear because there is enough real work to divide, not because an
	# abstract capacity number crossed a line. Institutions can delay the more
	# complex layers, but can never conjure them without people or places.
	if population>=220 or settlements>=2: stage=1
	if (population>=700 or settlements>=3) and institutions>=0.28: stage=2
	if (population>=2200 or settlements>=5) and institutions>=0.38: stage=3
	if (population>=8000 or settlements>=8) and institutions>=0.52: stage=4
	# Hysteresis preserves an established office through an ordinary downturn,
	# while a true collapse (including an old 120-person/stage-five save) sheds a
	# bureaucracy the remaining society can no longer sustain.
	if government_stage>=1 and (population>=160 or settlements>=2): stage=maxi(stage,1)
	if government_stage>=2 and (population>=500 or settlements>=3) and institutions>=0.22: stage=maxi(stage,2)
	if government_stage>=3 and (population>=1600 or settlements>=4) and institutions>=0.30: stage=maxi(stage,3)
	if government_stage>=4 and (population>=6000 or settlements>=7) and institutions>=0.42: stage=maxi(stage,4)
	return stage


func _update_government_stage(record_event:bool,events:Array[Dictionary]=[])->void:
	var previous:=government_stage
	government_stage=_stage_from_conditions()
	if government_stage==previous: return
	revision+=1
	if record_event:
		var expanded:=government_stage>previous
		var event:Dictionary={"day":int(GameState.elapsed_days),"title":"Government Expanded" if expanded else "Government Consolidated","description":"Population, distance, and institutional work now require additional named officeholders. Government remains a bounded cast of people, not an abstract cabinet." if expanded else "The surviving population and settlements can no longer sustain every specialized office. Their responsibilities return to the remaining general government.","domain":"institutions","severity":"major"}
		events.append(event)
		GameState.simulation_events.push_front(event)
		if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)


func government_form()->String:
	var identity:Dictionary=ValuesModel.identity_snapshot(GameState.societal_values)
	var name:=String(identity.get("name","FEDERATED FORMING ORDER")).to_upper()
	if name.begins_with("CENTRALIZED"): return "centralized"
	if name.begins_with("LOCALIST"): return "localist"
	return "federated"


func structure_snapshot()->Dictionary:
	initialize()
	return {
		"stage":government_stage,"form":government_form(),"name":String(ValuesModel.identity_snapshot(GameState.societal_values).get("name","Forming Order")),
		"scope":government_scope(),"active_offices":active_offices(),"living_people":living_people().size(),"pool_limit":MAX_GOVERNMENT_PEOPLE,"revision":revision,
	}


func government_scope()->String:
	return ["founding council","settlement offices","town administration","regional government","territorial government"][clampi(government_stage,0,4)]


func active_offices()->Array[Dictionary]:
	var definitions:Array[Dictionary]=[
		{"key":"Steward","unlock":0,"titles":{"centralized":["Hearth Chief","Chief Steward","First Administrator","First Minister","Executive Minister"],"federated":["First Speaker","Senior Steward","Council Speaker","First Councillor","Federal Convenor"],"localist":["Hearth Elder","Settlement Speaker","Civic Convenor","Senior Delegate","Commonwealth Speaker"]}},
		{"key":"Quartermaster","unlock":1,"titles":{"centralized":["Keeper of Stores","Chief Provisioner","Supply Prefect","Minister of Stores","Supply Minister"],"federated":["Storekeeper","Provisioning Delegate","Supply Councillor","Provisioning Secretary","Federal Quartermaster"],"localist":["Stores Keeper","Market Steward","Provisioning Convenor","Supply Delegate","Commons Provisioner"]}},
		{"key":"Marshal","unlock":2,"titles":{"centralized":["Watch Captain","War Leader","Security Prefect","Marshal","Defense Minister"],"federated":["Watch Speaker","Defense Delegate","Defense Councillor","Federal Marshal","Defense Secretary"],"localist":["Watch Keeper","Shield Speaker","Defense Convenor","Militia Delegate","Commons Marshal"]}},
		{"key":"Scholar","unlock":3,"titles":{"centralized":["Lore Keeper","Keeper of Records","Chief Examiner","Chancellor of Inquiry","Knowledge Minister"],"federated":["Memory Keeper","Inquiry Delegate","Learned Councillor","Research Secretary","Federal Chancellor"],"localist":["Story Keeper","Learning Speaker","Inquiry Convenor","Scholars' Delegate","Commons Chancellor"]}},
		{"key":"Envoy","unlock":4,"titles":{"centralized":["Messenger","Chief Emissary","Treaty Prefect","Foreign Secretary","Foreign Minister"],"federated":["Peace Messenger","Emissary Delegate","Treaty Councillor","Federal Envoy","External Secretary"],"localist":["Road Messenger","Guest Speaker","Treaty Convenor","Foreign Delegate","Commons Envoy"]}},
	]
	var result:Array[Dictionary]=[]
	var form:=government_form()
	for definition in definitions:
		if government_stage<int(definition.unlock): continue
		var titles:Array=definition.titles.get(form,definition.titles.federated)
		var title:=String(titles[clampi(government_stage,0,titles.size()-1)])
		result.append({"key":String(definition.key),"title":title,"unlock_stage":int(definition.unlock)})
	return result


func office_definition(office_key:String)->Dictionary:
	for office in active_offices():
		if String(office.key)==office_key: return office
	return {"key":office_key,"title":office_key,"unlock_stage":99}


func settlement_leader_title()->String:
	var form:=government_form()
	var titles:Dictionary={
		"centralized":["Hearth Steward","Appointed Steward","District Prefect","Governor","Regional Administrator"],
		"federated":["Hearth Speaker","Settlement Delegate","Town Speaker","Mayor","Regional Convenor"],
		"localist":["Hearth Elder","Local Speaker","Town Convenor","Mayor","Commons Delegate"],
	}
	var options:Array=titles.get(form,titles.federated)
	return String(options[clampi(government_stage,0,options.size()-1)])


func leader_disposition(person:Dictionary)->Dictionary:
	## Public demeanor is derived from durable personality and relationship state.
	## It changes how a leader speaks and whether they resist an instruction, not
	## the physical outcome of work they lack people or materials to perform.
	if person.is_empty(): return {"id":"unavailable","label":"UNAVAILABLE","description":"No appointed person can answer."}
	var personality:Dictionary=person.get("personality",{})
	var relationship:Dictionary=person.get("relationships",{}).get("sovereign",{})
	var traits:Array=person.get("traits",[])
	var courage:=float(person.get("courage",0.5))
	var honesty:=float(person.get("honesty",0.5))
	var pride:=float(person.get("pride",0.5))
	var suspicion:=float(person.get("suspicion",0.5))
	var fear:=float(relationship.get("fear",0.0))
	var trust:=float(relationship.get("trust",0.5))
	if (courage<0.38 and fear>0.22) or (honesty<0.40 and float(personality.get("assertiveness",0.5))<0.48):
		return {"id":"sycophantic","label":"EAGERLY DEFERENTIAL","description":"Quick to praise and agree; apparent enthusiasm is not proof of sound execution."}
	if suspicion>0.66 or (pride>0.68 and trust<0.48) or "Skeptical" in traits or "Severe" in traits:
		return {"id":"cantankerous","label":"CANTANKEROUS","description":"Challenges instructions, emphasizes flaws, and may demand explicit insistence."}
	if "Principled" in traits or (honesty>0.72 and courage>0.58):
		return {"id":"principled","label":"PLAIN-SPOKEN","description":"Answers directly and may refuse instructions judged indefensible."}
	if float(personality.get("empathy",0.5))>0.68 or "Diplomatic" in traits or "Warm" in traits:
		return {"id":"diplomatic","label":"DIPLOMATIC","description":"Seeks workable compromise and explains human costs before committing."}
	return {"id":"pragmatic","label":"PRAGMATIC","description":"Judges instructions mainly by feasibility, cost, and likely compliance."}


func _desired_pool_size()->int:
	# A hearth-sized polity should contain a handful of recognizable public
	# figures, not a miniature modern bureaucracy. The cast grows only when
	# places and specialist offices create real work for it.
	return clampi(3+government_stage*4+GameState.player_settlements.size()*2+active_offices().size(),6,MAX_GOVERNMENT_PEOPLE)


func _ensure_pool()->void:
	var target:=mini(_desired_pool_size(),maxi(1,GameState.population_total))
	while living_people().size()<target and people.size()<MAX_GOVERNMENT_PEOPLE:
		people.append(_generate_person(next_person_id))
		next_person_id+=1
		revision+=1


func _generate_person(person_id:int)->Dictionary:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:government_person:%d" % [GameState.world_seed,person_id])
	var name:="%s %s" % [GIVEN_NAMES[posmod(person_id*7+rng.randi(),GIVEN_NAMES.size())],FAMILY_NAMES[posmod(person_id*11+rng.randi(),FAMILY_NAMES.size())]]
	for existing in people:
		if String(existing.get("name",""))==name:
			name="%s %s" % [name,String.chr(65+posmod(person_id,26))]
			break
	var age:=rng.randi_range(18,58)
	var life_expectancy:=clampf(GameState.projected_life_expectancy()+18.0,48.0,88.0)
	var death_age:=clampf(rng.randfn(life_expectancy,11.5),maxf(36.0,float(age)+2.0),105.0)
	var skills:Dictionary={}
	for skill in SKILL_KEYS: skills[skill]=clampi(roundi(rng.randfn(47.0,11.0)),22,72)
	# Every public figure has an intelligible comparative advantage and a real
	# limitation. This prevents a candidate slate of statistically identical
	# generalists while still allowing rare broadly capable people.
	var primary_index:=posmod(person_id-1+int(GameState.world_seed%SKILL_KEYS.size()),SKILL_KEYS.size())
	var secondary_index:=posmod(primary_index+2+rng.randi_range(0,2),SKILL_KEYS.size())
	while secondary_index==primary_index: secondary_index=posmod(secondary_index+1,SKILL_KEYS.size())
	var weak_index:=posmod(primary_index+4+rng.randi_range(0,2),SKILL_KEYS.size())
	while weak_index==primary_index or weak_index==secondary_index: weak_index=posmod(weak_index+1,SKILL_KEYS.size())
	skills[String(SKILL_KEYS[primary_index])]=rng.randi_range(72,93)
	skills[String(SKILL_KEYS[secondary_index])]=maxi(int(skills[String(SKILL_KEYS[secondary_index])]),rng.randi_range(58,82))
	skills[String(SKILL_KEYS[weak_index])]=rng.randi_range(14,36)
	var trait_a:=String(TRAITS[rng.randi_range(0,TRAITS.size()-1)])
	var trait_b:=String(TRAITS[rng.randi_range(0,TRAITS.size()-1)])
	while trait_b==trait_a: trait_b=String(TRAITS[rng.randi_range(0,TRAITS.size()-1)])
	var personality:Dictionary={"openness":rng.randf_range(0.12,0.92),"discipline":rng.randf_range(0.12,0.92),"empathy":rng.randf_range(0.12,0.92),"assertiveness":rng.randf_range(0.12,0.92),"risk_tolerance":rng.randf_range(0.12,0.92)}
	var doctrine:="directive" if float(personality.assertiveness)>0.68 else ("representative" if float(personality.empathy)>0.68 else ("measured" if float(personality.discipline)>0.66 else ("territorial" if float(personality.risk_tolerance)<0.36 else "federated")))
	var background:=_background_for_skills(skills)
	var settlements:=GameState.player_settlements
	var home_id:=String(settlements[posmod(person_id-1,settlements.size())].get("id","")) if not settlements.is_empty() else ""
	var born_day:=int(GameState.elapsed_days)-age*365-rng.randi_range(0,364)
	var profile:=_dynamic_profile(skills,personality)
	return {
		"person_id":person_id,"name":name,"born_day":born_day,"death_age_years":death_age,"died_day":-1,"status":"active","known_since_day":int(GameState.elapsed_days),
		"home_settlement_id":home_id,"office_key":"","local_leader_of":"","appointed_day":-1,"experience_months":0,
		"background":background,"institutional":false,"traits":[trait_a,trait_b],"personality":personality,"skills":skills,"doctrine":doctrine,
		"dynamic_profile":profile,"subcategory_profile":{},"support":clampi(roundi(28.0+float(profile.culture)*34.0+float(profile.institutions)*26.0),18,92),
		"beliefs":[],"memories":[],"goals":["serve_home","preserve_reputation"],
		"relationships":{"sovereign":{"trust":rng.randf_range(0.30,0.76),"respect":rng.randf_range(0.30,0.80),"fear":rng.randf_range(0.03,0.32),"resentment":0.0,"obligation":rng.randf_range(0.28,0.72)}},
		"honesty":rng.randf_range(0.30,0.94),"courage":rng.randf_range(0.24,0.92),"pride":rng.randf_range(0.16,0.88),"suspicion":rng.randf_range(0.12,0.86),
	}


func _background_for_skills(skills:Dictionary)->String:
	var best:="Administration"
	for skill in SKILL_KEYS:
		if int(skills.get(skill,0))>int(skills.get(best,0)): best=skill
	return {"Administration":"Household mediator","Provisioning":"Store and harvest keeper","Construction":"Builder and works organizer","Logistics":"Route and caravan organizer","Knowledge":"Observer and memory keeper","Defense":"Watch organizer","Diplomacy":"Messenger and dispute mediator"}.get(best,"Respected settlement organizer")


func _dynamic_profile(skills:Dictionary,personality:Dictionary)->Dictionary:
	return {
		"demography":clampf((float(skills.Provisioning)+float(personality.empathy)*100.0)/200.0,0.0,1.0),
		"nutrition":float(skills.Provisioning)/100.0,"health":clampf((float(skills.Provisioning)+float(skills.Knowledge))/200.0,0.0,1.0),
		"labor":clampf((float(skills.Administration)+float(skills.Construction))/200.0,0.0,1.0),"knowledge":float(skills.Knowledge)/100.0,
		"production":clampf((float(skills.Construction)+float(skills.Logistics))/200.0,0.0,1.0),"infrastructure":float(skills.Construction)/100.0,
		"logistics":float(skills.Logistics)/100.0,"ecology":clampf((float(skills.Knowledge)+float(personality.discipline)*100.0)/200.0,0.0,1.0),
		"institutions":float(skills.Administration)/100.0,"security":float(skills.Defense)/100.0,
		"culture":clampf((float(skills.Diplomacy)+float(personality.empathy)*100.0)/200.0,0.0,1.0),
	}


func _legacy_source_value(skills:Dictionary,canonical_skill:String,default_value:float)->float:
	var values:Array[float]=[]
	for source_variant in (CANONICAL_FROM_LEGACY.get(canonical_skill,[]) as Array):
		var source:=String(source_variant)
		if skills.has(source): values.append(float(skills[source]))
	if values.is_empty(): return default_value
	var total:=0.0
	for value in values: total+=value
	return total/float(values.size())


func _canonical_skill_value(person:Dictionary,canonical_skill:String,default_value:float=35.0)->float:
	var skills:Dictionary=person.get("skills",{})
	if skills.has(canonical_skill): return clampf(float(skills[canonical_skill]),0.0,100.0)
	return clampf(_legacy_source_value(skills,canonical_skill,default_value),0.0,100.0)


func skill_value(person:Dictionary,requested_skill:String,default_value:float=35.0)->float:
	var skills:Dictionary=person.get("skills",{})
	if skills.has(requested_skill): return clampf(float(skills[requested_skill]),0.0,100.0)
	if requested_skill in SKILL_KEYS: return _canonical_skill_value(person,requested_skill,default_value)
	var weights:Dictionary=LEGACY_SKILL_WEIGHTS.get(requested_skill,{})
	if weights.is_empty(): return default_value
	var total:=0.0
	var weight_total:=0.0
	for canonical_variant in weights:
		var canonical:=String(canonical_variant)
		var weight:=float(weights[canonical_variant])
		total+=_canonical_skill_value(person,canonical,default_value)*weight
		weight_total+=weight
	var value:=total/maxf(0.001,weight_total)
	var personality:Dictionary=person.get("personality",{})
	var personality_key:=String({"Research":"openness","Education":"empathy","Empathy":"empathy","Discipline":"discipline","Oratory":"assertiveness","Strategy":"risk_tolerance","Tactics":"discipline","Stress Tolerance":"discipline","Creativity":"openness"}.get(requested_skill,""))
	if personality_key!="" and personality.has(personality_key): value=lerpf(value,float(personality[personality_key])*100.0,0.18)
	return clampf(value,0.0,100.0)


func competency(person:Dictionary,relevant_skills:Array)->float:
	if person.is_empty(): return 0.0
	if relevant_skills.is_empty(): return 0.50
	var total:=0.0
	for skill_variant in relevant_skills: total+=skill_value(person,String(skill_variant))
	return clampf(total/float(relevant_skills.size())/100.0,0.0,1.0)


func _weighted_canonical_competency(person:Dictionary,weights:Dictionary)->float:
	if person.is_empty() or weights.is_empty(): return 0.0
	var total:=0.0
	var weight_total:=0.0
	for skill_variant in weights:
		var skill:=String(skill_variant)
		var weight:=float(weights[skill_variant])
		total+=_canonical_skill_value(person,skill)*weight
		weight_total+=weight
	return clampf(total/maxf(0.001,weight_total)/100.0,0.0,1.0)


func _personality_fit(person:Dictionary,office_key:String)->float:
	var p:Dictionary=person.get("personality",{})
	var openness:=float(p.get("openness",0.5))
	var discipline:=float(p.get("discipline",0.5))
	var empathy:=float(p.get("empathy",0.5))
	var assertiveness:=float(p.get("assertiveness",0.5))
	var risk:=float(p.get("risk_tolerance",0.5))
	match office_key:
		"Steward": return discipline*0.32+empathy*0.28+openness*0.20+assertiveness*0.12+(1.0-risk)*0.08
		"Quartermaster": return discipline*0.40+(1.0-risk)*0.25+assertiveness*0.15+openness*0.10+empathy*0.10
		"Marshal": return discipline*0.30+assertiveness*0.25+risk*0.25+openness*0.10+empathy*0.10
		"Scholar": return openness*0.45+discipline*0.35+empathy*0.10+(1.0-assertiveness)*0.10
		"Envoy": return empathy*0.38+openness*0.28+assertiveness*0.20+discipline*0.14
		_: return discipline*0.30+empathy*0.25+assertiveness*0.20+openness*0.15+(1.0-risk)*0.10


func office_competency(person:Dictionary,office_key:String)->float:
	var weights:Dictionary=OFFICE_SKILL_WEIGHTS.get(office_key,OFFICE_SKILL_WEIGHTS.SettlementLeader)
	var skill_fit:=_weighted_canonical_competency(person,weights)
	var experience:=minf(0.08,float(person.get("experience_months",0))/1440.0*0.08)
	return clampf(skill_fit*0.86+_personality_fit(person,office_key)*0.14+experience,0.0,1.0)


func dynamic_competency(person:Dictionary,dynamic_id:String)->float:
	return _weighted_canonical_competency(person,DYNAMIC_SKILL_WEIGHTS.get(dynamic_id,{}))


func office_is_active(office_key:String)->bool:
	for office in active_offices():
		if String(office.key)==office_key: return true
	return false


func executing_office(requested_office:String)->String:
	# Before a specialist office exists, the founding Steward remains the
	# responsible generalist. Once an office exists, leaving it vacant has a real
	# cost and cannot be evaded by routing its work back through the Steward.
	if office_is_active(requested_office): return requested_office
	if office_is_active("Steward"): return "Steward"
	return requested_office


func appointment_assessment(person:Dictionary,office_key:String)->Dictionary:
	var weights:Dictionary=OFFICE_SKILL_WEIGHTS.get(office_key,OFFICE_SKILL_WEIGHTS.SettlementLeader)
	var ranked:Array[Dictionary]=[]
	for skill_variant in weights:
		var skill:=String(skill_variant)
		ranked.append({"skill":skill,"value":roundi(_canonical_skill_value(person,skill)),"weight":float(weights[skill_variant])})
	ranked.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.value)*float(a.weight)>float(b.value)*float(b.weight))
	var strongest:Dictionary=ranked[0] if not ranked.is_empty() else {"skill":"Unproven","value":0}
	var weakest:Dictionary=ranked[0] if not ranked.is_empty() else {"skill":"Unproven","value":0}
	for record in ranked:
		if int(record.value)<int(weakest.value): weakest=record
	var best_office:=office_key
	var best_fit:=office_competency(person,office_key)
	for possible in ["Steward","Quartermaster","Marshal","Scholar","Envoy","SettlementLeader"]:
		var possible_fit:=office_competency(person,possible)
		if possible_fit>best_fit:
			best_fit=possible_fit
			best_office=possible
	var weakness_text:="%s %d limits this portfolio" % [String(weakest.skill),int(weakest.value)]
	if best_office!=office_key and best_fit-office_competency(person,office_key)>=0.08:
		weakness_text="Better suited to %s; appointing here forgoes that advantage" % ("local leadership" if best_office=="SettlementLeader" else best_office)
	var current_duty:=String(person.get("office_key",""))
	if current_duty=="" and String(person.get("local_leader_of",""))!="": current_duty="Settlement leader"
	var known_days:=maxi(0,int(GameState.elapsed_days)-int(person.get("known_since_day",int(GameState.elapsed_days))))
	var experience_months:=int(person.get("experience_months",0))
	var record:="LITTLE TESTED"
	if known_days>=5*365 or experience_months>=48: record="ESTABLISHED RECORD"
	elif known_days>=365 or experience_months>=12: record="SOME RECORD"
	var support:=int(person.get("support",50))
	var standing:="DIVIDED REPUTATION" if support<40 else ("BROADLY REGARDED" if support>=68 else "MIXED STANDING")
	var public_concern:=String(PUBLIC_DOUBTS.get(String(weakest.skill),"Their limits are not yet well understood"))
	if best_office!=office_key and best_fit-office_competency(person,office_key)>=0.08:
		public_concern="Some expect their abilities would be better used in %s" % ("local leadership" if best_office=="SettlementLeader" else String(best_office).to_lower())
	return {
		"fit":office_competency(person,office_key),"strongest_skill":String(strongest.skill),"strongest_value":int(strongest.value),
		"weakest_skill":String(weakest.skill),"weakest_value":int(weakest.value),
		"strength":"%s %d is the clearest advantage" % [String(strongest.skill),int(strongest.value)],"weakness":weakness_text,
		"best_office":best_office,"current_duty":current_duty,"record":record,"standing":standing,
		"known_for":String(PUBLIC_STRENGTHS.get(String(strongest.skill),"They are regarded as capable, though accounts differ")),
		"public_concern":public_concern,
	}


func living_people()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for person in people:
		if String(person.get("status","active"))=="active": result.append(person.duplicate(true))
	return result


func age_years(person:Dictionary,day:int=-1)->int:
	var current_day:=int(GameState.elapsed_days) if day<0 else day
	var end_day:=int(person.get("died_day",current_day)) if int(person.get("died_day",-1))>=0 else current_day
	return maxi(0,floori(float(end_day-int(person.get("born_day",0)))/365.0))


func person_snapshot(person_id:int)->Dictionary:
	for person in people:
		if int(person.get("person_id",0))==person_id:
			var snapshot:=person.duplicate(true)
			snapshot["age"]=age_years(person)
			return snapshot
	return {}


func adjust_person_relationship(person_id:int,trust_delta:float=0.0,respect_delta:float=0.0,resentment_delta:float=0.0)->Dictionary:
	## Dialogue changes the same durable relationship used by later execution.
	## Keep the bounded government cast, advisor roster, and office snapshots in
	## sync so opening a different panel cannot silently revert the exchange.
	var index:=_find_person_index(person_id)
	if index<0: return {}
	var relationships:Dictionary=people[index].get("relationships",{})
	var sovereign:Dictionary=relationships.get("sovereign",{"trust":0.5,"respect":0.5,"fear":0.0,"resentment":0.0,"obligation":0.4})
	sovereign["trust"]=clampf(float(sovereign.get("trust",0.5))+trust_delta,0.0,1.0)
	sovereign["respect"]=clampf(float(sovereign.get("respect",0.5))+respect_delta,0.0,1.0)
	sovereign["resentment"]=clampf(float(sovereign.get("resentment",0.0))+resentment_delta,0.0,1.0)
	relationships["sovereign"]=sovereign
	people[index]["relationships"]=relationships
	for roster_index in GameState.advisor_roster.size():
		if int(GameState.advisor_roster[roster_index].get("person_id",0))!=person_id: continue
		GameState.advisor_roster[roster_index]["relationships"]=relationships.duplicate(true)
	for office_key in GameState.leadership_positions:
		if int((GameState.leadership_positions[office_key] as Dictionary).get("person_id",0))!=person_id: continue
		GameState.leadership_positions[office_key]["relationships"]=relationships.duplicate(true)
	revision+=1
	return sovereign.duplicate(true)


func record_person_memory(person_id:int,summary:String,kind:String="civic",importance:float=0.6,metadata:Dictionary={})->Dictionary:
	## Memories belong to the person, not to a transient panel snapshot. Keep a
	## small, save-safe record so later conversations can recall consequential
	## events without sending an ever-growing transcript to the interpreter.
	var index:=_find_person_index(person_id)
	var clean_summary:=summary.strip_edges()
	if index<0 or clean_summary.is_empty(): return {}
	var memory:Dictionary={
		"summary":clean_summary.substr(0,320),
		"kind":kind.strip_edges().substr(0,48),
		"importance":clampf(importance,0.0,1.0),
		"confidence":1.0,
		"emotional_weight":clampf(importance*0.5,0.0,1.0),
		"emotion":String(metadata.get("emotion","duty")).substr(0,32),
		"created_day":int(GameState.elapsed_days),
		"last_recalled_day":int(GameState.elapsed_days),
	}
	for key in ["order_id","outcome","settlement_id"]:
		if metadata.has(key): memory[key]=String(metadata[key]).substr(0,96)
	if metadata.has("inherited"): memory["inherited"]=bool(metadata.inherited)
	if metadata.has("policy_ids"):
		var policy_ids:Array[String]=[]
		for policy_id_variant in (metadata.get("policy_ids",[]) as Array):
			var policy_id:=String(policy_id_variant).strip_edges().substr(0,64)
			if not policy_id.is_empty() and not policy_ids.has(policy_id): policy_ids.append(policy_id)
			if policy_ids.size()>=4: break
		memory["policy_ids"]=policy_ids
	var memories:Array=people[index].get("memories",[])
	var order_id:=String(memory.get("order_id",""))
	if not order_id.is_empty():
		for memory_index in range(memories.size()-1,-1,-1):
			var existing:Dictionary=memories[memory_index]
			if String(existing.get("kind",""))==String(memory.kind) and String(existing.get("order_id",""))==order_id:
				memories.remove_at(memory_index)
	memories.push_front(memory)
	if memories.size()>MAX_PERSON_MEMORIES: memories.resize(MAX_PERSON_MEMORIES)
	people[index]["memories"]=memories
	for roster_index in GameState.advisor_roster.size():
		if int(GameState.advisor_roster[roster_index].get("person_id",0))==person_id:
			GameState.advisor_roster[roster_index]["memories"]=memories.duplicate(true)
	for office_key in GameState.leadership_positions:
		if int((GameState.leadership_positions[office_key] as Dictionary).get("person_id",0))==person_id:
			GameState.leadership_positions[office_key]["memories"]=memories.duplicate(true)
	revision+=1
	return memory.duplicate(true)


func _find_person_index(person_id:int)->int:
	for index in people.size():
		if int(people[index].get("person_id",0))==person_id: return index
	return -1


func candidates_for_office(office_key:String,settlement_id:String="",limit:int=6,rank_by_fit:bool=true)->Array[Dictionary]:
	if not initializing: initialize()
	var candidates:Array[Dictionary]=[]
	for person_variant in people:
		var person:Dictionary=person_variant
		if String(person.get("status",""))!="active": continue
		if settlement_id!="" and String(person.get("home_settlement_id",""))!=settlement_id and String(person.get("local_leader_of",""))!="": continue
		var copy:=person.duplicate(true)
		copy["age"]=age_years(person)
		copy["office_fit"]=_office_fit(person,office_key)
		candidates.append(copy)
	if rank_by_fit:
		candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.office_fit)>float(b.office_fit))
	else:
		# The player receives a socially legible shortlist, not a competency table
		# secretly sorted into the correct answer. The incumbent remains reviewable;
		# everyone else has a stable, seed-dependent order unrelated to true fit.
		var incumbent_id:=int((GameState.leadership_positions.get(office_key,{}) as Dictionary).get("person_id",0))
		candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
			var a_incumbent:=int(a.get("person_id",0))==incumbent_id
			var b_incumbent:=int(b.get("person_id",0))==incumbent_id
			if a_incumbent!=b_incumbent: return a_incumbent
			var a_order:=posmod(hash("%d:%s:shortlist:%d" % [GameState.world_seed,office_key,int(a.get("person_id",0))]),2147483647)
			var b_order:=posmod(hash("%d:%s:shortlist:%d" % [GameState.world_seed,office_key,int(b.get("person_id",0))]),2147483647)
			return a_order<b_order
		)
	if candidates.size()>limit: candidates.resize(limit)
	return candidates


func _office_fit(person:Dictionary,office_key:String)->float:
	return office_competency(person,office_key)*100.0


func mark_central_appointment(person_id:int,office_key:String)->Dictionary:
	var office:=office_definition(office_key)
	if int(office.get("unlock_stage",99))>government_stage: return {}
	var index:=_find_person_index(person_id)
	if index<0 or String(people[index].get("status",""))!="active": return {}
	# A person cannot execute two central portfolios at once. Reassignment is
	# allowed, but the former office becomes visibly vacant immediately.
	for other_index in people.size():
		if String(people[other_index].get("office_key",""))==office_key:
			people[other_index]["office_key"]=""
			people[other_index]["office_title"]=""
		if int(people[other_index].get("person_id",0))==person_id:
			var former_office:=String(people[other_index].get("office_key",""))
			if former_office!="" and former_office!=office_key: GameState.leadership_positions.erase(former_office)
			people[other_index]["office_key"]=""
			people[other_index]["office_title"]=""
	people[index]["office_key"]=office_key
	people[index]["appointed_day"]=int(GameState.elapsed_days)
	people[index]["office_title"]=String(office.title)
	GameState.leadership_positions[office_key]=person_snapshot(person_id)
	# At founding scale the central polity and its only settlement are the same
	# community. The Steward therefore carries the local duty too; we do not
	# invent a second layer of government for 120 residents.
	if office_key=="Steward" and government_stage==0 and GameState.player_settlements.size()==1:
		assign_settlement_leader(String(GameState.player_settlements[0].get("id","")),person_id)
	revision+=1
	_sync_advisor_roster()
	return person_snapshot(person_id)


func _synchronize_office_holders(events:Array[Dictionary]=[],record_events:bool=false)->void:
	var active_keys:Array[String]=[]
	for office in active_offices(): active_keys.append(String(office.key))
	for person_index in people.size():
		var assigned_key:=String(people[person_index].get("office_key",""))
		if assigned_key!="" and assigned_key not in active_keys:
			people[person_index]["office_key"]=""
			people[person_index]["office_title"]=""
	for key_variant in GameState.leadership_positions.keys():
		var key:=String(key_variant)
		var holder:Dictionary=GameState.leadership_positions.get(key,{})
		var person_id:=int(holder.get("person_id",0))
		var person:=person_snapshot(person_id)
		if key not in active_keys or person.is_empty() or String(person.get("status",""))!="active":
			GameState.leadership_positions.erase(key)
			continue
		person["office_title"]=String(office_definition(key).title)
		GameState.leadership_positions[key]=person
	# The first government is one recognizable person. Later specialist offices
	# emerge vacant and remain a player choice.
	if "Steward" not in GameState.leadership_positions:
		var candidates:=candidates_for_office("Steward","",1)
		if not candidates.is_empty():
			var person:=mark_central_appointment(int(candidates[0].person_id),"Steward")
			GameState.leadership_positions["Steward"]=person
			if government_stage==0 and GameState.player_settlements.size()==1 and record_events:
				events.append({"day":int(GameState.elapsed_days),"title":"Local Succession","description":"%s now carries the founding council and local leadership of %s." % [String(person.get("name","A successor")),String(GameState.player_settlements[0].get("name","the settlement"))],"domain":"institutions","severity":"notice"})


func officeholder(office_key:String)->Dictionary:
	initialize()
	var holder:Dictionary=GameState.leadership_positions.get(office_key,{})
	if holder.is_empty(): return {}
	var person:=person_snapshot(int(holder.get("person_id",0)))
	if person.is_empty(): return {}
	person["office_title"]=String(office_definition(office_key).title)
	return person


func assign_settlement_leader(settlement_id:String,person_id:int)->Dictionary:
	var person_index:=_find_person_index(person_id)
	if person_index<0 or String(people[person_index].get("status",""))!="active": return {"ok":false,"reason":"That person is not available."}
	var settlement_index:=-1
	for index in GameState.player_settlements.size():
		if String(GameState.player_settlements[index].get("id",""))==settlement_id: settlement_index=index; break
	if settlement_index<0: return {"ok":false,"reason":"That settlement is not owned."}
	if government_stage==0 and GameState.player_settlements.size()==1:
		var steward_id:=int((GameState.leadership_positions.get("Steward",{}) as Dictionary).get("person_id",0))
		if steward_id>0 and person_id!=steward_id:
			return {"ok":false,"reason":"The founding council and its only settlement are still one office. Replace the founding leader instead."}
	for other_index in people.size():
		if String(people[other_index].get("local_leader_of",""))==settlement_id: people[other_index]["local_leader_of"]=""
	people[person_index]["local_leader_of"]=settlement_id
	people[person_index]["home_settlement_id"]=settlement_id
	people[person_index]["appointed_day"]=int(GameState.elapsed_days)
	GameState.player_settlements[settlement_index]["leader_person_id"]=person_id
	GameState.player_settlements[settlement_index]["leader_title"]=settlement_leader_title()
	GameState.settlement_network_revision+=1
	revision+=1
	return {"ok":true,"leader":person_snapshot(person_id),"title":settlement_leader_title()}


func remove_settlement_leader(settlement_id:String,action:String="dismiss")->Dictionary:
	initialize()
	action="arrest" if action.to_lower()=="arrest" else "dismiss"
	var settlement_index:=-1
	for index in GameState.player_settlements.size():
		if String(GameState.player_settlements[index].get("id",""))==settlement_id: settlement_index=index; break
	if settlement_index<0: return {"ok":false,"reason":"That settlement is not owned."}
	var previous_id:=int(GameState.player_settlements[settlement_index].get("leader_person_id",0))
	var previous:=person_snapshot(previous_id)
	if previous.is_empty(): return {"ok":false,"reason":"That settlement has no leader to remove."}
	var arrest:=action=="arrest"
	var combined_founding_office:=government_stage==0 and GameState.player_settlements.size()==1
	var previous_index:=_find_person_index(previous_id)
	if previous_index>=0:
		people[previous_index]["local_leader_of"]=""
		people[previous_index]["removed_day"]=int(GameState.elapsed_days)
		people[previous_index]["removal_reason"]="arrested" if arrest else "dismissed"
		if arrest: people[previous_index]["status"]="detained"
	if combined_founding_office or arrest:
		for office_key_variant in GameState.leadership_positions.keys().duplicate():
			var office_key:=String(office_key_variant)
			if int((GameState.leadership_positions[office_key] as Dictionary).get("person_id",0))!=previous_id: continue
			GameState.leadership_positions.erase(office_key)
		if previous_index>=0:
			people[previous_index]["office_key"]=""
			people[previous_index]["office_title"]=""
	GameState.player_settlements[settlement_index]["leader_person_id"]=0
	GameState.player_settlements[settlement_index]["leader_title"]=settlement_leader_title()
	if arrest:
		GameState.simulation_metrics["legitimacy"]=clampf(float(GameState.simulation_metrics.get("legitimacy",0.5))-0.04,0.01,0.99)
		GameState.simulation_metrics["cohesion"]=clampf(float(GameState.simulation_metrics.get("cohesion",0.5))-0.025,0.01,0.99)
	else:
		GameState.simulation_metrics["legitimacy"]=clampf(float(GameState.simulation_metrics.get("legitimacy",0.5))-0.008,0.01,0.99)
		GameState.simulation_metrics["cohesion"]=clampf(float(GameState.simulation_metrics.get("cohesion",0.5))-0.002,0.01,0.99)
	_ensure_pool()
	var successors:=candidates_for_office("SettlementLeader",settlement_id,MAX_GOVERNMENT_PEOPLE,false)
	var successor:Dictionary={}
	for candidate_variant in successors:
		var candidate:Dictionary=candidate_variant
		if int(candidate.get("person_id",0))==previous_id: continue
		if String(candidate.get("status","active"))!="active": continue
		successor=candidate
		break
	var appointment:Dictionary={}
	if not successor.is_empty():
		if combined_founding_office:
			var appointed:=mark_central_appointment(int(successor.get("person_id",0)),"Steward")
			appointment={"ok":not appointed.is_empty(),"leader":appointed,"title":settlement_leader_title()}
		else:
			appointment=assign_settlement_leader(settlement_id,int(successor.get("person_id",0)))
	var successor_record:Dictionary=appointment.get("leader",{})
	var succession_text:=" %s now succeeds them." % String(successor_record.get("name","A successor")) if bool(appointment.get("ok",false)) else " The office is vacant."
	var event:={
		"day":int(GameState.elapsed_days),"title":"Leader Arrested" if arrest else "Leader Dismissed",
		"description":"%s was %s as %s of %s.%s" % [String(previous.get("name","The former leader")),"arrested and detained" if arrest else "dismissed",settlement_leader_title(),String(GameState.player_settlements[settlement_index].get("name","the settlement")),succession_text],
		"domain":"institutions","severity":"major" if arrest else "notice",
	}
	GameState.simulation_events.push_front(event)
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
	GameState.settlement_network_revision+=1
	revision+=1
	_sync_advisor_roster()
	var legitimacy_cost:=0.04 if arrest else 0.008
	var cohesion_cost:=0.025 if arrest else 0.002
	var successor_name:=String(successor_record.get("name","No successor"))
	var message:="%s was %s. %s%s" % [
		String(previous.get("name","The former leader")),"arrested and detained" if arrest else "dismissed",
		"%s took office. " % successor_name if bool(appointment.get("ok",false)) else "The office remains vacant. ",
		"This coercive removal seriously damaged legitimacy and cohesion." if arrest else "The abrupt replacement carried a small legitimacy and cohesion cost.",
	]
	return {"ok":true,"action":action,"former":previous,"successor":successor_record,"event":event,"legitimacy_cost":legitimacy_cost,"cohesion_cost":cohesion_cost,"message":message}


func settlement_leader(settlement_id:String)->Dictionary:
	if not initializing: initialize()
	for settlement in GameState.player_settlements:
		if String(settlement.get("id",""))!=settlement_id: continue
		var person:=person_snapshot(int(settlement.get("leader_person_id",0)))
		if person.is_empty(): return {}
		person["title"]=settlement_leader_title()
		return person
	return {}


func _ensure_local_leaders(events:Array[Dictionary]=[])->void:
	for settlement_index in GameState.player_settlements.size():
		var settlement:Dictionary=GameState.player_settlements[settlement_index]
		var settlement_id:=String(settlement.get("id",""))
		var current:=person_snapshot(int(settlement.get("leader_person_id",0)))
		if not current.is_empty() and String(current.get("status",""))=="active":
			settlement["leader_title"]=settlement_leader_title()
			GameState.player_settlements[settlement_index]=settlement
			continue
		# At founding scale the only civic office and the only local office are
		# intentionally the same person. A migrated save could have a Steward but
		# no leader_person_id; choosing the highest-rated generic local candidate
		# here was then rejected by assign_settlement_leader and left the colony
		# permanently vacant.
		if government_stage==0 and GameState.player_settlements.size()==1:
			var steward_id:=int((GameState.leadership_positions.get("Steward",{}) as Dictionary).get("person_id",0))
			if steward_id>0:
				var founding_result:=assign_settlement_leader(settlement_id,steward_id)
				if bool(founding_result.get("ok",false)):
					events.append({"day":int(GameState.elapsed_days),"title":"Founding Leader Recognized","description":"%s now carries both the founding council and the local leadership of %s." % [String((founding_result.get("leader",{}) as Dictionary).get("name","The founding leader")),String(settlement.get("name","the settlement"))],"domain":"institutions","severity":"notice"})
				continue
		var candidates:=candidates_for_office("SettlementLeader",settlement_id,1)
		if candidates.is_empty(): candidates=candidates_for_office("SettlementLeader","",1)
		if candidates.is_empty(): continue
		var result:=assign_settlement_leader(settlement_id,int(candidates[0].person_id))
		if bool(result.get("ok",false)):
			events.append({"day":int(GameState.elapsed_days),"title":"Local Succession","description":"%s now serves as %s of %s." % [String(candidates[0].name),String(result.title),String(settlement.get("name","the settlement"))],"domain":"institutions","severity":"notice"})


func _process_lifespans(day:int,events:Array[Dictionary])->void:
	for index in people.size():
		var person:Dictionary=people[index]
		# Detention removes someone from office and the available candidate pool;
		# it does not suspend their aging or turn them into an immortal record.
		if String(person.get("status","")) not in ["active","detained"]: continue
		if String(person.get("office_key",""))!="" or String(person.get("local_leader_of",""))!="":
			person["experience_months"]=int(person.get("experience_months",0))+1
		var age:=float(day-int(person.get("born_day",day)))/365.0
		if age<float(person.get("death_age_years",90.0)):
			people[index]=person
			continue
		person["status"]="deceased"
		person["died_day"]=day
		var held_title:=String(person.get("office_title",person.get("office_key","")))
		var local_id:=String(person.get("local_leader_of",""))
		people[index]=person
		# This named person is part of the aggregate population. Register exactly one
		# death through the same conserved demographic entry point.
		GameState.register_population_deaths(1,"Natural causes")
		var service_note:=" while serving as %s" % held_title if held_title!="" else (" while leading a settlement" if local_id!="" else "")
		var event:Dictionary={"day":day,"title":"Officeholder Died","description":"%s died aged %d%s. The office and local duties now pass through the same succession rules as every other appointment." % [String(person.name),floori(age),service_note],"domain":"institutions","severity":"major"}
		events.append(event)
		GameState.simulation_events.push_front(event)
		if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
		revision+=1


func _focus_decision_for_settlement(settlement:Dictionary)->Dictionary:
	var age_days:=maxi(0,int(GameState.elapsed_days)-int(settlement.get("founded_day",0)))
	if age_days<365:
		return {"id":"establishment","label":FOCUS_LABELS.establishment,"reason":"This place is less than a year old and still needs its first dependable works and routines."}
	var territory:Dictionary=settlement.get("territory_context",{})
	var is_primary:=bool(settlement.get("primary",false))
	var water:Dictionary=GameState.water_metrics
	var water_intake:=clampf(float(water.get("intake_ratio",1.0)),0.0,1.0)
	var source_accessible:=bool(water.get("source_accessible",true))
	var water_required:=maxf(0.0,float(water.get("required_today",0.0)))
	var water_collected:=maxf(0.0,float(water.get("collected_today",water_required)))
	var water_days:=maxf(0.0,float(water.get("days",30.0)))
	var local_water_access:=clampf(float(territory.get("water_access",0.5)),0.0,1.0)
	# Reserve days describe the size of the carried buffer, not whether people
	# received water today. A full four-day store must not trap every leader in a
	# permanent "water emergency" simply because twelve days cannot yet be held.
	if is_primary and water_intake<0.98:
		return {"id":"water","label":"RESTORE WATER SUPPLY","reason":"Only %d%% of today's drinking-water need was met." % roundi(water_intake*100.0)}
	if is_primary and not source_accessible:
		return {"id":"water","label":"FIND FRESH WATER","reason":"No recognized freshwater source is within usable reach."}
	if is_primary and water_required>0.0 and water_collected<water_required*1.03 and water_days<10.0:
		return {"id":"water","label":"STABILIZE WATER SUPPLY","reason":"Collection replaced only %d%% of daily use and the reserve has fallen to %.1f days." % [roundi(water_collected/water_required*100.0),water_days]}
	if not is_primary and local_water_access<0.28:
		return {"id":"water","label":"IMPROVE WATER ACCESS","reason":"This settlement's local freshwater access is weak; the bottleneck is finding and carrying water, not the size of the reserve."}
	var food_days:=float(GameState.simulation_metrics.get("food_days",30.0))
	var food_net:=float(GameState.simulation_metrics.get("food_net",0.0))
	var food_intake:=clampf(float(GameState.simulation_metrics.get("food_intake_ratio",1.0)),0.0,1.0)
	var food_projected_days:=float(GameState.simulation_metrics.get("food_projected_days",9999.0))
	var food_forecast:Dictionary=GameState.simulation_metrics.get("food_forecast_90",{})
	var forecast_shortage_day:=int(food_forecast.get("first_shortage_day",-1))
	if food_intake<0.995:
		return {"id":"provisions","label":"RESTORE FOOD SUPPLY","reason":"Only %d%% of today's food requirement was met." % roundi(food_intake*100.0)}
	if forecast_shortage_day>0 and forecast_shortage_day<=60:
		return {"id":"provisions","label":FOCUS_LABELS.provisions,"reason":"The seasonal and weather outlook projects a shortage in about %d days." % forecast_shortage_day}
	if food_net<0.0 and food_projected_days<45.0:
		return {"id":"provisions","label":FOCUS_LABELS.provisions,"reason":"Food stores are shrinking and are projected to last %.1f days without a correction." % food_projected_days}
	var housing_ratio:=float(GameState.simulation_metrics.get("housing_ratio",1.0))
	if housing_ratio<0.96:
		return {"id":"shelter","label":FOCUS_LABELS.shelter,"reason":"Shelter currently covers only %d%% of the population." % roundi(housing_ratio*100.0)}
	var security:=float(GameState.society_capacities.get("security",0.4))
	if security<0.30 and GameState.player_settlements.size()>1:
		return {"id":"defense","label":FOCUS_LABELS.defense,"reason":"Several settlements must be protected while security capacity remains weak."}
	var leader:=settlement_leader(String(settlement.get("id","")))
	if not leader.is_empty():
		var skills:Dictionary=leader.get("skills",{})
		if int(skills.get("Construction",0))+int(skills.get("Logistics",0))>135:
			return {"id":"development","label":FOCUS_LABELS.development,"reason":"Immediate needs are stable, so the local leader is using a proven strength in building and logistics."}
	return {"id":"balanced","label":FOCUS_LABELS.balanced,"reason":"Water, food, shelter, and security are currently stable enough for ordinary work."}


func _focus_for_settlement(settlement:Dictionary)->String:
	return String(_focus_decision_for_settlement(settlement).id)


func _manual_focus_reason(focus:String)->String:
	return "You directed this priority; the local leader will keep it until delegation is restored."


func _survival_guard()->Dictionary:
	var reasons:Array[String]=[]
	var water:Dictionary=GameState.water_metrics
	var required:=maxf(0.0,float(water.get("required_today",0.0)))
	var collected:=maxf(0.0,float(water.get("collected_today",required)))
	var water_days:=maxf(0.0,float(water.get("days",30.0)))
	var water_intake:=clampf(float(water.get("intake_ratio",1.0)),0.0,1.0)
	# An empty ledger before the first simulation day is unknown, not a confirmed
	# shortage. The safeguard begins as soon as actual demand has been measured.
	var water_measured:=required>0.0
	var water_risk:=water_measured and (water_intake<0.995 or not bool(water.get("source_accessible",true)) or (collected<required*1.03 and water_days<10.0))
	if water_risk:
		reasons.append("water collection is not safely replacing daily use")
	var metrics:Dictionary=GameState.simulation_metrics
	var food_intake:=clampf(float(metrics.get("food_intake_ratio",1.0)),0.0,1.0)
	var food_net:=float(metrics.get("food_net",0.0))
	var projected:=float(metrics.get("food_projected_days",9999.0))
	var forecast:Dictionary=metrics.get("food_forecast_90",{})
	var shortage_day:=int(forecast.get("first_shortage_day",-1))
	var food_risk:=food_intake<0.995 or (food_net<0.0 and projected<45.0) or (shortage_day>0 and shortage_day<=60)
	if food_risk:
		reasons.append("food stores are already short or the weather outlook projects a near-term drawdown")
	return {"active":water_risk or food_risk,"water":water_risk,"food":food_risk,"reasons":reasons}


func _apply_survival_guard(weights:Dictionary)->Dictionary:
	var guard:=_survival_guard()
	if bool(guard.food):
		weights.Food=float(weights.get("Food",0.0))+18.0
		weights.Logistics=float(weights.get("Logistics",0.0))+5.0
	if bool(guard.water):
		weights.Food=float(weights.get("Food",0.0))+5.0
		weights.Survey=float(weights.get("Survey",0.0))+7.0
		weights.Logistics=float(weights.get("Logistics",0.0))+10.0
		weights.Construction=float(weights.get("Construction",0.0))+4.0
	return guard


func _allocations_for_focus(focus:String,leader:Dictionary)->Dictionary:
	var weights:Dictionary=BASE_ALLOCATIONS.duplicate(true)
	var changes:Dictionary=({
		"logistics":{"Logistics":16.0,"Construction":4.0,"Administration":2.0},
		"establishment":{"Construction":10.0,"Logistics":5.0,"Food":3.0,"Administration":2.0},
		"water":{"Survey":8.0,"Construction":6.0,"Logistics":5.0,"Food":2.0},
		"provisions":{"Food":14.0,"Logistics":4.0,"Survey":2.0},
		"shelter":{"Construction":12.0,"Extraction":6.0,"Logistics":3.0},
		"defense":{"Defense":12.0,"Logistics":4.0,"Construction":3.0},
		"development":{"Construction":5.0,"Extraction":5.0,"Crafting":6.0,"Knowledge":3.0},
		"research":{"Knowledge":16.0,"Survey":5.0,"Administration":3.0},
	}).get(focus,{})
	for role in changes: weights[role]=float(weights.get(role,0.0))+float(changes[role])
	_apply_survival_guard(weights)
	if not leader.is_empty():
		var skills:Dictionary=leader.get("skills",{})
		weights.Administration=float(weights.Administration)+float(skills.get("Administration",50))*0.025
		weights.Logistics=float(weights.Logistics)+float(skills.get("Logistics",50))*0.018
		weights.Knowledge=float(weights.Knowledge)+float(skills.get("Knowledge",50))*0.012
	var total:=0.0
	for role in GameState.POPULATION_ROLES: total+=maxf(0.0,float(weights.get(role,0.0)))
	for role in GameState.POPULATION_ROLES: weights[role]=maxf(0.0,float(weights.get(role,0.0)))/maxf(0.001,total)*100.0
	return weights


func _delegate_settlements(_day:int)->void:
	var aggregate:Dictionary={}
	for role in GameState.POPULATION_ROLES: aggregate[role]=0.0
	var total_weight:=0.0
	var satellite_share:=0.0
	var management_changed:=false
	for settlement in GameState.player_settlements:
		if not bool(settlement.get("primary",false)): satellite_share+=maxf(0.0,float(settlement.get("population_share",0.0)))
	for index in GameState.player_settlements.size():
		var settlement:Dictionary=GameState.player_settlements[index]
		var share:=maxf(0.01,1.0-satellite_share) if bool(settlement.get("primary",false)) else maxf(0.001,float(settlement.get("population_share",0.0)))
		var auto_manage:=bool(settlement.get("auto_manage",true))
		var guard:Dictionary=SettlementModel.with_city_resources(String(settlement.id),_survival_guard)
		var decision:Dictionary=SettlementModel.with_city_resources(String(settlement.id),func()->Dictionary: return _focus_decision_for_settlement(settlement)) if auto_manage else {
			"id":String(settlement.get("management_focus","balanced")),
			"label":String(FOCUS_LABELS.get(String(settlement.get("management_focus","balanced")),"BALANCED STEWARDSHIP")),
			"reason":String(settlement.get("management_focus_reason",_manual_focus_reason(String(settlement.get("management_focus","balanced"))))),
		}
		var focus:=String(decision.id)
		var leader:=settlement_leader(String(settlement.get("id","")))
		# A manual focus governs discretionary work; the leader's food-and-water
		# safeguard still applies and is recalculated from the latest daily ledger.
		var allocations:Dictionary=SettlementModel.with_city_resources(String(settlement.id),func()->Dictionary: return _allocations_for_focus(focus,leader))
		var skills:Dictionary=leader.get("skills",{})
		var competence:=clampf(office_competency(leader,"SettlementLeader"),0.18,0.94) if not leader.is_empty() else 0.18
		var old_signature:="%s|%s|%s" % [String(settlement.get("management_focus","")),bool(settlement.get("survival_guard_active",false)),JSON.stringify(settlement.get("local_allocations",{}))]
		settlement["management_focus"]=focus
		settlement["management_focus_label"]=String(decision.label)
		settlement["management_focus_reason"]=String(decision.reason)
		var focus_effect:=String(FOCUS_EFFECTS.get(focus,FOCUS_EFFECTS.balanced))
		if bool(guard.active):
			focus_effect+=" Survival safeguard: %s." % "; ".join(guard.reasons)
		settlement["management_focus_effect"]=focus_effect
		settlement["survival_guard_active"]=bool(guard.active)
		settlement["auto_manage"]=auto_manage
		settlement["local_allocations"]=allocations
		settlement["delegated_effects"]={"competence":competence,"work":competence*0.12,"travel":float(skills.get("Logistics",35))/100.0*0.10,"water":float(skills.get("Provisioning",35))/100.0*0.08,"support":competence*0.14}
		var new_signature:="%s|%s|%s" % [focus,bool(guard.active),JSON.stringify(allocations)]
		management_changed=management_changed or old_signature!=new_signature
		GameState.player_settlements[index]=settlement
		for role in GameState.POPULATION_ROLES: aggregate[role]=float(aggregate[role])+float(allocations.get(role,0.0))*share
		total_weight+=share
	if total_weight>0.0:
		for role in GameState.POPULATION_ROLES: GameState.population_allocation_percentages[role]=float(aggregate[role])/total_weight
		GameState.synchronize_population_allocations()
	if management_changed: GameState.settlement_network_revision+=1


func settlement_management(settlement_id:String)->Dictionary:
	initialize()
	for settlement in GameState.player_settlements:
		if String(settlement.get("id",""))!=settlement_id: continue
		return {"leader":settlement_leader(settlement_id),"leader_title":settlement_leader_title(),"focus":String(settlement.get("management_focus","balanced")),"focus_label":String(settlement.get("management_focus_label",FOCUS_LABELS.balanced)),"focus_reason":String(settlement.get("management_focus_reason","Local priorities have not yet been reassessed.")),"focus_effect":String(settlement.get("management_focus_effect",FOCUS_EFFECTS.balanced)),"survival_guard_active":bool(settlement.get("survival_guard_active",false)),"auto_manage":bool(settlement.get("auto_manage",true)),"allocations":(settlement.get("local_allocations",BASE_ALLOCATIONS) as Dictionary).duplicate(true),"effects":(settlement.get("delegated_effects",{}) as Dictionary).duplicate(true)}
	return {}


func set_settlement_focus(settlement_id:String,focus:String)->Dictionary:
	if not String(SettlementModel.settlement_record(settlement_id).get("occupied_by","")).is_empty():return {"ok":false,"reason":"Use local recovery decisions while this city is occupied."}
	if focus not in FOCUS_LABELS: return {"ok":false,"reason":"Unknown settlement focus."}
	for index in GameState.player_settlements.size():
		if String(GameState.player_settlements[index].get("id",""))!=settlement_id: continue
		GameState.player_settlements[index]["management_focus"]=focus
		GameState.player_settlements[index]["management_focus_label"]=String(FOCUS_LABELS[focus])
		GameState.player_settlements[index]["management_focus_reason"]=_manual_focus_reason(focus)
		GameState.player_settlements[index]["management_focus_effect"]=String(FOCUS_EFFECTS.get(focus,FOCUS_EFFECTS.balanced))
		GameState.player_settlements[index]["auto_manage"]=false
		GameState.player_settlements[index]["local_allocations"]=_allocations_for_focus(focus,settlement_leader(settlement_id))
		GameState.settlement_network_revision+=1
		revision+=1
		return {"ok":true,"focus":focus,"label":String(FOCUS_LABELS[focus])}
	return {"ok":false,"reason":"That settlement is not owned."}


func restore_delegation(settlement_id:String)->Dictionary:
	if not String(SettlementModel.settlement_record(settlement_id).get("occupied_by","")).is_empty():return {"ok":false,"reason":"Use local recovery decisions while this city is occupied."}
	for index in GameState.player_settlements.size():
		if String(GameState.player_settlements[index].get("id",""))!=settlement_id: continue
		GameState.player_settlements[index]["auto_manage"]=true
		_delegate_settlements(int(GameState.elapsed_days))
		revision+=1
		return {"ok":true}
	return {"ok":false,"reason":"That settlement is not owned."}


func _sync_advisor_roster()->void:
	var prior_by_id:Dictionary={}
	for prior in GameState.advisor_roster:
		var prior_id:=int(prior.get("person_id",0))
		if prior_id>0: prior_by_id[prior_id]=prior
	var roster:Array[Dictionary]=[]
	for person in living_people():
		var person_id:=int(person.person_id)
		if prior_by_id.has(person_id):
			var prior:Dictionary=prior_by_id[person_id]
			for field in ["beliefs","memories","goals","relationships"]:
				if prior.has(field):
					var preserved:Variant=prior.get(field)
					person[field]=preserved.duplicate(true) if preserved is Array or preserved is Dictionary else preserved
		roster.append(person)
	GameState.advisor_roster=roster
