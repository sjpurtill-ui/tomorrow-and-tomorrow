extends RefCounted
## Keeping armies in the field (docs/MILITARY_SYSTEM_V2.md §3, critic rounds 1-2).
##
## Three things reach a band away from home along its supply line, or fail to:
##  - Food. A band hungry for three days or more loses men every day it stays
##    short: some fall sick (they rejoin when fed), some go home (they rejoin
##    the workforce), some die. At no food at all about one man in ninety a
##    day, a quarter of the band in a month; typical shortfalls cost a few in
##    a hundred a month. Not while a band is in battle (the battle holds its
##    men) nor at the home settlement (fed by hand). The war leader states it.
##  - Stores: fodder, fuel, rounds and spares, the loads each kit asks of the
##    line besides bread (equipment_ledger.gd supply). Horses can graze; fuel
##    cannot. Short stores weaken the kits that live on them.
##  - Replacements and gear. Open places are filled by drafts: people set
##    aside for defence (the Defense share of work) or already called up,
##    trained at the Reinforce pace (0.58 of full training), who walk out and
##    join. Only a band its supply line reaches, and that is not starving, is
##    drafted for. Gear goes with a draft only for the band's real gap; the
##    rest travels by the day's deliveries (military_campaign).
## Every count here moves between the same ledgers the rest of the game reads:
## formation counts, the wounded pool (hunger-sick kept apart from battle
## wounded), the drafts on the road (the "replacements" personnel category),
## inventories and population deaths.

const Ledger:=preload("res://scripts/equipment_ledger.gd")
const Rations:=preload("res://scripts/field_rations.gd")
const Supply:=preload("res://scripts/supply_state.gd")

## Men lost a day at no food at all (scaled by how short the band is).
const HUNGER_RATE:=0.011
const SICK_SHARE:=0.45
const DESERT_SHARE:=0.35
## Share of the hunger-sick who rejoin their formations each fed day.
const RECOVER_PER_DAY:=0.04
## Drafts train at the Reinforce pace.
const DRAFT_TRAINING:=0.58
## A formation is drafted for once its open places reach this many, or this
## share of its size: no daily dribble of one-man orders.
const DRAFT_MIN_MEN:=3
const DRAFT_MIN_SHARE:=0.02
## A band the carriers cannot reach at all is cut off.
const CUT_OFF:=0.01
## Hunger losses the war leader still speaks of, in days since the last.
const HUNGER_MEMORY_DAYS:=30
## Kits whose stores are mostly fodder: horses, oxen and elephants graze.
const FODDER_KITS:=["mounted_bow","field_gun","horse_gun","bombard"]

var host

func _init(owner)->void:
	host=owner

# --- Stores ------------------------------------------------------------------

static func is_fodder(weapon:String)->bool:
	return Ledger.family(weapon)=="mount" or weapon in FODDER_KITS

## Loads a day the band asks besides bread, and the share of them that is
## fodder (which horses can graze).
static func stores_demand(force:Dictionary)->Dictionary:
	var total:=0.0
	var fodder:=0.0
	for formation in force.get("formations",[]):
		var weapon:=String(formation.get("weapon","improvised"))
		var sets:=float(maxi(0,int(formation.get("equipment",0))))
		var loads:=sets*Ledger.supply(weapon)
		total+=loads
		if is_fodder(weapon): fodder+=loads
	return {"loads":total,"fodder":fodder}

## Share of the band's stores that arrives today: what the carriers bring, and
## for fodder what the country grazes. 1.0 when the band asks for none.
static func stores_share(force:Dictionary,carried:float,graze:float)->float:
	var demand:=stores_demand(force)
	var loads:=float(demand.loads)
	if loads<=0.0: return 1.0
	var fodder:=float(demand.fodder)
	var arrived:=loads*clampf(carried,0.0,1.0)+fodder*(1.0-clampf(carried,0.0,1.0))*clampf(graze,0.0,1.0)
	return clampf(arrived/loads,0.0,1.0)

# --- Hunger ------------------------------------------------------------------

## True while the band's men belong to a battle or stand at home.
func _held(force:Dictionary)->bool:
	if force.has("army_id") and host.command_hierarchy.battle.engaged(int(force.get("army_id",0))): return true
	return force.has("army_id") and host.at_home_point(force)

## A day's hunger losses on a band or garrison already marked for the day.
## Moves men out of its formations into the sick pool, home, or the grave.
func hunger_day(force:Dictionary,span:float)->Dictionary:
	var result:={"sick":0,"deserted":0,"dead":0}
	force["hunger_today"]=result.duplicate()
	var food:=clampf(float(force.get("provision_ratio",1.0)),0.0,1.0)
	var troops:=maxi(0,int(force.get("troops",0)))
	if not Rations.is_hungry(force) or food>=Rations.HUNGRY_BELOW or troops<=0 or _held(force):
		force["hunger_accumulator"]=0.0
		return result
	var rate:=HUNGER_RATE*(Rations.HUNGRY_BELOW-food)/Rations.HUNGRY_BELOW
	var owed:=float(force.get("hunger_accumulator",0.0))+float(troops)*rate*span
	var lost:=mini(troops,floori(owed))
	force["hunger_accumulator"]=owed-float(lost)
	if lost<=0: return result
	var removed:=_take_men(force,lost)
	result.sick=roundi(float(removed)*SICK_SHARE)
	result.deserted=roundi(float(removed)*DESERT_SHARE)
	result.dead=maxi(0,removed-result.sick-result.deserted)
	force["wounded_pool"]=int(force.get("wounded_pool",0))+int(result.sick)
	force["hunger_sick"]=int(force.get("hunger_sick",0))+int(result.sick)
	if int(result.dead)>0: WorldSimulation.state.register_population_deaths(int(result.dead),"Died of hunger in the field")
	# Deserters simply stop being soldiers: the mobilized count falls and they
	# are working hands at home again (military_campaign._mobilized_count).
	var totals:Dictionary=force.get("hunger_losses",{"sick":0,"deserted":0,"dead":0})
	for key in result: totals[key]=int(totals.get(key,0))+int(result[key])
	force["hunger_losses"]=totals
	force["hunger_last_day"]=int(WorldSimulation.state.elapsed_days)
	force["hunger_today"]=result.duplicate()
	return result

## Hunger's losses the war leader still speaks of: {} once a month has passed
## without any.
static func recent_hunger_losses(force:Dictionary,today:int)->Dictionary:
	if not force.get("hunger_losses") is Dictionary: return {}
	if today-int(force.get("hunger_last_day",-100000))>HUNGER_MEMORY_DAYS: return {}
	return (force.hunger_losses as Dictionary).duplicate()

## The hunger-sick rejoin their formations while the band is fed (battle
## wounded heal by the medical rules, not here).
func recovery_day(force:Dictionary,span:float)->int:
	var sick:=mini(maxi(0,int(force.get("hunger_sick",0))),maxi(0,int(force.get("wounded_pool",0))-maxi(0,int(force.get("disabled_pool",0)))))
	if sick<=0 or float(force.get("provision_ratio",1.0))<Rations.HUNGRY_BELOW or _held(force) and not host.at_home_point(force): return 0
	var owed:=float(force.get("recovery_accumulator",0.0))+float(sick)*RECOVER_PER_DAY*span
	var back:=mini(sick,floori(owed))
	force["recovery_accumulator"]=owed-float(back)
	if back<=0: return 0
	var placed:=_return_men(force,back)
	force["wounded_pool"]=int(force.get("wounded_pool",0))-placed
	force["hunger_sick"]=int(force.get("hunger_sick",0))-placed
	return placed

# --- Rest: will to fight and battle wounded -----------------------------------

## Morale regained a day at rest in full supply (camped; a third of it on the
## march). A band recovers toward a ceiling its supply sets: a fed band to
## full heart, a half-supplied one only part way. A hungry band loses heart.
const MORALE_REST:=0.03
const MORALE_MARCHING:=0.33
const MORALE_HUNGER_LOSS:=0.008
const MORALE_HUNGER_FLOOR:=0.30
## Battle wounded who rejoin a day in full supply (twice with a medical
## detachment in the band); the disabled stay in the pool until home.
const WOUNDED_RETURN:=0.015

## A day's rest for a band or garrison: heart regained or lost, and battle
## wounded back in their places. Nothing while it fights.
func rest_day(force:Dictionary,span:float)->Dictionary:
	var result:={"morale":0.0,"wounded_back":0}
	if force.has("army_id") and host.command_hierarchy.battle.engaged(int(force.get("army_id",0))): return result
	var supply:=clampf(float(force.get("supply_level",1.0)),0.0,1.0)
	var morale:=float(force.get("morale",1.0))
	var before:=morale
	if Rations.is_hungry(force):
		morale=maxf(minf(morale,MORALE_HUNGER_FLOOR),morale-MORALE_HUNGER_LOSS*span)
	else:
		var pace:=MORALE_REST*(MORALE_MARCHING if String(force.get("status","stationed"))=="moving" else 1.0)
		var logistics:=clampf(float((force.get("commander",{}) as Dictionary).get("logistics",0.5)) if force.get("commander") is Dictionary else 0.5,0.0,1.0)
		var ceiling:=0.55+0.45*supply
		if morale<ceiling: morale=minf(ceiling,morale+pace*(0.35+0.65*supply)*(0.9+0.2*logistics)*span)
	force["morale"]=morale
	result.morale=morale-before
	# Battle wounded (not the hunger-sick, not the disabled) heal in camp.
	var wounded:=maxi(0,int(force.get("wounded_pool",0))-maxi(0,int(force.get("hunger_sick",0)))-maxi(0,int(force.get("disabled_pool",0))))
	if wounded>0 and supply>=0.5 and not Rations.is_hungry(force):
		var care:=2.0 if _has_medics(force) else 1.0
		var owed:=float(force.get("wounded_accumulator",0.0))+float(wounded)*WOUNDED_RETURN*care*supply*span
		var back:=mini(wounded,floori(owed))
		force["wounded_accumulator"]=owed-float(back)
		if back>0:
			var placed:=_return_men(force,back)
			force["wounded_pool"]=int(force.get("wounded_pool",0))-placed
			result.wounded_back=placed
	return result

static func _has_medics(force:Dictionary)->bool:
	for formation in force.get("formations",[]):
		if String(formation.get("unit",""))=="medical_detachment" and int(formation.get("count",0))>0: return true
	return false

## Men out of the formations, in proportion to their counts. Returns the
## number removed; the formations' gear stays with the band.
func _take_men(force:Dictionary,count:int)->int:
	var formations:Array=force.get("formations",[])
	var total:=0
	for formation in formations: total+=maxi(0,int(formation.get("count",0)))
	if total<=0: return 0
	var want:=mini(count,total)
	var left:=want
	for index in formations.size():
		if left<=0: break
		var formation:Dictionary=formations[index]
		var have:=maxi(0,int(formation.get("count",0)))
		var take:=mini(have,mini(left,ceili(float(want)*float(have)/float(total))))
		formation["count"]=have-take
		formations[index]=formation
		left-=take
	force["formations"]=formations
	_rebuild(force)
	return want-left

## The band's formations with open places, largest gap first: the one order
## both the sick and the drafts fill them in.
static func gap_order(formations:Array)->Array:
	var order:=range(formations.size())
	order.sort_custom(func(a,b): return _gap(formations[a])>_gap(formations[b]) or (_gap(formations[a])==_gap(formations[b]) and a<b))
	return order

## Men back into formations with open places, largest gap first.
func _return_men(force:Dictionary,count:int)->int:
	var formations:Array=force.get("formations",[])
	var left:=count
	for index in gap_order(formations):
		if left<=0: break
		var formation:Dictionary=formations[index]
		var room:=_gap(formation)
		if room<=0: continue
		var put:=mini(room,left)
		formation["count"]=int(formation.get("count",0))+put
		formations[index]=formation
		left-=put
	force["formations"]=formations
	_rebuild(force)
	return count-left

static func _gap(formation:Dictionary)->int:
	return maxi(0,int(formation.get("authorized_count",formation.get("count",0)))-int(formation.get("count",0)))

func _rebuild(force:Dictionary)->void:
	var rebuilt:Dictionary=host.simulator.create_formation_force(String(force.get("name","Army")),force.get("formations",[]),float(force.get("morale",1.0)),float(force.get("readiness",1.0)))
	for key:String in ["troops","attack","defense","armor","penetration","formations"]: force[key]=rebuilt[key]

# --- Drafts ------------------------------------------------------------------

## Men already on their way to each formation of a band: in training or on
## the road ({formation id: {men, sets}}).
func _covered(army_id:int)->Dictionary:
	var covered:={}
	for order:Dictionary in host.training_queue:
		if String(order.get("mode",""))!="field_draft" or int(order.get("field_army_id",0))!=army_id: continue
		var id:=int(order.get("target_formation_id",-1))
		var entry:Dictionary=covered.get(id,{"men":0,"sets":0})
		entry.men=int(entry.men)+int(order.get("count",0))
		covered[id]=entry
	for draft:Dictionary in host.field_drafts:
		if int(draft.get("army_id",0))!=army_id: continue
		var id:=int(draft.get("formation_id",-1))
		var entry:Dictionary=covered.get(id,{"men":0,"sets":0})
		entry.men=int(entry.men)+int(draft.get("count",0))
		entry.sets=int(entry.sets)+int(draft.get("equipment",0))
		covered[id]=entry
	return covered

## Open places in a band not covered by the hunger-sick (who come back when
## fed) nor by drafts in training or on the road, largest gap first.
func open_places(force:Dictionary)->Dictionary:
	var covered:=_covered(int(force.get("army_id",0)))
	var sick:=maxi(0,int(force.get("hunger_sick",0)))
	var formations:Array=force.get("formations",[])
	var places:={}
	for index in gap_order(formations):
		var formation:Dictionary=formations[index]
		var id:=int(formation.get("id",-1))
		var open:=_gap(formation)-int((covered.get(id,{}) as Dictionary).get("men",0))
		var healed:=mini(maxi(0,open),sick)
		sick-=healed
		open-=healed
		if open>0: places[id]={"unit":String(formation.get("unit","levy")),"weapon":String(formation.get("weapon","improvised")),"count":open,"size":int(formation.get("authorized_count",formation.get("count",0)))}
	return places

## Why a band gets no drafts today, or "" when it may.
func draft_block(force:Dictionary)->String:
	if String(force.get("priority","normal"))=="last": return "last"
	if bool(force.get("general_managed",false)) and WorldSimulation.campaign!=null and WorldSimulation.campaign.active: return "campaign"
	if Rations.is_hungry(force): return "hungry"
	if not host.at_home_point(force) and float(host._force_provision_access(force))<=CUT_OFF: return "cut_off"
	return ""

## People a draft may take today: those already called up, then free adults
## only while the mobilized stay within the Defense share of work.
func draftable()->int:
	var free_adults:int=maxi(0,host.recruitment_capacity()-host._mobilized_count())
	var defence_room:int=maxi(0,host._home_garrison_target()-host._mobilized_count())
	return maxi(0,host.aggregate_recruits)+mini(free_adults,defence_room)

## Call up and start training drafts for every band's open places, First
## priority bands first. Returns what was started or added.
func draft_day()->Array:
	var started:=[]
	if host.recovery.home_unavailable(): return started
	var free:=draftable()
	var bands:Array=host.field_armies.duplicate()
	bands.sort_custom(func(a,b): return priority_rank(a)<priority_rank(b))
	for force:Dictionary in bands:
		force["draft_block"]=draft_block(force)
		if String(force.draft_block)!="": continue
		if free<=0:
			force["draft_block"]="no_people"
			continue
		var places:=open_places(force)
		for formation_id in places:
			var place:Dictionary=places[formation_id]
			var need:=int(place.count)
			if need<maxi(DRAFT_MIN_MEN,ceili(float(place.size)*DRAFT_MIN_SHARE)): continue
			var count:=mini(need,free)
			if count<=0: break
			if count>host.aggregate_recruits: host.raise_recruits(count-host.aggregate_recruits)
			count=mini(count,host.aggregate_recruits)
			if count<=0: break
			var order:=_open_order(int(force.get("army_id",0)),int(formation_id))
			if not order.is_empty():
				# More men join the course already under way.
				var old:=int(order.count)
				order.progress_days=float(order.progress_days)*old/maxi(1,old+count)
				order.count=old+count;order.initial_count=int(order.get("initial_count",old))+count
				host.aggregate_recruits-=count
			else:
				var result:Dictionary=host.start_training(String(place.unit),String(place.weapon),count)
				if result.has("error"): continue
				order=host.training_queue[-1]
				order["mode"]="field_draft"
				order["field_army_id"]=int(force.get("army_id",0))
				order["target_formation_id"]=int(formation_id)
				order["required_days"]=maxf(3.0,float(order.get("required_days",30.0))*DRAFT_TRAINING)
			free-=count
			force["drafted_today"]=int(force.get("drafted_today",0))+count
			started.append({"army_id":int(force.get("army_id",0)),"formation_id":int(formation_id),"count":count})
	for index in host.field_armies.size():
		var live:Dictionary=host.field_armies[index]
		for band:Dictionary in bands:
			if int(band.get("army_id",-1))==int(live.get("army_id",-2)): live["draft_block"]=String(band.get("draft_block",""))
	return started

func _open_order(army_id:int,formation_id:int)->Dictionary:
	for order:Dictionary in host.training_queue:
		if String(order.get("mode",""))=="field_draft" and int(order.get("field_army_id",0))==army_id and int(order.get("target_formation_id",-1))==formation_id and float(order.get("progress_days",0.0))<float(order.get("required_days",1.0)):
			return order
	return {}

static func priority_rank(force:Dictionary)->int:
	return {"first":0,"normal":1,"last":2}.get(String(force.get("priority","normal")),1)

## A trained draft leaves for its band, taking gear only for the band's real
## gap. A draft whose band is gone joins the army at home as trained men.
func dispatch(order:Dictionary)->Dictionary:
	var count:=maxi(0,int(order.get("count",0)))
	var weapon:=String(order.get("weapon","improvised"))
	var unit:=String(order.get("unit","levy"))
	var army_id:=int(order.get("field_army_id",0))
	var force:=_army(army_id)
	var formation:=_formation(force,int(order.get("target_formation_id",-1)))
	if force.is_empty() or formation.is_empty():
		order["mode"]="new"
		order.erase("field_army_id");order.erase("target_formation_id")
		host._complete_training(order)
		return {"home":true,"count":count}
	var required:=int(formation.get("equipment_required",host.simulator.equipment_required_for_weapon(weapon,int(formation.get("authorized_count",0)))))
	var on_road:=int((_covered(army_id).get(int(formation.id),{}) as Dictionary).get("sets",0))
	var gap:=maxi(0,required-int(formation.get("equipment",0))-on_road)
	var wanted:=mini(gap,host.simulator.equipment_required_for_weapon(weapon,count))
	var reserved:=maxi(0,int(order.get("reserved_equipment",0)))
	var issued:=mini(wanted,reserved+maxi(0,int(host.military_inventory.get(weapon,0))))
	host.military_inventory[weapon]=int(host.military_inventory.get(weapon,0))+reserved-issued
	var access:=clampf(float(order.get("equipment_access_sum",0.0))/maxf(0.01,float(order.get("instruction_progress_sum",order.get("required_days",1.0)))),0.0,1.0)
	var skill:float=host._training_quality(unit,0.0)*(0.72+access*0.28)
	var days:=travel_days(force)
	var today:=int(WorldSimulation.state.elapsed_days)
	var draft:={"army_id":army_id,"formation_id":int(formation.id),"unit":unit,"weapon":weapon,"count":count,"equipment":issued,"training":skill,"left_day":today,"arrive_day":today+(days if days>0 else 1),"waiting":days<=0}
	host.field_drafts.append(draft)
	return draft

## Days a draft walks to its band: the supply line's haul days, at least one;
## 0 when no road reaches the band (the draft waits at home).
func travel_days(force:Dictionary)->int:
	if force.is_empty() or host.at_home_point(force): return 1
	var days:=float(Supply.of_force(force).get("days",1.0))
	if not is_finite(days) or float(host._force_provision_access(force))<=CUT_OFF: return 0
	return maxi(1,ceili(days))

## Drafts that have arrived join their formations, up to the open places;
## any beyond them come home to the recruits, with gear beyond the band's
## need back in store. A band in battle or cut off takes them later; a draft
## whose band is gone comes home.
func arrivals_day()->Array:
	var joined:=[]
	var today:=int(WorldSimulation.state.elapsed_days)
	for index in range(host.field_drafts.size()-1,-1,-1):
		var draft:Dictionary=host.field_drafts[index]
		if int(draft.get("arrive_day",0))>today: continue
		var army_index:int=host._field_army_index(int(draft.army_id))
		if army_index>=0:
			var band:Dictionary=host.field_armies[army_index]
			var blocked:bool=host.command_hierarchy.battle.engaged(int(draft.army_id))
			if bool(draft.get("waiting",false)):
				var days:=travel_days(band)
				if days>0:
					draft["waiting"]=false;draft["arrive_day"]=today+days
				else:
					draft["arrive_day"]=today+1
				continue
			if blocked:
				draft["arrive_day"]=today+1
				continue
		host.field_drafts.remove_at(index)
		if army_index<0:
			_send_home(draft)
			continue
		var force:Dictionary=host.field_armies[army_index]
		var formations:Array=force.get("formations",[])
		var placed:=false
		for f_index in formations.size():
			var formation:Dictionary=formations[f_index]
			if int(formation.get("id",-1))!=int(draft.formation_id): continue
			var old:=maxi(0,int(formation.get("count",0)))
			var men:=mini(int(draft.count),_gap(formation))
			var required:=int(formation.get("equipment_required",int(formation.get("equipment",0))))
			var sets:=mini(int(draft.equipment),maxi(0,required-int(formation.get("equipment",0))))
			formation["count"]=old+men
			formation["equipment"]=int(formation.get("equipment",0))+sets
			if men>0:
				formation["training"]=(float(formation.get("training",0.5))*old+float(draft.training)*men)/maxf(1.0,float(old+men))
				formation["experience"]=float(formation.get("experience",0.0))*old/maxf(1.0,float(old+men))
			formations[f_index]=formation
			if int(draft.count)>men or int(draft.equipment)>sets:
				_send_home({"count":int(draft.count)-men,"weapon":draft.weapon,"equipment":int(draft.equipment)-sets})
			placed=true
			force["formations"]=formations
			_rebuild(force)
			force["drafts_joined"]=int(force.get("drafts_joined",0))+men
			host.field_armies[army_index]=force
			joined.append(draft)
			break
		if not placed: _send_home(draft)
	return joined

func _send_home(draft:Dictionary)->void:
	host.aggregate_recruits+=maxi(0,int(draft.get("count",0)))
	var weapon:=String(draft.get("weapon","improvised"))
	host.military_inventory[weapon]=int(host.military_inventory.get(weapon,0))+maxi(0,int(draft.get("equipment",0)))

func _army(army_id:int)->Dictionary:
	var index:int=host._field_army_index(army_id)
	return host.field_armies[index] if index>=0 else {}

static func _formation(force:Dictionary,formation_id:int)->Dictionary:
	for formation in force.get("formations",[]):
		if int(formation.get("id",-1))==formation_id: return formation
	return {}

## People in drafts on the road (the "replacements" personnel category).
func drafts_on_road()->int:
	var total:=0
	for draft:Dictionary in host.field_drafts: total+=maxi(0,int(draft.get("count",0)))
	return total

func drafts_for(army_id:int)->Dictionary:
	var men:=0
	var first:=-1
	for draft:Dictionary in host.field_drafts:
		if int(draft.get("army_id",0))!=army_id: continue
		men+=int(draft.get("count",0))
		first=int(draft.arrive_day) if first<0 else mini(first,int(draft.arrive_day))
	var training:=0
	for order:Dictionary in host.training_queue:
		if String(order.get("mode",""))=="field_draft" and int(order.get("field_army_id",0))==army_id: training+=int(order.get("count",0))
	var index:int=host._field_army_index(army_id)
	var block:=String((host.field_armies[index] as Dictionary).get("draft_block","")) if index>=0 else ""
	return {"on_road":men,"in_training":training,"next_arrival_day":first,"block":block}

## Saved drafts, keeping only well-formed records (a bad one is dropped, not
## the list).
static func clean_drafts(drafts:Variant)->Array:
	var out:=[]
	if not drafts is Array: return out
	for draft in drafts:
		if not draft is Dictionary: continue
		var d:Dictionary=draft
		var ok:=true
		for key in ["army_id","formation_id","count","equipment","arrive_day"]:
			if not d.has(key) or not (d[key] is int or d[key] is float) or int(d[key])<(0 if key!="formation_id" else -1): ok=false
		if not ok or int(d.count)<=0 or String(d.get("weapon",""))=="" or String(d.get("unit",""))=="": continue
		var clean:=d.duplicate(true)
		clean["training"]=clampf(float(d.get("training",0.4)),0.0,1.25)
		out.append(clean)
	return out

static func valid_drafts(drafts:Variant)->bool:
	return drafts is Array and clean_drafts(drafts).size()==(drafts as Array).size()
