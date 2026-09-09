extends RefCounted
## Headquarters reference real campaign forces. Expanding the tree is read-only;
## issuing an order to a subdivision detaches its actual people and equipment.
const R=preload("res://scripts/joint_regions.gd")
const G=preload("res://scripts/joint_geography.gd")
const LEVELS={
	"army":[["Team",4,"Team leader"],["Squad",12,"Sergeant"],["Platoon",50,"Lieutenant"],["Company",250,"Captain · First Sergeant"],["Battalion",1500,"Lieutenant Colonel"],["Regiment / Brigade",5000,"Colonel"],["Division",20000,"Major General"],["Corps",60000,"Lieutenant General"],["Army",200000,"General"]],
	"navy":[["Ship",1,"Captain"],["Section",4,"Senior captain"],["Squadron",12,"Commodore"],["Task force",40,"Rear Admiral"],["Fleet",200,"Admiral"]],
	"air":[["Element",2,"Flight leader"],["Flight",6,"Flight commander"],["Squadron",24,"Squadron commander"],["Group",96,"Group commander"],["Wing",300,"Wing commander"],["Air force",1500,"Air commander"]]}
const LAND_MISSIONS={"defend":"Defend / patrol zone","encircle":"Encircle enemy armies","defeat":"Defeat enemy armies","capture":"Capture city","occupy":"Besiege and occupy city","raze":"Capture and raze infrastructure","withdraw":"Withdraw home"}
const MAX_NODES=1024
const MAX_LAND_FORCES=256
var host:Node
var data:Dictionary
var executing:=false
var battle:RefCounted
var battle_candidates:Array=[]
var land:RefCounted
func _init(campaign:Node)->void:
	host=campaign;battle=preload("res://scripts/command_battle.gd").new(host);land=preload("res://scripts/land_command.gd").new(self);reset()
func reset()->void:
	data={"nodes":{},"zones":[],"fronts":[],"battles":[],"next_id":1,"last_day":-1}
	for service:String in LEVELS:data.nodes[service]={"id":service,"service":service,"name":"Army" if service=="army" else "Navy" if service=="navy" else "Air Force","parent":"","level":LEVELS[service].size(),"force_id":-1}
	if land!=null:land.clear_cache()
func node(id:String)->Dictionary:return data.nodes.get(id,{})
func force(record:Dictionary)->Dictionary:
	var id:=int(record.get("force_id",-1))
	if id<0:return {}
	if record.service!="army":return host.joint_operations.force(id)
	if id==0:return host.home_army
	var index:int=host._field_army_index(id)
	return {} if index<0 else host.field_armies[index]
func amount(record:Dictionary)->int:
	var total:=0
	if int(record.get("force_id",-1))>=0:
		var actual:=force(record)
		return int(actual.get("troops",0)) if record.service=="army" else host.joint_operations.hardware(actual) if not actual.is_empty() else 0
	for child:Dictionary in children(String(record.id)):total+=amount(child)
	return total
func people(record:Dictionary)->int:
	if int(record.get("force_id",-1))>=0:
		var actual:=force(record)
		return int(actual.get("troops",0)) if record.service=="army" else host.joint_operations.crew(actual) if not actual.is_empty() else 0
	var result:=0
	for child:Dictionary in children(String(record.id)):result+=people(child)
	return result
func level_for(service:String,count:int)->int:
	for index in LEVELS[service].size():
		if count<=int(LEVELS[service][index][1]):return index
	return LEVELS[service].size()-1
func _add(service:String,parent:String,level:int,name:String,force_id:int=-1)->Dictionary:
	var id:="command:%d" % int(data.next_id);data.next_id+=1
	var result:={"id":id,"service":service,"parent":parent,"level":level,"name":name,"force_id":force_id}
	data.nodes[id]=result;return result
func sync()->void:
	var owned:Dictionary={}
	for record:Dictionary in data.nodes.values():
		if int(record.force_id)>=0:
			if force(record).is_empty():record.force_id=-1;record["retired"]=true
			else:
				owned["%s:%d" % [record.service,int(record.force_id)]]=true
				if record.service!="army":
					var actual:=force(record);var current:=order_for(String(record.id));var mission:=String(actual.get("mission","hold"))
					var area_id:=String(actual.get("region",{}).get("id",""))
					var expected:=String(current.get("mission","hold"))
					if expected=="cancelled":expected="hold"
					if mission!=expected or area_id!=String(current.get("zone_id","")):
						record["order"]={"mission":mission,"zone_id":area_id,"target":"","vision":"","day":int(GameState.elapsed_days)}
	var records:Array=[{"service":"army","id":0,"actual":host.home_army}]
	for actual:Dictionary in host.field_armies:records.append({"service":"army","id":actual.army_id,"actual":actual})
	for actual:Dictionary in host.joint_operations.state.forces:
		if actual.owner=="player":records.append({"service":actual.domain,"id":actual.id,"actual":actual})
	for item:Dictionary in records:
		if owned.has("%s:%d" % [item.service,int(item.id)]) or item.actual.is_empty():continue
		var count:int=int(item.actual.get("troops",0)) if item.service=="army" else host.joint_operations.hardware(item.actual)
		if count<=0:continue
		var level:=level_for(item.service,count)
		var title:=String(item.actual.get("name",LEVELS[item.service][level][0]))
		if item.service=="army" and (int(item.id)==0 or title.ends_with("FIELD Army")):title="%s · %d" % [LEVELS.army[level][0],int(item.id)+1]
		_add(item.service,item.service,level,title,int(item.id))
func children(id:String)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for entry:Dictionary in data.nodes.values():
		if String(entry.parent)==id:result.append(entry)
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return String(a.name).naturalnocasecmp_to(String(b.name))<0)
	return result
func leaves(id:String)->Array[Dictionary]:
	var record:=node(id);var result:Array[Dictionary]=[]
	if record.is_empty():return result
	if int(record.force_id)>=0:result.append(record)
	else:
		for child:Dictionary in children(id):result.append_array(leaves(String(child.id)))
	return result
func order_for(id:String)->Dictionary:
	var record:=node(id)
	for _step in 32:
		if record.is_empty():break
		if record.has("order"):return record.order
		record=node(String(record.parent))
	return {}
func parts(count:int,level:int,service:String)->Array[int]:
	var result:Array[int]=[]
	if count<=1 or level<=0:return result
	var number:=clampi(ceili(float(count)/maxf(1,float(LEVELS[service][level-1][1])*.7)),2,6)
	number=mini(number,count)
	for index in number:result.append(count/number+(1 if index<count%number else 0))
	return result
func preview(id:String,path:Array=[])->Dictionary:
	var record:=node(id)
	if record.is_empty():return {}
	var count:=amount(record);var level:=int(record.level);var title:=String(record.name)
	for index in path:
		var subdivisions:=parts(count,level,record.service)
		if int(index)<0 or int(index)>=subdivisions.size():return {}
		count=subdivisions[int(index)];level-=1;title="%d · %s" % [int(index)+1,LEVELS[record.service][level][0]]
	return {"id":id,"path":path.duplicate(),"service":record.service,"count":count,"level":level,"name":title,"leader":String(LEVELS[record.service][mini(level,LEVELS[record.service].size()-1)][2]),"parts":parts(count,level,record.service) if int(record.force_id)>=0 else [],"order":order_for(id).duplicate(true)}
func organize(ids:Array,level:int,title:String="")->Dictionary:
	sync()
	if ids.size()<2:return {"error":"Select at least two commands to group under a headquarters."}
	var service:="";var chosen:Dictionary={}
	for id:String in ids:
		var entry:=node(id)
		if entry.is_empty() or String(entry.parent)=="" or chosen.has(id):return {"error":"Select distinct subordinate commands."}
		if service=="":service=entry.service
		if entry.service!=service or level<=int(entry.level) or level>=LEVELS[service].size():return {"error":"Choose a headquarters above every selected command, within the same service."}
		chosen[id]=true
	for id:String in ids:
		var parent:=String(node(id).parent)
		while parent!="":
			if chosen.has(parent):return {"error":"A command and its own subordinate cannot both be grouped."}
			parent=String(node(parent).get("parent",""))
	if data.nodes.size()>=MAX_NODES:return {"error":"Command organization is full."}
	var group:=_add(service,service,level,title.strip_edges().left(80) if title.strip_edges()!="" else "%s headquarters" % LEVELS[service][level][0])
	for id:String in ids:
		var inherited:=order_for(id).duplicate(true)
		if not inherited.is_empty():node(id)["order"]=inherited
		node(id).parent=group.id
	return {"ok":true,"id":group.id,"message":"Headquarters formed. Subordinates retain their current objectives until you give the whole command a new order."}
func _busy(record:Dictionary)->String:
	var actual:=force(record)
	if actual.is_empty():return "The force is no longer available."
	if record.service=="army":
		if battle.engaged(int(record.force_id)):return "This command is already committed to a battle."
		if GeneralCampaign.active and int(actual.get("army_id",-1))==int(GeneralCampaign.state.get("army_id",-2)):return "This army is committed to its general's active campaign."
		if not host.active_engagement.is_empty() or not host.pending_aftermath.is_empty():return "Resolve the active battle before reorganizing forces."
		if bool(actual.get("embarked",false)) or actual.get("status","stationed") in ["moving","besieging"]:return "Let this command assemble before detaching a subordinate."
	else:
		if not host.joint_operations.organized_at_home(actual):return "Subdivide this force at its ready home base before sending detachments."
	return ""
func _split(id:String)->Dictionary:
	var record:=node(id);var original:=force(record);var error:=_busy(record)
	if error!="":return {"error":error}
	var counts:=parts(amount(record),int(record.level),record.service)
	if counts.is_empty():return {"error":"This is already the smallest command."}
	var original_id:=int(record.force_id);var metadata:=original.duplicate(true)
	var created:Array[Dictionary]=[]
	# Each detached record is conserved by the campaign's existing aggregate split.
	for index in range(counts.size()-1,-1,-1):
		var new_id:=original_id
		if record.service=="army":
			if index>0 or original_id==0:
				var formations:Array[Dictionary]=host._detach_occupation_formations(counts[index]) if original_id==0 else host._detach_field_army_formations(original_id,counts[index])
				var detached:Dictionary=host.simulator.create_formation_force("Detachment",formations,float(metadata.get("morale",.7)),float(metadata.get("readiness",.5)))
				detached.merge({"position":G.pack(CivilizationSystem.player_world_origin),"status":"stationed","location_id":"player_home","location_name":"Home settlement","destination_id":"","destination_name":"","destination_position":{},"distance_total_km":0.0,"distance_remaining_km":0.0,"departure_day":-1,"arrival_day":-1},true)
				for key:String in ["status","location_id","location_name","position","destination_id","destination_position","destination_name","distance_total_km","distance_remaining_km","departure_day","arrival_day","supply_level","visual_theme","exercise_readiness_bonus"]:
					if metadata.has(key):detached[key]=metadata[key].duplicate(true) if metadata[key] is Dictionary else metadata[key]
				detached["army_id"]=int(host.next_field_army_id);host.next_field_army_id+=1;new_id=detached.army_id
				detached["commander"]=metadata.get("commander",{}).duplicate(true);detached.commander.erase("figure_id")
				detached.commander["name"]="%s leader" % LEVELS.army[int(record.level)-1][0]
				detached["runner_count"]=mini(2,counts[index]);detached["last_runner_departure_day"]=int(GameState.elapsed_days)
				detached["last_report"]=host._army_report_snapshot(detached);host.field_armies.append(detached)
			else:original=force(record)
		else:
			if index>0:
				var detached:Dictionary=original.duplicate(true);detached.id=host.joint_operations._id();new_id=detached.id
				detached.units={};detached.authorized={}
				var remaining:=counts[index]
				for type_id:String in original.units:
					var take:=mini(remaining,int(original.units[type_id]));remaining-=take
					detached.units[type_id]=take;detached.authorized[type_id]=take
					original.units[type_id]-=take;original.authorized[type_id]-=take
				host.joint_operations.state.forces.append(detached)
		var child:=_add(record.service,id,int(record.level)-1,"%d · %s" % [index+1,LEVELS[record.service][int(record.level)-1][0]],new_id)
		created.push_front(child)
		force(child)["name"]=String(child.name)+" / "+String(record.name)
	# Original recovery pools stay with their force (or the home reserve).
	record.force_id=-1
	return {"ok":true,"children":created}
func materialize(id:String,path:Array)->Dictionary:
	var previewed:=preview(id,path)
	if previewed.is_empty():return {"error":"This formation changed. Select it again."}
	if not path.is_empty():
		var error:=_busy(node(id))
		if error!="":return {"error":error}
		var bound:=path.size()*6
		if data.nodes.size()+bound>MAX_NODES:return {"error":"Command organization is full."}
		if node(id).service=="army" and host.field_armies.size()+bound>MAX_LAND_FORCES:return {"error":"Too many independent detachments; assign an existing command."}
		if node(id).service!="army" and host.joint_operations.state.forces.size()+bound>host.joint_operations.MAX_FORCES:return {"error":"Too many independent service commands."}
	var current:=id
	for index in path:
		var result:=_split(current)
		if result.has("error"):return result
		current=String(result.children[int(index)].id)
	# Home reserve becomes a deployable command only when actually ordered.
	if node(current).service=="army" and int(node(current).force_id)==0:
		var record:=node(current);var count:=amount(record)
		if count<=0:return {"error":"No trained personnel in this command."}
		if host.field_armies.size()>=MAX_LAND_FORCES:return {"error":"Command capacity is full."}
		var result:Dictionary=host._assemble_field_army(host._detach_occupation_formations(count),String(record.name))
		if result.has("error"):return result
		record.force_id=int(result.army.army_id)
	return {"ok":true,"id":current}
func zone(id:String)->Dictionary:
	for region:Dictionary in data.zones:
		if String(region.id)==id:return region
	return {}
func known_regions(domain:String="army")->Array:return data.zones if domain=="army" else host.joint_operations.known_regions(domain)
func create_region(domain:String,vertices:Array,title:String="")->Dictionary:
	if domain!="army":return host.joint_operations.create_region(domain,vertices,title)
	var error:=R.validate(vertices)
	if error!="":return {"error":error}
	if data.zones.size()>=32:return {"error":"Use one of your existing 32 battle zones."}
	var region:={"id":"battle-zone:%d" % int(data.next_id),"domain":"army","owner":"player","vertices":vertices.duplicate(true),"name":title.strip_edges().left(80)};data.next_id+=1
	var center:=R.bounds(region).get_center();region.position=G.pack(center)
	if region.name=="":region.name="Battle zone %d" % (data.zones.size()+1)
	if land.rally(region).is_empty():return {"error":"Include charted land in the zone so a commander has a place to assemble."}
	data.zones.append(region)
	return {"ok":true,"region":region,"message":"Battle zone saved. Choose a command and its objective."}
func remove_region(id:String)->Dictionary:
	for entry:Dictionary in data.nodes.values():
		if entry.get("order",{}).get("zone_id","")==id:return {"error":"Cancel orders for this zone before deleting it."}
	for index in data.zones.size():
		if data.zones[index].id==id:
			data.zones.remove_at(index);data.fronts=data.fronts.filter(func(front:Dictionary)->bool:return front.zone_id!=id)
			return {"ok":true,"message":"Battle zone deleted."}
	return {"error":"Select a battle zone."}
func assign(id:String,path:Array,region:Dictionary,mission:String,target:String="",vision:String="")->Dictionary:
	sync()
	var selected:=preview(id,path)
	if selected.is_empty() or int(selected.count)<=0:return {"error":"Select an available command."}
	if selected.service=="army":
		if mission not in LAND_MISSIONS:return {"error":"Choose a supported land objective."}
		if mission!="withdraw" and zone(String(region.get("id",""))).is_empty():return {"error":"Select a saved battle zone on the map."}
		if mission in ["capture","occupy","raze"]:
			var city:Dictionary=CivilizationSystem.city_intelligence.known("player",target)
			if city.is_empty() or not R.contains(region,G.unpack(city.position)):return {"error":"Select a reported city inside this zone."}
			if city.get("controller","")=="player" and mission=="capture":return {"error":"This city is already under your control."}
	else:
		if not path.is_empty() and mission not in host.joint_operations.missions_for(force(node(id))):return {"error":"This command is not equipped for that mission."}
		# Validate the whole order without changing a force. Restore the authority
		# in place after each trial, including any route prepared by assign().
		for leaf:Dictionary in leaves(id):
			var actual:=force(leaf);var saved:=actual.duplicate(true)
			var result:Dictionary=host.joint_operations.assign(int(leaf.force_id),region,mission)
			actual.clear();actual.merge(saved,true)
			if result.has("error"):return {"error":"%s: %s" % [leaf.name,result.error]}
	for leaf:Dictionary in leaves(id):
		if selected.service=="army" and _busy(leaf)!="" and (not path.is_empty() or int(leaf.force_id)==0):return {"error":_busy(leaf)}
	var organization_before:=export_state()
	var service_before:Dictionary=host.joint_operations.export_state() if selected.service!="army" else {}
	var built:=materialize(id,path)
	if built.has("error"):return built
	var selected_id:=String(built.id)
	for leaf:Dictionary in leaves(selected_id):
		if selected.service!="army":
			var result:Dictionary=host.joint_operations.assign(int(leaf.force_id),region,mission)
			if result.has("error"):
				import_state(organization_before);host.joint_operations.import_state(service_before);return result
		elif int(leaf.force_id)==0:
			var result:=materialize(String(leaf.id),[])
			if result.has("error"):return result
	# Explicit whole-command orders replace subordinate exceptions. Subsequent
	# orders to one child create a new exception without stealing siblings.
	for entry:Dictionary in descendants(selected_id):entry.erase("order")
	node(selected_id)["order"]={"zone_id":String(region.get("id","")),"mission":mission,"target":target,"vision":vision.strip_edges().left(240),"day":int(GameState.elapsed_days)}
	for leaf:Dictionary in leaves(selected_id):
		if leaf.service=="army":force(leaf).erase("city_operation");force(leaf).erase("target_formation_id");force(leaf)["command_status"]="Commander preparing objective"
	return {"ok":true,"id":selected_id,"message":"Objective given to %s and its subordinates. Leaders execute it as the calendar advances." % String(node(selected_id).name)}
func descendants(id:String)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for child:Dictionary in children(id):result.append(child);result.append_array(descendants(String(child.id)))
	return result
func cancel(id:String,path:Array=[],expected_count:int=-1)->Dictionary:
	sync()
	var selected:=preview(id,path)
	if selected.is_empty():return {"error":"This command changed. Select it again."}
	if not path.is_empty():
		if expected_count>=0 and int(selected.count)!=expected_count:return {"error":"This formation's strength changed. Select it again before cancelling its orders."}
		if String(selected.order.get("mission","")) in ["","hold","cancelled"]:
			return {"ok":true,"id":id,"path":path.duplicate(),"message":"This subdivision has no active objective to cancel."}
		# A virtual row shares its parent's force. Materialize the exact selected
		# branch before changing orders; never cancel that parent's other troops.
		var built:=materialize(id,path)
		if built.has("error"):return built
		id=String(built.id)
	# Service stand-down can be refused by an active transport or an invalid
	# return route. Validate all leaves, restoring each force in place, before
	# changing the headquarters directive or any sibling's actual mission.
	var service_changes:Array[Dictionary]=[]
	for leaf:Dictionary in leaves(id):
		if leaf.service=="army":continue
		var actual:=force(leaf);var saved:=actual.duplicate(true)
		var result:Dictionary=host.joint_operations.assign(int(leaf.force_id),{},"hold")
		var after:=actual.duplicate(true)
		actual.clear();actual.merge(saved,true)
		if result.has("error"):return {"error":"%s: %s" % [leaf.name,String(result.error)]}
		service_changes.append({"force_id":int(leaf.force_id),"after":after})
	node(id)["order"]={"mission":"cancelled"}
	for child:Dictionary in descendants(id):child.erase("order")
	for leaf:Dictionary in leaves(id):
		if leaf.service=="army":
			var actual:=force(leaf)
			var committed:bool=actual.get("status","")=="besieging" or battle.engaged(int(leaf.force_id))
			if not committed:actual["status"]="stationed";actual["destination_id"]="";actual.erase("city_operation");actual.erase("target_formation_id")
			actual["command_status"]="Objective cancelled · resolving current engagement" if committed else "Orders cancelled · holding current ground"
	for change:Dictionary in service_changes:
		var actual:Dictionary=host.joint_operations.force(int(change.force_id))
		actual.clear();actual.merge(change.after,true)
	var message:="Objectives cancelled for %s and its subordinates." % String(node(id).name)
	if node(id).service=="navy":message+=" Task forces hold at or return to their home ports."
	elif node(id).service=="air":message+=" Sorties stop; aircraft return to base or stand by on their carrier."
	else:message+=" Commanders hold ground after any current engagement."
	return {"ok":true,"id":id,"path":[],"message":message}
func advance(day:int)->void:
	if day<=int(data.last_day):return
	data.last_day=day;sync();battle.advance_all();land.advance(day)
func export_state()->Dictionary:return data.duplicate(true)
func import_state(payload:Dictionary)->void:
	reset()
	for key:String in data:
		if payload.has(key):data[key]=payload[key].duplicate(true) if payload[key] is Dictionary or payload[key] is Array else payload[key]
static func validate(payload:Variant)->String:
	if not payload is Dictionary:return "Invalid command hierarchy."
	if payload.is_empty():return ""
	if not payload.get("nodes",{}) is Dictionary or payload.nodes.size()>MAX_NODES:return "Invalid command nodes."
	if not payload.get("zones",[]) is Array or payload.zones.size()>32 or not payload.get("fronts",[]) is Array or payload.fronts.size()>256:return "Invalid battle zones."
	if not whole(payload.get("next_id",0),1) or not whole(payload.get("last_day",-1),-1):return "Invalid command clock or identity counter."
	for service:String in LEVELS:
		if not payload.nodes.has(service):return "Missing service headquarters."
	var references:Dictionary={}
	for id in payload.nodes:
		var entry:Variant=payload.nodes[id]
		if not entry is Dictionary or entry.get("id","")!=id or entry.get("service","") not in LEVELS or not entry.get("name",null) is String:return "Invalid command identity."
		if not entry.get("parent","") is String or not whole(entry.get("level",null),0) or int(entry.level)<0 or int(entry.level)>LEVELS[entry.service].size():return "Invalid command echelon."
		if not whole(entry.get("force_id",null),-1) or int(entry.force_id)<-1 or not entry.get("order",{}) is Dictionary:return "Invalid command force."
		if String(entry.parent)=="" and (id!=entry.service or int(entry.force_id)!=-1):return "Invalid root command."
		var directive:Dictionary=entry.get("order",{})
		if not directive.is_empty():
			var missions:Dictionary=LAND_MISSIONS if entry.service=="army" else {"hold":true,"patrol":true,"strike_force":true,"convoy_raiding":true,"convoy_escort":true,"invasion_support":true} if entry.service=="navy" else {"hold":true,"air_superiority":true,"interception":true,"close_air_support":true,"logistics_strike":true,"strategic_bombing":true,"naval_strike":true,"port_strike":true,"reconnaissance":true,"air_supply":true}
			if directive.get("mission","")!="cancelled" and directive.get("mission","") not in missions:return "Invalid command objective."
			for key:String in ["zone_id","target","vision"]:
				if not directive.get(key,"") is String:return "Invalid command order text."
		var parent:=String(entry.parent);var seen:Dictionary={id:true}
		while parent!="":
			if seen.has(parent) or not payload.nodes.has(parent) or not payload.nodes[parent] is Dictionary or payload.nodes[parent].get("service","")!=entry.service:return "Command hierarchy contains a cycle or a foreign parent."
			seen[parent]=true;parent=String(payload.nodes[parent].get("parent",""))
		if int(entry.force_id)>=0:
			var key:="%s:%d" % [entry.service,int(entry.force_id)]
			if references.has(key):return "One force appears under multiple commands."
			references[key]=true
	var zones:Dictionary={}
	for region in payload.zones:
		if not region is Dictionary or region.get("domain","")!="army" or R.validate(region.get("vertices",[]))!="" or not region.get("id",null) is String or not region.get("name",null) is String:return "Invalid land boundary."
		if not region.get("position",null) is Dictionary or not is_finite(float(region.position.get("x",NAN))) or not is_finite(float(region.position.get("z",NAN))):return "Invalid zone assembly position."
		if zones.has(region.id):return "Duplicate battle zone."
		zones[region.id]=true
	for front in payload.fronts:
		if not front is Dictionary or not front.get("points",null) is Array or front.points.size()!=3 or not zones.has(front.get("zone_id","")):return "Invalid front geometry."
		for at in front.points:
			if not at is Dictionary or not is_finite(float(at.get("x",NAN))) or not is_finite(float(at.get("z",NAN))):return "Invalid front position."
	return ""
func controls_army(army_id:int)->bool:
	for entry:Dictionary in data.nodes.values():
		if entry.service=="army" and int(entry.force_id)==army_id:
			var order:=order_for(String(entry.id))
			return not order.is_empty() and order.get("mission","")!="cancelled"
	return false

static func whole(value:Variant,minimum:int)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=minimum and floorf(float(value))==float(value)
static func validate_links(payload:Dictionary)->String:
	var hierarchy:Dictionary=payload.get("command_hierarchy",{})
	var valid:Dictionary={"army:0":true}
	if not payload.get("field_armies",[]) is Array:return "Invalid land force records."
	for force in payload.get("field_armies",[]):
		if not force is Dictionary:return "Invalid land force record."
		valid["army:%d" % int(force.get("army_id",0))]=true
	for force:Dictionary in payload.get("joint_operations",{}).get("forces",[]):
		if force.get("owner","")=="player":valid["%s:%d" % [force.get("domain",""),int(force.get("id",0))]]=true
	for record:Dictionary in hierarchy.get("nodes",{}).values():
		if int(record.force_id)>=0 and not valid.has("%s:%d" % [record.service,int(record.force_id)]):return "Command references a missing or foreign force."
	return preload("res://scripts/command_battle.gd").validate(hierarchy.get("battles",[]),payload.get("field_armies",[]))
