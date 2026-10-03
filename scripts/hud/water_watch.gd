extends RefCounted
## THE WATER WATCH: one reading of the whole people's drinking water for the
## WATER tile, its hover card and its drawer, from the towns' own water
## ledgers (civilization_kpi_model.gd) and the dry year in the crisis ledger.
##
## The user lost eleven to "thirst" in a dry year while the tile sat at 5.3
## days: the dry year's toll was fixed at its start and never touched the
## water. Now a dry year dries the springs (dry_water.gd): the store falls day
## by day, and when it runs out the people go thirsty and die of it. So:
## - someone went thirsty today (a town drew less than it drank and the store
##   could not cover it): red, the worst town named with its days;
## - a town's store is falling and nearly gone: amber, named;
## - a dry year is running: amber "dry year", with its dead so far and the
##   forecast ahead from the water ledger's own arithmetic (dry_water.gd
##   forecast), and what more carriers or a cistern would save;
## - else the people's days held. In good times the stores sit full (people x
##   days of storage) and the number stands still.

const EraWords:=preload("res://scripts/hud/era_words.gd")
const Crisis:=preload("res://scripts/crisis_system.gd")
const DryWater:=preload("res://scripts/dry_water.gd")

## A town whose store is falling is "running low" under this many days.
const LOW_DAYS:=3.0
## Drinking met below this share of the need: some went thirsty.
const SHORT_SHARE:=0.995
## The "more carriers" the card prices: this share of each town's people.
const MORE_CARRIERS:=0.05

## The town-by-town water reading. `t` is a civilization_kpi_model snapshot;
## `drought` is drought_now(); `causes` the deaths by cause of the last year
## (GameState.rolling_death_causes(365)); `dry_years` recent_droughts();
## `ahead` the dry year's forecasts (forecasts()).
## {tone: "short"|"low"|"dry"|"calm", days, where, thirsty, towns_short,
##  notes (most telling first: the tile shows the first that fits),
##  headline, facts [{text, trend, good}], status (the drawer's long line)}.
static func read(t:Dictionary,drought:Dictionary={},causes:Dictionary={},dry_years:Array=[],ahead:Dictionary={})->Dictionary:
	var cities:Array=t.get("cities",[])
	var many:=cities.size()>1
	var short:Array=[]
	var low:Array=[]
	var drawn:=0.0;var drunk:=0.0
	for city:Dictionary in cities:
		if not bool(city.get("water_report",false)):continue
		var need:=float(city.get("water_need",0.0))
		if need<=0.0:continue
		var people:=int(city.get("population",0))
		var days:=float(city.get("water_stock",0.0))/need
		var eaten:=float(city.get("water_eaten",0.0))
		drawn+=float(city.get("water_produced",0.0));drunk+=need
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
	var dry:=_dry_words(drought,ahead)
	var falling:=drawn<drunk*SHORT_SHARE
	if not short.is_empty():
		var worst:Dictionary=short[0]
		out.tone="short";out.days=float(worst.days);out.where=String(worst.name) if many else ""
		var held:="nothing left in store" if float(worst.days)<0.05 else "%s held" % EraWords.days(float(worst.days))
		var some:=EraWords.went_without(thirsty,"thirsty") if thirsty>0 else "running short"
		if many and short.size()==1:
			out.notes=(["%s: %s thirsty" % [worst.name,EraWords.grouped(int(worst.thirsty))]] if int(worst.thirsty)>0 else [])+["%s short" % worst.name,some]
			out.headline="Water is running short at %s: %s, and %s." % [worst.name,held,("%s went thirsty today" % EraWords.grouped(int(worst.thirsty))) if int(worst.thirsty)>0 else "the day's need was not met"]
		elif many:
			out.notes=(["%s thirsty, %s" % [EraWords.grouped(thirsty),EraWords.places(short.size())]] if thirsty>0 else [])+["%s short" % EraWords.places(short.size()),some]
			out.headline="Water is running short at %s, worst at %s: %s, and %s." % [EraWords.places(short.size()),worst.name,held,("%s went thirsty today" % EraWords.grouped(thirsty)) if thirsty>0 else "the day's need was not met"]
		else:
			out.notes=[some]
			out.headline="Water is running short: %s, and %s." % [held,("%s went thirsty today" % EraWords.grouped(thirsty)) if thirsty>0 else "the day's need was not met"]
		for row:Dictionary in short.slice(0,2):
			if many:out.facts.append({"text":"%s: %s held%s" % [row.name,EraWords.days(float(row.days)) if float(row.days)>=0.05 else "nothing",", %s thirsty" % EraWords.grouped(int(row.thirsty)) if int(row.thirsty)>0 else ""],"trend":-1,"good":false})
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
		out.notes=["dry year: %s dead" % EraWords.grouped(dead),"a dry year"] if dead>0 else ["a dry year"]
		out.headline="Everyone drank their fill today, but the dry year is drying the springs: %s, and %s." % [String(dry.springs),"the stores are falling" if falling else "the stores still hold"]
		out.status="%s %s" % [out.headline,String(dry.long)]
	else:
		out.notes=["of drinking water"]
		# Why the number stands still in good times: the store is as full as
		# its vessels, pits and cisterns hold (resource_system.gd capacity).
		var full:=_full_days(t)
		if full>0.0:out.facts.append({"text":"The stores are full: they hold %s at most" % EraWords.days(full)})
	if not dry.is_empty():
		if out.tone!="dry":
			out.facts.append({"text":_cap(String(dry.toll)).trim_suffix("."),"trend":-1,"good":false})
			out.status+=" "+String(dry.long)
		else:
			out.facts.append({"text":_cap(String(dry.toll)).trim_suffix("."),"trend":-1,"good":false})
		out.facts.append({"text":String(dry.ahead),"trend":-1,"good":false})
		if String(dry.saves)!="":out.facts.append({"text":String(dry.saves)})
		if String(dry.runs_dry)!="":out.facts.append({"text":String(dry.runs_dry),"trend":-1,"good":false})
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
## deaths, thirst (its dead of thirst so far), m, mult, pop0, sev, depth,
## loss (today's), choice, mid_choice, phase, start, end_day}. Cheap: the
## strip's signature reads it.
static func drought_now()->Dictionary:
	var c:=DryWater.running()
	if c.is_empty():return {}
	var out:={}
	for key in ["id","name","deaths","thirst","toll_dead","m","mult","pop0","sev","choice","mid_choice","phase","start","end_day","held_sum","held_days","draw"]:
		if c.has(key):out[key]=c[key]
	out["depth"]=DryWater.depth_of(c)
	out["loss"]=DryWater.loss(c,float(GameState.elapsed_days))
	return out

## The dry year's forecasts from today, from each town's last water day
## (dry_water.gd forecast): as things stand, with MORE_CARRIERS more on the
## water path, and with a lined cistern in every town. Kept for the day.
static var _ahead_cache:={"key":"","value":{}}
static func forecasts(drought:Dictionary)->Dictionary:
	if drought.is_empty():return {}
	var c:=DryWater.running()
	if c.is_empty():return {}
	var key:="%s|%d|%d|%s|%d" % [String(c.id),int(GameState.elapsed_days),int(c.deaths),String(c.phase),GameState.active_modifiers.size()]
	if String(_ahead_cache.key)==key:return _ahead_cache.value
	var towns:=DryWater.towns()
	var today:=float(GameState.elapsed_days)
	var value:={"now":DryWater.forecast(c,towns,today),"carriers":DryWater.forecast(c,towns,today,{"carriers":MORE_CARRIERS}),
		"cistern":DryWater.forecast(c,towns,today,{"cistern":true}),"extra_carriers":roundi(MORE_CARRIERS*float(GameState.population_total)),
		"cisterns_known":"rainwater_cisterns" in GameState.known_discoveries,"store_days":DryWater.store_days(),"today":today}
	_ahead_cache={"key":key,"value":value}
	return value

## The dry years that ended in the last `days` days, most recent first:
## [{id, name, deaths, end}]. From the crisis history and the sickness &
## disaster log (a shallow dry spell closes without a history line).
static func recent_droughts(days:int=365)->Array:
	var out:Array=[]
	var seen:={}
	var today:=int(GameState.elapsed_days)
	for h in Crisis.state().get("history",[]):
		if not h is Dictionary or String(h.get("type",""))!="drought":continue
		if int(h.get("end",-99999))<today-days+1:continue
		seen[String(h.get("id",""))]=true
		out.append({"id":String(h.get("id","")),"name":String(h.get("name","the dry year")),"deaths":int(h.get("deaths",0)),"end":int(h.get("end",0))})
	for e in preload("res://scripts/hardship_log.gd").entries():
		if not e is Dictionary or String(e.get("type",""))!="drought" or not e.has("end"):continue
		if seen.has(String(e.get("crisis",""))) or int(e.end)<today-days+1:continue
		seen[String(e.get("crisis",""))]=true
		out.append({"id":String(e.get("crisis","")),"name":String(e.get("name","the dry year")),"deaths":int(e.get("dead",0)),"end":int(e.end)})
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.end)>int(b.end))
	return out

## Everything the tile needs, read live: the KPI snapshot, the dry year, its
## forecasts and the last year's deaths. An older save's dry-year dead are
## re-read first (once: crisis_system.gd), so the card never says thirst
## where the dry year's own toll took them.
static func live(t:Dictionary)->Dictionary:
	Crisis.reconcile_drought_causes(Crisis.state())
	var drought:=drought_now()
	return read(t,drought,GameState.rolling_death_causes(365),recent_droughts(365),forecasts(drought))

## Words for a running dry year, with the engine's numbers.
static func _dry_words(drought:Dictionary,ahead:Dictionary)->Dictionary:
	if drought.is_empty():return {}
	var name:=String(drought.get("name","the dry year"))
	var dead:=int(drought.get("deaths",0))
	var thirst:=int(drought.get("thirst",0))
	var toll:="%s has taken %s so far%s." % [name,_count(dead)," (%s of thirst)" % _count(thirst) if thirst>0 else ""] if dead>0 else "%s has taken no one yet." % name
	var left:=clampi(roundi((1.0-float(drought.get("loss",0.0)))*10.0),0,10)
	var springs:="they give about %d in 10 of what they did" % left
	var now:Dictionary=ahead.get("now",{})
	var ahead_words:="Few if any more are likely to die of it"
	var runs_dry:=""
	var saves:=""
	var long:=""
	if not now.is_empty():
		var thirst_ahead:=roundi(float(now.thirst));var toll_ahead:=roundi(float(now.toll))
		var all:=roundi(float(now.total))
		if all>0:
			var parts:PackedStringArray=[]
			if thirst_ahead>0:parts.append("%s of thirst" % _count(thirst_ahead))
			if toll_ahead>0:parts.append("%s of the heat and the failed forage" % _count(toll_ahead))
			ahead_words="About %s more may die as things stand%s" % [_count(all),(": "+" and ".join(parts)) if not parts.is_empty() else ""]
		var dry_day:=int(now.get("dry_day",-1))
		var store:=float(ahead.get("store_days",-1.0))
		if dry_day>=0 and store>=0.05:runs_dry="The stores run dry in about %s" % _span(float(dry_day)-float(ahead.get("today",GameState.elapsed_days)))
		elif dry_day>=0:runs_dry="The stores are empty: what is drawn each day is all there is"
		# What more hands or a cistern would save, by the same forecast.
		var by_carriers:=maxi(0,roundi(float(now.total)-float((ahead.get("carriers",now) as Dictionary).total)))
		var by_cistern:=maxi(0,roundi(float(now.total)-float((ahead.get("cistern",now) as Dictionary).total)))
		var hands:=int(ahead.get("extra_carriers",0))
		var cistern_words:=("a lined cistern in every town about %s" if bool(ahead.get("cisterns_known",false)) else "cisterns, once the people learn to line them, about %s") % _count(by_cistern)
		if all>0:
			# More hands help only while the far pools give more than the carriers bring.
			saves=("%s more on the water path would save about %s; %s" % [EraWords.grouped(hands),_count(by_carriers),cistern_words]) if by_carriers>0 else ("More hands would not help, the far pools give all they have; %s" % cistern_words)
		var mult:=float(drought.get("mult",1.0))
		long="%s. Thirst is the water ledger's own count once the stores run out: at its worst the springs give %d in 10 of what they did, and the far pools what the carriers reach. The rest is the dry year's own toll (the heat, the failed forage, the sickness of foul water): %.1f in 1,000 of the %d people at this dryness, half that when everyone drinks%s." % [ahead_words,clampi(roundi((1.0-float(drought.get("depth",0.0)))*10.0),0,10),DryWater.toll_share(float(drought.get("sev",0.0)),0.0)*1000.0,int(drought.get("pop0",0)),", x%.2f for what was done about it" % mult if absf(mult-1.0)>0.005 else ""]
		if saves!="":long+=" %s." % saves
	return {"toll":toll,"ahead":ahead_words,"springs":springs,"runs_dry":runs_dry,"saves":saves,"long":long}

## "4 days", "about two weeks" for how soon the stores run dry.
static func _span(days:float)->String:
	if days<1.5:return "a day"
	if days<14.0:return "%d days" % roundi(days)
	return "%d weeks" % roundi(days/7.0)

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
