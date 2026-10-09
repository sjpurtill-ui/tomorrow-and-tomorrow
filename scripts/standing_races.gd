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

const Culture:=preload("res://scripts/artifact_culture.gd")

## [id, race, what is counted, what it asks of us]. Every race is a plain
## count a watcher could carry home: heads, practices, great works, goods.
const RACES:=[
	["people","Most people","people","hearths, food and years of peace"],
	["learning","Most learning","practices known","research, scholars and food for them"],
	["works","Greatest works","great works standing","builders, materials and years"],
	["wealth","Most wealth","goods held","makers' hands and materials"],
]

## Our row against every people we know: [{id, race, unit, ask, rows:[{civ_id,
## name, ours, value, low, high, unknown, text, said}], standing (words)}],
## rows in order, the best first and the unknown last.
static func races(_our:Dictionary,names:Dictionary)->Array:
	var out:Array=[]
	var known:Array=_known_peoples()
	var ours:=measures()
	for race:Array in RACES:
		var id:=String(race[0])
		var value:=float(ours.get(id,0.0))
		var rows:Array=[{"civ_id":"player","name":"Us","ours":true,"value":value,"low":value,"high":value,"unknown":false,"text":_words(id,value,value,value,true)}]
		for civ_id:String in known: rows.append(_theirs(id,civ_id,String(names.get(civ_id,_civ_name(civ_id)))))
		rows.sort_custom(_before)
		out.append({"id":id,"race":String(race[1]),"unit":String(race[2]),"ask":String(race[3]),"rows":rows,"standing":_standing(rows)})
	return out

## The four counts of the people in scope: {people, learning, works, wealth}.
## Read only.
static func measures()->Dictionary:
	var s=WorldSimulation.state
	var report:=Culture.allure_report(false)
	return {"people":maxf(0.0,float(s.population_exact)),"learning":float((s.known_discoveries as Array).size()),
		"works":float(report.get("works_standing",0)),"wealth":maxf(0.0,float(Standing.wealth_held().get("worth",0.0)))}

## Another people's four counts, read in their own scope (as Standing.their_true
## reads their strengths); {} when the world does not simulate them. One
## reading a day.
static func their_measures(civ_id:String)->Dictionary:
	var owner:=Exchange.owner_id(civ_id)
	if owner=="player" or not WorldSimulation.actors.has(owner): return {}
	var key:="%s|%d" % [owner,int(WorldSimulation.state.elapsed_days)]
	if _cache.has(key): return _cache[key]
	var read:Variant=WorldSimulation.scoped(owner,func()->Dictionary: return measures())
	var out:Dictionary=read if read is Dictionary else {}
	if _cache.size()>=32: _cache.clear()
	_cache[key]=out
	return out
static var _cache:Dictionary={}

static func _known_peoples()->Array:
	var out:Array=[]
	if String(WorldSimulation.actor_id)!="player": return out
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if not bool(civ.get("alive",true)): continue
		var relation:Dictionary=civ.get("player_relation",{})
		if int(relation.get("contact_level",0))>=1: out.append(String(civ.id))
	return out

## A people's own name, never its internal id: the board's name list covers
## only peoples it can see in full, but every people we have met is raced.
static func _civ_name(civ_id:String)->String:
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if String(civ.get("id",""))==civ_id and String(civ.get("name",""))!="": return String(civ.name)
	return "A people we have met"

static func _theirs(id:String,civ_id:String,name:String)->Dictionary:
	var truth:=their_measures(civ_id)
	var est:Dictionary={"unknown":true,"value":-1.0}
	if truth.has(id): est=Standing.estimate(civ_id,"race_"+id,float(truth[id]),true)
	var unknown:=bool(est.get("unknown",false)) or float(est.get("value",-1.0))<0.0
	var value:=float(est.get("value",-1.0))
	var low:=float(est.get("low",value))
	var high:=float(est.get("high",value))
	var row:={"civ_id":civ_id,"name":name,"ours":false,"value":value,"low":low,"high":high,"unknown":unknown,"exact":bool(est.get("exact",false)),
		"sure":Standing.certainty(civ_id)}
	row["text"]="unknown: we have not learned enough of them" if unknown else _words(id,value,low,high,bool(est.get("exact",false)))
	# Where the reading comes from: our eyes among them, and for how long.
	var net:Dictionary=preload("res://scripts/covert_ops.gd").network(civ_id)
	if int(net.eyes)>0 and not unknown:
		row["source"]="from our %s among them, %s" % [preload("res://scripts/eyes_corps.gd").word("eyes"),_years_words(float(net.years))]
		row["network"]=float(net.strength)
	var said:=boast_of(civ_id,id)
	if not said.is_empty(): row["said"]=_said_words(id,said,row)
	return row

static func _years_words(years:float)->String:
	if years<1.0: return "under a year"
	var n:=roundi(years)
	return "a year" if n==1 else "%d years" % n

## Their claim beside our reading: said plainly, never judged unless our own
## reading clears the whole claim (a known stretch) or falls short of it.
static func _said_words(id:String,said:Dictionary,row:Dictionary)->String:
	var claimed:=float(said.claimed)
	var verdict:=""
	# Our eyes among them know the truth of the boast, not only our estimate.
	if float(row.get("network",0.0))>=0.25:
		var truth:=float(their_measures(String(row.civ_id)).get(id,-1.0))
		if truth>0.0:
			if claimed>truth*1.15+0.5: return "Their envoy claimed %s, %s. Our eyes among them say it is stretched: the truth is nearer %s." % [_amount(id,claimed),_when(int(said.days_ago)),_amount(id,truth)]
			if claimed<truth*0.85-0.5: return "Their envoy claimed %s, %s. Our eyes among them say they hold back: the truth is nearer %s." % [_amount(id,claimed),_when(int(said.days_ago)),_amount(id,truth)]
			return "Their envoy claimed %s, %s. Our eyes among them say it is true." % [_amount(id,claimed),_when(int(said.days_ago))]
	if not bool(row.unknown):
		if claimed>float(row.high)*1.15+0.5: verdict=" Our watchers think it stretched."
		elif claimed<float(row.low)*0.85-0.5: verdict=" Our watchers think it modest."
	return "Their envoy claimed %s, %s.%s" % [_amount(id,claimed),_when(int(said.days_ago)),verdict]

## A count as the board says it: "about 3,700 people", "about 640 practices
## known (500 to 780)", "2 great works standing", "about 12,000 goods".
static func _words(id:String,value:float,low:float,high:float,exact:bool)->String:
	if exact or is_equal_approx(low,high): return _amount(id,value,true)
	var lo:=_round_count(low) if id!="works" else roundi(low)
	var hi:=_round_count(high) if id!="works" else roundi(high)
	if lo==hi: return _amount(id,value,id=="works")
	return "%s (%s to %s)" % [_amount(id,value),_grouped(lo),_grouped(hi)]

static func _amount(id:String,value:float,exact:bool=false)->String:
	match id:
		"works":
			var n:=roundi(value)
			if n<=0: return "no great work yet"
			return "%s%d great work%s" % ["" if exact else "about ",n,"" if n==1 else "s"]
		"learning": return "%s%s practices known" % ["" if exact else "about ",_grouped(roundi(value) if exact else _round_count(value))]
		"wealth": return "about %s goods" % _grouped(_round_count(value))
	return "about %s people" % _grouped(_round_count(value))

static func _when(days:int)->String:
	if days<30: return "this month"
	if days<365: return "%d months ago" % roundi(days/30.0)
	var years:=roundi(days/365.0)
	return "a year ago" if years<=1 else "%d years ago" % years

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
	# Too close to call, but their best guess is above ours: name them.
	var likely:PackedStringArray=[]
	for row:Dictionary in rows:
		if not bool(row.ours) and not bool(row.unknown) and float(row.value)>float(ours.value) and float(ours.value)>=float(row.low): likely.append(String(row.name))
	if behind==0 and not likely.is_empty(): return "%s %s probably ahead of us, though our watchers cannot be sure." % [" and ".join(likely),"is" if likely.size()==1 else "are"]
	if behind==0: return "We are probably ahead, but %s too close to call." % _peoples(close,"is","are")
	if ahead==0 and close==0: return "We trail every people we can measure."
	return "%s clearly ahead of us." % _cap(_peoples(behind,"is","are"))

static func _peoples(n:int,one:String,many:String)->String:
	return "%s %s" % [{1:"one people",2:"two peoples",3:"three peoples"}.get(n,"%d peoples" % n),one if n==1 else many]

static func _cap(text:String)->String:
	return text.left(1).to_upper()+text.substr(1)


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
	var truth:=their_measures(civ_id)
	var out:Array=[]
	var lines:={"people":"says their people number %s",
		"learning":"says their elders keep %s",
		"works":"says their people have raised %s that travellers cross hills to see",
		"wealth":"says their stores hold %s"}
	for race:Array in RACES:
		var id:=String(race[0])
		var value:=float(truth.get(id,0.0)) if truth.has(id) else (maxf(0.0,float(civ.get("population",0.0))) if id=="people" else 0.0)
		if value<=0.0: continue
		var claimed:=value*stretch
		if id=="works": claimed=float(maxi(1,roundi(claimed)))
		out.append(_boast(civ_id,name,id,"%s's envoy %s." % [name,String(lines[id]) % _amount(id,claimed)],claimed,day))
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
