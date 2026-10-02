extends RefCounted
## CAPTURE ONLY (--capture-war): a small, real war for screenshots of the War
## screen. A village of 150, six of them keeping the watch at home, three in
## drill, the army kept at 10% of the people, and one band of twelve under a
## named general marching on a town of a people in blood feud with us. Every
## number is made through the game's own calls (recruit, drill, form a band,
## name a general, the feud); only the band's place on the road and the war
## council's errand are written in, as a march already under way. Never used
## in play.
## "calm" (--capture-war-calm): the early village before any war, 120
## people, four on the watch, two in drill and no band out, at peace.
## "battle" (--capture-war-battle): the war, and the band met on the road by
## a band of theirs: a real battle begins (begin_threat_engagement).

const Commands:=preload("res://scripts/leader_commands.gd")
const WarLoop:=preload("res://scripts/war_loop.gd")

const PEOPLE:=150
const WATCH:=6
const BAND:=12
const DRILL:=3


static func stage(_terrain:Node,mode:="war")->Dictionary:
	if WorldSimulation.direction.needs_century_choice():WorldSimulation.direction.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	if mode=="calm":return _calm()
	if mode=="battle":return _battle(stage(_terrain,"war"))
	GameState.ensure_population_total(PEOPLE)
	GameState.housing_capacity=maxi(GameState.housing_capacity,PEOPLE+PEOPLE/5)
	GameState.elapsed_days=maxf(GameState.elapsed_days,40.0)
	var day:=int(GameState.elapsed_days)
	var mc:Node=MilitaryCampaign
	# The watch at home: six set to defence work, trained and standing there.
	GameState.population_allocations["Defense"]=WATCH
	_train(mc,WATCH+BAND)
	# The band of twelve, under a general the ruler named.
	var made:Dictionary=mc.create_field_army(BAND,"")
	if made.has("error"):
		push_error("war fixture: "+String(made.error))
		return {}
	var army_id:=int(made.army.army_id)
	var general:Dictionary=Commands.commission_general(mc)
	if general.has("figure_id"):Commands.assign(mc,army_id,String(general.figure_id))
	# Three in drill, about two fifths through it.
	mc.military_inventory["improvised"]=int(mc.military_inventory.get("improvised",0))+DRILL
	mc.raise_recruits(DRILL)
	mc.start_training("levy","improvised",DRILL)
	for order in mc.training_queue:
		if order is Dictionary and not bool((order as Dictionary).get("automated_basic",false)):
			(order as Dictionary)["progress_days"]=float((order as Dictionary).get("required_days",45.0))*0.4
	mc.army_levy_level="war"
	# A people in blood feud, whose home our scouts have seen.
	var civ:Dictionary=_nearest_people()
	if civ.is_empty():return {"army_id":army_id}
	var civ_id:=String(civ.id)
	var intel:Variant=WorldSimulation.world.city_intelligence
	# Their first town on the world's record (the capital when it stands);
	# a people still on the move has its capital stand for the capture.
	var founded:=false
	for region in civ.get("strategic_regions",[]):
		if bool((region as Dictionary).get("settlement_founded",true)):founded=true
	if not founded:
		for region in civ.get("strategic_regions",[]):
			if String((region as Dictionary).get("role",""))=="capital":(region as Dictionary)["settlement_founded"]=true
	var site:Dictionary={}
	for place:Dictionary in intel.sites(false):
		if String(place.civ_id)==civ_id and (site.is_empty() or bool(place.get("primary",false))):site=place
	var town_id:=String(site.get("city_id",intel.primary_id(civ_id)))
	var seen:Dictionary=intel.capture("player",town_id,0.7,day-12,"scout","capture fixture")
	if seen.is_empty():
		seen=intel.location_record({"city_id":town_id,"civ_id":civ_id,"name":String(site.get("name","their town")),"position":site.get("position",{"x":0.0,"z":0.0})},day-12,"scout","capture fixture")
	intel.publish("player",seen,day-12)
	var relation:Dictionary=civ.player_relation
	relation.merge({"contact_level":2,"met_day":day-200,"contact_source":"returned_scout_report","home_location_known":true,"home_position":(seen.get("position",{}) as Dictionary).duplicate(true)},true)
	var town:Dictionary=intel.known("player",town_id)
	if town.is_empty():town=seen
	var town_name:=String(town.get("name","their town")).trim_prefix("Reported home of ")
	WarLoop.blood_feud(civ_id,day-30,"the killing of their envoy")
	WarLoop.front(civ_id).merge({"their_dead":4,"our_dead":2,"last_harm":day-9},true)
	var front:Dictionary=WarLoop.front(civ_id)
	front["stance"]="take"
	front["take"]={"city_id":town_id,"name":town_name}
	if general.has("figure_id"):front["general"]=String(general.figure_id)
	# The band on the road to their town, a little under half way.
	var index:int=mc._field_army_index(army_id)
	var band:Dictionary=mc.field_armies[index]
	var home:Vector2=CivilizationSystem.player_world_origin
	var to:Dictionary=town.get("position",{}) if town.get("position") is Dictionary else {}
	var there:=Vector2(float(to.get("x",home.x+60.0)),float(to.get("z",home.y)))
	var at:=home.lerp(there,0.42)
	var total:=home.distance_to(there)
	band.merge({"status":"moving","position":{"x":at.x,"z":at.y},"location_id":"","location_name":"",
		"destination_id":town_id,"destination_name":town_name,"destination_position":{"x":there.x,"z":there.y},
		"distance_total_km":total,"distance_remaining_km":total*0.58,"departure_day":day-6,"arrival_day":day+8,
		"morale":0.64,"provision_ratio":0.82,"supply_level":0.82,
		"council":{"civ":civ_id,"act":"take","name":town_name,"city_id":town_id,"odds":1.6}},true)
	band["last_report"]=mc._army_report_snapshot(band)
	mc.field_armies[index]=band
	return {"army_id":army_id,"civ_id":civ_id,"town":town_name,"general":String(general.get("name","")),"feuds":WarLoop.feuds().size()}


## The war's band met on its road by a band of theirs a little larger, as
## the game's own field contact makes one: the battle begins and is fought.
static func _battle(war:Dictionary)->Dictionary:
	var mc:Node=MilitaryCampaign
	var army_id:=int(war.get("army_id",0))
	var civ_id:=String(war.get("civ_id",""))
	var index:int=mc._field_army_index(army_id)
	if index<0 or civ_id=="":return war
	var band:Dictionary=mc.field_armies[index]
	band["status"]="stationed"
	band["morale"]=0.8
	mc.field_armies[index]=band
	var at:Dictionary=band.position
	var enemy:Dictionary=mc.simulator.create_formation_force("their band",[{"unit":"levy","weapon":"improvised","count":BAND+3,"equipment":0,"training":0.25}],0.7,0.3)
	enemy["commander"]=mc.simulator.create_commander("their war leader",0.5,0.5,0.5,0.5)
	mc.active_threat={"id":"capture-contact","title":"Contact","incident_kind":"campaign","campaign_mode":"offensive","source_civ_id":civ_id,"source_name":WarLoop._name(civ_id),
		"field_encounter":true,"formation_id":"capture","target_region_id":"","target_region_name":"the road","field_army_id":army_id,"enemy_force":enemy,"terrain_defense":1.0,
		"seed":7,"deadline_day":99999,"discovered_day":int(GameState.elapsed_days),"target_position":{"x":float(at.x)+0.2,"z":float(at.z)}}
	var begun:Dictionary=mc.begin_threat_engagement(false)
	war["battle"]=String(begun.get("id",begun.get("error","")))
	return war


## The village before any war: four keep the watch, two drill, the army
## kept at 1% of the people, nobody out.
static func _calm()->Dictionary:
	GameState.ensure_population_total(120)
	GameState.housing_capacity=maxi(GameState.housing_capacity,144)
	GameState.elapsed_days=maxf(GameState.elapsed_days,40.0)
	var mc:Node=MilitaryCampaign
	GameState.population_allocations["Defense"]=4
	_train(mc,4)
	mc.military_inventory["improvised"]=int(mc.military_inventory.get("improvised",0))+2
	mc.raise_recruits(2)
	mc.start_training("levy","improvised",2)
	for order in mc.training_queue:
		if order is Dictionary and not bool((order as Dictionary).get("automated_basic",false)):
			(order as Dictionary)["progress_days"]=float((order as Dictionary).get("required_days",45.0))*0.65
	mc.army_levy_level="few"
	return {"mode":"calm","under_arms":preload("res://scripts/army_levy_law.gd").under_arms(mc)}


## Recruit, arm and drill `count` levy at home, as the court's levy would.
static func _train(mc:Node,count:int)->void:
	mc.military_inventory["improvised"]=int(mc.military_inventory.get("improvised",0))+count
	mc.raise_recruits(count)
	mc.start_training("levy","improvised",count)
	mc._complete_training(mc.training_queue[mc.training_queue.size()-1].duplicate(true))
	mc.training_queue.remove_at(mc.training_queue.size()-1)


## The living people nearest our home.
static func _nearest_people()->Dictionary:
	var home:Vector2=CivilizationSystem.player_world_origin
	var best:Dictionary={}
	var near:=INF
	for civ:Dictionary in CivilizationSystem.civilizations:
		if not bool(civ.get("alive",true)):continue
		var at:Variant=civ.get("world_position",null)
		var d:float=home.distance_to(at) if at is Vector2 else 1e9
		if best.is_empty() or d<near:
			best=civ
			near=d
	return best
