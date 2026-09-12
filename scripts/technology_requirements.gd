extends RefCounted
## Shared causal predicates. Each requires_any group is OR; groups and
## requires_all are AND. Route requirements never replace common foundations.
static func evaluate(spec:Dictionary,known:Array)->Dictionary:
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

static func validate(catalog:Array)->Array[String]:
	var errors:Array[String]=[]
	var index:Dictionary={}
	for entry:Dictionary in catalog:
		var id:=String(entry.get("id",""))
		if id.is_empty() or index.has(id):errors.append("Missing or duplicate technology ID: "+id)
		index[id]=entry
	for entry:Dictionary in catalog:
		var specs:Array=[entry]
		specs.append_array(entry.get("learning_routes",[]))
		var route_ids:Array=[]
		for spec:Dictionary in specs:
			if spec!=entry:
				var route_id:=String(spec.get("id",""))
				if route_id.is_empty() or route_id in route_ids:errors.append(String(entry.id)+": missing or duplicate route ID")
				route_ids.append(route_id)
			for group:Array in spec.get("requires_any",[]):
				if group.is_empty():errors.append(String(entry.id)+": empty OR group")
			for parent:String in parents(spec):
				if not index.has(parent):errors.append(String(entry.id)+": unknown prerequisite "+parent)
	# A fixed point checks achievable alternatives, rather than treating an
	# optional cyclic route as proof that every route to a discovery is blocked.
	var reachable:Array=[]
	var changed:=true
	while changed:
		changed=false
		for entry:Dictionary in catalog:
			if entry.id in reachable or not evaluate(entry,reachable).ready:continue
			var routes:Array=entry.get("learning_routes",[])
			var route_ready:=routes.is_empty()
			for route:Dictionary in routes:
				if evaluate(route,reachable).ready:route_ready=true;break
			if route_ready:reachable.append(entry.id);changed=true
	for id:String in index:
		if id not in reachable:errors.append(id+": no reachable causal route (cycle or missing foundation)")
	return errors
