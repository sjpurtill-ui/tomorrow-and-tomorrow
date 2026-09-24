extends RefCounted
## TEMPORARY INSTRUMENTATION (branch codex/terrain-cost-profile only).
## Counts and times noise-backed terrain/environment queries for
## docs/TERRAIN_COST_PROFILE.md. Disabled by default; transient, never saved.
## Remove before any production integration.
static var enabled:=false
static var counts:Dictionary={}
static var usec:Dictionary={}
## Outermost-only accumulator: nested noise queries are not double counted.
static var depth:=0
static var outer_usec:=0
## Outermost-only across primitives AND composite (river/geography) queries.
static var any_depth:=0
static var any_outer_usec:=0

static func enter()->int:
	if not enabled:return 0
	depth+=1;any_depth+=1
	return Time.get_ticks_usec()

static func leave(name:String,stamp:int)->void:
	if not enabled or stamp==0:return
	var elapsed:=Time.get_ticks_usec()-stamp
	depth-=1;any_depth-=1
	if any_depth==0:any_outer_usec+=elapsed
	counts[name]=int(counts.get(name,0))+1
	usec[name]=int(usec.get(name,0))+elapsed
	if depth==0:outer_usec+=elapsed

## Composite queries (reports/routes) are timed inclusively but do not count
## toward the primitive noise total, which they may contain.
static func enter_c()->int:
	if not enabled:return 0
	any_depth+=1
	return Time.get_ticks_usec()

static func leave_c(name:String,stamp:int)->void:
	if not enabled or stamp==0:return
	var elapsed:=Time.get_ticks_usec()-stamp
	any_depth-=1
	if any_depth==0:any_outer_usec+=elapsed
	counts[name]=int(counts.get(name,0))+1
	usec[name]=int(usec.get(name,0))+elapsed

static func count(name:String)->void:
	if enabled:counts[name]=int(counts.get(name,0))+1

static func reset()->void:
	counts={};usec={};depth=0;outer_usec=0;any_depth=0;any_outer_usec=0

static func snapshot()->Dictionary:
	return {"counts":counts.duplicate(),"usec":usec.duplicate(),"outer_usec":outer_usec,"any_outer_usec":any_outer_usec}
