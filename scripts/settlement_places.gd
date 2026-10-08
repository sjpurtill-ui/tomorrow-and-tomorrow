extends RefCounted
## PLACES OF THE ONE SEAT: towns that spring up without a second ledger.
##
## A people keeps one seat and one ledger (one_seat.gd). As it grows, some of
## its families settle apart: a fishing hamlet on the shore, a ford town on
## the river, a herders' stead out on the grass. Each is a PLACE: a name, a
## spot, the water that drew people there and a share of the people. It has
## no people, stores, labour or water of its own. Its people are the realm's
## people times its share, read when asked (people()), so the daily systems
## never loop over places and a people of twelve places costs what a people
## of one costs. (The user, 2026-10-08: organic expansion, but embedded in
## the central engine; the old daughter towns made every daily system run
## once per town.)
##
## Once a month (PASS_DAYS) the shares drift toward what draws people
## (pull()): water first, then age, the sea once boats go out, the seat's
## crowding, and a setback after a flood. A place that empties is left and
## kept as a ruin. When the people has room for another place and is fed,
## a new one may be founded, coast and lake shore first, then rivers, and
## dry ground only within the worked land (the user, 2026-10-08: "expansions
## should hew towards coasts and water access before they go anywhere else").
##
## What a place changes in the engine, all on the one ledger:
##   - a shore place works its coast for the whole people: the seat's coastal
##     profile reads the best shore place (coast_context), so fish, salt and
##     the sea lanes open, and the storms and erosion come with them;
##   - a flood can come in at a river, lake or sea place (flood_exposure,
##     flood_place), and sets that place back;
##   - names: no other town is given a place's name (settlement_model
##     names_in_use).
##
## Records live in the seat's own register entry (seat["places"]), so they
## are saved with it and need no migration. Graphics read them through
## snapshot() (docs/design/ORGANIC_PLACES.md, the contract for the map art).
## Static helpers; preload.

const OneSeat:=preload("res://scripts/one_seat.gd")
const RealmReach:=preload("res://scripts/realm_reach.gd")
const Extent:=preload("res://scripts/settlement_visual_extent.gd")
const Lang:=preload("res://scripts/people_language.gd")

## Days between passes.
const PASS_DAYS:=30
## Most places a people keeps (ruins aside), and most ruins remembered.
const MAX_PLACES:=12
const MAX_RUINS:=4
## Room for places: one per PEOPLE_PER_PLACE under the square root (400: 1;
## 1,600: 2; 10,000: 5; 57,600: 12).
const PEOPLE_PER_PLACE:=400.0
## Chance a pass with room and food founds a place (about one in three
## months, so a place comes some seasons after there is room for it).
const FOUND_CHANCE:=0.3
## Days of food in store below which no family leaves to settle apart.
const FOUND_FOOD_DAYS:=30.0
## Bearings walked per founding and the step along each, and how close two
## places may stand.
const RAYS:=16
const RAY_STEP_KM:=1.5
const MIN_SPACING_KM:=5.0
## Where a dry-ground place may stand at most, and how far people will go for
## shore water (a share of the realm's reach, never past WATER_MAX_KM).
const WATER_REACH_SHARE:=0.5
const WATER_MAX_KM:=160.0
## Water sampling: shore rings, open-water rings, a river this close.
const SHORE_KM:=[0.5,1.5]
const OPEN_KM:=[8.0,16.0]
const RIVER_KM:=1.5
const WATER_HEIGHT:=0.015
const LAND_HEIGHT:=0.012
## Site order: a coast before a lake before a river before dry ground.
const KIND_RANK:={"coast":4,"lake":3,"river":2,"inland":1}
## What draws people to a place, by its water.
const KIND_PULL:={"coast":1.5,"lake":1.3,"river":1.15,"inland":0.75}
## What holds people in the seat: its pull against all the places together.
const SEAT_PULL:=2.5
## Most of the people living away from the seat: 15% at 1,000, 35% at
## 100,000, never more than 55%.
const AWAY_BASE:=0.15
const AWAY_PER_DECADE:=0.10
const AWAY_MAX:=0.55
## Share of the gap to its target a place closes each pass.
const DRIFT:=0.06
## Years for a place to draw people at its full pull.
const MATURE_YEARS:=25.0
## The families who found a place, and the least share a living place keeps.
const FOUNDERS:=12.0
const ABANDON_SHARE:=0.0015
const ABANDON_AFTER_DAYS:=3650
## The draw left to a place the people no longer has room for.
const OVER_ROOM_PULL:=0.15
## A flood sets the place back this much for this long.
const FLOOD_SETBACK:=0.6
const FLOOD_SETBACK_DAYS:=1095
## A place holding this share of the people works its shore fully for the
## people (coast_context); a place not the seat works it at PLACE_SHORE_WORK.
const SHORE_FULL_SHARE:=0.04
const PLACE_SHORE_WORK:=0.85
## A place's flood exposure, against the seat's own river camp.
const FLOOD_EXPOSURE:={"coast":0.7,"lake":0.8,"river":1.0,"inland":0.0}

## Test seam: {height_at: Callable(x,z)->float, river_distance_at:
## Callable(x,z)->float}. Never set by the game, which reads the world's own
## geography (WorldSimulation.context_provider).
static var geography_hook:Callable=Callable()


## The living places of the people in scope (not ruins), oldest first.
static func list()->Array:
	var out:=[]
	for place:Variant in _records():
		if place is Dictionary and String((place as Dictionary).get("status","living"))!="ruin":out.append(place)
	return out

## Ruins of the people in scope.
static func ruins()->Array:
	var out:=[]
	for place:Variant in _records():
		if place is Dictionary and String((place as Dictionary).get("status",""))=="ruin":out.append(place)
	return out

static func find(place_id:String)->Dictionary:
	for place:Variant in _records():
		if place is Dictionary and String((place as Dictionary).get("id",""))==place_id:return place
	return {}

## The people of a place: the realm's people times its share.
static func people(place:Dictionary)->int:
	if String(place.get("status",""))=="ruin":return 0
	return roundi(maxf(0.0,float(place.get("share",0.0)))*maxf(0.0,float(WorldSimulation.state.population_exact)))

## The share of the people living away from the seat, in places.
static func away_share()->float:
	var total:=0.0
	for place:Dictionary in list():total+=maxf(0.0,float(place.get("share",0.0)))
	return clampf(total,0.0,1.0)

## The people of the seat itself.
static func seat_people()->int:
	return roundi(maxf(0.0,float(WorldSimulation.state.population_exact))*(1.0-away_share()))

## How many places the people has room for.
static func room(population:float)->int:
	return clampi(floori(sqrt(maxf(0.0,population)/PEOPLE_PER_PLACE)),0,MAX_PLACES)


## The monthly pass, from the calendar (civilization_day.gd secondary_plan).
## Returns the place founded or left this pass, if any ({} otherwise).
static func monthly(day:int)->Dictionary:
	if not OneSeat.has_seat():return {}
	var seat:=OneSeat.seat_record()
	if day-int(seat.get("places_day",-PASS_DAYS))<PASS_DAYS:return {}
	seat["places_day"]=day
	if not seat.has("places"):seat["places"]=[]
	drift(day)
	var left:=_leave_empty(day)
	if not left.is_empty():return left
	return _maybe_found(day,seat)


## Moves every place's share part of the way to what draws people to it.
static func drift(day:int)->void:
	var places:=list()
	if places.is_empty():return
	var population:=maxf(0.0,float(WorldSimulation.state.population_exact))
	# When the people shrink below the room for their places, the smallest
	# places lose their draw and empty first.
	var room_now:=room(population)
	var ranked:=places.duplicate()
	ranked.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.get("share",0.0))>float(b.get("share",0.0)))
	var pulls:=[]
	var total:=SEAT_PULL
	for place:Dictionary in places:
		var p:=pull(place,day)
		if ranked.find(place)>=room_now:p*=OVER_ROOM_PULL
		pulls.append(p)
		total+=p
	var away_cap:=away_limit(population)
	var targets:=[]
	var target_sum:=0.0
	for index in places.size():
		var t:=float(pulls[index])/total
		targets.append(t)
		target_sum+=t
	var scale:=minf(1.0,away_cap/target_sum) if target_sum>0.0 else 1.0
	for index in places.size():
		var place:Dictionary=places[index]
		var share:=float(place.get("share",0.0))
		place["share"]=clampf(share+DRIFT*(float(targets[index])*scale-share),0.0,1.0)
		place["target"]=float(targets[index])*scale

## What draws people to a place, against SEAT_PULL.
static func pull(place:Dictionary,day:int)->float:
	var kind:=String(place.get("kind","inland"))
	var value:=float(KIND_PULL.get(kind,0.75))
	var age_years:=maxf(0.0,float(day-int(place.get("founded_day",day))))/365.0
	value*=clampf(age_years/MATURE_YEARS,0.08,1.0)
	# The sea draws more once boats go farther out (research_mechanics sea_reach).
	if kind=="coast":value*=_sea_reach()
	value*=_crowding_pull()
	if day<int(place.get("setback_until",-1)):value*=FLOOD_SETBACK
	return value

## Most of the people living away from the seat.
static func away_limit(population:float)->float:
	if population<=0.0:return 0.0
	return clampf(AWAY_BASE+AWAY_PER_DECADE*log(maxf(1.0,population/1000.0))/log(10.0),0.05,AWAY_MAX)


static func _leave_empty(day:int)->Dictionary:
	for place:Dictionary in list():
		if day-int(place.get("founded_day",day))<ABANDON_AFTER_DAYS:continue
		if float(place.get("share",0.0))>=ABANDON_SHARE and people(place)>=roundi(FOUNDERS*0.5):continue
		place["status"]="ruin"
		place["left_day"]=day
		place["share"]=0.0
		_trim_ruins()
		_revise()
		if WorldSimulation.state==GameState:_tell_left(place)
		return {"left":place}
	return {}

static func _trim_ruins()->void:
	var seat:=OneSeat.seat_record()
	var records:Array=seat.get("places",[])
	while ruins().size()>MAX_RUINS:
		for index in records.size():
			if String((records[index] as Dictionary).get("status",""))=="ruin":
				records.remove_at(index)
				break


static func _maybe_found(day:int,seat:Dictionary)->Dictionary:
	var state=WorldSimulation.state
	var population:=maxf(0.0,float(state.population_exact))
	if list().size()>=room(population):return {}
	if float(state.simulation_metrics.get("food_days",0.0))<FOUND_FOOD_DAYS:return {}
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:%s:place:%d" % [int(state.world_seed),String(WorldSimulation.actor_id),day])
	if rng.randf()>=FOUND_CHANCE:return {}
	var origin:Vector2=seat.get("position",Vector2.ZERO) if seat.get("position") is Vector2 else Vector2.ZERO
	var site:=choose_site(origin,population,rng)
	if site.is_empty():return {}
	var place:=found(day,site,population)
	return {"founded":place}

## The best site for a new place about `origin`: a coast if any is in reach,
## else a lake shore, else a river, else dry ground within the worked land.
## {} when nothing will do. Walks RAYS bearings outward from the seat in
## RAY_STEP_KM steps, stopping each at the first water it meets (a shore is a
## thin line random spots would miss): a bounded number of height samples,
## and only on a founding.
static func choose_site(origin:Vector2,population:float,rng:RandomNumberGenerator)->Dictionary:
	var geo:=_geography(origin)
	var inner:=maxf(3.0,Extent.radius(roundi(population))*1.4)
	var dry_reach:=maxf(inner+MIN_SPACING_KM,OneSeat.reach_km())
	var realm:=RealmReach.ours() if WorldSimulation.actor_id=="player" else {}
	var water_reach:=maxf(dry_reach,minf(WATER_MAX_KM,float(realm.get("reach",dry_reach))*WATER_REACH_SHARE))
	var taken:=[origin]
	for place:Variant in _records():
		if place is Dictionary and (place as Dictionary).get("position") is Vector2:taken.append((place as Dictionary).position)
	var height:Callable=geo.get("height_at",Callable())
	var river:Callable=geo.get("river_distance_at",Callable())
	var turn:=rng.randf()*TAU
	var candidates:=[]
	for ray in RAYS:
		var direction:=Vector2.from_angle(turn+TAU*float(ray)/float(RAYS))
		var last_land:=-1.0
		var river_at:=-1.0
		var distance:=inner
		while distance<=water_reach:
			var at:=origin+direction*distance
			if height.is_valid() and float(height.call(at.x,at.y))<=WATER_HEIGHT:
				if last_land>0.0:
					# Find the water's edge between the last dry step and this one.
					var dry:=last_land
					var wet:=distance
					for halving in 5:
						var mid:=(dry+wet)*0.5
						var p:=origin+direction*mid
						if float(height.call(p.x,p.y))<=WATER_HEIGHT:wet=mid
						else:dry=mid
					candidates.append(origin+direction*maxf(inner,dry-0.3))
				break
			last_land=distance
			if river_at<0.0 and river.is_valid() and float(river.call(at.x,at.y))<=RIVER_KM:river_at=distance
			distance+=RAY_STEP_KM
		if river_at>0.0:candidates.append(origin+direction*river_at)
		candidates.append(origin+direction*lerpf(inner,dry_reach,rng.randf()))
	var best:={}
	var best_score:=-INF
	for at:Vector2 in candidates:
		var near:=false
		for other:Vector2 in taken:
			if at.distance_to(other)<MIN_SPACING_KM:near=true;break
		if near:continue
		var site:=survey(at,geo)
		if site.is_empty():continue
		var distance:=at.distance_to(origin)
		if String(site.kind)=="inland" and distance>dry_reach:continue
		var score:=float(KIND_RANK.get(String(site.kind),1))*10.0-distance/water_reach*3.0+rng.randf()*0.5
		if score>best_score:
			best_score=score
			best=site
			best["distance_km"]=distance
	return best

## What a spot offers: {position, kind, shoreline, marine, open_water} or {}
## when it is under water.
static func survey(at:Vector2,geo:Dictionary)->Dictionary:
	var height:Callable=geo.get("height_at",Callable())
	if not height.is_valid():return {"position":at,"kind":"inland","shoreline":0.0,"marine":0.0,"open_water":0.0}
	if float(height.call(at.x,at.y))<=LAND_HEIGHT:return {}
	var nearest:=INF
	var facing:=Vector2.ZERO
	for ring:float in SHORE_KM:
		for bearing in 8:
			var direction:=Vector2.from_angle(TAU*float(bearing)/8.0)
			var p:=at+direction*ring
			if float(height.call(p.x,p.y))<=WATER_HEIGHT:
				nearest=minf(nearest,ring)
				facing+=direction
		if nearest<INF:break
	if nearest<INF:
		var wet:=0
		var count:=0
		for ring:float in OPEN_KM:
			for bearing in 8:
				var p:=at+Vector2.from_angle(TAU*(float(bearing)+0.5)/8.0)*ring
				count+=1
				if float(height.call(p.x,p.y))<=WATER_HEIGHT:wet+=1
		var open:=float(wet)/float(count)
		var shoreline:=clampf(1.0-nearest/16.0,0.0,1.0)
		return {"position":at,"kind":"coast" if open>=0.25 else "lake","shoreline":shoreline,"marine":shoreline*smoothstep(0.05,0.55,open),"open_water":open,"facing":facing.normalized()}
	var river:Callable=geo.get("river_distance_at",Callable())
	if river.is_valid() and float(river.call(at.x,at.y))<=RIVER_KM:
		return {"position":at,"kind":"river","shoreline":0.0,"marine":0.0,"open_water":0.0}
	return {"position":at,"kind":"inland","shoreline":0.0,"marine":0.0,"open_water":0.0}

## Founds a place on `site` with its founding families.
static func found(day:int,site:Dictionary,population:float)->Dictionary:
	var seat:=OneSeat.seat_record()
	if not seat.has("places"):seat["places"]=[]
	var at:Vector2=site.position
	var kind:=String(site.get("kind","inland"))
	var used:Dictionary=WorldSimulation.settlements.names_in_use() if WorldSimulation.settlements!=null and WorldSimulation.settlements.has_method("names_in_use") else {}
	var owner:=String(WorldSimulation.actor_id) if String(WorldSimulation.actor_id)!="" else "player"
	var land:=String({"coast":"shore","lake":"reed","river":"river"}.get(kind,"plain"))
	var name:=Lang.town(owner,int(WorldSimulation.state.world_seed),"place:%d:%d" % [roundi(at.x*10.0),roundi(at.y*10.0)],used,land)
	if name=="" or used.has(name.to_lower()):name="%s %d" % [name if name!="" else "Steading",(seat.places as Array).size()+1]
	var next:=int(seat.get("places_next",1))
	seat["places_next"]=next+1
	var place:={"id":"%s-place-%d" % [String(seat.get("id","seat")),next],"name":name,"position":at,"kind":kind,
		"shoreline":float(site.get("shoreline",0.0)),"marine":float(site.get("marine",0.0)),"open_water":float(site.get("open_water",0.0)),
		"facing":site.get("facing",Vector2.ZERO) if site.get("facing") is Vector2 else Vector2.ZERO,
		"founded_day":day,"share":clampf(FOUNDERS/maxf(1.0,population),0.002,0.03),"target":0.0,"status":"living"}
	(seat.places as Array).append(place)
	_revise()
	if WorldSimulation.state==GameState:_tell_founded(place)
	return place


## The seat's coastal context with the best of its shore `places` (the
## seat record's "places") working its coast for the whole people
## (settlement_model.gd coastal_site_profile). Takes and returns the context
## fields that profile reads.
static func coast_context(context:Dictionary,places:Array)->Dictionary:
	var best:={}
	var best_value:=0.0
	for item:Variant in places:
		if not item is Dictionary:continue
		var place:Dictionary=item
		if String(place.get("status","living"))=="ruin" or not String(place.get("kind","")) in ["coast","lake"]:continue
		var work:=PLACE_SHORE_WORK*clampf(float(place.get("share",0.0))/SHORE_FULL_SHARE,0.0,1.0)
		var value:=float(place.get("shoreline",0.0))*work
		if value>best_value:best_value=value;best=place
	if best.is_empty() or best_value<=float(context.get("shoreline_access",0.0)):return context
	var out:=context.duplicate()
	var work:=best_value/maxf(0.0001,float(best.get("shoreline",1.0)))
	var open:=float(best.get("open_water",0.0))
	out["shoreline_access"]=best_value
	out["marine_opportunity"]=maxf(float(context.get("marine_opportunity",0.0)),smoothstep(0.05,0.55,open))
	out["salt_opportunity"]=maxf(float(context.get("salt_opportunity",0.0)),0.42+open*0.48)
	out["open_water_exposure"]=maxf(float(context.get("open_water_exposure",0.0)),open)
	# The sea's costs come with it: storms and the shore wearing away.
	out["storm_exposure"]=maxf(float(context.get("storm_exposure",0.0)),open*0.4)
	out["erosion_exposure"]=maxf(float(context.get("erosion_exposure",0.0)),0.3*lerpf(0.55,1.0,open))
	out["shore_place"]=String(best.get("name",""))
	out["shore_place_work"]=work
	return out

## How much of the people lives where water can come in (0..1), for the
## flood hazard of a people whose seat is not a river camp.
static func flood_exposure()->float:
	var total:=0.0
	for place:Dictionary in list():
		total+=float(FLOOD_EXPOSURE.get(String(place.get("kind","inland")),0.0))*clampf(float(place.get("share",0.0))/SHORE_FULL_SHARE,0.0,1.0)
	return clampf(total,0.0,1.0)

## The place a flood comes in at, by its exposure and people ({} for the
## seat). `seat_weight` is the seat's own exposure (1 for a river camp, 0
## otherwise). Sets the place back.
static func flood_place(rng:RandomNumberGenerator,seat_weight:float,day:int)->Dictionary:
	var weights:=[seat_weight]
	var options:=[{}]
	for place:Dictionary in list():
		var w:=float(FLOOD_EXPOSURE.get(String(place.get("kind","inland")),0.0))*clampf(float(place.get("share",0.0))/SHORE_FULL_SHARE,0.0,1.0)
		if w>0.0:weights.append(w);options.append(place)
	var total:=0.0
	for w:float in weights:total+=w
	if total<=0.0:return {}
	var roll:=rng.randf()*total
	for index in weights.size():
		roll-=float(weights[index])
		if roll<=0.0:
			var chosen:Dictionary=options[index]
			if not chosen.is_empty():chosen["setback_until"]=day+FLOOD_SETBACK_DAYS
			return chosen
	return {}


## Words for a place's water.
static func site_words(kind:String)->String:
	return String({"coast":"on the sea shore","lake":"on a lake shore","river":"by the river","inland":"on open ground"}.get(kind,"on open ground"))

## The places in plain words for the settlement page: each with its water,
## its people and which way it is going, then what the shore gives.
static func words()->String:
	var places:=list()
	var population:=maxf(0.0,float(WorldSimulation.state.population_exact))
	if places.is_empty():
		var room_now:=room(population)
		if room_now<=0:return "No families live apart yet. The first will settle out once we are about %d people." % roundi(PEOPLE_PER_PLACE)
		return "No families live apart yet. With enough food in store, some will settle out, by the sea or a lake if there is one in reach."
	var parts:PackedStringArray=[]
	for place:Dictionary in places:
		var trend:=float(place.get("target",0.0))-float(place.get("share",0.0))
		var way:="growing" if trend>0.0005 else ("shrinking" if trend<-0.0005 else "steady")
		if int(WorldSimulation.state.elapsed_days)<int(place.get("setback_until",-1)):way="rebuilding after the flood"
		parts.append("%s, %s: %d people, %s" % [String(place.name),site_words(String(place.kind)),people(place),way])
	var text:="%d people live in the seat itself. " % seat_people()+"; ".join(parts)+"."
	var shore:=coast_context({},places)
	if not String(shore.get("shore_place","")).is_empty():
		text+=" %s works the shore for all of us: more fish and salt, and the storms and the shore wearing away with them." % String(shore.shore_place)
	var room_now:=room(population)
	if places.size()<room_now:text+=" There is room for more places."
	return text

## Read-only view for the map art and the screens: the contract in
## docs/design/ORGANIC_PLACES.md. Plain copies; changing them changes
## nothing. Call it inside the owner's WorldSimulation scope; redraw when
## `revision` changes (a place founded or left) or a place's
## people cross a bucket the art cares about.
static func snapshot()->Dictionary:
	var out:=[]
	var population:=maxf(0.0,float(WorldSimulation.state.population_exact))
	var today:=int(WorldSimulation.state.elapsed_days)
	for place:Variant in _records():
		if not place is Dictionary:continue
		var p:Dictionary=place
		var share:=float(p.get("share",0.0))
		out.append({"id":String(p.get("id","")),"name":String(p.get("name","")),"position":p.get("position",Vector2.ZERO),
			"kind":String(p.get("kind","inland")),"status":String(p.get("status","living")),
			"people":roundi(share*population) if String(p.get("status",""))!="ruin" else 0,"share":share,
			"trend":signf(float(p.get("target",share))-share),"age_days":maxi(0,today-int(p.get("founded_day",today))),
			"flooded":today<int(p.get("setback_until",-1)),"shoreline":float(p.get("shoreline",0.0)),
			"open_water":float(p.get("open_water",0.0)),"facing":p.get("facing",Vector2.ZERO),
			"founded_day":int(p.get("founded_day",today)),"left_day":int(p.get("left_day",-1))})
	var seat:=OneSeat.seat_record()
	return {"owner":String(WorldSimulation.actor_id),"seat_position":seat.get("position",Vector2.ZERO),
		"seat_people":seat_people(),"places":out,"revision":int(WorldSimulation.state.settlement_network_revision)}


static func _records()->Array:
	if WorldSimulation.state==null:return []
	var seat:=OneSeat.seat_record()
	var records:Variant=seat.get("places",[])
	return records if records is Array else []

static func _revise()->void:
	WorldSimulation.state.settlement_network_revision+=1

static func _geography(origin:Vector2)->Dictionary:
	if geography_hook.is_valid():return geography_hook.call()
	if not WorldSimulation.context_provider.is_valid():return {}
	var context:Variant=WorldSimulation.context_provider.call(origin)
	if not context is Dictionary:return {}
	return {"height_at":(context as Dictionary).get("terrain_height_at",Callable()),"river_distance_at":(context as Dictionary).get("river_distance_at",Callable())}

static func _sea_reach()->float:
	if WorldSimulation.discovery==null:return 1.0
	return preload("res://scripts/research_mechanics.gd").sea_reach()

## Crowding in the seat pushes families out to the places.
static func _crowding_pull()->float:
	var state=WorldSimulation.state
	var EarlyLife:=preload("res://scripts/early_life_conditions.gd")
	var capacity:=EarlyLife.carrying_capacity(state,WorldSimulation.discovery)
	if capacity<=0.0:return 1.0
	return clampf(0.6+EarlyLife.people_on_the_land(state)/capacity,0.6,1.8)


static func _tell_founded(place:Dictionary)->void:
	var seat:=String(WorldSimulation.state.settlement_name)
	var why:=String({"coast":"for the fish and the salt of the sea shore","lake":"for the fish and reeds of the lake","river":"for the river's water and its fords","inland":"for the open ground"}.get(String(place.kind),"for the open ground"))
	preload("res://scripts/chronicle.gd").record({"key":"place:%s" % String(place.id),
		"title":"Families settle at %s" % String(place.name),
		"text":"A few families from %s have built %s, %s, and call the place %s. They are still our people and share our stores." % [seat,site_words(String(place.kind)),why,String(place.name)],
		"tier":"notice","kind":"settlement","domain":"settlement",
		"action":{"kind":"section","section":"settlement","sub":0}})

static func _tell_left(place:Dictionary)->void:
	preload("res://scripts/chronicle.gd").record({"key":"place_left:%s" % String(place.id),
		"title":"%s stands empty" % String(place.name),
		"text":"The last families of %s have come back to %s. The houses %s are left to fall in." % [String(place.name),String(WorldSimulation.state.settlement_name),site_words(String(place.kind))],
		"tier":"notice","kind":"settlement","domain":"settlement",
		"action":{"kind":"section","section":"settlement","sub":0}})
