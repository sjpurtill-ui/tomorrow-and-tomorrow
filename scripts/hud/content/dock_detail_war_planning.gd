extends "res://scripts/hud/content/dock_content_base.gd"
## Detail dock: war planning — threats, live engagements, battle aftermath,
## fronts with stance orders, and the war record. Replaces the legacy
## five-tab military modal's FRONTS & ORDERS surface.

const STANCES:Array[Array]=[["cautious","Preserve the force; yield ground before losses"],["balanced","Trade ground and losses evenly"],["offensive","Press the objective; accept higher losses"]]
const AFTERMATH_BUNDLES:Array[Array]=[
	["MERCIFUL","release","return property","release","Free prisoners and property; grievance fades, fear fades"],
	["PRAGMATIC","ransom","army stores","ransom","Ransom captives and keep stores; balanced reputation"],
	["HARSH","enslave","unrestricted plunder","execute","Maximum extraction; fear and grievance both grow"],
]

func meta()->Dictionary:
	return {
		"eyebrow":"MILITARY · DEEP COMMAND",
		"title":"War Planning",
		"subtabs":["FRONTS & ORDERS"],
	}

func tab(_sub:int)->Dictionary:
	var threat:Dictionary=MilitaryCampaign.threat_snapshot()
	var engagement:Dictionary=MilitaryCampaign.engagement_snapshot()
	var aftermath:Dictionary=MilitaryCampaign.pending_aftermath
	var fronts:Array=CivilizationSystem.military_fronts_snapshot().get("fronts",[])
	var reputation:Dictionary=MilitaryCampaign.war_reputation_snapshot()
	var kpis:Array=[
		{"label":"FRONTS","value":str(fronts.size()),"delta":"active","accent":Tokens.RED if fronts.size()>0 else Tokens.MUTED,"tip":"Wars with a live objective"},
		{"label":"THREAT","value":"YES" if not threat.is_empty() else "none","delta":"","accent":Tokens.RED if not threat.is_empty() else Tokens.GREEN,"tip":"An enemy force demands a response"},
		{"label":"BATTLE","value":"LIVE" if not engagement.is_empty() else "none","delta":"","accent":Tokens.RED if not engagement.is_empty() else Tokens.MUTED,"tip":"An engagement is being fought"},
		{"label":"REPUTATION","value":"Mercy %d" % roundi(float(reputation.get("mercy",0.0))*100.0),"delta":"Fear %d · Grievance %d" % [roundi(float(reputation.get("fear",0.0))*100.0),roundi(float(reputation.get("grievance",0.0))*100.0)],"accent":Tokens.AMBER,"tip":"Mercy · fear · grievance, as the world remembers your wars"},
	]
	var brief:Dictionary
	if not aftermath.is_empty():
		brief={"tone":"danger","title":"A battle ended — decide the aftermath","why":"Prisoners, spoils, and captured command staff wait on your policy below."}
	elif not engagement.is_empty():
		brief={"tone":"danger","title":"A battle is being fought","why":"Hold, push, or retreat below; each day of contact costs both sides."}
	elif not threat.is_empty():
		brief={"tone":"danger","title":String(threat.get("title","A force threatens the settlement")),"why":"Defend, buy them off, or withdraw before day %d." % int(threat.get("deadline_day",0))}
	elif fronts.is_empty():
		brief={"tone":"info","title":"No war is active","why":"Fronts appear here when a war begins. Stances steer replacement, supply, and battle orders."}
	else:
		brief={"tone":"warn","title":"%d front%s active" % [fronts.size(),"" if fronts.size()==1 else "s"],"why":"Set each front's stance; armies fight by it until you change it."}
	var blocks:Array=[]
	if not MilitaryCampaign.recovery.data.occupied.is_empty() or not MilitaryCampaign.recovery.absent_group().is_empty():
		blocks.append({"type":"actions","items":[{"label":"SURVIVAL & INDEPENDENCE","sub":"survivors, occupied cities and recovery","on_press":func()->void:preload("res://scripts/hud/recovery_screen.gd").open()}]})
	var siege:=MilitaryCampaign.siege_public_snapshot()
	if not siege.is_empty():
		brief={"tone":"warn","title":"Siege of "+String(siege.target_name),"why":"Hold the approaches, seek terms, or leave. Orders continue as time passes; no daily micromanagement is required."}
		blocks.append_array(_siege_blocks(siege))
	if not threat.is_empty():
		blocks.append({"type":"rows","heading":"THREAT","items":[{
			"name":String(threat.get("title","Enemy force")),
			"sub":"%s · ~%d strength · respond by day %d" % [String(threat.get("source_name","Unknown")),int(threat.get("estimated_strength",0)),int(threat.get("deadline_day",0))],
			"value":"","accent":Tokens.RED,"tip":"An unanswered threat resolves against you at the deadline",
		}]})
		blocks.append({"type":"actions","items":[
			{"label":"HOLD DEFENSES","sub":"begin a sustained siege","on_press":func()->void: _siege_notice(MilitaryCampaign.begin_siege()),"tip":"Shelter behind prepared defenses. Food access and endurance change with time; raids cannot be besieged."},
			{"label":"DEFEND","sub":"meet them under arms","primary":true,"on_press":func()->void: MilitaryCampaign.respond_to_threat("defend"),"tip":"Fight with the home force and fortifications"},
			{"label":"PAY TRIBUTE","sub":"%.0f food" % float(threat.get("tribute_food",0.0)),"on_press":func()->void: MilitaryCampaign.respond_to_threat("tribute"),"tip":"Buy them off from the food reserve"},
			{"label":"WITHDRAW","sub":"yield the ground","on_press":func()->void: MilitaryCampaign.respond_to_threat("withdraw"),"tip":"Evacuate and concede what they came for"},
		]})
	if not engagement.is_empty():
		var attacker:Dictionary=engagement.get("attacker",{})
		var defender:Dictionary=engagement.get("defender",{})
		blocks.append({"type":"rows","heading":"ENGAGEMENT","items":[{
			"name":"%s vs %s" % [String(attacker.get("name","Attacker")),String(defender.get("name","Defender"))],
			"sub":"day %d of contact" % maxi(1,int(GameState.elapsed_days)-int(engagement.get("started_day",GameState.elapsed_days))+1),
			"value":"","accent":Tokens.RED,"tip":"Each day of contact costs both sides personnel and supply",
		}]})
		blocks.append({"type":"actions","items":[
			{"label":"HOLD","sub":"keep the line","primary":true,"on_press":func()->void: MilitaryCampaign.advance_engagement("hold"),"tip":"Maintain contact without forcing a decision"},
			{"label":"PUSH","sub":"force a decision","on_press":func()->void: MilitaryCampaign.advance_engagement("push"),"tip":"Accept losses to break them"},
			{"label":"RETREAT","sub":"break contact","on_press":func()->void: MilitaryCampaign.advance_engagement("retreat"),"tip":"Withdraw and preserve the force"},
		]})
	if not aftermath.is_empty() or MilitaryCampaign.foreign_prisoners>0 or not MilitaryCampaign.held_generals.is_empty():
		var bundle_items:Array=[]
		for bundle in AFTERMATH_BUNDLES:
			var prisoner_policy:=String(bundle[1])
			var spoils_policy:=String(bundle[2])
			var general_policy:=String(bundle[3])
			bundle_items.append({
				"label":String(bundle[0]),"sub":String(bundle[4]),
				"primary":String(bundle[0])=="PRAGMATIC",
				"on_press":(func()->void:
					if MilitaryCampaign.pending_aftermath.is_empty(): MilitaryCampaign.resolve_held_captives(prisoner_policy,general_policy)
					else: MilitaryCampaign.resolve_aftermath(prisoner_policy,spoils_policy,general_policy)),
				"tip":"Prisoners: %s · Spoils: %s · Command staff: %s" % [prisoner_policy,spoils_policy,general_policy],
			})
		blocks.append({"type":"rows","heading":"AFTERMATH","note":"%d prisoners" % MilitaryCampaign.foreign_prisoners,"items":[{
			"name":"Battle aftermath awaits policy" if not aftermath.is_empty() else "Held captives await policy",
			"sub":"%d prisoners · %d command staff" % [MilitaryCampaign.foreign_prisoners,MilitaryCampaign.held_generals.size()],
			"value":"","accent":Tokens.AMBER,"tip":"The chosen bundle applies prisoner, spoils, and command policy together",
		}]})
		blocks.append({"type":"actions","items":bundle_items})
	if not fronts.is_empty():
		for front_variant in fronts:
			var front:Dictionary=front_variant
			var opponent_id:=String(front.get("opponent_id",""))
			var stance:=String(front.get("stance","balanced"))
			blocks.append({"type":"rows","heading":"FRONT · %s" % String(front.get("war_name","ACTIVE WAR")).to_upper(),"note":"score %+.0f" % float(front.get("war_score",0.0)),"items":[{
				"name":"%s — %s" % [String(front.get("opponent","Enemy")),String(front.get("target","home territory"))],
				"sub":"%d field · %d inbound · %d reserve · supply %d%%" % [int(front.get("field_personnel",0)),int(front.get("inbound_personnel",0)),int(front.get("reserve_personnel",0)),roundi(float(front.get("supply",0.0))*100.0)],
				"value":stance.to_upper(),"value_color":Tokens.GOLD,
				"accent":Tokens.RED,"tip":String(front.get("objective","")),
			}]})
			var stance_items:Array=[]
			for stance_option in STANCES:
				var stance_id:=String(stance_option[0])
				stance_items.append({
					"label":stance_id.to_upper(),"sub":String(stance_option[1]),
					"primary":stance_id==stance,
					"on_press":func()->void: CivilizationSystem.set_front_stance(opponent_id,stance_id),
					"tip":String(stance_option[1]),
				})
			blocks.append({"type":"actions","items":stance_items})
	var wars:Array=CivilizationSystem.war_history_snapshot(true)
	if not wars.is_empty():
		var record_items:Array=[]
		for war_index in range(mini(3,wars.size())):
			var war:Dictionary=wars[war_index]
			record_items.append({
				"name":String(war.get("name","War")),
				"sub":"day %d–%s · %s" % [int(war.get("started_day",0)),str(int(war.get("ended_day",0))) if int(war.get("ended_day",-1))>=0 else "ongoing",String(war.get("result",war.get("war_goal","")))],
				"value":"","accent":Tokens.MUTED,"tip":"The full record persists in the war history",
			})
		blocks.append({"type":"rows","heading":"WAR RECORD","note":"%d wars" % wars.size(),"items":record_items})
	if blocks.is_empty():
		blocks.append({"type":"text","heading":"QUIET","text":"No threat, battle, or front requires a decision. Armies, builds, and supply live in the MILITARY dock."})
	return {"kpis":kpis,"brief":brief,"blocks":blocks}

func signature()->Array:
	return [JSON.stringify(MilitaryCampaign.siege_public_snapshot()),MilitaryCampaign.threat_snapshot().size(),MilitaryCampaign.engagement_snapshot().size(),MilitaryCampaign.pending_aftermath.size(),CivilizationSystem.military_fronts_snapshot().get("fronts",[]).size(),MilitaryCampaign.foreign_prisoners]


func _siege_notice(result:Dictionary)->void:
	if terrain and is_instance_valid(terrain.get("travel_status_label")): terrain.travel_status_label.text=String(result.get("error",result.get("message","Siege orders updated.")))
	if hud and hud.has_method("request_immediate_dock_refresh"): hud.request_immediate_dock_refresh()

func _siege_blocks(siege:Dictionary)->Array:
	var identity:=String(siege.id)
	var rival:=String(siege.defender_id if String(siege.mode)=="offensive" else siege.attacker_id)
	var rows:Array=[
		{"name":"DURATION","sub":"Days holding siege positions","value":"%d days" % int(siege.days)},
		{"name":"ACCESS RESTRICTED","sub":"Estimated share of land approaches held","value":"%d%%" % roundi(float(siege.blockade)*100)},
		{"name":"ASSAULT PRESSURE","sub":"Estimated weakening of prepared defenses; does not guarantee victory","value":"%d%%" % roundi(float(siege.pressure)*100)},
		{"name":"YOUR SUPPLY","sub":"Latest delivered ration coverage","value":"%d%%" % roundi(float(siege.own_supply_ratio)*100)},
		{"name":"CIVILIAN HARDSHIP","sub":String(siege.civilian_hardship),"value":""},
		{"name":"BESIEGER ENDURANCE","sub":String(siege.besieger_endurance),"value":""},
		{"name":"ENEMY SUPPLIES","sub":String(siege.enemy_supply_assessment),"value":"reported day %d" % int(siege.enemy_supply_report_day) if int(siege.enemy_supply_report_day)>=0 else "UNKNOWN"},
	]
	if float(siege.own_food_days)>=0: rows.append({"name":"HOME FOOD RESERVE","sub":"Current food stores at current demand; not a guaranteed survival countdown","value":"%.1f days" % float(siege.own_food_days)})
	var blocks:Array=[{"type":"rows","heading":"SIEGE · "+String(siege.target_name),"items":rows},{"type":"actions","items":[
		{"label":"WATCH SIEGE","sub":"city, forces and live decisions","on_press":func()->void: preload("res://scripts/hud/siege_screen.gd").open(identity)},
		{"label":"CONTINUE","sub":"hold current orders","on_press":func()->void: _siege_notice(MilitaryCampaign.siege_order(identity,"continue"))},
		{"label":"NEGOTIATE","sub":"seek terms through envoys","on_press":func()->void: ForeignDiplomacy.open(rival)},
		{"label":"RELIEF & ALLIES","sub":"review real commitments and ability","on_press":func()->void: _open_siege_relief(identity)},
		{"label":"ASSAULT" if String(siege.mode)=="offensive" else "SORTIE","sub":"fight from current conditions","on_press":func()->void: _siege_notice(MilitaryCampaign.siege_order(identity,"assault"))},
		{"label":"WITHDRAW","sub":"lift siege / yield ground","on_press":func()->void: _siege_notice(MilitaryCampaign.siege_order(identity,"withdraw"))},
	]},{"type":"text","text":"Outside work and food access remain restricted while the siege holds. Relief camps use their own provisions and remain their allies' people. No fresh enemy store count is assumed from an old report."}]

	# Keep the orders visible before the longer supply assessment.
	return [blocks[1],blocks[0],blocks[2]]

func _open_siege_relief(siege_id:String)->void:
	if ForeignDiplomacy.has_method("open_relief"): ForeignDiplomacy.call("open_relief",siege_id)
	else: _siege_notice({"error":"Relief diplomacy is not available in this development build."})
