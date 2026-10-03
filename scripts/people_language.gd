extends RefCounted
## EVERY PEOPLE SPEAKS ITS OWN TONGUE.
##
## Each people (ours and every other) has a language of its own: a sound
## family (the feel of West African, Bantu, Polynesian, Turkic, Sinitic,
## Japonic, Nahuatl, Andean, Semitic, Slavic, Finnic, Inuit... speech; thirty
## in all) and, within it, its own choice of sounds, favourite endings, a
## small store of place words ("water", "hill", "stone") and a way of naming
## people: given name and family name, given name and father's name, or given
## name and clan. Its people, its towns and the people's own name all come
## from it, so a neighbour's envoy never sounds like one of ours, and two
## peoples never share a name.
##
## Every word is generated, never a real one: names are drawn from the sounds,
## then held against people_name_blocklist.gd (real places, peoples, famous and
## sacred figures, everyday English words, offensive strings). Real history is
## calibration only (docs: alternative-history naming).
##
## DETERMINISTIC AND KEPT. A people's tongue is made from the world seed and
## the people's id. The few numbers that make it ({family, seed}) are kept
## where the people's own records live (GameState.people_language for ours,
## the people's record in CivilizationSystem.civilizations for others) and
## made again from the seed when absent (older saves). Names already given stay
## as they are: only new names come from the tongues.
##
## The sound family is chosen apart from a people's looks (people_appearance.gd):
## a tongue says nothing about skin or descent.
##
## Static helpers; preload. No simulation RNG is used.

const Blocklist:=preload("res://scripts/people_name_blocklist.gd")

const VERSION:=1
## The peoples a world is made with: ours and up to 36 others
## (civilization_system.gd MAX_RIVAL_CIVILIZATIONS).
const ROSTER:=36
const NO_SEED:=-9223372036854775807
## The things every tongue has a word for, used in its place names.
const CONCEPTS:=["water","river","lake","sea","hill","mountain","stone","wood","field","home","high","new","red","white","black","sun","bird","fire","spring","island"]
## Ground a town stands on, and the words its name may take.
const LAND_CONCEPTS:={"shore":["sea","island","water"],"river":["river","water","spring"],"reed":["water","lake","bird"],"wood":["wood","bird","black"],
	"hill":["hill","mountain","stone","high"],"grass":["field","sun","white"],"sun":["sun","red","stone"],"frost":["white","stone","high"],"plain":["field","home","new"]}
## Letter groups heard as one sound when consonants are counted.
const UNITS:=["tch","sh","ch","kh","th","ph","gh","zh","ng","ny","ts","tz","dz","tl","ll","rr","kw","gw","bh","dh","gb","kp","qh","mb","nd","nj","nz","mw","rh"]
const VOWELS:="aeiou"
## Longest a name may be: given and second name together fit a herald's line.
const FULL_MAX:=18
## Syllables in a root, a family name and a place word; vowel groups in a
## given name; where a family does not say.
const COUNT_DEFAULTS:={"syl":"1 2","famsyl":"1 2","lexsyl":"1 1 2","gv":"2 3"}

## The sound families. Lists are space separated ("_" is no sound):
## on/mid: first and later syllable onsets; v: vowels; dip: vowel pairs (pd:
## how often); cod/fin: syllable and word-final consonants (pc/pf: how often);
## clu: consonant clusters inside a word; oni/vi: onsets that take only the
## vi vowels (Sinitic j, q, x); fix: sound changes ("si:shi");
## fs/ms: shapes of women's and men's names (C consonant, V vowel, K cluster,
## Q final consonant; ps: how often a shape is used) else a root and one of
## the f/m endings; ft/mt/famt/placet/folkt: templates around a word ("Ix%s");
## syl/famsyl/lexsyl: syllables in a root; gv: vowel groups a given name has;
## fam: family-name endings, famf: masculine:feminine forms; place: town
## endings; folk: the people's-name endings; tongue: the tongue's name ("+" is
## a space); pattern: family, patronym (the father's name) or clan;
## mode "syllabic": names built of whole syllables (Sinitic, Koreanic);
## gsyl: the syllables given names are made of, two at a time (Koreanic);
## gem: doubled consonants allowed; maxc/maxv: longest consonant/vowel run;
## avoid: endings that would read as English ("-ing", "-ed", "-ly").
const FAMILIES:={
	"west_african":{"on":"k k t t m m b d f s n l w y j ch kw ny _ _","mid":"b d f g k l m n s t w y j ch kw ny nk nt nd mb ng","v":"a a e i o o u","f":"a a e ya ola ike oma ua esi efa ina","m":"o u e i emi ade edu ka nna eku ofi","syl":"1 2 2","gv":"2 3","fam":"u wu or ah eng ola ide yi ama ekwe ike ong eme","famsyl":"1 2 2","place":"si ma ugu ta oko ra ado ani ena","folk":"_ a e","tongue":"%sgbe %s"},
	"bantu":{"on":"b ch d f g h j k l m n p s sh t v w y z mb nd ng nj nz mw kw ny _","mid":"b ch d f g h j k l m n p s sh t v w y z mb nd ng nk nt nz ny mw kw","v":"a a a e i i o u u","f":"a i e iwe ile ana ela isa ani ima eza ita","m":"o u i a ani ela ezi ika ende ongo uli","syl":"1 2 2","gv":"2 3","fam":"a e o i wa we ana ezi ombe ulu ira","famsyl":"1 2","place":"ma ni ngo ombe ezi oro ani we ala","folkt":"Wa%s Ba%s Ama%s","tongue":"Ki%s Chi%s Isi%s Si%s Lu%s"},
	"ethiopic":{"on":"b d f g h k l m n s sh t w y z ch _","mid":"b d f g h k l m n s sh t w y z ch r","v":"a a e e i o u","cod":"n r l s t m b","pc":0.25,"fin":"n m s t l r","pf":0.4,"fs":"CeCaC CiCiCt CeCeCa CaCet CiCot CeCeCa aCaCu","ms":"CaCiC CeCaCe CaCeCe CeCeCeC CaCaCu CoCaC aCeCe","ps":0.75,"f":"et ot am i e a ina","m":"e u it on aye ew o","syl":"1 2","gv":"2 3","place":"ar ama a e ole ela","folk":"_ e","tongue":"%sinya %signa","pattern":"patronym"},
	"polynesian":{"on":"h k l m n p t w v f r _ _","mid":"h k l m n p t w v f r ng","v":"a a e i o u","dip":"ai au ae ao ei oa ou","pd":0.15,"f":"a ani ina ele oa ehu ana ea","m":"i o u ana iki ea","syl":"1 2 2","gv":"2 4","fam":"a i o u ia ana ea","famsyl":"1 2","place":"a ua ia ea iki ono au","folk":"_","tongue":"Te+Reo+%s","pattern":"clan"},
	"austronesian":{"on":"b d g h j k l m n p r s t w y _","mid":"b d g h j k l m n p r s t w y ng ny mb nd nt mp nj","v":"a a a e i o u","cod":"n ng m r s t k","pc":0.25,"fin":"n ng r s t h k","pf":0.4,"f":"i a ah ayu ati ini ari ita","m":"o u an ar i ung adi ono","syl":"1 2 2","gv":"2 3","fam":"an ang ero on ia o ana ito","famsyl":"1 2","place":"ang an ur aya ong ari ung","folk":"_ a","tongue":"Basa+%s"},
	"turkic":{"on":"b ch d g k m n s sh t y z _ _ _ _","mid":"b ch d g j k l m n r s sh t y z","v":"a a e i o u","cod":"n r l k s z m y t","pc":0.5,"fin":"n r l k s z m y t sh","pf":0.7,"f":"ay in el ira ana ize sel ul ime","m":"an er ek ur at ay im al bek han","syl":"1 1 2","gv":"2 3","fam":"er an soy tas kan dag ay ov ev oglu","famsyl":"1 2","place":"kent tash kul dag su ar","folk":"ak ar en ir","tongue":"%sche %sca"},
	"mongolic":{"on":"b ch d g j k kh m n s sh t ts y z _ _ _","v":"a a e i o u o","cod":"n r l g d s m t","pc":0.4,"fin":"n r l g d s m t","pf":0.6,"f":"aa tuya gerel tseg maa jin","m":"bat ochir sukh dorj erdene tulga khuu","syl":"1 2 2","gv":"2 4","place":"khot nuur gol uul tal","folk":"ad _","tongue":"%s+Khel","pattern":"patronym"},
	"sinitic":{"on":"b p m f d t n l g k h zh ch sh r z s w","v":"a ai an ang ao e ei en eng o ong ou u ua uan ui un uo","pc":0.0,"pf":0.0,"oni":"j q x y b p m d t n l","vi":"i ia ian iang iao ie in ing iu iong","fix":"zo:zuo so:suo co:cuo zho:zhuo cho:chuo sho:shuo ro:ruo do:duo to:tuo no:nuo lo:luo go:guo ko:kuo ho:huo nui:nei lui:lei bui:bei pui:pei mui:mei fui:fei bong:beng pong:peng mong:meng fong:feng wong:weng wui:wei wun:wen wuo:wo wua:wa wuan:wan yia:ya yian:yan yiang:yang yiao:yao yie:ye yiu:you yiong:yong fai:fei fao:fou bua:ba pua:pa mua:ma fua:fa bun:ben pun:pen mun:men fun:fen buan:ban puan:pan muan:man fuan:fan biong:bing piong:ping miong:ming diong:ding tiong:ting niong:ning liong:ling bia:bian pia:pian mia:miao dia:diao tia:tiao","syl":"1 2 2 2","gv":"1 2","famsyl":"1","place":"zhou cheng ling shan he an kou ning du","tongue":"%shua %syu","mode":"syllabic","given_min":2,"fam_min":2},
	"japonic":{"on":"k k s s t t n n h m m y r r w g d _ sh ch k t m n h s","v":"a a i u e o o","cod":"n","pc":0.12,"fin":"n","pf":0.1,"fix":"si:shi ti:chi tu:tsu hu:fu zi:ji di:ji du:zu yi:i ye:e wi:i wu:u we:e wo:o she:se che:te je:ze","f":"ko mi e na ka ri yo ho ne ki","m":"ro ta to ki shi ya hei o ji suke","syl":"1 2 2","gv":"2 4","fam":"da ta moto mura kawa no oka shima saki hara","famsyl":"1 2","place":"ura kawa oka shima saki hama yama no be","tongue":"%sgo","gem":1},
	"koreanic":{"gsyl":"ji min seo yeon su hyun jun woo ha yun eun hye jin so a in do ho sung young jae won hee kyung sang tae hoon bin yu chae na ri da gyu mi seul ye han sol hwa jeong sook ok cheol yong gi hak beom seon nam il ju yeong hwan seok chan gyeong si ga bo rin sae dan joon kang moon byeol hyeon ae","on":"j s m h d g k b n ch t _ j s m h","v":"a a eo o u i i e eu ae oo","pc":0.45,"fin":"n n ng ng l k m","pf":0.35,"oni":"_ _ h","vi":"ye yeo yu yo ya wo wa","syl":"2","gv":"2 2","famsyl":"1","place":"ju won san cheon dong po","tongue":"%smal %seo","mode":"syllabic","given_min":3,"fam_min":2},
	"tai_khmer":{"on":"s ch k kh t th p ph n m w r l y b d _","v":"a a o i u e ae ai ao","cod":"n m ng k t p","pc":0.35,"fin":"n m ng k t p","pf":0.45,"f":"a i ee anya isa ana ali","m":"chai sak wit rat on an ith","syl":"1 1 2","gv":"2 3","fam":"wong sakul suk wat korn phan rat chai sri","famsyl":"1 2","place":"buri thani wang khet phon","tongue":"Phasa+%s"},
	"nahuatl":{"on":"t tl tz ch k kw m n p s sh y w x _","mid":"t tl tz ch k kw m n p s sh y w x l","v":"a a e i o","cod":"n k s ch l w","pc":0.25,"fin":"tl n k s","pf":0.3,"f":"li i tl ali eli itzi ina","m":"tl atl oc otl in i","syl":"1 2 2","gv":"2 4","fam":"tl in an ca co","famsyl":"1 2","place":"tlan pan co tepec apan can","folk":"ca tlaca","tongue":"%satl","pattern":"clan"},
	"mayan":{"on":"b ch k l m n p s t tz w x y j _","v":"a a e i o u","cod":"b k l m n s t x j ch","pc":0.4,"fin":"b k l m n s t x j ch tz","pf":0.65,"ft":"Ix%s %s %s","mt":"Aj%s %s %s %s","f":"el a il ul","m":"_ ab al ek","syl":"1 2 2","gv":"2 3","famsyl":"1 2","place":"ha tun kab al il","tongue":"%s+Tan","pattern":"clan"},
	"andean":{"on":"ch k p q t s y w l ll m n r h _ _ k t","mid":"ch k p q t s sh y w l ll m n ny r h","v":"a a a i u u","cod":"q k n s y w r","pc":0.3,"fin":"q k n s y","pf":0.35,"f":"a i y sa lla cha","m":"q n ru ki ka","syl":"1 2 2","gv":"2 3","fam":"i ni ri ca pe na za","famsyl":"1 2","place":"marka pampa qucha wasi tampu","tongue":"%s+Simi"},
	"semitic":{"on":"b d f g h j k kh l m n q r s sh t th w y z _","mid":"b d f h j k kh l m n q r s sh t th w y z","v":"a a a i i u e o","cod":"b d f h k l m n r s sh t z","pc":0.4,"fin":"b d f k l m n r s sh t z","pf":0.55,"fs":"CaCiCa CaCCa CaCiC aCiCa CaCaC CiCaC CaCia","ms":"CaCiC CaCiC CaCaC aCCaC CaCCaC CuCaC CiCaC","ps":0.75,"f":"a ah ira ina iya it","m":"im ir id an ar el on","syl":"1 2","gv":"2 3","fam":"i ani awi iya un","famsyl":"1 2","place":"iya at un ar el","folk":"_ i im","tongue":"%sit %siya"},
	"iranic":{"on":"b d f g h j k kh l m n p r s sh t v z _","mid":"b d f g h j k kh l m n p r s sh t v z zh","v":"a a e i o u","cod":"n r m s sh d z b h","pc":0.4,"fin":"n r m s sh d z b","pf":0.5,"fs":"CaCiCa CiCiC CaCeh CiCa CoCa CaCaC aCaCeh","ms":"aCaC CaCaC CaCiC CaCCaC CaCeh oCiC CaCuC","ps":0.7,"f":"in eh a ar az ana","m":"ash ad an am ar id","syl":"1 2","gv":"2 3","fam":"i ian zadeh pour far vand","famsyl":"1 2","place":"abad shahr an gerd kand dasht","folk":"an i","tongue":"%si"},
	"indo_aryan":{"on":"b ch d g h j k l m n p r s sh t v y _ b d k m n p r s v","mid":"b ch d g h j k l m n p r s sh t v y dh kh","v":"a a a i i u e o","cod":"n m r s l t k","pc":0.3,"fin":"n m r l t k","pf":0.45,"f":"a i ika ita ini ya ali","m":"esh it an ay av ul endra","syl":"1 2 2","gv":"2 3","fam":"a i ar wal kar ani ra","famsyl":"1 2","place":"pur abad nagar garh ganj","folk":"i a","tongue":"%si"},
	"dravidian":{"on":"k ch t p m n v y r l s j _ _","mid":"k ch t th p m n v y r l s j nd nn tt mm ll kk ng nj","v":"a a i u e o ai","cod":"n m l r","pc":0.2,"fin":"n m l r","pf":0.4,"f":"a i athi itha ya ani avi","m":"an am esh ar u appa","syl":"1 2 2","gv":"2 4","place":"ur palli patti pettai puram kottai","folk":"ar","tongue":"%su %sam","pattern":"patronym","gem":1},
	"slavic":{"on":"b v g d z k l m n p r s t ch sh br dr gr kr pr tr st sv zl vl _ b v d k l m n p r s t","mid":"b v g d zh z k l m n p r s t ch sh","v":"a a o o e i u","cod":"n r l s v k m t","pc":0.25,"fin":"n r l s v k m t sh d","pf":0.45,"f":"a ana ina ena ka ya ica ava ila","m":"an ek or slav mir ko ir","syl":"1 1 2","gv":"2 3","fam":"ov ev in ski ich enko ak ek uk","famf":"ov:ova ev:eva in:ina ski:ska","famsyl":"1 2","place":"grad ovo ava ets sk ica in ov","folk":"ane ichi","tongue":"%sski","avoid":"ing ed"},
	"germanic":{"on":"b d f g h j k l m n p r s t v w br dr fr gr kr st sv sk tr _","mid":"b d f g h j k l m n p r s t v w","v":"a a e e i o u o","dip":"ei ie oo aa","pd":0.06,"cod":"n l r s t k m d","pc":0.3,"fin":"n l r s t k m d rs ns ls ts ks lt nt nk rk rn rt st ld","pf":0.65,"clu":"lt nk nn ll rt rn nd ns lk lm rd tt ss mm rk ng lv","fs":"CVKe CVCa CVCVC VKa CVKa CVCe VCVn CiCa CVKa","ms":"CVQ CVQ CVCVQ VCVC CVKe CVC CVCeQ VKeQ","ps":0.85,"f":"a e ke je ine ie","m":"_ e o en er ar","syl":"1 1 2","gv":"1 3","lexsyl":"1","fam":"sen berg strom dal gaard ma stra inga er holm lund vik","famsyl":"1 1 2","place":"by stad heim dorp hus vik holm","folk":"ar ingar","tongue":"%ssk %sisk","avoid":"ing ed ly ness ment tion ful less ish"},
	"romance":{"on":"b c d f g l m n p r s t v _ b c d l m p s t br tr","mid":"b c d f g l m n p r s t v ll tt nz","v":"a a e i o o u","dip":"ia io ie au","pd":0.08,"cod":"n l r s","pc":0.2,"fin":"n l r s","pf":0.3,"clu":"rl lv nz nt rc rt ld nd lb rm ll tt ss rg","fs":"CVCia CVCVa CVKa VCVna CVCina CVKia VKa CVCVla","ms":"CVCo CVKo CVCVCo VCVCo CVKio CVCVs CVCiel CVKiel","ps":0.85,"f":"a ia ina ella etta ine elle","m":"o io ino el an or e","syl":"1 1 2","gv":"2 3","fam":"i ini elli etti ez ero ard ier escu eanu one","famsyl":"1 2","place":"ano ella ac ona esa ia ento","folk":"ani esi ois","tongue":"%sano %sais","gem":1,"avoid":"ing ed ly tion ment"},
	"celtic":{"on":"b c d f g gw ll m n p r rh s t br gl _","mid":"b c d f g m n r s t w l dd th","v":"a a e i o y","dip":"ae ai ei ia io","pd":0.1,"cod":"n l r s","pc":0.2,"fin":"n l r s th d","pf":0.5,"clu":"rw nw lw ff dd ll rd nd rn","fs":"CeCyQ CVCa eiCa CVCwen CVCen VCVn CiCa CVKen CVCi","ms":"CeCiQ VCeQ CVCan CVQ CVCin VCyQ CoCan CVKin CVCyn","ps":0.85,"f":"a en wen ys ia ine","m":"_ an ed in og","syl":"1 1 2","gv":"1 3","lexsyl":"1","fam":"an en og ec in","famt":"Tre%s Pen%s Ker%s Lan%s %s %s %s","famsyl":"1 2","placet":"Aber%s Bryn%s Caer%s Dun%s Kil%s Tre%s Pen%s Llan%s","tongue":"%seg %sek","avoid":"ing ed ly"},
	"hellenic":{"on":"p t k b d g f th kh m n l r s z pl pr tr kl kr st sp _","v":"a a e i o o i","dip":"ia io ou ei ai","pd":0.12,"cod":"n s r l","pc":0.2,"fin":"s n","pf":0.1,"f":"a i ia ou ini ina","m":"os is as on ias","syl":"1 2 2","gv":"2 3","fam":"opoulos akis idis atos as","famf":"opoulos:opoulou akis:aki idis:idou atos:atou as:a","famsyl":"1 2","place":"polis ia os ion ada ini","folk":"ites","tongue":"%sika","avoid":"ing ed"},
	"finnic":{"on":"h j k l m n p r s t v _ _","mid":"h j k l m n p r s t v kk tt pp ll nn mm ss","v":"a a e i o u","dip":"aa ee ii oo uu ai ei oi ui au ou ie uo","pd":0.2,"cod":"n l r s t k","pc":0.3,"fin":"n s","pf":0.2,"f":"a i o ina ja ka","m":"o i a u ri","syl":"1 2 2","gv":"2 3","fam":"nen la lainen o sto mets saar","famsyl":"1 2","place":"la lahti joki jarvi maa salo niemi koski","folk":"_ t","tongue":"%s+Kieli","gem":1},
	"inuit":{"on":"k q t p s m n l v j _ _ ng","mid":"k q t p s m n ng l v j r g kk qq tt mm nn ll","v":"a a i i u","dip":"aa ii uu","pd":0.15,"cod":"q k t p m n l r","pc":0.25,"fin":"q k t n","pf":0.45,"f":"aq uk ik a i ut juaq","m":"aq uk ik a i ut juaq","syl":"1 2 2","gv":"2 3","place":"vik juaq tuuq lik","folkt":"%smiut","tongue":"%stitut %stun","pattern":"patronym","gem":1},
	"athabaskan":{"on":"b ch d dz g h j k l n s sh t tl ts y zh _","v":"a a e i o","dip":"aa ii oo ee ai ei","pd":0.2,"cod":"n l sh s d h","pc":0.25,"fin":"n l sh s d h zh","pf":0.4,"f":"ni ba ah oni i","m":"kai iil ish eh an","syl":"1 2 2","gv":"2 3","fam":"nii ii tsoh ah","famsyl":"1 2","place":"tah ito yi kai","tongue":"%s+Bizaad","pattern":"clan"},
	"algonquian":{"on":"k m n p s sh t w ch b g _","mid":"k m n p s sh t w ch b g j z","v":"a a e i o","dip":"aa ii oo","pd":0.15,"cod":"n k s sh m w","pc":0.3,"fin":"n k s sh w","pf":0.4,"f":"kwe a i","m":"_ ik ash in ens","syl":"1 2 2","gv":"2 3","famsyl":"1 2","place":"ing ong sipi kamik","folk":"ak wak","tongue":"%smowin","pattern":"clan"},
	"kartvelian":{"on":"b d g k p t kh gh sh ch ts dz j l m n r s v z zh gv kv tb mts _","mid":"b d g k p t kh gh sh ch ts dz j l m n r s v z zh","v":"a a e i o u","cod":"n r l s t d","pc":0.2,"fin":"n r l s","pf":0.15,"f":"o a i an","m":"i a an ur o","syl":"1 2 2","gv":"2 3","fam":"shvili dze ia ava ani uri eli","famsyl":"1 2","place":"eti ubani tsikhe ani","folk":"eli","tongue":"%suli","maxc":3},
	"amazigh":{"on":"b d f g gh h j k l m n r s sh t w y z _","mid":"b d f g gh h j k l m n r s sh t w y z zz","v":"a a i u e","cod":"n r l s t m z d f","pc":0.4,"fin":"n r l s t m z d","pf":0.5,"ft":"Ta%st Ti%s %s %s","mt":"A%s I%s %s %s","f":"a i","m":"s n l r ir as","syl":"1 2","gv":"2 4","famt":"Ou%s","famsyl":"1 2","placet":"Ta%st Tin%s Ag%s I%sen","folkt":"I%sen","tongue":"Ta%st Ta%sit"},
	"aboriginal":{"on":"b d g j k l m n ng ny p r t w y _","mid":"b d g j k l m n ng ny p r rr t w y rl rn nd nj ngg mb ly","v":"a a a i u u","cod":"l n rr r ny ng m","pc":0.3,"fin":"n l rr","pf":0.25,"f":"a i ina ari","m":"u a o ara angu","syl":"1 2 2","gv":"2 3","fam":"ngu ra arra ari","famsyl":"1 2","place":"arra ong ingi ana uru","tongue":"%s+Wangka","pattern":"clan"},
}

static var _bases:Dictionary={}
static var _profiles:Dictionary={}
static var _worlds:Dictionary={}
static var _rosters:Dictionary={}


# --------------------------------------------------------------------------
# Which tongue a people speaks
# --------------------------------------------------------------------------

## The sound family a people speaks: every people of a world made with up to
## thirty peoples speaks a different one; larger worlds repeat families (each
## people still has its own sounds, endings and words).
static func family_for(seed_value:int,owner:String)->String:
	var ids:Array=FAMILIES.keys()
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value^0x2c1b3c6d
	var order:Array=range(ids.size())
	for i in range(order.size()-1,0,-1):
		var j:=rng.randi_range(0,i);var held:Variant=order[i];order[i]=order[j];order[j]=held
	return String(ids[int(order[posmod(_slot(owner),ids.size())])])

static func _slot(owner:String)->int:
	if owner=="player" or owner=="":return 0
	var number:=owner.trim_prefix("civ_")
	if owner.begins_with("civ_") and number.is_valid_int() and int(number)>0:return int(number)
	return ROSTER+1+posmod(owner.hash(),997)

## What makes a people's tongue: {family, seed, v, world_seed}. The kept one
## when there is one for this world, else made from the seed and kept.
static func record(owner:String,seed_value:int)->Dictionary:
	if owner=="":owner="player"
	var kept:=_kept(owner,seed_value)
	if FAMILIES.has(String(kept.get("family",""))) and kept.has("seed"):return kept
	var made:={"family":family_for(seed_value,owner),"seed":absi(("%d:tongue:%s" % [seed_value,owner]).hash()),"v":VERSION,"world_seed":seed_value}
	_keep(owner,seed_value,made)
	return made

static func _kept(owner:String,seed_value:int)->Dictionary:
	if GameState==null or seed_value!=int(GameState.world_seed):return {}
	if owner=="player":
		var mine:Variant=GameState.get("people_language")
		if mine is Dictionary and int((mine as Dictionary).get("world_seed",seed_value-1))==seed_value:return mine
		return {}
	var civ:=_civ(owner)
	var theirs:Variant=civ.get("language",{})
	if theirs is Dictionary and int((theirs as Dictionary).get("world_seed",seed_value))==seed_value:return theirs
	return {}

static func _keep(owner:String,seed_value:int,made:Dictionary)->void:
	if GameState==null or seed_value!=int(GameState.world_seed):return
	if owner=="player":
		if GameState.get("people_language") is Dictionary:GameState.set("people_language",made.duplicate())
		return
	var civ:=_civ(owner)
	if not civ.is_empty():civ["language"]=made.duplicate()

static func _civ(owner:String)->Dictionary:
	if CivilizationSystem==null:return {}
	for civ:Variant in CivilizationSystem.civilizations:
		if civ is Dictionary and String((civ as Dictionary).get("id",""))==owner:return civ
	return {}


# --------------------------------------------------------------------------
# A people's tongue
# --------------------------------------------------------------------------

## The whole tongue of a people: its sounds, endings, place words, the
## people's own name ("people"), its stem and the tongue's name
## ("tongue_name"). Cached; never changes for a world.
static func profile(owner:String="player",seed_value:int=NO_SEED)->Dictionary:
	if seed_value==NO_SEED:seed_value=int(GameState.world_seed) if GameState!=null else 0
	if owner=="":owner="player"
	var key:="%d|%s" % [seed_value,owner]
	if _profiles.has(key):return _profiles[key]
	_ensure_world(seed_value)
	if _profiles.has(key):return _profiles[key]
	var made:=_build(owner,seed_value)
	_name_people(made,_worlds[seed_value])
	_profiles[key]=made
	return made

## The people's own name for themselves ("Wakumbe").
static func people_name(owner:String="player",seed_value:int=NO_SEED)->String:
	return String(profile(owner,seed_value).people)

## The name of their tongue ("Kikumbe").
static func tongue_name(owner:String="player",seed_value:int=NO_SEED)->String:
	return String(profile(owner,seed_value).tongue_name)

## How the people name a person: "family" (given and family name),
## "patronym" (given and father's name) or "clan" (given and clan name).
static func pattern(owner:String="player",seed_value:int=NO_SEED)->String:
	return String(profile(owner,seed_value).pattern)

## Forgets every cached tongue (tests, a new world with a reused seed).
static func clear_cache()->void:
	_profiles.clear();_worlds.clear();_rosters.clear()

static func _ensure_world(seed_value:int)->void:
	if _worlds.has(seed_value):return
	if _profiles.size()>600:clear_cache()
	var taken:={}
	_worlds[seed_value]=taken
	for i in ROSTER+1:
		var owner:="player" if i==0 else "civ_%02d" % i
		var made:=_build(owner,seed_value)
		_name_people(made,taken)
		_profiles["%d|%s" % [seed_value,owner]]=made

static func _base(family:String)->Dictionary:
	if _bases.has(family):return _bases[family]
	var raw:Dictionary=FAMILIES.get(family,FAMILIES.west_african)
	var p:={"family":family}
	for k in ["on","mid","v","dip","cod","fin","clu","oni","vi","gsyl","fs","ms","ft","mt","f","m","fam","famt","place","placet","folk","folkt","tongue","avoid"]:
		p[k]=_list(String(raw.get(k,"")))
	if (p.mid as Array).is_empty():p.mid=(p.on as Array).duplicate()
	for k in ["syl","famsyl","lexsyl","gv"]:
		var numbers:Array=[]
		for x in _list(String(raw.get(k,COUNT_DEFAULTS[k]))):numbers.append(int(x))
		p[k]=numbers
	var fin_real:Array=[]
	for x in p.fin:if String(x)!="":fin_real.append(x)
	p["fin_real"]=fin_real
	for k in ["pd","pc","pf"]:p[k]=float(raw.get(k,0.0))
	p["ps"]=float(raw.get("ps",0.5))
	p["pattern"]=String(raw.get("pattern","family"))
	p["mode"]=String(raw.get("mode",""))
	p["gem"]=int(raw.get("gem",0))
	p["maxc"]=int(raw.get("maxc",2))
	p["maxv"]=int(raw.get("maxv",2))
	p["given_min"]=int(raw.get("given_min",3))
	p["fam_min"]=int(raw.get("fam_min",3))
	var fix:={}
	for pair in _list(String(raw.get("fix",""))):fix[String(pair).get_slice(":",0)]=String(pair).get_slice(":",1)
	p["fix"]=fix
	var famf:Array=[]
	for pair in _list(String(raw.get("famf",""))):famf.append([String(pair).get_slice(":",0),String(pair).get_slice(":",1)])
	p["famf"]=famf
	# Doubled letters a sound of the tongue already has ("ll", "dd", "nn").
	var inv:={}
	for k in ["on","mid","cod","fin","clu","oni","dip"]:
		for x in p[k]:
			var s:=String(x)
			for i in range(s.length()-1):inv[s.substr(i,2)]=true
	p["inv"]=inv
	_bases[family]=p
	return p

static func _list(text:String)->Array:
	var out:Array=[]
	for word in text.split(" ",false):out.append("" if word=="_" else String(word))
	return out

static func _build(owner:String,seed_value:int)->Dictionary:
	var rec:=record(owner,seed_value)
	var p:Dictionary=_base(String(rec.family)).duplicate(true)
	var rng:=RandomNumberGenerator.new();rng.seed=int(rec.seed)
	p["owner"]=owner;p["world_seed"]=seed_value;p["seed"]=int(rec.seed)
	# This people keeps most of its family's sounds and some of its endings.
	for k in ["on","mid"]:
		var keep:Array=[];var real:=0
		for x in p[k]:
			if String(x)=="" or rng.randf()<0.85:
				keep.append(x)
				if String(x)!="":real+=1
		if real>=6:p[k]=keep
	for k in ["f","m","fam","place"]:
		var list:Array=p[k]
		if list.size()>4:p[k]=_sample(list,maxi(4,list.size()-rng.randi_range(0,2)),rng)
	p["lex"]=_lexicon(p,rng)
	_stem(p,rng)
	return p

static func _sample(list:Array,count:int,rng:RandomNumberGenerator)->Array:
	var pool:=list.duplicate();var out:Array=[]
	while out.size()<count and not pool.is_empty():out.append(pool.pop_at(rng.randi_range(0,pool.size()-1)))
	return out

static func _lexicon(p:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var lex:={};var seen:={}
	for concept in CONCEPTS:
		for attempt in 80:
			var word:=_root(p,rng,int(_pick(p.lexsyl,rng)),true).to_lower()
			if seen.has(word) or not _valid(word,p,2,6,1,2):continue
			lex[concept]=word;seen[word]=true;break
	return lex

## A stem for the people's and the tongue's names.
static func _stem(p:Dictionary,rng:RandomNumberGenerator)->void:
	var stem:=""
	for attempt in 80:
		stem=_root(p,rng,[2,2,3][rng.randi_range(0,2)],false).to_lower()
		if _valid(stem,p,3,8,2,3):break
	p["stem"]=stem
	var tongue:=_cap(stem)
	var forms:Array=p.tongue
	if not forms.is_empty():
		var made:=_template(String(_pick(forms,rng)),stem).to_lower()
		if not Blocklist.blocks(made.replace(" ","")) and made.replace(" ","").length()<=14:tongue=_cap(made)
	p["tongue_name"]=tongue

static func _name_people(p:Dictionary,taken:Dictionary)->void:
	var rng:=_rng(p,"people")
	for attempt in 80:
		if attempt>0:_stem(p,rng)
		var stem:=String(p.stem)
		var name:=""
		if not (p.folkt as Array).is_empty():name=_template(String(_pick(p.folkt,rng)),stem)
		else:name=_join(stem,String(_pick(p.folk,rng)) if not (p.folk as Array).is_empty() else "",p)
		name=name.to_lower()
		if not _valid(name,p,4,10,2,4) or taken.has(name):continue
		taken[name]=true
		p["people"]=_cap(name)
		# A tongue is called otherwise than its people where it has a form for it.
		if String(p.tongue_name).to_lower()==name:
			for form in p.tongue:
				var other:=_template(String(form),stem).to_lower()
				if other!=name and not Blocklist.blocks(other.replace(" ","")):
					p["tongue_name"]=_cap(other);break
		return
	p["people"]=_cap(String(p.stem))


# --------------------------------------------------------------------------
# Names
# --------------------------------------------------------------------------

## A given name of this people (a woman's or a man's), from a key that always
## gives the same name. A name in `taken` (as written, or "given:<Name>") is
## passed over while another can be found.
static func given(owner:String,seed_value:int,key:String,woman:bool,taken:Dictionary={})->String:
	return _given(profile(owner,seed_value),key,woman,taken)

## The second name of a person of this people: a family name (in the woman's
## or man's form where the tongue has two), a father's name or a clan name, as
## the people name people. `family` (a kinsman's) is kept, in this person's form.
static func second(owner:String,seed_value:int,key:String,woman:bool,family:String="",taken:Dictionary={})->String:
	var p:=profile(owner,seed_value)
	if family.strip_edges()!="":return gendered(p,family.strip_edges(),woman)
	if String(p.pattern)=="patronym":return _given(p,key+":father",false,taken)
	var rng:=_rng(p,"family:"+key)
	var fallback:=""
	for attempt in 48:
		var word:=_family_word(p,rng)
		if word=="":continue
		# Both forms must pass ("Stas" is a name, "Sta" is not).
		var other:=gendered(p,word,not woman)
		word=gendered(p,word,woman)
		if Blocklist.blocks(word) or Blocklist.blocks(other) or word.length()<int(p.fam_min):continue
		if fallback=="":fallback=word
		if taken.has(word) or taken.has("byname:"+word):continue
		return word
	return fallback

## A byname: what a person is called before writing or lasting institutions,
## when nothing is handed down. A plain word of the tongue (often a place word
## or two of it), never with a family-name ending ("-ov", "-zadeh",
## "-shvili", "-sen", "-opoulos") or a family-name prefix ("Ou-", "Tre-").
## A people that names by the father calls a person by the father's name.
static func byname(owner:String,seed_value:int,key:String,woman:bool,taken:Dictionary={})->String:
	var p:=profile(owner,seed_value)
	if String(p.pattern)=="patronym":return _given(p,key+":father",false,taken)
	var rng:=_rng(p,"byname:"+key)
	var fallback:=""
	for attempt in 64:
		var word:=_byname_word(p,rng)
		if word=="":continue
		if fallback=="":fallback=word
		if taken.has(word) or taken.has("byname:"+word):continue
		return word
	return fallback

## True when a word ends or begins as this people's family names do.
static func has_family_mark(p:Dictionary,word:String)->bool:
	var low:=word.to_lower()
	var base:=_base(String(p.family))
	for ending in base.fam:
		if String(ending).length()>=2 and low.ends_with(String(ending)):return true
	for pair:Array in base.famf:
		for form in pair:
			if String(form).length()>=2 and low.ends_with(String(form)):return true
	for form in base.famt:
		var before:=String(form).get_slice("%s",0).to_lower()
		if before!="" and low.begins_with(before):return true
	return false

## A family name in a woman's or a man's form ("Dunavlova", "Dunavlov"), where
## the tongue has two.
static func gendered(p:Dictionary,family:String,woman:bool)->String:
	for pair:Array in p.get("famf",[]):
		var masc:=String(pair[0]);var fem:=String(pair[1])
		if woman and family.ends_with(masc) and not family.ends_with(fem):return family.substr(0,family.length()-masc.length())+fem
		if not woman and family.ends_with(fem):return family.substr(0,family.length()-fem.length())+masc
	return family

## A whole name, given and second: {name, given, second}. At most FULL_MAX
## letters where the tongue allows. `stage` (era_names.gd): before 2 the
## second name is a byname, unless a kinsman's name (`family`) is given.
static func person(owner:String,seed_value:int,key:String,woman:bool,taken:Dictionary={},family:String="",stage:int=2)->Dictionary:
	var first:=given(owner,seed_value,key,woman,taken)
	var best:={}
	for attempt in 10:
		var turn:=key if attempt==0 else "%s~%d" % [key,attempt]
		var other:=byname(owner,seed_value,turn,woman,taken) if stage<2 and family.strip_edges()=="" else second(owner,seed_value,turn,woman,family,taken)
		var full:=("%s %s" % [first,other]).strip_edges()
		if best.is_empty() or (full.length()<String(best.name).length() and String(best.name).length()>FULL_MAX):best={"name":full,"given":first,"second":other}
		if full.length()<=FULL_MAX and not taken.has(full):return {"name":full,"given":first,"second":other}
		if family!="":break
	return best

## A town name of this people, never one in `taken` (lower-case or as
## written) while another can be found. `land` (LAND_CONCEPTS: "river",
## "hill"...) puts a word for the ground in the name.
static func town(owner:String,seed_value:int,key:String,taken:Dictionary={},land:String="")->String:
	var p:=profile(owner,seed_value)
	var rng:=_rng(p,"town:"+key)
	var concepts:Array=LAND_CONCEPTS.get(land,[])
	var fallback:=""
	for attempt in 64:
		var concept:=String(_pick(concepts,rng)) if not concepts.is_empty() and attempt<40 else ""
		var word:=_town_word(p,rng,concept)
		if word=="":continue
		if fallback=="":fallback=word
		if taken.has(word.to_lower()) or taken.has(word):continue
		return word
	return fallback

## The given names most heard among this people: `count` of each sex, the
## same every time (crisis victims, newborns, village notables).
static func palette(owner:String,seed_value:int,woman:bool,count:int=40)->Array:
	var p:=profile(owner,seed_value)
	var slot:="palette_%s_%d" % ["f" if woman else "m",count]
	if p.has(slot):return p[slot]
	var names:Array=[];var seen:={}
	for i in count*6:
		var name:=_given(p,"common:%d" % i,woman,{})
		if name=="" or seen.has(name):continue
		seen[name]=true;names.append(name)
		if names.size()>=count:break
	p[slot]=names
	return names

## True when a name is one this people gives women (false: men; null: neither).
static func sex_of(owner:String,seed_value:int,name:String)->Variant:
	if palette(owner,seed_value,true).has(name):return true
	if palette(owner,seed_value,false).has(name):return false
	var p:=profile(owner,seed_value)
	var low:=name.to_lower()
	for pair in [[true,p.f],[false,p.m]]:
		for ending in pair[1]:
			if String(ending).length()>=2 and low.ends_with(String(ending)):return pair[0]
	return null

## A small sample of the tongue for a people's card: {tongue, people,
## persons (three whole names, as the people name people at `stage`), towns
## (three)}.
static func sample(owner:String="player",seed_value:int=NO_SEED,stage:int=2)->Dictionary:
	var p:=profile(owner,seed_value)
	var slot:="sample_%d" % mini(stage,2)
	if p.has(slot):return p[slot]
	var persons:Array=[];var towns:Array=[];var taken:={}
	for i in 3:
		var made:=person(owner,int(p.world_seed),"sample:%d" % i,i!=1,taken,"",stage)
		persons.append(String(made.name));taken["given:"+String(made.given)]=true
	for i in 3:
		var place:=town(owner,int(p.world_seed),"sample:%d" % i,taken)
		towns.append(place);taken[place.to_lower()]=true
	p[slot]={"tongue":String(p.tongue_name),"people":String(p.people),"persons":persons,"towns":towns,"family":String(p.family)}
	return p[slot]

## One plain line for a people's card: "Tongue: Kikumbe · names like Hakima
## Nzesiza, Tonika Sizashali · towns like Ndimwa, Noshezi".
static func card_line(owner:String="player",seed_value:int=NO_SEED,stage:int=2)->String:
	var s:=sample(owner,seed_value,stage)
	return "Tongue: %s · names like %s · towns like %s" % [String(s.tongue),", ".join(PackedStringArray((s.persons as Array).slice(0,2))),", ".join(PackedStringArray((s.towns as Array).slice(0,2)))]

## The world's other peoples as the world is made: civ_01..civ_36, each
## {name, cities: five town names}. People and town names are never shared
## across the world, and no town begins with its people's name.
static func roster(seed_value:int)->Array:
	if _rosters.has(seed_value):return _rosters[seed_value]
	_ensure_world(seed_value)
	var taken:={}
	for i in ROSTER+1:taken[people_name("player" if i==0 else "civ_%02d" % i,seed_value).to_lower()]=true
	var out:Array=[]
	for i in range(1,ROSTER+1):
		var owner:="civ_%02d" % i
		var name:=people_name(owner,seed_value)
		var cities:Array=[]
		var attempt:=0
		while cities.size()<5 and attempt<60:
			var city:=town(owner,seed_value,"region:%d:%d" % [cities.size(),attempt],taken)
			attempt+=1
			if city=="" or taken.has(city.to_lower()) or city.to_lower().begins_with(name.to_lower()):continue
			taken[city.to_lower()]=true;cities.append(city)
		while cities.size()<5:
			var spare:="%s %s" % [name,["Ford","Hill","Shore","Field","Spring"][cities.size()]]
			taken[spare.to_lower()]=true;cities.append(spare)
		out.append({"name":name,"cities":cities})
	_rosters[seed_value]=out
	return out


# --------------------------------------------------------------------------
# Making words
# --------------------------------------------------------------------------

static func _rng(p:Dictionary,key:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new();rng.seed=("%d|%s" % [int(p.seed),key]).hash()
	return rng

static func _pick(list:Array,rng:RandomNumberGenerator)->Variant:
	return list[rng.randi_range(0,list.size()-1)] if not list.is_empty() else ""

static func _given(p:Dictionary,key:String,woman:bool,taken:Dictionary)->String:
	var rng:=_rng(p,"given:%s:%s" % [key,"f" if woman else "m"])
	var fallback:=""
	for attempt in 48:
		var word:=_given_word(p,rng,woman)
		if word=="":continue
		if fallback=="":fallback=word
		if taken.has(word) or taken.has("given:"+word):continue
		return word
	return fallback

static func _given_word(p:Dictionary,rng:RandomNumberGenerator,woman:bool)->String:
	var shapes:Array=p.fs if woman else p.ms
	var word:=""
	if not (p.gsyl as Array).is_empty():word=String(_pick(p.gsyl,rng))+String(_pick(p.gsyl,rng))
	elif not shapes.is_empty() and rng.randf()<float(p.ps):word=_shape(p,rng,String(_pick(shapes,rng)))
	else:
		var ends:Array=p.f if woman else p.m
		var ending:=String(_pick(ends,rng)) if not ends.is_empty() else ""
		word=_join(_root(p,rng,int(_pick(p.syl,rng)),ending==""),ending,p)
	var forms:Array=p.ft if woman else p.mt
	if not forms.is_empty():word=_template(String(_pick(forms,rng)),word)
	word=word.to_lower()
	return _cap(word) if _valid(word,p,int(p.given_min),9,int((p.gv as Array).front()),int((p.gv as Array).back())) else ""

static func _byname_word(p:Dictionary,rng:RandomNumberGenerator)->String:
	var lex:Dictionary=p.lex
	var word:=""
	var roll:=rng.randf()
	if roll<0.35 and lex.size()>=2:word=_join(_lex_word(lex,rng,""),_lex_word(lex,rng,""),p)
	elif roll<0.55 and not lex.is_empty():word=_join(_root(p,rng,1,false),_lex_word(lex,rng,""),p)
	else:word=_root(p,rng,[1,2,2][rng.randi_range(0,2)],true)
	word=word.to_lower()
	if has_family_mark(p,word):return ""
	return _cap(word) if _valid(word,p,3,10,1,3) else ""

static func _family_word(p:Dictionary,rng:RandomNumberGenerator)->String:
	var lex:Dictionary=p.lex
	var word:=""
	if String(p.mode)=="syllabic" or lex.size()<2 or rng.randf()<0.75:
		var ending:=String(_pick(p.fam,rng)) if not (p.fam as Array).is_empty() else ""
		word=_join(_root(p,rng,int(_pick(p.famsyl,rng)),ending==""),ending,p)
	else:
		word=_join(_lex_word(lex,rng,""),_lex_word(lex,rng,""),p)
	if not (p.famt as Array).is_empty():word=_template(String(_pick(p.famt,rng)),word)
	word=word.to_lower()
	return _cap(word) if _valid(word,p,int(p.fam_min),11,1,4) else ""

static func _town_word(p:Dictionary,rng:RandomNumberGenerator,concept:String)->String:
	var lex:Dictionary=p.lex
	var word:=""
	if concept!="" and lex.has(concept):
		if rng.randf()<0.5:word=_join(_root(p,rng,[1,2][rng.randi_range(0,1)],false),String(lex[concept]),p)
		else:word=_join(_lex_word(lex,rng,concept),String(lex[concept]),p)
	else:
		var roll:=rng.randf()
		if roll<0.45 or String(p.mode)=="syllabic" or lex.size()<2:
			var forms:Array=p.placet
			if not forms.is_empty() and ((p.place as Array).is_empty() or rng.randf()<0.6):
				word=_template(String(_pick(forms,rng)),_root(p,rng,[1,2][rng.randi_range(0,1)],true))
			else:
				var ending:=String(_pick(p.place,rng)) if not (p.place as Array).is_empty() else ""
				word=_join(_root(p,rng,[1,2,2][rng.randi_range(0,2)],ending==""),ending,p)
		elif roll<0.7:word=_join(_lex_word(lex,rng,""),_lex_word(lex,rng,""),p)
		else:word=_join(_root(p,rng,[1,2][rng.randi_range(0,1)],false),_lex_word(lex,rng,""),p)
	word=word.to_lower()
	if word.replace(" ","").length()>11 and not word.contains(" "):return ""
	return _cap(word) if _valid(word,p,4,12,2,4) else ""

static func _lex_word(lex:Dictionary,rng:RandomNumberGenerator,other_than:String)->String:
	var keys:Array=lex.keys()
	for attempt in 6:
		var key:=String(keys[rng.randi_range(0,keys.size()-1)])
		if key!=other_than:return String(lex[key])
	return String(lex[keys[0]])

static func _syllable(p:Dictionary,rng:RandomNumberGenerator,initial:bool,last:bool)->String:
	var fix:Dictionary=p.fix
	if String(p.mode)=="syllabic":
		var s:=""
		if not (p.oni as Array).is_empty() and rng.randf()<0.3:s=String(_pick(p.oni,rng))+String(_pick(p.vi,rng))
		else:s=String(_pick(p.on,rng))+String(_pick(p.v,rng))
		if fix.has(s):s=String(fix[s])
		if not (p.fin as Array).is_empty() and rng.randf()<(float(p.pf) if last else float(p.pc)):s+=String(_pick(p.fin,rng))
		return s
	var onset:=String(_pick(p.on if initial else p.mid,rng))
	var nucleus:=String(_pick(p.dip,rng)) if not (p.dip as Array).is_empty() and rng.randf()<float(p.pd) else String(_pick(p.v,rng))
	var cv:=onset+nucleus
	if fix.has(cv):cv=String(fix[cv])
	var coda:=""
	if not last and not (p.cod as Array).is_empty() and rng.randf()<float(p.pc):coda=String(_pick(p.cod,rng))
	if last and not (p.fin as Array).is_empty() and rng.randf()<float(p.pf):coda=String(_pick(p.fin,rng))
	return cv+coda

static func _root(p:Dictionary,rng:RandomNumberGenerator,syllables:int,closed:bool)->String:
	var s:=""
	for i in syllables:s+=_syllable(p,rng,i==0,closed and i==syllables-1)
	return s

static func _shape(p:Dictionary,rng:RandomNumberGenerator,shape:String)->String:
	var s:=""
	for i in shape.length():
		var ch:=shape[i]
		match ch:
			"C":
				var c:=String(_pick(p.on if i==0 else p.mid,rng))
				var guard:=0
				while c=="" and guard<8:
					c=String(_pick(p.mid,rng));guard+=1
				s+=c
			"V":s+=String(_pick(p.v,rng))
			"K":s+=String(_pick(p.clu if not (p.clu as Array).is_empty() else p.mid,rng))
			"Q":s+=String(_pick(p.fin_real if not (p.fin_real as Array).is_empty() else p.mid,rng))
			_:s+=ch
	return s

static func _join(a:String,b:String,p:Dictionary)->String:
	if b=="":return a
	if a=="":return b
	var a_vowel:=VOWELS.contains(a.right(1));var b_vowel:=VOWELS.contains(b.left(1))
	if a_vowel and b_vowel:return a.substr(0,a.length()-1)+b
	if not a_vowel and not b_vowel:return a+String((p.v as Array)[0])+b
	return a+b

static func _glue(a:String,b:String)->String:
	if a!="" and b!="" and VOWELS.contains(a.right(1).to_lower()) and VOWELS.contains(b.left(1).to_lower()):return a.substr(0,a.length()-1)+b
	return a+b

static func _template(form:String,word:String)->String:
	var t:=form.replace("+"," ")
	if not t.contains("%s"):return t
	var before:=t.get_slice("%s",0);var after:=t.substr(before.length()+2)
	return _glue(_glue(before,word.to_lower() if before!="" else word),after)

static func _cap(word:String)->String:
	var parts:=PackedStringArray()
	for part in word.split(" ",false):parts.append(String(part).substr(0,1).to_upper()+String(part).substr(1))
	return " ".join(parts)

static func _units(word:String)->Array:
	var out:Array=[];var i:=0
	while i<word.length():
		var found:=""
		for unit:String in UNITS:
			if word.substr(i,unit.length())==unit:found=unit;break
		if found=="":found=word[i]
		out.append(found);i+=found.length()
	return out

static func _vowel_unit(units:Array,i:int)->bool:
	var c:=String(units[i])
	if c.length()==1 and VOWELS.contains(c):return true
	if c=="y":return not (i+1<units.size() and VOWELS.contains(String(units[i+1])))
	return false

static func _groups(word:String)->int:
	var units:=_units(word);var count:=0;var before:=false
	for i in units.size():
		var vowel:=_vowel_unit(units,i)
		if vowel and not before:count+=1
		before=vowel
	return count

## A word that stutters ("Kiki", "Haha", "Tzitzi", "Kalala"): it begins or
## ends with the same few letters twice over.
static func stutters(word:String)->bool:
	var low:=word.to_lower()
	for n in [2,3,4]:
		if low.length()>=2*n and low.substr(0,n)==low.substr(n,n):return true
	for n in [2,3]:
		if low.length()>=2*n+1 and low.substr(low.length()-n)==low.substr(low.length()-2*n,n) and not VOWELS.contains(low.substr(low.length()-n,1)):return true
	return false

## Pronounceable in its own tongue, of the right size and no real or
## offensive word.
static func _valid(word:String,p:Dictionary,shortest:int,longest:int,fewest_groups:int,most_groups:int)->bool:
	var lower:=word.to_lower()
	var letters:=lower.replace(" ","")
	if letters.length()<shortest or letters.length()>longest:return false
	for i in letters.length():
		var c:=letters.unicode_at(i)
		if c<97 or c>122:return false
	var groups:=_groups(letters)
	if groups<fewest_groups or groups>most_groups:return false
	for part in lower.split(" ",false):
		var text:=String(part)
		if stutters(text):return false
		# English endings read as English words ("Hunting", "Baged").
		for ending in p.get("avoid",[]):
			if text.length()>String(ending).length()+2 and text.ends_with(String(ending)):return false
		if String(p.mode)!="syllabic" and text.length()>=6 and text.ends_with("ing"):return false
		var units:=_units(text)
		var run_c:=0;var run_v:=0
		for i in units.size():
			# A sound written with two letters, twice running ("Akhkhad").
			if i>0 and String(units[i]).length()>1 and units[i]==units[i-1]:return false
			if _vowel_unit(units,i):
				run_v+=String(units[i]).length();run_c=0
			else:
				run_c+=1;run_v=0
			if run_c>int(p.maxc) or run_v>int(p.maxv):return false
		for i in range(1,text.length()):
			if text[i]!=text[i-1]:continue
			if i>=2 and text[i]==text[i-2]:return false
			var pair:=text.substr(i-1,2)
			if VOWELS.contains(text[i]):
				if not (p.dip as Array).has(pair):return false
			elif int(p.gem)==0 and not (p.inv as Dictionary).has(pair):return false
	return not Blocklist.blocks(lower)
