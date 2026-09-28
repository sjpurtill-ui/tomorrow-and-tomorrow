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
static func gear_words(band_row:Dictionary,mc:Node=null)->String:
	mc=_host(mc)
	var missing:Dictionary=band_row.get("gear_missing",{})
	if missing.is_empty():return "Every set issued: %d of %d." % [int(band_row.get("gear",0)),int(band_row.get("gear_target",0))]
	var parts:PackedStringArray=[]
	for item:String in missing:
		var row:Dictionary=Logistics.row(item,mc)
		var making:=float(row.get("making_per_day",0.0))
		var line:="Short %d %s · %d in store" % [int(missing[item]),String(row.get("name",item)),int(row.get("stock",0))]
		line+=" · workshops make %s a day" % _rate(making) if making>0.0 else " · no workshop makes them"
		parts.append(line)
	return "\n".join(parts)+"\nClick to open production."


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
			"art":art.illustration_path(first),"unit":first,"trainable":reason=="","reason":reason})
	return out
