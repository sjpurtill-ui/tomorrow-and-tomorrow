extends RefCounted
## Contact views resolve back to the actual owner. Both sides commit the same
## battle result through MilitaryCampaign, including injuries, gear and captives.
## Every town has its guards: the watch is the military (watch_military.gd);
## its home guard is spread over home and the towns by their people, home
## also keeps the offensive troops not out in a band, a band its men, and
## every town its townsfolk who rise (town_watch); a town's losses are its
## own and its guard's come off the watch (guard_ledger).
static func owner(id:String)->String:return "player" if id=="human" else id
## The id of home's watch-and-townsfolk block when another people's battle
## musters it (force_for): far above any formation id a people allocates.
const MILITIA_ID:=2_000_000_000

static func force_for(incident:Dictionary)->Dictionary:
	var id:=owner(String(incident.get("source_civ_id","")))
	if id!="player" and not WorldSimulation.actors.has(id):return {}
	var field_id:=int(incident.get("owned_force_id",0))
	var formation_id:=String(incident.get("formation_id",""))
	if formation_id.contains(":army:"):field_id=int(formation_id.get_slice(":army:",1))
	var city_id:=String(incident.get("target_region_id",""))
	var local_id:=""
	if city_id!="":
		var place:=WorldSimulation.world.region_snapshot(String(incident.source_civ_id),city_id)
		local_id=String(place.get("local_city_id",""))
	return WorldSimulation.scoped(id,func()->Dictionary:
		var force:Dictionary={}
		if field_id>0:
			var index:=WorldSimulation.military._field_army_index(field_id)
			if index>=0:force=WorldSimulation.military.field_armies[index].duplicate(true)
		elif local_id.is_empty() or bool(WorldSimulation.settlements.settlement_record(local_id).get("primary",false)):
			force=WorldSimulation.military._home_defense_force(false)
			# Home's watch and townsfolk stand as one block with an id of their
			# own, so they go home after the fight (commit_enemy), not into the
			# levy.
			for formation:Dictionary in force.get("formations",[]):
				if int(formation.get("id",0))==-1:formation["id"]=MILITIA_ID
			if force.has("emergency_militia_id"):force["emergency_militia_id"]=MILITIA_ID
		else:
			force=town_watch(local_id)
		if force.is_empty():force=WorldSimulation.military.simulator.create_formation_force(WorldSimulation.state.settlement_name+" defenders",[],.5,.1)
		force["owned_target"]={"actor":id,"field_id":field_id,"city_id":local_id}
		return force
	)

## A town's own defenders when it is attacked: its share of the home guard
## (the watch posted there, drilled as the watch at home is and carrying its
## share of the watch's arms: guard_kit) and its townsfolk who rise
## (guard_ledger) with whatever comes to hand, two blocks side by side. {}
## when nobody would stand. Run in the town's owner's scope.
static func town_watch(city_id:String)->Dictionary:
	var mc:Variant=WorldSimulation.military
	var city:=WorldSimulation.settlements.settlement_record(city_id)
	var guard:Dictionary=guard_ledger(mc).get(city_id,{})
	var watch:=int(guard.get("watch",0));var rise:=int(guard.get("rise",0))
	if watch+rise<=0: return {}
	var formations:Array=[]
	var condition:=float(mc._trainee_condition())
	if watch>0:
		var kit:=guard_kit(mc,watch)
		formations.append({"id":-1,"unit":String(kit.unit),"weapon":String(kit.weapon),"count":watch,"authorized_count":watch,"equipment":int(kit.equipment),"equipment_required":int(kit.equipment_required),"ammunition":0,"ammunition_required":0,
			"training":guard_drill(mc),"experience":0.0,"personnel_condition":condition,"emergency_militia":true})
	if rise>0:
		formations.append({"id":-2,"unit":"levy","weapon":"improvised","count":rise,"authorized_count":rise,"equipment":0,"equipment_required":rise,"ammunition":0,"ammunition_required":0,
			"training":RISE_TRAINING,"experience":0.0,"personnel_condition":condition,"emergency_militia":true})
	var force:Dictionary=mc.simulator.create_formation_force("%s watch" % String(city.get("name","the town")),formations,float(mc._campaign_morale()),0.18)
	force["commander"]=mc.simulator.create_commander("TOWN WATCH",0.35,0.35,0.35,0.45)
	force["supply_level"]=1.0
	force["town_watch"]=city_id
	force["guard_part"]=watch
	return force

## THE TOWNSFOLK RISE. When raiders come, a town's able grown people take up
## arms beside its watch: about one in ten of them, untrained and with what
## comes to hand. Pre-modern villages defended themselves this way, with
## their able men poorly armed (the hue and cry, the local levy of every
## farming people); the share keeps a band of raiders from walking into a
## town of hundreds unopposed without making every farmer a soldier.
const RISE_SHARE:=0.10
## How well each kind of defender is drilled (combat_simulator training):
## the home guard posted in a town is drilled as the watch at home is
## (guard_drill), this when nobody is at home to tell; the townsfolk have
## none. The simulator holds every block at 0.25 drill at the least.
const WATCH_TRAINING:=0.20
const RISE_TRAINING:=0.10

## THE GUARD LEDGER, one for every people: who would defend each of its
## towns if it were attacked now. {city_id: {watch, rise}} for every town of
## the owner (0 where none). One pass over the towns; run in the owner's
## scope, outside any one town's. `mc` is the owner's MilitaryCampaign.
## KEEPING WATCH IS THE MILITARY (watch_military.gd):
##  - The watch here is the HOME GUARD: the share of the watch the ruler
##    keeps at home (home_share), as many as stand at home today, spread
##    over home and the towns by their people, each in the town they live
##    in. They are the watch at home (home_army), counted once: those posted
##    in the other towns stand there, not in home's battle (posted_away).
##    Offensive troops at home stand at home; bands away defend nothing.
##  - The rise. Of the grown people (working age) not keeping watch or under
##    arms (personnel_ledger), RISE_SHARE take up arms, each in the town they
##    live in. No one rises twice, and no one both rises and keeps watch.
## Each is shared out by people among the towns that keep a guard (lived
## in, and not held by another people), home included, in whole people that
## add up exactly (largest remainder). Before any town is founded all of
## them are at home (home_militia).
static func guard_ledger(mc:Variant=null)->Dictionary:
	if mc==null:mc=WorldSimulation.military
	var out:={}
	if mc==null:return out
	var state=WorldSimulation.state
	var people:={}
	var total:=0.0
	for city:Dictionary in state.player_settlements:
		var id:=String(city.get("id",""))
		out[id]={"watch":0,"rise":0}
		if not keeps_watch(city):continue
		var here:=maxf(0.0,float(WorldSimulation.settlements._settlement_population(city)))
		if here<=0.0:continue
		people[id]=here;total+=here
	if total<=0.0:return out
	var counts:=_whole_people(mc)
	# The townsfolk of the towns that keep a guard only: those of a town held
	# or left empty do not rise for the rest.
	var rise:=roundi(float(counts.rise_exact)*minf(1.0,total/maxf(1.0,float(state.population_exact))))
	var watches:=_apportion(int(counts.watch),people,total,{})
	var rises:=_apportion(rise,people,total,watches)
	for id:String in people:out[id]={"watch":int(watches.get(id,0)),"rise":int(rises.get(id,0))}
	return out

## The people's whole home guard (standing at home today) and its
## townsfolk who would rise (unrounded), before they are shared out among
## the towns.
static func _whole_people(mc:Variant)->Dictionary:
	var state=WorldSimulation.state
	var Watch:=preload("res://scripts/watch_military.gd")
	# Grown people away from home (caravans, convoys, scouts, envoys, scholars
	# abroad) cannot rise, as they cannot enlist (recruitment_capacity). Read
	# first: reading them settles the people's counts, as enlisting does.
	var away:=_away(state)
	# Everyone keeping watch or under arms anywhere: the watch share, or more
	# while bands away stand above it. None of them rises.
	var serving:=maxi(Watch.manpower(mc),maxi(0,int(mc._mobilized_count())))
	var adults:=maxf(0.0,float(state.population_cohorts.get("working_age",float(state.population_exact)*0.60))-float(away)-float(serving))
	# Roads bring more of the countryside's people to the fight in time
	# (built_fabric.gd ROAD_RISE).
	return {"watch":Watch.home_guard(mc),"rise_exact":minf(adults,RISE_SHARE*adults*preload("res://scripts/built_fabric.gd").rise_factor())}

## Grown people of the people in scope who are away from their towns.
static func _away(state:Variant)->int:
	var away:=0
	var world:Variant=WorldSimulation.world
	# Read only from a world already made: player_population_commitments
	# first makes a world that is not (CivilizationSystem.initialize), and a
	# count of defenders must never remake the world it is read from.
	var made:bool=world!=null and world.has_method("player_population_commitments") and (WorldSimulation.actor_id!="player" or (not (world.civilizations as Array).is_empty() and int(state.world_seed)==int(world.last_world_seed)))
	if made:away+=int(world.player_population_commitments().get("working_absent",0))
	away+=int(preload("res://scripts/scholar_visits.gd").absent(state,int(state.elapsed_days)))
	# Hands of the god's people lent abroad on an envoy's business (a teacher,
	# healers, hunters on a drive: lent_hands.gd) are not home to rise.
	if WorldSimulation.actor_id=="player": away+=roundi(preload("res://scripts/lent_hands.gd").away(int(state.elapsed_days)))
	return maxi(0,away)

## `amount` whole people shared out by `people` (id -> count, summing to
## `total`), largest remainder first, never more in a town than live there
## beside `taken` (id -> already standing there).
static func _apportion(amount:int,people:Dictionary,total:float,taken:Dictionary)->Dictionary:
	var out:={}
	if amount<=0 or total<=0.0:return out
	var given:=0
	var rest:Array=[]
	for id:String in people:
		var room:=maxi(0,floori(float(people[id]))-int(taken.get(id,0)))
		var exact:=float(amount)*float(people[id])/total
		var whole:=mini(floori(exact),room)
		out[id]=whole;given+=whole
		rest.append([exact-float(whole),id,room])
	rest.sort_custom(func(a:Array,b:Array)->bool:return float(a[0])>float(b[0]) if float(a[0])!=float(b[0]) else String(a[1])<String(b[1]))
	var left:=amount-given
	for pair:Array in rest:
		if left<=0:break
		var id:=String(pair[1])
		if int(out[id])+1>int(pair[2]):continue
		out[id]=int(out[id])+1;left-=1
	return out

## {city_id: watch}: each town's share of the home guard alone (guard_ledger).
static func watch_ledger(mc:Variant=null)->Dictionary:
	var out:={}
	var ledger:=guard_ledger(mc)
	for id in ledger:out[id]=int((ledger[id] as Dictionary).get("watch",0))
	return out

## The drill of the home guard: the watch at home's, by its men
## (watch_military.gd drill_of); WATCH_TRAINING when nobody is at home.
static func guard_drill(mc:Variant=null)->float:
	if mc==null:mc=WorldSimulation.military
	if mc==null:return WATCH_TRAINING
	var formations:Array=mc.home_army.get("formations",[])
	if formations.is_empty():return WATCH_TRAINING
	return preload("res://scripts/watch_military.gd").drill_of(formations)

## What `men` of the home guard posted in a town carry: the kit most of the
## watch at home carries, and its share of the sets in hand there (the same
## share the fight at home leaves behind for them: MilitaryCampaign
## _take_posted_guard). {unit, weapon, equipment, equipment_required}.
static func guard_kit(mc:Variant,men:int)->Dictionary:
	var unit:="levy";var weapon:="improvised";var most:=-1
	for f in mc.home_army.get("formations",[]):
		if not f is Dictionary:continue
		var formation:Dictionary=f
		if int(formation.get("count",0))>most:most=int(formation.get("count",0));unit=String(formation.get("unit","levy"));weapon=String(formation.get("weapon","improvised"))
	var required:=int(mc._equipment_required_for(unit,men))
	var armed:=preload("res://scripts/watch_military.gd").armed_of(mc.home_army.get("formations",[]))
	return {"unit":unit,"weapon":weapon,"equipment":roundi(float(required)*armed),"equipment_required":required}

## The training of a block of `watch` of the home guard and `rise`
## townsfolk who stand together (`drill`: the guard's own).
static func militia_training(watch:int,rise:int,drill:float=WATCH_TRAINING)->float:
	if watch+rise<=0:return drill
	return (drill*float(watch)+RISE_TRAINING*float(rise))/float(watch+rise)

## Whether a town keeps a guard of ours: lived in (dry_towns.gd) and not held
## by another people (siege_recovery capture, a town taken).
static func keeps_watch(city:Dictionary)->bool:
	return not city.is_empty() and String(city.get("occupied_by","")).is_empty() and not WorldSimulation.settlements.abandoned(city)

## Home's own defenders beside its host: {watch (home's own share of the
## home guard; it stands in the host's formations), rise (its townsfolk who
## rise), count (the untrained block that stands with the host: the rise),
## training (the rise's)}.
static func home_militia(mc:Variant=null)->Dictionary:
	if mc==null:mc=WorldSimulation.military
	if mc==null:return {"watch":0,"rise":0,"count":0,"training":RISE_TRAINING}
	var home:=_home_record()
	var watch:=0;var rise:=0
	if home.is_empty():
		# No town founded yet: the whole people is at home.
		var counts:=_whole_people(mc)
		watch=int(counts.watch);rise=roundi(float(counts.rise_exact))
	else:
		var guard:Dictionary=guard_ledger(mc).get(String(home.get("id","")),{})
		watch=int(guard.get("watch",0));rise=int(guard.get("rise",0))
	return {"watch":watch,"rise":rise,"count":rise,"training":RISE_TRAINING}

## Home's own share of the home guard alone.
static func home_watch(mc:Variant=null)->int:
	return int(home_militia(mc).watch)

## The home guard posted in our towns other than home: they stand there,
## not in home's battle (MilitaryCampaign._home_defense_force).
static func posted_away(mc:Variant=null)->int:
	if mc==null:mc=WorldSimulation.military
	if mc==null:return 0
	var home:=_home_record()
	var out:=0
	var ledger:=guard_ledger(mc)
	for id in ledger:
		if not home.is_empty() and String(id)==String(home.get("id","")):continue
		out+=int((ledger[id] as Dictionary).get("watch",0))
	return out

static func _home_record()->Dictionary:
	for city:Dictionary in WorldSimulation.state.player_settlements:
		if bool(city.get("primary",false)):return city
	return {}

## A town's share of the home guard alone (guard_ledger). 0 for no town.
## Run in the town's owner's scope, outside any one town's.
static func watch_count(city_id:String)->int:
	return int((guard_ledger().get(city_id,{}) as Dictionary).get("watch",0))

## watch_count for a town's record already in hand.
static func watch_of(city:Dictionary)->int:
	return 0 if city.is_empty() else watch_count(String(city.get("id","")))

## Who stands at home when it is attacked, as _home_defense_force musters
## them: the offensive troops at home not in a band (trained), home's own
## share of the home guard (watch) and its townsfolk who rise. {trained,
## watch, rise}. Run in the owner's scope.
static func home_defenders()->Dictionary:
	var mc:Variant=WorldSimulation.military
	if mc==null:return {"trained":0,"watch":0,"rise":0}
	var militia:=home_militia(mc)
	return {"trained":_beyond_guard(mc),"watch":int(militia.watch),"rise":int(militia.rise)}

## Those at home beyond the home guard: the offensive troops at home.
static func _beyond_guard(mc:Variant)->int:
	return 0 if mc==null else int(preload("res://scripts/watch_military.gd").offensive_at_home(mc))

## Who would defend one of the owner's towns if it were attacked now, part
## by part: {trained, watch, rise} (trained, the offensive troops at home,
## only at home). A town another people holds has none; a home left empty
## keeps only those at home.
static func guard_of(city:Dictionary)->Dictionary:
	var out:={"trained":0,"watch":0,"rise":0}
	if city.is_empty() or not String(city.get("occupied_by","")).is_empty():return out
	if bool(city.get("primary",false)):out.trained=_trained()
	if not keeps_watch(city):return out
	var guard:Dictionary=guard_ledger().get(String(city.get("id","")),{})
	out.watch=int(guard.get("watch",0));out.rise=int(guard.get("rise",0))
	return out

static func _trained()->int:
	return _beyond_guard(WorldSimulation.military)

## How many of the owner's people defend one of its towns if it is attacked
## now, as force_for musters them: at home the offensive troops at home, its
## share of the home guard and its townsfolk who rise; anywhere else the
## town's share of the home guard and its townsfolk. 0 for a town another
## people holds (home included: siege_recovery capture) and for a place that
## is not the owner's. The count a town's page, badge and drawing show, and
## a scout's.
static func defenders(city_id:String)->int:
	return defenders_of(WorldSimulation.settlements.settlement_record(city_id))

## defenders for a town's record already in hand.
static func defenders_of(city:Dictionary)->int:
	if city.is_empty():return 0
	return int(defenders_by_town().get(String(city.get("id","")),0))

## Who would defend every town of the owner, part by part, by id, from one
## reading of the guard ledger: {city_id: {trained, watch, rise}}.
static func guards_by_town()->Dictionary:
	var mc:Variant=WorldSimulation.military
	var out:={}
	var ledger:=guard_ledger(mc)
	for city:Dictionary in WorldSimulation.state.player_settlements:
		var id:=String(city.get("id",""))
		var guard:Dictionary=ledger.get(id,{})
		var trained:=0
		if bool(city.get("primary",false)) and String(city.get("occupied_by","")).is_empty() and mc!=null:trained=_beyond_guard(mc)
		out[id]={"trained":trained,"watch":int(guard.get("watch",0)),"rise":int(guard.get("rise",0))}
	return out

## defenders for every town of the owner, by id (guards_by_town summed).
static func defenders_by_town()->Dictionary:
	var out:={}
	var guards:=guards_by_town()
	for id in guards:out[id]=int(guards[id].trained)+int(guards[id].watch)+int(guards[id].rise)
	return out

static func commit_enemy(result:Dictionary)->void:
	var target:Dictionary=result.get("threat",{}).get("owned_target",{})
	if target.is_empty():return
	var id:=String(target.actor)
	var mirrored:=result.duplicate(true)
	mirrored.home_side="defender" if String(result.get("home_side","attacker"))=="attacker" else "attacker"
	mirrored.home_force_id=int(target.field_id)
	mirrored.home_force_kind="field_army" if int(target.field_id)>0 else "field"
	# A town's own watch fought: its losses are that town's (not home's levy).
	var town_id:=String(target.get("city_id",""))
	if int(target.field_id)<=0 and town_id!="" and bool(WorldSimulation.scoped(id,func()->bool:return not WorldSimulation.settlements.settlement_record(town_id).is_empty() and not bool(WorldSimulation.settlements.settlement_record(town_id).get("primary",false)))):
		mirrored.home_force_kind="town"
		mirrored["home_force_city_id"]=town_id
	# Home's watch and townsfolk who stood with its levy go back to their
	# work after (MilitaryCampaign._dismiss_watch_militia).
	if String(mirrored.home_force_kind)=="field":mirrored["militia_id"]=MILITIA_ID
	# The home guard posted in its other towns stood there, not at home
	# (MilitaryCampaign._home_defense_force): back in its formations after.
	var mustered:Variant=(result.get("threat",{}) as Dictionary).get("enemy_force",{})
	if String(mirrored.home_force_kind)=="field" and mustered is Dictionary:mirrored["posted_guard"]=((mustered as Dictionary).get("posted_guard",{}) as Dictionary).duplicate(true)
	mirrored.command_participants=[]
	mirrored.commander_managed=id!="player"
	WorldSimulation.scoped(id,func()->void:WorldSimulation.military._commit_campaign_battle(mirrored))

## Views can be a day old while actors take their turns. Contact must read the
## current owner, including a line that just broke in another actor's battle.
static func refresh_formation(formation:Dictionary)->Dictionary:
	if not WorldSimulation.enabled or not formation.has("owned_force_id"):return formation
	var actor:=owner(String(formation.get("civ_id","")))
	if actor!="player" and not WorldSimulation.actors.has(actor):return formation
	return WorldSimulation.scoped(actor,func()->Dictionary:
		var view:=formation.duplicate(true)
		var index:int=WorldSimulation.military._field_army_index(int(formation.owned_force_id))
		if index<0:
			view["actual_troops"]=0;view["can_defend"]=false;view["defense_points"]=[]
			return view
		var force:Dictionary=WorldSimulation.military.field_armies[index]
		var point:Vector2=WorldSimulation.military.command_hierarchy.land.point(force)
		var front:=preload("res://scripts/army_front_contact.gd").snapshot(force)
		view.merge({"point_a":point,"point_b":point,"command_position":{"x":point.x,"z":point.y},"actual_troops":int(force.get("troops",0)),"readiness":float(force.get("readiness",0)),"morale":float(force.get("morale",1)),"provision_ratio":preload("res://scripts/supply_state.gd").fed(force),"disabled_until_day":int(force.get("command_recover_until",0)),"morale_cap":float(force.get("morale",1.0)),"border_front":front,"defense_points":front.points,
			"can_defend":preload("res://scripts/border_defense.gd").fit(force,int(WorldSimulation.state.elapsed_days))},true)
		return view
	)

static func troop_catalog()->Dictionary:
	var catalog:Dictionary={}
	var ids:Array=WorldSimulation.actors.keys();ids.append("player");ids.sort()
	for id:String in ids:
		var result:Array[Dictionary]=[]
		var visible_id:="human" if id=="player" else id
		WorldSimulation.scoped(id,func()->void:
			var day:=int(WorldSimulation.state.elapsed_days)
			for mission:Dictionary in WorldSimulation.world.scout_missions:
				var start:=int(mission.get("start_day",day));var finish:=int(mission.get("actual_return_day",mission.get("return_day",day+1)))
				var point:Vector2=WorldSimulation.world.city_intelligence.mission_position(mission,day)
				var scouting:Dictionary={"id":"%s:scout:%d" % [visible_id,int(mission.mission_id)],"civ_id":visible_id,"kind":"scout","point_a":WorldSimulation.world.player_world_origin,"point_b":point,"command_position":{"x":point.x,"z":point.y},"depart_day":start,"leg_days":maxf(1,float(finish-start)*.5),"strength_share":float(mission.personnel)/maxf(1,WorldSimulation.state.population_exact),"readiness":.5,"actual_troops":int(mission.personnel),"owned_mission":int(mission.mission_id),"route":mission.get("route",[]).duplicate(true),"concealment":.7,"evasion":.8,"last_report_cycle":0,"disabled_until_day":0,"evaded_until_day":int(mission.get("evaded_until_day",0)),"last_interception_day":int(mission.get("last_interception_day",-9999)),"search_sequence":0}
				result.append(scouting)
			for force in WorldSimulation.military.field_armies:
				if int(force.get("troops",0))<=0:continue
				var point:Vector2=WorldSimulation.military.command_hierarchy.land.point(force)
				result.append({"id":"%s:army:%d" % [visible_id,int(force.army_id)],"civ_id":visible_id,"kind":"expedition","point_a":point,"point_b":point,"command_position":{"x":point.x,"z":point.y},"depart_day":0,"leg_days":1.0,"strength_share":float(force.troops)/maxf(1,WorldSimulation.military._mobilized_count()),"readiness":float(force.get("readiness",0)),"actual_troops":int(force.troops),"owned_force_id":int(force.army_id)})
				result[-1]=refresh_formation(result[-1])
		)
		catalog[id]=result
	return catalog

static func troop_views(observer:String,catalog:Dictionary={})->Array[Dictionary]:
	var current:=troop_catalog() if catalog.is_empty() else catalog
	var result:Array[Dictionary]=[]
	for id:String in current:
		if id==observer:continue
		for entry:Dictionary in current[id]:result.append(entry.duplicate(true))
	return result

static func civilian_deaths(civ:Dictionary,region_id:String,requested:int)->Dictionary:
	var id:=owner(String(civ.id));var local_id:=""
	for region:Dictionary in civ.strategic_regions:
		if String(region.id)==region_id:local_id=String(region.get("local_city_id",""));break
	if local_id.is_empty():return {"civilization":civ,"dead":0}
	var count:int=WorldSimulation.scoped(id,func()->int:
		return WorldSimulation.settlements.with_city_resources(local_id,func()->int:
			return WorldSimulation.settlements.with_local_population(func()->int:return int(WorldSimulation.state.register_population_deaths(requested,"Civilian deaths in war").get("count",0)),true)
		)
	)
	return {"civilization":civ,"dead":count}

static func local_city(civ_id:String,region_id:String)->String:
	var region:=WorldSimulation.world.region_snapshot(civ_id,region_id)
	return String(region.get("local_city_id",region_id))
static func capture(civ:Dictionary,region_id:String,force:Dictionary)->Dictionary:
	var attacker:=WorldSimulation.actor_id
	var target:=owner(String(civ.id))
	var city_id:=local_city(String(civ.id),region_id)
	var occupying_id:="human" if attacker=="player" else attacker
	var result:Dictionary=WorldSimulation.scoped(target,func()->Dictionary:
		# Our home is lost only if our ruler yields it, never by a fight
		# (MilitaryCampaign._home_after_defeat); another people's ruler yields
		# theirs when the victors could hold it (capture_city).
		if target=="player" and bool(WorldSimulation.settlements.settlement_record(city_id).get("primary",false)):
			return {"error":"They broke through, but our home is still ours: it is lost only if its ruler yields it.","surrender_only":true}
		return WorldSimulation.military.recovery.capture_city(city_id,occupying_id,force)
	)
	var region:=WorldSimulation.world.region_snapshot(String(civ.id),region_id).duplicate(true)
	if result.has("error"):return {"civilization":civ,"outcome":{"region_captured":false,"message":result.error}}
	region.controller="player"
	_set_controller(civ,region_id,"player")
	return {"civilization":civ,"outcome":{"region_captured":true,"occupation_required":float(result.get("occupation_required",0)),"region":region,"territory_transferred":0.0,"message":result.get("message","The city is occupied.")}}
static func restore(civ:Dictionary,region_id:String)->Dictionary:
	var city_id:=local_city(String(civ.id),region_id)
	WorldSimulation.scoped(owner(String(civ.id)),func()->void:
		var city:=WorldSimulation.settlements.settlement_record(city_id)
		city.occupied_by=""
		for entry:Dictionary in WorldSimulation.military.recovery.data.occupied:
			if String(entry.city_id)==city_id:entry.liberated=true
	)
	var region:=WorldSimulation.world.region_snapshot(String(civ.id),region_id).duplicate(true);region.controller=civ.id
	_set_controller(civ,region_id,String(civ.id))
	return {"civilization":civ,"outcome":{"region_recaptured":true,"region":region,"territory_transferred":0.0,"message":"The city is free of occupation."}}
## The world's own record of who holds the town changes the moment it falls,
## as the projection will say at the next day's sync: the field report that
## follows the battle, the map and the court must not see the old holder.
static func _set_controller(civ:Dictionary,region_id:String,controller:String)->void:
	for region:Dictionary in civ.get("strategic_regions",[]):
		if String(region.get("id",""))!=region_id:continue
		region["controller"]=controller
		region["last_control_change_day"]=int(WorldSimulation.state.elapsed_days)
		return
static func same_force(a:Dictionary,b:Dictionary)->bool:
	if a.is_empty() or b.is_empty():return false
	if String(a.get("actor",""))!=String(b.get("actor","")) or int(a.get("field_id",0))!=int(b.get("field_id",0)):return false
	return int(a.get("field_id",0))>0 or String(a.get("city_id","")).is_empty() or String(b.get("city_id","")).is_empty() or a.city_id==b.city_id
static func reserved(target:Dictionary,include_sieges:bool=true)->bool:
	if target.is_empty():return false
	var ids:Array=WorldSimulation.actors.keys();ids.append("player")
	for id:String in ids:
		# Read each owner's campaign directly; entering its scope only to select
		# this instance cost two full scope rebinds per owner per query.
		var military:Node=MilitaryCampaign if id=="player" else WorldSimulation.actors[id].systems.MilitaryCampaign
		var operations:Array=military.engagements.values()
		if include_sieges and not military.active_siege.is_empty():operations.append(military.active_siege)
		for operation:Dictionary in operations:
			if same_force(operation.get("threat",{}).get("owned_target",{}),target):return true
			if same_force({"actor":id,"field_id":int(operation.get("home_force_id",operation.get("army_id",0)))},target):return true
			for member:Dictionary in operation.get("command_participants",[]):
				if same_force({"actor":id,"field_id":int(member.army_id)},target):return true
	return false
static func damage_city(civ_id:String,region_id:String,amount:float)->void:
	var target:=WorldSimulation.actor_id if civ_id=="player" else owner(civ_id)
	var city_id:=region_id if civ_id=="player" else local_city(civ_id,region_id)
	WorldSimulation.scoped(target,func()->void:
		WorldSimulation.settlements.with_city_resources(city_id,func()->void:
			for plot:Dictionary in WorldSimulation.state.settlement_plots:
				if String(plot.get("land_use","")) in ["workshop","mixed_household","storehouse"]:plot.condition=maxf(.05,float(plot.get("condition",1))-amount)
			WorldSimulation.state.morphology_revision+=1
			WorldSimulation.settlements.damage_city_form(amount)
			WorldSimulation.settlements.rebuild_summary()
		)
		for base:Dictionary in WorldSimulation.military.joint_operations.state.bases:
			if String(base.city_id)==city_id:base.condition=maxf(0,float(base.condition)-amount)
	)

static func intercept_scout(formation:Dictionary,action:String,success:bool,day:int)->void:
	var captor:=WorldSimulation.actor_id
	WorldSimulation.scoped(owner(String(formation.civ_id)),func()->void:
		for mission:Dictionary in WorldSimulation.world.scout_missions:
			if int(mission.mission_id)!=int(formation.owned_mission):continue
			mission.last_interception_day=day
			if not success:mission.evaded_until_day=day+7;return
			WorldSimulation.world._fail_player_scout_mission(mission,{"civ_id":"human" if captor=="player" else captor,"fate":"captured" if action=="capture" else "destroyed"},day)
			return
	)
static func governance(civ_id:String,region_id:String,region:Dictionary)->void:
	var city_id:=local_city(civ_id,region_id)
	WorldSimulation.scoped(owner(civ_id),func()->void:
		for entry:Dictionary in WorldSimulation.military.recovery.data.occupied:
			if String(entry.city_id)==city_id:
				for key in ["governance","damage","resistance","integration"]:
					if region.has(key):entry.region[key]=region[key]
	)

static func displace(civ_id:String,city_id:String,requested:int)->int:
	var owner_id:=WorldSimulation.actor_id if civ_id=="player" else owner(civ_id)
	return WorldSimulation.scoped(owner_id,func()->int:
		var source:=WorldSimulation.settlements.settlement_record(city_id)
		if source.is_empty():return 0
		var destinations:Array=[]
		for city:Dictionary in WorldSimulation.state.player_settlements:
			# Never into a place its people left (settlement_model.abandoned).
			if String(city.id)!=city_id and String(city.get("occupied_by","")).is_empty() and String(city.get("status",""))!="abandoned":destinations.append(city)
		if destinations.is_empty():return 0
		var amount:=mini(maxi(0,requested),floori(WorldSimulation.settlements._settlement_population(source)*.35))
		var share:=float(amount)/maxf(1,WorldSimulation.state.population_exact)
		if not bool(source.get("primary",false)):source.population_share=maxf(0,float(source.population_share)-share)
		for city:Dictionary in destinations:
			if not bool(city.get("primary",false)):city.population_share=float(city.population_share)+share/destinations.size()
		WorldSimulation.state.simulation_metrics["displaced_population"]=float(WorldSimulation.state.simulation_metrics.get("displaced_population",0))+amount
		WorldSimulation.state.settlement_network_revision+=1
		return amount
	)

static func occupation_presence(occupier:String,city_id:String)->Dictionary:
	var resident:=WorldSimulation.actor_id
	return WorldSimulation.scoped(owner(occupier),func()->Dictionary:
		for force:Dictionary in WorldSimulation.military.occupation_forces:
			if owner(String(force.get("civ_id","")))!=resident:continue
			var region:=WorldSimulation.world.region_snapshot(String(force.civ_id),String(force.region_id))
			if String(region.get("local_city_id",""))!=city_id:continue
			# The one rule for holding a town (town_hold.gd).
			var Hold:=preload("res://scripts/town_hold.gd")
			var effective:=Hold.force_strength(force)
			return {"control":clampf(effective/maxf(1,float(force.get("required",1))),0,1),"logistics":Hold.fed(force)}
		return {"control":0.0,"logistics":0.0}
	)
