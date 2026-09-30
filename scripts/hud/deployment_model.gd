extends RefCounted
## THE DEPLOYMENT QUEUE AS NUMBERS, the way HOI4's recruit and deploy screen
## shows it; hud/recruit_deploy_board.gd draws it.
##
## Everything comes from the one military ledger (docs/ADJUDICATION.md):
## MilitaryCampaign's personnel ledger, the recruitment lines and their
## training orders (scripts/recruit_deploy.gd), the instruction estimates
## (training_progress_snapshot) and the shared gear reading
## (scripts/equipment_logistics.gd). Pure reads; nothing here changes the
## world, and no number is kept twice.
##
##   manpower()   the strip on top: free to call up, serving, in training,
##                jobs left undone at home
##   lines()      each training line and its bands; each band has three bars
##                (men gathered, gear issued, training) and a day it is ready
##   templates()  the band templates as small cards (men, arms, gear to hand)
##   day_words()  a compact date, "12 Spring"

const Logistics:=preload("res://scripts/equipment_logistics.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const SEASONS:=["Spring","Summer","Autumn","Winter"]
## A band may be sent off early once this share of its training is done
## (scripts/recruit_deploy.gd uses the same fifth).
const EARLY_SHARE:=0.2

static func _host(mc:Node)->Node:
	return mc if mc!=null else MilitaryCampaign


static func _today()->int:
	return int(WorldSimulation.state.elapsed_days)


# --- Manpower -------------------------------------------------------------------

## {free, serving, training, undone, capacity, ledger}: free + serving +
## training is everyone who could serve (the capacity) while the draft has
## not taken more than that.
static func manpower(mc:Node=null)->Dictionary:
	mc=_host(mc)
	var ledger:Dictionary=mc.personnel_ledger()
	var total:=int(ledger.total)
	var training:=int(ledger.training)+int(ledger.recruits)
	return {"free":maxi(0,int(ledger.capacity)-total),"serving":maxi(0,total-training),"training":training,
		"undone":int(mc.population_commitment_snapshot().get("excess_beyond_defense",0)),"capacity":int(ledger.capacity),"ledger":ledger}


# --- Dates ----------------------------------------------------------------------

## "12 Spring": the day of its season and the season, the way a HOI4 row
## gives a date. A day more than 300 days ahead reads "Spring, year 9".
static func day_words(day:int)->String:
	if day<0:return ""
	var key:=floori((float(day)+45.625)/91.25)
	var start:=float(key)*91.25-45.625
	var hemisphere:=float((WorldSimulation.state.hearth_season as Dictionary).get("hemisphere",1.0))
	var season:String=SEASONS[posmod(key+(0 if hemisphere>=0.0 else 2),4)]
	if day-_today()>300:return "%s, year %d" % [season,day/365+1]
	return "%d %s" % [clampi(floori(float(day)-start)+1,1,92),season]


# --- Lines and bands ------------------------------------------------------------

static func lines(mc:Node=null)->Array[Dictionary]:
	mc=_host(mc)
	var out:Array[Dictionary]=[]
	var progress:Dictionary=mc.training_progress_snapshot()
	var today:=_today()
	for raw:Dictionary in mc.recruit_deploy.data.lines:
		out.append(line(mc,raw,progress,today))
	return out


static func line(mc:Node,raw:Dictionary,progress:Dictionary={},today:int=-1)->Dictionary:
	if today<0:today=_today()
	if progress.is_empty():progress=mc.training_progress_snapshot()
	var men:=0
	var arms:Array[String]=[]
	for entry:Dictionary in raw.get("entries",[]):
		men+=int(entry.get("count",0))
		var weapon:=String(entry.get("weapon","improvised"))
		if not arms.has(weapon):arms.append(weapon)
	var target:=int(raw.get("target_army",0))
	var target_name:=""
	if target!=0:
		var index:int=mc._field_army_index(target)
		target_name=Logistics.force_name(mc.field_armies[index]) if index>=0 else ""
	var bands:Array[Dictionary]=[]
	var slots:Array=raw.get("slots",[])
	for i in slots.size():bands.append(band(mc,raw,int(slots[i]),progress,today,i))
	var repeat:=bool(raw.get("repeat",false))
	return {"id":int(raw.id),"name":String(raw.get("name","Band")),"template_id":int(raw.get("template_id",0)),"men_per_band":men,"arms":arms,
		"in_training":slots.size(),"remaining":int(raw.get("remaining",0)),"count":slots.size()+int(raw.get("remaining",0)),"repeat":repeat,
		"paused":bool(raw.get("paused",false)),"priority":int(raw.get("priority",1)),"auto_deploy":bool(raw.get("auto_deploy",true)),
		"target_army":target,"target_name":target_name,"deployed":int(raw.get("deployed",0)),"bands":bands}


## One band in training: {slot, index, men, men_target, gear, gear_target,
## training (0..1), early, ready, days_left (-1 unknown), ready_day,
## gear_short, men_short, stalled, gear_missing:{item:count}, reasons}.
static func band(mc:Node,raw:Dictionary,slot:int,progress:Dictionary={},today:int=-1,index:int=0)->Dictionary:
	if today<0:today=_today()
	var id:=int(raw.id)
	var state:Dictionary=mc.recruit_deploy.status(id,slot)
	var jobs:Array[Dictionary]=mc.recruit_deploy.orders(id,slot)
	var entries:Array=raw.get("entries",[])
	var days:=0
	var reasons:Array[String]=[]
	var missing:Dictionary={}
	for job:Dictionary in jobs:
		var estimate:Dictionary=progress.get(int(job.get("id",-1)),{})
		var left:=int(estimate.get("estimated_days",-1))
		if left<0:days=-1
		elif days>=0:days=maxi(days,left)
		var reason:=String(estimate.get("reason",""))
		if reason!="" and reason!="Normal instruction pace" and not reasons.has(reason):reasons.append(reason)
		var weapon:=String(job.get("weapon","improvised"))
		var short:=maxi(0,int(mc._equipment_required_for(String(job.get("unit","levy")),int(job.get("count",0))))-int(job.get("reserved_equipment",0)))
		if short>0:missing[weapon]=int(missing.get(weapon,0))+short
	# A cohort that has not started (nobody free to call up yet) holds the band.
	if jobs.size()<entries.size():days=-1
	var men:=int(state.get("people",0))
	var men_target:=maxi(1,int(state.get("target",0)))
	var gear:=int(state.get("equipment",0))
	var gear_target:=maxi(1,int(state.get("equipment_required",0)))
	# Sets for recruits not yet called up are owed too.
	for entry_index in entries.size():
		var entry:Dictionary=entries[entry_index]
		var started:=false
		for job:Dictionary in jobs:
			if int(job.get("entry_index",-1))==entry_index:started=true
		if not started:
			var weapon:=String(entry.get("weapon","improvised"))
			missing[weapon]=int(missing.get(weapon,0))+int(mc._equipment_required_for(String(entry.get("unit","levy")),int(entry.get("count",0))))
	var training:=clampf(float(state.get("training",0.0)),0.0,1.0)
	var ready:=bool(state.get("ready",false))
	var gear_short:=gear<int(state.get("equipment_required",0))
	var waits_for_gear:=training>=1.0 and gear<int(state.get("current_equipment_required",0))
	var ready_day:=-1
	if ready:ready_day=today
	elif days>=0 and not waits_for_gear:ready_day=today+maxi(1,days)
	return {"slot":slot,"index":index,"line":id,"men":men,"men_target":men_target,"gear":gear,"gear_target":gear_target,"training":training,
		"early":bool(state.get("early",false)),"ready":ready,"days_left":days,"ready_day":ready_day,"gear_short":gear_short,"waits_for_gear":waits_for_gear,
		"men_short":men<int(state.get("target",0)),"stalled":days<0 and not ready,"gear_missing":missing,"reasons":reasons}


## Plain words for why a band's gear bar is short, for its tooltip:
## "Short 8 of Simple levy weapons · 2 in store · workshops make 1.5 a day".
static func gear_words(band_row:Dictionary,mc:Node=null,stock_rows:Dictionary={})->String:
	mc=_host(mc)
	var missing:Dictionary=band_row.get("gear_missing",{})
	if missing.is_empty():return "Every set issued: %d of %d." % [int(band_row.get("gear",0)),int(band_row.get("gear_target",0))]
	var parts:PackedStringArray=[]
	for item:String in missing:
		var row:Dictionary=stock_rows.get(item,{}) if stock_rows.has(item) else Logistics.row(item,mc)
		var making:=float(row.get("making_per_day",0.0))
		var line:="Short %d %s · %d in store" % [int(missing[item]),String(row.get("name",item)),int(row.get("stock",0))]
		line+=" · workshops make %s a day" % _rate(making) if making>0.0 else " · no workshop makes them"
		parts.append(line)
	return "\n".join(parts)+"\nClick to open production."


## The shared stock reading, keyed by item, for one refresh of the board.
static func stock_rows(mc:Node=null)->Dictionary:
	var out:={}
	for row:Dictionary in Logistics.rows(_host(mc)):out[String(row.item)]=row
	return out


static func _rate(value:float)->String:
	return ("%.1f" % value).trim_suffix(".0") if value<10.0 else str(roundi(value))


# --- Templates ------------------------------------------------------------------

## {id, name, men, entries:[{unit, weapon, count, unit_name, weapon_name}],
##  gear:{item:{need, stock}}, art, trainable, reason}
static func templates(mc:Node=null)->Array[Dictionary]:
	mc=_host(mc)
	var out:Array[Dictionary]=[]
	var art:=preload("res://scripts/hud/military_roster_visuals.gd")
	for raw:Dictionary in mc.army_template_snapshot().get("templates",[]):
		var men:=0
		var entries:Array[Dictionary]=[]
		var gear:={}
		var reason:=""
		for entry:Dictionary in raw.get("entries",[]):
			var unit:=String(entry.get("unit","levy"));var weapon:=String(entry.get("weapon","improvised"));var count:=int(entry.get("count",0))
			men+=count
			entries.append({"unit":unit,"weapon":weapon,"count":count,"unit_name":String(mc.UnitCatalog.archetype(unit).get("label",unit.replace("_"," ").capitalize())),"weapon_name":String(mc.PersistentProduction.product_name(weapon))})
			var slot:Dictionary=gear.get(weapon,{"need":0,"stock":int(mc.military_inventory.get(weapon,0))})
			slot.need=int(slot.need)+int(mc._equipment_required_for(unit,count))
			gear[weapon]=slot
			var gate:Dictionary=mc._training_gate(unit,weapon)
			if gate.has("error") and reason=="":reason=String(gate.error)
		if entries.is_empty():reason="Add men to this band first."
		var first:=String(entries[0].unit) if not entries.is_empty() else "levy"
		out.append({"id":int(raw.get("template_id",0)),"name":String(raw.get("name","Band")),"men":men,"entries":entries,"gear":gear,
			"art":art.illustration_path(first),"unit":first,"trainable":reason=="","reason":reason,"stats":template_stats(mc,entries)})
	return out


## What a band of this design does, by the engine's own rules, fully armed
## and drilled (HOI4's division designer, without the width puzzle):
## {strength, attack, defense, hard, armor, pierce, km_day, loads_man, bread,
##  stores, days, reinforce_days, machines}
## strength: the band's fighting power (combat_simulator: men x sqrt(attack x
## defense) per man, against an unarmoured foe on open ground).
static func template_stats(mc:Node,entries:Array)->Dictionary:
	var sim=mc.simulator
	var Ledger:=preload("res://scripts/equipment_ledger.gd")
	var formations:=[]
	var men:=0
	var machines:=0
	var days:=0.0
	var pace:=INF
	var stores:=0.0
	for entry:Dictionary in entries:
		var unit:=String(entry.get("unit","levy"));var weapon:=String(entry.get("weapon","improvised"));var count:=maxi(0,int(entry.get("count",0)))
		if count<=0:continue
		var sets:int=sim.equipment_required_for_weapon(weapon,count)
		formations.append({"id":formations.size()+1,"unit":unit,"weapon":weapon,"count":count,"authorized_count":count,"equipment":sets,"equipment_required":sets,"ammunition":sim.ammunition_required_for_weapon(weapon,sets,count),"training":0.8,"experience":0.0,"personnel_condition":1.0})
		men+=count
		if sim.is_machine(weapon):machines+=sets
		stores+=float(sets)*Ledger.supply(weapon)
		days=maxf(days,float(mc.UnitCatalog.training_days(unit)))
		pace=minf(pace,float(mc.UnitCatalog.archetype(unit).get("pace_km_day",24.0)))
	if men<=0:return {}
	var force:Dictionary=sim.create_formation_force("Design",formations,1.0,1.0)
	var cohorts:Array=sim.evaluate_force(force,{"formations":[]},1.0)
	var strength:=0.0;var attack:=0.0;var defense:=0.0;var hard:=0.0
	for i in cohorts.size():
		var c:Dictionary=cohorts[i]
		strength+=float(c.count)*sqrt(float(c.attack)*float(c.defense))
		attack+=float(c.count)*float(c.attack);defense+=float(c.count)*float(c.defense)
		hard+=float(c.count)*sim.kit_hardness(String(formations[i].weapon))
	var bread:=float(men)*1.12
	return {"strength":strength,"attack":attack/men,"defense":defense/men,"hard":hard/men,"armor":float(force.get("armor",0.0)),"pierce":float(force.get("penetration",0.0)),
		"km_day":pace if is_finite(pace) else 24.0,"loads_man":(bread+stores)/men,"bread":bread/men,"stores":stores/men,"days":days,"reinforce_days":maxf(3.0,days*0.58),"machines":machines}


## "Strength 210 · 24 km/day · 1.6 loads · 90 days" and its tooltip (the
## loads are per man per day).
static func stats_words(stats:Dictionary)->Array:
	if stats.is_empty():return ["",""]
	var line:="Strength %s · %d km/day · %s loads · %d days" % [EraWords.grouped(roundi(float(stats.strength))),roundi(float(stats.km_day)),("%.1f" % float(stats.loads_man)).trim_suffix(".0"),roundi(float(stats.days))]
	var tip:=PackedStringArray()
	tip.append("Strength %s: the band's fighting power, fully armed and drilled, on open ground (men × √(attack × defense) a man)." % EraWords.grouped(roundi(float(stats.strength))))
	tip.append("Each man: attack %.2f, defense %.2f." % [float(stats.attack),float(stats.defense)])
	if int(stats.machines)>0:tip.append("Machines: %d, run by the band's operators; they fight only with their machines." % int(stats.machines))
	if float(stats.hard)>0.01:tip.append("Armour: %d%% of the band is hard; blows that cannot pierce armour %.1f glance off it." % [roundi(float(stats.hard)*100.0),float(stats.armor)/maxf(0.01,float(stats.hard))])
	tip.append("Pierce %.1f: armour below this takes its blows in full." % float(stats.pierce))
	tip.append("Marches %d km a day on open level ground (its slowest arm)." % roundi(float(stats.km_day)))
	tip.append("Asks the supply line %.1f loads a man a day: bread %.1f, fodder, fuel and rounds %.1f." % [float(stats.loads_man),float(stats.bread),float(stats.stores)])
	tip.append("Trains in %d days; replacements train in %d." % [roundi(float(stats.days)),roundi(float(stats.reinforce_days))])
	return [line,"\n".join(tip)]
