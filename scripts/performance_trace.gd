extends RefCounted
## Opt-in developer measurements; static transient data never enters saves.
static var enabled:=false
static var totals:Dictionary={}
static func start()->int:return Time.get_ticks_usec() if enabled else 0
static func mark(name:String,stamp:int)->int:
	if not enabled:return 0
	var now:=Time.get_ticks_usec()
	var record:Dictionary=totals.get_or_add(name,{"calls":0,"microseconds":0})
	record.calls+=1;record.microseconds+=now-stamp
	return now
static var counts:Dictionary={}
## Population accounting (developer probes only): exact people added or
## removed by kind|cause, and national population change by day step.
static var population_flow:Dictionary={}
static var population_steps:Dictionary={}
static func flow(kind:String,cause:String,amount:float)->void:
	if enabled and amount!=0.0:
		var key:="%s|%s" % [kind,cause]
		population_flow[key]=float(population_flow.get(key,0.0))+amount
static func count(name:String)->void:
	if enabled:counts[name]=int(counts.get(name,0))+1
