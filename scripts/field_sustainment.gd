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
##
## The band's own general carries it (their commander record's skills,
## historical_figures.gd): their logistics sets how much hunger costs
## (x1.2 at none, x0.8 at the best: HUNGER_BY_LOGISTICS), and their command
## and resolve set the band's discipline, and so how many slip away under
## hardship, by the same rule as the band at home (desertion_day). Each
## general's record keeps the days, the march, the hungry days and the
## deserters (HistoricalFigures.note_field_day, note_record).

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
## Drafts on the road wait this long for a cut-off band before coming home.
const MAX_WAIT_DAYS:=30
## Hunger losses the war leader still speaks of, in days since the last.
const HUNGER_MEMORY_DAYS:=30
## Hunger's cost under a general: x(HUNGER_BASE - HUNGER_BY_LOGISTICS *
## logistics), so x1.0 under an ordinary one (0.5).
const HUNGER_BASE:=1.2
const HUNGER_BY_LOGISTICS:=0.4
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

## Share of the band's stores that arrives today: the country grazes part of
## the fodder, and the carriers bring `carried` of the rest they were asked
## for (carriers.gd stores ratio times the haul). 1.0 when it asks for none.
static func stores_share(force:Dictionary,carried:float,graze:float)->float:
	var demand:=stores_demand(force)
	var loads:=float(demand.loads)
	if loads<=0.0: return 1.0
	var grazed:=float(demand.fodder)*clampf(graze,0.0,1.0)
	var arrived:=grazed+(loads-grazed)*clampf(carried,0.0,1.0)
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
	var rate:=HUNGER_RATE*(Rations.HUNGRY_BELOW-food)/Rations.HUNGRY_BELOW*hunger_factor(force)
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
	_general_note(force,"deserted",float(result.deserted))
	force["hunger_losses"]=totals
	force["hunger_last_day"]=int(WorldSimulation.state.elapsed_days)
	force["hunger_today"]=result.duplicate()
	return result

## How much hunger costs a band under its general: their logistics, x1.2 at
## none to x0.8 at the best (1.0 for an ordinary one or none named).
static func hunger_factor(force:Dictionary)->float:
	return HUNGER_BASE-HUNGER_BY_LOGISTICS*_skill(force,"logistics")

static func _skill(force:Dictionary,skill:String)->float:
	var commander:Dictionary=force.get("commander",{}) if force.get("commander") is Dictionary else {}
	return clampf(float(commander.get(skill,0.5)),0.0,1.0)

## The named general of a band ("" for the war leader at home or none).
static func general_of(force:Dictionary)->String:
	var commander:Dictionary=force.get("commander",{}) if force.get("commander") is Dictionary else {}
	return String(commander.get("figure_id",""))

func _general_note(force:Dictionary,key:String,amount:float)->void:
	var id:=general_of(force)
	if id=="" or amount<=0.0 or WorldSimulation.figures==null: return
	WorldSimulation.figures.note_record(id,key,amount)

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
## full heart, a half-supplied one only part way. A hungry band loses heart:
## its will wears down toward MORALE_HUNGER_FLOOR, below the one break line
## (a quarter, army_lines.gd), so a band starved long enough breaks and the
## war leader brings it back to be fed (band_upkeep.gd). One already lower,
## beaten in a fight, regains a little toward that floor instead of staying
## where the fight left it.
const MORALE_REST:=0.03
const MORALE_MARCHING:=0.33
const MORALE_HUNGER_LOSS:=0.008
const MORALE_HUNGER_FLOOR:=preload("res://scripts/army_lines.gd").BREAK*0.6
## Battle wounded who rejoin a day in full supply (twice with a medical
## detachment in the band); the disabled stay in the pool until home.
const WOUNDED_RETURN:=0.015

## A day's rest for a band or garrison: heart regained or lost, and battle
## wounded back in their places. Nothing while it fights.
func rest_day(force:Dictionary,span:float)->Dictionary:
	var result:={"morale":0.0,"wounded_back":0}
	if force.has("army_id") and host.command_hierarchy.battle.engaged(int(force.get("army_id",0))):
		_general_day(force,span)
		return result
	desertion_day(force,span)
	_general_day(force,span)
	var supply:=clampf(float(force.get("supply_level",1.0)),0.0,1.0)
	var morale:=float(force.get("morale",1.0))
	var before:=morale
	if Rations.is_hungry(force):
		morale=move_toward(morale,MORALE_HUNGER_FLOOR,MORALE_HUNGER_LOSS*span)
	else:
		var pace:=MORALE_REST*(MORALE_MARCHING if String(force.get("status","stationed")) in ["moving","turning_back"] else 1.0)
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

# --- Discipline: who slips away --------------------------------------------

## A band's discipline under its general, by the home band's rule
## (military_campaign._process_aggregate_service_strain_day): 0.18 +
## leadership (command 0.55, resolve 0.45) x 0.42 + drill x 0.30 + a
## professional corps x 0.18.
func discipline_of(force:Dictionary)->float:
	var leadership:=clampf(_skill(force,"command")*0.55+_skill(force,"resolve")*0.45,0.0,1.0)
	var weighted:=0.0
	var men:=0.0
	for formation in force.get("formations",[]):
		weighted+=float(formation.get("training",0.0))*float(formation.get("count",0))
		men+=float(formation.get("count",0))
	var training:=clampf(weighted/maxf(1.0,men),0.0,1.0)
	var corps:=float(host._adoption("professional_corps")) if host!=null and host.has_method("_adoption") else 0.0
	return clampf(0.18+leadership*0.42+training*0.30+corps*0.18,0.0,1.0)

## A day's desertion from a band or garrison away from home, by the home
## band's rule: hardship (short supply, broken heart, the march) builds a
## strain that eases slowly; past it men slip away at a pressure that a
## well-led, drilled band (discipline_of) holds down and a cohesive people
## holds down further. Deserters go home to work (the mobilized count falls),
## counted on the band and on its general's record. {deserted, pressure}.
func desertion_day(force:Dictionary,span:float)->Dictionary:
	var out:={"deserted":0,"pressure":0.0}
	var troops:=maxi(0,int(force.get("troops",0)))
	if troops<=0 or (force.has("army_id") and host.at_home_point(force)): return out
	var supply:=clampf(float(force.get("supply_level",1.0)),0.0,1.0)
	var morale:=clampf(float(force.get("morale",1.0)),0.0,1.0)
	var marching:=String(force.get("status","stationed")) in ["moving","turning_back"]
	var hardship:=clampf(maxf(0.0,0.70-supply)/0.70+maxf(0.0,0.50-morale)*1.5+(0.15 if marching else 0.0),0.0,1.0)
	var strain:=float(force.get("service_strain",0.0))
	strain=move_toward(strain,hardship,(0.012 if hardship<strain else 0.006)*span)
	var discipline:=discipline_of(force)
	var cohesion:=clampf(float(WorldSimulation.state.simulation_metrics.get("cohesion",0.58)),0.0,1.0)
	var pressure:=(maxf(0.0,strain-0.42)*0.020*clampf(hardship*2.0,0.0,1.0)+maxf(0.0,0.42-supply)*0.024+maxf(0.0,0.32-morale)*0.018)*(1.15-discipline*0.65)*(1.10-cohesion*0.35)
	force["service_strain"]=strain
	force["discipline"]=discipline
	force["desertion_pressure"]=pressure
	if pressure<=0.0:
		force["desertion_accumulator"]=0.0
		return out
	var owed:=float(force.get("desertion_accumulator",0.0))+float(troops)*pressure*span
	var gone:=mini(troops,floori(owed))
	force["desertion_accumulator"]=owed-float(gone)
	out.pressure=pressure
	if gone<=0: return out
	var removed:=_take_men(force,gone)
	force["desertions_total"]=int(force.get("desertions_total",0))+removed
	force["morale"]=clampf(morale-minf(0.12,float(removed)/maxf(1.0,float(troops))*0.5),0.0,1.5)
	_general_note(force,"deserted",float(removed))
	out.deserted=removed
	return out

## The general's day in the field, for their record: the days, the march at
## the band's pace, and hunger (HistoricalFigures.note_field_day).
func _general_day(force:Dictionary,span:float)->void:
	var id:=general_of(force)
	if id=="" or WorldSimulation.figures==null: return
	# Their record follows their own skills as they grow (leader_commands.gd).
	WorldSimulation.figures.sync_force(host,force)
	id=general_of(force)
	if id=="": return
	if force.has("army_id") and host.at_home_point(force): return
	var marching:=String(force.get("status","stationed")) in ["moving","turning_back"]
	WorldSimulation.figures.note_field_day(id,span,marching,float(force.get("speed_km_day",0.0)),Rations.is_hungry(force))

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

## A draft goes to one force: a band (its army_id) or a garrison holding a
## town (its garrison key, field_rations.occupation_key: "civ/region").
## Training orders name the band in field_army_id, drafts on the road in
## army_id; both name a garrison in "garrison".
static func draft_key(force:Dictionary)->String:
	if force.has("army_id"): return "army:%d" % int(force.get("army_id",0))
	return "garrison:"+Rations.occupation_key(force)

static func _record_key(record:Dictionary)->String:
	var garrison:=String(record.get("garrison",""))
	if garrison!="": return "garrison:"+garrison
	return "army:%d" % int(record.get("field_army_id",record.get("army_id",0)))

## The band or garrison a draft key names ({} once it is gone).
func _force_of(key:String)->Dictionary:
	if key.begins_with("army:"): return _army(int(key.trim_prefix("army:")))
	if not key.begins_with("garrison:"): return {}
	var parts:=key.trim_prefix("garrison:").split("/",true,1)
	if parts.size()<2: return {}
	var at:int=host._occupation_force_index(String(parts[0]),String(parts[1]))
	return host.occupation_forces[at] if at>=0 else {}

## Men already on their way to each formation of a band or garrison: in
## training or on the road ({formation id: {men, sets}}).
func _covered(key:String)->Dictionary:
	var covered:={}
	for order:Dictionary in host.training_queue:
		if String(order.get("mode",""))!="field_draft" or _record_key(order)!=key: continue
		var id:=int(order.get("target_formation_id",-1))
		var entry:Dictionary=covered.get(id,{"men":0,"sets":0})
		entry.men=int(entry.men)+int(order.get("count",0))
		covered[id]=entry
	for draft:Dictionary in host.field_drafts:
		if _record_key(draft)!=key: continue
		var id:=int(draft.get("formation_id",-1))
		var entry:Dictionary=covered.get(id,{"men":0,"sets":0})
		entry.men=int(entry.men)+int(draft.get("count",0))
		entry.sets=int(entry.sets)+int(draft.get("equipment",0))
		covered[id]=entry
	return covered

## Open places in a band or garrison not covered by the hunger-sick (who come
## back when fed) nor by drafts in training or on the road, largest gap first.
func open_places(force:Dictionary)->Dictionary:
	var covered:=_covered(draft_key(force))
	# The hunger-sick still in the pool (never more than its able part), and
	# the battle wounded expected back before a draft could arrive, hold
	# their own places.
	var sick:=mini(maxi(0,int(force.get("hunger_sick",0))),maxi(0,int(force.get("wounded_pool",0))-maxi(0,int(force.get("disabled_pool",0)))))
	sick+=_wounded_back_within(force,_draft_lead(force))
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

## Days before a draft raised today would reach the band: its course at the
## Reinforce pace and the walk out.
func _draft_lead(force:Dictionary)->int:
	var course:=0.0
	for formation in force.get("formations",[]):
		course=maxf(course,float(host.UnitCatalog.training_days(String(formation.get("unit","levy"))))*DRAFT_TRAINING)
	return roundi(course)+maxi(1,travel_days(force))

## Battle wounded (not hunger-sick, not disabled) expected back in `days` at
## the band's present supply (rest_day's own rate).
func _wounded_back_within(force:Dictionary,days:int)->int:
	var wounded:=maxi(0,int(force.get("wounded_pool",0))-maxi(0,int(force.get("hunger_sick",0)))-maxi(0,int(force.get("disabled_pool",0))))
	var supply:=clampf(float(force.get("supply_level",1.0)),0.0,1.0)
	if wounded<=0 or supply<0.5 or Rations.is_hungry(force): return 0
	var rate:=WOUNDED_RETURN*(2.0 if _has_medics(force) else 1.0)*supply
	return floori(float(wounded)*(1.0-pow(1.0-minf(rate,1.0),float(maxi(0,days)))))

## Why a band or garrison gets no drafts today, or "" when it may.
func draft_block(force:Dictionary)->String:
	if String(force.get("priority","normal"))=="last": return "last"
	if bool(force.get("general_managed",false)) and WorldSimulation.campaign!=null and WorldSimulation.campaign.active: return "campaign"
	if Rations.is_hungry(force): return "hungry"
	var access:float=float(host._force_provision_access(force)) if force.has("army_id") else float(host._garrison_provision_access(force))
	if not host.at_home_point(force) and access<=CUT_OFF: return "cut_off"
	return ""

## Plain words for why no drafts come, for the screens and the war leader
## (drafts_for gives them as block_words). The old "no_people" block, told
## as "+0 coming" and as advice to raise the Defense share, is gone: drafts
## come from the army's size now.
const BLOCK_WORDS:={
	"at_level":"No more can come: everyone keeping watch is already serving, and the home guard stays home. Raise the watch share, or keep fewer at home, to fill the empty places.",
	"nobody_free":"Nobody free to call up: every able adult is already serving or away.",
	"hungry":"No drafts while the band is starving: they would starve too.",
	"cut_off":"No drafts: no road our carriers use reaches them.",
	"last":"No drafts for a band reinforced last.",
	"campaign":"The general's campaign keeps its own ranks.",
	"few":"No draft for so few: its empty places are one or two here and there.",
}

static func block_words(block:String)->String:
	return String(BLOCK_WORDS.get(block,""))

## The same reason in a few words: "the army stands at the size you set".
static func block_reason(block:String)->String:
	return String({"at_level":"the watch is all serving and the home guard stays home","nobody_free":"nobody is free to call up","hungry":"they are starving","cut_off":"no road our carriers use reaches them","last":"it is reinforced last","campaign":"the general's campaign keeps its own ranks","few":"its empty places are too few to call a draft for"}.get(block,"no drafts can reach them"))

## How many more the war leader may call up for the army today: the watch
## is the army (watch_military.gd), so only the watch share not yet under
## arms; drafts otherwise come from the offensive troops at home
## (home_reserve). Raise the watch share to fill more places.
func levy_room()->int:
	var read:Dictionary=preload("res://scripts/army_levy_law.gd").reading(host)
	return maxi(0,int(read.get("gap",0)))

## People a new draft may call up today: those already called up and
## waiting, then free adults within the room the army's size leaves.
func draftable()->int:
	var free_adults:int=maxi(0,host.recruitment_capacity()-host._mobilized_count())
	return maxi(0,host.aggregate_recruits)+mini(free_adults,levy_room())

## The army's reserve at home: the watch at home beyond the home guard (the
## offensive troops not in a band, watch_military.gd). They fill bands and
## garrisons first, needing no drill.
func home_reserve()->int:
	if host.recovery.home_unavailable() or host._home_battle_running(): return 0
	var watch:Dictionary=preload("res://scripts/army_levy_law.gd").watch(host)
	return maxi(0,int(host.home_army.get("troops",0))-int(watch.get("home",0)))

## Call up and start training drafts for every band's and garrison's open
## places, First priority bands first, then the others, then garrisons. The
## army's trained reserve at home goes first (to a band at home at once,
## else walking out); then new drafts, drilled at the Reinforce pace. Returns
## what was started or sent.
func draft_day()->Array:
	var started:=[]
	if host.recovery.home_unavailable(): return started
	var free:=draftable()
	var reserve:=home_reserve()
	var targets:Array=host.field_armies.duplicate()
	targets.sort_custom(func(a,b): return priority_rank(a)<priority_rank(b))
	var day:=int(WorldSimulation.state.elapsed_days)
	for garrison in host.occupation_forces:
		# The town's need is reckoned again every few days, not every day.
		if day%GARRISON_FIT_EVERY==0 or not (garrison as Dictionary).has("need"): _fit_garrison(garrison)
		targets.append(garrison)
	for force:Dictionary in targets:
		# A force with no empty place needs nothing reckoned (the supply line's
		# reach is the dear part of a day's drafts).
		if int(force.get("troops",0))<=0 or not _has_gap(force):
			force["draft_block"]=""
			continue
		force["draft_block"]=draft_block(force)
		if String(force.draft_block)!="": continue
		var places:=open_places(force)
		var short:=false
		var few:=false
		var drafted:=false
		for formation_id in places:
			var place:Dictionary=places[formation_id]
			var need:=int(place.count)
			if need<maxi(DRAFT_MIN_MEN,ceili(float(place.size)*DRAFT_MIN_SHARE)):
				few=true
				continue
			if reserve>0:
				var sent:=_send_reserve(force,int(formation_id),place,mini(need,reserve))
				reserve-=sent; need-=sent
				drafted=drafted or sent>0
				if sent>0: started.append({"key":draft_key(force),"army_id":int(force.get("army_id",0)),"formation_id":int(formation_id),"count":sent,"from":"reserve"})
			if need<=0: continue
			var count:=mini(need,free)
			# No daily dribble of one or two: a draft is the whole gap or at
			# least DRAFT_MIN_MEN.
			if count<mini(need,DRAFT_MIN_MEN):
				short=true
				continue
			# From the watch share not yet under arms (levy_room): they are
			# already counted in the share, so it does not move.
			if count>host.aggregate_recruits: host.aggregate_recruits=count
			count=mini(count,host.aggregate_recruits)
			if count<=0:
				short=true
				continue
			var order:=_open_order(draft_key(force),int(formation_id))
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
				if not force.has("army_id"): order["garrison"]=Rations.occupation_key(force)
				order["target_formation_id"]=int(formation_id)
				order["required_days"]=maxf(3.0,float(order.get("required_days",30.0))*DRAFT_TRAINING)
			free-=count
			drafted=true
			force["drafted_today"]=int(force.get("drafted_today",0))+count
			started.append({"key":draft_key(force),"army_id":int(force.get("army_id",0)),"formation_id":int(formation_id),"count":count})
		# Places left open with nobody to fill them: why, in one word. The
		# size the ruler set stops it while free hands remain; else nobody is
		# free.
		if short: force["draft_block"]="at_level" if levy_room()<maxi(0,int(host.recruitment_capacity())-int(host._mobilized_count())) else "nobody_free"
		# Only empty places too few to call a draft for (one here, two there):
		# nothing will come for them, so a band resting to refill is not kept
		# waiting for ever (band_upkeep.gd _nothing_more_coming).
		elif few and not drafted and not _drafts_open(force): force["draft_block"]="few"
	return started

## Drafts already in drill or on the road for this band or garrison.
func _drafts_open(force:Dictionary)->bool:
	var coming:=drafts_for_force(force)
	return int(coming.get("on_road",0))+int(coming.get("in_training",0))>0

static func _has_gap(force:Dictionary)->bool:
	for formation in force.get("formations",[]):
		if formation is Dictionary and _gap(formation)>0: return true
	return false

## How often (days) a garrison's need is reckoned again.
const GARRISON_FIT_EVERY:=5

## A garrison's full strength is what its town needs while its men are fed
## (town_hold.gd): when that grows past its places, its largest formation is
## given the room, so drafts come for the difference. need is kept on the
## record for the screens.
func _fit_garrison(force:Dictionary)->void:
	var Hold:=preload("res://scripts/town_hold.gd")
	var required:=Hold.town_required(String(force.get("civ_id","")),String(force.get("region_id","")),float(force.get("required",0.0)))
	var need:=Hold.need(required,maxf(Hold.fed(force),Rations.HUNGRY_BELOW),float(force.get("readiness",1.0)))
	force["need"]=need
	var formations:Array=force.get("formations",[])
	if formations.is_empty(): return
	var full:=0
	var largest:=0
	for index in formations.size():
		var formation:Dictionary=formations[index]
		full+=maxi(int(formation.get("count",0)),int(formation.get("authorized_count",0)))
		if int(formation.get("count",0))>int((formations[largest] as Dictionary).get("count",0)): largest=index
	if need<=full: return
	var grown:Dictionary=formations[largest]
	grown["authorized_count"]=maxi(int(grown.get("count",0)),int(grown.get("authorized_count",0)))+need-full
	grown["equipment_required"]=host._equipment_required_for(String(grown.get("unit","levy")),int(grown.authorized_count))
	grown["ammunition_required"]=host._ammunition_required_for(String(grown.get("weapon","improvised")),int(grown.equipment_required))
	formations[largest]=grown
	force["formations"]=formations

## Trained men of the reserve at home sent to a band's or garrison's open
## places: to a band at home at once, else walking out as a draft. Returns
## the men sent.
func _send_reserve(force:Dictionary,formation_id:int,place:Dictionary,count:int)->int:
	var men:=_take_from_home(String(place.unit),String(place.weapon),count)
	if int(men.men)<=0: return 0
	var today:=int(WorldSimulation.state.elapsed_days)
	var draft:={"army_id":int(force.get("army_id",0)),"formation_id":formation_id,"unit":String(place.unit),"weapon":String(place.weapon),"count":int(men.men),"equipment":int(men.sets),"ammunition":int(men.rounds),
		"training":float(men.training),"experience":float(men.experience),"left_day":today,"from_reserve":true}
	if not force.has("army_id"): draft["garrison"]=Rations.occupation_key(force)
	if force.has("army_id") and host.at_home_point(force):
		_join(force,draft)
		return int(men.men)
	var days:=travel_days(force)
	draft["arrive_day"]=today+(days if days>0 else 1)
	draft["waiting"]=days<=0
	host.field_drafts.append(draft)
	return int(men.men)

## Up to `want` trained men of this kind and these arms out of the army at
## home (never its untrained watch), with their share of its gear and rounds:
## {men, sets, rounds, training, experience}. The army at home is down by as
## many; nobody is lost or made.
func _take_from_home(unit:String,weapon:String,want:int)->Dictionary:
	var out:={"men":0,"sets":0,"rounds":0,"training":0.0,"experience":0.0}
	if want<=0: return out
	var home:Dictionary=host.home_army
	var formations:Array=home.get("formations",[])
	var drilled:=0.0
	var seen:=0.0
	for index in range(formations.size()-1,-1,-1):
		if int(out.men)>=want: break
		var formation:Dictionary=formations[index]
		if bool(formation.get("emergency_militia",false)) or String(formation.get("unit",""))!=unit or String(formation.get("weapon",""))!=weapon: continue
		var have:=maxi(0,int(formation.get("count",0)))
		if have<=0: continue
		var take:=mini(have,want-int(out.men))
		var sets:=mini(int(formation.get("equipment",0)),roundi(float(formation.get("equipment",0))*float(take)/float(have)))
		var rounds:=mini(int(formation.get("ammunition",0)),roundi(float(formation.get("ammunition",0))*float(take)/float(have)))
		formation["count"]=have-take
		formation["authorized_count"]=maxi(int(formation.count),int(formation.get("authorized_count",have))-take)
		formation["equipment"]=maxi(0,int(formation.get("equipment",0))-sets)
		formation["equipment_required"]=host._equipment_required_for(unit,int(formation.authorized_count))
		formation["ammunition"]=maxi(0,int(formation.get("ammunition",0))-rounds)
		formation["ammunition_required"]=host._ammunition_required_for(weapon,int(formation.equipment_required))
		drilled+=float(formation.get("training",0.5))*take
		seen+=float(formation.get("experience",0.0))*take
		out.men=int(out.men)+take
		out.sets=int(out.sets)+sets
		out.rounds=int(out.rounds)+rounds
		if int(formation.count)<=0: formations.remove_at(index)
		else: formations[index]=formation
	if int(out.men)<=0: return out
	home["formations"]=formations
	_rebuild(home)
	host._refresh_readiness()
	out.training=drilled/float(out.men)
	out.experience=seen/float(out.men)
	return out

func _open_order(key:String,formation_id:int)->Dictionary:
	for order:Dictionary in host.training_queue:
		if String(order.get("mode",""))=="field_draft" and _record_key(order)==key and int(order.get("target_formation_id",-1))==formation_id and float(order.get("progress_days",0.0))<float(order.get("required_days",1.0)):
			return order
	return {}

static func priority_rank(force:Dictionary)->int:
	return {"first":0,"normal":1,"last":2}.get(String(force.get("priority","normal")),1)

## A trained draft leaves for its band or garrison, taking gear only for the
## real gap. A draft whose band is gone joins the army at home as trained men.
func dispatch(order:Dictionary)->Dictionary:
	var count:=maxi(0,int(order.get("count",0)))
	var weapon:=String(order.get("weapon","improvised"))
	var unit:=String(order.get("unit","levy"))
	var key:=_record_key(order)
	var force:=_force_of(key)
	var formation:=_formation(force,int(order.get("target_formation_id",-1)))
	if force.is_empty() or formation.is_empty():
		order["mode"]="new"
		order.erase("field_army_id");order.erase("target_formation_id");order.erase("garrison")
		host._complete_training(order)
		return {"home":true,"count":count}
	var required:=int(formation.get("equipment_required",host.simulator.equipment_required_for_weapon(weapon,int(formation.get("authorized_count",0)))))
	var on_road:=int((_covered(key).get(int(formation.id),{}) as Dictionary).get("sets",0))
	var gap:=maxi(0,required-int(formation.get("equipment",0))-on_road)
	var wanted:=mini(gap,host.simulator.equipment_required_for_weapon(weapon,count))
	var reserved:=maxi(0,int(order.get("reserved_equipment",0)))
	# The reserved gear first, then what is held for the kit (watch_military.gd:
	# made sets for the watch's own kit, then the armoury).
	var from_reserve:=mini(wanted,reserved)
	var issued:=from_reserve+int(preload("res://scripts/watch_military.gd").take_weapons(host,wanted-from_reserve,weapon))
	if reserved>from_reserve: preload("res://scripts/watch_military.gd").return_weapons(host,reserved-from_reserve,weapon)
	host.gear_sent_out+=issued-reserved
	var access:=clampf(float(order.get("equipment_access_sum",0.0))/maxf(0.01,float(order.get("instruction_progress_sum",order.get("required_days",1.0)))),0.0,1.0)
	var skill:float=host._training_quality(unit,0.0)*(0.72+access*0.28)
	var days:=travel_days(force)
	var today:=int(WorldSimulation.state.elapsed_days)
	var draft:={"army_id":int(force.get("army_id",0)),"formation_id":int(formation.id),"unit":unit,"weapon":weapon,"count":count,"equipment":issued,"training":skill,"left_day":today,"arrive_day":today+(days if days>0 else 1),"waiting":days<=0}
	if key.begins_with("garrison:"): draft["garrison"]=key.trim_prefix("garrison:")
	host.field_drafts.append(draft)
	return draft

## Days a draft walks to its band or garrison: the supply line's haul days,
## at least one; 0 when no road reaches it (the draft waits at home).
func travel_days(force:Dictionary)->int:
	if force.is_empty() or host.at_home_point(force): return 1
	var days:=float(Supply.of_force(force).get("days",1.0))
	var access:float=float(host._force_provision_access(force)) if force.has("army_id") else float(host._garrison_provision_access(force))
	if not is_finite(days) or access<=CUT_OFF: return 0
	return maxi(1,ceili(days))

## Drafts that have arrived join their formations, up to the open places;
## any beyond them come home to the recruits, with gear beyond the force's
## need back in store. A band in battle or cut off takes them later; a draft
## whose band or garrison is gone comes home.
func arrivals_day()->Array:
	var joined:=[]
	var today:=int(WorldSimulation.state.elapsed_days)
	for index in range(host.field_drafts.size()-1,-1,-1):
		var draft:Dictionary=host.field_drafts[index]
		if int(draft.get("arrive_day",0))>today: continue
		var key:=_record_key(draft)
		var band:=_force_of(key)
		var army_id:=int(draft.get("army_id",0))
		if not band.is_empty():
			# In battle, or cut off from our roads: the draft waits a day.
			var engaged:bool=army_id>0 and host.command_hierarchy.battle.engaged(army_id)
			var access:float=float(host._force_provision_access(band)) if band.has("army_id") else float(host._garrison_provision_access(band))
			var blocked:bool=engaged or (not host.at_home_point(band) and access<=CUT_OFF)
			if bool(draft.get("waiting",false)):
				var days:=travel_days(band)
				if days>0:
					draft["waiting"]=false;draft["arrive_day"]=today+days
				else:
					draft["arrive_day"]=today+1
				continue
			if blocked:
				draft["waited"]=int(draft.get("waited",0))+1
				if int(draft.waited)<=MAX_WAIT_DAYS or engaged:
					draft["arrive_day"]=today+1
					continue
		host.field_drafts.remove_at(index)
		if band.is_empty() or int(draft.get("waited",0))>MAX_WAIT_DAYS:
			_send_home(draft)
			continue
		if _join(band,draft): joined.append(draft)
		else: _send_home(draft)
	return joined

## A draft joins its formation of the band or garrison, up to its open
## places; men and gear beyond them come home. False when the formation is
## gone.
func _join(force:Dictionary,draft:Dictionary)->bool:
	var formations:Array=force.get("formations",[])
	for f_index in formations.size():
		var formation:Dictionary=formations[f_index]
		if int(formation.get("id",-1))!=int(draft.formation_id): continue
		var old:=maxi(0,int(formation.get("count",0)))
		var men:=mini(int(draft.count),_gap(formation))
		var required:=int(formation.get("equipment_required",int(formation.get("equipment",0))))
		var sets:=mini(int(draft.equipment),maxi(0,required-int(formation.get("equipment",0))))
		formation["count"]=old+men
		formation["equipment"]=int(formation.get("equipment",0))+sets
		var rounds:=maxi(0,int(draft.get("ammunition",0)))
		if rounds>0:
			var room:=maxi(0,int(formation.get("ammunition_required",0))-int(formation.get("ammunition",0)))
			var put:=mini(rounds,room)
			formation["ammunition"]=int(formation.get("ammunition",0))+put
			var kind:String=host._ammunition_type_for(String(draft.get("weapon","improvised")))
			if kind!="" and rounds>put: host.military_consumables[kind]=int(host.military_consumables.get(kind,0))+rounds-put
		if men>0:
			formation["training"]=(float(formation.get("training",0.5))*old+float(draft.training)*men)/maxf(1.0,float(old+men))
			formation["experience"]=(float(formation.get("experience",0.0))*old+float(draft.get("experience",0.0))*men)/maxf(1.0,float(old+men))
		formations[f_index]=formation
		if int(draft.count)>men or int(draft.equipment)>sets:
			_send_home({"count":int(draft.count)-men,"unit":draft.get("unit","levy"),"weapon":draft.weapon,"equipment":int(draft.equipment)-sets,"training":draft.get("training",0.4)})
		force["formations"]=formations
		_rebuild(force)
		force["drafts_joined"]=int(force.get("drafts_joined",0))+men
		return true
	return false

## Drafts that cannot join come home: trained men join the army at home as
## a formation of their own (their drill kept), their gear back to store.
func _send_home(draft:Dictionary)->void:
	var weapon:=String(draft.get("weapon","improvised"))
	preload("res://scripts/watch_military.gd").return_weapons(host,maxi(0,int(draft.get("equipment",0))),weapon)
	host.gear_sent_out-=maxi(0,int(draft.get("equipment",0)))
	var rounds:=maxi(0,int(draft.get("ammunition",0)))
	var kind:String=host._ammunition_type_for(weapon) if rounds>0 else ""
	if kind!="": host.military_consumables[kind]=int(host.military_consumables.get(kind,0))+rounds
	var count:=maxi(0,int(draft.get("count",0)))
	if count<=0: return
	var unit:=String(draft.get("unit",""))
	if unit=="" or host.recovery.home_unavailable():
		host.aggregate_recruits+=count
		return
	host._complete_training({"mode":"new","unit":unit,"weapon":weapon,"count":count,"experience":clampf(float(draft.get("experience",0.0)),0.0,1.0),"progress_days":1.0,"required_days":1.0,"reserved_equipment":0,"prior_skill":float(draft.get("training",0.4))})

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

## What is coming to a band: {on_road, in_training, next_arrival_day, block,
## block_words}. drafts_for_force reads a garrison the same way.
func drafts_for(army_id:int)->Dictionary:
	return drafts_for_force(_army(army_id) if army_id>0 else {},"army:%d" % army_id)

func drafts_for_force(force:Dictionary,key:String="")->Dictionary:
	if key=="": key=draft_key(force)
	var men:=0
	var first:=-1
	for draft:Dictionary in host.field_drafts:
		if _record_key(draft)!=key: continue
		men+=int(draft.get("count",0))
		first=int(draft.arrive_day) if first<0 else mini(first,int(draft.arrive_day))
	var training:=0
	for order:Dictionary in host.training_queue:
		if String(order.get("mode",""))=="field_draft" and _record_key(order)==key: training+=int(order.get("count",0))
	var block:=String(force.get("draft_block","")) if not force.is_empty() else ""
	return {"on_road":men,"in_training":training,"next_arrival_day":first,"block":block,"block_words":block_words(block)}

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

# --- Trend: each band's last months at a glance --------------------------------

## A band's strength, supply and will, sampled every TREND_EVERY days and
## kept for TREND_KEEP samples (four months): [day, men, supply %, will %].
## The Readiness row draws it (hud/band_trend.gd) up to the last report home.
const TREND_EVERY:=5
const TREND_KEEP:=24

func trend_day()->void:
	if WorldSimulation.actor_id!="player": return
	var today:=int(WorldSimulation.state.elapsed_days)
	for index in host.field_armies.size():
		var record:Dictionary=host.field_armies[index]
		if int(record.get("troops",0))<=0: continue
		var samples:Array=record.get("trend",[]) if record.get("trend") is Array else []
		if not samples.is_empty() and today-int((samples[-1] as Array)[0])<TREND_EVERY: continue
		var fed:=float(record.get("provision_ratio",record.get("supply_level",1.0)))
		samples.append([today,int(record.troops),roundi(clampf(fed,0.0,1.0)*100.0),roundi(clampf(float(record.get("morale",1.0)),0.0,1.0)*100.0)])
		while samples.size()>TREND_KEEP: samples.pop_front()
		record["trend"]=samples
		host.field_armies[index]=record

## The samples home knows of: up to `known_day` (the last report's day).
static func trend_known(record:Dictionary,known_day:int)->Array:
	var out:=[]
	for s in (record.get("trend",[]) if record.get("trend") is Array else []):
		if s is Array and (s as Array).size()>=4 and int(s[0])<=known_day: out.append(s)
	return out
