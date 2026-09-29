extends RefCounted
const AXES:=["openness","discipline","empathy","assertiveness","risk_tolerance"]
const Culture:=preload("res://scripts/cultural_inheritance.gd")

## Which way each of a people's ambitions (people_direction.gd AMBITIONS)
## leans a temper, on the five axes of a ruler's personality. One table, read
## both ways: a ruler takes up the ambition that best fits it
## (civilization_strategy.gd preferences), and a people's own council, which
## has no ruler of its own, takes its temper from the ambitions the people
## have taken up (temper_of_culture). A negative weight reads the other end
## of the axis: a ruler with 0.3 risk tolerance fits "-0.24" as 0.7 x 0.24.
## Every ambition's weights add up to one, so fits compare fairly, and across
## rulers drawn at random each ambition is chosen by between 2 and 10 in 100
## (once other peoples are known: civilization_strategy.gd preferences).
const AMBITION_TEMPER:={
	"horizons":{"openness":.69,"risk_tolerance":.31},
	"makers":{"discipline":.5,"openness":.5},
	"gathering":{"empathy":.5,"assertiveness":-.5},
	"inquiry":{"openness":.76,"risk_tolerance":-.24},
	"military":{"assertiveness":.65,"discipline":.35},
	"sustenance":{"empathy":.49,"risk_tolerance":-.51},
	"wellbeing":{"empathy":.76,"assertiveness":-.24},
	"commerce":{"openness":.47,"empathy":.41,"risk_tolerance":.12},
	"expansion":{"risk_tolerance":.56,"discipline":-.28,"assertiveness":.16},
	"dominion":{"assertiveness":.63,"risk_tolerance":.2,"empathy":-.17},
	"purity":{"openness":-.76,"empathy":-.14,"assertiveness":.1},
	"dynasty":{"discipline":.57,"openness":-.23,"assertiveness":.2},
	"retribution":{"empathy":-.55,"risk_tolerance":-.29,"assertiveness":.16},
	"orthodoxy":{"openness":-.71,"discipline":.29},
}
## How far a people's ambitions move its council's temper from even (0.5).
const CULTURE_TEMPER_SPREAD:=0.6

static func generate(rng:RandomNumberGenerator)->Dictionary:
	var result:Dictionary={}
	for axis:String in AXES:result[axis]=rng.randf_range(.12,.92)
	return result

static func foreign(seed_value:int,id:String)->Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value^hash(id+":leader")
	return generate(rng)

## How well an ambition suits a temper, 0..1.
static func ambition_fit(ambition:String,p:Dictionary)->float:
	var fit:=0.0
	var weights:Dictionary=AMBITION_TEMPER.get(ambition,{})
	for axis:String in weights:
		var weight:=float(weights[axis])
		var value:=clampf(float(p.get(axis,.5)),0.0,1.0)
		fit+=weight*value if weight>=0.0 else -weight*(1.0-value)
	return fit

## The temper of a people's own council (the player's leaders, who have no
## ruler of their own): the people's, read from the ambitions they have taken
## up, the recent ones weighing most (cultural_inheritance.choice_weights).
## A people with no ambition yet is even-tempered: 0.5 on every axis.
static func temper_of_culture(choice_weights:Dictionary)->Dictionary:
	var total:=0.0
	for weight in choice_weights.values():total+=maxf(0.0,float(weight))
	var result:Dictionary={}
	for axis:String in AXES:
		var lean:=0.0
		if total>0.0:
			for choice in choice_weights:
				lean+=float((AMBITION_TEMPER.get(String(choice),{}) as Dictionary).get(axis,0.0))*maxf(0.0,float(choice_weights[choice]))/total
		result[axis]=clampf(.5+lean*CULTURE_TEMPER_SPREAD,.12,.92)
	return result

## The temper that guides an owner's automated leaders: a computer ruler's own
## personality; for the player (or a people no computer rules) its council's,
## taken from the people's ambitions. The same rules read either one.
static func of_owner(owner:String)->Dictionary:
	var actor:Dictionary=WorldSimulation.actors.get(owner,{})
	if owner!="player" and (actor.is_empty() or String(actor.get("controller",""))=="ai"):
		return foreign(int(WorldSimulation.state.world_seed),owner)
	return WorldSimulation.scoped(owner,func()->Dictionary:
		WorldSimulation.direction._ensure_cultural_memory()
		return temper_of_culture(Culture.choice_weights(WorldSimulation.direction.cultural_memory,int(WorldSimulation.state.elapsed_days))))

## The traits other systems read from a people (border tension, raids, rival
## wars, peace terms, occupation rule), drawn from its leader's character in
## their old ranges, so one character drives everything: aggression 0.18-0.88,
## diplomacy 0.22-0.90, adaptability 0.30-0.90.
static func character_traits(p:Dictionary)->Dictionary:
	var open:=clampf(float(p.get("openness",.5)),0,1);var empathy:=clampf(float(p.get("empathy",.5)),0,1)
	var assertive:=clampf(float(p.get("assertiveness",.5)),0,1);var risk:=clampf(float(p.get("risk_tolerance",.5)),0,1)
	var aggression:=assertive*.5+risk*.3+(1.0-empathy)*.2
	var diplomacy:=empathy*.45+open*.4+(1.0-assertive)*.15
	var adaptability:=open*.6+risk*.4
	return {"aggression":lerpf(.18,.88,clampf((aggression-.12)/.8,0,1)),"diplomacy":lerpf(.22,.90,clampf((diplomacy-.12)/.8,0,1)),"adaptability":lerpf(.30,.90,clampf((adaptability-.12)/.8,0,1))}

static func temperament(p:Dictionary)->String:
	if float(p.empathy)>.65:return "Bridge-builder"
	if float(p.assertiveness)>.65:return "Proud guardian"
	if float(p.openness)>.65:return "Restless visionary"
	return "Practical organizer"

static func food_constraints(situation:Dictionary)->Dictionary:
	var intake:=clampf(float(situation.get("food_intake_ratio",1)),0,1)
	var scarce:=float(situation.get("food_days",30))<16
	var hungry:=scarce or intake<.98
	var demand:=maxf(0,float(situation.get("food_consumption",0)))
	var transport_gap:=maxf(0,float(situation.get("army_provisions_required",0)))*(1-clampf(float(situation.get("army_provision_delivery_ratio",1)),0,1))
	# Only measured transport exclusion can explain away a supply deficit.
	# Missing diagnostic fields retain the existing conservative hunger response.
	var delivery_share:=minf(1-intake,transport_gap/demand) if demand>0 else 0.0
	return {"hungry":hungry,"food_shortage":scarce or intake+delivery_share<.98,"delivery_shortage":hungry and delivery_share>0.0}

static func agenda(civ:Dictionary,p:Dictionary)->Array[Dictionary]:
	var goals:Array[Dictionary]=[
		{"id":"care","title":"Keep our people fed and healthy","strategy":"sustenance","accord":"exchange","weight":float(p.empathy)},
		{"id":"learning","title":"Bring useful knowledge home","strategy":"inquiry","accord":"exchange","weight":float(p.openness)},
		{"id":"security","title":"Keep our homeland independent","strategy":"fortification","accord":"restraint","weight":float(p.discipline)*.6+(1-float(p.risk_tolerance))*.4},
		{"id":"exchange","title":"Build dependable ties with other peoples","strategy":"commerce","accord":"routes","weight":float(p.empathy)*.55+float(p.openness)*.45},
		{"id":"growth","title":"Make room for the next generation","strategy":"growth","accord":"routes","weight":float(p.discipline)*.45+float(p.assertiveness)*.55}
	]
	var constraints:=food_constraints(civ)
	var hungry:=bool(constraints.hungry)
	var threatened:=bool(civ.get("at_war",false)) or bool(civ.get("player_relation",{}).get("at_war",false))
	for relation:Dictionary in civ.get("relations",{}).values():threatened=threatened or bool(relation.get("at_war",false))
	for goal:Dictionary in goals:
		if goal.id=="care" and hungry:
			goal.weight=3.0
			if not constraints.food_shortage:
				goal.title="Deliver available food to people waiting for rations";goal.strategy="commerce";goal.accord="routes"
		if goal.id=="growth" and float(civ.get("integration_pressure",0))>.12:
			goal.title="Help arriving households settle and belong";goal.accord="restraint";goal.weight=1.4+float(p.empathy)*.5
		if goal.id=="learning" and float(civ.get("cultural_exchange",0))>.02:
			goal.title="Turn foreign knowledge into local skill";goal.weight+=float(p.openness)*.4
		if goal.id=="security" and threatened:goal.weight=2.0
	goals.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.weight)>float(b.weight))
	goals.resize(3)
	for goal:Dictionary in goals:goal.erase("weight")
	return goals
