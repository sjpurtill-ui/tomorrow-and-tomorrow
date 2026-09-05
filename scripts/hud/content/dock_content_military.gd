extends "res://scripts/hud/content/dock_content_base.gd"
## MILITARY section: Formations / Army Builds / Supply.
## Army builds work like division templates: compose a build from unlocked
## unit types, train it as one order, deploy it as a field army, then command
## the army on the map (left-click select, right-click march, then click an
## observed enemy to intercept). Deep war decisions (fronts, threats,
## engagements, aftermath) open in War Planning.

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
		1: return {"kpis":kpis,"brief":brief,"blocks":_builds_blocks(capabilities)}
		2: return {"kpis":kpis,"brief":brief,"blocks":_training_blocks()}
		3: return {"kpis":kpis,"brief":brief,"blocks":_supply_blocks(army,capabilities)}
	return {"kpis":kpis,"brief":brief,"blocks":_formation_blocks(army)}

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
			"on_press":func()->void: MilitaryCampaign.return_field_army(terrain.selected_army_id),
			"tip":"Order the selected army back to the settlement"},
			{"label":"DISBAND SELECTED","sub":"must be at home","disabled":not selected_active,
			"on_press":func()->void: MilitaryCampaign.disband_field_army(terrain.selected_army_id),
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

func _builds_blocks(capabilities:Dictionary)->Array:
	var blocks:Array=[_personnel_block()]
	if not MilitaryCampaign.field_armies.is_empty():
		blocks.append({"type":"actions","items":[{"label":"FIND YOUR ARMIES","sub":"open the deployed force roster","on_press":jump("military",0)}]})
	var snapshot:Dictionary=MilitaryCampaign.army_template_snapshot()
	blocks.append({"type":"text","text":"1. Set the number of soldiers. 2. RECRUIT & TRAIN fills missing places. 3. DEPLOY transfers exactly that many to a field army. Builds draw from the same reserve; they do not each own copies of the soldiers. To improve existing troops, use TRAINING. Recruit reserve: %d · mobilization %d of %d capacity." % [int(snapshot.get("recruit_reserve",0)),MilitaryCampaign._mobilized_count(),int(capabilities.get("recruitment_capacity",0))]})
	var units:Dictionary=capabilities.get("units",{})
	var unit_equipment:Dictionary=capabilities.get("unit_equipment",{})
	for template_variant in (snapshot.get("templates",[]) as Array):
		var template:Dictionary=template_variant
		var template_id:=int(template.get("template_id",0))
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
		var deployable:=bool(template.get("deployable",false))
		var ready_note:="%d of %d assembled" % [int(template.get("ready_total",0)),int(template.get("required_total",0))]
		if int(template.get("in_training_total",0))>0: ready_note+=" · %d in training" % int(template.get("in_training_total",0))
		ready_note+=" · %d unfilled" % int(template.get("unfilled",0))
		blocks.append({"type":"text","heading":"RECRUITMENT ORDER","text":("Full-intake order pending until deployment. " if bool(template.get("recruitment_requested",false)) else "Not ordered. RECRUIT & TRAIN waits for a complete intake. ")+String(template.get("blocker",""))})
		if entry_items.is_empty():
			blocks.append({"type":"text","heading":"BUILD · %s" % String(template.get("name","BUILD")),"note":"shared reserve","text":"Empty build — add cohorts below."})
		else:
			blocks.append({"type":"alloc","heading":"BUILD · %s" % String(template.get("name","BUILD")),"note":"shared reserve","items":entry_items})
		blocks.append({"type":"text","text":_build_status(template_id),"live_text":func()->String: return _build_status(template_id)})
		var command_items:Array=[
			{"label":"RECRUIT & TRAIN","sub":"fill missing places","primary":not deployable and int(template.get("required_total",0))>0,
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
		blocks.append({"type":"actions","items":command_items})
	blocks.append({"type":"actions","items":[{
		"label":"NEW BUILD","sub":"start another army design",
		"on_press":func()->void: MilitaryCampaign.create_army_template(),
		"tip":"Create an empty build to compose a different army",
	}]})
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
	if not queue_items.is_empty():
		blocks.append({"type":"rows","heading":"IN TRAINING","items":queue_items})
	return blocks

# --- SUPPLY -----------------------------------------------------------------

func _supply_blocks(army:Dictionary,capabilities:Dictionary)->Array:
	var inventory:Dictionary=army.get("military_inventory",{})
	var carts:=int(inventory.get("transport_cart",inventory.get("Transport cart",0)))
	var delivery:=clampf(MilitaryCampaign.field_provision_delivery_ratio(),0.0,1.0)
	var reputation:Dictionary=MilitaryCampaign.war_reputation_snapshot()
	var damaged:Dictionary=army.get("damaged_equipment",{})
	var damaged_total:=0
	for item in damaged: damaged_total+=int(damaged[item])
	var runner_note:="runners carry reports" if not bool(MilitaryCampaign.field_armies_snapshot().get("live_reports",true)) else "live signal reports"
	var tiles:Array=[
		{"label":"TRANSPORT CARTS","value":str(carts),"note":"logistics reach" if carts>0 else "no logistics reach","note_color":Tokens.GREEN if carts>0 else Tokens.RED,"tip":"Carts extend how far provisions can flow"},
		{"label":"FIELD SUPPLY","value":"%d%%" % roundi(delivery*100.0),"note":runner_note,"note_color":Tokens.GREEN if delivery>=0.99 else Tokens.AMBER,"tip":"Share of required field provisions actually delivered"},
		{"label":"DAMAGED GEAR","value":str(damaged_total),"note":"awaiting repair","note_color":Tokens.AMBER if damaged_total>0 else Tokens.MUTED,"tip":"Equipment recoverable through repair work"},
		{"label":"REPUTATION","value":"M%d F%d G%d" % [roundi(float(reputation.get("mercy",0.0))*100.0),roundi(float(reputation.get("fear",0.0))*100.0),roundi(float(reputation.get("grievance",0.0))*100.0)],"note":"mercy · fear · grievance","note_color":Tokens.MUTED,"tip":"How your conduct in war is remembered"},
	]
	var blocks:Array=[{"type":"tiles","heading":"SUPPLY","items":tiles}]
	var job_items:Array=[]
	for job_variant in (army.get("equipment_queue",[]) as Array):
		var job:Dictionary=job_variant
		job_items.append({
			"name":"%s ×%d" % [String(job.get("item","gear")).replace("_"," ").capitalize(),int(job.get("count",0))],
			"sub":"%s · %d of %d days" % [String(job.get("job_type","production")),int(job.get("progress_days",0)),int(job.get("required_days",1))],
			"value":"","accent":Tokens.GOLD,
			"tip":"Workshop line producing military supply",
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
			"on_press":func()->void: terrain._report_military_action(MilitaryCampaign.queue_equipment_repair(item_id,item_count)),
			"tip":"Queue repair work; costs far less than new production",
		})
	repair_items.append({
		"label":"BUILD 2 CARTS","sub":"extend supply reach",
		"on_press":func()->void: terrain._report_military_action(MilitaryCampaign.queue_transport_cart_production(2)),
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
	return [int(army.get("troops",0)),int(army.get("recruits",0)),MilitaryCampaign.field_armies.size(),(army.get("training_queue",[]) as Array).size(),template_state,terrain.selected_army_id,MilitaryCampaign._mobilized_count(),MilitaryCampaign.training_program.duplicate(true),MilitaryCampaign.training_queue.duplicate(true),MilitaryCampaign.command_development.duplicate(true),int(GameState.elapsed_days)]

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
