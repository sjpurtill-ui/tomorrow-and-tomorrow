extends RefCounted
## Who a person is and where they are now: one answer for every screen
## (Home's leader row, the Council, War's leaders). Offices and town
## leadership come from GovernmentPeopleSystem; whether a general leads men
## in the field comes from leader_commands.gd (the War screen's own numbers).
##
##   PersonPosts.of(subject, commands) -> {"title", "place", "group"}
##
## `subject` is a court-roster entry or any of: {"person_id"}, {"figure"},
## {"figure_id"}. Pass `commands` (PersonPosts.commands_now()) when asking
## about many people at once, so the armies are read once.
const Commands:=preload("res://scripts/leader_commands.gd")

## The armies as the War screen reads them (leader_commands.commands).
static func commands_now()->Array:
	if not is_instance_valid(MilitaryCampaign):return []
	return Commands.commands(MilitaryCampaign)

static func of(subject:Dictionary,commands:Array=[])->Dictionary:
	var pid:=int(subject.get("person_id",(subject.get("target",{}) as Dictionary).get("person_id",0) if subject.get("target") is Dictionary else 0))
	if pid<=0 and subject.get("person") is Dictionary:pid=int((subject.person as Dictionary).get("person_id",0))
	var figure:Dictionary=subject.get("figure",{}) if subject.get("figure") is Dictionary else {}
	var figure_id:=String(figure.get("id",subject.get("figure_id",(subject.get("target",{}) as Dictionary).get("figure_id","") if subject.get("target") is Dictionary else "")))
	if figure.is_empty() and figure_id!="" and is_instance_valid(HistoricalFigures):
		for one in HistoricalFigures.people:
			if one is Dictionary and String(one.get("id",""))==figure_id:figure=one;break
	if pid>0:return _official(pid,commands)
	if not figure.is_empty():return _figure(figure,commands)
	return {"title":String(subject.get("title","")),"place":"","group":String(subject.get("group",""))}

## An official: every office they hold, and the town they lead, if any.
static func _official(pid:int,commands:Array)->Dictionary:
	var titles:PackedStringArray=[]
	var group:="council"
	if is_instance_valid(GovernmentPeopleSystem):
		for office:Dictionary in GovernmentPeopleSystem.active_offices():
			var holder:Variant=WorldSimulation.state.leadership_positions.get(String(office.key),{})
			if holder is Dictionary and int((holder as Dictionary).get("person_id",0))==pid:
				titles.append(String(office.title))
				if String(office.key)=="ChiefScout":group="scouts"
				elif String(office.key)=="Marshal":group="war"
	var place:="At court"
	for settlement in WorldSimulation.state.player_settlements:
		if int((settlement as Dictionary).get("leader_person_id",0))!=pid:continue
		titles.append(GovernmentPeopleSystem.settlement_leader_title() if is_instance_valid(GovernmentPeopleSystem) else "Town leader")
		place=String((settlement as Dictionary).get("name","our town"))
		if titles.size()==1:group="settlement"
		break
	# The war leader at home (the Marshal) leading bands is in the field.
	for command in commands:
		var c:Dictionary=command
		if String(c.get("id",""))==Commands.WAR_LEADER and group=="war" and int(c.get("men",0))>0:place=_field_words(c)
	if titles.is_empty():titles.append("Official")
	return {"title":" and ".join(titles),"place":place,"group":group}

## A figure of note: a general (in the field or at home, as War shows them),
## a master builder, or one of the gifted.
static func _figure(figure:Dictionary,commands:Array)->Dictionary:
	var id:=String(figure.get("id",""))
	match String(figure.get("role","")):
		"General":
			for command in commands:
				var c:Dictionary=command
				var leader:Dictionary=c.get("leader",{})
				if String(leader.get("figure_id",""))!=id:continue
				var title:="War leader" if String(c.get("id",""))==Commands.WAR_LEADER else "General"
				return {"title":title,"place":_field_words(c) if int(c.get("men",0))>0 else "At home","group":"war"}
			return {"title":"General","place":"At home","group":"war"}
		"Architect":
			return {"title":"Master builder","place":"At home","group":"builders"}
	if figure.get("genius") is Dictionary:
		return {"title":preload("res://scripts/geniuses.gd").court_title(figure),"place":"At home","group":"gifted"}
	return {"title":String(figure.get("role","")).capitalize(),"place":"At home","group":"gifted"}

## "In the field at Tsaren", from the places its bands stand or march to.
static func _field_words(command:Dictionary)->String:
	var places:Dictionary=command.get("places",{})
	var best:="";var most:=0
	for place in places:
		if int(places[place])>most:most=int(places[place]);best=String(place)
	return "In the field" if best=="" or best=="the field" else "In the field at %s" % best
