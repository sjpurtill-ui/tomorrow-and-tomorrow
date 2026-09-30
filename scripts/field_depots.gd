extends RefCounted
## FIELD DEPOTS (docs/MILITARY_SYSTEM_V2.md §3): stores laid down ahead of a
## campaign, HOI4's supply hubs in our own terms.
##
## A band told to lay a depot (army_orders.gd, "depot") marches to the spot
## and builds it there: sheds, bread ovens and a fence, DEPOT_WORK man-days
## and never fewer than MIN_DAYS. A standing depot is a relay on the supply
## line exactly as a town we hold (supply_state.RELAY): the line from it
## starts at half the cost of reaching it, so the bands beyond it are fed as
## if the road behind the depot were half as long. It asks Forward Supply
## Depots (research); we keep LIMIT at once (MAGAZINE_LIMIT with Army
## Magazines), and a new one gives up the oldest. A hostile host passing
## within RAID_KM of a depot no band of ours stands by burns it.
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
## A hostile host this near a depot no band of ours stands by burns it.
const RAID_KM:=12.0
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
	return ""

## The depot a new one would give up ({} while there is room).
func replaces()->Dictionary:
	if host.field_depots.size()<limit(): return {}
	return host.field_depots[0]

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
	_chronicle("A Depot Laid Down",text,"depot:%d" % next_id)

## A depot no band of ours stands by burns when a host at war with us passes.
func _raid_day()->void:
	if host.field_depots.is_empty() or WorldSimulation.world==null: return
	var today:=float(WorldSimulation.state.elapsed_days)
	var hostile:Array=[]
	var world:Variant=WorldSimulation.world
	for f in world.foreign_formations:
		var rec:Dictionary=f
		if String(rec.get("kind",""))=="scout" or today<float(rec.get("disabled_until_day",0)): continue
		if not WO.at_war(String(rec.get("civ_id",""))): continue
		var at:Vector2=world._foreign_formation_position(rec,today)
		if at.is_finite(): hostile.append({"pos":at,"civ_id":String(rec.get("civ_id",""))})
	if hostile.is_empty(): return
	var ours:Array=[]
	for a in host.field_armies:
		var record:Dictionary=a
		if int(record.get("troops",0))<=0 or bool(record.get("embarked",false)): continue
		var p:=Supply.force_pos(record)
		if p.is_finite(): ours.append(p)
	for i in range(host.field_depots.size()-1,-1,-1):
		var depot:Dictionary=host.field_depots[i]
		var at:=Vector2(float(depot.x),float(depot.z))
		var guarded:=false
		for p:Vector2 in ours:
			if p.distance_to(at)<=RAID_KM: guarded=true; break
		if guarded: continue
		for h:Dictionary in hostile:
			if (h.pos as Vector2).distance_to(at)>RAID_KM: continue
			host.field_depots.remove_at(i)
			_chronicle("A Depot Burned","The %s burned our depot %s. No band of ours stood by it." % [_host_words(String(h.civ_id)),place_words(at)],"depot_burned:%d" % int(depot.get("id",0)))
			break

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
