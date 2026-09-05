extends RefCounted
## Foreign residents leave their source ledger at departure and enter the player
## ledger only on arrival. Transit owns precisely those absent people meanwhile.
const MAX_TRANSFERS:=8
const MAX_GROUPS:=128
const STATUSES:Dictionary={"citizen":"Citizens","enslaved":"Enslaved residents","penal":"Coerced penal labor"}
var data:Dictionary={"next_id":1,"last_day":-1,"transfers":[],"groups":[],"history":[]}

func reset()->void:
	data={"next_id":1,"last_day":-1,"transfers":[],"groups":[],"history":[]}

func preview(civ_id:String,region_id:String,count:int,status:String)->Dictionary:
	if not STATUSES.has(status): return {"error":"Choose citizenship, slavery or coerced penal status."}
	if SettlementModel._primary_settlement_id().is_empty(): return {"error":"Establish a home settlement before moving residents there."}
	if count<1: return {"error":"Choose at least one resident."}
	if data.transfers.size()>=MAX_TRANSFERS: return {"error":"All eight transport groups are already traveling."}
	if data.groups.size()+data.transfers.size()>=MAX_GROUPS: return {"error":"The community-record capacity is full."}
	var region:Dictionary=CivilizationSystem.region_snapshot(civ_id,region_id)
	if region.is_empty() or String(region.controller)!="player": return {"error":"Select a region you occupy."}
	var garrison:Dictionary=MilitaryCampaign.occupation_force_for_region(civ_id,region_id)
	if int(garrison.get("troops",0))<=0: return {"error":"An unsupported occupation cannot organize a transfer."}
	if count>floori(float(region.population)): return {"error":"There are fewer residents here than requested."}
	var available_housing:=maxi(0,GameState.housing_capacity-ceili(SettlementModel.primary_population_exact()))
	for transfer:Dictionary in data.transfers: available_housing-=int(transfer.people)
	if count>available_housing: return {"error":"Home has room for %d additional residents after pending arrivals." % maxi(0,available_housing)}
	var start:Vector2=CivilizationSystem.city_intelligence.vector(CivilizationSystem.city_intelligence.site(region_id).get("position",{}))
	var target:Vector2=CivilizationSystem.player_world_origin
	var plan:Dictionary=CivilizationSystem._plan_scout_land_route(start,target)
	if not bool(plan.get("ok",false)): return {"error":String(plan.get("reason","No continuous land route is available."))}
	var route:Array=plan.get("route",[])
	if route.is_empty(): return {"error":"No surveyed route is available."}
	var distance:float=CivilizationSystem._scout_route_distance(route)
	var days:=maxi(1,ceili(distance/12.0))
	var food:=float(count)*(days+7)
	var civ:Dictionary=CivilizationSystem.civilizations[CivilizationSystem._civilization_index(civ_id)]
	var local_food:=float(civ.food_days)*float(region.population)
	if food>local_food: return {"error":"The occupied region lacks %.0f travel rations. Shorten the transfer or restore local supplies." % (food-local_food)}
	if float(civ.population)-count<1: return {"error":"This transfer would exceed the source population."}
	return {"ok":true,"people":count,"status":status,"route":route,"distance":distance,"days":days,"food":food,"source":civ_id,"region":region_id,"destination":SettlementModel._primary_settlement_id()}

func depart(civ_id:String,region_id:String,count:int,status:String)->Dictionary:
	var ready:=preview(civ_id,region_id,count,status)
	if ready.has("error"): return ready
	var index:int=CivilizationSystem._civilization_index(civ_id)
	var civ:Dictionary=CivilizationSystem.civilizations[index]
	var region_index:int=CivilizationSystem._region_index(civ,region_id)
	var region:Dictionary=civ.strategic_regions[region_index]
	var profile:Dictionary={}
	var old_population:=float(civ.population)
	for key:String in civ.cohorts:
		var amount:=float(civ.cohorts[key])*count/old_population
		profile[key]=amount; civ.cohorts[key]=maxf(0,float(civ.cohorts[key])-amount)
	var food_remaining:=maxf(0,float(civ.food_days)*old_population-float(ready.food))
	civ.population=old_population-count
	civ.food_days=food_remaining/maxf(1,float(civ.population))
	region.population=float(region.population)-count
	var governance:Dictionary=preload("res://scripts/occupation_governance.gd").state(region)
	if status!="citizen":
		governance.grievance=clampf(float(governance.grievance)+.10,0,1)
		civ.player_relation.opinion=clampf(float(civ.player_relation.get("opinion",0))-.08,-1,1)
	region.governance=governance
	civ.strategic_regions[region_index]=region
	CivilizationSystem.civilizations[index]=civ
	ready.merge({"id":int(data.next_id),"depart_day":int(GameState.elapsed_days),"position":(ready.route as Array)[0].duplicate(true),"traveled":0.0,"cohorts":profile,"origin_name":String(civ.name),"origin_region_name":String(region.name),"mortality_remainder":0.0,"arrived":false},true)
	ready.erase("ok")
	data.next_id=int(data.next_id)+1
	if int(data.last_day)<0: data.last_day=int(GameState.elapsed_days)
	data.transfers.append(ready)
	return {"ok":true,"message":"%d residents departed %s with %.0f travel rations. Arrival is expected in about %d days; their legal status on arrival is %s." % [count,region.name,float(ready.food),int(ready.days),STATUSES[status]]}

func advance(day:int)->void:
	if int(data.last_day)<0: data.last_day=day-1
	while int(data.last_day)<day:
		data.last_day=int(data.last_day)+1
		_day(int(data.last_day))

func _day(day:int)->void:
	var pending:Array=[]
	for transfer:Dictionary in data.transfers:
		if day<=int(transfer.depart_day): pending.append(transfer); continue
		var people:=int(transfer.people)
		var needed:=float(people)
		var eaten:=minf(float(transfer.food),needed)
		transfer.food=maxf(0,float(transfer.food)-eaten)
		if eaten<needed:
			transfer.mortality_remainder=float(transfer.mortality_remainder)+people*.01*(1-eaten/maxf(1,needed))
			var deaths:=mini(people,floori(float(transfer.mortality_remainder)))
			transfer.mortality_remainder=float(transfer.mortality_remainder)-deaths
			transfer.people=people-deaths
			for key in transfer.cohorts: transfer.cohorts[key]=float(transfer.cohorts[key])*float(people-deaths)/maxf(1,people)
			people=int(transfer.people)
		if people<=0: _record(transfer,"No survivors reached a settlement.",day); continue
		transfer.traveled=minf(float(transfer.distance),float(transfer.traveled)+12.0*(.5+.5*eaten/maxf(1,needed)))
		var point:Vector2=CivilizationSystem.city_intelligence.route_position(transfer.route,float(transfer.traveled)/maxf(.001,float(transfer.distance)))
		transfer.position={"x":point.x,"z":point.y}
		if float(transfer.traveled)>=float(transfer.distance):
			if _housing_room(String(transfer.destination))<people:
				transfer.arrived=true; pending.append(transfer); continue
			_arrive(transfer,day)
		else: pending.append(transfer)
	data.transfers=pending
	if day%30==0:
		for group:Dictionary in data.groups:
			var coercion:=0.0 if String(group.status)=="citizen" else (1.0 if String(group.status)=="enslaved" else .7)
			group.grievance=clampf(float(group.grievance)+.012*coercion-.003*(1-coercion),0,1)
			group.inherited_grievance=move_toward(float(group.inherited_grievance),float(group.grievance),1.0/300.0)
			group.welfare=clampf(float(group.welfare)+.004*(1-coercion)-.008*coercion,0,1)

func _housing_room(city_id:String)->int:
	var city:=SettlementModel.settlement_record(city_id)
	if city.is_empty(): return 0
	var housing:int=SettlementModel.with_city_resources(city_id,func()->int:return GameState.housing_capacity)
	return maxi(0,housing-ceili(SettlementModel._settlement_population(city)))

func _arrive(transfer:Dictionary,day:int)->void:
	var old_population:=GameState.population_exact
	var counts:Dictionary={}
	for city:Dictionary in GameState.player_settlements:
		if not bool(city.get("primary",false)): counts[String(city.id)]=SettlementModel._settlement_population(city)
	var people:=int(transfer.people)
	GameState.register_population_arrivals(people,"Arrivals from "+String(transfer.origin_name),transfer.cohorts)
	for city:Dictionary in GameState.player_settlements:
		if counts.has(String(city.id)): city.population_share=(float(counts[String(city.id)])+(people if String(city.id)==String(transfer.destination) else 0))/GameState.population_exact
	for group:Dictionary in data.groups: group.share=float(group.share)*old_population/GameState.population_exact
	data.groups.append({"id":int(transfer.id),"origin":String(transfer.source),"origin_region":String(transfer.region),"origin_name":String(transfer.origin_name),"settlement_id":String(transfer.destination),"status":String(transfer.status),"share":float(people)/GameState.population_exact,"arrival_day":day,"grievance":.15 if String(transfer.status)=="citizen" else .65,"inherited_grievance":0.0,"welfare":.5})
	SettlementModel.with_city_resources(String(transfer.destination),func()->void:FoodSystem.receive_external_food(float(transfer.food)))
	_record(transfer,"Arrived: %d residents, %s." % [people,STATUSES[String(transfer.status)]],day)

func emancipate(group_id:int)->Dictionary:
	for group:Dictionary in data.groups:
		if int(group.id)!=group_id: continue
		if String(group.status)=="citizen": return {"error":"This community already has equal citizenship."}
		group.status="citizen"
		return {"ok":true,"message":"Citizenship and equal legal rights granted. Prior grievance and inherited harm remain and can heal over time."}
	return {"error":"Community not found."}

func effects()->Dictionary:
	var inequality:=0.0; var grievance:=0.0; var deprivation:=0.0
	for group:Dictionary in data.groups:
		var share:=float(group.share)
		inequality+=share*(0 if String(group.status)=="citizen" else 1)
		grievance+=share*(float(group.grievance)+float(group.inherited_grievance))*.5
		deprivation+=share*(1-float(group.welfare))
	return {"inequality":inequality,"grievance":grievance,"deprivation":deprivation}

func _record(transfer:Dictionary,message:String,day:int)->void:
	data.history.push_front({"id":int(transfer.id),"day":day,"people":int(transfer.people),"origin":String(transfer.origin_name),"description":message})
	while data.history.size()>32: data.history.pop_back()
	GameState.simulation_events.push_front({"day":day,"title":"Population transfer","description":message,"domain":"institutions","severity":"notice"})

static func validate(payload:Dictionary)->Array[String]:
	var errors:Array[String]=[]
	for table in ["transfers","groups","history"]:
		if not payload.get(table,[]) is Array: return ["Invalid population-transfer table."]
	if payload.get("transfers",[]).size()>MAX_TRANSFERS or payload.get("groups",[]).size()>MAX_GROUPS or payload.get("history",[]).size()>32: errors.append("Population-transfer bounds exceeded.")
	var total_share:=0.0
	var ids:Dictionary={}
	var greatest_id:=0
	for group in payload.get("groups",[]):
		if not group is Dictionary: return ["Invalid community record."]
		var group_id:=int(group.get("id",0))
		if group_id<=0 or ids.has(group_id): errors.append("Duplicate or invalid community ID.")
		ids[group_id]=true;greatest_id=maxi(greatest_id,group_id)
		if not STATUSES.has(String(group.get("status",""))): errors.append("Invalid community legal status.")
		for field in ["share","grievance","inherited_grievance","welfare"]:
			var value:=float(group.get(field,NAN))
			if not is_finite(value) or value<0 or value>1: errors.append("Invalid community social measure.")
		total_share+=float(group.get("share",0))
	if total_share>1.00001: errors.append("Community shares exceed the population.")
	for transfer in payload.get("transfers",[]):
		if not transfer is Dictionary: return ["Invalid traveling cohort."]
		var transfer_id:=int(transfer.get("id",0))
		if transfer_id<=0 or ids.has(transfer_id): errors.append("Duplicate or invalid transfer ID.")
		ids[transfer_id]=true;greatest_id=maxi(greatest_id,transfer_id)
		if String(transfer.get("destination","")).is_empty() or not transfer.get("cohorts",{}) is Dictionary: errors.append("Invalid transfer destination or cohorts.")
		if not STATUSES.has(String(transfer.get("status",""))) or int(transfer.get("people",-1))<0: errors.append("Invalid traveling population or status.")
		if not transfer.get("route",[]) is Array or transfer.get("route",[]).size()>512: errors.append("Invalid transfer route.")
		for field in ["food","distance","traveled"]:
			var value:=float(transfer.get(field,NAN))
			if not is_finite(value) or value<0: errors.append("Invalid transfer quantity.")
	if int(payload.get("next_id",1))<=greatest_id: errors.append("Next transfer ID would duplicate a record.")
	return errors
