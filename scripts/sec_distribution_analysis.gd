extends RefCounted
## Interprets measured standard/sample traces only. Reports a finite-resolution
## relative distribution; neither exact chains nor an absolute mass certificate.
const Model=preload("res://scripts/sec_elution_model.gd")
static func reject(reason:String)->Dictionary:return {"accepted":false,"reason":reason}
static func valid_trace(response:Variant)->bool:
	if not response is Dictionary or response.get("method")!="aqueous_peg_relative_sec_v1" or not response.get("sample_id") is String or response.sample_id.is_empty():return false
	for key:String in ["epoch","step","origin","measured_flow","noise_estimate","injected_mass"]:
		if not Model.number(response.get(key)):return false
	if float(response.epoch)<0 or float(response.epoch)!=floorf(float(response.epoch)) or float(response.step)!=Model.STEP or float(response.origin)!=0 or float(response.measured_flow)<=0 or float(response.noise_estimate)<=0 or float(response.injected_mass)<=0:return false
	if not response.get("trace") is Array or response.trace.size()!=Model.POINTS:return false
	for point:Variant in response.trace:
		if not Model.number(point) or absf(float(point))>10000:return false
	return true
static func peak(response:Dictionary)->Dictionary:
	var top:=0
	for index:int in Model.POINTS:
		if float(response.trace[index])>float(response.trace[top]):top=index
	var height:=float(response.trace[top]);var half:=height*.5
	var left:=top;var right:=top
	while left>0 and float(response.trace[left])>half:left-=1
	while right<Model.POINTS-1 and float(response.trace[right])>half:right+=1
	return {"center":top*Model.STEP,"width":(right-left)*Model.STEP,"snr":height/float(response.noise_estimate)}
static func area(response:Dictionary,lower:float,upper:float)->float:
	var result:=0.0
	for index:int in Model.POINTS-1:
		var left:=index*Model.STEP;var overlap:=maxf(0.0,minf(left+Model.STEP,upper)-maxf(left,lower))
		result+=overlap*maxf(0.0,(float(response.trace[index])+float(response.trace[index+1]))*.5)
	return result
static func calibrate(standards:Array)->Dictionary:
	if standards.size()!=3:return reject("Three assigned narrow PEG standards are required.")
	var centers:Array[float]=[];var widest:=0.0;var flow:=0.0;var gain:=0.0;var epoch:=-1
	for index:int in 3:
		var standard:Variant=standards[index]
		if not standard is Dictionary or standard.get("assigned_dp")!=[10.0,40.0,160.0][index] or not valid_trace(standard.get("response")):return reject("Assigned standard provenance or trace is invalid.")
		var response:Dictionary=standard.response
		if index==0:epoch=int(response.epoch);flow=float(response.measured_flow)
		if int(response.epoch)!=epoch or absf(float(response.measured_flow)/flow-1.0)>.01:return reject("Reference flow or column epoch changed.")
		var observed:=peak(response)
		if float(observed.snr)<100 or float(observed.width)>.35 or float(observed.width)<Model.STEP*2:return reject("Reference resolution or sensitivity is insufficient.")
		centers.append(float(observed.center));widest=maxf(widest,float(observed.width))
		gain+=area(response,0.0,12.0)/float(response.injected_mass)/3.0
	if centers[0]<=centers[1] or centers[1]<=centers[2]:return reject("Reference retention is not size ordered.")
	var slope:=(centers[2]-centers[0])/log(16.0)
	var intercept:=centers[0]-slope*log(10.0)
	if absf(centers[1]-(intercept+slope*log(40.0)))>.03 or absf(slope)<.5:return reject("Reference curve or separation range is unsuitable.")
	if gain<.9 or gain>1.1:return reject("Reference recovery or detector response is unsuitable.")
	return {"accepted":true,"epoch":epoch,"flow":flow,"slope":slope,"intercept":intercept,"width":widest,"gain":gain,"minimum_dp":10.0,"maximum_dp":160.0,"method":"aqueous_peg_relative_sec_v1"}
static func evaluate(response:Variant,calibration:Variant,sample_id:String)->Dictionary:
	if not valid_trace(response) or response.sample_id!=sample_id:return reject("Retained sample trace or identity is invalid.")
	if not calibration is Dictionary or calibration.get("accepted")!=true or calibration.get("method")!="aqueous_peg_relative_sec_v1":return reject("No accepted relative PEG calibration.")
	for key:String in ["epoch","flow","slope","intercept","width","gain","minimum_dp","maximum_dp"]:
		if not Model.number(calibration.get(key)):return reject("Invalid calibration metadata.")
	if calibration.minimum_dp!=10.0 or calibration.maximum_dp!=160.0 or float(calibration.slope)>=-.5 or float(calibration.width)<=0 or float(calibration.width)>.35 or float(calibration.gain)<.9 or float(calibration.gain)>1.1 or float(calibration.flow)<=0:return reject("Unsupported calibration range or resolution.")
	if response.epoch!=calibration.epoch or absf(float(response.measured_flow)/float(calibration.flow)-1.0)>.01:return reject("Recalibrate after column or flow changes.")
	var total:=area(response,0,12);var gain:=float(calibration.gain)
	var recovery:=total/(float(response.injected_mass)*gain)
	if recovery<.95 or recovery>1.05:return reject("Sample recovery is outside the supported method.")
	var noise_area:=float(response.noise_estimate)*12.0*3.0
	if noise_area>total*.01:return reject("Insufficient concentration sensitivity.")
	var slope:=float(calibration.slope);var intercept:=float(calibration.intercept)
	var margin:=float(calibration.width)*1.5+.03
	var low:=intercept+slope*log(160.0);var high:=intercept+slope*log(10.0)
	if area(response,0,low-margin)+area(response,high+margin,12)>total*.01:return reject("Material elutes outside the calibrated size range.")
	if area(response,low,high)<total*.99:return reject("Material is too close to the calibrated range boundary.")
	var bounds:Array[float]=[10.0,20.0,40.0,80.0,160.0];var fractions:Array[float]=[]
	for index:int in 4:
		fractions.append(area(response,intercept+slope*log(bounds[index+1]),intercept+slope*log(bounds[index]))/total)
	# A conservative inner window discounts instrumental width and baseline noise.
	# This is a conditional game grade; reported bins retain column broadening.
	var usable:=area(response,intercept+slope*log(80.0)+margin,intercept+slope*log(20.0)-margin)
	var lower:=maxf(0.0,(usable-noise_area)/(total+noise_area))
	return {"accepted":true,"sample_id":sample_id,"relative_distribution_measured":true,"bin_edges_dp":bounds,"observed_mass_fractions":fractions,"window_20_80_fraction_lower":lower,"narrow_binder_candidate":lower>=.9,"resolution_log_dp":float(calibration.width)/absf(slope),"scope":"retained_compatible_peg_relative_distribution","absolute_mass_certified":false,"exact_chain_distribution":false}
