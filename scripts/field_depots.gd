extends RefCounted
## FIELD DEPOTS (docs/MILITARY_SYSTEM_V2.md §3): stores laid down ahead of a
## campaign, HOI4's supply hubs in our own terms.
##
## A band told to lay a depot (army_orders.gd, "depot") marches to the spot
## and builds it there: sheds, bread ovens and a fence, DEPOT_WORK man-days
## and never fewer than MIN_DAYS. A standing depot feeds the carriers who
## pass it: what they eat on the road is reckoned as if the road behind the
## depot were half as long (supply_state.RELAY), so more of each load
## arrives beyond it. They still walk the whole road from home, so it does
## not shorten their round trip (supply_state.trip_effort): a depot saves
## food, not carriers. It asks Forward Supply Depots (research); we keep
## LIMIT at once (MAGAZINE_LIMIT with Army Magazines), counting those being
## laid, and a new one gives up the oldest. A hostile host whose day's march
## passes within RAID_KM of a depot burns it, unless our bands within RAID_KM
## are at least half its strength (GUARD_SHARE).
##
## Records: host.field_depots [{id, name, x, z, built_day, by}] (saved);
## a band's work in hand: its record's depot_site {x, z, work, days}.
## Only the player's bands lay depots (rivals' generals do not yet).

const Supply:=preload("res://scripts/supply_state.gd")
const WO:=preload("res://scripts/court_war_orders.gd")
const Marks:=preload("res://scripts/hud/army_marks.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

## Man-days of work in a depot, and the fewest days it takes however many dig.
const DEPOT_WORK:=900.0
const MIN_DAYS:=5
## The fewest hands that can build one.
const MIN_MEN:=20
## Adoption of the research that lets us build them (and hold more).
const GATE:=0.1
const LIMIT:=2
const MAGAZINE_LIMIT:=4
## A hostile host this near a depot burns it unless our bands this near are
## at least GUARD_SHARE of its strength.
const RAID_KM:=12.0
const GUARD_SHARE:=0.5
## A band this near its site is at work there.
const AT_SITE_KM:=3.0

var host

func _init(owner)->void:
	host=owner

func known()->bool:
	return float(host._adoption("forward_supply_depots"))>=GATE

func limit()->int:
	return MAGAZINE_LIMIT if float(host._adoption("army_supply_magazines"))>=GATE else LIMIT

## Days a band of `men` takes to build one.
static func days_for(men:int)->int:
	return maxi(MIN_DAYS,ceili(DEPOT_WORK/float(maxi(1,men))))

## Why `men` cannot lay a depot, or "".
func blocked(men:int)->String:
	if not known(): return "We have not learned to stock depots ahead of a campaign (Forward Supply Depots)."
	if men<MIN_MEN: return "A depot takes at least %d hands to build." % MIN_MEN
	if laying()>=limit(): return "Bands are already laying %d depots, as many as we keep." % laying()
	return ""

## Depots our bands are laying now.
func laying()->int:
	var n:=0
	for a in host.field_armies:
		if not progress(a).is_empty(): n+=1
	return n

## The depot a new one would give up when it stands, counting those being
## laid first ({} while there is room).
func replaces()->Dictionary:
	var index:int=host.field_depots.size()+laying()-limit()
	if index<0 or index>=host.field_depots.size(): return {}
	return host.field_depots[index]

## What a depot at `at` would do for a band standing there, on today's
## line: {days the carriers walk, now and with: the share of each load that
## arrives}; {} where no carrier reaches.
static func impact_at(at:Vector2)->Dictionary:
	var f:=Supply.field()
	var e:=Supply.effort_at(f,at)
	if not is_finite(float(e.effort)): return {}
	var who:=String(f.carrier) if not f.is_empty() else Supply.carrier()
	var chill:=float(Supply.land_at(f,at,Supply.today()).cold)
	var trip:=Supply.trip_effort(e)
	var endurance:=Supply.endurance_today()
	var now:=Supply.haul_share(Supply.haul_days(float(e.effort),who,chill),who,endurance)
	var with_depot:=Supply.haul_share(Supply.haul_days(minf(float(e.effort),trip*Supply.RELAY),who,chill),who,endurance)
	return {"days":Supply.haul_days(trip,who,chill),"now":now,"with":with_depot}

## "a depot 60 km north-east" (where it stands from home).
static func place_words(at:Vector2)->String:
	var home:Vector2=WorldSimulation.world.player_world_origin
	var km:=roundi(at.distance_to(home))
	var way:=Marks.compass(at-home)
	return "%s km %s" % [EraWords.grouped(km),way] if way!="" else "%s km out" % EraWords.grouped(km)

## Sets a band marching to `at` to build a depot there.
func assign(army_id:int,at:Vector2)->void:
	var index:int=host._field_army_index(army_id)
	if index<0: return
	var record:Dictionary=host.field_armies[index]
	# Where the march will end (the land road may stop short of the click).
	var heading:Variant=record.get("destination_position",{})
	if String(record.get("status",""))=="moving" and heading is Dictionary and (heading as Dictionary).has("x"):
		at=Vector2(float(heading.x),float(heading.get("z",at.y)))
	elif String(record.get("status",""))!="moving":
		var here:=Supply.force_pos(record)
		if here.is_finite(): at=here
	record["depot_site"]={"x":at.x,"z":at.y,"work":0.0,"days":0}
	host.field_armies[index]=record

## Work done and to do on a band's depot: {} or {work, needed, days_left}.
static func progress(record:Dictionary)->Dictionary:
	var site:Variant=record.get("depot_site",{})
	if not site is Dictionary or (site as Dictionary).is_empty(): return {}
	var men:=maxi(1,int(record.get("troops",0)))
	var work:=float(site.get("work",0.0))
	var left:=maxf(0.0,DEPOT_WORK-work)
	var days_left:=maxi(ceili(left/float(men)),MIN_DAYS-int(site.get("days",0)))
	return {"work":work,"needed":DEPOT_WORK,"days_left":maxi(0,days_left),"x":float(site.x),"z":float(site.z)}

## The day's work and raids (after the day's marches).
func day()->void:
	if WorldSimulation.actor_id!="player": return
	_build_day()
	_raid_day()

func _build_day()->void:
	var span:=maxf(1.0,float(WorldSimulation.span))
	for index in host.field_armies.size():
		var record:Dictionary=host.field_armies[index]
		var site:Variant=record.get("depot_site",{})
		if not site is Dictionary or (site as Dictionary).is_empty(): continue
		var at:=Vector2(float(site.x),float(site.z))
		var pos:=Supply.force_pos(record)
		var men:=int(record.get("troops",0))
		# Sent elsewhere, or too few left: the work is dropped.
		var heading:Variant=record.get("destination_position",{})
		var bound:=heading is Dictionary and Vector2(float((heading as Dictionary).get("x",INF)),float((heading as Dictionary).get("z",INF))).distance_to(at)<=AT_SITE_KM
		if String(record.get("status",""))=="moving":
			if not bound: record.erase("depot_site"); host.field_armies[index]=record
			continue
		if not pos.is_finite() or pos.distance_to(at)>AT_SITE_KM or men<MIN_MEN or bool(record.get("embarked",false)):
			record.erase("depot_site"); host.field_armies[index]=record
			if men<MIN_MEN and men>0: _chronicle("A Depot Left Unfinished","%s, down to %d, could not finish the depot %s." % [String(record.get("name","A band")),men,place_words(at)],"depot_dropped:%d:%d" % [int(record.get("army_id",0)),int(WorldSimulation.state.elapsed_days)])
			continue
		if host.command_hierarchy.battle.engaged(int(record.get("army_id",0))): continue
		site["work"]=float(site.get("work",0.0))+float(men)*span
		site["days"]=int(site.get("days",0))+int(span)
		record["depot_site"]=site
		if float(site.work)>=DEPOT_WORK and int(site.days)>=MIN_DAYS:
			record.erase("depot_site")
			host.field_armies[index]=record
			_finish(record,at)
			continue
		host.field_armies[index]=record

func _finish(record:Dictionary,at:Vector2)->void:
	var today:=int(WorldSimulation.state.elapsed_days)
	var given_up:=replaces()
	if not given_up.is_empty(): host.field_depots.erase(given_up)
	var next_id:=1
	for d in host.field_depots: next_id=maxi(next_id,int((d as Dictionary).get("id",0))+1)
	var name:="Depot "+place_words(at)
	var band:=String(record.get("name","A band"))
	host.field_depots.append({"id":next_id,"name":name,"x":at.x,"z":at.y,"built_day":today,"by":band})
	var text:="%s finished a depot %s. Bands beyond it are fed as if the road behind it were half as long." % [band,place_words(at)]
	if not given_up.is_empty(): text+=" We keep %d depots; the one %s was given up." % [limit(),String(given_up.name).trim_prefix("Depot ")]
	_chronicle("A Depot Laid Down",text,"depot:%d:%d" % [next_id,today])

## A host at war with us whose day's march passes a depot burns it, unless
## our bands there are at least half its strength.
func _raid_day()->void:
	if host.field_depots.is_empty() or WorldSimulation.world==null: return
	var today:=float(WorldSimulation.state.elapsed_days)
	var span:=maxf(1.0,float(WorldSimulation.span))
	var hostile:Array=[]
	var world:Variant=WorldSimulation.world
	for f in world.foreign_formations:
		var rec:Dictionary=f
		if String(rec.get("kind",""))=="scout" or today<float(rec.get("disabled_until_day",0)): continue
		var civ_id:=String(rec.get("civ_id",""))
		if not WO.at_war(civ_id): continue
		var at:Vector2=world._foreign_formation_position(rec,today)
		var was:Vector2=world._foreign_formation_position(rec,today-span)
		if not at.is_finite(): continue
		if not was.is_finite(): was=at
		hostile.append({"from":was,"to":at,"civ_id":civ_id,"men":_host_men(world,rec)})
	if hostile.is_empty(): return
	var ours:Array=[]
	for a in host.field_armies:
		var record:Dictionary=a
		if int(record.get("troops",0))<=0 or bool(record.get("embarked",false)): continue
		var p:=Supply.force_pos(record)
		if p.is_finite(): ours.append({"pos":p,"men":int(record.troops)})
	for i in range(host.field_depots.size()-1,-1,-1):
		var depot:Dictionary=host.field_depots[i]
		var at:=Vector2(float(depot.x),float(depot.z))
		var guards:=0
		for b:Dictionary in ours:
			if (b.pos as Vector2).distance_to(at)<=RAID_KM: guards+=int(b.men)
		for h:Dictionary in hostile:
			var nearest:=Geometry2D.get_closest_point_to_segment(at,h.from,h.to)
			if nearest.distance_to(at)>RAID_KM or float(guards)>=float(h.men)*GUARD_SHARE: continue
			host.field_depots.remove_at(i)
			var guarded:=(" Our %d there were too few to stop them." % guards) if guards>0 else " No band of ours stood by it."
			_chronicle("A Depot Burned","The %s burned our depot %s.%s" % [_host_words(String(h.civ_id)),place_words(at),guarded],"depot_burned:%d:%d" % [int(depot.get("id",0)),int(today)])
			break

## A host's men, as the world counts them (civilization_system).
static func _host_men(world:Variant,rec:Dictionary)->int:
	if rec.has("actual_troops"): return int(rec.actual_troops)
	var index:int=world._civilization_index(String(rec.get("civ_id","")))
	if index<0: return 1
	return maxi(1,roundi(float(world.land_military_population(world.civilizations[index]))*float(rec.get("strength_share",0.06))))

static func _host_words(civ_id:String)->String:
	var name:=WO.civ_name(civ_id)
	return ("%s host" % name) if name!="" else "enemy host"

static func _chronicle(title:String,text:String,key:String)->void:
	preload("res://scripts/chronicle.gd").record({"title":title,"text":text,"kind":"war","tier":"notice","key":key})

## Saved depots, cleaned: [{id, name, x, z, built_day, by}].
static func clean(raw:Variant)->Array:
	var out:Array=[]
	if not raw is Array: return out
	for d in raw:
		if not d is Dictionary: continue
		var row:Dictionary=d
		var x:=float(row.get("x",NAN)); var z:=float(row.get("z",NAN))
		if not is_finite(x) or not is_finite(z): continue
		out.append({"id":int(row.get("id",out.size()+1)),"name":String(row.get("name","Depot")),"x":x,"z":z,"built_day":int(row.get("built_day",0)),"by":String(row.get("by",""))})
	return out
