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
		1: return {"kpis":[kpis[2]],"brief":{"title":"Scouts are away" if bool(exploration.get("active",false)) else "Read what returned, then choose your next expedition","why":"Return dates are estimates. An overdue party is still on the road until a report or loss is confirmed." if bool(exploration.get("active",false)) else "Recent returns below open the findings. Every retained report remains in the Expedition Archive."},"blocks":_scouting_blocks(exploration)}
		2: return {"kpis":kpis,"brief":brief,"blocks":_standing_blocks(knowledge,competition)}
	return {"kpis":[kpis[0],kpis[2]],"brief":brief,"blocks":_contacts_blocks()}

func _contacts_blocks()->Array:
	var encounters:Array=CivilizationSystem.contact_encounters_snapshot()
	var items:Array=[]
	for encounter_variant in encounters:
		var encounter:Dictionary=encounter_variant
		var civ_id:=String(encounter.get("civ_id",""))
		items.append({
			"name":String(encounter.get("name","Unknown polity")),
			"sub":"met year %d, day %d · %s%s" % [int(encounter.get("day",0))/365+1,int(encounter.get("day",0))%365+1,String(encounter.get("source_description",""))," · home located" if bool(encounter.get("home_location_known",false)) else ""],
			"value":"REPORT","value_color":Tokens.GOLD,
			"accent":Tokens.AMBER,
			"on_click":func()->void: hud.open_detail(DetailCivReport.new(terrain,hud,civ_id)),
			"tip":"Open the full known record for this polity",
		})
	var blocks:Array=[{"type":"text","heading":"WHAT IS KNOWN","text":"Rumors are unverified leads. Encounters record where people were met. A located settlement supplies a destination for diplomacy; an encounter alone does not."}]
	if items.is_empty():
		blocks.append({"type":"text","heading":"KNOWN CONTACTS","text":"No polity has been confirmed. An encounter site is not a diplomatic destination until scouts locate a settlement."})
	else:
		blocks.append({"type":"rows","heading":"KNOWN CONTACTS","note":"click for the full record","items":items})
	var lead_count:=CivilizationSystem.rumor_network.list_leads("player",int(GameState.elapsed_days)).size()
	blocks.append({"type":"actions","heading":"ACCOUNTS BEYOND THE HORIZON","items":[{"label":"MAP OF RUMORS","sub":"%d mapped leads · where accounts were heard and where people may be" % lead_count,"on_press":func()->void: CivilizationSystem.rumor_network.open_map(terrain)}]})
	if not CivilizationSystem.rumored_civilizations_snapshot().is_empty():
		blocks.append({"type":"text","text":"Older hearsay has no recorded map coordinates. Its saved names and directions remain in expedition reports; no location is invented."})
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
			"value":"Overdue" if overdue>0 else "Due ~day %d"%int(party.get("return_day",0)),"value_color":Tokens.AMBER if overdue>0 else Tokens.TEAL,
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
	var archive_model:=preload("res://scripts/scout_archive.gd")
	var archive_provider:=preload("res://scripts/hud/content/dock_detail_scout_archive.gd")
	var highlights:Array=[]
	var newest:=archive_model.select(CivilizationSystem.scout_reports,"",0,false).slice(0,8)
	newest.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.priority)>int(b.priority))
	for item:Dictionary in newest.slice(0,3):
		var saved_report:Dictionary=item.report
		highlights.append({"name":String(item.title),"sub":"Day %d · %s · %s" % [item.day,item.party,item.place],"value":String(item.review),"accent":Tokens.RED if int(item.losses)>0 else Tokens.TEAL,"on_click":func()->void: hud.open_detail(preload("res://scripts/hud/content/dock_detail_scout_report.gd").new(terrain,hud,saved_report,archive_provider.new(terrain,hud)))})
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
