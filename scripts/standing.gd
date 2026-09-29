extends RefCounted
## STANDING: what we are (strengths), how each other people sees us (views)
## and how our own feel about it (pride). docs/STANDING_DESIGN.md.
##
## Every people runs the same code in its own WorldSimulation scope (its own
## state, army, offices and works); only the views OF US held by others are the
## human player's. Everything here is READ from state that already exists: soldiers and their
## readiness, stores, works and treasures, scholars and discoveries, offices,
## roads, and the memories other systems already keep of our deeds (foreign
## dread in divine_regard.gd, respect and resentment in society_exchange.gd,
## grudges in rival_rulers.gd, their rulers' trust in ForeignDiplomacy).
## Nothing is stored, so nothing can drift from the ledger. Every value comes
## with its reasons in plain words, for the court and the Standing page.
##
## Strengths are 0..1 against what the age expects (a village is not weak for
## lacking an empire's army). Views are what one other people feels: 0..1.
## Envy and Contempt are the two dangers read from the views.

const Hall:=preload("res://scripts/audience_hall.gd")
const Rewards:=preload("res://scripts/undertaking_rewards.gd")
const Exchange:=preload("res://scripts/society_exchange.gd")
const Culture:=preload("res://scripts/artifact_culture.gd")
const LIVES_PATH:="res://scripts/court_lives.gd"
const RIVALS_PATH:="res://scripts/rival_rulers.gd"

## Share of the people under arms, trained and ready, that is full Might for
## any age (pre-modern mobilisation tops out near 7%: war_loop MOBILIZE_MAX).
const MIGHT_FULL_SHARE:=0.07
## A trained, ready warrior counts as this many untrained defenders.
const WARRIOR_WEIGHT:=3.0
## Days of food in store that is full Wealth and full Endurance.
const WEALTH_FOOD_DAYS:=90.0
const ENDURANCE_FOOD_DAYS:=120.0
## Envy and Contempt start to move peoples above these.
const ENVY_RAID_FLOOR:=0.35
const CONTEMPT_FLOOR:=0.3

## The nine strengths in the order the Standing page's rose draws them,
## clockwise from the top: hard power, plenty, soft power, learning, order.
## [id, name, what it is, the rail section that raises it (and its tab),
## that section's name, what raising it costs the people]
const STRENGTHS:=[
	["might","Might","warriors trained and ready to fight","military",0,"Warriors","people out of the fields, and food and arms for them"],
	["endurance","Endurance","how long we could hold out, starved or besieged","economy",0,"Food","stores put by, and the hands to fill them"],
	["wealth","Wealth","food and materials put by","economy",0,"Food","nothing by itself, but plenty draws envy"],
	["reach","Reach","how far our carriers go and how many peoples know us","world",0,"Known World","carriers and scouts away from home"],
	["persuasion","Persuasion","our envoy's skill and how open our ways are","government",0,"Government","a skilled envoy, gifts, and time spent abroad"],
	["splendor","Splendor","great works and treasures others hear of","construction",3,"Landmarks","builders, materials and years"],
	["genius","Genius","what we know against the peoples we know","inquiry",0,"Research","people at research, and food for them"],
	["cunning","Cunning","scouts and watchers: what we find out and keep hidden","world",0,"Known World","scouts' days and sometimes their lives"],
	["order","Order","trust in the chiefs, holding together, a steward's hand","government",0,"Government","able officials, and restraint"],
]
## The six views another people holds of us: [id, name, what it makes them do].
const VIEWS:=[
	["allure","Allure","they want to come to us, trade with us and learn from us"],
	["awe","Awe","they defer to us and bring gifts"],
	["fear","Fear","they remember our wrath and give way"],
	["respect","Respect","they treat us as equals and weigh our word"],
	["trust","Trust","they believe our promises: pacts, trade, marriages"],
	["resentment","Resentment","they want redress, and grudges bring raiders"],
]
## What each strength makes of us when it leads, when it is second, and when
## it is neglected: the words of the Standing page's "what we are".
const LEANING:={"might":"A people of spears","endurance":"A hardy people","wealth":"A people of full stores","reach":"A far-travelling people","persuasion":"A people of good words","splendor":"A people of great works","genius":"A learned people","cunning":"A watchful people","order":"A well-ordered people"}
const ALSO:={"might":"strong in spears","endurance":"hard to starve out","wealth":"rich in stores","reach":"known far and wide","persuasion":"well spoken","splendor":"rich in works","genius":"learned","cunning":"watchful","order":"orderly"}
const NEGLECT:={"might":"with few spears","endurance":"who could not hold out long","wealth":"with thin stores","reach":"known to few","persuasion":"whose words carry little weight","splendor":"with nothing to show","genius":"slow to learn","cunning":"blind to what others plan","order":"quarrelsome"}

## How long a people remembers what was done to it, against oral memory: a
## people that writes keeps its dread and its grudges twice as long, one that
## prints three times (docs/STANDING_DESIGN.md section 6). Read from what that
## people itself knows.
static func memory_span(civ_id:String)->float:
	var voice:=load("res://scripts/character_voice.gd") as GDScript
	if voice==null or civ_id=="": return 1.0
	var known:Array=voice.call("known_ids",civ_id)
	for id in preload("res://scripts/hud/era_words.gd").STATISTICS:
		if known.has(id): return 3.0
	return 2.0 if (voice.call("era_tags",civ_id) as Array).has("writing") else 1.0

static func _lives()->GDScript:
	return load(LIVES_PATH) as GDScript if ResourceLoader.exists(LIVES_PATH) else null

static func _rivals()->GDScript:
	return load(RIVALS_PATH) as GDScript if ResourceLoader.exists(RIVALS_PATH) else null

static func _day()->int:
	return int(floor(WorldSimulation.state.elapsed_days))

# ------------------------------------------------------------------ strengths

## Our fighting strength in "people who can fight": every grown person defends
## the homes a little, a trained and ready warrior counts WARRIOR_WEIGHT times.
## The same scale war_loop.ratio gives other peoples (their people x readiness).
static func _population()->float:
	return maxf(1.0,float(WorldSimulation.state.population_exact))

static func our_fighting_strength()->float:
	var pop:=_population()
	var warriors:=clampf(_warriors(),0.0,pop)
	var readiness:=_readiness()
	return maxf(1.0,(pop-warriors)*0.8+warriors*(1.0+WARRIOR_WEIGHT*readiness))

static func _warriors()->float:
	if WorldSimulation.military==null: return 0.0
	var fielded:=float(WorldSimulation.military.home_army.get("troops",0))
	var trainees:=float(WorldSimulation.military._queued_trainees()) if WorldSimulation.military.has_method("_queued_trainees") else 0.0
	var recruits:=float(WorldSimulation.military.aggregate_recruits)
	return fielded+trainees*0.65+recruits*0.35

static func _readiness()->float:
	if WorldSimulation.military==null: return clampf(float(WorldSimulation.state.simulation_metrics.get("security",0.38)),0.0,1.0)
	return clampf(float(WorldSimulation.military.home_army.get("readiness",WorldSimulation.state.simulation_metrics.get("security",0.38))),0.0,1.0)

## Another people's fighting strength on the same scale (war_loop.ratio's).
static func their_fighting_strength(civ:Dictionary)->float:
	var pop:=maxf(10.0,float(civ.get("population",100.0)))
	var readiness:=clampf(float(civ.get("military_readiness",0.45)),0.2,1.0)
	var warriors:=clampf(float(civ.get("military_population",0.0)),0.0,pop)
	return maxf(1.0,(pop-warriors)*(0.55+readiness*0.3)+warriors*(1.0+WARRIOR_WEIGHT*readiness))

static func strengths()->Dictionary:
	## {id: {value, why}} for Might, Genius, Persuasion, Cunning, Wealth,
	## Splendor, Order, Endurance, Reach (and "_culture", the allure of our
	## culture, for the views). Always read fresh: nothing here can go stale.
	return _reckon_strengths()

## Kept for callers and tests from before readings were stored (no-op).
static func forget()->void:
	pass

static func _reckon_strengths()->Dictionary:
	var s=WorldSimulation.state
	var m:Dictionary=s.simulation_metrics
	var pop:=_population()
	var result:Dictionary={}
	var warriors:=_warriors()
	var readiness:=_readiness()
	var might:=clampf(warriors*readiness/maxf(1.0,pop*MIGHT_FULL_SHARE),0.0,1.0)
	result["might"]={"value":might,"why":"%d under arms or training, ready %d%%, among %d people" % [roundi(warriors),roundi(readiness*100.0),roundi(pop)]}
	var known:=float(s.known_discoveries.size())
	var best_known:=_best_known_rival()
	var scholars:=float(s.effective_workers("Knowledge"))
	var genius:=clampf(0.5+(known-best_known)/maxf(20.0,maxf(known,best_known))*1.5,0.0,1.0) if best_known>=0.0 else clampf(0.35+scholars/maxf(1.0,pop)*3.0,0.0,1.0)
	result["genius"]={"value":genius,"why":"%d practices known%s; %d people at research" % [roundi(known),(" against %d for the most learned people we know" % roundi(best_known)) if best_known>=0.0 else "",roundi(scholars)]}
	var envoy:=_office_skill("Envoy","Diplomacy")
	var lived:Dictionary=s.societal_values.get("lived",{}) if s.societal_values is Dictionary else {}
	var openness:=clampf((float(lived.get("openness",.5))+float(lived.get("pluralism",.5)))*.5,0,1)
	var persuasion:=clampf(envoy*0.55+openness*0.3+_familiarity()*0.15,0.0,1.0)
	result["persuasion"]={"value":persuasion,"why":"our envoy's skill %d%%, openness %d%%" % [roundi(envoy*100.0),roundi(openness*100.0)]}
	var scout:=_office_skill("ChiefScout","Knowledge")
	var cunning:=clampf(scout*0.6+clampf(float(s.population_allocations.get("Survey",0))/maxf(1.0,pop*0.08),0.0,1.0)*0.4,0.0,1.0)
	result["cunning"]={"value":cunning,"why":"our chief scout's skill %d%%, %d out watching and finding" % [roundi(scout*100.0),int(s.population_allocations.get("Survey",0))]}
	var food_days:=float(m.get("food_days",0.0))
	var materials:=0.0
	for resource in ["Timber","Stone","Clay","Fiber Plants"]: materials+=float(s.resource_stockpiles.get(resource,0.0))
	var wealth:=clampf(clampf(food_days/WEALTH_FOOD_DAYS,0.0,1.0)*0.65+clampf(materials/maxf(1.0,pop*5.0),0.0,1.0)*0.35,0.0,1.0)
	result["wealth"]={"value":wealth,"why":"food for %d days, %d loads of materials" % [roundi(food_days),roundi(materials)]}
	var works:=minf(0.25,Rewards.local_bonus(s,"attraction")+Rewards.local_bonus(s,"reputation")*0.5)
	var report:=Culture.allure_report(false)
	result["_culture"]=float(report.allure)
	var tier:=float(WorldSimulation.settlements.city_form().get("tier",0.0)) if WorldSimulation.settlements!=null and WorldSimulation.settlements.has_method("city_form") else 0.0
	var splendor:=clampf(works*2.4+maxf(0.0,float(report.allure)-works)*0.6+clampf(tier/6.0,0.0,1.0)*0.15,0.0,1.0)
	result["splendor"]={"value":splendor,"why":"%s; the town's building era %d" % ["great works standing" if works>0.0 else "no great work standing yet",roundi(tier)]}
	var legitimacy:=float(m.get("legitimacy",0.5))
	var cohesion:=float(m.get("cohesion",0.5))
	var order:=clampf(legitimacy*0.55+cohesion*0.25+_office_skill("Steward","Administration")*0.2,0.0,1.0)
	result["order"]={"value":order,"why":"trust in the chiefs %d%%, holding together %d%%" % [roundi(legitimacy*100.0),roundi(cohesion*100.0)]}
	var water_days:=float(s.water_metrics.get("days",0.0))
	var health:=float(s.population_health)
	var endurance:=clampf(clampf(food_days/ENDURANCE_FOOD_DAYS,0.0,1.0)*0.4+clampf(water_days/5.0,0.0,1.0)*0.15+health*0.25+cohesion*0.2,0.0,1.0)
	result["endurance"]={"value":endurance,"why":"food for %d days, water for %d, health %d%%" % [roundi(food_days),roundi(water_days),roundi(health*100.0)]}
	var met:=0
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))>=2: met+=1
	var logistics:=float(m.get("logistics",0.16))
	var reach:=clampf(logistics*0.6+clampf(float(met)/5.0,0.0,1.0)*0.4,0.0,1.0)
	result["reach"]={"value":reach,"why":"carrying and hauling %d%%, %d peoples met" % [roundi(logistics*100.0),met]}
	return result

static func _office_skill(office:String,skill:String)->float:
	var government=WorldSimulation.government
	var holder:Dictionary=government.officeholder(office) if government!=null and government.has_method("officeholder") else {}
	if holder.is_empty(): return 0.2
	return clampf(float((holder.get("skills",{}) as Dictionary).get(skill,40.0))/100.0,0.0,1.0)

static func _familiarity()->float:
	var total:=0.0
	var count:=0
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))<2: continue
		total+=float(_ties(String(civ.id)).get("familiarity",0.0))
		count+=1
	return total/float(count) if count>0 else 0.0

## Our ties with a people, read without creating a record (a reading must
## never change the ledger it reads).
static func _ties(civ_id:String)->Dictionary:
	var connections:Variant=(Exchange.data() as Dictionary).get("connections",{})
	if not connections is Dictionary: return {}
	var ties:Variant=(connections as Dictionary).get(Exchange.owner_id(civ_id),{})
	return ties if ties is Dictionary else {}

static func _best_known_rival()->float:
	var best:=-1.0
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))<2: continue
		best=maxf(best,float((civ.get("discovery_profile",{}).get("technologies",[]) as Array).size()))
	return best

# ---------------------------------------------------------------------- views

## How one other people sees us: {known, allure, awe, fear, respect, trust,
## resentment, envy, contempt, strength_ratio, why:{view: text}}. A people that
## has not met us holds no view (known false, all zero).
static func view_of(civ_id:String,our:Dictionary={})->Dictionary:
	if String(WorldSimulation.actor_id)!="player": return {"known":false,"allure":0.0,"awe":0.0,"fear":0.0,"respect":0.0,"trust":0.0,"resentment":0.0,"envy":0.0,"contempt":0.0,"strength_ratio":1.0,"why":{}}
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var relation:Dictionary=civ.get("player_relation",{}) if not civ.is_empty() else {}
	var empty:={"known":false,"allure":0.0,"awe":0.0,"fear":0.0,"respect":0.0,"trust":0.0,"resentment":0.0,"envy":0.0,"contempt":0.0,"strength_ratio":1.0,"why":{}}
	if civ.is_empty() or int(relation.get("contact_level",0))<2: return empty
	if our.is_empty(): our=strengths()
	var why:Dictionary={}
	# Might as they see it: ours over theirs, on one scale.
	var ours:=our_fighting_strength()
	var theirs:=their_fighting_strength(civ)
	# Bound with others against us, they weigh us against all of them.
	var league:=load("res://scripts/fear_league.gd") as GDScript
	if league!=null and bool(league.call("is_member",civ_id)): theirs=maxf(theirs,float(league.call("combined_strength")))
	var ratio:=ours/maxf(1.0,theirs)
	var might_term:=clampf((ratio-0.8)/1.6,0.0,1.0)
	# Works they have heard of, and what we know that they do not.
	var heard:=clampf(Rewards.diplomatic_bonus(WorldSimulation.state,civ_id,_day())/0.20,0.0,1.0)
	var their_known:=float((civ.get("discovery_profile",{}).get("technologies",[]) as Array).size())
	var our_known:=float(WorldSimulation.state.known_discoveries.size())
	var lead:=clampf((our_known-their_known)/maxf(20.0,maxf(our_known,their_known)),-1.0,1.0)
	var awe:=clampf(might_term*0.45+heard*0.35+maxf(0.0,lead)*0.35,0.0,1.0)
	why["awe"]="our fighting strength %s theirs%s%s" % [_ratio_words(ratio)," · works of ours they have heard of" if heard>0.05 else "",(" · we know %d things they do not" % roundi(our_known-their_known)) if lead>0.05 else ""]
	var lives:=_lives()
	var fear:=float(lives.call("rival_dread",civ_id)) if lives!=null else 0.0
	why["fear"]="what they remember of our wrath and harm" if fear>0.05 else "no harm done to them"
	# Allure: plenty, beauty and learning draw them; our warbands menace them.
	var tension:=clampf(float(relation.get("border_tension",0.0)),0.0,1.0)
	var menace:=float(our.might.value)*(0.35+tension*0.65)
	var culture:=float(our.get("_culture",-1.0))
	if culture<0.0: culture=float(Culture.allure_report(false).allure)
	var allure:=clampf(culture*0.5+float(our.wealth.value)*0.25+maxf(0.0,lead)*0.15+float(our.order.value)*0.1-menace*0.35,0.0,1.0)
	why["allure"]="plenty %d%%, culture %d%%%s" % [roundi(float(our.wealth.value)*100.0),roundi(culture*100.0),(" · our warbands menace them (−%d)" % roundi(menace*35.0)) if menace>0.05 else ""]
	var ties:=_ties(civ_id)
	var respect:=clampf(float(ties.get("respect",0.0))+heard*0.25+maxf(0.0,lead)*0.2+clampf(ratio-0.7,0.0,1.0)*0.2+float(our.order.value)*0.15,0.0,1.0)
	why["respect"]="their scholars' and travellers' regard, works that stand, our order"
	var rivals:=_rivals()
	var character:Dictionary=rivals.call("rival_character",civ_id) if rivals!=null else {}
	var leader:=ForeignDiplomacy.leader(civ_id)
	var trust:=clampf(0.5+float(leader.get("trust",0.0))*0.5+(0.15 if String(relation.get("treaty","none")) not in ["none","","war"] else 0.0)-(0.3 if bool(relation.get("at_war",false)) else 0.0),0.0,1.0)
	why["trust"]="their ruler's trust in our word%s" % (" · a treaty between us" if String(relation.get("treaty","none")) not in ["none","","war"] else "")
	var grudge:=float(character.get("grudge_weight",0.0))
	var resentment:=clampf(float(ties.get("resentment",0.0))+grudge*0.5,0.0,1.0)
	why["resentment"]="grudges held against us" if resentment>0.05 else "no grudge held"
	# The dangers: rich and not feared is raided; weak and unrespected is tested.
	var envy:=clampf((float(our.wealth.value)*0.6+heard*0.4)*(1.0-awe)*(1.0-trust*0.5)*(1.0-fear*0.5),0.0,1.0)
	why["envy"]="they see our stores and works%s" % (" and too few to guard them" if awe<0.35 else "")
	var contempt:=clampf((1.0-respect)*clampf(1.25-ratio,0.0,1.0)*(1.0-fear*0.6),0.0,1.0)
	why["contempt"]="our fighting strength %s theirs" % _ratio_words(ratio)
	return {"known":true,"allure":allure,"awe":awe,"fear":fear,"respect":respect,"trust":trust,"resentment":resentment,"envy":envy,"contempt":contempt,"strength_ratio":ratio,"why":why}

static func _ratio_words(ratio:float)->String:
	if ratio>=3.0: return "is several times"
	if ratio>=1.8: return "is about twice"
	if ratio>=1.25: return "is greater than"
	if ratio>=0.8: return "matches"
	if ratio>=0.5: return "is below"
	return "is a fraction of"

## Every people we have met, with its view of us.
static func views()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if String(WorldSimulation.actor_id)!="player": return result
	var our:=strengths()
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if not bool(civ.get("alive",true)): continue
		var v:=view_of(String(civ.id),our)
		if not bool(v.known): continue
		v["civ_id"]=String(civ.id)
		v["civ_name"]=String(civ.get("name",civ.id))
		result.append(v)
	return result

# ---------------------------------------------------------------------- pride

## Our own people's pride in who they are: the splendour they live among and
## the awe and allure a people like theirs commands. The same for every people,
## computer-run or not: read from its own strengths (its works, might,
## learning, plenty, order and culture), never from who happens to have met it.
## {value, why, awe, allure}. 0.5 is ordinary. `seen` is kept for callers.
static func pride(our:Dictionary={},_seen:Array=[])->Dictionary:
	if our.is_empty(): our=strengths()
	var command:=renown(our)
	# 0.5 is an ordinary people; splendour, awe and allure raise it.
	var value:=clampf(0.5+float(our.splendor.value)*0.25+float(command.awe)*0.15+float(command.allure)*0.1,0.0,1.0)
	var words:PackedStringArray=["the works and treasures we live among"]
	if float(command.awe)>=0.3: words.append("the awe our might and works command")
	if float(command.allure)>=0.3: words.append("the pull of our plenty and our ways")
	return {"value":value,"awe":float(command.awe),"allure":float(command.allure),"why":", ".join(words)}

## The awe and allure a people commands by what it is, before anyone in
## particular sees it (view_of adds each observer's own memories and
## strength): might, works and a lead in learning awe; culture, plenty,
## learning and good order draw, and warbands put people off.
static func renown(our:Dictionary={})->Dictionary:
	if our.is_empty(): our=strengths()
	var might:=float(our.might.value)
	var genius:=float(our.genius.value)
	var culture:=float(our.get("_culture",0.0))
	var awe:=clampf(might*0.45+float(our.splendor.value)*0.35+maxf(0.0,genius-0.5)*0.4,0.0,1.0)
	var allure:=clampf(culture*0.5+float(our.wealth.value)*0.25+maxf(0.0,genius-0.5)*0.2+float(our.order.value)*0.1-might*0.35*0.35,0.0,1.0)
	return {"awe":awe,"allure":allure}

# -------------------------------------------------------- read by daily systems

## The month's reading of might and pride, stored in the people's own metrics
## (saved with them): the daily systems that read them (attraction, cohesion
## and legitimacy targets) must not rebuild every people's view each day, and a
## reading kept with the state can never belong to another world or save.
## ConsequenceEngine.process_day calls this once a month.
static func record_monthly()->void:
	var our:=strengths()
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	for row:Array in STRENGTHS: metrics["standing_"+String(row[0])]=float((our[String(row[0])] as Dictionary).value)
	var command:=renown(our)
	metrics["standing_awe"]=float(command.awe)
	metrics["standing_allure"]=float(command.allure)
	metrics["standing_pride"]=float(pride(our).value)
	# How many peoples we know are moved against us (the rail's Standing badge).
	metrics["standing_dangers"]=float(danger_count(our))

## Peoples we know who are moved against us now: envy or contempt past their
## floors, a grudge heavy enough to raid, or a league against us.
static func danger_count(our:Dictionary={})->int:
	var count:=0
	var league:=load("res://scripts/fear_league.gd") as GDScript
	var war:=load("res://scripts/war_loop.gd") as GDScript
	for v:Dictionary in views():
		var id:=String(v.civ_id)
		var moved:=float(v.envy)>ENVY_RAID_FLOOR or float(v.contempt)>CONTEMPT_FLOOR
		if not moved and war!=null: moved=float(war.call("grudge_raid_chance",id))>0.0
		if not moved and league!=null: moved=bool(league.call("is_member",id))
		if moved: count+=1
	return count

static func monthly()->Dictionary:
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	return {"might":float(metrics.get("standing_might",0.0)),"pride":float(metrics.get("standing_pride",0.5)),"allure":float(metrics.get("standing_allure",ALLURE_ORDINARY)),"awe":float(metrics.get("standing_awe",0.0))}

## How much a target's fighting strength against ours holds a ruler back from
## declaring war on it: positive when they are stronger (awe of their might),
## negative when they are much weaker (contempt emboldens). The same for every
## ruler, read in its own scope; war decisions add it to other deterrence.
static func war_deterrence(target:Dictionary)->float:
	var ratio:=their_fighting_strength(target)/our_fighting_strength()
	return clampf((ratio-1.0)*0.12,-0.12,0.18)

## Allure an ordinary people commands (a plain village's culture and plenty).
const ALLURE_ORDINARY:=0.25

## Our warbands menace would-be newcomers; pride keeps our own people; allure
## draws others in.
static func attraction_shift()->float:
	var m:=monthly()
	return -float(m.might)*0.08+(float(m.pride)-0.5)*0.08+(float(m.allure)-ALLURE_ORDINARY)*0.08

## Pride lifts how well the people hold together and trust their chiefs, a little.
static func cohesion_shift()->float:
	return (float(monthly().pride)-0.5)*0.06

static func legitimacy_shift()->float:
	return (float(monthly().pride)-0.5)*0.04

## How far pride forgives the chiefs: the share by which the blame for
## unpopular orders, constant change and failed aims is lightened. A proud
## people forgives up to 30%; one ashamed of itself blames up to 20% more.
static func forgiveness()->float:
	return clampf((float(monthly().pride)-0.5)*0.8,-0.2,0.3)

## Share of the people under arms (trained, training or called up) that
## households carry without complaint; beyond it, levies are resented.
const LEVY_EASY_SHARE:=0.05

## How much a heavy levy weighs on the people, 0..: the share under arms past
## LEVY_EASY_SHARE (fields without hands, sons away). Read the same way for
## every people from its own army.
static func levy_burden()->float:
	return maxf(0.0,_warriors()/_population()-LEVY_EASY_SHARE)

## The blame multiplier the daily systems apply (1 - forgiveness).
static func blame()->float:
	return 1.0-forgiveness()

# ------------------------------------------------ read by the Standing page

## What the shape of our strengths makes of us, in plain words:
## {id, words, top, second, low, mean, spread, lopsided}. id is the leading
## strength's id, "balanced" or "small".
static func posture(our:Dictionary={})->Dictionary:
	if our.is_empty(): our=strengths()
	var ranked:Array=[]
	for row:Array in STRENGTHS: ranked.append({"id":String(row[0]),"name":String(row[1]),"value":float((our[String(row[0])] as Dictionary).value)})
	ranked.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.value)>float(b.value))
	var top:Dictionary=ranked[0]
	var second:Dictionary=ranked[1]
	var low:Dictionary=ranked[-1]
	var total:=0.0
	for entry:Dictionary in ranked: total+=float(entry.value)
	var spread:=float(top.value)-float(low.value)
	var id:=String(top.id)
	var words:=""
	if float(top.value)<0.3:
		id="small"
		words="A small people, not yet strong in anything"
	elif spread<0.3:
		id="balanced"
		words="A balanced people: nothing stands far above the rest, nothing is left undone"
	else:
		words=String(LEANING[top.id])
		if float(second.value)>=0.45 and float(second.value)>=float(top.value)-0.25: words+=", "+String(ALSO[second.id])
		if float(low.value)<0.25: words+=", "+String(NEGLECT[low.id])
	return {"id":id,"words":words+".","top":top,"second":second,"low":low,"mean":total/float(ranked.size()),"spread":spread,"lopsided":spread>=0.55}

## One sentence of how a people sees us, from its strongest feeling and the
## dangers it holds.
static func view_words(v:Dictionary)->String:
	if not bool(v.get("known",false)): return "They have not met us."
	var lead:=""
	var best:=0.2
	for pair:Array in [["allure","They are drawn to us"],["awe","They hold us in awe"],["fear","They fear us"],["respect","They respect us"],["trust","They trust our word"],["resentment","They resent us"]]:
		if float(v.get(String(pair[0]),0.0))>best:
			best=float(v.get(String(pair[0]),0.0))
			lead=String(pair[1])
	var parts:PackedStringArray=[]
	parts.append((lead+".") if lead!="" else "They hardly know what to make of us.")
	if float(v.get("envy",0.0))>ENVY_RAID_FLOOR: parts.append("They eye our stores.")
	if float(v.get("contempt",0.0))>CONTEMPT_FLOOR: parts.append("They think us easy to push.")
	elif float(v.get("resentment",0.0))>=0.4 and not lead.begins_with("They resent"): parts.append("They hold a grudge.")
	return " ".join(parts)

## "about 2 in 100 each month" for a monthly chance.
static func monthly_odds_words(chance:float)->String:
	if chance<=0.0: return "none"
	if chance>=0.0095: return "about %d in 100 each month" % maxi(1,roundi(chance*100.0))
	return "about 1 in %d each month" % maxi(100,roundi(1.0/chance/50.0)*50)

## "1.8 times as often" or "half as often" against a people that feels
## nothing either way about us.
static func times_words(weight:float)->String:
	if weight>=1.05: return "%.1f times as often" % weight
	if weight<=0.55: return "half as often or less"
	return "less often (%.1f times)" % weight

## What this people's view makes it do, with the engine's own odds and
## weights: [{id, tone ("danger", "good", "calm"), words, detail}].
static func consequences(civ_id:String,v:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	if not bool(v.get("known",false)): return out
	var league:=load("res://scripts/fear_league.gd") as GDScript
	if league!=null and bool(league.call("is_member",civ_id)):
		var others:PackedStringArray=[]
		for id in league.call("members"):
			if String(id)!=civ_id: others.append(String(ForeignDiplomacy.civilization(String(id)).get("name",id)))
		out.append({"id":"league","tone":"danger","words":"Bound with %s against us, for fear of us" % " and ".join(others),"detail":"They weigh our strength against all of theirs together, back each other's raids and demands (%.1f times as often) and share every grudge." % float(league.get_script_constant_map().get("RAID_BACKING",1.5))})
	var war:=load("res://scripts/war_loop.gd") as GDScript
	if war!=null:
		var grudge:=float(war.call("grudge_raid_chance",civ_id))
		if grudge>0.0: out.append({"id":"grudge","tone":"danger","words":"Raiders to settle an old grudge: %s" % monthly_odds_words(grudge),"detail":"Their ruler's grudges weigh heavy enough to send raiders without a new quarrel."})
		var raid:=float(war.call("envy_raid_chance",civ_id,float(v.get("envy",0.0))))
		if raid>0.0: out.append({"id":"envy","tone":"danger","words":"Raiders for our stores: %s" % monthly_odds_words(raid),"detail":"Envy %d%%: %s." % [roundi(float(v.envy)*100.0),String((v.get("why",{}) as Dictionary).get("envy",""))]})
	var lives:=_lives()
	if lives!=null:
		for row:Array in [["tribute_demand","Demands for tribute and tests of our resolve","danger"],["redress_demand","Demands to right old wrongs","danger"],["gift_goods","Gifts and offers of peace","good"],["trade_offer","Offers of trade and pacts","good"]]:
			var weight:=float(lives.call("standing_weight",String(row[0]),civ_id,v))
			if absf(weight-1.0)<0.15: continue
			var tone:=String(row[2])
			if weight<1.0: tone="calm" if tone=="danger" else "danger"
			out.append({"id":String(row[0]),"tone":tone,"words":"%s: %s" % [String(row[1]),times_words(weight)],"detail":"When their envoys come, against a people that feels nothing either way about us."})
	return out

## What pride and menace do at home this month, in points of 100:
## {attraction, cohesion, legitimacy, menace}.
static func home_effects()->Dictionary:
	var m:=monthly()
	return {"attraction":((float(m.pride)-0.5)+(float(m.allure)-ALLURE_ORDINARY))*8.0,"cohesion":cohesion_shift()*100.0,"legitimacy":legitimacy_shift()*100.0,"menace":-float(m.might)*8.0,"forgiveness":forgiveness(),"levy":levy_burden(),"under_arms":_warriors()/_population(),
		# What the levy costs, as ConsequenceEngine's targets take it.
		"levy_cohesion":levy_burden()*60.0,"levy_trust":levy_burden()*40.0*blame()}

## Another people's strengths, reckoned in their own scope by the same code as
## ours ({} if they are not simulated). Rounded to tens: we know them from
## envoys and travellers, not from their own tallies.
static func their_strengths(civ_id:String)->Dictionary:
	if civ_id=="" or not WorldSimulation.actors.has(civ_id): return {}
	var theirs:Variant=WorldSimulation.scoped(civ_id,func()->Dictionary: return strengths())
	if not theirs is Dictionary: return {}
	var result:Dictionary={}
	for row:Array in STRENGTHS:
		var entry:Variant=(theirs as Dictionary).get(String(row[0]),{})
		if entry is Dictionary: result[String(row[0])]={"value":snappedf(clampf(float((entry as Dictionary).get("value",0.0)),0.0,1.0),0.1)}
	return result
