extends RefCounted
## A ruler's preferences choose ordinary orders. These are not simulation bonuses.
const PERSONALITY=preload("res://scripts/leader_personality.gd")
const DOMAINS:=["demography","nutrition","health","labor","knowledge","production","infrastructure","logistics","ecology","institutions","security","culture"]
## Ambitions worth taking up only once another people is known (preferences).
const AMBITIONS_NEEDING_OTHERS:=["military","dominion","retribution","commerce"]

static func preferences(personality:Dictionary,situation:Dictionary)->Dictionary:
	var p:Dictionary={}
	for axis:String in PERSONALITY.AXES:p[axis]=clampf(float(personality.get(axis,.5)),0,1)
	var open:=float(p.openness);var discipline:=float(p.discipline);var empathy:=float(p.empathy)
	var assertive:=float(p.assertiveness);var risk:=float(p.risk_tolerance)
	var constraints:=PERSONALITY.food_constraints(situation)
	var hungry:=bool(constraints.hungry)
	var war:=bool(situation.get("at_war",false))
	var goals:=PERSONALITY.agenda(situation,p)
	var weights:={"demography":.25+empathy*.9,"nutrition":.3+empathy*.6+(1-risk)*.3,"health":.25+empathy*.8,"labor":.2+discipline*.6,"knowledge":.15+open*1.2,"production":.25+discipline*.5+open*.4,"infrastructure":.25+discipline*.65,"logistics":.25+open*.5+assertive*.3,"ecology":.2+empathy*.45+(1-risk)*.35,"institutions":.2+discipline*.65,"security":.15+assertive*.8+discipline*.5,"culture":.2+empathy*.6+open*.4}
	# The stated leading goal must be visible in actual spending of attention.
	var goal_domains:Dictionary={"care":{"health":1.5,"demography":.7},"learning":{"knowledge":1.8,"culture":.4},"security":{"security":1.8,"infrastructure":.6,"logistics":.4},"exchange":{"logistics":1.5,"production":.75,"culture":.5},"growth":{"infrastructure":1.5,"demography":1.0,"production":.5}}
	if hungry and not constraints.food_shortage:goal_domains.care={"logistics":1.5,"health":.7}
	for domain:String in goal_domains[String(goals[0].id)]:weights[domain]+=float(goal_domains[String(goals[0].id)][domain])
	if constraints.food_shortage:weights.nutrition+=3.0;weights.health+=1.0;weights.ecology+=.8
	if constraints.delivery_shortage:weights.logistics+=3.0
	var integration:=float(situation.get("integration_pressure",0))
	weights.institutions+=integration*8
	weights.culture+=integration*5
	weights.infrastructure+=integration*5
	if war:weights.security+=1.5;weights.logistics+=1.0
	# Every ambition a people can take up is open to its ruler, by fit to its
	# temper (leader_personality.gd AMBITION_TEMPER).
	var ambitions:Dictionary={}
	for candidate:String in PERSONALITY.AMBITION_TEMPER:ambitions[candidate]=PERSONALITY.ambition_fit(candidate,p)
	# Arms, rule over others, vengeance and trade need other peoples: until one
	# is met, a ruler sets its people on something it can use now.
	if int(situation.get("peoples_known",-1))==0:
		for candidate:String in AMBITIONS_NEEDING_OTHERS:ambitions[candidate]=float(ambitions[candidate])*.5
	if constraints.food_shortage:ambitions.sustenance+=2
	if constraints.delivery_shortage:ambitions.commerce+=2
	if war:ambitions.military+=1
	var ambition:="horizons"
	for candidate:String in ambitions:
		if float(ambitions[candidate])>float(ambitions[ambition]):ambition=candidate
	var training:="maintain" if discipline<.35 else ("intensive" if discipline>.68 and float(situation.get("food_days",0))>75 else "regular")
	if hungry:training="suspended"
	elif war:training="maintain" if risk<.65 else "regular"
	return {"personality":p,"goals":goals,"ambition":ambition,"research_weights":weights,"training":training,"at_war":war,"hungry":hungry,"food_shortage":constraints.food_shortage,"delivery_shortage":constraints.delivery_shortage,
		"recruit_share":clampf(.025+assertive*.055+discipline*.035+risk*.02-empathy*.02+(.08 if war else 0),.02,.22),
		"capacity_share":clampf(.3+assertive*.45+discipline*.25+(.2 if war else 0),.15,1),"deploy_share":.35+assertive*.25+risk*.2,
		# Boldness settles sooner, farther and oftener, but sends thinner rations:
		# a bold ruler's new town may go hungry before its first harvest; a
		# cautious one waits for full stores and sends settlers well provisioned.
		"expansion_food":45+(1-risk)*40+empathy*15,"settle_distance":16+24*risk,"settle_margin_days":ESTABLISHMENT_DAYS*lerpf(1.35,.65,risk),"expansion_months":expansion_months(p),
		"scout_days":180 if open>.75 and risk>.65 else (90 if open>.5 else 30),"scout_food":22+(1-risk)*30,
		"war_opinion":-.85+assertive*.35+risk*.2-empathy*.15,"war_food":30+(1-risk)*50,
		"trade_opinion":.25-empathy*.35-open*.15,"peace_food":12+empathy*18+(1-risk)*12,
		"offensive":assertive*.55+risk*.45>empathy*.3+(1-risk)*.35+.15}

## A ruler's research emphasis, in the steps the player's own screen uses (0 to
## 12 a field). Emphasis is only a set of shares, so no budget is carried over:
## steps are not a resource and a larger plan buys no research. Plans are laid
## out in Research600.ATTENTION_STEPS steps unless `steps` says otherwise. When
## there are steps enough, every field the ruler weighs at all keeps one, so each
## line stays alive on questions of its own age; the rest follow the ruler's
## preferences, twelve at most on any field.
static func research_plan(weights:Dictionary,steps:int=-1)->Dictionary:
	if steps<0:steps=preload("res://scripts/research_600_catalog.gd").ATTENTION_STEPS
	var result:Dictionary={}
	var weighed:Array[String]=[]
	for domain:String in DOMAINS:
		result[domain]=0
		if float(weights.get(domain,.1))>0.0:weighed.append(domain)
	if weighed.is_empty() or steps<=0:return result
	var left:=steps
	if steps>=weighed.size():
		for domain:String in weighed:result[domain]=1
		left-=weighed.size()
	for _point in left:
		var best:="";var score:=0.0
		for domain:String in weighed:
			if int(result[domain])>=12:continue
			var value:=float(weights.get(domain,.1))/float(int(result[domain])+1)
			if value>score:best=domain;score=value
		if best=="":break
		result[best]+=1
	return result

static func unit_score(definition:Dictionary,plan:Dictionary)->float:
	var p:Dictionary=plan.personality
	var preference:float={"force_generation":.5+(1-float(p.risk_tolerance))*.5,"heavy_infantry":float(p.discipline),"missile_infantry":float(p.openness),"mounted":float(p.risk_tolerance)*.6+float(p.assertiveness)*.4,"protection":1-float(p.risk_tolerance),"reconnaissance":float(p.openness),"siege_fires":float(p.assertiveness)*.6+float(p.discipline)*.4,"specialist_infantry":float(p.openness)*.6+float(p.risk_tolerance)*.4,"autonomous":float(p.openness)*.5+(1-float(p.risk_tolerance))*.5}.get(String(definition.get("branch","")),.5)
	# Capability matters, but longest training time is not a universal doctrine.
	return log(1+float(definition.get("training_days",7)))*(.3+float(p.openness)*.3)+preference*3.0

## The forces a rival staff measures its choices against: the player's
## army at home and in the field, grouped by unit and kit. [] when the player
## has no army.
static func threat_mix()->Array:
	var mc:Variant=MilitaryCampaign
	if mc==null: return []
	# Only a people in contact with ours (or at war with us) has seen our army.
	var civs:Variant=CivilizationSystem
	if civs==null: return []
	var index:int=civs._civilization_index(String(WorldSimulation.actor_id))
	if index<0: return []
	var relation:Dictionary=(civs.civilizations[index] as Dictionary).get("player_relation",{})
	if int(relation.get("contact_level",0))<1 and not bool(relation.get("at_war",false)): return []
	var grouped:={}
	for force in [mc.home_army]+Array(mc.field_armies):
		if not force is Dictionary: continue
		for formation in (force as Dictionary).get("formations",[]):
			var key:=String(formation.get("unit","levy"))+"|"+String(formation.get("weapon","improvised"))
			var entry:Dictionary=grouped.get(key,{"unit":String(formation.get("unit","levy")),"weapon":String(formation.get("weapon","improvised")),"count":0,"authorized_count":0,"equipment":0,"equipment_required":0,"training":0.7})
			entry.count=int(entry.count)+maxi(0,int(formation.get("count",0)))
			entry.authorized_count=int(entry.authorized_count)+maxi(0,int(formation.get("authorized_count",formation.get("count",0))))
			entry.equipment=int(entry.equipment)+maxi(0,int(formation.get("equipment",0)))
			entry.equipment_required=int(entry.equipment_required)+maxi(0,int(formation.get("equipment_required",0)))
			grouped[key]=entry
	var out:=[]
	for key in grouped:
		if int(grouped[key].count)>0: out.append(grouped[key])
	return out

## What raising this unit is worth against a threat mix, by the combat
## engine's own reading (pierce against armour, matchups, machines) per what
## it costs: ln(fighting power a man against them / (1 + training days / 60
## + workshop days a man / 2)). 0 against no threat.
static func counter_score(campaign:Object,unit:String,weapon:String,threat:Array)->float:
	if threat.is_empty(): return 0.0
	var sim=campaign.simulator
	var sets:int=sim.equipment_required_for_weapon(weapon,100)
	var ours:Dictionary=sim.create_formation_force("Candidate",[{"id":1,"unit":unit,"weapon":weapon,"count":100,"authorized_count":100,"equipment":sets,"equipment_required":sets,"ammunition":sim.ammunition_required_for_weapon(weapon,sets,100),"training":0.8}],1.0,1.0)
	var cohorts:Array=sim.evaluate_force(ours,{"formations":threat},1.0)
	if cohorts.is_empty(): return 0.0
	var c:Dictionary=cohorts[0]
	var power:=sqrt(maxf(0.0001,float(c.attack))*maxf(0.0001,float(c.defense))/maxf(0.05,float(c.get("through",1.0))))
	var recipe:Dictionary=campaign._equipment_recipe(weapon)
	var work:=float(recipe.get("days",1.0))*float(sets)/100.0
	var cost:=1.0+float(campaign.UnitCatalog.training_days(unit))/60.0+work/2.0
	return log(power/cost)

static func preferred_mission(service:String,available:Array,plan:Dictionary)->String:
	var p:Dictionary=plan.personality
	var ranked:Array=[]
	if service=="navy":
		if bool(plan.at_war) and bool(plan.offensive):ranked=["convoy_raiding","strike_force","invasion_support"]
		elif float(p.empathy)+float(p.openness)>1.1:ranked=["convoy_escort","patrol"]
		else:ranked=["patrol","convoy_escort"]
	else:
		if not bool(plan.at_war):ranked=["reconnaissance","air_superiority","interception"] if float(p.openness)>float(p.discipline) else ["interception","air_superiority","reconnaissance"]
		elif not bool(plan.offensive):ranked=["interception","air_superiority","reconnaissance","air_supply"]
		elif float(p.empathy)>.55:ranked=["close_air_support","logistics_strike","air_superiority"]
		else:ranked=["logistics_strike","strategic_bombing","close_air_support","naval_strike","air_superiority"]
	for mission:String in ranked:
		if mission in available:return mission
	return "hold"

## A gift is for making or mending a friendship, not for friends already won.
const GOODWILL_CEILING:=.5
## Food goes as a gift only from stores this full (days).
const GOODWILL_FOOD_DAYS:=90.0

## A known deterring Great Work (e.g. Crown of the Ridge) lowers the opinion at
## which this ruler would start a war against its holder; it never forbids war.
static func diplomatic_action(relation:Dictionary,plan:Dictionary,food_days:float,deterrence:float=0.0)->String:
	if bool(relation.get("at_war",false)):
		return "seek_peace" if food_days<float(plan.peace_food) else ""
	var opinion:=float(relation.get("opinion",0))
	# Deterrence: works they have heard of and a stronger target hold a ruler
	# back; a much weaker target emboldens it (standing.gd war_deterrence).
	if opinion<float(plan.war_opinion)-clampf(deterrence,-.12,.3) and food_days>float(plan.war_food) and bool(plan.offensive):return "declare_war"
	if opinion>float(plan.trade_opinion) and String(relation.get("treaty","none"))=="none":return "open_trade"
	return "goodwill" if opinion>-.5 and opinion<GOODWILL_CEILING and float(plan.personality.empathy)>.65 else ""

## The gift a goodwill mission carries, paid from real stores: the one the
## other people will value most that we can spare, or "" when nothing can be
## spared (then no mission goes). options: CivilizationSystem.diplomatic_gift_options.
## Food goes only from full stores, a material only while three times the
## gift is in store.
static func goodwill_gift(options:Array,food_days:float,plan:Dictionary)->String:
	var best:="";var score:=-INF
	for option:Dictionary in options:
		var amount:=float(option.get("amount",0.0))
		var available:=float(option.get("available",0.0))
		if not bool(option.get("can_send",false)) or amount<=0.0:continue
		if String(option.get("resource",""))=="Food":
			if food_days<GOODWILL_FOOD_DAYS or bool(plan.get("hungry",false)):continue
		elif available<amount*3.0:continue
		var value:=(1.0 if String(option.get("reception",""))=="especially useful" else 0.0)+minf(available/amount,10.0)*.05
		if value>score:score=value;best=String(option.get("resource",""))
	return best

# ------------------------------------------------------------------ Expansion
## Rations for a new town's first weeks, before its own food comes in: what
## SettlementModel.settlement_convoy_quote carries when nobody says otherwise.
const ESTABLISHMENT_DAYS:=45.0
## A people whose expansionist tradition is this strong looks for land every
## month (auto_founding.gd EXPANSIONIST_DRIVE is the same line).
const EXPANSIONIST_DRIVE:=.35
## The longest a council waits between searches for land, in months.
const LONGEST_LOOK_MONTHS:=6

## How often a council looks for land: every month for the boldest temper or
## a people with an expansionist tradition, every second month for a bold one,
## every third for an even temper, every fourth or fifth for the cautious. One
## rule for a computer ruler and for the player's leaders alike.
static func expansion_months(p:Dictionary,drive:float=0.0)->int:
	if drive>=EXPANSIONIST_DRIVE:return 1
	var caution:=(1.0-clampf(float(p.get("risk_tolerance",.5)),0,1))*.6+(1.0-clampf(float(p.get("assertiveness",.5)),0,1))*.4
	return clampi(1+roundi(caution*4.0),1,LONGEST_LOOK_MONTHS)

## Does a council held on `day` look for land, at this interval in months?
static func looks_for_land(day:int,months:int)->bool:
	return posmod(day/30,maxi(1,months))==0

# ---------------------------------------------------------------- Great Works
## Why and how boldly a ruler conceives a wonder. Preferences only: concepts,
## feasibility, costs and outcomes belong to the Great Works engine.
const WONDER_AMBITIONS:=["modest","grand","audacious"]
const WONDER_PAYOFF:={"modest":1.0,"grand":1.8,"audacious":3.0}
const WONDER_MOTIVE_THRESHOLD:=.7
## Purpose words -> [personality axis, trigger that makes the purpose apt].
## Trigger kinds are the Great Works engine's: victory, death, famine,
## anniversary, envy, plenty (see great_works.gd conceive()).
const WONDER_PURPOSE_CUES:=[[["dead","mourn","grief","ancestor"],"empathy","death"],[["bind","unite","tribe","assembly","law"],"discipline","anniversary"],[["flood","water","feed","hunger","famine","harvest","granary","rain"],"empathy","famine"],[["heaven","sky","star","watch","season"],"openness",""],[["awe","rival","might","power","glory"],"assertiveness","envy"],[["knowledge","remember","memory","learn","record","song"],"openness","anniversary"],[["thank","triumph","victory","celebrate"],"assertiveness","victory"],[["defy","god"],"risk_tolerance",""],[["welcome","stranger","trade","market"],"openness","plenty"],[["craft","master"],"discipline","plenty"]]

## How strongly this ruler is moved to build by what its people are living through.
static func wonder_motive(trigger:Dictionary,plan:Dictionary)->float:
	var p:Dictionary=plan.personality
	var open:=float(p.openness);var discipline:=float(p.discipline);var empathy:=float(p.empathy)
	var assertive:=float(p.assertiveness);var risk:=float(p.risk_tolerance)
	match String(trigger.get("kind","")):
		"victory":return assertive*.6+risk*.2+.3
		"death":return empathy*.7+.3
		"famine":return empathy*.5+(1-risk)*.3+.3
		"anniversary":return discipline*.5+open*.2+.3
		# Hearing of another people's work: envy for the proud, awe for the curious.
		"envy":return maxf(assertive*.7+(1-empathy)*.35,open*.55+empathy*.25)
		"plenty":return open*.3+assertive*.3+risk*.3+.15
	return 0.0

static func wonder_purpose_fit(purpose:String,trigger:Dictionary,plan:Dictionary)->float:
	var p:Dictionary=plan.personality
	var text:=purpose.to_lower()
	for cue:Array in WONDER_PURPOSE_CUES:
		for word:String in cue[0]:
			if text.contains(word):
				return float(p.get(String(cue[1]),.5))+(.6 if String(cue[2])==String(trigger.get("kind","")) else 0.0)
	return .5

## Value of one ambition at an assessed feasibility (0..1). Bold rulers weigh
## the payoff heavily and discount risk: they overreach and sometimes fail.
static func wonder_ambition_value(ambition:String,feasibility:float,plan:Dictionary)->float:
	var p:Dictionary=plan.personality
	var risk:=float(p.risk_tolerance);var assertive:=float(p.assertiveness)
	var f:=clampf(feasibility,0,1)
	if f<.45-.4*risk:return -INF
	return pow(float(WONDER_PAYOFF.get(ambition,1.0)),assertive*.5+risk*.5+.2)*pow(maxf(.001,f),1.4-risk)

## Years a ruler lets pass after beginning one work before conceiving another.
static func wonder_interval_days(plan:Dictionary)->int:
	var p:Dictionary=plan.personality
	return roundi(365.0*(12.0-8.0*(float(p.assertiveness)*.5+float(p.risk_tolerance)*.5)))

static func wonder_pace(plan:Dictionary,food_days:float)->String:
	var p:Dictionary=plan.personality
	if bool(plan.get("food_shortage",plan.get("hungry",false))):return "careful"
	if float(p.discipline)>.6 and food_days>90:return "press"
	if float(p.risk_tolerance)>.75 and food_days>60:return "press"
	return "careful"

## Prudent rulers cut their losses on a work their builders no longer believe in;
## reckless ones carry on toward triumph or collapse.
static func wonder_abandon(plan:Dictionary,feasibility:float)->bool:
	return feasibility>=0 and feasibility<.15 and float(plan.personality.risk_tolerance)<.4

## One rule for every people's answer at a great work's stage gates, whoever
## gives it: a computer ruler at once, the player's council when the god has
## given no word (undertaking_system.gd auto_option). The temper moves the
## lines, never the options. facts: enabled (the options the stores allow),
## ample (half the work's materials in store), feasibility (the builders'
## assessed odds), food_days, hierarchy (the people's lived values),
## cohesion, ego (the architect's).
static func works_answer(key:String,facts:Dictionary,p:Dictionary)->String:
	var enabled:Dictionary=facts.get("enabled",{})
	var open:=clampf(float(p.get("openness",.5)),0,1);var empathy:=clampf(float(p.get("empathy",.5)),0,1)
	var assertive:=clampf(float(p.get("assertiveness",.5)),0,1);var risk:=clampf(float(p.get("risk_tolerance",.5)),0,1)
	match key:
		"design":
			# The grander design wants materials to spare and builders who believe
			# in it. The bold believe sooner: assessed odds of 0.57 for the boldest,
			# 0.70 for an even temper, 0.81 for the most cautious.
			var bold:=assertive*.5+risk*.5
			return "grander" if bool(facts.get("ample",false)) and float(facts.get("feasibility",0.0))>=.85-.3*bold else "practical"
		"stores":
			# The stores feed extra crews only when full: 120 days for an even
			# temper, about 95 for the boldest, 143 for the most cautious.
			return "pour" if enabled.has("pour") and float(facts.get("food_days",0.0))>=150.0-60.0*risk else "protect"
		"labor":
			# Only a hard temper levies forced labor, and only from a people that
			# accepts rank and holds together; a gentle one relies on volunteers;
			# the rest pay the crews when they can.
			if assertive*.5+(1.0-empathy)*.5>=.65 and float(facts.get("hierarchy",.5))>=.65 and float(facts.get("cohesion",.5))>=.65:return "levy"
			if enabled.has("paid") and empathy*.6+(1.0-assertive)*.4<.7:return "paid"
			return "volunteers"
		"demand":
			# Honor the architect's demand when the stores allow it and the temper
			# prizes the work's glory, or when refusing would drive a vain architect away.
			if not enabled.has("honor"):return "refuse"
			return "honor" if open*.5+assertive*.5>=.35 or float(facts.get("ego",0.0))>.7 else "refuse"
	return ""

## Envy-driven sabotage: only a proud, callous, reckless ruler even considers it.
static func wonder_sabotage_temper(plan:Dictionary)->bool:
	var p:Dictionary=plan.personality
	return float(p.assertiveness)>.75 and float(p.empathy)<.3 and float(p.risk_tolerance)>.6
