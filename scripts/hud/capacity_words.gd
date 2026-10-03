extends RefCounted
## CAPACITY WORDS: the people's words for what the twelve capacities are made
## of and for why they moved. The numbers come from the capacity ledger
## (society_model.gd) and its monthly history (capacity_history.gd); this file
## only says them. Changes are told in points of the capacity (a capacity at
## 27% that gains 5 points stands at 32%), never "+0.0".

const EraWords:=preload("res://scripts/hud/era_words.gd")
const History:=preload("res://scripts/capacity_history.gd")

## Each capacity in plain words (the Chronicle's own names for the fields).
static func plain_name(dynamic_id:String)->String:
	var name:=String(preload("res://scripts/chronicle.gd").DOMAIN_NAMES.get(dynamic_id,dynamic_id))
	return name.substr(0,1).to_upper()+name.substr(1)

## The capacity's name as the strengths list shows it.
static func title(dynamic_id:String)->String:
	return dynamic_id.capitalize()

## The parts and inputs of the capacities: [plain name, when it raised the
## capacity, when it lowered it].
const PARTS:={
	"able":["Hands able to work","More hands able to work","Fewer hands able to work"],
	"health":["How healthy people are","Fewer people sick","More people sick"],
	"food":["Food to go round","More food to go round","Less food to go round"],
	"housing":["Roofs for our numbers","More roofs for our numbers","Fewer roofs for our numbers"],
	"cohesion":["Holding together","Holding together better","Pulling apart"],
	"ecology":["Health of the land","The land recovering","The land wearing thin"],
	"security":["Safety from harm","Safer from harm","Less safe from harm"],
	"legitimacy":["Trust in the chiefs","More trust in the chiefs","Less trust in the chiefs"],
	"diet":["Variety of food","More varied meals","Plainer meals"],
	"materials":["Materials at hand","More materials at hand","Fewer materials at hand"],
	"hauling":["Carrying and hauling","More carrying and hauling","Less carrying and hauling"],
	"learning":["What we remember","More remembered","Less remembered"],
	"keepers":["Lore keepers","More lore keepers","Fewer lore keepers"],
	"attention":["Keepers for our questions","Keepers less stretched","Keepers more stretched"],
	"overwork":["Questions at once","Fewer questions than keepers","More questions than keepers"],
	"fields":["Breadth of study","Studying more fields","Studying fewer fields"],
	"stewards":["Stewards","More stewards","Fewer stewards"],
	"works":["Public works","New public works","Public works lost"],
	"treasures":["Treasured works","More treasured works","Fewer treasured works"],
	"homes_quality":["How good our homes are","Better homes","Homes falling into disrepair"],
	"roads":["Roads and paths","Better roads","Roads roughening"],
	"officials":["Office holders","Office holders helping more","Office holders helping less"],
	"values":["What we value","What we value helping more","What we value helping less"],
	"limit":["What our age allows","Our age allows more","Held back by our age"],
	"upkeep":["Feeding full-time lore keepers","Fewer full-time keepers to feed","More full-time keepers to feed"],
	"watch_upkeep":["Keeping a large watch","A smaller watch to keep","A larger watch to keep"],
	"common":["What every people knows","",""],
	"preserved":["What we remember and keep","",""],
	"communication":["Sharing what we know","",""],
	"support":["Stewards and trust","",""],
	"labor":["Hands at work","",""],
	"~":["Smaller changes","Smaller changes","Smaller changes"],
}
## The practice totals: [plain name, when it raised the capacity, when it
## lowered it].
const EFFECTS:={
	"maternal_safety":["Safer births","Safer births","Less safe births"],
	"nutrition_quality":["Ways with food","Better ways with food","Poorer ways with food"],
	"health_protection":["Ways of keeping well","Better ways of keeping well","Ways of keeping well lapsing"],
	"disease_exposure":["Exposure to disease","Less exposure to disease","More exposure to disease"],
	"health_risk":["Risky work","Less risky work","Riskier work"],
	"labor_efficiency":["Ways of working","Better ways of working","Poorer ways of working"],
	"labor_demand":["Work our ways demand","Lighter work","Heavier work"],
	"fatigue":["Weariness","Less weariness","More weariness"],
	"knowledge_preservation":["Ways of keeping lore","Lore kept better","Lore kept less well"],
	"route_speed":["Known paths","Better known paths","Paths less known"],
	"standardization":["Shared measures","More shared measures","Fewer shared measures"],
	"state_capacity":["Ways of organizing","Better organized","Less organized"],
	"institutional_rigidity":["Rigid custom","Less rigid custom","More rigid custom"],
	"tool_quality":["Tools","Better tools","Poorer tools"],
	"task_coordination":["Working together","Working together better","Working together worse"],
	"construction_rate":["Building skill","More building skill","Less building skill"],
	"disaster_resilience":["Built to last","Built to last better","Built less to last"],
	"haul_capacity":["Ways of carrying loads","Better ways of carrying loads","Poorer ways of carrying loads"],
	"storage_loss":["Stores kept from spoiling","Less lost from the stores","More lost from the stores"],
	"ecology_recovery":["Letting the land rest","More rest for the land","Less rest for the land"],
	"ecological_pressure":["Strain on the land","Less strain on the land","More strain on the land"],
	"pollution":["Smoke and waste","Less smoke and waste","More smoke and waste"],
	"legitimacy":["Customs of rule","Stronger customs of rule","Weaker customs of rule"],
	"security_efficiency":["Watch and guard","Better watch and guard","Poorer watch and guard"],
	"warfare_readiness":["Readiness to fight","More ready to fight","Less ready to fight"],
	"cohesion":["Customs that bind us","Stronger customs that bind us","Weaker customs that bind us"],
}
## The offices in plain words.
const OFFICES:={"Steward":"steward","Quartermaster":"keeper of stores","Scholar":"keeper of lore","Marshal":"war leader","Envoy":"envoy","ChiefScout":"chief scout"}
## Hard times without a name of their own.
const HARD_TIMES:={"hunger":"Hunger","drought":"Drought","cold":"A cold year","sickness":"Sickness","stranger":"A strangers' sickness","flood":"A flood","fire":"A fire","thinning":"The land thinning"}


## A change in points of a capacity: "+5", "-2", "+0.4", "+<0.1"; never "+0.0".
static func points(value:float)->String:
	var size:=absf(value)
	var sign:="+" if value>0.0 else "-"
	if size<0.0000001: return "0"
	if size>=0.95: return "%s%d" % [sign,roundi(size)]
	if size>=0.05: return "%s%.1f" % [sign,snappedf(size,0.1)]
	return sign+"<0.1"

## The size of a change without its sign: "5", "0.4", "<0.1".
static func amount(value:float)->String:
	return points(absf(value)).trim_prefix("+")

## A level of a capacity: "27%".
static func percent(value:float)->String:
	return "%d%%" % roundi(clampf(value,0.0,100.0))

## The name of a part, input or practice total, in the people's words.
static func part_name(key:String)->String:
	if key.begins_with("fx:"): return String((EFFECTS.get(key.substr(3),[key.substr(3).replace("_"," ").capitalize()]) as Array)[0])
	return _era(String((PARTS.get(key,[key.capitalize()]) as Array)[0]))

## Why a capacity moved, for one reason: "More carrying and hauling (+6)",
## "Pack animals taken up (+4)", "Held back by our age (-1)".
static func reason(key:String,amount:float)->String:
	return "%s (%s)" % [reason_words(key,amount),points(amount)]

static func reason_words(key:String,amount:float)->String:
	var raised:=amount>=0.0
	var practice:=History.practice_id(key)
	if practice!="" or History._is_practice(key):
		var name:=practice_name(practice)
		match key.substr(0,2):
			"n:": return "%s learned" % name
			"d:": return "%s taken up" % name
			"l:": return "%s practiced less" % name
		return "%s worked %s" % [name,"harder" if raised else "less"]
	var words:Array=EFFECTS.get(key.substr(3),[]) if key.begins_with("fx:") else PARTS.get(key,[])
	if words.size()>=3 and String(words[1 if raised else 2])!="": return _era(String(words[1 if raised else 2]))
	return part_name(key)

static func practice_name(id:String)->String:
	if id=="": return "A practice"
	var definition:=DiscoverySystem.discovery_definition(id)
	var name:=String(definition.get("name",id.replace("_"," ").capitalize()))
	return name.substr(0,1).to_upper()+name.substr(1)

## A stored event code in words: "Raiders carried off 9 days of food".
static func event(code:Array)->String:
	var kind:=String(code[0]) if code.size()>0 else ""
	var a:Variant=code[1] if code.size()>1 else null
	var b:Variant=code[2] if code.size()>2 else null
	match kind:
		"raid": return "Raiders carried off %s" % _food(int(a))
		"war_food": return "War took %s" % _food(int(a))
		"sabotage": return "Saboteurs spoiled %s" % _food(int(a))
		"tribute": return "Tribute cost %s" % _food(int(a))
		"fallen": return "One of ours fell in battle" if int(a)==1 else "%s of ours fell in battle" % EraWords.grouped(int(a))
		"crisis":
			var name:=String(HARD_TIMES.get(String(a),String(a)))
			name=name.substr(0,1).to_upper()+name.substr(1)
			return name if int(b)<=0 else "%s: %s died" % [name,EraWords.grouped(int(b))]
		"decree":
			var decree:=String(GovernmentPolicyCatalog.display_name(String(a)))
			return ("Decree: %s" if int(b)==1 else "Decree ended: %s") % decree
		"official":
			var office:=String(OFFICES.get(String(a),String(a).to_lower()))
			return "No %s now" % office if String(b)=="" else "New %s: %s" % [office,String(b)]
		"built":
			if int(b)<0: return "A public work lost" if int(b)==-1 else "%d public works lost" % -int(b)
			if int(b)<=1: return "%s built" % String(a)
			return "%s and %d more built" % [String(a),int(b)-1]
	return kind.capitalize()

static func _food(days:int)->String:
	if days>=2: return "%d days of food" % days
	return "a day of food" if days==1 else "some food"

## Era words inside a phrase: chiefs, then rulers, then government; lore
## keepers, then scholars.
static func _era(text:String)->String:
	match EraWords.stage():
		"lettered": return text.replace("the chiefs","the rulers")
		"reckoned": return text.replace("the chiefs","government").replace("Lore keepers","Scholars").replace("lore keepers","scholars").replace("Keepers","Scholars").replace("keepers","scholars")
	return text

## One told change as a row's name: the two largest reasons.
## A told change that took more than a month to come about is a run.
const RUN_DAYS:=45

static func is_run(change:Dictionary)->bool:
	return int(change.get("day",0))-int(change.get("since",0))>=RUN_DAYS

## How long a run took, as the Chronicle counts time: "over a season",
## "over three seasons", "over a year", "over three years".
static func over(days:int)->String:
	var seasons:=maxi(1,roundi(float(days)/91.3))
	if seasons<4: return "over a season" if seasons==1 else "over %s seasons" % EraWords.count_word(seasons)
	var years:=maxi(1,roundi(float(days)/365.25))
	return "over a year" if years==1 else "over %s years" % EraWords.count_word(years)

## One told change as a row's name. A month's change: its two largest reasons,
## "More carrying and hauling (+6), Pack animals taken up (+1)". A run: its
## main cause, what that cause added in all, and how long it took, "More
## carrying and hauling: +6 over three years".
static func change_name(change:Dictionary)->String:
	if is_run(change):
		var span:=int(change.get("day",0))-int(change.get("since",0))
		for reason_pair:Array in change.get("reasons",[]):
			if String(reason_pair[0])=="~": continue
			return "%s: %s %s" % [reason_words(String(reason_pair[0]),float(reason_pair[1])),points(float(reason_pair[1])),over(span)]
		return "Many small changes: %s %s" % [points(float(change.get("change",0.0))),over(span)]
	var parts:PackedStringArray=[]
	for reason_pair:Array in change.get("reasons",[]):
		var key:=String(reason_pair[0])
		if key=="~": continue
		var text:=reason(key,float(reason_pair[1]))
		if not parts.is_empty() and not _keeps_capital(key): text=text.substr(0,1).to_lower()+text.substr(1)
		parts.append(text)
		if parts.size()>=2: break
	if parts.is_empty(): return "Many small changes (%s)" % points(float(change.get("change",0.0)))
	return ", ".join(parts)

## When a told change came about: its season, or where a run began and ended.
static func change_when(change:Dictionary)->String:
	if is_run(change): return "%s to %s" % [EraWords.when(int(change.get("since",0))),EraWords.when(int(change.get("day",0)))]
	return EraWords.when(int(change.get("day",0)))

## How many of its reasons a change's name already says.
static func named_reasons(change:Dictionary)->int:
	return 1 if is_run(change) else 2

## A practice's own name keeps its capital letter inside a sentence.
static func _keeps_capital(key:String)->bool:
	return History._is_practice(key)

## One told change as a sentence, for its tooltip.
static func change_sentence(title_name:String,change:Dictionary)->String:
	var sentence:="%s went from %s to %s between %s and %s." % [title_name,percent(float(change.from)),percent(float(change.to)),EraWords.when(int(change.since)),EraWords.when(int(change.day))]
	var said:PackedStringArray=[]
	for reason_pair:Array in change.get("reasons",[]):
		said.append(reason(String(reason_pair[0]),float(reason_pair[1])) if String(reason_pair[0])!="~" else "smaller changes together (%s)" % points(float(reason_pair[1])))
	if not said.is_empty(): sentence+=" What moved it: %s." % "; ".join(said)
	var told:PackedStringArray=[]
	for code:Array in change.get("events",[]): told.append(event(code))
	if not told.is_empty(): sentence+=" In that time: %s." % "; ".join(told)
	return sentence
