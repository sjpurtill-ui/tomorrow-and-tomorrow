extends RefCounted
## Five radial cells for one selected steel shaft, in normalized work/energy units.
## Fixed paid steps make saved temperature and transformation history replayable.
const STEP:=.05
const CELLS:=5
const TICKS:=100
const WORK:=TICKS*STEP
static func start(frequency:float=100.0,gap:float=1.0)->Dictionary:
	return {"frequency":frequency,"gap":gap,"tick":0,"temperatures":[20.0,20.0,20.0,20.0,20.0],
		"peaks":[20.0,20.0,20.0,20.0,20.0],"transformed":[false,false,false,false,false],"temper_ticks":[0,0,0,0,0],"trace":[]}
static func cost(tick:int)->Dictionary:
	return {"electricity":.6 if tick<20 else (.01 if tick<40 else (.2 if tick<60 else 0.0)),"water":.1 if tick>=20 and tick<40 else 0.0}
static func step(run:Dictionary)->void:
	var tick:=int(run.tick)
	if tick>=TICKS:return
	var before:Array=run.temperatures.duplicate()
	var after:Array=before.duplicate()
	# High frequency concentrates input at the surface; gap weakens coupling.
	var depth:=sqrt(100.0/float(run.frequency))*.7
	var weights:Array=[];var total:=0.0
	for cell:int in range(CELLS):
		var weight:=exp(-float(cell)/depth)
		weights.append(weight);total+=weight
	for cell:int in range(CELLS):
		var heat:=0.0
		if tick<20 and float(before[0])<900:
			heat=100.0*float(weights[cell])/total/(float(run.gap)*float(run.gap))
		if tick>=40 and tick<60:heat=maxf(0,minf(40,200.0-float(before[cell])))
		var conduction:=0.0
		if cell>0:conduction+=(float(before[cell-1])-float(before[cell]))*.025
		if cell<CELLS-1:conduction+=(float(before[cell+1])-float(before[cell]))*.025
		var loss:=(float(before[cell])-20.0)*(.22 if tick>=20 and tick<40 and cell==0 else (.1 if tick>=60 else .002))
		after[cell]=maxf(20,float(before[cell])+heat+conduction-loss)
		if tick>=40 and tick<60 and float(before[cell])>=150 and float(before[cell])<=250 and float(after[cell])>=150 and float(after[cell])<=250:run.temper_ticks[cell]+=1
		run.peaks[cell]=maxf(float(run.peaks[cell]),float(after[cell]))
		if tick>=20 and tick<40 and float(run.peaks[cell])>=800 and float(before[cell])>=300 and float(after[cell])<300 and (float(before[cell])-float(after[cell]))/STEP>=100:
			run.transformed[cell]=true
	run.temperatures=after;run.tick+=1
	run.trace.append({"temperatures":after.duplicate(),"paid":cost(tick)})
static func valid(run:Variant)->bool:
	if not run is Dictionary or not run.has_all(["frequency","gap","tick","temperatures","peaks","transformed","temper_ticks","trace"]):return false
	if not preload("res://scripts/metallurgy_thermal_cycle.gd").number(run.frequency) or float(run.frequency)<10 or float(run.frequency)>500:return false
	if not preload("res://scripts/metallurgy_thermal_cycle.gd").number(run.gap) or float(run.gap)<.5 or float(run.gap)>3:return false
	if not run.tick is int or run.tick<0 or run.tick>TICKS or not run.trace is Array or run.trace.size()>201:return false
	var replay:=start(float(run.frequency),float(run.gap))
	for event:Variant in run.trace:
		if not event is Dictionary:return false
		if event.has("idle_days"):
			if not event.idle_days is int or event.idle_days<=0 or event.idle_days>1000000:return false
			idle(replay,event.idle_days)
		else:
			if replay.tick>=TICKS:return false
			step(replay)
	return replay==run
static func indentation(run:Dictionary)->Dictionary:
	# A standardized normalized load produces a measured impression width.
	# This is a selected comparative test, not a certified hardness scale.
	var widths:Array=[]
	for cell:int in range(CELLS):
		var resistance:=2.0 if bool(run.transformed[cell]) else 1.0
		widths.append(snappedf(sqrt(1.0/resistance),.01))
	return {"method":"section_indentation_traverse","load":1.0,"depths":[0,1,2,3,4],"widths":widths,"uncertainty":.01,"tempered_surface":int(run.temper_ticks[0])>=10,"maximum_temperature":float(run.temperatures.max())}
static func accepted(report:Dictionary)->bool:
	return bool(report.tempered_surface) and float(report.maximum_temperature)<=150 and float(report.widths[0])+.01<.8 and float(report.widths[4])-.01>.9

static func idle(run:Dictionary,days:int)->void:
	if days<=0:return
	# Unpowered cooling is slow compared with the paid spray quench; it does
	# not qualify as a hardening transformation or contribute tempering time.
	var base:Array=run.temperatures.duplicate()
	if not run.trace.is_empty() and run.trace.back().has("idle_days"):
		days+=int(run.trace.back().idle_days)
		base=run.trace[-2].temperatures.duplicate() if run.trace.size()>1 else [20.0,20.0,20.0,20.0,20.0]
		run.trace.back().idle_days=days
	else:run.trace.append({"idle_days":days})
	for cell:int in range(CELLS):run.temperatures[cell]=20.0+(float(base[cell])-20.0)*exp(-2.0*float(days))
