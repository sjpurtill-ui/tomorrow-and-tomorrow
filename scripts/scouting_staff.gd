extends RefCounted
## Standing allocation controls physical parties, never fog or population directly.
const FOCI:={"exploration":"Exploration & discovery","recruitment":"Recruitment & influence"}
var host:Node
var data:Dictionary={}
func _init(world:Node)->void:host=world;reset()
func reset()->void:data={"share":0.0,"focus":"exploration","last_day":-1,"next_review":0,"status":"Choose a scouting allocation to begin.","food_spent":0.0,"last_visits":{}}
func valid(value:Variant)->bool:
	if not value is Dictionary:return false
	if value.is_empty():return true
	var visits:Variant=value.get("last_visits",{})
	if not visits is Dictionary or visits.size()>64:return false
	for date in visits.values():
		if not host.city_intelligence.number(date) or float(date)<0:return false
	return host.city_intelligence.number(value.get("share")) and float(value.share)>=0 and float(value.share)<=.10 and String(value.get("focus","")) in FOCI and host.city_intelligence.number(value.get("last_day",-1)) and host.city_intelligence.number(value.get("next_review",0)) and host.city_intelligence.number(value.get("food_spent",0)) and float(value.get("food_spent",0))>=0 and value.get("status","") is String
func restore(value:Dictionary)->void:
	reset();data.merge(value,true)
func set_policy(share:float,focus:String)->Dictionary:
	if not is_finite(share) or share<0 or share>.10 or not FOCI.has(focus):return {"error":"Choose 0–10% of the population and a scouting focus."}
	if is_equal_approx(float(data.share),share) and data.focus==focus:return {"ok":true}
	data.share=share;data.focus=focus;data.next_review=int(WorldSimulation.state.elapsed_days)
	data.status="Staff will organize parties on the next day." if share>0 else "No new departures. Parties already away will finish and return."
	return {"ok":true,"message":data.status}
func snapshot()->Dictionary:
	var population:=maxi(0,floori(WorldSimulation.state.population_exact))
	var assigned:=0
	for mission:Dictionary in host.scout_missions:assigned+=int(mission.get("personnel",0))
	return {"share":float(data.share),"focus":String(data.focus),"target":floori(population*float(data.share)),"away":assigned,"parties":host.scout_missions.size(),"status":String(data.status),"food_spent":float(data.food_spent),"daily_food":float(assigned)*.55}
func advance(day:int)->void:
	if day<=int(data.last_day):return
	data.last_day=day
	if float(data.share)<=0:return
	if not WorldSimulation.state.settlement_site_committed:data.status="Scouting begins after the settlement is founded.";return
	if day<int(data.next_review):return
	data.next_review=day+7
	var view:=snapshot();var free:=int(view.target)-int(view.away)
	if free<2:data.status="%d people away of a %d-person allocation." % [int(view.away),int(view.target)];return
	var slots:int=host.scout_party_capacity()-int(view.parties)
	if slots<=0:data.status="All organized parties are away. Staff will replace them after return.";return
	var people:=clampi(ceili(float(free)/slots),2,mini(80,free))
	var civilian_reserve:=maxf(1,WorldSimulation.state.population_exact)*.9*7
	var spendable:=WorldSimulation.food.total_stored()-civilian_reserve
	if spendable<float(people)*30*.55:data.status="Waiting for provisions; seven days of food stay at home.";return
	var target:="open_world" if data.focus=="exploration" else preload("res://scripts/society_exchange.gd").recruitment_target(host)
	if target.is_empty():
		data.status="Home needs spare housing, water, two weeks of food and reception staff before further invitations." if preload("res://scripts/society_exchange.gd").reception_capacity()<2 else "No unassigned known community to visit. Exploration can establish contact first."
		return
	# Start with a short circuit. Extend only when reaching the knowledge frontier
	# needs it, rather than keeping people away a year for a local walk.
	var chosen:Dictionary={};var chosen_allowance:=30
	for days:int in [30,90]:
		var quote:Dictionary=host.scout_mission_quote(days,target,"",people,true)
		if not bool(quote.get("can_dispatch",false)) or float(quote.provisions)>spendable:
			if chosen.is_empty():data.status=String(quote.get("blocker",quote.get("error","Not enough supplies.")))
			continue
		if data.focus=="exploration" and float(quote.route_plan.get("novelty",0))<.38:
			data.status="No useful uncharted route within current reach. Staff are holding provisions at home.";continue
		if chosen.is_empty() or float(quote.route_plan.get("novelty",0))>float(chosen.route_plan.get("novelty",0))+.1:chosen=quote;chosen_allowance=days
		if float(quote.route_plan.get("novelty",0))>.6:break
	if chosen.is_empty():return
	var result:Dictionary=host.dispatch_scouts(chosen_allowance,target,"",people,true)
	if result.has("error"):data.status=String(result.error);return
	var party:Dictionary=host.scout_missions[-1];party["staff_managed"]=true;party["staff_focus"]=String(data.focus)
	data.food_spent=float(data.food_spent)+float(party.provisions)
	data.status="%d scouts departed on a %d-day expedition. Staff handle the next departure." % [people,int(party.duration_days)]

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
		outcomes.append("Visits to %s improved goodwill by %.1f points." % [host.city_intelligence.controller_label(id),(float(relation.opinion)-before)*100])
	return outcomes
