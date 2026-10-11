extends RefCounted
## ARMIES BY SEA. When no land road reaches a place, an army whose people's
## boats are fit for the sea (sea_voyage.gd capability, that people's own)
## goes by water, ours and every rival's by the one rule:
##
##   on foot to the shore on its bearing, over the water, ashore, and on.
##
## The road is the straight bearing from where it stands to where it is sent
## (rival_land_routes.gd sea_road finds the shore it leaves and the shore it
## makes); the stretch between sails at the boats' speed, the rest marches by
## the ground like any road (march_terrain.gd).
##
## A crossing costs lives. Of an expedition sent `x` km over water and home
## again, 0.5 ^ (x / sea endurance) come back (expedition.gd); an army makes
## the crossing once each way, so of those who embark
##     0.5 ^ ((coast km x 0.2 + open km) / (2 x sea endurance))
## land, water in sight of a coast counting a fifth of water out of sight of
## land. The share who drown is stated with the order and taken when the army
## lands (military_campaign.gd). No general embarks an army to lose more than
## MAX_DROWN of it. The boats carry its food for the crossing and
## STORES_ASHORE_DAYS after.
##
## The planner's result is a land road's (points, e, t, length_km, effort_km,
## origin, mix_key, ground_words) with direct false and
##   sea: {from_e, to_e, sea_km, open_km, coast_km, drown, craft}
## from_e/to_e being the effort marks where it embarks and lands.
## Static; preload.

const Route:=preload("res://scripts/army_land_route.gd")
const March:=preload("res://scripts/march_terrain.gd")
const Rival:=preload("res://scripts/rival_land_routes.gd")
const SeaVoyage:=preload("res://scripts/sea_voyage.gd")
const Expedition:=preload("res://scripts/expedition.gd")

## No general embarks an army to drown more than this share of it.
const MAX_DROWN:=0.5
## The boats carry the army's food: it eats from them at sea and for this
## many days after it lands (military_campaign.gd _force_provision_access).
## After that it lives on what the land and the carriers give, and over
## the sea the carriers bring nothing.
const STORES_ASHORE_DAYS:=40
## How far over the sea a people can make war, in its sea endurances (at
## four, a quarter of those who embark would land).
const WAR_ENDURANCES:=4.0

## The share of those who embark that drown on a crossing.
static func drown_share(open_km:float,coast_km:float,endurance_km:float)->float:
	if endurance_km<=0.0:return 1.0
	return clampf(1.0-pow(0.5,(coast_km*Expedition.COAST_WEIGHT+open_km)/(2.0*endurance_km)),0.0,1.0)

## How far over the sea the people in scope can carry a war, km (0 with no
## boats fit for the sea). Reckoned once a day for each people.
static var _reach:={}
static func war_reach_km()->float:
	var key:=String(WorldSimulation.actor_id)
	var day:=int(WorldSimulation.state.elapsed_days) if WorldSimulation.state!=null else 0
	var held:Dictionary=_reach.get(key,{})
	if int(held.get("day",-1))==day:return float(held.km)
	var km:=Expedition.endurance_km(true)*WAR_ENDURANCES
	if _reach.size()>64:_reach.clear()
	_reach[key]={"day":day,"km":km}
	return km

## The sea road for a force of `mix` marching at `pace` km a day, for the
## people in scope: {} when its boats cannot go to sea or the bearing holds
## no crossing; {error, reason} when the crossing would drown too many.
## `craft` (tests): {ok, sail_km_per_day, endurance_km, label}.
static func find(start:Vector2,target:Vector2,land:Callable,mix:Dictionary,pace:float,craft:Dictionary={})->Dictionary:
	if craft.is_empty():
		craft=SeaVoyage.capability()
		craft["endurance_km"]=Expedition.endurance_km(true)
	if not bool(craft.get("ok",false)):return {}
	var chord:Dictionary=Rival.sea_road(start,target,land)
	if chord.has("error"):return {}
	var from:Vector2=chord.from
	var to:Vector2=chord.to
	var end:Vector2=chord.end
	var open:=float(chord.open_km)
	var coast:=float(chord.coast_km)
	var drown:=drown_share(open,coast,float(craft.get("endurance_km",0.0)))
	if drown>MAX_DROWN:
		return {"error":"No march was ordered: the crossing is %d km of water, %d of it out of sight of land, and about %d in 100 of those who embarked would drown. Our boats are not fit to carry an army so far." % [roundi(open+coast),roundi(open),roundi(drown*100.0)],"reason":"sea_too_far"}
	# On foot to the shore, by the ground.
	var points:Array=[]
	var marks:=PackedFloat32Array()
	var temps:=PackedFloat32Array()
	var ground:={}
	var length:=0.0
	var effort:=0.0
	var here:=start
	if start.distance_to(from)>0.5:
		var first:=_walk(start,from,land,mix)
		points.append_array(first.points)
		var first_t:PackedFloat32Array=first.get("t",PackedFloat32Array())
		for i in (first.points as Array).size():
			marks.append(float(first.e[i]));temps.append(float(first_t[i]) if i<first_t.size() else -1.0)
		length=float(first.length_km);effort=float(first.effort_km);ground=(first.get("ground",{}) as Dictionary).duplicate()
		here=from
	var from_e:=effort
	# Under sail: the boats' speed against the army's own day's march.
	var sea_km:=here.distance_to(to)
	effort+=sea_km*maxf(2.0,pace)/maxf(1.0,float(craft.get("sail_km_per_day",22.0)))
	length+=sea_km
	points.append(to);marks.append(effort);temps.append(-1.0)
	var to_e:=effort
	# Ashore and on.
	if to.distance_to(end)>0.5:
		var last:=_walk(to,end,land,mix)
		var last_t:PackedFloat32Array=last.get("t",PackedFloat32Array())
		for i in (last.points as Array).size():
			points.append(last.points[i]);marks.append(effort+float(last.e[i]));temps.append(float(last_t[i]) if i<last_t.size() else -1.0)
		length+=float(last.length_km);effort+=float(last.effort_km)
		var last_ground:Dictionary=last.get("ground",{})
		for k:String in last_ground:ground[k]=float(ground.get(k,0.0))+float(last_ground[k])
	var words:=March.ground_words({"ground":ground,"length_km":length})
	return {"ok":true,"origin":start,"points":points,"e":marks,"t":temps,"length_km":length,"effort_km":effort,"direct":false,"mix_key":March.mix_key(mix),"ground":ground,
		"ground_words":("by sea"+(" and "+words if words!="" else "")),
		"sea":{"from_e":from_e,"to_e":to_e,"sea_km":sea_km,"open_km":open,"coast_km":coast,"drown":drown,"craft":String(craft.get("label","boats"))}}

## A dry stretch of the bearing, by the land road when one is found, else straight.
static func _walk(a:Vector2,b:Vector2,land:Callable,mix:Dictionary)->Dictionary:
	var found:=Route.find(a,b,land,true,March.context(mix))
	var legs:Array=found.get("points",[b]) if not found.has("error") else [b]
	if found.has("e") and not found.has("error"):return found
	return Route._with_profile(a,legs,mix,land,{})

## Whether effort `done` on an army's road lies in its sea leg.
static func at_sea(army:Dictionary,done:float)->bool:
	var sea:Variant=army.get("march_sea")
	return sea is Dictionary and done>=float(sea.get("from_e",INF))-0.001 and done<float(sea.get("to_e",-INF))-0.001

## Whether an army eats from its boats today: under sail, or within
## STORES_ASHORE_DAYS of landing.
static func on_ship_stores(army:Dictionary,day:int)->bool:
	if day<=int(army.get("sea_stores_until",-1)):return true
	return String(army.get("status",""))=="moving" and at_sea(army,float(army.get("march_effort_done",0.0)))

## The words for an order that goes by sea.
static func order_words(sea:Dictionary,troops:int)->String:
	return " by sea in our %s: %d km under sail, %d of it out of sight of land. About %d of the %d who embark will drown on the crossing; the boats carry food for the crossing and %d days ashore" % [String(sea.get("craft","boats")),roundi(float(sea.get("sea_km",0.0))),roundi(float(sea.get("open_km",0.0))),roundi(float(troops)*float(sea.get("drown",0.0))),troops,STORES_ASHORE_DAYS]
