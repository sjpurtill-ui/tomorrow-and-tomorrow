extends RefCounted
## ERA WORDS: how the people themselves would count the numbers the HUD shows.
##
## A band that cannot write does not know "GDP", "IMR", "per mille" or "life
## expectancy". It knows how many bellies were filled today, how many winters
## a person lives, and how many children are lost before their first winter.
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
		"kpi.population":"PEOPLE","kpi.food":"STORES","kpi.water":"WATER","kpi.goods":"TOOLS & GEAR","kpi.health":"LIVES","kpi.science":"LORE","kpi.gdp":"BELLIES FILLED",
		"scope":"All our hearths","place":"hearth","places":"hearths",
	},
	"lettered":{
		"rail.overview":"The People","rail.world":"Known World","rail.chronicle":"Chronicle","rail.drawer":"Ledgers",
		"rail.inquiry":"Learning","rail.production":"Crafts",
		"kpi.population":"PEOPLE","kpi.food":"STORES","kpi.water":"WATER","kpi.goods":"GOODS","kpi.health":"LIVES","kpi.science":"LEARNING","kpi.gdp":"DAILY LABOUR",
		"scope":"All our towns","place":"town","places":"towns",
	},
	"reckoned":{
		"rail.overview":"The People","rail.world":"Known World","rail.chronicle":"Chronicle","rail.drawer":"Ledgers",
		"kpi.population":"POPULATION","kpi.food":"FOOD","kpi.water":"WATER","kpi.goods":"GOODS","kpi.health":"HEALTH","kpi.science":"SCIENCE","kpi.gdp":"REAL GDP / DAY",
		"scope":"Entire civilization","place":"city","places":"cities",
	},
}


static func word(key:String,fallback:String="")->String:
	return String((WORDS[stage()] as Dictionary).get(key,fallback))


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
	return "%.1f days" % value if value>=1.0 else "under a day"


## How long a person born now can hope to live.
static func life(years:float)->String:
	match stage():
		"hearth":return "%d winters" % roundi(years)
		"lettered":return "%d years" % roundi(years)
	return "%.1f yr" % years


## Children lost before their first winter, in the people's own counting.
static func babes_lost(per_1000:float)->String:
	match stage():
		"hearth":return "%d in 100 babes die" % roundi(per_1000/10.0)
		"lettered":return "%d in 1,000 infants die" % roundi(per_1000)
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


## Bellies filled today: the people fed in full, from today's eating.
static func fed(people_count:int,eaten:float,need:float)->int:
	if need<=0.0:return -1
	return clampi(roundi(float(people_count)*clampf(eaten/need,0.0,1.0)),0,people_count)


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


static func grouped(value:int)->String:
	var digits:=str(absi(value))
	var out:=""
	for i in digits.length():
		if i>0 and (digits.length()-i)%3==0:out+=","
		out+=digits[i]
	return ("-" if value<0 else "")+out
