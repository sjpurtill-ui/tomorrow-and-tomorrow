extends RefCounted
## Preparation of the selected naval/air command for the next zone, without orders.
static func snapshot(command:RefCounted,selection:Dictionary,area:Dictionary)->Dictionary:
	var result:={"visible":false,"training":0.0,"condition":0.0,"coverage":0.0,"fuel":0,"reserve":0,"shortage":0,"commands":0,"delayed":0,"summary":"","tooltip":"","warning":false}
	if selection.is_empty():return result
	var current:Dictionary=command.preview(String(selection.id),selection.get("path",[]))
	if current.is_empty() or current.service=="army" or int(current.count)<=0:return result
	var op:RefCounted=MilitaryCampaign.joint_operations
	var records:Array[Dictionary]=[];var notes:Array[String]=[]
	if not current.path.is_empty():
		var node:Dictionary=command.node(String(current.id));var actual:Dictionary=command.force(node).duplicate(true)
		if actual.is_empty():return result
		actual.units=current.units.duplicate(true);actual.authorized=actual.units.duplicate(true)
		records.append({"name":current.name,"actual":actual})
		var assembly:=String(command._busy(node))
		if assembly!="":notes.append(assembly)
	else:
		for leaf:Dictionary in command.leaves(String(current.id)):
			var actual:Dictionary=command.force(leaf)
			if not actual.is_empty():records.append({"name":leaf.name,"actual":actual.duplicate(true)})
	if records.is_empty():return result
	var craft:=0;var people:=0
	for entry:Dictionary in records:
		var actual:Dictionary=entry.actual
		# An empty next-zone selection must not borrow the old order's region.
		actual.region=area.duplicate(true)
		var ready:Dictionary=op.readiness_for(actual,area)
		var count:=int(op.hardware(actual));var crew:=int(op.crew(actual));craft+=count;people+=crew
		result.training+=float(actual.training)*crew;result.condition+=float(actual.condition)*count
		result.coverage+=float(ready.coverage)*count;result.fuel+=int(ready.fuel_per_day)
		var reasons:Array[String]=[]
		for reason:String in ready.blockers:
			if not reason.begins_with("Insufficient fuel:"):reasons.append(reason)
		if op.logistics.busy(int(actual.id)):reasons.append("Finish or recall the current transport before changing its objective.")
		if not reasons.is_empty():
			result.delayed+=1;notes.append(String(entry.name)+": "+" ".join(reasons))
	result.visible=true;result.commands=records.size()
	result.training/=maxi(1,people);result.condition/=maxi(1,craft);result.coverage/=maxi(1,craft)
	result.reserve=int(MilitaryCampaign.military_consumables.get("fuel",0))
	result.shortage=maxi(0,int(result.fuel)-int(result.reserve))
	if result.shortage>0:notes.push_front("Selected command needs %d fuel/day for all missions; only %d is in the shared reserve." % [int(result.fuel),int(result.reserve)])
	result.warning=not notes.is_empty()
	if area.is_empty():result.summary="Choose the next operating zone to check coverage."
	elif result.shortage>0:result.summary="Fuel short by %d for a full day of missions." % int(result.shortage)
	elif not notes.is_empty():result.summary=notes[0]
	else:result.summary="No listed preparation blockers for this zone."
	notes.append("Initial training is weighted by crew; condition and range coverage by craft. Coverage is not air/naval control or a battle prediction.")
	notes.append("Fuel is the full daily mission requirement of this selection, not a reservation. Other forces and staff exercises share the reserve. Orders can wait for preparation; staff still need compatible equipment and a navigable route.")
	result.tooltip="\n\n".join(notes)
	return result
