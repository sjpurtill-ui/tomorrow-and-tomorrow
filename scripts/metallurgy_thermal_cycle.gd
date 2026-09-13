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
static func start(program:Array,heat_capacity:float=1.0,initial_temperature:float=20.0)->Dictionary:
	if not valid_program(program) or not number(heat_capacity) or heat_capacity<=0 or not number(initial_temperature) or initial_temperature<20 or initial_temperature>1800:return {}
	return {"program":program.duplicate(true),"capacity":heat_capacity,"temperature":initial_temperature,"initial_temperature":initial_temperature,"heat_loss":0.0,"idle_heat_loss":0.0,
		"stage":0,"stage_work":0.0,"work":0.0,"energy":0.0,"coolant":0.0,
		"peak":initial_temperature,"hot_work":0.0,"hold_streak":0.0,"longest_hold":0.0,"cooling_work":0.0,"trace":[]}
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
		run.heat_loss+=maxf(0,spent-capacity*(float(run.temperature)-before))
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
				"work":float(run.work),"energy":float(run.energy),"coolant":float(run.coolant),
				"heat_loss":float(run.heat_loss),"idle_heat_loss":float(run.idle_heat_loss),"hot_work":float(run.hot_work),"longest_hold":float(run.longest_hold)})
			run.stage+=1;run.stage_work=0.0;run.hold_streak=0.0
	return receipt
static func complete(run:Dictionary)->bool:
	return valid(run) and int(run.stage)==run.program.size()
static func idle(run:Dictionary,days:int)->void:
	if days<=0 or not valid(run):return
	var stage:=mini(int(run.stage),run.program.size()-1)
	var before:=float(run.temperature)
	run.temperature=20.0+(before-20.0)*exp(-float(run.program[stage].loss)*float(days)/float(run.capacity))
	var lost:=float(run.capacity)*(before-float(run.temperature))
	run.heat_loss+=lost;run.idle_heat_loss+=lost
	if float(run.temperature)<800 or float(run.temperature)>950:run.hold_streak=0.0
static func close_number(actual:float,expected:float)->bool:
	return absf(actual-expected)<=EPS*maxf(1.0,absf(expected))
static func balance(run:Dictionary,record:Dictionary)->bool:
	return close_number(float(record.energy)+float(run.capacity)*(float(run.initial_temperature)-20.0),float(run.capacity)*(float(record.temperature)-20.0)+float(record.heat_loss))
static func valid(run:Variant)->bool:
	if not run is Dictionary or not valid_program(run.get("program")):return false
	if not run.get("stage") is int or run.stage<0 or run.stage>run.program.size():return false
	for key:String in ["capacity","temperature","initial_temperature","heat_loss","idle_heat_loss","stage_work","work","energy","coolant","peak","hot_work","cooling_work","hold_streak","longest_hold"]:
		if not number(run.get(key)) or run[key]<0:return false
	if run.capacity<=0 or run.initial_temperature<20 or run.initial_temperature>1800 or run.temperature<20-EPS or run.temperature>1800 or run.peak>1800 or run.temperature>run.peak+EPS or run.initial_temperature>run.peak+EPS:return false
	if not balance(run,run) or run.idle_heat_loss>run.heat_loss+EPS:return false
	# Even after cooling, a retained peak must have been paid for or carried in.
	if float(run.capacity)*maxf(0,float(run.peak)-float(run.initial_temperature))>float(run.energy)+EPS:return false
	if run.hot_work>run.work+EPS or run.cooling_work>run.work+EPS:return false
	if not run.get("trace") is Array or run.trace.size()!=run.stage:return false
	var expected:=0.0;var coolant:=0.0;var energy_cap:=0.0;var loss_cap:=0.0;var hold_cap:=0.0
	var previous_energy:=0.0;var previous_loss:=0.0;var previous_idle:=0.0;var previous_hot:=0.0;var previous_hold:=0.0
	for index:int in range(run.stage):
		var spec:Dictionary=run.program[index]
		var duration:=float(spec.duration)
		expected+=duration;coolant+=duration*float(spec.coolant);energy_cap+=duration*float(spec.power)
		loss_cap+=duration*float(spec.loss)*maxf(0,float(run.peak)-20.0)
		if bool(spec.get("hold",false)):hold_cap=maxf(hold_cap,duration)
		var frame:Variant=run.trace[index]
		if not frame is Dictionary or frame.get("stage")!=index:return false
		for key:String in ["temperature","work","energy","coolant","heat_loss","idle_heat_loss","hot_work","longest_hold"]:
			if not number(frame.get(key)) or frame[key]<0:return false
		if frame.temperature<20-EPS or frame.temperature>run.peak+EPS or not close_number(float(frame.work),expected) or not close_number(float(frame.coolant),coolant) or not balance(run,frame):return false
		if frame.energy<previous_energy-EPS or frame.energy>energy_cap+EPS or frame.energy-previous_energy>duration*float(spec.power)+EPS:return false
		if frame.heat_loss<previous_loss-EPS or frame.idle_heat_loss<previous_idle-EPS or frame.idle_heat_loss>frame.heat_loss+EPS or frame.heat_loss-frame.idle_heat_loss>loss_cap+EPS:return false
		if frame.hot_work<previous_hot-EPS or frame.hot_work-previous_hot>duration+EPS:return false
		if frame.longest_hold<previous_hold-EPS or frame.longest_hold>hold_cap+EPS or frame.longest_hold>frame.hot_work+EPS:return false
		if not bool(spec.get("hold",false)) and not close_number(float(frame.longest_hold),previous_hold):return false
		previous_energy=frame.energy;previous_loss=frame.heat_loss;previous_idle=frame.idle_heat_loss;previous_hot=frame.hot_work;previous_hold=frame.longest_hold
	var partial_power:=0.0
	if run.stage<run.program.size():
		var spec:Dictionary=run.program[run.stage]
		if run.stage_work>=float(spec.duration)+EPS:return false
		partial_power=float(run.stage_work)*float(spec.power)
		coolant+=float(run.stage_work)*float(spec.coolant)
		loss_cap+=float(run.stage_work)*float(spec.loss)*maxf(0,float(run.peak)-20.0)
		if bool(spec.get("hold",false)):hold_cap=maxf(hold_cap,float(run.stage_work))
		elif run.hold_streak>EPS or not close_number(float(run.longest_hold),previous_hold):return false
	elif run.stage_work!=0 or run.hold_streak!=0 or not close_number(float(run.longest_hold),previous_hold):return false
	if run.energy<previous_energy-EPS or run.energy-previous_energy>partial_power+EPS or run.heat_loss<previous_loss-EPS or run.idle_heat_loss<previous_idle-EPS:return false
	if run.heat_loss-run.idle_heat_loss>loss_cap+EPS:return false
	if run.hot_work<previous_hot-EPS or run.hot_work-previous_hot>run.stage_work+EPS:return false
	if run.longest_hold<previous_hold-EPS or run.longest_hold>hold_cap+EPS or run.longest_hold>run.hot_work+EPS or run.hold_streak>run.longest_hold+EPS or run.hold_streak>run.stage_work+EPS:return false
	return close_number(float(run.work),expected+float(run.stage_work)) and close_number(float(run.coolant),coolant)
