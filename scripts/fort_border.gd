extends RefCounted
## FORTS AND THE WATCHED BORDER (2026-10-09 direction, docs/FORT_BORDERS.md).
##
## A people's border is spanned by its forts. Without forts it holds only its
## home country: the seat's own fields and a day's walk beyond. Each fort holds
## ground about itself (its kind's reach), and two forts close enough apart
## are linked: the land between them is enclosed too. The outline seen from
## the seat is the far edge of all of that (outline()).
##
## The watch keeps the line. Of the watch at home (watch_military.gd) the
## ruler's border share goes out: first each fort's garrison, then the rest
## spread along the linked stretches by their length. A stretch's strength is
##     1 - exp(-watchmen per km / WATCH_KM)
## (two to a km about 63%, six about 95%). Ground no linked stretch covers is
## OPEN: the home guard's ordinary vigilance only. Whoever crosses a stretch
## (a scout, a spy, a raider, our own people leaving) is caught or turned back
## at its strength (catch()).
##
## Out there everything costs. Every person at a fort or on the line still
## eats, and the food carried out spoils and is eaten on the road: a share
##     1 - exp(-km / TRANSIT_KM x carrying)
## is lost (about a third at 60 km on foot), drawn from the stores each day.
## Each standing fort wants its kind's upkeep in materials; a fort short of
## them wears down and in the end is abandoned. Building a fort takes its
## materials at once and its garrison's work over days.
##
## Every people, ours and every computer ruler, keeps forts by these rules;
## the ledger is each people's own GameState.border_forts. Static; preload.

const WATCH_KM:=2.0
const TRANSIT_KM:=150.0
## The seat's own country beyond its fields' claim, km.
const HOME_KM:=25.0
## Forts link when no farther apart than this many times their reaches summed.
const LINK_SPAN:=2.5
## Strength on ground no linked stretch covers.
const OPEN_STRENGTH:=0.05
## Bearings of the outline (as nation_border_partition SHAPE_SAMPLES).
const BEARINGS:=64
## Old border posts stand at most this many of their kind's reach from the seat.
const SEED_REACHES:=4.0
## A fort short of its upkeep loses this much condition a day; at 0 it is left.
const DECAY:=0.01

## The forts our people can raise, by what they know. reach: km of ground a
## fort holds; garrison: watch it needs; work: garrison-days to raise; cost:
## materials at the start; upkeep: materials a day.
const KINDS:=[
	{"id":"watch_camp","name":"Watch camp","needs":[],"reach":18.0,"garrison":20,"work":600.0,"cost":{"Timber":30.0,"Fiber Plants":10.0},"upkeep":{"Timber":0.2}},
	{"id":"earthwork_fort","name":"Earthwork fort","needs":["boundary_marker_surveys"],"reach":25.0,"garrison":40,"work":2400.0,"cost":{"Timber":60.0,"Stone":40.0,"Fiber Plants":15.0},"upkeep":{"Timber":0.3,"Stone":0.2}},
	{"id":"palisade_fort","name":"Palisade fort","needs":["joinery"],"reach":32.0,"garrison":60,"work":6000.0,"cost":{"Timber":220.0,"Stone":80.0,"Fiber Plants":40.0},"upkeep":{"Timber":0.8,"Stone":0.3}},
	{"id":"stone_fort","name":"Stone fort","needs_any":["dry_stone_walls","lime_mortar"],"reach":45.0,"garrison":120,"work":18000.0,"cost":{"Stone":900.0,"Timber":240.0,"Clay":120.0},"upkeep":{"Stone":1.0,"Timber":0.5}},
	{"id":"bastion_fort","name":"Bastion fort","needs_any":["solid_bored_cannon","powder_artillery"],"reach":60.0,"garrison":300,"work":60000.0,"cost":{"Stone":2600.0,"Timber":600.0,"Clay":500.0},"upkeep":{"Stone":2.0,"Timber":1.0}},
]

# --- The ledger -------------------------------------------------------------

## The people in scope's ledger: {forts, border_share, next_id, seeded}.
## An older save counts its old border posts the first time its ledger is
## read once settled (seed_old_posts), so the map and the screens show them
## from the moment it loads, not only after a day has passed.
static var _seeding:=false
static func ledger(state:Node=null)->Dictionary:
	if state==null:state=WorldSimulation.state
	var d:Dictionary=state.border_forts
	if not d.has("forts"):d.merge({"forts":[],"border_share":-1.0,"next_id":1,"seeded":false},false)
	if not bool(d.seeded) and not _seeding and state==WorldSimulation.state and bool(state.settlement_site_committed) and not bool(state.convoy_traveling):
		_seeding=true
		seed_old_posts()
		_seeding=false
	return d

static func forts(state:Node=null)->Array:
	return ledger(state).forts

static func kind(id:String)->Dictionary:
	for k:Dictionary in KINDS:
		if String(k.id)==id:return k
	return {}

## The best fort the people in scope can raise now, {} before any.
static func best_kind(known:Array=[])->Dictionary:
	if known.is_empty():known=WorldSimulation.state.known_discoveries
	var best:={}
	for k:Dictionary in KINDS:
		var ok:=true
		for id:String in k.get("needs",[]):
			if not id in known:ok=false
		var any:Array=k.get("needs_any",[])
		if not any.is_empty() and not any.any(func(id:String)->bool:return id in known):ok=false
		if ok:best=k
	return best

## The ruler's share of the watch at home sent to the border (0..1): chosen,
## else the leaders' default (more for a people with forts to keep).
static func border_share(state:Node=null)->float:
	var share:=float(ledger(state).get("border_share",-1.0))
	if share>=0.0:return clampf(share,0.0,1.0)
	return 0.35 if not forts(state).is_empty() else 0.0

# --- Where things are -------------------------------------------------------

## The seat: the primary town (as realm_reach.gd centres a people's land).
static func seat(state:Node=null)->Vector2:
	if state==null:state=WorldSimulation.state
	for city:Dictionary in state.player_settlements:
		if bool(city.get("primary",false)) and city.get("position") is Vector2:return city.position
	var at:Vector3=state.settlement_founded_at
	return Vector2(at.x,at.z)

## The seat's own country: its fields' claim and HOME_KM beyond, but never
## more than its people would range over (realm_reach.gd reach_km): a band
## of a few dozen holds its camp's ground, not a day's walk round.
static func home_km(state:Node=null)->float:
	if state==null:state=WorldSimulation.state
	var claim:=0.0
	for city:Dictionary in state.player_settlements:claim=maxf(claim,float(city.get("claim_radius_km",0.0)))
	var ranging:=float(preload("res://scripts/realm_reach.gd").reach_km(float(state.population_total),0.0))
	return maxf(claim,minf(claim+HOME_KM,ranging))

static func _pos(fort:Dictionary)->Vector2:
	return Vector2(float(fort.get("x",0.0)),float(fort.get("z",0.0)))

## Forts that hold ground: standing ones (a fort going up holds nothing yet).
static func standing(state:Node=null)->Array:
	return forts(state).filter(func(f:Dictionary)->bool:return String(f.get("status",""))=="standing")

static func reach_of(fort:Dictionary)->float:
	return float(kind(String(fort.get("kind",""))).get("reach",0.0))*lerpf(0.6,1.0,clampf(float(fort.get("condition",1.0)),0.0,1.0))

## Linked stretches between standing forts: neighbours by bearing about the
## seat, close enough apart (LINK_SPAN). [{a, b, km, mid}] (fort ids).
static func links(state:Node=null)->Array:
	var center:=seat(state)
	var list:=standing(state)
	list.sort_custom(func(p:Dictionary,q:Dictionary)->bool:return (_pos(p)-center).angle()<(_pos(q)-center).angle())
	var out:=[]
	if list.size()<2:return out
	for i in list.size():
		var a:Dictionary=list[i];var b:Dictionary=list[(i+1)%list.size()]
		if list.size()==2 and i==1:break
		var km:=_pos(a).distance_to(_pos(b))
		if km>(reach_of(a)+reach_of(b))*LINK_SPAN:continue
		# Never wrap round the far side of the seat.
		var turn:=fposmod((_pos(b)-center).angle()-(_pos(a)-center).angle(),TAU)
		if turn>PI*0.9:continue
		out.append({"a":int(a.id),"b":int(b.id),"km":km,"mid":(_pos(a)+_pos(b))*0.5})
	return out

## The border seen from the seat: reach (km) at BEARINGS bearings, the far
## edge of the home country, every standing fort's ground and the land
## between linked forts. {center, table, reach, points}.
static func outline(state:Node=null)->Dictionary:
	var center:=seat(state)
	var discs:=[[Vector2.ZERO,home_km(state)]]
	var by_id:={}
	for f:Dictionary in standing(state):
		by_id[int(f.id)]=f
		discs.append([_pos(f)-center,reach_of(f)])
	for l:Dictionary in links(state):
		var a:Dictionary=by_id[int(l.a)];var b:Dictionary=by_id[int(l.b)]
		for k in range(1,8):
			var t:=float(k)/8.0
			discs.append([_pos(a).lerp(_pos(b),t)-center,lerpf(reach_of(a),reach_of(b),t)])
	var table:=PackedFloat32Array();table.resize(BEARINGS)
	var points:=PackedVector2Array()
	var most:=0.0
	for k in BEARINGS:
		var u:=Vector2.RIGHT.rotated(TAU*float(k)/float(BEARINGS))
		var far:=0.0
		for disc:Array in discs:
			var c:Vector2=disc[0];var r:float=disc[1]
			var along:=c.dot(u)
			var gap:=r*r-(c.length_squared()-along*along)
			if gap<0.0:continue
			far=maxf(far,along+sqrt(gap))
		table[k]=maxf(far,0.001);most=maxf(most,far)
		points.append(center+u*far)
	return {"center":center,"table":table,"reach":most,"points":points}

## Whether `point` lies within the border of the people in scope.
static func inside(point:Vector2,state:Node=null,shape:Dictionary={})->bool:
	if shape.is_empty():shape=outline(state)
	var offset:=point-Vector2(shape.center)
	var k:=posmod(roundi(fposmod(offset.angle(),TAU)/TAU*float(BEARINGS)),BEARINGS)
	return offset.length()<=float((shape.table as PackedFloat32Array)[k])

# --- The watch on the line --------------------------------------------------

## The watch out on the border: {garrisons: {fort id: people}, line: people,
## stretches: [{a, b, km, watchmen, per_km, strength}], posted}.
static func watch(state:Node=null,mc:Node=null)->Dictionary:
	if mc==null:mc=WorldSimulation.military if state==null or state==WorldSimulation.state else _military_of(state)
	var home:=0
	if mc!=null:home=preload("res://scripts/watch_military.gd").at_home(mc)
	else:home=int(float(state.population_allocations.get("Defense",0)))
	var out:=roundi(float(home)*border_share(state))
	var garrisons:={}
	var left:=out
	for f:Dictionary in forts(state):
		if String(f.get("status",""))=="abandoned":continue
		var need:=int(kind(String(f.kind)).get("garrison",0))
		var given:=mini(need,left)
		garrisons[int(f.id)]=given;left-=given
	var stretches:=[]
	var total_km:=0.0
	var ls:=links(state)
	for l:Dictionary in ls:total_km+=float(l.km)
	for l:Dictionary in ls:
		var men:=float(left)*float(l.km)/maxf(1.0,total_km)
		var per_km:=men/maxf(1.0,float(l.km))
		stretches.append({"a":int(l.a),"b":int(l.b),"km":float(l.km),"mid":l.mid,"watchmen":men,"per_km":per_km,"strength":strength_of(per_km)})
	return {"garrisons":garrisons,"line":left if not ls.is_empty() else 0,"stretches":stretches,"posted":out-(left if ls.is_empty() else 0)}

## The military of the people whose GameState is `state` (its own watch), or
## null when it is not found (then the Defense share stands in).
static func _military_of(state:Node)->Node:
	if state==GameState:return MilitaryCampaign
	for id:String in WorldSimulation.actors:
		var systems:Dictionary=(WorldSimulation.actors[id] as Dictionary).get("systems",{})
		if systems.get("GameState")==state:return systems.get("MilitaryCampaign")
	return null

## How `owner`'s border stops a crossing toward `other`'s home (the stretch
## facing it), for someone of `stealth`. Owners as society_exchange.gd names
## them ("player" or a people's id); 0 when either has no home.
static func facing(owner:String,other:String,stealth:float=0.5)->float:
	var Exchange:=preload("res://scripts/society_exchange.gd")
	var state:Node=Exchange.owner_state(owner)
	var there:Node=Exchange.owner_state(other)
	if state==null or there==null or not bool(state.settlement_site_committed) or not bool(there.settlement_site_committed):return 0.0
	var shape:=outline(state)
	var bearing:=(seat(there)-Vector2(shape.center)).angle()
	var table:PackedFloat32Array=shape.table
	var edge:=Vector2(shape.center)+Vector2.RIGHT.rotated(bearing)*float(table[posmod(roundi(fposmod(bearing,TAU)/TAU*float(BEARINGS)),BEARINGS)])
	return catch(edge,stealth,state)

static func strength_of(per_km:float)->float:
	return 1.0-exp(-maxf(0.0,per_km)/WATCH_KM)

## How well the stretch of border at `point`'s bearing (from the seat) is kept:
## a linked stretch's strength, a lone fort's ground half its garrison's worth,
## open ground OPEN_STRENGTH. {strength, kind: "line" | "fort" | "open"}.
static func at(point:Vector2,state:Node=null,kept:Dictionary={})->Dictionary:
	if kept.is_empty():kept=watch(state)
	var center:=seat(state)
	var bearing:=(point-center).angle()
	var by_id:={}
	for f:Dictionary in forts(state):by_id[int(f.id)]=f
	for s:Dictionary in kept.stretches:
		var a:=(_pos(by_id[int(s.a)])-center).angle();var b:=(_pos(by_id[int(s.b)])-center).angle()
		if fposmod(bearing-a,TAU)<=fposmod(b-a,TAU):return {"strength":float(s.strength),"kind":"line"}
	for f:Dictionary in standing(state):
		if point.distance_to(_pos(f))<=reach_of(f)*1.2:
			var manned:=float(kept.garrisons.get(int(f.id),0))/maxf(1.0,float(kind(String(f.kind)).get("garrison",1)))
			return {"strength":maxf(OPEN_STRENGTH,manned*0.5),"kind":"fort"}
	return {"strength":OPEN_STRENGTH,"kind":"open"}

## The chance the border of `owner` stops a crossing at `point` by someone of
## `stealth` (0..1): the stretch's strength, less what stealth slips past.
static func catch(point:Vector2,stealth:float=0.5,state:Node=null)->float:
	return clampf(float(at(point,state).strength)*(1.0-clampf(stealth,0.0,1.0)*0.4),0.0,0.95)

# --- What it costs ----------------------------------------------------------

## Share of food carried `km` that is lost on the way.
static func transit_loss(km:float,carrying:float=1.0)->float:
	return 1.0-exp(-maxf(0.0,km)/(TRANSIT_KM*maxf(0.2,carrying)))

## How much better than walking the people carry: roads, carts and route knowledge.
static func carrying()->float:
	var route:=float(WorldSimulation.discovery.effect("route_speed"))
	var haul:=float(WorldSimulation.discovery.effect("haul_capacity"))
	return (1.0+route)*(1.0+haul)*float(preload("res://scripts/built_fabric.gd").haul_factor())

## The day's cost of the border: {food_lost, food_eaten_out, upkeep: {material:
## amount}, posts: [{id, km, people, lost}]}. Food a ration a person a day.
static func costs(state:Node=null,kept:Dictionary={})->Dictionary:
	if state==null:state=WorldSimulation.state
	if kept.is_empty():kept=watch(state)
	var center:=seat(state)
	var ration:=float(state.simulation_metrics.get("food_consumption",state.population_exact))/maxf(1.0,float(state.population_exact))
	var carry:=carrying()
	var lost:=0.0;var out:=0.0
	var posts:=[]
	var upkeep:={}
	for f:Dictionary in forts(state):
		if String(f.get("status",""))=="abandoned":continue
		var people:=float(kept.garrisons.get(int(f.id),0))
		var km:=_pos(f).distance_to(center)
		var loss:=transit_loss(km,carry)
		var gone:=people*ration*loss/maxf(0.05,1.0-loss)
		lost+=gone;out+=people*ration
		posts.append({"id":int(f.id),"km":km,"people":people,"lost":gone})
		if String(f.get("status",""))=="standing":
			for m:String in kind(String(f.kind)).get("upkeep",{}):upkeep[m]=float(upkeep.get(m,0.0))+float(kind(String(f.kind)).upkeep[m])
	for s:Dictionary in kept.stretches:
		var km:=Vector2(s.mid).distance_to(center)
		var loss:=transit_loss(km,carry)
		lost+=float(s.watchmen)*ration*loss/maxf(0.05,1.0-loss);out+=float(s.watchmen)*ration
	return {"food_lost":lost,"food_eaten_out":out,"upkeep":upkeep,"posts":posts}

# --- The day ----------------------------------------------------------------

## Once a day for the people in scope: older peoples' border posts, the
## leaders' forts, raising forts, the food lost on the road and the upkeep.
static func advance(day:int)->void:
	var state:=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling:return
	var d:=ledger()
	if WorldSimulation.actor_id!="player" and posmod(day+hash(WorldSimulation.actor_id),30)==0:_leaders_decide()
	if forts().is_empty():return
	var span:=float(WorldSimulation.span)
	var kept:=watch()
	for f:Dictionary in forts():
		if String(f.get("status",""))!="building":continue
		f.progress=float(f.get("progress",0.0))+float(kept.garrisons.get(int(f.id),0))*span
		if float(f.progress)>=float(kind(String(f.kind)).get("work",1.0)):
			f.status="standing";f.condition=1.0;f.since=day
			_tell("%s stands at %s: the border reaches out to it." % [String(kind(String(f.kind)).name),String(f.get("name","the new post"))])
	var bill:=costs(state,kept)
	if float(bill.food_lost)>0.0:
		WorldSimulation.food.issue_for_obligation(float(bill.food_lost)*span,"border","Border forts: food lost on the road",span,int(kept.posted))
	var stock:Dictionary=state.resource_stockpiles
	var short:=false
	for m:String in bill.upkeep:
		var need:=float(bill.upkeep[m])*span
		var have:=float(stock.get(m,0.0))
		stock[m]=maxf(0.0,have-need)
		if have<need:short=true
	for f:Dictionary in standing():
		var manned:=float(kept.garrisons.get(int(f.id),0))/maxf(1.0,float(kind(String(f.kind)).get("garrison",1)))
		var wear:=(DECAY if short else 0.0)+(DECAY*0.5 if manned<0.5 else 0.0)
		var was:=float(f.get("condition",1.0))
		f.condition=clampf(was-wear*span+(0.002*span if wear<=0.0 else 0.0),0.0,1.0)
		# Said once, at half: why it is wearing down and how long it has.
		if was>=0.5 and float(f.condition)<0.5 and wear>0.0:
			var why:=("only %d of the %d it needs man it" % [int(kept.garrisons.get(int(f.id),0)),int(kind(String(f.kind)).get("garrison",0))]) if manned<0.5 else "its upkeep is short"
			_tell("%s is wearing down: %s. Left so, it is abandoned in about %d days, and the border with it. Send more of the watch out, or break it down while its stone is worth carrying home." % [String(f.get("name","A fort")),why,ceili(float(f.condition)/wear)])
		if float(f.condition)<=0.0:
			f.status="abandoned"
			_tell("%s at %s is left to the weather: it was not kept." % [String(kind(String(f.kind)).name),String(f.get("name","the post"))])
	d["last_bill"]={"day":day,"food_lost":float(bill.food_lost),"upkeep":bill.upkeep,"posted":int(kept.posted)}

# --- Raising and leaving forts ----------------------------------------------

## Raises a fort of the best kind known at `point` (the people in scope):
## takes its materials now; its garrison raises it over days. {ok, fort} or
## {error}.
static func build(point:Vector2,name:String="")->Dictionary:
	var k:=best_kind()
	if k.is_empty():return {"error":"Our people know no way to raise a fort."}
	if WorldSimulation.world.scout_land_authority.is_valid() and not WorldSimulation.world._scout_land_at(point):return {"error":"A fort needs dry ground."}
	var stock:Dictionary=WorldSimulation.state.resource_stockpiles
	for m:String in k.cost:
		if float(stock.get(m,0.0))<float(k.cost[m]):return {"error":"Raising a %s needs %d %s; we hold %d." % [String(k.name).to_lower(),roundi(float(k.cost[m])),m,roundi(float(stock.get(m,0.0)))]}
	for m:String in k.cost:stock[m]=float(stock[m])-float(k.cost[m])
	var d:=ledger()
	var fort:={"id":int(d.next_id),"kind":String(k.id),"x":point.x,"z":point.y,"status":"building","progress":0.0,"condition":1.0,"since":int(WorldSimulation.state.elapsed_days),
		"name":name if name!="" else "%s %s" % [_compass(seat(),point),String(k.name).to_lower()]}
	d.next_id=int(d.next_id)+1
	(d.forts as Array).append(fort)
	if float(d.get("border_share",-1.0))<0.0 and WorldSimulation.actor_id!="player":d.border_share=0.35
	return {"ok":true,"fort":fort}

## Leaves a fort: its garrison comes home; the ground it held is no longer ours.
static func abandon(id:int)->Dictionary:
	for f:Dictionary in forts():
		if int(f.id)==id:
			f.status="abandoned"
			return {"ok":true}
	return {"error":"No such fort."}

## The share of the watch at home that mans every fort's garrison (0..1; 1
## when even all of it falls short).
static func share_to_man(state:Node=null,mc:Node=null)->float:
	if mc==null:mc=WorldSimulation.military if state==null or state==WorldSimulation.state else _military_of(state)
	var home:=preload("res://scripts/watch_military.gd").at_home(mc) if mc!=null else 0
	var need:=0
	for f:Dictionary in forts(state):
		if String(f.get("status",""))!="abandoned":need+=int(kind(String(f.kind)).get("garrison",0))
	if need<=0:return 0.0
	if home<=0:return 1.0
	return clampf(ceilf(float(need)/float(home)*100.0)/100.0,0.0,1.0)

## Other peoples' forts our people know of: on land we have charted, of the
## peoples we have met. [{at, kind, status, owner, owner_name, name}].
static func known_foreign_forts()->Array:
	var out:=[]
	var world:Variant=WorldSimulation.world
	if world==null:return out
	var Exchange:=preload("res://scripts/society_exchange.gd")
	for civ:Dictionary in world.civilizations:
		if int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))<2:continue
		var id:=String(civ.get("id",""))
		var state:Node=Exchange.owner_state(id)
		if state==null or state==WorldSimulation.state:continue
		var d:Dictionary=state.border_forts
		for f:Dictionary in d.get("forts",[]):
			if String(f.get("status",""))=="abandoned":continue
			var at:=_pos(f)
			if world.has_method("_position_is_revealed") and not bool(world._position_is_revealed(at)):continue
			out.append({"at":at,"kind":String(f.get("kind","")),"status":String(f.get("status","")),"owner":id,"owner_name":String(civ.get("name","")),"name":String(f.get("name",""))})
	return out

## Sets the share of the watch at home sent out to the border (0..1).
static func set_border_share(share:float)->void:
	ledger().border_share=clampf(share,0.0,1.0)

# --- The god's hand: placing, moving, breaking down ----------------------------

## A fort moved keeps this share of the work done (its timbers and stones go
## with it); the move costs MOVE_COST of a new fort's materials.
const MOVE_KEEP:=0.4
const MOVE_COST:=0.25
## Broken down, a standing fort gives back this share of its materials (by its
## condition); one still going up gives back more, less what was raised.
const RECOVER:=0.5
## No two of our forts closer than this, km.
const MIN_APART_KM:=4.0

## Ground within the outline, km².
static func area(shape:Dictionary)->float:
	var total:=0.0
	for r:float in (shape.table as PackedFloat32Array):total+=0.5*r*r*TAU/float(BEARINGS)
	return total

## Runs `fn` with the ledger's forts as they would be with `extra` added and
## the fort `without` gone, then puts them back.
static func _with(extra:Dictionary,without:int,fn:Callable)->Variant:
	var d:=ledger()
	var saved:Array=d.forts
	var trial:=saved.filter(func(f:Dictionary)->bool:return int(f.id)!=without)
	if not extra.is_empty():trial.append(extra)
	d.forts=trial
	var result:Variant=fn.call()
	d.forts=saved
	return result

static func find_fort(id:int)->Dictionary:
	for f:Dictionary in forts():
		if int(f.id)==id:return f
	return {}

## What raising a fort at `point` (or moving fort `moving` there) would cost
## and gain, in the engine's numbers, for the god's people: {kind, kind_name,
## at, km, cost, short: {material: lacking}, garrison, days, food_lost,
## loss_share, upkeep, gain_km2, links: [{name, km}], problem}. It can be
## done when problem is "" and short is empty.
static func quote(point:Vector2,moving:int=-1)->Dictionary:
	var old:={}
	var k:=best_kind()
	if moving>=0:
		old=find_fort(moving)
		if old.is_empty():return {"problem":"No such fort.","short":{}}
		k=kind(String(old.kind))
	if k.is_empty():return {"problem":"Our people know no way to raise a fort yet.","short":{}}
	var state:=WorldSimulation.state
	var center:=seat()
	var out:={"kind":String(k.id),"kind_name":String(k.name),"at":point,"km":point.distance_to(center),"garrison":int(k.garrison),"upkeep":k.upkeep,"problem":"","links":[],"short":{},"moving":moving}
	var share:=MOVE_COST if moving>=0 else 1.0
	var cost:={}
	for m:String in k.cost:cost[m]=float(k.cost[m])*share
	out.cost=cost
	var stock:Dictionary=state.resource_stockpiles
	for m:String in cost:
		if float(stock.get(m,0.0))<float(cost[m]):out.short[m]=float(cost[m])-float(stock.get(m,0.0))
	out.days=ceili(float(k.work)*((1.0-MOVE_KEEP) if moving>=0 else 1.0)/maxf(1.0,float(k.garrison)))
	var ration:=float(state.simulation_metrics.get("food_consumption",state.population_exact))/maxf(1.0,float(state.population_exact))
	var loss:=transit_loss(float(out.km),carrying())
	out.loss_share=loss
	out.food_lost=float(k.garrison)*ration*loss/maxf(0.05,1.0-loss)
	var world:Variant=WorldSimulation.world
	if world!=null and world.scout_land_authority.is_valid() and not world._scout_land_at(point):out.problem="A fort needs dry ground."
	elif world!=null and world.has_method("_position_is_revealed") and not bool(world._position_is_revealed(point)):out.problem="Our people do not know this land yet."
	elif float(out.km)<home_km()*0.5:out.problem="This is our home country; it needs no fort."
	if out.problem=="":
		var held:=_held_by(point)
		if held!="":out.problem="That is %s's land: a fort there is an act of war." % held
	if out.problem=="":
		for f:Dictionary in forts():
			if int(f.id)==moving or String(f.get("status",""))=="abandoned":continue
			if _pos(f).distance_to(point)<MIN_APART_KM:out.problem="Too close to %s." % String(f.get("name","another fort"));break
	# What the border would become with it standing there.
	var trial:={"id":-99,"kind":String(k.id),"x":point.x,"z":point.y,"status":"standing","condition":1.0,"name":"the new fort"}
	var before:=area(outline())
	var after:Dictionary=_with(trial,moving,func()->Dictionary:
		var names:={}
		for f:Dictionary in forts():names[int(f.id)]=String(f.get("name",""))
		var joined:=[]
		for l:Dictionary in links():
			if int(l.a)==-99:joined.append({"name":String(names.get(int(l.b),"")),"km":float(l.km),"to":int(l.b)})
			elif int(l.b)==-99:joined.append({"name":String(names.get(int(l.a),"")),"km":float(l.km),"to":int(l.a)})
		var shape:=outline()
		return {"area":area(shape),"links":joined,"points":shape.points})
	out.gain_km2=float(after.area)-before
	out.links=after.links
	# The border as it would run with the fort standing there (the map's ghost).
	out.outline=after.points
	return out

## Whose land `point` is when another people's border holds it ("" if none).
static func _held_by(point:Vector2)->String:
	var Realm:=preload("res://scripts/realm_reach.gd")
	var own:=Realm.border_ours()
	var mine:=Realm._score(own,point) if not own.is_empty() else -INF
	for border:Dictionary in Realm.border_others():
		var theirs:=Realm._score(border,point)
		if theirs>0.0 and theirs>mine:
			for civ:Dictionary in WorldSimulation.world.civilizations:
				if String(civ.get("id",""))==String(border.owner):return String(civ.get("name","another people"))
			return "another people"
	return ""

## The god's hand: raises a fort at `point` when quote() allows it.
static func place(point:Vector2)->Dictionary:
	var q:=quote(point)
	if String(q.get("problem",""))!="":return {"error":String(q.problem)}
	if not (q.short as Dictionary).is_empty():return {"error":short_words(q)}
	var made:=build(point)
	if made.has("fort"):_tell("A %s is going up at %s, %d km out: about %d days to raise, %d of the watch to man it." % [String(q.kind_name).to_lower(),String(made.fort.name),roundi(float(q.km)),int(q.days),int(q.garrison)])
	return made

## "We need 12 more timber and 3 more stone."
static func short_words(q:Dictionary)->String:
	var parts:PackedStringArray=[]
	for m:String in q.short:parts.append("%d more %s" % [ceili(float(q.short[m])),m.to_lower()])
	return "We need %s." % " and ".join(parts)

## What breaking `fort` down gives back: {material: amount}.
static func recovered(fort:Dictionary)->Dictionary:
	var k:=kind(String(fort.get("kind","")))
	var share:=0.0
	match String(fort.get("status","")):
		"standing":share=RECOVER*clampf(float(fort.get("condition",1.0)),0.0,1.0)
		"building":share=lerpf(0.9,RECOVER,clampf(float(fort.get("progress",0.0))/maxf(1.0,float(k.get("work",1.0))),0.0,1.0))
	var out:={}
	for m:String in k.get("cost",{}):out[m]=float(k.cost[m])*share
	return out

## Breaks fort `id` down: its garrison comes home, part of its materials come
## back to the stores, and the ground it held is no longer ours.
static func dismantle(id:int)->Dictionary:
	var fort:=find_fort(id)
	if fort.is_empty():return {"error":"No such fort."}
	var back:=recovered(fort)
	var stock:Dictionary=WorldSimulation.state.resource_stockpiles
	for m:String in back:stock[m]=float(stock.get(m,0.0))+float(back[m])
	(ledger().forts as Array).erase(fort)
	_tell("%s is broken down; its garrison comes home with what could be carried, and the border draws back." % String(fort.get("name","The fort")))
	return {"ok":true,"recovered":back}

## Moves fort `id` to `point`: taken down and raised again there, keeping
## MOVE_KEEP of its work and costing MOVE_COST of its materials. Until it
## stands again it holds no ground.
static func move(id:int,point:Vector2)->Dictionary:
	var q:=quote(point,id)
	if String(q.get("problem",""))!="":return {"error":String(q.problem)}
	if not (q.short as Dictionary).is_empty():return {"error":short_words(q)}
	var fort:=find_fort(id)
	var stock:Dictionary=WorldSimulation.state.resource_stockpiles
	for m:String in q.cost:stock[m]=float(stock.get(m,0.0))-float(q.cost[m])
	var k:=kind(String(fort.kind))
	var was:=String(fort.get("name",""))
	fort.x=point.x;fort.z=point.y
	fort.status="building";fort.progress=float(k.work)*MOVE_KEEP;fort.condition=1.0
	fort.erase("old_post")
	fort.name="%s %s" % [_compass(seat(),point),String(k.name).to_lower()]
	_tell("%s is taken down and carried to %s, %d km out: about %d days to raise it again." % [was,String(fort.name),roundi(float(q.km)),int(q.days)])
	return {"ok":true,"fort":fort}

# --- Older campaigns and the leaders' forts ----------------------------------

## A people whose land grew before forts existed keeps a ring of old posts
## toward where its border lay (realm_reach.gd): at seven tenths of the old
## reach, but no farther than a line can be held (SEED_REACHES), linked one
## to the next, of the best kind it knows, standing. Once.
static func seed_old_posts()->void:
	var d:Dictionary=WorldSimulation.state.border_forts
	if not d.has("forts"):d.merge({"forts":[],"border_share":-1.0,"next_id":1},false)
	d.seeded=true
	if not forts().is_empty():return
	var k:=best_kind()
	if k.is_empty():return
	var old:=float(preload("res://scripts/realm_reach.gd").ours().get("reach",0.0))
	var home:=home_km()
	if old<home*1.5:return
	# One ring a line of forts can hold: never farther out than SEED_REACHES of
	# the kind's reach, spaced so that each links to the next.
	var ring:=clampf(old*0.7,home*1.5,float(k.reach)*SEED_REACHES)
	var count:=clampi(ceili(TAU*ring/(float(k.reach)*2.0*LINK_SPAN*0.8)),3,12)
	var center:=seat()
	var turn:=float(posmod(hash(str(WorldSimulation.state.world_seed)+WorldSimulation.actor_id),360))*PI/180.0
	for i in count:
		var u:=Vector2.RIGHT.rotated(turn+TAU*float(i)/float(count))
		var at:=Vector2.INF
		for step in 8:
			var p:=center+u*ring*(1.0-float(step)*0.1)
			if not WorldSimulation.world.scout_land_authority.is_valid() or WorldSimulation.world._scout_land_at(p):at=p;break
		if not at.is_finite():continue
		(d.forts as Array).append({"id":int(d.next_id),"kind":String(k.id),"x":at.x,"z":at.y,"status":"standing","progress":float(k.work),"condition":1.0,"since":int(WorldSimulation.state.elapsed_days),"old_post":true,"name":"%s old border post" % _compass(center,at)})
		d.next_id=int(d.next_id)+1
	if not forts().is_empty() and WorldSimulation.actor_id=="player":
		_tell("Our old border posts are counted: %d %ss hold the land our people have long called ours. Each must be manned, fed and kept; posts not kept fall away, and the border with them." % [forts().size(),String(k.name).to_lower()])

## A computer ruler's border, monthly, by the one rule: with food to spare
## and no fort going up, raise one toward the nearest people it knows, inside
## reach of its line; leave forts it cannot keep.
static func _leaders_decide()->void:
	var state:=WorldSimulation.state
	if forts().any(func(f:Dictionary)->bool:return String(f.get("status",""))=="building"):return
	if float(state.simulation_metrics.get("food_days",0.0))<60.0:return
	var k:=best_kind()
	if k.is_empty() or standing().size()>=10:return
	var center:=seat()
	var target:=Vector2.INF;var best:=INF
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))<2:continue
		var there:Vector2=WorldSimulation.world._civilization_world_position(civ)
		if there.distance_to(center)<best:best=there.distance_to(center);target=there
	if not target.is_finite():return
	var shape:=outline()
	var u:=(target-center).normalized()
	var k_index:=posmod(roundi(fposmod(u.angle(),TAU)/TAU*float(BEARINGS)),BEARINGS)
	var edge:=float((shape.table as PackedFloat32Array)[k_index])
	var km:=minf(edge+float(k.reach)*0.8,best*0.45)
	if km<=edge+2.0:return
	build(center+u*km)

# --- Words -------------------------------------------------------------------

static func _compass(from:Vector2,to:Vector2)->String:
	var names:=["East","Southeast","South","Southwest","West","Northwest","North","Northeast"]
	return String(names[posmod(roundi((to-from).angle()/(PI*0.25)),8)])

static func _tell(text:String)->void:
	if WorldSimulation.actor_id!="player":return
	WorldSimulation.state.simulation_events.push_front({"day":int(WorldSimulation.state.elapsed_days),"title":"THE BORDER","description":text,"domain":"security","severity":"notice"})
	if WorldSimulation.state.simulation_events.size()>80:WorldSimulation.state.simulation_events.resize(80)
