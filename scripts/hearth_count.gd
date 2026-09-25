extends RefCounted
## THE HEARTH COUNT — routine births, deaths and lost pregnancies are folded
## into one line per season instead of a ledger row each ("1 birth at ...").
## Crises are not folded: hunger, thirst, exposure, violence, exhausting travel
## and sickness during an epidemic still report as their own episodes.
##
## The tally lives on the simulated people's state (WorldSimulation.state), so a
## rival civilization's simulation keeps its own count without touching ours.

const Chronicle:=preload("res://scripts/chronicle.gd")
const EXCEPTIONAL_CAUSES:=["Hunger","Dehydration","Exposure","Travel exhaustion","Insecurity"]
const SEASONS:=["spring","summer","autumn","winter"]
const SEASON_DAYS:=91.25
const NUMBER_WORDS:=["no","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"]


static func routine(cause:String)->bool:
	if cause in EXCEPTIONAL_CAUSES:return false
	# Sickness is ordinary mortality until health itself is failing.
	if cause=="Illness" and WorldSimulation.state.population_health<0.55:return false
	return true


## Seasons are quarter-years offset so each is centred on its solstice or
## equinox; the index counts seasons since the world began.
static func season_key(day:int)->int:
	return floori((float(day)+SEASON_DAYS*0.5)/SEASON_DAYS)


## The calendar year (1-based) holding the middle of season `key`.
static func season_year(key:int)->int:
	return floori(float(key)*SEASON_DAYS/365.0)+1


static func season_name(key:int,hemisphere:float=1.0)->String:
	return SEASONS[posmod(key+(0 if hemisphere>=0.0 else 2),4)]


static func season_name_for_day(day:int)->String:
	return season_name(season_key(day),_hemisphere())


static func _hemisphere()->float:
	var state:Dictionary=GameState.hearth_season if Engine.get_main_loop()!=null else {}
	if state.has("hemisphere"):return float(state.hemisphere)
	return 1.0


static func tally(field:String,count:int)->void:
	if count<=0:return
	var s:Dictionary=WorldSimulation.state.hearth_season
	_open(s,int(WorldSimulation.state.elapsed_days))
	s[field]=int(s.get(field,0))+count
	if field in ["born","buried"]:
		var place:=WorldSimulation.state.settlement_name.strip_edges()
		if place!="":
			var places:Dictionary=s.get("places_"+field,{})
			places[place]=int(places.get(place,0))+count
			s["places_"+field]=places
	if not Chronicle.active() or WorldSimulation.state.settlement_founded_day<0 or WorldSimulation.state.convoy_traveling:return
	var home:=_home_name()
	if field=="born":
		Chronicle.record_first("first_birth",{"title":"The first child born at %s" % home,"text":"A child was born at the new hearth, the first of its people to know no other home.","kind":"birth","tier":"moment","domain":"population"})
	elif field=="buried":
		Chronicle.record_first("first_burial",{"title":"The first grave at %s" % home,"text":"The people buried one of their own beside the new hearth. From now on, this ground holds their dead as well as their living.","kind":"death","tier":"notice","domain":"population"})


static func _open(s:Dictionary,day:int)->void:
	if s.has("key"):return
	s["key"]=season_key(day)
	s["start_day"]=day
	if not s.has("hemisphere"):s["hemisphere"]=_measure_hemisphere()


static func _measure_hemisphere()->float:
	var food:Node=WorldSimulation.food
	if food==null or not food.has_method("current_environment_profile"):return 1.0
	var profile:Dictionary=food.call("current_environment_profile")
	var position:Variant=profile.get("position",Vector2.ZERO)
	# PlanetEnvironment.season_wave: positive y is the hemisphere whose year
	# begins in autumn.
	return -1.0 if position is Vector2 and (position as Vector2).y>0.0 else 1.0


## Called once per simulated day, after the day's births and deaths. When a
## season has ended with enough to tell, one line reports it. A thin season
## (fewer than MIN_TELLING changes) is carried into the next, so a small band
## hears its tally a few times a year and a large people every season; the
## year's tally is always read out at the end of winter. Quiet seasons say nothing.
const MIN_TELLING:=3

static func advance(events:Array[Dictionary])->void:
	var state:=WorldSimulation.state
	var s:Dictionary=state.hearth_season
	var day:=int(state.elapsed_days)
	if not s.has("key"):
		_open(s,day)
		return
	if season_key(day)==int(s.key):return
	var hemisphere:=float(s.get("hemisphere",_measure_hemisphere()))
	var closed_key:=int(s.key)
	var first_key:=int(s.get("first_key",closed_key))
	var told:=int(s.get("born",0))+int(s.get("buried",0))+int(s.get("lost",0))+int(s.get("stillborn",0))+int(s.get("afield",0))
	var year_end:=season_name(closed_key,hemisphere)=="winter"
	if told>0 and told<MIN_TELLING and not year_end:
		s["first_key"]=first_key
		s["key"]=season_key(day)
		return
	var line:=_summary(s,day-1,hemisphere) if told>0 else {}
	var last_people:=int(s.get("last_people",-1))
	s.clear()
	s["hemisphere"]=hemisphere
	s["last_people"]=int(line.get("people",state.population_total)) if not line.is_empty() else last_people
	_open(s,day)
	if line.is_empty():return
	state.simulation_events.push_front(line)
	if state.simulation_events.size()>80:state.simulation_events.resize(80)
	events.append(line)
	if year_end and Chronicle.active() and state.settlement_founded_day>=0 and int(line.get("start_day",0))>=state.settlement_founded_day:
		Chronicle.record_first("first_winter",{"title":"The first winter at %s is behind us" % _home_name(),"text":String(line.get("description","")),"kind":"hearth_count","tier":"notice","domain":"population"})


static func _summary(s:Dictionary,end_day:int,hemisphere:float)->Dictionary:
	var born:=int(s.get("born",0))
	var buried:=int(s.get("buried",0))
	var lost:=int(s.get("lost",0))+int(s.get("stillborn",0))
	var afield:=int(s.get("afield",0))
	if born<=0 and buried<=0 and lost<=0 and afield<=0:return {}
	var start_day:=int(s.get("start_day",end_day))
	var key:=int(s.get("key",season_key(end_day)))
	var first_key:=int(s.get("first_key",key))
	var season:=season_name(key,hemisphere)
	if first_key!=key:
		season=("%s and %s" if key-first_key==1 else "%s to %s") % [season_name(first_key,hemisphere),season]
	# The year is the closing season's own year. A carried tally opens in an
	# earlier season (spring begins before the calendar year turns), so its
	# start day can fall in the previous year: a spring-and-summer tally told
	# on day 503 is year 2's, not year 1's.
	var year:=season_year(key)
	var voice:=Chronicle.voice() if Engine.get_main_loop()!=null and WorldSimulation.state==GameState else {"era":"tally","count":"Tally","people":"souls at the hearths"}
	var annals:=String(voice.get("era",""))=="annals"
	var parts:PackedStringArray=[]
	if born>0:parts.append(plural(born,"birth","births",false) if annals else "%s born" % number(born))
	if buried>0:parts.append(plural(buried,"death","deaths",false) if annals else "%s buried" % number(buried))
	var detail:PackedStringArray=[]
	var infants:=int(s.get("infants",0))
	var mothers:=int(s.get("mothers",0))
	if infants>0:detail.append("a newborn" if infants==1 else "%s newborns" % number(infants))
	if mothers>0:detail.append("a mother lost in childbirth" if mothers==1 else "%s mothers lost in childbirth" % number(mothers))
	var text:=sentence_case((" and " if annals else ", ").join(parts))
	if not detail.is_empty():text+=" (among the dead, %s)" % " and ".join(detail)
	if text!="":text+="."
	if lost>0:text+=" %s lost before birth." % sentence_case(plural(lost,"pregnancy was","pregnancies were",not annals))
	if afield>0:text+=" %s never came home from scouting." % sentence_case(plural(afield,"traveler","travelers",not annals))
	var places_born:Dictionary=s.get("places_born",{})
	if places_born.size()>1:
		var split:PackedStringArray=[]
		for place in places_born:split.append("%s at %s" % [number(int(places_born[place])) if not annals else str(int(places_born[place])),String(place)])
		text+=" Births: %s." % ", ".join(split)
	var named:=_officeholders_lost(start_day,end_day)
	if not named.is_empty():text+=" Among the dead: %s." % "; ".join(named)
	# The whole people, across every hearth they keep.
	var people:=WorldSimulation.state.population_total
	var model:Node=WorldSimulation.settlements
	if model!=null and model.has_method("national_population"):people=maxi(people,int(model.call("national_population")))
	var count_text:=str(people) if people>12 or annals else sentence_case(number(people))
	text+=" %s %s%s." % [count_text,String(voice.get("people","people")),_change(people,int(s.get("last_people",-1)),annals)]
	text=text.strip_edges()
	var title:="%s of %s, year %d" % [String(voice.get("count","Tally")),season,year]
	return {"day":end_day,"start_day":start_day,"end_day":end_day,"title":title,"description":text,"domain":"population","severity":"minor","kind":"hearth_count","season":season,"born":born,"buried":buried,"lost":lost,"people":people,"id":"hearth_%d" % key}


static func _change(people:int,last:int,annals:bool)->String:
	if last<0:return ""
	var diff:=people-last
	if annals:return " (%+d since the last register)" % diff if diff!=0 else " (unchanged since the last register)"
	if diff==0:return ", as many as at the last tally"
	return ", %s %s than at the last tally" % [number(absi(diff)),"more" if diff>0 else "fewer"]


static func _officeholders_lost(start_day:int,end_day:int)->PackedStringArray:
	var out:PackedStringArray=[]
	# The court replaces the clerk's "Officeholder Died" line with its own
	# mourning, so the Remembered roll (court_lives.gd) names the season's dead.
	if Chronicle.active():
		var lives:GDScript=load("res://scripts/court_lives.gd")
		for remembered in lives.call("remembered"):
			var died:=int((remembered as Dictionary).get("died",-1))
			var office:=String((remembered as Dictionary).get("title",""))
			if died<start_day or died>end_day or office=="" or office=="of the hearth":continue
			var name:=String((remembered as Dictionary).get("name","")).strip_edges()
			if name=="" or out.has(name+", "+office):continue
			out.append(name+", "+office)
			if out.size()>=3:return out
	for event_variant in WorldSimulation.state.simulation_events:
		if not event_variant is Dictionary:continue
		var ev:Dictionary=event_variant
		var day:=int(ev.get("day",-1))
		if day<start_day or day>end_day or String(ev.get("title",""))!="Officeholder Died":continue
		var description:=String(ev.get("description",""))
		var name:=description.get_slice(" died aged",0).strip_edges()
		if name.is_empty() or name==description:continue
		var office:=""
		if "while serving as " in description:office=description.get_slice("while serving as ",1).get_slice(".",0).strip_edges()
		var line:=name+(", "+office if office!="" else "")
		if out.has(line) or Array(out).any(func(told:String)->bool:return told.begins_with(name+", ")):continue
		out.append(line)
		if out.size()>=3:break
	return out


static func _home_name()->String:
	var name:=WorldSimulation.state.settlement_name.strip_edges()
	return name if name!="" else "the new hearth"


static func number(count:int)->String:
	return NUMBER_WORDS[count] if count>=0 and count<NUMBER_WORDS.size() else str(count)


## "1 pregnancy was", "3 pregnancies were"; words for small counts when asked.
static func plural(count:int,singular:String,plural_form:String,words:bool=true)->String:
	return "%s %s" % [number(count) if words else str(count),singular if count==1 else plural_form]


static func sentence_case(text:String)->String:
	return text if text.is_empty() else text.left(1).to_upper()+text.substr(1)
