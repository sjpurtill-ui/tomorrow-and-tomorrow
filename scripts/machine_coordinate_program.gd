extends RefCounted
## Retained coordinate execution in bounded game length/work units.
## Callers own apparatus, stocks and service debits; this module cannot grant output.
const LIMIT:=64
static func finite(v:Variant,cap:float=10000.0)->bool:
	return (v is int or v is float) and is_finite(float(v)) and absf(float(v))<=cap
static func valid_program(program:Variant)->bool:
	if not program is Array or program.is_empty() or program.size()>LIMIT:return false
	for instruction:Variant in program:
		if not instruction is Dictionary or instruction.size()!=4:return false
		for key:String in ["x","y","z"]:
			if not finite(instruction.get(key)):return false
		if not finite(instruction.get("feed"),100) or instruction.feed<=0:return false
	return true
static func start(program:Array)->Dictionary:
	if not valid_program(program):return {}
	return {"program":program.duplicate(true),"cursor":0,"position":{"x":0.0,"y":0.0,"z":0.0},"distance":0.0,"work":0.0,"energy":0.0,"trace":[]}
static func distance(a:Dictionary,b:Dictionary)->float:
	return sqrt(pow(float(a.x)-float(b.x),2)+pow(float(a.y)-float(b.y),2)+pow(float(a.z)-float(b.z),2))
static func advance(run:Dictionary,work:float,energy:float,energy_per_work:float)->Dictionary:
	var receipt:={"work":0.0,"energy":0.0,"distance":0.0}
	if not valid(run) or not finite(work) or not finite(energy) or not finite(energy_per_work) or work<=0 or energy<0 or energy_per_work<=0:return receipt
	var budget:=minf(work,energy/energy_per_work)
	while budget>0 and int(run.cursor)<run.program.size():
		var target:Dictionary=run.program[int(run.cursor)]
		var remaining:=distance(run.position,target)
		if remaining<=.00000001:
			run.position={"x":float(target.x),"y":float(target.y),"z":float(target.z)}
			run.trace.append({"instruction":int(run.cursor),"position":run.position.duplicate(true),"work":float(run.work),"energy":float(run.energy)})
			run.cursor+=1;continue
		var used:=minf(budget,remaining/float(target.feed))
		var moved:=used*float(target.feed)
		var fraction:=minf(1,moved/remaining)
		for axis:String in ["x","y","z"]:run.position[axis]=lerpf(float(run.position[axis]),float(target[axis]),fraction)
		run.distance+=moved;run.work+=used;run.energy+=used*energy_per_work
		receipt.work+=used;receipt.energy+=used*energy_per_work;receipt.distance+=moved
		budget-=used
		if remaining-moved<=.00000001:
			run.trace.append({"instruction":int(run.cursor),"position":run.position.duplicate(true),"work":float(run.work),"energy":float(run.energy)})
			run.cursor+=1
	return receipt
static func complete(run:Dictionary)->bool:
	return valid(run) and int(run.cursor)==run.program.size()
static func valid(run:Variant)->bool:
	if not run is Dictionary or not valid_program(run.get("program")) or not run.get("cursor") is int:return false
	if run.cursor<0 or run.cursor>run.program.size() or not run.get("position") is Dictionary:return false
	for axis:String in ["x","y","z"]:
		if not finite(run.position.get(axis)):return false
	for key:String in ["distance","work","energy"]:
		if not finite(run.get(key),1e9) or run[key]<0:return false
	if not run.get("trace") is Array or run.trace.size()!=run.cursor:return false
	var previous_work:=0.0;var previous_energy:=0.0
	for index:int in range(run.trace.size()):
		var frame:Variant=run.trace[index]
		if not frame is Dictionary or frame.get("instruction")!=index or not frame.get("position") is Dictionary:return false
		for axis:String in ["x","y","z"]:
			if not finite(frame.position.get(axis)) or absf(float(frame.position[axis])-float(run.program[index][axis]))>.000001:return false
		if not finite(frame.get("work"),1e9) or not finite(frame.get("energy"),1e9) or frame.work<previous_work or frame.energy<previous_energy:return false
		previous_work=frame.work;previous_energy=frame.energy
	var origin:={"x":0.0,"y":0.0,"z":0.0}
	var expected_distance:=0.0;var expected_work:=0.0
	for index:int in range(int(run.cursor)):
		var endpoint:Dictionary=run.program[index]
		var length:=distance(origin,endpoint)
		expected_distance+=length;expected_work+=length/float(endpoint.feed)
		if absf(float(run.trace[index].work)-expected_work)>.000001:return false
		origin=endpoint
	if int(run.cursor)<run.program.size():
		var target:Dictionary=run.program[int(run.cursor)]
		var partial:=distance(origin,run.position)
		if absf(partial+distance(run.position,target)-distance(origin,target))>.000001:return false
		expected_distance+=partial;expected_work+=partial/float(target.feed)
	elif distance(origin,run.position)>.000001:return false
	if absf(expected_distance-float(run.distance))>.000001 or absf(expected_work-float(run.work))>.000001:return false
	return previous_work<=float(run.work) and previous_energy<=float(run.energy)
