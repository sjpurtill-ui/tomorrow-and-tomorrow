extends RefCounted
## Direct "scout this city" orders for the scouting window, the foreign-city
## dock and the map contact card. It only calls the existing staff APIs
## (dispatch_scouts for one party, scouting_staff.set_city_watch for a
## standing watch) and keeps no save state of its own.
const V:=preload("res://scripts/hud/city_report_visuals.gd")
const SURVIVAL:=preload("res://scripts/scout_survival.gd")
const MAX_WATCHES:=6
const MIN_PARTY:=2
const MAX_PARTY:=8
const DEFAULT_PARTY:=4
## Last choice per city in this session, so a second order starts where the
## first one left off. Deliberately not saved.
static var remembered:Dictionary={}
static var quote_cache:Dictionary={}
## The last order's answer per city, shown by the docks after they rebuild.
static var last_result:Dictionary={}

static func world()->Node:return WorldSimulation.world
static func staff()->RefCounted:return world().scouting_staff
static func durations()->Array:return world().SCOUT_DURATIONS

static func is_rival(city:Dictionary)->bool:
	if String(city.get("city_id","")).is_empty():return false
	return String(city.get("controller",""))!="player" and String(city.get("civ_id",""))!="player"

static func origin_position()->Vector2:
	var origin:Dictionary=world()._scout_origin(String(staff().data.get("origin_city_id","")))
	var value:Variant=origin.get("position",Vector2.ZERO)
	return value if value is Vector2 else Vector2.ZERO

static func distance_km(city:Dictionary)->float:
	var point:Dictionary=city.get("position",{})
	if not point.has("x"):return 0.0
	return origin_position().distance_to(Vector2(float(point.x),float(point.get("z",0.0))))

## Every reported foreign city, nearest first.
static func rival_cities()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for city:Dictionary in world().city_intelligence.known_cities("player"):
		if not is_rival(city):continue
		city["distance_km"]=distance_km(city)
		result.append(city)
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		return float(a.distance_km)<float(b.distance_km) if not is_equal_approx(float(a.distance_km),float(b.distance_km)) else String(a.city_id)<String(b.city_id))
	return result

## Shortest supported trip that reaches the city with time left to watch it.
## Straight-line distance gets a margin because real routes bend round water.
static func recommended_days(distance:float)->int:
	for days:int in durations():
		var reach:float=world().scout_one_way_range(days)
		if reach<distance*1.25:continue
		var leg:=ceili(distance*1.25/maxf(.01,2.0*reach/float(days)))
		if days-leg*2>=mini(10,days/3):return days
	return int(durations()[-1])

## Watch settings when a watch runs, else this session's last order, else a
## recommendation from distance with a four-person party.
static func defaults(city_id:String,city:Dictionary={})->Dictionary:
	var watch:Dictionary=staff().city_watch(city_id)
	if not watch.is_empty():return {"days":int(watch.duration_days),"personnel":int(watch.personnel),"source":"watch"}
	if remembered.has(city_id):
		var last:Dictionary=remembered[city_id]
		return {"days":int(last.days),"personnel":int(last.personnel),"source":"last"}
	if city.is_empty():city=world().city_intelligence.known("player",city_id)
	return {"days":recommended_days(distance_km(city)),"personnel":DEFAULT_PARTY,"source":"recommended"}

static func remember(city_id:String,days:int,personnel:int)->void:
	remembered[city_id]={"days":days,"personnel":personnel}

static func clamp_party(personnel:int)->int:return clampi(personnel,MIN_PARTY,MAX_PARTY)

## The same quote the City Intelligence screen reads. Cached for the current
## day, party count and stores, since route planning is not free.
static func quote(city_id:String,days:int,personnel:int)->Dictionary:
	var key:=var_to_str([city_id,days,personnel,int(WorldSimulation.state.elapsed_days),world().scout_missions.size(),String(staff().data.get("origin_city_id","")),roundi(float(world().scout_origin_staffing(String(staff().data.get("origin_city_id",""))).get("food",0.0)))])
	if quote_cache.has(key):return quote_cache[key]
	if quote_cache.size()>64:quote_cache.clear()
	var result:Dictionary=world().scout_mission_quote(days,"city:"+city_id,"",personnel)
	quote_cache[key]=result
	return result

static func party_away(city_id:String)->Dictionary:
	for mission:Dictionary in world().scout_missions:
		if String(mission.get("target_id",""))=="city:"+city_id:return mission
	return {}

static func watch_count()->int:
	return (staff().data.get("city_watches",{}) as Dictionary).size()

## Empty when a standing watch may be ordered for this city.
static func watch_block_reason(city_id:String)->String:
	if world().city_intelligence.known("player",city_id).is_empty():return "Only a reported city can be watched."
	var watches:Dictionary=staff().data.get("city_watches",{})
	if not watches.has(city_id) and watches.size()>=MAX_WATCHES:return "Six cities are already watched. Stop one of them to watch this one."
	return ""

## True when the chosen journey is too short to reach the city at all, which
## no amount of waiting fixes (unlike food, people or parties already out).
static func out_of_reach(quoted:Dictionary)->bool:
	if quoted.has("error") or bool(quoted.get("can_dispatch",false)):return false
	return float(quoted.get("target_distance_km",0.0))>float(quoted.get("one_way_range_km",INF)) or String(quoted.get("blocker","")).contains("Choose a longer expedition")

static func reach_reason(quoted:Dictionary)->String:
	var longest:int=int(durations()[-1])
	if int(quoted.get("requested_duration_days",0))>=longest:
		return "Out of reach: even a year's journey carries our scouts about %.0f km, and this city is %.0f km away." % [world().scout_one_way_range(longest),float(quoted.get("target_distance_km",0.0))]
	return "Too far for this journey: choose a longer one."

## Empty when one party can leave now for this city.
static func once_block_reason(city_id:String,quoted:Dictionary)->String:
	if quoted.has("error"):return String(quoted.error)
	if out_of_reach(quoted):return reach_reason(quoted)
	if not bool(quoted.get("can_dispatch",false)):return String(quoted.get("blocker","The party cannot leave yet."))
	return ""

static func send_once(city_id:String,days:int,personnel:int)->Dictionary:
	personnel=clamp_party(personnel);remember(city_id,days,personnel)
	quote_cache.clear()
	var result:Dictionary=world().dispatch_scouts(days,"city:"+city_id,"",personnel)
	_noted(city_id,result if result.has("error") else {"ok":true,"message":"%d scouts have left. Their report arrives when they come home." % personnel})
	return result

static func keep_watching(city_id:String,days:int,personnel:int)->Dictionary:
	personnel=clamp_party(personnel);remember(city_id,days,personnel)
	return _noted(city_id,staff().set_city_watch(city_id,true,days,personnel))

static func stop_watching(city_id:String)->Dictionary:
	return _noted(city_id,staff().set_city_watch(city_id,false))

static func _noted(city_id:String,result:Dictionary)->Dictionary:
	last_result[city_id]={"error":result.has("error"),"text":String(result.get("error",result.get("message",""))),"day":int(WorldSimulation.state.elapsed_days)}
	return result

## Status for the docks: an order's answer first, else what the watch or party is doing.
static func dock_status(city_id:String)->String:
	var parts:Array[String]=[]
	var last:Dictionary=last_result.get(city_id,{})
	if not last.is_empty() and int(last.day)==int(WorldSimulation.state.elapsed_days) and not String(last.text).is_empty():parts.append(String(last.text))
	var status:=status_text(city_id)
	if not status.is_empty() and not parts.has(status):parts.append(status)
	return "\n".join(parts)

static func city_name(city:Dictionary)->String:
	return String(city.get("name","Reported city")).trim_prefix("Reported home of ")

static func people_text(city:Dictionary)->String:
	var field:Dictionary=city.get("fields",{}).get("population",{})
	return "people unknown" if field.is_empty() else V.estimate("population",field)+" people"

static func seen_text(city:Dictionary)->String:
	var fresh:=V.freshness(city,int(WorldSimulation.state.elapsed_days))
	var observed:=int(city.get("observed_day",-1))
	if observed<0:return "never dated"
	var age:=maxi(0,int(WorldSimulation.state.elapsed_days)-observed)
	var when:="seen today" if age==0 else "seen yesterday" if age==1 else "seen %d days ago" % age if age<60 else "seen %d months ago" % roundi(age/30.0) if age<540 else "seen %d years ago" % roundi(age/365.0)
	return "%s · %s" % [when,String(fresh.status).to_lower()]

## One line for what is happening with this city right now.
static func status_text(city_id:String)->String:
	var watch:Dictionary=staff().city_watch(city_id)
	var away:=party_away(city_id)
	if not watch.is_empty():
		return "Watched · "+String(watch.get("status",""))
	if not away.is_empty():
		var remaining:=int(away.get("return_day",0))-int(WorldSimulation.state.elapsed_days)
		return "%d scouts away · due back in about %d days" % [int(away.get("personnel",0)),remaining] if remaining>=0 else "%d scouts away · %d days overdue" % [int(away.get("personnel",0)),-remaining]
	return ""

static func cost_text(quoted:Dictionary)->String:
	if not bool(quoted.get("can_dispatch",false)):return ""
	var line:="%d scouts away for %d days · %d food" % [int(quoted.personnel),int(quoted.duration_days),roundi(float(quoted.provisions))]
	line+=" · %d days out, %d watching, %d back" % [int(quoted.travel_leg_days),int(quoted.observation_days),int(quoted.travel_leg_days)]
	return line

static func risk_text(quoted:Dictionary)->String:
	if not bool(quoted.get("can_dispatch",false)):return ""
	var field:Dictionary=quoted.get("field_risk",{})
	var patrol:Dictionary=quoted.get("risk",{})
	return "Road danger %s: %s. Chance of being caught by their patrols: %s." % [String(field.get("label","low")).to_lower(),SURVIVAL.odds_phrase(field),String(patrol.get("label","low")).to_lower()]

## Everything a row needs, in one dictionary, for any of the three entry points.
static func row(city:Dictionary,days:int=-1,personnel:int=-1)->Dictionary:
	var id:=String(city.city_id)
	var chosen:=defaults(id,city)
	if days<0:days=int(chosen.days)
	if personnel<0:personnel=int(chosen.personnel)
	personnel=clamp_party(personnel)
	var quoted:=quote(id,days,personnel)
	var watch:Dictionary=staff().city_watch(id)
	return {"city_id":id,"name":city_name(city),"people":people_text(city),"distance_km":float(city.get("distance_km",distance_km(city))),"seen":seen_text(city),
		"days":days,"personnel":personnel,"quote":quoted,"cost":cost_text(quoted),"risk":risk_text(quoted),
		"watching":not watch.is_empty(),"watch":watch,"away":not party_away(id).is_empty(),"status":status_text(id),
		"once_blocked":once_block_reason(id,quoted),"watch_blocked":"" if not watch.is_empty() else (reach_reason(quoted) if out_of_reach(quoted) else watch_block_reason(id))}

## Dock action items (foreign-city dock and map contact card).
static func dock_items(city_id:String,after:Callable=Callable())->Array:
	var city:Dictionary=world().city_intelligence.known("player",city_id)
	if city.is_empty() or not is_rival(city):return []
	var model:=row(city)
	var days:=int(model.days);var personnel:=int(model.personnel)
	var once_blocked:=String(model.once_blocked)
	var send:=func()->void:
		send_once(city_id,days,personnel)
		if after.is_valid():after.call()
	var watch_on:=func()->void:
		keep_watching(city_id,days,personnel)
		if after.is_valid():after.call()
	var watch_off:=func()->void:
		stop_watching(city_id)
		if after.is_valid():after.call()
	var items:Array=[{"label":"Send scouts once","sub":String(model.cost) if once_blocked.is_empty() else once_blocked,"primary":true,"disabled":not once_blocked.is_empty(),
		"tip":String(model.risk) if once_blocked.is_empty() else once_blocked,"on_press":send}]
	if bool(model.watching):
		items.append({"label":"Stop watching","sub":String(model.watch.get("status","")),"on_press":watch_off,"tip":"No further departures. A party already away finishes and returns."})
	else:
		var blocked:=String(model.watch_blocked)
		items.append({"label":"Keep watching","sub":"%d scouts, %d-day visits, one after another" % [personnel,days] if blocked.is_empty() else blocked,"disabled":not blocked.is_empty(),
			"tip":"Staff send one party at a time and the next after each return. Reports still travel home; there is no live view." if blocked.is_empty() else blocked,"on_press":watch_on})
	return items
