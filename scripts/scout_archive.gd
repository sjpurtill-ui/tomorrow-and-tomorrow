class_name ScoutArchive
extends RefCounted
## Summaries use returned records only; a routine survey may still add route knowledge.
const PAGE_SIZE:=5
const FILTERS:=["All reports","Findings","Routine surveys","Losses","Unread"]

static func should_notify(report:Dictionary)->bool:
	# Standing watches still deliver/archive every report, without repeatedly
	# interrupting the map for ordinary estimates of an already-known city.
	if not bool(report.get("continuous_watch",false)):return true
	if int(report.get("lost_personnel",0))>0 or int(report.get("stayed_personnel",0))>0:return true
	if not String(report.get("turnback_reason","")).is_empty():return true
	if int(report.get("new_contact_count",0))>0 or not (report.get("contacts",[]) as Array).is_empty():return true
	if city_record(report).is_empty():return true
	return not significant_findings(report).is_empty()

## Whether a return deserves a word to the player at all. Exploration that
## brought home nothing new (only the route, examined curiosities, supplies)
## stays silent: the Known World and the scout archive still receive it.
static func newsworthy(report:Dictionary)->bool:
	if not should_notify(report):return false
	if bool(report.get("continuous_watch",false)) or String(report.get("mission_kind",""))=="observe_city":return true
	if int(report.get("new_contact_count",0))>0 or not (report.get("contacts",[]) as Array).is_empty():return true
	if int(report.get("recruits",0))>0 or not (report.get("recruitment_account",{}) as Dictionary).is_empty():return true
	if int(report.get("stayed_personnel",0))>0:return true
	if not String(report.get("target_finding","")).is_empty() or not String(report.get("turnback_reason","")).is_empty():return true
	if not (report.get("city_observations",[]) as Array).is_empty():return true
	for finding:Dictionary in report.get("discoveries",[]):
		# Curiosities go to the knowledge workers; a passing band that "kept
		# moving" is marked on the Known World (the first is told separately).
		if routine_finding(finding) or finding.has("collection_id") or String(finding.get("kind",""))=="encounter":continue
		return true
	return false

static func city_record(report:Dictionary)->Dictionary:
	var id:=String(report.get("target_city_id",String(report.get("target_id","")).trim_prefix("city:")))
	for city:Dictionary in report.get("city_observations",[]):
		if String(city.get("city_id",""))==id:return city
	return {}

## The shared date phrase ("Year 12 · Summer"), never a raw day number.
static func calendar_date(day:int)->String:
	return preload("res://scripts/hud/era_words.gd").when(maxi(0,day))

static func city_account(report:Dictionary)->String:
	var city:=city_record(report)
	var target:=String(city.get("name",String(report.get("target_label","the target city")).trim_prefix("OBSERVE ")))
	var text:="Watching %s: %d scouts came home after %s away. " % [target,int(report.get("returned_personnel",report.get("personnel",0))),preload("res://scripts/hud/report_when.gd").span(int(report.get("actual_days",report.get("duration_days",0))))]
	if city.is_empty():text+="They brought back nothing useful about the city, so what we know of it is unchanged."
	else:
		text+="%d days observing; what they saw dates from %s. " % [int(city.get("observation_days",1)),calendar_date(int(city.get("observed_day",0)))]
		var visuals=preload("res://scripts/hud/city_report_visuals.gd")
		for key:String in visuals.shown_keys():
			var field:Dictionary=city.get("fields",{}).get(key,{})
			if field.is_empty():continue
			text+=String(visuals.label(key))+": "+String(visuals.words(key,field))+". "
	if bool(report.get("continuous_watch",false)):text+="Standing order: they go back to watch it again once home, if people, food and the road allow."
	return text.strip_edges()

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
	if String(report.get("mission_kind",""))=="observe_city":
		title="City reconnaissance · "+String(city_record(report).get("name",String(report.get("target_label","Reported city")).trim_prefix("OBSERVE ")))
		detail=city_account(report);priority=maxi(priority,2)
	if losses>0: title="%d scouts did not return" % losses; detail="%d returned · %d stayed elsewhere. %s" % [int(report.get("returned_personnel",0)),int(report.get("stayed_personnel",0)),detail]; priority=5
	var party:=party_name(report)
	var place:=String(report.get("target_label","Open exploration")).capitalize()
	var route:Array=report.get("route",[])
	if place.to_lower() in ["open exploration","open world"] and route.size()>1:
		var start:Dictionary=route[0]; var end:Dictionary=route[-1]
		var offset:=Vector2(float(end.get("x",0))-float(start.get("x",0)),float(end.get("z",0))-float(start.get("z",0)))
		if offset.length()>1:
			var directions:=["east","southeast","south","southwest","west","northwest","north","northeast"]
			place="Out to the %s and back" % directions[posmod(roundi(offset.angle()/(PI/4)),8)]
	var review:="UNREAD" if report.has("archive_reviewed") and not bool(report.archive_reviewed) else ("READ" if bool(report.get("archive_reviewed",false)) else "")
	return {"id":identity(report),"title":title,"detail":detail,"party":party,"place":place,"day":int(report.get("day",0)),"priority":priority,"meaningful":meaningful,"losses":losses,"review":review,"kind":"Losses" if losses>0 else ("Findings" if meaningful else "Routine"),"report":report}

## A name for a scouting party the player can recognise: how many went and
## where they set out from, never a bare mission number.
static func party_name(report:Dictionary)->String:
	var count:=int(report.get("personnel",0))
	var origin:=String(report.get("origin_label",""))
	var who:="A scouting party" if count<=0 else ("One scout" if count==1 else "%d scouts" % count)
	if origin==origin.to_upper():origin=origin.capitalize()
	if origin!="" and origin.to_lower()!="home":who+=" from "+origin
	return who

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
		var searchable:=(JSON.stringify(report)+" party %d " % int(report.get("mission_id",0))+String(item.party)+" "+String(item.place)+" "+String(item.title)).to_lower()
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
	for saved:Dictionary in WorldSimulation.world.scout_reports:
		if identity(saved)==key: saved["archive_reviewed"]=true; return

static func revision(reports:Array)->Array:
	var reviewed:=0
	for report:Dictionary in reports:
		if bool(report.get("archive_reviewed",false)): reviewed+=1
	return [reports.size(),identity(reports[0]) if not reports.is_empty() else "",reviewed]
