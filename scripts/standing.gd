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
		total+=float(Exchange.connection(String(civ.id)).get("familiarity",0.0))
		count+=1
	return total/float(count) if count>0 else 0.0

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
	var ties:=Exchange.connection(civ_id)
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

## Our own people's pride in who they are: the splendour they live among, the
## awe and allure the known world holds of them, and their own order.
## {value, why}. 0.5 is ordinary.
static func pride(our:Dictionary={},seen:Array=[])->Dictionary:
	if our.is_empty(): our=strengths()
	if seen.is_empty(): seen=views()
	var awe:=0.0
	var allure:=0.0
	for v in seen:
		awe=maxf(awe,float((v as Dictionary).get("awe",0.0)))
		allure=maxf(allure,float((v as Dictionary).get("allure",0.0)))
	# 0.5 is an ordinary people; splendour, the world's awe and allure raise it.
	var value:=clampf(0.5+float(our.splendor.value)*0.25+awe*0.15+allure*0.1,0.0,1.0)
	return {"value":value,"why":"the works and treasures we live among%s" % (", and how the peoples we know see us" if not seen.is_empty() else "")}

# -------------------------------------------------------- read by daily systems

## The month's reading of might and pride, stored in the people's own metrics
## (saved with them): the daily systems that read them (attraction, cohesion
## and legitimacy targets) must not rebuild every people's view each day, and a
## reading kept with the state can never belong to another world or save.
## ConsequenceEngine.process_day calls this once a month.
static func record_monthly()->void:
	var our:=strengths()
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	metrics["standing_might"]=float(our.might.value)
	metrics["standing_pride"]=float(pride(our,views()).value)

static func monthly()->Dictionary:
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	return {"might":float(metrics.get("standing_might",0.0)),"pride":float(metrics.get("standing_pride",0.5))}

## Our warbands menace would-be newcomers; pride keeps our own people.
static func attraction_shift()->float:
	var m:=monthly()
	return -float(m.might)*0.08+(float(m.pride)-0.5)*0.08

## Pride lifts how well the people hold together and trust their chiefs, a little.
static func cohesion_shift()->float:
	return (float(monthly().pride)-0.5)*0.06

static func legitimacy_shift()->float:
	return (float(monthly().pride)-0.5)*0.04
