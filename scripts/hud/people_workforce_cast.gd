extends RefCounted
## One hundred persistent visual representatives, never simulation population.
## Allocation weights are detached head counts supplied by the existing preview.
const ROLES:Array[String]=["Food","Survey","Extraction","Construction","Crafting","Logistics","Knowledge","Administration","Defense"]
const COUNT:=100
const RESERVE:="Unassigned"
var people:Array[Dictionary]=[]
var percentages:Dictionary={}
var slots:Dictionary={}
var gates:Dictionary={}
var hub:=Vector2.ZERO
var initialized:=false
var route_provider:Callable

static func apportion(weights:Dictionary)->Dictionary:
	var result:Dictionary={};var total:=0.0;var clean:Dictionary={}
	for role:String in ROLES:
		var value:=float(weights.get(role,0.0))
		if not is_finite(value) or value<0:value=0.0
		clean[role]=value;total+=value;result[role]=0
	if total<=0:
		result[RESERVE]=COUNT;return result
	var fractions:Array[Dictionary]=[];var assigned:=0
	for role:String in ROLES:
		var exact:=float(clean[role])/total*COUNT
		result[role]=floori(exact);assigned+=int(result[role])
		fractions.append({"role":role,"fraction":exact-floor(exact),"order":ROLES.find(role)})
	fractions.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		return int(a.order)<int(b.order) if is_equal_approx(a.fraction,b.fraction) else float(a.fraction)>float(b.fraction))
	for index in COUNT-assigned:result[fractions[index].role]+=1
	return result

func configure(work_slots:Dictionary,work_gates:Dictionary,center:Vector2,routes:Callable=Callable())->void:
	slots=work_slots.duplicate(true);gates=work_gates.duplicate(true);hub=center
	route_provider=routes
	if not slots.has(RESERVE):
		var reserve:=PackedVector2Array()
		for i in COUNT:reserve.append(hub+Vector2((i%10)-4.5,(i/10)-4.5)*.0015)
		slots[RESERVE]=reserve
	if people.is_empty():
		for id in COUNT:
			people.append({"id":id,"sex":id%2,"role":RESERVE,"slot":id,"position":Vector2(slots[RESERVE][id]),"target":Vector2(slots[RESERVE][id]),"path":PackedVector2Array(),"segment":0,"traveled":0.0,"moving":false})

func set_weights(weights:Dictionary,animate:bool=true)->void:
	var wanted:=apportion(weights)
	if initialized and wanted==percentages:return
	percentages=wanted
	var retained:Dictionary={};var available:Array[int]=[]
	var keys:Array[String]=ROLES.duplicate();keys.append(RESERVE)
	for role:String in keys:retained[role]=[]
	# Keep already assigned identities and slots. Only the excess leaves a job.
	for person:Dictionary in people:
		var role:=String(person.role)
		if retained[role].size()<int(wanted.get(role,0)):retained[role].append(int(person.id))
		else:available.append(int(person.id))
	for role:String in keys:
		var used:Dictionary={}
		for id:int in retained[role]:used[int(people[id].slot)]=true
		var needed:int=int(wanted.get(role,0))-retained[role].size()
		for _index in needed:
			var slot:=0
			while used.has(slot):slot+=1
			used[slot]=true
			var destination:Vector2=slots[role][slot]
			available.sort_custom(func(a:int,b:int)->bool:
				var da:float=Vector2(people[a].position).distance_squared_to(destination)
				var db:float=Vector2(people[b].position).distance_squared_to(destination)
				return a<b if is_equal_approx(da,db) else da<db)
			var id:int=available.pop_front();var person:Dictionary=people[id]
			var previous:=String(person.role);person.role=role;person.slot=slot;person.target=destination
			if not initialized or not animate:
				person.position=destination;person.path=PackedVector2Array();person.segment=0;person.moving=false
			else:
				person.path=_transfer_path(Vector2(person.position),previous,role,destination)
				person.segment=0;person.moving=person.path.size()>1
	initialized=true

func _transfer_path(start:Vector2,from:String,to:String,destination:Vector2)->PackedVector2Array:
	var path:=PackedVector2Array([start])
	var journey:PackedVector2Array=route_provider.call(from,to) if route_provider.is_valid() else PackedVector2Array()
	if journey.is_empty():journey=PackedVector2Array([gates.get(from,hub),hub,gates.get(to,hub)])
	journey.append(destination)
	for point:Vector2 in journey:
		if point.distance_to(path[-1])>.00001:path.append(point)
	return path

func advance(delta:float)->void:
	for person:Dictionary in people:
		if not bool(person.moving):continue
		var remaining:=maxf(0,delta)*.004
		var path:PackedVector2Array=person.path
		while remaining>0 and int(person.segment)<path.size()-1:
			var end:Vector2=path[int(person.segment)+1];var at:Vector2=person.position
			var distance:=at.distance_to(end)
			if distance<=remaining:
				person.position=end;remaining-=distance;person.traveled+=distance;person.segment+=1
			else:
				person.position=at.move_toward(end,remaining);person.traveled+=remaining;remaining=0
		if int(person.segment)>=path.size()-1:person.position=person.target;person.moving=false

func direction(person:Dictionary)->Vector2:
	var path:PackedVector2Array=person.path
	if bool(person.moving) and int(person.segment)<path.size()-1:return (path[int(person.segment)+1]-Vector2(person.position)).normalized()
	# Work poses face the illustrated work surface to the right of each figure.
	return Vector2(.825,.565)

func population()->Array[Dictionary]:return people.duplicate(true)
