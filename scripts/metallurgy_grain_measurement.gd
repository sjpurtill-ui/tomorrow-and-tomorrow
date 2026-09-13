extends RefCounted
## Measures resolved boundary bands in a retained calibrated reflected-light field.
## No access to the source material's latent grain-size parameter.
const Scale=preload("res://scripts/metallurgy_scale.gd")
const MIN_SIZE:=16
const MAX_SIZE:=64
static func finite(v:Variant,low:float,high:float)->bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v)>=low and float(v)<=high
static func valid_frame(frame:Variant)->bool:
	if not frame is Dictionary:return false
	if frame.get("illumination")!="reflected" or frame.get("preparation")!="polished_etched":return false
	if not frame.get("source_id") is String or frame.source_id.is_empty() or frame.source_id.length()>128:return false
	if not frame.get("section_id") is int or frame.section_id<=0:return false
	if not finite(frame.get("micrometres_per_pixel"),.01,1000):return false
	if not finite(frame.get("calibration_uncertainty"),0,.2):return false
	if not frame.get("scale_reference") is Dictionary:return false
	var calibration:=Scale.measure(frame.scale_reference)
	if calibration.is_empty() or frame.micrometres_per_pixel!=calibration.micrometres_per_pixel or frame.calibration_uncertainty!=calibration.calibration_uncertainty:return false
	var rows:Variant=frame.get("pixels")
	if not rows is Array or rows.size()<MIN_SIZE or rows.size()>MAX_SIZE:return false
	if not rows[0] is Array or rows[0].size()<MIN_SIZE or rows[0].size()>MAX_SIZE:return false
	for row:Variant in rows:
		if not row is Array or row.size()!=rows[0].size():return false
		for pixel:Variant in row:
			if not finite(pixel,0,1):return false
	return true
static func measure(frame:Dictionary)->Dictionary:
	if not valid_frame(frame):return {}
	var pixels:Array=frame.pixels
	var height:=pixels.size();var width:int=pixels[0].size()
	var scale:=float(frame.micrometres_per_pixel)
	var lines:Array=[];var total_length:=0.0;var total_crossings:=0
	for vertical:bool in [false,true]:
		var extent:=height if vertical else width
		var across:=width if vertical else height
		for fraction:float in [.25,.5,.75]:
			var coordinate:=int(floor(float(across-1)*fraction))
			var crossings:Array=[];var in_band:=false;var band_start:=-1
			for point:int in range(extent):
				var value:float=pixels[point][coordinate] if vertical else pixels[coordinate][point]
				var dark:=value<=.35
				if dark and not in_band:band_start=point
				if not dark and in_band:
					# Exclude bands clipped by a field edge and broad unresolved marks.
					if band_start>0 and point-band_start<=3:
						var middle:=(float(band_start)+float(point-1))/2.0
						crossings.append(middle)
				in_band=dark
			var length:=float(extent-1)*scale
			lines.append({"orientation":"vertical" if vertical else "horizontal",
				"coordinate":coordinate,"length_um":length,"crossings_px":crossings})
			total_length+=length;total_crossings+=crossings.size()
	var qualified:=total_crossings>=12
	var mean:=total_length/maxi(1,total_crossings)
	return {"source_id":frame.source_id,"section_id":frame.section_id,
		"method":"resolved_boundary_line_intercepts","lines":lines,
		"total_length_um":total_length,"crossings":total_crossings,
		"qualified":qualified,"mean_intercept_um":mean if qualified else 0.0,
		"resolution_um":scale,"calibration_uncertainty":frame.calibration_uncertainty,
		"uncertainty_um":mean*float(frame.calibration_uncertainty)+2.0*scale if qualified else 0.0,
		"scope":"One prepared field; not whole-lot grain size, phase identity or strength."}
