extends RefCounted
## Names graded by what a people knows and by their own tradition.
##
## A band that has neither writing nor lasting institutions has no family
## names: a person is one name and what the band calls them ("Tala Long-Stride",
## "Oren Who Found the Ford"). Once villages and fields exist, people are also
## known by the place or hearth they come from ("Tala of Reedwater"). Family
## names arrive only with writing or institutions, and they grow out of those
## older bynames ("Tala Reedwater"). Each people's names share one sound
## palette, chosen from its visual ancestry (character_appearance.gd), so a
## neighbour's envoy never sounds like one of your own. Every name is invented;
## real history is calibration only. Given names are not repeated among the
## living people one court can see.
##
## Records already saved keep their names. Static helpers; preload.

const CV:=preload("res://scripts/character_voice.gd")
const Appearance:=preload("res://scripts/character_appearance.gd")

## Stage 0: one name and an epithet. 1: a byname of place. 2: a family name.
const STAGE_WORDS:=["name and epithet","name and place","family name"]

## Sound palettes: [women, men]. Invented, era-neutral, short enough for a hall.
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

## Stone age: what the band calls someone, from what they are good at.
## Epithets stay short (at most 18 letters) so a name still fits a herald's line.
const SKILL_EPITHETS:={
	"Administration":["the Fair","Even-Hand","Peace-Keeper","the Patient","Oath-Holder"],
	"Provisioning":["Full-Basket","Store-Keeper","Who Fed the Band","Berry-Finder","Deep-Pit"],
	"Construction":["Stone-Hand","Pole-Setter","Roof-Mender","Strong-Back","Hut-Raiser"],
	"Logistics":["Long-Stride","Who Found the Ford","Far-Walker","Load-Bearer","Swift-Foot"],
	"Knowledge":["Owl-Sight","Star-Counter","Who Remembers","Keen-Eye","Sky-Reader"],
	"Defense":["Spear-Arm","Who Held the Ridge","Night-Watcher","Wolf-Scarer","Hard-Heart"],
	"Diplomacy":["Soft-Voice","Stranger-Friend","Salt-Tongue","Anger-Tamer","Friend-of-All"],
}
const GENERIC_EPITHETS:=["the Quiet","the Laughing","Grey-Eyes","Tall-Grass","Cold-Swimmer","Salt-Walker","Quick-Hands","the Stubborn","Bone-Setter","Early-Riser","Fire-Tender","Reed-Weaver","Who Speaks Last","Sharp-Ear","the Younger"]
## Villages: people are known by the ground they come from.
const PLACES:=["Reedwater","the Ford","Ashbank","the Long Meadow","the Salt Spring","Hollow Hill","the Red Cliff","Stonewash","the Birch Stand","Deepwell","the Otter Pool","Windgap","the Twin Oaks","Mossbrook","the White Stones","Fernside","the High Camp","Crowfield","the Lake Shore","Thornbrake"]
## Family names grow out of the older bynames.
const FAMILIES:=["Reedwater","Ford","Ashbank","Longmeadow","Saltspring","Hollowhill","Redcliff","Stonewash","Birchstand","Deepwell","Otterpool","Windgap","Twinoak","Mossbrook","Whitestone","Fernside","Highcamp","Crowfield","Lakeshore","Thornbrake",
	"Stonehand","Longstride","Owlsight","Keeneye","Swiftfoot","Fairhand","Fullbasket","Polesetter","Nightwatch","Softvoice","Greyeyes","Tallgrass","Quickhand","Firetender","Reedweaver","Sharpear"]


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

static func _clean(options:Array,tags:Array)->Array:
	var out:Array=[]
	for o in options:
		if CV.permits(String(o),tags): out.append(o)
	return out if not out.is_empty() else options

## A whole name should fit a herald's line and a portrait plate.
const NAME_MAX:=18

static func _fitting(options:Array,given:String,used:Dictionary,rng:RandomNumberGenerator)->String:
	## A byname from options, from a seeded start: unused by anyone at court and
	## short enough to fit with the given name, else the shortest unused one.
	var start:=rng.randi_range(0,maxi(0,options.size()-1))
	var fallback:=""
	for offset in options.size():
		var candidate:=String(options[(start+offset)%options.size()])
		if used.has("%s %s" % [given,candidate]) or used.has("byname:"+candidate): continue
		if given.length()+1+candidate.length()<=NAME_MAX: return candidate
		if fallback=="" or candidate.length()<fallback.length(): fallback=candidate
	if fallback!="": return fallback
	return String(options[start]) if not options.is_empty() else ""

static func make(seed_value:int,serial:int,woman:bool,owner:String,used:Dictionary,hint:Dictionary={})->Dictionary:
	## {name,given,byname,family,stage,tradition}. `used` holds full names and
	## "given:<name>" keys; a given name already in use is avoided while any
	## other remains. hint: {skill, traits, family, stage}.
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:era_name:%s:%d" % [seed_value,owner,serial])
	var palette:Array=PALETTES[tradition(owner,seed_value)]
	var half:Array=palette[0] if woman else palette[1]
	var pool:Array=half.duplicate()
	var st:=int(hint.get("stage",stage(owner)))
	var tags:Array=CV.era_tags(owner)
	var start:=rng.randi_range(0,pool.size()-1)
	var given:=""
	for offset in pool.size():
		var candidate:=String(pool[(start+offset)%pool.size()])
		if not used.has("given:"+candidate): given=candidate; break
	if given=="":
		# Every name is taken: borrow from the other half of the palette.
		var other:Array=palette[1] if woman else palette[0]
		for offset in other.size():
			var candidate2:=String(other[(start+offset)%other.size()])
			if not used.has("given:"+candidate2): given=candidate2; break
	if given=="": given=String(pool[start])
	var byname:=""; var family:=""
	match st:
		0:
			var skill:=String(hint.get("skill",""))
			var own:Array=SKILL_EPITHETS.get(skill,[])
			var options:Array=_clean(own+GENERIC_EPITHETS.slice(0,4) if not own.is_empty() else GENERIC_EPITHETS,tags)
			byname=_fitting(options,given,used,rng)
		1:
			var places:Array=[]
			for place in _clean(PLACES,tags): places.append("of "+String(place))
			byname=_fitting(places,given,used,rng)
		_:
			family=String(hint.get("family",""))
			if family=="":
				var families:Array=_clean(FAMILIES,tags)
				for attempt in families.size():
					family=String(families[(rng.randi()+attempt)%families.size()])
					if not used.has("%s %s" % [given,family]): break
			byname=family
	var name:=("%s %s" % [given,byname]).strip_edges()
	return {"name":name,"given":given,"byname":byname,"family":family,"stage":st,"tradition":tradition(owner,seed_value)}

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
