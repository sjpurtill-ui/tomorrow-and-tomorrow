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
	var said:=boast_of(civ_id,String(race[0]))
	if not said.is_empty(): row["said"]=_said_words(said,row,counted)
	return row

## Their claim beside our reading: said plainly, never judged unless our own
## reading clears the whole claim (a known stretch) or falls short of it.
static func _said_words(said:Dictionary,row:Dictionary,counted:bool)->String:
	var when:=_when(int(said.days_ago))
	var claimed:=float(said.claimed)
	var verdict:=""
	if not bool(row.unknown):
		if claimed>float(row.high)*1.15: verdict=" Our watchers think it stretched."
		elif claimed<float(row.low)*0.85: verdict=" Our watchers think it modest."
	return "Their envoy claimed %s, %s.%s" % ["about %s" % _grouped(_round_count(claimed)) if counted else "%d%%" % roundi(claimed*100.0),when,verdict]

static func _when(days:int)->String:
	if days<30: return "this month"
	if days<365: return "%d months ago" % roundi(days/30.0)
	var years:=roundi(days/365.0)
	return "a year ago" if years<=1 else "%d years ago" % years

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


# ----------------------------------------------------------------- boasts
# What a ruler's envoy says of their own people's rank. The words are theirs,
# not the truth: the claim is stretched by the ruler's bent (a proud one
# stretches, a modest one holds back), and our watchers' reading sits beside
# it on the board. Kept in the ruler's own record (ForeignDiplomacy.leader).

const BOAST_KEEP:=6
## How much each bent stretches what is said.
const VANITY:={"Proud guardian":0.5,"Restless visionary":0.35,"Practical organizer":0.1,"Bridge-builder":0.05}
const BLUFFER_VANITY:=0.7

## The boasts an envoy of `civ_id` might make today, as news facts:
## [{w, f:{subject_civ_id, subject_civ_name, fact_kind, fact, boast:{race, claimed, day}}}].
## Seeded from the world, the people and the day, so a load never rerolls them.
static func boast_facts(civ_id:String,day:int)->Array:
	var civ:=ForeignDiplomacy.civilization(civ_id)
	if civ.is_empty(): return []
	var name:=String(civ.get("name",civ_id))
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|boast|%s|%d" % [int(WorldSimulation.state.world_seed),civ_id,day/ESTIMATE_DAYS])
	var vanity:=_vanity(civ_id)
	var stretch:=1.0+vanity*rng.randf_range(0.2,1.0) if vanity>=0.15 else rng.randf_range(0.85,1.0)
	var truth:=Standing.their_true(civ_id)
	var out:Array=[]
	var pop:=maxf(0.0,float(civ.get("population",0.0)))
	if pop>0.0:
		var said:=_round_count(pop*stretch)
		out.append(_boast(civ_id,name,"people","%s's envoy says their people number about %s." % [name,_grouped(said)],pop*stretch,day))
	for race:Array in RACES:
		var key:=String(race[2])
		if key=="" or not truth.has(key): continue
		var claimed:=clampf(float(truth[key])*stretch,0.0,1.0)
		var words:String={"genius":"say they know more than most peoples; that their elders keep more lore than they can tell",
			"splendor":"say they have raised works that travellers cross hills to see",
			"wealth":"say their stores and goods are the envy of the peoples near them"}.get(key,"")
		if words=="" or claimed<0.35: continue
		out.append(_boast(civ_id,name,String(race[0]),"%s's envoy %s." % [name,words],claimed,day))
	return out

static func _boast(civ_id:String,name:String,race:String,text:String,claimed:float,day:int)->Dictionary:
	return {"w":0.9,"f":{"subject_civ_id":civ_id,"subject_civ_name":name,"fact_kind":"boast_"+race,"fact":text,"boast":{"race":race,"claimed":claimed,"day":day,"text":text}}}

static func _vanity(civ_id:String)->float:
	var leader:=ForeignDiplomacy.leader(civ_id)
	var base:float=float(VANITY.get(String(leader.get("temperament","")),0.1))
	var character:Variant=leader.get("character",{})
	if character is Dictionary and String((character as Dictionary).get("trait",""))=="bluffer": base=maxf(base,BLUFFER_VANITY)
	return base

const ESTIMATE_DAYS:=91

## Keeps a boast the envoy made, newest per race (the ruler's own record).
static func remember_boast(civ_id:String,boast:Dictionary)->void:
	var leader:=ForeignDiplomacy.leader(civ_id)
	if leader.is_empty() or boast.is_empty(): return
	var kept:Array=leader.get("boasts",[])
	kept=kept.filter(func(b:Dictionary)->bool:return String(b.get("race",""))!=String(boast.get("race","")))
	kept.append(boast.duplicate())
	while kept.size()>BOAST_KEEP: kept.pop_front()
	leader["boasts"]=kept

## The newest thing their envoy said of one race, {} when nothing: {text,
## claimed, day, years_ago}.
static func boast_of(civ_id:String,race:String)->Dictionary:
	var leader:=ForeignDiplomacy.leader(civ_id)
	for b in leader.get("boasts",[]):
		if b is Dictionary and String((b as Dictionary).get("race",""))==race:
			var out:=(b as Dictionary).duplicate()
			out["days_ago"]=maxi(0,int(WorldSimulation.state.elapsed_days)-int(out.get("day",0)))
			return out
	return {}
