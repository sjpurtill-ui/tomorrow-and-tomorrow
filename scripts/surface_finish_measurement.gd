extends RefCounted
## Selected finish profiles in normalized game metrology units.
## Inspection measures the retained samples, not a hidden pass/fail label.
static func produced(kind:String,run:Dictionary,wear:float)->Dictionary:
	var strokes:=0
	var previous:=0.0;var direction:=0
	for command:Dictionary in run.program:
		var change:=float(command.z)-previous
		var next:=int(sign(change))
		if next!=0 and next!=direction:strokes+=1
		if next!=0:direction=next
		previous=float(command.z)
	var amplitude:=.12+.7*wear+.3/float(maxi(1,strokes))
	var surface:Array=[]
	for index:int in range(32):
		surface.append(amplitude*sin(float(index)*TAU/7.0)+amplitude*.25*sin(float(index)*TAU/3.0))
	var stations:Array=[]
	for station:int in range(3):
		var around:Array=[]
		for angle:int in range(8):
			around.append(.2+float(station)*(.03+.2*wear)+(.04+.15*wear)*cos(float(angle)*TAU/4.0))
		stations.append(around)
	return {"kind":kind,"surface_trace":surface,"diameter_stations":stations,
		"strokes":strokes,"rotation_turns":float(run.work)*5.0}
static func observed(physical:Dictionary,spec:Dictionary)->Dictionary:
	var method:Dictionary=spec.machine_observation
	var resolution:=float(method.resolution)
	var surface:Array=[];var mean:=0.0
	for value:float in physical.surface_trace:
		var read:=snappedf(value,resolution);surface.append(read);mean+=read
	mean/=float(surface.size())
	var roughness:=0.0
	for value:float in surface:roughness+=absf(value-mean)
	roughness/=float(surface.size())
	var station_means:Array=[];var station_readings:Array=[];var roundness:=0.0
	for station:Array in physical.diameter_stations:
		var sum:=0.0;var low:=INF;var high:=-INF;var readings:Array=[]
		for value:float in station:
			var read:=snappedf(value,resolution);readings.append(read)
			sum+=read;low=minf(low,read);high=maxf(high,read)
		station_readings.append(readings);station_means.append(sum/float(station.size()))
		roundness=maxf(roundness,high-low)
	var taper:=absf(float(station_means.back())-float(station_means.front()))
	var readings:={"roughness_error":roughness,"roundness_error":roundness,"taper_error":taper}
	return {"method":String(method.method),"readings":readings,"resolution":resolution,
		"uncertainty":float(method.uncertainty),"apparatus":spec.machine_inspection_tools.duplicate(true),
		"surface_samples":surface,"diameter_samples":station_readings}
