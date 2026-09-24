class_name InteractionText
extends RefCounted
## Offline text normalisation for the interaction database: lower-casing,
## punctuation folding, stop-word removal, a light stemmer and a synonym table
## that collapses a player's many phrasings onto one canonical token. Pure and
## deterministic; no engine state is read.

const STOPWORDS:Dictionary={
	"a":1,"an":1,"the":1,"and":1,"or":1,"but":1,"of":1,"to":1,"in":1,"on":1,"at":1,"by":1,"for":1,"with":1,"from":1,
	"into":1,"onto":1,"is":1,"are":1,"was":1,"were":1,"be":1,"been":1,"being":1,"am":1,"it":1,"its":1,"this":1,"that":1,
	"these":1,"those":1,"there":1,"then":1,"than":1,"so":1,"as":1,"if":1,"do":1,"does":1,"did":1,"i":1,"me":1,"my":1,
	"mine":1,"we":1,"us":1,"our":1,"ours":1,"you":1,"your":1,"yours":1,"he":1,"him":1,"his":1,"she":1,"her":1,"hers":1,
	"they":1,"them":1,"their":1,"theirs":1,"what":1,"which":1,"who":1,"whom":1,"whose":1,"when":1,"where":1,"why":1,
	"how":1,"can":1,"could":1,"would":1,"should":1,"will":1,"shall":1,"may":1,"might":1,"must":1,"let":1,"have":1,"has":1,
	"had":1,"having":1,"get":1,"got":1,"go":1,"now":1,"just":1,"very":1,"too":1,"also":1,"some":1,"any":1,"each":1,"s":1,
	"about":1,"up":1,"out":1,"over":1,"please":1,"want":1,"wish":1,"like":1,"make":1,"made":1,"thing":1,"things":1,
	"one":1,"ones":1,"not":0,"no":0,"all":0,"every":0,
}

## Surface word (or stem) -> canonical concept. Several spellings, dialect words
## and near-synonyms deliberately share a canonical token.
const SYNONYMS:Dictionary={
	# people and kin
	"men":"man","male":"man","males":"man","husband":"man","husbands":"man","guy":"man","fellow":"man","lad":"man","lads":"man",
	"women":"woman","female":"woman","females":"woman","lass":"woman","maiden":"woman","maidens":"woman","girl":"woman","girls":"woman",
	"wives":"wife","spouse":"wife","spouses":"wife","bride":"wife","brides":"wife",
	"children":"child","kid":"child","kids":"child","bairn":"child","bairns":"child","baby":"child","babies":"child","infant":"child",
	"infants":"child","offspring":"child","son":"child","sons":"child","daughter":"child","daughters":"child","young":"child","youngster":"child",
	"people":"people","folk":"people","folks":"people","populace":"people","tribe":"people","clan":"people","everyone":"people","villager":"people",
	"villagers":"people","citizen":"people","citizens":"people","subject":"people","subjects":"people","population":"people",
	"elder":"elder","elders":"elder","old":"elder","aged":"elder","grandparent":"elder","grandmother":"elder","grandfather":"elder",
	# breeding and family
	"sire":"breed","beget":"breed","impregnate":"breed","inseminate":"breed","mate":"breed","mating":"breed","mated":"breed","breeding":"breed",
	"procreate":"breed","stud":"breed","fertile":"fertile","virile":"fertile","potent":"fertile","fecund":"fertile","fertility":"fertile",
	"pregnant":"pregnant","pregnancy":"pregnant","conceive":"pregnant","conception":"pregnant","birth":"birth","births":"birth","born":"birth",
	"bear":"birth","childbirth":"birth","midwife":"birth","marry":"marry","married":"marry","marriage":"marry","wed":"marry","wedding":"marry",
	"betroth":"marry","betrothal":"marry","eugenic":"breed","eugenics":"breed","bloodline":"lineage","lineage":"lineage","heir":"lineage",
	# minds and bodies
	"smarter":"smart","smartest":"smart","clever":"smart","cleverest":"smart","cleverer":"smart","wise":"smart","wisest":"smart","wiser":"smart",
	"intelligent":"smart","brightest":"smart","bright":"smart","brilliant":"smart","sharpest":"smart","genius":"smart","gifted":"smart",
	"strongest":"strong","stronger":"strong","mighty":"strong","sturdy":"strong","healthiest":"healthy","fittest":"healthy",
	# killing and punishment
	"slay":"kill","slain":"kill","execute":"kill","execution":"kill","behead":"kill","hang":"kill","hanged":"kill","murder":"kill","death":"kill",
	"dead":"dead","die":"kill","slaughter":"kill","massacre":"kill","exterminate":"kill","cull":"kill","stone":"stone","stoning":"stone",
	"punish":"punish","punishment":"punish","flog":"punish","whip":"punish","beat":"punish","beating":"punish","torture":"punish","brand":"punish",
	"penalty":"punish","discipline":"punish","exile":"exile","banish":"exile","banishment":"exile","outcast":"exile","expel":"exile",
	"pardon":"pardon","forgive":"pardon","mercy":"pardon","amnesty":"pardon","spare":"pardon","release":"pardon","free":"free","freed":"free",
	"criminal":"criminal","thief":"criminal","thieves":"criminal","traitor":"traitor","traitors":"traitor","rebel":"rebel","rebels":"rebel",
	"dissenter":"rebel","dissenters":"rebel","heretic":"rebel","heretics":"rebel","troublemaker":"rebel","agitator":"rebel",
	# food
	"food":"food","eat":"food","eating":"food","meal":"food","meals":"food","provision":"food","provisions":"food","supplies":"food","grub":"food",
	"ration":"ration","rations":"ration","rationing":"ration","portion":"ration","portions":"ration","stint":"ration",
	"feast":"feast","feasting":"feast","banquet":"feast","celebration":"feast","celebrate":"feast","festival":"feast","party":"feast","revel":"feast",
	"hunt":"hunt","hunting":"hunt","hunter":"hunt","hunters":"hunt","prey":"hunt","forage":"forage","foraging":"forage","gather":"forage",
	"gathering":"forage","berries":"forage","roots":"forage","plant":"plant","planting":"plant","sow":"plant","sowing":"plant","seed":"plant",
	"seeds":"plant","crop":"plant","crops":"plant","field":"field","fields":"field","farm":"field","farms":"field","harvest":"harvest","reap":"harvest",
	"store":"store","stores":"store","storage":"store","stockpile":"store","granary":"store","cure":"store","dry":"store","smoke":"store",
	"fast":"fast","fasting":"fast","starve":"starve","starving":"starve","hunger":"starve","hungry":"starve","famine":"starve",
	"fish":"fish","fishing":"fish","fisher":"fish","net":"fish","nets":"fish","herd":"herd","herds":"herd","flock":"herd","cattle":"herd",
	"goats":"herd","goat":"herd","sheep":"herd","tame":"herd","pig":"herd","pigs":"herd","livestock":"herd","animal":"animal","animals":"animal","beast":"animal","beasts":"animal",
	# water and health
	"water":"water","well":"well","wells":"well","spring":"water","cistern":"water","aqueduct":"water","drink":"water","thirst":"water",
	"heal":"heal","healing":"heal","healer":"heal","healers":"heal","medicine":"heal","sick":"sick","sickness":"sick","ill":"sick",
	"illness":"sick","disease":"sick","wound":"sick","wounded":"sick","injured":"sick","fever":"sick","plague":"plague","pestilence":"plague",
	"quarantine":"quarantine","isolate":"quarantine","contagion":"plague","epidemic":"plague","clean":"clean","wash":"clean","bathe":"clean",
	"latrine":"latrine","latrines":"latrine","waste":"latrine","dung":"latrine","filth":"latrine","sanitation":"clean",
	# building
	"build":"build","building":"build","construct":"build","raise":"build","erect":"build","monument":"monument","statue":"monument",
	"tower":"monument","pyramid":"monument","megalith":"monument","obelisk":"monument","colossus":"monument","memorial":"monument",
	"shelter":"shelter","shelters":"shelter","hut":"shelter","huts":"shelter","house":"shelter","houses":"shelter","home":"shelter",
	"homes":"shelter","housing":"shelter","dwelling":"shelter","lodge":"shelter","wall":"wall","walls":"wall","palisade":"wall","fort":"wall",
	"fortify":"wall","fortification":"wall","rampart":"wall","ditch":"wall","stockade":"wall","road":"road","roads":"road","path":"road",
	"paths":"road","trail":"road","bridge":"road","track":"road","shrine":"shrine","temple":"shrine","altar":"shrine","sanctuary":"shrine",
	"workshop":"workshop","craft":"craft","crafts":"craft","artisan":"craft","artisans":"craft","tool":"tool","tools":"tool","toolmaker":"craft",
	# labour
	"work":"work","labor":"work","labour":"work","toil":"work","harder":"work","effort":"work","workers":"worker","worker":"worker",
	"rest":"rest","holiday":"rest","idle":"rest","sabbath":"rest","break":"rest","relax":"rest","slave":"slave","slaves":"slave",
	"slavery":"slave","enslave":"slave","captive":"slave","captives":"slave","servitude":"slave","forced":"force","compel":"force","coerce":"force",
	"apprentice":"apprentice","apprentices":"apprentice","master":"master",
	# the sacred
	"worship":"worship","pray":"worship","prayer":"worship","prayers":"worship","praise":"praise","ritual":"ritual","rite":"ritual","rites":"ritual",
	"ceremony":"ritual","dance":"ritual","chant":"ritual","hymn":"ritual","sacrifice":"sacrifice","offering":"sacrifice","offer":"sacrifice",
	"tribute":"tribute","god":"god","gods":"god","deity":"god","divine":"god","spirit":"god","spirits":"god","heaven":"god","heavens":"god",
	"omen":"omen","omens":"omen","prophecy":"omen","vision":"omen","sign":"omen","signs":"omen","portent":"omen","dream":"omen","dreams":"omen",
	"bless":"bless","blessing":"bless","blessed":"bless","favour":"bless","favor":"bless","smite":"smite","wrath":"smite","curse":"smite",
	"doom":"smite","destroy":"destroy","ruin":"destroy","raze":"destroy","burn":"burn","fire":"fire","flame":"fire",
	"miracle":"miracle","magic":"miracle","fly":"miracle","sun":"sky","moon":"sky","stars":"sky","sky":"sky","rain":"rain","storm":"storm",
	"taboo":"taboo","forbid":"forbid","forbidden":"forbid","ban":"forbid","prohibit":"forbid","outlaw":"forbid","never":"forbid","allow":"permit","permit":"permit",
	"love":"love","adore":"love","fear":"fear","afraid":"fear","dread":"fear","obey":"obey","obedience":"obey","loyal":"loyal","loyalty":"loyal",
	# law and order
	"law":"law","laws":"law","rule":"law","rules":"law","custom":"law","customs":"law","decree":"decree","edict":"decree","command":"decree",
	"order":"decree","proclaim":"decree","proclamation":"decree","guard":"guard","guards":"guard","watch":"guard","patrol":"guard","sentry":"guard",
	"sentries":"guard","police":"guard","spy":"spy","spies":"spy","informer":"spy","informers":"spy","eavesdrop":"spy","surveil":"spy",
	"dispute":"dispute","quarrel":"dispute","feud":"dispute","argument":"dispute","fight":"dispute","judge":"judge","judgment":"judge",
	"trial":"judge","verdict":"judge","rumour":"rumour","rumours":"rumour","rumor":"rumour","rumors":"rumour","gossip":"rumour",
	"silence":"silence","censor":"silence","propaganda":"rumour","story":"story","stories":"story","tale":"story","tales":"story","myth":"story",
	"song":"song","songs":"song","music":"song","sing":"song","drum":"song","drums":"song","paint":"art","painting":"art","carve":"art","carving":"art","art":"art",
	# war and neighbours
	"war":"war","raid":"war","raids":"war","attack":"war","invade":"war","conquer":"war","battle":"war","army":"army","warrior":"army",
	"warriors":"army","soldier":"army","soldiers":"army","troop":"army","troops":"army","conscript":"conscript","conscription":"conscript",
	"draft":"conscript","levy":"levy","recruit":"conscript","enlist":"conscript","defend":"defend","defense":"defend","defence":"defend",
	"enemy":"enemy","enemies":"enemy","foe":"enemy","foes":"enemy","neighbour":"neighbour","neighbours":"neighbour","neighbor":"neighbour",
	"neighbors":"neighbour","stranger":"stranger","strangers":"stranger","foreigner":"stranger","foreigners":"stranger","outsider":"stranger",
	"peace":"peace","truce":"peace","treaty":"peace","alliance":"ally","ally":"ally","allies":"ally","envoy":"envoy","envoys":"envoy",
	"messenger":"envoy","emissary":"envoy","ambassador":"envoy","trade":"trade","barter":"trade","exchange":"trade","merchant":"trade","market":"trade",
	"gift":"gift","gifts":"gift","present":"gift","scout":"scout","scouts":"scout","explore":"explore","exploration":"explore","expedition":"explore",
	"map":"explore","journey":"explore","voyage":"explore","hostage":"hostage","hostages":"hostage",
	# movement and land
	"move":"move","migrate":"move","migration":"move","relocate":"move","resettle":"move","leave":"move","abandon":"move","flee":"move",
	"colony":"colony","settle":"colony","outpost":"colony","village":"settlement","settlement":"settlement","town":"settlement","camp":"settlement",
	"city":"settlement","forest":"forest","woods":"forest","tree":"forest","trees":"forest","timber":"forest","wood":"forest","cut":"cut",
	"clear":"cut","chop":"cut","fell":"cut","protect":"protect","conserve":"protect","preserve":"protect","land":"land","territory":"land",
	# knowledge
	"teach":"teach","teaching":"teach","school":"teach","lesson":"teach","lessons":"teach","learn":"teach","educate":"teach","education":"teach",
	"lore":"lore","knowledge":"lore","study":"inquire","research":"inquire","discover":"inquire","invent":"inquire","experiment":"inquire",
	"investigate":"inquire","count":"count","census":"count","tally":"count","record":"count","records":"count","measure":"count",
	"name":"name","names":"name","rename":"name","call":"name","title":"name","identity":"name",
	"game":"game","games":"game","contest":"game","race":"game","wrestle":"game","wrestling":"game","competition":"game","sport":"game",
	# wealth and property
	"tax":"levy","taxes":"levy","share":"share","shares":"share","wealth":"wealth","rich":"wealth","riches":"wealth","treasure":"wealth",
	"redistribute":"share","equal":"share","equally":"share","fair":"share","own":"property","ownership":"property","property":"property",
	"belongings":"property",
	# rank and office
	"chief":"chief","leader":"chief","headman":"chief","official":"chief","officials":"chief","appoint":"appoint","promote":"appoint",
	"elevate":"appoint","crown":"appoint","choose":"appoint","dismiss":"dismiss","demote":"dismiss","remove":"dismiss","depose":"dismiss",
	"replace":"dismiss","fire_him":"dismiss","report":"report","status":"report","news":"report","advice":"advise","advise":"advise",
	"counsel":"advise","suggest":"advise","recommend":"advise","reward":"reward","honour":"reward","honor":"reward","praised":"reward",
	"medal":"reward","prize":"reward","shame":"shame","failed":"shame","failure":"shame","disappoint":"shame","disappointed":"shame",
	"useless":"shame","incompetent":"shame",
	# identity, custom
	"dress":"dress","clothes":"dress","clothing":"dress","wear":"dress","paint_face":"dress","tattoo":"dress","tattoos":"dress","jewel":"dress",
	"bury":"bury","burial":"bury","funeral":"bury","grave":"bury","graves":"bury","tomb":"bury","mourn":"bury","corpse":"bury","corpses":"bury",
	"hello":"greet","hi":"greet","greetings":"greet","hail":"greet","welcome":"greet","farewell":"greet","goodbye":"greet",
	"drunk":"intoxicant","drunkenness":"intoxicant","beer":"intoxicant","ale":"intoxicant","wine":"intoxicant","mead":"intoxicant",
	"brew":"intoxicant","intoxicant":"intoxicant","mushroom":"intoxicant","mushrooms":"intoxicant",
}

## Irregular or noisy stems the stemmer should never produce.
const STEM_KEEP:Dictionary={"harvest":1,"forest":1,"interest":1,"request":1,"conquest":1,"protest":1,"arrest":1,"contest":1,"honest":1,
	"modest":1,"suggest":1,"invest":1,"guest":1,"chest":1,"west":1,"nest":1,"quest":1,"rest":1,"test":1,"feast":1,"beast":1,"priest":1,
	"least":1,"east":1,"fast":1,"past":1,"vast":1,"cast":1,"less":1,"bless":1,"mess":1,"grass":1,"glass":1,"class":1,"ness":1,
	"news":1,"always":1,"series":1,"species":1,"lens":1,"famine":1,"festival":1,"ration":1,"nation":1,"station":1,"well":1,"hunger":1,
	"water":1,"father":1,"mother":1,"brother":1,"sister":1,"order":1,"never":1,"ever":1,"fever":1,"power":1,"other":1,"wander":1,"winter":1,
	"summer":1,"river":1,"thunder":1,"master":1,"elder":1,"leader":1,"hunter":1,"worker":1,"stranger":1,"neighbour":1,"harbour":1,"honour":1,
	"favour":1,"labour":1,"rumour":1}

const NUMBER_WORDS:Dictionary={"a":1,"an":1,"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,
	"eleven":11,"twelve":12,"thirteen":13,"fourteen":14,"fifteen":15,"sixteen":16,"seventeen":17,"eighteen":18,"nineteen":19,"twenty":20,
	"thirty":30,"forty":40,"fifty":50,"sixty":60,"hundred":100,"dozen":12,"score":20}

static var _canon_cache:Dictionary={}
static var _targets:Dictionary={}

## Lower-case, fold apostrophes and punctuation to spaces, collapse whitespace.
static func normalize(text:String)->String:
	var lower:String=text.to_lower().strip_edges()
	lower=lower.replace("’","'").replace("‘","'").replace("`","'")
	lower=lower.replace("'s ", " ").replace("s' ", "s ")
	if lower.ends_with("'s"): lower=lower.substr(0,lower.length()-2)
	var out:PackedStringArray=PackedStringArray()
	var buf:String=""
	for i:int in lower.length():
		var c:String=lower[i]
		var code:int=c.unicode_at(0)
		var keep:bool=(code>=97 and code<=122) or (code>=48 and code<=57) or code>127 or c=="?" or c=="!"
		if keep and c!="?" and c!="!": buf+=c
		else:
			if not buf.is_empty(): out.append(buf); buf=""
			if c=="?" or c=="!": out.append(c)
	if not buf.is_empty(): out.append(buf)
	return " ".join(out)

static func stem(word:String)->String:
	var w:String=word
	var n:int=w.length()
	if n<=3 or STEM_KEEP.has(w): return w
	if w.ends_with("ies") and n>4: return w.substr(0,n-3)+"y"
	if w.ends_with("iest") and n>5: return w.substr(0,n-4)+"y"
	if w.ends_with("sses"): return w.substr(0,n-2)
	if w.ends_with("ment") and n>7: return w.substr(0,n-4)
	if w.ends_with("ness") and n>6: return w.substr(0,n-4)
	if w.ends_with("ing") and n>5: return _undouble(w.substr(0,n-3))
	if w.ends_with("ied") and n>4: return w.substr(0,n-3)+"y"
	if w.ends_with("ed") and n>4 and not w.ends_with("eed"): return _undouble(w.substr(0,n-2))
	if w.ends_with("est") and n>6: return w.substr(0,n-3)
	if w.ends_with("ly") and n>5: return w.substr(0,n-2)
	if (w.ends_with("shes") or w.ends_with("ches") or w.ends_with("xes") or w.ends_with("zes")) and n>4: return w.substr(0,n-2)
	if w.ends_with("s") and not w.ends_with("ss") and not w.ends_with("us") and not w.ends_with("is") and n>3: return w.substr(0,n-1)
	return w

static func _undouble(w:String)->String:
	var n:int=w.length()
	if n>=4 and w[n-1]==w[n-2] and not (w[n-1] in ["l","s","z"]): return w.substr(0,n-1)
	return w

## One surface word -> canonical token ("" when it is a stop word).
static func canonical(word:String)->String:
	if _canon_cache.has(word): return String(_canon_cache[word])
	if _targets.is_empty():
		for k:Variant in SYNONYMS: _targets[String(SYNONYMS[k])]=true
	var result:String=""
	if STOPWORDS.has(word) and int(STOPWORDS[word])==1: result=""
	elif SYNONYMS.has(word): result=String(SYNONYMS[word])
	elif _targets.has(word): result=word
	else:
		var s:String=stem(word)
		if SYNONYMS.has(s): result=String(SYNONYMS[s])
		elif STOPWORDS.has(s) and int(STOPWORDS[s])==1: result=""
		else: result=s
	if _canon_cache.size()<200000: _canon_cache[word]=result
	return result

## Ordered canonical tokens (duplicates kept, punctuation dropped).
static func tokens(text:String)->PackedStringArray:
	var out:PackedStringArray=PackedStringArray()
	for word:String in normalize(text).split(" ",false):
		if word=="?" or word=="!": continue
		var c:String=canonical(word)
		if not c.is_empty(): out.append(c)
	return out

## Term-frequency map of canonical tokens plus adjacent bigrams ("a_b").
static func term_counts(text:String,with_bigrams:bool=true)->Dictionary:
	var toks:PackedStringArray=tokens(text)
	var counts:Dictionary={}
	for t:String in toks: counts[t]=int(counts.get(t,0))+1
	if with_bigrams:
		for i:int in range(toks.size()-1):
			var bigram:String=toks[i]+"_"+toks[i+1]
			counts[bigram]=int(counts.get(bigram,0))+1
	return counts

## Character trigrams of the normalised text, used for fuzzy re-ranking.
static func trigrams(text:String)->Dictionary:
	var s:String=" "+normalize(text).replace("?","").replace("!","").strip_edges()+" "
	var out:Dictionary={}
	for i:int in range(maxi(0,s.length()-2)): out[s.substr(i,3)]=true
	return out

static func jaccard(a:Dictionary,b:Dictionary)->float:
	if a.is_empty() or b.is_empty(): return 0.0
	var small:Dictionary=a if a.size()<=b.size() else b
	var large:Dictionary=b if a.size()<=b.size() else a
	var inter:int=0
	for k:Variant in small:
		if large.has(k): inter+=1
	return float(inter)/float(a.size()+b.size()-inter)

## First explicit count in the text ("ten men", "12 hunters"), or -1.
static func first_count(text:String)->int:
	for word:String in normalize(text).split(" ",false):
		if word.is_valid_int(): return clampi(int(word),0,1000000)
		if NUMBER_WORDS.has(word) and word!="a" and word!="an": return int(NUMBER_WORDS[word])
	return -1

## Removes anything that looks like a credential before text is stored.
static func redact(text:String)->String:
	var re:RegEx=RegEx.new()
	re.compile("(sk-[A-Za-z0-9_\\-]{12,}|Bearer\\s+[A-Za-z0-9_\\-\\.]{12,}|[A-Za-z0-9_\\-]{40,})")
	return re.sub(text,"[redacted]",true)
