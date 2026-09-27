extends RefCounted
## When something happened, in the words the reports use: "late summer, year 12".
##
## Batch B adds the shared EraWords.when(day). Until that lands this reads the
## season the same way the Chronicle does; once it exists every report asks it.

const ERA_WORDS_PATH:="res://scripts/hud/era_words.gd"
static var _shared:=-1

static func _has_shared()->bool:
	if _shared<0:
		_shared=0
		var script:=load(ERA_WORDS_PATH) as Script
		if script!=null:
			for method:Dictionary in script.get_script_method_list():
				if String(method.get("name",""))=="when":_shared=1;break
	return _shared==1

static func when(day:int)->String:
	if day<0:return "at an unknown time"
	if _has_shared():return String(load(ERA_WORDS_PATH).call("when",day))
	var key:=floori((float(day)+45.625)/91.25)
	var hemisphere:=1.0
	if Engine.get_main_loop()!=null and GameState.get("hearth_season") is Dictionary:
		hemisphere=float((GameState.hearth_season as Dictionary).get("hemisphere",1.0))
	var season:String=["spring","summer","autumn","winter"][posmod(key+(0 if hemisphere>=0.0 else 2),4)]
	var into:=fposmod(float(day)+45.625,91.25)/91.25
	var part:="early " if into<0.34 else "late " if into>0.66 else ""
	return "%s%s, year %d" % [part,season,day/365+1]

## "12 days", "3 months", "2 years": a span of time, never a raw day count.
static func span(days:int)->String:
	days=maxi(0,days)
	if days<=1:return "a day"
	if days<14:return "%d days" % days
	if days<60:return "%d weeks" % roundi(days/7.0)
	if days<540:return "%d months" % roundi(days/30.4)
	return "%d years" % roundi(days/365.0)

## "today", "12 days ago", "3 months ago".
static func ago(day:int,today:int)->String:
	if day<0:return "at an unknown time"
	var age:=today-day
	if age<=0:return "today"
	if age==1:return "yesterday"
	return span(age)+" ago"
