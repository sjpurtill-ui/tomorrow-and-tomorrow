extends "res://scripts/hud/content/dock_content_base.gd"
## Detail dock: one returned scout expedition's full report. Opened
## on demand after a party comes home.

const Archive:=preload("res://scripts/scout_archive.gd")
const When:=preload("res://scripts/hud/report_when.gd")
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
		"eyebrow":("Watching a city" if String(report.get("mission_kind",""))=="observe_city" else "A scouting party's telling")+" · "+Archive.calendar_date(int(report.get("day",0))),
		"title":title,
		"subtabs":["What they saw of the city" if String(report.get("mission_kind",""))=="observe_city" else "What they found","The journey"],
	}

func tab(_sub:int)->Dictionary:
	var personnel:=maxi(1,int(report.get("personnel",1)))
	var returned:=int(report.get("returned_personnel",personnel))
	var lost:=int(report.get("lost_personnel",0))
	var stayed:=int(report.get("stayed_personnel",0))
	var recruits:=int(report.get("recruits",0))
	var recruitment:Dictionary=report.get("recruitment_account",{})
	var is_recruitment:=not recruitment.is_empty() or String(report.get("mission_kind","")) in ["recruit_people","recruit_nomads","recruit_people_visit"]
	var contacts:Array=report.get("contacts",[])
	var kpis:Array=[
		{"label":"Came home","value":"%d of %d" % [returned,personnel],"delta":"%d lost · %d stayed" % [lost,stayed] if lost+stayed>0 else "all came home","delta_color":Tokens.RED_TEXT if lost>0 else (Tokens.AMBER_TEXT if stayed>0 else Tokens.GREEN_TEXT),"accent":Tokens.RED if lost>0 else Tokens.GREEN,"tip":"How many set out, and how many came back"},
		{"label":"Time away","value":When.span(int(report.get("actual_days",report.get("duration_days",0)))),"delta":"from "+String(report.get("origin_label","home")),"delta_color":Tokens.INK_MUTED,"accent":Tokens.TEAL,"tip":"From the day they left to the day they came home"},
		{"label":"Distance walked","value":"%d km" % int(report.get("distance_km",0)),"delta":"there and back","delta_color":Tokens.INK_MUTED,"accent":Tokens.BLUE,"tip":"The whole road, including the way home"},
		{"label":"Newcomers","value":"+%d" % recruits if recruits>0 else "None","delta":"joined us" if recruits>0 else "","delta_color":Tokens.GREEN_TEXT if recruits>0 else Tokens.INK_MUTED,"accent":Tokens.GREEN,"tip":"Wanderers who chose to come and live with us"},
	]
	var brief:Dictionary
	if lost>0:
		brief={"tone":"danger","title":"Not all who left came home","why":"%d of the party were lost on the road%s." % [lost,", and %d chose to remain with people they met" % stayed if stayed>0 else ""]}
	elif stayed>0:
		brief={"tone":"warn","title":"Some chose another life","why":"%d of the party remained with people met on the road — alive, but no longer ours." % stayed}
	elif is_recruitment and recruits>0:
		brief={"tone":"info","title":"%d people chose to join" % recruits,"why":String(recruitment.get("summary","The recruitment party returned with newcomers."))}
	elif is_recruitment and (int(recruitment.get("encountered",0))>0 or bool(recruitment.get("met_community",false))):
		brief={"tone":"warn","title":"They found people; no one came","why":String(recruitment.get("summary","Everyone approached declined the settlement's offer."))}
	elif is_recruitment:
		brief={"tone":"warn","title":"The recruitment party returned alone","why":String(recruitment.get("summary","No one willing to join was found."))}
	elif recruits>=10:
		brief={"tone":"info","title":"The gamble paid out","why":"The whole party came home, and %d newcomers walked in with them." % recruits}
	else:
		brief={"tone":"info","title":String(Archive.summary(report).title),"why":String(Archive.summary(report).detail)}
	var blocks:Array=[]
	if String(report.get("mission_kind",""))=="observe_city":
		var city:=Archive.city_record(report)
		kpis[3]={"label":"Time watching","value":When.span(int(city.get("observation_days",0))),"delta":"at the city","accent":Tokens.TEAL}
		brief={"tone":"warn" if lost>0 or city.is_empty() else "info","title":String(Archive.summary(report).title),"why":Archive.city_account(report)}
		if _sub==0:
			var visuals=preload("res://scripts/hud/city_report_visuals.gd")
			var rows:Array=[]
			for key:String in visuals.shown_keys():
				var field:Dictionary=city.get("fields",{}).get(key,{})
				rows.append({"name":String(visuals.label(key)),"value":String(visuals.words(key,field)),"sub":"Seen by the scouts" if not field.is_empty() else "Not seen","accent":Tokens.TEAL})
			blocks.append({"type":"rows","heading":"The target city, as they saw it","items":rows})
			blocks.append({"type":"text","text":"This is what they saw then; the city may have changed since. The journey tab has their road and anything else they found."})
			if return_provider!=null:blocks.append({"type":"actions","items":[{"label":"Back to every telling","on_press":func()->void:hud.open_detail(return_provider)}]})
			return {"kpis":kpis,"brief":brief,"blocks":blocks}
	if return_provider!=null:
		blocks.append({"type":"actions","items":[{"label":"Back to every telling","sub":"Where you left off","on_press":func()->void: hud.open_detail(return_provider)}]})
	if is_recruitment:
		blocks.append({"type":"text","heading":"Who came back with them","text":String(recruitment.get("summary","The party returned without a detailed account of whom it approached."))})
		var encountered:=int(recruitment.get("encountered",0))
		if encountered>0 or bool(recruitment.get("met_community",false)):
			var declined:=int(recruitment.get("declined",0))
			blocks.append({"type":"rows","heading":"Who they met","items":[{
				"name":_first_up(String(recruitment.get("group","People on the road"))),
				"sub":"%d joined · %d declined" % [recruits,declined] if declined>0 else ("%d traveling · %d joined" % [encountered,recruits] if encountered>0 else "community visited · no household transfer"),
				"value":"%d joined" % recruits if recruits>0 else "None joined","value_color":Tokens.GREEN_TEXT if recruits>0 else Tokens.AMBER_TEXT,"accent":Tokens.GREEN if recruits>0 else Tokens.AMBER,
			}]})
		var reason_lines:Array[String]=[]
		for reason_variant in recruitment.get("reasons",[]): reason_lines.append("• "+String(reason_variant))
		if not reason_lines.is_empty(): blocks.append({"type":"text","heading":"Why they decided","text":"\n".join(reason_lines)})
		var diplomatic_response:=String(recruitment.get("diplomatic_response",""))
		if not diplomatic_response.is_empty():blocks.append({"type":"text","heading":"What their leaders made of it","text":diplomatic_response})
	if _sub==0:
		var discoveries:Array=report.get("discoveries",[])

		if not contacts.is_empty():
			blocks.append({"type":"discovery","kind":"encounter","title":"Other people, beyond our horizon","description":"Direct contact with %s." % ", ".join(PackedStringArray(contacts)),"consequence":"Where they met is marked on the route. That is not where they live."})
		for finding in discoveries:
			if Archive.routine_finding(finding): continue
			var card:Dictionary=finding.duplicate(true)
			card["type"]="discovery"
			blocks.append(card)
		if not discoveries.is_empty() and Archive.significant_findings(report).is_empty():
			blocks.append({"type":"text","heading":"Nothing new","text":"They found nothing else worth telling. The journey tab has their road."})
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
				blocks.append({"type":"discovery","kind":"roadside supplies","title":"What sustained the journey","description":"The party recorded ordinary materials along the road and any supplies it carried home.","consequence":"These are useful local resupply notes, not distant treasure. Where and how much is written in the journey tab."})
			if report.get("windfalls",[]).is_empty(): blocks.append({"type":"text","text":"The road itself is what they found. Nothing else was brought home."})
		blocks.append({"type":"text","text":"The journey tab tells the road, who they met and what fed them."})
		return {"kpis":kpis,"brief":brief,"blocks":blocks}
	for finding:Dictionary in report.get("discoveries",[]):
		if Archive.routine_finding(finding) and String(finding.get("kind",""))!="landmark":
			blocks.append({"type":"text","heading":String(finding.get("title","Field notes")),"text":String(finding.get("description",""))+" "+String(finding.get("consequence",""))})
	blocks.append({"type":"expedition_chart","route":report.get("route",[]),"discoveries":report.get("discoveries",[])})
	var journal:Array=report.get("journal",[])
	if not journal.is_empty():
		var journal_lines:Array[String]=[]
		for entry in journal: journal_lines.append(String(entry))
		blocks.append({"type":"text","heading":"The journey","text":"\n".join(journal_lines)})
	var turnback:=String(report.get("turnback_reason",""))
	if turnback!="":
		blocks.append({"type":"text","heading":"Why they turned back","text":turnback})
	if not contacts.is_empty():
		var contact_items:Array=[]
		for contact_name in contacts:
			contact_items.append({"name":String(contact_name),"sub":"Met face to face · the place is marked on the route","value":"","accent":Tokens.AMBER,"tip":"Where we met them is not where they live."})
		blocks.append({"type":"rows","heading":"People they met","items":contact_items})
	var targeted:=String(report.get("target_finding",""))
	if targeted!="":
		blocks.append({"type":"text","heading":"What they were sent to learn","text":targeted})
	var windfalls:Array=report.get("windfalls",[])
	if windfalls.is_empty() and contacts.is_empty() and targeted=="" and not is_recruitment and Archive.significant_findings(report).is_empty() and (report.get("city_observations",[]) as Array).is_empty():
		blocks.append({"type":"text","heading":"What they found","text":"Nothing beyond the road itself."})
	else:
		var findings:Array[String]=[]
		for windfall in windfalls: findings.append("• "+String(windfall))
		if not findings.is_empty():
			blocks.append({"type":"text","heading":"What they found","text":"\n".join(findings)})
	if not _cover_path().is_empty():
		blocks.append({"type":"image","path":_cover_path(),"height":112,"cover":true,"tip":"The kind of country they walked through."})
	return {"kpis":kpis,"brief":brief,"blocks":blocks}

func signature()->Array:
	return [int(report.get("day",0)),String(report.get("target_id",""))]

func _cover_path()->String:
	return Archive.artwork(report)

static func _first_up(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)
