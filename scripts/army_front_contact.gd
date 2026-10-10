extends RefCounted
## Marches and staff orders meet the same physical front. No troop ledger:
## contact opens the existing reserved battle, at the ground actually met.
const Defense:=preload("res://scripts/border_defense.gd")
const Lines:=preload("res://scripts/army_lines.gd")

static func enemies(host:Node,army:Dictionary)->Array:
	var result:Array=[]
	var intended:=String((army.get("city_operation",{}) as Dictionary).get("civ_id",""))
	var intercept:=String(army.get("target_formation_id",""))
	for enemy:Dictionary in host.command_hierarchy.land.enemies(int(WorldSimulation.state.elapsed_days),false):
		if host.command_hierarchy.land.hostile(String(enemy.owner)) or String(enemy.owner)==intended or String(enemy.id)==intercept:
			result.append(enemy)
	return result

## Sweep each profiled road leg, not the chord between the day's endpoints.
## Effort and kilometres stop at precisely the first contact along that road.
static func sweep(host:Node,army:Dictionary,origin:Vector2,packed:Array,before:float,after:float)->Dictionary:
	var foes:=enemies(host,army)
	if foes.is_empty():return {}
	var previous:=origin;var previous_effort:=0.0;var kilometres:=0.0
	for row:Dictionary in packed:
		var point:=Vector2(float(row.x),float(row.z));var effort:=float(row.e)
		var length:=previous.distance_to(point)
		if effort>=before and previous_effort<=after and effort>previous_effort:
			var low:=clampf((before-previous_effort)/(effort-previous_effort),0.0,1.0)
			var high:=clampf((after-previous_effort)/(effort-previous_effort),0.0,1.0)
			var hit:=Defense.first_contact(previous.lerp(point,low),previous.lerp(point,high),foes,army)
			if not hit.is_empty():
				var fraction:=lerpf(low,high,float(hit.t))
				hit["effort"]=lerpf(previous_effort,effort,fraction)
				hit["km"]=kilometres+length*fraction
				return hit
		kilometres+=length;previous=point;previous_effort=effort
		if previous_effort>=after:break
	return {}

static func launch(host:Node,army_id:int,contact:Dictionary)->Dictionary:
	var index:int=host._field_army_index(army_id)
	if index<0:return {"error":"The army is no longer present."}
	if host.command_hierarchy.battle.engaged(army_id):return {"error":"This army is already fighting."}
	var army:Dictionary=host.field_armies[index]
	var at:Vector2=host.command_hierarchy.land.point(army)
	var id:=String(contact.get("formation_id",""))
	var candidates:Array=[]
	for enemy:Dictionary in enemies(host,army):
		if String(enemy.id)==id:candidates.append(enemy)
	# A stored or caller-supplied contact cannot order a distant attack.
	var confirmed:=Defense.first_contact(at,at,candidates,army)
	if confirmed.is_empty():return {"error":"That defended ground is no longer in contact."}
	var point:Vector2=confirmed.defended_point
	var sighting:Dictionary=WorldSimulation.world.observe_front_contact(id,point)
	if sighting.is_empty():return {"error":"The opposing formation is no longer present."}
	var incident:Dictionary=WorldSimulation.world.foreign_formation_engagement_data(id,int(army.get("troops",0)))
	if incident.has("error"):return incident
	incident["front_contact"]=true
	incident["target_position"]={"x":point.x,"z":point.y}
	army["movement_block_reason"]="Fighting through the defended line"
	army["command_status"]="Fighting through the defended line"
	return host._start_map_engagement(army_id,{"army":army.duplicate(true),"sighting":sighting},incident)

static func snapshot(army:Dictionary)->Dictionary:
	var points:=Defense.coverage(army,int(WorldSimulation.state.elapsed_days))
	var packed:Array=[]
	for point:Vector2 in points:packed.append({"x":point.x,"z":point.y})
	var day:=int(WorldSimulation.state.elapsed_days)
	var breached:=day-int(army.get("border_breached_day",-9999))<14 and not army.has("border_sector")
	return {"id":"%s:army:%d" % [WorldSimulation.actor_id,int(army.get("army_id",0))],"points":packed,"troops":int(army.get("troops",0)),"day":day,"assigned":army.has("border_sector") or breached,"state":"breached" if breached else ("held" if not packed.is_empty() else "deploying")}

## Called by both owners' normal casualty commit. The victor keeps its order;
## a defeated defender vacates its sector and cannot remain an invisible wall.
static func after_battle(host:Node,result:Dictionary)->void:
	if not bool((result.get("threat",{}) as Dictionary).get("front_contact",false)):return
	if String(result.get("home_force_kind",""))!="field_army":return
	var side:=String(result.get("home_side","attacker"))
	var other:="defender" if side=="attacker" else "attacker"
	var outcome:=String(result.get("outcome",""))
	var won:=outcome==side+"_victory" or outcome==other+"_retreat"
	var lost:=outcome==other+"_victory" or outcome==side+"_retreat" or String((result.get("termination",{}) as Dictionary).get("type",""))=="mutual_withdrawal"
	var members:Array=result.get("command_participants",[])
	if members.is_empty():members=[{"army_id":int(result.get("home_force_id",0))}]
	for member:Dictionary in members:
		var index:int=host._field_army_index(int(member.army_id))
		if index<0:continue
		var army:Dictionary=host.field_armies[index]
		army.erase("movement_block_reason")
		if not lost and not Lines.unfit(army):
			army["command_status"]=("The line holds" if side=="defender" else "Breakthrough · continuing toward the objective") if won else "The line remains contested"
			continue
		if army.has("border_sector"):army["border_breached_day"]=int(WorldSimulation.state.elapsed_days)
		army.erase("border_sector")
		army["status"]="stationed"
		army["location_id"]="field_position"
		army["location_name"]="Regrouping after battle"
		army["command_recover_until"]=int(WorldSimulation.state.elapsed_days)+14
		army["resting"]=true;army["rest_reason"]="battle";army["rest_since"]=int(WorldSimulation.state.elapsed_days)
		army["command_status"]="Regrouping after the line broke"
