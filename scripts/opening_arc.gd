extends RefCounted
## The Opening Arc: the first years of a new people, told as they happen.
##
## A daily watch over the real simulation during the first decade (the first
## real hour at the default 1 day/s). It never invents an event. It notices
## what the world actually did — a party came home with signs of strangers,
## the first winter closed in, a child was born at a court member's hearth,
## the first discovery was made, a people was met — and marks it as a beat:
##
##   * a "moment": pushed to GameState.simulation_events with kind
##     "opening_beat" and tier "moment", told in the Chronicle
##     (Chronicle.record_beat, merged with its own firsts) and emitted on
##     PeopleDirection.opening_beat(beat);
##   * sometimes also a waiting court matter (the Hearth Chief's first-winter
##     petition). Matters wait for the ruler, as all court business does.
##
## Named people inside a beat are representatives of real aggregate outcomes:
## the child is one of that day's real births, the family at risk stands for
## the cohorts the real winter threatens, and its fate in spring follows the
## real deaths of that winter and the ruler's answer.
##
## State lives in PeopleDirection.opening_arc (saved by reflection); a save
## without it starts an empty arc and simply records beats from then on.

const Hall:=preload("res://scripts/audience_hall.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const WINDOW_DAYS:=3650
const BEATS_MAX:=40
const CHILD_GAP_DAYS:=270
## The same kind of news about the same people is told at most once a year.
const NEWS_GAP_DAYS:=365
const PARENT_GAP_DAYS:=1095
const HEADCOUNTS:=[130,150,175,200,250,300,400,500]
const WINTER_DEEP:=-0.5
const SPRING:=0.0

## Every beat kind, in the order a new people usually meets them.
const KINDS:=["first_signs","first_winter","named_child","spring_after","first_contact","first_discovery"]

static func state()->Dictionary:
	var arc:Dictionary=PeopleDirection.opening_arc
	# An arc from another world (a load over a running session) never carries over.
	if int(arc.get("seed",GameState.world_seed))!=int(GameState.world_seed): arc={}
	# Nor does an arc recorded ahead of the loaded day, or for another founding.
	elif int(arc.get("last_day",-1))>int(GameState.elapsed_days)+1: arc={}
	elif arc.has("founded_day") and GameState.settlement_site_committed and int(arc.founded_day)!=maxi(0,int(GameState.settlement_founded_day)): arc={}
	arc["seed"]=int(GameState.world_seed)
	if not arc.get("done") is Dictionary: arc["done"]={}
	if not arc.get("beats") is Array: arc["beats"]=[]
	if not arc.get("children") is Array: arc["children"]=[]
	if not arc.get("winter") is Dictionary: arc["winter"]={}
	for key in ["signed","met","counted","watch","told"]:
		if not arc.get(key) is Dictionary: arc[key]={}
	if not arc.has("last_day"): arc["last_day"]=-1
	PeopleDirection.opening_arc=arc
	return arc

static func beats()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for beat in state().beats:
		if beat is Dictionary: result.append(beat)
	return result

static func done(kind:String)->bool:
	return (state().done as Dictionary).has(kind)

## Once per game day, after the Audience Hall. Returns the beats emitted today.
static func daily(day:int,terrain:Node=null)->Array[Dictionary]:
	var emitted:Array[Dictionary]=[]
	if WorldSimulation.actor_id!="player" or not GameState.settlement_site_committed: return emitted
	var arc:=state()
	if day<=int(arc.last_day): return emitted
	arc.last_day=day
	if not arc.has("founded_day"):
		arc["founded_day"]=maxi(0,int(GameState.settlement_founded_day))
		arc["founding_known"]=GameState.known_discoveries.size()
		arc["founding_population"]=int(GameState.population_total)
		# Numbers already passed at founding are not news.
		for mark:int in HEADCOUNTS:
			if int(GameState.population_total)>=mark: (arc.counted as Dictionary)[str(mark)]=-1
	var age:=day-int(arc.founded_day)
	if age>WINDOW_DAYS and done("spring_after") or age>WINDOW_DAYS*2: return emitted
	for beat in [_signs(day),_contact(day),_winter(day),_spring(day),_child(day),_first_year(day),_discovery(day,terrain),_headcount(day),_neighbours(day)]:
		if not (beat as Dictionary).is_empty(): emitted.append(beat)
	return emitted

# ---------------------------------------------------------------------------
# Beats
# ---------------------------------------------------------------------------

static func _signs(day:int)->Dictionary:
	## Signs of each people not yet met, the first time a party brings them home.
	var signed:Dictionary=state().signed
	for card in preload("res://scripts/neighbor_signs.gd").open_signs(CivilizationSystem):
		var civ_id:=String(card.get("civ_id",""))
		if signed.has(civ_id): continue
		signed[civ_id]=day
		var smoke:=String(card.get("description","")).to_lower().contains("smoke")
		var kind:="first_signs" if not done("first_signs") else "signs_%s" % civ_id
		var title:=("Smoke on the horizon" if smoke else "Tracks of strangers") if kind=="first_signs" else ("More smoke, another people" if smoke else "Other tracks, another people")
		return _emit(kind,day,title,String(card.get("description","")),{"bearing":String(card.get("bearing","")),"walk_days":int(card.get("walk_days",0))})
	return {}

static func _contact(day:int)->Dictionary:
	## Every people met in the first years is a turning point, the first most of all.
	var met:Dictionary=state().met
	for civ in CivilizationSystem.civilizations:
		var relation:Dictionary=civ.get("player_relation",{})
		var civ_id:=String(civ.get("id",""))
		if int(relation.get("contact_level",0))<2 or met.has(civ_id): continue
		met[civ_id]=day
		var name:=String(civ.get("name","strangers"))
		var how:="Our scouts met them on the road." if String(relation.get("contact_source",""))=="returned_scout_report" else "They found us before we found them."
		if not done("first_contact"):
			return _emit("first_contact",day,"Strangers at the fire","People of %s, and we of them, for the first time. %s Whatever they are to us — kin, rival or prey — they are real now." % [name,how],{"civ_id":civ_id})
		var count:=met.size()
		return _emit("met_%s" % civ_id,day,"Another people: %s" % name,"%s We know %s peoples now besides ourselves, and each has seen our fires." % [how,_count_word(count)],{"civ_id":civ_id,"peoples":count})
	return {}

static func _season(day:int)->float:
	var profile:=PlanetEnvironment.profile_at(CivilizationSystem.player_world_origin)
	return PlanetEnvironment.season_wave(profile,float(day))

static func _winter(day:int)->Dictionary:
	if done("first_winter"): return {}
	var arc:=state()
	if day-int(arc.founded_day)<10 or _season(day)>WINTER_DEEP: return {}
	var chief:=_chief()
	var profile:=PlanetEnvironment.profile_at(CivilizationSystem.player_world_origin)
	var cold:=PlanetEnvironment.ambient_temperature_c(profile,float(day))
	var c:=Hall.conditions()
	# The real pressure of this winter decides what the Hearth Chief asks for.
	var topic:="health"; var decree:="Support families and care for children"; var pressure:=""
	if float(c.housing_ratio)<1.0:
		topic="housing"; decree="Build shelters and repair housing"
		pressure="%d of us still sleep without proper shelter" % maxi(1,roundi(float(c.population)-float(GameState.housing_capacity)))
	elif float(c.food_days)<45.0 or float(c.food_intake)<0.97:
		topic="food"; decree="Send gatherers to find food"
		pressure="the stores would last about %d days" % maxi(0,roundi(float(c.food_days)))
	elif float(c.health)<0.62:
		topic="health"; decree="Organize healers to care for the sick"
		pressure="coughs are going round the shelters"
	else:
		pressure="the stores are good, %d days, but cold takes the old and the newborn first" % roundi(float(c.food_days))
	# Where winter never bites, the hard season is the lean one.
	var lean:=cold>=14.0
	var season:="lean season" if lean else "winter"
	var weather:="The lean months have come, and the country gives less every day" if lean else ("Water skins freeze at night now" if cold<=0.5 else ("The nights are bitter now" if cold<6.0 else "The rains have turned cold"))
	if lean and pressure.contains("cold takes"): pressure="the stores are good, %d days, but a hard season takes the old and the newborn first" % roundi(float(c.food_days))
	var family:=_family_name(day)
	var summary:="%s. This is our first %s in this place, and %s. The %s hearth worries me most: a grandmother who cannot walk far, and a child not yet weaned." % [weather,season,pressure,family]
	arc["winter"]={"day":day,"family":family,"topic":topic,"decree":decree,"deaths_before":int(GameState.lifetime_deaths),"chief_id":int(chief.get("person_id",0)),"cold_c":cold,"lean":lean}
	var matter:={}
	if not chief.is_empty():
		var built:={"topic":topic,"summary":summary,"decree":decree,"ask":"opening:first_winter","situation_type":"crisis_petition"}
		var audience:Dictionary=Hall._court_audience(chief,built,{"type":"opening","day":day,"crisis":true,"data":{"text":"the first winter in this place"}},day)
		matter=Hall._file_matter(audience,[])
		(arc.winter as Dictionary)["matter_id"]=String(matter.get("id",""))
	var who:=String(chief.get("name","The Hearth Chief"))
	return _emit("first_winter",day,"The first %s" % season,"%s waits to be heard about the %s: %s" % [who,season,summary],{"family":family,"topic":topic,"matter_id":String(matter.get("id","")),"person_id":int(chief.get("person_id",0)),"decision":not matter.is_empty()})

static func _spring(day:int)->Dictionary:
	if done("spring_after") or not done("first_winter"): return {}
	var winter:Dictionary=state().winter
	if day-int(winter.get("day",day))<60 or _season(day)<SPRING: return {}
	var deaths:=maxi(0,int(GameState.lifetime_deaths)-int(winter.get("deaths_before",GameState.lifetime_deaths)))
	var answer:=_winter_answer()
	var family:=String(winter.get("family","the"))
	var helped:=answer=="decree"
	var lean:=bool(winter.get("lean",false))
	var thaw:="The good season has come back." if lean else "The thaw has come."
	var season:="lean season" if lean else "winter"
	var text:=""
	var outcome:=""
	if deaths==0:
		outcome="all_lived"
		text="%s No one was buried this %s. The %s grandmother sat in the sun today with the child on her knee." % [thaw,season,family]
	elif helped:
		outcome="family_lived"
		text="%s %s did not live to see it, but the %s hearth came through whole; they say it was your word that kept them." % [thaw,_people_count(deaths),family]
	else:
		outcome="grandmother_died"
		text=("%s We buried the %s grandmother this %s; she was the only one we lost. The child lived." % [thaw,family,season]) if deaths==1 else ("%s %s were buried this %s, and the %s grandmother was one of them. The child lived." % [thaw,_people_count(deaths),season,family])
	var chief_id:=int(winter.get("chief_id",0))
	if chief_id>0 and not GovernmentPeopleSystem.person_snapshot(chief_id).is_empty():
		GovernmentPeopleSystem.record_person_memory(chief_id,"Our first %s here: %s" % [season,text],"opening",0.7,{"emotion":"grief" if outcome=="grandmother_died" else "relief"})
	(state().winter as Dictionary)["outcome"]=outcome
	return _emit("spring_after",day,"The good season returns" if lean else "The first thaw",text,{"family":family,"deaths":deaths,"answer":answer,"outcome":outcome})

static func _child(day:int)->Dictionary:
	var arc:=state()
	if day-int(arc.founded_day)<21: return {}
	var children:Array=arc.children
	if not children.is_empty() and day-int((children[-1] as Dictionary).get("day",0))<CHILD_GAP_DAYS: return {}
	if _births_today(day)<=0: return {}
	var parents:=[]
	var had:Dictionary={}
	for child in children:
		if day-int((child as Dictionary).get("day",0))<PARENT_GAP_DAYS: had[int((child as Dictionary).get("parent_id",0))]=true
	for person in Hall._officials():
		var age:=GovernmentPeopleSystem.age_years(person)
		if age>=18 and age<=44 and not had.has(int(person.person_id)): parents.append(person)
	if parents.is_empty(): return {}
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d|opening_child|%d" % [int(GameState.world_seed),day])
	var parent:Dictionary=parents[rng.randi_range(0,parents.size()-1)]
	# A child's name is their own: never a living official's or another named child's.
	var taken:Dictionary={}
	for person in GovernmentPeopleSystem.living_people(): taken[String(person.get("name","")).get_slice(" ",0)]=true
	for child in children: taken[String((child as Dictionary).get("name","")).get_slice(" ",0)]=true
	var pool:Array=GovernmentPeopleSystem.GIVEN_NAMES
	var start:=rng.randi_range(0,pool.size()-1)
	var given:=String(pool[start])
	for offset in pool.size():
		if not taken.has(String(pool[(start+offset)%pool.size()])): given=String(pool[(start+offset)%pool.size()]); break
	var parent_name:=String(parent.get("name",""))
	var family:=parent_name.get_slice(" ",1) if parent_name.get_slice_count(" ")>1 else ""
	var child_name:=given+(" "+family if family!="" else "")
	var daughter:=rng.randf()<0.5
	var record:={"day":day,"name":child_name,"parent_id":int(parent.person_id),"parent_name":parent_name,"daughter":daughter}
	children.append(record)
	GovernmentPeopleSystem.record_person_memory(int(parent.person_id),"My %s %s was born." % ["daughter" if daughter else "son",given],"family",0.8,{"emotion":"joy","child_name":child_name})
	var title:=String(parent.get("office_title","of the court"))
	var kind:="named_child" if not done("named_child") else "named_child_%d" % children.size()
	return _emit(kind,day,"A child at the %s's hearth" % title.to_lower(),"%s, %s, has a %s: %s. The whole camp came to see." % [parent_name,title,"daughter" if daughter else "son",child_name],{"parent_id":int(parent.person_id),"child_name":child_name})

static func _first_year(day:int)->Dictionary:
	## A named child's first year ends as that year really went for infants
	## here: the real infant mortality decides, and a loss is only told when
	## the settlement really buried someone that year.
	for child in state().children:
		var record:Dictionary=child
		if bool(record.get("year_told",false)) or day-int(record.get("day",day))<365: continue
		record["year_told"]=true
		var imr:=float(preload("res://scripts/civilization_indicators.gd").infant_mortality_per_1000())/1000.0
		var roll:=float(posmod(hash("%d|first_year|%s" % [int(GameState.world_seed),String(record.name)]),10000))/10000.0
		var buried:=GameState.rolling_vital_balance(365)
		var died:=roll<imr and float(buried.get("deaths",0.0))>=1.0
		record["lived"]=not died
		var given:=String(record.name).get_slice(" ",0)
		var odds:=maxi(2,roundi(1.0/maxf(0.01,imr)))
		if died:
			return _emit("child_lost_%s" % given.to_lower(),day,"%s's child" % String(record.parent_name).get_slice(" ",0),"%s, born at %s's hearth last year, did not live to see a second spring. One in every %d of our children dies so." % [String(record.name),String(record.parent_name),odds],{"child_name":String(record.name),"parent_id":int(record.parent_id),"lived":false})
		return _emit("child_year_%s" % given.to_lower(),day,"%s is walking" % given,"%s, %s's child, is a year old and walking, into the fire-stones and out again. %s has outlived the year that takes one in every %d of our children." % [String(record.name),String(record.parent_name),given,odds],{"child_name":String(record.name),"parent_id":int(record.parent_id),"lived":true})
	return {}

static func _headcount(day:int)->Dictionary:
	## The people count themselves at the fire when they pass a new number.
	var arc:=state()
	var counted:Dictionary=arc.counted
	var population:=int(GameState.population_total)
	for mark:int in HEADCOUNTS:
		if population<mark or counted.has(str(mark)): continue
		counted[str(mark)]=day
		var chief:=String(_chief().get("name","The Hearth Chief"))
		return _emit("headcount_%d" % mark,day,"%d of us" % mark,"%s counted us at the fire tonight, twice to be sure: %d, where we came here %d." % [chief,population,int(arc.get("founding_population",120))],{"population":population})
	return {}

static func _neighbours(day:int)->Dictionary:
	## What the peoples we know are really doing to us and to each other: the
	## frontier tightening, a swing in their regard, war and peace, hunger among
	## them, wars between them. Each change is read from the relation records.
	var watch:Dictionary=state().watch
	var told:Dictionary=state().told
	var fresh:=func(key:String)->bool:
		if day-int(told.get(key,-99999))<NEWS_GAP_DAYS: return false
		told[key]=day
		return true
	for civ in CivilizationSystem.civilizations:
		var relation:Dictionary=civ.get("player_relation",{})
		if int(relation.get("contact_level",0))<2 or not bool(civ.get("alive",true)): continue
		var id:=String(civ.get("id",""))
		var name:=String(civ.get("name",id))
		var now:={"t":Hall._tension_band(float(relation.get("border_tension",0.0))),"o":float(relation.get("opinion",0.0)),"w":bool(relation.get("at_war",false)),"h":Hall._hungry(civ),"x":Hall._third_wars(civ)}
		if not watch.has(id):
			watch[id]=now
			continue
		var before:Dictionary=watch[id]
		watch[id]=now.duplicate(true)
		if bool(now.w)!=bool(before.get("w",false)):
			return _emit("war_%s_%d" % [id,day] if bool(now.w) else "peace_%s_%d" % [id,day],day,("War with %s" if bool(now.w) else "Peace with %s") % name,
				("It has come to blood with %s. The generals will want to be heard." % name) if bool(now.w) else ("The fighting with %s has stopped. The dead are counted on both sides." % name),{"civ_id":id})
		if int(now.t)>int(before.get("t",0)) and fresh.call("tension:"+id):
			return _emit("tension_%s_%d" % [id,int(now.t)],day,"The %s border" % name,"%s hunters are ranging closer than they used to, and ours have started carrying spears to the far springs. The frontier with %s has grown %s." % [name,name,"dangerous" if int(now.t)>=2 else "tense"],{"civ_id":id})
		var swing:=float(now.o)-float(before.get("o",now.o))
		if absf(swing)>=0.15 and fresh.call(("warm:" if swing>0.0 else "cool:")+id):
			return _emit("regard_%s_%d" % [id,day],day,("%s warms to us" if swing>0.0 else "%s cools toward us") % name,
				("The people of %s speak of us kindly now; their children come to our fires to trade and stare." % name) if swing>0.0 else ("The people of %s speak of us coldly now. Their hunters no longer share a fire with ours." % name),{"civ_id":id,"swing":swing})
		(watch[id] as Dictionary)["o"]=float(before.get("o",now.o)) if absf(swing)<0.15 else float(now.o)
		if bool(now.h) and not bool(before.get("h",false)) and fresh.call("hunger:"+id):
			return _emit("hunger_%s_%d" % [id,day],day,"Hunger in %s" % name,"%s's stores are failing. Their people are thin, and some have been seen gathering on our side of the hills." % name,{"civ_id":id})
		for enemy in now.x:
			if String(enemy) in (before.get("x",[]) as Array): continue
			var index:=Hall._civ_index(String(enemy))
			var enemy_name:=String(CivilizationSystem.civilizations[index].get("name",enemy)) if index>=0 else "their neighbours"
			return _emit("strife_%s_%s" % [id,String(enemy)],day,"%s and %s at war" % [name,enemy_name],"Word has come that %s and %s are killing each other. Whoever wins will be nearer to us, and stronger." % [name,enemy_name],{"civ_id":id,"enemy":String(enemy)})
	return {}

static func _discovery(day:int,terrain:Node)->Dictionary:
	if done("first_discovery"): return {}
	var arc:=state()
	var known:Array=GameState.known_discoveries
	if known.size()<=int(arc.get("founding_known",known.size())): return {}
	var id:=String(known[-1])
	var event:=DiscoverySystem.player_facing_discovery_event({"id":id,"day":day})
	var name:=String(event.get("name",id.replace("_"," ").capitalize()))
	var finder:Dictionary={}
	for person in Hall._officials():
		if String(person.get("office_key",""))=="Scholar": finder=person
	if finder.is_empty(): finder=_chief()
	var who:=String(finder.get("name","One of our people"))
	var scene:="At the evening fire %s showed everyone what they had worked out: %s. People passed it from hand to hand until the fire burned low." % [who,name.to_lower()]
	event["scene"]=scene
	# When the Chronicle already tells this discovery as a moment, its card
	# carries the scene (Chronicle.record_beat); a popup would tell it twice.
	if not Chronicle.discovery_is_moment(id) and is_instance_valid(terrain) and "hud" in terrain and is_instance_valid(terrain.hud):
		preload("res://scripts/hud/discovery_popup.gd").announce(terrain,terrain.hud,[event])
	return _emit("first_discovery",day,"The first discovery: %s" % name,scene,{"discovery_id":id,"person_id":int(finder.get("person_id",0))})

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

static func _emit(kind:String,day:int,title:String,text:String,refs:Dictionary)->Dictionary:
	var arc:=state()
	(arc.done as Dictionary)[kind]=day
	var beat:={"id":"opening_%s_%d" % [kind,day],"kind":kind,"tier":"moment","day":day,"title":title,"text":text,"refs":refs}
	var list:Array=arc.beats
	list.append(beat)
	while list.size()>BEATS_MAX: list.pop_front()
	# The Chronicle tells the beat itself (once, merged with its own firsts),
	# so its daily ledger scan skips this line.
	GameState.simulation_events.push_front({"id":String(beat.id),"day":day,"title":title,"description":text,"domain":"society","severity":"major","kind":"opening_beat","tier":"moment","beat":kind,"chronicle":Chronicle.active()})
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
	Chronicle.record_beat(beat)
	PeopleDirection.opening_beat.emit(beat.duplicate(true))
	return beat

static func _chief()->Dictionary:
	var officials:=Hall._officials()
	for person in officials:
		if String(person.get("office_key",""))=="Steward": return person
	return officials[0] if not officials.is_empty() else {}

static func _family_name(day:int)->String:
	var taken:Dictionary={}
	for person in Hall._officials(): taken[String(person.get("name","")).get_slice(" ",1)]=true
	var names:Array=GovernmentPeopleSystem.FAMILY_NAMES
	var start:=posmod(hash("%d|winter_family|%d" % [int(GameState.world_seed),day]),names.size())
	for offset in names.size():
		var candidate:=String(names[(start+offset)%names.size()])
		if not taken.has(candidate): return candidate
	return String(names[start])

static func _births_today(day:int)->int:
	var history:Array=GameState.vital_statistics_history
	for index in range(history.size()-1,maxi(-1,history.size()-8),-1):
		var row:Dictionary=history[index]
		if int(row.get("day",-1))==day: return int(row.get("births",0))
		if int(row.get("day",-1))<day: break
	return 0

static func _winter_answer()->String:
	## How the ruler answered the first-winter petition: "decree", "promise",
	## "dismiss", or "" if the Hearth Chief was never summoned.
	for entry in Hall.ledger():
		if String(entry.get("ask",""))=="opening:first_winter": return String(entry.get("option",""))
	return ""

static func _people_count(value:int)->String:
	return "One of us" if value==1 else "%s of us" % _count_word(value).capitalize()

static func _count_word(value:int)->String:
	var words:=["none","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"]
	return words[value] if value>=0 and value<words.size() else str(value)
