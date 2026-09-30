extends RefCounted
## Keeping armies in the field (docs/MILITARY_SYSTEM_V2.md §3, critic round 1).
##
## Three things reach a band away from home along its supply line, or fail to:
##  - Food. A band hungry for three days or more loses men every day it stays
##    short: some fall sick (they rejoin when fed), some go home (they rejoin
##    the workforce), some die. At no food at all about one man in ninety a
##    day, a quarter of the band in a month; typical shortfalls cost a few in
##    a hundred a month. The war leader states the numbers.
##  - Stores: fodder, fuel, rounds and spares, the loads each kit asks of the
##    line besides bread (equipment_ledger.gd supply). Horses can graze; fuel
##    cannot. Short stores weaken mounts, guns and machines and slow motors.
##  - Replacements and gear. Losses are replaced by drafts: people called up
##    at home, trained at the Reinforce pace (0.58 of full training), who
##    then walk out to the band and join it on arrival. Gear and rounds from
##    the stores the Production screen shows reach bands in supply, as fast
##    as the day's delivery load and the band's line allow.
## Every count here moves between the same ledgers the rest of the game reads:
## formation counts, wounded pools, the drafts on the road (counted as field
## personnel), inventories and population deaths.

const Ledger:=preload("res://scripts/equipment_ledger.gd")
const Rations:=preload("res://scripts/field_rations.gd")
const Supply:=preload("res://scripts/supply_state.gd")

## Men lost a day at no food at all (scaled by how short the band is).
const HUNGER_RATE:=0.011
const SICK_SHARE:=0.45
const DESERT_SHARE:=0.35
## Share of the sick who rejoin their formations each fed day.
const RECOVER_PER_DAY:=0.04
## Drafts train at the Reinforce pace.
const DRAFT_TRAINING:=0.58
## How short stores weaken the kits that need them: combat_simulator.stores_factor.

var host

func _init(owner)->void:
	host=owner

# --- Stores ------------------------------------------------------------------

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
		if Ledger.family(weapon)=="mount" or weapon in ["field_gun","horse_gun","bombard"]: fodder+=loads
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

## A day's hunger losses on a band or garrison already marked for the day.
## Moves men out of its formations into the sick pool, home, or the grave.
func hunger_day(force:Dictionary,span:float)->Dictionary:
	var result:={"sick":0,"deserted":0,"dead":0}
	var food:=clampf(float(force.get("provision_ratio",1.0)),0.0,1.0)
	var troops:=maxi(0,int(force.get("troops",0)))
	if not Rations.is_hungry(force) or food>=Rations.HUNGRY_BELOW or troops<=0:
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
	if int(result.dead)>0: WorldSimulation.state.register_population_deaths(int(result.dead),"Died of hunger in the field")
	# Deserters simply stop being soldiers: the mobilized count falls and they
	# are working hands at home again (military_campaign._mobilized_count).
	var totals:Dictionary=force.get("hunger_losses",{"sick":0,"deserted":0,"dead":0})
	for key in result: totals[key]=int(totals.get(key,0))+int(result[key])
	force["hunger_losses"]=totals
	force["hunger_today"]=result.duplicate()
	return result

## Sick men rejoin their formations while the band is fed.
func recovery_day(force:Dictionary,span:float)->int:
	var sick:=maxi(0,int(force.get("wounded_pool",0))-maxi(0,int(force.get("disabled_pool",0))))
	if sick<=0 or float(force.get("provision_ratio",1.0))<Rations.HUNGRY_BELOW: return 0
	var owed:=float(force.get("recovery_accumulator",0.0))+float(sick)*RECOVER_PER_DAY*span
	var back:=mini(sick,floori(owed))
	force["recovery_accumulator"]=owed-float(back)
	if back<=0: return 0
	var placed:=_return_men(force,back)
	force["wounded_pool"]=int(force.get("wounded_pool",0))-placed
	return placed

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

## Men back into formations with open places, largest gap first.
func _return_men(force:Dictionary,count:int)->int:
	var formations:Array=force.get("formations",[])
	var left:=count
	var order:=range(formations.size())
	order.sort_custom(func(a,b): return _gap(formations[a])>_gap(formations[b]))
	for index in order:
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

## Open places in a band not yet covered by a draft in training or on the road.
func open_places(force:Dictionary)->Dictionary:
	var army_id:=int(force.get("army_id",0))
	var covered:={}
	for order:Dictionary in host.training_queue:
		if int(order.get("field_army_id",0))==army_id: covered[int(order.get("target_formation_id",-1))]=int(covered.get(int(order.get("target_formation_id",-1)),0))+int(order.get("count",0))
	for draft:Dictionary in host.field_drafts:
		if int(draft.get("army_id",0))==army_id: covered[int(draft.get("formation_id",-1))]=int(covered.get(int(draft.get("formation_id",-1)),0))+int(draft.get("count",0))
	var places:={}
	for formation in force.get("formations",[]):
		var id:=int(formation.get("id",-1))
		var open:=_gap(formation)-int(covered.get(id,0))
		if open>0: places[id]={"unit":String(formation.get("unit","levy")),"weapon":String(formation.get("weapon","improvised")),"count":open}
	return places

## Call up and start training drafts for every band's open places, First
## priority bands first. Sick men are not replaced (they come back when fed).
func draft_day()->Array:
	var started:=[]
	if host.recovery.home_unavailable(): return started
	var bands:Array=host.field_armies.duplicate()
	bands.sort_custom(func(a,b): return priority_rank(a)<priority_rank(b))
	for force:Dictionary in bands:
		if String(force.get("priority","normal"))=="last": continue
		if bool(force.get("general_managed",false)) and WorldSimulation.campaign.active: continue
		var sick:=maxi(0,int(force.get("wounded_pool",0)))
		var places:=open_places(force)
		for formation_id in places:
			var place:Dictionary=places[formation_id]
			# The sick fill their own places when they recover.
			var need:=maxi(0,int(place.count)-sick)
			sick=maxi(0,sick-int(place.count))
			if need<=0: continue
			var free:int=host.aggregate_recruits+maxi(0,host.recruitment_capacity()-host._mobilized_count())
			var count:=mini(need,free)
			if count<=0: return started
			if count>host.aggregate_recruits: host.raise_recruits(count-host.aggregate_recruits)
			var result:Dictionary=host.start_training(String(place.unit),String(place.weapon),count)
			if result.has("error"): continue
			var order:Dictionary=host.training_queue[-1]
			order["mode"]="field_draft"
			order["field_army_id"]=int(force.get("army_id",0))
			order["target_formation_id"]=int(formation_id)
			order["required_days"]=maxf(3.0,float(order.get("required_days",30.0))*DRAFT_TRAINING)
			started.append({"army_id":int(force.get("army_id",0)),"formation_id":int(formation_id),"count":count})
	return started

static func priority_rank(force:Dictionary)->int:
	return {"first":0,"normal":1,"last":2}.get(String(force.get("priority","normal")),1)

## A trained draft leaves for its band with the gear stores can give it.
func dispatch(order:Dictionary)->Dictionary:
	var count:=maxi(0,int(order.get("count",0)))
	var weapon:=String(order.get("weapon","improvised"))
	var unit:=String(order.get("unit","levy"))
	var needed:int=host.simulator.equipment_required_for_weapon(weapon,count)
	var reserved:=maxi(0,int(order.get("reserved_equipment",0)))
	var issued:=mini(needed,reserved+maxi(0,int(host.military_inventory.get(weapon,0))))
	host.military_inventory[weapon]=int(host.military_inventory.get(weapon,0))+reserved-issued
	var access:=clampf(float(order.get("equipment_access_sum",0.0))/maxf(0.01,float(order.get("instruction_progress_sum",order.get("required_days",1.0)))),0.0,1.0)
	var skill:float=host._training_quality(unit,0.0)*(0.72+access*0.28)
	var force:=_army(int(order.get("field_army_id",0)))
	var days:=travel_days(force)
	var draft:={"army_id":int(order.get("field_army_id",0)),"formation_id":int(order.get("target_formation_id",-1)),"unit":unit,"weapon":weapon,"count":count,"equipment":issued,"training":skill,"left_day":int(WorldSimulation.state.elapsed_days),"arrive_day":int(WorldSimulation.state.elapsed_days)+days}
	host.field_drafts.append(draft)
	return draft

## Days a draft walks to its band: the supply line's haul days, at least one.
func travel_days(force:Dictionary)->int:
	if force.is_empty() or host._army_is_home(force): return 1
	return maxi(1,ceili(float(Supply.of_force(force).get("days",1.0))))

## Drafts that have arrived join their formations; a draft whose band is gone
## comes home to the recruits and hands its gear back.
func arrivals_day()->Array:
	var joined:=[]
	var today:=int(WorldSimulation.state.elapsed_days)
	for index in range(host.field_drafts.size()-1,-1,-1):
		var draft:Dictionary=host.field_drafts[index]
		if int(draft.get("arrive_day",0))>today: continue
		host.field_drafts.remove_at(index)
		var army_index:int=host._field_army_index(int(draft.army_id))
		if army_index<0 or host.command_hierarchy.battle.engaged(int(draft.army_id)):
			if army_index>=0:
				# A band in battle takes its drafts when the fight is over.
				draft["arrive_day"]=today+1
				host.field_drafts.append(draft)
				continue
			host.aggregate_recruits+=int(draft.count)
			host.military_inventory[String(draft.weapon)]=int(host.military_inventory.get(String(draft.weapon),0))+int(draft.equipment)
			continue
		var force:Dictionary=host.field_armies[army_index]
		var formations:Array=force.get("formations",[])
		var placed:=false
		for f_index in formations.size():
			var formation:Dictionary=formations[f_index]
			if int(formation.get("id",-1))!=int(draft.formation_id): continue
			var old:=maxi(0,int(formation.get("count",0)))
			formation["count"]=old+int(draft.count)
			formation["equipment"]=int(formation.get("equipment",0))+int(draft.equipment)
			formation["training"]=(float(formation.get("training",0.5))*old+float(draft.training)*int(draft.count))/maxf(1.0,float(old+int(draft.count)))
			formation["experience"]=float(formation.get("experience",0.0))*old/maxf(1.0,float(old+int(draft.count)))
			formation["authorized_count"]=maxi(int(formation.get("authorized_count",old)),old+int(draft.count))
			formations[f_index]=formation
			placed=true
			break
		if not placed:
			host.aggregate_recruits+=int(draft.count)
			host.military_inventory[String(draft.weapon)]=int(host.military_inventory.get(String(draft.weapon),0))+int(draft.equipment)
			continue
		force["formations"]=formations
		_rebuild(force)
		force["drafts_joined"]=int(force.get("drafts_joined",0))+int(draft.count)
		host.field_armies[army_index]=force
		joined.append(draft)
	return joined

func _army(army_id:int)->Dictionary:
	var index:int=host._field_army_index(army_id)
	return host.field_armies[index] if index>=0 else {}

## People in drafts on the road (field personnel in the ledger).
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
		if int(order.get("field_army_id",0))==army_id: training+=int(order.get("count",0))
	return {"on_road":men,"in_training":training,"next_arrival_day":first}

## Validation for saved drafts: plain records with sane counts.
static func valid_drafts(drafts:Variant)->bool:
	if not drafts is Array: return false
	for draft in drafts:
		if not draft is Dictionary: return false
		for key in ["army_id","formation_id","count","equipment","arrive_day"]:
			if not (draft as Dictionary).has(key) or int(draft[key])<(0 if key!="formation_id" else -1): return false
	return true
