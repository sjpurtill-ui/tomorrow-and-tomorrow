extends RefCounted
## THE WATER WATCH: one reading of the whole people's drinking water for the
## WATER tile, its hover card and its drawer, from the towns' own water
## ledgers (civilization_kpi_model.gd) and the dry year in the crisis ledger.
##
## The user lost eleven to "thirst" in a dry year while the tile sat at 5.3
## days. Both were the engine's numbers: every town's store was full and
## everyone drank, and the dry year's toll is planned from how dry the season
## is (crisis_system.gd), not from the store. So the tile now tells each:
## - someone went thirsty today (a town drew less than it drank and the store
##   could not cover it): red, the worst town named with its days;
## - a town's store is falling and nearly gone: amber, named;
## - a dry year is running: amber "dry year", with its dead so far and the
##   toll still ahead as the crisis plans it;
## - else the people's days held, as before.
## The days held sit near the vessels' and pits' capacity (people x days of
## storage) whenever more is drawn than drunk, so in good times the number
## does not move; it falls only when a town draws less than it drinks.

const EraWords:=preload("res://scripts/hud/era_words.gd")
const Crisis:=preload("res://scripts/crisis_system.gd")

## A town whose store is falling is "running low" under this many days.
const LOW_DAYS:=3.0
## Drinking met below this share of the need: some went thirsty.
const SHORT_SHARE:=0.995

## The town-by-town water reading. `t` is a civilization_kpi_model snapshot;
## `drought` is drought_now(); `causes` the deaths by cause of the last year
## (GameState.rolling_death_causes(365)); `dry_years` recent_droughts().
## {tone: "short"|"low"|"dry"|"calm", days, where, thirsty, towns_short,
##  notes (most telling first: the tile shows the first that fits),
##  headline, facts [{text, trend, good}], status (the drawer's long line)}.
static func read(t:Dictionary,drought:Dictionary={},causes:Dictionary={},dry_years:Array=[])->Dictionary:
	var cities:Array=t.get("cities",[])
	var many:=cities.size()>1
	var short:Array=[]
	var low:Array=[]
	for city:Dictionary in cities:
		if not bool(city.get("water_report",false)):continue
		var need:=float(city.get("water_need",0.0))
		if need<=0.0:continue
		var people:=int(city.get("population",0))
		var days:=float(city.get("water_stock",0.0))/need
		var eaten:=float(city.get("water_eaten",0.0))
		var fed:=EraWords.fed(people,eaten,need)
		var row:={"name":String(city.get("name","")),"days":days,"thirsty":maxi(0,people-fed) if fed>=0 else 0,"people":people}
		if eaten<need*SHORT_SHARE:short.append(row)
		elif float(city.get("water_produced",0.0))<need*SHORT_SHARE and days<LOW_DAYS:low.append(row)
	short.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.thirsty)>int(b.thirsty) or (int(a.thirsty)==int(b.thirsty) and float(a.days)<float(b.days)))
	low.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.days)<float(b.days))
	var total_days:=float(t.get("water_days",-1.0))
	var out:={"tone":"calm","days":total_days,"where":"","thirsty":0,"towns_short":short.size(),"notes":[],"headline":"","facts":[],"status":""}
	var thirsty:=0
	for row:Dictionary in short:thirsty+=int(row.thirsty)
	out.thirsty=thirsty
	var dry:=_dry_words(drought)
	if not short.is_empty():
		var worst:Dictionary=short[0]
		out.tone="short";out.days=float(worst.days);out.where=String(worst.name) if many else ""
		var held:="nothing left in store" if float(worst.days)<0.05 else "%s held" % EraWords.days(float(worst.days))
		if many and short.size()==1:
			out.notes=["%s: %d thirsty" % [worst.name,int(worst.thirsty)],"%s short" % worst.name,EraWords.went_without(thirsty,"thirsty") if thirsty>0 else "running short"]
			out.headline="Water is running short at %s: %s, and %s." % [worst.name,held,("%s went thirsty today" % EraWords.grouped(int(worst.thirsty))) if int(worst.thirsty)>0 else "the day's need was not met"]
		elif many:
			out.notes=["%d thirsty, %s" % [thirsty,EraWords.places(short.size())],"%s short" % EraWords.places(short.size()),EraWords.went_without(thirsty,"thirsty") if thirsty>0 else "running short"]
			out.headline="Water is running short at %s, worst at %s: %s, and %s went thirsty today." % [EraWords.places(short.size()),worst.name,held,EraWords.grouped(thirsty)]
		else:
			out.notes=[EraWords.went_without(thirsty,"thirsty") if thirsty>0 else "running short"]
			out.headline="Water is running short: %s, and %s." % [held,("%s went thirsty today" % EraWords.grouped(thirsty)) if thirsty>0 else "the day's need was not met"]
		for row:Dictionary in short.slice(0,2):
			if many:out.facts.append({"text":"%s: %s held, %s thirsty" % [row.name,EraWords.days(float(row.days)) if float(row.days)>=0.05 else "nothing",EraWords.grouped(int(row.thirsty))],"trend":-1,"good":false})
		out.status=out.headline
	elif not low.is_empty():
		var worst:Dictionary=low[0]
		out.tone="low";out.days=float(worst.days);out.where=String(worst.name) if many else ""
		out.notes=["%s running low" % worst.name,"running low"] if many else ["running low"]
		out.headline="Water is running low%s: %s held, and less is drawn than drunk. All drank their fill today." % [" at %s" % worst.name if many else "",EraWords.days(float(worst.days))]
		out.status=out.headline
	elif not dry.is_empty():
		out.tone="dry"
		var dead:=int(drought.get("deaths",0))
		out.notes=["dry year: %d dead" % dead,"a dry year"] if dead>0 else ["a dry year"]
		out.headline="Everyone drank their fill today, with %s of water held. The danger is the dry year: %s" % [EraWords.days(total_days),String(dry.toll)]
		out.status="%s %s" % [out.headline,String(dry.why)]
		var full:=_full_days(t)
		if full>0.0:out.status+=" The water stores are full: they hold %s at most." % EraWords.days(full)
	else:
		out.notes=["of drinking water"]
		# Why the number stands still in good times: the store is as full as
		# its vessels, pits and cisterns hold (resource_system.gd capacity).
		var full:=_full_days(t)
		if full>0.0:out.facts.append({"text":"The stores are full: they hold %s at most" % EraWords.days(full)})
	if not dry.is_empty() and out.tone!="dry":out.facts.append({"text":_cap(String(dry.toll)).trim_suffix("."),"trend":-1,"good":false})
	if out.tone=="dry":
		out.facts.append({"text":String(dry.ahead),"trend":-1,"good":false})
		out.facts.append({"text":String(dry.short_why)})
	# The year past: what the dry years took, and whether anyone died of thirst.
	var year_dry:=0
	var deadly:Array=[]
	for spell:Dictionary in dry_years:
		if String(spell.get("id",""))==String(drought.get("id","-")) or int(spell.get("deaths",0))<=0:continue
		year_dry+=int(spell.deaths)
		deadly.append(spell)
	if year_dry>0:
		out.facts.append({"text":"%s took %s" % [_cap(String((deadly[0] as Dictionary).get("name","the dry year"))) if deadly.size()==1 else "The dry years",_count(year_dry)],"trend":-1,"good":false})
	var thirst_dead:=int(causes.get("Dehydration",0))
	if thirst_dead>0:out.facts.append({"text":"%s died of thirst in the last year" % EraWords.grouped(thirst_dead),"trend":-1,"good":false})
	elif year_dry>0 or not dry.is_empty():out.facts.append({"text":"No one died of thirst in the last year"})
	return out

## The running dry year from the crisis ledger, or {} when none: {id, name,
## deaths, ahead (deaths still planned as things stand), m, mult, pop0,
## choice, quiet}.
static func drought_now()->Dictionary:
	for c:Dictionary in Crisis.active():
		if String(c.get("type",""))!="drought" or String(c.get("phase","")) not in ["open","mid"]:continue
		# The middle of a dry year takes 0.4 of its toll and its end 0.6
		# (_mid, _end): what is still ahead, as stakes_words counts it.
		var share:=0.6 if String(c.get("phase",""))=="mid" else 1.0
		return {"id":String(c.get("id","")),"name":String(c.get("name","the dry year")),"deaths":int(c.get("deaths",0)),
			"ahead":float(c.get("pop0",0))*float(c.get("m",0.0))*float(c.get("mult",1.0))*share,
			"m":float(c.get("m",0.0)),"mult":float(c.get("mult",1.0)),"pop0":int(c.get("pop0",0)),"choice":String(c.get("choice","")),"mid_choice":String(c.get("mid_choice","")),"quiet":bool(c.get("quiet",false))}
	return {}

## The dry years that ended in the last `days` days (crisis history), most
## recent first: [{id, name, deaths, end}].
static func recent_droughts(days:int=365)->Array:
	var out:Array=[]
	var today:=int(GameState.elapsed_days)
	for h in Crisis.state().get("history",[]):
		if not h is Dictionary or String(h.get("type",""))!="drought":continue
		if int(h.get("end",-99999))<today-days+1:continue
		out.append({"id":String(h.get("id","")),"name":String(h.get("name","the dry year")),"deaths":int(h.get("deaths",0)),"end":int(h.get("end",0))})
	return out

## Everything the tile needs, read live: the KPI snapshot, the dry year and
## the last year's deaths.
static func live(t:Dictionary)->Dictionary:
	return read(t,drought_now(),GameState.rolling_death_causes(365),recent_droughts(365))

## Words for a running dry year: toll so far, toll ahead, and why it is not
## thirst, with the crisis's own numbers.
static func _dry_words(drought:Dictionary)->Dictionary:
	if drought.is_empty():return {}
	var name:=String(drought.get("name","the dry year"))
	var dead:=int(drought.get("deaths",0))
	var ahead:=roundi(float(drought.get("ahead",0.0)))
	var toll:="%s has taken %s so far." % [name,_count(dead)] if dead>0 else "%s has taken no one yet." % name
	var ahead_words:="About %s more may die of it as things stand" % _count(ahead) if ahead>0 else "Few if any more are likely to die of it"
	var share:=float(drought.get("m",0.0))*100.0
	var mult:=float(drought.get("mult",1.0))
	var done:PackedStringArray=[]
	for key in ["choice","mid_choice"]:
		var option:=String(drought.get(key,""))
		if absf(float(Crisis.DEATH_FACTOR.get(option,1.0))-1.0)>0.005:done.append(String(CHOICE_WORDS.get(option,"what was done")))
	var answer:=""
	if absf(mult-1.0)>0.005:answer=", x%.2f for %s" % [mult," and ".join(done) if not done.is_empty() else "what was done about it"]
	var why:="Its toll is the dry year's own, not thirst. It was set at its start from how dry the season is: %.1f in 100 of the %d people%s. The water store does not change it." % [share,int(drought.get("pop0",0)),answer]
	return {"toll":toll,"ahead":ahead_words,"why":why,"short_why":"Not thirst: the dry season sets its toll"}

## The answers to a dry year that change its toll (crisis_system.gd DEATH_FACTOR).
const CHOICE_WORDS:={"carry":"carrying water from the far pools","ration":"rationing","hardy":"sowing the seed that needs little water","river_camp":"moving the sleeping places to the river"}

## The days the people's stores hold at most, when they are full (within a
## day's drinking of it), else 0.
static func _full_days(t:Dictionary)->float:
	var capacity:=float(t.get("water_capacity",0.0))
	var need:=float(t.get("water_need",0.0))
	if capacity<=0.0 or need<=0.0:return 0.0
	if float(t.get("water_stock",0.0))<capacity-need*1.2:return 0.0
	return capacity/need

static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text

static func _count(n:int)->String:
	return "no one" if n<=0 else ("one" if n==1 else EraWords.grouped(n))
