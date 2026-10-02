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
const AutoFounding:=preload("res://scripts/auto_founding.gd")

## A question: a question mark, or a question's opening (with or without the
## mark, after "and", "so", a name and a comma...). "Do it", "Have them bound"
## and "Will it be done" as orders are not questions.
const QUESTION_RE:="(?i)(\\?\\s*[!.]*\\s*$|^\\s*((and|so|then|now|well|but|also)\\s+)?(how|what|where|who|whom|whose|which|when|why|tell me|i (want|need|wish|would like) to know|let me know|give me (the|a|their|our) (count|number|tally|reckoning)|is (it|there|that|this|he|she|the|our|their|any|anyone|anybody|everyone)|are (we|they|there|the|our|their|any|you|those|these|all)|was (it|there|that|the|anyone)|were (there|they|the|any|all)|did (we|they|you|the|any|anyone|he|she)|do (we|they|you|the|our|their|any)|does (the|it|he|she|anyone|our|their)|have (we|they|you|the|any|our|their)|has (the|anyone|he|she|it|our|their)|had (we|they|the)|can (you|we|they|i)|could (you|we|they)|will (we|they|you|our|their)|would (we|they|you)|any)\\b)"
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
	["road","\\b(on the road|on their way|on the way|still walking|walking here|arrived|have they come|reached (us|home|here)|how far (off|out|away))\\b"],
	["taken","\\b(taken|captives?|carried off|carried away|led away|brought (home|back|here)|on the road|arrived|slaves?|bondservants?)\\b"],
	["free","\\b(free|freed|loose|let go|in their houses)\\b"],
	["garrison","\\b(garrison|guards?|guarding it|fighters|soldiers|warriors|troops|spears|who holds|holds? it|holding it|of ours)\\b"],
	["all","\\b(all|the rest|rest of|left|remain|remaining|still there|what about|what became|what happened|become of|happened to|account|everyone|every one)\\b"],
	["here","\\b(live there|living there|there now|still there|in the town|inside|how many people|population|how big)\\b"],
]
## New towns founded by our leaders ("are our leaders founding new towns?",
## "will they settle new land?", "are we sending settlers out?"); never the
## houses at home ("new homes") or one town's settlers.
const NEW_TOWNS_Q:="\\b(new|more|other|another|further|fresh) (towns?|cities|villages?|settlements?|colon(y|ies))\\b|\\b(found|founding|founds|founded|settle|settling|colonis\\w*|coloniz\\w*) (any |some |more |new |fresh |other |further |the )*(towns?|cities|villages?|settlements?|land|lands|ground)\\b|\\bsend(s|ing)? (out )?(any |more |our )?settlers\\b"
## The topics that ask about a town's people.
const PEOPLE_TOPICS:=["bound","free","killed","fled","taken","road","hostage","worker","conscript","here"]
const STATUS_SHORT:={"free":"free","bound":"bound","hostage":"held as hostages","worker":"at forced labour","conscript":"serving with us"}
const STATUS_LONG:={"free":"free in their houses","bound":"bound under our guard","hostage":"held as hostages","worker":"at forced labour","conscript":"serving with us"}

static func _re(pattern:String)->RegEx:
	var r:=RegEx.new(); r.compile("(?i)"+pattern)
	return r

static func _has(text:String,pattern:String)->bool:
	return _re(pattern).search(text)!=null

## Typed shorthand read as said: "hows the food" is "how is the food", "whats
## in the stores" is "what is in the stores", "hw many spears" is "how many".
static func normalize(text:String)->String:
	var t:=text.replace("’","'")
	t=_re("\\b(how|what|where|who|when)'?s\\b").sub(t,"$1 is",true)
	t=_re("\\bhw\\b").sub(t,"how",true)
	t=_re("\\b(wat|wht|wut)\\b").sub(t,"what",true)
	t=_re("\\bhow meny\\b").sub(t,"how many",true)
	return t

## Words that ask something (a question mark, or a question's opening, also
## after a name: "Rovik, how many are bound").
static func is_question(text:String)->bool:
	var clean:=normalize(text.strip_edges())
	if _re(QUESTION_RE).search(clean)!=null: return true
	var comma:=clean.find(",")
	if comma>0 and comma<28 and clean.substr(0,comma).split(" ",false).size()<=3: return _re(QUESTION_RE).search(clean.substr(comma+1).strip_edges())!=null
	return false

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
## words ask nothing the sheet lists. recent: the audience's last lines, for a
## bare "how many?" just after an order about a town's men.
static func answer(sheet:Dictionary,question:String,spoken_of:String="",recent:String="")->String:
	var text:=normalize(question.strip_edges())
	if text.is_empty() or not is_question(text): return ""
	var lower:=text.to_lower()
	var offices:Array=sheet.get("offices",[])
	# A fight asked after by its place ("what happened at the ford?"), never
	# the town this audience spoke of.
	var fight:=battle_of(sheet,lower)
	if not fight.is_empty(): return _battle_answer(fight,lower)
	# Whether our fighters are fed (the war leader's count, supply_state.gd).
	if offices.has("war"):
		var fed:=_fed_answer(sheet,lower)
		if fed!="": return fed
	# How far a place is, and which way (the chief scout's count).
	if offices.has("scouts"):
		var way:=_way_answer(sheet,lower)
		if way!="": return way
	# The business sector: the purse keeper's own count (court_business_orders.gd).
	if offices.has("purse"):
		var business:=String((load("res://scripts/court_business_orders.gd") as GDScript).call("answer",sheet,lower))
		if business!="": return business
	# The realm's purse: its keeper's own count (court_purse_orders.gd).
	if offices.has("purse"):
		var purse:=String((load("res://scripts/court_purse_orders.gd") as GDScript).call("answer",sheet,lower))
		if purse!="": return purse
	var t:=town_of(sheet,lower,spoken_of)
	var group:=_group(lower)
	var topics:=_topics(lower)
	# About a town's people: named, or its people asked after, or (a bare
	# "is that all?", "how many is their number?") the town this audience is
	# speaking of.
	var named:=not t.is_empty() and _name_in(lower,String(t.get("name","")))
	var peopleish:=group!="" or topics.any(func(x:String)->bool: return x in PEOPLE_TOPICS)
	var counting:=_has(lower,"\\b(how many|number|count|tally|how much)\\b")
	var bare:=counting and group=="" and topics.is_empty() and not _has(lower,"\\b(we|us|our|ours)\\b")
	# "What happened at the ford?" names another place: never the town spoken of.
	var elsewhere:=_has(lower,"\\b(at|near|by|across|over|beyond) the (?!town|village|camp|settlement|gate|walls?|houses?|men|women|children|people)\\w+")
	var spoken:=not t.is_empty() and spoken_of!="" and String(t.get("name",""))==spoken_of and (topics.has("all") or topics.has("where") or bare) and not elsewhere
	if not t.is_empty() and (named or peopleish or spoken):
		# Their number, just after an order or a report about the town's men:
		# those men.
		if bare and not named and recent!="": group=_group(recent.to_lower())
		var said:=_town_answer(t,group,topics,lower,offices.has("war"))
		if said!="": return said
	# How another people sees us, named or as "our neighbours" (standing.gd).
	var standing:=_standing_answer(sheet,lower)
	if standing!="": return standing
	var common:=_common_answer(sheet,lower)
	if common!="": return common
	if offices.has("war"):
		var war:=_war_answer(sheet,lower,topics)
		if war!="": return war
	if offices.has("stores"):
		var stores:=_stores_answer(sheet,lower)
		if stores!="": return stores
	if offices.has("tribute"):
		var tribute:=_tribute_answer(sheet,lower)
		if tribute!="": return tribute
	if offices.has("scouts"):
		var scouts:=_scouts_answer(sheet,lower)
		if scouts!="": return scouts
	return ""

## How the peoples we know see us, from the keeper of our ties' or the war
## leader's sheet: a named people, or all of them when asked of "our
## neighbours". Only questions about their view of us or what they do to us.
static func _standing_answer(sheet:Dictionary,lower:String)->String:
	var peoples:Array=(sheet.get("standing",{}) as Dictionary).get("peoples",[])
	if peoples.is_empty(): return ""
	var about_us:=_has(lower,"\\b(see|think of|feel about|say of|say about|regard|fear|afraid of|scared of|respect|trust|hate|resent|envy|covet|like|admire) (us|we|our people|our folk)\\b|\\bthink of us\\b|\\bwhy (do|are|did|would|will) (the \\w+|they|them|our neighbou?rs) (raid|attack|hate|fear|threaten|demand|come)")
	var acts:=_has(lower,"\\b(raid(s|ing|ed)?|attack(s|ing|ed)?|demand(s|ing|ed)?|league|stand(ing)? together|band(ed)? together|gang(ed)? up)\\b")
	var named:Dictionary={}
	for p:Dictionary in peoples:
		if _name_in(lower,String(p.name)): named=p
	if named.is_empty():
		if not about_us or not _has(lower,"\\b(neighbou?rs|other peoples|the peoples|strangers|foreigners|everyone else|the world)\\b"): return ""
		var all:PackedStringArray=PackedStringArray()
		for p:Dictionary in peoples: all.append("the %s: %s" % [String(p.name),String(p.headline)])
		return _cap("; ".join(all))
	if not (about_us or acts): return ""
	var f:Dictionary=named.feelings
	var said:="The %s: %s Allure %d%%, awe %d%%, fear %d%%, respect %d%%, trust %d%%, resentment %d%%." % [String(named.name),String(named.headline),int(f.get("allure",0)),int(f.get("awe",0)),int(f.get("fear",0)),int(f.get("respect",0)),int(f.get("trust",0)),int(f.get("resentment",0))]
	if not (named.does as Array).is_empty(): said+=" "+_cap("; ".join(PackedStringArray(named.does)))+"."
	return said

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

## How many of the asked-for people a count has: by group, or by children's
## band, or both ("the women and girls": the women and the girls' bands).
static func _of(c:Dictionary,key:String,groups:Array,bands:Array)->int:
	var n:=0
	if not bands.is_empty():
		var row:Dictionary=c.get("kids_"+key,{}) if c.get("kids_"+key) is Dictionary else {}
		for b in bands: n+=int(row.get(b,0))
		if groups.is_empty() or groups.has("children"): return n
	for g in groups: n+=int(c.get("%s_%s" % [key,g],0))
	return n

## Several groups named together ("their women and girls", "the men and
## boys"): {groups, bands, who} in the order said; {} for one or none.
static func _several(lower:String)->Dictionary:
	# "old men" and "old women" are old people, not men and women.
	var text:=_re("\\bold (men|women|people|ones|folk)\\b").sub(lower,"elders",true)
	var found:Array=[]
	for row in GROUP_RES:
		var m:=_re(String(row[1])).search(text)
		if m!=null: found.append([m.get_start(),String(row[0])])
	if found.size()<2: return {}
	found.sort_custom(func(a:Array,b:Array)->bool: return int(a[0])<int(b[0]))
	var groups:Array=[]; var bands:Array=[]; var words:PackedStringArray=PackedStringArray()
	for f in found:
		var g:=String(f[1])
		match g:
			"girls": bands.append_array(["girls_young","girls_older"]); words.append("girls")
			"boys": bands.append_array(["boys_young","boys_older"]); words.append("boys")
			_: groups.append(g); words.append(String(Ledger.GROUP_WORDS.get(g,g)))
	if groups.has("children"): bands.clear()
	return {"groups":groups,"bands":bands,"who":_join(words)}

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
			var n:=_of(c,String(status),groups,bands)
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

## What the town itself is now, when that is not simply ours and held: a ruin
## we burned, or theirs again. "" for a town we hold. Ends with a space.
static func _town_state(t:Dictionary)->String:
	var name:=String(t.get("name","the town"))
	match String(t.get("status","")):
		"ruin":
			var who_lives:="nobody lives there now" if int(t.get("people_here",0))<=0 else "%d people are there now" % int(t.people_here)
			var again:=String(t.get("lived_in_again",""))
			return "%s is a ruin: we burned it %s, and %s%s. " % [name,String(t.get("burned","")),who_lives,("; "+again) if again!="" else ""]
		"theirs again":
			return "%s is the %s's again; nobody of ours is there. " % [name,String(t.get("taken_from","their people"))]
		"ours":
			return "%s is ours, but no garrison of ours stands in it. " % name
	return ""

## Those taken from a town and walking to us: on the road, arrived, died on
## the way. The road is counted for all we took from the town together, so a
## part of them is told exactly only when it is all of them, or none have
## arrived yet.
static func _road_answer(c:Dictionary,name:String,who:String,taken_n:int)->String:
	var road:=int(c.get("on_road",0)); var arrived:=int(c.get("arrived",0)); var days:=int(c.get("road_days",0))
	var died:=int(c.get("died_on_road",0))
	var all_taken:=int(c.get("taken",0))
	if taken_n<=0: return "None of %s's %s have been taken to %s." % [name,who,_home()]
	var died_words:=(" %d died on the way." % died) if died>0 else ""
	if taken_n>=all_taken or (arrived<=0 and died<=0):
		var on_road:=road if taken_n>=all_taken else taken_n
		var here_n:=arrived if taken_n>=all_taken else 0
		if on_road>0 and here_n<=0: return "%d %s of %s are on the road to %s, about %d days out; none have arrived yet.%s" % [on_road,who,name,_home(),maxi(1,days),died_words]
		if on_road<=0 and here_n>0: return "All %d %s of %s we took have arrived in %s.%s" % [here_n,who,name,_home(),died_words]
		return "%d %s of %s are on the road to %s, about %d days out, and %d have arrived.%s" % [on_road,who,name,_home(),maxi(1,days),here_n,died_words]
	return "%d %s of %s were taken to %s. Of all %d we took from there, %d are on the road and %d have arrived.%s" % [taken_n,who,name,_home(),all_taken,road,arrived,died_words]

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
	# "Their women and girls": both, counted together.
	var several:=_several(lower)
	if not several.is_empty():
		groups=several.groups; bands=several.bands; who=String(several.who)
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
	# On the road to us, or arrived: "how many women and girls are on the road?"
	if topics.has("road") and not topics.has("all"):
		return _road_answer(c,name,who,_of(c,"taken",groups,bands))
	# One status of one group: "how many men are bound?"
	for status in ["bound","hostage","worker","conscript","free"]:
		if not topics.has(status): continue
		if topics.has("all"): break
		var n:=_of(c,status,groups,bands)
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
	# Asked of the town as a whole: what the town itself is now comes first
	# ("What is left of Tsaren?": a ruin we burned, nobody living there).
	var state:=_town_state(t) if group=="" and several.is_empty() else ""
	if parts.is_empty():
		if group!="" or not several.is_empty(): return "There are no %s of %s left, and none were counted since we took it." % [who,name]
		return state.strip_edges() if state!="" else "Nobody lives in %s now." % name
	var lead:=""
	if _has(lower,"^\\s*(is|are|was|were)\\s+(that|those|these|they|it)\\s+(all|every|the whole)\\b|\\b(is that all|are those all|are they all|that'?s all|is it all)\\b"):
		lead="No. " if parts.size()>1 else "Yes. "
	var here_now:=("%d people are in %s now. " % [int(t.get("people_here",0)),name]) if group=="" and topics.has("here") and state=="" else ""
	var out:="%s%s%sOf %s's %s: %s." % [lead,state,here_now,name,who,_join(parts)]
	# Those we held there who went free, when they are among the people asked after.
	var went:=0
	if bands.is_empty():
		for g in groups: went+=int((c.get("went_free_groups",{}) as Dictionary).get(g,0))
	if not held and gone_free!="" and went>0 and not out.contains("went free"): out+=" "+gone_free
	return out.strip_edges()

# --------------------------------------------------------------------------
# A fight, and what everyone knows
# --------------------------------------------------------------------------

## Words about a fight rather than a town's people.
const FIGHT_WORDS:="\\b(battle|fight|fought|fighting|skirmish|clash|won|win|lose|lost|losses|our dead|of ours|captives|prisoners|spoils|plunder|loot|booty)\\b"

## The fight the words ask after: by its place ("at the ford"), or "the last
## fight"; {} when none. A fight at a town on the sheet is asked after only
## in words of fighting, so "how many men of Tsaren are bound?" stays the town's.
static func battle_of(sheet:Dictionary,lower:String)->Dictionary:
	var fights:Array=sheet.get("battles",[]) if not (sheet.get("battles",[]) as Array).is_empty() else sheet.get("last_fights",[])
	if fights.is_empty(): return {}
	var towns:Array=(sheet.get("towns",[]) as Array).map(func(t:Variant)->String: return String((t as Dictionary).get("name","")).to_lower() if t is Dictionary else "")
	for b in fights:
		if not b is Dictionary: continue
		var place:=String((b as Dictionary).get("place","")).to_lower().strip_edges()
		var key:=place.trim_prefix("the ").strip_edges()
		if key.length()<3 or not _name_in(lower,key): continue
		if place in towns or key in towns:
			if _has(lower,FIGHT_WORDS): return b
			continue
		return b
	if _has(lower,"\\b(the|that|our|last|latest) (battle|fight|skirmish|clash)\\b|\\bwho won\\b|\\bhow did (the|that|our) (battle|fight) go\\b"): return fights[0]
	return {}

static func _at(place:String)->String:
	var p:=place.strip_edges()
	if p=="" or p=="in the field": return "in the field"
	return "at "+p

static func _battle_answer(b:Dictionary,lower:String)->String:
	var at:=_at(String(b.get("place","")))
	var when:=String(b.get("in_season",b.get("when","")))
	var won:=bool(b.get("won",false)); var lost:=bool(b.get("lost",false))
	var result:="We won %s" % at if won else ("We lost %s" % at if lost else "Neither side won %s" % at)
	if not b.has("our_dead"):
		# Only what everyone has heard: the war leader keeps the count.
		var brought:=(" We took %d captives there, and they were %s." % [int(b.captives),String(b.get("captives_fate",""))]) if int(b.get("captives",0))>0 else ""
		return "%s, %s.%s The war leader keeps the count of the dead and the spoils." % [result,when,brought]
	var ours:=int(b.get("our_dead",0)); var theirs:=int(b.get("their_dead",0))
	var captives:=int(b.get("captives",0))
	var took:PackedStringArray=PackedStringArray()
	if captives>0: took.append("we took %d captives, and they were %s" % [captives,String(b.get("captives_fate",""))])
	if String(b.get("spoils",""))!="": took.append("the spoils were %s, and they went %s" % [String(b.spoils),String(b.get("spoils_went","to the stores"))])
	var take_words:=_cap("; ".join(took))+"." if not took.is_empty() else ""
	# What we took there.
	if _has(lower,"\\b(take|took|taken|captives?|prisoners?|spoils|plunder|loot|booty|carr(y|ied) off|brought (back|home)|bring (back|home)|gain(ed)?|what did we get)\\b"):
		if took.is_empty(): return "We took no captives %s, and no spoils." % at
		return "%s %s." % [_cap(at),"; ".join(took)]
	# Our dead, and theirs.
	if _has(lower,"\\b(lose|lost|losses|our dead|of ours|of us|did we lose|fell|fall|die|died|dead)\\b"):
		return "We lost %d %s, and they lost %d. %s" % [ours,at,theirs,"We won the day." if won else ("They won the day." if lost else "Neither side won it.")]
	if _has(lower,"\\b(kill|killed|slew|slain|their dead|of theirs|of them)\\b"):
		return "We killed %d of theirs %s; we lost %d." % [theirs,at,ours]
	# What happened: who won, the dead on each side, what we took.
	var sides:=""
	if int(b.get("our_troops",0))>0 and int(b.get("their_troops",0))>0:
		sides=": %d of ours against %d of %s" % [int(b.our_troops),int(b.their_troops),("the "+String(b.their_people)) if String(b.get("their_people",""))!="" else "theirs"]
	var out:="%s, %s%s. They lost %d dead and we lost %d." % [result,when,sides,theirs,ours]
	if take_words!="": out+=" "+take_words
	return out

## A feud in plain words, from the sheet (court_facts feud_words' numbers):
## "Their raiders have come three times since the spring of Year 94, and we
## have struck back twice; four of ours and six of theirs are dead."
static func feud_sentence(v:Dictionary)->String:
	return "It is no war: %s.%s" % [feud_head(v),feud_detail(v)]

## "we are in a feud with the Esurai, raids and killings back and forth, and
## nobody has declared anything"
static func feud_head(v:Dictionary)->String:
	return "we are in a feud with the %s, raids and killings back and forth, and nobody has declared anything" % String(v.get("name",""))

## The feud's own count, each sentence led by a space ("" when there is none).
static func feud_detail(v:Dictionary)->String:
	var parts:=PackedStringArray()
	var since:=(" since %s" % _since_words(int(v.since))) if int(v.get("since",-1))>=0 and int(v.get("days",0))>0 else ""
	if bool(v.get("open_fight",false)): parts.append("our own band is out against them now")
	var raids:=int(v.get("raids",0)); var strikes:=int(v.get("strikes",0))
	if raids>0: parts.append("their raiders have come %s%s%s" % [_times(raids),since,(", and we have struck back %s" % _times(strikes)) if strikes>0 else ""])
	elif strikes>0: parts.append("we have struck at them %s%s" % [_times(strikes),since])
	var ours:=int(v.get("our_dead",0)); var theirs:=int(v.get("their_dead",0))
	if ours+theirs>0: parts.append("%d of ours and %d of theirs are dead" % [ours,theirs])
	var out:=(" "+_cap("; ".join(parts))+".") if not parts.is_empty() else ""
	if not bool(v.get("hot",true)): out+=" It has been quiet for a while now."
	if not bool(v.get("home_known",false)): out+=" Nobody here knows yet where they live."
	return out

static func _times(n:int)->String:
	return "once" if n==1 else ("twice" if n==2 else "%s times" % _count_word(n))

static func _count_word(n:int)->String:
	var words:=["none","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"]
	return String(words[n]) if n>=0 and n<words.size() else str(n)

static func _since_words(day:int)->String:
	return String((load("res://scripts/court_facts.gd") as GDScript).call("_in_season",day)).trim_prefix("in ")

## What everyone at court knows: whom we fight, whom we are at peace with,
## the day, our own number.
static func _common_answer(sheet:Dictionary,lower:String)->String:
	var wars:Array=sheet.get("at_war_with",[])
	var peace:Array=sheet.get("at_peace_with",[])
	var feuds:Array=sheet.get("feuding_with",[])
	if _has(lower,"\\b(at war|war with|in a war|at peace|peace with|feud|feuding|fighting (with|us)|(who|whom) do we fight|who are we fighting|(who|which people) (is|are) our (enemy|enemies|foes?)|do we have (any )?(enemies|foes))\\b"):
		# A people named: yes or no, and the rest.
		for n in wars:
			if _name_in(lower,String(n)): return "Yes. We are at war with the %s." % String(n)
		# A small people: a feud, never a war (conflict_scale.gd), in plain words.
		for v in feuds:
			if v is Dictionary and _name_in(lower,String((v as Dictionary).get("name",""))): return feud_sentence(v)
		var feud_names:=PackedStringArray()
		for v in feuds: if v is Dictionary: feud_names.append(String((v as Dictionary).get("name","")))
		var feud_line:=(" We are in a feud with the %s: raids and killings back and forth, nothing declared." % " and the ".join(feud_names)) if not feud_names.is_empty() else ""
		for n in peace:
			if _name_in(lower,String(n)): return "No. We are at peace with the %s%s.%s" % [String(n),("; we are at war with the %s" % " and the ".join(PackedStringArray(wars))) if not wars.is_empty() else "",feud_line]
		if wars.is_empty() and feuds.size()==1 and feuds[0] is Dictionary: return "We are at war with nobody, but %s.%s%s" % [feud_head(feuds[0]),feud_detail(feuds[0]),(" We are at peace with the %s." % " and the ".join(PackedStringArray(peace))) if not peace.is_empty() else ""]
		if wars.is_empty(): return "We are at war with nobody.%s%s" % [feud_line,(" We are at peace with the %s." % " and the ".join(PackedStringArray(peace))) if not peace.is_empty() else ""]
		return "We are at war with the %s.%s%s" % [" and the ".join(PackedStringArray(wars)),feud_line,(" We are at peace with the %s." % " and the ".join(PackedStringArray(peace))) if not peace.is_empty() else ""]
	if _has(lower,"\\b(what|which) (day|year|season)\\b|\\bwhat time of (the )?year\\b"):
		var parts:=String(sheet.get("when","")).split(" · ")
		return "It is the %s of %s." % [parts[1].to_lower(),parts[0]] if parts.size()==2 else "It is %s." % String(sheet.get("when",""))
	# Our nation's name ("what is our nation called?", "what are we called?"),
	# from the sheet (nation_name.gd): the name given, or the town we go by.
	if _has(lower,"\\bwhat (is|are|'s) (our|my|the) (nation|people|realm|folk|tribe|kingdom)('s)? (called|named|name)\\b|\\bwhat( is|'s) the name of (our|my|the) (nation|people|realm|folk|tribe|kingdom)\\b|\\bwhat are we called\\b(?!\\s+(to|for|on|upon|by|into)\\b)|\\bwhat do we call ourselves\\b|\\bwhat do (they|other peoples|strangers|foreigners) call us\\b|\\bwhat( is|'s) our name\\s*\\??\\s*$"):
		var nation:=String(sheet.get("nation",""))
		if nation!="": return "We are %s." % (("the "+nation.substr(4)) if nation.begins_with("The ") else nation)
		var home:=String(sheet.get("home",""))
		return ("Our people have no name of their own yet; we go by %s." % home) if home!="" else "Our people have no name of their own yet."
	if int(sheet.get("home_people",0))>0 and _has(lower,"\\bhow many (are we|of us|souls|mouths)\\b|\\bhow many people (are there|live) (at home|here)\\b|\\bour number\\b"):
		return "We are %d people in %s." % [int(sheet.home_people),String(sheet.get("home","our home"))]
	# The god's word on new towns ("are our leaders founding new towns?"), as
	# the Settlement dock's switch stands (court_facts new_towns); a question
	# of judgement ("should we found more towns?") is the voice's.
	if sheet.get("new_towns") is Dictionary and _has(lower,NEW_TOWNS_Q) and not _has(lower,"\\b(should|ought|think|advise|would you|do you want|why)\\b"):
		return AutoFounding.court_words(sheet.new_towns,true)
	# Who holds an office now ("who keeps the stores now?", "who is on my council?").
	var holder:=_office_answer(sheet,lower)
	if holder!="": return holder
	# How the people hold the god ("do the people love me?", "are they happy?").
	var regard:Dictionary=sheet.get("people_regard",{})
	var collective:=_has(lower,"\\b(people|they|them|folk|everyone|everybody|the town|the camp|my subjects|the realm|the hearths)\\b") or _name_in(lower,String(sheet.get("home","")))
	if not regard.is_empty() and collective and _has(lower,"\\b(love|loves|fear|fears|dread|hate|hates|revere|worship|trust) (me|you|us|their god|the god)\\b|\\b(happy|content|contented|unhappy|angry|restless|loyal|afraid|satisfied|pleased)\\b|\\bthink of (me|you|us)\\b|\\bwhat do (the|my|our) people (think|say|feel)\\b|\\bhow do (the|my|our) people (feel|see|take)\\b"):
		return "%s: their love for you is %s, and their dread of you %s." % [_cap(String(regard.get("read","your people serve dutifully"))),String(regard.get("love","some")),String(regard.get("dread","little"))]
	return ""

## Office words the court uses, to the council's office keys.
const OFFICE_ANSWER_WORDS:=[
	["Quartermaster","\\b(stores?|keeper of (the )?stores|store-?keeper|tribute|keeper of tribute|quartermaster)\\b"],
	["Marshal","\\b(war leader|war chief|warleader|marshal|the bands|the warriors|the fighters|the spears)\\b"],
	["ChiefScout","\\b(pathfinder|chief scout|head scout|the scouts|the trails)\\b"],
	["Steward","\\b(headman|head man|hearth chief|steward|the hearths)\\b"],
]

static func _office_answer(sheet:Dictionary,lower:String)->String:
	var council:Array=sheet.get("council",[])
	if council.is_empty(): return ""
	if _has(lower,"\\bwho (is|are|sits?|serves?) (on|in) (my|our|the) council\\b|\\bwho (is|are) (my|our|the) (council|officials|advisors|advisers)\\b|\\bwho serves me\\b"):
		var names:PackedStringArray=PackedStringArray()
		for c:Dictionary in council: names.append("%s %s" % [String(c.get("title","")),String(c.get("name",""))])
		var aside:Array=sheet.get("set_aside",[])
		return "Your council: %s.%s" % [_join(names),(" Set aside: %s." % _join(PackedStringArray(aside))) if not aside.is_empty() else ""]
	if not _has(lower,"\\bwho (keeps|holds|has|runs|leads|minds|is|serves as|is our|is my|is the)\\b"): return ""
	for row in OFFICE_ANSWER_WORDS:
		if not _has(lower,String(row[1])): continue
		for c:Dictionary in council:
			if String(c.get("office",""))==String(row[0]): return "%s is %s now." % [String(c.get("name","")),String(c.get("title",""))] if _has(lower,"\\bnow\\b") else "%s is %s." % [String(c.get("name","")),String(c.get("title",""))]
		return "Nobody holds that office now."
	return ""

# --------------------------------------------------------------------------
# A foreign envoy's own people
# --------------------------------------------------------------------------

## An envoy's answer about their own people, from what they know of them
## (court_facts.people): the towns they still hold, where their ruler sits,
## their number, the towns they lost to us. "" when the words ask none of these.
static func envoy_answer(p:Dictionary,question:String)->String:
	var text:=question.strip_edges()
	if p.is_empty() or text.is_empty() or not is_question(text): return ""
	var lower:=text.to_lower()
	var towns:Array=p.get("towns",[])
	var names:=PackedStringArray(towns.map(func(t:Variant)->String: return String((t as Dictionary).get("name",""))))
	var lost:Array=p.get("lost",[])
	var lost_words:=PackedStringArray()
	var lost_seat:=""
	for l in lost:
		var ld:Dictionary=l
		lost_words.append("%s %s" % [String(ld.name),{"held":"is in your hands","taken":"is in your hands","burned":"you burned"}.get(String(ld.get("state","")),"is lost to us")])
		if bool(ld.get("seat",false)): lost_seat=String(ld.name)
	var lost_line:=(" "+_cap("; ".join(lost_words))+".") if not lost_words.is_empty() else ""
	# Where their ruler sits now.
	if _has(lower,"\\b(ruler|chief|king|queen|leader|lord|headman|master)\\b") and _has(lower,"\\b(where|sits?|seat|lives?|dwells?|stays?|now|hall)\\b"):
		if String(p.get("seat",""))=="": return "Our ruler has no town left to sit in."
		return "Our ruler sits at %s now.%s" % [String(p.seat),(" %s was our seat until you took it from us." % lost_seat) if lost_seat!="" and lost_seat!=String(p.seat) else ""]
	# A town named: how many live there, or that it is lost to us.
	for t in towns:
		if _name_in(lower,String((t as Dictionary).get("name",""))):
			return "%s is ours; about %d live there%s." % [String(t.name),int(t.people),", and our ruler sits there now" if String(t.name)==String(p.get("seat","")) else ""]
	for l in lost:
		if _name_in(lower,String((l as Dictionary).get("name",""))):
			return "%s? %s." % [String(l.name),_cap(String({"held":"it is in your hands; your garrison holds it","taken":"it is in your hands","burned":"you burned it"}.get(String(l.get("state","")),"it is lost to us")))]
	# How many they are.
	if _has(lower,"\\bhow many\\b") and _has(lower,"\\b(you|your|they|them|people|souls|of you|are you|are they)\\b"):
		return "We are about %d, in %s." % [int(p.get("people",0)),_join(names) if not names.is_empty() else "no town of our own now"]
	# What they hold still, their other towns.
	if _has(lower,"\\b(hold|have|keep|own|left|remain|still|other|another|towns?|cities|city|villages?|settlements?|homes?)\\b"):
		if names.is_empty(): return "We hold no town now.%s" % lost_line
		return "We still hold %s.%s" % [_join(names),lost_line]
	return ""

# --------------------------------------------------------------------------
# The war leader's own count, the headman's stores, the keeper's tribute
# --------------------------------------------------------------------------

static func _war_answer(sheet:Dictionary,lower:String,topics:Array[String])->String:
	# What they fight with: spears and other arms in store.
	if _has(lower,"\\b(spears?|weapons?|arms|axes?|bows?|slings?|clubs?|javelins?)\\b") and not _has(lower,"\\bunder arms\\b"):
		var n:=int(sheet.get("spears",0))
		var other:PackedStringArray=PackedStringArray()
		var weapons:Dictionary=sheet.get("weapons",{})
		for w in weapons: other.append("%d %s" % [int(weapons[w]),String(w)])
		var spears:="We have %d spears in store" % n if n>0 else "We have no spears in store"
		return "%s%s." % [spears,("; and "+_join(other)) if not other.is_empty() else ""]
	# Those called up and those in drill.
	if _has(lower,"\\b(recruits?|called up|new (fighters|warriors|men)|being trained|in training|training|drill(ing)?|levies)\\b"):
		return "%d are called up and waiting for weapons and drill; %d are in training now." % [int(sheet.get("recruits",0)),int(sheet.get("in_training",0))]
	var ready:=_has(lower,"\\b(ready|prepared|strong enough)\\b")
	if not (ready or topics.has("garrison") or _has(lower,"\\b(bands?|army|armies|host|at home|under arms|levy)\\b")): return ""
	var bits:PackedStringArray=PackedStringArray()
	var home_n:=int(sheet.get("fighters_at_home",0))
	bits.append("%d fighters are at home" % home_n if home_n>0 else "no fighters are at home")
	for b in sheet.get("bands",[]):
		if b is Dictionary: bits.append("%s has %d, %s" % [String(b.get("name","a band")),int(b.get("fighters",0)),String(b.get("where",""))])
	for g in sheet.get("garrisons",[]):
		if g is Dictionary and int(g.get("fighters",0))>0: bits.append("%d hold %s" % [int(g.fighters),String(g.get("town",""))])
	return _cap("; ".join(bits))+"."

## Food words about our own fighters (not the stores, not a town's people).
const FED_RE:="\\b(fed|feed|feeding|food|hungry|hunger|starv\\w*|rations?|provision\\w*|supplies|supplied|supply|eat|eating|eaten)\\b"
const OURS_RE:="\\b(my|our)\\s+(men|fighters|warriors|soldiers|troops|bands?|garrisons?|host|army|armies|levy|spears)\\b|\\b(fighters|warriors|soldiers|troops|bands?|garrisons?)\\b"

## "Are my men fed?": each band and garrison's share of a day's food, how
## it comes (foraged, carried, from its town), days hungry and its line
## back to our stores, exactly as the day's rations gave it. A band or town
## named in the question: that one only. "" when not asked.
static func _fed_answer(sheet:Dictionary,lower:String)->String:
	if not _has(lower,FED_RE) or _has(lower,"\\bstores?\\b"): return ""
	var bands:Array=sheet.get("bands",[]); var garrisons:Array=sheet.get("garrisons",[])
	var named:Array=[]
	for b in bands:
		if b is Dictionary and _name_in(lower,String((b as Dictionary).get("name",""))): named.append(b)
	for g in garrisons:
		if g is Dictionary and _name_in(lower,String((g as Dictionary).get("town",""))): named.append(g)
	if named.is_empty() and not _has(lower,OURS_RE): return ""
	var rows:Array=named if not named.is_empty() else bands+garrisons
	var bits:=PackedStringArray()
	for row in rows:
		if not row is Dictionary: continue
		var fed:Dictionary=(row as Dictionary).get("fed",{})
		if fed.is_empty(): continue
		var who:=String(row.get("name","")) if (row as Dictionary).has("name") else "The garrison in "+String(row.get("town",""))
		if bool(fed.get("at_home",false)):
			bits.append("%s is at home, fed from the stores" % who); continue
		var shares:=PackedStringArray()
		if int(fed.get("from_town",0))>0: shares.append("%d%% from the town" % int(fed.from_town))
		if int(fed.get("foraged",0))>0: shares.append("%d%% foraged" % int(fed.foraged))
		if int(fed.get("carried",0))>0: shares.append("%d%% carried" % int(fed.carried))
		var bit:="%s gets %d%% of its food%s: %s, %s" % [who,int(fed.get("gets",0)),(" ("+_join(shares)+")") if not shares.is_empty() else "",String(fed.get("state","")),String(fed.get("line",""))]
		if int(fed.get("hungry_days",0))>0: bit+=", hungry %d days now" % int(fed.hungry_days)
		bits.append(bit)
	if bits.is_empty():
		var home_n:=int(sheet.get("fighters_at_home",0))
		return "No band of ours is out; the %d at home eat from the stores." % home_n if home_n>0 else "No band of ours is out, and none is in the field to feed."
	return _cap("; ".join(bits))+"."

## Words for what the stores hold, to the store's own name.
const STORE_WORDS:=[["Timber","\\b(timber|wood|logs?|lumber)\\b"],["Stone","\\b(stones?|rock)\\b"],["Clay","\\b(clay|mud brick)\\b"],["Fiber Plants","\\b(fib(er|re)s?|reeds?|flax|rushes)\\b"],["Forced Labor","\\b(bondservants?|slaves|forced labou?r)\\b"],["Transport Carts","\\b(carts?|sledges?|wagons?)\\b"]]
## The work, in plain words (population_allocations task names).
const WORK_WORDS:={"food":"getting food","survey":"going over the land","extraction":"cutting timber and quarrying stone","construction":"building","crafting":"making tools and goods","logistics":"hauling and carrying",
	"knowledge":"learning and teaching the young","administration":"keeping the council's business","defense":"on the watch"}

static func _stores_answer(sheet:Dictionary,lower:String)->String:
	var stock:Dictionary=sheet.get("stock",{})
	# One thing in the stores, by name ("how much timber?", "how much clay is in the stores?").
	for row in STORE_WORDS:
		if not _has(lower,String(row[1])): continue
		var n:=int(stock.get(String(row[0]),0))
		return "We have %d %s in the stores." % [n,String(row[0])] if n>0 else "We have no %s in the stores." % String(row[0])
	# The whole of the stores.
	if _has(lower,"\\bwhat (do we have|is|'s) in (the |our )?stores?\\b|\\bwhat (do|does) (the |our )?stores? hold\\b|\\ball (the|our) stores\\b|\\beverything in (the|our) stores\\b"):
		var parts:PackedStringArray=PackedStringArray(["%d Food" % int(sheet.get("food_in_store",0))])
		for res in stock: parts.append("%d %s" % [int(stock[res]),String(res)])
		return "In the stores: %s. The food is enough for about %s days." % [_join(parts),str(sheet.get("food_days",0))]
	# The work: who is doing what.
	if _has(lower,"\\b(work|working|doing|busy|tasks?|jobs?|labou?r)\\b") and not _has(lower,"\\b(forced labou?r)\\b"):
		var tasks:Dictionary=sheet.get("workers_by_task",{})
		if not tasks.is_empty():
			var bits:PackedStringArray=PackedStringArray()
			for task in tasks: bits.append("%d %s" % [int(tasks[task]),String(WORK_WORDS.get(String(task).to_lower(),String(task).to_lower()))])
			# And who sets it (manual_work.gd), as the sheet says.
			var by:=(" "+preload("res://scripts/manual_work.gd").court_words(sheet.daily_work,true)) if sheet.get("daily_work") is Dictionary else ""
			return "At work now: %s.%s" % [_join(bits),by]
	if _has(lower,"\\b(food|stores?|grain|eat|hungry|ration)\\b|\\bhow long\\b.*\\blast\\b"):
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
	# Trade: with whom, and how much passes (the trade ledger's own words).
	if _has(lower,"\\b(trade|trading|traders?|barter|exchange)\\b"):
		var with_us:PackedStringArray=PackedStringArray()
		var none:PackedStringArray=PackedStringArray()
		for p:Dictionary in sheet.get("peoples",[]):
			# One people named: what passes with them, and what it makes of us.
			var named:=String(p.people).to_lower().trim_prefix("the ")
			if named.length()>=3 and _has(lower,"\\b"+named+"s?\\b"): return _trade_with(p)
		for p:Dictionary in sheet.get("peoples",[]):
			if float(p.get("trade",0.0))>0.0: with_us.append("the %s (we send %s; they send %s)" % [String(p.people),String(p.get("we_send","")),String(p.get("they_send",""))])
			else: none.append("the %s" % String(p.people))
		if with_us.is_empty(): return "We trade with no one yet: nothing passes between us and %s." % (_join(none) if not none.is_empty() else "any people we know")
		return "We trade with %s.%s" % [_join(with_us),(" Nothing passes between us and %s." % _join(none)) if not none.is_empty() else ""]
	return ""

## What passes between us and one people, from the keeper's facts.
static func _trade_with(p:Dictionary)->String:
	var name:=String(p.people)
	if not bool(p.get("met",true)): return "We know the %s only by word: no trader of ours has reached them, and nothing passes between us." % name
	var parts:=PackedStringArray()
	if float(p.get("trade",0.0))>0.0: parts.append("With the %s: we send %s; they send %s." % [name,String(p.get("we_send","nothing")),String(p.get("they_send","nothing"))])
	else: parts.append("Nothing passes between us and the %s yet." % name)
	for key in ["they_lean","we_lean"]:
		if String(p.get(key,""))!="": parts.append(String(p[key]))
	if String(p.get("our_stance",""))!="": parts.append("Our stance toward them: %s." % String(p.our_stance))
	if String(p.get("their_stance",""))!="": parts.append(String(p.their_stance)+".")
	if String(p.get("tribute",""))!="": parts.append(String(p.tribute)+".")
	return " ".join(parts)

## The chief scout: the parties out, and what lies beyond our lands.
static func _scouts_answer(sheet:Dictionary,lower:String)->String:
	var parties:Array=sheet.get("parties",[])
	if _has(lower,"\\b(scouts?|scouting|part(y|ies)|outriders|trackers)\\b"):
		if parties.is_empty(): return "No scouting party is out now; all our scouts are at home."
		var bits:PackedStringArray=PackedStringArray()
		for p:Dictionary in parties: bits.append((load("res://scripts/court_facts.gd") as GDScript).call("party_words",p))
		return "%s %s out: %s." % [str(parties.size()) if parties.size()>1 else "One",("parties are" if parties.size()>1 else "party is"),_join(bits)]
	if _has(lower,"\\b(out there|beyond|around us|who else|other peoples?|any peoples?|neighbou?rs?|strangers|met|have we found|what lies|what is there|what's there|the world|the lands?)\\b"):
		var met:PackedStringArray=PackedStringArray()
		for p:Dictionary in sheet.get("met_peoples",[]): met.append("the %s (%s%s)" % [String(p.name),"in a feud with us" if bool(p.get("feud",false)) else ("at war with us" if bool(p.at_war) else ("broken, no town of theirs left" if bool(p.get("broken",false)) else "at peace")),"" if bool(p.get("home_known",false)) else ", their home not yet found"])
		var towns:PackedStringArray=PackedStringArray()
		for t:Dictionary in sheet.get("known_towns",[]): towns.append((load("res://scripts/court_facts.gd") as GDScript).call("town_way_words",t))
		if met.is_empty() and towns.is_empty(): return "We have met no other people yet; the scouts have found nobody."
		return "We have met %s.%s" % [_join(met) if not met.is_empty() else "no people face to face",(" We know of %s." % _join(towns)) if not towns.is_empty() else ""]
	return ""

## How far a town is and which way ("how far is Tsaren?", "where is Eldwick?").
static func _way_answer(sheet:Dictionary,lower:String)->String:
	if not _has(lower,"\\b(how far|which way|what direction|where (is|are|lies)|how many (days|km)|distance)\\b"): return ""
	for t:Dictionary in sheet.get("known_towns",[]):
		if not _name_in(lower,String(t.get("name",""))): continue
		if not t.has("km"): return "We know of %s, but not yet the way there." % String(t.name)
		return "%s lies about %d km %s of %s%s." % [String(t.name),int(t.km),String(t.get("way","")),String(sheet.get("home","our home")),(", and it is ours now" if bool(t.get("held",false)) else "")]
	return ""
