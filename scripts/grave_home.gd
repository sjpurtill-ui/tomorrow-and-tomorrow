extends RefCounted
## GRAVE ORDERS AGAINST THE GOD'S OWN PEOPLE.
##
## "Kill all women in the village", "kill half the farmers", "burn our own
## village", "banish the old": the god's word against the people who are its
## own. Read here, adjudicated from the one ledger (docs/ADJUDICATION.md) and
## carried out through the real population model (GameState's age cohorts,
## its women by age, the pregnancies, the work), never a counter of its own:
##   1. An order, and only an order. The verb opens the order's own clause
##      (after nothing but a name spoken to, or "I order you to"); never a
##      sentence that forbids, doubts, reports or supposes it ("we must not
##      kill the children", "the elders say we should burn our village", "if
##      the harvest fails, kill the old").
##   2. What it falls on. People, named right after the verb and nothing
##      else (the women, the old, half the farmers, everyone in the village;
##      "the women and the old"): never goats, trees, the dead, time or
##      wolves, and the object ends with the verb's own clause ("kill two goats
##      and feed the children" is no order on the children). People narrowed
##      ("the sick women", "the men who deserted") are asked about: whom
##      exactly. Burning is of the village or town itself; banishing is out
##      of the realm (banish, exile, expel; "drive them out of our lands",
##      "never to return"), never "send the hunters out into the forest".
##   3. Whose people. Ours when the words say so ("our village", Seanstone, our
##      second town named), or when no other people is in our hands and no war
##      or feud is on. A town or people of theirs named, "their"/"them", or a
##      town we hold that this audience is speaking of: the war orders
##      (town_fate.gd), as before. "The village" while we hold a town nobody
##      has spoken of, or at war or in a feud: ONE question, which.
##   4. The read-back. The one ordered says the order back with its numbers
##      ("You would have the 300 women of Seanstone killed?"). It is carried
##      out only on the god's plain yes in the very next line of the same
##      audience (CONFIRM: yes, do it, I demand it, so be it, that is my word).
##      Any other next line drops it and is heard as itself; a yes later, or
##      in another audience, does nothing (next_line, the readback mark).
##   5. The one ordered: court_commands.obedience (obey, plead, refuse), then
##      the stated chance anyone refuses a grave order on their own people
##      (refusal_odds). A plea waits for the god's yes in the very next line
##      only.
##   6. The hands: our fighters at home, else the watch, else a few men the
##      official gathers (men of home). Each may refuse (hand_refusal_odds,
##      one seeded roll each); some of those flee the realm with their gear.
##   7. The people, by age and sex (each person once): each one named is
##      caught on the stated odds (catch_odds); a hand does a day's work
##      (KILLS_PER_HAND, DRIVE_PER_HAND) for at most DAYS_MAX days. Those not
##      caught run: from a killing most leave the realm (ESCAPED_LEAVE), the
##      rest hide with kin; from a banishing they hide and stay.
##   8. The ledger, in that town's own count: deaths and departures by
##      cohort and sex; the pregnancies of the mothers killed or gone; the
##      work of those killed for their work (by each kind's size); the houses
##      and stores burned. Before, less what is reported, is after. A town no
##      longer ours is never struck in its name.
##   9. What lasts: dread and lost love (divine_regard PEOPLE_ACTS), the
##      court's true memory, legitimacy and cohesion, fewer births while the
##      women are fewer, every people that knows us hears of it, a Chronicle
##      moment in plain words, the memory of the one who did it.
## Laws ("execute every thief", "anyone who murders will be put to death")
## stay laws (court_realm_acts.law). The words are plain and never graphic;
## children are counted, never described.
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
const SEXES:=["female","male"]

## Groups of our people a noun may name: [id, pattern, cohorts, sex, words, refusal weight].
const GROUPS:=[
	["old_women","^(old (women|woman|wives|mothers))$",["elders"],"female","old women",0.14],
	["old_men","^(old (men|man|males))$",["elders"],"male","old men",0.12],
	["elders","^(old|aged|elders|elderly|old people|old ones|old folks?|grandmothers|grandfathers|grey ?beards|grey ?heads)$",["elders"],"","old people",0.12],
	["girls","^(girls|daughters|little girls)$",["children"],"female","girls",0.22],
	["boys","^(boys|sons|little boys)$",["children"],"male","boys",0.22],
	["children","^(children|kids|young ones|little ones|babies|infants|toddlers|every child)$",["children"],"","children",0.22],
	["women","^(women|womenfolk|wives|mothers|females|grown women|every woman|every female)$",ADULT,"female","women",0.15],
	["men","^(men|males|menfolk|husbands|fathers|grown men|every man|every male)$",ADULT,"male","men",0.08],
	["everyone","^(everyone|everybody|every soul|people|villagers|townsfolk|townspeople|inhabitants|residents|population|families|households|whole (vill?age|town|camp|settlement|people|tribe|clan))$",ALL,"","people",0.2],
]
## Our own people by their work: [id, pattern, work role, words].
const TRADES:=[
	["farmers","^(farmers?|field ?hands|hunters?|gatherers?|foragers?|herders?|herdsmen|shepherds?|fishers?|fishermen)$","Food","farmers"],
	["builders","^(builders?|masons?|diggers?)$","Construction","builders"],
	["crafters","^(craftsmen|crafters?|craftspeople|potters?|weavers?|smiths?|toolmakers?|carvers?|tanners?)$","Crafting","craftspeople"],
	["carriers","^(carriers?|porters?|haulers?)$","Logistics","carriers"],
	["quarrymen","^(miners?|quarrymen|woodcutters?|stonecutters?)$","Extraction","quarrymen and woodcutters"],
]
## Every noun above, for reading where a group of people ends.
const PEOPLE_NOUN:="(old (women|woman|wives|mothers|men|man|males|people|ones|folks?)|little (girls|boys|ones)|young ones|grown (men|women)|every (man|woman|child|male|female|soul)|whole (vill?age|town|camp|settlement|people|tribe|clan)|old|aged|elders|elderly|grandmothers|grandfathers|grey ?beards|grey ?heads|girls|daughters|boys|sons|children|kids|babies|infants|toddlers|women|womenfolk|wives|mothers|females|men|males|menfolk|husbands|fathers|everyone|everybody|people|villagers|townsfolk|townspeople|inhabitants|residents|population|families|households|farmers?|field ?hands|hunters?|gatherers?|foragers?|herders?|herdsmen|shepherds?|fishers?|fishermen|builders?|masons?|diggers?|craftsmen|crafters?|craftspeople|potters?|weavers?|smiths?|toolmakers?|carvers?|tanners?|carriers?|porters?|haulers?|miners?|quarrymen|woodcutters?|stonecutters?)"
## The verbs, as whole words (their place in the sentence is checked apart).
const KILL_RE:="(?i)\\b(kill|kil|kiil|killl|slay|slaughter|massacre|butcher|execute|exterminate|murder|wipe out|cut down|do away with|get rid of|hang|behead|strangle|drown|poison|put (?<putobj>[\\w' ]{1,40}?) to (the sword|death)|rid (?<ridplace>[\\w' ]{0,30}?)\\s*of)\\b"
const BURN_RE:="(?i)\\b(burn|torch|raze|set fire to|set (?<setobj>[\\w' ]{1,30}?) (on fire|alight|ablaze)|put (?<torchobj>[\\w' ]{1,30}?) to the torch)\\b"
## Out of the realm, by the verb itself: banish, exile, expel.
const BANISH_RE:="(?i)\\b(banish|exile|expel)\\b"
## "Drive / cast ... out": out of the realm only with words that say so.
const OUT_RE:="(?i)\\b(drive|cast|throw|chase|force|turn|kick|run)\\s+(?<mid>[\\w' ]{0,40}?)\\s*\\b(out|away|off)\\b"
## Words that say the realm is left, for "drive / cast ... out".
const REALM_STRICT:="(?i)\\b((out of|from|beyond|past|outside( of)?) (the |our |my |this )?(own )?(realm|lands|land|country|territory|kingdom|borders?)|beyond the (border|borders|hills|river|mountains|pass)|never to return|for good|forever)\\b"
## Where a banishing sends them that is still a leaving of the realm.
const REALM_PHRASE:="(?i)\\b((out of|from|away from|beyond|past|outside( of)?) (the |our |my |this )?(own )?(realm|lands?|country|territory|kingdom|vill?age|town|camp|settlement|borders?)|beyond the (hills|river|border|mountains|forest|marshes|pass)|(in)?to the (wild|wilds|wilderness|hills|forest|waste|wastes|desert|marsh|marshes)|for good|forever|never to return)\\b"
## Out of a town of ours, by its name.
const FROM_TOWN:="(?i)\\b(out of|from|away from) %s\\b"
## A place the words move them to or from that is no leaving of the realm.
const PLACE_PHRASE:="(?i)\\b(out of|from|off|to|into|onto|away from|across|toward|towards)\\s+(the |our |my |this |his |her |their )?[a-z]+"
## What may come before the verb in the order's own clause, once the names of
## those spoken to are taken out: nothing, filler, or words of command.
const LEAD_OK:="(?i)^(?:(?:yes|now|then|so|well|please|listen|hear me|right|very well|enough|go|and|go and|at once)\\b\\s*)*(?:(?:i (?:want|need|order|command|bid|tell) you(?: all)? to|i (?:order|command|decree)(?: that)?(?: you)?|you (?:will|shall|must|are to)|see (?:that|to it that) you|make sure (?:that )?you|you)\\s*)?$"
## Words that make the sentence no order of the god's: it forbids, doubts,
## reports, wishes or supposes the act.
const NOT_ORDER:="(?i)\\b(not|never|no one|nobody|don'?t|doesn'?t|didn'?t|won'?t|wouldn'?t|shouldn'?t|couldn'?t|mustn'?t|can'?t|cannot|should|would|could|might|if|unless|when|whenever|lest|in case|what if|suppose|perhaps|maybe|whether|wrong|think|thinks|thought|believe|believes|say|says|said|saying|told|tell|tells|asked|asks|want|wants|wanted|wish|wishes|claim|claims|claimed|heard|hear|rumou?r|propose|proposes|suggest|suggests|advise|advises|plan|plans|planned|dream|dreamed|dreamt|story|tale)\\b"
## Words that send them out of the realm (never a doubt or a "not").
const REALM_WORDS:="(?i)\\b(never to return|for good|forever)\\b"
## Where the verb's own clause ends.
const CLAUSE_CUT:="(?i)[,;:.!?]|\\b(from now on|from this day|from today|henceforth|hereafter|always|every time|each time|but|so|then|until|till|while|because|before|after|since|unless|if|when|whenever|lest|to|who|whom|that|which|whose|take|bring|carry|lead|send|march|haul|herd|give|keep|hold|spare|free|release|leave|feed|build|burn|torch|raze|drive|cast|throw|let|make|tie|bind|round up|enslave|kill|slay|execute|protect|guard|go|come|return)\\b"
## A count or a part leading the object ("half the farmers", "20 of the women").
const QUANT:="(?i)^(all|every one|each|both|half|most|some|several|many|a few|two thirds|three quarters|a third|one third|a quarter|one quarter|a fourth|a fifth|one fifth|a tenth|one tenth|\\d{1,7}|a dozen|a score|a hundred|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|fifteen|twenty|thirty|forty|fifty|sixty|hundred)(\\s+of)?\\s+"
const DETERMINERS:="(?i)^((the|our|my|this|these|those|own|all|of)\\s+)+"
## Words after a group that keep it whole: where they are, and when.
const PEOPLE_TAIL:="(?i)(\\s+((in|of|from|at|across|throughout|within|among|out of)\\s+(the |our |my |this )?(own |whole )?(vill?age|vilage|villiage|town|camp|settlement|hamlet|home|homes|houses|realm|lands?|hearths?%s)|at home|of ours|among us|here|there|now|today|tonight|at once|immediately|too|as well|first|all|alike|every one|to a (man|woman)|without mercy|to the last|(in)?to the (wild|wilds|wilderness|hills|forest|waste|wastes|desert|marsh|marshes)|beyond the (borders?|hills|river|mountains|pass)|out of (the |our |my )?(realm|lands?|country|territory|kingdom)|for good|forever|never to return))+$"
## The village or town itself, as what is burned.
const PLACE_CORE:="(?i)^(own |whole |entire )?(vill?age|vilage|villiage|town|camp|settlement|hamlet|home)$"
## "The village", "this town": a village not named.
const VILLAGE_RE:="(?i)\\b(the|this|that|our|my|a|in|of) (vill?age|vilage|villiage|town|camp|settlement|hamlet|houses|homes|huts)\\b"
## The words say the people are ours.
const OWN_RE:="(?i)\\b(our|my) own\\b|\\b(our|my) (vill?age|vilage|villiage|town|camp|settlement|hamlet|home|homes|houses|huts|people|folk|kin|realm|hearths?|women|men|children|old|elders|girls|boys|farmers|hunters|builders|craftsmen|families|households|subjects|tribe|clan)\\b|\\bat home\\b|\\bof ours\\b|\\bamong us\\b|\\bin our midst\\b"
## Someone else's people, or the captives of a fight: the war orders'.
const FOREIGN_RE:="(?i)\\b(their|theirs|them|they|the enemy|enemy|enemies|foes?|those people|these people|strangers|foreigners|captives?|prisoners?|bondservants?|bondsmen|slaves|envoys?|heralds?|messengers?)\\b"
## Wrongdoers and standing words: a law or a measure, never this.
const EXCLUDE_RE:="(?i)\\b(rebels?|ringleaders?|troublemakers?|agitators?|instigators?|traitors?|deserters?|criminals?|outlaws?|thie(f|ves)|murderers?|wrongdoers?|the guilty|the lazy|cowards?|liars?|hoarders?|poachers?|drunkards?|anyone who|anybody who|whoever|any who|those who|all who|everyone who|everybody who|any (man|woman|one) who)\\b"
## A standing rule, not an act now.
const RULE_RE:="(?i)\\b(from now on|from this day|from today|henceforth|hereafter|law|every (time|day|season|year)|always|each (time|day))\\b"
## The god's own emphasis ("..., I said"), never someone else's words.
const EMPHASIS_RE:="(?i)\\b(i (said|say|told you|tell you|repeat|command it|demand it)|as i (said|say))\\b"
## Why words that name our own people are no order: [reason id, pattern].
const NOT_ORDER_WHY:=[
	["forbid","(?i)\\b(not|never|no one|nobody|none of|don'?t|doesn'?t|didn'?t|won'?t|mustn'?t|can'?t|cannot|stop|forbid|forbidden)\\b"],
	["if","(?i)\\b(if|unless|when|whenever|once|lest|in case|until|should (they|it|the|any|anyone|someone))\\b"],
	["reported","(?i)\\b(say|says|said|saying|told|tells|asked|asks|claim|claims|claimed|heard|hear|rumou?r|story|tale|dream|dreamed|dreamt)\\b"],
	["wonder","(?i)\\b(should|shouldn'?t|would|wouldn'?t|could|couldn'?t|might|may|think|thinks|thought|believe|believes|suppose|perhaps|maybe|whether|wrong|right to|want|wants|wanted|wish|wishes|propose|proposes|suggest|suggests|advise|advises|plan|plans|planned|what if|do we|are we|is it)\\b"],
]
## What the court says when words that name our own people are no order.
const NOT_ORDER_WORDS:={
	"forbid":"Nothing is done to them: those words forbid it, they do not order it.",
	"if":"Nothing is done now: an order that waits on an \"if\" or a \"when\" is not given. If you mean it, say it plainly, and it will be read back to you.",
	"reported":"Nothing is done: those were others' words, not your order.",
	"wonder":"Nothing is done: that was wondered aloud, not ordered.",
	"lead":"Nothing is done: that was no order of yours. If you mean it, say it plainly, and it will be read back to you.",
	"rule":"Nothing is done: the court keeps no standing rule to kill, burn or drive out people by the group. If you mean it now, say it plainly, naming whose people, and it will be read back to you.",
}
## Parts of the whole the words ask for: [pattern, share].
const PARTS:=[
	["^(two thirds)",2.0/3.0],["^(three quarters|most)",0.75],["^(half)",0.5],
	["^(a third|one third)",1.0/3.0],["^(a quarter|one quarter|a fourth)",0.25],
	["^(a fifth|one fifth)",0.2],["^(a tenth|one tenth)",0.1],["^(some|several|a few|many)",0.2],
]
const NUMBER_WORDS:={"a dozen":12,"a score":20,"a hundred":100,"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,"eleven":11,"twelve":12,"fifteen":15,"twenty":20,"thirty":30,"forty":40,"fifty":50,"sixty":60,"hundred":100}
## The god's plain yes to the read-back, and nothing else.
const CONFIRM:="(?i)^\\W*(?:(?:yes|yea|yeah|aye)\\b[\\s,!.]*)?(?:(?:do it|i demand it|so be it|(?:that|it) is my word|that's my word)\\b[\\s,!.]*)?(?:now|at once)?[\\s!.]*$"
const CONFIRM_TOKEN:="(?i)\\b(yes|yea|yeah|aye|do it|i demand it|so be it|my word)\\b"
const DEMAND:="(?i)\\b(demand|do it)\\b"
## Words a short answer to "Which village?" may hold besides the names.
const ANSWER_WORDS:=["the","village","town","camp","settlement","one","of","our","own","ours","home","here","i","mean","meant","that","this","please","then","in","it","is","a","yes","just","only","first","second","last","other","theirs","we","hold","held","took","taken","captured","there","oh","well","um","uh","said","course","obviously"]

## The line each open read-back, plea or question was said on (by reference,
## per audience): the god's answer counts only as the very next line in that
## audience. Not saved: after a load, an open one is dropped (never acted on).
static var _marks:Dictionary={}

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
	## The court's one choke point for words that name our own people as the
	## object of a killing, a burning or a banishing: {} when they do not (or
	## are the war orders' business: someone else's people); otherwise
	## {kind:"act"|"ask"|"whom"|"decline", how, groups, share, count, text,
	## own, home, settlement_id, options?, question?, why?}. "act" is read back
	## first; "decline" (forbidden, supposed, reported, on a condition, a
	## standing rule, no order at all) is answered plainly: nothing is done.
	var clean:=text.strip_edges().replace("’","'")
	if clean=="" or clean.ends_with("?") or audience.is_empty(): return {}
	if String(audience.get("origin",""))=="foreign": return {}
	var lower:=clean.to_lower()
	if _has(lower,EXCLUDE_RE): return {}
	var cc:=_cc()
	# The order's own sentence: the first that holds a grave verb.
	for sentence in _re("[^.!?;]+").search_all(lower):
		var s:=sentence.get_string().strip_edges()
		var verb:=_verb(s)
		if verb.is_empty(): continue
		return _read(clean,s,verb,audience,list,cc)
	return {}

static func _read(clean:String,sentence:String,verb:Dictionary,audience:Dictionary,list:Array[Dictionary],cc:GDScript)->Dictionary:
	var rest:=sentence.substr(int(verb.at))
	var object:=String(verb.object)
	# "..., I tell you": the god's emphasis, never a person the act falls on.
	if _one_person(_re(EMPHASIS_RE).sub(object," ",true),list,cc): return {}
	# 1. What it falls on: people, or the village itself.
	var how:=String(verb.how)
	var phrase:=_people(object)
	var people:=phrase.has("groups") or bool(phrase.get("qualified",false))
	if how=="burn":
		if phrase.has("groups"): how="kill"
		elif not _burns_the_village(object): return {}
	elif not people: return {}
	# 2. Whose people, read from the verb's own clause ("kill all the men,
	# bring the women to Seanstone": Seanstone is only where the women go).
	var clause:=sentence.substr(int(verb.at),int(verb.end)-int(verb.at))+" "+String(_clip(sentence.substr(int(verb.end))).text)
	var place:=_has(clause,VILLAGE_RE)
	var town:=_our_town(clause,list)
	var home:=String(town.get("name",""))
	var own:=_has(clause,OWN_RE) or bool(town.get("named",false))
	# Someone else's people: the war orders. Read past a condition or a time
	# ("kill the women if they resist", "... when the enemy comes"): those
	# words say when, never whose.
	if not own and _foreign(rest,cc): return {}
	var groups:Array=phrase.get("groups",[])
	var trades_only:=not groups.is_empty() and groups.all(func(g:Dictionary)->bool: return String(g.get("role",""))!="")
	var out:={"how":how,"groups":groups,"share":float(phrase.get("share",1.0)),"count":int(phrase.get("count",0)),"text":clean.substr(0,300),"own":own,"home":home,"settlement_id":String(town.get("id",""))}
	var kind:="act"
	var why:=_not_an_order(sentence,verb,list,cc,clean)
	# Words that are no order at all (on a condition, a standing rule,
	# supposed, reported, forbidden) whose people are unsaid: nothing is done,
	# never a town we hold read into them ("if the harvest fails, kill all the
	# women" while we hold Tsaren). An order that only opens with another verb
	# ("take the food and kill the men") stays the war orders'.
	var no_order:=why in ["if","rule","wonder","reported","forbid"]
	if not (own or trades_only):
		var id:=String(audience.get("id",""))
		var held:=WarOrders.held_towns()
		if not held.is_empty():
			# A town we hold that this audience is speaking of: its people (the
			# war orders). Named nowhere, the words with no place in them are the
			# town we hold as before; "the village" is asked.
			if not WarOrders._town_in_audience(held,id).is_empty() or _town_order_recent(audience): return _declined(out,why) if no_order else {}
			if not place: return _declined(out,why) if no_order else {}
			kind="ask"; out["options"]=_options(held,home); out["question"]=_question(out,held)
		elif not WarOrders._place_in_audience(id).is_empty(): return _declined(out,why) if no_order else {}
		else:
			var at_war:=_any_war()
			if at_war or _feud():
				if at_war and not place: return _declined(out,why) if no_order else {}
				kind="ask"; out["options"]=_options([],home); out["question"]=_question(out,[])
	# From here the words name our own people (or ask which village): this is
	# where they end. 3. An order, or plainly nothing done.
	if why!="":
		out["kind"]="decline"; out["why"]=why
		return out
	# Moving people within the realm is no banishing (and no grave act).
	if how=="drive" and not _leaves_realm(String(verb.kind),rest): return {}
	# People narrowed ("the sick women", "the men who deserted"): whom exactly.
	if bool(phrase.get("qualified",false)):
		if kind!="act": return {}
		kind="whom"; out["words"]=String(phrase.get("words",""))
	out["kind"]=kind
	return out

static func _declined(out:Dictionary,why:String)->Dictionary:
	out["kind"]="decline"; out["why"]=why
	return out

static func _not_an_order(sentence:String,verb:Dictionary,list:Array[Dictionary],cc:GDScript,clean:String)->String:
	## "" when the sentence is the god's order; else why it is not: "forbid",
	## "if", "reported", "wonder", "rule", "lead" (the verb does not open it).
	var s:=_re(EMPHASIS_RE).sub(_re(REALM_WORDS).sub(sentence," ",true)," ",true)
	for p:Dictionary in Realm.clauses(s):
		if bool(p.held): return "forbid"
	var mention:=func(t:String,l:Array[Dictionary])->Array[Dictionary]: return cc.call("mentions",t,l)
	if _has(s,RULE_RE) or not Realm.law(clean,list,mention).is_empty(): return "rule"
	for row in NOT_ORDER_WHY:
		if _has(s,String(row[1])): return String(row[0])
	var lead:=_re(EMPHASIS_RE).sub(sentence.substr(0,int(verb.at))," ",true)
	if not _is_command(lead,list,cc): return "lead"
	return ""

const COUNCIL_NO:="Nothing is set in motion: an order to kill, burn or drive out our own people is given at court, read back with its numbers, and done only on your yes."

static func names_our_people(text:String)->bool:
	## Read only, for the council's pipeline (local_terrain, the court screen):
	## do these words name people of ours by group (women, the old, everyone,
	## a trade, the village itself) as the object of a killing, a burning or a
	## banishing, with no people of theirs named? Such words are never a
	## council directive, whatever else they say: the court reads them back
	## (reading above) and only grave_home registers their deaths.
	var lower:=text.strip_edges().replace("’","'").to_lower()
	if lower=="" or _has(lower,EXCLUDE_RE): return false
	for sentence in _re("[^.!?;]+").search_all(lower):
		var s:=sentence.get_string().strip_edges()
		var verb:=_verb(s)
		if verb.is_empty(): continue
		var object:=String(verb.object)
		var phrase:=_people(object)
		if not (phrase.has("groups") or bool(phrase.get("qualified",false)) or (String(verb.how)=="burn" and _burns_the_village(object))): continue
		var rest:=s.substr(int(verb.at))
		var none:Array[Dictionary]=[]
		var own:=_has(rest,OWN_RE) or bool(_our_town(rest,none).get("named",false))
		if not own and _foreign(rest,_cc()): continue
		return true
	return false

## A condition or a time after the order ("if they resist", "when the enemy
## comes"): it says when, never whose people.
const WHEN_CLAUSE:="(?i)\\b(if|unless|when|whenever|once|until|till|lest|in case|before|after)\\b[^,;]*"

static func _foreign(rest:String,cc:GDScript)->bool:
	## Do the words from the verb on name someone else's people (theirs, the
	## enemy's, a place of theirs), a condition or a time left aside?
	var main:=_re(WHEN_CLAUSE).sub(rest," ",true)
	return _has(main,FOREIGN_RE) or bool(cc.call("_names_a_place",main))

static func grave_words(text:String)->bool:
	## Read only: do these words order a killing, a burning, a banishing or
	## harm on people (any people: ours by group, wrongdoers, "anyone who")?
	## Such words never go to the council's standing orders or the civic
	## pipeline, which could register deaths of our own people with no
	## read-back (court_commands.custom_order, the court screen).
	var lower:=text.to_lower()
	var cc:=_cc()
	var verb:=not _verb(lower).is_empty() or bool(cc.call("is_harm",text))
	if not verb: return false
	if _has(lower,"(?i)\\b"+PEOPLE_NOUN+"\\b") or _has(lower,EXCLUDE_RE): return true
	return _re(String(cc.get_script_constant_map().get("GROUP_OBJECT_PATTERN",""))).search(text)!=null

static func _verb(s:String)->Dictionary:
	## The first grave verb in the sentence and the words right after it:
	## {how, kind ("kill"|"burn"|"banish"|"out"), at, object, bare?}.
	var best:Dictionary={}
	var k:=_re(KILL_RE).search(s)
	if k!=null:
		best={"how":"kill","kind":"kill","at":k.get_start(),"end":k.get_end(),"object":k.get_string("putobj") if k.get_string("putobj")!="" else s.substr(k.get_end())}
	var b:=_re(BURN_RE).search(s)
	if b!=null and (best.is_empty() or b.get_start()<int(best.at)):
		var obj:=b.get_string("setobj") if b.get_string("setobj")!="" else (b.get_string("torchobj") if b.get_string("torchobj")!="" else s.substr(b.get_end()))
		best={"how":"burn","kind":"burn","at":b.get_start(),"end":b.get_end(),"object":obj}
	var ban:=_re(BANISH_RE).search(s)
	if ban!=null and (best.is_empty() or ban.get_start()<int(best.at)):
		best={"how":"drive","kind":"banish","at":ban.get_start(),"end":ban.get_end(),"object":s.substr(ban.get_end())}
	var o:=_re(OUT_RE).search(s)
	if o!=null and (best.is_empty() or o.get_start()<int(best.at)):
		var mid:=o.get_string("mid").strip_edges()
		best={"how":"drive","kind":"out","at":o.get_start(),"end":o.get_end(),"object":mid if mid!="" else s.substr(o.get_end()),"bare":mid==""}
	return best

static func _is_command(lead:String,list:Array[Dictionary],cc:GDScript)->bool:
	## Before the verb in its own sentence: nothing, the names of those spoken
	## to, filler, or words of command ("Kishan, kill...", "I order you to
	## kill..."). Never "we must not", "the elders say we should", "if...".
	var l:=lead.to_lower()
	var found:Array=cc.call("mentions",l,list)
	for i in range(found.size()-1,-1,-1):
		var m:Dictionary=found[i]
		if String(m.by) in ["name","title"]: l=l.substr(0,int(m.at))+" "+l.substr(int(m.end))
	l=_re("[^a-z' ]").sub(l," ",true)
	l=_re("\\s+").sub(l," ",true).strip_edges()
	return _has(l,LEAD_OK)

static func _clip(object:String)->Dictionary:
	## The verb's own clause: {text, relative (cut at who/that/which)}.
	var o:=object.strip_edges().to_lower()
	var cut:=_re(CLAUSE_CUT).search(o)
	if cut==null: return {"text":o,"relative":false}
	return {"text":o.substr(0,cut.get_start()).strip_edges(),"relative":cut.get_string().to_lower() in ["who","whom","that","which","whose"]}

static func _people(object:String)->Dictionary:
	## The people right after the verb, and nothing else:
	## {groups, share, count, words} for whole groups ("the women and the
	## old", "half the farmers", "20 of the women of Seanstone");
	## {qualified:true, words} for people narrowed ("the sick women", "the
	## men who deserted"); {} for anything else (goats, trees, time, the dead).
	var clipped:=_clip(object)
	var text:=String(clipped.text)
	if text=="": return {}
	var segs:=_re("\\s*(?:\\band\\b|\\bor\\b|&)\\s*").sub(text,"|",true).split("|",false)
	if segs.is_empty(): return {}
	var groups:Array=[]
	var share:=1.0
	var count:=0
	var words:=PackedStringArray()
	for i in segs.size():
		var seg:=String(segs[i]).strip_edges()
		var p:=_group_phrase(seg,i==0)
		if p.is_empty():
			if i==0: return {}
			break
		if bool(p.get("qualified",false)): return {"qualified":true,"words":seg}
		if i==0: share=float(p.share); count=int(p.count)
		for g in p.groups:
			if not groups.any(func(x:Dictionary)->bool: return String(x.id)==String((g as Dictionary).id)): groups.append(g)
		words.append(seg)
	if groups.is_empty(): return {}
	# "The men who refused to fight": narrowed by what follows.
	if bool(clipped.relative): return {"qualified":true,"words":" and ".join(words)}
	return {"groups":groups,"share":share,"count":count,"words":" and ".join(words)}

static func _group_phrase(seg:String,first:bool)->Dictionary:
	## One group of people: {groups, share, count} | {qualified:true} | {}.
	var s:=seg.strip_edges()
	var share:=1.0
	var count:=0
	var q:=_re(QUANT).search(s)
	if q!=null and first:
		var lead:=q.get_string(1).to_lower()
		if lead.is_valid_int(): count=int(lead)
		elif NUMBER_WORDS.has(lead): count=int(NUMBER_WORDS[lead])
		else:
			for pair in PARTS:
				if _has(lead,"(?i)"+String(pair[0])): share=float(pair[1]); break
		s=s.substr(q.get_end())
	s=_re(DETERMINERS).sub(s,"",false).strip_edges()
	s=_re(PEOPLE_TAIL % _town_names()).sub(s,"",false).strip_edges()
	if s=="": return {}
	var g:=_groups_of(s)
	if not g.is_empty(): return {"groups":g,"share":share,"count":count}
	# A group noun at the end with other words before it: people narrowed.
	var m:=_re("(?i)^([a-z' ]+?)\\s+"+PEOPLE_NOUN+"$").search(s)
	if m!=null and not _groups_of(s.substr(m.get_start(2))).is_empty() and not "'" in m.get_string(1): return {"qualified":true}
	return {}

static func _groups_of(noun:String)->Array:
	## The group a noun names exactly ("women", "old men", "farmers"), or [].
	var n:=noun.strip_edges().to_lower()
	for row in GROUPS:
		if _has(n,"(?i)"+String(row[1])): return [_group_row(row)]
	for row in TRADES:
		if _has(n,"(?i)"+String(row[1])): return [{"id":String(row[0]),"cohorts":WORKING.duplicate(),"sex":"","words":_trade_words(String(row[3])),"weight":0.08,"role":String(row[2])}]
	return []

static func _trade_words(words:String)->String:
	## The people of a kind of work in words their own time knows (before
	## anyone sows a crop, those who get our food are no "farmers").
	var tags:=preload("res://scripts/character_voice.gd").era_tags("player")
	if preload("res://scripts/character_voice.gd").permits(words,tags): return words
	return String({"farmers":"food-gatherers"}.get(words,"workers"))

static func _town_names()->String:
	var out:=""
	for s in GameState.player_settlements:
		var name:=String((s as Dictionary).get("name","")).to_lower() if s is Dictionary else ""
		if name!="": out+="|"+WarOrders._escape(name)
	var home:=String(GameState.settlement_name).to_lower()
	if home!="": out+="|"+WarOrders._escape(home)
	return out

static func _burns_the_village(object:String)->bool:
	## The village or town itself, and nothing less ("the huts of the sick",
	## "the houses" are not the village).
	var text:=String(_clip(object).text)
	var seg:=String(_re("\\s*(?:\\band\\b|\\bor\\b)\\s*").sub(text,"|",true).split("|",false)[0]) if text!="" else ""
	seg=_re("(?i)^((the|our|my|this|that)\\s+)+").sub(seg,"",false).strip_edges()
	if _has(seg,PLACE_CORE): return true
	for name in [String(GameState.settlement_name)]+GameState.player_settlements.map(func(t:Variant)->String: return String((t as Dictionary).get("name","")) if t is Dictionary else ""):
		if String(name)!="" and seg==String(name).to_lower(): return true
	return false

static func _leaves_realm(kind:String,rest:String)->bool:
	## Banishing is out of the realm: banish, exile, expel (never out of the
	## hall or to the fields); "drive / cast ... out" only with words that say
	## the realm is left ("out of our lands", "never to return").
	if kind!="banish": return _has(rest,REALM_STRICT)
	if _has(rest,REALM_PHRASE): return true
	var ours:Array=[String(GameState.settlement_name).to_lower()]
	for s in GameState.player_settlements:
		if s is Dictionary: ours.append(String((s as Dictionary).get("name","")).to_lower())
	for name in ours:
		if String(name)!="" and _has(rest,FROM_TOWN % WarOrders._escape(String(name))): return true
	return not _has(rest,PLACE_PHRASE)

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

static func _town_gone(settlement_id:String)->bool:
	## A town of ours named in the order that is ours no longer (or never was).
	if settlement_id=="": return false
	var record:Dictionary=SettlementModel.settlement_record(settlement_id)
	return record.is_empty() or not String(record.get("occupied_by","")).is_empty()

static func _scoped(settlement_id:String,operation:Callable,commit:bool=true)->Variant:
	## Done among that town's own people (SettlementModel's local count, which
	## the daily births and deaths read), then folded back into the realm's
	## (commit), or only read. Never on another town's people in its place.
	var model:Variant=WorldSimulation.settlements if WorldSimulation.settlements!=null else SettlementModel
	var local:=func()->Variant: return model.with_local_population(operation,commit)
	if settlement_id!="": return model.with_city_resources(settlement_id,local)
	return local.call()

static func _one_person(object:String,list:Array[Dictionary],cc:GDScript)->bool:
	## One person named ("Kavu", "the headman", "him"): a person act, not this.
	if list.is_empty(): return _has(object,"\\b(him|her|you|yourself|himself|herself)\\b")
	for m:Dictionary in cc.call("mentions",object,list):
		if String(m.by) in ["name","title"] and String(m.get("of",""))=="": return true
		if String(m.by)=="pronoun" and String(m.word) in ["him","her","you","yourself","himself","herself","this one","that one"]: return true
	return false

static func _group_row(row:Array)->Dictionary:
	return {"id":String(row[0]),"cohorts":(row[2] as Array).duplicate(),"sex":String(row[3]),"words":String(row[4]),"weight":float(row[5])}

static func _town_order_recent(audience:Dictionary)->bool:
	var last:Dictionary=audience.get("town_order",{}) if audience.get("town_order") is Dictionary else {}
	return not last.is_empty() and _day()-int(last.get("day",-99))<=2

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
# The very next line: answers, read-backs, pleas
# --------------------------------------------------------------------------

static func _pending(audience:Dictionary)->Dictionary:
	var p:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
	if String(p.get("verb",""))!=PENDING_VERB: return {}
	return p

static func has_pending(audience:Dictionary)->bool:
	return not _pending(audience).is_empty()

static func _open(id:String,audience:Dictionary,pending:Dictionary)->void:
	## Opens a read-back, plea or question on the line just said (the ruler's
	## last line here): only the very next line in this audience answers it.
	audience["pending_command"]=pending
	# Any older unanswered question of the order reader is gone with it: the
	# next line answers this, never that (order_reader.gd reader_pending).
	audience.erase("reader_pending")
	var lines:Array=audience.get("lines",[])
	for i in range(lines.size()-1,-1,-1):
		if String((lines[i] as Dictionary).get("role",""))=="ruler":
			_marks[id]=lines[i]; return
	_marks.erase(id)

static func _drop(id:String,audience:Dictionary)->void:
	if has_pending(audience): audience.erase("pending_command")
	_marks.erase(id)

static func _fresh(id:String,audience:Dictionary,clean:String)->bool:
	## Are these words the very next line after the one the read-back (or the
	## plea, or the question) was opened on, in this audience, the same day?
	if int(_pending(audience).get("day",-1))!=_day(): return false
	var mark:Variant=_marks.get(id,null)
	if not mark is Dictionary: return false
	var lines:Array=audience.get("lines",[])
	var at:=-1
	for i in range(lines.size()-1,-1,-1):
		if is_same(lines[i],mark): at=i; break
	if at<0: return false
	var said:=0
	var last_text:=""
	for i in range(at+1,lines.size()):
		if String((lines[i] as Dictionary).get("role",""))=="ruler":
			said+=1; last_text=String((lines[i] as Dictionary).get("text",""))
	if said==0: return true
	return said==1 and last_text.strip_edges()==clean.strip_edges()

static func confirms(text:String)->bool:
	## The god's plain yes, and nothing else ("yes", "do it", "I demand it",
	## "so be it", "that is my word").
	var t:=text.strip_edges()
	return t!="" and _has(t,CONFIRM) and _has(t,CONFIRM_TOKEN)

static func assent_like(text:String)->bool:
	## Words that would say yes or press on ("now!", "okay", "go on", "you heard
	## me", "I said kill"), whether or not they are the plain yes the read-back
	## takes: they never carry anything else after a read-back or a plea.
	var cc:=_cc()
	var map:Dictionary=cc.get_script_constant_map()
	return confirms(text) or _re(String(map.get("INSIST_PATTERN",""))).search(text)!=null or _re(String(map.get("CONFIRM_PATTERN",""))).search(text)!=null or bool(cc.call("bare_assent",text)) \
		or _has(text,"(?i)^\\W*(i said (kill|burn|banish|drive|do)|obey( me)?|you heard me|now|at once|okay|ok|sure|go on|carry on)\\b")

static func continues(audience:Dictionary,text:String)->bool:
	## Read only: do these words answer what grave_home has open here (a clear
	## answer to "which village?", or a yes to a read-back or a plea), as the
	## very next line?
	var p:=_pending(audience)
	if p.is_empty() or not _fresh(String(audience.get("id","")),audience,text): return false
	if String(p.get("ask",""))=="which_people": return not answer_choice(audience,text).is_empty()
	return confirms(text)

static func next_line(id:String,audience:Dictionary,list:Array[Dictionary],clean:String,context:Dictionary)->Dictionary:
	## The god's next words after a read-back, a plea or "which village?": the
	## yes (or a clear answer) carries it on; any other words, or any words that
	## are not the very next line here, drop it, and are heard as themselves ({}).
	var p:=_pending(audience)
	if p.is_empty(): return {}
	var cc:=_cc()
	var pressing:=assent_like(clean)
	if not _fresh(id,audience,clean):
		_drop(id,audience)
		# A yes or "now!" after the moment has passed: nothing is done, and the
		# old order is never read again from these words.
		if pressing: return _nothing(id,audience,clean,context,"Nothing is done: that order is no longer before the court. Give it again if you mean it, and it will be read back to you.")
		return {}
	var stored:Dictionary=(p.get("reading",{}) as Dictionary).duplicate(true)
	match String(p.get("ask","")):
		"which_people": return _answer(id,audience,list,clean,context,p,stored)
		"readback","plea":
			if not confirms(clean):
				_drop(id,audience)
				# The order given again in full ("yes, kill all the women of
				# Seanstone"): read back again as itself (court_commands.hear).
				if not reading(clean,audience,list).is_empty(): return {}
				if pressing: return _nothing(id,audience,clean,context,"Nothing is done: to carry it out, say yes, or I demand it.")
				return {}
			_drop(id,audience)
			stored["kind"]="act"
			# The read-back's numbers still hold, or it is read back again.
			if String(p.get("ask",""))=="readback" and readback_words(stored)!=String(p.get("question","")):
				return carry(id,audience,list,stored,false,context,clean)
			return carry(id,audience,list,stored,String(p.get("ask",""))=="plea" or _has(clean,DEMAND),context,clean,true)
	_drop(id,audience)
	return {}

static func _nothing(id:String,audience:Dictionary,clean:String,context:Dictionary,words:String)->Dictionary:
	var r:Dictionary=_cc().call("_plain_answer",id,audience,clean,context,words,true)
	r.verb=VERB; r.stage="grave_decline"
	return r

static func answer_choice(audience:Dictionary,clean:String)->Dictionary:
	## A short, clear answer to "Which village do you mean?": {pick:"own"} (our
	## own, named or "ours"), {pick:"town", option} (a town we held, by name or
	## "the second"), {pick:"place", place} (another town or people of theirs
	## named), {pick:"no"}, {pick:"yes"} (a bare yes: which is still not said,
	## unless there is only our own). {} for any other words. Read only.
	var p:=_pending(audience)
	if p.is_empty() or String(p.get("ask",""))!="which_people": return {}
	var text:=clean.strip_edges().replace("’","'")
	if text=="" or text.ends_with("?"): return {}
	var lower:=_re("[.!]+$").sub(text.to_lower(),"",false).strip_edges()
	var options:Array=p.get("options",[])
	if _has(lower,"^(no|nope|nay|neither|none( of them)?|nobody|no one|never mind|forget it|cancel( that| it)?|leave it|leave them( be)?|not now|stop|no,? (leave|forget) it)$"): return {"pick":"no"}
	if confirms(text): return {"pick":"own"} if options.size()<=1 else {"pick":"yes"}
	var words:=Array(_re("[^a-z0-9' ]").sub(lower," ",true).split(" ",false))
	if words.is_empty() or words.size()>7: return {}
	var allowed:=ANSWER_WORDS.duplicate()
	for o in options:
		for w in String((o as Dictionary).get("name","")).to_lower().split(" ",false): allowed.append(w)
	var places:Array=[]
	for t:Dictionary in WarOrders.known_places(): places.append({"name":String(t.name).trim_prefix("Reported home of "),"place":t})
	if WorldSimulation.world!=null:
		for c in WorldSimulation.world.civilizations:
			if c is Dictionary and String((c as Dictionary).get("id",""))!="player" and String((c as Dictionary).get("name",""))!="": places.append({"name":String((c as Dictionary).name),"place":{"name":String((c as Dictionary).name),"civ_id":String((c as Dictionary).id)}})
	for pl in places:
		for w in String((pl as Dictionary).name).to_lower().split(" ",false): allowed.append(w)
	for w in words:
		if not String(w) in allowed: return {}
	for o in options:
		if String((o as Dictionary).get("id",""))=="town" and WarOrders._name_hit(lower,String((o as Dictionary).get("name",""))): return {"pick":"town","option":o}
	for pl in places:
		if WarOrders._name_hit(lower,String((pl as Dictionary).name)): return {"pick":"place","place":(pl as Dictionary).place}
	if options.size()>1 and words.any(func(w:String)->bool: return w in ["second","last","other","theirs","hold","held","took","taken","captured"]):
		return {"pick":"town","option":options[1]}
	if not options.is_empty() and WarOrders._name_hit(lower,String((options[0] as Dictionary).get("name",""))): return {"pick":"own"}
	if words.any(func(w:String)->bool: return w in ["our","own","ours","home","here","first"]): return {"pick":"own"}
	return {}

static func _answer(id:String,audience:Dictionary,list:Array[Dictionary],clean:String,context:Dictionary,p:Dictionary,stored:Dictionary)->Dictionary:
	var choice:=answer_choice(audience,clean)
	var cc:=_cc()
	if choice.is_empty() and assent_like(clean):
		_drop(id,audience)
		return _nothing(id,audience,clean,context,"Nothing is done: you did not say which village. Give the order again with its name if you mean it.")
	if choice.is_empty():
		# The same order said again: still not said which (never asked twice).
		if _norm(clean)==_norm(String(p.get("text",""))):
			var said:Dictionary=cc.call("_plain_answer",id,audience,clean,context,"Nothing is done until you say which village: %s." % _option_words(p.get("options",[]) as Array),true)
			_open(id,audience,p)
			return said
		_drop(id,audience)
		return {}
	match String(choice.pick):
		"no":
			_drop(id,audience)
			return cc.call("_plain_answer",id,audience,clean,context,"Nothing is done to anyone.")
		"yes":
			var r:Dictionary=cc.call("_plain_answer",id,audience,clean,context,"Nothing is done until you say which village: %s." % _option_words(p.get("options",[]) as Array),true)
			_open(id,audience,p)
			return r
		"town":
			_drop(id,audience)
			var opt:Dictionary=choice.option
			var town:=WarOrders._held_town(String(opt.get("city_id","")))
			if town.is_empty(): return _reask(id,audience,list,clean,context,stored,String(opt.get("name","")))
			return _to_town(id,audience,list,clean,context,stored,town)
		"place":
			_drop(id,audience)
			return _to_town(id,audience,list,clean,context,stored,choice.place as Dictionary)
	_drop(id,audience)
	stored["kind"]="act"; stored["own"]=true
	return carry(id,audience,list,stored,false,context,clean)

static func _norm(text:String)->String:
	return _re("[^a-z0-9 ]").sub(text.to_lower(),"",true).strip_edges()

static func _reask(id:String,audience:Dictionary,list:Array[Dictionary],clean:String,context:Dictionary,stored:Dictionary,lost:String)->Dictionary:
	## The town named is no longer ours: asked again with what is true now.
	var again:=stored.duplicate(true)
	var held:=WarOrders.held_towns()
	again["kind"]="ask"; again["options"]=_options(held,String(stored.get("home","")))
	again["question"]=("%s is no longer in our hands. " % lost if lost!="" else "")+_question(again,held)
	return carry(id,audience,list,again,false,context,clean)

static func _option_words(options:Array)->String:
	var names:=PackedStringArray()
	for o in options: names.append(String((o as Dictionary).get("name","")))
	return " or ".join(names)

static func _to_town(id:String,audience:Dictionary,list:Array[Dictionary],clean:String,context:Dictionary,stored:Dictionary,town:Dictionary)->Dictionary:
	## The answer named a town not ours to strike: the order as the war orders
	## read it for that town (its fate when we hold it, else what it would take).
	var name:=String(town.get("name","")).trim_prefix("Reported home of ")
	if name=="": return _reask(id,audience,list,clean,context,stored,"")
	var cc:=_cc()
	var said:=String(stored.get("text",""))
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

static func cells(groups:Array)->Array:
	## The people the groups name, by age cohort and sex, each counted once
	## ("the women and the old": the old women once): [{cohort, sex, have
	## (in the cohort), target (named), whole (named outright, not only for
	## their work), roles {role: share of the cell at that work}}]. Work is
	## spread evenly over the working ages (the work split has no ages).
	var out:Array=[]
	var working:=0.0
	for c in WORKING: working+=maxf(0.0,float(GameState.population_cohorts.get(c,0.0)))
	for cohort in ALL:
		var n:=maxf(0.0,float(GameState.population_cohorts.get(cohort,0.0)))
		var women:=GameState.women_in([cohort])
		for sex in SEXES:
			var have:=women if sex=="female" else maxf(0.0,n-women)
			if have<=0.000001: continue
			var whole:=false
			var roles:={}
			for g in groups:
				var gd:Dictionary=g
				if not (gd.get("cohorts",[]) as Array).has(cohort): continue
				if String(gd.get("sex",""))!="" and String(gd.sex)!=sex: continue
				if String(gd.get("role",""))=="": whole=true
				else: roles[String(gd.role)]=clampf(float(GameState.population_allocations.get(String(gd.role),0))/maxf(1.0,working),0.0,1.0)
			var trade:=0.0
			for r in roles: trade+=float(roles[r])
			var share:=1.0 if whole else minf(1.0,trade)
			if share<=0.0: continue
			out.append({"cohort":cohort,"sex":sex,"have":have,"target":have*share,"whole":whole,"roles":roles})
	return out

static func group_count(groups:Array)->int:
	## How many people the groups name, each once, in whole people of each age
	## and sex (as the act takes them).
	var total:=0
	for c in cells(groups): total+=floori(float((c as Dictionary).target)+0.000001)
	return maxi(0,mini(total,GameState.population_total-1))

static func _want(cs:Array,share:float,count:int)->int:
	## The whole of those named, a part ("half"), or a number of them.
	var total:=0.0
	var whole_total:=0
	for c in cs:
		total+=float((c as Dictionary).target)
		whole_total+=floori(float((c as Dictionary).target)+0.000001)
	var want:=mini(whole_total,floori(total*share+0.000001)) if count<=0 else mini(count,whole_total)
	# Each cell its part, in whole people (largest remainders), never more than there are.
	var k:=float(want)/maxf(0.000001,total)
	var assigned:=0
	var rest:Array=[]
	for c in cs:
		var exact:=float((c as Dictionary).target)*k
		var whole:=mini(floori(exact+0.000001),floori(float((c as Dictionary).target)+0.000001))
		(c as Dictionary)["want"]=whole; assigned+=whole
		rest.append({"c":c,"frac":exact-float(whole)})
	rest.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.frac)>float(b.frac))
	for item in rest:
		if assigned>=want: break
		var c:Dictionary=item.c
		if int(c.want)+1<=floori(float(c.target)+0.000001): c["want"]=int(c.want)+1; assigned+=1
	return assigned

static func _named(r_in:Dictionary)->Dictionary:
	## Read only, in the town's own count: {want (to be struck), of (all of
	## them), people (the town's people)}.
	return _scoped(String(r_in.get("settlement_id","")),func()->Dictionary:
		var cs:=cells(r_in.get("groups",[]) as Array)
		var all:=0
		for c in cs: all+=floori(float((c as Dictionary).target)+0.000001)
		var want:=_want(cs,float(r_in.get("share",1.0)),int(r_in.get("count",0)))
		return {"want":want,"of":all,"people":int(GameState.population_total)}
	,false)

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
	## gear, and out of home's count (men of working age). Returns those gone.
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
	var gone:Dictionary=_scoped("",func()->Dictionary: return GameState.register_population_departures(going,"Fled rather than kill their own people",{"children":0.0,"youth":1.0,"early_adults":1.0,"established_adults":1.0,"mature_adults":0.5,"elders":0.0},"male"))
	return int(gone.get("count",0))

# --------------------------------------------------------------------------
# Carrying it out
# --------------------------------------------------------------------------

static func carry(id:String,audience:Dictionary,list:Array[Dictionary],r_in:Dictionary,insist:bool,context:Dictionary,said:String="",confirmed:bool=false)->Dictionary:
	## The god's grave order on our own people: asked about ("which village?",
	## "whom exactly?"), read back, or, on the god's yes in the very next line
	## (confirmed), decided and carried out. said: the words just spoken (an
	## answer, "yes"), else the order itself.
	var cc:=_cc()
	var words:=said if said!="" else String(r_in.get("text",""))
	cc.call("_echo",id,audience,words,context)
	var speaker:Dictionary=cc.call("_speaker_entry",list)
	var actor:=_actor(list,speaker,cc)
	var r:Dictionary=cc.call("_result",VERB,actor,{},String(r_in.get("text",words)),insist)
	r.verb=VERB; r.reaction="grave"
	r["grave_home"]={"how":String(r_in.get("how","")),"kind":String(r_in.get("kind",""))}
	var who_asks:=actor if not actor.is_empty() else speaker
	match String(r_in.get("kind","")):
		"ask":
			# The same unclear order again after the question: not asked twice.
			var open:=_pending(audience)
			if not open.is_empty() and String(open.get("ask",""))=="which_people" and String(open.get("text",""))==String(r_in.get("text","")):
				return cc.call("_plain_answer",id,audience,words,{"echoed":true},"Nothing is done until you say which village: %s." % _option_words(open.get("options",[]) as Array))
			_open(id,audience,{"verb":PENDING_VERB,"ask":"which_people","actor":String(actor.get("key","")),"target":"","day":_day(),"text":String(r_in.text),"reading":r_in.duplicate(true),"options":(r_in.get("options",[]) as Array).duplicate(true),"question":String(r_in.get("question",""))})
			return _asking(r,speaker,String(r_in.get("question","")),"Nothing is done yet: the court waits to hear which village you mean.","grave_ask")
		"whom":
			_drop(id,audience)
			# Said, not asked: nothing waits on an answer ("all of them" next is
			# heard as itself), so the god gives the whole order again.
			var q:="Nothing is done to the %s on those words. Give the order again, naming exactly whom you mean." % String(r_in.get("words","people")).trim_prefix("the ")
			var whom:=_asking(r,who_asks,q,"Nothing is done.","grave_whom")
			return whom
		"decline":
			_drop(id,audience)
			var no:Dictionary=cc.call("_plain_answer",id,audience,words,{"echoed":true},String(NOT_ORDER_WORDS.get(String(r_in.get("why","lead")),NOT_ORDER_WORDS.lead)))
			no.verb=VERB; no.stage="grave_decline"
			return no
	# A town of ours named that is ours no longer: never struck in its name.
	if _town_gone(String(r_in.get("settlement_id",""))):
		_drop(id,audience)
		var gone:Dictionary=cc.call("_plain_answer",id,audience,words,{"echoed":true},"Nothing is done: %s is no longer one of our towns." % String(r_in.get("home","that town")))
		gone.verb=VERB
		return gone
	if not confirmed:
		# The read-back: the order said back with its numbers; only the god's
		# yes in the very next line here carries it out.
		var q2:=readback_words(r_in)
		if q2=="":
			_drop(id,audience)
			var none:Dictionary=cc.call("_plain_answer",id,audience,words,{"echoed":true},"There are no %s in %s; nothing is done." % [_label_words(r_in),String(r_in.get("home","the village"))])
			none.verb=VERB
			return none
		_open(id,audience,{"verb":PENDING_VERB,"ask":"readback","actor":String(actor.get("key","")),"target":"","day":_day(),"text":String(r_in.get("text","")),"reading":r_in.duplicate(true),"question":q2})
		return _asking(r,who_asks,q2,"Nothing is done yet: %s waits for your word." % String(who_asks.get("name","the court")),"grave_readback")
	_drop(id,audience)
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
		# The plea: only the god's yes in the very next line here settles it.
		_open(id,audience,{"verb":PENDING_VERB,"ask":"plea","actor":String(actor.get("key","")),"target":"","day":_day(),"text":String(r_in.get("text","")),"reading":r_in.duplicate(true)})
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
	var done:=_act(id,r_in,rng)
	r["grave_home"]=done
	var lead:=_obeyed_words(actor,ob)
	# The chance they would have refused, all told (their own nature's, then this).
	var refuse_all:=float(ob.get("chance",0.0))+(1.0-float(ob.get("chance",0.0)))*p_refuse
	if lead!="" and not person.is_empty(): lead=lead.trim_suffix(".")+" (the chance they would refuse it: %s)." % Ledger.chance_words(refuse_all)
	r.outcome=(lead+" "+String(done.get("words",""))).strip_edges()
	r.executed=bool(done.get("ok",false))
	r.stage=VERB if r.executed else ("refuse_hands" if int(done.get("hands",0))>0 and int(done.get("willing",1))<=0 else "none")
	r["actor_says"]=_actor_says(done,ob,r_in)
	r.witness_ids=cc.call("_witness_ids",id,[])
	if r.executed: _consequences(id,actor,ob,r_in,done)
	elif int(done.get("hands_fled",0))>0:
		DIVINE.record_people_act("terrify_people")
	return r

static func _asking(r:Dictionary,who:Dictionary,question:String,outcome:String,stage:String)->Dictionary:
	r.stage=stage; r.executed=false; r.reaction="neutral"
	r.actor=who.duplicate(); r.actor_name=String(who.get("name",""))
	r.obedience={"id":"object","manner":"plain","chance":0.0}
	r["actor_says"]=question
	r.outcome=outcome
	return r

static func readback_words(r_in:Dictionary)->String:
	## The order said back with its numbers: "You would have the 300 women of
	## Seanstone killed?" "" when there is nobody to do it to.
	var home:=String(r_in.get("home","")) if String(r_in.get("home",""))!="" else (String(GameState.settlement_name) if String(GameState.settlement_name)!="" else "our village")
	var n:=_named(r_in)
	if String(r_in.get("how",""))=="burn":
		return "You would have %s burned, our own village, its %d people turned out of their houses?" % [home,int(n.people)]
	var want:=int(n.want); var all:=int(n.of)
	if want<=0: return ""
	var who:=_label_words(r_in)
	var whom:=("the %d %s of %s" % [want,who,home]) if want>=all else ("%d of the %d %s of %s" % [want,all,who,home])
	return "You would have %s %s?" % [whom,"driven out of the realm" if String(r_in.get("how",""))=="drive" else "killed"]

static func _act(id:String,r_in:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	## The act itself, on the ledger: who is named (read in the town's own
	## count), the hands (home's men), then the act in the town's own count,
	## then the work as it now stands. Every number reported is what moved.
	var how:=String(r_in.get("how","kill"))
	var sid:=String(r_in.get("settlement_id",""))
	var home:=String(r_in.get("home","")) if String(r_in.get("home",""))!="" else (String(GameState.settlement_name) if String(GameState.settlement_name)!="" else "the village")
	var realm_before:=int(GameState.population_total)
	var people:=DIVINE.people_regard(Hall._officials())
	var weight:=0.0
	for g in r_in.get("groups",[]): weight=maxf(weight,float((g as Dictionary).get("weight",0.1)))
	var out:={"ok":false,"how":how,"home":home,"hands":0,"willing":0,"refused":0,"hands_fled":0,"dead":0,"moved":0,"escaped":0,"hid":0,"kin_fled":0,"targets":0,"pregnancies_lost":0,"population_before":realm_before}
	# Women by age are kept from now on, the realm's and every town's alike.
	if how!="burn": GameState.ensure_female_cohorts()
	if how!="burn":
		var n:=_named(r_in)
		out.targets=int(n.want)
		if int(n.want)<=0:
			out["words"]="There are no %s in %s to %s." % [_label_words(r_in),home,"kill" if how=="kill" else "drive out"]
			out["population_after"]=int(GameState.population_total)
			return out
	var h:=hands()
	var hs:=_hands_step(h,how,0.1 if how=="burn" else weight,people,rng)
	out.hands=int(hs.n); out["hand_odds"]=float(hs.p); out.refused=int(hs.refused); out.hands_fled=int(hs.fled); out.willing=int(hs.willing)
	var parts:=PackedStringArray([_hands_words(h,hs)])
	if int(hs.willing)<=0:
		parts.append("Nothing was done to %s." % (_label(r_in) if how!="burn" else home))
		out["population_after"]=int(GameState.population_total)
		out["words"]=" ".join(parts)
		return out
	var done:Dictionary
	if how=="burn": done=_scoped(sid,func()->Dictionary: return _burn(r_in,int(hs.willing),people,rng))
	else: done=_scoped(sid,func()->Dictionary: return _cull(r_in,int(hs.willing),people,rng))
	out.merge(done,true)
	if done.has("asked"): out.targets=int(done.asked)
	# The work as it now stands in that town: those killed or driven out for
	# their work are gone from it (each kind by its own losses).
	if done.get("work_pct") is Dictionary: _set_work(sid,done.work_pct as Dictionary)
	GameState.synchronize_population_allocations()
	out["population_after"]=int(GameState.population_total)
	parts.append(String(done.get("words","")))
	out["words"]=" ".join(parts).strip_edges()
	return out

static func _set_work(sid:String,pct:Dictionary)->void:
	## That town's own work split after those killed for their work: the
	## town's record when it keeps its own split (or is not home), else the
	## realm's (home's own work).
	var record:Dictionary={}
	if sid!="": record=SettlementModel.settlement_record(sid)
	else:
		for s in GameState.player_settlements:
			if s is Dictionary and bool((s as Dictionary).get("primary",false)): record=s
	if not record.is_empty() and (sid!="" or not (record.get("local_allocations",{}) as Dictionary).is_empty()):
		record["local_allocations"]=pct.duplicate()
		return
	var shares:Dictionary=GameState.population_allocation_percentages
	for role in pct: shares[role]=float(pct[role])

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
	return "%sthe %s of %s" % [_part_words(r_in),_label_words(r_in),home]

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

static func _label_words(r_in:Dictionary)->String:
	var names:=PackedStringArray()
	for g in r_in.get("groups",[]): names.append(String((g as Dictionary).get("words","people")))
	return " and ".join(names) if not names.is_empty() else "people"

static func _obeyed_words(actor:Dictionary,ob:Dictionary)->String:
	var name:=String(actor.get("name",""))
	if name=="": return ""
	match String(ob.get("id","obey")):
		"reluctant": return "%s obeyed, though it cost them." % name
		_: return "%s obeyed%s." % [name,", trembling" if String(ob.get("manner",""))=="trembling" else ""]

static func _actor_says(done:Dictionary,ob:Dictionary,_r_in:Dictionary)->String:
	## The one ordered, in plain words, from the numbers decided.
	if int(done.get("hands",0))>0 and int(done.get("willing",1))<=0:
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

static func _cull(r_in:Dictionary,willing:int,people:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	## Killing or driving out the people named, by age and sex, on stated odds,
	## in this town's own count. Every number reported is what the ledger moved.
	var how:=String(r_in.get("how","kill"))
	var home:=String(r_in.get("home","")) if String(r_in.get("home",""))!="" else (String(GameState.settlement_name) if String(GameState.settlement_name)!="" else "the village")
	var pop_before:=int(GameState.population_total)
	var fertile_before:=GameState.fertile_women()
	var work_before:=(GameState.population_allocations as Dictionary).duplicate()
	var cs:=cells(r_in.get("groups",[]) as Array)
	var total:=_want(cs,float(r_in.get("share",1.0)),int(r_in.get("count",0)))
	var out:={"ok":false,"dead":0,"moved":0,"escaped":0,"hid":0,"kin_fled":0,"pregnancies_lost":0,"asked":total}
	if total<=0:
		out["words"]="There are no %s in %s to %s." % [_label_words(r_in),home,"kill" if how=="kill" else "drive out"]
		return out
	var p:=catch_odds(willing,total)
	var cap:=willing*(KILLS_PER_HAND if how=="kill" else DRIVE_PER_HAND)*DAYS_MAX
	var caught_total:=0
	for c in cs:
		(c as Dictionary)["caught"]=_binom(rng,int((c as Dictionary).get("want",0)),p); caught_total+=int((c as Dictionary).caught)
	# A few hands do a few days' work; the rest run or hide before they come.
	if caught_total>cap:
		var scale:=float(cap)/float(caught_total)
		for c in cs: (c as Dictionary)["caught"]=floori(float((c as Dictionary).caught)*scale)
	var dead:=0; var moved:=0; var escaped:=0; var hid:=0
	if how=="kill":
		var kill_cells:Array=[]
		for c in cs:
			if int((c as Dictionary).caught)>0: kill_cells.append({"cohort":String((c as Dictionary).cohort),"sex":String((c as Dictionary).sex),"count":int((c as Dictionary).caught)})
		var died:Dictionary=GameState.register_population_deaths_by_cell(kill_cells,DEATH_ID,"%s were killed at the god's word." % _cap(_label(r_in)),_label(r_in))
		for row in died.get("cells",[]):
			for c in cs:
				if String((c as Dictionary).cohort)==String((row as Dictionary).cohort) and String((c as Dictionary).sex)==String((row as Dictionary).sex): (c as Dictionary)["dead"]=int((row as Dictionary).dead)
		dead=int(died.get("count",0))
	var work_lost:={}
	for c in cs:
		var cd:Dictionary=c
		var weights:={}
		for k in ALL: weights[k]=1.0 if k==String(cd.cohort) else 0.0
		if how=="kill":
			# Those not caught run as it begins: most leave the realm, the rest
			# hide with kin and stay (ESCAPED_LEAVE, a roll each).
			var rest:=int(cd.get("want",0))-int(cd.get("dead",0))
			var leaving:=_binom(rng,rest,ESCAPED_LEAVE)
			var ran:=0
			if leaving>0: ran=int(GameState.register_population_departures(leaving,"Fled the killing at the god's word",weights,String(cd.sex)).get("count",0))
			cd["fled"]=ran; escaped+=ran
			cd["hid"]=maxi(0,int(cd.get("want",0))-int(cd.get("dead",0))-ran); hid+=int(cd.hid)
			cd["gone"]=int(cd.get("dead",0))+ran
		else:
			var gone:=0
			if int(cd.caught)>0: gone=int(GameState.register_population_departures(int(cd.caught),"Driven out at the god's word",weights,String(cd.sex)).get("count",0))
			cd["moved"]=gone; moved+=gone
			cd["hid"]=maxi(0,int(cd.get("want",0))-gone); hid+=int(cd.hid)
			cd["gone"]=gone
		# Those named only for their work: gone from that work, each kind by its size.
		if not bool(cd.get("whole",false)) and not (cd.get("roles",{}) as Dictionary).is_empty():
			var roles:Dictionary=cd.roles
			var sum:=0.0
			for role in roles: sum+=float(roles[role])
			for role in roles: work_lost[role]=float(work_lost.get(role,0.0))+float(cd.gone)*float(roles[role])/maxf(0.000001,sum)
	# The rest of the people: a share flees the realm after it, the more the
	# more of their kin were killed or driven out.
	var fp:=flight_odds(dead+moved,pop_before,people,how)
	var kin:=_binom(rng,maxi(0,int(GameState.population_total)-1),fp)
	var kin_gone:=0
	if kin>0: kin_gone=int(GameState.register_population_departures(kin,"Fled the realm after the god's killing" if how=="kill" else "Left the realm after the god's driving out",{"children":1.0,"youth":1.0,"early_adults":1.0,"established_adults":1.0,"mature_adults":1.0,"elders":1.0}).get("count",0))
	# The women of child-bearing age killed or gone take their pregnancies with them.
	var fertile_after:=GameState.fertile_women()
	var share_lost:=clampf(1.0-fertile_after/fertile_before,0.0,1.0) if fertile_before>0.000001 else 0.0
	var preg_lost:=0
	if share_lost>=0.0001: preg_lost=roundi(GameState.lose_pregnancies(share_lost))
	GameState.synchronize_population_allocations()
	# The work split those losses leave (applied to the town's own split after).
	var trade_lost:=0.0
	for role in work_lost: trade_lost+=float(work_lost[role])
	if trade_lost>0.0:
		var kept:={}
		var sum_kept:=0.0
		for role in GameState.POPULATION_ROLES:
			kept[role]=maxf(0.0,float(work_before.get(role,0))-float(work_lost.get(role,0.0)))
			sum_kept+=float(kept[role])
		if sum_kept>0.0:
			var pct:={}
			for role in GameState.POPULATION_ROLES: pct[role]=float(kept[role])/sum_kept*100.0
			out["work_pct"]=pct
	var days:=ceili(float(dead+moved)/float(maxi(1,willing*(KILLS_PER_HAND if how=="kill" else DRIVE_PER_HAND))))
	out.ok=dead+moved>0
	out.dead=dead; out.moved=moved; out.escaped=escaped; out.hid=hid; out.kin_fled=kin_gone; out.pregnancies_lost=preg_lost
	out["catch_odds"]=p; out["flight_odds"]=fp; out["days"]=days
	out["fertile_before"]=roundi(fertile_before); out["fertile_after"]=roundi(fertile_after)
	out["trade_lost"]=trade_lost; out["work_lost"]=work_lost
	out["cells"]=cs
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
	var parts:=PackedStringArray([t])
	if kin_gone>0: parts.append("%s more of our people %s." % [_cap(_count(kin_gone)),"fled the realm after it" if how=="kill" else "went with them"])
	# Mothers among them: fewer births for as long as the women are fewer.
	if fertile_before-fertile_after>=1.0:
		var left:=roundi(fertile_after)
		parts.append("Fewer children will be born for years: of %s women of an age to bear, %s%s." % [_count(roundi(fertile_before)),"none are left" if left<=0 else "%s are left" % _count(left),(", and %s pregnancies were lost with them" % _count(preg_lost)) if preg_lost>0 else ""])
	out["words"]=" ".join(parts)
	return out

static func _burn(r_in:Dictionary,willing:int,people:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	## Our own village set on fire by our own hands: the houses, the stores, the
	## few who could not get out, and those who flee after. On stated shares.
	var home:=String(r_in.get("home","")) if String(r_in.get("home",""))!="" else (String(GameState.settlement_name) if String(GameState.settlement_name)!="" else "the village")
	var pop_before:=int(GameState.population_total)
	var fertile_before:=GameState.fertile_women()
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
	# The mothers among the dead and the fled take their pregnancies with them.
	var fertile_after:=GameState.fertile_women()
	var share_lost:=clampf(1.0-fertile_after/fertile_before,0.0,1.0) if fertile_before>0.000001 else 0.0
	var preg_lost:=roundi(GameState.lose_pregnancies(share_lost)) if share_lost>=0.0001 else 0
	GameState.synchronize_population_allocations()
	var out:={"ok":true,"dead":dead,"kin_fled":kin_gone,"houses_lost":houses_lost,"food_lost":food_lost,"timber_lost":timber_lost,"burned_share":burned_share,"flight_odds":fp,"pregnancies_lost":preg_lost}
	var parts:=PackedStringArray()
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
	# The people: dread and lost love, remembered at every hearth (once).
	DIVINE.record_people_act(String({"kill":"slaughter_people","burn":"burn_village","drive":"drive_out_people"}.get(how,"slaughter_people")))
	# The court hears what the god ordered done to their own kin, as it was:
	# out in the village, not in the hall; each of them takes it once.
	var heard:=_what_was_done(how,label,home,done)
	for p:Dictionary in Hall._officials():
		var pid:=int(p.get("person_id",0))
		if pid<=0 or pid==int(actor.get("person_id",0)): continue
		var personality:Dictionary=p.get("personality",{}) if p.get("personality") is Dictionary else {}
		var empathy:=clampf(float(personality.get("empathy",0.5)),0.0,1.0)
		GovernmentPeopleSystem.adjust_person_bonds(pid,{"fear":clampf(0.03+0.1*weight,0.03,0.1),"love":-clampf(0.02+0.12*weight+0.04*empathy,0.02,0.14),"resentment":clampf(0.01+0.05*empathy,0.01,0.06),"hold_days":120})
		GovernmentPeopleSystem.record_person_memory(pid,"The god had %s. I heard it at court." % heard,"divine",0.8,{"emotion":"horror" if empathy>=0.6 else "dread","outcome":"grave_home_"+how})
	# The one who carried it out carries it after.
	var pid2:=int(actor.get("person_id",0))
	if pid2>0:
		var person:=GovernmentPeopleSystem.person_snapshot(pid2)
		var personality2:Dictionary=person.get("personality",{}) if person.get("personality") is Dictionary else {}
		var empathy2:=clampf(float(personality2.get("empathy",0.5)),0.0,1.0)
		var reluctant:=String(ob.get("id",""))=="reluctant"
		GovernmentPeopleSystem.adjust_person_bonds(pid2,{"fear":0.08,"love":-0.12 if reluctant else -0.06,"obligation":0.02,"resentment":(0.06+0.1*empathy2) if reluctant else 0.02+0.04*empathy2,"hold_days":180})
		GovernmentPeopleSystem.record_person_memory(pid2,"At the god's word I had %s." % heard,"divine",0.95,{"emotion":"horror" if reluctant else "duty","outcome":"grave_home_"+how})
	elif String(actor.get("kind",""))=="figure":
		HistoricalFigures.note(String(actor.get("figure_id","")),_day(),"At the ruler's word they had %s." % heard)
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

static func _what_was_done(how:String,label:String,home:String,done:Dictionary)->String:
	## What was done, in true plain words, with its numbers.
	match how:
		"burn":
			var dead:=int(done.get("dead",0))
			return "%s, our own village, set on fire: houses for %d burned, %s" % [home,int(done.get("houses_lost",0)),("%d died in it" % dead) if dead>0 else "and nobody died in it"]
		"drive":
			return "%s driven out of the realm: %d of them" % [label,int(done.get("moved",0))]
	return "%s killed: %d dead, %d fled the realm" % [label,int(done.get("dead",0)),int(done.get("escaped",0))]

# --------------------------------------------------------------------------
# Words
# --------------------------------------------------------------------------

static func _count(n:int)->String:
	return preload("res://scripts/town_fate.gd")._count(n)

static func _days(n:int)->String:
	return "a day" if n<=1 else "%s days" % _count(n)

static func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)
