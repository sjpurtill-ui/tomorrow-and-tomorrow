extends RefCounted
## Derive image scale from an independently imaged two-mark reference interval.
static func measure(reference:Dictionary)->Dictionary:
	var values:Variant=reference.get("pixels")
	var length:Variant=reference.get("interval_um")
	var uncertainty:Variant=reference.get("interval_uncertainty_um")
	if not values is Array or values.size()<16 or values.size()>128:return {}
	if not length is float or not is_finite(length) or length<=0:return {}
	if not uncertainty is float or not is_finite(uncertainty) or uncertainty<0:return {}
	var marks:Array=[];var start:=-1
	for index:int in range(values.size()+1):
		var dark:=false
		if index<values.size():
			var value:Variant=values[index]
			if not (value is float or value is int) or not is_finite(float(value)) or value<0 or value>1:return {}
			dark=float(value)<=.35
		if dark and start<0:start=index
		if not dark and start>=0:
			if start==0 or index==values.size() or index-start>3:return {}
			marks.append((float(start)+float(index-1))*.5);start=-1
	if marks.size()!=2:return {}
	var span:=float(marks[1])-float(marks[0])
	if span<10:return {}
	var relative:=float(uncertainty)/float(length)+.5/span
	if relative>.2:return {}
	return {"micrometres_per_pixel":float(length)/span,"calibration_uncertainty":relative,"mark_positions":marks}
static func reference_image(interval:float=20.0,uncertainty:float=.5)->Dictionary:
	var pixels:Array=[]
	for index:int in range(32):pixels.append(.1 if index in [5,25] else .9)
	return {"pixels":pixels,"interval_um":interval,"interval_uncertainty_um":uncertainty}
