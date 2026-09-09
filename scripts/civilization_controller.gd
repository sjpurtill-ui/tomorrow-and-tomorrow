extends RefCounted
## Only decisions live here. All population, equipment and technology changes
## must be accepted and paid for by the ordinary commands and simulation.
static func choose_orders(id:String)->void:
	if String(WorldSimulation.actors[id].controller)!="ai":return
	var day:=int(WorldSimulation.state.elapsed_days)
	if WorldSimulation.direction.needs_century_choice():
		var options:Array=WorldSimulation.direction.AMBITIONS.keys()
		WorldSimulation.submit(id,{"kind":"ambition","id":options[posmod(hash(id),options.size())]})
	if not WorldSimulation.state.settlement_site_committed:
		if WorldSimulation.state.convoy_traveling:return
		var founded:=WorldSimulation.submit(id,{"kind":"found"})
		if founded.has("error"):
			var home:=WorldSimulation.world.player_world_origin
			for distance:float in [2,5,10,20,40]:
				for spoke in 12:
					var destination:=home+Vector2.from_angle(TAU*float(spoke)/12)*distance
					if not WorldSimulation.world._position_is_revealed(destination):continue
					var known:=preload("res://scripts/civilization_day.gd").context(destination)
					if not bool(WorldSimulation.resources.water_access_snapshot(known).accessible):continue
					if not WorldSimulation.submit(id,{"kind":"move","destination":destination}).has("error"):return
		return
	if day%30!=0:return
	military_orders(id)
	foreign_orders(id)
	if bool(WorldSimulation.state.settlement_convoy.get("active",false)):return
	if "Hearth Circle" not in WorldSimulation.state.settlement_completed:return
	var home:=WorldSimulation.world.player_world_origin
	# Evaluate candidates only inside returned knowledge. Duration, founders,
	# supplies, and land/water checks belong to the same founding transaction.
	var best:Dictionary={};var best_value:=-INF
	for index in 16:
		var point:=home+Vector2.from_angle(TAU*float(index)/16.0)*24.0
		if not bool(WorldSimulation.settlements.known_land_assessment(point).known):continue
		var quote:=WorldSimulation.settlements.settlement_convoy_quote(point,0)
		if not bool(quote.get("ok",false)):continue
		var context:=preload("res://scripts/civilization_day.gd").context(point)
		if not bool(WorldSimulation.resources.water_access_snapshot(context).accessible):continue
		var value:=float(context.environment_profile.get("food_potential",0))
		if value>best_value:best={"kind":"settle","destination":point};best_value=value
	if not best.is_empty():WorldSimulation.submit(id,best)

static func military_orders(id:String)->void:
	var campaign:=WorldSimulation.military
	var war:=false
	for civ in WorldSimulation.world.civilizations:war=war or bool(civ.player_relation.get("at_war",false))
	var food_days:=float(WorldSimulation.state.simulation_metrics.get("food_days",0))
	var policy:="suspended" if food_days<15 else ("maintain" if war else "regular")
	for service in ["army","navy","air"]:WorldSimulation.submit(id,{"kind":"training_policy","service":service,"policy":policy})
	var capacity:=campaign.recruitment_capacity()
	var target:=mini(capacity,roundi(WorldSimulation.state.population_exact*(.14 if war else .06)))
	var vacancies:=maxi(0,target-campaign._mobilized_count())
	if vacancies>0:WorldSimulation.submit(id,{"kind":"recruit","count":vacancies})
	var chosen:="levy";var weapon:="improvised";var score:=-1.0
	for unit:String in campaign.UnitCatalog.ARCHETYPES:
		var definition:Dictionary=campaign.UnitCatalog.ARCHETYPES[unit]
		for item in definition.equipment:
			if campaign._training_gate(unit,String(item)).has("error"):continue
			var value:=float(definition.training_days)
			if value>score:chosen=unit;weapon=String(item);score=value
	ensure_line(id,weapon,maxi(4,target))
	if campaign.aggregate_recruits>0:WorldSimulation.submit(id,{"kind":"train","unit":chosen,"weapon":weapon,"count":campaign.aggregate_recruits})
	if campaign.field_armies.is_empty() and int(campaign.home_army.get("troops",0))>=4:
		WorldSimulation.submit(id,{"kind":"deploy","count":maxi(4,roundi(float(campaign.home_army.troops)*.6))})
	campaign.command_hierarchy.sync()
	if campaign.command_hierarchy.data.zones.is_empty() and not campaign.field_armies.is_empty():
		var zone:=WorldSimulation.submit(id,{"kind":"area","service":"army","name":"Home defense","vertices":campaign.command_hierarchy.R.rectangle(WorldSimulation.world.player_world_origin,8.0)})
		if zone.has("region"):WorldSimulation.submit(id,{"kind":"objective","command":"army","region":zone.region,"mission":"defend","vision":"Protect the settlement and its approaches."})
	for service in ["navy","air"]:
		if WorldSimulation.state.player_settlements.is_empty():continue
		var city:=String(WorldSimulation.state.player_settlements[0].id)
		if not campaign.joint_operations.available_base(service):WorldSimulation.submit(id,{"kind":"base","city":city,"service":service})
		for base:Dictionary in campaign.joint_operations.state.bases:
			if base.domain!=service or not campaign.joint_operations.base_ready(base):continue
			var candidate:="";var work:=-1.0
			for unit:String in campaign.joint_operations.C.UNITS:
				var definition:Dictionary=campaign.joint_operations.C.UNITS[unit]
				if definition.domain!=service or not bool(campaign._knowledge_gate(String(definition.gate),.10).unlocked):continue
				if int(definition.crew)>maxi(0,capacity-campaign._mobilized_count()):continue
				if float(definition.work_days)>work:candidate=unit;work=float(definition.work_days)
			if candidate=="":continue
			var equipment:=String(campaign.joint_operations.C.UNITS[candidate].equipment)
			ensure_line(id,equipment,1)
			WorldSimulation.submit(id,{"kind":"commission","base":int(base.id),"unit":candidate,"count":1})
	service_orders(id)

static func ensure_line(id:String,item:String,target:int)->void:
	for job in WorldSimulation.military.equipment_queue:
		if String(job.get("item",""))==item:return
	WorldSimulation.submit(id,{"kind":"production","item":item,"target":target})

static func foreign_orders(id:String)->void:
	var world:=WorldSimulation.world
	var food_days:=float(WorldSimulation.state.simulation_metrics.get("food_days",0))
	if world.scout_missions.is_empty() and food_days>20:
		WorldSimulation.submit(id,{"kind":"scout","days":30,"target":"open_world"})
	if not world.diplomatic_mission.is_empty():return
	for civ in world.civilizations:
		if int(civ.player_relation.get("contact_level",0))<2:continue
		var opinion:=float(civ.player_relation.get("opinion",0))
		var action:=""
		if bool(civ.player_relation.get("at_war",false)):
			if food_days<15:action="seek_peace"
			else:
				var reports:Array=world.city_intelligence.known_cities("player",String(civ.id),false)
				if not reports.is_empty() and WorldSimulation.military.command_hierarchy.order_for("army").get("target","")!=String(reports[0].city_id):
					var place:Dictionary=reports[0]
					var point:Vector2=world.city_intelligence.vector(place.position)
					var region:=WorldSimulation.submit(id,{"kind":"area","service":"army","name":"Campaign objective","vertices":WorldSimulation.military.command_hierarchy.R.rectangle(point,8)})
					if region.has("region"):WorldSimulation.submit(id,{"kind":"objective","command":"army","region":region.region,"mission":"occupy","target":place.city_id,"vision":"Take and hold the enemy settlement; preserve the army."})
		elif opinion<-.5 and food_days>30:action="declare_war"
		elif opinion>.15 and String(civ.player_relation.get("treaty","none"))=="none":action="open_trade"
		if action!="":WorldSimulation.submit(id,{"kind":"diplomacy","target":String(civ.id),"action":action});return

static func service_orders(id:String)->void:
	var op=WorldSimulation.military.joint_operations
	for force:Dictionary in op.state.forces:
		if force.owner!="player" or not force.region.is_empty():continue
		var base:Dictionary=op.base(int(force.base_id))
		if base.is_empty():continue
		var at:Vector2=op.point(base)
		var missions:Array=op.missions_for(force)
		var mission:="patrol" if force.domain=="navy" else "reconnaissance"
		if mission not in missions:
			mission="air_superiority" if "air_superiority" in missions else ""
		if mission=="":continue
		for spoke in 8:
			var center:=at+Vector2.from_angle(TAU*spoke/8.0)*20
			if force.domain=="navy" and op.geography.is_land(center):continue
			var created:Dictionary=op.create_region(String(force.domain),op.R.rectangle(center,20),"Home approaches")
			if created.has("error"):continue
			var response:=WorldSimulation.submit(id,{"kind":"service_mission","force":int(force.id),"region":created.region,"mission":mission})
			if not response.has("error"):break
			op.remove_region(String(created.region.id))
