extends RefCounted
## Selected external 30-tooth workpiece / 10-tooth cutter at a fixed crossing angle.
## Turns are retained alongside axial feed, not inferred from finished XYZ alone.
static func start()->Dictionary:
	return {"cutter_teeth":10,"workpiece_teeth":30,"crossing_angle":20.0,"cutter_turns":0.0,"workpiece_turns":0.0,"work":0.0,"axial":0.0}
static func advance(motion:Dictionary,work:float,axial:float,wear:float)->void:
	if work<=0:return
	motion.work+=work
	motion.cutter_turns+=2.0*work
	# Backlash grows with retained apparatus wear; synchronized command remains
	# distinct from the loaded workpiece's resulting phase.
	motion.workpiece_turns=-float(motion.cutter_turns)/3.0+wear*.01*float(motion.work)
	motion.axial=axial
static func phase_error(motion:Dictionary)->float:
	return absf(float(motion.workpiece_turns)+float(motion.cutter_turns)/3.0)
static func valid(motion:Variant,run:Dictionary,wear:float)->bool:
	var P=preload("res://scripts/machine_coordinate_program.gd")
	if not motion is Dictionary or motion.get("cutter_teeth")!=10 or motion.get("workpiece_teeth")!=30 or motion.get("crossing_angle")!=20.0:return false
	for key:String in ["cutter_turns","workpiece_turns","work","axial"]:
		if not P.finite(motion.get(key)):return false
	if absf(float(motion.work)-float(run.work))>.000001 or absf(float(motion.axial)-float(run.position.z))>.000001:return false
	if absf(float(motion.cutter_turns)-2.0*float(motion.work))>.000001:return false
	return absf(float(motion.workpiece_turns)+float(motion.cutter_turns)/3.0-wear*.01*float(motion.work))<.000001
