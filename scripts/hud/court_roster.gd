extends RefCounted
## Who is at court: everyone the ruler may call before them, grouped the way
## a court stands (the council, the leaders of settlements, those back from
## the field), the envoys waiting in the antechamber, and the foreign peoples
## one may send word to. Read-only; summoning still goes through AudienceHall.

const Hall:=preload("res://scripts/audience_hall.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const Civic:=preload("res://scripts/hud/court_civic.gd")
const GROUPS:=["council","settlement","scouts","builders","generals"]
const GROUP_WORDS:={"council":"THE COUNCIL","settlement":"LEADERS OF SETTLEMENTS","scouts":"SCOUTS","builders":"MASTER BUILDERS","generals":"WAR LEADERS"}
const MAX_GENERALS:=3

static func people()->Array[Dictionary]:
	## Everyone who may be summoned, each once:
	## {key,target,name,title,group,matters,person,regard,settlement_id}
	var result:Array[Dictionary]=[]
	var seen:Dictionary={}
	var offices:Dictionary={}
	for official in Hall._officials():
		offices[int(official.get("person_id",0))]=official
	for entry in Hall.summonable():
		var target:Dictionary=(entry.get("target",{}) as Dictionary).duplicate()
		var pid:=int(target.get("person_id",0))
		var role:=String(entry.get("role","official"))
		var person:Dictionary={}
		var group:="council"
		var settlement_id:=""
		if pid>0:
			person=offices.get(pid,{}) as Dictionary
			if person.is_empty(): person=GovernmentPeopleSystem.person_snapshot(pid)
			settlement_id=Civic.leader_settlement(pid)
			if role=="chief_scout": group="scouts"
			elif String(person.get("office_key",""))=="settlement": group="settlement"
		elif role=="chief_scout":
			group="scouts"
		elif role=="architect":
			group="builders"
		var key:=_key(target)
		if seen.has(key): continue
		seen[key]=true
		if person.is_empty(): person={"name":String(entry.get("name","")),"person_id":0}
		var regard:Dictionary=Divine.regard(person) if pid>0 else {}
		result.append({"key":key,"target":target,"name":String(entry.get("name","")),"title":String(entry.get("title","")),"group":group,
			"matters":int(entry.get("matters",0)),"person":person,"regard":regard,"settlement_id":settlement_id})
	# Master builders and war leaders who hold no matter may still be sent for.
	for figure in _figures():
		var target:={"figure_id":String(figure.get("id",""))}
		var key:=_key(target)
		if seen.has(key): continue
		seen[key]=true
		var role:=String(figure.get("role",""))
		var group:="builders" if role=="Architect" else "generals"
		var title:=_figure_title(figure)
		result.append({"key":key,"target":target,"name":String(figure.get("name","")),"title":title,"group":group,"matters":0,
			"person":{"name":String(figure.get("name","")),"person_id":0},"regard":{},"settlement_id":"","figure":figure})
	return result

static func grouped()->Dictionary:
	var groups:Dictionary={}
	for group in GROUPS: groups[group]=[]
	for entry in people(): (groups[String(entry.group)] as Array).append(entry)
	return groups

static func _key(target:Dictionary)->String:
	if int(target.get("person_id",0))>0: return "person:%d" % int(target.person_id)
	if String(target.get("figure_id",""))!="": return "figure:"+String(target.figure_id)
	if String(target.get("role",""))!="": return "role:"+String(target.role)
	return "holder:"+String(target.get("holder_key",target.get("name","")))

static func _figures()->Array[Dictionary]:
	## Living master builders, and war leaders (those in the field first).
	var result:Array[Dictionary]=[]
	if not is_instance_valid(HistoricalFigures): return result
	var assigned:Array=HistoricalFigures.assignments.values()
	var generals:Array[Dictionary]=[]
	for figure in HistoricalFigures.people:
		if not figure is Dictionary or String(figure.get("status",""))=="dead": continue
		match String(figure.get("role","")):
			"Architect": result.append(figure)
			"General": generals.append(figure)
	generals.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(assigned.has(a.id))>int(assigned.has(b.id)))
	for index in mini(generals.size(),MAX_GENERALS): result.append(generals[index])
	return result

static func _figure_title(figure:Dictionary)->String:
	var role:=String(figure.get("role",""))
	if role=="Architect": return "Master builder"
	if role=="General":
		var in_field:=HistoricalFigures.assignments.values().has(String(figure.get("id","")))
		return "War leader in the field" if in_field else "War leader"
	return role.capitalize()

static func envoys()->Array[Dictionary]:
	## Foreign envoys waiting in the antechamber, oldest first.
	var result:Array[Dictionary]=[]
	for audience in Hall.waiting():
		if String(audience.get("origin",""))=="foreign": result.append(audience)
	return result

static func court_waiting()->Array[Dictionary]:
	## Court audiences already opened but not yet concluded (e.g. set aside).
	var result:Array[Dictionary]=[]
	for audience in Hall.waiting():
		if String(audience.get("origin",""))!="foreign": result.append(audience)
	return result

static func foreign_peoples()->Array[Dictionary]:
	## Peoples whose leaders you can reach through envoys:
	## {civ_id,name,leader,access,regard,at_war,waiting}
	var result:Array[Dictionary]=[]
	var waiting:Dictionary={}
	for audience in envoys(): waiting[String(audience.get("civ_id",""))]=true
	for civ in CivilizationSystem.civilizations:
		if not civ is Dictionary: continue
		var id:=String(civ.get("id",""))
		if id.is_empty() or not bool(civ.get("alive",true)): continue
		var leader:Dictionary=ForeignDiplomacy.leader(id)
		if leader.is_empty(): continue
		var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
		var access:Dictionary=ForeignDialogue.access(id)
		result.append({"civ_id":id,"name":String(civ.get("name",id)),"leader":String(leader.get("name","")),"access":bool(access.get("ok",false)),
			"regard":Divine.foreign_regard(id),"at_war":bool(relation.get("at_war",false)),"waiting":waiting.has(id)})
	return result

static func find_by_words(text:String)->Dictionary:
	## The person the ruler's words name, by name or office ("Scout, what lies
	## east?"). Returns a roster entry, or {} when nobody is named.
	var lower:=" "+text.to_lower().replace(",", " ").replace("?", " ").replace(".", " ").replace("!", " ")+" "
	var best:Dictionary={}
	var best_score:=0
	for entry in people():
		var score:=0
		var name:=String(entry.get("name","")).to_lower()
		for part in name.split(" ",false):
			if part.length()>=3 and " %s " % part in lower: score=maxi(score,3)
		var title:=String(entry.get("title","")).to_lower()
		for word in title.split(" ",false):
			if word.length()>=4 and not word in ["of","the","master","leader"] and word in lower: score=maxi(score,2)
		if String(entry.group)=="scouts" and (" scout" in lower or "scouts" in lower): score=maxi(score,2)
		if String(entry.group)=="builders" and ("builder" in lower or "architect" in lower): score=maxi(score,2)
		if String(entry.group)=="generals" and ("general" in lower or "war leader" in lower): score=maxi(score,2)
		if score>best_score: best_score=score; best=entry
	return best

static func find_foreign_by_words(text:String)->Dictionary:
	var lower:=text.to_lower()
	for people_entry in foreign_peoples():
		var civ_name:=String(people_entry.get("name","")).to_lower()
		var leader_name:=String(people_entry.get("leader","")).to_lower().get_slice(" ",0)
		if (civ_name.length()>=3 and civ_name in lower) or (leader_name.length()>=3 and " %s" % leader_name in " "+lower): return people_entry
	return {}

static func default_speaker()->Dictionary:
	## Whom plain words to "the court" reach first: the leader of the settlement
	## you are looking at, else the first official.
	var selected:Dictionary=SettlementModel.selected_settlement_snapshot()
	var sid:=String(selected.get("id",""))
	var all:=people()
	for entry in all:
		if sid!="" and String(entry.get("settlement_id",""))==sid: return entry
	for entry in all:
		if String(entry.get("settlement_id",""))!="": return entry
	return all[0] if not all.is_empty() else {}
