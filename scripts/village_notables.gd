extends RefCounted
## Named village notables, improvised on demand and then remembered.
##
## The engine counts people in aggregate. When the god asks about one of them
## ("who is the smartest fertile man?"), a leader answers with a person, not a
## statistics lecture. That person is created deterministically from the world
## seed, settlement and question, kept in a small bounded registry (saved with
## the audience-hall payload), stays the same on re-ask, ages, and eventually
## dies. Nothing here changes population counts: notables are representatives
## drawn from the aggregate, like the bounded visual figures.

const MAX_PER_SETTLEMENT := 12
const STORE_KEY := "village_notables"

const MEN := ["Harl","Tesk","Oru","Brim","Kael","Dunn","Vesh","Tam","Pell","Rook","Faro","Garro","Nesh","Tuk","Arvo","Bekk","Joss","Lorn","Madoc","Senn","Ulf","Yarro","Dask","Hobb"]
const WOMEN := ["Ama","Sela","Iri","Nuna","Vesa","Tilla","Mora","Ysa","Kira","Oda","Luma","Hesk","Bryn","Edda","Fen","Ghia","Jora","Liss","Maren","Nell","Pira","Runa","Sabe","Wenna"]
const TRADES := ["flint-knapper","hide-scraper","fisher","trapper","fire-keeper","bone-carver","reed-weaver","tracker","digger","storyteller","wood-cutter","snare-setter","gatherer","net-maker","water-carrier","herb-finder"]
const QUALITIES := {
	"wit":{"terms":["smart","clever","wise","wisest","bright","intelligent","quick-witted","quickest mind","sharpest","learned","brain"],"say":"is quick as a hare at reckoning; the young ones bring him their knots to untie","say_f":"is quick as a hare at reckoning; the young ones bring her their knots to untie"},
	"strength":{"terms":["strong","strongest","toughest","biggest","mightiest","powerful"],"say":"carries two loads where others carry one","say_f":"carries two loads where others carry one"},
	"fertility":{"terms":["fertile","virile","most children","many children","fruitful","most sons","most daughters"],"say":"has more living children than any man his age","say_f":"has more living children than any woman her age"},
	"hunting":{"terms":["hunter","best hunter","tracker","best tracker","archer","spear"],"say":"never comes home from the hunt empty-handed","say_f":"never comes home from the hunt empty-handed"},
	"healing":{"terms":["healer","medicine","herbs","best nurse","midwife"],"say":"knows every root that eases a fever","say_f":"knows every root that eases a fever"},
	"age":{"terms":["oldest","eldest","most senior","elder"],"say":"has seen more winters than anyone living","say_f":"has seen more winters than anyone living"},
	"courage":{"terms":["bravest","boldest","fearless","courage"],"say":"was first into the river when the ice broke","say_f":"was first into the river when the ice broke"},
	"beauty":{"terms":["beautiful","handsome","prettiest","fairest","comeliest"],"say":"turns heads at every fire","say_f":"turns heads at every fire"},
	"trouble":{"terms":["troublemaker","most dangerous","angriest","worst","laziest","loudest","liar","thief"],"say":"stirs up quarrels wherever he sits","say_f":"stirs up quarrels wherever she sits"},
	"craft":{"terms":["best craftsman","best maker","best knapper","skilled","best worker","hardest worker","most skilled"],"say":"makes the finest blades in the valley","say_f":"makes the finest cord and baskets in the valley"},
}

# --------------------------------------------------------------------------
# Storage
# --------------------------------------------------------------------------

static func _store()->Dictionary:
	ForeignDiplomacy.ensure()
	var audiences:Dictionary=ForeignDiplomacy.audiences
	if not audiences.get(STORE_KEY) is Dictionary: audiences[STORE_KEY]={}
	return audiences[STORE_KEY]

static func roster(settlement_id:String)->Array:
	var store:=_store()
	if not store.get(settlement_id) is Array: store[settlement_id]=[]
	return store[settlement_id]

static func known(settlement_id:String)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for entry_variant in roster(settlement_id):
		if entry_variant is Dictionary: result.append(describe(entry_variant))
	return result

# --------------------------------------------------------------------------
# Query parsing
# --------------------------------------------------------------------------

static func is_person_query(text:String)->bool:
	var normalized:=" "+text.to_lower().strip_edges()+" "
	var asks_who:=false
	for opener in [" who is "," who's "," who are "," whom "," which man "," which woman "," which one "," name the "," tell me who "," who would "," who has "," who among "," is there a man"," is there a woman"," is there anyone"," who "]:
		if opener in normalized: asks_who=true; break
	if not asks_who: return false
	return not _qualities(normalized).is_empty() or _sex(normalized)!=""

static func _qualities(normalized:String)->Array[String]:
	var found:Array[String]=[]
	for quality in QUALITIES:
		for term_variant in (QUALITIES[quality] as Dictionary).terms:
			if String(term_variant) in normalized:
				if not found.has(String(quality)): found.append(String(quality))
				break
	found.sort()
	return found

static func _sex(normalized:String)->String:
	var male:=false
	var female:=false
	for term in [" man"," men "," men?"," husband"," father"," boy"," son "," he "," male"," lad"]:
		if term in normalized: male=true
	for term in [" woman"," women"," wife"," mother"," girl"," daughter"," she "," female"," maiden"]:
		if term in normalized: female=true
	if male and not female: return "male"
	if female and not male: return "female"
	return ""

static func query_key(text:String)->String:
	var normalized:=" "+text.to_lower().strip_edges()+" "
	var qualities:=_qualities(normalized)
	var sex:=_sex(normalized)
	return "%s|%s" % [",".join(PackedStringArray(qualities)) if not qualities.is_empty() else "notable",sex if sex!="" else "any"]

# --------------------------------------------------------------------------
# Resolution
# --------------------------------------------------------------------------

static func resolve(settlement_id:String,text:String)->Dictionary:
	## The notable who answers this question: the remembered one if alive, a
	## successor if they died, otherwise a new deterministic person.
	var key:=query_key(text)
	var day:=int(WorldSimulation.state.elapsed_days)
	var entries:=roster(settlement_id)
	var deceased:Dictionary={}
	for entry_variant in entries:
		var entry:Dictionary=entry_variant
		if not (entry.get("keys",[]) as Array).has(key): continue
		if is_alive(entry,day): return describe(entry)
		deceased=entry
	# Named person already known who satisfies the question? Reuse them.
	var wanted:=key.get_slice("|",0).split(",",false)
	var sex:=key.get_slice("|",1)
	for entry_variant in entries:
		var entry:Dictionary=entry_variant
		if not is_alive(entry,day): continue
		if sex!="any" and String(entry.get("sex",""))!=sex: continue
		var matches:=not wanted.is_empty() and String(wanted[0])!="notable"
		for quality in wanted:
			if not (entry.get("excels",[]) as Array).has(String(quality)): matches=false
		if matches:
			(entry.keys as Array).append(key)
			return describe(entry)
	var created:=_create(settlement_id,key,entries.size()+int(deceased.get("generation",0))*97)
	if not deceased.is_empty():
		created["succeeds"]=String(deceased.get("name",""))
		created["generation"]=int(deceased.get("generation",0))+1
	entries.append(created)
	while entries.size()>MAX_PER_SETTLEMENT:
		# Forget the dead first, then the oldest acquaintance.
		var removed:=false
		for index in entries.size():
			if not is_alive(entries[index],day):
				entries.remove_at(index)
				removed=true
				break
		if not removed: entries.remove_at(0)
	return describe(created)

static func find_named(settlement_id:String,text:String)->Dictionary:
	var normalized:=text.to_lower()
	for entry_variant in roster(settlement_id):
		var entry:Dictionary=entry_variant
		var given:=String(entry.get("given","")).to_lower()
		if given.length()>=3 and RegEx.create_from_string("\\b%s\\b" % given).search(normalized)!=null: return describe(entry)
	return {}

static func _create(settlement_id:String,key:String,serial:int)->Dictionary:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|%s|%s|%d" % [int(WorldSimulation.state.world_seed),settlement_id,key,serial])
	var wanted:=key.get_slice("|",0).split(",",false)
	var sex:=key.get_slice("|",1)
	if sex=="any": sex="male" if rng.randf()<0.5 else "female"
	var names:Array=MEN if sex=="male" else WOMEN
	var given:=String(names[rng.randi_range(0,names.size()-1)])
	var used:Dictionary={}
	for entry_variant in roster(settlement_id): used[String((entry_variant as Dictionary).get("given",""))]=true
	var guard:=0
	while used.has(given) and guard<names.size():
		given=String(names[(names.find(given)+1)%names.size()])
		guard+=1
	var trade:=String(TRADES[rng.randi_range(0,TRADES.size()-1)])
	if wanted.has("hunting"): trade="hunter"
	elif wanted.has("healing"): trade="herb-finder"
	elif wanted.has("craft"): trade="flint-knapper" if sex=="male" else "reed-weaver"
	var age:=rng.randi_range(24,36) if wanted.has("fertility") else rng.randi_range(22,48)
	if wanted.has("age"): age=rng.randi_range(58,71)
	var day:=int(WorldSimulation.state.elapsed_days)
	var lifespan:=rng.randi_range(52,76)
	if wanted.has("age"): lifespan=age+rng.randi_range(1,6)
	var excels:Array=[]
	for quality in wanted:
		if String(quality)!="notable": excels.append(String(quality))
	# Children stay consistent with the aggregate: the settlement's birth
	# conditions bound what one household can plausibly have.
	var fertility_bias:=1.6 if excels.has("fertility") else 0.8
	var adult_years:=maxf(0.0,float(age)-18.0)
	var children:=clampi(roundi(adult_years*0.28*fertility_bias*rng.randf_range(0.7,1.2)),0,9)
	if excels.has("fertility"): children=maxi(children,rng.randi_range(4,6))
	return {
		"id":"notable_%s_%d_%d" % [settlement_id,hash(key)&0xffffff,serial],"given":given,"trade":trade,
		"name":"%s the %s" % [given,trade],"sex":sex,"birth_day":day-age*365-rng.randi_range(0,300),
		"death_day":day+maxi(1,lifespan-age)*365+rng.randi_range(0,300),"excels":excels,"keys":[key],
		"children":children,"children_day":day,"created_day":day,"settlement_id":settlement_id,"notes":[],
	}

static func is_alive(entry:Dictionary,day:int=-1)->bool:
	var today:=int(WorldSimulation.state.elapsed_days) if day<0 else day
	return today<int(entry.get("death_day",today+1)) and not bool(entry.get("dead",false))

static func age_of(entry:Dictionary)->int:
	return maxi(0,(int(WorldSimulation.state.elapsed_days)-int(entry.get("birth_day",0)))/365)

static func children_of(entry:Dictionary)->int:
	var years:=maxf(0.0,float(int(WorldSimulation.state.elapsed_days)-int(entry.get("children_day",0)))/365.0)
	var rate:=0.55 if (entry.get("excels",[]) as Array).has("fertility") else 0.25
	if age_of(entry)>45: rate*=0.3
	return mini(14,int(entry.get("children",0))+floori(years*rate))

static func describe(entry:Dictionary)->Dictionary:
	var result:=entry.duplicate(true)
	result["age"]=age_of(entry)
	result["living_children"]=children_of(entry)
	result["alive"]=is_alive(entry)
	return result

static func note(settlement_id:String,notable_id:String,text:String)->void:
	for entry_variant in roster(settlement_id):
		var entry:Dictionary=entry_variant
		if String(entry.get("id",""))!=notable_id: continue
		var notes:Array=entry.get("notes",[])
		notes.append({"day":int(WorldSimulation.state.elapsed_days),"text":text.substr(0,160)})
		while notes.size()>6: notes.pop_front()
		entry["notes"]=notes
		return

static func prompt_view(settlement_id:String)->Array:
	## Compact list for the model so it can refer back to known people.
	var result:Array=[]
	for entry in known(settlement_id):
		if not bool(entry.get("alive",true)): continue
		result.append({"name":String(entry.get("name","")),"sex":String(entry.get("sex","")),"age":int(entry.get("age",0)),"children":int(entry.get("living_children",0)),"known_for":", ".join(PackedStringArray((entry.get("excels",[]) as Array).map(func(x:Variant)->String: return String(x))))})
		if result.size()>=8: break
	return result

# --------------------------------------------------------------------------
# Speech
# --------------------------------------------------------------------------

static func answer_line(notable:Dictionary)->String:
	## The in-world facts of the answer; the leader's voice wraps it.
	var given:=String(notable.get("given","Harl"))
	var female:=String(notable.get("sex",""))=="female"
	var pronoun:="She" if female else "He"
	var sentences:Array[String]=[]
	if not String(notable.get("succeeds","")).is_empty():
		sentences.append("%s is in the ground now. These days it would be %s." % [String(notable.succeeds).get_slice(" ",0),String(notable.get("name",given))])
	else:
		sentences.append("%s." % String(notable.get("name",given)))
	for quality_variant in notable.get("excels",[]):
		var spec:Dictionary=QUALITIES.get(String(quality_variant),{})
		if spec.is_empty(): continue
		sentences.append("%s %s." % [pronoun,String(spec.get("say_f" if female else "say",""))])
	sentences.append(_vitals(notable))
	return " ".join(sentences)

static func _vitals(notable:Dictionary)->String:
	var children:=int(notable.get("living_children",0))
	var children_text:="no children yet" if children==0 else "one living child" if children==1 else "%s living children" % _number_word(children)
	var winters:=_number_word(int(notable.get("age",30)))
	return "%s winters, %s." % [winters.substr(0,1).to_upper()+winters.substr(1),children_text]

const TRAIT_PHRASES := {"wit":"quick of mind","strength":"strong as an ox","fertility":"fruitful","hunting":"sure with a spear","healing":"gentle with the sick","age":"old and still sharp","courage":"afraid of nothing","beauty":"fair to look on","trouble":"quarrelsome","craft":"clever with the hands"}

static func trait_phrase(notable:Dictionary)->String:
	var parts:Array[String]=[]
	for quality in notable.get("excels",[]):
		if TRAIT_PHRASES.has(String(quality)): parts.append(String(TRAIT_PHRASES[String(quality)]))
	if parts.is_empty(): return "steady, and liked at every fire"
	return " and ".join(PackedStringArray(parts))

static func matcher_slots(settlement_id:String,text:String)->Dictionary:
	## Real villager slots for the offline matcher ({notable}, {trade}, {trait}),
	## so improvised replies name people the god can ask after again.
	var notable:Dictionary=resolve(settlement_id,text) if is_person_query(text) else {}
	if notable.is_empty():
		for entry in known(settlement_id):
			if bool(entry.get("alive",true)): notable=entry; break
	if notable.is_empty(): notable=resolve(settlement_id,"who is the most notable one among us")
	return {"notable":String(notable.get("given","")),"trade":String(notable.get("trade","")),"trait":trait_phrase(notable),"notable_id":String(notable.get("id",""))}

static func status_line(notable:Dictionary)->String:
	## What the leader says when the god asks after someone already named.
	var given:=String(notable.get("given","He"))
	var female:=String(notable.get("sex",""))=="female"
	if not bool(notable.get("alive",true)):
		return "%s is dead. We gave %s to the ground." % [given,"her" if female else "him"]
	var line:="%s lives, and is well enough. %s" % [given,_vitals(notable)]
	var notes:Array=notable.get("notes",[])
	if not notes.is_empty(): line+=" "+String((notes.back() as Dictionary).get("text",""))
	return line

static func _number_word(value:int)->String:
	var words:=["no","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen","twenty"]
	if value>=0 and value<words.size(): return String(words[value])
	if value<100 and value%10==0: return ["","","twenty","thirty","forty","fifty","sixty","seventy","eighty","ninety"][value/10]
	if value<100: return "%s-%s" % [["","","twenty","thirty","forty","fifty","sixty","seventy","eighty","ninety"][value/10],String(words[value%10])]
	return str(value)
