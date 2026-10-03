extends GdUnitTestSuite
## "We need much more varied civilizations with their own specific, unique
## name variations and skin colors... different races, different languages,
## and different names." Every people speaks its own tongue
## (people_language.gd) and has its own look (people_appearance.gd):
## - deterministic for a world, kept with the people, made again from the
##   seed for older saves;
## - a world's peoples speak different tongues, never share a people's name,
##   and their towns never repeat;
## - each tongue holds thousands of names, none a real place, people or
##   famous figure, nor an offensive or everyday English word;
## - looks differ from people to people and span the range of human skin,
##   and every portrait is drawn from its own people's look;
## - names already given in a saved game stay as they were.

const Lang:=preload("res://scripts/people_language.gd")
const Looks:=preload("res://scripts/people_appearance.gd")
const Blocklist:=preload("res://scripts/people_name_blocklist.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const Appearance:=preload("res://scripts/character_appearance.gd")
const Early:=preload("res://scripts/hud/early_civ_art.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const Identity:=preload("res://scripts/civilization_identity.gd")
const IdentityLine:=preload("res://scripts/hud/people_identity_line.gd")
const SEED:=424242

var _days:=0.0

func before_test()->void:
	_days=GameState.elapsed_days
	WorldSimulation.clear()
	GameState.reset_for_new_world(SEED)
	ForeignDiplomacy.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()

func after_test()->void:
	GameState.elapsed_days=_days

static func _owner(i:int)->String:
	return "player" if i==0 else "civ_%02d" % i

## One people for each sound family in this world (the first thirty peoples).
func _one_per_family(seed_value:int)->Dictionary:
	var out:={}
	for i in Lang.ROSTER+1:
		var family:=Lang.family_for(seed_value,_owner(i))
		if not out.has(family):out[family]=_owner(i)
	return out


func test_a_peoples_tongue_is_the_same_for_the_same_world()->void:
	var first:=Lang.sample("civ_04",SEED).duplicate(true)
	var record:=Lang.record("civ_04",SEED).duplicate()
	Lang.clear_cache()
	assert_dict(Lang.sample("civ_04",SEED)).is_equal(first)
	assert_dict(Lang.record("civ_04",SEED)).is_equal(record)
	# Kept with the people: the record made at the world's making.
	var civ:Dictionary=CivilizationSystem.civilizations[3]
	assert_str(String(civ.id)).is_equal("civ_04")
	assert_str(String((civ.language as Dictionary).family)).is_equal(String(record.family))
	Lang.record("player",SEED)
	assert_str(String(GameState.people_language.get("family",""))).is_equal(Lang.family_for(SEED,"player"))
	# Another world, other peoples.
	var other:=Lang.profile("civ_04",SEED+1)
	assert_str(String(other.people)).is_not_equal(String(first.people))
	# The same key gives the same name; the same person is always named alike.
	assert_str(Lang.given("civ_04",SEED,"probe",true)).is_equal(Lang.given("civ_04",SEED,"probe",true))
	assert_dict(EraNames.make(SEED,77,true,"civ_04",{})).is_equal(EraNames.make(SEED,77,true,"civ_04",{}))


func test_twelve_peoples_and_ours_speak_different_tongues_with_their_own_names()->void:
	for seed_value in [1,SEED,-212121,1788457137]:
		var families:={};var peoples:={};var tongues:={};var givens:={}
		for i in 13:
			var p:=Lang.profile(_owner(i),seed_value)
			assert_bool(families.has(p.family)).override_failure_message("%s shares %s" % [_owner(i),p.family]).is_false()
			families[p.family]=true
			assert_bool(peoples.has(String(p.people))).is_false();peoples[String(p.people)]=true
			assert_bool(tongues.has(String(p.tongue_name))).is_false();tongues[String(p.tongue_name)]=true
			for name in EraNames.palette(_owner(i),seed_value)[0]+EraNames.palette(_owner(i),seed_value)[1]:givens[String(name)]=int(givens.get(String(name),0))+1
		assert_int(families.size()).is_equal(13)
		# The commonest names of one people are hardly ever another's.
		var shared:=0
		for name in givens:if int(givens[name])>1:shared+=1
		assert_int(shared).is_less(givens.size()/20)


func test_no_two_peoples_of_a_world_share_a_name_and_towns_never_repeat()->void:
	for seed_value in [1,SEED,-212121]:
		var names:={};var cities:={}
		names[Lang.people_name("player",seed_value).to_lower()]=true
		var roster:=Identity.roster(seed_value)
		assert_array(roster).has_size(36)
		for entry:Dictionary in roster:
			assert_bool(names.has(String(entry.name).to_lower())).override_failure_message("two peoples called %s" % entry.name).is_false()
			names[String(entry.name).to_lower()]=true
			assert_array(entry.cities).has_size(5)
			for city:String in entry.cities:
				assert_bool(cities.has(city.to_lower())).is_false();cities[city.to_lower()]=true
				assert_bool(city.to_lower().begins_with(String(entry.name).to_lower())).is_false()
				assert_bool(Blocklist.blocks(city)).is_false()
		assert_int(cities.size()).is_equal(180)
	# The world's peoples take the roster's names and towns.
	for civ:Dictionary in CivilizationSystem.civilizations:
		assert_str(String(civ.name)).is_equal(Lang.people_name(String(civ.id),SEED))


func test_every_tongue_holds_thousands_of_names_and_none_is_real_or_rude()->void:
	var by_family:=_one_per_family(SEED)
	assert_int(by_family.size()).is_equal(Lang.FAMILIES.size())
	var legacy:={}
	for old in EraNames.PALETTES:
		for half in old:
			for name in half:legacy[String(name)]=true
	for family:String in by_family:
		var owner:String=by_family[family]
		var givens:={};var full:={};var towns:={}
		for i in 1000:
			var made:=Lang.person(owner,SEED,"count:%d" % i,i%2==0)
			givens[String(made.given)]=true;full[String(made.name)]=true
		for i in 400:towns[Lang.town(owner,SEED,"count:%d" % i)]=true
		assert_int(givens.size()).override_failure_message("%s: %d given names" % [family,givens.size()]).is_greater(780)
		assert_int(full.size()).override_failure_message("%s: %d whole names" % [family,full.size()]).is_greater(960)
		assert_int(towns.size()).override_failure_message("%s: %d towns" % [family,towns.size()]).is_greater(330)
		for word in givens.keys()+towns.keys():
			assert_bool(Blocklist.blocks(String(word))).override_failure_message("%s made %s" % [family,word]).is_false()
		for name in full:
			for part in String(name).split(" ",false):assert_bool(Blocklist.blocks(String(part))).override_failure_message("%s made %s" % [family,name]).is_false()
			assert_int(String(name).length()).is_less_equal(Lang.FULL_MAX+4)
		# Not the old shared palette.
		var old:=0
		for given in givens:if legacy.has(given):old+=1
		assert_int(old).is_less(givens.size()/50)


func test_the_blocklist_holds_real_names_and_rude_words()->void:
	for real in ["Paris","Kyoto","Lagos","Cusco","Tenochtitlan","Babylon","Genghis","Moctezuma","Zeus","Odin","Yoruba","Maori","Nanjing","Osaka"]:
		assert_bool(Blocklist.blocks(real)).override_failure_message(real).is_true()
	for word in ["Mine","Tone","Kill","Shithead","Kanigger","Fuku"]:
		assert_bool(Blocklist.blocks(word)).override_failure_message(word).is_true()
	for invented in ["Wakumbe","Tzutum","Ngilya","Chijak","Duvopeli"]:
		assert_bool(Blocklist.blocks(invented)).override_failure_message(invented).is_false()


func test_names_follow_the_peoples_way_and_what_they_know()->void:
	var CV:=preload("res://scripts/character_voice.gd")
	var by_family:=_one_per_family(SEED)
	# Before writing the second name is a byname only, not handed down.
	CV.knowledge_override["player"]=[]
	var band:=EraNames.make(SEED,5,true,"player",{})
	assert_str(String(band.family)).is_empty()
	assert_str(String(band.name)).is_equal("%s %s" % [band.given,band.byname])
	CV.knowledge_override["player"]=["pictographic_records"]
	var lettered:=EraNames.make(SEED,5,true,"player",{})
	assert_str(String(lettered.family)).is_equal(String(lettered.byname))
	CV.knowledge_override.erase("player")
	# A family name in a woman's and a man's form, kept by kin.
	var slavic:String=by_family.slavic
	var p:=Lang.profile(slavic,SEED)
	assert_str(Lang.gendered(p,"Stamov",true)).is_equal("Stamova")
	assert_str(Lang.second(slavic,SEED,"kin",false,"Stamova")).is_equal("Stamov")
	assert_str(String(EraNames.make(SEED,9,true,slavic,{},{"family":"Dunavlov","stage":2}).family)).is_equal("Dunavlova")
	# A people that names by the father: the second name is a man's given name.
	var ethiopic:String=by_family.ethiopic
	assert_str(Lang.pattern(ethiopic,SEED)).is_equal("patronym")
	assert_str(Lang.second(ethiopic,SEED,"son",false)).is_equal(Lang.given(ethiopic,SEED,"son:father",false))
	# A given name already at court is passed over.
	var taken:={"given:"+Lang.given("player",SEED,"player:12",true):true}
	assert_str(String(EraNames.make(SEED,12,true,"player",taken).given)).is_not_equal(Lang.given("player",SEED,"player:12",true))


func test_new_towns_and_first_fires_are_named_in_the_peoples_tongue()->void:
	var used:=SettlementModel.names_in_use()
	var destination:=Vector2(31,-12)
	var name:=SettlementModel.suggested_settlement_name(destination,"Home",used)
	assert_str(name).is_equal(Lang.town("player",SEED,"place:%d:%d:%s" % [310,-120,"Home"],used))
	assert_bool(used.has(name.to_lower())).is_false()
	var heard:=preload("res://scripts/fire_circle_voice.gd").name_suggestions({"coastal":true,"woodland":0.6},7)
	assert_array(heard).has_size(3)
	for first in heard:assert_bool(Blocklist.blocks(String(first))).is_false()
	# A people's card names its tongue with a few of its names and towns.
	var line:=Lang.card_line("civ_02",SEED)
	assert_str(line).contains(Lang.tongue_name("civ_02",SEED))
	for person in Lang.sample("civ_02",SEED).persons.slice(0,2):assert_str(line).contains(String(person))


func test_looks_differ_between_peoples_and_span_human_skin()->void:
	for seed_value in [1,SEED,-212121]:
		var seen:={};var families:={};var deepest:=0.0;var palest:=1.0
		for i in range(1,14):
			var look:=Looks.profile(_owner(i),seed_value)
			var key:=str([look.family,look.depth,look.cloth])
			assert_bool(seen.has(key)).is_false();seen[key]=true
			families[look.family]=true
			assert_array(look.skin).has_size(3)
			# Light to deep within a people.
			assert_float(Color(String(look.skin[0])).get_luminance()).is_greater(Color(String(look.skin[2])).get_luminance())
			deepest=maxf(deepest,float(look.depth[1]));palest=minf(palest,float(look.depth[0]))
		assert_int(families.size()).is_equal(13)
		assert_float(palest).is_less(0.2)
		assert_float(deepest).is_greater(0.85)
	# Their tongue says nothing of their look: one family speaks many tongues.
	var tongues_of_kilnfold:={}
	for seed_value in range(1,40):
		for i in 13:
			if Looks.profile(_owner(i),seed_value).family=="kilnfold":tongues_of_kilnfold[Lang.family_for(seed_value,_owner(i))]=true
	assert_int(tongues_of_kilnfold.size()).is_greater(8)


func test_every_portrait_shows_its_own_peoples_look()->void:
	# The first age: each person is painted in their own people's set.
	GameState.elapsed_days=10*365
	for i in 13:
		var owner:=_owner(i)
		var person:={"name":"Probe %d" % i,"person_id":0,"civilization_id":owner}
		var family:=Appearance.family_for(SEED,owner)
		assert_int(Early.profile(person)).is_equal(Early.PROFILES.find(family))
		assert_str(Looks.profile(owner).family).is_equal(family)
		var picture:=Portrait.texture(person) as AtlasTexture
		assert_str(picture.atlas.resource_path).is_equal(Early.PATHS[Early.PROFILES.find(family)])
	# A foreign ruler is drawn as one of their own.
	var ruler:=preload("res://scripts/rival_rulers.gd").portrait_person("civ_05")
	assert_str(Early.owner(ruler)).is_equal("civ_05")
	# Later everyone shares one five-face painting: each people sees the faces
	# nearest its own skin first, and every face drawn fits.
	GameState.elapsed_days=400*365
	var first_faces:={}
	for i in 13:
		var owner:=_owner(i)
		var fitting:=Looks.late_fitting(owner,SEED)
		for id in range(1,9):
			var person:={"name":"Late %d" % id,"person_id":id,"civilization_id":owner}
			assert_bool(fitting.has(Portrait.natural_index(person))).is_true()
		first_faces[int(Looks.late_cells(owner,SEED)[0])]=true
		var look:=Looks.profile(owner,SEED)
		if float(look.depth[0])>=0.75:assert_int(int(Looks.late_cells(owner,SEED)[0])).is_equal(0)
		if float(look.depth[1])<=0.3:assert_bool(fitting.has(0)).is_false()
	assert_int(first_faces.size()).is_greater(2)
	# One screen still never shows the same face twice while another remains.
	var people:Array=[]
	for id in range(1,6):people.append({"name":"Court %d" % id,"person_id":id,"civilization_id":"player"})
	var keys:={}
	for slot:Array in Portrait.distinct_slots(people):keys[str([slot[0],slot[2],slot[3]])]=true
	assert_int(keys.size()).is_equal(5)


func test_older_saves_keep_their_names_and_learn_their_tongue()->void:
	# An older save: peoples, towns and people named before the tongues, with
	# no tongue kept.
	var saved:=CivilizationSystem.export_state()
	saved.civilizations[0].name="Elarin"
	saved.civilizations[0].strategic_regions[0].name="Briar Tor"
	for civ:Dictionary in saved.civilizations:civ.erase("language")
	assert_bool(CivilizationSystem.import_state(JSON.parse_string(JSON.stringify(saved))).has("ok")).is_true()
	GameState.people_language={}
	Lang.clear_cache()
	assert_str(String(CivilizationSystem.civilizations[0].name)).is_equal("Elarin")
	assert_str(String(CivilizationSystem.civilizations[0].strategic_regions[0].name)).is_equal("Briar Tor")
	# The tongue is made again from the seed, the same as a new world's, and kept.
	var made:=Lang.record("civ_01",SEED)
	assert_str(String(made.family)).is_equal(Lang.family_for(SEED,"civ_01"))
	assert_str(String((CivilizationSystem.civilizations[0].language as Dictionary).family)).is_equal(String(made.family))
	assert_str(String(Lang.record("player",SEED).family)).is_equal(Lang.family_for(SEED,"player"))
	assert_str(String(GameState.people_language.family)).is_equal(Lang.family_for(SEED,"player"))
	# A person already named keeps the name; a new one is named in the tongue.
	var old:={"person_id":1,"name":"Tala Reedwater","family":"Reedwater","status":"active"}
	var kin:=EraNames.make(SEED,2,false,"player",{},{"family":EraNames.family_of(old),"stage":2})
	assert_str(String(old.name)).is_equal("Tala Reedwater")
	assert_str(String(kin.family)).is_equal("Reedwater")
	var stranger:=EraNames.make(SEED,3,false,"civ_01",{})
	assert_str(String(stranger.given)).is_equal(Lang.given("civ_01",SEED,"civ_01:3",false))
	assert_bool(EraNames.is_given_of_sex("Tilla",true)).is_true()


func test_a_peoples_card_shows_its_tongue_and_look()->void:
	var line:=IdentityLine.build(null,"civ_03")
	var words:=line.get_node("TongueLine") as Label
	assert_str(words.text).contains(Lang.tongue_name("civ_03"))
	var chips:=line.get_node("Look")
	assert_str(chips.tooltip_text).contains(String(Looks.profile("civ_03").skin_words).substr(1))
	var swatches:=0
	for child in chips.get_children():if child is Panel:swatches+=1
	var look:=Looks.profile("civ_03")
	assert_int(swatches).is_equal((look.skin as Array).size()+(look.hair as Array).size()+(look.cloth as Array).size())
	line.free()

func test_reviewed_words_slurs_and_jokes_never_become_names()->void:
	for word in ["Niga","Injun","Kunto","Kuntah","Abo","Pus","Bum","Tit","Gay","Die","Nun","Dad","Dunce","Sushi","Tofu","Ramen","Nacho","Judo","Sumo","Sumogo",
			"Haha","Jaja","Kiki","Mandela","Borgia","Cato","Jochi","Walid","Mamun","Rumi","Temur","Takasaki","Nikon","Sanyo","Atlan","Sony","Toyota","Nike","Lisa","Steve","Daddy"]:
		assert_bool(Blocklist.blocks(word)).override_failure_message(word).is_true()
	# Slurs anywhere in a word; some only where they begin one.
	for word in ["Kaniga","Akuntu","Bonazir","Injunar","Spicora","Tasexa"]:
		assert_bool(Blocklist.blocks(word)).override_failure_message(word).is_true()
	for word in ["Minjun","Acumo"]:
		assert_bool(Blocklist.blocks(word)).override_failure_message(word).is_false()
	# Common English words in general, not only the ones the probe met.
	for word in ["Water","People","Little","Great","Friend","Money","Number"]:
		assert_bool(Blocklist.blocks(word)).override_failure_message(word).is_true()


func test_names_never_stutter_nor_double_a_two_letter_sound()->void:
	for word in ["Haha","Jaja","Kiki","Lala","Tzitzi","Kalala","Sasak","Besabesa"]:
		assert_bool(Lang.stutters(word)).override_failure_message(word).is_true()
	for word in ["Kaleo","Amani","Tzutum","Minjun","Rukungun"]:
		assert_bool(Lang.stutters(word)).override_failure_message(word).is_false()
	var by_family:=_one_per_family(SEED)
	for family:String in by_family:
		var owner:String=by_family[family]
		for i in 150:
			for word in [Lang.given(owner,SEED,"st:%d" % i,i%2==0),Lang.byname(owner,SEED,"st:%d" % i,i%2==0),Lang.town(owner,SEED,"st:%d" % i)]:
				var low:=String(word).to_lower()
				assert_bool(Lang.stutters(low)).override_failure_message("%s: %s" % [family,word]).is_false()
				var units:=Lang._units(low)
				for u in range(1,units.size()):
					if String(units[u]).length()>1:assert_str(String(units[u])).override_failure_message("%s: %s" % [family,word]).is_not_equal(String(units[u-1]))


func test_bynames_before_writing_carry_no_family_endings()->void:
	var CV:=preload("res://scripts/character_voice.gd")
	var by_family:=_one_per_family(SEED)
	for family in ["slavic","iranic","kartvelian","germanic","hellenic","amazigh","celtic","turkic","japonic"]:
		var owner:String=by_family[family]
		var p:=Lang.profile(owner,SEED)
		for i in 200:
			var word:=Lang.byname(owner,SEED,"by:%d" % i,i%2==0)
			assert_bool(Lang.has_family_mark(p,word)).override_failure_message("%s byname %s" % [family,word]).is_false()
		CV.knowledge_override[owner]=[]
		for i in 40:
			var made:=EraNames.make(SEED,500+i,i%2==0,owner,{})
			assert_str(String(made.family)).is_empty()
			assert_bool(Lang.has_family_mark(p,String(made.byname))).override_failure_message("%s band name %s" % [family,made.name]).is_false()
		CV.knowledge_override.erase(owner)
	# A family name does carry them, once there is writing.
	var slavic:String=by_family.slavic
	var marked:=0
	for i in 60:if Lang.has_family_mark(Lang.profile(slavic,SEED),Lang.second(slavic,SEED,"fam:%d" % i,false)):marked+=1
	assert_int(marked).is_greater(40)


func test_kin_take_the_right_parents_name()->void:
	var CV:=preload("res://scripts/character_voice.gd")
	var by_family:=_one_per_family(SEED)
	var ethiopic:String=by_family.ethiopic
	var slavic:String=by_family.slavic
	CV.knowledge_override[ethiopic]=["pictographic_records"]
	CV.knowledge_override[slavic]=["pictographic_records"]
	# Named by the father: a child takes the father's given name, a sibling
	# shares it, a mother passes on her husband's, cousins start afresh.
	var father:={"name":"Hamet Kebu","family":"Kebu","sex":"male"}
	assert_str(EraNames.kin_family(father,"son",ethiopic)).is_equal("Hamet")
	assert_str(EraNames.kin_family(father,"daughter",ethiopic)).is_equal("Hamet")
	assert_str(EraNames.kin_family(father,"brother",ethiopic)).is_equal("Kebu")
	assert_str(EraNames.kin_family(father,"cousin",ethiopic)).is_empty()
	var mother:={"name":"Finot Zet","family":"Zet","sex":"female","household":{"spouse":{"name":"Gawet"}}}
	assert_str(EraNames.kin_family(mother,"child",ethiopic)).is_equal("Gawet")
	assert_str(EraNames.kin_family({"name":"Finot Zet","sex":"female"},"child",ethiopic)).is_empty()
	var son:=EraNames.make(SEED,71,false,ethiopic,{},{"family":EraNames.kin_family(father,"son",ethiopic)})
	assert_str(String(son.byname)).is_equal("Hamet")
	# A family name is shared, in the child's own form.
	var kin:={"name":"Vlana Stamova","family":"Stamova","sex":"female"}
	assert_str(EraNames.kin_family(kin,"son",slavic)).is_equal("Stamova")
	assert_str(String(EraNames.make(SEED,72,false,slavic,{},{"family":EraNames.kin_family(kin,"son",slavic)}).family)).is_equal("Stamov")
	# Before writing nothing is handed down.
	CV.knowledge_override[ethiopic]=[]
	assert_str(EraNames.kin_family(father,"son",ethiopic)).is_empty()
	CV.knowledge_override.erase(ethiopic)
	CV.knowledge_override.erase(slavic)


func test_later_faces_of_a_deep_skinned_people_are_varied()->void:
	GameState.elapsed_days=400*365
	var deep:=""
	for i in 13:
		if float(Looks.profile(_owner(i),SEED).depth[0])>=0.75 and Looks.late_fitting(_owner(i),SEED).size()==1:deep=_owner(i);break
	assert_str(deep).is_not_empty()
	# Six people of that people: the one face that fits, six different ways.
	var looks:={}
	for id in range(1,7):
		var v:=Portrait.late_variant({"name":"Deep %d" % id,"person_id":id,"civilization_id":deep})
		assert_int(int(v[0])).is_equal(0)
		looks[str([v[1],v[2]])]=true
	assert_int(looks.size()).is_equal(6)
	# On one screen: the fitting face in each of its crops before a lighter face.
	var people:Array=[]
	for id in range(11,15):people.append({"name":"Screen %d" % id,"person_id":id,"civilization_id":deep})
	var slots:=Portrait.distinct_slots(people)
	var crops:={}
	var on_face:=0
	for slot:Array in slots:
		if int(slot[0])==0:on_face+=1;crops[int(slot[2])]=true
	assert_int(on_face).is_equal(3)
	assert_int(crops.size()).is_equal(3)
