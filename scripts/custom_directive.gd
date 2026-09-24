extends RefCounted
## Custom directives: the universal fallback for any explicit order.
##
## Catalog policies remain the precise, tested path for the orders they cover.
## Everything else a god can say still happens: the order is read (by the live
## model through a strict schema, or offline by the lexicon below) into bounded
## changes on DecreeStatistics.PARAMETERS, scaled by physical feasibility and by
## how well the settlement can carry it out, applied for a duration through the
## ordinary ConsequenceEngine policy channels, paid for from real stores, and
## joined by unforeseen side effects drawn from a consequence table keyed to the
## nature of the order. Rolls are deterministic from the world seed and order.
## Nothing here refuses an order or reports a missing mechanic; impossible
## asks get the realistic result of trying.

const ID := "custom_directive"
const CV := preload("res://scripts/character_voice.gd")
const DivineRegard := preload("res://scripts/divine_regard.gd")
const Notables := preload("res://scripts/village_notables.gd")
const DEFAULT_DAYS := 180.0
const MAIN_MAGNITUDE := 0.12
const SIDE_MAGNITUDE := 0.04

## Nature table. effects: [parameter, strength, delay_days, days(0 = order)].
## side: [parameter, strength, probability, delay_days, days(0 = order)].
## deaths: [probability, share of population, max count, cause, deliberate].
## covered_by: catalog policy id -> parameters that policy already moves.
## supplement: also applies alongside a matched catalog policy.
const NATURES := {
	"selective_breeding":{"terms":["father children","father a child","father babies","sire","breed ","breeding","stud ","impregnat","other men's wives","other mens wives","others' wives","other men’s wives","lie with","mate with","seed the women","smartest men","cleverest men","best men to","wisest men to","strongest men to"],
		"act":"see that the men you favour father children in households not their own","risk":"Husbands will not forgive it easily, and there may be blood over it",
		"coercion":0.7,"supplement":true,"days":365.0,
		"effects":[["fertility",0.8,0,0],["knowledge",0.45,60,0],["cohesion",-0.7,0,0],["legitimacy",-0.3,0,0],["violence",0.35,0,0],["resentment",0.55,0,0]],
		"side":[["infant_mortality",0.6,0.45,150,0],["disease",0.5,0.35,40,0],["violence",0.6,0.4,20,90],["migration",-0.5,0.25,60,0],["cohesion",-0.45,0.3,30,0]],
		"covered_by":{"family_support":["fertility"],"coercive_pronatalism":["fertility","cohesion"]}},
	"selective_family":{"terms":["cleverest families","smartest families","clever families","best families","wisest families","strongest families","clever parents","cleverest parents","the best blood","bloodline","pure blood","purity of blood","better stock","finest stock","only the clever","only the strong","weakest should not"],
		"act":"favour the cleverest households so they raise more children","risk":"Those passed over will feel it",
		"coercion":0.15,"supplement":true,"days":365.0,
		"effects":[["fertility",0.35,0,0],["knowledge",0.3,90,0],["cohesion",-0.25,0,0],["food_use",0.15,0,0]],
		"side":[["cohesion",-0.35,0.3,45,0],["infant_mortality",0.3,0.2,200,0],["legitimacy",-0.25,0.2,60,0],["disease",0.25,0.15,90,0]],
		"covered_by":{"family_support":["fertility","food_use"]}},
	"monument":{"terms":["monument","statue","idol","temple","shrine","standing stone","stone circle","tower","great hall","pyramid","cairn","totem","effigy","carve your","carve my","carve a","image of me","likeness"],
		"act":"set hands to raising it","risk":"It will eat labour and stone that the huts could use",
		"coercion":0.2,
		"effects":[["labor",-0.5,0,120],["cohesion",0.4,0,0],["legitimacy",0.45,0,0],["construction",-0.3,0,120]],
		"side":[["health",-0.3,0.25,30,60],["resentment",0.25,0.2,60,0]],
		"costs":{"food":0.03,"materials":0.12},"deaths":[0.3,0.004,2,"Work accidents",false]},
	"defense_works":{"terms":["wall ","walls","palisade","ditch","fortif","stockade","barricade","rampart","fence the","earthwork"],
		"act":"raise the works","risk":"Every hand on the ditch is a hand off the hunt",
		"coercion":0.15,
		"effects":[["security",0.6,0,0],["labor",-0.35,0,90],["cohesion",0.1,0,0]],
		"side":[["health",-0.2,0.2,30,45]],
		"costs":{"materials":0.10},"deaths":[0.15,0.003,1,"Work accidents",false]},
	"feast":{"terms":["feast","festival","celebrat","banquet","games","dance","party","holiday","music","bonfire","gathering of all"],
		"act":"see the fires lit and the meat shared","risk":"A feast empties the racks faster than a hunt fills them",
		"coercion":0.0,
		"effects":[["cohesion",0.6,0,45],["legitimacy",0.3,0,45],["labor",-0.2,0,10],["food_use",0.25,0,10]],
		"side":[["disease",0.3,0.2,5,30],["violence",0.3,0.2,3,20]],
		"costs":{"food":0.06}},
	"worship":{"terms":["worship","pray","prayer","offering","altar","honor the god","honour the god","honor me","honour me","praise","kneel","bow to me","bow before","rite","ritual","ceremon","holy","sacred","priest","my name be","sing my name","fear me","love me","obey me","revere"],
		"act":"see it done at every hearth","risk":"Some will do it for show only",
		"coercion":0.2,
		"effects":[["cohesion",0.4,0,0],["legitimacy",0.5,0,0],["labor",-0.1,0,30]],
		"side":[["knowledge",-0.2,0.2,60,0],["resentment",0.3,0.15,30,0]],
		"costs":{"food":0.02}},
	"human_sacrifice":{"terms":[],
		"act":"give a life to you as you ask","risk":"Mothers will hide their children from me after this",
		"coercion":0.85,
		"effects":[["legitimacy",0.2,0,90],["cohesion",-0.35,0,0],["security",0.3,0,90],["resentment",0.55,0,0]],
		"side":[["migration",-0.45,0.3,20,0],["violence",0.3,0.2,10,60],["cohesion",-0.4,0.3,30,0]],
		"deaths":[1.0,0.0,1,"sacrifice",true]},
	"prohibition":{"terms":["forbid","ban ","banned","prohibit","outlaw","no one may","nobody may","not allowed","must not","shall not","never again","make it taboo","taboo"],
		"act":"make the ban known and see it kept","risk":"A ban is only as good as the eyes that watch it",
		"coercion":0.45,
		"effects":[["cohesion",-0.25,0,0],["legitimacy",-0.2,0,0],["security",0.15,0,0],["resentment",0.35,0,0]],
		"side":[["violence",0.35,0.25,20,60]]},
	"punishment":{"terms":["punish","flog","whip","beat ","beaten","brand ","shame","stocks","pillory","cut off","mutilat","tortur","imprison","lock up","chain ","chained","stone them","stone him","stone her"],
		"act":"see the punishment given in front of all","risk":"Fear keeps order until it breeds hatred",
		"coercion":0.7,
		"effects":[["security",0.35,0,0],["cohesion",-0.3,0,0],["legitimacy",-0.15,0,0],["resentment",0.4,0,0],["health",-0.1,0,30]],
		"side":[["violence",0.3,0.25,15,60],["migration",-0.25,0.2,30,0]]},
	"exile":{"terms":["exile","banish","drive out","cast out","expel","send away","throw out"],
		"act":"drive them past the last cairn","risk":"The banished know our paths and our stores",
		"coercion":0.6,
		"effects":[["migration",-0.6,0,60],["cohesion",-0.15,0,0],["security",0.2,0,0],["resentment",0.3,0,0]],
		"side":[["violence",0.3,0.25,30,60],["security",-0.3,0.2,60,90]]},
	"relocation":{"terms":["move to","migrate","relocate the village","abandon the village","leave the valley","settle by","move the village","move our","move everyone","go north","go south","go east","go west","cross the river","new home"],
		"act":"pack the camp and lead them there","risk":"The road is hard on the old and the very young",
		"coercion":0.35,
		"effects":[["labor",-0.4,0,60],["health",-0.3,0,60],["cohesion",-0.2,0,60],["logistics",-0.2,0,60]],
		"side":[["disease",0.3,0.25,10,60]],
		"costs":{"food":0.05},"deaths":[0.15,0.003,2,"Travel exhaustion",false]},
	"welcome":{"terms":["welcome","invite","take in","accept strangers","refugees","newcomers","outsiders","adopt them","let them join","let strangers"],
		"act":"open our fires to them","risk":"Strangers bring strange sicknesses as well as strong backs",
		"coercion":0.0,
		"effects":[["migration",0.6,0,0],["cohesion",-0.2,0,0],["knowledge",0.15,0,0],["food_use",0.1,0,0]],
		"side":[["disease",0.4,0.35,20,60],["violence",0.25,0.2,40,60]]},
	"hunt_beast":{"terms":["hunt the","hunt down","kill the wolf","kill the bear","the beast","wolf","wolves","bear ","bears","lion","great cat","mammoth","boar","big game","monster","the serpent"],
		"act":"send the best spears after it","risk":"A cornered beast takes a hunter with it, sometimes",
		"coercion":0.0,
		"effects":[["food_yield",0.35,0,45],["security",0.4,0,90],["cohesion",0.2,0,60],["legitimacy",0.15,0,60]],
		"side":[["health",-0.2,0.2,5,30]],
		"deaths":[0.3,0.0,1,"Hunting accident",false]},
	"rename":{"terms":["rename","name the","call the village","call our","call it ","henceforth","shall be called","be known as","new name"],
		"act":"see the new name spoken at every fire","risk":"The old ones will keep the old name a while",
		"coercion":0.05,
		"effects":[["cohesion",0.15,0,90],["legitimacy",0.1,0,90]],
		"side":[["resentment",0.15,0.15,30,0]]},
	"marriage":{"terms":["marry","marriage","wed ","wedding","betroth","arranged","pair them","pair the"],
		"act":"see the pairings made","risk":"Hearts do not always go where they are sent",
		"coercion":0.25,
		"effects":[["fertility",0.25,0,0],["cohesion",0.15,0,0]],
		"side":[["violence",0.2,0.15,30,60]],
		"covered_by":{"family_support":["fertility"]}},
	"polygamy":{"terms":["two wives","many wives","second wife","more than one wife","several wives","many husbands","two husbands"],
		"act":"let the strong men take more wives","risk":"Young men left without wives grow dangerous",
		"coercion":0.2,
		"effects":[["fertility",0.2,0,0],["cohesion",-0.3,0,0],["violence",0.25,0,0],["resentment",0.2,0,0]],
		"side":[["violence",0.4,0.3,60,90],["migration",-0.3,0.2,90,0]]},
	"teaching":{"terms":["teach","school","apprentice","learn","lesson","instruct","study the stars","count the","memoriz","tell the stories","train the young","pass on","knowledge keepers"],
		"act":"put the young at the elders' feet each evening","risk":"Evenings spent listening are evenings not spent working",
		"coercion":0.05,
		"effects":[["knowledge",0.6,0,0],["labor",-0.15,0,0],["cohesion",0.1,0,0]],
		"side":[["cohesion",0.2,0.15,90,0]],
		"covered_by":{"directed_inquiry":["knowledge"]}},
	"sanitation":{"terms":["latrine","wash","clean ","cleanse","bury the dead","burn the dead","boil","sanitat","waste pit","keep the water clean","bathe","quarantine","isolate the sick","separate the sick","keep the sick apart"],
		"act":"set the rules for water, waste and the dead","risk":"People grumble at new habits until they see fewer fevers",
		"coercion":0.15,
		"effects":[["disease",-0.6,0,0],["health",0.4,0,0],["labor",-0.1,0,0]],
		"side":[["resentment",0.15,0.15,30,0]]},
	"planting":{"terms":["plant ","planting","sow","seed the field","farm","till ","crops","garden","sow grain"],
		"act":"clear plots and put seed in the ground","risk":"Seed in the ground feeds no one until it ripens",
		"coercion":0.1,
		"effects":[["food_yield",0.45,90,365],["labor",-0.2,0,60],["ecology",-0.2,0,0]],
		"side":[["food_yield",-0.35,0.2,150,90]]},
	"clear_land":{"terms":["clear the forest","cut down","fell the trees","burn the forest","burn the woods","clear land","chop down","clear the trees"],
		"act":"take the trees down","risk":"The land does not forget what we take from it",
		"coercion":0.1,
		"effects":[["materials",0.4,0,0],["food_yield",0.2,60,0],["ecology",-0.7,0,0]],
		"side":[["ecology",-0.4,0.3,60,0]],
		"deaths":[0.15,0.003,1,"Work accidents",false]},
	"conservation":{"terms":["plant trees","protect the forest","let the land rest","spare the","sacred grove","do not hunt","stop hunting","leave the"],
		"act":"keep hands off the land you named","risk":"Lean weeks will test the rule",
		"coercion":0.2,
		"effects":[["ecology",0.6,0,0],["food_yield",-0.2,0,0]],
		"side":[["resentment",0.2,0.2,30,0]]},
	"work_harder":{"terms":["work harder","work longer","no rest","double the work","toil","from dawn","every hand to","work them","work until"],
		"act":"drive the work harder","risk":"Tired hands break tools and bones",
		"coercion":0.45,
		"effects":[["labor",0.6,0,60],["health",-0.3,0,60],["cohesion",-0.25,0,0],["resentment",0.3,0,0]],
		"side":[["disease",0.25,0.2,30,60]],"deaths":[0.1,0.002,1,"Work accidents",false]},
	"rest":{"terms":["day of rest","rest day","let them rest","lighten the work","ease the work","sleep late"],
		"act":"give them the rest you grant","risk":"The racks will fill slower",
		"coercion":0.0,
		"effects":[["labor",-0.3,0,30],["health",0.35,0,30],["cohesion",0.35,0,30]]},
	"trade":{"terms":["trade","exchange","barter","gifts to","send gifts","traders","market"],
		"act":"send people with goods to the neighbours","risk":"Traders carry sickness home with their goods",
		"coercion":0.0,
		"effects":[["logistics",0.35,0,0],["materials",0.3,0,0],["knowledge",0.15,0,0]],
		"side":[["disease",0.35,0.25,30,60]],
		"costs":{"materials":0.04},
		"covered_by":{"market_deregulation":["logistics","materials"]}},
	"raid":{"terms":["raid","attack","make war","invade","conquer","plunder","ambush","strike the","war on"],
		"act":"send the young spears out","risk":"Raids are answered with raids",
		"coercion":0.3,
		"effects":[["food_yield",0.2,20,60],["legitimacy",0.1,0,0],["violence",0.4,0,90],["labor",-0.25,0,45],["security",-0.2,0,60]],
		"side":[["violence",0.4,0.3,45,90],["security",-0.3,0.25,60,90]],
		"deaths":[0.5,0.01,3,"Raiding",false]},
	"enslave":{"terms":["enslave","slave","bondage","thrall","captives to work","force them to work","make them serve"],
		"act":"put them under the yoke","risk":"Chained people watch for the day the chain is loose",
		"coercion":0.85,
		"effects":[["labor",0.4,0,0],["cohesion",-0.4,0,0],["legitimacy",-0.15,0,0],["violence",0.3,0,0],["resentment",0.5,0,0]],
		"side":[["migration",-0.3,0.3,60,0],["disease",0.2,0.2,60,0]]},
	"mercy":{"terms":["free the","release the","pardon","forgive","mercy","amnesty","spare them","let them go"],
		"act":"open the pens and let them go","risk":"Some will read mercy as weakness",
		"coercion":0.0,
		"effects":[["cohesion",0.3,0,0],["legitimacy",0.25,0,0],["security",-0.15,0,0]]},
	"segregation":{"terms":["separate the men and women","men and women apart","keep women","seclude","women may not","women must not","men may not","keep the sexes"],
		"act":"keep men and women to separate fires","risk":"Fewer children will come of it, and more quarrels",
		"coercion":0.5,
		"effects":[["fertility",-0.45,0,0],["cohesion",-0.3,0,0],["resentment",0.3,0,0]]},
	"intoxicants":{"terms":["drink","brew","ferment","intoxic","get drunk","smoke the","dream-herb","mushroom"],
		"act":"let the cups go round","risk":"Loose tongues become loose fists",
		"coercion":0.0,
		"effects":[["cohesion",0.3,0,30],["health",-0.25,0,60],["violence",0.2,0,30]],
		"side":[["violence",0.35,0.3,10,30]]},
	"custom_art":{"terms":["paint","tattoo","wear ","dress","adorn","bead","song","story","legend","carving","custom","tradition","hair","mark our","mark every","honour our ancestors","honor our ancestors","remember the"],
		"act":"see it taken up at every fire","risk":"New customs take a season to settle",
		"coercion":0.1,
		"effects":[["cohesion",0.3,0,0],["knowledge",0.08,0,0],["labor",-0.05,0,30]]},
	"gathering_goods":{"terms":["gather wood","collect wood","firewood","timber","flint","clay","reeds","gather hides","collect bones","gather shells","collect shells","stockpile"],
		"act":"send gatherers out for it","risk":"Gatherers far afield are not hunting",
		"coercion":0.05,
		"effects":[["materials",0.45,0,60],["labor",-0.15,0,60]],
		"covered_by":{"stone_gathering_drive":["materials"]}},
	"fishing":{"terms":["fish","fishing","nets","weir"],
		"act":"put more hands on the water","risk":"The river gives less when it is pressed",
		"coercion":0.0,
		"effects":[["food_yield",0.3,0,90],["ecology",-0.1,0,0]]},
	"fasting":{"terms":["fast ","fasting","go hungry","eat less","eat nothing","skip meals"],
		"act":"see the fast kept","risk":"Hungry people grow weak and short-tempered",
		"coercion":0.3,
		"effects":[["food_use",-0.5,0,30],["health",-0.3,0,30],["cohesion",0.1,0,30]],
		"covered_by":{"rationing":["food_use"]}},
	"informers":{"terms":["spy","spies","informer","report on their","watch each other","denounce","eyes and ears"],
		"act":"set eyes to watch every hearth","risk":"Neighbours will stop trusting neighbours",
		"coercion":0.5,"supplement":true,
		"effects":[["security",0.3,0,0],["cohesion",-0.35,0,0],["legitimacy",-0.1,0,0],["resentment",0.3,0,0]]},
	"communal_children":{"terms":["raise the children together","children in common","common nursery","children belong to","raise all children"],
		"act":"gather the little ones to one fire","risk":"Mothers will not give up their own lightly",
		"coercion":0.35,
		"effects":[["labor",0.25,0,0],["fertility",0.1,0,0],["cohesion",-0.15,0,0],["resentment",0.25,0,0]],
		"side":[["disease",0.3,0.25,30,0],["infant_mortality",0.25,0.2,60,0]]},
	"miracle":{"terms":["make it rain","stop the rain","bring rain","bring the rain","make the sun","stop the sun","stop the wind","raise the dead","bring back the dead","back to life","live forever","never die","immortal","fly ","to fly","turn stone","turn the stone","into gold","move the mountain","part the river","command the sky","make the river","walk on water","end death","cure every","cure all","stop the winter","end winter","make the moon","stars to"],
		"act":"try it, with every rite we know","risk":"If nothing comes of it, people will wonder why",
		"coercion":0.1,"supplement":true,"feasibility":0.05,
		"effects":[["labor",-0.2,0,14],["cohesion",0.2,0,30]],
		"side":[["legitimacy",-0.5,0.55,30,90],["cohesion",-0.2,0.3,30,60]],
		"costs":{"food":0.02}},
	"attempt":{"terms":[],
		"act":"make what attempt we can with what we have","risk":"Without the means it will come to little, and people will see that",
		"coercion":0.1,"feasibility":0.2,
		"effects":[["labor",-0.15,0,14],["legitimacy",-0.1,0,60]]},
	"generic":{"terms":[],
		"act":"set people to it","risk":"It will cost us some work elsewhere",
		"coercion":0.1,
		"effects":[["labor",-0.15,0,30],["legitimacy",0.1,0,60],["cohesion",0.05,0,60]]},
}

const COERCION_TERMS := ["force","forced","must ","compel","whether they like","on pain of","or die","or be ","make them","every one of","no exceptions","by any means","drag"]
const INTENSIFIERS := ["all ","every","entire","double","massive","great ","huge","utterly","completely"]
const SOFTENERS := ["slightly","a little","gently","encourage","modest","some of","a few","try to","perhaps"]
const HUMAN_WORDS := ["child","children","man ","men ","woman","women","boy","girl","captive","prisoner","person","people","slave","virgin","firstborn","baby","infant","elder","stranger","one of us","one of them"]
const ANIMAL_WORDS := ["goat","sheep","deer","ox ","oxen","bird","animal","beast","boar","lamb","calf","dog","horse","fish"]
const FRAME_BREAKS := ["our records","the records","records give","records show","aggregate measure","aggregate","person-level","fertility register","not tracked","isn't tracked","is not tracked","cannot be simulated","can't be simulated","not simulated","simulation","the game","game mechanic","mechanic","not implemented","no system","systems provide","our systems","present systems","data","dataset","as an ai","language model","i cannot name","i can't name","percentage points","statistic","metric"]
const IMPERATIVE_STARTS := ["have","make","let","hold","give","take","bring","teach","marry","dance","sing","pray","worship","feast","celebrate","honor","honour","raise","plant","sow","burn","clear","name","rename","bury","wash","clean","boil","trade","raid","attack","invade","enslave","free","release","welcome","invite","exile","banish","punish","flog","shame","sacrifice","allow","permit","declare","proclaim","appoint","choose","select","pair","breed","sire","father","isolate","quarantine","fast","rest","work","dig","carve","paint","tattoo","wear","dress","cut","move","migrate","settle","abandon","leave","follow","obey","kneel","bow","tell","get","put","set","keep","open","close","call","kill","hunt","fish","gather","collect","build","erect","double","halve","feed","starve","drive","throw","offer","bless","curse","crown","anoint","summon","send","find","seize","burn","drown","cure","heal","end","begin","start","stop","ban","forbid","outlaw","every","all","no","nobody","everyone","each","from","henceforth","tonight","tomorrow","today","now"]
## Verbs that open a plain command even when no catalog word appears.
const IMPERATIVE_VERBS := ["have","make","let","hold","give","take","bring","teach","marry","dance","sing","pray","worship","feast","celebrate","honor","honour","raise","plant","sow","burn","clear","name","rename","bury","wash","clean","boil","trade","raid","attack","invade","enslave","free","release","welcome","invite","exile","banish","punish","flog","whip","shame","sacrifice","allow","permit","declare","proclaim","appoint","choose","select","pair","breed","sire","father","isolate","quarantine","fast","rest","work","dig","carve","paint","tattoo","wear","dress","cut","move","migrate","settle","abandon","leave","follow","obey","kneel","bow","put","set","keep","open","close","call","hunt","fish","feed","starve","drive","throw","offer","bless","curse","crown","anoint","summon","find","seize","drown","cure","double","halve","erect","train","praise","forgive","pardon","spare","chain","brand","fell","chop","weave","sew","cook","brew","play","race","wrestle","walk","march","sail","swim","climb","go","come","stay","wait","listen","watch","count","mark","remember","forget","destroy","tear","break","kill","slaughter","cull"]
const NON_ORDER_STARTS := ["the","a","an","our","we","it","its","it's","they","their","there","this","that","these","those","he","she","his","her","my","i","you","your","yes","no.","ok","okay","thanks","thank","hello","hi","hmm","well"]

# --------------------------------------------------------------------------
# Reading an order
# --------------------------------------------------------------------------

static func _padded(text:String)->String:
	var normalized:=text.to_lower().replace("’","'")
	for mark in [".",",",";",":","!","?","\"","(",")","\n","\t"]: normalized=normalized.replace(String(mark)," ")
	while "  " in normalized: normalized=normalized.replace("  "," ")
	return " %s " % normalized.strip_edges()

static func _has_term(padded:String,term:String)->int:
	## Terms match at a word start; a trailing space in the term requires a word end.
	return padded.find(" "+term)

static func detect_natures(text:String)->Array[String]:
	var padded:=_padded(text)
	var positions:Dictionary={}
	for nature_variant in NATURES:
		var nature:=String(nature_variant)
		for term_variant in (NATURES[nature] as Dictionary).get("terms",[]):
			var position:=_has_term(padded,String(term_variant))
			if position>=0:
				positions[nature]=mini(int(positions.get(nature,position)),position)
	var sacrifice:=_has_term(padded,"sacrific")
	if sacrifice>=0:
		var human:=false
		for word in HUMAN_WORDS:
			if _has_term(padded,String(word))>=0: human=true
		for word in ANIMAL_WORDS:
			if _has_term(padded,String(word))>=0: human=false
		positions["human_sacrifice" if human else "worship"]=sacrifice
	if positions.has("selective_breeding"): positions.erase("marriage")
	if positions.has("polygamy"): positions.erase("marriage")
	if positions.has("human_sacrifice"): positions.erase("worship")
	if positions.has("miracle"): positions.erase("custom_art")
	var ranked:Array=positions.keys()
	ranked.sort_custom(func(a:Variant,b:Variant)->bool: return int(positions[a])<int(positions[b]))
	var result:Array[String]=[]
	for nature in ranked:
		result.append(String(nature))
		if result.size()>=3: break
	return result

static func looks_like_order(text:String,speech_act:String)->bool:
	## Every explicit order is honoured. Plain statements and small talk are not
	## orders even when the speech-act guard could not classify them.
	if speech_act=="directive": return true
	if speech_act=="non_directive": return false
	var padded:=_padded(text)
	var words:=padded.strip_edges().split(" ",false)
	if words.is_empty(): return false
	var first:=String(words[0])
	if first in NON_ORDER_STARTS: return not detect_natures(text).is_empty() and (" must " in padded or " shall " in padded or " will be " in padded)
	if first in IMPERATIVE_VERBS: return true
	if first in IMPERATIVE_STARTS: return not detect_natures(text).is_empty()
	# An unfamiliar first word followed by a recognised nature is still a command
	# ("Sire children…", "Monuments to me everywhere").
	return not detect_natures(text).is_empty()

static func _intensity(padded:String)->float:
	var scale:=1.0
	for word in INTENSIFIERS:
		if _has_term(padded,String(word))>=0: scale=1.15
	for word in SOFTENERS:
		if _has_term(padded,String(word))>=0: scale=minf(scale,0.65)
	return scale

static func _summary(text:String)->String:
	var clean:=text.strip_edges().replace("\n"," ")
	return clean.substr(0,140)

static func offline_plan(text:String,future_delay:int=0,catalog_ids:Array=[])->Dictionary:
	## Deterministic lexicon reading used when no live model is available, and to
	## supply side effects and costs for a model plan. Returns {} when a catalog
	## policy already covers everything this text asks for.
	var natures:=detect_natures(text)
	var padded:=_padded(text)
	if not catalog_ids.is_empty():
		var supplements:Array[String]=[]
		for nature in natures:
			if bool((NATURES[nature] as Dictionary).get("supplement",false)): supplements.append(nature)
		natures=supplements
		if natures.is_empty(): return {}
	if natures.is_empty(): natures=["generic"]
	return plan_from_natures(natures,text,future_delay,catalog_ids,_intensity(padded))

static func plan_from_natures(natures:Array[String],text:String,future_delay:int,catalog_ids:Array,intensity:float=1.0)->Dictionary:
	var padded:=_padded(text)
	var effects:Dictionary={}
	var coercion:=0.0
	var feasibility:=1.0
	var food_share:=0.0
	var material_share:=0.0
	var covered:Dictionary={}
	for catalog_id in catalog_ids:
		for nature in natures:
			for parameter in ((NATURES[nature] as Dictionary).get("covered_by",{}) as Dictionary).get(String(catalog_id),[]):
				covered[String(parameter)]=true
	for nature in natures:
		var spec:Dictionary=NATURES[nature]
		coercion=maxf(coercion,float(spec.get("coercion",0.1)))
		feasibility=minf(feasibility,float(spec.get("feasibility",1.0)))
		food_share=maxf(food_share,float((spec.get("costs",{}) as Dictionary).get("food",0.0)))
		material_share=maxf(material_share,float((spec.get("costs",{}) as Dictionary).get("materials",0.0)))
		for row_variant in spec.get("effects",[]):
			var row:Array=row_variant
			var parameter:=String(row[0])
			if covered.has(parameter): continue
			var strength:=clampf(float(row[1])*intensity,-1.0,1.0)
			if effects.has(parameter):
				var prior:Dictionary=effects[parameter]
				prior["strength"]=clampf(float(prior.strength)+strength*0.5,-1.0,1.0)
				continue
			effects[parameter]={"parameter":parameter,"strength":strength,"uncertainty":0.25,"days":float(row[3]) if float(row[3])>0.0 else -1.0,"delay_days":float(row[2]),"reason":String(spec.get("act","the order"))}
	for term in COERCION_TERMS:
		if _has_term(padded,String(term))>=0:
			coercion=clampf(coercion+0.25,0.0,0.95)
			if not effects.has("resentment"): effects["resentment"]={"parameter":"resentment","strength":0.25,"uncertainty":0.2,"days":-1.0,"delay_days":0.0,"reason":"people resent being compelled"}
			break
	# "In ten years" is when a future order starts, not how long it lasts.
	var duration:Dictionary={} if future_delay>0 else PronouncementInterpreter._explicit_duration(text.to_lower())
	# Customs and standing arrangements outlast a work order.
	var nature_days:=DEFAULT_DAYS
	for nature in natures: nature_days=maxf(nature_days,float((NATURES[nature] as Dictionary).get("days",DEFAULT_DAYS)))
	var days:=float(duration.get("days",nature_days))
	var list:Array[Dictionary]=[]
	for effect_variant in effects.values():
		var effect:Dictionary=effect_variant
		if float(effect.days)<0.0: effect["days"]=days
		effect["delay_days"]=float(effect.delay_days)+float(future_delay)
		list.append(effect)
	return {
		"summary":_summary(text),"natures":natures,"feasibility":feasibility,"coercion":coercion,
		"effects":DecreeStatistics.validate_custom_effects(list),
		"costs":{"food_share":food_share,"material_share":material_share},
		"days":days,"future_delay":future_delay,"source":"lexicon",
	}

static func attempt_plan(text:String)->Dictionary:
	## The realistic result of trying when the proper means are missing: effort
	## spent, a little of what was wanted, and people noticing the shortfall.
	var natures:Array[String]=["attempt"]
	for nature in detect_natures(text):
		if natures.size()>=3: break
		natures.append(nature)
	var plan:=plan_from_natures(natures,text,0,[],1.0)
	plan["feasibility"]=minf(float(plan.get("feasibility",1.0)),0.2)
	plan["source"]="attempt"
	return plan

static func plan_from_offline(interpretation:Dictionary,text:String,future_delay:int=0,catalog_ids:Array=[])->Dictionary:
	## An answer from the offline interaction database: its scaled effects,
	## costs, counted deaths and consequences, over the lexicon's natures (for
	## side effects and the leader's words).
	var effects_raw:Array=interpretation.get("offline_effects",[])
	if effects_raw.is_empty(): return {}
	var natures:=detect_natures(text)
	if natures.is_empty(): natures=["generic"]
	var plan:=plan_from_natures(natures,text,future_delay,catalog_ids,_intensity(_padded(text)))
	var effects:=DecreeStatistics.effects_from_offline(effects_raw,float(plan.days))
	if effects.is_empty(): return {}
	# Recorded profiles speak in the six broad metrics; the lexicon adds the
	# parameters they cannot name (fertility, violence, resentment, migration…).
	var named:Dictionary={}
	for effect in effects:
		named[String(effect.parameter)]=true
		if future_delay>0: effect["delay_days"]=clampf(float(effect.delay_days)+float(future_delay),0.0,3650.0)
	for lexicon_effect in plan.get("effects",[]):
		if effects.size()>=DecreeStatistics.MAX_CUSTOM_EFFECTS: break
		if not named.has(String(lexicon_effect.parameter)): effects.append(lexicon_effect)
	plan["effects"]=effects
	var costs:Dictionary=interpretation.get("offline_costs",{}) if interpretation.get("offline_costs",{}) is Dictionary else {}
	var stored_food:=maxf(1.0,float(WorldSimulation.system("FoodSystem").call("total_stored")))
	var materials_available:=maxf(1.0,WorldSimulation.consequences._directive_material_available())
	plan["costs"]={"food_share":clampf(DecreeStatistics._number_or(costs.get("food_person_days"),0.0)/stored_food,0.0,0.25),"material_share":clampf(DecreeStatistics._number_or(costs.get("materials"),0.0)/materials_available,0.0,0.25)}
	var counted:Dictionary=interpretation.get("offline_counted",{}) if interpretation.get("offline_counted",{}) is Dictionary else {}
	if String(counted.get("kind",""))=="population_deaths": plan["counted_deaths"]=clampi(int(counted.get("count",0)),0,50)
	var narratives:Array=[]
	for side_variant in interpretation.get("offline_side_effects",[]):
		if side_variant is Dictionary and not String((side_variant as Dictionary).get("description","")).is_empty(): narratives.append((side_variant as Dictionary).duplicate())
		if narratives.size()>=4: break
	plan["narrative_side_effects"]=narratives
	plan["offline_type"]=String(interpretation.get("offline_type",""))
	plan["source"]="interaction database"
	return plan

static func validate_model_plan(raw:Variant,text:String,future_delay:int=0,catalog_ids:Array=[])->Dictionary:
	## The live model's proposal, bounded. Natures it names (or the lexicon finds)
	## supply side effects, costs and deaths; the model supplies primary effects.
	if not raw is Dictionary: return {}
	var proposal:Dictionary=raw
	if not bool(proposal.get("applies",false)): return {}
	var natures:Array[String]=[]
	for nature_variant in proposal.get("natures",[]):
		var nature:=String(nature_variant)
		if NATURES.has(nature) and not natures.has(nature): natures.append(nature)
		if natures.size()>=3: break
	for nature in detect_natures(text):
		if natures.size()>=3: break
		if not natures.has(nature): natures.append(nature)
	if natures.is_empty(): natures=["generic"]
	var lexicon:=plan_from_natures(natures,text,future_delay,catalog_ids,_intensity(_padded(text)))
	var effects:=DecreeStatistics.validate_custom_effects(proposal.get("effects",[]))
	if effects.is_empty(): effects=lexicon.effects
	for effect in effects:
		if future_delay>0: effect["delay_days"]=clampf(float(effect.delay_days)+float(future_delay),0.0,3650.0)
	# Either reading may recognise a physically impossible ask; the stricter wins.
	var feasibility:=minf(clampf(DecreeStatistics._number_or(proposal.get("feasibility"),1.0),0.02,1.0),float(lexicon.get("feasibility",1.0)))
	var costs:Dictionary=proposal.get("costs",{}) if proposal.get("costs",{}) is Dictionary else {}
	var summary:=String(proposal.get("summary","")).strip_edges().substr(0,160)
	return {
		"summary":summary if not summary.is_empty() else _summary(text),"natures":natures,
		"feasibility":feasibility,
		"coercion":clampf(DecreeStatistics._number_or(proposal.get("coercion"),float(lexicon.coercion)),0.0,1.0),
		"effects":effects,
		"costs":{"food_share":clampf(DecreeStatistics._number_or(costs.get("food_share"),float(lexicon.costs.food_share)),0.0,0.25),"material_share":clampf(DecreeStatistics._number_or(costs.get("material_share"),float(lexicon.costs.material_share)),0.0,0.25)},
		"days":_longest_days(effects,float(lexicon.days)),"future_delay":future_delay,"source":"model",
	}

static func _longest_days(effects:Array,fallback:float)->float:
	var longest:=0.0
	for effect in effects: longest=maxf(longest,float((effect as Dictionary).get("days",0.0)))
	return longest if longest>=7.0 else fallback

static func policy_from_plan(plan:Dictionary)->Dictionary:
	var days:=float(plan.get("days",DEFAULT_DAYS))
	var confidence:=0.9 if not (plan.get("natures",[]) as Array).has("generic") else 0.74
	return {
		"id":ID,"action":"enact","action_source":"custom directive","office":"Council","skills":["Administration","Diplomacy"],
		"effects":{},"magnitude":MAIN_MAGNITUDE,"days":days,"basis":String(plan.get("summary","")).substr(0,160),"confidence":confidence,
		"parameter_basis":"custom","magnitude_source":"custom","duration_source":"custom","ripple":String(plan.get("summary","")),
		"directive_parameters":{"custom_plan":plan.duplicate(true)},
	}

static func display_name(plan:Dictionary)->String:
	var summary:=String(plan.get("summary","your order")).strip_edges()
	if summary.is_empty(): return "your order"
	return "“%s”" % summary.substr(0,90)

# --------------------------------------------------------------------------
# Feasibility and application
# --------------------------------------------------------------------------

static func assessment(plan:Dictionary,duration_days:float,office_execution:float)->Dictionary:
	var state:=WorldSimulation.state
	var population:=maxf(1.0,state.population_exact)
	var institutions:=clampf(float(state.society_capacities.get("institutions",0.0)),0.0,1.0)
	var administration_share:=float(state.population_allocations.get("Administration",0))/population
	var defense_share:=float(state.population_allocations.get("Defense",0))/population
	var security:=clampf(float(state.simulation_metrics.get("security",state.society_capacities.get("security",0.0))),0.0,1.0)
	var legitimacy:=clampf(float(state.simulation_metrics.get("legitimacy",0.5)),0.0,1.0)
	var cohesion:=clampf(float(state.simulation_metrics.get("cohesion",0.5)),0.0,1.0)
	var administration_capacity:=clampf(institutions*0.62+clampf(administration_share/0.06,0.0,1.0)*0.38,0.0,1.0)
	var security_capacity:=clampf(security*0.72+clampf(defense_share/0.08,0.0,1.0)*0.28,0.0,1.0)
	var coercion:=clampf(float(plan.get("coercion",0.1)),0.0,1.0)
	var compliance:=clampf(0.12+legitimacy*0.38+cohesion*0.34+(1.0-coercion)*0.12+security_capacity*coercion*0.28,0.05,0.98)
	var resistance:=clampf(1.0-compliance+coercion*(1.0-security_capacity)*0.25,0.0,1.0)
	var administration_required:=0.08+coercion*0.18
	# Effort always happens; thin administration narrows it but never nulls it.
	var administration_factor:=clampf(administration_capacity/administration_required,0.3,1.0)
	var costs:Dictionary=plan.get("costs",{})
	var stored_food:=maxf(0.0,float(WorldSimulation.system("FoodSystem").call("total_stored")))
	var food_available:=maxf(0.0,stored_food-population*2.0)
	var food_requested:=stored_food*clampf(float(costs.get("food_share",0.0)),0.0,0.25)
	var material_available:=WorldSimulation.consequences._directive_material_available()
	var material_requested:=material_available*clampf(float(costs.get("material_share",0.0)),0.0,0.25)
	var food_factor:=1.0 if food_requested<=0.0001 else clampf(food_available/food_requested,0.25,1.0)
	var material_factor:=1.0 if material_requested<=0.0001 else clampf(material_available/maxf(0.0001,material_requested),0.25,1.0)
	if material_requested>0.0001 and material_available<=0.0001: material_factor=0.25
	var implementation:=clampf(clampf(office_execution,0.0,1.12)*administration_factor*minf(food_factor,material_factor)*(0.45+compliance*0.55),0.08,1.0)
	var limitations:Array[String]=[]
	if administration_factor<0.6: limitations.append("administrative coverage is thin for this order")
	if food_factor<0.9: limitations.append("food stores cannot fund all of it while keeping a reserve")
	if material_factor<0.9: limitations.append("material stores cannot fund all of it")
	if float(plan.get("feasibility",1.0))<0.2: limitations.append("what is asked lies beyond what people can do; only the attempt is possible")
	var days:=clampf(duration_days,7.0,730.0)
	return {
		"id":ID,"domain":"social","can_apply":true,"blocker":"","limitations":limitations,
		"requested_magnitude":MAIN_MAGNITUDE,"effective_magnitude":MAIN_MAGNITUDE*implementation,"duration_days":days,
		"implementation_rate":implementation,"office_execution":clampf(office_execution,0.0,1.12),
		"capacity":{"active":0,"slots":1,"factor":1.0},
		"constraints":{"administration":{"available":administration_capacity,"required":administration_required,"factor":administration_factor},"security":{"available":security_capacity,"required":0.0,"factor":1.0},"feasibility":float(plan.get("feasibility",1.0))},
		"costs":{"food_requested":food_requested,"food_available":food_available,"food_planned":food_requested*implementation,"materials_requested":material_requested,"materials_available":material_available,"materials_planned":material_requested*implementation},
		"compliance":compliance,"resistance":resistance,"coercion":coercion,"direct_effects_planned":{},
		"second_order_consequence":String(plan.get("summary","")),"directive_parameters":{"custom_plan":plan.duplicate(true)},
		"operation":"","operation_quote":{},"deadline_enforcement":"","bounded":true,
	}

static func _rng(order_id:String,plan:Dictionary)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|%s|%s" % [int(WorldSimulation.state.world_seed),order_id,String(plan.get("summary",""))])
	return rng

static func realize(plan:Dictionary,order_id:String,implementation:float)->Array[Dictionary]:
	## Final effects: primary effects with their uncertainty rolled and scaled by
	## feasibility and implementation, plus side effects rolled from the nature
	## table. Deterministic for a given world seed, order and wording.
	var rng:=_rng(order_id,plan)
	var feasibility:=clampf(float(plan.get("feasibility",1.0)),0.0,1.0)
	var days:=float(plan.get("days",DEFAULT_DAYS))
	var result:Array[Dictionary]=[]
	for effect_variant in plan.get("effects",[]):
		var effect:Dictionary=(effect_variant as Dictionary).duplicate(true)
		var parameter:=String(effect.get("parameter",""))
		var rolled:=float(effect.get("strength",0.0))*(1.0+rng.randf_range(-1.0,1.0)*float(effect.get("uncertainty",0.2))*0.5)
		# The attempt at an impossible thing still costs effort and stirs feeling;
		# only the intended physical result is scaled by feasibility.
		var effort:=parameter in ["labor","cohesion","resentment","legitimacy","food_use"] and rolled*float(DecreeStatistics.channel_value(parameter,1.0))<0.0
		var scale:=implementation*(1.0 if effort or parameter in ["cohesion","resentment"] else feasibility)
		effect["strength"]=clampf(rolled*scale,-1.0,1.0)
		effect["value"]=DecreeStatistics.channel_value(parameter,float(effect.strength)) if parameter!="resentment" else float(effect.strength)*float(DecreeStatistics.PARAMETERS.resentment.max)
		effect["side_effect"]=false
		result.append(effect)
	var future_delay:=float(plan.get("future_delay",0))
	for nature_variant in plan.get("natures",[]):
		var spec:Dictionary=NATURES.get(String(nature_variant),{})
		for row_variant in spec.get("side",[]):
			var row:Array=row_variant
			var chance:=clampf(float(row[2])*(0.6+0.4*implementation),0.0,0.95)
			var roll:=rng.randf()
			if roll>=chance: continue
			var parameter:=String(row[0])
			var strength:=clampf(float(row[1])*rng.randf_range(0.7,1.0)*sqrt(implementation),-1.0,1.0)
			result.append({
				"parameter":parameter,"strength":strength,
				"value":DecreeStatistics.channel_value(parameter,strength) if parameter!="resentment" else strength*float(DecreeStatistics.PARAMETERS.resentment.max),
				"uncertainty":0.0,"days":float(row[4]) if float(row[4])>0.0 else days,
				"delay_days":float(row[3])+future_delay+float(rng.randi_range(0,12)),
				"reason":"unforeseen: %s" % String(nature_variant).replace("_"," "),"side_effect":true,"nature":String(nature_variant),
			})
	# Recorded/typed consequences from the interaction database: narrative only
	# (the leader reports them if they happen); their numbers are the effects.
	for narrative_variant in plan.get("narrative_side_effects",[]):
		var narrative:Dictionary=narrative_variant
		if rng.randf()>=clampf(float(narrative.get("odds",0.0))*(0.6+0.4*implementation),0.0,0.95): continue
		result.append({"parameter":"","strength":0.0,"value":0.0,"uncertainty":0.0,"days":days,
			"delay_days":future_delay+float(rng.randi_range(10,60)),"reason":String(narrative.get("description","")).substr(0,160),
			"side_effect":true,"narrative":true,"nature":String(narrative.get("id",""))})
	return result

static func _deaths(plan:Dictionary,order_id:String,implementation:float)->Dictionary:
	var rng:=_rng(order_id+"|deaths",plan)
	var population:=maxf(1.0,WorldSimulation.state.population_exact)
	var counted:=int(plan.get("counted_deaths",0))
	if counted>0 and implementation>=0.2:
		# A recorded exchange named a count (one sacrifice, one example): exact,
		# and never more than a hundredth of the people.
		return {"count":mini(counted,maxi(1,floori(population*0.01))),"cause":"sacrifice","deliberate":true,"nature":"counted","delay_days":0}
	for nature_variant in plan.get("natures",[]):
		var spec:Dictionary=NATURES.get(String(nature_variant),{})
		var row:Array=spec.get("deaths",[])
		if row.is_empty(): continue
		var deliberate:=bool(row[4])
		var chance:=float(row[0])*(1.0 if deliberate else (0.6+0.4*implementation))
		if rng.randf()>=chance: continue
		var count:=clampi(maxi(1,roundi(population*float(row[1])*rng.randf_range(0.5,1.0))),1,int(row[2]))
		if deliberate and implementation<0.2: count=0
		if count>0: return {"count":count,"cause":String(row[3]),"deliberate":deliberate,"nature":String(nature_variant),"delay_days":0 if deliberate else rng.randi_range(5,40)}
	return {}

static func apply(plan:Dictionary,duration_days:float,source:String,metadata:Dictionary,office_execution:float)->Dictionary:
	var state:=WorldSimulation.state
	var order_id:=String(metadata.get("source_order_id",""))
	var assessed:=assessment(plan,duration_days,office_execution)
	assessed["source_order_id"]=order_id
	var implementation:=float(assessed.implementation_rate)
	var realized:=realize(plan,order_id,implementation)
	var day:=float(state.elapsed_days)
	var resistance:=float(assessed.resistance)*float(assessed.coercion)*0.8
	# Group effects into records by start day so delayed and side effects only
	# act on the engine once they begin.
	var groups:Dictionary={}
	for effect in realized:
		var parameter:=String(effect.parameter)
		if not DecreeStatistics.PARAMETERS.has(parameter): continue
		var start:=day+float(effect.get("delay_days",0.0))
		var span:=float(effect.get("days",duration_days))
		var side:=bool(effect.get("side_effect",false))
		var key:="%s|%d|%d" % ["side" if side else "main",roundi(start),roundi(span)]
		if not groups.has(key): groups[key]={"start":start,"span":span,"side":side,"effects":{},"resentment":0.0,"parameters":[]}
		var group:Dictionary=groups[key]
		(group.parameters as Array).append(parameter)
		if parameter=="resentment":
			group["resentment"]=float(group.resentment)+float(effect.value)
			continue
		var channel:=String((DecreeStatistics.PARAMETERS[parameter] as Dictionary).channel)
		var channels:Dictionary=group.effects
		channels[channel]=float(channels.get(channel,0.0))+float(effect.value)
	var baseline:=observation_snapshot()
	var records:=0
	var keys:Array=groups.keys()
	keys.sort()
	# The main, immediate record is appended first so reports find it.
	keys.sort_custom(func(a:Variant,b:Variant)->bool:
		var ga:Dictionary=groups[a]; var gb:Dictionary=groups[b]
		if bool(ga.side)!=bool(gb.side): return not bool(ga.side)
		return float(ga.start)<float(gb.start))
	var future_delay:=float(plan.get("future_delay",0))
	if keys.is_empty() or bool((groups[keys[0]] as Dictionary).side) or float((groups[keys[0]] as Dictionary).start)>day+future_delay:
		# Every order carries a main record, even when its effects start later.
		# A future-dated order's record begins on its day.
		groups["main|anchor"]={"start":day+future_delay,"span":duration_days,"side":false,"effects":{},"resentment":0.0,"parameters":[]}
		keys.push_front("main|anchor")
	for key in keys:
		var group:Dictionary=groups[key]
		var side:=bool(group.side)
		var magnitude:=SIDE_MAGNITUDE if side else maxf(0.02,MAIN_MAGNITUDE*implementation)
		var coefficients:Dictionary={}
		for channel in group.effects:
			coefficients[channel]=float(group.effects[channel])/magnitude
		var record:={
			"id":ID,"kind":"policy","effects":coefficients,"magnitude":magnitude,
			"started_day":float(group.start),"until_day":float(group.start)+clampf(float(group.span),1.0,3650.0),
			"description":source,"source_order_id":order_id,"source_order_sequence":int(metadata.get("source_order_sequence",0)),
			"office":String(metadata.get("office","Council")),"executor":String(metadata.get("executor","")),
			"custom_role":"side_effect" if side else ("primary" if records==0 else "delayed"),
			"custom_parameters":(group.parameters as Array).duplicate(),
			"resistance":clampf((resistance if not side else 0.0)+float(group.resentment),0.0,1.0),
			"compliance":float(assessed.compliance),"coercion":float(assessed.coercion),
			"execution_factor":implementation,"implementation_rate":implementation,
			"directive_domain":"social","second_order_consequence":String(plan.get("summary","")),
		}
		if records==0:
			record["custom_plan"]=plan.duplicate(true)
			record["custom_realized"]=realized.duplicate(true)
			record["custom_baseline"]=baseline
			record["directive_parameters"]={"custom_plan":plan.duplicate(true)}
		state.active_modifiers.append(record)
		records+=1
	# Costs come out of real stores.
	var costs:Dictionary=(assessed.costs as Dictionary).duplicate(true)
	if future_delay>0.0:
		# Stores are spent when the day comes, from whatever exists then.
		costs["food_paid"]=0.0
		costs["materials_paid"]=0.0
		for modifier_variant in state.active_modifiers:
			var modifier:Dictionary=modifier_variant
			if String(modifier.get("source_order_id",""))==order_id and String(modifier.get("id",""))==ID and modifier.has("custom_plan"):
				modifier["custom_pending_costs"]={"day":int(day+future_delay),"food_share":float((plan.get("costs",{}) as Dictionary).get("food_share",0.0))*implementation,"material_share":float((plan.get("costs",{}) as Dictionary).get("material_share",0.0))*implementation,"label":String(plan.get("summary","order")).substr(0,60)}
				break
	else:
		var paid:=_pay(float(costs.get("food_planned",0.0)),float(costs.get("materials_planned",0.0)),String(plan.get("summary","order")),duration_days)
		costs["food_paid"]=float(paid.food)
		costs["materials_paid"]=float(paid.materials)
	# A small immediate shift so the order is felt at once, not only as a slow
	# drift of targets. Future-dated orders shift nothing yet.
	var direct:Dictionary={}
	var immediate_map:={"cohesion":"cohesion","legitimacy":"legitimacy","security":"security","health":"health"}
	for effect in realized:
		if bool(effect.get("side_effect",false)) or float(effect.get("delay_days",0.0))>0.0: continue
		var parameter:=String(effect.parameter)
		if not immediate_map.has(parameter): continue
		var metric:=String(immediate_map[parameter])
		var before:=float(state.simulation_metrics.get(metric,state.population_health if metric=="health" else 0.5))
		var after:=clampf(before+float(effect.value)*0.35,0.01,0.99)
		state.simulation_metrics[metric]=after
		if metric=="health": state.population_health=after
		direct[metric+"_delta"]=after-before
	var death:=_deaths(plan,order_id,implementation)
	if not death.is_empty() and float(plan.get("future_delay",0))<=0.0:
		if bool(death.deliberate):
			var registered:=state.register_directive_population_deaths(int(death.count),ID,"%s (%s)" % [String(death.cause).capitalize(),String(plan.get("summary","")).substr(0,60)],{})
			direct["population_deaths"]=int(registered.get("count",0))
		else:
			# Accidents happen during the work, not at the moment of the order.
			for modifier_variant in state.active_modifiers:
				var modifier:Dictionary=modifier_variant
				if String(modifier.get("source_order_id",""))==order_id and String(modifier.get("id",""))==ID and modifier.has("custom_plan"):
					modifier["custom_pending_deaths"]={"count":int(death.count),"cause":String(death.cause),"day":int(day)+int(death.delay_days)}
					break
	WorldSimulation.consequences._add_event("Directive Implemented","%s — %s." % [String(plan.get("summary","A custom order")),"implementation is broad" if implementation>=0.72 else "implementation is uneven" if implementation>=0.36 else "implementation is narrow"],"social","notice")
	assessed["costs"]=costs
	assessed["direct_effects_applied"]=direct
	return {"applied":true,"assessment":assessed,"direct_effects":direct,"costs":costs,"custom_realized":realized}

static func _pay(food:float,materials:float,label:String,duration_days:float)->Dictionary:
	var food_paid:=0.0
	if food>0.01:
		food_paid=float(WorldSimulation.system("FoodSystem").call("issue_for_obligation",food,"directive","Directive: %s" % label.substr(0,60),duration_days,0))
	var materials_paid:=WorldSimulation.consequences._withdraw_directive_materials(materials) if materials>0.0001 else 0.0
	return {"food":food_paid,"materials":materials_paid}

static func process_day()->void:
	## Pending accident deaths and deferred costs from custom orders resolve on
	## their day. Called by ConsequenceEngine once per simulated day.
	var state:=WorldSimulation.state
	var today:=int(state.elapsed_days)
	for modifier_variant in state.active_modifiers:
		var modifier:Dictionary=modifier_variant
		if String(modifier.get("id",""))!=ID: continue
		if modifier.has("custom_pending_costs") and today>=int((modifier.custom_pending_costs as Dictionary).get("day",today)):
			var pending_costs:Dictionary=modifier.custom_pending_costs
			modifier.erase("custom_pending_costs")
			var stored_food:=maxf(0.0,float(WorldSimulation.system("FoodSystem").call("total_stored")))
			var paid:=_pay(stored_food*float(pending_costs.get("food_share",0.0)),WorldSimulation.consequences._directive_material_available()*float(pending_costs.get("material_share",0.0)),String(pending_costs.get("label","order")),float(modifier.get("until_day",today))-float(today))
			modifier["custom_costs_paid"]=paid
		if not modifier.has("custom_pending_deaths"): continue
		var pending:Dictionary=modifier.custom_pending_deaths
		if today<int(pending.get("day",today)): continue
		modifier.erase("custom_pending_deaths")
		var registered:=state.register_population_deaths(int(pending.get("count",0)),String(pending.get("cause","Work accidents")))
		modifier["custom_accident_deaths"]=int(registered.get("count",0))

static func observation_snapshot()->Dictionary:
	var state:=WorldSimulation.state
	var metrics:=state.simulation_metrics
	return {
		"day":int(state.elapsed_days),"population":float(state.population_exact),
		"births":int(state.lifetime_births),"conceptions":int(state.lifetime_conceptions),"pregnancies":int(state.estimated_active_pregnancies()),
		"neonatal_deaths":int(state.lifetime_neonatal_deaths),"deaths":int(state.lifetime_deaths),"departures":int(state.lifetime_departures),
		"cohesion":float(metrics.get("cohesion",0.5)),"legitimacy":float(metrics.get("legitimacy",0.5)),"knowledge":float(metrics.get("knowledge",0.0)),
		"security":float(metrics.get("security",0.5)),"health":float(state.population_health),"ecology":float(metrics.get("ecology",0.8)),
		"food":float(state.resource_stockpiles.get("Food",0.0)),"labor_efficiency":float(metrics.get("labor_efficiency",0.7)),
	}

# --------------------------------------------------------------------------
# Follow-up report
# --------------------------------------------------------------------------

const REPORT_LINES := {
	"fertility":["More women are carrying than before.","Fewer women are with child than before."],
	"infant_mortality":["Some of the new babies have not lived long.","The newborns are thriving better than they used to."],
	"disease":["A coughing sickness has gone round the huts.","Fewer fevers this season."],
	"health":["People look stronger for it.","People are worn thin by it."],
	"cohesion":["The households pull together more.","There is bad blood between households now."],
	"legitimacy":["They speak your name with more awe.","People mutter against the order, and against you, I fear."],
	"security":["The camp feels safer at night.","The camp feels less safe at night."],
	"violence":["Men have come to blows over it; one still limps.","Tempers have cooled."],
	"knowledge":["The young ones are sharper at reckoning, the elders say.","Less is being learned than before."],
	"labor":["The work goes quicker.","The work has cost us hands elsewhere."],
	"food_use":["The racks empty faster.","We are eating less."],
	"food_yield":["There is more food on the racks.","The food coming in has thinned."],
	"materials":["We have more to build and make with.","Materials are harder to come by."],
	"logistics":["Loads move more easily.","Hauling has slowed."],
	"construction":["Building goes faster.","Building has slowed."],
	"water":["Water comes easier.","Water is harder to bring in."],
	"ecology":["The land is resting.","The land is scarred by it."],
	"migration":["Newcomers have come to our fires.","A few families have slipped away in the night."],
	"resentment":["There is resentment, quiet for now.","The resentment has eased."],
}

static func evaluate(order_id:String,snapshot:Dictionary,current_day:int)->Dictionary:
	var main:Dictionary={}
	var records:Array[Dictionary]=[]
	for modifier_variant in WorldSimulation.state.active_modifiers:
		var modifier:Dictionary=modifier_variant
		if String(modifier.get("id",""))!=ID or String(modifier.get("source_order_id",""))!=order_id: continue
		records.append(modifier)
		if main.is_empty() and modifier.has("custom_plan"): main=modifier
	if main.is_empty():
		return {"id":ID,"label":"the order","outcome":"failure","delivery_score":0.0,"qualitative_evidence":"","limitations":["the standing implementation ended before this report"],"bounded":true,"custom_speech":"I must report that the order did not take hold. Nothing of it is still being done.","custom_receipt":""}
	var plan:Dictionary=main.get("custom_plan",{})
	var implementation:=clampf(float(main.get("implementation_rate",0.5)),0.0,1.0)
	var baseline:Dictionary=main.get("custom_baseline",{})
	var now:=observation_snapshot()
	var lines:Array[String]=[]
	var spoken:Dictionary={}
	# Intended effects that have begun.
	for effect_variant in main.get("custom_realized",[]):
		var effect:Dictionary=effect_variant
		var parameter:=String(effect.get("parameter",""))
		if spoken.has(parameter) or float(effect.get("delay_days",0.0))>float(current_day-int(baseline.get("day",current_day))): continue
		if absf(float(effect.get("strength",0.0)))<0.05: continue
		var positive:=float(effect.strength)>0.0
		var options:Array=REPORT_LINES.get(parameter,[])
		if options.is_empty(): continue
		lines.append(String(options[0] if positive else options[1]))
		spoken[parameter]=true
		if lines.size()>=3: break
	# Unforeseen effects that have surfaced.
	var surfaced:Array[String]=[]
	for effect_variant in main.get("custom_realized",[]):
		var effect:Dictionary=effect_variant
		if not bool(effect.get("side_effect",false)): continue
		if float(effect.get("delay_days",0.0))>float(current_day-int(baseline.get("day",current_day))): continue
		var parameter:=String(effect.get("parameter",""))
		if bool(effect.get("narrative",false)):
			var description:=String(effect.get("reason","")).strip_edges().trim_suffix(".")
			if description.is_empty(): continue
			lines.append("And something none of us foresaw: %s." % _lower_first(description) if surfaced.is_empty() else "%s." % (description.substr(0,1).to_upper()+description.substr(1)))
			surfaced.append(String(effect.get("nature","")))
			continue
		var options:Array=REPORT_LINES.get(parameter,[])
		if options.is_empty() or surfaced.has(parameter): continue
		surfaced.append(parameter)
		var line:=String(options[0] if float(effect.strength)>0.0 else options[1])
		if not lines.has(line): lines.append("And something none of us foresaw: %s" % _lower_first(line) if surfaced.size()==1 else line)
	var accident:=int(main.get("custom_accident_deaths",0))
	if accident>0: lines.append("We lost %s to it." % ("one of ours" if accident==1 else "%d of ours" % accident))
	var outcome:="success" if implementation>=0.64 else "partial" if implementation>=0.31 else "failure"
	if float(plan.get("feasibility",1.0))<0.2: outcome="failure"
	var opening:="It is done as you ordered." if outcome=="success" else "It is partly done." if outcome=="partial" else "I must report that it did not take hold."
	if float(plan.get("feasibility",1.0))<0.2: opening="We tried, with every rite and every hand. It did not take hold."
	var receipt:=_report_receipt(baseline,now,surfaced)
	return {
		"id":ID,"label":display_name(plan),"outcome":outcome,"delivery_score":implementation,
		"planned_implementation":implementation,"current_capacity":implementation,"observed_evidence":0.5,"continuity":1.0,
		"observation_summary":receipt,"qualitative_evidence":"","limitations":[],"bounded":true,
		"custom_speech":("%s %s" % [opening," ".join(lines)]).strip_edges(),"custom_receipt":receipt,"surfaced_side_effects":surfaced,
	}

static func _report_receipt(baseline:Dictionary,now:Dictionary,surfaced:Array[String])->String:
	var parts:Array[String]=[]
	if baseline.is_empty(): return ""
	parts.append("since day %d" % int(baseline.get("day",0)))
	parts.append("conceptions %d" % maxi(0,int(now.conceptions)-int(baseline.get("conceptions",0))))
	parts.append("births %d" % maxi(0,int(now.births)-int(baseline.get("births",0))))
	var newborn:=maxi(0,int(now.neonatal_deaths)-int(baseline.get("neonatal_deaths",0)))
	if newborn>0: parts.append("newborn deaths %d" % newborn)
	parts.append("deaths %d" % maxi(0,int(now.deaths)-int(baseline.get("deaths",0))))
	for metric in ["cohesion","legitimacy","knowledge","health","security"]:
		var before:=float(baseline.get(metric,0.0))
		var after:=float(now.get(metric,0.0))
		if absf(after-before)>=0.0005: parts.append("%s %.3f to %.3f" % [metric,before,after])
	if not surfaced.is_empty(): parts.append("unforeseen: %s" % ", ".join(PackedStringArray(surfaced.map(func(x:String)->String: return DecreeStatistics.label(x).replace("_"," ")))))
	return " · ".join(parts)

# --------------------------------------------------------------------------
# Voice
# --------------------------------------------------------------------------

static func breaks_frame(text:String)->bool:
	var low:=text.to_lower()
	for phrase in FRAME_BREAKS:
		if String(phrase) in low: return true
	return false

static func persona(leader:Dictionary)->Dictionary:
	if leader.is_empty(): return {}
	return CV.for_person(leader)

static func _lead(p:Dictionary,salt:String)->String:
	var tics:Array=p.get("tics",[])
	if tics.is_empty(): return ""
	return String(tics[posmod(hash(salt),tics.size())])

static func _lower_first(s:String)->String:
	return s.substr(0,1).to_lower()+s.substr(1) if not s.is_empty() else s

static func _soften_opening(text:String)->String:
	## Lower-case a common opening word after an address; keep names capitalised.
	var first:=text.get_slice(" ",0)
	if first in ["I","It","We","The","There","That","This","A","An","More","Some","No","Yes","When","If","And","Our","Your","They","What","As","At","Then","Now","Only","Every","Consider"]:
		return _lower_first(text) if first!="I" else text
	return text

static func _address(p:Dictionary,salt:String)->String:
	# The address term appears in at most one line in three.
	if posmod(hash(salt+"|address"),3)!=0: return ""
	return String(p.get("address",""))

static func voiced(leader:Dictionary,body:String,salt:String)->String:
	## Wrap plain in-world content in this leader's lifelong manner: one lead-in
	## from their manner, their address term now and then, and the god-regard
	## colour (terror hurries, worship exalts, resentment clips).
	var p:=persona(leader)
	var regard:=DivineRegard.regard(leader) if not leader.is_empty() else {}
	var prefix:=""
	match String(regard.get("id","")):
		"terror": prefix="At once. "
		"hates_dread": prefix="As you command. "
		"worships": prefix="Your will moves us. "
		"resents": prefix="As you say. "
	var lead:=_lead(p,salt)
	var address:=_address(p,salt)
	var text:=body.strip_edges()
	if not address.is_empty(): text="%s, %s" % [address,_soften_opening(text)]
	if not lead.is_empty() and prefix.is_empty(): text="%s %s" % [lead,text]
	else: text=prefix+text
	return text.strip_edges()

static func acceptance_body(plan:Dictionary,capacity_phrase:String)->String:
	var natures:Array=plan.get("natures",["generic"])
	var spec:Dictionary=NATURES.get(String(natures[0]) if not natures.is_empty() else "generic",NATURES.generic)
	var act:=String(spec.get("act","set people to it"))
	var risk:=String(spec.get("risk",""))
	var body:="I will %s." % act
	if String(natures[0] if not natures.is_empty() else "generic") in ["generic","attempt"] and not String(plan.get("summary","")).is_empty():
		body="I will %s: “%s.”" % [act,String(plan.summary).strip_edges().trim_suffix(".")]
	if float(plan.get("future_delay",0))>0.0: body="When the day comes, I will %s." % act
	if float(plan.get("feasibility",1.0))<0.2: body="No one has ever done such a thing, but I will %s." % act
	if not risk.is_empty(): body+=" %s." % risk.trim_suffix(".")
	if not capacity_phrase.is_empty(): body+=" "+capacity_phrase
	return body

static func notable_answer(leader:Dictionary,notable:Dictionary,salt:String)->String:
	return voiced(leader,Notables.answer_line(notable),salt)

static func discussion_body(text:String)->String:
	## An in-world answer to a question the catalog does not cover: the leader
	## reasons from what they know, never from what "the records" hold.
	var natures:=detect_natures(text)
	if natures.is_empty():
		return "I would have to walk the camp and ask before I answered that well. Tell me what you want done, and it will be done."
	var spec:Dictionary=NATURES[natures[0]]
	return "If you bid me %s, I would do it. %s. Say the word." % [String(spec.get("act","do it")),String(spec.get("risk","It would cost us something")).trim_suffix(".")]
