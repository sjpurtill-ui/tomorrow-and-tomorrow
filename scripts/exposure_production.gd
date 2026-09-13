extends RefCounted
## Exposure jobs use the existing workshop queue and civilization clock.
const Ops=preload("res://scripts/technology_operations.gd")
const KEYS=["exposure_started_day","exposure_last_day","exposure_day_work"]
static func clear(job:Dictionary)->void:
	for key:String in KEYS:job.erase(key)
static func advance(job:Dictionary,spec:Dictionary,work:float)->void:
	var s=WorldSimulation.state
	var day:=floori(s.elapsed_days)
	var duration:=float(spec.exposure_days)
	if not job.has("exposure_started_day"):
		if work<.1:return
		for resource:String in spec.materials:
			if float(s.resource_stockpiles.get(resource,0))<float(spec.materials[resource]):return
		for resource:String in spec.materials:
			s.resource_stockpiles[resource]=float(s.resource_stockpiles.get(resource,0))-float(spec.materials[resource])
			job.last_consumed[resource]=float(spec.materials[resource])
		job.exposure_started_day=day;job.exposure_last_day=day;job.exposure_day_work=0.0
		job.last_work=.1
		return
	if day<=int(job.exposure_started_day) or day<int(job.exposure_last_day):return
	if day!=int(job.exposure_last_day):job.exposure_last_day=day;job.exposure_day_work=0.0
	var possible:=minf(work,minf(1.0-float(job.exposure_day_work),duration-float(job.progress_days)))
	var daily_power:=float(spec.get("power",0))/duration
	if daily_power>0:possible=minf(possible,Ops.service("electricity")/daily_power)
	possible=maxf(0,possible)
	if possible<=0:return
	if daily_power>0:Ops.consume_electricity(possible*daily_power)
	job.exposure_day_work=float(job.exposure_day_work)+possible
	job.progress_days=float(job.progress_days)+possible;job.last_work=possible
	if float(job.progress_days)+.000000001<duration:return
	s.resource_stockpiles[String(spec.output)]=float(s.resource_stockpiles.get(String(spec.output),0))+1.0
	job.completed=int(job.completed)+1;job.last_output=1;job.progress_days=0.0
	clear(job)
static func validate(job:Dictionary,spec:Dictionary)->String:
	var count:=0
	for key:String in KEYS:
		if not job.has(key):continue
		count+=1
		var value:Variant=job[key]
		if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0:return "Invalid exposure progress."
	if count==0:return ""
	if count!=KEYS.size() or not spec.has("exposure_days"):return "Invalid exposure recipe."
	if float(job.exposure_day_work)>1 or float(job.exposure_started_day)!=floorf(float(job.exposure_started_day)) or float(job.exposure_last_day)!=floorf(float(job.exposure_last_day)) or float(job.exposure_last_day)<float(job.exposure_started_day):return "Invalid exposure day."
	if float(job.progress_days)>float(job.exposure_last_day)-float(job.exposure_started_day)+.000001:return "Impossible exposure duration."
	return ""
