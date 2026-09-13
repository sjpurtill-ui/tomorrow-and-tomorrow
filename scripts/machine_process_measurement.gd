extends RefCounted
## Bounded game error measures, not manufacturing tolerances in physical units.
## Distinct error channels are retained for the particular process and workpiece.
static func produced(kind:String,run:Dictionary,wear:float)->Dictionary:
	var feed:=0.0
	for instruction:Dictionary in run.program:feed=maxf(feed,float(instruction.feed))
	var travel:=float(run.distance)
	match kind:
		"skiving":return {"pitch_error":.08+wear*.7,"flank_error":.1+feed*.12+wear*.4}
		"wire_edm":return {"kerf_error":.1+feed*.15+wear*.35,"recast_layer":.08+float(run.energy)/maxf(1,travel)*.03+wear*.3}
		"sinker_edm":return {"cavity_error":.1+wear*.5,"electrode_loss":.05+float(run.energy)*.025+wear*.4}
		"ecm":return {"profile_error":.08+feed*.12+wear*.3,"overcut":.05+float(run.energy)/maxf(1,travel)*.03+wear*.5}
		"waterjet":return {"kerf_taper":.1+feed*.1+wear*.6,"edge_roughness":.1+feed*.16+wear*.5}
		"ultrasonic":return {"hole_error":.1+wear*.5,"edge_chipping":.08+feed*.2+wear*.6}
		"forming":return {"thinning":.1+absf(float(run.position.z))*.12+wear*.3,"springback":.08+travel*.03+wear*.6}
		"joining":return {"unbonded_fraction":.15+wear*.6,"joint_damage":.05+float(run.energy)*.02+wear*.4}
	return {}
static func observed(physical:Dictionary,uncertainty:float)->Dictionary:
	return {"readings":physical.duplicate(true),"uncertainty":uncertainty}
static func accepted(observation:Dictionary,limits:Dictionary)->bool:
	if observation.get("readings",{}).size()!=limits.size():return false
	for key:String in limits:
		if not observation.readings.has(key) or float(observation.readings[key])+float(observation.uncertainty)>float(limits[key]):return false
	return true
