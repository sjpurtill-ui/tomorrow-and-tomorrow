extends RefCounted
const GOVERNANCE=preload("res://scripts/occupation_governance.gd")
const MAX_OCCUPIED:=256
const ORDERS:Dictionary={"protect":"Protect residents","institutions":"Preserve institutions","organize":"Build independence support","outside_help":"Seek outside support","autonomy":"Negotiate autonomy","revolt":"Attempt independence"}
var data:Dictionary={"preparation":{},"remnant":{},"occupied":[],"history":[],"last_day":-1,"attempts":0}
var surface_assessor:Callable=Callable()
func reset()->void:
	data={"preparation":{},"remnant":{},"occupied":[],"history":[],"last_day":-1,"attempts":0}
func home_unavailable()->bool:
	var home:=SettlementModel.settlement_record(SettlementModel._primary_settlement_id())
	return not String(home.get("occupied_by","")).is_empty()
func has_active_occupation()->bool:
	for entry:Dictionary in data.occupied:
		if not bool(entry.get("liberated",false)):return true
	return false
func absent_group()->Dictionary:
	return data.preparation if not data.preparation.is_empty() else data.remnant
func absent_people()->int:
	return int(absent_group().get("people",0))
func prepare(people:int,days:int)->Dictionary:
	if home_unavailable():return {"error":"The home city is occupied. Use local recovery decisions."}
	if MilitaryCampaign.active_siege.is_empty() or String(MilitaryCampaign.active_siege.mode)!="defensive":return {"error":"Escape preparation requires a siege of your home settlement."}
	if not data.preparation.is_empty() or not data.remnant.is_empty():return {"error":"An escape group is already committed."}
	if bool(GameState.settlement_convoy.get("active",false)):return {"error":"An existing founding convoy must finish before another displaced group is organized."}
	var available:=maxi(0,floori(SettlementModel.primary_population_exact())-MilitaryCampaign._mobilized_count()-int(CivilizationSystem.player_population_commitments().total_absent)-1)
	var limit:=mini(available,floori(SettlementModel.primary_population_exact()*.35))
	if people<2 or people>limit:return {"error":"Choose 2–%d available residents; an escape group can include at most 35%% of this settlement." % maxi(0,limit)}
	days=clampi(days,7,90)
	var food:=float(people*days)
	var timber:=float(people)*.2
	if FoodSystem.total_stored()<food:return {"error":"The group needs %.0f food rations from your actual stores." % food}
	if float(GameState.resource_stockpiles.get("Timber",0))<timber:return {"error":"The group needs %.1f Timber for portable shelter and rebuilding." % timber}
	var issued:=FoodSystem.issue_for_obligation(food,"siege_escape","Escape group supplies",days,people)
	GameState.resource_stockpiles.Timber=float(GameState.resource_stockpiles.get("Timber",0))-timber
	var cohorts:Dictionary={}
	for key in GameState.population_cohorts:cohorts[key]=float(GameState.population_cohorts[key])*people/maxf(1,GameState.population_exact)
	var functions:Dictionary=GameState.proportional_population_commitment(people)
	functions.productive=int(functions.productive)+int(functions.mobilized);functions.mobilized=0
	SettlementModel.settlement_record(SettlementModel._primary_settlement_id()).recovery_capital=true
	data.preparation={"people":people,"food":issued,"timber":timber,"cohorts":cohorts,"functions":functions,"prepared_day":int(GameState.elapsed_days),"siege_id":String(MilitaryCampaign.active_siege.id),"origin_city":SettlementModel._primary_settlement_id(),"origin_name":GameState.settlement_name,"origin_position":CivilizationSystem.city_intelligence.point(CivilizationSystem.player_world_origin),"mortality_remainder":0.0}
	if int(data.last_day)<0:data.last_day=int(GameState.elapsed_days)
	return {"ok":true,"message":"%d residents, %.0f rations and %.1f Timber set aside. They now consume these supplies; fewer workers support the defenses. Choose a direction and attempt escape before supplies run out." % [people,issued,timber]}
func defense_factor()->float:
	return clampf(1.0-float(absent_people())/maxf(1,SettlementModel.primary_population_exact())*.8,.5,1)
func escape(heading:String="east")->Dictionary:
	if data.preparation.is_empty():return {"error":"Prepare an escape group first."}
	var preparation:Dictionary=data.preparation
	var siege:Dictionary=MilitaryCampaign.active_siege
	if siege.is_empty():
		for past:Dictionary in MilitaryCampaign.siege_history:
			if String(past.id)==String(preparation.siege_id):siege=past;break
	if siege.is_empty():return {"error":"The group's siege record is unavailable."}
	var start:=CivilizationSystem.city_intelligence.vector(preparation.origin_position)
	var angle:=deg_to_rad(float(CivilizationSystem.SCOUT_HEADINGS.get(heading,0)))
	var destination:=start+Vector2(cos(angle),sin(angle))*24.0
	var route:Dictionary=CivilizationSystem._plan_scout_land_route(start,destination)
	if not bool(route.get("ok",false)):return {"error":String(route.get("reason","No escape route is available."))}
	var preparation_days:=maxi(0,int(GameState.elapsed_days)-int(preparation.prepared_day))
	var supply:=clampf(float(preparation.food)/maxf(1,float(preparation.people)*14),0,1)
	var chance:=clampf(.12+.55*(1-float(siege.get("blockade",0)))+minf(.2,float(preparation_days)*.01)+supply*.1,.05,.90)
	var rng:=RandomNumberGenerator.new();rng.seed=GameState.world_seed^int((siege.get("threat",{}) as Dictionary).get("seed",0))^int(data.attempts)*104729
	data.attempts=int(data.attempts)+1
	if rng.randf()>chance:
		# The group is intercepted and remains among the settlement's people.
		# Supplies are lost; nobody is created, removed, or silently killed.
		data.preparation={}
		_record("Escape intercepted. The group remains in the settlement; its prepared supplies were lost.")
		return {"ok":true,"escaped":false,"chance":chance,"message":"The escape was intercepted. Residents remain in the settlement, with their prepared supplies lost."}
	var remnant:=preparation.duplicate(true)
	remnant.merge({"position":preparation.origin_position.duplicate(true),"route":route.route,"distance":float(route.distance_km),"traveled":0.0,"destination":CivilizationSystem.city_intelligence.point(destination),"phase":"escaping","heading":heading,"depart_day":int(GameState.elapsed_days)},true)
	data.remnant=remnant;data.preparation={}
	_record("Escape group departed. It must physically clear the siege and reach viable land before rebuilding.")
	return {"ok":true,"escaped":true,"chance":chance,"message":"The group slipped through the siege. It is traveling with finite supplies; rebuilding still requires viable land."}
func capture(civ_id:String)->Dictionary:
	var city:=SettlementModel.settlement_record(SettlementModel._primary_settlement_id())
	if city.is_empty() or home_unavailable():return {"error":"No free home settlement can be occupied."}
	if data.occupied.size()>=MAX_OCCUPIED:return {"error":"Occupied settlement capacity reached."}
	if not data.preparation.is_empty():
		var attempt:=escape()
		if attempt.has("error"):data.preparation={}
	city.occupied_by=civ_id
	var region:Dictionary={"population":maxf(1,SettlementModel.primary_population_exact()),"resistance":.45,"integration":0.0,"damage":.35}
	var government:=GOVERNANCE.state(region)
	var index:int=CivilizationSystem._civilization_index(civ_id)
	if index>=0 and float(CivilizationSystem.civilizations[index].get("aggression",0))>.6:government.policy="military_rule"
	region.governance=government
	var entry:Dictionary={"city_id":String(city.id),"occupier":civ_id,"captured_day":int(GameState.elapsed_days),"region":region,"order":{},"report":{},"report_due":-1,"last_report_day":int(GameState.elapsed_days),"next_order_day":int(GameState.elapsed_days)}
	data.occupied.append(entry)
	if int(data.last_day)<0:data.last_day=int(GameState.elapsed_days)
	var active_people:=int(MilitaryCampaign.home_army.get("troops",0))+int(MilitaryCampaign.home_army.get("wounded_pool",0))+int(MilitaryCampaign.home_army.get("scattered_pool",0))+MilitaryCampaign.aggregate_recruits+MilitaryCampaign._queued_trainees()+MilitaryCampaign.training_injury_pool
	entry.captive_people=active_people
	entry.captive_injuries=int(MilitaryCampaign.home_army.get("wounded_pool",0))+MilitaryCampaign.training_injury_pool
	entry.captive_disabled=int(MilitaryCampaign.home_army.get("severe_disabled_pool",0))
	entry.seized_training=MilitaryCampaign.training_queue.duplicate(true)
	MilitaryCampaign.aggregate_recruits=0;MilitaryCampaign.training_queue.clear();MilitaryCampaign.training_injury_pool=0
	entry.seized_production=MilitaryCampaign.equipment_queue.duplicate(true);MilitaryCampaign.equipment_queue.clear()
	MilitaryCampaign.home_army.captured_pool=int(MilitaryCampaign.home_army.get("captured_pool",0))+active_people
	MilitaryCampaign.home_army.formations=[];MilitaryCampaign.home_army.troops=0
	for key in ["wounded_pool","disabled_pool","severe_disabled_pool","scattered_pool"]:MilitaryCampaign.home_army[key]=0
	entry["seized_equipment"]=MilitaryCampaign.military_inventory.duplicate(true)
	entry["seized_consumables"]=MilitaryCampaign.military_consumables.duplicate(true)
	MilitaryCampaign.military_inventory.clear();MilitaryCampaign.military_consumables.clear()
	entry.report=region.duplicate(true)
	for other:Dictionary in GameState.player_settlements:
		if String(other.id)!=String(city.id) and String(other.get("occupied_by","")).is_empty():
			_activate_capital(other);break
	_record("%s is occupied. Residents retain their society and institutions; recovery decisions remain available." % String(city.name))
	return {"ok":true,"message":"The city is occupied. Continue through local resistance, negotiation, or the escaped group's recovery."}
func _activate_capital(city:Dictionary)->void:
	var previous:=SettlementModel.settlement_record(SettlementModel._primary_settlement_id())
	if String(previous.get("id",""))==String(city.id):return
	var old_count:=maxf(1,SettlementModel.primary_population_exact())
	var layout_fields:Array[String]=["settlement_nuclei","settlement_routes"]
	previous.recovery_layout={}
	for field in layout_fields:previous.recovery_layout[field]=GameState.get(field).duplicate(true)
	var old_resources:Dictionary={}
	for key in SettlementModel.CITY_RESOURCE_DEFAULTS:
		var value:Variant=GameState.get(key)
		old_resources[key]=value.duplicate(true) if value is Dictionary or value is Array else value
	previous.local_resources=old_resources;previous.primary=false;previous.population_share=old_count/maxf(1,GameState.population_exact)
	SettlementModel._ensure_city_resources(city)
	var resources:Dictionary=city.local_resources
	for key in SettlementModel.CITY_RESOURCE_DEFAULTS:
		var value:Variant=resources.get(key,SettlementModel.CITY_RESOURCE_DEFAULTS[key])
		GameState.set(key,value.duplicate(true) if value is Dictionary or value is Array else value)
	for field in layout_fields:
		var target:Array=GameState.get(field)
		target.assign(city.get("recovery_layout",{}).get(field,[]))
	city.primary=true;city.population_share=0.0;city.recovery_capital=true
	city.erase("local_resources")
	GameState.settlement_name=String(city.name)
	GameState.settlement_founded_day=int(city.get("founded_day",GameState.elapsed_days))
	var point:Vector2=SettlementModel._record_position(city)
	GameState.settlement_founded_at=Vector3(point.x,0,point.y);GameState.selected_player_settlement_id=String(city.id)
	CivilizationSystem.register_player_origin(point)
	GameState.settlement_network_revision+=1;GameState.morphology_revision+=1
	SettlementModel.ensure_founded()
	# Construction and equipment at the captured place never move with the title.
	MilitaryCampaign.settlement_defense={"stage":0,"integrity":1.0,"project_stage":-1,"project_progress":0.0,"reserved_materials":{}}
func queue_resistance(city_id:String,order:String)->Dictionary:
	if not ORDERS.has(order):return {"error":"Unknown recovery decision."}
	for entry:Dictionary in data.occupied:
		if String(entry.city_id)!=city_id or bool(entry.get("liberated",false)):continue
		if not entry.order.is_empty() or int(GameState.elapsed_days)<int(entry.next_order_day):return {"error":"The current local effort needs time before another can begin."}
		var city:=SettlementModel.settlement_record(city_id)
		var population:=SettlementModel._settlement_population(city)
		var food_cost:=maxf(1,population*.5)
		var stored:float=SettlementModel.with_city_resources(city_id,func()->float:return FoodSystem.total_stored())
		if stored<food_cost:return {"error":"Residents need %.0f local rations to sustain this effort." % food_cost}
		var delay:=0 if home_unavailable() else maxi(1,ceili(SettlementModel._record_position(city).distance_to(CivilizationSystem.player_world_origin)/17.0))
		entry.order={"kind":order,"arrival_day":int(GameState.elapsed_days)+delay,"resolve_day":int(GameState.elapsed_days)+delay+30,"food_cost":food_cost,"funded":false}
		entry.next_order_day=int(GameState.elapsed_days)+delay+60
		return {"ok":true,"message":"%s reserved an effort requiring %.0f local rations on receipt. The effort takes 30 days after instructions arrive%s." % [String(city.name),food_cost,"; communication takes %d days each way" % delay if delay>0 else ""]}
	return {"error":"This city is not under occupation."}
func _resolve_resistance(entry:Dictionary,day:int)->void:
	var order:=String(entry.order.kind);var region:Dictionary=entry.region;var government:Dictionary=region.governance
	var rng:=RandomNumberGenerator.new();rng.seed=GameState.world_seed^day*8191^hash(String(entry.city_id))
	var success:=false
	var outcome_message:="Local effort completed: %s. Independence remains unresolved." % ORDERS[order]
	match order:
		"protect":government.welfare=clampf(float(government.welfare)+.08,0,1);government.support=clampf(float(government.support)+.025,0,1)
		"institutions":government.local_institutions=clampf(float(government.local_institutions)+.075,0,1)
		"organize":government.support=clampf(float(government.support)+.10,0,1);government.suspicion=clampf(float(government.suspicion)+.12,0,1)
		"outside_help":
			var friendly:=false
			for civ:Dictionary in CivilizationSystem.civilizations:
				if int(civ.player_relation.get("contact_level",0))>=2 and float(civ.player_relation.get("opinion",0))>.3:friendly=true;break
			if friendly:government.support=clampf(float(government.support)+.08,0,1)
			else:outcome_message="No known friendly polity offered support. The outside appeal did not strengthen the movement."
			government.suspicion=clampf(float(government.suspicion)+.08,0,1)
		"autonomy":success=float(government.support)>.45 and rng.randf()<float(government.support)*(1-float(government.repression))*.65
		"revolt":
			success=float(government.support)>.55 and rng.randf()<float(government.support)*float(government.local_institutions)*.65
			if not success:
				government.repression=clampf(float(government.repression)+.2,0,1);government.welfare=maxf(0,float(government.welfare)-.12)
				var deaths:=maxi(0,floori(float(region.population)*.01))
				_lose_people(deaths,"Deaths in failed independence attempt",String(entry.city_id))
	if rng.randf()<float(government.suspicion)*float(government.repression):government.welfare=maxf(0,float(government.welfare)-.04)
	region.governance=government;entry.region=region;entry.order={}
	if success:
		var city:=SettlementModel.settlement_record(String(entry.city_id));city.erase("occupied_by")
		entry["liberated"]=true
		var released:=mini(int(entry.get("captive_people",0)),int(MilitaryCampaign.home_army.get("captured_pool",0)))
		MilitaryCampaign.home_army.captured_pool=int(MilitaryCampaign.home_army.get("captured_pool",0))-released
		GameState.receive_injured_veterans(mini(released,int(entry.get("captive_injuries",0))),mini(released,int(entry.get("captive_disabled",0))))
		entry.captive_people=0
		outcome_message="%s regained local independence after %s." % [String(city.name),ORDERS[order]]
	entry.pending_message=outcome_message
	var city:=SettlementModel.settlement_record(String(entry.city_id))
	var delay:=0 if home_unavailable() else maxi(1,ceili(SettlementModel._record_position(city).distance_to(CivilizationSystem.player_world_origin)/17))
	entry.report_due=day+delay
func assess_site(point:Vector2,actual:bool=false)->Dictionary:
	if not CivilizationSystem._scout_land_at(point):return {"valid":false,"reason":"This site is not traversable land."}
	if not surface_assessor.is_valid():return {"valid":false,"reason":"A local surface survey is required before rebuilding."}
	var surface:Dictionary=surface_assessor.call(Vector3(point.x,0,point.y))
	if not bool(surface.get("valid",false)):return surface
	if not CivilizationSystem.ground_survey_authority.is_valid():return {"valid":false,"reason":"Water and terrain conditions are not surveyed."}
	var ground:Dictionary=CivilizationSystem.ground_survey_authority.call(point)
	if float(ground.get("river_distance_km",INF))>12:return {"valid":false,"reason":"No dependable fresh-water access is established here."}
	var cities:Array=CivilizationSystem.city_intelligence.sites() if actual else CivilizationSystem.city_intelligence.known_cities()
	for site:Dictionary in cities:
		var center:=CivilizationSystem.city_intelligence.vector(site.position)
		var clearance:=8.0
		if actual and String(site.civ_id)!="player":
			var index:int=CivilizationSystem._civilization_index(String(site.civ_id))
			if index>=0:clearance+=float(CivilizationSystem.civilizations[index].logistics)*50
		if center.distance_to(point)<clearance:return {"valid":false,"reason":"The site lies within another settlement's occupied or patrolled territory."}
	return {"valid":true,"reason":"Surveyed land with fresh-water access; territorial conditions are checked again on arrival."}
func seek_site(heading:String,distance:float=32)->Dictionary:
	if data.remnant.is_empty():return {"error":"No escaped group is available."}
	if String(data.remnant.phase)=="escaping":return {"error":"The group must first clear the siege."}
	var start:=CivilizationSystem.city_intelligence.vector(data.remnant.position)
	var angle:=deg_to_rad(float(CivilizationSystem.SCOUT_HEADINGS.get(heading,0)))
	var destination:=start+Vector2(cos(angle),sin(angle))*clampf(distance,8,120)
	# A destination is a possibility, not a remote survey. Conditions are discovered on arrival.
	var route:Dictionary=CivilizationSystem._plan_scout_land_route(start,destination)
	if not bool(route.get("ok",false)):return {"error":String(route.get("reason","No land route reaches the site."))}
	data.remnant.merge({"route":route.route,"distance":float(route.distance_km),"traveled":0.0,"destination":CivilizationSystem.city_intelligence.point(destination),"phase":"seeking_site"},true)
	return {"ok":true,"message":"The group is traveling toward a possible site. It will rebuild only if land, water, territory and remaining supplies permit."}
func _resettle()->Dictionary:
	var remnant:Dictionary=data.remnant;var point:=CivilizationSystem.city_intelligence.vector(remnant.position)
	var eligibility:=assess_site(point,true)
	if not bool(eligibility.get("valid",false)):return {"error":String(eligibility.reason)}
	if float(remnant.food)<float(remnant.people)*3:return {"error":"Fewer than three days of food remain; this group cannot establish a viable settlement."}
	if GameState.player_settlements.size()>=SettlementModel.MAX_PLAYER_SETTLEMENTS:return {"error":"Settlement capacity is full."}
	var sequence:=GameState.next_player_settlement_id;GameState.next_player_settlement_id+=1
	var city:Dictionary={"id":"settlement_%03d" % sequence,"sequence":sequence,"primary":false,"name":"New "+String(remnant.origin_name),"position":point,"population_share":float(remnant.people)/maxf(1,GameState.population_exact),"founded_day":int(GameState.elapsed_days),"status":"established","source_settlement_id":String(remnant.origin_city),"territory_context":{},"environment_profile":{},"auto_manage":true,"management_focus":"establishment","leader_person_id":0,"recovery_capital":true}
	data.remnant={}
	GameState.player_settlements.append(city);SettlementModel._ensure_city_resources(city)
	city.local_resources.resource_stockpiles.Timber=float(remnant.timber)
	SettlementModel.with_city_resources(String(city.id),func()->void:FoodSystem.receive_external_food(float(remnant.food)))
	if home_unavailable():_activate_capital(city)
	data.remnant={}
	GameState.settlement_network_revision+=1
	_record("Survivors established %s. Knowledge and history survive; lost buildings, defenses and stores were not restored." % String(city.name))
	return {"ok":true,"city_id":String(city.id)}
func advance(day:int)->void:
	if int(data.last_day)<0:data.last_day=day-1
	while int(data.last_day)<day:
		data.last_day=int(data.last_day)+1;_day(int(data.last_day))
func _day(day:int)->void:
	for group:Dictionary in [data.preparation,data.remnant]:
		if group.is_empty():continue
		var people:=mini(int(group.people),maxi(0,GameState.population_total-1));group.people=people
		var eaten:=minf(float(group.food),float(people));group.food=maxf(0,float(group.food)-eaten)
		if eaten<people:
			group.mortality_remainder=float(group.mortality_remainder)+people*.01*(1-eaten/maxf(1,people))
			var dead:=mini(people,floori(float(group.mortality_remainder)));group.mortality_remainder=float(group.mortality_remainder)-dead
			var loss:Dictionary=_lose_people(dead,"Deaths among displaced survivors")
			group.people=people-int(loss.get("count",0))
			var remaining_ratio:=float(group.people)/maxf(1,float(people))
			for key in group.cohorts:group.cohorts[key]=float(group.cohorts[key])*remaining_ratio
			var assigned:=0
			for key in group.functions:
				group.functions[key]=floori(float(group.functions[key])*remaining_ratio);assigned+=int(group.functions[key])
			group.functions.productive=int(group.functions.productive)+maxi(0,int(group.people)-assigned)
	if not data.preparation.is_empty() and int(data.preparation.people)<=0:data.preparation={}
	if not data.remnant.is_empty():
		var remnant:Dictionary=data.remnant
		if int(remnant.people)<=0:data.remnant={};_record("The escaped group did not survive.")
		elif String(remnant.phase) in ["escaping","seeking_site"]:
			remnant.traveled=minf(float(remnant.distance),float(remnant.traveled)+8.0)
			var position:Vector2=CivilizationSystem.city_intelligence.route_position(remnant.route,float(remnant.traveled)/maxf(.001,float(remnant.distance)))
			remnant.position=CivilizationSystem.city_intelligence.point(position)
			if float(remnant.traveled)>=float(remnant.distance):
				if String(remnant.phase)=="escaping":remnant.phase="camped";_record("The survivors cleared the siege. Choose a direction to seek a new settlement site.")
				else:
					var result:=_resettle()
					if result.has("error"):remnant.phase="camped";_record(String(result.error))
	for entry:Dictionary in data.occupied:
		if bool(entry.get("liberated",false)):
			if int(entry.get("report_due",-1))>=0 and day>=int(entry.report_due):
				entry.report=entry.region.duplicate(true);entry.reported_liberated=true;entry.last_report_day=day;entry.report_due=-1
				if entry.has("pending_message"):_record(String(entry.pending_message));entry.erase("pending_message")
			continue
		var city_record:=SettlementModel.settlement_record(String(entry.city_id))
		entry.region.population=SettlementModel._settlement_population(city_record)
		var welfare:=float(entry.region.governance.get("welfare",.5))
		var food_report:Dictionary=SettlementModel.with_city_resources(String(entry.city_id),func()->Dictionary:return FoodSystem.process_day({"traveling":false},.3+welfare*.4,.6))
		entry.hunger_loss=float(entry.get("hunger_loss",0))+float(entry.region.population)*.002*maxf(0,.75-float(food_report.get("food_intake_ratio",1)))
		var deaths:=floori(float(entry.hunger_loss))
		if deaths>0:
			_lose_people(deaths,"Hunger deaths under occupation",String(entry.city_id));entry.hunger_loss=float(entry.hunger_loss)-deaths
		if day%30==0:
			var index:int=CivilizationSystem._civilization_index(String(entry.occupier))
			var occupier:Dictionary=CivilizationSystem.civilizations[index] if index>=0 else {}
			entry.region=GOVERNANCE.advance(entry.region,clampf(float(occupier.get("military_population",0))/maxf(1,float(entry.region.population)*.07),0,1),float(occupier.get("logistics",.2)),false)
		if not entry.order.is_empty() and day>=int(entry.order.arrival_day) and not bool(entry.order.get("funded",false)):
			var needed:=float(entry.order.get("food_cost",0))
			var available:float=SettlementModel.with_city_resources(String(entry.city_id),func()->float:return FoodSystem.total_stored())
			if available>=needed:
				SettlementModel.with_city_resources(String(entry.city_id),func()->void:FoodSystem.issue_for_obligation(needed,"resistance","Local recovery effort",30,0))
				entry.order.funded=true
			else:
				entry.order={};entry.pending_message="The effort could not begin: residents lacked the required rations when instructions arrived."
				entry.report_due=day+maxi(1,ceili(SettlementModel._record_position(city_record).distance_to(CivilizationSystem.player_world_origin)/17))
		if not entry.order.is_empty() and day>=int(entry.order.resolve_day) and bool(entry.order.get("funded",false)):_resolve_resistance(entry,day)
		if int(entry.report_due)>=0 and day>=int(entry.report_due):
			entry.report=entry.region.duplicate(true);entry.last_report_day=day;entry.report_due=-1
			entry.reported_liberated=bool(entry.get("liberated",false))
			if entry.has("pending_message"):_record(String(entry.pending_message));entry.erase("pending_message")
func snapshot()->Dictionary:
	var result:=data.duplicate(true)
	for entry:Dictionary in result.occupied:
		if not home_unavailable():
			entry.region=entry.report.duplicate(true)
			entry.liberated=bool(entry.get("reported_liberated",false))
			entry.erase("pending_message")
	return result
func _record(message:String)->void:
	data.history.push_front({"day":int(GameState.elapsed_days),"message":message})
	while data.history.size()>32:data.history.pop_back()
	GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"Survival and independence","description":message,"domain":"institutions","severity":"major"})
static func validate(payload:Dictionary)->Array[String]:
	var errors:Array[String]=[]
	for key in ["preparation","remnant"]:
		if not payload.get(key,{}) is Dictionary:return ["Invalid siege survivor record."]
		var group:Dictionary=payload.get(key,{})
		if group.is_empty():continue
		if int(group.get("people",-1))<0:return ["Invalid survivor count."]
		for field in ["food","timber"]:
			var amount:=float(group.get(field,NAN))
			if not is_finite(amount) or amount<0:errors.append("Invalid survivor supplies.")
	if not payload.get("preparation",{}).is_empty() and not payload.get("remnant",{}).is_empty():errors.append("Two survivor groups cannot own the same population.")
	for key in ["preparation","remnant"]:
		var group:Dictionary=payload.get(key,{})
		if group.is_empty():continue
		for required in ["people","food","timber","cohorts","functions","prepared_day","siege_id","origin_city","origin_name","origin_position","mortality_remainder"]:
			if not group.has(required):errors.append("Incomplete survivor record: "+required)
		if not valid_point(group.get("origin_position")):errors.append("Invalid survivor origin.")
		for table in ["cohorts","functions"]:
			if not group.get(table) is Dictionary:return ["Invalid survivor population profile."]
			for amount in group[table].values():
				if not amount is int and not amount is float:return ["Invalid survivor cohort amount."]
				if not is_finite(float(amount)) or float(amount)<0:errors.append("Invalid survivor cohort amount.")
		if key=="remnant":
			if not valid_route(group.get("route")) or not valid_point(group.get("position")) or not valid_point(group.get("destination")):errors.append("Invalid survivor travel route.")
			if not String(group.get("phase","")) in ["escaping","camped","seeking_site"]:errors.append("Invalid survivor travel phase.")
			for field in ["distance","traveled"]:
				if not is_finite(float(group.get(field,NAN))) or float(group.get(field,-1))<0:errors.append("Invalid survivor travel distance.")
	if not payload.get("occupied",[]) is Array or payload.get("occupied",[]).size()>MAX_OCCUPIED:return ["Invalid occupied-city table."]
	var cities:Dictionary={}
	for entry in payload.get("occupied",[]):
		if not entry is Dictionary:return ["Invalid occupied-city record."]
		for required in ["city_id","occupier","captured_day","region","order","report","report_due","last_report_day","next_order_day"]:
			if not entry.has(required):return ["Incomplete occupied-city record."]
		if String(entry.city_id).is_empty() or cities.has(String(entry.city_id)):errors.append("Invalid occupied-city identity.")
		cities[String(entry.city_id)]=true
		for field in ["region","order","report"]:
			if not entry[field] is Dictionary:return ["Invalid occupied-city state."]
		errors.append_array(GOVERNANCE.validate(entry.region))
		if not entry.order.is_empty():
			if not ORDERS.has(String(entry.order.get("kind",""))) or not entry.order.has_all(["arrival_day","resolve_day","food_cost","funded"]):errors.append("Invalid resistance order.")
	if not payload.get("history",[]) is Array or payload.get("history",[]).size()>32:errors.append("Invalid recovery history.")
	return errors

static func valid_point(value:Variant)->bool:
	if not value is Dictionary:return false
	for axis in ["x","z"]:
		if not value.get(axis) is float and not value.get(axis) is int:return false
		if not is_finite(float(value[axis])):return false
	return true
static func valid_route(value:Variant)->bool:
	if not value is Array or value.is_empty() or value.size()>512:return false
	for point in value:
		if not valid_point(point):return false
	return true

func cancel_preparation()->Dictionary:
	if data.preparation.is_empty():return {"error":"No preparation to cancel."}
	var group:Dictionary=data.preparation
	var city:=SettlementModel.settlement_record(String(group.origin_city))
	if not String(city.get("occupied_by","")).is_empty():return {"error":"These supplies are no longer under your control."}
	SettlementModel.with_city_resources(String(group.origin_city),func()->void:
		FoodSystem.receive_external_food(float(group.food))
		GameState.resource_stockpiles.Timber=float(GameState.resource_stockpiles.get("Timber",0))+float(group.timber)
	)
	data.preparation={}
	return {"ok":true,"message":"The group resumed local work. Unused rations and shelter materials returned to this settlement."}

func held_military()->int:
	var total:=0
	for entry:Dictionary in data.occupied:
		if not bool(entry.get("liberated",false)):total+=maxi(0,int(entry.get("captive_people",0)))
	return total

func _lose_people(count:int,reason:String,city_id:String="")->Dictionary:
	var counts:Dictionary={}
	for city:Dictionary in GameState.player_settlements:
		counts[String(city.id)]=SettlementModel._settlement_population(city)
	var result:=GameState.register_population_deaths(count,reason)
	for city:Dictionary in GameState.player_settlements:
		if not bool(city.get("primary",false)):
			var amount:=float(counts[String(city.id)])-(int(result.get("count",0)) if String(city.id)==city_id else 0)
			city.population_share=maxf(0,amount)/maxf(1,GameState.population_exact)
	return result
