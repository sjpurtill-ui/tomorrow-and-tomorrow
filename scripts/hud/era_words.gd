extends RefCounted
## ERA WORDS: how the people themselves would count the numbers the HUD shows.
##
## A band that cannot write does not know "GDP", "IMR", "per mille" or "life
## expectancy". It knows how many bellies were filled today, how many winters
## a person lives, and how many children are lost before their first winter.
## Who went hungry today is told under PEOPLE, not as a second head count.
## Every place the HUD shows a vital statistic asks this layer for the words.
##
## Stages (from what the player's people know):
##   hearth    before writing: souls, winters, days of food, "17 in 100".
##   lettered  writing (the "writing" era gate): registers, years, "in 1,000".
##   reckoned  printing: the statistical age, where GDP, IMR and education
##             indices finally have a meaning.
##
## Services are gated too: no Navy before boats, no Air Force before flight.

const Voice:=preload("res://scripts/character_voice.gd")
## The first craft that can carry a fighting crew (the navy's first gate).
const BOATS:=["river_craft","reed_bundle_boats","hide_covered_boats","coastal_watercraft"]
## The first flight (the air service's first gate).
const FLIGHT:=["aerostat_observation","powered_flight"]
const STATISTICS:=["printing_process"]

static var _stage_signature:=-1
static var _stage:="hearth"


static func stage()->String:
	var known:Array=GameState.known_discoveries if Engine.get_main_loop()!=null else []
	# Recomputed at most once a frame (tests and loads swap what is known).
	var signature:=known.size()*100003+Engine.get_process_frames()
	if signature==_stage_signature:return _stage
	_stage_signature=signature
	_stage="hearth"
	for id in STATISTICS:
		if known.has(id):
			_stage="reckoned"
			return _stage
	if Voice.era_tags("player").has("writing"):_stage="lettered"
	return _stage


static func hearth()->bool:
	return stage()=="hearth"


static func reckoned()->bool:
	return stage()=="reckoned"


static func has_boats()->bool:
	return _knows_any(BOATS) or _owns_service("navy")


static func has_flight()->bool:
	return _knows_any(FLIGHT) or _owns_service("air")


static func _knows_any(ids:Array)->bool:
	if Engine.get_main_loop()==null:return false
	for id in ids:
		if GameState.known_discoveries.has(id):return true
	return false


static func _owns_service(domain:String)->bool:
	## A service the people already field (an old save, a captured fleet)
	## always stays reachable.
	if Engine.get_main_loop()==null or MilitaryCampaign.get("joint_operations")==null:return false
	var state:Dictionary=MilitaryCampaign.joint_operations.state
	for list_name in ["bases","forces"]:
		for record in state.get(list_name,[]):
			if record is Dictionary and String(record.get("owner",""))=="player" and String(record.get("domain",""))==domain:return true
	return false


# --- Words ---------------------------------------------------------------------

## Section, chip and tile names. Keys not listed keep the given fallback.
const WORDS:={
	"hearth":{
		"rail.overview":"The People","rail.world":"Known World","rail.chronicle":"Chronicle","rail.drawer":"Tallies",
		"rail.government":"Chiefs","rail.inquiry":"Lore","rail.production":"Crafts","rail.military":"Warriors","rail.wealth":"Exchange",
		"kpi.population":"PEOPLE","kpi.food":"STORES","kpi.water":"WATER","kpi.goods":"TOOLS & GEAR","kpi.health":"LIVES","kpi.science":"LORE","kpi.gdp":"HANDS AT WORK",
		"scope":"All our hearths","place":"hearth","places":"hearths",
		"chronicle.caption":"Great moments told at the fire, and smaller things remembered.","chronicle.tallies":"Show every season's tally",
	},
	"lettered":{
		"rail.overview":"The People","rail.world":"Known World","rail.chronicle":"Chronicle","rail.drawer":"Ledgers",
		"rail.inquiry":"Learning","rail.production":"Crafts",
		"kpi.population":"PEOPLE","kpi.food":"STORES","kpi.water":"WATER","kpi.goods":"GOODS","kpi.health":"LIVES","kpi.science":"LEARNING","kpi.gdp":"DAILY LABOUR",
		"scope":"All our towns","place":"town","places":"towns",
		"chronicle.caption":"Great moments entered in the annals, and lesser things noted.","chronicle.tallies":"Show every season's register",
	},
	"reckoned":{
		"rail.overview":"The People","rail.world":"Known World","rail.chronicle":"Chronicle","rail.drawer":"Ledgers",
		"kpi.population":"POPULATION","kpi.food":"FOOD","kpi.water":"WATER","kpi.goods":"GOODS","kpi.health":"HEALTH","kpi.science":"SCIENCE","kpi.gdp":"REAL GDP / DAY",
		"scope":"Entire civilization","place":"city","places":"cities",
		"chronicle.caption":"Major events and notable news, newest first.","chronicle.tallies":"Show every season's report",
	},
}


static func word(key:String,fallback:String="")->String:
	return String((WORDS[stage()] as Dictionary).get(key,fallback))


## THE date phrase. Every date the player reads is the Chronicle's own
## year-and-season phrase, "Year 12 · Summer", never an absolute day number
## ("Day 34844") or "Year 3, Day 211". Pass the absolute simulation day (the
## same day GameState.elapsed_days counts). A negative day reads as unknown.
static func when(day:int)->String:
	if day<0:return "some time ago"
	return preload("res://scripts/chronicle.gd").date_label(day)


## when() for the current day.
static func today()->String:
	return when(int(floor(GameState.elapsed_days)) if Engine.get_main_loop()!=null else 0)


## How long ago something happened, in seasons and years rather than a count
## of days: "this season", "last season", "three seasons ago", "two years ago".
static func ago(day:int)->String:
	if day<0:return "some time ago"
	var now:=int(floor(GameState.elapsed_days)) if Engine.get_main_loop()!=null else day
	var chronicle:=preload("res://scripts/chronicle.gd")
	var seasons:int=chronicle.season_of(now)-chronicle.season_of(day)
	if seasons<=0:return "this season"
	if seasons==1:return "last season"
	if seasons<4:return "%s seasons ago" % count_word(seasons)
	var years:=roundi(seasons/4.0)
	return "a year ago" if years<=1 else "%s years ago" % count_word(years)


static func places(count:int)->String:
	return "%d %s" % [count,word("place") if count==1 else word("places")]


## "118 souls" / "1,240 people" / "1,240".
static func people(count:int)->String:
	match stage():
		"hearth":return "%s souls" % grouped(count)
		"lettered":return "%s people" % grouped(count)
	return grouped(count)


## Days of stores: "48 days", "4.5 days"; the statistical age keeps "48.0 d".
static func days(value:float)->String:
	if value<0.0:return "—"
	if reckoned():return "%.1f d" % value
	if value>=10.0:return "%d days" % roundi(value)
	if value<1.0:return "under a day"
	# "5 days", not "5.0 days"; a half day still matters when it is short.
	var tenths:=roundi(value*10.0)
	if tenths%10==0:return "%d day%s" % [roundi(tenths/10.0),"" if tenths==10 else "s"]
	return "%.1f days" % value


## How long the stores last, in the way the people count time: moons before
## writing, weeks and months after it, days once there are statistics.
static func store_span(value:float)->String:
	if value<0.0:return "stores not yet counted"
	if reckoned():return "food for %d days" % roundi(value)
	if value<1.0:return "food for less than a day"
	if value<1.5:return "food for one day"
	var lettered:=stage()=="lettered"
	if value<13.5:return "food for %s days" % count_word(roundi(value))
	if lettered:
		if value<60.0:return "food for %s weeks" % count_word(roundi(value/7.0))
		return "food for %s months" % count_word(roundi(value/30.0))
	if value<22.0:return "food for half a moon"
	if value<44.0:return "food for a moon"
	return "food for %s moons" % count_word(roundi(value/29.5))


## Where the People screen's knowledge comes from: talk at the fire before
## writing, the registers after it, the census once numbers are gathered.
static func register()->String:
	match stage():
		"hearth":return "TOLD AT THE FIRE"
		"lettered":return "FROM THE REGISTERS"
	return "FROM THE CENSUS"


## How long a person born now can hope to live.
static func life(years:float)->String:
	match stage():
		"hearth":return "%d winters" % roundi(years)
		"lettered":return "%d years" % roundi(years)
	return "%.1f yr" % years


## A change in how long a person born now can hope to live, in the unit that
## shows it: "+5 days", "+3 weeks", "-2 months", "+1.5 years" ("+2 winters"
## before writing). A new practice spreads over years, so its first month is
## often days, never "+0.0 years". Under a day: "less than a day".
static func life_change(delta_years:float)->String:
	var size:=absf(delta_years)
	var days:=size*365.25
	if days<1.0:return "less than a day"
	var sign:="+" if delta_years>0.0 else "-"
	if days<14.0:
		var d:=roundi(days)
		return "%s%d %s" % [sign,d,"day" if d==1 else "days"]
	if days<60.0:
		var w:=roundi(days/7.0)
		return "%s%d %s" % [sign,w,"week" if w==1 else "weeks"]
	if size<2.0:
		var m:=roundi(size*12.0)
		return "%s%d %s" % [sign,m,"month" if m==1 else "months"]
	match stage():
		"hearth":return "%s%d winters" % [sign,roundi(size)]
		"lettered":return "%s%d years" % [sign,roundi(size)]
	return "%s%.1f years" % [sign,size]


## Children lost before their first winter, in the people's own counting.
static func babes_lost(per_1000:float)->String:
	match stage():
		"hearth":return "%d in 100 babes die" % roundi(per_1000/10.0)
		"lettered":return "%d in 1,000 infants die" % roundi(per_1000)
	return "IMR %.0f‰" % per_1000


## The same, short enough for the note line under the lifespan in LIVES.
static func babes_lost_short(per_1000:float)->String:
	match stage():
		"hearth":return "%d in 100 babes lost" % roundi(per_1000/10.0)
		"lettered":return "%d in 1,000 infants lost" % roundi(per_1000)
	return "IMR %.0f‰" % per_1000


static func babes_lost_sentence(per_1000:float)->String:
	match stage():
		"hearth":return "Of every 100 children born, about %d are lost before their first winter." % roundi(per_1000/10.0)
		"lettered":return "Of every 1,000 children born, about %d are buried before their first year." % roundi(per_1000)
	return "Infant mortality: %.0f deaths per 1,000 live births." % per_1000


static func life_title()->String:
	return "How long we live" if not reckoned() else "Life expectancy"


static func life_unit()->String:
	match stage():
		"hearth":return "winters, for a child born now"
		"lettered":return "years, for a child born now"
	return "years · life expectancy"


static func babes_title()->String:
	match stage():
		"hearth":return "CHILDREN LOST BEFORE THEIR FIRST WINTER"
		"lettered":return "INFANTS BURIED BEFORE THEIR FIRST YEAR"
	return "INFANT MORTALITY"


## How many were fed in full today, from today's eating (-1 when not yet told).
static func fed(people_count:int,eaten:float,need:float)->int:
	if need<=0.0:return -1
	return clampi(roundi(float(people_count)*clampf(eaten/need,0.0,1.0)),0,people_count)


## The note under PEOPLE (or WATER) when some went without today.
static func went_without(count:int,want:String)->String:
	if reckoned():return "%s %s" % [grouped(count),want]
	return "%s went %s" % [grouped(count),want]


## Tools and gear against what households expect, in words before writing.
static func goods(coverage:float)->String:
	if reckoned() or stage()=="lettered":return "%d%%" % roundi(coverage*100.0)
	if coverage>=0.9:return "enough"
	if coverage>=0.6:return "most have"
	if coverage>=0.3:return "half have"
	return "few have"


static func goods_trend(net:float)->String:
	if reckoned():return "%+.1f / day" % net
	if net>0.05:return "more made"
	if net<-0.05:return "wearing out"
	return "holding"


## How the people hold together (cohesion) and trust their chiefs (legitimacy).
static func spirit(value:float)->String:
	if reckoned():return "%d%%" % roundi(value*100.0)
	if value>=0.8:return "one people"
	if value>=0.6:return "steady"
	if value>=0.4:return "uneasy"
	if value>=0.2:return "fraying"
	return "breaking"


static func trust(value:float)->String:
	if reckoned():return "%d%%" % roundi(value*100.0)
	if value>=0.8:return "trusted"
	if value>=0.6:return "heeded"
	if value>=0.4:return "doubted"
	if value>=0.2:return "resented"
	return "defied"


## How well what is known is kept and passed on (the education index).
static func teaching(value:float)->String:
	if reckoned():return "%d%%" % roundi(value*100.0)
	if value>=0.8:return "well kept"
	if value>=0.6:return "steadily"
	if value>=0.4:return "patchily"
	if value>=0.2:return "poorly"
	return "barely"


## How far along an aim or a work is: plain words before writing, a share after.
static func way_along(progress:float)->String:
	var p:=clampf(progress,0.0,1.0)
	if not hearth():return "%d%% of the way" % roundi(p*100.0)
	if p>=1.0:return "done"
	if p>=0.85:return "nearly there"
	if p>=0.6:return "most of the way"
	if p>=0.4:return "half the way"
	if p>=0.15:return "a quarter of the way"
	return "barely begun"


## The scouts on the map toolbar: who is out walking, never a staffing share.
static func scouts_out(away:int)->String:
	if away<=0:return "Send scouts"
	if hearth():return "%s out" % ("One walker" if away==1 else "%s walkers" % count_word(away).capitalize())
	return "%d scout%s out" % [away,"" if away==1 else "s"]


## How far the map looks, in the people's words (the four map distances).
const DISTANCE_WORDS:=["Close by","The valley","The region","The far lands"]


static func count_word(value:int)->String:
	var words:=["none","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"]
	return String(words[value]) if value>=0 and value<words.size() else grouped(value)


static func grouped(value:int)->String:
	var digits:=str(absi(value))
	var out:=""
	for i in digits.length():
		if i>0 and (digits.length()-i)%3==0:out+=","
		out+=digits[i]
	return ("-" if value<0 else "")+out
