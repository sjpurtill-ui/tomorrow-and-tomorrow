extends RefCounted
## FACTUAL QUESTIONS, ANSWERED FROM THE FACT SHEET (docs/ADJUDICATION.md:
## officials know their office).
##
## The live voice is handed the speaker's fact sheet (court_facts.gd). When
## that voice is off, fails, times out or is cut off, a factual question to an
## official of our own court still gets the facts: built here, from the same
## sheet, in plain words with the exact numbers. Never a stock line claiming
## not to know or not to have been told; when the sheet really does not list
## it, the official says who would know or what would find out (redirect).
##
##   "How many men of Tsaren are now bound?"
##     -> "21 men of Tsaren are bound under our guard." (held), or
##        "None of Tsaren's men are bound now. When our men left Tsaren, the
##        21 bound men there went free." (not held)
##   "Is that all of the men of Tsaren?"
##     -> "No. Of Tsaren's men: 21 free, 38 killed, 23 fled toward Stonefield."
##
## answer(sheet, question, spoken_of) -> the answer, or "" when the words are
##   not a question about anything the sheet lists.
## redirect(offices) -> who would know, for a question the sheet cannot answer.
## Static helpers; preload.

const Ledger:=preload("res://scripts/town_ledger.gd")
const TownFate:=preload("res://scripts/town_fate.gd")

const QUESTION_RE:="(?i)(\\?\\s*[!.]*\\s*$|^\\s*(how|what|where|who|whom|which|when|why|is|are|was|were|did|do|does|have|has|had|can|could|will|would|any|tell me)\\b)"
## Which people the words ask about (first match wins; "old men" are old people).
const GROUP_RES:=[
	["elders","\\b(elders|old people|old ones|old men|old women|old folk|the old)\\b"],
	["girls","\\b(girls?|daughters?)\\b"],
	["boys","\\b(boys?|sons)\\b"],
	["men","\\b(men|males?|menfolk|husbands|fathers|fighting men|every man|man)\\b"],
	["women","\\b(women|womenfolk|females?|wives|mothers|woman)\\b"],
	["children","\\b(children|child|kids?|little ones|young ones|babies)\\b"],
]
## What the words ask about them.
const TOPIC_RES:=[
	["where","\\bwhere\\b"],
	["hostage","\\bhostages?\\b"],
	["worker","\\b(forced labou?r|labou?ring|working|work gangs?|at work|put to work)\\b"],
	["conscript","\\b(serving|conscripts?|conscripted|in our bands|drafted)\\b"],
	["bound","\\b(bound|tied|tied up|in bonds|chained|shackled|under guard|prisoners?|rounded up|locked up|in our hands)\\b"],
	["killed","\\b(killed|dead|died|slain|slew|kill|put to the sword|put to death|executed|massacred|murdered)\\b"],
	["fled","\\b(fled|flee|fleeing|ran|run|running|escaped?|escaping|got away|get away|getting away|slipped away)\\b"],
	["taken","\\b(taken|captives?|carried off|carried away|led away|brought (home|back|here)|on the road|arrived|slaves?|bondservants?)\\b"],
	["free","\\b(free|freed|loose|let go|in their houses)\\b"],
	["garrison","\\b(garrison|guards?|guarding it|fighters|soldiers|warriors|troops|spears|who holds|holds? it|holding it|of ours)\\b"],
	["all","\\b(all|the rest|rest of|left|remain|remaining|still there|what about|what became|what happened|become of|happened to|account|everyone|every one)\\b"],
	["here","\\b(live there|living there|there now|still there|in the town|inside|how many people|population|how big)\\b"],
]
## The topics that ask about a town's people.
const PEOPLE_TOPICS:=["bound","free","killed","fled","taken","hostage","worker","conscript","here"]
const STATUS_SHORT:={"free":"free","bound":"bound","hostage":"held as hostages","worker":"at forced labour","conscript":"serving with us"}
const STATUS_LONG:={"free":"free in their houses","bound":"bound under our guard","hostage":"held as hostages","worker":"at forced labour","conscript":"serving with us"}

static func _re(pattern:String)->RegEx:
	var r:=RegEx.new(); r.compile("(?i)"+pattern)
	return r

static func _has(text:String,pattern:String)->bool:
	return _re(pattern).search(text)!=null

## Words that ask something (a question mark, or a question's opening).
static func is_question(text:String)->bool:
	return _re(QUESTION_RE).search(text.strip_edges())!=null

## A question of fact (how many, where, who, what became of...), not a
## question of judgement ("should we", "what do you think").
static func factual(text:String)->bool:
	var lower:=text.strip_edges().to_lower()
	if not is_question(lower): return false
	if _has(lower,"\\b(think|should|ought|advise|would you|do you want|opinion|why)\\b"): return false
	return _has(lower,"\\b(how many|how much|how long|how big|how far|where|who (holds|is|are|was)|what (happened|became)|become of|is there|are there|any (of|left|men|women|children)|count|number|left|remain)\\b")

static func _group(lower:String)->String:
	for row in GROUP_RES:
		if _has(lower,String(row[1])): return String(row[0])
	return ""

static func _topics(lower:String)->Array[String]:
	var out:Array[String]=[]
	for row in TOPIC_RES:
		if _has(lower,String(row[1])): out.append(String(row[0]))
	return out

static func _name_in(lower:String,name:String)->bool:
	var n:=name.to_lower().strip_edges()
	if n.length()<3: return false
	var esc:=""
	for c in n: esc+=("\\"+c) if c in ".^$*+?()[]{}|\\-" else c
	return _re("\\b%s\\b" % esc).search(lower)!=null

## The town the words ask about: named, else the one spoken of in this
## audience, else the only one on the sheet. {} when none.
static func town_of(sheet:Dictionary,lower:String,spoken_of:String="")->Dictionary:
	var towns:Array=sheet.get("towns",[])
	for t in towns:
		if t is Dictionary and _name_in(lower,String((t as Dictionary).get("name",""))): return t
	if spoken_of!="":
		for t in towns:
			if t is Dictionary and String((t as Dictionary).get("name",""))==spoken_of: return t
	if towns.size()==1 and towns[0] is Dictionary: return towns[0]
	return {}

static func _n(n:int)->String:
	return str(n)

static func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)

static func _home()->String:
	var home:=String(WorldSimulation.state.settlement_name) if WorldSimulation.state!=null else ""
	return home if home!="" else "our home"

## The answer to a factual question, from the speaker's sheet; "" when the
## words ask nothing the sheet lists.
static func answer(sheet:Dictionary,question:String,spoken_of:String="")->String:
	var text:=question.strip_edges()
	if text.is_empty() or not is_question(text): return ""
	var lower:=text.to_lower()
	var offices:Array=sheet.get("offices",[])
	var t:=town_of(sheet,lower,spoken_of)
	var group:=_group(lower)
	var topics:=_topics(lower)
	# About a town's people: named, or its people asked after, or (a bare
	# "is that all?") the town this audience is speaking of.
	var named:=not t.is_empty() and _name_in(lower,String(t.get("name","")))
	var peopleish:=group!="" or topics.any(func(x:String)->bool: return x in PEOPLE_TOPICS)
	var spoken:=not t.is_empty() and spoken_of!="" and String(t.get("name",""))==spoken_of and (topics.has("all") or topics.has("where"))
	if not t.is_empty() and (named or peopleish or spoken):
		var said:=_town_answer(t,group,topics,lower,offices.has("war"))
		if said!="": return said
	if offices.has("war"):
		var war:=_war_answer(sheet,lower,topics)
		if war!="": return war
	if offices.has("stores"):
		var stores:=_stores_answer(sheet,lower)
		if stores!="": return stores
	if offices.has("tribute"):
		var tribute:=_tribute_answer(sheet,lower)
		if tribute!="": return tribute
	return ""

## Who would know, or what would find it out, for a question the sheet does
## not answer. Never "I don't know" of anything the sheet lists.
static func redirect(offices:Array)->String:
	if offices.has("war"): return "That is not in my count. I keep the bands, the garrisons and the towns we took; the headman keeps the stores and the work."
	if offices.has("stores"): return "That is not in my count. I keep the stores, the water, the houses and the work; the war leader keeps the bands and the towns we took."
	if offices.has("tribute"): return "That is not in my count. I keep the tribute and the trade; the war leader keeps the bands and the towns we took."
	return "That is not mine to count. The war leader keeps the bands and the towns we took; the headman keeps the stores. Either will give you the numbers."

# --------------------------------------------------------------------------
# A town's people
# --------------------------------------------------------------------------

## The groups a question asks about, as the ledger counts them.
static func _groups_of(group:String)->Array:
	match group:
		"men","women","children","elders": return [group]
		"girls","boys": return ["children"]
	return Ledger.GROUPS.duplicate()

## The children bands the words mean ("girls", "boys under ten"); [] for all.
static func _bands_of(group:String,lower:String)->Array:
	if not group in ["girls","boys","children"]: return []
	var kw:=TownFate.kid_words(lower)
	if not kw.is_empty(): return (kw.bands as Dictionary).keys()
	if group=="girls": return ["girls_young","girls_older"]
	if group=="boys": return ["boys_young","boys_older"]
	return []

static func _who(group:String,lower:String)->String:
	if group in ["girls","boys","children"]:
		var kw:=TownFate.kid_words(lower)
		if not kw.is_empty(): return String(kw.words)
		return group
	return String(Ledger.GROUP_WORDS.get(group,"people"))

## How many of the asked-for people a count has: by group, or by children's band.
static func _of(c:Dictionary,key:String,groups:Array,bands:Array)->int:
	if not bands.is_empty():
		var row:Dictionary=c.get("kids_"+key,{}) if c.get("kids_"+key) is Dictionary else {}
		var n:=0
		for b in bands: n+=int(row.get(b,0))
		return n
	var m:=0
	for g in groups: m+=int(c.get("%s_%s" % [key,g],0))
	return m

## The children of the asked-for bands with a status in the town.
static func _kids_status(c:Dictionary,status:String,bands:Array)->int:
	return _of(c,status,[],bands)

## "toward Stonefield", "into the hills", or several places with their numbers.
static func _toward(fled_to:Dictionary)->String:
	var places:=fled_to.keys().filter(func(k:Variant)->bool: return int(fled_to[k])>0)
	if places.is_empty(): return ""
	if places.size()==1: return "into the hills" if String(places[0]) in ["","the hills"] else "toward "+String(places[0])
	return Ledger.fled_words(fled_to)

## The whole account of one group of a town's people, part by part:
## ["21 bound under our guard", "38 killed", "23 fled toward Stonefield"].
static func _account(t:Dictionary,groups:Array,bands:Array)->PackedStringArray:
	var c:Dictionary=t.get("counts",{})
	var parts:PackedStringArray=PackedStringArray()
	var unheard:=String(t.get("status",""))=="ruin" and int(t.get("people_here",0))<=0 and int(c.get("here",0))>0
	if not unheard:
		for status in Ledger.PRESENT:
			var n:=_kids_status(c,String(status),bands) if not bands.is_empty() else _of(c,String(status),groups,[])
			if n<=0: continue
			var words:=String(STATUS_LONG[status])
			if status=="free" and bands.is_empty():
				var went:=0
				for g in groups: went+=int((c.get("went_free_groups",{}) as Dictionary).get(g,0))
				if went>0: words+=" (%s went free when our men left)" % ("all of them" if went>=n else "%d of them" % went)
			parts.append("%d %s" % [n,words])
	var flight:Dictionary=c.get("flight",{}) if c.get("flight") is Dictionary else {}
	if int(c.get("running",0))>0 and bands.is_empty():
		var run_n:=0
		for g in groups: run_n+=int(((flight.get("groups",{}) as Dictionary) if flight.get("groups") is Dictionary else {}).get(g,0))
		if run_n>0: parts.append("%d still running %s" % [run_n,"into the hills" if bool(flight.get("hills",false)) else "toward "+String(flight.get("toward","their other towns"))])
	var killed:=_of(c,"killed",groups,bands)
	if killed>0: parts.append("%d killed" % killed)
	var fled:=_of(c,"fled",groups,bands)+_of(c,"displaced",groups,bands)
	if fled>0:
		var where:=_toward(c.get("fled_to",{}) as Dictionary) if c.get("fled_to") is Dictionary else ""
		parts.append("%d fled%s" % [fled,(" "+where) if where!="" else ""])
	var taken:=_of(c,"taken",groups,bands)
	if taken>0: parts.append("%d taken to %s" % [taken,_home()])
	return parts

static func _join(parts:PackedStringArray)->String:
	if parts.is_empty(): return ""
	if parts.size()==1: return parts[0]
	return ", ".join(parts.slice(0,parts.size()-1))+" and "+parts[parts.size()-1]

static func _town_answer(t:Dictionary,group:String,topics:Array[String],lower:String,war:bool)->String:
	var c:Dictionary=t.get("counts",{})
	var name:=String(t.get("name","the town"))
	var groups:=_groups_of(group)
	var bands:=_bands_of(group,lower)
	var who:=_who(group,lower)
	var held:=bool(t.get("held",false))
	var gone_free:=String(t.get("went_free_words",""))
	# Who holds it, and with how many.
	if topics.has("garrison") and not topics.has("bound"):
		if held: return "%d of ours hold %s%s." % [int(t.get("garrison",0)),name,(" under "+String(t.commander)) if String(t.get("commander",""))!="" else ""]
		return "Nobody of ours holds %s now. %s" % [name,String(t.get("why_not_held",""))] if String(t.get("why_not_held",""))!="" else "Nobody of ours holds %s now." % name
	# Where they went.
	if topics.has("where"):
		var where:=_toward(c.get("fled_to",{}) as Dictionary) if c.get("fled_to") is Dictionary else ""
		var taken:=_of(c,"taken",groups,bands)
		var bits:PackedStringArray=PackedStringArray()
		if where!="": bits.append("those who fled from %s went %s" % [name,where])
		if taken>0: bits.append("%d %s were taken to %s" % [taken,who,_home()])
		if int(c.get("running",0))>0: bits.append("%d are still running toward %s" % [int(c.running),String(c.get("running_toward","their other towns"))])
		if bits.is_empty(): return "Nobody has left %s since we took it; nobody ran." % name
		return _cap(_join(bits))+"."
	# One status of one group: "how many men are bound?"
	for status in ["bound","hostage","worker","conscript","free"]:
		if not topics.has(status): continue
		if topics.has("all"): break
		var n:=_kids_status(c,status,bands) if not bands.is_empty() else _of(c,status,groups,[])
		if n>0: return "%d %s of %s are %s." % [n,who,name,String(STATUS_LONG[status])]
		var short:=String(STATUS_SHORT[status])
		if status!="free" and not held:
			if gone_free!="": return "None of %s's %s are %s now. %s" % [name,who,short,gone_free]
			return "None of %s's %s are %s: nobody of ours holds %s, so nobody there is under our guard." % [name,who,short,name]
		return "None of %s's %s are %s." % [name,who,short]
	if topics.has("killed") and not topics.has("all"):
		var n:=_of(c,"killed",groups,bands)
		if n<=0: return "None of %s's %s have been killed since we took it." % [name,who]
		var by:=""
		if bands.is_empty() and groups.size()>1:
			var bits:PackedStringArray=PackedStringArray()
			for g in Ledger.GROUPS:
				var k:=int(c.get("killed_%s" % g,0))
				if k>0: bits.append("%d %s" % [k,String(Ledger.GROUP_WORDS[g])])
			if not bits.is_empty(): by=": "+_join(bits)
		return "%d of %s's %s have been killed since we took it%s." % [n,name,who,by]
	if topics.has("fled") and not topics.has("all"):
		var fled:=_of(c,"fled",groups,bands)+_of(c,"displaced",groups,bands)
		var flight:Dictionary=c.get("flight",{}) if c.get("flight") is Dictionary else {}
		var where:=_toward(c.get("fled_to",{}) as Dictionary) if c.get("fled_to") is Dictionary else ""
		var ran:=int(flight.get("ran",0)) if bands.is_empty() else 0
		if ran<=0 and fled<=0: return "None of %s's %s have run from it since we took it; the bound cannot run." % [name,who]
		var out:=""
		if ran>0:
			out="%d ran from %s before they could be caught or bound" % [ran,name]
			var away:=int(flight.get("reached",0))
			if away>0: out+=", and %s got away %s" % [("all %d" % away) if away>=ran else str(away),where if where!="" else "to their people"]
			if int(flight.get("caught",0))>0: out+="; %d of them were caught" % int(flight.caught)
			if int(flight.get("count",0))>0: out+="; %d are still running toward %s" % [int(flight.count),"the hills" if bool(flight.get("hills",false)) else String(flight.get("toward","their other towns"))]
			out+=". None of the bound got away: the bound cannot run."
			if fled>ran: out+=" %d more left the town %s." % [fled-ran,where if where!="" else "for their people"]
		else:
			out="%d %s got away %s." % [fled,who,where if where!="" else "to their people"]
		return out
	if topics.has("taken") and not topics.has("all"):
		var n:=_of(c,"taken",groups,bands)
		if n<=0: return "None of %s's %s have been taken to %s." % [name,who,_home()]
		var road:=int(c.get("on_road",0))
		var arrived:=int(c.get("arrived",0))
		return "%d %s of %s were taken to %s%s." % [n,who,name,_home(),(": %d on the road, %d arrived" % [road,arrived]) if road+arrived>0 and bands.is_empty() and groups.size()>1 else ""]
	# The whole account of them: "is that all of the men?", "what became of the women?"
	var parts:=_account(t,groups,bands)
	if parts.is_empty():
		return "There are no %s of %s left, and none were counted since we took it." % [who,name] if group!="" else "Nobody lives in %s now." % name
	var lead:=""
	if _has(lower,"^\\s*(is|are|was|were)\\s+(that|those|these|they|it)\\s+(all|every|the whole)\\b|\\b(is that all|are those all|are they all|that'?s all|is it all)\\b"):
		lead="No. " if parts.size()>1 else "Yes. "
	var here_now:=("%d people are in %s now. " % [int(t.get("people_here",0)),name]) if group=="" and topics.has("here") else ""
	var out:="%s%sOf %s's %s: %s." % [lead,here_now,name,who,_join(parts)]
	# Those we held there who went free, when they are among the people asked after.
	var went:=0
	if bands.is_empty():
		for g in groups: went+=int((c.get("went_free_groups",{}) as Dictionary).get(g,0))
	if not held and gone_free!="" and went>0 and not out.contains("went free"): out+=" "+gone_free
	return out.strip_edges()

# --------------------------------------------------------------------------
# The war leader's own count, the headman's stores, the keeper's tribute
# --------------------------------------------------------------------------

static func _war_answer(sheet:Dictionary,lower:String,topics:Array[String])->String:
	if not (topics.has("garrison") or _has(lower,"\\b(bands?|army|armies|host|at home|under arms|levy)\\b")): return ""
	var bits:PackedStringArray=PackedStringArray()
	var home_n:=int(sheet.get("fighters_at_home",0))
	bits.append("%d fighters are at home" % home_n if home_n>0 else "no fighters are at home")
	for b in sheet.get("bands",[]):
		if b is Dictionary: bits.append("%s has %d, %s" % [String(b.get("name","a band")),int(b.get("fighters",0)),String(b.get("where",""))])
	for g in sheet.get("garrisons",[]):
		if g is Dictionary and int(g.get("fighters",0))>0: bits.append("%d hold %s" % [int(g.fighters),String(g.get("town",""))])
	return _cap("; ".join(bits))+"."

static func _stores_answer(sheet:Dictionary,lower:String)->String:
	if _has(lower,"\\b(food|stores?|grain|eat|hungry|ration|last)\\b"):
		return "We have %d Food in store, enough for about %s days." % [int(sheet.get("food_in_store",0)),str(sheet.get("food_days",0))]
	if _has(lower,"\\b(water|wells?|drink)\\b"):
		var w:Dictionary=sheet.get("water",{})
		return "%d water is stored, about %s days%s." % [int(w.get("stored",0)),str(w.get("days",0)),"" if bool(w.get("reachable",true)) else ", and the source is out of reach"]
	if _has(lower,"\\b(houses?|housing|roofs?|shelter|homeless)\\b"):
		return "We are %d people, with houses for %d." % [int(sheet.get("people",0)),int(sheet.get("housing",0))]
	if _has(lower,"\\b(sick|sickness|ill|health|disease)\\b"):
		return "%s." % _cap(String(sheet.get("health","")))
	if _has(lower,"\\b(born|births?|babies)\\b"):
		return "%d were born this season, and %d died." % [int(sheet.get("births_this_season",0)),int(sheet.get("deaths_this_season",0))]
	if _has(lower,"\\b(died|deaths?|dead)\\b"):
		return "%d died this season, and %d were born." % [int(sheet.get("deaths_this_season",0)),int(sheet.get("births_this_season",0))]
	if _has(lower,"\\b(how many (people|of us|souls|mouths)|our people|population)\\b"):
		return "We are %d people." % int(sheet.get("people",sheet.get("home_people",0)))
	return ""

static func _tribute_answer(sheet:Dictionary,lower:String)->String:
	if _has(lower,"\\b(tribute)\\b"):
		var taken:Array=sheet.get("tribute_taken",[])
		return ("Tribute taken: %s." % "; ".join(PackedStringArray(taken))) if not taken.is_empty() else "We have taken no tribute."
	return ""
