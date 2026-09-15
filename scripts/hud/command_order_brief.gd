extends RefCounted
## Read-only presentation of issued orders, separate from the next-order form.
static func _key(order:Dictionary)->String:
	return str([order.get("mission",""),order.get("zone_id",""),order.get("target",""),order.get("vision","")])

static func snapshot(command:RefCounted,selection:Dictionary)->Dictionary:
	var result:={"summary":"No command selected","tooltip":"","order":{},"region":{},"editable":false,"mixed":false,"overrides":0}
	if selection.is_empty():return result
	var current:Dictionary=command.preview(String(selection.id),selection.get("path",[]))
	if current.is_empty():result.summary="Command no longer available";return result
	if int(current.count)<=0:result.summary="No forces assigned";return result
	var id:=String(current.id);var service:=String(current.service)
	var leaves:Array=command.leaves(id);var variants:Dictionary={}
	for leaf:Dictionary in leaves:
		var order:Dictionary=command.order_for(String(leaf.id));var key:=_key(order)
		if not variants.has(key):variants[key]={"order":order,"count":0}
		variants[key].count+=1
	var issued:Dictionary=current.order;var notes:Array[String]=[]
	if issued.is_empty() and variants.size()>1:
		result.summary="Mixed orders · %d commands" % leaves.size();result.mixed=true
		for variant:Dictionary in variants.values().slice(0,8):
			var name:=String(variant.order.get("mission",""))
			var line:="%d × %s" % [int(variant.count),"Unassigned" if name=="" else name.replace("_"," ").capitalize()]
			for area:Dictionary in command.known_regions(service):
				if area.id==variant.order.get("zone_id",""):line+=" · "+String(area.name);break
			var city:Dictionary=CivilizationSystem.city_intelligence.known("player",String(variant.order.get("target","")))
			if not city.is_empty():line+=" · "+String(city.name)
			if String(variant.order.get("vision",""))!="":line+=" · "+String(variant.order.vision).left(80)
			notes.append(line)
		if variants.size()>8:notes.append("%d other orders" % (variants.size()-8))
		notes.append("Select a subordinate to inspect its order. Giving this headquarters an objective replaces subordinate orders.")
		result.tooltip="\n".join(notes);return result
	if issued.is_empty() and variants.size()==1:
		issued=variants.values()[0].order
		if leaves.size()>1:notes.append("All %d subordinate commands share this order." % leaves.size())
	else:
		for variant:Dictionary in variants.values():
			if _key(variant.order)!=_key(issued):result.overrides+=int(variant.count)
		if not current.path.is_empty():notes.append("This subdivision shares its parent force's order until assigned separately.")
		elif not issued.is_empty():
			var source:Dictionary=command.node(id)
			while not source.is_empty() and not source.has("order"):source=command.node(String(source.parent))
			if not source.is_empty() and source.id!=id:notes.append("Inherited from %s." % String(source.name))
	result.order=issued.duplicate(true)
	var mission:=String(issued.get("mission",""))
	if mission=="":result.summary="No issued objective";result.tooltip="Choose a draft objective below, mark its area, then Issue objective.";return result
	var catalog:Dictionary=command.LAND_MISSIONS if service=="army" else MilitaryCampaign.joint_operations.MISSIONS[service]
	var title:="Holding" if mission=="cancelled" else mission.replace("_"," ").capitalize()
	var location:=""
	for region:Dictionary in command.known_regions(service):
		if region.id==issued.get("zone_id",""):result.region=region.duplicate(true);location=String(region.name);break
	var target:=String(issued.get("target",""));var reported:Dictionary={}
	if target!="":
		reported=CivilizationSystem.city_intelligence.known("player",target)
		location=String(reported.get("name","Unreported city"))
	result.summary=title+(" · "+location if location!="" else "")
	if int(result.overrides)>0:
		result.summary+=" · %d %s" % [int(result.overrides),"override" if int(result.overrides)==1 else "overrides"]
		notes.append("%d subordinate commands have different orders. Giving this command an objective replaces those orders." % int(result.overrides))
	var description:=String(catalog.get(mission,"Orders cancelled"))
	if not result.region.is_empty():description+="\nZone: "+String(result.region.name)
	if target!="":description+="\nCity: "+String(reported.get("name","Unreported city"))
	if String(issued.get("vision","")).strip_edges()!="":description+="\nBrief: "+String(issued.vision)
	notes.push_front(description)
	result.editable=catalog.has(mission) and mission!="transport"
	if mission not in ["hold","withdraw","cancelled"] and result.region.is_empty():
		result.editable=false;notes.append("The assigned zone is unavailable. Select a zone for a new objective.")
	if mission in ["capture","occupy","raze"] and (reported.is_empty() or not command.R.contains(result.region,command.G.unpack(reported.position))):
		result.editable=false;notes.append("The target needs a city report inside the assigned zone.")
	if mission=="transport":notes.append("Manage this transport in Ports & ships." if service=="navy" else "Manage this transport in Airbases & aircraft.")
	result.tooltip="\n".join(notes)
	return result
