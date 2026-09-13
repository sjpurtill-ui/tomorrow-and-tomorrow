extends RefCounted
## Lumped selected-specimen thermal model in game work/energy units.
## This runner owns no stocks or services. Its caller must pay each receipt.
const EPS:=0.000001
const MAX_STAGES:=12
static func number(v:Variant,cap:float=1000000.0)->bool:
	return (v is int or v is float) and is_finite(float(v)) and absf(float(v))<=cap
static func normalizing_program()->Array:
	return [
		{"duration":3.0,"target":880.0,"power":500.0,"loss":.05,"coolant":0.0},
		{"duration":1.0,"target":880.0,"power":100.0,"loss":.05,"coolant":0.0,"hold":true},
		{"duration":3.0,"target":20.0,"power":0.0,"loss":.8,"coolant":0.0}]
static func valid_program(program:Variant)->bool:
	if not program is Array or program.is_empty() or program.size()>MAX_STAGES:return false
	for stage:Variant in program:
		if not stage is Dictionary:return false
		for key:String in ["duration","target","power","loss","coolant"]:
			if not number(stage.get(key)) or stage[key]<0:return false
		if stage.has("hold") and not stage.hold is bool:return false
		if stage.duration<=0 or stage.duration>100 or stage.target>1800 or stage.loss>100:return false
	return true
static func start(program:Array,heat_capacity:float=1.0)->Dictionary:
	if not valid_program(program) or not number(heat_capacity) or heat_capacity<=0:return {}
	return {"program":program.duplicate(true),"capacity":heat_capacity,"temperature":20.0,
		"stage":0,"stage_work":0.0,"work":0.0,"energy":0.0,"coolant":0.0,
		"peak":20.0,"hot_work":0.0,"hold_streak":0.0,"longest_hold":0.0,"cooling_work":0.0,"trace":[]}
static func advance(run:Dictionary,work:float,energy:float,coolant:float)->Dictionary:
	var receipt:={"work":0.0,"energy":0.0,"coolant":0.0}
	if not valid(run) or not number(work) or not number(energy) or not number(coolant) or minf(work,minf(energy,coolant))<0:return receipt
	while work>EPS and int(run.stage)<run.program.size():
		var spec:Dictionary=run.program[int(run.stage)]
		var used:=minf(work,minf(.1,float(spec.duration)-float(run.stage_work)))
		# Conservatively reserve available power before computing thermostat use.
		if float(spec.power)>0:used=minf(used,energy/float(spec.power))
		if float(spec.coolant)>0:used=minf(used,coolant/float(spec.coolant))
		if used<=EPS:break
		var before:=float(run.temperature)
		var capacity:=float(run.capacity)
		var loss:=float(spec.loss)
		var power:=float(spec.power)
		var passive:=before
		var gain:=used/capacity
		if loss>0:
			var decay:=exp(-loss*used/capacity)
			passive=20.0+(before-20.0)*decay
			gain=(1.0-decay)/loss
		# A thermostat supplies only the energy needed to reach/hold its target.
		var supplied:=minf(power,maxf(0,(float(spec.target)-passive)/gain))
		run.temperature=passive+supplied*gain
		var spent:=supplied*used
		var fluid:=float(spec.coolant)*used
		run.stage_work+=used;run.work+=used;run.energy+=spent;run.coolant+=fluid
		run.peak=maxf(float(run.peak),float(run.temperature))
		if before>=800 and float(run.temperature)>=800:run.hot_work+=used
		if bool(spec.get("hold",false)) and before>=800 and before<=950 and float(run.temperature)>=800 and float(run.temperature)<=950:
			run.hold_streak+=used
			run.longest_hold=maxf(float(run.longest_hold),float(run.hold_streak))
		else:run.hold_streak=0.0
		if float(run.temperature)<before:run.cooling_work+=used
		receipt.work+=used;receipt.energy+=spent;receipt.coolant+=fluid
		work-=used;energy-=spent;coolant-=fluid
		if float(run.stage_work)+EPS>=float(spec.duration):
			run.trace.append({"stage":int(run.stage),"temperature":float(run.temperature),
				"work":float(run.work),"energy":float(run.energy),"coolant":float(run.coolant)})
			run.stage+=1;run.stage_work=0.0;run.hold_streak=0.0
	return receipt
static func complete(run:Dictionary)->bool:
	return valid(run) and int(run.stage)==run.program.size()
static func valid(run:Variant)->bool:
	if not run is Dictionary or not valid_program(run.get("program")):return false
	if not run.get("stage") is int or run.stage<0 or run.stage>run.program.size():return false
	for key:String in ["capacity","temperature","stage_work","work","energy","coolant","peak","hot_work","cooling_work","hold_streak","longest_hold"]:
		if not number(run.get(key)) or run[key]<0:return false
	if run.capacity<=0 or run.temperature>1800 or run.peak>1800 or run.temperature>run.peak+EPS:return false
	var longest_stage:=0.0
	for spec:Dictionary in run.program:
		if bool(spec.get("hold",false)):longest_stage=maxf(longest_stage,float(spec.duration))
	if run.hold_streak>run.longest_hold+EPS or run.longest_hold>longest_stage+EPS or run.longest_hold>run.hot_work+EPS:return false
	if run.hot_work>run.work+EPS or run.cooling_work>run.work+EPS:return false
	if not run.get("trace") is Array or run.trace.size()!=run.stage:return false
	var expected:=0.0;var previous_energy:=0.0;var previous_coolant:=0.0
	for index:int in range(run.stage):
		expected+=float(run.program[index].duration)
		var frame:Variant=run.trace[index]
		if not frame is Dictionary or frame.get("stage")!=index:return false
		for key:String in ["temperature","work","energy","coolant"]:
			if not number(frame.get(key)) or frame[key]<0:return false
		if frame.temperature>run.peak+EPS or absf(float(frame.work)-expected)>EPS:return false
		if frame.energy<previous_energy or frame.coolant<previous_coolant:return false
		previous_energy=frame.energy;previous_coolant=frame.coolant
	if run.stage<run.program.size():
		if run.stage_work>=float(run.program[run.stage].duration)+EPS:return false
	elif run.stage_work!=0:return false
	return absf(float(run.work)-expected-float(run.stage_work))<=EPS and previous_energy<=run.energy+EPS and previous_coolant<=run.coolant+EPS
