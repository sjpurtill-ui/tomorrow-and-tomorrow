extends "res://scripts/hud/content/dock_content_base.gd"
## Direct map interaction for every observed mobile foreign formation. A
## counter is a target, not decoration: click it, understand the contact, and
## issue the next valid action without hunting through unrelated reports.

var formation_id:String=""
var last_outcome:Dictionary={}

func _init(terrain_node:Node,hud_node:Control,target_formation_id:String="")->void:
	super._init(terrain_node,hud_node)
	formation_id=target_formation_id

func _sighting()->Dictionary:
	return CivilizationSystem.visible_formation_sighting(formation_id)

func _selected_army()->Dictionary:
	var selected_id:=int(terrain.selected_army_id)
	if selected_id<0: return {}
	for army_variant in MilitaryCampaign.field_armies_snapshot().get("armies",[]):
		var army:Dictionary=army_variant
		if int(army.get("army_id",0))==selected_id: return army
	return {}

func meta()->Dictionary:
	var sighting:=_sighting()
	return {
		"eyebrow":"MAP CONTACT · CLICKED TARGET",
		"title":String(sighting.get("label","Contact lost")),
		"subtabs":["ENGAGEMENT"],
	}

func tab(_sub:int)->Dictionary:
	var sighting:=_sighting()
	if sighting.is_empty():
		if not last_outcome.is_empty():
			return {
				"kpis":[],
				"brief":{"tone":"info" if bool(last_outcome.get("success",false)) else "warn","title":"Interception resolved" if bool(last_outcome.get("ok",false)) else "No action taken","why":String(last_outcome.get("message",last_outcome.get("error","The contact ended.")))},
				"blocks":[{"type":"text","heading":"STATUS","text":"The scout marker has left the map because this immediate attempt is over. The result above is now part of the world state."}],
			}
		return {
			"kpis":[],
			"brief":{"tone":"warn","title":"Contact lost","why":"The formation is no longer under reliable observation. No action was taken."},
			"blocks":[{"type":"text","heading":"WHAT NOW","text":"Watch the map for a new sighting. A moving target must remain visible until pursuit or an army makes contact."}],
		}
	var scout:=bool(sighting.get("carries_report",false))
	var hostile:=bool(sighting.get("hostile",false))
	var low:=int(sighting.get("strength_estimate_low",0))
	var high:=int(sighting.get("strength_estimate_high",low))
	var distance:=float(sighting.get("distance_km",0.0))
	var kpis:Array=[
		{"label":"CONTACT","value":"SCOUTS" if scout else "FORMATION","delta":"visible now","accent":Tokens.RED if hostile else Tokens.AMBER,"tip":"A current local observation, not omniscient tracking"},
		{"label":"EST. SIZE","value":"%d–%d" % [low,high],"delta":"uncertain","accent":Tokens.AMBER,"tip":"The public estimate stays a range; exact rival strength remains hidden"},
		{"label":"FROM HOME","value":"%.0f km" % distance,"delta":"","accent":Tokens.MUTED,"tip":"Distance from your primary settlement"},
		{"label":"STATUS","value":"ENEMY" if hostile else "OBSERVED","delta":"","accent":Tokens.RED if hostile else Tokens.TEAL,"tip":"Only a force belonging to a polity already at war with you is an enemy army"},
	]
	if scout: return _scout_tab(sighting,kpis)
	return _formation_tab(sighting,kpis)

func _scout_tab(sighting:Dictionary,kpis:Array)->Dictionary:
	var interception:Dictionary=sighting.get("interception",{})
	var capture_chance:=roundi(float(interception.get("capture",0.0))*100.0)
	var attack_chance:=roundi(float(interception.get("destroy",0.0))*100.0)
	var blocks:Array=[]
	var point:Dictionary=sighting.get("position",{})
	var nearby:Dictionary=terrain._contact_encounter_at(Vector3(float(point.get("x",0)),0,float(point.get("z",0))),0.3)
	if nearby.has("city_id"):
		var nearby_id:=String(nearby.city_id)
		blocks.append({"type":"actions","heading":"THIS COUNTER IS A SCOUT PARTY","items":[{"label":"OPEN NEARBY CITY REPORT","sub":"city movement, attack and siege orders","on_press":func()->void:CivilizationSystem.city_intelligence.open(nearby_id)}]})

	if not last_outcome.is_empty():
		blocks.append({"type":"text","heading":"RESULT","text":String(last_outcome.get("message",last_outcome.get("error","No interception occurred.")))})
	blocks.append({"type":"text","heading":"PURSUIT","text":"Select a fast field army and order it to pursue. Cavalry can close on foot scouts; infantry and siege baggage slow a mixed force. Capturing scouts can provoke their people. The local watch can also attempt an immediate interception below."})
	var army:=_selected_army()
	if army.is_empty():
		blocks.append({"type":"actions","items":[{"label":"SELECT NEAREST FIELD ARMY","on_press":_select_nearest_army}]})
	else:
		var availability:Dictionary=MilitaryCampaign.map_engagement_availability(int(army.get("army_id",0)),formation_id)
		blocks.append({"type":"text","heading":"SELECTED PURSUERS","text":"%s · %.1f km/day sustained march" % [String(army.get("name","Army")),MilitaryCampaign._field_army_speed(army)]})
		if bool(availability.get("can_order",false)):
			blocks.append({"type":"actions","items":[{"label":"PURSUE AND CAPTURE","primary":true,"on_press":_order_engagement.bind(bool(availability.get("can_engage",false)))}]})
		else:
			blocks.append({"type":"text","heading":"PURSUIT BLOCKED","text":String(availability.get("error","Contact lost"))})
	blocks.append({"type":"actions","heading":"INTERCEPT NOW","items":[
		{"label":"CAPTURE SCOUTS · %d%%" % capture_chance,"sub":"prisoners + carried notes","primary":true,"on_press":_resolve_scout.bind("capture"),"tip":"One immediate pursuit. Success stops the report and creates a captive cohort for questioning; failure loses contact."},
		{"label":"ATTACK SCOUTS · %d%%" % attack_chance,"sub":"higher chance · no intelligence","on_press":_resolve_scout.bind("destroy"),"tip":"One immediate lethal pursuit. Success destroys the report but yields no prisoners or notes and sharply raises grievance."},
	]})
	return {
		"kpis":kpis,
		"brief":{"tone":"danger","title":"A foreign report is leaving your territory","why":"Choose CAPTURE or ATTACK now. Either attempt is explicit; nothing happens merely because this card is open."},
		"blocks":blocks,
	}

func _formation_tab(sighting:Dictionary,kpis:Array)->Dictionary:
	var hostile:=bool(sighting.get("hostile",false))
	var army:=_selected_army()
	var blocks:Array=[]
	if not last_outcome.is_empty():
		blocks.append({"type":"text","heading":"ORDER STATUS","text":String(last_outcome.get("message",last_outcome.get("error","No order was issued.")))})
	if not hostile:
		blocks.append({"type":"text","heading":"ATTACKING STARTS A WAR","text":"You may attack without a declaration. War begins when your army makes battle contact; simply viewing or approaching this force does not start war."})
	if army.is_empty():
		blocks.append({"type":"text","heading":"HOW BATTLE STARTS","text":"1. Select a field army.  2. Click this red enemy counter.  3. Order MOVE TO INTERCEPT.  4. If sight is maintained, battle opens automatically when the forces make contact."})
		blocks.append({"type":"actions","items":[{"label":"SELECT NEAREST FIELD ARMY","sub":"make it the active map command","primary":true,"on_press":_select_nearest_army,"tip":"Select the field army closest to this visible enemy"}]})
		return {"kpis":kpis,"brief":{"tone":"danger","title":"Enemy in sight — no army selected","why":"Select a field army here, then issue the intercept order from this same contact card."},"blocks":blocks}
	var availability:Dictionary=MilitaryCampaign.map_engagement_availability(int(army.get("army_id",0)),formation_id)
	var can_engage:=bool(availability.get("can_engage",false))
	var can_order:=bool(availability.get("can_order",false))
	var army_distance:=float(availability.get("distance_km",0.0))
	blocks.append({"type":"rows","heading":"YOUR SELECTED FORCE","items":[{
		"name":String(army.get("name","FIELD ARMY")),
		"sub":"%d personnel · supply %d%%" % [int(army.get("troops",0)),roundi(float(army.get("supply_level",0.0))*100.0)],
		"value":"%.0f km" % army_distance,"value_color":Tokens.GOLD,"accent":Tokens.BLUE,
		"tip":"Distance from the selected army's last reported position to this observed target",
	}]})
	if can_order:
		blocks.append({"type":"actions","heading":"ENGAGEMENT ORDER","items":[{
			"label":"ENGAGE NOW" if can_engage else "MOVE TO INTERCEPT",
			"sub":"battle contact" if can_engage else "track the moving target · %.0f km" % army_distance,
			"primary":true,"on_press":_order_engagement.bind(can_engage),
			"tip":"Open battle now" if can_engage else "The army tracks this target while it remains visible. At close range, battle opens automatically.",
		}]})
	else:
		blocks.append({"type":"text","heading":"ORDER BLOCKED","text":String(availability.get("error","No engagement order is currently possible."))})
	blocks.append({"type":"text","heading":"ON CONTACT","text":"Battle is not an instant dice roll. WAR PLANNING opens with HOLD, PUSH, and RETREAT. Casualties, prisoners, supply, readiness, and aftermath then enter the simulation."})
	return {"kpis":kpis,"brief":{"tone":"danger","title":"Enemy formation in sight","why":"%s is selected. %s" % [String(army.get("name","Your army")),"It is close enough to engage." if can_engage else "Order it to intercept this moving target."]},"blocks":blocks}

func _resolve_scout(action:String)->void:
	last_outcome=terrain._resolve_map_scout_interception(formation_id,action)

func _select_nearest_army()->void:
	last_outcome=terrain._select_nearest_field_army_to_sighting(formation_id)

func _order_engagement(engage_now:bool)->void:
	last_outcome=terrain._resolve_map_formation_engagement(formation_id,engage_now)

func _open_foreign_record(civ_id:String)->void:
	hud.open_detail(preload("res://scripts/hud/content/dock_detail_civ_report.gd").new(terrain,hud,civ_id))

func signature()->Array:
	var sighting:=_sighting()
	return [formation_id,int(CivilizationSystem.observation_revision),int(terrain.selected_army_id),String((last_outcome.get("message",last_outcome.get("error","")))),String(sighting.get("position",{})),MilitaryCampaign.field_armies_snapshot().hash(),MilitaryCampaign.engagement_snapshot().size()]
