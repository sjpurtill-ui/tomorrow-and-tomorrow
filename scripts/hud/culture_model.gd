extends RefCounted
## WHAT OUR CULTURE DOES: the Culture screen's data, every line read from the
## engine (no number here is made up for the page).
##
## Culture in this game is four things, in order of weight:
##   1. the COURSE the people follow (cultural memory: this century's choice
##      counts most, older ones fade with a sixty-year half-life): it leans
##      the work and the research and carries real gains and costs
##      (ambition_effects.gd, PeopleDirection.research_multiplier);
##   2. the VALUES they live by (societal_values_model.gd): ten axes, lived and
##      official. How far the official sits from the lived sets how well the
##      people hold together (cohesion, legitimacy, institutions); the lived
##      values themselves speed or slow learning, new ways, trade and safety;
##   3. how our own LEADERS behave: the people's tendency read from the values
##      (leader_personality.from_values) lays the daily work, the research and
##      the pace of growth wherever the god does not;
##   4. how OTHERS are drawn to us: allure (artifact_culture.gd) warms foreign
##      rulers, draws settlers and visitors; newcomers not yet settled cost
##      cohesion (society_exchange.gd pressure).
## The LEDGER adds 1 and 2 into what culture does to the realm right now.

const ValuesModel:=preload("res://scripts/societal_values_model.gd")
const Ambition:=preload("res://scripts/ambition_effects.gd")
const Leader:=preload("res://scripts/leader_personality.gd")
const WorkPaths:=preload("res://scripts/work_paths.gd")
const Culture:=preload("res://scripts/artifact_culture.gd")
const Exchange:=preload("res://scripts/society_exchange.gd")

## The ledger's rows: [id, words, course lever, values effect]. A course lever
## or a values effect of "" has no part in that row.
const LEDGER:=[
	["cohesion","How close our people hold","cohesion_target","cohesion"],
	["legitimacy","Trust in those who rule","","legitimacy"],
	["institutions","How well our institutions work","","institutions"],
	["knowledge","Learning","knowledge_gain","knowledge"],
	["adoption","How fast new ways spread","adoption_rate","adoption"],
	["trade","Trade","trade_access","trade"],
	["security","Safety at home","security_target","security"],
	["food","Food from every field and hunt","food_yield",""],
	["health","Health","health_target",""],
	["births","Births","conception_support",""],
	["building","Building","construction_output",""],
	["resources","Stone, ore and timber won","resource_output",""],
	["work","Work done","labor_multiplier",""],
	["carrying","Carrying and roads","logistics_target",""],
	["drill","Drill","training_rate",""],
	["command","Our leaders' command","command_development",""],
	["surveying","Surveying","survey_output",""],
	["reach","How far our land reaches","realm_reach",""],
	["scouting","How fast our known country grows","scout_reach",""],
]

## The five sides of the people's tendency, and what each makes our leaders do.
const TENDENCY:=[
	["openness","Open to the new","take up new ways, welcome strangers, try what is untried"],
	["discipline","Bound by duty","hold to plans and shared work, keep order"],
	["empathy","Caring","spare the weak, share the stores, settle wrongs gently"],
	["assertiveness","Commanding","rank and command, press their claims"],
	["risk_tolerance","Daring","dare the untried, spend the land for growth"],
]

static func snapshot()->Dictionary:
	var state=WorldSimulation.state
	var values:Dictionary=state.societal_values if state.societal_values is Dictionary else {}
	var identity:=ValuesModel.identity_snapshot(values)
	return {"identity":identity,"course":course(),"ledger":ledger(values),"values":value_rows(values),
		"alignment":alignment(values,identity),"leaders":leaders(values),"others":others()}

## The course: this century's, and every remembered course by its share now.
static func course()->Dictionary:
	var direction=WorldSimulation.direction
	var current:=String(direction.ambition) if direction!=null else ""
	var shares:=Ambition.shares_today()
	var remembered:Array=[]
	for id in shares:
		var spec:Dictionary=direction.AMBITIONS.get(String(id),{}) if direction!=null else {}
		remembered.append({"id":String(id),"name":String(spec.get("name",String(id).capitalize())),"share":float(shares[id]),"current":String(id)==current,"does":Ambition.describe(String(id))})
	remembered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.share)>float(b.share))
	var research:Array=[]
	if direction!=null:
		for domain in ["nutrition","health","knowledge","production","infrastructure","logistics","ecology","institutions","culture","security","demography","labor"]:
			var m:=float(direction.research_multiplier(domain))
			if absf(m-1.0)>=0.005: research.append({"domain":domain,"multiplier":m})
	research.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.multiplier)>float(b.multiplier))
	var spec_now:Dictionary=direction.AMBITIONS.get(current,{}) if direction!=null else {}
	return {"current":current,"name":String(spec_now.get("name","No course chosen yet")),"vision":String(spec_now.get("vision","")),"remembered":remembered,"research":research}

## What culture does to the realm now: each row, from the course and from the
## lived values, and their sum (fractions of the row's own target).
static func ledger(values:Dictionary)->Array:
	var out:Array=[]
	for row:Array in LEDGER:
		var from_course:=Ambition.effect(String(row[2])) if String(row[2])!="" else 0.0
		var from_values:=ValuesModel.simulation_effect(values,String(row[3])) if String(row[3])!="" else 0.0
		if absf(from_course)<0.004 and absf(from_values)<0.004: continue
		out.append({"id":String(row[0]),"label":String(row[1]),"course":from_course,"values":from_values,"total":from_course+from_values})
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return absf(float(a.total))>absf(float(b.total)))
	return out

## The ten values, lived and official, with how far apart they stand.
static func value_rows(values:Dictionary)->Array:
	var lived:Dictionary=values.get("lived",{})
	var official:Dictionary=values.get("official",{})
	var out:Array=[]
	for axis in ValuesModel.VALUE_ORDER:
		var d:Dictionary=ValuesModel.VALUE_DEFINITIONS[axis]
		var l:=clampf(float(lived.get(axis,0.5)),0.0,1.0)
		var o:=clampf(float(official.get(axis,l)),0.0,1.0)
		out.append({"axis":axis,"name":String(d.name).capitalize(),"low":String(d.low).capitalize(),"high":String(d.high).capitalize(),"meaning":String(d.meaning),
			"lived":l,"official":o,"gap":absf(l-o)})
	return out

## How well what the people live by matches what is upheld: the engine's
## alignment and what it does to cohesion, legitimacy and institutions.
static func alignment(values:Dictionary,identity:Dictionary)->Dictionary:
	var widest:Dictionary={}
	for row:Dictionary in value_rows(values):
		if widest.is_empty() or float(row.gap)>float(widest.gap): widest=row
	return {"alignment":float(identity.get("alignment",0.5)),"tension":float(identity.get("tension",0.0)),
		"cohesion":ValuesModel.simulation_effect(values,"cohesion"),"legitimacy":ValuesModel.simulation_effect(values,"legitimacy"),"institutions":ValuesModel.simulation_effect(values,"institutions"),
		"widest":widest}

## How our own leaders behave: the people's tendency, and the work it leans.
static func leaders(values:Dictionary)->Dictionary:
	var tendency:=Leader.from_values(values)
	var sides:Array=[]
	for row:Array in TENDENCY:
		sides.append({"id":String(row[0]),"name":String(row[1]),"means":String(row[2]),"value":float(tendency.get(String(row[0]),0.5))})
	var line:=WorkPaths.leaders_line()
	return {"sides":sides,"work":String(line.get("text","")),"work_tip":String(line.get("tip","")),"temperament":Leader.temperament(tendency)}

## How others are drawn to us, and what newcomers cost.
static func others()->Dictionary:
	var report:=Culture.allure_report(true)
	var pressure:=Exchange.pressure()
	return {"allure":float(report.get("allure",0.0)),"label":String(report.get("label","")),"parts":report.get("breakdown",[]),"effects":report.get("effects",[]),
		"unsettled":float(pressure.get("unsettled",0.0)),"integration_cost":float(pressure.get("cohesion_cost",0.0))}

## Signed percent words: "+5%", "−3%", "+0.4%".
static func pct(x:float)->String:
	var v:=x*100.0
	var sign:="+" if v>=0.0 else "−"
	if absf(v)<1.0: return "%s%.1f%%" % [sign,absf(v)]
	return "%s%d%%" % [sign,roundi(absf(v))]
