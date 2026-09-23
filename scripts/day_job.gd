extends RefCounted
## An ordered, resumable world day. Groups run in sequence under their owner's
## scope; steps never hold a scope across a yield, so the frame loop, input and
## UI callbacks always observe the human scope between steps.
##
## A step is {"label", "call", "timings"}. Its callable may return an Array of
## further steps, which run immediately next (inside the same group). Setting
## run.halt drops the group's remaining planned steps after those insertions.

var groups:Array[Dictionary]=[]
var steps_run:=0
var longest_step_usec:=0
var last_step:={}
## Steps at least this long are recorded while performance tracing is on.
const SLOW_STEP_USEC:=40000
static var slow_steps:Array=[]
var result:Dictionary={}

static func step(label:String,timings:Dictionary,call:Callable)->Dictionary:
	return {"label":label,"call":call,"timings":timings}

## Converts [label, callable] parts to steps. A part may return an Array of
## further parts, which run immediately after it.
static func from_parts(parts:Array,timings:Dictionary={})->Array:
	var result:Array=[]
	for part:Array in parts:
		var call:Callable=part[1]
		result.append(step(String(part[0]),timings,func()->Variant:
			var more:Variant=call.call()
			return from_parts(more,timings) if more is Array else null
		))
	return result

## Runs [label, callable] parts synchronously in the same order as from_parts.
static func run_parts(parts:Array)->void:
	for part:Array in parts:
		var more:Variant=(part[1] as Callable).call()
		if more is Array:run_parts(more)

func add_group(owner:String,steps:Array,run:Dictionary={},done:Callable=Callable())->void:
	groups.append({"owner":owner,"steps":steps,"run":run,"done":done})

func finished()->bool:
	return groups.is_empty()

## Runs at least one step, then continues until the budget is spent.
## Returns true when every group has completed.
func run_for(budget_usec:int)->bool:
	var deadline:=Time.get_ticks_usec()+maxi(0,budget_usec)
	while not groups.is_empty():
		step_once()
		if Time.get_ticks_usec()>=deadline:break
	return groups.is_empty()

func run_all()->void:
	while not groups.is_empty():step_once()

func step_once()->void:
	var group:Dictionary=groups[0]
	var steps:Array=group.steps
	if steps.is_empty():
		_finish_group()
		return
	var next:Dictionary=steps.pop_front()
	var start:=Time.get_ticks_usec()
	var inserted:Variant=WorldSimulation.scoped(String(group.owner),next.call)
	var elapsed:=Time.get_ticks_usec()-start
	steps_run+=1
	longest_step_usec=maxi(longest_step_usec,elapsed)
	last_step={"owner":String(group.owner),"label":String(next.label),"usec":elapsed}
	if elapsed>=SLOW_STEP_USEC and preload("res://scripts/performance_trace.gd").enabled:slow_steps.append(last_step)
	var timings:Dictionary=next.timings
	if not timings.is_empty():
		var record:Dictionary=timings.get(String(next.label),{"calls":0,"microseconds":0})
		record.calls+=1;record.microseconds+=elapsed;timings[String(next.label)]=record
	var run:Dictionary=group.run
	if bool(run.get("halt",false)):
		run.erase("halt")
		steps.clear()
	if inserted is Array and not inserted.is_empty():
		var combined:Array=inserted.duplicate()
		combined.append_array(steps)
		group.steps=combined
	if (group.steps as Array).is_empty():_finish_group()

func _finish_group()->void:
	var group:Dictionary=groups.pop_front()
	if (group.done as Callable).is_valid():WorldSimulation.scoped(String(group.owner),group.done)
