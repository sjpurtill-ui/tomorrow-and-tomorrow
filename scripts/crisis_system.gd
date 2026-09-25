extends RefCounted
## CRISES: the first slice of the epochal-shock model, lived day by day.
##
## The offline research model (tools/sim/shocks/, docs/research/epochal/
## EPOCHAL_SHIFTS.md) draws shocks once a game year for many peoples. This is
## its port for the god's own people, run once a day from the court's daily
## pass (AudienceHall.daily) and read only from real game state:
##
##   hunger    the catalog's famine hazard: this season's harvest shortfall
##             (the real weather in FoodSystem), stores in years, crowding
##             against the land, trade, institutions and diet breadth.
##   sickness  endemic flare-ups: the catalog's pestilence form (crowding,
##             water, health practice, hunger, disease pool) with a local base
##             rate, and the catalog's mortality formula (virulence x density x
##             (1 - immunity) x (1 - medicine)^2 x hunger). Waves that kill
##             many return weaker 8-20 years later (catalog echoes).
##   stranger  the strangers' sickness: each people met can pass its sickness
##             to ours once, along contact and trade. When their disease pool
##             is far richer than ours it is a virgin-soil wave (catalog §3.1).
##   drought   read from the real weather: a dry pulse in FoodSystem that
##             holds the season's yield well below normal.
##   cold      the catalog's notable volcanic year (1.3 per game century):
##             a dim summer that cuts the harvest through the food_yield channel.
##   flood     river camps only, in wet years (the weather's favourable pulse).
##   fire      a camp fire: crowding, dry weather, winter hearths, ember practice.
##   thinning  "The Land Is Thinning" (consequence_engine) no longer repeats
##             every 120 days: its second telling becomes this decision.
##
## Each crisis opens a court matter the god must weigh (officials still wait
## to be summoned; only envoys come unbidden) with three or four real choices
## whose costs come out of real stores, labour, bonds, relations and timed
## policy channels (food_demand, disease_risk, food_yield, water_collection,
## labor_multiplier, ecology_delta). It then plays out over weeks: a report
## in the middle (and, when it is bad, a second decision), deaths counted and
## the dead named, an aftermath, and, when people died, how to remember them.
## If the god stays silent, the holder acts on their own judgement.
##
## Frequency and severity follow the catalog: the same hazard form
## base(era) x exp(sum beta (x - x_ref)) and the same magnitude draws, so the
## catalog-scale tail (famine >= 2% dead, pestilence >= 5%, climate shocks)
## stays inside the per-century bands of catalog.HISTORICAL_BASE_RATES and
## benchmarks_1200.json shock_widening; crisis deaths never take the people
## below the shock_widening floors (70% of the pre-crisis count, never under
## 30). Everyday hardships below those thresholds are the same hazards at a
## lower threshold. stats() reports both.
##
## Names are generic and invented (alternative history): "the Summer Flux of
## the ninth year", "the Kintara Fever".
##
## State lives in ForeignDiplomacy.audiences["crises"] (saved with the court;
## older saves start empty). Static helpers; load lazily from the hall.

const Hall:=preload("res://scripts/audience_hall.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Lives:=preload("res://scripts/court_lives.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const CV:=preload("res://scripts/character_voice.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const EXCHANGE:=preload("res://scripts/civilization_exchange.gd")
const EARLY_CARE:=preload("res://scripts/early_life_conditions.gd")
const ERAS:=preload("res://scripts/technology_eras.gd")
const HEARTH:=preload("res://scripts/hearth_count.gd")
const TURNING_PATH:="res://scripts/turning_points.gd"

const KEY:="crises"
## Probes turn off chance onsets to test one crisis at a time.
static var onsets_enabled:=true
const VERSION:=1
const LOG_MAX:=80
const HISTORY_MAX:=40
const ACTIVE_MAX:=2
## The opening arc owns the first months after founding.
const QUIET_AFTER_FOUNDING:=240
## Two crises never open within the same few weeks.
const ONSET_GAP:=30
## A crisis will not wait a season for the god: after this the holder acts.
const DECIDE_DAYS:=24
const MID_DECIDE_DAYS:=18
## Benchmarks (benchmarks_1200.json shock_widening): pestilence population
## low_mult 0.7 and the hard floor of 30 people.
const FLOOR_SHARE:=0.7
const FLOOR_PEOPLE:=30

## Mirrors of tools/sim/shocks/catalog.py tables (historical year, value).
const MEDICINE_CEILING:=[[-5000,0.35],[1400,0.45],[1850,0.8],[1900,0.9],[1945,0.95],[2030,0.95]]
const PANDEMIC_EMERGE:=[[-5000,0.01],[-3000,0.08],[-1200,0.075],[0,0.055],[1300,0.08],[1700,0.07],[1900,0.035],[2030,0.03]]
const VOLCANIC_NOTABLE:=1.3   ## per game century (catalog CLIMATE)
## Local hardship bases, per game year at the reference state. The severe
## tail of each is what the catalog counts (see stats()).
const BASE_SICKNESS:=0.40
const BASE_FIRE:=0.14
const BASE_FLOOD_WET:=0.35
const BASE_FLOOD_DRY:=0.03
const BASE_STRANGER:=0.55
## The reference state (x_ref in the catalog hazard form): an ordinary band
## of this game in its first centuries, housed at about twice its numbers,
## well watered and in good health.
const CROWD_REF:=0.55
const HEALTH_REF:=0.9
const POOL_REF:=0.12
## Reporting thresholds (catalog HISTORICAL_BASE_RATES).
const SEVERE:={"hunger":0.02,"sickness":0.05,"stranger":0.05}

const TYPES:={
	"hunger":{"offices":["Quartermaster","Steward","settlement"],"cause":"Hunger","domain":"nutrition"},
	"sickness":{"offices":["Scholar","Steward","settlement"],"cause":"Illness","domain":"health"},
	"stranger":{"offices":["Envoy","Scholar","Steward","ChiefScout","settlement"],"cause":"Illness","domain":"health"},
	"drought":{"offices":["Quartermaster","Steward","ChiefScout","settlement"],"cause":"Dehydration","domain":"ecology"},
	"cold":{"offices":["Quartermaster","Steward","settlement"],"cause":"Hunger","domain":"ecology"},
	"flood":{"offices":["Steward","Quartermaster","settlement"],"cause":"Drowning","domain":"ecology"},
	"fire":{"offices":["settlement","Steward","Quartermaster"],"cause":"Fire","domain":"demography"},
	"thinning":{"offices":["Quartermaster","Steward","ChiefScout","settlement"],"cause":"","domain":"ecology"},
}
const ORDINALS:=["first","second","third","fourth","fifth","sixth","seventh","eighth","ninth","tenth","eleventh","twelfth","thirteenth","fourteenth","fifteenth","sixteenth","seventeenth","eighteenth","nineteenth","twentieth",
	"twenty-first","twenty-second","twenty-third","twenty-fourth","twenty-fifth","twenty-sixth","twenty-seventh","twenty-eighth","twenty-ninth","thirtieth"]
const NUMBER_WORDS:=["no one","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"]

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func state()->Dictionary:
	# The court block is replaced when a new world begins: read it fresh.
	ForeignDiplomacy.ensure()
	var raw:Variant=ForeignDiplomacy.audiences.get(KEY,{})
	var s:Dictionary=raw if raw is Dictionary else {}
	if not s.is_empty() and (int(s.get("world_seed",GameState.world_seed))!=int(GameState.world_seed) or float(s.get("last_day",0))>GameState.elapsed_days+1.0): s.clear()
	if int(s.get("version",0))!=VERSION: _seed(s)
	ForeignDiplomacy.audiences[KEY]=s
	return s

static func _seed(s:Dictionary)->void:
	for key in ["active","last","exchanged","flags","stats","until"]:
		if not s.get(key) is Dictionary: s[key]={}
	for key in ["history","log","echoes"]:
		if not s.get(key) is Array: s[key]=[]
	for key in ["serial","last_day","last_onset","immunity","pool"]:
		if not _num(s.get(key)): s[key]=0 if key!="last_onset" else -99999
	s["world_seed"]=int(GameState.world_seed)
	s["version"]=VERSION

static func valid_state(data:Variant)->bool:
	## Optional save block; absent in older saves.
	if not data is Dictionary: return false
	var d:Dictionary=data
	if JSON.stringify(d).length()>120000: return false
	for key in ["active","last","exchanged","flags","stats","until"]:
		if d.has(key) and not d[key] is Dictionary: return false
	var limits:={"history":HISTORY_MAX,"log":LOG_MAX,"echoes":24}
	for key:String in limits:
		if not d.has(key): continue
		if not d[key] is Array or (d[key] as Array).size()>int(limits[key]): return false
		for entry in d[key]:
			if not entry is Dictionary: return false
	if d.has("active") and (d.active as Dictionary).size()>ACTIVE_MAX+2: return false
	return true

static func _num(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func _day()->int:
	return int(GameState.elapsed_days)

static func _rng(key:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:crisis:%s" % [int(GameState.world_seed),key])
	return rng

static func _pick(list:Array,key:String)->String:
	if list.is_empty(): return ""
	return String(list[posmod(hash("%d|%s" % [int(GameState.world_seed),key]),list.size())])

static func _log(kind:String,text:String,extra:Dictionary={})->void:
	## A bounded record (tests and the playtest harness read it).
	var entry:Dictionary={"day":_day(),"kind":kind,"text":text.substr(0,300)}
	for key in extra:
		var value:Variant=extra[key]
		if value is String or value is int or value is float or value is bool: entry[String(key)]=value
	var list:Array=state().log
	list.push_front(entry)
	while list.size()>LOG_MAX: list.pop_back()

static func _stat(type:String,key:String,amount:float=1.0)->void:
	var stats:Dictionary=state().stats
	var row:Dictionary=stats.get(type,{}) if stats.get(type) is Dictionary else {}
	row[key]=float(row.get(key,0.0))+amount
	stats[type]=row

static func stats()->Dictionary:
	## Per type: onsets, severe (the catalog-scale tail), deaths, decisions
	## (answered by the god), silent (the holder acted), years watched.
	var s:=state()
	var out:=(s.stats as Dictionary).duplicate(true)
	out["years_watched"]=maxf(0.0,float(_day()-maxi(0,GameState.settlement_founded_day)))/365.0
	return out

static func active()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	for key in state().active:
		var c:Variant=state().active[key]
		if c is Dictionary: out.append(c)
	return out

static func _turning()->GDScript:
	return load(TURNING_PATH) as GDScript if ResourceLoader.exists(TURNING_PATH) else null

static func unlocked(option_key:String)->bool:
	## A crisis choice opened by a turning point the people have lived through.
	var tp:=_turning()
	return tp!=null and bool(tp.call("unlocks",option_key))

# --------------------------------------------------------------------------
# Words
# --------------------------------------------------------------------------

static func _year_words(day:int)->String:
	var year:=maxi(0,int(floor(float(day-maxi(0,GameState.settlement_founded_day))/365.0)))
	return "the %s year" % String(ORDINALS[year]) if year<ORDINALS.size() else "year %d" % (year+1)

static func _count(n:int)->String:
	return String(NUMBER_WORDS[n]) if n>=0 and n<NUMBER_WORDS.size() else str(n)

static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text

static func _the(name:String)->String:
	if name.begins_with("The "): return "the "+name.substr(4)
	return name if name.begins_with("the ") else "the "+name

static func _season(day:int)->String:
	return HEARTH.season_name_for_day(day)

static func _era_ok(text:String)->bool:
	return CV.permits(text,CV.era_tags("player"))

static func _given(name:String)->String:
	return EraNames.given_of(name) if name!="" else "Someone"

static func _food_words(amount:float)->String:
	## Stores in days of food for everyone, as the people count them.
	var days:=roundi(amount/maxf(1.0,float(GameState.population_total)))
	if days<=1: return "a day's worth"
	return "%s days' worth" % _count(days)

const WOMEN_ROLES:=["an old woman","a young mother","a girl","a grandmother","a woman who gathered with the others"]
const MEN_ROLES:=["an old man","a small boy","a hunter","a grandfather","a young man"]

static func _dead_words(total:int,dead:Array)->String:
	## "two: Tesk, an old man, and Ama, a girl" or "five, among them ...".
	var named:PackedStringArray=PackedStringArray()
	for n in dead.slice(0,mini(3,dead.size())): named.append(String(n))
	if named.is_empty(): return _count(total)
	var listed:=named[0] if named.size()==1 else "%s; and %s" % ["; ".join(named.slice(0,named.size()-1)),named[named.size()-1]]
	if total>named.size(): return "%s, among them %s" % [_count(total),listed]
	return "%s: %s" % [_count(total),listed]

static func _used_names()->Dictionary:
	## Names at court, and the names this people's crises have lately told.
	var used:Dictionary=EraNames.used_in_court()
	for given in (state().get("names",[]) as Array): used["given:"+String(given)]=true
	return used

static func _remember_name(given:String)->void:
	var s:=state()
	if not s.get("names") is Array: s["names"]=[]
	(s.names as Array).push_back(given)
	while (s.names as Array).size()>30: (s.names as Array).pop_front()

static func _dead_names(count:int,salt:String)->Array[String]:
	## The dead are ordinary people: a given name and who they were.
	var out:Array[String]=[]
	var used:=_used_names()
	var s:=state()
	for i in count:
		s.serial=int(s.serial)+1
		var rng:=_rng("dead:%s:%d" % [salt,i])
		var woman:=rng.randf()<0.5
		var made:Dictionary=EraNames.make(int(GameState.world_seed),900000+int(s.serial),woman,"player",used,{})
		var given:=String(made.get("given",""))
		if given=="": continue
		used["given:"+given]=true
		_remember_name(given)
		var roles:Array=WOMEN_ROLES if woman else MEN_ROLES
		out.append("%s, %s" % [given,String(roles[rng.randi_range(0,roles.size()-1)])])
	return out

static func _people_names(count:int,salt:String,woman_bias:float=0.5)->Array[String]:
	## Invented names for ordinary people touched by a crisis (the dead, the
	## helpers). Never real names; never a name already at court.
	var out:Array[String]=[]
	var used:=_used_names()
	var s:=state()
	for i in count:
		s.serial=int(s.serial)+1
		var rng:=_rng("name:%s:%d" % [salt,i])
		var made:Dictionary=EraNames.make(int(GameState.world_seed),900000+int(s.serial),rng.randf()<woman_bias,"player",used,{})
		var name:=String(made.get("name",""))
		if name=="": continue
		used[name]=true; used["given:"+String(made.get("given",""))]=true
		_remember_name(String(made.get("given","")))
		out.append(name)
	return out

# --------------------------------------------------------------------------
# Real state: the hazard inputs
# --------------------------------------------------------------------------

static func _ramp(points:Array,x:float)->float:
	if points.is_empty(): return 0.0
	if x<=float(points[0][0]): return float(points[0][1])
	for i in range(1,points.size()):
		if x<=float(points[i][0]):
			var a:Array=points[i-1]; var b:Array=points[i]
			var t:=(x-float(a[0]))/maxf(0.0001,float(b[0])-float(a[0]))
			return lerpf(float(a[1]),float(b[1]),t)
	return float(points[points.size()-1][1])

static func hist_year()->float:
	## The era clock: game year -> historical year (TechnologyEras.CURVE).
	return _ramp(ERAS.CURVE,GameState.elapsed_days/365.0)

static func _effect(id:String)->float:
	return float(DiscoverySystem.effect(id)) if is_instance_valid(DiscoverySystem) and DiscoverySystem.has_method("effect") else 0.0

static func _knows(ids:Array)->bool:
	for id in ids:
		if String(id) in GameState.known_discoveries: return true
	return false

static func _weather(day:int)->float:
	return float(Lives._weather(day))

static func _weather_mean(from_day:int,to_day:int)->float:
	var total:=0.0; var n:=0
	var d:=from_day
	while d<=to_day:
		total+=_weather(maxi(0,d)); n+=1
		d+=6
	return total/maxf(1.0,float(n))

static func _contacts()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	for civ in CivilizationSystem.civilizations:
		if not civ is Dictionary: continue
		var rel:Dictionary=(civ as Dictionary).get("player_relation",{}) if (civ as Dictionary).get("player_relation") is Dictionary else {}
		if int(rel.get("contact_level",0))>0: out.append(civ)
	return out

static func _trade_level()->float:
	var partners:=0.0
	for civ in _contacts():
		var rel:Dictionary=civ.get("player_relation",{})
		partners+=0.04+(0.08 if String(rel.get("treaty",""))!="" else 0.0)
	return clampf(0.05+partners,0.0,1.0)

static func inputs(day:int)->Dictionary:
	## Everything the hazards read, from the live simulation.
	var m:Dictionary=GameState.simulation_metrics
	var pop:=float(maxi(1,GameState.population_total))
	var cap:=float(maxi(1,GameState.housing_capacity))
	var hp:=_effect("health_protection"); var san:=_effect("sanitation"); var ws:=_effect("water_safety"); var de:=_effect("disease_exposure")
	var hk:=clampf(0.05+(hp+san+ws)/3.0-0.5*de,0.0,1.0)
	var H:=hist_year()
	var water:=clampf(float(m.get("water_intake_ratio",1.0)),0.0,1.0)
	var forecast:Dictionary=m.get("food_forecast_90",{}) if m.get("food_forecast_90") is Dictionary else {}
	var water_origin:=String(GameState.water_metrics.get("source_origin",""))
	var water_kind:=String(GameState.water_metrics.get("source_kind",""))
	var water_km:=float(GameState.water_metrics.get("source_distance_km",-1.0))
	var carrying:=maxf(1.0,float(EARLY_CARE.carrying_capacity(GameState,DiscoverySystem)))
	return {
		"pop":pop,"crowd":pop/cap,"dens":clampf(pop/5000.0,0.02,1.0),
		"health":float(GameState.population_health),"food_days":float(m.get("food_days",30.0)),
		"intake":float(m.get("food_intake_ratio",1.0)),"shortage_days":float(m.get("food_shortage_days",0.0)),
		"first_shortage":int(forecast.get("first_shortage_day",-1)),
		"water":water,"water_q":clampf(water-0.15*de+0.2*ws+0.2*san,0.0,1.2),
		"hk":hk,"H":H,"med":hk*_ramp(MEDICINE_CEILING,H),
		"inst":float(GameState.society_capacities.get("institutions",0.25)),
		"divers":clampf(float(EARLY_CARE.diet_window(GameState)),0.0,1.0),
		"trade":_trade_level(),"ecology":float(m.get("ecology",0.88)),
		"cohesion":float(m.get("cohesion",0.58)),
		"pressure":maxf(0.0,pop/carrying-0.85),
		"weather":_weather(day),"weather_season":_weather_mean(day-24,day+36),
		"season":float(Lives._season(day)),
		"river":(water_origin=="mapped_hydrology" or water_kind.contains("river")) and water_km>=0.0 and water_km<=2.0,
	}

# --------------------------------------------------------------------------
# Hazards (annual rates; the daily roll uses rate/365)
# --------------------------------------------------------------------------

static func _active_of(type:String)->Dictionary:
	for c in active():
		if String(c.get("type",""))==type: return c
	return {}

static func _until(key:String)->int:
	return int((state().until as Dictionary).get(key,-1))

static func hazards(day:int,x:Dictionary={})->Dictionary:
	## Annual hazard per crisis type from today's real state.
	if x.is_empty(): x=inputs(day)
	var s:=state()
	var flags:Dictionary=s.flags
	var hunger_on:=0.0 if _active_of("hunger").is_empty() else 1.0
	var drought_on:=0.0 if _active_of("drought").is_empty() else 1.0
	var out:={}
	# Famine (catalog engine._famine), per game year.
	var other:=maxf(0.0,1.0-float(x.weather_season))+maxf(0.0,0.97-float(x.intake))
	var buffer:=0.35*minf(float(x.food_days)/365.0,1.0)+0.12*float(x.trade)+0.06*float(x.inst)+0.08*float(x.divers)-0.12
	var shortfall:=other+0.6*float(x.pressure)-buffer
	var p:=0.0025*exp(8.0*shortfall)+1.0/(1.0+exp(-(shortfall-0.16)/0.015))
	if day-int((s.last as Dictionary).get("famine",-99999))<6*365: p*=0.15
	out["hunger"]=minf(p,0.95)
	out["hunger_shortfall"]=shortfall
	# Endemic sickness (catalog pestilence form, local base).
	var season_factor:=1.0+0.35*absf(float(x.season))
	var sick:=BASE_SICKNESS*exp(1.6*(float(x.crowd)-CROWD_REF)+1.5*(1.0-minf(1.0,float(x.water_q)))+1.5*(HEALTH_REF-float(x.health))+0.8*hunger_on+0.6*(float(s.pool)-POOL_REF))*(1.0-0.5*float(x.med))*season_factor
	if day<_until("after_flood"): sick*=2.0
	if drought_on>0.0: sick*=1.3
	if bool(flags.get("apart_custom",false)): sick*=0.85
	out["sickness"]=clampf(sick,0.0,3.0)
	# Emergence of a truly new pestilence (catalog pandemic_emerge), era-scaled.
	out["pestilence_emerge"]=_ramp(PANDEMIC_EMERGE,float(x.H))/100.0*exp(1.6*(float(x.dens)-0.4)+1.2*(float(x.trade)-0.4)+0.8*hunger_on+0.6*(float(s.pool)-0.4))*(1.0-0.5*float(x.med))
	# Fire.
	var fire:=BASE_FIRE*exp(1.0*(float(x.crowd)-CROWD_REF))*(1.0+1.5*drought_on+0.8*maxf(0.0,1.0-float(x.weather)))*(1.0+0.3*maxf(0.0,-float(x.season)))
	if _knows(["ember_tending","cookfire_smoke_venting_habit"]): fire*=0.75
	if bool(flags.get("spaced",false)): fire*=0.6
	if bool(flags.get("earth",false)): fire*=0.5
	if day<_until("burn"): fire*=2.0
	out["fire"]=clampf(fire,0.0,2.0)
	# Flood: river camps, wet years.
	var flood:=0.0
	if bool(x.river):
		flood=BASE_FLOOD_WET if float(x.weather_season)>1.03 else BASE_FLOOD_DRY
		if bool(flags.get("moved_up",false)): flood*=0.5
		if bool(flags.get("mounds",false)) or _knows(["flood_house_mounds"]): flood*=0.4
	out["flood"]=flood
	out["cold"]=VOLCANIC_NOTABLE/100.0
	return out

# --------------------------------------------------------------------------
# The daily pass
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	if WorldSimulation.actor_id!="player": return
	if not GameState.settlement_site_committed or GameState.settlement_founded_day<0: return
	var s:=state()
	if int(s.last_day)>=day: return
	var first_pass:=int(s.last_day)<=0
	s.last_day=day
	var x:=inputs(day)
	# Immunity fades as new generations grow up (half-life ~18 years); the
	# disease pool drifts toward what crowding and trade support (catalog).
	s.immunity=float(s.immunity)*pow(0.962,1.0/365.0)
	var target_pool:=clampf(0.1+0.6*float(x.dens)+0.3*float(x.trade),0.0,1.0)
	if first_pass and float(s.pool)<=0.0: s.pool=target_pool
	s.pool=float(s.pool)+(target_pool-float(s.pool))*0.01/365.0
	for c in active(): _advance(c,day,x)
	var tp:=_turning()
	if tp!=null: tp.call("daily",day)
	if day-GameState.settlement_founded_day<QUIET_AFTER_FOUNDING: return
	_watch_thinning(day,x)
	var h:=hazards(day,x)
	# Expected onsets from the hazards alone (for stats() and the report).
	var expect:Dictionary=(s.stats as Dictionary).get("expected",{}) if (s.stats as Dictionary).get("expected") is Dictionary else {}
	for key in ["hunger","sickness","pestilence_emerge","fire","flood","cold"]: expect[key]=float(expect.get(key,0.0))+float(h.get(key,0.0))/365.0
	(s.stats as Dictionary)["expected"]=expect
	if not onsets_enabled or active().size()>=ACTIVE_MAX or day-int(s.last_onset)<ONSET_GAP: return
	_maybe_onset(day,x,h)

static func _roll(key:String,annual:float)->bool:
	if annual<=0.0: return false
	var daily_p:=1.0-pow(maxf(0.0,1.0-minf(annual,0.999)),1.0/365.0)
	if annual>=1.0: daily_p=annual/365.0
	return _rng(key).randf()<daily_p

static func _ready_again(type:String,day:int,gap:int)->bool:
	return day-int((state().last as Dictionary).get(type,-99999))>=gap

static func _maybe_onset(day:int,x:Dictionary,h:Dictionary)->void:
	var s:=state()
	# Echoes: a sickness that killed many comes back, weaker (catalog).
	for echo in (s.echoes as Array).duplicate():
		if echo is Dictionary and int(echo.get("day",0))<=day:
			(s.echoes as Array).erase(echo)
			if _active_of("sickness").is_empty() and _active_of("stranger").is_empty():
				_open_sickness(day,x,"sickness",float(echo.get("v",0.01)),String(echo.get("civ_id","")),true)
				var opened:=_active_of("sickness")
				if not opened.is_empty(): opened["echo_count"]=int(echo.get("count",1))
				return
	# Hunger: the hazard, or hunger already at the door.
	var hungry_now:=(float(x.shortage_days)>=10.0 and float(x.intake)<0.94) or (int(x.first_shortage)>0 and int(x.first_shortage)<=(75 if unlocked("hunger:early") else 45) and float(x.food_days)<(70.0 if unlocked("hunger:early") else 40.0))
	if _active_of("hunger").is_empty() and _ready_again("hunger",day,300) and (hungry_now or _roll("hunger:%d" % day,float(h.hunger))):
		_open_hunger(day,x,float(h.hunger_shortfall)); return
	# Drought and the dim summer: the real weather.
	if _active_of("drought").is_empty() and _ready_again("drought",day,300) and float(x.weather_season)<0.88 and float(x.season)>-0.45:
		_open_drought(day,x); return
	if _ready_again("cold",day,730) and _roll("cold:%d" % day,float(h.cold)):
		_open_cold(day,x); return
	# The strangers' sickness: once per people met, along contact and trade.
	if _active_of("stranger").is_empty() and _active_of("sickness").is_empty() and _ready_again("stranger",day,240):
		for civ in _contacts():
			var civ_id:=String(civ.get("id",""))
			if (s.exchanged as Dictionary).has(civ_id): continue
			var rel:Dictionary=civ.get("player_relation",{})
			var met:=int((s.exchanged as Dictionary).get("met:"+civ_id,-1))
			if met<0:
				(s.exchanged as Dictionary)["met:"+civ_id]=day
				continue
			if day-met<60: continue
			var link:=clampf(float(rel.get("contact_level",1))/3.0,0.2,1.0)*(0.5+float(x.trade)+(0.3 if String(rel.get("treaty",""))!="" else 0.0))
			if _roll("stranger:%s:%d" % [civ_id,day],BASE_STRANGER*link):
				(s.exchanged as Dictionary)[civ_id]=day
				_open_stranger(day,x,civ); return
	if _active_of("sickness").is_empty() and _active_of("stranger").is_empty() and _ready_again("sickness",day,150):
		var emerge:=float(h.pestilence_emerge)
		if _roll("pest:%d" % day,emerge):
			_open_sickness(day,x,"sickness",_lognormal(_rng("pestv:%d" % day),0.06,0.85,0.005,0.35),"",false,true); return
		if _roll("sick:%d" % day,float(h.sickness)):
			_open_sickness(day,x,"sickness",_lognormal(_rng("sickv:%d" % day),0.012,0.8,0.002,0.25),"",false); return
	if _active_of("flood").is_empty() and _ready_again("flood",day,365) and _roll("flood:%d" % day,float(h.flood)):
		_open_flood(day,x); return
	if _active_of("fire").is_empty() and _ready_again("fire",day,200) and _roll("fire:%d" % day,float(h.fire)):
		_open_fire(day,x); return

static func _lognormal(rng:RandomNumberGenerator,median:float,sigma:float,lo:float,hi:float)->float:
	return clampf(median*exp(sigma*rng.randfn(0.0,1.0)),lo,hi)

# --------------------------------------------------------------------------
# Onsets
# --------------------------------------------------------------------------

static func _holder(type:String)->Dictionary:
	var officials:=Hall._officials()
	for office in (TYPES[type] as Dictionary).offices:
		for person in officials:
			if String(person.get("office_key",""))==String(office): return person
	return officials[0] if not officials.is_empty() else {}

static func _second_voice(holder_pid:int)->Dictionary:
	for person in Hall._officials():
		if int(person.get("person_id",0))!=holder_pid: return person
	return {}

static func _new(type:String,kind:String,name:String,day:int,x:Dictionary,extra:Dictionary={})->Dictionary:
	var s:=state()
	s.serial=int(s.serial)+1
	var holder:=_holder(type)
	var c:Dictionary={"id":"c%d" % int(s.serial),"type":type,"kind":kind,"name":name,"start":day,"phase":"open",
		"pop0":int(float(x.pop)),"m":0.0,"mult":1.0,"deaths":0,"dead":[],"helpers":[],"choice":"","mid_choice":"",
		"decide_by":day+DECIDE_DAYS,"mid_day":day+30,"end_day":day+75,"holder_pid":int(holder.get("person_id",0)),
		"holder":String(holder.get("name","")),"holder_title":String(holder.get("office_title","")),"matter":"","signs":[],"notes":[]}
	c.merge(extra,true)
	(s.active as Dictionary)[String(c.id)]=c
	(s.last as Dictionary)[type]=day
	s.last_onset=day
	_stat(type,"onsets")
	return c

static func _signs(x:Dictionary,type:String)->Array[String]:
	## The lit signs (catalog court warnings), in plain words.
	var out:Array[String]=[]
	match type:
		"sickness","stranger":
			if float(x.crowd)>1.0: out.append("too many sleep under each roof")
			if float(x.water_q)<0.85: out.append("the drinking water is bad")
			if float(x.health)<0.55: out.append("people were already weak")
			if not _active_of("hunger").is_empty(): out.append("hunger has thinned them")
		"hunger":
			if float(x.food_days)<45.0: out.append("the stores are thin")
			if float(x.weather_season)<0.95: out.append("the season's gathering came in short")
			if float(x.pressure)>0.05: out.append("the land nearby feeds fewer than we are")
			if float(x.divers)<0.3: out.append("we live on too few foods")
	return out

static func _file(c:Dictionary,phase:String,summary:String,headline:String,deadline:int)->void:
	## The crisis waits at court as a matter held by an official.
	var holder:=Hall._official(int(c.holder_pid))
	if holder.is_empty():
		holder=_holder(String(c.type))
		if holder.is_empty(): return
		c.holder_pid=int(holder.get("person_id",0)); c.holder=String(holder.get("name","")); c.holder_title=String(holder.get("office_title",""))
	var day:=_day()
	var audience:=Hall._new_audience("court","petition",day)
	audience.speaker={"name":String(holder.get("name","")).substr(0,100),"title":String(holder.get("office_title","Official")).substr(0,100),"person_id":int(holder.get("person_id",0)),"role":"official"}
	audience.petition={"topic":"crisis","summary":summary.substr(0,400),"suggested_decree":""}
	audience.situation={"type":"crisis","ask":"crisis:%s:%s" % [String(c.id),phase],"headline":headline,"summary":summary.substr(0,400),
		"occasion":{"type":"crisis","text":String(c.name),"day":day,"crisis":true},"crisis":{"id":String(c.id),"phase":phase,"type":String(c.type)}}
	var entry:=Hall._file_matter(audience,[])
	entry["expires"]=deadline+2
	entry["urgency"]=0.95
	c.matter=String(entry.get("id",""))
	c["matter_phase"]=phase

static func _record(c:Dictionary,suffix:String,title:String,text:String,tier:String,kind:String,court:bool,priority:bool=false)->Dictionary:
	var moment:={"key":"crisis:%s:%s" % [String(c.id),suffix],"title":title,"text":text,"tier":tier,"kind":kind,"domain":String((TYPES[String(c.type)] as Dictionary).domain),"priority":priority}
	if court and int(c.holder_pid)>0: moment["action"]={"kind":"court","focus":{"person_id":int(c.holder_pid)}}
	return Chronicle.record(moment)

static func _announce(c:Dictionary,title:String,text:String)->void:
	var waits:=" %s waits to be summoned." % _given(String(c.holder)) if String(c.holder)!="" else ""
	_record(c,"onset",title,text+waits,"moment","omen",true,true)
	_log("onset",text,{"type":String(c.type),"sub":String(c.kind),"name":String(c.name),"crisis":String(c.id),"m":float(c.m),"severe":bool(c.get("severe",false))})

static func _plan_deaths(c:Dictionary,m:float)->void:
	c.m=clampf(m,0.0,0.6)
	var severe_at:=float(SEVERE.get(String(c.type),1.0))
	c["severe"]=float(c.m)>=severe_at
	if bool(c.severe): _stat(String(c.type),"severe")

static func _mortality(v:float,x:Dictionary,pool:float,rng:RandomNumberGenerator)->float:
	## Catalog engine._pandemic mortality(): one wave's death share.
	var s:=state()
	var virgin:=1.0+5.0*maxf(0.0,pool-float(s.pool)-0.1)
	var famine:=0.0 if _active_of("hunger").is_empty() else 1.0
	var m:=v*(0.5+float(x.dens))*(1.0-float(s.immunity))*pow(1.0-float(x.med),2.0)*(1.0+0.6*famine)*virgin
	return clampf(m*exp(0.35*rng.randfn(0.0,1.0)),0.0,0.6)

static func _open_hunger(day:int,x:Dictionary,shortfall:float)->void:
	var rng:=_rng("hungerm:%d" % day)
	var modern:=clampf((float(x.H)-1850.0)/100.0,0.0,1.0)
	var m:=clampf((0.012+0.2*maxf(0.0,shortfall))*(1.0-0.4*float(x.inst))*(1.0-0.5*modern)*exp(0.5*rng.randfn(0.0,1.0)),0.002,0.25)
	var winter:=_season(day) in ["autumn","winter"]
	var kind:="hungry_winter" if winter else "lean_season"
	var label:="the Hungry Winter" if winter else ("the Lean Spring" if _season(day)=="spring" else "the Lean Season")
	var c:=_new("hunger",kind,"%s of %s" % [label,_year_words(day)],day,x,{"mid_day":day+rng.randi_range(28,40),"end_day":day+rng.randi_range(80,120)})
	_plan_deaths(c,m)
	if bool(c.severe): (state().last as Dictionary)["famine"]=day
	c.signs=_signs(x,"hunger")
	var days:=roundi(float(x.food_days))
	var summary:="The stores hold about %d days. %s" % [days,_cap("; ".join(PackedStringArray(c.signs)))+"." if not (c.signs as Array).is_empty() else ""]
	_file(c,"open",summary.strip_edges(),"comes about the stores",int(c.decide_by))
	var title:="The Pits Run Low" if not winter else "A Hungry Winter Comes"
	_announce(c,title,"%s The god's people will go hungry before the land gives again." % summary.strip_edges())

static func _open_sickness(day:int,x:Dictionary,type:String,v:float,civ_id:String,echo:bool,new_pestilence:bool=false)->void:
	var s:=state()
	var rng:=_rng("sick:%s:%d" % [type,day])
	var season:=_season(day)
	var kind:="flux" if season=="summer" or float(x.water_q)<0.8 else ("cough" if season in ["winter","autumn"] else "fever")
	if new_pestilence: kind="pestilence"
	var label:String={"flux":"the Summer Flux","cough":"the Coughing Winter","fever":"the Shaking Fever","pestilence":"the Spotted Sickness"}[kind]
	var name:="%s of %s" % [label,_year_words(day)]
	if echo: name="%s Come Back" % label
	var c:=_new(type,kind,name,day,x,{"v":v,"echo":echo,"civ_id":civ_id,"mid_day":day+rng.randi_range(14,24),"end_day":day+rng.randi_range(45,80)})
	_plan_deaths(c,_mortality(v,x,float(s.pool),rng))
	c.signs=_signs(x,"sickness")
	var sick:=clampi(roundi(float(x.pop)*(0.06+3.0*float(c.m))),3,maxi(3,int(float(x.pop)/2.0)))
	c["sick"]=sick
	var where:=_pick(["at the east fire","at the fires by the water","in the huts nearest the midden","among the families at the edge of camp"],"where:%s" % String(c.id))
	var what:String={"flux":"the flux, the watery sickness","cough":"a deep cough and fever","fever":"a shaking fever","pestilence":"a sickness with spots no one has seen"}[kind]
	var summary:="%s are down with %s %s." % [_cap(_count(sick)),what,where]
	if echo: summary="%s It is the sickness we had before, come back." % summary
	if not (c.signs as Array).is_empty(): summary+=" %s." % _cap(String(c.signs[0]))
	_file(c,"open",summary,"comes about the sick",int(c.decide_by))
	_announce(c,"Sickness at the Fires",summary)

static func _civ_pool(civ:Dictionary)->float:
	var pop:=float(civ.get("population",100.0))
	var towns:=maxf(1.0,float(civ.get("settlement_count",civ.get("territory",1.0))))
	var dens:=clampf(pop/towns/5000.0,0.02,1.0)
	return clampf(0.1+0.6*dens+0.3*clampf(float(civ.get("trade_total",0.0))/500.0,0.0,1.0),0.0,1.0)

static func _open_stranger(day:int,x:Dictionary,civ:Dictionary)->void:
	var s:=state()
	var rng:=_rng("stranger:%d" % day)
	var civ_id:=String(civ.get("id",""))
	var civ_name:=String(civ.get("name","the strangers"))
	var pool:=_civ_pool(civ)
	var virgin:=pool-float(s.pool)>0.3
	# Between peoples whose sickness pools are alike the catalog exchanges no
	# new killer, only the ordinary fevers each side carries: a milder wave.
	# Only a far richer pool (a much more crowded people) brings virgin soil.
	var v:=0.2 if virgin else _lognormal(rng,0.02,0.8,0.004,0.2)
	var c:=_new("stranger","stranger_sickness","the %s Fever" % civ_name.trim_prefix("The ").trim_prefix("the "),day,x,{"v":v,"virgin":virgin,"civ_id":civ_id,"civ_name":civ_name,"their_pool":pool,
		"mid_day":day+rng.randi_range(14,24),"end_day":day+rng.randi_range(50,90)})
	_plan_deaths(c,_mortality(v,x,pool,rng))
	c.signs=_signs(x,"stranger")
	var sick:=clampi(roundi(float(x.pop)*(0.06+3.0*float(c.m))),3,maxi(3,int(float(x.pop)/2.0)))
	c["sick"]=sick
	var summary:="A fever came in with the last who walked back from %s. %s are sick with it, and it spreads from hearth to hearth." % [_the(civ_name),_cap(_count(sick))]
	_file(c,"open",summary,"comes about the strangers' sickness",int(c.decide_by))
	_announce(c,"The Strangers' Sickness",summary)

static func _open_drought(day:int,x:Dictionary)->void:
	var rng:=_rng("drought:%d" % day)
	var sev:=clampf(1.0-float(x.weather_season),0.0,0.6)
	var c:=_new("drought","drought","the Dry Year of %s" % _year_words(day) if sev<0.2 else "the Year the Springs Failed",day,x,{"sev":sev,"mid_day":day+rng.randi_range(30,45),"end_day":day+rng.randi_range(90,130)})
	_plan_deaths(c,_lognormal(rng,0.002,1.0,0.0,0.05)*(1.0+4.0*sev))
	if sev>=0.18: c["severe"]=true; _stat("drought","severe")
	var summary:="The rain has not come. The gathering grounds are brown and the %s is low. What we gather this season will be about %d parts in ten of a good year." % ["river" if bool(x.river) else "water",clampi(roundi(float(x.weather_season)*10.0),3,9)]
	_file(c,"open",summary,"comes about the dry weather",int(c.decide_by))
	_announce(c,"The Rain Does Not Come",summary)

static func _open_cold(day:int,x:Dictionary)->void:
	var rng:=_rng("cold:%d" % day)
	var sev:=rng.randf_range(0.04,0.12)
	var vuln:=1.0-0.5*float(x.divers)
	var loss:=clampf(sev*vuln*1.3,0.02,0.2)
	var c:=_new("cold","dim_summer","the Dim Summer of %s" % _year_words(day),day,x,{"sev":loss,"severe":true,"mid_day":day+40,"end_day":day+rng.randi_range(200,300)})
	_stat("cold","severe")
	_plan_deaths(c,0.0)
	c.severe=true
	_policy(c,"cold",{"food_yield":-loss},365)
	var summary:="The sun has been dim for weeks, as if through smoke, and there was frost where there should be none. The gathering will be poor all year: about %d parts in ten less." % maxi(1,roundi(loss*10.0))
	_file(c,"open",summary,"comes about the dim sun",int(c.decide_by))
	_announce(c,"The Sun Is Dim",summary)

static func _open_flood(day:int,x:Dictionary)->void:
	var rng:=_rng("flood:%d" % day)
	var food_share:=rng.randf_range(0.10,0.35)
	var house_share:=rng.randf_range(0.08,0.30)
	var lost:=Hall._debit_player("Food",Hall.player_stock("Food")*food_share)
	var cap_before:=int(GameState.housing_capacity)
	var house_lost:=maxi(1,roundi(float(cap_before)*house_share))
	GameState.housing_capacity=maxi(int(float(x.pop)*0.5),cap_before-house_lost)
	var c:=_new("flood","flood","the High Water of %s" % _year_words(day),day,x,{"food_lost":lost,"house_lost":cap_before-int(GameState.housing_capacity),"mid_day":day+rng.randi_range(20,30),"end_day":day+rng.randi_range(55,80)})
	_plan_deaths(c,_lognormal(rng,0.003,1.0,0.0,0.04))
	if food_share>=0.25: c["severe"]=true; _stat("flood","severe")
	var summary:="The river came over its banks in the night. It took %s of food from the pits and the water stands in the lowest huts; %s families have no roof." % [_food_words(lost),_count(clampi(roundi(float(c.house_lost)/5.0),1,12))]
	_file(c,"open",summary,"comes about the flood",int(c.decide_by))
	_announce(c,"The River Comes In",summary)

static func _open_fire(day:int,x:Dictionary)->void:
	var rng:=_rng("fire:%d" % day)
	var food_share:=rng.randf_range(0.04,0.22)
	var house_share:=rng.randf_range(0.08,0.25)
	var lost:=Hall._debit_player("Food",Hall.player_stock("Food")*food_share)
	var timber:=float(GameState.resource_stockpiles.get("Timber",0.0))
	GameState.resource_stockpiles["Timber"]=maxf(0.0,timber*(1.0-rng.randf_range(0.1,0.4)))
	var cap_before:=int(GameState.housing_capacity)
	GameState.housing_capacity=maxi(int(float(x.pop)*0.5),cap_before-maxi(1,roundi(float(cap_before)*house_share)))
	var c:=_new("fire","fire","the Burning of %s" % _year_words(day),day,x,{"food_lost":lost,"house_lost":cap_before-int(GameState.housing_capacity),"mid_day":day+rng.randi_range(12,20),"end_day":day+rng.randi_range(40,60)})
	_plan_deaths(c,_lognormal(rng,0.002,1.1,0.0,0.03))
	GameState.population_health=clampf(GameState.population_health-0.01,0.02,0.97)
	var roofs:=clampi(roundi(float(c.house_lost)/5.0),1,12)
	var summary:="A fire got loose from a hearth and ran through %s huts before it was beaten out. %s of food burned with them." % [_count(roofs),_cap(_food_words(lost))]
	_file(c,"open",summary,"comes about the fire",int(c.decide_by))
	_announce(c,"Fire in the Camp",summary)

static func _watch_thinning(day:int,x:Dictionary)->void:
	## "The Land Is Thinning" is told once by consequence_engine; its next
	## telling becomes a decision instead of the same notice again.
	if float(x.ecology)>=0.55 or not _active_of("thinning").is_empty(): return
	var told:=int(GameState.last_simulation_event_days.get("ecology_strain",-100000))
	if told<0 or day-told<100: return
	var c:=_new("thinning","worn_land","the Worn Land of %s" % _year_words(day),day,x,{"mid_day":day+60,"end_day":day+180})
	_plan_deaths(c,0.0)
	# The notice is not told again while this is being settled, nor for years after.
	GameState.last_simulation_event_days["ecology_strain"]=day+1200
	var summary:="The gatherers walk half a day now for what they once found by the camp. The near ground is worn out: roots dug, game gone, the brush stripped."
	_file(c,"open",summary,"comes about the worn land",int(c.decide_by))
	_announce(c,"The Land Is Worn Out",summary)

# --------------------------------------------------------------------------
# Effects
# --------------------------------------------------------------------------

static func _policy(c:Dictionary,tag:String,effects:Dictionary,days:int,start_after:int=0)->void:
	## A timed effect on the simulation's own policy channels.
	var magnitude:=0.2
	var coefficients:={}
	for channel in effects: coefficients[channel]=float(effects[channel])/magnitude
	var day:=float(_day())
	GameState.active_modifiers.append({"id":"crisis_%s_%s" % [String(c.id),tag],"kind":"policy","effects":coefficients,"magnitude":magnitude,
		"started_day":day+float(start_after),"until_day":day+float(start_after+days),"description":"%s: %s" % [String(c.name),tag.replace("_"," ")],"crisis":String(c.id)})

static func _metric(key:String,delta:float)->void:
	var m:Dictionary=GameState.simulation_metrics
	m[key]=clampf(float(m.get(key,0.5))+delta,0.01,0.99)

static func _health(delta:float)->void:
	GameState.population_health=clampf(GameState.population_health+delta,0.02,0.97)
	GameState.simulation_metrics["health"]=GameState.population_health

static func _bonds_all(deltas:Dictionary)->void:
	for person in Hall._officials(): GovernmentPeopleSystem.adjust_person_bonds(int(person.person_id),deltas)

static func _give_food(amount:float)->float:
	if amount<=0.0: return 0.0
	return float(EXCHANGE.receive("player","Food",amount))

static func _take_from_civ(civ_id:String,amount:float)->float:
	var index:=Hall._civ_index(civ_id)
	if index<0: return 0.0
	var civ:Dictionary=WorldSimulation.world.civilizations[index]
	var pop:=maxf(1.0,float(civ.get("population",1.0)))
	var have:=float(civ.get("food_days",0.0))*pop
	var taken:=minf(amount,have*0.25)
	civ["food_days"]=maxf(0.0,float(civ.get("food_days",0.0))-taken/pop)
	return taken

static func _neighbour(for_raid:bool)->Dictionary:
	## The people best placed to help (or to be robbed): met, nearest in regard.
	var best:Dictionary={}; var best_score:=-INF
	for civ in _contacts():
		var rel:Dictionary=civ.get("player_relation",{})
		if bool(rel.get("at_war",false)) and not for_raid: continue
		var score:=float(rel.get("opinion",0.0))*(-1.0 if for_raid else 1.0)+float(civ.get("food_days",30.0))/60.0
		if score>best_score: best_score=score; best=civ
	return best

static func _kill(c:Dictionary,count:int,salt:String)->int:
	## Deaths come out of the one aggregate population, never below the
	## shock_widening floor.
	if count<=0: return 0
	var floor_count:=maxi(FLOOR_PEOPLE,roundi(float(c.pop0)*FLOOR_SHARE))
	var allowed:=mini(count,maxi(0,GameState.population_total-floor_count))
	if allowed<=0: return 0
	var cause:=String((TYPES[String(c.type)] as Dictionary).cause)
	var result:=GameState.register_population_deaths(allowed,cause if cause!="" else "Hardship")
	var n:=int(result.get("count",0))
	c.deaths=int(c.deaths)+n
	var names:=_dead_names(mini(n,3),"%s:%s" % [String(c.id),salt])
	for name in names: (c.dead as Array).append(name)
	_stat(String(c.type),"deaths",float(n))
	return n

static func _due_deaths(c:Dictionary,share:float,salt:String)->int:
	var expected:=float(c.pop0)*float(c.m)*float(c.mult)*share
	var n:=floori(expected+_rng("due:%s:%s" % [String(c.id),salt]).randf())
	return _kill(c,n,salt)

# --------------------------------------------------------------------------
# Advancing a crisis
# --------------------------------------------------------------------------

static func _matter_alive(c:Dictionary)->bool:
	var id:=String(c.get("matter",""))
	if id=="": return false
	for m in Hall.state().matters:
		if m is Dictionary and String(m.get("id",""))==id: return true
	return _waiting_audience(c)!=""

static func _waiting_audience(c:Dictionary)->String:
	for audience in Hall.state().queue:
		if not audience is Dictionary or String(audience.get("status",""))!="waiting": continue
		var part:Dictionary=(audience.get("situation",{}) as Dictionary).get("crisis",{}) if (audience.get("situation",{}) as Dictionary).get("crisis") is Dictionary else {}
		if String(part.get("id",""))==String(c.id): return String(audience.get("id",""))
	return ""

static func _withdraw(c:Dictionary)->void:
	## The moment has passed: the matter leaves the court.
	var id:=String(c.get("matter",""))
	var list:Array=Hall.state().matters
	for m in list.duplicate():
		if m is Dictionary and String(m.get("id",""))==id: list.erase(m)
	var aid:=_waiting_audience(c)
	if aid!="":
		var audience:=Hall.find(aid)
		audience.status="expired"; audience.outcome="%s acted without the god's word." % String(c.holder)
		Hall._archive(audience)
	c.matter=""

static func _advance(c:Dictionary,day:int,x:Dictionary)->void:
	var phase:=String(c.phase)
	# Silence: the holder acts on their own judgement.
	if phase=="open" and String(c.choice)=="" and day>=int(c.decide_by):
		_withdraw(c)
		var pick:=_default_choice(c,"open")
		_apply(c,pick,"open",true)
	if phase=="mid" and String(c.mid_choice)=="" and String(c.get("matter_phase",""))=="mid" and day>=int(c.get("mid_decide_by",day+1)):
		_withdraw(c)
		_apply(c,_default_choice(c,"mid"),"mid",true)
	if phase=="remember" and String(c.get("rite",""))=="" and day>=int(c.get("remember_by",day+1)):
		_withdraw(c)
		_apply(c,"cairn","remember",true)
	if phase=="open" and day>=int(c.mid_day):
		_mid(c,day,x)
	elif phase in ["open","mid"] and day>=int(c.end_day):
		_end(c,day,x)
	elif phase=="remember" and String(c.get("rite",""))!="":
		_close(c)

static func _mid(c:Dictionary,day:int,x:Dictionary)->void:
	c.phase="mid"
	var type:=String(c.type)
	if String(c.choice)=="":
		# Still undecided at the turn: the holder acts now.
		_withdraw(c)
		_apply(c,_default_choice(c,"open"),"open",true)
	var n:=_due_deaths(c,0.4,"mid")
	var text:=""
	var needs:=false
	var names:Array=c.dead
	var dead_words:=""
	if n>0:
		dead_words=" %s died%s." % [_cap(_count(n)),(": "+", ".join(PackedStringArray(names.slice(maxi(0,names.size()-mini(n,3)),names.size())))) if not names.is_empty() else ""]
	match type:
		"sickness","stranger":
			var left:=float(c.pop0)*float(c.m)*float(c.mult)*0.6
			text="%s still has hold of the camp.%s" % [_cap(String(c.name)),dead_words]
			needs=left>=1.5 or bool(c.get("virgin",false))
			if needs: text+=" It has reached the children's fire."
		"hunger":
			var still:=float(x.food_days)<25.0 or float(x.intake)<0.95
			text="%s: the stores stand at about %d days.%s" % [_cap(String(c.name)),roundi(float(x.food_days)),dead_words]
			needs=still
			if needs: text+=" They will not reach the thaw."
		"drought":
			var dry:=_weather_mean(day-18,day+24)<0.9
			text=("The dry weather holds." if dry else "Rain came at last, though late.")+dead_words
			needs=dry
			if needs: text+=" The springs near camp are failing."
		"flood":
			text="The water is going down. It left mud in every hut and stores spoiled by damp.%s" % dead_words
		"fire":
			text="The ash is cold.%s" % dead_words
			if String(c.choice)=="rebuild": text+=" The huts are going back up."
		"cold":
			text="Frost again at midsummer. The berries are small and few."
		"thinning":
			text=String({"range":"The gatherers leave before light and come back after dark. The near ground is quiet.","rest":"The near ground is left alone. The pits fill more slowly.","burn_brush":"Green shoots are coming through the ash. The deer are back at the edge of it.","press":"The gatherers still work the same worn ground."}.get(String(c.choice),"The gatherers go on as before."))
	(c.notes as Array).append(text)
	_record(c,"mid",_cap(String(c.name)),text,"moment" if n>0 or needs else "notice","death" if n>0 else "omen",needs)
	_log("mid",text,{"type":type,"crisis":String(c.id),"deaths":n,"decision":needs})
	if needs:
		c["mid_decide_by"]=day+MID_DECIDE_DAYS
		c.end_day=maxi(int(c.end_day),day+MID_DECIDE_DAYS+14)
		var ask:=text
		_file(c,"mid",ask,"comes back about %s" % String(c.name).to_lower(),int(c.mid_decide_by))

static func _end(c:Dictionary,day:int,x:Dictionary)->void:
	if String(c.phase)=="mid" and String(c.get("matter_phase",""))=="mid" and String(c.mid_choice)=="":
		_withdraw(c)
		_apply(c,_default_choice(c,"mid"),"mid",true)
	var n:=_due_deaths(c,0.6,"end")
	var type:=String(c.type)
	var total:=int(c.deaths)
	var dead:Array=c.dead
	var names:=_dead_words(total,dead)
	var helpers:=_people_names(1,"helper:%s" % String(c.id))
	var helper:=String(helpers[0]) if not helpers.is_empty() else ""
	c.helpers=helpers
	var text:=""
	match type:
		"sickness","stranger":
			text="%s has passed. " % _cap(String(c.name))
			text+=("It took %s. " % names) if total>0 else "No one died of it. "
			if helper!="": text+="%s sat with the sick every night and did not fall ill; the people remember it. " % helper
			# Survivors are harder to kill with the same sickness; and a people
			# that lived through one learns to keep the sick apart (catalog R).
			var s:=state()
			s.immunity=maxf(float(s.immunity),minf(0.85,0.35+4.0*float(c.m)))
			if type=="stranger":
				var gap:=maxf(0.0,float(c.get("their_pool",0.0))-float(s.pool))
				s.pool=float(s.pool)+(0.35*gap if bool(c.get("virgin",false)) else maxf(0.0,0.9*float(c.get("their_pool",0.0))-float(s.pool)))
			_health(0.15*float(c.m))
			if float(c.m)>=0.02 or String(c.choice)=="apart": (s.flags as Dictionary)["apart_custom"]=true
			var v:=float(c.get("v",0.0))
			var echoes:=int(c.get("echo_count",0))
			if v>=0.03 and echoes<6 and _rng("echo:%s" % String(c.id)).randf()<minf(0.8,0.9 if bool(c.get("virgin",false)) else 2.0*v):
				var gap_years:=_rng("echoy:%s" % String(c.id)).randi_range(8,20)
				(s.echoes as Array).append({"count":echoes+1,"day":day+gap_years*365,"v":v*(0.75 if bool(c.get("virgin",false)) else _rng("echov:%s" % String(c.id)).randf_range(0.35,0.75)),"civ_id":String(c.get("civ_id",""))})
				while (s.echoes as Array).size()>24: (s.echoes as Array).pop_front()
		"hunger":
			text="%s is over; the land gives again. " % _cap(String(c.name))
			text+=("It took %s. " % names) if total>0 else "No one starved. "
			if helper!="": text+="%s found roots under the snow when others had stopped looking. " % helper
		"drought":
			text="The rains came back. "+(("The dry year took %s. " % names) if total>0 else "Everyone lived through the dry year. ")
		"flood":
			text="The river is back in its bed. "+(("It drowned %s. " % names) if total>0 else "No one drowned. ")
			if String(c.choice)=="wait": (state().until as Dictionary)["after_flood"]=day+60
		"fire":
			text="The camp has its roofs again. "+(("The fire killed %s. " % names) if total>0 else "The fire killed no one. ")
			GameState.housing_capacity=int(GameState.housing_capacity)+int(float(c.get("house_lost",0))*(1.0 if String(c.choice) in ["apart","earth"] else 0.0))
		"cold":
			text="The sun is clear again. It was a hungry year, and the people are glad to see it end. "
		"thinning":
			var eco:=float(x.ecology)
			text="The gatherers say the near ground %s. " % ("is coming back" if eco>=float(c.get("eco0",eco)) else "is still worn")
	if String(c.get("silent_note",""))!="": text+=String(c.silent_note)
	(c.notes as Array).append(text)
	if type in ["flood"] and String(c.choice) in ["high_ground","mounds"]:
		GameState.housing_capacity=int(GameState.housing_capacity)+int(float(c.get("house_lost",0))*0.8)
	_record(c,"end","After %s" % String(c.name),text.strip_edges(),"moment","death" if total>0 else "ceremony",false)
	_log("end",text,{"type":type,"crisis":String(c.id),"deaths":total,"severe":bool(c.get("severe",false)),"m":float(c.m),"mult":float(c.mult)})
	var hist:Dictionary={"id":String(c.id),"type":type,"name":String(c.name),"start":int(c.start),"end":day,"deaths":total,"dead":dead.slice(0,6),"choice":String(c.choice),"mid_choice":String(c.mid_choice),"severe":bool(c.get("severe",false)),"m":float(c.m)}
	var hl:Array=state().history
	hl.push_front(hist)
	while hl.size()>HISTORY_MAX: hl.pop_back()
	if total>=2 and Hall._official(int(c.holder_pid)).size()>0:
		c.phase="remember"
		c["rite"]=""
		c["remember_by"]=day+MID_DECIDE_DAYS
		_file(c,"remember","%s is over. %s died of it. The families ask how they are to be remembered." % [_cap(String(c.name)),_cap(_count(total))],"comes from the burials",int(c.remember_by))
		return
	_close(c)

static func _close(c:Dictionary)->void:
	c.phase="done"
	(state().active as Dictionary).erase(String(c.id))

# --------------------------------------------------------------------------
# The court: staging, options, answers
# --------------------------------------------------------------------------

static func _crisis_of(audience:Dictionary)->Dictionary:
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	var part:Dictionary=situation.get("crisis",{}) if situation.get("crisis") is Dictionary else {}
	var c:Variant=(state().active as Dictionary).get(String(part.get("id","")),{})
	return c if c is Dictionary else {}

static func _phase_of(audience:Dictionary)->String:
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	return String((situation.get("crisis",{}) as Dictionary).get("phase","open")) if situation.get("crisis") is Dictionary else "open"

static func _line(audience:Dictionary,person:Dictionary,text:String,aside:bool=false)->void:
	if text.strip_edges()=="": return
	Hall.append_line(String(audience.id),{"speaker":String(person.get("name","")),"role":"official","person_id":int(person.get("person_id",0)),"civ_id":"player","text":text,"day":_day(),"aside":aside})

static func _narrate(audience:Dictionary,text:String)->void:
	if text.strip_edges()=="": return
	Hall.append_line(String(audience.id),{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":text,"day":_day(),"aside":false})

static func on_open(audience:Dictionary)->void:
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	if String(situation.get("type",""))!="crisis": return
	var c:=_crisis_of(audience)
	if c.is_empty(): return
	var speaker:Dictionary=audience.get("speaker",{})
	var holder:=GovernmentPeopleSystem.person_snapshot(int(speaker.get("person_id",0)))
	if holder.is_empty(): holder={"person_id":int(speaker.get("person_id",0)),"name":String(speaker.get("name",""))}
	var phase:=_phase_of(audience)
	var given:=_given(String(holder.get("name","")))
	match phase:
		"mid":
			_narrate(audience,"[%s comes back in, tired, %s.]" % [given,String({"sickness":"smelling of the sick fire","stranger":"smelling of the sick fire","hunger":"thinner than before","drought":"with dust to the knees"}.get(String(c.type),"and sits down heavily"))])
			_line(audience,holder,"%s What do you want done now?" % String((c.notes as Array).back() if not (c.notes as Array).is_empty() else String(c.name)))
		"remember":
			_narrate(audience,"[%s comes from the burial ground. Behind them, the families wait outside.]" % given)
			var dead:Array=c.dead
			var who:=(" %s among them." % ", ".join(PackedStringArray(dead.slice(0,mini(3,dead.size()))))) if not dead.is_empty() else ""
			_line(audience,holder,"We buried %s.%s The families ask how they are to be remembered, and whether the god saw." % [_count(int(c.deaths)),who])
		_:
			_narrate(audience,"[%s comes in quickly and does not sit.]" % given)
			_line(audience,holder,String((audience.get("petition",{}) as Dictionary).get("summary",""))+" "+_ask_line(c))
			var second:=_second_voice(int(holder.get("person_id",0)))
			var aside:=_aside(c)
			if not second.is_empty() and aside!="": _line(audience,second,aside,true)

static func _ask_line(c:Dictionary)->String:
	match String(c.type):
		"sickness","stranger": return "If we keep them apart now, it may stop with them. Their kin will not like it."
		"hunger": return "We can make the stores stretch, or go and find more. Not both."
		"drought": return "Water first, then food. Tell me which we give up."
		"flood": return "The stores or the huts first. There are not hands for both."
		"fire": return "We can rebuild as it was, fast, or build it differently and be cold longer."
		"thinning": return "We walk farther, or we let this ground rest and eat less for a while."
		"cold": return "We can gather everything now, before it gets worse, or make what we have last."
	return ""

static func _aside(c:Dictionary)->String:
	## A second official speaks only when they have a real stake.
	match String(c.type):
		"sickness","stranger":
			if float(c.get("sick",0))>=6: return "Some of mine are at that fire. If you set them apart, let someone take them food."
		"hunger":
			if not _neighbour(false).is_empty(): return "%s have full pits this year. They may give, if we ask." % _cap(_the(String(_neighbour(false).get("name",""))))
		"fire":
			return "The fire started where the huts touch. They are too close."
	return ""

static func _opt(id:String,label:String,sub:String,tone:String,extra:Dictionary={})->Dictionary:
	var o:=Hall._option(id,label,sub,tone,bool(extra.get("enabled",true)),String(extra.get("reason","")))
	for key in ["cost","objection","support"]:
		if extra.has(key) and String(extra[key])!="": o[key]=String(extra[key])
	return o

static func options(audience:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var c:=_crisis_of(audience)
	var phase:=_phase_of(audience)
	if c.is_empty() or (phase=="open" and String(c.choice)!="") or (phase=="mid" and String(c.mid_choice)!="") or (phase=="remember" and String(c.get("rite",""))!=""):
		out.append(Hall._option("crisis_past","It is past","This has already been settled.","neutral"))
		return out
	if phase=="remember": return _remember_options(c)
	if phase=="mid": return _mid_options(c)
	var type:=String(c.type)
	match type:
		"hunger":
			out.append(_opt("ration","Cut every portion by a quarter","Until the land gives again. No one starves at once; everyone weakens, the old and the small most.","neutral",{"cost":"health"}))
			out.append(_opt("hunt","Send the strongest out to hunt far","A month away. They may bring back meat, or come back fewer.","neutral",{"cost":"labour"}))
			var friend:=_neighbour(false)
			if not friend.is_empty():
				out.append(_opt("ask","Ask %s for food" % _the(String(friend.get("name",""))),"They may give. They will remember that we asked.","warm"))
			var mark:=_neighbour(true)
			if not mark.is_empty():
				out.append(_opt("raid","Take food from %s's pits" % _the(String(mark.get("name",""))),"Food tonight. They will know who took it.","hostile",{"cost":"String: their anger","objection":"If we rob them now they will come for it when we are weakest." if Hall._officials().size()>1 else ""}))
			if unlocked("hunger:seed"): out.append(_opt("seed","Eat the seed","No one dies of hunger this winter. Next year's sowing will be thin.","neutral",{"cost":"next year"}))
			if unlocked("hunger:pots"): out.append(_opt("pots","Keep the pots boiling: bones, roots, bark","It stretches what we have. It tastes of nothing.","neutral"))
			if unlocked("hunger:herd"): out.append(_opt("herd","Kill from the tame herd","Meat now. Fewer young animals in spring.","neutral",{"cost":"herd"}))
			out.append(_opt("speak","Go among them as their god","It feeds no one. It may hold them together.","warm"))
		"sickness","stranger":
			var better:=unlocked("sickness:apart_plus") or bool((state().flags as Dictionary).get("apart_custom",false))
			out.append(_opt("apart","Keep the sick at their own fire","Their kin will hate it. %s" % ("We know how to do this now; it works if done early." if better else "Done now, it may stop the spread."),"neutral",{"cost":"cohesion","objection":"You would leave them alone in the dark?" if float(c.get("sick",0))>=6 and Hall._officials().size()>1 else ""}))
			out.append(_opt("tend","Everyone tends the sick","No one is left alone. More will catch it.","warm",{"cost":"String: more will fall sick"}))
			if unlocked("sickness:herbs"): out.append(_opt("herbs","Send for the plant-knowers","Bitter roots and bark. It eases more than it cures.","warm"))
			if unlocked("sickness:water"): out.append(_opt("water","Boil the water; move the drinking place upstream","Firewood and walking. It stops the flux where it starts.","neutral",{"cost":"labour"}))
			if type=="stranger":
				var civ_name:=_the(String(c.get("civ_name","the strangers")))
				out.append(_opt("close","Close the path to %s" % civ_name,"No one comes or goes until it passes. They will take it as an insult.","hostile",{"cost":"String: their regard"}))
				out.append(_opt("healers","Ask %s for their healers" % civ_name,"They have lived with this sickness. They will see how weak we are.","warm"))
			else:
				out.append(_opt("burn","Burn the sick huts and sleep elsewhere","Shelter lost before the cold. What is burned cannot carry it.","hostile",{"cost":"housing"}))
			out.append(_opt("rite","Call them to the fire to hear their god","It will not cool a fever. It will steady them.","warm"))
		"drought":
			out.append(_opt("carry","Carry water from the far pools","Every strong back on the water path. Other work waits.","neutral",{"cost":"labour"}))
			out.append(_opt("ration","Ration now, before the pits empty","Less for everyone from today. They will be weak at the harvest.","neutral",{"cost":"health"}))
			if unlocked("drought:hardy_seed"): out.append(_opt("hardy","Sow the seed that needs little water","Some of the ground will still give. The rest is lost this year anyway.","neutral"))
			out.append(_opt("rain","Tell them their god will bring rain","If it rains, they will never forget. If it does not, they will remember that too.","warm",{"cost":"String: your word"}))
		"cold":
			out.append(_opt("gather","Gather everything now, before it worsens","Every hand out while there is anything to find. Other work waits.","neutral",{"cost":"labour"}))
			out.append(_opt("ration","Make what we have last","Smaller portions all year. The small ones will feel it.","neutral",{"cost":"health"}))
			out.append(_opt("speak","Tell them the sun will come back","They are frightened. You are their god.","warm"))
		"flood":
			out.append(_opt("high_ground","Move the hearths up the slope, for good","A hard month of carrying. The river will not reach us there again.","neutral",{"cost":"labour"}))
			out.append(_opt("save_stores","Carry the stores out first","Most of the food can still be saved. The water is fast; someone may drown.","neutral",{"cost":"String: a life, maybe"}))
			if unlocked("flood:boats"): out.append(_opt("boats","Take the stores and the old out by boat","Slower, and no one needs to wade.","warm"))
			if unlocked("flood:mounds"): out.append(_opt("mounds","Raise the huts on mounds when the water drops","A season of digging. The next flood will pass under them.","neutral",{"cost":"labour"}))
			out.append(_opt("wait","Wait for the water to go down","Nothing more is lost to effort. Standing water breeds sickness.","neutral"))
		"fire":
			out.append(_opt("rebuild","Rebuild at once, as it was","Everyone to it; timber from the stack. The huts will be as close as before.","neutral",{"cost":"timber"}))
			out.append(_opt("apart","Rebuild the huts apart, hearths outside","Slower, colder for a while. A fire will not jump so easily.","neutral",{"cost":"time"}))
			if unlocked("fire:earth"): out.append(_opt("earth","Rebuild in earth that will not burn","Clay and months of work. The next fire stops at the wall.","neutral",{"cost":"clay"}))
			out.append(_opt("blame","Find who let it loose and punish them","Someone was careless. The people will fear your eye.","hostile",{"cost":"String: fear"}))
			out.append(_opt("rite","Give the ashes to the god","A fire of thanks that it was not worse. They will feel you are with them.","warm"))
		"thinning":
			out.append(_opt("range","Walk farther for food","Longer days for the gatherers; the near ground gets a rest.","neutral",{"cost":"labour"}))
			out.append(_opt("rest","Rest the near ground for a year","Less food this year. The roots and game come back.","neutral",{"cost":"food"}))
			out.append(_opt("burn_brush","Burn the old brush for new growth","New shoots and game in a season. Fire near the camp is a risk.","hostile",{"cost":"String: fire risk"}))
			out.append(_opt("press","Press on as we are","Nothing changes. The land will thin further.","neutral"))
	return out

static func _mid_options(c:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	match String(c.type):
		"sickness","stranger":
			out.append(_opt("children_apart","Keep the children away from the sick","Mothers kept from sick children. They will not forgive it easily.","neutral",{"cost":"cohesion"}))
			out.append(_opt("mothers","Let the mothers nurse their own","It is what they want. The sickness will go where they go.","warm",{"cost":"String: more sick"}))
			out.append(_opt("far_camp","Take the well to a camp upstream","A day's walk out and back. Clean water and air, and fewer hands at home.","neutral",{"cost":"labour"}))
			out.append(_opt("stay","Change nothing","Let it run its course as it is.","neutral"))
		"hunger":
			var friend:=_neighbour(false)
			out.append(_opt("send_away","Send some families away to kin %s" % (("among %s" % _the(String(friend.get("name","")))) if not friend.is_empty() else "in the far valleys"),"Fewer mouths. Some of them will not come back.","neutral",{"cost":"String: people leave"}))
			out.append(_opt("roots","Everyone out for roots and bark","Hard work on empty bellies. It keeps them alive.","neutral",{"cost":"labour"}))
			if String(c.choice)!="raid" and not _neighbour(true).is_empty():
				out.append(_opt("raid","Take food from %s's pits" % _the(String(_neighbour(true).get("name",""))),"Food tonight. They will know who took it.","hostile",{"cost":"String: their anger"}))
			out.append(_opt("hold","Hold on as we are","The god's people endure.","neutral"))
		"drought":
			out.append(_opt("river_camp","Move the sleeping places to the river","A long carry of everything. Water every day.","neutral",{"cost":"labour"}))
			out.append(_opt("send_hunters","Send the hunters after the game to the wet ground","Meat, if they find it, and fewer mouths at home.","neutral"))
			out.append(_opt("hold","Hold on as we are","Wait for the rain.","neutral"))
	return out

static func _remember_options(c:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var food:=Hall._nice(clampf(float(GameState.population_total)*0.2,6.0,60.0))
	var short:=Hall._short("Food",food)
	out.append(_opt("pyre","A great fire for the dead","%d Food shared at the fire, and their names said aloud. The families will love you for it." % roundi(food),"warm",{"enabled":short=="","reason":short,"cost":"food"}))
	out.append(_opt("cairn","A cairn where they lie","Stones carried by everyone. It will stand after we are gone.","warm",{"cost":"labour"}))
	out.append(_opt("rest_no_rite","No rite: back to work","The living need hands. The families will say the god did not see.","hostile",{"cost":"String: grief"}))
	return out

static func _default_choice(c:Dictionary,phase:String)->String:
	## What the holder does when the god is silent: the careful course.
	if phase=="mid":
		return String({"sickness":"children_apart","stranger":"children_apart","hunger":"roots","drought":"hold"}.get(String(c.type),"hold"))
	match String(c.type):
		"hunger": return "ration"
		"sickness","stranger": return "apart" if bool((state().flags as Dictionary).get("apart_custom",false)) else "tend"
		"drought": return "carry"
		"cold": return "ration"
		"flood": return "wait"
		"fire": return "rebuild"
		"thinning": return "range"
	return ""

static func resolve(audience:Dictionary,option_id:String)->Dictionary:
	var c:=_crisis_of(audience)
	if option_id=="crisis_past" or c.is_empty(): return {"outcome":"It had already been settled.","reaction":"neutral"}
	var phase:=_phase_of(audience)
	if phase=="open" and String(c.choice)!="": return {"error":"That has already been decided."}
	if phase=="mid" and String(c.mid_choice)!="": return {"error":"That has already been decided."}
	c.matter=""
	var result:=_apply(c,option_id,phase,false)
	if result.has("error"): return result
	_stat(String(c.type),"decisions")
	return result

static func _apply(c:Dictionary,option_id:String,phase:String,silent:bool)->Dictionary:
	## Carries out a choice. Returns {outcome, reaction}.
	var type:=String(c.type)
	var pid:=int(c.holder_pid)
	var pop:=float(maxi(1,GameState.population_total))
	var outcome:=""
	var reaction:="pleased"
	var rng:=_rng("apply:%s:%s:%s" % [String(c.id),phase,option_id])
	if phase=="remember":
		c["rite"]=option_id
		match option_id:
			"pyre":
				var paid:=Hall._debit_player("Food",Hall._nice(clampf(pop*0.2,6.0,60.0)))
				_bonds_all({"love":0.04,"hold_days":60})
				_metric("cohesion",0.01)
				Lives._mark_rite("pyre","for the dead of %s" % String(c.name),_day(),5,pid)
				outcome="A great fire for the dead of %s. %d Food shared, and every name said aloud." % [String(c.name),roundi(paid)]
				reaction="delighted"
			"cairn":
				_policy(c,"cairn",{"labor_multiplier":-0.03},20)
				_bonds_all({"love":0.02,"trust":0.02})
				Lives._mark_rite("cairn","for the dead of %s" % String(c.name),_day(),10,pid)
				outcome="A cairn stands over the dead of %s. Everyone carried a stone." % String(c.name)
			_:
				c["rite"]="rest_no_rite"
				_bonds_all({"love":-0.02,"fear":0.02})
				_metric("cohesion",-0.01)
				outcome="No rite for the dead of %s. The families buried them and went back to work." % String(c.name)
				reaction="neutral"
		_after(c,phase,option_id,outcome,silent)
		return {"outcome":outcome,"reaction":reaction}
	if phase=="mid":
		c.mid_choice=option_id
		match option_id:
			"children_apart":
				c.mult=float(c.mult)*0.7; _metric("cohesion",-0.006)
				outcome="The children were kept from the sick. Their mothers wept at the edge of the fire."
			"mothers":
				c.mult=float(c.mult)*1.15; _bonds_all({"love":0.02})
				outcome="The mothers nursed their own. The sickness went where they went."
				reaction="delighted"
			"far_camp":
				c.mult=float(c.mult)*0.65; _policy(c,"far_camp",{"labor_multiplier":-0.07},30)
				outcome="The well walked a day upstream to clean water. Fewer hands are left at home."
			"send_away":
				var friend:=_neighbour(false)
				var n:=maxi(1,roundi(pop*0.05))
				var gone:=int(GameState.register_population_departures(n,"Sent away in %s" % String(c.name)).get("count",0))
				c.mult=float(c.mult)*0.55
				if not friend.is_empty(): ForeignDiplomacy.remember(String(friend.id),"Families of the god's people came to us in their hungry winter.")
				outcome="%s families' worth of people, %d in all, went away to %s. Fewer mouths at the fire." % [_cap(_count(maxi(1,gone/4))),gone,_the(String(friend.get("name",""))) if not friend.is_empty() else "the far valleys"]
				reaction="neutral"
			"roots":
				c.mult=float(c.mult)*0.8; _policy(c,"roots",{"labor_multiplier":-0.08},30)
				var got:=_give_food(Hall._nice(pop*0.25))
				outcome="Everyone went out for roots and bark and brought back %d Food. It kept them alive." % roundi(got)
			"raid":
				return _raid(c,phase,silent)
			"river_camp":
				_policy(c,"river_camp",{"water_collection":0.35,"labor_multiplier":-0.06},60)
				c.mult=float(c.mult)*0.6
				outcome="The sleeping places moved down to the river. Water every day, and a long carry."
			"send_hunters":
				var got2:=_give_food(Hall._nice(pop*rng.randf_range(0.1,0.5)))
				outcome="The hunters went after the game to the wet ground and sent back %d Food." % roundi(got2)
			"hold","stay":
				outcome="Nothing changed. The god's people endure it."
				reaction="neutral"
			_:
				c.mid_choice=""
				return {"error":"That answer is not open to you here."}
		_after(c,phase,option_id,outcome,silent)
		return {"outcome":outcome,"reaction":reaction}
	c.choice=option_id
	match option_id:
		"ration":
			var cut:=0.25 if type=="hunger" else 0.15
			_policy(c,"ration",{"food_demand":-cut,"health_target":-0.02},100 if type!="cold" else 200)
			c.mult=float(c.mult)*0.6
			_metric("cohesion",-0.005)
			outcome="Every portion is smaller from today. The stores will last; the people are hungrier."
			reaction="neutral"
		"hunt":
			_policy(c,"hunt",{"labor_multiplier":-0.06},40)
			c.mult=float(c.mult)*0.8
			var got:=_give_food(Hall._nice(pop*rng.randf_range(0.15,0.8)))
			var lost_hunter:=rng.randf()<0.3
			outcome="The hunters went far and came back with %d Food." % roundi(got)
			if lost_hunter and _kill(c,1,"hunter")>0: outcome+=" %s did not come back." % String((c.dead as Array).back()).get_slice(",",0)
		"ask":
			var friend:=_neighbour(false)
			if friend.is_empty(): c.choice=""; return {"error":"There is no one to ask."}
			var rel:Dictionary=friend.get("player_relation",{})
			var p:Dictionary=Hall._personality(String(friend.id))
			var yes:=rng.randf()<clampf(0.35+float(rel.get("opinion",0.0))+0.3*float(p.get("empathy",0.5)),0.05,0.95)
			if yes:
				var give:=_take_from_civ(String(friend.id),Hall._nice(pop*0.6))
				var got3:=_give_food(give)
				c.mult=float(c.mult)*(0.5 if got3>=pop*0.3 else 0.8)
				Hall._shift_relation(String(friend.id),0.02,-0.02)
				ForeignDiplomacy.remember(String(friend.id),"We fed the god's people in their hungry winter.")
				outcome="%s gave %d Food. They will remember that they fed us." % [_cap(_the(String(friend.name))),roundi(got3)]
				reaction="delighted"
			else:
				Hall._shift_relation(String(friend.id),-0.02,0.0)
				_metric("cohesion",-0.008)
				outcome="%s would not give. Their own pits come first, they said." % _cap(_the(String(friend.name)))
				reaction="offended"
		"raid":
			return _raid(c,phase,silent)
		"seed":
			c.mult=float(c.mult)*0.45
			_policy(c,"seed",{"food_yield":-0.15},300,60)
			outcome="The seed is eaten. No one will starve of this; next year's sowing will be thin."
		"pots":
			c.mult=float(c.mult)*0.75
			_policy(c,"pots",{"food_demand":-0.12},90)
			outcome="The pots are kept boiling day and night: bones, roots, bark. Nothing is wasted."
		"herd":
			c.mult=float(c.mult)*0.5
			var got4:=_give_food(Hall._nice(pop*0.8))
			_metric("cohesion",-0.004)
			outcome="Animals from the herd were killed: %d Food. There will be fewer young in spring." % roundi(got4)
		"speak":
			c.mult=float(c.mult)*0.95
			_bonds_all({"love":0.03,"fear":0.01,"hold_days":40})
			_metric("cohesion",0.01)
			outcome="You went among them as their god. It fed no one. They held together."
			reaction="delighted"
		"apart":
			var strong:=unlocked("sickness:apart_plus") or bool((state().flags as Dictionary).get("apart_custom",false))
			c.mult=float(c.mult)*(0.4 if strong else 0.55)
			_policy(c,"apart",{"disease_risk":-0.3},45)
			_metric("cohesion",-0.01)
			outcome="The sick were set at their own fire, with food left at the edge of the light. Their kin grumble."
			reaction="neutral"
		"tend":
			c.mult=float(c.mult)*1.25
			_policy(c,"tend",{"labor_multiplier":-0.05},30)
			_metric("cohesion",0.01); _bonds_all({"love":0.02})
			outcome="Everyone tends the sick. No one is alone; more are falling ill."
			reaction="delighted"
		"herbs":
			c.mult=float(c.mult)*0.75
			_policy(c,"herbs",{"health_target":0.03},45)
			outcome="The plant-knowers came with their bitter roots. The fevers break sooner."
		"water":
			c.mult=float(c.mult)*(0.5 if String(c.kind)=="flux" else 0.85)
			_policy(c,"water",{"disease_risk":-0.2,"labor_multiplier":-0.03},90)
			outcome="The water is boiled and the drinking place moved upstream. It costs firewood and walking."
		"burn":
			c.mult=float(c.mult)*0.6
			var cap:=int(GameState.housing_capacity)
			GameState.housing_capacity=maxi(int(pop*0.5),cap-maxi(1,roundi(float(cap)*0.08)))
			_metric("cohesion",-0.008)
			outcome="The sick huts were burned. People crowd in with their neighbours for now."
			reaction="neutral"
		"rite":
			c.mult=float(c.mult)*1.05
			_bonds_all({"love":0.03,"fear":0.01,"hold_days":40})
			_metric("cohesion",0.012)
			if type=="fire": _metric("cohesion",0.004); c.mult=float(c.mult)/1.05
			Lives._mark_rite("bonfire",String(c.name),_day(),4,pid)
			outcome="They came to the fire to hear their god. It cured no one. They went home steadier."
			reaction="delighted"
		"close":
			c.mult=float(c.mult)*0.55
			var civ_id:=String(c.get("civ_id",""))
			Hall._shift_relation(civ_id,-0.06,0.05)
			ForeignDiplomacy.remember(civ_id,"The god's people closed their path to us when their fever came, as if we were the sickness.")
			outcome="The path to %s is closed until the fever passes. They are insulted." % _the(String(c.get("civ_name","")))
			reaction="neutral"
		"healers":
			c.mult=float(c.mult)*0.7
			var civ_id2:=String(c.get("civ_id",""))
			Hall._shift_relation(civ_id2,0.02,0.0)
			DIVINE.add_civ_dread(civ_id2,-0.03)
			ForeignDiplomacy.remember(civ_id2,"We sent our healers to the god's people in their fever. They were weak and afraid.")
			outcome="%s sent two healers who know this sickness. They saw how weak we are." % _cap(_the(String(c.get("civ_name",""))))
		"carry":
			_policy(c,"carry",{"water_collection":0.3,"labor_multiplier":-0.06},90)
			c.mult=float(c.mult)*0.7
			outcome="Every strong back is on the water path. Other work waits."
		"hardy":
			_policy(c,"hardy",{"food_yield":0.06},180)
			c.mult=float(c.mult)*0.8
			outcome="The seed that needs little water is sown. Some of the ground will still give."
		"rain":
			_bonds_all({"love":0.02,"hold_days":30})
			Lives._watch_sky("rain","rain for %s" % String(c.name),_day(),pid)
			c["promised_rain"]=_weather(_day())
			outcome="You told them their god will bring rain. They watch the sky."
			reaction="delighted"
		"gather":
			_policy(c,"gather",{"labor_multiplier":-0.05,"food_yield":0.04},120)
			outcome="Every hand is out gathering while there is anything to find."
		"high_ground":
			_policy(c,"high_ground",{"labor_multiplier":-0.08},45)
			(state().flags as Dictionary)["moved_up"]=true
			outcome="The hearths are moving up the slope. It is a hard month of carrying; the river will not reach them there."
		"save_stores":
			var back:=_give_food(float(c.get("food_lost",0.0))*0.6)
			outcome="Most of the stores were carried out of the water: %d Food saved." % roundi(back)
			if rng.randf()<0.35 and _kill(c,1,"drowned")>0: outcome+=" %s was taken by the current." % String((c.dead as Array).back()).get_slice(",",0)
		"boats":
			var back2:=_give_food(float(c.get("food_lost",0.0))*0.7)
			_policy(c,"boats",{"labor_multiplier":-0.03},20)
			outcome="The stores and the old went out by boat: %d Food saved, no one in the water." % roundi(back2)
			reaction="delighted"
		"mounds":
			_policy(c,"mounds",{"labor_multiplier":-0.1},90)
			(state().flags as Dictionary)["mounds"]=true
			outcome="When the water drops, the huts go up on mounds. A season of digging."
		"wait":
			(state().until as Dictionary)["after_flood"]=_day()+75
			outcome="They waited for the water to go down. The ground stays wet and foul for weeks."
			reaction="neutral"
		"rebuild":
			var timber:=float(GameState.resource_stockpiles.get("Timber",0.0))
			var cost:=minf(timber,float(c.get("house_lost",0))*0.8)
			GameState.resource_stockpiles["Timber"]=timber-cost
			GameState.housing_capacity=int(GameState.housing_capacity)+int(float(c.get("house_lost",0))*(0.8 if cost>0.0 else 0.4))
			_policy(c,"rebuild",{"labor_multiplier":-0.08},20)
			outcome="Everyone is rebuilding; %d timber from the stack. The huts go back up as close as before." % roundi(cost)
		"earth":
			var clay:=float(GameState.resource_stockpiles.get("Clay",0.0))
			GameState.resource_stockpiles["Clay"]=maxf(0.0,clay-float(c.get("house_lost",0)))
			(state().flags as Dictionary)["earth"]=true
			_policy(c,"earth",{"labor_multiplier":-0.06},60)
			outcome="The burned huts go back up in clay and earth. It will take months."
		"blame":
			var culprit:=_people_names(1,"culprit:%s" % String(c.id))
			_bonds_all({"fear":0.04,"love":-0.02,"hold_days":45})
			_metric("cohesion",-0.012)
			outcome="%s was found to have left a fire unwatched and was driven from the camp for a season. The people watch their hearths, and you." % (culprit[0] if not culprit.is_empty() else "Someone")
			reaction="neutral"
		"range":
			_policy(c,"range",{"labor_multiplier":-0.05,"ecology_delta":0.0005},240)
			c["eco0"]=float(GameState.simulation_metrics.get("ecology",0.5))
			outcome="The gatherers walk farther out; the near ground is left alone."
		"rest":
			_policy(c,"rest",{"food_yield":-0.08,"ecology_delta":0.0009},365)
			c["eco0"]=float(GameState.simulation_metrics.get("ecology",0.5))
			outcome="The near ground rests for a year. Less food comes in."
		"burn_brush":
			_metric("ecology",0.03)
			_policy(c,"burn_brush",{"food_yield":0.03},180)
			(state().until as Dictionary)["burn"]=_day()+60
			c["eco0"]=float(GameState.simulation_metrics.get("ecology",0.5))
			outcome="The old brush was burned. Green shoots in a month; the camp smells of smoke."
		"press":
			c["eco0"]=float(GameState.simulation_metrics.get("ecology",0.5))
			outcome="Nothing changes. The land will thin further."
			reaction="neutral"
		_:
			c.choice=""
			return {"error":"That answer is not open to you here."}
	_after(c,phase,option_id,outcome,silent)
	return {"outcome":outcome,"reaction":reaction}

static func _raid(c:Dictionary,phase:String,silent:bool)->Dictionary:
	var mark:=_neighbour(true)
	if mark.is_empty():
		if phase=="mid": c.mid_choice=""
		else: c.choice=""
		return {"error":"There is no one to take from."}
	var pop:=float(maxi(1,GameState.population_total))
	var taken:=_take_from_civ(String(mark.id),Hall._nice(pop*0.6))
	var got:=_give_food(taken)
	c.mult=float(c.mult)*0.5
	Hall._shift_relation(String(mark.id),-0.2,0.25)
	DIVINE.add_civ_dread(String(mark.id),0.05)
	ForeignDiplomacy.remember(String(mark.id),"The god's people robbed our pits in their hungry winter.")
	var outcome:="The raiders came back from %s's pits with %d Food. They will know who took it." % [_the(String(mark.name)),roundi(got)]
	if _rng("raid:%s" % String(c.id)).randf()<0.3 and _kill(c,1,"raider")>0: outcome+=" %s was killed at the pits." % String((c.dead as Array).back()).get_slice(",",0)
	_after(c,phase,"raid",outcome,silent)
	return {"outcome":outcome,"reaction":"neutral"}

static func _after(c:Dictionary,phase:String,option_id:String,outcome:String,silent:bool)->void:
	var pid:=int(c.holder_pid)
	if silent:
		_stat(String(c.type),"silent")
		var note:="The god was silent. %s acted alone. " % _given(String(c.holder))
		c["silent_note"]=note if phase=="open" else String(c.get("silent_note",""))
		if pid>0: GovernmentPeopleSystem.adjust_person_bonds(pid,{"trust":-0.02})
		_record(c,"silent:%s" % phase,"%s Acts Alone" % _given(String(c.holder)),note+outcome,"notice","court",false)
	elif pid>0:
		GovernmentPeopleSystem.record_person_memory(pid,"In %s the god told us: %s" % [String(c.name),outcome.substr(0,120)],"crisis",0.7,{"emotion":"duty"})
	_log("silent" if silent else "decided",outcome,{"type":String(c.type),"crisis":String(c.id),"phase":phase,"option":option_id})

# --------------------------------------------------------------------------
# Typed words (online)
# --------------------------------------------------------------------------

const WORDS:={"ration":["ration","portion","smaller","less food"],"hunt":["hunt","hunters","game"],"ask":["ask","beg","trade for"],"raid":["raid","take their","steal","rob"],
	"apart":["apart","separate","away from the others","isolate","their own fire"],"tend":["tend","care for","nurse","look after"],"rite":["pray","rite","ceremony","offering"],
	"carry":["carry water","fetch water","water from"],"rain":["rain"],"high_ground":["higher","up the slope","high ground"],"save_stores":["stores","save the food"],
	"wait":["wait"],"rebuild":["rebuild","build again"],"blame":["punish","blame","who did"],"range":["farther","further","walk"],"rest":["rest the"],"press":["press on","carry on"],
	"children_apart":["children away","keep the children"],"mothers":["mothers"],"send_away":["send them","send families"],"roots":["roots","bark"],"hold":["hold on","endure"],
	"pyre":["fire for the dead","pyre","feast"],"cairn":["cairn","stones"],"rest_no_rite":["back to work","no rite"]}

static func typed_choice(audience_id:String,text:String)->String:
	## Online, the god may just say it: "Keep the sick apart." Returns the
	## option id their words name, or "".
	var audience:=Hall.find(audience_id)
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	if String(situation.get("type",""))!="crisis" or String(audience.get("status",""))!="waiting": return ""
	var lower:=" "+text.to_lower()+" "
	var open:Array=options(audience).filter(func(o:Dictionary)->bool:return bool(o.get("enabled",true))).map(func(o:Dictionary)->String:return String(o.id))
	var found:=""
	for id in WORDS:
		if not String(id) in open: continue
		for word in WORDS[id]:
			if lower.contains(String(word)):
				if found!="" and found!=String(id): return ""
				found=String(id)
	return found
