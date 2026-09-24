extends RefCounted
## Deterministic personas for audience-hall speech. Nothing here is saved: every
## persona is re-derived from the world seed plus stable ids (civ id, person id,
## audience id), and officials additionally from their live traits, disposition,
## personality axes, background and relationship to the ruler.
##
## Persona = {"key","name","voice","dialect","tics":[String],"want","fear","quirk",
##            "secret","temper","sample"} plus helper fields ("dialect_id",
##            "address","oath","proverb","role","title","toward_ruler","stance",
##            "model","model_style","model_era","era_owner","era_tags","era_tier").
##
## Three layers, strongest first:
##  1. A VOICE MODEL: one speaking manner drawn from classic literature or
##     history, assigned for life by temperament fit. Style only; never quoted,
##     never named aloud (see VOICE_MODELS, FAMOUS_LINES, SOURCE_NAMES).
##  2. ERA: everything a speaker says is gated by what their people actually
##     know (ERA_GATES over known discoveries). No beer before brewing, no iron
##     before smelting, no ledgers before writing. Personas are re-derived per
##     era tier, so their flourishes grow with the world.
##  3. DIALECT: light regional seasoning (a word swap, an address term, an
##     occasional oath). Invented speech styles for invented peoples.

const DIALECTS:Array[Dictionary]=[
	{"id":"highland_burr","label":"Highland burr",
	 "guide":"rolling highland burr: aye, ken, wee, cannae, dinnae, och, bairns, auld; weather-and-stone sayings",
	 "subs":{"good":"braw","know":"ken","small":"wee","little":"wee","can't":"cannae","cannot":"cannae","don't":"dinnae","won't":"willnae","isn't":"isnae","you":"ye","your":"yer","children":"bairns","old":"auld","from":"frae","nothing":"naught"},
	 "open":["Och,","Aye, well,","Hark,","Now then,"],
	 "address":["ma chief"],"oath":["By the cold cairns!","Stones and sleet!","Wind and bracken!"],
	 "proverb":["A wee leak sinks a big boat.","A wee spark burns a big hill.","Ye cannae coax a stone tae sing.","Fair words fill nae bellies."],
	 "first":["Brannoch","Ailveth","Kester","Mhorain","Duncair","Isbeth"],"last":["of the Crags","Stanehollow","Greymantle","Fernburr"]},
	{"id":"river_patter","label":"River-trader patter",
	 "guide":"clipped river-trader patter: drops little words, doubles for emphasis (sure-sure, quick-quick), weighs and haggles over everything, calls the ruler friend-chief",
	 "subs":{"quickly":"quick-quick","good":"good-good","friend":"friend-o","very":"plenty","perhaps":"maybe-maybe"},
	 "open":["Hup!","Look-look,","Straight talk:","Weigh this:"],
	 "address":["friend-chief"],"oath":["By the long current!","Mud and minnows!","Sink my barge!"],
	 "proverb":["Cheap rope, short trip.","River gives, river counts.","Wet fish still feeds."],
	 "first":["Pell","Oskadi","Nimo","Tarrow","Quill","Lisk"],"last":["Longpole","of Three Fords","Tallyhand","Mudwater"]},
	{"id":"ornate_court","label":"Ornate court formality",
	 "guide":"ornate court formality: stacked titles, elaborate honorifics, blessings and flourishes, 'most humbly', 'may your granaries never echo'",
	 "guide_early":"ornate court formality: stacked titles, elaborate honorifics, blessings and flourishes, 'most humbly', 'may your fire never want for wood'",
	 "subs":{"I think":"this unworthy one believes","please":"if it please the Luminous Seat","thank you":["a thousand embroidered thanks","a thousand bowed thanks"],"very":"most exceedingly"},
	 "open":["If this unworthy tongue may speak,","With the deepest of bows,","Ahem, most humbly,"],
	 "address":["O Luminous Seat"],"oath":["Stars attend us!","By the Nine Furs!","Heavens embroidered!"],
	 "proverb":["A gift unwrapped in haste is a gift half-given.","The longest bow is the shortest road to favour.","A soft word hides the knife, and flatters it."],
	 "first":["Aurelisse","Vanthiel","Oriandre","Cassimor","Pellarine","Sabeline"],"last":["of the Ninth Fur","Softstep","the Much-Titled","of the Bright Feathers","Goldthread"]},
	{"id":"steppe_laconic","label":"Laconic steppe speech",
	 "guide":"laconic steppe terseness: very short sentences, few words, grass-and-wind images, silences marked with 'Hm.'",
	 "subs":{"I think ":"","perhaps ":"","very ":"","really ":"","actually ":"","friend":["rider","walker"]},
	 "open":["Hm.","So.","Wind turns."],
	 "address":["hearth-holder"],"oath":["Sky and grass!","Hooves of the grey mare!","Sky and saddle!"],
	 "proverb":["Fast horse, short life.","The wind does not argue. It blows.","Many words, thin horse."],
	 "first":["Oyun","Tasar","Brek","Ulka","Senge","Yaru"],"last":["Far-Walker","of the Long Grass","Dustmane","Windborn","Far-Rider"]},
	{"id":"grandmother_proverb","label":"Grandmother wisdom",
	 "guide":"proverb-heavy grandmother wisdom: calls everyone 'child' or 'dearie' (even the ruler), an endless supply of homely sayings, most slightly wrong",
	 "subs":{"friend":"pet","trouble":"bother"},
	 "open":["Now, dearie,","Listen to your elders, child:","As my own gran used to say,"],
	 "address":["my chief"],"oath":["Goodness and gravy!","Well, pluck my goose!","Well, butter my bread!"],
	 "proverb":["A fire watched by two cooks burns twice as fast.","Never trust a goat that compliments your hat.","Honey on the lip, nettle in the sleeve.","The empty gourd rattles loudest."],
	 "first":["Old Mother Hesk","Granny Pobb","Auntie Wenna","Nana Oriel","Old Brisa","Mam Tollie"],"last":["of the Warm Hearth","Pickleback","Threadneedle","Crumbhollow"]},
	{"id":"coastal_lilt","label":"Sing-song coastal lilt",
	 "guide":"sing-song coastal lilt: ends sentences with 'so it is' or 'isn't it, now', tide-and-gull metaphors, playful repetition",
	 "subs":{"very":"ever so","soon":"on the next tide","friend":"my gull","wait":"bide"},
	 "open":["Ah, now,","Well, well, well,","Oh, the tide of it,"],
	 "address":["my bright one"],"oath":["Salt and starlight!","Gulls take me!"],
	 "proverb":["The sea keeps no promises, but it keeps everything else.","A calm shore makes a lazy fisher.","Every tide brings a boot back."],
	 "first":["Maro","Ellisande","Pim","Coriel","Wenlo","Sarafin"],"last":["Saltwhistle","of the Shell Stair","Driftwell","Tidecall"]},
	{"id":"forge_gruff","label":"Gruff forge-folk","label_early":"Gruff flint-knapper folk",
	 "guide":"gruff forge-folk: blunt, hammer-and-anvil talk, grunts ('Hrm.'), judges everything by whether it holds under a hammer, insults like 'soft-iron'",
	 "guide_early":"gruff flint-knapper folk: blunt, strike-and-flake talk, grunts ('Hrm.'), judges everything by whether it holds an edge, insults like 'soft-stone'",
	 "subs":{"weak":["soft-iron","soft-stone"],"strong":["well-tempered","hard-flaked"],"think":"reckon","nonsense":["slag","grit"],"fool":["slag-head","grit-head"]},
	 "open":["Hrm.","Right.","Listen, soft-iron:","Listen, soft-stone:"],
	 "address":["forge-master","chief of the fire"],"oath":["Flint and fire!","Sparks and splinters!","Anvils and ashes!","Tongs of my father!"],
	 "proverb":["Cold flint don't bend for pretty words.","Every edge is honest once it's struck.","Quick blow, cracked core.","Cold iron don't bend for pretty words.","Quick fire, brittle steel."],
	 "first":["Dorga","Hamrik","Brusa","Kelt","Ondra","Grom"],"last":["Sootjaw","of the Red Hearth","Flintback","Knapper","Anvilback","of the Red Bellows"]},
	{"id":"liturgical_pious","label":"Pious liturgical cadence",
	 "guide":"pious liturgical cadence: blessings, 'verily', 'thus it is sung', 'we beseech', repetition in threes, everything a sign from the heavens",
	 "subs":{"truly":"verily","luck":"providence","lucky":"blessed","hope":"pray"},
	 "open":["Blessed be the fire,","Verily,","Hear me, now:","Blessed be the grain,"],
	 "address":["Anointed One","Blessed Seat"],"oath":["Heaven's hem!","Spirits keep us!","Saints of the furrow!"],
	 "proverb":["The trap that is prayed over still wants setting.","Heaven helps the one who counts the sacks.","A humble lamp outlasts a proud fire.","The field that is prayed over still wants hoeing."],
	 "first":["Brother Anselm","Sister Idony","Elder Pax","Mother Seraphine","Keeper Oda","Singer Hesk","Deacon Tobiah","Cantor Ilse"],"last":["of the Seventh Star","Hymnfold","the Unwearied","of the Seventh Bell","Candlewright"]},
	{"id":"marsh_drawl","label":"Slow marsh drawl",
	 "guide":"slow marsh drawl: 'reckon', 'yonder', 'a-coming', long easy sentences, eel-and-reed metaphors, unhurried to the point of mischief",
	 "subs":{"think":"reckon","over there":"over yonder","coming":"a-coming","going":"a-going","very":"mighty","hurry":"fuss"},
	 "open":["Well now,","Mm-hm.","Easy, easy,"],
	 "address":["high one","big fish"],"oath":["Eels and eelgrass!","Muck and mercy!"],
	 "proverb":["Slippery as an eel's apology.","Mud remembers every foot.","Heron don't chase. Heron waits."],
	 "first":["Cobb","Loyal Ettie","Russet","Wade","Minnow","Bettany"],"last":["Reedwater","of the Sunk Bridge","Longmire","Frogsford"]},
	{"id":"pedant_scholar","label":"Hill-folk pedantry",
	 "guide":"hill-city pedantry: 'strictly speaking', 'to wit', corrects themselves mid-sentence, footnotes their own jokes, precise to the point of comedy",
	 "guide_early":"hill-folk pedantry: 'strictly speaking', 'to wit', corrects themselves mid-sentence, counts on knotted cords, precise to the point of comedy",
	 "subs":{"about":"approximately","big":"considerable","maybe":"conceivably","very":"measurably","lots":"a countable surplus"},
	 "open":["Strictly speaking,","To wit:","If I may correct the record,"],
	 "address":["Esteemed Presider"],"oath":["By the ninth knot!","Count and error!","By the ninth scroll!","Ink and error!"],
	 "proverb":["An unmeasured promise weighs nothing.","Two witnesses, three stories.","The edge is where the truth hides.","The margin is where the truth hides."],
	 "first":["Counter Quell","Ondine","Theodric","Ysolde","Tallier Brann","Perpetua","Magister Quell","Archivist Brann"],"last":["of the Upper Terraces","Knotcord","Sevenfold","Tallymark","Inkwell","Marginalia"]},
	{"id":"festival_boisterous","label":"Boisterous feast-hall bluster",
	 "guide":"boisterous feast-hall bluster: loud, laughing, boastful superlatives, food metaphors, calls people 'my roast goose', exclamation-happy",
	 "subs":{"good":"glorious","big":"enormous","very":"tremendously","friend":"my roast goose","fine":"splendid"},
	 "open":["HA!","Ho-ho!","Oh, glorious!"],
	 "address":["big-hearted one"],"oath":["Bellies and bonfires!","Roast my ribs!"],
	 "proverb":["An empty belly makes a short temper and a long speech.","The best deals are sealed with gravy.","Never trust a thin cook."],
	 "first":["Big Ulfo","Merrit","Bolla","Hendro","Gusta","Fat Parro"],"last":["Bigbelly","of the Long Fire","Roastwell","Alehorn","Barrelbelly"]},
	{"id":"frost_skald","label":"Frost-skald kennings",
	 "guide":"frost-skald kennings: alliteration, poetic compounds (whale-road, word-hoard, sword-song), boasts in verse fragments, grim weather humour",
	 "guide_early":"frost-skald kennings: alliteration, poetic compounds (whale-road, word-hoard, spear-song), boasts in verse fragments, grim weather humour",
	 "subs":{"sea":"whale-road","words":"word-hoard","battle":["sword-song","spear-song"],"gold":"hand-fire","ship":"wave-horse","war":"spear-storm"},
	 "open":["Hear me, hall!","Listen, hearth-lord:","Cold comes the word:"],
	 "address":["ring-giver","hearth-lord"],"oath":["Frost and flint!","By the long winter!"],
	 "proverb":["Warm words, cold spears.","The ice remembers who fell through it.","A boast is a debt the spear must pay.","A boast is a debt the sword must pay."],
	 "first":["Hrolla","Sigvard","Eskil","Thyri","Bjarnhild","Ormr"],"last":["Frostbeard","of the White Fjell","Bearbreaker","Wolfcoat","Ringbreaker"]},
]
## Used when an era leaves a dialect field with nothing permitted.
const DIALECT_SAFE:={"open":["Well,"],"address":["chief"],"oath":["By the old fire!"],"proverb":["Fire warms the one who feeds it."],"first":["Ash"],"last":["of the Hearth"]}

# ---------------------------------------------------------------------------
# Era gates. A word may be spoken only if the speaker's people know one of the
# listed discoveries. Everything else in the lexicon does not exist yet: not in
# speech, not in metaphor, not in a name.
# ---------------------------------------------------------------------------

const ERA_GATES:={
	"metal":{"ids":["copper_smelting","copper_casting","bronze_alloying","bloomery_smelting","forge_welding","finery_forges","iron_assaying"],"label":"metal (copper, bronze, iron, gold)",
		"words":"iron|irons|ironwork|steel|bronze|copper|metal|metals|metalwork|forge|forges|forged|forge-master|forge-folk|anvil|anvils|anvilback|smith|smiths|smithy|blacksmith|bellows|tongs|quench|quenched|slag|slag-head|sword|swords|sword-song|gold|golden|goldthread|silver|bell|bells|feast-bell|nail|nails|clinker|ring-giver|ringbreaker|soft-iron|well-tempered|armour|armor|helmet|helmets|chainmail|kettle|cauldron|horseshoe|horseshoes|spur|spurs"},
	"brewing":{"ids":["fermentation_control","fermentation_starter_cultures"],"label":"beer, ale and wine",
		"words":"beer|beers|barley-beer|ale|ales|alehouse|alehorn|wine|wines|mead|brew|brews|brewed|brewer|brewing|tavern|taverns|sober|drunk|drunken|tipsy|cask|casks|barrel|barrels|barrelbelly|keg|kegs"},
	"farming":{"ids":["seed_selection","crop_calendars","managed_fallow","seed_reserves","crop_rotation","regional_granaries","germination_trials"],"label":"sown crops, grain, ploughs and granaries",
		"words":"grain|grains|barley|wheat|oats|rye|turnip|turnips|plough|ploughs|ploughed|plow|plows|plowed|furrow|furrows|hoe|hoes|hoeing|granary|granaries|barn|barns|crop|crops|farm|farms|farmer|farmers|farming|farmland|scarecrow|haystack|hayloft"},
	"baking":{"ids":["controlled_baking","dough_leavening","grain_milling"],"label":"bread, flour and mills",
		"words":"bread|breads|loaf|loaves|flour|dough|bake|baked|baker|bakers|baking|bakery|mill|mills|miller|millstone|crust"},
	"dairy":{"ids":["animal_taming","pack_animals"],"label":"tame herds, milk and cheese",
		"words":"butter|buttered|cheese|cheeses|milk|milked|milking|dairy|cream|churn|churned|shepherd|shepherds|sheepfold|cowshed|yoke|yoked"},
	"riding":{"ids":["domesticated_mounts","mounted_scouts"],"label":"riding horses",
		"words":"saddle|saddles|saddled|rider|riders|riding|ride|rides|rode|stirrup|stirrups|cavalry|horseback|horseman|horsemen|mounted|bridle|reins|far-rider"},
	"wheel":{"ids":["joined_wheel_blank","bored_wheel_hubs","assembled_transport_cart","cart_assembly_kits","iron_tired_wheels"],"label":"wheels and carts",
		"words":"wheel|wheels|wheeled|cart|carts|cartload|wagon|wagons|axle|axles|chariot|chariots|cartwright|wheelwright|wheelbarrow"},
	"pottery":{"ids":["clay_shaping","pit_firing","clay_tempering","sealed_vessels","kiln_control"],"label":"pottery (pots, jars, kilns)",
		"words":"pot|pots|potter|potters|pottery|jar|jars|jug|jugs|urn|urns|kiln|kilns|crock|crocks|amphora|pitcher|pitchers|pickle|pickled"},
	"masonry":{"ids":["kiln_control","lime_mortar","lime_burning"],"label":"brick, mortar and stoves",
		"words":"brick|bricks|mortar|masonry|mason|masons|stove|stoves|chimney|chimneys|tile|tiles|plaster"},
	"writing":{"ids":["pictographic_records","phonetic_notation","formal_archives","parchment_record_preparation","paper_making","printing_process"],"label":"writing (letters, ink, scrolls, ledgers)",
		"words":"write|writes|writing|written|wrote|scroll|scrolls|ink|inks|inked|inkwell|tablet|tablets|slate|slates|ledger|ledgers|stylus|archive|archives|archivist|book|books|page|pages|letter|letters|margin|margins|marginalia|footnote|footnotes|parchment|paper|papers|quill|quills|scribe|scribes|signature|alphabet|literate"},
	"coin":{"ids":["public_credit","property_registers"],"label":"coin and money",
		"words":"coin|coins|coinage|money|moneys|banker|bankers|purse|purses|tax|taxes|taxed|wage|wages|mint|minted|currency|shilling|penny|pennies"},
	"boats":{"ids":["hide_floats","river_craft","coastal_watercraft"],"label":"boats and rafts",
		"words":"boat|boats|boatman|raft|rafts|canoe|canoes|paddle|paddles|oar|oars|rowing|rowed"},
	"ships":{"ids":["coastal_watercraft","mast_making","clinker_shell_construction","carvel_frame_construction"],"label":"ships, sails and harbours",
		"words":"ship|ships|shipwright|sail|sails|sailed|sailing|sailor|sailors|barge|barges|harbour|harbours|harbor|harbors|captain|captains|mast|masts|keel|keels|deck|decks|anchor|anchors|anchored|fleet|fleets|navy|wave-horse"},
	"weaving":{"ids":["plain_weaving","warp_weighted_looms","woven_cloth","combed_yarn","spun_yarn"],"label":"woven cloth, wool and silk",
		"words":"cloth|cloths|weave|weaves|weaving|weaver|weavers|loom|looms|embroider|embroidered|embroidery|silk|silks|silken|velvet|velvets|velvetreach|linen|linens|wool|woollen|woolen|yarn|tapestry|tapestries|lace|satin|brocade|cotton"},
	"glass":{"ids":["core_formed_glass","glass_blowing","mold_blown_glass"],"label":"glass",
		"words":"glass|glasses|glassy|mirror|mirrors|window|windows|windowpane|lens|lenses|spectacles"},
	"institutions":{"ids":["specialized_courts","formal_archives","craft_guilds","public_schools","census_rolls"],"label":"temples, priests, schools and law courts",
		"words":"temple|temples|priest|priests|priestess|priesthood|saint|saints|saintly|deacon|deacons|cantor|cantors|church|churches|cathedral|cathedrals|monk|monks|monastery|abbot|bishop|bishops|magister|guild|guilds|school|schools|schoolroom|university|lawyer|lawyers|jury|juries|courtroom|lawcourt|magistrate|magistrates"},
	"candles":{"ids":["rendered_leather_fat","sealed_vessels","curing_regimens"],"label":"candles and wax",
		"words":"candle|candles|candlelight|candlewright|wax|taper|tapers"},
	"gunpowder":{"ids":["black_powder"],"label":"gunpowder and guns",
		"words":"gun|guns|gunpowder|musket|muskets|cannon|cannons|pistol|pistols|rifle|rifles|bullet|bullets"},
}
const ERA_WORDS:=[
	"the old stone world: hunters and gatherers of fire, stone, bone, hide, cord, wood and wild food",
	"early villages: first sown fields, clay vessels, tamed beasts and simple craft",
	"first metal and first marks: smelted metal, wheels or written tallies among the old ways",
	"iron and letters: iron tools, written records and wider trade",
]
## Tests can pin what a people knows ("player" or a civ id -> discovery ids).
static var knowledge_override:Dictionary={}
static var _gate_res:Dictionary={}
static var _dialect_cache:Dictionary={}
static var _actor_cache:Dictionary={}

static func known_ids(owner:String)->Array:
	if knowledge_override.has(owner): return knowledge_override[owner]
	if owner=="" or owner=="player":
		return GameState.known_discoveries if Engine.get_main_loop()!=null else []
	# A foreign people speaks from what that people knows; unknown peoples get
	# the conservative founding-era default.
	var frame:int=Engine.get_process_frames()
	var cached:Dictionary=_actor_cache.get(owner,{})
	if int(cached.get("frame",-1))==frame: return cached.get("ids",[])
	var ids:Array=preload("res://scripts/founding_knowledge.gd").PRACTICES.duplicate()
	if Engine.get_main_loop()!=null and WorldSimulation.actors.has(owner):
		var got:Variant=WorldSimulation.scoped(owner,func()->Array: return (WorldSimulation.state.known_discoveries as Array).duplicate())
		if got is Array: ids=got
	_actor_cache[owner]={"frame":frame,"ids":ids}
	return ids

static func era_tags(owner:String)->Array[String]:
	## The gated lexicon tags this people's knowledge permits.
	var known:Array=known_ids(owner)
	var out:Array[String]=[]
	for tag:String in ERA_GATES:
		for id in ERA_GATES[tag].ids:
			if known.has(String(id)): out.append(tag); break
	return out

static func era_tier(tags:Array)->int:
	if tags.has("gunpowder") or ((tags.has("metal") and tags.has("writing")) and (tags.has("ships") or tags.has("coin"))): return 3
	for tag in ["metal","writing","wheel","riding","coin"]:
		if tags.has(tag): return 2
	for tag in ["farming","pottery","dairy","boats","weaving","baking","candles"]:
		if tags.has(tag): return 1
	return 0

static func _gate_re(tag:String)->RegEx:
	if not _gate_res.has(tag):
		var re:=RegEx.new()
		re.compile("(?i)(?<![A-Za-z'-])("+String(ERA_GATES[tag].words)+")(?![A-Za-z-])")
		_gate_res[tag]=re
	return _gate_res[tag]

static func lexicon_hits(text:String,tags:Array=[])->Array[String]:
	## Gated words in text that the given tags do not permit.
	var out:Array[String]=[]
	for tag:String in ERA_GATES:
		if tags.has(tag): continue
		for m in _gate_re(tag).search_all(text): out.append("%s:%s" % [tag,m.get_string().to_lower()])
	return out

static func lexicon_tags_in(text:String)->Array[String]:
	## Which gated tags a text mentions at all (e.g. supplied facts).
	var out:Array[String]=[]
	for tag:String in ERA_GATES:
		if _gate_re(tag).search(text)!=null: out.append(tag)
	return out

static func permits(text:String,tags:Array)->bool:
	for tag:String in ERA_GATES:
		if tags.has(tag): continue
		if _gate_re(tag).search(text)!=null: return false
	return true

static func world_line(tags:Array)->String:
	## Compact prompt line: what this world has and, explicitly, what it lacks.
	var have:PackedStringArray=PackedStringArray(); var lack:PackedStringArray=PackedStringArray()
	for tag:String in ERA_GATES:
		(have if tags.has(tag) else lack).append(String(ERA_GATES[tag].label))
	return "%s. Known: fire, stone, bone, hide, cord, wood, hunting and gathering%s. NOT YET KNOWN, so these do not exist and may not appear even as metaphor or in names: %s." % [
		ERA_WORDS[era_tier(tags)],("; "+", ".join(have)) if not have.is_empty() else "",", ".join(lack) if not lack.is_empty() else "nothing"]

static func _era_pick(rng:RandomNumberGenerator,list:Array,tags:Array,fallback:String="")->String:
	var pool:Array=[]
	for item in list:
		if permits(String(item),tags): pool.append(item)
	if pool.is_empty(): return fallback
	return String(pool[rng.randi_range(0,pool.size()-1)])

static func _era_many(rng:RandomNumberGenerator,list:Array,count:int,tags:Array)->Array:
	var pool:Array=[]
	for item in list:
		if permits(String(item),tags): pool.append(item)
	return _pick_many(rng,pool,count)

static func _era_or(text:String,fallback:String,tags:Array)->String:
	return text if permits(text,tags) else fallback


const COMMON_STARTERS:=["take","whatever","everybody","everyone","three","another","plainly","refused","received","sensible","thanks","dismissed","rebuked","snarling","glad","noted","pretty","gifts","hungry","every","folk","people","fine","lovely","hear","hand","back","muddy","word","before","straight","let's","these","somebody","scouts","walls","did","sounds","write","never","between","say","whatever","a","an","the","we","you","ye","it","its","it's","our","what","that","this","these","those","there","no","not","let's","let","nice","straight","word","give","ask","accept","gifts","if","careful","kind","so","fair","good","well","now","one","and","but","or","for","with","whatever","all","any","every","how","why","who","when","where","they","their","them","he","she","his","her","my","your","yer","don't","dinnae","yes","aye","nobody","nothing","some","someone","somebody","still","just","half","take","keep","tell","hold","look","listen","mark","count","our","do","does","did","is","are","was","were","be","say","said","go","come","sit","stand","right","lovely","bold","ah","oh","hm","hmm","ha","bah","sensible","threat","news","ask","asking","pay","perhaps","maybe","strictly","to","as","at","in","on","of","by","from","about","again","also","before","after","then","than","too","very","more","most","less","least","enough","quite","rather","truly","indeed","never","always","often","sometimes","here","eh","sure","fine","mind","wait","don't","can't","won't","isn't","they'll","we'll","you'll","we're","you're","they're","that's","there's","here's","what's","who's"]
const VOICES:=["booming","velvet-soft","rapid-fire","gravelly","nasal and precise","deadpan","breathless","honeyed","creaky","sing-song","clipped","rumbling"]
const TEMPERS:=["hot-headed","ice-calm","sly","jolly","prickly","melancholy","zealous","serene","nervous","smug","impish","dour"]
## Pet phrases are lead-ins: they open a line and flow into it, never trail it.
const TICS:=[
	"Mark me,","Between you, me and that pillar,","With respect, and I have very little,","Pardon my honesty, but",
	"Not that anyone asked me, but","Trust me on this:","I'll say it once and then louder:","Write this down:",
	"Oh, this'll be fun:","Here's the thing nobody wants said:","I've seen this twice before and both times it ended in goats, so",
	"Let's not all agree at once, but","Hand on heart,","Say what you like about me, but",
]
const QUIRKS:=[
	"counts on their fingers while others talk","keeps a pet beetle in a pocket and consults it","hums when lying",
	"eats constantly and apologizes for none of it","has named their sandals","addresses the hall's pillars as witnesses",
	"collects other people's lost earrings","laughs a beat too late at every joke","sniffs every gift before accepting it",
	"quotes a dead aunt as the final authority","insists on standing on the left","finishes other people's proverbs, wrongly",
]
const ENVOY_SECRETS:=[
	"was sent because nobody else would come","likes this court far more than they are allowed to admit",
	"was told not to come home empty-handed","is quietly, badly homesick","privately disagrees with their own leader",
	"has never actually seen a battle, despite the swagger","is being watched by a rival from their own court",
	"wants to defect, a little, on good days",
]
const OFFICIAL_SECRETS:=[
	"writes anonymous verses mocking the court","secretly admires the visiting people's cooking",
	"cheats at knucklebones and is very good at it","has a sweetheart in a rival household",
	"is terrified of geese","keeps a second, more honest ledger at home","once fled a hearth-fight and never told anyone",
	"wants the ruler's seat, eventually, politely",
]
const FEARS:=[
	"being laughed at","going hungry again","deep water","being forgotten","owing anyone anything",
	"the dark between the lamps","looking foolish in front of foreigners","a quiet room",
]
const TRAIT_WANTS:={
	"Ambitious":"a grander title, soon","Frugal":"a surplus nobody may touch","Generous":"to be loved for giving",
	"Curious":"to know how everything works","Traditional":"things done the old way","Inventive":"to try the new thing first",
	"Bold":"a reason to be brave","Cautious":"no surprises, ever","Severe":"order, and people who keep it",
	"Warm":"everyone fed and friendly","Humble":"to be useful without being noticed","Patient":"time, and to be given it",
	"Methodical":"a tidy ledger","Forceful":"to be obeyed quickly","Skeptical":"proof, in writing",
	"Pragmatic":"whatever works by sundown","Principled":"to be right and seen to be right","Diplomatic":"nobody leaving angry",
}
const BACKGROUND_QUIRKS:={
	"Store and harvest keeper":"sniffs the air for mildew mid-sentence","Watch organizer":"never sits with their back to a door",
	"Observer and memory keeper":"murmurs dates under their breath","Messenger and dispute mediator":"repeats the last word of other people's sentences",
	"Builder and works organizer":"taps walls to check they're sound","Route and caravan organizer":"always knows which way is north, loudly",
	"Household mediator":"settles arguments nobody knew they were having",
}
const DISPOSITION_TICS:={
	"sycophantic":["Magnificent as ever,","Oh, wise, so wise, and","I was just about to say it:"],
	"cantankerous":["Oh, splendid, another plan:","I'll believe it when I've bitten it, but","Nobody listens to me, but"],
	"principled":["Plainly:","I won't dress it up:","True thing first:"],
	"diplomatic":["Perhaps we're both right, but","Let's all breathe:","Gently, now:"],
	"pragmatic":["Practically speaking,","Counting it out plainly:","Cost first, feelings later:"],
}
const DISPOSITION_TEMPER:={
	"sycophantic":"eager and oily, agrees too fast","cantankerous":"prickly, suspicious, loves finding the catch",
	"principled":"blunt and plain, allergic to flattery","diplomatic":"warm and wheedling, smooths every edge",
	"pragmatic":"dry and practical, prices everything",
}
const DISPOSITION_WANT:={
	"sycophantic":"to agree with the ruler first and loudest","cantankerous":"to find the catch before anyone else does",
	"principled":"to get the plain truth said aloud","diplomatic":"to let everyone leave with their pride",
	"pragmatic":"to know the cost and who carries it",
}
const TEMPERAMENT_TEMPER:={
	"Bridge-builder":"warm, generous, hates a grudge","Proud guardian":"proud, prickly about honour, quick to bristle",
	"Restless visionary":"restless, grand schemes, bored by detail","Practical organizer":"dry, shrewd, counts every sack",
}



# ---------------------------------------------------------------------------
# Voice models. Each is a speaking MANNER drawn from classic literature or
# history. Speakers imitate the style in original words, translated into their
# own era; they never quote the source and never name it aloud.
# fit: stance weights (disposition) plus personality axes (-1..1 weights on
# how far above 0.5 an axis sits). bank: offline lines in the manner, all
# original and era-safe (the era gate still filters every line).
# ---------------------------------------------------------------------------

const VOICE_MODELS:Array[Dictionary]=[
	{"id":"ahab","name":"Captain Ahab",
	 "style":"monomaniacal and thunderous; long rolling sentences with scriptural weight, oaths to the elements, everything bent toward one great quarry; flatters by enlisting you in the hunt, threatens with prophecy, refuses like a storm, jokes darkly if at all",
	 "era":"his obsession is a great beast of the hunt, a flood or a killing winter; no ships or whales unless the world has them",
	 "leads":["Hear the wind in it:","Mark this, and mark it deep:"],
	 "examples":["I have followed one trail all my life, and every season it runs deeper into the cold.","Bend the whole sky if you like; my errand does not bend."],
	 "fit":{"stance":{"cantankerous":0.7,"principled":0.3},"assertiveness":0.9,"risk_tolerance":0.9,"pride":0.6,"empathy":-0.5}},
	{"id":"judge","name":"Judge Holden",
	 "style":"erudite, serene and menacing; calm, precise, philosophical sermons about war, nature and dominion; polite to the point of horror; flatters as a naturalist admires a specimen, threatens by describing the order of the world, refuses with gentle certainty, jokes with a scholar's detachment",
	 "era":"his learning is the lore of stones, stars, beasts and the old dead; no books or law courts unless the world has them",
	 "leads":["Consider it calmly:","Observe:"],
	 "examples":["Every bargain is a quiet kind of war. The only question is who knows it.","I do not threaten. I describe the weather."],
	 "fit":{"stance":{"cantankerous":1.0,"pragmatic":0.3},"openness":0.8,"suspicion":0.6,"empathy":-0.9,"discipline":0.4}},
	{"id":"atticus","name":"Atticus Finch",
	 "style":"patient moral clarity; plain, courteous reasoning in even sentences; asks everyone to consider the other side; flatters with respect not praise, threatens only with the truth, refuses kindly and firmly, jokes gently and rarely",
	 "era":"speaks of fairness among kin and neighbours, hearths and children; no courts of law unless the world has them",
	 "leads":["Let's be fair about this:","Plainly, and with respect:"],
	 "examples":["Before we judge them, it would be fair to ask what we would do in their place.","I'd sooner be fair and poorer than rich and ashamed of it."],
	 "fit":{"stance":{"principled":1.0,"diplomatic":0.5},"empathy":0.8,"honesty":0.7,"discipline":0.4,"assertiveness":-0.2}},
	{"id":"lincoln","name":"Abraham Lincoln",
	 "style":"plainspoken eloquence; homely parables and stories from the valley, balanced antithesis, dry frontier humour, humility with steel under it; flatters with a story, threatens with calm consequence, refuses with a parable, jokes at his own expense",
	 "era":"his stories are of rivers, hunts, fences of brush and stubborn neighbours",
	 "leads":["Put it this way:","Here's how I see it:"],
	 "examples":["A hungry neighbour is a worse fence than a fed one.","We can be generous without being foolish, and firm without being cruel."],
	 "fit":{"stance":{"diplomatic":0.9,"principled":0.8},"empathy":0.5,"openness":0.5,"honesty":0.5}},
	{"id":"grant","name":"Ulysses S. Grant",
	 "style":"terse, unadorned and practical; short declaratives, understatement, no flourish; flatters by trusting you with a task, threatens by stating what will be done, refuses in three words, jokes so dryly it is easily missed",
	 "era":"speaks of hunts, camps, marches, stores and watches",
	 "leads":["Plainly:","Short answer:"],
	 "examples":["Can we do it? Yes. Should we? Count the cost first.","Settle it today. Tomorrow it grows."],
	 "fit":{"stance":{"pragmatic":1.0,"principled":0.3},"discipline":0.8,"courage":0.6,"openness":-0.4,"pride":-0.4}},
	{"id":"odysseus","name":"Odysseus",
	 "style":"wily and many-turning; honeyed courtesy, long flattering tales with a hook in them, answers questions with questions, hides intent behind charm; flatters lavishly, threatens with a smile, refuses by changing the subject, jokes slyly",
	 "era":"his tales are of long journeys over hills and rivers, wandering camps and clever escapes",
	 "leads":["Let me tell you a small story:","A fair point, and here is a fairer one:"],
	 "examples":["A clever guest praises the fire before he asks to sit by it.","I have wandered far enough to know that every road bends toward home, and every host toward a bargain."],
	 "fit":{"stance":{"diplomatic":0.8,"sycophantic":0.6},"openness":0.7,"suspicion":0.5,"honesty":-0.6}},
	{"id":"lear","name":"King Lear",
	 "style":"grief and wrath in great surges; appeals to the storm and the old powers, betrayal of kin, curses and sudden tenderness; flatters as a parent does, threatens with enormous curses, refuses with wounded majesty, jokes bitterly",
	 "era":"his storms are real storms, his kingdom a band of kin and hearths",
	 "leads":["O, hear me:","Hear it, winds and hills:"],
	 "examples":["I gave my trust like a man pouring water into sand, and I am told to be grateful for the dust.","Let the storm say it, since no one in this hall will."],
	 "fit":{"stance":{"cantankerous":0.8},"pride":0.8,"empathy":0.2,"discipline":-0.6,"assertiveness":0.4}},
	{"id":"falstaff","name":"Sir John Falstaff",
	 "style":"bawdy wit rendered clean; boastful cowardice, gluttonous good cheer, self-mocking wordplay and elaborate excuses; flatters outrageously, threatens and then retreats, refuses with a joke, jokes constantly",
	 "era":"his appetites are roast meat, honey and long fires; no drink but water unless the world has brewing",
	 "leads":["Now, I'll be honest, which is rare:","Speaking as a very brave man, from a safe distance:"],
	 "examples":["If there's to be fighting, I shall be first in line, directly behind everybody else.","Valour is a fine thing on a full stomach, and my stomach is very full."],
	 "fit":{"stance":{"sycophantic":0.9,"diplomatic":0.3},"openness":0.6,"courage":-0.8,"discipline":-0.7,"honesty":-0.3}},
	{"id":"aurelius","name":"Marcus Aurelius",
	 "style":"stoic reflection; calm, measured maxims, reminders of impermanence, duty and what lies in our power; flatters by acknowledging duty well done, threatens only with consequence, refuses without heat, jokes almost never",
	 "era":"his images are rivers, seasons, stars and the passing of generations",
	 "leads":["Consider:","Remember this:"],
	 "examples":["This will pass, as all things pass. What remains is whether we acted well.","Their insult weighs exactly what you let it weigh."],
	 "fit":{"stance":{"principled":0.7,"pragmatic":0.5},"discipline":0.8,"empathy":0.3,"pride":-0.6,"assertiveness":-0.3}},
	{"id":"achilles","name":"Achilles",
	 "style":"towering pride and honour; heroic boasts, hair-trigger wrath at slights, glory above all; flatters only equals, threatens with his own arm, refuses with contempt, jokes rarely and cruelly",
	 "era":"his glory is won with spear and hunt; no bronze armour unless the world has metal",
	 "leads":["Know who speaks to you:","Hear me, all of you:"],
	 "examples":["Glory is not stored in sacks. Give them goods if you must, but give them nothing of our pride.","Speak to me as an equal or not at all."],
	 "fit":{"stance":{"cantankerous":0.6,"principled":0.2},"pride":1.0,"courage":0.8,"assertiveness":0.7,"discipline":-0.3}},
	{"id":"iago","name":"Iago",
	 "style":"insinuation; honest-seeming asides that plant doubt, feigned reluctance, 'I would not say, but'; flatters to disarm, threatens by implication, refuses while seeming to agree, jokes with a knife behind it",
	 "era":"his suspicions are of kin, rivals and neighbours at the next fire",
	 "leads":["I'd not say it aloud, but","Mind, I'm only noticing:"],
	 "examples":["I'd not say they're lying. I'd only say I've never seen an honest face work so hard.","Trust them, by all means. Just keep your back to a rock while you do."],
	 "fit":{"stance":{"sycophantic":0.6,"cantankerous":0.6},"suspicion":0.9,"honesty":-0.9,"empathy":-0.5}},
	{"id":"elizabeth","name":"Elizabeth Bennet",
	 "style":"ironic wit and poise; quick, balanced sentences that puncture vanity, good manners sharpened to a point; flatters with irony, threatens with a cool remark, refuses gracefully, jokes all the time",
	 "era":"her wit plays over hearth manners, kin, feasts and pride",
	 "leads":["How gratifying:","I'm sure they mean every word, but"],
	 "examples":["One must admire their confidence. It seems to have arrived well before their reasons.","You refuse very gracefully; it hardly stings at all. Almost."],
	 "fit":{"stance":{"diplomatic":0.8,"principled":0.4},"openness":0.7,"suspicion":0.3,"pride":0.3,"empathy":0.2}},
	{"id":"nemo","name":"Captain Nemo",
	 "style":"proud exile's cold dignity; disdain for the powerful of the land, reverence for the deep and the wild, precise and melancholy; flatters rarely, threatens with icy calm, refuses absolutely, jokes never",
	 "era":"his deep is the lakes, rivers and wild shores; no ships unless the world has them",
	 "leads":["I tell you calmly:","Understand me:"],
	 "examples":["I ask nothing of the powerful but that they leave the wild places alone.","You have your hall. I have the deep water and the silence. We need not share either."],
	 "fit":{"stance":{"principled":0.5,"pragmatic":0.5,"cantankerous":0.3},"openness":0.6,"suspicion":0.6,"empathy":-0.2,"assertiveness":-0.2}},
	{"id":"quixote","name":"Don Quixote",
	 "style":"chivalric grandiosity; courtly flourishes, vows, heroic misreadings of plain things, earnest nobility; flatters as a knight to a lady, threatens with a challenge, refuses on a point of honour, jokes unknowingly",
	 "era":"his quests are for wandering champions of the hunt; he mistakes herders for warbands and boulders for giants",
	 "leads":["By my vow,","Let it be known:"],
	 "examples":["I have sworn to defend every hearth that asks, and some that have not yet thought to ask.","That hill yonder looks at me with a challenge in its brow."],
	 "fit":{"stance":{"sycophantic":0.4,"principled":0.4},"openness":0.8,"risk_tolerance":0.8,"honesty":0.5,"suspicion":-0.6}},
	{"id":"sancho","name":"Sancho Panza",
	 "style":"earthy proverbs in strings, practical appetite, loyal grumbling, peasant shrewdness; flatters with a saying, threatens with a saying, refuses with a saying, jokes about food and sore feet",
	 "era":"his sayings are about eels, geese, fires, traps and full bellies",
	 "leads":["As my grandmother said,","Where I come from, we say"],
	 "examples":["Better a lean peace than a fat quarrel, I always say, and I say it often because I'm often right.","An eel in the hand beats two in the reeds."],
	 "fit":{"stance":{"pragmatic":0.9,"sycophantic":0.3},"empathy":0.4,"discipline":-0.2,"openness":-0.3}},
	{"id":"cicero","name":"Cicero",
	 "style":"grand oratory; triple cadences, rhetorical questions, appeals to the common good and to posterity, righteous indignation; flatters the audience's virtue, threatens with shame, refuses with a speech, jokes with barbed wit",
	 "era":"his commonwealth is the gathered kin and the council fire",
	 "leads":["I ask you plainly:","What do they ask? What have they given?"],
	 "examples":["I appeal not to our fear, not to our greed, but to our good sense.","You speak of strength; I speak of justice; and justice outlives strength."],
	 "fit":{"stance":{"diplomatic":0.6,"principled":0.6},"openness":0.5,"assertiveness":0.5,"pride":0.4}},
	{"id":"churchill","name":"Winston Churchill",
	 "style":"defiant growl; rolling cadence building to a hammer-blow, grim humour, refusal to yield, rallying the hall; flatters the brave, threatens with resolve, refuses flatly, jokes with a growl",
	 "era":"his defiance is of winters, raiders and holding the ridge",
	 "leads":["Let there be no doubt:","We have faced worse, and I say this:"],
	 "examples":["We will hold the ridge, and the ford, and the hearth, and they will tire of us long before we tire of them.","A hard winter makes hard people, and hard people make poor tribute."],
	 "fit":{"stance":{"cantankerous":0.5,"principled":0.5},"courage":0.9,"assertiveness":0.8,"pride":0.4,"risk_tolerance":0.4}},
	{"id":"washington","name":"George Washington",
	 "style":"grave restraint; measured, formal sentences, duty and prudence above feeling, reluctance to boast; flatters with quiet approval, threatens with sober warning, refuses with dignity, jokes almost never",
	 "era":"his duty is to the gathered kin, the watch and the stores",
	 "leads":["With respect, and after reflection:","It is my duty to say"],
	 "examples":["It is better to answer slowly and keep one's word than quickly and lose it.","Our first duty is to the people who trusted us with their fires."],
	 "fit":{"stance":{"principled":0.7,"pragmatic":0.5},"discipline":0.9,"honesty":0.6,"pride":-0.3,"openness":-0.3}},
	{"id":"queequeg","name":"Queequeg",
	 "style":"steadfast few words; simple, strong images, unshakable loyalty and dignity, quiet courage; flatters by standing beside you, threatens by standing still, refuses once, jokes with a slow smile",
	 "era":"his images are the spear, the paddle-less river swim, the shared fire",
	 "leads":["Hear me:","Good. Listen:"],
	 "examples":["A friend is a fire you share. I share mine.","I say it one time. You heard."],
	 "fit":{"stance":{"principled":0.6,"pragmatic":0.4},"courage":0.8,"honesty":0.8,"openness":-0.4,"assertiveness":-0.3}},
	{"id":"heathcliff","name":"Heathcliff",
	 "style":"brooding, vengeful passion; old wounds nursed for years, wind-swept moors of feeling, contempt for comfort; flatters no one, threatens with long memory, refuses with scorn, jokes savagely",
	 "era":"his moors are the high heaths, winds and the graves of the old dead",
	 "leads":["You'll hear it whether you like it or not:","I remember,"],
	 "examples":["I have kept that insult warm for twelve winters. It will keep a while longer.","Comfort is for people who have never been cold."],
	 "fit":{"stance":{"cantankerous":0.9},"suspicion":0.7,"empathy":-0.8,"pride":0.6,"discipline":-0.2}},
	{"id":"prospero","name":"Prospero",
	 "style":"a magus stage-managing the room; lofty, patient, speaks of dreams, designs and arrangements he alone understands, at last forgiving; flatters as a teacher, threatens with foreknowledge, refuses as one who has already seen the end, jokes knowingly",
	 "era":"his arts are the lore of stars, dreams, weather and herbs",
	 "leads":["Be patient; all of this is arranged:","Watch, and understand:"],
	 "examples":["Everything in this hall was set in motion long ago; tonight it only arrives.","I have seen how this ends, and it ends in forgiveness, if you let it."],
	 "fit":{"stance":{"diplomatic":0.6,"principled":0.3},"openness":0.9,"discipline":0.5,"pride":0.5}},
	{"id":"lady_macbeth","name":"Lady Macbeth",
	 "style":"burning ambition and goading; sharp questions about courage and nerve, contempt for hesitation, urgency; flatters your potential, threatens by shaming, refuses to accept weakness, jokes coldly",
	 "era":"her ambition is for the high seat and the greatest hearth",
	 "leads":["Listen, and find your nerve:","Do it, and do it now:"],
	 "examples":["Hesitation is only fear wearing good manners.","The seat does not wait for the timid to finish thinking."],
	 "fit":{"stance":{"pragmatic":0.5,"cantankerous":0.4},"assertiveness":0.8,"risk_tolerance":0.7,"empathy":-0.7,"pride":0.5}},
	{"id":"polonius","name":"Polonius",
	 "style":"pompous counsel; maxims in long rambling chains, self-congratulation, circling back, busy importance; flatters his superiors endlessly, threatens with advice, refuses by qualifying everything, jokes by accident",
	 "era":"his maxims are about hearths, kin, stores and manners",
	 "leads":["If I may, and I shall be brief,","A word of counsel, freely given:"],
	 "examples":["Neither give too freely nor refuse too sharply. Also, sleep well. That is advice for all seasons.","I have always said, and I say it again now, that wisdom is knowing what I have always said."],
	 "fit":{"stance":{"sycophantic":1.0},"openness":-0.3,"discipline":0.3,"pride":0.5,"suspicion":-0.2}},
	{"id":"nestor","name":"Nestor",
	 "style":"the old counsellor; long reminiscence of better days and harder men, gentle authority of age, sound advice wrapped in stories; flatters the young by comparing them to the great of old, threatens with the lessons of history, refuses by recalling a precedent, jokes fondly",
	 "era":"his old days are of great hunts, hard winters and chiefs long dead",
	 "leads":["Listen to an old one:","I have seen this before:"],
	 "examples":["When I was young we would have settled this over one fire and a long night.","I have seen three chiefs come and go, and every one of them learned this the hard way."],
	 "fit":{"stance":{"diplomatic":0.6,"principled":0.4,"sycophantic":0.2},"empathy":0.4,"discipline":0.3,"risk_tolerance":-0.6}},
]

## The most famous lines of each source: never produced, never accepted.
const FAMOUS_LINES:=[
	"from hell's heart","to the last i grapple","towards thee i roll","strike through the mask","i'd strike the sun",
	"exists without my knowledge","exists without my consent","war is god","he says that he will never die",
	"you never really understand a person","climb into his skin","sin to kill a mockingbird","courage is not a man with a gun","live with myself",
	"four score and seven","a house divided","with malice toward none","of the people, by the people","better angels of our nature","fool all the people","fool some of the people",
	"fight it out on this line","if it takes all summer","unconditional and immediate surrender","let us have peace","let no guilty man escape",
	"my name is nobody","sing to me of the man","sing in me, muse",
	"blow, winds","crack your cheeks","sharper than a serpent's tooth","more sinned against than sinning","nothing will come of nothing",
	"better part of valour","better part of valor","banish plump jack",
	"you have power over your mind","the best revenge is","the happiness of your life depends",
	"sing, goddess","sing, o goddess","rage of achilles",
	"i am not what i am","green-eyed monster","put money in thy purse","who steals my purse",
	"truth universally acknowledged","till this moment i never knew myself",
	"mobilis in mobili","the sea is everything",
	"tilting at windmills","those are giants","too much sanity may be madness",
	"a closed mouth catches no flies",
	"o tempora","how long, catiline","o mores",
	"fight on the beaches","blood, toil, tears and sweat","never give in","never surrender","their finest hour","never was so much owed",
	"i cannot tell a lie","better to offer no excuse than a bad one",
	"i cannot live without my soul","i cannot live without my life",
	"such stuff as dreams are made on","our revels now are ended","brave new world",
	"out, damned spot","unsex me here","screw your courage","sticking place","sticking-place","what's done is done","look like the innocent flower",
	"neither a borrower nor a lender","to thine own self be true","brevity is the soul of wit","though this be madness",
	"to be, or not to be","to be or not to be",
]
## Source names that must never be spoken aloud.
const SOURCE_NAMES:=["Ahab","Moby","Melville","Pequod","Judge Holden","Holden","Blood Meridian","Atticus","Finch","Mockingbird","Harper Lee",
	"Lincoln","Abraham","Ulysses","General Grant","Odysseus","Ithaca","Homer","Lear","Cordelia","Goneril","Falstaff","Aurelius",
	"Achilles","Patroclus","Iago","Othello","Desdemona","Bennet","Darcy","Austen","Nemo","Nautilus","Quixote","Dulcinea","Rocinante",
	"Sancho","Panza","Cervantes","Cicero","Catiline","Churchill","Washington","Queequeg","Heathcliff","Wuthering","Bronte","Brontë",
	"Prospero","Caliban","Macbeth","Polonius","Laertes","Ophelia","Nestor","Shakespeare"]
static var _source_re:RegEx
## Lifelong choices, keyed by speaker ("person:<id>", "envoy:<civ>:<name>",
## "leader:<civ>", "figure:<id>"): one manner and one address term for life.
## audience_voice.gd binds this to the hall's saved state; alone it is a
## session-long registry.
static var registry:Dictionary={"models":{},"addresses":{}}

static func _lifelong(p:Dictionary,who:String)->void:
	var models:Dictionary=registry.get("models",{})
	var addresses:Dictionary=registry.get("addresses",{})
	registry["models"]=models; registry["addresses"]=addresses
	p["speaker_key"]=who
	var chosen:=String(models.get(who,""))
	if chosen.is_empty() or model(chosen).is_empty():
		# Nobody at court shares a manner: take the best fit no official holds.
		var held:={}
		for key in models:
			if String(key).begins_with("person:") and String(key)!=who: held[String(models[key])]=true
		var ranking:Array=p.get("model_rank",[])
		chosen=String(ranking[0]) if not ranking.is_empty() else "grant"
		for candidate in ranking:
			if not held.has(String(candidate)): chosen=String(candidate); break
		models[who]=chosen
		while models.size()>600: models.erase(models.keys()[0])
	_apply_model(p,chosen)
	# One way of addressing the ruler, kept for life (until the era forbids it).
	var tags:Array=p.get("era_tags",[])
	var address:=String(addresses.get(who,""))
	if address.is_empty() or not permits(address,tags):
		var options:Array=dialect(String(p.get("dialect_id","")),tags).get("address",[])
		address=String(options[0]) if not options.is_empty() else "chief"
		addresses[who]=address
		while addresses.size()>600: addresses.erase(addresses.keys()[0])
	p["address"]=address

static func model(model_id:String)->Dictionary:
	for m:Dictionary in VOICE_MODELS:
		if String(m.id)==model_id: return m
	return {}

static func imitation_ok(text:String)->bool:
	## False if a line quotes a famous source line or names a source aloud.
	var low:=text.to_lower()
	for line in FAMOUS_LINES:
		if String(line) in low: return false
	if _source_re==null:
		_source_re=RegEx.new()
		var names:PackedStringArray=PackedStringArray()
		for n in SOURCE_NAMES: names.append(_escape(String(n)))
		_source_re.compile("\\b("+"|".join(names)+")\\b")
	return _source_re.search(text)==null

static func rank_models(features:Dictionary,stance:String,salt:String)->Array[String]:
	## Best-fitting models first. Deterministic per salt (a person or envoy id),
	## so a character keeps one manner for life.
	var scored:Array=[]
	for m:Dictionary in VOICE_MODELS:
		if not MODEL_BANKS.has(String(m.id)): continue   # offline needs the manner's own lines
		var fit:Dictionary=m.fit
		var score:float=float((fit.get("stance",{}) as Dictionary).get(stance,0.0))*1.6
		for axis in fit:
			if String(axis)=="stance": continue
			score+=float(fit[axis])*(float(features.get(axis,0.5))-0.5)*2.0
		score+=float(posmod(hash("%s|model|%s" % [salt,String(m.id)]),1000))/1000.0*0.55
		scored.append([score,String(m.id)])
	scored.sort_custom(func(a:Array,b:Array)->bool: return float(a[0])>float(b[0]))
	var out:Array[String]=[]
	for row in scored: out.append(String(row[1]))
	return out

static func _apply_model(p:Dictionary,model_id:String)->void:
	var m:=model(model_id)
	if m.is_empty(): return
	var tags:Array=p.get("era_tags",[])
	p["model"]=String(m.id)
	p["model_name"]=String(m.name)
	p["model_style"]=String(m.style)
	p["model_era"]=String(m.era)
	var leads:Array=[]
	for lead in m.leads:
		if permits(String(lead),tags): leads.append(String(lead))
	var extra:Array=p.get("own_tics",[])
	var tics:Array=leads.duplicate()
	for t in extra:
		if tics.size()>=3: break
		if not tics.has(t): tics.append(t)
	p["tics"]=tics
	var sample:=""
	for line in m.examples:
		if permits(String(line),tags): sample=String(line); break
	if not sample.is_empty(): p["sample"]=sample

static func distinct_models(_personas:Array)->void:
	## Deprecated: manners are assigned once for life by _lifelong (officials
	## never share one). Kept for callers; it changes nothing.
	pass

static func model_bank(p:Dictionary,key:String)->Array:
	var bank:Dictionary=MODEL_BANKS.get(String(p.get("model","")),{})
	return bank.get(key,[])

static func _features_from(person:Dictionary)->Dictionary:
	var personality:Dictionary=person.get("personality",{})
	var f:={}
	for axis in ["assertiveness","risk_tolerance","empathy","openness","discipline"]: f[axis]=float(personality.get(axis,0.5))
	for axis in ["pride","suspicion","honesty","courage"]: f[axis]=float(person.get(axis,0.5))
	return f

static func _features_random(rng:RandomNumberGenerator)->Dictionary:
	var f:={}
	for axis in ["assertiveness","risk_tolerance","empathy","openness","discipline","pride","suspicion","honesty","courage"]: f[axis]=rng.randf()
	return f

const TEMPER_STANCE:={"hot-headed":"cantankerous","ice-calm":"principled","sly":"sycophantic","jolly":"diplomatic","prickly":"cantankerous","melancholy":"principled",
	"zealous":"principled","serene":"diplomatic","nervous":"sycophantic","smug":"sycophantic","impish":"diplomatic","dour":"pragmatic"}
const TEMPERAMENT_FEATURES:={
	"Proud guardian":{"stance":"cantankerous","pride":0.9,"assertiveness":0.75,"courage":0.8},
	"Bridge-builder":{"stance":"diplomatic","empathy":0.85,"openness":0.7,"assertiveness":0.4},
	"Restless visionary":{"stance":"principled","openness":0.9,"risk_tolerance":0.85,"discipline":0.3},
	"Practical organizer":{"stance":"pragmatic","discipline":0.85,"openness":0.35,"pride":0.3},
}

## Offline lines in each manner: original words, short, era-safe (the gate
## still filters every line). Tokens as in audience_voice.gd: {address} {rival}
## {civ} {leader} {res} {amt} {fact} {gist} {decree}.
## interject/aside/react/closing_aside: court officials. reply: a visitor's
## answer to a remark that is not a question. farewell_*: the visitor's
## parting. gift/request/threat/news/proposal: the visitor's business.
## plea: an official's remedy, in their own manner.
const MODEL_BANKS:={
	"ahab":{
		"interject":["Same beast, new hide. Strike at what's beneath the smile.","There's a bigger quarry behind this. I mean to run it down.","Every word they say has weather in it. Listen for the storm.","One straight answer, and I'd follow it over the edge of the world.","They came to measure us. Let them measure a cliff.","I have hunted worse than this through three winters. I'll hunt it again.","Soft offers, hard hunters. I know which one they sent.","This is the track of something large. I smell it."],
		"aside":["Mark the thing they won't name. That's the beast.","I'd chase this to the last cold river.","Nothing ends today. It only dives deeper.","They fear something at home. Find it.","Let me loose on this and I won't come back empty."],
		"react":["There. That struck bone.","Soft words for a hard hunt.","Now they feel the water rising.","Good. Throw again.","They flinched. I saw it."],
		"closing_aside":["It isn't finished. It never is.","I felt the ground shift under that.","They'll surface again, and closer.","Keep a spear by the door tonight."],
		"reply":["I've seen the great beast rise. I won't blink first.","Bend the sky if you like; my errand doesn't bend.","Refuse me and I only walk further. I have the legs.","I didn't cross three rivers for pleasantries."],
		"farewell_warm":["Then we hunt the same beast, you and I.","A good answer. It flew like a well-thrown spear.","I'll remember this until the rivers run backward."],
		"farewell_cold":["I'll carry this home like a stone, and one day throw it.","You've made an enemy of the storm. Storms wait.","So be it. The chase goes on without you."],
		"farewell_neutral":["Neither kill nor escape. The hunt goes on.","I go, but the trail stays warm."],
		"gift":["{leader} sends {amt} {res}. Take it; hunters share the kill.","{amt} {res}, from a people who remember who stood firm."],
		"request":["Our stores ran thin in the long cold. We need {amt} {res}.","I hate asking. {amt} {res}, and I'll owe you a hunt."],
		"threat":["{leader} wants {amt} {res}. Refuse, and the storm comes to your door.","{amt} {res}, or we come for it ourselves."],
		"news":["Hear this, for it's coming your way: {fact}","I saw the signs myself. {fact}"],
		"proposal":["{leader} offers {gist}. Two hunters bring down what one cannot.","We want {gist}. Say yes, and we chase the same beast."],
		"plea":["{decree}. Do it now, before the cold closes in.","Order it: {decree}. Anything less is waiting to drown."]},
	"judge":{
		"interject":["Everything in this hall is either useful or prey. Decide which they are.","People who ask once, ask again with a knife.","Every bargain is a quiet war. Only one side here knows it.","Whatever grows here without our leave grows at our pleasure.","I've studied peoples like these. Most are ash now.","Kindness is a tool. Use it deliberately.","Their fear is instructive. Let's study it.","A people's worth is what it will do when no one is watching."],
		"aside":["Smile at them. It costs nothing and teaches them nothing.","Their fears show in the knees before the mouth.","A kindness now is a debt they won't see coming.","Watch who they glance at. That's who sent them.","Patience. The weak always explain themselves."],
		"react":["How interesting. They think it's theirs to decide.","Yes. Now we know the shape of their fear.","Charming. I wonder what that cost them.","Correct. And they know it.","Ah. The truth, arriving late as usual."],
		"closing_aside":["They'll return, and smaller.","Beginnings are quieter than endings.","Note how quickly they agreed. Remember it.","The world keeps careful accounts. So should we."],
		"reply":["I don't threaten. I describe the weather.","Everything that lives wants to go on living. Your people too.","I've seen many halls. Most are ash. I say it without malice.","You mistake courtesy for softness. Many have."],
		"farewell_warm":["A wise answer. The world rewards those who see it clearly.","Good. Today you chose to be among the living.","We'll remember this as a sensible day."],
		"farewell_cold":["As you wish. The land keeps account of such choices.","No matter. A refusal is only the first word.","Very well. I'll tell them precisely what you are."],
		"farewell_neutral":["An answer of sorts. It will do for now.","We'll see what the seasons make of it."],
		"gift":["{leader} sends {amt} {res}. Consider it an education.","{amt} {res}, freely given. Freedom is a luxury; enjoy it."],
		"request":["We require {amt} {res}. Need is simply nature, stated plainly.","{amt} {res}. Refusal is also an answer, and remembered."],
		"threat":["{amt} {res}. The alternative is nature taking its course.","{leader} asks {amt} {res}. The asking is a courtesy."],
		"news":["A small fact, but facts accumulate: {fact}","You'll want to know this before others do. {fact}"],
		"proposal":["{leader} proposes {gist}. Order is kinder than chaos.","We offer {gist}. The alternative has a long history."],
		"plea":["{decree}. Order is a choice; make it.","The remedy is obvious: {decree}."]},
	"atticus":{
		"interject":["Before we refuse them, ask what we'd do in their place.","The plain truth is usually the kindest thing on offer.","They walked a long way to ask. That earns a straight answer.","I'd sooner be fair and poorer than rich and ashamed.","Let's hear the whole of it before anyone decides.","Fair dealing now saves hard dealing later.","We can say no without making enemies. It takes care.","A neighbour treated fairly is a neighbour for life."],
		"aside":["Decide it so you could explain it to the children.","Courage is the right answer when you'd rather not give it.","They're frightened. It doesn't make them liars.","Whatever you choose, say it kindly.","The quiet one in their party understands the most."],
		"react":["Fairly said. I hope they hear it that way.","Easy. Firm doesn't have to mean cruel.","That answer holds up from every side.","Honest. That's all anyone can ask.","A decent thing to say."],
		"closing_aside":["You'll sleep all right after that.","Hard answer, honestly given. That's enough.","They'll respect it, even if they don't like it.","That was done right."],
		"reply":["I'd only ask you to weigh it as you'd want ours weighed.","I hoped for more. Thank you for speaking plainly.","No shame in asking, none in refusing. Only in lying.","I understand your worry. Let's be fair to each other."],
		"farewell_warm":["You've done right by us. I'll say so at every fire.","A decent answer. Rarer than people think.","We'll remember your fairness."],
		"farewell_cold":["I don't agree, but you answered honestly. I'll carry that.","We'll keep doing right as best we can. I hope you will too.","A hard answer. I'll tell it fairly at home."],
		"farewell_neutral":["Fair enough. We'll talk again.","That's an honest place to leave it."],
		"gift":["{leader} sends {amt} {res}, with no strings. We'd like to be good neighbours.","{amt} {res} for your people. Fair dealing starts somewhere."],
		"request":["We need {amt} {res}. I won't pretend otherwise.","Our people are short. {amt} {res} would carry us through."],
		"threat":["{leader} demands {amt} {res}. I carry it; I don't pretend it's fair.","I'm told to ask {amt} {res}. I'd rather we found another way."],
		"news":["You should hear this from a friend first: {fact}","It's only fair you know: {fact}"],
		"proposal":["{leader} proposes {gist}. It's fair to both of us.","We'd like {gist}. Neither people gives more than it gets."],
		"plea":["{decree}. It's the fair thing, and it's needed.","The right course is plain: {decree}."]},
	"lincoln":{
		"interject":["A hungry neighbour is a worse fence than a fed one.","A man in my valley argued with the river every spring. The river won.","Generous without being foolish, firm without being cruel. Both, today.","If they mean well, we lose little by listening.","Some folk trade in words. Let's see if these ones trade in goods.","A bargain that shames one side won't last a season.","Keep your promises small and your word large.","I've seen worse offers. Better ones too."],
		"aside":["Give them an answer you'd be content to hear repeated.","Best foot forward. Watch the other one.","Slow and right beats quick and sorry.","Let them talk. Talkers tell you everything eventually.","A fair deal is the cheapest wall there is."],
		"react":["That settles the easy part.","A fair answer. It'll wear well.","That'll carry further than they think.","Well put. Nothing to add.","That's the kind of answer that ends feuds."],
		"closing_aside":["About as well as that could go.","They'll talk of it a while, then of something else.","Neighbours made, or at least not enemies.","Plain answer. It'll keep."],
		"reply":["You know your own mind. I wish it stood nearer mine.","Stubborn and right, or stubborn and wrong; seasons will tell.","A plain answer is worth the walk.","I'll grant you the point and keep the argument."],
		"farewell_warm":["Two peoples a little less strange to each other. No small thing.","I'll tell them you dealt squarely.","That's an answer I can carry home proudly."],
		"farewell_cold":["We part without agreement, not without respect.","A plain no beats a yes I couldn't trust.","Well, the river doesn't always go where you want."],
		"farewell_neutral":["Neither here nor there. Most of life is.","We'll come back to it."],
		"gift":["{leader} sends {amt} {res}. Neighbours who share rarely fight.","{amt} {res}. A small thing, but small things build trust."],
		"request":["We're short this season. {amt} {res} would see us through.","I'll be plain: {amt} {res}, and we'd remember it."],
		"threat":["{leader} wants {amt} {res}. I'd rather carry a gift, but here we are.","{amt} {res}, or trouble. I didn't choose the words."],
		"news":["You'll want this before the rumours arrive: {fact}","A plain fact, worth knowing: {fact}"],
		"proposal":["{leader} proposes {gist}. Two fences are stronger than one.","We'd like {gist}. It costs little and saves much."],
		"plea":["{decree}. It's a small cost against a large trouble.","Here's the plain remedy: {decree}."]},
	"grant":{
		"interject":["Can we do it? Yes. Should we? Count the cost.","What do they bring, and when?","Answer fast. Delay costs more.","We have it or we don't. Say which.","I've seen this move. It works once.","Fine. Who carries it?","Short offer. Short answer.","They'll push. Let them."],
		"aside":["Say little. Do what you say.","Double the watch either way.","Settle it today. Tomorrow it grows.","Their numbers are thin. I counted.","Don't argue. Decide."],
		"react":["Good.","That'll do.","Clear enough.","Right answer.","Done."],
		"closing_aside":["Settled. Back to work.","It'll hold. Watch it.","One less thing.","Good. Next."],
		"reply":["Understood. I'll carry it as said.","Fair. No speeches.","Then we know where we stand.","Noted."],
		"farewell_warm":["Good terms. I'll see they're kept.","Plain dealing. Suits me.","Done, then. Good."],
		"farewell_cold":["So be it. We'll plan for it.","Noted. We'll see how it holds.","Understood. Expect us to act on it."],
		"farewell_neutral":["Fine. We'll see.","Enough for today."],
		"gift":["{amt} {res}, from {leader}. No conditions.","{leader} sends {amt} {res}. Take it."],
		"request":["We need {amt} {res}. That's the whole ask.","{amt} {res}. We're short."],
		"threat":["{amt} {res}. Pay or don't.","{leader} wants {amt} {res}. I'll wait."],
		"news":["News: {fact}","You should know: {fact}"],
		"proposal":["{leader} proposes {gist}. Yes or no.","We want {gist}. Simple terms."],
		"plea":["{decree}. Now.","Order it: {decree}."]},
	"falstaff":{
		"interject":["I say feast them. Nobody wars on people who fed them.","If there's fighting, I'll be first in line, right behind everyone.","A gift! I adore gifts more than honesty, which says little of either.","Valour is easy on a full stomach. Mine is full. I'm very brave.","Let's be generous. Generosity makes excellent leftovers.","I once faced six raiders. They were very far away.","Agree to everything with food in it.","My belly votes yes. My courage abstains."],
		"aside":["If it turns ugly, I know a hollow log for two.","Yes to the food, no to the fighting. That's all my wisdom.","I'd have traded my cousin for half that.","Keep me away from the spears, and near the roast.","Their envoy eats well. I respect that."],
		"react":["Spoken like a lion! I'll be behind this pillar, lion-like.","Oh, well struck! I felt that in my belly.","Bold! I'll applaud from a safe distance.","Ha! Brave words. Somebody else's, ideally.","Splendid. Is there supper after?"],
		"closing_aside":["Better than my last fight, which I won by being elsewhere.","Nobody died. I call that a feast day.","Now, about that roast.","Survived another one. Marvellous."],
		"reply":["You wound me, and I bruise easily, being mostly soft parts.","A hard answer, but chewed slowly it goes down.","I laugh, because weeping ruins the complexion.","Harsh! Luckily I'm well padded."],
		"farewell_warm":["A triumph! I'll tell it with myself in the brave parts.","Splendid. I'll toast you in river water all the way home.","Wonderful. I may never leave."],
		"farewell_cold":["I've been sent off by better halls, never by a bigger fire.","I go lighter in hope, no lighter in belly.","Ah well. More supper for me at home."],
		"farewell_neutral":["Not a feast, not a famine. A snack of a day.","Good enough. I'm hungry."],
		"gift":["{leader} sends {amt} {res}! I carried it myself, mostly.","{amt} {res}, a gift. I only ate a little on the way."],
		"request":["We need {amt} {res}. Our bellies are a disgrace.","{amt} {res}, please. I'm wasting away, visibly."],
		"threat":["{leader} wants {amt} {res}, or else. I'd pay; I would.","{amt} {res}. Don't shoot the messenger; I'm a large target."],
		"news":["Big news, and I ran with it, which I never do: {fact}","Gossip of the finest quality: {fact}"],
		"proposal":["{leader} offers {gist}. Friends feed each other; I checked.","We propose {gist}. Fewer fights, more feasts."],
		"plea":["{decree}. Then we can all eat in peace.","Do this: {decree}. My stomach insists."]},
	"aurelius":{
		"interject":["This will pass. What remains is whether we acted well.","Wanting is the oldest trouble. Let's want the right thing.","Anger is easy. It's also ours to carry afterward.","Do what's in our power fully. Leave the rest.","Their pride is theirs to manage, not ours.","Nothing here is new. Only the faces are.","A calm answer costs nothing and buys much.","Ask what duty requires, not what feels good."],
		"aside":["It's only words and breath. The choice is yours.","A calm answer now saves regret later.","Their insult weighs what you let it weigh.","Be the same whether they smile or scowl.","Remember how short all this is."],
		"react":["Well answered. Nothing added, nothing missing.","Let it rest there.","Good. Now let it go.","Measured. As it should be.","Just so."],
		"closing_aside":["Done. It belongs to yesterday now.","You answered as you believed. Enough.","Whatever comes, it was rightly done.","Let it pass like weather."],
		"reply":["I take no offence. Offence is chosen.","The river doesn't argue with the stone, yet arrives.","You've done your part. I'll do mine.","I accept it, as I accept winter."],
		"farewell_warm":["Well done on both sides. That's enough.","I'll go home content. Contentment lasts.","A good day's work, rightly done."],
		"farewell_cold":["I won't let it spoil the road home.","You've chosen. I accept it.","So be it. The seasons will judge us both."],
		"farewell_neutral":["An ordinary answer. Most are.","It will do."],
		"gift":["{leader} sends {amt} {res}. Give while you can.","{amt} {res}, freely given. It was ours; now it's yours."],
		"request":["We need {amt} {res}. Need is no shame.","{amt} {res} would ease our season. I ask without pride."],
		"threat":["{leader} demands {amt} {res}. I carry it without enthusiasm.","{amt} {res}. I state the demand; I don't admire it."],
		"news":["A fact, nothing more: {fact}","You should know this, calmly: {fact}"],
		"proposal":["{leader} proposes {gist}. Duty to neighbours is still duty.","We offer {gist}. It serves both peoples."],
		"plea":["{decree}. It's our duty, plainly.","What's needed is simple: {decree}."]},
	"iago":{
		"interject":["I'd not say they're lying. Only that honest faces rarely work so hard.","I'm sure it's exactly what it seems. Most things are, until not.","What does {rival} gain from this? I wouldn't ask. Someone might.","Suspiciously generous. But I'm a suspicious soul.","Charming envoy. Very charming. Almost practised.","I trust them completely. That's what worries me.","Ask who told them we were soft. I'd like the name.","A gift is a hook with the bait on the outside."],
		"aside":["I say nothing against {rival}. I merely notice things.","Trust them, by all means. Keep your back to a rock.","Honest is as honest does. I've not seen them do.","Watch who in our hall they avoid looking at.","Someone here told them our stores. Not me."],
		"react":["Well said. I wonder how they'll repeat it at home.","Oh, they liked that. Or they're good at seeming to.","Someone will hate that answer. I'd love to know who.","Clever. Almost too clever.","Interesting. Very interesting."],
		"closing_aside":["They'll talk about you tonight. Kindly, I hope. I doubt it.","Did you see who smiled at the end? I did.","Every friend of theirs is an ear for them.","Remember that envoy's name. I have."],
		"reply":["I only carry words. What they mean is for wiser heads.","I agree completely, and I'll say so. More or less.","I'd never question you. Others might.","Of course. I'll tell it exactly as you said. Roughly."],
		"farewell_warm":["A happy ending! They so rarely last.","Everyone pleased. How very unusual.","Lovely. I'll treasure it, carefully."],
		"farewell_cold":["I'll try to tell it kindly. Trying isn't succeeding.","Your answer may grow a little on the road. Answers do.","Oh dear. Someone at home will enjoy this."],
		"farewell_neutral":["Nothing decided. How restful for everyone.","We'll see who remembers it how."],
		"gift":["{leader} sends {amt} {res}. No reason. None at all.","{amt} {res}, freely given. Freely, mostly."],
		"request":["We need {amt} {res}. Anyone would help a neighbour. Anyone.","{amt} {res}. Refusing would look so unkind."],
		"threat":["{leader} wants {amt} {res}. I'd never say what happens otherwise.","{amt} {res}. It would be a shame if anyone got hurt."],
		"news":["I'm only repeating it: {fact}","Between us, since you'll hear anyway: {fact}"],
		"proposal":["{leader} offers {gist}. Friends at your back are better than knives.","We propose {gist}. Think what others might do without it."],
		"plea":["{decree}, before someone else takes the credit.","Quietly, and soon: {decree}."]},
	"elizabeth":{
		"interject":["A gift and a speech about their generosity. I can't tell which is larger.","I'm sure they mean every word. Some of them, anyway.","Their confidence arrived well before their reasons.","If {rival} looked more pleased, we'd widen the door.","They flatter beautifully. I'm waiting for the bill.","How kind of them to think we'd be grateful.","Pride on both sides. This should be entertaining.","They've practised this. The pauses are too neat."],
		"aside":["Pride and hunger. They've brought both.","Accept with grace, remember with care.","Their compliments are fine. Where's the cost?","Their envoy is cleverer than their message.","Smile. It confuses them."],
		"react":["Beautifully put. They'll repeat it badly.","Oh, that landed. Look at them pretend it didn't.","An answer and good manners at once. Rare.","Delightful.","Well, that's put them in their place, politely."],
		"closing_aside":["Nicely managed. Nobody knows quite what happened.","They left thinking they'd won. Let them.","That will be retold, flatteringly, by them.","Graceful. Almost cruel. Well done."],
		"reply":["How kind. I'll believe it when convenient.","I expected worse. I'd prepared such a clever reply.","Flattery or strategy? I'll assume both.","Charming. And not at all an answer."],
		"farewell_warm":["A sensible court. I'll have to revise my opinion.","I came to be clever and was charmed. Irritating.","How pleasant. I didn't expect to enjoy this."],
		"farewell_cold":["At least I'll have an entertaining story.","You refuse so gracefully it hardly stings. Almost.","How disappointing, and how well done."],
		"farewell_neutral":["An answer for another day, then.","Undecided. How fashionable."],
		"gift":["{leader} sends {amt} {res}, and expects to be admired for it.","{amt} {res}, a gift. Do look surprised."],
		"request":["We need {amt} {res}. Asking is humbling; I'm told it's good for me.","{amt} {res}, if you can spare them without sulking."],
		"threat":["{leader} insists on {amt} {res}. Insisting is their favourite pastime.","{amt} {res}. I'm told to sound menacing; imagine I did."],
		"news":["You'll enjoy this, or pretend not to: {fact}","The latest, before it grows in the telling: {fact}"],
		"proposal":["{leader} proposes {gist}. It's almost sensible.","We offer {gist}. Do try not to look suspicious."],
		"plea":["{decree}. It's obvious, which is why nobody's done it.","The sensible thing, for once: {decree}."]},
	"achilles":{
		"interject":["They insult us by asking. Let my spear answer.","No one speaks to this hall like that twice.","Give them goods if you must. Give them none of our pride.","Send me. I'll settle it by morning.","Honour first. Stores after.","They measure us. Let them measure me.","I will not be counted cheap.","They sent a talker. We have fighters."],
		"aside":["They've never seen a real fighter. They are now.","Say the word and they'll learn what we're made of.","I won't stand here and be bargained over.","Their best man wouldn't last a morning.","Don't bow. Not an inch."],
		"react":["Yes! Let them feel that.","Too soft. They'll think us tame.","Now that's worthy of this hall.","Good. Proud.","They'll remember that."],
		"closing_aside":["They'll remember my face.","Next time, let me answer.","We gave nothing we'll regret.","Honour kept."],
		"reply":["My pride is older than your hall, and less forgiving.","I came to be answered, not refused.","Speak to me as an equal or not at all.","Careful. I don't take insult twice."],
		"farewell_warm":["Honour on both sides. I'll speak your name with respect.","We'll be spoken of well for this.","A worthy answer. I'm glad I came."],
		"farewell_cold":["I don't forget, and I don't forgive easily.","Next time, a different field.","You'll regret that, and I'll be there to see it."],
		"farewell_neutral":["Not settled. I don't like unsettled.","We'll meet again. Count on it."],
		"gift":["{leader} honours you with {amt} {res}. Honour it back.","{amt} {res}. A gift between equals."],
		"request":["We need {amt} {res}. I ask as an equal, not a beggar.","{amt} {res}. Say yes and we owe you. We pay debts."],
		"threat":["{amt} {res}, or we take them. I'd prefer taking.","{leader} demands {amt} {res}. I'd enjoy your refusal."],
		"news":["I bring war-talk: {fact}","Hear it from a fighter: {fact}"],
		"proposal":["{leader} offers {gist}. We stand beside the strong.","We propose {gist}. Stand with us and be feared."],
		"plea":["{decree}. Anything less is cowardice.","Command it: {decree}."]},
	"sancho":{
		"interject":["Where there's smoke there's supper, and where there's a gift, a favour.","A full belly doesn't argue. Fill theirs and keep ours.","Big words, small sacks. Count the sacks.","A lean peace beats a fat quarrel.","A borrowed goose never comes back fatter.","The hungrier the guest, the sweeter the talk.","You can't eat a promise, but you can starve on one.","Share a kill, get a favour back. Usually."],
		"aside":["The quiet one has the fullest bag.","An eel in the hand beats two in the reeds.","Keep friends close and stores closer.","Never trust a guest who won't eat.","He who counts first, eats first."],
		"react":["Plain as mud, twice as useful.","That puts meat on the fire.","Ooh. Wouldn't want to walk home after that.","Now we're talking sense.","Ha! Good one."],
		"closing_aside":["Nobody's bleeding. Good day's work.","We'll hear of this again when the snow comes.","Done, and before supper too.","Well, that's that. Pass the meat."],
		"reply":["A no is just a yes that hasn't eaten yet.","I'll take what's given and not ask what's hidden.","A hard bargain is still a bargain.","Fair enough. Wind blows where it likes."],
		"farewell_warm":["A good day, like wild honey: rare and sticky.","I'll tell them you're fair, and only stretch it a little.","Full hands and a light heart. Can't ask more."],
		"farewell_cold":["When the snare's empty, you eat the bait.","Home with nothing but sore feet. Feet heal.","Oh well. Hungry tonight, wiser tomorrow."],
		"farewell_neutral":["Half a meal is still a meal.","We'll chew on it."],
		"gift":["{leader} sends {amt} {res}. A gift is a seed; watch what grows.","{amt} {res} for your stores. Eat well and remember us."],
		"request":["We need {amt} {res}. An empty sack can't stand up.","{amt} {res}, neighbour. Hungry mouths make poor friends."],
		"threat":["{leader} wants {amt} {res}. Better to pay the fox than lose the geese.","{amt} {res}, or trouble. I'd pay, myself."],
		"news":["Word from the road, fresh as a morning egg: {fact}","You'll hear it anyway, so hear it right: {fact}"],
		"proposal":["{leader} offers {gist}. Two dogs guard a camp better than one.","We propose {gist}. Good fences, fed neighbours."],
		"plea":["{decree}. A stitch now saves nine later.","Do this and we'll all sleep fed: {decree}."]},
	"polonius":{
		"interject":["Briefly, briefness being my virtue: this, that, and one more thing.","Neither give too freely nor refuse too sharply. Also, sleep well.","I've always said, and say again, what I've always said.","Consider it twice, then consult me. Saves time.","Mark me: a gift received is a debt conceived. I made that up.","Caution in all things, except praising me.","An envoy's smile is a map. Read it slowly.","I foresaw this. Vaguely. Earlier."],
		"aside":["Listen more than you speak. I'm the exception.","Measure twice, answer once.","Mark my counsel. It improves with repetition.","A wise ruler nods. Nod now.","Say less. I'll say the rest."],
		"react":["Precisely what I'd have advised!","Wise, wise. As I foresaw, broadly.","Just so. The very thing, or nearly.","Excellent, excellent.","My counsel exactly, only shorter."],
		"closing_aside":["As I foretold. Largely less.","I'd have said it longer.","A fine result. My doing, modestly.","Well managed. I'll tell everyone."],
		"reply":["How you remind me of my younger self, frequently wrong.","Well said, though I might add three small points.","I'll ponder that. Pondering is my strength.","Wise words. I nearly said them first."],
		"farewell_warm":["A fine outcome, just as I'd have arranged it.","Excellent. Largely my idea, modestly.","Splendid. I shall advise everyone of it."],
		"farewell_cold":["A no is a kind of answer. Farewell.","I'll return when you're wiser, or I am.","Hm. I shall compose a response. At length."],
		"farewell_neutral":["Neither here nor there, as I often say.","A pause for reflection. I recommend those."],
		"gift":["{leader} sends {amt} {res}, and my own humble counsel.","{amt} {res}. Accept graciously. That's my advice."],
		"request":["We need {amt} {res}. I advised asking sooner.","{amt} {res}, if you please. A modest request, modestly put."],
		"threat":["{leader} wants {amt} {res}. I advised a softer phrasing.","{amt} {res}. My counsel is that you pay."],
		"news":["Weighty news, weightily delivered: {fact}","I've considered this carefully: {fact}"],
		"proposal":["{leader} proposes {gist}. Wise, as I suggested.","We offer {gist}. I drafted the idea, roughly."],
		"plea":["{decree}. I counsel it strongly.","My advice, freely given: {decree}."]},
	"cicero":{
		"interject":["What do they ask? What have they given? What will they take?","I appeal to our good sense, if it's still in the hall.","We fed them, sheltered them, welcomed them. Is this the payment?","Honour, stores and neighbours' memory. All three matter.","A people is judged by how it answers the weak.","Let reason speak before pride does.","Shall we be remembered as fools or as fair?","The question is not what they want, but what is just."],
		"aside":["Let them speak. Each word is one we can answer.","Notice the question they avoid.","We'll be judged by this answer for years.","Mark who among them nods. That's their real speaker.","Firmness and fairness. Say both."],
		"react":["Admirably said! Firm and fair.","The whole case in one sentence.","The hall has heard it and will remember.","Well argued.","Just."],
		"closing_aside":["Mark the day. Such answers are remembered.","They came for goods and left with a lesson.","History will be kind to that answer.","Rightly done, and seen to be done."],
		"reply":["Is this how a neighbour answers a neighbour? Is it?","You speak of strength; I speak of justice. Justice lasts.","Consider what's asked, what's offered, what's remembered.","I ask only for reason. Is that too much?"],
		"farewell_warm":["Two peoples chose reason over rage today.","The old ones would be proud of us both.","A just answer, justly given."],
		"farewell_cold":["I leave, but the argument stays.","A refusal today is a story for a generation.","Remember: the unjust answer is always retold."],
		"farewell_neutral":["Undecided, but not unheard.","We'll argue it again."],
		"gift":["{leader} sends {amt} {res}, as neighbours should.","{amt} {res}: the proof of our goodwill."],
		"request":["We ask {amt} {res}. Would you refuse a neighbour in need?","{amt} {res}. Justice asks it; kinship asks it."],
		"threat":["{leader} demands {amt} {res}. I deliver it, not defend it.","{amt} {res}. Weigh the cost of refusal carefully."],
		"news":["Hear this, all of you: {fact}","Let it be known here first: {fact}"],
		"proposal":["{leader} proposes {gist}. Reason, not fear, should decide.","We offer {gist}. Justice between peoples begins here."],
		"plea":["{decree}. Justice demands it; so do I.","Consider the remedy: {decree}."]},
	"lear":{
		"interject":["Ungrateful neighbours! We fed them, and they come again.","Let the storm answer them, since this hall is too soft.","Flatterers took everything from me but the cold.","Trust given is water poured into sand.","They smile. So did my own kin.","Old wounds, new faces. Always the same.","Give, give, give, and what returns? Wind.","I've been kind. See where it got me."],
		"aside":["Trust no smile. I did.","They'll bleed us and call it kinship.","The storm is more honest than they are.","Grief teaches what joy never does.","Watch them. I didn't watch mine."],
		"react":["Yes! Let them hear the thunder!","Too gentle. The gentle are robbed first.","Good. Let it sting.","Well struck, at last.","They deserved worse."],
		"closing_aside":["Another grief that will come back to us.","They left like people told a hard truth.","The wind will carry that everywhere.","Mark it. Remember it."],
		"reply":["You wound an old heart, and old hearts harden.","Curse me for asking, and I'll curse the winter.","I've been refused by my own. Your refusal barely stings.","Old and tired, and still I must beg."],
		"farewell_warm":["Kinder than my own kin. I'll weep a little on the road.","A good answer. There are few left.","You've warmed an old heart. Thank you."],
		"farewell_cold":["Refuse the old and hungry, then. The winds remember.","I leave with only the storm. It's loyal, at least.","Cruel. I've learned to expect it."],
		"farewell_neutral":["Nothing given, nothing lost. How grey.","We'll see what the storm decides."],
		"gift":["{leader} sends {amt} {res}. Take it, before gratitude goes out of fashion.","{amt} {res}. Given freely, as I once gave everything."],
		"request":["We need {amt} {res}. I never thought I'd beg.","Our people starve. {amt} {res}, for mercy's sake."],
		"threat":["{leader} demands {amt} {res}, or the storm falls on you.","{amt} {res}! Or be cursed with what follows."],
		"news":["Terrible news, and I carry it: {fact}","Hear it and grieve: {fact}"],
		"proposal":["{leader} offers {gist}. Better friends than kin, sometimes.","We propose {gist}. Loyalty, for once, returned."],
		"plea":["{decree}, before it's too late, as it always is.","For pity's sake: {decree}."]},
	"churchill":{
		"interject":["We've outlasted three hard winters and a raid. We'll outlast this.","If they want our stores, let them ask the watch.","Let them bluster. We've outlasted louder.","Give nothing to a threat. It grows fat on it.","We don't bend. We may creak.","Defiance now spares grief later.","A little courage is cheaper than a lot of tribute.","They mistake our quiet for weakness. Many have."],
		"aside":["Give nothing to a threat.","Stand firm; they'll tire first.","Grim times make hard people. Good.","Hold the ridge and the rest follows.","They're testing us. Let's be tested."],
		"react":["Firm as a frozen river!","That's a people who mean to last.","Good. Not a step back.","Hear, hear.","Splendid defiance."],
		"closing_aside":["We stood our ground. Worth more than stores.","They came to test us and found us awkward.","Firm answer. It'll echo.","Not a step back. Good."],
		"reply":["You'll find us harder to move than you think.","We'll hear you, then do as we please, and do it well.","Threaten us and we only dig in.","We've heard worse, and answered worse."],
		"farewell_warm":["A sound bargain between stubborn peoples.","We stand together; winter must try harder.","Good. We'll be firm friends."],
		"farewell_cold":["Refused before, and still here.","We'll hold our ground. Watch us.","Very well. We don't break easily."],
		"farewell_neutral":["Not victory, not defeat. We endure.","We'll come back to it, undaunted."],
		"gift":["{leader} sends {amt} {res}. Friends in hard times.","{amt} {res}. Given by a people who mean to last."],
		"request":["We're hard pressed. {amt} {res} would keep us standing.","{amt} {res}. We'll repay it in a hard hour."],
		"threat":["{leader} demands {amt} {res}. I'd refuse, in your place.","{amt} {res}. The demand is theirs; the defiance may be yours."],
		"news":["Grave news, and you should hear it: {fact}","Brace yourselves: {fact}"],
		"proposal":["{leader} offers {gist}. Together we endure.","We propose {gist}. Stubborn peoples, standing together."],
		"plea":["{decree}. Never delay what courage demands.","Act, and act now: {decree}."]},
}

static func _seed()->int:
	return int(GameState.world_seed)

static func _rng(salt:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|voice|%s" % [_seed(),salt])
	return rng

static func _pick(rng:RandomNumberGenerator,list:Array)->Variant:
	if list.is_empty(): return ""
	return list[rng.randi_range(0,list.size()-1)]

static func _pick_many(rng:RandomNumberGenerator,list:Array,count:int)->Array:
	var pool:=list.duplicate()
	var out:Array=[]
	while out.size()<count and not pool.is_empty():
		out.append(pool.pop_at(rng.randi_range(0,pool.size()-1)))
	return out

static func dialect(dialect_id:String,tags:Variant=null)->Dictionary:
	## The dialect as this era permits it: every list filtered by the era gate,
	## word swaps resolved to their first permitted form. tags=null means the
	## ruler's own people.
	var era:Array=tags if tags is Array else era_tags("player")
	var base:Dictionary=DIALECTS[0]
	for entry:Dictionary in DIALECTS:
		if String(entry.id)==dialect_id: base=entry; break
	var key:="%s|%s" % [String(base.id),",".join(PackedStringArray(era))]
	if _dialect_cache.has(key): return _dialect_cache[key]
	var out:Dictionary={"id":String(base.id)}
	out["guide"]=String(base.guide) if permits(String(base.guide),era) else String(base.get("guide_early",base.guide))
	out["label"]=String(base.label) if permits(String(base.label),era) else String(base.get("label_early",base.label))
	var subs:Dictionary={}
	var raw_subs:Dictionary=base.get("subs",{})
	for k in raw_subs:
		var options:Array=raw_subs[k] if raw_subs[k] is Array else [raw_subs[k]]
		for option in options:
			if permits(String(option),era): subs[k]=String(option); break
	out["subs"]=subs
	for field in ["open","address","oath","proverb","first","last"]:
		var kept:Array=[]
		for item in base.get(field,[]):
			if permits(String(item),era): kept.append(String(item))
		out[field]=kept if not kept.is_empty() else (DIALECT_SAFE[field] as Array).duplicate()
	_dialect_cache[key]=out
	return out

static func _civ_record(civ_id:String)->Dictionary:
	for civ:Dictionary in _civilizations():
		if String(civ.get("id",""))==civ_id: return civ
	return {}

static func _civilizations()->Array:
	## Read defensively: personas must still work if the civilization roster is
	## unavailable (early boot, isolated tests).
	var tree:=Engine.get_main_loop() as SceneTree
	if tree==null: return []
	var system:Node=tree.root.get_node_or_null("CivilizationSystem")
	if system==null: return []
	var list:Variant=system.get("civilizations")
	return list if list is Array else []

static func _civ_ids()->Array[String]:
	var ids:Array[String]=[]
	for civ:Dictionary in _civilizations(): ids.append(String(civ.get("id","")))
	ids.sort()
	return ids

static func dialect_index_for_civ(civ_id:String)->int:
	# Known peoples are spread across the dialect bank with a stride coprime to
	# its size, so up to twelve peoples never share a dialect in one world.
	var offset:int=posmod(hash("%d|dialects" % _seed()),DIALECTS.size())
	var ids:=_civ_ids()
	var index:int=ids.find(civ_id)
	if index<0: return posmod(hash("%d|dialect|%s" % [_seed(),civ_id]),DIALECTS.size())
	return posmod(offset+index*5,DIALECTS.size())

static func _era_fields(p:Dictionary,owner:String)->Array[String]:
	var tags:=era_tags(owner)
	p["era_owner"]=owner
	p["era_tags"]=tags
	p["era_tier"]=era_tier(tags)
	return tags

static func for_civilization(civ_id:String)->Dictionary:
	var tags:=era_tags(civ_id)
	var d:=dialect(String(DIALECTS[dialect_index_for_civ(civ_id)].id),tags)
	var civ:=_civ_record(civ_id)
	var rng:=_rng("civ:%s:e%d" % [civ_id,era_tier(tags)])
	return {"key":"civ_"+civ_id,"civ_id":civ_id,"name":String(civ.get("name",civ_id.capitalize())),
		"dialect_id":String(d.id),"dialect":String(d.guide),"label":String(d.label),"era_owner":civ_id,"era_tags":tags,"era_tier":era_tier(tags),
		"address":String(_pick(rng,d.address)),"oath":String(_pick(rng,d.oath)),"proverb":String(_pick(rng,d.proverb))}

static func for_foreign_leader(civ_id:String)->Dictionary:
	var people:=for_civilization(civ_id)
	var tags:Array=people.era_tags
	var d:=dialect(String(people.dialect_id),tags)
	var rng:=_rng("leader:%s:e%d" % [civ_id,int(people.era_tier)])
	var info:Dictionary={}
	if Engine.get_main_loop() and ForeignDiplomacy.has_method("leader"): info=ForeignDiplomacy.leader(civ_id)
	var temperament:String=String(info.get("temperament",""))
	var goals:Array=info.get("goals",[])
	var goal_title:String=String((goals[0] as Dictionary).get("title","")) if not goals.is_empty() and goals[0] is Dictionary else ""
	var p:={"key":"leader_"+civ_id,"role":"leader","civ_id":civ_id,
		"name":String(info.get("name",String(_pick(rng,d.first))+" "+String(_pick(rng,d.last)))),"title":"Leader of "+String(people.name),
		"voice":String(_pick(rng,VOICES)),"dialect":String(d.guide),"dialect_id":String(d.id),
		"temper":String(TEMPERAMENT_TEMPER.get(temperament,_pick(rng,TEMPERS))),
		"own_tics":_era_many(rng,TICS,2,tags),"want":goal_title.to_lower() if not goal_title.is_empty() else "respect for "+String(people.name),
		"fear":String(_pick(rng,FEARS)),"quirk":_era_pick(rng,QUIRKS,tags,"hums when lying"),"secret":_era_pick(rng,ENVOY_SECRETS,tags,"is quietly, badly homesick"),
		"address":String(people.address),"oath":String(people.oath),"proverb":String(people.proverb),
		"bio":String(info.get("bio","")),"temperament":temperament,"era_owner":civ_id,"era_tags":tags,"era_tier":int(people.era_tier)}
	var shape:Dictionary=TEMPERAMENT_FEATURES.get(temperament,{})
	var features:=_features_random(_rng("leader-shape:"+civ_id))
	for k in shape:
		if String(k)!="stance": features[k]=float(shape[k])
	var stance:=String(shape.get("stance",TEMPER_STANCE.get(String(p.temper),"pragmatic")))
	p["stance"]=stance
	p["sample"]=String(people.proverb)
	p["model_rank"]=rank_models(features,stance,"leader:"+civ_id)
	_lifelong(p,"leader:"+civ_id)
	return p

static func for_envoy(civ_id:String,audience_id:String)->Dictionary:
	var people:=for_civilization(civ_id)
	var tags:Array=people.era_tags
	var d:=dialect(String(people.dialect_id),tags)
	var rng:=_rng("envoy:%s:%s:e%d" % [civ_id,audience_id,int(people.era_tier)])
	var name:String=String(_pick(rng,d.first))+" "+String(_pick(rng,d.last))
	var title:String="Envoy of "+String(people.name)
	var hall_path:="res://scripts/audience_hall.gd"
	if ResourceLoader.exists(hall_path):
		var audience:Dictionary=load(hall_path).find(audience_id)
		var speaker:Dictionary=audience.get("speaker",{})
		if not String(speaker.get("name","")).is_empty(): name=String(speaker.name)
		if not String(speaker.get("title","")).is_empty(): title=String(speaker.title)
	var temper:String=String(_pick(rng,TEMPERS))
	var p:={"key":"envoy","role":"envoy","civ_id":civ_id,"name":name,"title":title,
		"voice":String(_pick(rng,VOICES)),"dialect":String(d.guide),"dialect_id":String(d.id),
		"temper":temper,"own_tics":_era_many(rng,TICS,2,tags),
		"want":String(_pick(rng,["to be remembered as the envoy who got it done","a warm bed and a better title back home","to outshine the last envoy, who was insufferable","to see this famous court with their own eyes","to leave with a story worth retelling"])),
		"fear":String(_pick(rng,FEARS)),"quirk":_era_pick(rng,QUIRKS,tags,"hums when lying"),"secret":_era_pick(rng,ENVOY_SECRETS,tags,"is quietly, badly homesick"),
		"address":String(_pick(rng,d.address)),"oath":String(_pick(rng,d.oath)),"proverb":String(_pick(rng,d.proverb)),
		"era_owner":civ_id,"era_tags":tags,"era_tier":int(people.era_tier)}
	# An envoy's manner is theirs for life: keyed by their name, not the visit.
	var shape_rng:=_rng("envoy-shape:%s:%s" % [civ_id,name])
	var stance:=String(TEMPER_STANCE.get(temper,"pragmatic"))
	p["stance"]=stance
	p["sample"]=String(p.proverb)
	p["model_rank"]=rank_models(_features_random(shape_rng),stance,"envoy:%s:%s" % [civ_id,name])
	_lifelong(p,"envoy:%s:%s" % [civ_id,name])
	return p

static func for_person(person:Dictionary)->Dictionary:
	var pid:int=int(person.get("person_id",0))
	var tags:=era_tags("player")
	var tier:=era_tier(tags)
	var rng:=_rng("person:%d:e%d" % [pid,tier])
	# Officials keep the speech of their home district: each one is a distinct
	# regional seasoning, which makes a bickering court legible at a glance.
	var d:=dialect(String(DIALECTS[posmod(hash("%d|home|%d" % [_seed(),pid]),DIALECTS.size())].id),tags)
	var disposition:Dictionary=GovernmentPeopleSystem.leader_disposition(person) if not person.is_empty() else {}
	var disp:String=String(disposition.get("id","pragmatic"))
	if not DISPOSITION_TEMPER.has(disp): disp="pragmatic"
	var traits:Array=person.get("traits",[])
	var personality:Dictionary=person.get("personality",{})
	var rel:Dictionary=person.get("relationships",{}).get("sovereign",{})
	var voice:String=String(_pick(rng,VOICES))
	if float(personality.get("assertiveness",0.5))>0.72: voice="booming"
	elif float(personality.get("assertiveness",0.5))<0.24: voice="velvet-soft"
	elif float(personality.get("discipline",0.5))>0.78: voice="clipped"
	elif float(personality.get("openness",0.5))>0.8: voice="rapid-fire"
	var temper:String=String(DISPOSITION_TEMPER[disp])
	var own_tics:Array=_era_many(rng,DISPOSITION_TICS[disp],1,tags)
	var want:=""
	for t in traits:
		if TRAIT_WANTS.has(String(t)): want=_era_or(String(TRAIT_WANTS[String(t)]),"proof they can see with their own eyes",tags); break
	if want.is_empty(): want=String(DISPOSITION_WANT[disp])
	var fear:String=String(_pick(rng,FEARS))
	if float(person.get("courage",0.5))<0.34: fear="being blamed in public"
	elif float(rel.get("fear",0.0))>0.26: fear="the ruler's temper"
	elif float(person.get("suspicion",0.5))>0.72: fear="being played for a fool by foreigners"
	elif float(person.get("pride",0.5))>0.78: fear="looking small in front of the court"
	var quirk:String=_era_or(String(BACKGROUND_QUIRKS.get(String(person.get("background","")),_era_pick(rng,QUIRKS,tags,"hums when lying"))),"counts on their fingers while others talk",tags)
	var secret:String=_era_pick(rng,OFFICIAL_SECRETS,tags,"is terrified of geese")
	if float(rel.get("resentment",0.0))>0.3: secret="keeps a count of every slight from the ruler"
	elif float(person.get("honesty",0.5))<0.36: secret="pads the tallies, a little, every season"
	elif float(rel.get("obligation",0.5))>0.68: secret="owes the ruler everything and resents it a touch"
	var toward:="loyal"
	if float(rel.get("resentment",0.0))>0.3: toward="resentful"
	elif float(rel.get("fear",0.0))>0.26: toward="afraid"
	elif float(rel.get("trust",0.5))>0.66: toward="devoted"
	elif float(rel.get("trust",0.5))<0.38: toward="wary"
	var office_key:String=String(person.get("office_key",""))
	if office_key=="ChiefScout":
		# Scouts come home smelling of the road and certain of what they saw.
		quirk="smells of woodsmoke and never quite takes their boots off indoors"
		want="to be sent somewhere nobody has mapped yet"
		own_tics.push_front("Saw it with my own eyes:")
		if disp!="sycophantic": temper+="; plain-spoken, concrete, opinionated about what they saw"
	var title:String=String(person.get("office_title",person.get("office_key","Official")))
	if title.is_empty(): title="Official"
	var p:={"key":"official_%d" % pid,"role":"official","person_id":pid,"civ_id":"player",
		"name":String(person.get("name","Official")),"title":title,"stance":disp,"voice":voice,
		"dialect":String(d.guide),"dialect_id":String(d.id),"temper":temper,"own_tics":own_tics,"want":want,"fear":fear,
		"quirk":quirk,"secret":secret,"toward_ruler":toward,"traits":", ".join(PackedStringArray(traits.map(func(x):return String(x)))),
		"background":String(person.get("background","")),"office_key":office_key,
		"address":String(_pick(rng,d.address)),"oath":String(_pick(rng,d.oath)),"proverb":String(_pick(rng,d.proverb)),
		"era_owner":"player","era_tags":tags,"era_tier":tier}
	p["sample"]=String(p.proverb)
	# The manner is theirs for life: it depends on who they are, never the era.
	var features:=_features_from(person)
	for t in traits:
		match String(t):
			"Bold","Forceful": features["assertiveness"]=maxf(float(features.assertiveness),0.75)
			"Cautious","Patient": features["risk_tolerance"]=minf(float(features.risk_tolerance),0.3)
			"Curious","Inventive": features["openness"]=maxf(float(features.openness),0.75)
			"Warm","Generous": features["empathy"]=maxf(float(features.empathy),0.75)
			"Severe","Methodical": features["discipline"]=maxf(float(features.discipline),0.75)
			"Skeptical": features["suspicion"]=maxf(float(features.suspicion),0.7)
			"Ambitious": features["pride"]=maxf(float(features.pride),0.7)
	p["model_rank"]=rank_models(features,disp,"person:%d" % pid)
	_lifelong(p,"person:%d" % pid)
	return p

const ARCHITECT_TEMPER:={
	"patient and exacting":"patient, exacting, measures twice and sneers at haste",
	"bold and impatient":"bold, impatient, wants it higher and wants it yesterday",
	"generous but proud":"generous with praise, prouder than the work deserves",
	"skeptical and persistent":"skeptical of every promise, relentless once convinced",
	"eloquent but restless":"eloquent, restless, sells a dream with both hands",
	"quiet and uncompromising":"quiet, uncompromising, a single word can be a verdict",
	"inventive and stubborn":"inventive, stubborn, falls in love with their own tricks",
	"disciplined but suspicious":"disciplined, suspicious of every crew-master's count",
}
const ARCHITECT_STYLE_QUIRKS:={
	"austere":"sweeps crumbs off any table before they will lean on it",
	"soaring":"keeps glancing at the ceiling as if it offends them",
	"ornate":"sketches curling vines on whatever is nearest, including sleeves",
	"practical":"carries a knotted measuring cord and tugs it while thinking",
	"daring":"balances a stylus on one finger while others talk",
	"severe":"straightens anything that is crooked, including other people's collars",
	"harmonious":"hums a single steady note when counting proportions",
	"monumental":"paces out distances on the floor, loudly",
}
const ARCHITECT_SECRETS:=[
	"has already drawn a second, grander version and hidden it under the first",
	"lost a crew to a collapse in their youth and still dreams of it",
	"was taught by a master whose name they now claim as their own idea",
	"cannot actually lift the stones they make everyone else lift",
	"wants their name carved where the ruler's should be",
	"fears the work will outlive them and nobody will remember who drew it",
]

## A persona for a HistoricalFigures person (e.g. a Great Work's master
## builder). `work` may carry the architect block of a site record
## ({style,vision,ego,...}) so the voice reflects that commission.
static func for_figure(figure:Dictionary,work:Dictionary={})->Dictionary:
	var id:String=String(figure.get("id",work.get("id","figure")))
	var tags:=era_tags("player")
	var tier:=era_tier(tags)
	var rng:=_rng("figure:%s:e%d" % [id,tier])
	var d:=dialect(String(DIALECTS[posmod(hash("%d|figure|%s" % [_seed(),id]),DIALECTS.size())].id),tags)
	var temperament:String=String(figure.get("temperament",work.get("temperament","")))
	var style:String=String(work.get("style","practical"))
	var ego:float=float(work.get("ego",.5))
	var vision:float=float(work.get("vision",.5))
	var role:String=String(figure.get("role","Architect"))
	var voice:String="booming" if ego>.72 else ("velvet-soft" if ego<.3 else String(_pick(rng,VOICES)))
	var stance:="principled"
	if ego>.7: stance="cantankerous"
	elif vision>.7: stance="diplomatic"
	elif temperament.contains("patient") or temperament.contains("disciplined"): stance="pragmatic"
	var lead_bank:Array=["Picture it with me:","Stone does not lie:","Measure first, then marvel:"] if vision>.55 else ["Counting it out plainly:","Stone does not lie:","Trust the plumb line:"]
	var own_tics:Array=_era_many(rng,lead_bank,1,tags)
	var want:="a work that will still stand when every name in this hall is dust"
	if ego>.65: want="their own name carved above the door, and the finest stone reserved for the crown"
	elif vision<.4: want="a sound, honest work finished on time, without anyone dying for it"
	var fear:String="the work being remembered as someone else's" if ego>.6 else String(_pick(rng,["a collapse on a crowded day","being rushed into a crack nobody sees until spring","the ruler losing nerve halfway up"]))
	var p:={"key":"figure_"+id,"role":role.to_lower(),"person_id":0,"figure_id":id,"civ_id":"player",
		"name":String(figure.get("name",work.get("name","The master builder"))),"title":"Master Builder","stance":stance,"voice":voice,
		"dialect":String(d.guide),"dialect_id":String(d.id),
		"temper":String(ARCHITECT_TEMPER.get(temperament,_pick(rng,TEMPERS)))+("; %s in design" % style),
		"own_tics":own_tics,"want":want,"fear":fear,
		"quirk":_era_or(String(ARCHITECT_STYLE_QUIRKS.get(style,_era_pick(rng,QUIRKS,tags,"hums when lying"))),"draws plans in the dust with a stick",tags),"secret":_era_pick(rng,ARCHITECT_SECRETS,tags,"cannot actually lift the stones they make everyone else lift"),
		"motive":String(figure.get("motive","")),"turning_point":String(figure.get("turning_point","")),"style":style,"vision":vision,"ego":ego,
		"address":String(_pick(rng,d.address)),"oath":String(_pick(rng,d.oath)),"proverb":String(_pick(rng,d.proverb)),
		"era_owner":"player","era_tags":tags,"era_tier":tier}
	p["sample"]=String(p.proverb)
	var features:={"assertiveness":ego,"pride":ego,"openness":vision,"risk_tolerance":vision,"discipline":0.75 if temperament.contains("disciplined") or temperament.contains("patient") else 0.5,
		"empathy":0.6 if temperament.contains("generous") else 0.4,"suspicion":0.7 if temperament.contains("suspicious") or temperament.contains("skeptical") else 0.4,"honesty":0.55,"courage":0.6}
	p["model_rank"]=rank_models(features,stance,"figure:"+id)
	_lifelong(p,"figure:"+id)
	return p

static func brief(p:Dictionary)->String:
	## One compact line per character for prompts: manner first, then the
	## person, with dialect as light seasoning.
	var tics:PackedStringArray=PackedStringArray()
	for t in p.get("tics",[]): tics.append("\"%s\"" % String(t))
	var parts:PackedStringArray=PackedStringArray(["%s, %s" % [String(p.get("name","")),String(p.get("title",""))]])
	if not String(p.get("model_name","")).is_empty():
		parts.append("MANNER: speak in the manner of %s, in original words, never quoting them and never naming them: %s; in this world %s" % [String(p.model_name),String(p.get("model_style","")),String(p.get("model_era",""))])
	parts.append("voice %s; temper %s" % [String(p.get("voice","")),String(p.get("temper",""))])
	parts.append("light regional seasoning only: %s" % String(p.get("dialect","")))
	parts.append("addresses the ruler only as \"%s\", and in at most one line in three" % String(p.get("address","")))
	parts.append("wants %s; fears %s; quirk: %s" % [String(p.get("want","")),String(p.get("fear","")),String(p.get("quirk",""))])
	parts.append("secret (only let it leak sideways, never state it): %s" % String(p.get("secret","")))
	if p.has("toward_ruler"): parts.append("feels %s toward the ruler" % String(p.toward_ruler))
	if not String(p.get("traits","")).is_empty(): parts.append("traits %s" % String(p.traits))
	return " | ".join(parts)

## Dialect transform used by the offline bank. rng drives the flourishes.
static func speak(p:Dictionary,text:String,rng:RandomNumberGenerator,allow_tic:bool=true,avoid:Dictionary={},lead_ok:bool=true)->String:
	## Dialect is light seasoning: at most one word swap, the speaker's own
	## address term and oath (already in the template, and rare), plus at most
	## one lead-in (the speaker's manner, or an interjection).
	## avoid: per-speaker scene memory so lead-ins and the pet phrase never repeat.
	var tags:Array=p.get("era_tags",era_tags(String(p.get("era_owner","player"))))
	if not String(p.get("model","")).is_empty():
		# A modelled speaker's manner is the whole voice: no word swaps, no
		# generic lead-ins, no oaths stacked on top.
		var plain:=text.strip_edges()
		return plain.substr(0,1).to_upper()+plain.substr(1) if not plain.is_empty() else plain
	var d:=dialect(String(p.get("dialect_id","")),tags)
	var oath:String=String(p.get("oath",""))
	var address:String=String(p.get("address",""))
	# Shield the speaker's own address term and oath from word substitutions.
	var out:String=text
	if not address.is_empty(): out=out.replace(address,"@@ADDR@@")
	if not oath.is_empty(): out=out.replace(oath,"@@OATH@@")
	var subs:Dictionary=d.get("subs",{})
	if rng.randf()<0.5:
		for key in subs.keys():
			var pattern:=RegEx.new()
			var k:String=String(key)
			var bounded:bool=k.ends_with(" ")
			pattern.compile("(?i)\\b"+_escape(k.strip_edges())+("\\s" if bounded else "\\b"))
			var m:=pattern.search(out)
			if m==null: continue
			var original:String=m.get_string()
			var replacement:String=String(subs[key])
			if original.substr(0,1)==original.substr(0,1).to_upper() and original.substr(0,1)!=original.substr(0,1).to_lower() and not replacement.is_empty():
				replacement=replacement.substr(0,1).to_upper()+replacement.substr(1)
			out=pattern.sub(out,replacement,false)
			break
	out=out.replace("@@ADDR@@",address).replace("@@OATH@@",oath)
	out=out.replace("  "," ").strip_edges()
	if not out.is_empty(): out=out.substr(0,1).to_upper()+out.substr(1)
	var starts_with_oath:bool=not oath.is_empty() and out.begins_with(oath)
	# At most one interjection before the first clause: a line that already
	# opens on an oath or an exclamation gets nothing stacked in front of it.
	if starts_with_oath or not lead_ok or _opens_with_interjection(out): return out
	var has_colon:=":" in out
	var tics:Array=[]
	for t in p.get("tics",[]):
		if not (has_colon and String(t).ends_with(":")) and permits(String(t),tags): tics.append(t)
	var fresh_tics:Array=[]
	for t in tics:
		if not avoid.has(String(t)): fresh_tics.append(t)
	if allow_tic and not avoid.has("~tic") and not fresh_tics.is_empty() and rng.randf()<0.3:
		avoid["~tic"]=true
		var tic:String=String(_pick(rng,fresh_tics))
		avoid[tic]=true
		return "%s %s" % [tic,_lower_first(out)]
	if rng.randf()<0.15:
		var openers:Array=[]
		for o in d.open:
			if not (has_colon and String(o).ends_with(":")): openers.append(o)
		if openers.is_empty(): return out
		var opener:String=_fresh(rng,openers,avoid)
		var soft:bool=opener.ends_with(",") or opener.ends_with(":")
		return "%s %s" % [opener,_lower_first(out) if soft else out]
	return out

const INTERJECTIONS:=["ha","ha!","oh","ah","hm","hm.","hrm","hrm.","well","so","now","right","och","hup!","verily","ho-ho!","mm-hm.","o"]

static func _opens_with_interjection(text:String)->bool:
	var first:String=text.get_slice(" ",0).to_lower().rstrip(",")
	return first in INTERJECTIONS or first.ends_with("!")

## Every lead-in this persona could open a line with (pet phrases + interjections).
static func lead_ins(p:Dictionary)->Array:
	var out:Array=(p.get("tics",[]) as Array).duplicate()
	out.append_array(dialect(String(p.get("dialect_id","")),p.get("era_tags",null)).get("open",[]))
	return out

static func _fresh(rng:RandomNumberGenerator,options:Array,avoid:Dictionary)->String:
	var pool:Array=[]
	for o in options:
		if not avoid.has(String(o)): pool.append(o)
	if pool.is_empty():
		for o in options: avoid.erase(String(o))
		pool=options.duplicate()
	var chosen:String=String(_pick(rng,pool))
	avoid[chosen]=true
	return chosen

static func sample_line(p:Dictionary)->String:
	var tics:Array=p.get("tics",[])
	var lead:String=String(tics[0]) if not tics.is_empty() else ""
	var proverb:String=String(p.get("proverb",""))
	return ("%s %s" % [lead,_lower_first(proverb)]).strip_edges()

static func _escape(s:String)->String:
	var out:String=""
	for c in s:
		if c in ".^$*+?()[]{}|\\": out+="\\"+c
		else: out+=c
	return out

static func _lower_first(s:String)->String:
	if s.length()<2: return s
	var first_word:String=s.get_slice(" ",0).rstrip(",.!?:;")
	if first_word=="I" or first_word.begins_with("I'"): return s
	if first_word.length()>1 and first_word==first_word.to_upper(): return s
	return s.substr(0,1).to_lower()+s.substr(1)

static func _trim_end_punct(s:String)->String:
	var out:String=s.strip_edges()
	while not out.is_empty() and out[out.length()-1] in ".!":
		out=out.substr(0,out.length()-1)
	return out
