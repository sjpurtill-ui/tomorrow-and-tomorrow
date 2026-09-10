extends RefCounted
const AXES:=["openness","discipline","empathy","assertiveness","risk_tolerance"]

static func generate(rng:RandomNumberGenerator)->Dictionary:
	var result:Dictionary={}
	for axis:String in AXES:result[axis]=rng.randf_range(.12,.92)
	return result

static func foreign(seed_value:int,id:String)->Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value^hash(id+":leader")
	return generate(rng)

static func temperament(p:Dictionary)->String:
	if float(p.empathy)>.65:return "Bridge-builder"
	if float(p.assertiveness)>.65:return "Proud guardian"
	if float(p.openness)>.65:return "Restless visionary"
	return "Practical organizer"

static func agenda(civ:Dictionary,p:Dictionary)->Array[Dictionary]:
	var goals:Array[Dictionary]=[
		{"id":"care","title":"Keep our people fed and healthy","strategy":"sustenance","accord":"exchange","weight":float(p.empathy)},
		{"id":"learning","title":"Bring useful knowledge home","strategy":"inquiry","accord":"exchange","weight":float(p.openness)},
		{"id":"security","title":"Keep our homeland independent","strategy":"fortification","accord":"restraint","weight":float(p.discipline)*.6+(1-float(p.risk_tolerance))*.4},
		{"id":"exchange","title":"Build dependable ties with other peoples","strategy":"commerce","accord":"routes","weight":float(p.empathy)*.55+float(p.openness)*.45},
		{"id":"growth","title":"Make room for the next generation","strategy":"growth","accord":"routes","weight":float(p.discipline)*.45+float(p.assertiveness)*.55}
	]
	var hungry:=float(civ.get("food_days",30))<16 or float(civ.get("food_intake_ratio",1))<.98
	var threatened:=bool(civ.get("at_war",false)) or bool(civ.get("player_relation",{}).get("at_war",false))
	for relation:Dictionary in civ.get("relations",{}).values():threatened=threatened or bool(relation.get("at_war",false))
	for goal:Dictionary in goals:
		if goal.id=="care" and hungry:goal.weight=3.0
		if goal.id=="growth" and float(civ.get("integration_pressure",0))>.12:
			goal.title="Help arriving households settle and belong";goal.accord="restraint";goal.weight=1.4+float(p.empathy)*.5
		if goal.id=="learning" and float(civ.get("cultural_exchange",0))>.02:
			goal.title="Turn foreign knowledge into local skill";goal.weight+=float(p.openness)*.4
		if goal.id=="security" and threatened:goal.weight=2.0
	goals.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.weight)>float(b.weight))
	goals.resize(3)
	for goal:Dictionary in goals:goal.erase("weight")
	return goals
