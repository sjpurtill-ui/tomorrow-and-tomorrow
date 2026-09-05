extends "res://scripts/hud/content/dock_content_base.gd"
## Detail dock: one returned scout expedition's full report. Opened
## on demand after a party comes home — the report can
## be read without changing simulation speed.

const Archive:=preload("res://scripts/scout_archive.gd")
var report:Dictionary={}
var return_provider:Object

func _init(terrain_node:Node,hud_node:Control,report_record:Dictionary={},archive_provider:Object=null)->void:
	super(terrain_node,hud_node)
	return_provider=archive_provider
	Archive.mark_reviewed(report_record)
	report=report_record.duplicate(true)
	CivilizationSystem._strip_retired_landmarks(report)

func meta()->Dictionary:
	var title:=String(Archive.summary(report).title)
	return {
		"eyebrow":"THE EXPEDITION CHRONICLES · DAY %d" % int(report.get("day",0)),
		"title":title,
		"subtabs":["DISCOVERIES","JOURNEY & ACCOUNTS"],
	}

func tab(_sub:int)->Dictionary:
	var personnel:=maxi(1,int(report.get("personnel",1)))
	var returned:=int(report.get("returned_personnel",personnel))
	var lost:=int(report.get("lost_personnel",0))
	var stayed:=int(report.get("stayed_personnel",0))
	var recruits:=int(report.get("recruits",0))
	var recruitment:Dictionary=report.get("recruitment_account",{})
	var is_recruitment:=not recruitment.is_empty() or String(report.get("mission_kind",""))=="recruit_people"
	var contacts:Array=report.get("contacts",[])
	var kpis:Array=[
		{"label":"RETURNED","value":"%d of %d" % [returned,personnel],"delta":"%d lost · %d stayed" % [lost,stayed] if lost+stayed>0 else "all came home","delta_color":Tokens.RED if lost>0 else (Tokens.AMBER if stayed>0 else Tokens.GREEN),"accent":Tokens.RED if lost>0 else Tokens.GREEN,"tip":"The party that left against the party that came home"},
		{"label":"DAYS AWAY","value":str(int(report.get("actual_days",report.get("duration_days",0)))),"delta":"actual" if report.has("actual_days") else "planned · older record","delta_color":Tokens.MUTED,"accent":Tokens.TEAL,"tip":"Elapsed days from departure to return, when recorded"},
		{"label":"JOURNEY","value":"%d km" % int(report.get("distance_km",0)),"delta":"out & back","delta_color":Tokens.MUTED,"accent":Tokens.BLUE,"tip":"Total route distance, including the journey home"},
		{"label":"NEWCOMERS","value":"+%d" % recruits if recruits>0 else "0","delta":"joined","delta_color":Tokens.GREEN if recruits>0 else Tokens.MUTED,"accent":Tokens.GREEN,"tip":"Wanderers who threw in their lot with the settlement"},
	]
	var brief:Dictionary
	if lost>0:
		brief={"tone":"danger","title":"Not all who left came home","why":"%d of the party were lost on the road%s." % [lost,", and %d chose to remain with people they met" % stayed if stayed>0 else ""]}
	elif stayed>0:
		brief={"tone":"warn","title":"Some chose another life","why":"%d of the party remained with people met on the road — alive, but no longer ours." % stayed}
	elif is_recruitment and recruits>0:
		brief={"tone":"info","title":"%d people chose to join" % recruits,"why":String(recruitment.get("summary","The recruitment party returned with newcomers."))}
	elif is_recruitment and int(recruitment.get("encountered",0))>0:
		brief={"tone":"warn","title":"They found people; no one came","why":String(recruitment.get("summary","Everyone approached declined the settlement's offer."))}
	elif is_recruitment:
		brief={"tone":"warn","title":"The recruitment party returned alone","why":String(recruitment.get("summary","No one willing to join was found."))}
	elif recruits>=10:
		brief={"tone":"info","title":"The gamble paid out","why":"The whole party came home, and %d newcomers walked in with them." % recruits}
	else:
		brief={"tone":"info","title":String(Archive.summary(report).title),"why":String(Archive.summary(report).detail)}
	var blocks:Array=[]
	if return_provider!=null:
		blocks.append({"type":"actions","items":[{"label":"BACK TO ARCHIVE","sub":"keep search, filter and page","on_press":func()->void: hud.open_detail(return_provider)}]})
	if is_recruitment:
		blocks.append({"type":"text","heading":"RECRUITMENT OUTCOME","text":String(recruitment.get("summary","The party returned without a detailed account of whom it approached."))})
		var encountered:=int(recruitment.get("encountered",0))
		if encountered>0:
			blocks.append({"type":"rows","heading":"WHO THEY MET","items":[{
				"name":String(recruitment.get("group","People on the road")).capitalize(),
				"sub":"%d approached · %d joined · %d declined" % [encountered,recruits,int(recruitment.get("declined",maxi(0,encountered-recruits)))],
				"value":"%d JOINED" % recruits if recruits>0 else "NONE","value_color":Tokens.GREEN if recruits>0 else Tokens.AMBER,"accent":Tokens.GREEN if recruits>0 else Tokens.AMBER,
			}]})
		var reason_lines:Array[String]=[]
		for reason_variant in recruitment.get("reasons",[]): reason_lines.append("• "+String(reason_variant))
		if not reason_lines.is_empty(): blocks.append({"type":"text","heading":"WHY THEY DECIDED","text":"\n".join(reason_lines)})
	if _sub==0:
		var discoveries:Array=report.get("discoveries",[])

		if not contacts.is_empty():
			blocks.append({"type":"discovery","kind":"encounter","title":"Other people, beyond our horizon","description":"Direct contact with %s." % ", ".join(PackedStringArray(contacts)),"consequence":"Their encounter sites are marked on the returned route. Contact is a beginning; it does not reveal their homeland."})
		for finding in discoveries:
			if Archive.routine_finding(finding): continue
			var card:Dictionary=finding.duplicate(true)
			card["type"]="discovery"
			blocks.append(card)
		if not discoveries.is_empty() and Archive.significant_findings(report).is_empty():
			blocks.append({"type":"text","heading":"SURVEY NOTES","text":"No additional findings recorded. Route sketches and routine evidence remain in Journey & Accounts."})
		if discoveries.is_empty():
			# Old saves retain their real outcomes; a new design must not invent rewards.
			var roadside_notes:=false
			for finding in report.get("windfalls",[]):
				var account:=String(finding)
				var normalized:=account.to_lower()
				if ("occurrence" in normalized and ("fiber plants" in normalized or "stone" in normalized or "timber" in normalized)) or "party hauls back" in normalized:
					roadside_notes=true
					continue
				if "charts and accounts circulate" in normalized:
					blocks.append({"type":"discovery","kind":"knowledge","title":"Routes worth remembering","description":"The party's charts and observations are being studied at home.","consequence":account})
				else: blocks.append({"type":"discovery","kind":"field note","title":"From the returning party","description":account})
			if roadside_notes:
				blocks.append({"type":"discovery","kind":"roadside supplies","title":"What sustained the journey","description":"The party recorded ordinary materials along the road and any supplies it carried home.","consequence":"These are useful local resupply notes, not distant treasure. The original locations and quantities are preserved in Journey & Accounts."})
			if report.get("windfalls",[]).is_empty(): blocks.append({"type":"text","text":"The route is the discovery. No additional finds were recorded on this journey."})
		blocks.append({"type":"text","text":"Read Journey & Accounts for the road, encounters and supplies. Reading a report leaves your chosen simulation speed unchanged."})
		return {"kpis":kpis,"brief":brief,"blocks":blocks}
	for finding:Dictionary in report.get("discoveries",[]):
		if Archive.routine_finding(finding) and String(finding.get("kind",""))!="landmark":
			blocks.append({"type":"text","heading":String(finding.get("title","FIELD NOTES")),"text":String(finding.get("description",""))+" "+String(finding.get("consequence",""))})
	blocks.append({"type":"expedition_chart","route":report.get("route",[]),"discoveries":report.get("discoveries",[])})
	var journal:Array=report.get("journal",[])
	if not journal.is_empty():
		var journal_lines:Array[String]=[]
		for entry in journal: journal_lines.append(String(entry))
		blocks.append({"type":"text","heading":"THE JOURNEY","text":"\n".join(journal_lines)})
	var turnback:=String(report.get("turnback_reason",""))
	if turnback!="":
		blocks.append({"type":"text","heading":"THE ROUTE","text":turnback})
	if not contacts.is_empty():
		var contact_items:Array=[]
		for contact_name in contacts:
			contact_items.append({"name":String(contact_name),"sub":"direct contact · encounter site marked on the route","value":"","accent":Tokens.AMBER,"tip":"An encounter site is not a homeland; investigate it to find routes onward"})
		blocks.append({"type":"rows","heading":"FIRST CONTACT","items":contact_items})
	var targeted:=String(report.get("target_finding",""))
	if targeted!="":
		blocks.append({"type":"text","heading":"THE MISSION'S QUESTION","text":targeted})
	var windfalls:Array=report.get("windfalls",[])
	if windfalls.is_empty() and contacts.is_empty() and targeted=="" and not is_recruitment and Archive.significant_findings(report).is_empty() and (report.get("city_observations",[]) as Array).is_empty():
		blocks.append({"type":"text","heading":"FINDINGS","text":"No additional findings were recorded. The returned route and survey notes remain available."})
	else:
		var findings:Array[String]=[]
		for windfall in windfalls: findings.append("• "+String(windfall))
		if not findings.is_empty():
			blocks.append({"type":"text","heading":"FINDINGS","text":"\n".join(findings)})
	if not _cover_path().is_empty():
		blocks.append({"type":"image","path":_cover_path(),"height":112,"cover":true,"tip":"Illustration inspired by recorded terrain; not evidence of a particular landmark."})
		blocks.append({"type":"text","text":"Illustration inspired by the saved terrain account. The route chart above is the recorded evidence."})
	blocks.append({"type":"text","text":"Reports stay available here; pause or change speed whenever you choose."})
	return {"kpis":kpis,"brief":brief,"blocks":blocks}

func signature()->Array:
	return [int(report.get("day",0)),String(report.get("target_id",""))]

func _cover_path()->String:
	return Archive.artwork(report)
