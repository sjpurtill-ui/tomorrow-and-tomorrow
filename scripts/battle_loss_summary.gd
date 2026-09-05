class_name BattleLossSummary
extends RefCounted

static func from_rounds(records:Array,side:int,remaining:int)->Dictionary:
	var key:="attacker" if side==0 else "defender"
	var result:Dictionary={"dead":0,"wounded":0,"disabled":0,"scattered":0,"unclassified":0,"disability_recorded":true,"remaining":remaining}
	for round_record:Dictionary in records:
		var losses:=int(round_record.get(key+"_losses",0))
		var casualties:Dictionary=round_record.get(key+"_casualties",{})
		result.dead+=int(casualties.get("killed",0)); result.wounded+=int(casualties.get("wounded",0))
		result.scattered+=int(casualties.get("scattered",0))
		result.disabled+=int(casualties.get("disabled",0))
		result.unclassified+=maxi(0,losses-int(casualties.get("killed",0))-int(casualties.get("wounded",0))-int(casualties.get("scattered",0)))
		if int(casualties.get("wounded",0))>0 and not casualties.has("disabled"): result.disability_recorded=false
	result["casualties"]=int(result.dead)+int(result.wounded)
	result["out_of_action"]=int(result.casualties)+int(result.scattered)+int(result.unclassified)
	result["starting"]=remaining+int(result.out_of_action)
	return result
