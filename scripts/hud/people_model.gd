extends RefCounted
## THE PEOPLE, as the god looks down on them: what the People screen shows,
## read from live state. Plain data only; hud/people_screen.gd draws it.
##
##   scene    the season and weather in words, one headline sentence, and one
##            voice from the fires (a named person's line about their life).
##   faces    named people: the newborn of the season, the oldest living, the
##            sick, the best hunter and maker, one with a grievance, kin of the
##            court, and the Remembered. The living are court-known persons
##            (court_persons.gd), so the court can summon the same person.
##   vitals   fed, stores, water, shelter, lifespan, spirit: a fill, a trend
##            over the last season and a plain cause line.
##   labor    what the productive people are doing today, by task.
##   story    the season's Chronicle entries that concern the people.
##
## Words are plain and era-grounded (era_words.gd): no proverbs, no statistics
## before the people can gather them.

const EraWords:=preload("res://scripts/hud/era_words.gd")
const Persons:=preload("res://scripts/court_persons.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const Lives:=preload("res://scripts/court_lives.gd")
const HearthCount:=preload("res://scripts/hearth_count.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Aims:=preload("res://scripts/legacy_aims.gd")

const SEASON_DAYS:=91
## The most figures one task's row draws; above it each figure stands for more.
const FIGURES_MAX:=12
## Chronicle kinds and domains that concern the people themselves.
const STORY_KINDS:=["birth","death","hearth_count","milestone","founding","settlement","work","ceremony","omen"]
const STORY_DOMAINS:=["population","demography","demographic","nutrition","food","health","social","settlement","infrastructure"]
## Labor roles (population_allocation_percentages) and the task words shown.
const TASKS:=[
	["gather","gathering"],["hunt","hunting"],["fish","fishing"],["tend","tending fields"],
	["build","building"],["fetch","fetching wood and stone"],["make","making tools"],["carry","carrying"],
	["scout","scouting"],["learn","learning"],["steward","keeping the stores"],["watch","keeping watch"],
]
const ROLE_TASK:={"Construction":"build","Extraction":"fetch","Crafting":"make","Logistics":"carry","Survey":"scout","Knowledge":"learn","Administration":"steward","Defense":"watch"}


# ---------------------------------------------------------------------------
# Scene
# ---------------------------------------------------------------------------

static func home_name()->String:
	for city in GameState.player_settlements:
		if city is Dictionary and bool((city as Dictionary).get("primary",false)):return String(city.get("name","the camp"))
	var named:=String(GameState.settlement_name).strip_edges()
	return named if named!="" else "the camp"


static func season_word(day:int=-1)->String:
	return HearthCount.season_name_for_day(int(GameState.elapsed_days) if day<0 else day)


## "Late autumn. Cold, and the weather is hard on the gatherers."
static func weather_line(celsius:float)->String:
	var season:=season_word()
	var feel:=""
	if not is_nan(celsius):
		for band in [[-8.0,"Bitter cold"],[3.0,"Cold"],[10.0,"Cool"],[18.0,"Mild"],[26.0,"Warm"],[34.0,"Hot"]]:
			if celsius<float(band[0]):feel=String(band[1]);break
		if feel=="":feel="Scorching"
		if GameState.known_discoveries.has("precision_thermometry"):feel="%s, %d°C" % [feel,roundi(celsius)]
	var weather:=float(GameState.simulation_metrics.get("food_weather_factor",1.0))
	var sky:="the weather is kind to the gatherers" if weather>=1.04 else "the weather is hard on the gatherers" if weather<0.9 else "the sky is quiet"
	if feel!="":return "%s. %s; %s." % [season.capitalize(),feel,sky]
	return "%s. %s." % [season.capitalize(),_cap(sky)]


static func headline(report:Dictionary,totals:Dictionary)->String:
	var count:=int(report.population)
	var parts:PackedStringArray=[]
	var stage:=EraWords.stage()
	if stage=="hearth":parts.append("%s at the %s fires." % [EraWords.people(count),home_name()] if not GameState.player_settlements.is_empty() else "%s on the move." % EraWords.people(count))
	elif stage=="lettered":parts.append("%s in %s." % [EraWords.people(count),EraWords.places(maxi(1,(report.cities as Array).size()))])
	else:parts.append("Population %s across %s." % [EraWords.grouped(count),EraWords.places(maxi(1,(report.cities as Array).size()))])
	var food:=float(report.food_min)
	if food>=0.0:parts.append(_cap(EraWords.store_span(food).replace("food for","Stores for"))+".")
	var need:=float(totals.get("food_need",0.0))
	var intake:=clampf(float(totals.get("food_eaten",0.0))/need,0.0,1.0) if need>0.0 else 1.0
	var children:="The children are fed" if intake>=0.99 else "Some children sleep hungry" if intake>=0.8 else "The children go hungry"
	var cold:=season_word()=="winter" or season_word()=="autumn"
	var health:=float(GameState.population_health)
	var old:="the old are well"
	if health<0.55:old="sickness is in the camp" if EraWords.hearth() else "sickness is in the houses"
	elif health<0.7 and cold:old="the old cough in the cold"
	elif health<0.7:old="the old are weak"
	elif int(GameState.hearth_season.get("buried",0))>0:old="we buried %s this season" % EraWords.count_word(int(GameState.hearth_season.buried))
	parts.append("%s; %s." % [children,old])
	return " ".join(parts)


static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text


# ---------------------------------------------------------------------------
# Faces
# ---------------------------------------------------------------------------

## The named people shown in the strip. Living ones are court-known persons
## found (or made once, then kept) by a stable description, so each face is
## the same person every day and can be summoned.
static func faces(settlement_id:String)->Array:
	var out:Array=[]
	var sid:=settlement_id
	var day:=int(GameState.elapsed_days)
	var season:Dictionary=GameState.hearth_season
	var season_key:=int(season.get("key",HearthCount.season_key(day)))
	if int(season.get("born",0))>0 and not GameState.player_settlements.is_empty():
		var babe:=Persons.find_or_create({"age":"child","settlement_id":sid,"quality":"newborn","deed":"was born in season %d" % season_key})
		if not babe.has("newborn_day"):
			babe["newborn_day"]=maxi(int(season.get("start_day",day)),day-7)
			babe["born_day"]=int(babe.newborn_day)
			var hh:Dictionary=babe.get("household",{}) if babe.get("household") is Dictionary else {}
			hh["children"]=0;hh["spouse"]={};babe["household"]=hh
		out.append(_face(babe,"newborn","NEWBORN","born this %s" % season_word()))
	out.append(_face(Persons.find_or_create({"age":"oldest","settlement_id":sid,"quality":"oldest living"}),"oldest","ELDEST",""))
	if float(GameState.population_health)<0.7 or float(GameState.malnutrition_burden)>0.12:
		out.append(_face(Persons.find_or_create({"settlement_id":sid,"quality":"sick","note":"The fever came on me and it has not left."}),"sick","SICK",""))
	var farming:=GameState.known_discoveries.has("seed_selection")
	out.append(_face(Persons.find_or_create({"trade":"farmer" if farming else "hunter","settlement_id":sid,"quality":"best "+("farmer" if farming else "hunter")}),"provider","BEST "+("FARMER" if farming else "HUNTER"),""))
	var maker:=Persons._fit_trade(["smith","potter","weaver","flint-knapper"])
	out.append(_face(Persons.find_or_create({"trade":maker,"settlement_id":sid,"quality":"best maker"}),"maker","BEST MAKER",""))
	out.append(_face(Persons.find_or_create({"settlement_id":sid,"quality":"troublemaker"}),"grievance","A GRIEVANCE",""))
	var officials:=Hall._officials()
	if not officials.is_empty():
		var chief:Dictionary=officials[0]
		var pid:=int(chief.get("person_id",0))
		if pid>0:
			var kin:=Persons.find_or_create({"settlement_id":sid,"age":"young","quality":"kin:%d" % pid,"kin_of":{"pid":pid,"relation":"child","name":String(chief.get("name",""))}})
			out.append(_face(kin,"kin","COURT KIN","child of %s, %s" % [String(chief.get("name","")),String(chief.get("title","")).to_lower()]))
	for entry in Lives.remembered(2):
		out.append({"id":"remembered:%d" % int(entry.get("pid",0)),"role":"remembered","tag":"REMEMBERED","alive":false,
			"person":{"name":String(entry.get("name","")),"person_id":int(entry.get("pid",0))},"name":String(entry.get("name","")),
			"age":int(entry.get("age",0)),"title":String(entry.get("title","")),"family":"" if String(entry.get("successor",""))=="" else "%s followed them" % String(entry.successor),
			"wants":"","regard":"","summon":{},"note":"Died in year %d, aged %d. They %s." % [int(int(entry.get("died",entry.get("day",0)))/365.0)+1,int(entry.get("age",0)),String(entry.get("deed","served"))]})
	return out


static func _face(p:Dictionary,role:String,tag:String,note:String)->Dictionary:
	var age:=Persons.age_of(p)
	var hh:Dictionary=p.get("household",{}) if p.get("household") is Dictionary else {}
	var sp:Dictionary=hh.get("spouse",{}) if hh.get("spouse") is Dictionary else {}
	var family:PackedStringArray=[]
	if String(hh.get("parents",""))!="":family.append("mother %s" % String(hh.parents))
	if not sp.is_empty():family.append(("%s %s" % ["husband" if String(p.get("sex",""))=="female" else "wife",String(sp.get("name",""))])+("" if bool(sp.get("alive",true)) else " (dead)"))
	var kids:=int(hh.get("children",0))
	if kids>0:family.append("%s %s" % [EraWords.count_word(kids),"child" if kids==1 else "children"])
	var kin:Dictionary=p.get("kin_of",{}) if p.get("kin_of") is Dictionary else {}
	if not kin.is_empty() and String(kin.get("name",""))!="":family.append("%s of %s" % [String(kin.get("relation","kin")),String(kin.name)])
	var regard:=Divine.read(float(p.get("love",0.5)),float(p.get("dread",0.2)),0.0)
	var trade:=Persons.trade_label(String(p.get("trade","")))
	var title:="newborn" if role=="newborn" else ("a child" if age<13 else trade)
	return {"id":String(p.get("id","")),"role":role,"tag":tag,"alive":String(p.get("status","living"))=="living",
		"person":{"name":String(p.get("name","")),"person_id":0,"portrait_index":absi(String(p.get("id","")).hash())},
		"name":String(p.get("name","")),"given":String(p.get("given",p.get("name",""))),"sex":String(p.get("sex","")),"age":age,
		"title":title,"village":String(p.get("village","")),"family":", ".join(family) if not family.is_empty() else "no close family living",
		"temper":String(p.get("temper","")),"detail":String(p.get("detail","")),
		"love":float(p.get("love",0.5)),"dread":float(p.get("dread",0.2)),"regard":String(regard.get("read","")),
		"wants":wants(role,p),"note":note,"summon":{"known_id":String(p.get("id",""))} if role!="newborn" else {}}


## What this person wants, from their place and the state of things.
static func wants(role:String,p:Dictionary)->String:
	var m:Dictionary=GameState.simulation_metrics
	var hungry:=float(m.get("food_intake_ratio",1.0))<0.99
	var game:=float(GameState.food_source_health.get("Hunting",0.9))
	match role:
		"newborn":return "Milk, and a warm place near the fire."
		"oldest":return "To see another spring, and to be asked before the young decide things."
		"sick":return "Rest, clean water, and someone to bring food until the fever breaks."
		"provider":
			if GameState.known_discoveries.has("seed_selection"):return "Rain at the right time, and more hands at the harvest."
			return "Better hunting ground. The game near camp is thin." if game<0.6 else "Sharper points, and a partner who can keep up."
		"maker":return "Good stone and time to work it, instead of carrying water." if EraWords.hearth() else "Good material and fewer days taken for other work."
		"grievance":return grievance()
		"kin":return "A seat nearer the fire when the chiefs talk, and a say in the sharing." if EraWords.hearth() else "A place at court like their parent."
	return "Enough to eat, and a dry place to sleep." if hungry else "To be left to their work."


## The grievance the discontented person carries, from the actual state.
static func grievance()->String:
	var m:Dictionary=GameState.simulation_metrics
	if float(m.get("food_intake_ratio",1.0))<0.95:return "They say the chiefs' families eat first while theirs go short."
	if GameState.housing_capacity<GameState.population_total:return "Their family sleeps in the open while others have roofs."
	if float(m.get("legitimacy",0.6))<0.5:return "They say the chiefs decide everything among themselves."
	if float(m.get("cohesion",0.6))<0.5:return "They quarrel with the families across the camp over the best ground."
	if int(GameState.hearth_season.get("buried",0))>0:return "They blame the watchers for the deaths this season."
	return "They want a bigger share of the meat for their household."


# ---------------------------------------------------------------------------
# The voice from the fires
# ---------------------------------------------------------------------------

## One named person's own words about their life, from the state of things.
## Plain speech: what they ate, who was born, who died, what they want.
static func voice(face_list:Array)->Dictionary:
	var m:Dictionary=GameState.simulation_metrics
	var water:Dictionary=GameState.water_metrics
	var season:Dictionary=GameState.hearth_season
	var food_days:=float(m.get("food_days",-1.0))
	var line:="";var role:=""
	if float(water.get("intake_ratio",1.0))<0.99:
		role="provider";line="We walk to the water again and again and it is still not enough. The little ones' lips are cracked."
	elif float(m.get("food_intake_ratio",1.0))<0.99:
		role="grievance";line="My children went to sleep hungry again. There is nothing left to dig near the camp."
	elif food_days>=0.0 and food_days<10.0:
		role="maker";line="The stores are nearly bare. I look at what is left every night before I sleep."
	elif GameState.housing_capacity<GameState.population_total:
		role="grievance";line="There are too many of us under one roof. When it rains, the children wake up wet."
	elif int(season.get("born",0))>0:
		role="oldest";line="There is a new baby at the fire this %s. I held it, and it held my finger." % season_word()
	elif int(season.get("buried",0))>0:
		role="oldest";line="We put one of ours in the ground this season. I still look for them at the fire."
	elif float(GameState.population_health)<0.65:
		role="sick";line="The cough will not leave me. I cannot go out with the others."
	elif season_word()=="winter":
		role="provider";line="It is cold at night. We need more hides before the worst of it."
	elif Aims.has_active():
		role="kin";line="We mean to %s. The young ones talk of nothing else." % String(Aims.active().get("phrase","do something great"))
	elif float(m.get("cohesion",0.7))<0.5:
		role="grievance";line=grievance().replace("They say","I say").replace("They ","We ").replace("their","our").replace("Their","Our")
	else:
		role="provider";line="We ate well today. The children are growing and nobody is sick."
	for face in face_list:
		if String((face as Dictionary).get("role",""))==role and bool(face.get("alive",false)):return {"face":face,"line":line}
	for face in face_list:
		if bool((face as Dictionary).get("alive",false)) and String(face.role)!="newborn":return {"face":face,"line":line}
	return {"face":{},"line":line}


# ---------------------------------------------------------------------------
# Vitals
# ---------------------------------------------------------------------------

static func _history_then(history:Array,field:String,days_back:int)->float:
	## The value recorded about days_back ago, or NAN when history is short.
	if history.size()<8:return NAN
	var today:=int(GameState.elapsed_days)
	for entry in history:
		if entry is Dictionary and int((entry as Dictionary).get("day",0))>=today-days_back:return float(entry.get(field,NAN))
	return NAN


static func _history_now(history:Array,field:String)->float:
	if history.is_empty():return NAN
	var sum:=0.0;var n:=0
	for i in range(maxi(0,history.size()-5),history.size()):
		var entry:Variant=history[i]
		if entry is Dictionary:sum+=float((entry as Dictionary).get(field,0.0));n+=1
	return sum/maxf(1.0,float(n))


static func _trend(now:float,then:float,tolerance:float)->int:
	if is_nan(now) or is_nan(then):return 0
	if now>then+tolerance:return 1
	if now<then-tolerance:return -1
	return 0


static func vitals(report:Dictionary,totals:Dictionary)->Array:
	var m:Dictionary=GameState.simulation_metrics
	var water:Dictionary=GameState.water_metrics
	var modern:=EraWords.reckoned()
	var out:Array=[]
	# Fed today.
	var need:=float(totals.get("food_need",0.0))
	var intake:=clampf(float(totals.get("food_eaten",0.0))/need,0.0,1.0) if need>0.0 else -1.0
	var fed_count:=EraWords.fed(int(totals.population),float(totals.food_eaten),need)
	var fed_trend:=_trend(_history_now(GameState.food_history,"intake_ratio"),_history_then(GameState.food_history,"intake_ratio",SEASON_DAYS),0.03)
	out.append({"id":"fed","label":"FED TODAY","value":("%d of %d" % [fed_count,int(totals.population)]) if fed_count>=0 else "Not yet told","fill":maxf(0.0,intake),
		"trend":fed_trend,"cause":"Everyone ate their fill." if intake>=0.99 else "%s went short today." % EraWords.count_word(maxi(0,int(totals.population)-fed_count)).capitalize() if intake>=0.0 else "Told once the people have eaten."})
	# Stores.
	var food:=float(report.food_min)
	var stored_now:=_history_now(GameState.food_history,"stored")
	var stored_then:=_history_then(GameState.food_history,"stored",SEASON_DAYS)
	var store_trend:=_trend(stored_now,stored_then,maxf(1.0,absf(stored_then)*0.08) if not is_nan(stored_then) else 1.0)
	out.append({"id":"stores","label":"STORES" if not modern else "FOOD RESERVE","value":EraWords.days(food) if food>=0.0 else "Not yet told","fill":clampf(food/90.0,0.0,1.0) if food>=0.0 else 0.0,
		"trend":store_trend,"cause":store_cause(store_trend,food)})
	# Water.
	var water_days:=float(report.water_min)
	var met:=float(water.get("intake_ratio",-1.0))
	var water_trend:=_trend(_history_now(GameState.water_history,"intake_ratio"),_history_then(GameState.water_history,"intake_ratio",SEASON_DAYS),0.03)
	var distance:=float(water.get("source_distance_km",-1.0))
	var water_cause:="Everyone drinks enough." if met>=0.99 else "Not everyone drinks enough; carrying cannot keep up." if met>=0.0 else "Told once the people have drunk."
	if met>=0.99 and distance>=1.5:water_cause="Enough to drink, but the water is a long walk away."
	out.append({"id":"water","label":"WATER","value":EraWords.days(water_days) if water_days>=0.0 else "Not yet told","fill":clampf(met,0.0,1.0) if met>=0.0 else 0.0,"trend":water_trend,"cause":water_cause})
	# Shelter.
	var residents:=int(report.residents);var sheltered:=int(report.sheltered);var places:=int(report.places)
	var building:=int(report.get("building",0))
	var roofs:="%d of %d under a roof" % [sheltered,residents]
	var shelter_cause:="Roofs for all, with room for %d more." % maxi(0,places-residents) if sheltered>=residents else "%s sleep in the open." % EraWords.count_word(residents-sheltered).capitalize()
	if building>0:shelter_cause+=" %s being built." % ("One shelter" if building==1 else "%s shelters" % EraWords.count_word(building).capitalize())
	out.append({"id":"shelter","label":"SHELTER","value":roofs if residents>0 else "On the move","fill":float(sheltered)/maxf(1.0,float(residents)),"trend":1 if building>0 else (-1 if sheltered<residents else 0),"cause":shelter_cause})
	# Life.
	var life:=float(report.get("life",0.0))
	var life_now:=_history_now(GameState.health_history,"life_expectancy")
	var life_then:=_history_then(GameState.health_history,"life_expectancy",SEASON_DAYS)
	var life_trend:=_trend(life_now,life_then,0.4)
	var life_cause:=EraWords.babes_lost_sentence(float(totals.get("infant",0.0)))
	if life_trend!=0 and not GameState.health_history.is_empty():
		var marker:=String((GameState.health_history.back() as Dictionary).get("marker_label",""))
		if marker!="" and marker!="Tracking begins":life_cause=("Lives are longer since: " if life_trend>0 else "Lives are shorter since: ")+marker.to_lower()+"."
	out.append({"id":"life","label":"HOW LONG WE LIVE" if not modern else "LIFE EXPECTANCY","value":EraWords.life(life) if residents>0 else "Not yet told","fill":clampf(life/70.0,0.0,1.0),"trend":life_trend,"cause":life_cause})
	# Spirit.
	var cohesion:=float(report.cohesion)/float(report.cohesion_population) if int(report.cohesion_population)>0 else -1.0
	var legitimacy:=float(report.legitimacy)/float(report.legitimacy_population) if int(report.legitimacy_population)>0 else -1.0
	var spirit_cause:="Trust in the chiefs: "+(EraWords.trust(legitimacy) if legitimacy>=0.0 else "not yet told")+"."
	if cohesion>=0.0 and cohesion<0.5:spirit_cause="Families quarrel. "+spirit_cause
	out.append({"id":"spirit","label":"SPIRIT" if not modern else "COHESION","value":EraWords.spirit(cohesion) if cohesion>=0.0 else "Not yet told","fill":maxf(0.0,cohesion),"trend":0,"cause":spirit_cause})
	return out


## Why the stores move, in plain words.
static func store_cause(trend:int,food_days:float)->String:
	var m:Dictionary=GameState.simulation_metrics
	var health:Dictionary=GameState.food_source_health
	var season:=season_word()
	if food_days<0.0:return "Told once the stores are counted."
	if trend>0:return "Stores rising: more comes in than we eat."
	if trend==0 and food_days>=20.0:return "Stores holding."
	var weakest:="";var low:=1.0
	for key in ["Hunting","Wild gathering","Fishing","Cultivation"]:
		if health.has(key) and float(health[key])<low:low=float(health[key]);weakest=key
	var head:="Stores falling: " if trend<0 else "Stores low: "
	if low<0.55:
		match weakest:
			"Hunting":return head+"the game near camp is hunted out."
			"Wild gathering":return head+"the plants near camp are stripped."
			"Fishing":return head+"the fish have grown scarce."
			"Cultivation":return head+"the fields are tired."
	if float(m.get("food_weather_factor",1.0))<0.9:return head+"the weather is hard on the gatherers."
	if season=="winter":return head+"little grows in winter."
	if float(m.get("food_spoilage",0.0))>float(m.get("food_production",1.0))*0.25:return head+"much of what is gathered spoils."
	return head+"we eat more than we bring in."


# ---------------------------------------------------------------------------
# Labor
# ---------------------------------------------------------------------------

## How many are at each task today: food labor split by what the food
## actually came from (plants, game, fish, fields), the rest by allocation.
static func labor(productive:int)->Array:
	var alloc:Dictionary=GameState.population_allocation_percentages
	var counts:Dictionary={}
	var food_workers:=float(alloc.get("Food",0.0))/100.0*float(productive)
	var harvest:Dictionary=GameState.simulation_metrics.get("food_harvest",{}) if GameState.simulation_metrics.get("food_harvest") is Dictionary else {}
	var split:={"gather":float(harvest.get("Fresh plants",0.0)),"hunt":float(harvest.get("Fresh meat",0.0)),"fish":float(harvest.get("Fish",0.0)),"tend":float(harvest.get("Dry staples",0.0))}
	var total:=0.0
	for key in split:total+=float(split[key])
	if total<=0.0:split={"gather":0.6,"hunt":0.3,"fish":0.1,"tend":0.0};total=1.0
	for key in split:counts[key]=float(split[key])/total*food_workers
	for role:String in ROLE_TASK:counts[ROLE_TASK[role]]=float(counts.get(ROLE_TASK[role],0.0))+float(alloc.get(role,0.0))/100.0*float(productive)
	var out:Array=[]
	for task in TASKS:
		var count:=roundi(float(counts.get(String(task[0]),0.0)))
		if count<=0:continue
		out.append({"id":String(task[0]),"label":String(task[1]),"count":count})
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.count)>int(b.count))
	return out


# ---------------------------------------------------------------------------
# The season's story
# ---------------------------------------------------------------------------

static func story(limit:int=4)->Array:
	var out:Array=[]
	for e in Chronicle.entries("whisper",120):
		var entry:Dictionary=e
		var kind:=String(entry.get("kind",""))
		if not (kind in STORY_KINDS or String(entry.get("domain","")) in STORY_DOMAINS):continue
		var text:=String(entry.get("text",""))
		var sentences:=text.split(". ",false)
		var short:=String(sentences[0]) if not sentences.is_empty() else ""
		if short!="" and not short.ends_with(".") and not short.ends_with("!") and not short.ends_with("?"):short+="."
		out.append({"title":String(entry.get("title","")),"text":short,"kind":kind,"day":int(entry.get("day",0)),"when":when(int(entry.get("day",0)))})
		if out.size()>=limit:break
	return out


static func when(day:int)->String:
	var ago:=int(GameState.elapsed_days)-day
	if ago<=0:return "today"
	if ago==1:return "yesterday"
	if ago<SEASON_DAYS and HearthCount.season_key(day)==HearthCount.season_key(int(GameState.elapsed_days)):return "this "+season_word()
	if EraWords.hearth():return "%s ago" % ("a season" if ago<SEASON_DAYS*2 else "%s seasons" % EraWords.count_word(mini(12,ago/SEASON_DAYS)))
	return "year %d, day %d" % [day/365+1,day%365+1]


# ---------------------------------------------------------------------------
# Hearths
# ---------------------------------------------------------------------------

## A settlement's needs in plain words.
static func needs_words(city:Dictionary)->String:
	if bool(city.get("occupied",false)):return "Held by strangers."
	var parts:PackedStringArray=[]
	var food:=float(city.get("food",-1.0))
	var met:=float(city.get("water_met",-1.0))
	var issues:Array=city.get("issues",[])
	if issues.has("Food shortfall"):parts.append("Going hungry")
	elif food>=0.0 and food<7.0:parts.append("Stores nearly gone")
	elif food>=0.0:parts.append(_cap(EraWords.store_span(food)))
	if issues.has("Water shortfall"):parts.append("short of water")
	elif met>=0.0:parts.append("water enough")
	var population:=int(city.get("population",0));var places:=int(city.get("places",0))
	parts.append("roofs for all" if places>=population else "%s without a roof" % EraWords.count_word(population-places))
	return ", ".join(parts)+"."
