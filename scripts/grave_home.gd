extends RefCounted
## GRAVE ORDERS AGAINST THE GOD'S OWN PEOPLE.
##
## "Kill all women in the village", "kill half the farmers", "burn our own
## village", "drive out the old": the god's word against the people who are
## its own. Read here, adjudicated from the one ledger (docs/ADJUDICATION.md)
## and carried out through the real population model (GameState's age
## cohorts, its count of women and men, the pregnancies, the work), never a
## counter of its own:
##   1. Whose people. Ours when the words say so ("our village", "my people",
##      Seanstone, the farmers), or when no other people is in our hands and no
##      war is on. A town or people of theirs named, "their"/"them", or a town
##      we hold that this audience is speaking of: the war orders
##      (town_fate.gd), as before. "The village" while we hold a town nobody
##      has spoken of, or at war with none held: ONE question, which
##      (answer() carries the reply; never the same question again).
##   2. The one ordered: court_commands.obedience (obey, plead, refuse), then
##      the stated chance anyone refuses a grave order on their own people
##      (refusal_odds: their empathy, love, courage and dread; the god's
##      insistence halves it). A refusal is court_commands._refusal (they flee,
##      or kneel bound); a plea waits for the god's "do it".
##   3. The hands: our fighters at home, else the watch, else a few men the
##      official gathers. Each may refuse (hand_refusal_odds, one seeded roll
##      each); of those who refuse some flee the realm, with their gear.
##   4. The people: each one named is caught on the stated odds (catch_odds:
##      the hands against their number, as town_fate.catch_odds); a hand does
##      a day's work (KILLS_PER_HAND, DRIVE_PER_HAND) for at most DAYS_MAX days,
##      so a few dozen hands are never instant and total. Those not caught run:
##      from a killing most leave the realm (ESCAPED_LEAVE) and the rest hide
##      with kin; from a driving out they hide and stay. Of the rest of the
##      people a share flees too (flight_odds).
##   5. The ledger: deaths by group (GameState.register_directive_population_
##      deaths with the cohorts and the sex named), flight (register_population
##      _departures), the pregnancies of the women lost (lose_pregnancies), the
##      houses and stores burned. The count before, less what is reported, is
##      the count after.
##   6. What lasts: dread and lost love (divine_regard PEOPLE_ACTS, the court's
##      bonds and memories), legitimacy and cohesion, fewer births while the
##      women are fewer (the birth model reads the women left), every people
##      that knows us hears of it, a Chronicle moment in plain words, and the
##      memory of the one who did it.
## Laws ("execute every thief", "anyone who murders will be put to death")
## stay laws (court_realm_acts.law): never read here. The words are plain and
## never graphic; children are counted, never described.
## Static helpers; preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const WarOrders:=preload("res://scripts/court_war_orders.gd")
const Realm:=preload("res://scripts/court_realm_acts.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Ledger:=preload("res://scripts/town_ledger.gd")
const CC_PATH:="res://scripts/court_commands.gd"

## The result's verb and the pending order's (court_commands, order_tracker).
const VERB:="slaughter"
const PENDING_VERB:="grave_home"
const PENDING_DAYS:=2
## What one hand does in a day: kill five who cannot fight back (as
## town_fate.KILLS_PER_FIGHTER), or drive eight from their houses.
const KILLS_PER_HAND:=5
const DRIVE_PER_HAND:=8
## How long it goes on before everyone left has run or hidden.
const DAYS_MAX:=3
## Of the hands who refuse, the share who flee the realm rather than stay.
const HAND_FLEE:=0.4
## Of those who got away from a killing, the share who leave the realm (the
## rest hide with kin and stay among us).
const ESCAPED_LEAVE:=0.6
## The directive the deaths are recorded under (GameState's demographic ledger).
const DEATH_ID:="killing_at_the_gods_word"

const ADULT:=["youth","early_adults","established_adults","mature_adults","elders"]
const WORKING:=["youth","early_adults","established_adults","mature_adults"]
const ALL:=["children","youth","early_adults","established_adults","mature_adults","elders"]

## Groups of our people the words may name, in the order they are tried:
## [id, pattern, cohorts, sex, words, refusal weight].
const GROUPS:=[
	["old_women","\\bold (women|wives|mothers|woman)\\b",["elders"],"female","old women",0.14],
	["old_men","\\bold (men|males|man)\\b",["elders"],"male","old men",0.12],
	["elders","\\b(old people|old ones|old folks?|elders|elderly|the aged|grandmothers|grandfathers|grey ?beards|grey ?heads|the old(?=\\s*$|\\s*[,.!;]|\\s+(and|too|now|first|as|from|out|away|of|in|at|with|who|that|here|there)\\b))",["elders"],"","old people",0.12],
	["girls","\\b(girls|daughters|little girls)\\b",["children"],"female","girls",0.22],
	["boys","\\b(boys|sons|little boys)\\b",["children"],"male","boys",0.22],
	["children","\\b(children|kids|young ones|little ones|babies|infants|toddlers|every child)\\b",["children"],"","children",0.22],
	["women","\\b(women|womenfolk|wives|mothers|females|every woman|every female)\\b",ADULT,"female","women",0.15],
	["men","\\b(men|males|menfolk|husbands|fathers|every man|every male)\\b",ADULT,"male","men",0.08],
	["everyone","\\b(everyone|everybody|every ?one of them|every soul|all of them|them all|the people|our people|my people|villagers|townsfolk|townspeople|inhabitants|residents|population|families|households|the whole (village|town|camp|settlement|people))\\b",ALL,"","people",0.2],
]
## Our own people by their work: [id, pattern, work role, words].
const TRADES:=[
	["farmers","\\b(farmers?|field ?hands|hunters?|gatherers?|foragers?|herders?|herdsmen|shepherds?|fishers?|fishermen)\\b","Food","farmers"],
	["builders","\\b(builders?|masons?|diggers?)\\b","Construction","builders"],
	["crafters","\\b(craftsmen|crafters?|craftspeople|potters?|weavers?|smiths?|toolmakers?|carvers?|tanners?)\\b","Crafting","craftspeople"],
	["carriers","\\b(carriers?|porters?|haulers?)\\b","Logistics","carriers"],
	["quarrymen","\\b(miners?|quarrymen|woodcutters?|stonecutters?)\\b","Extraction","quarrymen and woodcutters"],
]
const KILL_RE:="(?i)\\b(kill|kills|kil|kiil|killl|slay|slaughter|massacre|butcher|execute|exterminate|murder|wipe out|cut down|do away with|get rid of|put [\\w' ]{0,30}?to (the sword|death)|rid [\\w' ]{0,30}?\\bof)\\b"
const BURN_RE:="(?i)\\b(burn|burns|torch|set fire to|set [\\w' ]{0,30}?(on fire|alight|ablaze)|put [\\w' ]{0,30}?to the torch|raze)\\b"
const DRIVE_RE:="(?i)\\b((drive|cast|throw|chase|force|turn|kick|run) [\\w' ]{0,40}?\\b(out|away|off)\\b|banish|exile|expel)\\b"
## Where one order ends and the next begins.
const NEXT_RE:="(?i)[,;.!]|\\b(then|and then|take|bring|carry|lead|send|march|haul|give|keep|hold|spare|free|release|leave|feed|build)\\b"
## "The village", "this town": a village not named.
const VILLAGE_RE:="(?i)\\b(the|this|that|our|my|a|in|of) (vill?age|vilage|villiage|town|camp|settlement|hamlet|houses|homes|huts)\\b"
## The words say the people are ours.
const OWN_RE:="(?i)\\b(our|my) own\\b|\\b(our|my) (vill?age|vilage|villiage|town|camp|settlement|hamlet|home|homes|houses|huts|people|folk|kin|realm|hearths?|women|men|children|old|elders|girls|boys|farmers|hunters|builders|craftsmen|families|households|subjects|tribe|clan)\\b|\\bat home\\b|\\bof ours\\b|\\bamong us\\b|\\bin our midst\\b"
## Someone else's people, or the captives of a fight: the war orders'.
const FOREIGN_RE:="(?i)\\b(their|theirs|them|they|the enemy|enemy|enemies|foes?|those people|these people|strangers|foreigners|captives?|prisoners?|bondservants?|bondsmen|slaves|envoys?|heralds?|messengers?)\\b"
## Wrongdoers, conditions and standing words: a law or a measure, never this.
const EXCLUDE_RE:="(?i)\\b(rebels?|ringleaders?|troublemakers?|agitators?|instigators?|traitors?|deserters?|criminals?|outlaws?|thie(f|ves)|murderers?|wrongdoers?|the guilty|the lazy|cowards?|liars?|hoarders?|poachers?|drunkards?|anyone who|anybody who|whoever|any who|those who|all who|everyone who|everybody who|any (man|woman|one) who|if (they|any|anyone|someone|he|she)|whenever|from now on|henceforth|never|law)\\b"
## Parts of the whole the words ask for: [pattern, share].
const PARTS:=[
	["\\b(two thirds|2/3)\\b",2.0/3.0],["\\b(three quarters|most)\\b",0.75],["\\b(half|one half|1/2|every (second|other))\\b",0.5],
	["\\b(a third|one third|1/3|every third)\\b",1.0/3.0],["\\b(a quarter|one quarter|a fourth|one fourth|1/4|every fourth)\\b",0.25],
	["\\b(a fifth|one fifth|1/5|every fifth)\\b",0.2],["\\b(a tenth|one tenth|1/10|every tenth)\\b",0.1],["\\b(some|several)\\b",0.2],
]
const NUMBER_WORDS:={"a few":4,"a dozen":12,"a score":20,"a hundred":100,"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,"eleven":11,"twelve":12,"fifteen":15,"twenty":20,"thirty":30,"forty":40,"fifty":50,"sixty":60,"hundred":100}

static func _re(pattern:String)->RegEx:
	var re:=RegEx.new(); re.compile(pattern)
	return re

static func _has(text:String,pattern:String)->bool:
	return _re(pattern).search(text)!=null

static func _cc()->GDScript:
	return load(CC_PATH) as GDScript

static func _day()->int:
	return Hall._day()

# --------------------------------------------------------------------------
# Reading the words
# --------------------------------------------------------------------------

static func reading(text:String,audience:Dictionary,list:Array[Dictionary]=[])->Dictionary:
	## {} when these words are no grave order against our own people (or are
	## the war orders' business). Otherwise {kind:"act"|"ask", how:"kill"|
	## "burn"|"drive", groups:[...], share, count, text, own, options?}.
	var clean:=text.strip_edges().replace("’","'")
	if clean=="" or clean.ends_with("?") or audience.is_empty(): return {}
	if String(audience.get("origin",""))=="foreign": return {}
	var lower:=clean.to_lower()
	if _has(lower,"^\\W*(what|why|how|who|whom|where|when|should|could|can|would|shall we|do we|is it|are we|did|does|have we)\\b"): return {}
	var verb:=_verb(lower)
	if verb.is_empty(): return {}
	# Words that hold an act back, a law, wrongdoers, a condition: never this.
	for p:Dictionary in Realm.clauses(clean):
		if bool(p.held): return {}
	if _has(lower,EXCLUDE_RE): return {}
	var cc:=_cc()
	var mention:=func(t:String,l:Array[Dictionary])->Array[Dictionary]: return cc.call("mentions",t,l)
	if not Realm.law(clean,list,mention).is_empty(): return {}
	var span:=_span(lower,int(verb.at))
	# Someone else's people, or one person: the war orders and the person acts.
	if _has(span,FOREIGN_RE) or bool(cc.call("_names_a_place",span)): return {}
	if _one_person(span,list,cc): return {}
	var how:=String(verb.how)
	var groups:=_groups(span)
	var place:=_has(span,VILLAGE_RE)
	# Which of our towns: one named, else the one whose leader is ordered, else home.
	var town:=_our_town(span,list)
	var home:=String(town.get("name",""))
	var own:=_has(span,OWN_RE) or bool(town.get("named",false))
	if how=="burn":
		# Burning people is killing them; burning a place is burning the village.
		if not groups.is_empty(): how="kill"
		elif not (own or place): return {}
	if groups.is_empty():
		# "Kill the village", "drive everyone out of our town": all its people.
		if how=="burn": pass
		elif place or own: groups=[_group_row(GROUPS[GROUPS.size()-1])]
		else: return {}
	var trades_only:=groups.all(func(g:Dictionary)->bool: return String(g.get("role",""))!="")
	var out:={"how":how,"groups":groups,"share":_share(span),"count":_number(span,groups),"text":clean.substr(0,300),"own":own,"home":home,"settlement_id":String(town.get("id",""))}
	if own or trades_only:
		out["kind"]="act"; return out
	var id:=String(audience.get("id",""))
	var held:=WarOrders.held_towns()
	if not held.is_empty():
		# A town we hold that this audience is speaking of: its people (the war
		# orders, town_fate.gd). Named nowhere, the words with no place in them
		# are the town we hold as before; "the village" is asked.
		if not WarOrders._town_in_audience(held,id).is_empty() or _town_order_recent(audience): return {}
		if not place: return {}
		out["kind"]="ask"; out["options"]=_options(held,home); out["question"]=_question(out,held)
		return out
	# A town of theirs this audience speaks of: what it would take (take_first).
	if not WarOrders._place_in_audience(id).is_empty(): return {}
	var at_war:=_any_war()
	if at_war or _feud():
		# At war with none of theirs held: "kill all the men" is answered by the
		# war leader (nobody of theirs is in our hands); "the village" is asked.
		# In a feud (no war declared) whose women are meant is asked as well.
		if at_war and not place: return {}
		out["kind"]="ask"; out["options"]=_options([],home); out["question"]=_question(out,[])
		return out
	out["kind"]="act"
	return out

static func _our_town(span:String,list:Array[Dictionary])->Dictionary:
	## The town of ours the order falls on: {id ("" for home, whose people are the
	## realm's own count), name, named (said outright)}. A town of ours named in
	## the words; else the town whose leader stands before the god; else home.
	var home:={"id":"","name":String(GameState.settlement_name) if String(GameState.settlement_name)!="" else "our village","named":false}
	for s in GameState.player_settlements:
		if not s is Dictionary: continue
		var name:=String((s as Dictionary).get("name",""))
		if name=="" or not WarOrders._name_hit(span,name): continue
		if bool((s as Dictionary).get("primary",false)): return {"id":"","name":String(home.name),"named":true}
		return {"id":String((s as Dictionary).get("id","")),"name":name,"named":true}
	if String(GameState.settlement_name)!="" and WarOrders._name_hit(span,String(GameState.settlement_name)): return {"id":"","name":String(home.name),"named":true}
	for e:Dictionary in list:
		if not bool(e.get("speaker",false)) or String(e.get("office_key",""))!="settlement": continue
		var sid:=String(e.get("settlement_id",""))
		for s in GameState.player_settlements:
			if s is Dictionary and String((s as Dictionary).get("id",""))==sid and not bool((s as Dictionary).get("primary",false)) and String((s as Dictionary).get("name",""))!="":
				return {"id":sid,"name":String((s as Dictionary).name),"named":false}
	return home

static func _scoped(settlement_id:String,operation:Callable)->Variant:
	## Done among that town's own people (SettlementModel's local count, which
	## the daily births and deaths read), then folded back into the realm's.
	var model:Variant=WorldSimulation.settlements if WorldSimulation.settlements!=null else SettlementModel
	var local:=func()->Variant: return model.with_local_population(operation,true)
	if settlement_id!="": return model.with_city_resources(settlement_id,local)
	return local.call()

static func _verb(lower:String)->Dictionary:
	var best:Dictionary={}
	for pair in [["kill",KILL_RE],["burn",BURN_RE],["drive",DRIVE_RE]]:
		var m:=_re(String(pair[1])).search(lower)
		if m!=null and (best.is_empty() or m.get_start()<int(best.at)): best={"how":String(pair[0]),"at":m.get_start(),"end":m.get_end()}
	return best

static func _span(lower:String,at:int)->String:
	## The words the act falls on: from its verb up to the next order.
	var span:=lower.substr(at)
	var own_verb:=_verb(span)
	var from:=int(own_verb.get("end",0))
	var cut:=span.length()
	for m in _re(NEXT_RE).search_all(span,from):
		var before:=span.substr(0,m.get_start()).strip_edges()
		# "the women who take water", "those that hold the gate": inside the object.
		if before.ends_with(" who") or before.ends_with(" that") or before.ends_with(" which"): continue
		cut=m.get_start(); break
	return span.substr(0,cut).strip_edges()

static func _one_person(span:String,list:Array[Dictionary],cc:GDScript)->bool:
	## One person named ("Kavu", "the headman", "him"): a person act, not this.
	if list.is_empty(): return _has(span,"\\b(him|her|you|yourself|himself|herself)\\b")
	for m:Dictionary in cc.call("mentions",span,list):
		if String(m.by) in ["name","title"] and String(m.get("of",""))=="": return true
		if String(m.by)=="pronoun" and String(m.word) in ["him","her","you","yourself","himself","herself","this one","that one"]: return true
	return false

static func _group_row(row:Array)->Dictionary:
	return {"id":String(row[0]),"cohorts":(row[2] as Array).duplicate(),"sex":String(row[3]),"words":String(row[4]),"weight":float(row[5])}

static func _groups(span:String)->Array:
	## The groups the words name ("the women and children"), each once; "the
	## old men" is never also "the men", and everyone is everyone.
	var out:Array=[]
	var taken:=span.replace("old women","old_w").replace("old woman","old_w").replace("old men","old_m").replace("old man","old_m").replace("old wives","old_w").replace("old mothers","old_w").replace("old males","old_m")
	for row in GROUPS:
		var pattern:=String(row[1])
		var hit:=false
		match String(row[0]):
			"old_women": hit=_has(taken,"\\bold_w\\b")
			"old_men": hit=_has(taken,"\\bold_m\\b")
			_: hit=_has(taken,"(?i)"+pattern)
		if not hit: continue
		if String(row[0])=="everyone": return [_group_row(row)]
		out.append(_group_row(row))
	# "The girls and the boys" are the children; "children" with either is the children.
	var ids:=out.map(func(g:Dictionary)->String: return String(g.id))
	if "children" in ids: out=out.filter(func(g:Dictionary)->bool: return not String(g.id) in ["girls","boys"])
	elif "girls" in ids and "boys" in ids:
		out=out.filter(func(g:Dictionary)->bool: return not String(g.id) in ["girls","boys"])
		out.append(_group_row(GROUPS[5]))
	for row in TRADES:
		if _has(span,"(?i)"+String(row[1])): out.append({"id":String(row[0]),"cohorts":WORKING.duplicate(),"sex":"","words":String(row[3]),"weight":0.08,"role":String(row[2])})
	return out

static func _share(span:String)->float:
	for pair in PARTS:
		if _has(span,"(?i)"+String(pair[0])): return float(pair[1])
	return 1.0

static func _number(span:String,groups:Array)->int:
	## A count asked for ("kill 20 of the women", "kill ten farmers"), or 0.
	if groups.is_empty(): return 0
	var m:=_re("(?i)\\b(\\d{1,7}|a few|a dozen|a score|a hundred|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|fifteen|twenty|thirty|forty|fifty|sixty|hundred)\\s+(of\\s+(the|our|my|its)\\s+)?(\\w+\\s+)?(old |little |young )?(women|woman|men|man|males|females|children|kids|boys|girls|people|villagers|elders|old|ones|farmers|hunters|herders|fishers|builders|craftsmen|potters|weavers|carriers|families|households)\\b").search(span)
	if m==null: return 0
	var word:=m.get_string(1).to_lower()
	return int(word) if word.is_valid_int() else int(NUMBER_WORDS.get(word,0))

static func _town_order_recent(audience:Dictionary)->bool:
	var last:Dictionary=audience.get("town_order",{}) if audience.get("town_order") is Dictionary else {}
	return not last.is_empty() and _day()-int(last.get("day",-99))<=PENDING_DAYS

static func _any_war()->bool:
	if WorldSimulation.world==null: return false
	for c in WorldSimulation.world.civilizations:
		if not c is Dictionary: continue
		var rel:Dictionary=(c as Dictionary).get("player_relation",{}) if (c as Dictionary).get("player_relation") is Dictionary else {}
		if bool(rel.get("at_war",false)): return true
	return false

static func _feuding(civ_id:String)->bool:
	## A blood feud with a small people (war_loop.gd): fighting, no war declared.
	var war_loop:=load("res://scripts/war_loop.gd") as GDScript
	return war_loop!=null and civ_id!="" and bool(war_loop.call("feuding",civ_id))

static func _feud()->bool:
	if WorldSimulation.world==null: return false
	for c in WorldSimulation.world.civilizations:
		if c is Dictionary and String((c as Dictionary).get("id",""))!="player" and _feuding(String((c as Dictionary).get("id",""))): return true
	return false

static func _foe_name()->String:
	if WorldSimulation.world==null: return ""
	for c in WorldSimulation.world.civilizations:
		if not c is Dictionary or String((c as Dictionary).get("id",""))=="player": continue
		var rel:Dictionary=(c as Dictionary).get("player_relation",{}) if (c as Dictionary).get("player_relation") is Dictionary else {}
		if bool(rel.get("at_war",false)) or _feuding(String((c as Dictionary).get("id",""))): return String((c as Dictionary).get("name",""))
	return ""

static func _options(held:Array,home:String="")->Array:
	var out:Array=[{"id":"own","name":home if home!="" else String(GameState.settlement_name)}]
	for t in held: out.append({"id":"town","city_id":String((t as Dictionary).city_id),"name":String((t as Dictionary).name)})
	return out

static func _question(r:Dictionary,held:Array)->String:
	var home:=String(r.get("home","")) if String(r.get("home",""))!="" else "our own village"
	if held.is_empty():
		var foe:=_foe_name()
		return "Which village do you mean: %s, our own? We hold no town of %s; none of their people are in our hands." % [home,("the "+foe) if foe!="" else "theirs"]
	var names:=PackedStringArray()
	for t in held: names.append(String((t as Dictionary).name))
	return "Which village do you mean: %s, our own, or %s, which we hold?" % [home," or ".join(names)]

# --------------------------------------------------------------------------
# Answers, insistence
# --------------------------------------------------------------------------

static func _pending(audience:Dictionary)->Dictionary:
	var p:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
	if String(p.get("verb",""))!=PENDING_VERB or _day()-int(p.get("day",-99))>PENDING_DAYS: return {}
	return p

static func answer(id:String,audience:Dictionary,list:Array[Dictionary],clean:String,context:Dictionary)->Dictionary:
	## The god's answer to "Which village do you mean?": our own (it is done
	## here, adjudicated), a town we hold or theirs (the war orders), or no.
	## {} when these words answer nothing of ours.
	var p:=_pending(audience)
	if p.is_empty() or String(p.get("ask",""))!="which_people": return {}
	var lower:=clean.to_lower().strip_edges()
	if lower=="" or lower.ends_with("?"): return {}
	var stored:Dictionary=(p.get("reading",{}) as Dictionary).duplicate(true)
	var cc:=_cc()
	var held_back:=false
	for part:Dictionary in Realm.clauses(clean):
		if bool(part.held): held_back=true
	if held_back or _has(lower,"^\\W*(no|nope|nay|neither|none|nobody|no one|never mind|forget it|leave (it|them)|not now)\\b"):
		audience.erase("pending_command")
		return cc.call("_plain_answer",id,audience,clean,context,"Nothing is done to anyone.")
	var options:Array=p.get("options",[])
	var home:=String((options[0] as Dictionary).get("name","")).to_lower() if not options.is_empty() else String(GameState.settlement_name).to_lower()
	for o in options:
		var opt:Dictionary=o
		if String(opt.get("id",""))=="town" and WarOrders._name_hit(lower,String(opt.get("name",""))):
			return _to_town(id,audience,list,clean,context,stored,WarOrders._held_town(String(opt.get("city_id",""))))
	# A town of theirs we do not hold, named: what it would take (the war orders).
	for t:Dictionary in WarOrders.known_places():
		if WarOrders._name_hit(lower,String(t.name)): return _to_town(id,audience,list,clean,context,stored,t)
	# A people named (a feud's raiders, a people at war): theirs, by the war orders.
	if WorldSimulation.world!=null:
		for c in WorldSimulation.world.civilizations:
			if c is Dictionary and String((c as Dictionary).get("id",""))!="player" and WarOrders._name_hit(lower,String((c as Dictionary).get("name",""))):
				return _to_town(id,audience,list,clean,context,stored,{"name":String((c as Dictionary).name),"civ_id":String((c as Dictionary).id)})
	var ordinal:=_re("(?i)\\b(first|1st|the first one)\\b").search(lower)!=null
	var second:=_re("(?i)\\b(second|2nd|last|the other|theirs|the one we (hold|took))\\b").search(lower)!=null
	if second and options.size()>1:
		var opt2:Dictionary=options[1]
		return _to_town(id,audience,list,clean,context,stored,WarOrders._held_town(String(opt2.get("city_id",""))))
	if ordinal or _has(lower,"\\b(our own|ours|our (vill?age|town|camp|people|home|settlement)|my (vill?age|town|people|home)|home|here|us|our)\\b") or (home!="" and WarOrders._name_hit(lower,home)):
		stored["kind"]="act"; stored["own"]=true
		audience.erase("pending_command")
		return carry(id,audience,list,stored,false,context,clean)
	return {}

static func insisted(id:String,audience:Dictionary,list:Array[Dictionary],clean:String,context:Dictionary)->Dictionary:
	## "Do it", "I demand it" with an order of ours waiting: after a plea it is
	## carried out; after "Which village?" it is still not said which.
	var p:=_pending(audience)
	if p.is_empty(): return {}
	var stored:Dictionary=(p.get("reading",{}) as Dictionary).duplicate(true)
	if String(p.get("ask",""))=="which_people":
		return _cc().call("_plain_answer",id,audience,clean,context,"Nothing is done until you say which village: %s." % _option_words(p.get("options",[]) as Array),true)
	if not bool(p.get("hesitate",false)) or stored.is_empty(): return {}
	audience.erase("pending_command")
	stored["kind"]="act"
	return carry(id,audience,list,stored,true,context,clean)

static func _option_words(options:Array)->String:
	var names:=PackedStringArray()
	for o in options: names.append(String((o as Dictionary).get("name","")))
	return " or ".join(names)

static func _to_town(id:String,audience:Dictionary,list:Array[Dictionary],clean:String,context:Dictionary,stored:Dictionary,town:Dictionary)->Dictionary:
	## The answer named a town not ours to strike: the order as the war orders
	## read it for that town (its fate when we hold it, else what it would take).
	audience.erase("pending_command")
	var cc:=_cc()
	var said:=String(stored.get("text",""))
	var name:=String(town.get("name","")).trim_prefix("Reported home of ")
	var lower:=said.to_lower()
	var named:=_re(VILLAGE_RE).sub(said,"of "+name,false) if _has(lower,VILLAGE_RE) else "%s of %s" % [said,name]
	var civ:=String(audience.get("civ_id",""))
	var war:Dictionary
	if String(stored.get("how",""))=="kill": war=WarOrders.group_harm_reading(named,"kill","",civ,id)
	else: war=WarOrders.read(named,civ,id)
	if war.is_empty(): return cc.call("_plain_answer",id,audience,clean,context,"Nothing is done: the war leader can make nothing of that order for %s." % name)
	var cls:Dictionary=cc.call("classify",named)
	cls["act"]="command"; cls["verb"]="war"; cls["war"]=war; cls["text"]=named
	return cc.call("_perform",id,audience,list,"war",cc.call("_speaker_entry",list),{},clean,cls,false,context)

# --------------------------------------------------------------------------
# The odds (stated in every report)
# --------------------------------------------------------------------------

static func refusal_odds(person:Dictionary,how:String,weight:float,insist:bool)->float:
	## The chance the one ordered will not do this to their own people at all:
	## the tender-hearted, the brave and those who love the people refuse;
	## dread of the god keeps them at it; the god's insistence halves it.
	if person.is_empty(): return 0.0
	var personality:Dictionary=person.get("personality",{}) if person.get("personality") is Dictionary else {}
	var empathy:=clampf(float(personality.get("empathy",0.5)),0.0,1.0)
	var courage:=clampf(float(person.get("courage",0.5)),0.0,1.0)
	var dread:=DIVINE.dread_of(person)
	var love:=DIVINE.love_of(person)
	var p:=0.02+0.22*empathy+0.10*courage+0.06*love-0.30*dread
	p*=clampf(weight/0.15,0.5,1.5)
	if how=="drive": p*=0.5
	if insist: p*=0.5
	return clampf(p,0.0,0.6)

static func hand_refusal_odds(how:String,weight:float,people:Dictionary)->float:
	## Each hand's chance to refuse: worse the more defenceless those named,
	## less where the god is dreaded.
	var base:=weight
	if how=="burn": base=0.06
	elif how=="drive": base=weight*0.5
	return clampf(base+0.2*float(people.get("love",0.5))-0.25*float(people.get("dread",0.1)),0.02,0.6)

static func catch_odds(hands:int,victims:int)->float:
	## Each one named is caught (or found): our hands against their number, as
	## town_fate.catch_odds, within what such killings show.
	if victims<=0: return 1.0
	return clampf(0.7+0.2*(clampf(float(hands)*3.0/float(victims),0.0,1.5)-1.0),0.35,0.92)

static func flight_odds(lost:int,before:int,people:Dictionary,how:String)->float:
	## Of the rest of the people, the share who flee the realm afterwards.
	var weight:=float(lost)/maxf(1.0,float(before))
	var p:=(0.02+0.6*weight)*(1.4-float(people.get("love",0.5)))
	if how=="drive": p*=0.5
	return clampf(p,0.005,0.25)

static func _rng(id:String,said:String,salt:String)->RandomNumberGenerator:
	## A roll reproducible from the save: the world, the audience, the day and the words.
	var r:=RandomNumberGenerator.new()
	r.seed=hash("grave_home|%d|%s|%d|%s|%s" % [int(GameState.world_seed),id,_day(),said.to_lower().strip_edges(),salt])
	return r

static func _binom(r:RandomNumberGenerator,n:int,p:float)->int:
	## How many of n, each with chance p (one seeded roll each; a large people
	## by the same law's normal form, bounded the same).
	if n<=0 or p<=0.0: return 0
	if p>=1.0: return n
	if n<=2000:
		var k:=0
		for i in n:
			if r.randf()<p: k+=1
		return k
	return clampi(roundi(r.randfn(float(n)*p,sqrt(float(n)*p*(1.0-p)))),0,n)

# --------------------------------------------------------------------------
# Who is in the ledger
# --------------------------------------------------------------------------

static func group_count(g:Dictionary)->int:
	## How many of a group the population model holds: the age cohorts named,
	## the women or men among them, those at a kind of work.
	var total:=0.0
	for c in g.get("cohorts",[]): total+=maxf(0.0,float(GameState.population_cohorts.get(String(c),0.0)))
	var sex:=String(g.get("sex",""))
	if sex!="":
		var children_only:=(g.get("cohorts",[]) as Array)==["children"]
		var share:=GameState.BIRTH_FEMALE_SHARE if children_only else GameState.adult_female_share()
		total*=share if sex=="female" else 1.0-share
	var role:=String(g.get("role",""))
	if role!="": total=minf(total,float(GameState.population_allocations.get(role,0)))
	return maxi(0,mini(floori(total+0.000001),GameState.population_total-1))

static func hands()->Dictionary:
	## Who carries it out: our fighters at home, else the watch, else a few men
	## the official gathers. {n, who, words, home, bands:[[army_id,n]]}.
	var home_n:=maxi(0,int(MilitaryCampaign.home_army.get("troops",0)))
	var bands:Array=[]
	var band_n:=0
	for a in MilitaryCampaign.field_armies:
		if not a is Dictionary or int((a as Dictionary).get("troops",0))<=0: continue
		if WarOrders._at_home(a as Dictionary):
			bands.append([int((a as Dictionary).get("army_id",0)),int((a as Dictionary).troops)]); band_n+=int((a as Dictionary).troops)
	if home_n+band_n>0: return {"n":home_n+band_n,"who":"fighters","words":"fighters at home","home":home_n,"bands":bands}
	var watch:=int(GameState.population_allocations.get("Defense",0))
	if watch>0: return {"n":watch,"who":"watch","words":"of the watch","home":0,"bands":[]}
	return {"n":clampi(roundi(float(GameState.able_population())*0.03),2,12),"who":"gathered","words":"men gathered for it","home":0,"bands":[]}

static func _hands_flee(h:Dictionary,n:int)->int:
	## Hands who fled the realm rather than do it: out of their bands, with their
	## gear, and out of the people's count. Returns those gone.
	if n<=0: return 0
	var left:=n
	if String(h.get("who",""))=="fighters":
		var from_home:=mini(left,int(MilitaryCampaign.home_army.get("troops",0)))
		if from_home>0:
			MilitaryCampaign._detach_occupation_formations(from_home)
			left-=from_home
		for pair in h.get("bands",[]):
			if left<=0: break
			var take:=mini(left,int(pair[1]))
			if MilitaryCampaign._field_army_index(int(pair[0]))<0 or take<=0: continue
			# The band's own record loses them, with their gear (its troops too).
			MilitaryCampaign._detach_field_army_formations(int(pair[0]),take)
			left-=take
	# The watch, or men gathered for it, are ordinary people: all of them go.
	var going:=n-left if String(h.get("who",""))=="fighters" else n
	var gone:Dictionary=GameState.register_population_departures(going,"Fled rather than kill their own people",{"youth":1.0,"early_adults":1.0,"established_adults":1.0,"mature_adults":0.5})
	return int(gone.get("count",0))

# --------------------------------------------------------------------------
# Carrying it out
# --------------------------------------------------------------------------

static func carry(id:String,audience:Dictionary,list:Array[Dictionary],r_in:Dictionary,insist:bool,context:Dictionary,said:String="")->Dictionary:
	## The god's grave order on our own people, decided and carried out (or
	## asked about). said: the words just spoken (an answer, "do it"), else the
	## order itself.
	var cc:=_cc()
	var words:=said if said!="" else String(r_in.get("text",""))
	cc.call("_echo",id,audience,words,context)
	var speaker:Dictionary=cc.call("_speaker_entry",list)
	var actor:=_actor(list,speaker,cc)
	var r:Dictionary=cc.call("_result",VERB,actor,{},String(r_in.get("text",words)),insist)
	r.verb=VERB; r.reaction="grave"
	r["grave_home"]={"how":String(r_in.get("how","")),"kind":String(r_in.get("kind",""))}
	if String(r_in.get("kind",""))=="ask":
		# The same unclear order again after the question: not asked twice.
		var open:=_pending(audience)
		if not open.is_empty() and String(open.get("ask",""))=="which_people":
			return cc.call("_plain_answer",id,audience,words,{"echoed":true},"Nothing is done until you say which village: %s." % _option_words(open.get("options",[]) as Array))
		audience["pending_command"]={"verb":PENDING_VERB,"ask":"which_people","actor":String(actor.get("key","")),"target":"","day":_day(),"text":String(r_in.text),"reading":r_in.duplicate(true),"options":(r_in.get("options",[]) as Array).duplicate(true),"question":String(r_in.get("question",""))}
		r.stage="grave_ask"; r.executed=false; r.reaction="neutral"
		r.actor=speaker.duplicate(); r.actor_name=String(speaker.get("name",""))
		r.obedience={"id":"object","manner":"plain","chance":0.0}
		r["actor_says"]=String(r_in.get("question",""))
		r.outcome="Nothing is done yet: the court waits to hear which village you mean."
		return r
	audience.erase("pending_command")
	var how:=String(r_in.get("how","kill"))
	var weight:=0.0
	for g in r_in.get("groups",[]): weight=maxf(weight,float((g as Dictionary).get("weight",0.1)))
	if how=="burn": weight=0.1
	var rng:=_rng(id,String(r_in.get("text","")),"order")
	# The one ordered: obey, plead or refuse (court_commands.obedience), then the
	# chance anyone refuses this to their own people.
	var person:Dictionary=cc.call("_person",actor)
	var ob:Dictionary=cc.call("obedience",person,"exile" if how=="drive" else "kill",insist,rng.randf())
	r.obedience=ob
	var label:=_label(r_in)
	if String(ob.get("id",""))=="refuse":
		var refused:Dictionary=cc.call("_refusal",id,audience,list,r,person,"kill")
		refused.verb=VERB
		refused.outcome=String(refused.outcome)+" Nothing was done to %s." % label
		return refused
	if String(ob.get("id",""))=="hesitate":
		audience["pending_command"]={"verb":PENDING_VERB,"hesitate":true,"actor":String(actor.get("key","")),"target":"","day":_day(),"text":String(r_in.get("text","")),"reading":r_in.duplicate(true)}
		r.stage="grave_hesitate"; r.executed=false; r.reaction="troubled"
		r.outcome="%s has not done it. They hold back and plead for %s; your word still stands." % [String(actor.get("name","The one you ordered")),label]
		return r
	var p_refuse:=refusal_odds(person,how,weight,insist)
	r["refusal_odds"]=p_refuse
	if not person.is_empty() and rng.randf()<p_refuse:
		r.obedience={"id":"refuse","manner":"stricken","chance":p_refuse}
		var refused2:Dictionary=cc.call("_refusal",id,audience,list,r,person,"kill")
		refused2.verb=VERB
		refused2.outcome="%s would not do it to our own people (a chance of %s). %s Nothing was done to %s." % [String(person.get("name","They")),Ledger.chance_words(p_refuse),String(refused2.outcome),label]
		return refused2
	var done:Dictionary
	# Among the town's own people (its local count), then the realm's; every
	# number reported is what the ledger moved.
	var realm_before:=int(GameState.population_total)
	var sid:=String(r_in.get("settlement_id",""))
	if how=="burn": done=_scoped(sid,func()->Dictionary: return _burn(id,r_in,rng))
	else: done=_scoped(sid,func()->Dictionary: return _cull(id,r_in,rng))
	GameState.synchronize_population_allocations()
	done["population_before"]=realm_before; done["population_after"]=int(GameState.population_total)
	r["grave_home"]=done
	var lead:=_obeyed_words(actor,ob)
	# The chance they would have refused, all told (their own nature's, then this).
	var refuse_all:=float(ob.get("chance",0.0))+(1.0-float(ob.get("chance",0.0)))*p_refuse
	if lead!="" and not person.is_empty(): lead=lead.trim_suffix(".")+" (the chance they would refuse it: %s)." % Ledger.chance_words(refuse_all)
	r.outcome=(lead+" "+String(done.get("words",""))).strip_edges()
	r.executed=bool(done.get("ok",false))
	r.stage=VERB if r.executed else ("refuse_hands" if int(done.get("willing",1))<=0 else "none")
	r["actor_says"]=_actor_says(done,ob,r_in)
	r.witness_ids=cc.call("_witness_ids",id,[])
	if r.executed: _consequences(id,actor,ob,r_in,done)
	elif int(done.get("hands_fled",0))>0:
		DIVINE.record_people_act("terrify_people")
	return r

static func _actor(list:Array[Dictionary],speaker:Dictionary,cc:GDScript)->Dictionary:
	## The one ordered: the one before the god when they hold office or lead
	## men, else the headman, else the war leader.
	if String(speaker.get("kind","")) in ["official","figure"]: return speaker
	for office in ["Steward","Marshal"]:
		var p:Dictionary=GovernmentPeopleSystem.officeholder(office)
		if not p.is_empty():
			var e:Dictionary=cc.call("_entry",list,"person:%d" % int(p.person_id))
			if not e.is_empty(): return e
	return {}

static func _label(r_in:Dictionary)->String:
	## "the women of Seanstone", "half the farmers of Seanstone", "Seanstone".
	var home:=String(r_in.get("home","")) if String(r_in.get("home",""))!="" else (String(GameState.settlement_name) if String(GameState.settlement_name)!="" else "our village")
	if String(r_in.get("how",""))=="burn": return home
	var names:=PackedStringArray()
	for g in r_in.get("groups",[]): names.append(String((g as Dictionary).get("words","people")))
	var who:=" and ".join(names) if not names.is_empty() else "people"
	return "%sthe %s of %s" % [_part_words(r_in),who,home]

static func _part_words(r_in:Dictionary)->String:
	## "half ", "a third of ", "20 of ", or "" for all of them.
	if int(r_in.get("count",0))>0: return "%d of " % int(r_in.count)
	var share:=float(r_in.get("share",1.0))
	if share>=0.99: return ""
	if share>=0.74: return "most of "
	if share>=0.6: return "two thirds of "
	if share>=0.49: return "half "
	if share>=0.3: return "a third of "
	if share>=0.24: return "a quarter of "
	if share>=0.19: return "some of "
	return "a tenth of "

static func _obeyed_words(actor:Dictionary,ob:Dictionary)->String:
	var name:=String(actor.get("name",""))
	if name=="": return ""
	match String(ob.get("id","obey")):
		"reluctant": return "%s obeyed, though it cost them." % name
		_: return "%s obeyed%s." % [name,", trembling" if String(ob.get("manner",""))=="trembling" else ""]

static func _actor_says(done:Dictionary,ob:Dictionary,_r_in:Dictionary)->String:
	## The one ordered, in plain words, from the numbers decided.
	if int(done.get("willing",1))<=0:
		return "None of them would do it. %s" % ("%d fled the realm rather than do it." % int(done.hands_fled) if int(done.get("hands_fled",0))>0 else "They stand where they are and look at the ground.")
	if not bool(done.get("ok",false)): return ""
	var reluctant:=String(ob.get("id",""))=="reluctant"
	var lead:="It is done, as you commanded; I will carry it all my days." if reluctant else "It is done."
	match String(done.get("how","")):
		"burn": return "%s %s burned. %s" % [lead,String(done.get("home","The village")),("%d died in the fires." % int(done.dead)) if int(done.get("dead",0))>0 else "Nobody died in the fires."]
		"drive": return "%s %d of them are gone from the realm." % [lead,int(done.get("moved",0))]
	var away:=int(done.get("escaped",0))+int(done.get("hid",0))
	return "%s %d are dead. %s" % [lead,int(done.get("dead",0)),("%d got away." % away) if away>0 else "None got away."]

static func _hands_step(h:Dictionary,how:String,weight:float,people:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var n:=int(h.n)
	var p:=hand_refusal_odds(how,weight,people)
	var refused:=_binom(rng,n,p)
	var fleeing:=_binom(rng,refused,HAND_FLEE)
	var fled:=_hands_flee(h,fleeing)
	return {"n":n,"p":p,"refused":refused,"fled":fled,"willing":n-refused}

static func _hands_words(h:Dictionary,s:Dictionary)->String:
	var who:="%s %s" % [_count(int(s.n)),String(h.words)]
	var t:="%s were given the order (the chance each refuses: %s)" % [_cap(who),Ledger.chance_words(float(s.p))]
	if int(s.refused)<=0: return t+"; none refused."
	t+=": %s would not do it" % _count(int(s.refused))
	if int(s.fled)>0: t+=", and %s of them fled the realm rather than do it" % _count(int(s.fled))
	return t+"."

static func _cull(_id:String,r_in:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	## Killing or driving out the groups named, on stated odds, through the
	## population model. Every number reported is what the ledger moved.
	var how:=String(r_in.get("how","kill"))
	var home:=String(r_in.get("home","")) if String(r_in.get("home",""))!="" else (String(GameState.settlement_name) if String(GameState.settlement_name)!="" else "the village")
	var people:=DIVINE.people_regard(Hall._officials())
	var pop_before:=int(GameState.population_total)
	var fertile_before:=GameState.fertile_women()
	var weight:=0.0
	for g in r_in.get("groups",[]): weight=maxf(weight,float((g as Dictionary).get("weight",0.1)))
	var h:=hands()
	var hs:=_hands_step(h,how,weight,people,rng)
	var out:={"ok":false,"how":how,"home":home,"hands":int(hs.n),"hand_odds":float(hs.p),"refused":int(hs.refused),"hands_fled":int(hs.fled),"willing":int(hs.willing),
		"targets":0,"dead":0,"moved":0,"escaped":0,"hid":0,"kin_fled":0,"pregnancies_lost":0,"population_before":pop_before,"by_group":{}}
	var parts:=PackedStringArray([_hands_words(h,hs)])
	if int(hs.willing)<=0:
		parts.append("Nothing was done to %s." % _label(r_in))
		out["population_after"]=int(GameState.population_total)
		out["words"]=" ".join(parts)
		return out
	# Whom: each group's own count, the part asked for.
	var rows:Array=[]
	var total:=0
	var asked:=int(r_in.get("count",0))
	var share:=float(r_in.get("share",1.0))
	var have:=0
	for g in r_in.get("groups",[]): have+=group_count(g as Dictionary)
	for g in r_in.get("groups",[]):
		var n:=group_count(g as Dictionary)
		var want:=roundi(float(n)*share) if asked<=0 else (roundi(float(asked)*float(n)/float(maxi(1,have))))
		want=clampi(want,0,n)
		rows.append({"g":g,"have":n,"want":want}); total+=want
	if total<=0:
		parts.append("There are no %s in %s to %s." % [_label_words(r_in),home,"kill" if how=="kill" else "drive out"])
		out["population_after"]=int(GameState.population_total)
		out["words"]=" ".join(parts)
		return out
	var willing:=int(hs.willing)
	var p:=catch_odds(willing,total)
	var cap:=willing*(KILLS_PER_HAND if how=="kill" else DRIVE_PER_HAND)*DAYS_MAX
	var caught_total:=0
	for row in rows:
		row["caught"]=_binom(rng,int(row.want),p); caught_total+=int(row.caught)
	# A few hands do a few days' work; the rest run or hide before they come.
	if caught_total>cap:
		var scale:=float(cap)/float(caught_total)
		caught_total=0
		for row in rows:
			row["caught"]=floori(float(row.caught)*scale); caught_total+=int(row.caught)
	var dead:=0; var moved:=0; var escaped:=0; var hid:=0
	for row in rows:
		var g:Dictionary=row.g
		var weights:={}
		for c in ALL: weights[c]=1.0 if (g.cohorts as Array).has(c) else 0.0
		var target:={"age_cohorts":(g.cohorts as Array).duplicate(),"label":"%s of %s" % [String(g.words),home]}
		if String(g.sex)!="": target["sex"]=String(g.sex)
		var caught:=int(row.caught)
		var rest:=int(row.want)-caught
		if how=="kill":
			if caught>0:
				var died:Dictionary=GameState.register_directive_population_deaths(caught,DEATH_ID,"%d %s of %s were killed at the god's word." % [caught,String(g.words),home],target)
				row["dead"]=int(died.get("count",0)); dead+=int(row.dead)
			# Those not caught run as it begins: most leave the realm, the rest
			# hide with kin in the hills and stay (ESCAPED_LEAVE, a roll each).
			if rest>0:
				var leaving:=_binom(rng,rest,ESCAPED_LEAVE)
				if leaving>0:
					var ran:Dictionary=GameState.register_population_departures(leaving,"Fled the killing at the god's word",weights,String(g.sex))
					row["escaped"]=int(ran.get("count",0)); escaped+=int(row.escaped)
				row["hid"]=rest-leaving; hid+=rest-leaving
		else:
			if caught>0:
				var gone:Dictionary=GameState.register_population_departures(caught,"Driven out at the god's word",weights,String(g.sex))
				row["moved"]=int(gone.get("count",0)); moved+=int(row.moved)
			# Those not found hide with kin and stay.
			row["hid"]=rest; hid+=rest
		(out.by_group as Dictionary)[String(g.id)]={"words":String(g.words),"have":int(row.have),"asked":int(row.want),"dead":int(row.get("dead",0)),"moved":int(row.get("moved",0)),"escaped":int(row.get("escaped",0)),"hid":int(row.get("hid",0))}
	# The rest of the people: a share flees the realm after it, the more the
	# more of their kin were killed or driven out.
	var fp:=flight_odds(dead+moved,pop_before,people,how)
	var rest_people:=maxi(0,int(GameState.population_total)-1)
	var kin:=_binom(rng,rest_people,fp)
	var kin_gone:=0
	if kin>0: kin_gone=int(GameState.register_population_departures(kin,"Fled the realm after the god's killing" if how=="kill" else "Left the realm after the god's driving out",{"children":1.0,"youth":1.0,"early_adults":1.0,"established_adults":1.0,"mature_adults":1.0,"elders":1.0}).get("count",0))
	# Women killed or gone take their pregnancies with them.
	var fertile_after:=GameState.fertile_women()
	var share_lost:=clampf(1.0-fertile_after/maxf(0.000001,fertile_before),0.0,1.0) if fertile_before>0.0 else 0.0
	var preg_lost:=0
	if share_lost>=0.001: preg_lost=roundi(GameState.lose_pregnancies(share_lost))
	GameState.synchronize_population_allocations()
	var days:=ceili(float(dead+moved)/float(maxi(1,willing*(KILLS_PER_HAND if how=="kill" else DRIVE_PER_HAND))))
	out.ok=dead+moved>0
	out.targets=total; out.dead=dead; out.moved=moved; out.escaped=escaped; out.hid=hid; out.kin_fled=kin_gone; out.pregnancies_lost=preg_lost
	out["catch_odds"]=p; out["flight_odds"]=fp; out["days"]=days
	out["fertile_before"]=roundi(fertile_before); out["fertile_after"]=roundi(fertile_after)
	out["population_after"]=int(GameState.population_total)
	var who:=_label_words(r_in)
	var t:="%s went through %s against %s %s: %s %s each, %s." % [_cap(_count(willing)),home,_count(total),who,"a good chance to" if p>=0.6 else ("an even chance to" if p>=0.4 else "a poor chance to"),"catch" if how=="kill" else "find",Ledger.chance_words(p)]
	if how=="kill":
		t+=" %s %s were killed%s" % [_cap(_count(dead)),who,(" over %s" % _days(days)) if days>1 else ""]
		if escaped+hid<=0: t+="; none got away."
		else:
			t+="; %s got away" % _count(escaped+hid)
			var away:=PackedStringArray()
			if escaped>0: away.append("%s fled the realm" % _count(escaped))
			if hid>0: away.append("%s hid with kin and stay among us" % _count(hid))
			t+=": "+" and ".join(away)+"."
	else:
		t+=" %s %s were driven out of the realm%s" % [_cap(_count(moved)),who,(" over %s" % _days(days)) if days>1 else ""]
		t+=("; %s hid with kin and stay among us." % _count(hid)) if hid>0 else "."
	parts.append(t)
	if kin_gone>0: parts.append("%s more of our people %s." % [_cap(_count(kin_gone)),"fled the realm after it" if how=="kill" else "went with them"])
	# Mothers among those named: fewer births for as long as the women are fewer.
	var mothers:=(r_in.get("groups",[]) as Array).any(func(g:Dictionary)->bool: return String(g.get("sex",""))!="male" and (g.get("cohorts",[]) as Array).has("early_adults"))
	if mothers and (fertile_before-fertile_after)>=1.0:
		var left:=roundi(fertile_after)
		parts.append("Fewer children will be born for years: of %s women of an age to bear, %s%s." % [_count(roundi(fertile_before)),"none are left" if left<=0 else "%s are left" % _count(left),(", and %s pregnancies were lost with them" % _count(preg_lost)) if preg_lost>0 else ""])
	out["words"]=" ".join(parts)
	return out

static func _label_words(r_in:Dictionary)->String:
	var names:=PackedStringArray()
	for g in r_in.get("groups",[]): names.append(String((g as Dictionary).get("words","people")))
	return " and ".join(names) if not names.is_empty() else "people"

static func _burn(_id:String,r_in:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	## Our own village set on fire by our own hands: the houses, the stores, the
	## few who could not get out, and those who flee after. On stated shares.
	var home:=String(r_in.get("home","")) if String(r_in.get("home",""))!="" else (String(GameState.settlement_name) if String(GameState.settlement_name)!="" else "the village")
	var people:=DIVINE.people_regard(Hall._officials())
	var pop_before:=int(GameState.population_total)
	var h:=hands()
	var hs:=_hands_step(h,"burn",0.1,people,rng)
	var out:={"ok":false,"how":"burn","home":home,"hands":int(hs.n),"hand_odds":float(hs.p),"refused":int(hs.refused),"hands_fled":int(hs.fled),"willing":int(hs.willing),
		"dead":0,"kin_fled":0,"houses_lost":0,"food_lost":0,"timber_lost":0,"population_before":pop_before}
	var parts:=PackedStringArray([_hands_words(h,hs)])
	var willing:=int(hs.willing)
	if willing<=0:
		parts.append("%s was not set on fire." % home)
		out["population_after"]=int(GameState.population_total)
		out["words"]=" ".join(parts)
		return out
	# One hand fires about a dozen people's roofs in a day: a few hands burn a
	# part of a large village, a band most of a small one.
	var houses:=int(GameState.housing_capacity)
	var burned_share:=clampf(0.3+0.55*minf(1.0,float(willing)*12.0/maxf(1.0,float(houses))),0.3,0.85)
	var houses_lost:=roundi(float(houses)*burned_share)
	GameState.housing_capacity=maxi(0,houses-houses_lost)
	var food_share:=rng.randf_range(0.25,0.6)
	var food_lost:=roundi(Hall._debit_player("Food",Hall.player_stock("Food")*food_share))
	var timber:=float(GameState.resource_stockpiles.get("Timber",0.0))
	var timber_lost:=roundi(timber*rng.randf_range(0.3,0.6))
	GameState.resource_stockpiles["Timber"]=maxf(0.0,timber-float(timber_lost))
	# Those who could not get out: a few in a hundred at most.
	var death_share:=rng.randf_range(0.002,0.015)
	var dead:=0
	var want_dead:=_binom(rng,pop_before,death_share)
	if want_dead>0: dead=int(GameState.register_population_deaths(want_dead,"Died when the god's own village was burned").get("count",0))
	var lost_share:=float(houses_lost)/maxf(1.0,float(houses))
	var fp:=clampf((0.04+0.15*lost_share)*(1.4-float(people.get("love",0.5))),0.01,0.3)
	var kin:=_binom(rng,maxi(0,int(GameState.population_total)-1),fp)
	var kin_gone:=0
	if kin>0: kin_gone=int(GameState.register_population_departures(kin,"Fled the realm after the god's burning",{"children":1.0,"youth":1.0,"early_adults":1.0,"established_adults":1.0,"mature_adults":1.0,"elders":1.0}).get("count",0))
	GameState.synchronize_population_allocations()
	out.ok=true
	out.dead=dead; out.kin_fled=kin_gone; out.houses_lost=houses_lost; out.food_lost=food_lost; out.timber_lost=timber_lost
	out["burned_share"]=burned_share; out["flight_odds"]=fp
	out["population_after"]=int(GameState.population_total)
	parts.append("%s set fire to %s: houses for %d of the %d it could shelter burned (about %d in 10), with %d Food and %d Timber from the stores." % [_cap(_count(willing)),home,houses_lost,houses,clampi(roundi(burned_share*10.0),1,9),food_lost,timber_lost])
	parts.append(("%s could not get out and died in the fires." % _cap(_count(dead))) if dead>0 else "Everyone got out of the fires alive.")
	if kin_gone>0: parts.append("%s of our people fled the realm after it." % _cap(_count(kin_gone)))
	out["words"]=" ".join(parts)
	return out

# --------------------------------------------------------------------------
# What lasts
# --------------------------------------------------------------------------

static func _consequences(_id:String,actor:Dictionary,ob:Dictionary,r_in:Dictionary,done:Dictionary)->void:
	var how:=String(done.get("how","kill"))
	var home:=String(done.get("home","the village"))
	var before:=maxi(1,int(done.get("population_before",1)))
	var lost:=int(done.get("dead",0))+int(done.get("moved",0))+int(done.get("escaped",0))+int(done.get("kin_fled",0))
	var weight:=clampf(float(lost)/float(before),0.0,1.0)
	var label:=_label(r_in)
	# The realm: its standing and its cohesion, bounded.
	var metrics:Dictionary=GameState.simulation_metrics
	var legit:=clampf(0.04+0.6*weight,0.04,0.25) if how!="drive" else clampf(0.03+0.4*weight,0.03,0.15)
	var cohesion:=clampf(0.05+0.8*weight,0.05,0.3) if how!="drive" else clampf(0.04+0.5*weight,0.04,0.2)
	if how=="burn": legit=clampf(0.04+0.2*float(done.get("burned_share",0.5)),0.04,0.2); cohesion=clampf(0.05+0.25*float(done.get("burned_share",0.5)),0.05,0.25)
	metrics["legitimacy"]=clampf(float(metrics.get("legitimacy",0.5))-legit,0.01,0.99)
	metrics["cohesion"]=clampf(float(metrics.get("cohesion",0.5))-cohesion,0.01,0.99)
	done["legitimacy_lost"]=legit; done["cohesion_lost"]=cohesion
	# The people: dread and lost love, remembered at every hearth.
	DIVINE.record_people_act(String({"kill":"slaughter_people","burn":"burn_village","drive":"drive_out_people"}.get(how,"slaughter_people")))
	# The court hears what the god ordered done to their own kin.
	var officials:=Hall._officials()
	DIVINE.apply_to_court("cast_out" if how=="drive" else "strike_down",{"person_id":0,"name":label},officials)
	for p:Dictionary in officials:
		var pid:=int(p.get("person_id",0))
		if pid<=0 or pid==int(actor.get("person_id",0)): continue
		GovernmentPeopleSystem.adjust_person_bonds(pid,{"fear":clampf(0.02+0.1*weight,0.02,0.08),"love":-clampf(0.02+0.12*weight,0.02,0.1),"hold_days":120})
	# The one who carried it out carries it after.
	var pid2:=int(actor.get("person_id",0))
	if pid2>0:
		var person:=GovernmentPeopleSystem.person_snapshot(pid2)
		var personality:Dictionary=person.get("personality",{}) if person.get("personality") is Dictionary else {}
		var empathy:=clampf(float(personality.get("empathy",0.5)),0.0,1.0)
		var reluctant:=String(ob.get("id",""))=="reluctant"
		GovernmentPeopleSystem.adjust_person_bonds(pid2,{"fear":0.08,"love":-0.12 if reluctant else -0.06,"obligation":0.02,"resentment":(0.06+0.1*empathy) if reluctant else 0.02+0.04*empathy,"hold_days":180})
		var memory:=""
		match how:
			"burn": memory="At the god's word I had %s, our own village, set on fire; %d died in it." % [home,int(done.get("dead",0))]
			"drive": memory="At the god's word I had %s driven out of the realm: %d of them." % [label,int(done.get("moved",0))]
			_: memory="At the god's word I had %s killed: %d dead." % [label,int(done.get("dead",0))]
		GovernmentPeopleSystem.record_person_memory(pid2,memory,"divine",0.95,{"emotion":"horror" if reluctant else "duty","outcome":"grave_home_"+how})
	elif String(actor.get("kind",""))=="figure":
		HistoricalFigures.note(String(actor.get("figure_id","")),_day(),"At the ruler's word they had %s %s." % [label,String({"burn":"burned","drive":"driven out"}.get(how,"killed"))])
	# Every people that knows us hears of it.
	if WorldSimulation.world!=null:
		for civ in WorldSimulation.world.civilizations:
			if not civ is Dictionary or String((civ as Dictionary).get("id",""))=="player": continue
			if int(((civ as Dictionary).get("player_relation",{}) as Dictionary).get("contact_level",0))<2: continue
			DIVINE.add_civ_dread(String((civ as Dictionary).id),clampf(0.02+0.1*weight,0.02,0.12))
	# One sober Chronicle entry, and the realm's own log.
	var day:=_day()
	var title:=String({"burn":"The Burning of %s" % home,"drive":"The Driving Out of %s" % label}.get(how,"The Killing of %s" % label)).substr(0,70)
	var text:=String(done.get("words",""))
	Chronicle.record({"key":"grave_home:%s:%d:%s" % [how,day,String(r_in.get("text","")).md5_text().substr(0,8)],"title":title,"text":("By the god's word. "+text).substr(0,600),
		"tier":"moment","kind":"story","domain":"demography","priority":true})
	var events:Array=GameState.simulation_events
	events.push_front({"day":day,"title":title,"description":text.substr(0,300),"domain":"population","severity":"major"})
	while events.size()>80: events.pop_back()

# --------------------------------------------------------------------------
# Words
# --------------------------------------------------------------------------

static func _count(n:int)->String:
	return preload("res://scripts/town_fate.gd")._count(n)

static func _days(n:int)->String:
	return "a day" if n<=1 else "%s days" % _count(n)

static func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)
