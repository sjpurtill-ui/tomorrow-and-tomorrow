extends RefCounted
## REALM ORDERS WITH REAL MECHANICS (docs/ADJUDICATION.md: every order, the
## same path; never say an order is carried out unless a mechanic did it).
##
## The rest of the game's own functions, ordered in plain words at court and
## carried out by the system that owns them (the same levers the docks and
## every people's controller use, civilization_orders.gd), never a vague
## standing directive:
##   deploy      "Form a war band of 8 of the fighters at home", "Put 6 warriors
##               in the field as a band": MilitaryCampaign.create_field_army.
##   training    "Drill the army hard", "Train them lightly to save food",
##               "Stop all training", "Train as before": the army's standing
##               training policy (military_training_staff.gd).
##   camp_drill  "Hold a camp drill", "Exercise the warriors at home": the camp
##               drill program.
##   line        "Keep 20 spears in store", "Always have ten clubs ready", "Keep
##               making bows": a workshop line that holds that stock.
##   stop_making "Stop making weapons", "The workshops should stop making
##               clubs": their lines paused, their batches cancelled (what is
##               unspent goes back to the stores).
##   carts       "Build 3 carts": carts from the workshops.
##   research    "Put our minds to growing more food", "Study healing": the
##               field's emphasis made first among what our thinkers study.
##   inquiry     "Learn to make pottery": that very question, when our people
##               can take it up now (or what they must learn first).
##   scouting    "Put more people on scouting", "Stop sending scouts out",
##               "Look for wandering bands who might join us", "Search for
##               stone and ore": the scouting staff's share and aim.
##   society     "Let strangers settle among us", "Keep our knowledge to
##               ourselves": how strangers are received and what is taught.
##   work_pace   "Press on with the great work", "Take care with the monument",
##               "Abandon the great work": the pace of the work being built.
##   build       "Build a granary", "Build five more huts", "We need more homes":
##               a named work put first by the builders (settlement_
##               construction.set_priority); homes go up by themselves as the
##               people need them, so the builders turn to shelter (the town's
##               focus, or more hands on building when the god sets the work).
##   defences    "Build a wall around the camp", "Put a palisade around our
##               town": the next stage of the town's defences (watch posts,
##               earthworks, palisade, walls).
##   found_town  "Found a new town by the river": the best site the leaders
##               know (by the river when asked) and a settler party sets out.
##   ration      "Ration the food", "Everyone eats less until the harvest": a
##               timed ration, as a crisis's ration is; "Stop rationing" ends it.
##   provisions  "Store more food for the winter": the town turned to provisions.
##   declare_war "Declare war on the Esurai": envoys carry the declaration; no
##               one marches until the god says where to strike.
##   envoy       "Send gifts to the Varesh", "Open trade with the Varesh":
##               envoys with a gift or a proposal (court_commands.dispatch_
##               envoy), or the plain reason none can go.
##   repair      "Mend the broken weapons": the damaged gear put in the
##               workshops to be mended.
##   sick_apart  "Keep the sick apart": the people's own custom from today.
##   clean_water "Drink only clean water": water from the clean spring for a
##               season, as in a flux: fewer fall sick, more hands carry it.
##   scout_party "Send scouts to find good stone", "Send a party to look for
##               wandering bands": one party with that aim.
## read(text) -> {kind, ...} or {}; perform(reading) -> {ok, kind, count,
## says, outcome}: says is the official's plain answer, outcome the narration;
## ok=false when nothing could be set in motion (and says why).
## Called through home_orders.gd, so every court path (the words offline, the
## live reader, a follow-up) reaches the same mechanic. Static; preload.

const Home:=preload("res://scripts/home_orders.gd")

## A blow at someone is the war leader's, even with a band named.
const STRIKE:="(?i)\\b(attack|strike|raid|besiege|storm|assault|invade|conquer|burn|against|kill|slay)\\b"
const QUESTION:="(?i)^\\s*(?:what|why|how|who|whom|where|when|whose|which)\\b"
## Others put to work ("make them build our walls", "have the captives dig a
## ditch", "get the men of Tsaren to raise a palisade"), never our own
## builders ("have our men build a palisade", "build our walls"): in a town
## we hold, the garrison's forced labour (occupation_measures.gd).
const OTHERS_WORK:="(?i)\\b(?:make|force|have|set|put|get|compel|drive)\\s+(?:them|those|these|them all|(?:all|each|some|most|half|the rest|every one) of them|(?:(?:all|some|most|half)\\s+(?:of\\s+)?)?(?:(?:the|their|its|these|those)\\s+)?(?:(?:bound|captured|conquered|defeated|taken|remaining|able|able-bodied|young|grown|strong|strongest|other)\\s+)?(?:captives|prisoners|slaves|hostages|men|males|menfolk|women|boys|youths|villagers|townsfolk|townspeople|inhabitants|residents|people|folk|families|survivors)(?:\\s+of\\s+(?!our\\b)[a-z'-]+)?)\\s+(?:to\\s+)?(?:work|labou?r|toil|dig|build|carry|haul|clear|till|plough|plow|repair|mend|raise|cut|fell|drag|quarry|put up|throw up|serve)(?:s|ed|ing)?\\b"

# --- The words -------------------------------------------------------------------

const BAND_FORM:="(?i)\\b(?:form|make|put together|assemble|organi[sz]e|gather|set up)\\s+(?:up\\s+)?(?:a|an|one|another|new|a new|our)\\s+(?:new\\s+)?(?:war\\s*band|band|host|company|troop|detachment|war party|army)\\b"
const IN_FIELD:="(?i)\\b(?:in|into)\\s+the\\s+field\\b"
const FIGHTERS:="(?i)\\b(warriors?|fighters?|soldiers?|men|spearmen|archers|bowmen|troops|trained)\\b"
const NEW_FIGHTERS:="(?i)\\b(recruits?|levies|conscripts?|draftees?|new (?:fighters|warriors|men|soldiers))\\b"

const TRAIN_WORDS:="(?i)\\b(train|trains|training|trained|drill|drills|drilling|drilled|exercise|exercises|practi[cs]e|skills?)\\b"
const TRAIN_HARD:="(?i)\\b(hard|harder|hardest|as hard as|every day|each day|daily|more (?:drill|training)|intensive(?:ly)?|constantly|all the time|day and night|without rest)\\b"
const TRAIN_LIGHT:="(?i)\\b(lightly|light|a little|only keep|keep up (?:their |the |our )?(?:[\\w']+ )?skills?|just enough|save food|less (?:drill|training)|ease off|go easy|nothing more)\\b"
const TRAIN_STOP:="(?i)\\b(?:stop|halt|suspend|cease|pause|end)\\b[^.!?]{0,30}?\\b(?:training|drill|drilling|exercises?)\\b|\\bno more (?:training|drill|drilling|exercises?)\\b|\\b(?:training|drill|drilling) (?:stops|must stop|is over|ends)\\b"
const TRAIN_USUAL:="(?i)\\b(as usual|as before|normal(?:ly)?|ordinary|resume|start (?:the )?(?:training|drill) again|again as before|regular(?:ly)?)\\b"
const CAMP_DRILL:="(?i)\\b(?:camp drill|hold (?:a )?(?:drill|muster|exercise|exercises)|exercise (?:the |our )?(?:warriors|fighters|men|army|soldiers|band)|drill (?:the |our )?(?:warriors|fighters|men|army|soldiers|band)(?: at home)?)\\b"

## The workshop items the words name: [item, words].
const ITEMS:=[["spear","\\bspears?\\b"],["improvised","\\b(?:clubs?|staves|staffs?|cudgels?)\\b"],["bow","\\bbows?\\b"],["sword_shield","\\b(?:swords?|shields?)\\b"],["lance","\\blances?\\b"]]
const ITEM_NAMES:={"spear":"spears","improvised":"clubs and sharpened staves","bow":"bows","sword_shield":"swords and shields","lance":"lances"}
const KEEP_STOCK:="(?i)\\b(?:keep|always have|make sure we (?:always )?have|hold|maintain|have)\\b[^.!?]{0,40}?\\b(?:in store|in the stores?|ready|on hand|at all times|always|at hand|stocked)\\b|\\balways\\b[^.!?]{0,40}\\bready\\b"
const KEEP_MAKING:="(?i)\\b(?:keep|never stop|go on|carry on|continue)\\s+making\\b|\\bmake [\\w ]{0,20}? (?:continuously|without stopping|all the time)\\b"
const STOP_MAKING:="(?i)\\b(?:stop|halt|cease|quit|pause|no more|don'?t|do not|leave off)\\b[^.!?]{0,30}?\\b(?:making|make|forging|producing|production of)\\b"
const WEAPONS:="(?i)\\b(weapons?|arms|gear|equipment)\\b"
const CARTS:="(?i)\\b(?:build|make|craft|put together|construct)\\b[^.!?]{0,30}?\\bcarts?\\b"

const RESEARCH_LEAD:="(?i)\\b(?:put (?:our |their |the people's |your )?minds? to|focus (?:our |the |your )?(?:learning|research|studies|study|inquiry|minds?|thinking|thinkers) on|turn (?:our |the |your )?(?:minds?|learning|attention|thinkers) to|study|studies|learn (?:more )?about|learn better ways (?:of|to)|learn (?:new )?ways (?:of|to)|learn to|learn how to|discover how to|find (?:out )?how to|work out how to|look into|i want (?:our |the )?(?:people|thinkers|scholars|wise ones) to (?:learn|study|know))\\b"
## The fields of learning (research domains), by the words people use.
const FIELDS:=[
	["nutrition","\\b(food|farming|farms?|fields|crops?|growing|grow|harvests?|seeds?|grain|gathering|hunting|hunt|fishing|herds?|herding|cooking|eating|feeding|the land's yield)\\b","getting food"],
	["health","\\b(heal|healing|healers?|sickness|sick|medicines?|health|alive|fevers?|wounds?|mothers|birthing)\\b","healing"],
	["security","\\b(war|warfare|fighting|fight|weapons?|defen[cs]e|defending|warriors?|battles?|arms)\\b","war and defence"],
	["infrastructure","\\b(build|building|houses?|huts?|homes|walls?|shelters?|wells?|water supply|stonework)\\b","building"],
	["production","\\b(crafts?|crafting|making things|pottery|pots|weaving|tools?|workshops?|metals?|copper|tanning|leather)\\b","crafts and making"],
	["logistics","\\b(travel|travelling|carrying|roads?|paths?|boats?|rafts?|crossing|hauling)\\b","travel and carrying"],
	["ecology","\\b(the land|seasons|animals|plants|forests?|soil|weather)\\b","the land and seasons"],
	["institutions","\\b(laws?|order|governing|rule|justice|council|keeping the peace)\\b","law and custom"],
	["culture","\\b(songs?|stories|rites|art|carving|painting|music|customs)\\b","song and custom"],
	["knowledge","\\b(counting|records?|writing|marks|teaching|stars|sky|numbers)\\b","learning and records"],
	["demography","\\b(children|families|marriages?|births|our numbers)\\b","families and children"],
	["labor","\\b(work|working|labou?r|the day's work)\\b","work and tools"],
]
## Words that name nothing to look for in a question's name.
const STOP_WORDS:=["make","how","better","more","new","ways","way","learn","study","discover","our","the","and","for","with","from","good","find","out","about","people","what","that","this","them","their","want","should","could","into"]
const SAME_WORDS:={"pots":"pottery","pot":"pottery","potter":"pottery","bows":"bow","boats":"boat","rafts":"raft","nets":"net","baskets":"basket","ropes":"cordage","rope":"cordage","cords":"cordage"}

const SCOUT_WORDS:="(?i)\\b(scouts?|scouting|scouting parties|parties out|explorers?|exploring|outriders)\\b"
const SCOUT_MORE:="(?i)\\b(?:more|increase|double|extra)\\b[^.!?]{0,30}?\\b(?:scouts?|scouting|parties)\\b|\\bscout (?:more|further|farther)(?: often)?\\b|\\b(?:put|send) more (?:people |hands |of us )?(?:on|to|into|out) scouting\\b"
const SCOUT_LESS:="(?i)\\b(?:fewer|less)\\b[^.!?]{0,30}?\\b(?:scouts?|scouting|parties)\\b|\\bscout less\\b"
const SCOUT_NONE:="(?i)\\b(?:stop|halt|cease|end|no more|don'?t|do not)\\b[^.!?]{0,20}?\\b(?:scouting|scouts|sending (?:out )?scouts|sending parties|exploring)\\b"
const SEEK_PEOPLE:="(?i)\\b(?:look|search|seek|find|scout)\\b[^.!?]{0,30}?\\b(?:wandering bands?|nomads?|wanderers|bands? who might join|people (?:who might|to) join|strangers to join|newcomers)\\b"
const SEEK_STONE:="(?i)\\b(?:look|search|seek|find|prospect|hunt)\\b[^.!?]{0,30}?\\b(?:stone|ore|copper|tin|flint|clay|metal|salt|resources?|good ground)\\b"

const STRANGERS:="(?i)\\b(strangers?|newcomers?|outsiders?|wanderers|foreigners|refugees|anyone who wants to join|those who want to join)\\b"
const WELCOME:="(?i)\\b(?:let|allow|welcome|take in|accept|open (?:our )?(?:gates|town|fires) to)\\b"
const KEEP_OUT:="(?i)\\b(?:keep\\b[^.!?]{0,30}?\\bout|turn\\b[^.!?]{0,30}?\\baway|send\\b[^.!?]{0,30}?\\baway|close (?:our )?(?:gates|town|fires)|no (?:strangers|newcomers|outsiders) may|refuse)\\b"
const KNOWLEDGE:="(?i)\\b(knowledge|what we know|our ways|our crafts|our skills|our secrets|crafts|skills|lore)\\b"
const SHARE:="(?i)\\b(?:share|teach|show|give)\\b"
const GUARD:="(?i)\\b(?:keep\\b[^.!?]{0,30}?\\b(?:to ourselves|secret|from (?:outsiders|strangers|others))|guard|hide|do not teach|don'?t teach|never teach|teach no one|no outsider)\\b"

const DECLARE:="(?i)\\b(?:declare war|declare (?:a )?war|we are at war with|we are now at war with|are our enemies)\\b"
const TRADE:="(?i)\\b(?:open trade|trade with|start trading|barter with|begin trading)\\b"
const GIFT:="(?i)\\b(?:send|give|bring|take|offer)\\b[^.!?]{0,30}?\\b(?:gifts?|presents?|tokens?|food|timber|wood|stone|clay|fib(?:re|er))\\b"
const GIFT_RESOURCES:=[["Food","\\b(?:food|meat|grain)\\b"],["Timber","\\b(?:timber|wood|logs)\\b"],["Stone","\\bstone\\b"],["Clay","\\bclay\\b"],["Fiber Plants","\\bfib(?:re|er)s?\\b"]]
const SEND_PARTY:="(?i)\\bsend\\b[^.!?]{0,20}?\\b(?:scouts?|a party|parties|searchers|people|outriders)\\b"
const HEADING:="(?i)\\b(north[- ]?east|north[- ]?west|south[- ]?east|south[- ]?west|north|south|east|west)\\b"
const HOMES:="(?i)\\b(?:build|put up|raise|make|we need|need)\\b[^.!?]{0,30}?\\b(?:huts?|houses?|homes?|shelters?|dwellings?|roofs?)\\b"
## Named works of the town and the words for them (settlement_construction.gd).
const WORKS_NAMED:=[["Storage Pits","\\b(?:granar(?:y|ies)|store for (?:the )?(?:grain|food)|grain store|storage pits?|pits for (?:the )?food|food store)\\b"],["Public Stores","\\b(?:public stores?|common store|counted store)\\b"],
	["Open Work Area","\\b(?:work ?area|work ?yard|workshop yard|workshops?)\\b"],["Framed Hall","\\b(?:hall|meeting house|long ?house)\\b"],["Gathering Yard","\\b(?:gathering yard|quarry yard|digging yard|yard for (?:the )?(?:diggers|cutters))\\b"],["Lean-to Shelters","\\blean-?tos?\\b"]]
## A building verb and its object's first words: "build a", "put up two",
## "raise some more".
const OBJECT:="(?i)\\b(?:build|put up|raise|make|dig|set up|construct)\\s+(?:(?:a|an|the|our|new|another|some|more|few|several|many|two|three|four|five|six|seven|eight|nine|ten|\\d+)\\s+){0,3}"
const BUILD_VERB:="(?i)\\b(?:build|put up|raise|make|dig|set up|construct|we need|need)\\b"
const DEFENCES:="(?i)\\b(?:walls?|palisades?|stockades?|fences?|earthworks?|ditch(?:es)?|ramparts?|watch ?posts?|defen[cs]es|fortifications?)\\b"
const ONE_TOWN:="(?i)\\b(?:found|start|build|make|settle|plant|begin)\\b[^.!?]{0,20}?\\b(?:a|an|one|another|new)\\s+(?:new\\s+)?(?:town|village|settlement|hamlet|camp|colony)\\b|\\bsend settlers\\b"
const RATION:="(?i)\\b(?:ration|rations|rationing|eat less|eats less|eating less|less food|smaller shares?|cut (?:the )?food|half rations|tighten (?:our )?belts)\\b"
const RATION_END:="(?i)\\b(?:stop (?:the )?rationing|end (?:the )?ration(?:ing|s)?|no more rationing|full rations|eat (?:fully|well) again)\\b"
const PROVISIONS:="(?i)\\b(?:store|keep|put by|lay (?:up|in|by)|save|stock (?:up)?)\\b[^.!?]{0,25}?\\bfood\\b|\\bmore food in (?:store|the pits|the stores)\\b|\\bfill the (?:pits|stores)\\b"
const MEND:="(?i)\\b(?:mend|repair|fix|sharpen|restore)\\b[^.!?]{0,30}?\\b(?:weapons?|spears?|gear|clubs?|bows?|shields?|arms|equipment)\\b"
const SICK_APART:="(?i)\\b(?:the )?sick\\b[^.!?]{0,40}?\\b(?:apart|away from|separate|alone|at their own fire)\\b|\\bkeep (?:the )?sick\\b"
const CLEAN_WATER:="(?i)\\b(?:boil|boiled|clean|safe|fresh|good|pure)\\b[^.!?]{0,20}?\\b(?:drinking )?water\\b"

const TOWN_BACK:="(?i)\\b(?:let|leave it to|hand (?:the town|it) back to|give (?:the town|it) back to)\\b[^.!?]{0,30}?\\b(?:leaders|headman|elders|chiefs?)\\b[^.!?]{0,30}?\\b(?:run|manage|decide|lead|keep)\\b[^.!?]{0,20}?\\b(?:the town|our town|the camp|it)\\b"
const TOWN_FOCUS:="(?i)\\b(?:turn|set|focus|put)\\b[^.!?]{0,15}?\\b(?:the town|our town|the camp|everyone|the people)\\b[^.!?]{0,15}?\\b(?:to|on)\\b"
const FOCUS_WORDS_TOWN:=[["shelter","\\b(?:shelter|homes|huts|houses|building)\\b"],["provisions","\\b(?:food|provisions|stores|harvest)\\b"],["water","\\bwater\\b"],["defense","\\b(?:defen[cs]e|guard|holding the ground)\\b"],["research","\\b(?:learning|study|research)\\b"],["balanced","\\b(?:balance|balanced|a bit of everything)\\b"]]

const WORK_WORDS:="(?i)\\b(great work|monument|stone circle|circle|shrine|temple|tomb|mound|the work|building of)\\b"
const PRESS:="(?i)\\b(press on|hurry|speed up|faster|push on|quicken|drive (?:them|the builders)|get it done)\\b"
const CAREFUL:="(?i)\\b(carefully|careful|take care|slow down|slowly|safely|no one hurt|nobody hurt)\\b"
const ABANDON:="(?i)\\b(abandon|give up|stop building|leave off|tear down|end the)\\b"


static func _re(pattern:String)->RegEx:
	var r:=RegEx.new(); r.compile(pattern)
	return r

static func _has(text:String,pattern:String)->bool:
	return _re(pattern).search(text)!=null


# --- Reading ---------------------------------------------------------------------

## The first realm order the words give, or {}.
static func read(text:String)->Dictionary:
	var clean:=text.strip_edges()
	if clean.is_empty() or clean.ends_with("?") or _has(clean,QUESTION): return {}
	var lower:=clean.to_lower().replace("’","'")
	var r:=_diplomacy(lower)
	if r.is_empty(): r=_scout_party(lower)
	if r.is_empty(): r=_deploy(lower)
	if r.is_empty(): r=_training(lower)
	if r.is_empty(): r=_camp_drill(lower)
	if r.is_empty(): r=_line(lower)
	if r.is_empty(): r=_stop_making(lower)
	if r.is_empty(): r=_carts(lower)
	if r.is_empty(): r=_scouting(lower)
	if r.is_empty(): r=_society(lower)
	if r.is_empty(): r=_work_pace(lower)
	if r.is_empty(): r=_repair(lower)
	if r.is_empty(): r=_found_town(lower)
	if r.is_empty(): r=_build(lower)
	if r.is_empty(): r=_town(lower)
	if r.is_empty(): r=_ration(lower)
	if r.is_empty(): r=_provisions(lower)
	if r.is_empty(): r=_health(lower)
	if r.is_empty(): r=_research(lower)
	return r


## Whether the words put others to work (OTHERS_WORK), not our own people.
static func others_at_work(text:String)->bool:
	return _has(text.strip_edges().to_lower().replace("’","'"),OTHERS_WORK)


static func _foreign(lower:String)->bool:
	return Home._names_foreign(lower)


static func _deploy(lower:String)->Dictionary:
	if _has(lower,STRIKE) or _foreign(lower) or _has(lower,NEW_FIGHTERS): return {}
	var formed:=_has(lower,BAND_FORM) or (_has(lower,IN_FIELD) and _has(lower,FIGHTERS))
	if not formed: return {}
	return {"kind":"deploy","count":Home.number_in(lower)}


static func _training(lower:String)->Dictionary:
	if _has(lower,NEW_FIGHTERS) or _has(lower,STRIKE) or _foreign(lower): return {}
	var about:=_has(lower,TRAIN_WORDS)
	if not about: return {}
	if _has(lower,TRAIN_STOP): return {"kind":"training","policy":"suspended"}
	if _has(lower,TRAIN_HARD): return {"kind":"training","policy":"intensive"}
	if _has(lower,TRAIN_LIGHT): return {"kind":"training","policy":"maintain"}
	if _has(lower,TRAIN_USUAL) and _has(lower,FIGHTERS+"|\\b(army|band|training|drill)\\b"): return {"kind":"training","policy":"regular"}
	return {}


static func _camp_drill(lower:String)->Dictionary:
	if _has(lower,NEW_FIGHTERS) or _has(lower,STRIKE) or _foreign(lower): return {}
	if not _has(lower,CAMP_DRILL): return {}
	return {"kind":"camp_drill"}


static func _item(lower:String)->String:
	for pair in ITEMS:
		if _has(lower,String(pair[1])): return String(pair[0])
	return ""


static func _line(lower:String)->Dictionary:
	var item:=_item(lower)
	if item=="" or _has(lower,STOP_MAKING): return {}
	if _has(lower,KEEP_MAKING): return {"kind":"line","item":item,"target":0}
	var n:=Home.number_in(lower)
	if n>0 and _has(lower,KEEP_STOCK): return {"kind":"line","item":item,"target":n}
	return {}


static func _stop_making(lower:String)->Dictionary:
	if not _has(lower,STOP_MAKING): return {}
	var item:=_item(lower)
	if item=="" and not _has(lower,WEAPONS): return {}
	return {"kind":"stop_making","item":item}


static func _carts(lower:String)->Dictionary:
	if not _has(lower,CARTS): return {}
	return {"kind":"carts","count":Home.number_in(lower)}


static func _scouting(lower:String)->Dictionary:
	if _foreign(lower) or _has(lower,STRIKE): return {}
	if _has(lower,SEEK_PEOPLE): return {"kind":"scouting","focus":"recruitment","change":"aim"}
	if _has(lower,SEEK_STONE) and _has(lower,SCOUT_WORDS+"|\\b(?:search|prospect|look)\\b"): return {"kind":"scouting","focus":"prospecting","change":"aim"}
	if not _has(lower,SCOUT_WORDS): return {}
	if _has(lower,SCOUT_NONE): return {"kind":"scouting","change":"none"}
	if _has(lower,SCOUT_LESS): return {"kind":"scouting","change":"less"}
	if _has(lower,SCOUT_MORE): return {"kind":"scouting","change":"more"}
	return {}


static func _society(lower:String)->Dictionary:
	if _has(lower,STRIKE): return {}
	if _has(lower,STRANGERS):
		if _has(lower,KEEP_OUT): return {"kind":"society","migration":"consolidate"}
		if _has(lower,WELCOME): return {"kind":"society","migration":"welcome"}
	if _has(lower,KNOWLEDGE):
		if _has(lower,GUARD): return {"kind":"society","sharing":"guarded"}
		if _has(lower,SHARE) and _has(lower,"(?i)\\b(neighbou?rs|others|strangers|outsiders|freely|everyone|other peoples|all who ask)\\b"): return {"kind":"society","sharing":"open"}
	return {}


static func _work_pace(lower:String)->Dictionary:
	if not _has(lower,WORK_WORDS) or _foreign(lower): return {}
	if _has(lower,ABANDON): return {"kind":"work_pace","policy":"abandon"}
	if _has(lower,PRESS): return {"kind":"work_pace","policy":"press"}
	if _has(lower,CAREFUL): return {"kind":"work_pace","policy":"careful"}
	return {}


static func _research(lower:String)->Dictionary:
	var lead:=_re(RESEARCH_LEAD).search(lower)
	if lead==null or _has(lower,STRIKE) or _foreign(lower): return {}
	var rest:=lower.substr(lead.get_end())
	# "Focus our learning on food", "put our minds to healing": a whole field,
	# never one question that happens to share a word.
	if _has(lead.get_string(),"(?i)\\b(focus|minds?|turn)\\b"):
		for field in FIELDS:
			if _has(rest,"(?i)"+String(field[1])): return {"kind":"research","field":String(field[0]),"words":String(field[2]),"later":""}
		return {}
	var specific:=inquiry_for(rest)
	var open:=not specific.is_empty() and (String(specific.id) in WorldSimulation.state.known_discoveries or WorldSimulation.discovery._discovery_is_eligible(specific,int(WorldSimulation.state.elapsed_days)))
	if open: return {"kind":"inquiry","id":String(specific.id),"words":rest.strip_edges()}
	for field in FIELDS:
		if _has(rest,"(?i)"+String(field[1])): return {"kind":"research","field":String(field[0]),"words":String(field[2]),"later":String(specific.get("id","")) if not specific.is_empty() else ""}
	if not specific.is_empty(): return {"kind":"inquiry","id":String(specific.id),"words":rest.strip_edges()}
	return {}


## The question of learning the words name ("pottery", "how to make pots"),
## by the words of its name; {} when none is named plainly enough.
static func inquiry_for(words:String)->Dictionary:
	if Engine.get_main_loop()==null or WorldSimulation.discovery==null: return {}
	var wanted:=_content_words(words)
	if wanted.is_empty(): return {}
	var best:={}
	var best_score:=0.0
	var catalog:Dictionary=WorldSimulation.discovery.catalog_by_id
	for id in catalog:
		var d:Dictionary=catalog[id]
		var name_words:=_content_words(String(d.get("name","")))
		if name_words.is_empty(): continue
		var hits:=0
		for w in wanted:
			if name_words.has(w): hits+=1
		if hits==0: continue
		# All the words asked for, in as short a name as possible.
		var score:=float(hits)/float(wanted.size())+float(hits)/float(name_words.size())*0.5
		if score>best_score: best_score=score;best=d
	return best if best_score>=0.9 else {}


static func _content_words(text:String)->Array:
	var out:Array=[]
	for m in _re("[a-z]+").search_all(text.to_lower()):
		var w:=m.get_string()
		w=String(SAME_WORDS.get(w,w))
		if w.length()<4 or STOP_WORDS.has(w): continue
		if w.ends_with("ies"): w=w.substr(0,w.length()-3)+"y"
		elif w.ends_with("s") and not w.ends_with("ss"): w=w.substr(0,w.length()-1)
		if not out.has(w): out.append(w)
	return out


## The people the words name (another people we know), or {}.
static func _people_named(lower:String)->Dictionary:
	if Engine.get_main_loop()==null or WorldSimulation.world==null: return {}
	for c in WorldSimulation.world.civilizations:
		if not c is Dictionary or String((c as Dictionary).get("id",""))=="player": continue
		var name:=String((c as Dictionary).get("name","")).to_lower().trim_prefix("the ")
		if name.length()>=3 and _has(lower,"(?i)\\b"+name+"s?\\b"): return c
	return {}


static func _diplomacy(lower:String)->Dictionary:
	var civ:=_people_named(lower)
	if civ.is_empty(): return {}
	var id:=String(civ.get("id",""))
	# A small people's fight is a feud (conflict_scale.gd): the war leader
	# takes "declare war on them" as the order to go after them, not an
	# embassy (court_war_orders.gd).
	if _has(lower,DECLARE):
		if not bool((load("res://scripts/war_loop.gd") as GDScript).call("formal",id)): return {}
		return {"kind":"declare_war","civ_id":id}
	if _has(lower,STRIKE): return {}
	if _has(lower,TRADE): return {"kind":"envoy","purpose":"trade","civ_id":id}
	if _has(lower,GIFT):
		var resource:=""
		for pair in GIFT_RESOURCES:
			if _has(lower,"(?i)"+String(pair[1])): resource=String(pair[0]); break
		return {"kind":"envoy","purpose":"gift","civ_id":id,"resource":resource if resource!="" else "Food","amount":Home.number_in(lower)}
	return {}


static func _scout_party(lower:String)->Dictionary:
	if not _has(lower,SEND_PARTY) or _foreign(lower) or _has(lower,STRIKE): return {}
	var aim:=""
	if _has(lower,SEEK_STONE): aim="prospecting"
	elif _has(lower,SEEK_PEOPLE): aim="people"
	if aim=="": return {}
	var heading:=""
	var m:=_re(HEADING).search(lower)
	if m!=null: heading=m.get_string(1).replace("-","").replace(" ","")
	return {"kind":"scout_party","aim":aim,"heading":heading}


static func _repair(lower:String)->Dictionary:
	return {"kind":"repair"} if _has(lower,MEND) else {}


static func _found_town(lower:String)->Dictionary:
	if not _has(lower,ONE_TOWN) or _foreign(lower) or _has(lower,STRIKE) or _has(lower,RESEARCH_LEAD): return {}
	return {"kind":"found_town","river":_has(lower,"(?i)\\b(river|stream|water|lake|shore|ford)\\b")}


static func _build(lower:String)->Dictionary:
	if _foreign(lower) or _has(lower,STRIKE) or _has(lower,"(?i)\\b(great|monument|temple|shrine|tomb|circle|statue)\\b"): return {}
	# Weapons named are the workshops' making, and "learn to build" is study.
	if _item(lower)!="" or _has(lower,RESEARCH_LEAD): return {}
	if not _has(lower,BUILD_VERB) and not _has(lower,"(?i)\\b(?:put|set)\\b[^.!?]{0,20}?\\b(?:around|round|about)\\b"): return {}
	# What is built is the verb's own object ("build a granary", "put a
	# palisade around our town"), never a word further on ("build roads between
	# the houses" builds roads).
	if _has(lower,OBJECT+"(?:"+DEFENCES.trim_prefix("(?i)")+")") or _has(lower,"(?i)\\b(?:put|set)\\s+(?:up\\s+)?(?:a|an|the|our|some)?\\s*(?:walls?|palisades?|stockades?|fences?|ditch(?:es)?|ramparts?|watch ?posts?)\\b"): return {"kind":"defences"}
	for pair in WORKS_NAMED:
		if _has(lower,OBJECT+String(pair[1]).trim_prefix("\\b")): return {"kind":"build","work":String(pair[0])}
	if _has(lower,OBJECT+"(?:more\\s+)?(?:huts?|houses?|homes?|shelters?|dwellings?|roofs?)\\b") or _has(lower,"(?i)\\b(?:we need|need)\\s+(?:more\\s+)?(?:huts|houses|homes|shelter|roofs)\\b"): return {"kind":"build","work":"homes","count":Home.number_in(lower)}
	return {}


static func _town(lower:String)->Dictionary:
	if _has(lower,TOWN_BACK): return {"kind":"town_focus","focus":"leaders"}
	if not _has(lower,TOWN_FOCUS): return {}
	for pair in FOCUS_WORDS_TOWN:
		if _has(lower,"(?i)"+String(pair[1])): return {"kind":"town_focus","focus":String(pair[0])}
	return {}


static func _ration(lower:String)->Dictionary:
	if _has(lower,RATION_END): return {"kind":"ration","end":true}
	if _has(lower,RATION): return {"kind":"ration","end":false}
	return {}


static func _provisions(lower:String)->Dictionary:
	return {"kind":"provisions"} if _has(lower,PROVISIONS) else {}


static func _health(lower:String)->Dictionary:
	if _has(lower,SICK_APART): return {"kind":"sick_apart"}
	if _has(lower,CLEAN_WATER) and _has(lower,"(?i)\\b(drink|drinking|boil|only|use|water for)\\b"): return {"kind":"clean_water","boil":_has(lower,"(?i)\\bboil")}
	return {}


# --- Carrying them out ---------------------------------------------------------------

static func perform(reading:Dictionary)->Dictionary:
	match String(reading.get("kind","")):
		"deploy": return _form_band(reading)
		"training": return _set_training(reading)
		"camp_drill": return _hold_drill()
		"line": return _keep_stock(reading)
		"stop_making": return _stop(reading)
		"carts": return _make_carts(reading)
		"research": return _emphasis(reading)
		"inquiry": return _inquiry(reading)
		"scouting": return _scouting_policy(reading)
		"society": return _society_policy(reading)
		"work_pace": return _pace(reading)
		"build": return _build_work(reading)
		"defences": return _defences()
		"found_town": return _found(reading)
		"ration": return _set_ration(reading)
		"provisions": return _lay_in(reading)
		"declare_war": return _declare(reading)
		"envoy": return _envoy(reading)
		"repair": return _mend()
		"sick_apart": return _keep_sick_apart()
		"clean_water": return _water(reading)
		"scout_party": return _party(reading)
		"town_focus": return _town_focus(reading)
	return {"ok":false,"kind":"","says":"","outcome":""}


static func _no(kind:String,says:String,outcome:String="")->Dictionary:
	return {"ok":false,"kind":kind,"count":0,"says":says,"outcome":outcome if outcome!="" else "Nothing is set in motion: "+_lower_first(says)}

static func _lower_first(text:String)->String:
	return text.substr(0,1).to_lower()+text.substr(1) if text!="" else text

static func _plain(error:String)->String:
	if "settlement is unlocated" in error: return "Nobody knows where they live yet: scouts must find their home before envoys can go to them."
	var m:=_re("^Insufficient (.+?): need ([0-9.]+)\\.").search(error)
	if m!=null: return "There is not enough %s in the stores (%d is needed)." % [m.get_string(1),ceili(float(m.get_string(2)))]
	if error.begins_with("All ") and "production lines" in error: return "Every workshop line is already at other work."
	return error


static func _form_band(reading:Dictionary)->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null: return _no("deploy","There is nobody to form a band from.")
	var home:=int(mc.home_army.get("troops",0))
	if home<=0: return _no("deploy","Nobody trained is at home to form a band. Raise and drill a levy first.")
	var asked:=int(reading.get("count",0))
	var n:=mini(asked,home) if asked>0 else home
	var made:Dictionary=mc.create_field_army(n,"")
	if made.has("error"): return _no("deploy",_plain(String(made.error)))
	var band:Dictionary=made.get("army",{}) if made.get("army") is Dictionary else {}
	var troops:=int(band.get("troops",n))
	var short:=(" Only %d trained are at home." % home) if asked>home else ""
	var keep:=home-troops
	return {"ok":true,"kind":"deploy","count":troops,"army_id":int(band.get("army_id",0)),
		"says":"%d of the trained at home form a band. They stand ready at the camp until you give them somewhere to go.%s%s" % [troops,short,(" %d stay at home to keep watch." % keep) if keep>0 else ""],
		"outcome":"A band of %d is formed at home and stands ready." % troops}


const TRAINING_WORDS:={
	"intensive":["They train hard from today: more of them at drill, more often, and more food and gear spent on it.","hard"],
	"maintain":["They train only enough to keep their skills: little drill, little food spent on it.","lightly"],
	"suspended":["All drill stops from today. Nobody trains, and nothing is spent on it, until you give the word.","not at all"],
	"regular":["They train as before: steady drill, a quarter of them at a time.","as before"],
}

static func _set_training(reading:Dictionary)->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null or mc.training_staff==null: return _no("training","There is nobody under arms to train.")
	var policy:=String(reading.get("policy","regular"))
	var was:=String((mc.training_staff.policy("army") as Dictionary).get("id","regular"))
	var set:Variant=mc.training_staff.set_policy("army",policy)
	if set is Dictionary and (set as Dictionary).has("error"): return _no("training",_plain(String(set.error)))
	var words:Array=TRAINING_WORDS.get(policy,TRAINING_WORDS.regular)
	var same:=" That was already the way of it." if was==policy else ""
	return {"ok":true,"kind":"training","count":1,"policy":policy,"says":String(words[0])+same,"outcome":"The army trains %s from today." % String(words[1])}


static func _hold_drill()->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null: return _no("camp_drill","There is nobody under arms to drill.")
	var home:=int(mc.home_army.get("troops",0))
	if home<=0: return _no("camp_drill","There is nobody under arms at home to drill.")
	if not (mc.training_program as Dictionary).is_empty(): return {"ok":true,"kind":"camp_drill","count":home,"says":"The %d at home are already at camp drill." % home,"outcome":"The camp drill goes on."}
	var began:Dictionary=mc.start_training_program("camp_drill")
	if began.has("error"): return _no("camp_drill",_plain(String(began.error)))
	return {"ok":true,"kind":"camp_drill","count":home,"says":"The %d under arms at home go to camp drill: musters, signals and changes of formation, for about %d days." % [home,roundi(float(mc.TRAINING_PROGRAMS.camp_drill.duration_days))],
		"outcome":"The %d under arms at home begin camp drill." % home}


static func _persistent_line(mc:Variant,item:String)->Dictionary:
	for job in mc.equipment_queue:
		if bool((job as Dictionary).get("persistent",false)) and String((job as Dictionary).get("item",""))==item: return job
	return {}


static func _keep_stock(reading:Dictionary)->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null: return _no("line","There are no workshops to set.")
	var item:=String(reading.get("item","spear"))
	var target:=int(reading.get("target",0))
	var names:=String(ITEM_NAMES.get(item,item))
	var stock:=int((mc.military_inventory as Dictionary).get(item,0))
	var keep_words:=("keep %d %s in store" % [target,names]) if target>0 else "keep making %s without stopping" % names
	var line:=_persistent_line(mc,item)
	if not line.is_empty():
		var set:Dictionary=mc.configure_production_line(int(line.id),target,false)
		if set.has("error"): return _no("line",_plain(String(set.error)))
	else:
		var started:Dictionary=mc.start_production_line(item,target)
		if started.has("error"):
			var turned:=false
			if String(started.error).begins_with("All "):
				# Every line is taken: an idle line is turned over to them.
				for job in mc.equipment_queue:
					var j:Dictionary=job
					if not bool(j.get("persistent",false)) or not bool(j.get("paused",false)): continue
					if mc.retool_production_line(int(j.id),item).has("error"): continue
					if mc.configure_production_line(int(j.id),target,false).has("error"): continue
					turned=true;break
			if not turned: return _no("line",_plain(String(started.error)))
	var now:=(" There are %d in store now." % stock) if target>0 else ""
	return {"ok":true,"kind":"line","count":maxi(1,target),"item":item,"target":target,
		"says":"A workshop line will %s, making more whenever they are taken.%s" % [keep_words,now],
		"outcome":"A workshop line is set to %s." % keep_words}


static func _stop(reading:Dictionary)->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null: return _no("stop_making","There are no workshops to stop.")
	var item:=String(reading.get("item",""))
	var paused:=0; var cancelled:=0
	for job in (mc.equipment_queue as Array).duplicate():
		var j:Dictionary=job
		var what:=String(j.get("item",""))
		if not ITEM_NAMES.has(what) or (item!="" and what!=item): continue
		if bool(j.get("persistent",false)):
			if bool(j.get("paused",false)): continue
			if not mc.configure_production_line(int(j.id),int(j.get("target_stock",0)),true).has("error"): paused+=1
		elif String(j.get("job_type","production"))=="production":
			if not mc.cancel_equipment_job(int(j.id)).has("error"): cancelled+=1
	var what_words:=String(ITEM_NAMES.get(item,"weapons")) if item!="" else "weapons"
	if paused+cancelled==0: return {"ok":true,"kind":"stop_making","count":0,"says":"Nothing is being made now: no workshop is at %s." % what_words,"outcome":"No workshop was making %s." % what_words}
	var parts:PackedStringArray=PackedStringArray()
	if paused>0: parts.append("%d %s paused" % [paused,"line" if paused==1 else "lines"])
	if cancelled>0: parts.append("%d %s set aside, and what was not yet used goes back to the stores" % [cancelled,"batch" if cancelled==1 else "batches"])
	return {"ok":true,"kind":"stop_making","count":paused+cancelled,"says":"The workshops stop making %s: %s." % [what_words,", ".join(parts)],"outcome":"The workshops stop making %s." % what_words}


static func _make_carts(reading:Dictionary)->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null: return _no("carts","There are no workshops to make carts.")
	var n:=maxi(1,int(reading.get("count",0)))
	var queued:Dictionary=mc.queue_transport_cart_production(n)
	if queued.has("error"):
		var why:=String(queued.error)
		if "Requires inquiry" in why or "joinery" in why.to_lower(): why="Our people do not yet know how to join timber well enough to build a cart."
		return _no("carts",_plain(why))
	return {"ok":true,"kind":"carts","count":n,"says":"The workshops will build %d %s: about %d days of work, and the timber is set aside now." % [n,"cart" if n==1 else "carts",ceili(float(queued.get("work_days",0.0)))],
		"outcome":"%d %s put in hand in the workshops." % [n,"cart" if n==1 else "carts"]}


static func _emphasis(reading:Dictionary)->Dictionary:
	var field:=String(reading.get("field",""))
	var state:Variant=WorldSimulation.state
	if field=="" or not (state.research_allocations as Dictionary).has(field): return _no("research","Our thinkers do not know what to turn to.")
	var top:=0
	for k in state.research_allocations: top=maxi(top,int(state.research_allocations[k]))
	var was:=int(state.research_allocations.get(field,0))
	var weight:=clampi(maxi(top+2,4) if was<top+2 else was,0,12)
	var done:=WorldSimulation.submit("player",{"kind":"research_emphasis","domain":field,"weight":weight})
	if done.has("error"): return _no("research",_plain(String(done.error)))
	var later:=""
	if String(reading.get("later",""))!="":
		later=" %s itself must wait until they know more." % _cap(String(WorldSimulation.discovery.discovery_definition(String(reading.later)).get("name","It")).to_lower())
	return {"ok":true,"kind":"research","count":1,"field":field,"weight":weight,
		"says":"Our thinkers turn to %s: from today it comes first among what they study.%s" % [String(reading.get("words",field)),later],
		"outcome":"%s is made first among what our thinkers study." % String(reading.get("words",field)).capitalize()}


static func _inquiry(reading:Dictionary)->Dictionary:
	var id:=String(reading.get("id",""))
	var d:Dictionary=WorldSimulation.discovery.discovery_definition(id)
	if d.is_empty(): return _no("inquiry","Nobody knows what that would be.")
	var name:=String(d.get("name",id))
	if id in WorldSimulation.state.known_discoveries: return {"ok":true,"kind":"inquiry","count":0,"says":"We already know %s." % name.to_lower(),"outcome":"%s is already known." % name}
	var day:=int(WorldSimulation.state.elapsed_days)
	if not WorldSimulation.discovery._discovery_is_eligible(d,day):
		var first:PackedStringArray=PackedStringArray()
		for r in d.get("requires",[]):
			if not String(r) in WorldSimulation.state.known_discoveries:
				first.append(String(WorldSimulation.discovery.discovery_definition(String(r)).get("name",String(r))).to_lower())
		var need:=(" First we must learn %s." % " and ".join(first.slice(0,2))) if not first.is_empty() else " It is beyond what our people can take up now."
		return _no("inquiry","We cannot take up %s yet.%s" % [name.to_lower(),need])
	var field:=String(d.get("dynamic",""))
	if field!="" and int((WorldSimulation.state.research_allocations as Dictionary).get(field,0))<=0:
		WorldSimulation.submit("player",{"kind":"research_emphasis","domain":field,"weight":4})
	var chosen:=WorldSimulation.submit("player",{"kind":"research_target","id":id})
	if chosen.has("error") or not bool(chosen.get("ok",true)): return _no("inquiry",_plain(String(chosen.get("error",chosen.get("reason","It cannot be taken up now.")))))
	return {"ok":true,"kind":"inquiry","count":1,"id":id,"says":"Our thinkers take up %s now; it will take as long as it takes, and they will tell you what they find." % name.to_lower(),
		"outcome":"%s is taken up by our thinkers." % name}


const FOCUS_WORDS:={"exploration":"exploring the land","recruitment":"looking for wandering bands who might join us","prospecting":"looking for stone and ore"}

static func _scouting_policy(reading:Dictionary)->Dictionary:
	var staff:Variant=WorldSimulation.world.scouting_staff if WorldSimulation.world!=null else null
	if staff==null: return _no("scouting","There is nobody to send.")
	var share:=float(staff.data.get("share",0.0))
	var focus:=String(staff.data.get("focus","exploration"))
	match String(reading.get("change","")):
		"none": share=0.0
		"less": share=maxf(0.0,share-0.02)
		"more": share=minf(0.10,maxf(share+0.02,0.03))
		"aim":
			focus=String(reading.get("focus",focus))
			share=maxf(share,0.03)
	var set:Dictionary=staff.set_policy(snappedf(share,0.005),focus,false)
	if set.has("error"): return _no("scouting",_plain(String(set.error)))
	var pop:=maxi(1,int(WorldSimulation.state.population_total))
	var people:=roundi(float(pop)*share)
	var says:=""
	if share<=0.0: says="No more parties go out. Those already away will finish and come home."
	else: says="From now on about %d of our people, %d in a hundred, go out scouting in turns, %s." % [people,roundi(share*100.0),String(FOCUS_WORDS.get(focus,"exploring the land"))]
	return {"ok":true,"kind":"scouting","count":1,"share":share,"focus":focus,"says":says,"outcome":"The scouting is set: %s." % ("none" if share<=0.0 else "%d in a hundred, %s" % [roundi(share*100.0),String(FOCUS_WORDS.get(focus,""))])}


static func _society_policy(reading:Dictionary)->Dictionary:
	var ex:=preload("res://scripts/society_exchange.gd")
	var now:Dictionary=ex.data()
	var migration:=String(reading.get("migration",now.get("migration_policy","balanced")))
	var sharing:=String(reading.get("sharing",now.get("sharing_policy","selective")))
	var set:Dictionary=ex.policy(migration,sharing)
	if set.has("error"): return _no("society",_plain(String(set.error)))
	var says:=""
	if reading.has("migration"):
		says="Strangers who come to us are taken in and given a place at the fires." if migration=="welcome" else ("Strangers are turned away; those already among us stay." if migration=="consolidate" else "Strangers are taken in as before, a few at a time.")
	else:
		says="Our crafts and ways are taught to any people who ask." if sharing=="open" else ("What we know stays with us; nobody outside is taught our crafts." if sharing=="guarded" else "We teach others as before, a little at a time.")
	return {"ok":true,"kind":"society","count":1,"says":says,"outcome":says}


const PACE_WORDS:={"press":["The builders are driven harder: it goes faster, and more of them will be hurt.","pressed on"],"careful":["The builders go carefully: slower, and fewer are hurt.","taken carefully"],"abandon":["The work is given up. What was built stands as it is.","abandoned"]}

static func _pace(reading:Dictionary)->Dictionary:
	var city_id:=String(WorldSimulation.settlements._primary_settlement_id()) if WorldSimulation.settlements!=null else ""
	var city:Dictionary=WorldSimulation.settlements.settlement_record(city_id) if city_id!="" else {}
	var work:Dictionary={}
	for r in city.get("undertakings",[]):
		if r is Dictionary and String((r as Dictionary).get("status","")) in ["building","stalled"]: work=r;break
	if work.is_empty(): return _no("work_pace","No great work is being built now.")
	var policy:=String(reading.get("policy","careful"))
	var done:=WorldSimulation.submit("player",{"kind":"great_work_policy","city":city_id,"id":String(work.id),"policy":policy})
	if done.has("error"): return _no("work_pace",_plain(String(done.error)))
	var words:Array=PACE_WORDS.get(policy,PACE_WORDS.careful)
	var name:=String(work.get("name","the great work"))
	return {"ok":true,"kind":"work_pace","count":1,"says":String(words[0]),"outcome":"%s is %s." % [name,String(words[1])]}


static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text


static func _city_id()->String:
	var sid:=String(WorldSimulation.state.get("selected_player_settlement_id")) if "selected_player_settlement_id" in WorldSimulation.state else ""
	return sid if sid!="" else String(WorldSimulation.settlements._primary_settlement_id())


static func _build_work(reading:Dictionary)->Dictionary:
	var sid:=_city_id()
	var work:=String(reading.get("work","homes"))
	if work=="homes":
		var housing:=int(WorldSimulation.state.housing_capacity)
		var people:=int(WorldSimulation.state.population_total)
		if not "Lean-to Shelters" in WorldSimulation.state.settlement_completed:
			var first:Dictionary=preload("res://scripts/settlement_construction.gd").set_priority(sid,"Lean-to Shelters")
			if first.has("error"): return _no("build",_plain(String(first.error)))
			return {"ok":true,"kind":"build","count":1,"says":"The builders put up the lean-to shelters first; after them, huts go up as the people need them.","outcome":"The lean-to shelters are put first by the builders."}
		if bool(WorldSimulation.direction.automatic_work):
			var focus:Dictionary=WorldSimulation.government.set_settlement_focus(sid,"shelter")
			if not bool(focus.get("ok",false)): return _no("build",_plain(String(focus.get("reason","The builders cannot turn to homes now."))))
			return {"ok":true,"kind":"build","count":1,"says":"The town is turned to building shelter until you say otherwise: more hands build, and new huts go up as the builders get to them. There are places for %d and we are %d." % [housing,people],
				"outcome":"The town is turned to building shelter."}
		var n:=maxi(3,int(reading.get("count",0))*2)
		var moved:Dictionary=preload("res://scripts/manual_work.gd").move("Construction",n)
		if not bool(moved.get("ok",false)): return _no("build",_plain(String(moved.get("reason","Nobody could be moved to building."))))
		return {"ok":true,"kind":"build","count":int(moved.get("moved",n)),"says":"%d more go to building, so homes go up sooner. There are places for %d and we are %d." % [int(moved.get("moved",n)),housing,people],
			"outcome":"%d more hands go to building homes." % int(moved.get("moved",n))}
	if work in WorldSimulation.state.settlement_completed:
		return {"ok":true,"kind":"build","count":0,"says":"The %s already stand." % work.to_lower(),"outcome":"The %s already stand." % work.to_lower()}
	var set:Dictionary=preload("res://scripts/settlement_construction.gd").set_priority(sid,work)
	if set.has("error"): return _no("build",_plain(String(set.error)))
	return {"ok":true,"kind":"build","count":1,"says":"The builders put the %s first. They go up as soon as what they need is at hand." % work.to_lower(),"outcome":"The %s are put first by the builders." % work.to_lower()}


static func _defences()->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null: return _no("defences","There is nobody to raise defences.")
	var began:Dictionary=mc.start_settlement_defense_upgrade()
	if began.has("error"): return _no("defences",_plain(String(began.error)))
	var index:=int(mc.settlement_defense.get("project_stage",-1))
	var stages:Array=mc.SETTLEMENT_DEFENSE_STAGES
	var stage:=String((stages[index] as Dictionary).get("short","the next defences")).to_lower() if index>=0 and index<stages.size() else "the next defences"
	var later:=" Walls come stage by stage: this is the next one." if index>=0 and index<3 else ""
	return {"ok":true,"kind":"defences","count":1,"says":"The watch begin the %s around the town, with the materials set aside now; you can see it rise on the map.%s" % [stage,later],"outcome":"Work begins on the %s around the town." % stage}


## Test seam (never set by the game): returns the site to found at, or
## Vector2.INF; tests have no mapped rivers to judge water by.
static var site_override:Callable=Callable()

static func _found(reading:Dictionary)->Dictionary:
	var Ctl:=preload("res://scripts/civilization_controller.gd")
	var plan:Dictionary=Ctl.current_plan("player")
	var best:=Vector2.INF
	var top:=-INF
	var cache:={}
	var river:=bool(reading.get("river",false))
	var found_river:=false
	var candidates:Array=[] if site_override.is_valid() else Ctl.expansion_candidates(WorldSimulation.world.player_world_origin,float(plan.get("settle_distance",20.0)))
	if site_override.is_valid(): best=site_override.call()
	for p:Vector2 in candidates:
		if not bool(WorldSimulation.settlements.known_land_assessment(p).get("known",false)): continue
		if not bool(WorldSimulation.settlements.settlement_convoy_quote(p,0.0,cache).get("ok",false)): continue
		var ctx:Dictionary=preload("res://scripts/civilization_day.gd").context(p)
		if not bool(WorldSimulation.resources.water_access_snapshot(ctx).get("accessible",false)): continue
		var near_river:=float(ctx.get("surface_water_distance_km",INF))<=2.0
		var v:=float(Ctl.expansion_site_value(ctx,plan))+(2.0 if river and near_river else 0.0)
		if v>top: top=v;best=p;found_river=near_river
	if best==Vector2.INF: return _no("found_town","Our people know no place near enough, with water and a road, where a new town could stand. Send scouts out first.")
	var went:Dictionary=WorldSimulation.settlements.begin_settlement_convoy(best,0.0,"",false,{"establishment_days":float(plan.get("settle_margin_days",45.0))})
	if not bool(went.get("ok",false)): return _no("found_town",_plain(String(went.get("reason","The settlers cannot set out."))))
	var km:=roundi(float(went.get("distance_km",0.0)))
	var founders:=int(went.get("population",0))
	var by:=" by the water" if found_river else (", though no good place by a river is known" if river else "")
	return {"ok":true,"kind":"found_town","count":founders,"says":"%d settlers set out for a place %d km away%s, with food for the road and the first weeks." % [founders,km,by],
		"outcome":"%d settlers set out to found a new town %d km away." % [founders,km]}


const RATION_ID:="court_ration"

static func _set_ration(reading:Dictionary)->Dictionary:
	var mods:Array=WorldSimulation.state.active_modifiers
	var day:=float(WorldSimulation.state.elapsed_days)
	var live:=-1
	for i in mods.size():
		if mods[i] is Dictionary and String((mods[i] as Dictionary).get("id","")).begins_with(RATION_ID) and float((mods[i] as Dictionary).get("until_day",0.0))>day: live=i
	if bool(reading.get("end",false)):
		if live<0: return {"ok":true,"kind":"ration","count":0,"says":"Nobody is on short rations now.","outcome":"There was no ration to end."}
		mods.remove_at(live)
		return {"ok":true,"kind":"ration","count":1,"says":"The ration ends: every family eats its full share again.","outcome":"The ration ends."}
	if live>=0: return {"ok":true,"kind":"ration","count":0,"says":"The families are already on short rations, until about day %d." % int((mods[live] as Dictionary).get("until_day",day)),"outcome":"The ration goes on."}
	mods.append({"id":"%s_%d" % [RATION_ID,int(day)],"kind":"policy","effects":{"food_demand":-0.75,"health_target":-0.1},"magnitude":0.2,"started_day":day,"until_day":day+100.0,"description":"Court order: ration"})
	WorldSimulation.state.simulation_metrics["cohesion"]=clampf(float(WorldSimulation.state.simulation_metrics.get("cohesion",0.58))-0.005,0.0,1.0)
	return {"ok":true,"kind":"ration","count":1,"says":"Every family eats less from today, for about a hundred days: the stores last longer, but people grow weaker and the sick mend slower.","outcome":"The families go on short rations for about a hundred days."}


static func _lay_in(_reading:Dictionary)->Dictionary:
	var sid:=_city_id()
	if bool(WorldSimulation.direction.automatic_work):
		var focus:Dictionary=WorldSimulation.government.set_settlement_focus(sid,"provisions")
		if not bool(focus.get("ok",false)): return _no("provisions",_plain(String(focus.get("reason","The town cannot turn to provisions now."))))
		return {"ok":true,"kind":"provisions","count":1,"says":"The town is turned to provisions until you say otherwise: more hands gather, carry and store food, and the pits fill for the winter.","outcome":"The town is turned to laying in food."}
	var moved:Dictionary=preload("res://scripts/manual_work.gd").move("Food",5)
	if not bool(moved.get("ok",false)): return _no("provisions",_plain(String(moved.get("reason","Nobody could be moved to food."))))
	return {"ok":true,"kind":"provisions","count":int(moved.get("moved",5)),"says":"%d more go to getting food, so the pits fill for the winter." % int(moved.get("moved",5)),"outcome":"%d more hands go to getting food." % int(moved.get("moved",5))}


static func _declare(reading:Dictionary)->Dictionary:
	var civ_id:=String(reading.get("civ_id",""))
	var world:Variant=WorldSimulation.world
	var index:int=world._civilization_index(civ_id)
	if index<0: return _no("declare_war","Nobody knows that people.")
	var civ:Dictionary=world.civilizations[index]
	var name:=String(civ.get("name","them"))
	if bool((civ.get("player_relation",{}) as Dictionary).get("at_war",false)): return {"ok":true,"kind":"declare_war","count":0,"says":"We are already at war with the %s. Say where to strike." % name,"outcome":"The war with the %s goes on." % name}
	var can:Dictionary=world.player_action_availability(civ_id,"declare_war")
	if String(can.get("error","")).begins_with("Choose"):
		world.set_player_war_goal(civ_id,"limited")
		can=world.player_action_availability(civ_id,"declare_war")
	if can.has("error"):
		if bool(can.get("feud",false)): return _no("declare_war","The %s are too few for a war between peoples. It is a feud: say where to strike, and our fighters will go." % name)
		return _no("declare_war",_plain(String(can.error)))
	var sent:Dictionary=world.dispatch_diplomat(civ_id,"","declare_war")
	if sent.has("error"): return _no("declare_war",_plain(String(sent.error)))
	return {"ok":true,"kind":"declare_war","count":1,"says":"Envoys go to the %s to tell them it is war. When they arrive, it is war; nobody marches until you say where to strike." % name,
		"outcome":"Envoys set out to declare war on the %s." % name}


static func _envoy(reading:Dictionary)->Dictionary:
	var world:Variant=WorldSimulation.world
	var index:int=world._civilization_index(String(reading.get("civ_id","")))
	if index<0: return _no("envoy","Nobody knows that people.")
	var civ:Dictionary=world.civilizations[index]
	var CC:=load("res://scripts/court_commands.gd")
	var trade:=String(reading.get("purpose",""))=="trade"
	var gift:=String(reading.get("resource","Food")) if not trade else ""
	var words:="open trade" if trade else "a gift and good words"
	var sent:Dictionary=CC.call("dispatch_envoy",civ,"trade" if trade else "",gift)
	if not bool(sent.get("ok",false)): return _no("envoy",String(sent.get("says","No envoy can go now.")))
	var fixed:=""
	if not trade and int(reading.get("amount",0))>0: fixed=" The gift is what our envoys can carry and what befits us, not a count you name."
	return {"ok":true,"kind":"envoy","count":1,"says":String(sent.get("says",""))+fixed,"outcome":String(sent.get("outcome","Envoys set out with %s." % words))}


static func _mend()->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null: return _no("repair","There is nothing to mend.")
	var mended:PackedStringArray=PackedStringArray()
	var problem:=""
	for item in (mc.damaged_equipment as Dictionary).keys():
		var n:=int(mc.damaged_equipment[item])
		if n<=0: continue
		var queued:Dictionary=mc.queue_equipment_repair(String(item),n)
		if queued.has("error"):
			if problem=="": problem=_plain(String(queued.error))
			continue
		mended.append("%d %s" % [n,String(ITEM_NAMES.get(String(item),String(item).replace("_"," ")))])
	if mended.is_empty():
		if problem!="": return _no("repair",problem)
		return {"ok":true,"kind":"repair","count":0,"says":"Nothing in the stores is broken; what the bands carry is mended in the field.","outcome":"Nothing needed mending at home."}
	return {"ok":true,"kind":"repair","count":mended.size(),"says":"The workshops will mend %s.%s" % [", ".join(mended)," "+problem if problem!="" else ""],"outcome":"%s put in the workshops to be mended." % _cap(", ".join(mended))}


static func _keep_sick_apart()->Dictionary:
	var flags:Dictionary=preload("res://scripts/crisis_system.gd").state().flags
	var had:=bool(flags.get("apart_custom",false))
	flags["apart_custom"]=true
	if had: return {"ok":true,"kind":"sick_apart","count":0,"says":"That is already the custom: the sick are kept at their own fire.","outcome":"The sick are kept apart, as before."}
	return {"ok":true,"kind":"sick_apart","count":1,"says":"From today the sick are kept at their own fire, with food left at the edge of the light. Families will grumble at being parted, but fewer will fall sick.","outcome":"Keeping the sick apart becomes the people's custom."}


const WATER_ID:="court_water"

static func _water(reading:Dictionary)->Dictionary:
	var mods:Array=WorldSimulation.state.active_modifiers
	var day:=float(WorldSimulation.state.elapsed_days)
	for m in mods:
		if m is Dictionary and String((m as Dictionary).get("id","")).begins_with(WATER_ID) and float((m as Dictionary).get("until_day",0.0))>day:
			return {"ok":true,"kind":"clean_water","count":0,"says":"The water already comes only from the clean spring.","outcome":"Clean water is still carried."}
	mods.append({"id":"%s_%d" % [WATER_ID,int(day)],"kind":"policy","effects":{"disease_risk":-1.0,"labor_multiplier":-0.15},"magnitude":0.2,"started_day":day,"until_day":day+90.0,"description":"Court order: clean water"})
	var pots:="pottery" in WorldSimulation.state.known_discoveries or "fired_clay_vessels" in WorldSimulation.state.known_discoveries
	var how:="boiled in pots before anyone drinks it" if bool(reading.get("boil",false)) and pots else "carried from the clean spring upstream, never from the still pools"
	var note:=" We have no pots that stand the fire, so it is carried clean instead." if bool(reading.get("boil",false)) and not pots else ""
	return {"ok":true,"kind":"clean_water","count":1,"says":"For the season, drinking water is %s: fewer fall sick from it, and the carrying takes more hands.%s" % [how,note],"outcome":"Drinking water is carried clean for the season."}


static func _party(reading:Dictionary)->Dictionary:
	var world:Variant=WorldSimulation.world
	var aim:=String(reading.get("aim","prospecting"))
	var target:="open_world"
	var note:=""
	if aim=="people": target="recruit_people"
	elif bool((world.prospecting_status() as Dictionary).get("available",false)): target="rare_resources"
	else: note=" Nobody yet knows what stone or ore to look for, so they go to see the land and bring back what they find."
	var sent:Dictionary=world.dispatch_scouts(90,target,String(reading.get("heading","")))
	if sent.has("error"): return _no("scout_party",_plain(String(sent.error)))
	var what:="to look for wandering bands who might join us" if aim=="people" else "to look for good stone and ore"
	var way:=(" to the "+String(reading.heading)) if String(reading.get("heading",""))!="" else ""
	return {"ok":true,"kind":"scout_party","count":1,"says":"A party goes out%s %s, for about ninety days.%s" % [way,what,note],"outcome":"A scouting party sets out %s." % what}


const TOWN_FOCUS_SAYS:={"shelter":"building shelter","provisions":"laying in food","water":"water: finding it, bringing it nearer, carrying it","defense":"holding the ground","research":"learning","balanced":"a little of everything"}

static func _town_focus(reading:Dictionary)->Dictionary:
	var sid:=_city_id()
	var focus:=String(reading.get("focus","balanced"))
	if focus=="leaders":
		var back:Dictionary=WorldSimulation.government.restore_delegation(sid)
		if not bool(back.get("ok",false)): return _no("town_focus",_plain(String(back.get("reason","The town cannot be handed back now."))))
		return {"ok":true,"kind":"town_focus","count":1,"says":"The leaders run the town again and choose its work as they see fit.","outcome":"The town is handed back to its leaders."}
	var set:Dictionary=WorldSimulation.government.set_settlement_focus(sid,focus)
	if not bool(set.get("ok",false)): return _no("town_focus",_plain(String(set.get("reason","The town cannot be turned to that now."))))
	return {"ok":true,"kind":"town_focus","count":1,"says":"The town is turned to %s until you say otherwise." % String(TOWN_FOCUS_SAYS.get(focus,focus)),"outcome":"The town is turned to %s." % String(TOWN_FOCUS_SAYS.get(focus,focus))}
