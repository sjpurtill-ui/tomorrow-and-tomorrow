extends "res://scripts/hud/content/dock_content_base.gd"
## WORLD section: Contacts / Scouting / Standing.
## Replaces the civilizations panel; deep civilization reports open in the
## second (detail) dock. Dispatch flows stay as pausing confirm modals.

const DetailCivReport:=preload("res://scripts/hud/content/dock_detail_civ_report.gd")

func meta()->Dictionary:
	return {
		"eyebrow":"WORLD · CONTACTS & EXPLORATION",
		"title":"The Known World",
		"subtabs":["WORLD OVERVIEW","EXPEDITIONS","STANDING"],
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
		1: return {"kpis":[kpis[2]],"brief":{"title":"Scouts are away" if bool(exploration.get("active",false)) else "Read what returned, then choose your next expedition","why":"Return dates are estimates. An overdue party is still on the road until a report or loss is confirmed." if bool(exploration.get("active",false)) else "Recent returns below open the findings. Every retained report remains in the Expedition Archive."},"blocks":_scouting_blocks(exploration)}
		2: return {"kpis":kpis,"brief":brief,"blocks":_standing_blocks(knowledge,competition)}
	return {"blocks":_world_board(exploration)}

func _scouting_blocks(exploration:Dictionary)->Array:
	var blocks:Array=[]
	var party_items:Array=[]
	for party_variant in (exploration.get("parties",[]) as Array):
		var party:Dictionary=party_variant
		var overdue:=int(party.get("overdue_days",0))
		party_items.append({
			"name":String(party.get("target_label","Scout party away")),
			"sub":"%d people · OVERDUE %d day%s" % [int(party.get("personnel",0)),overdue,"" if overdue==1 else "s"] if overdue>0 else "%d people · %d days remaining" % [int(party.get("personnel",0)),int(party.get("days_remaining",0))],
			"value":"Overdue" if overdue>0 else preload("res://scripts/scout_archive.gd").calendar_date(int(party.get("return_day",0))),"value_color":Tokens.AMBER if overdue>0 else Tokens.TEAL,
			"accent":Tokens.AMBER if overdue>0 else Tokens.TEAL,
			"tip":"The road decides the true return day; an overdue party is not yet a lost one." if overdue>0 else String(party.get("turnback_reason","Observations remain aboard the party until it returns.")),
		})
	if party_items.is_empty():
		var latest:Dictionary=exploration.get("latest_report",{})
		var latest_sub:="no party is away"
		if not latest.is_empty():
			latest_sub="Last return · " + preload("res://scripts/scout_archive.gd").calendar_date(int(latest.get("day",0)))
		party_items.append({"name":"No party away","sub":latest_sub,"value":"","tip":String(exploration.get("message",""))})
	blocks.append({"type":"rows","heading":"PARTIES","note":"%d of %d away" % [int(exploration.get("active_count",0)),int(exploration.get("capacity",1))],"items":party_items})
	var archive_model:=preload("res://scripts/scout_archive.gd")
	var archive_provider:=preload("res://scripts/hud/content/dock_detail_scout_archive.gd")
	var highlights:Array=[]
	var newest:=archive_model.select(CivilizationSystem.scout_reports,"",0,false).slice(0,8)
	newest.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.priority)>int(b.priority))
	for item:Dictionary in newest.slice(0,3):
		var saved_report:Dictionary=item.report
		highlights.append({"name":String(item.title),"sub":"%s · %s · %s" % [archive_model.calendar_date(int(item.day)),item.party,item.place],"value":String(item.review),"accent":Tokens.RED if int(item.losses)>0 else Tokens.TEAL,"on_click":func()->void: hud.open_detail(preload("res://scripts/hud/content/dock_detail_scout_report.gd").new(terrain,hud,saved_report,archive_provider.new(terrain,hud)))})
	blocks.append({"type":"actions","items":[{"label":"EXPEDITION ARCHIVE","sub":"Search, filter and read %d retained reports" % CivilizationSystem.scout_reports.size(),"on_press":func()->void: hud.open_detail(archive_provider.new(terrain,hud))}]})
	if not highlights.is_empty(): blocks.append({"type":"rows","heading":"RECENT RETURNS","note":"highlights from the latest eight","items":highlights})
	blocks.append({"type":"actions","items":[{"label":"PLAN EXPEDITION","sub":"Review target, duration, people and provisions","primary":true,"on_press":func()->void:terrain._open_scout_dispatch_panel()}]})
	blocks.append({"type":"text","text":"Nothing is revealed while a party is away. Personnel and provisions leave at departure; interception can erase an entire report. Up to %d parties can range at once; logistics, travel knowledge, and mounts determine their range." % int(exploration.get("capacity",1))})
	return blocks

func _standing_blocks(knowledge:Dictionary,competition:Dictionary)->Array:
	var blocks:Array=[
		{"type":"text","heading":String(knowledge.get("title","NO COMPARATIVE FRAMEWORK")),"text":String(knowledge.get("summary",""))},
		{"type":"text","heading":"NEXT","text":String(knowledge.get("next_step",""))},
	]
	var history:Dictionary=CivilizationSystem.chronicle.snapshot(int(GameState.elapsed_days))
	blocks.push_front(preload("res://scripts/undertaking_rewards.gd").victory_block(GameState))
	blocks.push_front({"type":"text","heading":String(history.title).to_upper(),"text":"Year %d · %s\n\n%s"%[int(history.year),String(history.summary),String(history.next)]})
	var records:Array=[]
	for item:Dictionary in history.recent:
		records.append({"name":String(item.kind),"sub":"Year %d"%(int(item.day)/365),"detail":String(item.text)})
	if not records.is_empty():blocks.append({"type":"rows","heading":"WHAT ENDURED AND CHANGED","items":records})
	if bool(history.review_available):
		blocks.append({"type":"actions","items":[{"label":"REVIEW OUR LEGACY","sub":"Record a closing account; you may continue playing","on_press":func():CivilizationSystem.chronicle.reckon(int(GameState.elapsed_days));hud.request_immediate_dock_refresh()}]})
	if not history.reckonings.is_empty():blocks.append({"type":"text","heading":"LEGACY ACCOUNT","text":String(history.reckonings[-1].text)})

	return blocks

func signature()->Array:
	var exploration:Dictionary=CivilizationSystem.exploration_status()
	var overdue_total:=0
	for party_variant in (exploration.get("parties",[]) as Array):
		overdue_total+=int((party_variant as Dictionary).get("overdue_days",0))
	return [CivilizationSystem.rumor_network.revision,int(GameState.elapsed_days),CivilizationSystem.contact_encounters_snapshot().size(),CivilizationSystem.rumored_civilizations_snapshot().size(),int(exploration.get("active_count",0)),int(exploration.get("days_remaining",0)),overdue_total,int(exploration.get("report_count",0)),preload("res://scripts/scout_archive.gd").revision(CivilizationSystem.scout_reports)]

func _world_board(exploration:Dictionary)->Array:
	var archive=preload("res://scripts/scout_archive.gd")
	var archive_provider=preload("res://scripts/hud/content/dock_detail_scout_archive.gd")
	var encounters:Array=CivilizationSystem.contact_encounters_snapshot()
	var destinations:=0
	var contacts:Array=[]
	for encounter:Dictionary in encounters:
		var id:=String(encounter.get("civ_id",""))
		var located:=bool(encounter.get("home_location_known",false))
		if located:destinations+=1
		contacts.append({"tag":"DIPLOMATIC DESTINATION" if located else "ENCOUNTER · HOME NOT LOCATED","title":String(encounter.get("name","Unknown polity")),"detail":"%s · %s" % [archive.calendar_date(int(encounter.get("day",0))),String(encounter.get("source_description","Returned encounter"))],"action":"View known record","on_press":func()->void:hud.open_detail(DetailCivReport.new(terrain,hud,id))})
	if contacts.is_empty():
		contacts.append({"tag":"CONTACTS","title":"No societies encountered","detail":"Explore further to meet neighbors and locate their settlements."})
	var leads:=CivilizationSystem.rumor_network.list_leads("player",int(GameState.elapsed_days)).size()
	if leads>0:contacts.append({"tag":"UNVERIFIED LEADS","title":"%d rumors mapped" % leads,"detail":"Follow a lead to investigate possible neighbors.","action":"Open rumor map","on_press":func()->void:CivilizationSystem.rumor_network.open_map(terrain)})
	var operations:Array=[]
	for party:Dictionary in exploration.get("parties",[]):
		var overdue:=int(party.get("overdue_days",0))
		operations.append({"tag":"OVERDUE · NOT CONFIRMED LOST" if overdue>0 else "EXPEDITION UNDERWAY","title":String(party.get("target_label","Exploring")),"detail":"%d scouts · %s" % [int(party.get("personnel",0)),"%d days overdue" % overdue if overdue>0 else "about %d days until return" % int(party.get("days_remaining",0))]})
	var findings:Array=[]
	for item:Dictionary in archive.select(CivilizationSystem.scout_reports,"",0,false).slice(0,4):
		var report:Dictionary=item.report
		findings.append({"tag":"%s · %s" % [archive.calendar_date(int(item.day)),String(item.kind)],"title":String(item.title),"detail":String(item.place),"unread":String(item.review)=="UNREAD","action":"Read report","on_press":func()->void:hud.open_detail(preload("res://scripts/hud/content/dock_detail_scout_report.gd").new(terrain,hud,report,archive_provider.new(terrain,hud)))})
	if findings.is_empty():findings.append({"tag":"AWAITING FIRST RETURN","title":"The world is still unwritten","detail":"Returned scouts bring route charts, resources and encounters here."})
	var presentation:Dictionary=terrain._diplomat_action_presentation(CivilizationSystem.diplomatic_mission_status(),destinations)
	var active:=int(exploration.get("active_count",0))
	var capacity:=int(exploration.get("capacity",1))
	var actions:Array=[
		{"label":"Plan expedition","primary":true,"on_press":func()->void:terrain._open_scout_dispatch_panel()},
		{"label":"Report archive (%d)" % int(exploration.get("report_count",0)),"on_press":func()->void:hud.open_detail(archive_provider.new(terrain,hud))}]
	if destinations>0:
		actions.append({"label":"Send diplomat","disabled":bool(presentation.disabled),"tip":String(presentation.tooltip),"on_press":func()->void:terrain._open_diplomat_dispatch_panel()})
	return [{"type":"world_board","title":"Explore beyond the familiar",
		"subtitle":"%d parties away · %d available" % [active,maxi(0,capacity-active)],"actions":actions,
		"sections":[{"title":"RECENT DISCOVERIES","items":findings},{"title":"ON THE HORIZON","items":operations+contacts}]}]
