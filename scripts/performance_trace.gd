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
