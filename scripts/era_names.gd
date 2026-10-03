extends RefCounted
## Names graded by what a people knows, in each people's own tongue.
##
## Every people speaks its own language (people_language.gd): a sound family,
## its own sounds and endings, and its own way of naming people (given name and
## family name, given name and father's name, or given name and clan). A
## neighbour's envoy never sounds like one of your own, and the names are
## natural names of that tongue, not one shared old-fashioned palette.
##
## What a people knows still grades what the second name is. Before writing
## or lasting institutions (stages 0 and 1) it is a byname only: the person is
## known by it, but it is not handed down (family ""). Once writing or
## institutions exist (stage 2) it is the family's name (or the father's or
## the clan's, as that people name people) and kin share it. Every name is
## invented; real history is calibration only. Given names are not repeated
## among the living people one court can see while another can be found.
##
## Records already saved keep their names. Static helpers; preload.

const CV:=preload("res://scripts/character_voice.gd")
const Appearance:=preload("res://scripts/character_appearance.gd")
const Lang:=preload("res://scripts/people_language.gd")

## Stage 0: a name and a byname. 1: a name and a byname. 2: a family name.
const STAGE_WORDS:=["name and byname","name and byname","family name"]

## How many given names of each sex a people mostly uses (palette()).
const COMMON_NAMES:=40

## The sound palettes names were drawn from before each people had its own
## tongue. Kept so names given then are still known as a woman's or a man's
## (is_given_of_sex) and tradition() reads as before; no new name comes from
## them. [women, men].
const PALETTES:=[
	[["Ama","Sela","Iri","Nuna","Vesa","Tilla","Ysa","Oda","Luma","Pira","Runa","Wenna","Esi","Tova","Mira","Anni","Lisse","Hena","Ulla","Sabe"],
	 ["Harl","Tesk","Oru","Brim","Kael","Dunn","Vesh","Tam","Pell","Rook","Faro","Garro","Nesh","Tuk","Arvo","Bekk","Joss","Lorn","Senn","Yarro"]],
	[["Karsa","Vilka","Torra","Hesk","Ghia","Jora","Maren","Skai","Drenna","Ilke","Brisa","Kolla","Tyra","Asta","Gerd","Norra","Vessa","Hild","Rika","Solv"],
	 ["Grom","Hask","Torv","Brek","Dask","Hobb","Ulf","Kjal","Rovik","Stav","Gunn","Oskel","Birk","Arn","Hallo","Vidd","Tor","Ekkvar","Kolv","Sten"]],
	[["Aluna","Imeri","Sorava","Telani","Eshki","Namira","Ovea","Qira","Saoli","Yenna","Ilisa","Merai","Anai","Suri","Tamsa","Liora","Zeva","Hadra","Nesri","Ashti"],
	 ["Tomaq","Idrin","Kavu","Orun","Belem","Sadu","Ekkan","Anzu","Rimo","Tahun","Oskan","Mahun","Ilak","Zerem","Adu","Namar","Esru","Kishan","Belun","Ulim"]],
	[["Tsema","Ikka","Numa","Oze","Neka","Aduwa","Sisi","Temba","Yaro","Kuma","Ondi","Lesa","Mbira","Zola","Ifa","Nanda","Asha","Wema","Tula","Eshe"],
	 ["Bako","Sefu","Kamo","Juma","Tendo","Oyo","Radi","Masu","Kofa","Diru","Anu","Seko","Mbu","Taro","Ekwe","Lusa","Obi","Nuru","Zaki","Chuma"]],
	[["Yelu","Soma","Pashi","Inni","Tavi","Rella","Anoka","Wisa","Hoya","Emu","Kallu","Nisa","Ossa","Timi","Lehu","Pema","Sayo","Ruhi","Vani","Oki"],
	 ["Tahu","Pemo","Kanu","Iwo","Rahu","Sokko","Mato","Lenu","Wiru","Hanu","Olo","Tepa","Nuko","Ruma","Suvo","Kelo","Paku","Yoru","Emo","Tuvi"]],
	[["Cendra","Fenna","Morwe","Liseth","Brynne","Oriel","Thessa","Caelin","Merra","Evra","Sirra","Dalla","Anwe","Rhosa","Talwe","Ennis","Varra","Iwen","Selwe","Norwe"],
	 ["Corvan","Tebb","Hollin","Mardo","Brannoc","Fenwic","Garth","Radd","Tollan","Evrin","Kerrin","Dunnor","Aldo","Brask","Callum","Derro","Emmet","Farran","Gallo","Hewin"]],
]

static func stage(owner:String="player")->int:
	var tags:Array=CV.era_tags(owner)
	if tags.has("writing") or tags.has("institutions"): return 2
	if CV.era_tier(tags)>=1: return 1
	return 0

static func tradition(owner:String="player",seed_value:int=-1)->int:
	## One sound palette per people, from its visual ancestry.
	var s:=seed_value if seed_value>=0 else int(GameState.world_seed)
	var family:=Appearance.initial_family(s,owner)
	return posmod(Appearance.FAMILIES.find(family)+posmod(s,7),PALETTES.size())

## Words too common to pick a person out of speech ("who", "long", "fire").
const COMMON_WORDS:=["the","of","who","and","our","you","your","for","with","from","long","cold","fire","hand","hands","eye","eyes","foot","back","heart","voice","ear","grass","stone",
	"sky","night","early","quick","sharp","swift","full","deep","strong","soft","salt","friend","even","keen","owl","star","bone","reed","wolf","spear","tall","grey","pole","berry",
	"hard","far","younger","quiet","laughing","stubborn","patient","fair","all","us","in","who's","one"]

static func name_keys(name:String)->Array[String]:
	## Lower-case words that pick this person out of speech: the full name,
	## the given name, a one-word byname or family name, or a whole epithet.
	## Never a common word inside an epithet ("who", "the", "long").
	var clean:=name.strip_edges().to_lower()
	var keys:Array[String]=[]
	if clean=="": return keys
	keys.append(clean)
	var words:=clean.split(" ",false)
	if String(words[0]).length()>=3 and not String(words[0]) in COMMON_WORDS: keys.append(String(words[0]))
	if words.size()==2:
		var second:=String(words[1])
		if second.length()>=3 and not second in COMMON_WORDS: keys.append(second)
	elif words.size()>2:
		keys.append(" ".join(words.slice(1)))
		if String(words[1])=="of" and words.size()==3 and String(words[2]).length()>=4: keys.append(String(words[2]))
	return keys

static func given_of(name:String)->String:
	return name.strip_edges().get_slice(" ",0)

static func family_of(person:Variant)->String:
	## A person's family name, or "" where the people have none yet.
	if person is Dictionary:
		var rec:Dictionary=person
		if rec.has("family"): return String(rec.family)
		return String(rec.get("name","")).get_slice(" ",1) if String(rec.get("name","")).split(" ",false).size()==2 else ""
	var text:=String(person)
	return text.get_slice(" ",1) if text.split(" ",false).size()==2 else ""

## The longest whole name that fits a herald's line (people_language.gd FULL_MAX).
const NAME_MAX:=18

static func make(seed_value:int,serial:int,woman:bool,owner:String,used:Dictionary,hint:Dictionary={})->Dictionary:
	## {name,given,byname,family,stage,tradition,tongue_name}, in the people's own
	## tongue. `used` holds full names and "given:<name>" keys; a given name
	## already in use is avoided while any other remains. hint: {family (a
	## kinsman's, kept in this person's form), stage}.
	if owner=="": owner="player"
	var st:=int(hint.get("stage",stage(owner)))
	var made:=Lang.person(owner,seed_value,"%s:%d" % [owner,serial],woman,used,String(hint.get("family","")),st)
	var second:=String(made.get("second",""))
	return {"name":String(made.get("name","")),"given":String(made.get("given","")),"byname":second,"family":second if st>=2 else "","stage":st,
		"tradition":tradition(owner,seed_value),"tongue_name":Lang.tongue_name(owner,seed_value)}

static func second_name(owner:String,seed_value:int,key:String,woman:bool,taken:Dictionary={})->String:
	## A second name for an ordinary person of this people, as they are named
	## now: a byname before writing or institutions, else a family, father's or
	## clan name.
	if owner=="": owner="player"
	if stage(owner)<2: return Lang.byname(owner,seed_value,key,woman,taken)
	return Lang.second(owner,seed_value,key,woman,"",taken)

static func kin_family(kin:Dictionary,relation:String="child",owner:String="player")->String:
	## The second name a kinsman hands to a relation (a court person's kin, a
	## ruler's heir), for make()'s hint. Before writing or institutions nothing
	## is handed down (""). A people that names by the father gives a child the
	## father's given name (the kinsman's own when he is the father, his
	## wife's husband's when she is the mother, "" when unknown) and a brother
	## or sister the same father's name; nephews, nieces, cousins and parents
	## are named afresh. Every other people shares its family or clan name.
	if owner=="": owner="player"
	if stage(owner)<2: return ""
	if Lang.pattern(owner)!="patronym": return family_of(kin)
	match relation:
		"brother","sister","sibling": return family_of(kin)
		"child","son","daughter":
			if not _is_woman(kin): return given_of(String(kin.get("name","")))
			var household:Variant=kin.get("household",{})
			var spouse:Variant=(household as Dictionary).get("spouse",{}) if household is Dictionary else {}
			if spouse is Dictionary and String((spouse as Dictionary).get("name",""))!="": return given_of(String((spouse as Dictionary).name))
	return ""

static func _is_woman(person:Dictionary)->bool:
	if person.has("woman"): return bool(person.woman)
	return String(person.get("sex",person.get("gender",""))) in ["female","woman"]

static func given_for(seed_value:int,key:String,woman:bool,owner:String,taken:Dictionary)->String:
	## One given name in this people's tongue and of the person's sex (a
	## newborn, a traveller): mostly one of the names the people commonly give.
	## A name in `taken` (bare or "given:<name>") is avoided while any other of
	## that sex remains.
	if owner=="": owner="player"
	var common:Array=Lang.palette(owner,seed_value,woman,COMMON_NAMES)
	var start:=posmod(hash("%d:given:%s:%s" % [seed_value,owner,key]),maxi(1,common.size()))
	for offset in common.size():
		var candidate:=String(common[(start+offset)%common.size()])
		if not taken.has(candidate) and not taken.has("given:"+candidate): return candidate
	return Lang.given(owner,seed_value,"given:"+key,woman,taken)

static func palette(owner:String="player",seed_value:int=Lang.NO_SEED)->Array:
	## [women's names, men's names] this people most often give (COMMON_NAMES
	## of each), the same every time.
	if owner=="": owner="player"
	var s:=seed_value if seed_value!=Lang.NO_SEED else int(GameState.world_seed)
	return [Lang.palette(owner,s,true,COMMON_NAMES),Lang.palette(owner,s,false,COMMON_NAMES)]

static func is_given_of_sex(given:String,woman:bool,owner:String="player")->bool:
	## True when a given name belongs to that sex: in the people's tongue, or in
	## the palettes older names came from.
	for old in PALETTES:
		if String(given) in ((old as Array)[0 if woman else 1] as Array): return true
	var sex:Variant=Lang.sex_of(owner,int(GameState.world_seed),given)
	return sex!=null and bool(sex)==woman

static func hearth_of(seed_value:int,key:String,owner:String,taken:Dictionary={})->Dictionary:
	## How the people name one family. A band names a hearth for its eldest
	## ("Tesk's hearth"); villagers by where it came from ("the hearth from
	## Nziforo"); a people with family names by that name ("the Kekwe
	## hearth"), all in the people's own tongue. {name: the hearth, at:
	## "at <the hearth>"}.
	if owner=="": owner="player"
	match stage(owner):
		0:
			var start:=posmod(hash("%d:hearth:%s:%s" % [seed_value,owner,key]),1000003)
			var pool:Array=(Lang.palette(owner,seed_value,true,COMMON_NAMES) as Array)+(Lang.palette(owner,seed_value,false,COMMON_NAMES) as Array)
			var elder:=String(pool[start%pool.size()]) if not pool.is_empty() else Lang.given(owner,seed_value,"hearth:"+key,false,taken)
			for offset in pool.size():
				var candidate:=String(pool[(start+offset)%pool.size()])
				if not taken.has(candidate) and not taken.has("given:"+candidate): elder=candidate; break
			return {"name":"%s's hearth" % elder,"at":"at %s's hearth" % elder}
		1:
			var place:=Lang.town(owner,seed_value,"hearth:"+key)
			return {"name":"the hearth from %s" % place,"at":"of the hearth from %s" % place}
	var family:=Lang.second(owner,seed_value,"hearth:"+key,false)
	return {"name":"the %s hearth" % family,"at":"of the %s hearth" % family}

static func used_in_court()->Dictionary:
	## Full and given names of every living person the player's court can see:
	## the government cast, remembered commoners and the realm's great figures.
	var used:Dictionary={}
	var add:=func(name:String)->void:
		if name.strip_edges()=="": return
		used[name]=true
		used["given:"+given_of(name)]=true
		var rest:=name.strip_edges().substr(given_of(name).length()).strip_edges()
		if rest!="": used["byname:"+rest]=true
	for p in GovernmentPeopleSystem.people:
		if String((p as Dictionary).get("status","active")) in ["active","detained"]: add.call(String((p as Dictionary).get("name","")))
	if is_instance_valid(HistoricalFigures):
		for f in HistoricalFigures.people:
			if f is Dictionary and String(f.get("status",""))!="dead": add.call(String(f.get("name","")))
	var persons:Variant=ForeignDiplomacy.audiences.get("court_persons",{}) if ForeignDiplomacy.audiences is Dictionary else {}
	if persons is Dictionary:
		for p in (persons as Dictionary).get("people",[]):
			if p is Dictionary and String(p.get("status",""))=="living": add.call(String(p.get("name","")))
	return used
