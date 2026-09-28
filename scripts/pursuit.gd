extends RefCounted
## THE MEN WHO GOT AWAY, AND THE CHASE AFTER THEM.
##
## When the men of a town we hold are put to the sword (town_fate.gd) or
## rounded up (occupation_measures.gd), some may get away. They are counted
## in the town's one ledger (town_ledger.gd: its running record says how
## many, of which groups, which day and which way they ran: their people's
## nearest other town, else the hills). Bound men never run. The war leader
## says so and offers a chase.
##
## A chase is a real, bounded operation:
##   begin()  a detachment leaves the garrison (the garrison's count drops by
##            as many) as its own small field army at the town, and walks a
##            short way after them: a day or two out, never more than
##            MAX_DAYS_OUT. Foot pursuit of scattered men in their own
##            country is mostly fruitless, and the numbers say so.
##   daily()  the chase ends where the detachment stops (or when its days are
##            up): each man is caught on the stated chance (chance_of: the
##            pursuers to the runners, horses, the days lost), one seeded
##            roll each; the caught are killed and the rest get away; a man
##            of ours may be hurt. The war leader reports once with the
##            numbers and the odds (a court matter and one Chronicle line).
##            The detachment turns back, reaches the town and rejoins the
##            garrison. If the town is gone by then, it walks home instead.
##   Those who got away reach their refuge: the ledger counts them fled (and
##   where), they are moved out of the town into their people's other towns
##   (or out of every town, into the hills), and a share of the men are
##   fighting men their people can use again (bounded). If nobody chases
##   them within FLED_DAYS, they are gone the same way.
##
## A detachment is an ordinary field army carrying a `pursuit` record, so
## the map draws it, recall reaches it, rations feed it, and a save keeps it.
## reconcile() repairs a detachment whose record no longer matches the
## world (loaded saves, a lost town, a march that stopped): it is sent back
## to its town or home, or rejoins its garrison where it stands.
## Static helpers; preload.

const Chronicle:=preload("res://scripts/chronicle.gd")
const Ledger:=preload("res://scripts/town_ledger.gd")

const WAR_LOOP_PATH:="res://scripts/war_loop.gd"

## A chase ends after this many days out, caught or not.
const MAX_DAYS_OUT:=3
## After this many days nobody catches men who ran; they have reached their refuge.
const FLED_DAYS:=4
## How long the garrison remembers who got away (for a plain answer).
const FLED_REMEMBER:=40
## The garrison always keeps some at the gate.
const KEEP_AT_LEAST:=2
const KEEP_SHARE:=0.25
## A detachment out longer than this is brought back, whatever held it up.
const STUCK_DAYS:=14
## Of the men who got away, the share who are fighting men their people use again.
const FIGHTERS_SHARE:=0.6
const MAX_FIGHTERS_BACK:=40


static func _mc()->Variant: return WorldSimulation.military
static func _world()->Variant: return WorldSimulation.world
static func _day()->int: return int(WorldSimulation.state.elapsed_days) if WorldSimulation.state!=null else 0

static func _count(n:int)->String:
	return preload("res://scripts/battle_account.gd").count_words(n) if n<=12 else str(n)

static func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)

static func _v2(p:Variant)->Vector2:
	if p is Vector2: return p
	if p is Dictionary and (p as Dictionary).has_all(["x","z"]): return Vector2(float(p.x),float(p.z))
	return Vector2.INF


# --------------------------------------------------------------------------
# Where things are
# --------------------------------------------------------------------------

## Where a town we hold stands on our chart: the place our people know it
## by (the same point its label and marching orders use), else the site.
static func town_position(region_id:String)->Vector2:
	var world:Variant=_world()
	if world==null or world.city_intelligence==null: return Vector2.INF
	var known:Dictionary=world.city_intelligence.known("player",region_id)
	var at:=_v2(known.get("position",{}))
	if at.is_finite() and world.city_intelligence.valid_point(known.get("position",{})): return at
	return _v2(world.city_intelligence.site(region_id).get("position",{}))


## Where the men of a town run: their people's nearest other town they
## still hold, else the hills away from us. {name, region_id, position, hills}.
static func refuge(civ_id:String,region_id:String)->Dictionary:
	var world:Variant=_world()
	var from:=town_position(region_id)
	var index:int=world._civilization_index(civ_id)
	var best:={}
	var best_d:=INF
	if index>=0 and from.is_finite():
		for r:Dictionary in world.civilizations[index].strategic_regions:
			var rid:=String(r.get("id",""))
			if rid==region_id or not bool(r.get("settlement_founded",true)): continue
			if String(r.get("controller",civ_id))!=civ_id: continue
			var at:=_v2(world.city_intelligence.site(rid).get("position",{}))
			if not at.is_finite(): continue
			var d:=from.distance_to(at)
			if d<best_d: best_d=d; best={"name":String(r.get("name","their other town")),"region_id":rid,"position":{"x":at.x,"z":at.y},"hills":false}
	if not best.is_empty(): return best
	# Nowhere of theirs to go: into the hills, away from us.
	var home:Vector2=world.player_world_origin
	var away:=(from-home).normalized() if from.is_finite() and from.distance_to(home)>0.5 else Vector2.UP
	var hills:=from+away*25.0 if from.is_finite() else Vector2.INF
	return {"name":"the hills","region_id":"","position":{"x":hills.x,"z":hills.y} if hills.is_finite() else {},"hills":true}


# --------------------------------------------------------------------------
# The men who got away
# --------------------------------------------------------------------------

## n free men of a town we hold run for their refuge (a sack they escaped):
## the town's ledger counts them as running until they get there. Returns
## the flight record ({} when none).
static func record_flight(civ_id:String,region_id:String,count:int)->Dictionary:
	if count<=0: return {}
	var l:=Ledger.of(civ_id,region_id)
	if l.is_empty(): return {}
	return Ledger.run(l,"free","men",count,refuge(civ_id,region_id),_day()).duplicate(true)

## The last flight from a town (the town's ledger): {count (still running),
## ran, caught, reached, day, toward, toward_id, toward_position, hills,
## state}. {} when nobody ran.
static func flight_of(civ_id:String,region_id:String)->Dictionary:
	# An older save keeps its flight on the garrison: the ledger takes it over.
	var mc:Variant=_mc()
	var legacy:=false
	if mc!=null:
		var at:int=mc._occupation_force_index(civ_id,region_id)
		legacy=at>=0 and mc.occupation_forces[at].get("fled") is Dictionary
	var l:=Ledger.of(civ_id,region_id,legacy)
	return Ledger.last_flight(l) if not l.is_empty() else {}


## Words for where they ran ("toward Stonefield", "into the hills").
static func toward_words(fled:Dictionary)->String:
	return "into the hills" if bool(fled.get("hills",false)) else "toward %s" % String(fled.get("toward",fled.get("name","their other towns")))


## The held town whose people ran most recently: {civ_id, region_id, name,
## fled (the flight record), garrison, age}; {} when none. region_id narrows
## it to that town.
static func latest_flight(region_id:String="")->Dictionary:
	var mc:Variant=_mc()
	if mc==null: return {}
	var best:={}
	for f in mc.occupation_forces:
		var force:Dictionary=f
		if region_id!="" and String(force.get("region_id",""))!=region_id: continue
		# Only a town we hold (the one reading) has a garrison to send.
		if not Ledger.holds(String(force.get("civ_id","")),String(force.get("region_id",""))): continue
		var fled:=flight_of(String(force.get("civ_id","")),String(force.get("region_id","")))
		if fled.is_empty(): continue
		var age:=_day()-int(fled.get("day",0))
		if age>FLED_REMEMBER: continue
		if best.is_empty() or int(fled.day)>int((best.fled as Dictionary).day):
			best={"civ_id":String(force.get("civ_id","")),"region_id":String(force.get("region_id","")),"name":String(force.get("region_name","the town")),"fled":fled.duplicate(true),"garrison":int(force.get("troops",0)),"age":age}
	return best


## The offer the war leader makes when men got away ("" when none).
static func offer_words(fled:Dictionary,garrison:int)->String:
	# Only fighting men are hunted; women, children and the old are let go.
	var n:=int((fled.get("groups",{}) as Dictionary).get("men",0)) if fled.get("groups") is Dictionary else int(fled.get("count",0))
	if n<=0: return ""
	var spare:=detachment_size(garrison,n,0)
	if spare<=0: return "I have too few in the town to send any after them."
	return "I can send %s of the garrison after them for a day or two, if you want it. They know the paths out there and we do not." % _count(spare)


## How many go: an asked number, bounded by the garrison less the watch it keeps.
static func detachment_size(garrison:int,fled:int,asked:int)->int:
	var keep:=maxi(KEEP_AT_LEAST,ceili(float(garrison)*KEEP_SHARE))
	var most:=maxi(0,garrison-keep)
	if asked>0: return mini(asked,maxi(0,garrison-1))
	return mini(most,maxi(4,fled+fled/2))


# --------------------------------------------------------------------------
# The chase
# --------------------------------------------------------------------------

## Send a detachment after the people who fled a town we hold.
## {ok, army_id, troops, days, says, outcome} | {error (plain words), reason}.
static func begin(civ_id:String,region_id:String,asked:int=0)->Dictionary:
	var mc:Variant=_mc()
	var world:Variant=_world()
	if mc==null or world==null: return {"error":"We have nobody to send.","reason":"no_military"}
	var at:int=mc._occupation_force_index(civ_id,region_id)
	var h:=Ledger.hold(civ_id,region_id)
	if at<0 or not bool(h.held):
		var why:=Ledger.hold_words(h)
		return {"error":(why+" There is nobody of ours there to send after them.") if why!="" else "Nobody of ours holds that town, so there is nobody to send after them.","reason":"no_garrison"}
	var force:Dictionary=mc.occupation_forces[at]
	var name:=String(force.get("region_name","the town"))
	var fled:=flight_of(civ_id,region_id)
	if fled.is_empty(): return {"error":"Nobody is running from %s that I know of." % name,"reason":"nobody_fled"}
	var age:=_day()-int(fled.get("day",0))
	if String(fled.get("state",""))=="chased" and int(fled.get("count",0))>0: return {"error":"Some of ours are already after the men who ran from %s." % name,"reason":"already"}
	if String(fled.get("state",""))!="running" or int(fled.get("count",0))<=0 or age>FLED_DAYS:
		var ran:=int(fled.get("ran",fled.get("count",0)))
		var caught_n:=int(fled.get("caught",0))
		if String(fled.get("state",""))=="caught" or (ran>0 and caught_n>=ran):
			return {"error":"Nobody is left running from %s: the %s who ran were caught." % [name,_count(ran)],"reason":"too_late"}
		return {"error":"The men who ran from %s got away %s %s ago. They are %s by now; nobody catches them on foot after that." % [name,toward_words(fled),"a day" if age<=1 else "%s days" % _count(age),"in the hills" if bool(fled.get("hills",false)) else "inside %s" % String(fled.get("toward","their other towns"))],"reason":"too_late"}
	if not mc.active_engagement.is_empty(): return {"error":"Not while a battle is being fought.","reason":"busy"}
	if mc.field_armies.size()>=mc.field_army_capacity(): return {"error":"I cannot split off another band: every command we can lead is already out.","reason":"capacity"}
	var garrison:=int(force.get("troops",0))
	# Fighters guarding bound men or hostages (occupation_measures.gd) stay.
	var tied:=0
	for m in force.get("measures",[]):
		if m is Dictionary and not bool((m as Dictionary).get("ended",false)): tied+=int((m as Dictionary).get("guards",0))
	# Only the men who ran are hunted.
	var men:=int(Ledger._rec_groups(fled).get("men",0))
	if men<=0: return {"error":"Only women, children and old people ran from %s; there are no fighting men to go after." % name,"reason":"nobody_fled"}
	var sent:=detachment_size(maxi(0,garrison-tied),men,asked)
	if sent<=0: return {"error":"%s of ours hold %s. If any go after them, nobody keeps the gate." % [_cap(_count(garrison)),name],"reason":"too_few"}
	var from:=town_position(region_id)
	if not from.is_finite(): return {"error":"I do not know that ground well enough to send men across it.","reason":"no_position"}
	var goal:=_chase_point(from,_v2(fled.get("toward_position",{})),mc,force)
	if not goal.is_finite(): return {"error":"They ran across water or ground we cannot cross. There is no following them.","reason":"no_route"}
	# The detachment leaves the garrison: its formations, gear and all.
	var reserve:Dictionary=mc.home_army
	mc.home_army=force.duplicate(true)
	var detached:Array[Dictionary]=mc._detach_occupation_formations(sent)
	var reduced:Dictionary=mc.home_army
	mc.home_army=reserve
	var took:=0
	for formation in detached: took+=int(formation.get("count",0))
	if took<=0: return {"error":"Nobody in the garrison is fit to go.","reason":"too_few"}
	var made:Dictionary=mc._assemble_field_army(detached,"Detachment from %s" % name)
	if made.has("error"):
		# Put them back as they were.
		mc.occupation_forces[at]=force
		return {"error":String(made.error),"reason":"cannot_form"}
	mc.occupation_forces[at]=_rebuilt(reduced,reduced.get("formations",[]))
	var index:int=mc._field_army_index(int((made.army as Dictionary).army_id))
	var army:Dictionary=mc.field_armies[index]
	army["position"]={"x":from.x,"z":from.y}
	army["location_id"]=region_id; army["location_name"]=name
	army["commander"]=(force.get("commander",{}) as Dictionary).duplicate(true)
	army["supply_level"]=clampf(float(force.get("supply_level",army.get("supply_level",1.0))),0.0,1.0)
	army["morale"]=float(force.get("morale",army.get("morale",0.6)))
	army["pursuit"]={"civ_id":civ_id,"region_id":region_id,"town":name,"fled":men,"toward":String(fled.get("toward","")),"hills":bool(fled.get("hills",false)),
		"toward_id":String(fled.get("toward_id","")),"state":"chasing","start_day":_day(),"fled_day":int(fled.get("day",_day())),"sent":took,"reported":false}
	mc.field_armies[index]=army
	var march:=_march(index,goal,"field_position","the men who fled %s" % name)
	if march.has("error"):
		_rejoin(index)
		return {"error":String(march.error),"reason":"no_route"}
	army=mc.field_armies[index]
	army["last_report"]=mc._army_report_snapshot(army)
	mc.field_armies[index]=army
	fled["state"]="chased"
	var days:=mini(MAX_DAYS_OUT,maxi(1,int(march.days)))
	var left:=int(mc.occupation_forces[at].get("troops",0))
	return {"ok":true,"army_id":int(army.army_id),"troops":took,"days":days,"left":left,"town":name,
		"says":"%s of the garrison go after them %s now; %s stay to hold %s. I will not keep them out more than %s: after that the men will be where we cannot follow." % [_cap(_count(took)),toward_words(fled),_count(left),name,"a day" if days<=1 else "%s days" % _count(days)],
		"outcome":"%s set out after the men who fled %s." % [_cap(_count(took)),name]}


## A point a short way along their flight: a day or so out, on dry ground
## the detachment can reach. INF when there is none.
static func _chase_point(from:Vector2,toward:Vector2,mc:Variant,force:Dictionary)->Vector2:
	var world:Variant=_world()
	var home:Vector2=world.player_world_origin
	var dir:=(toward-from).normalized() if toward.is_finite() and toward.distance_to(from)>0.5 else ((from-home).normalized() if from.distance_to(home)>0.5 else Vector2.UP)
	var reach:=float(toward.distance_to(from))*0.5 if toward.is_finite() else 20.0
	var speed:=maxf(4.0,float(mc._field_army_speed(force)))
	var km:=clampf(minf(reach,speed*1.5),3.0,30.0)
	var land:=Callable(world,"_scout_land_at")
	for scale in [1.0,0.6,0.35]:
		for turn in [0.0,0.4,-0.4]:
			var goal:=from+dir.rotated(turn)*km*float(scale)
			if land.is_valid() and not bool(land.call(goal)): continue
			if not mc.field_route(from,goal,force).has("error"): return goal
	return Vector2.INF


## Set a field army on a short march (no chart check: the garrison stands on
## that ground and saw where the men ran). {days} | {error}.
static func _march(index:int,goal:Vector2,destination_id:String,label:String)->Dictionary:
	var mc:Variant=_mc()
	var army:Dictionary=mc.field_armies[index]
	var start:=_v2(army.get("position",{}))
	var distance:=start.distance_to(goal)
	if distance<0.5:
		army["status"]="stationed"; army["position"]={"x":goal.x,"z":goal.y}; army["destination_id"]=""; army["distance_remaining_km"]=0.0
		if destination_id!="field_position": army["location_id"]=destination_id; army["location_name"]=label
		mc.field_armies[index]=army
		return {"days":0}
	var route:Dictionary=mc.field_route(start,goal,army)
	if route.has("error"): return {"error":String(route.error)}
	var speed:=maxf(0.1,float(mc._field_army_speed(army)))
	army.erase("city_operation"); army.erase("movement_block_reason")
	army["status"]="moving"
	army["origin_position"]={"x":start.x,"z":start.y}
	army["destination_id"]=destination_id
	army["destination_name"]=label
	army["destination_position"]={"x":goal.x,"z":goal.y}
	mc._set_march_route(army,route)
	army["distance_total_km"]=float(route.length_km)
	army["distance_remaining_km"]=float(route.length_km)
	army["departure_day"]=_day()
	# The one march estimate (march_terrain.gd), as the daily march spends it.
	var days:=int(mc._march_days_left(army,start))
	army["arrival_day"]=_day()+days
	army["speed_km_day"]=speed
	mc.field_armies[index]=army
	return {"days":days}


## Every detachment still out: [{army_id, troops, town, state}].
static func detachments()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var mc:Variant=_mc()
	if mc==null: return out
	for a in mc.field_armies:
		var p:Variant=(a as Dictionary).get("pursuit")
		if p is Dictionary: out.append({"army_id":int(a.army_id),"troops":int(a.get("troops",0)),"town":String(p.get("town","")),"region_id":String(p.get("region_id","")),"state":String(p.get("state",""))})
	return out


## How many of a town's garrison are out on a chase now.
static func away_from(region_id:String)->int:
	var n:=0
	for d:Dictionary in detachments():
		if String(d.region_id)==region_id: n+=int(d.troops)
	return n


## What a detachment is doing, in plain words ("" when it is not one).
static func doing_words(army:Dictionary)->String:
	var p:Variant=army.get("pursuit")
	if not p is Dictionary: return ""
	var town:=preload("res://scripts/hud/army_marks.gd").place(String(p.get("town","the town")))
	match String(p.get("state","")):
		"chasing": return "chasing the %s men who fled" % town
		"returning": return ("marching to join the garrison at %s" if bool((p as Dictionary).get("reinforce",false)) else "returning to %s") % town
		"home": return "marching home"
	return ""


## Called each day (court_war_orders.daily). Returns report matters filed.
static func daily(day:int)->Array:
	var filed:Array=[]
	var mc:Variant=_mc()
	var world:Variant=_world()
	if mc==null or world==null: return filed
	# People nobody went after reach their refuge (every town with a ledger,
	# held or burned and left).
	for pair in Ledger.towns():
		var l:=Ledger.of(String(pair[0]),String(pair[1]),false)
		var rec:=Ledger.running(l)
		if not rec.is_empty() and String(rec.get("state",""))=="running" and day-int(rec.get("day",day))>FLED_DAYS:
			arrive(String(pair[0]),String(pair[1]))
	var i:int=mc.field_armies.size()-1
	while i>=0:
		var army:Dictionary=mc.field_armies[i]
		var p:Variant=army.get("pursuit")
		if p is Dictionary:
			var matter:=_step(i,day)
			if not matter.is_empty(): filed.append(matter)
		i-=1
		i=mini(i,mc.field_armies.size()-1)
	return filed

## Everyone still running from a town reaches their refuge now: the ledger
## counts them fled (and where), and the world moves them. Returns how many.
static func arrive(civ_id:String,region_id:String)->int:
	var l:=Ledger.of(civ_id,region_id,false)
	if l.is_empty(): return 0
	var rec:=Ledger.running(l)
	if rec.is_empty(): return 0
	var where:=rec.duplicate(true)
	var took:=Ledger.reached_refuge(l,int(rec.count))
	_reach_refuge(civ_id,region_id,int(took.total),where,int(took.get("men",0)))
	return int(took.total)


static func _step(index:int,day:int)->Dictionary:
	var mc:Variant=_mc()
	var army:Dictionary=mc.field_armies[index]
	var p:Dictionary=army.pursuit
	if mc.command_hierarchy.battle.engaged(int(army.army_id)): return {}
	var state:=String(p.get("state",""))
	var stopped:=String(army.get("status",""))!="moving"
	if state=="chasing":
		if stopped or day-int(p.get("start_day",day))>=MAX_DAYS_OUT: return _resolve(index,day)
		return {}
	if state=="returning":
		var town:=town_position(String(p.region_id))
		var here:=_v2(army.get("position",{}))
		if stopped and town.is_finite() and here.distance_to(town)<=1.0: _rejoin(index); return {}
		if stopped or day-int(p.get("start_day",day))>STUCK_DAYS: _send_back(index)
		return {}
	if state=="home":
		if stopped and mc._army_is_home(army):
			army.erase("pursuit"); mc.field_armies[index]=army
		return {}
	return {}


## The chase ends: the stated chance for each man, one seeded roll each; the
## caught are killed, the rest reach their refuge; one report; the
## detachment turns back.
static func _resolve(index:int,day:int)->Dictionary:
	var mc:Variant=_mc()
	var world:Variant=_world()
	var army:Dictionary=mc.field_armies[index]
	var p:Dictionary=army.pursuit
	var civ_id:=String(p.civ_id); var region_id:=String(p.region_id); var town:=String(p.town)
	var l:=Ledger.of(civ_id,region_id,false)
	var rec:=Ledger.running(l) if not l.is_empty() else {}
	# The men who ran: the ones the detachment went after.
	var fled:=Ledger.running_men(l) if not l.is_empty() else 0
	var sent:=maxi(1,int(army.get("troops",p.get("sent",1))))
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("pursuit|%d|%s|%d|%d" % [int(GameState.world_seed),region_id,int(p.get("start_day",day)),sent])
	# Scattered men in their own country: most get away. More pursuers and
	# horses help a little; every day since they ran hurts.
	var mounted:=0
	for formation in army.get("formations",[]):
		if String((formation as Dictionary).get("unit",""))=="cavalry": mounted+=int(formation.get("count",0))
	var late:=maxi(0,int(p.get("start_day",day))-int(p.get("fled_day",day)))
	var chance:=chance_of(sent,fled,mounted,late)
	var caught:=Ledger.roll(rng,fled,chance)
	var hurt:=1 if sent>2 and rng.randf()<0.15 else 0
	var killed:=0
	var where_rec:=rec.duplicate(true)
	var away:=0
	if not l.is_empty():
		# The ledger first (the world's changes rebuild the town's record, and
		# the ledger goes with it): the caught die, the rest reach their refuge.
		killed=Ledger.caught(l,caught,"men")
		var took:=Ledger.reached_refuge(l,Ledger.running_total(l))
		away=int(took.total)
		var index_civ:int=world._civilization_index(civ_id)
		if killed>0 and index_civ>=0:
			var done:Dictionary=world._apply_rival_civilian_deaths(world.civilizations[index_civ],region_id,killed)
			world.civilizations[index_civ]=done.civilization
		_reach_refuge(civ_id,region_id,away,where_rec,int(took.get("men",0)))
	# A hurt man is carried back; he mends with the garrison or at home.
	if hurt>0: _hurt(index,hurt)
	army=mc.field_armies[index]
	p["state"]="returning"; p["caught"]=killed; p["got_away"]=away; p["hurt"]=hurt; p["start_day"]=day; p["reported"]=true; p["chance"]=chance
	army["pursuit"]=p
	mc.field_armies[index]=army
	var back:=_send_back(index)
	var where:="into the hills" if bool(p.get("hills",false)) else "toward %s" % String(p.get("toward","their other towns"))
	var odds:="%s, %s for each man" % [chance_quality(chance),Ledger.chance_words(chance)]
	var text:=""
	if fled<=0:
		text="We went after the men who fled %s with %s, but they were gone before we got onto their tracks." % [town,_count(sent)]
	elif killed>0:
		text="We went after the men who fled %s with %s: %s of them running in their own country, %s. We ran down %s and killed them; the other %s got away %s, where we could not follow." % [town,_count(sent),_count(fled),odds,_count(killed),_count(away),where]
	else:
		text="We went after the men who fled %s with %s: %s of them running in their own country, %s. We followed their tracks until they split up in rough ground and lost them; all %s got %s." % [town,_count(sent),_count(fled),odds,_count(fled),where]
	if hurt>0: text+=" One of ours was hurt and is carried back."
	text+=" "+String(back.get("words",""))
	return _report(civ_id,town,region_id,int(army.army_id),text,day)

## The chance to catch each man: pursuers to runners, horses, the days lost.
static func chance_of(sent:int,fled:int,mounted:int,late:int)->float:
	return clampf(0.08+0.18*clampf(float(sent)/maxf(1.0,float(fled)),0.0,1.5)/1.5+0.25*float(mounted)/float(maxi(1,sent))-0.05*float(late),0.02,0.45)

static func chance_quality(p:float)->String:
	if p<0.2: return "a poor chance"
	if p<0.35: return "a fair chance"
	return "a good chance"


## Those who got away reach their refuge: out of the town into their other
## towns, or into the hills (out of every town), and the men among them are
## fighting men again (bounded). The ledger is the caller's to write first.
## men: how many of them are men (-1: all).
static func _reach_refuge(civ_id:String,region_id:String,count:int,fled:Dictionary,men:int=-1)->void:
	var world:Variant=_world()
	if world==null or count<=0: return
	var index:int=world._civilization_index(civ_id)
	if index<0: return
	var left:=count
	if not bool(fled.get("hills",false)):
		for attempt in 12:
			if left<=0: break
			var moved:Dictionary=world._apply_rival_displacement(world.civilizations[index],region_id,left)
			world.civilizations[index]=moved.civilization
			var n:=int(moved.get("displaced",0))
			if n<=0: break
			left-=n
	if left>0: _into_the_hills(civ_id,region_id,left)
	var civ:Dictionary=world.civilizations[index]
	var fighters:=mini(MAX_FIGHTERS_BACK,roundi(float(count if men<0 else men)*FIGHTERS_SHARE))
	if fighters>0 and civ.has("military_population"):
		civ["military_population"]=float(civ.get("military_population",0.0))+float(fighters)
		world.civilizations[index]=civ

## n people leave a town for the hills: out of the town's count, still their
## people's (the multi-actor world counts them as gone from the settlement).
static func _into_the_hills(civ_id:String,region_id:String,n:int)->void:
	var world:Variant=_world()
	var index:int=world._civilization_index(civ_id)
	if index<0 or n<=0: return
	var civ:Dictionary=world.civilizations[index]
	var ri:int=world._region_index(civ,region_id)
	if ri<0: return
	var region:Dictionary=civ.strategic_regions[ri]
	var here:=maxi(0,roundi(float(region.get("population",0.0))))
	var gone:=mini(n,here)
	if gone<=0: return
	if WorldSimulation.enabled:
		var city_id:=String(region.get("local_city_id",""))
		if city_id!="":
			WorldSimulation.scoped(preload("res://scripts/civilization_combat.gd").owner(civ_id),func()->void:
				WorldSimulation.settlements.with_city_resources(city_id,func()->void:
					WorldSimulation.settlements.with_local_population(func()->void:
						WorldSimulation.state.register_population_departures(gone,"Fled into the hills")
					,true)
				)
			)
	region["population"]=maxf(0.0,float(region.get("population",0.0))-float(gone))
	civ["displaced_population"]=maxf(0.0,float(civ.get("displaced_population",0.0))+float(gone))
	world.civilizations[index]=civ


static func _hurt(index:int,count:int)->void:
	var mc:Variant=_mc()
	var army:Dictionary=mc.field_armies[index]
	var formations:Array=army.get("formations",[])
	var left:=count
	for i in range(formations.size()-1,-1,-1):
		if left<=0: break
		var take:=mini(left,maxi(0,int(formations[i].get("count",0))-(1 if i==0 else 0)))
		if take<=0: continue
		formations[i]["count"]=int(formations[i].count)-take
		left-=take
	var hurt:=count-left
	if hurt<=0: return
	army["formations"]=formations
	army["troops"]=maxi(0,int(army.get("troops",0))-hurt)
	army["wounded_pool"]=int(army.get("wounded_pool",0))+hurt
	mc.field_armies[index]=army


## Turn a detachment back to its town (or home when the town is no longer
## ours). {days, to:"town"|"home", words} | {error, words}.
static func _send_back(index:int)->Dictionary:
	var mc:Variant=_mc()
	var army:Dictionary=mc.field_armies[index]
	var p:Dictionary=army.pursuit
	var held:=_town_to_rejoin(String(p.civ_id),String(p.region_id))
	var town:=town_position(String(p.region_id))
	var name:=String(p.get("town","the town"))
	if held and town.is_finite():
		p["state"]="returning"; p["start_day"]=_day()
		army["pursuit"]=p; mc.field_armies[index]=army
		var went:=_march(index,town,String(p.region_id),name)
		if went.has("error"):
			# No road back from here: they find their own way in.
			_rejoin(index)
			return {"days":0,"to":"town","words":"We are back inside %s." % name}
		var days:=int(went.get("days",0))
		if days<=0:
			# Still at the gate: they are back in the garrison at once.
			_rejoin(index)
		return {"days":days,"to":"town","words":"We are walking back to %s, about %s on the road." % [name,"a day" if days<=1 else "%s days" % _count(days)] if days>0 else "We are back inside %s." % name}
	p["state"]="home"; army["pursuit"]=p; mc.field_armies[index]=army
	var r:Dictionary=mc.return_field_army(int(army.army_id))
	if r.has("error"): return {"error":String(r.error),"words":"%s is not ours now, and we cannot start for home yet: %s" % [name,String(r.error)]}
	var home_days:=int(r.get("days",0))
	return {"days":home_days,"to":"home","words":"%s is not ours now, so we are coming home, %s." % [name,"about a day" if home_days<=1 else "about %s days" % _count(home_days)]}


## A detachment's town is still ours, with its garrison there to rejoin
## (town_ledger.hold: the region says whose it is; the detachment is part of
## that garrison, so its own absence never makes the town unheld).
static func _town_to_rejoin(civ_id:String,region_id:String)->bool:
	var mc:Variant=_mc()
	return mc!=null and int(mc._occupation_force_index(civ_id,region_id))>=0 and bool(Ledger.hold(civ_id,region_id).get("ours",false))


## The detachment rejoins its garrison where it stands; with no garrison
## left, it goes home.
static func _rejoin(index:int)->void:
	var mc:Variant=_mc()
	var army:Dictionary=mc.field_armies[index]
	var p:Dictionary=army.get("pursuit",{})
	var at:int=mc._occupation_force_index(String(p.get("civ_id","")),String(p.get("region_id","")))
	if at<0:
		p["state"]="home"; army["pursuit"]=p; mc.field_armies[index]=army
		mc.return_field_army(int(army.army_id))
		return
	var force:Dictionary=mc.occupation_forces[at]
	var combined:Array=(force.get("formations",[]) as Array).duplicate(true)
	combined.append_array((army.get("formations",[]) as Array).duplicate(true))
	var joined:=_rebuilt(force,combined)
	for pool in ["wounded_pool","disabled_pool","severe_disabled_pool","scattered_pool","captured_pool"]:
		if int(army.get(pool,0))>0: joined[pool]=int(force.get(pool,0))+int(army.get(pool,0))
	mc.occupation_forces[at]=joined
	mc.field_armies.remove_at(index)
	mc._refresh_readiness()
	mc.army_changed.emit(mc.home_army.duplicate(true))


## A garrison record rebuilt round a new set of formations (strength and
## the rest recomputed), keeping who it is and what it holds.
static func _rebuilt(force:Dictionary,formations:Array)->Dictionary:
	var mc:Variant=_mc()
	var joined:Dictionary=mc.simulator.create_formation_force(String(force.get("name","OCCUPATION")),formations.duplicate(true),float(force.get("morale",0.55)),float(force.get("readiness",0.45)))
	for key in force:
		if not joined.has(key) or key in ["commander","fate_note","civ_id","region_id","region_name","required","supply_level","committed_day"]:
			joined[key]=force[key].duplicate(true) if force[key] is Dictionary or force[key] is Array else force[key]
	return joined


## Turn detachments back (recall). to_town: back to their garrison;
## otherwise home, leaving the garrison for good. [{name, troops, days, to}].
static func recall(to_town:bool)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var mc:Variant=_mc()
	if mc==null: return out
	var i:int=mc.field_armies.size()-1
	while i>=0:
		var army:Dictionary=mc.field_armies[i]
		var p:Variant=army.get("pursuit")
		if p is Dictionary and String(p.get("state",""))!="home":
			var troops:=int(army.get("troops",0))
			var town:=String(p.get("town","the town"))
			if to_town and _town_to_rejoin(String(p.civ_id),String(p.region_id)):
				var back:Dictionary={}
				if String(p.state)=="returning" and String(army.get("status",""))=="moving":
					back={"days":maxi(0,int(army.get("arrival_day",_day()))-_day())}
				else:
					if String(p.state)=="chasing":
						# Called off: the men they chased keep running, and get there.
						p["called_off"]=true; army["pursuit"]=p; mc.field_armies[i]=army
						arrive(String(p.civ_id),String(p.region_id))
					back=_send_back(i)
				out.append({"name":"the detachment from %s" % town,"troops":troops,"days":int(back.get("days",0)),"to":town})
			else:
				p["state"]="home"; army["pursuit"]=p; mc.field_armies[i]=army
				var r:Dictionary=mc.return_field_army(int(army.army_id))
				out.append({"name":"the detachment from %s" % town,"troops":troops,"days":int(r.get("days",0)),"to":"home","error":String(r.get("error",""))})
		i-=1
	return out


## Repair detachments whose record no longer matches the world (on load and
## daily): a finished chase standing idle goes back; a detachment of a town
## we lost goes home; one out far too long rejoins.
static func reconcile()->int:
	var mc:Variant=_mc()
	if mc==null or _world()==null: return 0
	var fixed:=0
	var i:int=mc.field_armies.size()-1
	while i>=0:
		var army:Dictionary=mc.field_armies[i]
		var p:Variant=army.get("pursuit")
		if p is Dictionary:
			var state:=String(p.get("state",""))
			var held:=_town_to_rejoin(String(p.get("civ_id","")),String(p.get("region_id","")))
			var idle:=String(army.get("status",""))!="moving"
			if int(army.get("troops",0))<=0:
				pass
			elif not held and state!="home":
				(p as Dictionary)["state"]="home"; army["pursuit"]=p; mc.field_armies[i]=army
				mc.return_field_army(int(army.army_id)); fixed+=1
			elif state=="returning" and idle:
				var town:=town_position(String(p.region_id))
				if town.is_finite() and _v2(army.get("position",{})).distance_to(town)<=1.0: _rejoin(i)
				else: _send_back(i)
				fixed+=1
			elif state=="chasing" and _day()-int(p.get("start_day",_day()))>STUCK_DAYS:
				_rejoin(i); fixed+=1
		i-=1
		i=mini(i,mc.field_armies.size()-1)
	return fixed


static func _report(civ_id:String,town:String,region_id:String,army_id:int,text:String,day:int)->Dictionary:
	var war_loop:GDScript=load(WAR_LOOP_PATH)
	var matter:Variant=war_loop.call("_file",civ_id,"report",text,day)
	Chronicle.record({"key":"pursuit:%s:%d:%d" % [region_id,army_id,day],"title":("The Chase After the Men of %s" % town).substr(0,70),"text":text,"tier":"notice","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":civ_id}}})
	return matter if matter is Dictionary else {"text":text}
