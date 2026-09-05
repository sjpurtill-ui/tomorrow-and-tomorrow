extends "res://scripts/hud/content/dock_content_base.gd"
## WORLD section: Contacts / Scouting / Standing.
## Replaces the civilizations panel; deep civilization reports open in the
## second (detail) dock. Dispatch flows stay as pausing confirm modals.

const DetailCivReport:=preload("res://scripts/hud/content/dock_detail_civ_report.gd")

func meta()->Dictionary:
	return {
		"eyebrow":"WORLD STRATEGY · WHAT YOU CAN VERIFY",
		"title":"The Known World",
		"subtabs":["CONTACTS","SCOUTING","STANDING"],
	}

func tab(sub:int)->Dictionary:
	var competition:Dictionary=CivilizationSystem.known_competition_snapshot()
	var knowledge:Dictionary=CivilizationSystem.strategic_knowledge_snapshot()
	var observation:Dictionary=CivilizationSystem.local_observation_snapshot()
	var exploration:Dictionary=CivilizationSystem.exploration_status()
	var contacts:=int(competition.get("contacted_count",0))
	var visible_foreign:=int(observation.get("visible_count",0))
	var rank_hidden:=bool(competition.get("global_rank_hidden",true))
	var kpis:Array=[
		{"label":"CONTACTS","value":str(contacts),"delta":"of ? polities","delta_color":Tokens.MUTED,"accent":Tokens.AMBER,"tip":"Confirmed by sight or returned report"},
		{"label":"IN SIGHT","value":str(visible_foreign),"delta":"%.0f km lookout" % float(observation.get("radius_km",0.0)),"delta_color":Tokens.MUTED,"accent":Tokens.TEAL,"tip":"Foreign formations currently observed"},
		{"label":"REPORTS","value":str(int(exploration.get("report_count",0))),"delta":"returned","delta_color":Tokens.MUTED,"accent":Tokens.GREEN,"tip":"Scout reports that physically returned"},
		{"label":"RANK","value":"hidden" if rank_hidden else "#%d" % int(competition.get("player_rank",0)),"delta":"need contact" if rank_hidden else "of %d" % int(competition.get("contender_count",0)),"delta_color":Tokens.MUTED,"accent":Tokens.MUTED if rank_hidden else Tokens.GOLD,"tip":"Revealed only with sustained contact and comparison"},
	]
	var brief:Dictionary
	if bool(exploration.get("active",false)):
		brief={"tone":"info","title":"A scout party is away","why":String(exploration.get("message",""))}
	elif contacts==0:
		brief={"tone":"warn","title":"No foreign polity has been met","why":"Only a returned scout report reveals new ground or contacts."}
	else:
		brief={"tone":"info","title":"%d polit%s known" % [contacts,"y is" if contacts==1 else "ies are"],"why":"Knowledge is only what physically returned; estimates decay as reports age."}
	match sub:
		1: return {"kpis":kpis,"brief":brief,"blocks":_scouting_blocks(exploration)}
		2: return {"kpis":kpis,"brief":brief,"blocks":_standing_blocks(knowledge,competition)}
	return {"kpis":kpis,"brief":brief,"blocks":_contacts_blocks()}

func _contacts_blocks()->Array:
	var encounters:Array=CivilizationSystem.contact_encounters_snapshot()
	var items:Array=[]
	for encounter_variant in encounters:
		var encounter:Dictionary=encounter_variant
		var civ_id:=String(encounter.get("civ_id",""))
		items.append({
			"name":String(encounter.get("name","Unknown polity")),
			"sub":"met day %d · %s%s" % [int(encounter.get("day",0)),String(encounter.get("source_description",""))," · home located" if bool(encounter.get("home_location_known",false)) else ""],
			"value":"REPORT","value_color":Tokens.GOLD,
			"accent":Tokens.AMBER,
			"on_click":func()->void: hud.open_detail(DetailCivReport.new(terrain,hud,civ_id)),
			"tip":"Open the full known record for this polity",
		})
	var blocks:Array=[]
	if items.is_empty():
		blocks.append({"type":"text","heading":"KNOWN CONTACTS","text":"No polity has been confirmed. An encounter site is not a diplomatic destination until scouts locate a settlement."})
	else:
		blocks.append({"type":"rows","heading":"KNOWN CONTACTS","note":"click for the full record","items":items})
	var rumor_items:Array=[]
	for rumor_variant in CivilizationSystem.rumored_civilizations_snapshot():
		var rumor:Dictionary=rumor_variant
		rumor_items.append({
			"name":String(rumor.get("name","An unnamed people")),
			"sub":"heard day %d · somewhere to the %s · %s" % [int(rumor.get("day",0)),String(rumor.get("direction","?")),String(rumor.get("distance_hint",""))],
			"value":"RUMOR","value_color":Tokens.MUTED,
			"accent":Tokens.MUTED,
			"tip":"Hearsay from newcomers: a name and a rough direction, nothing confirmed. Scouts ranging that way may find them.",
		})
	if not rumor_items.is_empty():
		blocks.append({"type":"rows","heading":"RUMORED PEOPLES","note":"names and directions only","items":rumor_items})
	var diplomatic_status:Dictionary=CivilizationSystem.diplomatic_mission_status()
	var known_destinations:=0
	for encounter_variant in encounters:
		if bool((encounter_variant as Dictionary).get("home_location_known",false)): known_destinations+=1
	var diplomat_presentation:Dictionary=terrain._diplomat_action_presentation(diplomatic_status,known_destinations)
	blocks.append({"type":"actions","items":[
		{"label":"SEND DIPLOMAT","sub":"physical delegation · confirm before departure","primary":known_destinations>0,
		"disabled":bool(diplomat_presentation.disabled),
		"on_press":func()->void: terrain._open_diplomat_dispatch_panel(),
		"tip":String(diplomat_presentation.tooltip)},
		{"label":"SEND SCOUTS","sub":"chart ground · investigate encounters",
		"on_press":func()->void: terrain._open_scout_dispatch_panel(),
		"tip":"Open the scout dispatch review"},
	]})
	return blocks

func _scouting_blocks(exploration:Dictionary)->Array:
	var blocks:Array=[]
	var party_items:Array=[]
	for party_variant in (exploration.get("parties",[]) as Array):
		var party:Dictionary=party_variant
		var overdue:=int(party.get("overdue_days",0))
		party_items.append({
			"name":String(party.get("target_label","Scout party away")),
			"sub":"%d people · OVERDUE %d day%s" % [int(party.get("personnel",0)),overdue,"" if overdue==1 else "s"] if overdue>0 else "%d people · %d days remaining" % [int(party.get("personnel",0)),int(party.get("days_remaining",0))],
			"value":"%d%%" % roundi(float(party.get("progress",0.0))*100.0),"value_color":Tokens.AMBER if overdue>0 else Tokens.TEAL,
			"accent":Tokens.AMBER if overdue>0 else Tokens.TEAL,
			"tip":"The road decides the true return day; an overdue party is not yet a lost one." if overdue>0 else String(party.get("turnback_reason","Observations remain aboard the party until it returns.")),
		})
	if party_items.is_empty():
		var latest:Dictionary=exploration.get("latest_report",{})
		var latest_sub:="no party is away"
		if not latest.is_empty():
			latest_sub="last report day %d" % int(latest.get("day",0))
		party_items.append({"name":"No party away","sub":latest_sub,"value":"","tip":String(exploration.get("message",""))})
	blocks.append({"type":"rows","heading":"PARTIES","note":"%d of %d away" % [int(exploration.get("active_count",0)),int(exploration.get("capacity",1))],"items":party_items})
	var report_actions:Array=[]
	for report_record:Dictionary in CivilizationSystem.scout_reports:
		var saved_report:=report_record.duplicate(true)
		report_actions.append({
			"label":"READ EXPEDITION REPORT", "sub":"day %d · %s" % [int(saved_report.get("day",0)),String(saved_report.get("target_label","open exploration")).to_lower()],
			"on_press":func()->void: hud.open_detail(preload("res://scripts/hud/content/dock_detail_scout_report.gd").new(terrain,hud,saved_report)),
			"tip":"Read this returned expedition's journey, findings and losses. Your simulation speed is unchanged.",
		})
	if not report_actions.is_empty(): blocks.append({"type":"actions","heading":"RETURNED REPORTS","items":report_actions})
	var can_begin:=bool(exploration.get("can_begin",true))
	var duration_items:Array=[]
	for duration in [30,90,180,365]:
		var quote:Dictionary=CivilizationSystem.scout_mission_quote(duration,"open_world")
		var can_dispatch:=bool(quote.get("can_dispatch",false))
		var sub_text:="%d people · %d rations" % [int(quote.get("personnel",0)),roundi(float(quote.get("provisions",0.0)))] if can_dispatch else String(quote.get("blocker",quote.get("error","unavailable"))).to_lower().substr(0,42)
		duration_items.append({
			"label":"DISPATCH %d DAYS" % duration,"sub":sub_text,
			"primary":duration==90 and can_dispatch,
			"disabled":not can_dispatch,
			"on_press":func()->void: terrain._open_scout_dispatch_panel(),
			"tip":"Review personnel, provisions, risk, and target before anything departs",
		})
	blocks.append({"type":"actions","items":duration_items})
	blocks.append({"type":"text","text":"Nothing is revealed while a party is away. Personnel and provisions leave at departure; interception can erase an entire report. Up to %d parties can range at once; logistics, travel knowledge, and mounts determine their range." % int(exploration.get("capacity",1))})
	return blocks

func _standing_blocks(knowledge:Dictionary,competition:Dictionary)->Array:
	var blocks:Array=[
		{"type":"text","heading":String(knowledge.get("title","NO COMPARATIVE FRAMEWORK")),"text":String(knowledge.get("summary",""))},
		{"type":"text","heading":"NEXT","text":String(knowledge.get("next_step",""))},
	]
	if bool(knowledge.get("victory_structure_known",false)):
		blocks.append({"type":"text","heading":"VICTORY","text":String(competition.get("victory_rule","")) if competition.has("victory_rule") else "After Year 20, lead four of seven domains with a 10% overall lead held twelve consecutive months. Rivals are judged by the same rule."})
	return blocks

func signature()->Array:
	var exploration:Dictionary=CivilizationSystem.exploration_status()
	var overdue_total:=0
	for party_variant in (exploration.get("parties",[]) as Array):
		overdue_total+=int((party_variant as Dictionary).get("overdue_days",0))
	return [CivilizationSystem.contact_encounters_snapshot().size(),CivilizationSystem.rumored_civilizations_snapshot().size(),int(exploration.get("active_count",0)),int(exploration.get("days_remaining",0)),overdue_total,int(exploration.get("report_count",0))]
