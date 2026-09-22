extends RefCounted
## The calendar follows monotonic wall time, not the physics-clamped frame delta.
## Limit each frame to one calendar day so input/rendering get another turn.
const MAX_FRAME_DAYS:=1.0
const MAX_BACKLOG_SECONDS:=2.0
const SUSPEND_GAP_SECONDS:=10.0
var last_usec:int=-1
var last_rate:float=0.0
var pending_days:float=0.0

func reset(now_usec:int=-1)->void:
	last_usec=now_usec;pending_days=0.0;last_rate=0.0

func take_days(now_usec:int,days_per_second:float,interaction_active:bool=false)->float:
	var rate:=maxf(0.0,days_per_second)
	# Daily simulation is synchronous. Yield its work during direct navigation,
	# and discard wall-time debt rather than freezing the first frame afterward.
	# Simulation dates advance only when their full daily work can run.
	if interaction_active:
		last_usec=now_usec;last_rate=rate;pending_days=0.0
		return 0.0
	if last_usec<0 or rate!=last_rate:
		last_usec=now_usec;last_rate=rate;pending_days=0.0
		return 0.0
	var seconds:=maxf(0.0,float(now_usec-last_usec)/1000000.0)
	last_usec=now_usec
	if rate<=0.0 or seconds>SUSPEND_GAP_SECONDS:
		pending_days=0.0
		return 0.0
	pending_days=minf(pending_days+seconds*rate,maxf(MAX_FRAME_DAYS,rate*MAX_BACKLOG_SECONDS))
	var days:=minf(pending_days,MAX_FRAME_DAYS)
	pending_days-=days
	return days
