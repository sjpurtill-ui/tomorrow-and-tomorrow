extends RefCounted
## Objective execution on the ordinary campaign clock and physical terrain.
## Fronts are contact between real forces, never the outline the player drew.
const R=preload("res://scripts/joint_regions.gd")
const G=preload("res://scripts/joint_geography.gd")
var _command:WeakRef
var command:RefCounted:
	get:return _command.get_ref()
var host:Node
var claims:Array[Dictionary]=[]
var route_cache:Dictionary={}
func _init(owner:RefCounted)->void:_command=weakref(owner);host=owner.host
func clear_cache()->void:route_cache.clear();claims.clear()
func point(force:Dictionary)->Vector2:return G.unpack(force.get("position",G.pack(WorldSimulation.world.player_world_origin)))
func is_land(at:Vector2)->bool:
	return WorldSimulation.world.scout_land_authority.is_valid() and WorldSimulation.world._scout_land_at(at)
func rally(region:Dictionary)->Dictionary:
	var center:=R.bounds(region).get_center()
	if R.contains(region,center) and is_land(center) and WorldSimulation.world._position_is_revealed(center):return G.pack(center)
	var box:=R.bounds(region)
	for x in 12:
		for y in 12:
			var at:=box.position+box.size*Vector2((x+.5)/12.0,(y+.5)/12.0)
			if R.contains(region,at) and is_land(at) and WorldSimulation.world._position_is_revealed(at):return G.pack(at)
	return {}
func refresh_claims()->void:
	claims.clear()
	for entry:Dictionary in WorldSimulation.settlements.territory_control_snapshot().settlement_claims:
		var owner:=String(entry.controller)
		claims.append({"owner":"player" if owner=="" else owner,"city_id":entry.id,"position":entry.position,"boundary":entry.boundary})
	# Use the same population/terrain-driven claim geometry as domestic cities.
	for site:Dictionary in WorldSimulation.world.city_intelligence.sites(false):
		var location:Dictionary=WorldSimulation.world._region_location(String(site.city_id))
		if location.is_empty():continue
		var civ:Dictionary=WorldSimulation.world.civilizations[int(location.owner_index)]
		var region:Dictionary=civ.strategic_regions[int(location.region_index)]
		if WorldSimulation.enabled:
			claims.append({"owner":String(region.controller),"city_id":site.city_id,"position":G.unpack(site.position),"boundary":region.get("boundary",PackedVector2Array())})
			continue
		var record:Dictionary={"id":site.city_id,"position":G.unpack(site.position),"primary":site.primary,"status":"established","territory_context":{}}
		var reach:=.65+float(civ.get("logistics",.2))*.25+float(civ.get("institutions",.2))*.2
		var radius:=clampf(sqrt(maxf(.12,float(region.population)/72.0*reach*reach)/PI),.32,4600.0)
		claims.append({"owner":String(region.controller),"city_id":site.city_id,"position":record.position,"boundary":WorldSimulation.settlements._claim_boundary(record,radius)})
func territory(at:Vector2)->Dictionary:
	for claim:Dictionary in claims:
		if Geometry2D.is_point_in_polygon(at,claim.boundary):return claim
	return {}
func hostile(owner:String)->bool:return host.joint_operations._hostile("player",owner)
func strength(actual:Dictionary)->float:
	var equipped:=0.0
	for formation:Dictionary in actual.get("formations",[]):
		var count:=maxi(0,int(formation.get("count",0)))
		var gear:=minf(1,float(formation.get("equipment",0))/maxf(1,float(formation.get("equipment_required",count))))
		equipped+=count*(.2+.8*gear)*(.35+.65*float(formation.get("training",.3)))*float(formation.get("personnel_condition",1))
	return equipped*(.25+.75*float(actual.get("supply_level",.5)))*(.4+.6*float(actual.get("morale",.7)))
func frontage(troops:int)->float:
	# A tiny squad cannot seal kilometres of ground. Later communications and
	# equipment improve execution through existing readiness and movement rates.
	return clampf(sqrt(maxf(0,troops))*.085,.12,10.0)
func enemies(day:int,only_hostile:bool=true)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for formation:Dictionary in WorldSimulation.world.foreign_formations:
		if formation.get("kind","")=="scout" or day<int(formation.get("disabled_until_day",0)) or (only_hostile and not hostile(String(formation.civ_id))):continue
		var index:int=WorldSimulation.world._civilization_index(String(formation.civ_id))
		if index<0:continue
		var civ:Dictionary=WorldSimulation.world.civilizations[index]
		var land_personnel:float=WorldSimulation.world.land_military_population(civ)
		var count:=int(formation.get("actual_troops",maxi(1,roundi(land_personnel*float(formation.get("strength_share",.05)))) if land_personnel>=1 else 0))
		if count<=0:continue
		result.append({"id":formation.id,"owner":formation.civ_id,"position":G.pack(WorldSimulation.world._foreign_formation_position(formation,float(day))),"troops":count,"strength":count*(.35+.65*float(formation.get("readiness",.4))),"record":formation})
	return result
func _known_enemies(day:int)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for enemy:Dictionary in enemies(day):
		if not WorldSimulation.world.visible_formation_sighting(String(enemy.id)).is_empty():result.append(enemy)
	return result
func route(start:Vector2,goal:Vector2)->Array:
	if not is_land(start) or not is_land(goal):return []
	if not host.field_route_availability(start,goal).has("error"):return [G.pack(goal)]
	var step:=clampf(start.distance_to(goal)/24.0,.25,5.0)
	var key:=str(WorldSimulation.state.world_seed)+str(start.snapped(Vector2.ONE*.1))+str(goal.snapped(Vector2.ONE*.1))
	if route_cache.has(key):
		var valid:=true;var previous:=start
		for waypoint:Dictionary in route_cache[key]:
			var next:=G.unpack(waypoint)
			if host.field_route_availability(previous,next).has("error"):valid=false;break
			previous=next
		if valid:return route_cache[key].duplicate(true)
		route_cache.erase(key)
	# Bounded A* around the direct route. Every edge is checked for water;
	# diagonals cannot cut across a coastline or river mouth.
	var open:Array[Vector2i]=[Vector2i.ZERO];var cost:Dictionary={Vector2i.ZERO:0.0};var previous:Dictionary={}
	var target:=Vector2i((goal-start)/step);var finish:=Vector2i.ZERO;var found:=false
	var visited:=0
	while not open.is_empty() and visited<1600:
		var best:=0;var score:=INF
		for index in open.size():
			var value:=float(cost[open[index]])+Vector2(open[index]).distance_to(Vector2(target))
			if value<score:score=value;best=index
		var cell:Vector2i=open.pop_at(best);visited+=1
		var at:=start+Vector2(cell)*step
		if at.distance_to(goal)<=step*1.5 and not host.field_route_availability(at,goal).has("error"):finish=cell;found=true;break
		for offset:Vector2i in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]:
			var next:=cell+offset
			if absi(next.x)>abs(target.x)+20 or absi(next.y)>abs(target.y)+20:continue
			var next_at:=start+Vector2(next)*step
			var next_cost:=float(cost[cell])+Vector2(offset).length()
			if cost.has(next) and float(cost[next])<=next_cost:continue
			if host.field_route_availability(at,next_at).has("error"):continue
			cost[next]=next_cost;previous[next]=cell
			if not next in open:open.append(next)
	var result:Array=[]
	if found:
		result.append(G.pack(goal))
		while finish!=Vector2i.ZERO:result.push_front(G.pack(start+Vector2(finish)*step));finish=previous[finish]
	if route_cache.size()>=24:route_cache.clear()
	if not result.is_empty():route_cache[key]=result.duplicate(true)
	return result
func _respond_rivals(day:int)->void:
	if WorldSimulation.enabled:return # Their own leaders move their real formations.
	# Existing patrol/expedition personnel leave their physical position to meet
	# incursions. This changes their route, not their nation's manpower ledger.
	for enemy:Dictionary in enemies(day,false):
		var record:Dictionary=enemy.record
		if not hostile(String(enemy.owner)) and not record.has("command_position"):continue
		if int(record.get("command_response_day",-1))>=day or command.battle.enemy_engaged(String(enemy.id)):continue
		var current:=point(enemy);var target:=current;var closest:=INF
		for actual:Dictionary in host.field_armies:
			if not hostile(String(enemy.owner)) or int(actual.get("troops",0))<=0 or bool(actual.get("embarked",false)):continue
			var at:=point(actual);var distance:=at.distance_to(current)
			if distance>16 or distance>=closest:continue
			closest=distance;target=at
		if closest==INF:
			if not record.has("command_position"):continue
			target=Vector2(record.get("point_a",current))
			if current.distance_to(target)<.2:record.erase("command_position");record.depart_day=day;continue
		record["command_response_day"]=day
		var width:=frontage(int(enemy.troops))
		if current.distance_to(target)<=width+.2:continue
		var destination:=target+(current-target).normalized()*(width+.2)
		var path:=route(current,destination)
		if path.is_empty():continue
		var budget:=18.0*(.5+.5*float(record.get("readiness",.4)))
		for waypoint:Dictionary in path:
			var next:=G.unpack(waypoint);var leg:=current.distance_to(next);var move:=minf(budget,leg)
			current=current.move_toward(next,move);budget-=move
			if budget<=.001:break
		record["command_position"]=G.pack(current)
func _encirclement(enemy:Dictionary,allies:Array)->float:
	# Sample possible retreat directions; every direction must actually be
	# covered by a supplied, sufficiently strong friendly frontage.
	var covered:=0
	var radius:=maxf(.8,frontage(int(enemy.troops))*1.8)
	for index in 24:
		var escape:=point(enemy)+Vector2.from_angle(TAU*index/24.0)*radius
		for ally:Dictionary in allies:
			if float(ally.get("supply_level",0))<.35 or strength(ally)<float(enemy.strength)/12.0:continue
			if point(ally).distance_to(escape)<=frontage(int(ally.get("troops",0))):covered+=1;break
	return covered/24.0
func _move(actual:Dictionary,destination:Vector2,order:Dictionary,day:int)->void:
	var start:=point(actual)
	if start.distance_to(destination)<.08:actual["status"]="stationed";return
	var path:=route(start,destination)
	if order.get("mission","")=="encircle":
		for enemy:Dictionary in _known_enemies(day):
			var radius:=frontage(int(actual.troops))+frontage(int(enemy.troops))+.3
			if point(enemy).distance_to(Geometry2D.get_closest_point_to_segment(point(enemy),start,destination))>=radius or start.distance_to(point(enemy))>radius*4:continue
			var angle:=(start-point(enemy)).angle();var target_angle:=(destination-point(enemy)).angle()
			var next_angle:=angle+clampf(angle_difference(angle,target_angle),-PI/4,PI/4)
			var flank:=point(enemy)+Vector2.from_angle(next_angle)*maxf(radius,start.distance_to(point(enemy)))
			var region:Dictionary=command.zone(String(order.get("zone_id","")))
			if R.contains(region,flank) and is_land(flank):path=route(start,flank)
			break
	if path.is_empty():actual["command_status"]="No land route · commander needs another approach";actual["command_route"]=[];return
	actual["command_route"]=path
	var budget:float=host._field_army_speed(actual)
	var current:=start
	for waypoint:Dictionary in path:
		var next:=G.unpack(waypoint)
		while current.distance_to(next)>.01 and budget>.001:
			var distance:=minf(.25,minf(budget,current.distance_to(next)))
			var proposed:=current.move_toward(next,distance)
			var claim:=territory(proposed)
			if not claim.is_empty() and claim.owner!="player" and not hostile(String(claim.owner)):
				var city:Dictionary=WorldSimulation.world.city_intelligence.known("player",String(order.get("target","")))
				if not city.is_empty() and String(city.get("civ_id",""))==String(claim.owner) and order.mission in ["capture","occupy","raze"]:
					WorldSimulation.world.record_player_hostile_order(String(claim.owner),String(claim.city_id),"A commanded offensive crossed the defended city border.")
				else:actual["command_status"]="Holding at neutral border · no authority to invade";budget=0;break
			var blocked:=false
			for enemy:Dictionary in enemies(day):
				var width:=frontage(int(actual.get("troops",0)))+frontage(int(enemy.troops))
				if proposed.distance_to(point(enemy))<width and proposed.distance_to(point(enemy))<current.distance_to(point(enemy)) and strength(actual)<float(enemy.strength)*1.15:
					actual["command_status"]="Front contested · protecting flanks and awaiting support";blocked=true;break
			if blocked:budget=0;break
			current=proposed;budget-=distance
		if budget<=.001:break
	actual["position"]=G.pack(current);actual["status"]="stationed";actual["location_id"]="field_position"
	actual["location_name"]="Commanded ground";actual["distance_remaining_km"]=current.distance_to(destination)
	actual["destination_position"]=G.pack(destination);actual["destination_id"]=""
	actual["supply_level"]=clampf(float(actual.get("supply_level",1))-.0008*current.distance_to(start),.0,1)
	if current.distance_to(WorldSimulation.world.player_world_origin)<.5:actual["location_id"]="player_home";actual["location_name"]="Home settlement"
func _engage(actual:Dictionary,enemy:Dictionary,order:Dictionary,allies:Array)->void:
	if command.battle.enemy_engaged(String(enemy.id)) or command.data.battles.size()>=32:return
	if not host.active_engagement.is_empty() or not host.active_siege.is_empty() or not host.active_threat.is_empty() or not host.pending_aftermath.is_empty():return
	var distance:=point(actual).distance_to(point(enemy))
	var width:=minf(host.MAP_ENGAGEMENT_RANGE_KM,frontage(int(actual.troops))+frontage(int(enemy.troops))+.15)
	if distance>width+.5:return
	var nearby:Array=command.battle.participants(actual,allies,point(enemy))
	var combined:=0.0
	for ally:Dictionary in nearby:combined+=strength(ally)
	var ratio:=combined/maxf(1,float(enemy.strength))
	var enclosed:=_encirclement(enemy,allies)
	if order.mission=="encircle" and enclosed<.95 and allies.size()>=3 and distance>width*.6:return
	command.executing=true;command.battle_candidates=nearby
	var result:Dictionary=host.launch_map_engagement(int(actual.army_id),String(enemy.id))
	command.executing=false;command.battle_candidates=[]
	if result.has("error"):actual["command_status"]=String(result.error);return
	if not host.active_engagement.is_empty():
		host.active_engagement["commander_managed"]=true;host.active_engagement["command_objective"]=order.mission
		host.active_engagement["encirclement"]=enclosed
		if enclosed>=.95:
			var side:String=host._engagement_enemy_side(host.active_engagement)
			host.active_engagement[side]["supply_level"]=minf(float(host.active_engagement[side].get("supply_level",1)),1.0-enclosed*.65)
		actual["command_status"]="Engaging · escape routes cut" if enclosed>=.95 else "Engaging enemy front"
		command.battle.archive_active()
func advance(day:int)->void:
	var has_orders:=false
	for actual:Dictionary in host.field_armies:
		if command.controls_army(int(actual.army_id)):has_orders=true;break
	if not has_orders:command.data.fronts=[];_respond_rivals(day);return
	for record:Dictionary in command.leaves("army"):
		var directive:Dictionary=command.order_for(String(record.id))
		if directive.get("mission","")=="encircle" and not bool(record.get("maneuver_organized",false)) and command.amount(record)>12 and int(record.force_id)>0:
			if command._busy(record)=="" and host.field_armies.size()+6<command.MAX_LAND_FORCES and command.data.nodes.size()+6<command.MAX_NODES:
				var split:Dictionary=command._split(String(record.id))
				if split.has("ok"):
					for child:Dictionary in split.children:child["maneuver_organized"]=true
	refresh_claims();_respond_rivals(day)
	WorldSimulation.world._process_local_observation(day,true)
	var groups:Dictionary={}
	for record:Dictionary in command.leaves("army"):
		var actual:Dictionary=command.force(record);var order:Dictionary=command.order_for(String(record.id))
		if actual.is_empty() or int(record.force_id)<=0 or order.is_empty() or order.get("mission","")=="cancelled":continue
		var key:=String(order.get("zone_id",""))+":"+str(order.get("target",""))+":"+String(order.mission)
		if not groups.has(key):groups[key]=[]
		groups[key].append({"actual":actual,"order":order,"node":record})
	var known:=_known_enemies(day)
	for group:Array in groups.values():
		var allies:Array=[]
		for item:Dictionary in group:allies.append(item.actual)
		for index in group.size():
			var item:Dictionary=group[index];var actual:Dictionary=item.actual;var order:Dictionary=item.order
			if int(actual.get("troops",0))<=0 or bool(actual.get("embarked",false)):continue
			if WorldSimulation.campaign.active and int(actual.army_id)==int(WorldSimulation.campaign.state.get("army_id",-1)):continue
			if not host.active_siege.is_empty() and int(actual.army_id) in host.active_siege.get("command_members",[int(host.active_siege.get("army_id",0))]):
				if order.mission=="withdraw" and int(actual.army_id)==int(host.active_siege.army_id):host.siege_order(String(host.active_siege.id),"withdraw")
				else:actual["command_status"]="Investing city · siege staff executing";continue
			if command.battle.engaged(int(actual.army_id)):continue
			var region:Dictionary=command.zone(String(order.get("zone_id","")))
			var destination:=rally(region) if not region.is_empty() else {}
			if order.mission=="withdraw":destination=G.pack(WorldSimulation.world.player_world_origin)
			if destination.is_empty():actual["command_status"]="No charted assembly ground · awaiting reconnaissance";continue
			actual["command_status"]="Assembling in zone" if not R.contains(region,point(actual)) else "Patrolling assigned ground"
			var supply:=float(actual.get("supply_level",0))
			if supply<.2 or float(actual.get("morale",1))<.22 or day<int(actual.get("command_recover_until",0)):
				actual["command_status"]="Commander withdrawing to recover supply and morale";_move(actual,WorldSimulation.world.player_world_origin,{"mission":"withdraw"},day);continue
			var target:Dictionary={};var nearest:=INF
			for enemy:Dictionary in known:
				if not R.contains(region,point(enemy)) or order.mission=="withdraw":continue
				var distance:=point(enemy).distance_to(point(actual))
				if distance<nearest:nearest=distance;target=enemy
			if not target.is_empty():
				var ratio:=strength(actual)/maxf(1,float(target.strength))
				if order.mission=="defend":
					destination=G.pack(point(target)+(point(actual)-point(target)).normalized()*(frontage(int(actual.troops))+frontage(int(target.troops))))
				elif order.mission=="encircle" and _encirclement(target,allies)<.95 and group.size()>=3:
					var radius:=maxf(.8,maxf(frontage(int(target.troops))*1.8,frontage(int(actual.troops))+frontage(int(target.troops))+.25))
					var at:=point(target)+Vector2.from_angle(TAU*index/group.size())*radius
					if R.contains(region,at) and is_land(at):destination=G.pack(at);actual["command_status"]="Maneuvering to close escape routes"
					else:destination=target.position;actual["command_status"]="Flank blocked by terrain / zone edge · probing front"
				else:destination=target.position;actual["command_status"]="Pressing enemy front" if ratio>=1.15 else "Holding contact and seeking support"
				_engage(actual,target,order,allies)
				if command.battle.engaged(int(actual.army_id)):continue
			elif order.mission in ["capture","occupy","raze"]:
				var city:Dictionary=WorldSimulation.world.city_intelligence.known("player",String(order.get("target","")))
				if city.is_empty():actual["command_status"]="City report unavailable · awaiting reconnaissance";continue
				destination=city.position
				if point(actual).distance_to(G.unpack(destination))<=.5:
					_city(actual,city,order,day,allies);continue
			elif order.mission in ["encircle","defeat"] and R.contains(region,point(actual)):actual["command_status"]="Searching zone · no observed enemy army"
			_move(actual,G.unpack(destination),order,day)
			if host._army_is_home(actual) or host._live_army_reporting():actual["last_report"]=host._army_report_snapshot(actual)
	_build_fronts(day)
func _city(actual:Dictionary,city:Dictionary,order:Dictionary,day:int,allies:Array=[])->void:
	if command.battle.city_engaged(String(city.city_id)) or command.data.battles.size()>=32:
		actual["command_status"]="Holding city approaches · another command is assaulting";return
	var location:Dictionary=WorldSimulation.world._region_location(String(city.city_id))
	if location.is_empty():actual["command_status"]="City ownership unavailable";return
	var region:Dictionary=WorldSimulation.world.civilizations[int(location.owner_index)].strategic_regions[int(location.region_index)]
	if String(region.controller)=="player":
		actual["location_id"]=String(city.city_id);actual["command_status"]="Holding occupied city"
		var control:Dictionary=WorldSimulation.world.occupation_control(String(city.civ_id),String(city.city_id),order.mission=="raze")
		if control.has("required") and not bool(control.get("controlled",false)):
			var garrison:Dictionary=host.occupation_force_for_region(String(city.civ_id),String(city.city_id))
			if garrison.is_empty():host.establish_occupation_force(String(city.civ_id),region,float(control.required),int(actual.army_id))
			else:command.battle.reinforce_occupation(String(city.civ_id),String(city.city_id),[{"army_id":int(actual.army_id)}],float(control.required))
		if order.mission=="raze" and not bool(region.get("governance",{}).get("ruined",false)):
			var result:Dictionary=WorldSimulation.world.set_occupation_policy(String(city.civ_id),String(city.city_id),"raze")
			actual["command_status"]=String(result.get("error","City infrastructure razed · occupation retained"))
		return
	if not host.active_engagement.is_empty() or not host.active_siege.is_empty() or not host.active_threat.is_empty() or not host.pending_aftermath.is_empty():actual["command_status"]="Holding approach · another engagement is resolving";return
	actual["status"]="stationed";actual["location_id"]=String(city.city_id)
	command.executing=true;command.battle_candidates=command.battle.participants(actual,allies,G.unpack(city.position))
	var result:Dictionary=host.order_city_operation(int(actual.army_id),String(city.civ_id),String(city.city_id),order.mission=="occupy")
	command.executing=false;command.battle_candidates=[]
	actual["command_status"]=String(result.get("error","Commander attacking city defenses"))
	if not host.active_engagement.is_empty():
		host.active_engagement["commander_managed"]=true;host.active_engagement["command_objective"]=order.mission
		command.battle.archive_active()
	if not host.active_siege.is_empty() and int(host.active_siege.get("army_id",0))==int(actual.army_id):
		host.active_siege["commander_managed"]=true
		host.active_siege["command_members"]=[]
		for member:Dictionary in command.battle.participants(actual,allies,G.unpack(city.position)):host.active_siege.command_members.append(int(member.army_id))
func battle_order()->String:
	var engagement:Dictionary=host.active_engagement
	var side:String=host._engagement_home_side(engagement);var enemy:String=host._engagement_enemy_side(engagement)
	var actual:Dictionary=engagement[side];var rival:Dictionary=engagement[enemy]
	if float(actual.get("morale",1))<.25 or float(actual.get("supply_level",1))<.15 or int(actual.troops)<int(engagement.get(side+"_initial",actual.troops))*.45:return "retreat"
	return "push" if strength(actual)>strength(rival)*1.25 or float(engagement.get("encirclement",0))>=.95 else "hold"
func _build_fronts(day:int)->void:
	var fronts:Array=[]
	for region:Dictionary in command.data.zones:
		var allies:Array=[]
		for leaf:Dictionary in command.leaves("army"):
			if command.order_for(String(leaf.id)).get("zone_id","")==region.id and int(leaf.force_id)>0:allies.append(command.force(leaf))
		for enemy:Dictionary in _known_enemies(day):
			if not R.contains(region,point(enemy)):continue
			for actual:Dictionary in allies:
				if int(actual.get("troops",0))<=0:continue
				var own_width:=frontage(int(actual.troops));var enemy_width:=frontage(int(enemy.troops));var distance:=point(actual).distance_to(point(enemy))
				if distance>own_width+enemy_width+1.0:continue
				var center:=point(actual).lerp(point(enemy),own_width/maxf(.01,own_width+enemy_width))
				var perpendicular:=(point(enemy)-point(actual)).normalized().orthogonal()*minf(own_width,enemy_width)
				fronts.append({"zone_id":region.id,"army_id":actual.army_id,"enemy_id":enemy.id,"day":day,"points":[G.pack(center-perpendicular),G.pack(center),G.pack(center+perpendicular)],"encirclement":_encirclement(enemy,allies),"status":"Contested front"})
				if fronts.size()>=256:command.data.fronts=fronts;return
	command.data.fronts=fronts
