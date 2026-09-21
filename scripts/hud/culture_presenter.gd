extends RefCounted
static func tendency(weights:Dictionary)->String:
	var strongest:=0.0
	for weight in weights.values():strongest=maxf(strongest,float(weight))
	if strongest<=0:return ""
	var labels:Array[String]=[]
	for key:String in weights:
		if is_equal_approx(float(weights[key]),strongest):labels.append(key.replace("_"," ").capitalize())
	return " / ".join(labels)
