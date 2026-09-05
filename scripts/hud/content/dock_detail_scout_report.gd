extends "res://scripts/hud/content/dock_content_base.gd"
## Detail dock: one returned scout expedition's full report. Opened
## automatically when a party comes home — the world pauses so the report can
## be read; choosing any speed resumes it.

var report:Dictionary={}

func _init(terrain_node:Node,hud_node:Control,report_record:Dictionary={})->void:
	super(terrain_node,hud_node)
	report=report_record.duplicate(true)
	CivilizationSystem._strip_retired_landmarks(report)

func meta()->Dictionary:
	var title:="Beyond the familiar world" if String(report.get("mission_kind","explore"))=="explore" else String(report.get("target_label","Scout Expedition")).capitalize()
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
		brief={"tone":"info","title":"They brought the horizon home","why":"%d travelers returned with a route through the unknown. Here is what they found—and what it could mean for your people." % returned}
	var blocks:Array=[]
	if _sub==0:
		var discoveries:Array=report.get("discoveries",[])
		blocks.append({"type":"image","path":_cover_path(),"height":225,"cover":true,"tip":"Symbolic expedition cover inspired by the recorded journey. The actual route chart is in Journey & Accounts."})
		if not contacts.is_empty():
			blocks.append({"type":"discovery","kind":"encounter","title":"Other people, beyond our horizon","description":"Direct contact with %s." % ", ".join(PackedStringArray(contacts)),"consequence":"Their encounter sites are marked on the returned route. Contact is a beginning; it does not reveal their homeland."})
		for finding in discoveries:
			var card:Dictionary=finding.duplicate(true)
			card["type"]="discovery"
			blocks.append(card)
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
		blocks.append({"type":"text","text":"Read Journey & Accounts for the road, encounters and supplies. The world remains paused; choose a speed when you are ready."})
		return {"kpis":kpis,"brief":brief,"blocks":blocks}
	blocks.append({"type":"expedition_chart","route":report.get("route",[]),"discoveries":report.get("discoveries",[])})
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
	if windfalls.is_empty() and contacts.is_empty() and targeted=="" and not is_recruitment:
		blocks.append({"type":"text","heading":"FINDINGS","text":"The party found only ground: no people, no workable deposits, nothing worth a name. The charted route itself is the whole of the report."})
	else:
		var findings:Array[String]=[]
		for windfall in windfalls: findings.append("• "+String(windfall))
		if not findings.is_empty():
			blocks.append({"type":"text","heading":"FINDINGS","text":"\n".join(findings)})
	blocks.append({"type":"text","text":"The world is paused while you read. Choose any speed to resume."})
	return {"kpis":kpis,"brief":brief,"blocks":blocks}

func signature()->Array:
	return [int(report.get("day",0)),String(report.get("target_id",""))]

func _cover_path()->String:
	# Read saved observations, never resurvey a changed world or consume simulation RNG.
	var journal:= " ".join(PackedStringArray(report.get("journal",[]))).to_lower()
	var candidates:Array[String]=[]
	var keywords:Dictionary={"forest":["woodland","forest"],"desert":["drylands","desert","dunes"],"mountains":["summit","high bare ground","mountain","treeline"],"river":["running water","river","wetland","floodplain"]}
	for scene in keywords:
		for word in keywords[scene]:
			if String(word) in journal:
				candidates.append(scene)
				break
	var selected:="dawn"
	if not candidates.is_empty():
		var identity:="%s:%s:%s" % [report.get("mission_id",0),report.get("day",0),report.get("target_id","")]
		selected=candidates[posmod(identity.hash(),candidates.size())]
	return "res://assets/textures/expeditions/chronicle-%s.png" % selected
