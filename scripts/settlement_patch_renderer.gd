extends RefCounted
## Retained presentation only. A request replaces pending work for the same key;
## existing geometry stays attached until the latest replacement is complete.
## The time budget is cooperative: a single bounded builder is not preemptible.
var parent:Node3D
var desired:Dictionary={}
var installed:Dictionary={}
var pending:Array[String]=[]
var builds:=0
var reused:=0
var retired:=0
var last_slice_usec:=0
var max_job_usec:=0
var max_job_key:=""
var last_jobs:=0
const MAX_HIDDEN_PATCHES:=64
var request_serial:=0

func _init(root:Node3D)->void:
	parent=root

func request(records:Array[Dictionary])->void:
	request_serial+=1
	var next:Dictionary={}
	for record:Dictionary in records:
		var key:=String(record.key)
		next[key]=record
		if installed.has(key):
			installed[key].node.visible=true
			installed[key].seen=request_serial
		if installed.has(key) and installed[key].signature==record.signature:
			reused+=1
			continue
		if key not in pending:pending.append(key)
	desired=next
	var hidden:Array[String]=[]
	for key:String in installed:
		if desired.has(key):continue
		installed[key].node.visible=false
		hidden.append(key)
	hidden.sort_custom(func(a:String,b:String)->bool:return int(installed[a].seen)<int(installed[b].seen))
	while hidden.size()>MAX_HIDDEN_PATCHES:
		var key:String=hidden.pop_front()
		var old:Node3D=installed[key].node
		if is_instance_valid(old):parent.remove_child(old);old.queue_free()
		installed.erase(key);retired+=1
	pending=pending.filter(func(key:String)->bool:
		return desired.has(key) and (not installed.has(key) or installed[key].signature!=desired[key].signature))
	pending.sort_custom(func(a:String,b:String)->bool:
		var first:=float(desired[a].get("priority",0.0));var second:=float(desired[b].get("priority",0.0))
		return a<b if is_equal_approx(first,second) else first<second)

func process(budget_usec:int=4000,max_jobs:int=2)->void:
	var began:=Time.get_ticks_usec()
	last_jobs=0
	while not pending.is_empty() and last_jobs<maxi(0,max_jobs):
		if last_jobs>0 and Time.get_ticks_usec()-began>=budget_usec:break
		var key:String=pending.pop_front()
		if not desired.has(key):continue
		var record:Dictionary=desired[key]
		var replacement:=Node3D.new()
		replacement.name=String(record.get("name",key)).replace(":","_")
		replacement.set_meta("settlement_patch",true)
		replacement.set_meta("patch_key",key)
		var started:=Time.get_ticks_usec()
		(record.build as Callable).call(replacement)
		var build_usec:=Time.get_ticks_usec()-started
		if build_usec>max_job_usec:max_job_usec=build_usec;max_job_key=key
		parent.add_child(replacement)
		if installed.has(key):
			var old:Node3D=installed[key].node
			if is_instance_valid(old):parent.remove_child(old);old.queue_free()
		installed[key]={"node":replacement,"signature":record.signature,"seen":request_serial,"build_usec":build_usec,"parts":record.get("parts",{})}
		builds+=1;last_jobs+=1
	last_slice_usec=Time.get_ticks_usec()-began

func stats()->Dictionary:
	var keys:Dictionary={}
	for key:String in installed:
		keys[key]={"node_id":installed[key].node.get_instance_id(),"signature":installed[key].signature,"visible":installed[key].node.visible,"build_usec":installed[key].build_usec,"parts":installed[key].parts}
	var hidden:=0
	for key:String in installed:
		if not desired.has(key):hidden+=1
	return {"pending":pending.size(),"installed":installed.size(),"cached":hidden,"cache_limit":MAX_HIDDEN_PATCHES,"builds":builds,"reused":reused,"retired":retired,"last_slice_usec":last_slice_usec,"max_job_usec":max_job_usec,"max_job_key":max_job_key,"last_jobs":last_jobs,"keys":keys}
