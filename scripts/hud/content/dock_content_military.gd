extends "res://scripts/hud/content/dock_content_base.gd"
## MILITARY section: Formations / Training / Supply.
## Replaces the top-level Military Command modal's overview tabs; deep war
## planning (fronts, orders, engagements) opens as the war-planning view.

func meta()->Dictionary:
	return {
		"eyebrow":"MILITARY COMMAND",
		"title":"Watch & Field",
		"subtabs":["FORMATIONS","TRAINING","SUPPLY"],
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
		{"label":"FIELD SOLDIERS","value":str(troops),"delta":"%d watch" % watch,"delta_color":Tokens.MUTED,"accent":Tokens.RED,"tip":"Trained field formation strength"},
		{"label":"READINESS","value":"%d%%" % roundi(organization*100.0),"delta":"","accent":Tokens.AMBER,"tip":"Organization and condition"},
		{"label":"MOBILIZED","value":str(mobilized),"delta":"%d cap" % mobilization_cap,"delta_color":Tokens.MUTED,"accent":Tokens.BLUE,"tip":"Citizens raised vs. mobilization capacity"},
		{"label":"UPKEEP","value":"%.1f" % upkeep,"delta":"rations/day","delta_color":Tokens.MUTED,"accent":Tokens.TEAL,"tip":"Daily provision cost"},
	]
	var brief:Dictionary
	if troops==0 and int(army.get("recruits",0))==0:
		brief={"tone":"info","title":"No field formation exists","why":"Raise citizens, then train them. Each soldier is absent from food and construction."}
	else:
		var threat:Dictionary=MilitaryCampaign.threat_snapshot() if MilitaryCampaign.has_method("threat_snapshot") else {}
		if not (threat.get("threats",[]) as Array).is_empty():
			brief={"tone":"danger","title":"A threat requires a response","why":"Open war planning to review and respond.","action_label":"WAR PLANNING","on_action":func()->void: terrain._open_war_planning()}
		else:
			brief={"tone":"info","title":"Forces are standing by","why":"Fronts, orders, and engagements live in war planning.","action_label":"WAR PLANNING","on_action":func()->void: terrain._open_war_planning()}
	match sub:
		1: return {"kpis":kpis,"brief":brief,"blocks":_training_blocks(army,capabilities)}
		2: return {"kpis":kpis,"brief":brief,"blocks":_supply_blocks(army,capabilities)}
	return {"kpis":kpis,"brief":brief,"blocks":_formation_blocks(army,capabilities)}

func _formation_blocks(army:Dictionary,capabilities:Dictionary)->Array:
	var commander:Dictionary=army.get("commander",{})
	var commander_items:Array=[{
		"name":String(commander.get("name","No commander")),
		"sub":"CMD %d · TAC %d · LOG %d · RES %d" % [roundi(float(commander.get("command",0.0))*100.0),roundi(float(commander.get("tactics",0.0))*100.0),roundi(float(commander.get("logistics",commander.get("supply",0.0)))*100.0),roundi(float(commander.get("resolve",0.0))*100.0)],
		"value":"","accent":Tokens.BLUE,
		"tip":"The Marshal's office commands the home force; appoint a Marshal to improve execution",
	}]
	var condition:Dictionary=MilitaryCampaign.force_condition_profile()
	var troops:=maxi(0,int(army.get("troops",0)))
	var recruits:=maxi(0,int(army.get("recruits",0)))
	var supply:=clampf(float(army.get("supply_level",1.0)),0.0,1.0)
	var organization:=clampf(float(army.get("organization",0.0)),0.0,1.0)
	var morale:=clampf(float(army.get("morale",0.0)),0.0,1.0)
	var personnel_items:Array=[
		{"name":"Soldiers","value":str(troops),"ratio":clampf(float(troops)/100.0,0.0,1.0),"color":Tokens.MUTED if troops==0 else Tokens.BODY_2,"tip":"Trained field soldiers"},
		{"name":"Recruits","value":str(recruits),"ratio":clampf(float(recruits)/50.0,0.0,1.0),"color":Tokens.AMBER if recruits>0 else Tokens.MUTED,"tip":"Raised citizens awaiting training"},
		{"name":"Organization","value":"%d%%" % roundi(organization*100.0),"ratio":organization,"color":Tokens.BLUE,"tip":"Command structure and drill"},
		{"name":"Morale","value":"%d%%" % roundi(morale*100.0),"ratio":morale,"color":Tokens.TEAL,"tip":"Willingness to fight"},
		{"name":"Supply","value":"%d%%" % roundi(supply*100.0),"ratio":supply,"color":Tokens.TEAL,"tip":"Provision delivery to the force"},
	]
	var blocks:Array=[
		{"type":"rows","heading":"COMMANDER","items":commander_items},
		{"type":"bars","heading":"PERSONNEL","items":personnel_items},
		{"type":"actions","items":[
			{"label":"RAISE 10 RECRUITS","sub":"−10 from the labor pool","primary":true,
			"on_press":func()->void: MilitaryCampaign.raise_recruits(10),
			"tip":"Mobilize ten citizens as untrained recruits"},
			{"label":"DEMOBILIZE 10","sub":"return people to labor","disabled":troops+recruits<=0,
			"on_press":func()->void: MilitaryCampaign.demobilize(10),
			"tip":"Release soldiers or recruits back to civilian work"},
		]},
	]
	var bands:Array=condition.get("bands",[])
	if not bands.is_empty() and int(condition.get("total",0))>0:
		var segment_items:Array=[]
		for band_variant in bands:
			var band:Dictionary=band_variant
			if int(band.get("count",0))<=0: continue
			segment_items.append({"label":String(band.get("label","")),"value":str(int(band.get("count",0))),"share":float(band.get("count",0)),"color":Color(String(band.get("color","#8a948f"))),"tip":"Physical condition band"})
		if not segment_items.is_empty():
			blocks.insert(2,{"type":"segments","heading":"CONDITION","items":segment_items})
	return blocks

func _training_blocks(army:Dictionary,capabilities:Dictionary)->Array:
	var rate:=float(capabilities.get("training_rate",0.0))
	var capacity:=int(capabilities.get("training_capacity",0))
	var load:=int(capabilities.get("training_load",0))
	var workshop:=clampf(float(capabilities.get("workshop_utilization",0.0)),0.0,1.0)
	var training_items:Array=[
		{"name":"Rate","value":"%.1f/day" % rate,"ratio":clampf(rate/5.0,0.0,1.0),"color":Tokens.AMBER,"tip":"Trainees completing per day"},
		{"name":"Capacity","value":str(capacity),"ratio":clampf(float(capacity)/20.0,0.0,1.0),"color":Tokens.BLUE,"tip":"Simultaneous trainees supported"},
		{"name":"In training","value":str(load),"ratio":clampf(float(load)/maxf(1.0,float(capacity)),0.0,1.0),"color":Tokens.TEAL if load<=capacity else Tokens.RED,"tip":"Queued and active trainees"},
		{"name":"Workshop","value":"%d%%" % roundi(workshop*100.0),"ratio":workshop,"color":Tokens.MUTED,"tip":"Equipment production supporting training"},
	]
	var program_items:Array=[]
	var catalog:Dictionary=capabilities.get("training_programs",{})
	var count:=0
	for program_id in catalog:
		if count>=4: break
		count+=1
		var program:Dictionary=catalog[program_id]
		var unlocked:=bool(program.get("unlocked",false))
		program_items.append({
			"label":String(program.get("name",program_id)).to_upper(),
			"sub":String(program.get("reason",program.get("description",""))).substr(0,44),
			"primary":unlocked and count==1,
			"disabled":not unlocked,
			"on_press":(func()->void: MilitaryCampaign.start_training_program(String(program_id))) if unlocked else null,
			"tip":String(program.get("reason",program.get("description",""))),
		})
	var blocks:Array=[{"type":"bars","heading":"TRAINING","items":training_items}]
	if not program_items.is_empty():
		blocks.append({"type":"actions","items":program_items})
	var active_program:Dictionary=capabilities.get("training_program",{})
	if bool(active_program.get("active",false)):
		blocks.append({"type":"text","heading":"ACTIVE PROGRAM","text":"%s · %d day%s remain." % [String(active_program.get("name","Training")),int(active_program.get("days_remaining",0)),"" if int(active_program.get("days_remaining",0))==1 else "s"]})
	return blocks

func _supply_blocks(army:Dictionary,capabilities:Dictionary)->Array:
	var inventory:Dictionary=army.get("military_inventory",{})
	var carts:=int(inventory.get("transport_cart",inventory.get("Transport cart",0)))
	var delivery:=clampf(MilitaryCampaign.field_provision_delivery_ratio(),0.0,1.0)
	var reputation:Dictionary=MilitaryCampaign.war_reputation_snapshot()
	var damaged:Dictionary=army.get("damaged_equipment",{})
	var damaged_total:=0
	for item in damaged: damaged_total+=int(damaged[item])
	var tiles:Array=[
		{"label":"TRANSPORT CARTS","value":str(carts),"note":"logistics reach" if carts>0 else "no logistics reach","note_color":Tokens.GREEN if carts>0 else Tokens.RED,"tip":"Carts extend how far provisions can flow"},
		{"label":"FIELD SUPPLY","value":"%d%%" % roundi(delivery*100.0),"note":"delivery ratio","note_color":Tokens.GREEN if delivery>=0.99 else Tokens.AMBER,"tip":"Share of required field provisions actually delivered"},
		{"label":"DAMAGED GEAR","value":str(damaged_total),"note":"awaiting repair","note_color":Tokens.AMBER if damaged_total>0 else Tokens.MUTED,"tip":"Equipment recoverable through repair work"},
		{"label":"REPUTATION","value":"M%d F%d G%d" % [roundi(float(reputation.get("mercy",0.0))*100.0),roundi(float(reputation.get("fear",0.0))*100.0),roundi(float(reputation.get("grievance",0.0))*100.0)],"note":"mercy · fear · grievance","note_color":Tokens.MUTED,"tip":"How your conduct in war is remembered"},
	]
	return [
		{"type":"tiles","heading":"SUPPLY","items":tiles},
		{"type":"actions","items":[
			{"label":"QUEUE EQUIPMENT","sub":"workshop production","primary":true,
			"on_press":func()->void: terrain._open_war_planning(3),
			"tip":"Open the supply ledger to queue specific equipment"},
			{"label":"REPAIR","sub":"recover damaged gear","disabled":damaged_total<=0,
			"on_press":func()->void: terrain._open_war_planning(3),
			"tip":"Open the supply ledger to queue repair work" if damaged_total>0 else "Nothing is damaged"},
		]},
		{"type":"text","text":"Missions take their provisions at departure. Field forces are supplied only as far as carts and carriers can reach."},
	]

func signature()->Array:
	var army:Dictionary=MilitaryCampaign.campaign_army_snapshot()
	return [int(army.get("troops",0)),int(army.get("recruits",0)),MilitaryCampaign._mobilized_count(),snappedf(float(army.get("provisions_required_today",0.0)),0.1)]
