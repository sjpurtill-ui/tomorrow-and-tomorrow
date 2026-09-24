extends RefCounted
## Deterministic personas for audience-hall speech. Nothing here is saved: every
## persona is re-derived from the world seed plus stable ids (civ id, person id,
## audience id), and officials additionally from their live traits, disposition,
## personality axes, background and relationship to the ruler.
##
## Persona = {"key","name","voice","dialect","tics":[String],"want","fear","quirk",
##            "secret","temper","sample"} plus helper fields ("dialect_id",
##            "address","oath","proverb","role","title","toward_ruler","stance").
##
## Dialects are invented fictional speech styles for invented peoples.

const DIALECTS:Array[Dictionary]=[
	{"id":"highland_burr","label":"Highland burr",
	 "guide":"rolling highland burr: aye, ken, wee, cannae, dinnae, och, bairns, auld; weather-and-stone sayings",
	 "subs":{"good":"braw","know":"ken","small":"wee","little":"wee","can't":"cannae","cannot":"cannae","don't":"dinnae","won't":"willnae","isn't":"isnae","you":"ye","your":"yer","children":"bairns","old":"auld","from":"frae","nothing":"naught"},
	 "open":["Och,","Aye, well,","Hark,","Now then,"],
	 "address":["chief","ma chief"],"oath":["By the cold cairns!","Stones and sleet!"],
	 "proverb":["A wee leak sinks a big boat.","Ye cannae milk a stone, however hard ye squeeze.","Fair words butter nae turnips."],
	 "first":["Brannoch","Ailveth","Kester","Mhorain","Duncair","Isbeth"],"last":["of the Crags","Stanehollow","Greymantle","Fernburr"]},
	{"id":"river_patter","label":"River-trader patter",
	 "guide":"clipped river-trader patter: drops little words, doubles for emphasis (sure-sure, quick-quick), prices and weighs everything, calls the ruler friend-chief",
	 "subs":{"quickly":"quick-quick","good":"good-good","friend":"friend-o","very":"plenty","expensive":"dear-dear","perhaps":"maybe-maybe"},
	 "open":["Hup!","Look-look,","Straight talk:","Weigh this:"],
	 "address":["friend-chief","boss-of-the-bank"],"oath":["Sink my barge!","By the long current!"],
	 "proverb":["Cheap rope, short trip.","River gives, river counts.","Wet coin still spends."],
	 "first":["Pell","Oskadi","Nimo","Tarrow","Quill","Lisk"],"last":["Longpole","of Three Fords","Tallyhand","Mudwater"]},
	{"id":"ornate_court","label":"Ornate court formality",
	 "guide":"ornate court formality: stacked titles, elaborate honorifics, blessings and flourishes, 'most humbly', 'may your granaries never echo'",
	 "subs":{"I think":"this unworthy one believes","please":"if it please the Luminous Seat","thank you":"a thousand embroidered thanks","very":"most exceedingly"},
	 "open":["If this unworthy tongue may speak,","With the deepest of bows,","Ahem, most humbly,"],
	 "address":["Most Radiant","O Luminous Seat","Thrice-Honoured"],"oath":["By the Nine Cushions!","Heavens embroidered!"],
	 "proverb":["A gift unwrapped in haste is a gift half-given.","The longest bow is the shortest road to favour.","Silk hides the knife, and flatters it."],
	 "first":["Aurelisse","Vanthiel","Oriandre","Cassimor","Pellarine","Sabeline"],"last":["of the Ninth Cushion","Goldthread","the Much-Titled","Velvetreach"]},
	{"id":"steppe_laconic","label":"Laconic steppe speech",
	 "guide":"laconic steppe terseness: very short sentences, few words, horse-and-wind images, silences marked with 'Hm.'",
	 "subs":{"I think ":"","perhaps ":"","very ":"","really ":"","actually ":"","friend":"rider"},
	 "open":["Hm.","So.","Wind turns."],
	 "address":["hearth-holder","tent-lord"],"oath":["Sky and saddle!","Hooves of the grey mare!"],
	 "proverb":["Fast horse, short life.","The wind does not argue. It blows.","Many words, thin horse."],
	 "first":["Oyun","Tasar","Brek","Ulka","Senge","Yaru"],"last":["Far-Rider","of the Long Grass","Dustmane","Windborn"]},
	{"id":"grandmother_proverb","label":"Grandmother wisdom",
	 "guide":"proverb-heavy grandmother wisdom: calls everyone 'child' or 'dearie' (even the ruler), an endless supply of homely sayings, most slightly wrong",
	 "subs":{"friend":"pet","trouble":"a pickle"},
	 "open":["Now, dearie,","Listen to your elders, child:","As my own gran used to say,"],
	 "address":["dearie","child","my duck"],"oath":["Well, butter my bread!","Goodness and gravy!"],
	 "proverb":["A pot watched by two cooks boils twice as sour.","Never trust a goat that compliments your hat.","Honey on the lip, nettle in the sleeve.","The empty jar rattles loudest."],
	 "first":["Old Mother Hesk","Granny Pobb","Auntie Wenna","Nana Oriel","Old Brisa","Mam Tollie"],"last":["of the Warm Stove","Pickleback","Threadneedle","Crumbhollow"]},
	{"id":"coastal_lilt","label":"Sing-song coastal lilt",
	 "guide":"sing-song coastal lilt: ends sentences with 'so it is' or 'isn't it, now', tide-and-gull metaphors, playful repetition",
	 "subs":{"very":"ever so","soon":"on the next tide","friend":"my gull","wait":"bide"},
	 "open":["Ah, now,","Well, well, well,","Oh, the tide of it,"],
	 "address":["my bright one","sweet captain"],"oath":["Salt and starlight!","Gulls take me!"],
	 "proverb":["The sea keeps no promises, but it keeps everything else.","A calm harbour makes a lazy sailor.","Every tide brings a boot back."],
	 "first":["Maro","Ellisande","Pim","Coriel","Wenlo","Sarafin"],"last":["Saltwhistle","of the Shell Stair","Driftwell","Tidecall"]},
	{"id":"forge_gruff","label":"Gruff forge-folk",
	 "guide":"gruff forge-folk: blunt, hammer-and-anvil talk, grunts ('Hrm.'), judges everything by whether it holds under a hammer, insults like 'soft-iron'",
	 "subs":{"weak":"soft-iron","strong":"well-tempered","think":"reckon","nonsense":"slag","fool":"slag-head"},
	 "open":["Hrm.","Right.","Listen, soft-iron:"],
	 "address":["boss","forge-master"],"oath":["Anvils and ashes!","Tongs of my father!"],
	 "proverb":["Cold iron don't bend for pretty words.","Every blade's honest once it's quenched.","Quick fire, brittle steel."],
	 "first":["Dorga","Hamrik","Brusa","Kelt","Ondra","Grom"],"last":["Sootjaw","of the Red Bellows","Anvilback","Clinker"]},
	{"id":"liturgical_pious","label":"Pious liturgical cadence",
	 "guide":"pious liturgical cadence: blessings, 'verily', 'thus it is sung', 'we beseech', repetition in threes, everything a sign from the heavens",
	 "subs":{"truly":"verily","luck":"providence","lucky":"blessed","hope":"pray"},
	 "open":["Blessed be the grain,","Verily,","Hear me, now:"],
	 "address":["Anointed One","Blessed Seat"],"oath":["Saints of the furrow!","Heaven's hem!"],
	 "proverb":["The field that is prayed over still wants hoeing.","Heaven helps the one who counts the sacks.","A humble lamp outlasts a proud fire."],
	 "first":["Brother Anselm","Sister Idony","Elder Pax","Mother Seraphine","Deacon Tobiah","Cantor Ilse"],"last":["of the Seventh Bell","Candlewright","Hymnfold","the Unwearied"]},
	{"id":"marsh_drawl","label":"Slow marsh drawl",
	 "guide":"slow marsh drawl: 'reckon', 'yonder', 'a-coming', long easy sentences, eel-and-reed metaphors, unhurried to the point of mischief",
	 "subs":{"think":"reckon","over there":"over yonder","coming":"a-coming","going":"a-going","very":"mighty","hurry":"fuss"},
	 "open":["Well now,","Mm-hm.","Easy, easy,"],
	 "address":["high one","big fish"],"oath":["Eels and eelgrass!","Muck and mercy!"],
	 "proverb":["Slippery as an eel's apology.","Mud remembers every foot.","Heron don't chase. Heron waits."],
	 "first":["Cobb","Loyal Ettie","Russet","Wade","Minnow","Bettany"],"last":["Reedwater","of the Sunk Bridge","Longmire","Frogsford"]},
	{"id":"pedant_scholar","label":"Hill-city pedantry",
	 "guide":"hill-city pedantry: 'strictly speaking', 'to wit', corrects themselves mid-sentence, footnotes their own jokes, precise to the point of comedy",
	 "subs":{"about":"approximately","big":"considerable","maybe":"conceivably","very":"measurably","lots":"a quantifiable surplus"},
	 "open":["Strictly speaking,","To wit:","If I may correct the record,"],
	 "address":["Principal","Esteemed Presider"],"oath":["By the ninth scroll!","Ink and error!"],
	 "proverb":["An unmeasured promise weighs nothing.","Two witnesses, three stories.","The margin is where the truth hides."],
	 "first":["Magister Quell","Ondine","Theodric","Ysolde","Archivist Brann","Perpetua"],"last":["of the Upper Stacks","Inkwell","Sevenfold","Marginalia"]},
	{"id":"festival_boisterous","label":"Boisterous feast-hall bluster",
	 "guide":"boisterous feast-hall bluster: loud, laughing, boastful superlatives, food-and-drink metaphors, calls people 'my roast goose', exclamation-happy",
	 "subs":{"good":"glorious","big":"enormous","very":"tremendously","friend":"my roast goose","fine":"splendid"},
	 "open":["HA!","Ho-ho!","Oh, glorious!"],
	 "address":["my great bear","big-hearted one"],"oath":["Beards and barley-beer!","Roast my ribs!"],
	 "proverb":["An empty belly makes a short temper and a long speech.","The best deals are sealed with gravy.","Never trust a sober cook."],
	 "first":["Big Ulfo","Merrit","Bolla","Hendro","Gusta","Fat Parro"],"last":["Alehorn","of the Long Table","Roastwell","Barrelbelly"]},
	{"id":"frost_skald","label":"Frost-skald kennings",
	 "guide":"frost-skald kennings: alliteration, poetic compounds (whale-road, word-hoard, sword-song), boasts in verse fragments, grim weather humour",
	 "subs":{"sea":"whale-road","words":"word-hoard","battle":"sword-song","gold":"hand-fire","ship":"wave-horse","war":"spear-storm"},
	 "open":["Hear me, hall!","Listen, hearth-lord:","Cold comes the word:"],
	 "address":["ring-giver","hearth-lord"],"oath":["Frost and flint!","By the long winter!"],
	 "proverb":["Warm words, cold spears.","The ice remembers who fell through it.","A boast is a debt the sword must pay."],
	 "first":["Hrolla","Sigvard","Eskil","Thyri","Bjarnhild","Ormr"],"last":["Frostbeard","of the White Fjell","Ringbreaker","Wolfcoat"]},
]

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

static func dialect(dialect_id:String)->Dictionary:
	for entry:Dictionary in DIALECTS:
		if String(entry.id)==dialect_id: return entry
	return DIALECTS[0]

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

static func for_civilization(civ_id:String)->Dictionary:
	var d:=DIALECTS[dialect_index_for_civ(civ_id)]
	var civ:=_civ_record(civ_id)
	var rng:=_rng("civ:"+civ_id)
	return {"key":"civ_"+civ_id,"civ_id":civ_id,"name":String(civ.get("name",civ_id.capitalize())),
		"dialect_id":String(d.id),"dialect":String(d.guide),"label":String(d.label),
		"address":String(_pick(rng,d.address)),"oath":String(_pick(rng,d.oath)),"proverb":String(_pick(rng,d.proverb))}

static func for_foreign_leader(civ_id:String)->Dictionary:
	var people:=for_civilization(civ_id)
	var d:=dialect(String(people.dialect_id))
	var rng:=_rng("leader:"+civ_id)
	var info:Dictionary={}
	if Engine.get_main_loop() and ForeignDiplomacy.has_method("leader"): info=ForeignDiplomacy.leader(civ_id)
	var temperament:String=String(info.get("temperament",""))
	var goals:Array=info.get("goals",[])
	var goal_title:String=String((goals[0] as Dictionary).get("title","")) if not goals.is_empty() and goals[0] is Dictionary else ""
	var p:={"key":"leader_"+civ_id,"role":"leader","civ_id":civ_id,
		"name":String(info.get("name",String(_pick(rng,d.first))+" "+String(_pick(rng,d.last)))),"title":"Leader of "+String(people.name),
		"voice":String(_pick(rng,VOICES)),"dialect":String(d.guide),"dialect_id":String(d.id),
		"temper":String(TEMPERAMENT_TEMPER.get(temperament,_pick(rng,TEMPERS))),
		"tics":_pick_many(rng,TICS,3),"want":goal_title.to_lower() if not goal_title.is_empty() else "respect for "+String(people.name),
		"fear":String(_pick(rng,FEARS)),"quirk":String(_pick(rng,QUIRKS)),"secret":String(_pick(rng,ENVOY_SECRETS)),
		"address":String(people.address),"oath":String(people.oath),"proverb":String(people.proverb),
		"bio":String(info.get("bio","")),"temperament":temperament}
	p["sample"]=sample_line(p)
	return p

static func for_envoy(civ_id:String,audience_id:String)->Dictionary:
	var people:=for_civilization(civ_id)
	var d:=dialect(String(people.dialect_id))
	var rng:=_rng("envoy:%s:%s" % [civ_id,audience_id])
	var name:String=String(_pick(rng,d.first))+" "+String(_pick(rng,d.last))
	var title:String="Envoy of "+String(people.name)
	var hall_path:="res://scripts/audience_hall.gd"
	if ResourceLoader.exists(hall_path):
		var audience:Dictionary=load(hall_path).find(audience_id)
		var speaker:Dictionary=audience.get("speaker",{})
		if not String(speaker.get("name","")).is_empty(): name=String(speaker.name)
		if not String(speaker.get("title","")).is_empty(): title=String(speaker.title)
	var p:={"key":"envoy","role":"envoy","civ_id":civ_id,"name":name,"title":title,
		"voice":String(_pick(rng,VOICES)),"dialect":String(d.guide),"dialect_id":String(d.id),
		"temper":String(_pick(rng,TEMPERS)),"tics":_pick_many(rng,TICS,rng.randi_range(3,4)),
		"want":String(_pick(rng,["to be remembered as the envoy who got it done","a warm bed and a better title back home","to outshine the last envoy, who was insufferable","to see this famous court with their own eyes","to leave with a story worth retelling"])),
		"fear":String(_pick(rng,FEARS)),"quirk":String(_pick(rng,QUIRKS)),"secret":String(_pick(rng,ENVOY_SECRETS)),
		"address":String(_pick(rng,d.address)),"oath":String(_pick(rng,d.oath)),"proverb":String(_pick(rng,d.proverb))}
	p["sample"]=sample_line(p)
	return p

static func for_person(person:Dictionary)->Dictionary:
	var pid:int=int(person.get("person_id",0))
	var rng:=_rng("person:%d" % pid)
	# Officials keep the speech of their home district: each one is a distinct
	# regional voice, which makes a bickering court legible at a glance.
	var d:=DIALECTS[posmod(hash("%d|home|%d" % [_seed(),pid]),DIALECTS.size())]
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
	var tics:Array=_pick_many(rng,DISPOSITION_TICS[disp],2)
	tics.append_array(_pick_many(rng,TICS,rng.randi_range(1,2)))
	var want:=""
	for t in traits:
		if TRAIT_WANTS.has(String(t)): want=String(TRAIT_WANTS[String(t)]); break
	if want.is_empty(): want=String(DISPOSITION_WANT[disp])
	var fear:String=String(_pick(rng,FEARS))
	if float(person.get("courage",0.5))<0.34: fear="being blamed in public"
	elif float(rel.get("fear",0.0))>0.26: fear="the ruler's temper"
	elif float(person.get("suspicion",0.5))>0.72: fear="being played for a fool by foreigners"
	elif float(person.get("pride",0.5))>0.78: fear="looking small in front of the court"
	var quirk:String=String(BACKGROUND_QUIRKS.get(String(person.get("background","")),_pick(rng,QUIRKS)))
	var secret:String=String(_pick(rng,OFFICIAL_SECRETS))
	if float(rel.get("resentment",0.0))>0.3: secret="keeps a list of every slight from the ruler"
	elif float(person.get("honesty",0.5))<0.36: secret="pads the accounts, a little, every season"
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
		tics[0]="Saw it with my own eyes:"
		if disp!="sycophantic": temper+="; plain-spoken, concrete, opinionated about what they saw"
	var title:String=String(person.get("office_title",person.get("office_key","Official")))
	if title.is_empty(): title="Official"
	var p:={"key":"official_%d" % pid,"role":"official","person_id":pid,"civ_id":"player",
		"name":String(person.get("name","Official")),"title":title,"stance":disp,"voice":voice,
		"dialect":String(d.guide),"dialect_id":String(d.id),"temper":temper,"tics":tics,"want":want,"fear":fear,
		"quirk":quirk,"secret":secret,"toward_ruler":toward,"traits":", ".join(PackedStringArray(traits.map(func(x):return String(x)))),
		"background":String(person.get("background","")),"office_key":office_key,
		"address":String(_pick(rng,d.address)),"oath":String(_pick(rng,d.oath)),"proverb":String(_pick(rng,d.proverb))}
	p["sample"]=sample_line(p)
	return p

static func brief(p:Dictionary)->String:
	## One compact line per character for prompts.
	var tics:PackedStringArray=PackedStringArray()
	for t in p.get("tics",[]): tics.append("\"%s\"" % String(t))
	var parts:PackedStringArray=PackedStringArray([
		"%s, %s" % [String(p.get("name","")),String(p.get("title",""))],
		"voice %s; temper %s" % [String(p.get("voice","")),String(p.get("temper",""))],
		"dialect: %s" % String(p.get("dialect","")),
		"calls the ruler \"%s\"; oath \"%s\"" % [String(p.get("address","")),String(p.get("oath",""))],
		"pet phrases %s" % ", ".join(tics),
		"wants %s; fears %s; quirk: %s" % [String(p.get("want","")),String(p.get("fear","")),String(p.get("quirk",""))],
		"secret (only let it leak sideways, never state it): %s" % String(p.get("secret","")),
	])
	if p.has("toward_ruler"): parts.append("feels %s toward the ruler" % String(p.toward_ruler))
	if not String(p.get("traits","")).is_empty(): parts.append("traits %s" % String(p.traits))
	return " | ".join(parts)

## Dialect transform used by the offline bank. rng drives the flourishes;
## every result carries at least one visible dialect marker.
static func speak(p:Dictionary,text:String,rng:RandomNumberGenerator,allow_tic:bool=true,avoid:Dictionary={},lead_ok:bool=true)->String:
	## Dialect lives inside the sentence: word substitutions, the speaker's own
	## address term and oath (already in the template), plus at most one lead-in
	## (an interjection, or this speaker's single pet phrase for the scene).
	## avoid: per-speaker scene memory so lead-ins and the pet phrase never repeat.
	var d:=dialect(String(p.get("dialect_id","")))
	var oath:String=String(p.get("oath",""))
	var address:String=String(p.get("address",""))
	# Shield the speaker's own address term and oath from word substitutions.
	var out:String=text
	if not address.is_empty(): out=out.replace(address,"@@ADDR@@")
	if not oath.is_empty(): out=out.replace(oath,"@@OATH@@")
	var changed:=false
	var subs:Dictionary=d.get("subs",{})
	var applied:=0
	for key in subs.keys():
		if applied>=3: break
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
		out=pattern.sub(out,replacement,true)
		changed=true
		applied+=1
	out=out.replace("@@ADDR@@",address).replace("@@OATH@@",oath)
	out=out.replace("  "," ").strip_edges()
	if not out.is_empty(): out=out.substr(0,1).to_upper()+out.substr(1)
	var starts_with_oath:bool=not oath.is_empty() and out.begins_with(oath)
	var marked:bool=changed or (not address.is_empty() and address in out) or (not oath.is_empty() and oath in out)
	# At most one interjection before the first clause: a line that already
	# opens on an oath or an exclamation gets nothing stacked in front of it.
	if starts_with_oath or not lead_ok or _opens_with_interjection(out): return out
	var has_colon:=":" in out
	var tics:Array=[]
	for t in p.get("tics",[]):
		if not (has_colon and String(t).ends_with(":")): tics.append(t)
	var fresh_tics:Array=[]
	for t in tics:
		if not avoid.has(String(t)): fresh_tics.append(t)
	if allow_tic and not avoid.has("~tic") and not fresh_tics.is_empty() and rng.randf()<0.4:
		avoid["~tic"]=true
		var tic:String=String(_pick(rng,fresh_tics))
		avoid[tic]=true
		return "%s %s" % [tic,_lower_first(out)]
	if not marked or rng.randf()<0.3:
		var openers:Array=[]
		for o in d.open:
			if not (has_colon and String(o).ends_with(":")): openers.append(o)
		if openers.is_empty(): return out
		var opener:String=_fresh(rng,openers,avoid)
		var soft:bool=opener.ends_with(",") or opener.ends_with(":")
		return "%s %s" % [opener,_lower_first(out) if soft else out]
	return out

const INTERJECTIONS:=["ha","ha!","oh","ah","hm","hm.","hrm","hrm.","well","so","now","right","och","hup!","verily","ho-ho!","mm-hm."]

static func _opens_with_interjection(text:String)->bool:
	var first:String=text.get_slice(" ",0).to_lower().rstrip(",")
	return first in INTERJECTIONS or first.ends_with("!")

## Every lead-in this persona could open a line with (pet phrases + interjections).
static func lead_ins(p:Dictionary)->Array:
	var out:Array=(p.get("tics",[]) as Array).duplicate()
	out.append_array(dialect(String(p.get("dialect_id",""))).get("open",[]))
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
