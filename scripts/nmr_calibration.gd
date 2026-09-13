extends RefCounted
## One reference-qualified bench channel. All numbers are synthetic game assay
## units, not magnet construction specifications or empirical chemical shifts.
const WORK=8.0
const VALID_DAYS=7
static func data()->Dictionary:
	return WorldSimulation.state.technology_operations.get("nmr_calibration",{})
static func start()->bool:
	var ops=load("res://scripts/technology_operations.gd")
	if ops.service("nmr_unqualified_time")<=0 or data().get("status")=="calibrating" or usable():return false
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	if float(stocks.get("NMR Methanol References",0))<1:return false
	stocks["NMR Methanol References"]=float(stocks["NMR Methanol References"])-1
	WorldSimulation.state.technology_operations.nmr_calibration={"status":"calibrating","work":0.0,"started_day":floori(WorldSimulation.state.elapsed_days),"last_day":floori(WorldSimulation.state.elapsed_days),"day_work":0.0}
	return true
static func advance()->void:
	var state:=data()
	if state.get("status")!="calibrating":return
	var ops=load("res://scripts/technology_operations.gd")
	var day:=floori(WorldSimulation.state.elapsed_days)
	if day<int(state.last_day):return
	if day>int(state.last_day):state.last_day=day;state.day_work=0.0
	var used:float=ops.consume_service("nmr_unqualified_time",minf(1.0-float(state.day_work),WORK-float(state.work)))
	state.day_work=float(state.day_work)+used
	state.work=float(state.work)+used
	if float(state.work)<WORK:return
	# Paid adjustment converges on this bounded synthetic bench configuration.
	# Acceptance is then measured from the reference trace, not the work counter.
	var response:Dictionary=load("res://scripts/nmr_signal_model.gd").acquire([{"position":10.0,"amplitude":1.0,"intrinsic_width":.05}],profile(),16,73)
	state.reference=assess(response)
	state.status="qualified" if bool(state.reference.get("accepted",false)) else "failed"
	state.checked_day=floori(WorldSimulation.state.elapsed_days)
static func profile()->Dictionary:
	return {"linewidth":.1,"noise":.0001,"gain":1.0,"shift_error":0.01,"temperature_drift":.1}
static func assess(response:Dictionary)->Dictionary:
	if not response.get("trace") is Array or response.trace.size()!=401:return {"accepted":false,"reason":"Missing reference trace."}
	for point:Variant in response.trace:
		if not (point is int or point is float) or not is_finite(float(point)):return {"accepted":false,"reason":"Invalid reference trace."}
	if not (response.get("noise_estimate") is int or response.get("noise_estimate") is float) or not is_finite(float(response.noise_estimate)) or float(response.noise_estimate)<=0:return {"accepted":false,"reason":"Missing reference sensitivity."}
	var peak:=80
	for index:int in range(81,121):
		if float(response.trace[index])>float(response.trace[peak]):peak=index
	var height:=float(response.trace[peak])
	var left:=peak;var right:=peak
	while left>80 and float(response.trace[left])>height*.5:left-=1
	while right<120 and float(response.trace[right])>height*.5:right+=1
	var width:=(right-left)*.05
	var shift:=peak*.1-10.0
	var snr:=height/float(response.noise_estimate)
	return {"accepted":absf(shift)<=.05 and width<=.3 and snr>=20.0,"shift_error":shift,"half_width":width,"snr":snr}
static func usable()->bool:
	var state:=data()
	return state.get("status")=="qualified" and int(WorldSimulation.state.elapsed_days)>=int(state.get("checked_day",-1)) and int(WorldSimulation.state.elapsed_days)-int(state.get("checked_day",-1))<=VALID_DAYS
static func valid(value:Variant)->bool:
	if not value is Dictionary or not value.has_all(["status","work","started_day","last_day","day_work"]):return false
	if value.status not in ["calibrating","qualified","failed"]:return false
	for key:String in ["work","started_day","last_day","day_work"]:
		if not (value[key] is int or value[key] is float) or not is_finite(float(value[key])) or float(value[key])<0:return false
	if float(value.work)>WORK or float(value.started_day)!=floorf(float(value.started_day)):return false
	if float(value.last_day)<float(value.started_day) or float(value.last_day)!=floorf(float(value.last_day)) or float(value.day_work)>1 or float(value.work)>float(value.last_day)-float(value.started_day)+1:return false
	if value.status=="calibrating":return float(value.work)<WORK
	if float(value.work)!=WORK or not value.get("reference") is Dictionary:return false
	if not (value.get("checked_day") is int or value.get("checked_day") is float) or not is_finite(float(value.checked_day)) or float(value.checked_day)<float(value.started_day) or float(value.checked_day)!=floorf(float(value.checked_day)):return false
	var ref:Dictionary=value.reference
	if not ref.get("accepted") is bool or bool(ref.accepted)!=(value.status=="qualified"):return false
	for key:String in ["shift_error","half_width","snr"]:
		if not (ref.get(key) is int or ref.get(key) is float) or not is_finite(float(ref[key])):return false
	return float(ref.half_width)>=0 and float(ref.snr)>=0 and (value.status!="qualified" or (absf(float(ref.shift_error))<=.05 and float(ref.half_width)<=.3 and float(ref.snr)>=20))
