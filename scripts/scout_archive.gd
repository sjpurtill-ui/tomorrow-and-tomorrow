class_name ScoutArchive
extends RefCounted
## Summaries use returned records only; a routine survey may still add route knowledge.
const PAGE_SIZE:=5
const FILTERS:=["All reports","Findings","Routine surveys","Losses","Unread"]

static func identity(report:Dictionary)->String:
	return "%s:%s:%s:%s" % [report.get("mission_id",0),report.get("day",0),report.get("target_id",""),hash(JSON.stringify(report.get("route",[])))]

static func routine_finding(finding:Dictionary)->bool:
	return String(finding.get("title","")) in ["A wider world, carried home","Routes worth remembering","What sustained the journey"] or String(finding.get("kind","")) in ["roadside supplies","landmark"]

static func significant_findings(report:Dictionary)->Array:
	var findings:Array=[]
	for finding:Dictionary in report.get("discoveries",[]):
		if not routine_finding(finding): findings.append(finding)
	return findings

static func summary(report:Dictionary)->Dictionary:
	var findings:=significant_findings(report)
	if findings.is_empty() and (report.get("discoveries",[]) as Array).is_empty():
		for old_note in report.get("windfalls",[]):
			var note:=String(old_note); var lower:=note.to_lower()
			if "charts and accounts circulate" in lower or "supplies brought home" in lower or "party hauls back" in lower: continue
			if "occurrence" in lower and ("timber" in lower or "stone" in lower or "fiber plants" in lower): continue
			findings.append({"title":"Field findings recorded","description":note})
	var city_observations:Array=report.get("city_observations",[])
	if not city_observations.is_empty(): findings.push_front({"title":"City observations returned","description":"%d dated city observation records are available in this report." % city_observations.size()})
	var contacts:Array=report.get("contacts",[])
	var recruits:=maxi(0,int(report.get("recruits",0)))
	var losses:=maxi(0,int(report.get("lost_personnel",0)))
	var targeted:=String(report.get("target_finding",""))
	var recruitment:Dictionary=report.get("recruitment_account",{})
	var meaningful:=not findings.is_empty() or not contacts.is_empty() or recruits>0 or not targeted.is_empty()
	var title:="Routine survey returned"
	var detail:="No additional findings recorded; route and field notes retained."
	var priority:=0
	if not findings.is_empty():
		title=String(findings[0].get("title","Recorded finding")); detail=String(findings[0].get("description","")); priority=2
	if not targeted.is_empty(): title="Investigation returned"; detail=targeted; priority=maxi(priority,2)
	if not recruitment.is_empty(): title="Recruitment party returned"; detail=String(recruitment.get("summary","No recruitment outcome recorded."))
	if recruits>0: title="%d newcomers arrived" % recruits; priority=3
	if not contacts.is_empty(): title="Contact with "+", ".join(PackedStringArray(contacts)); detail="Encounter reported; this alone does not locate a homeland."; priority=4
	if losses>0: title="%d scouts did not return" % losses; detail="%d returned · %d stayed elsewhere. %s" % [int(report.get("returned_personnel",0)),int(report.get("stayed_personnel",0)),detail]; priority=5
	var party:="Party %s" % report.mission_id if int(report.get("mission_id",0))>0 else "Earlier expedition"
	var place:=String(report.get("target_label","Open exploration")).capitalize()
	var route:Array=report.get("route",[])
	if place.to_lower() in ["open exploration","open world"] and route.size()>1:
		var start:Dictionary=route[0]; var end:Dictionary=route[-1]
		var offset:=Vector2(float(end.get("x",0))-float(start.get("x",0)),float(end.get("z",0))-float(start.get("z",0)))
		if offset.length()>1:
			var directions:=["east","southeast","south","southwest","west","northwest","north","northeast"]
			place="%s route · %d km out & back" % [directions[posmod(roundi(offset.angle()/(PI/4)),8)].capitalize(),int(report.get("distance_km",0))]
	var review:="UNREAD" if report.has("archive_reviewed") and not bool(report.archive_reviewed) else ("READ" if bool(report.get("archive_reviewed",false)) else "")
	return {"id":identity(report),"title":title,"detail":detail,"party":party,"place":place,"day":int(report.get("day",0)),"priority":priority,"meaningful":meaningful,"losses":losses,"review":review,"kind":"LOSSES" if losses>0 else ("FINDINGS" if meaningful else "ROUTINE"),"report":report}

static func select(reports:Array,query:String="",filter_index:int=0,important_first:bool=true)->Array:
	var selected:Array=[]
	var terms:=query.strip_edges().to_lower().split(" ",false)
	for report:Dictionary in reports:
		var item:=summary(report)
		if terms.size()==2 and String(terms[1]).is_valid_int():
			if terms[0]=="party" and int(report.get("mission_id",0))!=int(terms[1]): continue
			if terms[0]=="day" and int(item.day)!=int(terms[1]): continue
		if filter_index==1 and not bool(item.meaningful): continue
		if filter_index==2 and (bool(item.meaningful) or int(item.losses)>0): continue
		if filter_index==3 and int(item.losses)==0: continue
		if filter_index==4 and item.review!="UNREAD": continue
		var searchable:=(JSON.stringify(report)+" "+String(item.party)+" "+String(item.place)+" "+String(item.title)).to_lower()
		var matches:=true
		for term in terms:
			if not String(term) in searchable: matches=false; break
		if matches: selected.append(item)
	selected.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if important_first and int(a.priority)!=int(b.priority): return int(a.priority)>int(b.priority)
		if int(a.day)!=int(b.day): return int(a.day)>int(b.day)
		return String(a.id)<String(b.id))
	return selected

static func artwork(report:Dictionary)->String:
	# No generic fallback: missing terrain evidence gets its actual route chart.
	var text:=(" ".join(PackedStringArray(report.get("journal",[])))+" "+JSON.stringify(report.get("discoveries",[]))).to_lower()
	var keywords:={"forest":["woodland","forest"],"desert":["drylands","desert","dunes"],"mountains":["summit","high bare ground","mountain","treeline"],"river":["running water","river","wetland","floodplain"]}
	var candidates:Array=[]
	for terrain:String in keywords:
		for word:String in keywords[terrain]:
			if word in text: candidates.append(terrain); break
	if candidates.is_empty(): return ""
	return "res://assets/textures/expeditions/chronicle-%s.png" % candidates[posmod(identity(report).hash(),candidates.size())]

static func mark_reviewed(report:Dictionary)->void:
	var key:=identity(report)
	for saved:Dictionary in CivilizationSystem.scout_reports:
		if identity(saved)==key: saved["archive_reviewed"]=true; return

static func revision(reports:Array)->Array:
	var reviewed:=0
	for report:Dictionary in reports:
		if bool(report.get("archive_reviewed",false)): reviewed+=1
	return [reports.size(),identity(reports[0]) if not reports.is_empty() else "",reviewed]
