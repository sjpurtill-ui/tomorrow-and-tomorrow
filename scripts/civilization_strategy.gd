extends RefCounted
## A ruler's preferences choose ordinary orders. These are not simulation bonuses.
const PERSONALITY=preload("res://scripts/leader_personality.gd")
const DOMAINS:=["demography","nutrition","health","labor","knowledge","production","infrastructure","logistics","ecology","institutions","security","culture"]

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
	var ambitions:={"horizons":open*.65+risk*.35,"makers":discipline*.55+open*.45,"gathering":empathy*.6+(1-assertive)*.4,"inquiry":open*.85+(1-risk)*.15,"military":assertive*.65+discipline*.35,"sustenance":empathy*.4+(1-risk)*.6,"wellbeing":empathy*.85+(1-assertive)*.15,"commerce":open*.45+empathy*.35+risk*.2}
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
		"capacity_share":clampf(.3+assertive*.45+discipline*.25+(.2 if war else 0),.15,1),"deploy_share":.35+assertive*.25+risk*.2,"expansion_food":30+(1-risk)*60+empathy*15,"settle_distance":12+36*risk,
		"scout_days":180 if open>.75 and risk>.65 else (90 if open>.5 else 30),"scout_food":22+(1-risk)*30,
		"war_opinion":-.85+assertive*.35+risk*.2-empathy*.15,"war_food":30+(1-risk)*50,
		"trade_opinion":.25-empathy*.35-open*.15,"peace_food":12+empathy*18+(1-risk)*12,
		"offensive":assertive*.55+risk*.45>empathy*.3+(1-risk)*.35+.15}

static func research_plan(weights:Dictionary,budget:int)->Dictionary:
	var result:Dictionary={}
	for domain:String in DOMAINS:result[domain]=0
	# Preserve the existing emphasis budget, including a deliberately zero budget.
	for _point in clampi(budget,0,DOMAINS.size()*12):
		var best:="";var score:=-INF
		for domain:String in DOMAINS:
			if int(result[domain])>=12:continue
			var value:=float(weights.get(domain,.1))/float(int(result[domain])+1)
			if value>score:best=domain;score=value
		if best!="":result[best]+=1
	return result

static func unit_score(definition:Dictionary,plan:Dictionary)->float:
	var p:Dictionary=plan.personality
	var preference:float={"force_generation":.5+(1-float(p.risk_tolerance))*.5,"heavy_infantry":float(p.discipline),"missile_infantry":float(p.openness),"mounted":float(p.risk_tolerance)*.6+float(p.assertiveness)*.4,"protection":1-float(p.risk_tolerance),"reconnaissance":float(p.openness),"siege_fires":float(p.assertiveness)*.6+float(p.discipline)*.4,"specialist_infantry":float(p.openness)*.6+float(p.risk_tolerance)*.4}.get(String(definition.get("branch","")),.5)
	# Capability matters, but longest training time is not a universal doctrine.
	return log(1+float(definition.get("training_days",7)))*(.3+float(p.openness)*.3)+preference*3.0

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

## A known deterring Great Work (e.g. Crown of the Ridge) lowers the opinion at
## which this ruler would start a war against its holder; it never forbids war.
static func diplomatic_action(relation:Dictionary,plan:Dictionary,food_days:float,deterrence:float=0.0)->String:
	if bool(relation.get("at_war",false)):
		return "seek_peace" if food_days<float(plan.peace_food) else ""
	var opinion:=float(relation.get("opinion",0))
	if opinion<float(plan.war_opinion)-clampf(deterrence,0,.3) and food_days>float(plan.war_food) and bool(plan.offensive):return "declare_war"
	if opinion>float(plan.trade_opinion) and String(relation.get("treaty","none"))=="none":return "open_trade"
	return "goodwill" if opinion>-.5 and float(plan.personality.empathy)>.65 else ""

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

## Envy-driven sabotage: only a proud, callous, reckless ruler even considers it.
static func wonder_sabotage_temper(plan:Dictionary)->bool:
	var p:Dictionary=plan.personality
	return float(p.assertiveness)>.75 and float(p.empathy)<.3 and float(p.risk_tolerance)>.6
