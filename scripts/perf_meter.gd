extends RefCounted
## PERFORMANCE METER: how fast the live game runs, written to the player log
## once a minute while the calendar runs (never while paused), so the pace the
## player sees can be measured instead of guessed. One line:
##   PERF speed=5 days_per_s=2.61 fps=41 frame_ms p50=22 p95=31 max=180
##        sim_ms_per_frame=13.2 sim_ms_per_day=204 dock_refreshes=80 dock_ms=37
##        dock_max_ms=120 frames_over_33ms=3 long_sim=1 long_dock=1 long_other=1
## A frame over 33 ms is put down to the simulation when that ran most of
## it, to the dock when its refresh did, else to the rest (map, HUD, drawing).
## local_terrain.gd reports each frame (frame), the simulation it ran (sim) and
## each dock refresh (dock). Nothing here changes the game; it only counts.

const WINDOW_USEC:=60_000_000
const MAX_SAMPLES:=6000

static var _window_began:=0
static var _frames:=0
static var _frame_ms:PackedFloat32Array=PackedFloat32Array()
static var _sim_usec:=0
static var _dock_usec:=0
static var _dock_max_usec:=0
static var _dock_count:=0
static var _day_at_start:=-1.0
static var _speed:=0.0
static var _last_frame_usec:=0
static var _frame_dock_usec:=0
static var _long_sim:=0
static var _long_dock:=0
static var _long_other:=0

## One frame: its length in seconds, the speed it ran at, and the simulation
## that frame ran (microseconds).
static func frame(delta:float,speed:float,sim_usec:int=0)->void:
	var now:=Time.get_ticks_usec()
	var dock_usec:=_frame_dock_usec
	_frame_dock_usec=0
	if speed<=0.0:
		_reset(now)
		return
	if _window_began==0 or speed!=_speed:
		_reset(now)
		_speed=speed
		return
	_frames+=1
	if _frame_ms.size()<MAX_SAMPLES:_frame_ms.append(delta*1000.0)
	if delta>0.033:
		if float(sim_usec)>delta*1000000.0*0.4:_long_sim+=1
		elif float(dock_usec)>delta*1000000.0*0.3:_long_dock+=1
		else:_long_other+=1
	_last_frame_usec=now
	if now-_window_began>=WINDOW_USEC:
		print(line(now))
		_reset(now)

## Simulation run this frame, in microseconds.
static func sim(usec:int)->void:
	_sim_usec+=maxi(0,usec)

## One dock refresh check (a rebuild when the day changed), in microseconds.
static func dock(usec:int)->void:
	if usec<=0:return
	_dock_usec+=usec;_dock_count+=1;_dock_max_usec=maxi(_dock_max_usec,usec)
	_frame_dock_usec+=usec

## The summary line for the window so far.
static func line(now:int)->String:
	var seconds:=maxf(0.001,float(now-_window_began)/1_000_000.0)
	var days:=maxf(0.0,float(GameState.elapsed_days)-_day_at_start)
	var sorted:=_frame_ms.duplicate();sorted.sort()
	var p50:=sorted[sorted.size()/2] if not sorted.is_empty() else 0.0
	var p95:=sorted[int(sorted.size()*0.95)] if not sorted.is_empty() else 0.0
	var worst:=sorted[-1] if not sorted.is_empty() else 0.0
	var over:=0
	for ms in sorted:if ms>33.0:over+=1
	return "PERF speed=%d days_per_s=%.2f fps=%.0f frame_ms p50=%.0f p95=%.0f max=%.0f sim_ms_per_frame=%.1f sim_ms_per_day=%.0f dock_refreshes=%d dock_ms=%.0f dock_max_ms=%.0f frames_over_33ms=%d long_sim=%d long_dock=%d long_other=%d" % [
		roundi(_speed),days/seconds,float(_frames)/seconds,p50,p95,worst,
		float(_sim_usec)/1000.0/maxf(1.0,float(_frames)),float(_sim_usec)/1000.0/maxf(0.01,days),
		_dock_count,float(_dock_usec)/1000.0/maxf(1.0,float(_dock_count)),float(_dock_max_usec)/1000.0,over,_long_sim,_long_dock,_long_other]

static func _reset(now:int)->void:
	_window_began=now;_frames=0;_frame_ms=PackedFloat32Array()
	_sim_usec=0;_dock_usec=0;_dock_max_usec=0;_dock_count=0
	_long_sim=0;_long_dock=0;_long_other=0
	_day_at_start=float(GameState.elapsed_days)
