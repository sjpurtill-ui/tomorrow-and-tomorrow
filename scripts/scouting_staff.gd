extends RefCounted
## Standing allocation controls physical parties, never fog or population directly.
const EXCHANGE=preload("res://scripts/society_exchange.gd")
const FOCI:={"exploration":"Exploration & discovery","recruitment":"Recruitment & influence"}
var host:Node
var data:Dictionary={}
func _init(world:Node)->void:host=world;reset()
func reset()->void:data={"share":0.0,"focus":"exploration","origin_city_id":"","last_day":-1,"next_review":0,"status":"Choose a scouting allocation to begin.","food_spent":0.0,"last_visits":{},"target_cursor":0}
func valid(value:Variant)->bool:
	if not value is Dictionary:return false
	if value.is_empty():return true
	if not host.city_intelligence.number(value.get("target_cursor",0)) or float(value.get("target_cursor",0))<0:return false
	var visits:Variant=value.get("last_visits",{})
	if not visits is Dictionary or visits.size()>64:return false
	for date in visits.values():
		if not host.city_intelligence.number(date) or float(date)<0:return false
	return host.city_intelligence.number(value.get("share")) and float(value.share)>=0 and float(value.share)<=.10 and String(value.get("focus","")) in FOCI and value.get("origin_city_id","") is String and String(value.get("origin_city_id","")).length()<100 and host.city_intelligence.number(value.get("last_day",-1)) and host.city_intelligence.number(value.get("next_review",0)) and host.city_intelligence.number(value.get("food_spent",0)) and float(value.get("food_spent",0))>=0 and value.get("status","") is String
func restore(value:Dictionary)->void:
	reset();data.merge(value,true)
func set_policy(share:float,focus:String)->Dictionary:
	if not is_finite(share) or share<0 or share>.10 or not FOCI.has(focus):return {"error":"Choose 0–10% of the population and a scouting focus."}
	if is_equal_approx(float(data.share),share) and data.focus==focus:return {"ok":true}
	data.share=share;data.focus=focus;data.next_review=int(WorldSimulation.state.elapsed_days);data.target_cursor=0
	data.status="Staff will organize parties on the next day." if share>0 else "No new departures. Parties already away will finish and return."
	return {"ok":true,"message":data.status}
func set_origin(origin_city_id:String)->Dictionary:
	var origin:Dictionary=host._scout_origin(origin_city_id)
	if origin_city_id!="" and String(origin.get("id",""))!=origin_city_id:return {"error":"Choose a player-controlled settlement as the scouting origin."}
	data.origin_city_id=String(origin.get("id",""));data.next_review=int(WorldSimulation.state.elapsed_days)
	data.status="New scouting parties will organize from %s." % String(origin.get("label","the selected settlement"))
	return {"ok":true,"message":data.status}
func snapshot()->Dictionary:
	var population:=maxi(0,floori(WorldSimulation.state.population_exact))
	var assigned:=0
	for mission:Dictionary in host.scout_missions:assigned+=int(mission.get("personnel",0))
	var recruitment:Dictionary={}
	if data.focus=="recruitment":
		var targets:=EXCHANGE.recruitment_targets(host)
		recruitment={"known_targets":targets.size(),"reception":EXCHANGE.reception_snapshot()}
		if not targets.is_empty():
			var option:Dictionary=host._scout_target_option(String(targets[0]))
			if not option.is_empty():
				recruitment["target_label"]=String(option.get("label","known community")).trim_prefix("VISIT ").capitalize()
				recruitment["outlook"]=EXCHANGE.invitation_outlook(String(option.get("civ_id","")))
	var origin:Dictionary=host._scout_origin(String(data.get("origin_city_id","")))
	return {"share":float(data.share),"focus":String(data.focus),"origin_city_id":String(origin.get("id","")),"origin_label":String(origin.get("label","Home settlement")),"origins":host.scout_origin_options(),"target":floori(population*float(data.share)),"away":assigned,"parties":host.scout_missions.size(),"status":String(data.status),"food_spent":float(data.food_spent),"daily_food":float(assigned)*.55,"review_in":maxi(0,int(data.next_review)-int(WorldSimulation.state.elapsed_days)),"reception":EXCHANGE.reception_snapshot() if data.focus=="recruitment" else {},"recruitment":recruitment}
func advance(day:int)->void:
	if day<=int(data.last_day):return
	data.last_day=day
	if float(data.share)<=0:return
	if not WorldSimulation.state.settlement_site_committed:data.status="Scouting begins after the settlement is founded.";return
	if day<int(data.next_review):return
	data.next_review=day+7
	var view:=snapshot();var free:=int(view.target)-int(view.away)
	if free<2:
		data.status="Allocation supports %d scout; a party needs at least 2. Increase the allocation." % int(view.target) if int(view.away)==0 else "%d people away of a %d-person allocation. Staff replace returning parties." % [int(view.away),int(view.target)]
		return
	var slots:int=host.scout_party_capacity()-int(view.parties)
	if slots<=0:data.status="All organized parties are away. Staff will replace them after return.";return
	var adults:=maxi(0,WorldSimulation.state.able_population()-WorldSimulation.military._mobilized_count()-host.mission_absent_personnel()-12)
	if adults<2:data.status="Waiting for people: %d adults free after existing commitments and essential work; a party needs 2." % adults;return
	var people:=mini(adults,clampi(ceili(float(free)/slots),2,mini(80,free)))
	var civilian_reserve:=maxf(1,WorldSimulation.state.population_exact)*.9*7
	var spendable:=maxf(0,WorldSimulation.food.total_stored()-civilian_reserve)
	if spendable<2*30*.55:
		data.status="Waiting for provisions: %.0f food available for travel; the smallest party needs 33. Seven days of food stay at home." % spendable
		return
	var targets:Array[String]=[]
	if data.focus=="recruitment":
		var known:=EXCHANGE.recruitment_targets(host)
		# Check a bounded group, rotating past unreachable reports on later
		# reviews. One inaccessible city must not block the entire service.
		for offset in mini(3,known.size()):targets.append(known[(int(data.target_cursor)+offset)%known.size()])
		data.target_cursor=(int(data.target_cursor)+mini(3,known.size()))%maxi(1,known.size())
		targets.append("recruit_people")
	else:targets.append("open_world")
	var last_reason:="No connected route found within our current travel and food budget."
	for target:String in targets:
		var search:=target in ["open_world","recruit_people"]
		# Familiar ground may need to be crossed to reach new country. Longer
		# budgets are tried only when shorter, affordable trips are not useful.
		for days:int in host.SCOUT_DURATIONS:
			var party_size:=mini(people,floori(spendable/(days*.55)))
			if party_size<2:break
			var quote:Dictionary=host.scout_mission_quote(days,target,"",party_size,true,String(view.get("origin_city_id","")))
			if not bool(quote.get("can_dispatch",false)):
				last_reason=String(quote.get("blocker",quote.get("error",last_reason)));continue
			if float(quote.provisions)>spendable:
				last_reason="Waiting for provisions: this route needs %.0f food; %.0f is available after the home reserve." % [float(quote.provisions),spendable];continue
			if search and float(quote.route_plan.get("novelty",0))<.38:
				last_reason="No useful uncharted route found within the affordable travel budget. Staff will check again; no food was spent.";continue
			var result:Dictionary=host.dispatch_scouts(days,target,"",party_size,true,String(view.get("origin_city_id","")))
			if result.has("error"):data.status=String(result.error);return
			var party:Dictionary=host.scout_missions[-1];party["staff_managed"]=true;party["staff_focus"]=String(data.focus)
			data.food_spent=float(data.food_spent)+float(party.provisions)
			var purpose:="chart unvisited ground"
			if data.focus=="recruitment":purpose="find communities and make contact" if search else "visit "+String(quote.target.label).trim_prefix("VISIT ")+" and build goodwill"
			data.status="%d scouts departed from %s to %s. Expected back in %d days; staff handle the next departure." % [int(party.personnel),String(party.get("origin_label","home")),purpose,int(party.duration_days)]
			return
	data.status=last_reason

func returned_influence(mission:Dictionary,reports:Array[Dictionary],day:int)->Array[String]:
	var outcomes:Array[String]=[]
	if mission.get("target_kind","") not in ["recruit_people","recruit_people_visit"]:return outcomes
	var visited:Dictionary={}
	for report:Dictionary in reports:
		var id:=String(report.get("controller",""))
		if id.is_empty() or visited.has(id) or int(report.get("observed_day",-1))<int(mission.get("start_day",0)):continue
		visited[id]=true
		var index:int=host._civilization_index(id)
		if index<0 or day-int(data.last_visits.get(id,-9999))<180:continue
		var relation:Dictionary=host.civilizations[index].player_relation
		if bool(relation.get("at_war",false)):continue
		var gain:=minf(.04,.005*maxi(1,int(report.get("observation_days",1))))
		var before:=float(relation.get("opinion",0))
		relation.opinion=minf(1,before+gain);data.last_visits[id]=day
		var ties:=EXCHANGE.connection(id)
		var familiarity_before:=float(ties.familiarity)
		ties.familiarity=minf(1.0,familiarity_before+minf(.12,.035+.005*maxi(1,int(report.get("observation_days",1)))))
		outcomes.append("Visits to %s improved goodwill by %.1f points and familiarity by %.1f points. Future household invitations will weigh that trust." % [host.city_intelligence.controller_label(id),(float(relation.opinion)-before)*100,(float(ties.familiarity)-familiarity_before)*100])
	return outcomes
