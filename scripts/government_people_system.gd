extends Node
## A bounded cast of named people who embody government. The population remains
## aggregate; these records are actual members sampled from it, not extra people
## and not one runtime entity per citizen. At planetary scale the cast remains
## capped while offices, titles, experience, succession, and local delegation
## continue to matter.

const ValuesModel:=preload("res://scripts/societal_values_model.gd")
## Forms of court and office derived from discoveries (never saved).
const CivicStages:=preload("res://scripts/civic_stages.gd")
const NORMAL_GOVERNMENT_POOL:=96
# Covers the bounded 256-settlement network, central offices and successors.
const MAX_GOVERNMENT_PEOPLE:=288
const MAX_PERSON_MEMORIES:=20
const MONTH_DAYS:=30

## Invented names only (alternative history); people are named through
## era_names.gd, which knows the era and each people's tradition. These lists
## remain for callers that need a plain pool.
const GIVEN_NAMES:=[
	"Ama","Sela","Iri","Nuna","Vesa","Tilla","Ysa","Oda","Luma","Pira","Runa","Wenna",
	"Harl","Tesk","Oru","Brim","Kael","Dunn","Vesh","Tam","Pell","Rook","Faro","Garro",
]
const FAMILY_NAMES:=[
	"Reedwater","Ford","Ashbank","Longmeadow","Saltspring","Hollowhill","Redcliff","Stonewash","Birchstand","Deepwell","Otterpool","Windgap",
	"Twinoak","Mossbrook","Whitestone","Fernside","Highcamp","Crowfield","Lakeshore","Thornbrake","Stonehand","Longstride","Owlsight","Keeneye",
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
	# Reading country, keeping a party fed on the road, noticing what matters and
	# coming home alive to say it plainly.
	"ChiefScout":{"Logistics":0.36,"Knowledge":0.30,"Defense":0.20,"Diplomacy":0.14},
	# Offices that discoveries add to the court (data/civic/civic_stages.json).
	"HighPriest":{"Diplomacy":0.40,"Knowledge":0.34,"Administration":0.16,"Provisioning":0.10},
	"Justice":{"Administration":0.46,"Knowledge":0.30,"Diplomacy":0.24},
	"Treasurer":{"Administration":0.44,"Provisioning":0.26,"Logistics":0.20,"Knowledge":0.10},
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

var administration_records:Dictionary=preload("res://scripts/civic_administration.gd").empty_state()
var people:Array[Dictionary]=[]
var next_person_id:=1
var last_processed_month:=-1
var government_stage:=0
var revision:=0
var initializing:=false
## True while a new world's first council is seated (initialize with no
## people yet): the founders take their places as the hearth chose them;
## every later succession follows the stated rule (succession_rule).
var _founding:=false


func reset_for_new_world()->void:
	administration_records=preload("res://scripts/civic_administration.gd").empty_state()
	people=[]
	next_person_id=1
	last_processed_month=-1
	government_stage=0
	revision=0
	initializing=false


func initialize(reconcile_stage:bool=true)->void:
	if "Hearth Circle" not in WorldSimulation.state.settlement_completed or WorldSimulation.state.player_settlements.is_empty(): return
	if initializing: return
	initializing=true
	# Re-evaluate the structure when a save is opened as well as when a new world
	# begins. Earlier builds allowed abstract institutional capacity to create a
	# modern-sized cabinet in a settlement of 120 people; this also migrates those
	# worlds back to a government their actual civic scale can support.
	_founding=people.is_empty()
	if people.is_empty():
		_update_government_stage(false)
	elif reconcile_stage and _stage_from_conditions()<government_stage:
		# A read-only panel may repair an impossible oversized legacy structure, but
		# normal expansion waits for process_day so it receives a dated event.
		_update_government_stage(false)
	_ensure_pool()
	_synchronize_office_holders()
	_founding=false
	_ensure_local_leaders()
	_sync_advisor_roster()
	initializing=false


func process_day(day:int)->Array[Dictionary]:
	# Let the dated monthly transition below record expansion or consolidation;
	# ordinary UI initialization may reconcile an older save silently.
	initialize(false)
	if people.is_empty(): return []
	_fade_bonds(day)
	WorldSimulation.settlements.with_local_population(func()->void:preload("res://scripts/civic_administration.gd").credit_day(self,day))
	var month:=day/MONTH_DAYS
	# Local leaders rebalance ordinary labor every day. Mortality, succession and
	# institutional expansion remain monthly, but survival cannot wait up to thirty
	# days for the next government tick.
	if month<=last_processed_month:
		# initialize(false) has already synchronized today's officials. Local
		# leader lookups inside delegation must not synchronize the same roster
		# again for each city.
		initializing=true
		_delegate_settlements(day)
		preload("res://scripts/civic_administration.gd").finish_day(self)
		initializing=false
		return []
	last_processed_month=month
	# Treat the monthly transaction as one synchronization pass. Candidate lookup
	# must not recursively initialize the system midway through succession, or it
	# can perform the appointment before the dated event is recorded.
	initializing=true
	var events:Array[Dictionary]=[]
	_process_lifespans(day,events)
	_update_government_stage(true,events)
	_note_court_change(events)
	_ensure_pool()
	_synchronize_office_holders(events,true)
	_ensure_local_leaders(events)
	_delegate_settlements(day)
	preload("res://scripts/civic_administration.gd").finish_day(self)
	_sync_advisor_roster()
	initializing=false
	# Officials who love the god take up their own business unbidden when it
	# plainly needs doing (office_initiative.gd), by the ordinary paths.
	events.append_array(preload("res://scripts/office_initiative.gd").month(day))
	return events


func _stage_from_conditions()->int:
	var population:=WorldSimulation.state.population_total
	var settlements:=WorldSimulation.settlements.lived_in().size()
	var institutions:=clampf(float(WorldSimulation.state.society_capacities.get("institutions",0.0)),0.0,1.0)
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
		var event:Dictionary={"day":int(WorldSimulation.state.elapsed_days),"title":"Government Expanded" if expanded else "Government Consolidated","description":"Population, distance, and institutional work now require additional named officeholders. Government remains a bounded cast of people, not an abstract cabinet." if expanded else "The surviving population and settlements can no longer sustain every specialized office. Their responsibilities return to the remaining general government.","domain":"institutions","severity":"major"}
		events.append(event)
		WorldSimulation.state.simulation_events.push_front(event)
		if WorldSimulation.state.simulation_events.size()>80: WorldSimulation.state.simulation_events.resize(80)


func _note_court_change(events:Array[Dictionary])->void:
	## The court's form follows discoveries; say so, dated, when it changes.
	var change:=CivicStages.note_change()
	if change.is_empty(): return
	var after:=CivicStages.stage(String(change.to))
	var before:=CivicStages.stage(String(change.from))
	revision+=1
	var event:Dictionary={"day":int(WorldSimulation.state.elapsed_days),"title":"The Court Changes: %s" % String(after.get("name","")),
		"description":"%s gives way to %s. %s" % [String(before.get("place_name","The old court")),String(after.get("place_name","a new court")).to_lower(),CivicStages.protocol_line(after)],
		"domain":"institutions","severity":"major"}
	events.append(event)
	WorldSimulation.state.simulation_events.push_front(event)
	if WorldSimulation.state.simulation_events.size()>80: WorldSimulation.state.simulation_events.resize(80)


func court_stage()->Dictionary:
	## The form of court this people's discoveries support (see CivicStages).
	return CivicStages.current()


func government_form()->String:
	var identity:Dictionary=ValuesModel.identity_snapshot(WorldSimulation.state.societal_values)
	var name:=String(identity.get("name","FEDERATED FORMING ORDER")).to_upper()
	if name.begins_with("CENTRALIZED"): return "centralized"
	if name.begins_with("LOCALIST"): return "localist"
	return "federated"


func structure_snapshot()->Dictionary:
	initialize()
	return {
		"stage":government_stage,"form":government_form(),"name":String(ValuesModel.identity_snapshot(WorldSimulation.state.societal_values).get("name","Forming Order")),
		"scope":government_scope(),"active_offices":active_offices(),"court_stage":String(court_stage().get("id","")),"court_stage_name":String(court_stage().get("name","")),"living_people":living_people().size(),"pool_limit":MAX_GOVERNMENT_PEOPLE,"revision":revision,
	}


func government_scope()->String:
	return ["founding council","settlement offices","town administration","regional government","territorial government"][clampi(government_stage,0,4)]


## The central offices and their titles by form and rank (active_offices).
const OFFICE_DEFINITIONS:=[
	{"key":"Steward","unlock":0,"titles":{"centralized":["Hearth Chief","Chief Steward","First Administrator","First Minister","Executive Minister"],"federated":["First Speaker","Senior Steward","Council Speaker","First Councillor","Federal Convenor"],"localist":["Hearth Elder","Settlement Speaker","Civic Convenor","Senior Delegate","Commonwealth Speaker"]}},
	{"key":"Quartermaster","unlock":1,"titles":{"centralized":["Keeper of Stores","Chief Provisioner","Supply Prefect","Minister of Stores","Supply Minister"],"federated":["Storekeeper","Provisioning Delegate","Supply Councillor","Provisioning Secretary","Federal Quartermaster"],"localist":["Stores Keeper","Market Steward","Provisioning Convenor","Supply Delegate","Commons Provisioner"]}},
	{"key":"Marshal","unlock":2,"titles":{"centralized":["Watch Captain","War Leader","Security Prefect","Marshal","Defense Minister"],"federated":["Watch Speaker","Defense Delegate","Defense Councillor","Federal Marshal","Defense Secretary"],"localist":["Watch Keeper","Shield Speaker","Defense Convenor","Militia Delegate","Commons Marshal"]}},
	{"key":"Scholar","unlock":3,"titles":{"centralized":["Lore Keeper","Keeper of Records","Chief Examiner","Chancellor of Inquiry","Knowledge Minister"],"federated":["Memory Keeper","Inquiry Delegate","Learned Councillor","Research Secretary","Federal Chancellor"],"localist":["Story Keeper","Learning Speaker","Inquiry Convenor","Scholars' Delegate","Commons Chancellor"]}},
	# Every band already sends people over the next ridge. The Chief Scout gathers
	# what they saw and says it plainly, from the founding council onward.
	{"key":"ChiefScout","unlock":0,"titles":{"centralized":["Pathfinder","Chief of Scouts","Master of Outriders","Director of Reconnaissance","Intelligence Director"],"federated":["Trail Speaker","Scouting Delegate","Outriders' Councillor","Reconnaissance Secretary","Federal Intelligence Secretary"],"localist":["Trail Keeper","Far-Walker","Wayfinders' Convenor","Scouts' Delegate","Commons Pathfinder"]}},
	{"key":"Envoy","unlock":4,"titles":{"centralized":["Messenger","Chief Emissary","Treaty Prefect","Foreign Secretary","Foreign Minister"],"federated":["Peace Messenger","Emissary Delegate","Treaty Councillor","Federal Envoy","External Secretary"],"localist":["Road Messenger","Guest Speaker","Treaty Convenor","Foreign Delegate","Commons Envoy"]}},
]

func active_offices()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var form:=government_form()
	var cap:=_title_era_cap()
	# The court's form (from discoveries) renames offices from the elders' circle
	# on; the founding hearth council keeps the size-and-form titles above.
	var civic:=CivicStages.current()
	var staged:=int(civic.get("rank",0))>=1
	for definition in OFFICE_DEFINITIONS:
		if government_stage<int(definition.unlock): continue
		var titles:Array=definition.titles.get(form,definition.titles.federated)
		var title:=String(titles[clampi(mini(government_stage,cap),0,titles.size()-1)])
		if cap==0: title=String(STONE_AGE_TITLES.get(String(definition.key),title))
		if staged:
			var stage_title:=CivicStages.office_title(civic,String(definition.key))
			if stage_title!="": title=stage_title
		result.append({"key":String(definition.key),"title":title,"unlock_stage":int(definition.unlock)})
	# Offices that discoveries add (the god's priesthood, judges, a treasury),
	# and that some forms of court abolish again.
	var held:=CivicStages.held()
	for extra_variant in CivicStages.office_definitions():
		var extra:Dictionary=extra_variant
		if not CivicStages.office_open(extra,civic,held,government_stage): continue
		var key:=String(extra.get("key",""))
		var title:=CivicStages.office_title(civic,key)
		if title=="": title=String(extra.get("title",key))
		result.append({"key":key,"title":title,"unlock_stage":int(extra.get("min_government_stage",0)),"added_by":"discovery"})
	return result


## The keys of the offices active_offices lists, in its order and by its own
## tests (the same court readings, in the same order), without titling them:
## titles need the government's form and era, which offices sit does not.
func _active_office_keys()->Array[String]:
	var keys:Array[String]=[]
	var civic:=CivicStages.current()
	for definition in OFFICE_DEFINITIONS:
		if government_stage<int(definition.unlock): continue
		keys.append(String(definition.key))
	var held:=CivicStages.held()
	for extra_variant in CivicStages.office_definitions():
		var extra:Dictionary=extra_variant
		if not CivicStages.office_open(extra,civic,held,government_stage): continue
		keys.append(String(extra.get("key","")))
	return keys


## Office titles follow what the people know, not only how large the state
## has grown: a stone-age band has no "Secretaries". Keys never change.
const STONE_AGE_TITLES:={"Steward":"Hearth Chief","Quartermaster":"Keeper of Stores","Marshal":"War Leader","Scholar":"Lore Keeper","ChiefScout":"Pathfinder","Envoy":"Messenger","Settlement":"Hearth Elder"}

func _title_era_cap()->int:
	## Highest title rank the era supports: stone age 0, first villages 1,
	## first metal or marks 2, iron and letters 4.
	return [0,1,2,4][clampi(_player_era_tier(),0,3)]


## CharacterVoice.era_tier(CharacterVoice.era_tags("player")), asking only
## about the gates era_tier reads, in its order and each at most once. Titles
## are read many times a day, and era_tags tests every gate against every
## known practice. Keep in step with era_tier (test_government_people_system
## compares the two).
static func _player_era_tier()->int:
	var voice:=preload("res://scripts/character_voice.gd")
	var known:Array=voice.known_ids("player")
	var open:Dictionary={}
	var has:=func(tag:String)->bool:
		if not open.has(tag):
			var hit:=false
			if voice.ERA_GATES.has(tag):
				for id in voice.ERA_GATES[tag].ids:
					if known.has(String(id)):
						hit=true
						break
			open[tag]=hit
		return bool(open[tag])
	if has.call("gunpowder") or ((has.call("metal") and has.call("writing")) and (has.call("ships") or has.call("coin"))): return 3
	for tag in ["metal","writing","wheel","riding","coin"]:
		if has.call(tag): return 2
	for tag in ["farming","pottery","dairy","boats","weaving","baking","candles"]:
		if has.call(tag): return 1
	return 0


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
	var civic:=CivicStages.current()
	if int(civic.get("rank",0))>=1 and CivicStages.office_title(civic,"Settlement")!="": return CivicStages.office_title(civic,"Settlement")
	var cap:=_title_era_cap()
	if cap==0: return String(STONE_AGE_TITLES.Settlement)
	return String(options[clampi(mini(government_stage,cap),0,options.size()-1)])


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
	# Dread of the god bends all but the proudest and bravest into flattery;
	# a love the god has openly kindled, without dread, makes people frank.
	if fear>=0.6 and not (pride>0.75 and courage>0.7):
		return {"id":"sycophantic","label":"EAGERLY DEFERENTIAL","description":"Frightened of your anger: quick to praise and agree, slow to bring bad news."}
	var love:Variant=relationship.get("love",null)
	if (love is float or love is int) and float(love)>=0.72 and fear<0.3 and honesty>=0.35:
		return {"id":"principled","label":"PLAIN-SPOKEN","description":"Loves you enough to tell you the truth, unasked."}
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
	var settlements:=WorldSimulation.settlements.lived_in().size()
	var offices:=_active_office_keys().size()
	var ordinary:=clampi(3+government_stage*4+settlements*2+offices,6,NORMAL_GOVERNMENT_POOL)
	return mini(MAX_GOVERNMENT_PEOPLE,maxi(ordinary,settlements+offices+4))


func _ensure_pool()->void:
	var target:=mini(_desired_pool_size(),maxi(1,WorldSimulation.state.population_total))
	var living_count:=0
	for person in people:
		if String(person.get("status","active"))=="active":living_count+=1
	# The cap bounds the active roster, not the historical record. Dead officials
	# retain their identity and history without blocking later generations.
	while living_count<target:
		people.append(_generate_person(next_person_id))
		living_count+=1
		next_person_id+=1
		revision+=1


func _generate_person(person_id:int)->Dictionary:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:government_person:%d" % [WorldSimulation.state.world_seed,person_id])
	# Names follow what the people know (era_names.gd); drawn after skills so a
	# stone-age epithet can say what the band values in them.
	var woman:=posmod(hash("%d:government_sex:%d" % [WorldSimulation.state.world_seed,person_id]),2)==0
	rng.randi(); rng.randi()   # the two draws the older naming used, so ages and skills keep their seeds
	var age:=rng.randi_range(18,58)
	var death_age:=adult_death_age(rng,age,float(WorldSimulation.state.projected_life_expectancy()))
	var skills:Dictionary={}
	for skill in SKILL_KEYS: skills[skill]=clampi(roundi(rng.randfn(47.0,11.0)),22,72)
	# Every public figure has an intelligible comparative advantage and a real
	# limitation. This prevents a candidate slate of statistically identical
	# generalists while still allowing rare broadly capable people.
	var primary_index:=posmod(person_id-1+int(WorldSimulation.state.world_seed%SKILL_KEYS.size()),SKILL_KEYS.size())
	var secondary_index:=posmod(primary_index+2+rng.randi_range(0,2),SKILL_KEYS.size())
	while secondary_index==primary_index: secondary_index=posmod(secondary_index+1,SKILL_KEYS.size())
	var weak_index:=posmod(primary_index+4+rng.randi_range(0,2),SKILL_KEYS.size())
	while weak_index==primary_index or weak_index==secondary_index: weak_index=posmod(weak_index+1,SKILL_KEYS.size())
	skills[String(SKILL_KEYS[primary_index])]=rng.randi_range(72,93)
	skills[String(SKILL_KEYS[secondary_index])]=maxi(int(skills[String(SKILL_KEYS[secondary_index])]),rng.randi_range(58,82))
	skills[String(SKILL_KEYS[weak_index])]=rng.randi_range(14,36)
	var era_names:=preload("res://scripts/era_names.gd")
	var owner:=String(WorldSimulation.actor_id) if String(WorldSimulation.actor_id)!="" else "player"
	var used_names:Dictionary=era_names.used_in_court() if owner=="player" else {}
	for existing_person in people:
		if String(existing_person.get("status","active")) in ["active","detained"]:
			used_names[String(existing_person.get("name",""))]=true
			used_names["given:"+era_names.given_of(String(existing_person.get("name","")))]=true
	var identity:Dictionary=era_names.make(int(WorldSimulation.state.world_seed),person_id,woman,owner,used_names,{"skill":String(SKILL_KEYS[primary_index])})
	var name:=String(identity.get("name","Nameless"))
	# A second person of the same name and place is told apart the way people
	# are: the younger, then the third, never a stray letter.
	var taken:={}
	for existing in people:taken[String(existing.get("name",""))]=true
	if taken.has(name):
		for word in ["the Younger","the Third","the Fourth","the Fifth"]:
			if not taken.has("%s %s" % [name,word]):name="%s %s" % [name,word];break
	var trait_a:=String(TRAITS[rng.randi_range(0,TRAITS.size()-1)])
	var trait_b:=String(TRAITS[rng.randi_range(0,TRAITS.size()-1)])
	while trait_b==trait_a: trait_b=String(TRAITS[rng.randi_range(0,TRAITS.size()-1)])
	var personality:Dictionary=preload("res://scripts/leader_personality.gd").generate(rng)
	var doctrine:="directive" if float(personality.assertiveness)>0.68 else ("representative" if float(personality.empathy)>0.68 else ("measured" if float(personality.discipline)>0.66 else ("territorial" if float(personality.risk_tolerance)<0.36 else "federated")))
	var background:=_background_for_skills(skills)
	var settlements:=WorldSimulation.state.player_settlements
	var home_id:=String(settlements[posmod(person_id-1,settlements.size())].get("id","")) if not settlements.is_empty() else ""
	var born_day:=int(WorldSimulation.state.elapsed_days)-age*365-rng.randi_range(0,364)
	var profile:=_dynamic_profile(skills,personality)
	return {
		"person_id":person_id,"name":name,"given":String(identity.get("given","")),"family":String(identity.get("family","")),"sex":"female" if woman else "male","born_day":born_day,"death_age_years":death_age,"adult_life":1,"died_day":-1,"status":"active","known_since_day":int(WorldSimulation.state.elapsed_days),
		"home_settlement_id":home_id,"office_key":"","local_leader_of":"","appointed_day":-1,"experience_months":0,"aged_years":0,
		"background":background,"institutional":false,"traits":[trait_a,trait_b],"personality":personality,"skills":skills,"doctrine":doctrine,
		"dynamic_profile":profile,"subcategory_profile":{},"support":clampi(roundi(28.0+float(profile.culture)*34.0+float(profile.institutions)*26.0),18,92),
		"beliefs":[],"memories":[],"goals":["serve_home","preserve_reputation"],
		"relationships":{"sovereign":{"trust":rng.randf_range(0.30,0.76),"respect":rng.randf_range(0.30,0.80),"fear":rng.randf_range(0.03,0.32),"resentment":0.0,"obligation":rng.randf_range(0.28,0.72)}},
		"honesty":rng.randf_range(0.30,0.94),"courage":rng.randf_range(0.24,0.92),"pride":rng.randf_range(0.16,0.88),"suspicion":rng.randf_range(0.12,0.86),
	}


static func adult_death_age(rng:RandomNumberGenerator,age:int,life_expectancy_at_birth:float)->float:
	## A public person is already grown, so the hard years of infancy are behind
	## them: birth expectancy (often 20-35 in early eras) says little about when
	## an adult dies. Adult life tables of foragers and early farmers put the
	## years still to come at about 35-40 at twenty and 20-25 at forty, so a
	## grown person usually reaches 55-65. `old` is the age the grown reach in
	## this era; the years remaining shrink as a person nears it.
	var old:=clampf(62.0+(life_expectancy_at_birth-30.0)*0.35,60.0,80.0)
	var remaining:=maxf(4.0,(old+16.0-float(age))*0.6)
	return clampf(float(age)+rng.randfn(remaining,remaining*0.4),float(age)+2.0,105.0)


func admit_person(identity:Dictionary)->Dictionary:
	## A commoner the god raises into public life (court_persons.gd): generated
	## like any public person, then given the identity the court already knows.
	## Offices still come only through mark_central_appointment and its rules.
	initialize()
	var living_count:=0
	for person in people:
		if String(person.get("status","active"))=="active": living_count+=1
	if living_count>=MAX_GOVERNMENT_PEOPLE: return {}
	var person:=_generate_person(next_person_id)
	next_person_id+=1
	if String(identity.get("name",""))!="": person["name"]=String(identity.name).substr(0,80)
	if identity.get("born_day") is int or identity.get("born_day") is float:
		person["born_day"]=int(identity.born_day)
		person["death_age_years"]=maxf(float(person.get("death_age_years",60.0)),float(age_years(person))+4.0)
	if String(identity.get("home_settlement_id",""))!="": person["home_settlement_id"]=String(identity.home_settlement_id)
	for key in ["courage","honesty","pride"]:
		if identity.get(key) is float or identity.get(key) is int: person[key]=clampf(float(identity[key]),0.0,1.0)
	if String(identity.get("background",""))!="": person["background"]=String(identity.background).substr(0,120)
	person["known_since_day"]=int(WorldSimulation.state.elapsed_days)
	people.append(person)
	revision+=1
	return person_snapshot(int(person.person_id))


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
		"HighPriest": return empathy*0.34+discipline*0.30+openness*0.20+(1.0-risk)*0.16
		"Justice": return discipline*0.40+empathy*0.25+(1.0-risk)*0.20+openness*0.15
		"Treasurer": return discipline*0.45+(1.0-risk)*0.30+openness*0.15+empathy*0.10
		"ChiefScout":
			# Curiosity to look, nerve to go close, and enough discipline to count.
			var courage:=clampf(float(person.get("courage",0.5)),0.0,1.0)
			return openness*0.32+courage*0.22+risk*0.20+discipline*0.18+empathy*0.08
		_: return discipline*0.30+empathy*0.25+assertiveness*0.20+openness*0.15+(1.0-risk)*0.10


func office_competency(person:Dictionary,office_key:String)->float:
	var weights:Dictionary=OFFICE_SKILL_WEIGHTS.get(office_key,OFFICE_SKILL_WEIGHTS.SettlementLeader)
	var skill_fit:=_weighted_canonical_competency(person,weights)
	var experience:=minf(0.08,float(person.get("experience_months",0))/1440.0*0.08)
	return clampf(skill_fit*0.86+_personality_fit(person,office_key)*0.14+experience,0.0,1.0)


func dynamic_competency(person:Dictionary,dynamic_id:String)->float:
	return _weighted_canonical_competency(person,DYNAMIC_SKILL_WEIGHTS.get(dynamic_id,{}))


func office_is_active(office_key:String)->bool:
	# A central office whose rank the government has reached is listed ahead
	# of anything a discovery adds; it needs no reading of the court.
	for definition in OFFICE_DEFINITIONS:
		if String(definition.key)==office_key and government_stage>=int(definition.unlock): return true
	return office_key in _active_office_keys()


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
	for possible in ["Steward","Quartermaster","Marshal","Scholar","Envoy","ChiefScout","SettlementLeader"]:
		var possible_fit:=office_competency(person,possible)
		if possible_fit>best_fit:
			best_fit=possible_fit
			best_office=possible
	var weakness_text:="%s %d limits this portfolio" % [String(weakest.skill),int(weakest.value)]
	if best_office!=office_key and best_fit-office_competency(person,office_key)>=0.08:
		weakness_text="Better suited to %s; appointing here forgoes that advantage" % ("local leadership" if best_office=="SettlementLeader" else ("scouting" if best_office=="ChiefScout" else best_office))
	var current_duty:=String(person.get("office_key",""))
	if current_duty=="" and String(person.get("local_leader_of",""))!="": current_duty="Settlement leader"
	var known_days:=maxi(0,int(WorldSimulation.state.elapsed_days)-int(person.get("known_since_day",int(WorldSimulation.state.elapsed_days))))
	var experience_months:=int(person.get("experience_months",0))
	var record:="LITTLE TESTED"
	if known_days>=5*365 or experience_months>=48: record="ESTABLISHED RECORD"
	elif known_days>=365 or experience_months>=12: record="SOME RECORD"
	var support:=int(person.get("support",50))
	var standing:="DIVIDED REPUTATION" if support<40 else ("BROADLY REGARDED" if support>=68 else "MIXED STANDING")
	var public_concern:=String(PUBLIC_DOUBTS.get(String(weakest.skill),"Their limits are not yet well understood"))
	if best_office!=office_key and best_fit-office_competency(person,office_key)>=0.08:
		public_concern="Some expect their abilities would be better used in %s" % ("local leadership" if best_office=="SettlementLeader" else ("scouting" if best_office=="ChiefScout" else String(best_office).to_lower()))
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
	var current_day:=int(WorldSimulation.state.elapsed_days) if day<0 else day
	var end_day:=int(person.get("died_day",current_day)) if int(person.get("died_day",-1))>=0 else current_day
	return maxi(0,floori(float(end_day-int(person.get("born_day",0)))/365.0))


func _person_record(person_id:int)->Dictionary:
	for person in people:
		if int(person.get("person_id",0))==person_id:return person
	return {}

func person_snapshot(person_id:int)->Dictionary:
	var person:=_person_record(person_id)
	if person.is_empty():return {}
	if not person.has("early_art_index") or not person.has("early_art_profile"):_assign_early_art_indices()
	var snapshot:=person.duplicate(true)
	snapshot["age"]=age_years(person)
	# Carry ownership out of scoped opponent queries so presentation cannot
	# accidentally choose the player's appearance after the scope closes.
	snapshot["appearance_civ_id"]=WorldSimulation.actor_id
	snapshot["appearance_world_seed"]=GameState.world_seed
	return snapshot

func _assign_early_art_indices()->void:
	# Saved appearance belongs to a person, never to their current office.
	# Prioritize the visible cabinet when upgrading an existing save. Reuse is
	# unavoidable beyond the four illustrated people; balance it across the cast.
	# Keep the authored family name in save data. Growing the future art library
	# must not change an established person's appearance through modulo changes.
	var family:String=preload("res://scripts/character_appearance.gd").family_for(GameState.world_seed,WorldSimulation.actor_id,people)
	var ordered:Array[Dictionary]=[]
	var added:Dictionary={}
	for office in active_offices():
		var holder:Dictionary=WorldSimulation.state.leadership_positions.get(String(office.key),{})
		var record:=_person_record(int(holder.get("person_id",0)))
		if not record.is_empty() and not added.has(int(record.person_id)):
			ordered.append(record);added[int(record.person_id)]=true
	for record in people:
		if not added.has(int(record.person_id)):ordered.append(record)
	var usage:=[0,0,0,0]
	for record in ordered:
		if record.has("early_art_index"):usage[posmod(int(record.early_art_index),4)]+=1
	for record in ordered:
		if not record.has("early_art_profile"):record["early_art_profile"]=family
		if record.has("early_art_index"):continue
		var slot:=0
		for candidate in range(1,4):
			if usage[candidate]<usage[slot]:slot=candidate
		record["early_art_index"]=slot;usage[slot]+=1


func adjust_person_relationship(person_id:int,trust_delta:float=0.0,respect_delta:float=0.0,resentment_delta:float=0.0)->Dictionary:
	## Dialogue changes the same durable relationship used by later execution.
	## Keep the bounded government cast, advisor roster, and office snapshots in
	## sync so opening a different panel cannot silently revert the exchange.
	return adjust_person_bonds(person_id,{"trust":trust_delta,"respect":respect_delta,"resentment":resentment_delta})


const BOND_KEYS:=["trust","respect","fear","resentment","obligation","love"]
const BOND_DEFAULTS:={"trust":0.5,"respect":0.5,"fear":0.0,"resentment":0.0,"obligation":0.4,"love":0.5}

func adjust_person_bonds(person_id:int,deltas:Dictionary)->Dictionary:
	## Any of the sovereign bonds, each clamped to 0..1. "love" is optional on
	## older records: it is first set from how the person already stands (see
	## divine_regard.gd) and then moved, so every change is relative.
	var index:=_find_person_index(person_id)
	if index<0: return {}
	var relationships:Dictionary=people[index].get("relationships",{})
	var sovereign:Dictionary=relationships.get("sovereign",{"trust":0.5,"respect":0.5,"fear":0.0,"resentment":0.0,"obligation":0.4})
	if deltas.has("love") and not (sovereign.get("love") is float or sovereign.get("love") is int):
		sovereign["love"]=preload("res://scripts/divine_regard.gd").derived_love(sovereign)
	for key:String in BOND_KEYS:
		if not deltas.has(key): continue
		var delta:=float(deltas[key])
		if not is_finite(delta): continue
		sovereign[key]=clampf(float(sovereign.get(key,BOND_DEFAULTS[key]))+delta,0.0,1.0)
	# Fading stamps (divine_regard.gd fade): a big act holds its dread for a
	# while, and fresh resentment restarts the quiet spell before it eases.
	var today:=int(WorldSimulation.state.elapsed_days)
	var hold_days:=int(deltas.get("hold_days",0)) if (deltas.get("hold_days") is int or deltas.get("hold_days") is float) else 0
	if hold_days>0:
		var held_until:=int(float(sovereign.get("dread_hold",-1))) if (sovereign.get("dread_hold") is int or sovereign.get("dread_hold") is float) else -1
		sovereign["dread_hold"]=maxi(held_until,today+mini(hold_days,400))
	if float(deltas.get("resentment",0.0))>0.0: sovereign["resent_day"]=today
	relationships["sovereign"]=sovereign
	people[index]["relationships"]=relationships
	for roster_index in WorldSimulation.state.advisor_roster.size():
		if int(WorldSimulation.state.advisor_roster[roster_index].get("person_id",0))!=person_id: continue
		WorldSimulation.state.advisor_roster[roster_index]["relationships"]=relationships.duplicate(true)
	for office_key in WorldSimulation.state.leadership_positions:
		if int((WorldSimulation.state.leadership_positions[office_key] as Dictionary).get("person_id",0))!=person_id: continue
		WorldSimulation.state.leadership_positions[office_key]["relationships"]=relationships.duplicate(true)
	revision+=1
	return sovereign.duplicate(true)


func _fade_bonds(day:int)->void:
	## Love, dread and resentment drift back toward each person's own baseline
	## (divine_regard.gd fade). Elapsed-day based, so multi-day steps match
	## daily ones. Office and roster copies follow the person record.
	var divine:=preload("res://scripts/divine_regard.gd")
	var changed:Dictionary={}
	for person:Dictionary in people:
		if String(person.get("status","active"))!="active": continue
		if divine.fade(person,day): changed[int(person.get("person_id",0))]=person.relationships
	if changed.is_empty(): return
	for roster_index in WorldSimulation.state.advisor_roster.size():
		var roster_id:=int(WorldSimulation.state.advisor_roster[roster_index].get("person_id",0))
		if changed.has(roster_id): WorldSimulation.state.advisor_roster[roster_index]["relationships"]=(changed[roster_id] as Dictionary).duplicate(true)
	for office_key in WorldSimulation.state.leadership_positions:
		var holder_id:=int((WorldSimulation.state.leadership_positions[office_key] as Dictionary).get("person_id",0))
		if changed.has(holder_id): WorldSimulation.state.leadership_positions[office_key]["relationships"]=(changed[holder_id] as Dictionary).duplicate(true)


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
		"created_day":int(WorldSimulation.state.elapsed_days),
		"last_recalled_day":int(WorldSimulation.state.elapsed_days),
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
	for roster_index in WorldSimulation.state.advisor_roster.size():
		if int(WorldSimulation.state.advisor_roster[roster_index].get("person_id",0))==person_id:
			WorldSimulation.state.advisor_roster[roster_index]["memories"]=memories.duplicate(true)
	for office_key in WorldSimulation.state.leadership_positions:
		if int((WorldSimulation.state.leadership_positions[office_key] as Dictionary).get("person_id",0))==person_id:
			WorldSimulation.state.leadership_positions[office_key]["memories"]=memories.duplicate(true)
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
		if settlement_id!="" and String(person.get("local_leader_of","")) not in ["",settlement_id]: continue
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
		var incumbent_id:=int((WorldSimulation.state.leadership_positions.get(office_key,{}) as Dictionary).get("person_id",0))
		candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
			var a_incumbent:=int(a.get("person_id",0))==incumbent_id
			var b_incumbent:=int(b.get("person_id",0))==incumbent_id
			if a_incumbent!=b_incumbent: return a_incumbent
			var a_order:=posmod(hash("%d:%s:shortlist:%d" % [WorldSimulation.state.world_seed,office_key,int(a.get("person_id",0))]),2147483647)
			var b_order:=posmod(hash("%d:%s:shortlist:%d" % [WorldSimulation.state.world_seed,office_key,int(b.get("person_id",0))]),2147483647)
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
	# retained for save compatibility and development tools; normal play assigns
	# successors automatically.
	var former_office:=String(people[index].get("office_key",""))
	if former_office!="" and former_office!=office_key:
		WorldSimulation.state.leadership_positions.erase(former_office)
	for other_index in people.size():
		if String(people[other_index].get("office_key",""))==office_key:
			people[other_index]["office_key"]=""
			people[other_index]["office_title"]=""
		if int(people[other_index].get("person_id",0))==person_id and other_index!=index:
			people[other_index]["office_key"]=""
			people[other_index]["office_title"]=""
	people[index]["office_key"]=office_key
	people[index]["appointed_day"]=int(WorldSimulation.state.elapsed_days)
	people[index]["office_title"]=String(office.title)
	WorldSimulation.state.leadership_positions[office_key]=person_snapshot(person_id)
	# At founding scale the central polity and its only settlement are the same
	# community. The Steward therefore carries the local duty too; we do not
	# invent a second layer of government for 120 residents.
	if office_key=="Steward" and government_stage==0 and WorldSimulation.state.player_settlements.size()==1:
		assign_settlement_leader(String(WorldSimulation.state.player_settlements[0].get("id","")),person_id)
	revision+=1
	_sync_advisor_roster()
	return person_snapshot(person_id)


func _synchronize_office_holders(events:Array[Dictionary]=[],record_events:bool=false)->void:
	# Nothing below changes what offices exist before the holders are titled,
	# so the offices are read once (office_definition reads them per key).
	var active_keys:Array[String]=[]
	var titles:Dictionary={}
	for office in active_offices():
		active_keys.append(String(office.key))
		if not titles.has(String(office.key)): titles[String(office.key)]=String(office.title)
	for person_index in people.size():
		var assigned_key:=String(people[person_index].get("office_key",""))
		if assigned_key!="" and assigned_key not in active_keys:
			people[person_index]["office_key"]=""
			people[person_index]["office_title"]=""
	for key_variant in WorldSimulation.state.leadership_positions.keys():
		var key:=String(key_variant)
		var holder:Dictionary=WorldSimulation.state.leadership_positions.get(key,{})
		var person_id:=int(holder.get("person_id",0))
		var person:=person_snapshot(person_id)
		if key not in active_keys or person.is_empty() or String(person.get("status",""))!="active":
			WorldSimulation.state.leadership_positions.erase(key)
			continue
		person["office_title"]=String(titles[key])
		WorldSimulation.state.leadership_positions[key]=person
	# Every available office remains staffed. The sovereign judges results and may
	# remove an officeholder, but does not sort candidate slates. Selection uses a
	# stable seed-dependent order, so a save reload never rerolls its government.
	for key in active_keys:
		if key in WorldSimulation.state.leadership_positions: continue
		var predecessor:=_last_holder_of(key)
		var successor:=_automatic_successor(key,0,predecessor)
		if successor.is_empty(): continue
		var person:=mark_central_appointment(int(successor.person_id),key)
		if person.is_empty(): continue
		if record_events:
			var event_title:="Local Succession" if key=="Steward" and government_stage==0 else "%s Appointed" % String(office_definition(key).title)
			var why:=succession_words(String(successor.get("succession_rule","ablest")),String(_person_record(predecessor).get("name","")))
			var description:="%s now carries the founding council and local leadership of %s, %s." % [String(person.get("name","A successor")),String(WorldSimulation.state.player_settlements[0].get("name","the settlement")),why] if key=="Steward" and government_stage==0 and WorldSimulation.state.player_settlements.size()==1 else "%s was chosen to serve as %s: %s." % [String(person.get("name","A successor")),String(office_definition(key).title),why]
			events.append({"day":int(WorldSimulation.state.elapsed_days),"title":event_title,"description":description,"domain":"institutions","severity":"notice"})


## Who fills an office by the stated rule (succession_rule): the eldest able
## kin of the one who held it, where custom keeps the seat in a house; else
## the ablest the council knows, by its judgement of their fit
## (estimated_fit: true fit seen through an error that shrinks with service
## and acquaintance). Someone without another central office first; local
## and central duty may overlap in a small polity, as the founding Steward
## shows. The candidate carries "succession_rule" ("kin" or "ablest").
func _automatic_successor(office_key:String,excluded_person_id:int=0,predecessor_id:int=0)->Dictionary:
	# Read the candidates without reconciling the government first: that would
	# fill the very office being decided here by a second, nested choice.
	var was:=initializing
	initializing=true
	var candidates:=candidates_for_office(office_key,"",MAX_GOVERNMENT_PEOPLE,false)
	initializing=was
	if _founding:
		# The founders' places, as the hearth chose them (a stable seed order).
		for candidate in candidates:
			if int(candidate.get("person_id",0))!=excluded_person_id and String(candidate.get("office_key",""))=="": return candidate.merged({"succession_rule":"founding"})
		for candidate in candidates:
			if int(candidate.get("person_id",0))!=excluded_person_id: return candidate.merged({"succession_rule":"founding"})
		return {}
	if succession_rule()=="kin" and predecessor_id>0:
		var heir:=_eldest_able_kin(predecessor_id,office_key,candidates,excluded_person_id)
		if not heir.is_empty():
			heir["succession_rule"]="kin"
			return heir
	for free_only in [true,false]:
		var best:Dictionary={}
		var best_fit:=-1.0
		for candidate in candidates:
			if int(candidate.get("person_id",0))==excluded_person_id: continue
			if free_only and String(candidate.get("office_key",""))!="": continue
			var guess:=estimated_fit(candidate,office_key)
			if guess>best_fit+0.000001: best_fit=guess; best=candidate
		if not best.is_empty():
			best["succession_rule"]="ablest"
			return best
	return {}


## How this people fills an empty office: "kin" where its order is
## centralized (a chief's house keeps the seat: the eldest able kin of the
## last holder), else "ablest" (the council's best judgement of fit).
func succession_rule()->String:
	return "kin" if government_form()=="centralized" else "ablest"

## The rule in plain words, for the chronicle and the court.
func succession_words(rule:String,predecessor_name:String="")->String:
	if rule=="kin": return "as custom keeps the seat in the house of %s, the eldest of their kin able to hold it" % (predecessor_name if predecessor_name!="" else "the last holder")
	return "the ablest the council knows for the work, by its own judgement"

## The least office fit an heir must show to inherit a seat.
const HEIR_MIN_FIT:=0.40

func _eldest_able_kin(predecessor_id:int,office_key:String,candidates:Array[Dictionary],excluded_person_id:int)->Dictionary:
	var kin_ids:Dictionary={}
	for link in _person_record(predecessor_id).get("kin",[]):
		if link is Dictionary: kin_ids[int((link as Dictionary).get("pid",0))]=true
	var eldest:Dictionary={}
	for candidate in candidates:
		var pid:=int(candidate.get("person_id",0))
		if pid==excluded_person_id or not kin_ids.has(pid) or String(candidate.get("office_key",""))!="": continue
		if office_competency(candidate,office_key)<HEIR_MIN_FIT: continue
		if eldest.is_empty() or int(candidate.get("born_day",0))<int(eldest.get("born_day",0)): eldest=candidate
	return eldest

## The council's judgement of someone's fit for an office (0..1): their
## true fit seen through a seeded error of up to FIT_GUESS_ERROR that shrinks
## as they serve (experience_months, sure at 48) and as the court comes to
## know them (eight years).
const FIT_GUESS_ERROR:=0.10

func estimated_fit(person:Dictionary,office_key:String)->float:
	var fit:=office_competency(person,office_key)
	return clampf(fit+_guess_noise(person,office_key)*FIT_GUESS_ERROR*(1.0-how_sure(person)),0.0,1.0)

## How well the court knows someone's work, 0..1.
func how_sure(person:Dictionary)->float:
	var months:=float(person.get("experience_months",0))
	var known:=maxf(0.0,float(WorldSimulation.state.elapsed_days)-float(person.get("known_since_day",WorldSimulation.state.elapsed_days)))
	return clampf(months/48.0+known/(365.0*8.0),0.0,1.0)

func _guess_noise(person:Dictionary,office_key:String)->float:
	return float(posmod(hash("%d:fit_guess:%s:%d" % [WorldSimulation.state.world_seed,office_key,int(person.get("person_id",0))]),2001)-1000)/1000.0

## The free people the council would weigh for an office, best judged fit
## first: [{person_id, name, fit (judged), low, high, sure}]. Those holding
## another central office and the holder themselves are left out.
func shortlist(office_key:String,limit:int=3)->Array[Dictionary]:
	if not initializing: initialize()
	var out:Array[Dictionary]=[]
	var holder_id:=int((WorldSimulation.state.leadership_positions.get(office_key,{}) as Dictionary).get("person_id",0))
	for person in people:
		if String(person.get("status",""))!="active" or String(person.get("office_key",""))!="" or int(person.get("person_id",0))==holder_id: continue
		var guess:=estimated_fit(person,office_key)
		var spread:=FIT_GUESS_ERROR*(1.0-how_sure(person))
		out.append({"person_id":int(person.get("person_id",0)),"name":String(person.get("name","")),"fit":guess,"low":clampf(guess-spread,0.0,1.0),"high":clampf(guess+spread,0.0,1.0),"sure":how_sure(person)})
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.fit)>float(b.fit) if absf(float(a.fit)-float(b.fit))>0.000001 else int(a.person_id)<int(b.person_id))
	if out.size()>limit: out.resize(limit)
	return out

## The one who held an office and died in it this past month (for the kin
## rule); 0 when the office is new or long empty.
func _last_holder_of(office_key:String)->int:
	var last:=-1
	var who:=0
	var since:=int(WorldSimulation.state.elapsed_days)-MONTH_DAYS-1
	for person in people:
		if String(person.get("died_office_key",""))!=office_key or int(person.get("died_day",-1))<since: continue
		if int(person.get("died_day",-1))>last: last=int(person.get("died_day",-1)); who=int(person.get("person_id",0))
	return who


func remove_central_officeholder(office_key:String,action:String="dismiss")->Dictionary:
	initialize()
	var normalized:="execute" if action.to_lower() in ["kill","execute"] else "dismiss"
	var previous:=officeholder(office_key)
	if previous.is_empty(): return {"ok":false,"reason":"That office has no holder to remove."}
	var previous_id:=int(previous.get("person_id",0))
	var index:=_find_person_index(previous_id)
	if index<0: return {"ok":false,"reason":"That officeholder is no longer available."}
	people[index]["office_key"]=""
	people[index]["office_title"]=""
	people[index]["removed_day"]=int(WorldSimulation.state.elapsed_days)
	people[index]["removal_reason"]="executed" if normalized=="execute" else "dismissed"
	WorldSimulation.state.leadership_positions.erase(office_key)
	# If this person also leads a settlement, that local office passes through the
	# same automatic succession machinery.
	var local_id:=String(people[index].get("local_leader_of",""))
	if normalized=="execute":
		people[index]["status"]="deceased"
		people[index]["died_day"]=int(WorldSimulation.state.elapsed_days)
		people[index]["local_leader_of"]=""
		WorldSimulation.state.register_directive_population_deaths(1,"officeholder_execution","%s was executed by sovereign order." % String(previous.get("name","An officeholder")),{"exact_count":1,"label":"named officeholder"})
		WorldSimulation.state.simulation_metrics["legitimacy"]=clampf(float(WorldSimulation.state.simulation_metrics.get("legitimacy",0.5))-0.08,0.01,0.99)
		WorldSimulation.state.simulation_metrics["cohesion"]=clampf(float(WorldSimulation.state.simulation_metrics.get("cohesion",0.5))-0.05,0.01,0.99)
	elif local_id!="":
		people[index]["local_leader_of"]=""
	if local_id!="":
		for settlement_index in WorldSimulation.state.player_settlements.size():
			if String(WorldSimulation.state.player_settlements[settlement_index].get("id",""))==local_id:
				WorldSimulation.state.player_settlements[settlement_index]["leader_person_id"]=0
				break
	_ensure_pool()
	var successor:=_automatic_successor(office_key,previous_id)
	var appointed:Dictionary={}
	if not successor.is_empty(): appointed=mark_central_appointment(int(successor.person_id),office_key)
	_ensure_local_leaders()
	var verb:="executed" if normalized=="execute" else "dismissed"
	var successor_text:=" %s took office automatically." % String(appointed.get("name","A successor")) if not appointed.is_empty() else " The office remains vacant."
	var event:Dictionary={"day":int(WorldSimulation.state.elapsed_days),"title":"Officeholder Executed" if normalized=="execute" else "Officeholder Dismissed","description":"%s was %s as %s.%s" % [String(previous.get("name","The officeholder")),verb,String(previous.get("office_title",office_key)),successor_text],"domain":"institutions","severity":"major" if normalized=="execute" else "notice"}
	WorldSimulation.state.simulation_events.push_front(event)
	if WorldSimulation.state.simulation_events.size()>80: WorldSimulation.state.simulation_events.resize(80)
	revision+=1
	_sync_advisor_roster()
	return {"ok":true,"action":normalized,"former":previous,"successor":appointed,"event":event,"message":event.description}


func officeholder(office_key:String)->Dictionary:
	initialize()
	var holder:Dictionary=WorldSimulation.state.leadership_positions.get(office_key,{})
	if holder.is_empty(): return {}
	var person:=person_snapshot(int(holder.get("person_id",0)))
	if person.is_empty(): return {}
	person["office_title"]=String(office_definition(office_key).title)
	return person


## Whether officeholder(office_key) would name someone, with the same
## reconciliation and record upkeep (person_snapshot's art indices), without
## copying the person or listing the offices for a title.
func has_officeholder(office_key:String)->bool:
	initialize()
	var holder:Dictionary=WorldSimulation.state.leadership_positions.get(office_key,{})
	if holder.is_empty(): return false
	var person:=_person_record(int(holder.get("person_id",0)))
	if person.is_empty(): return false
	if not person.has("early_art_index") or not person.has("early_art_profile"):_assign_early_art_indices()
	return true


func assign_settlement_leader(settlement_id:String,person_id:int)->Dictionary:
	var person_index:=_find_person_index(person_id)
	if person_index<0 or String(people[person_index].get("status",""))!="active": return {"ok":false,"reason":"That person is not available."}
	var settlement_index:=-1
	for index in WorldSimulation.state.player_settlements.size():
		if String(WorldSimulation.state.player_settlements[index].get("id",""))==settlement_id: settlement_index=index; break
	if settlement_index<0: return {"ok":false,"reason":"That settlement is not owned."}
	# Nobody lives in a place its people left: nobody is named to lead it.
	if WorldSimulation.settlements.abandoned(WorldSimulation.state.player_settlements[settlement_index]): return {"ok":false,"reason":WorldSimulation.settlements.left_reason(WorldSimulation.state.player_settlements[settlement_index])}
	if government_stage==0 and WorldSimulation.state.player_settlements.size()==1:
		var steward_id:=int((WorldSimulation.state.leadership_positions.get("Steward",{}) as Dictionary).get("person_id",0))
		if steward_id>0 and person_id!=steward_id:
			return {"ok":false,"reason":"The founding council and its only settlement are still one office. Replace the founding leader instead."}
	# A person can lead only one settlement. Reconciliation fills the vacated
	# post through the ordinary successor pool, retaining all personal history.
	for index in WorldSimulation.state.player_settlements.size():
		if index!=settlement_index and int(WorldSimulation.state.player_settlements[index].get("leader_person_id",0))==person_id:
			WorldSimulation.state.player_settlements[index]["leader_person_id"]=0
	for other_index in people.size():
		if String(people[other_index].get("local_leader_of",""))==settlement_id: people[other_index]["local_leader_of"]=""
	people[person_index]["local_leader_of"]=settlement_id
	people[person_index]["home_settlement_id"]=settlement_id
	people[person_index]["appointed_day"]=int(WorldSimulation.state.elapsed_days)
	WorldSimulation.state.player_settlements[settlement_index]["leader_person_id"]=person_id
	WorldSimulation.state.player_settlements[settlement_index]["leader_title"]=settlement_leader_title()
	preload("res://scripts/civic_administration.gd").queue_handovers(self,settlement_id,person_id)
	WorldSimulation.state.settlement_network_revision+=1
	revision+=1
	return {"ok":true,"leader":person_snapshot(person_id),"title":settlement_leader_title()}


func remove_settlement_leader(settlement_id:String,action:String="dismiss")->Dictionary:
	initialize()
	action="execute" if action.to_lower() in ["kill","execute"] else ("arrest" if action.to_lower()=="arrest" else "dismiss")
	var settlement_index:=-1
	for index in WorldSimulation.state.player_settlements.size():
		if String(WorldSimulation.state.player_settlements[index].get("id",""))==settlement_id: settlement_index=index; break
	if settlement_index<0: return {"ok":false,"reason":"That settlement is not owned."}
	var previous_id:=int(WorldSimulation.state.player_settlements[settlement_index].get("leader_person_id",0))
	var previous:=person_snapshot(previous_id)
	if previous.is_empty(): return {"ok":false,"reason":"That settlement has no leader to remove."}
	var arrest:=action=="arrest"
	var execute:=action=="execute"
	var combined_founding_office:=government_stage==0 and WorldSimulation.state.player_settlements.size()==1
	var previous_index:=_find_person_index(previous_id)
	if previous_index>=0:
		people[previous_index]["local_leader_of"]=""
		people[previous_index]["removed_day"]=int(WorldSimulation.state.elapsed_days)
		people[previous_index]["removal_reason"]="executed" if execute else ("arrested" if arrest else "dismissed")
		if arrest: people[previous_index]["status"]="detained"
		if execute:
			people[previous_index]["status"]="deceased"
			people[previous_index]["died_day"]=int(WorldSimulation.state.elapsed_days)
			WorldSimulation.state.register_directive_population_deaths(1,"local_leader_execution","%s was executed by sovereign order." % String(previous.get("name","A local leader")),{"exact_count":1,"label":"named local leader"})
	if combined_founding_office or arrest or execute:
		for office_key_variant in WorldSimulation.state.leadership_positions.keys().duplicate():
			var office_key:=String(office_key_variant)
			if int((WorldSimulation.state.leadership_positions[office_key] as Dictionary).get("person_id",0))!=previous_id: continue
			WorldSimulation.state.leadership_positions.erase(office_key)
		if previous_index>=0:
			people[previous_index]["office_key"]=""
			people[previous_index]["office_title"]=""
	WorldSimulation.state.player_settlements[settlement_index]["leader_person_id"]=0
	WorldSimulation.state.player_settlements[settlement_index]["leader_title"]=settlement_leader_title()
	if execute:
		WorldSimulation.state.simulation_metrics["legitimacy"]=clampf(float(WorldSimulation.state.simulation_metrics.get("legitimacy",0.5))-0.08,0.01,0.99)
		WorldSimulation.state.simulation_metrics["cohesion"]=clampf(float(WorldSimulation.state.simulation_metrics.get("cohesion",0.5))-0.05,0.01,0.99)
	elif arrest:
		WorldSimulation.state.simulation_metrics["legitimacy"]=clampf(float(WorldSimulation.state.simulation_metrics.get("legitimacy",0.5))-0.04,0.01,0.99)
		WorldSimulation.state.simulation_metrics["cohesion"]=clampf(float(WorldSimulation.state.simulation_metrics.get("cohesion",0.5))-0.025,0.01,0.99)
	else:
		WorldSimulation.state.simulation_metrics["legitimacy"]=clampf(float(WorldSimulation.state.simulation_metrics.get("legitimacy",0.5))-0.008,0.01,0.99)
		WorldSimulation.state.simulation_metrics["cohesion"]=clampf(float(WorldSimulation.state.simulation_metrics.get("cohesion",0.5))-0.002,0.01,0.99)
	_ensure_pool()
	var successors:=candidates_for_office("SettlementLeader",settlement_id,MAX_GOVERNMENT_PEOPLE,false)
	# The ablest the council knows for the town (estimated_fit), the same rule
	# as the central offices.
	var successor:Dictionary={}
	var successor_fit:=-1.0
	for candidate_variant in successors:
		var candidate:Dictionary=candidate_variant
		if int(candidate.get("person_id",0))==previous_id: continue
		if String(candidate.get("status","active"))!="active": continue
		var guess:=estimated_fit(candidate,"SettlementLeader")
		if guess>successor_fit+0.000001: successor_fit=guess; successor=candidate
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
		"day":int(WorldSimulation.state.elapsed_days),"title":"Leader Executed" if execute else ("Leader Arrested" if arrest else "Leader Dismissed"),
		"description":"%s was %s as %s of %s.%s" % [String(previous.get("name","The former leader")),"executed" if execute else ("arrested and detained" if arrest else "dismissed"),settlement_leader_title(),String(WorldSimulation.state.player_settlements[settlement_index].get("name","the settlement")),succession_text],
		"domain":"institutions","severity":"major" if arrest or execute else "notice",
	}
	WorldSimulation.state.simulation_events.push_front(event)
	if WorldSimulation.state.simulation_events.size()>80: WorldSimulation.state.simulation_events.resize(80)
	WorldSimulation.state.settlement_network_revision+=1
	revision+=1
	_sync_advisor_roster()
	var legitimacy_cost:=0.08 if execute else (0.04 if arrest else 0.008)
	var cohesion_cost:=0.05 if execute else (0.025 if arrest else 0.002)
	var successor_name:=String(successor_record.get("name","No successor"))
	var message:="%s was %s. %s%s" % [
		String(previous.get("name","The former leader")),"executed" if execute else ("arrested and detained" if arrest else "dismissed"),
		"%s took office. " % successor_name if bool(appointment.get("ok",false)) else "The office remains vacant. ",
		"The execution seriously damaged legitimacy and cohesion." if execute else ("This coercive removal seriously damaged legitimacy and cohesion." if arrest else "The abrupt replacement carried a small legitimacy and cohesion cost."),
	]
	if execute:WorldSimulation.direction.record_cultural_action("execution:%s" % str(previous.get("person_id",previous.get("id",0))),"retribution",2.0)
	return {"ok":true,"action":action,"former":previous,"successor":successor_record,"event":event,"legitimacy_cost":legitimacy_cost,"cohesion_cost":cohesion_cost,"message":message}


func person_departs(person_id:int,reason:String="fled")->Dictionary:
	## An official leaves the ruler's service alive: cast out by decree
	## ("exiled"), bound and kept under guard ("detained") or slipped away in
	## fear ("fled"). Their offices pass through
	## the ordinary succession machinery; they leave the active roster but keep
	## their identity and history.
	initialize()
	var index:=_find_person_index(person_id)
	if index<0 or String(people[index].get("status",""))!="active": return {"ok":false,"reason":"That person is not available."}
	var normalized:=reason if reason in ["exiled","detained"] else "fled"
	var name:=String(people[index].get("name","An official"))
	var offices:Array[String]=[]
	for office_key in WorldSimulation.state.leadership_positions.keys():
		if int((WorldSimulation.state.leadership_positions[office_key] as Dictionary).get("person_id",0))==person_id: offices.append(String(office_key))
	var local_id:=String(people[index].get("local_leader_of",""))
	var successors:Array[String]=[]
	var combined_founding_office:=government_stage==0 and WorldSimulation.state.player_settlements.size()==1 and local_id!=""
	var before_events:=WorldSimulation.state.simulation_events.size()
	if combined_founding_office:
		var removed:=remove_settlement_leader(local_id,"dismiss")
		if bool(removed.get("ok",false)) and not (removed.get("successor",{}) as Dictionary).is_empty(): successors.append(String(removed.successor.get("name","")))
	else:
		for office_key in offices:
			var removed_office:=remove_central_officeholder(office_key,"dismiss")
			if bool(removed_office.get("ok",false)) and not (removed_office.get("successor",{}) as Dictionary).is_empty(): successors.append(String(removed_office.successor.get("name","")))
		index=_find_person_index(person_id)
		if index>=0 and String(people[index].get("local_leader_of",""))!="":
			var removed_local:=remove_settlement_leader(String(people[index].local_leader_of),"dismiss")
			if bool(removed_local.get("ok",false)) and not (removed_local.get("successor",{}) as Dictionary).is_empty(): successors.append(String(removed_local.successor.get("name","")))
	# The ordinary removal notices are replaced by one that says what happened.
	var added:=maxi(0,WorldSimulation.state.simulation_events.size()-before_events)
	if WorldSimulation.state.simulation_events.size()>=80: added=mini(offices.size()+1,WorldSimulation.state.simulation_events.size())
	for i in range(mini(added,WorldSimulation.state.simulation_events.size())-1,-1,-1):
		var existing:Dictionary=WorldSimulation.state.simulation_events[i]
		if String(existing.get("title","")) in ["Officeholder Dismissed","Leader Dismissed"] and String(existing.get("description","")).begins_with(name): WorldSimulation.state.simulation_events.remove_at(i)
	index=_find_person_index(person_id)
	if index<0: return {"ok":false,"reason":"That person is no longer available."}
	people[index]["status"]=normalized
	people[index]["office_key"]=""
	people[index]["office_title"]=""
	people[index]["local_leader_of"]=""
	people[index]["removed_day"]=int(WorldSimulation.state.elapsed_days)
	people[index]["removal_reason"]=normalized
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	if normalized=="fled":
		metrics["cohesion"]=clampf(float(metrics.get("cohesion",0.5))-0.01,0.01,0.99)
	else:
		metrics["legitimacy"]=clampf(float(metrics.get("legitimacy",0.5))-0.01,0.01,0.99)
		metrics["cohesion"]=clampf(float(metrics.get("cohesion",0.5))-0.005,0.01,0.99)
	_ensure_pool()
	_ensure_local_leaders()
	var successor_text:=" %s took up the work." % " and ".join(PackedStringArray(successors)) if not successors.is_empty() else ""
	var event:={"day":int(WorldSimulation.state.elapsed_days),"title":String({"fled":"Official Fled","detained":"Official Imprisoned"}.get(normalized,"Official Cast Out")),
		"description":String({"fled":"%s fled in the night, beyond the hills and out of reach of the ruler's anger.%s","detained":"%s was bound and put under guard by the ruler's decree.%s"}.get(normalized,"%s was cast out of the realm by the ruler's decree.%s")) % [name,successor_text],
		"domain":"institutions","severity":"major" if normalized=="fled" else "notice"}
	WorldSimulation.state.simulation_events.push_front(event)
	if WorldSimulation.state.simulation_events.size()>80: WorldSimulation.state.simulation_events.resize(80)
	revision+=1
	_sync_advisor_roster()
	return {"ok":true,"status":normalized,"person_id":person_id,"name":name,"offices":offices,"successors":successors,"event":event,"message":event.description}


func person_released(person_id:int)->Dictionary:
	## One bound and kept under guard at the ruler's word walks free again. Their
	## offices stay with whoever took them up; they rejoin the council's people
	## and may be appointed again.
	initialize()
	var index:=_find_person_index(person_id)
	if index<0: return {"ok":false,"reason":"That person is not known."}
	if String(people[index].get("status",""))!="detained": return {"ok":false,"reason":"They are not held."}
	people[index]["status"]="active"
	people[index]["released_day"]=int(WorldSimulation.state.elapsed_days)
	_ensure_pool()
	revision+=1
	_sync_advisor_roster()
	return {"ok":true,"person":person_snapshot(person_id)}


func person_put_to_death(person_id:int)->Dictionary:
	## One of the council's people who holds no office now (put out of it, or
	## held under guard) put to death at the ruler's word: one named death
	## through the same conserved entry point; legitimacy and cohesion pay.
	initialize()
	var index:=_find_person_index(person_id)
	if index<0 or String(people[index].get("status","")) not in ["active","detained"]: return {"ok":false,"reason":"That person is not available."}
	if String(people[index].get("office_key",""))!="" or String(people[index].get("local_leader_of",""))!="": return {"ok":false,"reason":"They hold an office; the office passes first."}
	var name:=String(people[index].get("name","A former official"))
	people[index]["status"]="deceased"
	people[index]["died_day"]=int(WorldSimulation.state.elapsed_days)
	people[index]["removal_reason"]="executed"
	WorldSimulation.state.register_directive_population_deaths(1,"person_execution","%s was put to death by sovereign order." % name,{"exact_count":1,"label":"named person"})
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	metrics["legitimacy"]=clampf(float(metrics.get("legitimacy",0.5))-0.05,0.01,0.99)
	metrics["cohesion"]=clampf(float(metrics.get("cohesion",0.5))-0.03,0.01,0.99)
	var event:={"day":int(WorldSimulation.state.elapsed_days),"title":"Put to Death","description":"%s was put to death by the ruler's decree." % name,"domain":"institutions","severity":"major"}
	WorldSimulation.state.simulation_events.push_front(event)
	if WorldSimulation.state.simulation_events.size()>80: WorldSimulation.state.simulation_events.resize(80)
	_ensure_pool()
	revision+=1
	_sync_advisor_roster()
	return {"ok":true,"name":name,"event":event}


func settlement_leader(settlement_id:String)->Dictionary:
	if not initializing: initialize()
	for settlement in WorldSimulation.state.player_settlements:
		if String(settlement.get("id",""))!=settlement_id: continue
		var person:=person_snapshot(int(settlement.get("leader_person_id",0)))
		if person.is_empty(): return {}
		person["title"]=settlement_leader_title()
		return person
	return {}


## A town its people left (dry_towns.gd): its leader steps down without
## blame (no dismissal, no lost office), and everyone whose home it was lives
## in `to_id` from now. Returns how many named people moved.
func rehome_from(settlement_id:String,to_id:String)->int:
	var moved:=0
	for person:Dictionary in people:
		if String(person.get("local_leader_of",""))==settlement_id:person["local_leader_of"]=""
		if String(person.get("home_settlement_id",""))==settlement_id:
			person["home_settlement_id"]=to_id
			moved+=1
	for settlement:Dictionary in WorldSimulation.state.player_settlements:
		if String(settlement.get("id",""))!=settlement_id:continue
		settlement["leader_person_id"]=0
		settlement["leader_title"]=settlement_leader_title()
	# The government screens redraw on this count.
	revision+=1
	return moved


func _ensure_local_leaders(events:Array[Dictionary]=[])->void:
	for settlement_index in WorldSimulation.state.player_settlements.size():
		var settlement:Dictionary=WorldSimulation.state.player_settlements[settlement_index]
		# Nobody lives in a place its people left: nobody leads it.
		if WorldSimulation.settlements.abandoned(settlement): continue
		var settlement_id:=String(settlement.get("id",""))
		var current:=_person_record(int(settlement.get("leader_person_id",0)))
		if not current.is_empty() and String(current.get("status",""))=="active" and String(current.get("local_leader_of",""))==settlement_id:
			settlement["leader_title"]=settlement_leader_title()
			WorldSimulation.state.player_settlements[settlement_index]=settlement
			continue
		# At founding scale the only civic office and the only local office are
		# intentionally the same person. A migrated save could have a Steward but
		# no leader_person_id; choosing the highest-rated generic local candidate
		# here was then rejected by assign_settlement_leader and left the colony
		# permanently vacant.
		if government_stage==0 and WorldSimulation.state.player_settlements.size()==1:
			var steward_id:=int((WorldSimulation.state.leadership_positions.get("Steward",{}) as Dictionary).get("person_id",0))
			if steward_id>0:
				var founding_result:=assign_settlement_leader(settlement_id,steward_id)
				if bool(founding_result.get("ok",false)):
					events.append({"day":int(WorldSimulation.state.elapsed_days),"title":"Founding Leader Recognized","description":"%s now carries both the founding council and the local leadership of %s." % [String((founding_result.get("leader",{}) as Dictionary).get("name","The founding leader")),String(settlement.get("name","the settlement"))],"domain":"institutions","severity":"notice"})
				continue
		var candidates:=candidates_for_office("SettlementLeader",settlement_id,1)
		if candidates.is_empty(): continue
		var result:=assign_settlement_leader(settlement_id,int(candidates[0].person_id))
		if bool(result.get("ok",false)):
			events.append({"day":int(WorldSimulation.state.elapsed_days),"title":"Local Succession","description":"%s now serves as %s of %s." % [String(candidates[0].name),String(result.title),String(settlement.get("name","the settlement"))],"domain":"institutions","severity":"notice"})


## research_600: the life table already expects a named person's death, so it
## is charged against the natural-death accumulator and not counted twice.
## fun-pop: once a settlement exists, daily deaths run on the settlement's own
## accumulator inside SettlementModel.with_local_population; the national
## death_progress is swapped out there and never read. Charging the national
## field left every named death as an extra one (about 6-10 per 1,000 a year
## in a band of a hundred), so the death and its charge go through the local
## scope that the daily mortality reads.
func _register_named_death()->void:
	WorldSimulation.settlements.with_local_population(func()->void:
		WorldSimulation.state.register_population_deaths(1,"Natural causes")
		WorldSimulation.state.death_progress-=1.0
	,true)


func _process_lifespans(day:int,events:Array[Dictionary])->void:
	for index in people.size():
		var person:Dictionary=people[index]
		# Detention removes someone from office and the available candidate pool;
		# it does not suspend their aging or turn them into an immortal record.
		if String(person.get("status","")) not in ["active","detained"]: continue
		if String(person.get("office_key",""))!="" or String(person.get("local_leader_of",""))!="":
			person["experience_months"]=int(person.get("experience_months",0))+1
			# A year in office sharpens what the office asks of them.
			if int(person.experience_months)%12==0: _grow_in_office(person)
		var age:=float(day-int(person.get("born_day",day)))/365.0
		_decline_with_age(person,age)
		if not person.has("adult_life"):
			# Records from before adult life tables: a grown person gets the
			# adult span (never a shorter one than they had).
			person["adult_life"]=1
			var life_rng:=RandomNumberGenerator.new()
			life_rng.seed=hash("%d:adult_life:%d" % [WorldSimulation.state.world_seed,int(person.get("person_id",0))])
			person["death_age_years"]=maxf(float(person.get("death_age_years",60.0)),adult_death_age(life_rng,floori(age),float(WorldSimulation.state.projected_life_expectancy())))
		if age<float(person.get("death_age_years",90.0)):
			people[index]=person
			continue
		person["status"]="deceased"
		person["died_day"]=day
		var held_title:=String(person.get("office_title",person.get("office_key","")))
		var local_id:=String(person.get("local_leader_of",""))
		# What they held when they died, for the court's mourning (court_lives.gd).
		person["died_office_key"]=String(person.get("office_key",""))
		person["died_office_title"]=held_title
		person["died_local_leader_of"]=local_id
		people[index]=person
		# This named person is part of the aggregate population. Register exactly one
		# death through the same conserved demographic entry point.
		_register_named_death()
		var service_note:=" while serving as %s" % held_title if held_title!="" else (" while leading a settlement" if local_id!="" else "")
		var event:Dictionary={"day":day,"title":"Officeholder Died","description":"%s died aged %d%s. The office and local duties now pass through the same succession rules as every other appointment." % [String(person.name),floori(age),service_note],"domain":"institutions","severity":"major"}
		events.append(event)
		WorldSimulation.state.simulation_events.push_front(event)
		if WorldSimulation.state.simulation_events.size()>80: WorldSimulation.state.simulation_events.resize(80)
		revision+=1


## Growth in office: each year served adds GROWTH_PER_YEAR to the two skills
## the office weighs most (a town's leader: its own), up to SKILL_CAP; the
## Ambitious grow half again as fast. Age takes it back: from DECLINE_AGE on,
## every skill loses DECLINE_PER_YEAR a year, to no less than SKILL_FLOOR.
## Losing a seasoned official therefore costs what they had learned.
const GROWTH_PER_YEAR:=1
const SKILL_CAP:=95
const DECLINE_AGE:=60
const DECLINE_PER_YEAR:=1
const SKILL_FLOOR:=10

func _grow_in_office(person:Dictionary)->void:
	var office:=String(person.get("office_key",""))
	if office=="": office="SettlementLeader"
	var weights:Dictionary=OFFICE_SKILL_WEIGHTS.get(office,OFFICE_SKILL_WEIGHTS.SettlementLeader)
	var keys:Array=weights.keys()
	keys.sort_custom(func(a:Variant,b:Variant)->bool: return float(weights[a])>float(weights[b]))
	var years:=int(person.get("experience_months",0))/12
	var amount:=GROWTH_PER_YEAR+(1 if "Ambitious" in (person.get("traits",[]) as Array) and years%2==0 else 0)
	var skills:Dictionary=person.get("skills",{})
	for key in keys.slice(0,2):
		if skills.has(String(key)): skills[String(key)]=mini(SKILL_CAP,maxi(int(skills[String(key)]),int(skills[String(key)])+amount))
	person["skills"]=skills
	person["grown_years"]=int(person.get("grown_years",0))+1

func _decline_with_age(person:Dictionary,age:float)->void:
	var past:=floori(age)-DECLINE_AGE
	if past<=0: return
	# Records from before this rule start counting from today, never all at once.
	if not person.has("aged_years"):
		person["aged_years"]=past
		return
	var done:=int(person.get("aged_years",0))
	if past<=done: return
	var skills:Dictionary=person.get("skills",{})
	for key in skills: skills[key]=maxi(SKILL_FLOOR,int(skills[key])-DECLINE_PER_YEAR*(past-done))
	person["skills"]=skills
	person["aged_years"]=past

func _focus_decision_for_settlement(settlement:Dictionary)->Dictionary:
	var age_days:=maxi(0,int(WorldSimulation.state.elapsed_days)-int(settlement.get("founded_day",0)))
	var territory:Dictionary=settlement.get("territory_context",{})
	var is_primary:=bool(settlement.get("primary",false))
	var water:Dictionary=WorldSimulation.state.water_metrics
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
	var food_days:=float(WorldSimulation.state.simulation_metrics.get("food_days",30.0))
	var food_net:=float(WorldSimulation.state.simulation_metrics.get("food_net",0.0))
	var food_intake:=clampf(float(WorldSimulation.state.simulation_metrics.get("food_intake_ratio",1.0)),0.0,1.0)
	var food_projected_days:=float(WorldSimulation.state.simulation_metrics.get("food_projected_days",9999.0))
	var food_forecast:Dictionary=WorldSimulation.state.simulation_metrics.get("food_forecast_90",{})
	var forecast_shortage_day:=int(food_forecast.get("first_shortage_day",-1))
	if food_intake<0.995:
		return {"id":"provisions","label":"RESTORE FOOD SUPPLY","reason":"Only %d%% of today's food requirement was met." % roundi(food_intake*100.0)}
	if forecast_shortage_day>0 and forecast_shortage_day<=60:
		return {"id":"provisions","label":FOCUS_LABELS.provisions,"reason":"The seasonal and weather outlook projects a shortage in about %d days." % forecast_shortage_day}
	if food_net<0.0 and food_projected_days<45.0:
		return {"id":"provisions","label":FOCUS_LABELS.provisions,"reason":"Food stores are shrinking and are projected to last %.1f days without a correction." % food_projected_days}
	var housing_ratio:=float(WorldSimulation.state.simulation_metrics.get("housing_ratio",1.0))
	if housing_ratio<0.96:
		return {"id":"shelter","label":FOCUS_LABELS.shelter,"reason":"Shelter currently covers only %d%% of the population." % roundi(housing_ratio*100.0)}
	var security:=float(WorldSimulation.state.society_capacities.get("security",0.4))
	if security<0.30 and WorldSimulation.state.player_settlements.size()>1:
		return {"id":"defense","label":FOCUS_LABELS.defense,"reason":"Several settlements must be protected while security capacity remains weak."}
	# Founding work must yield to measured survival needs at every settlement age.
	if age_days<365:
		return {"id":"establishment","label":FOCUS_LABELS.establishment,"reason":"This place is less than a year old and still needs its first dependable works and routines."}
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
	var water:Dictionary=WorldSimulation.state.water_metrics
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
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	var food_intake:=clampf(float(metrics.get("food_intake_ratio",1.0)),0.0,1.0)
	var food_net:=float(metrics.get("food_net",0.0))
	var projected:=float(metrics.get("food_projected_days",9999.0))
	var forecast:Dictionary=metrics.get("food_forecast_90",{})
	var shortage_day:=int(forecast.get("first_shortage_day",-1))
	var food_risk:=food_intake<0.995 or (food_net<0.0 and projected<45.0) or (shortage_day>0 and shortage_day<=60)
	if food_risk:
		reasons.append("food stores are already short or the weather outlook projects a near-term drawdown")
	return {"active":water_risk or food_risk,"water":water_risk,"food":food_risk,"reasons":reasons}


## reserve_lean: how far the people's own ambitions ask for deeper stores
## (0 none, 1 a people wholly set on lasting abundance: reserve_lean_of).
func _apply_survival_guard(weights:Dictionary,reserve_lean:float=0.0)->Dictionary:
	var guard:=_survival_guard()
	if bool(guard.food):
		weights.Food=float(weights.get("Food",0.0))+18.0
		weights.Logistics=float(weights.get("Logistics",0.0))+5.0
	if bool(guard.water):
		weights.Food=float(weights.get("Food",0.0))+5.0
		weights.Survey=float(weights.get("Survey",0.0))+7.0
		weights.Logistics=float(weights.get("Logistics",0.0))+10.0
		weights.Construction=float(weights.get("Construction",0.0))+4.0
	# Use the city's measured output per share of labor. Fixed extra weights can
	# leave a poor site permanently short even while its leader says "provisions".
	# Keep the subsistence floor after stores recover, avoiding daily oscillation
	# back to the allocation that caused the deficit. More productive methods
	# naturally release labor for the ruler's other priorities.
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	var demand:=maxf(0.0,float(metrics.get("food_consumption",0)))
	var produced:=maxf(0.0,float(metrics.get("food_production",0)))
	var previous_share:=clampf(float(metrics.get("food_labor_share",0)),0.0,1.0)
	if demand>0.0 and previous_share>0.0:
		# Planners keep a reserve against the lean season and bad years: while
		# the stores hold less than RESERVE_TARGET_DAYS they plan for more than
		# today's need, in proportion to how far short the stores are.
		# Never more than the stores can hold: before storage pits a camp keeps
		# only what its baskets and bundles carry.
		# A people set on lasting abundance keeps up to twice the store, with
		# up to twice the margin (reserve_lean).
		var lean:=clampf(reserve_lean,0.0,1.0)
		var target:=RESERVE_TARGET_DAYS*(1.0+lean)
		if WorldSimulation.food!=null and WorldSimulation.food.has_method("_food_storage_capacity"):target=minf(target,float(WorldSimulation.food._food_storage_capacity())/demand*0.8)
		var reserve_gap:=clampf((target-float(metrics.get("food_days",target)))/maxf(1.0,target),0.0,1.0)
		var buffer:=(1.08 if bool(guard.food) else 1.02)+RESERVE_MARGIN*(1.0+lean)*reserve_gap
		var ceiling:=.72 if bool(guard.water) else .85
		var needed:=clampf(previous_share*demand*buffer/maxf(.01,produced),0.0,ceiling)
		var other:=0.0
		for role:String in weights:
			if role!="Food":other+=maxf(0.0,float(weights[role]))
		weights.Food=maxf(float(weights.get("Food",0)),other*needed/maxf(.01,1.0-needed))
		# research_3000: once food workers comfortably out-produce the need and
		# the stores hold, the planned food labor comes down to what is needed
		# (with a margin); _apply_food_labor_floor still holds the era's floor.
		if not bool(guard.food) and float(metrics.get("food_projected_days",0.0))>=SURPLUS_RELEASE_DAYS:
			var released:=clampf(needed*SURPLUS_RELEASE_MARGIN,0.0,ceiling)
			weights.Food=minf(float(weights.get("Food",0)),other*released/maxf(.01,1.0-released))
	return guard

## research_3000: stores (days) and margin over the needed share at which
## planners move surplus food workers to other work.
const SURPLUS_RELEASE_DAYS:=45.0
const SURPLUS_RELEASE_MARGIN:=1.15
## The reserve planners aim to hold (days of food), and how much more than
## today's need they plan for when the stores are empty.
const RESERVE_TARGET_DAYS:=60.0
const RESERVE_MARGIN:=0.15
## The food work a people wholly set on lasting abundance asks for
## (cultural_inheritance.gd WORK sustenance "Food"): that wish doubles the
## reserve and its margin; wellbeing's half as much adds half.
const RESERVE_FOOD_WISH:=12.0

## How far a people's wish for food work (labor_bias "Food") deepens the
## reserve its planners keep, 0..1.
static func reserve_lean_of(food_wish:float)->float:
	return clampf(food_wish/RESERVE_FOOD_WISH,0.0,1.0)


## research_600 balance: getting, grinding, cooking and storing food took most
## of a pre-modern household's working time (docs/research/BENCHMARKS_600.md,
## typical: 62% at year 0, 52% by year 600). Planned labor keeps at least that
## share on food; the surplus fills the stores. A society focused on food and
## labor research needs less (up to a quarter), and decrees that claim labor
## (care rotas, watches, levies) leave less time for everything, so food takes more.
## research_3000: the floor follows the benchmark's typical share of labor on
## food through 3000 (docs/research/benchmarks_*.json food_labor_share).
## The planned floor is this share of the era's typical food labour: a safety
## net under the planners' own reckoning of need, low enough that a people
## ahead in farming frees hands for other work and one behind must find more.
const FOOD_FLOOR_OF_TYPICAL:=0.9
const FOOD_LABOR_FLOOR:Array=[[0.0,0.62],[100.0,0.60],[300.0,0.56],[600.0,0.52],[1200.0,0.47],[1800.0,0.45],[2400.0,0.38],[2500.0,0.36],[2600.0,0.33],[2700.0,0.28],[2800.0,0.22],[2900.0,0.13],[3000.0,0.08]]

func _apply_food_labor_floor(weights:Dictionary)->void:
	var floor_share:=food_floor_share()
	var other:=0.0
	for role:String in weights:
		if role!="Food":other+=maxf(0.0,float(weights[role]))
	weights.Food=maxf(float(weights.get("Food",0)),other*floor_share/maxf(.01,1.0-floor_share))

## The share of those who can work that this people's planners keep on food at
## the least: the age's typical share (FOOD_LABOR_FLOOR) times
## FOOD_FLOOR_OF_TYPICAL, less for food and labour research, more for care and
## for orders that claim labour.
func food_floor_share()->float:
	var year:=float(WorldSimulation.state.elapsed_days)/365.0
	var floor_share:=float(FOOD_LABOR_FLOOR[FOOD_LABOR_FLOOR.size()-1][1])
	for index in range(1,FOOD_LABOR_FLOOR.size()):
		if year<=float(FOOD_LABOR_FLOOR[index][0]):
			var low:Array=FOOD_LABOR_FLOOR[index-1]
			var high:Array=FOOD_LABOR_FLOOR[index]
			floor_share=lerpf(float(low[1]),float(high[1]),(year-float(low[0]))/(float(high[0])-float(low[0])))
			break
	var focus:Dictionary=WorldSimulation.discovery.society_model.line_focus if WorldSimulation.discovery!=null else {}
	floor_share*=FOOD_FLOOR_OF_TYPICAL
	floor_share*=1.0-0.25*clampf(float(focus.get("nutrition",0.0))+0.5*float(focus.get("labor",0.0)),0.0,1.0)
	# Care-focused societies keep more of their sick, old and young alive to feed.
	floor_share*=1.0+0.12*float(focus.get("health",0.0))+0.08*float(focus.get("demography",0.0))
	if WorldSimulation.consequences!=null:floor_share*=1.0+maxf(0.0,-float(WorldSimulation.consequences.policy_effect("labor_multiplier")))
	return clampf(floor_share,0.0,0.85)

## The reserve this people's planners aim for, as _apply_survival_guard reckons
## it: {target_days, food_days, gap (0..1 short), margin (planned above need)}.
func reserve_plan()->Dictionary:
	var lean:=0.0
	if WorldSimulation.direction!=null:
		WorldSimulation.direction._ensure_cultural_memory()
		var bias:=preload("res://scripts/cultural_inheritance.gd").labor_bias(WorldSimulation.direction.cultural_memory,int(WorldSimulation.state.elapsed_days))
		lean=reserve_lean_of(float(bias.get("Food",0.0)))
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	var demand:=maxf(0.01,float(metrics.get("food_consumption",0)))
	var target:=RESERVE_TARGET_DAYS*(1.0+lean)
	if WorldSimulation.food!=null and WorldSimulation.food.has_method("_food_storage_capacity"):target=minf(target,float(WorldSimulation.food._food_storage_capacity())/demand*0.8)
	var days:=float(metrics.get("food_days",target))
	var gap:=clampf((target-days)/maxf(1.0,target),0.0,1.0)
	return {"target_days":target,"food_days":days,"gap":gap,"margin":RESERVE_MARGIN*(1.0+lean)*gap}

## Why this many hands are on food, in plain words with the planners' own
## numbers (the Food page reads it).
func food_plan_words()->String:
	var state=WorldSimulation.state
	var metrics:Dictionary=state.simulation_metrics
	var able:=maxf(1.0,float(state.able_population()))
	var on_food:=float(state.population_allocations.get("Food",0))
	var eaten:=float(metrics.get("food_consumption",0.0))
	if eaten<=0.0: return ""
	var ratio:=float(metrics.get("food_production",0.0))/eaten
	var line:="%d of the %d who can work are on food (%d%%), bringing in %s what is eaten." % [roundi(on_food),roundi(able),roundi(on_food/able*100.0),("%.2f times" % ratio) if absf(ratio-1.0)>=0.005 else "just"]
	if WorldSimulation.direction!=null and not bool(WorldSimulation.direction.automatic_work):
		return line+" You set the daily work, so no floor or reserve plan changes it."
	line+=" The planners keep at least %d%% on food" % roundi(food_floor_share()*100.0)
	var plan:=reserve_plan()
	if float(plan.gap)>0.01:
		line+="; while the stores hold %d of the %d days they aim for, they plan %d%% more than is eaten." % [roundi(float(plan.food_days)),roundi(float(plan.target_days)),maxi(1,roundi(float(plan.margin)*100.0))]
	else:
		line+="; the stores hold what they aim for, so no one works food beyond the need."
	return line


## Planning weight added to guards at full threat (the base plan gives guards 4).
const THREAT_GUARD_WEIGHT:=10.0

## How hard the neighbours press on this people, 0..1, read the same way for
## every people from its own view of them: border tension, ill will, open war.
func neighbour_threat()->float:
	var worst:=0.0
	if WorldSimulation.world==null: return 0.0
	for civ in WorldSimulation.world.civilizations:
		if not civ is Dictionary or not bool((civ as Dictionary).get("alive",true)): continue
		var relation:Dictionary=(civ as Dictionary).get("player_relation",{}) if (civ as Dictionary).get("player_relation") is Dictionary else {}
		var at_war:=bool(relation.get("at_war",false))
		if int(relation.get("contact_level",0))<1 and not at_war: continue
		worst=maxf(worst,float(relation.get("border_tension",0.0))*0.5+maxf(0.0,-float(relation.get("opinion",0.0)))*0.4+(0.5 if at_war else 0.0))
	return clampf(worst,0.0,1.0)

func _allocations_for_focus(focus:String,leader:Dictionary,cultural:bool=false)->Dictionary:
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
	var reserve_lean:=0.0
	if cultural:
		WorldSimulation.direction._ensure_cultural_memory()
		var bias:=preload("res://scripts/cultural_inheritance.gd").labor_bias(WorldSimulation.direction.cultural_memory,int(WorldSimulation.state.elapsed_days))
		for role in bias:
			if role!="Food":weights[role]=float(weights.get(role,0))+float(bias[role])
		# The people's wish for food work (sustenance, wellbeing) is planned as
		# deeper stores: extra hands on food until the larger reserve is full,
		# not a share the planners' own floor already covers.
		reserve_lean=reserve_lean_of(float(bias.get("Food",0.0)))
	# The workshop officer asks for gatherers while soldiers' gear lacks materials.
	if WorldSimulation.military!=null:weights.Extraction=float(weights.get("Extraction",0))+float(WorldSimulation.military.workshop.extraction_request().get("weight",0.0))
	# Guards in proportion to how hard the neighbours press (docs/STANDING_DESIGN.md
	# section 7); food still comes first (the guard and the floor below).
	weights.Defense=float(weights.get("Defense",0))+THREAT_GUARD_WEIGHT*neighbour_threat()
	_apply_survival_guard(weights,reserve_lean)
	_apply_food_labor_floor(weights) # research_600 balance
	if not leader.is_empty():
		var skills:Dictionary=leader.get("skills",{})
		weights.Administration=float(weights.Administration)+float(skills.get("Administration",50))*0.025
		weights.Logistics=float(weights.Logistics)+float(skills.get("Logistics",50))*0.018
		weights.Knowledge=float(weights.Knowledge)+float(skills.get("Knowledge",50))*0.012
	var total:=0.0
	for role in GameState.POPULATION_ROLES: total+=maxf(0.0,float(weights.get(role,0.0)))
	for role in GameState.POPULATION_ROLES: weights[role]=maxf(0.0,float(weights.get(role,0.0)))/maxf(0.001,total)*100.0
	return weights


## Lays today's daily work on our towns now (the ruler's split, or the
## leaders' own): the one entry point the People view and the court use
## (manual_work.gd), so the split applies at once, not at the next dawn.
func delegate_now()->void:
	var was:=initializing
	initializing=true
	_delegate_settlements(int(WorldSimulation.state.elapsed_days))
	initializing=was
	revision+=1


func _delegate_settlements(_day:int)->void:
	# The ruler sets the daily work (manual_work.gd): the same split for every
	# town, as the ruler left it, except that a town's leader puts more on food
	# when its food is running out (_ruler_split_fed). The People view and the
	# court say what it will do; the chronicle tells when a leader steps in,
	# and warns of a town no leader is feeding (manual_work.warn_towns).
	if not bool(WorldSimulation.direction.automatic_work):
		_lay_ruler_split()
		var manual:=preload("res://scripts/manual_work.gd")
		if _day%manual.WARN_EVERY==0:manual.warn_towns(_day)
		return
	var aggregate:Dictionary={}
	for role in GameState.POPULATION_ROLES: aggregate[role]=0.0
	var total_weight:=0.0
	var satellite_share:=0.0
	var management_changed:=false
	for settlement in WorldSimulation.state.player_settlements:
		if not bool(settlement.get("primary",false)): satellite_share+=maxf(0.0,float(settlement.get("population_share",0.0)))
	for index in WorldSimulation.state.player_settlements.size():
		var settlement:Dictionary=WorldSimulation.state.player_settlements[index]
		if WorldSimulation.settlements.abandoned(settlement): continue
		var share:=maxf(0.01,1.0-satellite_share) if bool(settlement.get("primary",false)) else maxf(0.001,float(settlement.get("population_share",0.0)))
		var auto_manage:=bool(settlement.get("auto_manage",true))
		var leader:=_person_record(int(settlement.get("leader_person_id",0)))
		# Evaluate the city's needs and discretionary allocation inside one
		# resource scope, without swapping all its ledgers three times.
		var local:Dictionary=WorldSimulation.settlements.with_city_resources(String(settlement.id),func()->Dictionary:
			var guard:=_survival_guard()
			var decision:=_focus_decision_for_settlement(settlement) if auto_manage else {
				"id":String(settlement.get("management_focus","balanced")),
				"label":String(FOCUS_LABELS.get(String(settlement.get("management_focus","balanced")),"BALANCED STEWARDSHIP")),
				"reason":String(settlement.get("management_focus_reason",_manual_focus_reason(String(settlement.get("management_focus","balanced"))))),
			}
			return {"guard":guard,"decision":decision,"allocations":_allocations_for_focus(String(decision.id),leader,auto_manage)}
		)
		var guard:Dictionary=local.guard
		var decision:Dictionary=local.decision
		var focus:=String(decision.id)
		var allocations:Dictionary=local.allocations
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
		settlement.erase("fed_by_leader")
		settlement["auto_manage"]=auto_manage
		settlement["local_allocations"]=allocations
		settlement["delegated_effects"]={"competence":competence,"work":competence*0.12,"travel":float(skills.get("Logistics",35))/100.0*0.10,"water":float(skills.get("Provisioning",35))/100.0*0.08,"support":competence*0.14}
		var new_signature:="%s|%s|%s" % [focus,bool(guard.active),JSON.stringify(allocations)]
		management_changed=management_changed or old_signature!=new_signature
		WorldSimulation.state.player_settlements[index]=settlement
		for role in GameState.POPULATION_ROLES: aggregate[role]=float(aggregate[role])+float(allocations.get(role,0.0))*share
		total_weight+=share
	if total_weight>0.0:
		for role in GameState.POPULATION_ROLES: WorldSimulation.state.population_allocation_percentages[role]=float(aggregate[role])/total_weight
		WorldSimulation.state.synchronize_population_allocations()
	if management_changed: WorldSimulation.state.settlement_network_revision+=1


## The ruler's split on every town (manual_work.gd applied_percentages), as
## each town's leader lays it. The realm's ledger and each town's share of
## work read the same shares, except that no leader lets a town starve
## (_ruler_split_fed): a town whose food is running out gets just enough more
## on food from its own leader, and the rest of the split keeps the ruler's
## proportions. Each town keeps its leader, the leader's standing and the
## ruler's last ask of them (auto_manage, the focus), so handing the work back
## to the leaders returns every town to what it had.
func _lay_ruler_split()->void:
	var shares:Dictionary=preload("res://scripts/manual_work.gd").applied_percentages()
	var management_changed:=false
	var aggregate:Dictionary={}
	for role in GameState.POPULATION_ROLES: aggregate[role]=0.0
	var total_weight:=0.0
	var satellite_share:=0.0
	for settlement in WorldSimulation.state.player_settlements:
		if not bool(settlement.get("primary",false)): satellite_share+=maxf(0.0,float(settlement.get("population_share",0.0)))
	for index in WorldSimulation.state.player_settlements.size():
		var settlement:Dictionary=WorldSimulation.state.player_settlements[index]
		if WorldSimulation.settlements.abandoned(settlement): continue
		var share:=maxf(0.01,1.0-satellite_share) if bool(settlement.get("primary",false)) else maxf(0.001,float(settlement.get("population_share",0.0)))
		var leader:=_person_record(int(settlement.get("leader_person_id",0)))
		var skills:Dictionary=leader.get("skills",{})
		var competence:=clampf(office_competency(leader,"SettlementLeader"),0.18,0.94) if not leader.is_empty() else 0.18
		var old_signature:="%s|%s|%s" % [String(settlement.get("management_focus","")),bool(settlement.get("survival_guard_active",false)),JSON.stringify(settlement.get("local_allocations",{}))]
		# The leader's own feeding under the ruler's split (fed_by_leader),
		# apart from the leaders' food-and-water guard of their own work.
		var guarded:=bool(settlement.get("fed_by_leader",false))
		var yesterday:=float((settlement.get("local_allocations",{}) as Dictionary).get("Food",float(shares.get("Food",0.0))))
		var laid:Dictionary=WorldSimulation.settlements.with_city_resources(String(settlement.get("id","")),func()->Dictionary:return _ruler_split_fed(shares,yesterday,guarded))
		var allocations:Dictionary=laid.allocations
		settlement["fed_by_leader"]=bool(laid.active)
		settlement["survival_guard_active"]=bool(laid.active)
		settlement["local_allocations"]=allocations.duplicate(true)
		settlement["delegated_effects"]={"competence":competence,"work":competence*0.12,"travel":float(skills.get("Logistics",35))/100.0*0.10,"water":float(skills.get("Provisioning",35))/100.0*0.08,"support":competence*0.14}
		if bool(laid.active) and not guarded and float(laid.food)>float(shares.get("Food",0.0))+0.01: _tell_fed(settlement,leader,laid,float(shares.get("Food",0.0)))
		var new_signature:="%s|%s|%s" % [String(settlement.get("management_focus","")),bool(laid.active),JSON.stringify(settlement.local_allocations)]
		management_changed=management_changed or old_signature!=new_signature
		WorldSimulation.state.player_settlements[index]=settlement
		for role in GameState.POPULATION_ROLES: aggregate[role]=float(aggregate[role])+float(allocations.get(role,0.0))*share
		total_weight+=share
	for role in GameState.POPULATION_ROLES: WorldSimulation.state.population_allocation_percentages[role]=float(aggregate[role])/total_weight if total_weight>0.0 else float(shares.get(role,0.0))
	WorldSimulation.state.synchronize_population_allocations()
	if management_changed: WorldSimulation.state.settlement_network_revision+=1


## A leader keeps feeding a town past the ruler's split until its stores hold
## this many days of eating again, once the food alarm made them step in.
const RULER_RELEASE_DAYS:=120.0
## No leader puts more than this share of a town's hands on food.
const FOOD_CEILING_SHARE:=85.0

## The ruler's split for one town, read in the town's own scope: the ruler's
## shares (`shares`, percent), unless the leaders' own food alarm
## (_survival_guard: short now, losing food with under 45 days left, or a lean
## season forecast within 60) is up, or the town's leader is already feeding
## it (`guarded`) and its stores hold less than RULER_RELEASE_DAYS. Then the
## leader puts enough on food to cover what the town eats and spoils, with
## more while the stores are under RESERVE_TARGET_DAYS, from the town's own
## food per hand (the count's food_labor_share, else yesterday's share), and
## takes those hands from the ruler's other tasks in proportion.
## {active, allocations, food (share %), days (of eating in store)}.
func _ruler_split_fed(shares:Dictionary,yesterday_food:float,guarded:bool)->Dictionary:
	var ruler_food:=float(shares.get("Food",0.0))
	var out:={"active":false,"allocations":shares.duplicate(true),"food":ruler_food,"days":-1.0}
	var m:Dictionary=WorldSimulation.state.simulation_metrics
	if not m.has("food_production"):return out
	var need:=maxf(0.0,float(m.get("food_consumption",0.0)))
	if need<=0.0:return out
	var eats:=need+maxf(0.0,float(m.get("food_spoilage",0.0)))
	var produced:=maxf(0.0,float(m.get("food_production",0.0)))
	var stock:=maxf(0.0,float(m.get("food_total_stock",WorldSimulation.state.resource_stockpiles.get("Food",0.0))))
	var days:=stock/need
	out.days=days
	var alarm:=bool(_survival_guard().food)
	if not alarm and not (guarded and days<RULER_RELEASE_DAYS):return out
	out.active=true
	var working:=clampf(float(m.get("food_labor_share",0.0)),0.0,1.0)*100.0
	if working<=0.01:working=maxf(yesterday_food,ruler_food)
	var gap:=clampf((RESERVE_TARGET_DAYS-days)/RESERVE_TARGET_DAYS,0.0,1.0)
	var wanted:=eats*(1.05+RESERVE_MARGIN*gap)
	var food:=working*wanted/produced if produced>0.01 else FOOD_CEILING_SHARE
	food=clampf(food,ruler_food,maxf(ruler_food,FOOD_CEILING_SHARE))
	if food<=ruler_food+0.01:return out
	var others:=100.0-ruler_food
	var scale:=(100.0-food)/others if others>0.01 else 0.0
	var allocations:={}
	for role in GameState.POPULATION_ROLES:allocations[role]=food if role=="Food" else float(shares.get(role,0.0))*scale
	out.allocations=allocations
	out.food=food
	return out

## The chronicle's word when a town's leader first puts more on food than the
## ruler's split: the town, its stores, the leader and the shares.
func _tell_fed(settlement:Dictionary,leader:Dictionary,laid:Dictionary,ruler_food:float)->void:
	var chronicle:=preload("res://scripts/chronicle.gd")
	if not chronicle.active():return
	var town:=String(settlement.get("name","The town"))
	var who:=("%s, its %s," % [String(leader.get("name","")),settlement_leader_title().to_lower()]) if not leader.is_empty() else "Its leader"
	var days:=float(laid.get("days",-1.0))
	var stores:=("its stores held %d days of eating" % roundi(days)) if days>=1.0 else "its stores were empty"
	var day:=int(WorldSimulation.state.elapsed_days)
	chronicle.record({"key":"split_fed:%s:%d" % [String(settlement.get("id","")),day],"day":day,"title":"%s's Leader Puts More on Food" % town,
		"text":"At your split %s was eating more than it gathered, and %s. %s has put %d in 100 of its hands on getting food, against your %d, until the stores hold %d days again. The rest of your split stands." % [town,stores,who,roundi(float(laid.food)),roundi(ruler_food),roundi(RULER_RELEASE_DAYS)],
		"tier":"notice","kind":"warning","domain":"food"})


func settlement_management(settlement_id:String)->Dictionary:
	initialize()
	for settlement in WorldSimulation.state.player_settlements:
		if String(settlement.get("id",""))!=settlement_id: continue
		return {"leader":settlement_leader(settlement_id),"leader_title":settlement_leader_title(),"focus":String(settlement.get("management_focus","balanced")),"focus_label":String(settlement.get("management_focus_label",FOCUS_LABELS.balanced)),"focus_reason":String(settlement.get("management_focus_reason","Local priorities have not yet been reassessed.")),"focus_effect":String(settlement.get("management_focus_effect",FOCUS_EFFECTS.balanced)),"survival_guard_active":bool(settlement.get("survival_guard_active",false)),"auto_manage":bool(settlement.get("auto_manage",true)),"allocations":(settlement.get("local_allocations",BASE_ALLOCATIONS) as Dictionary).duplicate(true),"effects":(settlement.get("delegated_effects",{}) as Dictionary).duplicate(true),
			# The ruler sets the daily work for every town (manual_work.gd).
			"ruler_sets_work":not bool(WorldSimulation.direction.automatic_work)}
	return {}


func set_settlement_focus(settlement_id:String,focus:String)->Dictionary:
	if not String(WorldSimulation.settlements.settlement_record(settlement_id).get("occupied_by","")).is_empty():return {"ok":false,"reason":"Use local recovery decisions while this city is occupied."}
	var record:Dictionary=WorldSimulation.settlements.settlement_record(settlement_id)
	if WorldSimulation.settlements.abandoned(record):return {"ok":false,"reason":WorldSimulation.settlements.left_reason(record)}
	if focus not in FOCUS_LABELS: return {"ok":false,"reason":"Unknown settlement focus."}
	# While the ruler sets the daily work, no leader can shift hands.
	if not bool(WorldSimulation.direction.automatic_work): return {"ok":false,"reason":"You set the daily work yourself. Move people in The People, or hand the work back to our leaders."}
	for index in WorldSimulation.state.player_settlements.size():
		if String(WorldSimulation.state.player_settlements[index].get("id",""))!=settlement_id: continue
		WorldSimulation.state.player_settlements[index]["management_focus"]=focus
		WorldSimulation.state.player_settlements[index]["management_focus_label"]=String(FOCUS_LABELS[focus])
		WorldSimulation.state.player_settlements[index]["management_focus_reason"]=_manual_focus_reason(focus)
		WorldSimulation.state.player_settlements[index]["management_focus_effect"]=String(FOCUS_EFFECTS.get(focus,FOCUS_EFFECTS.balanced))
		WorldSimulation.state.player_settlements[index]["auto_manage"]=false
		WorldSimulation.state.player_settlements[index]["local_allocations"]=_allocations_for_focus(focus,settlement_leader(settlement_id))
		WorldSimulation.state.settlement_network_revision+=1
		revision+=1
		return {"ok":true,"focus":focus,"label":String(FOCUS_LABELS[focus])}
	return {"ok":false,"reason":"That settlement is not owned."}


func restore_delegation(settlement_id:String)->Dictionary:
	if not String(WorldSimulation.settlements.settlement_record(settlement_id).get("occupied_by","")).is_empty():return {"ok":false,"reason":"Use local recovery decisions while this city is occupied."}
	for index in WorldSimulation.state.player_settlements.size():
		if String(WorldSimulation.state.player_settlements[index].get("id",""))!=settlement_id: continue
		WorldSimulation.state.player_settlements[index]["auto_manage"]=true
		_delegate_settlements(int(WorldSimulation.state.elapsed_days))
		revision+=1
		return {"ok":true}
	return {"ok":false,"reason":"That settlement is not owned."}


func _sync_advisor_roster()->void:
	var prior_by_id:Dictionary={}
	for prior in WorldSimulation.state.advisor_roster:
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
	WorldSimulation.state.advisor_roster=roster
