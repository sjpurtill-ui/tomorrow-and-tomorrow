extends RefCounted
## Chief Scout: turns what a returning party physically carried home into a
## plain-spoken court debrief. Every spoken claim is keyed to a fact present in
## the returned record (dated city estimates, cards, route journal, losses).
## Nothing here changes the world; the Audience Hall owns the resulting audience.

const HALL_PATH:="res://scripts/audience_hall.gd"
const VOICE_PATH:="res://scripts/character_voice.gd"
const ValuesModel:=preload("res://scripts/societal_values_model.gd")
const FACTS_MAX:=20
const NUMBER_WORDS:=["no","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"]
const TIMES_WORDS:=["","once","twice","three times","four times","five times","six times","seven times","eight times","nine times","ten times"]

# ---------------------------------------------------------------------------
# Findings
# ---------------------------------------------------------------------------

static func findings(event:Dictionary)->Dictionary:
	## Normalizes a returned scout report, envoy return or expedition record into
	## a flat list of supported facts. Missing data yields no fact, never a guess.
	var source:=_source(event)
	var day:=int(event.get("day",event.get("returned_day",_today())))
	var facts:Array[Dictionary]=[]
	var city:=_subject_city(event)
	var fields:Dictionary=city.get("fields",{}) if not city.is_empty() else {}
	var contacts:Array=event.get("contacts",[]) if event.get("contacts",[]) is Array else []
	var contact_records:Array=event.get("contact_records",[]) if event.get("contact_records",[]) is Array else []
	var subject_civ_id:=String(city.get("civ_id","")) if not city.is_empty() else ""
	if subject_civ_id=="": subject_civ_id=String(event.get("civ_id",""))
	if subject_civ_id=="" and not contact_records.is_empty(): subject_civ_id=String((contact_records[0] as Dictionary).get("civ_id",""))
	var civ_name:=String(event.get("civ_name",""))
	if civ_name=="" and subject_civ_id!="": civ_name=_civ_name(subject_civ_id)
	if civ_name=="" and not contacts.is_empty(): civ_name=String(contacts[0])
	var place:=""
	if not city.is_empty() and String(city.get("civ_id",""))!="": place=String(city.get("name",""))
	if place.begins_with("Reported") or place.begins_with("Unidentified"): place=""
	var observed_day:=int(city.get("observed_day",-1)) if not city.is_empty() else -1
	if observed_day<0: observed_day=day
	var home:Dictionary=event.get("home",{}) if event.get("home",{}) is Dictionary else {}

	# -- people and work -----------------------------------------------------
	var pop:=_field(fields,"population")
	var pop_mid:=-1.0
	if not pop.is_empty():
		pop_mid=_mid(pop)
		var shown:=_count_text(pop_mid)
		var spread:="%s to %s" % [_count_text(pop.low),_count_text(pop.high)]
		facts.append(_fact("population","≈%s people" % shown,"Roughly %s people (estimate %s)." % [shown,spread],pop.quality,{"value":pop_mid,"shown":shown,"low_shown":_count_text(pop.low),"high_shown":_count_text(pop.high)}))
		var home_pop:=float(home.get("population",0))
		if home_pop>0.0:
			facts[-1]["home_ratio"]=pop_mid/home_pop
	var production:=_field(fields,"production")
	if not production.is_empty():
		var p:=_mid(production)
		var band:=_band(p,[[0.16,"few"],[0.36,"some"],[0.60,"busy"],[9.0,"teeming"]])
		var labels:={"few":"few makers","some":"some workshops","busy":"busy workshops","teeming":"workshops everywhere"}
		var texts:={"few":"Very few people at crafts or workshops.","some":"Some workshop activity, much of it small.","busy":"Steady workshop production; many hands at crafts.","teeming":"Heavy workshop production; crafts on every side."}
		facts.append(_fact("makers",String(labels[band]),String(texts[band]),production.quality,{"value":p,"band":band,"home":float(home.get("makers",-1.0))}))
	var gdp:=_field(fields,"gdp")
	if not gdp.is_empty() and pop_mid>0.0:
		var per_head:=_mid(gdp)/pop_mid
		var busy_band:=_band(per_head,[[0.22,"idle"],[0.45,"steady"],[9.0,"hard"]])
		var busy_texts:={"idle":"Much of the population looked idle for want of work.","steady":"Most adults appeared to be working at something.","hard":"Nearly everyone of working age was at work."}
		facts.append(_fact("busyness",{"idle":"idle hands","steady":"steady work","hard":"all at work"}[busy_band],String(busy_texts[busy_band]),minf(gdp.quality,pop.get("quality",gdp.quality)),{"value":per_head,"band":busy_band}))
	var logistics:=_field(fields,"logistics")
	if not logistics.is_empty():
		var l:=_mid(logistics)
		var road_band:=_band(l,[[0.18,"paths"],[0.42,"tracks"],[9.0,"roads"]])
		facts.append(_fact("roads",{"paths":"footpaths only","tracks":"worn tracks","roads":"good roads"}[road_band],{"paths":"Only footpaths; little sign of organized carrying.","tracks":"Worn tracks and some organized carrying.","roads":"Well-kept roads and heavy carrying traffic."}[road_band],logistics.quality,{"value":l,"band":road_band}))

	# -- defenses --------------------------------------------------------------
	var fort:=_field(fields,"fortification")
	if not fort.is_empty():
		var f:=_mid(fort)
		var wall_band:=_band(f,[[0.10,"none"],[0.30,"light"],[0.58,"walled"],[9.0,"heavy"]])
		facts.append(_fact("walls",{"none":"no real defenses","light":"light defenses","walled":"walled","heavy":"heavily walled"}[wall_band],{"none":"No defenses worth the name.","light":"Light, incomplete defenses.","walled":"Substantial defensive works.","heavy":"Heavy, deep defensive works."}[wall_band],fort.quality,{"value":f,"band":wall_band,"home":float(home.get("walls",-1.0))}))
	var garrison:=_field(fields,"garrison")
	if not garrison.is_empty():
		var g:=_mid(garrison)
		var shown_g:=_count_text(g)
		facts.append(_fact("garrison","≈%s under arms" % shown_g,"About %s people under arms (estimate %s to %s)." % [shown_g,_count_text(garrison.low),_count_text(garrison.high)],garrison.quality,{"value":g,"shown":shown_g,"home":float(home.get("troops",-1.0))}))
	var damage:=_field(fields,"damage")
	if not damage.is_empty() and _mid(damage)>=0.12:
		var d:=_mid(damage)
		facts.append(_fact("damage","damaged" if d<0.4 else "badly damaged","Visible damage to the settlement." if d<0.4 else "Heavy visible damage to the settlement.",damage.quality,{"value":d,"band":"light" if d<0.4 else "heavy"}))

	# -- food and health -------------------------------------------------------
	var supply:=_field(fields,"supply")
	if not supply.is_empty():
		var s:=_mid(supply)
		var food_band:=_band(s,[[12.0,"starving"],[24.0,"thin"],[70.0,"fed"],[1e9,"full"]])
		facts.append(_fact("food",{"starving":"hungry","thin":"thin stores","fed":"fed","full":"full stores"}[food_band],{"starving":"Food reserves close to exhausted.","thin":"Food reserves thin.","fed":"Food reserves adequate.","full":"Food reserves large."}[food_band],supply.quality,{"value":s,"band":food_band,"home":float(home.get("food_days",-1.0))}))
	var health:=_field(fields,"health")
	if not health.is_empty():
		var h:=_mid(health)
		if h<0.48 or h>0.74:
			facts.append(_fact("health","sickly" if h<0.48 else "healthy","Many looked unwell." if h<0.48 else "People looked healthy.",health.quality,{"value":h,"band":"sick" if h<0.48 else "well"}))
	var life:=_field(fields,"life_expectancy")
	if not life.is_empty():
		var years:=_mid(life)
		if years<34.0 or years>52.0:
			facts.append(_fact("old_age","few elders" if years<34.0 else "many elders","Few people live to old age there." if years<34.0 else "Many people live to old age there.",life.quality,{"value":years,"band":"few" if years<34.0 else "many"}))
	var infants:=_field(fields,"infant_mortality")
	if not infants.is_empty() and _mid(infants)>=180.0:
		facts.append(_fact("infants","infant deaths high","Many infants die there.",infants.quality,{"value":_mid(infants)}))
	var education:=_field(fields,"education")
	var science:=_field(fields,"science_capacity")
	if not education.is_empty() and _mid(education)>=0.55:
		facts.append(_fact("learning","keep lessons","Children appear to be taught systematically.",education.quality,{"value":_mid(education)}))
	elif not science.is_empty() and _mid(science)>=4.0:
		var sc:=_count_text(_mid(science))
		facts.append(_fact("learning","%s scholars" % sc,"About %s people seem to spend their days on study." % sc,science.quality,{"value":_mid(science),"shown":sc}))

	# -- look of the place: architecture seen and objects carried home ----------
	var arch:Dictionary=event.get("architecture",{}) if event.get("architecture",{}) is Dictionary else {}
	var city_quality:=float(city.get("quality",0.0)) if not city.is_empty() else 0.0
	if not arch.is_empty() and (city_quality>=0.35 or source=="envoys"):
		var beauty:=_beauty_fact(arch,maxf(city_quality,0.5))
		if not beauty.is_empty(): facts.append(beauty)
	var ornaments:Array[String]=[]
	for card_variant in _cards(event):
		var card:Dictionary=card_variant
		if String(card.get("kind",""))=="artifact" and String(card.get("title",""))!="":
			ornaments.append(String(card.title))
	if not ornaments.is_empty():
		var artifact:=ornaments[0]
		var decorated:=_decorated(artifact)
		facts.append(_fact("ornament","brought: %s" % _short(artifact),"The party carried home %s%s." % [artifact," — decorated work" if decorated else ""],0.95,{"name":artifact,"decorated":decorated}))

	# -- how they were received -------------------------------------------------
	var lost:=int(event.get("lost_personnel",0))
	if lost>0:
		facts.append(_fact("losses","%d lost" % lost,"%d of the party did not come home." % lost,1.0,{"value":lost}))
	var stayed:=int(event.get("stayed_personnel",0))
	if stayed>0:
		facts.append(_fact("stayed","%d stayed behind" % stayed,"%d of the party chose to stay elsewhere." % stayed,1.0,{"value":stayed}))
	var turnback:=String(event.get("turnback_reason",""))
	if turnback!="":
		facts.append(_fact("turnback","turned back",turnback,1.0,{}))
	var reception:=_reception(event,source,subject_civ_id)
	if not reception.is_empty(): facts.append(reception)
	if not contacts.is_empty():
		facts.append(_fact("contact","first contact","First direct meeting with %s." % ", ".join(PackedStringArray(contacts)),1.0,{"names":contacts.duplicate()}))

	# -- the road ---------------------------------------------------------------
	for card_variant in _cards(event):
		var card:Dictionary=card_variant
		var kind:=String(card.get("kind",""))
		var description:=String(card.get("description",""))
		match kind:
			"resource":
				if bool(card.get("minor",false)) and facts.any(func(x:Dictionary)->bool:return String(x.key)=="resource"): continue
				var resource:=String(card.get("resource",""))
				if resource=="": continue
				var km:=int(card.get("distance_km",0))
				facts.append(_fact("resource","%s%s" % [resource.to_lower()," · %d km" % km if km>0 else ""],"%s marked about %d km out." % [resource,km] if km>0 else "%s marked on the route." % resource,clampf(float(card.get("quality",0.7)),0.4,1.0),{"resource":resource,"km":km}))
			"intelligence":
				var armed:=_first_int(description,"roughly (\\d+) under arms")
				facts.append(_fact("armed","armed column seen" if armed<0 else "≈%d armed on the road" % armed,description,0.7,{"value":armed}))
			"hearsay":
				facts.append(_fact("rumor","hearsay",description,0.35,{}))
			"encounter":
				facts.append(_fact("nomads","wanderers met",description,0.8,{}))
			"knowledge":
				facts.append(_fact("taught","learned from strangers",description,0.9,{}))
			"sign":
				facts.append(_fact("sign","signs of people · %s" % String(card.get("bearing","")),description,0.6,{"bearing":String(card.get("bearing","")),"walk_days":int(card.get("walk_days",0))}))
	var recruits:=int(event.get("recruits",0))
	if recruits>0:
		facts.append(_fact("recruits","%d newcomers" % recruits,"%d people came home with the party to join us." % recruits,1.0,{"value":recruits}))
	var terrain:=_terrain(event.get("journal",[]))
	if not terrain.is_empty(): facts.append(terrain)

	# -- dating -----------------------------------------------------------------
	var age:=maxi(0,_today()-observed_day)
	var obs_days:=int(city.get("observation_days",1)) if not city.is_empty() else 1
	var seen_text:="Observed on day %d; %s." % [observed_day,"reported today" if age==0 else "%d days ago" % age]
	facts.append(_fact("seen","seen today" if age==0 else "seen %d days ago" % age,seen_text,1.0,{"value":age,"observation_days":obs_days,"observed_day":observed_day}))
	if facts.size()>FACTS_MAX: facts.resize(FACTS_MAX)

	var flags:=_flags(facts,city.is_empty() or fields.is_empty(),contacts)
	return {
		"subject_civ_id":subject_civ_id,"subject_name":civ_name if civ_name!="" else (place if place!="" else _sign_subject(facts)),
		"place":place,"civ_name":civ_name,"source":source,"observed_day":observed_day,"age_days":age,"day":day,
		"facts":facts,"flags":flags,"home":home.duplicate(),
		"significant":_significant(facts,flags),
	}


static func _sign_subject(facts:Array[Dictionary])->String:
	## Signs of an unmet people are their own subject, never the empty country.
	var sign:Dictionary=_by_key(facts).get("sign",{})
	if sign.is_empty(): return "the wild country"
	var bearing:=String(sign.get("bearing",""))
	var what:="smoke" if String(sign.get("text","")).to_lower().contains("smoke") else "tracks"
	return "the %s to the %s" % [what,bearing] if bearing!="" else "signs of people"


static func _source(event:Dictionary)->String:
	var explicit:=String(event.get("source",""))
	if explicit in ["scouts","envoys","expedition"]: return explicit
	if event.has("accepted") or event.has("purpose"): return "envoys"
	if String(event.get("mission_kind",""))!="" or event.has("mission_id"): return "scouts"
	return "expedition"


static func _subject_city(event:Dictionary)->Dictionary:
	var cities:Array=[]
	for key in ["city_observations","returned_city_observations"]:
		var value:Variant=event.get(key,[])
		if value is Array: cities.append_array(value)
		elif value is Dictionary: cities.append_array((value as Dictionary).values())
	var target:=String(event.get("target_city_id",String(event.get("target_id","")).trim_prefix("city:")))
	var best:Dictionary={}
	var best_score:=-1.0
	for city_variant in cities:
		if not city_variant is Dictionary: continue
		var city:Dictionary=city_variant
		var fields:Dictionary=city.get("fields",{}) if city.get("fields",{}) is Dictionary else {}
		var score:=float(fields.size())*10.0+float(city.get("quality",0.0))
		if target!="" and String(city.get("city_id",""))==target: score+=1000.0
		if fields.is_empty(): score-=500.0
		if score>best_score:
			best_score=score
			best=city
	return best


static func _field(fields:Dictionary,key:String)->Dictionary:
	var field:Variant=fields.get(key,{})
	if not field is Dictionary or (field as Dictionary).is_empty(): return {}
	var low:=float(field.get("observed_low",field.get("low",-1.0)))
	var high:=float(field.get("observed_high",field.get("high",-1.0)))
	if low<0.0 or high<low or not is_finite(high): return {}
	return {"low":low,"high":high,"quality":clampf(float(field.get("quality",0.5)),0.0,1.0),"observed_day":int(field.get("observed_day",-1))}


static func _mid(field:Dictionary)->float:
	return (float(field.get("low",0.0))+float(field.get("high",0.0)))*0.5


static func _band(value:float,bands:Array)->String:
	for band in bands:
		if value<float(band[0]): return String(band[1])
	return String(bands[-1][1])


static func _fact(key:String,label:String,text:String,confidence:float,extra:Dictionary)->Dictionary:
	var fact:={"key":key,"label":label.substr(0,40),"text":text.substr(0,400),"confidence":snappedf(clampf(confidence,0.0,1.0),0.01)}
	for k in extra: fact[k]=extra[k]
	return fact


static func _count_text(value:float)->String:
	var v:=maxf(0.0,value)
	var step:=1.0
	if v>=20000.0: step=500.0
	elif v>=2000.0: step=50.0
	elif v>=200.0: step=10.0
	elif v>=40.0: step=5.0
	var rounded:=int(roundf(v/step)*step)
	if rounded>=10000:
		var s:=str(rounded)
		var out:=""
		for i in s.length():
			if i>0 and (s.length()-i)%3==0: out+=","
			out+=s[i]
		return out
	return str(rounded)


static func _short(text:String)->String:
	var cut:=text.split("·")[0].strip_edges()
	return cut.to_lower() if cut.length()<=28 else cut.substr(0,26).to_lower()+"…"


static func _decorated(name:String)->bool:
	var lower:=name.to_lower()
	for word in ["etched","painted","carved","ceremonial","incised","ornament","decorat","figur","bead","inlaid"]:
		if word in lower: return true
	return false


static func _cards(event:Dictionary)->Array:
	var result:Array=[]
	for key in ["discoveries","brought_home"]:
		var value:Variant=event.get(key,[])
		if value is Array:
			for card in value:
				if card is Dictionary: result.append(card)
	return result


static func _first_int(text:String,pattern:String)->int:
	var regex:=RegEx.new()
	regex.compile(pattern)
	var match_result:=regex.search(text)
	if match_result==null: return -1
	return int(match_result.get_string(1))


static func _beauty_fact(arch:Dictionary,quality:float)->Dictionary:
	# The rendered settlement's look is derived from these same aggregate values,
	# so the party is describing what anyone standing there would see.
	var details:Array[String]=[]
	var keys:Array[String]=[]
	if float(arch.get("civic_space",0.0))>=0.6: details.append("open common ground kept clear at the heart of it"); keys.append("civic_space")
	if float(arch.get("terrain_conformity",0.0))>=0.62: details.append("every building tucked into the lie of the land as if it grew there"); keys.append("terrain_conformity")
	if float(arch.get("monumentality",0.0))>=0.62: details.append("raised buildings you can see from far off, built to make a visitor feel small"); keys.append("monumentality")
	if float(arch.get("permeability",0.0))>=0.68: details.append("paths running straight in from every side, nothing shut against you"); keys.append("permeability")
	if details.is_empty(): return {}
	var score:=0.0
	for key in ["civic_space","terrain_conformity","monumentality"]: score=maxf(score,float(arch.get(key,0.0)))
	var lovely:=score>=0.68 or details.size()>=2
	return _fact("beauty","handsome town" if lovely else "notable layout","Settlement layout: %s." % "; ".join(PackedStringArray(details)),clampf(quality,0.3,0.9),{"details":details,"traits":keys,"lovely":lovely})


static func _reception(event:Dictionary,source:String,civ_id:String)->Dictionary:
	if source=="envoys" and event.has("accepted"):
		var accepted:=bool(event.get("accepted",false))
		var outcome:=String(event.get("outcome",""))
		return _fact("reception","received" if accepted else "turned away",outcome if outcome!="" else ("The delegation was received." if accepted else "The proposal was refused."),1.0,{"band":"welcome" if accepted else "refused"})
	var response:Dictionary=event.get("recruitment_account",{}).get("diplomatic_response",{}) if event.get("recruitment_account",{}) is Dictionary else {}
	if String(response.get("severity",""))=="hostile":
		return _fact("reception","hostile",String(response.get("message","They answered the visit with open hostility.")),0.9,{"band":"hostile"})
	var relation:Dictionary=event.get("relation",{}) if event.get("relation",{}) is Dictionary else {}
	if relation.is_empty() or civ_id=="": return {}
	if bool(relation.get("at_war",false)):
		return _fact("reception","at war with us","This people is at war with us.",1.0,{"band":"hostile"})
	var opinion:=float(relation.get("opinion",0.0))
	var tension:=float(relation.get("border_tension",0.0))
	if opinion<=-0.35 or tension>=0.6:
		return _fact("reception","hostile","Their standing toward us is hostile.",0.8,{"band":"hostile"})
	if opinion>=0.35:
		return _fact("reception","friendly","Their standing toward us is friendly.",0.8,{"band":"welcome"})
	return {}


static func _terrain(journal_variant:Variant)->Dictionary:
	if not journal_variant is Array or (journal_variant as Array).is_empty(): return {}
	var journal:Array=journal_variant
	var legs:Array[String]=[]
	var leg_days:Array[int]=[]
	var rivers:=0
	var high:=false
	var coast:=false
	var regex:=RegEx.new()
	regex.compile("(\\d+) days? across ([^;.]+)")
	for line_variant in journal:
		var line:=String(line_variant)
		if line.begins_with("The outward road"):
			for m in regex.search_all(line):
				leg_days.append(int(m.get_string(1)))
				legs.append(m.get_string(2).strip_edges())
		if "forded running water" in line:
			rivers=maxi(1,_first_int(line,"(\\d+) times"))
			if " twice" in line: rivers=2
		if "treeline" in line or "high bare ground" in line: high=true
		if "open water" in line: coast=true
	if legs.is_empty() and rivers==0 and not high and not coast: return {}
	var label:=legs[0] if not legs.is_empty() else ("high country" if high else "river country")
	var text:=String(journal[0])
	if journal.size()>1: text+=" "+" ".join(PackedStringArray(journal.slice(1).map(func(x):return String(x))))
	return _fact("terrain",label.substr(0,40),text,1.0,{"legs":legs,"leg_days":leg_days,"rivers":rivers,"high":high,"coast":coast})


static func _flags(facts:Array[Dictionary],no_city:bool,contacts:Array)->Dictionary:
	var by:=_by_key(facts)
	var flags:={}
	var makers:=String(by.get("makers",{}).get("band",""))
	var busy:=String(by.get("busyness",{}).get("band",""))
	flags["poor"]=makers=="few" or busy=="idle"
	flags["rich"]=makers in ["busy","teeming"] or (busy=="hard" and makers!="few")
	var walls:=String(by.get("walls",{}).get("band",""))
	flags["walled"]=walls in ["walled","heavy"]
	flags["open"]=walls=="none"
	var food:=String(by.get("food",{}).get("band",""))
	flags["starving"]=food=="starving"
	flags["hungry"]=food in ["starving","thin"]
	flags["sick"]=String(by.get("health",{}).get("band",""))=="sick"
	flags["beautiful"]=bool(by.get("beauty",{}).get("lovely",false)) or bool(by.get("ornament",{}).get("decorated",false))
	flags["hostile"]=String(by.get("reception",{}).get("band",""))in ["hostile","refused"] or by.has("losses")
	flags["big"]=float(by.get("population",{}).get("home_ratio",0.0))>=1.4
	flags["small"]=by.has("population") and float(by.get("population",{}).get("home_ratio",1.0))<0.7
	flags["armed"]=by.has("armed") or float(by.get("garrison",{}).get("value",0.0))>=40.0
	flags["empty"]=no_city and contacts.is_empty() and not by.has("nomads") and not by.has("reception") and not by.has("sign")
	flags["signs"]=by.has("sign") and contacts.is_empty()
	return flags


static func _significant(facts:Array[Dictionary],flags:Dictionary)->bool:
	var by:=_by_key(facts)
	for key in ["population","makers","walls","food","garrison","contact","losses","armed","ornament","reception","nomads","taught","recruits","turnback","beauty","sign"]:
		if by.has(key): return true
	if by.has("resource"):
		for fact in facts:
			if String(fact.key)=="resource" and String(fact.get("resource",""))!="Fiber Plants": return true
	return false


static func _by_key(facts:Array)->Dictionary:
	var by:={}
	for fact_variant in facts:
		if not fact_variant is Dictionary: continue
		var key:=String(fact_variant.get("key",""))
		if key!="" and not by.has(key): by[key]=fact_variant
	return by


static func _all(facts:Array,key:String)->Array:
	var result:=[]
	for fact_variant in facts:
		if fact_variant is Dictionary and String(fact_variant.get("key",""))==key: result.append(fact_variant)
	return result

# ---------------------------------------------------------------------------
# The debrief
# ---------------------------------------------------------------------------

static func debrief_lines(audience:Dictionary)->Array[Dictionary]:
	## Offline debrief in the contract Line shape, 3–6 lines, deterministic per
	## audience. Each sentence is anchored to a fact present in audience.report.
	var report:Dictionary=audience.get("report",{}) if audience.get("report",{}) is Dictionary else {}
	var facts:Array=report.get("facts",[]) if report.get("facts",[]) is Array else []
	var by:=_by_key(facts)
	var flags:Dictionary=report.get("flags",{}) if report.get("flags",{}) is Dictionary else _flags_from(facts)
	var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker",{}) is Dictionary else {}
	var persona:=_persona(speaker)
	var day:=int(audience.get("arrived_day",report.get("observed_day",_today())))
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%s|%s|%s|%d|%d" % [str(audience.get("id","")),String(report.get("subject_name","")),String(report.get("source","")),int(report.get("observed_day",0)),int(speaker.get("person_id",0))])
	var ctx:={"addr":String(persona.address),"place":_place_phrase(report),"people":_people_phrase(report),"source":String(report.get("source","scouts"))}
	var body:Array[String]=[]
	var used:={}
	# 1. How it felt to arrive.
	body.append(_opener(by,flags,ctx,persona,rng,used))
	# 2. The middle: the most telling facts, in order of what a scout would blurt.
	var beats:Array[Callable]=[]
	if by.has("losses") or String(by.get("reception",{}).get("band",""))!="" or by.has("turnback"): beats.append(_beat_reception.bind(by,flags,ctx,persona,rng,used))
	if by.has("population"): beats.append(_beat_size.bind(by,flags,ctx,persona,rng,used))
	if flags.get("poor",false) and flags.get("beautiful",false): beats.append(_beat_poor_but_lovely.bind(by,flags,ctx,persona,rng,used))
	else:
		if by.has("makers") or by.has("busyness"): beats.append(_beat_work.bind(by,flags,ctx,persona,rng,used))
		if by.has("beauty") or by.has("ornament"): beats.append(_beat_beauty.bind(by,flags,ctx,persona,rng,used))
	if by.has("walls") or by.has("garrison") or by.has("damage"): beats.append(_beat_defense.bind(by,flags,ctx,persona,rng,used))
	if by.has("armed"): beats.append(_beat_armed.bind(by,flags,ctx,persona,rng,used))
	if by.has("food") or by.has("health") or by.has("old_age") or by.has("infants"): beats.append(_beat_food.bind(by,flags,ctx,persona,rng,used))
	if by.has("resource"): beats.append(_beat_covet.bind(facts,by,flags,ctx,persona,rng,used))
	if by.has("nomads") or by.has("taught") or by.has("recruits"): beats.append(_beat_people_met.bind(by,flags,ctx,persona,rng,used))
	if by.has("sign"): beats.push_front(_beat_signs.bind(by,flags,ctx,persona,rng,used))
	if by.has("rumor"): beats.append(_beat_rumor.bind(by,flags,ctx,persona,rng,used))
	if flags.get("empty",false) and by.has("terrain"): beats.push_front(_beat_country.bind(by,flags,ctx,persona,rng,used))
	for beat in beats:
		if body.size()>=5: break
		var text:=String(beat.call())
		if text!="": body.append(text)
	# 3. What worries them, what they'd do, and how old the news is.
	body.append(_closing(by,flags,ctx,persona,rng,used))
	while body.size()<3:
		var filler:=_filler(by,ctx,persona,rng,used)
		if filler=="": break
		body.insert(body.size()-1,filler)
	var lines:Array[Dictionary]=[]
	var dialect:=_dialect(persona)
	var oath_line:=1 if body.size()>2 and rng.randf()<0.45 else -1
	for index in body.size():
		var text:=body[index].strip_edges()
		if text=="": continue
		# Home-district speech is woven into the sentences themselves (word
		# choices, an opening interjection, one oath at the surprising part),
		# never bolted on as a trailing catchphrase.
		text=_era_plain(_weave(dialect,text,rng,index==0,index==oath_line))
		lines.append({"speaker":String(persona.name),"role":"official","person_id":int(speaker.get("person_id",0)),"civ_id":"player","text":text,"day":day,"aside":false})
	_thin_address(lines,String(persona.address))
	# A muttered aside, if the speaker is the sort.
	var aside:=_era_plain(_aside(by,flags,persona,rng))
	if aside!="" and lines.size()<6:
		lines.append({"speaker":String(persona.name),"role":"official","person_id":int(speaker.get("person_id",0)),"civ_id":"player","text":aside,"day":day,"aside":true})
	return lines


static func _thin_address(lines:Array[Dictionary],address:String)->void:
	# People say "Your Grace" once or twice in a report, not in every breath.
	if address=="": return
	var seen:=0
	for line in lines:
		var text:=String(line.text)
		var parts:=text.split(address)
		if parts.size()<=1: continue
		var rebuilt:=parts[0]
		for i in range(1,parts.size()):
			seen+=1
			if seen<=2:
				rebuilt+=address+parts[i]
			else:
				if rebuilt.ends_with(", "): rebuilt=rebuilt.substr(0,rebuilt.length()-2)
				elif rebuilt.ends_with(" "): rebuilt=rebuilt.substr(0,rebuilt.length()-1)
				var rest:=parts[i]
				if rest.begins_with(","): rest=rest.substr(1)
				rebuilt+=rest
		line["text"]=rebuilt.replace("  "," ").strip_edges()


static func _flags_from(facts:Array)->Dictionary:
	var typed:Array[Dictionary]=[]
	for fact in facts:
		if fact is Dictionary: typed.append(fact)
	return _flags(typed,not _by_key(facts).has("population"),[])


static func _persona(speaker:Dictionary)->Dictionary:
	var pid:=int(speaker.get("person_id",0))
	var person:Dictionary={}
	if pid>0: person=GovernmentPeopleSystem.person_snapshot(pid)
	var voice_persona:Dictionary={}
	var voice:=_voice_script()
	if voice!=null and not person.is_empty():
		var made:Variant=voice.call("for_person",person)
		if made is Dictionary: voice_persona=made
	var traits:Array=person.get("traits",[])
	var temperament:="wry"
	for t in traits:
		match String(t):
			"Forceful","Severe","Bold","Principled": temperament="blunt"; break
			"Curious","Inventive","Warm","Generous","Diplomatic": temperament="wonder"; break
			"Cautious","Methodical","Traditional","Patient","Humble": temperament="wary"; break
			"Ambitious","Frugal": temperament="hungry"; break
			"Skeptical","Pragmatic": temperament="wry"; break
	var address:=String(voice_persona.get("address",""))
	if address=="": address="Your Grace"
	return {"name":String(speaker.get("name",person.get("name","The scout"))),"title":String(speaker.get("title","Chief Scout")),
		"temperament":temperament,"honest":float(person.get("honesty",0.6))>=0.45,"nervous":float(person.get("courage",0.6))<0.36,
		"address":address,"voice_persona":voice_persona,"traits":traits}


static func _dialect(persona:Dictionary)->Dictionary:
	var voice_persona:Dictionary=persona.get("voice_persona",{})
	var voice:=_voice_script()
	if voice==null or voice_persona.is_empty(): return {}
	var found:Variant=voice.call("dialect",String(voice_persona.get("dialect_id","")))
	return found if found is Dictionary else {}


static func _weave(dialect:Dictionary,text:String,rng:RandomNumberGenerator,opening:bool,oath:bool)->String:
	if dialect.is_empty(): return text
	var out:=text
	var subs:Dictionary=dialect.get("subs",{})
	for key_variant in subs:
		var key:=String(key_variant)
		var replacement:=String(subs[key_variant])
		var bounded:=key.ends_with(" ")
		var pattern:=RegEx.new()
		pattern.compile("(?i)\\b"+_regex_escape(key.strip_edges())+("\\s" if bounded else "\\b"))
		var m:=pattern.search(out)
		while m!=null:
			var original:=m.get_string()
			var swap:=replacement+(" " if bounded and replacement!="" else "")
			var first:=original.substr(0,1)
			if first!=first.to_lower() and swap!="": swap=swap.substr(0,1).to_upper()+swap.substr(1)
			out=out.substr(0,m.get_start())+swap+out.substr(m.get_end())
			m=pattern.search(out,m.get_start()+swap.length())
	out=out.replace("  "," ").strip_edges()
	if out!="" and out.substr(0,1)!=out.substr(0,1).to_upper(): out=out.substr(0,1).to_upper()+out.substr(1)
	if oath:
		var oaths:Array=dialect.get("oath",[])
		if not oaths.is_empty(): out="%s %s" % [String(oaths[rng.randi_range(0,oaths.size()-1)]),out]
	elif opening and rng.randf()<0.55:
		var opens:Array=dialect.get("open",[])
		var addresses:Array=dialect.get("address",[])
		var lead:=String(opens[rng.randi_range(0,opens.size()-1)]) if not opens.is_empty() else ""
		var doubled:=false
		for address in addresses:
			if String(address).to_lower() in lead.to_lower() and String(address).to_lower() in out.to_lower(): doubled=true
		if lead!="" and not doubled:
			out="%s %s" % [lead,_sentence_tail(out)]
	return out


const COMMON_STARTS:=["You","We","The","They","Their","There's","There","Nobody","Nobody's","Quiet","Empty","Well.","Home","New","Before","Not","About","Small","Only","Much","Poor","Walls?","Defenses?","Heavily","Proper","Hungry.","Hungry","Food's","Food?","Stores","Cold","Make","Everyone's","Everybody","Craft","Good","Mark","And","Best","One","That","That's","If","Rich","A","It","Somebody","Our","Some","Plenty","Lots","Healthy-looking","Coughs","Hardly","Handsome","Whatever","Look","Something","Wrecked,","On","All","Mind","Take","Near","Counting","Don't","Barely","Much","Send","Walls","Friendly","Real"]


static func _sentence_tail(text:String)->String:
	# Lower the first letter only for ordinary sentence openers, never for a
	# place or people's name.
	var first_word:=text.split(" ")[0]
	if first_word in COMMON_STARTS: return text.substr(0,1).to_lower()+text.substr(1)
	return text


static func _regex_escape(text:String)->String:
	var out:=""
	for c in text:
		if c in ".^$*+?()[]{}|\\": out+="\\"
		out+=c
	return out


static func _era_plain(text:String)->String:
	## A scout names only what the home people can name: no carts before the
	## wheel, no saddles before the pack saddle, no bullets before guns.
	var voice:=_voice_script()
	if voice==null or text=="": return text
	var told:Variant=voice.call("era_plain_for",text,"player")
	return String(told) if told is String else text


static func _voice_script()->Script:
	if not ResourceLoader.exists(VOICE_PATH): return null
	var script:=load(VOICE_PATH) as Script
	if script==null: return null
	for method in script.get_script_method_list():
		if String(method.get("name",""))=="speak":
			return script
	return null


static func _pick(rng:RandomNumberGenerator,options:Array)->String:
	if options.is_empty(): return ""
	return String(options[rng.randi_range(0,options.size()-1)])


static func _fill(template:String,ctx:Dictionary)->String:
	return template.format(ctx)


static func _hedge(fact:Dictionary,persona:Dictionary,rng:RandomNumberGenerator)->String:
	# Frank uncertainty, spoken the way people actually say it.
	var confidence:=float(fact.get("confidence",1.0))
	if confidence>=0.62 or not bool(persona.honest): return ""
	return _pick(rng,["I'd not swear to it, but ","Counting from a hillside, mind — ","Take this with a pinch of salt: ","Near as I could tell, ","Don't hold me to the number, but "])


static func _hedged(hedge:String,text:String)->String:
	if hedge=="" or text=="": return text
	return hedge+_sentence_tail(text)


static func _place_phrase(report:Dictionary)->String:
	var place:=String(report.get("place",""))
	if place!="": return place
	var name:=String(report.get("civ_name",report.get("subject_name","")))
	if name!="" and name!="the wild country": return "the %s town" % name if not name.to_lower().begins_with("the ") else "%s's town" % name
	return "their town"


static func _people_phrase(report:Dictionary)->String:
	var name:=String(report.get("civ_name",report.get("subject_name","")))
	if name=="" or name=="the wild country": return "they"
	return name if name.to_lower().begins_with("the ") else "the %s" % name


static func _cap(text:String)->String:
	if text.is_empty(): return text
	return text.substr(0,1).to_upper()+text.substr(1)


static func _opener(by:Dictionary,flags:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	var source:=String(ctx.source)
	if by.has("losses"):
		used["losses"]=true
		var n:=int(by.losses.get("value",1))
		return _fill(_pick(rng,[
			"I'll say the hard part first, {addr}: {n_word} of ours didn't come home. Everything else I tell you, we paid for.",
			"We came back short, {addr}. {N_word} missing. I've told their families; now I'll tell you what they died finding out.",
			"Before the rest — we lost {n_word}. I want that said out loud in this hall before anyone starts counting what we gained.",
		]),ctx.merged({"n_word":_number_word(n),"N_word":_cap(_number_word(n))}))
	if source=="envoys" and by.has("reception"):
		used["reception"]=true
		if String(by.reception.get("band",""))=="refused":
			return _fill(_pick(rng,[
				"They heard us out at {place}, {addr}, and sent us home with nothing but sore feet and a polite no.",
				"Well. They listened. Nodded a great deal. Then said no, which they could have done at the gate and saved us the walk.",
			]),ctx)
		return _fill(_pick(rng,[
			"They let us in at {place}, {addr}, and said yes — though I noticed they never once let us wander off alone.",
			"We were received, {addr}. Properly, too — and while the talkers talked, I kept my eyes open.",
		]),ctx)
	if flags.get("empty",false):
		var terrain:Dictionary=by.get("terrain",{})
		used["terrain"]=true
		var country:=_country_phrase(terrain)
		if country=="":
			return _fill(_pick(rng,["Nobody out there, {addr}. Not a soul, not a thread of smoke. Just country, and the wind having opinions about it.","Empty, {addr}. We walked until our shadows got bored and met no one at all."]),ctx)
		return _fill(_pick(rng,[
			"Nobody out there, {addr}. Not a soul, not a thread of smoke — just {country}, and the wind for company.",
			"{Country_cap}. That's what's out there, {addr}. No people, no smoke, nobody's footprints but our own.",
			"We walked {country} and met not one living person. I started talking to my own pack by the end.",
		]),ctx.merged({"country":country,"Country_cap":_cap(country)}))
	if by.has("makers"):
		used["makers_sound"]=true
		match String(by.makers.get("band","")):
			"teeming","busy":
				return _fill(_pick(rng,[
					"You hear {place} before you see it, {addr} — hammering from first light, and workshop smoke you can taste at the back of your throat.",
					"{Place_cap} never shuts up, {addr}. Hammers, shouting, somebody always calling for more of something.",
					"The first thing about {place} is the noise, {addr}. Everybody's knocking on something.",
				]),ctx.merged({"Place_cap":_cap(String(ctx.place))}))
			"few":
				return _fill(_pick(rng,[
					"{Place_cap} is a quiet place, {addr}. Too quiet. No hammering, no workshop smoke — you could hear the wind.",
					"We lay above {place} and I don't think I heard a hammer the whole while. Strange, for so many people.",
					"Quiet as a held breath, {place}. Nobody knocking on anything, {addr}. That told me most of what I needed.",
				]),ctx.merged({"Place_cap":_cap(String(ctx.place))}))
			_:
				return _fill(_pick(rng,[
					"{Place_cap} hums along, {addr} — a hammer here, a shout there, nobody in any great hurry.",
					"We had a good long look at {place}, {addr}. Ordinary sort of busy, the way a place is when nothing's on fire.",
				]),ctx.merged({"Place_cap":_cap(String(ctx.place))}))
	if by.has("contact"):
		used["contact"]=true
		var name:=String((by.contact.get("names",[""]) as Array)[0]) if not (by.contact.get("names",[]) as Array).is_empty() else String(ctx.people)
		return _fill(_pick(rng,[
			"We met people, {addr}. Real ones, not rumours — they call themselves {name}, and they stared at us exactly as hard as we stared at them.",
			"New faces, {addr}. {name}. We came over a rise and there they were, and for a long breath nobody knew what to do with their hands.",
		]),ctx.merged({"name":name}))
	if by.has("population"):
		return _fill(_pick(rng,[
			"We got close enough to {place} to count heads, {addr} — not close enough to be offered supper.",
			"We watched {place} from the high ground, {addr}. Here's what we saw.",
		]),ctx)
	return _fill(_pick(rng,["We're back, {addr}, and we've things to tell.","Home again, {addr}, and not empty-handed."]),ctx)


static func _beat_reception(by:Dictionary,flags:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	if by.has("turnback") and not used.has("turnback"):
		used["turnback"]=true
		var reason:=String(by.turnback.get("text","")).trim_suffix(".")
		return _fill(_pick(rng,["We never reached where you sent us: {reason}. I'll not pretend otherwise.","We turned back, {addr}. {Reason}. I'd rather bring everyone home than push on and lose them."]),ctx.merged({"reason":reason.to_lower() if reason.length()>0 else reason,"Reason":reason}))
	if by.has("reception") and not used.has("reception"):
		used["reception"]=true
		match String(by.reception.get("band","")):
			"hostile":
				return _fill(_pick(rng,[
					"They know who we are, and they don't like it. Every one of them watched us like we'd come to steal the washing.",
					"Cold as a winter well, {addr}. Nobody threw anything, but I saw a few thinking about it.",
					"Make no mistake about {people}: they see us as trouble, and they'd sooner we stayed home.",
				]),ctx)
			"welcome":
				return _fill(_pick(rng,["They were glad enough to see us — or they pretend beautifully.","Friendly lot. Too friendly, maybe. But they fed us and let us walk about."]),ctx)
			"refused":
				return _fill(_pick(rng,["They said no, and said it politely, which somehow made it worse.","A no, {addr}. They didn't leave any room to ask again."]),ctx)
	if by.has("losses") and not used.has("losses"):
		used["losses"]=true
		return _fill("We lost {n}, {addr}. I'd have that remembered when we talk about what this cost.",ctx.merged({"n":_number_word(int(by.losses.get("value",1)))}))
	return ""


static func _beat_size(by:Dictionary,flags:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	var pop:Dictionary=by.population
	used["population"]=true
	var shown:=String(pop.get("shown",""))
	var hedge:=_hedge(pop,persona,rng)
	var ratio:=float(pop.get("home_ratio",0.0))
	var text:=""
	if ratio<=0.0:
		text=_pick(rng,["There's about {pop} of them.","I make it {pop} people, give or take."])
	elif ratio>=2.4:
		text=_pick(rng,[
			"There's a crowd of them — about {pop}. That's {times} our number, and they didn't look like they'd noticed us at all.",
			"About {pop} people, {addr}. {Times} what we are. I counted twice because I didn't like the first answer.",
			"{pop} of them, near enough. Put all of us in among them and you'd hardly notice we'd arrived.",
		])
	elif ratio>=1.25:
		text=_pick(rng,["About {pop} of them by my count — more than us, not by a mile, but more.","{pop}, give or take. Bigger than us. Not frighteningly. Yet."])
	elif ratio>=0.8:
		text=_pick(rng,["About {pop} souls — near enough our own size. We'd look each other in the eye.","Much our size: {pop} or so. We'd be evenly matched."])
	else:
		text=_pick(rng,["Small place — {pop}, give or take. We'd outnumber them {outnumber}.","Only about {pop} of them, {addr}. You could lose that many at one of our harvest feasts and not notice."])
	var rev:=1.0/maxf(0.01,ratio) if ratio>0.0 else 1.0
	var outnumber:="%s to one" % _number_word(roundi(rev)) if rev>=1.75 else "comfortably"
	return _hedged(hedge,_fill(text,ctx.merged({"pop":shown,"times":_times_word(ratio),"Times":_cap(_times_word(ratio)),"outnumber":outnumber})))


static func _beat_work(by:Dictionary,flags:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	var makers:Dictionary=by.get("makers",{})
	var busy:Dictionary=by.get("busyness",{})
	var band:=String(makers.get("band",""))
	var text:=""
	if band=="few" or (band=="" and String(busy.get("band",""))=="idle"):
		text=_pick(rng,[
			"Poor, {addr}. Hardly a workshop between them, and the few there were stood half idle.",
			"Nobody's making much. I saw more people sitting about than working at anything.",
			"They own what they carry and not much besides. If they've a craftsman worth the name, he was hiding from us.",
		])
		if String(busy.get("band",""))=="idle" and band!="": text+=" "+_pick(rng,["Plenty of hands, mind. Just nothing in them.","It's not laziness — there's just no work to go round."])
	elif band in ["busy","teeming"]:
		text=_pick(rng,[
			"They're rich, and they don't hide it. Workshops cheek by jowl, and every pair of hands busy at something.",
			"Everyone's making something — stand still there and somebody hands you a job.",
			"Craft everywhere you look, {addr}. It made my fingers itch to steal a trade or two.",
		])
	elif band=="some":
		text=_pick(rng,["They get by. Some workshops, some idle hands — like us on a good week, if I'm honest.","A few workshops, working steady. Nothing to write songs about."])
	elif String(busy.get("band",""))=="hard":
		text=_pick(rng,["Everybody works there, {addr}. Everybody. Even the ones who look like they shouldn't.","Not an idle soul in sight — I felt guilty just standing there counting them."])
	elif String(busy.get("band",""))=="idle":
		text=_pick(rng,["A lot of people sitting about with nothing to do. Either they're at ease, or they're bored and restless.","Idle hands everywhere. Bored young men with nothing to do will start looking for trouble."])
	if text=="": return ""
	used["makers"]=true
	var home:=float(makers.get("home",-1.0))
	var theirs:=float(makers.get("value",-1.0))
	if home>=0.0 and theirs>=0.0 and rng.randf()<0.8:
		if theirs>home+0.15: text+=" "+_pick(rng,["More hands at work than we've got, and it galls me to say so.","Our own workshops would look sleepy next to theirs."])
		elif theirs<home-0.15: text+=" "+_pick(rng,["Our workshops would put theirs to shame.","We make more in a week than they do in a month, I'd guess."])
	return _hedged(_hedge(makers if not makers.is_empty() else busy,persona,rng),_fill(text,ctx))


static func _beauty_detail(by:Dictionary,rng:RandomNumberGenerator)->String:
	var beauty:Dictionary=by.get("beauty",{})
	var details:Array=beauty.get("details",[])
	if not details.is_empty(): return String(details[rng.randi_range(0,details.size()-1)])
	return ""


static func _beat_poor_but_lovely(by:Dictionary,flags:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	used["makers"]=true
	used["beauty"]=true
	var detail:=_beauty_detail(by,rng)
	var ornament:Dictionary=by.get("ornament",{})
	var extra:={"detail":detail,"thing":String(ornament.get("name","")).split("·")[0].strip_edges().to_lower()}
	if detail!="":
		return _fill(_pick(rng,[
			"Poor as field mice, {addr} — hardly a workshop fire between them. But the place is lovely: {detail}. I stood there longer than a scout should.",
			"They've next to nothing, but they've taken care of the place. {Detail}. Our camp looks shabby beside it.",
			"No riches — hardly a craftsman working. And yet, {addr}, I'd live there tomorrow. {Detail}.",
		]),ctx.merged(extra).merged({"Detail":_cap(detail)}))
	used["ornament"]=true
	return _fill(_pick(rng,[
		"Poor as field mice, {addr} — hardly a workshop working. But look at this {thing} we brought home. Somebody with nothing took their time over that.",
		"They've not much of anything. Except this {thing} — look at the work on it. Someone spent days on that.",
	]),ctx.merged(extra))


static func _beat_beauty(by:Dictionary,flags:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	if used.has("beauty") and used.has("ornament"): return ""
	var parts:Array[String]=[]
	if by.has("beauty") and not used.has("beauty"):
		used["beauty"]=true
		var detail:=_beauty_detail(by,rng)
		var lovely:=bool(by.beauty.get("lovely",false))
		if String(persona.temperament)=="wonder":
			parts.append(_fill(_pick(rng,["And it's beautiful, {addr}. I don't say that of places. {Detail}.","I'll be honest, I forgot to count for a while. {Detail}."]),ctx.merged({"Detail":_cap(detail)})))
		elif lovely:
			parts.append(_fill(_pick(rng,["Handsome place, I'll give them that: {detail}.","Whatever else, they build well — {detail}."]),ctx.merged({"detail":detail})))
		else:
			parts.append(_fill("They lay a town out their own way: {detail}.",ctx.merged({"detail":detail})))
	if by.has("ornament") and not used.has("ornament"):
		used["ornament"]=true
		var thing:=String(by.ornament.get("name","")).split("·")[0].strip_edges().to_lower()
		if bool(by.ornament.get("decorated",false)):
			parts.append(_fill(_pick(rng,["And we brought this home — a {thing}. Hold it to the light. Somebody took their time over that.","Look at this {thing}. I'd have carried home two if they'd let me."]),ctx.merged({"thing":thing})))
		else:
			parts.append(_fill("We brought home a {thing} — plain work, but it tells you how they live.",ctx.merged({"thing":thing})))
	return " ".join(PackedStringArray(parts))


static func _beat_defense(by:Dictionary,flags:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	var parts:Array[String]=[]
	if by.has("walls"):
		used["walls"]=true
		var walls:Dictionary=by.walls
		match String(walls.get("band","")):
			"none": parts.append(_pick(rng,["Walls? Not really. A few of our hunters could walk straight in.","Defenses? Hardly any. A small raiding party would get through.","No walls to speak of. Nobody has ever attacked them, I'd guess."]))
			"light": parts.append(_pick(rng,["They've made a start on defending themselves — a ditch, half dug.","Some defenses, half-finished. Enough to slow a thief, not a war."]))
			"walled": parts.append(_fill(_pick(rng,["The walls are real, {addr}. You'd want ladders, patience and a better reason than we've got.","Proper walls. Somebody there has thought hard about people like us."]),ctx))
			"heavy": parts.append(_fill(_pick(rng,["Heavily walled. I walked the whole way round looking for a soft spot and came back with sore feet and no soft spot.","Walls on walls, {addr}. Whoever built them was frightened of something, and built like it."]),ctx))
		var home_walls:=float(walls.get("home",-1.0))
		if home_walls>=0.0 and float(walls.get("value",0.0))>home_walls+0.2 and String(walls.get("band",""))in ["walled","heavy"]:
			parts.append(_pick(rng,["Better than ours, and that should keep somebody here up at night.","Ours look like a sheep pen beside them."]))
	if by.has("garrison"):
		used["garrison"]=true
		var g:Dictionary=by.garrison
		var line:=_pick(rng,["About {g} under arms, and they looked like they knew which end was which.","{G} under arms, give or take — and awake to their business.","I counted {g} carrying weapons. Maybe more indoors."])
		if float(g.get("value",0.0))<3.0: line=_pick(rng,["Barely anyone under arms that I saw.","Hardly a spear among them."])
		var hedge:=_hedge(g,persona,rng)
		parts.append(_hedged(hedge,_fill(line,ctx.merged({"g":String(g.get("shown","")),"G":_cap(String(g.get("shown","")))}))))
	if by.has("damage"):
		used["damage"]=true
		parts.append(_pick(rng,["Something's hit them lately — broken buildings, patched in a hurry.","They've been knocked about, and not long ago. The repairs are still raw."]) if String(by.damage.get("band",""))=="light" else _pick(rng,["They've been hit hard. Half the place is broken and nobody's had the heart to mend it.","Wrecked, {addr}. Somebody beat on that town and meant it."]))
	return _fill(" ".join(PackedStringArray(parts)),ctx)


static func _beat_armed(by:Dictionary,flags:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	used["armed"]=true
	var n:=int(by.armed.get("value",-1))
	var text:=_pick(rng,["On the road we crossed a column — about {n} under arms, moving. Where to, I couldn't tell you.","And on the way home: about {n} under arms, marching. We lay flat in the grass until they'd gone by."]) if n>0 else _pick(rng,["On the road we crossed armed strangers on the move. We kept our heads down and they kept walking."])
	return _fill(text,ctx.merged({"n":str(n)}))


static func _beat_food(by:Dictionary,flags:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	var parts:Array[String]=[]
	if by.has("food"):
		used["food"]=true
		match String(by.food.get("band","")):
			"starving": parts.append(_fill(_pick(rng,["They're hungry, {addr}. Their stores are near empty — you see it in the faces before you see it in the storehouses.","Food's nearly gone there. You notice people watching every mouthful, including ours.","Hungry. Properly hungry. I shared out our road bread and wished I'd brought more."]),ctx))
			"thin": parts.append(_pick(rng,["Their stores look thin — they'll get through, but they're counting.","Food's tight. Not starving, but nobody's taking seconds."]))
			"fed": parts.append(_pick(rng,["They eat well enough.","Nobody's hungry that I saw."]))
			"full": parts.append(_pick(rng,["Stores full to the rafters — they'll not go hungry this year, nor likely next.","Food? More than they know what to do with. I've never envied a storehouse before."]))
	if by.has("health"):
		used["health"]=true
		parts.append(_pick(rng,["And they're sickly. You don't need a healer to see it.","Coughs everywhere. We kept our distance and I'd advise the same."]) if String(by.health.get("band",""))=="sick" else _pick(rng,["Healthy-looking lot, too — clear eyes, straight backs.","And they look well. Better than we do, some of them."]))
	if by.has("old_age"):
		used["old_age"]=true
		parts.append(_pick(rng,["Hardly a grey head in the place. Folk don't get old there.","You don't see many old ones. That tells you something."]) if String(by.old_age.get("band",""))=="few" else _pick(rng,["Plenty of grey heads, which says something good about the place.","Lots of old folk, sat about telling each other how it used to be."]))
	if by.has("infants"):
		used["infants"]=true
		parts.append(_pick(rng,["And they bury too many babies. Folk there don't talk about it, which is how you know.","They lose a lot of little ones. That's the saddest thing I saw."]))
	return _fill(" ".join(PackedStringArray(parts)),ctx)


const RESOURCE_WANT:={
	"Flint":"stone that'll take an edge keen enough to shave a mouse",
	"Salt":"white salt-earth, enough to keep a winter's meat",
	"Medicinal Plants":"a stand of healing plants — our herb-folk would weep",
	"Fertile Soil":"black earth you could grow a fence post in",
	"Game":"game so thick it barely bothered to run from us",
	"Timber":"timber standing thick enough to lose a cow in",
	"Stone":"good workable stone lying right at the surface",
	"Clay":"clay that holds its shape when you squeeze it",
	"Fiber Plants":"cordage plants, if we're ever short of rope",
	"Copper Ore":"green-stained rock that means copper",
	"Tin Ore":"tin-bearing rock",
	"Iron Ore":"iron-red rock in the uplands",
	"Coal":"black stone that burns",
	"Gold Ore":"a trace of gold in the rock — and no, I didn't lick it",
	"Crude Oil":"ground that seeps black oil",
	"Phosphate Rock":"phosphate rock our growers would thank us for",
}


static func _beat_covet(facts:Array,by:Dictionary,flags:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	var resources:=_all(facts,"resource")
	var best:Dictionary=resources[0]
	for r in resources:
		if String(r.get("resource",""))!="Fiber Plants" and String(best.get("resource",""))=="Fiber Plants": best=r
	used["resource"]=true
	var want:=String(RESOURCE_WANT.get(String(best.get("resource","")),String(best.get("resource","")).to_lower()))
	var km:=int(best.get("km",0))
	var where:="about %d km out" % km if km>0 else "on the way"
	var text:=""
	match String(persona.temperament):
		"hungry": text=_pick(rng,["Now here's what I want, {addr}: {want}, {where}. Put a road to it and we'd never look back.","And I'll tell you what's worth the walk: {want}, {where}. I'd have it before anyone else thinks of it."])
		"wary": text=_pick(rng,["There's {want}, {where}. Worth having — if we can hold the road to it.","We marked {want}, {where}. Useful. Far, though, and far things are hard to keep."])
		_: text=_pick(rng,["And we found {want}, {where}. That's the bit I'd put in a song.","Best thing we found wasn't people: {want}, {where}.","There's {want}, {where}. I've dreamt about it twice since."])
	if resources.size()>1: text+=" "+_pick(rng,["That, and more besides — it's all on the chart.","There's more on the chart, but that's the prize."])
	return _fill(text,ctx.merged({"want":want,"where":where}))


static func _beat_people_met(by:Dictionary,flags:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	var parts:Array[String]=[]
	if by.has("nomads"):
		used["nomads"]=true
		parts.append(_pick(rng,["We crossed paths with wanderers — folk who carry their homes on their backs and seemed to pity us for not doing the same.","Met some wandering people out there. Friendly enough. Wouldn't come home with us, though."]) if not by.has("recruits") else "We met wandering folk out there, and some of them liked the sound of us.")
	if by.has("recruits"):
		used["recruits"]=true
		parts.append(_fill("{N} of them walked home with us, {addr}. Feed them and they'll stay.",ctx.merged({"N":_cap(_number_word(int(by.recruits.get("value",0))))})))
	if by.has("taught"):
		used["taught"]=true
		parts.append(_pick(rng,["And they showed us a trick or two — our scholars already have it in hand.","We learned something off them, too. I made the old ones learn it before I forgot it."]))
	return " ".join(PackedStringArray(parts))


static func _beat_signs(by:Dictionary,flags:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	## What the party saw of a people it did not meet: told as seen, not guessed.
	used["sign"]=true
	var text:=String(by.sign.get("text",""))
	if text=="": return ""
	return _fill(_pick(rng,["We are not alone out there, {addr}. {sign}","Listen, {addr}. {sign} We did not go closer; there were too few of us.","{sign} Someone lives there, {addr}, and they know that country better than we do."]),ctx.merged({"sign":text}))


static func _beat_rumor(by:Dictionary,flags:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	used["rumor"]=true
	var text:=String(by.rumor.get("text","")).split(". ")[0].trim_suffix(".")
	if text=="": return ""
	return _fill(_pick(rng,["And people talk. Here's what we heard, for what it's worth: {rumor}. Hearsay — I'd not act on it alone.","One more thing, only hearsay: {rumor}. Might be nothing. Might be someone."]),ctx.merged({"rumor":text}))


static func _beat_country(by:Dictionary,flags:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	used["terrain"]=true
	used["terrain_detail"]=true
	var terrain:Dictionary=by.terrain
	var parts:Array[String]=[]
	var rivers:=int(terrain.get("rivers",0))
	if rivers>0: parts.append("We forded running water %s and my boots still haven't forgiven me." % ("once" if rivers==1 else ("twice" if rivers==2 else "%s times" % _number_word(rivers))))
	if bool(terrain.get("high",false)): parts.append("Went up high enough the trees gave up before we did.")
	if bool(terrain.get("coast",false)): parts.append("Walked a good while with open water in sight — more of it than anyone needs.")
	return " ".join(PackedStringArray(parts))


static func _closing(by:Dictionary,flags:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	var worry:=""
	var temper:=String(persona.temperament)
	if flags.get("starving",false) and flags.get("big",false):
		worry=_pick(rng,["That many hungry people don't stay home forever. I'd watch that border.","There are a lot of them and they're hungry, {addr}. When their stores run out, they'll look over the hill — at us."])
	elif flags.get("armed",false) and flags.get("walled",false):
		worry=_pick(rng,["If they ever come our way, we'll need walls and spears of our own.","Walls and weapons both. They're expecting a fight with somebody."])
	elif flags.get("rich",false) and flags.get("open",false):
		worry=_pick(rng,["That's a lot of good things sitting behind nothing. Somebody will try to take it. I'd rather we got there first as friends.","Rich and unguarded. Other scouts will have seen that too."])
	elif flags.get("poor",false) and flags.get("beautiful",false):
		worry=_pick(rng,["I'd trade with them, {addr}. We've things they need, and they've a knack we haven't.","Send them good stone tools and they'd send back fine work, I reckon."])
	elif flags.get("hostile",false):
		worry=_pick(rng,["I'd keep the watch doubled on that side for a while.","They know where we came from now. They may come and look at us next."])
	elif flags.get("signs",false):
		worry=_pick(rng,["Send us back the way we came and we'll find whose fires those are.","Whoever they are, they'll have seen our smoke by now too."])
	elif flags.get("empty",false):
		worry=_pick(rng,["Good country for the taking, {addr}, if we've people to spare to take it.","Nobody's claimed it. Either nobody's found it yet, or something drove them off. I don't know which."])
	elif flags.get("hungry",false):
		worry=_pick(rng,["They could use food more than compliments, if you wanted a friend there.","A few baskets of food would win us more friends there than any talk."])
	elif flags.get("rich",false):
		worry=_pick(rng,["They've things worth having. I'd trade for them.","I'd know them better, {addr}. People working that hard will be strong in a few years."])
	else:
		worry=_pick(rng,["That's the lot of it. Make of it what you will.","I'd send us back in a season and see what's changed."])
	if temper=="blunt" and rng.randf()<0.5: worry=worry.split(".")[0]+"."
	elif bool(persona.nervous) and rng.randf()<0.6: worry+=" "+_pick(rng,["Forgive me for saying so.","I'd not like to be the one who didn't say it."])
	var seen:Dictionary=by.get("seen",{})
	var age:=int(seen.get("value",0))
	var dating:=""
	if age>=3 and rng.randf()<0.85:
		dating=" "+_pick(rng,["Mind — that's how it stood {age} days ago. Things move.","That's {age} days old now, remember; the road home is long.","All that was {age} days back. Could be different by now."]).format({"age":str(age)})
	elif String(ctx.source)=="scouts" and int(seen.get("observation_days",1))>=3 and by.has("population"):
		dating=" "+"We watched for {d} days, so I'll stand by the counts.".format({"d":str(int(seen.observation_days))})
	return _fill(worry,ctx)+dating


static func _filler(by:Dictionary,ctx:Dictionary,persona:Dictionary,rng:RandomNumberGenerator,used:Dictionary)->String:
	if by.has("terrain") and not used.has("terrain"):
		used["terrain"]=true
		var country:=_country_phrase(by.terrain)
		if country!="": return "The road there was {country}. Long, but honest.".format({"country":country})
	if by.has("contact") and not used.has("contact"):
		used["contact"]=true
		return _fill("And this was a first meeting, {addr} — they'd never set eyes on our kind before.",ctx)
	if by.has("roads") and not used.has("roads"):
		used["roads"]=true
		var band:=String(by.roads.get("band",""))
		return {"paths":"Their roads are footpaths. Getting anything heavy in or out would be misery.","tracks":"They've worn tracks between places, enough to haul along if you're patient.","roads":"Good roads, too — they move things about easily, which cuts both ways."}.get(band,"")
	return ""


static func _aside(by:Dictionary,flags:Dictionary,persona:Dictionary,rng:RandomNumberGenerator)->String:
	if rng.randf()>0.45: return ""
	match String(persona.temperament):
		"wry": return _pick(rng,["(My feet will never forgive you for this one.)","(And no, before anyone asks, we never once went astray. We were surveying.)"])
		"hungry": return "(Whoever gets there first gets the best of it. I'm only saying.)"
		"wonder": return "(I'd go back tomorrow, if anyone's asking.)"
		"wary": return "(I slept with my boots on the whole way. Every night.)"
		"blunt": return "(That's the truth of it. Somebody write it down before the Steward tidies it.)"
	return ""


static func _country_phrase(terrain:Dictionary)->String:
	var legs:Array=terrain.get("legs",[])
	var days:Array=terrain.get("leg_days",[])
	if legs.is_empty(): return ""
	var parts:Array[String]=[]
	for i in mini(3,legs.size()):
		var n:=int(days[i]) if i<days.size() else 0
		parts.append("%s day%s of %s" % [_number_word(n),"" if n==1 else "s",String(legs[i])] if n>0 else String(legs[i]))
	if parts.size()==1: return parts[0]
	return ", ".join(PackedStringArray(parts.slice(0,parts.size()-1)))+" and "+parts[-1]


static func _number_word(n:int)->String:
	if n>=0 and n<NUMBER_WORDS.size(): return String(NUMBER_WORDS[n])
	return str(n)


static func _times_word(ratio:float)->String:
	var r:=roundi(ratio)
	var lead:="nearly " if ratio<float(r)-0.2 else ("better than " if ratio>float(r)+0.2 else "")
	var bare:=_times_bare(r)
	return bare if bare in ["about","more times than I've fingers"] else lead+bare


static func _times_bare(r:int)->String:
	if r>=2 and r<TIMES_WORDS.size(): return String(TIMES_WORDS[r])
	if r>=TIMES_WORDS.size() and r<NUMBER_WORDS.size(): return "%s times" % String(NUMBER_WORDS[r])
	if r>=NUMBER_WORDS.size(): return "more times than I've fingers"
	return "about"

# ---------------------------------------------------------------------------
# AI prompt context
# ---------------------------------------------------------------------------

static func voice_brief(audience:Dictionary)->Dictionary:
	var report:Dictionary=audience.get("report",{}) if audience.get("report",{}) is Dictionary else {}
	var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker",{}) is Dictionary else {}
	var persona:=_persona(speaker)
	var facts:Array=[]
	for fact_variant in report.get("facts",[]):
		if not fact_variant is Dictionary: continue
		var confidence:=float(fact_variant.get("confidence",1.0))
		facts.append({"topic":String(fact_variant.get("key","")),"fact":String(fact_variant.get("text","")),"certainty":"sure" if confidence>=0.75 else ("fairly sure" if confidence>=0.5 else "unsure — say so")})
	var voice:=_voice_script()
	var persona_line:=""
	if voice!=null and not (persona.voice_persona as Dictionary).is_empty():
		persona_line=String(voice.call("brief",persona.voice_persona))
	var seen:Dictionary=_by_key(report.get("facts",[])).get("seen",{})
	var home:Dictionary=report.get("home",{}) if report.get("home",{}) is Dictionary else {}
	return {
		"role":"chief_scout_debrief","speaker":String(persona.name),"title":String(persona.title),"temperament":String(persona.temperament),
		"persona":persona_line,"address":String(persona.address),"subject":String(report.get("subject_name","")),"place":String(report.get("place","")),
		"source":String(report.get("source","scouts")),"days_since_observed":int(seen.get("value",0)),"facts":facts,
		"home_for_comparison":{"population":roundi(float(home.get("population",0))),"food_days":roundi(float(home.get("food_days",0)))} if not home.is_empty() else {},
		"flags":(report.get("flags",{}) as Dictionary).duplicate() if report.get("flags",{}) is Dictionary else {},
		"instructions":"Speak as the ruler's Chief Scout reporting in person after the party came home. Plain spoken, concrete and sensory: what they saw, heard and smelled, who they met, what surprised them, what worries them, what they covet. Compare with home in homely terms. Be opinionated and allowed to be funny. Say uncertainty out loud in natural words ('I'd not swear to it, but…') for facts marked unsure. Use ONLY the listed facts: never invent numbers, names, buildings, animals, battles, agreements or materials that are not listed; figures of speech are fine when clearly figures of speech. 3–6 short spoken lines, no lists, no game or system words.",
	}

# ---------------------------------------------------------------------------
# Audience record and return hook
# ---------------------------------------------------------------------------

static func speaker_for(event:Dictionary)->Dictionary:
	var holder:Dictionary=GovernmentPeopleSystem.officeholder("ChiefScout")
	if not holder.is_empty():
		return {"name":String(holder.get("name","")),"title":String(holder.get("office_title","Chief Scout")),"person_id":int(holder.get("person_id",0)),"role":"official"}
	return fallback_speaker(event)


static func fallback_speaker(event:Dictionary)->Dictionary:
	# Vacant office: the party's own lead speaks for it.
	var leader:=String(event.get("party_leader",""))
	if leader!="": return {"name":leader,"title":"Scout Leader","person_id":0,"role":"official"}
	var source:=_source(event)
	var seed_value:=int(WorldSimulation.state.world_seed) if WorldSimulation.state!=null else 0
	var names:Array[String]=["Oda","Brannoc","Tessaly","Ivar","Mirren","Kasso","Ulla","Dunmore","Sefa","Harl","Nimue","Corran"]
	var pick:=names[posmod(hash("%d|%s|%s" % [seed_value,str(event.get("mission_id",0)),str(event.get("day",0))]),names.size())]
	return {"name":pick,"title":"Envoy of the returning party" if source=="envoys" else "Lead Scout","person_id":0,"role":"official"}


static func report_record(event:Dictionary,found:Dictionary={})->Dictionary:
	var f:=found if not found.is_empty() else findings(event)
	var speaker:=speaker_for(event)
	var chip_facts:Array=[]
	for fact in f.facts: chip_facts.append(fact)
	var report:={"facts":chip_facts,"subject_civ_id":String(f.subject_civ_id),"subject_name":String(f.subject_name),"source":String(f.source),
		"observed_day":int(f.observed_day),"place":String(f.place),"civ_name":String(f.civ_name),"flags":(f.flags as Dictionary).duplicate(),"home":(f.home as Dictionary).duplicate()}
	var preview:={"id":"report:%s:%d" % [String(f.subject_name),int(f.day)],"arrived_day":_today(),"speaker":speaker,"report":report}
	return {"kind":"report","origin":"court","civ_id":String(f.subject_civ_id),"civ_name":String(f.civ_name),"speaker":speaker,"report":report,"lines":debrief_lines(preview)}


static func report_returned(event:Dictionary,source:String="")->Dictionary:
	## Called when a scout party, envoy delegation or expedition comes home.
	## Harmless when the Audience Hall is absent or the report is routine.
	if WorldSimulation.actor_id!="player": return {}
	# Standing city watches keep reporting quietly unless something changed.
	if event.has("mission_id") and not ScoutArchive.should_notify(event): return {}
	var enriched:=event.duplicate(true)
	if source!="": enriched["source"]=source
	_enrich(enriched)
	var found:=findings(enriched)
	if not bool(found.significant): return {}
	var hall:=_hall()
	if hall==null: return {}
	# One report per subject waits at a time; a newer return replaces nothing.
	# The Chief Scout never comes uninvited: the report waits as a matter until
	# the ruler summons them. Returns that matter ({} when nothing new).
	var pending:Array=[]
	var waiting:Variant=hall.call("waiting")
	if waiting is Array: pending.append_array(waiting)
	var held:Variant=hall.call("matters","")
	if held is Array:
		for matter in held:
			if matter is Dictionary and matter.get("audience") is Dictionary: pending.append(matter.audience)
	for audience in pending:
		if audience is Dictionary and String(audience.get("kind",""))=="report" and String((audience.get("report",{}) as Dictionary).get("subject_name",""))==String(found.subject_name):
			return {}
	var record:=report_record(enriched,found)
	var stored:Variant=hall.call("enqueue",record)
	if stored is Dictionary and not (stored as Dictionary).is_empty(): return stored
	held=hall.call("matters","")
	if held is Array:
		for matter in held:
			if matter is Dictionary and String(matter.get("kind",""))=="report" and String(((matter.get("audience",{}) as Dictionary).get("report",{}) as Dictionary).get("subject_name",""))==String(found.subject_name): return matter
	return {}


static func _hall()->Script:
	if not ResourceLoader.exists(HALL_PATH): return null
	var script:=load(HALL_PATH) as Script
	if script==null: return null
	var has_enqueue:=false
	var has_waiting:=false
	for method in script.get_script_method_list():
		var name:=String(method.get("name",""))
		if name=="enqueue": has_enqueue=true
		elif name=="waiting": has_waiting=true
	return script if has_enqueue and has_waiting else null


static func _enrich(event:Dictionary)->void:
	## Adds what the returning party can compare against: our own settlement,
	## the look of any foreign city they physically saw, and known standing.
	var state=WorldSimulation.state
	if state!=null and not event.has("home"):
		var home:={"population":float(state.population_total),"makers":float(state.simulation_metrics.get("material_capacity",0.12)),"food_days":float(state.simulation_metrics.get("food_days",30.0))}
		if WorldSimulation.military!=null:
			home["walls"]=clampf(float(WorldSimulation.military.settlement_defense.get("stage",0))/5.0,0.0,1.0)
			home["troops"]=float(WorldSimulation.military.home_army.get("troops",0))
		event["home"]=home
	var city:=_subject_city(event)
	var civ_id:=String(city.get("civ_id","")) if not city.is_empty() else String(event.get("civ_id",""))
	if civ_id=="" or civ_id=="player": return
	var civ:={}
	for candidate in CivilizationSystem.civilizations:
		if String(candidate.get("id",""))==civ_id: civ=candidate; break
	if civ.is_empty(): return
	if not event.has("civ_name"): event["civ_name"]=String(civ.get("name",""))
	if not event.has("architecture") and (float(city.get("quality",0.0))>=0.35 or _source(event)=="envoys"):
		event["architecture"]=ValuesModel.architecture_snapshot(civ.get("societal_values",{}))
	if not event.has("relation") and int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))>=2:
		var relation:Dictionary=civ.player_relation
		event["relation"]={"opinion":float(relation.get("opinion",0.0)),"border_tension":float(relation.get("border_tension",0.0)),"at_war":bool(relation.get("at_war",false))}


static func _civ_name(civ_id:String)->String:
	for civ in CivilizationSystem.civilizations:
		if String(civ.get("id",""))==civ_id: return String(civ.get("name",""))
	return ""


static func _today()->int:
	return int(WorldSimulation.state.elapsed_days) if WorldSimulation.state!=null else 0
