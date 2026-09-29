extends RefCounted
## HOME ORDERS WITH REAL MECHANICS (docs/ADJUDICATION.md: every order, the
## same path; never say an order is carried out unless a mechanic did it).
##
## An order about our own people at home that a real system carries out goes
## to that system, never into a vague standing directive:
##   levy     "Recruit 20 more warriors", "Raise thirty new fighters", "Call up
##            fifteen more men to fight", "Recruit, train and arm 5 levies",
##            "Train the recruits": every part of raising a levy is done, never
##            only the first thing the words name. New fighters are called up
##            (MilitaryCampaign.raise_recruits: real adults leave their work,
##            only as many as there are free adults), they begin their drill at
##            once (start_training: as a levy, or as the archers or spearmen
##            named when our people can train them), and the weapons they lack
##            are put in hand in the workshops (queue_equipment_production:
##            only what the store and the work already under way will not
##            cover). Words that only drill ("train the recruits") drill those
##            waiting; with none waiting, those under arms at home go to camp
##            drill.
##   stand_down  "Please dismiss 5 of our soldiers and return them to the
##            workforce", "send the recruits home", "stand the levy down":
##            MilitaryCampaign.demobilize(n), those hurt first, then the
##            recruits waiting, then the fighters at home; their weapons go
##            back to the store. Never the dismissal of the one who is told
##            (a count or a group of our fighters is never one person). With
##            no number and no "all", the court asks how many.
##   arm      "make the weapons we need for the soldiers I requisitioned",
##            "Make twenty spears", "Arm the recruits": the workshops' queue
##            (MilitaryCampaign.queue_equipment_production); the materials are
##            set aside now. With no number, enough for the recruits waiting.
##   found_towns  "Stop founding new towns", "don't found any more towns
##            without my word", "found new towns as you see fit", "our
##            leaders may settle new land again": the leaders' leave to found
##            new towns on their own (auto_founding.gd), the same switch as the
##            Settlement dock's. One town asked for ("found a town by the
##            river") is not their leave.
##   work     "I will set the work myself", "put 10 more on building", "take
##            three off the watch", "let the headman decide the work again":
##            who sets the daily work and people moved between tasks
##            (manual_work.gd), the same switch and split as The People view.
## Words about a foreign town or its people ("conscript the men of Tsaren",
## "take their weapons") are the war leader's business, never these.
##
## read(text) -> {kind:"levy"|"arm"|"found_towns"|"work", count, item?,
##   recruit?, arm_said?, unit?, for_recruits?, allow?, mode?, role?, fewer?,
##   other?} or {}. ("recruit", an older reading, is still carried out.)
## perform(reading) -> {ok, says, outcome, kind, count, ...}: says is the
##   official's own plain answer, outcome the narration; ok=false when nothing
##   could be set in motion (and says what stands in the way).
## Static helpers; preload.

const DEFAULT_RECRUITS:=10
## Home orders a real system carries out: never turned into a law, a war
## order or a standing directive on the way (court_commands.gd).
const ENGINE_KINDS:=["levy","recruit","arm","stand_down","found_towns","work","deploy","training","camp_drill","line","stop_making","carts","research","inquiry","scouting","society","work_pace",
	"build","defences","found_town","ration","provisions","declare_war","envoy","repair","sick_apart","clean_water","scout_party","town_focus"]

## "Muster" and "call out" gather the fighters we have (the war leader's);
## these call up new ones.
const RECRUIT_VERBS:="(?i)\\b(recruit|enlist|draft|conscript|levy|call up|raise)\\b"
## A march or a strike is the war leader's, even with fighters named.
const WAR_WORDS:="(?i)\\b(attack|march|strike|raid|besiege|storm|assault|invade|conquer|burn|fight them|go to war|war on|against)\\b"
const FIGHTER_NOUNS:="(?i)\\b(warriors?|fighters?|soldiers?|spearmen|bowmen|archers|recruits?|levies|troops|men (to|who can|who will|for the) (fight|war|band|spears?)|fighting men|more men|able men|young men|new men|a war ?band|a band|a host|an army)\\b"
const MAKE_VERBS:="(?i)\\b(make|craft|forge|fashion|produce|prepare|shape|knap|carve|build|fit out|arm|equip|outfit)\\b"
const WEAPON_NOUNS:="(?i)\\b(weapons?|arms|spears?|bows?|clubs?|axes?|shields?|swords?|lances?|gear|equipment|kit)\\b"
## Theirs, not ours: occupation measures and captives belong to the war leader.
const THEIRS:="(?i)\\b(their|theirs|captives?|prisoners?|bondservants?|enemy|enemies)\\b"

## Drilling our fighters: "train", "drill", "teach them to fight".
const DRILL_VERBS:="(?i)\\b(train|trains|training|trained|drill|drills|drilling|drilled|teach (?:them |the [\\w']+ )?to fight|make (?:them )?ready to fight)\\b"
## The new fighters a drill is for ("train the recruits"), never a band before
## a march ("let the band finish its drill" is the war leader's).
const NEW_FIGHTERS:="(?i)\\b(recruits?|levies|levy|conscripts?|draftees?|new (?:fighters|warriors|men|soldiers|spearmen|archers|bowmen))\\b"
## "Recruit a scout", "call up the builders": people for other work.
const OTHER_CALLINGS:="(?i)\\b(scouts?|builders?|workers?|hunters?|gatherers?|farmers?|settlers?|healers?|teachers?|carriers?|porters?|stewards?|elders?|priests?|makers?|smiths?|potters?|weavers?|traders?|envoys?|messengers?|runners?|a law|laws?|a plan|plans?|a letter)\\b"
## "Levy a tax", "levy ten hides from each family": goods, not fighters.
const LEVY_GOODS:="(?i)\\b(tax|taxes|tribute|tithe|dues?|shares?|hides?|food|grain|goods|stores?|payment|furs?|meat|timber|stone)\\b"
## Standing our fighters down: dismissed, released, sent home or back to work.
const STAND_DOWN_VERBS:="(?i)\\b(dismiss|dismissed|release|released|discharge|discharged|demobili[sz]e|demobili[sz]ed|stand [\\w' ]{0,30}?down|disband|disbanded|let [\\w' ]{0,30}?go home|send [\\w' ]{0,30}?(?:home|back to (?:the |their )?(?:fields|work|workforce|homes|hearths|families))|return [\\w' ]{0,30}?to (?:the |their )?(?:workforce|fields|work|homes|hearths|families))\\b"
## Our own fighters, as a group or a number ("5 of our soldiers").
const OUR_FIGHTERS:="(?i)\\b(soldiers?|fighters?|warriors?|levies|levy|recruits?|troops|spearmen|archers|bowmen|men under arms|men at arms|fighting men)\\b"

## A kind of fighter the words ask for: [unit, its weapon, the words].
const KIND_WORDS:=[["archer","bow","\\b(archers?|bowmen)\\b"],["spearman","spear","\\bspearmen\\b"]]
const KIND_NAMES:={"levy":"a levy","archer":"archers","spearman":"spearmen"}

const ITEM_WORDS:=[["spear","\\bspears?\\b"],["bow","\\b(bows?|archers?|bowmen)\\b"],["improvised","\\b(clubs?|staves|staffs?|cudgels?|sticks?)\\b"],["sword_shield","\\b(swords?|shields?)\\b"],["lance","\\blances?\\b"]]
const ITEM_NAMES:={"improvised":"clubs and sharpened staves","spear":"spears","bow":"bows","sword_shield":"swords and shields","lance":"lances"}
## What a recruit is armed with, best first, when the words name no weapon.
const FIRST_WEAPONS:=["spear","improvised"]

## New towns, the leaders' leave to found them (see found_reading).
const PLACE_NOUNS:="(?:towns?|cities|city|villages?|settlements?|hamlets?|colony|colonies)"
const ONE_PLACE:=["town","city","village","settlement","hamlet","colony"]
## Founding a place: "found new towns", "the founding of new villages",
## "don't found any more towns"; a plainer verb needs the place to be new:
## "build new towns", "start more villages" (never "make our towns stronger").
const FOUND_PLACES:="(?i)\\b(?:found|founding|founds|colonise|colonising|colonize|colonizing)\\s+(?:(?:any|some|more|new|other|further|fresh|another|a|an|no|the|our|of)\\s+){0,3}"+PLACE_NOUNS+"\\b|\\b(?:build|building|start|starting|raise|raising|make|making|plant|planting|settle|settling)\\s+(?:(?:any|a|an|no|some)\\s+)?(?:(?:more|new|other|further|fresh|another)\\s+){1,2}"+PLACE_NOUNS+"\\b"
## Settling new land: "settle new land", "found new homes".
const FOUND_LAND:="(?i)\\b(?:found|founding|founds|settle|settling|settles|colonise|colonising|colonize|colonizing)\\s+(?:(?:any|some|more|the|our|of)\\s+){0,2}(?:new|fresh|other|further|free|empty|open|unclaimed|good)\\s+(?:land|lands|ground|homes|hearths|places)\\b"
## Settlers sent out (only with words that stop or allow it: "send settlers
## to the river" is one party, not the leaders' leave).
const SEND_SETTLERS:="(?i)\\bsend(?:s|ing)?\\s+(?:(?:out|off|away|any|more|new|our|the)\\s+){0,3}settlers\\b|\\bsettlers\\s+(?:out|away)\\b"
## "No more new towns", "new towns only when I order it": said without a verb.
const NEW_PLACES:="(?i)\\bnew\\s+(?:towns|cities|villages|settlements|colonies)\\b"
## "found" that is the finding of something ("the scout who found new land").
const FINDING:="(?i)\\b(who|that|which|had|have|has|we|they|i|he|she|it|scouts?|hunters?|someone|somebody|nobody|everyone)\\s+found\\b"
## Words that hold the leaders back: nothing is founded without the god's word.
const FOUND_STOP:="(?i)\\b(stop|stops|stopping|halt|cease|quit|no more|no longer|don'?t|do not|dont|never|not|no new|nobody|no one|forbid|forbidden|ban|banned|mustn'?t|must not|shall not|may not|cannot|can'?t|hold off|leave (?:it |that |them |this |the founding |new towns )?to me|i (?:will|shall|alone|myself) (?:decide|choose|say)|i decide|wait (?:for|on) my|until i|unless i|except (?:when|if|on|by) (?:i|my)|only (?:when|if|on|at|by|after|once|with) (?:i|my|me)|without my (?:word|leave|order|orders|say|permission|command|consent))\\b"
## ...unless they say the god's word is no longer needed.
const FOUND_FREE:="(?i)\\b(?:(?:no longer|don'?t|do not|dont|needn'?t|need not|never) (?:need|wait for|wait on|ask for|ask|require|have to (?:ask|wait))|without (?:asking|waiting|needing)|(?:don'?t|do not|never) stop)\\b"
## Leave given in so many words (one town or one party asked for is not it).
const FOUND_LEAVE:="(?i)\\b(?:may|can|free to|as you see fit|as they see fit|whenever|again|on (?:your|their) own|yourselves|themselves|let (?:them|the|our|my)|leave (?:it|that|this) to (?:the|our|you)|allow|permit|resume|keep|continue|go on|carry on|you decide|they decide|leaders decide)\\b"
## A question about it is talk ("why did our leaders found new towns").
const QUESTION_LEADS:="(?i)^\\s*(?:what|why|how|who|whom|where|when|whose|which)\\b"
## A march or a strike beside it is the war leader's.
const FOUND_WAR:="(?i)\\b(attack|march|strike|raid|besiege|storm|assault|invade|conquer|go to war|war on)\\b"

const UNITS:={"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,"eleven":11,"twelve":12,"thirteen":13,"fourteen":14,"fifteen":15,"sixteen":16,"seventeen":17,"eighteen":18,"nineteen":19}
const TENS:={"twenty":20,"thirty":30,"forty":40,"fifty":50,"sixty":60,"seventy":70,"eighty":80,"ninety":90}

static func _re(pattern:String)->RegEx:
	var r:=RegEx.new(); r.compile(pattern)
	return r

static func _has(text:String,pattern:String)->bool:
	return _re(pattern).search(text)!=null

## The first number said: digits, or words ("thirty", "twenty-five", "a
## dozen", "a score", "a hundred"). 0 when none.
static func number_in(text:String)->int:
	var lower:=text.to_lower()
	var d:=_re("\\b(\\d{1,5})\\b").search(lower)
	if d!=null: return int(d.get_string(1))
	var m:=_re("\\b(twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety)(?:[ -](one|two|three|four|five|six|seven|eight|nine))?\\b").search(lower)
	if m!=null: return int(TENS[m.get_string(1)])+(int(UNITS.get(m.get_string(2),0)) if m.get_string(2)!="" else 0)
	var u:=_re("\\b(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen)\\b").search(lower)
	if u!=null: return int(UNITS[u.get_string(1)])
	if _has(lower,"\\b(a )?dozen\\b"): return 12
	if _has(lower,"\\ba score\\b"): return 20
	if _has(lower,"\\b(a )?hundred\\b"): return 100
	return 0

## Words about a foreign town or people named by name.
static func _names_foreign(lower:String)->bool:
	var WarOrders:=preload("res://scripts/court_war_orders.gd")
	var names:Array[String]=[]
	if WorldSimulation.military!=null and WorldSimulation.world!=null:
		for t:Dictionary in WarOrders.held_towns(): names.append(String(t.name))
		for t:Dictionary in WarOrders.known_places(): names.append(String(t.name).trim_prefix("Reported home of "))
	if WorldSimulation.world!=null:
		for c in WorldSimulation.world.civilizations:
			if c is Dictionary and String((c as Dictionary).get("id",""))!="player": names.append(String((c as Dictionary).get("name","")))
	for n in names:
		if n.length()>=3 and WarOrders._name_hit(lower,n): return true
	return false

## The leaders' leave to found new towns (auto_founding.gd): {kind:
## "found_towns", allow} when the words give it or take it back, else {}.
## Not a question, a march, a foreign town named, one town asked for ("found a
## new town by the river") or one party sent ("send settlers to the ford").
static func found_reading(text:String)->Dictionary:
	var clean:=text.strip_edges()
	if clean.is_empty() or clean.ends_with("?") or _has(clean,QUESTION_LEADS): return {}
	# "The scout who found new land" came upon it; nobody founded anything.
	var lower:=_re(FINDING).sub(clean.to_lower(),"$1 came upon",true)
	if _has(lower,FOUND_WAR) or _names_foreign(lower): return {}
	var stop:=_has(lower,FOUND_STOP) and not _has(lower,FOUND_FREE)
	var leave:=_has(lower,FOUND_LEAVE) or _has(lower,FOUND_FREE)
	var place:=_re(FOUND_PLACES).search(lower)
	if place!=null:
		var said:=place.get_string().split(" ",false)
		if not stop and not leave and String(said[said.size()-1]) in ONE_PLACE: return {}
	elif not _has(lower,FOUND_LAND):
		# Settlers sent out, or new towns named without a verb: only with
		# words that stop or allow it.
		if not (_has(lower,SEND_SETTLERS) or _has(lower,NEW_PLACES)) or not (stop or leave): return {}
	return {"kind":"found_towns","allow":not stop}

## Who sets the daily work, and people moved between tasks (manual_work.gd).
## The tasks as the People view names them, each to its work.
const WORK_TASKS:=[
	["Food","(?:getting |gathering |the )?food|gathering|foraging|hunting|the hunt|fishing|the fields|farming|the harvest|gatherers|hunters|fishers|food gatherers"],
	["Survey","searching(?: the land)?|searchers|surveying|the survey|scouting the land"],
	["Extraction","cutting(?: and digging| wood| timber)?|digging|quarrying|the quarr(?:y|ies)|the clay pits|woodcutting|cutters(?: and diggers)?|diggers|fetching wood(?: and stone)?|wood and stone"],
	["Construction","building|builders|construction|the building work"],
	["Crafting","making(?: tools| goods)?|makers|crafts?|crafting|toolmaking|tool ?making|the workshops?"],
	["Logistics","carrying(?: water)?|carriers|hauling|haulers|porters|fetching water|water carrying"],
	["Knowledge","learning|the lore|lore ?keeping|lore keepers|studying|study|teaching|scholars"],
	["Administration","keeping the stores|stewards|stewarding|the council'?s business|keeping count"],
	["Defense","(?:the |keeping )?watch|watchmen|guarding|guard duty|sentries|the guard"],
]
## People moved: "put 10 more on building", "take three off the watch",
## "move 5 from food to building", "ten fewer on the fields".
const PEOPLE_WORDS:="(?:(?:people|hands|men|women|workers|folk|of them|souls)\\s+)?"
## The daily work as a whole, never "work the fields" or "put them to work".
const WORK_NOUNS:="(?:(?:the |our |their )(?:daily )?(?:work|labou?r|tasks|jobs)|daily work|who does what|who works at what|the sharing of (?:the )?work)"
const WORK_VERBS:="(?:set|decide|assign|share out|share|choose|direct|run|give out|hand out|allot|order)"
## The god takes the daily work in hand: "I will set the work myself",
## "leave the work to me", "let me decide who does what".
const WORK_RULER:="(?i)\\b(?:i|i'll|i will|i shall|let me|myself)\\b[^.!]*?\\b"+WORK_VERBS+"\\b[^.!]*?"+WORK_NOUNS+"\\b|\\bleave "+WORK_NOUNS+" to me\\b|"+WORK_NOUNS+" (?:is|are) mine\\b"
## ...or gives it back to our leaders: "let the headman decide the work
## again", "hand the work back to the leaders", "our leaders may set the work
## again", "I want you to decide the work", "Kishan, decide the work again".
const WORK_LEADERS:="(?i)\\b(?:let|leave|hand|give|return)\\b(?! me\\b)[^.!]*?\\b"+WORK_VERBS+"\\b[^.!]*?"+WORK_NOUNS+"\\b|\\b(?:hand|give|return|leave)\\b[^.!]*?"+WORK_NOUNS+"\\b[^.!]*?\\b(?:to|with) (?:the |our |my )?(?:headman|head man|leaders?|chiefs?|elders?|hearth chief|stewards?|council|you|them)\\b|\\b(?:our |the )?leaders? (?:may|can|should|will|must|are to) (?:again )?"+WORK_VERBS+"\\b[^.!]*?"+WORK_NOUNS+"\\b|\\byou (?:may |can |should |will |must |are to |to )?(?:again )?"+WORK_VERBS+"\\b[^.!]*?"+WORK_NOUNS+"\\b|^\\s*(?:[\\w' ]{1,24},\\s*)?(?:decide|set|share out|choose|run)\\b[^.!]*?"+WORK_NOUNS+"\\b"

static func _task_role(words:String)->String:
	var lower:=words.strip_edges().to_lower()
	for pair in WORK_TASKS:
		if _re("(?i)^(?:"+String(pair[1])+")$").search(lower)!=null: return String(pair[0])
	return ""

static func _any_task()->String:
	var parts:PackedStringArray=[]
	for pair in WORK_TASKS: parts.append(String(pair[1]))
	return "(?:"+"|".join(parts)+")"

## Who sets the daily work, or people moved between tasks: {kind: "work",
## mode: "ruler"|"leaders"} or {kind: "work", role, count, fewer, other}; {}
## when the words are neither (a question, a foreign town or a march named,
## a task nobody works at).
static func work_reading(text:String)->Dictionary:
	var clean:=text.strip_edges()
	if clean.is_empty() or clean.ends_with("?") or _has(clean,QUESTION_LEADS): return {}
	var lower:=clean.to_lower().replace("’","'")
	if _has(lower,FOUND_WAR) or _names_foreign(lower) or _has(lower,"(?i)\\b(captives?|prisoners?|bondservants?|slaves?|enemy|enemies)\\b"): return {}
	var task:=_any_task()
	var number:="(\\d{1,5}|a dozen|a score|a hundred|(?:twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety)(?:[ -](?:one|two|three|four|five|six|seven|eight|nine))?|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|some|a few|more|several)"
	# "move 5 from food to building", "take 3 from the watch and put them on building".
	var between:=_re("(?i)\\b(?:move|shift|take|send|put|switch)\\s+"+number+"\\s+(?:more\\s+)?"+PEOPLE_WORDS+"(?:off|from|out of)\\s+(?:the\\s+)?("+task+")\\s+(?:to|onto|on|into|and put them (?:on|to))\\s+(?:the\\s+)?("+task+")\\b").search(lower)
	if between!=null:
		var from_role:=_task_role(between.get_string(2))
		var to_role:=_task_role(between.get_string(3))
		if from_role!="" and to_role!="" and from_role!=to_role: return {"kind":"work","role":to_role,"count":number_in(between.get_string(1)),"fewer":false,"other":from_role}
	# Fewer: "take three off the watch", "ten fewer on the fields", "pull 5 people from building".
	var off:=_re("(?i)\\b(?:take|pull|remove|call|bring)\\s+(?:back\\s+)?"+number+"\\s+(?:more\\s+)?"+PEOPLE_WORDS+"(?:off|from|out of|away from)\\s+(?:the\\s+)?("+task+")\\b").search(lower)
	if off==null: off=_re("(?i)\\b"+number+"\\s+(?:fewer|less)\\s+"+PEOPLE_WORDS+"(?:on|at|to|in|for|doing)\\s+(?:the\\s+)?("+task+")\\b").search(lower)
	if off!=null:
		var role:=_task_role(off.get_string(2))
		if role!="": return {"kind":"work","role":role,"count":number_in(off.get_string(1)),"fewer":true,"other":""}
	var fewer:=_re("(?i)\\b(?:fewer|less)\\s+"+PEOPLE_WORDS+"(?:on|at|to|in|for|doing)\\s+(?:the\\s+)?("+task+")\\b").search(lower)
	if fewer!=null:
		var role:=_task_role(fewer.get_string(1))
		if role!="": return {"kind":"work","role":role,"count":0,"fewer":true,"other":""}
	# More: "put 10 more on building", "add five to the watch", "10 more on the fields".
	var on:=_re("(?i)\\b(?:put|set|add|move|send|assign|give|have|get|place)\\s+(?:another\\s+)?"+number+"\\s+(?:more\\s+)?"+PEOPLE_WORDS+"(?:on|onto|to|at|into|in|for|doing|to work on)\\s+(?:the\\s+)?("+task+")\\b").search(lower)
	if on==null: on=_re("(?i)^\\s*(?:and\\s+)?"+number+"\\s+more\\s+"+PEOPLE_WORDS+"(?:on|to|at|in|for|doing)\\s+(?:the\\s+)?("+task+")\\b").search(lower)
	if on!=null:
		var role:=_task_role(on.get_string(2))
		if role!="": return {"kind":"work","role":role,"count":number_in(on.get_string(1)),"fewer":false,"other":""}
	var more:=_re("(?i)\\b(?:put|set|add|move|send|assign|have|get|place)\\s+more\\s+"+PEOPLE_WORDS+"(?:on|onto|to|at|into|in|for|doing|to work on)\\s+(?:the\\s+)?("+task+")\\b").search(lower)
	# Said without a verb: "More hands on the hunt", "more people for the fields".
	if more==null: more=_re("(?i)^\\s*(?:and\\s+)?(?:we need\\s+)?more\\s+(?:people|hands|men|women|workers|folk|of us)\\s+(?:on|to|at|in|for)\\s+(?:the\\s+)?("+task+")\\b").search(lower)
	if more!=null:
		var role:=_task_role(more.get_string(1))
		if role!="": return {"kind":"work","role":role,"count":0,"fewer":false,"other":""}
	# Who sets it: the god in so many words ("myself", "leave it to me"), else
	# the leaders when they are named or told, else the god who speaks.
	var ruler:=_has(lower,WORK_RULER)
	if ruler and _has(lower,"\\b(myself|let me|to me|is mine|are mine)\\b"): return {"kind":"work","mode":"ruler"}
	if _has(lower,WORK_LEADERS): return {"kind":"work","mode":"leaders"}
	if ruler: return {"kind":"work","mode":"ruler"}
	return {}

static func read(text:String)->Dictionary:
	var clean:=text.strip_edges()
	var lower:=clean.to_lower()
	if clean.is_empty() or clean.ends_with("?"): return {}
	# The god's word on new towns comes first: "at their own judgment" is not
	# someone else's people, and "against my word" is no war.
	var founding:=found_reading(clean)
	if not founding.is_empty(): return founding
	# Who sets the daily work, or people moved between tasks (manual_work.gd):
	# "let our leaders decide their work again" names nobody else's people.
	var work:=work_reading(clean)
	if not work.is_empty(): return work
	# Our fighters stood down: "dismiss 5 of our soldiers" is never a levy,
	# and never the dismissal of whoever is told.
	var down:=stand_down_reading(clean)
	if not down.is_empty(): return down
	# The rest of the realm's own functions (realm_orders.gd): a band formed,
	# the army's training, workshop lines, what our thinkers study, the
	# scouting, how strangers are received, a great work's pace.
	var realm:=realm_reading(clean)
	if not realm.is_empty(): return realm
	if _has(lower,THEIRS) or _has(lower,WAR_WORDS) or _names_foreign(lower): return {}
	# New fighters of our own, called up, drilled and armed: every part said in
	# one breath is done ("recruit, train and arm 5 levies"), and a levy called
	# up is drilled and armed as a matter of course.
	var levy:=levy_reading(clean)
	if not levy.is_empty(): return levy
	# Weapons for our fighters: "make the weapons we need", "arm the recruits".
	var make:=_re(MAKE_VERBS).search(lower)
	var weapon:=_re(WEAPON_NOUNS).search(lower)
	var arming:=_has(lower,"\\b(arm|equip|outfit|fit out)\\b") and _has(lower,FIGHTER_NOUNS+"|\\b(them|the men|our men|new men)\\b")
	if (make!=null and weapon!=null and weapon.get_start()>make.get_start()) or arming:
		var item:=""
		for pair in ITEM_WORDS:
			if _has(lower,String(pair[1])): item=String(pair[0]); break
		return {"kind":"arm","count":number_in(lower),"item":item,"for_recruits":arming or _has(lower,FIGHTER_NOUNS+"|\\b(requisitioned|called up|conscripted|drafted|raised)\\b")}
	return {}


## The realm's own functions (realm_orders.gd), loaded when used: that module
## reads numbers and foreign names through this one.
static func _realm()->GDScript:
	return load("res://scripts/realm_orders.gd") as GDScript


## A realm order (realm_orders.gd read) or {}.
static func realm_reading(text:String)->Dictionary:
	return _realm().call("read",text)


## Words that put others to work, not our own people (realm_orders.gd
## others_at_work): in a town we hold, the garrison's forced labour.
static func others_at_work(text:String)->bool:
	return bool(_realm().call("others_at_work",text))


## Our fighters stood down: {kind: "stand_down", count, all, recruits} when
## the words dismiss, release or send home a number or a group of our own
## fighters; else {}. Not a question, a march, or words about another
## people's men ("release the prisoners" is the war leader's).
static func stand_down_reading(text:String)->Dictionary:
	var clean:=text.strip_edges()
	if clean.is_empty() or clean.ends_with("?") or _has(clean,QUESTION_LEADS): return {}
	var lower:=clean.to_lower()
	if _has(lower,THEIRS) or _has(lower,WAR_WORDS) or _names_foreign(lower): return {}
	if not _has(lower,STAND_DOWN_VERBS) or not _has(lower,OUR_FIGHTERS): return {}
	var recruits:=_has(lower,"\\brecruits?\\b") and not _has(lower,"\\b(soldiers?|fighters?|warriors?|troops|levies|spearmen|archers|bowmen)\\b")
	return {"kind":"stand_down","count":number_in(lower),"all":_has(lower,"\\b(all|every|everyone|each|the whole)\\b"),"recruits":recruits}


## New fighters of our own: {kind: "levy", count, recruit, arm_said, unit,
## item} when the words call up new fighters, or drill the ones called up;
## else {}. Arming alone ("arm the recruits", "make twenty spears") is read()'s
## "arm". Not a question, a march, words about another people's fighters, or
## people called for other work ("recruit a scout", "draft a law", "levy a
## tax").
static func levy_reading(text:String)->Dictionary:
	var clean:=text.strip_edges()
	if clean.is_empty() or clean.ends_with("?") or _has(clean,QUESTION_LEADS): return {}
	var lower:=clean.to_lower()
	if _has(lower,THEIRS) or _has(lower,WAR_WORDS) or _names_foreign(lower): return {}
	var verb:=_re(RECRUIT_VERBS).search(lower)
	# The fighters named, never the verb itself ("recruit a scout" names none).
	var named:=lower if verb==null else lower.substr(0,verb.get_start())+" "+lower.substr(verb.get_end())
	var noun:=_has(named,FIGHTER_NOUNS)
	var n:=number_in(lower)
	var other:=_has(lower,OTHER_CALLINGS) and not noun
	var recruit:=false
	if verb!=null:
		var word:=verb.get_string(1)
		# "Recruit 20": the verb and a number are enough; "draft", "enlist",
		# "conscript" and "levy" need fighters or a number of people named;
		# "raise" and "call up" need fighters named ("raise the wall").
		if word=="recruit": recruit=not other
		elif word in ["enlist","draft","conscript","levy"]: recruit=noun or (n>0 and not other and not _has(lower,LEVY_GOODS))
		else: recruit=noun
		if word=="raise" and (_has(lower,"\\braise [\\w' ]{0,30}?up\\b") or _has(lower,"\\b(spirits?|morale|hopes?|hearts?|pay|wages?|rations?|banners?|standards?|voices?|the alarm)\\b")): recruit=false
	var drill:=_has(lower,DRILL_VERBS) and (_has(lower,NEW_FIGHTERS) or (recruit and _has(lower,"\\b(them|they)\\b")))
	if not recruit and not drill: return {}
	var make:=_re(MAKE_VERBS).search(lower)
	var weapon:=_re(WEAPON_NOUNS).search(lower)
	var arm_said:=_has(lower,"\\b(arm|arms|armed|equip|equipped|outfit|fit out)\\b") or (make!=null and weapon!=null)
	var unit:="levy"
	var item:=""
	for k in KIND_WORDS:
		if _has(lower,String(k[2])): unit=String(k[0]); item=String(k[1]); break
	if item=="":
		for pair in ITEM_WORDS:
			if _has(lower,String(pair[1])): item=String(pair[0]); break
	return {"kind":"levy","count":n,"recruit":recruit,"arm_said":arm_said,"unit":unit,"item":item}

# --------------------------------------------------------------------------
# Carrying them out
# --------------------------------------------------------------------------

static func perform(reading:Dictionary)->Dictionary:
	match String(reading.get("kind","")):
		"levy": return _levy(reading)
		"stand_down": return _stand_down(reading)
		"deploy","training","camp_drill","line","stop_making","carts","research","inquiry","scouting","society","work_pace","build","defences","found_town","ration","provisions","declare_war","envoy","repair","sick_apart","clean_water","scout_party","town_focus":
			return _realm().call("perform",reading)
		"recruit": return _recruit(reading)
		"arm": return _arm(reading)
		"found_towns": return preload("res://scripts/auto_founding.gd").court_order(bool(reading.get("allow",true)))
		"work": return preload("res://scripts/manual_work.gd").court_order(reading)
	return {"ok":false,"kind":"","says":"","outcome":""}

static func _recruit(reading:Dictionary)->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null: return {"ok":false,"kind":"recruit","says":"","outcome":""}
	var asked:=int(reading.get("count",0))
	var named:=asked>0
	var n:=asked if named else DEFAULT_RECRUITS
	var r:Dictionary=mc.raise_recruits(n)
	var raised:=int(r.get("raised",0))
	var waiting:=int(r.get("recruit_reserve",mc.aggregate_recruits))
	var out:={"ok":raised>0,"kind":"recruit","count":raised,"asked":n,"waiting":waiting}
	if raised<=0:
		out.says="There is nobody left to call up: every able adult is already under arms or away."
		out.outcome="Nothing is set in motion: no free adults remain to be called up."
		return out
	var short:=(" Only %d could be found; there are no more free adults." % raised) if raised<n else ""
	var unnamed:=" You named no number, so I called up %d." % raised if not named else ""
	out.says="%d are called up and leave their work in the fields and workshops.%s%s %d now wait for weapons and drill." % [raised,short,unnamed,waiting]
	out.outcome="%d called up from our own people; %d recruits now wait for weapons and drill, and that much less work is done at home." % [raised,waiting]
	return out

## Fighters stood down (MilitaryCampaign.demobilize): those hurt first, then
## the recruits waiting, then the fighters at home; bands away in the field
## are the war leader's to bring home first. Every number is the engine's own.
static func _stand_down(reading:Dictionary)->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null: return {"ok":false,"kind":"stand_down","says":"","outcome":""}
	var waiting:=int(mc.aggregate_recruits)
	var at_home:=int(mc.home_army.get("troops",0))
	var free:=waiting+at_home
	var out:={"ok":false,"kind":"stand_down","count":0}
	var n:=int(reading.get("count",0))
	if n<=0:
		if bool(reading.get("recruits",false)): n=waiting
		elif bool(reading.get("all",false)): n=free
	if n<=0:
		out.says="How many should go home? %d wait as recruits and %d are under arms at home." % [waiting,at_home] if free>0 else "There is nobody under arms at home to send back."
		out.outcome="Nothing is set in motion: no number was named." if free>0 else "Nothing is set in motion: nobody is under arms at home."
		return out
	if free<=0:
		out.says="There is nobody under arms at home to send back; our fighters are away with the bands."
		out.outcome="Nothing is set in motion: nobody is under arms at home."
		return out
	var r:Dictionary=mc.demobilize(mini(n,free))
	if r.has("error"):
		out.says="They cannot be stood down: %s" % String(r.error)
		out.outcome="Nothing is set in motion: %s" % String(r.error)
		return out
	var released:=int(r.get("released",0))
	out.ok=released>0
	out.count=released
	var parts:PackedStringArray=PackedStringArray()
	if int(r.get("released_injured_veterans",0))>0: parts.append("%d who were hurt" % int(r.released_injured_veterans))
	if int(r.get("released_recruits",0))>0: parts.append("%d recruits" % int(r.released_recruits))
	if int(r.get("released_field_soldiers",0))>0: parts.append("%d who stood under arms" % int(r.released_field_soldiers))
	var short:=(" Only %d were at home to send back; the rest are away with the bands." % released) if released<n else ""
	var gear:=""
	var returned:Dictionary=r.get("returned_equipment",{}) if r.get("returned_equipment") is Dictionary else {}
	var back:PackedStringArray=PackedStringArray()
	for item in returned:
		if int(returned[item])>0: back.append("%d %s" % [int(returned[item]),String(ITEM_NAMES.get(String(item),String(item).replace("_"," ")))])
	if not back.is_empty(): gear=" Their %s go back to the store." % ", ".join(back)
	out.says="%d go home to their families and their work: %s.%s%s" % [released,", ".join(parts) if not parts.is_empty() else "%d in all" % released,short,gear]
	out.outcome="%d stood down and back at work at home." % released
	return out


## A levy raised: called up (when the words call up new fighters), drilled
## at once, and armed from the store with the rest put in hand in the
## workshops. Every number said is the engine's own.
static func _levy(reading:Dictionary)->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null: return {"ok":false,"kind":"levy","says":"","outcome":""}
	var asked:=int(reading.get("count",0))
	var named:=asked>0
	var calling:=bool(reading.get("recruit",false))
	var out:={"ok":false,"kind":"levy","asked":asked,"count":0,"raised":0,"drilling":0,"made":0}
	var says:PackedStringArray=[]
	var done:PackedStringArray=[]
	var raised:=0
	if calling:
		var n:=asked if named else DEFAULT_RECRUITS
		var r:Dictionary=mc.raise_recruits(n)
		raised=int(r.get("raised",0))
		out.raised=raised
		if raised>0:
			var short:=(" Only %d could be found; there are no more free adults." % raised) if raised<n else ""
			var unnamed:=(" You named no number, so I called up %d." % raised) if not named else ""
			says.append("%d are called up and leave their work in the fields and workshops.%s%s" % [raised,short,unnamed])
			done.append("%d called up from our own people" % raised)
		elif int(mc.aggregate_recruits)<=0:
			out.says="There is nobody left to call up: every able adult is already under arms or away."
			out.outcome="Nothing is set in motion: no free adults remain to be called up."
			return out
		else:
			says.append("There is nobody left to call up, so I drill those already waiting.")
	var waiting:=int(mc.aggregate_recruits)
	if waiting<=0:
		# Only a drill was asked, and nobody is waiting: those under arms at
		# home go to camp drill, if they are not at it already.
		return _drill_home(mc,out)
	var drill_count:=mini(waiting,asked if named else (raised if raised>0 else waiting))
	var kit:=_kit(mc,String(reading.get("unit","levy")),String(reading.get("item","")))
	if kit.is_empty():
		out.ok=raised>0;out.count=raised
		says.append("They cannot begin a drill yet: our people know no way to train them.")
		out.says=" ".join(says);out.outcome=(", ".join(done)+"; they wait for a drill we cannot yet give." if not done.is_empty() else "Nothing more is set in motion.")
		return out
	var started:Dictionary=mc.start_training(String(kit.unit),String(kit.weapon),drill_count)
	var weapon:=String(kit.weapon)
	var arms:=String(ITEM_NAMES.get(weapon,weapon.replace("_"," ")))
	if started.has("error"):
		says.append("Their drill cannot begin: %s" % String(started.error))
		out.ok=raised>0;out.count=raised
		out.says=" ".join(says);out.outcome=", ".join(done)+"." if not done.is_empty() else "Nothing more is set in motion."
		return out
	var drilling:=int(started.get("accepted",drill_count))
	var days:=ceili(float(started.get("required_days",0.0)))
	out.drilling=drilling
	if String(kit.get("note",""))!="": says.append(String(kit.note))
	var as_what:=String(KIND_NAMES.get(String(kit.unit),"a levy"))
	says.append("%s begin their drill as %s with %s now: about %d days before they are fit to fight." % ["They" if raised>0 else ("The %d waiting" % drilling),as_what,arms,days])
	done.append("%d begin drill as %s with %s, about %d days" % [drilling,as_what,arms,days])
	# Armed: what they need, less the store and the work already under way
	# that nobody else in drill is counting on.
	var need:int=mc._equipment_required_for(String(kit.unit),drilling)
	var stock:=int((mc.military_inventory as Dictionary).get(weapon,0))
	var making:=_in_production(mc,weapon)
	var spoken:=_spoken_for(mc,weapon,int(started.get("id",-1)))
	var cover:=maxi(0,stock+making-spoken)
	var short:=maxi(0,need-cover)
	if short<=0:
		says.append("We have the %s for them%s." % [arms," in store" if stock>=need else " in store and in the making"])
	else:
		var have:=("%d in store" % cover) if cover>0 else "none in store"
		var put:=_put_in_hand(mc,weapon,short,stock)
		if put.has("error"):
			says.append("Of the %d %s they need we have %s, and the workshops cannot make the rest now: %s They drill with what they have until then." % [need,arms,have,String(put.error)])
			done.append("%d short of %s" % [short,arms])
		else:
			out.made=short
			says.append("Of the %d %s they need we have %s; %s" % [need,arms,have,String(put.says)])
			done.append("%d %s put in hand in the workshops" % [short,arms])
	out.ok=true
	out.count=drilling
	out.says=" ".join(says)
	out.outcome=_cap_first("; ".join(done))+"."
	return out


## Nobody waiting to be drilled: those under arms at home go to camp drill.
static func _drill_home(mc:Variant,out:Dictionary)->Dictionary:
	var home:=int(mc.home_army.get("troops",0))
	if home<=0:
		out.says="There is nobody waiting to be drilled and nobody under arms at home. Call up a levy first."
		out.outcome="Nothing is set in motion: nobody is waiting to be drilled."
		return out
	if not (mc.training_program as Dictionary).is_empty():
		out.ok=true;out.count=home
		out.says="The %d under arms at home are already at their drill." % home
		out.outcome="The drill at home goes on."
		return out
	var began:Dictionary=mc.start_training_program("camp_drill")
	if began.has("error"):
		out.says="Nobody is waiting to be drilled, and camp drill cannot begin: %s" % String(began.error)
		out.outcome="Nothing is set in motion: %s" % String(began.error)
		return out
	out.ok=true;out.count=home
	out.says="Nobody new is waiting, so the %d under arms at home go to camp drill: musters, signals and changes of formation, for about %d days." % [home,roundi(float(mc.TRAINING_PROGRAMS.camp_drill.duration_days))]
	out.outcome="The %d under arms at home begin camp drill." % home
	return out


## The kind of fighter and weapon a levy drills with: the kind and weapon the
## words name when our people can train them now, else a levy with spears
## once spears are a practice, else with clubs and staves. {unit, weapon,
## note} ({} when none can be trained); note says, in plain words, why the
## kind asked for could not be.
static func _kit(mc:Variant,unit:String,item:String)->Dictionary:
	var tries:Array=[]
	if unit!="" and unit!="levy":tries.append([unit,item if item!="" else String(mc.UnitCatalog.equipment_for(unit)[0])])
	if item!="":tries.append(["levy",item])
	for fallback in ["spear","improvised"]:
		if not tries.has(["levy",fallback]):tries.append(["levy",fallback])
	var wanted:=String(tries[0][0])!="levy" or String(tries[0][1])==item
	for pair in tries:
		var gate:Dictionary=mc._training_gate(String(pair[0]),String(pair[1]))
		if gate.has("error") or bool(gate.get("prototype",false)):continue
		var note:=""
		if wanted and (String(pair[0])!=String(tries[0][0]) or String(pair[1])!=String(tries[0][1])):
			var asked:=String(KIND_NAMES.get(String(tries[0][0]),"")) if String(tries[0][0])!="levy" else String(ITEM_NAMES.get(String(tries[0][1]),String(tries[0][1])))
			note="We cannot train them with %s yet: our people do not know how well enough." % asked if String(tries[0][0])=="levy" else "We cannot train %s yet: our people do not know how well enough." % asked
		return {"unit":String(pair[0]),"weapon":String(pair[1]),"note":note}
	return {}


## `short` weapons put in hand, the way the workshops' own lines work: a line
## that already makes them keeps that many more in store (and works again if
## it was paused); else a batch of them; else, when every line is taken, a
## paused line is turned over to them. {says} or {error} in plain words.
static func _put_in_hand(mc:Variant,weapon:String,short:int,stock:int)->Dictionary:
	var arms:=String(ITEM_NAMES.get(weapon,weapon.replace("_"," ")))
	for job in mc.equipment_queue:
		var j:Dictionary=job
		if not bool(j.get("persistent",false)) or String(j.get("item",""))!=weapon:continue
		var target:=maxi(int(j.get("target_stock",0)),stock+short) if int(j.get("target_stock",0))>0 else 0
		var set:Dictionary=mc.configure_production_line(int(j.id),target,false)
		if set.has("error"):return {"error":String(set.error)}
		return {"says":"the workshop line that makes %s is set to keep %d in store, and is at work on them now." % [arms,target] if target>0 else "the workshop line that makes %s keeps on making them." % arms}
	# A batch of them already in the workshops takes these too.
	for job in mc.equipment_queue:
		var j:Dictionary=job
		if bool(j.get("persistent",false)) or String(j.get("item",""))!=weapon or String(j.get("job_type","production"))!="production":continue
		var grown:=_grow_batch(mc,j,weapon,short)
		if grown.has("error"):return grown
		return {"says":"the %s already being made in the workshops are %d more now, about %d more days of work, and %s are set aside for them now." % [arms,short,ceili(float(grown.days)),String(grown.materials)]}
	var queued:Dictionary=mc.queue_equipment_production(weapon,short)
	if not queued.has("error"):
		var materials:PackedStringArray=PackedStringArray()
		var recipe:Dictionary=mc._equipment_recipe(weapon)
		for m in (recipe.get("materials",{}) as Dictionary):
			materials.append("%d %s" % [ceili(float(recipe.materials[m])*short),String(m)])
		return {"says":"the workshops will make %d more, about %d days of work, and %s are set aside for it now." % [short,ceili(float(queued.get("work_days",0.0))),", ".join(materials) if not materials.is_empty() else "nothing"]}
	if not String(queued.error).begins_with("All "):
		return {"error":_plain_shortage(String(queued.error))}
	# Every line is taken: a paused line is turned over to them.
	for job in mc.equipment_queue:
		var j:Dictionary=job
		if not bool(j.get("persistent",false)) or not bool(j.get("paused",false)):continue
		var was:=String(ITEM_NAMES.get(String(j.get("item","")),String(j.get("item","")).replace("_"," ")))
		var turned:Dictionary=mc.retool_production_line(int(j.id),weapon)
		if turned.has("error"):continue
		var set:Dictionary=mc.configure_production_line(int(j.id),stock+short,false)
		if set.has("error"):return {"error":String(set.error)}
		return {"says":"every workshop line was taken, so the idle line that made %s now makes %s, to keep %d in store." % [was,arms,stock+short]}
	return {"error":"every workshop line is already at other work."}


## A batch already in hand grows by `count`: its work and its materials,
## taken from the stores now as for a new batch. {days, materials} or {error}.
static func _grow_batch(mc:Variant,job:Dictionary,weapon:String,count:int)->Dictionary:
	var recipe:Dictionary=mc._equipment_recipe(weapon)
	var materials:Dictionary=recipe.get("materials",{}) if recipe.get("materials") is Dictionary else {}
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	for m in materials:
		var need:=float(materials[m])*count
		if float(stocks.get(m,0.0))<need:return {"error":"there is not enough %s in the stores (%d is needed)." % [String(m),ceili(need)]}
	var words:PackedStringArray=PackedStringArray()
	var reserved:Dictionary=job.get("reserved_materials",{}) if job.get("reserved_materials") is Dictionary else {}
	for m in materials:
		var need2:=float(materials[m])*count
		stocks[m]=float(stocks.get(m,0.0))-need2
		reserved[m]=float(reserved.get(m,0.0))+need2
		words.append("%d %s" % [ceili(need2),String(m)])
	job["reserved_materials"]=reserved
	var per:=float(job.get("work_per_item",recipe.get("days",1.0)))
	job["count"]=int(job.get("count",0))+count
	job["required_days"]=float(job.get("required_days",0.0))+per*count
	return {"days":per*count,"materials":", ".join(words) if not words.is_empty() else "nothing"}


## A workshop's refusal in the people's words.
static func _plain_shortage(error:String)->String:
	var m:=RegEx.create_from_string("^Insufficient (.+?): need ([0-9.]+)\\.").search(error)
	if m!=null:return "there is not enough %s in the stores (%d is needed)." % [m.get_string(1),ceili(float(m.get_string(2)))]
	return error.substr(0,1).to_lower()+error.substr(1)


## Weapons of this kind still being made in the workshops.
static func _in_production(mc:Variant,weapon:String)->int:
	var n:=0
	for job in mc.equipment_queue:
		var j:Dictionary=job
		if String(j.get("item",""))!=weapon or String(j.get("job_type","production"))!="production" or bool(j.get("persistent",false)):continue
		n+=maxi(0,int(j.get("count",0))-int(j.get("completed",0)))
	return n


## Weapons of this kind already counted on by others in drill (not on a
## recruitment line, whose weapons are set aside as they come).
static func _spoken_for(mc:Variant,weapon:String,skip_id:int)->int:
	var n:=0
	for order in mc.training_queue:
		var o:Dictionary=order
		if int(o.get("id",-1))==skip_id or o.has("deployment_line") or String(o.get("weapon",""))!=weapon:continue
		n+=maxi(0,int(mc._equipment_required_for(String(o.get("unit","levy")),int(o.get("count",0))))-int(o.get("reserved_equipment",0)))
	return n


static func _cap_first(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text


## What the recruits waiting need, less what is in store.
static func _needed(mc:Variant,item:String)->int:
	return maxi(0,int(mc.aggregate_recruits)-int((mc.military_inventory as Dictionary).get(item,0)))

static func _arm(reading:Dictionary)->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null: return {"ok":false,"kind":"arm","says":"","outcome":""}
	var asked:=int(reading.get("count",0))
	var items:Array=[String(reading.item)] if String(reading.get("item",""))!="" else FIRST_WEAPONS.duplicate()
	var problem:=""
	for item:String in items:
		var n:=asked if asked>0 else _needed(mc,item)
		if n<=0:
			var stock:=int((mc.military_inventory as Dictionary).get(item,0))
			return {"ok":true,"kind":"arm","count":0,"item":item,"says":"We have what they need: %d %s in store for the %d recruits waiting. Nothing more has to be made." % [stock,String(ITEM_NAMES.get(item,item)),int(mc.aggregate_recruits)],
				"outcome":"Nothing more is set to be made: the %s in store are enough." % String(ITEM_NAMES.get(item,item))}
		var queued:Dictionary=mc.queue_equipment_production(item,n)
		if queued.has("error"):
			if problem=="": problem=String(queued.error)
			continue
		var days:=float(queued.get("work_days",0.0))
		var names:=String(ITEM_NAMES.get(item,item))
		var materials:PackedStringArray=PackedStringArray()
		var recipe:Dictionary=mc._equipment_recipe(item)
		for m in (recipe.get("materials",{}) as Dictionary):
			materials.append("%d %s" % [ceili(float(recipe.materials[m])*n),String(m)])
		var for_whom:=" for the %d recruits waiting" % int(mc.aggregate_recruits) if asked<=0 and bool(reading.get("for_recruits",true)) else ""
		var experimental:=" We have not made these before, so it goes slowly." if bool(queued.get("experimental",false)) else ""
		return {"ok":true,"kind":"arm","count":int(queued.get("queued",n)),"item":item,
			"says":"The workshops are set to make %d %s%s: about %d days of work, and %s are set aside for it now.%s" % [int(queued.get("queued",n)),names,for_whom,ceili(days),", ".join(materials) if not materials.is_empty() else "nothing",experimental],
			"outcome":"%d %s put in hand in the workshops, about %d workshop-days; the materials are taken from the stores now." % [int(queued.get("queued",n)),names,ceili(days)]}
	return {"ok":false,"kind":"arm","count":0,"says":"The workshops cannot take it: %s" % problem,"outcome":"Nothing is set in motion: %s" % problem}
