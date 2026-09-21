extends RefCounted
## Template production lines. Personnel and equipment live only in the existing
## military ledger; lines contain orders and IDs, never a second troop pool.
var host:Node
var data:Dictionary={}
func _init(campaign:Node)->void:host=campaign;reset()
func reset()->void:data={"next_id":1,"next_slot":1,"lines":[]}
func load_state(saved:Dictionary)->void:
	reset()
	data.merge(saved.duplicate(true),true)
func line(id:int)->Dictionary:
	for item:Dictionary in data.lines:
		if int(item.id)==id:return item
	return {}
func add(template_id:int,parallel:int=1,serial:int=1,repeat:bool=false)->Dictionary:
	var index:int=host._template_index(template_id)
	if index<0:return {"error":"Choose a formation template."}
	var entries:Array=host.army_templates[index].get("entries",[])
	if entries.is_empty():return {"error":"Add units to the template first."}
	for entry:Dictionary in entries:
		var gate:Dictionary=host._training_gate(String(entry.unit),String(entry.weapon))
		if gate.has("error"):return gate
	var id:int=data.next_id;data.next_id=id+1
	data.lines.append({"id":id,"name":String(host.army_templates[index].name),"template_id":template_id,"entries":entries.duplicate(true),"parallel":maxi(1,parallel),"remaining":0 if repeat else maxi(1,serial)*maxi(1,parallel),"repeat":repeat,"priority":1,"paused":false,"auto_deploy":true,"target_army":0,"deployed":0,"slots":[]})
	prepare()
	return {"ok":true,"id":id,"message":"Recruitment queued. People and equipment fill independently; shortages remain visible."}
func configure(id:int,key:String,value:Variant)->Dictionary:
	var item:=line(id)
	if item.is_empty():return {"error":"Recruitment line no longer exists."}
	if key in ["repeat","paused","auto_deploy"]:item[key]=bool(value)
	elif key=="priority":item[key]=clampi(int(value),0,2)
	elif key=="parallel":item[key]=maxi(1,int(value))
	elif key=="remaining":item[key]=maxi(0,int(value))
	elif key=="target_army":
		if int(value)!=0 and host._field_army_index(int(value))<0:return {"error":"Army no longer exists."}
		item[key]=int(value)
	else:return {"error":"Unknown recruitment setting."}
	return {"ok":true}
func orders(id:int,slot:int)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for order:Dictionary in host.training_queue:
		if int(order.get("deployment_line",-1))==id and int(order.get("deployment_slot",-1))==slot:result.append(order)
	return result
func prepare()->void:
	if host.recovery.home_unavailable():return
	var indexed:Dictionary={}
	for order:Dictionary in host.training_queue:
		if order.has("deployment_line"):indexed[[int(order.deployment_line),int(order.deployment_slot),int(order.entry_index)]]=order
	var sorted:Array=data.lines.duplicate()
	sorted.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.priority)>int(b.priority) if int(a.priority)!=int(b.priority) else int(a.id)<int(b.id))
	for item:Dictionary in sorted:
		if bool(item.paused):continue
		var size:=0
		for entry:Dictionary in item.entries:size+=int(entry.count)
		var available:int=host.aggregate_recruits+maxi(0,host.recruitment_capacity()-host._mobilized_count())
		# Unfunded parallel requests remain aggregate pending counts, not millions
		# of empty per-formation records when the population is small.
		var materialized:=mini(int(item.parallel),item.slots.size()+ceili(float(available)/maxi(1,size)))
		while item.slots.size()<materialized and (bool(item.repeat) or int(item.remaining)>0):
			var slot:int=data.next_slot;data.next_slot=slot+1
			item.slots.append(slot)
			if not bool(item.repeat):item.remaining=int(item.remaining)-1
		for slot in item.slots:
			for entry_index in item.entries.size():
				var entry:Dictionary=item.entries[entry_index]
				var order:Dictionary=indexed.get([int(item.id),int(slot),entry_index],{})
				var need:=maxi(0,int(entry.count)-int(order.get("count",0)))
				if need>0:
					var people_now:int=host.aggregate_recruits+maxi(0,host.recruitment_capacity()-host._mobilized_count())
					var count:=mini(need,people_now)
					if count>host.aggregate_recruits:host.raise_recruits(count-host.aggregate_recruits)
					if count>0 and order.is_empty():
						var result:Dictionary=host.start_training(String(entry.unit),String(entry.weapon),count)
						if not result.has("error"):
							order=host.training_queue[-1]
							indexed[[int(item.id),int(slot),entry_index]]=order
							order.merge({"deployment_line":int(item.id),"deployment_slot":int(slot),"entry_index":entry_index,"target_count":int(entry.count),"reserved_equipment":0})
					elif count>0:
						var old:int=order.count
						order.progress_days=float(order.progress_days)*old/maxi(1,old+count)
						order.count=old+count;order.initial_count=int(order.get("initial_count",old))+count
						host.aggregate_recruits-=count
				if order.is_empty():continue
				var weapon:=String(order.weapon)
				var required:int=host._equipment_required_for(String(order.unit),int(order.count))
				var held:int=order.get("reserved_equipment",0)
				var take:=mini(maxi(0,required-held),maxi(0,int(host.military_inventory.get(weapon,0))))
				order.reserved_equipment=held+take;host.military_inventory[weapon]=int(host.military_inventory.get(weapon,0))-take
func status(id:int,slot:int)->Dictionary:
	return _status(line(id),orders(id,slot))
func _status(item:Dictionary,jobs:Array[Dictionary])->Dictionary:
	var result:={"people":0,"target":0,"equipment":0,"equipment_required":0,"current_equipment_required":0,"training":1.0,"early":false,"ready":false}
	if item.is_empty():return result
	for entry:Dictionary in item.entries:
		result.target+=int(entry.count)
		result.equipment_required+=host._equipment_required_for(String(entry.unit),int(entry.count))
	if jobs.size()!=item.entries.size():result.training=0.0
	for job:Dictionary in jobs:
		result.people+=int(job.count);result.equipment+=int(job.get("reserved_equipment",0))
		result.current_equipment_required+=host._equipment_required_for(String(job.unit),int(job.count))
		result.training=minf(float(result.training),clampf(float(job.progress_days)/maxf(1,float(job.required_days)),0,1))
	result.early=int(result.people)>0 and jobs.size()==item.entries.size() and float(result.training)>=.2
	result.ready=bool(result.early) and float(result.training)>=1.0 and int(result.equipment)>=int(result.current_equipment_required)
	return result
func deploy_ready()->void:
	var grouped:Dictionary={}
	for job:Dictionary in host.training_queue:
		if not job.has("deployment_line"):continue
		var key:=[int(job.deployment_line),int(job.deployment_slot)]
		if not grouped.has(key):grouped[key]=[]
		grouped[key].append(job)
	for item:Dictionary in data.lines:
		if bool(item.paused) or not bool(item.auto_deploy):continue
		for slot in item.slots.duplicate():
			var jobs:Array[Dictionary]=[];jobs.assign(grouped.get([int(item.id),int(slot)],[]))
			if bool(_status(item,jobs).ready):deploy(int(item.id),int(slot))
func deploy(id:int,slot:int,early:bool=false)->Dictionary:
	var item:=line(id);var report:=status(id,slot)
	if item.is_empty() or slot not in item.slots:return {"error":"Training formation no longer exists."}
	if not bool(report.early if early else report.ready):return {"error":"Early deployment needs 20% training; automatic deployment needs full people, equipment and training."}
	if not host.active_engagement.is_empty() or not host.pending_aftermath.is_empty() or host.recovery.home_unavailable():return {"error":"Deployment site is unavailable during combat, occupation or unresolved aftermath."}
	var target:int=item.target_army
	if target!=0:
		var target_index:int=host._field_army_index(target)
		if target_index<0:return {"error":"Assigned army no longer exists. Choose another destination."}
		var force:Dictionary=host.field_armies[target_index]
		if String(force.get("location_id",""))!="player_home" or String(force.get("status",""))!="stationed":return {"error":"Assigned army must be at home to receive recruits; soldiers cannot teleport."}
	elif host.field_armies.size()>=host.field_army_capacity():return {"error":"Assign recruits to an existing army at home."}
	var completed_ids:Array[int]=[]
	for order:Dictionary in orders(id,slot):
		completed_ids.append(host.next_formation_id)
		host._complete_training(order);host.training_queue.erase(order)
	var formations:Array[Dictionary]=[]
	for index in range(host.home_army.formations.size()-1,-1,-1):
		var formation:Dictionary=host.home_army.formations[index]
		if int(formation.get("id",-1)) in completed_ids:
			formations.append(formation);host.home_army.formations.remove_at(index)
			host.home_army.troops=int(host.home_army.troops)-int(formation.count)
	if target==0:
		host._assemble_field_army(formations,String(item.name)+" "+str(int(item.deployed)+1))
	else:
		var army:Dictionary=host.field_armies[host._field_army_index(target)]
		for formation:Dictionary in formations:army.formations.append(formation);army.troops=int(army.troops)+int(formation.count)
		var rebuilt:Dictionary=host.simulator.create_formation_force(String(army.name),army.formations,float(army.get("morale",.8)),float(army.get("readiness",.5)))
		for key in ["troops","attack","defense","armor","penetration","formations"]:army[key]=rebuilt[key]
		host._refresh_readiness()
	item.slots.erase(slot);item.deployed=int(item.deployed)+1
	return {"ok":true,"message":"%d soldiers deployed at home%s." % [int(report.people)," with incomplete training" if early else ""]}
func cancel(id:int)->Dictionary:
	var item:=line(id)
	if item.is_empty():return {"error":"Recruitment line no longer exists."}
	for slot in item.slots:
		for order:Dictionary in orders(id,int(slot)):
			var weapon:=String(order.weapon)
			host.military_inventory[weapon]=int(host.military_inventory.get(weapon,0))+int(order.get("reserved_equipment",0))
			# Cancellation releases these draftees to civilian life, not another queue.
			host.training_queue.erase(order)
	data.lines.erase(item)
	return {"ok":true,"message":"Recruitment cancelled. Draftees returned to civilian life; equipment returned to stores. Injured personnel remain in recovery."}
static func validate_saved(payload:Dictionary)->String:
	var state:Variant=payload.get("recruit_deploy",{})
	if not state is Dictionary:return "Invalid recruitment lines."
	if state.is_empty():return ""
	if not state.get("lines") is Array:return "Invalid recruitment lines."
	var ids:Dictionary={};var slots:Dictionary={};var greatest:=0;var greatest_slot:=0
	for item in state.lines:
		if not item is Dictionary:return "Invalid recruitment line."
		for key in ["id","parallel","remaining","priority","target_army","deployed"]:
			if not item.get(key) is int or int(item[key])<0:return "Invalid recruitment value: "+key
		if int(item.id)<=0 or int(item.parallel)<=0 or ids.has(int(item.id)):return "Invalid recruitment line identity."
		for key in ["repeat","paused","auto_deploy"]:
			if not item.get(key) is bool:return "Invalid recruitment switch."
		if not item.get("entries") is Array or item.entries.is_empty() or not item.get("slots") is Array:return "Invalid recruitment composition."
		for entry in item.entries:
			if not entry is Dictionary or not entry.get("unit") is String or not entry.get("weapon") is String or not entry.get("count") is int or int(entry.count)<=0:return "Invalid recruitment cohort."
		ids[int(item.id)]=item;greatest=maxi(greatest,int(item.id))
		for slot in item.slots:
			if not slot is int or slot<=0 or slots.has(slot):return "Invalid recruitment slot identity."
			slots[slot]=int(item.id);greatest_slot=maxi(greatest_slot,slot)
	if int(state.get("next_id",0))<=greatest or int(state.get("next_slot",0))<=greatest_slot:return "Invalid recruitment sequence."
	var cohorts:Dictionary={}
	for job in payload.get("training_queue",[]):
		if not job is Dictionary or not job.has("deployment_line"):continue
		var id:=int(job.deployment_line);var slot:=int(job.get("deployment_slot",0));var index:=int(job.get("entry_index",-1))
		if not ids.has(id) or int(slots.get(slot,-1))!=id or index<0 or index>=ids[id].entries.size():return "Recruitment cohort lost its parent order."
		var key:=[id,slot,index]
		if cohorts.has(key):return "Duplicate recruitment cohort."
		cohorts[key]=true
	return ""
