extends RefCounted
## Selected forge-welded strap: local heat, upsetting, cooling and witness tests.
## Normalized responses, not arbitrary alloy weld qualification.
static func evidence(work:float,cooling:float)->Dictionary:
	var temperatures:Array=[20.0,20.0,20.0]
	var peaks:Array=temperatures.duplicate();var trace:Array=[]
	var bond:=0.0;var oxide:=.12;var rapid_cooling:=0.0
	var remaining:=minf(work,5.0);var elapsed:=0.0
	while remaining>.000001:
		var used:=minf(.05,remaining)
		var before:Array=temperatures.duplicate()
		var heating:=elapsed+.000001<3.0
		for zone:int in range(3):
			var heat:=minf(2600.0,maxf(0,(1250-float(before[zone]))/used)) if heating and zone==0 else 0.0
			var exchange:=0.0
			if zone>0:exchange+=(float(before[zone-1])-float(before[zone]))*.8
			if zone<2:exchange+=(float(before[zone+1])-float(before[zone]))*.8
			var loss:=(float(before[zone])-20.0)*(.05 if heating else cooling)
			temperatures[zone]=maxf(20,float(before[zone])+(heat+exchange-loss)*used)
			peaks[zone]=maxf(float(peaks[zone]),float(temperatures[zone]))
			if not heating and zone==1 and float(before[zone])>500:rapid_cooling=maxf(rapid_cooling,(float(before[zone])-float(temperatures[zone]))/used)
		if elapsed+.000001>=2.0 and elapsed+.000001<3.0 and float(temperatures[0])>=1100:
			bond=minf(1,bond+used*1.2);oxide=maxf(0,oxide-used*.15)
		elapsed+=used;remaining-=used
		if elapsed+0.000001>=float(trace.size()+1)*.5:trace.append({"work":elapsed,"temperatures":temperatures.duplicate()})
	return {"work":minf(work,5.0),"temperatures":temperatures,"peaks":peaks,"bond":bond,"oxide":oxide,"rapid_cooling":rapid_cooling,"trace":trace}
static func witness(e:Dictionary)->Dictionary:
	var pixels:Array=[]
	var gap_pixels:=int(round((1-float(e.bond)+float(e.oxide))*20))
	for index:int in range(20):pixels.append(0.0 if index<gap_pixels else 1.0)
	var hardening:=clampf((float(e.rapid_cooling)-800.0)/500.0,0,1)
	var indentations:Array=[snappedf(.9,.01),snappedf(.9-.25*hardening,.01),snappedf(.9,.01)]
	var bends:Array=[]
	for angle:int in [15,30,45,60]:
		bends.append({"angle":angle,"crack_opening":snappedf(maxf(0,float(angle)/60.0*(1-float(e.bond)+float(e.oxide)+hardening)-.1),.01)})
	return {"section_pixels":pixels,"indentation_widths":indentations,"bend_trace":bends,"resolution":.01,"temperature":float(e.temperatures.max())}
static func inspect(observed:Dictionary)->Dictionary:
	var dark:=0
	for value:float in observed.section_pixels:
		if value<.5:dark+=1
	var gap:=float(dark)/float(observed.section_pixels.size())
	var mismatch:=absf(float(observed.indentation_widths[1])-float(observed.indentation_widths[0]))
	var opening:=float(observed.bend_trace.back().crack_opening)
	return {"qualified":gap+.05<=.15 and mismatch+.01<=.15 and opening+.01<=.1 and float(observed.temperature)<=150,
		"unbonded_fraction":gap,"haz_indent_difference":mismatch,"bend_opening":opening,"scope":"selected welded strap and destructive witnesses"}
