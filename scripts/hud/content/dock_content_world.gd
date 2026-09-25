extends "res://scripts/hud/content/dock_content_base.gd"
## WORLD section: The Known World / Expeditions / Standing.
## The first tab is "the world as your people know it": a chart drawn from
## returned routes only, the peoples met, walkers abroad and what they carried
## home. Everything shown physically returned; nothing is read from hidden
## world state. Deep reports open in the second (detail) dock, conversations
## with foreign leaders go to the court, returned findings are told by the
## Chief Scout when summoned. Dispatch flows stay as pausing confirm modals.

const DetailCivReport:=preload("res://scripts/hud/content/dock_detail_civ_report.gd")
const Archive:=preload("res://scripts/scout_archive.gd")
const ArchiveProvider:=preload("res://scripts/hud/content/dock_detail_scout_archive.gd")
const ReportProvider:=preload("res://scripts/hud/content/dock_detail_scout_report.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Voice:=preload("res://scripts/character_voice.gd")
const EarlyArt:=preload("res://scripts/hud/early_civ_art.gd")
const CULTURE_PATH:="res://scripts/artifact_culture.gd"
const GALLERY_PATH:="res://scripts/hud/artifact_gallery.gd"
const COMPASS:=["east","southeast","south","southwest","west","northwest","north","northeast"]
const TRAIL_LIMIT:=30
const PLACE_LIMIT:=16
const FIND_GROUPS:=6
const FIND_ITEMS:=3

func meta()->Dictionary:
	return {
		"eyebrow":"WORLD · AS OUR PEOPLE KNOW IT",
		"title":"The Known World",
		"serif":true,"title_size":26,
		"subtabs":["THE KNOWN WORLD","EXPEDITIONS","STANDING"],
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
	return {"blocks":[{"type":"known_world","model":known_world_model(exploration)}]}

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


# ---------------------------------------------------------------------------
# The known world: one plain model for scripts/hud/known_world_board.gd
# ---------------------------------------------------------------------------

func known_world_model(exploration:Dictionary)->Dictionary:
	var day:=int(GameState.elapsed_days)
	var tier:=era_tier()
	var home:=CivilizationSystem.player_world_origin
	var pace:=walk_km_per_day()
	var encounters:Array=CivilizationSystem.contact_encounters_snapshot()
	var located:=0
	for encounter:Dictionary in encounters:
		if bool(encounter.get("home_location_known",false)):located+=1
	var leads:Array=CivilizationSystem.rumor_network.list_leads("player",day)
	var reports:Array=CivilizationSystem.scout_reports
	var unread:=0
	for report:Dictionary in reports:
		if report.has("archive_reviewed") and not bool(report.archive_reviewed):unread+=1
	var chief:Dictionary=GovernmentPeopleSystem.officeholder("ChiefScout")
	var matters:=chief_scout_matters()
	var presentation:Dictionary={"label":"Send envoys","disabled":located==0,"tooltip":"Envoys need a located hearth to walk to."}
	if is_instance_valid(terrain) and terrain.has_method("_diplomat_action_presentation"):
		presentation=terrain._diplomat_action_presentation(CivilizationSystem.diplomatic_mission_status(),located)
	var chief_name:=String(chief.get("name",""))
	var summon_label:=("Summon %s, your Chief Scout, to hear it" % chief_name) if not chief_name.is_empty() else "Call in the returned walkers to hear it"
	var summon_tip:="Call them into the audience hall; they will tell what the walkers saw."
	if matters>0:summon_tip="%s holds %d matter%s from the road. Returned findings are told in the audience hall." % [chief_name if not chief_name.is_empty() else "The Chief Scout",matters,"" if matters==1 else "s"]
	var envoys:={"label":"Send envoys" if located>0 else "Envoys need a found hearth","disabled":bool(presentation.get("disabled",located==0)),"tip":String(presentation.get("tooltip","")),"on_press":open_envoys}
	return {
		"tier":tier,
		"settlement":_settlement_name(),
		"counters":{"peoples":encounters.size(),"located":located,"away":int(exploration.get("active_count",0)),"capacity":int(exploration.get("capacity",1)),"reports":reports.size(),"unread":unread,"leads":leads.size(),"matters":matters},
		"chart":_chart_model(home,encounters,leads,reports,exploration,pace),
		"peoples":_peoples_model(encounters,home,pace),
		"leads":_leads_model(leads,home,pace),
		"parties":_parties_model(exploration),
		"finds":_finds_model(reports),
		"chief_name":chief_name,
		# What the people strive for, and what rivals have sworn (legacy_aims.gd).
		"aims":preload("res://scripts/legacy_aims.gd").board_model(),
		"actions":{"plan":plan_expedition,"archive":open_archive,"rumor_map":open_rumor_map,"summon":summon_chief_scout,"summon_label":summon_label,"summon_tip":summon_tip,"envoys":envoys},
	}

func plan_expedition()->void:
	if is_instance_valid(terrain) and terrain.has_method("_open_scout_dispatch_panel"):terrain._open_scout_dispatch_panel()

func open_archive()->void:
	if is_instance_valid(hud):hud.open_detail(ArchiveProvider.new(terrain,hud))

func open_rumor_map()->void:
	CivilizationSystem.rumor_network.open_map(terrain)

func open_envoys()->void:
	if is_instance_valid(terrain) and terrain.has_method("_open_diplomat_dispatch_panel"):terrain._open_diplomat_dispatch_panel()

func open_record(civ_id:String)->void:
	if is_instance_valid(hud):hud.open_detail(DetailCivReport.new(terrain,hud,civ_id))

func open_report(report:Dictionary)->void:
	if is_instance_valid(hud):hud.open_detail(ReportProvider.new(terrain,hud,report,ArchiveProvider.new(terrain,hud)))

func open_piece(id:String)->void:
	if ResourceLoader.exists(GALLERY_PATH):(load(GALLERY_PATH) as Script).call("open",hud,terrain,id)

static func era_tier()->int:
	return clampi(Voice.era_tier(Voice.era_tags("player")),0,3)

static func walk_km_per_day()->float:
	var pace:=14.0
	if CivilizationSystem.has_method("scout_one_way_range"):pace=float(CivilizationSystem.scout_one_way_range(1))
	return maxf(4.0,pace)

static func compass(from:Vector2,to:Vector2)->String:
	## World +x is east and +z is south.
	return COMPASS[posmod(roundi(rad_to_deg((to-from).angle())/45.0),8)]

static func walk_text(distance:float,pace:float)->String:
	var days:=distance/maxf(1.0,pace)
	if days<1.0:return "within a day's walk"
	var whole:=maxi(1,roundi(days))
	if whole>=60:return "more than a season's walk"
	if whole==1:return "about a day's walk"
	return "about %d days' walk" % whole

static func vec(value:Variant)->Vector2:
	if value is Vector2:return value
	if value is Dictionary and (value as Dictionary).has("x"):
		var point:Dictionary=value
		return Vector2(float(point.get("x",0.0)),float(point.get("z",point.get("y",0.0))))
	return Vector2.INF

static func points(route:Variant)->PackedVector2Array:
	var result:=PackedVector2Array()
	if not route is Array:return result
	for point:Variant in route:
		var p:=vec(point)
		if p!=Vector2.INF and p.is_finite():result.append(p)
	return result

static func farthest(route:PackedVector2Array)->Vector2:
	if route.is_empty():return Vector2.ZERO
	var far:=route[0]
	for p:Vector2 in route:
		if p.distance_squared_to(route[0])>far.distance_squared_to(route[0]):far=p
	return far

func _settlement_name()->String:
	var named:=String(GameState.settlement_name)
	return named if not named.is_empty() else "Our hearth"

func chief_scout_matters()->int:
	var counts:Dictionary=Hall.matter_counts()
	var total:=0
	for key:String in Hall.summon_keys({"role":"chief_scout"}):total+=int(counts.get(key,0))
	return total

func summon_chief_scout()->void:
	var director:Node=terrain.find_child("AudienceDirector",true,false) if is_instance_valid(terrain) else null
	if director!=null and director.has_method("summon"):director.call("summon",{"role":"chief_scout"})

func speak_with(civ_id:String)->void:
	## One court for every leader conversation; the older modal is a fallback.
	if is_instance_valid(terrain) and terrain.has_method("open_court_for"):
		terrain.call("open_court_for",{"civ_id":civ_id,"kind":"foreign"})
		return
	if is_instance_valid(terrain) and terrain.has_method("_set_game_speed"):terrain.call("_set_game_speed",0)
	ForeignDiplomacy.open(civ_id)

static func terrain_of(report:Dictionary)->String:
	var journal:Variant=report.get("journal",[])
	var text:=(" ".join(PackedStringArray(journal)) if journal is Array else "").to_lower()
	for pair:Array in [["mountains",["summit","high bare ground","mountain","treeline"]],["river",["running water","river","wetland","floodplain"]],["forest",["woodland","forest"]],["desert",["drylands","desert","dunes"]]]:
		for word:String in pair[1]:
			if word in text:return String(pair[0])
	return ""

static func mark_for(civ_id:String)->int:
	return posmod(civ_id.hash(),6)

static func pigment_for(civ_id:String)->int:
	return posmod(civ_id.hash()/7,5)

func _chart_model(home:Vector2,encounters:Array,leads:Array,reports:Array,exploration:Dictionary,pace:float)->Dictionary:
	var trails:Array=[]
	var places:Array=[]
	var rank:=0
	for report:Dictionary in reports.slice(0,TRAIL_LIMIT):
		var route:=points(report.get("route",[]))
		if route.size()<2:continue
		trails.append({"points":route,"return":points(report.get("return_route",[])),"rank":rank,"terrain":terrain_of(report),"far":farthest(route),"lost":int(report.get("lost_personnel",0))>0,"title":"%s · %s" % [Archive.calendar_date(int(report.get("day",0))),route_phrase(report,route)]})
		rank+=1
		for card:Dictionary in report.get("discoveries",[]):
			if places.size()>=PLACE_LIMIT or Archive.routine_finding(card):continue
			var where:=vec(card.get("position",{}))
			if where==Vector2.INF:continue
			places.append({"pos":where,"kind":String(card.get("kind","")),"label":_find_name(card),"resource":String(card.get("resource","")),"tip":String(card.get("description",""))})
	var peoples:Array=[]
	for encounter:Dictionary in encounters:
		var id:=String(encounter.get("civ_id",""))
		var located:=bool(encounter.get("home_location_known",false))
		var at:=vec(encounter.get("home_position",{})) if located else vec(encounter.get("position",{}))
		if at==Vector2.INF:continue
		peoples.append({"pos":at,"name":String(encounter.get("name","")),"mark":mark_for(id),"pigment":pigment_for(id),"located":located,"tip":"%s · %s · %s" % [String(encounter.get("name","")),"their hearth" if located else "where we met them; their hearth is not yet found",walk_text(home.distance_to(at),pace)]})
	var rumors:Array=[]
	for lead:Dictionary in leads.slice(0,10):
		var center:=vec(lead.get("center",{}))
		if center==Vector2.INF:continue
		rumors.append({"pos":center,"radius":float(lead.get("radius",60.0)),"name":String(lead.get("name","")),"confidence":float(lead.get("confidence",0.0)),"direction":compass(home,center),"tip":"%s? · told of, never seen · somewhere %s, %s" % [String(lead.get("name","A people")),compass(home,center),walk_text(home.distance_to(center),pace)]})
	var hearsay:Array=[]
	for rumored:Dictionary in CivilizationSystem.rumored_civilizations_snapshot():
		hearsay.append({"name":String(rumored.get("name","")),"direction":String(rumored.get("direction","")),"distance":String(rumored.get("distance_hint",""))})
	var parties:Array=[]
	var status_by_id:Dictionary={}
	for party:Dictionary in exploration.get("parties",[]):status_by_id[int(party.get("mission_id",0))]=party
	for mission:Dictionary in CivilizationSystem.scout_missions:
		var status:Dictionary=status_by_id.get(int(mission.get("mission_id",0)),{})
		var route:=points(mission.get("route",[]))
		if route.size()<2:continue
		parties.append({"route":route,"circuit":bool(mission.get("circuit",false)),"progress":float(status.get("progress",0.0)),"days":int(status.get("days_remaining",0)),"overdue":int(status.get("overdue_days",0)),"personnel":int(mission.get("personnel",0)),"title":party_title(String(mission.get("target_label","")),String(mission.get("planned_heading","")))})
	return {"home":home,"pace":pace,"trails":trails,"places":places,"peoples":peoples,"rumors":rumors,"hearsay":hearsay,"parties":parties}

static func route_phrase(report:Dictionary,route:PackedVector2Array)->String:
	var far:=farthest(route)
	var days:=int(report.get("actual_days",report.get("duration_days",0)))
	if route.is_empty() or far.distance_to(route[0])<=1.0:return "a walk near home, %d days" % days
	return "%sward, %d days away" % [compass(route[0],far).capitalize(),days]

static func party_title(label:String,heading:String)->String:
	var upper:=label.to_upper()
	var toward:=(" toward the "+heading) if not heading.is_empty() else ""
	if upper in ["","OPEN EXPLORATION","OPEN WORLD"]:return "Into unwalked country"+toward
	if upper=="SEEK NOMADIC TRIBES":return "Seeking wandering bands"+toward
	if upper=="SURVEY MATERIAL SOURCES":return "Searching for good stone and clay"+toward
	if upper.begins_with("INVESTIGATE LEAD · "):return "Following word of the "+title_case(label.substr(19))
	if upper.begins_with("INVESTIGATE ") and upper.ends_with(" ENCOUNTER"):return "Back to where we met the "+title_case(label.substr(12,label.length()-22))
	if upper.begins_with("OBSERVE "):return "Watching "+title_case(label.substr(8))
	if upper.begins_with("RECRUIT FROM "):return "Inviting households from "+title_case(label.substr(13).split(" · ")[0])
	return title_case(label)

static func title_case(text:String)->String:
	var words:=text.strip_edges().to_lower().split(" ",false)
	for i:int in words.size():
		if i>0 and words[i] in ["of","the","and","a","an","to","at"]:continue
		words[i]=words[i].substr(0,1).to_upper()+words[i].substr(1)
	return " ".join(words)

func _peoples_model(encounters:Array,home:Vector2,pace:float)->Array:
	var result:Array=[]
	for encounter:Dictionary in encounters:
		var id:=String(encounter.get("civ_id",""))
		var leader:Dictionary=ForeignDiplomacy.leader(id)
		if not leader.is_empty() and EarlyArt.active():EarlyArt.bind_foreign_identity(leader,id,GameState.world_seed)
		var regard:Dictionary=Divine.foreign_regard(id)
		var located:=bool(encounter.get("home_location_known",false))
		var at:=vec(encounter.get("home_position",{})) if located else vec(encounter.get("position",{}))
		var where:=""
		if at!=Vector2.INF:where="%s, %s" % [_first_upper(walk_text(home.distance_to(at),pace)),("to the "+compass(home,at)) if at.distance_to(home)>1.0 else "close by"]
		if not located:where+=" · where we met them"
		var last_word:=""
		var memories:Variant=leader.get("memories",[])
		if memories is Array and not (memories as Array).is_empty() and (memories as Array)[0] is Dictionary:last_word=String(((memories as Array)[0] as Dictionary).get("text",""))
		var met:=int(encounter.get("day",-1))
		result.append({"civ_id":id,"name":String(encounter.get("name","A people")),"leader":leader,"leader_name":String(leader.get("name","")),"temperament":String(leader.get("temperament","")),
			"regard":String(regard.get("read","are undecided about you")),"regard_id":String(regard.get("id","undecided")),"love":float(regard.get("love",0.5)),"dread":float(regard.get("dread",0.0)),
			"where":where,"located":located,"met":("First met "+Archive.calendar_date(met)) if met>=0 else "","last_word":last_word,"mark":mark_for(id),"pigment":pigment_for(id),
			"on_speak":speak_with.bind(id),"on_record":open_record.bind(id),"aim":preload("res://scripts/legacy_aims.gd").rival_aim(id)})
	return result

func _leads_model(leads:Array,home:Vector2,pace:float)->Array:
	var result:Array=[]
	for lead:Dictionary in leads.slice(0,4):
		var center:=vec(lead.get("center",{}))
		var confidence:=float(lead.get("confidence",0.0))
		var word:="A firm telling" if confidence>=.35 else ("An uncertain telling" if confidence>=.15 else "A faint telling")
		var direction:=compass(home,center) if center!=Vector2.INF else "unknown"
		var distance:=walk_text(home.distance_to(center),pace) if center!=Vector2.INF else "an unknown distance"
		result.append({"name":String(lead.get("name","")),"confidence":confidence,"word":word,
			"text":"%s spoke of the %s, somewhere to the %s — %s." % [_first_upper(String(lead.get("via","travelers"))),String(lead.get("name","strangers")),direction,distance],
			"stale":String(lead.get("state",""))=="stale","searched":int(lead.get("attempts",0))})
	for rumored:Dictionary in CivilizationSystem.rumored_civilizations_snapshot():
		if result.size()>=5:break
		result.append({"name":String(rumored.get("name","")),"confidence":.2,"word":"Hearsay",
			"text":"Some speak of the %s, off to the %s, %s away." % [String(rumored.get("name","strangers")),String(rumored.get("direction","an unknown direction")),String(rumored.get("distance_hint","an unknown distance"))],"stale":false,"searched":0})
	return result

func _parties_model(exploration:Dictionary)->Array:
	var result:Array=[]
	for party:Dictionary in exploration.get("parties",[]):
		var overdue:=int(party.get("overdue_days",0))
		var days:=int(party.get("days_remaining",0))
		var when:="Home in about %d days" % days
		if days<=1:when="Home any day now"
		if overdue>0:when="Overdue %d day%s — not yet mourned" % [overdue,"" if overdue==1 else "s"]
		var reason:=String(party.get("turnback_reason",""))
		result.append({"id":int(party.get("mission_id",0)),"title":party_title(String(party.get("target_label","")),String(party.get("planned_heading",""))),"personnel":int(party.get("personnel",0)),
			"days":days,"overdue":overdue,"progress":float(party.get("progress",0.0)),"when":when,"from":String(party.get("origin_label","")),
			"turning_back":String(party.get("route_status",""))=="turning_back","tip":reason if not reason.is_empty() else "What they see stays with them until they walk back in.",
			"return_date":Archive.calendar_date(int(party.get("return_day",0)))})
	return result

func _find_name(card:Dictionary)->String:
	var kind:=String(card.get("kind",""))
	if kind=="artifact":
		var piece:=_artifact(String(card.get("collection_id","")))
		if not piece.is_empty():return String(piece.get("name",""))
		return title_case(String(card.get("title","A found thing")).split(" · ")[0])
	if kind=="resource" and not String(card.get("resource","")).is_empty():return String(card.resource)
	return String(card.get("title",""))

func _artifact(id:String)->Dictionary:
	if id.is_empty() or not ResourceLoader.exists(CULTURE_PATH):return {}
	var culture:Script=load(CULTURE_PATH)
	var found:Variant=culture.call("artifact",id)
	return found if found is Dictionary else {}

func _finds_model(reports:Array)->Array:
	var groups:Array=[]
	for report:Dictionary in reports:
		if groups.size()>=FIND_GROUPS:break
		var items:Array=[]
		var on_report:Callable=open_report.bind(report)
		for contact:Variant in report.get("contacts",[]):
			items.append({"kind":"contact","title":"Met the %s" % String(contact),"sub":"a first meeting","on_open":on_report})
		for card:Dictionary in Archive.significant_findings(report):
			var kind:=String(card.get("kind",""))
			if kind=="artifact":
				var id:=String(card.get("collection_id",""))
				var piece:=_artifact(id)
				if piece.is_empty():
					items.append({"kind":"artifact","title":_find_name(card),"sub":"carried home","on_open":on_report})
				else:
					items.append({"kind":"artifact","title":String(piece.get("name","")),"sub":String(piece.get("rarity","")).to_lower(),"texture":piece.get("texture"),"rarity_index":int(piece.get("rarity_index",0)),"state":String(piece.get("state","")),"study":float(piece.get("study_progress",0.0)),"on_open":open_piece.bind(id)})
			else:
				items.append({"kind":kind,"title":_find_name(card),"sub":find_sub(kind),"resource":String(card.get("resource","")),"on_open":on_report})
		if int(report.get("recruits",0))>0:items.append({"kind":"recruits","title":"%d came home with them" % int(report.recruits),"sub":"newcomers","on_open":on_report})
		if int(report.get("lost_personnel",0))>0:items.append({"kind":"losses","title":"%d did not come home" % int(report.lost_personnel),"sub":"lost on the road","on_open":on_report})
		if items.is_empty():continue
		var route:=points(report.get("route",[]))
		var mission:=int(report.get("mission_id",0))
		groups.append({"party":("Party %d" % mission) if mission>0 else "An earlier party","date":Archive.calendar_date(int(report.get("day",0))),
			"place":route_phrase(report,route) if route.size()>=2 else title_case(String(report.get("target_label","Open exploration"))),
			"unread":report.has("archive_reviewed") and not bool(report.archive_reviewed),"items":items.slice(0,FIND_ITEMS),"more":maxi(0,items.size()-FIND_ITEMS),"on_open":on_report})
	return groups

static func _first_upper(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)

static func find_sub(kind:String)->String:
	return String({"resource":"marked on the way","deposit":"workable ground","intelligence":"armed strangers","hearsay":"a name overheard","encounter":"wanderers met","knowledge":"learned from strangers"}.get(kind,"noted by the walkers"))
