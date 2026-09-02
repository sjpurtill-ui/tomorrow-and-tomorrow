extends "res://scripts/hud/content/dock_content_base.gd"
## MILITARY section: Formations / Army Builds / Supply.
## Army builds work like division templates: compose a build from unlocked
## unit types, train it as one order, deploy it as a field army, then command
## the army on the map (left-click select, right-click march). Deep war
## decisions (fronts, threats, engagements, aftermath) open in War Planning.

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
		"subtabs":["FORMATIONS","ARMY BUILDS","SUPPLY"],
	}

func tab(sub:int)->Dictionary:
	var army:Dictionary=MilitaryCampaign.campaign_army_snapshot()
	var capabilities:Dictionary=MilitaryCampaign.military_capabilities()
	var troops:=maxi(0,int(army.get("troops",0)))
	var watch:=int(GameState.population_allocations.get("Defense",0))
	var mobilized:=MilitaryCampaign._mobilized_count()
	var mobilization_cap:=int(capabilities.get("recruitment_capacity",0))
	var organization:=clampf(float(army.get("organization",0.0)),0.0,1.0)
	var upkeep:=float(army.get("provisions_required_today",0.0))
	var kpis:Array=[
		{"label":"HOME FORCE","value":str(troops),"delta":"%d watch" % watch,"delta_color":Tokens.MUTED,"accent":Tokens.RED,"tip":"Trained personnel at home, ready to deploy"},
		{"label":"FIELD ARMIES","value":str(MilitaryCampaign.field_armies.size()),"delta":"of %d" % MilitaryCampaign.field_army_capacity(),"delta_color":Tokens.MUTED,"accent":Tokens.BLUE,"tip":"Deployed maneuver armies vs command capacity"},
		{"label":"READINESS","value":"%d%%" % roundi(organization*100.0),"delta":"","accent":Tokens.AMBER,"tip":"Organization and condition of the home force"},
		{"label":"UPKEEP","value":"%.1f" % upkeep,"delta":"rations/day","delta_color":Tokens.MUTED,"accent":Tokens.TEAL,"tip":"Daily provision cost of everyone under arms"},
	]
	var brief:Dictionary=_command_brief()
	match sub:
		1: return {"kpis":kpis,"brief":brief,"blocks":_builds_blocks(capabilities)}
		2: return {"kpis":kpis,"brief":brief,"blocks":_supply_blocks(army,capabilities)}
	return {"kpis":kpis,"brief":brief,"blocks":_formation_blocks(army)}

func _command_brief()->Dictionary:
	if not MilitaryCampaign.threat_snapshot().is_empty() or not MilitaryCampaign.engagement_snapshot().is_empty() or not MilitaryCampaign.pending_aftermath.is_empty():
		return {"tone":"danger","title":"A war decision awaits","why":"A threat, battle, or aftermath needs your order.","action_label":"WAR PLANNING","on_action":func()->void: terrain._open_war_planning()}
	if MilitaryCampaign.field_armies.is_empty() and int(MilitaryCampaign.campaign_army_snapshot().get("troops",0))<=0:
		return {"tone":"info","title":"No field force exists","why":"Compose an army build, train it as one order, then deploy it. Every soldier is absent from food and construction."}
	return {"tone":"info","title":"Forces are standing by","why":"Select an army on the map and right-click charted land to march it. Runners carry each army's reports home.","action_label":"WAR PLANNING","on_action":func()->void: terrain._open_war_planning()}

func _unit_label(unit:String)->String:
	return unit.replace("_"," ").capitalize()

# --- FORMATIONS -------------------------------------------------------------

func _formation_blocks(army:Dictionary)->Array:
	var blocks:Array=[]
	var snapshot:Dictionary=MilitaryCampaign.field_armies_snapshot()
	var live_reports:=bool(snapshot.get("live_reports",true))
	var army_items:Array=[]
	for force_variant in (snapshot.get("armies",[]) as Array):
		var force:Dictionary=force_variant
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
			"value":str(shown_troops),"value_color":Tokens.GOLD if selected else Tokens.BODY_2,
			"accent":Tokens.GOLD if selected else Tokens.BLUE,
			"on_click":func()->void: terrain._select_army_and_focus(army_id),
			"tip":"Click to select this army on the map; right-click charted land to march it. Reports travel home by runner until signal-era development.",
		})
	if army_items.is_empty():
		blocks.append({"type":"text","heading":"FIELD ARMIES","text":"No army is deployed. Compose and train a build in ARMY BUILDS, then deploy it."})
	else:
		blocks.append({"type":"rows","heading":"FIELD ARMIES","note":"click to select on map","items":army_items})
		var selected_active:bool=int(terrain.selected_army_id)!=-1
		blocks.append({"type":"actions","items":[
			{"label":"RETURN SELECTED","sub":"march it home","disabled":not selected_active,
			"on_press":func()->void: MilitaryCampaign.return_field_army(terrain.selected_army_id),
			"tip":"Order the selected army back to the settlement"},
			{"label":"DISBAND SELECTED","sub":"must be at home","disabled":not selected_active,
			"on_press":func()->void: MilitaryCampaign.disband_field_army(terrain.selected_army_id),
			"tip":"Dissolve the selected army into the home force (only while stationed at home)"},
		]})
	var formation_items:Array=[]
	for formation_variant in (army.get("formations",[]) as Array):
		var formation:Dictionary=formation_variant
		var unit:=String(formation.get("unit","levy"))
		formation_items.append({
			"name":"%s · %s" % [_unit_label(unit),String(formation.get("weapon","improvised")).replace("_"," ")],
			"sub":"training %d%% · condition %d%%" % [roundi(float(formation.get("training",0.0))*100.0),roundi(float(formation.get("personnel_condition",1.0))*100.0)],
			"value":"%d/%d" % [int(formation.get("count",0)),int(formation.get("authorized_count",0))],
			"value_color":Tokens.BODY_2,
			"accent":UNIT_COLORS.get(unit,Tokens.MUTED),
			"tip":"Equipment %d of %d · ammunition %d of %d" % [int(formation.get("equipment",0)),int(formation.get("equipment_required",0)),int(formation.get("ammunition",0)),int(formation.get("ammunition_required",0))],
		})
	if formation_items.is_empty():
		blocks.append({"type":"text","heading":"HOME FORCE","text":"No trained formations are at home. Train an army build to create them."})
	else:
		blocks.append({"type":"rows","heading":"HOME FORCE","note":"trained cohorts","items":formation_items})
	var defense:Dictionary=MilitaryCampaign.settlement_defense_snapshot()
	blocks.append({"type":"tiles","heading":"SETTLEMENT DEFENSE","items":[
		{"label":"WORKS","value":String(defense.get("short","Open ground")),"note":"integrity %d%%" % roundi(float(defense.get("integrity",0.0))*100.0),"note_color":Tokens.RED if float(defense.get("integrity",0.0))<0.4 else Tokens.MUTED,"tip":String(defense.get("description",""))},
		{"label":"LOOKOUT","value":"%.0f km" % float(defense.get("observation_radius_km",0.0)),"note":"observation reach","note_color":Tokens.MUTED,"tip":"How far approaching forces are seen"},
		{"label":"GARRISON","value":"%d/%d" % [int(defense.get("garrison_personnel",0)),int(defense.get("garrison_required",0))],"note":"coverage %d%%" % roundi(float(defense.get("garrison_coverage",0.0))*100.0),"note_color":Tokens.GREEN if float(defense.get("garrison_coverage",0.0))>=1.0 else Tokens.AMBER,"tip":"Home troops against the required garrison"},
		{"label":"STORES","value":"%d%%" % roundi(float(MilitaryCampaign.store_protection().get("total",MilitaryCampaign.store_protection().get("protection",0.0)))*100.0),"note":"protected share","note_color":Tokens.MUTED,"tip":"Share of the food reserve protected from raids"},
	]})
	return blocks

# --- ARMY BUILDS ------------------------------------------------------------

func _builds_blocks(capabilities:Dictionary)->Array:
	var blocks:Array=[]
	var snapshot:Dictionary=MilitaryCampaign.army_template_snapshot()
	blocks.append({"type":"text","text":"A build is a reusable army design. Add cohorts, TRAIN the build as one order (recruits are raised automatically), then DEPLOY it as a field army. Recruit reserve: %d." % int(snapshot.get("recruit_reserve",0))})
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
				"pct":"%d ready" % int(entry.get("ready",0)),
				"color":UNIT_COLORS.get(unit,Tokens.MUTED),
				"tip":"%d ready at home · %d in training · target %d" % [int(entry.get("ready",0)),int(entry.get("in_training",0)),int(entry.get("count",0))],
				"on_minus":func()->void: MilitaryCampaign.adjust_template_entry(template_id,unit,weapon,-10),
				"on_plus":func()->void: MilitaryCampaign.adjust_template_entry(template_id,unit,weapon,10),
			})
		var deployable:=bool(template.get("deployable",false))
		var ready_note:="%d of %d trained" % [int(template.get("ready_total",0)),int(template.get("required_total",0))]
		if int(template.get("in_training_total",0))>0: ready_note+=" · %d in training" % int(template.get("in_training_total",0))
		if entry_items.is_empty():
			blocks.append({"type":"text","heading":"BUILD · %s" % String(template.get("name","BUILD")),"note":ready_note,"text":"Empty build — add cohorts below."})
		else:
			blocks.append({"type":"alloc","heading":"BUILD · %s" % String(template.get("name","BUILD")),"note":ready_note,"items":entry_items})
		var command_items:Array=[
			{"label":"TRAIN BUILD","sub":"raise + queue what's missing","primary":not deployable and int(template.get("required_total",0))>0,
			"on_press":func()->void: terrain._report_military_action(MilitaryCampaign.queue_template_training(template_id)),
			"tip":"One order: raise the missing recruits and queue typed training for every under-strength cohort"},
			{"label":"DEPLOY ARMY","sub":"lift trained cohorts into the field","primary":deployable,"disabled":not deployable,
			"on_press":func()->void: terrain._report_military_action(MilitaryCampaign.deploy_army_from_template(template_id)),
			"tip":"Deploy this build as a field army" if deployable else "Every cohort must read ready before the build can deploy"},
			{"label":"DELETE BUILD","sub":"remove the design",
			"on_press":func()->void: terrain._report_military_action(MilitaryCampaign.delete_army_template(template_id)),
			"tip":"Delete this build (armies already deployed keep their troops)"},
		]
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
				"on_press":func()->void: MilitaryCampaign.adjust_template_entry(template_id,unit_id,weapon_id,10),
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
		queue_items.append({
			"name":"%s · %s ×%d" % [_unit_label(String(order.get("unit","levy"))),String(order.get("weapon","improvised")).replace("_"," "),int(order.get("count",0))],
			"sub":"%d of %d days" % [int(order.get("progress_days",0)),int(order.get("required_days",1))],
			"value":"%d%%" % roundi(float(order.get("progress_days",0))/maxf(1.0,float(order.get("required_days",1)))*100.0),
			"value_color":Tokens.AMBER,"accent":Tokens.AMBER,
			"tip":"Trainees become a typed formation when training completes",
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
	return [int(army.get("troops",0)),int(army.get("recruits",0)),MilitaryCampaign.field_armies.size(),(army.get("training_queue",[]) as Array).size(),template_state,terrain.selected_army_id,MilitaryCampaign._mobilized_count()]
