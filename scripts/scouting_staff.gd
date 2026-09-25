extends RefCounted
## Standing allocation controls physical parties, never fog or population directly.
const EXCHANGE=preload("res://scripts/society_exchange.gd")
const SURVIVAL=preload("res://scripts/scout_survival.gd")
const FOCI:={"exploration":"Exploration & discovery","recruitment":"Seek nomadic tribes","prospecting":"Resource prospecting"}
var host:Node
var data:Dictionary={}
func _init(world:Node)->void:host=world;reset()
func reset()->void:data={"share":0.0,"focus":"exploration","origin_city_id":"","last_day":-1,"next_review":0,"status":"Choose a scouting allocation to begin.","food_spent":0.0,"last_visits":{},"target_cursor":0,"city_watches":{},"veterancy":0.0,"homecomings":0,"scouts_lost":0,"last_loss_day":-1}
func valid(value:Variant)->bool:
	if not value is Dictionary:return false
	if value.is_empty():return true
	var watches:Variant=value.get("city_watches",{})
	if not watches is Dictionary or watches.size()>6:return false
	for id in watches:
		var watch:Variant=watches[id]
		if not id is String or id.length()>200 or not watch is Dictionary:return false
		if not watch.get("enabled") is bool or not watch.get("status") is String or String(watch.status).length()>1000:return false
		if not host.city_intelligence.number(watch.get("personnel")) or int(watch.personnel)<2 or int(watch.personnel)>8:return false
		if not host.city_intelligence.number(watch.get("duration_days")) or int(watch.duration_days) not in host.SCOUT_DURATIONS or float(watch.duration_days)!=float(int(watch.duration_days)):return false
		if not watch.get("origin_city_id","") is String:return false
		if not host.city_intelligence.number(watch.get("next_review",0)):return false
	if not host.city_intelligence.number(value.get("target_cursor",0)) or float(value.get("target_cursor",0))<0:return false
	if not host.city_intelligence.number(value.get("veterancy",0.0)) or float(value.get("veterancy",0.0))<0 or float(value.get("veterancy",0.0))>1:return false
	for counter in ["homecomings","scouts_lost"]:
		if not host.city_intelligence.number(value.get(counter,0)) or float(value.get(counter,0))<0:return false
	if not host.city_intelligence.number(value.get("last_loss_day",-1)):return false
	var visits:Variant=value.get("last_visits",{})
	if not visits is Dictionary or visits.size()>64:return false
	for date in visits.values():
		if not host.city_intelligence.number(date) or float(date)<0:return false
	return host.city_intelligence.number(value.get("share")) and float(value.share)>=0 and float(value.share)<=.10 and String(value.get("focus","")) in FOCI and value.get("origin_city_id","") is String and String(value.get("origin_city_id","")).length()<100 and host.city_intelligence.number(value.get("last_day",-1)) and host.city_intelligence.number(value.get("next_review",0)) and host.city_intelligence.number(value.get("food_spent",0)) and float(value.get("food_spent",0))>=0 and value.get("status","") is String
func restore(value:Dictionary)->void:
	reset();data.merge(value,true)
func set_policy(share:float,focus:String,delegated:bool=false)->Dictionary:
	if not is_finite(share) or share<0 or share>.10 or not FOCI.has(focus):return {"error":"Choose 0–10% of the population and a scouting focus."}
	if not delegated and WorldSimulation.actor_id=="player":WorldSimulation.direction.auto_scouting=false
	if is_equal_approx(float(data.share),share) and data.focus==focus:return {"ok":true}
	data.share=share;data.focus=focus;data.next_review=int(WorldSimulation.state.elapsed_days);data.target_cursor=0
	data.status="Staff will organize parties on the next day." if share>0 else "No new departures. Parties already away will finish and return."
	return {"ok":true,"message":data.status}
func set_origin(origin_city_id:String)->Dictionary:
	var origin:Dictionary=host._scout_origin(origin_city_id)
	if origin_city_id!="" and String(origin.get("id",""))!=origin_city_id:return {"error":"Choose a player-controlled settlement as the scouting origin."}
	if WorldSimulation.actor_id=="player":WorldSimulation.direction.auto_scouting=false
	data.origin_city_id=String(origin.get("id",""));data.next_review=int(WorldSimulation.state.elapsed_days)
	data.status="New scouting parties will organize from %s." % String(origin.get("label","the selected settlement"))
	return {"ok":true,"message":data.status}
func veterancy()->float:
	return clampf(float(data.get("veterancy",0.0)),0.0,SURVIVAL.MAX_VETERANCY)

func record_homecoming(returned:int,personnel:int,lost:int,day:int)->void:
	## Returning scouts teach the corps; the dead take their craft with them.
	data["veterancy"]=SURVIVAL.updated_veterancy(veterancy(),returned,personnel,lost)
	if returned>0:data["homecomings"]=int(data.get("homecomings",0))+1
	if lost>0:
		data["scouts_lost"]=int(data.get("scouts_lost",0))+lost
		data["last_loss_day"]=day

func prudence()->Dictionary:
	## The Chief Scout reads the people's natural increase and decides how much
	## standing risk to accept. Player orders bypass this; staff never do.
	var state:=WorldSimulation.state
	var population:=float(state.population_exact) if state.population_exact>0 else float(state.population_total)
	var vital:Dictionary=state.rolling_vital_balance(365) if state.has_method("rolling_vital_balance") else {}
	var tracked:=0
	if int(state.vital_statistics_tracking_start_day)>=0:tracked=int(state.elapsed_days)-int(state.vital_statistics_tracking_start_day)
	var view:=SURVIVAL.prudence(population,SURVIVAL.natural_increase(population,vital,tracked))
	view["standing_risk"]=standing_risk()
	view["veterancy"]=veterancy()
	return view

func standing_risk()->float:
	## Expected deaths a year if every party now away were kept replaced.
	var total:=0.0
	for mission:Dictionary in host.scout_missions:
		if bool(mission.get("staff_managed",false)) or mission.has("city_watch"):total+=float(mission.get("field_annual_risk",0.0))
	return total

func snapshot()->Dictionary:
	var pool:Dictionary=host.scout_origin_staffing(String(data.get("origin_city_id","")))
	var population:=maxi(0,floori(pool.population))
	var assigned:=int(pool.away)
	var recruitment:Dictionary={}
	if data.focus=="recruitment":
		recruitment={"reception":EXCHANGE.reception_snapshot(),"nomads":host.nomadic_recruitment_status()}
	var origin:Dictionary=host._scout_origin(String(data.get("origin_city_id","")))
	return {"share":float(data.share),"focus":String(data.focus),"origin_city_id":String(origin.get("id","")),"origin_label":String(origin.get("label","Home settlement")),"origins":host.scout_origin_options(),"target":floori(population*float(data.share)),"away":assigned,"parties":host.scout_missions.size(),"status":String(data.status),"food_spent":float(data.food_spent),"daily_food":float(assigned)*.55,"review_in":maxi(0,int(data.next_review)-int(WorldSimulation.state.elapsed_days)),"reception":EXCHANGE.reception_snapshot() if data.focus=="recruitment" else {},"recruitment":recruitment,"prospecting":host.prospecting_status(),"prudence":prudence()}
func advance(day:int)->void:
	preload("res://scripts/day_job.gd").run_parts(advance_steps(day))

## The daily staff review as ordered [label, callable] parts. The weekly
## dispatch tries one travel budget per part; later parts stop once one
## dispatches, fails, or runs out of affordable party size.
func advance_steps(day:int)->Array:
	var routes:Array=[]
	var shared:Dictionary={"active":false,"searching":false,"last_reason":"No connected route found within our current travel and food budget."}
	var parts:Array=[["scouting_review",func()->void:
		if day<=int(data.last_day):return
		data.last_day=day
		shared.active=true
	],["scouting_city_watches",func()->void:
		if shared.active:advance_city_watches(day)
	],["scouting_dispatch_plan",func()->Variant:
		if not shared.active:return null
		if float(data.share)<=0:return null
		if not WorldSimulation.state.settlement_site_committed:data.status="Scouting begins after the settlement is founded.";return null
		if day<int(data.next_review):return null
		data.next_review=day+7
		var view:=snapshot();var free:=int(view.target)-int(view.away)
		if free<2:
			data.status="Allocation supports %d scout; a party needs at least 2. Increase the allocation." % int(view.target) if int(view.away)==0 else "%d people away of a %d-person allocation. Staff replace returning parties." % [int(view.away),int(view.target)]
			return null
		var caution:Dictionary=view.prudence
		var slots:int=mini(host.scout_party_capacity(),int(caution.max_parties))-int(view.parties)
		if slots<=0:
			data.status="All organized parties are away. Staff will replace them after return." if int(view.parties)>=host.scout_party_capacity() else "The Chief Scout keeps %d part%s out. %s" % [int(caution.max_parties),"y" if int(caution.max_parties)==1 else "ies",String(caution.label)]
			return null
		var pool:Dictionary=host.scout_origin_staffing(String(view.origin_city_id))
		var adults:=int(pool.available)
		if adults<2:data.status="Waiting for people: %d adults free after existing commitments and essential work; a party needs 2." % adults;return null
		var people:=mini(adults,clampi(ceili(float(free)/slots),2,mini(80,free)))
		var civilian_reserve:=maxf(1,float(pool.population))*.9*7
		var spendable:=maxf(0,float(pool.food)-civilian_reserve)
		if spendable<2*30*.55:
			data.status="Waiting for provisions: %.0f food available for travel; the smallest party needs 33. Seven days of food stay at home." % spendable
			return null
		var target:="open_world"
		if data.focus=="recruitment":
			# Standing staff never choose the hostile act of recruiting inside a
			# foreign city. That requires the player's explicit named-city order.
			target="recruit_people"
		elif data.focus=="prospecting":
			var prospecting:Dictionary=host.prospecting_status()
			if not bool(prospecting.available):data.status=String(prospecting.message);return null
			target="rare_resources"
		shared.merge({"searching":true,"view":view,"people":people,"spendable":spendable,"target":target,"caution":caution},true)
		data["search_turn"]=int(data.get("search_turn",0))+1
		return routes
	]]
	# Familiar ground may need to be crossed to reach new country. Longer
	# budgets are tried only when shorter, affordable trips are not useful.
	# Rival staff with multi-day steps (day_span.gd) plan one trip length per
	# review, rotating through them; each plan is a costly route search.
	var durations:Array=host.SCOUT_DURATIONS
	if WorldSimulation.actor_id!="player" and WorldSimulation.span_limit>1:
		durations=[host.SCOUT_DURATIONS[posmod(int(data.get("search_turn",0)),host.SCOUT_DURATIONS.size())]]
	for days:int in durations:
		routes.append(["scouting_route_%d" % days,func()->void:
			if not shared.searching:return
			var target:String=shared.target;var view:Dictionary=shared.view;var spendable:float=shared.spendable
			var caution:Dictionary=shared.caution
			if days>int(caution.max_duration):
				shared.searching=false
				if shared.last_reason.begins_with("No connected"):shared.last_reason="The Chief Scout will not send parties farther than %d days out. %s" % [int(caution.max_duration),String(caution.label)]
				data.status=shared.last_reason;return
			var search:=target in ["open_world","recruit_people","rare_resources"]
			var party_size:=mini(int(shared.people),floori(spendable/(days*.55)))
			if party_size<2:
				shared.searching=false;data.status=shared.last_reason;return
			var quote:Dictionary=host.scout_mission_quote(days,target,"",party_size,true,String(view.get("origin_city_id","")))
			if not bool(quote.get("can_dispatch",false)):
				shared.last_reason=String(quote.get("blocker",quote.get("error",shared.last_reason)));return
			if float(quote.provisions)>spendable:
				shared.last_reason="Waiting for provisions: this route needs %.0f food; %.0f is available after the home reserve." % [float(quote.provisions),spendable];return
			if search and float(quote.route_plan.get("novelty",0))<.38:
				shared.last_reason="No useful uncharted route found within the affordable travel budget. Staff will check again; no food was spent.";return
			# The Chief Scout weighs the standing toll against the people's growth.
			var field:Dictionary=quote.get("field_risk",{})
			if float(caution.standing_risk)+float(field.get("annual_expected_deaths",0.0))>float(caution.budget) and int(view.parties)>0:
				shared.searching=false
				data.status="The Chief Scout holds the next party back: with the people growing so slowly, %d part%s on the road is risk enough." % [int(view.parties),"y" if int(view.parties)==1 else "ies"]
				return
			shared.searching=false
			var result:Dictionary=host.dispatch_scouts(days,target,"",party_size,true,String(view.get("origin_city_id","")))
			if result.has("error"):data.status=String(result.error);return
			var party:Dictionary=host.scout_missions[-1];party["staff_managed"]=true;party["staff_focus"]=String(data.focus)
			data.food_spent=float(data.food_spent)+float(party.provisions)
			var purpose:="chart unvisited ground"
			if data.focus=="recruitment":purpose="search for scarce wandering bands"
			elif data.focus=="prospecting":purpose="survey material, mineral and fuel sources"
			data.status="%d scouts departed from %s to %s. Expected back in %d days; staff handle the next departure." % [int(party.personnel),String(party.get("origin_label","home")),purpose,int(party.duration_days)]
		])
	routes.append(["scouting_status",func()->void:
		if shared.searching:
			data.status=shared.last_reason
			# Rival staff with multi-day steps (day_span.gd) wait four weeks after a
			# fruitless search instead of repeating every route plan each week.
			if WorldSimulation.actor_id!="player" and WorldSimulation.span_limit>1:data.next_review=maxi(int(data.next_review),day+28)
	])
	return parts

func city_watch(city_id:String)->Dictionary:
	return (data.get("city_watches",{}) as Dictionary).get(city_id,{}).duplicate(true)

func set_city_watch(city_id:String,enabled:bool,days:int=30,personnel:int=4)->Dictionary:
	if not enabled:
		data.city_watches.erase(city_id)
		return {"ok":true,"message":"Continuous scouting stopped. The party already away will finish and return."}
	if days not in host.SCOUT_DURATIONS or personnel<2 or personnel>8:return {"error":"Choose a 2–8-person party and a supported reconnaissance duration."}
	if host.city_intelligence.known("player",city_id).is_empty():return {"error":"Only a reported city can be watched."}
	if not data.city_watches.has(city_id) and data.city_watches.size()>=6:return {"error":"At most six city watches can be organized."}
	var origin:Dictionary=host._scout_origin(String(data.get("origin_city_id","")))
	data.city_watches[city_id]={"enabled":true,"duration_days":days,"personnel":personnel,"origin_city_id":String(origin.get("id","")),"next_review":int(WorldSimulation.state.elapsed_days),"status":"Continuous scouting ordered. Staff will organize one party on the next day."}
	return {"ok":true,"message":data.city_watches[city_id].status}

func advance_city_watches(day:int)->void:
	if not WorldSimulation.state.settlement_site_committed:return
	var caution:Dictionary={}
	for city_id:String in data.city_watches:
		var watch:Dictionary=data.city_watches[city_id]
		if not bool(watch.enabled) or day<int(watch.next_review):continue
		watch.next_review=day+7
		var away:=false
		for mission:Dictionary in host.scout_missions:
			if String(mission.get("target_id",""))=="city:"+city_id:
				away=true;watch.status="One party is visiting this city. The next departure follows its return.";break
		if away:continue
		if host.city_intelligence.known("player",city_id).is_empty():watch.enabled=false;watch.status="Stopped: the city's reported location is unavailable.";continue
		var quote:Dictionary=host.scout_mission_quote(int(watch.duration_days),"city:"+city_id,"",int(watch.personnel),true,String(watch.origin_city_id))
		if not bool(quote.get("can_dispatch",false)):
			watch.status=String(quote.get("error",quote.get("blocker","Waiting for a route.")));continue
		if caution.is_empty():caution=prudence()
		var field:Dictionary=quote.get("field_risk",{})
		if float(caution.standing_risk)+float(field.get("annual_expected_deaths",0.0))>float(caution.budget) and float(caution.standing_risk)>0.0:
			watch.status="The Chief Scout rests this watch while other parties are out; the people are growing too slowly to risk more.";continue
		var pool:Dictionary=host.scout_origin_staffing(String(watch.origin_city_id))
		var reserve:=maxf(1,float(pool.population))*.9*7
		if float(pool.food)-float(quote.provisions)<reserve:
			watch.status="Waiting for provisions; seven days of food are reserved at home.";continue
		var result:Dictionary=host.dispatch_scouts(int(watch.duration_days),"city:"+city_id,"",int(watch.personnel),true,String(watch.origin_city_id))
		if result.has("error"):watch.status=String(result.error);continue
		var mission:Dictionary=host.scout_missions[-1]
		mission["city_watch"]=city_id
		caution["standing_risk"]=float(caution.standing_risk)+float(mission.get("field_annual_risk",0.0))
		watch.status="%d scouts away; reports arrive on return. Staff will organize the next visit." % int(mission.personnel)
		data.food_spent=float(data.food_spent)+float(mission.provisions)

func city_watch_returned(mission:Dictionary,day:int,returned:bool)->void:
	var id:=String(mission.get("city_watch",""))
	if id.is_empty() or not data.city_watches.has(id):return
	var watch:Dictionary=data.city_watches[id]
	var rest:=int(prudence().watch_rest_days) if returned else 1
	watch.next_review=day+rest
	watch.status=("Report delivered. The next visit will be organized tomorrow." if rest<=1 else "Report delivered. The Chief Scout rests the watchers %d days before the next visit." % rest) if returned else "Watch paused: the party failed to return. Review before sending another."
	if not returned:watch.enabled=false

func returned_influence(mission:Dictionary,reports:Array[Dictionary],day:int)->Array[String]:
	var outcomes:Array[String]=[]
	if mission.get("target_kind","")!="recruit_people_visit":return outcomes
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
