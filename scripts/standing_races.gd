extends RefCounted
## WHO LEADS: the four plain races between peoples (most people, most
## learning, greatest works, most wealth), each with every people we know laid
## in order. A standing, never a finish line: nothing here ends anything.
##
## Ours are read exactly. Theirs come through our watchers' estimate
## (Standing.estimate): a band that narrows as envoys, scouts and years teach
## us more, and a people we know too little of is "unknown", not a number. So
## the board is as clear as our knowledge of them and no clearer.

const Standing:=preload("res://scripts/standing.gd")
const Exchange:=preload("res://scripts/society_exchange.gd")

## [id, race, strength it reads ("" = head count), what it asks of us]
const RACES:=[
	["people","Most people","","hearths, food and years of peace"],
	["learning","Most learning","genius","research, scholars and food for them"],
	["works","Greatest works","splendor","builders, materials and years"],
	["wealth","Most wealth","wealth","makers' hands and materials"],
]

## Our row against every people we know: [{id, race, ask, rows:[{civ_id, name,
## ours, value, low, high, unknown, text}], standing (words)}], rows in order,
## the best first and the unknown last. `our` is Standing.strengths().
static func races(our:Dictionary,names:Dictionary)->Array:
	var out:Array=[]
	var known:Array=_known_peoples()
	for race:Array in RACES:
		var rows:Array=[_ours(race,our)]
		for civ_id:String in known: rows.append(_theirs(race,civ_id,String(names.get(civ_id,civ_id))))
		rows.sort_custom(_before)
		out.append({"id":String(race[0]),"race":String(race[1]),"ask":String(race[3]),"rows":rows,"standing":_standing(rows)})
	return out

static func _known_peoples()->Array:
	var out:Array=[]
	if String(WorldSimulation.actor_id)!="player": return out
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if not bool(civ.get("alive",true)): continue
		var relation:Dictionary=civ.get("player_relation",{})
		if int(relation.get("contact_level",0))>=1: out.append(String(civ.id))
	return out

static func _ours(race:Array,our:Dictionary)->Dictionary:
	var value:float
	if String(race[2])=="": value=maxf(0.0,float(WorldSimulation.state.population_exact))
	else: value=float((our.get(String(race[2]),{}) as Dictionary).get("value",0.5))
	return {"civ_id":"player","name":"Us","ours":true,"value":value,"low":value,"high":value,"unknown":false,"text":("about %s people" % _grouped(_round_count(value))) if String(race[2])=="" else _words(false,value,value,value,true)}

static func _theirs(race:Array,civ_id:String,name:String)->Dictionary:
	var counted:=String(race[2])==""
	var est:Dictionary
	if counted:
		var state:Variant=Exchange.owner_state(civ_id)
		est=Standing.estimate(civ_id,"population",maxf(0.0,float(state.population_exact)) if state!=null else 0.0,true)
	else:
		var strengths:=Standing.their_strengths(civ_id)
		est=strengths.get(String(race[2]),{"unknown":true,"value":-1.0,"low":-1.0,"high":-1.0,"exact":false})
	var unknown:=bool(est.get("unknown",false)) or float(est.get("value",-1.0))<0.0
	var value:=float(est.get("value",-1.0))
	var low:=float(est.get("low",value))
	var high:=float(est.get("high",value))
	var row:={"civ_id":civ_id,"name":name,"ours":false,"value":value,"low":low,"high":high,"unknown":unknown,"exact":bool(est.get("exact",false)),
		"sure":Standing.certainty(civ_id)}
	row["text"]="unknown: we have not learned enough of them" if unknown else _words(counted,value,low,high,bool(est.get("exact",false)))
	return row

static func _words(counted:bool,value:float,low:float,high:float,exact:bool)->String:
	if counted:
		if exact: return "%s people" % _grouped(roundi(value))
		return "about %s people (%s to %s)" % [_grouped(_round_count(value)),_grouped(_round_count(low)),_grouped(_round_count(high))]
	if exact: return "%d%%" % roundi(value*100.0)
	return "about %d%% (%d to %d)" % [roundi(value*100.0),roundi(low*100.0),roundi(high*100.0)]

## A head count rounded to what a watcher could say: two figures.
static func _round_count(value:float)->int:
	if value<20.0: return roundi(value)
	var step:=pow(10.0,floor(log(value)/log(10.0))-1.0)
	return roundi(value/step)*int(step)

static func _grouped(value:int)->String:
	var digits:=str(absi(value))
	var out:=""
	for index in digits.length():
		if index>0 and (digits.length()-index)%3==0: out+=","
		out+=digits[index]
	return out

## Known rows by value, best first; the unknown after them.
static func _before(a:Dictionary,b:Dictionary)->bool:
	if bool(a.unknown)!=bool(b.unknown): return not bool(a.unknown)
	if is_equal_approx(float(a.value),float(b.value)): return bool(a.ours)
	return float(a.value)>float(b.value)

## Where we stand in plain words, honest about the band: "ahead" only when our
## value clears every known rival's whole band, "behind" only when a rival's
## whole band clears ours, else "close".
static func _standing(rows:Array)->String:
	var ours:Dictionary={}
	for row:Dictionary in rows:
		if bool(row.ours): ours=row
	var ahead:=0
	var behind:=0
	var close:=0
	var rivals:=0
	for row:Dictionary in rows:
		if bool(row.ours) or bool(row.unknown): continue
		rivals+=1
		if float(ours.value)>float(row.high): ahead+=1
		elif float(ours.value)<float(row.low): behind+=1
		else: close+=1
	if rivals==0: return "We have no one to measure ourselves against yet."
	if behind==0 and close==0: return "We lead every people we can measure."
	if behind==0: return "We lead, but %s %s close behind or level." % [_count_word(close),"is" if close==1 else "are"]
	if ahead==0 and close==0: return "We trail every people we can measure."
	return "%s %s ahead of us." % [_count_word(behind),"is" if behind==1 else "are"]

static func _count_word(n:int)->String:
	return {1:"One people",2:"Two peoples",3:"Three peoples"}.get(n,"%d peoples" % n)
