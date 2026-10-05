extends "res://scripts/hud/content/dock_content_base.gd"
## Detail dock: the war, in plain words. What is being fought now, the last
## fight and how it went, captives waiting on your word, and, only when a
## war is on, how hard each front should fight. Nothing that does not apply
## is shown (simple-obvious-controls): no empty counters, no scores.

const BattleAccount:=preload("res://scripts/battle_account.gd")
## [id, label, what it means]
const STANCES:Array[Array]=[["cautious","Carefully","Keep our people alive; give ground rather than lose many"],["balanced","Evenly","Trade ground and losses evenly"],["offensive","Hard","Press them; accept heavier losses"]]
## [label, prisoners, spoils, their leader, what it means]
const AFTERMATH_BUNDLES:Array[Array]=[
	["Show mercy","release","return property","release","Let the captives go and give back what we took. They will hate us less and fear us less."],
	["Ransom them","ransom","army stores","ransom","Their people pay to have them back; we keep what we took."],
	["Be harsh","enslave","unrestricted plunder","execute","Make the captives slaves, take everything, kill their leader. Others will fear us and hate us."],
]

## An order for one of our battles: that battle comes into focus first.
func _order(battle_id:String,order:String)->void:
	if MilitaryCampaign.focus_engagement(battle_id): MilitaryCampaign.advance_engagement(order)


func meta()->Dictionary:
	return {
		"eyebrow":"WAR",
		"title":"War Planning",
		"subtabs":["NOW"],
	}

func tab(_sub:int)->Dictionary:
	var threat:Dictionary=MilitaryCampaign.threat_snapshot()
	# Our battles being fought now: several can run at once, on different fronts.
	var fights:Array=MilitaryCampaign.own_battles()
	var aftermath:Dictionary=MilitaryCampaign.pending_aftermath
	var fronts:Array=CivilizationSystem.military_fronts_snapshot().get("fronts",[])
	var captives:=int(MilitaryCampaign.foreign_prisoners)
	# Counters only when they count something.
	var kpis:Array=[]
	if not fronts.is_empty():
		kpis.append({"label":"AT WAR WITH","value":_peoples(fronts),"delta":"","accent":Tokens.RED,"tip":"Peoples we are at war with now"})
	if captives>0:
		kpis.append({"label":"CAPTIVES","value":str(captives),"delta":"held by us","accent":Tokens.AMBER,"tip":"Enemy fighters we hold"})
	var brief:Dictionary
	if not aftermath.is_empty():
		brief={"tone":"danger","title":"The fight is over. The captives wait on your word","why":"Choose what becomes of them and of what we took, below."}
	elif not fights.is_empty():
		brief={"tone":"danger","title":"Our people are fighting now" if fights.size()==1 else "Our people are fighting in %d places" % fights.size(),
			"why":"The war leader commands the fight. You will get his report when it ends." if fights.size()==1 else "Each war leader commands his own fight. You will get each report when it ends."}
	elif not threat.is_empty():
		brief={"tone":"danger","title":String(threat.get("title","A war band is coming")),"why":"Decide how to meet them before %s, or the war leader decides for you." % preload("res://scripts/calendar_date.gd").words(int(threat.get("deadline_day",0)))}
	elif fronts.is_empty():
		brief={"tone":"info","title":"We are at peace","why":"If war comes, what is being fought and how it goes will be here."}
	else:
		brief={"tone":"warn","title":"At war with %s" % _peoples(fronts),"why":"The war leader fights it. Tell him how hard to push, or speak with him in the court."}
	var blocks:Array=[]
	if not MilitaryCampaign.recovery.data.occupied.is_empty() or not MilitaryCampaign.recovery.absent_group().is_empty():
		blocks.append({"type":"actions","items":[{"label":"SURVIVAL & INDEPENDENCE","sub":"survivors, occupied cities and recovery","on_press":func()->void:preload("res://scripts/hud/recovery_screen.gd").open()}]})
	var siege:=MilitaryCampaign.siege_public_snapshot()
	if not siege.is_empty():
		brief={"tone":"warn","title":"Siege of "+String(siege.target_name)+" · day %d" % maxi(1,int(siege.days)),"why":"Hold the approaches, seek terms, or leave. Orders continue as time passes; no daily micromanagement is required."}
		blocks.append_array(_siege_blocks(siege))
	if siege.is_empty() and not MilitaryCampaign.siege_history.is_empty():
		blocks.append({"type":"actions","items":[{"label":"REOPEN LAST SIEGE","sub":"outcome and recovery","on_press":func()->void:preload("res://scripts/hud/siege_screen.gd").open(String(MilitaryCampaign.siege_history[0].id))}]})
	if not threat.is_empty():
		blocks.append({"type":"rows","heading":"COMING AT US","items":[{
			"name":String(threat.get("title","A war band")),
			"sub":"%s · about %d fighters · they arrive by %s" % [String(threat.get("source_name","Strangers")),int(threat.get("estimated_strength",0)),preload("res://scripts/calendar_date.gd").words(int(threat.get("deadline_day",0)))],
			"value":"","accent":Tokens.RED,"tip":"If nobody answers, the watch defends or gives way when they arrive",
		}]})
		blocks.append({"type":"actions","items":[
			{"label":"Shelter behind the walls","sub":"hold out, however long","on_press":func()->void: _siege_notice(MilitaryCampaign.begin_siege()),"tip":"Stay behind our defences. Food and patience run down with time; raiders cannot be waited out this way."},
			{"label":"Meet them","sub":"fight with who we have","primary":true,"on_press":func()->void: MilitaryCampaign.respond_to_threat("defend"),"tip":"Fight with our watch and defences"},
			{"label":"Pay them off","sub":"%.0f food" % float(threat.get("tribute_food",0.0)),"on_press":func()->void: MilitaryCampaign.respond_to_threat("tribute"),"tip":"Give them food from the stores to go away"},
			{"label":"Give way","sub":"let them take what they came for","on_press":func()->void: MilitaryCampaign.respond_to_threat("withdraw"),"tip":"Get our people clear and let them take it"},
		]})
	for fight_index in fights.size():
		var engagement:Dictionary=fights[fight_index]
		var battle_id:=String(engagement.get("id",""))
		var home_side:=String(engagement.get("home_side","attacker"))
		var enemy_side:="defender" if home_side=="attacker" else "attacker"
		var ours:Dictionary=engagement.get(home_side,{})
		var theirs:Dictionary=engagement.get(enemy_side,{})
		var threat_now:Dictionary=engagement.get("threat",{})
		var place:=String(threat_now.get("target_region_name",""))
		var rounds:Array=engagement.get("rounds",[])
		var rows:Array=[{
			"name":"Fighting %s%s" % [String(threat_now.get("source_name","them")),(" at "+place) if place!="" and not place.begins_with("the field") else ""],
			"sub":"%d of ours still fighting, %s · %s exchanges so far" % [int(ours.get("troops",0)),BattleAccount.morale_words(float(ours.get("morale",1.0))),BattleAccount.count_words(rounds.size())],
			"value":"","accent":Tokens.RED,"tip":"Each exchange is about half an hour of fighting",
		}]
		var plan:Dictionary=engagement.get("tactics",{})
		if not plan.is_empty():
			var words:=preload("res://scripts/hud/era_words.gd").stage()
			rows.append({"name":BattleAccount._tactic_line(String((plan.get(home_side,{}) as Dictionary).get("id","head_on")),words,true),"sub":"our war leader's choice","value":"","accent":Tokens.RED,"tip":"He chose this from our fighters, what our people know and the ground. Ask him about it in the court."})
			rows.append({"name":BattleAccount._tactic_line(String((plan.get(enemy_side,{}) as Dictionary).get("id","head_on")),words,false),"sub":"as our people saw it · they have about %d" % int(theirs.get("troops",0)),"value":"","accent":Tokens.RED,"tip":"What their leader is doing, as our people read it from the field."})
		blocks.append({"type":"rows","heading":"THE FIGHT NOW" if fights.size()==1 else "FIGHTING NOW · %d OF %d" % [fight_index+1,fights.size()],"items":rows})
		blocks.append({"type":"actions","items":[
			{"label":"Watch the battle","sub":"the two lines and how it goes","primary":true,"on_press":func()->void: MilitaryCommandUI.call_deferred("open_engagement",battle_id),"tip":"Opens this battle. Watching does not fight it."},
			{"label":"Hold the line","sub":"keep fighting as we are","on_press":func()->void: _order(battle_id,"hold"),"tip":"Keep fighting without forcing it"},
			{"label":"Press them hard","sub":"more losses, quicker end","on_press":func()->void: _order(battle_id,"push"),"tip":"Accept losses to break them"},
			{"label":"Pull back","sub":"break off and save who we can","on_press":func()->void: _order(battle_id,"retreat"),"tip":"Break off the fight"},
		]})
	# The last fight, as the war leader told it.
	if fights.is_empty() and not MilitaryCampaign.battle_history.is_empty():
		var record:Dictionary=MilitaryCampaign.battle_history[0]
		if int(GameState.elapsed_days)-int(record.get("day",0))<=60:
			var account:=BattleAccount.build(record,BattleAccount.gather(record))
			var seed:=int(record.get("seed",0))
			blocks.append({"type":"rows","heading":"THE LAST FIGHT","items":[{"name":String(account.headline),"sub":BattleAccount.ledger_line(account.ours),"value":"","accent":Tokens.MUTED,"tip":String(account.now)}]})
			var links:Array=[{"label":"Read the report","sub":"what happened and what comes next","on_press":func()->void: preload("res://scripts/hud/battle_report_panel.gd").open(terrain if terrain!=null else (Engine.get_main_loop() as SceneTree).current_scene,seed)}]
			if not (record.get("rounds",[]) as Array).is_empty():
				links.append({"label":"Watch the battle","sub":"played from what happened","on_press":func()->void: MilitaryCommandUI.call_deferred("_open_battle_graphics",0,seed)})
			blocks.append({"type":"actions","items":links})
	if not aftermath.is_empty() or captives>0 or not MilitaryCampaign.held_generals.is_empty():
		var bundle_items:Array=[]
		for bundle in AFTERMATH_BUNDLES:
			var prisoner_policy:=String(bundle[1])
			var spoils_policy:=String(bundle[2])
			var general_policy:=String(bundle[3])
			bundle_items.append({
				"label":String(bundle[0]),"sub":String(bundle[4]),
				"primary":String(bundle[1])=="ransom",
				"on_press":(func()->void:
					if MilitaryCampaign.pending_aftermath.is_empty(): MilitaryCampaign.resolve_held_captives(prisoner_policy,general_policy)
					else: MilitaryCampaign.resolve_aftermath(prisoner_policy,spoils_policy,general_policy)),
				"tip":String(bundle[4]),
			})
		var leaders:=MilitaryCampaign.held_generals.size()
		blocks.append({"type":"rows","heading":"CAPTIVES","items":[{
			"name":"What becomes of them is your word" if not aftermath.is_empty() else "Captives we are holding",
			"sub":"%s%s" % [_count(captives,"captive","captives"),(" and %s" % _count(leaders,"of their leaders","of their leaders")) if leaders>0 else ""],
			"value":"","accent":Tokens.AMBER,"tip":"One choice decides the captives, what we took, and any leader we hold",
		}]})
		blocks.append({"type":"actions","items":bundle_items})
	# How others see our wars, only once they have something to say.
	var reputation:Dictionary=MilitaryCampaign.war_reputation_snapshot()
	var said:=_reputation_words(reputation)
	if said!="": blocks.append({"type":"text","heading":"WHAT OTHERS SAY OF US","text":said})
	for front_variant in fronts:
		var front:Dictionary=front_variant
		var opponent_id:=String(front.get("opponent_id",""))
		var stance:=String(front.get("stance","balanced"))
		var score:=float(front.get("war_score",0.0))
		blocks.append({"type":"rows","heading":"THE WAR WITH %s" % String(front.get("opponent","them")).to_upper(),"note":"we are ahead" if score>8.0 else ("we are behind" if score<-8.0 else "even so far"),"items":[{
			"name":"Fighting for %s" % String(front.get("target","our land")),
			"sub":"%d in the field · %d on the way · %d at home · food %s" % [int(front.get("field_personnel",0)),int(front.get("inbound_personnel",0)),int(front.get("reserve_personnel",0)),_supply_words(float(front.get("supply",0.0)))],
			"value":_stance_label(stance),"value_color":Tokens.GOLD,
			"accent":Tokens.RED,"tip":String(front.get("objective","")),
		}]})
		var stance_items:Array=[]
		for stance_option in STANCES:
			var stance_id:=String(stance_option[0])
			stance_items.append({
				"label":"Fight %s" % String(stance_option[1]).to_lower(),"sub":String(stance_option[2]),
				"primary":stance_id==stance,
				"on_press":func()->void: CivilizationSystem.set_front_stance(opponent_id,stance_id),
				"tip":String(stance_option[2]),
			})
		blocks.append({"type":"actions","items":stance_items})
	var wars:Array=CivilizationSystem.war_history_snapshot(true)
	if not wars.is_empty():
		var record_items:Array=[]
		for war_index in range(mini(3,wars.size())):
			var war:Dictionary=wars[war_index]
			record_items.append({
				"name":String(war.get("name","War")),
				"sub":"%s · %s" % [preload("res://scripts/chronicle.gd").date_label(int(war.get("started_day",0))),"still going" if int(war.get("ended_day",-1))<0 else String(war.get("result",war.get("war_goal","ended")))],
				"value":"","accent":Tokens.MUTED,"tip":"Every war is kept in the record",
			})
		blocks.append({"type":"rows","heading":"PAST WARS","items":record_items})
	if blocks.is_empty():
		blocks.append({"type":"text","heading":"QUIET","text":"Nothing here needs your word: no war, no fight, no captives. Armies and their supplies are in the Military dock."})
	return {"kpis":kpis,"brief":brief,"blocks":blocks}


func _peoples(fronts:Array)->String:
	var names:PackedStringArray=[]
	for front_variant in fronts:
		var name:=String((front_variant as Dictionary).get("opponent",""))
		if name!="" and not names.has(name): names.append(name)
	return ", ".join(names) if not names.is_empty() else "a people"


func _count(n:int,one:String,many:String)->String:
	return "%s %s" % [BattleAccount.count_words(n),one if n==1 else many]


func _stance_label(stance:String)->String:
	for option in STANCES:
		if String(option[0])==stance: return "Fighting %s" % String(option[1]).to_lower()
	return "Fighting evenly"


func _supply_words(supply:float)->String:
	if supply>=0.85: return "enough"
	if supply>=0.6: return "a little short"
	if supply>=0.35: return "short"
	return "running out"


## Mercy, fear and grievance as other peoples would put it; "" while the
## world has nothing to say about our wars yet.
static func _reputation_words(reputation:Dictionary)->String:
	var parts:Array[String]=[]
	if float(reputation.get("mercy",0.0))>=0.1: parts.append("we let captives go")
	if float(reputation.get("fear",0.0))>=0.1: parts.append("we are cruel to the beaten")
	if float(reputation.get("grievance",0.0))>=0.1: parts.append("we owe them for wrongs done")
	if parts.is_empty(): return ""
	return "Other peoples say %s." % " and ".join(parts)

func signature()->Array:
	# Each battle of ours being fought, by id and how far it has gone.
	var fights:=""
	for engagement in MilitaryCampaign.own_battles(): fights+="%s:%d;" % [String((engagement as Dictionary).get("id","")),((engagement as Dictionary).get("rounds",[]) as Array).size()]
	return [JSON.stringify(MilitaryCampaign.siege_public_snapshot()),MilitaryCampaign.threat_snapshot().size(),fights,MilitaryCampaign.pending_aftermath.size(),CivilizationSystem.military_fronts_snapshot().get("fronts",[]).size(),MilitaryCampaign.foreign_prisoners,MilitaryCampaign.battle_history.size(),int(MilitaryCampaign.battle_history[0].get("seed",0)) if not MilitaryCampaign.battle_history.is_empty() else 0]


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
		{"name":"ENEMY SUPPLIES","sub":String(siege.enemy_supply_assessment),"value":"reported %s" % preload("res://scripts/calendar_date.gd").words(int(siege.enemy_supply_report_day)) if int(siege.enemy_supply_report_day)>=0 else "UNKNOWN"},
	]
	if float(siege.own_food_days)>=0: rows.append({"name":"HOME FOOD RESERVE","sub":"Current food stores at current demand; not a guaranteed survival countdown","value":"%.1f days" % float(siege.own_food_days)})
	var blocks:Array=[{"type":"rows","heading":"SIEGE · "+String(siege.target_name),"items":rows},{"type":"actions","items":[
		{"label":"WATCH SIEGE","sub":"city, forces and live decisions","on_press":func()->void: preload("res://scripts/hud/siege_screen.gd").open(identity)},
		{"label":"CONTINUE","sub":"hold current orders","on_press":func()->void: _siege_notice(MilitaryCampaign.siege_order(identity,"continue"))},
		{"label":"NEGOTIATE","sub":"seek terms through envoys, in the court","on_press":court({"civ_id":rival})},
		{"label":"RELIEF & ALLIES","sub":"review real commitments and ability","on_press":func()->void: _open_siege_relief(identity)},
		{"label":"ASSAULT" if String(siege.mode)=="offensive" else "SORTIE","sub":"fight from current conditions","on_press":func()->void: _siege_notice(MilitaryCampaign.siege_order(identity,"assault"))},
		{"label":"WITHDRAW","sub":"lift siege / yield ground","on_press":func()->void: _siege_notice(MilitaryCampaign.siege_order(identity,"withdraw"))},
	]},{"type":"text","text":"Outside work and food access remain restricted while the siege holds. Relief camps use their own provisions and remain their allies' people. No fresh enemy store count is assumed from an old report."}]

	# Keep the orders visible before the longer supply assessment.
	return [blocks[1],blocks[0],blocks[2]]

func _open_siege_relief(siege_id:String)->void:
	if ForeignDiplomacy.has_method("open_relief"): ForeignDiplomacy.call("open_relief",siege_id)
	else: _siege_notice({"error":"Relief diplomacy is not available in this development build."})
