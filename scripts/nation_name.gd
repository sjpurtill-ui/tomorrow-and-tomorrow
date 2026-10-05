extends RefCounted
## OUR PEOPLE'S NAME: what we call ourselves, and other peoples call us.
##
## Every people has one settlement that grows (no new towns). Our people's
## name (GameState.nation_name, "" until given) may be given from the start:
##   - at the first fire, under the settlement's own name
##     (hud/fire_circle_opening.gd, mode "name");
##   - spoken in the court ("call our people the Reedfolk",
##     court_realm_acts.nation);
##   - named or changed in the court (the Headman's "Name our nation" choices).
## Unnamed, our people go by the settlement's name ("the people of
## Seanstone"), and everything reads as before. The settlement keeps its own
## name, and its own uses (where the army stands, where the stores are) never
## change.
##
## Suggestions are invented, in the people's own words for their time
## (era_names.gd stages): what they call themselves in their own tongue
## (people_language.gd), from the land the first town stands on, from that
## town, from the founders and from the towns together. Real history is
## calibration only. Static helpers; preload.

const EraNames:=preload("res://scripts/era_names.gd")
const CV:=preload("res://scripts/character_voice.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

const MAX_LENGTH:=32
## Towns it takes before the people may take a name of their own.
const TOWNS_TO_NAME:=2
## Words kept small inside a name ("The Folk of the Ford").
const SMALL_WORDS:=["of","the","and","by","on","in","at","under","over","upon","beyond"]
## The land a people is named for, from the ground its first town stands on.
const LAND_FOLK:={"shore":"Shorefolk","river":"Riverfolk","reed":"Reedfolk","wood":"Woodfolk","hill":"Hillfolk","grass":"Grassfolk","sun":"Sunfolk","frost":"Frostfolk","plain":"Plainsfolk"}


## The nation's name as the ruler gave it ("The Reedfolk"), or "".
static func current()->String:
	return String(GameState.nation_name).strip_edges()


static func named()->bool:
	return current()!=""


## Our own towns, not counting one an enemy holds now.
static func towns()->int:
	var count:=0
	for city in GameState.player_settlements:
		if city is Dictionary and String((city as Dictionary).get("occupied_by","")).is_empty(): count+=1
	return count


## May our people be named (or renamed) now: always (one settlement each).
static func can_name()->bool:
	return true


## A town's founding asks for the nation's name while it has none.
static func ask_at_founding()->bool:
	return not named() and towns()>=TOWNS_TO_NAME


## A name inside a sentence: "the Reedfolk" (a leading "The" lower-cased);
## "" stays "".
static func in_sentence(name:String)->String:
	var clean:=name.strip_edges()
	return "the "+clean.substr(4) if clean.begins_with("The ") else clean


## How our people are called in a row or a label: the nation's name, else
## "The people of <home town>", else "Our people".
static func people_title()->String:
	if named(): return current()
	var home:=String(GameState.settlement_name).strip_edges()
	return "The people of %s" % home if home!="" else "Our people"


## A typed name made tidy: quotes and end marks dropped, each word begun with
## a capital (small words after the first stay small), at most 32 letters.
static func tidy(text:String)->String:
	var clean:=text.strip_edges()
	for mark in ["\"","“","”","«","»"]: clean=clean.replace(mark,"")
	clean=clean.strip_edges().trim_suffix(".").trim_suffix("!").trim_suffix(",").trim_suffix(";").strip_edges()
	var words:=PackedStringArray()
	for raw in clean.split(" ",false):
		var word:=String(raw)
		if not words.is_empty() and word.to_lower() in SMALL_WORDS: words.append(word.to_lower())
		else: words.append(word.substr(0,1).to_upper()+word.substr(1))
	return " ".join(words).substr(0,MAX_LENGTH).strip_edges()


## Names (or renames) the nation and tells it once in the Chronicle.
## how: "founding" (the naming card at a town's founding), "court", "screen".
## town: the town just founded, for the founding's telling.
## {ok, name, old} or {ok:false, reason, why}; why: "empty", "one_town",
## "same", "taken".
static func give_name(text:String,how:String="screen",town:String="")->Dictionary:
	var name:=tidy(text)
	if name=="": return {"ok":false,"why":"empty","reason":"A nation's name cannot be empty."}
	if not can_name(): return {"ok":false,"why":"one_town","reason":"Our people live in one %s and go by its name until a second %s stands." % [EraWords.word("place","town"),EraWords.word("place","town")]}
	var old:=current()
	if old.to_lower()==name.to_lower(): return {"ok":false,"why":"same","name":old,"reason":"We are already %s." % in_sentence(old)}
	var other:=_foreign_people(name)
	if other!="": return {"ok":false,"why":"taken","name":name,"reason":"%s are another people; our nation needs a name of its own." % _cap(in_sentence(other) if other.begins_with("The ") else "the "+other)}
	GameState.nation_name=name
	_tell(name,old,how,town)
	return {"ok":true,"name":name,"old":old}


## Our towns by name for a sentence: "Seanstone and Reedmouth",
## "Seanstone, Reedmouth and Ashbank", or "all four of our towns".
static func towns_words()->String:
	var names:=PackedStringArray()
	for city in GameState.player_settlements:
		if city is Dictionary and String((city as Dictionary).get("occupied_by","")).is_empty():
			var name:=String((city as Dictionary).get("name","")).strip_edges()
			if name!="": names.append(name)
	if names.is_empty(): return "our %s" % EraWords.word("places","towns")
	if names.size()==1: return names[0]
	if names.size()<=3: return "%s and %s" % [", ".join(names.slice(0,names.size()-1)),names[names.size()-1]]
	return "all %s of our %s" % [EraWords.count_word(names.size()),EraWords.word("places","towns")]


static func _tell(name:String,old:String,how:String,town:String)->void:
	var day:=int(GameState.elapsed_days)
	var title:=("A Name for Our People: %s" % name) if old=="" else ("A New Name for Our People: %s" % name)
	var text:=""
	if old!="":
		text="By the god's word, %s are called %s from this day." % [in_sentence(old),in_sentence(name)]
	elif how=="start":
		text="At the first fire the god named our people: %s." % in_sentence(name)
	elif how=="founding" and town!="":
		text="With %s founded, our people live in %s %s, and the god gave them one name for all of them: %s." % [town,EraWords.count_word(towns()),EraWords.word("places","towns"),in_sentence(name)]
	else:
		text="By the god's word, the people of %s are called %s from this day." % [towns_words(),in_sentence(name)]
	preload("res://scripts/chronicle.gd").record({"key":"nation_name:%d:%s" % [day,name.to_lower()],"day":day,"title":title,"text":text,"tier":"moment","kind":"milestone","domain":"culture","ledger":true})


## The name of another people this one would repeat ("the Esurai"), or "".
static func _foreign_people(name:String)->String:
	var bare:=name.to_lower().trim_prefix("the ").strip_edges()
	var world:Variant=CivilizationSystem
	if world==null: return ""
	for civ in world.civilizations:
		if not civ is Dictionary: continue
		var theirs:=String((civ as Dictionary).get("name","")).strip_edges()
		if theirs!="" and theirs.to_lower().trim_prefix("the ").strip_edges()==bare: return theirs
	return ""


static func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)


# --------------------------------------------------------------------------
# Names the people might take
# --------------------------------------------------------------------------

## The land word of the ground our first town stands on (LAND_FOLK keys).
static func land_word()->String:
	var profile:Dictionary={}
	if CivilizationSystem!=null and PlanetEnvironment!=null:
		profile=PlanetEnvironment.profile_at(CivilizationSystem.player_world_origin)
	if bool(profile.get("coastal",false)): return "shore"
	if float(profile.get("river_distance_km",99.0))<3.0: return "river"
	if float(profile.get("water_access",0.0))>0.5: return "reed"
	if float(profile.get("woodland",0.0))>0.4: return "wood"
	if float(profile.get("relief",0.0))>0.3: return "hill"
	var ground:=String(GameState.province_terrain).to_lower()
	if "wet" in ground or "marsh" in ground: return "reed"
	if "river" in ground or "flood" in ground: return "river"
	if "wood" in ground or "forest" in ground: return "wood"
	if "upland" in ground or "hill" in ground: return "hill"
	if "cold" in ground or "barren" in ground or "tundra" in ground: return "frost"
	if "dry" in ground or "sun" in ground: return "sun"
	if "grass" in ground or "steppe" in ground: return "grass"
	return "plain"


## A few names the people might take, at most count, in their own words for
## their time: the land, the first town, the founders, the towns together.
## Never another people's name, one of our towns', or our own name now.
static func suggestions(count:int=4)->Array[String]:
	var tags:Array=CV.era_tags("player")
	var stage:=EraNames.stage("player")
	var candidates:Array[String]=[]
	# What the people call themselves in their own tongue (people_language.gd).
	candidates.append("The %s" % preload("res://scripts/people_language.gd").people_name("player",int(GameState.world_seed)))
	# The land.
	candidates.append("The %s" % String(LAND_FOLK.get(land_word(),"Plainsfolk")))
	# The first town.
	var home:=_first_town()
	if home!="":
		if stage>=2 and CV.known_ids("player").has("kingship"): candidates.append("The Kingdom of %s" % home)
		elif stage>=2: candidates.append("The Realm of %s" % home)
		else: candidates.append("The Folk of %s" % home)
	# The founders: the one who kept the first fire.
	var founder:=EraNames.given_of(String(GovernmentPeopleSystem.officeholder("Steward").get("name","")))
	if founder!="": candidates.append(("%s's Kin" % founder) if stage==0 else ("The Children of %s" % founder))
	# The towns together.
	var together:=towns()
	if together>=2 and together<=12: candidates.append("The %s %s" % [EraWords.count_word(together).capitalize(),"Hearths" if stage<2 else "Towns"])
	var taken:=_taken()
	var out:Array[String]=[]
	for candidate in candidates:
		var name:=candidate.strip_edges()
		if name=="" or name.length()>MAX_LENGTH or not CV.permits(name,tags): continue
		if taken.has(name.to_lower()) or taken.has(name.to_lower().trim_prefix("the ")) or out.has(name): continue
		out.append(name)
		if out.size()>=count: break
	return out


static func _first_town()->String:
	for city in GameState.player_settlements:
		if city is Dictionary and bool((city as Dictionary).get("primary",false)): return String((city as Dictionary).get("name","")).strip_edges()
	var home:=String(GameState.settlement_name).strip_edges()
	return "" if home.to_upper()=="FIRST SETTLEMENT" else home


## Lower-case names already in use: other peoples', our towns', our own now.
static func _taken()->Dictionary:
	var out:={}
	if current()!="": out[current().to_lower()]=true
	for city in GameState.player_settlements:
		if city is Dictionary: out[String((city as Dictionary).get("name","")).to_lower()]=true
	if CivilizationSystem!=null:
		for civ in CivilizationSystem.civilizations:
			if civ is Dictionary:
				var theirs:=String((civ as Dictionary).get("name","")).to_lower()
				out[theirs]=true
				out[theirs.trim_prefix("the ")]=true
	return out
