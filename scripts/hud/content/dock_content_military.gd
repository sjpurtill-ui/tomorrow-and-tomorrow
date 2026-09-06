extends "res://scripts/hud/content/dock_content_base.gd"
## MILITARY section: Formations / Army Builds / Supply.
## Army builds work like division templates: compose a build from unlocked
## unit types, train it as one order, deploy it as a field army, then command
## the army on the map (left-click select, right-click march, then click an
## observed enemy to intercept). Deep war decisions (fronts, threats,
## engagements, aftermath) open in War Planning.

var template_page:=0
var equipment_page:=0
var equipment_batch:=5

const UnitCatalog:=preload("res://scripts/military_unit_catalog.gd")

const UNIT_COLORS:Dictionary={
	"levy":Color("#8fa26a"),"line_infantry":Color("#79a8a0"),"skirmisher":Color("#a9946e"),
	"cavalry":Color("#c9a95a"),"siege_engineer":Color("#b39a68"),"field_artillery":Color("#c67462"),
	"rifle_infantry":Color("#8798b5"),"machine_gun_company":Color("#a897c9"),
	"motorized_infantry":Color("#d0b46f"),"armored_formation":Color("#766d72"),"modern_artillery":Color("#c67462"),
}

func meta()->Dictionary:
	return {
		"eyebrow":"MILITARY COMMAND",
		"title":"Watch & Field",
		"subtabs":["FORCES","RECRUIT & DEPLOY","TRAINING","SUPPLY"],
	}

func tab(sub:int)->Dictionary:
	var army:Dictionary=MilitaryCampaign.campaign_army_snapshot()
	var capabilities:Dictionary=MilitaryCampaign.military_capabilities()
	var troops:=maxi(0,int(army.get("troops",0)))
	var watch:=int(GameState.population_allocations.get("Defense",0))
	var mobilized:=MilitaryCampaign._mobilized_count()
	var mobilization_cap:=int(capabilities.get("recruitment_capacity",0))
	var organization:=clampf(float(army.get("readiness",0.0)),0.0,1.0)
	var upkeep:=float(army.get("provisions_required_today",0.0))
	var ledger:=MilitaryCampaign.personnel_ledger()
	var kpis:Array=[
		{"label":"TOTAL PERSONNEL","value":str(ledger.total),"live_value":func()->String: return str(MilitaryCampaign.personnel_ledger().total),"live_delta":func()->String: return "%d training" % int(MilitaryCampaign.personnel_ledger().training),"delta":"%d training" % int(ledger.training),"delta_color":Tokens.MUTED,"accent":Tokens.RED,"tip":"Everyone in military service, including reserves, trainees, deployed soldiers, and recovery pools. Deployment does not change this total."},
		{"label":"FIELD SOLDIERS","value":str(ledger.field),"live_value":func()->String: return str(MilitaryCampaign.personnel_ledger().field),"live_delta":func()->String: return "%d active armies" % MilitaryCampaign.field_armies.filter(func(force:Dictionary)->bool:return int(force.get("troops",0))>0).size(),"delta":"%d active armies" % MilitaryCampaign.field_armies.filter(func(force:Dictionary)->bool:return int(force.get("troops",0))>0).size(),"delta_color":Tokens.MUTED,"accent":Tokens.BLUE,"tip":"Deployed maneuver armies vs command capacity"},
		{"label":"READINESS","value":"%d%%" % roundi(organization*100.0),"live_value":func()->String: return "%d%%" % roundi(float(MilitaryCampaign.home_army.get("readiness",0))*100),"delta":"","accent":Tokens.AMBER,"tip":"Organization and condition of the home force"},
		{"label":"UPKEEP","value":"%.1f" % upkeep,"live_value":func()->String: return "%.1f" % float(MilitaryCampaign.campaign_army_snapshot().get("provisions_required_today",0)),"delta":"rations/day","delta_color":Tokens.MUTED,"accent":Tokens.TEAL,"tip":"Daily provision cost of everyone under arms"},
	]
	var brief:Dictionary=_command_brief()
	match sub:
		1: return {"kpis":[kpis[0],kpis[1]],"blocks":_builds_blocks(capabilities)}
		2: return {"kpis":kpis,"brief":brief,"blocks":_training_blocks()}
		3: return {"kpis":[kpis[3]],"blocks":_supply_overview()}
	return {"kpis":[kpis[0],kpis[1]],"brief":brief,"blocks":_forces_overview()}

func _command_brief()->Dictionary:
	if not MilitaryCampaign.pending_aftermath.is_empty() and not MilitaryCampaign.battle_history.is_empty():
		var battle:Dictionary=MilitaryCampaign.battle_history[0]
		return {"tone":"warn","title":"Battle finished · review the aftermath","why":MilitaryCampaign.city_force_summary(String(battle.get("target_region_id",""))),"action_label":"REVIEW AFTERMATH","on_action":func():terrain._open_war_planning()}
	if not MilitaryCampaign.threat_snapshot().is_empty() or not MilitaryCampaign.engagement_snapshot().is_empty() or not MilitaryCampaign.pending_aftermath.is_empty():
		return {"tone":"danger","title":"A war decision awaits","why":"A threat, battle, or aftermath needs your order.","action_label":"WAR PLANNING","on_action":func()->void: terrain._open_war_planning()}
	if MilitaryCampaign.field_armies.is_empty() and int(MilitaryCampaign.campaign_army_snapshot().get("troops",0))<=0:
		return {"tone":"info","title":"No field force exists","why":"Compose an army build, train it as one order, then deploy it. Every soldier is absent from food and construction."}
	return {"tone":"info","title":"How to engage from the map","why":"SCOUTS: click their counter and choose CAPTURE or ATTACK. ENEMY ARMIES: select your field army, click the red enemy counter, then choose MOVE TO INTERCEPT. Battle opens automatically at contact.","action_label":"WAR PLANNING","on_action":func()->void: terrain._open_war_planning()}

func _unit_label(unit:String)->String:
	return unit.replace("_"," ").capitalize()

# --- FORMATIONS -------------------------------------------------------------

func _formation_blocks(army:Dictionary)->Array:
	var blocks:Array=[_personnel_block()]
	var snapshot:Dictionary=MilitaryCampaign.field_armies_snapshot()
	var live_reports:=bool(snapshot.get("live_reports",true))
	var army_items:Array=[]
	for force_variant in (snapshot.get("armies",[]) as Array):
		var force:Dictionary=force_variant
		if int(force.get("troops",0))<=0:continue
		var army_id:=int(force.get("army_id",0))
		var at_home:=String(force.get("status","stationed"))=="stationed" and String(force.get("location_id",""))=="player_home"
		var report:Dictionary=force.get("last_report",{})
		var use_report:=not live_reports and not at_home and not report.is_empty()
		var shown_troops:=int(report.get("troops",force.get("troops",0))) if use_report else int(force.get("troops",0))
		var shown_supply:=roundi((float(report.get("supply_level",1.0)) if use_report else float(force.get("supply_level",1.0)))*100.0)
		var report_age:=maxi(0,int(GameState.elapsed_days)-int(report.get("day",GameState.elapsed_days))) if use_report else 0
		var status_text:String
		if at_home: status_text="at home"
		elif use_report:
			status_text="reported %s" % ("marching on %s" % String(report.get("destination_name","its objective")) if String(report.get("status",""))=="moving" else "holding %s" % String(report.get("location_name","the field")))
			status_text+=" · runner %dd old" % report_age
		else:
			status_text="moving to %s" % String(force.get("destination_name","")) if String(force.get("status",""))=="moving" else "holding %s" % String(force.get("location_name",""))
		var selected:bool=int(terrain.selected_army_id)==army_id
		army_items.append({
			"name":String(force.get("name","FIELD ARMY"))+(" ◈" if selected else ""),
			"sub":"%s · supply %d%%" % [status_text,shown_supply],
			"value":"%d soldiers" % shown_troops,"value_color":Tokens.GOLD if selected else Tokens.BODY_2,
			"accent":Tokens.GOLD if selected else Tokens.BLUE,
			"on_click":func()->void: terrain._select_army_and_focus(army_id),
			"tip":"Click to select this army on the map. Right-click charted land for a normal march; click a red enemy counter to order an intercept. Reports travel home by runner until signal-era development.",
		})
	if army_items.is_empty():
		blocks.append({"type":"text","heading":"FIELD ARMIES","text":"No army is deployed. Compose and train a build in ARMY BUILDS, then deploy it."})
	else:
		blocks.append({"type":"rows","heading":"FIELD ARMIES · CLICK TO SHOW ON MAP","note":"new armies assemble at home","items":army_items})
		var selected_active:bool=int(terrain.selected_army_id)!=-1
		blocks.append({"type":"actions","items":[
			{"label":"RETURN SELECTED","sub":"march it home","disabled":not selected_active,
			"on_press":func()->void: terrain._report_military_action(MilitaryCampaign.return_field_army(terrain.selected_army_id)),
			"tip":"Order the selected army back to the settlement"},
			{"label":"DISBAND SELECTED","sub":"must be at home","disabled":not selected_active,
			"on_press":func()->void: terrain._report_military_action(MilitaryCampaign.disband_field_army(terrain.selected_army_id)),
			"tip":"Dissolve the selected army into the home force (only while stationed at home)"},
		]})
	var garrisons:Array=[]
	for force:Dictionary in MilitaryCampaign.occupation_forces:
		if int(force.get("troops",0))<=0:continue
		var owner:=String(force.civ_id);var region:=String(force.region_id)
		garrisons.append({"name":String(force.get("region_name","Occupied settlement")),"value":"%d soldiers" % int(force.troops),"sub":"Occupation garrison · click to manage","on_click":func():preload("res://scripts/hud/occupation_view.gd").open(owner,region)})
	if not garrisons.is_empty():blocks.append({"type":"rows","heading":"YOUR GARRISONS","items":garrisons})
	for force:Dictionary in MilitaryCampaign.field_armies:
		if int(force.get("troops",0))>0:continue
		blocks.append({"type":"text","heading":String(force.get("name","Former field force")),"text":"No active field soldiers. %d scattered, %d wounded, %d recorded killed. Recovery records are retained; occupation soldiers appear above." % [int(force.get("scattered_pool",0)),int(force.get("wounded_pool",0)),int(force.get("dead",0))]})
	var formation_items:Array=[]
	for formation_variant in MilitaryCampaign.grouped_home_formations(army):
		var formation:Dictionary=formation_variant
		var unit:=String(formation.get("unit","levy"))
		var band:=UnitCatalog.readiness_band(formation)
		formation_items.append({
			"name":"%s%s · %s" % ["PROTOTYPE " if bool(formation.get("prototype",false)) else "",_unit_label(unit),String(formation.get("weapon","improvised")).replace("_"," ")],
			"sub":"%s · drill skill %d%% · condition %d%%" % [band,roundi(float(formation.get("training",0.0))*100.0),roundi(float(formation.get("personnel_condition",1.0))*100.0)],
			"value":"%d soldiers" % int(formation.get("count",0)),
			"value_color":Tokens.BODY_2,
			"accent":UNIT_COLORS.get(unit,Tokens.MUTED),
			"tip":"Completed instruction; drill skill is proficiency, not unfinished course progress. Equipment %d of %d · ammunition %d of %d" % [int(formation.get("equipment",0)),int(formation.get("equipment_required",0)),int(formation.get("ammunition",0)),int(formation.get("ammunition_required",0))],
		})
	if formation_items.is_empty():
		blocks.append({"type":"text","heading":"HOME FORCE","text":"No trained formations are at home. Train an army build to create them."})
	else:
		blocks.append({"type":"rows","heading":"HOME FORCE","note":"grouped by unit and equipment","items":formation_items})
	var releasable:=maxi(0,int(army.get("troops",0)))+maxi(0,MilitaryCampaign.aggregate_recruits)
	if releasable>0:
		blocks.append({"type":"actions","items":[
			{"label":"STAND DOWN 10","sub":"release to labor",
			"on_press":func()->void: terrain._report_military_action(MilitaryCampaign.demobilize(10)),
			"tip":"Return up to 10 recruits or home troops to the civilian labor pool; their equipment goes back to stores"},
			{"label":"STAND DOWN ALL","sub":"disband the home force",
			"on_press":func()->void: terrain._report_military_action(MilitaryCampaign.demobilize(releasable)),
			"tip":"Return every recruit and home formation to the civilian labor pool; equipment goes back to stores. Field armies are untouched."},
		]})
	var defense:Dictionary=MilitaryCampaign.settlement_defense_snapshot()
	blocks.append({"type":"tiles","heading":"SETTLEMENT DEFENSE","items":[
		{"label":"WORKS","value":String(defense.get("short","Open ground")),"note":"integrity %d%%" % roundi(float(defense.get("integrity",0.0))*100.0),"note_color":Tokens.RED if float(defense.get("integrity",0.0))<0.4 else Tokens.MUTED,"tip":String(defense.get("description",""))},
		{"label":"LOOKOUT","value":"%.0f km" % float(defense.get("observation_radius_km",0.0)),"note":"observation reach","note_color":Tokens.MUTED,"tip":"How far approaching forces are seen"},
		{"label":"GARRISON","value":"%d/%d" % [int(defense.get("garrison_personnel",0)),int(defense.get("garrison_required",0))],"note":"%d trained · %d militia" % [int(defense.get("garrison_trained",0)),int(defense.get("garrison_militia",0))],"note_color":Tokens.GREEN if float(defense.get("garrison_coverage",0.0))>=1.0 else Tokens.AMBER,"tip":"The local Defense allocation always mans the watch and receives automatic basic training. Advanced formations and exercises remain under your control."},
		{"label":"STORES","value":"%d%%" % roundi(float(MilitaryCampaign.store_protection().get("total",MilitaryCampaign.store_protection().get("protection",0.0)))*100.0),"note":"protected share","note_color":Tokens.MUTED,"tip":"Share of the food reserve protected from raids"},
	]})
	return blocks

# --- ARMY BUILDS ------------------------------------------------------------

func _builds_blocks(capabilities:Dictionary,template_filter:int=-1,step:int=0)->Array:
	if template_filter<0:return _build_roster()
	var blocks:Array=[]
	if step==2 and not MilitaryCampaign.field_armies.is_empty():
		blocks.append({"type":"actions","items":[{"label":"FIND YOUR ARMIES","sub":"open the deployed force roster","on_press":jump("military",0)}]})
	var snapshot:Dictionary=MilitaryCampaign.army_template_snapshot()
	var explanation:=["Choose the unit types and target headcounts. This changes a design; it does not recruit people or create soldiers. All designs draw from the same home reserve.","One order prepares a full class, combining matching home soldiers with missing recruits. Training takes time; repeating the order never duplicates people.","Deploy moves the assembled soldiers from the shared home reserve into a field army at home. It does not march or attack. Review condition and supplies before giving a destination on the map."]
	blocks.append({"type":"text","text":explanation[clampi(step,0,2)]})

	var units:Dictionary=capabilities.get("units",{})
	var unit_equipment:Dictionary=capabilities.get("unit_equipment",{})
	for template_variant in (snapshot.get("templates",[]) as Array):
		var template:Dictionary=template_variant
		var template_id:=int(template.get("template_id",0))
		if template_id!=template_filter:continue
		var entry_items:Array=[]
		for entry_variant in (template.get("entries",[]) as Array):
			var entry:Dictionary=entry_variant
			var unit:=String(entry.get("unit","levy"))
			var weapon:=String(entry.get("weapon","improvised"))
			entry_items.append({
				"name":"%s · %s" % [_unit_label(unit),weapon.replace("_"," ")],
				"count":int(entry.get("count",0)),
				"pct":"%d/%d at home" % [int(entry.get("ready",0)),int(entry.get("count",0))],
				"live_pct":func()->String: return _entry_status(template_id,unit,weapon),
				"color":UNIT_COLORS.get(unit,Tokens.MUTED),
				"tip":"%d assembled at home · %d in training · target %d; assembled does not mean combat-ready" % [int(entry.get("ready",0)),int(entry.get("in_training",0)),int(entry.get("count",0))],
				"on_minus":func()->void: terrain._report_military_action(MilitaryCampaign.adjust_template_entry(template_id,unit,weapon,-1)),
				"on_plus":func()->void: terrain._report_military_action(MilitaryCampaign.adjust_template_entry(template_id,unit,weapon,1)),
			})
		if step!=0:
			for entry:Dictionary in entry_items:entry.erase("on_minus");entry.erase("on_plus")
		var deployable:=bool(template.get("deployable",false))
		var ready_note:="%d of %d assembled" % [int(template.get("ready_total",0)),int(template.get("required_total",0))]
		if int(template.get("in_training_total",0))>0: ready_note+=" · %d in training" % int(template.get("in_training_total",0))
		ready_note+=" · %d unfilled" % int(template.get("unfilled",0))
		if step==1:
			var quote:=MilitaryCampaign.template_training_quote(template_id)
			var requirements:="Full class: %d soldiers; at least %.0f food rations in stores."%[int(quote.get("required",0)),float(quote.get("food",0))]
			var blockers:Array=quote.get("blockers",[])
			if not blockers.is_empty():requirements+="\n"+String(blockers[0])+ (" Additional shortages: %d."%(blockers.size()-1) if blockers.size()>1 else "")
			blocks.append({"type":"text","heading":"BEFORE RECRUITMENT","text":requirements})
			blocks.append({"type":"text","heading":"YOUR ORDER","text":("Recruitment ordered. " if bool(template.get("recruitment_requested",false)) else "Recruitment not ordered. ")+("Recruit & Train starts this class now." if bool(quote.get("can_start",false)) else "Recruit & Train records a waiting order; no new soldiers enter until the shortages are resolved.")})
		elif step==2:
			var availability:=MilitaryCampaign.template_deployment_availability(template_id)
			blocks.append({"type":"text","heading":"DEPLOYMENT","text":String(availability.get("error","The required soldiers are assembled at home. Deployment transfers them into one field army; it does not duplicate the reserve."))})
		if entry_items.is_empty():
			blocks.append({"type":"text","heading":"BUILD · %s" % String(template.get("name","BUILD")),"note":"shared reserve","text":"Empty build — add cohorts below."})
		else:
			blocks.append({"type":"alloc","heading":"BUILD · %s" % String(template.get("name","BUILD")),"note":"shared reserve","items":entry_items})
		if step!=1:blocks.append({"type":"text","text":_build_status(template_id),"live_text":func()->String: return _build_status(template_id)})
		var command_items:Array=[
			{"label":"RECRUIT & TRAIN","sub":"Start full class" if bool(MilitaryCampaign.template_training_quote(template_id).get("can_start",false)) else "Record a waiting order","primary":not deployable and int(template.get("required_total",0))>0,
			"on_press":func()->void: terrain._report_military_action(MilitaryCampaign.queue_template_training(template_id)),
			"tip":"One order: raise the missing recruits and queue typed training for every under-strength cohort"},
			{"label":"DEPLOY %d SOLDIERS" % int(template.get("required_total",0)),"sub":"%d remain in reserve" % maxi(0,int(MilitaryCampaign.home_army.get("troops",0))-int(template.get("required_total",0))),"primary":deployable,"disabled":not deployable,
			"on_press":func()->void: _deploy_build(template_id),
			"tip":String(MilitaryCampaign.template_deployment_availability(template_id).get("error","Form this army at home and show it on the map.")),
			"live_disabled":func()->bool: return MilitaryCampaign.template_deployment_availability(template_id).has("error"),
			"live_tip":func()->String: return String(MilitaryCampaign.template_deployment_availability(template_id).get("error","Form this army at home and show it on the map.")),
			"live_sub":func()->String: return _build_status(template_id)},
			{"label":"DELETE BUILD","sub":"remove the design",
			"on_press":func()->void: terrain._report_military_action(MilitaryCampaign.delete_army_template(template_id)),
			"tip":"Delete this build (armies already deployed keep their troops)"},
		]
		# §18.1: an UNDERSTOOD unit offers one experimental cohort — exceptional
		# cost, bounded size — before the practice is established.
		for unit_variant in units:
			var proto_unit:=String(unit_variant)
			var proto_gate:Dictionary=units[proto_unit] if units[proto_unit] is Dictionary else {}
			var capability:Dictionary=proto_gate.get("capability",{})
			if not bool(capability.get("can_prototype",false)): continue
			var proto_weapons:Array=unit_equipment.get(proto_unit,["improvised"])
			var proto_weapon:=String(proto_weapons[0]) if not proto_weapons.is_empty() else "improvised"
			command_items.append({
				"label":"PROTOTYPE %s" % _unit_label(proto_unit).to_upper(),"sub":"experimental cohort of 8",
				"on_press":func()->void: terrain._report_military_action(MilitaryCampaign.start_training(proto_unit,proto_weapon,8)),
				"tip":"The principle is understood but not yet established practice. Raise one experimental cohort at %.1f× training time; its service spreads the practice." % MilitaryCampaign.PROTOTYPE_TRAINING_MULTIPLIER,
			})
			break
		if bool(template.get("recruitment_requested",false)):
			command_items.append({"label":"STOP RECRUITMENT","sub":"keep current soldiers","on_press":func()->void:terrain._report_military_action(MilitaryCampaign.cancel_template_recruitment(template_id))})
		var added:=0
		for unit_variant in units:
			if added>=3: break
			var unit_id:=String(unit_variant)
			var gate:Dictionary=units[unit_id] if units[unit_id] is Dictionary else {}
			if not bool(gate.get("unlocked",false)): continue
			var already:=false
			for entry_variant in (template.get("entries",[]) as Array):
				if String((entry_variant as Dictionary).get("unit",""))==unit_id: already=true; break
			if already: continue
			var weapons:Array=unit_equipment.get(unit_id,["improvised"])
			var weapon_id:=String(weapons[0]) if not weapons.is_empty() else "improvised"
			added+=1
			command_items.append({
				"label":"+10 %s" % _unit_label(unit_id).to_upper(),"sub":weapon_id.replace("_"," "),
				"on_press":func()->void: terrain._report_military_action(MilitaryCampaign.adjust_template_entry(template_id,unit_id,weapon_id,10)),
				"tip":"Add a %s cohort to this build" % _unit_label(unit_id),
			})
		var focused:Array=[]
		for command:Dictionary in command_items:
			var label:=String(command.label)
			if (step==0 and (label=="DELETE BUILD" or label.begins_with("+10"))) or (step==1 and not label.begins_with("DEPLOY") and label!="DELETE BUILD" and not label.begins_with("+10")) or (step==2 and label.begins_with("DEPLOY")):focused.append(command)
		if step==1:focused.append(focused_action("REQUIREMENTS & NEXT STEPS","See each shortage and how to address it",_recruitment_requirements.bind(template_id)))
		blocks.append({"type":"actions","items":focused})

	var queue_items:Array=[]
	for order_variant in (MilitaryCampaign.campaign_army_snapshot().get("training_queue",[]) as Array):
		var order:Dictionary=order_variant
		var order_id:=int(order.get("id",0))
		queue_items.append({
			"name":"%s · %s ×%d" % [_unit_label(String(order.get("unit","levy"))),String(order.get("weapon","improvised")).replace("_"," "),int(order.get("count",0))],
			"sub":_training_status(order_id),
			"live_sub":func()->String: return _training_status(order_id),
			"detail":_training_reason(order_id),
			"live_detail":func()->String: return _training_reason(order_id),
			"live_value":func()->String: return _training_percent(order_id),
			"value":"%d%%" % roundi(float(order.get("progress_days",0))/maxf(1.0,float(order.get("required_days",1)))*100.0),
			"value_color":Tokens.AMBER,"accent":Tokens.AMBER,
			"tip":"Surviving trainees join the home reserve. Injured trainees enter recovery, then return to the recruit reserve. Instruction days can take longer with crowded classes or missing equipment.",
		})
	if step==1 and not queue_items.is_empty():
		blocks.append({"type":"rows","heading":"IN TRAINING","items":queue_items})
	return blocks

# --- SUPPLY -----------------------------------------------------------------

func _supply_blocks(army:Dictionary,capabilities:Dictionary)->Array:
	var inventory:Dictionary=army.get("military_inventory",{})
	var carts:=int(GameState.resource_stockpiles.get("Transport Carts",0))
	var delivery:=clampf(MilitaryCampaign.field_provision_delivery_ratio(),0.0,1.0)
	var reputation:Dictionary=MilitaryCampaign.war_reputation_snapshot()
	var damaged:Dictionary=army.get("damaged_equipment",{})
	var damaged_total:=0
	for item in damaged: damaged_total+=int(damaged[item])
	var runner_note:="runners carry reports" if not bool(MilitaryCampaign.field_armies_snapshot().get("live_reports",true)) else "live signal reports"
	var tiles:Array=[
		{"label":"TRANSPORT CARTS","value":str(carts),"note":"extend carrying reach" if carts>0 else "carriers only","note_color":Tokens.GREEN if carts>0 else Tokens.RED,"tip":"Carts extend how far provisions can flow"},
		{"label":"FIELD SUPPLY","value":"%d%%" % roundi(delivery*100.0) if MilitaryCampaign.field_army_active_personnel()>0 else "—","note":"ration needs delivered" if MilitaryCampaign.field_army_active_personnel()>0 else "no deployed armies","note_color":Tokens.GREEN if delivery>=0.99 else Tokens.AMBER,"tip":"Share of required field provisions actually delivered"},
		{"label":"DAMAGED GEAR","value":str(damaged_total),"note":"awaiting repair","note_color":Tokens.AMBER if damaged_total>0 else Tokens.MUTED,"tip":"Equipment recoverable through repair work"},

	]
	var blocks:Array=[{"type":"tiles","heading":"SUPPLY","items":tiles}]
	var job_items:Array=[]
	for job_variant in (army.get("equipment_queue",[]) as Array):
		var job:Dictionary=job_variant
		job_items.append({
			"name":"%s ×%d" % [String(job.get("item","gear")).replace("_"," ").capitalize(),int(job.get("count",0))],
			"sub":"%d / %d finished · %.2f / %.2f workshop work-days" % [int(job.get("completed",0)),int(job.get("count",0)),float(job.get("progress_days",0)),float(job.get("required_days",1))],
			"value":"","accent":Tokens.GOLD,
			"tip":"Work-days measure production effort, not elapsed calendar time. Click to review the line.","on_click":func():_open_workshop_job(int(job.id)),
		})
	if not job_items.is_empty():
		blocks.append({"type":"rows","heading":"WORKSHOP LINES","items":job_items})
	var repair_items:Array=[]
	for item in damaged:
		if int(damaged[item])<=0 or repair_items.size()>=2: continue
		var item_id:=String(item)
		var item_count:=int(damaged[item])
		repair_items.append({
			"label":"REPAIR %s" % item_id.replace("_"," ").to_upper(),"sub":"×%d damaged" % item_count,"primary":true,
			"on_press":func()->void:var action:=focused_action("REPAIR "+item_id.replace("_"," ").to_upper(),"",_supply_order_report.bind("repair",item_id));action.on_press.call(),
			"tip":"Queue repair work; costs far less than new production",
		})
	repair_items.append({
		"label":"BUILD CARTS","sub":"review materials and workshop time",
		"on_press":func()->void:var action:=focused_action("BUILD CARTS","",_supply_order_report.bind("transport","transport_cart"));action.on_press.call(),
		"tip":"Queue transport cart production on a workshop line",
	})
	blocks.append({"type":"actions","items":repair_items})
	blocks.append({"type":"text","text":"Missions take their provisions at departure. Field forces are supplied only as far as carts and carriers reach; each army's runners consume nothing but carry everything you know."})
	return blocks

func signature()->Array:
	var army:Dictionary=MilitaryCampaign.campaign_army_snapshot()
	var template_state:Array=[]
	for template_variant in MilitaryCampaign.army_templates:
		var template:Dictionary=template_variant
		template_state.append([int(template.get("template_id",0)),(template.get("entries",[]) as Array).duplicate(true)])
	return [int(army.get("troops",0)),int(army.get("recruits",0)),MilitaryCampaign.field_armies.size(),(army.get("training_queue",[]) as Array).size(),template_state,terrain.selected_army_id,MilitaryCampaign._mobilized_count(),MilitaryCampaign.training_program.duplicate(true),MilitaryCampaign.training_queue.duplicate(true),MilitaryCampaign.command_development.duplicate(true),MilitaryCampaign.military_inventory.duplicate(true),MilitaryCampaign.military_consumables.duplicate(true),MilitaryCampaign.damaged_equipment.duplicate(true),MilitaryCampaign.equipment_queue.duplicate(true),GameState.resource_stockpiles.duplicate(true),equipment_batch,equipment_page,int(GameState.elapsed_days)]

func _deploy_build(template_id:int)->void:
	var result:=MilitaryCampaign.deploy_army_from_template(template_id)
	terrain._report_military_action(result)
	if result.has("ok"):
		terrain._select_army_and_focus(int(result.army.army_id))
	hud.request_immediate_dock_refresh()

func _personnel_block()->Dictionary:
	return {"type":"text","heading":"WHERE YOUR SOLDIERS ARE","text":_personnel_text(),"live_text":_personnel_text}

func _personnel_text()->String:
	var ledger:=MilitaryCampaign.personnel_ledger()
	return "%d total = %d home reserve + %d in field armies + %d occupation + %d recruits + %d in training + %d recovering + %d missing or captured.\nDefense workers are a labor allocation, not additional soldiers." % [ledger.total,ledger.home,ledger.field,ledger.occupation,ledger.recruits,ledger.training,ledger.recovering,ledger.missing]

func _training_blocks()->Array:
	var state:=MilitaryCampaign.training_program_snapshot()
	var active:Dictionary=state.active
	var participants:=MilitaryCampaign.exercise_personnel()
	var blocks:Array=[_personnel_block(),{"type":"text","heading":"IMPROVE EXISTING SOLDIERS","text":"%d trained soldiers can exercise here: home reserves and field armies stationed at home. Marching and distant armies do not attend. Exercises improve skills; they do not recruit more people. Command practice is shared across unit types and future formations." % participants}]
	var skills:Array=[]
	var descriptions:Dictionary={"command":"coordination and orders","tactics":"combat decisions","logistics":"supply and recovery","resolve":"holding morale under pressure"}
	for skill in descriptions:
		skills.append({"name":String(skill).capitalize(),"sub":descriptions[skill],"value":"+%.1f / 30" % (float(state.command_development.get(skill,0.0))*100.0),"live_value":func()->String: return "+%.1f / 30" % (float(MilitaryCampaign.command_development.get(skill,0))*100),"accent":Tokens.TEAL})
	blocks.append({"type":"rows","heading":"SHARED COMMAND SKILLS","items":skills})
	if not active.is_empty():
		blocks.append({"type":"text","heading":String(active.label),"text":"%d attending · %.1f / %.0f effective days · %.1f extra rations used. %s" % [int(active.participants),float(active.progress_days),float(active.duration_days),float(active.food_consumed_total),String(active.paused_reason)]})
		blocks.append({"type":"actions","items":[{"label":"CANCEL EXERCISE","on_press":func()->void: terrain._report_military_action(MilitaryCampaign.cancel_training_program())}]})
	for id in state.catalog:
		var program:Dictionary=state.catalog[id]
		var gains:Array[String]=[]
		for skill in program.command_gain: gains.append("%s +%.1f" % [String(skill).capitalize(),float(program.command_gain[skill])*100.0])
		var attendees:=MilitaryCampaign._training_program_participants(program)
		blocks.append({"type":"text","heading":String(program.label),"text":"%s\n%s · formation training +%.1f points.\n%d attending · %.0f effective days · %.2f extra rations/day · fatigue and equipment wear apply.%s" % [program.description,", ".join(gains),float(program.training_gain)*100.0,attendees,float(program.duration_days),attendees*float(program.food_per_participant),"" if bool(program.unlocked) else "\n"+String(program.reason)]})
		var program_id:=String(id)
		blocks.append({"type":"actions","items":[{"label":"START "+String(program.label),"disabled":not active.is_empty() or not bool(program.unlocked),"on_press":func()->void: terrain._report_military_action(MilitaryCampaign.start_training_program(program_id))}]})
	return blocks

func _build_status(template_id:int)->String:
	for item:Dictionary in MilitaryCampaign.army_template_snapshot().templates:
		if int(item.template_id)==template_id:
			return "%d at home + %d training + %d unfilled = %d target" % [item.ready_total,item.in_training_total,item.unfilled,item.required_total]
	return "Build removed"

func _training_status(order_id:int)->String:
	var item:Dictionary=MilitaryCampaign.training_progress_snapshot().get(order_id,{})
	if item.is_empty(): return "Training finished — check home reserve and recovery"
	var estimate:=int(item.estimated_days)
	return "%s · %.1f / %.1f instruction days" % [("about %d calendar days left" % estimate) if estimate>=0 else "Training stalled",item.progress,item.required]

func _training_reason(order_id:int)->String:
	var item:Dictionary=MilitaryCampaign.training_progress_snapshot().get(order_id,{})
	if item.is_empty(): return "Injured trainees recover separately; ready soldiers can deploy."
	return "%s · %d injured, recovering separately. Estimate changes with capacity and equipment." % [item.reason,item.injured]

func _training_percent(order_id:int)->String:
	var item:Dictionary=MilitaryCampaign.training_progress_snapshot().get(order_id,{})
	return "%d%%" % int(item.percent) if not item.is_empty() else "DONE"

func _entry_status(template_id:int,unit:String,weapon:String)->String:
	for item:Dictionary in MilitaryCampaign.army_template_snapshot().templates:
		if int(item.template_id)!=template_id: continue
		for entry:Dictionary in item.entries:
			if entry.unit==unit and entry.weapon==weapon:
				return "%d at home + %d training + %d unfilled = %d target" % [entry.ready,entry.in_training,entry.unfilled,entry.count]
	return "Removed"

func _build_roster()->Array:
	var templates:Array=MilitaryCampaign.army_template_snapshot().templates
	template_page=clampi(template_page,0,maxi(0,(templates.size()-1)/4))
	var items:Array=[]
	for template:Dictionary in templates.slice(template_page*4,template_page*4+4):
		var id:=int(template.template_id)
		items.append({"label":String(template.name),"sub":"%d target · %d assembled at home"%[int(template.required_total),int(template.ready_total)],"on_press":func()->void:_open_build(id)})
	return [{"type":"text","heading":"PREPARE AN ARMY","text":"Open a design, choose its composition, recruit and train, then deploy. A design is a plan; soldiers are real people drawn from your settlement and shared home reserve."},{"type":"actions","heading":"CHOOSE A DESIGN","items":items},{"type":"actions","items":[{"label":"NEW DESIGN","sub":"Create an empty army plan","disabled":templates.size()>=8,"on_press":func()->void:
		var result:=MilitaryCampaign.create_army_template()
		if result.has("error"):terrain._report_military_action(result)
		else:_open_build(int(result.template.template_id))},{"label":"OTHER DESIGNS","sub":"Page %d / %d"%[template_page+1,maxi(1,ceili(templates.size()/4.0))],"disabled":templates.size()<=4,"on_press":func():template_page=(template_page+1)%maxi(1,ceili(templates.size()/4.0));hud.request_immediate_dock_refresh()}]}]

func _open_build(id:int)->void:
	hud.open_detail(preload("res://scripts/hud/content/army_preparation.gd").new(terrain,hud,self,id))

func _forces_overview()->Array:
	return [{"type":"actions","heading":"COMMAND","items":[{"label":"PREPARE AN ARMY","sub":"Compose, recruit, train and deploy","primary":true,"on_press":jump("military",1)},focused_action("FIELD ARMIES","Select an army and give map orders",_force_report.bind("field")),focused_action("HOME RESERVE","Condition, equipment and standing down",_force_report.bind("home")),focused_action("CITY GARRISONS","Occupation forces and their control",_force_report.bind("garrisons")),focused_action("HOME DEFENSE","Watch, fortifications and protected stores",_force_report.bind("defense")),focused_action("PERSONNEL ACCOUNT","Every military person, counted once",func()->Dictionary:return {"blocks":[_personnel_block()]})]},
		{"type":"text","heading":"SIZE MATTERS","text":"A small force can patrol or fight another small force. Occupying a city needs enough supplied, ready soldiers to hold its population; a siege also needs coverage of the approaches. Winning a fight alone does not grant control."}]

func _force_report(kind:String)->Dictionary:
	var blocks:=_formation_blocks(MilitaryCampaign.campaign_army_snapshot())
	var chosen:Array=[];var section:="field"
	for block:Dictionary in blocks:
		var heading:=String(block.get("heading",""))
		if heading=="WHERE YOUR SOLDIERS ARE":continue
		if heading=="YOUR GARRISONS":section="garrisons"
		elif heading=="HOME FORCE":section="home"
		elif heading=="SETTLEMENT DEFENSE":section="defense"
		elif String(block.get("text","")).begins_with("No active field soldiers."):section="field"
		if section==kind:chosen.append(block)
	if chosen.is_empty():chosen.append({"type":"text","text":"No forces are recorded here yet. Prepare and deploy an army before assigning it to a city."})
	return {"blocks":chosen}

func _supply_overview()->Array:
	return [{"type":"text","heading":"KEEP THE FORCE EQUIPPED","text":"Training and deployment draw on real equipment and provisions. Workshop orders reserve materials now and finish over time; a queued order is not usable gear."},{"type":"actions","items":[focused_action("MAKE EQUIPMENT","Choose a type, quantity and material cost",_equipment_catalog),focused_action("MAKE AMMUNITION","Arrows, cartridges and artillery rounds",_ammunition_catalog),focused_action("WORKSHOP & TRANSPORT","Existing jobs, repairs and carrying capacity",func()->Dictionary:return {"blocks":_supply_blocks(MilitaryCampaign.campaign_army_snapshot(),MilitaryCampaign.military_capabilities())}),focused_action("CONDUCT IN WAR","Mercy, fear and grievance explained",_reputation_report),{"label":"CIVILIAN STORES","sub":"Materials available for production","on_press":jump("economy",1)}]}]

func _equipment_catalog()->Dictionary:
	var names:Array=MilitaryCampaign.EQUIPMENT_KNOWLEDGE.keys()
	equipment_page=clampi(equipment_page,0,maxi(0,(names.size()-1)/4))
	var items:Array=[]
	for key:String in names.slice(equipment_page*4,equipment_page*4+4):
		items.append(focused_action(key.replace("_"," ").to_upper(),"%d equipment sets in store"%int(MilitaryCampaign.military_inventory.get(key,0)),_equipment_order_report.bind(key)))
	return {"blocks":[{"type":"actions","heading":"CHOOSE EQUIPMENT","items":items},{"type":"actions","items":[{"label":"MORE EQUIPMENT","sub":"Page %d / %d"%[equipment_page+1,ceili(names.size()/4.0)],"on_press":func():equipment_page=(equipment_page+1)%ceili(names.size()/4.0);hud.request_immediate_dock_refresh()}]}]}

func _equipment_order_report(item:String)->Dictionary:return _supply_order_report("equipment",item)
func _ammunition_catalog()->Dictionary:
	var items:Array=[]
	for item:String in ["arrows","artillery_rounds","small_arms_ammunition","heavy_shells"]:items.append(focused_action(item.replace("_"," ").to_upper(),"%d in store"%int(MilitaryCampaign.military_consumables.get(item,0)),_supply_order_report.bind("ammunition",item)))
	return {"blocks":[{"type":"actions","heading":"CHOOSE AMMUNITION","items":items}]}
func _supply_order_report(kind:String,item:String)->Dictionary:
	var quote:Dictionary
	match kind:
		"ammunition":quote=MilitaryCampaign.consumable_production_quote(item,equipment_batch)
		"transport":quote=MilitaryCampaign.transport_cart_quote(equipment_batch)
		"repair":quote=MilitaryCampaign.equipment_repair_quote(item,equipment_batch)
		_:quote=MilitaryCampaign.equipment_production_quote(item,equipment_batch)
	var count:=int(quote.get("amount",equipment_batch))
	var unit:="CARTS" if kind=="transport" else ("ARROWS" if item=="arrows" else ("ROUNDS" if kind=="ammunition" else "SETS"))
	var cost:=String(quote.get("error",""))
	if not quote.has("error"):
		var parts:Array[String]=[]
		for material:String in quote.recipe.materials:parts.append("%.2f %s"%[float(quote.recipe.materials[material])*count*float(quote.get("material_factor",1)),ResourceSystem.display_name(material)])
		cost="RESERVED NOW: "+", ".join(parts)+".\nWORK REQUIRED: %.2f workshop work-days. Calendar time depends on assigned capacity and practice."%(float(quote.recipe.days)*count*float(quote.get("work_factor",1)))
		if kind=="repair":cost+="\n%d damaged sets enter the workshop; they become usable only as repairs finish."%count
	var quantities:Array=[]
	for amount:int in [1,5,20,100]:quantities.append({"label":"%d %s"%[amount,unit.trim_suffix("S") if amount==1 else unit],"primary":equipment_batch==amount,"on_press":func():equipment_batch=amount;hud.request_immediate_dock_refresh()})
	return {"blocks":[{"type":"actions","heading":"QUANTITY PER ORDER","items":quantities},{"type":"text","heading":"BEFORE YOU ORDER","text":cost},{"type":"actions","items":[{"label":("REPAIR" if kind=="repair" else "MAKE")+" %d %s"%[count,unit.trim_suffix("S") if count==1 else unit],"sub":"Reserve materials and queue work","primary":true,"disabled":quote.has("error"),"tip":String(quote.get("error",cost)),"on_press":func():_queue_supply_order(kind,item,equipment_batch)},{"label":"MATERIAL STORES","sub":"Understand a shortage","on_press":jump("economy",1)}]},{"type":"text","text":"Finished items enter home stores. Queueing creates no usable equipment or ammunition; supplies still have to reach field armies."}]}
func _queue_supply_order(kind:String,item:String,count:int)->void:
	var result:Dictionary
	match kind:
		"ammunition":result=MilitaryCampaign.queue_consumable_production(item,count)
		"transport":result=MilitaryCampaign.queue_transport_cart_production(count)
		"repair":result=MilitaryCampaign.queue_equipment_repair(item,count)
		_:result=MilitaryCampaign.queue_equipment_production(item,count)
	terrain._report_military_action(result);hud.request_immediate_dock_refresh()
func _open_workshop_job(id:int)->void:
	var action:=focused_action("WORKSHOP ORDER","",_workshop_job_report.bind(id));action.on_press.call()
func _workshop_job_report(id:int)->Dictionary:
	for job:Dictionary in MilitaryCampaign.equipment_queue:
		if int(job.id)!=id:continue
		return {"blocks":[{"type":"text","heading":String(job.item).replace("_"," ").to_upper(),"text":"%d of %d items finished. %.2f of %.2f work-days completed. Work-days are production effort, not calendar days."%[int(job.get("completed",0)),int(job.count),float(job.progress_days),float(job.required_days)]},{"type":"actions","items":[{"label":"CANCEL REMAINING WORK","sub":"Completed items stay in stores","on_press":func():terrain._report_military_action(MilitaryCampaign.cancel_equipment_job(id));hud.request_immediate_dock_refresh()}]},{"type":"text","text":"Cancellation returns unused reserved materials and unfinished damaged items. A partially worked item consumes up to 35% of its materials; finished items are retained."}]}
	return {"blocks":[{"type":"text","text":"This workshop order has finished or was cancelled. Finished items are in home stores."}]}

func _reputation_report()->Dictionary:
	var reputation:=MilitaryCampaign.war_reputation_snapshot();var items:Array=[]
	for key:String in ["mercy","fear","grievance"]:items.append({"name":key.capitalize(),"value":"%d / 100"%roundi(float(reputation.get(key,0))*100),"sub":{"mercy":"Remembered humane treatment","fear":"Intimidation from wartime conduct","grievance":"Resentment from wartime harm"}[key]})
	return {"blocks":[{"type":"text","text":"These are remembered conduct scores, not chances of success or a count of people."},{"type":"rows","heading":"CONDUCT SCORES","items":items}]}

func _recruitment_requirements(template_id:int)->Dictionary:
	var quote:=MilitaryCampaign.template_training_quote(template_id)
	var blockers:Array=quote.get("blockers",[])
	var actions:Array=[]
	if int(quote.get("missing",0))>int(quote.get("people_room",0)):
		actions.append(focused_action("PERSONNEL ACCOUNT","See where existing military places are used",func()->Dictionary:return {"blocks":[_personnel_block()]}))
		actions.append({"label":"SECURITY PRACTICES","sub":"Review watch and levy development","on_press":func():hud.providers["inquiry"].open_domain("security")})
	if int(quote.get("required",0))>int(quote.get("training_places",0)):
		actions.append({"label":"LOCAL WORK PRIORITY","sub":"Leaders allocate Defense instructors; no instant capacity","on_press":jump("settlement",0)})
	for weapon:String in quote.get("equipment",{}):
		if int(quote.equipment[weapon])>int(MilitaryCampaign.military_inventory.get(weapon,0)):
			actions.append(focused_action("MAKE "+weapon.replace("_"," ").to_upper(),"Review materials and workshop time",_equipment_order_report.bind(weapon)))
	if float(quote.get("food",0))>FoodSystem.total_stored():actions.append({"label":"FOOD & RESERVES","sub":"Review supply and local work priority","on_press":jump("economy",0)})
	return {"blocks":[{"type":"text","heading":"CURRENT REQUIREMENTS","text":"\n\n".join(blockers) if not blockers.is_empty() else "Requirements met. Return to Recruit & Train to issue the order."},{"type":"actions","items":actions},{"type":"text","heading":"WHAT HAPPENS NEXT","text":"A waiting order is checked as game days advance. It starts only when the full class meets every requirement. Stop Recruitment cancels future intake; already enrolled soldiers continue. If another army uses all military places, you must change that commitment or develop greater capacity; simply waiting does not guarantee recruitment."}]}
