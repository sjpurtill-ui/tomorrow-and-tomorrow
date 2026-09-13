extends RefCounted
## Shared causal predicates. Each requires_any group is OR; groups and
## requires_all are AND. Route requirements never replace common foundations.
# Callers scanning many entries may build one short-lived membership index.
# Array callers remain supported; neither form is retained across state changes.
static func index_known(known:Array)->Dictionary:
	var result:Dictionary={}
	for id:String in known:result[id]=true
	return result

static func evaluate(spec:Dictionary,known:Variant)->Dictionary:
	var missing:Array[String]=[]
	var alternatives:Array=[]
	for id:String in spec.get("requires_all",spec.get("requires",[])):
		if id not in known:missing.append(id)
	for group:Array in spec.get("requires_any",[]):
		var satisfied:=false
		for id:String in group:
			if id in known:satisfied=true;break
		if not satisfied:alternatives.append(group.duplicate())
	return {"ready":missing.is_empty() and alternatives.is_empty(),"missing_all":missing,"missing_any":alternatives}

static func parents(spec:Dictionary)->Array[String]:
	var result:Array[String]=[]
	for id:String in spec.get("requires_all",spec.get("requires",[])):
		if id not in result:result.append(id)
	for group:Array in spec.get("requires_any",[]):
		for id:String in group:
			if id not in result:result.append(id)
	return result

static func validate(catalog:Array,dormant_or:Array=[])->Array[String]:
	var errors:Array[String]=[]
	var index:Dictionary={}
	for entry:Dictionary in catalog:
		var id:=String(entry.get("id",""))
		if id.is_empty() or index.has(id):errors.append("Missing or duplicate technology ID: "+id)
		index[id]=entry
	var approved:Array=[]
	if not dormant_or.is_empty():
		var audit:Dictionary=load("res://tools/technology-review/dormant_or_audit.gd").verify(index,dormant_or)
		errors.append_array(audit.errors)
		approved=audit.approved
	for entry:Dictionary in catalog:
		var specs:Array=[entry]
		specs.append_array(entry.get("learning_routes",[]))
		var route_ids:Array=[]
		for spec_index:int in range(specs.size()):
			var spec:Dictionary=specs[spec_index]
			if spec_index>0:
				var route_id:=String(spec.get("id",""))
				if route_id.is_empty() or route_id in route_ids:errors.append(String(entry.id)+": missing or duplicate route ID")
				route_ids.append(route_id)
			for group:Array in spec.get("requires_any",[]):
				if group.is_empty():errors.append(String(entry.id)+": empty OR group")
			for parent:String in parents(spec):
				if not index.has(parent):
					var dormant:=false
					# Only a common OR edge may be declared dormant; AND and
					# local acquisition-route requirements remain strict.
					if spec_index==0 and parent not in spec.get("requires_all",spec.get("requires",[])):
						for declaration:Dictionary in approved:
							if declaration.child==entry.id and declaration.parent==parent:dormant=true
					if not dormant:errors.append(String(entry.id)+": unknown prerequisite "+parent)
	# Revisit only entries affected by a newly reachable parent. Optional cycles
	# remain valid when another route reaches a root; authoring order is irrelevant.
	var dependents:Dictionary={}
	for entry:Dictionary in catalog:
		var specs:Array=[entry]
		specs.append_array(entry.get("learning_routes",[]))
		for spec:Dictionary in specs:
			for parent:String in parents(spec):
				if not dependents.has(parent):dependents[parent]={}
				dependents[parent][entry.id]=true
	var reachable:Dictionary={}
	var queue:Array=index.keys()
	var queued:Dictionary=index.duplicate()
	var cursor:=0
	while cursor<queue.size():
		var id:String=queue[cursor]
		cursor+=1
		queued.erase(id)
		if reachable.has(id):continue
		var entry:Dictionary=index[id]
		if not evaluate(entry,reachable).ready:continue
		var routes:Array=entry.get("learning_routes",[])
		var route_ready:=routes.is_empty()
		for route:Dictionary in routes:
			if evaluate(route,reachable).ready:route_ready=true;break
		if not route_ready:continue
		reachable[id]=true
		for child:String in dependents.get(id,{}):
			if not reachable.has(child) and not queued.has(child):
				queue.append(child)
				queued[child]=true
	for declaration:Dictionary in approved:
		var alternative_reachable:=false
		for parent:String in declaration.group:
			if reachable.has(parent):alternative_reachable=true
		if not alternative_reachable:errors.append(String(declaration.child)+": dormant OR has no reachable live alternative")
	for id:String in index:
		if not reachable.has(id):errors.append(id+": no reachable causal route (cycle or missing foundation)")
	return errors
