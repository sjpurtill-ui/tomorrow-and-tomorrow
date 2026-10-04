extends "res://tests/court_chapter_capture.gd"
## Same-camera court-only light comparisons. Use --reference --chapters=9
## --acting-review --quality=high on the private GPU runner.

func _capture_stage(stage:Control,label:String)->void:
	if not capture or not (label.ends_with("-audience") or label.ends_with("-speech-02")):return
	var destination:=ProjectSettings.globalize_path("res://reports/court_shadows/")
	DirAccess.make_dir_recursive_absolute(destination)
	var light:DirectionalLight3D=stage.court_set.sun
	var angular_size:=light.light_angular_distance
	var original_camera:Transform3D=stage.camera.transform
	var baseline:Dictionary={}
	for setting in ["baseline","high","low"]:
		stage.court_set.set_quality("high")
		if setting=="baseline":
			light.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			light.directional_shadow_max_distance=30.0
			light.directional_shadow_split_1=0.1
			light.directional_shadow_blend_splits=true
			light.light_angular_distance=1.2
		else:
			stage.court_set.set_quality(setting)
			light.light_angular_distance=angular_size
		await _frames(3)
		await RenderingServer.frame_post_draw
		var rendered:Image=stage.view3d.get_texture().get_image()
		rendered.save_png(destination+label+"-"+setting+".png")
		if not stage.camera.transform.is_equal_approx(original_camera):_fail("shadow comparison moved camera")
		print("COURT_SHADOW ",label," ",setting," mode=",light.directional_shadow_mode," reach=",light.directional_shadow_max_distance," split=",light.directional_shadow_split_1," camera=",stage.camera.transform)
		if label=="09-seated-speech-02":
			var measured:=_sill_edge(rendered)
			print("COURT_SHADOW_EDGE ",setting," ",measured)
			if setting=="baseline":baseline=measured
			else:
				if float(measured.rms)>float(baseline.rms)*0.4:_fail(setting+" did not resolve the sill's stair-step shadow")
				if float(measured.contrast)<float(baseline.contrast)*0.8:_fail(setting+" removed the shadow contrast")
	stage.court_set.set_quality("high")
	light.light_angular_distance=angular_size

func _luminance(pixel:Color)->float:
	return (pixel.r+pixel.g+pixel.b)/3.0

func _sill_edge(rendered:Image)->Dictionary:
	# The fixed chapter-09 speech camera sees a straight sill shadow across
	# this wall-only patch. Fit its projection slope, then measure deviations.
	# Retaining contrast rejects a false pass caused by disabling shadows.
	var heights:PackedFloat64Array=[]
	var sx:=0.0;var sy:=0.0;var sxx:=0.0;var sxy:=0.0;var contrast:=0.0
	for column in range(80,780):
		var best:=-INF;var edge:=390
		for row in range(390,499):
			var gradient:=_luminance(rendered.get_pixel(column,row+1))-_luminance(rendered.get_pixel(column,row))
			if gradient>best:best=gradient;edge=row
		heights.append(float(edge))
		var x:=float(column-80)
		sx+=x;sy+=edge;sxx+=x*x;sxy+=x*edge
		contrast+=_luminance(rendered.get_pixel(column,505))-_luminance(rendered.get_pixel(column,370))
	var n:=float(heights.size())
	var slope:=(n*sxy-sx*sy)/(n*sxx-sx*sx)
	var intercept:=(sy-slope*sx)/n
	var squared:=0.0
	for x in heights.size():squared+=pow(heights[x]-(slope*x+intercept),2.0)
	return {"rms":sqrt(squared/n),"contrast":contrast/n}
