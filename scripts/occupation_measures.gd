extends RefCounted
## WHAT OUR GARRISON DOES WITH THE PEOPLE OF A TOWN WE HOLD.
##
## town_fate.gd decides what becomes of a town (sack, burn, rule, give back).
## This is the everyday business of holding one: the god's word to the
## garrison about the people living under it. "Round up all the men and tie
## them up; if any resist or try to flee, threaten their wives and children"
## is two things at once: a measure (bind the men) and a stance (harsh, with
## the families threatened).
##
## Each measure in CATALOGUE is bounded by what the garrison can physically
## do: its size, the gate watch it always keeps, and the hands already tied
## to guard duty by other measures. Each runs a set number of days and acts
## through the systems that already exist:
##   the town's resistance and its occupation governance (grievance, trust,
##   welfare, repression, local institutions): occupation_governance.gd,
##   synced through civilization_combat.governance;
##   the town's people: town_ledger.gd, the one ledger of who is free,
##   bound, a hostage, at forced labour or serving with us, and who ran
##   (a round-up's flight is a seeded roll on the stated odds, so the war
##   leader can offer a chase; pursuit._reach_refuge moves deserters);
##   food: the town's own stores (civilization_exchange, or the rival's food
##   days) and ours;
##   deaths: civilization_system._apply_rival_civilian_deaths;
##   opinion and border tension, dread, grudges and memory: audience_hall,
##   divine_regard, rival_rulers, ForeignDiplomacy; our war reputation
##   (mercy, fear, grievance);
##   the court's fear or love of the god and the general's own memory:
##   GovernmentPeopleSystem; our cohesion (simulation_metrics).
##
## A stance modifies a measure (STANCES): harsh means fewer escape, more
## dread and more resentment, and a small bounded chance of a later incident
## the war leader reports once. Lenient is the reverse.
##
## Measures live on the garrison's own record (occupation force "measures"),
## are saved with it and end with it; the people they hold are counted only
## in the town's ledger (no measure keeps a count of its own). daily() (called from
## court_war_orders.daily) feeds the bound, keeps resistance down while the
## men are held, runs labour and desertion, ends measures when their days
## are up and files each incident once. The garrison's map card
## (force.fate_note) and the held-town report (held_town.gd) show what is in
## force.
##
## read(text)     the god's words -> {measures, stance, ...} | {}.
## nearest(text)  loose words about a held town -> the closest measure.
## apply(...)     carries measures out -> {ok, text, outcome, ...} | {error}.
## Static helpers; preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const Governance:=preload("res://scripts/occupation_governance.gd")
const Pursuit:=preload("res://scripts/pursuit.gd")
const Combat:=preload("res://scripts/civilization_combat.gd")
const CV:=preload("res://scripts/character_voice.gd")
const Ledger:=preload("res://scripts/town_ledger.gd")
const WAR_LOOP_PATH:="res://scripts/war_loop.gd"

## Measure ids, in the order a war leader carries them out and tells them.
const IDS:=["release","execute_ringleaders","hostages","curfew","bind_men","disarm","search","labour","conscript","requisition","relief","set_headman","settle"]
const STANCE_IDS:=["lenient","firm","harsh","brutal"]
## Measures that take lives: asked about when only guessed at.
const GRAVE:=["execute_ringleaders"]
## Measures that hold people ("free them" lets them go).
const PEOPLE_HELD:=["bind_men","hostages","labour"]
## The standing word to the garrison when nothing more exact is meant.
const WORD:="word"

## How hard the hand is. escape: share of the usual flight; resent and dread
## multiply grievance and fear; incident: chance of a later incident; desert:
## a conscript's daily chance of running off.
const STANCES:={
	"lenient":{"escape":1.5,"resent":0.5,"dread":0.3,"incident":0.03,"desert":0.02},
	"firm":{"escape":1.0,"resent":1.0,"dread":1.0,"incident":0.07,"desert":0.012},
	"harsh":{"escape":0.45,"resent":1.6,"dread":1.7,"incident":0.16,"desert":0.006},
	"brutal":{"escape":0.3,"resent":2.2,"dread":2.4,"incident":0.25,"desert":0.004},
}

## label: the card and report name. days: how long it stands. cap: the
## town's resistance cannot rise above this while it runs. incident: weight
## of the incident chance. order: the plain words for it (offline choices,
## the war leader's questions); short: the same, in a question.
const CATALOGUE:={
	"bind_men":{"label":"Men bound and under guard","days":30,"cap":0.35,"incident":1.0,"order":"Round up the men of %s and bind them","short":"bind the men and keep them under guard"},
	"disarm":{"label":"Disarmed","days":90,"cap":0.6,"incident":0.5,"order":"Take the weapons of %s","short":"take their weapons"},
	"hostages":{"label":"Hostages held","days":90,"cap":0.5,"incident":0.8,"order":"Take hostages from %s","short":"take hostages from their leading families"},
	"curfew":{"label":"Kept to their houses","days":20,"cap":0.5,"incident":0.6,"order":"Keep the people of %s in their houses","short":"keep them to their houses"},
	"search":{"label":"Houses searched","days":10,"cap":1.0,"incident":0.8,"order":"Search every house in %s","short":"search every house"},
	"labour":{"label":"Men at forced labour","days":30,"cap":0.55,"incident":0.8,"order":"Make the men of %s work for us","short":"put the men to work for us"},
	"requisition":{"label":"Their stores taken","days":30,"cap":1.0,"incident":0.6,"order":"Take the food stores of %s","short":"take their food"},
	"conscript":{"label":"Their men serving with ours","days":60,"cap":0.55,"incident":1.0,"order":"Take the young men of %s into our bands","short":"take their young men into our bands"},
	"execute_ringleaders":{"label":"Ringleaders put to death","days":30,"cap":0.45,"incident":0.0,"order":"Put the ringleaders of %s to death","short":"put the few who led them to death"},
	"release":{"label":"Let go","days":0,"cap":1.0,"incident":0.0,"order":"Free the men of %s","short":"free them"},
	"relief":{"label":"Fed and protected","days":30,"cap":1.0,"incident":0.2,"order":"Feed the people of %s and protect them","short":"feed them and keep our men's hands off them"},
	"set_headman":{"label":"Our headman over them","days":365,"cap":1.0,"incident":0.0,"order":"Set one of ours over %s as headman","short":"set one of ours over them as headman"},
	"settle":{"label":"Our settlers there","days":365,"cap":1.0,"incident":0.0,"order":"Send some of our families to settle in %s","short":"send some of our families to live there"},
	"word":{"label":"Your word to the garrison","days":30,"cap":1.0,"incident":0.5,"order":"","short":""},
}

## Measures no longer running stay this many days in the report, then go.
const KEEP_ENDED_DAYS:=12
const MAX_RECORDS:=16
## The gate watch a garrison always keeps (as pursuit.gd).
const KEEP_AT_LEAST:=2
const KEEP_SHARE:=0.25
## Adult men in a farming village (town_fate.MEN_SHARE).
const MEN_SHARE:=0.24
## One guard watches this many bound men, hostages, conscripts or workers.
const BOUND_PER_GUARD:=8
const HOSTAGES_PER_GUARD:=4
const CONSCRIPTS_PER_GUARD:=3
const WORKERS_PER_GUARD:=10
## Share of the men who slip away as a round-up starts, with a firm hand.
const ROUND_UP_FLIGHT:=0.22
## Daily food for a bound man or a hostage (a fighter eats about 0.72).
const BOUND_RATION:=0.4
const HOSTAGE_RATION:=0.6
## Labour: a stake wall rises this much a day per 40 workers, to a bound.
const WALL_PER_DAY:=0.004
const WALL_MAX:=0.15
const FIELD_FOOD_PER_WORKER:=0.25
const FIELD_FOOD_MAX:=300.0

# --------------------------------------------------------------------------
# Reading the god's words
# --------------------------------------------------------------------------

## The people of a town as the object of a verb: "them", "all the men of
## Tsaren", "every man", "their young men". Never a single "the man".
const OBJ:="(?:them|those|these|everyone|everybody|every one of them|(?:all|each|any|some|most|half|the rest) of them|them all|(?:(?:all|every|each|any|some|most|half|the rest)\\s+)?(?:of\\s+)?(?:(?:the|their|its|these|those)\\s+)?(?:(?:able|able-bodied|grown|young|fighting|bound|captured|remaining|other|older|strong|strongest)\\s+)?(?:men|males|menfolk|boys|sons|husbands|fathers|women|womenfolk|girls|wives|daughters|children|villagers|townsfolk|townspeople|inhabitants|residents|people|families|prisoners|captives|elders|youths|survivors|fighters|warriors|folk|rebels|ringleaders|leaders|troublemakers)(?:\\s+of\\s+[a-z'-]+)?|(?:every|each|any)\\s+(?:man|male|soul))"
## Words that name the town's people (not "them").
const PEOPLE_WORDS:="\\b(men|males|menfolk|boys|sons|husbands|fathers|women|womenfolk|girls|wives|daughters|children|villagers|townsfolk|townspeople|inhabitants|residents|people|families|prisoners|captives|elders|youths|survivors|rebels|ringleaders|troublemakers|every man|each man|any man|everyone|everybody)\\b"
const EVERYONE_WORDS:="\\b(everyone|everybody|all of them|them all|the people|villagers|townsfolk|townspeople|inhabitants|residents|families|women|children)\\b"

const BIND_RE:="\\b(?:round(?:ing|ed)?\\s+up\\s+"+OBJ+"|round\\s+"+OBJ+"\\s+up|(?:tie|ties|tying|bind|binding|chain|shackle|fetter|manacle|rope)\\s+(?:up\\s+)?"+OBJ+"|"+OBJ+"\\s+(?:(?:are|is|to|be|must|should|will|shall|get|kept)\\s+){0,3}(?:tied|bound|chained|shackled|fettered|roped|rounded up|locked up)|(?:lock|pen|shut)\\s+(?:up\\s+)?"+OBJ+"(?:\\s+(?:up|away|in\\s+(?:a|the)\\s+(?:pen|pit|stockade|hut|yard|square)))?|(?:put|hold|keep|place)\\s+"+OBJ+"\\s+(?:all\\s+)?(?:under\\s+(?:guard|watch)|in\\s+(?:chains|bonds|fetters|irons|cords|ropes|the stocks))|(?:take|make)\\s+"+OBJ+"\\s+prisoners?|take\\s+prisoners|(?:arrest|detain|imprison|herd|corral)\\s+"+OBJ+")"
const CURFEW_RE:="\\b(?:curfew|confine\\s+"+OBJ+"(?:\\s+to\\s+(?:their|the)\\s+(?:houses?|homes?|huts?|dwellings?))?|(?:keep|lock|shut|hold|confine)\\s+"+OBJ+"\\s+(?:in|inside|within|indoors)(?:\\s+(?:their|the)\\s+(?:houses?|homes?|huts?|dwellings?))?|(?:nobody|no one|no-one|none|no man)\\s+(?:is to\\s+|may\\s+|shall\\s+|will\\s+|must\\s+|can\\s+)?(?:leave|leaves|go out|goes out|walk|walks|step out|steps out|stir|stirs|be out|is out)(?:\\s+(?:of\\s+)?(?:their|the|his)\\s+(?:houses?|homes?|huts?|doors?))?(?:\\s+(?:after|at|by)\\s+(?:dark|night))?|(?:stay|remain)\\s+(?:in|inside|indoors))"
const WEAPONS:="(?:weapons?|spears?|bows?|arrows|axes|axe|knives|knife|clubs?|slings?|blades?|swords?|daggers?|javelins?|shields?|maces?|arms)"
const DISARM_RE:="\\b(?:disarm(?:ed|ing)?|(?:take|seize|collect|gather|confiscate|strip|carry off|remove|pile up|hand over|give up)\\s+(?:away\\s+)?(?:all\\s+)?(?:of\\s+)?(?:(?:their|the|its|every|any|all)\\s+)?(?:(?!up\\b)[a-z'-]+\\s+)?"+WEAPONS+"|(?:burn|break|destroy|smash|snap|wreck)\\s+(?:all\\s+)?(?:of\\s+)?(?:(?:their|the|its|every|any)\\s+)?(?:[a-z'-]+\\s+)?(?:weapons?|spears?|bows?|axes|clubs?|slings?|blades?|swords?|daggers?|javelins?|shields?)|strip\\s+"+OBJ+"\\s+of\\s+(?:their\\s+)?"+WEAPONS+"|(?:no|not a|not one)\\s+(?:man|one|soul)\\s+(?:is to\\s+|may\\s+|shall\\s+)?(?:keep|carry|bear|hold|have)s?\\s+(?:a|any)\\s+"+WEAPONS+")"
const DESTROY_RE:="\\b(burn|burned|burnt|break|broken|destroy|destroyed|smash|smashed|snap|wreck)\\b"
const HOSTAGE_RE:="\\b(?:hostages?|as\\s+(?:surety|sureties|pledges?|security)|(?:take|keep|hold|seize|carry off|bring)\\s+(?:some\\s+of\\s+|a few of\\s+|two of\\s+)?(?:their|the)\\s+(?:elders|headm[ae]n'?s?\\s+(?:family|kin|sons|children|wives?)|chiefs?'?s?\\s+(?:family|kin|sons|children|wives?)|leading men'?s?\\s+(?:families|sons|children)|best families|leading families|first families)|(?:take|seize|hold|keep|arrest)\\s+(?:their|the town'?s|its)\\s+(?:chief|chiefs|headm[ae]n|leaders?|elders)(?:\\s+(?:prisoner|prisoners|hostage|hostages|captive|captives))?)"
const SEARCH_RE:="\\b(?:search(?:es|ed|ing)?\\s+(?!for\\b|after\\b)(?:(?:every|each|all|the|their|its)\\s+)?[a-z'-]+|house to house|door to door|comb\\s+(?:through\\s+)?(?:the|every|their)\\s+(?:town|village|houses?)|turn\\s+(?:the town|the village|every house|their houses|it|the place)\\s+(?:over|upside down|inside out)|go\\s+through\\s+(?:every|each|their|all the)\\s+(?:house|houses|home|homes|huts?)|root out\\s+(?:any|the|their|all)|(?:hunt|look)\\s+for\\s+(?:hidden|their hidden)\\s+(?:weapons|food|men|stores|spears))"
const WORKVERB:="(?:work|labou?r|toil|dig|build|carry|haul|clear|till|repair|raise|cut|fell|drag|quarry|serve us|fetch)"
const LABOUR_RE:="\\b(?:(?:make|force|have|set|put)\\s+"+OBJ+"\\s+(?:to\\s+)?"+WORKVERB+"|put\\s+"+OBJ+"\\s+to\\s+(?:work|labou?r|the (?:fields|walls|ditch|stone))|forced\\s+labou?r|(?:labou?r|work|chain)\\s+gangs?|work\\s+"+OBJ+"\\s+(?:hard|in gangs|like)|(?:build|raise|dig|repair|mend|put up|throw up)\\s+(?:us\\s+)?(?:(?:a|an|our|the|new|some)\\s+)*(?:(?:stone|stake|earth|wooden|timber|high|strong)\\s+)?(?:walls?|palisades?|stockades?|ditch(?:es)?|ramparts?|fences?|defences|defenses|roads?|tracks?|paths?|earthworks?)|work\\s+(?:our|the|their)\\s+fields|(?:till|plough|plow|harvest|sow|reap|tend)\\s+(?:our|the|their)\\s+fields\\s+for\\s+us)"
const WALL_WORDS:="\\b(walls?|palisades?|stockades?|ditch(es)?|ramparts?|fences?|defences|defenses|earthworks?)\\b"
const ROAD_WORDS:="\\b(roads?|tracks?|paths?)\\b"
const FIELD_WORDS:="\\b(fields?|plough|plow|harvest|sow|reap|till|crops?)\\b"
const FOODS:="(?:food|grain|stores|stock|stocks|harvest|cattle|herds?|flocks?|livestock|provisions|meat|fish|goats|sheep|pigs|granar(?:y|ies)|storehouses?|barns?|pits|seed)"
const REQUISITION_RE:="\\b(?:requisition\\w*|commandeer\\w*|(?:take|seize|collect|gather|carry off|empty|confiscate|claim|strip|drive off)\\s+(?:(?:all|half|most|some|a share|a third|much)\\s+)?(?:of\\s+)?(?:their|the|its|the town'?s|what)\\s+(?:[a-z'-]+\\s+)?"+FOODS+"|take what (?:food|grain|they have)|(?:feed|provision)\\s+(?:the garrison|our men|ourselves|our fighters)\\s+(?:from|off|on|out of)\\s+(?:their|them|the town))"
const HEAVY_RE:="\\b(all|everything|every last|to the last|bare|empty)\\b"
const CONSCRIPT_RE:="\\b(?:conscript\\w*|draft\\s+"+OBJ+"|press\\s+"+OBJ+"\\s+into|levy\\s+"+OBJ+"|(?:make|force|have)\\s+"+OBJ+"\\s+(?:fight|serve|march|carry spears|bear arms|stand)\\s+(?:for|with|beside|among)\\s+us|(?:take|put|bring|draft|enrol|enroll)\\s+"+OBJ+"\\s+into\\s+(?:our|the)\\s+(?:bands?|ranks|army|host|levy|garrison|war ?bands?)|enlist\\s+"+OBJ+"|recruit\\s+"+OBJ+"|(?:join|serve in|serve with|fight in|fight for)\\s+(?:our|the)\\s+(?:bands?|army|host|garrison|ranks))"
const LEADERS:="(?:ringleaders?|ring-leaders?|leaders?|troublemakers?|trouble-makers?|agitators?|instigators?|rebels?|chiefs?|their headm[ae]n|their elders|the worst of them|a few of them|one or two of them|one in (?:every )?ten|every tenth(?: man)?|(?:those|the ones|the men|any) (?:who|that) (?:led|fought|resisted|stirred|started|lead|stir))"
const KILLV:="(?:kill|execute|hang|behead|put to death|slay|cut down|impale|stone|spear|strangle|drown|burn)"
const EXECUTE_RE:="\\b(?:"+KILLV+"\\s+(?:[a-z'-]+\\s+){0,3}?"+LEADERS+"|put\\s+(?:[a-z'-]+\\s+){0,2}?"+LEADERS+"(?:\\s+(?:of|in|from)\\s+[a-z'-]+)?\\s+to\\s+death|make an example of|decimate|"+LEADERS+"(?:\\s+(?:of|in|from)\\s+[a-z'-]+)?\\s+(?:(?:are|is|must|shall|will|to|be)\\s+){0,3}(?:killed|executed|hanged|hung|beheaded|put to death|slain|cut down))"
const RELEASE_RE:="\\b(?:(?:free|release|untie|unbind|unchain|unshackle|loose|loosen|unfetter)\\s+"+OBJ+"|(?:let|set)\\s+"+OBJ+"\\s+(?:go|loose|free|out)|"+OBJ+"\\s+(?:(?:are|is|to|be|can|may)\\s+){0,3}(?:freed|released|untied|let go|set free)|(?:lift|end|stop|call off)\\s+the\\s+(?:curfew|labou?r|work|gangs?|work gangs?)|(?:send|let)\\s+"+OBJ+"\\s+(?:back\\s+)?to\\s+their\\s+(?:houses|homes|fields|families)|(?:give|send)\\s+(?:back\\s+)?the\\s+hostages|free\\s+the\\s+hostages)"
const RELIEF_RE:="\\b(?:feed\\s+"+OBJ+"|feed\\s+(?:the\\s+)?(?:town|village|hungry)|share\\s+(?:our\\s+)?(?:food|grain|stores|meat)\\s+(?:[a-z'-]+\\s+){0,2}?with|give\\s+"+OBJ+"\\s+(?:some\\s+|our\\s+)?(?:food|grain|meat|a share|gifts?|seed)|protect\\s+(?:"+OBJ+"|the town|the village|their (?:houses|homes|goods|women))|keep\\s+"+OBJ+"\\s+safe|(?:no one|nobody|none of ours|our men|the garrison|our fighters|the soldiers|my men|your men)\\s+(?:is to\\s+|may\\s+|must\\s+|shall\\s+|will\\s+)?(?:not\\s+)?(?:harm|touch|rob|hurt|abuse|lay (?:a )?hands? on|take from|steal from|mistreat)|reward\\s+(?:[a-z'-]+\\s+){0,3}?(?:who|that)\\s+(?:help|helps|helped|cooperate|cooperates|serve|serves|obey|obeys|work with|side with|come over)|reward\\s+"+OBJ+"|win\\s+"+OBJ+"\\s+over|make friends (?:of|with)\\s+"+OBJ+"|treat\\s+"+OBJ+"\\s+(?:well|kindly|gently|fairly|as our own|with respect)|be\\s+(?:kind|gentle|fair|merciful|good)\\s+(?:to|with)\\s+"+OBJ+")"
const SETTLE_RE:="\\b(?:(?:settle|move|send|plant|bring|put)\\s+(?:(?:some|a few|\\d+|twenty|ten|thirty)\\s+(?:of\\s+)?)?(?:our|of our)\\s+(?:own\\s+)?(?:people|families|settlers|folk|hunters|households|kin|young families)(?:\\s+[a-z'-]+){0,3}?\\s+(?:in|into|to|there|at|among)|(?:our\\s+)?settlers?\\s+(?:to|in|into|there)|colonists?|coloni[sz]e|(?:let|have)\\s+our\\s+(?:people|families|folk)\\s+(?:live|settle|move|dwell)|move\\s+(?:some of\\s+)?our\\s+(?:people|families)\\s+in)"
## "Set Imeri over them", "make Imeri headman of Tsaren": read on the words
## as typed, so a name is known by its capital letter.
const HEADMAN_RE:="\\b(?i:set|put|place|make|appoint|name|install|leave|let)\\s+(?<who>[A-Z][\\w'-]+|(?i:one of (?:ours|our own|our men|our people|my men|your men)|our own (?:man|headman|chief|steward)|our (?:man|headman|chief|steward)|a (?:man|captain|headman) of (?:ours|our own)))\\s+(?i:as\\s+(?:the\\s+)?(?:headman|chief|master|steward|elder|head|leader|governor|ruler|lord)\\b|over\\b|in charge\\b|to (?:rule|govern|lead|run) (?:them|it|the town|over)\\b|(?:rule|govern|lead|run)\\s+(?:them|it|the town)\\b|(?:the\\s+)?(?:headman|chief|master|steward|governor|ruler|lord)\\s+(?:of|over|in|for)\\b)|\\b(?<who2>[A-Z][\\w'-]+)\\s+(?i:(?:will|shall|is to|must|should)\\s+(?:rule|govern|lead|run|sit over|be headman))|\\b(?i:(?:a new|our own|a) headman (?:of our own|from among us|over them|for them))"
const NOT_A_NAME:=["The","Our","My","Their","Them","It","Home","Your","War","Battle","Me","You","One","A","An","All","Every","Each","Any","Some","If","And","Then","He","She","They","We","I","Let","Set","Make","Put","Now","Round","Tie","Take","Keep"]

## A condition and what follows it: "if any resist or attempt to flee,
## threaten their wives and children"; "kill any who run".
const COND_SUBJ:="(?:any|anyone|anybody|any of them|any man|any men|any of the men|some|some of them|one|one of them|a man|they|the men|the villagers|those|he|she)"
const COND_VERB:="(?:resists?|resisted|resisting|fights?|fight back|fights back|fought|flees?|fled|runs?|run away|runs away|ran|escapes?|escaped|bolts?|struggles?|refuses?|disobeys?|rises?|rebels?|make trouble|makes trouble|cause trouble|causes trouble|talks? back|tries to (?:run|flee|escape|fight|get away|break free)|try to (?:run|flee|escape|fight|get away|break free)|attempts? to (?:flee|escape|run|fight|get away|break free)|gets? away|breaks? free)"
const COND_IF_RE:="\\b(?:if|should|in case|whenever)\\s+"+COND_SUBJ+"\\b[^.;!?]*?\\b"+COND_VERB+"\\b[^,.;!?]*"
## "Any who run", "whoever defies us": a condition when the verb is present
## tense ("those who resisted" are particular men, not a condition).
const COND_WHO_RE:="\\b(?:(?:anyone|anybody|any man|any|those|the ones|any of them)\\s+(?:who|that)|whoever)\\s+(?:so much as\\s+|even\\s+|dares? to\\s+)?(?!(?:[a-z']+ed|fled|fought|ran|led|lead|leads|stir|stirs|incite|incites|took|stole|was|were|did|had)\\b)(?<verb>(?:tries|try|attempts?) to [a-z']+|[a-z']+)\\b"
const BRUTAL_RE:="\\b(kill|slay|cut\\s+(?:[a-z]+\\s+)?down|put\\s+(?:[a-z]+\\s+){0,2}to death|hang|execute|spear|run\\s+(?:[a-z]+\\s+)?through|burn\\s+(?:[a-z]+\\s+){0,2}(?:house|houses|home|homes)|no mercy|show no mercy|behead|strike\\s+(?:[a-z]+\\s+)?down)\\b"
const HARSH_RE:="\\b(threaten|menace|beat|flog|whip|thrash|lash|punish|hurt|take\\s+(?:[a-z]+\\s+){0,2}(?:wives|women|children|families|sons|daughters|kin)|seize\\s+(?:[a-z]+\\s+){0,2}(?:wives|women|children|families|kin)|burn\\s+(?:[a-z]+\\s+){0,2}roofs?|make\\s+(?:[a-z]+\\s+)?(?:pay|suffer)|break\\s+(?:[a-z]+\\s+){0,2}(?:legs|hands|fingers))\\b"
const LENIENT_COND_RE:="\\b(let\\s+(?:[a-z]+\\s+)?go|leave\\s+(?:[a-z]+\\s+)?be|do not hurt|don't hurt|no harm|spare|forgive)\\b"
const FAMILY_RE:="\\b(wives|wife|women|children|child|families|family|kin|mothers|sons|daughters)\\b"
## A stance said outright, anywhere in the order.
const STANCE_BRUTAL_RE:="\\b(no mercy|without mercy|show no mercy|mercilessly|brutally|savagely|spare none|spare no one)\\b"
const STANCE_HARSH_RE:="\\b(harshly|roughly|a hard hand|a firm hand|an iron hand|a heavy hand|with fear|show them who rules|make them (?:fear|afraid|understand|obey|respect)|teach them (?:a lesson|to fear|to obey)|break their (?:spirit|pride)|threaten (?:their|the) (?:wives|women|children|families|kin))\\b"
const STANCE_LENIENT_RE:="\\b(gently|kindly|softly|with care|carefully|without (?:harm|hurting|violence|bloodshed|blood)|no (?:violence|bloodshed)|(?:do not|don't|never) (?:hurt|harm|beat|strike|kill|touch)|harm no one|hurt no one|(?:nobody|no one) (?:is to be |is |gets |must be |should be |will be )?(?:hurt|harmed)|(?:treat|handle) (?:[a-z]+ ){0,2}(?:well|kindly|gently|fairly|with respect)|be (?:kind|gentle|fair|merciful))\\b"
## Words that make it an order at all.
const ORDER_LEADS:=["i want","i order","i command","i demand","i decree","you will","you shall","you must","see that","see to it","make sure","let ","have ","tell the garrison","tell them","tell your men","i need you"]
const IMPERATIVES:=["round","tie","bind","chain","shackle","take","make","keep","put","set","give","feed","search","burn","free","release","untie","let","send","have","lock","hold","gather","seize","arrest","detain","disarm","conscript","draft","requisition","protect","reward","treat","be","move","settle","force","show","teach","break","crush","punish","deal","handle","watch","guard","kill","hang","execute","confine","empty","strip","appoint","install","place","work","build","dig","clear","get","do","go","see","tell","bring","leave","stop","end","lift","collect","confiscate","pen","herd","hunt","root","comb","turn","starve","frighten","scare","terrify","calm","quiet","silence","control","govern","rule","manage","squeeze","press","enlist","recruit","plant","colonise","colonize","spare","loosen","fetter","rope","imprison","patrol","occupy","threaten","impose","enforce","post","station","double","tighten","ease","relax","forgive","pardon","warn","remind","question","interrogate","count","make",
	"destroy","wipe","annihilate","exterminate","raze","level","finish","sack","loot","plunder","smash","slaughter","slay","massacre","butcher","murder","whip","flog","beat","hurt","harm","drive","expel","banish","scatter","deal","sort","handle","squash","stamp","quell","subdue","tame","bring"]
const NUMBER_WORDS:={"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,"a dozen":12,"twelve":12,"fifteen":15,"twenty":20,"thirty":30,"forty":40,"fifty":50}

static var _regex:Dictionary={}

static func _re(pattern:String,case_sensitive:bool=false)->RegEx:
	var key:=("cs:" if case_sensitive else "ci:")+pattern
	if not _regex.has(key):
		var re:=RegEx.new()
		re.compile(pattern if case_sensitive else "(?i)"+pattern)
		_regex[key]=re
	return _regex[key]

static func _has(text:String,pattern:String)->bool:
	return _re(pattern).search(text)!=null

static func _find(text:String,pattern:String)->RegExMatch:
	return _re(pattern).search(text)


## The order with its conditional clauses cut out, and what they said:
## {main, stance, families, clause, spans:[[from,to]] in the lowered text}.
## "Round up the men. If any run, kill them" -> main "round up the men.",
## stance "brutal".
static func conditions(lower:String)->Dictionary:
	var out:={"main":lower,"stance":"","families":false,"clause":"","cuts":[]}
	var main:=lower
	var cuts:Array=[]
	for guard in 4:
		var start:=-1; var stop:=-1; var consequence:=""
		var m:=_find(main,COND_IF_RE)
		if m!=null:
			start=m.get_start()
			var rest:=main.substr(m.get_end())
			var end_at:=rest.length()
			var sentence_end:=_re("[.;!?]").search(rest)
			if sentence_end!=null: end_at=sentence_end.get_start()
			consequence=rest.substr(0,end_at).strip_edges().trim_prefix(",").strip_edges().trim_prefix("then ").strip_edges()
			stop=m.get_end()+end_at
			if consequence=="":
				# "Threaten their families if any run": the consequence came first.
				var before:=main.substr(0,start)
				var from:=_clause_start(before)
				consequence=before.substr(from).strip_edges()
				start=from
		else:
			var w:RegExMatch=null
			for hit in _re(COND_WHO_RE).search_all(main):
				# "Kill any who run": the verb before the relative clause; after
				# it for "whoever resists, kill him".
				var before:=main.substr(0,hit.get_start())
				var from:=_clause_start(before)
				var said:=before.substr(from).strip_edges()
				var after_end:=hit.get_end()
				if said=="":
					var rest:=main.substr(hit.get_end())
					var end_at:=rest.length()
					var sentence_end:=_re("[.;!?]").search(rest)
					if sentence_end!=null: end_at=sentence_end.get_start()
					var comma:=rest.find(",")
					if comma>=0 and comma<end_at:
						said=rest.substr(comma+1,end_at-comma-1).strip_edges()
						after_end=hit.get_end()+end_at
				# Only a threat makes it a condition: "reward those who help us"
				# is a measure, "kill anyone who defies us" a standing word.
				var threat:=_has(said,BRUTAL_RE) or _has(said,HARSH_RE) or _has(said,LENIENT_COND_RE)
				if _has(hit.get_string("verb"),"^"+COND_VERB+"$") or threat:
					w=hit; consequence=said; start=from if before.substr(from).strip_edges()!="" else hit.get_start(); stop=after_end
					break
			if w==null: break
		var stance:="firm"
		if _has(consequence,BRUTAL_RE): stance="brutal"
		elif _has(consequence,HARSH_RE): stance="harsh"
		elif _has(consequence,LENIENT_COND_RE): stance="lenient"
		out.stance=_harder(String(out.stance),stance)
		if stance in ["harsh","brutal"] and _has(consequence,FAMILY_RE): out.families=true
		var cut:=main.substr(start,stop-start)
		out.clause=(String(out.clause)+" "+cut).strip_edges()
		cuts.append(cut.strip_edges())
		main=(main.substr(0,start)+main.substr(stop)).strip_edges()
	out.main=main
	out.cuts=cuts
	return out

## Where the clause that ends the text begins (after ". ", "; ", ", " or " and ").
static func _clause_start(before:String)->int:
	var best:=0
	for sep in [". ","; ",", "," and "," then "]:
		var at:=before.rfind(sep)
		if at>=0: best=maxi(best,at+sep.length())
	return best

static func _harder(a:String,b:String)->String:
	if a=="": return b
	if b=="": return a
	return a if STANCE_IDS.find(a)>=STANCE_IDS.find(b) else b

static func _count_in(lower:String)->int:
	var m:=_find(lower,"\\b(\\d{1,4})\\b")
	if m!=null: return int(m.get_string(1))
	for word:String in NUMBER_WORDS:
		if _has(lower,"\\b%s\\b" % word): return int(NUMBER_WORDS[word])
	return 0

## The god's words to a garrison: {} when they name no measure and no stance.
## {measures:[ids], stance, stance_set, families, clause, who ("men" |
##  "people"), work ("walls"|"roads"|"fields"|""), count, headman (a name,
##  or "" for one of ours), release:[ids], destroy, heavy, people (the words
##  name the town's people), pronoun (only "them"), consumes:[fate flags]}.
static func read(text:String)->Dictionary:
	var clean:=text.strip_edges()
	if clean.is_empty() or clean.ends_with("?"): return {}
	var lower:=clean.to_lower()
	for lead in ["what ","why ","how ","who ","whom ","where ","when ","should we ","could we ","can we ","would ","shall we ","do we ","is it ","are we "]:
		if lower.begins_with(lead): return {}
	var cond:=conditions(lower)
	var main:=String(cond.main)
	var found:Array[String]=[]
	var out:={"measures":found,"stance":"firm","stance_set":false,"families":bool(cond.families),"clause":String(cond.clause),"who":"men","work":"","count":_count_in(main),
		"headman":"","release":[],"destroy":false,"heavy":false,"people":false,"pronoun":false,"consumes":[]}
	var curfew:=_find(main,CURFEW_RE)
	var captives_freed:=_has(main,"\\b(free|release|emancipate|unbind)\\s+(the\\s+)?(captives|slaves|bonded)")
	var release:=_find(main,RELEASE_RE)
	if release!=null and not captives_freed: found.append("release")
	if _has(main,EXECUTE_RE): found.append("execute_ringleaders")
	if _has(main,HOSTAGE_RE): found.append("hostages")
	if curfew!=null: found.append("curfew")
	var bind:=_find(main,BIND_RE)
	if bind!=null:
		var said:=bind.get_string()
		# "Lock them in their houses" keeps them home; it does not bind them.
		var kept_home:=curfew!=null and _has(said,"\\b(lock|shut|keep|hold|confine)\\b") and curfew.get_start()<=bind.get_start()+2
		if not kept_home and not (release!=null and release.get_start()==bind.get_start()):
			found.append("bind_men")
			out.who=_who_of(_clause_from(main,bind.get_start()))
	var disarm:=_find(main,DISARM_RE)
	if disarm!=null:
		found.append("disarm")
		# "Take their weapons and burn them": destroyed, not kept.
		out.destroy=_has(disarm.get_string(),DESTROY_RE) or _has(main.substr(disarm.get_end()),"^\\W*(?:and\\s+)?(?:then\\s+)?(burn|break|destroy|smash)\\s+(them|the lot|all of them|every one)\\b")
	if _has(main,SEARCH_RE): found.append("search")
	var labour:=_find(main,LABOUR_RE)
	if labour!=null:
		found.append("labour")
		if _has(main,WALL_WORDS): out.work="walls"
		elif _has(main,ROAD_WORDS): out.work="roads"
		elif _has(main,FIELD_WORDS): out.work="fields"
		# Who is put to work: "make the women work the fields" is the women.
		out["work_who"]=_who_of(_clause_from(main,labour.get_start()))
	var requisition:=_find(main,REQUISITION_RE)
	if requisition!=null:
		found.append("requisition")
		out.heavy=_has(requisition.get_string(),HEAVY_RE) or _has(main,"\\b(everything|every last|to the last|leave them nothing|strip them bare|all of it|all they have)\\b")
	if _has(main,CONSCRIPT_RE): found.append("conscript")
	if _has(main,RELIEF_RE): found.append("relief")
	var headman:=_re(HEADMAN_RE,true).search(_uncut(clean,cond.get("cuts",[])))
	if headman!=null:
		var who:=headman.get_string("who")
		if who=="": who=headman.get_string("who2")
		# "Let Tsaren govern themselves" names a town, not a headman.
		if not _is_place(who):
			if who!="" and who.substr(0,1)!=who.substr(0,1).to_lower() and not who in NOT_A_NAME: out.headman=who
			found.append("set_headman")
	if _has(main,SETTLE_RE): found.append("settle")
	# What "free them" lets go; "free the hostages" and "lift the curfew" end
	# those measures rather than start them.
	if found.has("release"):
		var what:Array=[]
		var free_words:=release.get_string()
		var span:=Vector2i(release.get_start(),release.get_end())
		for pair in [["hostages","\\bhostages\\b",HOSTAGE_RE],["curfew","\\bcurfew\\b",CURFEW_RE],["labour","\\b(labou?r|work|gangs?)\\b",LABOUR_RE],["conscript","\\b(conscripts|recruits|the men we took)\\b",CONSCRIPT_RE]]:
			if not _has(free_words,String(pair[1])): continue
			what.append(String(pair[0]))
			var own:=_find(main,String(pair[2]))
			if own!=null and own.get_start()<span.y and own.get_end()>span.x: found.erase(String(pair[0]))
		if what.is_empty() or _has(free_words,"\\b(men|males|prisoners|bound)\\b"): what.append("bind_men")
		if _has(free_words,"\\b(them|everyone|everybody|all of them)\\b"):
			for id in ["hostages","labour"]:
				if not what.has(id): what.append(id)
		out.release=what
		# Whom it unties: the groups the words name ("let the women go"), or
		# everyone we bind when they name none ("free them", "free the prisoners").
		var clause:=_clause_from(main,release.get_start())
		var names_group:=false
		for g in WHO_WORDS: if _has(clause.replace("old men","old ones") if String(g)=="men" else clause,String(WHO_WORDS[g])): names_group=true
		out["release_who"]=_who_of(clause) if names_group and not _has(clause,ALL_PEOPLE) else "people"
	# Unique, in the order they are carried out.
	var ordered:Array[String]=[]
	for id:String in IDS:
		if found.has(id) and not ordered.has(id): ordered.append(id)
	out.measures=ordered
	# The stance: a condition's consequence first, then words said outright.
	var stance:=String(cond.stance)
	if _has(lower,STANCE_BRUTAL_RE): stance=_harder(stance,"brutal")
	elif _has(main,STANCE_HARSH_RE): stance=_harder(stance,"harsh")
	if _has(main,"\\bthreaten (their|the) (wives|women|children|families|kin)\\b"): out.families=true
	if stance=="" and _has(main,STANCE_LENIENT_RE): stance="lenient"
	out.stance_set=stance!=""
	out.stance=stance if stance!="" else "firm"
	if ordered.is_empty() and not bool(out.stance_set): return {}
	out.people=_has(main,PEOPLE_WORDS) or _has(String(cond.clause),PEOPLE_WORDS)
	out.pronoun=not bool(out.people) and _has(main,"\\b(them|they|their)\\b")
	# The fate flags these measures already explain (town_fate.fate_words).
	var consumes:Array=[]
	if ordered.any(func(id:String)->bool: return id in ["bind_men","hostages","curfew","labour","conscript","set_headman","relief"]): consumes.append("hold")
	if ordered.has("requisition"): consumes.append("tribute")
	if ordered.has("execute_ringleaders") and not _has(main,"\\b(all|every|the rest of|rest of)\\s+(the\\s+)?(men|males)\\b"): consumes.append_array(["kill_men","kill_all"])
	if ordered.has("release"): consumes.append("free")
	if ordered.has("relief") or (String(out.stance)=="lenient" and not ordered.is_empty()): consumes.append("spare")
	if ordered.has("labour") and not _has(main,"\\b(enslave|slaves?)\\b"): consumes.append("policy")
	# "Burn their spears" burns the weapons, not the town.
	if ordered.has("disarm") and bool(out.destroy): consumes.append("raze")
	# A threat on a condition is a stance, never an order to kill everyone.
	if String(cond.clause)!="": consumes.append_array(["kill_men","kill_all","captives"])
	out.consumes=consumes
	return out

## Which of the town's people the words name: "men" (the default),
## "women", "children", "elders", several ("women,children") or "people"
## (everyone), in the ledger's groups.
const WHO_WORDS:={
	"men":"\\b(men|males|menfolk|husbands|fathers|sons|fighters|warriors|youths|every man|each man|any man)\\b",
	"women":"\\b(women|womenfolk|wives|females|mothers)\\b",
	"children":"\\b(children|boys|girls|daughters|young ones|little ones|babies|infants)\\b",
	"elders":"\\b(elders|old men|old women|old people|old ones|grandfathers|grandmothers)\\b",
}
const ALL_PEOPLE:="\\b(everyone|everybody|all of them|them all|the people|its people|their people|villagers|townsfolk|townspeople|inhabitants|residents|families|every soul)\\b"

static func _who_of(said:String)->String:
	if _has(said,ALL_PEOPLE): return "people"
	var parts:PackedStringArray=PackedStringArray()
	for g in Ledger.GROUPS:
		# "old men" are elders, not men.
		var words:=said.replace("old men","old ones") if g=="men" else said
		if _has(words,String(WHO_WORDS[g])): parts.append(g)
	if parts.is_empty(): return "men"
	return "people" if parts.size()==Ledger.GROUPS.size() else ",".join(parts)

## The clause of an order from a match onward, to its end (". ; ! ?").
static func _clause_from(text:String,at:int)->String:
	var rest:=text.substr(at)
	var stop:=_re("[.;!?]").search(rest)
	return rest.substr(0,stop.get_start()) if stop!=null else rest

## A town or a people we know by that name (never a person to set over them).
static func _is_place(word:String)->bool:
	var key:=word.strip_edges().to_lower()
	if key=="" or key.begins_with("one of") or key.begins_with("our") or key.begins_with("a "): return false
	if WorldSimulation.state!=null and String(WorldSimulation.state.settlement_name).to_lower()==key: return true
	var world:Variant=_world()
	if world==null: return false
	for civ in world.civilizations:
		if not civ is Dictionary: continue
		if String((civ as Dictionary).get("name","")).to_lower()==key: return true
		for region in (civ as Dictionary).get("strategic_regions",[]):
			if region is Dictionary and String((region as Dictionary).get("name","")).to_lower()==key: return true
	return false

## The typed words with the conditional clauses cut out, keeping their case
## (a name is known by its capital letter).
static func _uncut(clean:String,cuts:Array)->String:
	var out:=clean
	for cut in cuts:
		var i:=out.to_lower().find(String(cut))
		if i>=0 and String(cut)!="": out=out.substr(0,i)+out.substr(i+String(cut).length())
	return out

## Is this an order at all ("make them understand who rules now"), rather
## than a remark about the town?
static func looks_like_order(text:String)->bool:
	var lower:=text.strip_edges().to_lower()
	if lower.is_empty() or lower.ends_with("?"): return false
	for lead:String in ORDER_LEADS:
		if lower.begins_with(lead): return true
	var comma:=lower.find(",")
	if comma>0 and comma<28 and lower.substr(0,comma).split(" ",false).size()<=3: lower=lower.substr(comma+1).strip_edges()
	for lead:String in ORDER_LEADS:
		if lower.begins_with(lead): return true
	var words:=lower.split(" ",false)
	if words.is_empty(): return false
	var first:=String(words[0]).trim_suffix("!").trim_suffix(".").trim_suffix(",")
	if first in IMPERATIVES: return true
	return _has(lower,"\\b(must|is to|are to|shall|should be|needs to|need to)\\b")

## Loose words about a held town's people mapped to the closest measure and
## tone: {id ("" when none), tone ("harsh"|"lenient"|"neutral"), stance,
## grave}. "Punish them" is nearest to putting the ringleaders to death.
const NEAREST:={
	"bind_men":["prisoner","prisoners","captive","guard them","watch them","pen them","corral","contain","hold the men","keep the men","grab","collect the men","lock","secure them","secure the men","gather the men"],
	"disarm":["weapon","weapons","spear","spears","bow","bows","armed"],
	"hostages":["elders","surety","pledge","their chief's","the headman's"],
	"curfew":["indoors","at night","after dark","quiet at night","keep them in","off the lanes"],
	"search":["search","look through","hidden","hiding","comb","dig out"],
	"labour":["work","labour","labor","build","dig","carry","haul","toil","useful","serve us","sweat"],
	"requisition":["food","grain","stores","harvest","cattle","herds","provisions","eat"],
	"conscript":["fight for us","join us","our bands","serve with","as soldiers","into our ranks","our levy"],
	"execute_ringleaders":["example","punish","ringleader","ringleaders","troublemaker","troublemakers","hang","put down","pay for","make them pay","root out the leaders"],
	"release":["free","let go","loose","untie","send home","set free"],
	"relief":["feed","help","care","heal","gift","gifts","reward","protect","safe","look after","kind to","be good to"],
	"set_headman":["headman","chief","in charge","over them","govern","run the town","someone to rule"],
	"settle":["settlers","our families","our people live","move in","take over the houses"],
}
const TONE_HARSH:=["hard","harsh","harshly","fear","terrify","punish","crush","break","teach","show them","obey","submit","who rules","who is master","tremble","afraid","squeeze","grind","tight","firm","control","keep them down","in line","no nonsense","understand"]
const TONE_LENIENT:=["kind","kindly","gentle","gently","care","soft","mercy","merciful","well","fair","fairly","friends","trust","calm","peace","easy","ease","help","decently","respect them","win them","let them be","leave them be","leave them alone","in peace"]

static func nearest(text:String)->Dictionary:
	var lower:=" "+text.to_lower().replace(","," ").replace("."," ").replace("!"," ").replace(";"," ")+" "
	var best:=""; var score:=0
	for id:String in NEAREST:
		var hits:=0
		for word:String in NEAREST[id]:
			if lower.contains(" "+word+" ") or lower.contains(" "+word+"s "): hits+=1
		if hits>score: score=hits; best=id
	var harsh:=0; var soft:=0
	for word:String in TONE_HARSH:
		if lower.contains(" "+word+" "): harsh+=1
	for word:String in TONE_LENIENT:
		if lower.contains(" "+word+" "): soft+=1
	var tone:="neutral"
	if harsh>soft: tone="harsh"
	elif soft>harsh: tone="lenient"
	if best in ["release","relief"] and tone=="neutral": tone="lenient"
	var stance:=String({"harsh":"harsh","lenient":"lenient"}.get(tone,"firm"))
	return {"id":best,"tone":tone,"stance":stance,"grave":best in GRAVE}

## The plain words of a measure as an order ("Round up the men of Tsaren and
## bind them"): what the war leader's reading carries out when confirmed.
static func order_words(id:String,town:String)->String:
	var words:=String((CATALOGUE.get(id,{}) as Dictionary).get("order",""))
	return words % town if words.contains("%s") else words


# --------------------------------------------------------------------------
# Where things stand
# --------------------------------------------------------------------------

static func _mc()->Variant: return WorldSimulation.military
static func _world()->Variant: return WorldSimulation.world
static func _day()->int: return int(WorldSimulation.state.elapsed_days) if WorldSimulation.state!=null else 0

static func _force_index(civ_id:String,region_id:String)->int:
	var mc:Variant=_mc()
	if mc==null: return -1
	return int(mc._occupation_force_index(civ_id,region_id))

## Every measure record on a garrison (running or recently ended).
static func records(civ_id:String,region_id:String)->Array:
	var at:=_force_index(civ_id,region_id)
	if at<0: return []
	var list:Variant=_mc().occupation_forces[at].get("measures",[])
	return list if list is Array else []

## The measures still running on a garrison, most important first.
static func active(civ_id:String,region_id:String)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	for m in records(civ_id,region_id):
		if m is Dictionary and not bool((m as Dictionary).get("ended",false)): out.append(m)
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return _priority(String(a.id))<_priority(String(b.id)))
	return out

static func _priority(id:String)->int:
	var order:=["bind_men","hostages","labour","conscript","execute_ringleaders","curfew","disarm","requisition","set_headman","settle","relief","search","word"]
	var i:=order.find(id)
	return i if i>=0 else 99

static func _running(force:Dictionary,id:String)->Dictionary:
	var list:Variant=force.get("measures",[])
	if not list is Array: return {}
	for m in list:
		if m is Dictionary and String((m as Dictionary).get("id",""))==id and not bool((m as Dictionary).get("ended",false)): return m
	return {}

## Men of this town bound and under our guard now (the town's ledger).
static func men_bound(civ_id:String,region_id:String)->int:
	if not Ledger.has(civ_id,region_id): return 0
	var l:=Ledger.of(civ_id,region_id)
	var at:=_force_index(civ_id,region_id)
	return Ledger.count(l,"bound","men")+(bound_workers(_mc().occupation_forces[at],l) if at>=0 else 0)

## A measure that holds people ends when nobody it held is left in the town
## (killed, taken, scattered); the guards on the bound shrink with them.
static func settle_records(civ_id:String,region_id:String)->void:
	var at:=_force_index(civ_id,region_id)
	if at<0 or not Ledger.has(civ_id,region_id): return
	var force:Dictionary=_mc().occupation_forces[at]
	_end_empty(force,Ledger.of(civ_id,region_id),_day())
	refresh_note(force)

static func _end_empty(force:Dictionary,l:Dictionary,day:int)->void:
	for pair in [["bind_men","bound"],["hostages","hostage"],["labour","worker"],["conscript","conscript"]]:
		var m:=_running(force,String(pair[0]))
		# The bound men put to work are still bound men.
		var still:=Ledger.count(l,String(pair[1]))+(bound_workers(force,l) if String(pair[0])=="bind_men" else 0)
		if not m.is_empty() and still<=0:
			m["ended"]=true; m["end_day"]=day; m["end_reason"]="none_left"
	var bind:=_running(force,"bind_men")
	if not bind.is_empty(): bind["guards"]=maxi(1,ceili(float(Ledger.count(l,"bound"))/float(BOUND_PER_GUARD)))
	var hostages:=_running(force,"hostages")
	if not hostages.is_empty(): hostages["guards"]=maxi(1,ceili(float(Ledger.count(l,"hostage"))/float(HOSTAGES_PER_GUARD)))

## The garrison's free hands: its strength less the gate watch and the
## guards already tied to running measures.
static func free_hands(force:Dictionary)->int:
	var garrison:=int(force.get("troops",0))
	var keep:=maxi(KEEP_AT_LEAST,ceili(float(garrison)*KEEP_SHARE)) if garrison>KEEP_AT_LEAST else garrison
	var guards:=0
	for m in force.get("measures",[]):
		if m is Dictionary and not bool((m as Dictionary).get("ended",false)): guards+=int(m.get("guards",0))
	return maxi(0,garrison-keep-guards)


# --------------------------------------------------------------------------
# Carrying it out
# --------------------------------------------------------------------------

## opts: {stance, stance_set, families, clause, who, work, count, headman,
##  release:[ids], destroy, heavy, tone (for a standing word), words (the
##  god's words), reading ("nearest" when it is the war leader's own guess)}.
## -> {ok, town, text (the war leader's account), outcome (one plain note),
##     applied:[ids started], renewed:[ids], freed:[ids], refused:[reasons],
##     bound, fled, killed, hostages, weapons, food, workers, conscripts,
##     fled_record} | {error}.
static func apply(civ_id:String,region_id:String,ids:Array,opts:Dictionary={},general:Dictionary={})->Dictionary:
	var world:Variant=_world(); var mc:Variant=_mc()
	if world==null or mc==null: return {"error":"Nobody holds that town for us."}
	var region:Dictionary=world.region_snapshot(civ_id,region_id)
	var at:=_force_index(civ_id,region_id)
	# Who holds it: the one reading every system uses (town_ledger.hold).
	var h:=Ledger.hold(civ_id,region_id)
	if region.is_empty() or at<0 or not bool(h.held):
		var why:=Ledger.hold_words(h)
		return {"error":(why+" Nobody of ours is there to carry it out.") if why!="" else "We do not hold that town."}
	var force:Dictionary=mc.occupation_forces[at]
	var garrison:=int(h.garrison)
	if not force.get("measures") is Array: force["measures"]=[]
	var stance:=String(opts.get("stance","firm"))
	if not stance in STANCE_IDS: stance="firm"
	var day:=_day()
	var tags:=CV.era_tags("player")
	# The town's one ledger of its people: every measure reads and writes it.
	var l:=Ledger.of(civ_id,region_id)
	var c:={"civ_id":civ_id,"region_id":region_id,"name":String(region.get("name",force.get("region_name","the town"))),"population":maxi(0,roundi(float(region.get("population",0.0)))),
		"garrison":garrison,"force":force,"ledger":l,"stance":stance,"S":STANCES[stance],"opts":opts,"day":day,"tags":tags,"metal":tags.has("metal"),"general":general,
		"texts":[],"notes":[],"titles":[],"applied":[],"renewed":[],"freed":[],"refused":[],"harsh":0.0,"mercy":0.0,"weight":0,"killed":0,"fled":0,
		"gov":{},"resist_mul":1.0,"resist_add":0.0,"integration_add":0.0,"results":{},"fled_record":{}}
	c["men"]=Ledger.here(l,"men")
	var order:Array[String]=[]
	for id:String in IDS:
		if ids.has(id) and not order.has(id): order.append(id)
	if order.is_empty(): order.append(WORD)
	for id:String in order:
		match id:
			"release": _release(c)
			"execute_ringleaders": _execute(c)
			"hostages": _hostages(c)
			"curfew": _curfew(c)
			"bind_men": _bind(c)
			"disarm": _disarm(c)
			"search": _search(c)
			"labour": _labour(c)
			"conscript": _conscript(c)
			"requisition": _requisition(c)
			"relief": _relief(c)
			"set_headman": _headman(c)
			"settle": _settle(c)
			WORD: _word(c)
	if (c.texts as Array).is_empty():
		return {"error":" ".join(PackedStringArray(c.refused)) if not (c.refused as Array).is_empty() else "There is nothing the garrison can do about that."}
	var line:=_stance_line(c,order)
	if line!="": (c.texts as Array).append(line)
	if not (c.refused as Array).is_empty(): (c.texts as Array).append("But "+_lower_first(" ".join(PackedStringArray(c.refused))))
	_region_effects(c)
	_consequences(c)
	_end_empty(force,c.ledger,day)
	_trim(force)
	refresh_note(force)
	_chronicle(c)
	var gpid:=int(general.get("person_id",0))
	if gpid>0 and not (c.notes as Array).is_empty():
		var memory:=("At the god's word, in %s: %s" % [String(c.name),_lower_first(" ".join(PackedStringArray(c.notes)))]).substr(0,220)
		GovernmentPeopleSystem.record_person_memory(gpid,memory,"divine",0.7,{"emotion":"duty","outcome":"town_measure"})
	var results:Dictionary=c.results
	var out:={"ok":true,"town":String(c.name),"text":CV.era_plain(" ".join(PackedStringArray(c.texts)),tags),"outcome":_outcome(c),"applied":(c.applied as Array).duplicate(),"renewed":(c.renewed as Array).duplicate(),
		"freed":(c.freed as Array).duplicate(),"refused":(c.refused as Array).duplicate(),"killed":int(c.killed),"fled":int(c.fled),"stance":stance,"fled_record":(c.fled_record as Dictionary).duplicate()}
	for key in results: out[key]=results[key]
	return out

static func _rng(region_id:String,day:int,salt:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("measure|%d|%s|%d|%s" % [int(GameState.world_seed),region_id,day,salt])
	return rng

## A new running record on the garrison, with its chance of a later incident.
static func _start(c:Dictionary,id:String,fields:Dictionary)->Dictionary:
	var days:=int((CATALOGUE[id] as Dictionary).days)
	var m:={"id":id,"day":int(c.day),"until":int(c.day)+days,"stance":String(c.stance),"last_day":int(c.day),"ended":false,"end_day":-1,"families":bool((c.opts as Dictionary).get("families",false))}
	m.merge(fields,true)
	var S:Dictionary=c.S
	var chance:=clampf(float(S.incident)*float((CATALOGUE[id] as Dictionary).get("incident",0.0)),0.0,0.3)
	if chance>0.0 and days>2:
		var rng:=_rng(String(c.region_id),int(c.day),id)
		if rng.randf()<chance: m["incident"]={"day":int(c.day)+rng.randi_range(2,mini(12,days-1)),"done":false}
	((c.force as Dictionary).measures as Array).append(m)
	(c.applied as Array).append(id)
	return m

## The same order given again while it runs: it runs longer, never twice.
static func _renew(c:Dictionary,m:Dictionary)->void:
	var id:=String(m.id)
	m["until"]=maxi(int(m.get("until",0)),int(c.day)+int((CATALOGUE[id] as Dictionary).days))
	m["stance"]=_harder(String(m.get("stance","firm")),String(c.stance)) if bool((c.opts as Dictionary).get("stance_set",false)) else String(m.get("stance","firm"))
	if bool((c.opts as Dictionary).get("families",false)): m["families"]=true
	m["renewed"]=int(m.get("renewed",0))+1
	(c.renewed as Array).append(id)

static func _gov(c:Dictionary,deltas:Dictionary)->void:
	var gov:Dictionary=c.gov
	for key in deltas: gov[key]=float(gov.get(key,0.0))+float(deltas[key])

static func _resent(c:Dictionary)->float: return float((c.S as Dictionary).resent)

## People put to death, in the order given (plan: [[status, group], ...]).
## The town's ledger is read afresh after (the world's deaths rebuild the
## town's record). Returns how many died.
static func _kill(c:Dictionary,plan:Array,count:int)->int:
	var dead:=_die(String(c.civ_id),String(c.region_id),plan,count)
	c["ledger"]=Ledger.of(String(c.civ_id),String(c.region_id))
	c["killed"]=int(c.killed)+dead
	c["population"]=maxi(0,int(c.population)-dead)
	return dead

## Deaths in a town we hold: the ledger first (it goes with the town's
## record the world rebuilds), then the world's count.
static func _die(civ_id:String,region_id:String,plan:Array,count:int)->int:
	var l:=Ledger.of(civ_id,region_id)
	if count<=0 or l.is_empty(): return 0
	var have:=0
	for step in plan: have+=Ledger.count(l,String(step[0]),String(step[1]))
	count=mini(count,have)
	if count<=0: return 0
	var world:Variant=_world()
	var index:int=world._civilization_index(civ_id)
	if index<0: return 0
	var dead:=int(Ledger.remove(l,plan,count,"killed").total)
	var done:Dictionary=world._apply_rival_civilian_deaths(world.civilizations[index],region_id,dead)
	world.civilizations[index]=done.civilization
	return dead

# --- Food ---------------------------------------------------------------------

## Food in the town's own stores: the rival's ledger when it is simulated,
## else its food days for the people of this town.
static func town_food(civ_id:String,region_id:String)->float:
	var stock:=Hall.foreign_stock(civ_id,"Food")
	if stock>=0.0: return stock
	var world:Variant=_world()
	var index:int=world._civilization_index(civ_id)
	if index<0: return 0.0
	var civ:Dictionary=world.civilizations[index]
	var region:Dictionary=world.region_snapshot(civ_id,region_id)
	return maxf(0.0,float(civ.get("food_days",0.0))*float(region.get("population",0.0)))

static func _take_town_food(civ_id:String,region_id:String,amount:float)->float:
	if amount<=0.0: return 0.0
	if Hall.foreign_stock(civ_id,"Food")>=0.0: return float(Hall.EXCHANGE.take(civ_id,"Food",amount))
	var world:Variant=_world()
	var index:int=world._civilization_index(civ_id)
	if index<0: return 0.0
	var civ:Dictionary=world.civilizations[index]
	var got:=minf(amount,town_food(civ_id,region_id))
	civ["food_days"]=maxf(0.0,float(civ.get("food_days",0.0))-got/maxf(1.0,float(civ.get("population",1.0))))
	world.civilizations[index]=civ
	return got

static func _give_town_food(civ_id:String,amount:float)->void:
	if amount<=0.0: return
	if Hall.foreign_stock(civ_id,"Food")>=0.0: Hall.EXCHANGE.receive(civ_id,"Food",amount); return
	var world:Variant=_world()
	var index:int=world._civilization_index(civ_id)
	if index<0: return
	var civ:Dictionary=world.civilizations[index]
	civ["food_days"]=float(civ.get("food_days",0.0))+amount/maxf(1.0,float(civ.get("population",1.0)))
	world.civilizations[index]=civ

static func _take_our_food(amount:float)->float:
	var have:=Hall.player_stock("Food")
	if amount<=0.0 or have<=0.0: return 0.0
	return float(Hall.EXCHANGE.take("player","Food",minf(amount,have)))

static func _receive_our_food(amount:float)->void:
	if amount>0.0: Hall.EXCHANGE.receive("player","Food",amount)

# --- Words --------------------------------------------------------------------

static func _count(n:int)->String:
	return preload("res://scripts/battle_account.gd").count_words(n) if n<=12 else str(n)

static func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)

static func _lower_first(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_lower()+text.substr(1)

static func _days(n:int)->String:
	return "a day" if n<=1 else "%s days" % _count(n)

static func _home()->String:
	var name:=String(WorldSimulation.state.settlement_name) if WorldSimulation.state!=null else ""
	return name if name!="" else "home"

static func _bind_means(c:Dictionary)->String:
	var words:=String((c.opts as Dictionary).get("words","")).to_lower()
	if bool(c.metal) and _has(words,"\\b(chain|chains|chained|shackle|shackles|shackled|fetter|fetters|irons)\\b"): return "bound in chains"
	return "bound hand and foot with cords" if not bool(c.metal) else "bound hand and foot"

static func _weapon_words(c:Dictionary)->String:
	return "spears, bows, axes and knives" if bool(c.metal) else "spears, bows, axes and clubs"

static func _wall_words(c:Dictionary)->String:
	return "a wall and a ditch" if (c.tags as Array).has("masonry") else "a stake wall and a ditch"

static func _road_words(c:Dictionary)->String:
	return "a road" if (c.tags as Array).has("wheel") else "a track"

# --- The measures -------------------------------------------------------------

## Who "the men" of an order are, as ledger groups ("women,children" names two).
static func _who_groups(who:String)->Array:
	if who in ["people",""]: return ["men","women","elders","children"]
	var out:Array=[]
	for part in who.split(",",false):
		if String(part) in Ledger.GROUPS: out.append(String(part))
	return out if not out.is_empty() else ["men"]

static func _who_words(who:String)->String:
	if who in ["people",""]: return "people"
	var words:PackedStringArray=PackedStringArray()
	for g in _who_groups(who): words.append(String(Ledger.GROUP_WORDS[g]))
	return " and ".join(words)

static func _bind(c:Dictionary)->void:
	var force:Dictionary=c.force
	var l:Dictionary=c.ledger
	var name:=String(c.name)
	var opts:Dictionary=c.opts
	var who:=String(opts.get("who","men"))
	var groups:=_who_groups(who)
	var words:=_who_words(who)
	var running:=_running(force,"bind_men")
	var free:=0
	var held:=0
	for g in groups:
		free+=Ledger.count(l,"free",String(g))
		held+=Ledger.count(l,"bound",String(g))
	if free<=0:
		if not running.is_empty() and held>0:
			_renew(c,running)
			(c.texts as Array).append("The %s of %s are already bound and under guard, %s of them. They stay so for another month." % [words,name,_count(held)])
			c.results["bound"]=Ledger.count(l,"bound")
		else:
			(c.refused as Array).append("There are no %s left free in %s to bind." % [words,name])
		return
	var hands:=free_hands(force)
	if hands<=0:
		(c.refused as Array).append("Every one of the %s holding %s is on the gate or already guarding; there is nobody to spare for a round-up. Send me more, or let some of those we hold go." % [_count(int(c.garrison)),name]); return
	var wanted:=free
	if int(opts.get("count",0))>0: wanted=mini(wanted,int(opts.count))
	# The odds, stated: the share who slip away as a round-up starts, by the
	# hand we show; fewer when they are kept indoors or their kin are hostages.
	var S:Dictionary=c.S
	var flight:=ROUND_UP_FLIGHT*float(S.escape)
	if not _running(force,"curfew").is_empty(): flight*=0.5
	if Ledger.count(l,"hostage")>0: flight*=0.6
	flight=clampf(flight,0.03,0.45)
	var r:=_rng(String(c.region_id),int(c.day),"round-up:"+who)
	var refuge:=Pursuit.refuge(String(c.civ_id),String(c.region_id))
	var capacity:=hands*BOUND_PER_GUARD
	var fled:=0
	var bound:=0
	var left:=wanted
	for g in groups:
		if left<=0: break
		var want:=mini(Ledger.count(l,"free",String(g)),left)
		left-=want
		# Men run at the full rate; women, the old and children at half.
		var ran:=Ledger.roll(r,want,flight if String(g)=="men" else flight*0.5)
		if ran>0: Ledger.run(l,"free",String(g),ran,refuge,int(c.day))
		fled+=ran
		bound+=Ledger.move(l,"free","bound",String(g),mini(want-ran,capacity-bound))
	var loose:=0
	for g in groups: loose+=Ledger.count(l,"free",String(g))
	var killed:=0
	if String(c.stance)=="brutal":
		killed=_kill(c,[["bound","men"]],mini(5,roundi(float(bound)*0.04)))
		l=c.ledger
	bound-=killed
	var guards:=maxi(1,ceili(float(Ledger.count(l,"bound"))/float(BOUND_PER_GUARD)))
	if running.is_empty(): _start(c,"bind_men",{"guards":guards,"who":who})
	else:
		running["guards"]=guards
		running["who"]=who if String(running.get("who","men"))==who else "people"
		_renew(c,running)
		(c.applied as Array).append("bind_men")
		(c.renewed as Array).erase("bind_men")
	c["fled"]=int(c.fled)+fled
	if fled>0: c["fled_record"]=Ledger.running(l).duplicate(true)
	c.results["bound"]=bound; c.results["guards"]=guards; c.results["flight_odds"]=flight
	c["resist_mul"]=float(c.resist_mul)*0.55
	_gov(c,{"grievance":0.10*_resent(c),"trust":-0.06*_resent(c),"welfare":-0.04,"repression":0.10})
	c["harsh"]=float(c.harsh)+1.0
	c["weight"]=int(c.weight)+bound
	var t:="We went house to house in %s. %s %s are %s and kept together under guard; %s of the %s of ours watch them in turns." % [name,_cap(_count(bound)),words,_bind_means(c),_count(guards),_count(int(c.garrison))]
	if fled>0: t+=" %s got away %s before we reached them; %s run when a round-up starts, the way we went about it." % [_cap(_count(fled)),Pursuit.toward_words(refuge),Ledger.chance_words(flight)]
	else: t+=" None got away."
	if loose>0: t+=" We are too few to guard more; %s are still loose in their houses." % _count(loose)
	if killed>0: t+=" %s fought us and were killed." % _cap(_count(killed))
	t+=" They eat from their own stores."
	(c.texts as Array).append(t)
	(c.notes as Array).append("%s %s of %s were bound and put under guard%s." % [_cap(_count(bound)),words,name,"; %s got away" % _count(fled) if fled>0 else ""])
	(c.titles as Array).append("The %s of %s Bound" % [_cap(words),name])

static func _disarm(c:Dictionary)->void:
	var force:Dictionary=c.force
	var name:=String(c.name)
	var running:=_running(force,"disarm")
	if not running.is_empty():
		_renew(c,running)
		(c.texts as Array).append("We took their weapons already. I have had the houses gone through again and the order stands.")
		return
	var stance:=String(c.stance)
	var found:=clampi(roundi(float(c.men)*0.8*(0.75 if stance=="lenient" else (1.1 if stance in ["harsh","brutal"] else 1.0))),0,300)
	if found<=0:
		(c.refused as Array).append("There is nobody left in %s with weapons to take." % name); return
	var destroy:=bool((c.opts as Dictionary).get("destroy",false))
	var kept:=0
	if not destroy:
		kept=mini(found,40)
		var mc:Variant=_mc()
		mc.military_inventory["improvised"]=int(mc.military_inventory.get("improvised",0))+kept
	_start(c,"disarm",{"count":found,"kept":kept,"destroyed":destroy,"guards":0})
	c.results["weapons"]=found
	c["resist_mul"]=float(c.resist_mul)*0.8
	_gov(c,{"grievance":0.05*_resent(c),"trust":-0.03*_resent(c),"repression":0.05})
	c["harsh"]=float(c.harsh)+0.4
	c["weight"]=int(c.weight)+found/4
	var t:="We searched every house in %s; %s weapons were taken: %s." % [name,_count(found),_weapon_words(c)]
	if destroy: t+=(" We broke them and burned the shafts in the middle of the town, where they could all see." if bool(c.metal) else " We burned them in the middle of the town, where they could all see.")
	else: t+=" They are kept with the garrison; %s of them will serve our own levy." % _count(kept)
	(c.texts as Array).append(t)
	(c.notes as Array).append("%s weapons were taken from the houses of %s%s." % [_cap(_count(found)),name," and burned" if destroy else ""])
	(c.titles as Array).append("%s Disarmed" % name)

static func _hostages(c:Dictionary)->void:
	var force:Dictionary=c.force
	var l:Dictionary=c.ledger
	var name:=String(c.name)
	var running:=_running(force,"hostages")
	if not running.is_empty() and Ledger.count(l,"hostage")>0:
		_renew(c,running)
		(c.texts as Array).append("We hold %s hostages from %s already. They stay with the garrison." % [_count(Ledger.count(l,"hostage")),name])
		return
	var opts:Dictionary=c.opts
	var free:=Ledger.count(l,"free")
	var n:=int(opts.count) if int(opts.get("count",0))>0 else clampi(roundi(float(c.population)*0.03),2,12)
	n=mini(n,mini(20,free))
	var hands:=free_hands(force)
	if hands<=0:
		(c.refused as Array).append("Nobody can be spared to guard hostages; every one of the %s is on the gate or already guarding." % _count(int(c.garrison))); return
	n=mini(n,hands*HOSTAGES_PER_GUARD)
	if n<=0:
		(c.refused as Array).append("There is nobody left free in %s to take." % name); return
	# Two of their elders, then the families of the men who led the fighting.
	var elders:=Ledger.move_any(l,"free","hostage",mini(2,n),["elders","men","women"])
	var family:=Ledger.move_any(l,"free","hostage",n-mini(2,n),["women","children","elders","men"])
	var got:=0
	for g in elders: got+=int(elders[g])
	for g in family: got+=int(family[g])
	var guards:=maxi(1,ceili(float(Ledger.count(l,"hostage"))/float(HOSTAGES_PER_GUARD)))
	if not running.is_empty(): running["ended"]=true; running["end_day"]=int(c.day); running["end_reason"]="again"
	_start(c,"hostages",{"guards":guards})
	c.results["hostages"]=got
	c["resist_mul"]=float(c.resist_mul)*0.75
	_gov(c,{"grievance":0.06*_resent(c),"trust":-0.04*_resent(c)})
	c["harsh"]=float(c.harsh)+0.7
	c["weight"]=int(c.weight)+got
	var old:=int(elders.get("elders",0))
	var whom:=""
	if got<=old: whom="%s of their elders" % _count(got)
	elif old>0: whom="%s of their elders and %s from the families of the men who led the fighting" % [_count(old),_count(got-old)]
	else: whom="%s from the families of the men who led the fighting" % _count(got)
	(c.texts as Array).append("We took %s of %s's people as hostages: %s. They are held in the garrison's house under watch, and the town knows they answer for any rising." % [_count(got),name,whom])
	(c.notes as Array).append("%s hostages were taken from %s." % [_cap(_count(got)),name])
	(c.titles as Array).append("Hostages Taken at %s" % name)

static func _curfew(c:Dictionary)->void:
	var force:Dictionary=c.force
	var name:=String(c.name)
	var running:=_running(force,"curfew")
	if not running.is_empty():
		_renew(c,running)
		(c.texts as Array).append("They are kept to their houses already; the order holds another twenty days.")
		return
	var patrol:=mini(2,free_hands(force))
	_start(c,"curfew",{"guards":patrol,"count":patrol})
	_gov(c,{"welfare":-0.03,"grievance":0.04*_resent(c),"trust":-0.02*_resent(c)})
	c["harsh"]=float(c.harsh)+(0.4 if patrol>0 else 0.2)
	if patrol>0:
		(c.texts as Array).append("From tonight nobody in %s leaves their house after dark, and by day only to the fields and the water. %s of ours walk the lanes at night. It holds for twenty days unless you say otherwise." % [name,_cap(_count(patrol))])
	else:
		(c.texts as Array).append("Nobody in %s is to leave their house after dark, but every one of ours is on the gate or guarding, so nobody walks the lanes to see it kept." % name)
	(c.notes as Array).append("The people of %s were kept to their houses after dark." % name)
	(c.titles as Array).append("%s Kept Indoors" % name)

static func _search(c:Dictionary)->void:
	var force:Dictionary=c.force
	var l:Dictionary=c.ledger
	var name:=String(c.name)
	var old:=_running(force,"search")
	if not old.is_empty(): old["ended"]=true; old["end_day"]=int(c.day); old["end_reason"]="again"
	var disarmed:=not _running(force,"disarm").is_empty()
	var weapons:=roundi(float(c.men)*(0.05 if disarmed else 0.25))
	var food:=0.0
	if String(c.stance)!="lenient":
		food=_take_town_food(String(c.civ_id),String(c.region_id),minf(town_food(String(c.civ_id),String(c.region_id))*0.08,60.0))
		_receive_our_food(food)
	var hid:=0
	var bind:=_running(force,"bind_men")
	if not bind.is_empty():
		# Men who hid from the round-up, found in roofs and pits, bound with the rest.
		var r:=_rng(String(c.region_id),int(c.day),"search")
		var found_men:=Ledger.roll(r,Ledger.count(l,"free","men"),0.3)
		hid=Ledger.move(l,"free","bound","men",mini(found_men,free_hands(force)*BOUND_PER_GUARD))
		bind["guards"]=maxi(1,ceili(float(Ledger.count(l,"bound"))/float(BOUND_PER_GUARD)))
	_start(c,"search",{"weapons":weapons,"food":roundi(food),"hid":hid,"guards":0})
	c.results["weapons"]=int(c.results.get("weapons",0))+weapons
	if hid>0: c.results["bound"]=int(c.results.get("bound",0))+hid
	c["resist_add"]=float(c.resist_add)-0.05
	_gov(c,{"grievance":0.04*_resent(c),"trust":-0.02*_resent(c)})
	c["harsh"]=float(c.harsh)+0.3
	var found:PackedStringArray=PackedStringArray()
	if weapons>0: found.append("%s spears and bows hidden in roofs and under floors" % _count(weapons))
	if food>=1.0: found.append("%d Food hidden away, now in our stores" % roundi(food))
	if hid>0: found.append("%s men hiding, now bound with the rest" % _count(hid))
	var list:=", ".join(found) if found.size()<=1 else ", ".join(found.slice(0,found.size()-1))+" and "+found[found.size()-1]
	(c.texts as Array).append("We searched every house in %s. We found %s." % [name,list if not found.is_empty() else "nothing hidden"])
	(c.notes as Array).append("Every house in %s was searched." % name)
	(c.titles as Array).append("The Houses of %s Searched" % name)

static func _labour(c:Dictionary)->void:
	var force:Dictionary=c.force
	var l:Dictionary=c.ledger
	var name:=String(c.name)
	var opts:Dictionary=c.opts
	var running:=_running(force,"labour")
	# Who is put to work: the men unless the words name others ("make the
	# women work the fields"). Old records without it were the men.
	var who:=String(opts.get("work_who","men"))
	var groups:=_who_groups(who)
	var words:=_who_words(who)
	if not running.is_empty() and Ledger.count(l,"worker")>0:
		_renew(c,running)
		if String(opts.get("work",""))!="" and String(opts.work)!=String(running.get("work","")): running["work"]=String(opts.work)
		(c.texts as Array).append("The work gangs of %s go on another month, %s %s in them." % [name,_count(Ledger.count(l,"worker")),_who_words(String(running.get("who","men")))])
		return
	var bind:=_running(force,"bind_men")
	var bound_pool:=0
	for g in groups: bound_pool+=Ledger.count(l,"bound",String(g))
	var from:="bound" if bound_pool>0 else "free"
	var pool:=0
	for g in groups: pool+=Ledger.count(l,from,String(g))
	var hands:=free_hands(force)+(1 if from=="bound" else 0)
	var workers:=mini(pool,hands*WORKERS_PER_GUARD)
	if int(opts.get("count",0))>0: workers=mini(workers,int(opts.count))
	if workers<=0:
		(c.refused as Array).append(("Nobody can be spared to watch a work gang; every one of the %s is on the gate or already guarding." % _count(int(c.garrison))) if pool>0 else ("There are no %s left in %s to work." % [words,name]))
		return
	var moved:=0
	for g in groups:
		if moved>=workers: break
		moved+=Ledger.move(l,from,"worker",String(g),mini(Ledger.count(l,from,String(g)),workers-moved))
	workers=moved
	var guards:=0 if from=="bound" else maxi(1,ceili(float(workers)/float(WORKERS_PER_GUARD)))
	var work:=String(opts.get("work",""))
	if not running.is_empty(): running["ended"]=true; running["end_day"]=int(c.day); running["end_reason"]="again"
	_start(c,"labour",{"guards":guards,"work":work,"done":0.0,"from":from,"who":who})
	c.results["workers"]=workers
	c.results["work_who"]=who
	_gov(c,{"welfare":-0.05,"grievance":0.08*_resent(c),"trust":-0.05*_resent(c),"inequality":0.05,"repression":0.05})
	c["harsh"]=float(c.harsh)+0.8
	c["weight"]=int(c.weight)+workers
	var under:=_count(maxi(1,guards if guards>0 else int(bind.get("guards",1))))
	var gang:=("%s of the bound %s" % [_count(workers),words]) if from=="bound" else "%s %s of %s" % [_count(workers),words,name]
	var t:=""
	match work:
		"walls": t="From tomorrow %s are put to forced labour on %s round the town, in gangs under %s of ours. They eat from their own stores. It will take about a month." % [gang,_wall_words(c),under]
		"fields": t="From tomorrow %s are put to forced labour in their fields for us, under %s of ours. What they bring in feeds the garrison first, and the rest comes to %s." % [gang,under,_home()]
		"roads": t="From tomorrow %s are put to forced labour clearing %s from the town toward %s, under %s of ours. Our carriers will reach the garrison quicker when it is done." % [gang,_road_words(c),_home(),under]
		_: t="From tomorrow %s are put to forced labour, carrying and digging wherever the garrison needs them, under %s of ours." % [gang,under]
	(c.texts as Array).append(_cap(t))
	(c.notes as Array).append("%s %s of %s were put to forced labour." % [_cap(_count(workers)),words,name])
	(c.titles as Array).append("%s Put to Work" % name)

static func _requisition(c:Dictionary)->void:
	var force:Dictionary=c.force
	var name:=String(c.name)
	var heavy:=bool((c.opts as Dictionary).get("heavy",false))
	var running:=_running(force,"requisition")
	if not running.is_empty() and not heavy:
		(c.texts as Array).append("We took %d Food from their stores %s ago. What is left is what they eat; if you want that too, say so, and they go hungry." % [int(running.get("food",0)),_days(maxi(1,int(c.day)-int(running.day)))])
		return
	var stock:=town_food(String(c.civ_id),String(c.region_id))
	var share:=0.6 if heavy else 0.33
	var got:=_take_town_food(String(c.civ_id),String(c.region_id),minf(stock*share,float(c.garrison)*50.0))
	if got<1.0:
		(c.refused as Array).append("Their stores are already empty; there is nothing left to take."); return
	_receive_our_food(got)
	if not running.is_empty(): running["ended"]=true; running["end_day"]=int(c.day); running["end_reason"]="again"
	_start(c,"requisition",{"food":roundi(got),"heavy":heavy,"guards":0})
	c.results["food"]=roundi(got)
	_gov(c,{"welfare":-0.15 if heavy else -0.08,"grievance":(0.12 if heavy else 0.08)*_resent(c),"trust":-0.06*_resent(c)})
	c["resist_add"]=float(c.resist_add)+0.03
	c["harsh"]=float(c.harsh)+(0.9 if heavy else 0.6)
	c["weight"]=int(c.weight)+int(c.population)/6
	var t:="We opened the stores of %s and took %d Food from them, " % [name,roundi(got)]
	t+=("nearly all they had. They will go hungry before the next harvest." if heavy else "about a third of what they had. The rest is left so they can eat until the next harvest.")
	t+=" What we took feeds the garrison and %s." % _home()
	(c.texts as Array).append(t)
	(c.notes as Array).append("%d Food was taken from the stores of %s." % [roundi(got),name])
	(c.titles as Array).append("The Stores of %s Taken" % name)

static func _conscript(c:Dictionary)->void:
	var force:Dictionary=c.force
	var l:Dictionary=c.ledger
	var name:=String(c.name)
	var opts:Dictionary=c.opts
	var running:=_running(force,"conscript")
	if not running.is_empty() and Ledger.count(l,"conscript")>0:
		_renew(c,running)
		(c.texts as Array).append("Their young men already serve with the garrison, %s of them still with us." % _count(Ledger.count(l,"conscript")))
		return
	# Their young men: from the bound first, then the work gangs, then the free.
	var from:="free"
	for status in ["bound","worker","free"]:
		if Ledger.count(l,String(status),"men")>0: from=String(status); break
	var men:=Ledger.count(l,"free","men")+Ledger.count(l,"bound","men")+Ledger.count(l,"worker","men")
	var hands:=free_hands(force)
	var n:=mini(roundi(float(men)*0.3),mini(hands*CONSCRIPTS_PER_GUARD,40))
	if int(opts.get("count",0))>0: n=mini(int(opts.count),mini(hands*CONSCRIPTS_PER_GUARD,60))
	n=mini(n,Ledger.count(l,from,"men"))
	if n<=0:
		(c.refused as Array).append("I have nobody to spare to watch new men; every one of ours is on the gate or guarding." if men>0 else "There are no young men left in %s to take." % name); return
	n=Ledger.move(l,from,"conscript","men",n)
	var guards:=maxi(1,ceili(float(n)/float(CONSCRIPTS_PER_GUARD)))
	if not running.is_empty(): running["ended"]=true; running["end_day"]=int(c.day); running["end_reason"]="again"
	_start(c,"conscript",{"guards":guards,"deserted":0,"carry":0.0})
	c.results["conscripts"]=n
	c["resist_mul"]=float(c.resist_mul)*0.85
	_gov(c,{"grievance":0.07*_resent(c),"trust":-0.04*_resent(c)})
	c["harsh"]=float(c.harsh)+0.8
	c["weight"]=int(c.weight)+n
	var t:="We took %s of the young men of %s%s to serve with the garrison. They carry, dig and stand watch beside ours with spears we give them. I would not trust them in a fight yet, and some will run off when they can." % [_count(n),name,{"bound":" from among the bound men","worker":" from the work gangs"}.get(from,"")]
	if bool(opts.get("families",false)): t+=" Their families know what running would cost them."
	(c.texts as Array).append(t)
	(c.notes as Array).append("%s young men of %s were taken to serve with the garrison." % [_cap(_count(n)),name])
	(c.titles as Array).append("The Young Men of %s Taken" % name)

static func _execute(c:Dictionary)->void:
	var force:Dictionary=c.force
	var l:Dictionary=c.ledger
	var name:=String(c.name)
	var opts:Dictionary=c.opts
	var men:=Ledger.here(l,"men")
	var n:=clampi(int(opts.count),1,10) if int(opts.get("count",0))>0 else clampi(roundi(float(men)*0.05),1,6)
	n=mini(n,men)
	if n<=0:
		(c.refused as Array).append("There are no men left in %s to put to death." % name); return
	# The men who led them are among those we hold, if we hold any.
	var dead:=_kill(c,[["bound","men"],["worker","men"],["conscript","men"],["hostage","men"],["free","men"]],n)
	if dead<=0:
		(c.refused as Array).append("The men who led them are not to be found in %s." % name); return
	var old:=_running(force,"execute_ringleaders")
	if not old.is_empty(): old["ended"]=true; old["end_day"]=int(c.day); old["end_reason"]="again"
	_start(c,"execute_ringleaders",{"dead":dead,"guards":0})
	c.results["executed"]=dead
	c["resist_add"]=float(c.resist_add)-0.15
	_gov(c,{"grievance":0.18*_resent(c),"trust":-0.12*_resent(c),"legitimacy":-0.05})
	c["harsh"]=float(c.harsh)+1.8
	c["weight"]=int(c.weight)+dead*4
	var who:="the man who led the fighting" if dead==1 else "the %s men who led the fighting" % _count(dead)
	(c.texts as Array).append("At first light we put to death %s in %s, in front of the whole town. Nobody spoke. They will obey for now, and they will not forgive it." % [who,name])
	(c.notes as Array).append(("%s men who led the fighting in %s were put to death." % [_cap(_count(dead)),name]) if dead>1 else ("The man who led the fighting in %s was put to death." % name))
	(c.titles as Array).append("The Ringleaders of %s Put to Death" % name)

static func _release(c:Dictionary)->void:
	var force:Dictionary=c.force
	var l:Dictionary=c.ledger
	var name:=String(c.name)
	var what:Array=(c.opts as Dictionary).get("release",[])
	if what.is_empty(): what=PEOPLE_HELD.duplicate()
	var said:PackedStringArray=PackedStringArray()
	var let_go:=0
	# Whom the words untie: "let the women go" frees the women and the bound
	# men stay bound. Words that name nobody free all we bind.
	var who:=String((c.opts as Dictionary).get("release_who","people"))
	var loosed:=_who_groups(who)
	var bind_ended:=false
	for id in what:
		var m:=_running(force,String(id))
		var status:=String({"bind_men":"bound","hostages":"hostage","labour":"worker","conscript":"conscript"}.get(String(id),""))
		var groups:Array=loosed if String(id)=="bind_men" else Ledger.GROUPS
		var held:=0
		if status!="":
			for g in groups: held+=Ledger.count(l,status,String(g))
		if String(id)=="bind_men" and held<=0 and Ledger.count(l,status)>0:
			said.append("None of the %s of %s are bound; those we hold stay bound." % [_who_words(who),name])
			continue
		if m.is_empty() and held<=0: continue
		var n:=0
		if status!="":
			for g in groups: n+=Ledger.move(l,status,"free",String(g),Ledger.count(l,status,String(g)))
		# A binding ends only when nobody is left bound under it.
		var still:=Ledger.count(l,status) if status!="" else 0
		if not m.is_empty() and (String(id)!="bind_men" or still<=0):
			m["ended"]=true; m["end_day"]=int(c.day); m["end_reason"]="released"
		if String(id)=="bind_men": bind_ended=still<=0
		(c.freed as Array).append(String(id))
		let_go+=n
		match String(id):
			"bind_men":
				var whom:=_who_words(who) if who!="people" else "people"
				var rest:=(" The other %s stay bound." % _count(still)) if still>0 else ""
				said.append((("The %s bound %s of %s are untied and sent back to their houses." % [_count(n),whom,name]) if n>0 else ("The %s of %s are untied and sent back to their houses." % [whom,name]))+rest)
				c["resist_add"]=float(c.resist_add)+0.08
				_gov(c,{"grievance":-0.03,"trust":0.03})
				c["mercy"]=float(c.mercy)+0.4
			"hostages":
				said.append(("The %s hostages go back to their families." % _count(n)) if n>0 else "The hostages go back to their families.")
				_gov(c,{"grievance":-0.04,"trust":0.05})
				c["mercy"]=float(c.mercy)+0.3
			"labour":
				said.append(("The work gangs are sent home, %s %s." % [_count(n),_who_words(String(m.get("who","men")))]) if n>0 else "The work gangs are sent home.")
				_gov(c,{"welfare":0.02})
				c["mercy"]=float(c.mercy)+0.2
			"curfew":
				said.append("The curfew is lifted; they may go out after dark again.")
				c["mercy"]=float(c.mercy)+0.1
			"conscript":
				said.append(("The %s men we took into the garrison are sent back to their families." % _count(n)) if n>0 else "The men we took into the garrison are sent back to their families.")
				c["mercy"]=float(c.mercy)+0.2
	# Workers taken from the bound are bound no more once the binding ends.
	if bind_ended and (c.freed as Array).has("bind_men") and not (c.freed as Array).has("labour"):
		var lab:=_running(force,"labour")
		if not lab.is_empty() and String(lab.get("from",""))=="bound":
			lab["ended"]=true; lab["end_day"]=int(c.day); lab["end_reason"]="released"
			for g in Ledger.GROUPS: let_go+=Ledger.move(l,"worker","free",String(g),Ledger.count(l,"worker",String(g)))
	l["released"]=int(l.get("released",0))+let_go
	c.results["released"]=let_go
	if said.is_empty():
		(c.texts as Array).append("Nobody in %s is bound or held by us; there is no one to free." % name)
		return
	(c.texts as Array).append(" ".join(said))
	(c.notes as Array).append(("%s people held in %s were let go." % [_cap(_count(let_go)),name]) if let_go>0 else ("The people held in %s were let go." % name))
	(c.titles as Array).append("The %s of %s Freed" % [_cap(_who_words(who)) if who!="people" else "People",name])

static func _relief(c:Dictionary)->void:
	var force:Dictionary=c.force
	var name:=String(c.name)
	var running:=_running(force,"relief")
	if not running.is_empty():
		_renew(c,running)
		(c.texts as Array).append("They are fed and protected already. I will see it goes on.")
		return
	var gift:=minf(minf(Hall.player_stock("Food")*0.03,float(c.population)*0.5*7.0),400.0)
	var given:=0.0
	if gift>=5.0:
		given=_take_our_food(gift)
		_give_town_food(String(c.civ_id),given)
	_start(c,"relief",{"food":roundi(given),"guards":0})
	c.results["food_given"]=roundi(given)
	c["resist_add"]=float(c.resist_add)-0.06
	_gov(c,{"welfare":0.08,"trust":0.08,"grievance":-0.06})
	c["mercy"]=float(c.mercy)+1.0
	var reward:=_has(String((c.opts as Dictionary).get("words","")),"\\breward")
	var t:=("We opened our own stores to %s: %d Food shared out among the houses. " % [name,roundi(given)]) if given>=1.0 else "Our own stores are too low to feed them. "
	t+="My men are told to keep their hands off their people and their goods, and any who takes from them answers to me."
	if reward: t+=" Those who help us get a bigger share."
	(c.texts as Array).append(t)
	(c.notes as Array).append("The people of %s were fed from our stores and protected." % name if given>=1.0 else "The people of %s were put under our protection." % name)
	(c.titles as Array).append("%s Fed From Our Stores" % name if given>=1.0 else "%s Under Our Protection" % name)

## Someone of ours by name: an official, else anyone of our people.
static func person_named(who:String)->Dictionary:
	var key:=who.strip_edges().to_lower()
	if key=="": return {}
	for person in Hall._officials():
		var full:=String(person.get("name","")).to_lower()
		if full==key or full.get_slice(" ",0)==key: return {"name":String(person.name),"person_id":int(person.person_id)}
	for person in GovernmentPeopleSystem.people:
		if String(person.get("status","active"))!="active": continue
		var full:=String(person.get("name","")).to_lower()
		if full==key or full.get_slice(" ",0)==key: return {"name":String(person.name),"person_id":int(person.person_id)}
	return {}

static func _headman(c:Dictionary)->void:
	var force:Dictionary=c.force
	var name:=String(c.name)
	var asked:=String((c.opts as Dictionary).get("headman",""))
	var person:=person_named(asked)
	var unknown:=""
	if asked!="" and person.is_empty(): unknown="I know no %s among ours, so " % asked
	var commander:Dictionary=force.get("commander",{}) if force.get("commander") is Dictionary else {}
	var ours_there:=false
	if person.is_empty():
		var cname:=String(commander.get("name",""))
		if cname!="": person={"name":cname,"person_id":int(commander.get("person_id",0))}; ours_there=true
		else:
			var leader:Dictionary=c.general
			person={"name":String(leader.get("name","one of my captains")),"person_id":int(leader.get("person_id",0))}
			ours_there=true
	var pname:=String(person.name)
	var old:=_running(force,"set_headman")
	if not old.is_empty():
		if String(old.get("headman",""))==pname:
			_renew(c,old)
			(c.texts as Array).append("%s already sits over %s as headman in your name." % [pname,name])
			return
		old["ended"]=true; old["end_day"]=int(c.day); old["end_reason"]="replaced"
	_start(c,"set_headman",{"headman":pname,"person_id":int(person.get("person_id",0)),"guards":0})
	c.results["headman"]=pname
	c["resist_add"]=float(c.resist_add)-0.04
	_gov(c,{"local_institutions":-0.10,"grievance":0.05*_resent(c),"trust":-0.02,"repression":0.03})
	c["harsh"]=float(c.harsh)+0.3
	var pid:=int(person.get("person_id",0))
	if pid>0:
		GovernmentPeopleSystem.record_person_memory(pid,"The god set me over %s as headman." % name,"divine",0.75,{"emotion":"duty","outcome":"set_over_town"})
		GovernmentPeopleSystem.adjust_person_bonds(pid,{"obligation":0.04,"respect":0.02})
	var given:=pname.get_slice(" ",0)
	var t:=""
	if ours_there and unknown!="": t="%s%s, who leads the garrison there, sits over them as headman in your name." % [unknown,given]
	elif ours_there: t="%s, who leads the garrison there, sits over %s as headman in your name." % [given,name]
	else: t="%s goes to %s to sit over them as headman in your name." % [given,name]
	t+=" Their elders keep their houses but lose their say; they answer to %s now." % given
	(c.texts as Array).append(_cap(t))
	(c.notes as Array).append("%s was set over %s as headman." % [given,name])
	(c.titles as Array).append("A Headman of Ours Over %s" % name)

static func _settle(c:Dictionary)->void:
	var force:Dictionary=c.force
	var name:=String(c.name)
	var running:=_running(force,"settle")
	if not running.is_empty():
		_renew(c,running)
		(c.texts as Array).append("%s of our families already live in %s." % [_cap(_count(int(running.count))),name])
		return
	var ours:=int(WorldSimulation.state.population_total) if WorldSimulation.state!=null else 0
	if ours<80:
		(c.refused as Array).append("We are too few at home to spare families for %s." % name); return
	var n:=int((c.opts as Dictionary).count) if int((c.opts as Dictionary).get("count",0))>0 else clampi(roundi(float(ours)*0.02),5,40)
	n=clampi(n,1,60)
	_start(c,"settle",{"count":n,"guards":0})
	c.results["settlers"]=n
	c["integration_add"]=float(c.integration_add)+0.05
	c["resist_add"]=float(c.resist_add)-0.04
	_gov(c,{"grievance":0.05*_resent(c),"trust":-0.03})
	c["harsh"]=float(c.harsh)+0.4
	(c.texts as Array).append("%s of our families will go to %s and take up the empty houses and the land of the men who are gone, under the garrison's protection. They stay our people; the houses there will be theirs." % [_cap(_count(n)),name])
	(c.notes as Array).append("%s of our families went to live in %s." % [_cap(_count(n)),name])
	(c.titles as Array).append("Our Families Settle in %s" % name)

## A standing word to the garrison: a conditional order ("if any run, kill
## them"), or the war leader's nearest reading of words that name no measure.
static func _word(c:Dictionary)->void:
	var force:Dictionary=c.force
	var name:=String(c.name)
	var opts:Dictionary=c.opts
	var stance:=String(c.stance)
	var tone:=String(opts.get("tone",""))
	if tone=="": tone={"harsh":"harsh","brutal":"brutal","lenient":"lenient"}.get(stance,"neutral") if bool(opts.get("stance_set",false)) else "neutral"
	var conditional:=String(opts.get("clause",""))!=""
	var running:=_running(force,WORD)
	if not running.is_empty():
		if String(running.get("tone",""))==tone:
			_renew(c,running)
			(c.texts as Array).append("The garrison already has that word from you. I have reminded them of it, and it holds another month.")
			return
		running["ended"]=true; running["end_day"]=int(c.day); running["end_reason"]="replaced"
	_start(c,WORD,{"tone":tone,"guards":0,"conditional":conditional})
	var t:=""
	var families:=bool(opts.get("families",false))
	if conditional:
		match tone:
			"brutal": t="The garrison has your word: any man of %s who fights us or runs is killed. I have had it said at every door." % name
			"harsh": t=("The garrison has your word: if any man of %s fights us or runs, his wife and children answer for it. I have had it said at every door." % name) if families else ("The garrison has your word: any man of %s who fights us or runs is beaten in front of the rest. I have had it said at every door." % name)
			"lenient": t="The garrison has your word: nobody in %s is to be hurt, even if they run." % name
			_: t="The garrison has your word: any man of %s who fights us or runs is caught and bound." % name
	else:
		match tone:
			"brutal": t="I take it you want them crushed. From today my men carry their spears in the lanes of %s, and any man who raises a hand to us is killed." % name
			"harsh": t="I take it you want a harder hand in %s. From today my men carry their spears in the lanes, any man who talks back is beaten, and nobody gathers after dark." % name
			"lenient": t="I take it you want them treated gently. My men will keep their hands off the houses and goods of %s, and we will take nothing we do not need." % name
			_: t="I will keep %s as you say: the garrison keeps order, and nobody who does not raise a hand to us is harmed. I will tell you if anything changes there." % name
	match tone:
		"brutal":
			c["resist_add"]=float(c.resist_add)-0.07
			_gov(c,{"grievance":0.08,"trust":-0.05,"repression":0.06})
			c["harsh"]=float(c.harsh)+1.0
		"harsh":
			c["resist_add"]=float(c.resist_add)-0.05
			_gov(c,{"grievance":0.05*_resent(c),"trust":-0.03,"repression":0.04})
			c["harsh"]=float(c.harsh)+0.6
		"lenient":
			c["resist_add"]=float(c.resist_add)-0.03
			_gov(c,{"grievance":-0.04,"trust":0.04})
			c["mercy"]=float(c.mercy)+0.6
		_:
			c["resist_add"]=float(c.resist_add)-0.01
			_gov(c,{"trust":0.01})
	(c.texts as Array).append(t)
	(c.notes as Array).append("The garrison of %s was given a %s word." % [name,{"brutal":"killing","harsh":"hard","lenient":"gentle"}.get(tone,"plain")])
	(c.titles as Array).append("The God's Word to the Garrison of %s" % name)

## The stance said once, after the deeds.
static func _stance_line(c:Dictionary,order:Array)->String:
	var opts:Dictionary=c.opts
	if not bool(opts.get("stance_set",false)) or order.has(WORD): return ""
	# Only the same orders again: the town was told already.
	if (c.applied as Array).is_empty() and not (c.renewed as Array).is_empty():
		match String(c.stance):
			"harsh": return "The town knows already that their families answer for any who run." if bool(opts.get("families",false)) else "The town knows already what running costs."
			"brutal": return "The town knows already that any man who fights us is killed."
		return ""
	match String(c.stance):
		"harsh":
			if bool(opts.get("families",false)): return "I told the town that if any man fights us or runs, his wife and children will answer for it."
			return "Any man who fights us or runs will be beaten in front of the rest; the town has been told."
		"brutal": return "I told them that any man who fights us or runs will be killed."
		"lenient": return "My men are to hurt nobody."
	return ""

# --- Effects ------------------------------------------------------------------

## The town's resistance and governance, moved once for the whole order.
static func _region_effects(c:Dictionary)->void:
	var world:Variant=_world()
	var civ_id:=String(c.civ_id); var region_id:=String(c.region_id)
	var index:int=world._civilization_index(civ_id)
	if index<0: return
	var civ:Dictionary=world.civilizations[index]
	var ri:int=world._region_index(civ,region_id)
	if ri<0: return
	var r:Dictionary=civ.strategic_regions[ri]
	var data:Dictionary=Governance.state(r)
	var gov:Dictionary=c.gov
	for key in gov:
		if data.has(key): data[key]=clampf(float(data[key])+float(gov[key]),0.0,1.0)
	var resistance:=clampf(float(r.get("resistance",0.5))*float(c.resist_mul)+float(c.resist_add),0.01,1.0)
	resistance=minf(resistance,cap_of(c.force as Dictionary))
	r["resistance"]=resistance
	if float(c.integration_add)!=0.0: r["integration"]=clampf(float(r.get("integration",0.0))+float(c.integration_add),0.0,1.0)
	r["governance"]=data
	civ.strategic_regions[ri]=r
	world.civilizations[index]=civ
	if WorldSimulation.enabled: Combat.governance(civ_id,region_id,r)

## The lowest resistance cap of the measures running on a garrison.
static func cap_of(force:Dictionary)->float:
	var cap:=1.0
	for m in force.get("measures",[]):
		if m is Dictionary and not bool((m as Dictionary).get("ended",false)):
			cap=minf(cap,float((CATALOGUE.get(String(m.get("id","")),{}) as Dictionary).get("cap",1.0)))
	return cap

## Dread, grudges, reputation, the court's fear or love; bounded.
static func _consequences(c:Dictionary)->void:
	var mc:Variant=_mc()
	var civ_id:=String(c.civ_id)
	var S:Dictionary=c.S
	var harsh:=float(c.harsh)
	var mercy:=float(c.mercy)
	var weight:=clampf(float(c.weight)/80.0,0.0,1.0)
	var name:=String(c.name)
	if harsh>0.0:
		var feared:=harsh*float(S.dread)
		var hated:=harsh*float(S.resent)
		Hall._shift_relation(civ_id,-clampf(0.03*hated+0.03*weight,0.01,0.25),clampf(0.02*harsh,0.0,0.12))
		DIVINE.add_civ_dread(civ_id,clampf(0.025*feared+0.04*weight,0.005,0.2))
		mc._adjust_war_reputation(0.0,clampf(0.015*feared,0.0,0.12),clampf(0.012*hated,0.0,0.1))
		if hated>=1.2:
			var what:="what the god's garrison did to the people of %s" % name
			preload("res://scripts/rival_rulers.gd").grudge(civ_id,what,clampf(0.3+0.2*harsh,0.3,1.2),"measures:%s:%d" % [String(c.region_id),int(c.day)])
			ForeignDiplomacy.remember(civ_id,"The god's garrison in %s: %s" % [name,_lower_first(" ".join(PackedStringArray(c.notes)))])
		if feared>=1.5:
			for person:Dictionary in Hall._officials():
				var pid:=int(person.get("person_id",0))
				if pid>0: GovernmentPeopleSystem.adjust_person_bonds(pid,{"fear":clampf(0.006*feared,0.004,0.03),"hold_days":30})
		var metrics:Dictionary=WorldSimulation.state.simulation_metrics
		if int(c.killed)>0 or String(c.stance)=="brutal":
			metrics["cohesion"]=clampf(float(metrics.get("cohesion",0.5))-clampf(0.002+0.001*float(c.killed),0.0,0.01),0.0,1.0)
	if mercy>0.0:
		Hall._shift_relation(civ_id,clampf(0.03*mercy,0.0,0.1),-clampf(0.02*mercy,0.0,0.06))
		mc._adjust_war_reputation(clampf(0.03*mercy,0.0,0.08),0.0,-clampf(0.015*mercy,0.0,0.05))
		if mercy>=0.9:
			for person:Dictionary in Hall._officials():
				var pid:=int(person.get("person_id",0))
				if pid>0: GovernmentPeopleSystem.adjust_person_bonds(pid,{"love":clampf(0.005*mercy,0.0,0.02)})

static func _chronicle(c:Dictionary)->void:
	var applied:Array=c.applied
	if applied.is_empty() or (c.titles as Array).is_empty(): return
	var key:="measures:%s:%d:%s" % [String(c.region_id),int(c.day),"+".join(PackedStringArray(applied))]
	Chronicle.record({"key":key,"title":String((c.titles as Array)[0]).substr(0,70),"text":" ".join(PackedStringArray(c.notes)),
		"tier":"moment" if applied.has("execute_ringleaders") else "notice","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":String(c.civ_id)}}})

## One plain note: "Tsaren: 58 men bound and under guard, 14 got away."
static func _outcome(c:Dictionary)->String:
	var bits:PackedStringArray=PackedStringArray()
	var r:Dictionary=c.results
	var who:=_who_words(String((c.opts as Dictionary).get("who","men")))
	for id in (c.applied as Array)+(c.renewed as Array):
		match String(id):
			"bind_men": bits.append("%s %s bound and under guard" % [_count(int(r.get("bound",0))),who])
			"disarm": bits.append("%s weapons taken" % _count(int(r.get("weapons",0))))
			"hostages": bits.append("%s hostages held" % _count(int(r.get("hostages",0))))
			"curfew": bits.append("kept to their houses after dark")
			"search": bits.append("every house searched")
			"labour": bits.append("%s %s at forced labour" % [_count(int(r.get("workers",0))),_who_words(String(r.get("work_who","men")))])
			"requisition": bits.append("%d Food taken from their stores" % int(r.get("food",0)))
			"conscript": bits.append("%s of their men serving with ours" % _count(int(r.get("conscripts",0))))
			"execute_ringleaders": bits.append("%s ringleaders put to death" % _count(int(r.get("executed",0))))
			"relief": bits.append("fed and protected")
			"set_headman": bits.append("%s set over them" % String(r.get("headman","one of ours")).get_slice(" ",0))
			"settle": bits.append("%s of our families settling there" % _count(int(r.get("settlers",0))))
			WORD: bits.append("the garrison has your word")
	if not (c.freed as Array).is_empty(): bits.append(("%s let go" % _count(int(r.get("released",0)))) if int(r.get("released",0))>0 else "those held let go")
	if int(c.fled)>0: bits.append("%s got away" % _count(int(c.fled)))
	if bits.is_empty(): return "%s: nothing is changed." % String(c.name)
	var unique:PackedStringArray=PackedStringArray()
	for b in bits:
		if not unique.has(b): unique.append(b)
	return "%s: %s." % [String(c.name),", ".join(unique)]


# --------------------------------------------------------------------------
# The map card and the held-town report
# --------------------------------------------------------------------------

## The line a measure puts on the garrison's map card; the people it holds are
## read from the town's ledger.
static func card_label(m:Dictionary,l:Dictionary={},force:Dictionary={})->String:
	var n:=int(m.get("count",0))
	match String(m.get("id","")):
		"bind_men":
			var bound:=Ledger.count(l,"bound")+bound_workers(force,l) if not l.is_empty() else n
			var men_only:=l.is_empty() or Ledger.count(l,"bound")==Ledger.count(l,"bound","men")
			return "%s · %d" % ["Men bound and under guard" if men_only else "People bound and under guard",bound]
		"hostages": return "Hostages held · %d" % (Ledger.count(l,"hostage") if not l.is_empty() else n)
		"labour": return "%s at forced labour · %d" % [_cap(_who_words(String(m.get("who","men")))),(Ledger.count(l,"worker") if not l.is_empty() else n)]
		"conscript": return "Their men serving with ours · %d" % (Ledger.count(l,"conscript") if not l.is_empty() else n)
		"execute_ringleaders": return "Ringleaders put to death · %d" % int(m.get("dead",n))
		"curfew": return "Kept to their houses"
		"disarm": return "Disarmed · %d weapons taken" % n
		"requisition": return "Stores taken · %d Food" % int(m.get("food",0))
		"set_headman": return "%s set over them" % String(m.get("headman","One of ours")).get_slice(" ",0)
		"settle": return "Our settlers there · %d families" % n
		"relief": return "Fed and protected"
		"search": return "Houses searched"
		WORD: return {"brutal":"Your word: kill any who fight","harsh":"Your word: a hard hand","lenient":"Your word: a light hand"}.get(String(m.get("tone","")),"Your word to the garrison")
	return String((CATALOGUE.get(String(m.get("id","")),{}) as Dictionary).get("label",""))

## Bound men put to forced labour (labour taken from the bound): still bound.
static func bound_workers(force:Dictionary,l:Dictionary)->int:
	var lab:=_running(force,"labour")
	if lab.is_empty() or String(lab.get("from",""))!="bound" or l.is_empty(): return 0
	return Ledger.count(l,"worker")

## The card lines of every measure running on a town's garrison.
static func card_labels(civ_id:String,region_id:String)->Array[String]:
	var out:Array[String]=[]
	var at:=_force_index(civ_id,region_id)
	if at<0: return out
	var force:Dictionary=_mc().occupation_forces[at]
	var l:=Ledger.of(civ_id,region_id,false)
	for m:Dictionary in active(civ_id,region_id): out.append(card_label(m,l,force))
	return out

## The town's ledger for a garrison record ({} when it has none).
static func ledger_of(force:Dictionary)->Dictionary:
	return Ledger.of(String(force.get("civ_id","")),String(force.get("region_id","")),false)

## The garrison's card note follows what is in force; when nothing is, the
## last order's note (town_fate) comes back.
static func refresh_note(force:Dictionary)->void:
	var list:Array[Dictionary]=[]
	for m in force.get("measures",[]):
		if m is Dictionary and not bool((m as Dictionary).get("ended",false)): list.append(m)
	if list.is_empty():
		if bool(force.get("measure_note",false)):
			force["fate_note"]=String(force.get("note_before",""))
			force.erase("measure_note"); force.erase("note_before")
		return
	list.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return _priority(String(a.id))<_priority(String(b.id)))
	if not bool(force.get("measure_note",false)): force["note_before"]=String(force.get("fate_note",""))
	force["measure_note"]=true
	var note:=card_label(list[0],ledger_of(force),force)
	if list.size()>1: note+=" · %d more" % (list.size()-1)
	force["fate_note"]=note.substr(0,70)

## The report's lines for what is in force: [{id, label, value, text}].
static func report_lines(civ_id:String,region_id:String)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var day:=_day()
	var l:=Ledger.of(civ_id,region_id,false)
	var at:=_force_index(civ_id,region_id)
	var force:Dictionary=_mc().occupation_forces[at] if at>=0 else {}
	for m:Dictionary in active(civ_id,region_id):
		var n:=int(m.get("count",0))
		var left:=maxi(0,int(m.get("until",day))-day)
		var holds:=" The order holds %s more." % _days(left) if left>0 and left<200 else ""
		var text:=""; var value:=""
		match String(m.id):
			"bind_men":
				var working:=bound_workers(force,l)
				var bound:=Ledger.count(l,"bound")+working
				var men:=Ledger.count(l,"bound","men")+working
				value=str(bound)
				text="%s %s bound and kept under guard%s; %s of ours watch them.%s" % [_cap(_count(bound)),("men are" if bound!=1 else "man is") if men==bound else "people are (%d of them men)" % men,(", %s of them at forced labour" % _count(working)) if working>0 else "",_count(int(m.get("guards",0))),holds]
			"hostages":
				n=Ledger.count(l,"hostage")
				value=str(n); text="%s of their people are held in the garrison's house as hostages.%s" % [_cap(_count(n)),holds]
			"labour":
				n=Ledger.count(l,"worker")
				value=str(n)
				text="%s %s work %s under our guard.%s" % [_cap(_count(n)),_who_words(String(m.get("who","men"))),{"walls":"on a wall round the town","fields":"their fields for us","roads":"on a track toward "+_home()}.get(String(m.get("work","")),"wherever the garrison needs them"),holds]
			"conscript":
				n=Ledger.count(l,"conscript")
				value=str(n); text="%s of their young men serve with the garrison%s.%s" % [_cap(_count(n)),"; %s have run off" % _count(int(m.get("deserted",0))) if int(m.get("deserted",0))>0 else "",holds]
			"execute_ringleaders":
				n=int(m.get("dead",n))
				value=str(n); text="%s who led the fighting %s put to death %s ago." % [_cap(_count(n))+" men" if n>1 else "The man","were" if n>1 else "was",_days(maxi(1,day-int(m.day)))]
			"curfew":
				text="Nobody goes out after dark.%s" % holds
			"disarm":
				value=str(n); text="We took %s weapons from their houses%s." % [_count(n),"; they were burned" if bool(m.get("destroyed",false)) else ""]
			"requisition":
				value="%d Food" % int(m.get("food",0)); text="We took %d Food from their stores %s ago." % [int(m.get("food",0)),_days(maxi(1,day-int(m.day)))]
			"set_headman":
				value=String(m.get("headman","")).get_slice(" ",0); text="%s sits over them as headman in your name." % value
			"settle":
				value=str(n); text="%s of our families live there now." % _cap(_count(n))
			"relief":
				text="We gave them %d Food; our men are told to keep their hands off them." % int(m.get("food",0)) if int(m.get("food",0))>0 else "Our men are told to keep their hands off them."
			"search":
				text="Every house was searched %s ago." % _days(maxi(1,day-int(m.day)))
			WORD:
				text={"brutal":"Your word to the garrison: any man who fights or runs is killed.","harsh":"Your word to the garrison: a hard hand.","lenient":"Your word to the garrison: a light hand."}.get(String(m.get("tone","")),"The garrison keeps order as you said.")
		out.append({"id":String(m.id),"label":card_label(m,l,force).get_slice(" · ",0),"value":value,"text":text})
	return out


# --------------------------------------------------------------------------
# Day by day
# --------------------------------------------------------------------------

## Called each day (court_war_orders.daily). Returns the report matters filed.
static func daily(day:int)->Array:
	var filed:Array=[]
	var mc:Variant=_mc(); var world:Variant=_world()
	if mc==null or world==null: return filed
	for i in mc.occupation_forces.size():
		var force:Dictionary=mc.occupation_forces[i]
		var list:Variant=force.get("measures")
		if not list is Array or (list as Array).is_empty(): continue
		var civ_id:=String(force.get("civ_id","")); var region_id:=String(force.get("region_id",""))
		var region:Dictionary=world.region_snapshot(civ_id,region_id)
		# Not held (the one reading): nothing the garrison ordered runs there,
		# and those it held go free (town_ledger.settle).
		if region.is_empty() or not Ledger.holds(civ_id,region_id):
			force.erase("measures"); continue
		var cap:=1.0
		var hungry:=0.0
		for m in list:
			if not m is Dictionary or bool((m as Dictionary).get("ended",false)): continue
			var rec:Dictionary=m
			var last:=int(rec.get("last_day",day))
			if day>last:
				for step in range(last+1,day+1):
					hungry+=_tick(rec,force,civ_id,region_id,step,filed)
					if bool(rec.get("ended",false)): break
				rec["last_day"]=day
			if not bool(rec.get("ended",false)): cap=minf(cap,float((CATALOGUE.get(String(rec.id),{}) as Dictionary).get("cap",1.0)))
		var l:=Ledger.of(civ_id,region_id,false)
		if not l.is_empty(): _end_empty(force,l,day)
		_daily_region(civ_id,region_id,cap,hungry)
		_trim(force)
		refresh_note(force)
	return filed

## One day of one measure. Returns the food the town could not find for
## those we hold (the hunger is theirs, and their grievance).
static func _tick(m:Dictionary,force:Dictionary,civ_id:String,region_id:String,day:int,filed:Array)->float:
	var id:=String(m.id)
	var short:=0.0
	var l:=Ledger.of(civ_id,region_id)
	match id:
		"bind_men":
			var need:=float(Ledger.count(l,"bound"))*BOUND_RATION
			var got:=_take_town_food(civ_id,region_id,need)
			if got<need: got+=_take_our_food(need-got)
			short=maxf(0.0,need-got)
		"hostages":
			var need:=float(Ledger.count(l,"hostage"))*HOSTAGE_RATION
			var got:=_take_our_food(need)
			if got<need: got+=_take_town_food(civ_id,region_id,need-got)
			short=maxf(0.0,need-got)
		"labour":
			var workers:=Ledger.count(l,"worker")
			match String(m.get("work","")):
				"walls":
					var rise:=minf(WALL_PER_DAY*float(workers)/40.0,maxf(0.0,WALL_MAX-float(m.get("done",0.0))))
					if rise>0.0:
						m["done"]=float(m.get("done",0.0))+rise
						_edit_region(civ_id,region_id,func(r:Dictionary)->void: r["fortification"]=clampf(float(r.get("fortification",0.0))+rise,0.0,1.0))
				"fields":
					var want:=minf(float(workers)*FIELD_FOOD_PER_WORKER,maxf(0.0,FIELD_FOOD_MAX-float(m.get("done",0.0))))
					var got:=_take_town_food(civ_id,region_id,want)
					if got>0.0: _receive_our_food(got); m["done"]=float(m.get("done",0.0))+got
		"conscript":
			var n:=Ledger.count(l,"conscript")
			var rate:=float((STANCES.get(String(m.get("stance","firm")),STANCES.firm) as Dictionary).desert)
			m["carry"]=float(m.get("carry",0.0))+float(n)*rate
			var gone:=mini(n,floori(float(m.carry)))
			if gone>0:
				m["carry"]=float(m.carry)-float(gone)
				m["deserted"]=int(m.get("deserted",0))+gone
				_leave(civ_id,region_id,"conscript","men",gone)
				if Ledger.count(l,"conscript")<=0: m["ended"]=true; m["end_day"]=day; m["end_reason"]="deserted"
	var incident:Variant=m.get("incident")
	if incident is Dictionary and not bool((incident as Dictionary).get("done",false)) and day>=int((incident as Dictionary).get("day",day+1)) and not bool(m.get("ended",false)):
		(incident as Dictionary)["done"]=true
		var matter:=_incident(m,force,civ_id,region_id,day)
		if not matter.is_empty(): filed.append(matter)
	if not bool(m.get("ended",false)) and day>=int(m.get("until",day+1)):
		m["ended"]=true; m["end_day"]=day; m["end_reason"]="done"
		var matter:=_ended(m,force,civ_id,region_id,day)
		if not matter.is_empty(): filed.append(matter)
	return short

## n of a status slip off to their people for good: the ledger first, then
## the world moves them to their refuge.
static func _leave(civ_id:String,region_id:String,status:String,group:String,n:int,refuge:Dictionary={})->int:
	var l:=Ledger.of(civ_id,region_id)
	var to:=refuge if not refuge.is_empty() else Pursuit.refuge(civ_id,region_id)
	var went:=Ledger.fled_now(l,status,group,n,"the hills" if bool(to.get("hills",false)) else String(to.get("name","the hills")))
	if went>0: Pursuit._reach_refuge(civ_id,region_id,went,to,went if group=="men" else 0)
	return went

## Resistance held under the running measures' cap; hunger among those we
## hold is their people's grievance.
static func _daily_region(civ_id:String,region_id:String,cap:float,hungry:float)->void:
	if cap>=1.0 and hungry<=0.0: return
	var edit:=func(r:Dictionary)->void:
		if cap<1.0: r["resistance"]=minf(float(r.get("resistance",0.5)),cap)
		if hungry>0.0:
			var data:Dictionary=Governance.state(r)
			data.grievance=clampf(float(data.grievance)+0.002,0.0,1.0)
			data.welfare=clampf(float(data.welfare)-0.002,0.0,1.0)
			r["governance"]=data
	_edit_region(civ_id,region_id,edit)

static func _edit_region(civ_id:String,region_id:String,edit:Callable)->void:
	var world:Variant=_world()
	var index:int=world._civilization_index(civ_id)
	if index<0: return
	var civ:Dictionary=world.civilizations[index]
	var ri:int=world._region_index(civ,region_id)
	if ri<0: return
	var r:Dictionary=civ.strategic_regions[ri]
	edit.call(r)
	civ.strategic_regions[ri]=r
	world.civilizations[index]=civ
	if WorldSimulation.enabled: Combat.governance(civ_id,region_id,r)

## Something went wrong (or right) under a measure: told once by the war
## leader as a court matter, with one Chronicle line. Bound men never get
## away: a man who works his cords loose is caught at the edge of the fields.
static func _incident(m:Dictionary,force:Dictionary,civ_id:String,region_id:String,day:int)->Dictionary:
	var name:=String(force.get("region_name","the town"))
	var region:Dictionary=_world().region_snapshot(civ_id,region_id)
	if not region.is_empty(): name=String(region.get("name",name))
	var l:=Ledger.of(civ_id,region_id)
	var stance:=String(m.get("stance","firm"))
	var hard:=stance in ["harsh","brutal"]
	var text:=""
	var grievance:=0.0; var trust:=0.0; var resist:=0.0; var dread:=0.0
	match String(m.id):
		"bind_men":
			if Ledger.count(l,"bound")<=0: return {}
			if stance=="brutal":
				if _die(civ_id,region_id,[["bound","men"],["bound","women"],["bound","elders"]],1)<=0: return {}
				text="One of the bound men in %s got loose in the night and went for a guard with a stone. The guards killed him. The town has been silent since." % name
				grievance=0.06; dread=0.03
			elif stance=="harsh" and bool(m.get("families",false)):
				text="Two nights ago one of the bound men in %s worked his cords loose and ran. As you ordered, the guards dragged his wife and children into the open; he came back by morning and gave himself up. The whole town watched it." % name
				grievance=0.05; dread=0.02; resist=-0.02
			elif stance=="harsh":
				text="One of the bound men in %s tried to run and was caught at the edge of the fields. He was beaten in front of the rest." % name
				grievance=0.04; dread=0.015
			else:
				text="One of the bound men in %s worked his cords loose in the night. The guard on the fields caught him before he reached the trees, and he is bound again." % name
				grievance=0.01
		"hostages":
			if Ledger.count(l,"hostage")<=0: return {}
			if hard and _die(civ_id,region_id,[["hostage","elders"],["hostage","men"],["hostage","women"],["hostage","children"]],1)>0:
				text="One of the hostages from %s, an old man, sickened in the garrison's house and died. His family says we let him die." % name
				grievance=0.05
			else:
				text="The families of the hostages from %s come to the garrison's house each day with food. There has been no trouble." % name
				trust=0.02
		"labour":
			if Ledger.count(l,"worker")<=0: return {}
			if hard:
				text="A log slipped on the work gang at %s and broke a man's leg. They say we drive them too hard." % name
				grievance=0.04
			elif String(m.get("from",""))=="bound":
				text="One of the work gang at %s fell sick in the heat and was carried back to the others under guard. The rest work on." % name
				grievance=0.01
			else:
				var ran:=_leave(civ_id,region_id,"worker","men",2,{"name":"the hills","region_id":"","hills":true})
				if ran<=0: return {}
				text="%s of the work gang at %s slipped off into the hills in the night." % [_cap(_count(ran)),name]
				grievance=0.01
		"conscript":
			var n:=Ledger.count(l,"conscript")
			if n<=0: return {}
			var k:=_leave(civ_id,region_id,"conscript","men",mini(n,1+roundi(float(n)*0.15)))
			if k<=0: return {}
			m["deserted"]=int(m.get("deserted",0))+k
			text="%s of the men we took from %s ran off in the night, with the spears we gave them." % [_cap(_count(k)),name]
		"search":
			if hard and _die(civ_id,region_id,[["free","women"],["free","men"]],1)>0:
				text="During the search of %s a woman struck one of ours with a stick; he struck back, and she died of it. Her people want blood." % name
				grievance=0.06
			elif not _running(force,"bind_men").is_empty() and Ledger.move(l,"free","bound","men",1)>0:
				text="During the search of %s one of ours was cut by a man hiding in a roof. He will mend; the man is bound with the rest." % name
				grievance=0.01
			else:
				text="During the search of %s one of ours was cut by a man hiding in a roof. He will mend; we took the man's spear." % name
				grievance=0.01
		"curfew":
			text="Three boys of %s were caught out after dark and beaten by our watch. Their mothers came to the gate to scream at us." % name
			grievance=0.03
		"disarm":
			text="Some of the men of %s had hidden spears in their roofs. We found two and burned them." % name
			resist=-0.01
		"requisition":
			var got:=_take_town_food(civ_id,region_id,20.0)
			_receive_our_food(got)
			text="The people of %s were hiding food under their floors. We found some of it and took it." % name
			grievance=0.02
		"relief":
			text="Some of the old men of %s came to the garrison to thank us for the food." % name
			trust=0.03; grievance=-0.02
		WORD:
			match String(m.get("tone","")):
				"brutal":
					if _die(civ_id,region_id,[["free","men"]],1)<=0: return {}
					text="A man of %s raised his hand to one of ours in the lane. As you ordered, he was killed where he stood." % name
					grievance=0.05; dread=0.03
				"harsh":
					text="A man of %s spat at one of ours in the lane and was beaten for it, as you ordered." % name
					grievance=0.03; dread=0.01
				"lenient":
					text="One of ours took a goat from a house in %s. I had him flogged and the goat given back; they saw it." % name
					trust=0.03
				_:
					text="A quarrel over water between one of ours and a woman of %s. I settled it before it went further." % name
	if text=="": return {}
	var edit:=func(r:Dictionary)->void:
		var data:Dictionary=Governance.state(r)
		data.grievance=clampf(float(data.grievance)+grievance,0.0,1.0)
		data.trust=clampf(float(data.trust)+trust,0.0,1.0)
		r["governance"]=data
		r["resistance"]=clampf(float(r.get("resistance",0.5))+resist,0.01,1.0)
	_edit_region(civ_id,region_id,edit)
	if dread>0.0: DIVINE.add_civ_dread(civ_id,dread)
	if grievance>=0.04: Hall._shift_relation(civ_id,-grievance,grievance*0.5)
	m["incident_text"]=text
	return _report(civ_id,name,region_id,String(m.id),int(m.day),text,day,"incident")

## A measure that held people ran its days: the war leader says so once, and
## the people it held go back to their houses (the ledger says so too).
static func _ended(m:Dictionary,force:Dictionary,civ_id:String,region_id:String,day:int)->Dictionary:
	var name:=String(force.get("region_name","the town"))
	var region:Dictionary=_world().region_snapshot(civ_id,region_id)
	if not region.is_empty(): name=String(region.get("name",name))
	var l:=Ledger.of(civ_id,region_id)
	var text:=""
	match String(m.id):
		"bind_men":
			var n:=_send_home(l,"bound")
			var lab:=_running(force,"labour")
			if not lab.is_empty() and String(lab.get("from",""))=="bound":
				lab["ended"]=true; lab["end_day"]=day; lab["end_reason"]="released"
				n+=_send_home(l,"worker")
			_edit_region(civ_id,region_id,func(r:Dictionary)->void: r["resistance"]=clampf(float(r.get("resistance",0.5))+0.06,0.01,1.0))
			if n<=0: return {}
			text="The month is out. I have let the %s bound men of %s go back to their houses and fields; the harvest would not wait. Say the word and we bind them again." % [_count(n),name]
		"hostages":
			var n:=_send_home(l,"hostage")
			if n<=0: return {}
			text="We have kept the %s hostages from %s three months. I have sent them back to their families; say the word if you want others taken." % [_count(n),name]
		"labour":
			var bound_still:=String(m.get("from",""))=="bound" and not _running(force,"bind_men").is_empty()
			var n:=0
			if bound_still:
				for g in Ledger.GROUPS: n+=Ledger.move(l,"worker","bound",String(g),Ledger.count(l,"worker",String(g)))
			else: n=_send_home(l,"worker")
			var back:=(" They are back with the other bound %s." % _who_words(String(m.get("who","men")))) if bound_still else ""
			match String(m.get("work","")):
				"walls": text="The work gangs at %s are done. The town has a stake wall and a ditch round it now.%s" % [name,back]
				"fields": text="The work gangs at %s are done. Their fields gave %d Food to the garrison and to %s.%s" % [name,roundi(float(m.get("done",0.0))),_home(),back]
				"roads":
					var mc:Variant=_mc()
					var at:int=mc._occupation_force_index(civ_id,region_id)
					if at>=0: mc.occupation_forces[at]["supply_level"]=clampf(float(mc.occupation_forces[at].get("supply_level",0.5))+0.1,0.0,1.0)
					text="The work gangs at %s are done. A track is cleared from the town toward %s, and our carriers reach the garrison quicker.%s" % [name,_home(),back]
				_: text=("The work gangs at %s are done and sent home, %s men." % [name,_count(n)]) if not bound_still else "The work gangs at %s are done.%s" % [name,back]
		"conscript":
			var n:=_send_home(l,"conscript")
			text="The two months are up. Of the young men of %s who served with us, %s are still here; I have sent them home." % [name,_count(n)]
	if text=="": return {}
	return _report(civ_id,name,region_id,String(m.id),int(m.day),text,day,"ended")

## Everyone of a status goes back to their houses. Returns how many.
static func _send_home(l:Dictionary,status:String)->int:
	var n:=0
	for g in Ledger.GROUPS: n+=Ledger.move(l,status,"free",String(g),Ledger.count(l,status,String(g)))
	return n

static func _report(civ_id:String,town:String,region_id:String,id:String,started:int,text:String,day:int,kind:String)->Dictionary:
	var war_loop:GDScript=load(WAR_LOOP_PATH)
	var matter:Variant=war_loop.call("_file",civ_id,"report",text,day)
	var title:=("Trouble Under Our Garrison in %s" % town) if kind=="incident" else ("Word From the Garrison in %s" % town)
	Chronicle.record({"key":"measure_%s:%s:%s:%d" % [kind,region_id,id,started],"title":title.substr(0,70),"text":text,"tier":"notice","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":civ_id}}})
	return matter if matter is Dictionary and not (matter as Dictionary).is_empty() else {"text":text}

## Old records go; the list stays bounded.
static func _trim(force:Dictionary)->void:
	var list:Variant=force.get("measures")
	if not list is Array: return
	var day:=_day()
	var kept:Array=[]
	for m in list:
		if not m is Dictionary: continue
		if bool((m as Dictionary).get("ended",false)) and day-int((m as Dictionary).get("end_day",day))>KEEP_ENDED_DAYS: continue
		kept.append(m)
	# Ended ones go first; a running measure is never dropped (at most one
	# of each kind runs, so the list stays within the catalogue's size).
	while kept.size()>MAX_RECORDS:
		var at:=-1
		for i in kept.size():
			if bool((kept[i] as Dictionary).get("ended",false)): at=i; break
		if at<0: break
		kept.remove_at(at)
	force["measures"]=kept
